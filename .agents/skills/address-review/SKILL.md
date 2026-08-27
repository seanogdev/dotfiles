---
name: address-review
description: Work through the review comments on a GitHub PR. Fix what should be fixed, reply with the reasoning where it should not, vote each comment up or down, then resolve every thread. Use when a review lands on a PR and the user says "address the review", "fix the review comments", "respond to the review", "handle this review", or points at review feedback to act on.
user-invocable: true
---

# Address review

Take every piece of unresolved feedback on the PR to a conclusion: fix it or push back, reply either way, vote the comment up or down, then resolve it. Inline threads are only one of the three places it arrives, and the other two are the easiest to miss. Then account for the whole pass to the user. If no PR was named, use the open PR for the current branch.

## Reading the feedback

REST does not expose thread resolution state, so read them over GraphQL. The `id` on each thread is the node id the reply and resolve mutations need. The `id` on each comment is the node id the vote mutation needs. `viewerHasReacted` marks the comments the user voted on, which the next section weighs.

```bash
gh api graphql -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id isResolved isOutdated path line
          comments(first:20) {
            nodes {
              id url author { login } body
              reactionGroups { content viewerHasReacted }
            }
          }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F number=N \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[]
        | select(.isResolved == false)
        | .comments.nodes |= map({id, url, author: .author.login, body,
                                  userVotes: [.reactionGroups[] | select(.viewerHasReacted) | .content]})'
```

Keep each comment `url`. The summary at the end links its rows by them.

Read the top level review bodies too. General feedback often never becomes an inline thread, and it is the part most likely to be missed.

```bash
gh api graphql -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviews(first:50) {
        nodes {
          id url state author { login } body
          reactionGroups { content viewerHasReacted }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F number=N \
  --jq '.data.repository.pullRequest.reviews.nodes[]
        | select(.body != "")
        | {id, url, state, author: .author.login, body,
           userVotes: [.reactionGroups[] | select(.viewerHasReacted) | .content]}'
```

The `id` here is the review node id. A review body takes a vote, and carries the user's vote, the same way a comment does.

Read the comments on the PR itself last. These sit in the conversation, outside any review, and a reviewer will often raise the thing they care about most there rather than against a line.

```bash
gh api graphql -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      id
      comments(first:100) {
        nodes {
          id url author { login } body
          reactionGroups { content viewerHasReacted }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F number=N \
  --jq '{prId: .data.repository.pullRequest.id,
         comments: [.data.repository.pullRequest.comments.nodes[]
                    | {id, url, author: .author.login, body,
                       userVotes: [.reactionGroups[] | select(.viewerHasReacted) | .content]}]}'
```

Skip the ones the user wrote themselves, and skip the bot noise a PR collects. Keep the `prId`, the reply mutation needs it. There is no thread and no resolution state here, so a conversation comment is in scope until the reply and the vote are on it.

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

Make the fixes, commit them in small logical commits, and push to the PR branch **before** replying. The reply should point at code that is already on the PR.

Then vote on each comment, reply to its thread, and resolve the thread:

```bash
gh api graphql -f query='
mutation($subjectId:ID!, $content:ReactionContent!) {
  addReaction(input: {subjectId: $subjectId, content: $content}) { reaction { content } }
}' -F subjectId=COMMENT_ID -F content=THUMBS_UP

gh api graphql -f query='
mutation($threadId:ID!, $body:String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { url }
  }
}' -F threadId=THREAD_ID -f body='...'

gh api graphql -f query='
mutation($threadId:ID!) {
  resolveReviewThread(input: {threadId: $threadId}) { thread { isResolved } }
}' -F threadId=THREAD_ID
```

Pass the body with `-f`, never `-F`. `-F` reads the value from a file when it starts with `@`, and a reply that opens with a mention is the common case.

A review body and a conversation comment have no thread to reply into. Answer both with a comment on the PR, using the `prId` from the query, and open it with the author's `@login` so the reply reads as an answer to their point rather than a stray remark:

```bash
gh api graphql -f query='
mutation($subjectId:ID!, $body:String!) {
  addComment(input: {subjectId: $subjectId, body: $body}) { commentEdge { node { url } } }
}' -F subjectId=PR_ID -f body='...'
```

