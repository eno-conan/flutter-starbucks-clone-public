# LSP (Language Server Protocol) Guidelines

## Overview

**LSP (Language Server Protocol)** provides powerful code intelligence features that significantly outperform text-based searches like `grep` and `find` for code navigation and analysis.

This guideline explains:
- What LSP is and how it works
- When to use LSP vs. grep
- Practical examples in this Flutter/Dart project
- Anti-patterns to avoid

---

## What is LSP?

LSP is a protocol that provides **semantic understanding** of code, enabling:

- **Go to Definition**: Jump directly to where a symbol (function, class, variable) is defined
- **Find References**: Locate all usages of a symbol across the codebase
- **Type Hierarchy**: View class inheritance and implementation relationships
- **Hover Information**: See type signatures and documentation instantly

**Key advantage**: LSP understands **code structure and types**, not just text patterns.

---

## Dart Analyzer: Flutter's LSP Implementation

In this Flutter project, **Dart Analyzer** provides LSP capabilities:

- Type-aware symbol resolution
- Import path resolution
- Riverpod Provider tracking
- Widget hierarchy navigation

**Why it matters**:
- Faster than grep (no need to scan all files)
- More accurate (understands scope and context)
- Type-safe (follows actual code relationships)

---

## When to Use LSP vs. grep

### ✅ LSP優先ケース (Prefer LSP)

Use LSP for:

1. **RPC Function Usage**
   - Finding where `Rpcs.checkSignupEmailExists` is called
   - Tracing RPC function flow from definition to usage

2. **Provider Usage**
   - Finding where `authStateProvider` is watched/read
   - Tracing state management flow

3. **Class/Method Definitions**
   - Finding where a Notifier class is defined
   - Understanding inheritance relationships

4. **Notifier State Updates**
   - Finding all places where `setTab()` is called
   - Tracing state mutation points

5. **Service Layer Navigation**
   - Finding which services call specific methods
   - Understanding service dependencies

### ✅ grep適用ケース (Use grep)

Use grep for:

1. **String Literals**
   - Error messages: `"ユーザーが認証されていません"`
   - Log messages: `LoggerService.info('...')`

2. **Comments**
   - TODOs: `// TODO: Fix this`
   - Documentation: `/// This function...`

3. **Broad Keyword Discovery**
   - Initial exploration: `grep -r "payment" lib/`
   - Exploratory research (when unsure what to look for)

4. **File Names**
   - Finding files by pattern: `find . -name "*_test.dart"`

---

## Core LSP Features

### 1. Go to Definition

**What it does**: Jump directly to the definition of a symbol.

**Use cases**:
- Find where a Provider is defined
- Find the implementation of an RPC function
- Locate a Service class definition

**Example workflow**:
```
1. Open a file where `authStateProvider` is used
2. Place cursor on `authStateProvider`
3. Use "Go to Definition" (F12 in VSCode)
→ Jumps to lib/provider/auth_state_provider.dart
```

**Why better than grep**:
- Instant (no file scanning)
- Context-aware (knows which `authStateProvider` you mean)
- Works across complex import paths

---

### 2. Find References

**What it does**: Locate all places where a symbol is used.

**Use cases**:
- Find all screens that use a specific Provider
- Find all services that call an RPC function
- Locate all places where a Notifier method is called

**Example workflow**:
```
1. Open lib/constants/supabase_rpcs.dart
2. Place cursor on `checkSignupEmailExists`
3. Use "Find References" (Shift+F12 in VSCode)
→ Lists all files/lines where this RPC is used
```

**Why better than grep**:
- Type-safe (only finds actual usages, not string matches)
- Scoped correctly (ignores comments, strings)
- Faster for large codebases

---

### 3. Type Hierarchy

**What it does**: Show inheritance and implementation relationships.

**Use cases**:
- See all Notifier classes in the project
- Understand which classes extend a base class
- Find all implementations of an interface

**Example workflow**:
```
1. Open a Notifier class definition
2. Use "Type Hierarchy" (Ctrl+T H in VSCode)
→ Shows Notifier → YourNotifier → (subclasses if any)
```

---

### 4. Hover Information

