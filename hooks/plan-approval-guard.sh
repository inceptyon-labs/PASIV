#!/bin/bash
# PASIV PreToolUse hook (matcher: AskUserQuestion) — deny the plan-approval
# question until the plan has actually been displayed in the terminal.
#
# The plan skill pastes the plan into its response and runs
# `kick-state.sh plan-shown`; if it skips that, this deny tells it exactly
# how to recover, so the flow self-corrects instead of asking the user to
# approve a plan they never saw.

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

ASKS_APPROVAL=$(printf '%s' "$INPUT" | jq -r '[.tool_input.questions[]?.question // "" | test("approve this implementation plan"; "i")] | any' 2>/dev/null)
[ "$ASKS_APPROVAL" = "true" ] || exit 0

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
SELF_DIR=$(cd "$(dirname "$0")" && pwd)
KS="$SELF_DIR/../scripts/kick-state.sh"

STATE=$(bash "$KS" status --cwd "${CWD:-$PWD}" 2>/dev/null)
printf '%s\n' "$STATE" | grep -q '^ACTIVE=1$' || exit 0
printf '%s\n' "$STATE" | grep -q '^PLAN_SHOWN=1$' && exit 0

REASON="Denied: the plan has not been displayed to the user. Paste the plan into your response text first — verbatim if short, otherwise the header plus every task's Goal/Files/Acceptance Criteria with a pointer to the saved file. The terminal is the approval surface; the user will not open a file to review a plan. After pasting it, run: bash \"$KS\" plan-shown — then re-ask this question."

jq -n --arg r "$REASON" '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": $r}}'
exit 0
