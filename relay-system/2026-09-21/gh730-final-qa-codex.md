# RELAY · Final QA: GH-730 agent-chorus legacy fixture + gate no-bytecode
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
-->

NEXT: Producer
STATUS: Approved
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

### Reviewer — codex — Round 1

swept file: yes

- [Pass] Root cause 1 is fixed without weakening the branch under test. The suite creates a fresh
  guarded `$WORK` (`test/agent-chorus.sh:9-27`), and the only occurrence of `pre-rename-clone` in the
  swept file is the link target at `test/agent-chorus.sh:718`; therefore the link exists, its target
  does not, and the target text still ends in `/skills/agent2agent`. That reaches the installer's
  `[ -L ]` guard, false `[ -e ]`, and legacy-name `case` arm at
  `skills/agent-chorus/install.sh:28-38`. Static probe:
  `rg -n 'pre-rename-clone' test/agent-chorus.sh` exited 0 with only
  `718:ln -s "$WORK/pre-rename-clone/skills/agent2agent" ...`.

- [Pass] The assertion remains strict. `test/agent-chorus.sh:721-738` reads the resulting link and
  requires a non-empty target that is `-ef` the real `skills/agent-chorus` directory. A
  non-repointing installer leaves a dangling target, which cannot satisfy `-ef`; a wrong live target
  has a different inode and also fails. The swept-file explanation states those two discriminating
  cases explicitly at `test/agent-chorus.sh:729-731`.

- [Blocker] Root cause 2 is fixed for every `validate.sh` mode, but not for the other gate paths the
  Definition of Done explicitly asks about. `validate.sh:12` sources the helper before mode/tier
  parsing (`validate.sh:686-793`), so parallel, sequential, tier 2, and auto inherit the export.
  However, `ci-local.sh` never sources `gate-env.sh` and launches suites/Pytest directly at
  `ci-local.sh:297` and `ci-local.sh:318`; its `validate.sh --list` child at `ci-local.sh:367` cannot
  export back into the parent. Likewise an explicit marathon command is selected at
  `utils/py/marathon_drive.py:1367-1368`, while `_gate_env()` only copies and scrubs at
  `utils/py/marathon_drive.py:2279-2283` before passing that environment to the command at
  `utils/py/marathon_drive.py:2310-2318`. The default marathon gate is covered because it resolves to
  `validate.sh` (`utils/py/marathon_drive.py:1385-1387`); an explicit `--pre-advance-cmd` is not.
  Static probe command:
  `rg -n 'gate-env\.sh|PYTHONDONTWRITEBYTECODE' ci-local.sh; rg -n 'bash "test/\$t"|python3 -m pytest' ci-local.sh; rg -n 'PYTHONDONTWRITEBYTECODE' utils/py/marathon_drive.py relay-automation/marathon-drive.sh`.
  Exit statuses were `1`, `0`, `1`; decisive output was `ci-local.sh:297`, `ci-local.sh:318`, and no
  bytecode-setting match in either marathon driver.
  Concrete fix: source the shared helper in `ci-local.sh`, and make the marathon gate environment set
  `PYTHONDONTWRITEBYTECODE=1` for explicit pre-advance commands (including the supported Bash fallback),
  with a contract assertion for both consumers.
  Observed input: ordinary `ci-local.sh` with `PYTHONDONTWRITEBYTECODE` initially unset, and
  `marathon-drive --pre-advance-cmd '<Python-bearing gate>'`; the static launch paths above pass the
  unchanged caller environment to Python-bearing work.
  Affected scope: full/`--probe` `ci-local.sh` suite runs and explicit marathon pre-advance commands;
  `validate.sh` modes and the default marathon gate are already covered.
  Falsifier: from an initially unset shell, a hermetic environment-capture fixture for each launch
  path must observe `PYTHONDONTWRITEBYTECODE=1`; a Producer/build turn must still observe it unset.
  A full suite confirmation is [Unverified — needs clone run].

