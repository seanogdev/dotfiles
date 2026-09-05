function git-lazy
    git add .
    if test (count $argv) -eq 0
        set -l message (git diff --cached | claude -p "Write a concise, conventional git commit message for this diff. Output only the commit message, no explanation or quotes.")
        git commit -m "$message"
    else
        git commit -m "$argv"
    end
    git push --set-upstream origin (git-current-branch)
end
