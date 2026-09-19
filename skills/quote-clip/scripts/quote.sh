#!/usr/bin/env bash
# Turn prose into a block quote and copy it to the clipboard.
# Flattens markdown headings to bold, then prefixes every line with "> ".
# Usage: quote.sh < message.md
#        quote.sh <<'EOF'
#        message text
#        EOF

set -uo pipefail

command -v pbcopy >/dev/null || { echo "quote.sh: pbcopy is required (macOS only)" >&2; exit 2; }

sed -E 's/^#{1,6}[[:space:]]+(.*)$/**\1**/' \
  | awk '{ if (length($0) == 0) print ">"; else print "> " $0 }' \
  | pbcopy
