function git-current-branch --description 'Get the current git branch'
    git rev-parse --abbrev-ref HEAD
end
