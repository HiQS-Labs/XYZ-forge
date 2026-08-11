---
gh_issue: 387
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/387
title: "A builder turn killed at its wall-clock cap is committed and gated as if it completed — the gate becomes the first thing to ever execute the partial work"
status: "2-WORKING — BUILT 2026-08-11 as a direct PR. The gate probe is removed from recover_timeout_exit(); the reviewer now inspects a timed-out artifact before any gate executes it. GH-205 and GH-432 both preserved — no regression was required. test/gh387-gate-not-first-executor.sh 9/0, pre-fix replay 7/2. The untracked-partial leak remains open and is sequenced second."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 4
risk: 5
effort: 4
phases: 2
ratings_provisional: true
roadmap_exempt: false
related:
  - "#386 — adjacent, NOT this doc. #386 is about WHY the kill fires at the wrong threshold (claude-turn's 600s default vs every other builder's 900s, and swarm-preflight's computed budget never being exported). #387 is about WHAT HAPPENS AFTER a kill fires, regardless of which threshold caused it: the killed turn's partial work is committed and handed off exactly like a clean turn, and the gate then runs it unattended. Fixing #386 makes the kill fire less often; it does nothing about what the harness does once it fires — that is this issue."
  - "#384 — adjacent, NOT this doc. #384 is a post-hoc recovery gap: after a whole marathon RUN is interrupted (host crash, OOM, Ctrl-C), there is no documented path back to a known-good state, and its own evidence table includes 'an ungated builder commit' whose phase never reached ANY gate because the driver process itself died first. #387 is a live, in-run mechanism: the RUN keeps going, a single builder TURN is killed at its cap, and the driver's own recovery logic (`recover_timeout_exit`, marathon_drive.py:1980) deliberately feeds that killed turn's artifact into the gate as if it were a clean handoff — which is what caused the crash #384 later has to clean up after. #384 is about recovering from the aftermath; #387 is about the mechanism that produces the unverified commit in the first place."
  - "#432 (CLOSED, PROJECT/3-COMPLETED/GH-432-TURN-FAILURE-PERSIST.md) — the deliberate design decision this issue's defect rides on. GH-432 made a FAILED turn (exit 5) fall through to `rtl_enforce` (commit + containment + token handoff) the same way a TIMED-OUT turn (exit 7) already did, specifically so a crashed builder's work is never silently lost and its token never orphans the relay. That guarantee is correct and must not regress. #387 is the sharp edge it left in place: falling through to `rtl_enforce` on a timeout is *also* what guarantees the gate later has an artifact to probe."
  - "#390 / #457 (shipped) — the pre-advance gate is now wrapped in wall-clock + CPU + RSS caps (commit 94cafc9, hardened in 1fcef22) that would very likely have killed the runaway `while True:` gate process described in this issue's incident *before* it took the host down. This ships AFTER issue #387 was filed (94cafc9 lands 2026-07-31 19:46 UTC; #387 was filed 2026-07-31 03:08 UTC) — see 'The defect' for the dating. It tempers the specific 'host panic' severity but does not touch the structural defect: a killed, never-executed turn is still committed, handed off, and fed to the gate as the first execution of anything it wrote."
non_goals:
  - "Re-litigating #386's timeout VALUE or export bug. Out of scope here; see related."
  - "Building #384's post-interruption recovery tooling (bisecting a stale lock, a dead heartbeat, a hung suite after a crashed run). Out of scope here; see related."
  - "Re-implementing gate resource bounds. #390/#457 already ship wall-clock + CPU + RSS caps on the gate subprocess and are not reopened here."
  - "Weakening GH-432's guarantee that a killed or failed turn's work is committed and its token is handed off, not silently lost or left claimed by a dead agent. Any fix here must keep that property; it may not simply revert to the pre-GH-432 behavior of skipping `rtl_enforce` on a bad exit."
  - "Changing the wall-clock kill mechanism itself (`rtl_run_bounded`) or its 600/900s cap values. Only what happens AFTER the kill, before the gate, is in scope."
