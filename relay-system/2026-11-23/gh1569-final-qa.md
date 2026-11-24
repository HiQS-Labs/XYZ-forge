# RELAY · GH-1569 final QA (build_queue daily-goals checklist-only)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1569-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/kickstart/scripts/build_queue.py` (`CHECKBOX`, `parse_daily_goals_refs`), the committed
  implementation vs `origin/development` (base `2ac998d130d9b6940ab00884c4248f4672b2dabb`), together with
  `skills/1-hourly/kickstart/SKILL.md` (daily-goals bullet), the plan `PROJECT/1-INBOX/GH-1569-DAILY-GOALS-CHECKLIST-ONLY.md`
  (plan QA APPROVED round 2: `relay-system/2026-11-23/gh1569-plan-qa.md`), and the evidence `TESTS-RESULTS/2026-11-23+GH-1569/`
  (`manual-check.md`, `outputs/controls-green.txt`, `outputs/smoke.txt`, `provenance.jsonl`). `releases.db`/`releases.sql` changes are
  the roadmap row + rating written through `releases_app.py` (not hand edits).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Operational envelope: a ~540-line local developer CLI, read-only. Grade against the stated requirements and commensurate
  complexity. This repo forbids new test suites (AGENTS.md "No new tests", GH-831): a new `test/` file, `validate.sh` entry or gate
  machinery in the diff is a finding; `outputs/controls-probe-source.txt` is a retained evidence copy of a manual probe, not a suite.
