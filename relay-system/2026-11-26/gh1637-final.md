# RELAY · GH-1637 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-26.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Manual relay: commit only the relay file** (`relay(gh1637-final): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1637-impl.patch** — the read-only path that
  `relay-drive.sh --artifact-file /var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T//gh1637-impl.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-26
- Definition of Done: issue #1637 (operator decision) as planned in `PROJECT/2-WORKING/GH-1637-REVIEW-CAP-CONSULT.md`
  (`## Acceptance`, `## Decisions on the issue's notes`, `## Verification`). The plan was QA'd for 4 rounds
  (`relay-system/2026-11-26/gh1637-plan.md`); its round-4 outcome was 0 open Blockers.
- Review packet: the seeded artifact is the implementation diff (`git diff origin/development...HEAD`, minus ledger,
  tarball, transcripts and receipts). Read the real files at this checkout, not only the patch:
  `utils/py/relay_drive.py` (`consult_adjudicate`, `adjudication_close_token`, `judge_terminal`, the cap check),
  `utils/py/relay_attest.py`, `utils/py/consult.py` (`CONSULT_PIN_SHA`), `utils/py/marathon_drive.py`,
  `utils/py/jog_run.py` (`_merge_reviewed_pr`), `relay-automation/marathon.sh`. Evidence:
  `TESTS-RESULTS/2026-11-26+GH-1637/` (manual_check.log 25/25, manual_check_marathon.log 9/9, README.md).
- Operational envelope: grade against the stated requirements, commensurate complexity and the repo's own threat
  model; a factory-efficiency change, not an enterprise subsystem. The repo forbids new tests (AGENTS.md, GH-831): a
  new test file or registry entry is a finding; the manual-check scripts are recorded evidence, not suites.
- Questions: (1) is each acceptance bullet satisfied and where is the observed rejection of an unchanged/unfixed
  candidate? (2) do the code paths match the plan, and did a duplicate subsystem or second attestation writer slip in?
  (3) can `Consult-Adjudicated` satisfy any consumer that needs `Approved` (express, jog merge, gate_receipt, PDDA)?
  (4) are the gate, token close and publication ordered as planned and recoverable? (5) do the checks substantiate
  the claims? Round budget: up to 4; classify findings [Blocker]/[Should]/[Nit]; give a verdict.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Round 1 · Reviewer · codex

VERDICT: FAIL

Basis: Malformed advisor answers can adjudicate a lane, and a REAL repair can receive extra turns after its review. Token recovery and published evidence also need correction.

swept file: no

Reviewed the seeded patch and traced the affected source paths through consultation, attestation, Marathon success and escalation, and publication and merge. The indexed Forge checkout was a separate checkout, so current-path conclusions use the seeded source. No full sweep of all changed modules or clone gate run in this turn.

- [Blocker] Require an actual final advisor verdict before allowing adjudication. Observed input: cases 2–4 in the read-only probe below all print `adjudicated`. The multiline scan in `utils/py/relay_drive.py:1038,1134–1148` treats a withdrawn verdict, a fenced example, and a valid verdict preceded by a malformed verdict as valid. This contradicts the final-line and malformed-answer rules in `PROJECT/2-WORKING/GH-1637-REVIEW-CAP-CONSULT.md:41–42`. Affected scope: a named `[ok]` answer containing one recognized token plus trailing prose, fenced quoting, or an additional invalid verdict line. Falsifier: cases 2–4 each hold as `consult-inconclusive`, while case 1 can adjudicate with a second valid NON-BLOCKING. Require exactly one unquoted verdict declaration, validate its token and placement as the last nonblank line, and record these negative controls through the existing manual check.
- [Blocker] End the REAL repair after the promised builder and reviewer turns. Observed input: consult at cap 9 without progress grants cap 11 but leaves hard cap 13 (`utils/py/relay_drive.py:1173–1177,1602–1611`). A repair reviewer who leaves Open and adds one `[x]` enables the ordinary extension at turn 11 (`:1580–1595`; probe prints `progress extension True`). Affected scope: a REAL consultation before the ordinary extension budget is exhausted, followed by a still-open review that records progress. Falsifier: the repaired reviewer records progress at the second cap, and the driver escalates after exactly the two repair turns with one consult. Disable ordinary extensions after spending the consult or set the repair ceiling to the new cap. S2c currently checks exit and consult count, which can pass after extra turns (`TESTS-RESULTS/2026-11-26+GH-1637/manual_check.sh:134–136`).
- [Should] Recover from a refused handoff release after the driver acquires the token. Observed input: the probe uses a builder handoff, successful claim, and first release refused while a later release could succeed. The close helper returns False with the token still claimed by builder. `utils/py/relay_drive.py:1053–1069` exits before cleanup, while `:1623–1628` only restores the transcript. Affected scope: NON-BLOCKING close or REAL reroute that must transfer ownership and gets a claim success followed by a release refusal. Falsifier: a one-time handoff release refusal leaves the original open handoff, prior STATUS and no attestation. Roll back the acquired claim on this path and report any failure to restore it. S7 covers a refused done verb (`manual_check.log:28–30` in the evidence directory).
- [Should] Carry resolvable advisor evidence through publication. Observed input: the phase archive is copied and committed in `utils/py/marathon_drive.py:2303–2327`, but the lane notes only list local paths (`:144–152,2748–2752`), the QA comment only mentions a transcript (`:1759–1772`), and the multi-phase PR body receives just phase IDs from the new temp file while still printing all phases as approved (`relay-automation/marathon.sh:690–706`). The archive is written in the harness root while the lane closeout may publish a foreign target repo. Affected scope: readers of any adjudicated PR or phase QA comment without access to the authoring clone, including mixed closeout with progress disabled. Falsifier: generated lane PR and QA comment both link to each published answer excerpt, and the mixed closeout preserves the completed count with adjudicated phases labelled and linked. Reuse a reference to the published consult block or publish the excerpts inline where no shared archive exists. Use the existing phase transcript/result for closeout; the ID-only sidecar misses the evidence and is left behind on the halt path (`marathon.sh:669–680,709`).
- [Should] Reconcile the checked acceptance matrix with the committed evidence. Observed input: acceptance line 48 says red pre-advance was exercised with Open STATUS/token and marks mixed closeout, cap 9 REAL, retry, and the Jog triple covered. The checked-in receipts show cap 3 and 2 REAL, focused-gate red, refusal of the adjudicated Jog record, and a simulated receipt write failure. The Marathon log ends with the acceptance recheck (lines 14–18), and the project verification section and evidence README explicitly say closeout and retry were unexercised (`GH-1637-REVIEW-CAP-CONSULT.md:78`, evidence `README.md:21–23`). Without a focused gate, the pre-advance failure follows token consumption (`utils/py/relay_drive.py:919–966`, `utils/py/marathon_drive.py:2787–2801`). Affected scope: the stated evidence for failure and recovery, distinction between Approved/Closed/adjudicated merges, and the mixed closeout. Falsifier: retained disposable-clone outputs record the actual state and reason in each promised case. Correct the red pre-advance expectation to match the selected ordering and attach the missing outputs and revision-bound `provenance.jsonl` required by AGENTS.md. The evidence directory in this checkout has no such file.

