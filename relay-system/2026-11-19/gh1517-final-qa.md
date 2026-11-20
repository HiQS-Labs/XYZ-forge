# RELAY · GH-1517 Final QA: merge-cleanup sweep sentence
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-19.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
6. **Manual relay: commit only the relay file** (`relay(gh1517-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/merge-cleanup/SKILL.md`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-19
- Definition of Done: issue #1517 — the batch protocol sentence and the GH-1383 bullet agree; docs only; no new suite.

Simple docs change (plan QA skipped: one sentence reworded). Diff: `git diff origin/development..HEAD`.
Note: this SKILL.md is a full-gate route surface; the gate runs at push.

Questions (cite file:line):
1. Does the reworded batch-protocol sentence in `skills/2-daily/merge-cleanup/SKILL.md` now agree with
   Discipline bullet 6 (GH-1383) and with `merge_cleanup.py` (auto-sweep at batch end on `--execute`,
   skipped with `--no-auto-sweep`, deferred when the sweep is a hosted `gh workflow run` or marked deferred,
   verdict via `--record-sweep`)? Cite the code lines you checked.
2. Does anything else in the file still say the script runs no sweep?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis; set STATUS Approved only on PASS (approval = `tick done`).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

- [Pass] The revised batch paragraph (`skills/2-daily/merge-cleanup/SKILL.md:493-497`) agrees with Discipline bullet 6 (`:22`) and the detailed GH-1383 bullet (`:531`). Local source inspection: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2989-3009` requires `--execute`, a nonempty command, no `--no-auto-sweep`, no deferred flag, and no `gh workflow run` prefix; it returns 0 for a clean automatic sweep and 4 otherwise. Lines 3090-3108 record clean/findings and update the issue; lines 2528-2529 and 3111-3127 implement manual `--record-sweep`. No runtime execution is claimed.
- [Pass] No blanket statement that the script runs no sweep remains in the full 737-line skill. The nearby “runs no scan, merge or teardown” at `skills/2-daily/merge-cleanup/SKILL.md:536-537` correctly describes only `--record-sweep`; conditional absence/deferment at `:77-82` and `:529` is consistent with the implementation.
- [Should] The pre-existing **Done rule** still requires every qualifying batch verdict “to be recorded with `--record-sweep`” (`skills/2-daily/merge-cleanup/SKILL.md:460-465`), contradicting the automatic-recording route now stated at `:495-497` and `:531`. A caller following this literally after auto-sweep success is instructed to invoke a manual recorder that requires QA pending and otherwise exits 2 (`merge_cleanup.py:3114-3117`). Cheapest fix: allow a covering verdict recorded automatically **or** through `--record-sweep`, while retaining the caller analysis obligation and exit-4 restriction.
  Observed input: `SKILL.md:463-464` unconditionally says the verdict must be recorded “with `--record-sweep`”; the concrete successful-auto branch at `merge_cleanup.py:3090-3099` already records it and returns 0.
  Affected scope: qualifying batches whose automatic sweep records a covering clean verdict; no change to runtime behavior or manual/deferred recovery.
  Falsifier: an automatically recorded covering clean verdict still requiring a second manual recording for completion would invalidate this finding; current `merge_cleanup.py:2980-3002` and `:3114-3117` instead distinguish covered batches from QA-pending batches.

Whole-file sweep found this pre-existing documentation inconsistency; no other actionable defect identified. Review used direct local source reads because this relay worktree is absent from the graph project inventory; the nearest Forge graph generation is 2026-11-18T19:39:07Z, with no recorded gaps for the two paths, but it is a different checkout. No gate, suite, executable fixture, or git command ran. Read commands (`nl -ba … | sed -n …`, `sed -n …`, and `rg -n 'auto.sweep|record.sweep|workflow run|sweep_command' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`) exited 0; decisive code spans are cited above.

Handing off to Producer — revise the Done rule to accept automatic verdict recording, then return for review.

swept file: yes
VERDICT: FAIL
Basis: The changed sentence satisfies the requested auto-sweep contract, but the required whole-file review found a contradictory manual-only completion instruction at lines 463-464.

### Producer · Round 1

- **Should (Done rule) — Accepted.** `SKILL.md` Done rule now accepts a verdict recorded in the batch record
  and issue "either by the automatic sweep (GH-1383) or with `--record-sweep`"; the exit-4-is-never-Done
  clause and the issue-failure note are unchanged.

### Reviewer · Round 2

- [Pass] Round 1's Should is resolved: `skills/2-daily/merge-cleanup/SKILL.md:463-465` now permits recording “either by the automatic sweep (GH-1383) or with `--record-sweep`”. This matches automatic recording and issue update at `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:3090-3099` and manual recording at `:3111-3127`; the exit-4 restriction and issue-failure disclosure remain at `SKILL.md:466-468`. No further fix needed.
- [Pass] The batch paragraph at `skills/2-daily/merge-cleanup/SKILL.md:494-498` agrees with Discipline bullet 6 at `:22` and the detailed GH-1383 bullet at `:532`. The source requires execution, a nonempty command, no opt-out, no deferred flag, and no `gh workflow run` prefix (`merge_cleanup.py:2989-2998`); it returns 0 for automatic success and 4 for findings or manual/deferred recovery (`:2999-3009`). No further fix needed.
- [Pass] Whole-file reread found no remaining blanket claim that the script runs no sweep and no additional actionable pre-existing defect. The “runs no scan, merge or teardown” statement at `skills/2-daily/merge-cleanup/SKILL.md:537-538` applies specifically to `--record-sweep`; caller analysis remains required at `:547-550`. No further fix needed.

Evidence: local `sed -n …` / `nl -ba … | sed -n …` source reads exited 0. `rg -n 'sweep|runs no|no suite' skills/2-daily/merge-cleanup/SKILL.md` exited 0 and showed the conditional sweep instructions cited above. Source-pin lookup `rg -n 'runs no suite|GH-1064 moved|Done rule|either by the automatic sweep' test` exited 0: only the unchanged Done-rule prefix and section-removal control occur (`test/gh534_phase_c_tests.py:913,930`). An earlier globbed lookup exited 1 before searching (`zsh: no matches found: test/gh*batch*`); the directory lookup replaced it. No suite, executable fixture, gate or git command ran; approval covers documentation/source consistency, not a runtime gate result, and assumes no later gate result.

Graph context: Verify tier; project inventory has no entry for this worktree. Nearest Forge index is a different checkout, generation `2026-11-18T19:39:07Z`; coverage reports no recorded issue for the two reviewed paths, which is not completeness proof. Current local source was therefore read directly.

Relay closed (Approved), no further turn needed.

swept file: yes
VERDICT: PASS
Basis: The requested sentence and repaired Done rule consistently describe automatic local sweep recording and manual/deferred recovery; the full skill reread found no further actionable defect. Runtime gates were not run in this reviewer worktree.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
