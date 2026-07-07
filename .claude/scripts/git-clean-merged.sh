#!/usr/bin/env bash
#
# git-clean-merged.sh — remove local branches and their worktrees that are
# fully merged into the base branch.
#
# SAFE BY DEFAULT: dry-run. It prints a plan and changes nothing until you
# pass --apply.
#
# Usage:
#   git-clean-merged.sh                 # dry-run: show what would be removed
#   git-clean-merged.sh --apply         # actually remove merged worktrees/branches
#   git-clean-merged.sh --base <ref>    # override base (default: origin/<default>)
#   git-clean-merged.sh --force-dirty   # also remove worktrees with uncommitted changes
#   git-clean-merged.sh --help
#
# "Merged" means the branch tip is an ancestor of the base — every commit on
# the branch is already in the base. This matches merge-commit and fast-forward
# PR merges. Squash/rebase-merged branches are NOT auto-detected (their commits
# are not ancestors) and are kept; delete those by hand after checking them.
#
# Worktrees with uncommitted tracked changes are skipped unless --force-dirty.
# Ignored files (node_modules, build caches) never block removal.
# Run from your main checkout (not from inside a linked worktree).

set -eo pipefail

APPLY=0
FORCE_DIRTY=0
BASE_OVERRIDE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --force-dirty) FORCE_DIRTY=1 ;;
    --base) shift; BASE_OVERRIDE="$1" ;;
    -h|--help) sed -n '2,/^set /{/^set /d;s/^# \{0,1\}//;p;}' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "error: not inside a git repository" >&2; exit 1; }
ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

# Resolve base ref and its short name.
if [ -n "$BASE_OVERRIDE" ]; then
  BASE="$BASE_OVERRIDE"
else
  DEF=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
  DEF="${DEF#origin/}"
  [ -z "$DEF" ] && DEF="main"
  BASE="origin/$DEF"
fi
BASE_NAME="${BASE##*/}"

echo "Repository: $ROOT"
echo "Base:       $BASE"
if [ "$APPLY" -eq 1 ]; then echo "Mode:       APPLY"; else echo "Mode:       dry-run (pass --apply to execute)"; fi
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

REMOVE_WT=""   # newline-separated worktree paths
DEL_BRANCH=""  # newline-separated branch names
KEEP=""        # human-readable
SKIP=""        # human-readable
SWITCH_CURRENT=0

while IFS= read -r b; do
  [ "$b" = "$BASE_NAME" ] && continue
  if git merge-base --is-ancestor "$b" "$BASE" 2>/dev/null; then
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
    DEL_BRANCH="$DEL_BRANCH$b\n"
  else
    ahead=$(git rev-list --count "$BASE..$b" 2>/dev/null || echo "?")
    KEEP="$KEEP$b ($ahead ahead)\n"
  fi
done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

echo
echo "=== Plan ==="
if [ -n "$REMOVE_WT" ]; then printf "Worktrees to remove:\n"; printf '%b' "$REMOVE_WT" | sed 's/^/  - /'; else echo "Worktrees to remove: none"; fi
if [ -n "$DEL_BRANCH" ]; then printf "Branches to delete (merged into %s):\n" "$BASE"; printf '%b' "$DEL_BRANCH" | sed 's/^/  - /'; else echo "Branches to delete: none"; fi
[ "$SWITCH_CURRENT" -eq 1 ] && echo "Note: current branch is merged; main checkout will switch to '$BASE_NAME' first."
[ -n "$KEEP" ] && { echo "Keeping (unmerged):"; printf '%b' "$KEEP" | sed 's/^/  - /'; }
[ -n "$SKIP" ] && { echo "Skipped (use --force-dirty to include):"; printf '%b' "$SKIP" | sed 's/^/  - /'; }

if [ -z "$DEL_BRANCH" ] && [ -z "$REMOVE_WT" ]; then
  echo; echo "Nothing to clean."; exit 0
fi

if [ "$APPLY" -eq 0 ]; then
  echo; echo "Dry-run only. Re-run with --apply to execute."; exit 0
fi

echo
echo "=== Applying ==="
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

printf '%b' "$DEL_BRANCH" | while IFS= read -r b; do
  [ -z "$b" ] && continue
  if git branch -D "$b"; then echo "deleted branch: $b"; else echo "FAILED branch: $b"; fi
done

echo
echo "=== Done ==="
git worktree list
