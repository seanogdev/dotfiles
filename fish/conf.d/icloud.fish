set -x ICLOUD_DOTFILES_PATH "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles"

## fonts
if test -d "$ICLOUD_DOTFILES_PATH/sync/fonts"
    cp -Rf "$ICLOUD_DOTFILES_PATH/sync/fonts/"* "$HOME/Library/Fonts/"
end

## sensitive functions
if test -d "$ICLOUD_DOTFILES_PATH/sync/fish/functions"
    ln -sf  "$ICLOUD_DOTFILES_PATH/sync/fish/functions"* "$HOME/.config/fish/functions/"
end