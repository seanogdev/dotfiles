#!/usr/bin/env bash
cwd=$(jq -r '.cwd')
case "$cwd" in */.claude/worktrees/*) exit 0 ;; esac
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
echo "Edits outside a worktree are blocked. Call EnterWorktree first." >&2
exit 2
