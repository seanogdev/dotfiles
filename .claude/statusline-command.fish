#!/opt/homebrew/bin/fish

# Read JSON input from stdin
set input (cat)

# Extract values from JSON
set model (echo $input | jq -r ".model.display_name" | string replace " (1M context)" " 1M")
set cwd (echo $input | jq -r ".workspace.current_dir")
set tokens_used (echo $input | jq -r '((.context_window.current_usage.input_tokens // 0) + (.context_window.current_usage.cache_creation_input_tokens // 0) + (.context_window.current_usage.cache_read_input_tokens // 0))')
set context_size (echo $input | jq -r '.context_window.context_window_size // 200000')
set optimal_limit 200000
set used_pct_of_optimal (echo "$tokens_used $optimal_limit" | awk '{printf "%.2f", ($1 / $2) * 100}')
set used_pct_of_total (echo "$tokens_used $context_size" | awk '{printf "%.2f", ($1 / $2) * 100}')

# Get directory name
set dir_name (basename "$cwd")

# Get git branch info
set git_branch (git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
set git_info ""
if test -n "$git_branch"
    set git_info " "(printf "\033[1;35m󰘬 %s\033[0m" "$git_branch")
end

# Segment 1: directory name and git branch
set segment1 (printf "\033[1;36m%s\033[0m%s" "$dir_name" "$git_info")

# Segment 2: model name, color coded by model family
if string match -qi "*haiku*" "$model"
    set model_color "\033[38;5;111m"  # Serene periwinkle blue
else if string match -qi "*sonnet*" "$model"
    set model_color "\033[38;5;75m"   # Blue
else if string match -qi "*opus*" "$model"
    set model_color "\033[38;5;167m"  # Red
else
    set model_color "\033[38;5;208m"  # Fallback orange
end
set segment2 (printf "\033[38;5;208m✻\033[0m %b%s\033[0m" "$model_color" "$model")

# Segment 3 & 4: token count and progress bar
# Color based on usage relative to the 200K optimal limit
if test (echo "$used_pct_of_optimal < 50" | bc -l) -eq 1
    set token_color "\033[1;32m"  # Green
else if test (echo "$used_pct_of_optimal < 80" | bc -l) -eq 1
    set token_color "\033[1;33m"  # Amber
else
    set token_color "\033[1;31m"  # Red
end

set pct_display (math --scale=0 "$used_pct_of_optimal")

# Format token counts: show as M if >= 1000K, otherwise K
if test $tokens_used -ge 1000000
    set tokens_fmt (math --scale=1 "$tokens_used / 1000000")"M"
else
    set tokens_fmt (math --scale=1 "$tokens_used / 1000")"k"
end
set optimal_fmt (math --scale=0 "$optimal_limit / 1000")"k"
if test $context_size -ge 1000000
    set size_fmt (math --scale=0 "$context_size / 1000000")"M"
else
    set size_fmt (math --scale=0 "$context_size / 1000")"k"
end

set segment3 (printf "%b󰆼 %s/%s [%s%%]\033[0m" "$token_color" "$tokens_fmt" "$size_fmt" "$pct_display")

# Yellow color for pipe separators
set pipe_separator (printf " \033[38;5;242m•\033[0m ")

# Segment 5: rate limits (5-hour and 7-day windows)
#   Each entry: label, jq object key, jq array key, date format
set rl_windows "5h,five_hour,5h,%H:%M" "7d,seven_day,7d,%d/%m"
set rate_limit_segments

for window in $rl_windows
    set parts (string split "," $window)
    set label $parts[1]
    set obj_key $parts[2]
    set arr_key $parts[3]
    set time_fmt $parts[4]

    # Try new object format, fall back to old array format
    set pct (echo $input | jq -r ".rate_limits.$obj_key.used_percentage // empty" 2>/dev/null)
    if test -z "$pct"
        set pct (echo $input | jq -r ".rate_limits[] | select(.window == \"$arr_key\") | .used_percentage // empty" 2>/dev/null)
    end
    test -z "$pct"; and continue

    set reset_at (echo $input | jq -r ".rate_limits.$obj_key.resets_at // empty" 2>/dev/null)
    if test -z "$reset_at"
        set reset_at (echo $input | jq -r ".rate_limits[] | select(.window == \"$arr_key\") | .resets_at // empty" 2>/dev/null)
    end

    # Round percentage to integer
    set pct (printf "%.0f" "$pct")

    # Color based on usage percentage
    if test (echo "$pct < 50" | bc -l) -eq 1
        set rl_color "\033[1;32m"
    else if test (echo "$pct < 80" | bc -l) -eq 1
        set rl_color "\033[1;33m"
    else
        set rl_color "\033[1;31m"
    end

    # Dim label, colored percentage, dim reset time
    set dim "\033[38;5;242m"
    if test -n "$reset_at"
        set reset_time (date -r "$reset_at" "+$time_fmt" 2>/dev/null; or echo $reset_at)
        set -a rate_limit_segments (printf "%b%s %b%s%%\033[0m %b%s\033[0m" "$dim" "$label" "$rl_color" "$pct" "$dim" "$reset_time")
    else
        set -a rate_limit_segments (printf "%b%s %b%s%%\033[0m" "$dim" "$label" "$rl_color" "$pct")
    end
end

set rate_limit_info (string join "$pipe_separator" $rate_limit_segments)

# Build the complete status line with pipe separators
set line1 "$segment1$pipe_separator$segment2"
set line2 "$segment3"
if test -n "$rate_limit_info"
    set line2 "$line2$pipe_separator$rate_limit_info"
end
set single "$line1$pipe_separator$line2"

# Measure visible width (strip ANSI), add 1 per double-width nerd-font glyph
set stripped (string replace -ra '\e\[[0-9;]*m' '' -- "$single")
set vis_len (string length -- "$stripped")
set wide_glyphs (string match -ar '[󰘬✻󰆼]' -- "$stripped" | count)
set vis_len (math "$vis_len + $wide_glyphs")

# Terminal width (fall back to 120 if not on a tty)
set cols (stty size </dev/tty 2>/dev/null | awk '{print $2}')
test -z "$cols"; and set cols 120

if test $vis_len -gt $cols
    printf "%s\n%s" "$line1" "$line2"
else
    printf "%s" "$single"
end
