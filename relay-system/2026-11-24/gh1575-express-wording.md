# RELAY · GH-1575 express manual-entry wording
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-24.
-->

NEXT: none
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
6. **Manual relay: commit only the relay file** (`relay(gh-1575-express-manual-entry-wording): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/express/SKILL.md` (only this file may change; the relay file is also writable).
- Reviewer: claude   ·   Producer: codex
- Started: 2026-11-24
- Definition of Done (issue #1575, docs-only; operational envelope: one sentence in a skill doc; no code, no tests, no ledger edit):
  1. In `skills/2-daily/express/SKILL.md`, step 5 ("Docs born complete", the sentence ending "add one by hand if the change needs it.", about lines 207-212), make the manual-entry instruction explicit that a hand-written CHANGELOG entry applies only under `CHANGELOG_WRITES=branch`; under `off`/`landing` a branch must not write `CHANGELOG.md` (see `PROJECT/PDDA.md` CHANGELOG contract, ~lines 1062-1070, and `utils/py/wave_reconcile.py` `read_changelog_writes_mode`). Keep the change to that sentence (at most about 3 lines); change nothing else.
  2. Do not touch `releases.db`, `releases.sql`, or any other file. The GH-1530 ledger row's marker was already verified absent (no change needed).
  3. No new tests, no scripts. Producer: edit, then run `utils/pdda/pdda.sh run` is NOT required here; the harness commits your turn. Reviewer: grade the wording for accuracy against the two cited sources, and confirm the diff touches only the one sentence.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Producer · Round 1 · codex
- Updated the single manual-entry sentence to restrict branch entries to `CHANGELOG_WRITES=branch` and prohibit branch writes under `off`/`landing`.
- Verified the wording against `PROJECT/PDDA.md` and `wave_reconcile.read_changelog_writes_mode`; a focused text assertion passed and rejected the previous wording as a red control. Searched for other exact-text pins; none found.
- No suite or PDDA gate was run, as specified for this docs-only turn. No prior findings required disposition.
- Handing off to Reviewer (claude) to review the whole artifact and the requested sentence.

### Reviewer · Round 1 · claude
swept file: yes

VERDICT: PASS
Basis: the reworded sentence is accurate against both cited sources and the diff is confined to that one sentence.

- [Pass] Wording matches the PDDA contract. `skills/2-daily/express/SKILL.md:212-213` says a hand-written entry applies "only under `CHANGELOG_WRITES=branch`" and that under `off`/`landing` "a branch must not write `CHANGELOG.md`". `PROJECT/PDDA.md` (CHANGELOG section) agrees: `off` disables writing on PR branches, `landing` synthesizes post-landing with "PR branches do not write to `CHANGELOG.md`", and `branch` is the only mode that updates on the PR branch.
- [Pass] Mode set matches the code. `utils/py/wave_reconcile.py:1935` `read_changelog_writes_mode` allows exactly `off`/`landing`/`branch`, with default `off`. The `off`/`landing` grouping in the sentence is complete.
- [Pass] Scope is correct. `git diff bef7eef90 HEAD --name-only` lists only `skills/2-daily/express/SKILL.md` and this relay file. The skill diff is +2/-1, in the step-5 sentence only. There is no `releases.db`, `releases.sql`, test or script change.
- [Pass] No contradiction elsewhere in the file. `SKILL.md:18`, `:29` and `:188` already gate the CHANGELOG entry on `CHANGELOG_WRITES=branch`, and `:209` already says `off`/`landing` leave `CHANGELOG.md` untouched. I found no pre-existing defects in the file that bear on this change.
- [Nit] `SKILL.md:212` reads "add one by hand if the change needs it only under `CHANGELOG_WRITES=branch`;". "only" could be read as modifying "needs it". "add one by hand only under `CHANGELOG_WRITES=branch`, if the change needs it;" would be clearer. This is optional and not blocking: line 213 removes the ambiguity.

handing off: relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-24T19:18:27Z
task: RELAY-gh1575-express-wording
reviewer: claude
status: Approved
reviewed-head: 79916c3c77d5d0f50f445ea50f887c95d2b67159
added-range: 9539+1784
added-sha256: 1a75f5bd4d386db8ca2b398649fc06c42f61def7077555cf47aae2b751c6613a
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
