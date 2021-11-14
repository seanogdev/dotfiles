#! /usr/bin/env sh

DOTFILES_PATH=$HOME/dotfiles
ICLOUD_DOTFILES_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles"
cloudFontsPath="$ICLOUD_DOTFILES_PATH/sync/fonts"
cloudFunctionsPath="$ICLOUD_DOTFILES_PATH/fish/functions"
cloudNgrokPath="$ICLOUD_DOTFILES_PATH/sync/ngrok.yml"

# config files
ln -sf $DOTFILES_PATH/fish $HOME/.config/
ln -sf $DOTFILES_PATH/.gitconfig $HOME/
ln -sf $DOTFILES_PATH/.editorconfig $HOME/
ln -sf $DOTFILES_PATH/sync/.Brewfile $HOME/
ln -sf $DOTFILES_PATH/sync/.Npmfile $HOME/
ln -sf $DOTFILES_PATH/sync/.nvm $HOME/

## fonts
if [[ -d $cloudFontsPath ]]
then
cp -Rf "$cloudFontsPath/"* $HOME/Library/Fonts/
ls -l $HOME/Library/Fonts/
fi

## sensitive functions
if [[ -d $cloudFunctionsPath ]]
then
  ln -sf "$cloudFunctionsPath/"* $DOTFILES_PATH/fish/functions/
  ls -l $DOTFILES_PATH/fish/functions/
fi

## ngrok
if [[ -f $cloudNgrokPath ]]
then
  ln -sf $cloudNgrokPath $HOME/
fi
