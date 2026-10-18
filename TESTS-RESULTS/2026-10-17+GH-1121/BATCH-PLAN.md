# Non-CI integration batch — GH-1121

Author: Codex (OpenAI GPT family). Independent reviewer must be actual Gemini via agy, not merely another CLI. Operator cap: two cumulative QA rounds, including resumes. No new CI tests/cases; defer non-Critical/non-High findings to a follow-up GH issue. Reviewer gives severity explicitly.

## Frozen input and path

Base development a984865eab17456dc8240f68b3206e414e255179. Member heads in heads.json. Order 1062 -> 1089 -> 1097 -> 1120. No hard member dependencies found. Shared releases/CHANGELOG/index are soft collision sites. Semantic surfaces are largely separate: local/PR review workflow split, start-task smoke instructions, Skills Army read-only Pulse diagnostics, and independent worth-it skill bundle. 1120 last minimizes index and ledger churn because it starts from current base. Source upstream PR15 remains open/pinned and excluded.

Operator explicitly authorized an isolated integration branch and batch PR with at most one development merge at end; no individual PR merge, retarget or auto-merge. Policy GH1066 permits separately authorized aggregate path; user instruction supplies the branch/batch authorization, without waiving gates. Use merge commit per .merge-cleanup.json; original member heads remain ancestors. No settings/workflow/CI/runtime experiment changes, main promotion, deployment, skill installation or schedule activation.

## Resolutions and preservation

1062: current close-the-loop, daily-planner, express index rows retained; review-code rename and review-pr addition included; daily count derived from actual disk. Ledger current generation retained and GH1060 replayed via canonical writer. Historical source assertions were operator-trimmed; changed existing suites remain tier3.
1089: replay only GH1088 via writer. Preserve current changelog history exactly and prepend only each source-added block; B1 strict additive resolver refused the second source after earlier union ordering, so the caller extracted and asserted each exact source delta instead. Three minor CodeRabbit findings remain (Step6 vs Step8 reference, stale PR placeholder, ledger position tie): defer under operator severity rule, no extra QA round for nits.
1097: current development has completed GH942 and newer GH1075 docs and newer Jog transitions. Keep all current Jog rows and current GH942/GH1075 state; reject stale promotion/queue rollback from source. Integrate sync.py/recovery.md and reviewed GH960 working doc, remove its duplicate inbox and repoint only GH960 through canonical CLI. Existing merger rebuilds/releases check passed. No live Jog mutation or attempt reset. Original source gate was killed at1800s; historical focused6/6 and independent Codex approval are limited evidence, not full qualification.
1120: retain exact source skill/LICENSE/NOTICE; replay only GH1119 via writer; metadata minor fixed at pinned8c010b3. Source planQA approved round2, finalQA round1; hosted smoke success, Ubuntu/macOS skipped.
Routine views restored to base bytes for hosted ownership. Trim only trailing whitespace in two inherited1097 relay logs. Resolution receipts retained; no other source fixes.

## Review requested

Review this grouping/strategy AND the full combined production changes, preserving required source QA: skills/2-daily/review-code-xyz/SKILL.md and install.sh; review-pr-xyz equivalents; review-xyz SKILL; skills/1-hourly/start-task/SKILL.md; skills/3-weekly/skills-army-hq/scripts/sync.py and references/recovery.md; skills/3-weekly/worth-it/{SKILL.md,LICENSE,NOTICE}; utils/py/xyz_mini_sync.py; changed tests gh589/gh778/gh798; index, README, mini README, linked plan docs and retained source QA. Read whole changed production files; avoid expanding to CI optimization or source PR15. Challenge hidden dependencies, semantic interactions, stale ledger resolution, gate deferral, new-test authorization, attribution/license/source bytes, rollback and reconciliation under aggregate merge. Do not run tests in worktree or modify production files. Reviewer only appends relay. State actual model identity, swept file yes/no, graded findings with observed input/scope/falsifier for behavior claims and VERDICT PASS/FAIL/PARKED. Approve only if no Critical/High blockers; explicitly separate review approval from pending full gate/hosted qualification.

## Checkpoints and rollback

