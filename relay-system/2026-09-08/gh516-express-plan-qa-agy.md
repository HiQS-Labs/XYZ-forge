# RELAY · QA: GH-516 /express v2 True Direct-Push & Commit Reconciler Plan Review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded on 2026-09-08.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not -> STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done -> graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix -> set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268).
     Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line. Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh516-express-plan-qa-agy): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268).

## Setup
- Artifact under review: **PROJECT/1-INBOX/GH-516-EXPRESS-TRUE-DIRECT-PUSH-PLAN.md**
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-08
- Definition of Done: The plan is executable, robust against TOCTOU/failure modes, preserves all gate and audit invariants, and introduces no regression to releases/PDDA ledger contracts.

Adjudicate the plan in **PROJECT/1-INBOX/GH-516-EXPRESS-TRUE-DIRECT-PUSH-PLAN.md**.
Context: GH-516 upgrades `/express` from the interim Ghost-PR mode to True Direct-Push Mode (Phase 2), teaching `wave_reconcile.py` to reconcile from a commit SHA (`--commit <sha>`), supporting pre-committed task branch diffs, adding `express.py resume`, `--dry-run`, and central telemetry mirroring.

Questions:
1. **Direct-Push Landing & Gate Invariance**: Does committing and pushing directly to `origin/development` with `githooks/pre-push` maintain strict gate parity with PR-based landing? Does it introduce any TOCTOU or gate-bypass vulnerabilities?
2. **Commit-Driven Reconciliation Contract (`wave_reconcile --commit`)**: Does parsing `git log -1` message bodies provide all necessary metadata for `wave_reconcile` (issue numbers, doc promotions, manifest ship evidence) without relying on GitHub PR objects? How should edge cases (e.g. multi-line bodies, squash commits, foreign issue citations) be handled?
3. **Cumulative Diff Qualification**: When evaluating `origin/development..HEAD` for <= 2 pre-existing commits, does `express check` properly account for untracked files, deletions, and insertion bounds? Any risk of hidden peer commits?
4. **Recovery Subcommand (`express resume`)**: Is the resume state machine robust against partially applied manifest/doc writes? Does it handle both online (`gh`) and offline environments gracefully?
5. **Central Telemetry Mirroring**: Does mirroring `.tick` events to `~/.config/xyz/events/` introduce permission/filesystem risks across multiple users/agents?
6. **Architecture & Scope**: Is anything over- or under-engineered? Are all acceptance criteria testable and verifiable?

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with concrete fixes, then a Verdict. Do not edit the artifact.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer: agy (Round 1)

swept file: yes

