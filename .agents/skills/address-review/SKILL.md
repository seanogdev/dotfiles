---
name: address-review
description: Work through the review feedback on a GitHub PR, across inline threads, review bodies and conversation comments. Fix what should be fixed, reply with the reasoning where it should not, vote on each comment, then resolve every thread that has one. Works local feedback the same way — a review sitting in this conversation, or in a file — minus the parts that need a PR. Use when a review lands and the user says "address the review", "fix the review comments", "respond to the review", "handle this review", "work through the feedback in review.md", or points at review feedback to act on.
user-invocable: true
---

# Address review

Take every piece of live feedback to a conclusion: fix it or push back, then account for the whole pass to the user. On a PR that also means replying either way, voting on the comment, and resolving the thread, where inline threads are only one of three places feedback arrives.

## Where the feedback is

**A PR.** The default. If no PR was named, use the open PR for the current branch.

**Local.** A review sitting in this conversation — a `/code-review` report, a pasted set of comments, the user listing what they want changed — or a file they point at. Everything about deciding and fixing is the same.

Which one it is: a path or an `@file` in the invocation means the file. The user pointing at feedback already in the conversation ("address that", "fix those", "work through the review above") with no PR named means the context. Otherwise it is the PR. Where they name both, read both and run each under its own rules, then give one summary covering the lot.

## Reading the feedback

### On a PR

**Query first, every time.** Read the feedback from the API as the first action of the pass, before anything else. A read from earlier in this conversation is stale and cannot be reused: reviewers add comments while a pass is running, and a second invocation minutes after the first usually means something landed in between.

```bash
~/.claude/skills/address-review/fetch.sh [PR]
```

Feedback arrives in three places on a PR: inline review threads, review bodies, and conversation comments. This reads all three in one go, keeps the threads that are still live, and defaults to the open PR for the current branch.

Still live means unresolved, plus any thread you replied in that someone has spoken on since. GitHub leaves a thread resolved when a new comment lands on it, so a reviewer answering the reply you closed a thread with would otherwise never reach the next pass. Those come back carrying `isResolved: true`.

Skip anything `viewer` wrote themselves, and skip the CI and coverage chatter a PR collects. Your own replies inside a thread are the exception: they are what the reviewer is answering, so read them. Keep every `url`. The summary at the end links its rows by them.

Which id becomes which plan field: `threads[].id` is a `threadId` and `threads[].comments[0].id` is that item's `commentId`; `reviews[].id` and `conversation[].id` are each their own `commentId`, and both take the `prId`, since neither has a thread to reply into. A review body carries a vote, and the user's vote, the same way a comment does.

`userVotes` marks the comments the user voted on, which the next section weighs. `isBot` is true where a GitHub App wrote the comment, which is what **What the vote means** turns on. An automated reviewer running on a machine user account comes back false, so read the author too.

A review body often never becomes an inline thread, and a reviewer often raises their main point in the conversation rather than against a line. Those two are the easiest to miss.

### Local

**Read it at the start of the pass, every time.** A file gets read again even if it was read minutes ago, for the same reason the PR gets queried again: the user edits these files, and the copy from earlier in this conversation is stale. Where the feedback is in the conversation instead, the latest version of it wins — the user narrowing it or adding to it after the fact is part of the feedback, not a footnote to it.

Split it into items, one per distinct point. A paragraph raising three things is three items. Keep the `path:line` each one points at, since that is what the summary labels its rows by when there are no urls.

Nothing is filtered out here and every item is live: there is no thread state and there are no reactions, so **Threads that have come back** and **Votes the user left** are both PR-only. What stands in for a vote is the user saying it out loud — "the second one matters", "ignore the lint one". Weigh that exactly as their `THUMBS_UP` or `THUMBS_DOWN` is weighed below.

## Deciding

The goal is the right call on each comment. Agreeing and disagreeing are both fine outcomes, neither one is the target.

So check the claim before acting on it. Read the surrounding file, not only the diff hunk, and where a comment describes a bug, trace the path that would produce it. A reviewer working from a hunk in isolation will sometimes flag something the wider file already handles. Apply the same standard whoever wrote the comment.

The comment was written against some commit, and the branch has likely moved since. Before acting on it, check the file as it stands now, not the snippet quoted in the comment or the diff hunk it was raised against. A later commit can already fix what the comment describes, move the line it points at, or change the code around it enough that the concern no longer applies. Where the comment's line number or quoted code no longer matches the file, that gap is itself a sign the code moved on, and the current version is what decides the call.

