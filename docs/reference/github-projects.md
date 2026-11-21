# GitHub Projects integration

Issues are automatically added to a GitHub Project board.

## Auto-created project

Named after your repository. Created on first `/issue`, `/parent`, or `/backlog`.

## Auto-prioritization

`/backlog` outputs suggested implementation order based on:

1. Layer dependencies: `area:db` → `area:infra` → `area:backend` → `area:frontend`
2. Parent/sub-issue relationships: parents before children
3. Explicit dependencies: `Depends on #N` in issue body

## Required token scope

```bash
gh auth refresh -s project
```
