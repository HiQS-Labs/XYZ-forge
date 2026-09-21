# RELAY · Plan QA: GH-744 skills/ frequency-tier reorganization
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh744-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md` (the plan; committed at 51aeb57c)
- Reviewer: agy   ·   Producer: claude-a   (re-pointed from codex 2026-09-21: codex-cli 0.154.0-alpha.6.2 fails every tool call with `missing field code_mode_host_duration_ns`; operator chose agy)
- Started: 2026-09-21
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/744
- Definition of Done: the plan is grounded in the actual paths, complete against the issue's four
  requirements, extends the existing scanners/publishers/locators rather than adding a parallel
  subsystem, and its acceptance checks would actually catch the failures they claim to.

### Operational envelope (grade against THIS, not an imagined one)
A one-time `git mv` of 60 skill directories into four tier folders inside a single-maintainer
developer harness repo, plus repointing the code and docs that address `skills/<name>`. No runtime
service, no multi-tenant surface, no data migration. Machinery and tests must stay commensurate:
no resolver library, no registry file, no layout fuzzer, no compatibility symlink layer unless you
can show a concrete consumer that breaks without it (cite it). The Producer will disposition
requests for unrequested machinery as `Rejected (Out of Scope / Ponytail)`.

### Read these (repo-relative, all in the worktree at HEAD)
- The plan doc above — in full, including the Recon section and the Ordered implementation list.
- `utils/py/skill_drift_check.py` (the `scan()` glob), `utils/py/xyz_mini_sync.py` (MANIFEST),
  `utils/ci-route.sh:24-50,300-320` (subsystem registry), `relay-automation/xyz-vendor.sh:425-445` (VENDOR_DIRS).
- `skills/relay-xyz/find-harness.sh:100-215`, `skills/hq/find-hq.sh:35-70`, `skills/file-xyz-bug/find-xyz.sh:40-70`,
  `skills/vendor-stack/find-pdda.sh:20-40`, `skills/vendor-stack/install.sh:45-55`,
  `skills/relay-to-issue/relay-to-issue.sh:45-52`, `skills/relay-automation/make-pkg.sh`,
  `skills/agent-chorus/scripts/agent_chorus.py:79-90`, `skills/merge-cleanup/scripts/scan_clones.py:185-195`.
- `mini/skills/skill-viewer/scripts/list_skills.py:64-85` (why it is NOT changed).
- `test/gh396-find-harness-roots.sh`, `test/hq-locator.sh`, `test/gh660-skill-drift.sh`, `test/path-integrity.sh:20-60,130-150`, `test/ci-route.sh:60-80,150-190`.
- `ARCHITECTURE.md:35-100` (the Skills Index the plan regroups).

### Questions (answer each by number; cite file:line)
1. Consumers: run `grep -rn -E 'skills/[a-z0-9-]+' --include='*.sh' --include='*.py' --include='*.yml' --include='*.json' .` (excluding `.git`, `CHANGELOG.md`, `relay-system/`, `marathon-system/`, `PROJECT/`, `temp/`, `.xyz/`) and name any executable consumer of a `skills/<name>` path that the plan's Recon section does NOT list. Ignore comment-only hits.
2. Locators: for each bash locator listed, is `../..` → `../../..` the complete change, or does another self-relative derivation in that file (e.g. the `_hp_lib` source line, a `LIVE_HARNESS` probe) also need it? Is there any locator that also runs from a FLAT layout (XYZ-mini publish, Deployed Skills copy) where a depth bump would mis-resolve rather than fall through?
3. `agent_chorus.py` and `scan_clones.py` are published/copied to flat layouts too. Does the plan's "walk up to the nearest ancestor containing `skills/` (or `bin/tick`), fall back to `parents[3]`" resolve correctly at both depths and in a vendored `.xyz/`? Name a concrete layout where it picks the wrong root, if one exists.
4. `skill_drift_check.py`: the plan keeps one-level scanning for XYZ-mini collections and adds two-level for forge. Does `test/gh660-skill-drift.sh` still act as a red control (detect drift on its own fixture) after that change, or does it need a two-level fixture to prove the new branch?
5. `ci-route.sh`: will `skills/*/hq/*`-style globs in the `case` statement match `git diff --name-only` output correctly (bash `case` globbing, `*` matching `/`)? Cite the exact line pattern that would be wrong if so.
6. Tier assignment: the operator anchored 9 skills; the Producer placed the other 51. Is any placement contradicted by that skill's own trigger description (cite the SKILL.md line)? This is advisory — one `[Nit]` per disagreement, not a blocker.
7. Rating `55/25/50/45`: is any axis contradicted by evidence in the repo (e.g. an open issue showing this layout blocks work, which would raise sev/pri)? Appeal must stay 50 unless the operator set it.
8. Missing requirement: does the plan omit anything the issue's Acceptance section requires, or anything AGENTS.md / ROUTER.md requires for a change of this shape (issue-first, PDDA capture, CHANGELOG, full gate in a disposable clone)?
9. Rollback: is a single revert of the merge commit actually sufficient, or does any generated artifact (`relay-pkg.tar.gz`, `releases.sql`, a security-scan baseline) need a paired action?

Output: one graded finding per question (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), file:line cited,
`swept file: yes|no`, then `VERDICT: PASS|FAIL` and `Basis:`. Set `STATUS: Approved` on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Review (agy) — Round 1 · 2026-09-21

swept file: yes

Pre-existing defects in plan file: none found beyond the missing recon references and unupdated locator/scanner lines identified in the findings below.

#### Findings

1. **Consumers** `[Blocker]`
   - `repro.sh:165,167,276`: Directly executes and checks `skills/relay-xyz/find-harness.sh` (`if [ -x skills/relay-xyz/find-harness.sh ]; then bash skills/relay-xyz/find-harness.sh --check ...` and `grep -q 'AGY_BIN' skills/relay-xyz/find-harness.sh`). Missing from the plan's Recon section (`PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md:78-144`) and Ordered implementation list (`:185-205`).
   - `skills/agent-chorus/publish-manifest.tsv:4-15`: Declares 12 canonical source paths (`skills/agent-chorus/...`), which `skills/agent-chorus/sync-to-standalone.sh:78` validates with `[ -f "$SOURCE_REPO/$source_rel" ] || exit 1`. Unlisted in Recon or implementation plan; moving `skills/agent-chorus/` breaks `sync-to-standalone.sh`.
   - `skills/agent-chorus/standalone/ci.yml:24`: Executes `bash "$RUNNER_TEMP/XYZ-forge/skills/agent-chorus/sync-to-standalone.sh" --check` (categorized under docs in plan at `:133`, but is an executable GitHub Actions workflow).
   - `skills/review-xyz/scripts/review_engine.py:9`: Root resolver omitted from Recon; breaks when moved into tier directory (see Finding 2).
   - **Fix:** Add `repro.sh:165,167,276`, `skills/agent-chorus/publish-manifest.tsv:4-15`, and `skills/agent-chorus/standalone/ci.yml:24` to Recon and Step 8/5.
   - `Observed input:` Execution of `./repro.sh` and `skills/agent-chorus/sync-to-standalone.sh --check` after moving `skills/relay-xyz` and `skills/agent-chorus`.
   - `Affected scope:` `repro.sh:165,167,276`, `skills/agent-chorus/publish-manifest.tsv:4-15`.
   - `Falsifier:` In a tiered tree without these repoints, `repro.sh` skips/fails `find-harness.sh --check` and `sync-to-standalone.sh --check` exits 1 with `Missing source file`.

2. **Locators** `[Blocker]`
   - `skills/relay-xyz/find-harness.sh:103,172,207`: All three lines (`_hp_lib`, case 5 `_cand`, `LIVE_HARNESS`) require `../../..`. The plan correctly lists all three at `PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md:100`.
   - `skills/file-xyz-bug/find-xyz.sh:70`: Plan cites lines 46 and 64 (`:101`), but misses line 70: `for _l in "$HOME/.claude/skills/relay-xyz/find-harness.sh" "$SELF_DIR/../relay-xyz/find-harness.sh"`. Line 70 derives `relay-xyz` as a sibling. Under tiers, `file-xyz-bug` is in `skills/2-daily/` while `relay-xyz` is in `skills/1-hourly/`, so `"$SELF_DIR/../relay-xyz/find-harness.sh"` silently misses.
   - `skills/relay-automation/make-pkg.sh:11,30`: Plan cites line 5 (`cd ../..`) at `:102`, but misses line 11 (`tar czf skills/relay-automation/relay-pkg.tar.gz`) and line 30, which write the archive to the old un-tiered path.
   - `skills/review-xyz/scripts/review_engine.py:9`: Completely omitted from the plan. Line 9 derives `XYZ_ROOT = os.path.dirname(os.path.dirname(SKILL_DIR))`. Under tiering, `SKILL_DIR` is `skills/2-daily/review-xyz`, so `XYZ_ROOT` resolves to `skills/` instead of the repository root, and `review_engine.py` fails with exit 2 (`cannot locate review_xyz.py at <root>/skills/utils/py/review_xyz.py`).
   - Flat layout behavior: No bash locator is published to XYZ-mini (`utils/py/xyz_mini_sync.py:29-59`). In a Deployed Skills copy, every bash locator guards self-relative resolution with specific marker checks (`_has_harness`, `_has_hq`, `_is_intake`, `_is_pdda_repo`); since `../../..` lands in `$HOME` or `/Users` which lack these markers, all locators safely fall through rather than mis-resolving.
   - **Fix:** Update `find-xyz.sh:70` to target `../../1-hourly/relay-xyz/find-harness.sh`, update `make-pkg.sh:11,30` to target `skills/1-hourly/relay-automation/relay-pkg.tar.gz`, and update `review_engine.py:9` with an extra `os.path.dirname` call.
   - `Observed input:` `find-xyz.sh` step 3 fallback invocation; `make-pkg.sh` execution; `review_engine.py` invocation from `skills/2-daily/review-xyz/scripts/`.
   - `Affected scope:` `skills/file-xyz-bug/find-xyz.sh:70`, `skills/relay-automation/make-pkg.sh:11,30`, `skills/review-xyz/scripts/review_engine.py:9`.
   - `Falsifier:` Executing `python3 skills/2-daily/review-xyz/scripts/review_engine.py` exits 2 without adding a third `dirname`.

3. **Python walk-up in vendored `.xyz/`** `[Blocker]`
   - `skills/merge-cleanup/scripts/scan_clones.py:190`: Walking up to find `bin/tick` correctly resolves `<repo>/bin/tick` in canonical forge and `<repo>/.xyz/bin/tick` in vendored `.xyz/`, matching the docstring at line 186 ("The harness's own `bin/tick`, then PATH").
   - `skills/agent-chorus/scripts/agent_chorus.py:85`: The plan's proposed "walk up to the nearest ancestor containing `skills/`, fall back to `parents[3]`" (`PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md:104`) FAILS in a vendored `.xyz/` layout (`<consumer>/.xyz/skills/...`). In a vendored layout, `<consumer>/.xyz` contains `skills/`, so the nearest ancestor containing `skills/` is `<consumer>/.xyz`. This sets `default_root()` to `<consumer>/.xyz` instead of `<consumer>`, directing `relay-system/` into `<consumer>/.xyz/relay-system/` instead of `<consumer>/relay-system/` (`agent_chorus.py:188`). Furthermore, in a Deployed Skills copy outside a repository, no ancestor contains `skills/` and falling back to `parents[3]` resolves to `~/Documents`.
   - **Fix:** In `agent_chorus.py:default_root()`, check whether the resolved ancestor is named `.xyz` and take its parent (`if root.name == ".xyz": root = root.parent`), matching `skills/relay-xyz/find-harness.sh:127-130` and `utils/py/harness_paths.py`.
   - `Observed input:` Vendored setup at `<consumer>/.xyz/skills/2-daily/agent-chorus/scripts/agent_chorus.py`.
   - `Affected scope:` `skills/agent-chorus/scripts/agent_chorus.py:81-86`.
   - `Falsifier:` In a vendored checkout, `agent_chorus.py` resolves `root` to `.xyz` directory rather than consumer repository root unless it steps up from `.xyz`.

4. **`skill_drift_check.py` and red control** `[Blocker]`
   - `utils/py/skill_drift_check.py:52`: The plan proposes updating line 36 (`canonical.glob("*/SKILL.md")` -> globbing `*/SKILL.md` and `*/*/SKILL.md`), but omits line 52: `if not (canonical / name / "SKILL.md").is_file():`. In line 52, `collection` is flat. When checking if a vendored skill exists in canonical, it tests `canonical / name / "SKILL.md"`. When canonical is tiered (`canonical/<tier>/<name>/SKILL.md`), that path never exists, so EVERY vendored skill in `collection` will be falsely reported as `unrecognized` in lines 50-54.
   - `test/gh660-skill-drift.sh:11-14`: The test's fixture uses a strictly one-level canonical tree (`$FIX/canonical/skills/alpha/SKILL.md`). Because the checker preserves `*/SKILL.md` globbing, the test still acts as a red control for the 1-level branch (detects drift on `beta`). However, it does NOT test or prove the two-level branch at all; it cannot catch the line 52 regression.
   - **Fix:** In `skill_drift_check.py:50-54`, check whether `name` exists in the set of canonical skill names discovered in the first loop instead of testing a hardcoded flat path. Update `test/gh660-skill-drift.sh` to include a two-level canonical skill in its fixture (e.g. `$FIX/canonical/skills/1-hourly/alpha/SKILL.md`) to prove the tiered branch.
   - `Observed input:` Tiered canonical tree with `skills/1-hourly/recon/SKILL.md` and collection with `recon/SKILL.md`.
   - `Affected scope:` `utils/py/skill_drift_check.py:50-54` and `test/gh660-skill-drift.sh:11-17`.
   - `Falsifier:` Run `python3 utils/py/skill_drift_check.py --canonical <tiered-dir> --collection <collection-dir> --json`. With only line 36 patched, `recon` appears in `unrecognized`.

