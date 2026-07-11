---
description: Remove local git branches and worktrees that are fully merged into their head (PR base), or into the fallback base
argument-hint: "[--apply] [--base <ref>] [--force-dirty] [--no-gh]"
allowed-tools: Bash(bash "$HOME/.claude/scripts/git-clean-merged.sh"*), Bash(git worktree list*), Bash(git branch*), Bash(git log*), Bash(gh pr view*)
---

Clean up merged branches and worktrees using the reusable script at
`$HOME/.claude/scripts/git-clean-merged.sh`. Run this from the main checkout.
**This is local-only** — it never deletes remote branches or closes PRs; it only
reads GitHub (read-only) to learn each branch's PR base and merge status.

Arguments passed by the user: `$ARGUMENTS`

Do this:

1. **Dry-run first.** Run:
   `bash "$HOME/.claude/scripts/git-clean-merged.sh" $ARGUMENTS`
   The script is safe by default — without `--apply` it only prints a plan and
   changes nothing. It queries GitHub per branch (read-only), so it may take a
   few seconds.

2. **Present the plan** in your own words: which worktrees and branches would be
   removed (merged — say whether via PR into its head branch or as an ancestor
   of the base), which are kept (unmerged, with ahead-count and PR state), and
   any that were skipped for having uncommitted changes.

3. **If nothing to clean,** say so and stop.

4. **If there is something to clean and the user did NOT already pass `--apply`,**
   confirm with the user, then re-run adding `--apply`:
   `bash "$HOME/.claude/scripts/git-clean-merged.sh" --apply $ARGUMENTS`
   (Worktree removal deletes node_modules and can take a minute or more each —
   run it in the background so it doesn't time out.)

5. **Report** what was removed and show the final `git worktree list`.

Notes:
- A branch counts as **merged** when either (1) GitHub reports its PR as MERGED
  into that PR's own base branch — so a branch merged into another feature
  branch in a stack counts, and **squash/rebase merges are detected** — or (2)
  its tip is an ancestor of the fallback base (`origin/<default>`), covering
  merge-commit and fast-forward merges with no network.
- **Local only.** Deletion removes local worktrees and local branches (`git
  branch -D`). It never touches the remote — no push, no remote branch deletion,
  no PR changes.
- **No silent data loss.** A gh-merged branch is auto-deleted only when its local
  tip equals the exact commit GitHub merged (`headRefOid`). If the local tip
  differs (unpushed commits after merge), it's listed under "merged on GitHub but
  local tip differs" and left for the user to delete by hand.
- GitHub detection needs `gh` authenticated. Without it (or with `--no-gh`) only
  the git-ancestor check runs, and squash-merged branches are kept for manual
  review — flag any that look merged-by-PR so the user can delete them by hand.
- Worktrees with uncommitted tracked changes are skipped unless `--force-dirty`.
