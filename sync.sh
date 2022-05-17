#! /usr/bin/env sh

LOCAL_DOTFILES_PATH="$HOME/dotfiles"
LOCAL_FISHCONFIG_PATH="$HOME/.config/fish"
CLOUD_DOTFILES_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles"
CLOUD_FISH_CONFIG_PATH="$CLOUD_DOTFILES_PATH/.config/fish"
CLOUD_SYNC_FOLDER_PATH="$CLOUD_DOTFILES_PATH/sync"

# config files
ln -sf "$LOCAL_DOTFILES_PATH/.gitconfig" $HOME/
ln -sf "$LOCAL_DOTFILES_PATH/.editorconfig" $HOME/
ln -sf "$LOCAL_DOTFILES_PATH/sync/.Brewfile" $HOME/
ln -sf "$LOCAL_DOTFILES_PATH/sync/.Npmfile" $HOME/
ln -sf "$LOCAL_DOTFILES_PATH/sync/.nvm" $HOME/

# fish config files
if [ ! -d $LOCAL_FISHCONFIG_PATH ]; then
    mkdir -p $LOCAL_FISHCONFIG_PATH
fi
ln -sf "$LOCAL_DOTFILES_PATH/.config/fish/completions/"* $LOCAL_FISHCONFIG_PATH
ln -sf "$LOCAL_DOTFILES_PATH/.config/fish/conf.d/"* $LOCAL_FISHCONFIG_PATH
ln -sf "$LOCAL_DOTFILES_PATH/.config/fish/functions/"* $LOCAL_FISHCONFIG_PATH
ln -sf "$LOCAL_DOTFILES_PATH/.config/fish/aliases.fish" $LOCAL_FISHCONFIG_PATH
ln -sf "$LOCAL_DOTFILES_PATH/.config/fish/config.fish" $LOCAL_FISHCONFIG_PATH
ln -sf "$LOCAL_DOTFILES_PATH/.config/fish/fish_plugins" $LOCAL_FISHCONFIG_PATH
fisher update

## fonts
cloudFontsPath="$CLOUD_SYNC_FOLDER_PATH/fonts"
if [[ -d $cloudFontsPath ]]
then
    cp -Rf "$cloudFontsPath/"* $HOME/Library/Fonts/
fi

## sensitive functions
cloudFunctionsPath="$CLOUD_FISH_CONFIG_PATH/functions"
if [[ -d $cloudFunctionsPath ]]
then
    ln -sf "$cloudFunctionsPath/"* $LOCAL_FISHCONFIG_PATH/functions/
fi

## ngrok
cloudNgrokPath="$CLOUD_SYNC_FOLDER_PATH/ngrok.yml"
if [[ -f $cloudNgrokPath ]]
then
    ln -sf $cloudNgrokPath $HOME/
fi

echo "Successfully synced data from dotfiles."
