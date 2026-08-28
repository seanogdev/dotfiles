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
- If a PR exists, merge into the body it already has, then write it back with `gh pr edit`.

Open the PR ready for review. Pass `--draft` only when the user asks for a draft, or when the work
is unfinished.

### Carry the author's content across

`gh pr edit` replaces the entire body, and an image attached by hand cannot be restored from the CLI
once it is gone. Treat the existing body as something to merge into.

Save it first. Keep the file in `/tmp` so no scratch file lands in the repo, and strip the newline
`gh` adds, which otherwise grows the body by a blank line on every run:

```bash
gh pr view --json body -q .body | perl -pe 'chomp if eof' > /tmp/pr-body-before.md
```

Keep everything the skill does not own:

- Image and video markup wherever it sits: `![alt](url)`, `<img ...>`, `<video ...>`, and bare
  `https://github.com/user-attachments/...` links.
- The whole `## Screenshots` section, verbatim.
- Any heading the author added that is not `Changes`, the file table, or part of the repo template.

Every image keeps its heading, its caption and its position.

Write the new body to a file with no trailing newline and pass it as `gh pr edit --body-file`.

Before that edit, confirm nothing was dropped:

```bash
grep -oE 'https://[^ )">]*(user-attachments|githubusercontent)[^ )">]*' /tmp/pr-body-before.md | sort -u
```

Every URL it prints must appear in the new body. If one is missing, put it back. Do not run
`gh pr edit` until the check passes.

## 7. Attach screenshots the session already produced

Only when the session already has screenshots on disk. Capturing them is not part of this step. With
no images, leave `## Screenshots` to the author and move on.

GitHub has no API, CLI or MCP route for uploading an attachment, so the file has to go through a
browser. Hand that to a sub-agent with the `agent-browser` skill.

Offer first:

> The session produced N screenshots. Want me to attach them to the PR description?

Go straight ahead only when the user has already asked for them on the PR.

### Auth

A `gh` token does not work here. The upload runs on a web session cookie with a CSRF check, and
there is no way to trade one for the other, so the browser has to be signed in already.

Set that up once:

```bash
agent-browser --headed open https://github.com/login   # without --headed there is no window to use
# sign in, then:
agent-browser state save ~/.config/agent-browser/github-auth.json
chmod 600 ~/.config/agent-browser/github-auth.json
```

Pass `--state ~/.config/agent-browser/github-auth.json` on every command after that. Confirm it
took by opening `github.com` and reading the page rather than assuming.

That file is a live GitHub session. Keep it under `~/.config`, never in a repo, and set
`AGENT_BROWSER_ENCRYPTION_KEY` to a 64 character hex key to encrypt it at rest. It expires after 30
days, and the symptom is a login page where the PR should be.

Two fallbacks when a state file is not an option:

- **A running browser over CDP.** `agent-browser connect 9222`, or `--auto-connect`. Needs the
  browser started with `--remote-debugging-port=9222`, which a normal launch does not do.
- **A real profile directory.** `--executable-path <binary> --profile <directory>`. A running
  browser locks its profile, so it has to be closed first. Do not assume a profile named `Default`,
  because some Chromium browsers number theirs.

Never type credentials into a login form. If no route leaves the browser signed in, stop and ask.

### The sub-agent

The browser only uploads. GitHub publishes an attachment the moment a file input accepts it, so the
comment it was dropped into is never submitted, and the description stays with `gh pr edit` under
the step 6 rules.

Spawn one sub-agent. Give it the PR URL, the absolute path of every image, and the `--state` flag.
Tell it to:

1. Load the `agent-browser` skill and open the PR.
2. Wait for `input[type=file]` to exist, because the editor mounts these after first paint.
   `#fc-new_comment_field` is the reply box and `#fc-issue-<id>-body` is the description.
3. Upload one file at a time: `agent-browser upload "#fc-new_comment_field" <path>`.
4. Read each URL back out of the textarea. GitHub writes HTML there, not markdown:
   `<img width="..." height="..." alt="..." src="https://github.com/user-attachments/assets/<uuid>" />`.
5. Clear the textarea and leave the comment unsubmitted.
6. Report one `https://github.com/user-attachments/assets/...` URL per image.

Put those URLs under `## Screenshots` and write the body per step 6. On a private repo they resolve
only for a signed-in viewer, so an anonymous `curl` returning 404 does not mean the upload failed.

## 8. Apply labels

Follow the repo's label rules when its config provides them. Those rules sometimes sit outside the
repo, in the instructions for the directory that holds it. Apply no labels when no rules exist.

Reconcile the labels on an existing PR too. Remove a label that no longer fits.
