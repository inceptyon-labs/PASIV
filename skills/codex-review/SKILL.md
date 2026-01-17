---
name: codex-review
description: Deep code review using Codex CLI. Use when user says "codex review", "deep review", "security review", or wants thorough analysis of code, PR, or specific files.
allowed-tools:
  - Bash
  - Read
---

# Codex Deep Review

Run Codex for deep analysis: $ARGUMENTS (files, PR number, or empty for current changes)

## Option 1: Quick Review (current changes)

If no arguments or reviewing current branch:

```bash
codex /review --sandbox read-only
```

## Option 2: Targeted Review (specific files or PR)

### For PR number:
```bash
FILES=$(gh pr view NUMBER --json files -q '.files[].path' | tr '\n' ', ')

codex --quiet "Deep code review for PR #NUMBER.

Files changed:
$FILES

Review for:
1. Security vulnerabilities (injection, auth bypass, data exposure)
2. Architecture issues (coupling, SOLID violations, patterns)
3. Edge cases and error handling
4. Performance problems
5. Maintainability concerns

For each finding:
- Severity: ERROR (must fix) / WARNING (should fix) / SUGGESTION
- Location: file:line
- Description: What's wrong
- Fix: How to resolve it

Be thorough and specific."
```

### For specific files:
```bash
codex --quiet "Deep code review of the following files:

$ARGUMENTS

Review for:
1. Security vulnerabilities
2. Architecture issues
3. Edge cases and error handling
4. Performance problems
5. Maintainability concerns

Categorize as ERROR/WARNING/SUGGESTION with file:line locations."
```

### For current changes vs main:
```bash
FILES=$(git diff --name-only main)

codex --quiet "Deep code review of current changes.

Files changed:
$FILES

Review for security, architecture, edge cases, performance, maintainability.
Categorize as ERROR/WARNING/SUGGESTION with file:line locations."
```

## Report Results

Format Codex findings clearly and offer to fix any errors.
