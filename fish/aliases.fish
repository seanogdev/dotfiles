#! /usr/bin/env fish

# set -l workAliasesPath "$ICLOUD_DOTFILES_PATH/fish/aliases.fish"

# if test -n $workAliasesPath
#     source $workAliasesPath
# end

# Easier navigation: .., ..., ...., ....., ~ and -
function ..
    cd ..
end
function ...
    cd ../..
end
function ....
    cd ../../..
end
function .....
    cd ../../../..
end

# Google Chrome
alias chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
alias canary="/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"

# IP addresses
alias ip-wan="dig +short myip.opendns.com @resolver1.opendns.com"
alias ip-lan="ipconfig getifaddr en0"
alias ip-all="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# Flush Directory Service cache
alias flush="dscacheutil -flushcache; killall -HUP mDNSResponder"

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user; killall Finder"

# Utility commands
alias s="source ~/.config/fish/config.fish"
alias c="clear"
alias lockbegone="git checkout origin/HEAD -- ./package-lock.json"


