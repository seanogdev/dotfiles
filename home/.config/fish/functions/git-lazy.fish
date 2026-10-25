function git-lazy
    argparse n/no-verify -- $argv
    or return
    set -l verify_flag
    set -q _flag_no_verify; and set verify_flag --no-verify

    git add .
    or return
    if test (count $argv) -eq 0
        set -l message (git diff --cached | claude -p "Write a concise, conventional git commit message for this diff. Output only the commit message, no explanation or quotes.")
        git commit $verify_flag -m "$message"
    else
        git commit $verify_flag -m "$argv"
    end
    or return
    git push $verify_flag --set-upstream origin (git-current-branch)
end
