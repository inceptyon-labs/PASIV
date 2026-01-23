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
# SessionStart hooks use systemMessage, not hookSpecificOutput
cat <<EOF
{
  "systemMessage": "[PASIV SessionStart Hook]\n\n<EXTREMELY_IMPORTANT>\nYou have PASIV installed.\n\n**Below is the full content of your 'pasiv:using-pasiv' skill. For all other skills, use the Skill tool:**\n\n$ESCAPED_CONTENT\n</EXTREMELY_IMPORTANT>"
}
EOF

exit 0
