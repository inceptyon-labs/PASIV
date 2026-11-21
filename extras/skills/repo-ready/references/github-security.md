# GitHub dependency and secret monitoring (Phase 4o + Phase 6)

The standard for every repo hosted on GitHub. `repo-ready` applies it on first push; `repo-tidy` checks existing repos against it. None of it applies to a non-GitHub remote.

## 1. `.github/dependabot.yml`

Skip if a Renovate config exists: `git ls-files | grep -E '(^|/)(renovate\.json5?|\.renovaterc(\.json5?)?)$'` prints something.

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
    cooldown:
      default-days: 7

  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    cooldown:
      default-days: 7
```

The `cooldown` block makes Dependabot wait a week before proposing a new release, which is the window in which a hijacked package is usually caught and pulled. Security updates ignore it. zizmor flags an entry without one.

If the file already exists, add only the missing entries. Leave its schedules, groups and ignores as they are.

Once the file reaches the default branch, Dependabot opens one PR per outdated dependency on its first run. Say so in the summary so the batch isn't a surprise. Merging a PR that edits a workflow file through `gh pr merge` needs the `workflow` token scope (`gh auth refresh -s workflow`).

## 2. Repository settings

These need admin on the repo, and the repo has to exist on GitHub first. Set `R=<owner>/<name>`.

Current state:

```bash
gh api -i repos/$R/vulnerability-alerts 2>/dev/null | head -1   # 204 = alerts on, 404 = off
gh api repos/$R/automated-security-fixes --jq .enabled
gh api repos/$R --jq '{visibility, security_and_analysis}'
gh api repos/$R/private-vulnerability-reporting --jq .enabled
gh api repos/$R/rulesets --jq '.[].name'
gh api repos/$R/code-scanning/default-setup --jq .state        # configured | not-configured
gh api repos/$R/actions/permissions/workflow --jq .default_workflow_permissions
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

Public repos also get these. Private repos on a free plan can't use rulesets or CodeQL, so list them as not applicable there:

```bash
# Private vulnerability reporting, so SECURITY.md can point at a form and not an email address
gh api -X PUT repos/$R/private-vulnerability-reporting

# Default branch: no force-push, no deletion. Skip if a ruleset named protect-default-branch exists.
gh api -X POST repos/$R/rulesets --input - <<'JSON'
{"name":"protect-default-branch","target":"branch","enforcement":"active",
 "conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},
 "rules":[{"type":"deletion"},{"type":"non_fast_forward"}]}
JSON

# CodeQL default setup: no workflow file to maintain. A 4xx means no supported language; skip it.
gh api -X PATCH repos/$R/code-scanning/default-setup -f state=configured
```

The ruleset has no bypass, so a deliberate history rewrite (`de-vibe --git`, a secret purge) means disabling it first: `gh api -X PUT repos/$R/rulesets/<id> -f enforcement=disabled`, then back to `active`.

Read-only default `GITHUB_TOKEN`, public and private:

```bash
gh api -X PUT repos/$R/actions/permissions/workflow -f default_workflow_permissions=read
```

On a new repo apply it straight away. On an existing repo apply it only when every workflow has its own `permissions:` block (`grep -LE '^permissions:' .github/workflows/*.y*ml` prints nothing); a workflow that relies on the write default breaks otherwise. If any lack one, list the files as a follow-up and leave the setting alone.

Secret scanning is free on public repos. On private repos it is the paid GitHub Secret Protection add-on, so skip that call there; the gitleaks hook and workflow cover private repos.

Push protection rejects a push that contains a recognised credential until the pusher bypasses it. Mention that when enabling it.

Secret scanning also reads history, so enabling it can raise alerts for keys already committed, including fake ones in test fixtures:

```bash
gh api "repos/$R/secret-scanning/alerts?state=open" --jq '.[] | {number, secret_type_display_name, html_url}'
gh api "repos/$R/dependabot/alerts?state=open" --jq length
```

Report what these return. A 404 from the secret-scanning call means scanning is disabled on the repo, not that there are no alerts. Don't resolve an alert without reading the flagged line.
