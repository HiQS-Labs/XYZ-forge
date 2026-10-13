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
