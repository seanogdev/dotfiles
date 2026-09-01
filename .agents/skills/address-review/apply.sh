#!/usr/bin/env bash
# Execute a review-response plan: reply, vote and resolve across every thread at once.
# Usage: apply.sh [--dry-run] PLAN.json   (PLAN of "-" reads stdin)

set -uo pipefail

JOBS=${ADDRESS_REVIEW_JOBS:-4}
SELF=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")

die() { printf 'apply.sh: %s\n' "$1" >&2; exit 2; }

gql() {
  gh api graphql -f query="$1" "${@:2}" 2>&1
}

# Idempotent calls only: a reply is not one.
retry_gql() {
  local attempt=1 out rc
  while :; do
    out=$(gql "$@"); rc=$?
    if [ $rc -eq 0 ]; then printf '%s' "$out"; return 0; fi
    if [ $attempt -ge 3 ]; then printf '%s' "$out"; return $rc; fi
    sleep $((attempt * 2))
    attempt=$((attempt + 1))
  done
}

Q_REPLY='mutation($threadId:ID!, $body:String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { url }
  }
}'
Q_COMMENT='mutation($subjectId:ID!, $body:String!) {
  addComment(input: {subjectId: $subjectId, body: $body}) { commentEdge { node { url } } }
}'
Q_VOTE='mutation($subjectId:ID!, $content:ReactionContent!) {
  addReaction(input: {subjectId: $subjectId, content: $content}) { reaction { content } }
}'
Q_RESOLVE='mutation($threadId:ID!) {
  resolveReviewThread(input: {threadId: $threadId}) { thread { isResolved } }
}'

