---
name: prune-merged-branches
description: Delete the local git branches that are merged, and remove their worktrees. A branch counts as merged into its own PR base, or into the fallback base. Local only. It never changes the remote.
license: MIT
argument-hint: "[--apply] [--base <ref>] [--force-dirty] [--no-gh]"
disable-model-invocation: true
allowed-tools: Bash(bash *prune-merged-branches/prune.sh*), Bash(git worktree list*), Bash(git branch*), Bash(git log*), Bash(gh pr view*)
---

# Prune merged branches

Each path in this skill is relative to the directory that holds this file. Expand it to a full path
before you run a command.

This skill deletes local branches and removes their worktrees. It changes nothing on the remote. It
never pushes. It never deletes a remote branch. It never closes a pull request. It reads GitHub
read-only, to learn each branch's PR base and merge status.

Run it from the main checkout. Do not run it from inside a linked worktree.

Arguments from the user: `$ARGUMENTS`

## Steps

1. Run the dry run:

   ```bash
   bash prune.sh $ARGUMENTS
   ```

   Without `--apply` the script changes nothing. It prints a plan only. It queries GitHub once per
   branch, so it takes a few seconds.

2. Present the plan in your own words. Cover four groups:

   - The worktrees the script removes.
   - The branches the script deletes. Say how each one counts as merged. Name either the PR and its
     base branch, or the fallback base.
   - The branches the script keeps. Give the ahead-count and the PR state for each one.
   - The branches the script skipped. An uncommitted change in the worktree is the reason.

3. If the plan is empty, say so. Then stop.

4. If the plan is not empty, and the user passed no `--apply`, ask the user to confirm. Then run:

   ```bash
   bash prune.sh --apply $ARGUMENTS
   ```

   Worktree removal deletes `node_modules`. It takes a minute or more for each worktree. Run this
   command in the background, so it does not time out.

5. Report what the script removed. Then show `git worktree list`.

## What counts as merged

A branch is merged when one of these is true:

- GitHub reports its PR as `MERGED` into that PR's own base branch. A branch merged into another
  feature branch in a stack counts. A squash merge counts. A rebase merge counts.
- Its tip is an ancestor of the fallback base, `origin/<default>`. This covers a merge commit and a
  fast-forward merge. It needs no network.

## Gotchas

- The script never deletes a branch when the local tip differs from the commit GitHub merged. A
  difference means there are unpushed commits after the merge. The script lists that branch under
  "merged on GitHub but local tip differs". The user deletes it by hand.
- GitHub detection needs an authenticated `gh`. Without one, or with `--no-gh`, only the
  git-ancestor check runs. A squash-merged branch then stays. Flag any branch that looks merged by
  PR, so the user can delete it by hand.
- The script skips a worktree with uncommitted tracked changes. `--force-dirty` includes it.
