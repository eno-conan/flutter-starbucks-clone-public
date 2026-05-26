# Repository Investigation Guidelines

## Overview

This Flutter repository uses:
- **Backend**: Supabase (RPC functions, no Next.js API routes)
- **State Management**: Riverpod 3.0 (Notifier API)
- **RPC Definitions**: `lib/constants/supabase_rpcs.dart`
- **Providers**: `lib/provider/*_provider.dart`
- **Services**: `lib/services/**/*.dart`
- **Screens**: `lib/screens/**/*.dart`

When investigating unfamiliar features or concerns, follow these structured steps to **minimize token usage** and **avoid redundant searches**.

---

## Core Principles

### 1. Prefer Structural Truth Over Textual Search

**Philosophy**: Always check architectural entry points before running broad text searches.

**DO**:
- ✅ First identify structural files:
  - **RPC Functions**: `lib/constants/supabase_rpcs.dart`
  - **Providers**: `lib/provider/*_provider.dart`
  - **Services**: `lib/services/**/*.dart`
  - **Screens**: `lib/screens/**/*.dart`

**DON'T**:
- ❌ Run `grep -r` across the entire repository before checking structural files
- ❌ Search for keywords (e.g., "delete", "payment") globally without first confirming relevant RPC/Provider existence

**Example**:
```
✅ Correct approach:
1. Check lib/constants/supabase_rpcs.dart for RPC definitions
2. If RPC exists, search for its usage in services
3. If no RPC, conclude the feature does not exist

❌ Inefficient approach:
1. grep -r "delete" lib/
2. find . -name "*delete*"
3. grep -r "remove" lib/
```

---

### 2. Avoid Redundant Scans

**Prohibition**: Do NOT search the same concern in:
- Both file contents AND file names
- Both specific files AND the entire repository
- Multiple times using different keywords

**Strategy**: If a concern is disproven at a higher level, **STOP further searching**.

**Example**:
```
✅ Efficient:
1. Check lib/constants/supabase_rpcs.dart
2. No DELETE-related RPC found
3. **Stop here** - deletion feature does not exist

❌ Wasteful:
1. Check lib/constants/supabase_rpcs.dart (no DELETE RPC)
2. grep -r "delete" lib/services/
3. grep -r "remove" lib/
4. find . -name "*delete*"
→ All searches after step 1 are redundant
```

---

### 3. Deletion / Destructive Logic Investigation

**Steps**:
1. **Check RPC definitions first**: `lib/constants/supabase_rpcs.dart`
   - If no DELETE-related RPC exists, **STOP here**
2. **Check Services** (only if RPC exists): `lib/services/**/*`
3. **Check Providers** (only if service-level deletion is confirmed): `lib/provider/*_provider.dart`

**DON'T**:
- ❌ Search for "delete", "remove", "destroy" keywords globally before RPC verification

**Example**:
```
User asks: "Does this app have a deletion feature?"

✅ Correct approach:
1. Read lib/constants/supabase_rpcs.dart
2. Search for "delete", "remove", "destroy" in RPC constant names
3. If absent → Report: "No deletion feature found in RPC definitions"
4. **End investigation**

❌ Incorrect approach:
1. grep -r "delete" lib/
2. grep -r "remove" lib/services/
3. find . -name "*delete*"
4. grep -r "DELETE" lib/
→ Wastes tokens before checking the authoritative source
```

---

### 4. API / Data Flow Investigation

**For Supabase RPC functions**:
1. **Start here**: `lib/constants/supabase_rpcs.dart` (RPC definitions)
2. **Next**: `lib/services/**/*` (find RPC callers)
3. **Finally**: `lib/provider/*_provider.dart` (state management layer)

**For UI State**:
1. **Start here**: `lib/provider/*_provider.dart` (state definitions)
2. **Next**: `lib/screens/**/*.dart` (UI usage)

**DON'T**:
- ❌ Start from screens and trace backward (inefficient, bottom-up)
- ❌ Use `grep -r "rpc_function_name"` without first confirming the RPC exists

**Recommended Flow**:
```
Top-down investigation (Backend → Frontend):
RPC Definition → Service Layer → Provider Layer → UI Layer

✅ Example:
1. Find RPC in lib/constants/supabase_rpcs.dart
2. Search for RPC usage in lib/services/
3. Find which Provider calls the service
4. Find which Screen consumes the Provider
```

---

### 5. Feature Existence Verification

**Before investigating a feature**, verify its existence:

1. **Check if the feature has a dedicated Provider**:
   - `lib/provider/<feature>_provider.dart`
2. **Check if the feature has a dedicated Service**:
   - `lib/services/<feature>/**/*.dart`
3. **Check if the feature has RPC support**:
   - `lib/constants/supabase_rpcs.dart`

**Stop conditions**:
- If **none** of the above exist → **Feature does not exist**
- Do NOT run `grep -r "<feature_keyword>"` globally

**Example**:
```
User asks: "How does the payment feature work?"

✅ Correct approach:
1. Check lib/constants/supabase_rpcs.dart for payment-related RPCs
2. Check lib/provider/ for *payment* providers
3. Check lib/services/ for payment services
4. If all absent → Report: "Payment feature not implemented"

❌ Incorrect approach:
1. grep -r "payment" lib/
2. grep -r "pay" lib/
3. grep -r "transaction" lib/
→ Broad searches without structural verification
```

---

### 6. Minimize Token and IO Usage

**Prefer**:
- ✅ Scoped searches in known directories:
  - `lib/constants/supabase_rpcs.dart`
  - `lib/provider/`
  - `lib/services/`
  - `lib/screens/`

