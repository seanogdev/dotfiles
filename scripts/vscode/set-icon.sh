#! /usr/bin/env sh

DIR=$(dirname "$0")
cd "$DIR"

source ../functions.sh

if [[ $1 == "-o" ]]; then
    set -o xtrace
fi

vsc_dir="/Applications/Visual Studio Code.app/Contents/Resources"

# very dangerous

yes | cp "Code.icns" "$vsc_dir/Code.icns"

killall Finder

killall Dock

echo "Dark icon for Visual Studio Code is set up ! 🌈"
