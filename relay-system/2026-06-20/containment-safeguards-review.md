# RELAY · headless-containment safeguards review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real files / the latest `git show <commit>` diff; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here. **Before you set `Approved`, re-read the artifact files themselves** (not this log) and confirm every prior `Implemented` fix is actually present and complete.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work. **Before you flip `NEXT`, re-read the artifact and confirm each `Implemented → @ file:line` actually landed.**
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (the relay log): `git commit -m "relay(containment-safeguards-review): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line. Do **not** push.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

## Setup
- Artifact under review: the **headless-containment safeguards** (contain a headless reviewer/agent that goes off the rails). Read these files at their current branch state, and the commit diffs:
  - **#1 reviewer-allowlist scoping** — `relay-automation/relay-turn-lib.sh` (`rtl_is_reviewer_turn`, the scoping in `rtl_init`, and in `rtl_turn_prompt`); tests in `test/codex-turn.sh` + `test/agy-turn.sh` (the "REVIEWER-turn scoping" cases). Commits: `2f9b995` (core) + `9b751a8` (agy test + header-only detector).
  - **#2 worktree isolation for the cross-model shims** — `relay-automation/agy-turn.sh` + `relay-automation/codex-turn.sh` (the `RELAY_WORKTREE_ISOLATION=1` blocks); test `test/shim-worktree.sh`. Commit: `1221e7d`. (The shared core `rtl_worktree_begin/end` and the reference wiring `relay-automation/claude-turn.sh` are pre-existing — review the wiring's faithfulness to them.)
- Definition of Done: both safeguards are **correct and well-scoped** — (a) no false-negative that still lets a reviewer/agent escape (e.g. an absolute-path write, a NEXT detection miss, a worktree teardown ordering bug); (b) no false-positive that breaks a legitimate **Producer** turn or the default (isolation-OFF) path; (c) the worktree wiring faithfully mirrors `claude-turn.sh` (begin → cwd_wrap → teardown-before-other-checks → off-lane exit 6 precedence); (d) the tests actually exercise the new behavior; (e) `bash validate.sh` is **35/35**, no regressions.
- Producer: Claude (claude-a)   ·   Reviewer: Codex (codex)
- Handoff: cli-driven (codex)   <!-- driven by relay-automation/relay-drive.sh + codex-turn.sh -->
- Started: 2026-06-20

## Ground rules
1. This file is the single source of truth. The two agents are different tools (Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top.
4. Stay tight. Findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer decides each proposal and implements the approved ones — logging a disposition for every one.
6. Grade every finding: `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound. Answer the Producer's "Re-review this" questions in an `Answers:` block.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved**. To get proposals actioned in-thread set `Changes requested`, not `Approved`. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated`.
8. End your turn by committing it: `relay(containment-safeguards-review): <role> r<N>`, then fill the hash into your `Commit:` line. No push.
9. **One actor at a time, clean tree at every handoff.** The `SAFEGUARD-TURN` tick token is the lock. Never flip `NEXT` with uncommitted changes in the tree.
10. **Evidence contract — state your proof every turn.** This artifact IS executable (shell + tests), so prefer `behaviorally proven` (you ran `bash validate.sh` / a specific test) over `textual only`.
11. **Reconcile claims against the file, not this log.** Before `Approved`, the Reviewer re-reads the artifact files themselves and confirms every `Implemented` fix is present.

