---
name: kick
description: Full implementation flow - plan, implement, review, merge. Use when user says "kick issue", "kick #42", "work on issue", "implement issue", or wants to fully implement and merge a GitHub issue. Named after the "kick" in Inception that brings you from dream to reality.
model: opus
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Skill
  - mcp__my-codex-mcp__codex
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
---

# Kick Issue Into Reality

Full flow for: $ARGUMENTS (issue number or "next")

## Issue Type Hierarchy

| Level | Type | Scope | `/kick` Behavior |
|-------|------|-------|------------------|
| **Epic** | Strategic | Multiple features | Process all Features → all Tasks |
| **Feature** | Tactical | Single capability | Process all Tasks |
| **Task** | Execution | Single work item | Implement → Review → Merge |

**Reviews always happen at the Task level** - that's where code is written and reviewed.

**Helper skills (run with Haiku in forked context for efficiency):**
- `issue-ops` - Issue operations (get, create, close, check-off)
- `project-ops` - Project operations (setup, move status)
- `git-ops` - Git operations (branch, commit, push, merge)

**Methodology skills (referenced inline):**
- `tdd` - Test-Driven Development cycle
- `verification` - Pre-completion verification gate
- `systematic-debugging` - Root cause debugging

---

## Step 0: Get Issue Details

**Use Skill tool:** `issue-ops` with args: `get $ISSUE_NUM`

If argument is "next", first find highest priority open issue:
```bash
ISSUE_NUM=$(gh issue list --label "priority:high" --state open --limit 1 --json number -q '.[0].number')
[ -z "$ISSUE_NUM" ] && ISSUE_NUM=$(gh issue list --state open --limit 1 --json number -q '.[0].number')
```

Store: ISSUE_NUM, ISSUE_TITLE, ISSUE_URL, ISSUE_BODY, ISSUE_LABELS

---

## Step 0.5: Check for Sub-Issues

**Use Skill tool:** `issue-ops` with args: `get-sub-issues $OWNER $REPO $ISSUE_NUM`

**If no sub-issues:** Continue with normal flow (Step 1).

