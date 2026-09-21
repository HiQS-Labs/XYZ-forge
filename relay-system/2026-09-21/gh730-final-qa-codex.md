# RELAY · Final QA: GH-730 agent-chorus legacy fixture + gate no-bytecode
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh730-final-qa-codex): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh730-final-qa-artifact.diff** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-21

### Artifact — gh730-final-qa-artifact.diff
````
commit 5fca8017256aa5707a181998568ccf19b7f33be8
Author: Noel Saw <56978803+noelsaw1@users.noreply.github.com>
Date:   Mon Sep 21 11:22:30 2026 -0700

    fix(test, gate): agent-chorus legacy fixture dangles by construction; gate runs write no bytecode (GH-730)
    
    Two root causes behind the pre-push gate going red on test/agent-chorus.sh from
    the operator's primary clone while origin/development was green:
    
    1. test/agent-chorus.sh:713 built the "dangling" legacy link as
       ln -s "$REPO/skills/agent2agent". migrate_legacy_link repoints only when the
       target no longer exists, so on any clone where skills/agent2agent/ survives
       as an ignored __pycache__ shell the installer correctly leaves the link alone
       and the assertion fails. The fixture now targets $WORK/pre-rename-clone/skills/
       agent2agent — a path the suite never creates — so the precondition is the
       test's, not the clone's. The path still ends in /skills/agent2agent, which is
       what the installer's case arm matches.
    
    2. Gate runs manufactured the ghosts: suites import repo modules directly and
       wrote __pycache__/ under skills/*/scripts and utils/py, which .gitignore then
       let outlive the directory's rename (#193). relay-automation/gate-env.sh — the
       GH-441 single gate-environment prologue validate.sh sources — now exports
       PYTHONDONTWRITEBYTECODE=1, matching what the relay shims already do for
       reviewer turns (GH-682).
    
    Evidence (unsandboxed, this clone):
    - red control: clean clone + stale skills/agent2agent/scripts/__pycache__ →
      agent-chorus 214/1 on the reported assertion; after fix → 215/0 with and
      without the ghost
    - assertion still strict: installer repoint disabled → 214/1 on the same line
    - gate-env'd suite run → 215/0 and zero __pycache__ dirs under skills/ test/ utils/
    - test/gh441-gate-env-contract.sh → 16/0
    
    Issue item 3 (show the failing line in the refusal) is already served by
    validate.sh:1345-1346 (tail -40 of the serial re-run). Not changed.
    
    Intake: PROJECT/1-INBOX/GH-730-AGENT-CHORUS-LEGACY-FIXTURE.md, parked and
    rated 70/70/50/95 via releases_app.py (LEADERBOARD.md regenerated by the CLI).
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>

diff --git a/PROJECT/1-INBOX/GH-730-AGENT-CHORUS-LEGACY-FIXTURE.md b/PROJECT/1-INBOX/GH-730-AGENT-CHORUS-LEGACY-FIXTURE.md
new file mode 100644
index 00000000..9824df46
--- /dev/null
+++ b/PROJECT/1-INBOX/GH-730-AGENT-CHORUS-LEGACY-FIXTURE.md
@@ -0,0 +1,102 @@
+---
+title: pre-push gate red on test/agent-chorus.sh in any clone with a leftover skills/agent2agent/__pycache__ — legacy-symlink assertion reads clone state, not a fixture
+status: Proposed (1-INBOX — executing on fix/gh730-agent-chorus-legacy-fixture)
+created: 2026-09-21
+owner: agent-b
+gh_issue: 730
+source: https://github.com/HiQS-Labs/XYZ-forge/issues/730
+doc_type: bugfix
+complexity: 1
+risk: 1
+effort: 1
+phases: 1
+reported_from: XYZ-forge primary clone (while landing GH-720 / PR #729)
+harness_commit: bd8c6950   # origin/development at task start
+non_goals:
+  - Broadening skills/agent-chorus/install.sh to treat a tracked-file-less legacy dir as gone (the issue's item 2 — a test's problem must not widen the installer)
+  - A gate-side "ghost directory" detector or auto-clean of ignored leftovers in operator clones
+  - Setting PYTHONDONTWRITEBYTECODE in every script entry point (ordinary CLI runs may still write bytecode; .gitignore already covers it and no test depends on its absence any more)
+related:
+  - GH-193 (Phase 0 rename that left the ignored shell behind)
+  - GH-458 / GH-463 (earlier false reds on the same assertion — path spelling, not clone state)
+  - GH-682 (relay shims already set PYTHONDONTWRITEBYTECODE for reviewer turns)
+  - GH-720 / PR #729 (the push the red gate blocked)
+goal: >
+  test/agent-chorus.sh passes on every clone regardless of what ignored leftovers the clone
+  carries, and a gate run stops manufacturing the leftovers in the first place.
+---
+
+# GH-730 — agent-chorus legacy-symlink assertion coupled to clone state; gate runs write bytecode into the tree
+
+> **1-INBOX capture** for a fix carried on its own branch. Simple change (two files, no design
+> decision) — plan relay QA skipped per start-task Step 6; final Codex relay QA applies.
+
+## Symptom
+`git push` from the operator's primary clone was refused by the pre-push gate after 1099s with
+exactly one red suite, `agent-chorus.sh`, and this assertion:
+
+```text
+FAIL: legacy symlink not repointed (now -> '<clone>/skills/agent2agent', which is not the same directory as '<clone>/skills/agent-chorus')
+```
+
+The same suite on a pristine `origin/development` checkout is 215/0.
+
+## Root causes (two, both deterministic)
+
+1. **The fixture was the clone.** `test/agent-chorus.sh:713` built the "dangling" legacy link as
+   `ln -s "$REPO/skills/agent2agent"`. `skills/agent-chorus/install.sh:24-30`
+   (`migrate_legacy_link`) repoints only when the target no longer exists. On any clone where
+   `skills/agent2agent/` still exists — as an ignored, zero-tracked-file shell — the installer
+   correctly declines to touch a live link and the assertion fails. The assertion's precondition
+   lived in the clone's untracked state, not in a fixture the test controls.
+
+2. **Gate runs create the ghosts.** Suites import repo modules directly (`importlib` at
+   `test/agent-chorus.sh:437`, the `unittest` files under `test/`), and every such import wrote
+   `__pycache__/` under `skills/*/scripts` and `utils/py`. Those caches are gitignored, so they
+   outlive the rename or removal of the directory that held them. The primary clone carried two
+   such ghosts: `skills/agent2agent/scripts/__pycache__/` (Aug 22) and
+   `skills/skills-sync-trinity/scripts/__pycache__/`. The relay shims already set
+   `PYTHONDONTWRITEBYTECODE=1` for reviewer turns (GH-682); the gate did not.
+
+## Fix (surgical, extends what exists)
+
+| Surface | Change |
+|---|---|
+| `test/agent-chorus.sh:713` | Fixture link targets `$WORK/pre-rename-clone/skills/agent2agent` — a path the suite never creates, so it is dangling by construction. Still ends in `/skills/agent2agent`, which is what the installer's `case` arm matches. |
+| `relay-automation/gate-env.sh` | `export PYTHONDONTWRITEBYTECODE=1` — the shared gate prologue `validate.sh:12` already sources (the GH-441 single registry for gate environment), so every suite in every gate mode inherits it. |
+
+Issue item 3 (print the failing line in the refusal block) is already served:
+`validate.sh:1345-1346` tails the last 40 lines of the failing suite's serial re-run before the
+`failed:` summary. No change.
+
+## Surveyed and clean
+- Installers with legacy logic: `skills/agent-chorus/install.sh` (fixed fixture) and
+  `skills/releases/install.sh` (removes legacy symlinks unconditionally — no dependence on a
+  repo path existing).
+- Tests linking a `$REPO` path expected to be absent: only the one at `test/agent-chorus.sh:713`.
+  `test/test_deploy_skills.py:548` checks `skills/skills-sync-trinity/SKILL.md`, a tracked file,
+  not the directory — unaffected by the ghost.
+
+## Acceptance (all run on this branch, unsandboxed per GH-177)
+- [x] Red control: clean clone + `mkdir -p skills/agent2agent/scripts/__pycache__` → `agent-chorus: 214 pass, 1 fail` (the reported assertion)
+- [x] After fix, same clone state → `215 pass, 0 fail`; ghost removed → `215 pass, 0 fail`
+- [x] Red control for the changed assertion: installer's `ln -sfn` repoint disabled → `214 pass, 1 fail` on the same assertion (it still detects a non-repointing installer); installer restored
+- [x] `. relay-automation/gate-env.sh && bash test/agent-chorus.sh` → 215/0 and **zero** `__pycache__` directories under `skills/ test/ utils/` afterwards
+- [x] `test/gh441-gate-env-contract.sh` → 16 pass, 0 fail
+- [ ] Full `./validate.sh` green through the pre-push gate on the final commit
+- [ ] Final Codex relay QA: Approved
+
+## Ratings (RELEASES, 2026-09-21)
+`rated 70/70/50/95`. **sev 70:** deterministic gate red on every push from an affected clone;
+recoverable (`rm -rf` the ghost) but it normalises `--no-verify`, which is the gate's own
+failure mode. **pri 70:** severity-led; the operator's primary clone is affected and it blocked
+a landing today. **appeal 50:** neutral, no operator preference given. **effort 95:** two-line
+fix, focused suites already green. **Recurrence:** third false red on this one assertion
+(GH-458, GH-463 on path spelling; this one on clone state) — 2026-09-07..21 window: 1 incident
+(this); prior 14 days: 0 on this assertion. Same class (test keyed on clone state) — no other
+instance found in the survey above.
+
+## Operator follow-up (not in this PR)
+The primary clone's `skills/agent2agent` ghost was moved to the session scratchpad on
+2026-09-21; `skills/skills-sync-trinity/scripts/__pycache__/` is still there and is now
+harmless — `rm -rf skills/skills-sync-trinity` when convenient (zero tracked files).
diff --git a/relay-automation/gate-env.sh b/relay-automation/gate-env.sh
index aba4ea61..eadc2ab7 100644
--- a/relay-automation/gate-env.sh
+++ b/relay-automation/gate-env.sh
@@ -81,3 +81,11 @@ else
 fi
 
 unset _ge_src _ge_dir _ge_root _ge_py _ge_names _ge_n
+
+# GH-730: no bytecode into the tree from a gate run. Suites import repo modules directly
+# (importlib in test/agent-chorus.sh, the unittest files under test/), and every such import
+# wrote `__pycache__/` under skills/*/scripts and utils/py. Those caches are gitignored, so
+# they outlive the rename or removal of the directory that held them — `skills/agent2agent/`
+# survived the #193 rename as an ignored shell for a month and turned the pre-push gate red.
+# The relay shims already set this for reviewer turns (GH-682); the gate gets the same rule.
+export PYTHONDONTWRITEBYTECODE=1
diff --git a/test/agent-chorus.sh b/test/agent-chorus.sh
index 52c36d91..e25e84e9 100755
--- a/test/agent-chorus.sh
+++ b/test/agent-chorus.sh
@@ -710,7 +710,12 @@ install_rc=$?
 # target), leave real directories alone, and drop links that dangle at something unrelated.
 MIG_DIR="$WORK/legacy-skills"
 mkdir -p "$MIG_DIR"
-ln -s "$REPO/skills/agent2agent" "$MIG_DIR/agent2agent"   # the pre-rename install shape (now dangling)
+# GH-730: the dangling target is a fixture path this suite never creates, NOT $REPO/skills/agent2agent.
+# The installer repoints only when the target no longer exists, and on a long-lived clone the old
+# directory survives the #193 rename as an ignored `scripts/__pycache__/` shell — so pointing at the
+# real path coupled this assertion to the clone's untracked state and turned the pre-push gate red.
+# The path still ends in `/skills/agent2agent`, which is what migrate_legacy_link's case arm matches.
+ln -s "$WORK/pre-rename-clone/skills/agent2agent" "$MIG_DIR/agent2agent"   # the pre-rename install shape (dangling by construction)
 mig_out="$(CLAUDE_SKILLS_DIR="$MIG_DIR" CODEX_SKILLS_DIR="$WORK/mig-codex" \
   run_installer 2>&1)"
 mig_target="$(readlink "$MIG_DIR/agent2agent" 2>/dev/null || true)"
````
- Definition of Done: the numbered questions below, graded; Approved only if no [Blocker] stands.

### Context for the Reviewer

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/730 — `git push` from the operator's primary clone was refused
by the pre-push gate: `test/agent-chorus.sh` red on one assertion ("legacy symlink not repointed"), while the same
suite on pristine `origin/development` was 215/0. Commit under review: `5fca8017` on
`fix/gh730-agent-chorus-legacy-fixture` (base `origin/development` bd8c6950). The embedded artifact is its diff
for the three files that matter; `releases.db`/`releases.sql`/`LEADERBOARD.md` also changed via the ledger CLI only.

**Operational envelope:** a local developer test suite and its gate prologue in a single-repo CLI harness. Grade
against the two stated root causes and commensurate complexity — no enterprise fail-safes, no ghost-directory
detectors, no installer broadening (the issue's own item 2 is a declared non-goal).

Read, in the worktree: `skills/agent-chorus/install.sh` (`migrate_legacy_link`, lines ~24-45),
`test/agent-chorus.sh` lines ~700-760, `relay-automation/gate-env.sh` (whole), `validate.sh:12` (sources it) and
`validate.sh:1340-1350` (tail-40 of a failing suite's serial re-run).

Evidence already produced by the Producer (unsandboxed, this clone): red control with a stale
`skills/agent2agent/scripts/__pycache__/` → 214/1 on the reported assertion; after fix → 215/0 with and without
the ghost; installer repoint disabled → 214/1 on the same assertion (strictness kept); gate-env'd run → 215/0 and
zero `__pycache__` dirs under `skills/ test/ utils/`; `test/gh441-gate-env-contract.sh` → 16/0.

### Questions

1. Root cause 1: does the new fixture target `$WORK/pre-rename-clone/skills/agent2agent` satisfy every branch the
   installer takes — `[ -L ]`, `[ -e ]` false, and the `case` arm `*"/skills/$LEGACY_SKILL_NAME"` — so the repoint
   is exercised for real and not skipped? Is there any way this path could exist at test time?
2. Does the assertion remain strict — would a non-repointing installer, or one repointing to the wrong directory,
   still fail it? (The Producer's red control says yes; confirm from the code.)
3. Root cause 2: is `relay-automation/gate-env.sh` the right single place for `PYTHONDONTWRITEBYTECODE=1` — does
   every gate mode (`validate.sh` parallel/sequential/`--tier 2`/`--auto`, `ci-local.sh`, marathon
   `--pre-advance-cmd`) actually source it, and is there a consumer of gate-env.sh for which this export is wrong
   (e.g. anything that relies on bytecode being written, or a suite that asserts on `__pycache__`)?
4. Does the export interfere with the GH-441 scrub contract (`utils/py/gate_env.py`,
   `test/gh441-gate-env-contract.sh`) — e.g. does the registry need to know about it, or does any test assert
   gate-env.sh sets nothing?
5. Survey completeness: the Producer found only one test that links a `$REPO` path expected to be absent
   (`test/agent-chorus.sh:713`) and one other installer with legacy logic (`skills/releases/install.sh`, which
   removes symlinks unconditionally). Can you find another test or installer whose pass/fail depends on the
   clone's untracked/ignored state?
6. The intake doc claims issue item 3 (show the failing line in the refusal) is already served by
   `validate.sh:1345-1346`. Is that true for the parallel path the operator hit? Is it also true for the
   sequential path?
7. Is anything over- or under-engineered here relative to the envelope? Flag unneeded machinery or a missing
   surgical piece.

Output: graded findings ([Blocker]/[Should]/[Nit]/[Pass]) with file:line, each behaviour-change request carrying
`Observed input:` / `Affected scope:` / `Falsifier:`. End with VERDICT and set STATUS to Approved if nothing blocks.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
