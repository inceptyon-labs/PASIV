#!/bin/bash
set -euo pipefail

# PASIV token report — per-model token usage for the current session.
# Usage: token-report.sh [identifier]
# Prints a per-model table and appends a JSONL record to docs/metrics/tokens.jsonl.
# Numbers are session-cumulative; per-kick delta = diff of consecutive records
# sharing a session id.

IDENTIFIER="${1:-}"

command -v jq >/dev/null || { echo "token report skipped: jq not found"; exit 0; }

PROJ_DIR="$HOME/.claude/projects/$(pwd | sed 's|[/.]|-|g')"
[ -d "$PROJ_DIR" ] || { echo "token report skipped: no transcript dir at $PROJ_DIR"; exit 0; }

SESSION=$(ls -t "$PROJ_DIR"/*.jsonl 2>/dev/null | head -1)
[ -n "$SESSION" ] || { echo "token report skipped: no session transcript"; exit 0; }
SID=$(basename "$SESSION" .jsonl)

FILES=("$SESSION")
if [ -d "$PROJ_DIR/$SID/subagents" ]; then
  while IFS= read -r f; do FILES+=("$f"); done \
    < <(ls "$PROJ_DIR/$SID/subagents"/agent-*.jsonl 2>/dev/null)
fi

# fromjson? skips the partial last line of a transcript still being written
SUMMARY=$(cat "${FILES[@]}" | jq -Rs '
  [split("\n")[] | fromjson? | select(.message.usage != null)
   | {m: .message.model, u: .message.usage}]
  | group_by(.m)
  | map({model: .[0].m,
         calls: length,
         in:          (map(.u.input_tokens // 0) | add),
         out:         (map(.u.output_tokens // 0) | add),
         cache_read:  (map(.u.cache_read_input_tokens // 0) | add),
         cache_write: (map(.u.cache_creation_input_tokens // 0) | add)})')

echo "Token usage (session ${SID:0:8}, ${#FILES[@]} transcript(s)):"
echo "$SUMMARY" | jq -r '.[] |
  "  \(.model): \(.calls) calls · in \(.in) · out \(.out) · cache-read \(.cache_read) · cache-write \(.cache_write)"'

mkdir -p docs/metrics
jq -cn \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg id "$IDENTIFIER" \
  --arg sid "$SID" \
  --argjson models "$SUMMARY" \
  '{ts: $ts, identifier: $id, session: $sid, models: $models}' \
  >> docs/metrics/tokens.jsonl
echo "  → docs/metrics/tokens.jsonl"
