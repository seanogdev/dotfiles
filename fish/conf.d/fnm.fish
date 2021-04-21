set -gx PATH /var/folders/8d/w_mvjyy91v7dwvtllyzljrz40000gn/T/fnm_multishells/2021_1618965285286/bin $PATH
set -gx FNM_MULTISHELL_PATH /var/folders/8d/w_mvjyy91v7dwvtllyzljrz40000gn/T/fnm_multishells/2021_1618965285286
set -gx FNM_DIR "/Users/seanogrady/.fnm"
set -gx FNM_LOGLEVEL info
set -gx FNM_NODE_DIST_MIRROR "https://nodejs.org/dist"
set -gx FNM_ARCH x64
function _fnm_autoload_hook --on-variable PWD --description 'Change Node version on directory change'
    status --is-command-substitution; and return
    if test -f .node-version -o -f .nvmrc
        fnm use
    end
end

_fnm_autoload_hook

fnm env | source
