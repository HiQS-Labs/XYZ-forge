#!/usr/bin/env bash
# gate-status.sh — answer "is this commit verified, and is it promotable?" in one screen. (GH-509)
#
# WHY THIS EXISTS. Nothing can be a required check on this plan — `gh api .../branches/<b>/protection`
# returns `403: Upgrade to GitHub Pro or make this repository public` — so CI here is a DETECTOR, not
# a gate. PR #511 merged with `tier1=FAILURE` because nothing could stop it, and on 2026-08-12
# `development` sat red for 11 of 14 runs across ~5 hours and 8 commits with nobody reading it.
#
# A correct, cheap, loophole-free CI that nobody reads buys nothing. This is the reading surface.
#
# THE OUTPUT IS DELIBERATELY NOT A BINARY. A bare `MISMATCH` trains people to ignore the one signal
# worth protecting, because once pushes are routed the newest boundary run will legitimately trail
# HEAD most of the time. `behind` is normal working information; `red` and `none` are the states that
# actually mean "do not promote".
#
# Usage: bash utils/gate-status.sh [--no-network] [--repo DIR]
# Exit:  0 always for reporting; this is a report, not a gate. Callers read the STATUS lines.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

NO_NET=0
REPO="$ROOT"
# `--repo` exists because the first draft hardcoded `cd "$ROOT"` and therefore always reported THIS
# repo no matter where it ran — which made the whole reporting path untestable against a fixture, and
# a reporting tool nobody can test against a known state is exactly the kind of thing that quietly
# starts lying. Defaults to this clone, so ordinary use is unchanged.
while (($#)); do
  case "$1" in
    --no-network) NO_NET=1; shift ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    -h|--help) sed -n '1,20p' "$0"; exit 0 ;;
    *) echo "gate-status: unknown argument: $1" >&2; exit 2 ;;
  esac
done
cd "$REPO" 2>/dev/null || { echo "gate-status: no such repo: $REPO" >&2; exit 2; }

# `--verify`: bare `git rev-parse HEAD` prints the literal "HEAD" on stdout in a repo with no
# commits, which would have this report a commit named HEAD rather than admitting there is none.
head_sha="$(git rev-parse --verify HEAD 2>/dev/null || echo "")"
branch="$(git branch --show-current 2>/dev/null || echo "?")"
[ -n "$head_sha" ] || { echo "gate-status: not a git repo"; exit 0; }

dirty=""
[ -n "$(git status --porcelain 2>/dev/null | head -1)" ] && dirty=" (working tree DIRTY)"
printf '%s HEAD %s%s\n' "$branch" "${head_sha:0:8}" "$dirty"

# ── local evidence ───────────────────────────────────────────────────────────────────────────────
# Answers "has anyone run the whole suite against THIS commit here?" — the day-to-day question.
# Explicitly not the release question: this record is self-reported, and an earlier draft of the
# GH-509 plan that let it qualify a promotion was circular (the agy review caught it). If a
# self-reported record satisfies the boundary, the boundary is optional.
if [ -f ".gate-evidence/${head_sha}.txt" ]; then
  printf 'local full suite: VERIFIED on this commit (self-reported — not promotion evidence)\n'
else
  local_n=0
  [ -d .gate-evidence ] && local_n="$(find .gate-evidence -name '*.txt' 2>/dev/null | wc -l | tr -d ' ')"
  printf 'local full suite: not recorded for this commit (%s other commit(s) recorded) — run ./ci-local.sh\n' "$local_n"
fi

if [ "$NO_NET" -eq 1 ] || ! command -v gh >/dev/null 2>&1; then
  printf 'hosted macOS boundary: UNKNOWN (no network check requested, or gh unavailable)\n'
  printf 'portability canary (ubuntu): UNKNOWN\n'
  printf '\nstatus: unknown — cannot tell promotable from not without querying the hosted runs.\n'
  exit 0
fi

