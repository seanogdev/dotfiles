#! /usr/bin/env sh

DOTFILES_PATH=$HOME/dotfiles
ICLOUD_DOTFILES_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles"

ln -sf $DOTFILES_PATH/fish $HOME/.config/
ln -sf $DOTFILES_PATH/.gitconfig $HOME/
ln -sf $DOTFILES_PATH/.editorconfig $HOME/
ln -sf $DOTFILES_PATH/sync/.Brewfile $HOME/
ln -sf $DOTFILES_PATH/sync/.Npmfile $HOME/
ln -sf $DOTFILES_PATH/sync/.nvm $HOME/

## sync fonts
cloudFontsPath="$ICLOUD_DOTFILES_PATH/sync/fonts"
echo $cloudFontsPath

if [[ -d $cloudFontsPath ]]
then
echo  $cloudFontsPath
cp -Rf "$cloudFontsPath/"* $HOME/Library/Fonts/ && ls -l $HOME/Library/Fonts/
fi

## sync sensitive functions
cloudFunctionsPath="$ICLOUD_DOTFILES_PATH/fish/functions"
if [[ -d $cloudFunctionsPath ]]
then
  ln -sf "$cloudFunctionsPath/"* $DOTFILES_PATH/fish/functions/ && ls -l $DOTFILES_PATH/fish/functions/
fi

## sync ngrok
cloudNgrokPath="$ICLOUD_DOTFILES_PATH/sync/ngrok.yml"
if [[ -f $cloudNgrokPath ]]
then
  ln -sf $cloudNgrokPath $HOME/
fi
