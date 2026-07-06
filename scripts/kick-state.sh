#!/bin/bash
# PASIV kick state — deterministic turn-discipline state for /kick.
#
# The coordinator model cannot be trusted to keep its turn alive between
# step-skills (prose instructions demonstrably don't hold), so the state
# lives here and hooks enforce it:
#   - kick-guard.sh   (UserPromptSubmit)  arms the machine on /kick
#   - post-skill.sh   (PostToolUse:Skill) advances it on every step-skill call
#   - stop-guard.sh   (Stop)              bounces turn-ends while it's armed
#   - plan-approval-guard.sh (PreToolUse) checks PLAN_SHOWN before approval
# Skills call set-tasks / plan-shown / abort directly.
#
# One state file per project directory (keyed by cwd hash) — a second
# concurrent session in the same project shares it; the block cap keeps
# that from ever wedging a turn.
#
# Usage: kick-state.sh <init|set-tasks N|step NAME|plan-shown|block|abort|status> [--cwd DIR]

set -u

CMD="${1:-status}"
[ $# -gt 0 ] && shift

ARG=""
DIR="$PWD"
while [ $# -gt 0 ]; do
  if [ "$1" = "--cwd" ]; then
    DIR="${2:-$PWD}"
    shift
    [ $# -gt 0 ] && shift
  else
    ARG="$1"
    shift
  fi
done

KEY=$(printf '%s' "$DIR" | cksum | awk '{print $1}')
STATE="/tmp/pasiv-kick-$KEY.state"

ACTIVE=0; TASKS_REMAINING=1; LAST_STEP=start; PLAN_SHOWN=0; BLOCK_COUNT=0; BLOCKED_AT=none
[ -f "$STATE" ] && . "$STATE"

write_state() {
  cat > "$STATE" <<EOF
ACTIVE=$ACTIVE
TASKS_REMAINING=$TASKS_REMAINING
LAST_STEP=$LAST_STEP
PLAN_SHOWN=$PLAN_SHOWN
BLOCK_COUNT=$BLOCK_COUNT
BLOCKED_AT=$BLOCKED_AT
EOF
}

case "$CMD" in
  init)
    ACTIVE=1; TASKS_REMAINING=1; LAST_STEP=start; PLAN_SHOWN=0; BLOCK_COUNT=0; BLOCKED_AT=none
    write_state
    echo "kick state: armed ($STATE)"
    ;;
  set-tasks)
    TASKS_REMAINING="${ARG:-1}"
    write_state
    echo "kick state: $TASKS_REMAINING task(s) queued"
    ;;
  step)
    [ "$ACTIVE" = "1" ] || exit 0
    LAST_STEP="${ARG:-unknown}"
    BLOCK_COUNT=0; BLOCKED_AT=none
    [ "$LAST_STEP" = "plan" ] && PLAN_SHOWN=0
    if [ "$LAST_STEP" = "finish" ]; then
      TASKS_REMAINING=$((TASKS_REMAINING - 1))
      [ "$TASKS_REMAINING" -le 0 ] && ACTIVE=0
    fi
    write_state
    ;;
  plan-shown)
    PLAN_SHOWN=1
    write_state
    echo "kick state: plan marked as displayed"
    ;;
  block)
    # Stop-hook bookkeeping. Prints DECISION=block|allow (+ context on block).
    # Cap: two blocks with no step progress in between → stand down (ACTIVE=0)
    # so a wedged or abandoned kick can never trap the session.
    if [ "$ACTIVE" != "1" ]; then
      echo "DECISION=allow"
      exit 0
    fi
    # Stale-state TTL: every step advance rewrites the file, so a state file
    # untouched for 6h is an abandoned kick (interrupted session, closed
    # terminal) — disarm instead of bouncing an unrelated future turn.
    MTIME=$(stat -f %m "$STATE" 2>/dev/null || stat -c %Y "$STATE" 2>/dev/null || echo 0)
    if [ "$MTIME" -gt 0 ] && [ $(( $(date +%s) - MTIME )) -gt 21600 ]; then
      ACTIVE=0
      write_state
      echo "DECISION=allow"
      exit 0
    fi
    if [ "$BLOCKED_AT" = "$LAST_STEP" ]; then
      BLOCK_COUNT=$((BLOCK_COUNT + 1))
    else
      BLOCK_COUNT=1
      BLOCKED_AT="$LAST_STEP"
    fi
    if [ "$BLOCK_COUNT" -gt 2 ]; then
      ACTIVE=0
      write_state
      echo "DECISION=allow"
      exit 0
    fi
    write_state
    echo "DECISION=block"
    echo "LAST_STEP=$LAST_STEP"
    echo "TASKS_REMAINING=$TASKS_REMAINING"
    ;;
  abort)
    ACTIVE=0
    write_state
    echo "kick state: aborted"
    ;;
  status)
    [ -f "$STATE" ] && cat "$STATE" || echo "no state"
    ;;
  *)
    echo "unknown command: $CMD" >&2
    exit 1
    ;;
esac
exit 0
