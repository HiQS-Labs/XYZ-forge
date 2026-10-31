# RELAY · GH-1279 Stage B plan QA (tooling and window)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Reviewer
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
