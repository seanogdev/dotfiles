---
name: quote-clip
description: Copy Claude's last chat message to the clipboard as a block quote, with markdown headings flattened to bold, for pasting into chat apps with limited markdown support. Use when the user says things like "copy that as a quote", "block quote that", "quote that for Slack", or "put > before each line".
---

Take your own immediately preceding chat message in this conversation, verbatim — the prose you sent, not tool output or system reminders.

Hand it to the `quote-formatter` subagent (via the Agent tool) as the prompt, unmodified. That subagent converts markdown headings to bold, prefixes every line with `> `, and copies the result to the clipboard.

Confirm to the user once it's copied.
