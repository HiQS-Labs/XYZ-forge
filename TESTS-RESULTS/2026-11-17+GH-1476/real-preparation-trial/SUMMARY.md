# GH-1476 real preparation trial — summary (branch-only, PR #1514 unmerged)

Start 2026-11-17T19:05:24Z; deadline 19:50:24Z (45 min); core preparation finished ~19:12Z, within budget. Policy under test: Conveyor at `2e22cce06edaa1a4f0a58b85cff9e23ab62a18af`. Live `development` `6000f3de1e24995806eb151bc1720b7cff77350a`. Subscription-only (native Claude child). Budgets: research 1/1 used (#1517), routine repairs 1/3 (isolated `git init`), PR #1514 review budgets untouched.

| Case | Issue | Expected (frozen) | Actual | Local prep state | Integration readiness |
| --- | --- | --- | --- | --- | --- |
| RAW | #1517 | Medium research child, capture, contract, isolated pickup | As expected; research found issue's rewording incomplete and the file is a full-gate route | Capture + contract + isolated row `rmi-01M7NERCQV784J7A707AZP7ZGZ` 30/30/50/90 | None: no PR, no preflight, no review, no canonical row |
| Prepared | #1171 | Reuse by freshness, no research child | Reused: capture identical at branch and live; probe still discriminates (rc1 unfixed at both); parser/linter OK; no overlapping functions in #1467/#1505. Held for execution owner: live `jog_queue` failed, `attempt_count 2`, unreviewed candidate `ae942d0f` preserved | Fresh preparation evidence; medium-checklist gaps listed | None: Step 5 preflight needs a disposable clone; re-admission is an operator/Jog decision |
| Held | #1518 | Visible operator-decision hold, no research | As expected: 0 comments, live `is_full_gate_receipt` unchanged, no PR, no row | Held | None |

## Acceptance outcomes witnessed (OL-09) — do not tick automatically

Witnessed in a real bounded run: RAW no-row/no-contract issue accepted and given one medium research child under a pre-recorded deadline and budget; prepared item reused by freshness without a child; genuine human hold kept visible while other items continued; research child stayed read-only; capture before pickup with a real doc path; operator/neutral ratings (appeal 50, ovr null) via the canonical writer (isolated); no dangling rows; held/reused items got no new writes.

Not witnessed: deeper-research trigger; explicit risk-deferral; daily-goals issue intake; 10days batch path (Conveyor path only); Step 5 preflight at the integration ref; Step 6 independent preparation QA and publication; readiness label; canonical-ledger pickup; behavior after PR #1514 merges.

## Limitations

- Isolated ledger is a copy of the branch `releases.db` in a scratch git repo; the writer's repo-identity behavior there may differ from a real clone.
- The #1517 "fixed" polarity witness is a simulated in-memory rewording, not a builder change.
- Graph (codebase-memory) not used for source claims; all line claims are from exact pinned source reads (branch clone and `gh api …?ref=6000f3de`).
- The test sub-agent wrote the #1517 capture itself (parent role) and the selection; there was no independent reviewer of this trial.
- Sandbox blocked `gh` TLS and writes to `/private/tmp/gh1476-real-preparation-trial`; commands ran with the sandbox disabled, read-only except trial-dir writes.

## No-mutation confirmation (end)

Evidence clone HEAD `2e22cce0`, porcelain 0 before durable copy; `releases.db` hash `b0a4f7b4…` unchanged. Primary HEAD `e389786d043995e3894969cfc9caad31b3e84f9d`, porcelain 0. No label, Jog admission, merge, push or primary write.

## Parent completion of Step 5

Preflight ran using the unmerged PR runtime in a separate disposable full clone at development `6000f3de1e24995806eb151bc1720b7cff77350a`. Original #1517 capture returned exit 5: acceptance criteria differed from the issue without declared deviations. Original failure retained. Parent restored the issue acceptance block verbatim (repair 2/3 total); rerun returned exit 0, READY. #1171 returned exit 0, READY, but remains HELD for its exhausted historical execution budget; this run grants no new attempt. Clone HEAD/origin and clean working tree unchanged. No implementation, admission, readiness label or merge.

These supersede the earlier missing-Step-5 statements above. Independent preparation QA/publication and daily-goal/10days paths remain untested; OL09 remains unchecked. This is agent-assisted preparation evidence, not unattended execution. Hosted checks: one SUCCESS, two SKIPPED, CodeRabbit NEUTRAL; earlier all-four-passed wording was inaccurate.