- [Pass] Default and isolation wiring match the accepted design in `relay-automation/marathon.sh:594–595`, `utils/py/marathon_drive.py:3093–3097,3547–3552`, `utils/py/relay_drive.py:1092–1099,1124–1129,1173–1178,1570–1576`, and `utils/py/consult.py:730–753`. The recorded dirty-tree check saw the pinned HEAD and no untracked overlay (`TESTS-RESULTS/2026-11-26+GH-1637/manual_check.log:39–41`).
- [Pass] The attestation uses the existing judge, transcript trailer and record writer (`utils/py/relay_drive.py:871–881,919–1023,1612–1616`, `utils/py/relay_attest.py:450–469`). With a focused gate, execution precedes close and publication. On the default path, the existing acceptance recheck precedes the pre-advance gate and PR. The recorded failing and fixed candidate pair is at `TESTS-RESULTS/2026-11-26+GH-1637/manual_check_marathon.log:14–16`.
- [Pass] Jog and Express keep the approval boundary (`utils/py/jog_run.py:2113–2119`, `utils/py/express.py:204–205`), and PDDA still only accepts Approved/Closed (`utils/pdda/check_marathon_qa.py:304–306`). The archived push qualification path deliberately accepts a valid terminal attestation bound to the candidate, including adjudication (`utils/py/gate_receipt.py:145–175`, `utils/py/relay_attest.py:31–32,450–454`).

Read-only command for the first three findings (exit 0). It evaluates the seeded logic with synthetic values and uses no repository subprocesses or executable fixtures.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PYPROBE'
import re
from pathlib import Path
from textwrap import dedent
from types import SimpleNamespace
src = Path('utils/py/relay_drive.py').read_text().splitlines()
read = lambda a, b: dedent('\n'.join(src[a-1:b]))
env = {'re': re}
exec(read(1038, 1038), env)
cases = ['Reason\nADJUDICATION: NON-BLOCKING', 'ADJUDICATION: NON-BLOCKING\nI withdraw that decision.', '```\nADJUDICATION: NON-BLOCKING\n```', 'ADJUDICATION: UNKNOWN\nADJUDICATION: NON-BLOCKING']
for i, text in enumerate(cases, 1):
    found = env['ADJ_TOKEN_RE'].findall(text)
    env['verdicts'] = {'codex': found[0] if len(found) == 1 else None, 'agy': 'NON-BLOCKING'}
    exec(read(1144, 1148), env)
    print(i, env['outcome'])
env = dict(args=SimpleNamespace(round_cap=9), hard_cap=11, round_idx=11, made_progress=True, consult_used=True)
exec(read(1609, 1610), env)
print('post-REAL cap/hard cap', env['args'].round_cap, env['hard_cap'])
print('progress extension', eval(read(1586, 1586)[3:-1], env))
state, verbs = ['open', 'builder'], []
def tick(verb, *args):
    verbs.append(verb)
    if verb == 'claim':
        state[0] = 'claimed'
        return True
    if len(verbs) == 2:
        return False
    state[0] = 'open'
    return True
env = dict(token_state=lambda: tuple(state), tick_ok=tick, args=SimpleNamespace(reviewer='reviewer', relay_task='token'), relay_file='RELAY.md')
exec(read(1046, 1070), env)
print('close refused', env['adjudication_close_token'](), 'verbs', verbs, 'token', state)
PYPROBE
```

```text
1 adjudicated
2 adjudicated
3 adjudicated
4 adjudicated
post-REAL cap/hard cap 11 13
progress extension True
close refused False verbs ['claim', 'release'] token ['claimed', 'builder']
```

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
