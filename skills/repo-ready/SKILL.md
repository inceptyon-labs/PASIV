---
name: repo-ready
description: Prepare a project for its first push to GitHub. Generates repo description, README polish, LICENSE, CONTRIBUTING, SECURITY, CHANGELOG, .github templates, and scans for committed secrets. Use when user says "repo ready", "prep for github", "first push", "get this ready to publish", or is about to create a new repo.
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Skill
user-invocable: true
---

# Repo Ready

Prepare the current project for its first push to a public or private git host. Scan the codebase for signals, propose a complete set of repo artifacts, confirm only the non-inferrable choices, then write the files and print (do NOT execute) the final `gh repo create` command.

**Input:** $ARGUMENTS (optional — pass `--dry-run` to print the plan without writing files)

---

## Phase 1: Preflight

```bash
pwd && git rev-parse --is-inside-work-tree 2>/dev/null && git remote -v
```

If not a git repo, stop and suggest `git init` first.

If `origin` already exists and points to a real remote, ask whether to continue — this skill is for *first* push prep. If they say yes, skip the final `gh repo create` step at the end.

---

## Phase 2: Scan for Signals

Gather everything inferrable before asking the user anything. Run these in parallel where possible.

**Project type & stack** (read only the files that exist):
- `package.json` → name, description, author, license, scripts, deps → detect framework (React/Next/Vue/Fastify/Express/etc.)
- `pyproject.toml` / `setup.py` / `requirements.txt` → Python
- `Cargo.toml` → Rust
- `go.mod` → Go
- `Gemfile` → Ruby
- `composer.json` → PHP
- `pubspec.yaml` → Dart/Flutter
- `Dockerfile`, `docker-compose.yml` → deployment signals
- `.github/workflows/` → existing CI

