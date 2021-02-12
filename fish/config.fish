source ~/.config/fish/aliases.fish

set -x ICLOUD_DOTFILES_PATH ~/Library/Mobile\ Documents/com~apple~CloudDocs/Code/dotfiles

# golang
set -x GOPATH $HOME/go
set -x GOBINPATH $GOPATH/bin

# general paths
set -x PATH $HOME/bin $PATH
set -x PATH $GOBINPATH $PATH
set -x PATH /usr/local/bin $PATH
set -x PATH /usr/local/sbin $PATH
set -x PATH /usr/local/opt/go/libexec/bin $PATH
set -x PATH /usr/local/opt/node@12/bin $PATH
set -x PATH "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" $PATH

# Start fnm
fnm env | source

# Start Starship
starship init fish | source