- [Pass] The new export does not conflict with the GH-441 scrub registry. The registry governs
  variables exported by drivers (`utils/py/gate_env.py:23-30,57-140`); the shell helper's no-second-
  unset-list checks are `test/gh441-gate-env-contract.sh:69-103`, and its consumer check is
  `test/gh441-gate-env-contract.sh:145-151`. The new export is after the scrub and cleanup at
  `relay-automation/gate-env.sh:83-91`, so it neither adds a driver export nor duplicates the unset
  registry. A scratch probe also confirmed explicit compilation still behaves explicitly:
  `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile "$TMPDIR/gh730-pycompile-probe.py"` exited 0 and
  produced `$TMPDIR/__pycache__/gh730-pycompile-probe.cpython-314.pyc`; therefore the existing
  `py_compile` assertions are not disabled by this setting.

- [Pass] The surveyed clone-state class is complete on the current tree to the limits of a
  repository-wide literal/source search. The only skill installers containing legacy migration logic
  were `skills/agent-chorus/install.sh:18-47` and `skills/releases/install.sh:20-39,72-77`; the latter
  removes legacy symlinks based on link type, not whether a repository target path happens to exist.
  The other named absence assertion checks a tracked file, not a directory
  (`test/test_deploy_skills.py:547-549`). Targeted `rg` searches across `skills/**/install.sh` and
  `test/**` found no second test linking a real `$REPO`/`$ROOT` path as an expected-absent legacy
  target. The current worktree graph index attempt failed, so the negative claim rests on the full
  source sweep and literal search; the older primary-clone coverage report had known parser gaps, and
  the relevant reported ranges in `test/agent-chorus.sh` were read directly.

- [Pass] Issue item 3 is already served on both execution paths. A parallel failure is rerun alone,
  and a real failure prints the final 40 serial lines before classification
  (`validate.sh:1330-1347`). A forced sequential run streams each suite directly to the operator,
  including its failing assertion, at `validate.sh:1383-1401`; it does not need the tail replay.

- [Should] Pre-existing swept-file defect: sourcing `gate-env.sh` clobbers/leaks generic caller
  variables. The helper assigns `_src` and `_hp_lib` at `relay-automation/gate-env.sh:27-39`, but its
  cleanup unsets the nonexistent `_ge_src` and omits `_hp_lib` at
  `relay-automation/gate-env.sh:83`. Probe command:
  `bash -c '_src=caller; unset _hp_lib; . ./relay-automation/gate-env.sh; printf "src=%s\\nhp=%s\\n" "${_src-unset}" "${_hp_lib-unset}"'`.
  Exit 0; decisive output was `src=./relay-automation/gate-env.sh` and
  `hp=<repo>/relay-automation/harness-paths.sh`. Rename these internals consistently to `_ge_src` /
  `_ge_hp_lib` (and clean them) so a sourced helper preserves caller state.
  Observed input: a custom gate with `_src=caller` sources the documented shared helper.
  Affected scope: any `gate-env.sh` consumer that already uses `_src` or `_hp_lib`; current
  `validate.sh` happens not to rely on them after sourcing.
  Falsifier: the same probe must exit 0 with `src=caller` and `hp=unset`, while the scrubbed variables
  remain absent and `PYTHONDONTWRITEBYTECODE=1` remains exported.

- [Pass] Beyond the helper namespace leak above, the full touched files were swept and no additional
  pre-existing defect was identified: `relay-automation/gate-env.sh:1-91`,
  `test/agent-chorus.sh:1-1393`, and
  `PROJECT/1-INBOX/GH-730-AGENT-CHORUS-LEGACY-FIXTURE.md:1-102`.

VERDICT: FAIL

Basis: the fixture repair is correct, strict, and appropriately surgical, but the claimed gate-wide
no-bytecode behavior does not reach `ci-local.sh` or explicit marathon pre-advance commands. The
focused Producer receipts were not rerun in this reviewer worktree per the relay safety rule; the
full disposable-clone gate remains pending after the blocker is fixed.

handing off to Producer — go to the Producer window and say 'take your turn'

### Producer — claude-a — Round 1 response

Revision under review is now commit `9186eaae` (on top of `5fca8017`). Dispositions:

