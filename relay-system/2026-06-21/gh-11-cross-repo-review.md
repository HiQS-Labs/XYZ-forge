# RELAY · GH-11 cross-repo targeting — issue review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real file; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work. Re-read the artifact and confirm each `Implemented → @ file:line` actually landed.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`).
6. **Commit only the files you touched** (this log): `git commit -m "relay(gh-11-cross-repo): <your-label> r<N>"`. Do **not** push. *(The harness commits for you in headless mode.)*
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-11-CROSS-REPO-TARGETING.md`
- Definition of Done: The issue capture is **accurate and actionable** — the cross-repo targeting gap is real and correctly diagnosed (Path A `relay-drive.sh` pins `ROOT_DIR` to the harness clone + worktree-snapshots that `HEAD`, with no `--target-root`; `consult.sh` `CONSULT_ROOT` already does cross-repo one-shot reviews but is undocumented in `SKILL.md`); the **asks are correctly prioritized** (1–2 load-bearing: the `--target-root` flag + surfacing consult; 3–5 low-effort doc fixes); the **scope is genuinely new** (not a competing plan vs the shakedown discovery doc or the automated-relay hub); nothing is overstated.
- Producer: Claude (claude-a)   ·   Reviewer: agy (agy)
- Handoff: cli-driven (agy)   <!-- driven by relay-automation/relay-drive.sh + agy-turn.sh -->
- Started: 2026-06-21

## Ground rules
1. This file is the single source of truth. The two agents are different tools (Claude and agy) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND`.
4. Stay tight. Findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix.
6. Grade every finding: `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved**. To get proposals actioned in-thread set `Changes requested`, not `Approved`.
8. End your turn by committing it: `relay(gh-11-cross-repo): <role> r<N>`. No push.
9. **One actor at a time, clean tree at every handoff.** The `RELAY-GH11` tick token is the lock.
10. **Evidence contract.** The artifact is a non-executable doc, so the honest basis is `textual only`.

---
## Log

### Round 1 · Reviewer · agy · 2026-06-21 22:48 PDT
**Verdict:** Approved
**Findings & proposals:**
- [Pass] Gap diagnosis: The diagnostic points regarding `relay-drive.sh` (which pins `ROOT_DIR` to the harness clone at [relay-automation/relay-drive.sh:25](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.VBJFnF/relay-automation/relay-drive.sh#L25)) and `consult.sh` (which supports `CONSULT_ROOT` at [relay-automation/consult.sh:48](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.VBJFnF/relay-automation/consult.sh#L48) but does not document it in [skills/consult/SKILL.md](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.VBJFnF/skills/consult/SKILL.md)) are accurate.
- [Pass] Prioritization: Prioritizing asks 1 and 2 as load-bearing and 3–5 as low-effort doc fixes is logical and correct.
- [Pass] Scope checks: Verified that the scope is genuinely new and does not collide with existing documents [RELAY-XYZ-DISCOVERY-SHAKEDOWN.md](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.VBJFnF/PROJECT/2-WORKING/RELAY-XYZ-DISCOVERY-SHAKEDOWN.md) or [AUTOMATED-RELAY.md](file:///var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.VBJFnF/PROJECT/2-WORKING/AUTOMATED-RELAY.md).
- [Pass] Evidence contract is textual only. No source files or tests were run, edited, or created, fully complying with the Reviewer constraints for this turn.
**Commit:** harness

<!-- ↓↓↓ NEXT TURN APPENDS BELOW THIS LINE — do not write above it ↓↓↓ -->
