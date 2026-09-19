---
name: quote-clip
description: Copy Claude's last chat reply to the clipboard as a block quote, for pasting into apps with limited markdown support. Covers any phrasing that describes the visual result — a quote marker, a ">" symbol, or similar mark before each line — even when the word "quote" is not used.
license: MIT
compatibility: Requires macOS (pbcopy)
---

1. Use your last chat message in this conversation.
2. Use only the prose of that message. Copy it word for word.
3. Do not use tool output. Do not use system reminders.
4. Pipe that text into `scripts/quote.sh`. Use a heredoc. Do not retype the text by hand.
5. Do not print the result in the chat.
6. After you copy the text, tell the user.
