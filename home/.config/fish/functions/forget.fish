function forget --description 'Delete the last N commands from fish history'
    set -l count 1
    if set -q argv[1]
        if not string match -qr '^[1-9][0-9]*$' -- $argv[1]
            echo "forget: expected a positive number, got '$argv[1]'" >&2
            return 1
        end
        set count $argv[1]
    end

    set -l self (status current-commandline)
    set -l targets (history --null --max (math $count + 1) | string split0)
    if test "$targets[1]" = "$self"
        set -e targets[1]
    end
    set targets $targets[1..$count]

    if not set -q targets[1]
        echo "forget: no history entries found" >&2
        return 1
    end

    history delete --exact --case-sensitive -- $targets $self
    echo "Forgot "(count $targets)" command(s)."
end
