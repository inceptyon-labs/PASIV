#!/usr/bin/env bash
# Secret gate for a git repo. Scans everything that could be pushed:
#   1. every commit on the chosen refs, merge commits included (gitleaks)
#   2. commit messages and annotated-tag messages
#   3. what is staged, and everything else uncommitted that isn't gitignored
#   4. the files gitleaks never opens: paths on its built-in skip list
#      (lockfiles, *.svg, go.mod, node_modules/, ...) and binary files
#   5. sensitive filenames, in the tree now or anywhere in history
#   6. tracked files that .gitignore says should not be tracked
# Gitignored files that were never committed are out of scope: they don't ship.
# Secret values are never printed, and nothing is written into the repo.
#
# Usage: secret-gate.sh [repo-path]        (default: current directory)
# Env:   SECRET_GATE_BUILTIN=1   strict mode, for a public push or a repo you
#                                don't trust: shipped config only, and the
#                                repo's own suppressions (.gitleaksignore,
#                                inline "gitleaks:allow") are not honored
#        SECRET_GATE_REFS=main   scan only these refs' history (default: every
#                                ref except the stash). Use it when only one
#                                branch will be pushed; tags are then skipped.
# Exit:  0 clean
#        1 gitleaks found secrets            -> hard stop
#        2 cannot scan (no gitleaks, not git, shallow clone)
#                                            -> a hard stop before a public push
#        3 no secrets, but files to review   -> read each one before continuing

set -u
REPO="${1:-.}"
cd "$REPO" 2>/dev/null || { echo "secret-gate: no such directory: $REPO" >&2; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "secret-gate: not a git repo" >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)" || exit 2
command -v gitleaks >/dev/null 2>&1 || { echo "secret-gate: gitleaks not installed (brew install gitleaks)" >&2; exit 2; }
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
  echo "secret-gate: shallow clone, history is incomplete (git fetch --unshallow)" >&2; exit 2
fi

# A push sends the real objects, so scan those, not their refs/replace stand-ins.
export GIT_NO_REPLACE_OBJECTS=1

TOP=$(pwd)
GITDIR=$(git rev-parse --absolute-git-dir)
OBJECTS=$(cd "$(git rev-parse --git-path objects)" && pwd)
GIT="git -c core.quotepath=off"
REFS="${SECRET_GATE_REFS:---exclude=refs/stash --all}"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# A .gitattributes entry like "config.txt -diff" makes git print "Binary files
# differ" and gitleaks sees nothing. Reading attributes from the empty tree
# turns the in-repo ones off for every scan below. Needs git 2.40.
ENVV=("GIT_ATTR_SOURCE=$(git hash-object -t tree /dev/null)")
ATTR_RE='(^|[[:space:]])(-diff|binary|diff=)'
gv=$(git version | sed -E 's/[^0-9]*([0-9]+)\.([0-9]+).*/\1 \2/')
if [ "${gv% *}" -lt 2 ] || { [ "${gv% *}" -eq 2 ] && [ "${gv#* }" -lt 40 ]; }; then
  if $GIT ls-files -co --exclude-standard | grep -E '(^|/)\.gitattributes$' | tr '\n' '\0' | xargs -0 grep -qE "$ATTR_RE" -- /dev/null 2>/dev/null; then
    echo "secret-gate: .gitattributes hides files from diffs and git $(git version | cut -d' ' -f3) is too old to override it (need 2.40)" >&2; exit 2
  fi
fi

# The repo's own config if it has one, else the one this skill ships.
BUILTIN="$(cd "$(dirname "$0")/.." && pwd)/assets/gitleaks.toml"
CONFIG=".gitleaks.toml"
STRICT=()
SRC="."
if [ -n "${SECRET_GATE_BUILTIN:-}" ]; then
  CONFIG="$BUILTIN"
  # gitleaks always loads <source>/.gitleaksignore, so strict mode points it
  # at an empty directory and tells git where the repo is.
  mkdir "$tmp/src" "$tmp/noignore"
  SRC="$tmp/src"
  ENVV+=("GIT_DIR=$GITDIR" "GIT_WORK_TREE=$TOP")
  STRICT=(--ignore-gitleaks-allow --gitleaks-ignore-path "$tmp/noignore")
elif [ ! -f "$CONFIG" ]; then
  CONFIG="$BUILTIN"
