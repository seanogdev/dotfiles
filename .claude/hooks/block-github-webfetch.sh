#!/bin/bash
# Block WebFetch for GitHub repo URLs → use gh CLI instead
# Allows through: docs, blog, community, education, gist pages, etc.

INPUT=$(cat)
URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty')

[[ "$URL" != *"github.com"* ]] && exit 0

path=$(echo "$URL" | sed -E 's|https?://[^/]*github\.com||')

if echo "$path" | grep -qE '^/[^/]+/[^/]+/(pull|pulls|issue|issues|commit|commits|releases|actions|compare|tree|blob|blame|raw)(/|$)' || \
   echo "$path" | grep -qE '^/[^/]+/[^/]+/?$'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Do not use WebFetch for GitHub repository URLs. Use the `gh` CLI instead (e.g., `gh api`, `gh pr view`, `gh issue view`, `gh repo view`, `gh release view`, etc.)."
  }
}
EOF
fi
