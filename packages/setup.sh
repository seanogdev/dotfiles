#! /usr/bin/env sh

DIR=$(dirname "$0")
cd "$DIR"

. ../scripts/functions.sh

sudo -v

info "Installing Brewfile packages..."
brew bundle --global
success "Finished installing Brewfile packages."
