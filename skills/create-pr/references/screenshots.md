# Attach screenshots

Read this file when the session already has screenshots on disk and they go on the PR. The step
numbers below point at `SKILL.md`.

GitHub has no API, CLI or MCP route for uploading an attachment, so the file has to go through a
browser. Hand that to a sub-agent with the `agent-browser` skill.

Offer first:

> The session produced N screenshots. Want me to attach them to the PR description?

Go straight ahead only when the user has already asked for them on the PR.

## Auth

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

## The sub-agent

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

Put those URLs under `## Screenshots`. Write the body per step 6 of `SKILL.md`. On a private repo
they resolve only for a signed-in viewer, so an anonymous `curl` that returns 404 does not mean the
upload failed.
