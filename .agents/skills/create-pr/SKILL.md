---
name: create-pr
description: Open or update a GitHub pull request in Sean's format — branch, fast checks, changeset, title, description and labels. Use when opening a PR, running `gh pr create`, or when the user asks to create, open, draft, write or update a PR or a PR description.
---

# Create a pull request

## 1. Check the branch

If the current branch is `main` or `master`, create a branch first. Never push to `main`.

Follow the repo's own branch naming rules. Some repos cap the length, and some take no `fix/`,
`feature/` or `chore/` prefix.

## 2. Run the fast checks

Run the repo's format, lint and unit test commands. Fix what they report before you continue.

Do not silence a check to make it pass. An `eslint-disable`, a `.skip` or a loosened assertion needs
a comment saying why the rule is wrong here, and it goes in the PR body. If you cannot fix what a
check reports, stop and tell the user.

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

**Changes.** A top level bullet list that summarises the PR. Judge what the reviewer needs. A bullet
earns its place when the reviewer would miss something without it, and it goes as short as it can go
without losing that. One bullet is right when one thing changed, so do not pad the list out to look
thorough.

Write for a reviewer who is about to read the diff. Give each bullet the one thing the diff does not
say, and stop there. Do not restate the diff, do not repeat the title, and do not explain code the
reviewer can read.

Describe the state the branch is in. How the session reached it is not the reviewer's concern: no
approach you abandoned, no order you worked in, no problem you hit and then solved.

Call a workaround a workaround. Give it a bullet that names the real fix.

**File table.** A collapsible table that covers every changed file, with a very short note on how
each one changed. A few words per cell, not a sentence.

A GitHub table never wraps. It scrolls sideways, so a long path in the File column pushes the Change
column out of view. Strip the prefix every row shares and name it once in the summary line:

```markdown
<details>
<summary>Files changed in <code>src/api/</code></summary>

| File | Change |
| ---- | ------ |
| `client.ts` | Added the retry wrapper |
| `client.test.ts` | Covers the new backoff path |

</details>
```

Where the rows share no prefix, strip what each row shares with its neighbours and group the table
by directory. Where the paths are still wide enough to scroll, drop the table and use a bullet list,
which wraps at the page width:

```markdown
- `src/api/client.ts`: added the retry wrapper
```

**Collapse the bulk.** Anything the reviewer needs on hand but not on screen goes in a `<details>`
block with a summary line that says what is inside. That covers review findings, a log excerpt, a
benchmark run, a long list. The file table above is the pattern. The open part of the body stays
short enough to read without scrolling.

Add no heading the repo's template does not ask for. `Changes`, the file table and `Screenshots`
are the whole of it: no `Testing`, `Motivation`, `Risks` or `Notes` section unless the template has
one.

Leave a `## Screenshots` heading. Leave it empty unless step 7 fills it, and never write placeholder
text into it.

Punctuate properly. A bullet or a table cell can be a fragment. Do not use em dashes.

Obey any PR description rule the repo's own config sets. A repo may ask for plain language that both
a non-native English speaker and a non-technical reader can follow.

## 6. Push, then create or update

Push the branch. Then check for an open PR on it with `gh pr view`.

- If no PR exists, create it with `gh pr create`.
- If a PR exists, merge into the body it already has, then write it back with `pr-body.sh` below.

Open the PR ready for review. Pass `--draft` only when the user asks for a draft, or when the work
is unfinished.

### Carry the author's content across

`gh pr edit` replaces the entire body, and an image attached by hand cannot be restored from the CLI
once it is gone.

```bash
~/.claude/skills/create-pr/pr-body.sh save > /tmp/pr-body-before.md
~/.claude/skills/create-pr/pr-body.sh edit /tmp/pr-body-new.md
```

`edit` refuses to write a body that drops an attachment the author added, and strips the trailing
newline `gh` adds, which otherwise grows the body by a blank line on every run. `check` runs the
same guard and edits nothing.

Keep everything the skill does not own:

- Image and video markup wherever it sits: `![alt](url)`, `<img ...>`, `<video ...>`, and bare
  `https://github.com/user-attachments/...` links.
- The whole `## Screenshots` section, verbatim.
- Any heading the author added that is not `Changes`, the file table, or part of the repo template.

Every image keeps its heading, its caption and its position. The guard compares attachment urls and
nothing else, so a caption or a heading you drop around one still gets through.

## 7. Attach screenshots the session already produced

Only when the session already has screenshots on disk. Capturing them is not part of this step.

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
