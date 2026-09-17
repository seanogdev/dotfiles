#!/usr/bin/env bash
# Remove your thumbs up or down from a comment, given its url.
# Usage: unvote.sh [--dry-run] COMMENT_URL

set -uo pipefail

die() { printf 'unvote.sh: %s\n' "$1" >&2; exit 2; }

case "${1:-}" in -h|--help) sed -n '2,3s/^# \{0,1\}//p' "$0"; exit 0;; esac

DRY=""
[ "${1:-}" = "--dry-run" ] && { DRY=yes; shift; }
URL=${1:-}
[ -n "$URL" ] || die "usage: unvote.sh [--dry-run] COMMENT_URL"

OWNER=$(printf '%s' "$URL" | awk -F/ '{print $4}')
REPO=$(printf '%s' "$URL" | awk -F/ '{print $5}')
FRAG=${URL##*#}

case "$FRAG" in
  discussion_r*) KIND=pulls/comments; ID=${FRAG#discussion_r};;
  issuecomment-*) KIND=issues/comments; ID=${FRAG#issuecomment-};;
  pullrequestreview-*)
    die "REST has no reactions endpoint for a review body, so a vote on one cannot be undone here. Say so in the reply instead.";;
  *) die "cannot tell what '$URL' points at. Needs a #discussion_r or #issuecomment- url.";;
esac
[ -n "$OWNER" ] && [ -n "$REPO" ] && [ -n "$ID" ] || die "cannot parse $URL"

ME=$(gh api user --jq .login) || die "cannot read the current login"

# removeReaction returns FORBIDDEN on this account, so this goes over REST,
# which takes REST ids rather than node ids.
FOUND=$(gh api "/repos/$OWNER/$REPO/$KIND/$ID/reactions" \
  --jq ".[] | select(.user.login == \"$ME\") | select(.content == \"+1\" or .content == \"-1\") | \"\(.id)\t\(.content)\"") \
  || die "cannot list reactions on $URL"

[ -n "$FOUND" ] || { printf 'No vote from %s on %s\n' "$ME" "$URL"; exit 0; }

while IFS=$'\t' read -r rid content; do
  [ -n "$rid" ] || continue
  if [ -n "$DRY" ]; then
    printf 'would remove %s (reaction %s)\n' "$content" "$rid"
  else
    if gh api -X DELETE "/repos/$OWNER/$REPO/$KIND/$ID/reactions/$rid" >/dev/null 2>&1; then
      printf 'removed %s\n' "$content"
    else
      printf 'unvote.sh: could not remove reaction %s\n' "$rid" >&2; exit 1
    fi
  fi
done <<EOF
$FOUND
EOF
