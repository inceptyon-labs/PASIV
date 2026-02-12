---
name: repo-scan
description: Security scan a repo for vulnerabilities, obfuscated code, malicious calls, malware, and supply chain risks. Use when user says "repo scan", "repo-scan", "security scan", "audit repo", or wants to vet a forked/cloned repo.
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

---

## Step 0: Set Target

```
TARGET = $ARGUMENTS or current working directory
```

Verify TARGET exists and is a directory. If not, stop with error.

---

## Step 1: Detect Ecosystem

Scan TARGET for package manager files to determine the ecosystem(s):

| File | Ecosystem |
|------|-----------|
| `package.json` | Node.js / npm |
| `yarn.lock` | Node.js / Yarn |
| `pnpm-lock.yaml` | Node.js / pnpm |
| `bun.lockb` | Node.js / Bun |
| `requirements.txt`, `setup.py`, `pyproject.toml` | Python |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `Gemfile` | Ruby |
| `composer.json` | PHP |

Store detected ecosystems as ECOSYSTEMS.

Detect primary languages by file extensions: `.js`, `.ts`, `.jsx`, `.tsx`, `.py`, `.rb`, `.rs`, `.go`, `.php`, `.sh`, `.java`, `.kt`.

Store as LANGUAGES.

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

**Mark task in_progress.**

### Node.js
```bash
npm audit --json 2>/dev/null || true
```
Also check for typosquatting — scan `package.json` dependencies for names that are:
- One character off from popular packages (e.g., `lodassh`, `expresss`)
- Contain suspicious scopes

### Python
```bash
pip audit --format=json 2>/dev/null || pip-audit --format=json 2>/dev/null || true
```

### Rust
```bash
cargo audit --json 2>/dev/null || true
```

### Go
```bash
govulncheck ./... 2>/dev/null || true
```

If the audit tool is not installed, note it as "SKIPPED — tool not installed" and move on.

Record all findings with severity levels.

**Mark task completed.**

---

## Step 4: Suspicious Install Scripts

**Mark task in_progress.**

### Node.js
Check `package.json` for lifecycle scripts that could execute arbitrary code:

```
Grep for: "preinstall|postinstall|preuninstall|postuninstall|prepare|prepublish" in package.json
```

**Red flags:**
- Scripts that `curl`, `wget`, or `fetch` from URLs
- Scripts that run encoded/obfuscated commands
- Scripts that write to system directories outside the project
- Scripts that spawn background processes

Also check **all** `node_modules/*/package.json` for suspicious lifecycle scripts (if node_modules exists):
```
Grep for: "preinstall|postinstall" in node_modules/*/package.json
```

### Python
Check `setup.py` for suspicious `cmdclass` overrides or code in `setup()` that downloads/executes.

### Any ecosystem
Check for `.github/workflows`, `Makefile`, or CI configs that execute suspicious commands.

Record all findings.

**Mark task completed.**

---

## Step 5: Obfuscated Code Detection

**Mark task in_progress.**

Scan ALL source files (not node_modules, not .git, not vendor, not dist) for:

### Encoding patterns
```
Grep for: "eval\s*\(|Function\s*\(|new\s+Function"
Grep for: "atob\s*\(|btoa\s*\(|Buffer\.from\s*\(.*(base64|hex)"
Grep for: "\\\\x[0-9a-fA-F]{2}\\\\x[0-9a-fA-F]{2}"  (hex escape sequences, 3+ consecutive)
Grep for: "\\\\u[0-9a-fA-F]{4}\\\\u[0-9a-fA-F]{4}"  (unicode escape sequences, 3+ consecutive)
Grep for: "fromCharCode"
Grep for: "String\.raw"
```

### Suspicious patterns
```
Grep for: "eval\(.*decode|eval\(.*unescape|eval\(.*fromCharCode"
Grep for: "document\.write\s*\(.*unescape"
Grep for: "\\bexec\s*\(" in .py files (Python exec)
Grep for: "compile\s*\(.*exec" in .py files
Grep for: "__import__\s*\(" in .py files
```

