---
name: git-ops
description: Git operations helper. Use for branch creation, commits, push, merge. Internal skill - typically called by /start.
model: haiku
context: fork
allowed-tools:
  - Bash
user-invocable: false
---

# Git Operations

Perform git operation: $ARGUMENTS

## Available Operations

### create-branch
Create a feature branch for an issue.
```bash
git checkout -b feature/issue-$ISSUE_NUM
```

### commit
Stage and commit changes with a message.
```bash
git add -A
git commit -m "$MESSAGE"
```

### push
Push current branch to origin.
```bash
git push origin $(git branch --show-current)
```

### merge-to-main
Merge feature branch to main and clean up.
```bash
BRANCH=$(git branch --show-current)
git checkout main
git merge $BRANCH
git push origin main
git branch -d $BRANCH
```

## Response Format

Return a brief confirmation:
```
✓ [operation]: [details]
```

Example:
```
✓ commit: "feat: add user authentication (#42)"
✓ push: feature/issue-42 → origin
✓ merge: feature/issue-42 → main
```
