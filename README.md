# GitHub Automation Template

**Free GitHub automation using Claude Code - no API costs**

## Use This Template

### Via GitHub (Recommended)

1. Push this to GitHub
2. Mark as template repository (Settings → Template repository)
3. Click "Use this template" for new projects

### Via CLI

```bash
# Create new project from this
cp -r github-automation my-new-project
cd my-new-project
rm -rf .git
git init
```

## What It Does

- ✅ Organized issue templates (Epic & Task)
- ✅ GitHub labels (size, priority, area)
- ✅ Claude Code integration for spec parsing
- ✅ Claude GitHub App for PR reviews
- ✅ $0/month cost

## Quick Start (2 min)

### 1. Copy to your project

```bash
cp -r .github /path/to/your-project/
cd /path/to/your-project
```

### 2. Create labels

```bash
bash .github/scripts/create-labels.sh
```

### 3. Install Claude GitHub App

https://github.com/apps/claude-code

Done!

## Usage

### Create Issues from Spec

In Claude Code:
```
Read my spec.md and generate GitHub CLI commands to create epics and issues
```

Run the commands → issues created!

### Review PRs

Comment on PR:
```
@claude review this PR
```

### Work Normally

Use Claude Code as usual for implementation.

---

**That's it. Simple. Free. Effective.**

See `.github/README.md` for details.
