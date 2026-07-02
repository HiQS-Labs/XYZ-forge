# RELAY · GH-75 XYZ.json completion telemetry — plan review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 5

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real files / the latest `git show <last commit>` diff; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here. **Before you set `Approved`, re-read the artifact file itself** (not this log) and confirm every prior `Implemented` fix is actually present and complete — any that is missing or partial → set `Changes requested` with a `[Blocker] claimed-implemented-but-absent @ file:line` instead. For a doc artifact this file check is the only backstop there is.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work. **Before you flip `NEXT`, re-read the artifact and confirm each `Implemented → @ file:line` actually landed in the file** — cite the line as it appears in your commit diff. A claim you can't point to in the file is not done.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`. (Need the exact shape? Mirror the most recent block of the other role above.)
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (artifact + this log): `git commit -m "relay(<slug>): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line and `git commit --amend --no-edit`. Push if the team shares a remote.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

## Setup
- Artifact under review: PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md
- Definition of Done: The three harness hook points, the double-emission fix, the record schema, the lock-protected prepend mechanics, and the phase breakdown are sound (or every gap is named as a concrete, actionable finding) before this plan is filed as a GitHub issue.
- Producer: Claude   ·   Reviewer: agy
- Handoff: cli-driven (agy)
- Started: 2026-07-01

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound (records what was verified, not assumed). Answer the Producer's "Re-review this" questions in an `Answers:` block.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(<slug>): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.
10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:` (what it ran / skipped / couldn't run); the Reviewer logs a verdict `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run) — and classes any prior fix `textually fixed` vs `behaviorally proven`. An `Approved` can't silently mean "looked fine on read": if correctness rides on runtime behavior and nothing ran, `textual only` is the strongest honest verdict. Scales to the artifact — a pure doc answers `N/A — non-executable artifact`.
11. **Reconcile claims against the file, not this log.** A disposition is a claim until the artifact proves it. The Producer, before flipping `NEXT`, re-reads the artifact (or `git show <its commit>`) and confirms each `Implemented → @ file:line` actually landed — citing the line as it appears in the commit diff. The Reviewer, before it may set `Approved`, re-reads the **artifact itself** and confirms every `Implemented` finding is present and complete; any missing or partial one flips the verdict to `Changes requested` with a `[Blocker] claimed-implemented-but-absent @ file:line`. For a non-executable artifact (design-spec / plan doc) this file check is the only backstop — so the closing approval is never granted on the log's word alone.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · 2026-07-01 00:00 PT
**Did:**
- Researched prior art (GH-24 `extract-relay-telemetry.sh`, closed 2026-06-30) and confirmed no existing auto-append-at-session-end mechanism exists in the repo today
- Read the actual terminal points in all three harnesses: `relay-drive.sh:208-209`, `marathon.sh:95` (+ halt path `marathon.sh:83-88`), and confirmed `swarm-preflight.sh` never executes — it hands off to `marathon-drive.sh`
- Wrote the full plan at `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`: hook points, an `XYZ_HARNESS_CONTEXT` flag to stop `marathon-drive.sh`'s internal per-phase relay loop from double-emitting, a schema extending GH-24's `{health, title, description, updatedAt}` with `{harness, sessionId}`, a locked read-modify-write-prepend to a gitignored `XYZ.json`, and a 3-phase build breakdown

**Review this:**
- Is the `XYZ_HARNESS_CONTEXT` env-var flag the right mechanism to stop `marathon-drive.sh`'s internal relay loop from emitting its own `harness:"relay"` record per phase, or is there a cleaner way to distinguish "standalone relay" from "relay nested inside a marathon phase"?
- Marathon health mapping only has `green` (all phases approved) and `red` (halt-on-first-failure) — is there a real `orange` case worth designing for now (e.g. `Escalated` mid-chain), or is deferring it correct?
- Is reusing the GH-72 `mkdir`-based advisory lock appropriate for `XYZ.json`'s concurrent-write problem, or does a JSON-array-of-N-growing-records change the risk profile (e.g. lock hold time growing with file size)?
- Is the Phase 1/2/3 split buildable/testable independently, or does Phase 2 (marathon+swarm) actually need to land before Phase 1 (relay) is safe to ship alone?
- Any gap in the schema, the gitignore-not-git-tracked call, or the phase/QA-gate checklists?

**Verification:** N/A — non-executable artifact (design/plan doc; no code written yet)
**Open questions:** see "Review this" above
**Commit:** 81071b9

### Round 1 · Reviewer · agy-findings · 2026-07-01 20:35 Local

**Verdict:** Changes requested
VERDICT: FAIL
Basis: static review (non-executable design/plan doc)

**Answers to "Review this":**
1. The `XYZ_HARNESS_CONTEXT` env var context flag is a clean and lightweight approach to passing the execution state down the process hierarchy without modifying CLI signatures.
2. Deferring the `orange` health case for marathon runs is correct for now; a binary green/red health outcome aligns well with the existing marathon halt-on-first-failure logic.
3. Reusing the `mkdir`-based advisory lock from GH-72 is appropriate, but we recommend implementing atomic file replacement (write temp file + rename) to safeguard `XYZ.json` from corruption during aborts.
4. Yes, Phase 1's shared writer and relay hook can be built and tested independently using a standalone relay run before Phase 2 is introduced.

**Findings & proposals:**
- [Blocker] Swarm runs will not emit telemetry if `marathon-drive.sh` lacks a completion hook: The plan specifies that swarm runs are invoked via `marathon-drive.sh` directly (not `marathon.sh`), and that `marathon-drive.sh` sets `XYZ_HARNESS_CONTEXT=marathon-phase` around its internal relay loop. This prevents `relay-drive.sh` from writing to `XYZ.json`. However, the plan only wires completion hooks into `relay-drive.sh` and `marathon.sh`, leaving `marathon-drive.sh` without a hook. Thus, swarm runs will not emit any telemetry. To fix this, `marathon-drive.sh` must also have a completion/halt hook that fires when `XYZ_HARNESS_CONTEXT=swarm`.
- [Should] Standalone relay telemetry misses failure/escalation outcomes: The plan only wires the telemetry hook into the successful exit path of `relay-drive.sh` (lines 208-209), meaning any standalone relay runs that end in `Escalated` (exit 4/5 by design) or stall/cap-exceeded (exit 3/4) will not emit any telemetry to `XYZ.json`. Since marathon runs log both green and red (halt) outcomes, standalone relays should similarly log non-green outcomes to ensure telemetry completeness.
- [Should] Clarify how `marathon.sh`/`swarm-preflight.sh` generates `title` and `description`: The schema requires `title` and `description`. For a standalone relay, these are extracted from the relay file's markdown headers. But for a marathon or swarm run, there is no single markdown file to extract them from. The plan should specify how `marathon.sh` and `swarm-preflight.sh` will construct these values (e.g., using the top-level plan name for `title` and phase counts/exit codes for `description`).
- [Should] Explicitly include `XYZ_HARNESS_CONTEXT=swarm` in the generated command in `marathon-invocation.txt`: The plan states that `swarm-preflight.sh` sets `XYZ_HARNESS_CONTEXT=swarm` to propagate it to `marathon-drive.sh`. Since `swarm-preflight.sh` is a non-executing planner and the operator executes the run manually via the command in `marathon-invocation.txt`, this environment variable must be explicitly prefixing the command written to `marathon-invocation.txt` (e.g., `XYZ_HARNESS_CONTEXT=swarm relay-automation/marathon-drive.sh ...`).
- [Nit] Clarify which repo root contains `XYZ.json` during cross-repo runs: When running with a foreign `--target-root` (cross-repo run), it should be explicitly stated whether `XYZ.json` is written to the harness repository root or the target repository root. (Telemetry is usually collected in the harness repository root where execution is driven).
- [Nit] Use atomic file replacement when writing `XYZ.json`: To prevent `XYZ.json` corruption if the runner is killed or crashes mid-write, the Python script should write the updated JSON array to a temporary file in the same directory and then atomically rename/move it over `XYZ.json` (e.g., using `os.replace` in Python).

**Commit:** pending (harness-committed)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
