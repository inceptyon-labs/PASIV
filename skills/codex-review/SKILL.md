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

## Step 2: Check Diff Size

```bash
git diff main --stat | tail -1  # Shows total lines changed
```

**If diff is large (> 500 lines changed):** Split by file to avoid timeout.

```bash
# Get list of changed files
git diff main --name-only
```

For each file (or logical group of related files):
1. Get file-specific diff: `git diff main -- path/to/file.ts`
2. Call Codex with that chunk
3. Collect findings
4. Move to next file

**If diff is small (≤ 500 lines):** Review entire diff at once (Step 3).

## Step 3: Call Codex MCP Tool

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

Format Codex findings clearly. If any ERRORs found, fix them immediately and commit. Do not ask for permission.
