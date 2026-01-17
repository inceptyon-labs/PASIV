# GitHub Automation Plugin

Solo dev workflow: specs → issues → implement → test → 3-model review → merge.

## Install

```bash
claude plugin install github:jnew00/github-automation
```

## Quick Start

```bash
# Create a single issue
/issue add logout button to header

# Create a parent issue with sub-issues
/parent user authentication system

# Parse a spec into a full backlog
/backlog spec.md

# Start working on an issue (full flow)
/start 42
```

## Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/issue` | Create sized & labeled issue | `/issue add CSV export` |
| `/parent` | Create parent + sub-issues | `/parent user notifications` |
| `/backlog` | Parse spec into issues | `/backlog design.md` |
| `/start` | Full implementation flow | `/start 42` or `/start next` |
| `/3pass-review` | 3-model review pipeline | `/3pass-review feature-branch` |
| `/codex-review` | Deep Codex-only review | `/codex-review` |

## The `/start` Flow

```
/start 42
```

1. Get issue #42, move to **In Progress**
2. Create plan (including tests) → wait for approval
3. Implement on feature branch
4. **Write tests** for acceptance criteria
5. **Run tests** (must pass)
6. Review: Sonnet → Opus → Codex
7. Fix errors (max 3 iterations)
8. **Check off acceptance criteria**
9. Final test run
10. Merge to main, move to **Done**, close issue

### Parent/Sub-issue Cascading

- Starting a sub-issue → parent moves to In Progress
- Completing last sub-issue → parent moves to Done & closes

## Review Pipeline

| Pass | Model | Focus |
|------|-------|-------|
| 1 | Sonnet | Bugs, security basics, dead code, missing tests |
| 2 | Opus | Architecture, edge cases, performance, test coverage |
| 3 | Codex CLI | Fresh eyes, what others missed |

**Restart logic:**
- Errors from Opus/Codex → fix → restart from Pass 1
- Errors from Sonnet only → fix → re-run Pass 1

## GitHub Projects Integration

Issues are **automatically added** to a GitHub Project board.

- **Auto-creates project** named after your repo (on first `/issue`, `/parent`, or `/backlog`)
- **Prompts if other projects exist** (choose existing or create new)
- **Status updates**: Issues move to In Progress/Done automatically
- **Prioritization**: `/backlog` outputs suggested implementation order

### Required Token Scope

```bash
gh auth refresh -s project
```

### Implementation Order

`/backlog` prioritizes issues by:
1. Layer: `area:db` → `area:infra` → `area:backend` → `area:frontend`
2. Parent/sub-issue relationships
3. Explicit `Depends on #N` references

## Labels

| Category | Labels |
|----------|--------|
| Type | `enhancement`, `bug`, `documentation` |
| Priority | `priority:high`, `priority:medium`, `priority:low` |
| Size | `size:S` (1-4h), `size:M` (4-8h), `size:L` (8+h) |
| Area | `area:frontend`, `area:backend`, `area:infra`, `area:db` |

## Requirements

- **GitHub CLI** (`gh`) - https://cli.github.com
- **Codex CLI** - for Pass 3 reviews
- **jq** - for JSON parsing

## Setup for Your Repo

```bash
# Ensure token has project scope
gh auth refresh -s project

# Create labels (optional)
bash ~/.claude/plugins/github-automation/.github/scripts/create-labels.sh
```

## Plugin Structure

```
skills/
├── issue/SKILL.md         # /issue
├── parent/SKILL.md        # /parent (native sub-issues)
├── start/SKILL.md         # /start (full flow)
├── 3pass-review/SKILL.md  # /3pass-review
├── codex-review/SKILL.md  # /codex-review
└── backlog/SKILL.md       # /backlog

.github/
├── scripts/
│   ├── install.sh
│   └── create-labels.sh
└── workflows/
    └── version-bump.yml   # Auto-bump version on push
```

## Updating

```bash
rm -rf ~/.claude/plugins/cache
claude plugin update github-automation
```
