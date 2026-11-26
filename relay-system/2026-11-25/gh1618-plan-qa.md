# RELAY · GH-1618 plan QA: correct the 'ungated' claim in the GH-1606 documents
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
6. **Manual relay: commit only the relay file** (`relay(gh1618-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1618-UNGATED-CLAIM-CORRECTION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1618-UNGATED-CLAIM-CORRECTION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: every factual claim in the plan (and in the correction note it proposes) is grounded in the real code at base `086b657ea` and does not overclaim; the plan keeps what was measured and only supersedes the wrong inference; the acceptance checks can detect an uncorrected or over-corrected document; nothing but documentation text changes.

### Operational envelope and non-goals
- Documentation-only correction of two already-merged files in the XYZ-forge repo. Grade against the plan's stated requirements and commensurate complexity; the repo's own threat model governs. Challenge bloat; do not manufacture scope.
- XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a new `test/` suite, `validate.sh` entry or gate machinery is itself a finding. The probe script under `TESTS-RESULTS/2026-11-25+GH-1618/` is a manual check with `provenance.jsonl`, not a suite.
- The plan's non-goals (frontmatter `non_goals`) are the author's; say which you accept and which you contest, with evidence. Operator-set constraints: `provenance.jsonl` row `FINDING-phaseB-pre-existing` stays unchanged; no code, tests or gate registration; no absolute home paths.

### Step 1: paraphrase first (GH-1414), BEFORE reading any source file
Read ONLY the artifact under review. Then, before any source-backed assessment, write under three labelled headings: **What this proposes** (2-5 sentences), **How the existing system works, per this document** (2-5 sentences), **What it's not** (short; ground each exclusion in a plan section; separate excluded work, deferred work, unresolved choices and later authorization; label inference and missing boundaries rather than inventing non-goals). State the input boundary: "paraphrase written from the artifact only." Only afterwards read the code and label the rest **source-backed**. Use **bold labels**, never markdown heading lines, inside your review block (the driver counts a block's body only up to the next heading line).

### Step 2: source-backed validation
Read: `test/gh436-merge-cleanup.py` (lines 36-45 and 1375-1390), `validate.sh` around line 96, `test/gh534_phase_b_tests.py` (`LedgerFixture`, `TestPhase5EndToEnd`), `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` around lines 2160-2215 (`gate_toolchain_fault_reason`, `attempt_record.reserve`), the receipts `TESTS-RESULTS/2026-11-25+GH-1618/` and `TESTS-RESULTS/2026-11-25+GH-1615/`, and the two target files (`PROJECT/3-COMPLETED/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md`, `TESTS-RESULTS/2026-11-25+GH-1606/SUMMARY.md`, `provenance.jsonl`) in your worktree.

### Questions (answer each; cite `file:line`)
1. **Premise.** Is it true that the gate reaches the phase B/C tests through `gh436` (`import *`, `validate.sh:96`)? Is there any way the gated run does NOT execute them (name collision, skip, `load_tests`)? Is the plan right that the original measurement (standalone red at `b479f74e0`: 39 tests, 14 failures, 1 error, cause GH-1576) is a separate true fact?
2. **No overclaim.** The proposed correction note says a gated-collected phase B test reaches `attempt_record.reserve` on the healthy path, and that no gated test drives the toolchain-fault ordering. Do the retained probe and `git grep` actually support exactly that, and is the wording no broader than the evidence? Is anything in the note unverified (the plan says the probe ran at `086b657ea`, not at the GH-1606 base)?
3. **Complete list of wrong sentences.** Grep the two target files (and `provenance.jsonl`) for the same claim in other wording ("not referenced", "never saw", "withdrawn as a witness", "red at base", "no suite drives"). Does the plan's edit list cover every site? Is any claim the plan proposes to strike actually true and worth keeping?
4. **Does not rewrite history.** Does the plan keep the original observation and wording (struck through) and add a dated note, and leave `provenance.jsonl` byte-identical while the SUMMARY note supersedes its title word?
5. **What prevents an unfixed candidate being reported as delivered.** AC-1 to AC-5: would each reject an uncorrected or over-corrected document, and where is the observed rejection (the plan says AC-1's red control is the same grep at `origin/development`)? Are admission probes distinguished from final acceptance?
6. **PDDA and governance.** The doc stays in `PROJECT/3-COMPLETED/`; the plan doc `PROJECT/2-WORKING/GH-1618-...md` and its roadmap pointer row were created through `releases_app.py roadmap pickup`. Anything in the plan that would break PDDA front matter, the status table, or the hardcoded-path rule?
7. **Rating.** `15/10/40/90` (pri/sev/appeal/effort, effort = cheapness; appeal 40 is the operator's supplied value). Grounded?
8. **Surgical and DRY.** Smallest honest correction? Anything missing, or any unneeded machinery?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix and `file:line` citations, the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`. Every behaviour-change finding needs `Observed input:` / `Affected scope:` / `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
