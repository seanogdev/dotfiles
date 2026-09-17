---
name: create-pr
description: Open or update a GitHub pull request in Sean's format — branch, fast checks, changeset, title, description and labels. Use when opening a PR, running `gh pr create`, or when the user asks to create, open, draft, write or update a PR or a PR description.
---

# Create a pull request

## 1. Check the branch

If the current branch is `main` or `master`, create a branch first. Never push to `main`.

Follow the repo's own branch naming rules. Some repos limit the length. Some repos take no `fix/`,
`feature/` or `chore/` prefix.

## 2. Run the fast checks

Run the repo's format, lint and unit test commands. Fix what they report before you continue.

Do not silence a check to make it pass. An `eslint-disable`, a `.skip` or a loosened assertion needs
a comment that says why the rule is wrong here. Put that comment in the PR body. If you cannot fix
what a check reports, stop. Tell the user.

Do not run the reviewer agents here. Do not run browser testing here. State plainly that neither
ran.

Where the repo has a skill that names those commands, follow it.

## 3. Check for a changeset

If the repo uses changesets and the diff ships code, confirm that a `.changeset/` file covers it.
Write one if it is absent. Follow the `changeset` skill for the wording.

## 4. Write the title

Write one line in sentence case. Add a `docs:`, `fix:`, `refactor:` or `i18n:` prefix only when it
helps.

## 5. Write the body

Look for a repository template first: `.github/pull_request_template.md`,
`.github/PULL_REQUEST_TEMPLATE.md`, or a file in `.github/PULL_REQUEST_TEMPLATE/`. If a template
exists, fill it in. Fit the two sections below into it. Do not replace it.

**Changes.** Write a top level bullet list that summarises the PR. Judge what the reviewer needs.
Write a bullet only when the reviewer would miss something without it. Make each bullet as short as
it can go without the loss of that thing. One bullet is correct when one thing changed. Do not pad
the list to look thorough.

Write for a reviewer who is about to read the diff. Give each bullet the one thing the diff does not
say. Then stop. Do not restate the diff. Do not repeat the title. Do not explain code the reviewer
can read.

Call a workaround a workaround. Give it a bullet that names the real fix.

**File table.** Write a collapsible table that covers every changed file. Add a very short note on
how each file changed. Write a few words per cell, not a sentence.

A GitHub table never wraps. It scrolls sideways, so a long path in the File column pushes the Change
column out of view. Remove the prefix that every row shares. Name that prefix once in the summary
line:

```markdown
<details>
<summary>Files changed in <code>src/api/</code></summary>

| File | Change |
| ---- | ------ |
| `client.ts` | Added the retry wrapper |
| `client.test.ts` | Covers the new backoff path |

</details>
```

If the rows share no prefix, remove what each row shares with its neighbours. Group the table by
directory. If the paths are still wide enough to scroll, drop the table. Use a bullet list, which
wraps at the page width:

```markdown
- `src/api/client.ts`: added the retry wrapper
```

**Describe the state the branch is in.** This rule owns every section of the body, the repo
template's sections included. It does not own the `Changes` bullets alone. How the session reached
the current state is not the reviewer's concern. The reviewer reads the branch as it stands now. So
the body holds:

- No approach you abandoned.
- No order you worked in.
- No problem you hit and then solved.
- No round of review you answered.

Where the branch stands on another branch, that is current state and it stays: which PR this one
follows, which issue it closes, what is still open elsewhere. The behaviour of the code before this
PR also stays, where the reviewer needs it to read the change.

No sentence in the body may refer to an earlier revision of the PR itself. Cut all of these:

- "An earlier revision moved the lead to the observer's margin"
- "the first answer was yes"
- "two things the previous revisions asserted turned out to be false"
- "no performance number on this revision"

Where a superseded claim taught you something the reviewer still needs, state that thing as a fact
about the current code. Where it did not, cut it.

A `Revision history` section is the same mistake inside a `<details>` block. Do not write one.

**Collapse the bulk.** Put anything the reviewer needs on hand but not on screen in a `<details>`
block. Give the block a summary line that says what is inside. That covers review findings, a log
excerpt, a benchmark run and a long list. The file table above is the pattern. Keep the open part of
the body short enough to read without a scroll.

Add no heading the repo's template does not ask for. `Changes`, the file table and `Screenshots` are
the whole of it. Add no `Testing`, `Motivation`, `Risks` or `Notes` section unless the template has
one.

Leave a `## Screenshots` heading. Leave it empty unless step 7 fills it. Never write placeholder
text into it.

