# Command Examples

## Refine a Vague Idea

```
/brainstorm
```
1. Socratic dialogue (one question at a time)
2. Explore 2-3 approaches with trade-offs
3. Present design in digestible chunks
4. Save to `docs/designs/YYYY-MM-DD-feature.md`
5. Offer to create issues with `/backlog`

## Stress-Test Existing Document

```
/brainstorm half-baked-plan.md
```

## Create a Task

```
/issue add CSV export to reports page
```

## Create a Feature with Tasks

```
/parent user notification system with email and push
```

## Create Epics from a Spec

```
/backlog spec.md
```

## Full Implementation Flow

```
/kick 42
```
1. Read issue #42
2. Create implementation plan
3. Select review tier (S/O/SC/OC/SOC)
4. Implement using TDD (test-first)
5. Run selected review pipeline
6. Verification gate (fresh evidence)
7. Merge to main and close issue

## Security Scan a Forked Repo

```
/repo-scan ~/Development/some-cloned-repo
```
1. Detect ecosystems and languages
2. Audit dependencies for known CVEs
3. Check for suspicious install scripts
4. Detect obfuscated/encoded code
5. Analyze network calls to unknown servers
6. Scan for malware patterns (miners, shells, exfil)
7. Find hardcoded secrets and credentials
8. Flag file system anomalies
9. Generate report with verdict (PASS/CAUTION/FAIL)

## Parent Issue (Autonomous)

```
/kick 41  # parent with sub-issues
```
1. Show all sub-issues with recommended review tiers
2. Approve once, walk away
3. Autonomous implementation of all sub-issues
4. Stops only on error

## Write Session Handoff

```
/handoff
```
Saves structured context to `docs/handoffs/handoff-YYYY-MM-DD-topic.md` for the next session.

## Configure Task Backend

```
/pasiv init
```
Interactive wizard to choose GitHub Issues, Beans, or local markdown backend.