goal: >
  A builder turn killed at its wall-clock cap and a builder turn that completed cleanly currently
  produce an indistinguishable artifact by the time anything downstream decides whether to run the
  gate against it: both are committed file-scoped by `rtl_enforce`, both hand the relay token off to
  the next actor, and — specifically when the killed turn already produced a file the driver
  recognizes as a declared artifact — the marathon driver's own timeout-recovery logic then runs the
  full gate against code that has never executed even once, by design (the builder is explicitly told
  not to run the gate itself). Make a genuine builder-turn kill distinguishable from a clean handoff
  at the point the gate-or-escalate decision is made, without regressing GH-432's no-lost-work,
  no-orphaned-token guarantee.
---

# GH-387 · a killed builder turn is committed, handed off, and gated exactly like a completed one

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-11 (direct PR).** The gate probe is gone from `recover_timeout_exit()` (`utils/py/marathon_drive.py`). A timed-out turn's artifact is now inspected by the **reviewer** before any gate executes it. **Nothing regressed:** all six GH-205 assertions in `test/marathon.sh` pass unchanged (33/0), and GH-432's commit/handoff is untouched. `test/gh387-gate-not-first-executor.sh` 9/0; pre-fix replay restoring the probe fails the pin 7/2. | Close #387. **Sequenced second and still open:** the untracked-partial leak — a LATER invocation can still execute a leftover, because `path_has_nonempty_phase_delta` accepts an untracked file as evidence. That needs a durable `unreviewed-partial` marker (new persistent state) and is independent of this change. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/387

## The defect

**The kill is detected and produces a distinct exit code — but that distinction dies before it reaches the gate.**

1. `rtl_run_bounded()` in `relay-automation/relay-turn-lib.sh:431-454` runs the builder CLI under a
   sleep-then-`kill -9` watchdog. When the watchdog fires, the backgrounded process's `rc=137`
   (SIGKILL) is mapped to a distinct return code: `relay-turn-lib.sh:452` — `return 7`. This is a real,
   working distinction between "killed at the cap" and both a clean exit (0) and an ordinary CLI
   failure (any other nonzero).

2. `relay-automation/claude-turn.sh:200-252` captures that as `bounded_rc`. At `:244-245` it correctly
   detects `bounded_rc -eq 7` and prints `claude-turn: claude -p exceeded ${turn_timeout}s wall-clock
   cap — killed` — the exact line quoted in the issue's log. But the very next thing the script does,
   unconditionally, is call `rtl_enforce` at `:251`. Only *after* `rtl_enforce` returns does `:252` exit
   7. The Python twin (`utils/py/claude-turn.py:154-178`) does the identical thing: detect, log, THEN
   call `rtl.enforce(...)` at `:176`, THEN `sys.exit(7)` at `:178`.

3. `rtl_enforce()` (`relay-automation/relay-turn-lib.sh:1026`) is the shared kernel function both the
   Bash and Python turn shims call — `utils/py/rtl.py:407-410`'s `enforce()` literally shells out to the
   Bash `rtl_enforce` function (`lib = ...relay-turn-lib.sh`), so there is exactly one implementation,
   not a twin pair. It takes `<task> <agent> <log> <tool>` — **no exit-code or timeout parameter at
   all**. It cannot condition its behavior on how the turn ended because it is never told:
   - `:1102-1146` stages the allowlist and creates the file-scoped commit unconditionally
     (`git commit -q -m "relay(${task}): ${agent} turn ..."` at `:1144`) — this is the literal source of
     the issue's `claude-turn: committed claude turn (file-scoped, no push)` log line.
   - `:1172-1219` (the "authoritative token handoff", GH-67) then hands the relay token to the peer
     reviewer (`tick release --to $_peer` at `:1209`, printed at `:1210`) — the source of the issue's
     `claude-turn: handed off token ... → agy` line — again with no knowledge of `bounded_rc`.

4. `utils/py/relay_drive.py:479-485` runs whichever shim owns the current turn as a subprocess and, if
   its exit code is nonzero, immediately `sys.exit(res.returncode)` — so relay-drive's own multi-turn
   loop DOES stop on the timeout. This is the one place in the chain that reacts to the distinction —
   but only after steps 2-3 already committed and handed off.

