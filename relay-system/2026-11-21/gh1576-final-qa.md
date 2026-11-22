# RELAY · GH-1576 Final QA: refuse push from unwired clone
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-21.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1576-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1576-PREPUSH-HOOK-CHECK.md` (the plan) and the committed change
  `3dc703600..HEAD` (`git diff 3dc703600..HEAD`) on `fix/XYZ-forge-gh1576-prepush-hook-check-2026-11-21`:
  `skills/1-hourly/kickstart/scripts/run_record.py`, `utils/py/jog_run.py`, `utils/py/express.py`,
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, the skill text in
  `skills/1-hourly/start-task/SKILL.md`, `skills/1-hourly/kickstart/SKILL.md`,
  `skills/2-daily/express/SKILL.md`, fixture wiring in `test/gh280-jog-marathon-adapter.sh` and
  `test/gh436-merge-cleanup.py`, and the evidence in `TESTS-RESULTS/2026-11-21+GH-1576/`
  (`README.md`, `check.sh`, `red.log`, `green.log`, `provenance.jsonl`, `real-gate.log`,
  `focused-suites.log`).
- Plan (approved by Codex plan QA round 2): `PROJECT/2-WORKING/GH-1576-PREPUSH-HOOK-CHECK.md`;
  plan relay `relay-system/2026-11-21/gh1576-plan-qa.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-21
- Definition of Done: issue #1576 is satisfied (asks 1-3, red/green) by the smallest change that
  works; code paths match the approved plan; no second detector or writer slipped in; the evidence
  substantiates each claim. Issue #1576 asks: (1) clone provisioning runs `bash githooks/install.sh`;
  (2) immediately before every push by start-task and the lanes reusing its push step (kickstart,
  express, jog, merge-cleanup repairs), run `bash githooks/install.sh --check`, stop and do not push on
  failure, never fall back to `--no-verify`; (3) extend existing provisioning/push steps, no new
  subsystem, no new suite (GH-831).

Operational envelope: grade against the stated requirements, commensurate complexity and this
repo's own threat model (`githooks/install.sh` header: `--no-verify` and per-clone wiring are not
fixable client-side). XYZ-forge forbids new tests (AGENTS.md, GH-831): a new test file or registry
entry in the diff is a finding. This touches gate/hook surfaces: do not suggest deferring a finding.

**Step A — paraphrase first (GH-1414).** Before reading source or evidence, read only this Setup
section and the plan doc and write 2-5 sentences each under **What this proposes** and **How the
existing system works, per this document**, plus a short **What it's not**. Label inference.

**Step B — source-backed check.** Then read the diff and evidence. Answer:
1. Does each push site in the plan's table now run the check immediately before pushing, with
   the plan's applicability rule (missing installer refuses; only jog/express keep the existing
   vendored policy)? Cite `file:line`. Is any push site in the lane family still unguarded?
