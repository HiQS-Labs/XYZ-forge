#!/usr/bin/env bash
# verify-fixture.sh — prove the kernel SEALS a terminal token (GH-41 terminality-seal).
#
# History: this canary was authored (GH-40 Phase 2) to prove a *real, latent* fault — the kernel did
# NOT catch token reuse, so folding the mutated stream silently resurrected a done task
# (status done -> claimed) with ZERO rejections. GH-41 (decisions/2026-07-02-terminality-seal.md)
# fixed foldWithMeta, so this oracle is now INVERTED: it asserts the kernel catches it — the mutated
# stream folds to `done` + exactly ONE rejection (reason `claim-after-terminal`), the injected
# post-terminal epoch-4 reclaim. If this ever regresses to `claimed 0` (or any rejections != 1), the
# terminality seal has broken — re-run after any src/project.js change.
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

project_status() {  # $1 = events dir -> prints "status count reasons" (reasons = comma-joined, or '-')
  local evdir="$1"
  local run="$SCRATCH/run"
  rm -rf "$run"; mkdir -p "$run/.tick/events"
  cp "$evdir"/*.jsonl "$run/.tick/events/"
  node -e '
    const {foldWithMeta}=require("./src/project");
    const {readAllEvents}=require("./src/events");
    const r=foldWithMeta(readAllEvents(process.argv[1]));
    const t=r.tasks.get("RELAY-TURN");
    const reasons=r.rejections.map(x=>x.reason).join(",")||"-";
    process.stdout.write((t?t.status:"<none>")+" "+r.rejections.length+" "+reasons);
  ' "$run"
}

echo "[1/2] folding the mutated stream (7 real events + 1 injected epoch-4 claim)…"
MUT="$(project_status "$HERE/events")"
echo "  -> '$MUT'  (status count reasons)"
[ "$MUT" = "done 1 claim-after-terminal" ] \
  || fail "expected 'done 1 claim-after-terminal' (kernel seals the terminal — GH-41); got '$MUT'. If 'claimed 0' the terminality seal has REGRESSED (silent resurrection is back); if the reason differs the seal is mis-classifying a lifecycle violation."

echo "[2/2] control: same stream WITHOUT the injected event should be a clean terminal…"
CTLDIR="$SCRATCH/control-src"
rm -rf "$CTLDIR"; mkdir -p "$CTLDIR"
for f in "$HERE"/events/*.jsonl; do
  grep -q '"ts":"2026-06-25T04:01:00.000Z"' "$f" || cp "$f" "$CTLDIR/"
done
CTL="$(project_status "$CTLDIR")"
echo "  -> '$CTL'  (status count reasons)"
[ "$CTL" = "done 0 -" ] \
  || fail "control stream should fold to 'done 0 -' (real terminal lifecycle, nothing to seal); got '$CTL'"

echo
echo "FIXTURE OK (GH-41): the injected post-terminal epoch-4 reclaim is SEALED —"
echo "the token stays 'done' and the reclaim is rejected as 'claim-after-terminal' (1 rejection)."
echo "Control (no reclaim) folds clean to 'done 0'. The kernel now catches token reuse."