5. `utils/py/marathon_drive.py:1927` captures that as `relay_exit = _run_relay_drive()`. At
   `:2016-2018`, `relay_exit == 7` routes into `recover_timeout_exit()` (`:1980-1993`, added for GH-205).
   This function's own comment states its intent: *"a relay timeout (exit 7) whose declared artifact
   already landed AND is gate-green AND left a live reviewer handoff is resumed... instead of a false
   hang."* It checks `artifacts_exist()` (`:1933-1943`, backed by `path_has_nonempty_phase_delta` at
   `:1439-1469`, which checks the committed diff against `pre_phase_head` first and a `git status
   --porcelain` fallback second) — and because step 3 just committed the killed turn's edit, this is
   true. So at `:1988-1989` it logs *"probing the pre-advance gate"* and calls `run_pre_advance_gate()`
   — which runs `bash validate.sh` (pytest) against the code the builder was killed mid-write on. This
   is the exact mechanism behind the issue's `........ [ 51%] <-- gate; log ends here` — the dots are
   pytest's own progress output, not a green run.

**Why this is not simply "someone forgot a branch."** `utils/py/claude-turn.py:163-175` documents the
unconditional fall-through to `rtl_enforce` as the deliberate fix for a *different*, already-shipped
issue: **GH-432** (`PROJECT/3-COMPLETED/GH-432-TURN-FAILURE-PERSIST.md`), which made a FAILED turn
(exit 5) reach `rtl_enforce` the same way a TIMED-OUT turn (exit 7) already did — because the
alternative (skip `rtl_enforce` on any bad exit) orphaned the relay token and silently discarded the
builder's edits, which was itself a real, reported outage. GH-432's fix is correct on its own terms.
#387 is the cost of applying it uniformly: the one case that most needs its work preserved (a
mid-write kill) is now indistinguishable, by the time `marathon_drive.py` decides whether to gate, from
a turn that finished cleanly.

**Severity nuance, verified by date, not assumed:** the gate itself is no longer unbounded. `#390`'s
RSS/CPU/wall-clock guard on `run_pre_advance_gate()` (`marathon_drive.py:1321-1349`, defaults on by
`MARATHON_GATE_GUARD` per `:1328`) shipped at commit `94cafc9`, dated `2026-07-31 12:46:52 -0700`
(`2026-07-31T19:46:52Z`) — **after** issue #387 was filed (`2026-07-31T03:08:57Z`, confirmed via
`gh issue view 387`). The two host-panic incidents the issue cites (`f33b714`, `39cde29`) predate that
guard. Today, the same killed-turn artifact would very likely be caught and killed by the RSS/CPU cap
before taking the host down — but it would still be *executed*, unattended, having never run once
before. The host-panic severity is tempered; the structural defect (gate as first-execution of killed,
unreviewed code) is not touched by #390/#457 at all.

**The issue's own related link to #383 is stale.** `PROJECT/2-WORKING/GH-383-GATE-TIMEOUT-ALREADY-SHIPPED.md`
(same batch) independently verifies the gate now has exactly the timeout #383 asked for. This does not
change #387's defect — see the severity nuance above — but it means #383 should not be read as still
describing an untimed gate.

## Acceptance

*The issue (fetched fresh via `gh issue view 387` on 2026-08-10; live body byte-matches the local
capture at the top of this task) has no `## Acceptance` heading at all — it is a field report ending in
a "Suggested fix" section, the same shape `PROJECT/3-COMPLETED/GH-432-TURN-FAILURE-PERSIST.md` and
`PROJECT/2-WORKING/GH-402-MARATHON-BRANCH-ENFORCEMENT.md` document for this repo's GH-400 contract.
No text is copied verbatim here as "the issue's acceptance" because none exists. See the authored
section below.*

## Acceptance — authored (issue has none)

