#!/usr/bin/env python3
"""Complete GH-1548 (KS-05) Controls 1-4, regression checks, and KS-04 compatibility check."""
import importlib.util, json, os, shutil, subprocess, sys, tempfile
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
ks04_repo = Path(sys.argv[2]).resolve()
out_path = Path(sys.argv[3]).resolve()
logs = []

base_sha = subprocess.check_output(["git", "-C", str(repo), "merge-base", "origin/development", "HEAD"], text=True).strip()
cand_code_sha = "b280e6709ce93b7e89676d0ac61c859bce119968"
ks04_sha = subprocess.check_output(["git", "-C", str(ks04_repo), "rev-parse", "HEAD"], text=True).strip()
logs.append(f"=== REVISIONS ===\nbase_sha={base_sha}\ncandidate_code_sha={cand_code_sha}\nks04_authoritative_sha={ks04_sha}")

def make_sandbox(td: Path, use_base: bool = False):
    sb = td / ("base_sb" if use_base else "cand_sb")
    sb.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=str(sb), check=True)
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=str(sb), check=True)
    subprocess.run(["git", "config", "user.name", "Test"], cwd=str(sb), check=True)
    shutil.copytree(repo / "utils/py", sb / "utils/py")
    if use_base:
        # Overwrite relay_drive.py and harness.py with pre-change base_sha versions!
        for rel in ("utils/py/relay_drive.py", "utils/py/harness.py"):
            raw = subprocess.check_output(["git", "-C", str(repo), "show", f"{base_sha}:{rel}"])
            (sb / rel).write_bytes(raw)
    shutil.copytree(repo / "bin", sb / "bin")
    os.symlink(repo / "src", sb / "src")
    (sb / ".relay-scratch").mkdir()
    (sb / "relay-system/2026-11-20").mkdir(parents=True)
    rf = sb / "relay-system/2026-11-20/test-ks05.md"
    rf.write_text("# Relay Test\n\nSTATUS: In progress\nNEXT: codex\n\n## Turn 1 — Producer\nHello\n")
    subprocess.run(["git", "add", "utils/py", "bin", "relay-system"], cwd=str(sb), check=True)
    subprocess.run(["git", "commit", "-q", "-m", "init"], cwd=str(sb), check=True)
    env = os.environ.copy()
    env["PATH"] = f"{sb / 'bin'}:{env.get('PATH', '')}"
    env["TICK_REPO_ROOT"] = str(sb)
    env["XYZ_REPO_ROOT"] = str(sb)
    return sb, rf, env

def seed_tick(sb: Path, env: dict, task_id: str, rel_rf: str):
    tick = str(sb / "bin/tick")
    for args in [
        [tick, "log", "task.created", task_id, "--agent", "antigravity", "--paths", rel_rf],
        [tick, "claim", task_id, "--agent", "antigravity", "--paths", rel_rf],
        [tick, "release", task_id, "--agent", "antigravity", "--to", "codex"],
    ]:
        subprocess.run(args, cwd=str(sb), env=env, check=True, stdout=subprocess.DEVNULL)

