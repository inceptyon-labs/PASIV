#!/bin/bash
# PASIV UserPromptSubmit hook — deterministic step-skill enforcement.
# When a /kick (or /review) fires, inject a hard rule so the coordinator
# invokes the step-skills instead of improvising the workflow inline.
# /kick additionally arms the kick state machine (scripts/kick-state.sh):
# from there a Stop hook bounces any attempt to end the turn before finish.

INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null)

case "$PROMPT" in
  /kick*|/pasiv:kick*)
    CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
    SELF_DIR=$(cd "$(dirname "$0")" && pwd)
    bash "$SELF_DIR/../scripts/kick-state.sh" init --cwd "${CWD:-$PWD}" >/dev/null 2>&1
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "[PASIV enforcement — not advisory] Every workflow step MUST run through its Skill: plan → execute → review → verification → finish. NEVER perform a step's work inline instead of invoking its skill — no hand-rolled merges, test runs, task closes, or wrap-up reports. Git operations go through git-ops, tests through test-runner, task CRUD through task-ops. The step-skills carry the model routing (Haiku/Sonnet workers) and the opt-ins (token report, auto-reflect, parent cascade); bypassing them silently drops all of it. If a skill fails to load, STOP and say so. TURN DISCIPLINE: the entire /kick is ONE continuous turn. A step's '>>> … COMPLETE <<<' marker is a mid-turn progress line, NOT a sign-off — the moment it prints, invoke the next step's skill in the same turn. Never end the turn before finish's report; a Stop hook bounces premature stops. Mid-kick questions to the user go through the AskUserQuestion tool, never by ending the turn. PLAN APPROVAL: the approval question may only fire after the plan text has been pasted into your response — the user reviews plans in the terminal, never by opening a file."
  }
}
EOF
    ;;
  /review*|/pasiv:review*)
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "[PASIV enforcement — not advisory] Every workflow step MUST run through its Skill: plan → execute → review → verification → finish. NEVER perform a step's work inline instead of invoking its skill — no hand-rolled merges, test runs, task closes, or wrap-up reports. Git operations go through git-ops, tests through test-runner, task CRUD through task-ops. The step-skills carry the model routing (Haiku/Sonnet workers) and the opt-ins (token report, auto-reflect, parent cascade); bypassing them silently drops all of it. If a skill fails to load, STOP and say so."
  }
}
EOF
    ;;
esac
exit 0
