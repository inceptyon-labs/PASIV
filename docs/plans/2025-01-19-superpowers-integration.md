# Superpowers Integration Plan

**Goal**: Integrate TDD methodology, verification gates, and systematic debugging from [obra/superpowers](https://github.com/obra/superpowers) into github-automation.

**Key Technologies**: Claude Code skills, bash, GitHub CLI

**Subskill reference**: `@start`, `@3pass-review`, `@git-ops`

---

## Overview

| Component | Action | Priority |
|-----------|--------|----------|
| `skills/tdd/SKILL.md` | **NEW** - TDD cycle skill | P0 |
| `skills/verification/SKILL.md` | **NEW** - Verification gate skill | P0 |
| `skills/systematic-debugging/SKILL.md` | **NEW** - Debug methodology | P1 |
| `skills/start/SKILL.md` | **MODIFY** - Integrate TDD + verification | P0 |
| `skills/receiving-review/SKILL.md` | **NEW** - Review feedback handling | P2 |
| `CLAUDE.md` | **MODIFY** - Document new skills | P0 |

---

## Phase 1: Core TDD Skill

### Task 1.1: Create TDD skill directory

**Files**: `skills/tdd/SKILL.md` (create)

```yaml
---
name: tdd
description: Test-Driven Development cycle. Use when implementing any feature or fix. Enforces RED-GREEN-REFACTOR methodology.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---
```

### Task 1.2: Write TDD skill content

**File**: `skills/tdd/SKILL.md`

The skill must enforce:

1. **The Iron Law**: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
2. **RED Phase**: Write minimal test, verify it fails for the RIGHT reason
3. **GREEN Phase**: Write simplest code to pass, nothing more
4. **REFACTOR Phase**: Clean up while keeping tests green
5. **Commit**: After each GREEN-REFACTOR cycle

**Key sections**:

```markdown
# Test-Driven Development

**The Iron Law**: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST

Any code written before tests must be deleted and reimplemented through TDD.

---

## RED Phase

1. Write ONE minimal test for the next piece of functionality
2. Test must be clear and test real behavior (not mocks when avoidable)
3. Run the test

**Verify RED**:
```bash
# Run test suite (detect framework)
npm test || pytest || go test ./... || cargo test
```

The test MUST fail. If it passes immediately:
- STOP - you wrote code before the test, or the test doesn't test what you think
- Delete any production code written prematurely
- Rewrite the test to actually test the new behavior

**Expected output**: Test fails because the feature doesn't exist yet (not syntax error, not import error)

---

## GREEN Phase

1. Write the SIMPLEST code that makes the test pass
2. No extra features, no "while I'm here" improvements
3. Run the test

**Verify GREEN**:
```bash
npm test || pytest || go test ./... || cargo test
```

All tests must pass. If they don't:
- Fix ONLY what's needed to pass
- Don't add defensive code "just in case"

---

## REFACTOR Phase

Only after GREEN:
1. Remove duplication
2. Improve naming
3. Extract helpers if truly needed
4. Run tests after each change

```bash
npm test || pytest || go test ./... || cargo test
```

Tests must stay green throughout refactoring.

---

## Commit

After each complete RED-GREEN-REFACTOR cycle:

**Use Skill tool**: `git-ops` with args: `commit "test: add test for X" && commit "feat: implement X"`

Or combined if small:
**Use Skill tool**: `git-ops` with args: `commit "feat: X with tests"`

---

## Red Flags - STOP and Restart

If any of these occur, delete the code and restart TDD properly:

- [ ] Wrote production code before the test
- [ ] Test passed immediately without code changes
- [ ] Can't explain why the test should fail
- [ ] Added features beyond what the test requires
- [ ] "I'll add tests later" thought
- [ ] Test uses excessive mocking instead of real behavior

---

## When to Use TDD

**Always use for**:
- New features
- Bug fixes (write failing test that reproduces bug first)
- Refactoring (ensure tests exist first)
- Any behavior change

**May skip for** (with partner approval):
- Throwaway prototypes
- Generated/scaffolded code
- Pure config changes
```

---

## Phase 2: Verification Gate Skill

### Task 2.1: Create verification skill

**Files**: `skills/verification/SKILL.md` (create)

```yaml
---
name: verification
description: Verification gate before completion claims. Use before merge, before closing issues, before claiming "done".
allowed-tools:
  - Bash
  - Read
---
```

### Task 2.2: Write verification skill content

**File**: `skills/verification/SKILL.md`

```markdown
# Verification Before Completion

**The Rule**: NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE

Before asserting work is complete, fixed, or passing - execute verification and examine actual output.

---

## The Five-Step Gate

Before ANY completion claim:

### 1. IDENTIFY
What command proves your assertion?
- "Tests pass" → `npm test`
- "Build succeeds" → `npm run build`
- "No lint errors" → `npm run lint`

### 2. RUN
Execute it completely and freshly:
```bash
# Run the actual command, don't rely on memory
npm test
```

### 3. READ
Examine the FULL output:
- Exit code (0 = success)
- All test results
- Any warnings

### 4. VERIFY
Do the results ACTUALLY support your claim?
- "All 47 tests passed" ✓
- "45 passed, 2 skipped" - investigate skipped
- "Tests passed" with warnings - are warnings acceptable?

### 5. CLAIM
Only now state the result with evidence:
"Tests pass: 47/47 passing, 0 skipped, exit code 0"

---

## What Counts as Verification

| Claim | Required Evidence |
|-------|-------------------|
| "Tests pass" | Fresh test run output showing all pass |
| "Build works" | Fresh build output with exit code 0 |
| "No lint errors" | Fresh lint run output |
| "Feature works" | Test output OR manual verification steps |
| "Bug is fixed" | Test that reproduced bug now passes |

---

## What Does NOT Count

- Previous test runs (need CURRENT evidence)
- "Should pass" (need ACTUAL run)
- Partial checks (full suite required)
- Memory of earlier success (run again)
- Linter passing (doesn't mean tests pass)
- Agent/subagent success reports (verify yourself)

---

## Red Flag Language - STOP Before Claiming

If you catch yourself saying:
- "probably works"
- "should pass"
- "seems fine"
- "I think it's done"
- "tests were passing earlier"

STOP. Run verification. Get evidence.

---

## Before Merge Checklist

Run ALL of these and verify output:

```bash
# 1. Tests
npm test

# 2. Build
npm run build

# 3. Lint (if exists)
npm run lint

# 4. Type check (if exists)
npm run typecheck
```

Each must show clean output. If any fail, do not merge.

---

## Usage

This skill is called automatically by `/start` before merge.

Can also invoke directly:
**Use Skill tool**: `verification` with args: `pre-merge`
```

---

## Phase 3: Systematic Debugging Skill

### Task 3.1: Create debugging skill

**Files**: `skills/systematic-debugging/SKILL.md` (create)

```yaml
---
name: systematic-debugging
description: Systematic debugging methodology. Use when fixing bugs or when tests fail unexpectedly. Enforces root cause analysis before fixes.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Grep
  - Glob
---
```

### Task 3.2: Write debugging skill content

**File**: `skills/systematic-debugging/SKILL.md`

```markdown
# Systematic Debugging

**The Rule**: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST

Symptom-focused fixes mask problems and create technical debt.

---

## Phase 1: Root Cause Investigation

### Read the Error
```bash
# Get full error output
npm test 2>&1 | head -100
```

Look for:
- Exact error message
- Stack trace
- File and line numbers
- What was expected vs actual

### Reproduce Consistently
Can you make it fail every time? If intermittent:
- Note conditions when it fails
- Note conditions when it passes

### Check Recent Changes
```bash
git log --oneline -10
git diff HEAD~3
```

What changed recently that could cause this?

---

## Phase 2: Pattern Analysis

### Find Similar Working Code
```bash
# Search for similar patterns that work
grep -r "similar_function" --include="*.ts"
```

### Compare Methodically
Document EVERY difference between working and broken:
- Imports
- Function signatures
- Parameter types
- Return handling
- Error handling

---

## Phase 3: Hypothesis Testing

### Form Specific Hypothesis
"The bug is caused by X because Y"

Not: "something is wrong with the auth"
But: "the JWT token is not being refreshed because the refresh endpoint returns 401"

### Test with Minimal Change
ONE change at a time:
1. Make the smallest possible change
2. Run tests
3. If still fails, revert and try different hypothesis

### Three Strikes Rule
If 3 independent fixes have failed:
- STOP
- Question the architecture
- The bug may be a symptom of deeper design issue

---

## Phase 4: Implementation

### Write Failing Test First
```bash
# Add test that reproduces the bug
npm test -- --grep "bug description"
```

Test must fail, confirming it catches the bug.

### Apply Single Fix
Fix the root cause (not symptoms).

### Verify
```bash
npm test
```

Bug test passes, no other tests broken.

---

## Red Flags - Restart Phase 1

- Proposing fix before understanding cause
- "Let me just try one more thing"
- Each fix reveals new problems
- Assuming cause without verification
- Fix works but you can't explain why

---

## Debug Log Template

When debugging, maintain this log:

```
## Bug: [description]

### Error Output
[paste actual error]

### Hypothesis 1: [theory]
Evidence for: [what supports this]
Evidence against: [what contradicts]
Test: [what I tried]
Result: [what happened]

### Hypothesis 2: [theory]
...

### Root Cause
[final determination]

### Fix
[what was changed and why]
```
```

---

## Phase 4: Modify `/start` to Integrate TDD + Verification + Review Depth Selection

### Task 4.0: Add Review Depth Selection to Step 2 (Plan Approval)

**File**: `skills/start/SKILL.md`

**Current** (lines 74-88):
```markdown
## Step 2: Create Plan

Analyze the issue and codebase. Present:

- **Summary**: What we're building
- **Files to modify**: With expected changes
- **New files**: If any
- **Tests to add**: What tests will verify this works
- **Approach**: Step-by-step
- **Risks**: Potential issues

**Use AskUserQuestion tool** to get approval:
- **Approve**: Continue to Step 3
- **Revise**: Ask what to change, update plan, ask again
- **Cancel**: Stop and explain why
```

**Replace with**:
```markdown
## Step 2: Create Plan

Analyze the issue and codebase. Present:

- **Summary**: What we're building
- **Files to modify**: With expected changes
- **New files**: If any
- **Tests to add**: What tests will verify this works
- **Approach**: Step-by-step
- **Risks**: Potential issues

### Determine Review Depth Recommendation

Check for security-sensitive files in the plan:
```bash
# Files that trigger Full review recommendation
SECURITY_PATTERNS="auth|crypto|password|payment|token|secret|credential|session|login|oauth|jwt|apikey|private"
```

**Recommendation logic**:
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

**Question 1** - "Approve this implementation plan?"
- Approve - Continue to implementation
- Revise - Modify the plan
- Cancel - Stop work on this issue

**Question 2** - "What review depth for this change?"
- Light (Sonnet only) - simple bug/config {add "(Recommended)" if that's the recommendation}
- Medium (Codex only) - moderate complexity {add "(Recommended)" if that's the recommendation}
- Full 3-pass (Sonnet → Opus → Codex) - complex/security-sensitive {add "(Recommended)" or "(Recommended - security files detected)" if applicable}

**Store**: REVIEW_DEPTH = "light" | "medium" | "full"

**If Approve**: Continue to Step 3 with selected REVIEW_DEPTH
**If Revise**: Ask what to change, update plan, ask again
**If Cancel**: Stop and explain why
```

---

### Task 4.0b: Parent Issue Review Depth Selection (Step 0.5)

**File**: `skills/start/SKILL.md`

When a parent issue has sub-issues, show all review depth recommendations upfront for "approve once, walk away" autonomy.

**Current** (lines 37-49):
```markdown
## Step 0.5: Check for Sub-Issues

**Use Skill tool:** `issue-ops` with args: `get-sub-issues $OWNER $REPO $ISSUE_NUM`

**If sub-issues exist:**
1. Move parent to In Progress (Step 1.5)
2. For each sub-issue (in priority order):
   - Ask user: "Ready to start sub-issue #N: Title?"
   - Run Steps 1-7 for that sub-issue
   - After completing, continue to next
3. After all done, parent auto-closes (Step 7 cascade)

**If no sub-issues:** Continue with normal flow.
```

**Replace with**:
```markdown
## Step 0.5: Check for Sub-Issues

**Use Skill tool:** `issue-ops` with args: `get-sub-issues $OWNER $REPO $ISSUE_NUM`

**If no sub-issues:** Continue with normal flow (Step 1).

**If sub-issues exist:**

### Analyze All Sub-Issues

For each sub-issue, determine recommended review depth:
```bash
SECURITY_PATTERNS="auth|crypto|password|payment|token|secret|credential|session|login|oauth|jwt|apikey|private"
```

```
FOR each sub-issue:
  Get labels and planned files
  IF files match SECURITY_PATTERNS:
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

### Present Upfront Summary

Display:
```
Parent #$PARENT_NUM: $PARENT_TITLE ($COUNT sub-issues)

Implementation order:
  1. #42 Add user model        → Light  (size:S)
  2. #43 Add auth endpoints    → Full   (size:M) [security]
  3. #44 Add login UI          → Medium (size:M)

Methodology: TDD (test-first) for all sub-issues
Verification gate before each merge
```

**Use AskUserQuestion tool:**

**Question**: "Approve implementation plan with these review depths?"
- Yes, start autonomous run (Recommended) - Implement all sub-issues with shown review depths
- Customize review depths - I'll specify different depths
- Cancel - Stop work

**If "Yes, start autonomous run":**
- Store REVIEW_DEPTHS map: {42: "light", 43: "full", 44: "medium"}
- Move parent to In Progress (Step 1.5)
- Process each sub-issue autonomously (Steps 1-7) using stored depth
- No further prompts until all complete or error occurs

**If "Customize review depths":**
- **Use AskUserQuestion** for each sub-issue to set depth
- Then proceed with autonomous run

**If "Cancel":** Stop and explain why

### Autonomous Sub-Issue Processing

For each sub-issue (in priority order):
1. Display: "Starting sub-issue #N: Title (Review: DEPTH)"
2. Run Steps 2-7 using REVIEW_DEPTHS[N]
3. On success: Continue to next sub-issue
4. On error: STOP, report error, ask how to proceed

After all sub-issues complete:
- Parent auto-closes (Step 7 cascade)
- Report summary of all sub-issues
```

---

### Task 4.1: Update Step 3 (Implement) to use TDD

**File**: `skills/start/SKILL.md`

**Current** (lines 91-101):
```markdown
## Step 3: Implement

**Use Skill tool:** `git-ops` with args: `create-branch $ISSUE_NUM`

Make the changes AND write tests:
1. Implement the feature/fix
2. **Write tests** that verify acceptance criteria
3. Ensure tests cover edge cases

**Use Skill tool:** `git-ops` with args: `commit "feat: description (#$ISSUE_NUM)"`
```

**Replace with**:
```markdown
## Step 3: Implement (TDD)

**Use Skill tool:** `git-ops` with args: `create-branch $ISSUE_NUM`

### For each piece of functionality:

**Follow the TDD cycle (RED-GREEN-REFACTOR):**

1. **RED**: Write ONE failing test
   ```bash
   # Run tests - must FAIL
   npm test || pytest || go test ./...
   ```
   Verify: Test fails because feature doesn't exist (not syntax/import error)

2. **GREEN**: Write simplest code to pass
   ```bash
   # Run tests - must PASS
   npm test || pytest || go test ./...
   ```
   Verify: Test passes, no other tests broken

3. **REFACTOR**: Clean up if needed, tests stay green

4. **COMMIT**: After each cycle
   **Use Skill tool:** `git-ops` with args: `commit "feat: [what was added] (#$ISSUE_NUM)"`

**Repeat** for each acceptance criterion until all are covered.

### TDD Violations - STOP

If you find yourself:
- Writing code before tests → Delete code, write test first
- Test passes immediately → Test doesn't test what you think
- Adding features beyond the test → Remove extras

**Reference**: `@tdd` skill for full methodology
```

### Task 4.2: Add Verification Gate before merge

**File**: `skills/start/SKILL.md`

**Insert between Step 6 and Step 7** (after line 191, before "## Step 7"):

```markdown
## Step 6.5: Verification Gate

**Before merge, verify ALL of these with fresh runs:**

```bash
# 1. Tests pass
npm test || pytest || go test ./...

# 2. Build succeeds (if applicable)
npm run build || go build ./... || cargo build

# 3. Lint clean (if applicable)
npm run lint || golangci-lint run
```

**For each command:**
1. Run it fresh (don't rely on earlier results)
2. Verify exit code is 0
3. Check output for warnings

**Only proceed to merge if ALL verifications pass.**

If any fail:
1. Fix the issue
2. Run 3-pass review on the fix
3. Re-run verification gate

**Reference**: `@verification` skill for methodology
```

### Task 4.3: Update Step 3.5 (tests fail) to use systematic debugging

**File**: `skills/start/SKILL.md`

**Current** (lines 115-124):
```markdown
## Step 3.5: Run Tests

**Tests must pass before review.**

Detect and run test suite. If tests fail:
1. Fix the failing tests
2. **Use Skill tool:** `git-ops` with args: `commit "fix: failing tests"`
3. Re-run until pass

**Do not proceed to review until tests pass.**
```

**Replace with**:
```markdown
## Step 3.5: Run Tests

**Tests must pass before review.**

```bash
npm test || pytest || go test ./...
```

### If tests fail:

**Use systematic debugging (don't guess):**

1. **Investigate** - Read full error, identify root cause
2. **Hypothesize** - Form specific theory about the cause
3. **Test** - Make ONE minimal change
4. **Verify** - Run tests again

```bash
# After each fix attempt
npm test || pytest || go test ./...
```

**Three Strikes Rule**: If 3 fix attempts fail, STOP and reassess. The failure may indicate a deeper design issue.

After fix:
**Use Skill tool:** `git-ops` with args: `commit "fix: [root cause description]"`

**Reference**: `@systematic-debugging` skill for full methodology

**Do not proceed to review until tests pass.**
```

---

### Task 4.4: Update Step 4 (Review) to use REVIEW_DEPTH

**File**: `skills/start/SKILL.md`

**Current** (lines 127-174) - the full 3-pass review section.

**Replace with**:
```markdown
## Step 4: Code Review (based on REVIEW_DEPTH)

### If REVIEW_DEPTH = "light":

**Pass 1 only: Sonnet (fast)**

Quick scan for bugs, security basics, missing error handling, missing tests.

```
### Review (Sonnet)
- [ERROR] file:line - description
- [WARNING] file:line - description
```

**If any ERRORs:**
1. Fix each error
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Sonnet review findings"`

Skip to Step 5.

---

### If REVIEW_DEPTH = "medium":

**Pass 1 only: Codex (independent deep review)**

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
1. Fix each error
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Codex review findings"`

Skip to Step 5.

---

### If REVIEW_DEPTH = "full":

**Flow: Sonnet → FIX → Opus → FIX → Codex → FIX → Done**

#### Pass 1: Sonnet (fast)
Quick scan for bugs, security basics, missing error handling, **missing tests**.

**STOP after Pass 1.** If any ERRORs:
1. Fix each error
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Sonnet review findings"`
3. Then proceed to Pass 2

#### Pass 2: Opus (deep)
Architecture, edge cases, performance, maintainability, **test coverage quality**.

**STOP after Pass 2.** If any ERRORs:
1. Fix each error
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
1. Fix each error
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Codex review findings"`
```

---

## Phase 5: Update CLAUDE.md

### Task 5.1: Add new skills to documentation

**File**: `CLAUDE.md`

**Add to Slash Commands table:**

| Command | What it does |
|---------|-------------|
| (internal) `@tdd` | TDD cycle enforcement |
| (internal) `@verification` | Pre-completion verification gate |
| (internal) `@systematic-debugging` | Root cause debugging methodology |

**Update "## Review Pipeline" section to:**

```markdown
## Review Pipeline

Select review depth during plan approval in `/start`:

| Depth | Models | When to Use | Cost |
|-------|--------|-------------|------|
| **Light** | Sonnet | Simple bugs, config, `size:S` | $ |
| **Medium** | Codex | Moderate features, `size:M` | $$ |
| **Full** | Sonnet → Opus → Codex | Complex, security-sensitive, `size:L` | $$$ |

**Smart recommendations**: Based on issue size labels and security file detection (auth, crypto, payment, etc.)

**Full 3-pass flow**: Sonnet → FIX → Opus → FIX → Codex → FIX → Done
```

**Add new section after "## Review Pipeline":**

```markdown
## Development Methodology

### TDD Cycle (enforced in `/start`)

```
RED → GREEN → REFACTOR → COMMIT → repeat
```

1. Write failing test
2. Verify it fails for the RIGHT reason
3. Write minimal code to pass
4. Verify it passes
5. Refactor if needed
6. Commit

**Iron Law**: No production code without a failing test first.

### Verification Gate (before merge)

Fresh evidence required for all claims:
- Tests pass → run `npm test`, see output
- Build works → run `npm run build`, see output
- Lint clean → run `npm run lint`, see output

No "should work" or "was passing earlier".

### Systematic Debugging (when tests fail)

1. **Investigate** root cause (don't guess)
2. **Hypothesize** specific theory
3. **Test** with minimal change
4. **Three strikes** → reassess architecture
```

---

## Phase 6: Optional - Receiving Review Skill

### Task 6.1: Create receiving-review skill (P2)

**Files**: `skills/receiving-review/SKILL.md` (create)

For handling feedback from 3-pass review without performative language.

**Key principles**:
- Restate technical requirements, don't say "great point!"
- Verify suggestions against codebase before implementing
- Push back when suggestions break functionality or violate YAGNI
- Fix one item at a time with TDD

---

## Implementation Order

1. **Phase 1**: Create `skills/tdd/SKILL.md`
2. **Phase 2**: Create `skills/verification/SKILL.md`
3. **Phase 4**: Modify `skills/start/SKILL.md`:
   - Task 4.0: Add review depth selection to Step 2
   - Task 4.1: Update Step 3 to use TDD
   - Task 4.2: Add verification gate (Step 6.5)
   - Task 4.3: Update Step 3.5 with systematic debugging
   - Task 4.4: Update Step 4 to branch on REVIEW_DEPTH
4. **Phase 5**: Update `CLAUDE.md` (review depth table + methodology section)
5. **Phase 3**: Create `skills/systematic-debugging/SKILL.md`
6. **Phase 6**: Create `skills/receiving-review/SKILL.md` (optional)

---

## Testing the Integration

After implementation, test with:

```bash
# Create test issue
/issue add test TDD integration

# Run full flow
/start [issue-number]
```

Verify:
- [ ] TDD cycle is followed (tests written before code)
- [ ] Failing tests trigger systematic debugging
- [ ] Verification gate runs before merge
- [ ] All claims backed by fresh evidence

---

## Rollback Plan

If issues arise:
1. Skills are modular - can disable individually
2. Original `/start` behavior preserved if TDD/verification skills removed
3. No breaking changes to existing helper skills (git-ops, issue-ops, project-ops)
