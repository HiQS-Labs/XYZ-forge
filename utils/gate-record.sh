#!/usr/bin/env bash
# gate-record.sh — write (or refuse to write) the per-commit local gate record. (GH-509)
#
# Split out of ci-local.sh so the REFUSAL can be tested directly. Inlined, the only way to exercise a
# dirty-tree refusal was a ~15-minute full suite run, so it would have shipped asserted-by-comment —
# and "a check never observed failing is not evidence" (#419) applies to a refusal exactly as much as
# to a gate.
#
# WHAT THE RECORD MEANS: "somebody ran the whole suite against THIS commit on this machine." That is
# the day-to-day question — it lets an agent tell a verified HEAD from an unverified one without
# re-running fifteen minutes of tests on a hunch.
#
# WHAT IT DOES NOT MEAN: promotion qualification. An earlier draft of the GH-509 plan let a local
# record qualify a commit; the agy review called that circular and was right — if self-reported
# evidence satisfies the boundary, the boundary is optional and buys nothing. Promotion needs the
# hosted macOS run.
#
# Usage: utils/gate-record.sh [--repo DIR]
# Exit:  0 recorded · 3 refused (dirty tree) · 4 refused (no commit) · 2 usage

set -uo pipefail

REPO="."
SUITE_LOG=""
VERDICTS=""
while (($#)); do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    # GH-536: both optional, and the record degrades honestly without them. A caller that has the
    # suite transcript passes it; anything else still gets the original six-line record rather than
    # a broken one.
    --suite-log) SUITE_LOG="${2:-}"; shift 2 ;;
    --verdicts)  VERDICTS="${2:-}";  shift 2 ;;
    -h|--help) sed -n '1,20p' "$0"; exit 0 ;;
    *) echo "gate-record: unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Resolve to absolute BEFORE the `cd "$REPO"` below, or a relative --suite-log silently resolves
# against the wrong directory and the hash is quietly omitted.
[ -n "$SUITE_LOG" ] && case "$SUITE_LOG" in /*) ;; *) SUITE_LOG="$PWD/$SUITE_LOG" ;; esac
[ -n "$VERDICTS" ]  && case "$VERDICTS"  in /*) ;; *) VERDICTS="$PWD/$VERDICTS"   ;; esac
cd "$REPO" 2>/dev/null || { echo "gate-record: no such repo: $REPO" >&2; exit 2; }

# `--verify` is load-bearing: bare `git rev-parse HEAD` in a repo with NO COMMITS prints the
# literal string "HEAD" to stdout while erroring, so the no-commit branch below never fired and this
# script cheerfully wrote `.gate-evidence/HEAD.txt`. Caught by test/gh509-gate-evidence.sh case 3.
sha="$(git rev-parse --verify HEAD 2>/dev/null || true)"
if [ -z "$sha" ]; then
  echo "gate-record: no commit to record against (not a git repo, or no commits)" >&2
  exit 4
fi

# THE REFUSAL IS THE WHOLE INTEGRITY STORY. A record keyed to a commit hash while uncommitted edits
# sit in the tree attests to a state that was never tested — worse than no record, because it reads
# as evidence. Refuse, say why, and name what made it dirty rather than leaving the operator to guess.
dirty="$(git status --porcelain 2>/dev/null | head -5)"
if [ -n "$dirty" ]; then
  echo "gate-record: REFUSED — working tree is dirty" >&2
  echo "gate-record: a record keyed to ${sha:0:8} would name a state that was never tested" >&2
  printf '%s\n' "$dirty" | sed 's/^/  /' >&2
  exit 3
fi

# GH-536: `result: green` alone is a bare assertion about output that no longer exists by the time
# anyone reads the record — a reader cannot tell "the suite ran and passed" from "someone stamped
# green". Two additions fix that, and neither changes what the record MEANS.
#
# `output-sha256` makes the record TAMPER-EVIDENT: edit the transcript afterwards and the hash stops
# matching. It deliberately does NOT make the record attested — a hash you compute on your own
# machine over output you produced proves diligence, not provenance, and someone can still stub a
# suite and hash the doctored result. That distinction is why the disclaimer below is unchanged:
# #536 argued this earns a higher trust level, and it does not. Promotion still needs the hosted run.
sha256_of() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else echo "unavailable"; fi
}

mkdir -p .gate-evidence
{
  printf 'commit: %s\n' "$sha"
  printf 'result: green\n'
  printf 'scope: full local suite (ci-local.sh, %s)\n' "$(uname -s)"
  printf 'host: %s %s\n' "$(uname -s)" "$(uname -r)"
  printf 'recorded: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [ -n "$SUITE_LOG" ] && [ -f "$SUITE_LOG" ]; then
    printf 'output-sha256: %s\n' "$(sha256_of "$SUITE_LOG")"
    printf 'output-bytes: %s\n' "$(wc -c < "$SUITE_LOG" | tr -d ' ')"
  else
    # Say so rather than omitting the field. A record missing a line reads as an older format; a
    # record that states the transcript was unavailable cannot be mistaken for one that had it.
    printf 'output-sha256: unavailable (no suite transcript passed to gate-record)\n'
  fi
  printf 'NOT-promotion-evidence: self-reported; promotion needs a hosted macOS run (GH-509)\n'
  if [ -n "$VERDICTS" ] && [ -f "$VERDICTS" ]; then
    printf 'suites: %s recorded\n' "$(grep -c . "$VERDICTS" 2>/dev/null || echo 0)"
    printf -- '--- per-suite verdicts ---\n'
    cat "$VERDICTS"
  else
    printf 'suites: not recorded (no verdict list passed to gate-record)\n'
  fi
} > ".gate-evidence/${sha}.txt"
echo "gate-record: recorded .gate-evidence/${sha:0:8}.txt"
exit 0