5. **`ci-route.sh` globs** `[Pass]`
   - Verified that in bash `case "$path" in ...)` statements, pattern matching uses standard shell pattern matching rules (fnmatch without `FNM_PATHNAME`), where `*` matches any sequence of characters including `/`.
   - `skills/*/hq/*` at `utils/ci-route.sh:37` correctly matches `skills/2-daily/hq/find-hq.sh` as well as any subdirectories (e.g. `skills/2-daily/hq/fixtures/...`).
   - `skills/*/relay-xyz/*` at `utils/ci-route.sh:316` correctly matches `skills/1-hourly/relay-xyz/SKILL.md` and triggers `full_required=true` as verified against `test/ci-route.sh:170`.
   - Quoted check: `p="skills/2-daily/hq/find-hq.sh"; case "$p" in skills/*/hq/*) echo MATCH ;; esac` exits 0 and prints `MATCH`. No pattern in `ci-route.sh` is broken by this behavior.

6. **Tier assignments** `[Nit]`
   - `skills/releases/SKILL.md:3`: Placed in `1-hourly` (`PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md:66`). Its trigger description defines it as a periodic/milestone planning ledger and release management router ("/releases; release status or health checks; stale-plan review... publishing a planned GitHub Release"). Release planning is not an hourly developer activity; placement in `2-daily` or `3-weekly` better aligns with its cadence.
   - `skills/standup/SKILL.md:3`: Placed in `2-daily` (`:67`). Its trigger description defines it as "Session-scoped triage: what did I leave open, what is rotting, and is the plan still right — answered in under a screen." Because it governs work session boundaries, it could be considered `1-hourly`.
   - `skills/whack-a-mole/SKILL.md:3`: Placed in `3-weekly` (`:68`). Its description cites a 14-day scan window, which is bi-weekly/sprint level; placement in `3-weekly` is reasonable given the 4-tier model.
   - **Fix:** (Advisory) Consider swapping `releases` to `2-daily` and `standup` to `1-hourly`.