1. A builder turn killed at its wall-clock cap (`rtl_run_bounded` returns 7,
   `relay-turn-lib.sh:452`) must be distinguishable, at the point `marathon_drive.py`'s
   `recover_timeout_exit()` (`:1980-2018`) decides whether to probe the gate, from (a) a turn that
   completed cleanly and (b) a relay-level exit 7 that occurred *after* the builder itself already
   finished and handed off (GH-205's original case). Today all three look identical — `relay_exit == 7`
   plus `artifacts_exist()` — and only the third case is safe to auto-probe.
2. When the killed turn is a genuine mid-write kill, the gate must not be the first process to execute
   its output without an intervening, human-visible escalation checkpoint. The issue's own "at minimum"
   ask — escalate the phase and stop, rather than advance into the gate — must be an exercised path for
   this specific case.
3. GH-432's guarantee is preserved: the killed turn's work is still committed file-scoped (or otherwise
   durably preserved) and the tick token is still not left claimed by a dead agent. A fix that
   reintroduces "skip `rtl_enforce` on a bad exit" to solve #387 is a regression of #432, not a fix.
4. The fix applies uniformly across all five turn shims that share `rtl_run_bounded` / `rtl_enforce`
   (claude, agy, codex, aider, pi — confirmed all five call `rtl_run_bounded` in
   `relay-automation/{agy,codex,aider,pi}-turn.sh` alongside `claude-turn.sh`) and both halves of each
   frozen-twin pair, matching GH-432's own precedent that a single-shim fix leaves the same defect
   reachable through the other four builders.
5. A regression test reproduces the GH-382 shape: a builder turn killed mid-edit, having created a new
   file the driver recognizes as a declared artifact, must not reach `run_pre_advance_gate()`
   (`marathon_drive.py:1321`) without the new escalation/checkpoint step firing first. The negative
   control is today's tree: `recover_timeout_exit()` calls the gate directly.
6. A genuinely clean turn (`bounded_rc == 0`) and GH-205's original recovery case (relay-level timeout
   after a clean builder handoff) are byte-identical in behavior before and after the fix — this is the
   guard against the fix over-correcting and disabling GH-205's recovery for the case it was built for.

## Acceptance — deviations from the issue

*There is no verbatim block to deviate from (see above); these are deviations from the issue's
"Suggested fix" section, which is the closest thing it has to acceptance criteria.*

- **"Leave the tree dirty or stash" conflicts with GH-432's guarantee**, which exists specifically
  because leaving a killed turn's work uncommitted was itself a reported, real outage (orphaned tokens,
  silently lost edits). Criterion 3 above makes preserving that guarantee an explicit constraint rather
  than adopting the issue's alternative wholesale.
- **"Do not commit" would not, on its own, close the hole.** `path_has_nonempty_phase_delta`
  (`marathon_drive.py:1439-1469`) treats a newly created *untracked* file (`??` in `git status
  --porcelain`, `:1467`) as evidence of progress even with no commit at all — and the issue's own
  crash scenario is a newly-written test file, which is exactly the untracked-new shape. A fix aimed
  only at the commit step in `claude-turn.sh`/`.py` leaves `recover_timeout_exit()`'s gate-probe
  reachable via the working-tree fallback. The real fix point is closer to `recover_timeout_exit()`
  itself (or a signal it consults), not only the commit call — reflected in criteria 1 and 5.
- **The issue's pseudocode (`if bounded_rc == TIMEOUT_RC: ... return EXIT_TIMEOUT`) is written as if
  it lives in one turn shim.** The actual commit/handoff logic is a single shared kernel function
  (`rtl_enforce`, `relay-turn-lib.sh:1026`, invoked by both languages) with no exit-code parameter, and
  the actual gate-probe decision is a separate function in a separate file (`marathon_drive.py`). A real
  fix necessarily touches at least two files across the kernel/driver boundary, not one — reflected in
  Reversibility & blast radius below.

## Phases

- **Phase 1** — thread a distinguishable "this is a genuine mid-turn kill" signal from the point it is
  known (`rtl_run_bounded` / the calling shim, which has `bounded_rc == 7` before `rtl_enforce` ever
  runs) through to `marathon_drive.py`'s `recover_timeout_exit()`, and make that function refuse to
  auto-probe the gate on that signal — escalating the phase instead, per criterion 2. Preserve GH-432's
  commit/handoff behavior unchanged (criterion 3). Apply to all five shims (criterion 4).
- **Phase 2** — regression tests: the GH-382 negative control (criterion 5) and the GH-205
  non-regression control (criterion 6), plus a check that a genuinely clean turn is byte-identical
  before and after.

## Cross-model consult, 2026-08-10 — the tension is three-way, not two-way

