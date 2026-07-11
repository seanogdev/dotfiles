#!/usr/bin/env bash
#
# git-clean-merged.sh — remove LOCAL branches and their worktrees that are
# fully merged into their head (the PR base branch), plus branches merged into
# the fallback base.
#
# LOCAL ONLY: this never touches the remote. It removes local worktrees and
# deletes local branches. It never pushes, never deletes a remote branch, and
# never closes a pull request. GitHub is consulted READ-ONLY (gh pr view) to
# learn each branch's base and merge status.
#
# SAFE BY DEFAULT: dry-run. It prints a plan and changes nothing until you
# pass --apply.
#
# Usage:
#   git-clean-merged.sh                 # dry-run: show what would be removed
#   git-clean-merged.sh --apply         # actually remove merged worktrees/branches
#   git-clean-merged.sh --base <ref>    # override fallback base (default: origin/<default>)
#   git-clean-merged.sh --force-dirty   # also remove worktrees with uncommitted changes
#   git-clean-merged.sh --no-gh         # ignore GitHub; use the git-ancestor check only
#   git-clean-merged.sh --help
#
# A branch counts as MERGED when EITHER:
#   1. GitHub reports its pull request as MERGED (via gh). This is keyed on the
#      PR's own base branch ("its head"), so a branch merged into another
#      feature branch in a stack is detected, and squash/rebase merges count
#      too (their commits are not ancestors, so git alone can't see them); OR
#   2. its tip is an ancestor of the fallback base (origin/<default>) — every
#      commit on the branch is already in the base. This matches merge-commit
#      and fast-forward merges and works with no network access.
#
# GitHub detection needs gh installed and authenticated; without it (or with
# --no-gh) only the ancestor check runs, and squash-merged branches are kept
# for manual review.
#
# Worktrees with uncommitted tracked changes are skipped unless --force-dirty.
# Ignored files (node_modules, build caches) never block removal.
# Run from your main checkout (not from inside a linked worktree).

set -eo pipefail

APPLY=0
FORCE_DIRTY=0
USE_GH=1
BASE_OVERRIDE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --force-dirty) FORCE_DIRTY=1 ;;
    --no-gh) USE_GH=0 ;;
    --base) shift; BASE_OVERRIDE="$1" ;;
    -h|--help) sed -n '2,/^set /{/^set /d;s/^# \{0,1\}//;p;}' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "error: not inside a git repository" >&2; exit 1; }
ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

# Resolve the fallback base ref and its short name.
if [ -n "$BASE_OVERRIDE" ]; then
  BASE="$BASE_OVERRIDE"
else
  DEF=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
  DEF="${DEF#origin/}"
  [ -z "$DEF" ] && DEF="main"
  BASE="origin/$DEF"
fi
BASE_NAME="${BASE##*/}"

# Probe the GitHub CLI once — read-only.
GH_OK=0
if [ "$USE_GH" -eq 1 ] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GH_OK=1
fi

echo "Repository: $ROOT"
echo "Base:       $BASE (fallback)"
if [ "$GH_OK" -eq 1 ]; then
  echo "GitHub:     gh authenticated — using PR merge status (read-only)"
elif [ "$USE_GH" -eq 0 ]; then
  echo "GitHub:     disabled (--no-gh) — git-ancestor check only"
else
  echo "GitHub:     gh unavailable — git-ancestor check only (squash-merges kept)"
fi
if [ "$APPLY" -eq 1 ]; then echo "Mode:       APPLY (local only — no remote changes)"; else echo "Mode:       dry-run (pass --apply to execute)"; fi
echo

echo "Fetching & pruning..."
git fetch --prune origin >/dev/null 2>&1 || echo "  warn: fetch failed; using cached refs"
git rev-parse --verify --quiet "$BASE" >/dev/null || { echo "error: base ref '$BASE' not found" >&2; exit 1; }

CURRENT=$(git branch --show-current 2>/dev/null || true)

# Return the worktree path a given branch is checked out in, or nothing.
worktree_for_branch() {
  git worktree list --porcelain | awk -v want="branch refs/heads/$1" '
    /^worktree /{ p=substr($0,10) }
    $0==want { print p; exit }'
}

# Classify a branch. Echoes a tab-separated "MERGED\t<reason>" or "KEEP\t<detail>".
# GitHub is queried read-only; the ancestor check is the offline fallback.
classify_branch() {
  local b="$1" line state base num oid local_sha ahead ref
  if [ "$GH_OK" -eq 1 ]; then
    line=$(gh pr view "$b" --json state,baseRefName,number,headRefOid \
      --jq '.state + "\t" + .baseRefName + "\t" + (.number|tostring) + "\t" + .headRefOid' 2>/dev/null || true)
    if [ -n "$line" ]; then
      IFS=$'\t' read -r state base num oid <<<"$line"
      if [ "$state" = "MERGED" ]; then
        # Only auto-delete when the local tip IS the commit GitHub merged; a
        # mismatch means unpushed local commits that -D would silently drop.
        local_sha=$(git rev-parse --verify --quiet "refs/heads/$b" || true)
        if [ -n "$oid" ] && [ "$local_sha" = "$oid" ]; then
          printf 'MERGED\tPR #%s merged into %s\n' "$num" "$base"
        else
          printf 'REVIEW\tPR #%s merged into %s, but local tip differs from merged head (unpushed commits?) — delete by hand\n' "$num" "$base"
        fi
        return 0
      fi
    fi
  fi
  if git merge-base --is-ancestor "$b" "$BASE" 2>/dev/null; then
    printf 'MERGED\tancestor of %s\n' "$BASE"
    return 0
  fi
  # Not merged — report how far ahead of its base it is (PR base if known).
  ref="$BASE"
  if [ -n "${base:-}" ] && git rev-parse --verify --quiet "origin/$base" >/dev/null; then
    ref="origin/$base"
  fi
  ahead=$(git rev-list --count "$ref..$b" 2>/dev/null || echo "?")
  if [ "$ref" = "$BASE" ]; then
    printf 'KEEP\t%s ahead of %s%s\n' "$ahead" "$BASE_NAME" "${state:+ (PR $state)}"
  else
    printf 'KEEP\t%s ahead of %s (PR base%s)\n' "$ahead" "${ref#origin/}" "${state:+, $state}"
  fi
  return 0
}

