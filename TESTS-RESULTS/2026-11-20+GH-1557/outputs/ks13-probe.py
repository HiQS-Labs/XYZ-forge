#!/usr/bin/env python3
"""GH-1557 (KS-13) Paired Red/Green Replay & Edge-Control Probe.

Part A: Executed CLI & parser controls comparing pre-change origin/development
        kickstart_status.py (baseline) vs candidate kickstart_status.py + run_record.py.
Part B: Explicitly labeled SIMULATED pre-handback consumer walkthrough exercising the
        single reconciled decision table against real kickstart_status.py --json outputs.
        (Does NOT claim live autonomous full-gate execution, which is measured in run 2.)
"""
import json, subprocess, sys, tempfile
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
out_path = Path(sys.argv[2]).resolve()

base_sha = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "origin/development"], text=True).strip()
cand_sha = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()

SHA1 = "1111111111111111111111111111111111111111"  # run-1 head after PR #1534 (initial final-QA)
SHA2 = "2222222222222222222222222222222222222222"  # run-1 head after later PR #1539 landing
SHA3 = "3333333333333333333333333333333333333333"  # concurrent landing occurring DURING final-QA re-run

logs: list[str] = [
    f"=== KS-13 PROBE METADATA ===\nBASE_ORIGIN_DEVELOPMENT={base_sha}\nCANDIDATE_HEAD={cand_sha}\n"
    f"PROBE_SOURCE=TESTS-RESULTS/2026-11-20+GH-1557/outputs/ks13-probe.py"
]

def run_status(script: Path, record: Path, dev_head: str | None = None) -> tuple[list[str], int, dict, str]:
    cmd = [sys.executable, str(script), "--record", str(record), "--skip-prs", "--json"]
    if dev_head is not None:
        cmd += ["--development-head", dev_head]
    p = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(p.stdout) if p.returncode == 0 else {}
    return cmd, p.returncode, data, p.stderr

