# A PR

Read this file when the feedback is on a GitHub PR. That is the default mode. The rules that decide each comment live in `SKILL.md`.

Each path below is relative to the skill directory, the one that holds `SKILL.md`. Expand it to a full path before you run a command.

## Reading the feedback

**Query first, every time.** Read the feedback from the API as the first action of the pass. A read from earlier in this conversation is stale. Do not reuse it. Reviewers add comments while a pass runs. A second invocation minutes after the first usually means something landed in between.

```bash
./scripts/fetch.sh [PR]
```

Pass `$ARGUMENTS` as the `[PR]` argument only when it names a PR. A review file path must never reach this command.

Feedback arrives in three places on a PR: inline review threads, review bodies, and conversation comments. This command reads all three at once. It keeps the threads that are still live. It defaults to the open PR for the current branch.

Still live means unresolved, plus any thread you replied in that someone spoke on since. GitHub leaves a thread resolved when a new comment lands on it. Without this rule, a reviewer who answers the reply you closed a thread with never reaches the next pass. Those threads come back with `isResolved: true`.

Skip anything `viewer` wrote. Skip the CI and coverage chatter a PR collects. Your own replies inside a thread are the exception. They are what the reviewer answers, so read them. Keep every `url`. The summary at the end links its rows by them.

Each id becomes a plan field:

| Source field | Plan field |
| --- | --- |
| `threads[].id` | `threadId` |
| `threads[].comments[0].id` | `commentId` |
| `reviews[].id` | `commentId`, plus the `prId` |
| `conversation[].id` | `commentId`, plus the `prId` |

A review body and a conversation comment have no thread to reply into. That is why each one takes the `prId`. A review body carries a vote, and the user's vote, the same way a comment does.

`userVotes` marks the comments the user voted on. The next section weighs them. `isBot` is true where a GitHub App wrote the comment, and **What the vote means** turns on it. An automated reviewer that runs on a machine user account comes back false, so read the author too.

A review body often never becomes an inline thread. A reviewer often raises the main point in the conversation, not against a line. Those two are the easiest to miss.

## Threads that have come back

A thread with `isOutdated: true` usually means the code moved on. Check if the concern still applies before you spend effort on it.

`isResolved: true` on a thread means you settled it on an earlier pass and someone replied since. The earlier call is not binding. The reviewer read it and answered it. That is the case for deciding again, not for standing behind the first answer.

Read the whole thread, your own reply included. Treat the last comment as the live one. Then decide it as you decide any other comment. A reviewer who answers a decline with a path you did not trace has earned a second look. A reviewer who repeats the original point with nothing new behind it has not. Say so once more, and that is the whole reply.

If they accept the answer or say thanks, do nothing more: the thread stays resolved, it needs no plan item, and a row in the summary is the whole of it.

Otherwise reply, re-vote where the call moved, and resolve again. Reactions add, they do not replace. Clear the old vote with `scripts/unvote.sh` before you cast the new one. If the call moves to a decline on a human comment, `scripts/unvote.sh` is the whole action. No vote replaces the one you remove.

## Votes the user left

The user votes on review comments too, with the same two reactions. A vote from the user is the one vote that carries weight here. It says they read the comment and formed a view on it before you got to it. A reaction from anyone else is not that signal. The `userVotes` field leaves them out.

Read the votes before you cast any of your own. `gh` runs as the user's account, so once this skill reacts, its reaction is indistinguishable from theirs. Your own reply in the thread is what tells them apart. No reply from you means the vote is theirs. If you replied, the vote is yours from that pass, and the reply says which way it went. If the two disagree, the user changed it, and that disagreement is the signal.

**`THUMBS_UP` from the user.** They value the comment. Treat it with more reverence than the rest. Reverence is a higher bar for declining, not agreement by default. Check the claim as carefully as ever. Then:

- Read the whole file and trace the failure path before you decline it. The decline needs a line reference, not an assertion.
- Take the fix where the call is close.
- An out of scope answer needs a follow-up issue or task. The reply names it.
- If you declined it anyway, tell the user in the summary. They may want to reverse that.

**`THUMBS_DOWN` from the user.** They do not want the comment addressed. Take that as the decision and decline it. One exception: if the check turns up a real defect, do not close the thread on it. Leave that thread open. Put the evidence in the summary, so the user can change their mind.

## Applying, voting and replying

Then build a plan and hand it to `apply.ts`, which lives in the skill's `scripts/` directory:

```bash
./scripts/apply.ts PLAN.json
```

It sends every reply at once. Then it sends every vote and resolve at once. Two rounds rather than one pass per item, so a vote never lands on a thread ahead of the reply that explains it. Every reply posts publicly the moment it is sent. If a reply fails, that item's vote and resolve are skipped. No thread ends up voted and closed with nothing said in it. Running the same plan twice is safe. A reply already on the thread in your name is reported as `duplicate` and is not sent again.

Resolve every thread you replied to, the pushed-back ones included. A thread that has come back gets `"resolve": true` again. Only one thread stays open, the case named in **Votes the user left**: the user voted a comment down and the claim holds up anyway. You cannot resolve a conversation comment, so the reply and the vote close it.

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
- `threadId` replies into an inline thread. `prId` posts a new conversation comment instead, which is how a review body and a conversation comment get answered. Open those bodies with the author's `@login`. Give exactly one of the two.
- `commentId` is what the vote lands on: the first comment in the thread, or the review or conversation node itself. Never your own reply.
- `bodyFile` is a path, never the body itself. A double-quoted body runs every backticked identifier as a command and strips the code references out of the reply. Write the reply to a file whatever it contains. Do not judge that case by case.
- `vote` is `THUMBS_UP` or `THUMBS_DOWN`. Leave it out for no vote.
- `resolve` defaults to false. A thread you mean to close needs `"resolve": true` on it.

## What the vote means

The vote records one thing: whether the comment should be addressed. It is not a verdict on the reviewer. It is not a score for how well the comment was written.

`THUMBS_UP` and `THUMBS_DOWN` are the only two reactions this skill uses. Never send `LAUGH`, `HOORAY`, `CONFUSED`, `HEART`, `ROCKET` or `EYES`, whatever the comment says.

- **`THUMBS_UP`**: the comment should be addressed. Vote it up when you fixed it. Vote it up when you agree with it but the fix is out of scope for this PR. Any author.
- **`THUMBS_DOWN`**: the comment should not be addressed. Cast it only on an automated comment, where it feeds the reviewer's own accuracy stats. Vote it down when you declined it: it misreads the code, the concern is already handled, or the change would be wrong.
- **No vote**: every other case. That covers a declined human comment, a question you asked instead of making a call, and an outdated thread.

Never vote a human's comment down. The reply carries the decline, and it says why.

Vote on the comment that raised the point, which is the first comment in the thread. Do not vote on your own reply. Cast one vote per comment. The vote must match what the reply says. A reply that declines and a thumbs up next to it read as a contradiction.

Undo a vote with `./scripts/unvote.sh COMMENT_URL`. A vote on a review body cannot be undone at all, so be sure of that one before you cast it.

A comment the user already voted on keeps their vote. It is on the same account as yours. Do not add to it, change it or remove it. Your reply carries your call on those.

Vote the review bodies and the conversation comments the same way, with their own node id as the item's `commentId`. Skip the vote where nothing is raised to act on, an "LGTM" body included.
