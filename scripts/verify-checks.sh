#!/bin/bash
# Deterministic verification runner — detects applicable checks, runs them
# concurrently, prints per-check verdicts with failure log tails.
# Exit 0 = all detected checks pass; exit 1 = failures (details printed).
# Lint runs WITHOUT autofix here — nothing may mutate files while tests run.
set -uo pipefail
DIR=/tmp/pasiv-verify
rm -rf "$DIR" && mkdir -p "$DIR"
NAMES=()

# Task's changed file set (committed-vs-base + staged + unstaged). Lint is
# scoped to these so pre-existing issues in files the task never touched can
# never enter the gate — and therefore never provoke an out-of-scope "fix".
BASE=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null || true)
CHANGED=$( { git diff --name-only ${BASE:+"$BASE"}; git diff --name-only; git diff --name-only --cached; } 2>/dev/null | sort -u | grep -v '^$' || true)

runsh() { local name=$1 cmd=$2; NAMES+=("$name"); { bash -c "$cmd"; echo "exit:$?"; } > "$DIR/$name.log" 2>&1 & }

# --- tests ---
if [ -f package.json ] && grep -q '"test"' package.json; then runsh tests "npm test"
elif [ -f pytest.ini ] || [ -f pyproject.toml ]; then runsh tests "pytest"
elif [ -f go.mod ]; then runsh tests "go test ./..."
elif [ -f Cargo.toml ]; then runsh tests "cargo test"
elif [ -f Package.swift ]; then runsh tests "swift test"
elif [ -f build.gradle ] || [ -f build.gradle.kts ]; then runsh tests "./gradlew test"
elif [ -f pom.xml ]; then runsh tests "mvn -q test"
fi

# --- build ---
if [ -f package.json ] && grep -q '"build"' package.json; then runsh build "npm run build"
elif [ -f go.mod ]; then runsh build "go build ./..."
elif [ -f Cargo.toml ]; then runsh build "cargo build"
elif [ -f Package.swift ]; then runsh build "swift build"
fi

# --- lint (no autofix) ---
if [ -f package.json ] && grep -q '"lint"' package.json; then runsh lint "npm run lint"
elif [ -f go.mod ] && command -v golangci-lint >/dev/null; then runsh lint "golangci-lint run"
elif [ -f Cargo.toml ]; then runsh lint "cargo clippy"
elif command -v swiftlint >/dev/null && { [ -f .swiftlint.yml ] || [ -f Package.swift ]; }; then
  SWIFT_CHANGED=$(printf '%s\n' "$CHANGED" | grep '\.swift$' | tr '\n' ' ')
  # Only lint the task's own changed .swift files. No changed swift → no lint
  # check (nothing in this task could have broken it); never lint repo-wide.
  [ -n "${SWIFT_CHANGED// /}" ] && runsh lint "swiftlint --strict --quiet $SWIFT_CHANGED"
fi

# --- typecheck ---
if [ -f tsconfig.json ]; then
  if [ -f package.json ] && grep -q '"typecheck"' package.json; then runsh typecheck "npm run typecheck"
  else runsh typecheck "npx tsc --noEmit"; fi
elif [ -f pyproject.toml ] && grep -q 'mypy' pyproject.toml; then runsh typecheck "mypy ."
fi

# --- smoke (.pasiv.yml verify.command) ---
SMOKE=$(awk '/^verify:/{s=1;next} /^[A-Za-z_]+:/{s=0} s && $1=="command:"{sub(/^[^:]*: */,""); gsub(/^"|"$/,""); print; exit}' .pasiv.yml 2>/dev/null || true)
[ -n "${SMOKE:-}" ] && runsh smoke "$SMOKE"

wait

if [ ${#NAMES[@]} -eq 0 ]; then echo "⚠ no checks detected"; echo "PASIV_VERIFY_RESULT=NONE"; exit 0; fi

FAIL=0
for n in "${NAMES[@]}"; do
  code=$(tail -1 "$DIR/$n.log" | sed -n 's/^exit://p')
  if [ "$code" = "0" ]; then
    echo "✓ $n (exit 0)"
  else
    FAIL=1
    echo "✗ $n (exit ${code:-unknown}) — full log: $DIR/$n.log"
    tail -30 "$DIR/$n.log" | sed 's/^/    /'
  fi
done
[ "$FAIL" = "0" ] && echo "PASIV_VERIFY_RESULT=PASS" || echo "PASIV_VERIFY_RESULT=FAIL"
exit $FAIL
