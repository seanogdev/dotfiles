#!/opt/homebrew/bin/fish

# Read JSON input from stdin
set input (cat)

# Extract values from JSON
set model (echo $input | jq -r ".model.display_name")
set cwd (echo $input | jq -r ".workspace.current_dir")
set tokens_used (echo $input | jq -r '((.context_window.current_usage.input_tokens // 0) + (.context_window.current_usage.cache_creation_input_tokens // 0) + (.context_window.current_usage.cache_read_input_tokens // 0))')
set context_size (echo $input | jq -r '.context_window.context_window_size // 200000')
set used_pct (echo $input | jq -r '.context_window.used_percentage // 0')

# Get today's cost from ccusage
set today_iso (date +%Y-%m-%d)
set ccusage_output (npx ccusage@latest daily --json 2>/dev/null)
set cost (echo $ccusage_output | jq -r --arg date "$today_iso" '(.daily[] | select(.date == $date) | .totalCost) // 0')

if test -z "$cost"; or test "$cost" = "null"
    set cost 0
end

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

# Segment 3: cost in RAG colors
# Determine cost color based on thresholds:
# Green: $0.00 - $4.99
# Amber: $5.00 - $39.99
# Red: $40.00+
set cost_color ""
if test "$cost" = "N/A"
    set cost_color "\033[1;31m"  # Red for N/A (error state)
    set cost_display "N/A"
else
    set cost_display (printf "%.2f" $cost)
    if test (echo "$cost < 15.00" | bc -l) -eq 1
        set cost_color "\033[1;32m"  # Green
    else if test (echo "$cost < 50.00" | bc -l) -eq 1
        set cost_color "\033[1;33m"  # Amber/Yellow
    else
        set cost_color "\033[1;31m"  # Red
    end
end

set segment3 (printf "%b\$%s\033[0m" "$cost_color" "$cost_display")

# Segment 4 & 5: token count and progress bar
# Determine color based on usage percentage
if test (echo "$used_pct < 50" | bc -l) -eq 1
    set token_color "\033[1;32m"  # Green
else if test (echo "$used_pct < 80" | bc -l) -eq 1
    set token_color "\033[1;33m"  # Amber
else
    set token_color "\033[1;31m"  # Red
end

set tokens_k (math --scale=1 "$tokens_used / 1000")
set size_k (math --scale=0 "$context_size / 1000")
set pct_display (math --scale=0 "$used_pct")
set segment4 (printf "%b%sk/%sk [%s%%]\033[0m" "$token_color" "$tokens_k" "$size_k" "$pct_display")

# Dynamic bar width: fill remaining terminal width minus a 4-char safety buffer
set term_width (stty size </dev/tty 2>/dev/null | string split ' ')[2]
if test -z "$term_width"
    set term_width (tput cols 2>/dev/null)
end
if test -z "$term_width"
    set term_width 80
end
set w_dir (string length -- "$dir_name")
set w_git 0
if test -n "$git_branch"
    set w_git (math "4 + "(string length -- "$git_branch"))  # space + 2-col icon + space + branch
end
set w_model (string length -- "$model")
set w_cost (math "1 + "(string length -- "$cost_display"))  # $ + digits
set w_tokens (string length -- (printf "%sk/%sk [%s%%]" "$tokens_k" "$size_k" "$pct_display"))
set w_separators 8  # 2 separators × " • " (3 chars) + 2 spaces flanking the bar
set w_other (math "$w_dir + $w_git + $w_model + $w_cost + $w_tokens + $w_separators")
set bar_width (math "max(5, $term_width - $w_other - 7)")
set filled (math --scale=0 "$bar_width * $used_pct / 100")
if test $filled -gt $bar_width
    set filled $bar_width
end
set empty (math "$bar_width - $filled")
set filled_str (string repeat -n $filled "█")
set empty_str (string repeat -n $empty "░")
set segment5 (printf "%b%s%s\033[0m" "$token_color" "$filled_str" "$empty_str")

# Yellow color for pipe separators
set pipe_separator (printf " \033[38;5;242m•\033[0m ")

# Build the complete status line with pipe separators
set output "$segment1$pipe_separator$segment2$pipe_separator$segment3 $segment5 $segment4"

# Print the status line
printf "%s" "$output"
