# GitHub dependency and secret monitoring (Phase 4o + Phase 6)

The standard for every repo hosted on GitHub. `repo-ready` applies it on first push; `repo-tidy` checks existing repos against it. None of it applies to a non-GitHub remote.

## 1. `.github/dependabot.yml`

Skip if a Renovate config exists (`renovate.json`, `.renovaterc*`, `.github/renovate.json*`).

One `updates` entry per manifest in the repo, on a weekly schedule, plus `github-actions` whenever `.github/workflows/` exists or is being created:

| Manifest | `package-ecosystem` |
|---|---|
| `package.json` (npm, Yarn, pnpm) | `npm` |
| `bun.lock` | `bun` |
| `pyproject.toml` / `requirements.txt` | `pip` (`uv` when `uv.lock` exists) |
| `Cargo.toml` | `cargo` |
| `go.mod` | `gomod` |
| `Gemfile` | `bundler` |
| `composer.json` | `composer` |
| `pubspec.yaml` | `pub` |
| `Package.swift` | `swift` |
| `Dockerfile` | `docker` |
| `docker-compose.yml` | `docker-compose` |
| `.github/workflows/` | `github-actions` |

`directory` is the folder that holds the manifest (`/` at the root). A monorepo gets one entry per folder.

```yaml
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly

  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

If the file already exists, add only the missing entries. Leave its schedules, groups and ignores as they are.

Once the file reaches the default branch, Dependabot opens one PR per outdated dependency on its first run. Say so in the summary so the batch isn't a surprise. Merging a PR that edits a workflow file through `gh pr merge` needs the `workflow` token scope (`gh auth refresh -s workflow`).

## 2. Repository settings

These need admin on the repo, and the repo has to exist on GitHub first. Set `R=<owner>/<name>`.

Current state:

```bash
gh api -i repos/$R/vulnerability-alerts 2>/dev/null | head -1   # 204 = alerts on, 404 = off
gh api repos/$R/automated-security-fixes --jq .enabled
gh api repos/$R --jq '{visibility, security_and_analysis}'
```

Enable. Every call is idempotent:

```bash
# Dependabot alerts and automatic security-fix PRs: public and private repos
gh api -X PUT repos/$R/vulnerability-alerts
gh api -X PUT repos/$R/automated-security-fixes

# Secret scanning and push protection: public repos only
gh api -X PATCH repos/$R --input - <<'JSON'
{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}
JSON
```

Secret scanning is free on public repos. On private repos it is the paid GitHub Secret Protection add-on, so skip that call there; the gitleaks hook and workflow cover private repos.

Push protection rejects a push that contains a recognised credential until the pusher bypasses it. Mention that when enabling it.

Secret scanning also reads history, so enabling it can raise alerts for keys already committed, including fake ones in test fixtures:

```bash
gh api "repos/$R/secret-scanning/alerts?state=open" --jq '.[] | {number, secret_type_display_name, html_url}'
gh api "repos/$R/dependabot/alerts?state=open" --jq length
```

Report what these return. Don't resolve an alert without reading the flagged line.
