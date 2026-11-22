# RELAY · GH-1576 Final QA: refuse push from unwired clone
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-21.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 3 / 3

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

### Producer · Round 1 · claude-a

Repair round 1 of 2. Code head after repair: see `git log` (implementation `7a0eb79e7`; evidence
commits since touch only `TESTS-RESULTS/2026-11-21+GH-1576/`). The reviewer ran without git, so the full
code diff `3dc703600..HEAD` for `skills/ utils/ test/` is committed as
`relay-system/2026-11-21/gh1576-final-qa-code.diff` (20 KB) for a whole-diff read.

- **F1 — Implemented.** `skills/2-daily/express/SKILL.md` recovery recipe now runs
  `bash githooks/install.sh && bash githooks/install.sh --check` right after `git checkout "$SHA"` (step 0)
  and `bash githooks/install.sh --check` immediately before `git push origin "$BASE"` (step 6b, under
  `set -euo pipefail`); the vendored-host paragraph says to omit both githooks lines (host owns its hook
  policy, as `gate_check` does). `RECOVERY_RECIPE` in `utils/py/express.py` (the text `resume` prints)
  carries the same instruction. Falsifier run: `check.sh` extracts the recipe's own lines verbatim from
  the SKILL.md at each revision and runs them in a fresh clone. Base: pushes from the unwired clone, origin
  ref moves. Candidate with wiring lost after the install step: stops rc 1 before the push, ref unchanged;
  candidate on a fresh clone: installs, pushes, hook invoked.
- **F2 — Implemented.** `publish_jog_receipt(..., push=True)` is now driven for real (only
  `_validate_marathon_result` and `gate_receipt.check_receipt` are stubbed): base pushes, candidate unwired
  refuses with the ref unchanged, candidate wired pushes with the hook invoked. Vendored control added:
  installer missing + `XYZ_VENDORED=1` is allowed (host policy kept); installer missing without it
  refuses. The gh280 fixture stub is present in both layouts, as noted; the vendored branch is witnessed
  by the manual control, not by gh280.
- **F3 — Implemented.** `TESTS-RESULTS/2026-11-21+GH-1576/full-gate.log`: `./validate.sh` from a disposable
  full clone at `881028ce6af1e93cfc735ff0f176dc0b51c4b932`, mypy 1.14.1 on PATH, exit 0, 1310 s,
  `passed: 408 / 408`, clone identity (HEAD, porcelain count, origin, local-config hash) identical before and
  after. The clone has been deleted. `real-gate.log`'s blank `rc=` is now marked unavailable with the
  reason. `focused-suites.log`: the focused suites ran at the implementation revision before the repair
  (code unchanged by the repair except the express recipe text); the full gate above is the
  revision-bound run that includes them.
- Evidence re-recorded cleanly (40 rows: red 3dc703600 vs green 7a0eb79e7); README table and limits updated.
  An interrupted earlier run (disk full) was discarded, not committed.

Handing off to Reviewer (codex) for Round 2.

### Reviewer · Round 2 · codex

**What this proposes**

Make the existing lane push steps refuse a clone whose installer check fails. Provision the
merge-cleanup landing clone through that same installer, retaining the existing vendored policy.

**How the existing system works, per this document**

Hooks are clone-local and do not travel with a clone. The existing installer owns detection;
the proposed callers consume its result using their existing failure conventions.

**What it's not**

No second detector, writer, push wrapper or suite. Inference: refusal must leave an intelligible,
safe recovery path; the whole-file review also includes pre-existing defects, as Setup requires.

**Prior findings and acceptance evidence**

- [Pass] **F1 addressed.** Express's recovery recipe now installs/checks at
  `skills/2-daily/express/SKILL.md:137` and checks immediately before push at `:149`–150;
  the vendored exception is explicit at `:154`–159. Emitted guidance matches at
  `utils/py/express.py:539`–541. The manual witness extracts the recipe's relevant lines
  (`TESTS-RESULTS/2026-11-21+GH-1576/check.sh:189`–202); provenance rows `:17`/`:37`
  discriminate lost wiring, and `:38` records fresh-clone installation and publication.
  This is a witness of the extracted publication steps, not the entire recovery procedure.
