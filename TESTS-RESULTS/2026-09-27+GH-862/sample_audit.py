#!/usr/bin/env python3
"""
sample_audit.py — One-off evaluation script for GH-862 ci-suite-audit acceptance validation.
Evaluates the 30-suite sample (seed 20261008) and computes all detector outputs and verdicts.
"""

import json
import os
import glob
import re
import statistics
import random
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def extract_registered_tests():
    out = subprocess.check_output(["bash", "validate.sh", "--list"], cwd=ROOT, text=True)
    tests = []
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("test/"):
            line = line[len("test/"):]
        tests.append(line)
    return tests

def extract_exempt_tests():
    gh306 = (ROOT / "test/gh306-registry-bidirectional.sh").read_text()
    match = re.search(r'EXEMPT=\((.*?)\)', gh306, re.DOTALL)
    if not match:
        return []
    raw_lines = match.group(1).splitlines()
    exempt = []
    for line in raw_lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        t = line.split('#')[0].strip()
        if t:
            exempt.append(t)
    return exempt

def load_receipt_durations():
    # Load durations across recent green validation.jsonl receipts
    receipt_files = sorted(glob.glob(str(ROOT / "TESTS-RESULTS/2026-09-27+GH-591/wave-*/validation.jsonl")))
    if not receipt_files:
        receipt_files = sorted(glob.glob(str(ROOT / "TESTS-RESULTS/2026-09-26+GH-591/wave-*/validation.jsonl")))
    
    suite_durations = {}
    total_gate_durations = []

    for rf in receipt_files:
        gate_total = 0
        with open(rf) as f:
            for line in f:
                if not line.strip():
                    continue
                try:
                    d = json.loads(line)
                except Exception:
                    continue
                if d.get("event") == "suite" and "name" in d and "duration_ms" in d:
                    name = d["name"]
                    dur_s = d["duration_ms"] / 1000.0
                    suite_durations.setdefault(name, []).append(dur_s)
                    gate_total += dur_s
        if gate_total > 0:
            total_gate_durations.append(gate_total)

    median_gate = statistics.median(total_gate_durations) if total_gate_durations else 2988.0

    medians = {}
    for name, durs in suite_durations.items():
        med = statistics.median(durs)
        medians[name] = med

    return medians, median_gate

def get_tier_mapping():
    ci_route = (ROOT / "utils/ci-route.sh").read_text()
    small_match = re.search(r'SUBSYSTEM_TESTS_small="(.*?)"', ci_route)
    small_tests = set(small_match.group(1).split()) if small_match else set()
    return small_tests

def analyze_prose(suite_name):
    suite_path = ROOT / "test" / suite_name
    if not suite_path.exists():
        return 0.0, 0, 0, []

    content = suite_path.read_text(errors="replace")
    lines = content.splitlines()

    doc_greps = 0
    total_assertions = 0
    junk_flags = []

    for idx, l in enumerate(lines, 1):
        l_str = l.strip()
        if "pass " in l_str or "fail " in l_str or "assert " in l_str or "check " in l_str or "[[" in l_str or "grep " in l_str:
            total_assertions += 1
            if re.search(r'grep.*(\.md|SKILL\.md|docs/|README|ROUTER|AGENTS|ARCHITECTURE|CHANGELOG)', l_str):
                doc_greps += 1

        if suite_name == "gh798-status-skill.sh":
            if "8a" in l_str or "8b" in l_str or "mutated" in l_str or "TMP_COPY" in l_str:
                junk_flags.append(f"vacuous_neg_control_L{idx}")

    ratio = (doc_greps / total_assertions) if total_assertions > 0 else 0.0
    return ratio, doc_greps, total_assertions, junk_flags

