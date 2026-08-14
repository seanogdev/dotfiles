---
name: pr-description
description: Write a GitHub pull request description in Sean's format, with a Changes summary and a collapsible per-file table. Use when opening a PR, running `gh pr create`, or when the user asks to write, draft or update a PR description or PR body.
---

# PR description

Check for a repository template first (`.github/PULL_REQUEST_TEMPLATE.md`, or one of the files in `.github/PULL_REQUEST_TEMPLATE/`). If there is one, fill it in and fit the two sections below into it rather than replacing it.

**Changes.** A top level bullet list summarising the PR. Say what changed and why it matters, not a line-by-line restatement of the diff.

**File table.** A collapsible table covering every changed file, with a very short note on how each one changed.

```markdown
<details>
<summary>Files changed</summary>

| File | Change |
| ---- | ------ |
| `src/api/client.ts` | Added the retry wrapper |
| `src/api/client.test.ts` | Covers the new backoff path |

</details>
```

Complete sentences and proper punctuation, no em dashes.
