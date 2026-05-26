#!/bin/bash
# Post-tool-use lint checks for Dart files

file=$(cat | jq -r ".tool_input.file_path // empty" 2>/dev/null || true)

if [[ -z "$file" || ! "$file" =~ \.dart$ ]]; then
  exit 0
fi

dart format "$file" 2>/dev/null || true
dart fix --apply --code=always_use_package_imports "$file" 2>/dev/null || true
dart fix --apply --code=directives_ordering "$file" 2>/dev/null || true
dart fix --apply --code=sort_constructors_first "$file" 2>/dev/null || true
dart fix --apply --code=prefer_null_aware_operators "$file" 2>/dev/null || true

dart analyze "$file" 2>/dev/null || true
