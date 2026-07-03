---
name: repo-scan
description: Security-vet a repo for vulnerabilities, obfuscated code, malware, supply-chain risk. Use for "repo scan", "security scan", "audit repo", or vetting a forked/cloned repo.
model: opus
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Task
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
---

# Security Scan

Comprehensive security scan of a repository. Designed for vetting forked/cloned repos before trusting them.

**Input:** $ARGUMENTS (optional path to scan — defaults to current working directory)

**Task bookkeeping:** Wrap every scan step (3–9) in TaskUpdate — mark its task in_progress at the start and completed at the end. Not repeated per step below.

---

## Step 0: Set Target

TARGET = $ARGUMENTS or current working directory. Verify TARGET exists and is a directory; if not, stop with error.

---

## Step 1: Detect Ecosystem

Scan TARGET for package manager files to determine the ecosystem(s), stored as ECOSYSTEMS:

- `package.json` / `yarn.lock` / `pnpm-lock.yaml` / `bun.lockb` → Node.js (npm / Yarn / pnpm / Bun)
- `requirements.txt` / `setup.py` / `pyproject.toml` → Python
- `Cargo.toml` → Rust; `go.mod` → Go; `Gemfile` → Ruby; `composer.json` → PHP

Detect primary languages by file extensions: `.js`, `.ts`, `.jsx`, `.tsx`, `.py`, `.rb`, `.rs`, `.go`, `.php`, `.sh`, `.java`, `.kt`. Store as LANGUAGES.

---

## Step 2: Create Scan Tasks

Create native tasks for each scan phase:

1. **Dependency Audit** — Known CVEs in dependencies
2. **Suspicious Install Scripts** — Lifecycle hooks that execute code
3. **Obfuscated Code Detection** — Encoded, minified, or deliberately obscured code
4. **Network Call Analysis** — Outbound connections to unknown servers
5. **Malware Pattern Scan** — Crypto miners, reverse shells, data exfiltration
6. **Secrets Detection** — Hardcoded credentials, API keys, tokens
7. **File System Anomalies** — Hidden files, unexpected binaries, suspicious permissions

---

## Step 3: Dependency Audit

Run the audit tool for each detected ecosystem:

| Ecosystem | Command |
|-----------|---------|
| Node.js | `npm audit --json 2>/dev/null \|\| true` |
| Python | `pip audit --format=json 2>/dev/null \|\| pip-audit --format=json 2>/dev/null \|\| true` |
| Rust | `cargo audit --json 2>/dev/null \|\| true` |
| Go | `govulncheck ./... 2>/dev/null \|\| true` |

For Node.js, also check for typosquatting — scan `package.json` dependencies for names one character off from popular packages (e.g., `lodassh`, `expresss`) or with suspicious scopes.

If the audit tool is not installed, note it as "SKIPPED — tool not installed" and move on.

Record all findings with severity levels.

---

## Step 4: Suspicious Install Scripts

### Node.js
Check `package.json` for lifecycle scripts that could execute arbitrary code:

```
Grep for: "preinstall|postinstall|preuninstall|postuninstall|prepare|prepublish" in package.json
```

**Red flags:** scripts that `curl`/`wget`/`fetch` from URLs, run encoded/obfuscated commands, write to system directories outside the project, or spawn background processes.

Also check **all** `node_modules/*/package.json` for suspicious lifecycle scripts (if node_modules exists):
```
Grep for: "preinstall|postinstall" in node_modules/*/package.json
```

### Python
Check `setup.py` for suspicious `cmdclass` overrides or code in `setup()` that downloads/executes.

### Any ecosystem
Check for `.github/workflows`, `Makefile`, or CI configs that execute suspicious commands.

Record all findings.

---

## Step 5: Obfuscated Code Detection

