---
name: create-pr
description: Open or update a GitHub pull request in Sean's format — branch, fast checks, changeset, title, description and labels. Use when opening a PR, running `gh pr create`, or when the user asks to create, open, draft, write or update a PR or a PR description.
---

# Create a pull request

Work through the steps in order.

## 1. Check the branch

If the current branch is `main` or `master`, create a branch first. Never push to `main`.

Follow the repo's own branch naming rules. Some repos cap the length, and some take no `fix/`,
`feature/` or `chore/` prefix. Read the repo's config before you name the branch.

## 2. Run the fast checks

Run the repo's format, lint and unit test commands. Fix what they report before you continue.

Do not run the reviewer agents or browser testing here. State plainly that they did not run.

Where the repo has a skill that names those commands, follow it.

## 3. Check for a changeset

If the repo uses changesets and the diff ships code, confirm a `.changeset/` file covers it. Write
one if it is missing. Follow the `changeset` skill for the wording.

## 4. Write the title

One line, sentence case. Add a `docs:`, `fix:`, `refactor:` or `i18n:` prefix only when it helps.

## 5. Write the body

Look for a repository template first: `.github/pull_request_template.md`,
`.github/PULL_REQUEST_TEMPLATE.md`, or a file in `.github/PULL_REQUEST_TEMPLATE/`. If one exists,
fill it in. Fit the two sections below into it. Do not replace it.

**Changes.** A top level bullet list that summarises the PR. Say what changed and why it matters.
Do not restate the diff line by line.

**File table.** A collapsible table that covers every changed file, with a very short note on how
each one changed.

```markdown
<details>
<summary>Files changed</summary>

| File | Change |
| ---- | ------ |
| `src/api/client.ts` | Added the retry wrapper |
| `src/api/client.test.ts` | Covers the new backoff path |

</details>
```

Leave a `## Screenshots` heading. The images under it belong to the author. Leave it empty unless
step 7 fills it, and never write placeholder text into it.

Use complete sentences and proper punctuation. Do not use em dashes.

Obey any PR description rule the repo's own config sets. A repo may ask for plain language that both
a non-native English speaker and a non-technical reader can follow.

## 6. Push, then create or update

Push the branch. Then check for an open PR on it with `gh pr view`.

- If no PR exists, create it with `gh pr create`.
- If a PR exists, carry the author's content across first, then rewrite the body with `gh pr edit`.

Open the PR ready for review. Pass `--draft` only when the user asks for a draft, or when the work
is unfinished.

### Carry the author's content across

`gh pr edit --body` replaces the entire body. Anything attached by hand is gone, and an image cannot
be put back from the CLI once it is lost. Treat every existing body as something to merge into, not
something to overwrite.

Save the current body before you touch it. Write it to `/tmp`, never into the repo you are working
in, so a scratch file cannot end up in a commit:

```bash
gh pr view --json body -q .body > /tmp/pr-body-before.md
```

Carry across everything the skill does not own:

- Image and video markup wherever it sits: `![alt](url)`, `<img ...>`, `<video ...>`, and bare
  `https://github.com/user-attachments/...` links.
- The whole `## Screenshots` section, verbatim.
- Any heading the author added that is not `Changes`, the file table, or part of the repo template.

Put each image back under the heading it sat under before. Keep its caption and its order.

Then verify. List every asset URL in the old body:

```bash
grep -oE 'https://[^ )">]*(user-attachments|githubusercontent)[^ )">]*' /tmp/pr-body-before.md | sort -u
```

Every URL that command prints must appear in the new body. If one is missing, the edit is wrong.
Put it back and run the check again. Do not run `gh pr edit` until the check passes.

## 7. Attach screenshots the session already produced

This step only applies when the session has already produced screenshots on disk. It is not your job
to capture any. If the session has no images, skip the step and leave `## Screenshots` for the
author.

GitHub has no API, CLI or MCP route for uploading an attachment. The upload only happens in a
browser, against the PR page, so hand it to a sub-agent that has the `agent-browser` skill.

Offer before you do it:

> The session produced N screenshots. Want me to attach them to the PR description?

Skip the offer and go ahead only when the user has already asked for those images on the PR.

### Auth

The `gh` token is no use here. It is an OAuth token, and the upload runs on a web session cookie
with a CSRF check. There is no way to trade one for the other, so the browser has to be signed in to
GitHub already.

`agent-browser` assumes Chrome. When the browser in use is a different Chromium, point it at the
right binary and profile:

```bash
--executable-path <the browser binary>
--profile <the profile directory>
```

Do not assume a profile called `Default` exists, because other Chromium browsers number theirs
instead. Do not guess which profile is signed in either. Open `github.com` and read the page to
confirm.

Pick a route in this order:

1. **A saved state file.** Sign in once in the browser `agent-browser` launches, then
   `agent-browser state save ~/.config/agent-browser/github-auth.json`. Pass
   `--state ~/.config/agent-browser/github-auth.json` on every run after that. This is the default
   choice. It survives the browser being open and does not care which profile is which. That file is
   a live GitHub session, so treat it as a credential: keep it under `~/.config`, never inside a
   repo, and `chmod 600` it after saving. Set `AGENT_BROWSER_ENCRYPTION_KEY` to a 64 character hex
   key to have it encrypted at rest. Saved state expires after 30 days, so expect to sign in again
   and re-save when the upload suddenly lands on a login page.
2. **A running browser over CDP.** Works only when the browser was started with
   `--remote-debugging-port=9222`. Then `agent-browser connect 9222`, or `--auto-connect` to find it.
   Nothing is written to disk, but a normal launch has no debugging port, so this usually needs a
   restart first.
3. **The real profile directory.** The two flags above. A running browser locks its profile
   directory, so this fails while it is open. Last resort.

Say which route the sub-agent used. If none of them leave the browser signed in, stop and ask. Never
type credentials into a login form.

### The sub-agent

Spawn one. Give it the PR URL, the absolute path of every image, a caption for each, and the auth
flag from above. Tell it to:

1. Load the `agent-browser` skill and open the PR.
2. Edit the description. Do not add a comment.
3. Upload the files under the `## Screenshots` heading with `agent-browser upload`, one at a time,
   waiting for each upload to finish before starting the next.
4. Save the description.
5. Report back the `https://github.com/user-attachments/...` URL it got for every image.

Keep those URLs. They are what the next run has to carry across in step 6.

## 8. Apply labels

Follow the repo's label rules when its config provides them. Those rules sometimes sit outside the
repo, in the instructions for the directory that holds it. Apply no labels when no rules exist.

Reconcile the labels on an existing PR too. Remove a label that no longer fits.