with tempfile.TemporaryDirectory() as td_s:
    td = Path(td_s).resolve()

    # Materialize exact pre-change baseline kickstart_status.py + run_record.py from origin/development
    base_dir = td / "baseline_scripts"
    base_dir.mkdir()
    for fname in ("kickstart_status.py", "run_record.py"):
        content = subprocess.check_output(
            ["git", "-C", str(repo), "show", f"origin/development:skills/1-hourly/kickstart/scripts/{fname}"],
            text=True,
        )
        (base_dir / fname).write_text(content, encoding="utf-8")
    base_ks = base_dir / "kickstart_status.py"
    cand_ks = repo / "skills/1-hourly/kickstart/scripts/kickstart_status.py"
    cand_rr = repo / "skills/1-hourly/kickstart/scripts/run_record.py"

    # --- PART A.1: ISOLATED MULTI-SHA SUPPRESSION RED vs GREEN CONTROL ---
    rec_multi = td / "rec_multi.md"
    rec_multi.write_text(
        "# Kickstart Run\n\nRUN-RECORD-VERSION: 1\nLANDING_CLONE: /tmp/landing\n\n## Progress log\n"
        f"- PR #1534: MERGED ({SHA1}) 2026-11-20T08:00Z\n"
        f"GATE: final-QA {SHA1} full 920s green 2026-11-20T08:15:00Z\n"
        f"- PR #1539: MERGED (rebased from {SHA1}, merge {SHA2}) 2026-11-20T08:45Z\n"
    )
    # Test with dev_head=None AND dev_head=SHA1 (old QA head) to isolate later_landings from head-mismatch!
    _, rc_b_none, d_b_none, _ = run_status(base_ks, rec_multi, None)
    _, rc_c_none, d_c_none, _ = run_status(cand_ks, rec_multi, None)
    _, rc_b_old, d_b_old, _ = run_status(base_ks, rec_multi, SHA1)
    _, rc_c_old, d_c_old, _ = run_status(cand_ks, rec_multi, SHA1)

    logs.append(
        "=== PART_A1_ISOLATED_MULTI_SHA_RED_VS_GREEN ===\n"
        f"BASE (dev_head=None): status={d_b_none['final_qa']['status']} later_landings={len(d_b_none['final_qa']['later_landings'])} has_handback_allowed={'handback_allowed' in d_b_none['final_qa']}\n"
        f"CAND (dev_head=None): status={d_c_none['final_qa']['status']} later_landings={len(d_c_none['final_qa']['later_landings'])} rerun_required={d_c_none['final_qa']['rerun_required']} handback_allowed={d_c_none['final_qa']['handback_allowed']} action={d_c_none['final_qa']['recommended_action']}\n"
        f"BASE (dev_head=SHA1): status={d_b_old['final_qa']['status']} later_landings={len(d_b_old['final_qa']['later_landings'])}\n"
        f"CAND (dev_head=SHA1): status={d_c_old['final_qa']['status']} later_landings={len(d_c_old['final_qa']['later_landings'])} rerun_required={d_c_old['final_qa']['rerun_required']} handback_allowed={d_c_old['final_qa']['handback_allowed']} action={d_c_old['final_qa']['recommended_action']}"
    )
    assert rc_b_none == 0 and d_b_none["final_qa"]["status"] == "unknown" and len(d_b_none["final_qa"]["later_landings"]) == 0
    assert rc_c_none == 0 and d_c_none["final_qa"]["status"] == "stale" and len(d_c_none["final_qa"]["later_landings"]) == 1 and d_c_none["final_qa"]["rerun_required"] is True and d_c_none["final_qa"]["handback_allowed"] is False
    assert rc_b_old == 0 and d_b_old["final_qa"]["status"] == "fresh" and len(d_b_old["final_qa"]["later_landings"]) == 0
    assert rc_c_old == 0 and d_c_old["final_qa"]["status"] == "stale" and len(d_c_old["final_qa"]["later_landings"]) == 1 and d_c_old["final_qa"]["rerun_required"] is True and d_c_old["final_qa"]["handback_allowed"] is False

    # --- PART A.2: NONEMPTY / ALL-TRUE BOUNDARY CONTROLS (SAME-SHA-ONLY vs SHA-LESS) ---
    rec_same_only = td / "rec_same_only.md"
    rec_same_only.write_text(
        "# Kickstart Run\n\nRUN-RECORD-VERSION: 1\nLANDING_CLONE: /tmp/landing\n\n## Progress log\n"
        f"GATE: final-QA {SHA1} full 920s green 2026-11-20T08:15:00Z\n"
        f"- PR #1534: MERGED retroactive log ({SHA1}) 2026-11-20T08:16Z\n"
    )
    rec_shaless = td / "rec_shaless.md"
    rec_shaless.write_text(
        "# Kickstart Run\n\nRUN-RECORD-VERSION: 1\nLANDING_CLONE: /tmp/landing\n\n## Progress log\n"
        f"GATE: final-QA {SHA1} full 920s green 2026-11-20T08:15:00Z\n"
        "- PR #1539: MERGED (no sha recorded yet) 2026-11-20T08:45Z\n"
    )
    _, _, d_same, _ = run_status(cand_ks, rec_same_only, SHA1)
    _, _, d_shaless_b, _ = run_status(base_ks, rec_shaless, SHA1)
    _, _, d_shaless_c, _ = run_status(cand_ks, rec_shaless, SHA1)
    logs.append(
        "=== PART_A2_BOUNDARY_SAME_SHA_AND_SHALESS ===\n"
        f"SAME_SHA_ONLY (CAND): status={d_same['final_qa']['status']} later_landings={len(d_same['final_qa']['later_landings'])} handback_allowed={d_same['final_qa']['handback_allowed']}\n"
        f"SHALESS (BASE preserved): status={d_shaless_b['final_qa']['status']} later_landings={len(d_shaless_b['final_qa']['later_landings'])}\n"
        f"SHALESS (CAND preserved): status={d_shaless_c['final_qa']['status']} later_landings={len(d_shaless_c['final_qa']['later_landings'])} rerun_required={d_shaless_c['final_qa']['rerun_required']} handback_allowed={d_shaless_c['final_qa']['handback_allowed']}"
    )
    assert d_same["final_qa"]["status"] == "fresh" and len(d_same["final_qa"]["later_landings"]) == 0 and d_same["final_qa"]["handback_allowed"] is True
    assert d_shaless_b["final_qa"]["status"] == "stale" and len(d_shaless_b["final_qa"]["later_landings"]) == 1
    assert d_shaless_c["final_qa"]["status"] == "stale" and len(d_shaless_c["final_qa"]["later_landings"]) == 1 and d_shaless_c["final_qa"]["rerun_required"] is True

    # --- PART A.3: RUN-1 LATER-LANDING SEQUENCE REPLAY (CLI + run_record.py append + failed rerun + landing-during-QA) ---
    rec_seq = td / "rec_run1_seq.md"
    rec_seq.write_text(
        "# Kickstart Run 1 Replay\n\nRUN-RECORD-VERSION: 1\nLANDING_CLONE: /tmp/landing\n\n## Progress log\n"
        f"- PR #1534: MERGED ({SHA1}) 2026-11-20T08:00Z\n"
        f"GATE: final-QA {SHA1} full 920s green 2026-11-20T08:15:00Z\n"
    )
    _, _, s1, _ = run_status(cand_ks, rec_seq, SHA1)
    assert s1["final_qa"]["status"] == "fresh" and s1["final_qa"]["handback_allowed"] is True and s1["final_qa"]["recommended_action"] == "handback-ready"

    # Step 2: later PR #1539 lands
    with rec_seq.open("a", encoding="utf-8") as f:
        f.write(f"- PR #1539: MERGED ({SHA2}) 2026-11-20T08:45Z\n")
    _, _, s2, _ = run_status(cand_ks, rec_seq, SHA2)
    assert s2["final_qa"]["status"] == "stale" and s2["final_qa"]["rerun_required"] is True and s2["final_qa"]["handback_allowed"] is False and s2["final_qa"]["recommended_action"] == "rerun-final-qa"

    # Step 3: failed rerun appends red via real run_record.py append -> blocks handback
    subprocess.run([sys.executable, str(cand_rr), "append", str(rec_seq), "--kind", "gate", "--target", "final-QA", "--sha", SHA2, "--route", "full", "--seconds", "300", "--verdict", "red"], check=True)
    _, _, s3, _ = run_status(cand_ks, rec_seq, SHA2)
    assert s3["final_qa"]["status"] == "stale" and s3["final_qa"]["final_qa_verdict"] == "red" and s3["final_qa"]["rerun_required"] is True and s3["final_qa"]["handback_allowed"] is False

    # Step 4: rerun passes green on SHA2, BUT concurrent landing SHA3 occurred during QA -> post-QA re-verify catches SHA3 != SHA2!
    subprocess.run([sys.executable, str(cand_rr), "append", str(rec_seq), "--kind", "gate", "--target", "final-QA", "--sha", SHA2, "--route", "full", "--seconds", "890", "--verdict", "green"], check=True)
    _, _, s4, _ = run_status(cand_ks, rec_seq, SHA3)
    assert s4["final_qa"]["status"] == "stale" and s4["final_qa"]["rerun_required"] is True and s4["final_qa"]["handback_allowed"] is False and SHA3 in s4["final_qa"]["reason"]

    # Step 5: rerun passes green on verified final head SHA3 -> fresh & handback_allowed=True
    subprocess.run([sys.executable, str(cand_rr), "append", str(rec_seq), "--kind", "gate", "--target", "final-QA", "--sha", SHA3, "--route", "full", "--seconds", "890", "--verdict", "green"], check=True)
    _, _, s5, _ = run_status(cand_ks, rec_seq, SHA3)
    assert s5["final_qa"]["status"] == "fresh" and s5["final_qa"]["rerun_required"] is False and s5["final_qa"]["handback_allowed"] is True and s5["final_qa"]["final_qa_sha"] == SHA3

    # Also capture markdown render of stale state vs fresh state
    md_fresh = subprocess.run([sys.executable, str(cand_ks), "--record", str(rec_seq), "--development-head", SHA3, "--skip-prs"], capture_output=True, text=True, check=True).stdout
    logs.append(
        "=== PART_A3_RUN1_LATER_LANDING_SEQUENCE_CLI_REPLAY ===\n"
        f"STEP1_INITIAL_QA_SHA1: {json.dumps(s1['final_qa'])}\n"
        f"STEP2_AFTER_PR1539_SHA2: {json.dumps(s2['final_qa'])}\n"
        f"STEP3_FAILED_RERUN_RED: {json.dumps(s3['final_qa'])}\n"
        f"STEP4_LANDING_DURING_QA_SHA3: {json.dumps(s4['final_qa'])}\n"
        f"STEP5_FINAL_GREEN_SHA3: {json.dumps(s5['final_qa'])}\n"
        f"MARKDOWN_FRESH_SNIPPET:\n{md_fresh[md_fresh.index('## Final-QA Staleness'):]}"
    )

    # --- PART A.4: DECISION-TABLE EDGE CONTROLS ---
    # (a) Non-landing task GATE: line after final-QA stays fresh
    rec_task_gate = td / "rec_task_gate.md"
    rec_task_gate.write_text(
        "# Kickstart Run\n\nRUN-RECORD-VERSION: 1\nLANDING_CLONE: /tmp/landing\n\n## Progress log\n"
        f"- PR #1534: MERGED ({SHA1}) 2026-11-20T08:00Z\n"
        f"GATE: final-QA {SHA1} full 920s green 2026-11-20T08:15:00Z\n"
        f"GATE: TASK-999 {SHA2} docs 120s green 2026-11-20T08:20:00Z\n"
    )
    _, _, e_task, _ = run_status(cand_ks, rec_task_gate, SHA1)
    assert e_task["final_qa"]["status"] == "fresh" and e_task["final_qa"]["handback_allowed"] is True

    # (b) Missing final-QA WITH landings -> run-final-qa / handback_allowed=False
    rec_miss_land = td / "rec_miss_land.md"
    rec_miss_land.write_text(
        "# Kickstart Run\n\nRUN-RECORD-VERSION: 1\nLANDING_CLONE: /tmp/landing\n\n## Progress log\n"
        f"- PR #1534: MERGED ({SHA1}) 2026-11-20T08:00Z\n"
    )
    _, _, e_ml, _ = run_status(cand_ks, rec_miss_land, SHA1)
    assert e_ml["final_qa"]["status"] == "missing" and e_ml["final_qa"]["rerun_required"] is True and e_ml["final_qa"]["handback_allowed"] is False and e_ml["final_qa"]["recommended_action"] == "run-final-qa"

    # (c) Missing final-QA WITH ZERO landings -> handback-ready-no-landings / handback_allowed=True
    rec_miss_zero = td / "rec_miss_zero.md"
    rec_miss_zero.write_text("# Kickstart Run\n\nRUN-RECORD-VERSION: 1\nLANDING_CLONE: /tmp/landing\n\n## Progress log\n")
    _, _, e_m0, _ = run_status(cand_ks, rec_miss_zero, SHA1)
    assert e_m0["final_qa"]["status"] == "missing" and e_m0["final_qa"]["rerun_required"] is False and e_m0["final_qa"]["handback_allowed"] is True and e_m0["final_qa"]["recommended_action"] == "handback-ready-no-landings"

    # (d) Unverified --development-head -> unknown / verify-development-head / handback_allowed=False
    _, _, e_unk, _ = run_status(cand_ks, rec_task_gate, None)
    assert e_unk["final_qa"]["status"] == "unknown" and e_unk["final_qa"]["rerun_required"] is False and e_unk["final_qa"]["handback_allowed"] is False and e_unk["final_qa"]["recommended_action"] == "verify-development-head"

    logs.append(
        "=== PART_A4_DECISION_TABLE_EDGE_CONTROLS ===\n"
        f"NON_LANDING_TASK_GATE: status={e_task['final_qa']['status']} handback_allowed={e_task['final_qa']['handback_allowed']}\n"
        f"MISSING_WITH_LANDINGS: status={e_ml['final_qa']['status']} rerun_required={e_ml['final_qa']['rerun_required']} handback_allowed={e_ml['final_qa']['handback_allowed']} action={e_ml['final_qa']['recommended_action']}\n"
        f"MISSING_ZERO_LANDINGS: status={e_m0['final_qa']['status']} rerun_required={e_m0['final_qa']['rerun_required']} handback_allowed={e_m0['final_qa']['handback_allowed']} action={e_m0['final_qa']['recommended_action']}\n"
        f"UNKNOWN_DEV_HEAD: status={e_unk['final_qa']['status']} rerun_required={e_unk['final_qa']['rerun_required']} handback_allowed={e_unk['final_qa']['handback_allowed']} action={e_unk['final_qa']['recommended_action']}"
    )

    # --- PART B: SIMULATED PRE-HANDBACK CONSUMER WALKTHROUGH (EXPLICITLY LABELED SIMULATED) ---
    # Exercises the SKILL.md decision table against real kickstart_status.py --json outputs without claiming live full-gate runtime execution.
    def simulated_child_pre_handback(record: Path, remote_heads: list[str | None], qa_verdicts: list[str]) -> list[str]:
        trace: list[str] = []
        idx_head = 0
        idx_v = 0
        for _ in range(4):
            cur_head = remote_heads[min(idx_head, len(remote_heads) - 1)]
            _, _, rep, _ = run_status(cand_ks, record, cur_head)
            fqa = rep["final_qa"]
            trace.append(f"check(head={cur_head[:8] if cur_head else 'None'}) -> status={fqa['status']} action={fqa['recommended_action']} handback={fqa['handback_allowed']}")
            if fqa["handback_allowed"]:
                trace.append(f"HANDBACK_OK ({fqa['recommended_action']})")
                return trace
            if fqa["status"] == "unknown":
                if idx_head + 1 < len(remote_heads) and remote_heads[idx_head + 1] is not None:
                    idx_head += 1
                    continue
                trace.append("HOLD_HANDBACK (remote development head unverified)")
                return trace
            if fqa["rerun_required"]:
                verdict = qa_verdicts[min(idx_v, len(qa_verdicts) - 1)]
                idx_v += 1
                tested = cur_head or fqa["target_head"] or SHA1
                subprocess.run([sys.executable, str(cand_rr), "append", str(record), "--kind", "gate", "--target", "final-QA", "--sha", tested, "--route", "full", "--seconds", "880", "--verdict", verdict], check=True)
                trace.append(f"SIMULATED_AUTONOMOUS_RERUN(tested={tested[:8]}, verdict={verdict}, parent_prompts=0)")
                if verdict != "green":
                    trace.append("HOLD_NORMAL_COMPLETION (failed rerun red)")
                    return trace
                # Post-QA re-fetch simulates whether remote head advanced during QA
                if idx_head + 1 < len(remote_heads):
                    idx_head += 1
        return trace

    # Sim 1: empty run (0 landings) -> immediate handback without QA
    sim_empty = simulated_child_pre_handback(rec_miss_zero, [SHA1], [])
    # Sim 2: stale after PR #1539 -> autonomous rerun on SHA2 -> post-QA re-verify finds SHA3 -> second rerun on SHA3 -> handback ok
    rec_sim2 = td / "rec_sim2.md"
    rec_sim2.write_text(
        "# Sim 2\n\nRUN-RECORD-VERSION: 1\nLANDING_CLONE: /tmp/landing\n\n## Progress log\n"
        f"- PR #1534: MERGED ({SHA1}) 2026-11-20T08:00Z\n"
        f"GATE: final-QA {SHA1} full 920s green 2026-11-20T08:15:00Z\n"
        f"- PR #1539: MERGED ({SHA2}) 2026-11-20T08:45Z\n"
    )
    sim_stale_to_green = simulated_child_pre_handback(rec_sim2, [SHA2, SHA3], ["green", "green"])
    # Sim 3: failed rerun -> hold normal completion
    rec_sim3 = td / "rec_sim3.md"
    rec_sim3.write_text(rec_sim2.read_text())
    sim_failed = simulated_child_pre_handback(rec_sim3, [SHA2], ["red"])
    # Sim 4: unknown head unable to verify -> hold handback
    sim_unknown_hold = simulated_child_pre_handback(rec_task_gate, [None], [])

    assert sim_empty[-1] == "HANDBACK_OK (handback-ready-no-landings)"
    assert sim_stale_to_green[-1] == "HANDBACK_OK (handback-ready)" and sum("SIMULATED_AUTONOMOUS_RERUN" in x for x in sim_stale_to_green) == 2
    assert sim_failed[-1] == "HOLD_NORMAL_COMPLETION (failed rerun red)"
    assert sim_unknown_hold[-1] == "HOLD_HANDBACK (remote development head unverified)"

    logs.append(
        "=== PART_B_SIMULATED_CONSUMER_WALKTHROUGH (SIMULATED; NO LIVE FULL-GATE RUNTIME CLAIM) ===\n"
        f"SIM_EMPTY_RUN: {sim_empty}\n"
        f"SIM_STALE_CONCURRENT_LANDING_RERUN: {sim_stale_to_green}\n"
        f"SIM_FAILED_RERUN_HOLD: {sim_failed}\n"
        f"SIM_UNKNOWN_HEAD_HOLD: {sim_unknown_hold}"
    )

out_path.write_text("\n\n".join(logs) + "\n", encoding="utf-8")
print("ALL_KS13_CONTROLS_PASSED bytes=", out_path.stat().st_size)
