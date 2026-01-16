#!/bin/bash

# Script to create all required labels for the GitHub automation system

set -e

echo "Creating GitHub labels..."

# Epic and type labels
gh label create "epic" --color "8B5CF6" --description "High-level feature grouping" --force
gh label create "enhancement" --color "84CC16" --description "New feature or improvement" --force
gh label create "bug" --color "EF4444" --description "Something isn't working" --force
gh label create "documentation" --color "06B6D4" --description "Documentation changes" --force

# Priority labels
gh label create "priority: high" --color "DC2626" --description "Critical priority" --force
gh label create "priority: medium" --color "F59E0B" --description "Medium priority" --force
gh label create "priority: low" --color "10B981" --description "Low priority" --force

# Size labels
gh label create "size: S" --color "DBEAFE" --description "Small task (1-4 hours)" --force
gh label create "size: M" --color "BFDBFE" --description "Medium task (4-8 hours)" --force
gh label create "size: L" --color "93C5FD" --description "Large task (8+ hours)" --force

# Status labels
gh label create "status: planning" --color "E5E7EB" --description "Planning in progress" --force
gh label create "status: in-progress" --color "FBBF24" --description "Work in progress" --force
gh label create "status: review-needed" --color "A78BFA" --description "Needs code review" --force
gh label create "status: auto-fixing" --color "FB923C" --description "Claude auto-fixing issues" --force
gh label create "status: ready-to-merge" --color "34D399" --description "Approved and ready" --force
gh label create "needs-manual-fix" --color "DC2626" --description "Auto-fix failed, needs manual intervention" --force

# Area labels
gh label create "area: frontend" --color "EC4899" --description "Web/React changes" --force
gh label create "area: backend" --color "8B5CF6" --description "API/Hono changes" --force
gh label create "area: infra" --color "6B7280" --description "DevOps/CI/CD" --force
gh label create "area: db" --color "3B82F6" --description "Database schema/queries" --force

echo "✅ All labels created successfully!"
echo ""
echo "Next steps:"
echo "1. Create a GitHub Project (Projects → New Project → Board)"
echo "2. Update PROJECT_NUMBER in .github/workflows/spec-to-backlog.yml"
echo "3. Add secrets: ANTHROPIC_API_KEY and GH_PROJECT_TOKEN"
echo "4. Create spec.md and run: gh workflow run spec-to-backlog.yml"
