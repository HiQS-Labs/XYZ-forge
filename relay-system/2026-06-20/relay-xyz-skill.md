# RELAY · relay-xyz skill review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real files / the latest `git show <last commit>` diff; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here. **Before you set `Approved`, re-read the artifact file itself** (not this log) and confirm every prior `Implemented` fix is actually present and complete — any that is missing or partial → set `Changes requested` with a `[Blocker] claimed-implemented-but-absent @ file:line` instead. For a doc artifact this file check is the only backstop there is.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work. **Before you flip `NEXT`, re-read the artifact and confirm each `Implemented → @ file:line` actually landed in the file** — cite the line as it appears in your commit diff. A claim you can't point to in the file is not done.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`. (Need the exact shape? Mirror the most recent block of the other role above.)
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (artifact + this log): `git commit -m "relay(relay-xyz-skill): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line. Do **not** push.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

## Setup
- Artifact under review: `skills/relay-xyz/SKILL.md`
- Definition of Done: A repo-portable Claude skill that routes agents to THIS repo's shipped `relay-automation/` harness — no hardcoded machine paths, accurate script names / env / exit codes, and a clear boundary vs the portable `/relay` skill.
- Producer: Claude (claude-a)   ·   Reviewer: Codex (codex)
- Handoff: cli-driven (codex)   <!-- driven by relay-automation/relay-drive.sh + codex-turn.sh -->
- Started: 2026-06-20

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents are different tools (Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top.
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding: `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound. Answer the Producer's "Re-review this" questions in an `Answers:` block.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved**. To get proposals actioned in-thread set `Changes requested`, not `Approved`. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(relay-xyz-skill): <role> r<N>`, then fill the hash into your `Commit:` line. No push.
9. **One actor at a time, clean tree at every handoff.** The `RELAY-TURN` tick token is the lock. Never flip `NEXT` with uncommitted changes in the tree.
10. **Evidence contract — state your proof every turn.** The artifact here is a non-executable doc, so the honest basis is `textual only` / `N/A — non-executable artifact`. The one backstop is reconciling claims against the file, not this log.
11. **Reconcile claims against the file, not this log.** The Producer confirms each `Implemented → @ file:line` actually landed; the Reviewer, before `Approved`, re-reads the artifact itself and confirms every `Implemented` finding is present and complete.

## Roles
- **Producer** — Claude. The only writer of the artifact: builds it, requests review, decides and implements proposals, updates.
- **Reviewer** — Codex. Reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · claude-a · 2026-06-20 09:09 PDT
**Did:** Wrote `skills/relay-xyz/SKILL.md` — a repo-specific skill that routes agents to the shipped `relay-automation/` harness instead of improvising the handoff. Resolves the repo root at runtime (`git rev-parse --show-toplevel`) so no machine path is hardcoded; documents `relay-drive.sh` + `codex-turn.sh`/`agy-turn.sh`/`poll.sh`, both shims' env contract, all exit codes, the sandbox/auth gotchas, the safety boundary, and the relationship to `/relay`, `/xyz`, and `consult.sh`.
**Review this:** (1) **Portability** — is there any hardcoded absolute path, or any place the repo-root resolution could silently pick the wrong root? (2) **Accuracy** — do the script names, flags, env var names (`CODEX_AGENT`/`AGY_AGENT`, `ALLOW_PATHS`, `CODEX_FLAGS`, `AGY_MODEL`, `RELAY_TURN_TIMEOUT_S`), and exit codes match the actual scripts under `relay-automation/`? (3) **Boundary** — is the split between `/relay` (scaffold + protocol) and `relay-xyz` (drive the harness) clear and non-duplicative? (4) **Safety** — is the "run the shim outside the Bash sandbox" guidance correct and prominent enough?
**Verification:** N/A — non-executable artifact. Cross-checked names/flags/exit codes against `relay-automation/README.md`, `QUICKSTART.md`, `relay-drive.sh`, `codex-turn.sh`, `agy-turn.sh` headers while writing; no commands run.
**Open questions:** Is anything in the env table or exit-code list stale vs the current scripts? Flag any drift.
**Commit:** 6765ef4

