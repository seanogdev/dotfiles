#!/opt/homebrew/bin/fish

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

set -l separator (printf " %b•%b " $dim $reset)
set -l optimal_limit 200000

function usage_color -a pct
    if test $pct -lt 50
        printf '%s' $green
    else if test $pct -lt 80
        printf '%s' $amber
    else
        printf '%s' $red
    end
end

function format_count -a value scale
    if test $value -ge 1000000
        printf '%sM' (math --scale=$scale "$value / 1000000")
    else
        printf '%sk' (math --scale=$scale "$value / 1000")
    end
end

function rate_limit_segment -a label pct reset_at time_fmt
    test -z "$pct"; and return

    set -l rounded (printf "%.0f" "$pct")
    set -l color (usage_color $rounded)

    if test -n "$reset_at"
        set -l reset_time (date -r "$reset_at" "$time_fmt" 2>/dev/null; or echo $reset_at)
        printf '%b%s %b%s%%%b %b%s%b' $dim $label $color $rounded $reset $dim $reset_time $reset
    else
        printf '%b%s %b%s%%%b' $dim $label $color $rounded $reset
    end
end

# Read JSON input from stdin and extract every field in one pass
set -l input (cat | string collect)
set -l fields (printf '%s' $input | jq -r '
    def window($key; $name):
        (.rate_limits // null) as $limits
        | if ($limits | type) == "object" then ($limits[$key] // {})
          elif ($limits | type) == "array" then (($limits | map(select(.window == $name)) | first) // {})
          else {} end;
    def text($value): ($value // "") | tostring;
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

set -l model (string replace " (1M context)" " 1M" -- $fields[1])
set -l cwd $fields[2]
set -l tokens_used $fields[3]
set -l context_size $fields[4]
set -l effort $fields[5]

# Segment 1: directory name and git branch
set -l dir_name (basename "$cwd")
set -l git_branch
test -n "$cwd"; and set git_branch (git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
set -l segment1 (printf '%b%s%b' $cyan $dir_name $reset)
if test -n "$git_branch"
    set segment1 "$segment1"(printf ' %b󰘬 %s%b' $magenta $git_branch $reset)
end

# Segment 2: model name, color coded by model family
set -l model_color $orange
if string match -qi "*haiku*" "$model"
    set model_color $periwinkle
else if string match -qi "*sonnet*" "$model"
    set model_color $blue
else if string match -qi "*opus*" "$model"
    set model_color $rose
end
set -l segment2 (printf '%b✻%b %b%s%b' $orange $reset $model_color $model $reset)

# Segment 3: reasoning effort level (absent when model lacks effort support)
set -l segment3 ""
if test -n "$effort"
    set -l effort_color
    switch $effort
        case low
            set effort_color $periwinkle
        case medium
            set effort_color $blue
        case high
            set effort_color $gold
        case '*'
            set effort_color $rose
    end
    set segment3 (printf '%b󰓅 %s%b' $effort_color $effort $reset)
end

# Segment 4: token count, colored by usage relative to the 200K optimal limit
set -l used_pct (math --scale=2 "($tokens_used / $optimal_limit) * 100")
set -l segment4 (printf '%b󰆼 %s/%s [%s%%]%b' \
    (usage_color $used_pct) \
    (format_count $tokens_used 1) \
    (format_count $context_size 0) \
    (math --scale=0 "$used_pct") \
    $reset)

# Segment 5: rate limits (5-hour and 7-day windows)
set -l rate_limits
set -a rate_limits (rate_limit_segment 5h "$fields[6]" "$fields[7]" "+%H:%M")
set -a rate_limits (rate_limit_segment 7d "$fields[8]" "$fields[9]" "+%d/%m")

# Build the complete status line
set -l line1 $segment1 $segment2
test -n "$segment3"; and set -a line1 $segment3
set -l line2 $segment4 $rate_limits

set line1 (string join "$separator" $line1)
set line2 (string join "$separator" $line2)
set -l single "$line1$separator$line2"

# Measure visible width (strip ANSI), add 1 per double-width nerd-font glyph
set -l stripped (string replace -ra '\e\[[0-9;]*m' '' -- "$single")
set -l wide_glyphs (string match -ar '[󰘬✻󰆼󰓅]' -- "$stripped" | count)
set -l vis_len (math (string length -- "$stripped") + $wide_glyphs)

# Terminal width. Claude Code does not pass width in the JSON, and the
# statusline subprocess usually has no controlling tty (so `stty </dev/tty`
# fails). Try several sources in order, and when width is genuinely unknown
# prefer wrapping to two lines over a single line the terminal would clip —
# never drop the trailing (rate-limit) segments.
set -l cols $COLUMNS
test -z "$cols"; and set cols (stty size </dev/tty 2>/dev/null | awk '{print $2}')
test -z "$cols"; and set cols (tput cols 2>/dev/null)
# Unknown width -> 0 forces the wrap branch so everything stays visible.
string match -qr '^[0-9]+$' -- "$cols"; or set cols 0

if test $vis_len -gt $cols
    printf '%s\n%s' "$line1" "$line2"
else
    printf '%s' "$single"
end
