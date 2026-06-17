#!/bin/bash
# Post-tool-use lint checks for Dart files

file=$(cat | jq -r ".tool_input.file_path // empty" 2>/dev/null || true)

if [[ -z "$file" || ! "$file" =~ \.dart$ ]]; then
  exit 0
fi

# Auto-fix: formatting and common lint issues (silent)
dart format "$file" 2>/dev/null || true
dart fix --apply --code=always_use_package_imports "$file" 2>/dev/null || true
dart fix --apply --code=directives_ordering "$file" 2>/dev/null || true
dart fix --apply --code=sort_constructors_first "$file" 2>/dev/null || true
dart fix --apply --code=prefer_null_aware_operators "$file" 2>/dev/null || true

# Static analysis: capture output and fail on errors
analyze_output=$(dart analyze "$file" 2>/dev/null)

if echo "$analyze_output" | grep -qE "(^  error |[0-9]+ error)"; then
  echo "❌ 静的解析エラー検出 ($file):"
  echo "$analyze_output"
  exit 1
fi

if echo "$analyze_output" | grep -qE "^  (warning|info) "; then
  echo "⚠️ 静的解析警告 ($file):"
  echo "$analyze_output"
fi

exit 0
