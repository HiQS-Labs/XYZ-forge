# RELAY · GH-238 J1: fail-fast pre-advance gate + document the default
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-18.
-->

NEXT: —
STATUS: Approved
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh238-preadvance-gate): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifacts (Producer may create/edit ONLY these):
  - `relay-automation/marathon-drive.sh` — the fail-fast check
  - `relay-automation/MARATHON.example.yaml` — document the gate default
  - `test/marathon-drive.sh` — regression coverage
- Source of truth: [`PROJECT/2-WORKING/GH-238-MARATHON-PREADVANCE-GATE-DEFAULT.md`](../../PROJECT/2-WORKING/GH-238-MARATHON-PREADVANCE-GATE-DEFAULT.md)
- Reviewer: agy   ·   Producer: codex
- Started: 2026-07-18
- Lane: J1 of [MARATHON-PLAN-2026-07-18-J](../../PROJECT/2-WORKING/MARATHON-PLAN-2026-07-18-J-VENDORED-CONSUMER-DX.md). J2 (#239) already landed and is Approved — do not revisit it.

> **Note on how this lane is driven.** The artifact here IS `marathon-drive.sh`, so this relay is
> driven by `relay-drive.sh`, never by `marathon-drive.sh` itself — the file being edited is not the
> file executing. Do not invoke `marathon-drive.sh` during your turn for any reason.

### The problem being solved

`marathon-drive.sh:376` defaults the pre-advance gate to `bash $ROOT/validate.sh` and never checks
the file exists. `:751` runs that gate only **after** `relay approved`. So in a consuming repo with
no `validate.sh` (the normal case for a vendored `.xyz/` install), a phase pays a **full builder
turn plus a full reviewer turn** and only then halts at exit 5. The failure is late and expensive,
and every consuming repo rediscovers it independently.

The gate is also probed on two recovery paths — `:662` (relay timed out, exit 7) and `:779` (relay
stalled, exit 3) — so a missing gate target degrades those too, not just the happy path.

### Definition of Done

1. After `ROOT` is resolved and `PRE_ADVANCE_CMD` is defaulted (`:376`), `marathon-drive.sh` verifies
   the gate command is actually runnable **before dispatching the first builder turn**, and exits
   immediately with an actionable message naming the resolved command, the reason, and
   `--pre-advance-cmd` as the remedy. The message must contain the literal phrase
   `pre-advance gate not runnable` (the lane's preflight probe greps for it).
2. The same guarantee covers the `:662` and `:779` recovery probes — either via the single startup
   check, or per-site. State in your turn block which approach you took and why.
3. `MARATHON.example.yaml` documents the gate default and when a consuming repo must override it.
   It currently never mentions gating at all.
4. `test/marathon-drive.sh` asserts the refusal happens **before turn 1** — not merely that it fails.
   A test that only checks a non-zero exit does not satisfy this.
5. Targeted tests green. **Do not run the full `validate.sh`** — its baseline is known non-green
   (#170 / #232) and running it can create files that trip containment and discard your turn.

### Explicitly NOT in scope

- **Do not silently skip the gate when its target is missing.** That trades a safety gate for
  convenience. Fail fast instead. This was considered and rejected in the capture doc.
- **Do not make the default mode-dependent** (a different default under a vendored `.xyz/` layout).
  An invisible, context-dependent default is the same failure class being fixed.
- Not fixing `validate.sh`'s own failing tests — that's #170 / #232.

### Constraints

- Your change lands under `relay-automation/`, so `relay-pkg.tar.gz` goes stale. Note it in your
  turn block; the orchestrator re-runs `skills/relay-automation/make-pkg.sh`.
- No push. Commit locally, file-scoped, per the turn protocol above.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Turn 1: codex (Producer) — RECOVERED, not self-reported

codex's turn was **killed by the turn timeout at 36m20s** (`relay-drive.sh:164`, `Terminated: 15`,
driver exit 144) while it was running `bash test/marathon-drive.sh` to verify its own work. It never
reached the handoff, so it never wrote a turn block and the shim never made its file-scoped commit.

The work itself was complete and intact in the abandoned isolation worktree
(`rtl-wt.OCUjFc`). The orchestrator extracted `git diff` from that worktree, confirmed it touched
**exactly** the three allowlisted artifacts and nothing else, removed the stray worktree
(`git worktree remove --force`), reaped the stuck `codex` claim, and applied the patch to the lane
branch. 84 insertions across the three files. No turn-block prose below is codex's — it did not
write any; the findings are the reviewer's reading of the code.

### Turn 2: claude-a (Reviewer)

**Verdict: Approved.** All four substantive DoD items met, verified by execution rather than by
reading the producer's claims (there were none to read).

- `[Pass]` **DoD 1 — fail-fast before turn 1.** `preflight_pre_advance_gate()` at
  `marathon-drive.sh:385-425`, invoked unconditionally at `:426`, after the default is resolved at
  `:376`. `die`s with `pre-advance gate not runnable: '<cmd>' (<reason>). Pass --pre-advance-cmd
  '<runnable command>' to override it.` — the required phrase plus the remedy.
- `[Pass]` **DoD 2 — recovery paths covered.** Handled via the single startup check: an unrunnable
  gate terminates the process before any phase begins, so `:662` (exit-7 timeout probe) and `:779`
  (exit-3 stall probe) are unreachable in that state. codex could not state its choice in a turn
  block (killed first), so this rationale is the reviewer's reconstruction from the code, not the
  producer's claim.
- `[Pass]` **DoD 3 — example documents the gate.** `MARATHON.example.yaml` gains a six-line block
  naming the default, the `--pre-advance-cmd` override with a worked `npm test` example, and the
  explicit note that a missing default fails fast "rather than being skipped".
- `[Pass]` **DoD 4 — asserts before turn 1, not merely non-zero.** Test case (13a) checks exit 2 AND
  the phrase AND the remedy AND **three independent negatives**: no `phases/p1/RELAY.md` rendered, no
  `relay-drive-args` (the stub records invocation), and no `MARATHON-P1-TURN` tick event. That is
  stronger evidence than the brief required.
- `[Pass]` **Gate green.** `bash test/marathon-drive.sh` → `112 pass, 0 fail`.
- `[Pass]` **Non-goals respected.** The gate is never silently skipped, and the default is not
  mode-dependent — one default plus a loud early failure, as the capture doc specified.
- `[Pass]` **Design point the brief did NOT ask for, and should have.** The probe is deliberately
  **non-executing**: `marathon-drive.sh:377-379` reasons that gates like `test -f build/output`
  only become true *after* the builder runs, so executing them at preflight would convert valid
  gates into false preflight failures. It checks syntax (`bash -n`), interpreter presence, and
  script-file existence instead. It also resolves relative paths against `${TARGET_ROOT:-$ROOT}`,
  so the cross-repo `--target-root` case is correct.
- `[Nit]` No turn block from the producer means no self-reported disposition trail for this lane.
  Recorded here instead; not worth a re-fire.

**Orchestrator follow-up:** `relay-automation/` changed, so `relay-pkg.tar.gz` is stale again —
regenerating after this commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
