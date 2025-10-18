---
name: Generating Commit Messages
description: Generates clear commit messages from git diffs. Use when writing commit messages or reviewing staged changes.
---

# Generating Commit Messages

## Instructions

1. Run `git diff --staged` to see changes
2. I'll suggest a commit message with:
   - Summary under 50 characters
   - Detailed description
   - Affected files
3. Use conventional commit format (feat:, fix:, docs:, style:, refactor:, test:, chore:)
4. Ensure clarity and context for future reference

## Best practices

- Use present tense
- Explain what and why, not how
