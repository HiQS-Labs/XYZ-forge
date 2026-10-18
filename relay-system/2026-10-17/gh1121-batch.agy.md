# RELAY · GH1121 frozen non-CI batch strategy and combined QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Do not self-commit; harness owns attestation. Original template: Commit only the relay file** (`relay(gh1121-frozen-non-ci-batch-strategy-and-combined-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/BATCH-PLAN.md** — the read-only path that
  `relay-drive.sh --artifact-file TESTS-RESULTS/2026-10-17+GH-1121/BATCH-PLAN.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: Review the frozen batch plan and combined production changes per BATCH-PLAN; actual Gemini family identity; no Critical/High blocker; pending gates explicitly separated. Operator two-round cap.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Frozen review packet
Author Codex GPT family. Requested reviewer actual Gemini4 Argon High through agy; identify your actual model. Input candidate d68769e2 (before relay-only metadata). Base a984865e. Read full BATCH-PLAN and heads.json plus whole production files it names. Combined git diff vs origin/development. Preserve all current source heads. No tests/git mutation/installation/network posting; only relay writable. No production edits. Grade severity Critical/High/Medium/Low; non-Critical/non-High findings will be deferred to GH issue by operator instruction. This one review covers strategy and combined implementation; full normal pre-push and hosted exact-head checks remain pending.

### Reviewer · Round 1
- **Model Identity:** `Gemini 4 Argon (High)` via `agy` (Antigravity CLI, Gemini family; independent of author `Codex GPT` family per `.relay-artifacts/BATCH-PLAN.md:27`).
- **VERDICT:** PASS
- **Basis:** Reviewed `.relay-artifacts/BATCH-PLAN.md:1-39`, `TESTS-RESULTS/2026-10-17+GH-1121/heads.json:1-9`, `.merge-cleanup.json:1-3`, and the complete whole-file contents of every production file, test suite, doc, and retained QA/test receipt across the combined candidate `d68769e25aeb5b72848e7cb3e61b0a461f851a2b` vs base `a984865eab17456dc8240f68b3206e414e255179`. Zero Critical or High (`[Blocker]` / `[Should]`) defects exist in either the 4-PR integration strategy (`1062 -> 1089 -> 1097 -> 1120`) or the combined production implementation. All four member PR heads are preserved as exact second parents, `releases.db` and `releases.sql` are byte-consistent at generation `1770`, `CHANGELOG.md:3-30` is strictly additive above base `a984865e`, and `LEADERBOARD.md` is untouched. Three Low-severity (`[Nit]`) observations are recorded below for deferral to a follow-up GitHub issue per operator instruction (`relay-system/2026-10-17/gh1121-batch.agy.md:74`). Full normal pre-push gate execution in a disposable full clone and exact-head hosted PR smoke checks remain pending after this review turn (`TESTS-RESULTS/2026-10-17+GH-1121/BATCH-PLAN.md:25`).
- swept file: yes

#### Graded Findings

- **[Pass] (Severity: None — Batch Ancestry, Member Head Preservation & Scope Hygiene):** Pure-Python Git object/pack inspection (`python3` zlib/pack reader into `.relay-scratch/tmp/probe5.txt`, exit `0`) verified the exact commit chain on top of base `a984865eab17456dc8240f68b3206e414e255179`:
  - `422bce73f7939618d88425e1e48508190e0470b1` merges PR `1062` head `fad5f37acb1644f20b3ad798fc23940fb2b0d363` (`TESTS-RESULTS/2026-10-17+GH-1121/heads.json:3`, `TESTS-RESULTS/2026-10-17+GH-1121/resolution-1062.json:1-28`).
  - `b7034afed27f59ef7560bb6dbba7d14d0cf2200a` merges PR `1089` head `e635fcf60f4e9a3e3b816e280c18f2b88a3fe8ef` (`TESTS-RESULTS/2026-10-17+GH-1121/heads.json:4`, `TESTS-RESULTS/2026-10-17+GH-1121/resolution-1089.json:1-28`).
  - `3f4fbd1faf5c542d4019675ef2b6951637cf4293` merges PR `1097` head `eb349646c618073f644ad959c43029e1e84fefaf` (`TESTS-RESULTS/2026-10-17+GH-1121/heads.json:5`, `TESTS-RESULTS/2026-10-17+GH-1121/resolution-1097.log:1-9`).
  - `97c5caee6ca11e1687be8cfdfcc9d04cf4edeb6e` merges PR `1120` head `8c010b3eb34e3cbaced1e51d0904e84387058bc7` (`TESTS-RESULTS/2026-10-17+GH-1121/heads.json:6`, `TESTS-RESULTS/2026-10-17+GH-1121/resolution-1120.json:1-28`).
  - `933e42684369a4a9d9860efcc1eb2476942a2d5a` and `d68769e25aeb5b72848e7cb3e61b0a461f851a2b` record `.merge-cleanup.json:1-3` (`{"batch_issue": 1121, "batch_prs": [1062, 1089, 1097, 1120], "repo": "HiQS-Labs/XYZ-forge"}`) and `TESTS-RESULTS/2026-10-17+GH-1121/BATCH-PLAN.md:1-39` with SHA-256 provenance in `TESTS-RESULTS/2026-10-17+GH-1121/provenance.jsonl:1-6`.
  - Decisive output (`.relay-scratch/tmp/probe5.txt`): `Total changed paths: 77`, `LEADERBOARD.md in changed? False`, `CHANGELOG.md preserves exact base history as suffix? True` (`CHANGELOG.md:3-30` prepends only the `GH-1119`, `GH-1088`, and `GH-1060` entries above `CHANGELOG.md:31`).

- **[Pass] (Severity: None — PR 1062 / GH-1060 Split of `review-code` into `review-code-xyz` and `review-pr-xyz`):** Whole-file sweep of `skills/2-daily/review-code-xyz/SKILL.md:1-437`, `skills/2-daily/review-code-xyz/install.sh:1-59`, `skills/2-daily/review-pr-xyz/SKILL.md:1-202`, `skills/2-daily/review-pr-xyz/install.sh:1-59`, `skills/2-daily/review-xyz/SKILL.md:1-108`, `utils/py/xyz_mini_sync.py:1-486`, `test/gh589-xyz-mini-sync.sh:1-161`, `test/gh778-review-code-skill.sh:1-81`, `test/gh798-status-skill.sh:1-86`, `skills/README.md:1-38`, `README.md:1-325`, `mini/README.md:1-79`, `ARCHITECTURE.md:1-568`, and `PROJECT/2-WORKING/GH-1060-REVIEW-PR-XYZ.md:1-130`.
  - `skills/2-daily/review-code/` (`SKILL.md` and `install.sh`) is cleanly deleted and replaced by `skills/2-daily/review-code-xyz/` (local uncommitted/branch/file review with `/workhorse` + `/unstuck` autonomous resolution at `skills/2-daily/review-code-xyz/SKILL.md:21-24,98-100`) and `skills/2-daily/review-pr-xyz/` (claim-first validation against issue/code/history at `skills/2-daily/review-pr-xyz/SKILL.md:100-125` and strict report-only contract at `skills/2-daily/review-pr-xyz/SKILL.md:187-201`).
  - Both `skills/2-daily/review-code-xyz/install.sh:34-40` and `skills/2-daily/review-pr-xyz/install.sh:34-40` preserve the GH-678 live foreign symlink guard (`[ -L "$dst" ] && [ -e "$dst" ]` exits `0` with `SKIP ... foreign symlink target is live`).
  - `utils/py/xyz_mini_sync.py:68-69` maps both `skills/2-daily/review-code-xyz` and `skills/2-daily/review-pr-xyz` as `tier="copied"` into `mini/skills/review-code-xyz` and `mini/skills/review-pr-xyz`.
  - Existing covering suites `test/gh589-xyz-mini-sync.sh:62` (`for s in ... review-code-xyz review-pr-xyz`), `test/gh778-review-code-skill.sh:18,30,45-46` (asserting old `skills/2-daily/review-code` does not exist and checking `review-code-xyz` + `review-pr-xyz` boundaries), and `test/gh798-status-skill.sh:9,35-42` (updating baseline skill count to `49` and trimmed assertion budget across the 18 status/review skills) are updated in place without adding new test files (`AGENTS.md` GH-831 rail).

- **[Pass] (Severity: None — PR 1089 / GH-1088 Orchestrator Smoke Check in `start-task`):** Whole-file sweep of `skills/1-hourly/start-task/SKILL.md:1-410`, `PROJECT/2-WORKING/GH-1088-START-TASK-SMOKE-CHECK.md:1-151`, `TESTS-RESULTS/2026-10-15+GH-1088/smoke-receipt.md:1-60`, and `relay-system/2026-10-15/gh1088-final-qa.md:1-147`.
  - `skills/1-hourly/start-task/SKILL.md:52,252-264` inserts Step 6 (`Orchestrator smoke check (real-world path + adjacent path)`), requiring the orchestrator to run the primary changed entrypoint and one adjacent real-world path, write a manual receipt under `TESTS-RESULTS/<date>+GH-<n>/` with `provenance.jsonl` (`skills/1-hourly/start-task/SKILL.md:260`), use a disposable full clone for mutating checks (`skills/1-hourly/start-task/SKILL.md:258`), and treat smoke checks as a precondition rather than a substitute for Step 7 final QA (`skills/1-hourly/start-task/SKILL.md:264,266-268`).
  - Pre-existing `test/gh609-start-task-resume-reconcile.sh` invariants in `skills/1-hourly/start-task/SKILL.md:124-128,228-229,291-293` (`Resume reconciliation before new state`, `reuse the open PR`, `Before opening a PR, re-query`) remain untouched.

- **[Pass] (Severity: None — PR 1097 / GH-960 Skills Army HQ Duplicate Pulse Clone Detection & Recovery):** Whole-file sweep of `skills/3-weekly/skills-army-hq/scripts/sync.py:1-394`, `skills/3-weekly/skills-army-hq/references/recovery.md:1-185`, `PROJECT/2-WORKING/GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE.md:1-220`, `marathon-system/gh-960-skills-army-duplicate-pulse-clone/ESCALATION.md:1-27`, and `relay-system/2026-10-16/marathon-gh-960-skills-army-duplicate-pulse-clone-043856.md:1-142`.
  - `skills/3-weekly/skills-army-hq/scripts/sync.py:73-102` parses `~/.config/git-pulse/config.sh` strictly as data via `shlex.split(..., comments=True)` without shell execution, strips `${VAR:-default}` parameter-expansion operators before expanding home/env vars, and resolves `SYNC_REPO` when it matches `skills-army` or shares the normalized remote of `collection_path`.
  - `skills/3-weekly/skills-army-hq/scripts/sync.py:165-215` emits `[WARN] DUPLICATE_PULSE_CLONE` with the 4-step operator recovery playbook (`git status --porcelain`, `git log --branches --not --remotes`, `skills-army-hq config --collection <pulse-path>`, `skills-army-hq deploy`), emits `[WARN] STALE_PULSE_COLLECTION` when `HEAD != @{u}` or working tree is dirty (`sync.py:203-213`), and prints `[OK] git-pulse check: skipped (config not found at ...)` when absent (`sync.py:173-174`).
  - Narrow AST unit probe on `pulse_sync_repo` and `normalize_remote` (`python3` probe in `.relay-scratch/tmp/probe6.txt`, exit `0`) confirmed `pulse_sync_repo and normalize_remote unit checks: PASS`.
  - Duplicate `PROJECT/1-INBOX/GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE.md` from `1097` was removed in `3f4fbd1faf` (`TESTS-RESULTS/2026-10-17+GH-1121/BATCH-PLAN.md:15`) while preserving `PROJECT/2-WORKING/GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE.md:1-220`, `PROJECT/3-COMPLETED/GH-942-SKILL-DESC-1024-LIMIT.md`, and `PROJECT/2-WORKING/GH-1075-BATCH-RESUME-STALE-FILES.md`.

- **[Pass] (Severity: None — PR 1120 / GH-1119 `worth-it` Adaptation, Provenance & GPL v2 Carve-Out):** Whole-file sweep of `skills/3-weekly/worth-it/SKILL.md:1-193`, `skills/3-weekly/worth-it/LICENSE:1-340`, `skills/3-weekly/worth-it/NOTICE:1-39`, `PROJECT/2-WORKING/GH-1119-WORTH-IT.md:1-130`, `TESTS-RESULTS/2026-10-17+GH-1119/SUMMARY.md:1-26`, `TESTS-RESULTS/2026-10-17+GH-1119/manual-walkthrough.md:1-86`, and `TESTS-RESULTS/2026-10-17+GH-1119/provenance.jsonl:1-2`.
  - `skills/3-weekly/worth-it/SKILL.md:1-193` stays within the 1024-char description ceiling, preserves the five-step flow (`Classify -> Score -> Gate -> Execute -> Log`), enforces read-only inspection during Steps 1–3 (`worth-it/SKILL.md:128,186`), gates `[RED]` and one-way-door decisions on explicit operator approval (`worth-it/SKILL.md:94-95,187`), and appends JSONL telemetry to `temp/worth-it-log.jsonl` (`worth-it/SKILL.md:130-149`).
  - SHA-256 verification (`python3` digest check in `.relay-scratch/tmp/probe6.txt`, exit `0`) matched `skills/3-weekly/worth-it/SKILL.md` (`01d5711d5de7529b8aad6ade83a6ab38e348d40fd2ba0e718c762865f4c8c93d`) and `skills/3-weekly/worth-it/LICENSE` (`8177f97513213526df2cf6184d8ff986c675afb514d4e68a404010521b880643`) against `skills/3-weekly/worth-it/NOTICE:13-14` and `TESTS-RESULTS/2026-10-17+GH-1119/provenance.jsonl:1-2`. `README.md:321-322` documents the third-party GPL v2 license carve-out.

- **[Pass] (Severity: None — Ledger Integrity & CI Routing Probe):** Read-only SQLite + dump inspection and `utils/ci-route.sh` probe (`.relay-scratch/tmp/probe6.txt`, exit `0`):
  - `releases.db` and `releases.sql` match at `generation=1770` (`releases.sql:2,10`), `op_receipts=1971`, and `roadmap_items` rows for `GH-960` (`id=323`, `status=planned`), `GH-1060` (`id=373`, `status=planned`), `GH-1088` (`id=374`, `status=planned`, rated `55/45/50/85`), and `GH-1119` (`id=375`, `status=planned`, rated `65/25/75/80`).
  - `jog_queue` preserves `development`'s `21` rows (`id=17` `GH-942` `completed`, `id=19` `GH-1075` `pending`), matching `TESTS-RESULTS/2026-10-17+GH-1121/resolution-1097.log:1-9` and `TESTS-RESULTS/2026-10-17+GH-1121/resolution-1120.json:1-28`.
  - Running `XYZ_CI_CHANGED_FILES="$(cat .relay-scratch/tmp/changed_files.txt)" bash utils/ci-route.sh pull_request` exited `0` with `docs_only=false`, `pdda_needed=true`, `changed_tests=gh589-xyz-mini-sync.sh,gh778-review-code-skill.sh,gh798-status-skill.sh`, `route=fast`, `tier=3`.

- **[Nit] (Severity: Low — Deferred to follow-up GH issue: `mini/README.md` prose skill count):** `mini/README.md:8` still reads `"Mini carries eleven skills and a TODO.md."`, whereas the table at `mini/README.md:17-30`, `utils/py/xyz_mini_sync.py:62-98`, and `test/gh589-xyz-mini-sync.sh:62` now carry twelve skills after splitting `review-code` into `review-code-xyz` and `review-pr-xyz`. Concrete fix (for follow-up GH issue): update `eleven` to `twelve` at `mini/README.md:8`.

- **[Nit] (Severity: Low — Deferred to follow-up GH issue / post-merge closeout note: `GH-960` `jog_queue` row absence in merged `releases.db`):** `TESTS-RESULTS/2026-10-17+GH-1121/BATCH-PLAN.md:31,37` states that `1097`'s `GH-960` Jog row stays failed until `jog land GH-960 --pr <n>` reconciles it (or retains failed/blocked if non-ledger merge deltas prevent `jog land` certification). Because `3f4fbd1faf` resolved `releases.sql` in favor of `development`'s `jog_queue` rows (`1..21`) and dropped `1097`'s verify-clone row `jog-01M51CM8TPRMEPM607GP7X8JYP` (`gh_number=960`), `releases.db` on this branch has no `jog_queue` row for `gh_number=960` (only `roadmap_items` `id=323`). Concrete fix (for post-merge closeout / follow-up GH issue): check whether the primary checkout's local `releases.db` holds a `GH-960` `jog_queue` row or reconcile `GH-960` via standard roadmap/issue-doc-sync reconciliation after merge.

- **[Nit] (Severity: Low — Deferred to follow-up GH issue: Pre-existing `ARCHITECTURE.md` section-header skill counts and `1089` cosmetic nits):** In `ARCHITECTURE.md:49` (`### 1-hourly (15)`) and `ARCHITECTURE.md:99` (`### 3-weekly (15)`), the parenthetical counts pre-date `GH-1119` (`1-hourly` lists 16 skills on disk and in its table; `3-weekly` now has 16 skills on disk because `weekly-planner` has no table row), while `### 2-daily (20)` (`ARCHITECTURE.md:72`) matches its 20 skills. Additionally, the three low-severity `1089` nits noted in `TESTS-RESULTS/2026-10-17+GH-1121/BATCH-PLAN.md:14` (`position=127` tie between `GH-1088` and `GH-1119` in `roadmap_items`, `(opened next)` placeholder in `PROJECT/2-WORKING/GH-1088-START-TASK-SMOKE-CHECK.md:121`, and Step 6 vs Step 8 numbering in `TESTS-RESULTS/2026-10-15+GH-1088/smoke-receipt.md:14`) remain cosmetic. Concrete fix (for follow-up GH issue): reconcile `ARCHITECTURE.md:49,99` counts and `weekly-planner` row alongside the deferred `1089` nits.