Fix it when the claim holds up, and when the reviewer is pointing at a real risk even if their suggested fix is not the one you would pick. Say so when it does not hold up: the comment misreads the code, the change would break something not visible from the diff, the problem it describes cannot be reproduced, or it asks for an abstraction the codebase has not earned yet.

A thread with `isOutdated: true` usually means the code moved on. Check whether the concern still applies before spending effort on it.

Where a comment is genuinely ambiguous, ask rather than guessing at what the reviewer meant: in the reply on a PR, and straight to the user where the feedback is local.

### Threads that have come back

`isResolved: true` on a thread means you settled it on an earlier pass and someone has replied since. The earlier call is not binding. The reviewer has read it and answered it, which is the case for deciding again rather than for standing behind the first answer.

Read the whole thread, your own reply included, and treat the last comment as the live one. Then decide it the way any other comment gets decided. A reviewer who answers a decline with a path you did not trace has earned a second look; one who repeats the original point with nothing new behind it has not, and saying so once more is the whole reply. Where they accept the answer or just say thanks, nothing needs doing: it stays resolved, it needs no plan item, and a row in the summary is the whole of it.

Otherwise reply, re-vote where the call moved, and resolve again. Reactions add rather than replace, so clear the old vote with `unvote.sh` before you cast the new one. Where the call moves to a decline on a human comment, `unvote.sh` is the whole of it, since no vote replaces the one you remove.

### Votes the user left

The user votes on review comments too, with the same two reactions. A vote from the user is the one vote that carries weight here. It says they read the comment and formed a view on it before you got to it. Reactions from anyone else are not that signal, and the `userVotes` field leaves them out.

Read the votes before you cast any of your own. `gh` runs as the user's account, so once this skill reacts, its reaction is indistinguishable from theirs. Your own reply in the thread is what tells them apart. No reply from you means the vote is theirs. Where you have replied, the vote is yours from that pass and the reply says which way it went, unless the two disagree, in which case the user changed it and that disagreement is the signal.

**`THUMBS_UP` from the user.** They value the comment. Treat it with more reverence than the rest. Reverence is a higher bar for declining, not agreement by default, so check the claim exactly as carefully. Then:

- Read the whole file and trace the failure path before declining it. The decline needs a line reference, not an assertion.
- Take the fix where the call is close.
- An out of scope answer needs a follow-up issue or task, and the reply names it.
- Tell the user in the summary if you declined it anyway. They may want to reverse that.

**`THUMBS_DOWN` from the user.** They do not want the comment addressed. Take that as the decision and decline it. One exception: where checking the claim turns up a real defect, do not close the thread on it. Leave that thread open and put the evidence in the summary, so the user can change their mind.

## Applying, voting and replying

Fix the cause, not the symptom. Suppressing a warning, skipping a test, loosening an assertion or special-casing the reviewer's input is not a fix. Where the real fix is out of scope, decline the comment.

Make the fixes, commit them in small logical commits, and push to the PR branch **before** replying. The reply should point at code that is already on the PR. Read every identifier back from its source before it goes in a public reply: the shas from `git log`, a line number from the file as it now stands, an issue number from `gh`. Never quote one from memory. You have to correct a wrong one in public.

Then build a plan and hand it to `apply.ts`, which lives beside this file:

```bash
~/.claude/skills/address-review/apply.ts PLAN.json
```

It sends every reply at once, then every vote and resolve at once. Two rounds rather than one pass per item, so a vote never lands on a thread ahead of the reply that explains it. Every reply posts publicly the moment it is sent. Where a reply fails, that item's vote and resolve are skipped, so no thread ends up voted and closed with nothing said in it. Running the same plan twice is safe: a reply already on the thread in your name is reported as `duplicate` and not sent again.

One object per piece of feedback:

```json
[
  { "ref": "useFoo.ts:24",
    "threadId": "PRRT_kwDO...",
    "commentId": "PRRC_kwDO...",
    "bodyFile": "/tmp/reply-usefoo.md",
    "vote": "THUMBS_UP",
    "resolve": true },
  { "ref": "review body (alice)",
    "prId": "PR_kwDO...",
    "commentId": "PRR_kwDO...",
    "bodyFile": "/tmp/reply-alice.md",
    "vote": "THUMBS_DOWN" }
]
```

