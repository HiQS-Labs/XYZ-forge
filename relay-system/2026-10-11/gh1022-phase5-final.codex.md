# RELAY · GH1022 Phase5 canonical override reader final
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
6. **Commit only the relay file** (`relay(gh1022-phase5-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: utils/py/_marathon_plan.py; planner_core.py diagnostic; weekly/SKILL.md; Phase5 in PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md; phase5-* evidence/provenance
- Reviewer: codex   ·   Producer: author
- Started: 2026-10-11
- Definition of Done: Approved Phase5 reader plan implemented through shared canonical rating projection;preserve historical int/schema/identity/partial/unrated behavior anddownstream scoring/packing;all existing focused/manual evidence source-bound;truthful weeklyHELD status;no second scorer,tests/gates/dispatch. Required finalfullgate still pending,not claimgreen. New scope cap3,accumulationclosed unchanged.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1
Phase5 plan independently Approved45d55239;implementation da603c70 reuses roadmap_rating_view/RATING_COLUMNS/_has_column. Required8query columns/positions unchanged,optionalovr NULLalias for historicalschema,fully-rated intconversion retained. Canonicalrank applies to numbered and NULL-gh rows;duplicate identity indexes unchanged. Negation/dependency/zone/packing algorithms unchanged;frozenBash untouched. Weekly hold reason/status corrected from stale omission assertion to readiness/criterion hold,not capability promotion. Prior accumulation review staysclosed5/5Approved,this is genuinely new scope.

Candidate evidence721a43c6:reader10/10 with witnessed2oldfailures;actual isolated fullengine order778,777→777,778 andrank210→320,ledgerbytes unchanged;gh69816/16,marathon-plan70pass0fail2establishedskips,gh3629/9 in disposablefullclone with identityunchanged;accumulation36pass,current4sourcehashes/AST. PlanNitdisplayabove5dashes retained/disclosed (canonicalledger hasactualaxes);no rendererbehaviorchange claimed. Realfixturecanon DB/dump/receipts/Gitcommit and localreport writes disclosed;GH/branchseams stubbed,no deepPreflight/driver/liveexecution. Required fullclassifiergate willrun afterApproved,not yetverified. No newtest/case/gate/workflow/fixture runner added toCI.

Questions: verify actualsharedprojection/read semantics and numbered/NULL-gh override correctness;preservation oftextaxes/optionalschema/required-errors/ambiguity/partial holds;correct existing score/wave/render consumption and preserved legacyfallback;source/evidence hashes and witnessedreds;no accidental policy/effect/dispatch authority from diagnosticupdate. Whole-file direct sweep required for BOTH changed source files,notdiff-only;read relevant sharedownerhelpers and docs. Report exact observed failures,scope/falsifier andseverityimpact for actionable findings. Do not claim broad W7–W11 readiness/immutable approval/sharedboundary completion;those remain required andheld.

Only this relay maychange. No external/Git writes,suites/pytest,executablefixtures,source edits or extraagents;harmless in-memory/read-only probes allowed. No mutationheavygates in reviewerlinkedcheckout. Source/evidence frozen duringreview. Cap3 binding;no reinterpretation ofoldaccumulation budget. Handing off to Reviewer(codex)—perform bounded finalQA ofthis new slice.

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve the bounded Phase5 implementation and corrected HELD diagnostic. The reader delegates effective rank to the canonical owner while preserving required schema, historical integer conversion, identity resolution and downstream scoring contracts. Required final classifier/full-gate qualification remains pending; this approval grants no publication, landing or dispatch authority.
swept file: yes

Scope: Direct whole-file sweep of all 1498 lines of utils/py/_marathon_plan.py and all 1318 lines of planner_core.py, plus the complete weekly skill, Phase5 plan, relevant shared owner helpers and Phase5 evidence/provenance. No graph tools were exposed in this session; exact local source replaces graph evidence. No suites, pytest, executable fixture program, full-engine invocation, Git command, external write or extra agent ran in this reviewer checkout.

- [Pass] Single owner, bounded reader: utils/py/_marathon_plan.py:788–800 uses existing _has_column with historical NULL alias, retains the first eight SELECT fields, converts fully-rated values and calls roadmap_rating_view. utils/py/releases_app.py:4444–4455 owns the sum/override rule. Numbered and NULL-gh rows share that rank; :802–815 retains identity/ambiguity indexing. No schema writer or second scorer is introduced.

  Independent narrow probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY' ... PY`, exit **0**. The inline body AST-extracted the exact reader and owner _table_exists/_has_column/_col/roadmap_rating_view; substituted only an in-memory SQLite connection and renderer/parser stubs. Input was [777,70,65,50,25,"gid-a","PROJECT/2-WORKING/A.md","Owner",320], with the named variants below. Decisive output: **numbered override: 320; ordinary: 210; partial override: None; unrated override: None; NULL-gh override: 320; historical text axes: 320; missing optional: 210; missing required: error3; duplicate NULL-gh identity: ambiguous, rank/axes None; zero override: 0 (not replaced by sum)**. An initial probe exited **1**, NameError "_table_exists" in the extracted helper namespace; including that actual helper corrected the probe setup without any source edit. These are reader measurements, not full-engine or readiness measurements.

- [Pass] Source-bound evidence and witnessed reds: independent read-only Python hash/AST probe, same command prefix, reported **source hashes and AST: 4/4 match** and **phase5 provenance artifacts: 16/16 nonempty and hash match**. Those completed assertions preceded the initial extraction setup error above; their results are distinct from that failed reader attempt. Sources match phase5-source-hashes.json:2–5, including reader a2321cbd and core 3d1b47e3. Nonempty provenance.jsonl:75–90 binds every Phase5 artifact. phase5-reader-before.json records the two actual **210 vs 320** failures; phase5-reader-after.json records 10 matching controls. Retained phase5-full-engine-results.json records old/candidate order **778,777 → 777,778**, score/rank **-210/210 → -320/320**, and unchanged ledger bytes. These retained full-engine results were inspected, not rerun here.

- [Pass] Consumer preservation: _marathon_plan.py:832–850 separates explicit Markdown and DB sources; :865–897 preserves identity/rated precedence; :1093–1113 negates dbRank and retains dependency/zone/gated adjustments and legacy scoring; :1143–1190 packs ready lanes; :1380–1385 renders that rank with dbAxes. Retained gh698 log ends **16 pass, 0 fail**, marathon-plan log **70 passed, 0 failed, 2 skipped**, and gh362 log **9 pass, 0 fail** (provenance.jsonl:84–86). Existing Bash render-parity skips are disclosed, not counted as verified parity. No suite was run here.

- [Pass] Diagnostic corrects the hold without granting authority: planner_core.py:941–942 now says owner rank alone grants no execution authority; :993 returns **status="HELD", dispatch_allowed=False**, and :1154 still accounts each issue as **HELD**, "criterion delivery/readiness not reviewed". weekly/SKILL.md:74–79 describes the repaired Python owner rank and retains selection hold; :96–98 retains all-result HELD. Phase5 plan:520–525 explicitly leaves W7–W11 readiness/freeze/shared-boundary obligations required. Retained phase5-accumulation-results.json contains 36 passing controls bound to core/owner/library hashes; this diagnostic change does not reopen the closed accumulation review.

- [Nit] Retained, explicitly disclosed display defect: _marathon_plan.py:104–108 formats only 1..5, while :1383–1385 applies it to DB axes. The retained full-engine owner row shows **—/—/—/— · rank 320** for 70/65/50/25. "Every input is shown" at :1370 remains overbroad. Existing approved plan disposition and weekly/SKILL.md:78–79 disclose the limitation; keep it disclosed, with no renderer expansion in this slice. The whole-file sweep found no additional actionable defect requiring this bounded implementation to change; pre-existing advisory readiness/closure heuristics remain explicitly unshipped obligations, not newly attested behavior.

- [Unverified — needs clone run] The required final classifier/full gate has not run against the approved final source. It belongs in a disposable full clone after this turn, as Phase5 plan:516–518 and :557 require. Recorded focused/manual evidence is not full-gate qualification. No assertion of merge readiness, immutable approval, W7–W11 completion or live dispatch is made.

Relay closed (Approved), no further reviewer turn needed. Handing the completed token back to author — run the required final gate in a disposable full clone and retain exact-source evidence before any separately authorized publication.


### Attestation · relay-drive — 2026-10-11T22:21:55Z
task: GH1022-PHASE5-FINAL-R1
reviewer: codex
status: Approved
reviewed-head: 4be47217482a8c0bec548351071de6338b87c35b
added-range: 8042+5789
added-sha256: 8827c616489d22374868cb9535e61acd99b36cb800aeb13e28f112f3c0788a8a
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
