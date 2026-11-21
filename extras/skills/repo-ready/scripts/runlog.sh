#!/usr/bin/env bash
# Run ledger for the repo-ready, repo-tidy and repo-scan skills. `start` lists
# every check the run owes and records which tools are installed. Each check is
# then recorded as it runs, or skipped with a reason. `report` prints the table
# and names every listed check that nothing recorded.
#
# Usage (call every command from the directory the skill started in; the
# ledger is keyed on it):
#   runlog.sh start  <skill> <check>... [--tools <tool>...]
#   runlog.sh ran    <check> <exit-code> [detail]   a tool command ran
#   runlog.sh done   <check> [detail]               a step with no tool finished
#   runlog.sh skip   <check> <reason>               deliberately not run
#   runlog.sh report                                every record, in check order
# Exit:  report: 0 every listed check has a record, 1 at least one has none
#        others: 0 recorded, 2 usage error, unknown check, or no ledger
# The ledger lives outside the repo, under $TMPDIR/repo-runlog/.

set -u
dir="${TMPDIR:-/tmp}"; dir="${dir%/}/repo-runlog"
here=$(pwd -P)
log="$dir/$(printf '%s' "$here" | cksum | cut -d' ' -f1).tsv"
cmd="${1:-}"; [ $# -gt 0 ] && shift

usage() { sed -n '7,16p' "$0" >&2; exit 2; }
clean() { printf '%s' "$*" | tr '\t\n' '  ' | cut -c1-120; }
need_log() {
  [ -f "$log" ] && return
  echo "runlog: no ledger for $here. Run 'runlog.sh start' first, from the directory the skill started in." >&2
  exit 2
}
need_check() {
  [ -n "${1:-}" ] || usage
  awk -F'\t' -v c="$1" '$1=="C" && $2==c {f=1} END{exit !f}' "$log" && return
  echo "runlog: '$1' is not a listed check. Listed: $(awk -F'\t' '$1=="C"{printf "%s ", $2}' "$log")" >&2
  exit 2
}

# What an exit code means for the tools these skills run. "couldn't run" is a
# command that executed but checked nothing (tool missing, no lockfile, no score).
meaning() {
  local c="$1" rc="$2"
  case "$rc" in
    127) echo "couldn't run|command not found"; return ;;
    126) echo "couldn't run|not executable"; return ;;
  esac
  case "$c:$rc" in
    secret-gate*:0) echo "ok|clean" ;;
    secret-gate*:1) echo "findings|secrets found" ;;
    secret-gate*:2) echo "couldn't run|could not scan" ;;
    secret-gate*:3) echo "findings|files to review" ;;
    live-check:0)   echo "ok|no live credentials" ;;
    live-check:1)   echo "findings|LIVE credentials" ;;
    live-check:2)   echo "couldn't run|could not run" ;;
    live-check:3)   echo "findings|candidates, unverified" ;;
    zizmor:0)       echo "ok|clean" ;;
    zizmor:3)       echo "ok|nothing to audit" ;;
    zizmor:10)      echo "findings|worst: unknown severity" ;;
    zizmor:11)      echo "findings|worst: informational" ;;
    zizmor:12)      echo "findings|worst: Low" ;;
    zizmor:13)      echo "findings|worst: Medium" ;;
    zizmor:14)      echo "findings|worst: High" ;;
    zizmor:*)       echo "couldn't run|zizmor error" ;;
    osv-scanner:0)  echo "ok|no known vulnerabilities" ;;
    osv-scanner:1)  echo "findings|vulnerabilities" ;;
    osv-scanner:128) echo "couldn't run|no lockfile, nothing checked" ;;
    osv-scanner:*)  echo "couldn't run|osv-scanner error" ;;
    pinact:0)       echo "ok|all pinned" ;;
    pinact:*)       echo "findings|unpinned actions" ;;
    hadolint:0)     echo "ok|clean" ;;
    hadolint:*)     echo "findings|lint findings" ;;
    scorecard:0)    echo "ok|scored" ;;
    scorecard:*)    echo "couldn't run|no score" ;;
    scan:0)         echo "ok|pattern pass complete" ;;
    scan:*)         echo "couldn't run|pattern pass failed" ;;
    *:0)            echo "ok|" ;;
    *)              echo "findings|exit $rc" ;;
  esac
}

