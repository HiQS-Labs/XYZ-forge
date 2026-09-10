# GH-505 / GH-509 / GH-510 — recorded negative controls

Test:     `test/gh505-relay-attest.sh` (TEST_SOFT_FAIL=1)
Baseline: `a6441b9b` — `origin/development` before the fix; the suite re-extracts it with
          `git archive` into a second fixture harness and drives it with the SAME stub
          shim/agent, minus the flags the base driver does not have (`--reviewer`, `--builder`)
Date:     2026-09-08

## What is asserted, and how each control is observed red

A check never seen failing is decorative (AGENTS.md §6), so every guard below is paired with the
run that goes the other way. The base driver cannot take `--reviewer` (it rejects unknown flags
with exit 2 — `relay_drive.py:55-56` at base), so "red at base" is the base driver invoked
without the new flags, not the fixed driver with a mutation.

| Guard | Fixed driver | Base driver (`a6441b9b`) | Where |
|---|---|---|---|
| A — builder-role turn writes `STATUS: Approved` | exit 4 `forged-terminal`, STATUS reverted on disk and in HEAD, no record | **exit 0** — the forgery is accepted | `RED CONTROL A` |
| C — file already `Approved` at startup, token done, no turn | exit 4 `unattested-terminal` | **exit 0** after 0 turns | `RED CONTROL C` |
| B4 — peer commit lands during the turn | worktree cut at the pinned revision; `candidate_ok` refuses the drifted HEAD | base cuts at live HEAD (`rtl_worktree_begin` used `HEAD`); no candidate check exists | asserted in-suite (`wt-cut-*` capture) |
| I2 / I3 — jog merge refused / no PR (GH-510) | `(False, "parked", …)` | base returned `(True, "completed", None)` — **source comparison** (`jog_run.py:1467-1471` at base), not an executed base run | in-suite (fixed side only) |
| J — jog override | driver exit 4 returned unchanged | base returned 0 when the file said Approved — **source comparison** (`jog_run.py:1375-1389` at base) | in-suite (fixed side only) |
| H — marathon consumers | covered by the shipped marathon suites re-pointed at the attestation (see below) | | |

Guards that are NOT red at base and are recorded as positive controls: B, B5, K1 (the shim closes
the token), L (reader refusals are new code with no base counterpart).

Marathon (`H`) is covered by the shipped suites rather than a new fixture: every stub relay-drive
in `test/marathon-drive.sh`, `test/gh280-jog-marathon-adapter.sh`, `test/gh385-*`, `test/gh491-*`,
`test/gh387-*`, `test/gh438-*`, `test/gh378-*`, `test/gh390-*`, `test/gh407-*`, `test/gh457-*`,
`test/gh319-*`, `test/gh399-*`, `test/xyz-harness-hooks.sh` and `test/marathon.sh` had to start
publishing an attestation (`test/lib/attest-stub.sh`) before marathon would report success again.
That is the H1/H2/H4 red control, observed across the whole suite on the first gate run of this
branch (19 failures in `test/marathon-drive.sh` alone, every one `exit 4` with
`relay is terminal (STATUS: Approved) but NOT attested by relay-drive`).

## Observed run — fixed driver, with the base-driver controls inline

