#!/usr/bin/env bash
# Read every piece of feedback on a PR: inline threads, review bodies, conversation.
# Usage: fetch.sh [PR]   (number, url or branch; defaults to the current branch's PR)

set -uo pipefail

die() { printf 'fetch.sh: %s\n' "$1" >&2; exit 2; }

case "${1:-}" in -h|--help) sed -n '2,3s/^# \{0,1\}//p' "$0"; exit 0;; esac

command -v gh >/dev/null || die "gh is required"
command -v jq >/dev/null || die "jq is required"

if [ $# -gt 0 ]; then
  URL=$(gh pr view "$1" --json url --jq .url 2>&1) \
    || die "no PR for '$1': $URL"
else
  URL=$(gh pr view --json url --jq .url 2>&1) \
    || die "no PR for this branch: $URL. Pass a number, url or branch."
fi

OWNER=$(printf '%s' "$URL" | awk -F/ '{print $4}')
REPO=$(printf '%s' "$URL" | awk -F/ '{print $5}')
NUMBER=$(printf '%s' "$URL" | awk -F/ '{print $7}')
[ -n "$OWNER" ] && [ -n "$REPO" ] && [ -n "$NUMBER" ] \
  || die "cannot read owner/repo/number out of $URL"

# REST does not expose thread resolution state, so all three sources come over
# GraphQL in one read.
gh api graphql -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  viewer { login }
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      id
      reviewThreads(first:100) {
        nodes { id isResolved isOutdated path line comments(first:20) { nodes { ...c } } }
      }
      reviews(first:50) { nodes { id url state author { login } body ...r } }
      comments(first:100) { nodes { ...c } }
    }
  }
}
fragment r on Reactable { reactionGroups { content viewerHasReacted } }
fragment c on Reactable {
  id
  reactionGroups { content viewerHasReacted }
  ... on PullRequestReviewComment { url author { login } body }
  ... on IssueComment { url author { login } body }
}' -f owner="$OWNER" -f repo="$REPO" -F number="$NUMBER" \
  --jq '{viewer: .data.viewer.login}
        + (.data.repository.pullRequest
        | {prId: .id,
           threads: [.reviewThreads.nodes[] | select(.isResolved == false)
                     | {id, path, line, isOutdated,
                        comments: [.comments.nodes[] | {id, url, author: .author.login, body,
                                   userVotes: [.reactionGroups[] | select(.viewerHasReacted) | .content]}]}],
           reviews: [.reviews.nodes[] | select(.body != "")
                     | {id, url, state, author: .author.login, body,
                        userVotes: [.reactionGroups[] | select(.viewerHasReacted) | .content]}],
           conversation: [.comments.nodes[] | {id, url, author: .author.login, body,
                          userVotes: [.reactionGroups[] | select(.viewerHasReacted) | .content]}]})' \
  | jq --arg pr "$URL" '{pr: $pr} + .'