**Avoid**:
- ❌ `grep -r` at repository root
- ❌ `find . -name` without directory constraints
- ❌ Recursive searches when the feature location is known

**Token-saving strategies**:
- Read specific files instead of grepping
- Use LSP (Language Server Protocol) for code navigation (see `.claude/rules/lsp-guidelines.md`)
- Limit grep scope to specific directories

---

### 7. Explain Intent Before Execution

**Before running investigation commands**, briefly state:
1. What is being verified
2. What condition will stop further searching
3. Why this approach is the most efficient

**Example**:
> "Verifying if DELETE RPC exists by checking `lib/constants/supabase_rpcs.dart`. If absent, deletion feature investigation will stop immediately."

**Benefits**:
- Clarifies thought process
- Allows self-correction before wasting tokens
- Provides transparency to users

---

## Quick Reference: Investigation Order

### For API/Backend concerns:
```
1. lib/constants/supabase_rpcs.dart (RPC definitions)
   ↓
2. lib/services/**/*.dart (RPC callers)
   ↓
3. lib/provider/*_provider.dart (State management)
```

### For UI/State concerns:
```
1. lib/provider/*_provider.dart (State definitions)
   ↓
2. lib/screens/**/*.dart (UI usage)
```

### For deletion/destructive logic:
```
1. lib/constants/supabase_rpcs.dart → No DELETE RPC? → **STOP**
   ↓ (only if RPC exists)
2. lib/services/**/* → Service-level deletion? → Check Providers
   ↓ (only if service exists)
3. lib/provider/* → Provider-level deletion? → Check Screens
```

---

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Broad grep before structural check

**Bad**:
```bash
grep -r "delete" lib/
```

**Good**:
```bash
# 1. Check RPC first
cat lib/constants/supabase_rpcs.dart | grep -i delete
# 2. If not found, stop here
```

---

### ❌ Anti-Pattern 2: Redundant file name + content search

**Bad**:
```bash
find . -name "*delete*"  # Already checked RPC
grep -r "delete" lib/    # Redundant
```

**Good**:
```bash
cat lib/constants/supabase_rpcs.dart  # RPC is the source of truth
# If not found, stop
```

---

### ❌ Anti-Pattern 3: Bottom-up investigation (UI → Backend)

**Bad**:
```bash
grep -r "Navigator.push" lib/screens/
# Then trace backward to services
```

**Good**:
```bash
# 1. Check RPC
# 2. Check Service
# 3. Check Provider
# 4. Check Screen
# Top-down flow is more efficient
```

---

### ❌ Anti-Pattern 4: Ignoring LSP capabilities

**Bad**:
```bash
grep -r "authStateProvider" lib/
grep -r "class.*Auth.*Provider" lib/
```

**Good**:
```
Use LSP "Go to Definition" or "Find References"
(See .claude/rules/lsp-guidelines.md for details)
```

---

## LSP Utilization (Brief Reference)

For efficient code navigation, prefer **LSP (Language Server Protocol)** over text-based searches:

- **Go to Definition**: Jump to RPC/Provider/Service definitions
- **Find References**: Locate all usage of a function/Provider
- **Type Hierarchy**: Understand class inheritance

**When to use LSP**:
- ✅ Finding where a Provider is used
- ✅ Finding where an RPC is called
- ✅ Tracing method definitions

**When to use grep**:
- ✅ Searching string literals (error messages, etc.)
- ✅ Searching comments
- ✅ Initial broad keyword discovery

**Detailed LSP guidelines**: See `.claude/rules/lsp-guidelines.md`

---

## Self-Correction Directive

When Claude Code detects that it is about to violate this guideline:

### 1. Stop the inefficient action

### 2. Explain the violation
Example: "I was about to run `grep -r "delete"`, but according to Repository Investigation Guidelines, I should first check `lib/constants/supabase_rpcs.dart`."

### 3. Execute the correct action
Follow the guideline-compliant approach.

### 4. Report the correction
Example: "Following the guideline, I checked the RPC definitions first and found no DELETE-related functions. Investigation complete."

---

### Example of Self-Correction in Action

**Original plan**: `grep -r "delete" lib/`

**Self-corrected approach**:
> "I was about to search for 'delete' globally, but Repository Investigation Guidelines specify checking structural files first. Let me check `lib/constants/supabase_rpcs.dart` for DELETE-related RPC definitions."
>
> → Checked `supabase_rpcs.dart`
> → No DELETE RPC found
> → **Investigation complete** (no deletion feature exists)

**Benefits**:
- Token usage reduced by ~80%
- No redundant searches
- Clear explanation of reasoning

---

## Summary

**Key Takeaways**:
- **Structure > Text**: Always check architectural files first
- **Stop early**: If disproven at a higher level, don't search deeper
- **Scoped searches**: Avoid repository-wide `grep` and `find`
- **Explain intent**: State what you're verifying and when you'll stop
- **Top-down flow**: Backend (RPC) → Service → Provider → Screen
- **Use LSP**: Prefer Language Server Protocol over grep for code navigation

**Expected impact**:
- ✅ 50%+ reduction in command execution
- ✅ 80-90% reduction in token usage
- ✅ Elimination of "grep → re-grep" redundancy
- ✅ Self-correction messages during investigation

---

**This guideline applies to**: All investigation phases (Plan Mode, normal questions, bug investigations, feature explorations)

**Related guidelines**: `.claude/rules/lsp-guidelines.md` (LSP/Dart Analyzer usage)
