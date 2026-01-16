#!/bin/bash

set -e

echo "🚀 Installing GitHub Automation System..."
echo ""

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo "⚠️  Bun is not installed."
    echo "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash

    # Source bun
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Install dependencies
echo "📦 Installing dependencies..."
cd "$(dirname "$0")"  # Navigate to scripts directory
bun install

echo ""
echo "✅ Dependencies installed successfully!"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI (gh) not found."
    echo ""
    echo "Please install GitHub CLI from: https://cli.github.com/"
    echo "You'll need it to run workflows and create labels."
    echo ""
    exit 1
fi

# Check if config file exists
if [ ! -f "../automation.config.json" ]; then
    echo "⚠️  Config file not found!"
    echo ""
    echo "Creating .github/automation.config.json from template..."

    cat > "../automation.config.json" <<'EOF'
{
  "project": {
    "name": "My Project",
    "owner": "your-github-username",
    "repo": "your-repo-name",
    "projectNumber": 1
  },
  "labels": {
    "areas": ["frontend", "backend", "infrastructure", "database", "documentation"],
    "priorities": ["high", "medium", "low"],
    "sizes": ["S", "M", "L"]
  },
  "review": {
    "maxAutoFixIterations": 3,
    "fastReviewModel": "claude-sonnet-4.5",
    "deepReviewModel": "claude-opus-4.5"
  },
  "backlog": {
    "defaultSpecPath": "spec.md",
    "defaultPlanPath": "plan.md"
  }
}
EOF

    echo "✅ Config file created!"
    echo "📝 Please edit .github/automation.config.json with your project details"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Edit .github/automation.config.json with your project details"
echo "   - Set your GitHub username/repo name"
echo "   - Update project number after creating GitHub Project"
echo ""
echo "2. Install Claude GitHub App for PR reviews:"
echo "   https://github.com/apps/claude-code"
echo ""
echo "3. Create GitHub labels:"
echo "   bash .github/scripts/create-labels.sh"
echo ""
echo "4. Create GitHub Project (Projects → New Project → Board)"
echo "   - Then update projectNumber in automation.config.json"
echo ""
echo "5. Test the system:"
echo "   gh workflow run spec-to-backlog.yml"
echo ""
echo "📖 For detailed instructions, see .github/SETUP_CHECKLIST.md"
echo ""