```
== test: gh505-relay-attest ==
  PASS: A: the stub builder turn really ran through codex-turn
  PASS: A: builder-written Approved → driver exits 4
  PASS: A: escalation reason is forged-terminal
  PASS: A: STATUS restored on disk
  PASS: A: STATUS restored in HEAD (revert committed)
  PASS: A: revert commit is the driver's
  PASS: A: no attestation trailer
  PASS: A: no record written
  PASS: A2: failed turn keeps the shim's exit 5 (not 4)
  PASS: A2: reason still names the forgery
  PASS: A2: forged STATUS reverted in HEAD on the failure path
  PASS: A2: no record
  PASS: A3: failed reviewer turn keeps the shim's exit 5
  PASS: A3: reason is failed-turn-terminal
  PASS: A3: the failed turn's Approved reverted in HEAD
  PASS: A3: no trailer, no record
  PASS: B: reviewer approval → driver exits 0
  PASS: B: attestation trailer appended
  PASS: B: reviewed-head = HEAD before dispatch
  PASS: B: the isolated worktree was cut at the pinned revision
  PASS: B: reviewed-head is the parent of the shim's commit
  PASS: B: record loads for reviewer rev; digest = sha256(exactly the appended bytes)
  PASS: B4: approval still attested (the reviewer read the pinned revision)
  PASS: B4: reviewed-head is the PRE-dispatch revision, not the peer commit
  PASS: B4: control — HEAD had already moved when the shim started
  PASS: B4: worktree cut at the pin even though HEAD moved before the cut
  PASS: B4: candidate_ok REFUSES the HEAD that carries the peer's source change
  PASS: B5: harness's uncited-claim downgrade does not read as a body rewrite; approval attested
  PASS: B5: the downgrade really happened (control)
  PASS: B5: record still loads after the downgrade
  PASS: B6: appended citation changes the harness's judgement of an OLD line without reading as a rewrite
  PASS: B6: control — the old claim stayed un-stamped (the awk saw the new citation)
  PASS: B7: CRLF relay file attested
  PASS: B7: record loads on the CRLF file
  PASS: C: pre-approved file → unattested-terminal (exit 4)
  PASS: C: no turn dispatched
  PASS: D1: STATUS-only approval → empty-approval
  PASS: D3: rewritten body → review-body-rewritten
  PASS: D3: no record
  PASS: E2: no --reviewer → warned at startup; the approval is refused as forged (no reviewer can exist)
  PASS: E2: no record
  PASS: E3: builder == reviewer → exit 2
  PASS: S1: RELAY_WORKTREE_ISOLATION=false refused before dispatch
  PASS: S1: no turn dispatched
  PASS: K1: the shim closes the token for a terminal reviewer turn; approval attested
  PASS: K2: bare agent-cmd leaves the token claimed → close-mismatch, not attested
  PASS: K2: no record
  PASS: L: fixture approval attested
  PASS: L: reader refuses wrong reviewer / edited STATUS / edited review text / truncated record
  PASS: N3: neighbouring source drift refused; relay-only and ESCALATION.md-only changes pass
  PASS: F: RELAY_ROLE=reviewer outranks a directive that calls the agent builder
  PASS: F: RELAY_ROLE=builder outranks a directive that calls the agent reviewer
  PASS: F2: without RELAY_DRIVER_LOCKED the directive still decides
  PASS: F: same answer through the rtl.py bridge (allowlist narrows to the relay file for a reviewer)
  PASS: G: both prompts render non-empty
  PASS: G: builder prompt does not invite STATUS: Approved
  PASS: G: reviewer prompt carries the approval instruction
  PASS: I/J: jog landing parks on merge failure, missing PR, drifted candidate; merges with --match-head-commit; no driver override
  PASS: RED CONTROL A: base driver (a6441b9b) exits 0 on a BUILDER-written Approved
  PASS: RED CONTROL C: base driver exits 0 on a pre-approved file after 0 turns
```

The two `RED CONTROL` lines are the base driver being **observed** accepting the forgery and the
pre-approved file — the exact behaviours #505 reports — on the same fixture, in the same run. The I/J
rows above are source comparisons against the base code, not executed base runs; the H row is the
observed first-gate breakage. The H4 second-bind mutation control is recorded below.

## Deviations from the reviewed plan, recorded here so final QA can judge them

- `--reviewer` missing is a **loud warning**, not an exit-2 refusal (plan said refuse; round-1 QA
  said "preferably"). Reason: dozens of shipped suites and every vendored `.xyz/` copy drive
  non-terminal relays without it; refusing strands them for no safety gain — without a reviewer
  the driver still cannot accept any terminal status (E2 pins that a "no reviewer" approval is
  reverted as forged).
- `canonical()` also applies the harness's own uncited-claim downgrade (GH-173 B3) so the
  shim's in-place `[Unverified — no citation]` stamp is not read as a reviewer rewrite (B5).
- `candidate_ok` also excludes marathon's two named phase records beside the relay file
  (`ESCALATION.md`, `PHASE-INTERRUPTED.md`) — never the directory (final-QA round 1 B2; N3).
- A turn whose shim returned non-zero is reverted whatever its role and never attested
  (final-QA round 1 B1; A3). Jog's landing requires the token to read `done` (F1; I0).
- Marathon binds the candidate **twice** on the success path: before the approved event is
  published (so a drifted candidate never becomes an approved receipt) and again after the
  post-approve command (which may move HEAD); the receipt carries the second, `reviewed_candidate`.

## H4 — second-bind mutation control (observed)

`utils/py/marathon_drive.py` with the post-approve bind replaced by `pass` (mutation applied and
reverted in the task clone; `git diff --quiet` confirmed the restore), `test/marathon-drive.sh`
under `TEST_SOFT_FAIL=1`, 2026-09-08:

```
# MUTATION — post-approve bind disabled
  FAIL: H4: exit=0 (expected 4)
  FAIL: H4: ESCALATION.md missing the reason
  PASS: H4: control — the hook really committed source (the SECOND bind is what refused)
  FAIL: H4: refusal not attributed to the post-approve bind
  FAIL: H4: receipt approved or missing: {
  FAIL: H4: a green completion line was emitted

# RESTORED
  PASS: H4: post-approve source commit → exit 4 (approval not bound to the final candidate)
  PASS: H4: escalation names candidate-drifted-from-reviewed-head
  PASS: H4: control — the hook really committed source (the SECOND bind is what refused)
  PASS: H4: the refusal came from the post-approve bind, after the approved event
  PASS: H4: receipt is not approved and carries no validated candidate
  PASS: H4: no green completion was emitted
```

With the second bind gone the hook's source commit is accepted as an approved run (exit 0,
approved receipt, green completion emitted); with it restored the run refuses, the receipt is not
approved, and the refusal is attributed to the post-approve bind. The first bind alone does not
catch this — the hook runs after it.
