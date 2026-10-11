set -gx PNPM_HOME "$HOME/Library/pnpm"
fish_add_path $PNPM_HOME
fish_add_path --move --path $PNPM_HOME/bin
