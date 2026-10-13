import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

# Add planner script directory to sys.path
planner_dir = Path(__file__).parent.parent / "skills" / "3-weekly" / "weekly-planner" / "scripts"
sys.path.insert(0, str(planner_dir))

import planner_core


def test_detect_merge_sequence_phases():
    prs = [
        {
            "number": 101,
            "title": "feat: clean ready PR",
            "isDraft": False,
            "reviewDecision": "APPROVED",
            "mergeable": "MERGEABLE",
            "statusCheckRollup": [{"status": "COMPLETED", "conclusion": "SUCCESS"}],
            "body": "",
        },
        {
            "number": 102,
            "title": "feat: ready but draft PR",
            "isDraft": True,
            "reviewDecision": "APPROVED",
            "mergeable": "MERGEABLE",
            "statusCheckRollup": [{"status": "COMPLETED", "conclusion": "SUCCESS"}],
            "body": "",
        },
        {
            "number": 103,
            "title": "docs: Retain qualification receipts (GH-1012)",
            "isDraft": True,
            "reviewDecision": "NONE",
            "mergeable": "MERGEABLE",
            "statusCheckRollup": [],
            "body": "Evidence carrier for test runs.",
        },
        {
            "number": 104,
            "title": "[HOLD] feat: held spike",
            "isDraft": False,
            "reviewDecision": "NONE",
            "mergeable": "MERGEABLE",
            "statusCheckRollup": [],
            "body": "Held pending review authority.",
        },
        {
            "number": 105,
            "title": "feat: conflicting branch",
            "isDraft": False,
            "reviewDecision": "NONE",
            "mergeable": "CONFLICTING",
            "statusCheckRollup": [],
            "body": "",
        },
    ]

    seq = planner_core.detect_merge_sequence(prs)
    phases = seq["status_phases"]

    ready_nums = [p["number"] for p in phases["ready_to_land"]]
    undraft_nums = [p["number"] for p in phases["ready_pending_undraft"]]
    held_nums = [p["number"] for p in phases["evidence_carriers_or_held"]]
    rebase_nums = [p["number"] for p in phases["needs_rebase"]]

    assert 101 in ready_nums
    assert 102 in undraft_nums
    assert 103 in held_nums
    assert 104 in held_nums
    assert 105 in rebase_nums


def test_adversarial_audit_ignores_evidence_carriers():
    prs = [
        {
            "number": 1034,
            "title": "feat(GH-1012): implement core feature",
            "isDraft": False,
            "reviewDecision": "NONE",
            "mergeable": "MERGEABLE",
            "statusCheckRollup": [],
            "body": "Resolves #1012",
        },
        {
            "number": 1039,
            "title": "docs(GH-1012): Retain qualification receipts",
            "isDraft": True,
            "reviewDecision": "NONE",
            "mergeable": "MERGEABLE",
            "statusCheckRollup": [],
            "body": "Evidence carrier for #1012. Do not merge.",
        },
    ]

    plan = {"prs": prs, "tasks": []}
    audit = planner_core.audit_adversarial(plan, prs=prs)
    findings = [f for f in audit["findings"] if f["type"] == "TASK_DUPLICATION"]

    # Since 1039 is an evidence carrier, no duplication conflict should be flagged
    assert len(findings) == 0


def test_format_weekly_markdown():
    plan_data = {
        "timestamp": "2026-10-13T06:00:00Z",
        "intake_mode": "native_prs",
        "decisions_issue": 202,
        "release_milestones": {
            "next_release": "0.6.0 Front-Door (draft) target=2026-09-26",
            "overdue_note": " (17 days overdue)",
            "upcoming_releases": ["0.8.0 Sundown (draft) target=2026-10-17"],
        },
        "merge_sequence": {
            "status_phases": {
                "ready_to_land": [],
                "ready_pending_undraft": [{"number": 102, "title": "feat: undraft candidate", "ci_status": "SUCCESS"}],
                "blockers_to_fix": [],
                "needs_rebase": [],
                "in_review_or_wip": [],
                "evidence_carriers_or_held": [{"number": 1039, "title": "receipts", "hold_reason": "Evidence carrier (leave unmerged)"}],
            }
        },
        "teammate_assignments": {
            "Noel": {
                "domain": "Orchestration/Gate",
                "tasks": [{"gh_number": 854, "title": "Execute approved gate dispositions", "assignment_source": "GitHub assignee (@noelsaw1)"}],
            },
            "Jose": {"domain": "Data/Pipeline", "tasks": []},
        },
        "unassigned_items": [{"gh_number": 920, "title": "Deferred ungated warning"}],
        "deferred_items": [{"gh_number": 916, "title": "Deferred: attribute live relay"}],
        "adversarial_audit": {"findings": []},
    }

    md = planner_core.format_weekly_markdown("2026-10-13", plan_data)

    assert "## 0. Release Milestone Context & Active Targets" in md
    assert "0.6.0 Front-Door" in md
    assert "(17 days overdue)" in md
    assert "Phase 2: Ready Pending Undraft" in md
    assert "Phase 5: Held Drafts & Evidence Carriers" in md
    assert "Noel (Orchestration/Gate)" in md
    assert "GH-854" in md
    assert "[GitHub assignee (@noelsaw1)]" in md
    assert "Unassigned / Triage Queue" in md
    assert "GH-920" in md
    assert "Deferred / Parked Intake" in md
    assert "GH-916" in md


