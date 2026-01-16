#!/bin/bash

# Script to extract GitHub automation system to a standalone template repository

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GitHub Automation Template Extractor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if destination is provided
if [ -z "$1" ]; then
    echo "Usage: bash extract-to-template.sh <destination-path>"
    echo ""
    echo "Example:"
    echo "  bash extract-to-template.sh ../github-automation-template"
    echo ""
    exit 1
fi

DEST="$1"
SOURCE="$(pwd)"

# Create destination directory
mkdir -p "$DEST"
echo "📁 Creating directory structure in $DEST..."

# Create directory structure
mkdir -p "$DEST/.github/workflows"
mkdir -p "$DEST/.github/scripts/utils"
mkdir -p "$DEST/.github/ISSUE_TEMPLATE"
mkdir -p "$DEST/docs"

# Copy workflows
echo "📄 Copying workflows..."
cp .github/workflows/spec-to-backlog.yml "$DEST/.github/workflows/"
cp .github/workflows/claude-handler.yml "$DEST/.github/workflows/"
cp .github/workflows/pr-review-loop.yml "$DEST/.github/workflows/"
cp .github/workflows/auto-fix.yml "$DEST/.github/workflows/"

# Copy scripts
echo "📄 Copying scripts..."
cp .github/scripts/package.json "$DEST/.github/scripts/"
cp .github/scripts/*.ts "$DEST/.github/scripts/" 2>/dev/null || true
cp .github/scripts/*.sh "$DEST/.github/scripts/"
cp -r .github/scripts/utils "$DEST/.github/scripts/"

# Copy templates
echo "📄 Copying issue templates..."
cp .github/ISSUE_TEMPLATE/*.yml "$DEST/.github/ISSUE_TEMPLATE/"

# Copy documentation
echo "📄 Copying documentation..."
cp .github/AUTOMATION_README.md "$DEST/.github/"
cp .github/SETUP_CHECKLIST.md "$DEST/.github/"
cp .github/QUICK_REFERENCE.md "$DEST/.github/"
cp .github/README.md "$DEST/.github/"
cp docs/GITHUB_AUTOMATION_ARCHITECTURE.md "$DEST/docs/"
cp docs/AUTOMATION_SUMMARY.md "$DEST/docs/"

# Copy examples and config
echo "📄 Copying examples and config..."
cp spec.example.md "$DEST/"
cp AUTOMATION_MANIFEST.md "$DEST/"
cp .github/automation.config.json "$DEST/.github/automation.config.json.example"

# Create template README
echo "📄 Creating template README..."
cat > "$DEST/README.md" <<'EOF'
# GitHub Automation Template

> AI-powered GitHub automation for solo developers: spec to production

Transform how you build software with AI-assisted project management, code reviews, and automated fixes.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🎯 What Is This?

A complete GitHub automation system that:

- ✅ **Generates epics and issues** from spec.md using Claude Opus
- ✅ **Implements features** with `@claude` command assistance
- ✅ **Multi-pass AI code review** (Fast/Deep/Independent)
- ✅ **Auto-fixes bugs** before merge (max 3 iterations)
- ✅ **Integrates with GitHub Projects** for complete visibility

## 🚀 Quick Start

### 1. Use This Template

Click **"Use this template"** → **"Create a new repository"**

### 2. Clone and Install

```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git
cd YOUR-REPO

# Run installer
bash .github/scripts/install.sh
```

### 3. Configure

Edit `.github/automation.config.json`:

```json
{
  "project": {
    "name": "My Awesome Project",
    "owner": "your-github-username",
    "repo": "your-repo-name",
    "projectNumber": 1
  }
}
```

### 4. Setup GitHub

```bash
# Create labels
bash .github/scripts/create-labels.sh
```

**Add secrets** (Settings → Secrets and variables → Actions):
- `ANTHROPIC_API_KEY` - Get from [console.anthropic.com](https://console.anthropic.com)
- `GH_PROJECT_TOKEN` - GitHub PAT with `repo` + `project` scopes

**Create GitHub Project**:
1. Go to Projects → New Project → Board
2. Update `projectNumber` in `automation.config.json`

### 5. Test It

```bash
# Use example spec
gh workflow run spec-to-backlog.yml

# Check results
gh run list
```

## 📖 How It Works

```
1. Write spec.md
   ↓
2. Run: gh workflow run spec-to-backlog.yml
   ↓
3. Claude Opus generates Epics + Issues
   ↓
4. Comment on issue: @claude /start
   ↓
5. Claude creates plan → You approve
   ↓
6. Claude implements → Opens PR
   ↓
7. 3-pass review runs automatically
   ↓
8. Auto-fix errors (or escalate)
   ↓
9. Merge when green ✅
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Quick Start](.github/AUTOMATION_README.md) | Get started in 5 minutes |
| [Setup Checklist](.github/SETUP_CHECKLIST.md) | Step-by-step setup guide |
| [Command Reference](.github/QUICK_REFERENCE.md) | All commands at a glance |
| [Full Architecture](docs/GITHUB_AUTOMATION_ARCHITECTURE.md) | Complete technical documentation |
| [Summary](docs/AUTOMATION_SUMMARY.md) | Executive overview with ROI |

## 💰 Cost & ROI

### Monthly Cost
- **GitHub Actions**: Free tier sufficient (2,000 minutes/month)
- **Anthropic API**: ~$30-40 for active development

### Time Saved
- **Backlog planning**: 2-3 hours → 10 minutes
- **Code review**: 3-4 hours → 30 minutes
- **Bug fixing**: 2-3 hours → 1 hour

**Total**: 6-10 hours saved per week

**ROI**: Pays for itself in the first week

## ✨ Features

### Spec to Backlog
- Parse spec.md with Claude Opus
- Generate properly-sized epics and issues
- Auto-add to GitHub Projects with labels
- Identify spec gaps and questions

### Implementation Assistance
- `@claude /start` - Begin planning
- `@claude /approve` - Start implementation
- Branch + PR creation
- Links back to issues

### Multi-Pass Review
- **Fast Review** (Sonnet): Bugs, style, security
- **Deep Review** (Opus): Architecture, performance
- **Independent Review**: Fresh perspective
- Aggregate findings by severity

### Auto-Fix System
- Automatically fix review errors
- Max 3 iterations (prevents loops)
- Escalate to manual if stuck
- Clear status updates

## 🎯 Use Cases

Perfect for:
- Solo developers
- Side projects
- Startups
- Agencies managing multiple clients

## 🛠️ Technology

- **GitHub Actions** - Workflow automation
- **Claude (Anthropic)** - AI assistance
- **TypeScript + Bun** - Fast scripting
- **Zod** - Schema validation
- **Octokit** - GitHub API

## 📊 What Gets Automated

| Task | Before | After |
|------|--------|-------|
| Backlog creation | 2-3 hours | 10 minutes |
| Issue breakdown | 1-2 hours | 5 minutes |
| Code review | 3-4 hours | 30 minutes |
| Bug fixing | 2-3 hours | 1 hour |

## 🔒 Security

- Minimal permissions (scoped per workflow)
- No force push to main
- Branch protection enforced
- All secrets encrypted in GitHub

## 🤝 Contributing

Contributions welcome! Open an issue or PR.

### Development Setup

```bash
cd .github/scripts
bun install
bun run parse-spec.ts  # Test individual scripts
```

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details

## 🆘 Support

- **Documentation**: See `docs/` directory
- **Issues**: Open a GitHub issue
- **Example**: Check `spec.example.md`

## 🌟 Star This Repo

If this saves you time, give it a star! ⭐

## 🔄 Updates

Check [Releases](../../releases) for updates and changelogs.

To update in an existing project:

```bash
git remote add template https://github.com/YOUR-USERNAME/github-automation-template.git
git fetch template
git checkout template/main -- .github/workflows/
git commit -m "Update automation from template"
```

---

Built with ❤️ for solo developers who want to ship faster
EOF

# Create LICENSE
echo "📄 Creating LICENSE..."
cat > "$DEST/LICENSE" <<'EOF'
MIT License

Copyright (c) 2026 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Create .gitignore
echo "📄 Creating .gitignore..."
cat > "$DEST/.gitignore" <<'EOF'
# Dependencies
node_modules/
.bun/

# Build outputs
dist/
build/

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Environment
.env
.env.local

# GitHub automation specific
.github/automation.config.json
review-*.json
review-findings.json

# Keep example config
!.github/automation.config.json.example
EOF

# Create CHANGELOG
echo "📄 Creating CHANGELOG..."
cat > "$DEST/CHANGELOG.md" <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-16

### Added
- Initial release
- Spec to backlog generation with Claude Opus
- `@claude` command handlers (/start, /approve, /plan)
- Multi-pass PR review system (Fast/Deep/Independent)
- Auto-fix system with iteration limits
- GitHub Projects integration
- Complete documentation suite
- Issue templates (Epic and Task)
- Example spec file
- Installation and setup scripts

### Features
- Parse spec.md into structured epics and issues
- Automatic issue creation and labeling
- AI-powered implementation planning
- Three-pass code review with severity categorization
- Automatic bug fixing (max 3 iterations)
- Configurable via automation.config.json
- Minimal GitHub permissions required

### Documentation
- Complete architecture guide (3,500+ lines)
- Setup checklist
- Quick reference card
- Day-to-day playbook
- Troubleshooting guide

## [Unreleased]

### Planned
- npm package for easier installation
- CLI tool for init/update commands
- Template sync workflow
- Metrics dashboard
- Custom review prompt templates
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Extraction Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Template created at: $DEST"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Navigate to the template:"
echo "   cd $DEST"
echo ""
echo "2. Initialize git repository:"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit: GitHub automation template v1.0.0'"
echo ""
echo "3. Create GitHub repository:"
echo "   gh repo create github-automation-template --public --source=. --remote=origin --push"
echo ""
echo "4. Mark as template repository:"
echo "   - Go to Settings on GitHub"
echo "   - Check 'Template repository'"
echo ""
echo "5. Create first release:"
echo "   git tag -a v1.0.0 -m 'Version 1.0.0'"
echo "   git push --tags"
echo "   gh release create v1.0.0 --title 'v1.0.0 - Initial Release' --notes 'See CHANGELOG.md'"
echo ""
echo "🎉 Your template is ready to use!"
echo ""
