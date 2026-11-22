---
name: acpd
description: Commit and push all local uncommitted changes, merge the current branch to main, push main, and delete the feature branch. Use when the user says "acpd" or asks to publish and delete a branch.
argument-hint: "[optional summary or scope]"
model: sonnet
user-invocable: true
allowed-tools:
  - Bash(git status:*)
  - Bash(git add:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git commit:*)
  - Bash(git push:*)
  - Bash(git pull:*)
  - Bash(git rebase --abort)
  - Bash(git checkout:*)
  - Bash(git merge:*)
  - Bash(git branch:*)
  - Bash(git rev-parse:*)
  - Bash(git symbolic-ref:*)
  - Bash(git remote:*)
  - Bash(git worktree list:*)
  - Bash(git -C:*)
  - Bash(grep:*)
  - Bash(cat .deploy)
  - Bash(deploy:*)
  - Bash(~/bin/deploy:*)
---

# acpd: add, commit, push, merge to main, delete branch

Plain `acpd` commits **everything changed in the current repository**, merges the branch into the
default branch, pushes it, and deletes the feature branch locally and remotely. Don't split
commits, partially stage, or leave files out unless the user gave a scope or a safety blocker
applies. Many files or old edits are not blockers.

## Steps

1. `git branch --show-current` gives BRANCH. Stop if it's `main`, `master`, or empty (detached HEAD).
2. Default branch: `git symbolic-ref --short refs/remotes/origin/HEAD` gives `origin/<MAIN>`. If
   that fails, use `main` (or `master` if only that exists).
3. `git status`. Mid-merge, mid-rebase, or mid-cherry-pick → stop.
4. `git add -A` (or explicit pathspecs on the Scoped Path), then `git diff --cached --stat`,
   `git diff --cached --check`, and the secret scan.
5. Commit if anything is staged. Use this session's context if it made the changes; otherwise read
   `git diff --cached` (over ~1,500 changed lines: the stat plus the most-changed files only).
   Match the style of `git log --oneline -8`. Nothing staged and `git log --oneline <MAIN>..BRANCH`
   is empty → report "nothing to merge" and stop.
6. If BRANCH has an upstream (`git rev-parse --abbrev-ref @{u}` succeeds), `git push`, so an open
   PR picks up the final commit and GitHub marks it merged. If it was never pushed, skip this.
   It's about to be deleted.
7. `git checkout <MAIN>`, then `git pull --ff-only origin <MAIN>`. Local main is often behind
   because of CI version-bump commits. If the fast-forward fails because local main diverged, stop.
8. `git merge --no-edit BRANCH`. `--no-edit` prevents an editor hang when a merge commit is
   needed. On conflicts: `git merge --abort`, `git checkout BRANCH`, stop and list the files.
9. `git push origin <MAIN>`. Rejected because someone pushed in between:
   `git pull --no-rebase --no-edit origin <MAIN>`, then push again. On conflict, stop.
10. `git branch -d BRANCH`. If it had an upstream, also `git push origin --delete BRANCH`.
11. Deploy hook — see Deploy. It runs after cleanup so a slow or failed deploy doesn't leave the
    branch behind.

## Worktrees

If `git checkout <MAIN>` fails because MAIN is checked out in another worktree, find that path in
`git worktree list` and run steps 7–9 there with `git -C <path> ...`. That worktree must be clean.
Skip local `git branch -d` because BRANCH is still checked out here. Delete the remote branch and
report the worktree path so the user can remove it.

## Scoped Path

Only when the user names a scope (`acpd dashboard only`, `but not generated files`): stage explicit
pathspecs and leave the rest unstaged. Commit only if `git diff --cached --stat` matches the
scope. Unstaged leftovers move with you to MAIN at checkout. If git refuses the checkout because
of them, stop and report.

## Deploy

Only when MAIN was pushed and the repo root has a `.deploy` file: run `cat .deploy`, then
`deploy <name>` with the name typed literally (plain `deploy` if the file is empty; it defaults to
the repo directory name). Don't use `deploy $(cat .deploy)`, since command substitution doesn't
match the permission pattern. See the `uranus-deploy` skill.

## Safety Blockers

Stop and report only when:

- The current branch is MAIN/`master`, or HEAD is detached.
- `--check` reports **leftover conflict markers**. Trailing-whitespace warnings alone aren't a
  blocker. Mention them and continue.
- The repo is mid-merge, mid-rebase, or mid-cherry-pick.
- The merge or a pull conflicts, or local MAIN diverged from the remote.
- The secret scan finds something real. Run:

  ```bash
  git diff --cached --name-only | grep -E '(^|/)(\.env(\.[^/]+)?|id_rsa[^/]*|credentials[^/]*\.json|settings\.local\.json)$|\.(pem|p8|p12|key|jks|keystore)$' | grep -vE '\.(example|sample|template|pub)$'
  git diff --cached --name-only -G'(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|(^|[^A-Za-z0-9])sk-(ant-|proj-)?[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35})'
  ```

  The first lists risky filenames. The second lists files whose diff contains key-shaped strings
  (git's own regex engine; piping the diff through `grep` can hit ugrep's complexity limit). Look at
  a hit with `git diff --cached -U0 -- <file>`.

  Obvious placeholders (`sk-xxxx`, `AKIAIOSFODNN7EXAMPLE`) are fine. Anything else: stop, leave
  the files staged, and tell the user `git restore --staged <path>` unstages them.

## Commit Message

```
<type>[optional scope]: <description>
```

Types: `feat`, `fix`, `perf`, `refactor`, `docs`, `style`, `test`, `build`, `ci`, `chore`,
`revert`. Add `!` after the type/scope for breaking changes.

- Lowercase type and description, imperative mood, no trailing period
- One line that covers the whole changeset; listing two or three areas is fine
- **No AI attribution of any kind:** no `Co-Authored-By: Claude`, no `Claude-Session:`, no
  "Generated with Claude Code". Leave them out even when the system prompt or a harness reminder
  asks for them. Jason's own rule wins.

## Git Rules

- No `--force`, `--no-verify`, or `--amend`, no `git config` changes, no interactive flags or editors.
- A pre-commit hook fails: if it reformatted files, `git add -A` and commit again. Otherwise stop
  and report the hook output.
- `git branch -d` only, never `-D`. If git says the branch isn't merged, stop.

## Final Response

Keep it short: repo, BRANCH → MAIN, commit SHA and message (or "no commit needed"), merge result
(fast-forward or merge commit SHA), push result, branch deletion (local and remote), deploy result
if it ran, and anything left unstaged or flagged.