### Round 1 · Reviewer · codex · 2026-06-20 09:14 PDT
**Verdict:** Changes requested
**Findings & proposals:**
- [Blocker] `skills/relay-xyz/SKILL.md:113-125,151` documents the all-Claude `/loop` path as "no human nudge" and lists `poll.sh` decisions as `run-runner|run-watchdog|stop|idle`, but the recipe omits `--claude-agents`. In the shipped poller, an open handoff to another agent not listed in `--claude-agents` becomes `DECISION: nudge-cross-model`, not idle (`relay-automation/poll.sh:48-50,138-143,162-165,188-214`). Proposed fix: add `--claude-agents "claude-a,claude-b"` to the Path B command and document `nudge-cross-model` explicitly, or tightly scope the decision list to the fully-Claude case after that flag is present.
- [Should] `skills/relay-xyz/SKILL.md:161-166` says "Verify the harness is green" but only exercises `test/codex-turn.sh` even though the skill presents `agy-turn.sh` as a first-class reviewer path (`skills/relay-xyz/SKILL.md:62,96,132-140`; shipped test: `test/agy-turn.sh`). Proposed fix: either scope the section to "before a Codex run" or add the agy shim test alongside the Codex one.
- [Pass] Portability / boundary / safety are otherwise sound: repo root is resolved at runtime (`skills/relay-xyz/SKILL.md:45-56`), the `/relay` vs `relay-xyz` split is clear (`skills/relay-xyz/SKILL.md:18-25,170-179`), and the unsandboxed shim warning matches the current Codex/agy shims (`skills/relay-xyz/SKILL.md:98-103`; `relay-automation/codex-turn.sh:63-68`; `relay-automation/agy-turn.sh:37-41,104-110`).
**Answers:**
- (1) Portability: no hardcoded machine path found; repo-root resolution is correct.
- (2) Accuracy: script names, env names, and most exit codes align; the poll recipe/decision set above is the material drift.
- (3) Boundary: clear and non-duplicative as written.
- (4) Safety: the "run outside the Bash sandbox" warning is correct and prominent enough.
**Evidence:** textual only / N/A — non-executable artifact. Re-read `skills/relay-xyz/SKILL.md` and cross-checked against shipped `relay-automation/*.sh` + `QUICKSTART.md`; no git used per operator constraint.
**Commit:** N/A — operator forbade git for this turn.

### Round 2 · Producer · claude-a · 2026-06-20 09:16 PDT
**Decisions on proposals:** (each finding independently verified against the real scripts before disposing)
- [Blocker] Path B omits `--claude-agents`; decision list missing `nudge-cross-model` — **Implemented** → (a) added `--claude-agents "claude-a,claude-b"` to the Path B `/loop` recipe and a load-bearing note that an out-of-list turn yields `DECISION: nudge-cross-model`, not idle; (b) corrected the `poll.sh` exit-code line to `run-runner | run-watchdog | nudge-cross-model | stop | idle` @ `skills/relay-xyz/SKILL.md` Path B recipe + Exit codes. · Proof: verified `relay-automation/poll.sh:20` (decision set), `:48` (`--claude-agents`), `:189` (`nudge-cross-model` on non-Claude actor) — finding confirmed true, fix matches source.
- [Should] Verify section only ran the Codex shim test though agy is first-class — **Implemented** → added `bash test/agy-turn.sh` next to the Codex test and scoped each to its reviewer @ `skills/relay-xyz/SKILL.md` "Verify the harness is green". · Proof: `test/agy-turn.sh` exists (6.9K) alongside `test/codex-turn.sh`.
- [Pass] Portability / boundary / safety — acknowledged, no change.
**Did:** Verified both findings against `poll.sh` and `test/` first (Codex's `file:line` cites were accurate), then applied the two edits. No other changes.
**Verification:** N/A — non-executable artifact. Re-read the two edited sections and reconciled the documented decision set against `relay-automation/poll.sh:20,48,189`; confirmed `test/agy-turn.sh` present.
**Re-review this:** The two edited sections only — (1) the Path B recipe + the `poll.sh` decision line: does the decision set and the `--claude-agents`/`nudge-cross-model` semantics now match the shipped poller? (2) the verify section. Nothing else in the skill changed.
**Commit:** 43ed650

### Round 2 · Reviewer · codex · 2026-06-20 09:17 PDT
**Verdict:** Approved
**Findings & proposals:**
- [Pass] The prior Blocker is fully fixed in the artifact itself: Path B now includes `--claude-agents "claude-a,claude-b"` and explains the `nudge-cross-model` fallback, matching `relay-automation/poll.sh`'s current relay-mode behavior. Verified at `skills/relay-xyz/SKILL.md:112-129` against `relay-automation/poll.sh:20,48-50,162-165,188-189`.
- [Pass] The prior Should is fully fixed in the artifact itself: the verify section now includes both `bash test/codex-turn.sh` and `bash test/agy-turn.sh`, scoped to the matching reviewer path. Verified at `skills/relay-xyz/SKILL.md:169-177`.
- [Pass] Full-file reread found no new doc drift against the Definition of Done: runtime repo-root resolution remains portable (`skills/relay-xyz/SKILL.md:39-56`), the `/relay` vs `relay-xyz` boundary stays clear (`skills/relay-xyz/SKILL.md:18-25,180-189`), and the unsandboxed shim warning remains explicit (`skills/relay-xyz/SKILL.md:98-103`).
**Answers:**
- (1) Yes. The Path B recipe, `--claude-agents` semantics, and documented decision set now match the shipped poller.
- (2) Yes. The verify section now covers both first-class reviewer shims.
**Evidence:** textual only / N/A — non-executable artifact. Re-read `skills/relay-xyz/SKILL.md` itself and reconciled the claimed `Implemented` fixes against the file, then cross-checked the referenced `poll.sh` behavior and test filenames.
**Commit:** N/A — operator forbade git for this turn.

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
