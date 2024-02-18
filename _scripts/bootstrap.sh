#!/usr/bin/env bash

# Originally from https://github.com/andrew8088/dotfiles/blob/main/install/bootstrap.sh
# bootstrap installs things.

cd "$(dirname "$0")/.."
DOTFILES=$(pwd -P)
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

link_file () {
  local src=$1 dst=$2

  local overwrite=
  local backup=
  local skip=
  local action=

  # if the src is a directory copy all of the files in the directory instead
  if [ -d "$src" ]; then
    for file in "$src"/*; do
      link_file "$file" "$dst/$(basename "$file")"
    done
  else
    if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]
    then

      if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
      then

        # ignoring exit 1 from readlink in case where file already exists
        # shellcheck disable=SC2155,SC2086
        local currentSrc="$(readlink $dst)"

        if [ "$currentSrc" == "$src" ]
        then

          skip=true;

        else

          user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
          [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
          # shellcheck disable=SC2162
          read -n 1 action  < /dev/tty

          case "$action" in
            o )
              overwrite=true;;
            O )
              overwrite_all=true;;
            b )
              backup=true;;
            B )
              backup_all=true;;
            s )
              skip=true;;
            S )
              skip_all=true;;
            * )
              ;;
          esac

        fi

      fi

      overwrite=${overwrite:-$overwrite_all}
      backup=${backup:-$backup_all}
      skip=${skip:-$skip_all}

      if [ "$overwrite" == "true" ]
      then
        rm -rf "$dst"
        success "removed $dst"
      fi

      if [ "$backup" == "true" ]
      then
        mv "$dst" "${dst}.backup"
        success "moved $dst to ${dst}.backup"
      fi

      if [ "$skip" == "true" ]
      then
        success "skipped $src"
      fi
    fi

    if [ "$skip" != "true" ]  # "false" or empty
    then
      ln -s "$1" "$2"
      success "linked $1 to $2"
    fi
  fi
}


prop () {
   PROP_KEY=$1
   PROP_FILE=$2
   PROP_VALUE=$(eval echo "$(cat "$PROP_FILE" | grep "$PROP_KEY" | cut -d'=' -f2)")
   echo "$PROP_VALUE"
}

install_dotfiles () {
  info 'installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false

  # shellcheck disable=SC2162
  find -H "$DOTFILES" -maxdepth 2 -name 'links.prop' | while read linkfile
  do
    # shellcheck disable=SC2002
    cat "$linkfile" | while read line
    do
        local src dst dir
        src=$(eval echo "$line" | cut -d '=' -f 1)
        dst=$(eval echo "$line" | cut -d '=' -f 2)
        # shellcheck disable=SC2086
        dir=$(dirname $dst)

        mkdir -p "$dir"
        link_file "$src" "$dst"
    done
  done
}

copy_icloud_data() {
  ## fonts
  if [ -d "$ICLOUD_PATH/Code/dotfiles/sync/fonts" ]
  then
      cp -Rf "$ICLOUD_PATH/Code/dotfiles/sync/fonts/"* "$HOME/Library/Fonts/"
      success "Copied fonts"
  fi

  ## sensitive functions
  if [ -d "$ICLOUD_PATH/Code/dotfiles/sync/fish/functions" ]
  then
      ln -sf  "$ICLOUD_PATH/Code/dotfiles/sync/fish/functions"* "$HOME/.config/fish/functions/"
      success "Linked sensitive functions"
  fi
}

install_dotfiles
copy_icloud_data

echo ''
echo ''
success 'All installed!'