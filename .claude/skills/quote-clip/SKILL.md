---
name: quote-clip
description: Copy Claude's last chat message to the clipboard as a block quote, with markdown headings flattened to bold, for pasting into chat apps with limited markdown support. Use when the user says things like "copy that as a quote", "block quote that", "quote that for Slack", or "put > before each line".
---

Take your own immediately preceding chat message in this conversation, verbatim — the prose you sent, not tool output or system reminders.

Convert any markdown heading (`#` through `######`) to bold (`**text**`), then prefix every line with `> ` (blank lines get a bare `>`). Copy the result to the clipboard with `pbcopy` via a heredoc — don't retype it by hand or print it back.

Confirm to the user once it's copied.
