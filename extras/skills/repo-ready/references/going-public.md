# Going public (Public GitHub destination, or flipping a private repo)

Publishing is one-way: a clone, a fork or a cache can keep whatever was visible for a minute. Run every check before the push or the visibility change. Report all findings together, then fix or get an explicit decision on each. Nothing below is skipped because the repo "looks clean".

`R=<owner>/<name>`. Run from the repo root.

## 1. Secrets, in history and in the tree

Run the gate in strict mode, so an allowlist in the repo's own `.gitleaks.toml`, a `.gitleaksignore` entry or an inline `gitleaks:allow` comment can't hide anything: `SECRET_GATE_BUILTIN=1 bash "$SKILL_DIR/scripts/secret-gate.sh" "$PWD"`. It must exit 0, or exit 3 with every listed file read and cleared. Exit 1 or 2 blocks a public destination.

Then ask the providers. The gate matches patterns; `scripts/live-check.sh` runs TruffleHog over every branch's history and verifies each candidate with its provider, so it finds live keys the gate's rules missed and tells you which of the gate's findings still work:

```bash
bash "$SKILL_DIR/scripts/live-check.sh" "$PWD"; echo "live-check exit=$?"
```

Exit 1 (a LIVE credential) blocks a public destination even when the gate was clean. Exit 3 (candidates the provider could not be reached to verify) is treated the same until each is checked. Exit 2 (TruffleHog not installed) is reported as SKIPPED, not as a pass. "Not live" is not "safe to publish": a revoked key in history still gets the repo flagged, so it goes through the steps below too. Own repos only; never run it on a repo being vetted.

A secret that was ever committed stays compromised after it is deleted from HEAD. In order:

1. **Rotate it.** Always, before anything else. Purging history does not un-leak a key.
2. **Get it out of history.** Pick one, with the user:
   - **Squash (first push only, simplest).** Publish one commit and keep the old history local:
     ```bash
     git branch -m main private-history      # old history stays on this machine
     git checkout --orphan main          # index still holds every tracked file
     git commit -m "Initial commit"
     ```
     No `git add -A` here: it would sweep untracked files into the one public commit. Never push `private-history`. After the push, `git ls-remote --heads origin` must list `main` only.
   - **Purge (history is worth keeping).** Needs `git filter-repo`, which refuses a non-fresh clone without `--force` and removes the `origin` remote. Take a backup first (`git bundle create ../<name>-backup.bundle --all`):
     ```bash
     git filter-repo --invert-paths --path <file>            # drop a file everywhere
     git filter-repo --replace-text <(echo 'literal-secret==>REMOVED')   # or scrub a value
     ```
3. Re-run the gate. It has to pass on the rewritten history. After a squash, the old commits are still on the local `private-history` branch, so scope the gate to what will be pushed: `SECRET_GATE_BUILTIN=1 SECRET_GATE_REFS=main bash "$SKILL_DIR/scripts/secret-gate.sh" "$PWD"`.

## 2. Personal and infrastructure details

Not secrets, but they are in the repo for good once public. List the hits and let the user decide on each:

```bash
# private IPs, home-directory paths, root@ logins, .local/.lan/.internal hostnames (no \b: BSD regex ignores it)
PAT='(^|[^0-9.])(192\.168|10\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]{1,3}\.[0-9]{1,3}([^0-9]|$)|/Users/[A-Za-z0-9._-]+|/home/[a-z0-9._-]+|(^|[^A-Za-z0-9])root@|[a-z0-9-]+\.(local|lan|internal)([^a-z0-9]|$)'
EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}'
echo "## in the tree";          git grep -nIE "$PAT" | cut -c1-160
echo "## emails in the tree";   git grep -nIE "$EMAIL" | grep -viE 'noreply|example\.(com|org)|@(types|[a-z0-9-]+/)' | cut -c1-160
echo "## commits whose diff has such a line (history)"; git log --all --oneline -E -G"$PAT|$EMAIL" | head -30
echo "## author identities";    git log --all --format='%an <%ae>%n%cn <%ce>' | sort -u      # every author email becomes public
```

