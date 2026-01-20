---
name: start
description: Full implementation flow - plan, implement, review, merge. Use when user says "start issue", "work on issue", "implement issue", "start #42", or wants to fully implement and merge a GitHub issue.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Skill
---

# Start Working on Issue

Full flow for: $ARGUMENTS (issue number or "next")

## Issue Type Hierarchy

| Level | Type | Scope | `/start` Behavior |
|-------|------|-------|-------------------|
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

### Determine Review Depth Recommendation

Check planned files for security patterns:
```bash
SECURITY_PATTERNS="auth|crypto|password|payment|token|secret|credential|session|login|oauth|jwt|apikey|private|key"
```

**Recommendation logic:**
```
IF any planned files match SECURITY_PATTERNS:
  → RECOMMEND = "Full 3-pass" + note "(security files detected)"
ELSE IF issue has label "size:L" OR "priority:high":
  → RECOMMEND = "Full 3-pass"
ELSE IF issue has label "size:M":
  → RECOMMEND = "Medium (Codex)"
ELSE IF issue has label "size:S" OR "bug":
  → RECOMMEND = "Light (Sonnet)"
ELSE:
  → RECOMMEND = "Medium (Codex)"
```

### Ask for Approval + Review Depth

**Use AskUserQuestion tool** with TWO questions:

**Question 1**: "Approve this implementation plan?"
- Approve - Continue to implementation
- Revise - Modify the plan
- Cancel - Stop work on this issue

**Question 2**: "What review depth for this change?"
- Light (Sonnet only) - simple bug/config {add "(Recommended)" if matches}
- Medium (Codex only) - moderate complexity {add "(Recommended)" if matches}
- Full 3-pass (Sonnet → Opus → Codex) - complex/security-sensitive {add "(Recommended)" or "(Recommended - security files detected)" if applicable}

**Store**: REVIEW_DEPTH = "light" | "medium" | "full"

**If Approve**: Continue to Step 3 with selected REVIEW_DEPTH
**If Revise**: Ask what to change, update plan, ask again
**If Cancel**: Stop and explain why

---

## Step 3: Implement (TDD)

**Use Skill tool:** `git-ops` with args: `create-branch $ISSUE_NUM`

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

## Step 4: Code Review (based on REVIEW_DEPTH)

### If REVIEW_DEPTH = "light"

**Sonnet review only (fast)**

Perform quick review focusing on:
- Clear bugs and errors
- Security basics (XSS, injection, auth flaws)
- Missing error handling
- Test coverage gaps

**Reference**: `@sonnet-review` skill for standalone use

Output format:
```
### Quick Review (Sonnet)
- [ERROR] file:line - description
- [WARNING] file:line - description
```

**If any ERRORs:**
1. Fix each error (use TDD - write test first if missing)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Sonnet review findings"`

Proceed to Step 5.

---

### If REVIEW_DEPTH = "medium"

**Codex review only (independent deep review)**

```bash
DIFF=$(git diff main)

codex exec -s read-only -o /tmp/codex-review.txt "Code review for Issue #$ISSUE_NUM.

Here is the diff:
$DIFF

Focus on:
1. Bugs and logic errors
2. Security issues
3. Test coverage gaps
4. Edge cases

Categorize as ERROR/WARNING/SUGGESTION."

cat /tmp/codex-review.txt
```

**If any ERRORs:**
1. Fix each error (use TDD - write test first if missing)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Codex review findings"`

Proceed to Step 5.

---

### If REVIEW_DEPTH = "full"

**Flow: Sonnet → FIX → Opus → FIX → Codex → FIX → Done**

#### Pass 1: Sonnet (fast)
Quick scan for bugs, security basics, missing error handling, **missing tests**.

**STOP after Pass 1.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Sonnet review findings"`
3. Then proceed to Pass 2

#### Pass 2: Opus (deep)
Architecture, edge cases, performance, maintainability, **test coverage quality**.

**STOP after Pass 2.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Opus review findings"`
3. Then proceed to Pass 3

#### Pass 3: Codex (independent)