**If sub-issues exist:** Follow [Parent Issue Flow](#parent-issue-flow-autonomous).

---

## Step 1: Confirm Working Issue

Display: "Working on Issue #$ISSUE_NUM: $ISSUE_TITLE"

---

## Step 1.5: Move to In Progress

**Use Skill tool:** `project-ops` with args: `setup` → get PROJECT_NUM, PROJECT_ID

**Use Skill tool:** `project-ops` with args: `move-to-in-progress $PROJECT_ID $PROJECT_NUM $OWNER $ISSUE_URL`

### Cascade to Parent (if sub-issue)

**Use Skill tool:** `issue-ops` with args: `get-parent $OWNER $REPO $ISSUE_NUM`

If parent exists:
- Store PARENT_NUM for later use
- Move parent to In Progress

---

## Step 1.75: Load Sibling Context (if has parent)

If this Task has a parent (PARENT_NUM exists), load context from completed sibling Tasks:

**Use Skill tool:** `issue-ops` with args: `get-sibling-context $OWNER $REPO $PARENT_NUM`

This returns completion summaries from closed sibling Tasks containing:
- Files they changed
- Key decisions made
- Notes for subsequent tasks

**Use this context when planning** - it helps understand:
- What code already exists from previous Tasks
- Patterns and conventions established
- Dependencies and APIs available

If no parent or no closed siblings, skip this step.

---

## Step 2: Create Plan + Select Review Depth

Analyze the issue and codebase. Present:

- **Summary**: What we're building
- **Files to modify**: With expected changes
- **New files**: If any
- **Tests to add**: What tests will verify this works
- **Approach**: Step-by-step
- **Risks**: Potential issues

### Review Tiers

| Tier | Name | Models | Cost | When to Use |
|------|------|--------|------|-------------|
| 1 | S | Sonnet | $ | Typos, config, trivial fixes |
| 2 | O | Opus | $$ | Simple features, clear scope |
| 3 | SC | Sonnet → Codex | $$ | Moderate changes, budget-conscious |
| 4 | OC | Opus → Codex | $$$ | Complex features, quality focus |
| 5 | SOC | Sonnet → Opus → Codex | $$$$ | Security-critical, large refactors |

All multi-pass reviews are **cascading** - each pass reviews cumulative changes including previous fixes.

### Determine Review Tier Recommendation

Check planned files for security patterns:
```bash
SECURITY_PATTERNS="auth|crypto|password|payment|token|secret|credential|session|login|oauth|jwt|apikey|private|key"
```

**Recommendation logic:**
```
IF any planned files match SECURITY_PATTERNS:
  IF size:XS → O + note "[security]"
  IF size:S  → SC + note "[security]"
  IF size:M  → OC + note "[security]"
  IF size:L  → SOC + note "[security]"
  IF size:XL → SOC + note "[security]"
  ELSE       → OC + note "[security]"
ELSE (no security files):
  IF size:XS → S
  IF size:S  → O
  IF size:M  → SC
  IF size:L  → OC
  IF size:XL → SOC
  ELSE       → SC (default)
```

### Ask for Approval + Review Tier

**Use AskUserQuestion tool** with TWO questions:

**Question 1**: "Approve this implementation plan?"
- Approve - Continue to implementation
- Revise - Modify the plan
- Cancel - Stop work on this issue

**Question 2**: "What review tier for this change?"
- S (Sonnet) - trivial changes {add "(Recommended)" if matches}
- O (Opus) - simple features {add "(Recommended)" if matches}
- SC (Sonnet → Codex) - moderate, budget {add "(Recommended)" if matches}
- OC (Opus → Codex) - complex, quality {add "(Recommended)" or "[security]" if applicable}
- SOC (Sonnet → Opus → Codex) - security-critical {add "(Recommended)" or "[security]" if applicable}

**Store**: REVIEW_TIER = "S" | "O" | "SC" | "OC" | "SOC"

**If Approve**: Continue to Step 2.5 (Create Tasks)
**If Revise**: Ask what to change, update plan, ask again
**If Cancel**: Stop and explain why

---

## Step 2.5: Create Native Tasks from Plan

**REQUIRED:** Create native tasks to track progress throughout implementation.

### Create Implementation Tasks

For each step in the approved plan:

```
TaskCreate:
  subject: "Step N: [Component Name]"
  description: |
    [Details from plan]

    Files: [files to create/modify]

    Acceptance Criteria:
    - [ ] Test exists and fails initially
    - [ ] Implementation passes test
    - [ ] Committed with descriptive message
  activeForm: "Implementing [Component Name]"
```

### Create Review Task

```
TaskCreate:
  subject: "Review: [REVIEW_TIER]"
  description: "Run [REVIEW_TIER] review pipeline on all changes"
  activeForm: "Running [REVIEW_TIER] review"
```

### Create Verification Task

```
TaskCreate:
  subject: "Verification Gate"
  description: "Run tests, build, lint - fresh evidence required"
  activeForm: "Verifying implementation"
```

### Set Up Dependencies

```
TaskUpdate:
  taskId: [step-2-id]
  addBlockedBy: [step-1-id]

TaskUpdate:
  taskId: [review-task-id]
  addBlockedBy: [all-step-ids]

TaskUpdate:
  taskId: [verification-task-id]
  addBlockedBy: [review-task-id]
```

### Display Task Structure

Run `TaskList` to show the complete structure before starting implementation.

---

## Step 3: Implement (TDD)

**Use Skill tool:** `git-ops` with args: `create-branch $ISSUE_NUM`

### For each implementation step:

**Start of step:**
```
TaskUpdate:
  taskId: [current-step-id]
  status: in_progress
```

### For each piece of functionality, follow TDD:

#### RED Phase
1. Write ONE minimal failing test
2. Run tests - must FAIL:
```bash
npm test || pytest || go test ./... || cargo test || bun test
```
3. Verify: Test fails because feature doesn't exist (not syntax/import error)

#### GREEN Phase
1. Write the SIMPLEST code to make test pass
2. Run tests - must PASS:
```bash
npm test || pytest || go test ./... || cargo test || bun test
```
3. Verify: New test passes, no other tests broken

#### REFACTOR Phase
1. Clean up if needed (remove duplication, improve names)
2. Run tests after each change - must stay GREEN

#### COMMIT
After each RED-GREEN-REFACTOR cycle:
**Use Skill tool:** `git-ops` with args: `commit "feat: [what was added] (#$ISSUE_NUM)"`

**End of step (after all cycles for this step):**
```
TaskUpdate:
  taskId: [current-step-id]
  status: completed
```

Run `TaskList` to show progress.

### TDD Violations - STOP

If you find yourself:
- Writing code before tests → Delete code, write test first
- Test passes immediately → Test doesn't test what you think, rewrite
- Adding features beyond the test → Remove extras, stay minimal

**Reference**: `@tdd` skill for full methodology

**Repeat TDD cycle** for each acceptance criterion until all are covered.

---

## Step 3.25: Format & Lint

**Run formatters first, then linters.**

Detect and run appropriate formatters/linters for the project.

If changes made:
**Use Skill tool:** `git-ops` with args: `commit "style: format and lint"`

---

## Step 3.5: Run Tests

**Tests must pass before review.**

```bash
npm test || pytest || go test ./... || cargo test || bun test
```

### If tests fail - Use Systematic Debugging

**Do NOT guess at fixes.** Follow root cause analysis:

1. **Read** the full error output - exact message, stack trace, file:line
2. **Reproduce** consistently - run the specific failing test
3. **Hypothesize** - form a SPECIFIC theory ("X fails because Y")
4. **Test** - make ONE minimal change
5. **Verify** - run tests again

```bash
# After each fix attempt
npm test || pytest || go test ./... || cargo test || bun test
```

### Three Strikes Rule

**If 3 independent fix attempts fail: STOP**

The failure may indicate deeper design issues. Report to user:
```
Tests failing after 3 fix attempts.

Attempts:
1. [hypothesis] → [result]
2. [hypothesis] → [result]
3. [hypothesis] → [result]

Options:
- Debug together - Help me investigate
- Skip review - Merge anyway (not recommended)
- Stop - I'll handle manually
```

After successful fix:
**Use Skill tool:** `git-ops` with args: `commit "fix: [root cause description]"`

**Reference**: `@systematic-debugging` skill for full methodology

**Do not proceed to review until tests pass.**

---

## Step 4: Code Review (based on REVIEW_TIER)

**Start of review:**
```
TaskUpdate:
  taskId: [review-task-id]
  status: in_progress
```

All multi-pass reviews are **cascading** - get fresh `git diff main` before each pass to include previous fixes.

---

### If REVIEW_TIER = "S" (Sonnet only)

Perform quick review focusing on:
- Clear bugs and errors
- Security basics (XSS, injection, auth flaws)
- Missing error handling
- Test coverage gaps

Output format:
```
### Review: S (Sonnet)
- [ERROR] file:line - description
- [WARNING] file:line - description
```

**If any ERRORs:**
1. Fix each error (use TDD - write test first if missing)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Sonnet review findings"`

Proceed to Step 5.

---

### If REVIEW_TIER = "O" (Opus only)

Perform thorough single-pass review:
- Architecture and design patterns
- Edge cases and error scenarios
- Performance implications
- Security in depth
- Test coverage quality

Output format:
```
### Review: O (Opus)
- [ERROR] file:line - description
- [WARNING] file:line - description
```

**If any ERRORs:**
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Opus review findings"`

Proceed to Step 5.

---

### If REVIEW_TIER = "SC" (Sonnet → Codex)

**Flow: Sonnet → FIX → Codex → FIX → Done**

#### Pass 1: Sonnet
Get diff: `git diff main`

Quick scan for bugs, security basics, missing error handling, missing tests.

**STOP after Pass 1.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Sonnet review findings"`
3. Then proceed to Pass 2

#### Pass 2: Codex
Get fresh diff (includes Pass 1 fixes): `git diff main`

Use `mcp__my-codex-mcp__codex` tool with:
- `prompt`: "Independent code review. Focus on: 1) Things Sonnet missed, 2) Subtle bugs, 3) Security edge cases, 4) Test gaps. Categorize as ERROR/WARNING/SUGGESTION."
- `code`: The diff output
- `context`: "Pass 2 of SC review. Looking for issues Sonnet missed."

**STOP after Pass 2.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Codex review findings"`

Proceed to Step 5.

---

### If REVIEW_TIER = "OC" (Opus → Codex)

**Flow: Opus → FIX → Codex → FIX → Done**

#### Pass 1: Opus
Get diff: `git diff main`

Deep review: architecture, edge cases, performance, maintainability, test coverage quality.

**STOP after Pass 1.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Opus review findings"`
3. Then proceed to Pass 2

#### Pass 2: Codex
Get fresh diff (includes Pass 1 fixes): `git diff main`

Use `mcp__my-codex-mcp__codex` tool with:
- `prompt`: "Independent code review. Focus on: 1) Things Opus missed, 2) Subtle bugs, 3) Security edge cases, 4) Test gaps. Categorize as ERROR/WARNING/SUGGESTION."
- `code`: The diff output
- `context`: "Pass 2 of OC review. Looking for issues Opus missed."

**STOP after Pass 2.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Codex review findings"`

Proceed to Step 5.

---

### If REVIEW_TIER = "SOC" (Sonnet → Opus → Codex)

**Flow: Sonnet → FIX → Opus → FIX → Codex → FIX → Done**

#### Pass 1: Sonnet
Get diff: `git diff main`

Quick scan for bugs, security basics, missing error handling, missing tests.

**STOP after Pass 1.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Sonnet review findings"`
3. Then proceed to Pass 2

#### Pass 2: Opus
Get fresh diff (includes Pass 1 fixes): `git diff main`

Deep review: architecture, edge cases, performance, maintainability, test coverage quality.

**STOP after Pass 2.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Opus review findings"`
3. Then proceed to Pass 3

#### Pass 3: Codex
Get fresh diff (includes Pass 1 + Pass 2 fixes): `git diff main`

Use `mcp__my-codex-mcp__codex` tool with:
- `prompt`: "Independent code review - catch what others missed. Focus on: 1) Things Sonnet and Opus missed, 2) Subtle bugs, 3) Security edge cases, 4) Test gaps. Categorize as ERROR/WARNING/SUGGESTION."
- `code`: The diff output
- `context`: "Pass 3 of SOC review. Looking for issues Sonnet and Opus missed."

**STOP after Pass 3.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Codex review findings"`

Proceed to Step 5.

---

## Step 5: Check Off Acceptance Criteria

**Mark review complete:**
```
TaskUpdate:
  taskId: [review-task-id]
  status: completed
```

**Use Skill tool:** `issue-ops` with args: `check-off-criteria $ISSUE_NUM`

---

## Step 6: Verification Gate

**Start verification:**
```
TaskUpdate:
  taskId: [verification-task-id]
  status: in_progress
```

**Before merge, verify ALL with fresh runs.**

Run each and check output:

```bash
# 1. Tests pass
npm test || pytest || go test ./... || cargo test

# 2. Build succeeds (if applicable)
npm run build || go build ./... || cargo build

# 3. Lint clean (if configured)
npm run lint || golangci-lint run || cargo clippy

# 4. Type check (if applicable)
npm run typecheck || tsc --noEmit
```

**For each command:**
1. Run it fresh (don't rely on earlier results)
2. Check exit code is 0
3. Review output for warnings

**Report:**
```
## Verification Gate

Tests:     ✓ [count] passed (exit 0)
Build:     ✓ completed (exit 0)
Lint:      ✓ no errors (exit 0)

Ready to merge.
```

**If any fail:**
1. Fix the issue (use systematic debugging if tests)
2. Re-run verification
3. Only proceed when ALL pass

**Reference**: `@verification` skill for methodology

**Mark verification complete:**
```
TaskUpdate:
  taskId: [verification-task-id]
  status: completed
```

Run `TaskList` to show all tasks completed.

---

## Step 6.5: Add Completion Summary (if has parent)

If this Task has a parent (PARENT_NUM exists), add a completion summary for sibling context:

**Use Skill tool:** `issue-ops` with args: `add-completion-summary $ISSUE_NUM "$FILES" "$DECISIONS" "$NOTES"`

Where:
- **FILES**: List of files created/modified (from git diff)
- **DECISIONS**: Key technical decisions made during implementation
- **NOTES**: Helpful context for the next Task (APIs created, patterns used, gotchas)

Example:
```
Files changed:
- src/auth/jwt.ts (new)
- src/middleware/requireAuth.ts (new)
- src/types/auth.ts (modified)

Key decisions:
- Used RS256 for JWT signing (more secure than HS256)
- Tokens expire in 1 hour, refresh tokens in 7 days
- Stored refresh tokens in Redis for revocation support

Notes for next task:
- Use `requireAuth()` middleware for protected routes
- Access user via `req.user` after auth
- Token refresh endpoint is POST /auth/refresh
```

This helps subsequent Tasks in the same Feature understand what was done.

---

## Step 7: Merge

**Use Skill tool:** `git-ops` with args: `merge-to-main`

**Use Skill tool:** `issue-ops` with args: `close $ISSUE_NUM "Completed in $(git rev-parse --short HEAD)"`

---

## Step 8: Move to Done

**Use Skill tool:** `project-ops` with args: `move-to-done $PROJECT_ID $PROJECT_NUM $OWNER $ISSUE_URL`

### Cascade to Parent (if all sub-issues done)

If this issue has a parent:
1. **Use Skill tool:** `issue-ops` with args: `get-sub-issues $OWNER $REPO $PARENT_NUM`
2. If all sub-issues closed:
   - **Use Skill tool:** `issue-ops` with args: `check-off-criteria $PARENT_NUM`
   - **Use Skill tool:** `project-ops` with args: `move-to-done ... $PARENT_URL`
   - **Use Skill tool:** `issue-ops` with args: `close $PARENT_NUM "All sub-issues completed"`

---

## Done

### Find Next Issue

```bash
# Find next priority issue
NEXT_ISSUE=$(gh issue list --label "priority:high" --state open --limit 1 --json number,title -q '.[0] | "#\(.number) \(.title)"')
[ -z "$NEXT_ISSUE" ] && NEXT_ISSUE=$(gh issue list --state open --limit 1 --json number,title -q '.[0] | "#\(.number) \(.title)"')
```

### Report

```
## Done

Issue #$ISSUE_NUM completed and merged to main.

Methodology: TDD (test-first)
Review: [S/O/SC/OC/SOC]
Verification: ✓ All checks passed

Commit: [short SHA]

---
**Next up:** $NEXT_ISSUE (or "No open issues remaining")
Run `/kick next` to continue.
```

---

## Parent Issue Flow (Autonomous)

When `/kick` is called on an Epic or Feature (issue with sub-issues), use "approve once, walk away" mode.

**Key principle:** Reviews happen at the **Task level only**. Epics and Features are containers - no code is written directly in them.

### Flatten the Hierarchy to Tasks

Recursively collect ALL Tasks under this issue:

```
FUNCTION collect_tasks(issue_num):
  sub_issues = get_sub_issues(issue_num)
  tasks = []

  FOR each sub_issue:
    sub_sub_issues = get_sub_issues(sub_issue.number)
    IF sub_sub_issues is empty:
      # This is a Task (leaf node)
      tasks.append(sub_issue)
    ELSE:
      # This is a Feature/Epic (has children) - recurse
      tasks.extend(collect_tasks(sub_issue.number))

  RETURN tasks
```

### Determine Review Tier for Each Task

```
FOR each task:
  Get labels and estimate planned files
  IF likely touches security patterns (auth, crypto, payment, token, etc.):
    IF size:XS → O + "[security]"
    IF size:S  → SC + "[security]"
    IF size:M  → OC + "[security]"
    IF size:L  → SOC + "[security]"
    IF size:XL → SOC + "[security]"
    ELSE       → OC + "[security]"
  ELSE (no security files):
    IF size:XS → S
    IF size:S  → O
    IF size:M  → SC
    IF size:L  → OC
    IF size:XL → SOC
    ELSE       → SC
```

### Present Full Hierarchy

Display the hierarchy with Tasks and their review tiers:

**For Epic:**
```
Epic #10: User Authentication System

├── Feature #11: Email/Password Login
│   ├── #14 Create user table        → S   (size:XS, area:db)
│   ├── #15 Create auth endpoint     → OC  (size:M) [security]
│   └── #16 Create login form        → SC  (size:M, area:frontend)
│
└── Feature #12: OAuth Login
    ├── #17 Add OAuth config         → SC  (size:S) [security]
    └── #18 Add OAuth callback       → OC  (size:M) [security]

Total: 5 Tasks across 2 Features
Methodology: TDD (test-first) for all Tasks
Verification gate before each Task merge
```

**For Feature:**
```
Feature #11: Email/Password Login (3 Tasks)

  1. #14 Create user table        → S   (size:XS, area:db)
  2. #15 Create auth endpoint     → OC  (size:M) [security]
  3. #16 Create login form        → SC  (size:M, area:frontend)

Methodology: TDD (test-first) for all Tasks
Verification gate before each Task merge
```

### Ask for Approval

**Use AskUserQuestion tool:**

**Question**: "Approve implementation plan with these review tiers?"
- Yes, start autonomous run (Recommended) - Implement all Tasks with shown tiers
- Customize review tiers - I'll specify different tiers
- Cancel - Stop work

**If "Yes, start autonomous run":**
- Store REVIEW_TIERS map: {14: "S", 15: "OC", 16: "SC", ...}
- Move Epic/Feature to In Progress
- Process each Task autonomously using stored tier
- No further prompts until all complete or error occurs

**If "Customize review tiers":**
- Ask for each Task's review tier
- Then proceed with autonomous run

**If "Cancel":** Stop and explain why

### Autonomous Task Processing

For each Task (in priority order):
1. Display: "Starting Task #N: $TITLE (Review: $TIER)"
2. Run Steps 1-8 using REVIEW_TIERS[N]
3. On success:
   - Task closes automatically
   - Check if parent Feature's Tasks are all done → close Feature
   - Check if parent Epic's Features are all done → close Epic
   - Continue to next Task
4. On error: STOP, report error, ask how to proceed:
   ```
   ERROR in Task #N: [description]

   Options:
   - Debug together - Help me investigate
   - Skip this Task - Continue to next
   - Stop - I'll handle manually
   ```

### After All Tasks Complete

All parent issues auto-close via Step 8 cascade.

Find next issue:
```bash
NEXT_ISSUE=$(gh issue list --label "priority:high" --state open --limit 1 --json number,title -q '.[0] | "#\(.number) \(.title)"')
[ -z "$NEXT_ISSUE" ] && NEXT_ISSUE=$(gh issue list --state open --limit 1 --json number,title -q '.[0] | "#\(.number) \(.title)"')
```

Report summary:
```
## Epic Complete

Epic #10: User Authentication System

Feature #11: Email/Password Login
  ✓ #14 Create user table        (S)
  ✓ #15 Create auth endpoint     (OC)
  ✓ #16 Create login form        (SC)

Feature #12: OAuth Login
  ✓ #17 Add OAuth config         (SC)
  ✓ #18 Add OAuth callback       (OC)

5 Tasks completed, 2 Features closed, 1 Epic closed.
All merged to main.

---
**Next up:** $NEXT_ISSUE (or "No open issues remaining")
Run `/kick next` to continue.
```

---

## Priority Order for Tasks

When processing Tasks (from Feature or Epic), order by:

1. `area:db` (database first)
2. `area:infra` (infrastructure)
3. `area:backend` (backend services)
4. `area:frontend` (frontend last)
5. Within same area: `priority:high` → `priority:medium` → `priority:low`

**Within a Feature:** Process Tasks in the order above.

**Within an Epic:** Process Features in the order their first Task appears (by area priority), then process all Tasks within each Feature before moving to the next Feature.
