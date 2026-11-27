# RELAY · GH-1663 plan QA: ci-optimize SKILL.md small defects
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
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
6. **Manual relay: commit only the relay file** (`relay(gh1663-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1663-CI-OPTIMIZE-SKILL-DEFECTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1663-CI-OPTIMIZE-SKILL-DEFECTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-27
- Definition of Done: every claim in the plan is grounded in the real file and suites; the six edits make `skills/4-occasional/ci-optimize/SKILL.md` self-consistent and portable without changing what any principle requires or rescaling the rubric; the acceptance checks can detect the actual defects and cannot pass vacuously on the unchanged base.

### Operational envelope and non-goals
- Documentation-only edit of one skill file in XYZ-forge. Grade against the plan's stated requirements and commensurate complexity; the repo's own threat model governs. Challenge bloat; do not manufacture scope. Parallel work on `skills/2-daily/merge-cleanup/` is out of scope.
- XYZ-forge forbids new tests (`AGENTS.md` *No new tests*, GH-831): a new `test/` suite, `validate.sh` entry or gate machinery is itself a finding. Verification is the existing suites `test/gh578-ci-optimize-skill.sh` and `test/gh609-sdlc-agent-gaps.sh`, the docs route, and a manual check under `TESTS-RESULTS/2026-11-27+GH-1663/` with `provenance.jsonl`.
- The plan's `non_goals` are the author's; say which you accept and which you contest, with evidence.

### Step 1: paraphrase first (GH-1414), BEFORE reading any source file
Read ONLY the artifact at `.relay-artifacts/GH-1663-CI-OPTIMIZE-SKILL-DEFECTS.md` (no author conversation history is supplied). Before opening `skills/4-occasional/ci-optimize/SKILL.md`, the suites, or the issue, write inside your block, using **bold labels** (never markdown heading lines): **What this proposes** (2-5 sentences), **How the existing system works, per this document** (2-5 sentences), and **What it's not** (short; ground exclusions in the plan's sections and label inference).

### Step 2: source-backed validation (label this section "source-backed")
Now read `skills/4-occasional/ci-optimize/SKILL.md` in full (whole file, not a diff), `test/gh578-ci-optimize-skill.sh`, and `test/gh609-sdlc-agent-gaps.sh` (`check_ci_optimize_contract`). Answer:
1. Is each of defects 1, 2, 3, 4a, 4b real as stated at this revision, with the cited evidence? Is any defect claimed that is not real, or any clearly wrong small defect missed (wrong count, dead anchor, cross-section contradiction)? List what you checked.
2. Is "14 principles, P13/P14 situational extensions outside the 12-row rubric and the waves, bands untouched" the smallest change that keeps the rubric's meaning intact? Is adding rows/waves clearly better (plan says no)? Does the wording risk reading as "ignore P13/P14"?
3. Would edits 1-6 keep both existing suites green? Cite the exact greps that touch edited lines (the description, the heading line `The 12 Foundational Principles`, the roadmap sentence, the mermaid node, the Related Skills bullet).
4. Does the flat-install fallback proposed for `ci-suite-audit` match the existing `sanity-check` one, and does the plan make BOTH links truthfully portable (the sanity-check fallback sits in a later paragraph than its link: sufficient)? Is a suggested alternative better?
5. Are the nine issue numbers correctly labeled XYZ-forge numbers (plan claims all exist as issues in HiQS-Labs/XYZ-forge)? Is the proposed wording portable?
6. What prevents an unchanged, unfixed candidate from being reported as delivered, and where is the observed rejection? Is the manual checker's design (before/after counts, tree vs flat link resolution) able to detect each defect, and is a red control specified?
7. Is the plan surgical and DRY (one file, no new test/registry entry, no duplicate subsystem)? Flag any bloat.

Flag anything wrong, missing, incorrectly scoped or over-engineered, citing file:line. Required lines in your block: `swept file: yes|no`, `VERDICT:` (PASS, FAIL or PARKED) and `Basis:`. Set `STATUS: Approved` only if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes**
Make six bounded text edits to ci-optimize: reconcile fourteen principles with its twelve-row scorecard, include P9 in the roadmap diagram, label issue provenance, and add the missing flat-install fallback. Preserve principle requirements and scoring bands.

**How the existing system works, per this document**
The skill supplies instructions and a twelve-row rubric, with P13/P14 added outside that rubric. Two existing suites pin headings and phrases; relative links work in the Forge directory tree, while flat collections need name resolution. A retained manual before/after check is planned to distinguish the fixed candidate from the unchanged base.

**What it's not**
The non_goals exclude redesign, score rescaling, new waves/rows, merge-cleanup work, umbrella closure and new test machinery. I accept these boundaries provisionally; preserving the existing rubric is the stated purpose.

**source-backed**

swept file: yes

- [Pass] Swept all 172 lines of `skills/4-occasional/ci-optimize/SKILL.md`. Defects 1, 2, 3, 4a and 4b are real: description at :8, fourteen headings at :42-107, twelve rows at :149-160, unlabeled provenance at :15, links at :24/:171, diagram omission at :133 versus P9 at :139, and overbroad roadmap sentence at :127. The existing sanity-check fallback at :34 is sufficient within the same named section; adding the matching ci-suite-audit sentence is surgical. No additional small count, anchor or wave-membership defect found. There are no internal anchor links to repair. Anti-pattern references (:119), no-new-tests callout (:38-40), score rows and bands (:149-165) agree.
- [Pass] Preserve the twelve-row rubric and apply P13/P14 when their conditions arise: P13 already calls its stress loop a “diagnostic option” (:103), while P14 specifies performance-critical workloads (:108). The proposed intro explicitly says “applied when the situation arises” (artifact :71); adding rows/waves would change the rubric's meaning. Accept the listed non-goals; no new subsystem or registered test is justified.
- [Pass] Static suite compatibility: `test/gh578-ci-optimize-skill.sh:15` only greps `description:`; :17's “12 Foundational Principles” is a comment, not an assertion; :18-33 pin numbered headings/titles. :43-47 grep the roadmap heading, `Wave 1`, `Wave 4`, scorecard heading and `20–24 Points`, all retained. No grep pins the roadmap sentence, node wording or Related Skills bullet. `test/gh609-sdlc-agent-gaps.sh:139-149` pins P13/P14 headings and body fragments, all unchanged by the plan. This predicts compatibility; suites were NOT executed here and need the prescribed disposable clone run.
- [Should] Resolve issue provenance by subject, not merely issue existence, before applying edit 2. **Observed input:** artifact :46 infers “not upstream-archive numbers” from existence. However `docs/ROADMAP-UPSTREAM-ARCHIVE.md:72` identifies upstream #528 as test-suite recalibration and :94 identifies upstream #544 as local-gate-before-push. Read-only GitHub connector calls `fetch_issue(repository_full_name="HiQS-Labs/XYZ-forge", issue_number=528)` and the same call for 544 succeeded: Forge #528 is “fix(skill): /unstuck — queue simultaneous blockers, tripwire recurring blocker classes”; Forge #544 is “research: archive Luna/Needle model benchmarks and Git/PR analyst findings”. These do not support the skill's pipeline provenance. All nine Forge issue lookups succeeded, but existence does not establish identity. **Affected scope:** the nine provenance numbers on skill :15 and artifact :46/:70. **Falsifier:** source history or primary issue content showing these Forge records actually document the cited CI mechanisms; expected result is a subject-matching citation for each number. **Concrete fix:** map each number to its actual source repository and link/group accordingly; #35 can remain Forge, while demonstrably upstream numbers must name upstream. Correct the recon assertion and add subject-aware acceptance rather than declaring every number Forge.
- [Should] Specify a discriminating acceptance result, including all six edits, rather than only printed observations. **Observed input:** artifact :75 specifies a checker that “prints” counts/literals/node/link results; :85 calls “reports the inconsistencies” an observed rejection. Neither specifies a failing result, and :75 has no check for the repository-label edit (:70), narrowed roadmap sentence (:72), situational intro (:71), or rubric-only explanation (:73). The two existing suites do not check those changes (citations above), so a partial fix can satisfy the described observations. **Affected scope:** this one retained manual checker and delivery evidence, not any new CI gate. **Falsifier:** an explicit checker contract that rejects an unchanged candidate and individually rejects omission of the provenance correction, roadmap scope, extension explanation and scorecard scope, while accepting the intended candidate. **Concrete fix:** enumerate those assertions, nonempty extraction checks, expected base/candidate exit statuses and decisive output; record the observed red base run and green candidate run during implementation. Keep the checker in the existing evidence directory; no new registered suite.
- [Pass] Narrow non-mutating Python inspection exited 0, using `re.findall(r'^### \d+\.', s, re.M)` and `re.findall(r'^\| \d+ \|', s, re.M)` after `assert s`: decisive output was `headings= 14 rows= 12`, `old_heading= True`, `P9_in_node= False`, `sanity-check tree_exists= True flat_relative_exists= False fallback= True`, `ci-suite-audit tree_exists= True flat_relative_exists= False fallback= False`. The flat path probe checked `/tmp/flat/ci-optimize` lexical placement only; it is not a populated flat-install fixture. This establishes current defects, not a passing final checker or an observed checker rejection. No gate is configured in this relay and no later gate is assumed.

VERDICT: FAIL
Basis: The six-edit scope is proportionate and the rubric decision is sound, but the proposed universal Forge provenance label is contradicted by source records. Tighten the manual rejection contract before implementation; actual clone runs remain implementation evidence owed.

Handing off to Producer (claude) — correct provenance and acceptance specifications, then take the next turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