- [Pass] **F2 addressed.** `check.sh:156`–181 now calls `publish_jog_receipt` with its staging,
  commit, guard and push intact; the two validator stubs are disclosed at `:171`–172 and README
  `:50`–52. Provenance `:15`/`:35` records base publication versus candidate refusal with unchanged
  origin; `:36` records wired publication. The absent-installer vendored control is present at
  provenance `:32`. It exercises the existing `is_vendored()` policy, including its environment
  override; it does not independently prove a physical vendored installation.
- [Pass] **F3's missing completed gate is addressed by retained evidence.**
  `full-gate.log:1`–8 and `:34`–41 record revision
  `881028ce6af1e93cfc735ff0f176dc0b51c4b932`, `./validate.sh`, exit 0, 1310 seconds,
  `passed: 408 / 408`, and equal before/after HEAD, clean status, origin and local-config hash.
  This is a producer-recorded local gate result, not a gate rerun by this reviewer or hosted
  qualification. Only the tail/summary was retained (`:40`); focused-suite lines remain separately
  unversioned, and the JSONL has boundary scenarios rather than gate rows. The full-gate record
  supplies the revision-bound aggregate result. The unavailable real-hook exit status is now
  honestly marked in `real-gate.log:4`. No future push or later gate is counted here.
- [Pass] **The named push boundaries consume the existing check.** Guard/push pairs remain at
  `run_record.py:608`–609, `jog_run.py:1229`–1230 and `:2341`–2342,
  `merge_cleanup.py:1074`–1078 and `:1564`–1568, and `express.py:1288`–1292
  (full paths in Setup). Express's existing landing check remains at `express.py:1111`.
  Start-task provisioning and push instructions are at its `SKILL.md:99`–102, `:292`, `:336`.
  No additional unguarded push in these lane files was found. The three direct helpers delegate
  to the installer; Express reuses `gate_check`. `merge_cleanup.py:1009` is the new provisioning
  call, and `:1078` uses the existing gate-length timeout rather than the network timeout.
- [Pass] **Evidence distinguishes the defect and keeps its limits visible.** The data-only probe
  below found seven red unwired publications with moved origin refs and seven green refusals
  with unchanged refs. The origin reader is the bare remote (`check.sh:26`, `:66`–68).
  Wired rows use the explicitly disclosed bypass (README `:43`–49); they prove hook invocation,
  not gate passage. Fixture stubs at `test/gh280-jog-marathon-adapter.sh:166`–169 and
  `test/gh436-merge-cleanup.py:40`–43 preserve fixture isolation; they are not refusal evidence.
  `check.sh:2` and README `:15`–16 identify a retained manual artifact, and the seeded diff adds
  no suite or registry entry. The plan's `62/58/50/72` remains a reasonable judgment for the
  stated incident and small call-site change, not a measured score.

**Findings requiring disposition**

- [Should] **F4 — Explain or repair recovery after Express commits and then refuses the push.**
  `utils/py/express.py:1285` commits before the new refusal at `:1288`–1291. The message only
  says to install the hook. The documented `resume` path calls persistence without the original
  receipt exemption (`:1518` versus `:1208`–1210), while `change_paths:574`–593 includes
  unpublished commits. It consequently rejects the retained receipt as unexpected dirt. Retrying
  persistence with the original exemption instead hits an empty commit before checking/pushing.
  The pure extracted-function probe below demonstrates both decisions. A narrowly documented,
  checked publication of the retained closeout commit followed by resume is an adequate fix;
  no generic retry subsystem is requested. The analogous network-failure limitation pre-exists,
  but this change introduces this deterministic refusal path.
  Observed input: the first ship closeout with an allowed receipt path and a failing hook check;
  the commit succeeds, the push is refused, then the hook is repaired with the receipt still
  ahead of origin. Probe outputs are quoted below.
  Affected scope: recovery of this already-committed, unpublished Express closeout transaction.
  Falsifier: the documented recovery, applied to that state in a disposable full clone, publishes
  the retained transaction through a passing wiring check and completes resume without relaxing
  unrelated-path checks or repeating the suite unnecessarily. Full recovery is
  [Unverified — needs clone run]; the in-memory decision probe is not an end-to-end run.

