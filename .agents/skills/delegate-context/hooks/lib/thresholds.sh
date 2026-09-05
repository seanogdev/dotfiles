#!/bin/bash
# Shared size check for the delegate-context hooks. Sourced, not run
# directly, so it can be unit tested on its own later.

DELEGATE_CONTEXT_MIN_LINES="${DELEGATE_CONTEXT_MIN_LINES:-350}"
case "$DELEGATE_CONTEXT_MIN_LINES" in ''|*[!0-9]*) DELEGATE_CONTEXT_MIN_LINES=350 ;; esac

# should_delegate_file <path>
# Prints a block reason and returns 0 if the file is over the line
# threshold. Returns 1 (silent) if it should be read directly, including
# when the path is empty or does not exist.
should_delegate_file() {
  local file_path="$1"

  if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    return 1
  fi

  local lines
  lines=$(wc -l < "$file_path" 2>/dev/null | tr -d ' ' || echo 0)

  if [ "$lines" -gt "$DELEGATE_CONTEXT_MIN_LINES" ]; then
    echo "File is ${lines} lines (threshold: ${DELEGATE_CONTEXT_MIN_LINES}). Delegate this read to the bulk-reader subagent (Agent tool, subagent_type \"bulk-reader\") instead of reading it directly. If you need exact content for editing, re-read with an offset/limit for just the section you need."
    return 0
  fi

  return 1
}
