---
name: address-review
description: Work through the review feedback on a GitHub PR, across inline threads, review bodies and conversation comments. Fix what should be fixed, reply with the reasoning where it should not, vote each comment up or down, then resolve every thread that has one. Use when a review lands on a PR and the user says "address the review", "fix the review comments", "respond to the review", "handle this review", or points at review feedback to act on.
user-invocable: true
---

# Address review

Take every piece of unresolved feedback on the PR to a conclusion: fix it or push back, reply either way, vote the comment up or down, then resolve it. Inline threads are only one of three places feedback arrives. Then account for the whole pass to the user. If no PR was named, use the open PR for the current branch.

## Reading the feedback

**Query first, every time.** Read the feedback from the API as the first action of the pass, before anything else. A read from earlier in this conversation is stale and cannot be reused: reviewers add comments while a pass is running, and a second invocation minutes after the first usually means something landed in between. So an earlier query result, an earlier summary, or a recollection of what the threads said is never the input here. Nothing is up to date until this query says so, and "I just read this" is not evidence that it is.

```bash
~/.claude/skills/address-review/fetch.sh [PR]
```

Feedback arrives in three places on a PR: inline review threads, review bodies, and conversation comments. This reads all three in one go, keeps only the unresolved threads, and defaults to the open PR for the current branch.

Skip anything `viewer` wrote themselves, and skip the CI and coverage chatter a PR collects. Keep every `url`. The summary at the end links its rows by them.

Which id becomes which plan field: `threads[].id` is a `threadId` and `threads[].comments[0].id` is that item's `commentId`; `reviews[].id` and `conversation[].id` are each their own `commentId`, and both take the `prId`, since neither has a thread to reply into. A review body carries a vote, and the user's vote, the same way a comment does.

`userVotes` marks the comments the user voted on, which the next section weighs.

A review body often never becomes an inline thread, and a reviewer often raises their main point in the conversation rather than against a line. Those two are the easiest to miss.

## Deciding

The goal is the right call on each comment. Agreeing and disagreeing are both fine outcomes, neither one is the target.

So check the claim before acting on it. Read the surrounding file, not only the diff hunk, and where a comment describes a bug, trace the path that would produce it. A reviewer working from a hunk in isolation will sometimes flag something the wider file already handles. Apply the same standard whoever wrote the comment. A senior reviewer and an automated one both get checked, and both are usually right.

Fix it when the claim holds up, and when the reviewer is pointing at a real risk even if their suggested fix is not the one you would pick. Say so when it does not hold up: the comment misreads the code, the change would break something not visible from the diff, the problem it describes cannot be reproduced, or it asks for an abstraction the codebase has not earned yet.

A thread with `isOutdated: true` usually means the code moved on. Check whether the concern still applies before spending effort on it.

Where a comment is genuinely ambiguous, ask in the reply rather than guessing at what the reviewer meant.

### Votes the user left

The user votes on review comments too, with the same two reactions. A vote from the user is the one vote that carries weight here. It says they read the comment and formed a view on it before you got to it. Reactions from anyone else are not that signal, and the `userVotes` field leaves them out.

Read the votes before you cast any of your own. `gh` runs as the user's account, so once this skill reacts, its reaction is indistinguishable from theirs. Two things keep them apart: only unresolved threads are in scope, and every thread this skill votes on gets resolved.

**`THUMBS_UP` from the user.** They value the comment. Treat it with more reverence than the rest. Reverence is a higher bar for declining, not agreement by default, so check the claim exactly as carefully. Then:

- Read the whole file and trace the failure path before declining it. The decline needs a line reference, not an assertion.
- Take the fix where the call is close.
- An out of scope answer needs a follow-up issue or task, and the reply names it.
- Tell the user in the summary if you declined it anyway. They may want to reverse that.

**`THUMBS_DOWN` from the user.** They do not want the comment addressed. Take that as the decision and decline it. One exception: where checking the claim turns up a real defect, do not close the thread on it. Leave that thread open and put the evidence in the summary, so the user can change their mind.

## Applying, voting and replying

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

Read the plan back with `--dry-run` before it goes out.

Resolve every thread you replied to, the pushed-back ones included. The only thread that stays open is the one case named in **Votes the user left**: the user voted a comment down and the claim holds up anyway. You cannot resolve a conversation comment, so the reply and the vote close it.

### What the vote means

The vote records one thing: whether the comment should be addressed. It is not a verdict on the reviewer, and it is not a score for how well the comment was written.

