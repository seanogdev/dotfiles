function git-lazy
    git add .
    git commit -a -m $argv
    git push --set-upstream origin (git-current-branch)
end
