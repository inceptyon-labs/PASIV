# GitHub Automation - Free Version

**Cost**: $0/month (uses your Claude Code subscription)

## How It Works

### 1. Create Issues from Spec (5-10 min)

In Claude Code, say:
```
Read my spec.md and generate GitHub CLI commands to create epics and issues
```

I'll give you commands like:
```bash
gh issue create --title "[EPIC] Feature X" --label "epic"
gh issue create --title "Task Y" --label "enhancement,size: M"
```

Run them → issues created!

### 2. Work on Issues

Pick an issue, work with Claude Code normally.

### 3. Review PRs

**One-time**: Install Claude GitHub App at https://github.com/apps/claude-code

**Every PR**: Comment `@claude review this PR`

### 4. Merge

Fix issues found, then merge.

---

## Setup (5 min)

### In This Repo

```bash
# Create labels
bash .github/scripts/create-labels.sh
```

### On GitHub

1. Install Claude GitHub App: https://github.com/apps/claude-code
2. Create a GitHub Project (optional)

Done!

---

## What's Included

- ✅ Issue templates (Epic & Task)
- ✅ Labels (size, priority, area)
- ✅ Claude handler workflow
- ✅ All organized, $0 cost

## Files

```
.github/
├── workflows/
│   └── claude-handler.yml        # Responds to @claude mentions
├── scripts/
│   ├── create-labels.sh          # Creates GitHub labels
│   └── utils/                    # Helper utilities
├── ISSUE_TEMPLATE/
│   ├── epic.yml                  # Epic template
│   └── task.yml                  # Task template
└── README.md                     # This file
```

That's it. Simple and free.