REMOVE_WT=""   # newline-separated worktree paths
DEL_BRANCH=""  # newline-separated "branch\treason"
KEEP=""        # human-readable
REVIEW=""      # merged on GitHub but local tip differs — never auto-deleted
SKIP=""        # human-readable
SWITCH_CURRENT=0

[ "$GH_OK" -eq 1 ] && echo "Querying GitHub for PR merge status (read-only)..."

while IFS= read -r b; do
  [ "$b" = "$BASE_NAME" ] && continue
  res=$(classify_branch "$b")
  kind=${res%%$'\t'*}
  detail=${res#*$'\t'}
  if [ "$kind" = "MERGED" ]; then
    path=$(worktree_for_branch "$b")
    if [ -n "$path" ] && [ "$path" != "$ROOT" ]; then
      dirty=$(git -C "$path" status --porcelain 2>/dev/null || true)
      if [ -n "$dirty" ] && [ "$FORCE_DIRTY" -eq 0 ]; then
        SKIP="$SKIP$b — worktree has uncommitted changes ($path)\n"
        continue
      fi
      REMOVE_WT="$REMOVE_WT$path\n"
    fi
    [ "$b" = "$CURRENT" ] && SWITCH_CURRENT=1
    DEL_BRANCH="$DEL_BRANCH$b\t$detail\n"
  elif [ "$kind" = "REVIEW" ]; then
    REVIEW="$REVIEW$b ($detail)\n"
  else
    KEEP="$KEEP$b ($detail)\n"
  fi
done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

echo
echo "=== Plan ==="
if [ -n "$REMOVE_WT" ]; then printf "Worktrees to remove:\n"; printf '%b' "$REMOVE_WT" | sed 's/^/  - /'; else echo "Worktrees to remove: none"; fi
if [ -n "$DEL_BRANCH" ]; then
  echo "Branches to delete (merged, local only):"
  printf '%b' "$DEL_BRANCH" | awk -F'\t' 'NF{printf "  - %s  [%s]\n", $1, $2}'
else
  echo "Branches to delete: none"
fi
[ "$SWITCH_CURRENT" -eq 1 ] && echo "Note: current branch is merged; main checkout will switch to '$BASE_NAME' first."
[ -n "$REVIEW" ] && { echo "Merged on GitHub but local tip differs (review before deleting):"; printf '%b' "$REVIEW" | sed 's/^/  - /'; }
[ -n "$KEEP" ] && { echo "Keeping (unmerged):"; printf '%b' "$KEEP" | sed 's/^/  - /'; }
[ -n "$SKIP" ] && { echo "Skipped (use --force-dirty to include):"; printf '%b' "$SKIP" | sed 's/^/  - /'; }

if [ -z "$DEL_BRANCH" ] && [ -z "$REMOVE_WT" ]; then
  echo
  if [ -n "$REVIEW" ]; then
    echo "Nothing to auto-clean. See the review list above to delete by hand."
  else
    echo "Nothing to clean."
  fi
  exit 0
fi

if [ "$APPLY" -eq 0 ]; then
  echo; echo "Dry-run only. Re-run with --apply to execute (local only — no remote changes)."; exit 0
fi

echo
echo "=== Applying (local only) ==="
printf '%b' "$REMOVE_WT" | while IFS= read -r p; do
  [ -z "$p" ] && continue
  if git worktree remove --force "$p"; then echo "removed worktree: $p"; else echo "FAILED worktree: $p"; fi
done
git worktree prune

if [ "$SWITCH_CURRENT" -eq 1 ]; then
  if git rev-parse --verify --quiet "refs/heads/$BASE_NAME" >/dev/null; then
    git switch "$BASE_NAME"
  else
    git switch -c "$BASE_NAME" --track "$BASE"
  fi
  git merge --ff-only "$BASE" >/dev/null 2>&1 || echo "  note: could not fast-forward $BASE_NAME"
fi

printf '%b' "$DEL_BRANCH" | while IFS= read -r line; do
  [ -z "$line" ] && continue
  b=${line%%$'\t'*}
  if git branch -D "$b"; then echo "deleted branch: $b"; else echo "FAILED branch: $b"; fi
done

echo
echo "=== Done ==="
git worktree list
