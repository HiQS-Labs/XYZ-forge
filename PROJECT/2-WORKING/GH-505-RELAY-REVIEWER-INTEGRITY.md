---
title: "GH-505: Builder can approve and close its own relay; no merge path checks for a reviewer"
status: In progress
created: 2026-09-08
updated: 2026-09-08
owner: agent-b
goal: make "STATUS: Approved" mean a reviewer approved — attribute the terminal status to a trusted actor, stop jog overriding the driver's escalation, and enforce a review requirement at a boundary that actually intercepts every merge
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
  - Adding a new review subsystem, receipt store, or reviewer-quality metric
  - Changing the relay turn protocol, token model, or round-cap semantics
  - Retroactively auditing or reverting already-merged PRs
  - Migrating the `marathon-drive:` directive to a neutral marker name
  - Bridging relay-reviewer identity to GitHub-reviewer identity (named as an open gap, not solved here)
effort: 40
complexity: 4
risk: 4
phases: 4
---

# GH-505 — Relay reviewer integrity

## Status

| What was just completed | What's next |
|---|---|
| Codex plan QA round 1 returned **CHANGES REQUESTED** with 5 blockers and 2 fixes; all independently verified as valid and the plan rewritten around them — the trust anchor moved from the in-file directive to the tick event log | Round 2 Codex QA on this revision; no implementation until Approved |

## Table of contents

