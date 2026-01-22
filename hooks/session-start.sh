#!/bin/bash
set -euo pipefail

# Find the plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# Read the using-pasiv skill content
SKILL_CONTENT=$(cat "$PLUGIN_ROOT/skills/using-pasiv/SKILL.md" 2>/dev/null || echo "")

# Escape for JSON
escape_json() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

ESCAPED_CONTENT=$(escape_json "$SKILL_CONTENT")

# Output JSON for Claude Code hook system
cat <<EOF
{
  "hookName": "SessionStart",
  "additionalContext": "EXTREMELY_IMPORTANT",
  "content": "$ESCAPED_CONTENT"
}
EOF

exit 0
