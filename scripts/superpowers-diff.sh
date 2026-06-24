#!/usr/bin/env bash
#
# superpowers-diff.sh — show what changed upstream in the community Superpowers
# fork since you last looked, so you can decide what (if anything) to pull into
# PASIV. Manual and read-only: it never touches PASIV's own files.
#
# It clones the chosen repo into a gitignored cache (.cache/superpowers/), fetches
# on later runs, and diffs the current upstream tip against the SHA you last marked
# "reviewed". Triage the output, then run --seen to advance the marker.
#
# Usage:
#   scripts/superpowers-diff.sh            # commits + changed skills since last seen
#   scripts/superpowers-diff.sh --skills   # also list upstream skills vs PASIV's (gap view)
#   scripts/superpowers-diff.sh --seen     # mark the current upstream tip as reviewed
#
# Env:
#   REPO=owner/name   # which fork to track (default: pcvelz/superpowers)
#                     # e.g. REPO=obra/superpowers to diff the original upstream
#
set -euo pipefail

REPO="${REPO:-pcvelz/superpowers}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SLUG="${REPO//\//_}"
CACHE="$ROOT/.cache/superpowers/$SLUG"
SEEN_FILE="$ROOT/scripts/.superpowers-seen"   # tracked: "owner/name <sha>" per line

c_bold=$'\033[1m'; c_dim=$'\033[2m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_rst=$'\033[0m'

note() { printf '%s\n' "$*"; }
hdr()  { printf '\n%s%s%s\n' "$c_bold" "$*" "$c_rst"; }

# --- ensure cache is present and current ---------------------------------------
if [[ ! -d "$CACHE/.git" ]]; then
  note "${c_dim}Cloning $REPO into cache (first run)…${c_rst}"
  mkdir -p "$(dirname "$CACHE")"
  git clone --quiet "https://github.com/$REPO.git" "$CACHE"
else
  git -C "$CACHE" fetch --quiet origin
fi

# default branch of the remote (fallback: main)
BRANCH="$(git -C "$CACHE" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null \
          | sed 's@^origin/@@')" || true
BRANCH="${BRANCH:-main}"
TIP="$(git -C "$CACHE" rev-parse "origin/$BRANCH")"

# previously-seen sha for this repo
SEEN="$(grep -E "^$REPO " "$SEEN_FILE" 2>/dev/null | awk '{print $2}' | tail -1 || true)"

# --- --seen: record the current tip and exit -----------------------------------
if [[ "${1:-}" == "--seen" ]]; then
  mkdir -p "$(dirname "$SEEN_FILE")"
  tmp="$(mktemp)"
  grep -vE "^$REPO " "$SEEN_FILE" 2>/dev/null > "$tmp" || true
  printf '%s %s\n' "$REPO" "$TIP" >> "$tmp"
  mv "$tmp" "$SEEN_FILE"
  note "${c_grn}Marked $REPO @ ${TIP:0:10} as reviewed.${c_rst}"
  exit 0
fi

note "${c_bold}Upstream:${c_rst} $REPO  ${c_dim}(branch $BRANCH, tip ${TIP:0:10})${c_rst}"

# guard: seen sha may be absent from history (force-push / first run)
have_seen=0
if [[ -n "$SEEN" ]] && git -C "$CACHE" cat-file -e "${SEEN}^{commit}" 2>/dev/null; then
  have_seen=1
fi

if [[ "$have_seen" -eq 0 ]]; then
  hdr "No reviewed baseline yet."
  note "Run '${c_bold}scripts/superpowers-diff.sh --seen${c_rst}' to set the current tip as your baseline."
  note "Future runs will then show only what's new."
elif [[ "$SEEN" == "$TIP" ]]; then
  hdr "Up to date — nothing new since ${SEEN:0:10}."
else
  hdr "Commits since ${SEEN:0:10}:"
  git -C "$CACHE" log --oneline --no-decorate "$SEEN..$TIP"

  hdr "Changed files in skills/ commands/ hooks/:"
  git -C "$CACHE" diff --stat "$SEEN..$TIP" -- skills commands hooks || note "(none)"

  hdr "New skills:"
  git -C "$CACHE" diff --name-status "$SEEN..$TIP" -- skills \
    | awk '$1=="A" && $2 ~ /SKILL\.md$/ {print "  '"$c_grn"'+ "$2"'"$c_rst"'"}' || true

  hdr "Modified skills:"
  git -C "$CACHE" diff --name-status "$SEEN..$TIP" -- skills \
    | awk '$1=="M" && $2 ~ /SKILL\.md$/ {print "  '"$c_yel"'~ "$2"'"$c_rst"'"}' || true

  note ""
  note "${c_dim}When you've triaged these, run --seen to advance the marker.${c_rst}"
fi

# --- --skills: gap view (upstream skills vs PASIV's) ---------------------------
if [[ "${1:-}" == "--skills" ]]; then
  hdr "Upstream skills (name — lines):"
  while IFS= read -r f; do
    n="$(basename "$(dirname "$f")")"
    lines="$(wc -l < "$CACHE/$f" | tr -d ' ')"
    if [[ -d "$ROOT/skills/$n" ]]; then
      printf '  %-40s %5s  %s(also in PASIV)%s\n' "$n" "$lines" "$c_dim" "$c_rst"
    else
      printf '  %-40s %5s  %snot in PASIV (by name)%s\n' "$n" "$lines" "$c_yel" "$c_rst"
    fi
  done < <(cd "$CACHE" && git ls-files 'skills/*/SKILL.md')
  note "${c_dim}Name-match only — different names may still overlap conceptually.${c_rst}"
fi
