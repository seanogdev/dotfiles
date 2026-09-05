#!/usr/bin/env bash
# Idempotently merge the delegate-context PreToolUse hooks into
# ~/.claude/settings.json. Safe to re-run: skips entries already
# installed, and touches nothing else in the file. This machine's
# settings.json is not otherwise synced from dotfiles (per-machine
# fields like `model` differ), so this merges only the `hooks` key.

set -euo pipefail

SETTINGS="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"

READ_HOOK_CMD='$HOME/.claude/skills/delegate-context/hooks/check-file-size'
BASH_HOOK_CMD='$HOME/.claude/skills/delegate-context/hooks/check-bash-read'

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

if ! jq -e . "$SETTINGS" > /dev/null 2>&1; then
  echo "error: $SETTINGS is not valid JSON, refusing to edit it" >&2
  exit 1
fi

additions=$(jq -n \
  --arg readCmd "$READ_HOOK_CMD" \
  --arg bashCmd "$BASH_HOOK_CMD" \
  '[
    {matcher: "Read", hooks: [{type: "command", command: $readCmd}]},
    {matcher: "Bash", hooks: [{type: "command", command: $bashCmd}]}
  ]')

tmp=$(mktemp)
jq --argjson additions "$additions" '
  .hooks.PreToolUse = (
    (.hooks.PreToolUse // []) as $existing
    | ($existing | [.[].hooks[]?.command]) as $existingCommands
    | $existing + [
        $additions[]
        | select(([.hooks[].command] - $existingCommands) != [])
      ]
  )
' "$SETTINGS" > "$tmp"

jq -e . "$tmp" > /dev/null
mv "$tmp" "$SETTINGS"

echo "delegate-context hooks present in $SETTINGS"
