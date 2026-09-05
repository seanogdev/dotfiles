---
name: delegate-context
description: Keep bulk file reads and boilerplate writes out of the main context window by delegating them to a cheap subagent, the way Portal by Spotify's bulk-reader and code-writer modes do. Use before reading 3+ files or any large file only to gather information, and before writing new code that copies an existing pattern.
---

# Delegate bulk reads and boilerplate writes

This session's context is the expensive resource. Most bulk file reading and
pattern-copying does not need this model's reasoning. Push that work onto a
subagent on a cheaper model, and keep only the result.

## Large reads are enforced, not just suggested

`hooks/check-file-size` and `hooks/check-bash-read` are real `PreToolUse`
hooks (see `install-hooks.sh`), not prose you're expected to follow
voluntarily. Once installed, `Read` and `cat`/`head`/`tail`/`less`/`more`
are blocked automatically on any file over the line threshold (default 350,
`DELEGATE_CONTEXT_MIN_LINES` to change it), with a message pointing at
`bulk-reader`. If a read gets blocked, follow the block's instruction — you
do not need to judge file size yourself first.

An earlier version of this skill only put the threshold in prose here and
asked the model to check it before reading. That doesn't hold up: nothing
stops the model from skipping the check and reading anyway. The hooks close
that gap the way Portal by Spotify's `shunt` plugin does it — as an
enforced block, not a rule the model can ignore.

## When to delegate

**Bulk read.** The hook above already covers a single large file or a
`cat`/`head`/`tail` on one. Delegate proactively, before the hook would
even fire, when you already know you're about to read 3 or more separate
files just for a summary — the hook only ever sees one file at a time.

**Boilerplate write.** Nothing enforces this one — decide it yourself.
About to create a new file that follows an existing pattern in the repo (a
new component, test, config, or handler shaped like others already in the
tree).

## When not to delegate

- The file is already in context from an earlier read or edit.
- The edit needs judgment about this conversation's decisions, not pattern
  matching.
- The work touches secrets, credentials, or anything security-sensitive.
- The file is small (under ~100 lines) and reading it directly is cheaper
  than the round trip.

## How to delegate

Use the `Agent` tool with `subagent_type: "bulk-reader"` for reads, or
`subagent_type: "code-writer"` for boilerplate. Both run on a cheap model
and are read-restricted or write-restricted by their own definitions in
`.agents/agents/`. Never use `fork` for this — a fork inherits your full
context, which defeats the point of keeping the file content out of it.

**Bulk read.** Name the exact files or glob, and the question to answer:

> Read `src/api/*.ts`. Report, in bullet points: which files export a
> `retry` helper, and what its signature is.

**Boilerplate write.** Point at the pattern file and the new file's
purpose:

> Read `src/components/UserCard.tsx` as the pattern. Write
> `src/components/TeamCard.tsx` following the same structure, for a team
> with `name`, `members`, and `avatarUrl`.

Both agents are told to report a summary, not raw content. Take that
summary at face value for routing decisions. Read the file yourself only if
you need to edit it, verify a claim, or the summary does not answer the
question.

If `bulk-reader` or `code-writer` is not available as a `subagent_type`
(the agent definitions did not load), fall back to `general-purpose` with
`model: "haiku"` and repeat the same rules in the prompt.

## Installing the hooks

`~/.claude/settings.json` is not synced from this dotfiles repo — it holds
per-machine fields like `model` that differ between machines. Run this once
per machine instead of relying on stow:

```fish
~/.claude/skills/delegate-context/install-hooks.sh
```

It merges only `hooks.PreToolUse` into the file with `jq`, leaves every
other key untouched, and is safe to re-run — it skips any entry already
present instead of duplicating it.
