# RELAY · QA review — GH-21 quality gate planning doc

NEXT: claude-a
STATUS: Changes requested
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first

You are **claude-b**, the Reviewer, taking a **QA turn** in a file-based relay. Your task is to
**review the restructured GH-21 project planning doc** for actionability, completeness, and
internal consistency. This is a read-only review — **do NOT edit the planning doc itself**.

> ⏱️ **TIME-BUDGET — read first.** Textual review only. Do NOT run `./validate.sh` or any test
> suite. Read the planning doc and the key referenced scripts, then write your block.

1. **Read the planning doc** (do NOT edit it):
   `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/PROJECT/1-INBOX/GH-21-RELAY-QUALITY-GATE.md`

2. **Read the referenced code** (skim what you need; read-only):
   - `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/bin/tick`
     (the `release` and `done` verb handlers — Phase 1's proposed hook-in point, ~L220/L236)
   - `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh`
     (Phase 1: verify the architecture claim that `rtl_enforce` fires AFTER `tick release`)
   - `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/relay-automation/relay-drive.sh`
     (Phase 3: verify `--consult-verify` seam and the `exit 4` / `STATUS: Escalated` flow)

3. **Review the planning doc** on these four dimensions:

   **A. Checklist observability** — for EACH phase checklist item, ask: can an agent or human
   verify this item deterministically without ambiguity? Flag any item that is vague,
   unmeasurable, or missing a success criterion. Cite by checklist item text.

   **B. QA checklist testability** — for each Phase QA checklist, ask: does every item specify
   (a) what to run, (b) what to pass in, and (c) what exit code / output to expect?
   Flag items missing any of those three. A good QA item looks like:
   "Run X with input Y — confirm exit Z and output W."

   **C. Architecture consistency** — verify that the implementation details in the doc
   (hook-in points, exit codes, flag names, field names) match the actual code.
   Specifically check:
   - Phase 1: Do `release` and `done` verb handlers actually exist at ~L220/L236 in `bin/tick`?
   - Phase 1: Does `exit 6` (containment revert) actually exist in `relay-turn-lib.sh` as claimed?
   - Phase 3: Is `exit 4` used for `STATUS: Escalated` in `relay-drive.sh` as claimed?
   Cite findings by `/absolute/path:line`.

   **D. Completeness** — are there any gaps between the "what done looks like" prose in the
   original doc and the checklist items under each phase? List anything material that appears
   in the phase description but has no corresponding checklist item.

4. **Append ONE block** at the bottom of THIS relay file (above the `---` marker) using tags:
   `[A-Observability]`, `[B-Testability]`, `[C-Architecture]`, `[D-Completeness]` — one bullet
   per finding under each tag. Use `[Pass]` for any dimension that is fully sound.
   Log a `Basis:` line (textual only / behaviorally proven).

5. **Set the header:**
   - `STATUS: Approved` if no `[Blocker]` or `[Should]` findings survive
   - `STATUS: Changes requested` if you find items the doc author needs to fix before execution

6. **Set the verdict at the top of your block:**
   `VERDICT: PASS` (approved as-is) | `VERDICT: FAIL` (changes required) | `VERDICT: PARKED` (blocked on info)

7. **Hand off the lock** (use the absolute tick path, do not shorten):
   ```
   TICK_REPO_ROOT="/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/bin/tick" done RELAY-gh21-plan-qa --agent claude-b
   ```

8. **Stop.** One-line result to the operator.

## Setup

- Artifact: `PROJECT/1-INBOX/GH-21-RELAY-QUALITY-GATE.md` (read-only — do NOT edit it)
- Definition of Done: claude-b appends a graded QA block covering observability, testability,
  architecture consistency, and completeness — with a VERDICT line.
- Reviewer: **claude-b** (this turn). Author: Claude-a (will apply findings to the plan doc).
- Lock: tick task **RELAY-gh21-plan-qa**
- Started: 2026-06-25

## Ground rules

1. This file is the single source of truth. Append one block at the bottom (above `---`); never edit earlier turns.
2. Do NOT edit `PROJECT/1-INBOX/GH-21-RELAY-QUALITY-GATE.md` — QA review turn only.
3. Stay tight: bullets, not essays. Cite real code by absolute path:line when possible.
4. Evidence contract: log a `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run).

---
## Log

### claude-b QA turn — 2026-06-25

VERDICT: FAIL

**[A-Observability]**

- [Pass] Phase 1 checklist item "Read `bin/tick` and locate `release` and `done` verb handlers (~L220/L236)" — deterministic; no ambiguity.
- [Pass] Phase 1 items "Verify malformed block triggers `exit 8`" and "Verify well-formed block passes" — observable binary outcomes.
- [Should] Phase 2 item "Run `test/relay-self-sufficiency.sh` manually against a real headless agent" — no success criterion defined. What output or exit code constitutes a manual pass? Add: "confirm exit 0 and summary line enumerating assertions checked."
- [Should] Phase 2 item "If FAIL: document which tacit knowledge leaked through ambient context; encode fix into relay file template" — conditional but the condition trigger is not measurable. Specify: what diagnostic output from the script names the failure, and what counts as "encoded" (a diff to the template file)?
- [Pass] Phase 3 checklist items are each deterministic (exit code / field value / presence of block).

**[B-Testability]**

- [Pass] Phase 1 QA checklist items each satisfy (a) what to run, (b) what to pass, (c) what to expect. e.g. "Run `bin/tick release` against a relay file missing `VERDICT:` — confirm `exit 8`, token not released."
- [Blocker] Phase 1 QA item "Run `bin/tick release` against a relay file missing `VERDICT:`" — `bin/tick release` does NOT currently invoke any validator; the hook-in is the implementation work of Phase 1. This QA item therefore CANNOT be run until after `bin/validate-relay-block` is wired in (Phase 1 implementation checklist items 4–5). The QA checklist must clarify it is a POST-implementation test, or reorder to make the dependency explicit.
- [Should] Phase 1 QA item "Run the existing Part A dogfood relay end-to-end — confirm no regression" — no pass criterion stated. Specify: confirm relay terminates `STATUS: Approved` and `exit 0` from `relay-drive.sh`.
- [Pass] Phase 2 QA items specify exit code and output expectations sufficiently.
- [Should] Phase 3 QA item "Confirm conflict-warning block in the log is parseable" — "parseable" is undefined. Specify what parse action is performed (e.g. "Phase 1 validator exits 0 on the escalated file" — which the next bullet already covers). Consider merging with bullet 5.
- [Pass] Phase 3 QA items otherwise satisfy the three-part criterion.

**[C-Architecture]**

- [Blocker] Phase 1 doc claims hook-in at `bin/tick` `release` (~L220) and `done` (~L236). **Code verified at `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/bin/tick:220-226` and `:236-242`.** `release` handler is at L220–226 and `done` handler is at L236–242. Line numbers are accurate. HOWEVER: the current `release` and `done` handlers contain NO validator hook-in point — they call `release()` / `done()` from `src/scope` directly and return 0. The `bin/validate-relay-block` call must be inserted BEFORE those function calls. The plan correctly says "wire … into `bin/tick release` before lock release" but does NOT specify exactly where in the case block to insert — between the arg validation guard and the `release(root, …)` call. This is implementation-sufficient but could use a precise "after arg check, before `release(root,…)`" callout.
- [Pass] Phase 1: `exit 6` in `relay-turn-lib.sh` for containment revert — confirmed at `/Users/noelsaw/Documents/GitHub Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh:289` (in-ROOT commit bypass) and `:321` (off-allowlist enforcement). Both fire `exit 6`. The distinction from the proposed `exit 8` (quality failure) is sound.
- [Blocker] Phase 1 doc claims `exit 6` is for "containment revert" and proposes `exit 8` for structural quality failures. **Verified**: `bin/tick` currently exits with `process.exit(1)` on any thrown error (`:374`) and returns `2` for usage errors (`:125`, `:161`, etc.). There is NO `exit 8` in `bin/tick` today. The plan must add `exit 8` to the Node.js `main()` function's switch-case, not just to "docs" — the call to `bin/validate-relay-block` must itself `process.exit(8)` or propagate an exit code 8. The checklist item "Add `exit 8` constant … to `bin/tick`'s error legend / docs" undersells the work: actual code change to `bin/tick`'s main() is required to propagate `exit 8`.
- [Pass] Phase 3: `exit 4` for `STATUS: Escalated` — confirmed in `relay-drive.sh`. `escalated_status()` at `:93` matches `Escalated`, and both `:133` and `:169` `exit 4` on that branch. Architecture claim is accurate.
- [Should] Phase 3 doc says consult fires "After the turn-taker's `tick release`" — but `relay-drive.sh` currently has no post-turn hook point between `"$AGENT_CMD"` invocation (`:155-159`) and the no-progress guard (`:163`). The `--consult-verify` insertion point needs to be specified as after line `:160` (`round=$((round + 1))`) and before `:163` (no-progress read). Not a blocker but should be called out precisely.

**[D-Completeness]**

- [Should] Phase 1 "what done looks like" (doc goal): "a deterministic script validates relay block shape … independent of the turn-taker." The checklist includes writing `bin/validate-relay-block` but has NO item for updating `AGENTS.md` or the relay protocol docs to reference the new validator — agents and operators won't know it exists or what `exit 8` means without documentation beyond the help/usage text.
- [Should] Phase 2 "what done looks like": "formally verify … sufficient for a context-free agent on a fresh clone." The checklist has the test script but NO item covering what happens when `validate.sh` integration is added — the test could break `validate.sh` if the headless agent requirement (network, API key) is unavailable in CI. A note on CI-gating or mocking is absent.
- [Pass] Phase 3 checklist covers all material points from the phase description.
- [Should] "Connection to Existing Tracks" section mentions "Add to GUIDING-PRINCIPLES.md when this track ships Phase 1." This is captured in Phase 3 QA checklist item 6 but NOT in any Phase 1 checklist item. A Phase 1 checklist item should explicitly call out: "after Phase 1 ships, update GUIDING-PRINCIPLES.md with the 'Independent Verification (Separated Grading)' principle." Currently this falls through the Phase 3 gate and could be dropped if Phase 3 never runs.

Basis: textual only (read planning doc and referenced code; no commands run per time-budget constraint).
