#!/bin/bash
# PASIV UserPromptSubmit hook — deterministic step-skill enforcement.
# When a /kick (or /review) fires, inject a hard rule so the coordinator
# invokes the step-skills instead of improvising the workflow inline.

INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null)

case "$PROMPT" in
  /kick*|/pasiv:kick*|/review*|/pasiv:review*)
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