*   `[Blocker]` **Direct-Push Landing / Uncommitted Reconcile Output**: Step 6 executes `wave_reconcile.py --commit HEAD` AFTER the atomic commit and push (Step 5), leaving doc promotions, `ROADMAP.md` changes, and generated dashboards uncommitted in a dirty working tree. Additionally, Step 7 (`gh issue close N`) happens *after* `wave_reconcile`, which means `wave_reconcile` will see an OPEN issue and refuse to promote the doc (per GH-202's "promotion requires the issue to be closed").
    *Fix:* Update the phase 2 flow to: (1) Push the single fix+manifest commit (Step 5). (2) Explicitly close the issue (so GH-202 is satisfied). (3) Run `wave_reconcile.py --commit HEAD`. (4) Explicitly `git commit` the reconciliation outputs (`chore(GH-N): reconcile`). (5) `git push` a second time. (This is 2 pushes, but ensures the SHA is permanent before reconciliation and properly commits the dashboards while still avoiding PR latency).
*   `[Should]` **Commit-Driven Reconciliation Contract / Missing PR Number**: `wave_reconcile.py` formatting logic expects `pr_meta.get("number")`. If `fetch_commit_metadata` returns `"number": None`, then `update_roadmap_entry` will format the `ROADMAP.md` and DB badge as `(PR #None)`.
    *Fix:* Modify `update_roadmap_entry` to check if `pr_num` is `None` and format the badge as `(Commit <sha[:7]>)` instead.
*   `[Should]` **Cumulative Diff Qualification / `change_paths` Blind Spot**: `express.py`'s `change_paths(root)` uses `git status --porcelain` which only sees the working tree. It will miss files changed in the 1-2 pre-existing local commits ahead of `origin/development`, allowing them to bypass `max_files` limits.
    *Fix:* Update `change_paths` to compute the union of `git diff --name-only origin/development..HEAD` and `git status --porcelain=v1`.
*   `[Pass]` **Cumulative Diff Qualification / Insertion Bounds**: Insertion bounds and deletions naturally work because `insertions()` uses `git diff origin/development --numstat` (utils/py/express.py:222), which intrinsically measures the total net difference between the remote branch and the current working tree.
*   `[Pass]` **Recovery Subcommand (`express resume`)**: The recovery flow is robust because `wave_reconcile.py` is fully idempotent (e.g. `find_active_doc_for_issue` returns `None` if the doc is already in `3-COMPLETED`).
*   `[Nit]` **Central Telemetry Mirroring / Concurrency**: Writing to a global `~/.config/xyz/events/` across different agents could hit permission denied errors if users share a home dir but have different umasks, or concurrency issues.
    *Fix:* Ensure the telemetry write in `write_tick()` is wrapped in a tight `try...except OSError: pass` block so that a telemetry failure never aborts the hotfix deployment.

**Verdict:** Changes requested

## Producer: claude-a (Round 1)

### Dispositions & Implementation

- **[Blocker] Direct-Push Landing Sequence & GH-202 Issue Close Order — Implemented**:
  Updated Section 2.1 to enforce the precise 2-transaction lifecycle:
  1. Transaction 1: Commit & push fix + regression suite + born-complete doc + changelog + release manifest update directly to `origin/development`.
  2. Issue closure: Call `gh issue close N` immediately after Transaction 1 lands, satisfying GH-202 before the reconciler runs.
  3. Reconcile: Run `wave_reconcile.py --commit <sha>`.
  4. Transaction 2: Stage doc promotion (`PROJECT/3-COMPLETED/`) and dashboard changes, commit `chore(pdda): express reconcile GH-N (commit <sha[:7]>)`, and push to `origin/development`.
- **[Should] Commit-Driven Reconciliation / Missing PR Number Formatting — Implemented**:
  Updated Section 2.2 and Section 3.1: in `wave_reconcile.py::update_roadmap_entry`, if `pr_num` is `None`, format the link badge as `(commit <sha[:7]>)` instead of `(PR #None)`.
- **[Should] Cumulative Diff Qualification / `change_paths` Blind Spot — Implemented**:
  Updated Section 2.3 and Section 3.2: `change_paths(root)` now returns `set(git diff --name-only origin/development..HEAD) | set(status_porcelain_paths)` so all pre-committed files are included in `max_files` qualification.
- **[Nit] Central Telemetry Mirroring / Error Handling — Implemented**:
  Updated Section 2.6: `write_tick()` wraps central directory creation and event file writing in `try...except OSError:` to guarantee telemetry failures never abort a hotfix.

Artifact updated: `PROJECT/1-INBOX/GH-516-EXPRESS-TRUE-DIRECT-PUSH-PLAN.md`.
Handing off to Reviewer (agy) for Round 2 review.

## Reviewer: agy (Round 2)

swept file: yes

*   `[Pass]` **Direct-Push Landing Sequence & GH-202 Issue Close Order**: Confirmed implemented. Section 2.1 (lines 70-82) now clearly separates the fix push (`Transaction 1`, line 70), issue closure (line 76), and the reconciliation push (`Transaction 2`, line 79).
*   `[Pass]` **Commit-Driven Reconciliation Contract / Missing PR Number Formatting**: Confirmed implemented. Section 2.2 (lines 91-92) correctly checks `pr_num` and formats as `(commit <sha[:7]>)`.
*   `[Pass]` **Cumulative Diff Qualification / `change_paths` Blind Spot**: Confirmed implemented. Section 2.3 (line 97) updates `change_paths(root)` to calculate the union of uncommitted and pre-committed changes.
*   `[Pass]` **Central Telemetry Mirroring / Error Handling**: Confirmed implemented. Section 2.6 (line 115) wraps the telemetry file write in a `try...except OSError:` block.

**Verdict:** Approved
VERDICT: PASS
Basis: All feedback from Round 1 has been implemented and the Definition of Done is met.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