- `ref` labels the row in the output. Use the name the summary table will use.
- `threadId` replies into an inline thread. `prId` posts a new conversation comment instead, which is how a review body and a conversation comment get answered, so open those bodies with the author's `@login`. Exactly one of the two.
- `commentId` is what the vote lands on: the first comment in the thread, or the review or conversation node itself. Never your own reply.
- `bodyFile` is a path, never the body itself. A double-quoted body runs every backticked identifier as a command and strips the code references out of the reply. Write the reply to a file whatever it contains, and do not judge that case by case.
- `vote` is `THUMBS_UP` or `THUMBS_DOWN`, or leave it out for no vote.
- `resolve` defaults to false, so a thread you mean to close needs `"resolve": true` on it.

Resolve every thread you replied to, the pushed-back ones included. A thread that has come back gets `"resolve": true` again. The only thread that stays open is the one case named in **Votes the user left**: the user voted a comment down and the claim holds up anyway. You cannot resolve a conversation comment, so the reply and the vote close it.

### What the vote means

The vote records one thing: whether the comment should be addressed. It is not a verdict on the reviewer, and it is not a score for how well the comment was written.

`THUMBS_UP` and `THUMBS_DOWN` are the only two reactions this skill uses. Never send `LAUGH`, `HOORAY`, `CONFUSED`, `HEART`, `ROCKET` or `EYES`, whatever the comment says.

- **`THUMBS_UP`** — the comment should be addressed. Vote it up when you fixed it, and when you agree with it but the fix is out of scope for this PR. Any author.
- **`THUMBS_DOWN`** — the comment should not be addressed. Cast it only on an automated comment, where it feeds the reviewer's own accuracy stats. Vote it down when you declined it: it misreads the code, the concern is already handled, or the change would be wrong.
- **No vote** — every other case. That covers a declined human comment, a question you asked instead of making a call, and an outdated thread.

Never vote a human's comment down. The reply carries the decline, and it says why.

Vote on the comment that raised the point, which is the first comment in the thread. Do not vote on your own reply. One vote per comment, and any vote you cast must match what the reply says. A reply that declines and a thumbs up next to it read as a contradiction.

Undo a vote with `~/.claude/skills/address-review/unvote.sh COMMENT_URL`. A vote on a review body cannot be undone at all, so be sure of that one before casting it.

A comment the user already voted on keeps their vote. It is on the same account as yours, so do not add to it, change it or remove it. Your reply carries your call on those.

Vote the review bodies and the conversation comments the same way, with their own node id as the item's `commentId`. Skip the vote where nothing is raised to act on, an "LGTM" body included.

### Local

Make the fixes and commit them in small logical commits the same way. Nothing here has a thread to reply into or a comment to vote on, so the plan above has no per-item rows.

Where the branch has an open PR, push and leave one comment on it saying what changed this round and why. The review happened off the PR, so without that comment the branch grows commits nothing on the PR accounts for. Keep it to a line per point, each naming its sha, in the voice below.

It goes through `apply.ts` as a single item carrying a `prId` and a `bodyFile` and nothing else, which posts it as a conversation comment. An identical body already posted in your name comes back as `duplicate`.

```json
[{ "ref": "round summary", "prId": "PR_kwDO...", "bodyFile": "/tmp/round.md" }]
```

`gh pr view --json id --jq .id` is where that `prId` comes from when no `fetch.sh` ran this pass.

That comment is the only place the round goes. Never move it, or any part of it, into the PR description. The description follows the rule in **Finishing**, the same as on any other pass.

With no PR on the branch, nothing is pushed unless the user asks and the summary is the whole of the output. Leave the feedback file itself as it is either way.

## Reply voice

For everything this skill writes: the thread replies, the round comment a local pass leaves, any follow-up issue it opens, and the summary at the end.

**Keep every reply short.** One or two sentences. Three at the outside, and only when a decline needs a second line of evidence. Lead with the outcome. Cut any sentence that does not change what the reviewer does next.

**Write it in simple technical English.** One idea per sentence. Active voice, and name who did what. Simple present or simple past. No `-ing` verb forms, no idiom, no slang, no metaphor. Write "removes" not "bails", "starts" not "kicks off". Use the same word for the same thing each time. Drop the words that add emphasis and no information: "just", "simply", "actually", "really", "basically".

**Cut what the reviewer can already see.** They have their own comment, the file and the line the thread sits on, the diff, and the sha you linked. So none of this goes in a reply:

