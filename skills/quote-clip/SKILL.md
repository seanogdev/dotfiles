---
name: quote-clip
description: Copy Claude's last chat message to the clipboard as a block quote, with markdown headings flattened to bold, for pasting into chat apps with limited markdown support. Use when the user says things like "copy that as a quote", "block quote that", "quote that for Slack", or "put > before each line".
license: MIT
compatibility: Requires macOS (pbcopy)
---

1. Use your last chat message in this conversation.
2. Use only the prose of that message. Copy it word for word.
3. Do not use tool output. Do not use system reminders.
4. Change every markdown heading (`#` through `######`) to bold (`**text**`).
5. Put `> ` in front of every line.
6. Put a bare `>` on each blank line.
7. Copy the result to the clipboard with `pbcopy`. Use a heredoc. Do not retype the text by hand.
8. Do not print the result in the chat.
9. After you copy the text, tell the user.
