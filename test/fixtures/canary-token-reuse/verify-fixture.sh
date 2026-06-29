#!/usr/bin/env bash
# verify-fixture.sh — prove the token-reuse canary is a *real, latent* fault.
#
# Unlike the Gamma poison (which has a validate.sh oracle), this canary's whole point is that the
# kernel does NOT catch it — so the "substrate" we verify is: folding the mutated stream silently
# resurrects a done task (status done -> claimed) with ZERO rejections logged. If the kernel ever
# starts catching it (status stays done, or a rejection is logged), this canary is obsolete and must
# be retired — re-run this script after any src/project.js change.
#
#   bash test/fixtures/canary-token-reuse/verify-fixture.sh
#
# Read-only: never touches the real .tick/. Uses a scratch root under the fixture dir.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
cd "$ROOT" || exit 2

SCRATCH="$HERE/.projroot"
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

fail() { echo "FIXTURE FAIL: $*"; exit 1; }

project_status() {  # $1 = events dir -> prints "status rejections"
  local evdir="$1"
  local run="$SCRATCH/run"
  rm -rf "$run"; mkdir -p "$run/.tick/events"
  cp "$evdir"/*.jsonl "$run/.tick/events/"
  node -e '
    const {foldWithMeta}=require("./src/project");
    const {readAllEvents}=require("./src/events");
    const r=foldWithMeta(readAllEvents(process.argv[1]));
    const t=r.tasks.get("RELAY-TURN");
    process.stdout.write((t?t.status:"<none>")+" "+r.rejections.length);
  ' "$run"
}

echo "[1/2] folding the mutated stream (7 real events + 1 injected epoch-4 claim)…"
MUT="$(project_status "$HERE/events")"
echo "  -> status='${MUT% *}' rejections=${MUT#* }"
[ "$MUT" = "claimed 0" ] \
  || fail "expected 'claimed 0' (silent resurrection); got '$MUT'. If status=done, the injected event is missing; if rejections>0 the kernel now catches it — retire this canary."

echo "[2/2] control: same stream WITHOUT the injected event should be terminal…"
CTLDIR="$SCRATCH/control-src"
rm -rf "$CTLDIR"; mkdir -p "$CTLDIR"
for f in "$HERE"/events/*.jsonl; do
  grep -q '"ts":"2026-06-25T04:01:00.000Z"' "$f" || cp "$f" "$CTLDIR/"
done
CTL="$(project_status "$CTLDIR")"
echo "  -> status='${CTL% *}' rejections=${CTL#* }"
[ "$CTL" = "done 0" ] \
  || fail "control stream should fold to 'done 0' (real terminal lifecycle); got '$CTL'"

echo
echo "FIXTURE OK: injected epoch-4 claim silently resurrects a done task (done->claimed, 0 rejections)."
echo "The kernel does NOT catch token reuse — a Reviewer must. Expected verdict: see EXPECTED.md."