Both advisors were asked, independently and in parallel, whether GH-432 and GH-387 can both hold.
Transcripts: `relay-system/2026-08-10/gh387-tension-211827/`.

**They agree, and it is the load-bearing agreement:** the two guarantees are reconcilable, and the
offending line is the *early gate probe* inside `recover_timeout_exit()` at
`utils/py/marathon_drive.py:1989`. Persistence and execution-eligibility are separable states.
Commit the killed turn and hand off the token exactly as GH-432 requires; run the **reviewer**
before any gate. Neither advisor would touch `rtl_enforce`, `rtl.py`, or the turn shims — both
warned independently that editing those is how you accidentally revert GH-432. That narrows the
write-set to `marathon_drive.py` plus tests, which is materially smaller than this doc's Phase 1
assumed.

**They agree on a second point that kills the naive fix:** refusing only the *current* gate does not
close the hole. `path_has_nonempty_phase_delta` (`:1439-1468`) accepts an untracked `??` file as
evidence of work, so the partial survives on disk and a later invocation — a resume, or the next
phase's gate — executes it anyway. Both rated this a Blocker.

**Where they split, and the adjudication:**

1. *Is refusing the gate sufficient?* agy flagged the leak as a Blocker and then recommended a fix
   that does not close it — remove the probe, defer to the reviewer, and nothing more. codex
   carried its own Blocker through to the remedy: a **durable, repo-wide `unreviewed-partial`
   marker** that fails every gate closed until a reviewer approves that exact HEAD. **codex is
   right.** agy's recommendation contradicts agy's own finding 3; an in-memory refusal cannot
   survive the process exit that a resume implies.

2. *Should #387 be WONTFIX?* agy argued yes — GH-390 now bounds the gate by wall/CPU/RSS, so a
   runaway is killed cleanly and "the residual risk in an ephemeral container is negligible."
   **Rejected on a false premise.** These marathons run on the operator's own machine against a
   real working clone, not an ephemeral container. GH-390 bounds how *much* the gate consumes; it
   does not bound what the code *does*. A killed agent's un-inspected code that deletes files,
   rewrites history, or reaches the network is stopped by none of those caps. The severity is
   genuinely lower post-GH-390 — the host-takedown scenario really is dated — but "cheaper to
   survive" is not "safe to execute."

3. *Coordinates.* agy's cites were wrong — `:1863` for `recover_timeout_exit` (actually `:1980`)
   and `:1372` for `path_has_nonempty_phase_delta` (actually `:1439`); both land on unrelated code.
   codex's `:1988-1993` and `:1439-1468` match the tree exactly. Verified by hand, not taken from
   either. Worth noting the consult harness flagged **codex** for citing no firsthand verification
   while codex was the one with accurate line numbers — that flag measures form, not accuracy.

**What agy contributed that codex did not, and that this doc had under-weighted:** the early probe
is not an accident, it is **GH-205**, and the comment says so at `:1981` — "a relay timeout (exit 7)
whose declared artifact already landed AND is gate-green AND left a live reviewer handoff is resumed
with one more relay-drive pass instead of a false hang." So the gate is being used deliberately as
the *oracle* for whether a timeout was a false alarm.

That makes this a **three-way** tension, which is the real finding of the consult:

| | wants |
|---|---|
| **GH-432** (shipped) | a killed turn's work MUST be committed and its token handed off |
| **GH-205** (shipped) | the gate MAY run early, as the oracle for "was this a real hang?" |
| **GH-387** (open) | the gate MUST NOT be the first executor of un-inspected work |

GH-432 and GH-387 are reconcilable. **GH-205 and GH-387 are not** — GH-205's mechanism *is*
GH-387's defect. Fixing #387 necessarily costs GH-205's hands-free recovery of a near-miss timeout;
the reviewer becomes the oracle instead of the gate, which is slower and spends a review turn on
work that may be broken. That is a real, quantifiable loss and it belongs to the operator to accept,
not to a builder to discover mid-lane. Criterion 6 already reserves a GH-205 non-regression control;
it should be **restated as a deliberate, bounded regression** rather than a control, because the two
cannot both pass.

**CORRECTION, same session — the paragraph above overstates the conflict.** GH-205 and GH-387 *are*
reconcilable, and the difference changes the recommendation from "accept a regression" to "no
regression is required."

