#! /usr/bin/env sh

CLOUD_DOTFILES_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles"
# CLOUD_FISH_CONFIG_PATH="$CLOUD_DOTFILES_PATH/.config/fish"

## fonts
cloudFontsPath="$CLOUD_DOTFILES_PATH/sync/fonts"
if [[ -d $cloudFontsPath ]]
then
    cp -Rf "$cloudFontsPath/"* $HOME/Library/Fonts/
fi

# ## sensitive functions
# cloudFunctionsPath="$CLOUD_FISH_CONFIG_PATH/functions"
# if [[ -d $cloudFunctionsPath ]]
# then
#     ln -sf "$cloudFunctionsPath/"* $LOCAL_FISHCONFIG_PATH/functions/
# fi

echo "Successfully synced data from dotfiles. Make sure to run fisher manually"
