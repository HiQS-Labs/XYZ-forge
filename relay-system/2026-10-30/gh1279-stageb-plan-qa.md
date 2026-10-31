# RELAY · GH-1279 Stage B plan QA (tooling and window)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh1279-stageb-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1279-READ-ONLY-PLANNING-SOAK.md`, section "Stage B plan — tooling and the window (this machine)", together with the issue contract it mirrors ("Issue contract" section, sections Shared run contract, Execution-readiness dry runs, Independent adversarial plan QA, One ordered execution plan, Hard stop conditions, Acceptance criteria) and the "Operator decisions recorded (2026-10-31)" table, which overrides the older mirrored text where they differ. Sources: `utils/py/harness.py` (`init_from_prs`, `available_digest`, `_snapshot`, `run_tick`, `status`, `make_packet`, `plan_draft`, `_build_proposal`), `TESTS-RESULTS/2026-10-29+GH-1248/driver.py`, `relay-automation/marathon.sh`, `bin/marathon-yaml`, `AGENTS.md` (No new tests, GH-831).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: the Stage B plan's "Acceptance (Stage B tooling)" list is achievable and falsifiable; it delivers every item of the issue's steps 2-10 that still needs building, with the smallest change to production code (only `init` layout in `harness.py`), and fits the recorded operator decisions (this machine, Terra 6.1 medium with authoring, up to 180 calls, dry-run cap 10, QA minimums, no merge, start after the build on Noel's go).

**Operational envelope.** Local single-operator experiment on one Mac; read-only; the deterministic validator and the loop's existing containment are the safety boundary; an 8-hour foreground window. Grade against the stated requirements and commensurate complexity. Do NOT ask for multi-tenant threat models, retries, new test suites or registry entries (GH-831), a watchdog, or scheduler installation. Challenge bloat in the plan itself.

