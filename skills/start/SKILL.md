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

**Helper skills (run with Haiku in forked context for efficiency):**
- `issue-ops` - Issue operations (get, create, close, check-off)
- `project-ops` - Project operations (setup, move status)
- `git-ops` - Git operations (branch, commit, push, merge)

---

## Step 0: Get Issue Details

**Use Skill tool:** `issue-ops` with args: `get $ISSUE_NUM`

If argument is "next", first find highest priority open issue:
```bash
ISSUE_NUM=$(gh issue list --label "priority:high" --state open --limit 1 --json number -q '.[0].number')
[ -z "$ISSUE_NUM" ] && ISSUE_NUM=$(gh issue list --state open --limit 1 --json number -q '.[0].number')
```

Store: ISSUE_NUM, ISSUE_TITLE, ISSUE_URL, ISSUE_BODY

---

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

---

## Step 1: Confirm Working Issue

Display: "Working on Issue #$ISSUE_NUM: $ISSUE_TITLE"

---

## Step 1.5: Move to In Progress

**Use Skill tool:** `project-ops` with args: `setup` → get PROJECT_NUM, PROJECT_ID

**Use Skill tool:** `project-ops` with args: `move-to-in-progress $PROJECT_ID $PROJECT_NUM $OWNER $ISSUE_URL`

### Cascade to Parent (if sub-issue)

**Use Skill tool:** `issue-ops` with args: `get-parent $OWNER $REPO $ISSUE_NUM`

If parent exists, also move parent to In Progress.

---

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

---

## Step 3: Implement

**Use Skill tool:** `git-ops` with args: `create-branch $ISSUE_NUM`

Make the changes AND write tests:
1. Implement the feature/fix
2. **Write tests** that verify acceptance criteria
3. Ensure tests cover edge cases

**Use Skill tool:** `git-ops` with args: `commit "feat: description (#$ISSUE_NUM)"`

---

## Step 3.25: Format & Lint

**Run formatters first, then linters.**

Detect and run appropriate formatters/linters for the project.

If changes made:
**Use Skill tool:** `git-ops` with args: `commit "style: format and lint"`

---

## Step 3.5: Run Tests

**Tests must pass before review.**

Detect and run test suite. If tests fail:
1. Fix the failing tests
2. **Use Skill tool:** `git-ops` with args: `commit "fix: failing tests"`
3. Re-run until pass

**Do not proceed to review until tests pass.**

---

## Step 4: 3-Model Review

**Flow: Sonnet → FIX → Opus → FIX → Codex → FIX → Done**

### Pass 1: Sonnet (fast)
Quick scan for bugs, security basics, missing error handling, **missing tests**.

**STOP after Pass 1.** If any ERRORs:
1. Fix each error
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Sonnet review findings"`
3. Then proceed to Pass 2

### Pass 2: Opus (deep)
Architecture, edge cases, performance, maintainability, **test coverage quality**.

**STOP after Pass 2.** If any ERRORs:
1. Fix each error
2. **Use Skill tool:** `git-ops` with args: `commit "fix: address Opus review findings"`
3. Then proceed to Pass 3

### Pass 3: Codex (independent)

**IMPORTANT: Use the custom prompt, NOT `codex review --base main`.**

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

---

## Step 5: Check Off Acceptance Criteria

**Use Skill tool:** `issue-ops` with args: `check-off-criteria $ISSUE_NUM`

---

## Step 6: Final Test Run & Merge

Run tests one final time. If fail, fix and re-run review cycle.

When all clean:

**Use Skill tool:** `git-ops` with args: `merge-to-main`

**Use Skill tool:** `issue-ops` with args: `close $ISSUE_NUM "Completed in $(git rev-parse --short HEAD)"`

---

## Step 7: Move to Done

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

Report:
```
## Done

Issue #$ISSUE_NUM completed and merged to main.

Review passes:
- Pass 1 (Sonnet): ✓
- Pass 2 (Opus): ✓
- Pass 3 (Codex): ✓

Commit: [short SHA]
```

---

## Parent Issue Flow (when sub-issues exist)

When `/start` is called on a parent issue that has sub-issues:

1. **List all sub-issues** and show suggested order
2. **Move parent to In Progress**
3. **For each sub-issue** (in priority order):
   - Ask user: "Ready to start sub-issue #N: Title?"
   - Run the full flow (Steps 1-7) for that sub-issue
   - Report completion
   - Ask: "Continue to next sub-issue #M?"
4. **After all sub-issues complete**, parent auto-closes

**Priority order for sub-issues:**
1. `area:db` (database first)
2. `area:infra` (infrastructure)
3. `area:backend` (backend services)
4. `area:frontend` (frontend last)
5. Within same area: `priority:high` → `priority:medium` → `priority:low`
