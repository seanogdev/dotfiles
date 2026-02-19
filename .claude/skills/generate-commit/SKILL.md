---
name: generate-commit
description: Stages changes and generates clear commit messages following conventional commit format. Use when the user asks to commit, is ready to save their work, or wants a commit message generated.
---

# Generating Commit Messages

## Instructions

1. Run `git status` to see staged and unstaged changes. Stage specific files with `git add <file>` — never `git add .` or `git add -A` to avoid accidentally including sensitive files.
2. Run `git diff --staged` to see staged changes
3. Suggest a single-sentence commit message under 72 characters
4. Use conventional commit format (feat:, fix:, docs:, style:, refactor:, test:, chore:)
5. Ensure clarity and context for future reference

## Best practices

- Use present tense
- Explain what and why, not how
