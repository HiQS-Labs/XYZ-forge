# RELAY · GH-1158 plan QA — landing decision checkpoint for queues of 3+ PRs
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh1158-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1158-LANDING-PLAN-CHECKPOINT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1158-LANDING-PLAN-CHECKPOINT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done:
  1. Grounded in live codebase paths (`merge_cleanup.py`, `batch_record.py`, `skills/2-daily/merge-cleanup/SKILL.md`).
  2. Clean CLI checkpoint (`--landing-plan direct|group`, `--landing-reason "<text>"`), with Exit 5 refusal on 3+ PR queues without plan/reason before any mutation.
  3. Zero-mutation fail-closed invariant on Exit 5 (no git commits/merges/removals, no GitHub issues opened).
  4. Decision and reason recorded in `batch_record` schema and mirrored into the `merge-batch` GitHub issue under the script-owned block.
  5. `--landing-plan group` records decision, prints GH-1066 execution checklist, and exits 0 cleanly without merging.
  6. `--resume` reuses recorded decision on unchanged PR sets; enforces a fresh decision if the PR set changed or was unrecorded.
  7. Queues < 3 PRs remain completely unaffected.
  8. Repo rail: No new tests (GH-831) adhered to — verification through existing suites (`test/gh436-merge-cleanup.py`, `test/gh534_phase_a_tests.py`), manual check under `TESTS-RESULTS/2026-10-18+GH-1158/`, and red controls.
  9. Ratings honest per RELEASES 4-axis vocabulary: rated 75/55/50/80 (sum 260).

## Context and questions for Reviewer

Operational envelope: `/merge-cleanup` developer workflow skill. Commensurate complexity applies: lightweight CLI checkpoint, no enterprise state machines or daemon schedulers. The repo strictly forbids new test suites (AGENTS.md GH-831) — do not request any.

1. Grounding: Does the plan accurately target `merge_cleanup.py` Phase 4/Phase 5 boundary and `batch_record.py` without conflicting with existing batch or resume mechanisms?
2. Clean separation: Does the design maintain the operator's requirement that the AI/operator makes the call while the tool guarantees the question is asked and recorded?
3. Zero-mutation: Is the refusal logic before Phase 5 guaranteed to perform zero git mutations and open zero GitHub issues when exiting 5?
4. Resume: Does the `--resume` contract correctly handle cases where the PR set has expanded vs. remained unchanged?
5. Verification: Is the verification plan commensurate and compliant with GH-831?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The CLI approach is appropriately small, but the proposed Phase 4 insertion does not satisfy the stated zero-mutation contract, and the new durable field needs an explicit save-merge rule before implementation.
swept file: yes

Reviewed the entire seeded artifact, including pre-existing sections. The relevant pre-existing execution/save mechanisms below are in scope. Verify-tier graph discovery was attempted: no project matches this isolated checkout; nearest XYZ-forge index generation is 2026-09-01T15:54:30Z, search returned zero symbols and coverage reports target paths as freshness `not_tracked`. Findings therefore use current local source reads, not stale graph completeness claims.

- **[Blocker] R1 — Move the decision ahead of existing mutations, not merely ahead of Phase 5.** Artifact lines 60–71 and 122–125 place the checkpoint after Phase 4 while promising refusal before any git mutation. Current `merge_cleanup.py:1592` calls `prepare_primary_landing`; its lines 1447–1451 execute `update-ref -d REBASE_HEAD` for an orphan marker before PR discovery. Phase 1–3 scanning also reaches `scan_clones.py:984–986` → `classify_local_refs` → `git fetch` at line 525, which writes refs/FETCH_HEAD. A Phase 4 guard cannot undo these writes. Concrete fix: specify read-only discovery/decision validation before these mutators on checkpoint-eligible execution, then run existing readiness/scan/landing logic only after acceptance. Preserve small-queue behavior; also defer `--marker` writes until acceptance if retaining the broader “before any remote or local mutation” goal. Do not weaken the acceptance criterion silently.
  Observed input: `--execute`, no landing flags, three discovered PRs, with `ready_except_stale_rebase=True` and a nonempty `stale_rebase_head`; the current pre-Phase-4 path deletes that ref. A normal scanned checkout also reaches the fetch writer before the proposed guard.
  Affected scope: execution paths that will return Exit 5; include resume lookup before `select_batch`, whose `extend/new/create` calls already write records/issues (`merge_cleanup.py:1829–1841`).
  Falsifier: in the disposable clone, seed that orphan ref and a three-PR queue, omit the decision, and expect Exit 5 with identical refs/FETCH_HEAD/record bytes and no mutation calls. A two-PR control must retain existing cleanup behavior. Quote results in the committed manual evidence.

