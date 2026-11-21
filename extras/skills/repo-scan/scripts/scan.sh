#!/usr/bin/env bash
# repo-scan pattern pass. Reads files only: never installs, builds, imports or
# executes anything from TARGET. One run prints every pattern group with a hit
# count, the busiest files, and the first few hits, so the reviewer reads
# context only where there is something to read.
#
# Usage: scan.sh TARGET
# Env:   SCAN_MAX_HITS  hits shown per group (default 12)
# Exit:  0 scan ran, 2 could not scan

set -u
TARGET="${1:-.}"
MAX="${SCAN_MAX_HITS:-12}"
cd "$TARGET" 2>/dev/null || { echo "scan: no such directory: $TARGET" >&2; exit 2; }
command -v rg >/dev/null 2>&1 || { echo "scan: ripgrep (rg) not installed" >&2; exit 2; }

# Every group below needs PCRE2; without it rg -P fails and would read as "0 hits".
echo ab | rg -q -P 'a(?=b)' 2>/dev/null || { echo "scan: this rg build has no PCRE2 support (rg -P)" >&2; exit 2; }
command -v perl >/dev/null 2>&1 || { echo "scan: perl not installed" >&2; exit 2; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
LIST="$T/list"; SAFE="$T/safe"; CODE="$T/code"; LINKS="$T/links"; HITS="$T/hits"; IGN="$T/ignored"

# ---- file list -------------------------------------------------------------
# A .git directory that arrived in an archive can carry config that runs code
# on ordinary git commands. Read it as text first; only use git if it is plain.
GIT_OK=0
if [ -d .git ]; then
  if rg -q -i -P '^\s*fsmonitor\s*=\s*(?!(true|false)\s*$)|^\s*\[(filter|diff|merge|include|includeIf)\b|textconv|^\s*(sshCommand|askpass|pager|editor|gitProxy)\s*=' .git/config 2>/dev/null; then
    echo "GIT: untrusted config - .git/config defines commands (shown under AUTOEXEC). Not running git in this repo."
  else
    GIT_OK=1
  fi
fi
if [ $GIT_OK -eq 1 ]; then
  # Tracked plus untracked-not-ignored. A file that is tracked AND gitignored
  # stays in the list, so .gitignore cannot be used to hide one.
  if git -c core.quotepath=off ls-files -co --exclude-standard > "$LIST" 2>/dev/null && [ -s "$LIST" ]; then
    echo "GIT: file list from git ($(wc -l < "$LIST" | tr -d ' ') files)"
    odd=$(grep -c '^"' "$LIST"); [ "$odd" -gt 0 ] && echo "ANOMALY: $odd filenames with quotes or control characters, NOT scanned by the pattern groups (git ls-files | grep '^\"')"
  else
    # git refused (ownership, corruption) or listed nothing: never report an empty scan as clean.
    echo "GIT: git could not list this repo, walking the directory instead"
    GIT_OK=0
  fi
fi
if [ $GIT_OK -eq 0 ]; then
  rg --files --no-ignore --hidden -g '!.git/' -g '!node_modules/' > "$LIST" 2>/dev/null
  echo "GIT: walked the directory ($(wc -l < "$LIST" | tr -d ' ') files)"
fi
if [ ! -s "$LIST" ]; then echo "scan: no files found under $TARGET - nothing was scanned" >&2; exit 2; fi
# Never read through a symlink: a link to ~/.ssh or /etc, or a directory
# swapped for a link, would pull files from outside TARGET into the output.
# drop_links FILE: paths with no symlink in them go to stdout, the links to $LINKS.
drop_links() {
  perl -ne 'chomp; my ($q,$bad)=("",0);
    for my $c (split m{/}) { $q = length($q) ? "$q/$c" : $c;
      $l{$q} = (-l $q ? 1 : 0) unless exists $l{$q};
      if ($l{$q}) { print STDERR "$q\n" unless $seen{$q}++; $bad=1; last } }
    print "$_\n" unless $bad' "$1" 2>> "$LINKS"
}
: > "$LINKS"
drop_links "$LIST" > "$SAFE"
find . -type l -not -path './.git/*' -not -path '*/node_modules/*' 2>/dev/null | sed 's#^\./##' >> "$LINKS"
sort -u -o "$LINKS" "$LINKS"

# Lockfiles, source maps and media are left out of the code patterns. Media is
# excluded by extension, so FILES checks that each one really is what its
# extension says. Minified files and SVG stay in: both can carry a payload.
MEDIA='\.(png|jpe?g|gif|webp|ico|icns|pdf|woff2?|ttf|otf|eot|mp[34]|mov|webm|wav)$'
NOISE='(^|/)(package-lock\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|Cargo\.lock|Gemfile\.lock|composer\.lock|poetry\.lock|uv\.lock|go\.sum|Package\.resolved|pubspec\.lock)$|\.map$|'"$MEDIA"
grep -vE "$NOISE" "$SAFE" > "$CODE"
SCOPE="$CODE"

# ---- helpers ---------------------------------------------------------------
# grp MODE LABEL PATTERN [FILE_FILTER_REGEX]
#   MODE hits  = count + first $MAX hits        MODE files = count + busiest files only
grp() {
  local mode="$1" label="$2" pat="$3" filter="${4:-}" n f
  if [ -n "$filter" ]; then grep -E "$filter" "$SCOPE"; else cat "$SCOPE"; fi \
    | tr '\n' '\0' | xargs -0 rg -H -n -P --no-heading --color never --no-messages -M 180 --max-columns-preview -e "$pat" -- /dev/null > "$HITS" 2>/dev/null
  n=$(wc -l < "$HITS" | tr -d ' ')
  if [ "$n" -eq 0 ]; then echo "-- $label: 0"; return; fi
  f=$(cut -d: -f1 "$HITS" | sort -u | wc -l | tr -d ' ')
  echo "-- $label: $n hits in $f files"
  if [ "$mode" = files ] || [ "$n" -gt "$MAX" ]; then
    cut -d: -f1 "$HITS" | sort | uniq -c | sort -rn | head -8 | sed 's/^/     /'
  fi
  [ "$mode" = hits ] && head -n "$MAX" "$HITS" | sed 's/^/   /'
  [ "$mode" = hits ] && [ "$n" -gt "$MAX" ] && echo "   ... $((n - MAX)) more (Grep the pattern to see them)"
}
# names LABEL REGEX : list files whose path matches
names() {
  local out; out=$(grep -E "$2" "$LIST")
  if [ -z "$out" ]; then echo "-- $1: 0"; return; fi
  echo "-- $1: $(printf '%s\n' "$out" | wc -l | tr -d ' ')"
  printf '%s\n' "$out" | head -40 | sed 's/^/   /'
}

SRC='\.(js|jsx|ts|tsx|mjs|cjs|py|rb|rs|go|php|sh|bash|zsh|java|kt|swift|pl|lua|ps1)$'

# ---- STEP 4: code that runs at install or build ------------------------------
echo; echo "== INSTALL =="
grp hits "npm lifecycle scripts" '"(preinstall|install|postinstall|preuninstall|postuninstall|prepare|prepublish|prepublishOnly|prepack|postpack)"\s*:' '(^|/)package\.json$'
names "build-time code (runs on install/build)" '(^|/)(binding\.gyp|build\.rs|setup\.py|extconf\.rb|conftest\.py|[^/]*\.pth|Makefile|justfile|Taskfile\.ya?ml|\.pnpmfile\.cjs)$'
grp hits "pipe to shell" '(curl|wget|iwr|Invoke-WebRequest)[^|\n]*\|\s*(sudo\s+)?((ba|z|da)?sh|python3?|node|iex)\b'
grp hits "registry override or token" 'registry\s*=|_authToken|always-auth|--(extra-)?index-url|trusted-host' '(^|/)(\.npmrc|\.yarnrc(\.yml)?|pip\.conf|requirements[^/]*\.txt|\.pypirc)$'
grp hits "non-registry dependency in a manifest" '"[^"]+"\s*:\s*"(git\+|git://|github:|https?://|file:)' '(^|/)package\.json$'
grp hits "pip dependency from git or URL" '^\s*(-e\s+)?(git\+|https?://)' '(^|/)requirements[^/]*\.txt$'
if [ -s "$SAFE" ]; then
  n=$(grep -E '(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml)$' "$SAFE" | tr '\n' '\0' | xargs -0 rg -c -P --no-messages '"?resolved"?:?\s*"?(?!https://registry\.(npmjs\.org|yarnpkg\.com)/)https?://|tarball:\s*(?!https://registry\.npmjs\.org/)https?://' -- /dev/null 2>/dev/null | awk -F: '{s+=$NF} END{print s+0}')
  echo "-- lockfile entries resolved outside the npm registry: $n"
fi
if [ -d node_modules ] && [ ! -L node_modules ]; then
  rg -l --no-ignore --no-messages -g 'package.json' '"(preinstall|install|postinstall)"\s*:' node_modules > "$HITS" 2>/dev/null
  echo "-- installed packages with install scripts: $(wc -l < "$HITS" | tr -d ' ')"
  sed -E 's#/package\.json$##' "$HITS" | head -40 | sed 's/^/   /'
fi

# ---- STEP 5: obfuscation ---------------------------------------------------
echo; echo "== OBFUSCATION =="
grp hits "eval / Function constructor" '\beval\s*\(|\bnew\s+Function\b|\bFunction\s*\(\s*[\x27"`]'
grp hits "decode then execute" '(eval|exec|Function)\s*\(.*(atob|decode|unescape|fromCharCode|b64)|document\.write\s*\(.*unescape'
grp files "decoders" 'atob\s*\(|Buffer\.from\s*\([^)]*[\x27"](base64|hex)|b(ase)?64\.?(b64)?decode|fromCharCode|unescape\s*\(|String\.raw'
grp hits "hex/unicode escape runs" '(\\x[0-9a-fA-F]{2}){3,}|(\\u[0-9a-fA-F]{4}){3,}'
grp hits "python dynamic exec" '\bexec\s*\(|__import__\s*\(|compile\s*\(.*exec|marshal\.loads|pickle\.loads' '\.py$'
grp hits "long base64-like string" '[A-Za-z0-9+/]{120,}={0,2}'
grp hits "long hex literal" '0x[0-9a-fA-F]{24,}'
grp files "source line over 1000 chars" '.{1000,}' "$SRC"
grp hits "code pushed off-screen by whitespace" '\S[ \t]{120,}\S' "$SRC"

# ---- unicode tricks --------------------------------------------------------
echo; echo "== UNICODE =="
grp hits "bidi control characters (Trojan Source)" '[\x{202A}-\x{202E}\x{2066}-\x{2069}]'
grp hits "zero-width characters" '[\x{200B}\x{200C}\x{2060}]|\x{200D}(?![\x{1F000}-\x{1FAFF}\x{2600}-\x{27BF}])|.\x{FEFF}'
grp hits "invisible tag / variation-selector characters" '[\x{E0000}-\x{E007F}\x{E0100}-\x{E01EF}]'

# ---- STEP 6: network -------------------------------------------------------
echo; echo "== NETWORK =="
tr '\n' '\0' < "$CODE" | xargs -0 rg -o -I -N --no-messages 'https?://[^\s"\x27`<>)\]]+' -- /dev/null 2>/dev/null \
  | grep -E '^https?://' | sed -E 's#^https?://([^/:?\#@]*@)?([^/:?\#]+).*#\2#' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn > "$HITS"
echo "-- distinct URL hosts: $(wc -l < "$HITS" | tr -d ' ') (count host)"
head -60 "$HITS" | sed 's/^/   /'
[ "$(wc -l < "$HITS")" -gt 60 ] && echo "   ... rarest hosts:" && tail -20 "$HITS" | sed 's/^/   /'
echo "-- hosts on watch-list TLDs or exfil/tunnel services:"
grep -E '\.(ru|cn|tk|ml|ga|cf|gq|xyz|top|buzz|club|icu|pw|su|zip|mov)$|pastebin|hastebin|ngrok|trycloudflare|webhook\.site|requestbin|pipedream|interact\.sh|oast\.|burpcollaborator|transfer\.sh|discord(app)?\.com|hooks\.slack\.com|api\.telegram\.org|ipinfo\.io|ifconfig\.|icanhazip' "$HITS" | sed 's/^/   /'
tr '\n' '\0' < "$CODE" | xargs -0 rg -o -I -N --no-messages '\b(?:\d{1,3}\.){3}\d{1,3}\b(?::\d{2,5})?' -- /dev/null 2>/dev/null \
  | grep -vE '^(127\.0\.0\.1|0\.0\.0\.0|255\.255\.255\.[0-9]+)(:|$)' | sort | uniq -c | sort -rn > "$HITS"
echo "-- distinct hardcoded IPs: $(wc -l < "$HITS" | tr -d ' ')"
head -30 "$HITS" | sed 's/^/   /'
grp hits "URL built at runtime" '[\x27"`]https?://[^\x27"`\s]*[\x27"`]\s*\+|[\x27"`]https?://(\$\{|\{[a-z_]+\}|%s)|\bf[\x27"]https?://\{'
grp files "network calls" '\bfetch\s*\(|axios[.(]|https?\.(request|get)\s*\(|urllib|requests\.(get|post|put|delete|patch)|XMLHttpRequest|WebSocket\s*\(|net\.connect|dgram\.|dns\.(resolve|lookup)|URLSession|http\.(Get|Post)\('
grp files "process spawning" 'child_process|subprocess\.(run|call|Popen|check_output)|os\.(system|popen)|Runtime\.getRuntime|exec\.Command|Process\(\)|\bspawn(Sync)?\s*\('

# ---- STEP 7: malware -------------------------------------------------------
echo; echo "== MALWARE =="
grp hits "crypto mining" '(?i)coinhive|cryptonight|stratum\+tcp|xmrig|minero|CoinImp|JSEcoin|mining\.pool|pool\.minergate|\bmonero\b'
grp hits "reverse shell" '/bin/(ba|z)?sh\s+-i|>&?\s*/dev/tcp/|pty\.spawn|\bn(c|cat|etcat)\b.*\s-e\s|socket\.connect.*shell|mkfifo\s.*\bnc\b|bash\s+-c\s.*base64\s+-d'
grp hits "credential and wallet paths" '\.ssh/|id_(rsa|ed25519)|\.aws/|\.gnupg/|\.npmrc|\.pypirc|\.netrc|\.kube/config|\.docker/config\.json|\.config/gcloud|Login Data|Local State|wallet\.dat|keychain|\.claude(\.json|/)|\.codex/|authorized_keys'
grp hits "environment harvesting" 'JSON\.stringify\(\s*process\.env\s*\)|Object\.(keys|entries|values)\(\s*process\.env\s*\)|os\.environ\.(copy|items)\(\)|dict\(os\.environ\)|readFileSync\([^)]*\.env|open\([^)]*\.env'
grp hits "shell execution" 'subprocess.*shell\s*=\s*True|child_process[^\n]*exec|spawn(Sync)?\s*\(\s*[\x27"](ba|z)?sh\b|os\.system\('
grp hits "beaconing" 'setInterval\s*\([^\n]*(fetch|request|axios)|setTimeout\s*\([^\n]*(fetch|request|axios)|while\s+True[^\n]*requests\.'
grp hits "persistence and system writes" '\.(bashrc|bash_profile|zshrc|zprofile|profile)\b|crontab|/etc/cron|Launch(Agents|Daemons)|systemctl\s+enable|chmod\s+(777|\+x)|writeFile(Sync)?\([^)]*(/etc/|/usr/|/tmp/|~/|%APPDATA%)'

# ---- auto-execution surface ------------------------------------------------
echo; echo "== AUTOEXEC =="
names "files an editor, agent, shell or git acts on without being asked" '(^|/)(\.claude/|\.mcp\.json$|\.cursor/|\.cursorrules$|\.windsurf|\.vscode/(tasks|settings|launch|extensions)\.json$|\.idea/|\.devcontainer|\.envrc$|\.husky/|\.githooks/|lefthook\.ya?ml$|\.pre-commit-config\.yaml$|\.gitattributes$|\.gitmodules$|\.npmrc$|\.yarnrc|mise\.toml$|\.mise\.toml$|\.tool-versions$|(CLAUDE|AGENTS|GEMINI)\.md$|\.github/copilot-instructions\.md$)'
grp hits "VS Code task on folder open" '"runOn"\s*:\s*"folderOpen"|"task\.allowAutomaticTasks"'
grp hits "agent hooks and MCP commands" '"(hooks|command|args|url)"\s*:' '(^|/)(\.claude/[^/]*\.json|\.mcp\.json|\.cursor/[^/]*\.json)$'
grp hits "devcontainer lifecycle commands" '"(postCreate|postStart|postAttach|onCreate|initialize|updateContent)Command"'
grp hits "gitattributes drivers" '\b(filter|diff|merge)=' '(^|/)\.gitattributes$'
grp hits "submodule URLs" '^\s*url\s*=' '(^|/)\.gitmodules$'
grp hits "instructions aimed at an AI agent" '(?i)ignore (all |any )?(previous|prior|above|earlier) (instructions|rules)|disregard (the|your|all|any) (previous|above|instructions)|you are now\b|do not (tell|mention|reveal|inform) (this |it )?(to )?the user|</?system>|(always|must|silently) (run|execute)[^\n]{0,40}(curl|wget|bash|sh\b|npx|pip)'
grp hits "Actions: fork-triggered with secrets" 'pull_request_target|workflow_run' '(^|/)\.github/workflows/'
grp hits "Actions: untrusted event text outside an env: mapping (injection when inside run: or script:)" '^(?!\s*(-\s*)?([A-Z_][A-Z0-9_]*|if)\s*:).*\$\{\{[^}]*github\.(head_ref|event\.[a-z_.]*(title|body|ref|label|message|name|email|head_branch))' '(^|/)\.github/(workflows|actions)/'
grp hits "Actions: third-party action not pinned to a SHA" 'uses:\s*(?!actions/|github/|\./)[^@\s]+@(?![0-9a-f]{40}\b)' '(^|/)\.github/(workflows|actions)/'
grp hits "Dockerfile: remote fetch or host access" '^\s*ADD\s+https?://|--privileged|docker\.sock|--network[= ]host' '(^|/)(Dockerfile[^/]*|[^/]*\.dockerfile|(docker-)?compose[^/]*\.ya?ml)$'
if [ -d .git ]; then
  echo "-- .git/config lines that run commands:"
  rg -n -i --no-messages 'fsmonitor|sshCommand|hooksPath|textconv|askpass|pager|editor|gitProxy|^\s*\[(filter|diff|merge|include|includeIf|alias)\b' .git/config | sed 's/^/   /'
  echo "-- active .git/hooks:"
  ls .git/hooks 2>/dev/null | grep -v '\.sample$' | sed 's/^/   /'
fi

# ---- gitignored files that are on disk anyway ------------------------------
# A normal clone has none outside dependency and build output. An archive can
# ship them, and a tracked script can run them, so they get a high-signal pass.
if [ $GIT_OK -eq 1 ]; then
  echo; echo "== IGNORED =="
  git -c core.quotepath=off ls-files -oi --exclude-standard 2>/dev/null \
    | grep -vE '(^|/)(node_modules|\.venv|venv|Pods|\.dart_tool|\.gradle|target|__pycache__)/' > "$T/ign.all"
  drop_links "$T/ign.all" | grep -vE "$NOISE" > "$IGN"
  echo "-- gitignored files on disk, outside dependency directories: $(wc -l < "$IGN" | tr -d ' ') (never committed; by top-level entry)"
  cut -d/ -f1 "$IGN" | sort | uniq -c | sort -rn | head -12 | sed 's/^/   /'
  if [ -s "$IGN" ]; then
    SCOPE="$IGN"
    grp files "ignored files that execute, decode, spawn or read the environment" '\beval\s*\(|\bnew\s+Function\b|(atob|b64decode|fromCharCode|unescape)\s*\(|child_process|subprocess\.|os\.(system|popen)|/dev/tcp/|(curl|wget)[^|\n]*\|\s*(ba|z)?sh|JSON\.stringify\(\s*process\.env|os\.environ\.(copy|items)|\.ssh/|\.aws/' "$SRC"
    SCOPE="$CODE"
  fi
fi

# ---- STEP 9: file system ---------------------------------------------------
echo; echo "== FILES =="
echo "-- hidden top-level entries (files beneath):"
grep -E '^\.' "$LIST" | cut -d/ -f1 | sort | uniq -c | sed 's/^/   /'
echo "-- binaries and archives by content (not extension):"
grep -vE "$MEDIA" "$SAFE" | tr '\n' '\0' | xargs -0 file --mime-type 2>/dev/null \
  | grep -E ': +application/(x-mach-binary|x-executable|x-pie-executable|x-sharedlib|x-dosexec|x-object|x-archive|java-archive|zip|gzip|x-tar|x-bzip2|x-xz|x-7z-compressed|wasm|x-elf|vnd\.microsoft\.portable-executable|octet-stream)$' | head -40 | sed 's/^/   /'
echo "-- media or font extension, different content:"
grep -E "$MEDIA" "$SAFE" | tr '\n' '\0' | xargs -0 file --mime-type 2>/dev/null \
  | grep -vE ': +(image|font|audio|video)/|: +application/(pdf|font-|vnd\.ms-fontobject|vnd\.ms-opentype|x-font-)|: +application/octet-stream$' | head -40 | sed 's/^/   /'
echo "-- source files with binary content (NUL bytes; patterns report these as 'binary file matches'):"
grep -E "$SRC" "$CODE" | tr '\n' '\0' | xargs -0 file --mime-encoding 2>/dev/null | grep -E ': +binary$' | head -40 | sed 's/^/   /'
echo "-- executable bit set, not a shell script:"
if [ $GIT_OK -eq 1 ]; then git ls-files -s | awk '$1=="100755"{sub(/^[^\t]*\t/,""); print}'; else find . -type f \( -perm -100 -o -perm -010 -o -perm -001 \) -not -path './.git/*' -not -path '*/node_modules/*' 2>/dev/null | sed 's#^\./##'; fi \
  | grep -vE '\.(sh|bash|zsh)$|(^|/)(gradlew|mvnw)$' | head -40 | sed 's/^/   /'
echo "-- symlinks (target):"
head -40 "$LINKS" | while IFS= read -r l; do echo "   $l -> $(readlink "$l" 2>/dev/null)"; done
echo "-- files over 5 MB (size in KB):"
tr '\n' '\0' < "$SAFE" | xargs -0 du -k 2>/dev/null | awk '$1>5000' | sort -rn | head -20 | sed 's/^/   /'
exit 0
