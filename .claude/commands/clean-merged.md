---
description: Remove local git branches and worktrees that are fully merged into the base branch
argument-hint: "[--apply] [--base <ref>] [--force-dirty]"
allowed-tools: Bash(bash "$HOME/.claude/scripts/git-clean-merged.sh"*), Bash(git worktree list*), Bash(git branch*), Bash(git log*)
---

Clean up merged branches and worktrees using the reusable script at
`$HOME/.claude/scripts/git-clean-merged.sh`. Run this from the main checkout.

Arguments passed by the user: `$ARGUMENTS`

Do this:

1. **Dry-run first.** Run:
   `bash "$HOME/.claude/scripts/git-clean-merged.sh" $ARGUMENTS`
   The script is safe by default — without `--apply` it only prints a plan and
   changes nothing.

2. **Present the plan** in your own words: which worktrees and branches would be
   removed (merged), which are kept (unmerged, with ahead-count), and any that
   were skipped for having uncommitted changes.

3. **If nothing to clean,** say so and stop.

4. **If there is something to clean and the user did NOT already pass `--apply`,**
   confirm with the user, then re-run adding `--apply`:
   `bash "$HOME/.claude/scripts/git-clean-merged.sh" --apply $ARGUMENTS`
   (Worktree removal deletes node_modules and can take a minute or more each —
   run it in the background so it doesn't time out.)

5. **Report** what was removed and show the final `git worktree list`.

Notes:
- "Merged" means the branch tip is an ancestor of the base (`origin/<default>`),
  i.e. every commit is already in the base. This matches merge-commit and
  fast-forward PR merges.
- **Squash/rebase-merged branches are kept** (their commits are not ancestors).
  If a kept branch looks merged-by-PR but wasn't auto-removed, flag it so the
  user can delete it by hand after confirming — never force-delete unmerged work
  without asking.
- Worktrees with uncommitted tracked changes are skipped unless `--force-dirty`.