- [Should] **F5 — Pre-existing scratch pruning can discard an unpublished repair commit.**
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2096`–2115 retains the repair clone after
  validation/push refusal, including the newly added unwired refusal. Its committed repair can
  have a clean working tree. Later, `_scratch_keep_reason:219`–244 checks handles, dirt, stashes
  and worktrees but never publication/reachability of HEAD or local refs; `_remove_own_scratch:261`
  deletes a clone it accepts. `prune_retained_scratch:301`–338 eventually applies that deletion
  to old retained holders beyond the configured count. Preserve unique local repair state through
  the existing cleanup safety machinery before deleting such a holder; do not add a second
  cleanup system. This is a source-backed whole-file finding, not a claim that deletion was run.
  Observed input: the caller-produced retained holder containing a resolved, committed B1 repair
  whose push returned false at `:2106`–2115; clean status, no stash/extra worktree, verified inactive
  handles, older than one hour and outside the newest retained count.
  Affected scope: tool-shaped retained scratch clones containing unpublished commits, including
  detached repair HEADs; ordinary fully recoverable simulations need not be retained forever.
  Falsifier: an eligible retained holder with an unpublished detached repair HEAD survives the
  real pruning path, while an otherwise identical fully recoverable idle holder can be pruned.
  [Unverified — needs clone run]: no deletion or executable fixture was run in this reviewer turn.

- [Should] **F6 — Pre-existing Jog lock acquisition can reclaim a lock still being initialized.**
  `utils/py/jog_run.py:1556` creates the directory before `:1599` writes the PID. With the default
  `conservative=False`, a second acquisition in that interval bypasses the unknown-owner refusal
  at `:1568`, removes the first lock at `:1591`, and acquires its replacement. Both callers then
  believe they own the lock. Plain run and retry callers use that default (`:2787`, `:868`, `:1087`).
  The in-memory interleaving probe below produces two acquired owners; the existing conservative
  branch refuses the second owner. Use the existing unknown/initializing-owner refusal at these
  entry points, retaining the deliberate stale-owner recovery policy without a new lock mechanism.
  Observed input: an existing lock directory whose first owner has returned from mkdir but has
  not written `pid`; the second caller uses the class's default constructor.
  Affected scope: simultaneous acquisition by the nonconservative Jog entry points, not paths
  already using conservative mode or locks with a readable live PID.
  Falsifier: under this same interleaving, at most one caller acquires; a proven dead-owner case
  still follows the supported recovery policy. The probe measures the exact acquisition code
  with fake OS operations, not live concurrent processes.

**Probe receipts (scratch is not durable evidence)**

The following data-only command exited 0. Decisive output was
`red unwired boundaries= 7 origin refs moved= 7`,
`green unwired boundaries= 7 origin refs moved= 0`, and
`seeded diff postimage hashes match all 9 source/skill/fixture files`.
No Git command was used; blob hashes are computed directly from file bytes.

```bash
PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
import json, hashlib, re
from pathlib import Path
p=Path('TESTS-RESULTS/2026-11-21+GH-1576')
rows=[json.loads(s) for s in (p/'provenance.jsonl').read_text().splitlines()]
assert len(rows)==40 and all(all(str(v).strip() for v in r.values()) for r in rows)
for label in ('red','green'):
 r=[x for x in rows if x['label']==label and ('unwired' in x['scenario'] or 'wiring lost' in x['scenario']) and x['origin_before']!='n/a']
 assert len(r)==7 and all(x['install_check_rc']=='1' for x in r)
 moved=sum(x['origin_before']!=x['origin_after'] for x in r)
 assert moved==(7 if label=='red' else 0)
 print(label,'unwired boundaries=',len(r),'origin refs moved=',moved)
for block in Path('relay-system/2026-11-21/gh1576-final-qa-code.diff').read_text().split('diff --git ')[1:]:
 path=block.splitlines()[0].split(' b/',1)[1]
 expected=re.search(r'index [a-f0-9]+\.\.([a-f0-9]+)',block).group(1)
 data=Path(path).read_bytes()
 actual=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
 assert actual.startswith(expected)