- [What round 1 changed](#what-round-1-changed)
- [Phase 0 — delete the jog override](#phase-0--delete-the-jog-override)
- [Phase 1 — attribute the terminal status to a trusted actor](#phase-1--attribute-the-terminal-status-to-a-trusted-actor)
- [Phase 2 — take the Approved clause out of the shared prompt](#phase-2--take-the-approved-clause-out-of-the-shared-prompt)
- [Phase 3 — enforce a review requirement at a real merge boundary](#phase-3--enforce-a-review-requirement-at-a-real-merge-boundary)

## What round 1 changed

Codex blocked the first plan. Every finding was verified against source before acceptance; all
seven were valid and three of them invalidated the plan's core premise. Dispositions:

| Finding | Verified | Disposition |
|---|---|---|
| **B1** — the role directive is editable by the party it authorizes | The directive is a bare line at `RELAY.md:5`, outside the `▽ DO NOT MODIFY ▽` block, in a file every turn may write | **Accepted — premise invalidated.** Trust anchor moved to the tick event log (below) |
| **B2** — three driver success sites, not two; `token_state()` returns `""` for done; NEXT is not the dispatch input | Third site confirmed at `relay_drive.py:868-873`; empty actor at `:374-377`; dispatch reads token state at `:570` | **Accepted.** All three sites gated; no auto-repair, integrity escalation only |
| **B3** — Phase 3 conflated two jog executors; the deletion orphaned `proc`; the seed used `task_name` before assignment | `run_single_phase_drive(root, gh_num, builder="agy", simulate=False)` has no reviewer param (`:1279`); `proc` is assigned at `:1374`; `task_name` at `:1336` | **Accepted.** Directive-seeding dropped entirely; only the override block is deleted |
| **B4** — a PreToolUse hook is not a merge choke point | A tool call launching `express.py` need not contain `gh pr merge`; its subprocesses are not separate tool calls | **Accepted.** Hook demoted to a supplement; enforcement moved to server policy + a shared check at owned callers |
| **B5** — marathon has its own terminal consumers | `satisfied_lane_terminal()` (`marathon_drive.py:2677-2698`) and recovery at `:3218-3222` accept terminal STATUS with `_actor` discarded | **Accepted.** Phase 1 extends to these consumers |
| **F1** — the four red controls lack exact oracles | Reasoning accepted as written | **Accepted.** Each control now names entrypoint, exit code, reason string, and evidence destination |
| **F2** — inventory wrong; frozen-twin edit unnecessary | `marathon_drive.py:2801` also emits the directive, so "only marathon-drive.sh" was false; `test/gh308-frozen-twin-guard.sh:49-64` selects changed paths even for comments | **Accepted.** Claim corrected; `relay-drive.sh:32` edit dropped |

**Rejected: none.** Two corrections to Codex's own text, neither changing a verdict: the fail-closed
*principle* was affirmed, not blocked (B1 blocks the mechanism, not the goal); and the relay-file
count discrepancy is a scope artifact — my 201 counted `relay-system/<date>/*.md`, its 261 counted
recursively. Both are stored-document counts and neither measures active traffic, which is Codex's
actual point and is conceded.

### The corrected trust anchor

The first plan called the in-file directive "authoritative, computed, unguessable." It is none of
those against a builder that edits it. The trust anchor must live outside anything a turn can write.

`.tick/events/` is that anchor: one append-only JSONL file per event, named
`<ts>-<agent>-<verb>-<task>.jsonl`, written by `tick` itself and **not** on any turn's allowlist:

```
{"schema_version":"0.2.0","ts":"...","type":"task.created","task":"RELAY-gh505-plan-qa","agent":"claude-a"}
```

So "who held the token when the terminal STATUS appeared" is answerable from evidence the reviewed
party cannot forge. Combined with an explicit reviewer identity passed to the driver at invocation —
`relay_drive.py` currently has **no** `--builder`/`--reviewer` argument, confirmed — the terminal
decision becomes attributable without inventing a receipt subsystem.

## Implementation

Phase order changed: the override deletion moves **first**, per B3/Codex answer 3. Phase 1's
protection is meaningless while jog discards its exit code.

### Phase 0 — delete the jog override

Delete `jog_run.py:1375-1387` — **the override block only**. Line `:1374`
(`proc = subprocess.run(cmd, cwd=root, env=env)`) stays; the function ends `return proc.returncode`.
Deleting through `:1374` as the first plan said would have removed the assignment and orphaned the
`except`.

Nothing is seeded into the relay file here. `run_single_phase_drive` has no reviewer parameter and
no reviewer dispatch; adding a comment cannot create one, and building a second two-agent path in a
builder-only function is exactly the duplicate subsystem this repo forbids. Whether legacy jog should
gain a reviewer at all is **out of scope** and named as an open question below.

**Acceptance** — `test/gh505-jog-no-override.sh`: stub the driver to exit 4 while leaving
`STATUS: Approved`; assert `run_single_phase_drive` returns exactly 4. Red control: returns 0 at
`0b37c36f`. Stubbing the driver (not the relay file) is what makes the control fail for the right
reason.

### Phase 1 — attribute the terminal status to a trusted actor

1. Add `--reviewer <agent>` to `relay_drive.py`, supplied by the invoker, not read from the relay file.
2. Add `terminal_actor(task)` reading `.tick/events/` for the last `claimed`/`released` event on the
   task, returning the agent that held the token when the terminal STATUS appeared.
3. Gate **all three** success sites — `:571-579`, `:830-833`, `:868-873` — on that actor equalling
   `--reviewer`.
4. On mismatch or unprovable attribution: **no auto-repair.** Exit non-zero with reason
   `terminal-by-non-reviewer` or `terminal-role-unprovable`. The first plan's "restore STATUS, point
   NEXT at the reviewer, continue" does not hand off the token — dispatch reads token state, not
   `NEXT:` — so it would either re-dispatch the builder or hit a token-state escalation.
5. Apply the same rule to marathon's consumers: `satisfied_lane_terminal()` (`:2677-2698`), and the
   recovery sites at `:3218-3222` and `:3294-3298`.
6. Where `--reviewer` is absent (every existing caller), attribution is unprovable → escalate. This
   is the fail-closed choice, and it now rests on unforgeable evidence rather than an editable comment.

**Runtime boundary, stated honestly:** this is a Python-side fix. The frozen shell twin
`relay-automation/relay-drive.sh` is unchanged and retains the old behavior. Lanes running the shell
driver are **not** protected by this PR. Named as a limitation in the PR, not papered over.

**Acceptance** — `test/gh505-relay-terminal-role.sh`, driving the real `relay_drive.py` entrypoint
with a fake turn, asserting the exact exit code and reason string, and proving the terminal branch
was reached (not a setup/lock/shim error):
- builder holds token, writes `Approved` → `terminal-by-non-reviewer`, non-zero. **Red at `0b37c36f`.**
- reviewer holds token, writes `Approved` → exit 0, at an ordinary turn **and** at final-cap.
- review-once mode, both roles.
- terminal at startup/resume before any turn → unprovable.
- directive tampered to name the builder as reviewer → still refused (proves the anchor is the event
  log, not the file).
- no `--reviewer` supplied → unprovable, not silent success.

Evidence: red/green transcripts committed to `TESTS-RESULTS/2026-09-08+GH-505/`.

### Phase 2 — take the Approved clause out of the shared prompt

`relay-turn-lib.sh:1011`: remove `(or done + set STATUS: Approved when approving)` from the shared
`printf`; add it to the reviewer `role_note` at `:994-1000`.

**Dropped from the first plan:** the `relay-drive.sh:32` comment edit. It touches a frozen twin, and
`test/gh308-frozen-twin-guard.sh:49-64` selects changed paths even for a comment-only change.

**Acceptance** — `test/gh505-prompt-role-split.sh`: assert both rendered prompts are non-empty and
carry their role-specific text, then assert only the reviewer's contains `STATUS: Approved`. Red
control: both contain it at `0b37c36f`.

### Phase 3 — enforce a review requirement at a real merge boundary

The hook-only design is withdrawn. A PreToolUse hook matches model tool calls; `express.py` invoking
`gh pr merge` in a subprocess is not one, so the hook fails open even when installed.

1. **Server policy is the universal boundary.** Branch protection on `development` requiring one
   approving review. Not a code change, not revertable by `git revert` — landed as an explicit
   operator action, separately, after the code.
2. **Shared check at owned callers** as the local enforcement that ships in this PR: one
   `require_approving_review(pr)` helper called by `express.py:599`, `marathon-closeout.sh:292`,
   `jog_run.py:1432`, `skills/merge-cleanup/scripts/merge_cleanup.py:55-56`. Several callers of one
   function is still DRY; four copies of the logic would not be.
3. The helper fails closed on unavailable or malformed `gh` output, and needs author and approver
   identities — `--json reviewDecision` alone does not supply them.
4. A PreToolUse hook may supplement this later. It is not the boundary.

**Open gap, stated not solved:** a relay approval by `codex` is not a GitHub review by a distinct
GitHub actor. This PR does not bridge those identities, so the merge check enforces "a GitHub review
by someone other than the author" — which automation cannot currently satisfy on its own. That is the
honest consequence and it belongs in the PR body, not in a claim that automation still flows.

**Acceptance** — `test/gh505-merge-review-gate.sh`: call `require_approving_review` directly with
representative inputs and assert whether the merge side effect is reached; include malformed and
unavailable `gh` output as fail-closed cases. Red control: the merge proceeds at `0b37c36f`.

## Dependencies and ordering

Phase 0 → 1 (hard: the override discards Phase 1's exit code). Phase 2 independent. Phase 3
independent of 0–2 and the only defence for a merge that never went through a relay.

## Risks and rollback

| Risk | Mitigation |
|---|---|
| Fail-closed escalation on every caller that passes no `--reviewer` | Real and intended. Scope is *active launchers*, not the 201-file document count — that count is being replaced with a measured inventory of live callers before Phase 1 lands. |
| Rollback reopens the integrity hole | Stated explicitly. Revert is not a neutral action here. |
| Shell twin lanes stay unprotected | Named as a limitation in the PR. |
| Branch protection blocks an automated lane that cannot produce a GitHub reviewer | Landed separately, operator-approved, after the identity gap above is understood. |

## Open questions carried to round 2

1. Should legacy `run_single_phase_drive` gain a reviewer, or should reviewed work route through the
   marathon executor that already has one?
2. What is the measured count of *active* callers that would begin escalating?
3. Is the relay-approval → GitHub-review identity bridge in scope for a follow-up issue?

## Re-rating

Effort revised **55 → 40** (lower = more expensive). The corrected write-set adds the tick-event
attribution reader, three marathon consumers, a shared merge helper at four callers, and six Phase 1
fixtures. Severity 85 and appeal 50 unchanged and affirmed by review. Priority 85 held as a
severity-led judgment, with the companion report's defect counts explicitly uncounted and claiming no
trend. New rating: **85/85/50/40**.

## Verification

Full `./validate.sh` in a **separate disposable clone**, never this task clone. Every red control
demonstrated red at `0b37c36f` before its fix, with transcripts committed to
`TESTS-RESULTS/2026-09-08+GH-505/`. Implementation-time failures route through `/debug-mantra`.
