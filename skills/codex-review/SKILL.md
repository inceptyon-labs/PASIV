---
name: codex-review
description: Deep code review using Codex CLI. Use when user says "codex review", "deep review", "security review", or wants thorough analysis of code, PR, or specific files.
allowed-tools:
  - Bash
  - Read
---

# Codex Deep Review

Run Codex for deep analysis: $ARGUMENTS (branch, commit SHA, or empty for current changes)

## Option 1: Review Current Branch vs Main

```bash
codex review --base main
```

## Option 2: Review with Custom Focus

```bash
codex review --base main "Focus on security vulnerabilities, architecture issues, and edge cases.

For each finding:
- Severity: ERROR / WARNING / SUGGESTION
- Location: file:line
- Description and fix

Be thorough and specific."
```

## Option 3: Review Specific Commit

```bash
codex review --commit SHA
```

## Option 4: Review Uncommitted Changes

```bash
codex review --uncommitted
```

## Option 5: Custom Prompt (Non-interactive)

For complex custom analysis:

```bash
codex exec -s read-only "Analyze the codebase for:
1. Security vulnerabilities
2. Performance bottlenecks
3. Code duplication

$ARGUMENTS"
```

## Report Results

Format Codex findings clearly and offer to fix any errors.
