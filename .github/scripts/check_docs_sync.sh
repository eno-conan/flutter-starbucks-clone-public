#!/bin/bash

# Implementation/Documentation Sync Validator for GitHub Actions
# Ensures that changes to implementation code in lib/screens/ 
# are accompanied by corresponding documentation updates in docs/screens/

set -euo pipefail

# セキュリティ設定
umask 077
export PATH="/usr/local/bin:/usr/bin:/bin"

echo "🔍 Checking Implementation/Documentation Sync..."

# 入力検証関数
validate_git_ref() {
    local ref="$1"
    local name="$2"
    
    if [[ -z "$ref" ]]; then
        return 0  # 空の場合は検証をスキップ
    fi
    
    # Git参照の形式チェック（英数字、ハイフン、アンダースコア、スラッシュのみ）
    if [[ ! "$ref" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
        echo "❌ Invalid $name format: $ref"
        exit 1
    fi
    
    # 長さ制限（通常のGitハッシュは40文字、ブランチ名は255文字以下）
    if [[ ${#ref} -gt 255 ]]; then
        echo "❌ $name too long: $ref"
        exit 1
    fi
}

# パス検証関数
validate_file_path() {
    local path="$1"
    
    # パストラバーサルの検出
    if [[ "$path" == *".."* ]] || [[ "$path" == "/"* ]]; then
        echo "❌ Suspicious path detected: $path"
        return 1
    fi
    
    # 制御文字の検出
    if [[ "$path" =~ [[:cntrl:]] ]]; then
        echo "❌ Control characters in path: $path"
        return 1
    fi
    
    return 0
}

# 安全な出力関数
safe_echo() {
    local text="$1"
    # 制御文字を除去してから出力
    echo "$text" | tr -d '\000-\037\177'
}

# 環境変数の検証
validate_environment() {
    # GitHub Actions環境でのみ実行
    if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
        echo "❌ This script should only run in GitHub Actions"
        exit 1
    fi
    
    # 必須環境変数の確認
    if [[ -z "${GITHUB_WORKSPACE:-}" ]] || [[ -z "${GITHUB_EVENT_NAME:-}" ]]; then
        echo "❌ Required GitHub environment variables are missing"
        exit 1
    fi
    
    # 環境変数の検証
    validate_git_ref "${GITHUB_BASE_REF:-}" "GITHUB_BASE_REF"
    validate_git_ref "${GITHUB_HEAD_REF:-}" "GITHUB_HEAD_REF"
    validate_git_ref "${GITHUB_SHA:-}" "GITHUB_SHA"
    validate_git_ref "${GITHUB_EVENT_BEFORE:-}" "GITHUB_EVENT_BEFORE"
}

# 安全なgit操作
safe_git_diff() {
    local from="$1"
    local to="$2"
    
    # 引数の検証
    validate_git_ref "$from" "from_ref"
    validate_git_ref "$to" "to_ref"
    
    # git diffを安全に実行
    if ! git diff --name-only "$from" "$to" 2>/dev/null; then
        echo "❌ Git diff failed for $from..$to"
        return 1
    fi
}

# Function to get changed files in PR/push
get_changed_files() {
    case "${GITHUB_EVENT_NAME:-}" in
        "pull_request")
            echo "📋 Detected Pull Request event"
            # For pull requests, use the provided base and head references
            if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
                safe_echo "🔍 Comparing against base branch: $GITHUB_BASE_REF"
                # Ensure we have the latest base branch
                git fetch origin "$GITHUB_BASE_REF:$GITHUB_BASE_REF" 2>/dev/null || \
                git fetch origin "$GITHUB_BASE_REF" 2>/dev/null || true
                
                # Use three-dot notation to get changes in the feature branch
                safe_git_diff "$GITHUB_BASE_REF" "HEAD" || \
                git diff --name-only "$GITHUB_BASE_REF"...HEAD
            else
                echo "⚠️  GITHUB_BASE_REF not available, falling back to origin/main"
                git fetch origin main 2>/dev/null || true
                git diff --name-only origin/main...HEAD
            fi
            ;;
        "push")
            echo "📋 Detected Push event"
            # For push events, compare the range of commits in the push
            if [[ -n "${GITHUB_EVENT_BEFORE:-}" ]] && [[ "$GITHUB_EVENT_BEFORE" != "0000000000000000000000000000000000000000" ]]; then
                safe_echo "🔍 Comparing push range: $GITHUB_EVENT_BEFORE..$GITHUB_SHA"
                safe_git_diff "$GITHUB_EVENT_BEFORE" "$GITHUB_SHA"
            elif git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
                echo "🔍 Comparing with previous commit"
                git diff --name-only HEAD~1 HEAD
            else
                echo "🔍 Initial commit detected, listing all files"
                git ls-files
            fi
            ;;
        *)
            echo "📋 Unknown event type: ${GITHUB_EVENT_NAME:-}"
            echo "🔍 Falling back to HEAD~1 comparison"
            if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
                git diff --name-only HEAD~1 HEAD
            else
                git ls-files
            fi
            ;;
    esac
}

# メイン処理開始
validate_environment

# Debug information
echo "🔧 Debug Information:"
safe_echo "  Event: ${GITHUB_EVENT_NAME:-}"
safe_echo "  Base Ref: ${GITHUB_BASE_REF:-}"
safe_echo "  Head Ref: ${GITHUB_HEAD_REF:-}"
safe_echo "  SHA: ${GITHUB_SHA:-}"
safe_echo "  Before: ${GITHUB_EVENT_BEFORE:-}"
echo ""

# Get all changed files
changed_files=$(get_changed_files)

if [[ -z "$changed_files" ]]; then
    echo "✅ No files changed, skipping sync check"
    exit 0
fi

echo "📁 Changed files detected:"
while IFS= read -r file; do
    # ファイルパスの検証
    if validate_file_path "$file"; then
        safe_echo "  $file"
    else
        echo "⚠️  Skipping suspicious file: $file"
    fi
done <<< "$changed_files"
echo ""

# Extract directories that have changes in lib/screens/
implementation_dirs=()
docs_dirs=()

# Process each changed file
while IFS= read -r file; do
    # Skip empty lines
    [[ -z "$file" ]] && continue
    
    # ファイルパスの検証
    if ! validate_file_path "$file"; then
        continue
    fi
    
    # Check if it's a file in lib/screens/
    if [[ "$file" == lib/screens/* ]]; then
        # Extract the directory path after lib/screens/
        # Example: lib/screens/starbucks_user_side/signin/login.dart 
        #          -> starbucks_user_side/signin
        dir_path=$(dirname "$file" | sed 's|^lib/screens/||')
        
        # Skip if it's directly in lib/screens/ (no subdirectory)
        if [[ "$dir_path" != "." ]] && [[ "$dir_path" != "" ]]; then
            # パスの再検証
            if validate_file_path "$dir_path"; then
                implementation_dirs+=("$dir_path")
                safe_echo "🔧 Found implementation change: lib/screens/$dir_path"
            fi
        fi
    fi
    
    # Check if it's a file in docs/screens/
    if [[ "$file" == docs/screens/* ]]; then
        # Extract the directory path after docs/screens/
        dir_path=$(dirname "$file" | sed 's|^docs/screens/||')
        
        # Skip if it's directly in docs/screens/ (no subdirectory)
        if [[ "$dir_path" != "." ]] && [[ "$dir_path" != "" ]]; then
            # パスの再検証
            if validate_file_path "$dir_path"; then
                docs_dirs+=("$dir_path")
                safe_echo "📚 Found documentation change: docs/screens/$dir_path"
            fi
        fi
    fi
done <<< "$changed_files"

# Remove duplicates and sort using mapfile
if [[ ${#implementation_dirs[@]} -gt 0 ]]; then
    mapfile -t implementation_dirs < <(printf '%s\n' "${implementation_dirs[@]}" | sort -u)
fi

if [[ ${#docs_dirs[@]} -gt 0 ]]; then
    mapfile -t docs_dirs < <(printf '%s\n' "${docs_dirs[@]}" | sort -u)
fi

echo ""
echo "📊 Summary:"
echo "🔧 Implementation directories with changes:"
if [[ ${#implementation_dirs[@]} -eq 0 ]]; then
    echo "  (none)"
else
    for dir in "${implementation_dirs[@]}"; do
        safe_echo "  - lib/screens/$dir"
    done
fi

echo ""
echo "📚 Documentation directories with changes:"
if [[ ${#docs_dirs[@]} -eq 0 ]]; then
    echo "  (none)"
else
    for dir in "${docs_dirs[@]}"; do
        safe_echo "  - docs/screens/$dir"
    done
fi

# Check sync
missing_docs=()
for impl_dir in "${implementation_dirs[@]}"; do
    # Check if corresponding docs directory has changes
    found=false
    for doc_dir in "${docs_dirs[@]}"; do
        if [[ "$impl_dir" = "$doc_dir" ]]; then
            found=true
            break
        fi
    done
    
    if [[ "$found" = false ]]; then
        missing_docs+=("$impl_dir")
    fi
done

# Report results
echo ""
echo "🎯 Validation Results:"
if [[ ${#missing_docs[@]} -eq 0 ]]; then
    echo "✅ Implementation/Documentation sync check PASSED!"
    if [[ ${#implementation_dirs[@]} -eq 0 ]]; then
        echo "   No implementation changes detected in lib/screens/."
    else
        echo "   All implementation changes have corresponding documentation updates."
    fi
else
    echo "❌ Implementation/Documentation sync check FAILED!"
    echo ""
    echo "📋 The following implementation directories have changes but no corresponding documentation updates:"
    for dir in "${missing_docs[@]}"; do
        safe_echo "  ⚠️  Implementation: lib/screens/$dir"
        safe_echo "      Missing docs:    docs/screens/$dir"
        echo ""
    done
    
    echo "📝 Action Required:"
    echo "Please update the documentation in the corresponding docs/screens/ directories"
    echo "to match your implementation changes, or create the documentation if it doesn't exist."
    echo ""
    echo "This ensures that implementation and documentation stay synchronized."
    
    exit 1
fi

echo ""
echo "🎯 Sync validation completed successfully!"
