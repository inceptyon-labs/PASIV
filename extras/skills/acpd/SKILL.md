---
name: acpd
description: Commit and push all local uncommitted changes, merge the current branch to main, push main, and delete the feature branch. Use when the user says "acpd" or asks to publish and delete a branch.
argument-hint: "[optional summary or scope]"
model: sonnet
user-invocable: true
allowed-tools:
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(git push:*)
  - Bash(test -f .deploy:*)
  - Bash(cat .deploy:*)
  - Bash(deploy:*)
  - Bash(~/bin/deploy:*)
  - Bash(git checkout:*)
  - Bash(git merge:*)
  - Bash(git branch:*)
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git rev-parse:*)
  - Bash(git remote:*)
---

# Task: Add, Commit, Push, Merge to Main, and Delete Branch

Perform the complete branch closeout workflow. Default behavior for plain `acpd` is: commit **everything currently changed in the current repository**, push the current branch, merge it into main, push main, then delete the feature branch locally and remotely.

Terminology: a "dirty" tree means local uncommitted changes from `git status`, not divergence from the remote.

## Default Path: Commit Everything, Then Merge

Use this path for plain `acpd`, even if the changes come from multiple sessions:

1. `git branch --show-current`
2. Stop if current branch is `main` or `master`; there is no feature branch to merge/delete.
3. `git status --short`
4. `git diff --stat`
5. `git diff --check`
6. Draft one **Conventional Commit** message summarizing the whole local changeset.
7. `git add -A`
8. If there are staged changes, `git commit -m "<message>"`.
9. `git push origin <current-branch>`
10. `git checkout main`
11. `git merge <current-branch>`
12. `git push origin main`
13. **Deploy hook.** If the repo root has a `.deploy` file, run `~/bin/deploy $(cat .deploy)` now that main is pushed (empty file means the repo directory name). Report the result.
14. `git branch -d <current-branch>`
15. `git push origin --delete <current-branch>`

Do not split commits, partially stage, or exclude files unless the user supplied a scope or a safety blocker applies.

## Scoped Path

Use this path only when the user includes an explicit scope such as `acpd dashboard only`, `commit the testing changes`, or `acpd this repo but not generated files`.

1. Identify the intended commit scope from the user's request and recent task context.
2. Stage only relevant paths with explicit pathspecs.
3. Leave unrelated changes unstaged.
4. Before committing, run:

   ```bash
   git diff --cached --stat
   git diff --cached --check
   ```

5. Commit, push, merge, and delete only if the staged diff matches the intended scope.

## Safety Blockers

Pause and ask or report clearly before committing or merging only when one of these is true:

- `git diff --check` reports whitespace or conflict-marker errors.
- The staged diff appears to contain secrets, private keys, credentials, `.env` values, or tokens.
- The repo is mid-merge, mid-rebase, or has unresolved conflict markers.
- The current branch is `main` or `master`.
- `git merge <current-branch>` reports conflicts.

Do not treat "many files", "old local edits", or "multiple sessions worth of work" as a blocker for plain `acpd`.

## Empty Commit Handling

If there are no local changes, skip the commit step and continue with push/merge/delete only if the branch already has commits to merge.

## Final Response

Report:

- Repository name or path
- Feature branch name
- Commit SHA and message, or note that no commit was needed
- Main merge result
- Branch deletion result
- Any intentionally unstaged files, summarized briefly

**Conventional Commit Format (REQUIRED):**

```
<type>[optional scope]: <description>
```

**Types:**

* `feat` - New feature
* `fix` - Bug fix
* `perf` - Performance improvement
* `docs` - Documentation only
* `style` - Formatting, whitespace
* `refactor` - Code restructuring
* `test` - Adding/updating tests
* `chore` - Maintenance tasks
* `ci` - CI/CD changes

**Important:**

* Use lowercase for type and description
* No period at end of description
* Do NOT add the Claude Code attribution footer
* Never force push to main
* Confirm the current branch name before deletion
* Follow the Git Safety Protocol from system instructions
* Keep the workflow moving; avoid interactive git commands