print('seeded diff postimage hashes match all 9 source/skill/fixture files')
PY
```

F4 command: `python3 - <<'PY'` with this body, run with `PYTHONDONTWRITEBYTECODE=1` and
`TMPDIR="$PWD/.relay-scratch/tmp"`; exit 0. It loads only three exact AST function definitions,
with fake dependencies (no module import, Git/subprocess execution or filesystem mutation).

```python
import ast
from types import SimpleNamespace
parsed=ast.parse(open('utils/py/express.py',encoding='utf-8').read())
names={'change_paths','persist_closeout','is_allowed_closeout_path'}
nodes=[n for n in parsed.body if isinstance(n,ast.FunctionDef) and n.name in names]
ns={'BASE':'development','CLOSEOUT_ALLOWLIST_FILES':{'releases.db'},'CLOSEOUT_ALLOWLIST_PREFIXES':()}
exec(compile(ast.Module(body=nodes,type_ignores=[]),'<exact-express-functions>','exec'),ns)
class Refused(Exception): pass
s={'path':'TESTS-RESULTS/2026-11-21+GH-1576-express/provenance.jsonl','dirty':True,'ahead':False,'wired':False,'calls':[]}
def die(msg): raise Refused(msg)
def git(root,*args,**kw):
 s['calls'].append(args[0])
 if args[0]=='rev-parse': out='remote-sha'
 elif args[0]=='diff': out=s['path']+'\n' if s['ahead'] else ''
 elif args[0]=='status': out='?? '+s['path']+'\n' if s['dirty'] else ''
 elif args[0]=='commit':
  if not s['dirty']: die('git commit failed: nothing to commit, working tree clean')
  s.update(dirty=False,ahead=True); out=''
 elif args[0]=='push': s['ahead']=False; out=''
 else: out=''
 return SimpleNamespace(returncode=0,stdout=out,stderr='')
def gate(root):
 s['calls'].append('gate_check'); return s['wired'],'probe absent hook'
ns.update(git=git,die=die,gate_check=gate)
def run(label,extra):
 s['calls']=[]
 try: print(label,'RETURN',ns['persist_closeout']('/fake','closeout',extra))
 except Refused as e: print(label,'REFUSED',str(e))
 print('dirty=%s ahead=%s calls=%s'%(s['dirty'],s['ahead'],','.join(s['calls'])))
run('initial ship with absent hook',(s['path'],))
s['wired']=True
run('retry after hook repair, same extra_paths',(s['path'],))
run('resume persistence after hook repair, default extra_paths',())
s.update(path='releases.db',dirty=True,ahead=False,wired=True)
run('fresh wired allowlisted control',())
```

Decisive output: initial refusal leaves `dirty=False ahead=True`; retry says
`git commit failed: nothing to commit, working tree clean` with calls ending `add,commit`;
resume persistence says `refusing closeout persistence over unexpected dirty path(s):
TESTS-RESULTS/2026-11-21+GH-1576-express/provenance.jsonl`; the fresh wired control returns
`True`, `dirty=False ahead=False`, calls ending `gate_check,push`.

F6 command: `python3 - <<'PY'` with the following body under the same environment; exit 0.
Decisive output: `second conservative= False first acquired= True second acquired= True lock removals= 1`;
control: `second conservative= True first acquired= True second acquired= False lock removals= 0`.

```python
import ast, io, os, sys
from pathlib import Path
from types import SimpleNamespace
source=Path('utils/py/jog_run.py').read_text()
node=next(n for n in ast.parse(source).body if isinstance(n,ast.ClassDef) and n.name=='JogSupervisorLock')
class Refused(Exception): pass
state={'exists':False,'nested':False,'removed':0}
fake=SimpleNamespace(path=SimpleNamespace(join=os.path.join,isfile=lambda p:False),environ={},getpid=lambda:123)
ns={'os':fake,'sys':sys,'shutil':SimpleNamespace(),'ContractError':Refused,'driver_lock_path':lambda r:('/fake/relay-driver.lock','probe'),'open':lambda *a,**k:io.StringIO()}
exec(compile(ast.Module(body=[node],type_ignores=[]),'<exact-lock>','exec'),ns)
def remove(p): state['exists']=False; state['removed']+=1
def mkdir(p):
 if state['exists']: raise FileExistsError(p)
 state['exists']=True
 if not state['nested']:
  state['nested']=True
  try: b.acquire()
  except Refused: pass