### Long encoded strings
```
Grep for: "[A-Za-z0-9+/=]{100,}" (base64-like strings over 100 chars)
Grep for: "0x[0-9a-fA-F]{20,}" (long hex strings)
```

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

**Mark task completed.**

---

## Step 6: Network Call Analysis

**Mark task in_progress.**

Scan all source files for outbound network activity:

### URLs and IPs
```
Grep for: "https?://[^\s'\"\`\)]+" (extract all hardcoded URLs)
Grep for: "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b" (hardcoded IPs)
```

### Network functions
```
Grep for: "fetch\s*\(|axios\.|http\.request|https\.request|urllib|requests\.(get|post|put|delete|patch)"
Grep for: "XMLHttpRequest|\.ajax\(|WebSocket\s*\("
Grep for: "net\.connect|dgram\.|dns\.resolve|child_process"
Grep for: "subprocess\.(run|call|Popen)|os\.system|os\.popen" in .py files
Grep for: "curl|wget|nc\s|ncat\s|netcat" in .sh files
```

### DNS/domain patterns
```
Grep for: "\.(ru|cn|tk|ml|ga|cf|gq|xyz|top|buzz|club)\b" in URLs (suspicious TLDs — flag, not auto-condemn)
```

**For each URL found:**
- Is it a well-known domain? (github.com, npmjs.org, pypi.org, googleapis.com, etc.) → LOW
- Is it an IP address instead of a domain? → HIGH
- Is it dynamically constructed? (`http://" + var + "/path`) → HIGH
- Is it going to a domain that doesn't match the project's purpose? → MEDIUM-HIGH
- Is it localhost/127.0.0.1? → LOW (likely development)

Record all findings with risk levels.

**Mark task completed.**

---

## Step 7: Malware Pattern Scan

**Mark task in_progress.**

### Crypto mining indicators
```
Grep for: "coinhive|cryptonight|stratum\+tcp|xmrig|minero|hashrate|CoinImp|JSEcoin"
Grep for: "monero|mining\.pool|pool\.minergate"
```

### Reverse shell patterns
```
Grep for: "/bin/sh\s*-i|/bin/bash\s*-i|bash\s*-c.*>/dev/tcp"
Grep for: "socket\.connect.*\bshell\b|pty\.spawn|spawn.*\/bin\/(sh|bash)"
Grep for: "nc\s+-e\s+/bin|ncat.*-e|netcat.*-e"
```

### Data exfiltration
```
Grep for: "process\.env|os\.environ|os\.getenv" combined with network calls nearby
Grep for: "\.ssh/|\.aws/|\.gnupg/|\.npmrc|\.pypirc|\.netrc"
Grep for: "readFileSync.*\.env|open\(.*\.env"
Grep for: "keychain|credential|password.*file|token.*file"
```

### Backdoor patterns
```
Grep for: "child_process.*exec|spawn\s*\(.*sh|shell.*exec"
Grep for: "os\.system|subprocess.*shell=True"
Grep for: "setInterval.*fetch|setTimeout.*fetch" (periodic beaconing)
Grep for: "webhook.*discord|webhook.*slack" with env/credential access nearby
```

### File system manipulation
```
Grep for: "fs\.writeFileSync.*(/etc/|/usr/|/tmp/|~\/|%APPDATA%)"
Grep for: "chmod.*777|chmod.*\\+x"
Grep for: "\.bashrc|\.bash_profile|\.zshrc|\.profile" (shell config modification)
Grep for: "crontab|/etc/cron"
```

**For each hit, read surrounding context (±10 lines) to determine if legitimate.**

Record all findings.

**Mark task completed.**

---

## Step 8: Secrets Detection

**Mark task in_progress.**

### API keys and tokens
```
Grep for: "(api[_-]?key|apikey|api[_-]?secret)\s*[:=]\s*['\"][A-Za-z0-9]" -i
Grep for: "(access[_-]?token|auth[_-]?token|bearer)\s*[:=]\s*['\"][A-Za-z0-9]" -i
Grep for: "sk[-_](live|test)_[A-Za-z0-9]{20,}" (Stripe keys)
Grep for: "AKIA[0-9A-Z]{16}" (AWS access keys)
Grep for: "ghp_[A-Za-z0-9]{36}" (GitHub tokens)
Grep for: "xox[bpras]-[A-Za-z0-9-]+" (Slack tokens)
```

