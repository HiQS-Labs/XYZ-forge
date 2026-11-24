# RELAY · GH-1587 Plan QA v2 (Operator Option 1 — GH-681 Prose-Pin Scope)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 2 / 2

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
6. **Manual relay: commit only the relay file** (`relay(gh1587-plan-qa-v2): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: Following operator authorization of **Option 1 (Ponytail / GH-681 precedent)** after `relay-system/2026-11-23/gh1587-plan-qa.md` escalated solely on skill-prose behavioral A/B testing, verify that `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` honestly scopes skill-prose additions (`review-code-xyz`, `review-pr-xyz`, `start-task`) to Layer A deterministic red-on-base/green-on-candidate pin suites (making NO unproven behavioral LLM detection claim for prose, per `test/gh681-reviewer-probe-rules.sh:17`), keeps Layer B live execution focused on GH-836 `test/relay-self-sufficiency.sh` + one `new-relay.sh`-scaffolded Form 2 `Clone probe:` Reviewer+Producer turn (working + errored/unavailable probe paths), and preserves all previously passed controls (final-head ordering before Final QA, 4-field `WORKTREE-SAFETY.md:504-505` clone identity, persisted `85/80/50/70` rating, GH-831, GH-308, and merge-parent rollback).
- Operational Envelope: Local XYZ-forge skill docs, relay turn prompts, marathon brief, packaged tarball, and in-place existing pin suites. Operator explicitly rejected a multi-class LLM A/B harness as disproportionate machinery (`/ponytail`); do not request one.
- Paraphrase-First Step (GH-1414): Before reading source files, write 2–5 sentences each under `**What this proposes**`, `**How the existing system works, per this document**`, and `**What it's not**` (input boundary: plan artifact only), then provide `**Source-backed technical validation**`.
- Plan QA v2 Questions:
  1. Does the Acceptance Map cleanly and honestly separate Layer A prose-pin verification (with zero behavioral LLM claim for prose) from Layer B live relay/harness execution (`relay-self-sufficiency.sh` + scaffolded Form 2 `Clone probe:` Reviewer+Producer turn)?
  2. Are all previously passed gates intact (final-head ordering before Final QA, 4-field clone identity, persisted row `rmi-01M859AVNYRXE06BH6A6QH6F5E` `85/80/50/70`, Form 1/Form 2 closure rules, GH-831, GH-308, merge-parent rollback)?
  3. Is the plan ready for `STATUS: Approved` so implementation can begin after `--accepted-start`?

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
The plan adds six review checks and a two-form relay finding protocol. It tests prose with deterministic pins and exercises the relay handoff in a disposable clone.

**How the existing system works, per this document**
Reviewers currently need concrete observed input and worktree containment limits runtime probes. The plan describes existing skill ladders, relay prompts, a generated package, and existing pin suites that must remain aligned.

**What it's not**
It does not propose an LLM behavioral benchmark for skill prose or new test suites. It does not authorize weakening worktree containment or changing finding tag syntax.

**Source-backed technical validation**

- [Should] Specify an executable red-on-base setup. The plan says to run updated suites against copies in `$TMPDIR` (.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md:188-190), but the current suites derive their target roots from their own locations: `test/gh681-reviewer-probe-rules.sh:23-26`, `test/gh778-review-code-skill.sh:6-8`, and `test/gh616-start-task-commensurate-envelope.sh:4-5,16`. Merely creating base copies does not make these suites read them; a candidate-green run could be mistaken for the intended red control. Specify a disposable complete base tree with candidate test changes overlaid, or a supported explicit target injection, and require the expected new pin failures rather than any nonzero exit.
  Observed input: Phase 2 step 2's `14cb8a60d` target copies in `$TMPDIR`, while the suite paths above resolve under their own repository root.
  Affected scope: all three updated pin suites' red-on-base evidence.
  Falsifier: demonstrate a documented invocation of each updated suite which reads the unchanged base copies, rejects the intended missing new clauses, and passes against candidate files.
- [Should] Add the first-push condition and fallback to the final gate. The plan unconditionally expects the hook to run the full gate (.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md:184,206-207), but `skills/1-hourly/start-task/SKILL.md:291-293` says that holds only for a wired first push; a later docs-only pushed range can route docs. Check the remote branch and actual hook route immediately before push; if not first push or full route is not assured, run the full final-head gate once in the disposable full clone and use its receipt as the documented workflow requires.
  Observed input: a previously published branch with a docs-only final pushed range, explicitly described in `skills/1-hourly/start-task/SKILL.md:293`.
  Affected scope: final approved commit verification when the planned push is not the first branch push.
  Falsifier: show the actual final push is the first push with a wired hook routing the complete change to the full gate, or show a qualifying final-head full-gate receipt.
- [Pass] The prose verification boundary is explicit: .relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md:145-151 separates deterministic pins from live relay smoke and disclaims prose behavioral proof; `test/gh681-reviewer-probe-rules.sh:17-20` makes the same distinction. Keep this separation.
- [Pass] The plan retains final-head re-review, four identity fields, the persisted rating admission check, GH-831/GH-308 and merge-parent rollback (.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md:67-72,176-183,203-205,219-225; `WORKTREE-SAFETY.md:504-505`). Preserve these controls while correcting the findings.

swept file: yes
Pre-existing defects: the red-control setup and unconditional push-gate assumption above are the material issues found in the whole plan; no additional pre-existing defects identified in this sweep. Suite execution and live relay behavior are [Unverified — needs clone run], as required by containment.
VERDICT: FAIL
Basis: The proposed red controls do not specify how base inputs reach the suites, and the final full-gate assumption omits the documented later-push case. Handing off to Producer to repair both and return for review.

### Round 1 · Producer · claude-a · 2026-11-23

**Decisions on proposals:**
- **[Should] 1 (Executable red-on-base setup):** Implemented (`PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` Phase 2 step 2). Replaced the bare `$TMPDIR` copy wording with a complete temporary base checkout at `14cb8a60d` (`$TMPDIR/base-red-check` via `git clone --no-hardlinks` + `git checkout --detach 14cb8a60d`), overlaying ONLY the three updated test scripts (`test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, `test/gh616-start-task-commensurate-envelope.sh`) onto `$TMPDIR/base-red-check/test/` so each suite resolves targets against its own repo root at `14cb8a60d`, asserting each fails specifically on the newly added GH-1587 pin assertions (capturing failing lines rather than accepting any nonzero exit).
- **[Should] 2 (First-push condition & fallback for Tier-3 full gate):** Implemented (`PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` Phase 2 Clone safety boundary, step 7, and Phase 2 QA Gate). Added explicit pre-push check of `git ls-remote --heads origin <branch>` and `bash utils/ci-route.sh` alongside `bash githooks/install.sh --check` per `start-task/SKILL.md:291-293`; if the push is not a first-push full Tier-3 route, run full `./validate.sh` once on the final approved SHA inside `-verify` and record its qualifying receipt before pushing.

**Did:** Applied both surgical fixes to `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` in commit `aa5872ee5`.

**Re-review this:** Re-read `.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md` Phase 2 (Clone safety boundary, step 2, step 7, and QA Gate) to verify both Round 1 `[Should]`s are closed cleanly.

**Commit:** `aa5872ee5`

Handing off to Reviewer (codex) — take your Round 2 turn.

### Reviewer · Round 2

**What this proposes**
The plan adds six targeted review checks and a two-form relay finding protocol. It verifies prose through deterministic pins and exercises the relay handoff in a disposable clone.

**How the existing system works, per this document**
Reviewers must provide concrete evidence and worktree containment restricts executable probes. The plan describes synchronized prompt surfaces, existing pin suites, clone identity checks, and final-head QA before push.

**What it's not**
It does not claim that prose pins prove LLM behavior or introduce an LLM benchmark. It does not authorize new test suites or edits to frozen Bash twins.

**Source-backed technical validation**

- [Pass] The first earlier finding is addressed: the three candidate suites are overlaid onto a complete base checkout and must fail specifically on new assertions (.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md:188-190; test/gh681-reviewer-probe-rules.sh:23-26, test/gh778-review-code-skill.sh:6-8, test/gh616-start-task-commensurate-envelope.sh:4-5,16). Retain the targeted failure evidence.
- [Should] The second earlier finding remains open: the specified `bash utils/ci-route.sh` invocation cannot check the push route because it supplies neither an event nor the pushed paths (.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md:184,207; utils/ci-route.sh:73-74,124-132; githooks/pre-push:325-335). Probe `bash utils/ci-route.sh </dev/null` exited 2 with `ci-route: unsupported event: <empty>`. Specify a `push` invocation fed the same complete `--no-renames` base-to-head path list the hook classifies, check the result, and retain the fallback when first-push/full routing is not established.
  Observed input: the literal planned `bash utils/ci-route.sh` command, with no event argument or path stream.
  Affected scope: final-push route verification before selecting hook execution versus the fallback full gate.
  Falsifier: run the documented invocation against a representative branch diff and show it exits 0 and reports the same route and tier as the hook; expected for a test-file change is full/tier 3.
- [Pass] The plan keeps the prose-pin boundary explicit and the Form 2 failed-probe finding open (.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md:124-151). It retains final-head re-review, clone identity, persisted rating admission, GH-831/GH-308, and merge-parent rollback (lines 73-79, 176-183, 203-205, 219-225).

swept file: yes
Pre-existing defects: apart from the unresolved route-check issue above, no additional material defects were identified in the whole-plan sweep. Live suites and relay execution are [Unverified — needs clone run].
VERDICT: FAIL
Basis: The first-push fallback is described, but the prescribed route command fails before it can establish the required evidence. Round limit reached; handing off to Producer for escalation and correction.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