2. Does anything duplicate a subsystem or writer? (Three small direct `--check` calls plus
   express's existing `gate_check` were the approved shape.) Is `gate_unwired_reason(install=True)` in
   `prepare_landing_clone` the only new provisioning step, and is the `PUSH_GATE_TIMEOUT_S` change on the
   repair push correct?
3. Do `check.sh` / `provenance.jsonl` actually reject an unchanged, unfixed candidate (red rows push
   from unwired clones with the origin ref moving; green rows refuse with the ref unchanged)? Check
   the rows against the claims in `README.md` and its stated limits. Is the stub installer in the
   gh280 fixture and the module-level stub in gh436 acceptable, given the pushes there are mocked or
   fixture-only and the refusal is witnessed by the manual check?
4. Is `check.sh` under `TESTS-RESULTS/` a manual-check artifact or a new test/registry entry
   (GH-831)?
5. Rating `62/58/50/72` vs the evidence; anything over-built or missing.

Cite `file:line` for disagreements. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, and
set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

**What this proposes**

Make the listed lane pushes consume the existing installer check and refuse unwired clones.
Wire merge-cleanup's own landing clone when provisioning it, and preserve existing lane failure
conventions and Express/Jog vendored policy.

**How the existing system works, per this document**

Hooks live in clone metadata and do not travel with clones. The installer already detects missing
wiring; Express already checks its main landing path, while the other listed boundaries need to
consume that check. The plan identifies skill instructions as start-task's provisioning owner.

**What it's not**

No second hook detector, server control, wrapper, or new suite; ad-hoc human Git commands remain
outside scope. Inference: an executable recovery recipe shipped by the Express skill is part of
that lane's publication instructions, distinct from an arbitrary human push.

**Findings — changes required before approval**

- [Should] **F1 — Express's shipped recovery recipe still publishes from a fresh unwired clone.**
  `skills/2-daily/express/SKILL.md:131` explicitly starts recovery in a fresh full clone, but its
  publication command at `:147` goes straight from commit to `git push origin "$BASE"`.
  There is no install or check in that recovery block. `utils/py/express.py:531`–539 directs failed
  resume users to that recipe, so this is a lane-owned recovery path missed by the plan's Python
  push inventory. Extend the existing recipe with provisioning and an immediately preceding
  fail-closed check, retaining the documented vendored-host policy; align the emitted recovery
  guidance. No new helper/subsystem is needed.
  Observed input: the literal fresh-clone recipe at `skills/2-daily/express/SKILL.md:131`–147,
  ending `git add TESTS-RESULTS && git commit ... && git push origin "$BASE"`, with zero references
  to `githooks/install.sh` in the block. This is a source-observed omission, not a claimed live push.
  Affected scope: the Express recovery-receipt publication instructions, specifically canonical
  Forge clones with absent/invalid hook wiring; preserve Express's existing downstream policy.
  Falsifier: in a disposable Forge clone, the revised recipe's publication step with a failing
  installer check must stop before push and leave the origin ref unchanged; a wired clone must
  reach its hook. A positively identified vendored host must retain its documented host policy.

- [Should] **F2 — Finish the promised receipt-publication witness.**
  `TESTS-RESULTS/2026-11-21+GH-1576/check.sh:119`–131 calls `_require_gate_wired` directly;
  `:134`–149 separately drives `JogCheckpoint._push`. Neither drives `publish_jog_receipt`.
  The README correctly discloses this at `:48`–49, but deleting the new call at
  `utils/py/jog_run.py:1229` would leave every retained scenario unchanged. That is precisely the
  unfixed-boundary gap plan QA F3 required closing; its Round 2 explicitly says a cost-recorded,
  unexecuted witness remains unverified. Retain a manual base/candidate run through
  `publish_jog_receipt(..., push=True)` with its valid receipt bundle, unwired refusal and unchanged
  remote ref, plus wired publication. This asks for the approved evidence, not a new suite.
  Also retain the planned vendored-policy adjacent control: the current provenance has zero
  vendored scenarios, and gh280's stub installer is present in both fixture layouts
  (`test/gh280-jog-marathon-adapter.sh:166`–169), so that fixture does not witness the absent-installer
  vendored branch in `jog_run.py:1156`–1158.

- [Unverified — needs clone run] **F3 — No completed full-gate result is supplied for final QA.**
  `TESTS-RESULTS/2026-11-21+GH-1576/real-gate.log:2` records refusal at attempt admission,
  before the suite; `:4` even has an empty `rc=` field. README `:44`–45 assigns the full-gate pass
  to the task's future push. `focused-suites.log:1`–10 records focused outcomes only and does
  not bind their runs to a revision; the 30 provenance rows describe manual boundary scenarios,
  not those suite runs. Supply the existing required gate result from a disposable full clone,
  identify the tested code revision and pre/post clone identity, and retain its command, exit
  status and provenance together with revision-bound focused-suite receipts. Correct the blank
  real-hook rc from retained evidence or explicitly mark it unavailable. A later unconfigured
  gate or future push cannot satisfy this review. No gates or executable fixtures were run here.

- [Pass] **The named Python push boundaries have the intended guards and reuse the authority.**
  The guard/push pairs are `skills/1-hourly/kickstart/scripts/run_record.py:608`–609,
  `utils/py/jog_run.py:1229`–1230 and `:2341`–2342,
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1074`–1078 and `:1564`–1568,
  and `utils/py/express.py:1286`–1290. Express's pre-existing main-path check remains at `:1109`.
  The three small local helpers delegate to the clone's installer; they do not implement another
  stub detector or writer (`run_record.py:427`, `jog_run.py:1148`, `merge_cleanup.py:964`).
  Jog's exception is only on absent installer plus `is_vendored()`; Express retains its existing
  `gate_check` at `:551`. `prepare_landing_clone` is the new install=True call at
  `merge_cleanup.py:1009`, and the repair push now uses the existing 3600-second
  `PUSH_GATE_TIMEOUT_S` at `:1078`, preserving its attempt context and false/reason convention.
  Start-task provisioning and push instructions are present at
  `skills/1-hourly/start-task/SKILL.md:99`–102, `:292`, and `:336`.

- [Pass] **The retained five unwired boundary pairs discriminate the demonstrated defect.**
  `TESTS-RESULTS/2026-11-21+GH-1576/provenance.jsonl:1`, `:5`, `:7`, `:12`, `:14` record
  base pushes moving the origin ref without a hook; the matching candidate rows `:16`, `:20`,
  `:22`, `:27`, `:29` record refusal and unchanged refs. The evidence reader queries the local
  bare origin (`check.sh:25`, `:65`–67), not merely a publishing clone's tracking ref.
  The wired controls are wiring evidence with a disclosed bypass, not full-gate passes
  (README `:41`–47). A successful `check.sh` exit alone is not acceptance: it records outcomes
  rather than asserting expectations (`:29`–35, `:172`); these rows were inspected separately.

- [Pass] **The local reuse and fixture adaptations are proportionate.**
  The gh280 installer stub (`test/gh280-jog-marathon-adapter.sh:166`–169) and gh436 module stub
  (`test/gh436-merge-cleanup.py:40`–43) isolate existing fixture behavior; neither is evidence
  of refusal. The retained real-ref manual controls supply that evidence for their exercised
  boundaries. `check.sh:2` describes a retained manual witness, and its callers are the explicit
  commands in README `:15`–16; this shape does not require making it a registered suite.
  The plan's `62/58/50/72` rating remains a reasonable judgment for silent gate omission across
  several small call sites (`PROJECT/2-WORKING/GH-1576-PREPUSH-HOOK-CHECK.md`, Task rating).
  The numeric score is not a measured result. No additional mechanism is justified by these findings.

**Read-only probe receipts and scope**

With `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`, this exact data probe
exited 0 (no source execution or Git invocation):

```python
import json
from pathlib import Path
rows=[json.loads(s) for s in Path('TESTS-RESULTS/2026-11-21+GH-1576/provenance.jsonl').read_text().splitlines()]
assert len(rows)==30
for label in ('red','green'):
 r=[x for x in rows if x['label']==label and 'unwired' in x['scenario'] and x['origin_before']!='n/a']
 assert len(r)==5 and all(x['install_check_rc']=='1' and x['pre_push_invocations']=='0' for x in r)
 moved=sum(x['origin_before']!=x['origin_after'] for x in r)
 assert moved==(5 if label=='red' else 0)
 print(label, 'unwired boundaries=',len(r),'origin refs moved=',moved)
print('vendored scenario rows=',sum('vendor' in x['scenario'] for x in rows))
print('gate/suite provenance rows=',sum('gate' in x or 'command' in x for x in rows))
```

Command: `python3 - <<'PY'` with the body above and closing `PY`.
Decisive output: `red unwired boundaries= 5 origin refs moved= 5`;
`green unwired boundaries= 5 origin refs moved= 0`; `vendored scenario rows= 0`;
`gate/suite provenance rows= 0`.
Command: `rg -n 'publish_jog_receipt|_require_gate_wired' TESTS-RESULTS/2026-11-21+GH-1576/check.sh`;
exit 0; decisive output: line 119 is a comment and line 123 is
`g = getattr(jog_run, "_require_gate_wired", None)`.

Graph tools are unavailable, so no project/generation or coverage claim is made. This turn read the
whole plan and manual evidence script and inspected the lane push/recovery paths and surrounding
source, including pre-existing code. It did not complete an every-line sweep of all large modules
and fixture suites, and did not obtain the base-to-HEAD diff under the explicit no-Git constraint;
therefore this is not whole-file implementation signoff. F1 is a pre-existing recovery-path omission
in a touched skill; absence of other pre-existing defects is not established.

swept file: no
VERDICT: FAIL
Basis: The exercised new guards are supported by discriminating rows, but the shipped recovery
recipe remains unguarded, one changed publication boundary lacks its promised runtime witness,
and final gate evidence is outstanding. Whole-file/diff review also remains incomplete; no later
gate or future push is assumed.

Handing off to Producer (claude-a) — disposition F1–F3, complete the evidence, and return for review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
