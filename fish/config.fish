set -x DOTFILES_PATH $HOME/dotfiles
set -x ICLOUD_DOTFILES_PATH "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles"

source ~/.config/fish/aliases.fish

# golang
set -x GOPATH $HOME/go
set -x GOBINPATH $GOPATH/bin

# general paths

set -x PATH $HOME/bin $PATH
set -x PATH $GOBINPATH $PATH
set -x PATH /opt/homebrew/bin $PATH
set -x PATH /usr/local/bin $PATH
set -x PATH /usr/local/sbin $PATH
set -x PATH /usr/local/opt/go/libexec/bin $PATH
set -x PATH "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" $PATH

# Start Starship
starship init fish | source

# tabtab source for packages
# uninstall by removing these lines
if [ -f "$HOME/.config/tabtab/fish/__tabtab.fish" ]
    source "$HOME/.config/tabtab/fish/__tabtab.fish"
end
