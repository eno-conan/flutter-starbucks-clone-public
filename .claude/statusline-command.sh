#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON using pure bash
extract_json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

# Extract numeric values
extract_json_number() {
    local json="$1"
    local key="$2"
    echo "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p" | head -1
}

# Format token count (1000+ = K, 1000000+ = M)
format_token_count() {
    local tokens="$1"
    if [[ "$tokens" -ge 1000000 ]]; then
        local value=$((tokens / 1000000))
        echo "${value}M"
    elif [[ "$tokens" -ge 1000 ]]; then
        local value=$((tokens / 1000))
        echo "${value}K"
    else
        echo "$tokens"
    fi
}

# Extract nested values
current_dir=$(echo "$input" | sed -n 's/.*"workspace"[[:space:]]*:[[:space:]]*{[^}]*"current_dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
model_name=$(echo "$input" | sed -n 's/.*"model"[[:space:]]*:[[:space:]]*{[^}]*"display_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
session_id=$(extract_json_value "$input" "session_id")

# Extract context window information
context_window_size=$(extract_json_number "$input" "context_window_size")
input_tokens=$(extract_json_number "$input" "input_tokens")
cache_creation_tokens=$(extract_json_number "$input" "cache_creation_input_tokens")
cache_read_tokens=$(extract_json_number "$input" "cache_read_input_tokens")

# Calculate current token usage
current_tokens=$((${input_tokens:-0} + ${cache_creation_tokens:-0} + ${cache_read_tokens:-0}))

# Get username and hostname
username=$(whoami)
hostname=$(hostname -s)

# Get current directory (abbreviated like ~)
if [[ "$current_dir" == "$HOME"* ]]; then
    display_dir="~${current_dir#$HOME}"
else
    display_dir="$current_dir"
fi

# Git information with enhanced status
git_info=""
if git -C "$current_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        status_info=""
        
        # Check remote sync status (ahead/behind)
        upstream=$(git -C "$current_dir" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
        if [[ -n "$upstream" ]]; then
            ahead_behind=$(git -C "$current_dir" rev-list --left-right --count HEAD..."$upstream" 2>/dev/null)
            if [[ -n "$ahead_behind" ]]; then
                ahead=$(echo "$ahead_behind" | cut -f1)
                behind=$(echo "$ahead_behind" | cut -f2)
                
                if [[ "$ahead" -gt 0 ]]; then
                    status_info="${status_info} ↑${ahead}"
                fi
                if [[ "$behind" -gt 0 ]]; then
                    status_info="${status_info} ↓${behind}"
                fi
            fi
        fi
        
        # Get local changes status
        git_status=$(git -C "$current_dir" status --porcelain 2>/dev/null)
        if [[ -n "$git_status" ]]; then
            staged=$(echo "$git_status" | grep -c "^[MADRC]" 2>/dev/null || echo 0)
            unstaged=$(echo "$git_status" | grep -c "^.[MD]" 2>/dev/null || echo 0)
            untracked=$(echo "$git_status" | grep -c "^??" 2>/dev/null || echo 0)
            
            if [[ "$staged" -gt 0 ]]; then
                status_info="${status_info} +${staged}"
            fi
            if [[ "$unstaged" -gt 0 ]]; then
                status_info="${status_info} ~${unstaged}"
            fi
            if [[ "$untracked" -gt 0 ]]; then
                status_info="${status_info} ?${untracked}"
            fi
        fi
        
        if [[ -n "$status_info" ]]; then
            git_info=" [${branch}${status_info}]"
        else
            git_info=" [${branch}]"
        fi
    fi
fi

# Calculate context usage percentage and format display
context_info=""
if [[ -n "$context_window_size" ]] && [[ "$context_window_size" -gt 0 ]]; then
    # Auto-compact limit is 80% of context window
    auto_compact_limit=$((context_window_size * 80 / 100))

    # Calculate percentage (cap at 100%)
    percentage=$((current_tokens * 100 / auto_compact_limit))
    if [[ "$percentage" -gt 100 ]]; then
        percentage=100
    fi

    # Format token display
    token_display=$(format_token_count "$current_tokens")

    # Choose color based on percentage
    if [[ "$percentage" -ge 90 ]]; then
        context_info=" | Context: \033[31m${percentage}%\033[0m (${token_display})"
    elif [[ "$percentage" -ge 70 ]]; then
        context_info=" | Context: \033[33m${percentage}%\033[0m (${token_display})"
    else
        context_info=" | Context: \033[32m${percentage}%\033[0m (${token_display})"
    fi
fi

# Create enhanced status line with colors
# Order: model_name | context (percentage + tokens) | git_info | user@host:directory
# Using echo -e to properly interpret ANSI escape sequences
echo -e "\033[36m${model_name}\033[0m${context_info}${git_info} | \033[32m${username}@${hostname}\033[0m:\033[34m${display_dir}\033[0m"