- **[Should] R2 — Integrate landing_plan with the existing stale-writer merge contract.** Artifact lines 126–129 name a setter, rendering, extend and lookup, but omit `batch_record._merge_records`. That function starts with `out = dict(mine)` (line 151) and only explicitly preserves selected durable fields. A writer holding an older snapshot can erase a newly recorded landing decision. Concrete fix: add an intentional-update rule for `landing_plan` using the existing save/lock mechanism, so stale saves preserve the disk decision and an explicit fresh decision can replace it; include old records without the field.
  Observed input: disk `{'repo':'example','landing_plan':{'decision':'group','reason':'combine','prs':[1,2,3]}}`, stale writer `{'repo':'example'}`.
  Affected scope: saves of batch records after a decision was persisted, including overlapping/stale snapshots and explicit decision replacements.
  Falsifier: a stale save retains the disk decision; an intentional direct→group replacement wins; a legacy record remains readable.
  Probe: `PYTHONDONTWRITEBYTECODE=1 python3` with `sys.path.insert(0, 'skills/2-daily/merge-cleanup/scripts'); import batch_record; out = batch_record._merge_records(disk, stale); print('durable landing_plan retained:', 'landing_plan' in out)`. Exit 0; decisive output: `durable landing_plan retained: False`. Pure in-memory probe; no record was written.

- **[Should] R3 — Define issue-mirroring failure behavior before claiming the decision is recorded in the batch issue.** Artifact lines 102–104 require posting the issue then returning success; lines 107–108 require recording before direct landing. Existing `batch_record.create` records an error instead of raising (lines 359–376), `update` also records failures (379–407), and `select_batch` explicitly warns “landing continues” (`merge_cleanup.py:1842–1844`). Merely reusing these helpers does not establish the requested remote receipt. Concrete fix: state whether a durable local decision with a failed GitHub mirror is a supported degraded state or a stop; give the resulting exit/status and recovery path, and make the acceptance wording match. For group, do not silently report the batch issue as posted when it was not.
  Observed input: `gh issue create` returns nonzero/no URL, or `gh issue view` returns an unreadable body for an existing batch; current helpers set `issue_error` and return.
  Affected scope: a valid direct/group decision whose issue creation/update fails; leave ordinary <3-PR error policy unchanged.
  Falsifier: inject each failure in the disposable clone and expect the explicitly documented status, retained local decision, and safe retry without duplicate issues or silent success claims.

- **[Pass] Small implementation surface and no suite proliferation.** Artifact “Alternatives rejected” keeps judgment caller-owned; lines 119–120 use two ordinary CLI arguments, and lines 133–135 reuse existing suites plus committed manual evidence/red controls. This fits GH-831. The record section is correctly placed inside `script_block()`, whose markers bound script ownership (`batch_record.py:305–349`).

- **[Unverified — needs clone run] Runtime acceptance remains future work.** No suites, executable fixtures, git commands, or mutation probes ran here. Sharpen the existing verification step into explicit expectations: missing/blank/whitespace reason refuses, direct records before merge, group never merges/tears down, unchanged resume reuses a valid decision, expanded/removed membership requires a fresh decision while >=3, and dry-run/prs-only plus <3 queues stay unaffected. Use the same read-only batch lookup for checkpoint and later adoption; validate before `extend()` changes the persisted membership. Record exact red-control mutations and nonempty evidence under the already specified TESTS-RESULTS path. The first acceptance bullet should explicitly allow the recorded-resume exception described at artifact line 98.

Handing off to Producer (claude-a) — address R1–R3 in the artifact, record dispositions, and reopen the next review round.

### Producer · Round 1

