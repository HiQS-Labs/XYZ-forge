# RELAY · GH-1280 final QA: campaign dispositions and report
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
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
6. **Commit only the relay file** (`relay(gh1280-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `TESTS-RESULTS/2026-10-30+GH-1280/SUMMARY.md` (sha256
  `61910ac997aa13d86919d0f4594dfb51f44362c66a3cf4c372aae9f79db8cf33`) and the evidence it cites, all committed at
  `6e60dd4a` on `chore/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30`. `provenance.jsonl` (sha256
  `6a5dc903bf941d15da050126f5655ce4640e8d3e4d82943d4e6798f164bfdde9`) hashes every evidence file. A read-only copy of
  SUMMARY.md is also seeded at `.relay-artifacts/SUMMARY.md`. Do NOT edit any of it.
- Key evidence: `runs/long/supervisor-report.json`, `runs/long/campaign-report.json`, `runs/long/telemetry.jsonl.gz`
  (complete telemetry, 10,000 events), `ev/11-phase3.json` (R1–R4), `ev/12-phase3b.json`, `ev/14-d1-unsandboxed.txt`,
  `ev/06-candidate-status-creates-state.txt`, `ev/timeline.txt`, `contracts/contract-long*.json`, `tools/phase3*.py`,
  `tools/supervisor.py`. Source under `utils/py/` (harness.py `status()` ~line 1267, gen4_campaign.py).
- Prior reviews: `relay-system/2026-10-30/gh1280-plan-qa.md`, `relay-system/2026-10-30/gh1280-long-contract-qa.md`
  (round 2 PASS: "final campaign evidence and dispositions still require their separate review" — this is it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Operational envelope: one supervised local experiment on the operator's Mac Studio; disposable clones; no
  production-code change; no new tests (GH-831); nothing filed automatically. Grade against issue #1280's acceptance
  criteria (plan `PROJECT/2-WORKING/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md` § Acceptance criteria and Phase 3 step 11/13)
  and commensurate complexity.
- Definition of Done — answer each, citing file/section:
  1. Does every signal (D1–D6) have an accountable disposition with replay and clean/failing controls, and the row
     fields Phase 3 step 11 requires? Is any disposition wrong (e.g. D2 "expected behaviour", D4 "not flaky", D5
     "environment limit")?
  2. Do the long-run numbers in SUMMARY.md match the reports and telemetry (counts per class per target, 0 candidates,
     stop reason, deadlines, no survivors, canaries unchanged)?
  3. Are the deviations (corpus deleted by the replay reset; D4 replay setup fault) honestly stated, and does either
     invalidate a result?
  4. Is the acceptance criterion "stopped at the no-new-signal limit or earlier" met given D6, and is the stop/go
     recommendation supported?
  Approve only if the report and dispositions may ship as the campaign's record.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL

Basis: Hold shipping this version of the campaign record for two bounded reporting corrections. The supplied evidence supports the numerical results and D1–D5 dispositions; D6 leaves semantic stopping unproven, and the corpus description misstates what was recovered. Neither finding requests production changes, a new suite, or a repeat long campaign.

swept file: yes

Reviewed the entire seeded SUMMARY.md, bound to measured SHA256 `61910ac997aa13d86919d0f4594dfb51f44362c66a3cf4c372aae9f79db8cf33`, against the plan's Acceptance criteria and Phase 3 steps 11/13, the full supervisor and Phase 3 tooling, relevant source, reports and telemetry. Findings below include pre-existing content; no additional blocking defect was identified in this bounded document sweep. Verify-tier graph inventory has no current worktree project; nearest `XYZ-forge` generation `2026-09-01T15:54:30Z` reports harness metadata changed and gen4/evidence tooling unavailable. Current-source claims use direct reads, not graph completeness. No git command, executable fixture, suite, pytest or campaign ran. Runtime outcomes are inspected committed evidence, not fresh runtime verification; a requested runtime qualification would be **[Unverified — needs clone run]**.

- **[Should] F1 — DoD 3: correct the corpus recovery description (SUMMARY.md:108–112).** The report says the extract “lists the 1,736 admissions” and explains that “874 admissions evicted an older entry.” These are separate action populations: telemetry contains 1,736 `added`, 874 `evicted+added`, and 197 `replaced`; the 1,736-row extract omits the latter two populations. It therefore is neither all admissions nor a recovery of corpus membership. `utils/py/fuzz_engine.py:177–193` distinguishes these actions explicitly. Fix the prose to label the extract as only the `added` subset, state the omitted actions/counts and that final membership was lost (unless separately reconstructed and evidenced). Retaining complete telemetry preserves replay inputs and decision history, so this loss does not invalidate the measured invocation counts or D1.
  Observed input: `ev/13-corpus-long-from-telemetry.jsonl` has 1,736 rows; the complete telemetry's action counts are quoted below.
  Affected scope: the report's claimed recovered corpus coverage and interpretation of that extract.
  Falsifier: an extract containing the 874 eviction-admission events and 197 replacement events, or corrected wording explicitly limiting the existing extract to 1,736 `added` events, would remove the discrepancy.

- **[Should] F2 — DoD 4: explicitly disposition the no-new-signal acceptance criterion (SUMMARY.md:25–27,88–91).** “The ... no-new-signal stop [was] not reached” and “the budget ... stopped first, as the contract predicted” do not establish the plan criterion “stopped at the no-new-signal limit or earlier” when D6 itself labels novelty a faulty oracle. Bound compliance is supported; semantic stopping is not demonstrated. State this acceptance item as unproven/qualified because of D6, while retaining the budget and deadline successes and the conditional future go recommendation. Also narrow “could never fire” to this run's ineffective novelty measurement: the historical repeated-signature control and `Tracker.stop_reason()` show the stop can fire on other inputs. No retroactive contract change or rerun is required to publish an honest qualified experiment.
  Observed input: `supervisor-report.json` records 2,302 usage signatures of 2,313, stop `mutation budget reached (10000)`, streak 4 and quiet batches 0; SUMMARY D6 attributes this to echoed mutated tokens rather than new semantic signals.
  Affected scope: this campaign's acceptance statement and the scope of D6's claim; not the historical evidence or frozen contract.
  Falsifier: independent evidence that semantic no-new-signal stopping was reached or that the budget stop preceded that semantic limit would justify marking this acceptance item met; absent that, explicitly recording it as unproven resolves the reporting finding.

- **[Pass] DoD 1 — D1–D5 dispositions are supported, with limits stated.** `ev/11-phase3.json` R2 records status-first rc 0 → init rc 2 twice and DB creation; its overall `reproduced:false` reflects clean sandbox tick rc 1, which SUMMARY D1 expressly discloses. `ev/12-phase3b.json` supplies clean unsandboxed init/tick rc 0/0, versus `ev/14-d1-unsandboxed.txt` status-first 0/2/1. Together these support one low-severity initialization defect and its controls. SUMMARY D1 supplies target, argv, invariant, suspected cause, impact, owner, evidence, replay and issue-search result required by step 11. D2's R3 rc 0 with `?? NaN` is consistent with an explicit output path; R4's 234/234 guard messages support D3. D4's sole R1 mismatch (seed 12994 index 1) is resolved by `ev/12-phase3b.json`'s prefix rc 0 followed by Errno 20 rc 2, so the reset fault does not invalidate that classification. D5's same clean sequence with sandbox on/off gives tick 1/0; “environment limit” is justified at that boundary, while the specific denied operation remains unknown. D6 is correctly owned by campaign tooling rather than outer-loop code.

- **[Pass] DoD 2 — counts, deadlines and reported cleanup agree with the supplied evidence.** Independently parsed all 10,000 telemetry events: every per-target/class total matches SUMMARY's table (8,949 usage, 773 pass, 234 run-root, 21 cap, 18 state, 2 sandbox, 3 input). `campaign-report.json` has 200 batches, counts 773/8,949/278, 41 fp-genman contamination events and no host violations. `supervisor-report.json` has zero candidates, empty survivors/canary movement, launch 1793413513.190052, end 1793418008.246591 and discovery/total deadlines 1793435113.190052/1793442313.190052. This supports the report's budget/deadline arithmetic and its recorded cleanup outcome, not exhaustive OS containment proof. All 175 existing files with provenance hashes matched; decompressed telemetry SHA256 `f5f6dc41c8bc7e31d0117964d1262fe853db962044fbdbcc3d88bd9bf489a70a` also matches its provenance entry.

- **[Unverified — no citation] DoD 3/4 — deviations and conditional future recommendation are otherwise proportionate.** SUMMARY “Deviations” discloses corpus deletion, the replay reset fault, and historical controls tooling. Its “Coverage, honestly” excludes fuzzed sequences and limits stateful claims to Track B. “Go, after two changes” explicitly requires correcting D6 and resolving D5 before stateful fuzzing; it is not approval to launch that future campaign. F1/F2 are needed before this record ships.

Reproducible non-mutating accounting probe, exit **0** (only reads evidence; no fixture imported or executed):
```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PROBE'
import collections,gzip,json,pathlib,hashlib
p=pathlib.Path('TESTS-RESULTS/2026-10-30+GH-1280')
events=[json.loads(s) for s in gzip.open(p/'runs/long/telemetry.jsonl.gz','rt')]
print('events',len(events),'corpus_actions',dict(collections.Counter(e['extra']['corpus_action'] for e in events)))
print('extracted_rows',len((p/'ev/13-corpus-long-from-telemetry.jsonl').read_text().splitlines()))
r=json.loads((p/'runs/long/supervisor-report.json').read_text())
print('usage_signatures',sum('|usage|' in s for s in r['signatures']),'all_signatures',len(r['signatures']),'stop',r['stop_reason'],'streak',r['streak_at_stop'],'quiet_batches',r['quiet_batches_at_stop'])
print('artifact_sha256',hashlib.sha256(pathlib.Path('.relay-artifacts/SUMMARY.md').read_bytes()).hexdigest())
PROBE
```
Decisive output:
```text
events 10000 corpus_actions {'added': 1736, 'dropped': 7193, 'replaced': 197, 'evicted+added': 874}
extracted_rows 1736
usage_signatures 2302 all_signatures 2313 stop mutation budget reached (10000) streak 4 quiet_batches 0
artifact_sha256 61910ac997aa13d86919d0f4594dfb51f44362c66a3cf4c372aae9f79db8cf33
```

Handing off to Producer (claude-a) — disposition F1/F2, correct and rebind the report/provenance, then open Round 2; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
