set -g FZF_DEFAULT_COMMAND 'rg --files'
set -g FZF_CTRL_T_COMMAND "command find -L \$dir -type f 2> /dev/null | sed '1d; s#^\./##'"
