#!/usr/bin/env bash
# Which secrets in this repo's committed history still work?
# TruffleHog finds candidates on every branch and asks each provider whether
# the credential is valid. A live one has to be rotated before anything else.
#
# OWN REPOS ONLY. Verifying a credential means presenting it to its provider.
# Never run this on a repo you are vetting: that would be using someone
# else's leaked key.
#
# Covers committed history only. Uncommitted files are the secret gate's job.
# Secret values are never printed.
#
# Usage: live-check.sh [repo-path]        (default: current directory)
# Exit:  0 nothing verifiable found
#        1 at least one LIVE credential            -> rotate it now, hard stop
#        2 cannot run (no trufflehog, not git, scan error)
#        3 candidates found, provider could not be reached to verify them

set -u
REPO="${1:-.}"
cd "$REPO" 2>/dev/null || { echo "live-check: no such directory: $REPO" >&2; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "live-check: not a git repo" >&2; exit 2; }
TOP=$(git rev-parse --show-toplevel)
command -v trufflehog >/dev/null 2>&1 || { echo "live-check: trufflehog not installed (brew install trufflehog)" >&2; exit 2; }
command -v perl >/dev/null 2>&1 || { echo "live-check: perl not installed" >&2; exit 2; }
git -C "$TOP" rev-parse --verify -q HEAD >/dev/null || { echo "no commits yet"; exit 0; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
trufflehog git "file://$TOP" --results=verified,unknown --json --no-update > "$tmp/out" 2> "$tmp/err"
rc=$?
if [ $rc -ne 0 ]; then
  echo "live-check: trufflehog failed (exit $rc):" >&2; tail -3 "$tmp/err" >&2; exit 2
fi

# One line per finding: status, detector, file:line, commit. Raw values are dropped here.
perl -MJSON::PP -ne '
  my $d = eval { decode_json($_) } or next;
  next unless ref $d eq "HASH" && exists $d->{DetectorName};
  my $g = $d->{SourceMetadata}{Data}{Git} || {};
  printf "%s\t%s\t%s:%s\t%s\n", ($d->{Verified} ? "LIVE" : "UNVERIFIED (provider unreachable)"),
    $d->{DetectorName}, $g->{file} // "?", $g->{line} // "?", substr($g->{commit} // "?", 0, 12);
' "$tmp/out" | sort -u > "$tmp/found"

if [ ! -s "$tmp/found" ]; then echo "no live credentials found in committed history"; exit 0; fi
cat "$tmp/found"
if grep -q '^LIVE' "$tmp/found"; then
  echo "LIVE CREDENTIALS FOUND - rotate each one at its provider now, then remove it from history"
  exit 1
fi
echo "candidates found but not verified; treat them as live until checked"
exit 3