### Passwords and credentials
```
Grep for: "(password|passwd|pwd)\s*[:=]\s*['\"][^'\"]{4,}" -i
Grep for: "(secret|private[_-]?key)\s*[:=]\s*['\"][^'\"]{8,}" -i
```

### Private keys
```
Grep for: "-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"
Grep for: "-----BEGIN PGP PRIVATE KEY BLOCK-----"
```

**Exclusions:** Skip hits in:
- `.env.example`, `.env.sample`, `.env.template` (placeholder values)
- Test/fixture files with obviously fake values (`test123`, `password`, `xxx`)
- Documentation files showing examples

Record genuine findings as CRITICAL.

**Mark task completed.**

---

## Step 9: File System Anomalies

**Mark task in_progress.**

### Hidden files (beyond standard)
```bash
find TARGET -name ".*" -not -name ".git" -not -name ".gitignore" -not -name ".gitattributes" -not -name ".github" -not -name ".env*" -not -name ".eslintrc*" -not -name ".prettierrc*" -not -name ".editorconfig" -not -name ".npmrc" -not -name ".nvmrc" -not -name ".node-version" -not -name ".python-version" -not -name ".ruby-version" -not -name ".tool-versions" -not -name ".vscode" -not -name ".idea" -not -name ".DS_Store" -not -name ".husky" -not -name ".changeset" -not -name ".turbo" -not -name ".next" -not -name ".nuxt" -not -name ".svelte-kit" -not -name ".vercel" -not -name ".netlify" -not -name ".dockerignore" -not -name ".browserslistrc" -not -name ".babelrc*" -not -name ".swcrc" -not -name ".postcssrc*" -not -name ".stylelintrc*" -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.next/*" -type f 2>/dev/null
```

### Binary files in source
```bash
find TARGET -type f \( -name "*.exe" -o -name "*.dll" -o -name "*.so" -o -name "*.dylib" -o -name "*.bin" -o -name "*.dat" -o -name "*.pyc" -o -name "*.class" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
```

### Unusual permissions
```bash
find TARGET -type f -perm +111 -not -path "*/.git/*" -not -path "*/node_modules/*" -not -name "*.sh" -not -name "gradlew" -not -name "mvnw" 2>/dev/null
```

Flag unexpected hidden files, binaries in source directories, and files with unusual executable permissions.

**Mark task completed.**

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

## HIGH Findings
[...]

## MEDIUM Findings
[...]

## LOW Findings
[...]

## Informational
[...]

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

- **PASS**: Zero CRITICAL or HIGH findings
- **CAUTION**: Zero CRITICAL, but has HIGH findings that may be false positives
- **FAIL**: Any CRITICAL findings, or multiple confirmed HIGH findings

### Output Location

Save report to:
```
docs/scans/YYYY-MM-DD-<repo-name>.md
```

---

## Step 11: Present Results

Display the Executive Summary and any CRITICAL/HIGH findings directly to the user.

If verdict is **FAIL**:
> "This repository has critical security findings. Review the full report before using this code."

If verdict is **CAUTION**:
> "This repository has some concerning findings that may be false positives. Review the flagged items."

If verdict is **PASS**:
> "No critical issues detected. The full report is saved for reference."

---

## Principles

### Assume hostile until proven safe
- This tool exists to vet untrusted code. Default to suspicion.
- Better to flag a false positive than miss a real threat.

### Context over pattern matching
- Always read surrounding code before classifying a finding.
- `eval()` in a test helper is different from `eval()` decoding a base64 blob.

### Don't touch the code
- This is a **read-only** scan. Never modify the repo being scanned.
- The report documents findings — the user decides what to do.

### Be specific
- Every finding must include: file path, line number, evidence (the actual code), and why it's suspicious.
- Vague warnings are useless. Show the code.
