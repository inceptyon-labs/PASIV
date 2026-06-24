---
name: execute
description: Implement an approved plan task-by-task. Opus writes RED tests in-context; a fresh Sonnet implementer subagent does GREEN+REFACTOR+COMMIT per task, keeping the coordinator context lean. Internal — called by /kick.
model: opus
user-invocable: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Skill
  - Task
  - TaskGet
  - TaskUpdate
  - TaskList
---

# Execute

Implement the plan's tasks. **You (Opus) are the coordinator** — you write the failing tests (RED) because the test IS the spec and the stronger model writes better specs. Then you **dispatch a fresh Sonnet implementer subagent** to make them pass (GREEN), so the edit/run/error/retry loop happens in *its* context, not yours. You stay lean: you only absorb a short status report per task.

This is what keeps the whole session inside standard 200k context — no inline accumulation, no metered 1M. (See `docs/reference/model-optimization.md`.)

Inputs from `/kick`: `$ISSUE_NUM`, the `WORKFLOW_*` config, and the native tasks created by `plan`.

## Step 0: Branch

**Use Skill tool:** `git-ops` with args: `create-branch $ISSUE_NUM`

## Per implementation task

Loop over the plan's implementation tasks in dependency order.

**1. Mark in progress + read the spec**

```
TaskUpdate: { taskId: <id>, status: in_progress }
```

`TaskGet` the task and parse its `json:metadata` fence → `files`, `acceptanceCriteria`, `verifyCommand`.

**2. RED — you write the failing tests (Opus, in-context)**

For each acceptance criterion, write a test covering the behavior, edges, and boundaries. Run them; confirm they FAIL because the feature is missing (not a syntax/import error).

If `WORKFLOW_TDD` is false: skip RED; the subagent implements to the AC and adds tests after.

**3. GREEN — dispatch a fresh implementer subagent (Sonnet)**

**Use the Task tool** with `model: sonnet`, passing the prompt below filled in. Do NOT make the subagent read the plan file — hand it everything:

```
You are implementing one task. Make the failing tests pass with the least code that works.

TASK: <task Goal>
FILES: <files from metadata>
FAILING TESTS: <test file paths> — run `<verifyCommand>` to see them fail.
ACCEPTANCE CRITERIA: <acceptanceCriteria>

Climb the ladder before writing — stop at the first rung that holds:
1 needs to exist? 2 already in this codebase (reuse)? 3 stdlib? 4 native platform feature?
5 installed dependency? 6 one line? 7 only then the minimum that works.
Never simplify away trust-boundary validation, data-loss handling, security, or accessibility.

For EACH failing test: write minimal code → run `<verifyCommand>` → refactor while green → commit
via the git-ops skill (`commit "feat: <what> (#<issue>)"`). When all tests pass, run the full suite once.

Report back ONLY: a status line — DONE | DONE_WITH_CONCERNS | BLOCKED — then per-cycle one-liners
(test → GREEN/REFACTOR/COMMIT) and any concerns. Keep it short; this report is your return value.
```

**4. Handle the subagent's status**

- **DONE** → mark the task completed.
- **DONE_WITH_CONCERNS** → read the concerns. Correctness/scope concern → address before continuing; observation → note and continue.
- **BLOCKED** → assess: missing context → re-dispatch with it; needs more reasoning → re-dispatch one tier up (Opus); task too large → split; plan wrong → escalate to the user. Never re-dispatch the same model with no change.

Never write the production code yourself — that pollutes your context and defeats the isolation. Your job is RED + coordination.

**5. Close the task**

```
TaskUpdate: { taskId: <id>, status: completed }
```

Run `TaskList`. More tasks → loop. All done → continue below. **Do not stop to check in between tasks** — execute the plan through.

## After all tasks: Format & Lint

Run the project's formatter, then linter. If anything changed:

**Use Skill tool:** `git-ops` with args: `commit "style: format and lint"`

## Run the full suite

```bash
npm test || pytest || go test ./... || cargo test || bun test
```

**If tests fail — systematic debugging, no guessing:**

1. Read the full error — message, stack, file:line.
2. Reproduce the specific failing test.
3. Hypothesize ONE specific cause ("X fails because Y").
4. Make ONE minimal change.
5. Re-run.

**Three Strikes:** if 3 independent fix attempts fail, STOP and report the three hypotheses + results to the user — the failure likely signals a design problem, not a bug.

## Return

End your response with the continuation marker the caller depends on:

```
>>> EXECUTE COMPLETE — proceed to review (Step 4) <<<
```
