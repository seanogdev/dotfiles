---
name: address-review
description: Take every comment in a code review to a conclusion, on a GitHub PR or on a local review. Use when a review lands and the user says "address the review", "fix the review comments", "respond to the review", "handle this review", "work through the feedback in review.md", or points at review feedback to act on.
argument-hint: "[PR number, url or branch, or a path to a review file]"
user-invocable: true
---

# Address review

Take every item of live feedback to a conclusion. Fix it, or push back on it. Then account for the whole pass to the user. On a PR, also reply either way, vote on the comment, and resolve the thread. Inline threads are only one of three places feedback arrives.

## Where the feedback is

**A PR.** The default. If no PR was named, use the open PR for the current branch.

**Local.** A review that sits in this conversation: a `/code-review` report, a pasted set of comments, or the user listing what they want changed. A file the user points at is local too. Deciding and fixing are the same.

`$ARGUMENTS` holds what the user typed after the skill name. It is empty when they gave nothing.

Route the invocation like this:

- A path or an `@file` in the invocation means the file.
- The user pointing at feedback already in the conversation ("address that", "fix those", "work through the review above") with no PR named means the conversation.
- Otherwise it is the PR.
- If the user names both, read both. Run each under its own rules. Then give one summary that covers the lot.

If the feedback is local, read `~/.claude/skills/address-review/references/local.md`.

## Reading the feedback

### On a PR

**Query first, every time.** Read the feedback from the API as the first action of the pass. A read from earlier in this conversation is stale. Do not reuse it. Reviewers add comments while a pass runs. A second invocation minutes after the first usually means something landed in between.

