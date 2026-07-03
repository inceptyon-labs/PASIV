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

Inputs from `/kick`: `$IDENTIFIER`, the `WORKFLOW_*` config, and the native tasks created by `plan`.

## Step 0: Branch

**Use Skill tool:** `git-ops` with args: `create-branch $IDENTIFIER`

## Per implementation task

Loop over the plan's implementation tasks in dependency order.

**1. Mark in progress + read the spec**

```
TaskUpdate: { taskId: <id>, status: in_progress }
```

`TaskGet` the task and parse its `json:metadata` fence → `files`, `acceptanceCriteria`, `verifyCommand`, `modelTier`.

**2. RED — you write the failing tests (Opus, in-context)**

For each acceptance criterion, write a test covering the behavior, edges, and boundaries. Run them; confirm they FAIL because the feature is missing (not a syntax/import error).

**Adequacy check before dispatch** — the test is the spec; an unguarded AC becomes unwritten code. Map each acceptance criterion to at least one failing test. Any AC without coverage: write its test now. Only then dispatch.

If `WORKFLOW_TDD` is false: skip RED; the subagent implements to the AC and adds tests after.

**3. GREEN — dispatch a fresh implementer subagent**

Resolve the implementer model from the task's `modelTier`:
- `.pasiv.yml` has a `model_routing` section → `model = model_routing[modelTier][host]`, where host is `claude` (`$CLAUDECODE` set) or `codex` (`$CODEX_*` set). E.g. `mechanical` → Haiku on Claude.
- `frontier` with no `model_routing` entry → `COORDINATOR_MODEL` if set (kick Step 0), else **Opus**.
- Otherwise (default) → **Sonnet**.

**Use the Task tool** at the resolved `model`, passing the prompt below filled in. Do NOT make the subagent read the plan file — hand it everything:

```
You are implementing one task. Make the failing tests pass with the least code that works.

GOAL: <task Goal>
SCOPE: <files from metadata> plus their test files. Anything outside is OUT OF BOUNDS —
if the fix seems to need another file, return BLOCKED and say why instead of expanding scope.
FAILING TESTS: <test file paths> — run `<verifyCommand>` to see them fail.
ACCEPTANCE CRITERIA: <acceptanceCriteria>
DONE MEANS: `<verifyCommand>` passes, then the full suite passes once.

Climb the ladder before writing — stop at the first rung that holds:
1 needs to exist? 2 already in this codebase (reuse)? 3 stdlib? 4 native platform feature?
5 installed dependency? 6 one line? 7 only then the minimum that works.
Never simplify away trust-boundary validation, data-loss handling, security, or accessibility.

For EACH failing test: write minimal code → run `<verifyCommand>` → refactor while green → commit
via the git-ops skill (`commit "feat: <what> (#<issue>)"`).

CONTRACT — report back ≤15 lines, nothing else: a status line (DONE | DONE_WITH_CONCERNS | BLOCKED),
per-cycle one-liners (test → GREEN/REFACTOR/COMMIT), and any concerns. No raw test output (summarize
failures as file:line), no diffs over 30 lines, no narration. This report is your return value.
```

When re-dispatching after a failure (ladder below), append a `PRIOR ATTEMPTS:` section with the earlier failure reports verbatim — the next model must not rediscover the dead ends.

**4. Handle the subagent's status**

- **DONE** → mark the task completed.
- **DONE_WITH_CONCERNS** → read the concerns. Correctness/scope concern → address before continuing; observation → note and continue.
- **BLOCKED or failed** → climb the escalation ladder:
  1. Missing context → re-dispatch **once** at the same tier with the context added. This is the only same-tier retry.
  2. Second failure at a tier → bump `modelTier` one step (mechanical→standard→frontier), re-resolve the model, re-dispatch with both failure reports in `PRIOR ATTEMPTS`. Never a third attempt at the same tier, never a silent step down.
  3. Task too large → split. Plan wrong → escalate to the user. Failing at frontier → stop and hand the user both failure reports; that signals a design problem, not an implementation one.

Never write the production code yourself — that pollutes your context and defeats the isolation. Your job is RED + coordination.

**5. Close the task**

```
TaskUpdate: { taskId: <id>, status: completed }
```

Run `TaskList`. More tasks → loop. All done → continue below. **Do not stop to check in between tasks** — execute the plan through.

## Bounded Parallel Dispatch (optimization)

The per-task loop above is the default. When the plan's next tasks are **independent**, dispatch their implementer subagents concurrently to cut wall-clock — but only when all of these hold:

- **Disjoint files** — the tasks' `files` metadata (from `plan`) share no path. The `files` list IS the test; no overlap means no write conflict.
- **No dependency** — neither task is in the other's `blockedBy` chain.
- **Worktree isolation** — dispatch each with the Task tool's `isolation: "worktree"` so parallel writers don't collide (it auto-cleans if untouched).

Mark every parallel task `in_progress` before dispatching. You still write each task's RED, and each still gets its own review as it completes. When overlap is uncertain, **serialize** — parallelism is the optimization, not the baseline. Never two writers on one file.

## After all tasks: Format & Lint

Run the project's formatter, then linter. If anything changed:

**Use Skill tool:** `git-ops` with args: `commit "style: format and lint"`

## Run the full suite

```bash
npm test || pytest || go test ./... || cargo test || bun test
```

Then typecheck if the project has one (`tsc --noEmit` / `npm run typecheck` / `mypy` / `cargo check`) — catch type errors here, before review sees the diff.

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
>>> EXECUTE COMPLETE — proceed to the review skill <<<
```
