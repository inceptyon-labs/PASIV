---
name: acp
description: Commit and push all local uncommitted changes with an AI-generated Conventional Commit message. Use when the user says "acp", "add commit push", "commit and push", or asks to publish everything local.
argument-hint: "[optional summary or scope]"
model: sonnet
user-invocable: true
allowed-tools:
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(git push:*)
  - Bash(git checkout:*)
  - Bash(git merge:*)
  - Bash(git branch:*)
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git rev-parse:*)
  - Bash(git remote:*)
  - Bash(test -f .deploy:*)
  - Bash(cat .deploy:*)
  - Bash(deploy:*)
  - Bash(~/bin/deploy:*)
---

# Task: Add, Commit, and Push with AI-Generated Message

Perform a complete git publish workflow. Default behavior for plain `acp` is: commit **everything currently changed in the current repository** and push it.

Terminology: a "dirty" tree means local uncommitted changes from `git status`, not divergence from the remote.

## Default Path: Commit Everything

Use this path for plain `acp`, even if the changes come from multiple sessions:

1. `git status --short`
2. `git diff --stat`
3. `git diff --check`
4. Draft one **Conventional Commit** message summarizing the whole local changeset.
5. `git add -A`
6. `git commit -m "<message>"`
7. `git push`
8. **Deploy hook.** If the repo root has a `.deploy` file and the current branch is `main`, run `~/bin/deploy $(cat .deploy)` (an empty file means the repo directory name). This ships the just-pushed HEAD to Uranus and rebuilds it; see the `uranus-deploy` skill. Include the deploy result in the final response. Never run it on a non-main branch or when the push failed.

Do not split commits, partially stage, or exclude files unless the user supplied a scope or a safety blocker applies.

## Scoped Path

Use this path only when the user includes an explicit scope such as `acp dashboard only`, `commit the testing changes`, or `acp this repo but not generated files`.

1. Identify the intended commit scope from the user's request and recent task context.
2. Stage only relevant paths with explicit pathspecs:

   ```bash
   git add path/to/file another/path
   ```

3. Leave unrelated changes unstaged.
4. Before committing, run:

   ```bash
   git diff --cached --stat
   git diff --cached --check
   ```

5. Commit and push only if the staged diff matches the intended scope.

## Safety Blockers

Pause and ask or report clearly before committing only when one of these is true:

- `git diff --check` reports whitespace or conflict-marker errors.
- The staged diff appears to contain secrets, private keys, credentials, `.env` values, or tokens.
- The repo is mid-merge, mid-rebase, or has unresolved conflict markers.
- There is nothing to commit.

Do not treat "many files", "old local edits", or "multiple sessions worth of work" as a blocker for plain `acp`.

## Multiple Repositories

For plain `acp`, operate in the current repository only. If the user explicitly asks to publish multiple repositories, commit and push each repository separately and report every commit SHA.

## Final Response

Report:

- Repository name or path
- Commit SHA and message
- Push result
- Deploy result, if the repo has a `.deploy` file (service name, rev, container status)
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
* Follow the Git Safety Protocol from system instructions
* Keep the workflow moving; avoid interactive git commands
