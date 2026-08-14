---
name: address-review
description: Work through the review comments on a GitHub PR. Fix what should be fixed, reply with the reasoning where it should not, then resolve every thread. Use when a review lands on a PR and the user says "address the review", "fix the review comments", "respond to the review", "handle this review", or points at review feedback to act on.
user-invocable: true
---

# Address review

Take every unresolved review thread on the PR to a conclusion: fix it or push back, reply either way, then resolve it. If no PR was named, use the open PR for the current branch.

## Reading the threads

REST does not expose thread resolution state, so read them over GraphQL. The `id` on each thread is the node id the reply and resolve mutations need.

```bash
gh api graphql -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id isResolved isOutdated path line
          comments(first:20) { nodes { author { login } body } }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F number=N \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

Read the top level review bodies too. General feedback often never becomes an inline thread, and it is the part most likely to be missed.

```bash
gh pr view <number> --json reviews --jq '.reviews[] | {author: .author.login, state, body}'
```

## Deciding

The goal is the right call on each comment. Agreeing and disagreeing are both fine outcomes, neither one is the target.

So check the claim before acting on it. Read the surrounding file, not only the diff hunk, and where a comment describes a bug, trace the path that would produce it. A reviewer working from a hunk in isolation will sometimes flag something the wider file already handles. Apply the same standard whoever wrote the comment. A senior reviewer and an automated one both get checked, and both are usually right.

Fix it when the claim holds up, and when the reviewer is pointing at a real risk even if their suggested fix is not the one you would pick. Say so when it does not hold up: the comment misreads the code, the change would break something not visible from the diff, the problem it describes cannot be reproduced, or it asks for an abstraction the codebase has not earned yet.

A thread with `isOutdated: true` usually means the code moved on. Check whether the concern still applies before spending effort on it.

Where a comment is genuinely ambiguous, ask in the reply rather than guessing at what the reviewer meant.

## Applying and replying

Make the fixes, commit them in small logical commits, and push to the PR branch **before** replying. The reply should point at code that is already on the PR.

Then reply to each thread and resolve it:

```bash
gh api graphql -f query='
mutation($threadId:ID!, $body:String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { url }
  }
}' -F threadId=THREAD_ID -F body='...'

gh api graphql -f query='
mutation($threadId:ID!) {
  resolveReviewThread(input: {threadId: $threadId}) { thread { isResolved } }
}' -F threadId=THREAD_ID
```

Resolve every thread you replied to, the pushed-back ones included. Nothing is left open.

## Reply voice

The same collaborative register as the `review-pr` skill, from the other side of the table.

**Fixed.** Say what changed, briefly. "Good catch, moved the normalisation into the transformer." A commit sha beats a description of the change.

**Declined.** Point at the code that answers the comment: "`useFoo` bails when the ref is null on line 24, so the extra check would be dead code." A reviewer can check a line reference, they cannot check an assertion. Leave room to be wrong, "happy to change it if you'd rather be explicit", and mean it.

Never argue. If a thread is turning into back and forth, say so and take it off the PR.

## Finishing

Summarise for the user: what was fixed, what was declined and why, and anything that needs their call. Call out anything resolved on thin reasoning. A resolved thread is easy for the reviewer to scroll past, so the user should know where you closed a door on their behalf.
