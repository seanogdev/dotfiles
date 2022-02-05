#! /usr/bin/env fish

set -x DOTFILES_PATH $HOME/dotfiles
set -x ICLOUD_DOTFILES_PATH "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles"

source ~/.config/fish/aliases.fish

# golang
set -x GOPATH $HOME/go
set -x GOBINPATH $GOPATH/bin

# general paths

fish_add_path $HOME/bin
fish_add_path $GOBINPATH
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/opt/coreutils/libexec/gnubin
fish_add_path /usr/local/bin
fish_add_path /usr/local/sbin
fish_add_path /usr/local/opt/go/libexec/bin
fish_add_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
