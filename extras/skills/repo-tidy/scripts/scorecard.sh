#!/usr/bin/env bash
# OpenSSF Scorecard for a public GitHub repo, lowest checks first.
# Uses the scorecard CLI (fresh result, about 5 seconds, needs a GitHub token
# from gh). Without the CLI it falls back to OpenSSF's public API, which only
# knows repos in its weekly dataset and can be days old.
#
# Usage: scorecard.sh <owner>/<name>
# Exit:  0 printed a score, 2 could not get one

set -u
R="${1:-}"
case "$R" in */*) ;; *) echo "usage: scorecard.sh <owner>/<name>" >&2; exit 2 ;; esac
command -v perl >/dev/null 2>&1 || { echo "scorecard: perl not installed" >&2; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

src=""
if command -v scorecard >/dev/null 2>&1 && token=$(gh auth token 2>/dev/null) && [ -n "$token" ]; then
  GITHUB_AUTH_TOKEN="$token" scorecard --repo="github.com/$R" --format=json > "$tmp/sc.json" 2> "$tmp/err" && src="scorecard CLI"
fi
if [ -z "$src" ]; then
  code=$(curl -sS -o "$tmp/sc.json" -w '%{http_code}' "https://api.securityscorecards.dev/projects/github.com/$R" 2>/dev/null)
  [ "$code" = 200 ] && src="OpenSSF API (may be days old)"
fi
if [ -z "$src" ]; then
  echo "scorecard: no result for $R." >&2
  command -v scorecard >/dev/null 2>&1 || echo "  scorecard CLI not installed (brew install scorecard), and the repo is not in OpenSSF's public dataset" >&2
  [ -s "$tmp/err" ] && tail -2 "$tmp/err" >&2
  exit 2
fi

perl -MJSON::PP -e '
  local $/; my $d = eval { decode_json(<STDIN>) } or do { print STDERR "scorecard: unreadable output\n"; exit 2 };
  printf "Scorecard %s/10 for %s (%s, %s)\n", $d->{score}, $ARGV[0], substr($d->{date} // "", 0, 10), $ARGV[1];
  for (sort { $a->{score} <=> $b->{score} or $a->{name} cmp $b->{name} } @{ $d->{checks} || [] }) {
    printf "  %2s  %-22s %s\n", ($_->{score} < 0 ? "?" : $_->{score}), $_->{name}, substr($_->{reason} // "", 0, 100) }
' "$R" "$src" < "$tmp/sc.json"
