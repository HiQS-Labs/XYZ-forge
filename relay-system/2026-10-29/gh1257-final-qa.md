# RELAY · GH-1257 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-29.
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
6. **Commit only the relay file** (`relay(gh1257-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/harness.py`
- Also review: utils/py/_marathon_plan.py (the compute/render split, _pack_waves, _contract_seams, releases_db cfg); the diff `git diff 89e1af53..HEAD -- utils/`; the approved plan PROJECT/2-WORKING/GH-1257-BACKLOG-WAVE-PILOT.md (plan QA: relay-system/2026-10-29/gh1257-plan-qa.md, Approved round 3); the evidence TESTS-RESULTS/2026-10-29+GH-1257/ (SUMMARY.md, provenance.jsonl, controls.txt, suites.txt, pilot-1/, the two control scripts); issue #1257.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-29
- Operational envelope: a local, single-operator, read-only experiment on an unmerged spike branch. Grade against the approved plan and its acceptance criteria with commensurate complexity; do not demand multi-tenant or enterprise machinery. XYZ-forge forbids new test suites (AGENTS.md, GH-831): a new `test/` suite or validate.sh entry would itself be a finding; verification is existing suites plus recorded manual controls.
- Definition of Done: each plan step 1–5 and acceptance criterion 1–6 is implemented as approved and substantiated by the evidence; the planner split is behaviour-preserving; no second planner, writer or suite slipped in; the tool stays read-only and offline; the ambiguity handling matches the plan; the evidence is honest about what it shows (including the #216 under-count); the 60/35/50/45 rating still fits.
- Questions:
  1. Does the code match plan steps 1–5 (including the F1–F6 dispositions)? Cite any divergence with file:line.
  2. Is the `Engine` split truly behaviour-preserving, including `_pack_waves(force_tail=True)` and `_contract_seams` (wave numbering), and is the recorded parity check adequate?
  3. Are there correctness bugs in `plan_draft`, `_build_proposal`, `_verify_plan_draft`, `init_from_prs`, the new `run_tick` branch, `_accepted_briefs` or `status`? Consider copied-vs-shared records, request consumption, reconciliation of a crashed plan-draft tick, and the synthetic tools' unchanged behaviour.
  4. Does the evidence substantiate every acceptance criterion, and is anything claimed that the evidence does not show?
  5. Anything over- or under-built for this pilot?
- Note: the full repository gate (`validate.sh`, route=full per `utils/ci-route.sh`) has not run yet; it runs once on the final approved commit in a disposable clone. Grade it `[Unverified — needs clone run]`, not as a code finding.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

**VERDICT: FAIL**

**Basis:** Two small implementation corrections remain in sourced-scope extraction/admission. The architecture and rating remain proportionate to this local read-only pilot; no new planner, validator subsystem or suite is needed. Full-gate readiness remains outstanding.

swept file: yes

Read all 1,148 lines of `utils/py/harness.py` and all 1,516 lines of `utils/py/_marathon_plan.py`, the approved plan and plan-QA history, evidence summary/provenance/controls/scripts and retained pilot outputs. Compared the three draft issues (#1201, #216, #478) with their capture docs through read-only source reads and GitHub connector fetches. The pre-existing rating-rendering defect below was found during the sweep; no other material pre-existing defect is asserted. Graph project enumeration has no index for this worktree; used direct source fallback, without an indexed-generation or exhaustive graph claim.

- **[Should] F1 — Folded YAML goals become a literal scope of `>` (`harness.py:440–444`).** The retained #478 draft's *only* scope is `{"heading":"frontmatter goal","source":"PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L16","text":">"}` (`TESTS-RESULTS/2026-10-29+GH-1257/pilot-1/slot_007.json`). Its actual goal starts on the next line, “No ATE invocation can hang past a bounded timeout inside a suite…”. This fails plan step 3's sourced scope requirement, yet the brief is `draft` and enters provisional packing. #216 also contains this marker as a second scope entry. Decode the frontmatter goal's scalar content, preserving source provenance; an unsupported/empty scalar must not count as scope. Correct the affected retained briefs/proposal and hand-inspection conclusions when rerunning evidence.
  Observed input: #478's capture doc `goal: >` at line 16 followed by substantive indented lines; retained `slot_007.json.scope[0].text == ">"`.
  Affected scope: frontmatter goal extraction, especially folded/literal multiline scalars; ordinary inline goals and headed scope must continue to work.
  Falsifier: the #478 input must yield the actual goal text, while an empty goal/block marker alone must yield no sourced scope and remain held if no other scope exists; an inline goal must still be extracted.
  Probe (exit 0): `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with `import json,re; from pathlib import Path; b=json.loads(Path('TESTS-RESULTS/2026-10-29+GH-1257/pilot-1/slot_007.json').read_text()); doc=Path(b['doc_path']).read_text(); print(b['scope']); print(re.search(r'^goal:\s*(.+)$',doc.split('\n---',1)[0],re.M).group(1)); print(doc.splitlines()[16])`. Decisive output: scope text `'>'`; extracted goal `>`; next line `  No ATE invocation can hang past a bounded timeout inside a suite, and no ATE child's`.

- **[Should] F2 — Apply the brief admission predicate to planner-ready requests too (`harness.py:365–378,454–463`).** `plan_draft` declares a ready record ready before checking scope, and `_build_proposal` preloads every active lane then ignores ready briefs. Thus an accepted ready brief with no sourced scope remains in provisional waves without a held reason. Plan `PROJECT/2-WORKING/GH-1257-BACKLOG-WAVE-PILOT.md:83` explicitly requires *both* sourced scope and write set for brief admission. Preserve the actual planner waves, but ensure a reviewed request failing this predicate cannot survive through the preloaded lane in the provisional view. Record the paired ready-brief control alongside the existing needs-contract control.
  Observed input: in-memory copy of retained `slot_001.json` (#418, `draft_status="ready"`, nonempty existing-contract write set) with only `scope=[]`; provisional packing still contains #418 and `held=[]`.
  Affected scope: provisional admission of reviewed/accepted briefs, including planner-ready requests; the actual planner view must remain unchanged.
  Falsifier: identical ready brief with sourced scope stays eligible; empty-scope version is held as `missing-scope` and absent from provisional waves, while #418 stays in the actual planner view in both cases.
  Probe (exit 0; no files written): `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'`:
  ```python
import sys,json,copy
from pathlib import Path
sys.path.insert(0,'utils/py')
import harness as h
from _marathon_plan import Engine
d=Path('TESTS-RESULTS/2026-10-29+GH-1257/pilot-1')
b=json.loads((d/'slot_001.json').read_text())
m=json.loads((d/'backlog-manifest.json').read_text())
e=Engine.__new__(Engine); e.findings=[]
r={'gh':418,'title':b['title'],'docRel':b['doc_path'],'deps':[],
   'state':'ready','writeset':[x['path'] for x in b['write_set']],
   'zone':'probe','zoneRule':{'maxPerWave':None,'conservativeWhenInferred':False},
   'zoneInferred':False,'wave':1}
c={'active':[r],'deduped':[r],'waves':[[r]],'contract_seams':[]}
for missing in [False,True]:
    brief=copy.deepcopy(b)
    if missing: brief['scope']=[]
    p=h._build_proposal(e,c,[brief],m,'probe',brief['request_id'])
    print(bool(brief['scope']),
          any(x['issue']==418 for w in p['provisional']['waves'] for x in w),
          p['held'])
  ```
  Decisive output: `True True []`, then `False True []`. This is a narrow admission probe, not an end-to-end tick run.

- **[Pass] F1–F5 from plan QA are otherwise substantially implemented by inspection.** Transactional consumption is at `harness.py:128–135,997–1007`; scoped nonzero/timeout/verification ambiguity at `:967–990`; crash reconciliation and completed-only accepted-brief selection at `:797–829`; frozen backup/Queue selection/exclusions at `:527–569`; four-file identity, render and hash verification at `:494–518`. The producer and tightened verifier ship together, consistent with `LESSONS-LEARNED.md:38–43`. Recorded controls in `controls.txt` show uncertain/quarantine for wrong hash, missing key, Markdown mismatch, missing file, post-output failure and missing receipt. Synthetic tools retain their failure branch at `:969–974`; this is source evidence, not a fresh synthetic soak.

- **[Pass] Planner reuse and copied provisional records fit the plan.** `_marathon_plan.py:812–861` retains forced-tail packing by default and returns unplaced lanes with `False`; `:863–879,1203–1209` preserve one-based seam numbering. `harness.py:366–367,371–375` copies lane records, and `:381–405` separates actual and provisional results. A narrow in-memory query of `Engine._pack_waves` on two ready records with reciprocal dependencies exited 0: `force_tail=False -> waves [], held [1,2]`; `True -> waves [[1,2]], held []`. The admission probe also left its input wave equal to 1. The retained parity receipt (`provenance.jsonl`, id `planner-split-parity`) reports equal exit codes and byte-identical report/render in five modes; this supports the claimed sample, not complete equivalence.

- **[Pass] Retained output attribution is consistent for the artifacts inspected.** Read-only SHA-256/render queries exited 0: `slot_001.json` hash `61c9e556…` and `slot_001.md` hash `054a9b11…` match slot 1's receipt; final proposal hashes `13ce15c0…` / `65781267…` match slot 10's receipt in `pilot-1/run.txt`. All four retained briefs and the final proposal match their Markdown renderers. Source hashes equal the provenance receipt: harness `fc728466…`, planner `f0bd8233…`. Earlier cumulative proposal versions are not retained; their receipts attest historical hashes, not today's shared-path bytes.

- **[Pass] #216's under-count is honestly reported, and the rating/scope remain reasonable.** `pilot-1/slot_004.json` has only `PROJECT/PDDA.md` in its write set; the actual issue names vendored planner paths and bare filenames. `SUMMARY.md` “Hand inspection” and plan `:110` explicitly describe the unsafe direction. Keep this limit visible; resolving bare names or validating stale readiness is separate design work. No demand for dispatch, adapters, a watchdog or a new suite. The 60/35/50/45 rationale at the plan's “Rating rationale” remains appropriate.

- **[Nit] Pre-existing DB-rating rendering uses the obsolete five-point formatter.** `_marathon_plan.py:104–108,1403–1407` renders retained #418's valid `88/78/80/75` axes as `—/—/—/—` while still showing its rank. A read-only call `'/'.join(_rating_num(a) for a in [88,78,80,75])` exited 0 with that output. This predates the split; record it as a follow-up rather than silently changing behavior in a parity-only refactor.

- **[Unverified — needs clone run] Remaining acceptance evidence.** The eight focused suite receipts/logs are retained (`suites.txt`), but this turn ran no suite or executable control script. The supplied evidence does not record `releases_app.py check`, frozen-twin staged check or PDDA outcomes required by AC1/AC6. Complete and retain those with the planned final full gate in a disposable clone. The parity receipt gives a descriptive candidate revision and no raw base/candidate report/render pair; retain exact revisions and comparison output on the corrective run. AC3's dependency/collision/absence accounting also needs an explicit evidence disposition: #418's retained brief has dependency #423; the three draft briefs have none; the final proposal has shared-spine seams but no explicit dependency field. Identify what was exercised and what was absent rather than implying every case ran. No local git command was run; the connector compare `89e1af53..0fcda47f` returned HTTP 404, so the requested baseline diff could not be independently inspected here.

Root cause: scope extraction accepts a YAML syntax marker as evidence, and provisional admission trusts planner readiness before applying the brief's scope predicate; Fix site: existing goal extraction and provisional admission in harness.py; Why not upstream/downstream: actual planner semantics should remain behavior-preserving, and renderer/verifier-only changes would preserve the wrong admission decision.

Handing off to Producer (claude-a) — address or disposition F1–F2, refresh the affected evidence and open round 2; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