**Questions** (cite file:line; give the concrete failing input for any behaviour-change request):
1. Is the slot-layout design correct against `init_from_prs`, `available_digest`, the 288-slot manifest map and `_snapshot`'s per-slot digest check? Can canaries (synthetic `source: "unregistered"` issues with numbers 900001+) flow through `plan_draft`, `_build_proposal`, `make_packet`, the planner `compute()` and `bin/marathon-yaml` without special cases or crashes? Name every place a synthetic issue number or a missing `issues.json` entry would break.
2. Slot budget: do 24 canary + 6 missed (85-90) + N real + (66 - N) idle = 96 hold for the proposed placement (real requests fill the next free slots in order), including slot 37 carrying a real request and no canary on 37 or 85-90? What happens to a request that becomes available during 85-90 (it must not) and to the crash at 37 (quarantine of that slot's input)?
3. Driver: is deriving from the 12-hour driver sound for two arms in one process (rules tick then codex tick per slot)? Check the stop conditions against actual `status()` fields and tick outcomes: unknown-cost handling, `paused` on the codex arm before the cap, `uncertain` count with `crash-act` on both arms, per-slot manifest digest, allowlisted top-level instance files with `backlog` present, and `caffeinate`. Is any stop condition untestable or wrong?
4. Two `init` calls: is "retry up to three times, abort on unequal manifests" enough given that live GitHub state can move between calls? Is there a smaller correct way to give both arms identical frozen inputs that does not add a write path?
5. Dry runs and QA: are the `packet` -> `marathon.sh --dry-run` -> preflight steps real and runnable in a disposable clone as described? Is the blinding/flawed-control/scorer design the smallest that meets the issue's QA requirements, with zero false approvals on seeded flaws as the target and Codex-reviews-rules / Claude-reviews-codex separation?
6. Verification before the window: do the compressed driver run and the init layout controls detect the real failure modes (including a planted fault that must stop the run), without adding a suite or registry entry? What is missing?
7. Is anything the issue requires for Stage B missing, or contradicted, in the plan? Is the plan commensurate, and which piece could be cut?

Write the verdict (PASS / FAIL / PARKED) with a Basis; set `STATUS: Approved` only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: Changes requested. The small init-layout change is a sound direction, but the parity comparison does not cover the planner's frozen inputs, the canary specification contradicts itself, and the driver/QA acceptance checks can miss required failures. These are plan corrections, not requests for a new production subsystem, suite, registry entry or watchdog.
swept file: yes

Read the entire 365-line artifact, including the older issue mirror and Stage A/A2 text; operator decisions at lines 280–292 govern their stated overrides. The pre-existing driver path defect below is in scope; no other pre-existing defect requiring a separate production change was established. Runtime execution and mutation-heavy checks were deliberately not run in this review worktree.

- **[Should] R1 — Compare the complete frozen planning input, not only request IDs (artifact:347).** `scenario_sha256` hashes only `requests`; the slot digests hash only available IDs (`utils/py/harness.py:851`, `:853`, `:895`). The planner separately consumes `gh-state.json`, the ledger and git listings (`:364–372`), and delivery checks consume `manifest.delivered` (`:554–567`). Thus two inits can pass the proposed comparison while planning different waves. Keep the bounded retry/abort approach if desired; compare the frozen backlog files and the relevant manifest fields, including delivered/excluded/source identity, before either arm starts. No new production writer or instance-copy facility is necessary.
  Observed input: retained control `TESTS-RESULTS/2026-10-30+GH-1270/controls.txt:1–2` shows #1075 switching from absent to active solely with frozen-state coverage. A pair with identical selected requests but differing state for that unselected ledger row passes the proposed hashes; `_marathon_plan.py:994` changes its classification.
  Affected scope: two-arm initialization parity, including unselected ledger rows that enter computed proposals.
  Falsifier: hold requests/layout fixed and change only #1075's frozen state in one arm; preparation must reject the pair. Identical frozen inputs with the intended rules/Codex config differences must pass. Record this manual control with Stage B provenance.

- **[Should] R2 — Resolve the stale/delivered canary representation before building (artifact:345–346).** Item 1 makes every canary a synthetic 900001+ unregistered issue; item 2 requires real closed/possibly-delivered issues with no synthetic body, yet its row shape has no real issue reference. Re-numbering closed #1075 as a synthetic issue removes the ledger/state lookup that made it closed. Choose and specify the actual row variant and its expected outcome; preserve real identity/state/body for real stale/delivered controls, exclude duplicate real selections, and count those controls among the 24. For synthetic rows explicitly populate the normal request fields (`doc_path`/`doc_sha256` null, canonical issue hash, matching issues entry) rather than adding planner special cases.
  Observed input: the contradictory row contract at artifact:345–346; `plan_draft` indexes `issues[str(req["issue"])]` at `harness.py:632` and uses an unregistered fallback at `:642–643`. An absent issues entry raises before drafting; a synthetic replacement has state `unregistered` (`:476–483`), not the original closed state. A missing `doc_path` also fails at `:634`; `doc_sha256` and `issue_sha256` are required at `:637` and `:694`.
  Affected scope: the 24 canary records and their init conversion, especially real stale/delivered controls.
  Falsifier: round-trip all 24 rows through init → draft → proposal in a disposable clone; show a real closed control stays held, the retained possibly-delivered case stays excluded/held, synthetic rows neither crash nor lose their material, and no real issue is scheduled twice. Invalid row/missing-entry controls must fail explicitly. This is manual evidence, not a new suite.

- **[Should] R3 — Correct the inherited driver's repository depth (artifact:348).** The cited driver sets `REPO = RUN_ROOT.parents[2]` at `TESTS-RESULTS/2026-10-29+GH-1248/driver.py:19`. At both its checked-in location and the proposed Stage B location that resolves to the directory above the repository. Specify `parents[1]` for this layout, or pass an explicit repository root, and include path resolution in the compressed smoke. This is a correction in the run-specific derivative only.
  Observed input: narrow read-only probe, exit **0**: `python3 -c 'from pathlib import Path; r=Path("TESTS-RESULTS/2026-10-29+GH-1248/driver.py").resolve().parent; print("inherited harness exists:", (r.parents[2]/"utils/py/harness.py").is_file()); print("correct-depth harness exists:", (r.parents[1]/"utils/py/harness.py").is_file())'` → `inherited harness exists: False`; `correct-depth harness exists: True`.
  Affected scope: the derivative's harness executable and subprocess cwd, before any timed slot.
  Falsifier: from the planned evidence directory, resolve the pinned clone's actual `utils/py/harness.py` and demonstrate both arms' smoke calls use it; the inherited parent depth must fail this check.

- **[Should] R4 — Verify recovery by selected input, not uncertainty count alone (artifact:348,358).** Specify a per-arm slot-38 check of slot-37's persisted intent and the exact affected IDs, their quarantine, and absence of later consumption/re-fire. The inherited driver checks only aggregate uncertainty/nonterminal counts (`driver.py:102–110`). `_reconcile` quarantines IDs from the chosen intent, not all inputs available at slot 37 (`harness.py:1139–1146`). Codex can choose an older request or safe-idle; merely scheduling a real request at 37 does not establish that it was quarantined. Record an idle intent as having no affected IDs rather than claiming that scheduled input was quarantined.
  Observed input: accepted `idle` with `{}` args (`harness.py:1061`) or an older eligible `plan-draft` ID (`:1055`) at crash-act; reconciliation still produces one `uncertain`, but the IDs differ or are empty.
  Affected scope: both arms' crash recovery and the no-retry/no-duplicate claim, without constraining Codex's selection policy.
  Falsifier: the compressed manual control must detect a recovery with correct uncertainty count but a missing/wrong quarantine. Include a clean selected-request case and an idle/older-selection case; preserve the per-arm intent/quarantine evidence.

- **[Should] R5 — Make frozen-identity stop checks explicit in the derivative (artifact:348).** The required hard stops include ledger modification and prompt/model drift (artifact:177–179), but neither the inherited containment check (`driver.py:53–61`) nor the listed new stops checks those identities. Adding `backlog` to the allowlist allows its contents to change unnoticed by that check, and the harness's slot check sees only IDs. Reuse the manifest's frozen hashes: compare the source/frozen ledgers and immutable input/config/prompt identities around ticks, stopping before further evaluation on drift. Also explicitly add STOP handling: the cited driver contains no STOP-file implementation to “keep.” No scheduler or generalized write-monitor is needed.
  Observed input: a changed `backlog/releases.db` or config `codex_model` leaves all allowed top-level names and the available-ID digest unchanged (`harness.py:1071–1076`); the proposed stop list accepts this state. The original driver has no PAUSE/STOP polling beyond accepting a `paused` outcome (`driver.py:100`).
  Affected scope: required frozen identities and operator stop handling in this foreground run.
  Falsifier: compressed manual controls changing one frozen ledger/config identity must stop before the next evaluation; an unchanged run with expected Codex `unknown_cost` must continue. A STOP file must prevent the next tick. Record these alongside the planted-escape red control; no new test file.

- **[Should] R6 — Cover collisions and define the disagreement denominator (artifact:350,364).** The issue expressly requires unsafe parallel-lane collisions (`artifact:155`); the six named controls omit them. Add a shared-write-set collision to an existing flawed control or add a seventh. Freeze an expected-result key with the rubric, keep it out of review packets, and name what “disagreement” compares: separate arm packs alone provide no paired plan verdicts. The same seeded controls can supply a small common comparison set; alternatively report plan-level reviewer disagreement as unmeasured. Keep the cross-model routing and Opus authority from the issue contract. The three-plan trial should assert expected classifications and a deliberately wrong verdict's nonzero false-approval count, not merely file creation.
  Observed input: the six enumerated controls at artifact:350 contain no collision; the two reviewers receive different arm packs there, while artifact:157 requires disagreement results.
  Affected scope: QA rubric/control coverage and scorer denominators, not additional model arms or a second review pipeline.
  Falsifier: a seeded same-wave pair writing the same path must be rejected; a seeded unsafe approval must increment false approvals and prevent a zero-false-approval claim. Disagreement is computed only for identical hashed items reviewed twice, or explicitly marked unmeasured.

- **[Pass] Slot availability design and budget are compatible with the current seam.** For 24 distinct canary slots outside 37/85–90, six misses and `0 <= N <= 66`, free real/idle capacity is 66 and `24 + 6 + N + (66-N) = 96` (artifact:345). Slot assignment must feed both inbox insertion and all 288 manifest entries (`harness.py:853–864`); `_snapshot` includes consumed/quarantined IDs in its availability digest (`:1071–1078`), so consumption does not invalidate that check. No request may first become available in 85–90. Availability is not consumption: pending work may survive across those misses. Preserve the planned refusal when a short backlog leaves 37 empty.

- **[Pass] Synthetic issue numbers have no intrinsic numeric-range barrier on the cited downstream path.** With R2's complete records, `plan_draft` has the unregistered fallback (`harness.py:642–643`), proposal dependency lookup includes unadmitted unregistered requests (`:558–559`, `:588–589`), and packet generation tolerates a missing planner record when an accepted brief exists (`:1203–1212`). YAML emission uses integer-derived `gh{issue}` IDs (`utils/py/marathon_yaml_emit.py:253–260`); `bin/marathon-yaml:92–100` requires an ID and supported reviewer, not a live issue-number range. This is a source-path review, not a completed end-to-end canary run.

- **[Unverified — needs clone run] Dry-run execution and tooling gates.** The packet's emitted brief path matches copying its folder under `PROJECT/2-WORKING/` (`harness.py:1217`, `:1242–1244`); Marathon resolves that path at `relay-automation/marathon.sh:590–596`. Preflight needs the original capture doc/contract (`utils/py/swarm_preflight.py:1219–1263`), not an assumption that every generated brief supports it. Preserve non-supported/no-ready reasons and all real outcomes, including `NOT-READY` (`:1645`). Run the planned one-lane trial and exact-SHA gates in a disposable full clone. No runtime success is attested here.

Scope/cut: three run-specific helpers and canary data are commensurate with this local experiment. Retain the bounded two-init approach with R1's complete comparison; do not build snapshot import, retries during ticks, a scheduler or a new gate. Clarify that “byte-identical” default behavior compares controlled outputs with timestamps/absolute instance paths accounted for (`harness.py:848`, `:857–869`), not two independently timestamped databases.

Handing off to Producer (claude-a) — disposition R1–R6, revise the plan, then return it for Round 2; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
