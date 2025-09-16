#!/usr/bin/env bash

# Originally from https://github.com/andrew8088/dotfiles/blob/main/install/bootstrap.sh
# bootstrap installs things.

cd "$(dirname "$0")/.."
ICLOUD_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

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

copy_icloud_data() {
  ## fonts
  if [ -d "$ICLOUD_PATH/Code/dotfiles/sync/fonts" ]
  then
      cp -Rf "$ICLOUD_PATH/Code/dotfiles/sync/fonts/"* "$HOME/Library/Fonts/"
      success "Copied fonts"
  else
      fail "No fonts found in iCloud"
  fi

  ## sensitive functions
  if [ -d "$ICLOUD_PATH/Code/dotfiles/sync/fish/functions" ]
  then
      ln -sf  "$ICLOUD_PATH/Code/dotfiles/sync/fish/functions"* "$HOME/.config/fish/functions/"
      success "Linked sensitive functions"
  else
      fail "No sensitive functions found in iCloud"
  fi
}

copy_icloud_data

echo ''
echo ''
success 'All installed!'
