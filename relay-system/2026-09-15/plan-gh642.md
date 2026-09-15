---
Goal: Codex plan review — GH-642 consumer-repo fruit tranche (marathon SOP turnkey)
Date: 2026-09-15
NEXT: claude-a
STATUS: Open
---

# Context

Review the PLAN (not an implementation) at `PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md` — a
6-item surgical tranche + 4 deferrals distilled from two foreign-repo marathons
([#621](https://github.com/HiQS-Labs/XYZ-forge/issues/621) run-2 report) and tracked in
[#642](https://github.com/HiQS-Labs/XYZ-forge/issues/642). The tree you are in is the task clone
at `origin/development` @ d5c18633 — read any file for ground truth.

Source paths the plan touches (read them):
- relay-automation/xyz-vendor.sh (gitignore append block ~:230-330; RELEASES_OVERLAY :344)
- relay-automation/claude-turn.sh + utils/py/claude-turn.py + utils/py/claude_cli.py (effort_flags :19)
- relay-automation/marathon-drive.sh + utils/py/marathon_drive.py (relay-task derivation :762, lane-attempt :88-110)
- relay-automation/relay-turn-lib.sh (rtl_worktree_begin; node_modules/.cache pattern :549)
- relay-automation/swarm-preflight.sh (~:883) + utils/py/swarm_preflight.py (:1716, GH-399 :779)

Operational envelope: grade against the plan's stated requirements and the commensurate-complexity
mantra — these are DX fixes to a bash/python harness, not multi-tenant infrastructure. Do not
demand speculative machinery. Findings must cite file:line.

Questions:

1. Ground truth: is every recon claim in the plan's table correct at this HEAD (vendor append
   behavior and its "direction 1/2" asymmetry; effort_flags env name + validation set; RELEASES_OVERLAY
   contents; GH-399 lossy-inline fail)? Cite file:line for any correction.
2. Item 1 (vendor → .git/info/exclude): any consumer or test that RELIES on the rules landing in
   the target .gitignore (check test/xyz-vendor.sh assertions, docs)? Does `git rev-parse --git-path
   info/exclude` cover every vendor target shape (normal clone, linked worktree, --separate-git-dir)?
   Is the direction-2 refusal genuinely untouched by the change?
3. Item 2: is the bash twin's effort support the right parity shape (same env var, same validation
   set, `--effort` appended)? Is a non-fatal stderr warning the right severity for Opus+default-budget,
   or should it refuse? Does anything parse claude-turn's stderr such that a warning line breaks it?
4. Item 3 (spent-token auto-suffix): what is the machine-readable way to detect "spent" (tick info
   status field? claim exit code?) and is it stable across the tick versions in the wild? Failure
   modes when tick is missing entirely? Should the suffixed id persist across subsequent re-fires
   (R2 → R3), and does the lane-attempt-cap key interact?
5. Item 4 (node_modules into the isolated worktree): the plan says symlink. A symlink lets turn
   writes traverse into ROOT/node_modules — does that reopen the containment gap worktree isolation
   exists to close (note rtl's existing 'node_modules/.cache' revert pattern at relay-turn-lib.sh:549)?
   Adjudicate: symlink vs one-shot copy vs leave-unfixed-with-docs. Which is commensurate?
6. Item 5 (xyz-init-clone.sh): right home and shape? Anything in the existing vendor/skill surface
   that already does half of it (skills/relay-xyz/install.sh, xyz-sync.sh)? Flags/naming concerns?
7. Item 6 (zero-criteria stderr warning): exit code unchanged — sufficient? Should it instead be a
   packet-status field? Both twins must agree — any drift risk given the bash twin's age?
8. Coverage: is any #642 requirement missing from the plan's tranche+deferral split? Are the four
   deferrals genuinely feature-sized (vs excuse-sized)? Is the already-landed table accurate?
9. Ratings: is `rated 60/35/50/60` grounded for this batch given the policy axes (sev band for
   workflow-friction-with-real-cost; effort for six dual-runtime items)? 
10. Blast radius, dependency ordering, rollback: any ordering hazard inside p1–p4? Any change here
    that pins or breaks MACHINE-CONTRACTS.md documented behavior?

Write `### Plan Review · codex` below with: per-question answers (file:line citations), a findings
list each tagged BLOCKER / SHOULD / NIT, and one final line `VERDICT: APPROVED` or
`VERDICT: CHANGES REQUESTED` (with the minimal change list). Edit ONLY this relay file. Do NOT run git.

### Plan Review · codex

**Basis:** textual review of the plan and current task-clone source at the stated `d5c18633` tree;
no tests or git commands were run, per the turn contract. The available code graph was useful for
symbol discovery but indexed a newer `development` SHA, so every material conclusion below was
checked against the task-clone files directly. The referenced GitHub issue pages were unavailable to
the web reader, so question 8 is bounded to the issue inventory reproduced in this plan.

#### Per-question answers

1. **Ground truth.** The four recon claims are substantively correct, with one path correction.
   Direction 2 is checked before mutation and only warns/refuses to un-ignore
   (`relay-automation/xyz-vendor.sh:252-294`); direction 1 currently creates/appends the target
   `.gitignore` (`relay-automation/xyz-vendor.sh:296-304`). `RELEASES_OVERLAY` does include
   `utils/py/releases_app.py` (`relay-automation/xyz-vendor.sh:336-344`). Python effort support reads
   `CLAUDE_REASONING_EFFORT`, accepts exactly low/medium/high/xhigh/max, and emits `--effort <v>`
   (`utils/py/claude_cli.py:19-24`). GH-399 builds and verifies the rendered checklist before the
   verdict and makes a lossy render NOT-READY (`utils/py/swarm_preflight.py:1472-1485`). Correction:
   the Bash preflight twin is `utils/swarm-preflight.sh`, not the nonexistent
   `relay-automation/swarm-preflight.sh` named in the review prompt and plan item 6; the frozen-twin
   registry confirms that ownership (`AGENTS.md:237-242`).

2. **Vendor exclude move.** Current tests explicitly depend on `.gitignore`: the base assertions are
   at `test/xyz-vendor.sh:76-77`, the direction-2 matrix expects the two added lines at
   `test/xyz-vendor.sh:105-114`, and rerun idempotence counts a `.gitignore` line at
   `test/xyz-vendor.sh:146-150`. Documentation/comments also encode the destination, notably
   `relay-automation/xyz-vendor.sh:388-392`, `test/gh312-vendor-preserves-state.sh:5-9`, and the
   operator probe in `skills/vendor-stack/SKILL.md:123-127`; they must move with the behavior.
   `git rev-parse --git-path info/exclude` is the correct Git-owned resolver for normal clones,
   linked worktrees, and separate git dirs, but the plan should prove all three shapes rather than
   merely call it worktree-safe. Direction 2 remains untouched if the edit stays below line 296;
   its `git check-ignore` authority already sees info/exclude (`relay-automation/xyz-vendor.sh:252-277`).

3. **Claude parity and warning.** The requested Bash parity shape is correct: the same env name,
   validation set, omission behavior, and a trailing `--effort <v>` matching
   `utils/py/claude-turn.py:67-71,186-194`. A warning is the right severity: selecting Opus is an
   explicit operator choice, while the current comments already say the $0.50 ceiling is Sonnet-sized
   and must be raised for costlier models (`relay-automation/claude-turn.sh:168-183`). Refusal would
   silently turn an advisory cost mismatch into a new policy gate. I found no consumer that parses
   parent shim stderr as a fixed schema; Python deliberately prints diagnostics there and stores CLI
   stderr separately (`utils/py/claude-turn.py:93-98,201-205`), while the subscription suite already
   tolerates wrapper diagnostics (`test/gh610-claude-subscription.sh:241-257`). Emit the warning before
   dispatch, not into the Bash JSON transcript, whose stdout/stderr are combined at
   `relay-automation/claude-turn.sh:230-238`.

4. **Spent-token suffix.** `tick info` is the stable machine-readable seam here: it exits 0 for an
   existing task and prints `status: done|circuit_broken|open|claimed`
   (`bin/tick:458-475`; terminal projection at `src/project.js:209-218`). Claim exit 1 is unsuitable
   because it intentionally conflates terminality, another owner, overlap, and the claim cap
   (`bin/tick:174-177,245-273`). Treat only `done` and `circuit_broken` as spent. If tick is absent or
   its output is malformed, fail before rendering/committing anything; do not interpret probe failure
   as “free.” Scan `-R2`, `-R3`, ... and choose the first task for which `tick info` returns not-found,
   so subsequent forced re-fires persist monotonically. Keep the attempt key unchanged: it is keyed by
   `MARATHON_LANE_NS`/phase, not token (`utils/py/marathon_drive.py:1340-1345,1068-1115`). Resolve the
   suffix before relay rendering and update every downstream identity, especially the receipt's
   `token` field required by `MACHINE-CONTRACTS.md:94-103`; today `_RESULT["token"]` is assigned at
   `utils/py/marathon_drive.py:1340-1341` and the render/seed uses that same variable
   (`utils/py/marathon_drive.py:3127-3141,3178-3184`).

5. **Worktree dependencies.** Reject the symlink. It makes `$wt/node_modules` a writable route into
   `$RTL_ROOT/node_modules`, while containment judges the isolated worktree's own Git state; writes
   through the link can mutate the real checkout without appearing as an off-lane worktree change.
   That contradicts the isolation boundary described at `relay-automation/relay-turn-lib.sh:722-753`.
   The existing `node_modules/.cache` exemption (`relay-automation/relay-turn-lib.sh:538-565`) does not
   make this safe; it only exempts a path observed inside the disposable worktree. Of the three choices,
   a one-shot `cp -R` into the disposable tree is the commensurate safe implementation: simple, no new
   dependency, and turn writes stay disposable. Add an explicit size/time observation to the focused
   test or defer the item with documentation if real-world copy cost is unacceptable; do not ship the
   symlink.

6. **Clone initializer.** A thin initializer is justified; `skills/relay-xyz/install.sh` only installs
   skill symlinks (`skills/relay-xyz/install.sh:31-73`) and `xyz-sync.sh` only manages an already
   vendored install (`relay-automation/xyz-sync.sh:33-55`), so neither already clones a consumer repo.
   The proposed `.sh` home is nevertheless disallowed by the repo's no-new-Bash rail: new executables
   belong in `utils/py/` unless a named exception is justified (`AGENTS.md:266-269`). Make this
   `utils/py/xyz_init_clone.py` (or explicitly justify a `New-bash-exception`), require `--umbrella`
   because marathon triage says an unnamed umbrella is not ready (`skills/marathon-triage/SKILL.md:80-83`),
   validate the <=3-word slug, and use the documented `-r2` retry suffix on an occupied derived name
   (`skills/marathon-triage/SKILL.md:98-110`). Also resolve the plan's contradiction: `--with-releases`
   is shown as optional at plan line 76, while line 78 says vendoring always passes it. The wrapper must
   either forward the flag only when selected or drop the flag and declare Tier 2 mandatory. Refuse a
   pre-existing explicit `--dir`; never merge into it.

7. **Zero criteria.** A non-fatal stderr warning is sufficient. The structured packet already records
   `SP_ACC_INLINE.criteria`, including zero (`utils/py/swarm_preflight.py:1607-1611`), so a second status
   field would duplicate truth. Emit the warning when `acc_items` is known, before the dry-run exit at
   `utils/py/swarm_preflight.py:1688-1694`; the current fallback text is constructed only later at
   `utils/py/swarm_preflight.py:1711-1716`, so placing the warning beside that fallback would miss dry
   runs. Correct the Bash path to `utils/swarm-preflight.sh`. Both twins agreeing is an explicit frozen
   fallback exception, not ordinary maintenance (see question 10).

8. **Coverage and deferrals.** Against the inventory reproduced in this plan, the tranche covers all
   six stated surgical items, the three “already landed” rows are supported by source, and the four
   named deferrals are genuinely feature-sized: they alter retry/token semantics, rendering/attestation,
   intake command shape, or the documented issue-resolution contract (`PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md:42-49,85-97`).
   I cannot independently assert completeness against #642's live body because that page was unavailable
   during this turn; retain that as an explicit review limitation rather than claiming exhaustive issue
   coverage.

9. **Ratings.** 60 priority, 35 severity, and neutral 50 appeal are plausible for repeated workflow
   hard-stops without corruption. Effort-cheapness 60 is optimistic after accounting for two frozen
   fallback edits, a new initializer, cross-Git-layout tests, token/receipt identity, and dependency-copy
   performance. The plan provides no axis rationale at `PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md:10-14`.
   Add one dated sentence and reconsider effort around 45-50 (or explain why 60 remains grounded).

10. **Blast radius, order, rollback, contracts.** p1 before p3 is correct because the initializer
    consumes vendor behavior. In p2, suffix resolution must precede receipt assignment, render, commit,
    heartbeat, and seed; otherwise one execution advertises two token identities. Item 4 must use a copy
    or defer, as above. Item 6's real Bash twin is frozen. More broadly, `claude-turn.sh`,
    `marathon-drive.sh`, and `utils/swarm-preflight.sh` are frozen (`AGENTS.md:237-258`), so the plan must
    name the required per-file `Frozen-twin-exception` trailers or drop fallback edits; a new `.sh`
    initializer separately needs `New-bash-exception` (`AGENTS.md:266-269`). Changes under
    `relay-automation/` also require regenerating `skills/relay-automation/relay-pkg.tar.gz` and running
    its freshness check. Finally, plan lines 101-112 schedule `test/*.sh`, `validate.sh`, and `ci-local.sh`
    without the mandated disposable-full-clone boundary (`AGENTS.md:15-16,319`); revise verification so
    mutation-heavy suites never run in the task clone whose state matters. Item 3 must preserve Contract
    B's resolved `token` value (`MACHINE-CONTRACTS.md:94-103`); no schema version change is needed.

#### Findings

- **BLOCKER — unsafe containment:** replace item 4's `node_modules` symlink with a disposable one-shot
  copy, or defer the item and document the missing-dependency limitation
  (`PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md:71-74`; `relay-automation/relay-turn-lib.sh:722-753`).
- **BLOCKER — plan violates executable/twin governance:** change the initializer to Python (or justify
  the exact new-Bash exception), correct preflight to `utils/swarm-preflight.sh`, and name the required
  frozen-twin exceptions for every fallback edit (`AGENTS.md:237-269`).
- **BLOCKER — unsafe verification location:** put focused suites and both full gates in a separate
  disposable full clone and add relay-package regeneration/freshness verification
  (`PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md:99-121`; `AGENTS.md:15-16,319`).
- **SHOULD — token identity is under-specified:** define terminal statuses, malformed/missing-tick
  refusal, R2/R3 scanning, and assignment before every render/receipt consumer
  (`utils/py/marathon_drive.py:1340-1345,3127-3184`; `MACHINE-CONTRACTS.md:94-103`).
- **SHOULD — initializer contract is ambiguous:** require the umbrella, pin occupied-name `-r2`
  behavior, refuse an existing `--dir`, and resolve optional-vs-always `--with-releases`
  (`skills/marathon-triage/SKILL.md:80-110`; plan lines 75-80).
- **SHOULD — vendor blast radius is wider than one test assertion:** update stale comments/docs and
  add normal/linked/separate-git-dir fixtures for the exclude destination
  (`test/xyz-vendor.sh:76-77,105-114,146-150`; `skills/vendor-stack/SKILL.md:123-127`).
- **NIT — rating evidence:** add the short axis rationale and reconsider effort-cheapness 60
  (`PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md:10-14`).

**Minimal change list:** (1) copy or defer item 4; (2) correct item 6's path and all frozen/new-Bash
governance; (3) move verification to a disposable full clone and regenerate the relay package; (4)
make suffix selection/receipt identity and failure behavior explicit; (5) close the initializer's
umbrella/retry/destination/Tier ambiguity.

VERDICT: CHANGES REQUESTED

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex — PLAN REVIEWER role; ALLOW_PATHS is empty: this relay file is your only
writable path; review the plan against the code, never edit code)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
