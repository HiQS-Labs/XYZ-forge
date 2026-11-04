# RELAY · GH-1332 final QA: in-flight promotion passes roadmap coverage
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-04.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 4

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1332-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh1332-qa.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-04

### Artifact — gh1332-qa.md
````
## Diff (7af4ee3d..HEAD, code)

```diff
diff --git a/utils/pdda/pdda.sh b/utils/pdda/pdda.sh
index 7c54b747..26336e11 100755
--- a/utils/pdda/pdda.sh
+++ b/utils/pdda/pdda.sh
@@ -379,6 +379,19 @@ check_roadmap_coverage() {
     if pdda_roadmap_covers "$rel"; then
       continue
     fi
+    # GH-1332: Jog promotes a 1-INBOX doc on an execution branch without writing the ledger
+    # (one writer); wave_reconcile repoints the row after landing. Until then the moved doc is
+    # covered by its 1-INBOX pointer, provided the 1-INBOX file is really gone (a move, not a copy).
+    case "$rel" in
+      PROJECT/2-WORKING/*)
+        inbox_rel="PROJECT/1-INBOX/${rel#PROJECT/2-WORKING/}"
+        if [ ! -e "$PDDA_REPO_ROOT/$inbox_rel" ] && pdda_roadmap_covers "$inbox_rel"; then
+          pdda_record_finding info "$CHECK_NAME" "$file" 1 \
+            "promoted in flight: the ledger still points at $inbox_rel; wave_reconcile repoints it on landing" "skip"
+          continue
+        fi
+        ;;
+    esac
 
     pdda_record_finding error "$CHECK_NAME" "$file" 1 \
       "active working doc has no pointer in $ledger_name ($rel) — $ledger_hint, or set roadmap_exempt: true" \
```

# GH-1332 item 1: a doc Jog promotes on an execution branch passes roadmap coverage

**Cause.** `jog_run.promote_contract_to_working` moves a `1-INBOX` doc to `2-WORKING` on the execution branch and, by design, writes no ledger there (one writer; `_execution_root` refuses lane ledger changes; `wave_reconcile` repoints after landing). `pdda-check-roadmap-coverage` required the exact `2-WORKING` path in the ledger, so every gate run on such a branch failed: Marathon's `pdda.sh` pre-advance gate, and `pdda-repo-contract` / `gh269-roadmap-retired` in the full suite. In the #1298 batch this hit all five promoted items, and the workaround (repointing on the lane branch) broke `jog resume` / `jog land` by adding lane ledger changes.

**Change.** `utils/pdda/pdda.sh`, working-doc coverage loop only: a `PROJECT/2-WORKING/<name>` doc with no pointer is covered (INFO, not ERROR) when the ledger points at `PROJECT/1-INBOX/<name>` **and** that `1-INBOX` file no longer exists (a move, not a copy).

**Landing side (read, not changed).** `wave_reconcile.update_roadmap_entry` selects the row by `gh_number` and repoints it to the doc's destination when `doc_path` differs, so a row still naming `1-INBOX` is corrected when the PR lands.

**Manual check (no new test, GH-831)** in a disposable clone of `origin/development` `7af4ee3d`, output in `coverage-check-output.txt`:

| Case | Red (unpatched) | Green (patched) |
|---|---|---|
| A: `git mv` GH-1295 `1-INBOX` -> `2-WORKING`, ledger untouched (Jog's in-flight state) | ERROR | INFO "promoted in flight" |
| B: copy GH-1296 to `2-WORKING` (`1-INBOX` still present) | ERROR | ERROR |
| C: new `2-WORKING` doc with no ledger row at all | ERROR | ERROR |

**Not changed:** the `1-INBOX` coverage loop; item 2 of #1332 (`jog retry-gate` refusing a relay-receipt-only tail) stays open.

## Check output
```
== RED: origin/development 7af4ee3d ==
ERROR [pdda-check-roadmap-coverage] PROJECT/2-WORKING/GH-1295-INJECTED-TEXT-IN-BRIEFS.md:1 active working doc has no pointer in releases.db (PROJECT/2-WORKING/GH-1295-INJECTED
ERROR [pdda-check-roadmap-coverage] PROJECT/2-WORKING/GH-1296-LAUNCH-LANES-FAIL-PREFLIGHT.md:1 active working doc has no pointer in releases.db (PROJECT/2-WORKING/GH-1296-LAUN
ERROR [pdda-check-roadmap-coverage] PROJECT/2-WORKING/GH-99999-NO-ROW.md:1 active working doc has no pointer in releases.db (PROJECT/2-WORKING/GH-99999-NO-ROW.md) — park it 
== GREEN: with the GH-1332 patch ==
INFO [pdda-check-roadmap-coverage] PROJECT/2-WORKING/GH-1295-INJECTED-TEXT-IN-BRIEFS.md:1 promoted in flight: the ledger still points at PROJECT/1-INBOX/GH-1295-INJECTED-TEXT-
ERROR [pdda-check-roadmap-coverage] PROJECT/2-WORKING/GH-1296-LAUNCH-LANES-FAIL-PREFLIGHT.md:1 active working doc has no pointer in releases.db (PROJECT/2-WORKING/GH-1296-LAUN
ERROR [pdda-check-roadmap-coverage] PROJECT/2-WORKING/GH-99999-NO-ROW.md:1 active working doc has no pointer in releases.db (PROJECT/2-WORKING/GH-99999-NO-ROW.md) — park it 
```
````
- Definition of Done: #1332 item 1 is fixed without breaking Jog's one-writer ledger design: a doc Jog moved from 1-INBOX to 2-WORKING on an execution branch (ledger untouched) passes `pdda-check-roadmap-coverage`; a copy (1-INBOX still present) and an unregistered 2-WORKING doc still fail; after landing, `wave_reconcile` repoints the row; no new test file (GH-831).

**Operational envelope.** Local single-operator repo. A 13-line change to `utils/pdda/pdda.sh` (Forge is the canonical PDDA source; installed copies consume it). Grade against the stated requirement and commensurate complexity. You may read the checkout (it is `origin/development` 7af4ee3d plus this change); run no git and no suites. Edit only this relay file.

**Questions (design first).**
1. **Is relaxing the gate this way sound?** Read `utils/py/jog_run.py::promote_contract_to_working` (around line 1438; the `primary != root` branch returns before any repoint) and `_execution_root` (around line 524; refuses lane ledger changes vs `origin/development`). Is accepting the in-flight state in the gate the right place, versus having Jog write the repoint on the lane branch? Name any loophole: what else could now pass that should not (e.g. a hand `git mv` that is never reconciled, a 1-INBOX row belonging to a different issue with the same filename, the second (1-INBOX) loop).
2. **Landing side.** Does `utils/py/wave_reconcile.py::update_roadmap_entry` (around line 1540) really repoint a row whose `doc_path` still names `PROJECT/1-INBOX/<name>` when the doc lands from `2-WORKING`? Any path where it would not (doc found by filename, `moved_docs`, `repoint_moved_doc_rows`)?
3. **Matching.** `pdda_roadmap_covers` is a fixed-string `grep -F` over all `doc_path` and `raw_text` values. Can `PROJECT/1-INBOX/<name>` false-match another row's text?
4. **Evidence.** Do cases A/B/C detect the failure and guard the obvious regressions? Anything in the diff that should not be there?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

swept file: yes

VERDICT: FAIL
Basis: The bounded gate change is sound for the advertised move/copy distinction, but the unconditional landing guarantee in the artifact/DoD is not supported by the caller. Reviewed the entire embedded artifact and all of utils/pdda/pdda.sh, plus the relevant Jog and reconciliation paths. No additional concrete pre-existing defect identified in the pdda.sh sweep beyond the inherited matching limitation below. Graph discovery was unavailable (approval policy denied the tool); used source reads.

- [Pass] Preserve one writer: utils/py/jog_run.py:524 (_execution_root) rejects lane ledger changes, and promote_contract_to_working returns from the separate-primary branch before the roadmap update. Accepting the stale pointer in coverage therefore fits the existing ownership contract. Easy to reverse: remove the bounded fallback; installed PDDA consumers also inherit this behavior.
- [Pass] The new predicate at utils/pdda/pdda.sh:385-394 requires both an absent inbox source and inbox coverage; it leaves the inbox loop at :402-418 untouched. Thus a still-present source cannot take this fallback. Nothing unrelated appears in the embedded diff; it adds no test file.
- [Should] Resolve the overbroad promise that wave_reconcile repoints every in-flight row on landing. At utils/py/wave_reconcile.py:2392-2397, an OPEN issue with a found doc and a merged landing only records merge evidence; the update_roadmap_entry call is in the mutually exclusive branch at :2417. This matters for partial issue landings (the artifact itself says #1332 item 2 stays open). The INFO text at pdda.sh:390 also promises repointing on landing. Concrete fix: correct the artifact/diagnostic and explicitly disposition the DoD as permitting a stale pointer until terminal reconciliation, OR provide the narrowly scoped primary-side repoint for open landings if immediate convergence is required. Do not terminalize an open issue.
  Observed input: caller predicate doc_path truthy, issue_state="OPEN", is_merged=True, force_promote=False at wave_reconcile.py:2390-2397; it bypasses update_roadmap_entry and does not add a moved_docs entry.
  Affected scope: merged partial landings whose promoted working doc exists while their issue remains open and their ledger still names the inbox path.
  Falsifier: a disposable-clone reconciliation of that precise state which repoints the row to 2-WORKING while preserving its active section and OPEN issue would disprove the gap; the current branch predicts no repoint.
- [Nit] Matching is inherited substring coverage, not issue ownership or exact-path identity (pdda.sh:357-360). A raw_text mention of PROJECT/1-INBOX/X.md, or doc_path PROJECT/1-INBOX/X.md.bak, matches X.md. The fallback consequently cannot prove a Jog move, and a manual move can pass indefinitely. This is acceptable for the stated single-operator coverage gate if documented; do not present the missing-source check as proof of provenance. No speculative matching redesign requested.
- [Pass] Terminal reconciliation does repoint the owning row: wave_reconcile.py:1575-1588 substitutes the old path and invokes roadmap repoint when doc_path differs. find_active_doc_for_issue (:1070) locates docs by issue filename; missing/mismatched filenames provide no destination. repoint_moved_doc_rows (:1515) handles additional rows naming the source actually moved during reconciliation; a 2-WORKING→3-COMPLETED move does not itself match an additional row still naming 1-INBOX.
- [Unverified — needs clone run] Embedded A/B/C output is directionally appropriate, including a pre-fix red control, but was not rerun here. It shows per-doc findings, not isolated whole-command exit statuses (B/C deliberately remain errors). Before merge readiness, retain clone-run commands, statuses, and committed provenance as required by the repository. No validate.sh, test/*.sh, pytest, fixture execution, or git command was run this turn.

Handing off to Producer (claude-a): disposition the landing-guarantee finding and update the review artifact/implementation as warranted, then request the next review turn.

### Producer · Round 1 · claude-a

- **[Should] landing guarantee: accepted, wording fixed.** Confirmed at `wave_reconcile.py` ~2392-2397: a merge that leaves the issue open records evidence only. That is intended, so no code change. The comment, the INFO text (now "...until wave_reconcile closes the issue") and `SUMMARY.md` no longer promise a repoint on every merge; the fallback keeps covering the doc until the issue closes.
- **[Nit] substring matching: accepted, documented** in the code comment ("shows a move happened, not that Jog made it") and in SUMMARY's Limit paragraph. No redesign.
- **[Unverified] statuses: supplied.** Re-ran in the disposable clone against the final patch; `coverage-check-output.txt` now records `pdda.sh run` exit statuses: all three cases exit 1 both ways (B and C must fail); case A alone exits 1 unpatched and **0 patched**.

Diff since round 1: comment and INFO string in `utils/pdda/pdda.sh` (logic unchanged), `SUMMARY.md`, `coverage-check-output.txt`, `provenance.jsonl`. Round 2 requested.

### Reviewer · Round 2 · codex

swept file: yes

VERDICT: PASS
Basis: Ship for the bounded item-1 change, with the Producer's explicit disposition that partial landings may retain the stale inbox pointer until terminal reconciliation. Read the entire embedded artifact and relay history, the revised source predicate, summary, output and provenance, and the relevant Jog/reconciliation branches. The original embedded snapshot remains historical; the Round 1 Producer disposition and current SUMMARY supersede its unconditional landing wording. No additional concrete pre-existing defect identified in this review beyond the already documented substring limitation. Graph lookup was denied by approval policy; source reads supplied the evidence. Reversibility: Easy, by removing the fallback; distributed PDDA consumers inherit the gate relaxation.

- [Pass] Round 1 Should resolved without another ledger writer: `utils/pdda/pdda.sh:382-393` now says reconciliation occurs when the issue is reconciled closed, and the INFO says "until wave_reconcile closes the issue". `TESTS-RESULTS/2026-11-04+GH-1332/SUMMARY.md`, **Landing side**, explicitly permits an OPEN partial landing to retain the inbox pointer. This matches `wave_reconcile.py:2392-2397` (evidence only) versus the terminal update call at `:2417`; `update_roadmap_entry` at `:1575-1588` repoints the qualified owning row to the supplied destination. Approval adopts that disposition of the DoD, rather than promising immediate repointing on every merge.
- [Pass] The bounded predicate still requires missing inbox source AND inbox coverage (`utils/pdda/pdda.sh:388-394`); the second inbox loop is unchanged (`:404-420`). `_execution_root` (`utils/py/jog_run.py:524-537`) rejects execution-ledger changes, and the separate-primary promotion branch (`:1525-1528`) returns before repointing. The fallback therefore preserves the existing one-writer design. The accepted matching/provenance limitation is documented in SUMMARY's **Limit** paragraph; it is not an exact identity or Jog-origin check.
- [Pass] Evidence supplied for the previous status gap: `TESTS-RESULTS/2026-11-04+GH-1332/coverage-check-output.txt` records "patched: pdda.sh exit 0" and "unpatched: pdda.sh exit 1" for case A alone, plus exit 1 for both combined A/B/C runs and ERROR findings for B/C. `provenance.jsonl` names the command, base revision, artifacts and observed outcomes. This is inspected producer evidence, not an independently executed clone run; the post-turn harness gate still must attest the final state before merge readiness.
- [Unverified — no citation] Scope remains the roadmap-coverage fallback and its documentation/evidence; the embedded diff adds no test file or unrelated implementation. No source/artifact edit, git command, suite, pytest or executable fixture was run this turn. Only this relay file was changed.

Relay closed (Approved), no further turn needed. The harness owns the file-scoped commit and subsequent gate.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
