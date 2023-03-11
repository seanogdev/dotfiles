#! /usr/bin/env fish

# Easier navigation: .., ..., ...., .....
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Shortcuts
alias ls=exa
alias sl=exa
alias c='clear'

# IP addresses
alias ip-wan="dig +short myip.opendns.com @resolver1.opendns.com"
alias ip-lan="ipconfig getifaddr en0"
alias ip-all="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Utility commands
alias s="source ~/.config/fish/config.fish"
alias c="clear"
alias lockbegone="git checkout origin/HEAD -- ./package-lock.json"


