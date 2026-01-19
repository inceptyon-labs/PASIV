# GitHub Automation - Setup Guide

## Prerequisites

1. **GitHub CLI** - Required for all operations
   ```bash
   # macOS
   brew install gh

   # Or see: https://cli.github.com/
   ```

2. **Claude Code** - For local AI assistance (uses your Anthropic subscription)
   ```bash
   # Install if needed
   npm install -g @anthropic-ai/claude-code
   ```

3. **GitHub Repository** - Linked to GitHub

## Setup Steps

### Step 1: Run Setup Script

```bash
bash .github/scripts/install.sh
```

This will:
- Check prerequisites
- Create GitHub labels
- Show next steps

### Step 2: Add API Key Secret (for GitHub Actions)

The GitHub Actions workflows need an Anthropic API key to run Claude:

```bash
gh secret set ANTHROPIC_API_KEY
# Paste your API key when prompted
```

**Note**: This is separate from your Claude Code subscription. You can get an API key at https://console.anthropic.com/

### Step 3: Create GitHub Project (Optional)

1. Go to your repo → Projects → New Project
2. Choose "Board" template
3. Note the project number (shown in URL)

### Step 4: Install Claude GitHub App (Optional)

For `@claude` mentions to work on GitHub.com:
https://github.com/apps/claude

## How It Works

### A. Bootstrap from Spec

Write a `spec.md` file describing your project:

```markdown
# My Project Spec

## Overview
A web app that does X, Y, Z.

## Features

### User Authentication
- Sign up with email
- OAuth with Google
- Password reset

### Dashboard
- View metrics
- Export data
```

Then create your backlog:

**Option 1: Local (free, uses your subscription)**
```bash
claude "Read spec.md and create GitHub issues"
```

**Option 2: GitHub Actions**
```bash
gh workflow run spec-to-backlog.yml -f spec_path=spec.md
```

### B. Work on Issues

1. **Start**: Comment `@claude /start` on any issue
2. **Review Plan**: Claude posts an implementation plan
3. **Approve**: Comment `@claude /approve`
4. **PR Created**: Claude implements and opens a PR

### C. Automated PR Review

Every PR triggers a 3-pass review:

| Pass | Focus | Model |
|------|-------|-------|
| Fast | Bugs, security, style | Sonnet |
| Deep | Architecture, edge cases | Sonnet |
| Independent | Fresh perspective | Sonnet |

**Finding Categories:**
- **Error**: Must fix (blocks merge)
- **Warning**: Should fix
- **Suggestion**: Nice to have

**Auto-Fix Loop:**
1. If errors found → Claude fixes automatically
2. Review re-runs
3. Max 3 iterations before escalation

### D. Ongoing Work

Create new issues anytime:

```bash
# Via workflow
gh workflow run quick-task.yml -f type=issue -f title="Add logout button" -f priority=medium

# Via comment on any issue
@claude /quick-task: Add dark mode toggle
```

## Day-to-Day Usage

### Starting a New Project

1. Write `spec.md`
2. Run: `claude "Create GitHub issues from spec.md"`
3. Start working on issues with `@claude /start`

### Working on Existing Project

1. Pick an issue from your Project board
2. Comment `@claude /start`
3. Review and approve the plan
4. PR gets created and reviewed automatically

### Quick Tasks

```bash
# Create an epic
@claude /quick-task: Epic - User settings page

# Create a task
@claude /quick-task: Add email validation to signup form
```

### Manual Review

On any PR, comment:
```
@claude review
```

## Configuration

### Repository Variables (optional)

Set in Settings → Secrets and Variables → Variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_REVIEW_ITERATIONS` | 3 | Auto-fix loop limit |

### Repository Secrets (required)

Set in Settings → Secrets and Variables → Secrets:

| Secret | Required | Description |
|--------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | For GitHub Actions |
| `GITHUB_TOKEN` | Auto | Provided by GitHub |

## Workflows Reference

### spec-to-backlog.yml

**Trigger**: `workflow_dispatch`

**Inputs**:
- `spec_path`: Path to spec file (default: `spec.md`)
- `plan_path`: Path to plan file (optional)
- `project_number`: GitHub Project number (default: `1`)
- `dry_run`: Test without creating issues

### claude-handler.yml

**Trigger**: Issue comments

**Commands**:
- `@claude /start` - Begin work
- `@claude /plan` - Create/regenerate plan
- `@claude /approve` - Approve and implement
- `@claude /status` - Check status

### pr-review-loop.yml

**Trigger**: PR open/update, or `@claude review`

**Outputs**:
- Review comment with findings
- Auto-fix commits if errors
- Ready-to-merge label when clean

### quick-task.yml

**Trigger**: `workflow_dispatch` or `@claude /quick-task:`

**Inputs**:
- `type`: `issue` or `epic`
- `title`: Task title
- `description`: Brief description
- `priority`: high/medium/low
- `area`: frontend/backend/etc
- `size`: S/M/L

## Troubleshooting

### "ANTHROPIC_API_KEY not found"

Add your API key:
```bash
gh secret set ANTHROPIC_API_KEY
```

### "gh: command not found"

Install GitHub CLI: https://cli.github.com/

### Review loop keeps running

- Check the `review-iteration-N` label
- Max 3 iterations before escalation
- Remove label to reset: `gh pr edit N --remove-label review-iteration-3`

### Claude not responding to commands

1. Check Claude GitHub App is installed
2. Verify ANTHROPIC_API_KEY secret exists
3. Check workflow run logs: `gh run list`

## Local Development

Use Claude Code locally for free operations:

```bash
# Create issues
claude "Read spec.md and create GitHub issues"

# Plan implementation
claude "Create a plan to implement issue #5"

# Review code
claude "Review the changes in this PR: $(git diff main)"
```

The `.claude/skills.json` file defines available skills.
