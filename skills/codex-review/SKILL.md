---
name: codex-review
description: Deep code review using Codex CLI MCP. Use when user says "codex review", "deep review", "security review", or wants thorough analysis of code, PR, or specific files.
allowed-tools:
  - Bash
  - Read
---

# Codex Deep Review

Run Codex for deep analysis: $ARGUMENTS (files or PR number)

## Get Context

If PR number:
```bash
gh pr diff NUMBER > /tmp/pr_diff.txt
gh pr view NUMBER --json files -q '.files[].path'
```

If files specified, read them directly.

If empty, get current changes:
```bash
git diff main > /tmp/changes.txt
git diff --name-only main
```

## Run Codex Review

Use the `mcp__codex__codex` MCP tool:

```
mcp__codex__codex(
  prompt: "Perform a thorough code review of these changes:

[paste diff or file contents]

Review for:
1. Security vulnerabilities (injection, auth bypass, data exposure)
2. Architecture issues (coupling, SOLID violations, patterns)
3. Edge cases and error handling
4. Performance problems
5. Maintainability concerns

For each finding:
- Severity: ERROR (must fix) / WARNING (should fix) / SUGGESTION
- Location: file:line if applicable
- Description: What's wrong
- Fix: How to resolve it

Be thorough and specific.",
  sandbox: "read-only"
)
```

## Report Results

Format Codex findings clearly and offer to fix any errors.
