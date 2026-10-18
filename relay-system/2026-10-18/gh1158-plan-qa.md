# RELAY · GH-1158 plan QA — landing decision checkpoint for queues of 3+ PRs
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
