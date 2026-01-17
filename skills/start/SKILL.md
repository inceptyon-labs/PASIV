---
name: start
description: Full implementation flow - plan, implement, review, merge. Use when user says "start issue", "work on issue", "implement issue", "start #42", or wants to fully implement and merge a GitHub issue.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# Start Working on Issue

Full flow for: $ARGUMENTS (issue number or "next")

## Step 1: Get Issue

```bash
gh issue view NUMBER --json title,body,labels
```

If "next", find highest priority:
```bash
gh issue list --label "priority:high" --state open --limit 1
```

## Step 2: Create Plan

Analyze the issue and codebase. Present:

- **Summary**: What we're building
- **Files to modify**: With expected changes
- **New files**: If any
- **Approach**: Step-by-step
- **Risks**: Potential issues

Ask: **"Does this plan look good?"**

Wait for approval before continuing.

## Step 3: Implement

```bash
git checkout -b feature/issue-NUMBER
```

Make the changes, then commit:

```bash
git add -A && git commit -m "feat: description (#NUMBER)"
```

## Step 4: 3-Model Review

Run the full review pipeline on the branch:

### Pass 1: Sonnet (fast)
Quick scan for obvious bugs, security basics, dead code.

### Pass 2: Opus (deep)
Architecture, edge cases, performance, maintainability.

### Pass 3: Codex (independent)
Use `mcp__codex__codex`:
```
mcp__codex__codex(
  prompt: "Independent code review - catch what others missed. Review for subtle bugs, security edge cases, test gaps. Categorize as ERROR/WARNING/SUGGESTION.",
  sandbox: "read-only"
)
```

## Step 5: Fix & Iterate

If errors found:
1. Fix them
2. Commit: `git add -A && git commit -m "fix: address review findings"`
3. If errors were from Opus/Codex → restart from Pass 1
4. If errors were only from Sonnet → re-run Pass 1 only
5. Max 3 iterations before asking user

## Step 6: Merge

When all passes are clean:

```bash
git checkout main
git merge feature/issue-NUMBER
git push origin main
git branch -d feature/issue-NUMBER
gh issue close NUMBER --comment "Completed in $(git rev-parse --short HEAD)"
```

Report:
```
## Done

Issue #NUMBER completed and merged to main.

Review passes:
- Pass 1 (Sonnet): ✓
- Pass 2 (Opus): ✓
- Pass 3 (Codex): ✓

Commit: abc1234
```
