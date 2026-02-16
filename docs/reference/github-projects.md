# GitHub Projects Integration

Issues are automatically added to a GitHub Project board.

## Auto-Created Project

Named after your repository. Created on first `/issue`, `/parent`, or `/backlog`.

## Auto-Prioritization

`/backlog` outputs suggested implementation order based on:

1. Layer dependencies: `area:db` → `area:infra` → `area:backend` → `area:frontend`
2. Parent/sub-issue relationships: parents before children
3. Explicit dependencies: `Depends on #N` in issue body

## Required Token Scope

```bash
gh auth refresh -s project
```