- Their point, said back to them.
- The file or line the thread is anchored to, named on its own. A line reference that carries evidence stays.
- "I agree", "good catch", "as you suggested", "you're right".
- A description of a change the linked sha already shows.
- An offer to do more work, or a question about whether they are happy.
- A restatement of the outcome in a second sentence.

**Fixed.** Say what changed, in one sentence. "Moved the normalisation into the transformer." A commit sha beats a description of the change, and a sha the reviewer can click beats a bare one. Link every sha you name to its commit:

```
Moved the normalisation into the transformer ([`a1b2c3d`](https://github.com/OWNER/REPO/commit/a1b2c3d4e5f6789012345678901234567890abcd)).
```

Short sha as the link text, full sha in the href, read back together with `git log -1 --format='%h %H'`. Same for a review body or conversation reply.

**Declined.** Point at the code that answers the comment: "`useFoo` returns early when the ref is null on line 24, so the extra check is dead code." A reviewer can check a line reference, they cannot check an assertion. Stop there. Do not add a closing offer.

Never argue. If a thread turns into back and forth, say so and take it off the PR.

Save the detail for the user-facing summary at the end. That is where length is allowed, not the PR.

## Finishing

**Re-read the feedback before the summary.** Run `fetch.sh` again — the pass took time, and a reviewer may have commented during it. On local feedback, read the file again for the same reason, and check whether the user has said anything since the invocation that changes the ask. Anything the first read missed goes through the same decide, reply, vote, resolve loop, and then query once more. A thread you have just answered drops out of the next read, because your reply is the last comment on it. Only write the summary when a fresh query comes back with nothing left to act on.

**Bring the PR description up to date.** Read the PR body once the re-read above comes back with nothing left to act on. This covers a local pass too, wherever the branch has an open PR. With no PR there is nothing to do here. The fixes this pass made can change what the branch does, or make a claim in the body false. Where either happened, write the body again from scratch under `create-pr` step 6, and post it with `pr-body.sh`. Where the fixes changed nothing the body states, leave the body as it is. Do this once, here, not once per comment.

Never patch the body round by round. Do not append a paragraph that answers this review. Do not add a revision history, in a `<details>` block or anywhere else. Do not leave a note beside a claim saying the claim no longer holds: remove the claim. A body that is edited line by line grows on every pass and ends up contradicting itself. The reviewer needs the branch as it stands, not the path it took to get there.

The summary goes to the user, and it is the last thing the pass produces. Write it once the fixes are pushed and every thread is settled, so the shas and the outcomes in it are real.

Lead with a table, one row per piece of feedback, in query order:

| Comment | Outcome | Change |
| --- | --- | --- |
| [`useFoo.ts:24`](COMMENT_URL) | Fixed | Moved the normalisation into the transformer (`a1b2c3d`) |
| [`Bar.vue:88`](COMMENT_URL) | Declined | The null guard on line 24 already covers it |
| [`Baz.ts:12`](COMMENT_URL) | Out of scope | Tracked in #418 |

How to fill it in:

- Link every row to its `url`, so the user can read the feedback without hunting for it. A local item has no url: label it `path:line` and leave it unlinked.
- Use one of seven outcomes and nothing else: Fixed, Worked around, Declined, Out of scope, Asked, Outdated, Acknowledged. Acknowledged is for a thread that came back only to accept the last answer, so it is PR-only.
- Fixed means the problem is gone. A change that hides the symptom is Worked around, and that row names the real fix.
- Name the commit sha for every fix.
- Keep each Change cell to one line.
- Write the Change cell in the same simple technical English as the replies. The same cuts apply.
- Do not repeat the Outcome word in the Change cell. "Fixed" beside "Fixed the null guard" says it twice.
- Do not repeat the file or the line from the Comment cell.
- Give the review bodies and the conversation comments a row each. Mark the Comment cell on any row that is not inline: `review body` or `conversation`.

Then, under the table, the parts a table cannot hold. Add only what the table cannot carry. Never restate a row:

- Every comment the user voted up, or said out loud that they wanted, that you declined anyway, with the reason. This one goes first.
- Every thread that came back from an earlier pass, and whether the reviewer's answer moved your call.
- Anything you resolved on thin reasoning.
- Every point you worked around rather than fixed, and what the real fix is.
- Any thread you left open, and any automated comment you left unvoted.
- Anything that needs the user's call.

A resolved thread is easy for the reviewer to scroll past, so the user should know where you closed a door on their behalf.