Reading `recover_timeout_exit()` (`:1980-2029`) end to end, the gate probe decides **nothing**. It
runs second, and every branch after it is resolved by `file_status()` and `token_state()`:

| condition | outcome | decided by |
|---|---|---|
| no artifact | real hang, exit 7 | `artifacts_exist()`, *before* the gate |
| terminal status, no live actor | continue, exit 0 | token |
| no live actor | halt, exit 7 | token |
| actor is still the builder | real hang, exit 7 | token |
| actor moved to the reviewer | resume relay-drive | token |

The tick token records the handoff directly, so the gate is a **proxy** for a question the token
already answers — "did the builder finish and hand off?" Deleting the probe preserves all five
outcomes and every one of GH-205's recovery paths.

What is genuinely lost is one thing, and it is not a guarantee: the `timeout-gate-failed` early exit
(exit 5). Today a timed-out turn whose artifact is already red halts immediately; without the probe
it resumes to the reviewer, who rejects it. **The cost is one wasted reviewer turn on work that was
going to fail anyway** — a fail-fast optimisation, not a capability and not a safety property.

**Recommendation: delete the probe.** Trading a token-saving shortcut for "the gate is never the
first executor of un-inspected code" is a good trade at any plausible rate of near-miss timeouts.
Criterion 6's GH-205 control stays a *control*: it should pass unchanged, and if it does not, the
change is wrong.

**Still open, and deliberately sequenced second:** the untracked-artifact leak. Refusing this gate
does not stop a *later* invocation from executing the leftover partial, because
`path_has_nonempty_phase_delta` (`:1439-1468`) accepts an untracked file as evidence of work. Closing
that needs codex's durable `unreviewed-partial` marker, which introduces new persistent state and is
materially bigger than removing the probe. The two are independent — the small change is worth having
on its own, and the marker can follow if the residual exposure is judged to matter.

## Litmus tests

1. Simulate a builder turn that is SIGKILLed mid-edit after creating a new untracked file containing an
   unbounded loop (the actual GH-382 shape). Pre-fix: `recover_timeout_exit()` calls
   `run_pre_advance_gate()` directly — the gate subprocess launches. Post-fix: the phase escalates
   before any gate subprocess is spawned against that artifact.