Punctuate properly. A bullet or a table cell can be a fragment. Do not use em dashes.

Obey any PR description rule the repo's own config sets. A repo may ask for plain language that both
a non-native English speaker and a non-technical reader can follow.

## 6. Push, then create or update

Push the branch. Then check for an open PR on it with `gh pr view`.

- If no PR exists, create it with `gh pr create`.
- If a PR exists, write the body again from scratch under step 5. Then write it back with
  `pr-body.sh` below.

**Rebuild the body, never append to it.** Read the current body first, for the content the next
section says to keep. Read it also for what it tells you about the branch. Then write the body the
diff asks for today. Do not edit the body line by line. Do not add a paragraph that answers the last
round of review. A body that is patched each round grows, contradicts itself, and keeps claims the
code has moved past.

Open the PR ready for review. Pass `--draft` only when the user asks for a draft, or when the work
is unfinished.

### Carry the author's content across

`gh pr edit` replaces the entire body, and an image attached by hand cannot be restored from the CLI
once it is gone.

```bash
~/.claude/skills/create-pr/pr-body.sh save > /tmp/pr-body-before.md
~/.claude/skills/create-pr/pr-body.sh edit /tmp/pr-body-new.md
```

`edit` refuses to write a body that drops an attachment the author added. It also strips the
trailing newline `gh` adds, which otherwise grows the body by a blank line on every run. `check`
runs the same guard and edits nothing.

Keep everything the skill does not own:

- Image and video markup wherever it sits: `![alt](url)`, `<img ...>`, `<video ...>`, and bare
  `https://github.com/user-attachments/...` links.
- The whole `## Screenshots` section, verbatim.
- Any heading the author added that is not `Changes`, the file table, or part of the repo template.
- Every reference the diff cannot regenerate: the task or issue link a template section holds, a
  linked issue number, a `Follow-up to #NNNNN` line. A rebuilt body loses these unless you carry
  them across by hand. Read them out of the saved body before you write the new one.

Every image keeps its heading, its caption and its position. The guard compares attachment urls and
nothing else, so a caption or a heading you drop around one still gets through.

## 7. Attach screenshots the session already produced

Do this only when the session already has screenshots on disk. You do not capture screenshots in
this step.

GitHub has no API, CLI or MCP route for uploading an attachment, so the file has to go through a
browser. Hand that to a sub-agent with the `agent-browser` skill.

Offer first:

> The session produced N screenshots. Want me to attach them to the PR description?

Go straight ahead only when the user has already asked for them on the PR.

### Auth

A `gh` token does not work here. The upload runs on a web session cookie with a CSRF check. You
cannot trade one for the other, so the browser has to be signed in already.

Set that up once:

```bash
agent-browser --headed open https://github.com/login   # without --headed there is no window to use
# sign in, then:
agent-browser state save ~/.config/agent-browser/github-auth.json
chmod 600 ~/.config/agent-browser/github-auth.json
```

Pass `--state ~/.config/agent-browser/github-auth.json` on every command after that. Do not assume
it took. Open `github.com` and read the page.

That file is a live GitHub session. Keep it under `~/.config`. Never keep it in a repo. Set
`AGENT_BROWSER_ENCRYPTION_KEY` to a 64 character hex key to encrypt it at rest. It expires after 30
days, and the symptom is a login page where the PR should be.

Two fallbacks when a state file is not an option:

- **A running browser over CDP.** `agent-browser connect 9222`, or `--auto-connect`. Needs the
  browser started with `--remote-debugging-port=9222`, which a normal launch does not do.
- **A real profile directory.** `--executable-path <binary> --profile <directory>`. A running
  browser locks its profile, so close the browser first. Do not assume a profile named `Default`,
  because some Chromium browsers number theirs.

Never type credentials into a login form. If no route leaves the browser signed in, stop. Ask the
user.

### The sub-agent

The browser only uploads. GitHub publishes an attachment the moment a file input accepts it, so the
comment it was dropped into is never submitted. The description stays with `gh pr edit` under the
step 6 rules.

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

Put those URLs under `## Screenshots`. Write the body per step 6. On a private repo they resolve
only for a signed-in viewer, so an anonymous `curl` that returns 404 does not mean the upload
failed.

## 8. Apply labels

Follow the repo's label rules when its config provides them. Those rules sometimes sit outside the
repo, in the instructions for the directory that holds it. Apply no labels when no rules exist.

Reconcile the labels on an existing PR too. Remove a label that no longer fits.
