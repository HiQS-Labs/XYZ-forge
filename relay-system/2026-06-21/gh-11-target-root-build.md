# RELAY · GH-11 Ask 1 — `--target-root` build (agy builds, Codex verifies)
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: —
STATUS: Escalated
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Build spec, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "not my turn."
3. **Do your role's work:**
   - **Producer (agy):** implement the Build spec below. Edit **only** the files in `ALLOW_PATHS` (+ this relay file). Cite `file:line`. After building, append your block with what you did and how you verified, then hand off to the Reviewer.
   - **Reviewer (Codex):** verify the Producer's diff against the Build spec / Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit any source file; only append findings here. **Before `Approved`, confirm the default (no `--target-root`) path is byte-for-byte unchanged and a test covers the foreign-root case.**
4. **Append ONE block** at the very bottom, above the marker. Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`. Producer: `**Did:**` + `**Verified:**` + `**Re-review this:**` + `**Commit:**`. Reviewer: `**Verdict:**` + `**Findings & proposals:**` + `**Commit:**`.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`); Producer bumps `ROUND` on a new cycle.
6. **Commit only the files you touched:** `git commit -m "relay(gh-11-target-root): <your-label> r<N>"`. Do **not** push. *(The harness commits for you in headless mode.)*
7. **Stop.** Tell the operator your one-line result.

## Setup
- Build target: GH-11 Ask 1 — add `--target-root` to the relay harness so Path A can review/build an artifact in a repo **other than** the harness clone. Capture: `PROJECT/1-INBOX/GH-11-CROSS-REPO-TARGETING.md`.
- Files in play (`ALLOW_PATHS`): `relay-automation/relay-drive.sh`, `relay-automation/relay-turn-lib.sh`, `test/relay-target-root.sh` (new).
- Producer: agy (agy)   ·   Reviewer: Codex (codex)
- Handoff: cli-driven   <!-- driven by relay-automation/relay-drive.sh + the turn shims -->
- Started: 2026-06-21

## Build spec (Definition of Done)
Mirror `consult.sh`'s `CONSULT_ROOT` pattern (`relay-automation/consult.sh:48`).

1. **`relay-drive.sh`:** accept `--target-root <dir>`. Default = the harness clone (today's behavior). Validate `<dir>` is a git repo (`git -C <dir> rev-parse` ok) or `die` with a clear message. Export it (e.g. `RELAY_TARGET_ROOT`) into the turn-taker env.
2. **`relay-turn-lib.sh`:** when `RELAY_TARGET_ROOT` is set, the worktree-isolation base, the `ALLOW_PATHS` resolution, and the file-scoped commit all operate against `RELAY_TARGET_ROOT` instead of the harness clone (the `rtl_init` / `cwd_wrap` / `rtl_enforce` path).
3. **Default unchanged:** with no `--target-root`, behavior is byte-for-byte today's (harness clone). This is the hard backward-compat gate.
4. **Test:** add `test/relay-target-root.sh` proving (a) a foreign `--target-root` resolves the worktree + allowlist against the external repo, and (b) the default is unchanged. Stubbed agent, no real CLI.
5. **No regression:** `validate.sh` stays green; the new test is added to it if that is the convention.

## Ground rules
1. This file is the single source of truth. Producer (agy) and Reviewer (Codex) are different tools and never share memory.
2. Take a turn only if `NEXT` names your role.
3. One turn = one block at the very bottom, above the marker. Never edit earlier turns. Update `NEXT`/`STATUS`/`ROUND`.
4. Stay tight. Bullets, not essays.
5. **The Reviewer never edits source.** It proposes graded findings; the Producer implements approved ones.
6. Grade every finding: `[Blocker]` must-fix · `[Should]` strong · `[Nit]` optional · `[Pass]` sound.
7. Reviewer posts a Verdict every turn. Relay ends on **Approved**. To get changes actioned set `Changes requested`.
8. Commit your turn: `relay(gh-11-target-root): <role> r<N>`. No push.
9. **One actor at a time, clean tree at every handoff.** The `RELAY-GH11-BUILD` tick token is the lock.
10. **Evidence contract — state your proof.** Producer: name the test you ran + its result. Reviewer: reconcile the diff against the spec and the default-unchanged gate.

---
## Log

<!-- ↓↓↓ NEXT TURN APPENDS BELOW THIS LINE — do not write above it ↓↓↓ -->

### Orchestrator note · claude-a · 2026-06-21 22:59 PDT — RELAY ESCALATED (Producer failed, contained)
The agy **Producer/builder** turn failed and was contained — it did **not** land a working `--target-root`:
- Turn 1 produced no tracked changes (token-only move). Turn 2 **hung past the 300s cap (F7)** and **committed mid-turn (F6)** → the shim reset to the scaffold commit and failed the turn (**exit 6**). Token handling was erratic (F4): the token ended `handoff-to codex` with no valid producer output.
- **Containment held:** `relay-drive.sh` + `relay-turn-lib.sh` unchanged (parse-clean; `test/agy-turn.sh` still 22/0); operator WIP untouched; nothing pushed.
- **Salvage:** agy left an untracked 120-line `test/relay-target-root.sh` (a real, unfinished test scaffold) — usable as a starting point if a competent builder takes Ask 1.
- **Verdict:** agy is **not ready as an unattended builder**. Nothing valid for Codex to verify, so the relay is escalated to the human rather than handed to Codex.
