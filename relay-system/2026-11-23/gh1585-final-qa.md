# RELAY · GH-1585 Final QA: laser-focus skill + /finish-line retirement
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1585-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/laser-focus/SKILL.md` (the new skill; sweep the whole file), as part of the committed change from `c58ab03e7` to HEAD (`git diff c58ab03e7..HEAD`) on
  `feat/XYZ-forge-gh1585-laser-focus-2026-11-23`. The change also includes:
  - the `/finish-line` repoints in `skills/2-daily/releases/SKILL.md` (:3, :241-243), `skills/1-hourly/unstuck/SKILL.md`, `skills/1-hourly/standup/SKILL.md`, `ROUTER.md`, `PROJECT/PDDA.md`;
  - the updated assertion in `test/releases-skill.sh`;
  - the `ARCHITECTURE.md` index row;
  - the working doc `PROJECT/2-WORKING/GH-1585-LASER-FOCUS.md` (its 16-goal checklist is the plan);
  - the ledger row in `releases.sql`;
  - the evidence in `TESTS-RESULTS/2026-11-23+GH-1585/`.
- Spec: issue #1585 (`gh issue view 1585`) and its first comment (consult dispositions). Plan QA ran
  as three operator-requested consult rounds, not a relay.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done:
  - The SKILL implements issue #1585 §3 as written: Step 0; frame lock as the first output; the **mandatory** Step 1b gate (target represented with an eligible status, every flagged row dispositioned, nothing invented, `next` as evidence only, decline ends the run); optional Step 1c with rubric R1–R8 and consult QA; the Step 2 audit; the Step 3 ordered 12-code table with first match wins and no fall-through; the Step 4 persistence contract; Step 5 handoffs.
  - It never writes `releases.db` itself, and its only outside write is the confirmed plain-GitHub milestone/tracker.
  - The rules are internally consistent: no two instructions contradict, and every code is reachable.
  - Every live `/finish-line` routing reference is repointed; historical records are untouched.
  - No new test files (GH-831). The evidence substantiates each claim, including the red controls.
  - XYZ-forge is a **public** repo, so no private client data appears in the diff (the dogfood is deliberately redacted).
  - The operator decisions are fixed and are not to be re-litigated: Step 1b is mandatory; `/finish-line` is retired; automatic write-back to the skill's own issue is authorized.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The whole new skill was swept; its plain-GitHub gate remains internally contradictory, and retained evidence omits two promised manual outputs. This is a documentation review, not a new execution of the clone gates.
swept file: yes

- [Should] **F1 — Make the plain-GitHub gate explicit.** `skills/2-daily/laser-focus/SKILL.md:86-88` says *all three* conditions must hold and requires status `draft` or `active`; `:101-103` instead offers an **open** milestone/tracker but never states that this satisfies condition 1. The spec's §3 explicitly says “the gate passes on represented + confirmed.” State that backend-specific equivalence directly and restrict the release-status requirement to release ledgers. Preserve the mandatory gate and other two conditions.
  Observed input: The concrete rule pair at `:87-88` and `:101-102`: an operator-confirmed `<T>` represented by an open GitHub tracker, with no release ledger and no flagged contradictions. Its status is `open`, so the literal universal condition fails despite the intended plain-GitHub route.
  Affected scope: Step 1b for repos whose declared ledger is a GitHub milestone or tracker; release-ledger status checks stay intact.
  Falsifier: A paper walkthrough showing the existing text explicitly maps `open` to the eligible condition would invalidate this finding. After the fix, confirmed open tracker/milestone passes, absent or closed tracker stops, and declining creation stops without triage. No new test file is requested.
  Probe: `python3` read-only line inspection of `skills/2-daily/laser-focus/SKILL.md` (exit 0) printed `:86: **Gate.** Triage starts only when all three hold`, `:87-88: ... eligible status (draft or active, never shipped)` and `:101: ... an open milestone or tracker issue`. This is a textual contradiction, not a claim of an observed live-agent run.

- [Should] **F2 — Retain the promised Step 1c and printed-body paper receipts, or explicitly disposition their omission.** The working plan G-07 requires a dry-run checklist summing to 100; G-10 requires a printed body with the marker on line 1; G-15 includes both. `TESTS-RESULTS/2026-11-23+GH-1585/DOGFOOD-READONLY.md` contains Steps 0–1b and a hypothetical Steps 2–3 table only. Its `provenance.jsonl` has no Step 1c or printed-body receipt. Supply redacted, clearly hypothetical paper outputs and truthful provenance (no actual issue creation), or record an explicit scoped deferral rather than claiming these checks completed. A structural assertion alone is not the requested checklist/body exercise.
  Probe: `python3` reading the seven files in `TESTS-RESULTS/2026-11-23+GH-1585/` (exit 0) reported all nonempty, then `DOGFOOD contains Step 1c: False`, `DOGFOOD contains G-01: False`, `DOGFOOD contains laser-focus body marker: False`; full receipt inspection likewise found neither output.

- [Pass] The central frame/gate safeguards are present: `skills/2-daily/laser-focus/SKILL.md:66-68` forbids triage or writes before frame answers; `:89-95` requires operator-approved dispositions, prohibits invented dates, and treats `next` as scheduling evidence; `:107-109` ends a declined alignment run. The full skill sweep found no additional actionable pre-existing defect beyond F1; this does not certify unrelated surrounding files as fully swept.
- [Pass] Retained focused results include both positive and negative controls: `TESTS-RESULTS/2026-11-23+GH-1585/releases-skill.log` ends “40 pass, 0 fail”; `red-releases-skill.log` ends “39 pass, 1 fail”; `path-integrity.log` ends “3 pass, 0 fail”; `red-path-integrity.log` reports the intentionally broken `worth-it-NOPE` link. `provenance.jsonl` records rc 0/1 and a disposable gate clone for these runs. These are inspected historical receipts, not reviewer reruns or proof of a final-SHA gate.
- [Unverified — needs clone run] No `validate.sh`, `test/*.sh`, pytest, or executable fixture ran in this worktree. Final-commit pre-push/full-gate qualification remains outside this review; no later gate is assumed. The abbreviated dogfood digest is a reported equality, not independently reproducible hash proof here.
- Scope/evidence: Read issue #1585 and its first consult-dispositions comment through the connected GitHub reader after `gh issue view 1585 --repo HiQS-Labs/XYZ-forge --comments` exited 1 (“error connecting to api.github.com”). Inspected the named repoints, index row, roadmap row, working plan, existing assertion, and retained logs. No git command ran; no source/artifact was changed. The review is bounded to inspected content; it does not independently establish untouched history or the complete base-to-HEAD file set.

Handing off to Producer (claude-a) — disposition F1 and F2, then return for Round 2.

### Producer · Round 1 (claude-a)

- **F1 — Implemented.** In `skills/2-daily/laser-focus/SKILL.md`, Step 1b gate condition 1 is now backend-specific:
  - release ledger: a `<T>` row with status `draft`/`active`, never `shipped`;
  - plain GitHub: an **open** milestone or tracker for `<T>`; a closed one, or none, does not pass.

  Conditions 2–3 and the mandatory gate are unchanged.
- **F2 — Implemented.** `TESTS-RESULTS/2026-11-23+GH-1585/DOGFOOD-READONLY.md` gains two sections, both redacted and labelled hypothetical paper outputs:
  - **Step 1c dry run:** 10 goals, weights summing to 100, each `check:` with an expected result and a fail condition, R1–R8 self-scored, and a note that consult QA was not called in the paper run;
  - **Step 4 printed body:** marker on line 1, header, sections, title, and the fact that a gate-NOT-MET run prints and stops.

  `provenance.jsonl` gets two `dogfood-paper` records stating that nothing was posted.

Handing off to Reviewer (codex) — Round 2.

### Reviewer · Round 2

VERDICT: PASS
Basis: F1 and F2 are closed by the revised gate wording and the explicitly hypothetical paper receipts. Re-swept the entire laser-focus skill; found no additional actionable pre-existing defect. Approval is for this documentation review, not final-commit gate qualification or live client execution.
swept file: yes

- [Pass] **F1 closed.** `skills/2-daily/laser-focus/SKILL.md:87-89` now makes eligibility backend-specific: release rows require `draft`/`active`; plain GitHub requires an **open** milestone/tracker and explicitly rejects absent or closed targets. Paper walkthrough: confirmed open tracker plus approved dispositions and nothing invented passes; absent/closed tracker fails condition 1; declining alignment still ends the run under “Declining alignment ends the run: no triage table and no issue.” Conditions 2–3 remain intact.
- [Pass] **F2 closed within the requested paper-evidence scope.** `TESTS-RESULTS/2026-11-23+GH-1585/DOGFOOD-READONLY.md:56-76` supplies the hypothetical ten-goal checklist and self-scored rubric; `:78` onward supplies the printed body. `provenance.jsonl` has two `dogfood-paper` records, expressly “paper run, no GitHub writes.” These are illustrations, not validated client acceptance checks or a consult run; the receipt explicitly says “this paper run did not call it.”
  Probe: read-only `python3` using `pathlib`, `re` and `json` to extract `^\| G-\d+ \| (\d+) \|`, sum weights, inspect the first line after the Step 4 `text` fence, parse provenance labels, and extract the ordered skill codes; exit 0. Decisive output: `paper goals: 10 weight total: 100`; `printed first line: <!-- laser-focus:x-y-0:2026-11-23 -->`; `paper provenance records: 2`; `ordered codes: ['R0', 'C1', 'A1', 'C4', 'A4', 'A2', 'A3', 'C2', 'P2', 'P1', 'C3', 'D1']`. Assertions checked nonzero goal count, exact total, exact marker and two records. No executable fixture or gate ran.
- [Pass] Whole-file review retains the intended separation: “No triage, no GitHub write, and no ledger route runs before the answers arrive”; Step 1c requires advisor scoring and operator approval; Step 3 says “first match wins” and provides the C1 fallback; Step 4 requires paginated discovery and read-modify-write; Step 5 says “never auto-invoke.” These quoted spans are in `skills/2-daily/laser-focus/SKILL.md`. No additional actionable contradiction was found in this sweep.
- [Pass] Re-inspected routing references: `ROUTER.md:218`, `PROJECT/PDDA.md:861`, `skills/1-hourly/unstuck/SKILL.md:216`, `skills/2-daily/releases/SKILL.md:241`, and `test/releases-skill.sh:40` name `/laser-focus`; `ARCHITECTURE.md:90` links its skill. This is inspection of the named surfaces, not proof of a complete base-to-HEAD diff or untouched historical records.
- [Unverified — needs clone run] No final-SHA suite qualification was performed in this reviewer worktree. Round 1's inspected green/red receipts remain historical evidence, and no later gate is assumed. The private-client source, abbreviated digest equality, live collaborator checks and real consult execution remain outside independently reproduced evidence here. The paper printed body deliberately shows NOT MET and is never authorization to triage or post against a failed gate.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-23T20:33:17Z
task: RELAY-gh1585-final-qa
reviewer: codex
status: Approved
reviewed-head: f4807b2cdccb1a829ce22f645d6bc2d4caa7497b
added-range: 13919+3360
added-sha256: 67273b6c94a2477d610f969d2e47e6fc88e69fdb8203da83b764aa33219be4f1
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
