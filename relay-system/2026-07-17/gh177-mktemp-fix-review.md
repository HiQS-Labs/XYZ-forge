# RELAY · GH-177 mktemp-trap repo-wipe fix — independent review
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
- Artifact under review: `test/hq-hardening.sh`, `test/hq-promote.sh`, `test/hq-locator.sh`, `test/mktemp-trap-guard.sh` (new), `validate.sh` (1-line addition) — commits `e7fd117` and `47e054a` on `development`. Full diff also embedded in Round 1 below for convenience.
- Definition of Done: The 3 fixed files no longer have any code path where a failed `mktemp -d` can silently resolve `$TMP` to the repo root and feed a destructive `EXIT` trap; `test/mktemp-trap-guard.sh` would actually fail if this exact bug (or an equivalent unguarded mktemp-into-destructive-rm-rf/cd-recapture pattern) were reintroduced anywhere in the repo, without false-positiving on the safe, common bare-`mktemp`-plus-trap idiom used elsewhere in the suite.
- Producer: Claude (this session)   ·   Reviewer: Codex
- Handoff: cli-driven (codex)
- Started: 2026-07-17

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

### Round 1 · Producer · 2026-07-17 15:56 PDT
**Did:**
- `test/hq-hardening.sh`, `test/hq-promote.sh`, `test/hq-locator.sh`: replaced the unguarded `TMP="$(cd "$(mktemp -d)" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT` with an explicit `mktemp` exit-status check, then a non-empty + `-d` check, THEN the trap, THEN a separate canonicalization step (`TMP="$(cd "$TMP" && pwd -P)"`) only once `$TMP` is already verified real.
- New `test/mktemp-trap-guard.sh`: a static audit (mirrors `test/marathon-root-audit.sh`'s style) scanning every `.sh` under `test/`, `utils/`, `relay-automation/`, `skills/`, `bin/` for (a) the exact inline `cd "$(mktemp` idiom, or (b) the split-line twin — a var assigned from `mktemp` later re-captured via `X="$(cd "$X" && pwd ...)"` — without an intervening non-empty/`-d` guard. Comment-only lines are skipped so it doesn't flag documentation quoting the bug. Added to `validate.sh`'s `TESTS` array.
**Review this:**
- Is the fix in the 3 files actually sufficient — does the exit-status + `-n`/`-d` check fully close the "mktemp fails silently, cd swallows it" failure mode, or is there still a gap (e.g. a TOCTOU race, or another code path)?
- Does `test/mktemp-trap-guard.sh`'s detection logic have any blind spot — a way to write an equivalently dangerous pattern that would slip past both its Tier 1 and Tier 2 checks?
- Any false positives left in the audit against the CURRENT real repo state (it passed 191/191 clean when last run by the Producer, but re-verify independently)?
**Verification:** ran `bash test/mktemp-trap-guard.sh` → `PASS: audited 191 .sh files ... no unguarded mktemp-into-destructive-rm-rf pattern found` (0 failures) · separately proved detection works by writing two disposable scratch files reconstructing the inline and split-line bug shapes, confirmed both FAIL, then deleted the scratch files and re-confirmed a clean pass · did NOT re-run the full `validate.sh` suite (that suite includes the very scripts this bug lives in; re-running it sandboxed is what caused this incident twice — ran only the new test standalone, un-sandboxed, both times).
**Open questions:**
- Should the audit also cover `.mjs`/`.py` equivalents of this pattern (e.g. Python `tempfile.mkdtemp()` misuse), or is this scoped correctly to bash-only per the doc's stated non-goal?
**Commit:** e7fd117 (3-file fix + new test + validate.sh wiring), 47e054a (doc move to 3-COMPLETED, not part of the code under review)

### Round 1 · Reviewer · codex · 2026-07-17 15:59 PDT
**Verdict:** Changes requested
**Basis:** textual only — operator instruction for this reviewer turn forbade running artifact/test files, so this review is live-file inspection only.
**Findings & proposals:**
- [Blocker] `test/mktemp-trap-guard.sh:34` and `test/mktemp-trap-guard.sh:41` undercut the stated DoD: the audit does **not** cover "anywhere in the repo"; it only walks `test/`, `utils/`, `relay-automation/`, `skills/`, and `bin/`, so a reintroduced footgun in root-level shell files like `validate.sh`, `install.sh`, `run-tests.sh`, or under `tools/` would pass clean. Proposed fix: drive the scan from repo root (or add explicit root-level `.sh` + `tools/`) and keep the current transcript/vendor exclusions as negative filters instead of positive-directory allowlisting.
- [Blocker] `test/mktemp-trap-guard.sh:72`, `test/mktemp-trap-guard.sh:90`, and `test/mktemp-trap-guard.sh:95` leave an evasion path: Tier 2 only catches the one-line re-capture form `VAR="$(cd "$VAR" && pwd ...)"`, and it treats **any** later line mentioning `$VAR` plus `||` as "guarded". An equivalent bug can slip through as split steps such as `cd "$TMP"` on one line and `TMP="$(pwd -P)"` on the next, or by inserting an unrelated `echo "$TMP" || true` before the re-capture. Proposed fix: replace the current heuristic with a small state machine that tracks explicit validation of the same var (`-n` and `-d` / equivalent `test` or `[[ ... ]]` forms) and flags both inline and multi-line `cd "$VAR"` -> `pwd` re-capture before that validation.
- [Pass] `test/hq-hardening.sh:20`, `test/hq-hardening.sh:21`, `test/hq-hardening.sh:22`, `test/hq-promote.sh:23`, `test/hq-promote.sh:24`, `test/hq-promote.sh:25`, `test/hq-locator.sh:23`, `test/hq-locator.sh:24`, and `test/hq-locator.sh:25` do close the original repo-wipe path textually: `mktemp -d` must now succeed and yield a non-empty real directory before the destructive `EXIT` trap is armed, and canonicalization happens only afterward.
**Answers:**
- The 3-file fix itself looks sufficient for the original failure mode. I do not see a remaining path where a failed `mktemp -d` can silently turn into repo-root `rm -rf` in those three tests, because the trap is no longer armed until after the success + `-n` + `-d` checks.
- The audit has blind spots; the two blockers above are the material ones.
- I did not independently re-run `bash test/mktemp-trap-guard.sh` because the operator explicitly forbade running artifact/test files this turn. Textually, the script still appears designed to avoid the known comment-only and bare-`mktemp` false positives, but that is not a behavioral re-verification.
**Commit:** none (operator instructed no git; harness should make the file-scoped handoff commit)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
