# The apply.ts plan

Read this file when you build the plan for `apply.ts`. The rules that decide a reply, a vote and a resolve live in `SKILL.md`.

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