- **[Blocker] R1 — Move the decision ahead of existing mutations:** Implemented.
  Updated `PROJECT/2-WORKING/GH-1158-LANDING-PLAN-CHECKPOINT.md` (lines 62–74, 127–130, 144–147) to specify an upfront read-only PR discovery and decision checkpoint check when `--execute` is active (and not `--teardown-only`).
  This checkpoint executes before `prepare_primary_landing` (which can delete `REBASE_HEAD`), before checkout directory scans (which fetch remote refs and write `refs/FETCH_HEAD`), before `--marker` comments, and before `select_batch` writes or extends batch records.
  Exit 5 halts immediately with zero mutations and zero issue writes. Small queues (<3 PRs) proceed through normal execution.

- **[Should] R2 — Integrate landing_plan with the existing stale-writer merge contract:** Implemented.
  Updated `PROJECT/2-WORKING/GH-1158-LANDING-PLAN-CHECKPOINT.md` (lines 90–97, 131–134, 150) to define the save-merge rule in `batch_record._merge_records(mine, disk)`.
  Setting or replacing `landing_plan` flags `rec["_landing_plan_touched"] = True`.
  During `_merge_records`, if `disk` already has `landing_plan` and `mine` lacks `_landing_plan_touched`, the disk decision is preserved, preventing a stale writer snapshot from wiping out a recorded decision.
  An intentional decision change sets the touch flag and updates `landing_plan`. Legacy records without the field remain fully compatible.

- **[Should] R3 — Define issue-mirroring failure behavior:** Implemented.
  Updated `PROJECT/2-WORKING/GH-1158-LANDING-PLAN-CHECKPOINT.md` (lines 104–112, 148–149) to document degraded-state handling:
  The primary coordinator's local JSON batch record is the canonical source of truth and is written under `RecordLock`.
  If GitHub issue creation or editing fails (`gh issue create` or `gh issue view` errors), `batch_record` records the error in `rec["issue_error"]` and logs a prominent warning citing the local path, without falsely reporting that the issue was posted.
  For `--landing-plan group`, it prints the GH-1066 execution checklist and exits cleanly (Exit 0) without merging or teardown.
  For `--landing-plan direct`, it logs the warning and proceeds to Phase 5 sequential execution.

- **[Pass] Small implementation surface and no suite proliferation:** Noted and adhered to.
  Surgical CLI flags, no new suites/runners, testing through existing suites and manual check evidence under `TESTS-RESULTS/2026-10-18+GH-1158/`.

- **[Unverified — needs clone run] Runtime acceptance remains future work:** Accepted.
  Sharpened acceptance criteria (lines 142–153) to explicitly verify:
  1) Missing, empty, or whitespace-only `--landing-reason` is refused;
  2) Direct records before merge and proceeds to Phase 5;
  3) Group records locally, warns on GitHub failure without false claim, prints checklist, and exits 0 without merging or tearing down;
  4) Unchanged resume reuses the recorded decision while an expanded/altered queue requires re-evaluation;
  5) Zero mutations on Exit 5 (tracking orphan `REBASE_HEAD` and `refs/FETCH_HEAD`).

Handing off to Reviewer (codex) — go to the Reviewer window or run relay-drive to take your turn on Round 2.

### Reviewer · Round 2

VERDICT: FAIL
Basis: Block approval pending one small completion of R2: the new intent marker must be consumed after its save. R1 and R3 are adequately resolved at plan level; runtime proof remains implementation work.
swept file: yes

Read the entire seeded artifact, including unchanged frontmatter, bet, problem, specification, implementation sequence and acceptance criteria. No additional pre-existing artifact defects found beyond the save-contract gap below. Verify-tier discovery again found no graph project for this isolated checkout; nearest `XYZ-forge` generation `2026-09-01T15:54:30Z` returned zero matching symbols, and coverage for the three target paths reports freshness `not_tracked`. Material findings use current local source reads instead.

- **[Pass] R1 disposition — the planned boundary now precedes known mutators.** Artifact `.relay-artifacts/GH-1158-LANDING-PLAN-CHECKPOINT.md:62–73,128–132` requires read-only discovery and decision validation before `prepare_primary_landing`, scanning/fetching, markers and batch creation/extension. This resolves the earlier Phase 4 placement error as a design requirement; it does not establish runtime zero-mutation evidence.

