# GitHub Automation Plugin

## Slash Commands

| Command | What it does |
|---------|-------------|
| `/issue add dark mode toggle` | Create a sized & labeled issue |
| `/parent user notifications` | Create parent issue + sub-issues |
| `/start 42` | Plan → Implement → Review → Merge |
| `/start next` | Work on highest priority issue |
| `/review` | Sonnet → Opus → Codex review pipeline |
| `/review feature-branch` | Review specific branch |
| `/codex-review` | Codex-only deep review |
| `/backlog` | Create issues from spec.md |
| `/backlog design.md` | Create issues from custom spec |

## Examples

**Create an issue:**
```
/issue add CSV export to reports page
```

**Create a parent issue with sub-issues:**
```
/parent user notification system with email and push
```

**Full implementation flow:**
```
/start 42
```
1. Read issue #42
2. Create implementation plan
3. Ask for your approval
4. Implement on a feature branch
5. Run 3-model review (Sonnet → Opus → Codex)
6. Fix any errors found
7. Merge to main & close issue

## Review Pipeline

| Pass | Model | Focus |
|------|-------|-------|
| 1 | Sonnet | Bugs, security basics, dead code |
| 2 | Opus | Architecture, edge cases, performance |
| 3 | Codex MCP | Fresh eyes, what others missed |

**Restart logic:**
- Errors from Opus/Codex → fix → restart from Pass 1
- Errors from Sonnet only → fix → re-run Pass 1
- Max 3 iterations → ask user

## Labels

| Category | Labels |
|----------|--------|
| Type | `enhancement`, `bug`, `documentation` |
| Priority | `priority:high`, `priority:medium`, `priority:low` |
| Size | `size:S` (1-4h), `size:M` (4-8h), `size:L` (8+h) |
| Area | `area:frontend`, `area:backend`, `area:infra`, `area:db` |

## GitHub Projects Integration

Issues are automatically added to a GitHub Project board.

**Auto-created project**: Named after your repository (created on first `/issue`, `/parent`, or `/backlog`)

**Auto-prioritization**: `/backlog` outputs suggested implementation order based on:
1. Layer dependencies: `area:db` → `area:infra` → `area:backend` → `area:frontend`
2. Parent/sub-issue relationships: Parents before children
3. Explicit dependencies: `Depends on #N` in issue body

**Required token scope**:
```bash
gh auth refresh -s project
```

## Plugin Structure

```
skills/
├── issue/SKILL.md       # /issue
├── parent/SKILL.md      # /parent
├── start/SKILL.md       # /start (full flow)
├── review/SKILL.md      # /review (3-model)
├── codex-review/SKILL.md # /codex-review
└── backlog/SKILL.md     # /backlog

.github/
├── scripts/
│   ├── install.sh       # Setup script
│   └── create-labels.sh # Create labels
├── workflows/           # GitHub Actions (optional)
└── ISSUE_TEMPLATE/      # Issue templates
```