```bash
~/.claude/skills/address-review/fetch.sh [PR]
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

### Local

Read `~/.claude/skills/address-review/references/local.md`.

## Deciding

The goal is the right call on each comment. Agreeing and disagreeing are both fine outcomes. Neither one is the target.

Check the claim before you act on it. Read the surrounding file, not only the diff hunk. If a comment describes a bug, trace the path that produces it. A reviewer who works from a hunk in isolation sometimes flags something the wider file already handles. Apply the same standard whoever wrote the comment.

The comment was written against some commit, and the branch has probably moved since. Check the file as it stands now, not the snippet quoted in the comment and not the diff hunk it was raised against. A later commit can fix what the comment describes, move the line it points at, or change the code around it. If the line number or the quoted code no longer matches the file, that gap is itself a sign the code moved on. The current version decides the call.

Fix it if the claim holds up. Fix it also if the reviewer points at a real risk, even where you would pick a different fix. Say so if it does not hold up. Decline it in these cases:

- The comment misreads the code.
- The change breaks something that the diff does not show.
- The problem it describes cannot be reproduced.
- It asks for an abstraction the codebase has not earned yet.

A thread with `isOutdated: true` usually means the code moved on. Check if the concern still applies before you spend effort on it.

If a comment is ambiguous, ask. Do not guess what the reviewer meant. Ask in the reply on a PR. Ask the user directly if the feedback is local.

### Threads that have come back

`isResolved: true` on a thread means you settled it on an earlier pass and someone replied since. The earlier call is not binding. The reviewer read it and answered it. That is the case for deciding again, not for standing behind the first answer.

Read the whole thread, your own reply included. Treat the last comment as the live one. Then decide it as you decide any other comment. A reviewer who answers a decline with a path you did not trace has earned a second look. A reviewer who repeats the original point with nothing new behind it has not. Say so once more, and that is the whole reply.

If they accept the answer or say thanks, do nothing more: the thread stays resolved, it needs no plan item, and a row in the summary is the whole of it.

Otherwise reply, re-vote where the call moved, and resolve again. Reactions add, they do not replace. Clear the old vote with `unvote.sh` before you cast the new one. If the call moves to a decline on a human comment, `unvote.sh` is the whole action. No vote replaces the one you remove.

### Votes the user left

The user votes on review comments too, with the same two reactions. A vote from the user is the one vote that carries weight here. It says they read the comment and formed a view on it before you got to it. A reaction from anyone else is not that signal. The `userVotes` field leaves them out.

Read the votes before you cast any of your own. `gh` runs as the user's account, so once this skill reacts, its reaction is indistinguishable from theirs. Your own reply in the thread is what tells them apart. No reply from you means the vote is theirs. If you replied, the vote is yours from that pass, and the reply says which way it went. If the two disagree, the user changed it, and that disagreement is the signal.

**`THUMBS_UP` from the user.** They value the comment. Treat it with more reverence than the rest. Reverence is a higher bar for declining, not agreement by default. Check the claim as carefully as ever. Then:

- Read the whole file and trace the failure path before you decline it. The decline needs a line reference, not an assertion.
- Take the fix where the call is close.
- An out of scope answer needs a follow-up issue or task. The reply names it.
- If you declined it anyway, tell the user in the summary. They may want to reverse that.

**`THUMBS_DOWN` from the user.** They do not want the comment addressed. Take that as the decision and decline it. One exception: if the check turns up a real defect, do not close the thread on it. Leave that thread open. Put the evidence in the summary, so the user can change their mind.

## Applying, voting and replying

Fix the cause, not the symptom. Suppressing a warning, skipping a test, loosening an assertion or special-casing the reviewer's input is not a fix. If the real fix is out of scope, decline the comment.

Make the fixes. Commit them in small logical commits. Push to the PR branch **before** you reply. The reply must point at code that is already on the PR. Read every identifier back from its source before it goes in a public reply: the shas from `git log`, a line number from the file as it now stands, an issue number from `gh`. Never quote one from memory. A wrong one has to be corrected in public.

Then build a plan and hand it to `apply.ts`, which lives beside this file:

```bash
~/.claude/skills/address-review/apply.ts PLAN.json
```

It sends every reply at once. Then it sends every vote and resolve at once. Two rounds rather than one pass per item, so a vote never lands on a thread ahead of the reply that explains it. Every reply posts publicly the moment it is sent. If a reply fails, that item's vote and resolve are skipped. No thread ends up voted and closed with nothing said in it. Running the same plan twice is safe. A reply already on the thread in your name is reported as `duplicate` and is not sent again.

Read `~/.claude/skills/address-review/references/plan.md` for the plan format. Read it when you build the plan, not before.

Resolve every thread you replied to, the pushed-back ones included. A thread that has come back gets `"resolve": true` again. Only one thread stays open, the case named in **Votes the user left**: the user voted a comment down and the claim holds up anyway. You cannot resolve a conversation comment, so the reply and the vote close it.

### What the vote means

The vote records one thing: whether the comment should be addressed. It is not a verdict on the reviewer. It is not a score for how well the comment was written.

`THUMBS_UP` and `THUMBS_DOWN` are the only two reactions this skill uses. Never send `LAUGH`, `HOORAY`, `CONFUSED`, `HEART`, `ROCKET` or `EYES`, whatever the comment says.

- **`THUMBS_UP`**: the comment should be addressed. Vote it up when you fixed it. Vote it up when you agree with it but the fix is out of scope for this PR. Any author.
- **`THUMBS_DOWN`**: the comment should not be addressed. Cast it only on an automated comment, where it feeds the reviewer's own accuracy stats. Vote it down when you declined it: it misreads the code, the concern is already handled, or the change would be wrong.
- **No vote**: every other case. That covers a declined human comment, a question you asked instead of making a call, and an outdated thread.

Never vote a human's comment down. The reply carries the decline, and it says why.

Vote on the comment that raised the point, which is the first comment in the thread. Do not vote on your own reply. Cast one vote per comment. The vote must match what the reply says. A reply that declines and a thumbs up next to it read as a contradiction.

Undo a vote with `~/.claude/skills/address-review/unvote.sh COMMENT_URL`. A vote on a review body cannot be undone at all, so be sure of that one before you cast it.

A comment the user already voted on keeps their vote. It is on the same account as yours. Do not add to it, change it or remove it. Your reply carries your call on those.

Vote the review bodies and the conversation comments the same way, with their own node id as the item's `commentId`. Skip the vote where nothing is raised to act on, an "LGTM" body included.

### Local

Read `~/.claude/skills/address-review/references/local.md`.

## Reply voice

This covers everything this skill writes: the thread replies, the round comment a local pass leaves, any follow-up issue it opens, and the summary at the end.

**Keep every reply short.** One or two sentences. Three at the outside, and only when a decline needs a second line of evidence. Lead with the outcome. Cut any sentence that does not change what the reviewer does next.

**Write it in simple technical English.** One idea per sentence. Active voice. Name who did what. Simple present or simple past. No `-ing` verb forms. No idiom, no slang, no metaphor. Write "removes" not "bails", "starts" not "kicks off". Use the same word for the same thing each time. Drop the words that add emphasis and no information: "just", "simply", "actually", "really", "basically".

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

Short sha as the link text. Full sha in the href. Read the two back together with `git log -1 --format='%h %H'`. Use the same format in a review body reply or a conversation reply.

**Declined.** Point at the code that answers the comment: "`useFoo` returns early when the ref is null on line 24, so the extra check is dead code." A reviewer can check a line reference. A reviewer cannot check an assertion. Stop there. Do not add a closing offer.

Never argue. If a thread turns into back and forth, say so and take it off the PR.

Save the detail for the user-facing summary at the end. That is where length is allowed, not the PR.

## Finishing

**Re-read the feedback before the summary.** Run `fetch.sh` again. The pass took time, and a reviewer may have commented during it. On local feedback, read the file again for the same reason. Also check whether the user has said anything since the invocation that changes the ask. Anything the first read missed goes through the same decide, reply, vote and resolve loop. Then query once more. A thread you have just answered drops out of the next read, because your reply is the last comment on it. Write the summary only when a fresh query comes back with nothing left to act on.

**Bring the PR description up to date.** Read the PR body once the re-read above comes back with nothing left to act on. This covers a local pass too, wherever the branch has an open PR. With no PR there is nothing to do here. The fixes this pass made can change what the branch does, or make a claim in the body false. If either happened, write the body again from scratch under `create-pr` step 6, and post it with `pr-body.sh`. If the fixes changed nothing the body states, leave the body as it is. Do this once, here, not once per comment.

Never patch the body round by round. Do not append a paragraph that answers this review. Do not add a revision history, in a `<details>` block or anywhere else. Do not leave a note beside a claim that says the claim no longer holds: remove the claim. A body that is edited line by line grows on every pass and ends up contradicting itself. The reviewer needs the branch as it stands, not the path it took to get there.

The summary goes to the user. It is the last thing the pass produces. Write it once the fixes are pushed and every thread is settled, so the shas and the outcomes in it are real.

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

Then, under the table, add the parts a table cannot hold. Add only what the table cannot carry. Never restate a row:

- Every comment the user voted up, or said out loud that they wanted, that you declined anyway, with the reason. This one goes first.
- Every thread that came back from an earlier pass, and whether the reviewer's answer moved your call.
- Anything you resolved on thin reasoning.
- Every point you worked around rather than fixed, and what the real fix is.
- Any thread you left open, and any automated comment you left unvoted.
- Anything that needs the user's call.

A resolved thread is easy for the reviewer to scroll past. The user should know where you closed a door on their behalf.