- **[Blocker] ci-local.sh / explicit marathon `--pre-advance-cmd`** — Accepted for `ci-local.sh`: it now
  sources `relay-automation/gate-env.sh` right after `HERE` (`ci-local.sh:70-74`); this also closes the
  GH-441 scrub gap you noticed (the qualifying runner never sourced the prologue at all).
  `Disposition: Rejected (Out of Scope / Ponytail)` for `marathon_drive._gate_env()`: the helper's own
  contract (`gate-env.sh:2-3`, "SOURCE this at the top of any --pre-advance-cmd") already places the
  export in a custom gate's hands, and the default gate resolves to `validate.sh`
  (`utils/py/marathon_drive.py:1385-1387`). A second writer for gate environment inside the driver is
  the exact duplication GH-441 removed. Contract assertion added for the accepted consumer:
  `test/gh441-gate-env-contract.sh` C7a.
- **[Should] `_src`/`_hp_lib` leak** — Accepted. All scratch names are `_ge_`-prefixed and unset
  (`gate-env.sh:29-43, 96`). Your falsifier now yields `src=caller hp=unset pdb=1`; pinned as C8a.
- All **[Pass]** findings — acknowledged, no change.

Evidence (unsandboxed, this clone): `test/gh441-gate-env-contract.sh` → 18 pass, 0 fail. Red controls:
pre-fix `ci-local.sh` → C7a FAIL; pre-fix `gate-env.sh` → C8a FAIL with
`got 'unset|<repo>/relay-automation/gate-env.sh|<repo>/relay-automation/harness-paths.sh'`.
The full `./validate.sh` gate runs once on the approved commit via the pre-push hook, after your verdict.

Round-2 diff (commit `9186eaae`):

````diff
commit 9186eaae4c25310bcfc6ef881db00557ab9f5178
Author: Noel Saw <56978803+noelsaw1@users.noreply.github.com>
Date:   Mon Sep 21 11:38:51 2026 -0700

    fix(gate): ci-local.sh sources gate-env.sh; helper keeps its scratch names to itself (GH-730 r1)
    
    Codex round-1 findings on the GH-730 final QA:
    - Blocker (accepted in part): ci-local.sh launches suites and pytest directly
      and never sourced relay-automation/gate-env.sh, so the qualifying run got
      neither the GH-441 scrub nor the GH-730 no-bytecode rule. One source line.
      The explicit marathon --pre-advance-cmd half is rejected: the helper's own
      contract makes a custom gate source it, and the default gate is validate.sh.
    - Should (accepted): gate-env.sh assigned bare _src/_dir/_hp_lib and unset a
      nonexistent _ge_src, leaking into any caller that sourced it. All scratch
      names are now _ge_-prefixed and unset.
    - test/gh441-gate-env-contract.sh gains C7a (ci-local.sh consumes the helper)
      and C8a (helper exports PYTHONDONTWRITEBYTECODE=1 and leaves _src/_hp_lib
      alone). Both red against the pre-fix files, 18/0 after.
    
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>

diff --git a/ci-local.sh b/ci-local.sh
index 7d24fb28..91ba14c0 100755
--- a/ci-local.sh
+++ b/ci-local.sh
@@ -68,6 +68,11 @@ set -uo pipefail
 HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 cd "$HERE" || exit 1
 
+# The same gate-environment prologue validate.sh sources (GH-441 scrub of ambient marathon exports;
+# GH-730 no-bytecode rule). This runner launches suites and pytest directly below, so it must source
+# it itself — a `validate.sh --list` child cannot export back into this shell.
+. "$HERE/relay-automation/gate-env.sh"
+
 # ── GH-45: REFUSE to run from a linked git worktree ─────────────────────────────────────────────
 # Same guard, same reason, same override as validate.sh's (kept inline in both rather than a new
 # shared .sh — GH-551; both copies are pinned by test/gh35-test-tiers.sh): this script runs the
diff --git a/relay-automation/gate-env.sh b/relay-automation/gate-env.sh
index eadc2ab7..d227f7ea 100644
--- a/relay-automation/gate-env.sh
+++ b/relay-automation/gate-env.sh
@@ -24,18 +24,20 @@
 
 # Resolve the harness root from this script's own location, following symlinks, so sourcing works
 # from any CWD and from a vendored .xyz/ install. No machine path is ever hardcoded.
