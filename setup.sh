#! /usr/bin/env bash

cd "$(dirname "$0")/.."

set -e

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] %s\n" "$1"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s" "$1"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
  echo ''
  exit
}

info "Installing Homebrew..."

# if brew is not installed
if ! command -v brew &> /dev/null
then
    fail "Homebrew could not be found, please install it from https://brew.sh/"
fi

info "Installing stow"

brew install stow

info "Linking dotfiles with stow"

stow -d "$HOME/projects/personal/dotfiles" -t "$HOME" --no-folding --adopt .

# TEMPORARY (2026-09-16): the delegate-context skill and its PreToolUse hooks are
# gone from the repo. A machine that has not run this yet still has hooks in
# ~/.claude/settings.json pointing at the deleted scripts, which fails every Read
# and Bash call. Delete this block once every machine has run setup.sh.
info "Removing the delegate-context hooks"

settings="$HOME/.claude/settings.json"
if [ -f "$settings" ] && command -v jq &> /dev/null && jq -e '.hooks' "$settings" > /dev/null 2>&1; then
  cp "$settings" "$settings.bak"
  jq 'del(.hooks)' "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
  info "Removed hooks from $settings, backup at $settings.bak"
fi

rm -rf "$HOME/.claude/skills/delegate-context" "$HOME/.agents/skills/delegate-context"
rm -f "$HOME/.claude/agents/bulk-reader.md" "$HOME/.claude/agents/code-writer.md" \
      "$HOME/.agents/agents/bulk-reader.md" "$HOME/.agents/agents/code-writer.md"

info "Installing Brewfile packages..."

sudo brew bundle install --global

info "Installing a global Node with pnpm"

PNPM_HOME="$HOME/Library/pnpm" PATH="$HOME/Library/pnpm/bin:$PATH" pnpm runtime set node lts -g

info "Installing fonts from iCloud..."

sh ./install-fonts.sh

info "Changing default shell"

echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells

chsh -s "$(which fish)"

