# GitHub Automation Plugin

Solo dev workflow: specs → issues → implement → 3-model review → merge.

## Install

```bash
# Add marketplace
/plugin marketplace add your-username/github-automation

# Install plugin
/plugin install github-automation
```

Or install directly from GitHub:
```bash
/plugin install github:your-username/github-automation
```

## The Pipeline

```
Issue → Plan → Implement → Review (Sonnet→Opus→Codex) → Merge
```

## Commands

| Command | Example |
|---------|---------|
| `/issue` | `/issue add logout button` |
| `/epic` | `/epic user notifications` |
| `/start` | `/start 42` or `/start next` |
| `/review` | `/review` (current branch) |
| `/backlog` | `/backlog` (parse spec.md) |

## Full Flow

```
/start 42
```

1. Read issue #42
2. Create plan → wait for approval
3. Implement on feature branch
4. Review: Sonnet → Opus → Codex
5. Fix errors (max 3 iterations)
6. Merge to main & close issue

## Review Pipeline

| Pass | Model | Focus |
|------|-------|-------|
| 1 | Sonnet | Bugs, security basics, dead code |
| 2 | Opus | Architecture, edge cases, performance |
| 3 | Codex | Fresh eyes, what others missed |

## Requirements

- **GitHub CLI** (`gh`) - https://cli.github.com
- **Codex MCP** - for Pass 3 reviews (optional)

## Setup for Your Repo

After installing the plugin, run in your project:

```bash
# Create labels
bash $(claude plugin path github-automation)/.github/scripts/create-labels.sh
```

Or manually copy the GitHub templates:
```bash
cp -r $(claude plugin path github-automation)/.github/ISSUE_TEMPLATE .github/
```

## Files

```
.claude-plugin/
├── plugin.json          # Plugin manifest
└── marketplace.json     # Marketplace definition

skills/                  # Slash commands
├── issue/SKILL.md       # /issue
├── epic/SKILL.md        # /epic
├── start/SKILL.md       # /start
├── review/SKILL.md      # /review (3-model)
├── codex-review/SKILL.md # /codex-review
└── backlog/SKILL.md     # /backlog

.github/
├── scripts/             # Setup scripts
├── workflows/           # GitHub Actions (optional)
└── ISSUE_TEMPLATE/      # Issue templates
```

## Labels

| Category | Labels |
|----------|--------|
| Type | `epic`, `enhancement`, `bug` |
| Priority | `priority:high`, `priority:medium`, `priority:low` |
| Size | `size:S`, `size:M`, `size:L` |
| Area | `area:frontend`, `area:backend`, `area:infra`, `area:db` |

## Publishing Your Own Marketplace

1. Push to GitHub
2. Others install with:
   ```bash
   /plugin marketplace add your-username/github-automation
   /plugin install github-automation
   ```

## GitHub Actions (Optional)

For cloud automation, add API key to your repo:

```bash
gh secret set ANTHROPIC_API_KEY
```

Then `@claude /start` works on GitHub.com.
