---
title: "GH-505: Builder can approve and close its own relay; no merge path checks for a reviewer"
status: In progress
created: 2026-09-08
updated: 2026-09-08
owner: agent-b
goal: make "STATUS: Approved" mean a reviewer approved — bind the terminal status to the supervisor's own observation of the turn it dispatched, stop jog discarding that verdict, and enforce a review requirement at the owned merge paths
gh_issue: 505
source: https://github.com/HiQS-Labs/XYZ-forge/issues/505
branch: fix/gh505-relay-reviewer-integrity
base_sha: 0b37c36f
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/482
  - https://github.com/BinoidCBD/LTVera-Pandas/issues/440
context_tags: [relay, review-integrity, governance, merge-gate]
non_goals:
  - Authenticating tick events, or any new receipt/event-signing subsystem
  - Defending against arbitrary same-user host code execution outside the dispatch/containment contract
  - Changing the relay turn protocol, token model, or round-cap semantics
  - Migrating the `marathon-drive:` directive to a neutral marker name
  - Bridging relay-reviewer identity to GitHub-reviewer identity (named as an open gap, deferred to a follow-up issue)
  - Retroactively auditing or reverting already-merged PRs
effort: 40
complexity: 4
risk: 4
phases: 4
---

# GH-505 — Relay reviewer integrity

## Status

| What was just completed | What's next |
|---|---|
| Codex round 2 blocked the tick-event anchor with source proof that the turn can write `.tick` and spoof `--agent`; verified and accepted. Anchor moved a third time — to the supervisor's own in-process observation, which the child cannot reach | Round 3 Codex QA (cap). Approved → implement Phase 0→3; not approved → stop and record blocked |

## Table of contents