One full normal pre-push publication gate in separate disposable full clone at final reviewed production content (not a linked worktree). Full selected due test edits; no bypass. Additional meaningful existing focused checks only when they resolve a concrete claim; no new tests. Hosted batch PR smoke must run on its exact final head; skipped macOS/Ubuntu are not qualification. Recheck development and all member heads, no draft/hold/auto-merge, final diff and gate/review evidence immediately before final pinned merge. Any base/source/production change reopens affected evidence within cap, else hold. Combined publication gate is self-reported full suite, not ci-local sequential promotion evidence. Actual development landing requires hosted wave-reconcile full tier3 qualification at covered commit; reuse it for batch sweep without duplicate broad run. AGENTS permits automatic hosted reconciliation; inspect PRS check and issue-doc-sync afterwards. No main promotion.

Before landing: nothing on development to roll back; keep source refs and integration branch. After single merge: revert batch merge first-parent diff in reviewed PR; no force rewrite. Preserve all original heads and task receipts. This action is Easy to reverse by revert, no schema/access/workflow change; shared remote write still requires exact-head conditional guard and fresh base.

## Traceability and closure

Batch PR body should close only issues1060,1088,960,1119 with actual delivered changes. Source originals stay open until final development landing proves ancestry. Their commits may cause GitHub to mark originals merged when batch lands; observe and verify. Hosted reconcile catch-up may rediscover these originals; inspect receipts and do not race active hosted writer. Source1097 reported a failed Jog run in its verify clone, but read-only SQL now confirms neither the current base nor pinned primary has a GH960 Jog row. Keep that absence; do not recreate stale verify-clone execution state. Current hook leaves unbundled mapped rows unchanged with a warning. Standard roadmap and issue-doc-sync reconciliation remain required. Batch issue records outcome and sweep; no-op reconciliation is reported as no-op.

## Carry-overs (not authorized deployment)

1062: Refresh deployed copies through Skills Army HQ (`intake.py --apply update` for both, then `sync.py`). /push-downstream --target XYZ-mini.
1089: Refresh the deployed /start-task copy (Skills Army HQ) from the repo. That copy is also behind on GH-1059.
1097: Jog row for GH-960 stays failed until this lands and jog land GH-960 --pr <n> reconciles it.
1120: Skill installation/deployment not requested; source upstream stays open at pinned revision.

## Review round1 failure and bounded continuation

Round1 Gemini4 Argon High completed a report but driver exit6 rejected attestation: caller created manual-preservation.txt in the source while review ran; guard preserved it then reverted that untracked caller file. Source production bytes unchanged. Report also contains unsupported citations (e.g. claiming .merge-cleanup.json has batch keys; actual file only preserve_commit_history:true; fabricated full merge SHA suffixes and incorrect worth-it behavior/hash claims). No round1 approval accepted. Evidence and caller file restored from orphan-backup. Second/final round stays under the same batch record cap2, not a reset. No source writes during reviewer lifetime. No harness changes. Review actual current production files and only cite observed output; do not parse Git packs. Source ancestry/preservation is author-measured in manual-preservation.txt; distinguish it from independently verified source content.

Verified Low findings for GH1121 follow-up: mini/README.md still says eleven while mapping has twelve; architecture1-hourly/3-weekly headings stale; source1089 three Minor findings already retained. GH960 Jog absence is now corrected factual closeout metadata rather than an unresolved execution transition. No Low finding is fixed in production in this batch.

## Current terminal QA state

Cumulative QA2/2 exhausted. Round2 Gemini3.8 Flash High returned PASS but driver exit4 refused attestation because one prior blank line above its review block was removed (`review-body-rewritten`). No attestation accepted, and reviewer terminal Approved is not merge readiness. Do not rewrite the receipt, manually attest, reset caps, or dispatch another reviewer without operator extension. No supported Critical/High source finding; lack of valid required review remains a procedural landing blocker. Complete normal full publication gate and expose an explicitly unapproved DRAFT batch PR for operator review, then stop before any development merge. No further review or development write authorized by this record.

## Qualified publication checkpoint and refreshed base

Normal installed full pre-push gate passed409/409 in1024s on a2a1389094c96a8ef249e3286973540098bac5b2, 4-wide macOS15.6.1; clone identity unchanged; remote branch exact SHA verified. This is full publication self-check, NOT ci-local sequential promotion evidence. Source gate log and telemetry retained. Pre-existing hosted reconciliation39077671933 completed successfully and advanced development to7f19d57db884588bc7f59dac0e2f24659f5a5ea6. Its five changed paths are governance/docs/qualification evidence only, no ledger changes. Clean merge incorporates that base; production/runtime/test bytes remain identical to tested a2a13890. Receipt/header metadata and inherited base receive normal documentation push gate. Review remains unaccepted at cap2/2; final candidate/base must be re-reviewed only after explicit operator extension.
