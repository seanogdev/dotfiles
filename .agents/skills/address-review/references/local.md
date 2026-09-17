# Local feedback

Read this file when the feedback is local: a review that sits in this conversation, or a file the user points at. Everything else in the pass follows `SKILL.md`.

## Reading the feedback

**Read it at the start of the pass, every time.** Read a file again even if you read it minutes ago. The reason is the reason the PR gets queried again: the user edits these files, and the copy from earlier in this conversation is stale. If the feedback is in the conversation instead, the latest version of it wins. The user narrowing it or adding to it after the fact is part of the feedback, not a footnote to it.

Split it into items, one per distinct point. A paragraph that raises three things is three items. Keep the `path:line` each one points at. The summary labels its rows by that when there are no urls.

Nothing is filtered out here. Every item is live. There is no thread state and there are no reactions, so **Threads that have come back** and **Votes the user left** in `SKILL.md` are both PR-only. What stands in for a vote is the user saying it out loud: "the second one matters", "ignore the lint one". Weigh that exactly as **Votes the user left** weighs a `THUMBS_UP` or a `THUMBS_DOWN`.

## Applying and replying

Make the fixes. Commit them in small logical commits, the same way. Nothing here has a thread to reply into or a comment to vote on, so the plan in `SKILL.md` has no per-item rows.

If the branch has an open PR, push. Then leave one comment on the PR that says what changed this round and why. The review happened off the PR. Without that comment, the branch grows commits that nothing on the PR accounts for. Keep it to a line per point. Each line names its sha. Write it in the **Reply voice** of `SKILL.md`.

It goes through `apply.ts` as a single item that carries a `prId` and a `bodyFile` and nothing else. That posts it as a conversation comment. An identical body already posted in your name comes back as `duplicate`.

```json
[{ "ref": "round summary", "prId": "PR_kwDO...", "bodyFile": "/tmp/round.md" }]
```

`gh pr view --json id --jq .id` is where that `prId` comes from when no `fetch.sh` ran this pass.

That comment is the only place the round goes. Never move it, or any part of it, into the PR description. The description follows the rule in **Finishing** in `SKILL.md`, the same as on any other pass.

If the branch has no PR, push nothing unless the user asks. The summary is the whole of the output. Leave the feedback file itself as it is either way.
