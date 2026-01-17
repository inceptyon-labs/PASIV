#!/bin/bash

set -e

echo "GitHub Automation Setup"
echo "======================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) not found."
    echo ""
    echo "Please install it from: https://cli.github.com/"
    echo "Then run this script again."
    echo ""
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Not authenticated with GitHub CLI."
    echo ""
    echo "Run: gh auth login"
    echo "Then run this script again."
    echo ""
    exit 1
fi

echo "GitHub CLI: OK"
echo ""

# Get repo info
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
    echo "Not in a GitHub repository."
    echo "Make sure you're in a git repo linked to GitHub."
    exit 1
fi

echo "Repository: $REPO"
echo ""

# Create labels
echo "Creating labels..."
bash "$(dirname "$0")/create-labels.sh"
echo ""

# Check for Claude GitHub App
echo "Checking GitHub App setup..."
echo ""
echo "For PR reviews to work, you need the Claude GitHub App installed:"
echo "  https://github.com/apps/claude"
echo ""

# Check for ANTHROPIC_API_KEY secret (needed for GitHub Actions)
echo "Checking repository secrets..."
HAS_SECRET=$(gh secret list 2>/dev/null | grep -c "ANTHROPIC_API_KEY" || echo "0")

if [ "$HAS_SECRET" -eq "0" ]; then
    echo ""
    echo "ANTHROPIC_API_KEY secret not found."
    echo ""
    echo "For GitHub Actions workflows to use Claude, you need to add your API key:"
    echo "  gh secret set ANTHROPIC_API_KEY"
    echo ""
    echo "Note: This is separate from your Claude Code subscription."
    echo "The API key is only used by GitHub Actions workflows."
    echo ""
fi

# Summary
echo ""
echo "Setup Complete!"
echo "==============="
echo ""
echo "What was configured:"
echo "  - GitHub labels for issues"
echo ""
echo "What you can do now:"
echo ""
echo "  LOCAL (uses your Claude Code subscription - FREE):"
echo "    claude 'Read spec.md and create GitHub issues'"
echo "    claude 'Create an epic for user authentication'"
echo ""
echo "  GITHUB ACTIONS (requires ANTHROPIC_API_KEY secret):"
echo "    @claude /start     - Start working on an issue"
echo "    @claude /review    - Review a PR"
echo ""
echo "  WORKFLOWS:"
echo "    gh workflow run spec-to-backlog.yml  - Create issues from spec.md"
echo "    gh workflow run quick-task.yml       - Create single issue/epic"
echo ""
echo "Documentation: See CLAUDE.md and .github/README.md"
echo ""