- **[Unverified — needs clone run] (Severity: None — Pending Disposable Full-Clone Pre-Push Gate & Exact-Head Hosted PR Checks):** Per reviewer turn constraints and `AGENTS.md`, `validate.sh`, `test/gh589-xyz-mini-sync.sh`, `test/gh778-review-code-skill.sh`, `test/gh798-status-skill.sh`, `test/gh609-start-task-resume-reconcile.sh`, `test/gh639-skills-army-hq-sync.sh`, `test/gh942-skill-frontmatter-budget.sh`, and `utils/pdda/pdda.sh run` were not executed inside this isolated review worktree. As explicitly separated in `TESTS-RESULTS/2026-10-17+GH-1121/BATCH-PLAN.md:25`, the disposable full-clone pre-push gate, exact-head hosted PR smoke check, and post-merge `wave-reconcile.yml` tier-3 qualification run after this review turn closes.

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

### System · relay-drive — 2026-10-17T23:50:26Z
terminal STATUS Approved written by FAILED reviewer turn (agy; shim returned non-zero) — reverted

### Coordinator disposition — cap2/2 exhausted
Driver rejected attestation. Header marked Escalated to prevent treating the reviewer report as an accepted approval. Historical reviewer block is preserved. Operator extension requested; no additional QA dispatched.