def test_compute_prs_score():
    # 1. 4-axis rating calculation
    item_4axis = {
        "rating_pri": 80,
        "rating_sev": 75,
        "rating_appeal": 85,
        "rating_effort": 90,
    }
    score, badge = planner_core.compute_prs_score(item_4axis)
    assert score == 330
    assert badge == "*[PRS: 330 (80/75/85/90)]*"

    # 2. Operator override takes precedence
    item_ovr = {
        "rating_pri": 80,
        "rating_sev": 75,
        "rating_appeal": 85,
        "rating_effort": 90,
        "rating_ovr": 360,
    }
    score, badge = planner_core.compute_prs_score(item_ovr)
    assert score == 360
    assert badge == "*[PRS: 360 (ovr)]*"

    # 3. Unrated item returns None and empty string
    item_unrated = {}
    score, badge = planner_core.compute_prs_score(item_unrated)
    assert score is None
    assert badge == ""


def test_format_weekly_markdown_with_prs_and_builds():
    plan_data = {
        "timestamp": "2026-10-13T06:00:00Z",
        "intake_mode": "native_prs",
        "decisions_issue": 202,
        "release_milestones": {
            "next_release": "0.6.0 Front-Door (draft) target=2026-09-26",
            "overdue_note": " (17 days overdue)",
            "target_release": {
                "version": "0.6.0",
                "codename": "Front-Door",
                "status": "draft",
                "exit_criterion": "bash test/meter-release.sh --release-gate exits 0. Half A AUDITS launch artifact, Half B EXECUTES stranger's path.",
            },
            "manifest_summary": {
                "total_items": 19,
                "shipped_count": 11,
                "dialed_in_count": 8,
                "burndown_pct": 57.9,
                "dialed_in_numbers": [255, 256, 275, 342, 345, 416, 418, 419],
            },
            "active_marathons": [
                {"id": 1, "status": "planned", "url": "https://github.com/HiQS-Labs/XYZ-forge/issues/13"}
            ],
            "active_jog_queue": [
                {"gh_number": 904, "position": 1, "status": "pending"},
                {"gh_number": 907, "position": 2, "status": "pending"},
            ],
            "upcoming_releases": ["0.8.0 Sundown (draft) target=2026-10-17"],
        },
        "merge_sequence": {"status_phases": {}},
        "teammate_assignments": {
            "Noel": {
                "domain": "Orchestration/Gate",
                "tasks": [
                    {
                        "gh_number": 255,
                        "title": "meter launch gate: clean clone, secret scan",
                        "is_release_build": True,
                        "release_build_version": "0.6.0",
                        "prs_score": 310,
                        "prs_badge": "*[PRS: 310 (80/75/75/80)]*",
                        "risk": 4,
                        "is_high_risk_gate": True,
                        "risk_gate_badge": "*[GATE: risk 4]*",
                        "assignment_source": "GitHub assignee (@noelsaw1)",
                    }
                ],
            }
        },
        "unassigned_items": [
            {
                "gh_number": 418,
                "title": "sanitize telemetry: remove absolute workstation paths",
                "is_release_build": True,
                "release_build_version": "0.6.0",
                "prs_score": 320,
                "prs_badge": "*[PRS: 320 (85/80/75/80)]*",
            }
        ],
        "deferred_items": [],
        "adversarial_audit": {"findings": []},
    }

    md = planner_core.format_weekly_markdown("2026-10-13", plan_data)

    assert "**Release Exit Criterion:** bash test/meter-release.sh" in md
    assert "**Release Build Burndown:** 11 shipped, 8 dialed-in (57.9% complete)" in md
    assert "**Dialed-in Build Tasks:** #255, #256, #275, #342, #345, #416, #418, #419" in md
    assert "**Active Marathons:**" in md
    assert "**Active Jog Build Queue:**" in md
    assert "Pos 1: GH-904" in md
    assert "*[Release Build: 0.6.0]*" in md
    assert "*[PRS: 310 (80/75/75/80)]*" in md
    assert "*[GATE: risk 4]*" in md


if __name__ == "__main__":
    test_detect_merge_sequence_phases()
    test_adversarial_audit_ignores_evidence_carriers()
    test_format_weekly_markdown()
    test_compute_prs_score()
    test_format_weekly_markdown_with_prs_and_builds()
    print("PASS: all test_planner_core checks passed successfully.")