fi
case "$CONFIG" in /*) ;; *) CONFIG="$TOP/$CONFIG" ;; esac
COMMON=(--config "$CONFIG" --redact --verbose --no-banner --no-color ${STRICT[@]+"${STRICT[@]}"})

leaks=0
review=0
HAS_HEAD=0; git rev-parse --verify -q HEAD >/dev/null && HAS_HEAD=1

fail() { echo "secret-gate: gitleaks failed:" >&2; printf '%s\n' "$1" | tail -5 >&2; }

# Prints one "<commit>:<file>:<rule>:<line>" per finding. Fingerprints carry no secret.
# Extra VAR=value arguments before "--" are added to gitleaks' environment.
scan_git() {
  local out rc extra=()
  while [ "$1" != "--" ]; do extra+=("$1"); shift; done; shift
  out=$(env "${ENVV[@]}" ${extra[@]+"${extra[@]}"} gitleaks git "${COMMON[@]}" "$@" "$SRC" 2>&1)
  rc=$?
  if [ $rc -ne 0 ] && ! printf '%s\n' "$out" | grep -q '^Fingerprint:'; then fail "$out"; return 2; fi
  printf '%s\n' "$out" | sed -n 's/^Fingerprint: *//p' | sort -u
}

echo "== HISTORY ($REFS) =="
if [ $HAS_HEAD -eq 1 ]; then
  # -m: diff merge commits against each parent, or a secret added while
  # resolving a merge is never shown.
  hist=$(scan_git -- --log-opts="$REFS --full-history -m") || exit 2
  if [ -n "$hist" ]; then echo "$hist"; leaks=1; else echo "clean"; fi

  echo "== COMMIT AND TAG MESSAGES =="
  # shellcheck disable=SC2086
  { git log $REFS --format=%B 2>/dev/null
    [ -n "${SECRET_GATE_REFS:-}" ] || git for-each-ref refs/tags --format='%(contents)' 2>/dev/null
  } > "$tmp/messages"
  out=$(gitleaks stdin "${COMMON[@]}" < "$tmp/messages" 2>&1); rc=$?
  if [ $rc -ne 0 ] && ! printf '%s\n' "$out" | grep -q '^RuleID:'; then fail "$out"; exit 2; fi
  msgs=$(printf '%s\n' "$out" | sed -n 's/^RuleID: *//p' | sort | uniq -c)
  if [ -n "$msgs" ]; then
    echo "$msgs"; echo "(rule and count; find it with: git log $REFS --format='%h %s%n%b', and git tag -n99 for tag messages)"; leaks=1
  else echo "clean"; fi
else
  echo "no commits yet"
fi

echo "== UNCOMMITTED (staged as-is, plus unstaged and untracked; gitignored files excluded) =="
# 1. The index exactly as it stands: this is what the next commit contains,
#    even if the working copy was cleaned up afterwards.
staged=$(scan_git -- --pre-commit --staged) || exit 2
# 2. A throwaway index with everything added, written to a throwaway object
#    store, so untracked files are scanned without touching the repo.
real_index=$(git rev-parse --git-path index)
[ -f "$real_index" ] && cp "$real_index" "$tmp/index"
mkdir "$tmp/objects"
ISO=("GIT_INDEX_FILE=$tmp/index" "GIT_OBJECT_DIRECTORY=$tmp/objects" "GIT_ALTERNATE_OBJECT_DIRECTORIES=$OBJECTS")
# Files flagged assume-unchanged or skip-worktree are passed over by "git add";
# clear the flags in the copy so an edited one is scanned like any other file.
if [ -f "$tmp/index" ]; then
  env "${ISO[@]}" git ls-files -v -z 2>/dev/null | tr '\0' '\n' | sed -n 's/^[a-zS] //p' | tr '\n' '\0' \
    | env "${ISO[@]}" git update-index --no-assume-unchanged --no-skip-worktree -z --stdin 2>/dev/null
fi
if ! err=$(env "${ISO[@]}" git add -A 2>&1); then
  echo "secret-gate: could not stage the working tree for scanning:" >&2; printf '%s\n' "$err" | tail -3 >&2; exit 2
fi
work=$(scan_git "${ISO[@]}" -- --pre-commit --staged) || exit 2
unc=$(printf '%s\n%s\n' "$staged" "$work" | grep -v '^$' | sort -u)
if [ -n "$unc" ]; then echo "$unc"; leaks=1; else echo "clean"; fi