- Requirements (issue #1569): with a task list in the daily-goals body, admit only numbers on unchecked `- [ ]` lines; a checked
  `- [x]` line and prose are not admitted; ONE lead number per checklist line (the FIRST `#N`; later ones are references);
  a body with no task list behaves exactly as today OR fails closed (smaller one chosen and proven: unchanged behaviour); handle the
  parser's other readers of that body; no new suite; red = #1568's ORIGINAL body (recovered via GraphQL userContentEdits): #1480/#1483
  queued and #1537 in Needs-the-operator on base, green = not; #1568's current body still yields 7 items; nested `(GH-…)` / `after #N`
  on checklist lines behave as stated.
- Rating persisted (read back via `releases_app.py roadmap list --json`): pri 60 / sev 45 / appeal 50 (neutral, no operator preference) / effort 90.

## Definition of Done (for THIS review)

STEP 1 — paraphrase first, from the plan only: **What this proposes**, **How the existing system works, per this document**, short **What it's not** (2-5 sentences each). State the input boundary.
STEP 2 — then read the diff (`git diff origin/development...HEAD -- skills/`), the source and the evidence; label that part "source-backed".

Questions (cite file:line):
1. Is each requirement of #1569 satisfied by the diff and observed evidence (not merely by a successful CLI exit)?
2. What prevents an unchanged, unfixed `build_queue.py` from being reported as delivered, and where is the observed rejection? Check `controls-green.txt` discriminator rows and the red/green CLI outputs; you may run narrow read-only probes (no `test/*`, no validate.sh).
3. Does the code match the plan (lead-ref rule: first `ATOMIC_REF` match consumed even when foreign/self/seen; unchecked no-ref line contributes nothing; no-task-list path unchanged)? Name any divergence or edge-case bug with a concrete input (Observed input / Affected scope / Falsifier).
4. Did a duplicate subsystem or writer slip in (second parser, new flag, new test/suite, hand-edited ledger)?
5. Is the persisted rating consistent with the evidence, and are the provenance receipts truthful (hashes match, synthetic fixture labelled, accounting-root deviation disclosed)?
6. Is the SKILL.md text accurate and its safety promise preserved? Is the diff free of accidental files (the relay-system threads and TESTS-RESULTS are intended)?

Write the verdict (PASS / FAIL) with a Basis; include a literal `swept file: yes|no` line.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

**What this proposes (plan only).** With a supported task list in the sanitized daily-goals body, admit only the first atomic reference on each unchecked checklist line. Checked lines and prose contribute nothing; without a task list, preserve the existing prose behavior (plan `PROJECT/1-INBOX/GH-1569-DAILY-GOALS-CHECKLIST-ONLY.md:42-63`).

**How the existing system works, per this document.** One admission parser selects numbers, then existing resolution and classification build the queue. A separate safety reader can hold the goals issue itself and PRs that close it; that reader stays unchanged (`:24-38`).

**What it is not.** This adds no queue subsystem, flag, runtime writer or test suite. The input boundary is the existing sanitizer followed by the specified `-`, `*`, `+`, `N.` checkbox grammar and ATOMIC_REF, not a new general Markdown parser (`:52-63`).

**Source-backed review.** Reviewed head `df505c685a7ca37aed12ba84cd1af1e1b8c6ffc9`. The source and SKILL blobs match evidence candidate `0855f773a3dba9e45410bdb25a573f73f38c15d0` and working bytes: respectively `fe69fe25d4a0f3cc5b1f889d14b2bb285aec6164` and `816d286d3f8f73ef222b728045fd74de0d32755e`. Per the turn prohibition, no Git command was executed: base source/tree came through the GitHub read connector at pinned base `2ac998d130d9b6940ab00884c4248f4672b2dabb`, compared with local committed trees and source using read-only Python. Graph tier: Verify; nearest indexed project was the primary XYZ-forge checkout, generation `2026-11-23T23:18:20Z`. Coverage reported missing freshness for these skill/plan paths, so the review used direct source fallback and makes no graph-completeness claim.

swept file: yes

- **[Pass] Plan and implementation agree.** `skills/1-hourly/kickstart/scripts/build_queue.py:97,259-284` detects checkbox presence after sanitization, skips checked/non-checkbox lines, and slices to the first ATOMIC_REF BEFORE foreign/self/seen filtering. Later refs cannot be promoted when the first is rejected. An unchecked no-ref line activates checklist mode but admits nothing. With no checkbox, all matches use the original filtering loop. Retained `TESTS-RESULTS/2026-11-23+GH-1569/outputs/controls-green.txt:1-14` and the independent probe below cover after-ref, second-ref, foreign/self/duplicate leads, no-ref, uppercase, nested, numbered and plus bullets. No divergence or edge-case defect requiring a fix found within the specified grammar.

- **[Pass] Acceptance rejects unchanged code.** `outputs/controls-green.txt:16-19` records #1480/#1483 queued and #1537 in Needs-the-operator on base, while candidate selects exactly #1417 #1467 #1471 #1497 #1500 #1530 #1551. The independent probe below reproduced both retained original-body outputs and rejected base by its excluded numbers, not its successful CLI exit. Current-body output is byte-identical base/candidate. The prior explicit red rejection is also preserved in `relay-system/2026-11-23/gh1569-plan-qa.md`: `AssertionError: acceptance rejected unchanged code: [1480, 1483, 1537]`. Prose parity is recorded at `outputs/controls-green.txt:19`; this turn also independently replayed the prose-only body with equal exit 0/output and an all-checked body with equal zero-selection errors on both versions. Unchecked-no-ref returned the same candidate zero-selection error with no output.

- **[Pass] Safety reader and ownership remain intact.** The only runtime delta is CHECKBOX plus parse_daily_goals_refs. Full base comparison leaves the other functions unchanged: selection at `build_queue.py:461-493`, safety collection/closing-target inspection at `:438,501-524`, and parked_issues/classify_prs at `:205-255,526`. Both versions return `{1568}` for `- [ ] #10 after #11` with open #11 (`outputs/controls-green.txt:15` and independent probe). I swept the complete 550-line script and complete SKILL.md and found no additional pre-existing defect to raise. Reversal is **Easy**: revert the parser and paragraph together; no state migration exists.

- **[Pass] Scope stays surgical.** The complete committed-tree comparison has 29 changed paths: two skill files, one GH-1569 plan, two intended relay threads, 22 intended evidence files, and releases.db/releases.sql. No test/, gate, new flag, second parser or runtime writer was added. `outputs/controls-probe-source.txt` is explicitly retained manual evidence, and was inspected but NOT executed here because it writes retained outputs. The CLI still writes only explicit --out (`build_queue.py:541-545`) and keeps --no-conflict-files on its live PR reader (`:424-425`). Literal search command `rg -n "build_queue|CHECKED_LINE|parse_daily_goals_refs" test/` returned no matches (rg exit 1); no source-text pin was found in that scope.

- **[Pass] Documentation, rating and receipts are consistent.** The SKILL.md delta is confined to `:305`; its safety promise at `:307` is unchanged. `releases.sql:1051` and the read-only SQLite query below agree on 60/45/50/90, consistent with one observed incident and a small fix (`plan:85-89`); CLI-shaped parked/rated/in_flight events are at `releases.sql:6026-6028`. Historical use of the CLI writer is producer-reported, not something DB bytes alone prove. `manual-check.md:20-22` labels the issue universe SYNTHETIC, and `:43-44` discloses the accounting-root deviation. All 21 nonempty artifact hashes/sizes in provenance.jsonl matched, including the retained probe and gate log.

- **[Pass] Verification limits remain explicit.** `manual-check.md:40-44` records docs/tier-1 routing, the retained PDDA result and unavailable mypy. This review does not claim a mypy/full-suite pass. The current-body `exit=` in `outputs/smoke.txt` is blank, so it is not used as exit evidence; the independent replay below returned 0. No phase gate is configured for this reviewer turn; none was run or assumed to run later. No validate.sh, test/*.sh, pytest, executable fixture, live service or Git command was run.

**Independent probe: exact command and retained source.** Command `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$PWD/.relay-scratch/tmp/final_probe.py"` exited **0**. Scratch base-build_queue.txt contains the source fetched at the pinned base through the GitHub connector. Subprocess execution is replaced with an assertion, preventing Git/network subprocesses. Probe source and decisive output are embedded because scratch is discarded.

```python
import contextlib,hashlib,io,json,re,runpy,sqlite3,subprocess,sys
from pathlib import Path
D=Path('TESTS-RESULTS/2026-11-23+GH-1569')
rs=[json.loads(x) for x in (D/'provenance.jsonl').read_text().splitlines()]
for r in rs:
 b=Path(r['artifact']).read_bytes()
 assert b and len(b)==r['size_bytes'] and hashlib.sha256(b).hexdigest()==r['sha256']
print('receipt hashes and sizes:',len(rs),'PASS')
con=sqlite3.connect('file:releases.db?mode=ro&immutable=1',uri=True)
assert con.execute('select rating_pri,rating_sev,rating_appeal,rating_effort from roadmap_items where gh_number=1569').fetchall()==[(60,45,50,90)]
print('persisted rating: 60/45/50/90 PASS')
mods=[runpy.run_path(p,run_name='review') for p in ('.relay-scratch/tmp/base-build_queue.txt','skills/1-hourly/kickstart/scripts/build_queue.py')]
def forbidden(*a,**kw):raise AssertionError('unexpected subprocess')
subprocess.run=forbidden
cases=[('- [ ] #10 after #1601',[10]),('- [ ] #11 and #12',[11]),('- [ ] #10 (GH-1700)',[10]),('- [ ] #11\n- [x] #9\nsee #10',[11]),('prose #10 and #11',[10,11]),('- [x] #10\n- [X] #11',[]),('- [ ] other/repo#9 then #10',[]),('- [ ] HiQS-Labs/XYZ-forge#9 then #10',[9]),('- [ ] #1568 then #10',[]),('- [ ] #10\n- [ ] #10 again #11',[10]),('- [ ] write it up\nOut of scope: #7',[]),('- [ ] `#10` after #11',[10]),('- [ ] #1\n  - [ ] #2 #3\n+ [ ] #4\n1. [ ] #5\n* [X] #6',[1,2,4,5])]
for body,want in cases:assert mods[1]['parse_daily_goals_refs'](body,'HiQS-Labs/XYZ-forge',1568)==want
print('parser controls: 13/13 PASS')
for m in mods:assert m['parked_issues']([{'number':1568,'title':'Daily goals','body':'- [ ] #10 after #11'}],set(),set(),'noelsaw1',{10,11,1568})=={1568}
print('safety reader: base=candidate={1568}')
for name in ('original','current'):
 outputs=[]
 for m in mods:
  sys.argv=['build_queue.py','--as-of','2026-11-20','--owner','noelsaw1','--repo-slug','HiQS-Labs/XYZ-forge','--other-session','1400,1418','--prs-json',str(D/'inputs/prs.json'),'--pr-meta-json',str(D/'inputs/pr-meta.json'),'--issues-json',str(D/'inputs/issues.json'),'--daily-goals','1568','--daily-goals-json',str(D/f'inputs/1568-{name}-body.json')]
  out=io.StringIO()
  with contextlib.redirect_stdout(out):rc=m['main']()
  assert rc==0 and out.getvalue();outputs.append(out.getvalue())
 b,c=outputs
 q=c.split('## Queue (execution order)\n')[1].split('\n## Needs the operator')[0]
 assert re.findall(r'^\d+\. #(\d+) ',q,re.M)==['1417','1467','1471','1497','1500','1530','1551']
 if name=='original':
  assert b==(D/'outputs/red-base-original-body.md').read_text()
  assert c==(D/'outputs/green-candidate-original-body.md').read_text()
  bad=[n for n in (1480,1483,1537) if f'#{n} ' in b]
  assert bad==[1480,1483,1537] and not any(f'#{n} ' in c for n in bad)
  print('unfixed acceptance REJECTED:',bad,'candidate exactly seven: PASS')
 else:
  assert b==c==(D/'outputs/current-body-candidate.md').read_text()
  print('current-body exit 0, seven items, byte parity: PASS')
print('all probes PASS; subprocess calls=0')
```

```text
receipt hashes and sizes: 21 PASS
persisted rating: 60/45/50/90 PASS
parser controls: 13/13 PASS
safety reader: base=candidate={1568}
unfixed acceptance REJECTED: [1480, 1483, 1537] candidate exactly seven: PASS
current-body exit 0, seven items, byte parity: PASS
all probes PASS; subprocess calls=0
```

VERDICT: PASS

Basis: The implementation matches the approved bounded plan; the red discriminator rejects unchanged behavior, independent green/parity probes reproduce the claimed outputs, safety evidence remains intact, and receipt hashes match. No required finding remains open. Approval covers this artifact review with the disclosed unavailable mypy/full-suite checks; it does not assume a future gate. Only this relay file was edited outside disposable scratch.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-24T05:35:19Z
task: RELAY-gh1569-final-qa
reviewer: codex
status: Approved
reviewed-head: df505c685a7ca37aed12ba84cd1af1e1b8c6ffc9
added-range: 11288+10305
added-sha256: d9fedd63834b0642ec72f2bb2fecec1147d8e4e23aeb9a916068f5f40397a159
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