# ── hosted macOS boundary ────────────────────────────────────────────────────────────────────────
# The only evidence that qualifies a promotion: a clean machine, on the platform we ship to, and not
# produced by the person making the claim.
# THE FILTER MUST MIRROR THE JOB'S OWN `if:`, and getting this wrong is not a small bug — the first
# draft matched any successful `push` or `workflow_dispatch` run and duly reported a push to
# `development` as boundary evidence. That run executed the UBUNTU CANARY and never touched macOS, so
# the tool would have presented a Linux green as a promotion qualification: exactly the false-evidence
# class this whole issue exists to remove, produced by the tool built to prevent it.
#
# `boundary-macos` runs when: push to main. That is the whole list — `workflow_dispatch` was removed
# on 2026-08-13 after 75 macOS minutes cost $4.65 against a $10 monthly budget (see the job's own
# comment in ci.yml). A dispatch run therefore no longer contains a macOS job at all, and accepting
# one here would report an ubuntu-only run as boundary evidence — the exact false green this filter
# was written to stop, arriving from the other direction. This condition is COUPLED to the workflow's
# `if:` and test/gh509-gate-evidence.sh asserts they agree.
boundary="$(gh run list --workflow=ci.yml --json headSha,conclusion,createdAt,event,headBranch \
  --limit 60 2>/dev/null | python3 -c '
import json,sys
try: runs=json.load(sys.stdin)
except Exception: sys.exit(0)
for r in runs:
    if r.get("conclusion") != "success":
        continue
    ev, br = r.get("event"), r.get("headBranch")
    if ev == "push" and br == "main":
        print(r["headSha"], r["createdAt"], sep="\t"); break
' 2>/dev/null || true)"

if [ -z "$boundary" ]; then
  printf 'hosted macOS boundary: NONE found in the last 60 runs\n'
  status="none"
else
  b_sha="${boundary%%$'\t'*}"; b_when="${boundary##*$'\t'}"
  if [ "$b_sha" = "$head_sha" ]; then
    printf 'hosted macOS boundary: %s — EXACT match for HEAD (%s)\n' "${b_sha:0:8}" "$b_when"
    status="exact"
  else
    # DISTANCE, not just mismatch. `git rev-list --count` is the honest measure of how far the
    # evidence trails; an unrelated/unfetched SHA yields no count and is reported as such rather
    # than as zero, which would read as "current".
    dist="$(git rev-list --count "${b_sha}..${head_sha}" 2>/dev/null || echo "?")"
    printf 'hosted macOS boundary: %s — HEAD is %s commit(s) ahead (%s)\n' "${b_sha:0:8}" "$dist" "$b_when"
    status="behind"
  fi
fi

# ── portability canary ───────────────────────────────────────────────────────────────────────────
# The mechanism that makes an advisory job READ rather than merely non-blocking. agy's review of the
# GH-509 plan was right that "advisory" supplies nobody a reason to look; attaching it to the moment
# someone is already deciding is the only reliable fix.
canary="$(gh run list --workflow=ci.yml --branch "$branch" --limit 1 \
  --json conclusion,headSha -q '.[0] | "\(.conclusion)\t\(.headSha)"' 2>/dev/null || true)"
if [ -z "$canary" ] || [ "${canary%%$'\t'*}" = "null" ]; then
  printf 'portability canary (ubuntu): no run found for %s\n' "$branch"
else
  c_concl="${canary%%$'\t'*}"
  if [ "$c_concl" = "success" ]; then
    printf 'portability canary (ubuntu): green\n'
  else
    printf 'portability canary (ubuntu): DRIFT (%s) — not breakage; resolve before Linux support ships\n' "$c_concl"
  fi
fi

echo
case "$status" in
  exact) echo "status: EXACT — this commit is promotion-qualified." ;;
  behind) echo "status: BEHIND — normal for WIP. The macOS boundary now runs only on push to main (its workflow_dispatch trigger was removed for cost), so qualify locally with ./validate.sh + utils/gate-record.sh, which is self-reported and does not promote." ;;
  none) echo "status: NONE — no boundary evidence exists. Not promotable." ;;
  *) echo "status: unknown" ;;
esac
exit 0
