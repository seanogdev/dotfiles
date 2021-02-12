set -l DIR (dirname "$0")
cd $DIR

ln -sf $HOME/dotfiles/fish $HOME/.config
ln -sf $HOME/dotfiles/.gitconfig $HOME/
ln -sf $HOME/dotfiles/sync/.Brewfile $HOME/
ln -sf $HOME/dotfiles/sync/.Npmfile $HOME/

# sync sensitive functions
set -l cloudFunctionsPath "$ICLOUD_DOTFILES_PATH/fish/functions"
if test -d $cloudFunctionsPath
    ln -sf $cloudFunctionsPath/* $HOME/dotfiles/fish/functions
end

# sync fonts
set -l cloudFontsPath "$ICLOUD_DOTFILES_PATH/sync/fonts"
if test -d $cloudFontsPath
    ln -sf $cloudFontsPath $HOME/Library/Fonts/CloudFonts
end

# sync ngrok
set -l cloudNgrokPath "$ICLOUD_DOTFILES_PATH/sync/ngrok.yml"
if test -e $cloudNgrokPath
    ln -sf $cloudNgrokPath $HOME/ngrok.yml
end