**What it does**: Display type signatures and documentation on hover.

**Use cases**:
- Quickly check a function's return type
- See parameter types without opening definition
- Read inline documentation

**Example**:
```
Hover over `ref.watch(authStateProvider)`
→ Shows: StreamProvider<User?>
→ Shows documentation if available
```

---

## Practical Examples

### Example 1: RPC Function Usage Investigation

**Scenario**: Find all places where `checkSignupEmailExists` RPC is called.

#### ❌ Before (grep approach)

```bash
grep -r "checkSignupEmailExists" lib/
grep -r "check_signup_email_exists" lib/
```

**Problems**:
- Searches both the constant definition AND usage
- May match string literals/comments
- Slower for large codebases

---

#### ✅ After (LSP approach)

**Steps**:
1. Open `lib/constants/supabase_rpcs.dart`
2. Place cursor on `checkSignupEmailExists`
3. Execute "Find References" (Shift+F12)

**Result**:
→ Instantly shows all actual usages (e.g., in services)
→ Click to jump to each usage

**Efficiency gain**: ~80% faster, 100% accurate

---

### Example 2: Provider Definition Lookup

**Scenario**: Find where `authStateProvider` is defined.

#### ❌ Before (grep approach)

```bash
grep -r "authStateProvider" lib/provider/
grep -r "class.*Auth.*Provider" lib/
```

**Problems**:
- Multiple grep commands needed
- Regex patterns are error-prone
- May match unrelated code

---

#### ✅ After (LSP approach)

**Steps**:
1. In any file where `authStateProvider` is used
2. Place cursor on `authStateProvider`
3. Execute "Go to Definition" (F12)

**Result**:
→ Jumps directly to `lib/provider/auth_state_provider.dart`

**Efficiency gain**: Instant vs. several seconds of grep

---

### Example 3: Notifier Method Call Sites

**Scenario**: Find all places where `setTab()` method is called.

#### ❌ Before (grep approach)

```bash
grep -r "selectedTabProvider.notifier" lib/
grep -r "setTab" lib/
grep -r "\.setTab(" lib/
```

**Problems**:
- First grep finds Provider references (not method calls)
- Second grep finds method definition too
- Third grep might miss some cases

---

#### ✅ After (LSP approach)

**Steps**:
1. Open `lib/provider/selected_tab_provider.dart`
2. Place cursor on `setTab` method definition
3. Execute "Find References" (Shift+F12)

**Result**:
→ Lists all call sites of `setTab()`
→ Excludes the definition itself
→ Type-safe (only actual method calls)

**Efficiency gain**: 100% accurate, no false positives

---

### Example 4: Service Method Callers

**Scenario**: Find which Providers call `AuthService.signIn()`.

#### ❌ Before (grep approach)

```bash
grep -r "signIn" lib/
grep -r "authService.signIn" lib/
```

**Problems**:
- Too many false positives (e.g., "signInButton", comments)
- Hard to filter results

---

#### ✅ After (LSP approach)

**Steps**:
1. Open `lib/services/auth_service.dart`
2. Place cursor on `signIn` method
3. Execute "Find References" (Shift+F12)

**Result**:
→ Shows only actual calls to `AuthService.signIn()`
→ Grouped by file
→ Easy to navigate

---

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Using grep for code symbol lookups

**Bad**:
```bash
# Searching for Provider definition
grep -r "class.*Provider" lib/provider/
```

**Why it's bad**:
- Slow (scans all files)
- Regex is fragile
- May miss multiline definitions

**Good**:
```
Use "Go to Definition" on the Provider usage
→ Instant, always correct
```

---

### ❌ Anti-Pattern 2: Using grep for method call sites

**Bad**:
```bash
# Finding where setTab is called
grep -r "\.setTab(" lib/
```

**Why it's bad**:
- May match string literals
- May miss some call patterns
- Includes definition in results

**Good**:
```
Use "Find References" on the method definition
→ Type-safe, accurate
```

---

### ❌ Anti-Pattern 3: Confusing string search with type search

**Bad**:
```bash
# Trying to find Provider usage
grep -r "authStateProvider" lib/
```

