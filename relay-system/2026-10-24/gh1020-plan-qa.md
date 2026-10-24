# RELAY · GH-1020 plan QA — reviewer close-mismatch fix
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
6. **Commit only the relay file** (`relay(gh-1020-plan-qa-reviewer-close-mismatch-fix): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1020-REVIEWER-CLOSE-MISMATCH.md` (the plan; also seeded read-only at
  `.relay-artifacts/GH-1020-REVIEWER-CLOSE-MISMATCH.md`). This is a PLAN review; no fix code exists yet.
- Requirements source (read in full first): https://github.com/HiQS-Labs/XYZ-forge/issues/1020 (body + the two
  operator comments: the second comment's "Root cause found" and "Smallest fix" are the binding requirement;
  "Acceptance" lines 1 and 4 are binding, line 2 (row 4, header left Open) and proposal 3 are out of scope here) and
  https://github.com/HiQS-Labs/XYZ-forge/issues/763 (duplicate of the same mode; closed by the same PR).
- Ground-truth paths (read, do not grade): `relay-automation/relay-turn-lib.sh` (`rtl_turn_prompt` :995-1075, esp. the
  `handoff` string :999-1000 and the `role_note` sentence :1047; `rtl_enforce` step 4 :1559-1608),
  `relay-automation/codex-turn.sh:30-36,100` (RELAY_PEER is read from env only), `utils/py/relay_drive.py:402-420`
  (`token_state`), `:726-733` and `:777-782` (close-mismatch), `src/scope.js` (`assertOwnership`, `release`, `done`),
  `src/claim.js` (`claim`: the "Reserved for someone else" branch), `bin/tick:117,159,315-333`,
  `test/gh681-reviewer-probe-rules.sh:45-60` (pins the role_note sentence), `test/gh554-tick-unknown-flags.sh`
  (precedent: tick refuses a misuse), `TESTS-RESULTS/2026-10-24+GH-1020/` (today's before-fix reproduction: driver
  log, tick info before/after, the model's exact `tick release ... --to done` command, the relay thread it wrote),
  `AGENTS.md` (No new tests, GH-831).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Operational envelope: a headless relay/marathon reviewer turn on one Mac, driven by `relay-drive.sh` through the
  shipped shims; one token per thread; `tick` is a local append-only event log. **Commensurate complexity:** grade
  against #1020's acceptance lines 1 and 4 and this envelope. Do not ask for new state, retries, a token registry,
  schema changes, or test frameworks. GH-831: a plan step that adds a test file or registry entry is itself a finding.
  Keep `close-mismatch` (relay_drive.py) as is — it is the safety property.
- Definition of Done — answer each with a grade and `file:line` / issue-section citations:
  1. **Grounded?** Does the plan's "Observed" section match the cited source: the `handoff` string when RELAY_PEER is
     unset, that relay-drive never sets RELAY_PEER, the `role_note` sentence, `assertOwnership` failing after a
     release, `claim` refusing an open token reserved for another agent (so no in-place repair exists), and the
     receipt in `TESTS-RESULTS/2026-10-24+GH-1020/`?
  2. **Does edit 1 (prompt) remove the trigger** without breaking any pinned sentence (gh681) or the non-approval path
     (`release --to <peer>` / the agent named by NEXT)? Is the proposed wording unambiguous for a model that reads
     both the `handoff` sentence and the `role_note` sentence?
  3. **Does edit 2 (tick guard: `release --to done|Approved|Closed` refused in `src/scope.js release()`) make
     acceptance line 1 true "whether or not the model also runs tick itself"?** Trace the sequence: model runs the
     refused command → still owner → shim `rtl_enforce` step 4 runs `tick done` → driver attests. Name any input where
     the guard is wrong (an agent legitimately named `done`?) or where ownership still changes hands.
  4. **Smallest change / no duplicate writer:** is a tick-layer guard the right home (precedent #554) versus
     prompt-only or a shim-side repair? Is anything in the plan beyond the two edits?
  5. **Blast radius:** who else calls `tick release --to` (`rtl_enforce`, `marathon-drive`, `relay-drive`, tests)?
     Does any legitimate caller pass a terminal word as the target?
  6. **Verification plan:** focused suites named, tier-3 full gate in a disposable clone once, and a manual before/after
     receipt with a red control (the before run) — truthful under GH-831? What is missing to falsify the claim?
  7. **Rating** `85/82/50/80` (pri/sev/appeal/effort; effort = cheapness; appeal must be 50) and the recurrence
     evidence (3 incidents 2026-09-23..28, 6 in 2026-10-10..14, 1 reproduction today) — defensible?
  8. **Non-goals:** row 4 (header left Open), proposal 3 (marathon retry), loosening close-mismatch — correctly excluded?
- Output: one Reviewer block with `swept file: yes|no`, graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each
  with a concrete fix; every `[Blocker]`/`[Should]` requesting a change carries `Observed input:` / `Affected scope:` /
  `Falsifier:`; then **VERDICT** (PASS / FAIL / PARKED) and **Basis**. Read-only probes allowed (`sed -n`, `grep`,
  `node -e`, `gh issue view`), output under `$TMPDIR`; do not run `validate.sh` or `test/*.sh`; do not post any comment.
- Token: when you approve, set `STATUS: Approved` and `NEXT: done`, then close the token with
  `tick done <task> --agent codex`. Never `tick release --to done` (that is the defect under review).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
