---
name: delegate-context
description: Keep bulk file reads and boilerplate writes out of the main context window by delegating them to a cheap subagent, the way Portal by Spotify's bulk-reader and code-writer modes do. Use before reading 3+ files or any large file only to gather information, and before writing new code that copies an existing pattern.
---

# Delegate bulk reads and boilerplate writes

This session's context is the expensive resource. Most bulk file reading and
pattern-copying does not need this model's reasoning. Push that work onto a
subagent on a cheaper model, and keep only the result.

## When to delegate

**Bulk read.** About to read 3 or more files, or one file over roughly 300
lines, only to answer a question or summarize — not to edit the file here.

**Boilerplate write.** About to create a new file that follows an existing
pattern in the repo (a new component, test, config, or handler shaped like
others already in the tree).

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
