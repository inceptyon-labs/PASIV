#!/bin/bash
# Deterministic .pasiv.yml reader — emits KEY=VALUE lines for kick Step 0.
# Defaults live here; skills consume the output verbatim and never re-derive.
set -euo pipefail
CFG="${1:-.pasiv.yml}"

TASK_BACKEND=local
WORKFLOW_PLAN_APPROVAL=true
WORKFLOW_TDD=true
WORKFLOW_REVIEW=true
WORKFLOW_VERIFICATION=true
WORKFLOW_UI_VERIFY=false
AUTO_REFLECT=false
TOKEN_REPORT=false
VERIFY_COMMAND=""
COORDINATOR_MODEL=""
DESIGN_SYSTEM=""
REVIEW_DEFAULT=standard

if [ -f "$CFG" ]; then
  # get <section> <key>: value of an indented key under a top-level section
  get() { awk -v s="$1" -v k="$2" '
    /^[A-Za-z_]+:/ { sec=$1; sub(":","",sec) }
    sec==s && $1==k":" { sub(/^[^:]*: */,""); gsub(/^"|"$/,""); gsub(/ *#.*$/,""); print; exit }' "$CFG"; }
  # top <key>: value of a top-level scalar
  top() { awk -v k="$1" '
    $0 ~ "^"k":" && NF>1 { sub(/^[^:]*: */,""); gsub(/^"|"$/,""); gsub(/ *#.*$/,""); print; exit }' "$CFG"; }

  v=$(top task_backend);            [ -n "$v" ] && TASK_BACKEND=$v
  v=$(get workflow plan_approval);  [ -n "$v" ] && WORKFLOW_PLAN_APPROVAL=$v
  v=$(get workflow tdd);            [ -n "$v" ] && WORKFLOW_TDD=$v
  v=$(get workflow review);         [ -n "$v" ] && WORKFLOW_REVIEW=$v
  v=$(get workflow verification);   [ -n "$v" ] && WORKFLOW_VERIFICATION=$v
  v=$(get workflow ui_verify);      [ -n "$v" ] && WORKFLOW_UI_VERIFY=$v
  v=$(get workflow auto_reflect);   [ -n "$v" ] && AUTO_REFLECT=$v
  v=$(get metrics tokens);          [ -n "$v" ] && TOKEN_REPORT=$v
  v=$(get verify command);          [ -n "$v" ] && VERIFY_COMMAND=$v
  v=$(get models coordinator);      [ -n "$v" ] && COORDINATOR_MODEL=$v
  v=$(get design system);           [ -n "$v" ] && DESIGN_SYSTEM=$v
  v=$(get review default);          [ -n "$v" ] && REVIEW_DEFAULT=$v
fi

cat <<EOF
TASK_BACKEND=$TASK_BACKEND
WORKFLOW_PLAN_APPROVAL=$WORKFLOW_PLAN_APPROVAL
WORKFLOW_TDD=$WORKFLOW_TDD
WORKFLOW_REVIEW=$WORKFLOW_REVIEW
WORKFLOW_VERIFICATION=$WORKFLOW_VERIFICATION
WORKFLOW_UI_VERIFY=$WORKFLOW_UI_VERIFY
AUTO_REFLECT=$AUTO_REFLECT
TOKEN_REPORT=$TOKEN_REPORT
VERIFY_COMMAND=$VERIFY_COMMAND
COORDINATOR_MODEL=$COORDINATOR_MODEL
DESIGN_SYSTEM=$DESIGN_SYSTEM
REVIEW_DEFAULT=$REVIEW_DEFAULT
EOF