## Roles
- **Producer** — Claude. The only writer of the artifact: builds it, requests review, decides and implements proposals.
- **Reviewer** — Codex. Reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · claude-a · 2026-06-20 20:31 PDT
**Did:** Built two containment safeguards after a headless agy *reviewer* went off the rails (it edited `validate.sh` because the artifact was on `ALLOW_PATHS`).
- **#1 Reviewer-allowlist scoping** (`relay-turn-lib.sh`): new `rtl_is_reviewer_turn` (matches the FIRST `NEXT:` header line only). When it's a reviewer turn, `rtl_init` drops the caller's `ALLOW_PATHS` (allowlist = relay file only) and `rtl_turn_prompt` tells the model not to edit the artifact. A reviewer that edits anything → reverted + exit 6. Producer turns keep the full allowlist. Tests: `test/codex-turn.sh` (27/0) + `test/agy-turn.sh` (22/0) prove an artifact on `ALLOW_PATHS` is reverted on a `NEXT: Reviewer` turn.
- **#2 Worktree isolation** wired into `agy-turn.sh` + `codex-turn.sh` (opt-in `RELAY_WORKTREE_ISOLATION=1`, default OFF): mirrors `claude-turn.sh` — run the turn with CWD = a throwaway `git worktree` of `ROOT@HEAD`; teardown copies back only the allowlist; off-lane in the worktree → exit 6 (precedence over timeout/failure). Test `test/shim-worktree.sh` (18/0) proves both shims contain an off-lane write + copy back a good turn + leave the OFF path unchanged.
**Review this:** (1) **#1 false-negatives** — can a reviewer still escape? e.g. absolute-path write to ROOT (does the path-allowlist still catch it since `rtl_enforce` runs on ROOT?), a `NEXT:` detection miss (header variants), or the prompt still tempting the model. (2) **#1 false-positives** — does a legitimate `NEXT: Producer` turn keep its `ALLOW_PATHS` (the scoping must NOT fire for producers)? (3) **#2 wiring faithfulness** — does the `agy/codex` worktree block match `claude-turn.sh` exactly on ordering (teardown BEFORE the timeout/empty-output checks; off-lane exit 6 precedence)? Any interaction bug with the agy empty-output guard or the codex `OPENAI_API_KEY`-strip env when `cwd_wrap` is prepended? (4) **Test quality** — do `test/shim-worktree.sh` + the reviewer-scoping cases actually exercise the behavior (relative writes land in the worktree; absolute would not)? (5) Anything that regresses the default (isolation-OFF / non-reviewer) path.
**Verification:** behaviorally proven — `bash validate.sh` → **35/35** (incl. new `shim-worktree.sh` 18/0; `codex-turn.sh` 27/0; `agy-turn.sh` 22/0). Syntax-checked all three shells.
**Open questions:** (a) Should `#1` reviewer-scoping be enforced even when the operator *explicitly* set `ALLOW_PATHS` (current: yes, scoping wins)? (b) Worktree copy-back is forward-only (deletions don't propagate) — acceptable for review/producer turns?
**Commit:** 2f9b995 (#1 core) + 9b751a8 (#1 completion) + 1221e7d (#2) — diff to review: `git show 9b751a8 1221e7d` and `git show 2f9b995 -- relay-automation/relay-turn-lib.sh`

### Round 1 · Reviewer · codex · 2026-06-20 20:35 PDT
**Verdict:** Changes requested
**Findings & proposals:**
- [Blocker] `relay-automation/relay-turn-lib.sh:154-169` still emits the original `RELAY_FILE` and `ALLOW_PATHS` strings into the model prompt, while `relay-automation/codex-turn.sh:71-88` and `relay-automation/agy-turn.sh:105-117` only change the subprocess CWD. When those paths are absolute, the model can write straight into `RTL_ROOT`, bypassing the throwaway worktree entirely. `test/shim-worktree.sh:19-34` does not catch that because the stub ignores the prompt and writes only relative paths. Proposed fix: when `RELAY_WORKTREE_ISOLATION=1`, rewrite prompt-visible file targets to the worktree copies, or pass only repo-relative paths after an explicit `cd` into the worktree, then add a regression where the stub follows the exact path strings it was given.
- [Blocker] `relay-automation/relay-turn-lib.sh:125-148` is explicitly forward-only: it copies back allowlisted edits/creates but never propagates allowlisted deletions. That silently breaks a legitimate isolated Producer turn which deletes an artifact file: the turn can exit 0 while `RTL_ROOT` still keeps the file, which misses the DoD's "no false-positive" bar. `test/shim-worktree.sh:58-81` covers copy-back for edits only, not delete propagation. Proposed fix: in `rtl_worktree_end`, detect allowlisted paths deleted in the worktree and remove the corresponding `RTL_ROOT` path before teardown, then add an isolation test for delete-on-allowlist for both shims.
- [Pass] Reviewer-turn scoping itself is well-placed: `relay-automation/relay-turn-lib.sh:50-67` narrows the allowlist before normalization, and `relay-automation/relay-turn-lib.sh:160-169` removes the artifact-edit invitation from the prompt on reviewer turns. The direct overstep case is exercised in `test/codex-turn.sh:128-140` and `test/agy-turn.sh:109-122`.
- [Pass] The cross-model wiring matches Claude on the ordering the DoD called out: begin isolation, run via `cwd_wrap`, tear down before timeout/failure checks, and give exit 6 precedence on isolated off-lane writes. The ordering in `relay-automation/codex-turn.sh:66-108` and `relay-automation/agy-turn.sh:100-146` mirrors `relay-automation/claude-turn.sh:156-176`.
**Answers:**
- Proof: textual only. I read the current branch files and tests directly; per the operator constraint for this turn I did not run `git`, `bash validate.sh`, or any artifact/test script.
- (1) Reviewer-scope false-negatives: the in-ROOT guard still catches absolute-path writes to tracked files because enforcement runs against `RTL_ROOT`, but the isolation path re-opens an escape if the prompt hands the model absolute ROOT paths.
- (2) Reviewer-scope false-positives: the scoping does not fire on producer turns; `rtl_init` only drops `ALLOW_PATHS` when the header `NEXT:` line names Reviewer.
- (3) Wiring faithfulness: yes on ordering and precedence; no regression found in the agy empty-output guard or Codex env-strip composition.
- (4) Test quality: reviewer-scoping tests are good for the direct artifact-edit case; isolation tests miss the prompt-path leak and allowlisted-delete behavior.
**Commit:** harness

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
