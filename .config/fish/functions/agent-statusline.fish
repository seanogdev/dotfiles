#!/opt/homebrew/bin/fish

function agent-statusline -a harness
    test -z "$harness"; and set harness claude

set -g reset '\033[0m'
set -g dim '\033[38;5;242m'
set -g green '\033[1;32m'
set -g amber '\033[1;33m'
set -g red '\033[1;31m'

set -l cyan '\033[1;36m'
set -l magenta '\033[1;35m'
set -l orange '\033[38;5;208m'
set -l periwinkle '\033[38;5;111m'
set -l blue '\033[38;5;75m'
set -l gold '\033[38;5;220m'
set -l rose '\033[38;5;167m'
set -l lime '\033[38;5;149m'

set -l separator (printf " %b•%b " $dim $reset)
set -l optimal_limit 200000

set -l input (cat | string collect)
set -l fields

switch $harness
    case claude
        set fields (printf '%s' $input | jq -r '
            def window($key; $name):
                (.rate_limits // null) as $limits
                | if ($limits | type) == "object" then ($limits[$key] // {})
                  elif ($limits | type) == "array" then (($limits | map(select(.window == $name)) | first) // {})
                  else {} end;
            def text($value): (($value // "") | tostring) as $s | if $s == "" then "__AGENT_STATUSLINE_EMPTY__" else $s end;
            [
                text(.model.display_name),
                text(.workspace.current_dir),
                ( (.context_window.current_usage.input_tokens // 0)
                + (.context_window.current_usage.cache_creation_input_tokens // 0)
                + (.context_window.current_usage.cache_read_input_tokens // 0) ),
                (.context_window.context_window_size // 200000),
                text(.effort.level),
                text(window("five_hour"; "5h").used_percentage),
                text(window("five_hour"; "5h").resets_at),
                text(window("seven_day"; "7d").used_percentage),
                text(window("seven_day"; "7d").resets_at)
            ] | @tsv' | string split \t)
    case pi
        set fields (printf '%s' $input | jq -r '
            def text($value): (($value // "") | tostring) as $s | if $s == "" then "__AGENT_STATUSLINE_EMPTY__" else $s end;
            [
                text(.model.display_name // .model.name // .model),
                text(.workspace.current_dir // .cwd),
                (.context_window.current_usage.input_tokens // .tokens_used // 0),
                (.context_window.context_window_size // .context_size // 200000),
                text(.effort.level // .effort),
                text(.rate_limits.five_hour.used_percentage),
                text(.rate_limits.five_hour.resets_at),
                text(.rate_limits.seven_day.used_percentage),
                text(.rate_limits.seven_day.resets_at),
                (.usage.input // 0),
                (.usage.output // 0),
                (.usage.cacheRead // 0),
                (.usage.cacheWrite // 0),
                (.usage.reasoning // 0),
                (.usage.cost // 0)
            ] | @tsv' | string split \t)
    case '*'
        echo "agent-statusline: unknown harness '$harness'" >&2
        return 2
end

set fields (string replace -a __AGENT_STATUSLINE_EMPTY__ '' -- $fields)

set -l model (string replace " (1M context)" " 1M" -- $fields[1])
set -l cwd $fields[2]
set -l tokens_used $fields[3]
set -l context_size $fields[4]
set -l effort $fields[5]
set -l total_input $fields[10]
set -l total_output $fields[11]
set -l cache_read $fields[12]
set -l cache_write $fields[13]
set -l reasoning_tokens $fields[14]
set -l total_cost $fields[15]

set -l dir_name (basename "$cwd")
set -l git_branch
test -n "$cwd"; and set git_branch (git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
set -l segment1 (printf '%b%s%b' $cyan $dir_name $reset)
if test -n "$git_branch"
    set segment1 "$segment1"(printf ' %b󰘬 %s%b' $magenta $git_branch $reset)
end

set -l model_icon ✻
set -l model_icon_color $orange
set -l model_color $orange

if test "$harness" = pi
    set model_icon π
    set model_icon_color $lime
    set model_color $lime
else if string match -qi "*haiku*" "$model"
    set model_color $periwinkle
else if string match -qi "*sonnet*" "$model"
    set model_color $blue
else if string match -qi "*opus*" "$model"
    set model_color $rose
end
set -l segment2 (printf '%b%s%b %b%s%b' $model_icon_color $model_icon $reset $model_color $model $reset)

set -l segment3 ""
if test -n "$effort" -a "$effort" != off
    set -l effort_color
    switch $effort
        case minimal low
            set effort_color $periwinkle
        case medium
            set effort_color $blue
        case high xhigh max
            set effort_color $gold
        case '*'
            set effort_color $rose
    end
    set segment3 (printf '%b󰓅 %s%b' $effort_color $effort $reset)
end

set -l segment3b ""
set -l ports (__agent_statusline_dev_server_ports "$cwd")
if test -n "$ports"
    set -l link (__agent_statusline_osc8 "http://localhost:$ports[1]" "󰖟 :$ports[1]")
    set segment3b (printf '%b%s%b' $lime $link $reset)
    if test (count $ports) -gt 1
        set segment3b "$segment3b"(printf '%b +%d%b' $dim (math (count $ports) - 1) $reset)
    end
end

set -l segment3c ""
if test -n "$cwd"
    set -l target (string replace -a ' ' %20 -- $cwd)
    set segment3c (printf '%b%s%b' $blue (__agent_statusline_osc8 "vscode://file$target" "󰨞 code") $reset)
end

test -z "$tokens_used"; and set tokens_used 0
test -z "$context_size"; and set context_size 200000
set -l used_pct (math --scale=2 "($tokens_used / $optimal_limit) * 100")
set -l segment4 (printf '%b󰆼 %s/%s [%s%%]%b' \
    (__agent_statusline_usage_color $used_pct) \
    (__agent_statusline_format_count $tokens_used 1) \
    (__agent_statusline_format_count $context_size 0) \
    (math --scale=0 "$used_pct") \
    $reset)

set -l pi_usage_segments
if test "$harness" = pi
    test -z "$total_input"; and set total_input 0
    test -z "$total_output"; and set total_output 0
    test -z "$cache_read"; and set cache_read 0
    test -z "$cache_write"; and set cache_write 0
    test -z "$reasoning_tokens"; and set reasoning_tokens 0
    test -z "$total_cost"; and set total_cost 0

    set -a pi_usage_segments (printf '%b↑%s ↓%s%b' $dim (__agent_statusline_format_count $total_input 1) (__agent_statusline_format_count $total_output 1) $reset)
    if test $cache_read -gt 0 -o $cache_write -gt 0
        set -a pi_usage_segments (printf '%bcache r%s/w%s%b' $dim (__agent_statusline_format_count $cache_read 1) (__agent_statusline_format_count $cache_write 1) $reset)
    end
    if test $reasoning_tokens -gt 0
        set -a pi_usage_segments (printf '%bthink %s%b' $gold (__agent_statusline_format_count $reasoning_tokens 1) $reset)
    end
    if test (math --scale=0 "$total_cost * 1000000") -gt 0
        set -a pi_usage_segments (printf '%b$%.3f%b' $green $total_cost $reset)
    end
end

set -l rate_limits
set -a rate_limits (__agent_statusline_rate_limit_segment 5h "$fields[6]" "$fields[7]" "+%H:%M")
set -a rate_limits (__agent_statusline_rate_limit_segment 7d "$fields[8]" "$fields[9]" "+%d/%m")
if test "$harness" = claude
    set -a rate_limits (__agent_statusline_credits_segment)
end

set -l line1 $segment1 $segment2
test -n "$segment3"; and set -a line1 $segment3
test -n "$segment3b"; and set -a line1 $segment3b
test -n "$segment3c"; and set -a line1 $segment3c
set -l line2 $segment4 $pi_usage_segments $rate_limits

set line1 (string join "$separator" $line1)
set line2 (string join "$separator" $line2)
set -l single "$line1$separator$line2"

set -l stripped (string replace -ra '\e\][^\a\e]*(\e\\\\|\a)' '' -- "$single")
set stripped (string replace -ra '\e\[[0-9;]*m' '' -- "$stripped")
set -l wide_glyphs (string match -ar '[󰘬✻󰆼󰓅󰖟󰨞]' -- "$stripped" | count)
set -l vis_len (math (string length -- "$stripped") + $wide_glyphs)

set -l cols $COLUMNS
test -z "$cols"; and set cols (stty size </dev/tty 2>/dev/null | awk '{print $2}')
test -z "$cols"; and set cols (tput cols 2>/dev/null)
string match -qr '^[0-9]+$' -- "$cols"; or set cols 0
test "$harness" = pi; and set cols 9999

if test $vis_len -gt $cols
    printf '%s\n%s' "$line1" "$line2"
else
    printf '%s' "$single"
end
end

function __agent_statusline_usage_color -a pct
    if test $pct -lt 50
        printf '%s' $green
    else if test $pct -lt 80
        printf '%s' $amber
    else
        printf '%s' $red
    end
end

function __agent_statusline_format_count -a value scale
    if test $value -ge 1000000
        printf '%sM' (math --scale=$scale "$value / 1000000")
    else
        printf '%sk' (math --scale=$scale "$value / 1000")
    end
end

function __agent_statusline_rate_limit_segment -a label pct reset_at time_fmt
    test -z "$pct"; and return

    set -l rounded (printf "%.0f" "$pct")
    set -l color (__agent_statusline_usage_color $rounded)

    if test -n "$reset_at"
        set -l reset_time (date -r "$reset_at" "$time_fmt" 2>/dev/null; or echo $reset_at)
        printf '%b%s %b%s%%%b %b%s%b' $dim $label $color $rounded $reset $dim $reset_time $reset
    else
        printf '%b%s %b%s%%%b' $dim $label $color $rounded $reset
    end
end

function __agent_statusline_refresh_credits_cache -a cache
    set -l token (security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
    set -l org (jq -r '.oauthAccount.organizationUuid // empty' ~/.claude.json 2>/dev/null)
    test -n "$token" -a -n "$org"; or return

    set -l base https://api.anthropic.com/api/oauth
    set -l headers -H "Authorization: Bearer $token" -H 'anthropic-beta: oauth-2025-04-20'
    set -l usage (curl -sf --max-time 5 $base/usage $headers | string collect); or return
    set -l credits (curl -sf --max-time 5 $base/organizations/$org/prepaid/credits $headers | string collect); or return

    jq -n --argjson usage "$usage" --argjson credits "$credits" \
        '{enabled: $usage.extra_usage.is_enabled, credits: $credits}' >"$cache.tmp"
    and jq -e .credits.balance.money "$cache.tmp" >/dev/null
    and mv "$cache.tmp" "$cache"
    rm -f "$cache.tmp"
end

function __agent_statusline_credits_segment
    set -l cache ~/.cache/claude-statusline/credits.json
    set -l stamp "$cache.refresh"
    mkdir -p (path dirname $cache)

    set -l age (path mtime -R $cache 2>/dev/null; or echo 999999)
    set -l stamp_age (path mtime -R $stamp 2>/dev/null; or echo 999999)
    if test $age -gt 120 -a $stamp_age -gt 60
        touch $stamp
        fish -c (functions __agent_statusline_refresh_credits_cache | string collect)"
__agent_statusline_refresh_credits_cache '$cache'" </dev/null &>/dev/null &
        disown
    end

    test -f $cache; or return
    set -l credit (jq -r 'select(.enabled == true) | .credits
        | .balance.money as $m
        | ([.tranches[]?.granted_amount_minor_units // 0] | add // 0) as $granted
        | [($m.amount_minor / pow(10; $m.exponent)), $m.exponent, $m.currency,
           (if $granted > 0 then 100 - ($m.amount_minor * 100 / $granted) else 0 end)]
        | @tsv' $cache 2>/dev/null | string split \t)
    test (count $credit) -eq 4; or return

    set -l symbol
    switch $credit[3]
        case EUR
            set symbol €
        case USD
            set symbol \$
        case GBP
            set symbol £
        case '*'
            set symbol "$credit[3] "
    end
    set -l left (printf "%.*f" $credit[2] $credit[1])
    set -l color (__agent_statusline_usage_color (printf "%.0f" $credit[4]))
    printf '%bcredits %b%s%s%b' $dim $color $symbol $left $reset
end

function __agent_statusline_osc8 -a url label
    set -l st (printf '\e\\')
    printf '\e]8;;%s%s%s\e]8;;%s' $url $st $label $st
end

function __agent_statusline_dev_server_ports -a root
    test -n "$root"; or return

    set -l listeners (lsof -nP -iTCP -sTCP:LISTEN -F pn 2>/dev/null | awk '
        /^p/ { pid = substr($0, 2) }
        /^n/ {
            n = split(substr($0, 2), parts, ":")
            port = parts[n]
            if (port ~ /^[0-9]+$/ && !seen[pid " " port]++) print pid, port
        }')
    test -n "$listeners"; or return

    set -l pids (printf '%s\n' $listeners | awk '{print $1}' | sort -u | paste -sd, -)
    set -l matched (lsof -a -d cwd -p $pids -Fpn 2>/dev/null | awk -v root="$root" '
        /^p/ { pid = substr($0, 2) }
        /^n/ {
            cwd = substr($0, 2)
            if (cwd == root || index(cwd, root "/") == 1) print pid
        }')
    test -n "$matched"; or return

    set -l ports
    for entry in $listeners
        set -l parts (string split ' ' -- $entry)
        if contains -- $parts[1] $matched
            set -a ports $parts[2]
        end
    end
    test -n "$ports"; or return

    printf '%s\n' $ports | sort -un
end

