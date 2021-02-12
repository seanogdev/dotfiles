#! /usr/local/bin/fish

set -l workAliasesPath "$ICLOUD_DOTFILES_PATH/fish/aliases.fish"

if test -n $workAliasesPath
    source $workAliasesPath
end

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

# Get macOS Software Updates, Homebrew updates, npm, and global installed packages
alias update="softwareupdate -i -a; bubu; npm install npm -g; npm update -g"

# Google Chrome
alias chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
alias canary="/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# Flush Directory Service cache
alias flush="dscacheutil -flushcache; killall -HUP mDNSResponder"

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user; killall Finder"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"


# Utility commands
alias lockbegone="git checkout origin/master -- ./package-lock.json"

