#!/bin/bash
# Block WebFetch for npmjs.org/npmjs.com → use npmx.dev instead

INPUT=$(cat)
URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty')

if [[ "$URL" == *"npmjs.org"* || "$URL" == *"npmjs.com"* ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Do not use npmjs.org/npmjs.com. Use npmx.dev instead for the same package information."
  }
}
EOF
fi