echo "== FILES GITLEAKS DOES NOT OPEN (its built-in skip list, and binary files) =="
# gitleaks' default config never looks inside the paths below, in any mode, and
# it skips binary diffs. A token in package-lock.json, in a text file named
# logo.svg, or inside a committed binary or zip passes every scan above. Those
# files are copied out under neutral names and scanned as plain files.
# Keep SKIPPED in step with the allowlist in gitleaks' default config (checked
# against v8.30.1); a superset is fine. assets/pre-commit and
# assets/gitleaks-workflow.yml carry the same list.
SKIPPED='gitleaks\.toml|\.(bmp|gif|jpe?g|png|svg|tiff?|eot|[ot]tf|woff2?|docx?|xlsx?|pdf|bin|socket|vsidx|v2|suo|wsuo|dll|pdb|exe|gltf|gem)$|go\.(mod|sum|work(\.sum)?)$|(^|/)(node_modules|bower_components|vendor)/|(^|/)(deno\.lock|npm-shrinkwrap\.json|package-lock\.json|pnpm-lock\.yaml|yarn\.lock|pipfile\.lock|poetry\.lock|gradle\.lockfile|gradlew(\.bat)?|mvnw(\.cmd)?|javascript\.json)$|(^|/)\.mvn/wrapper/|(^|/)(angular|bootstrap|jquery(-?ui)?|plotly|swagger-?ui)[a-z0-9.-]*\.js(\.map)?$|verification-metadata\.xml|database\.refactorlog|(^|/)(v?env|virtualenv)/lib|(^|/)(lib(64)?/python[23]|python/[23])|\.dist-info(/|$)|\.min\.js(\.map)?$'
# Binary formats with nothing to grep; anything else binary is scanned.
MEDIA='\.(png|jpe?g|gif|bmp|tiff?|ico|icns|webp|heic|pdf|woff2?|ttf|otf|eot|mp[34]|m4[av]|mov|avi|mkv|webm|wav|flac|ogg|psd|sketch|fig)$'
mkdir "$tmp/skip"; : > "$tmp/skip.map"; : > "$tmp/binpaths"

# (a) text on the skip list: added lines, taken from the patch. The path comes
# from the "+++ b/<path>" header line, which is only read between "diff --git"
# and the first hunk, so a content line that starts with "++ " stays content.
collect() {   # stdin: patch text; $1: label when the stream has no commit lines; $2: file-name prefix
  awk -v re="$SKIPPED" -v dir="$tmp/skip" -v map="$tmp/skip.map" -v c="$1" -v p="$2" '
    /^commit [0-9a-f]+$/ { c = substr($2, 1, 12); keep = 0; next }
    /^diff --git /  { hdr = 1; keep = 0; next }
    hdr && /^\+\+\+ / { f = substr($0, 5); sub(/\t$/, "", f); gsub(/^"|"$/, "", f); sub(/^b\//, "", f)
                        keep = (f != "/dev/null" && tolower(f) ~ re)
                        if (keep) { if (out) close(out); n++; out = dir "/" p n ".txt"; print p n ".txt\t" c ":" f >> map }
                        next }
    hdr && /^@@ /   { hdr = 0; next }
    hdr             { next }
    keep && /^\+/   { print substr($0, 2) > out }'
}
DIFF=(-U0 --no-renames --no-color --no-ext-diff)
if [ $HAS_HEAD -eq 1 ]; then
  # shellcheck disable=SC2086
  env "${ENVV[@]}" $GIT log $REFS -p -m --full-history "${DIFF[@]}" --format='commit %H' 2>/dev/null | collect history h
  # shellcheck disable=SC2086
  env "${ENVV[@]}" $GIT log $REFS -m --full-history --no-renames --numstat --format= 2>/dev/null | sed -n 's/^-	-	//p' >> "$tmp/binpaths"
fi
env "${ENVV[@]}" $GIT diff --cached "${DIFF[@]}" 2>/dev/null | collect staged s
env "${ENVV[@]}" "${ISO[@]}" $GIT diff --cached "${DIFF[@]}" 2>/dev/null | collect uncommitted u
env "${ENVV[@]}" "${ISO[@]}" $GIT diff --cached --no-renames --numstat 2>/dev/null | sed -n 's/^-	-	//p' >> "$tmp/binpaths"

# (b) binary files that are not plain media: every version of each, as a file.
# Archives keep their extension so gitleaks can look inside them.
sort -u "$tmp/binpaths" | grep -viE "$MEDIA" > "$tmp/bin.want"
toobig=""
if [ -s "$tmp/bin.want" ]; then
  { [ $HAS_HEAD -eq 1 ] && env "${ENVV[@]}" $GIT rev-list --objects $REFS 2>/dev/null
    env "${ISO[@]}" $GIT ls-files -s 2>/dev/null | awk '{ sha = $2; sub(/^[^\t]*\t/, ""); print sha " " $0 }'
  } | awk 'NR == FNR { want[$0] = 1; next } { sha = $1; path = substr($0, length(sha) + 2) } path in want && !seen[sha]++ { print sha "\t" path }' "$tmp/bin.want" - > "$tmp/bin.blobs"
  n=0
  while IFS='	' read -r sha path; do
    size=$(env "${ISO[@]}" git cat-file -s "$sha" 2>/dev/null) || continue
    if [ "$size" -gt 52428800 ]; then toobig="$toobig$path ($((size / 1048576)) MB)"$'\n'; continue; fi
    n=$((n + 1)); ext=dat
    case "$(printf '%s' "$path" | tr 'A-Z' 'a-z')" in
      *.tar.gz|*.tgz) ext=tar.gz ;; *.zip|*.jar|*.war|*.ear|*.apk|*.ipa|*.aar|*.whl|*.nupkg|*.xpi|*.vsix) ext=zip ;;
      *.tar) ext=tar ;; *.gz) ext=gz ;; *.bz2) ext=bz2 ;; *.xz) ext=xz ;; *.7z) ext=7z ;;
    esac
    env "${ISO[@]}" git cat-file blob "$sha" > "$tmp/skip/b$n.$ext" 2>/dev/null
    printf 'b%s.%s\tbinary:%s\n' "$n" "$ext" "$path" >> "$tmp/skip.map"
  done < "$tmp/bin.blobs"