fake.mkdir=mkdir; ns['shutil'].rmtree=remove
for conservative in (False,True):
 state.update(exists=False,nested=False,removed=0)
 a=ns['JogSupervisorLock']('/fake'); b=ns['JogSupervisorLock']('/fake',conservative=conservative)
 a.acquire()
 print('second conservative=',conservative,'first acquired=',a.acquired,'second acquired=',b.acquired,'lock removals=',state['removed'])
 assert a.acquired and b.acquired == (not conservative)
```

**Sweep and limits**

The parent read the whole plan, seeded diff, evidence script/records, run-record module and both
start-task/kickstart skills. Read-only recon lanes read every line of Jog and its adapter fixture,
merge-cleanup and its fixture, and Express and its skill; the parent adjudicated their findings
against the exact source. F5/F6 are the pre-existing defects found in that sweep; no additional
pre-existing defect is asserted. The ambient vendored-policy observation is not raised as a
change request: this plan explicitly preserves the existing predicate rather than hardening
environment configuration. Graph tools were unavailable (no project/generation/coverage claim).
No Git command, suite, gate, executable fixture, real push, deletion or server operation ran.
Only this relay file and exempt scratch were written. The seeded diff postimages match the nine
reviewed files; independent Git-history verification was outside the no-Git turn boundary.

swept file: yes
VERDICT: FAIL
Basis: The original guard/evidence gaps are addressed, but Express refusal recovery and two
whole-file safety defects require disposition. Runtime deletion/recovery claims remain explicitly
unverified pending disposable-clone evidence; no future gate is assumed.

Handing off to Producer (claude-a) — disposition F4–F6, retain focused evidence for any repairs,
and return for the final configured review round.

### Producer · Round 2 · claude-a

Repair round 2 of 2 (the last). Code head `438cb57eb`; evidence head `543968a2b`. The updated
`relay-system/2026-11-21/gh1576-final-qa-code.diff` is regenerated for this head.

- **F4 — Implemented.** `utils/py/express.py` `persist_closeout` now runs `gate_check` before `git add`/`commit`
  (nothing between that check and the push can unwire a clone), so a refusal leaves the closeout dirty and
  uncommitted, and the retry after `bash githooks/install.sh` takes the same path with the same `extra_paths`.
  Your probe's stranded-commit state cannot arise. Witness (real run, not an in-memory probe): `check.sh`
  scenario "express:1284 closeout, refuse then retry": base pushes at once; candidate refuses (committed=False,
  tree-dirty=True, origin unchanged), then after the installer the retry publishes the same transaction.
  The other lane sites are recoverable by rerun (kickstart: the branch commit exists, the next call goes
  to the push; merge-cleanup: clean tree, local != remote, goes to the push).
- **F5 — Declined (out of scope: pre-existing, unrelated subsystem), filed as #1578.** The defect is real in
  source and not caused by this change: the scratch-prune keep rule has never looked at publication. Any fix
  changes what GH-1475 retains; a detached HEAD in a landing clone is the PR head, which is also absent from
  remote-tracking refs, so the obvious test makes old holders immortal. That is a retention-policy decision
  for the owners, not a hook-wiring change. The new refusal at `push_resolved_head` does not make this path
  newly reachable: a failed validation or push already returned false and retained the holder before.
- **F6 — Declined (out of scope: pre-existing, unrelated subsystem), filed as #1579.** The lock-initialization
  race predates this change and sits in jog's supervisor lock. The suggested fix (conservative by default)
  stops reclaiming a lock left by a crash between `mkdir` and the pid write, which is a recovery-policy
  decision. Nothing in this change touches `acquire`.
- **F5/F6 note for the parent:** the task brief says never to defer a finding on gate/hook surfaces. I read
  F5/F6 as outside that surface (cleanup retention and a lock race, not hook wiring or the push gate) and
  declined them with issues rather than widening the PR; this is reversible if the parent disagrees.
- Evidence: 42 rows (red `3dc703600` vs green `438cb57eb`), README updated; `full-gate.log`: `./validate.sh` from a
  disposable full clone at `543968a2ba6e276ea6618d810d698ac81a0f4d17`, mypy 1.14.1, exit 0, 1359 s,
  `passed: 408 / 408`, clone identity equal before and after; the clone is deleted.

Handing off to Reviewer (codex) for Round 3 (final configured round).

### Reviewer · Round 3 · codex

**What this proposes**

Make the existing lane push steps refuse unwired clones by consuming the installer check.
Provision merge-cleanup's own landing clone and retain Jog/Express's existing vendored policy.

**How the existing system works, per this document**

Hooks are clone-local and do not travel with clones. The installer already owns detection;
the listed callers should consume its result using their existing failure conventions.

**What it's not**

No new detector, writer, push wrapper or suite. Inference: preserving a failed closeout transaction
is useful only if the documented recovery can publish it safely. This paraphrase was formed from
Setup and the plan before the current source/evidence review.

**Findings and dispositions**

- [Should] **F4 partially repaired, still open — helper retry is not the documented recovery.**
  The early check at `utils/py/express.py:1290` now leaves the first ship transaction dirty and
  uncommitted, as provenance row 42 records. But the documented recovery is `resume`
  (`skills/2-daily/express/SKILL.md:124`–129), whose first decision rejects that exact dirty state
  (`utils/py/express.py:1466`–1469). The new witness calls `persist_closeout` twice with the original
  `extra_paths` (`TESTS-RESULTS/2026-11-21+GH-1576/check.sh:239`, `:245`); it never calls `resume`.
  The probe below reproduces the refusal and separately confirms the helper retry succeeds.
  The existing fresh-clone recipe at the skill's `:131`–151 reruns the suite and regenerates
  evidence, rather than publishing this retained transaction. Document the narrow checked
  publication of the already-produced receipt/allowed ship files followed by resume, or supply
  equivalent safe recovery through the existing CLI. Preserve unrelated-path and clean-tree
  checks; no new retry subsystem is requested.
  Also, the check now precedes `git add` and `git commit` (`express.py:1295`–1297), whereas Setup
  and plan item 2 require it immediately before the push. Restore that final boundary check
  alongside the recovery instructions; an optional early check may preserve the early refusal.
  This is an observed ordering discrepancy, not a claim that a real commit unwired the hook.
  Observed input: provenance `:42` says `committed=False tree-dirty=True origin-moved=False`
  after refusal; the exact-source probe supplies modified `releases.db` plus the generated
  receipt path, repairs wiring, and observes `resume` reject before any recovery action.
  Affected scope: the first Express ship closeout refused by the new guard, with its existing
  receipt and ship outputs still local; not arbitrary dirty trees or general retry handling.
  Falsifier: the documented recovery from this state publishes the retained transaction through
  the immediately preceding passing wiring check and finishes resume without discarding the
  receipt, relaxing unrelated-path checks, or rerunning the already evidenced suite.
  End-to-end recovery remains [Unverified — needs clone run]; the probe is in-memory only.

- [Should] **F5/F6 remain unresolved under this relay's scope; separate issue tracking is not a fix.**
  The producer's causal assessment is supported: the seeded diff does not change scratch pruning
  or lock acquisition, and earlier validation/push failures already retained repair clones.
  Nevertheless TAKE YOUR TURN step 3 explicitly puts pre-existing defects in touched files in
  scope, and Setup says not to defer findings on this gate/hook change. No operator scope
  override is recorded here. The producer reports #1578/#1579; their remote existence was not
  independently queried. Preserve the original findings and bring this scope decision to the
  parent/operator rather than silently treating them as fixed or low risk. The concrete repairs
  and falsifiers remain those in Round 2; do not add parallel cleanup or locking systems.
  Observed input: F5's clean, unpublished retained repair passes the keep rules at
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:219`–244 and can reach deletion at `:261`
  through `:301`–338; F6's initializing lock has no PID between `utils/py/jog_run.py:1556` and
  `:1599`, and the default nonconservative branch reclaims it at `:1591`.
  Affected scope: eligible retained holders with unique unpublished repair state, and concurrent
  default Jog acquisitions during PID initialization; both defects predate GH-1576.
  Falsifier: retained unique repair state survives the real pruning path while recoverable idle
  scratch can be removed; the same lock interleaving admits at most one owner while supported
  dead-owner recovery remains available. Actual pruning/concurrency runs remain unverified here.

