# RELAY · GH-1114 plan QA: hosted reconcile qualifies with --parallel 4; receipt records first-attempt failures
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh1114-parallel-receipt-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1114-PARALLEL-QUALIFYING-RECEIPT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1114-PARALLEL-QUALIFYING-RECEIPT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-17
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Plan QA request.** Read `PROJECT/2-WORKING/GH-1114-PARALLEL-QUALIFYING-RECEIPT.md` in full, then `utils/py/wave_reconcile.py` L455-720 (qualification_summary, qualification_receipt_matches, select_qualification_gate, the glob at ~L682, the receipt writer ~L703-716), `validate.sh` L996-1012, L1100-1110, L1280-1320, L1345-1410, L1500-1545, `test/lib/runner-telemetry.sh` L68-80 and L170-180, `test/gh425-gate-provenance-pr.sh` L295-330 and L390-410, `test/gh740-hosted-lane-publish.sh` L45-65 and ~L182.

**Operational envelope (grade against this, not an enterprise threat model):** single-maintainer repo. Operator decisions already made and NOT under review: parallel is the standard qualifying form (#1118/#1114 override), a GH-528-rescued first-attempt failure does not block qualification but must be recorded in the receipt, sequential stays accepted and is the fallback, `ci.yml:203` promotion boundary stays sequential in this PR, no new test files or test cases (GH-831; any new case needs separate operator approval), no change to validate.sh.

**Questions (cite file:line):**
1. Reader semantics: with executed lanes = `sequential|pool|driver-lock` and final rc taken from the `lane:"retry"` suite row when present, is any input accepted that today's reader would (correctly) reject? Specifically: a suite with no pool row and only a retry row (validate.sh ~L1386-1388 "no recorded result" path), duplicate names across pool and driver-lock, and `suite_events_match` (validate.sh ~L1538-1540 counts pool+driver-lock+sequential only). Name the falsifier for each.
2. Glob `validate-*-{pgid}.jsonl` at L682: can a nested probe run (the gh425 decoy `validate-sequential-nested-0.jsonl`) or a shard file (`RT_SHARD`, per-worker `.w<pid>` shards, validate.sh ~L1261-1325) match the pgid-bound pattern after `rt_merge_shards`? If a shard can survive, name the exact filename shape.
3. Receipt: additive keys `mode`, `width`, `first_attempt_failures`, `retries` under schema `wave-qualification@1` — does anything reject unknown keys (`qualification_receipt_matches` L531-585, `test/gh740-hosted-lane-publish.sh:182`, hosted_lane_report.py, batch_record.py)? Is a schema bump required?
4. `ACCEPTED_GATES` at L539: does accepting both `--parallel 4` and `--sequential` for tier 3 open any receipt-forgery path that the existing telemetry sha256 + run-id binding does not already close?
5. Test adaptation: stub change at `gh425:299` to accept `"$*" = "--parallel 4"` — does any gh425 mutation (L396-406) or gh740 assertion become vacuous? Are gh425/gh740/gh421 the complete covering set for `qualification_summary` and `select_qualification_gate`?
6. Anything in the plan that is a generalization without an observed input, or anything the plan omits that the operator decisions require?

Please end with VERDICT and a `swept file: yes|no` line.
### Reviewer · Round 1

**VERDICT: FAIL**

**Basis:** The selected parallel gate and additive receipt approach fit the operator decisions. Tighten the reader contract and verification below before implementation. This is plan QA, not runtime qualification.

swept file: yes

Read the entire 48-line canonical `PROJECT/2-WORKING/GH-1114-PARALLEL-QUALIFYING-RECEIPT.md`, including risks and acceptance. Setup's `.relay-artifacts/GH-1114-PARALLEL-QUALIFYING-RECEIPT.md` is absent: `cat` exited 1, `No such file or directory`; the artifact directory contains only `gh182-claim-guards.md`. Review therefore uses the canonical copy explicitly requested in the Producer block. The stale graph (`XYZ-forge`, generation `2026-09-01T15:54:30Z`, another checkout) found no qualification symbols; coverage reported changed/untracked evidence paths, so current local source is the evidence. No source/artifact changes, Git commands, suites, or executable fixtures were run.

- **[Should] S1 — State which old reader checks survive the retry override** (plan:22). The existing full reader checks **every** suite row's integer rc, including non-suite Python/gamma probes (`utils/py/wave_reconcile.py:517-527`). Replacing this with final rc over executed names alone drops that protection. Preserve non-suite rc/type validation; allow an initial nonzero rc only for a registered suite with a successful retry. Preserve both executed-row count and unique-name count, not just set cardinality. Keep the summary/envelope/run-set/required-probe checks. This changes the existing reader, not the runner.
  Observed input: AST-extracted current reader, gh425-shaped sequential evidence with `registered=1`, `fixture.sh rc=0`, both required non-suite names, green summary; changing only `python:test_python_layer.py` to `rc=1` raises `ValueError`. Probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 .relay-scratch/reader_probe.py`; exit 0; decisive output: `baseline ACCEPT; summary mode=MISSING width=MISSING` and `non-suite python rc=1 / green summary: REJECT`. The probe extracted only `qualification_summary` using AST, supplied `json` and `SMALL_NON_SUITE`, and invoked no subprocess.
  Affected scope: full-registry telemetry under the proposed per-name retry reduction; non-suite probes are never eligible for retry replacement.
  Falsifier: on the implemented reader, the identical bad non-suite row must still raise; an otherwise complete parallel run with a failed pool suite and successful retry must pass and name that suite. If both already hold, no further change is needed. Record this as manual evidence, without adding a suite/case.

- **[Should] S2 — Make receipt metadata and tier selection observable in acceptance** (plan:24-25,47). `run.start` owns mode/width (`test/lib/runner-telemetry.sh:76-77`); `run.summary` lacks them (`:174-175`), and `qualification_summary` returns only the latter (`wave_reconcile.py:528`). Specify propagating the actual start values to the receipt, including sequential fallback, instead of deriving them from the requested gate. Existing gh425 evidence omits width (`test/gh425-gate-provenance-pr.sh:310`) and stays sequential; its argument-stub adaptation does not exercise the parallel reader or new receipt fields. A3's “existing gh425 paths” also does not establish both tier outcomes: gh425's fixture has no ci-route file, causing the classifier's full-gate fallback (`wave_reconcile.py:608-613`). Cheapest fix: extend the already planned manual verification description to inspect an emitted receipt's metadata/list/count and explicitly exercise the two classifier branches with controlled responses in isolation; retain command, result, red control and committed `provenance.jsonl` with the planned log. No new automated tests.
  Observed input: the probe above prints `summary mode=MISSING width=MISSING` despite a start row with `mode=sequential,width=1`; gh425 fixture rows at `:310-315` have no width anywhere. A3 at plan:47 names coverage that does not supply a tier-1 classification.
  Affected scope: production receipt metadata and the plan's A2/A3 evidence; historical width-less fixtures/receipts remain accepted.
  Falsifier: final manual evidence shows parallel receipt `mode=parallel,width=4`, its rescued suite/list/count, sequential fallback metadata `mode=sequential,width=1`, and tier-1 versus tier-3 gate selection; intentionally wrong metadata/gate is detected by the manual comparison.

- **[Should] S3 — Restore the active-document contract** (canonical plan:1-48). This pre-existing omission is in scope: the file starts with a heading and contains no YAML frontmatter or near-top `## Status` table. `PROJECT/PDDA.md:47-61` requires both for `PROJECT/2-WORKING` documents. Add the required frontmatter and exact two-column status table; include targeted doc hygiene in the later disposable-clone verification. This is a document correction, not a runtime behavior change.

- **[Pass] Q1 — Retry-only completeness remains rejected if existing checks stay.** A missing initial worker record can be rescued by `validate.sh:1384-1391`, but the telemetry summary counts only pool/driver-lock/sequential (`:1538-1543`), so such a run has `suite_events_match=no`; retaining `wave_reconcile.py:521` rejects it. Falsifier: complete pool evidence plus a successful retry must pass, while removing the initial row and using the runner's resulting `suite_events_match=no` must fail. Pool/driver-lock names are partitioned from one run set (`validate.sh:1298-1304`); duplicates must not be collapsed into proof of completeness. Falsifier: two executed rows with the same name cannot replace two distinct suites. Do not relax `suite_events_match` to admit retries: retries are deliberately excluded from that denominator (`:1523-1527`).

- **[Pass] Q2 — The broadened pgid suffix excludes the named decoy and shards.** `test/gh425-gate-provenance-pr.sh:324` uses suffix `-0.jsonl`; worker filenames are `<main>.jsonl.w<BASHPID>` (`test/lib/runner-telemetry.sh:81-87`), and successful merge unlinks them (`:109-110`). Even a surviving shard cannot end in `-{pgid}.jsonl`. The same probe command above exited 0 and printed `validate-parallel-123-4242.jsonl True`, `validate-sequential-nested-0.jsonl False`, `validate-parallel-123-4242.jsonl.w999 False` using `fnmatchcase(name,'validate-*-4242.jsonl')`. Keep exact-one-file and launched run-id checks (`wave_reconcile.py:683-688`).

- **[Pass] Q3/Q4 — Additive keys need no schema bump for these readers.** `qualification_receipt_matches` selects known fields without a closed-key whitelist (`wave_reconcile.py:534-569`); gh740:182 calls that reader. `hosted_lane_report.py:123-127` reads logs/outcomes, not receipt JSON; `batch_record.py:263-279` consumes the classifier's tuple. Accepting historical sequential and new parallel gate strings does not add an authority boundary in this operational envelope: both require replayed telemetry, SHA digest and ancestry checks. These checks are consistency checks, not cryptographic authentication of an author. Retain Small's separate expected-list path (`wave_reconcile.py:558-564`).

- **[Pass] Q5 — Existing negative assertions remain meaningful, but coverage is bounded.** gh425's mutations at `:400-406` still target registry size, failed count, run-set, completeness and envelope; gh740's byte mutation at `:183-185` still tests the telemetry digest. Neither becomes vacuous from accepting the parallel argument. These suites plus gh421 cover receipt/reconciliation paths, not a demonstrated complete parallel/tier-selection covering set; see S2. **[Unverified — needs clone run]** Their actual post-change results and red controls must be measured after implementation in a disposable full clone.

- **[Nit] N1 — Correct two factual details without changing scope.** Plan:21 says Small is “~6 suites”; the same probe command exited 0 and reported `Small suite count: 72` from `utils/ci-route.sh:38`. Keeping Small sequential is an operator decision and remains intact. Plan:27's proposed comment change at `ci-route.sh:35` is unnecessary: that comment accurately describes the unchanged Small sequential gate. Omit that edit unless there is specific inaccurate wording to replace.

No additional pre-existing defect was identified in the plan beyond S3; the reader-contract ambiguity and evidence gaps are listed above. The root fix remains the existing qualification reader/writer and gate constant, with no new mechanism. No request here changes the chosen operator policy.

NEXT: Producer (claude-a) — disposition S1-S3 and N1, revise the plan, then return for Round 2. Handing off to Producer — go to the other window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
