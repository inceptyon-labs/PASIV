#!/bin/bash
# PASIV PostToolUse hook (matcher: Skill) — advance the kick state machine
# whenever a step-skill is invoked. Deterministic: the skill invocation IS
# the progress signal; no prose obligation on the model. No-op unless a
# kick armed the state (kick-guard.sh).

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

SKILL=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // ""' 2>/dev/null)
STEP="${SKILL##*:}"

case "$STEP" in
  plan|execute|review|verification|finish)
    CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
    SELF_DIR=$(cd "$(dirname "$0")" && pwd)
    bash "$SELF_DIR/../scripts/kick-state.sh" step "$STEP" --cwd "${CWD:-$PWD}" >/dev/null 2>&1
    ;;
esac
exit 0
