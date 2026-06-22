# RELAY · GH-11 Ask 1 (v2, narrow) — `--target-root` FLAG only (agy builds, Codex verifies)
<!--
  Single source of truth for this two-agent relay. Read this ENTIRE file before doing anything.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Build spec, Ground rules, Log).
2. **Check it's your turn:** `NEXT` (top) names the role. Confirm you are bound to it (Setup) and the last Log block isn't yours. If not → STOP ("not my turn").
3. **Do your role's work:**
   - **Producer (agy):** implement the Build spec. Edit **only** `relay-automation/relay-drive.sh` (+ this relay file). Keep it small — this is flag parsing only. **Do NOT run git** (no add/commit/push) — the harness commits for you. Then append your block and hand to the Reviewer.
   - **Reviewer (Codex):** verify the diff against the Build spec → graded findings → **Verdict**. Do not edit source; only append findings.
4. **Append ONE block** at the very bottom, above the marker. Producer: `**Did:**` + `**Verified:**` + `**Commit:**`. Reviewer: `**Verdict:**` + `**Findings & proposals:**` + `**Commit:**`.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only).
6. Do **not** run git — the harness commits your turn.
7. **Stop.** One-line result to the operator.

## Setup
- Build target: GH-11 Ask 1 — **flag parsing ONLY** this round. Capture: `PROJECT/1-INBOX/GH-11-CROSS-REPO-TARGETING.md`.
- File in play (`ALLOW_PATHS`): `relay-automation/relay-drive.sh` — **nothing else** (do NOT touch `relay-turn-lib.sh` this round).
- Producer: agy (agy)   ·   Reviewer: Codex (codex)
- Started: 2026-06-21

## Build spec (Definition of Done) — small and self-contained
Add **only** the `--target-root <dir>` flag to `relay-automation/relay-drive.sh`. The flag is **inert** this
round (it changes no behavior yet) — it is plumbing a later round will consume. Do NOT touch the kernel.

1. **Parse** `--target-root <dir>` in the existing arg loop (next to `--relay-file` / `--relay-task` / `--round-cap`).
2. **Validate:** `<dir>` must be an existing git repo — `git -C "<dir>" rev-parse --show-toplevel` must succeed; else `die` with a clear message naming the bad path.
3. **Export** `RELAY_TARGET_ROOT="<dir>"` into the turn-taker env (so a later `relay-turn-lib.sh` change can consume it). With the flag **absent**, leave `RELAY_TARGET_ROOT` unset → today's behavior is byte-for-byte unchanged.
4. **Document** it in the `usage()` text.

DoD: flag parses + validates + exports; **default (no flag) behavior unchanged**; `bash -n relay-automation/relay-drive.sh` clean; `validate.sh` stays green. The flag being inert is expected — kernel wiring is a later round.

## Ground rules
1. Single source of truth. agy (Producer) and Codex (Reviewer) never share memory.
2. Take a turn only if `NEXT` names your role.
3. One block at the very bottom, above the marker. Never edit earlier turns. Update `NEXT`/`STATUS`.
4. Bullets, not essays.
5. **Reviewer never edits source.** It proposes graded findings.
6. Grade: `[Blocker]` must-fix · `[Should]` strong · `[Nit]` optional · `[Pass]` sound.
7. Reviewer posts a Verdict every turn. Relay ends on **Approved**.
8. **Do NOT run git** — the harness commits your turn (`relay(gh-11-target-root-v2): <role> r<N>`). No push.
9. **One actor at a time.** The `RELAY-GH11-FLAG` tick token is the lock.
10. **Evidence contract.** Producer: run `bash -n relay-automation/relay-drive.sh` and report it. Reviewer: reconcile the diff against the default-unchanged gate.

---
## Log

### Round 1 · Producer · agy · 2026-06-21 23:36 PDT
**Did:**
- Added parsing for the `--target-root DIR` flag in the existing arg loop in [relay-drive.sh](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.3VdNnq/relay-automation/relay-drive.sh).
- Validated that `DIR` is an existing git repo by verifying `git -C "$DIR" rev-parse --show-toplevel` succeeds, and `die`s if not.
- Exported `RELAY_TARGET_ROOT="$DIR"` into the turn-taker env when the flag is present, leaving it unset if the flag is absent.
- Documented `--target-root DIR` in the usage text of [relay-drive.sh](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.3VdNnq/relay-automation/relay-drive.sh).
**Verified:**
- Checked syntax of [relay-drive.sh](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.3VdNnq/relay-automation/relay-drive.sh) using `bash -n` to ensure clean syntax.
- Verified all 35 tests passed successfully by running [validate.sh](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.3VdNnq/validate.sh).
- Tested manually that running [relay-drive.sh](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.3VdNnq/relay-automation/relay-drive.sh) with an invalid target root `/invalid/path` correctly prints `relay-drive: invalid target root (not a git repo): /invalid/path` and exits with code 2.
- Tested manually that running [relay-drive.sh](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.3VdNnq/relay-automation/relay-drive.sh) with a valid target root (the workspace root) and a dummy `--agent-cmd` correctly exports the environment variable `RELAY_TARGET_ROOT` inside the turn-taker environment.
**Commit:** harness

### Round 1 · Reviewer · Codex · 2026-06-21 23:41 PDT
**Verdict:** Approved
**Findings & proposals:**
- [Pass] `--target-root DIR` is parsed in the existing arg loop, documented in `usage()`, and exported only when present, so the no-flag path stays unchanged by inspection.
- [Pass] Validation follows the requested contract for normal inputs: `git -C "$TARGET_ROOT" rev-parse --show-toplevel` gates acceptance and the failure path names the bad path.
- [Pass] Review basis: source inspection only. I did not independently rerun `bash -n` or `validate.sh` because this reviewer turn explicitly forbids running source or artifact files.
- [Nit] `--target-root \"\"` would currently validate against the supervisor CWD because `git -C \"\"` falls back to `.`; if you want strict empty-input rejection, add a non-empty check before `rev-parse`.
- Reversibility: Easy — single-script flag plumbing, no kernel wiring.
- Blast radius: limited to `relay-automation/relay-drive.sh` arg parsing and the turn-taker environment.
**Commit:** harness

<!-- ↓↓↓ NEXT TURN APPENDS BELOW THIS LINE — do not write above it ↓↓↓ -->

### Orchestrator note · claude-a · 2026-06-21 23:42 PDT — CLOSED (agy built it, Codex approved)
Cross-model build relay **succeeded** on the narrow slice:
- **agy (Producer)** built the `--target-root` flag correctly — parse + git-repo validation + conditional `RELAY_TARGET_ROOT` export + usage doc; no-flag path unchanged; followed the no-git rule. **`validate.sh` 35/35** (claim independently confirmed).
- **Codex (Reviewer)** verified by source inspection → **Approved** with one real `[Nit]`: `--target-root ""` validates against CWD (`git -C ""` → `.`); add a non-empty check before `rev-parse`.
- **Refined finding:** agy-as-builder is **scope-sensitive** — it FAILED the big kernel-spanning task (v1: F4/F6/F7) but SUCCEEDED on this small, well-bounded one. Scope discipline is the key variable.
- **Done this round:** GH-11 Ask 1 *flag* increment only (inert until the kernel-wiring round). Open: `relay-turn-lib.sh` consuming `RELAY_TARGET_ROOT` + Codex's empty-string Nit. Commits local, no push.