**Why it's bad**:
- Matches comments, strings, and definitions
- No context about actual usage
- Hard to filter results

**Good**:
```
Use "Find References" on the Provider definition
→ Only actual usages
→ Contextual information
```

---

### ❌ Anti-Pattern 4: Not using LSP when available

**Bad workflow**:
```
1. grep -r "someFunction" lib/
2. Open multiple files manually
3. Search within files
4. Trace relationships manually
```

**Good workflow**:
```
1. Use "Go to Definition" → Find function
2. Use "Find References" → See all usages
3. Click to jump between files
→ Faster, more accurate
```

---

## Integration with Repository Investigation Guidelines

**Relationship**:
- **Repository Investigation Guidelines**: Define **what** and **when** to investigate
- **LSP Guidelines**: Define **how** to investigate efficiently

**Combined workflow example**:

**Task**: Investigate how user authentication works

1. **Repository Investigation Guidelines** → Check structural files:
   - `lib/constants/supabase_rpcs.dart` (RPC definitions)
   - `lib/provider/auth_state_provider.dart` (state management)
   - `lib/services/auth_service.dart` (business logic)

2. **LSP Guidelines** → Navigate efficiently:
   - Use "Go to Definition" on RPC constants
   - Use "Find References" to trace RPC usage
   - Use "Type Hierarchy" to understand Provider structure

**Result**: Structural truth (what exists) + Efficient navigation (how to explore)

---

## Self-Correction Directive

Before executing a `grep` command for **code symbols** (functions, classes, variables):

### 1. Check if LSP can solve it

**Questions to ask**:
- Am I looking for a **definition**? → Use "Go to Definition"
- Am I looking for **usages**? → Use "Find References"
- Am I looking for **inheritance**? → Use "Type Hierarchy"

### 2. Explain the choice

**If using grep**:
> "I'm searching for string literal error messages, so grep is appropriate."

**If using LSP instead**:
> "I was about to grep for `authStateProvider`, but LSP 'Find References' will be more accurate. Let me use that instead."

### 3. Report the correction

**Example**:
> "Originally planned: `grep -r "authStateProvider" lib/`"
>
> "Self-corrected: Used LSP 'Find References' on `authStateProvider` definition"
>
> "→ Found 15 usage sites across 8 files (in 0.1 seconds)"

---

## Summary

**Key Takeaways**:
- **LSP > grep** for code navigation (symbols, types, definitions)
- **grep > LSP** for text search (strings, comments, broad exploration)
- Use LSP features:
  - **Go to Definition**: Find where symbols are defined
  - **Find References**: Locate all usages
  - **Type Hierarchy**: Understand inheritance
  - **Hover**: Quick type info
- Avoid anti-patterns:
  - Don't grep for class/function definitions
  - Don't grep for method call sites
  - Don't confuse string search with type search
- Self-correct before running grep on code symbols

**Expected impact**:
- ✅ 80%+ faster code navigation
- ✅ 100% accuracy for symbol lookups
- ✅ Reduced token usage (fewer file reads)
- ✅ Better understanding of code structure

---

**This guideline applies to**: All code investigation tasks

**Related guidelines**: `.claude/rules/repository-investigation.md` (Investigation workflow)

---

## Quick Reference Table

| Task | grep | LSP | Recommended |
|------|------|-----|-------------|
| Find RPC definition | ❌ | ✅ Go to Definition | **LSP** |
| Find RPC usage sites | ❌ | ✅ Find References | **LSP** |
| Find Provider definition | ❌ | ✅ Go to Definition | **LSP** |
| Find Provider usages | ❌ | ✅ Find References | **LSP** |
| Find error message string | ✅ | ❌ | **grep** |
| Find TODO comments | ✅ | ❌ | **grep** |
| Understand class hierarchy | ❌ | ✅ Type Hierarchy | **LSP** |
| Find method callers | ❌ | ✅ Find References | **LSP** |
| Broad keyword exploration | ✅ | ❌ | **grep** |
| Find file by name | ✅ (find) | ❌ | **find** |

**Rule of thumb**: If it's a **code symbol** (function, class, variable), use **LSP**. If it's **text content** (strings, comments), use **grep**.