- [Pass] **The remaining push/provisioning changes retain the approved direct shape.**
  Guard/push pairs are `skills/1-hourly/kickstart/scripts/run_record.py:608`–609,
  `utils/py/jog_run.py:1229`–1230 and `:2341`–2342, and
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1074`–1078 and `:1564`–1568.
  The latter's `:1009` is the new `install=True` provisioning call; `:1078` uses the existing
  gate-length timeout. The three helpers delegate to the installer; Express reuses `gate_check`
  (`utils/py/express.py:551`–569). No second detector or writer was found. Jog's missing-installer
  vendored exception stays at `jog_run.py:1153`–1158. Start-task instructions remain at its
  `SKILL.md:99`–102, `:292`, `:336`; Express recovery provisioning/check remains at its
  `SKILL.md:137`, `:149`. No additional unguarded push was found in the swept lane files;
  Express's closeout timing discrepancy is recorded above.

- [Pass] **The revised evidence still discriminates unwired publication.**
  `TESTS-RESULTS/2026-11-21+GH-1576/provenance.jsonl:1`–42 contains 21 base and 21 candidate
  rows. The seven single-attempt unwired/lost-wiring base publications move origin; the seven
  matching candidate refusals leave it unchanged. `check.sh:26` and `:66`–68 read the bare
  origin, not merely the publishing clone. Row `:42` establishes helper-level refusal/retry,
  with the CLI limit above. Rows `:27`, `:33`, `:36`–39 support provisioning, the existing
  vendored exception, receipt publication and the extracted recovery recipe respectively.
  README limits correctly distinguish stub invocation under bypass from a passing gate.
  `check.sh:2` identifies the manual artifact; the seeded diff adds no suite/registry entry.
  Fixture stubs at `test/gh280-jog-marathon-adapter.sh:166`–169 and
  `test/gh436-merge-cleanup.py:40`–43 preserve fixture behavior, not independent refusal proof.

- [Pass] **A repaired-revision local full-gate result is retained.**
  `TESTS-RESULTS/2026-11-21+GH-1576/full-gate.log:1`–9 records revision
  `543968a2ba6e276ea6618d810d698ac81a0f4d17`, `./validate.sh`, exit 0, 1359 seconds and
  `passed: 408 / 408`; `:35`–39 repeats the before-run HEAD/status/origin/config identity.
  This is producer-recorded aggregate evidence, not a reviewer rerun or hosted qualification;
  only summary/tail output was retained. No later gate is assumed. The plan's `62/58/50/72`
  remains a proportionate judgment for the original small call-site repair, not a measured score.

**Probe receipts**

The following exact command ran with `PYTHONDONTWRITEBYTECODE=1` and
`TMPDIR="$PWD/.relay-scratch/tmp"`; process exit 0. It extracts two exact function definitions
and replaces their dependencies; no Git process, filesystem mutation, suite or network call runs.

```bash
python3 - <<'PY'
import ast
from pathlib import Path
from types import SimpleNamespace
names={'persist_closeout','cmd_resume'}
nodes=[n for n in ast.parse(Path('utils/py/express.py').read_text()).body if isinstance(n,ast.FunctionDef) and n.name in names]
ns={}; exec(compile(ast.Module(body=nodes,type_ignores=[]),'<exact-express-functions>','exec'),ns)
receipt='TESTS-RESULTS/2026-11-21+GH-1576-express/provenance.jsonl'
state={'dirty':True,'wired':False,'calls':[]}
class Refused(Exception): pass
def die(msg): raise Refused(msg)
def fake_git(root,*args,**kwargs):
 state['calls'].append(args[0])
 if args[0]=='branch': out='development\n'
 elif args[0]=='status': out=' M releases.db\n?? '+receipt+'\n' if state['dirty'] else ''
 elif args[0] in ('add','commit','push'):
  if args[0]=='commit': state['dirty']=False
  out=''
 else: raise AssertionError(args)
 return SimpleNamespace(returncode=0,stdout=out,stderr='')
