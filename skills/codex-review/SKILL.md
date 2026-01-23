---
name: codex-review
description: Deep code review using Codex CLI. Use when user says "codex review", "deep review", "security review", or wants thorough analysis of code, PR, or specific files.
model: haiku
context: fork
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - mcp__my-codex-mcp__codex
---

# Codex Deep Review

Run Codex for deep analysis: $ARGUMENTS (branch, commit SHA, or empty for current changes)

## Step 1: Get the Code to Review

```bash
# Get the diff (current branch vs main, or specific commit/branch)
git diff main
```

## Step 2: Call Codex MCP Tool

Use the `mcp__my-codex-mcp__codex` tool with:

| Parameter | Value |
|-----------|-------|
| `prompt` | "Focus on security vulnerabilities, architecture issues, and edge cases. For each finding: Severity (ERROR/WARNING/SUGGESTION), Location (file:line), Description and fix. Be thorough and specific." |
| `code` | The diff output from Step 1 |
| `context` | "Code review of git diff" |

**Example tool call:**
```
mcp__my-codex-mcp__codex(
  prompt: "Focus on security vulnerabilities, architecture issues, and edge cases...",
  code: "<diff output>",
  context: "Code review of git diff against main branch"
)
```

## Report Results

Format Codex findings clearly and offer to fix any errors.