**Existing docs** (so we don't overwrite):
```bash
ls README* LICENSE* CONTRIBUTING* SECURITY* CHANGELOG* CODE_OF_CONDUCT* .github 2>/dev/null
```

**Secret leakage scan** — **do this before writing anything**:
```bash
git ls-files | grep -E '^(\.env$|\.env\.|.*\.pem$|.*\.key$|credentials|secrets\.)' 2>/dev/null
```
Also scan `.env.example` and any committed config for values that look like real secrets (hex strings ≥32 chars, `sk_live_`, `AKIA`, `ghp_`, `xoxb-`, JWTs). If any real secrets are committed: **STOP the entire skill** and report to the user. Do not proceed until they rotate and remove.

**Repo origin hint:**
```bash
git config --get user.name && git config --get user.email && gh api user --jq .login 2>/dev/null
```

Store everything detected as a **repo-manifest** you'll reference through the rest of the skill.

---

## Phase 3: Propose & Confirm

Print a short summary of what was detected (3-5 bullets max) and the draft plan. Example:

```
Detected: Node 20 / Fastify + React / Postgres / Docker
Existing: README.md (basic), .gitignore, .env.example
Missing:  LICENSE, CONTRIBUTING.md, SECURITY.md, CHANGELOG.md, .github/
Secrets:  clean ✓
```

Then ask **only** the questions that can't be inferred. Use `AskUserQuestion` with multiple-choice where possible.

**Question 1 — License:**
- MIT (most permissive, default for open source)
- Apache-2.0 (permissive + patent grant)
- AGPL-3.0 (copyleft, network use triggers)
- Proprietary / None (no LICENSE file)
- Other (user specifies)

**Question 2 — Visibility:**
- Public
- Private

**Question 3 — Accept contributions?** (gates CONTRIBUTING.md + templates)
- Yes — include CONTRIBUTING.md, issue templates, PR template
- No — skip contribution scaffolding

**Question 4 — Repo description:**
Draft a one-line description (≤350 chars, GitHub's limit) from the scan. Present it and ask:
- Use as-is
- Edit it (user provides text)
- Generate 3 alternatives to choose from

**Question 5 — Logo / banner:**
- Already have one (provide path)
- Generate with nano-banana
- Skip

**Question 6 — Repo owner + name:**
Default from `gh api user` + directory name. Confirm or override.

**Question 7 — CI starter?**
Only ask if no `.github/workflows/` exists AND the project has a detectable test command:
- Yes — generate a basic CI workflow (test + build on PR)
- No

---

## Phase 4: Generate Artifacts

Write files only for what's missing or was approved to replace. Never overwrite an existing file without explicit confirmation.

### 4a. LICENSE

Fetch the SPDX-standard text for the chosen license. For MIT/Apache-2.0/AGPL-3.0, use the canonical template with `{year}` and `{copyright holder}` filled from `git config user.name` (confirm with user if ambiguous).

### 4b. README.md

If a README exists, **enhance it** rather than replacing. Check for and add any missing sections:
- Logo/banner at top (if generated or provided)
- Badges row (license, CI status placeholder, version if in package.json)
- One-line description (from Phase 3)
- Quickstart / Install
- Usage
- Configuration / Environment Variables
- API (if server project)
- Contributing (link to CONTRIBUTING.md)
- License

If no README exists, generate from the repo-manifest with all standard sections.

### 4c. CONTRIBUTING.md (if accepting contributions)

Standard sections: Code of Conduct link, Development setup, Running tests, Commit style, PR process, Issue reporting.

### 4d. CODE_OF_CONDUCT.md (if accepting contributions)

Use the Contributor Covenant 2.1 template with maintainer email from `git config user.email` (confirm).

### 4e. SECURITY.md

Template with a vuln-reporting email or link. Ask for the reporting channel if not inferable.

### 4f. CHANGELOG.md

Seed with Keep-a-Changelog format:
```markdown
# Changelog
All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - YYYY-MM-DD
### Added
- Initial release.
```

### 4g. .github/ templates (if accepting contributions)

- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

### 4h. CI workflow (if approved)

Detect test runner from package.json / pyproject / etc. Write `.github/workflows/ci.yml` with lint + test + build on PR and main push. Keep it minimal — user can expand later.

### 4i. .gitignore sanity

Check the existing `.gitignore` for common omissions given the detected stack (e.g., `node_modules`, `dist`, `.env`, `__pycache__`, `target/`, `.DS_Store`). Append missing entries with a comment block header `# Added by repo-ready`.

### 4j. Logo (if requested)

**Use Skill tool:** `nano-banana` with args describing the project, `--transparent` flag. Save to `assets/logo.png` or `.github/logo.png`. Reference from README.

---

## Phase 5: Final Review

Show a summary of everything written/modified:

```
Wrote:
  LICENSE (MIT)
  CONTRIBUTING.md
  CODE_OF_CONDUCT.md
  SECURITY.md
  CHANGELOG.md
  .github/ISSUE_TEMPLATE/bug_report.md
  .github/PULL_REQUEST_TEMPLATE.md
  .github/workflows/ci.yml
Modified:
  README.md (added badges, logo, license section)
  .gitignore (added .env, .DS_Store)
Skipped:
  (none)
```

Run a final check:
```bash
git status --short
```

---

## Phase 6: Print gh repo create Command

**Do NOT execute.** Print the command so the user can review and run it themselves. This is a shared-state action — creating a remote repo has consequences (name collision, wrong org, etc.) that merit explicit user action.

Build from the manifest:

```bash
gh repo create <owner>/<name> \
  --<public|private> \
  --description "<description>" \
  --source=. \
  --remote=origin \
  --push
```

If topics were inferred from the stack (e.g., `react`, `fastify`, `postgres`, `docker`), suggest a follow-up:

```bash
gh repo edit <owner>/<name> --add-topic <t1>,<t2>,<t3>
```

End with: "Review the artifacts, then run the commands above when you're ready."

---

## STOP

**This skill prepares artifacts and prints commands. It does NOT:**
- Execute `gh repo create`
- Push to remote
- Commit changes (user decides when to commit)
- Overwrite existing files without confirmation

If the user asks to commit + push after review, they should do it themselves or invoke `/acp`.

---

## Principles

- **Inferred-first, ask-second.** Every question should be one that can't be answered by reading the repo.
- **Never overwrite silently.** Existing README/LICENSE/etc. are enhanced or skipped, never replaced without explicit yes.
- **Secrets are a hard stop.** If committed secrets are found, halt and report. No exceptions.
- **Print, don't execute, shared-state commands.** `gh repo create` and `git push` are the user's call.
- **Match the project's voice.** If the existing README is terse, stay terse. If it has ASCII diagrams and personality, match that energy.