2. After the same killed turn, confirm GH-432's guarantees still hold: the work is still durably
   preserved (commit, stash, or an equivalent the fix substitutes) and `tick info` for the relay task
   does **not** show it claimed by the now-dead builder agent. Negative control: revert the fix,
   confirm both still worked pre-fix too (this is the guard against "fixing" #387 by reintroducing
   #432).
3. A clean turn (`bounded_rc == 0`) drives the gate exactly as before — no change to the happy path.
4. GH-205's original case — relay-level exit 7 *after* the builder already finished and handed off
   cleanly to a live reviewer — still gets the benefit-of-the-doubt gate probe. A fix that blanket-
   disables `recover_timeout_exit()` for every exit 7 passes litmus 1 by over-correcting and fails
   this one.

## Reversibility & blast radius

**Major, and it cannot be a marathon lane.** The distinguishing signal in criterion 1 is known earliest
inside the turn kernel (`rtl_run_bounded` / the code immediately around the `rtl_enforce` call in each
turn shim) and must be consumed inside the driver (`marathon_drive.py`'s `recover_timeout_exit()`).
Both are named explicitly in this repo's self-modification constraint:

- `relay-automation/relay-turn-lib.sh` / `utils/py/rtl.py` — the turn kernel. `rtl.py`'s `enforce()`
  (`:407-410`) shells directly into the Bash `rtl_enforce`, so this is not a twin pair to keep in sync —
  it is one shared implementation. Any change here is live for every relay/marathon turn immediately,
  including the one gating the fix's own review turn.
- `relay-automation/marathon-drive.sh` / `utils/py/marathon_drive.py` — the running driver, and a
  frozen-twin pair (`test/gh308-frozen-twin-guard.sh:23`). Only the Bash half is frozen (`frozen_paths()`
  collects only the left side of each pair per GH-402's own citation of the same mechanism); the Python
  side is the authoritative one and is editable without a `Frozen-twin-exception:` trailer, but the
  Bash twin still needs one if touched, or must be kept in parity.

If criterion 4 (apply to all five shims) is honored, the write-set additionally spans all five
Bash/Python turn-shim frozen-twin pairs (`test/gh308-frozen-twin-guard.sh:14-18`:
`agy-turn.sh:agy-turn.py`, `aider-turn.sh:aider-turn.py`, `claude-turn.sh:claude-turn.py`,
`codex-turn.sh:codex-turn.py`, `pi-turn.sh:pi-turn.py`) and possibly `relay-drive.sh:relay_drive.py`
(`:21`) if the signal needs to pass through that layer explicitly rather than only via the exit code.

**Blast radius if wrong:** too aggressive an escalation-on-kill regresses toward pre-GH-432 behavior
(orphaned tokens, a relay that cannot reach a terminal state without manual `tick done`) — the exact
outage GH-432 was filed to fix. Too narrow a fix (e.g., scoped to `claude-turn` only, or to the commit
step only per the deviations above) leaves the crash reproducible via any of the other four builders or
via the untracked-file fallback path. Neither failure mode is data-destructive — `rtl_enforce` never
pushes (`relay-turn-lib.sh` commits are local-only) — but a wrong fix either reintroduces a known outage
or silently fails to close this one.

Fully revertible by reverting the PR; not revertible mid-run in the sense that a marathon already
executing against the old kernel/driver code will finish that run under the old behavior regardless of
what lands afterward — this is inherent to editing shared, always-live infrastructure, not specific to
this fix.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "utils/py/marathon_drive.py", "pattern": "builder-turn-killed" }
  ],
  "artifacts":     ["relay-automation/relay-turn-lib.sh", "utils/py/rtl.py", "utils/py/marathon_drive.py", "relay-automation/marathon-drive.sh"],
  "artifacts_new": [],
  "remediation":   { "source": "issue #387", "criteria": "distinguish a genuine builder-turn kill from a clean handoff before marathon_drive.py's recover_timeout_exit() probes the gate, without regressing GH-432's commit/handoff guarantee — ranking summary only, NOT the definition of done (that is the authored ## Acceptance block above, since the issue itself has none)" },
  "lanes": { "agy_safe": [], "orchestrator_only": ["relay-automation/relay-turn-lib.sh", "utils/py/rtl.py", "utils/py/marathon_drive.py", "relay-automation/marathon-drive.sh"] }
}
```

**This contract describes the fix's shape for documentation purposes only — it is NOT fireable as a
marathon lane.** The write-set is the turn kernel and the running driver (see Reversibility & blast
radius above); per this repo's self-modification constraint it must ship as a direct PR reviewed by a
human, not through `swarm-preflight` → `marathon-drive`. `lanes.orchestrator_only` reflects that no
agy/aider lane should touch these files at all, driver or not.

**Probe polarity** (probes detect the **bug**, not the fix): `grep_absent` on the placeholder marker
`builder-turn-killed` reports the fix as still required while no such distinguishing signal name exists
anywhere in `marathon_drive.py` today (confirmed: `recover_timeout_exit()` branches only on
`relay_exit == 7` and `artifacts_exist()`, with no concept of "was the builder itself killed"). This is
a placeholder, not a prescription — the actual fix may name the signal differently; a reviewer should
treat this probe as illustrative and rely on the litmus tests above to judge the real fix, the same
caveat GH-402's analogous kernel-touching contract carries.

## Provenance

Filed as issue #387, created 2026-07-31, from a real marathon run (`p5-gh139`) that crashed the host
twice (`f33b714`, `39cde29`, both reverted) before #390's gate-guard shipped. Captured into `2-WORKING`
2026-08-10 as part of Nightwatch batch 2, cross-checked against `PROJECT/3-COMPLETED/GH-432-TURN-FAILURE-PERSIST.md`
(the design decision this defect rides on), `PROJECT/2-WORKING/GH-383-GATE-TIMEOUT-ALREADY-SHIPPED.md`
(same batch; corrects the issue's own stale #383 reference), and `PROJECT/2-WORKING/GH-402-MARATHON-BRANCH-ENFORCEMENT.md`
(same-repo precedent for a kernel/driver-touching, non-marathon-fireable capture doc).
