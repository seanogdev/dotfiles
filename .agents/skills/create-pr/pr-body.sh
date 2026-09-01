#!/usr/bin/env bash
# Read a PR body, or write one back without dropping the author's attachments.
# Usage: pr-body.sh save [PR]
#        pr-body.sh check NEW.md [PR]
#        pr-body.sh edit  NEW.md [PR]

set -uo pipefail

die() { printf 'pr-body.sh: %s\n' "$1" >&2; exit 2; }

case "${1:-}" in -h|--help|"") sed -n '2,5s/^# \{0,1\}//p' "$0"; exit 0;; esac

command -v gh >/dev/null || die "gh is required"

CMD=$1; shift
case "$CMD" in
  save) NEW=""; PR=${1:-};;
  check|edit) NEW=${1:-}; [ -n "$NEW" ] || die "$CMD needs a body file"; PR=${2:-};;
  *) die "unknown command '$CMD'. One of save, check, edit.";;
esac
[ -z "$NEW" ] || [ -f "$NEW" ] || die "no such body file: $NEW"

# `gh` appends a newline that would grow the body by a blank line on every run.
if [ -n "$PR" ]; then
  BODY=$(gh pr view "$PR" --json body -q .body 2>&1) || die "cannot read PR '$PR': $BODY"
else
  BODY=$(gh pr view --json body -q .body 2>&1) || die "cannot read the PR for this branch: $BODY"
fi
BODY=$(printf '%s' "$BODY" | perl -pe 'chomp if eof')

if [ "$CMD" = save ]; then printf '%s' "$BODY"; exit 0; fi

attachments() {
  grep -oE 'https://[^ )">]*(user-attachments|githubusercontent)[^ )">]*' | sort -u
}

MISSING=""
while IFS= read -r url; do
  [ -n "$url" ] || continue
  grep -qF -- "$url" "$NEW" || MISSING="$MISSING  $url"$'\n'
done <<EOF
$(printf '%s' "$BODY" | attachments)
EOF

if [ -n "$MISSING" ]; then
  printf 'pr-body.sh: %s would drop attachments the author added:\n%s' "$CMD" "$MISSING" >&2
  printf 'Put every one of them back, in its own section, before editing.\n' >&2
  exit 1
fi

KEPT=$(printf '%s' "$BODY" | attachments | grep -c . || true)

if [ "$CMD" = check ]; then
  printf 'ok: %s attachment(s) in the current body all survive\n' "$KEPT"
  exit 0
fi

TMP=$(mktemp "${TMPDIR:-/tmp}/pr-body.XXXXXX") || die "cannot make a temp file"
trap 'rm -f "$TMP"' EXIT
perl -pe 'chomp if eof' < "$NEW" > "$TMP"

if [ -n "$PR" ]; then
  gh pr edit "$PR" --body-file "$TMP" || die "gh pr edit failed"
else
  gh pr edit --body-file "$TMP" || die "gh pr edit failed"
fi
printf 'Updated the body, %s attachment(s) intact\n' "$KEPT"