worker() {
  local item=$1 n result ref threadId prId commentId bodyFile vote resolve
  n=${item##*/item-}
  result=${item%/item-*}/result-$n

  ref=$(jq -r '.ref' "$item")
  threadId=$(jq -r '.threadId // ""' "$item")
  prId=$(jq -r '.prId // ""' "$item")
  commentId=$(jq -r '.commentId // ""' "$item")
  bodyFile=$(jq -r '.bodyFile // ""' "$item")
  vote=$(jq -r '.vote // ""' "$item")
  resolve=$(jq -r 'if .resolve then "yes" else "" end' "$item")

  local reply=skipped replyUrl="" voteState=skipped resolveState=skipped err=""

  if [ -n "$bodyFile" ]; then
    local out rc
    if [ -n "$threadId" ]; then
      out=$(gql "$Q_REPLY" -f threadId="$threadId" -F body=@"$bodyFile" \
        --jq '.data.addPullRequestReviewThreadReply.comment.url'); rc=$?
    else
      out=$(gql "$Q_COMMENT" -f subjectId="$prId" -F body=@"$bodyFile" \
        --jq '.data.addComment.commentEdge.node.url'); rc=$?
    fi
    if [ $rc -eq 0 ]; then
      reply=ok
      replyUrl=$out
    else
      # Leave the vote and the resolve alone: a thread with no reply must not
      # end up voted and closed.
      reply=failed
      err=$out
      jq -n --arg ref "$ref" --arg reply "$reply" --arg replyUrl "$replyUrl" \
        --arg vote "$voteState" --arg resolve "$resolveState" --arg err "$err" \
        '{$ref,$reply,$replyUrl,$vote,$resolve,$err}' > "$result"
      return 0
    fi
  fi

  local vf rf
  vf=$item.vote; rf=$item.resolve

  if [ -n "$vote" ]; then
    ( out=$(retry_gql "$Q_VOTE" -f subjectId="$commentId" -f content="$vote")
      if [ $? -eq 0 ]; then printf 'ok' > "$vf"; else printf 'failed\n%s' "$out" > "$vf"; fi ) &
  fi
  if [ -n "$resolve" ]; then
    ( out=$(retry_gql "$Q_RESOLVE" -f threadId="$threadId")
      if [ $? -eq 0 ]; then printf 'ok' > "$rf"; else printf 'failed\n%s' "$out" > "$rf"; fi ) &
  fi
  wait

  if [ -f "$vf" ]; then
    voteState=$(head -1 "$vf")
    [ "$voteState" = failed ] && err="$err$(tail -n +2 "$vf")"
  fi
  if [ -f "$rf" ]; then
    resolveState=$(head -1 "$rf")
    [ "$resolveState" = failed ] && err="$err$(tail -n +2 "$rf")"
  fi

  jq -n --arg ref "$ref" --arg reply "$reply" --arg replyUrl "$replyUrl" \
    --arg vote "$voteState" --arg resolve "$resolveState" --arg err "$err" \
    '{$ref,$reply,$replyUrl,$vote,$resolve,$err}' > "$result"
}

if [ "${1:-}" = "--worker" ]; then
  worker "$2"
  exit 0
fi

DRY=""
[ "${1:-}" = "--dry-run" ] && { DRY=yes; shift; }
PLAN=${1:-}
[ -n "$PLAN" ] || die "usage: apply.sh [--dry-run] PLAN.json"
command -v jq >/dev/null || die "jq is required"
command -v gh >/dev/null || die "gh is required"

if [ "$PLAN" = "-" ]; then PLAN_JSON=$(cat); else
  [ -f "$PLAN" ] || die "no such plan: $PLAN"
  PLAN_JSON=$(cat "$PLAN")
fi

printf '%s' "$PLAN_JSON" | jq -e 'type == "array" and length > 0' >/dev/null \
  || die "plan must be a non-empty JSON array"

# Validate the whole plan before sending anything. A plan that fails halfway is
# the expensive failure, so every check happens up front.
ERRORS=$(printf '%s' "$PLAN_JSON" | jq -r '
  def bad($i; $m): "  item \($i) (\(.ref // "no ref")): \($m)";
  to_entries | map(.key as $i | .value |
    [ if (.ref // "") == "" then bad($i; "missing ref") else empty end,
      if ((.threadId // null) == null) == ((.prId // null) == null)
        then bad($i; "needs exactly one of threadId or prId") else empty end,
      if (.vote // null) != null and ((.vote | IN("THUMBS_UP","THUMBS_DOWN")) | not)
        then bad($i; "vote must be THUMBS_UP or THUMBS_DOWN") else empty end,
      if (.vote // null) != null and (.commentId // "") == ""
        then bad($i; "vote needs a commentId") else empty end,
      if (.resolve // false) and (.threadId // null) == null
        then bad($i; "resolve needs a threadId") else empty end,
      if (.bodyFile // null) == null and (.vote // null) == null and ((.resolve // false) | not)
        then bad($i; "no reply, vote or resolve") else empty end ]
  ) | flatten | .[]')
[ -z "$ERRORS" ] || { printf 'apply.sh: invalid plan\n%s\n' "$ERRORS" >&2; exit 2; }

MISSING=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -s "$f" ] || MISSING="$MISSING  $f"$'\n'
done <<EOF
$(printf '%s' "$PLAN_JSON" | jq -r '.[].bodyFile // empty')
EOF
[ -z "$MISSING" ] || { printf 'apply.sh: missing or empty body files\n%s' "$MISSING" >&2; exit 2; }

COUNT=$(printf '%s' "$PLAN_JSON" | jq 'length')

if [ -n "$DRY" ]; then
  printf '%s' "$PLAN_JSON" | jq -r '.[] |
    "\(.ref)\t\(if .bodyFile then (if .threadId then "reply" else "comment" end) else "-" end)\t\(.vote // "-")\t\(if .resolve then "resolve" else "-" end)"' \
    | awk -F'\t' 'BEGIN{printf "%-34s %-8s %-12s %s\n","REF","REPLY","VOTE","RESOLVE"}
                  {printf "%-34s %-8s %-12s %s\n",$1,$2,$3,$4}'
  printf '\n%d items, %d at a time.\n' "$COUNT" "$JOBS"
  exit 0
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/address-review.XXXXXX") || die "cannot make a work dir"
trap 'rm -rf "$WORK"' EXIT

i=0
while [ $i -lt "$COUNT" ]; do
  printf '%s' "$PLAN_JSON" | jq -c ".[$i]" > "$WORK/item-$(printf '%03d' $i)"
  i=$((i + 1))
done

ls "$WORK"/item-* | xargs -P "$JOBS" -n1 "$SELF" --worker

RESULTS=$(cat "$WORK"/result-* 2>/dev/null | jq -s '.')
[ "$(printf '%s' "$RESULTS" | jq 'length')" = "$COUNT" ] \
  || printf 'apply.sh: %s of %s items reported back\n' \
       "$(printf '%s' "$RESULTS" | jq 'length')" "$COUNT" >&2

printf '%s' "$RESULTS" | jq -r '.[] | "\(.ref)\t\(.reply)\t\(.vote)\t\(.resolve)"' \
  | awk -F'\t' 'BEGIN{printf "%-34s %-8s %-9s %s\n","REF","REPLY","VOTE","RESOLVE"}
                {printf "%-34s %-8s %-9s %s\n",$1,$2,$3,$4}'

printf '\n'
printf '%s' "$RESULTS" | jq -r '.[] | select(.replyUrl != "") | "\(.ref)  \(.replyUrl)"'

FAILED=$(printf '%s' "$RESULTS" | jq '[.[] | select(.reply == "failed" or .vote == "failed" or .resolve == "failed")] | length')
if [ "$FAILED" != 0 ]; then
  printf '\n%s item(s) failed:\n' "$FAILED" >&2
  printf '%s' "$RESULTS" | jq -r '.[] | select(.err != "") | "  \(.ref): \(.err)"' >&2
  printf '\nA failed reply sends no vote and no resolve. Re-read those threads before retrying: GitHub sometimes posts a reply and then fails the response.\n' >&2
  exit 1
fi
