# RELAY · GH-1476 holds-only repair plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 1

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
6. **Manual relay: commit only the relay file** (`relay(gh1476-holds-only-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1476-RAW-TASK-PREPARATION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Definition of Done: Review ONLY the section "Holds-only repair plan — 2026-11-25" of the seeded artifact (the rest is history). Envelope: local-first developer CLI; plan and review only, no implementation; no new test suite (GH-831), scheduler, database or attempt reset.
  **Scope is settled by the operator decision of 2026-11-25 on #1476** (issue comment, "Operator decision 2026-11-25"): before a task is promoted out of the inbox or handed to a worker, refuse it on a hold in the live issue, a hold in the capture/preparation document, or work it comes after that is not confirmed done; if the check cannot be made, hold; a refusal starts no worker, consumes no attempt, leaves the task where it is and records the reason through existing writers. Out of scope by that decision (so "it does not also solve trusted-copy or attempt-key" is NOT a finding): which copy of the instructions is trusted / how a withdrawal clears managed identity, and recovering a missing prior attempt key. It is partial progress and claims no OL-10 credit.
  **What IS a finding:** (1) a hold in the issue, the capture, or an unfinished dependency that can still reach a worker through the real `jog run` or `jog retry-build` path; (2) a wrong insertion point (check it against `utils/py/jog_run.py:2842–2910`, `:1111`, `utils/py/releases_app.py:5072–5130`): is it before the lease, before inbox promotion, before any execution record and native reservation? (3) an acceptance line that cannot be proven with the existing replay harness `TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt` or that would not be red on the unchanged head; (4) a regression for ready work or for existing callers (`test/jog-queue.sh`, `test/gh280-jog-marathon-adapter.sh`, vendored layout, `--simulate`, supervised/checkpoint modes); (5) the open-reference source for `after #N` being wrong or unbounded (`skills/1-hourly/kickstart/scripts/build_queue.py:89,182–201`).
  **Questions to answer with file:line:** Q1 Does the helper at jog_run.py:2875–2879 sit before everything it must precede, and does `jog_set_status` park a still-pending row without a lease and without touching `attempt_count`? Q2 Does the plan correctly state which `issue_hold_reason` forms are conditional on the open set and which are unconditional, and is the open-reference source (item 3) complete and fail-closed? Q3 Is the refusal path consistent with the existing promotion-failure branch under checkpoint/supervised modes (no stuck loop, no skipped task count)? Q4 Is each of the six acceptance rows provable and red-or-control as claimed, and are the per-refusal assertions measurable? Q5 Is the shared-caller analysis complete (who else reaches the touched lines, and is the `gh` shim consequence for gh280 sections G/H/I/K/N right)? Q6 Is loading `build_queue.py` by path from the harness root sound in root and vendored layouts? Q7 Is it surgical and DRY with no unwarranted machinery?
  Verdict PASS only if no blocker remains; this is the single authorized review, so grade everything now. Measure read-only per the reviewer note; do not run suites.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The insertion and hold semantics are sound at plan level, but the promised ready-work controls cannot pass with the specified fixture changes: both fixture installers omit the newly required recognizer. This is an observed artifact contradiction, not a claim that an implementation or suite was run. The single authorized review is exhausted; stop, no repair round or implementation.

swept file: yes

Reviewed the entire seeded file, grading only its settled holds-only section, `.relay-artifacts/GH-1476-RAW-TASK-PREPARATION.md:360–480`; earlier managed-admission text is superseded history. No additional in-scope pre-existing defects found beyond the findings below. No artifact/source edits, Git commands, suites, executable fixtures, or external-service probes were run.

- [Blocker] **B1 — Install the recognizer in the existing fixtures before claiming ready-work compatibility (Q4/Q5/Q6).**
  **Observed input:** Form 1 contradiction: the plan at `.relay-artifacts/GH-1476-RAW-TASK-PREPARATION.md:416–420` requires loading `skills/1-hourly/kickstart/scripts/build_queue.py` relative to the executing `jog_run.py`, holding if absent; at `:474–476` it specifies adding one `gh issue view` answer to restore the existing suite. However, `test/gh280-jog-marathon-adapter.sh:160–162` and `TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt:160–162` both install only `relay-automation bin src utils`. Their remote starts from an empty commit (`test/_setup.sh:85–93`), so cloning it supplies no missing `skills/`. The replay invokes the fixture's copied CLI (`control.txt:226`), and gh280's vendored run invokes its copied `.xyz/utils/py/releases_app.py` (`test/gh280-jog-marathon-adapter.sh:724`). Thus the proposed changed-head ready and dependency-done controls (`artifact:457–458`) encounter `hold-check-unavailable`, not their expected worker call. The production vendor manifest containing `skills` does not repair these hand-built fixture installers.
  **Affected scope:** The existing Day 1 replay and gh280 root/vendored fixtures executing the new helper; ready tasks as well as all intended hold cases. A zero-call hold case could otherwise pass for the missing-import reason and conceal a nonfunctional hold reader.
  **Fix:** Include the existing recognizer at its correct harness-relative path in both existing fixture installers, alongside the proposed shim change. Keep this within the existing fixture/replay edits; add no suite or gate. Make the hold cases assert the specific reason as well as the `hold:` prefix, and retain the ready/done exactly-one controls. Parameterize the replay's existing author-machine paths (`control.txt:12,14`) to the disposable clone used for the candidate/base comparison.
  **Falsifier:** In the disposable root and vendored fixtures, import the recognizer from the executing Jog module's harness root, then run the ready and closed-dependency controls: exactly one sentinel line each, no `hold-check-unavailable`. Run the hold fixtures: zero calls with their intended hold reasons. A fixture already supplying that exact module would falsify the missing-install finding; neither current installer does. Full execution remains **[Unverified — needs clone run]**.

- [Nit] **N1 — Correct the shared-caller inventory (Q5).** `artifact:469–472` names G/H/I/K/N as rows reaching the new check. Section M also invokes the real queue at `test/gh280-jog-marathon-adapter.sh:1136–1141`, specifically exercising inbox promotion. Section N's retry-build case is a live-lock refusal (`:1304–1312`); the lock is acquired at `utils/py/jog_run.py:1087–1090`, before the proposed helper at `:1111`, so N7 will not need the new issue answer. Fix the inventory to distinguish M's admission coverage from N's earlier lock refusal. Running the whole existing suite, as already planned, remains appropriate.

- [Pass] **Q1 — Correct placement and writer.** The loop check at `utils/py/jog_run.py:2875–2879` precedes lease acquisition, promotion at `:2891`, and execution creation at `:2910` → `:624–640`; retry-build's check before `:1111` precedes its lease and `:1112` dispatch. `utils/py/releases_app.py:5125–5127` updates status/reason/lease without assigning `attempt_count`; `:5128–5132` explicitly handles pending→parked, and `:5136–5137` uses the existing receipt writer. No live writer was invoked during this review.

- [Pass] **Q2 — Open references are bounded to the recognizer's conditional grammar.** `build_queue.py:185–196` makes the label, HELD, Blocked-by and active-after forms unconditional. Only `:197–200` depends on the supplied open set; it uses the same `AFTER` at `:89` that item 3 enumerates after sanitization (`:146–150`). Thus every conditional match gets one deduplicated lookup; failures/unknown states remain unresolved under the plan's positive done test (`artifact:409–415`). A line-start `depends on` needs no lookup to hold. The plain-sentence done fixture avoids the unconditional branch. The claimed live PR response was not independently queried here; dependency-state transport still needs the planned clone verification.

- [Pass] **Q3 — Refusal control flow matches promotion failure.** Park removes the row from the pending selector (`jog_run.py:2844–2848`); `break` when checkpointed and otherwise `continue` matches `:2894–2899`. Counting the refusal under checkpoint/supervised mirrors `:2881–2882` and preserves their `max_tasks` bound (`:2834–2836`). This avoids repeatedly selecting the same pending row. Ordinary mode's existing promotion-failure path likewise does not count the parked task as a completed task.

- [Unverified — needs clone run] **Q4 — Six acceptance rows are measurable, but not yet established.** The replay already reaches the worker edge (`control.txt:101–110,226–230`) and queries queue attempts/status. The proposed append-only sentinel, independent issue/capture cases, reference-aware shim, inbox placement, and before/after snapshots can measure the six rows and per-refusal assertions (`artifact:445–464`), once B1 is corrected. Query attempts/status in the primary DB, execution count in primary `.tick/jog/<gid>/state.json` (`jog_run.py:624–640`), and capture/native attempts in the execution target (`control.txt:213–226`). Treat an absent prior state file as zero executions, and snapshot both file names and bytes for unchanged native history. The current replay's `held` case sets both sources (`control.txt:189–191,204`), its `dependency` case is HELD prose (`:193–195,204`), and its sentinel overwrites (`:106`), so historical outputs alone prove none of the new independent cases or exactly-one assertions. The plan explicitly calls for those upgrades and for honest red/control classification; no later gate is assumed.

- [Pass] **Q5/Q6/Q7 — Remaining architecture is surgical.** The CLI routes are `releases_app.py:5223` and `:5252–5253` → `jog_run.py:1095–1119`; direct `jog_run.py:3034` reaches the same loop. Legacy relay shares that loop (`:2907–2910,2952–2985`), simulation is guarded there, and dry-run returns earlier (`:2727–2770`). The stated `gh` shim mismatch is real (`test/gh280-jog-marathon-adapter.sh:57–74`). Production root/vendored loading relative to `jog_run.py` is structurally sound: `build_queue.py:549–550` guards its CLI main, and `relay-automation/xyz-vendor.sh:451,480–484` ships `skills/`. B1 concerns the fixtures, not that production manifest. One helper with two entry-point calls and the existing status writer introduces no scheduler, database, attempt reset, or parallel hold grammar (`artifact:388–422`). Production vendored execution is not claimed as run.

Read-only probe (exit **0**; imports the main-guarded recognizer, performs only in-memory calls and source reads):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import importlib.util
from pathlib import Path
p=Path('skills/1-hourly/kickstart/scripts/build_queue.py')
s=importlib.util.spec_from_file_location('holds_probe',p)
m=importlib.util.module_from_spec(s); s.loader.exec_module(m)
for body in ['Blocked by #902','after #902','depends on #902','Proceed after #902 lands','Proceed after #902 is done.']:
    refs={int(x.group(1)) for x in m.AFTER.finditer(m._sanitize_body(body))}
    print(repr(body), 'done=',repr(m.issue_hold_reason({'body':body},set())),'open=',repr(m.issue_hold_reason({'body':body},refs)))
print('label:',m.issue_hold_reason({'labels':[{'name':'status:held'}]},set()))
for path in ['test/gh280-jog-marathon-adapter.sh','TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt']:
    print(path+': '+next(x.strip() for x in Path(path).read_text().splitlines() if 'for d in relay-automation' in x))
PY
```

Decisive output:

```text
'Blocked by #902' done= 'blocked by #902' open= 'blocked by #902'
'after #902' done= 'after #902' open= 'after #902'
'depends on #902' done= 'after #902' open= 'after #902'
'Proceed after #902 lands' done= 'after #902' open= 'after #902'
'Proceed after #902 is done.' done= None open= 'after #902'
label: label status:held
test/gh280-jog-marathon-adapter.sh: for d in relay-automation bin src utils; do
TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt: for d in relay-automation bin src utils; do
```

Evidence boundary: Verify-tier graph discovery used project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-25T18:19:12Z`. It indexes another checkout, not this relay worktree; caller tracing was denied by tool approval policy. All material citations were therefore checked against local source. Coverage flagged gh280 lines 729–730 and xyz-vendor line 304 (read locally), and the replay/seed as missing in that indexed checkout (read locally). No whole-repository graph completeness claim is made.

Handing off to Producer (claude-a) — report the escalated finding to the operator and stop under the one-review budget; no repair round or implementation is authorized here.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