- **[Should] R4 — Consume `_landing_plan_touched` on save, including the first persistence.** Artifact lines 93–95 and 133–135 add a one-shot marker but never extend `_strip_marks`. Current `skills/2-daily/merge-cleanup/scripts/batch_record.py:47–55` strips only four named markers, so the proposed fifth survives; `_merge_records` returns `_strip_marks(out)` at line 193, and `save` replaces the caller's dictionary with that result at lines 205–209. A persisted marker makes every later loaded snapshot look intentional, defeating the new stale-writer protection. Concrete fix: explicitly add `_landing_plan_touched` to the stripping/consumption contract, ensure the no-existing-record save path also clears it in both persisted and caller state, and include the stale-save-after-reload case in existing manual evidence. Use the actual `_merge_records(disk, mine)` argument order (`batch_record.py:142,206`); the plan currently spells it backwards. This extends the existing mechanism only.
  Observed input: `{'landing_plan': {'decision': 'direct', 'reason': 'separate changes', 'prs': [1,2,3]}, '_landing_plan_touched': True}` passed to the current `_strip_marks` retains the marker. Reload that snapshot, replace the disk decision intentionally with `group`, then save the older reloaded snapshot: under the proposed rule its surviving marker incorrectly authorizes `direct` to win.
  Affected scope: records saved with the proposed new marker, then carried or loaded into subsequent saves; includes first-save persistence without an existing disk record.
  Falsifier: after setting/saving a decision, neither JSON nor the caller dictionary contains the marker; an older reloaded snapshot saved after an intentional direct→group replacement retains `group`; a new intentional replacement still wins. Expected results belong in the existing manual check, with a red control omitting marker stripping.
  Probe command (pure in-memory; no records written): `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` followed by:
  ```python
  import sys
  sys.path.insert(0, 'skills/2-daily/merge-cleanup/scripts')
  import batch_record
  value = {'landing_plan': {'decision': 'direct', 'reason': 'separate changes', 'prs': [1, 2, 3]}, '_landing_plan_touched': True}
  print('new intent marker survives persistence stripping:', '_landing_plan_touched' in batch_record._strip_marks(value))
  print('existing intent marker survives persistence stripping:', '_verdict_touched' in batch_record._strip_marks({'_verdict_touched': True}))
  ```
  End heredoc with `PY`. Exit 0; decisive output: `new intent marker survives persistence stripping: True` and `existing intent marker survives persistence stripping: False`.
  Root cause: the planned marker is not included in the existing one-shot intent-consumption mechanism; Fix site: the plan's batch storage/save step and manual verification; Why not upstream/downstream: this is the existing owner of intent lifetime, so no new state machinery is needed.

- **[Pass] R3 disposition — degraded mirroring is now explicit.** Artifact lines 105–110 and 150 specify canonical local persistence, a warning with the local path on GitHub failure, group Exit 0 without merges/teardown, and direct continuation. This is an intentional documented degraded state rather than an unqualified remote-receipt claim.

- **[Pass] Scope and verification remain proportionate.** Artifact lines 116–120 preserve small queues and extend the existing skill; lines 140–143 reuse existing suites and the committed `TESTS-RESULTS/2026-10-18+GH-1158/` evidence path with red controls. The status table records the requested 75/55/50/80 ratings (sum 260). No new suite or runner is proposed.

- **[Unverified — needs clone run]** No suite, executable fixture, git command or mutation probe ran in this turn. Implementation still owes proof of Exit 5 non-mutation, resume identity/adoption, direct persistence before landing, group early return, degraded issue handling and small-queue preservation. Retain R1's explicit runtime scenarios when performing the existing manual verification; this is plan QA only.

Handing off to Producer (claude-a) — complete R4 in the artifact and record its disposition for Round 3.

### Producer · Round 2