with tempfile.TemporaryDirectory() as td:
    td = Path(td).resolve()

    # --- CONTROL 1 (RED pre-fix vs GREEN candidate): stale cap-stalled vs zero-output exit-3 stall ---
    base_sb, base_rf, base_env = make_sandbox(td, use_base=True)
    cand_sb, cand_rf, cand_env = make_sandbox(td, use_base=False)
    rel_rf = "relay-system/2026-11-20/test-ks05.md"
    seed_tick(base_sb, base_env, "RELAY-C1-RED", rel_rf)
    seed_tick(cand_sb, cand_env, "RELAY-C1-GREEN", rel_rf)
    seed_tick(cand_sb, cand_env, "RELAY-C1-NOOP", rel_rf)

    # Zero-output shim: modifies relay file (e.g. adds blank line) without appending a review block -> GH-397 zero-output-stall!
    shim_zero_src = "append newline to sandbox relay file without review block"
    shim_noop_src = "#!/usr/bin/env bash\nexit 0\n"
    for sb, rf in ((base_sb, base_rf), (cand_sb, cand_rf)):
        (sb / "shim_zero.sh").write_text(f"#!/usr/bin/env bash\nprintf '\\n' >> \"{rf}\"\nexit 0\n"); (sb / "shim_zero.sh").chmod(0o755)
        (sb / "shim_noop.sh").write_text(shim_noop_src); (sb / "shim_noop.sh").chmod(0o755)

    (base_sb / ".relay-scratch/escalation-reason").write_text("cap-stalled\n")
    cmd_c1_red = [sys.executable, str(base_sb / "utils/py/relay_drive.py"), "--relay-file", str(base_rf), "--relay-task", "RELAY-C1-RED", "--agent-cmd", str(base_sb / "shim_zero.sh"), "--reviewer", "codex", "--review-once"]
    p_c1_red = subprocess.run(cmd_c1_red, cwd=str(base_sb), env=base_env, capture_output=True, text=True)
    base_esc = (base_sb / ".relay-scratch/escalation-reason").read_text().strip()
    base_receipts = list((base_sb / ".relay-scratch").glob("stop-reasons/*.json"))
    logs.append(f"=== CONTROL_1A_RED_PRE_CHANGE_BASE (base={base_sha}, rc={p_c1_red.returncode}) ===\nCMD: {' '.join(cmd_c1_red)}\nSHIM: {shim_zero_src.strip()}\nLEGACY_ESC={base_esc}\nSTOP_RECEIPTS={len(base_receipts)}\nSTDERR:\n{p_c1_red.stderr}")
    assert p_c1_red.returncode == 3 and base_esc == "cap-stalled" and len(base_receipts) == 0, f"Base C1 unexpected: rc={p_c1_red.returncode} esc={base_esc}"

    (cand_sb / ".relay-scratch/escalation-reason").write_text("cap-stalled\n")
    cmd_c1_green = [sys.executable, str(cand_sb / "utils/py/relay_drive.py"), "--relay-file", str(cand_rf), "--relay-task", "RELAY-C1-GREEN", "--agent-cmd", str(cand_sb / "shim_zero.sh"), "--reviewer", "codex", "--review-once"]
    p_c1_green = subprocess.run(cmd_c1_green, cwd=str(cand_sb), env=cand_env, capture_output=True, text=True)
    cand_esc = (cand_sb / ".relay-scratch/escalation-reason").read_text().strip()
    cand_receipts = sorted((cand_sb / ".relay-scratch/stop-reasons").glob("*.json"))
    rec_c1 = json.loads(cand_receipts[-1].read_text())
    logs.append(f"=== CONTROL_1B_GREEN_ZERO_OUTPUT_STALL (rc={p_c1_green.returncode}) ===\nCMD: {' '.join(cmd_c1_green)}\nLEGACY_ESC={cand_esc}\nRECEIPT={json.dumps(rec_c1)}\nSTDERR:\n{p_c1_green.stderr}")
    assert p_c1_green.returncode == 3 and cand_esc == "zero-output-stall" and rec_c1["reason"] == "zero-output-stall" and rec_c1["exit_code"] == 3, (p_c1_green.returncode, cand_esc, rec_c1, p_c1_green.stderr)

    # --- CONTROL 2 (Adapter-level U13 429->provider-quota vs adapter-error + live stderr 429 vs generic turn-error) ---
    # 2A: Adapter-level codex_decide() comparison (base returns "rate-limited", candidate returns "provider-quota" and "adapter-error")
    sys.path.insert(0, str(cand_sb / "utils/py"))
    spec_h = importlib.util.spec_from_file_location("harness_cand", cand_sb / "utils/py/harness.py")
    h_mod = importlib.util.module_from_spec(spec_h); sys.modules["harness_cand"] = h_mod; spec_h.loader.exec_module(h_mod)
    spec_hb = importlib.util.spec_from_file_location("harness_base", base_sb / "utils/py/harness.py")
    hb_mod = importlib.util.module_from_spec(spec_hb); sys.modules["harness_base"] = hb_mod; spec_hb.loader.exec_module(hb_mod)

    class FakeRun:
        def __init__(self, rc, stdout, stderr):
            self.rc, self.stdout, self.stderr, self.timed_out = rc, stdout, stderr, False

    def probe_codex_decide(mod, fake_res):
        orig_run = mod.run_bounded
        mod.run_bounded = lambda *a, **kw: fake_res
        try:
            prompt_text = (mod.PACKAGE / "prompts" / "evaluator.v2.md").read_text(encoding="utf-8")
            snap = {"inbox": [{"id": "m1", "text": "ping"}], "now": 1000, "last_probe": 0}
            cfg = {
                "prompt_sha256": mod.sha_text(prompt_text),
                "codex_model": "gpt-6.1-sol",
                "codex_effort": "medium",
                "adapter_timeout_s": 30,
            }
            res = mod.codex_decide(snap, cfg)
            return getattr(res, "normalized", getattr(res, "status", str(res)))
        finally:
            mod.run_bounded = orig_run

    r2a_base_429 = probe_codex_decide(hb_mod, FakeRun(1, "", "HTTP 429 Too Many Requests: insufficient_quota"))
    r2a_cand_429 = probe_codex_decide(h_mod, FakeRun(1, "", "HTTP 429 Too Many Requests: insufficient_quota"))
    r2a_cand_err = probe_codex_decide(h_mod, FakeRun(1, "", "SyntaxError: invalid syntax"))
    logs.append(f"=== CONTROL_2A_ADAPTER_CODEX_DECIDE ===\nbase_429_result={r2a_base_429!r}\ncand_429_result={r2a_cand_429!r}\ncand_non_quota_result={r2a_cand_err!r}")
    assert "rate-limited" in str(r2a_base_429) and "provider-quota" in str(r2a_cand_429) and "adapter-error" in str(r2a_cand_err), (r2a_base_429, r2a_cand_429, r2a_cand_err)

    # 2B: relay_drive.py live stderr 429 -> provider-quota vs generic error -> turn-error
    seed_tick(cand_sb, cand_env, "RELAY-C2-429", rel_rf)
    seed_tick(cand_sb, cand_env, "RELAY-C2-ERR", rel_rf)
    shim_429_src = "#!/usr/bin/env bash\necho 'HTTP 429 Too Many Requests: insufficient_quota' >&2\nexit 1\n"
    shim_err_src = "#!/usr/bin/env bash\necho 'SyntaxError: invalid syntax in target' >&2\nexit 1\n"
    (cand_sb / "shim_429.sh").write_text(shim_429_src); (cand_sb / "shim_429.sh").chmod(0o755)
    (cand_sb / "shim_err.sh").write_text(shim_err_src); (cand_sb / "shim_err.sh").chmod(0o755)

    p_c2_429 = subprocess.run([sys.executable, str(cand_sb / "utils/py/relay_drive.py"), "--relay-file", str(cand_rf), "--relay-task", "RELAY-C2-429", "--agent-cmd", str(cand_sb / "shim_429.sh"), "--reviewer", "codex", "--review-once"], cwd=str(cand_sb), env=cand_env, capture_output=True, text=True)
    rec_c2_429 = json.loads(max((cand_sb / ".relay-scratch/stop-reasons").glob("RELAY-C2-429-*.json"), key=lambda _f: _f.stat().st_mtime_ns).read_text())
    p_c2_err = subprocess.run([sys.executable, str(cand_sb / "utils/py/relay_drive.py"), "--relay-file", str(cand_rf), "--relay-task", "RELAY-C2-ERR", "--agent-cmd", str(cand_sb / "shim_err.sh"), "--reviewer", "codex", "--review-once"], cwd=str(cand_sb), env=cand_env, capture_output=True, text=True)
    rec_c2_err = json.loads(max((cand_sb / ".relay-scratch/stop-reasons").glob("RELAY-C2-ERR-*.json"), key=lambda _f: _f.stat().st_mtime_ns).read_text())
    logs.append(f"=== CONTROL_2B_LIVE_STDERR_QUOTA_VS_TURN_ERROR ===\n429_rc={p_c2_429.returncode} receipt={json.dumps(rec_c2_429)}\nerr_rc={p_c2_err.returncode} receipt={json.dumps(rec_c2_err)}")
    assert rec_c2_429["reason"] == "provider-quota" and rec_c2_err["reason"] == "turn-error"

    # --- CONTROL 3: Per-turn fresh log isolation (consecutive same-task turns + repeated quota + generic turn-error + caller-reused CODEX_LOG with stale 429 & partial overwrite) ---
    # Use a shim that inspects CODEX_LOG, logs it to a sidecar, and behaves according to a sequence file!
    seq_file = cand_sb / "turn_seq.txt"
    log_paths_file = cand_sb / "seen_codex_logs.txt"
    shim_seq = cand_sb / "shim_seq.sh"
    shim_seq.write_text(f"""#!/usr/bin/env bash
echo "CODEX_LOG=$CODEX_LOG" >> "{log_paths_file}"
MODE=$(head -n 1 "{seq_file}")
tail -n +2 "{seq_file}" > "{seq_file}.tmp" && mv "{seq_file}.tmp" "{seq_file}"
if [ "$MODE" = "quota_log_only" ]; then
    echo "HTTP 429 Too Many Requests: quota exceeded" > "$CODEX_LOG"
    exit 1
elif [ "$MODE" = "generic_log_only" ]; then
    echo "syntax error on line 42" > "$CODEX_LOG"
    exit 1
elif [ "$MODE" = "partial_overwrite" ]; then
    # Append generic error without erasing stale 429 already in caller-reused CODEX_LOG
    echo "syntax error after stale header" >> "$CODEX_LOG"
    exit 1
elif [ "$MODE" = "reused_with_live_stderr_429" ]; then
    echo "syntax error in log" >> "$CODEX_LOG"
    echo "HTTP 429 Too Many Requests on live stderr" >&2
    exit 1
fi
exit 1
""")
    shim_seq.chmod(0o755)
    seed_tick(cand_sb, cand_env, "RELAY-C3-SAME", rel_rf)
    # Consecutive runs on SAME task with fresh per-turn logs (no CODEX_LOG in env):
    # Turn 1: quota_log_only -> provider-quota
    # Turn 2: quota_log_only (identical repeated quota text!) -> provider-quota, DISTINCT log path
    # Turn 3: generic_log_only -> turn-error, DISTINCT log path
    env_no_log = {k: v for k, v in cand_env.items() if k != "CODEX_LOG"}
    seq_file.write_text("quota_log_only\nquota_log_only\ngeneric_log_only\n")
    c3_runs = []
    for idx in range(3):
        p = subprocess.run([sys.executable, str(cand_sb / "utils/py/relay_drive.py"), "--relay-file", str(cand_rf), "--relay-task", "RELAY-C3-SAME", "--agent-cmd", str(shim_seq), "--reviewer", "codex", "--review-once"], cwd=str(cand_sb), env=env_no_log, capture_output=True, text=True)
        recs = sorted((cand_sb / ".relay-scratch/stop-reasons").glob("RELAY-C3-SAME-*.json"))
        c3_runs.append((p.returncode, json.loads(recs[-1].read_text())))
    seen_logs = log_paths_file.read_text().strip().splitlines()
    assert len(set(seen_logs)) == 3, f"Expected 3 distinct fresh per-turn CODEX_LOG paths, got {seen_logs}"
    assert c3_runs[0][1]["reason"] == "provider-quota"
    assert c3_runs[1][1]["reason"] == "provider-quota"
    assert c3_runs[2][1]["reason"] == "turn-error"

    # Caller-reused CODEX_LOG with stale HTTP 429:
    reused_log = cand_sb / "caller-reused.log"
    reused_log.write_text("STALE PREVIOUS RUN: HTTP 429 Too Many Requests\n")
    env_reused = dict(cand_env); env_reused["CODEX_LOG"] = str(reused_log)
    seq_file.write_text("partial_overwrite\nreused_with_live_stderr_429\n")
    p_c3_partial = subprocess.run([sys.executable, str(cand_sb / "utils/py/relay_drive.py"), "--relay-file", str(cand_rf), "--relay-task", "RELAY-C3-SAME", "--agent-cmd", str(shim_seq), "--reviewer", "codex", "--review-once"], cwd=str(cand_sb), env=env_reused, capture_output=True, text=True)
    rec_c3_partial = json.loads(max((cand_sb / ".relay-scratch/stop-reasons").glob("RELAY-C3-SAME-*.json"), key=lambda _f: _f.stat().st_mtime_ns).read_text())
    p_c3_live429 = subprocess.run([sys.executable, str(cand_sb / "utils/py/relay_drive.py"), "--relay-file", str(cand_rf), "--relay-task", "RELAY-C3-SAME", "--agent-cmd", str(shim_seq), "--reviewer", "codex", "--review-once"], cwd=str(cand_sb), env=env_reused, capture_output=True, text=True)
    rec_c3_live429 = json.loads(max((cand_sb / ".relay-scratch/stop-reasons").glob("RELAY-C3-SAME-*.json"), key=lambda _f: _f.stat().st_mtime_ns).read_text())
    logs.append(
        "=== CONTROL_3_FRESH_LOG_ISOLATION_AND_REUSED_LOG_FALSIFIERS ===\n"
        f"fresh_same_task_logs={seen_logs}\n"
        f"turn1_quota={json.dumps(c3_runs[0][1])}\n"
        f"turn2_repeated_quota={json.dumps(c3_runs[1][1])}\n"
        f"turn3_generic_after_quota={json.dumps(c3_runs[2][1])}\n"
        f"caller_reused_stale429_partial_overwrite={json.dumps(rec_c3_partial)}\n"
        f"caller_reused_stale429_live_stderr_429={json.dumps(rec_c3_live429)}"
    )
    assert rec_c3_partial["reason"] == "turn-error", f"Reused stale 429 leaked! {rec_c3_partial}"
    assert rec_c3_live429["reason"] == "provider-quota", f"Live stderr 429 missed! {rec_c3_live429}"

    # --- CONTROL 4A: Post-start consult-verify escalation write failure (no STATUS: line) -> consult-escalation-write-failed (rc=1) ---
    # Create a relay file with NO STATUS: line and a shim that appends VERDICT: PASS, plus a fake consult script outputting DISAGREE
    rf_nostatus = cand_sb / "relay-system/2026-11-20/test-nostatus.md"
    rf_nostatus.write_text("# Relay Without Status Header\n\nNEXT: codex\n\n## Turn 1 — Producer\nHello\n")
    seed_tick(cand_sb, cand_env, "RELAY-C4-CV", "relay-system/2026-11-20/test-nostatus.md")
    fake_consult = cand_sb / "relay-automation"
    fake_consult.mkdir(exist_ok=True)
    consult_sh = fake_consult / "consult.sh"
    consult_sh.write_text("""#!/usr/bin/env bash
OUT=""
while [ $# -gt 0 ]; do
  if [ "$1" = "--out" ]; then OUT="$2"; shift 2; else shift; fi
done
if [ -n "$OUT" ]; then
  mkdir -p "$OUT"
  echo "DISAGREE" > "$OUT/codex.md"
  echo "[ok] codex -> $OUT/codex.md"
fi
exit 0
""")
    consult_sh.chmod(0o755)
    shim_pass = cand_sb / "shim_pass.sh"
    shim_pass.write_text(f"""#!/usr/bin/env bash
cat >> "{rf_nostatus}" <<'EOF'

## Turn 2 — Reviewer (Codex)
VERDICT: PASS
**NEXT: Producer**
EOF
exit 0
""")
    shim_pass.chmod(0o755)
    (cand_sb / ".relay-scratch/escalation-reason").write_text("cap-stalled\n")
    p_c4a = subprocess.run([
        sys.executable, str(cand_sb / "utils/py/relay_drive.py"),
        "--relay-file", str(rf_nostatus), "--relay-task", "RELAY-C4-CV",
        "--agent-cmd", str(shim_pass), "--reviewer", "codex",
        "--review-once", "--consult-verify"
    ], cwd=str(cand_sb), env=cand_env, capture_output=True, text=True)
    c4a_esc = (cand_sb / ".relay-scratch/escalation-reason").read_text().strip()
    c4a_recs = sorted((cand_sb / ".relay-scratch/stop-reasons").glob("RELAY-C4-CV-*.json"))
    rec_c4a = json.loads(c4a_recs[-1].read_text()) if c4a_recs else {}
    logs.append(f"=== CONTROL_4A_POST_START_CONSULT_ESCALATION_WRITE_FAILED (rc={p_c4a.returncode}) ===\nLEGACY_ESC={c4a_esc}\nRECEIPT={json.dumps(rec_c4a)}\nSTDERR:\n{p_c4a.stderr}")
    assert p_c4a.returncode == 1 and c4a_esc == "consult-escalation-write-failed" and rec_c4a.get("reason") == "consult-escalation-write-failed", (p_c4a.returncode, c4a_esc, rec_c4a, p_c4a.stderr)

    # --- CONTROL 4B: Preflight driver-lock contention preserves active driver's legacy escalation-reason ---
    seed_tick(cand_sb, cand_env, "RELAY-C4-LOCK", rel_rf)
    (cand_sb / ".relay-scratch/escalation-reason").write_text("active-driver-preserved-reason\n")
    lock_dir = cand_sb / ".git/relay-driver.lock"
    lock_dir.mkdir(parents=True, exist_ok=True)
    (lock_dir / "pid").write_text(str(os.getpid()) + "\n")  # Current live PID holds lock!
    p_c4b = subprocess.run([
        sys.executable, str(cand_sb / "utils/py/relay_drive.py"),
        "--relay-file", str(cand_rf), "--relay-task", "RELAY-C4-LOCK",
        "--agent-cmd", str(cand_sb / "shim_noop.sh"), "--reviewer", "codex", "--review-once"
    ], cwd=str(cand_sb), env=cand_env, capture_output=True, text=True)
    c4b_esc = (cand_sb / ".relay-scratch/escalation-reason").read_text().strip()
    rec_c4b = json.loads(max((cand_sb / ".relay-scratch/stop-reasons").glob("RELAY-C4-LOCK-*.json"), key=lambda _f: _f.stat().st_mtime_ns).read_text())
    shutil.rmtree(lock_dir)
    logs.append(f"=== CONTROL_4B_PREFLIGHT_LOCK_CONTENTION_PRESERVES_LEGACY (rc={p_c4b.returncode}) ===\nLEGACY_ESC={c4b_esc}\nRECEIPT={json.dumps(rec_c4b)}\nSTDERR:\n{p_c4b.stderr}")
    assert p_c4b.returncode == 1 and rec_c4b["reason"] == "driver-lock-active" and c4b_esc == "active-driver-preserved-reason"

    # --- CONTROL 5: Direct receipt JSON compatibility check against authoritative KS-04 kickstart_status.py ---
    ks04_script = ks04_repo / "skills/1-hourly/kickstart/scripts/kickstart_status.py"
    run_rec = td / "ks04_run_record.md"
    run_rec.write_text("# Kickstart Run\n\nRUN-RECORD-VERSION: 1\nLANDING_CLONE: /tmp/landing\n\n## Progress log\n")
    # Feed actual candidate stop-reason receipts directly to authoritative KS-04 kickstart_status.py --receipt
    rec_quota_path = max((cand_sb / ".relay-scratch/stop-reasons").glob("RELAY-C2-429-*.json"), key=lambda _f: _f.stat().st_mtime_ns)
    rec_lock_path = max((cand_sb / ".relay-scratch/stop-reasons").glob("RELAY-C4-LOCK-*.json"), key=lambda _f: _f.stat().st_mtime_ns)
    p_ks04_q = subprocess.run([
        sys.executable, str(ks04_script), "--record", str(run_rec), "--skip-prs", "--receipt", str(rec_quota_path), "--json"
    ], cwd=str(ks04_repo), capture_output=True, text=True)
    p_ks04_l = subprocess.run([
        sys.executable, str(ks04_script), "--record", str(run_rec), "--skip-prs", "--receipt", str(rec_lock_path), "--json"
    ], cwd=str(ks04_repo), capture_output=True, text=True)
    logs.append(
        f"=== CONTROL_5_KS04_DIRECT_COMPATIBILITY (ks04_sha={ks04_sha}) ===\n"
        f"CMD_QUOTA: python3 kickstart_status.py --record {run_rec} --skip-prs --receipt {rec_quota_path} --json (rc={p_ks04_q.returncode})\n"
        f"STDOUT_QUOTA:\n{p_ks04_q.stdout}\n"
        f"CMD_LOCK: python3 kickstart_status.py --record {run_rec} --skip-prs --receipt {rec_lock_path} --json (rc={p_ks04_l.returncode})\n"
        f"STDOUT_LOCK:\n{p_ks04_l.stdout}"
    )
    assert p_ks04_q.returncode == 0 and "provider-quota" in p_ks04_q.stdout, (p_ks04_q.returncode, p_ks04_q.stdout, p_ks04_q.stderr)
    assert p_ks04_l.returncode == 0 and "driver-lock-active" in p_ks04_l.stdout, (p_ks04_l.returncode, p_ks04_l.stdout, p_ks04_l.stderr)

# --- Existing Regression Checks ---
for tname in ("test/gh115-round-cap.sh", "test/gh505-relay-attest.sh"):
    pt = subprocess.run(["bash", tname], cwd=str(repo), capture_output=True, text=True)
    logs.append(f"=== REGRESSION_{tname} (rc={pt.returncode}) ===\n{pt.stdout[-1200:]}\n{pt.stderr[-600:]}")
    assert pt.returncode == 0, f"{tname} failed: {pt.stdout}\n{pt.stderr}"

out_path.write_text("\n\n".join(logs) + "\n")
print("ALL_KS05_R3_CONTROLS_PASSED bytes=", out_path.stat().st_size)
