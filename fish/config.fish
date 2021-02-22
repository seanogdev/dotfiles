set -x DOTFILES_PATH $HOME/dotfiles
set -x ICLOUD_DOTFILES_PATH ~/Library/Mobile\ Documents/com~apple~CloudDocs/Code/dotfiles
source ~/.config/fish/aliases.fish

# golang
set -x GOPATH $HOME/go
set -x GOBINPATH $GOPATH/bin

# general paths
set -x PATH $HOME/bin $PATH
set -x PATH $GOBINPATH $PATH
set -x PATH /usr/local/bin $PATH
set -x PATH /usr/local/sbin $PATH
set -x PATH /usr/local/opt/go/libexec/bin $PATH
set -x PATH "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" $PATH

# Start fnm
# fnm env --use-on-cd | source

# Start Starship
starship init fish | source

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/fish/__tabtab.fish ]; and source ~/.config/tabtab/fish/__tabtab.fish; or true
