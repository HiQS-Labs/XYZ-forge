# RELAY · GH-11 Ask 1 (v2, narrow) — `--target-root` FLAG only (agy builds, Codex verifies)
<!--
  Single source of truth for this two-agent relay. Read this ENTIRE file before doing anything.
-->

NEXT: Reviewer
STATUS: Open
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

<!-- ↓↓↓ NEXT TURN APPENDS BELOW THIS LINE — do not write above it ↓↓↓ -->
