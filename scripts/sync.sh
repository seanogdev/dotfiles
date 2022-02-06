#! /usr/bin/env sh

DOTFILES_PATH=$HOME/dotfiles
ICLOUD_DOTFILES_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles"
FISH_CONFIG_PATH="$ICLOUD_DOTFILES_PATH/.config/fish"
SYNC_FOLDER_PATH="$ICLOUD_DOTFILES_PATH/sync"

# config files
ln -sf "$DOTFILES_PATH/.config/"* $HOME/.config
ln -sf $DOTFILES_PATH/.gitconfig $HOME/
ln -sf $DOTFILES_PATH/.editorconfig $HOME/
ln -sf $DOTFILES_PATH/sync/.Brewfile $HOME/
ln -sf $DOTFILES_PATH/sync/.Npmfile $HOME/
ln -sf $DOTFILES_PATH/sync/.nvm $HOME/

## fonts
cloudFontsPath="$SYNC_FOLDER_PATH/fonts"
if [[ -d $cloudFontsPath ]]
then
cp -Rf "$cloudFontsPath/"* $HOME/Library/Fonts/
ls -l $HOME/Library/Fonts/
fi

## sensitive functions
cloudFunctionsPath="$FISH_CONFIG_PATH/functions"
if [[ -d $cloudFunctionsPath ]]
then
  ln -sf "$cloudFunctionsPath/"* $DOTFILES_PATH/fish/functions/
  ls -l $DOTFILES_PATH/fish/functions/
fi

## ngrok
cloudNgrokPath="$SYNC_FOLDER_PATH/ngrok.yml"
if [[ -f $cloudNgrokPath ]]
then
  ln -sf $cloudNgrokPath $HOME/
fi
