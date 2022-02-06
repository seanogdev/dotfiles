
function reload --description 'Reload the shell (i.e. invoke as a login shell)'
    clear
    exec $SHELL -l
end
