#!/bin/bash
# PASIV Stop hook — refuse to end the turn while a /kick is mid-flight.
#
# Stopping is the model's absorbing default state; prose can't prevent an
# omission. This hook converts a premature turn-end back into a continuation
# with an explicit next action. kick-state.sh owns the bookkeeping, including
# the block cap (2 blocks with no progress → stand down) and the abort path.

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
SELF_DIR=$(cd "$(dirname "$0")" && pwd)
KS="$SELF_DIR/../scripts/kick-state.sh"

RESULT=$(bash "$KS" block --cwd "${CWD:-$PWD}" 2>/dev/null) || exit 0

case "$RESULT" in
  *DECISION=block*) ;;
  *) exit 0 ;;
esac

LAST_STEP=$(printf '%s\n' "$RESULT" | sed -n 's/^LAST_STEP=//p')
REMAIN=$(printf '%s\n' "$RESULT" | sed -n 's/^TASKS_REMAINING=//p')

REASON="PASIV kick in flight — the last step-skill invoked was '$LAST_STEP' and $REMAIN task(s) have not reached finish. Do not end the turn. Run TaskList, find the first step task that is not completed, and invoke its Skill now (plan → execute → review → verification → finish). If you need the user's input, ask with the AskUserQuestion tool instead of ending the turn. If the user cancelled or the kick genuinely cannot continue, run: bash \"$KS\" abort — then explain why and stop."

jq -n --arg r "$REASON" '{"decision": "block", "reason": $r}'
exit 0