-_src="${BASH_SOURCE[0]:-$0}"
-while [ -h "$_src" ] || [ -L "$_src" ]; do
-  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
-  _src="$(readlink "$_src")"
-  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
+# Every scratch name here is `_ge_`-prefixed and unset at the end: this file is SOURCED, so a bare
+# `_src` or `_hp_lib` would clobber the caller's own (GH-730 review finding).
+_ge_src="${BASH_SOURCE[0]:-$0}"
+while [ -h "$_ge_src" ] || [ -L "$_ge_src" ]; do
+  _ge_ldir="$(cd -P "$(dirname "$_ge_src")" >/dev/null 2>&1 && pwd)"
+  _ge_src="$(readlink "$_ge_src")"
+  case "$_ge_src" in /*) ;; *) _ge_src="$_ge_ldir/$_ge_src" ;; esac
 done
-_ge_dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
+_ge_dir="$(cd -P "$(dirname "$_ge_src")" >/dev/null 2>&1 && pwd)"
 
-_hp_lib="$_ge_dir/harness-paths.sh"
-if [ -f "$_hp_lib" ]; then
+_ge_hp_lib="$_ge_dir/harness-paths.sh"
+if [ -f "$_ge_hp_lib" ]; then
   # shellcheck source=relay-automation/harness-paths.sh
-  . "$_hp_lib"
+  . "$_ge_hp_lib"
 fi
 _ge_root="$(cd -P "$_ge_dir/.." && pwd)"
 _ge_py="$_ge_root/utils/py/gate_env.py"
@@ -80,7 +82,7 @@ else
   return 1 2>/dev/null || exit 1
 fi
 
-unset _ge_src _ge_dir _ge_root _ge_py _ge_names _ge_n
+unset _ge_src _ge_ldir _ge_dir _ge_hp_lib _ge_root _ge_py _ge_names _ge_n
 
 # GH-730: no bytecode into the tree from a gate run. Suites import repo modules directly
 # (importlib in test/agent-chorus.sh, the unittest files under test/), and every such import
diff --git a/test/gh441-gate-env-contract.sh b/test/gh441-gate-env-contract.sh
index 4b188dca..0aaa6933 100755
--- a/test/gh441-gate-env-contract.sh
+++ b/test/gh441-gate-env-contract.sh
@@ -150,5 +150,16 @@ printf '%s' "$orphan_out" | /usr/bin/grep -q "GH-441" \
   && pass "C6b validate.sh no longer hardcodes its own prologue" \
   || fail "C6b validate.sh still carries the duplicated unset line"
 
+# ── C7 (GH-730): ci-local.sh is a gate entry point too — it launches suites and pytest directly ──
+/usr/bin/grep -q "gate-env.sh" "$ROOT/ci-local.sh" \
+  && pass "C7a ci-local.sh sources the shared helper" \
+  || fail "C7a ci-local.sh does not source gate-env.sh — its suites run with an ungoverned environment"
+
+# ── C8 (GH-730): sourcing the helper sets the no-bytecode rule and leaves the caller's names alone ──
+c8_out="$(env -u PYTHONDONTWRITEBYTECODE bash -c '_src=caller; unset _hp_lib; . "$1"; printf "%s|%s|%s" "${PYTHONDONTWRITEBYTECODE-unset}" "${_src-unset}" "${_hp_lib-unset}"' _ "$HELPER" 2>/dev/null)"
+[ "$c8_out" = "1|caller|unset" ] \
+  && pass "C8a the helper exports PYTHONDONTWRITEBYTECODE=1 and does not clobber a caller's _src/_hp_lib" \
+  || fail "C8a expected '1|caller|unset', got '$c8_out'"
+
 printf '  gh441-gate-env-contract: %s pass, %s fail\n' "$PASS" "$FAIL"
 [ "$FAIL" -eq 0 ]
````

Questions for round 2: (a) does the `ci-local.sh` source line sit early enough — before any suite or
pytest launch — and is there any ordering hazard with the GH-45 worktree guard below it? (b) does the
`_ge_` rename leave any reference to the old names? (c) anything else blocking Approved?

handing off to Reviewer

### Reviewer — codex — Round 2

swept file: yes

- [Pass] `ci-local.sh` now sources the shared gate environment before every suite or pytest launch.
  The runner establishes `HERE`, changes into it, and sources the helper at `ci-local.sh:66-74`; the
  direct suite and pytest launches are much later at `ci-local.sh:302` and `ci-local.sh:323`. The
  GH-45 worktree refusal follows at `ci-local.sh:76-99`, but there is no ordering hazard: before
  exporting the no-bytecode rule, the helper only resolves its own paths and invokes
  `utils/py/gate_env.py`, whose imports are standard-library `os` and `sys`
  (`relay-automation/gate-env.sh:29-61`, `utils/py/gate_env.py:51-52`). No mutation-heavy gate was run
  in this reviewer worktree.

- [Pass] The `_ge_` rename is complete and the cleanup covers every helper-owned scratch name.
  Assignments are `_ge_src`, `_ge_ldir`, `_ge_dir`, `_ge_hp_lib`, `_ge_root`, `_ge_py`, `_ge_names`,
  and `_ge_n` at `relay-automation/gate-env.sh:29-70`; all are unset at
  `relay-automation/gate-env.sh:85`. Static/source probe command:
  `env -u PYTHONDONTWRITEBYTECODE bash -c '_src=caller; unset _hp_lib; . "$1"; printf "src=%s hp=%s pdb=%s\\n" "${_src-unset}" "${_hp_lib-unset}" "${PYTHONDONTWRITEBYTECODE-unset}"' _ "$PWD/relay-automation/gate-env.sh"`.
  Exit status was 0; decisive output was `src=caller hp=unset pdb=1`. `bash -n ci-local.sh
  relay-automation/gate-env.sh` also exited 0.

- [Pass] The new C7 source-consumer assertion is not vacuous under deletion of the line it guards.
  It checks the only exact `gate-env.sh` occurrence in `ci-local.sh`
  (`test/gh441-gate-env-contract.sh:153-156`). Mutation probe command:
  `sed '/^[[:space:]]*\\. .*gate-env\\.sh/d' ci-local.sh | rg -n 'gate-env\\.sh'`.
  Exit status was 1 with no output, so removing the source line makes C7 fail rather than leaving a
  comment match behind. The Producer's reported 18/0 executable-fixture result remains
  [Unverified — needs clone run] here by relay policy.

- [Pass] The Producer's explicit-marathon disposition is acceptable within the declared contract.
  A repo-owned gate entry point that directly launches suites (`ci-local.sh`) now sources the helper;
  the default marathon gate remains `validate.sh`. An arbitrary custom `--pre-advance-cmd` is the
  documented extension point and must source the helper itself, stated at
  `relay-automation/gate-env.sh:2-4` and `utils/py/gate_env.py:158-163`. Adding a second implicit
  writer inside the marathon driver is not required to satisfy that contract.

- [Nit] Pre-existing swept-file documentation mismatch: `ci-local.sh:425-427` says `--probe` does
  not exercise the suite, but suite execution is gated only by `FAST` at `ci-local.sh:397-405`;
  `PROBE` instead prevents the evidence record at `ci-local.sh:435`. This does not affect GH-730 or
  the runner's behavior, but the comment should eventually say that probe runs are intentionally
  non-qualifying rather than suite-free.

- [Pass] The full revised files were swept: `ci-local.sh:1-449`,
  `relay-automation/gate-env.sh:1-93`, and `test/gh441-gate-env-contract.sh:1-165`. No additional
  blocking defect was identified. The current relay worktree is not present in the codebase-memory
  project list; the closest XYZ index is dated 2026-09-18 and marks the changed contract test stale,
  so current-worktree source reads above are the authority rather than stale graph results.

VERDICT: PASS

Basis: the fixture repair remains correct, `validate.sh` and the qualifying `ci-local.sh` runner now
share the no-bytecode prologue, the helper no longer clobbers the reported caller names, and the new
contract check demonstrably fails when its source line is removed. The full disposable-clone gate is
still the post-relay harness step, not reviewer evidence.

relay closed (Approved), no further turn needed


### Attestation · relay-drive — 2026-09-21T18:46:42Z
task: RELAY-gh730-final-qa-codex
reviewer: codex
status: Approved
reviewed-head: 2ef7850ae53cfb87e486147416a20da86d96e3af
added-range: 34865+3869
added-sha256: 55501788de9d741fa8a200a7738210834e7f19e5bd8a5c40c2b0aafd94ef7c1c
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