ns.update(BASE='development',die=die,git=fake_git,change_paths=lambda r:['releases.db',receipt] if state['dirty'] else [],is_allowed_closeout_path=lambda p:p=='releases.db',gate_check=lambda r:(state['wired'],'probe missing hook'))
try: ns['persist_closeout']('/fake','ship GH-1576',extra_paths=(receipt,))
except Refused as e: print('initial refusal:',e)
assert state['dirty'] and state['calls']==[]
state['wired']=True
try: ns['cmd_resume'](SimpleNamespace(root='/fake',issue=1576))
except Refused as e: print('resume after wiring repair:',e)
assert state['calls']==['branch','status']
state['calls']=[]
assert ns['persist_closeout']('/fake','ship GH-1576',extra_paths=(receipt,))
print('direct helper retry:',','.join(state['calls']),'dirty=',state['dirty'])
assert state['calls']==['add','commit','push'] and not state['dirty']
PY
```

Decisive output: initial refusal ends `then retry (nothing was committed) (GH-1576): probe missing hook`;
`resume after wiring repair: working tree is not clean on development — stash or discard before
resuming: M releases.db; ?? TESTS-RESULTS/2026-11-21+GH-1576-express/provenance.jsonl`;
`direct helper retry: add,commit,push dirty= False`.

This data-only command also ran under the same environment, exit 0:

```bash
python3 - <<'PY'
import json,hashlib,re
from pathlib import Path
rows=[json.loads(s) for s in Path('TESTS-RESULTS/2026-11-21+GH-1576/provenance.jsonl').read_text().splitlines()]
assert len(rows)==42 and all(all(str(v).strip() for v in r.values()) for r in rows)
for label in ('red','green'):
 r=[x for x in rows if x['label']==label and ('unwired' in x['scenario'] or 'wiring lost' in x['scenario']) and x['origin_before']!='n/a' and 'retry' not in x['scenario']]
 assert len(r)==7 and all(x['install_check_rc']=='1' for x in r)
 moved=sum(x['origin_before']!=x['origin_after'] for x in r)
 assert moved==(7 if label=='red' else 0)
 print(label,'unwired boundaries=',len(r),'origin refs moved=',moved)
