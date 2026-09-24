---
title: "GH-749 relay exit-code truth + measured gate cost — marathon capture (one chain, four lanes)"
status: "Delivered — four lanes Approved and gated; PR #750 open against development (head 3810a621, 411/411)"
created: 2026-09-22
updated: 2026-09-22
owner: Noel Saw
goal: >
  Land the two members of the GH-749 arc through one marathon chain: #720 (a real reviewer block must
  never read as a zero-output stall) and #732's small, independently landable CI/CD items (measure
  C.1/D.2, refresh the timing claims and render the timings the gate already records, name
  environment faults). Tracking lives in GitHub issue 749.
doc_type: project
gh_issue: 749
roadmap_exempt: true
source: https://github.com/HiQS-Labs/XYZ-forge/issues/749
reversibility: "Easy — one delivery PR into development from the marathon branch; the chain halts on a failed phase and nothing is merged by the marathon itself"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/720
  - https://github.com/HiQS-Labs/XYZ-forge/issues/732
  - https://github.com/HiQS-Labs/XYZ-forge/issues/496
  - https://github.com/HiQS-Labs/XYZ-forge/issues/673
---

# GH-749 — relay exit-code truth + measured gate cost (marathon capture)

## Status

| What was just completed | What's next |
|---|---|
| 2026-09-22: chain ran to completion — p1 #720 (`45b7d2cd`, attest `a58338fe`, 408/408) · p2 #732 C.1/D.2 (`5e9e0d5e`, `d3c5a21e`, 408/408) · p3 #732 A.1–A.5 (`a6b4a50c`, `4ef3ff58`, 409/409) · p4 #732 B.1/B.2 (`10836fc9`, `4c8717e9`, re-gated after the eval fix `4b15834e`). Bridges recorded: #507 (skip under the driver, standalone 410/410 in `TESTS-RESULTS/2026-09-22+GH-720/l1/`), #745 (tick events split), #752 filed (multi-phase re-fire), `MARATHON-p4-retry.yaml`. Final un-nested push gate 411/411 GREEN in 1068 s. PR #750 updated. | Merge lane: land #750 one-at-a-time (never alongside #751); hosted reconcile closes #720 or close it by hand; #732 stays open (D.2 exit condition, A.6/A.7, #496 P3–5). Follow-up surfaced by L3's block: `gh251-validate-pytest-skip.sh` is the slowest suite at 710 s. |

Tracking issue: https://github.com/HiQS-Labs/XYZ-forge/issues/749 (members, write-sets, tiers, what is held, acceptance).
Ledger: `marathons` row `mar-01M33PJX8HPKMJHPQFH1S0WG6B` → #749; member rows GH-720 (`rmi-01M32MGB…`, rated 60/55/50/85) and GH-732 (`rmi-01M32XWJ…`, rated 55/40/50/70), both 🚧.

One chain, four sequential lanes (`MARATHON.yaml`, phases p1..p4, strict `depends_on`):

| Phase | Lane | Issue | Write-set | Tier (`ci-route`) |
|---|---|---|---|---|
| p1 | L1 review-once block regex | #720 | `utils/py/relay_drive.py`, `test/gh648-l8-zero-output-handback.sh`, `relay-automation/new-relay.sh` | 3 |
| p2 | L2 measure C.1 + D.2 | #732 | `TESTS-RESULTS/2026-09-22+GH-732/{c1,d2}/` | 1 |
| p3 | L3 timing claims + render gate timings | #732 A.1–A.5 | `AGENTS.md`, `ROUTER.md`, `githooks/pre-push`, `validate.sh`, `test/gh732-l3-gate-summary.sh` | 3 |
| p4 | L4 named environment faults | #732 B.1 / B.2 | `validate.sh`, `test/gh251-validate-pytest-skip.sh`, `test/gh268-relay-cue-and-target-checks.sh` | 3 |

p3 and p4 both edit `validate.sh` — ordered by `depends_on`, never parallel. `CHANGELOG.md` and the ledger collide on every lane and are reconciled at landing, not by wave placement.

## Held (decided at triage, not in this chain)

- **#673** — implementation merged (#719); remainder gated on #646 (PR #723 draft, CONFLICTING). Verify-and-close after #646.
- **#496 Phases 3–5** — Phase 3 is a Costly, spike-gated `releases.db` transport change; follow-on arc.
- **#732 A.6 / A.7** — recommendations only.

## Firing recipe (existing path, GH-648 precedent #650 → #687)

```bash
CLONE="$HOME/marathon-clones/marathon-gh-749-relay-gate-cost"      # full clone, branch feat/gh749-relay-gate-cost
cd "$CLONE"
export PATH="$HOME/.cache/xyz-forge-test-venv/bin:/opt/homebrew/bin:$PATH"
relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-749-RELAY-GATE-COST/MARATHON.yaml --dry-run
relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-749-RELAY-GATE-COST/MARATHON.yaml --closeout-pr
```

The GH-561 branch guard leaves lane commits on the current non-protected branch, so all four phases land on `feat/gh749-relay-gate-cost` and `--closeout-pr` opens (never merges) the delivery PR. Never fire from the primary checkout; never from `development`.

## Acceptance for the marathon as a whole

- [ ] Every phase approved by its reviewer and its `bash validate.sh` gate green in the clone; per-lane red/green controls with `provenance.jsonl` under `TESTS-RESULTS/<UTC-date>+GH-<issue>/<lane>/`.
- [ ] #720 closes when L1 lands (exit 5 on a `### Reviewer (agy)` handback; exit 3 still on a genuinely empty turn).
- [ ] #732 items A.1–A.5, B.1, C.1, D.2 ticked in its canonical body with the landing commit; B.2 fresh-clone `GREEN in Ns` line recorded; #732 stays open until its D.2 exit condition or its owner re-scopes it.
- [ ] One delivery PR from the marathon branch, landed through the merge lane one PR at a time.

## Lessons Learned (For Future Agents)

- The planner reads a ledger row's `raw_text` for the `[plan](…)` link, not `doc_path` — a row with `doc_path` set but no link in `raw_text` reports `needs-doc` + `drift` (GH-673 was the case here); fix it with `roadmap update --raw-text` through the writer.
- `artifacts_new` entries need a `path_absent` fix probe on the same path or preflight refuses the contract (exit 3).
- `swarm-preflight` appends inferred covering tests to `--artifact`; the contract's declared list is the audited write-set, the suggestion is wider by design.
