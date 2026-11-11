---
title: GH1399 qualification and attempt accounting recon
status: Recon
created: 2026-11-10
updated: 2026-11-10
owner: Codex
goal: Trace qualification entry and canonical attempt history before implementation
roadmap_exempt: true
---

# Recon Map

## Status

| What was just completed | What's next |
|---|---|
| Entry and state traces completed before implementation | Runtime proof and final QA are tracked in the GH-1399 task doc |

Base68367d6682737b5bcdb324c1bede6def53c197a2. Read-only source trace, two lanes (entry/consumers and state/writers). No graph service available; rg and source reads used. No runtime reproduction or implementation yet.

## Entry and qualification contracts

- githooks/install.sh153-190 delegates to the in-tree hook, or directly to validate.sh for old branches. Hook66-74 discards ref names and retains SHA pairs.
- githooks/pre-push258-263 exits after docs PDDA;289-308 reuses exact-SHA full receipts;267-281 and311-323 invoke runtime validation. Accounting must precede successful shortcuts. Existing delete-only/explicit bypass77-85 are separate contracts.
- utils/ci-route.sh63-69 classifies changed paths, not task identity. Task skill documentation can route docs, so docs cannot itself mean administrative exemption.
- validate.sh48 and ci-local.sh72 scrub gate environment; gate_env.py68-95 removes run/lane identifiers while134-139 retains TICK_REPO_ROOT. validate.sh52-75 independently forbids linked worktrees.
- validate.sh1591-1597 writes successful full receipts, swallowing writer failure. gate_receipt.py28-116 atomically writes and reads SHA/result metadata, with no attempt attribution and a legacy fallback.
- ci-local.sh431-440 -> utils/gate-record.sh80-106 writes legacy green evidence BEFORE JSON writing with ignored failure. Guarding the JSON writer alone leaves this qualification path open.
- marathon-closeout.sh149-175 reads passing receipts before publication; marathon_drive.py159-200/2887-2890 writes completion receipts without downgrading stronger full gates.

## State and writers

- relay_drive.py245-284 counts timestamp+fire lines in .tick/attempts/<sanitized lane>. LANE_ATTEMPT_COUNTED249 suppresses nested counting, not proof.297-317 resolves coordinator root and excludes dry-run/review-only turns.
- marathon_drive.py1513-1516 names the lane;3222-3223 and3472-3473 clear inherited counted state for outer precheck/fire;3520-3525 passes nested counted ownership to relay.
- jog_run.py485-507,1003-1008 preserves issue phase identity; new execution IDs do not reset build caps.
- merge-cleanup/scripts/attempt_record.py49-51 selects explicit primary/origin/PR JSON;61-89/117-143 lock and atomically reserve;146-159 finish/annotate. CLI170-214 requires absolute MERGE_CLEANUP_RECORD. No utils/py/attempt_record.py exists.
- merge_cleanup.py1581-1583 finishes B1 as resolved BEFORE qualification in a second full clone. Active-only admission would break this existing supported path.
- rtl.py11-25 archives exact successful lane bytes atomically under attempt-history; failures leave source bytes. relay_drive.py286-295 and marathon_drive.py1286-1299 propagate archive errors. Archives are passive evidence, not live budget input.
- marathon_drive.py2857-2861 resets/archives BEFORE post-approve commands; later publication may have historical accounting only.

## Authority and failure paths

Existing separate lane/repair writers remain authoritative; qualification context must be a reference/projection, not another budget ledger. No existing shared active lease, branch/SHA binding or automatic ignored-state transfer exists. Missing, malformed, stale or mismatched context must not become zero attempts or success. Do not interpret a nonempty timestamp file or environment flag as proof. Completed repair commit and archived lane evidence require explicit semantics. Current documented git bypasses mean this is accidental-omission prevention, not tamper-proof security.

## Existing verification surfaces

Existing gh544-pre-push-gate.sh, gh35-test-tiers.sh, gh509-gate-evidence.sh, gh441-gate-env-contract.sh, gh307-gate-env-scrub.sh, gh534_phase_c_tests.py through gh436-merge-cleanup.py, lane-attempt-cap.sh, gh124-closeout.sh. The lane cap shell suite extracts frozen Bash logic and cannot alone establish new Python behavior. Use retained manual red/green controls for new predicates; no new suites/gates/runners.

## Unknowns to settle before plan QA

Task identity versus integration/admin updates; active/completed candidate binding; candidate evolution within one logical repair; explicit proof transfer to a disposable full clone; preserving producer lifecycle and history without false qualification. Broader hostile-agent enforcement is not claimed.
