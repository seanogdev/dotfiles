---
description: Configure the statusLine to use the Fish script from dotfiles
---

Update the `~/.claude/settings.json` file to configure the statusLine.

**Requirements:**
1. Read the existing `~/.claude/settings.json` file (if it exists)
2. Update or add the `statusLine` configuration to use the Fish script at `~/.claude/statusline-command.fish`
3. Preserve all other settings that already exist in the file
4. The statusLine configuration should be:
   ```json
   "statusLine": {
     "type": "command",
     "command": "/opt/homebrew/bin/fish /Users/seanogrady/.claude/statusline-command.fish"
   }
   ```

**Expected Output:**
Confirm that the settings.json file has been updated and the statusLine is now configured.

**Note:** The `statusline-command.fish` script should already exist at `~/.claude/statusline-command.fish` (symlinked from dotfiles via stow).