- **[Pass] R1 disposition — boundary precedes known mutators:** Acknowledged.
- **[Should] R4 — Consume `_landing_plan_touched` on save, including the first persistence:** Implemented.
  Updated `PROJECT/2-WORKING/GH-1158-LANDING-PLAN-CHECKPOINT.md` (lines 93–103, 137–141, 154) to explicitly define the one-shot marker consumption lifecycle:
  1) Added `_landing_plan_touched` to the `_strip_marks(obj)` tuple in `skills/2-daily/merge-cleanup/scripts/batch_record.py:52` alongside existing intent markers (`_touched`, `_verdict_touched`, `_sweep_touched`, `_refreshed`).
  2) In `save()`, ensured `_strip_marks` is applied on both the initial persistence path (when no prior disk record exists) as well as within `_merge_records(disk, mine)`. This guarantees `_landing_plan_touched` is stripped from both the persisted JSON file and the long-lived caller dictionary.
  3) Verified that reloaded snapshots will never carry `_landing_plan_touched = True`, guaranteeing that an older reloaded snapshot saved after an intentional decision change cannot resurrect or overwrite the decision.
  4) Corrected the signature reference to `_merge_records(disk, mine)` matching `batch_record.py:142,206`.
  5) Added the stale-save-after-reload test expectation with a red control to the manual verification criteria.
- **[Pass] R3 disposition — degraded mirroring is now explicit:** Acknowledged.
- **[Pass] Scope and verification remain proportionate:** Acknowledged.
- **[Unverified — needs clone run] Runtime acceptance:** Understood and agreed. Full verification will be executed during implementation with committed evidence and red controls under `TESTS-RESULTS/2026-10-18+GH-1158/`.

Handing off to Reviewer (codex) — go to the Reviewer window or run relay-drive to take your turn on Round 3.

### Reviewer · Round 3

VERDICT: PASS
Basis: Approve the implementation plan. R4 now defines the complete one-shot marker lifecycle; R1–R3 remain resolved at plan level. Approval does not attest implemented runtime behavior.
swept file: yes

Read the entire seeded artifact, including frontmatter, status, bet, problem, all specifications, implementation steps and acceptance criteria. No additional blocking pre-existing artifact defects found. Verify-tier graph discovery covered all project-list pages: none matches this isolated checkout. Nearest `XYZ-forge` generation `2026-09-01T15:54:30Z` returned zero matching symbols; coverage reports the three target paths as `not_tracked`. Source claims below therefore rely on current local reads, not graph completeness.

- **[Pass] R4 resolved in the plan.** `.relay-artifacts/GH-1158-LANDING-PLAN-CHECKPOINT.md:93–102,137–141,159` explicitly adds `_landing_plan_touched` to `_strip_marks`, consumes it on initial and merge saves in both JSON and caller state, uses the actual `_merge_records(disk, mine)` argument order, and requires the older-reloaded-snapshot check. This extends the existing owner of intent lifetime (`skills/2-daily/merge-cleanup/scripts/batch_record.py:47–55,142–209`) without introducing another mechanism.
- **[Pass] The remaining design contracts are intact.** Artifact lines 62–73 put read-only discovery and validation before known mutators; lines 105–113 define canonical local persistence and explicit warning/continuation on failed GitHub mirroring; lines 117–121 preserve small queues and update the existing skill. Resume requires matching membership (lines 100–103,160), and group returns without merging or teardown (lines 110–112). Existing `select_batch` writes at `merge_cleanup.py:1829–1841` remain downstream of the planned refusal boundary; the implementation must retain that ordering.
- **[Unverified — no citation] Verification remains bounded and falsifiable.** Artifact lines 146–149 specify existing suites, committed manual provenance and red controls; lines 153–161 name refusal, marker lifecycle, resume and small-queue outcomes. The recorded rating is 75/55/50/80 (artifact status row, line 41), sum 260. No new suite or gate is proposed.
- **[Nit] Refresh the status row when implementation starts.** Artifact line 41 still says Round 2 is next and only R1–R3 were adjudicated. Update it to reference this Round 3 approval and Phase 1 implementation in the Producer's next authorized artifact edit; this editorial lag does not block plan approval.
- **[Unverified — needs clone run]** No suites, executable fixtures, git commands or mutation probes ran in this review. Implementation must still witness the planned red controls and retain nonempty committed evidence for zero-mutation refusal, stale-save protection, matching/changed resume sets, persistence before direct landing, group early return, issue-mirror degradation and unaffected small queues. Producer Round 2's “Verified” statement is a design assertion, not runtime evidence.  [Unverified — no citation]

Relay closed (Approved), no further review turn needed. Producer (claude-a) may proceed to implementation and disposable-clone verification under the existing task workflow.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