Editing a file fixes the tree, not the history. If the user wants a hit gone and its commit is in the history list, that takes the squash or a `git filter-repo --replace-text` purge from section 1; say so, don't report it as fixed.

If the user wants a commit email kept private: `git config user.email "$(gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"')"` covers future commits. Rewriting past ones is a `git filter-repo --mailmap` history rewrite. Offer both; never change `user.email` or rewrite authors unasked.

## 3. What else ships

```bash
# blobs over 5 MB anywhere in history (GitHub rejects files over 100 MB)
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | awk '$1=="blob" && $2>5000000' | sort -k2 -nr | head
# dependencies an outsider cannot fetch
cat .gitmodules 2>/dev/null
git grep -nIE 'git\+ssh://|git@[a-z0-9.-]+:|"file:\.\.?/|link:\.\.?/' -- '*.json' '*.toml' '*.yaml' '*.yml' '*.lock' | head
# agent files, handoffs, task trackers and scratch notes that are tracked
git ls-files | grep -iE '(^|/)(CLAUDE\.md|AGENTS\.md|\.claude/|\.cursor|\.mcp\.json|\.beans/|handoffs?/|HANDOFF|NOTES\.md|TODO\.md|docs/tasks/)'
# known vulnerabilities and licenses of every locked dependency (reads lockfiles only; needs network)
osv-scanner scan source -r . --licenses 2>/dev/null; echo "osv-scanner exit=$?"
```

Agent files are the user's call (`de-vibe --gitignore` untracks them). A public repo needs a LICENSE; without one it is all-rights-reserved, so confirm "None" was deliberate.

Reading the `osv-scanner` output (exit 1 = vulnerabilities found, 128 = no lockfile, so nothing was checked; not installed = SKIPPED, `brew install osv-scanner`):

- **Vulnerabilities**: report the count and the worst CVSS score. Publishing with known-vulnerable dependencies is the user's call, but they should hear it before Dependabot tells them in public. Don't upgrade anything in this pass.
- **Licenses**: the last table lists each license and how many packages use it. Compare it with the license chosen in Question 1:
  - Project is MIT, Apache-2.0 or BSD and a dependency is GPL, AGPL or LGPL only (no `OR` alternative): flag it. The combined work may have to be distributed under the copyleft license.
  - Any dependency with no license, `UNLICENSED`, or a non-commercial or source-available license (`BUSL`, `SSPL`, `CC-BY-NC`, `Elastic`): flag it for every project license.
  - Project is AGPL-3.0 or GPL-3.0: permissive dependencies are fine; flag `GPL-2.0-only` and Apache-2.0 under GPL-2.0.
  - Name the packages behind a flagged license with `osv-scanner scan source -r . --licenses --format json`. This is a heads-up, not legal advice; say that.

## 4. Workflows

A public repo runs workflows for strangers' pull requests.

Run zizmor first if it is installed (`brew install zizmor`). It audits workflows, composite actions and `dependabot.yml` for far more than the greps below: template injection, credentials left on disk by `actions/checkout`, cache poisoning, writes to `GITHUB_ENV`, spoofable bot checks, over-broad secrets and permissions. With a token it also checks actions against known-vulnerable versions and impostor commits:

```bash
T="$(gh auth token 2>/dev/null)"
if [ -n "$T" ]; then GH_TOKEN="$T" zizmor --no-progress .; else zizmor --offline --no-progress .; fi; echo "zizmor exit=$?"
pinact run --fix=false --no-api; echo "pinact exit=$?"
```

- zizmor exit codes: 0 = nothing found; 3 = no workflows or actions to audit, which is not applicable, not a failure; 14 = at least one **High**; 13, 12, 11 = worst finding Medium, Low, informational. High findings block a public push until fixed or accepted; show Medium and Low, and let the user decide. A fix it marks "unsafe" changes behavior: describe it, don't apply it blind.
- pinact exits non-zero and prints one "can't be pinned" line per action that is not pinned to a full SHA (offline it cannot say more). `GITHUB_TOKEN="$T" pinact run` rewrites each `uses:` to its commit SHA with the version in a comment. That is the same code the workflow runs today, so it is safe to apply to workflows this skill wrote; for the project's existing workflows show the diff and apply on a yes. An action on a branch ref (`@main`, `@beta`) has no version to pin and stays as it is: list it as a follow-up. pinact honors a `.pinact.yaml` in the repo, so an action excluded there is not reported.
- Neither installed: say SKIPPED for each and fall back to the greps.
- If this runs before the skill has written `.github/` (Phase 3 of repo-ready), run it again after Phase 4: the workflows and `dependabot.yml` it writes are audited too.

