# RELAY · GH-1020 final QA — reviewer close-mismatch fix
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Reviewer
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
6. **Commit only the relay file** (`relay(gh-1020-final-qa-reviewer-close-mismatch-fix): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation on this branch (`fix/XYZ-forge-gh1020-reviewer-close-mismatch-2026-10-24`,
  reviewed head = the worktree you are in) against the plan `PROJECT/2-WORKING/GH-1020-REVIEWER-CLOSE-MISMATCH.md`
  (also seeded at `.relay-artifacts/GH-1020-REVIEWER-CLOSE-MISMATCH.md`), which Codex approved as a plan in
  `relay-system/2026-10-24/gh1020-plan-qa.md` round 2. This is FINAL QA of code + evidence.
- Requirements source: https://github.com/HiQS-Labs/XYZ-forge/issues/1020 (second comment "Root cause found / Smallest
  fix" binding; Acceptance lines 1 and 4 binding) and https://github.com/HiQS-Labs/XYZ-forge/issues/763 (duplicate).
- Diff under review (`git diff origin/development..HEAD -- relay-automation/relay-turn-lib.sh src/scope.js`):
  `relay-automation/relay-turn-lib.sh` — inside `rtl_turn_prompt`'s reviewer branch (after `verify_note=''`), the
  `handoff` sentence is prefixed with: "if you set STATUS: Approved or Closed, close the token with: done <task>
  --agent <me> (never release --to done — done is a verb, not an agent); otherwise <peer | the role named by NEXT>".
  Builder prompt unchanged (gh505 case G). `src/scope.js` — `TERMINAL_WORDS = /^(done|approved|closed)$/i` and
  `release()` throws before `assertOwnership`/`emitEvent` when `to_agent` matches, message names `tick done <task>
  --agent <agent>`. Nothing else in runtime code changed.
- Evidence: `TESTS-RESULTS/2026-10-24+GH-1020/SUMMARY.md` and `provenance.jsonl` (sha256 per artifact);
  `before-fix-*` (red control: exit 4, `handoff-to: done`, the model's verbatim `release … --to done`);
  `check1-forced-replay/` (script + outputs: 25 PASS, 0 FAIL, guard-reverted red control);
  `check2-after-fix/` (real Codex approval on the fixed prompt: exit 0, attested, model ran `tick done`);
  `check3-after-fix/` (real Codex non-approval: exit 5, `release --to claude-a`); `focused-suites-7cbbeb5e.txt`.
- Ground-truth paths (read, do not grade): `relay-turn-lib.sh` `rtl_turn_prompt` :995-1080 and `rtl_enforce` step 4
  :1565-1615; `src/scope.js` :1-40, :84-110 (`assertOwnership`, `release`, `done`); `src/claim.js:45-60`;
  `bin/tick:315-333, 576-584`; `utils/py/relay_drive.py:402-420, 726-733, 777-782`; `test/gh505-relay-attest.sh:352-366`
  (case G); `test/gh681-reviewer-probe-rules.sh:45-60`; `test/relay-turn-handoff.sh`; `AGENTS.md` (No new tests, GH-831).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Operational envelope: headless relay/marathon reviewer turns on one Mac through the shipped shims; `tick` is a local
  append-only event log. **Commensurate complexity:** grade against #1020 acceptance lines 1 and 4 and this envelope;
  do not ask for new state, retries, registries, schema changes, or test frameworks. GH-831: a new test file or
  registry entry in the diff would be a finding (there is none; `check1.sh` lives under `TESTS-RESULTS/`, not `test/`).
  `close-mismatch` in relay_drive.py is intentionally untouched.
- Definition of Done — answer each with a grade and `file:line` citations:
  1. **Acceptance line 1** (approving turn → header Approved, token done, exit 0, whether or not the model runs tick):
     does the code achieve it? Trace both branches: model runs `tick done` (check 2) and model runs the refused
     `release --to done` then the shim closes (check 1, incl. the `tick done after refused misfire` case). Is any branch
     left where ownership is lost before the shim's step 4?
  2. **Acceptance line 4** (no weakening of GH-505/509 attestation): confirm the diff touches neither
     `relay_drive.py` nor the attestation inputs; the verdict is still reviewer-appended bytes.
  3. **Codepaths match the plan:** exactly the two edits, prompt reviewer-only, guard before any event write, message
     content as planned; no second writer, no repair path, no new state.
  4. **Blast radius of the guard:** any legitimate `release --to` caller (`rtl_enforce`:1598, `marathon_drive.py`,
     `jog_run.py`, tests) passing a terminal word? Is case-insensitive matching (`approved`/`closed` lowercase too)
     acceptable, or over-broad? Is the compatibility limit stated where an operator will see it (error text, plan, PR)?
  5. **Pinned sentences:** gh681's reviewer sentence byte-identical; gh505 case G (builder prompt never says
     `STATUS: Approved`) — verify from the diff and the suite log.
  6. **Evidence substantiates the claims:** do the receipts show what SUMMARY.md says (check the sha256 rows, the
     before/after `tick info`, the model's exact tick commands, the red control)? Is anything claimed but not shown?
  7. **Rating** `85/82/50/80` still matches the evidence and effort actually spent?
  8. **Remaining gate:** the plan requires one tier-3 `ci-local.sh` run in a disposable `-gate` clone on the approved
     commit; it has NOT run yet and will run after your approval — is that the right order, and is anything else
     outstanding before a ready PR against `development`?
- Output: one Reviewer block with `swept file: yes|no`, graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each
  with a concrete fix; every `[Blocker]`/`[Should]` requesting a change carries `Observed input:` / `Affected scope:` /
  `Falsifier:`; then **VERDICT** (PASS / FAIL / PARKED) and **Basis**. Read-only probes allowed (`git diff`, `sed -n`,
  `grep`, `node -e` against a copy under `$TMPDIR`, `python3 -c` hash checks), output under `$TMPDIR`; do not run
  `validate.sh` or `test/*.sh`; do not post any comment.
- Token: when you approve, set `STATUS: Approved` and `NEXT: done`, then close the token with
  `tick done <task> --agent codex`. Never `tick release --to done`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