- [Trust anchor: third and final](#trust-anchor-third-and-final)
- [Round 2 dispositions](#round-2-dispositions)
- [Phase 0 — delete the jog override](#phase-0--delete-the-jog-override)
- [Phase 1 — supervisor-observed approval](#phase-1--supervisor-observed-approval)
- [Phase 2 — take the Approved clause out of the shared prompt](#phase-2--take-the-approved-clause-out-of-the-shared-prompt)
- [Phase 3 — enforce a review requirement at the owned merge paths](#phase-3--enforce-a-review-requirement-at-the-owned-merge-paths)

## Trust anchor: third and final

Two anchors have now failed review, both for the same reason — I placed trust in something the
reviewed party can write.

| Attempt | Why it failed | Verified |
|---|---|---|
| In-file `marathon-drive:` directive | A bare line at `RELAY.md:5`, outside the `▽ DO NOT MODIFY ▽` block, in a file every turn may write | Round 1 B1 |
| `.tick/events/` log | The Codex shim unconditionally grants `--add-dir <tick_repo_root>/.tick` (`utils/py/codex-turn.py:65-70`); containment deliberately spares `.tick` because it is "coordination state the turn legitimately writes" (`relay-turn-lib.sh:1309-1313`); and `bin/tick:190-193` passes a **caller-supplied** `--agent` straight through, so a builder can claim under the reviewer's name | Round 2 B1 |

**The anchor is the supervising process's own memory.** `relay_drive.py` is the parent; the turn runs
as a child under containment. The parent already holds, in local variables the child cannot reach:

- `actor` — the identity it *chose* to dispatch, exported as `RELAY_AGENT` at `:619`
- `s`, `rfsig`, `nextp` — relay STATUS, content signature and pointer **before** the turn (`:611-613`)
- `ns`, `nrfsig`, `nnextp` — the same **after** the turn returns through containment (`:820-823`)

So "did the STATUS transition to terminal during the turn I dispatched to X" is answerable with no
new subsystem, no event authentication, and nothing the child can forge.

**The claim is explicitly bounded.** This defends the supported dispatch/containment contract. It is
not authentication against arbitrary same-user host code execution — a process running outside the
driver can still write anything. Tick remains coordination evidence, never sole approval authority.
That boundary is stated in the PR, not implied.

## Round 2 dispositions

All six accepted; none rejected. Each verified against source first.

| Finding | Verified at | Disposition |
|---|---|---|
| **B1** — `.tick` is reachable and `--agent` is spoofable | `codex-turn.py:65-70`, `relay-turn-lib.sh:1309-1313`, `bin/tick:190-193` | Anchor replaced (above); unforgeability claim withdrawn |
| **B2** — last claim/release cannot bind a STATUS transition | `src/scope.js:90-91`, `src/project.js:116-175` | `terminal_actor()` dropped entirely. One predicate, below. No subset port of token projection |
| **B3** — fail-closed with no launcher migration rejects every working relay | `marathon_drive.py:1024-1026`, `:3144-3149` | Marathon's existing `args.reviewer` wired in **this** change; launchers enumerated; same-agent self-review classified unprovable |
| **F1** — controls can pass for unrelated reasons | `relay_drive.py:572-575` (`close-mismatch` already rejects a live actor) | Controls rewritten: token completed, exact exit 4 + reason, baseline-compatible invocation, per-caller merge tests |
| **F2** — deletion range still orphans the handler | Override spans `:1375-1389`; `except OSError: pass` at `:1388-1389` | Corrected to the complete outer `if` block |
| **F3** — merge check contract unspecified | Four callers resolve differently: `-R args.repo`, `cwd=root`, `cwd=repo_path`, PR URL | Full contract specified below |

Documentation corrections accepted: the count dispute is dropped (your `202/66/136` shows scope alone
does not explain it, and active-launcher evidence is the relevant measure anyway); the **Costly**
reversibility read and a rollout tripwire are added to Risks.

## Implementation

### Phase 0 — delete the jog override

Remove the complete outer `if proc.returncode != 0:` block at `jog_run.py:1375-1389`, **including its
nested `except OSError: pass`**. Preserve `proc = subprocess.run(...)` at `:1374` and the final
`return proc.returncode`. Nothing is seeded into the relay file; `run_single_phase_drive` has no
reviewer parameter and gaining one is out of scope.

**Acceptance** — `test/gh505-jog-no-override.sh`: stub the driver to exit 4 while leaving
`STATUS: Approved`; assert the function returns exactly 4. Red control: returns 0 at `0b37c36f`.

### Phase 1 — supervisor-observed approval

**One approval predicate**, applied identically wherever a terminal status is honored. A terminal
STATUS (`Approved` **or** `Closed`) is accepted only when all four hold:

1. the turn was dispatched by this driver to the configured reviewer (captured `actor`, not read back from any file);
2. the turn completed successfully through containment;
3. the STATUS transitioned to terminal **during that turn** (`s` non-terminal → `ns` terminal);
4. the token is in a valid terminal state per the **canonical** projection — call the existing interpretation, do not port a subset.

Anything else — including a terminal status already present at startup, resume, or recovery — is
**unprovable** and escalates with exit 4 and an explicit reason (`terminal-by-non-reviewer`,
`terminal-role-unprovable`, `terminal-unobserved`). No auto-repair: restoring STATUS and repointing
`NEXT:` does not hand off the token, because dispatch reads token state at `:570`, not `NEXT:`.

Applied at all three driver success sites (`:571-579`, `:830-833`, `:868-873`) and all three marathon
consumers (`satisfied_lane_terminal()` `:2677-2698`; recovery `:3218-3222` and `:3294-3298`). A
post-timeout or failed turn must never become success.

**Launcher wiring, in this change:**

| Launcher | Action |
|---|---|
| `marathon_drive.py` | Already requires `args.reviewer` (`:1024-1026`); pass it into the relay command at `:3144-3149` |
| `jog_run.py` legacy `run_single_phase_drive` | Builder-only, no reviewer; refuses **before dispatch** with a migration message rather than spending a turn |
| Direct `relay-drive.sh` invocation | New `--reviewer` required; pre-dispatch refusal when absent |

**Self-review:** builder identity equal to reviewer identity is classified unprovable, not accepted.
The compatibility parser's same-agent fall-through (`relay-turn-lib.sh:88-101`) is deliberately not
preserved for terminal authorization.

**Runtime boundary:** Python-side only. The frozen twin `relay-automation/relay-drive.sh` is
unchanged and its lanes are not protected. Stated in the PR.

**Acceptance** — `test/gh505-relay-terminal-role.sh`, driving the real entrypoint:
- builder dispatched, writes terminal STATUS **and completes the token** → exit 4, reason `terminal-by-non-reviewer`. Red control uses a narrowly transposed guard mutation, since `0b37c36f` does not accept `--reviewer` and would otherwise fail for the wrong reason. Must also prove the terminal branch was reached, not `close-mismatch` at `:572-575`.
- reviewer dispatched, same actions → exit 0, at an ordinary turn and at final cap.
- review-once mode, both roles.
- terminal present at startup/resume → `terminal-unobserved`, never a historical actor.
- `Closed` covered alongside `Approved`.
- builder == reviewer → unprovable.
- all three marathon consumers, including post-timeout evidence.

Evidence: red/green transcripts **and** `provenance.jsonl` committed to `TESTS-RESULTS/2026-09-08+GH-505/`.

### Phase 2 — take the Approved clause out of the shared prompt

`relay-turn-lib.sh:1011`: move `(or done + set STATUS: Approved when approving)` out of the shared
`printf` into the reviewer `role_note` at `:994-1000`. The `relay-drive.sh:32` comment edit stays
dropped — frozen twin, and `test/gh308-frozen-twin-guard.sh:49-64` selects changed paths even for comments.

**Acceptance** — assert both prompts non-empty and carrying role-specific text, then only the
reviewer's contains `STATUS: Approved`. Red control: both contain it at `0b37c36f`.

### Phase 3 — enforce a review requirement at the owned merge paths

One shared `require_approving_review()` — canonical Python implementation plus a thin shell entry for
the one shell caller.

**Contract:**

| Concern | Rule |
|---|---|
| Target resolution | Explicit repo + PR inputs per caller. `express.py:599` uses `-R args.repo`; `jog_run.py:1432` uses `cwd=root`; `merge_cleanup.py:55-56` uses `cwd=repo_path`; `marathon-closeout.sh:292` uses a PR URL. A bare `pr` argument must never query a same-numbered PR in the harness repo |
| Current approval | An approving review by an actor other than the PR author, not dismissed, not superseded, and against the current head SHA |
| Unavailable/malformed `gh` output | Fail closed |
| Refusal result | Caller returns a distinct awaiting-review outcome; reconciliation and teardown must not proceed past it |

**Scope claim:** this PR delivers enforcement at the **owned merge paths**. Server branch protection
is the universal boundary and is a separate operator action — named repo/branch, intended settings,
bypass behavior, and read-back proof recorded there. Phase 3 is not "complete" from code alone.

**Open gap, disclosed not solved:** a relay approval by `codex` is not a GitHub review by a distinct
GitHub actor. Consequence: unattended landing pauses for an eligible external review. No identity
bridge in this PR; deferred to a follow-up issue.

**Acceptance** — exercise **each real caller** with upstream work stubbed and a fake merge marker:
baseline reaches merge without approval; candidate refuses without reaching merge; a valid approval
reaches merge. Removing any caller's check must make that caller's test fail. Dismissed, superseded,
changed-head, malformed and unavailable cases included. Helper unit tests are additional, not a
substitute.

## Dependencies and ordering

Phase 0 → 1 (hard). Phase 2 independent. Phase 3 independent of 0–2.

## Risks and rollback

**Reversibility: Costly.** This changes relay completion, marathon recovery, and queue landing.

| Risk | Mitigation |
|---|---|
| A launcher not enumerated begins refusing pre-dispatch | Refusal is before a turn is spent, with a migration message. **Tripwire:** any `terminal-role-unprovable` on a marathon lane in the first week means the wiring missed a caller — stop and re-inventory rather than widening acceptance |
| Rollback reopens the integrity hole | Explicit: revert is not neutral here |
| Frozen-twin lanes unprotected | Named as a PR limitation |
| Branch protection blocks a lane that cannot produce a GitHub reviewer | Separate operator action, after the identity gap is understood |

## Verification

Full `./validate.sh` in a **separate disposable clone**, never this task clone. Every red control
demonstrated red at `0b37c36f` before its fix. Implementation-time failures route through
`/debug-mantra`.
