# RELAY · GH-1615 final QA: scoped wiring stub in the shared phase B fixture
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
6. **Manual relay: commit only the relay file** (`relay(gh1615-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1615-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-XYZ-forge/e3f96cf1-a102-4b6b-8e5b-e513c6a2ffc3/scratchpad/gh1615/GH-1615-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: Issue #1615's acceptance is met by the committed change; the code matches the approved plan; no duplicate subsystem, gate registration or new test slipped in; the retained evidence substantiates its claims and would have rejected an unfixed candidate.

### FORMAT (read first)
Inside your review block use **bold labels** (for example `**Q1**`), NEVER markdown heading lines (`#`, `##`, `####`). The driver counts a block's body only up to the next heading line, so a block that opens with a sub-heading is read as empty and called a stall. Keep the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`.

### What is under review
- The diff against `origin/development` is the artifact above (`test/`, `TESTS-RESULTS/`, `PROJECT/`, `releases.sql`; `releases.db` is binary and omitted; relay threads omitted). The approved plan is `PROJECT/2-WORKING/GH-1615-PHASE-B-FIXTURE-REPAIR.md` (Codex plan QA APPROVED round 2, `relay-system/2026-11-25/gh1615-plan-qa.md`). Evidence: `TESTS-RESULTS/2026-11-25+GH-1615/` (`SUMMARY.md`, `provenance.jsonl` with 20 rows, runners, `failures-at-base.txt`).
- The whole production-code change is 8 added lines in `test/gh534_phase_b_tests.py` (`LedgerFixture.setUp`). Read that file's fixture, `test/gh436-merge-cleanup.py:38-43` and `:1375-1390`, and `test/gh534_phase_c_tests.py:34`.

### Operational envelope and non-goals
- Test-fixture repair, XYZ-forge repo. XYZ-forge forbids new tests and gate registrations (`AGENTS.md` *No new tests*, GH-831): a new `test/` file, a `validate.sh` / `ci-local.sh` / CI entry, or an edit to the gated `gh436` suite in this diff is a finding. Editing an EXISTING suite to keep it truthful is allowed. No production code may change.
- Not yet run, by design: the repository qualification gate for the pushed commit. Do not assume it and do not demand it here.

### Questions (answer each; cite `file:line`)
1. Issue #1615's acceptance: (a) a recorded keep-or-retire decision, (b) fixture brought in line with GH-1576 and the suite shown passing on a clean clone, (c) a recorded run under TESTS-RESULTS with provenance. Is each met by the change and the receipts? Quote the deciding spans.
2. Does the code match the approved plan exactly (scoped `mock.patch.object`, `addCleanup`, placement next to the existing environment patch, the comment's claims true)? Is anything in the diff outside the plan?
3. What prevents an UNCHANGED, unfixed candidate from being reported as delivered, and where is the observed rejection? Cite `BASE-B-red`, `BASE-C-red` and the mutant rows. Could any row pass on empty or absent output? Are the two mutants discriminating (own assertion, differs from the original, green unmutated)?
4. Existing guarantees: try to violate them. The gated entry point now executes the changed fixture (`CAND-GATED-green`); importers (`IMPORTER-DRIVER`); the 24 phase B tests that already passed; scoped-stub stacking over `gh436`'s module-level stub. What did you try and find?
5. Test honesty: does the stub mock away a seam any phase B/C test claims to exercise? Any test asserting a historical invariant GH-1576 changed?
6. Documentation honesty: the plan, `SUMMARY.md` and the provenance correct the issue's "no gate runs it" and the earlier "no gated suite reaches the B1 path" claims. Are those corrections true and proportionate? Is anything overstated or unverified in `SUMMARY.md`, the plan's *Observed* table or the rating re-assessment (`30/35/50/65` to `20/25/50/85`, forced)? Label each remaining gap accepted-and-recorded or a finding.
7. Is any operator decision hiding (gate registration, deleting `gh436`'s now-redundant stub, anything else)?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix and `file:line` citations. Every behaviour-change finding needs `Observed input:` / `Affected scope:` / `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: PASS
Basis: Approve the fixture repair against the stated acceptance, based on the whole phase B file, phase C consumers, complete seeded diff and retained Producer receipts. No blocking defect, new test, gate registration, duplicate subsystem or production edit found. No pre-existing defect requiring a change was found in the phase B file sweep. This is independent source/evidence review, not an independent replay of the clone runs or qualification of a pushed commit. The one newly raised Nit below is optional.

- [Pass] **Q1 — acceptance met.** The recorded decision is “KEEP” (PROJECT/2-WORKING/GH-1615-PHASE-B-FIXTURE-REPAIR.md:65); the fixture repair is test/gh534_phase_b_tests.py:204–211. TESTS-RESULTS/2026-11-25+GH-1615/provenance.jsonl:12–14 records candidate `1a9cf2823`, exit 0, “Ran 39 tests ... OK”, “Ran 111 tests ... OK”, and “Ran 227 tests ... OK”; SUMMARY.md:5 identifies the base/candidate. Preserve those receipts. These are retained disposable-clone results, not runs performed in this reviewer worktree.
- [Pass] **Q2 — implementation matches the chosen design.** The scoped `mock.patch.object`, `start`, and `addCleanup(wiring.stop)` immediately follow the environment cleanup (test/gh534_phase_b_tests.py:201–211; plan:71–73). The seed copies only the releases app/resolver and supporting files, without githooks (test/gh534_phase_b_tests.py:181–190). Production's missing-installer refusal is explicit at skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1057–1059 and is called before landing at :1124. The existing module stub is test/gh436-merge-cleanup.py:43. The diff adds no production edit, new test file or registry entry; its remaining changes are the planned evidence, plan and ledger bookkeeping. No fix required.
- [Pass] **Q3 — red controls distinguish delivery.** provenance.jsonl:1 and :3 record `BASE-B-red` (exit 1, 14 failures/1 error) and `BASE-C-red` (exit 1, 32 failures/1 error), versus the candidate greens at :12–13. The failing-name lists reconcile to 15 and 33. Rows :15–16 record distinct mutant substitutions, `differs from the original: True`, own-assertion failures, and unmutated success: `3 != 0` for the allowlist and `'remote head moved' not found` for the head comparison. Those assertions exist at test/gh534_phase_b_tests.py:495 and :648. All 20 retained rows contain nonempty commands, revisions and decisive output (reviewer JSON/AST probe, exit 0: “receipts: 20 unique nonempty rows; base lists reconcile to 15 and 33 failures/errors”). No row is being accepted from an exit code alone. The experiment/collection helpers do not enforce success via process exit (run_stubbed_phase_b.py:6–9, run_stubbed_phase_c.py:6–9, collect_count.py:12–16); these are manual receipts, so reruns must inspect counts/OK/RESULT and nonempty output. Keep that interpretation; no new gate requested.
- [Pass] **Q4 — existing guarantees retained.** `CAND-GATED-green` records 227 tests and `IMPORTER-DRIVER` records “PASS rows=18 FAIL rows=0” (provenance.jsonl:14, :17). The complete 39-test candidate run at :12 includes the 24 previously green tests. I attacked patch stacking/restoration by executing only the AST-extracted three patch statements against dummy objects, without importing or running fixtures. Command below exited 0, decisive output: “PASS: real and aggregator identities restored; both call signatures accepted”. This checks the real cleanup mechanism against both prior identities; it does not pretend to replay the gate. No fix required.

```python
# Invocation: PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY' (body below; PY terminator)
import ast,types,unittest
from pathlib import Path
from unittest import mock
p=Path('test/gh534_phase_b_tests.py')
c=next(n for n in ast.parse(p.read_text()).body if isinstance(n,ast.ClassDef) and n.name=='LedgerFixture')
s=next(n for n in c.body if isinstance(n,ast.FunctionDef) and n.name=='setUp')
for prior in (lambda: 'real',lambda: 'aggregator'):
    obj=types.SimpleNamespace(gate_unwired_reason=prior); case=unittest.TestCase()
    exec(compile(ast.Module(body=s.body[-3:],type_ignores=[]),str(p),'exec'),dict(mock=mock,merge_cleanup=obj,self=case))
    assert obj.gate_unwired_reason(None)==obj.gate_unwired_reason(None,install=True)==''
    case.doCleanups(); assert obj.gate_unwired_reason is prior
print('PASS: real and aggregator identities restored; both call signatures accepted')
```

- [Pass] **Q5 — the seam being mocked is outside these tests' claims.** Phase B checks ledger classification, landing/repair and the ledger gate; the gate-red pin still patches `pre_merge_ledger_gate` separately (test/gh534_phase_b_tests.py:728–740). Hook wiring is a different function. Phase C imports the fixture at :34 and its override calls `super().setUp()` first at :249–250. The sweep found no B/C assertion demanding the GH-1576 wiring refusal or the old right to push an unwired clone. The comment accurately scopes the stub, and separate refusal evidence exists under TESTS-RESULTS/2026-11-21+GH-1576/provenance.jsonl. No fix required.
- [Pass] **Q6 — corrections and limits are proportionate.** `validate.sh:96` registers the wrapper, test/gh436-merge-cleanup.sh:11 executes the aggregator, and test/gh436-merge-cleanup.py:1382–1384 imports A/B/C. Thus the corrected gating premise (plan:42–55; SUMMARY.md:21) is true. Recorded collection/run receipts at provenance.jsonl:6–7 support all 39 B tests being included. Accepted-and-recorded limits are other untraced aggregator shims, missing raw baseline logs and outstanding qualification (SUMMARY.md:38–43). Candidate receipt snippets, rather than full raw logs or retained mutant runner, limit independent forensic replay; the precise substitutions/test names and own-assertion outputs at provenance.jsonl:15–16 are sufficient for this small repair. The rating explanation at plan:119 correctly narrows severity to standalone failures; the seeded releases.sql adds only GH-1615 and its pickup/rate/update receipts. The literal `--force` invocation is Producer-attested, not independently demonstrated by that SQL. None of these is a hidden qualification claim. Preserve the limits.
- [Nit] **Q2/Q6 — align the mutant A description.** Plan:96 names `eligible = None`, while provenance.jsonl:15 records `deferred_set = deferred_closure(all_ordered, eligible)` → `deferred_set = set()`. Both target the allowlist guarantee, and the observed assertion is discriminating, so this does not block approval. Optional fix: update that plan cell to the actual recorded substitution; do not rewrite the historical receipt.
- [Pass] **Q7 — no operator decision is hidden.** Plan:13–17 excludes new registration, retirement, production changes and editing the gated aggregator; :111–115 explicitly retains the aggregator stub and leaves any later deletion optional. The seeded diff respects those bounds. No additional decision or fix required.

Relay closed (Approved), no further turn needed. Producer may proceed with the separately recorded qualification/publication steps; this approval assumes no later gate result.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
