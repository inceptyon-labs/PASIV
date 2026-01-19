#!/bin/bash

# Script to create all required labels for PASIV

set -e

echo "Creating PASIV labels..."

# Type labels
gh label create "enhancement" --color "84CC16" --description "New feature or improvement" --force
gh label create "bug" --color "EF4444" --description "Something isn't working" --force
gh label create "documentation" --color "06B6D4" --description "Documentation changes" --force

# Priority labels (no spaces - matches skill expectations)
gh label create "priority:high" --color "DC2626" --description "Critical priority" --force
gh label create "priority:medium" --color "F59E0B" --description "Medium priority" --force
gh label create "priority:low" --color "10B981" --description "Low priority" --force

# Size labels (no spaces - matches skill expectations)
gh label create "size:S" --color "DBEAFE" --description "Small task (1-4 hours)" --force
gh label create "size:M" --color "BFDBFE" --description "Medium task (4-8 hours)" --force
gh label create "size:L" --color "93C5FD" --description "Large task (8+ hours)" --force

# Area labels (no spaces - matches skill expectations)
gh label create "area:frontend" --color "EC4899" --description "Web/UI changes" --force
gh label create "area:backend" --color "8B5CF6" --description "API/server changes" --force
gh label create "area:infra" --color "6B7280" --description "DevOps/CI/CD" --force
gh label create "area:db" --color "3B82F6" --description "Database schema/queries" --force

# PASIV internal label (to distinguish from user-opened issues)
gh label create "pasiv" --color "1a1a2e" --description "Created by PASIV automation" --force

echo "✅ All labels created successfully!"
echo ""
echo "Issues created by PASIV will be tagged with the 'pasiv' label."