```bash
DIFF=$(git diff main)

codex exec -s read-only -o /tmp/codex-review.txt "Independent code review for Issue #$ISSUE_NUM.

Here is the diff:
$DIFF

Focus on:
1. Subtle bugs or logic errors
2. Security edge cases
3. Test gaps
4. What previous reviewers missed

Categorize as ERROR/WARNING/SUGGESTION."

cat /tmp/codex-review.txt
```

**STOP after Pass 3.** If any ERRORs:
1. Fix each error (use TDD)
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Codex review findings"`

Proceed to Step 5.

---

## Step 5: Check Off Acceptance Criteria

**Use Skill tool:** `issue-ops` with args: `check-off-criteria $ISSUE_NUM`

---

## Step 6: Verification Gate

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
Review: [Light/Medium/Full]
Verification: ✓ All checks passed

Commit: [short SHA]

---
**Next up:** $NEXT_ISSUE (or "No open issues remaining")
Run `/start next` to continue.
```

---

## Parent Issue Flow (Autonomous)

When `/start` is called on an Epic or Feature (issue with sub-issues), use "approve once, walk away" mode.

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

### Determine Review Depth for Each Task

```
FOR each task:
  Get labels and estimate planned files
  IF likely touches security patterns (auth, crypto, payment, token, etc.):
    → RECOMMEND = "Full" + flag "[security]"
  ELSE IF has label "size:L" OR "priority:high":
    → RECOMMEND = "Full"
  ELSE IF has label "size:M":
    → RECOMMEND = "Medium"
  ELSE IF has label "size:S" OR "bug":
    → RECOMMEND = "Light"
  ELSE:
    → RECOMMEND = "Medium"
```

### Present Full Hierarchy

Display the hierarchy with Tasks and their review depths:

**For Epic:**
```
Epic #10: User Authentication System

├── Feature #11: Email/Password Login
│   ├── #14 Create user table        → Light  (size:S, area:db)
│   ├── #15 Create auth endpoint     → Full   (size:M) [security]
│   └── #16 Create login form        → Medium (size:M, area:frontend)
│
└── Feature #12: OAuth Login
    ├── #17 Add OAuth config         → Full   (size:S) [security]
    └── #18 Add OAuth callback       → Full   (size:M) [security]

Total: 5 Tasks across 2 Features
Methodology: TDD (test-first) for all Tasks
Verification gate before each Task merge
```

**For Feature:**
```
Feature #11: Email/Password Login (3 Tasks)

  1. #14 Create user table        → Light  (size:S, area:db)
  2. #15 Create auth endpoint     → Full   (size:M) [security]
  3. #16 Create login form        → Medium (size:M, area:frontend)

Methodology: TDD (test-first) for all Tasks
Verification gate before each Task merge
```

### Ask for Approval

**Use AskUserQuestion tool:**

**Question**: "Approve implementation plan with these review depths?"
- Yes, start autonomous run (Recommended) - Implement all Tasks with shown review depths
- Customize review depths - I'll specify different depths
- Cancel - Stop work

**If "Yes, start autonomous run":**
- Store REVIEW_DEPTHS map: {14: "light", 15: "full", 16: "medium", ...}
- Move Epic/Feature to In Progress
- Process each Task autonomously using stored depth
- No further prompts until all complete or error occurs

**If "Customize review depths":**
- Ask for each Task's review depth
- Then proceed with autonomous run

**If "Cancel":** Stop and explain why

### Autonomous Task Processing

For each Task (in priority order):
1. Display: "Starting Task #N: $TITLE (Review: $DEPTH)"
2. Run Steps 1-8 using REVIEW_DEPTHS[N]
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
  ✓ #14 Create user table        (Light review)
  ✓ #15 Create auth endpoint     (Full review)
  ✓ #16 Create login form        (Medium review)

Feature #12: OAuth Login
  ✓ #17 Add OAuth config         (Full review)
  ✓ #18 Add OAuth callback       (Full review)

5 Tasks completed, 2 Features closed, 1 Epic closed.
All merged to main.

---
**Next up:** $NEXT_ISSUE (or "No open issues remaining")
Run `/start next` to continue.
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
