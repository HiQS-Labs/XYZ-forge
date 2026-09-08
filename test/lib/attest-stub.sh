#!/usr/bin/env bash
# GH-505/GH-509 — approve a relay the way relay-drive does, for STUB relay-drives in tests.
#
# marathon-drive's success path no longer trusts a driver exit 0 by itself: it requires the
# relay-drive/attest@1 record the real driver publishes after watching the named reviewer approve
# (utils/py/relay_attest.py). A test stub that stands in for relay-drive and wants the marathon to
# SUCCEED therefore has to produce that record — this helper is that contract in one call:
#
#   bash test/lib/attest-stub.sh "$@"     # pass the stub's own argv (the driver's flags)
#
# It reads --relay-file / --relay-task / --reviewer / --target-root from the argv, appends a
# reviewer block, sets STATUS: Approved, moves the token to done as the reviewer (claim + done via
# $TICK_BIN under $TICK_REPO_ROOT), then appends the attestation trailer and writes the record with
# reviewed_head = the target repo's current HEAD. Idempotent for an already-approved file.
set -u
relay_file="" task="RELAY-TURN" reviewer="" target_root=""
while (($#)); do
  case "$1" in
    --relay-file)  relay_file="$2"; shift ;;
    --relay-task)  task="$2"; shift ;;
    --reviewer)    reviewer="$2"; shift ;;
    --target-root) target_root="$2"; shift ;;
  esac
  shift
done
[[ -n "$relay_file" && -n "$reviewer" ]] || { echo "attest-stub: --relay-file and --reviewer required" >&2; exit 2; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS="${ATTEST_STUB_HARNESS:-$(cd "$HERE/../.." && pwd)}"
target_root="${target_root:-${MARATHON_ROOT:-$(git -C "$(dirname "$relay_file")" rev-parse --show-toplevel 2>/dev/null)}}"
tick="${TICK_BIN:-$HARNESS/bin/tick}"
export TICK_REPO_ROOT="${TICK_REPO_ROOT:-$target_root}"
# Move the token to done AS THE REVIEWER. marathon seeds it open+handed to the builder (handoff-
# exclusive), so mirror the real sequence when a direct reviewer claim is refused: builder claims,
# releases to the reviewer, reviewer claims, reviewer marks done.
if ! "$tick" claim "$task" --agent "$reviewer" --paths "$relay_file" >/dev/null 2>&1; then
  builder="${MARATHON_BUILDER:-claude}"
  "$tick" claim "$task" --agent "$builder" --paths "$relay_file" >/dev/null 2>&1 || true
  "$tick" release "$task" --agent "$builder" --to "$reviewer" >/dev/null 2>&1 || true
  "$tick" claim "$task" --agent "$reviewer" --paths "$relay_file" >/dev/null 2>&1 || true
fi
"$tick" done "$task" --agent "$reviewer" >/dev/null 2>&1 || true
if ! "$tick" info "$task" 2>/dev/null | grep -qE '^status:[[:space:]]+done$'; then
  echo "attest-stub: token $task does not read done after claim/done as $reviewer (TICK_REPO_ROOT=$TICK_REPO_ROOT) — the stub manufactured no valid success" >&2
  exit 3
fi
python3 - "$HARNESS" "$relay_file" "$task" "$reviewer" "$target_root" <<'PY'
import os, sys, time
harness, relay_file, task, reviewer, target_root = sys.argv[1:6]
sys.path.insert(0, os.path.join(harness, "utils", "py"))
import relay_attest
pre = relay_attest.canonical(relay_file)
with open(relay_file, "r", encoding="utf-8", errors="surrogateescape") as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if line.startswith("STATUS:"):
        lines[i] = "STATUS: Approved\n"
        break
lines.append(f"\n### Round 1 · Reviewer · {reviewer} (attest-stub)\n**Verdict:** Approved — stub review.\n")
with open(relay_file, "w", encoding="utf-8", errors="surrogateescape") as f:
    f.writelines(lines)
post = relay_attest.canonical(relay_file)
assert post.startswith(pre)
added = post[len(pre):]
rec = {
    "schema": relay_attest.SCHEMA, "task": task,
    "transcript_repo": target_root, "relay_file": os.path.abspath(relay_file),
    "relay_file_rel": relay_attest.repo_relative(relay_file, target_root),
    "target_repo": os.path.abspath(target_root), "reviewer": reviewer, "status": "Approved",
    "isolated": True, "reviewed_head": relay_attest.rev_parse(target_root), "artifact_sha256": None,
    "added_start": len(pre), "added_len": len(added), "added_sha256": relay_attest.sha256(added),
    "attested_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "driver_pid": os.getpid(),
}
trailer = relay_attest.trailer_text(rec)
rec["trailer_sha256"] = relay_attest.sha256(trailer.encode("utf-8"))
with open(relay_file, "a", encoding="utf-8") as f:
    f.write(trailer)
relay_attest.write(rec)
PY
