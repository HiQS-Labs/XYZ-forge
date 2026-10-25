# RELAY · GH-1208 plan QA: jog land accepts local reconcile evidence
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh-1208-plan-qa-jog-land-accepts-local-reconcile-evidence): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1208-JOG-LAND-LOCAL-RECEIPT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1208-JOG-LAND-LOCAL-RECEIPT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: the plan in the artifact is approved when a reviewer confirms, against the live
  source paths, that (1) the defect claim is grounded: `utils/py/jog_run.py:1189-1201` requires a hosted
  `wave-reconcile.yml` run and `.github/workflows/wave-reconcile.yml` is `workflow_dispatch` only (#1131);
  (2) the call-site claim is grounded: merge-cleanup Phase 5 (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:651-820`)
  invokes `run_jog_post_merge_land` BEFORE `commit_and_push_phase5_writes`, so a reconcile-commit check
  would refuse there and the reconciler's ledger write is the evidence that exists at that moment;
  (3) the local-evidence predicate (`roadmap_items` row for GH-N: `section == "Completed"` and `raw_text`
  contains `(PR #N)`) matches what `utils/py/wave_reconcile.py:1516-1581` writes, and is read through the
  existing read-only `connect()` already used in `jog_land` — no new file, schema, writer or reader;
  (4) hosted evidence stays accepted first and unchanged; "neither" still refuses with a message that names
  both remedies; `_landing_tail_proof` and all pre-merge checks are untouched;
  (5) the verification plan is falsifiable on the EXISTING gh280 fixture: the suite stays green unmodified,
  and a disposable copy whose stub `run list` returns `[]` turns L5 red on reverted code and green on fixed
  code, with a "neither" red control and an idempotent replay; no new suite or registry entry (GH-831);
  (6) the rating 78/75/50/85 is grounded in the stated consequence and recurrence; appeal neutral.
- Operational envelope: a ~15-line either/or evidence change in one function of a single-operator harness.
  Grade against #1208's acceptance, #1131, GH-1108/#1116's committed-receipt landing rules and GH-831; do
  not request a new receipt format, a second authority, hosted re-enablement, or enterprise threat models.
  Reviewer writes stay in this thread.
- Source paths to read: `utils/py/jog_run.py` (`jog_land`, `_landing_tail_proof`, `_committed_jog_receipt`),
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:640-830`, `utils/py/wave_reconcile.py:1500-1600`,
  `.github/workflows/wave-reconcile.yml`, `test/gh280-jog-marathon-adapter.sh:20-75` (gh stub) and `:995-1020` (L5).

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
Basis: The local-ledger design fits the actual call order and keeps the change in one function, but the plan stops before an existing downstream consumer that crashes on its primary success case. Amend the plan for that consumer before implementation. Reversibility: Easy — one-function change with a one-hunk rollback.
swept file: yes

- [Blocker] **The planned local-only success still crashes while constructing landing evidence.** Artifact lines 89-90 say “Nothing else in `jog_land` changes”, but `utils/py/jog_run.py:1221` unconditionally serializes `"hosted_reconcile": matching[0]`. With the planned `run list -> []` input, local evidence can pass the new gate while this expression raises `IndexError`. This occurs **after** `jog_set_status(..., "completed")` at lines 1215-1217 and outside the refusal handler at lines 1209-1211: queue completion can be written while the command fails and no landing marker is produced.
  Observed input: `matching=[]`, exactly the no-hosted-run case specified in artifact lines 104-108. The read-only expression probe below failed with exit 1.
  Affected scope: local-ledger acceptance when there is no matching hosted run; the existing hosted-success serialization must retain its current value.
  Falsifier: in the disposable gh280 copy, return `[]` from `run list` with the reconciled GH-901 row present; fixed L5 must exit 0, write parseable `landing.json` without inventing a green hosted run, and L6/L7 must replay successfully. An unchanged line 1221 cannot meet that result.
  Concrete fix: extend the one-function plan to define how the **existing** landing marker represents absent hosted evidence (for example, `hosted_reconcile: null` on local-only acceptance), preserving the hosted-success object. Include this marker assertion in the already-planned manual L5 check; no new receipt file, schema version, suite, or registry entry is needed.

  Probe command (with `PYTHONDONTWRITEBYTECODE=1` and scratch `TMPDIR`):
  ```sh
  python3 -c 'import ast,pathlib; t=ast.parse(pathlib.Path("utils/py/jog_run.py").read_text()); n=next(n for n in ast.walk(t) if isinstance(n,ast.Subscript) and n.lineno==1221); print(ast.unparse(n), flush=True); eval(compile(ast.Expression(n),"jog_run.py","eval"),{"matching":[]})'
  ```
  Exit: `1`. Decisive output: `matching[0]` followed by `IndexError: list index out of range` at `jog_run.py:1221`. Only this expression was evaluated; no repository function, fixture, git command, or suite was executed.

- [Pass] **Defect and call-site claims are grounded.** `utils/py/jog_run.py:1189-1201` queries hosted runs and refuses an empty list; `.github/workflows/wave-reconcile.yml:10-11` contains only `workflow_dispatch`. `merge_cleanup.py:782-805` runs local reconciliation and checks before Jog landing; both outer callers commit afterward (`:1423-1432`, `:1719-1726`). Requiring an already-created reconcile commit would fail at this call site.
- [Pass] **The proposed predicate reuses the existing owner and reader.** `wave_reconcile.py:1520-1521,1550-1558` writes `Completed` and `SHIPPED ... (PR #N)`; `jog_run.py:1202-1206` already opens the ledger read-only. The seeded `releases.sql:770,891` contains the cited GH-763/GH-1020 Completed rows with `(PR #1192)`. Artifact lines 17-21 and 77-90 preserve pre-merge/tail checks and the hosted branch, require refusal when neither evidence exists, and introduce no separate writer or store. Root cause: the landing consumer retained a per-merge hosted requirement after the workflow became dispatch-only; fix site: `jog_land`; upstream intentionally follows decision #1131.
- [Pass] **Verification is falsifiable at plan level.** The existing gh stub synthesizes green hosted evidence (`test/gh280-jog-marathon-adapter.sh:45-48`); L5 runs the actual offline reconciler before landing (`:1009-1013`), and L6/L7 already exercise replay (`:1029-1043`). Artifact lines 100-116 name retained provenance, a no-run pre-fix red/fixed green comparison, a neither-evidence refusal, replay, and a disposable full-clone gate without adding suites. Add the marker assertion requested above to close the missed consumer.
- [Unverified — needs clone run] No claim that the suite currently passes 223/223, that the modified copy passes, or that the final gate is green: those runs are prohibited in this reviewer worktree and remain implementation evidence owed under artifact lines 102-116.
- [Pass] **Rating rationale is proportionate to the stated scope.** Artifact lines 120-127 distinguish a blocked unattended landing from data loss, identify recurrence since #1131 and the #1200 dependency, and keep appeal at neutral 50. The one-function reuse supports the stated cheapness; these are prioritization judgments, not measured frequency claims.
- [Nit] **Correct two descriptions while revising.** Artifact line 30 says “committed ledger evidence”, although lines 61-63 and 83-84 correctly allow the about-to-be-committed writes. Lines 78-79 also overstate current error handling: `jog_run.py:1196` maps nonzero `gh` exit to `[]`, while malformed JSON reaches the outer `ValueError` handler. Describe that existing behavior accurately without silently widening this patch's scope.

Whole-artifact sweep completed, including frontmatter, scope, alternatives, rollback, verification, and rating rationale. No additional pre-existing defects found in the artifact beyond the findings above. Graph tools were unavailable; evidence uses direct source reads and the quoted pure-expression probe.

Handing off to Producer (claude-a) — revise the plan for the existing landing marker consumer and disposition these findings, then return for Round 2 QA.

### Producer · Round 1 — claude-a

Dispositions (plan revised in this commit):

- **Blocker — Accepted, and thank you: a real crash-after-commit.** `jog_run.py:1221` serialises `matching[0]` after `jog_set_status(... "completed")`; with `run list → []` the local path would complete the row and then raise `IndexError` with no marker. New plan item 4: in the same hunk the marker becomes `"hosted_reconcile": matching[0] if matching else None` (hosted success unchanged) plus a sibling `"local_reconcile": {"roadmap_gid", "raw_text"} | None`. Same file, same writer, no new receipt or schema; existing `landing.json` consumers read `merged_sha` and presence only. Manual check 1 now asserts `landing.json` parses with `hosted_reconcile == null` and a `local_reconcile` object, and that L6/L7 replay stay green.
- **Nit (wording) — Accepted.** Goal now says the evidence is "written, committed or about to be committed by merge-cleanup Phase 5"; the error-handling paragraph now states the existing behaviour exactly (nonzero `gh` → `[]` at `:1196`; malformed JSON → outer `ValueError` refusal; non-list → `invalid hosted reconciliation evidence`) and that none of it changes.
- **Also fixed while revising:** the gh280 L5 fixture is legacy-ROADMAP with no `roadmap_items` row for GH-901, so the disposable copy seeds the row the way the suite itself does at `:1089`; stated in manual check 1. Added a one-paragraph **Limit**: legacy-ROADMAP consumer repos without a ledger row keep hosted-only behaviour.

No change to the design's shape: either/or evidence inside `jog_land`, hosted first, refuse on neither, `_landing_tail_proof` untouched, ~20 lines.

VERDICT: PASS
Basis: blocker folded into the plan as item 4 with a marker assertion in the manual check; nits corrected; requesting round 2.

Handing off to Reviewer (codex) — go to the Reviewer window and say 'take your turn'.

### Reviewer · Round 2

VERDICT: PASS
Basis: Ship the plan. The revision closes the observed empty-hosted-list crash, specifies the existing marker's local-only representation, and makes the existing fixture usable for the proposed local predicate. Approval is for the plan; implementation and clone-run evidence remain outstanding. Reversibility: Easy — one function, existing reader/writer, one-hunk rollback.
swept file: yes

- [Pass] **Round 1 blocker is resolved at plan level.** Artifact `.relay-artifacts/GH-1208-JOG-LAND-LOCAL-RECEIPT.md:92-99` explicitly replaces the unsafe `matching[0]` at `utils/py/jog_run.py:1221` with `matching[0] if matching else None` and records local evidence in the same marker. Its verification at artifact `:123-125` requires parseable `landing.json`, null hosted evidence, the GH-901 local row, and successful replay. The hosted-success object remains unchanged; no additional receipt file or writer is proposed.
- [Pass] **The source still supports the defect, ordering, and bounded fix.** `jog_run.py:1189-1201` requires a successful hosted run; `.github/workflows/wave-reconcile.yml:9-11` is dispatch-only. `merge_cleanup.py:782-805` reconciles and checks before Jog landing, while its callers commit afterward (`:1423-1432`, `:1719-1726`). The existing read-only connection is at `jog_run.py:1202-1206`; the writer sets `Completed` and the PR badge at `wave_reconcile.py:1520-1521,1550-1558`. The actual GH-763 and GH-1020 rows carry `(PR #1192)` in `releases.sql:770,891`. Artifact `:17-21,81-90,101-104` preserves the committed-receipt, pre-merge and tail-proof boundaries and requires refusal naming both remedies when neither evidence exists. Root cause: the landing consumer retained a hosted-per-merge requirement after decision #1131; fix site: `jog_land`; why not upstream: dispatch-only reconciliation is intentional.
- [Pass] **Fixture correction and falsification are specified adequately.** The existing hosted stub is `test/gh280-jog-marathon-adapter.sh:45-48`, the real offline reconciler runs at `:1009`, and L6/L7 replay at `:1029-1043`. Artifact `:118-126` now seeds GH-901 using the existing `roadmap add` pattern at suite `:1089-1092`; `wave_reconcile.py:1525-1558` updates an existing DB row independently of the legacy markdown branch at `:1561`. Thus the copy can exercise the actual local evidence writer rather than relying on a missing row. Artifact `:114-133` requires retained provenance, pre-fix red/fixed green, neither-evidence refusal, marker assertions, replay with DB hash comparison, and the final disposable-clone gate, without a new registered suite.
- [Pass] **Rating remains proportionate to the bounded consequence.** Artifact `:143-150` explains 78/75/50/85 using a blocked unattended lifecycle, recurrence from the dispatch-only default, neutral appeal, and one-function reuse. Artifact `:135-139` explicitly limits local acceptance to issues with ledger rows. These are prioritization judgments, not claims of measured failure frequency.
- [Nit] **One stale error-handling sentence remains.** Artifact `:79-80` still says “Any error or non-list answer still raises `invalid hosted reconciliation evidence`”, contradicting the accurate paragraph at `:101-103`. `jog_run.py:1196` maps nonzero `gh` exit to `[]`, and malformed JSON reaches the outer `ValueError` handler at `:1209`. Delete that stale sentence or make it agree with the later paragraph during implementation; the later explicit paragraph makes the intended behavior clear, so this is not an approval blocker.
- [Unverified — needs clone run] No suite, executable fixture, gate, or git command was run in this reviewer turn. The 223/223 baseline, modified-copy outcomes, marker serialization, and DB-byte replay assertions are implementation evidence still owed under artifact `:114-133`; source review does not establish their runtime results.

Whole-artifact sweep completed (`:1-150`), including frontmatter, status, observations, alternatives, rollback, verification, limitation, and ratings. No additional pre-existing defects found in the artifact beyond the nonblocking wording nit above. Graph tools were unavailable; the bounded source evidence above comes from direct reads and text searches.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-10-25T03:36:23Z
task: RELAY-gh1208-plan-qa
reviewer: codex
status: Approved
reviewed-head: 6ec90623b882a6c779884a3c8a82d05c18132794
added-range: 15260+4311
added-sha256: 0fd9d67b7e652a08c7c7787e4a32e393654c842b33991bddcd25da8831c5b81a
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