7. **Rating `55/25/50/45`** `[Pass]`
   - Verified against `releases.db` (`roadmap_items` row for GH-744): `pri=55, sev=25, appeal=50, effort=45`.
   - `sev 25`: Verified at `PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md:210` — no defect or active failure; flat layout causes navigation friction. No open issue in `releases.db` claims a blocker caused by the flat layout.
   - `pri 55`: Verified operator prioritized GH-744 directly.
   - `appeal 50`: Unset by operator; neutral 50 preserved.
   - `effort 45`: Verified mechanical refactor across ~80 files. No axis is contradicted.

8. **Requirements & Governance** `[Pass]`
   - Completeness against Issue #744 Acceptance criteria: all four criteria (60 tiered skills with empty root, validate.sh green in disposable clone, skill_drift_check recognition, relay-xyz find-harness check) are incorporated in plan steps 1, 2, 5, and 9 (`PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md:185-205`).
   - Compliance with `AGENTS.md` and `ROUTER.md`: issue-first followed (GH-744), PDDA capture created in `1-INBOX` with frontmatter, roadmap row parked in `releases.db`, promotion procedure noted for activation (`:33-35`), CHANGELOG entry planned, and validation constrained to a disposable full clone (`:204`).

9. **Rollback** `[Should]`
   - `PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md:171`: A single `git revert <merge_commit>` cleanly reverts all tracked files in git (including `relay-pkg.tar.gz` and `security-scan-baseline.txt`).
   - However, for machine-local state (`:138-142`), if the operator runs `intake.py --apply update <name> --source <forge>/skills/<tier>/<name>` in Skills Army HQ after merge, a subsequent git revert requires a paired external action: re-running `intake.py --apply update <name> --source <forge>/skills/<name>` to restore flat provenance.
   - **Fix:** Explicitly document this paired external rollback command in the Risks / rollback section (`:171`).
   - `Observed input:` Rollback after post-merge Skills Army HQ intake update.
   - `Affected scope:` `PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md:171`.
   - `Falsifier:` Reverting the git merge without reverting Skills Army HQ provenance leaves Skills Army HQ pointing to deleted `<forge>/skills/<tier>/<name>` paths.

VERDICT: FAIL
Basis: The plan correctly captures the overall architecture, tier structure, and the majority of test and locator repoints, but contains concrete execution blockers that would cause runtime failures: (1) skill_drift_check.py:52 checks flat canonical paths in its collection loop, causing every vendored skill to be reported unrecognized; (2) skills/review-xyz/scripts/review_engine.py is omitted and resolves root to skills/; (3) skills/relay-automation/make-pkg.sh:11,30 still targets un-tiered tarball paths; (4) skills/agent-chorus/publish-manifest.tsv is unlisted and breaks sync-to-standalone.sh; (5) skills/file-xyz-bug/find-xyz.sh:70 assumes relay-xyz is a sibling at ../relay-xyz. In addition, agent_chorus.py walk-up mis-resolves in vendored .xyz/ layouts, test/gh660-skill-drift.sh lacks a two-level fixture, and repro.sh:165,167,276 is unlisted.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
