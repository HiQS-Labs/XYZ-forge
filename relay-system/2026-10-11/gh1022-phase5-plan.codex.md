# RELAY · GH1022 Phase5 canonical override reader plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1022-phase5-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md Phase5; utils/py/_marathon_plan.py reader/callers; utils/py/releases_app.py roadmap_rating_view; TESTS-RESULTS/2026-10-11+GH-1022/phase5-reader-before.json
- Reviewer: codex   ·   Producer: author
- Started: 2026-10-11
- Definition of Done: Grounded smallest canonical override-reader plan;preserve required-column errors/optional historical schema,fully-rated integer axes,unrated holds,NULL-gh/duplicate identity,existing score/packing/Markdown/frozenBash behavior;existing/manual verification only;all wider W7–W11 remain HELD. No production implementation claimed. Own cap3,not an accumulation cap reset.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1
Genuinely new W8 prerequisite after accumulation review closed5/5 Approved;do not reopen/reset that artifact. Parent explicitly authorized normal capped review for new scope. Review ONLY the proposed canonical override-reader plan and preserved contracts,not delivered source: production reader is still unchanged. Current basef1225359,published31ba903e,no four other PR overlap. Source baseline10 shows exactly owner/document override210vs320 omissions;eight preservation controls pass. Existing canonical projection already owns arithmetic.

Questions: (1) Is the missing override proven at current canonical reader and are numbered/NULL-gh identities both covered? (2) Does reuse of roadmap_rating_view plus existing optional-column inspection preserve old required8-column failure semantics,fully-rated int conversion,unrated/partial holds andduplicate-doc ambiguity? (3) Are callers/rank-negation/dependency-zone adjustments,packing,Markdown/frozenBash behavior preserved with an honest targeted override semantic change? (4) Is verification bounded to existing gh698/marathon-plan plus recorded manual controls,no newtests/cases/gates? (5) Does plan keep all W7–W11 readiness/freeze/sharedboundary obligations active andweeklyHELD,without false completion or dispatch authority? (6) Is smallest change/rollback sufficient for this read-only seam?

No engine/source implementation writes yet. Reviewer reads plan/source/evidence;only this relay may change. Harmless in-memory probes permitted;no external/Git writes,suites,pytest,executable fixtures,extra agents or source edits. Full-module sweep needed for final code QA,not evidence that proposed code exists now. State explicit severity/impact for actionable findings;do not down-rank data loss. No lower-issue filing authority inferred beyond earlier scoped accumulation disposition. Cap3 binding. Handing off to Reviewer(codex)—take this new plan turn.

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve the proposed reader plan only. The override omission is reproduced in the unchanged reader for both supported identities; the plan reuses the existing projection and explicitly preserves historical conversion/schema/identity and downstream contracts. Implementation, full-engine behavior and final gates are not attested by this turn.
swept file: yes

Scope: Read all 533 lines of the owning plan, all 1489 engine lines, the entire CLI wrapper and baseline JSON. Releases-owner inspection is bounded to the rating projection, optional-column helpers and list consumers; this is not a new whole-module releases CLI QA attestation. Graph discovery used nearest indexed XYZ-forge, generation 2026-09-01T15:54:30Z; this worktree is not indexed, coverage metadata is changed/missing and the symbol query is insufficient. Exact local source is the evidence, not that stale graph.

- [Pass] Grounded minimal repair: `_marathon_plan.py:786–792` selects eight fields and calculates only the converted axis sum; `releases_app.py:4444–4455` already owns fully-rated effective override rank. Plan `GH-1022-WEEKLY-INTAKE.md:484–508` retains the required query, uses existing optional-column inspection/NULL alias and preserves integer conversion. Do not pass historical text axes directly into the shared projection's raw `sum(axes)`; the plan explicitly requires their conversion. No duplicate scorer, migration or writer is justified.

  Independent probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY' ... PY`, exit **0**. Body AST-extracted the actual `Engine._load_ledger_from_db`, used `sqlite3.connect(":memory:")` with `sqlite3.Row`, stubbed only connect/render/parse and supplied rows `[gh,70,65,50,25,"rmi-one","PROJECT/2-WORKING/OWNER.md","owner",320]`; it separately AST-extracted `roadmap_rating_view`/`_col`. Decisive output: numbered `{1022: 210}`; doc-only `('rmi-one', 210, (70, 65, 50, 25))`; canonical `'rating_calc': 210, 'rating_rank': 320`. This witnesses the required semantic change without executing a CLI, filesystem DB, fixture program or full engine.

- [Pass] Preservation controls match the current seam (`_marathon_plan.py:790–809`): the same probe returned ordinary, old-schema and text-axis rank **210**; partial/unrated maps **{}**; missing required field **'read-error-3'**; duplicate doc/title **('one of rmi-one, rmi-two', None, None)**. Baseline source SHA matched exactly, ten recorded controls are nonempty and its only mismatches are **['owner-override', 'doc-only-override']** (`phase5-reader-before.json:1–76`; retained baseline provenance entries `provenance.jsonl:75–77`). These are reader controls, not proof that all readiness states pass.

- [Pass] Consumer boundary is adequately bounded: `_marathon_plan.py:822–840` keeps explicit Markdown mode separate; `:856–879` resolves DB identity/rated precedence; `:1085–1092` negates rank then adds existing dependency/zone/gated adjustments; `:1106–1177` packs ready lanes; `:1376–1380` renders dbRank/dbAxes. Plan `:485–495` names those consumers and an Easy reader-only rollback. Keeping these algorithms unchanged still intentionally changes ordering for override rows; it does not promise byte parity for that changed input.

- [Nit] Pre-existing display limitation, non-blocking under the explicit Markdown-preservation scope: `_rating_num` accepts only 1..5 (`_marathon_plan.py:104–108`), but the DB axes use 1..100 and `:1378–1380` applies that formatter to them. Narrow AST-only probe command `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY' ... PY`, exit **0**, called that exact function on `(70,65,50,25)`: **axes ['—', '—', '—', '—'] legacy5 5**. Thus the existing “Every input is shown” sentence (`:1367`) overstates the display. Cheapest disposition: disclose this retained display limitation in final evidence; no renderer behavior change is required by this reader plan. The full sweep found no additional actionable blocker to the proposed slice; this known limitation is not silently treated as correct.

- [Pass] Verification and authority remain honest: plan `:509–518` specifies existing suites/manual controls, disposable full-clone runs, independent final whole-file QA and its own cap3, with no new tests/cases/gates. `:520–533` retains all W7–W11 readiness/freeze/shared-boundary obligations and weekly **HELD**. Accumulation review is not reopened or reset. `/debug-mantra` remains the execution-time failure protocol (`:175–176`).
- [Unverified — needs clone run] No implementation exists to approve, and no suites, pytest, executable fixtures, full-engine invocation, Git command or connector/network action ran here. Planned before/after engine/ordering/render checks and the classifier-required full gate remain mandatory after implementation; this PASS supplies no promotion, merge or dispatch authority.

Relay closed (Approved), no further plan-review turn needed. Handing the completed token back to author; proceed with the scoped implementation and its separately required final QA/gates.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