Scan ALL source files (not node_modules, not .git, not vendor, not dist) for encoding patterns, suspicious eval/exec usage, and long encoded strings. Run the Step 5 patterns from `references/scan-patterns.md` (relative to this skill's directory).

**Context matters.** For each hit:
- Read surrounding lines (±5) to assess context
- Legitimate uses: test fixtures, SVG data, font data, source maps, bundled dependencies
- Suspicious uses: standalone encoded blobs, eval'd strings, decoded-then-executed patterns

**Classification:**
- CRITICAL: `eval()` of decoded/constructed strings
- HIGH: Large encoded blobs without clear purpose
- MEDIUM: `eval()` / `exec()` with static strings
- LOW: Base64 in test fixtures or data files
- FALSE POSITIVE: Source maps, SVG inline data, font data

Record findings with classification.

---

## Step 6: Network Call Analysis

Scan all source files for outbound network activity — hardcoded URLs/IPs, network functions, suspicious TLDs. Run the Step 6 patterns from `references/scan-patterns.md` (relative to this skill's directory).

**For each URL found:**
- Is it a well-known domain? (github.com, npmjs.org, pypi.org, googleapis.com, etc.) → LOW
- Is it an IP address instead of a domain? → HIGH
- Is it dynamically constructed? (`http://" + var + "/path`) → HIGH
- Is it going to a domain that doesn't match the project's purpose? → MEDIUM-HIGH
- Is it localhost/127.0.0.1? → LOW (likely development)

Record all findings with risk levels.

---

## Step 7: Malware Pattern Scan

Scan for crypto mining indicators, reverse shells, data exfiltration, backdoors, and file system manipulation. Run the Step 7 patterns from `references/scan-patterns.md` (relative to this skill's directory).

**For each hit, read surrounding context (±10 lines) to determine if legitimate.**

Record all findings.

---

## Step 8: Secrets Detection

Scan for API keys/tokens, passwords/credentials, and private keys. Run the Step 8 patterns from `references/scan-patterns.md` (relative to this skill's directory).

**Exclusions:** Skip hits in:
- `.env.example`, `.env.sample`, `.env.template` (placeholder values)
- Test/fixture files with obviously fake values (`test123`, `password`, `xxx`)
- Documentation files showing examples

Record genuine findings as CRITICAL.

---

## Step 9: File System Anomalies

Find unexpected hidden files, binaries in source directories, and files with unusual executable permissions. Run the Step 9 patterns from `references/scan-patterns.md` (relative to this skill's directory), then flag anything unexpected.

---

## Step 10: Generate Report

Compile all findings into a structured report.

### Report Format

```markdown
# Security Scan Report

**Repository:** [name]
**Scanned:** [date]
**Path:** [TARGET]
**Ecosystems:** [detected]
**Languages:** [detected]

---

## Executive Summary

- **CRITICAL:** [count] findings
- **HIGH:** [count] findings
- **MEDIUM:** [count] findings
- **LOW:** [count] findings
- **INFO:** [count] findings

**Verdict:** [PASS / CAUTION / FAIL]

---

## CRITICAL Findings
[Each finding with file:line, description, evidence, and recommendation]

## HIGH / MEDIUM / LOW / Informational Findings
[Same structure — one section per severity level]

---

## Scan Coverage

| Check | Status | Findings |
|-------|--------|----------|
| Dependency Audit | [DONE/SKIPPED] | [count] |
| Install Scripts | DONE | [count] |
| Obfuscated Code | DONE | [count] |
| Network Calls | DONE | [count] |
| Malware Patterns | DONE | [count] |
| Secrets | DONE | [count] |
| File Anomalies | DONE | [count] |

---

## Recommendations

[Prioritized list of actions to take before trusting this code]
```

### Verdict Logic

Count only findings that remain after the context-review pass (false positives removed):

- **FAIL**: ≥1 CRITICAL finding remains, or ≥3 HIGH findings remain
- **CAUTION**: Zero CRITICAL, 1–2 HIGH findings remain
- **PASS**: Zero CRITICAL and zero HIGH findings remain

### Output Location

Save report to:
```
docs/scans/YYYY-MM-DD-<repo-name>.md
```

---

## Step 11: Present Results

Display the Executive Summary and any CRITICAL/HIGH findings directly to the user, then the verdict message:

- **FAIL** — "This repository has critical security findings. Review the full report before using this code."
- **CAUTION** — "This repository has HIGH findings that survived context review. Review the flagged items."
- **PASS** — "No critical issues detected. The full report is saved for reference."

---

## Principles

- **Assume hostile until proven safe.** This tool exists to vet untrusted code. Default to suspicion — better to flag a false positive than miss a real threat.
- **Context over pattern matching.** Always read surrounding code before classifying a finding. `eval()` in a test helper is different from `eval()` decoding a base64 blob.
- **Don't touch the code.** This is a **read-only** scan. Never modify the repo being scanned. The report documents findings — the user decides what to do.
- **Be specific.** Every finding must include: file path, line number, evidence (the actual code), and why it's suspicious. Vague warnings are useless. Show the code.
