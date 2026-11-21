# Going public (Public GitHub destination, or flipping a private repo)

Publishing is one-way: a clone, a fork or a cache can keep whatever was visible for a minute. Run every check before the push or the visibility change. Report all findings together, then fix or get an explicit decision on each. Nothing below is skipped because the repo "looks clean".

`R=<owner>/<name>`. Run from the repo root.

## 1. Secrets, in history and in the tree

Run the gate in strict mode, so an allowlist in the repo's own `.gitleaks.toml`, a `.gitleaksignore` entry or an inline `gitleaks:allow` comment can't hide anything: `SECRET_GATE_BUILTIN=1 bash scripts/secret-gate.sh "$PWD"`. It must exit 0, or exit 3 with every listed file read and cleared. Exit 1 or 2 blocks a public destination.

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
3. Re-run the gate. It has to pass on the rewritten history. After a squash, the old commits are still on the local `private-history` branch, so scope the gate to what will be pushed: `SECRET_GATE_BUILTIN=1 SECRET_GATE_REFS=main bash scripts/secret-gate.sh "$PWD"`.

## 2. Personal and infrastructure details

Not secrets, but they are in the repo for good once public. List the hits and let the user decide on each:

```bash
git grep -nIE '\b(192\.168|10\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]{1,3}\.[0-9]{1,3}\b|/Users/[A-Za-z0-9._-]+|/home/[a-z0-9._-]+|\broot@|[a-z0-9-]+\.(local|lan|internal)\b' | cut -c1-160
git grep -nIE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}' | grep -viE 'noreply|example\.(com|org)|@(types|[a-z0-9-]+/)' | cut -c1-160
git log --all --format='%an <%ae>%n%cn <%ce>' | sort -u      # every author email becomes public
```

If the user wants a commit email kept private: set `git config user.email <id>+<login>@users.noreply.github.com` for future commits. Rewriting past ones is a `git filter-repo --mailmap` history rewrite; offer it, don't assume it.

## 3. What else ships

```bash
# blobs over 5 MB anywhere in history (GitHub rejects files over 100 MB)
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | awk '$1=="blob" && $2>5000000' | sort -k2 -nr | head
# dependencies an outsider cannot fetch
cat .gitmodules 2>/dev/null
git grep -nIE 'git\+ssh://|git@[a-z0-9.-]+:|"file:\.\.?/|link:\.\.?/' -- '*.json' '*.toml' '*.yaml' '*.yml' '*.lock' | head
# agent files, handoffs, task trackers and scratch notes that are tracked
git ls-files | grep -iE '(^|/)(CLAUDE\.md|AGENTS\.md|\.claude/|\.cursor|\.mcp\.json|\.beans/|handoffs?/|HANDOFF|NOTES\.md|TODO\.md|docs/tasks/)'
```

Agent files are the user's call (`de-vibe --gitignore` untracks them). A public repo needs a LICENSE; without one it is all-rights-reserved, so confirm "None" was deliberate.

## 4. Workflows

A public repo runs workflows for strangers' pull requests.

```bash
grep -rnE 'pull_request_target|workflow_run' .github/workflows 2>/dev/null
# untrusted event text; safe only as the value of an env: entry (those lines are filtered out)
grep -rnE '\$\{\{[^}]*github\.(head_ref|event\.[a-z_.]*(title|body|ref|label|message|name|email|head_branch))' .github/workflows 2>/dev/null \
  | grep -vE ':[0-9]+:[[:space:]]*(-[[:space:]]*)?([A-Z_][A-Z0-9_]*|if)[[:space:]]*:'
grep -rnE 'runs-on:.*self-hosted' .github/workflows 2>/dev/null
grep -LE '^permissions:' .github/workflows/*.y*ml 2>/dev/null                          # no explicit token scope
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
git fetch origin '+refs/heads/*:refs/remotes/origin/*' --tags --prune   # explicit refspec: a single-branch clone fetches one branch otherwise
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

Print, then ask before running (same rule as Phase 6):

```bash
gh repo edit $R --visibility public --accept-visibility-change-consequences
```

Then apply `references/github-security.md` section 2.