case "$cmd" in
start)
  skill="${1:-}"; [ -n "$skill" ] || usage; shift
  case "${1:-}" in ''|--tools) echo "runlog: start needs at least one check" >&2; exit 2 ;; esac
  mkdir -p "$dir" || exit 2
  tmp="$log.$$"
  {
    printf 'H\tskill\t%s\n' "$(clean "$skill")"
    printf 'H\tdir\t%s\n' "$here"
    printf 'H\tstarted\t%s\n' "$(date '+%Y-%m-%d %H:%M')"
    mode=C
    for a in "$@"; do
      if [ "$a" = --tools ]; then mode=T; continue; fi
      if [ $mode = C ]; then printf 'C\t%s\n' "$(clean "$a")"; continue; fi
      if command -v "$a" >/dev/null 2>&1; then
        v=$( { "$a" --version || "$a" version; } </dev/null 2>/dev/null | grep -m1 -oE '[0-9]+(\.[0-9]+)+')
        printf 'T\t%s\t%s\n' "$a" "${v:-installed}"
      else
        printf 'T\t%s\tMISSING\n' "$a"
      fi
    done
  } > "$tmp" || { rm -f "$tmp"; exit 2; }
  mv "$tmp" "$log"
  awk -F'\t' '$1=="C"{n++} $1=="T"{t=t (t?", ":"") $2 " " $3} END{printf "runlog: %d checks listed\n", n; if (t) print "Tools: " t}' "$log"
  ;;
ran)
  need_log; need_check "${1:-}"
  case "${2:-}" in ''|*[!0-9]*) echo "runlog: exit code must be a number, got '${2:-}'" >&2; exit 2 ;; esac
  m=$(meaning "$1" "$2"); d="${m#*|}"
  [ $# -gt 2 ] && d="${d:+$d; }$(clean "${*:3}")"
  printf 'R\t%s\t%s\t%s\t%s\n' "$1" "${m%%|*}" "$2" "$d" >> "$log"
  ;;
done)
  need_log; need_check "${1:-}"
  printf 'R\t%s\tdone\t\t%s\n' "$1" "$(clean "${*:2}")" >> "$log"
  ;;
skip)
  need_log; need_check "${1:-}"
  [ $# -gt 1 ] || { echo "runlog: skip needs a reason" >&2; exit 2; }
  printf 'R\t%s\tskipped\t\t%s\n' "$1" "$(clean "${*:2}")" >> "$log"
  ;;
report)
  need_log
  awk -F'\t' '
    $1=="H" { h[$2] = $3 }
    $1=="T" { tools = tools (tools ? ", " : "") $2 " " $3 }
    $1=="C" { order[++n] = $2 }
    $1=="R" { r++; rc[r] = $2; rs[r] = $3; re[r] = $4; rd[r] = $5; last[$2] = $3 }
    END {
      printf "Run report: %s\n", h["skill"]
      printf "Dir:        %s\n", h["dir"]
      printf "Started:    %s\n", h["started"]
      if (tools) printf "Tools:      %s\n", tools
      printf "\n%-20s %-13s %-5s %s\n", "CHECK", "STATUS", "EXIT", "DETAIL"
      for (i = 1; i <= n; i++) {
        c = order[i]
        if (!(c in last)) { printf "%-20s NOT RUN\n", c; missing = missing (missing ? ", " : "") c; count["NOT RUN"]++; continue }
        name = c
        for (k = 1; k <= r; k++) if (rc[k] == c) { printf "%-20s %-13s %-5s %s\n", name, rs[k], re[k], rd[k]; name = "" }
        count[last[c]]++
      }
      printf "\n%d checks:", n; sep = " "
      split("ok findings done skipped", k1, " ")
      for (j = 1; j <= 4; j++) if (count[k1[j]]) { printf "%s%d %s", sep, count[k1[j]], k1[j]; sep = ", " }
      if (count["couldn'\''t run"]) { printf "%s%d couldn'\''t run", sep, count["couldn'\''t run"]; sep = ", " }
      if (missing) printf "%s%d NOT RUN (%s)", sep, count["NOT RUN"], missing
      print ""
      exit missing ? 1 : 0
    }' "$log"
  ;;
*) usage ;;
esac
