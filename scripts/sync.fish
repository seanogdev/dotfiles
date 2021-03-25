ln -sf $DOTFILES_PATH/fish $HOME/.config
ln -sf $DOTFILES_PATH/.gitconfig $HOME/
ln -sf $DOTFILES_PATH/.editorconfig $HOME/
ln -sf $DOTFILES_PATH/sync/.Brewfile $HOME/
ln -sf $DOTFILES_PATH/sync/.Npmfile $HOME/

# sync sensitive functions
set -l cloudFunctionsPath $ICLOUD_DOTFILES_PATH/fish/functions
if test -d $cloudFunctionsPath
    ln -sf $cloudFunctionsPath/* $DOTFILES_PATH/fish/functions
end

# sync fonts
set -l cloudFontsPath $ICLOUD_DOTFILES_PATH/sync/fonts
if test -d $cloudFontsPath
    ln -sf $cloudFontsPath/* $HOME/Library/Fonts/
end

# sync ngrok
set -l cloudNgrokPath $ICLOUD_DOTFILES_PATH/sync/ngrok.yml
if test -e $cloudNgrokPath
    ln -sf $cloudNgrokPath $HOME/ngrok.yml
end
