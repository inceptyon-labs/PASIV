# Repo-Scan Pattern Blocks

Command blocks for `/repo-scan`, keyed by step number in `SKILL.md`. Run every block in the step verbatim. `TARGET` = the scan root set in Step 0.

---

## Step 5: Obfuscated Code Detection

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

---

## Step 6: Network Call Analysis

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

---

## Step 7: Malware Pattern Scan

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

---

## Step 8: Secrets Detection

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

---

## Step 9: File System Anomalies

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
find TARGET -type f -perm /111 -not -path "*/.git/*" -not -path "*/node_modules/*" -not -name "*.sh" -not -name "gradlew" -not -name "mvnw" 2>/dev/null
```