fi

skip=""
if [ -s "$tmp/skip.map" ]; then
  out=$(gitleaks dir "${COMMON[@]}" --max-archive-depth 3 "$tmp/skip" 2>&1); rc=$?
  if [ $rc -ne 0 ] && ! printf '%s\n' "$out" | grep -q '^RuleID:'; then fail "$out"; exit 2; fi
  skip=$(printf '%s\n' "$out" | awk -v map="$tmp/skip.map" '
    BEGIN { while ((getline l < map) > 0) { split(l, a, "\t"); m[a[1]] = a[2] } }
    /^RuleID:/ { r = $2 }
    /^File:/   { f = $2; inner = ""; i = index(f, "!"); if (i) { inner = " (inside: " substr(f, i + 1) ")"; f = substr(f, 1, i - 1) }
                 sub(/^.*\//, "", f); print m[f] ":" r inner }' | sort -u)
fi
if [ -n "$skip" ]; then echo "$skip"; leaks=1; else echo "clean"; fi
if [ -n "$toobig" ]; then echo "not scanned, over 50 MB:"; printf '%s' "$toobig"; review=1; fi

SENSITIVE='(^|/)(\.env(\.[^/]*)?|\.npmrc|\.pypirc|\.netrc|\.htpasswd|id_(rsa|dsa|ecdsa|ed25519)|[^/]*\.(pem|key|p12|pfx|jks|keystore|mobileprovision|tfstate|tfvars|kdbx|ovpn|har|sqlite3?|db|sql|dump)|[^/]*\.tfstate\.backup|[^/]*credentials?[^/]*\.(json|ya?ml|xml|plist|csv)|[^/]*secrets?\.[^/]+|service[-_]?account[^/]*\.json|google-services\.json|GoogleService-Info\.plist)$'
PLACEHOLDER='(^|/)\.env\.(example|sample|template|dist|defaults)$'

echo "== SENSITIVE FILENAMES (in the tree) =="
now=$($GIT ls-files -co --exclude-standard | grep -E "$SENSITIVE" | grep -vE "$PLACEHOLDER" | sort -u)
if [ -n "$now" ]; then echo "$now"; review=1; else echo "none"; fi

echo "== SENSITIVE FILENAMES (deleted, still in history) =="
# shellcheck disable=SC2086
past=$($GIT log $REFS --no-renames --diff-filter=A --name-only --format= 2>/dev/null | grep -E "$SENSITIVE" | grep -vE "$PLACEHOLDER" | sort -u)
gone=$(comm -23 <(printf '%s\n' "$past") <($GIT ls-files | sort -u) | grep -v '^$')
if [ -n "$gone" ]; then echo "$gone"; review=1; else echo "none"; fi

echo "== TRACKED BUT GITIGNORED (git rm --cached <file>) =="
ign=$($GIT ls-files -ci --exclude-standard)
if [ -n "$ign" ]; then echo "$ign"; review=1; else echo "none"; fi

if grep -qE "$ATTR_RE" "$GITDIR/info/attributes" 2>/dev/null; then
  echo "== LOCAL ATTRIBUTES =="
  echo ".git/info/attributes marks files as binary; the scans above could not read them:"
  grep -E "$ATTR_RE" "$GITDIR/info/attributes"; review=1
fi
if [ -n "$(git for-each-ref refs/replace 2>/dev/null)" ]; then
  echo "== REPLACE REFS =="
  echo "refs/replace exists. The scans above read the real objects, which is what a push sends; what you see in git log may differ."
  review=1
fi

echo "== RESULT =="
if [ $leaks -eq 1 ]; then echo "SECRETS FOUND (the sections above list where; a REVIEW section may also need reading)"; exit 1; fi
if [ $review -eq 1 ]; then echo "no secrets detected; review the files listed above"; exit 3; fi
echo "clean"
