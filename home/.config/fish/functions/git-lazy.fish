function git-lazy
    argparse q/quiet v/verbose no-verify s/signoff no-gpg-sign amend allow-empty f/force 'force-with-lease=?' dry-run tags -- $argv
    or return

    set -l commit_flags
    set -l push_flags
    for name in quiet verbose no-verify
        set -l var _flag_(string replace -a - _ $name)
        if set -q $var
            set -a commit_flags --$name
            set -a push_flags --$name
        end
    end
    for name in signoff no-gpg-sign amend allow-empty
        set -l var _flag_(string replace -a - _ $name)
        set -q $var; and set -a commit_flags --$name
    end
    for name in force dry-run tags
        set -l var _flag_(string replace -a - _ $name)
        set -q $var; and set -a push_flags --$name
    end
    if set -q _flag_force_with_lease
        if test -n "$_flag_force_with_lease"
            set -a push_flags --force-with-lease=$_flag_force_with_lease
        else
            set -a push_flags --force-with-lease
        end
    end

    git add .
    or return
    if test (count $argv) -eq 0
        set -l message (git diff --cached | claude -p "Write a concise, conventional git commit message for this diff. Output only the commit message, no explanation or quotes.")
        git commit $commit_flags -m "$message"
    else
        git commit $commit_flags -m "$argv"
    end
    or return
    git push $push_flags --set-upstream origin (git-current-branch)
end