Resolve every thread you replied to, the pushed-back ones included. The only thread that stays open is the one case named in **Votes the user left**: the user voted a comment down and the claim holds up anyway. Nothing in the conversation resolves, so there the reply and the vote are the whole close.

### What the vote means

The vote records one thing: whether the comment should be addressed. It is not a verdict on the reviewer, and it is not a score for how well the comment was written.

`THUMBS_UP` and `THUMBS_DOWN` are the only two reactions this skill uses. Never send `LAUGH`, `HOORAY`, `CONFUSED`, `HEART`, `ROCKET` or `EYES`, whatever the comment says.

- **`THUMBS_UP`** — the comment should be addressed. Vote it up when you fixed it, and when you agree with it but the fix is out of scope for this PR.
- **`THUMBS_DOWN`** — the comment should not be addressed. Vote it down when you declined it: it misreads the code, the concern is already handled, or the change would be wrong.
- **No vote** — you have not decided. Leave a comment unvoted when you asked the reviewer a question instead of making a call, and when a thread is outdated so the point no longer applies either way.

Vote on the comment that raised the point, which is the first comment in the thread. Do not vote on your own reply. One vote per comment, and any vote you cast must match what the reply says. A reply that declines and a thumbs up next to it read as a contradiction.

A comment the user already voted on keeps their vote. It is on the same account as yours, so do not add to it, change it or remove it. Your reply carries your call on those.

Vote the top level review bodies and the conversation comments the same way, using the review or comment node id as `subjectId`. A review body that only says "LGTM" needs no vote, and neither does a conversation comment that raises nothing to act on.

## Reply voice

The same collaborative register as the `review-pr` skill, from the other side of the table.

**Keep every reply short.** One or two sentences. Three at the outside, and only when a decline needs a second line of evidence. The reviewer already knows the context, so do not restate their comment, do not recap the surrounding code, and do not explain your reasoning step by step. Lead with the outcome. Cut any sentence that does not change what the reviewer does next.

Do not open with filler ("Great point", "You're absolutely right"), do not close with an offer to do more work, and do not add headings, bullet lists or code blocks unless a diff is the shortest way to say it.

**Fixed.** Say what changed, in one sentence. "Moved the normalisation into the transformer." A commit sha beats a description of the change.

**Declined.** Point at the code that answers the comment: "`useFoo` bails when the ref is null on line 24, so the extra check would be dead code." A reviewer can check a line reference, they cannot check an assertion. One line of "happy to change it if you'd rather be explicit" is enough, and mean it.

Never argue. If a thread is turning into back and forth, say so and take it off the PR.

Save the detail for the user-facing summary at the end. That is where length is allowed, not the PR.

## Finishing

The summary goes to the user, and it is the last thing the pass produces. Write it once the fixes are pushed and every thread is settled, so the shas and the outcomes in it are real.

Lead with a table, one row per piece of feedback, in the order it came back from the queries, inline threads first:

| Comment | Outcome | Change |
| --- | --- | --- |
| [`useFoo.ts:24`](COMMENT_URL) | Fixed | Moved the normalisation into the transformer (`a1b2c3d`) |
| [`Bar.vue:88`](COMMENT_URL) | Declined | The null guard on line 24 already covers it |
| [`Baz.ts:12`](COMMENT_URL) | Out of scope | Tracked in #418 |

How to fill it in:

- Link every row to the comment `url`, so the user can read the thread without hunting for it.
- Use one of five outcomes and nothing else: Fixed, Declined, Out of scope, Asked, Outdated.
- Name the commit sha for every fix.
- Keep each Change cell to one line.
- Give the top level review bodies and the conversation comments a row each, linked by their own `url`. Mark the source in the Comment cell where the row is not an inline one, `review body` or `conversation`, so the user can see the feedback outside the diff was covered.

Then, under the table, the parts a table cannot hold:

- Every comment the user voted up that you declined anyway, with the reason. This one goes first.
- Anything you resolved on thin reasoning.
- Any comment you left unvoted, and any thread you left open.
- Anything that needs the user's call.

A resolved thread is easy for the reviewer to scroll past, so the user should know where you closed a door on their behalf.
