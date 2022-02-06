function git-push-fast
    git commit -a -n -m $argv
    git push --set-upstream origin (git-current-branch)
end