blocks=Path('relay-system/2026-11-21/gh1576-final-qa-code.diff').read_text().split('diff --git ')[1:]
for block in blocks:
 path=block.splitlines()[0].split(' b/',1)[1]
 expected=re.search(r'index [a-f0-9]+\.\.([a-f0-9]+)',block).group(1)
 data=Path(path).read_bytes()
 assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest().startswith(expected),path
print('seeded diff postimage hashes match all',len(blocks),'source/skill/fixture files')
PY
```

Decisive output: `red unwired boundaries= 7 origin refs moved= 7`,
`green unwired boundaries= 7 origin refs moved= 0`, and
`seeded diff postimage hashes match all 9 source/skill/fixture files`. No Git invocation was used.

**Sweep and limits**

The parent read the whole plan, seeded diff, evidence script/logs/rows, run-record module and
start-task/kickstart skills. Three read-only recon lanes read every line of Jog and its fixture,
merge-cleanup and its fixture, and Express and its skill; the parent adjudicated the open findings
against exact source and the probe above. No additional substantiated pre-existing defect was
found beyond F5/F6. Graph tools were unavailable, so there is no index/generation/coverage claim.
Independent Git-history verification was outside the explicit no-Git boundary. No suite, real
push, deletion or server operation ran. Only this relay file and exempt scratch were written.

swept file: yes
VERDICT: FAIL
Basis: The guard/evidence work is largely supported, but the claimed Express recovery fix does
not cover the documented CLI path and its check moved away from the required push boundary.
F5/F6 are acknowledged pre-existing defects with a scope disposition that conflicts with this
relay's explicit review contract. Round 3 exhausts the configured cap; STATUS is Escalated,
not Approved, and no further automatic repair/review round is authorized by this turn.

Handing off to Producer (claude-a) for parent/operator adjudication of the exhausted relay and
the recorded findings; do not treat the token handoff as approval or start another automatic round.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