`THUMBS_UP` and `THUMBS_DOWN` are the only two reactions this skill uses. Never send `LAUGH`, `HOORAY`, `CONFUSED`, `HEART`, `ROCKET` or `EYES`, whatever the comment says.

- **`THUMBS_UP`** — the comment should be addressed. Vote it up when you fixed it, and when you agree with it but the fix is out of scope for this PR.
- **`THUMBS_DOWN`** — the comment should not be addressed. Vote it down when you declined it: it misreads the code, the concern is already handled, or the change would be wrong.
- **No vote** — you have not decided. Leave a comment unvoted when you asked the reviewer a question instead of making a call, and when a thread is outdated so the point no longer applies either way.

Vote on the comment that raised the point, which is the first comment in the thread. Do not vote on your own reply. One vote per comment, and any vote you cast must match what the reply says. A reply that declines and a thumbs up next to it read as a contradiction.

Undo a vote with `~/.claude/skills/address-review/unvote.sh COMMENT_URL`. A vote on a review body cannot be undone at all, so be sure of that one before casting it.

A comment the user already voted on keeps their vote. It is on the same account as yours, so do not add to it, change it or remove it. Your reply carries your call on those.

Vote the review bodies and the conversation comments the same way, with their own node id as the item's `commentId`. Skip the vote where nothing is raised to act on, an "LGTM" body included.

## Reply voice

The same collaborative register as the `review-pr` skill, from the other side of the table.

**Keep every reply short.** One or two sentences. Three at the outside, and only when a decline needs a second line of evidence. The reviewer already knows the context, so do not restate their comment, do not recap the surrounding code, and do not explain your reasoning step by step. Lead with the outcome. Cut any sentence that does not change what the reviewer does next.

Do not open with filler ("Great point", "You're absolutely right"), do not close with an offer to do more work, and do not add headings, bullet lists or code blocks unless a diff is the shortest way to say it.

**Fixed.** Say what changed, in one sentence. "Moved the normalisation into the transformer." A commit sha beats a description of the change, and a sha the reviewer can click beats a bare one. Link every sha you name to its commit:

```
Moved the normalisation into the transformer ([`a1b2c3d`](https://github.com/OWNER/REPO/commit/a1b2c3d4e5f6789012345678901234567890abcd)).
```

Short sha as the link text, full sha in the href, read back together with `git log -1 --format='%h %H'`. Same for a review body or conversation reply.

**Declined.** Point at the code that answers the comment: "`useFoo` bails when the ref is null on line 24, so the extra check would be dead code." A reviewer can check a line reference, they cannot check an assertion. One line of "happy to change it if you'd rather be explicit" is enough, and mean it.

Never argue. If a thread is turning into back and forth, say so and take it off the PR.

Save the detail for the user-facing summary at the end. That is where length is allowed, not the PR.

## Finishing

**Re-read the feedback before the summary.** Run `fetch.sh` again. The pass took time, and a reviewer may have commented during it. Anything unresolved that the first read missed goes through the same decide, reply, vote, resolve loop, and then query once more. Only write the summary when a fresh query comes back with nothing left to act on.

The summary goes to the user, and it is the last thing the pass produces. Write it once the fixes are pushed and every thread is settled, so the shas and the outcomes in it are real.

Lead with a table, one row per piece of feedback, in query order:

| Comment | Outcome | Change |
| --- | --- | --- |
| [`useFoo.ts:24`](COMMENT_URL) | Fixed | Moved the normalisation into the transformer (`a1b2c3d`) |
| [`Bar.vue:88`](COMMENT_URL) | Declined | The null guard on line 24 already covers it |
| [`Baz.ts:12`](COMMENT_URL) | Out of scope | Tracked in #418 |

How to fill it in:

- Link every row to its `url`, so the user can read the feedback without hunting for it.
- Use one of five outcomes and nothing else: Fixed, Declined, Out of scope, Asked, Outdated.
- Name the commit sha for every fix.
- Keep each Change cell to one line.
- Give the review bodies and the conversation comments a row each. Mark the Comment cell on any row that is not inline: `review body` or `conversation`.

Then, under the table, the parts a table cannot hold:

- Every comment the user voted up that you declined anyway, with the reason. This one goes first.
- Anything you resolved on thin reasoning.
- Any comment you left unvoted, and any thread you left open.
- Anything that needs the user's call.

A resolved thread is easy for the reviewer to scroll past, so the user should know where you closed a door on their behalf.
