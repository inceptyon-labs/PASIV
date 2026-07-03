---
name: git-ops
description: Git operations helper. Use for branch creation, commits, push, merge. Internal skill - typically called by /kick.
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
If the branch already exists, `git checkout feature/issue-$ISSUE_NUM` instead and say so.

### commit
Stage and commit changes with a message.
```bash
git add -A
git commit -m "$MESSAGE"
```
If there is nothing to commit, report "nothing to commit" — that is not an error.

### push
Push current branch to origin.
```bash
git push origin $(git branch --show-current)
```
If the push is rejected or there is no remote, report the error and stop — do not force-push.

### merge-to-main
Merge feature branch to main and clean up. Delete the branch only after the merge is committed AND pushed:
```bash
BRANCH=$(git branch --show-current)
git status --porcelain          # must be empty; if not, stop and report the dirty files
git checkout main
git merge $BRANCH               # on conflict: git merge --abort, report the conflicting files, stop
git push origin main            # on failure: report and stop — keep $BRANCH, do not delete
git branch -d $BRANCH
```
Never resolve conflicts yourself — abort and report; the caller decides.

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