The greps work without either tool. Each command prints under its own heading; a heading with nothing under it is a pass.

```bash
echo "## fork-triggered with secrets"; grep -rnE 'pull_request_target|workflow_run' .github/workflows 2>/dev/null
# untrusted event text; safe only as the value of an env: entry (those lines are filtered out)
echo "## event text outside env:"; grep -rnE '\$\{\{[^}]*github\.(head_ref|event\.[a-z_.]*(title|body|ref|label|message|name|email|head_branch))' .github/workflows 2>/dev/null \
  | grep -vE ':[0-9]+:[[:space:]]*(-[[:space:]]*)?([A-Z_][A-Z0-9_]*|if)[[:space:]]*:'
echo "## self-hosted runners"; grep -rnE 'runs-on:.*self-hosted' .github/workflows 2>/dev/null
echo "## workflow files with no top-level permissions: (file names)"; find .github/workflows -name '*.y*ml' -exec grep -LE '^permissions:' {} + 2>/dev/null
```

- `pull_request_target` or `workflow_run` that checks out or runs PR code hands a fork the repo's secrets: stop and fix.
- Event text (`title`, `body`, `head.ref`, commit `message`, …) expanded inside a `run:` or `script:` block, on the `run:` line or any line of a multi-line script, is shell injection: move the value into `env:` and use the variable.
- A self-hosted runner on a public repo executes fork code on that machine: stop.
- A workflow with no `permissions:` block gets the repo default; add `permissions: contents: read` and widen per job.

## 5. Flipping an existing private repo

Everything above, plus what already lives on GitHub:

```bash
# The local clone has to hold everything the remote does, or the gate scans less than what goes public.
[ "$(git rev-parse --is-shallow-repository)" = true ] && git fetch --unshallow origin
# Explicit refspecs: a single-branch clone fetches one branch otherwise, and a plain --tags
# refuses to update a local tag that differs from the remote's. Remote tags land under
# refs/remotes/origin-tags/, where the gate's --all picks them up without touching local tags.
git fetch origin '+refs/heads/*:refs/remotes/origin/*' '+refs/tags/*:refs/remotes/origin-tags/*' --prune || echo "FETCH FAILED - stop, the gate would scan a stale copy"
git ls-remote --heads --tags origin                                # every branch and tag goes public
comm -23 <(git ls-remote --heads origin | awk '{print $2}' | sed 's#refs/heads/##' | sort) <(git branch -r --format='%(refname:lstrip=3)' | sort)   # must print nothing
gh issue list -R $R --state all --limit 200 --json number,title
gh pr list -R $R --state all --limit 200 --json number,title
gh run list -R $R --limit 30
gh release list -R $R
gh api repos/$R/actions/secrets --jq '.secrets[].name'             # names only; note which workflows use them
```

- Delete stale remote branches before the flip. The gate scans every local and remote-tracking ref, so it only covers the remote after the fetch above; run it again now. Pull-request refs (`refs/pull/*`) are not fetched: closed PRs from deleted branches stay readable on a public repo, so check them by hand if any exist.
- Issue, PR and review text, release assets, the wiki, and Actions logs and artifacts all become readable. Skim the titles; delete runs whose logs print anything private (`gh run delete <id>`).
- Commits that were force-pushed away can stay reachable by SHA on GitHub. If the gate found a secret in history, a purge plus force-push on the existing repo is not enough to rely on: rotate, and prefer publishing to a new repo over flipping the old one.

When the flip is done or abandoned, drop the temporary tag refs: `git for-each-ref refs/remotes/origin-tags --format='delete %(refname)' | git update-ref --stdin`.

Print, then ask before running (same rule as Phase 6):

```bash
gh repo edit $R --visibility public --accept-visibility-change-consequences
```

Then apply `references/github-security.md` section 2.
