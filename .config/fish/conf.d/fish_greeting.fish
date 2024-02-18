function fish_greeting --description 'Print the shell greeting'
    set -l c_n (set_color normal)
    set -l c_w (set_color cyan)

    set -l location (printf "%sWelcome back to %s%s%s bitch 👋" $c_n $c_w (hostname) $c_n)
    set -l datetime (printf "%sIt is %s%s%s (%s) on %s%s%s" $c_n $c_w (date +%T) $c_n (date +%Z) $c_w (date +%F) $c_n)

    printf "\n%s\n%s\n" $location $datetime
end
