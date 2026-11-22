---
name: acp
description: Commit and push all local uncommitted changes with an AI-generated Conventional Commit message. Use when the user says "acp", "add commit push", "commit and push", or asks to publish everything local.
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
  - Bash(git branch:*)
  - Bash(git rev-parse:*)
  - Bash(git remote:*)
  - Bash(grep:*)
  - Bash(cat .deploy)
  - Bash(deploy:*)
  - Bash(~/bin/deploy:*)
---

# acp: add, commit, push

Plain `acp` commits **everything changed in the current repository** and pushes it, even if the
changes span several sessions. Don't split commits, partially stage, or leave files out unless the
user gave a scope or a safety blocker applies. Many files or old edits are not blockers.

## Steps

1. `git status` — read the state and the file list in one call.
   - Mid-merge, mid-rebase, or mid-cherry-pick → stop (blocker).
   - Nothing to commit: if the branch is ahead of its upstream, skip to step 7 and push; otherwise
     report "nothing to commit" and stop.
2. `git add -A` — stage first so the checks below cover untracked files too.
3. `git diff --cached --stat` and `git diff --cached --check`.
4. Secret scan (see Safety Blockers).
5. Write the message. Use this session's context if it made the changes; otherwise read
   `git diff --cached` (over ~1,500 changed lines: read the stat plus the most-changed files only).
   Check `git log --oneline -8` and match the repo's scope names and style.
6. `git commit -m "<message>"`.
7. Push — see Push.
8. Deploy hook — see Deploy.

## Scoped Path

Only when the user names a scope (`acp dashboard only`, `commit the testing changes`,
`acp but not generated files`): stage explicit pathspecs (`git add path/a path/b`) instead of
`git add -A`, leave the rest unstaged, then run steps 3–8. Commit only if
`git diff --cached --stat` matches the intended scope.

## Push

- `git push`. No upstream yet → `git push -u origin HEAD`.
- Rejected because the remote has new commits (e.g. a CI version-bump commit): `git pull --rebase`,
  then `git push`. If the rebase conflicts, `git rebase --abort` and stop. The local commit is
  intact; report the conflicting files.
- Never force push.

## Deploy

Only when the push succeeded, the branch is `main` or `master`, and the repo root has a `.deploy`
file: run `cat .deploy`, then `deploy <name>` with the name typed literally (plain `deploy` if the
file is empty; it defaults to the repo directory name). Don't use `deploy $(cat .deploy)`, since
command substitution doesn't match the permission pattern. This ships the pushed HEAD to Uranus;
see the `uranus-deploy` skill.

## Safety Blockers

Stop and report before committing only when:

- `--check` reports **leftover conflict markers**. Trailing-whitespace warnings alone aren't a
  blocker. Mention them in the report and commit anyway.
- The repo is mid-merge, mid-rebase, or mid-cherry-pick.
- The secret scan finds something real. Run:

  ```bash
  git diff --cached --name-only | grep -E '(^|/)(\.env(\.[^/]+)?|id_rsa[^/]*|credentials[^/]*\.json|settings\.local\.json)$|\.(pem|p8|p12|key|jks|keystore)$' | grep -vE '\.(example|sample|template|pub)$'
  git diff --cached --name-only -G'(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|(^|[^A-Za-z0-9])sk-(ant-|proj-)?[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35})'
  ```

  The first lists risky filenames. The second lists files whose diff contains key-shaped strings
  (git's own regex engine; piping the diff through `grep` can hit ugrep's complexity limit). Look at
  a hit with `git diff --cached -U0 -- <file>`.

  Obvious placeholders (`sk-xxxx`, `AKIAIOSFODNN7EXAMPLE`) are fine. Anything else: stop.

On a blocker, leave the files staged and tell the user `git restore --staged <path>` unstages them.

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
- Current repository only. If the user names several repos, commit and push each separately and
  report every SHA.

## Final Response

Keep it short: repo, branch, commit SHA and message, push result (say if a rebase onto the remote
was needed), deploy result if it ran, and anything left unstaged or flagged.
