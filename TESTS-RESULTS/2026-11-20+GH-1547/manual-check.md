# Manual Check — GH-1547 (KS-04): `kickstart_status.py` Thin Derived Read-Only Status Report

- **Pre-change SHA:** `0edbab45d60f9b7d92e4d2b616743d3874b526d5`
- **Candidate SHA:** `ee70eced1b30963559c1744e99af704868812f09`
- **Scope:** Verify all KS-04, U3, U10, canonical final-QA staleness, invocation-attributed stop-reason, and GH-1527 read-only invariance checks with paired pre-change red controls. No new test suites (GH-831).

## Literal Runnable Check Block

```bash
set -euo pipefail
PRE_SHA="0edbab45d60f9b7d92e4d2b616743d3874b526d5"
CAND_SHA="ee70eced1b30963559c1744e99af704868812f09"
OUT_DIR="TESTS-RESULTS/2026-11-20+GH-1547/outputs"
mkdir -p "$OUT_DIR"

echo "=== 1. Pre-change red control: kickstart_status.py absent at PRE_SHA ==="
if git cat-file -e "${PRE_SHA}:skills/1-hourly/kickstart/scripts/kickstart_status.py" 2>/dev/null; then
  echo "FAIL: kickstart_status.py unexpectedly existed at PRE_SHA"
  exit 1
fi
echo "PASS: red control confirmed (kickstart_status.py absent at ${PRE_SHA})"
git rev-parse --verify "${CAND_SHA}^{commit}" >/dev/null
echo "PASS: candidate commit verified (${CAND_SHA})"

echo "=== 2. Fixtures: U3 liveness, unapplied amendments, U10 attempts+remote, final-QA, stop-reason ==="
python3 - "$OUT_DIR" <<'PY'
import json, os, subprocess, sys, tempfile
from datetime import datetime, timezone
from pathlib import Path

out_dir = Path(sys.argv[1])
script = Path("skills/1-hourly/kickstart/scripts/kickstart_status.py").resolve()
NOW = "2026-11-20T12:00:00Z"
NOW_TS = datetime(2026, 11, 20, 12, 0, 0, tzinfo=timezone.utc).timestamp()

def run_status(*args: str) -> dict:
    p = subprocess.run([sys.executable, str(script), *args, "--json"], capture_output=True, text=True)
    assert p.returncode == 0, f"rc={p.returncode} stderr={p.stderr}"
    return json.loads(p.stdout)

with tempfile.TemporaryDirectory() as td:
    tmp = Path(td)
    landing_a = tmp / "landing-pinned"
    landing_b = tmp / "landing-unpinned"
    for root, pr, sha in ((landing_a, 1539, "aaaa1111bbbb2222"), (landing_b, 9999, "ffff9999eeee8888")):
        rec_dir = root / ".tick" / "merge-cleanup" / "HiQS-Labs-XYZ-forge"
        rec_dir.mkdir(parents=True, exist_ok=True)
        (rec_dir / f"pr-{pr}.json").write_text(json.dumps({
            "schema": 1, "pr": pr, "repo": "https://github.com/HiQS-Labs/XYZ-forge.git",
            "attempts": [{"by": "driver", "head_sha": sha, "rung": "B1", "started": "2026-11-20T11:30:00Z", "outcome": "in_progress"}],
        }))
    # Add second PR in pinned landing clone for OPEN-same-head, OPEN-changed-head, and unknown-remote tests
    mc_a = landing_a / ".tick" / "merge-cleanup" / "HiQS-Labs-XYZ-forge"
    for pr, sha in ((1540, "bbbb2222cccc3333"), (1541, "cccc3333dddd4444"), (1542, "dddd4444eeee5555")):
        (mc_a / f"pr-{pr}.json").write_text(json.dumps({
            "schema": 1, "pr": pr, "repo": "https://github.com/HiQS-Labs/XYZ-forge.git",
            "attempts": [{"by": "driver", "head_sha": sha, "rung": "B1", "started": "2026-11-20T11:40:00Z", "outcome": "in_progress"}],
        }))

    prs_json = tmp / "prs.json"
    prs_json.write_text(json.dumps([
        {"pr": 1546, "title": "KS-03 clean", "draft": False, "held": None, "inherited_hold": None, "unknown": False, "conflicting": False, "failing": [], "behind": False, "drift": 0, "rung": 0},
        {"pr": 1549, "title": "KS-02 behind", "draft": False, "held": None, "inherited_hold": None, "unknown": False, "conflicting": False, "failing": [], "behind": True, "drift": 2, "rung": 0},
        {"pr": 1024, "title": "held draft", "draft": True, "held": "Review authority limit", "inherited_hold": None, "unknown": False, "conflicting": False, "failing": [], "behind": False, "drift": 0, "rung": 2},
    ]))

    remote_prs_json = tmp / "remote_prs.json"
    remote_prs_json.write_text(json.dumps({
        "1539": {"state": "MERGED", "headRefOid": "aaaa1111bbbb2222", "mergeCommit": {"oid": "9999000011112222"}, "mergedAt": "2026-11-20T11:45:00Z"},
        "1540": {"state": "OPEN", "headRefOid": "bbbb2222cccc3333"},
        "1541": {"state": "OPEN", "headRefOid": "ffffffff00000000"},
    }))

    rec_unapplied = tmp / "record-unapplied.md"
    rec_unapplied.write_text(f"""# Kickstart run: KS-04 fixture
RUN-RECORD-VERSION: 1
LANDING_CLONE: {landing_a}

## Progress log
OPERATOR_AMENDMENT: OA-1 2026-11-20T06:48Z legacy line without turn citation
PARENT_NOTE: PN-1 2026-11-20T07:00Z check PR 1546 before landing
CURRENT: KS-04 kickstart_status.py
- KS-15 (#1543): MERGED PR #1544 (merge 8c44d86bbd, reconciled 0edbab45d6) 2026-11-20T08:18Z
GATE: final-QA 0edbab45d6 full 900s green 2026-11-20T08:30:00Z
GATE: #1549 head 25bafe0611 docs 35s green 2026-11-20T08:40:00Z
""")

    rec_applied = tmp / "record-applied.md"
    rec_applied.write_text(f"""# Kickstart run: KS-04 fixture applied
RUN-RECORD-VERSION: 1
LANDING_CLONE: {landing_a}

## Progress log
OPERATOR_AMENDMENT: OA-2 operator turn 12: approve scope 2026-11-20T07:00Z
PARENT_NOTE: PN-2 2026-11-20T07:05Z verify head
APPLIED: OA-2 -> applied scope update 2026-11-20T07:02Z
APPLIED: PN-2 -> applied head verified 2026-11-20T07:06Z
GATE: final-QA 0edbab45d60f9b7d92e4d2b616743d3874b526d5 full 900s green 2026-11-20T08:30:00Z
- KS-03 (#1545): MERGED PR #1546 (merge 1111222233, reconciled 4444555566) 2026-11-20T09:00Z
""")

    rec_red_qa = tmp / "record-red-qa.md"
    rec_red_qa.write_text(f"""# Kickstart run: KS-04 red final-QA
RUN-RECORD-VERSION: 1
LANDING_CLONE: {landing_a}

## Progress log
GATE: final-QA 0edbab45d6 full 900s red 2026-11-20T08:30:00Z
""")

    # Create logs with controlled mtimes
    log_30s = tmp / "log-30s.log"; log_30s.write_text("running\n"); os.utime(log_30s, (NOW_TS - 30, NOW_TS - 30))
    log_240s = tmp / "log-240s.log"; log_240s.write_text("quiet\n"); os.utime(log_240s, (NOW_TS - 240, NOW_TS - 240))
    log_900s = tmp / "log-900s.log"; log_900s.write_text("stuck\n"); os.utime(log_900s, (NOW_TS - 900, NOW_TS - 900))
    lock_file = tmp / "active.lock"; lock_file.write_text("1")
    absent_lock = tmp / "absent.lock"

    # Case A: U3 liveness matrix (all 6 sub-cases)
    r_wait = run_status("--record", str(rec_unapplied), "--prs-json", str(prs_json), "--remote-prs-json", str(remote_prs_json),
                        "--log-file", str(log_30s), "--now", NOW, "--owner-state", "live",
                        "--development-head", "0edbab45d60f9b7d92e4d2b616743d3874b526d5")
    assert r_wait["liveness"]["state"] == "waiting", r_wait["liveness"]

    r_quiet = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                         "--log-file", str(log_240s), "--now", NOW, "--owner-state", "live")
    assert r_quiet["liveness"]["state"] == "quiet", r_quiet["liveness"]

    r_stale_live = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                              "--log-file", str(log_900s), "--now", NOW, "--owner-state", "live")
    assert r_stale_live["liveness"]["state"] == "stale-candidate", r_stale_live["liveness"]
    assert "never authorizes finish or redispatch" in (r_stale_live["liveness"]["advisory"] or "")

    r_dead_live_child = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                                   "--log-file", str(log_900s), "--now", NOW,
                                   "--owner-state", "stopped", "--lock-path", str(absent_lock),
                                   "--children-state", "live", "--sessions-state", "stopped")
    assert r_dead_live_child["liveness"]["state"] != "confirmed-stopped"
    assert r_dead_live_child["liveness"]["state"] == "stale-candidate"

    r_dead_unknown_child = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                                      "--now", NOW,
                                      "--owner-state", "stopped", "--lock-path", str(absent_lock),
                                      "--children-state", "unknown", "--sessions-state", "unknown")
    assert r_dead_unknown_child["liveness"]["state"] == "unknown", r_dead_unknown_child["liveness"]

    r_confirmed = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                             "--log-file", str(log_900s), "--now", NOW,
                             "--owner-state", "stopped", "--owner-pid", "99999999",
                             "--lock-path", str(absent_lock),
                             "--children-state", "stopped", "--sessions-state", "stopped")
    assert r_confirmed["liveness"]["state"] == "confirmed-stopped", r_confirmed["liveness"]
    print("PASS: U3 liveness matrix (all 6 sub-cases; stuck fixture never live or confirmed-stopped without 4-part proof)")

    # Case B: Unapplied amendments (including legacy OA-1 + PN-1) vs applied
    unapp_ids = {a["id"] for a in r_wait["unapplied_amendments"]}
    assert unapp_ids == {"OA-1", "PN-1"}, unapp_ids
    r_app = run_status("--record", str(rec_applied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                       "--now", NOW, "--development-head", "4444555566")
    assert r_app["unapplied_amendments"] == [], r_app["unapplied_amendments"]
    print("PASS: unapplied amendments surfaced (including legacy OA-1) and cleared when APPLIED")

    # Case C: PR hygiene merge-ready summary
    pr_map = {p["pr"]: p for p in r_wait["prs"]["items"]}
    assert pr_map[1546]["merge_ready"] is True
    assert pr_map[1549]["merge_ready"] is False and any("behind" in b for b in pr_map[1549]["blockers"])
    assert pr_map[1024]["merge_ready"] is False and any("draft" in b for b in pr_map[1024]["blockers"])
    print("PASS: PR merge-ready summary derived cleanly")

    # Case D: U10 pinned LANDING_CLONE attempt records + remote PR state (ignores landing_b #9999!)
    sa_map = {a["pr"]: a for a in r_wait["attempts"]["stale_attempts"]}
    assert set(sa_map.keys()) == {1539, 1540, 1541, 1542}, sa_map.keys()
    assert 9999 not in sa_map
    assert sa_map[1539]["remote_state"] == "MERGED" and sa_map[1539]["head_matches_attempt"] is True
    assert sa_map[1540]["remote_state"] == "OPEN" and sa_map[1540]["head_matches_attempt"] is True
    assert sa_map[1541]["remote_state"] == "OPEN" and sa_map[1541]["head_matches_attempt"] is False
    assert sa_map[1542]["remote_state"] == "unknown" and sa_map[1542]["head_matches_attempt"] is None
    print("PASS: U10 pinned attempt records + remote PR state (MERGED / OPEN-same / OPEN-changed / unknown; unpinned ignored)")

    # Case E: Final-QA staleness (all 6 sub-cases)
    # 1+2: canonical green + later non-landing task GATE: PR-1549 + abbreviated-vs-full --development-head -> fresh!
    assert r_wait["final_qa"]["status"] == "fresh", r_wait["final_qa"]
    # 3: canonical green + no --development-head -> unknown!
    assert r_quiet["final_qa"]["status"] == "unknown", r_quiet["final_qa"]
    # 4: canonical green + real later MERGED line -> stale!
    assert r_app["final_qa"]["status"] == "stale", r_app["final_qa"]
    # 5: canonical green + different --development-head -> stale!
    r_diff_dev = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                            "--now", NOW, "--development-head", "deadbeef12345678")
    assert r_diff_dev["final_qa"]["status"] == "stale", r_diff_dev["final_qa"]
    # 6: canonical red final-QA -> stale!
    r_red = run_status("--record", str(rec_red_qa), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                       "--now", NOW, "--development-head", "0edbab45d6")
    assert r_red["final_qa"]["status"] == "stale", r_red["final_qa"]
    print("PASS: final-QA staleness (green+task-gate+short/full match=fresh, unverified=unknown, later-MERGED=stale, diff-head=stale, red-QA=stale)")

    # Case F: Stop-reason attribution (all 5 sub-cases; rejects mtime-only and sidecar-only!)
    harness = tmp / "harness"
    esc_dir = harness / ".relay-scratch"
    esc_dir.mkdir(parents=True)
    esc = esc_dir / "escalation-reason"
    sidecar = esc_dir / "escalation-reason.meta.json"

    # F1: plain-text stale cap-stalled -> unknown/unattributable
    esc.write_text("cap-stalled\n")
    os.utime(esc, (NOW_TS - 3600, NOW_TS - 3600))
    r_f1 = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                      "--harness-root", str(harness), "--invocation-id", "inv-A")
    assert r_f1["stop_reason"]["stop_reason"] == "unknown" and r_f1["stop_reason"]["attribution"] == "unattributable"

    # F2: newer plain-text file written AFTER run start by different invocation -> STILL unknown/unattributable!
    esc.write_text("cap-stalled\n")
    os.utime(esc, (NOW_TS + 10, NOW_TS + 10))
    r_f2 = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                      "--harness-root", str(harness), "--invocation-id", "inv-A")
    assert r_f2["stop_reason"]["stop_reason"] == "unknown" and r_f2["stop_reason"]["attribution"] == "unattributable"

    # F3: matching-A stale sidecar + overwritten plain-text B -> STILL unknown/unattributable!
    sidecar.write_text(json.dumps({"invocation_id": "inv-A"}))
    r_f3 = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                      "--harness-root", str(harness), "--invocation-id", "inv-A")
    assert r_f3["stop_reason"]["stop_reason"] == "unknown" and r_f3["stop_reason"]["attribution"] == "unattributable"

    # F4: conflicting payload inv-B + stale sidecar inv-A -> STILL unknown/unattributable!
    esc.write_text(json.dumps({"invocation_id": "inv-B", "reason": "cap-stalled"}))
    r_f4 = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                      "--harness-root", str(harness), "--invocation-id", "inv-A")
    assert r_f4["stop_reason"]["stop_reason"] == "unknown" and r_f4["stop_reason"]["attribution"] == "unattributable"

    # F5: self-contained matching structured payload AND exclusive per-run receipt -> quoted verbatim!
    esc.write_text(json.dumps({"invocation_id": "inv-A", "reason": "provider-quota"}))
    r_f5a = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                       "--harness-root", str(harness), "--invocation-id", "inv-A")
    assert r_f5a["stop_reason"]["stop_reason"] == "provider-quota" and r_f5a["stop_reason"]["attribution"] == "shared-file-invocation-id"

    receipt = tmp / "run-receipt.json"
    receipt.write_text(json.dumps({"stop_reason": "cap-progressing-extended"}))
    r_f5b = run_status("--record", str(rec_unapplied), "--skip-prs", "--remote-prs-json", str(remote_prs_json),
                       "--receipt", str(receipt), "--harness-root", str(harness), "--invocation-id", "inv-A")
    assert r_f5b["stop_reason"]["stop_reason"] == "cap-progressing-extended" and r_f5b["stop_reason"]["attribution"] == "run-receipt"
    print("PASS: stop-reason attribution (stale/newer plain-text, sidecar+plain-text, conflicting payload+sidecar -> unknown; self-contained & receipt -> verbatim)")

    # Save redacted representative JSON + Markdown outputs
    (out_dir / "fixture-live-report.json").write_text(json.dumps(r_wait, indent=2, sort_keys=True).replace(str(tmp), "<TMP>") + "\n")
    (out_dir / "fixture-stale-candidate.json").write_text(json.dumps(r_stale_live, indent=2, sort_keys=True).replace(str(tmp), "<TMP>") + "\n")
    p_md = subprocess.run(
        [sys.executable, str(script), "--record", str(rec_unapplied), "--prs-json", str(prs_json),
         "--remote-prs-json", str(remote_prs_json), "--log-file", str(log_30s), "--now", NOW,
         "--owner-state", "live", "--development-head", "0edbab45d60f9b7d92e4d2b616743d3874b526d5"],
        capture_output=True, text=True, check=True,
    )
    (out_dir / "fixture-live-report.md").write_text(p_md.stdout.replace(str(tmp), "<TMP>"))
PY

echo "=== 3. GH-1527 Read-Only Live Check (git shim + refs/FETCH_HEAD/count-objects) ==="
SHIM_DIR="$(mktemp -d)"
GIT_LOG="$SHIM_DIR/git-verbs.log"
REAL_GIT="$(command -v git)"
cat > "$SHIM_DIR/git" <<SHIM
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GIT_LOG"
exec "$REAL_GIT" "\$@"
SHIM
chmod +x "$SHIM_DIR/git"

REFS_BEFORE="$(git show-ref | sha256sum)"
FH_BEFORE="$(stat -f '%m %z' .git/FETCH_HEAD 2>/dev/null || echo absent)"
OBJ_BEFORE="$(git count-objects -v)"

LIVE_REC="$SHIM_DIR/live-record.md"
cat > "$LIVE_REC" <<'REC'
# Kickstart live read-only check
RUN-RECORD-VERSION: 1
LANDING_CLONE: ~/nonexistent-readonly-probe

## Progress log
- KS-15 (#1543): MERGED PR #1544 (merge 8c44d86bbd) 2026-11-20T08:18Z
REC

PATH="$SHIM_DIR:$PATH" python3 skills/1-hourly/kickstart/scripts/kickstart_status.py \
  --record "$LIVE_REC" --target-root . --json \
  | sed "s|$HOME|~|g" > "$OUT_DIR/live-readonly-report.json"

REFS_AFTER="$(git show-ref | sha256sum)"
FH_AFTER="$(stat -f '%m %z' .git/FETCH_HEAD 2>/dev/null || echo absent)"
OBJ_AFTER="$(git count-objects -v)"

test "$REFS_BEFORE" = "$REFS_AFTER" && echo "PASS: git show-ref unchanged"
test "$FH_BEFORE" = "$FH_AFTER" && echo "PASS: FETCH_HEAD unchanged"
test "$OBJ_BEFORE" = "$OBJ_AFTER" && echo "PASS: git count-objects unchanged"
if grep -E '(^| )(fetch|merge-tree|update-ref|commit|checkout|reset|push|pull)\b' "$GIT_LOG" 2>/dev/null; then
  echo "FAIL: mutating git verb observed during live kickstart_status.py run"
  exit 1
fi
sed "s|$HOME|~|g" "$GIT_LOG" > "$OUT_DIR/readonly-git-verbs.log"
echo "PASS: zero mutating git verbs in live run ($(wc -l < "$GIT_LOG" | tr -d ' ') read-only git calls logged)"
rm -rf "$SHIM_DIR"

echo "=== 4. CI route classification & mypy ==="
git diff --name-only "${PRE_SHA}..HEAD" | ./utils/ci-route.sh pull_request
mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/kickstart_status.py
```