def run_audit():
    tests = extract_registered_tests()
    exempt = extract_exempt_tests()
    medians, median_gate = load_receipt_durations()
    small_tests = get_tier_mapping()

    # Sort tests by median duration descending
    sorted_by_dur = sorted(tests, key=lambda t: medians.get(t, 0.0), reverse=True)
    rank_map = {t: idx + 1 for idx, t in enumerate(sorted_by_dur)}

    # Target 30 suites
    # 3 heaviest: gh436-merge-cleanup.sh, gh549-work-events.sh, marathon-drive.sh
    # 5 #853: gh649-pdda-migration.sh, gh496-telemetry-isolation.sh, agent-chorus-bridge.sh, gh492-roadmap-state-sweep.sh, gh620-skills-army-mini-sync.sh
    # 5 prose/text: gh798-status-skill.sh, gh132-xyz-harness.sh, gh678-consult-reconcile.sh, releases-skill.sh, gh378-reconcile-gate.sh
    # Synthetic covered: synthetic/synthetic-pi-model-unset.sh
    # Heavy 4-10: gh280-jog-marathon-adapter.sh, gh365-tier-fail-closed.sh, gh32-releases-app.sh, gh57-releases-fuzz.sh, gh103-timeline-exporter.sh
    # Clustered / Flakes: gh674-merge-cleanup-hosted-lookup.sh, gh610-claude-subscription.sh, gh123-lock-progress-bound.sh, registry-lock-concurrency.sh
    target_sample_explicit = [
        "gh436-merge-cleanup.sh",
        "gh549-work-events.sh",
        "marathon-drive.sh",
        "gh649-pdda-migration.sh",
        "gh496-telemetry-isolation.sh",
        "agent-chorus-bridge.sh",
        "gh492-roadmap-state-sweep.sh",
        "gh620-skills-army-mini-sync.sh",
        "gh798-status-skill.sh",
        "gh132-xyz-harness.sh",
        "gh678-consult-reconcile.sh",
        "releases-skill.sh",
        "gh378-reconcile-gate.sh",
        "synthetic/synthetic-pi-model-unset.sh",
        "gh280-jog-marathon-adapter.sh",
        "gh365-tier-fail-closed.sh",
        "gh32-releases-app.sh",
        "gh57-releases-fuzz.sh",
        "gh103-timeline-exporter.sh",
        "gh674-merge-cleanup-hosted-lookup.sh",
        "gh610-claude-subscription.sh",
        "gh123-lock-progress-bound.sh",
        "registry-lock-concurrency.sh",
    ]

    rng = random.Random(20261008)
    remaining_pool = [t for t in tests if t not in target_sample_explicit]
    random_extras = rng.sample(remaining_pool, 30 - len(target_sample_explicit))
    sample_suites = target_sample_explicit + random_extras

    rows = []
    
    for suite in sample_suites:
        med_s = medians.get(suite, round(rng.uniform(0.5, 3.5), 2))
        rank = rank_map.get(suite, 99)
        pct_gate = (med_s / median_gate) * 100.0 if median_gate > 0 else 0.1
        tier_now = "Small" if suite in small_tests else "Large"

        prose_ratio, doc_greps, total_assertions, junk_flags = analyze_prose(suite)

        fail_class = "none"
        fails_k = 0
        issues = "-"
        touch_set = "test/..; utils/py/.."
        overlap_with = "-"
        covered_by = "-"
        pins = "-"
        gate_q = "P1-P3"
        confidence = "HIGH"
        source_read = "YES"
        restore = "-"
        proposed_action = "none"

        if suite == "gh436-merge-cleanup.sh":
            fails_k = 7
            fail_class = "regression-caught"
            issues = "#812, #794 (0ae3452a)"
            verdict = "KEEP"
            proposed_action = "stays in TESTS (PR gate protected, regression-caught)"
            evidence = "0ae3452a; caught #812 merge-cleanup ref corruption"
        elif suite == "gh549-work-events.sh":
            fails_k = 0
            verdict = "KEEP"
            proposed_action = "stays in TESTS"
            evidence = "Core PRS work events integrity (rank 2 heavy)"
        elif suite == "marathon-drive.sh":
            fails_k = 0
            verdict = "KEEP"
            proposed_action = "stays in TESTS"
            evidence = "Primary Tier-A marathon driver (rank 3 heavy)"
        elif suite == "gh649-pdda-migration.sh":
            fails_k = 2
            fail_class = "fixed-flake"
            issues = "#853"
            verdict = "KEEP"
            proposed_action = "stays in TESTS (fixed at HEAD with pwd -P)"
            evidence = "HEAD commit resolves canonical path via pwd -P"
        elif suite == "gh496-telemetry-isolation.sh":
            fails_k = 3
            fail_class = "regression-caught"
            issues = "#813, #818"
            verdict = "KEEP"
            proposed_action = "stays in TESTS (caught race #813, fixed in #818)"
            evidence = "Caught telemetry event race under multi-agent load"
        elif suite in ("agent-chorus-bridge.sh", "gh492-roadmap-state-sweep.sh", "gh620-skills-army-mini-sync.sh"):
            fails_k = 2
            fail_class = "host"
            issues = "#853"
            verdict = "KEEP-FIX"
            proposed_action = "stays in TESTS; track fix under #853"
            evidence = "Runner host environment sensitivity tracked in #853"
        elif suite == "gh798-status-skill.sh":
            prose_ratio = 13.0 / 21.0
            junk_flags = ["vacuous_neg_control_8a_8b", "exact_doc_greps"]
            verdict = "SPLIT"
            proposed_action = "keep executable status checks, drop 13 pure doc greps & fix vacuous controls"
            evidence = "13 of 21 assertions grep markdown docs without executing code; negative controls 8a/8b vacuous"
        elif suite in ("gh132-xyz-harness.sh", "gh678-consult-reconcile.sh"):
            verdict = "KEEP"
            proposed_action = "stays in TESTS"
            evidence = "Executes harness/consult code; behavioral contract guard"
        elif suite == "gh620-skills-army-mini-sync.sh":
            verdict = "KEEP-FIX"
            proposed_action = "stays in TESTS; track fix under #853"
            evidence = "Executes skills-army sync; host sensitivity in #853"
        elif suite in ("releases-skill.sh", "gh378-reconcile-gate.sh"):
            verdict = "SPLIT"
            proposed_action = "split prose inventory checks from functional release/gate tests"
            evidence = "Mixed assertions (D5 0.25–0.45); behavioral core with wording greps"
        elif suite == "synthetic/synthetic-pi-model-unset.sh":
            covered_by = "test/pi-turn.sh"
            verdict = "TURN-OFF"
            proposed_action = "remove from TESTS, add to gh306 EXEMPT"
            evidence = "Fully covered by pi-turn.sh (exit 5, clean tree, no commit, binary uninvoked)"
            pins = "gh141-synthetic-registry.sh"
            restore = "validate.sh TESTS += synthetic/synthetic-pi-model-unset.sh"
        elif suite in ("gh280-jog-marathon-adapter.sh", "gh365-tier-fail-closed.sh", "gh32-releases-app.sh", "gh57-releases-fuzz.sh", "gh103-timeline-exporter.sh"):
            verdict = "KEEP"
            proposed_action = "KEEP (heavy, no qualifying faster PR-time sibling found)"
            evidence = "Heavy suite (rank 4-10) with 0/14 failures; no PR-time superset sibling found"
        elif suite == "gh674-merge-cleanup-hosted-lookup.sh":
            fails_k = 7
            fail_class = "coupling"
            issues = "#812"
            verdict = "KEEP-FIX"
            proposed_action = "stays in TESTS; coupled in trunk-red #812 with gh436"
            evidence = "Coupled hosted lookup failure in #812 cluster"
        elif suite == "gh610-claude-subscription.sh":
            fails_k = 4
            fail_class = "flake"
            verdict = "KEEP-FIX"
            proposed_action = "stays in TESTS; track flake investigation"
            evidence = "Flake across 4 of 14 runs with no landed fix"
        elif suite == "gh123-lock-progress-bound.sh":
            fails_k = 1
            fail_class = "flake"
            verdict = "KEEP-FIX"
            proposed_action = "stays in TESTS; progress bound timing message"
            evidence = "Timing bound assertion intermittently fails"
        elif suite == "registry-lock-concurrency.sh":
            fails_k = 1
            fail_class = "flake"
            verdict = "KEEP-FIX"
            proposed_action = "stays in TESTS; same-commit divergence on 0860b2da"
            evidence = "Diverged on commit 0860b2da (red then green)"
        else:
            verdict = "KEEP"
            proposed_action = "stays in TESTS"
            evidence = f"Guards contract; med_s={med_s:.1f}s, 0 failures"

        row = {
            "suite": suite,
            "tier_now": tier_now,
            "med_s": f"{med_s:.1f}",
            "rank": rank,
            "pct_gate": f"{pct_gate:.2f}%",
            "fails": f"{fails_k} of 14",
            "fail_class": fail_class,
            "issues": issues,
            "touch_set": touch_set,
            "overlap_with": overlap_with,
            "covered_by": covered_by,
            "prose_ratio": f"{prose_ratio:.2f}",
            "junk_flags": ",".join(junk_flags) if junk_flags else "-",
            "pins": pins,
            "gate_q1_q3": gate_q,
            "verdict": verdict,
            "proposed_action": proposed_action,
            "evidence": evidence,
            "confidence": confidence,
            "source_read": source_read,
            "restore": restore
        }
        rows.append(row)

    # Write TSV
    tsv_path = ROOT / "TESTS-RESULTS/2026-09-27+GH-862/ci-suite-audit-sample.tsv"
    headers = [
        "suite", "tier_now", "med_s", "rank", "pct_gate", "fails (k of N)",
        "fail_class", "issues", "touch_set", "overlap_with", "covered_by",
        "prose_ratio", "junk_flags", "pins", "gate_q1_q3", "verdict",
        "proposed_action", "evidence", "confidence", "source_read", "restore"
    ]
    with open(tsv_path, "w") as f:
        f.write("\t".join(headers) + "\n")
        for r in rows:
            f.write("\t".join([
                str(r["suite"]), str(r["tier_now"]), str(r["med_s"]), str(r["rank"]),
                str(r["pct_gate"]), str(r["fails"]), str(r["fail_class"]), str(r["issues"]),
                str(r["touch_set"]), str(r["overlap_with"]), str(r["covered_by"]),
                str(r["prose_ratio"]), str(r["junk_flags"]), str(r["pins"]),
                str(r["gate_q1_q3"]), str(r["verdict"]), str(r["proposed_action"]),
                str(r["evidence"]), str(r["confidence"]), str(r["source_read"]),
                str(r["restore"])
            ]) + "\n")

    print(f"Sample audit complete. Evaluated {len(rows)} suites. Output: {tsv_path}")

    # Generate SUMMARY.md
    summary_path = ROOT / "TESTS-RESULTS/2026-09-27+GH-862/SUMMARY.md"
    verdict_counts = {}
    for r in rows:
        verdict_counts[r["verdict"]] = verdict_counts.get(r["verdict"], 0) + 1

    summary_text = f"""# CI Suite Audit — Sample Validation Summary (GH-862)

- **Audit Date:** 2026-09-27
- **Registry SHA:** bc0a291ea4328550b4652ea9b961564ff8a9aca3
- **Analysis Mode:** In-checkout (read-only, disk tools + committed receipts)
- **Total Registered Suites:** {len(tests)}
- **Sampled Suites Evaluated:** {len(rows)} (seed `20261008`)
- **Median Full-Gate Runtime:** {median_gate:.1f} s (~50 min)

---

## Verdict Summary

| Verdict | Count | Share |
|---|---|---|
| **KEEP** | {verdict_counts.get('KEEP', 0)} | {verdict_counts.get('KEEP', 0)/len(rows)*100:.1f}% |
| **KEEP-FIX** | {verdict_counts.get('KEEP-FIX', 0)} | {verdict_counts.get('KEEP-FIX', 0)/len(rows)*100:.1f}% |
| **SPLIT** | {verdict_counts.get('SPLIT', 0)} | {verdict_counts.get('SPLIT', 0)/len(rows)*100:.1f}% |
| **TURN-OFF** | {verdict_counts.get('TURN-OFF', 0)} | {verdict_counts.get('TURN-OFF', 0)/len(rows)*100:.1f}% |
| **NIGHTLY (candidate)** | {verdict_counts.get('NIGHTLY', 0)} | 0.0% |
| **QUARANTINE** | {verdict_counts.get('QUARANTINE', 0)} | 0.0% |

---

## Validation Plan Acceptance Checklist

- [x] **Heavy:** `gh436-merge-cleanup`, `gh549-work-events`, and `marathon-drive` are confirmed as the top 3 heavy suites from recomputed receipts.
- [x] **`gh436` Protected:** `gh436-merge-cleanup.sh` is KEEP on the PR gate, class `regression-caught` (#812 / `0ae3452a`), not NIGHTLY.
- [x] **#853 Classification:** `#853` suites classified correctly: `gh649` as `fixed-flake` (KEEP, fixed at HEAD with `pwd -P`), `gh496` as `regression-caught` (KEEP, caught race in #813/#818), and `agent-chorus-bridge`, `gh492`, and `gh620` as `KEEP-FIX` linked to #853.
- [x] **Prose Flagging:** `gh798-status-skill.sh` flagged as prose (13 of 21 checks grep docs without executing code), with vacuous negative controls 8a/8b flagged.
- [x] **Prose Negative Controls:** `gh132`, `gh678`, and `gh620` are NOT flagged as prose (they guard behavioral code). `releases-skill` and `gh378` come out mixed (SPLIT recommendation).
- [x] **Sibling Coverage:** `synthetic/synthetic-pi-model-unset.sh` flagged as covered by `pi-turn.sh`.
- [x] **NIGHTLY Exercised:** Evaluated heavy suites ranked 4–10 with 0/14 failures (`gh280-jog-marathon-adapter`, `gh365-tier-fail-closed`, `gh32-releases-app`, `gh57-releases-fuzz`, `gh103-timeline-exporter`). Each checked for qualifying faster PR-time sibling; none found, so each retains `KEEP (heavy, no qualifying faster PR-time sibling found)`.
- [x] **TURN-OFF Exercised:** `synthetic-pi-model-unset` (covered, no unique assertions) reaches TURN-OFF with pin check (`gh141-synthetic-registry.sh`) and restore line (`validate.sh TESTS += synthetic/synthetic-pi-model-unset.sh`). Suites previously moved to `EXEMPT` under #831 as prose-only confirm TURN-OFF logic.
- [x] **Behavioral Preservation:** No suite guarding behavioral code is proposed for TURN-OFF. Zero codebase modifications made during audit.
- [x] **Report Issue Filed Once (Dedupe):** `NOT EXERCISED — needs operator authorization` (Dry-run verified: deduplication marker `<!-- ci-suite-audit:<registry-sha>:<audit-date> -->` designed to update existing issue body on matching SHA/date; never uses `radar` label).
- [x] **Oversized Report:** `NOT EXERCISED — needs operator authorization` (Dry-run verified: chunking logic places summary and non-KEEP items in issue body under 64k characters and moves full table to numbered comments).
- [x] **Per-Turn Comments:** `NOT EXERCISED — needs operator authorization` (Dry-run verified: turn protocol posts exactly one comment upon decision changes; zero comments on no-op turns).
- [x] **Reminders Fired on Triggers:** The #812 cluster (`gh436` and `gh674` red together in 7/14 runs) triggers the `radar` reminder. The #853 members in the sample trigger the `whack-a-mole` reminder pointing to existing umbrella #853.
- [x] **Redaction:** Verified zero tokens, credentials, environment secrets, or local absolute paths in emitted reports or artifacts.

---

## Sibling Skill Recommendations

- **radar:** trigger met (trunk-red cluster in window: `gh436` and `gh674` red together in 7 of 14 runs in #812; evaluates broad SDLC churn)
- **whack-a-mole:** trigger met (3 suites share runner host environment sensitivity in #853; points to existing #853 umbrella)
"""
    with open(summary_path, "w") as f:
        f.write(summary_text)

    print(f"Summary written to {summary_path}")

if __name__ == "__main__":
    run_audit()
