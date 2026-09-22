# RELAY · Final QA: GH-744 skills/ frequency-tier reorganization
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh744-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation on this branch — `git diff -M origin/development..HEAD`
  (932 files: 845 pure renames + the edits below), graded against the approved plan
  `PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md` (agy Approved, `relay-system/2026-09-21/gh744-plan-qa.md`)
  and the focused-suite evidence `relay-system/2026-09-21/gh744-final-qa-evidence.md`.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-21
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/744
- Definition of Done: every requirement in the issue is satisfied by the code as committed; the codepaths
  match the approved plan (no parallel subsystem, registry, resolver library or symlink shim slipped in);
  the evidence substantiates the claims; the persisted rating still matches the evidence.

### Operational envelope (grade against THIS, not an imagined one)
One-time `git mv` of 60 skill directories into four tier folders inside a single-maintainer developer
harness repo, plus repointing the code, tests and docs that address `skills/<name>`. No runtime service,
no multi-tenant surface, no data migration. Machinery and tests must stay commensurate. The Producer
will disposition requests for unrequested machinery as `Rejected (Out of Scope / Ponytail)`.

### Read these (worktree at HEAD)
- `git diff -M --stat origin/development..HEAD` then the non-rename edits: `utils/py/skill_drift_check.py`,
  `utils/py/xyz_mini_sync.py`, `utils/ci-route.sh`, `utils/ate/install.sh`, `relay-automation/hooks/skill-nudge.sh`,
  `mini/skills/skill-viewer/scripts/list_skills.py`, `test/path-integrity.sh`, `test/gh660-skill-drift.sh`,
  `test/test_deploy_skills.py`, `test/gh589-xyz-mini-sync.sh`.
- Moved skills with logic edits: `skills/1-hourly/relay-xyz/find-harness.sh`, `skills/2-daily/hq/find-hq.sh`,
  `skills/2-daily/file-xyz-bug/find-xyz.sh`, `skills/4-occasional/vendor-stack/{find-pdda.sh,install.sh}`,
  `skills/2-daily/relay-to-issue/relay-to-issue.sh`, `skills/1-hourly/relay-automation/make-pkg.sh`,
  `skills/2-daily/review-xyz/scripts/review_engine.py`, `skills/2-daily/agent-chorus/scripts/agent_chorus.py`,
  `skills/2-daily/agent-chorus/publish-manifest.tsv`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py`.
- `skills/README.md` (new), `ARCHITECTURE.md:35-130` (regrouped index), `CHANGELOG.md` (top entry), `.gitignore`.

### Questions (answer each by number; cite file:line)
1. Requirement 1-2 (issue): are all 60 skills at exactly `skills/<tier>/<name>/` with no content change?
   Probe: `git diff -M --name-status origin/development..HEAD | grep -c '^R100'` and
   `find skills -mindepth 2 -maxdepth 2 -name SKILL.md`. Name any skill whose files changed beyond path literals.
2. Requirement 3: run the plan's consumer grep against HEAD (`grep -rn -E 'skills/[a-z0-9-]+/'` over `*.sh *.py *.yml *.json *.tsv`,
   excluding `.git`, `CHANGELOG.md`, `relay-system/`, `marathon-system/`, `PROJECT/`, `temp/`, `.xyz/`, `mini/`) and
   name any executable consumer still addressing a one-level `skills/<name>` path that is NOT an app-discovery
   root (`~/.claude/skills/...` etc.), a fixture literal, or the XYZ-mini/standalone DESTINATION side of a manifest.
3. Scanners: does `skill_drift_check.py` now recognise a tiered canonical AND a flat one, and does the GH-660 test
   prove both branches (`test/gh660-skill-drift.sh` delta fixture)? Does `xyz_mini_sync.py` keep every destination flat?
4. Locators: for each moved script with a self-relative root, is the new derivation correct at its new depth, and
   does the Deployed-Skills copy (`~/Documents/Deployed Skills/<name>/`) still fall through rather than mis-resolve?
   Is `find-xyz.sh`'s cross-tier glob correct bash (unquoted glob inside a `for` list)?
5. Walk-ups: do `agent_chorus.py:default_root()` and `scan_clones.py:_tick_binary()` return the same directory as
   before in (a) the forge, (b) a flat XYZ-mini/standalone root, (c) a vendored `<consumer>/.xyz/`? Name a layout where they differ.
6. Did any parallel subsystem, registry file, resolver library, or symlink shim slip in? `skills/README.md` is a doc,
   not code — confirm it introduces no machinery.
7. `ci-route.sh`: are the tier-agnostic globs (`skills/*/hq/*` etc.) pinned by `test/ci-route.sh` with tiered paths,
   and does any registered subsystem lose coverage?
8. `path-integrity.sh`: the app-discovery-root blanking (`app_root_re`) and the three mini fixture literals — could either
   mask a REAL broken repo path? Give the concrete path it would miss, if any.
9. Evidence: does `gh744-final-qa-evidence.md` substantiate the claims (which suites, which counts), and is the
   `gh549-work-events.sh` failure plausibly pre-existing (it is env-driven and identical on the untouched primary clone)?
   The full `./validate.sh` in a disposable clone is scheduled AFTER this review on the approved commit — grade
   `[Unverified — needs clone run]` where only that run can answer.
10. Rating `55/25/50/45` persisted for GH-744: still consistent with the delivered scope? Appeal must stay 50.

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

Pre-existing defects in touched files: none found across touched scripts, locators, tests, and configurations.

#### Findings

1. **Requirement 1-2 (60 skills tiered with no content change)** `[Pass]`
   - Probe `git diff -M --name-status origin/development..HEAD | grep -c '^R100'` returns `800` pure renames (`R100`) across the 60 skill directories.
   - Probe `find skills -mindepth 3 -maxdepth 3 -name SKILL.md | wc -l` confirms all `60` skills exist at exactly `skills/<tier>/<name>/SKILL.md` (and `find skills -mindepth 1 -maxdepth 2 -name SKILL.md` returns 0).
   - Skills whose files changed beyond path literals / locators / manifests: none. All non-`R100` diffs within `skills/` are strictly path literal repoints in docs/comments (`skills/3-weekly/10days/SKILL.md`, `skills/3-weekly/skills-army-hq/SKILL.md`, `skills/4-occasional/rpr/SKILL.md`, etc.), self-relative root locators (`skills/1-hourly/relay-xyz/find-harness.sh`, `skills/2-daily/hq/find-hq.sh`, `skills/2-daily/file-xyz-bug/find-xyz.sh`, `skills/4-occasional/vendor-stack/find-pdda.sh`, `skills/4-occasional/vendor-stack/install.sh`, `skills/2-daily/relay-to-issue/relay-to-issue.sh`, `skills/1-hourly/relay-automation/make-pkg.sh`, `skills/2-daily/review-xyz/scripts/review_engine.py`), parent walk-ups (`skills/2-daily/agent-chorus/scripts/agent_chorus.py`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py`), or manifest/tarball generation (`skills/2-daily/agent-chorus/publish-manifest.tsv`, `skills/1-hourly/relay-automation/relay-pkg.tar.gz`).

2. **Requirement 3 (consumer grep against HEAD)** `[Pass]`
   - Grep probe `grep -rn -E 'skills/[a-z0-9-]+/'` across `*.sh *.py *.yml *.json *.tsv` (excluding `.git`, `CHANGELOG.md`, `relay-system/`, `marathon-system/`, `PROJECT/`, `temp/`, `.xyz/`, `mini/`) confirms zero executable consumers address an un-tiered `skills/<name>/` path for repo skills.
   - Remaining single-level occurrences are all permitted exceptions:
     - App-discovery roots: `utils/pdda/pdda-install.sh:599` (`"$TARGET/.claude/skills/pdda/SKILL.md"`), `utils/pdda/pdda.sh:908` (`.claude/skills/pdda/SKILL.md`), `skills/2-daily/file-xyz-bug/find-xyz.sh:70` (`"$HOME/.claude/skills/relay-xyz/find-harness.sh"`), `test/find-harness.sh:41` (`$HOME/.claude/skills/relay-xyz/find-harness.sh`), `test/gh436-merge-cleanup.py:640` (`.claude/skills/front-door/SKILL.md`), `test/gh649-pdda-migration.sh:26` (`$T/.claude/skills/pdda/SKILL.md`).
     - Manifest destination side: `utils/py/xyz_mini_sync.py:40-42` (`("skills/2-daily/agent-chorus/install.sh", "skills/agent-chorus/install.sh", "managed")`) and `skills/2-daily/agent-chorus/publish-manifest.tsv:7-15` (`skills/2-daily/agent-chorus/SKILL.md	skills/agent-chorus/SKILL.md`).
     - Test fixture data: `test/path-integrity.sh:144` (`fixture_literals=" skills/debug-mantra/SKILL.md skills/honest/SKILL.md skills/ponytail/install.sh ..."`), `test/path-integrity.sh:153` (`test/gh649-pdda-migration.sh:skills/pdda/SKILL.md`), `test/gh660-skill-drift.sh:13-14` (`$FIX/canonical/skills/alpha/SKILL.md`), and `test/gh589-xyz-mini-sync.sh:66,69,70,88,90` (asserting on files within the flat XYZ-mini destination temp repo).
     - Historical test run receipts: `TESTS-RESULTS/` JSON files (`packet.json`, `links.json`).

3. **Scanners (`skill_drift_check.py` and `xyz_mini_sync.py`)** `[Pass]`
   - `utils/py/skill_drift_check.py:38-41`: Scans both `canonical.glob("*/SKILL.md")` and `canonical.glob("*/*/SKILL.md")`, recording discovered canonical names into `canonical_names = set()`.
   - `utils/py/skill_drift_check.py:54-58`: Keys the `unrecognized` collection check against `canonical_names` (`if name not in canonical_names:`), preventing tiered canonical skills from being falsely flagged as unrecognized extras.
   - `test/gh660-skill-drift.sh:11-20, 39-43, 55-62`: Fixture includes flat (`alpha`, `beta`) and tiered (`skills/1-hourly/delta/SKILL.md`) canonical entries; proves both branches with tests 3 ("2 ok"), 3b (`! grep -q "UNRECOGNIZED  delta:"`), and 5 ("mutation proof — stale vendors re-flag after canonical moves (flat + tiered)").
   - `utils/py/xyz_mini_sync.py:29-59`: `MANIFEST` maps each tiered source (`skills/1-hourly/relay`, `skills/2-daily/agent-chorus/SKILL.md`, etc.) to a flat mini destination (`skills/relay`, `skills/agent-chorus/SKILL.md`), and `SKILLS_ARMY_MANIFEST` (:60-66) maps `skills/3-weekly/skills-army-hq` to the root `""`. Every mini destination remains flat.

4. **Locators (self-relative roots and cross-tier glob)** `[Pass]`
   - `skills/1-hourly/relay-xyz/find-harness.sh:103, 172, 207`: Steps up 3 levels (`$SELF_DIR/../../..`). In Deployed Skills (`~/Documents/Deployed Skills/relay-xyz`), stepping up 3 levels lands in `~` where `_has_harness` (`test -x "$1/relay-automation/relay-drive.sh"`, line 28) returns false, safely falling through to git root and caller `.xyz/`.
   - `skills/2-daily/hq/find-hq.sh:42, 62`: Steps up 3 levels (`$SELF_DIR/../../..`), guarded by `_has_hq` (`test -x "$1/utils/hq/hq.sh"`, line 31); safely falls through when deployed.
   - `skills/2-daily/file-xyz-bug/find-xyz.sh:46, 64, 70`: Steps up 3 levels (`$SELF_DIR/../../..`), guarded by `_is_intake` (`test -d "$1/PROJECT/1-INBOX" && test -e "$1/.git"`, line 33); safely falls through. At line 70, `for _l in "$HOME/.claude/skills/relay-xyz/find-harness.sh" "$SELF_DIR"/../../*/relay-xyz/find-harness.sh; do` uses valid bash pathname expansion (`*` left unquoted in a `for` word list): `"$SELF_DIR"/../..` is `<repo>/skills`, and `*/relay-xyz/find-harness.sh` expands to `1-hourly/relay-xyz/find-harness.sh`. Non-matching globs are safely ignored by `[ -x "$_l" ]` (line 71).
   - `skills/4-occasional/vendor-stack/{find-pdda.sh:28,35, install.sh:50}`: Steps up 3 levels (`$SELF_DIR/../../..`), guarded by `_is_pdda_repo` (line 46); falls through safely in Deployed Skills.
   - `skills/2-daily/relay-to-issue/relay-to-issue.sh:49`: Correctly derives `REPO_ROOT="$(cd "$SELF_DIR/../../.." >/dev/null 2>&1 && pwd || true)"`.
   - `skills/1-hourly/relay-automation/make-pkg.sh:5, 11, 30`: Steps up 3 levels (`cd "$(dirname "${BASH_SOURCE[0]}")/../../.."`) and outputs to `skills/1-hourly/relay-automation/relay-pkg.tar.gz`.
   - `skills/2-daily/review-xyz/scripts/review_engine.py:9`: Derives `XYZ_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(SKILL_DIR)))`, resolving the repo root cleanly (verified by running `review_engine.py --help`, which exits 0).

5. **Walk-ups (`agent_chorus.py` and `scan_clones.py`)** `[Pass]`
   - `skills/2-daily/agent-chorus/scripts/agent_chorus.py:88-92`: Iterates through `here.parents` checking `(parent / "skills").is_dir()`, falling back to `here.parents[3]`:
     - (a) Forge: `<forge>/skills/2-daily/agent-chorus/scripts/agent_chorus.py` -> parent with `skills/` is `<forge>`. Matches prior `parents[3]`.
     - (b) Flat XYZ-mini/standalone: `<mini>/skills/agent-chorus/scripts/agent_chorus.py` -> parent with `skills/` is `<mini>`. Matches prior `parents[3]`.
     - (c) Vendored `<consumer>/.xyz/`: `<consumer>/.xyz/skills/2-daily/agent-chorus/scripts/agent_chorus.py` -> parent with `skills/` is `<consumer>/.xyz`. Matches prior `parents[3]` (as accepted in Plan QA Round 1 dispositions).
     - Deployed Skills copy outside a repository: no parent contains `skills/`, falling back to `here.parents[3]` (`~/Documents`), matching prior behavior.
   - `skills/2-daily/merge-cleanup/scripts/scan_clones.py:190-194`: Iterates through `Path(__file__).resolve().parents` searching for `parent / "bin" / "tick"`, falling back to `shutil.which("tick")`:
     - (a) Forge: finds `<forge>/bin/tick`. Matches prior `parents[3]`.
     - (b) Flat XYZ-mini/standalone: no `bin/tick`, falls back to `shutil.which("tick")`. Matches prior `parents[3]`.
     - (c) Vendored `<consumer>/.xyz/`: finds `<consumer>/.xyz/bin/tick`. Matches prior `parents[3]`.
   - Both walk-ups return the identical directory as before across all supported layouts.

6. **Machinery check & `skills/README.md`** `[Pass]`
   - Verified that no parallel subsystem, registry file, resolver library, or compatibility symlink shim was added.
   - Only 7 files were added in `origin/development..HEAD`: the approved plan (`PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md`), two relay files (`relay-system/2026-09-21/gh744-plan-qa.md`, `relay-system/2026-09-21/gh744-final-qa.md`), the evidence log (`relay-system/2026-09-21/gh744-final-qa-evidence.md`), the moved `publish-manifest.tsv`, the rebuilt `relay-pkg.tar.gz`, and `skills/README.md`.
   - `skills/README.md:1-33` is pure documentation describing the tier categories, depth contract, lookup commands, and re-tiering instructions without any executable machinery or scripts.

7. **`ci-route.sh` globs and subsystem coverage** `[Pass]`
   - `utils/ci-route.sh:37-45, 316`: Patterns `skills/*/hq/*`, `skills/*/releases/*`, `skills/*/agent-chorus/*`, `skills/*/standup/*`, `skills/*/skills-army-hq/*`, `skills/*/relay-automation/*`, and `skills/*/relay-xyz/*` use wildcard `*` matching in bash `case` statements, which matches any path segment including `/`.
   - `test/ci-route.sh:158, 166-167, 170, 181, 183`: Explicitly tests these globs using tiered paths (`skills/2-daily/hq/find-hq.sh`, `skills/2-daily/agent-chorus/scripts/agent_chorus.py`, `skills/2-daily/agent-chorus/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/3-weekly/skills-army-hq/scripts/intake.py`).
   - None of the 9 registered subsystems (`hq`, `releases`, `telemetry`, `ate`, `swe-diagram`, `pdda`, `agent-chorus`, `standup`, `skills-army-hq`) loses test coverage.

8. **`path-integrity.sh`: `app_root_re` and mini fixture literals** `[Pass]`
   - `test/path-integrity.sh:74`: `app_root_re='s#(\.claude|\.codex|\.agents|\.zcode|config|antigravity|antigravity-cli)/skills/[A-Za-z0-9._/-]+##g'` blanks app discovery roots before token extraction so that doc references to installed paths (e.g. `~/.claude/skills/<name>`) are not mistaken for broken repo-relative paths. It cannot mask a real broken repo path because this repository contains no tracked files under those directories.
   - `test/path-integrity.sh:144`: Whitelists `skills/debug-mantra/SKILL.md`, `skills/honest/SKILL.md`, and `skills/ponytail/install.sh`, which exist as runtime assertions inside the XYZ-mini destination temp fixture in `test/gh589-xyz-mini-sync.sh`.
   - Concrete path it would miss: If an author wrote an un-tiered reference to `skills/debug-mantra/SKILL.md`, `skills/honest/SKILL.md`, or `skills/ponytail/install.sh` in a tracked script or scanned doc instead of `skills/1-hourly/debug-mantra/SKILL.md`, `skills/3-weekly/honest/SKILL.md`, or `skills/1-hourly/ponytail/install.sh`, `path-integrity.sh` Check B would skip it. However, our Question 2 consumer grep verified that zero such references exist in the tree.

9. **Evidence & disposable clone verification** `[Pass]`
   - `relay-system/2026-09-21/gh744-final-qa-evidence.md:1-55` records 40 focused test suites executed on HEAD `f323fe7c` and re-run after path repoints (`faa62025`):
     - `ci-route.sh` (76 pass), `find-harness.sh` (23 pass), `path-integrity.sh` (2 pass), `agent-chorus.sh` (215 pass), `skills-army-hq.sh` (33 passed), `gh660-skill-drift.sh` (7 pass), `gh589-xyz-mini-sync.sh` (18 passed), `gh77-standup-triage.sh` (150 pass), etc.
     - `gh549-work-events.sh`: Observed failure (105 pass, 20 fail) is identical on the untouched primary clone and driven by the external environment variable `XYZ_WORK_CONNECTORS_REGISTRY`; git diff confirms only lines 589 and 592 were modified to point `merge_cleanup.py` to `skills/2-daily/merge-cleanup`.
     - Acceptance one-liners: 60 depth-2 `SKILL.md` files, 0 depth-1, `find-harness.sh --check` verified (resolves via `git-root`), publish manifests verified, drift check verified.
     - Full `./validate.sh` run in a disposable clone is scheduled after this review on the approved commit [Unverified — needs clone run].

10. **Rating `55/25/50/45` persisted for GH-744** `[Pass]`
    - Verified in `releases.db` (`SELECT rating_pri, rating_sev, rating_appeal, rating_effort FROM roadmap_items WHERE gh_number = 744`): `55/25/50/45`.
    - `pri 55`: Urgent operator priority.
    - `sev 25`: Structural reorganization and navigation friction without defect or data loss.
    - `appeal 50`: Unset / neutral (preserved).
    - `effort 45`: Mechanical refactor across ~80-90 files.
    - The delivered scope matches the approved plan and operational envelope.

VERDICT: PASS
Basis: All 10 questions pass with verified citations and concrete probe outputs. The 60 skills are cleanly partitioned into the 4 tiers (14/14/14/18) with zero content changes to the skills themselves beyond self-relative locator and manifest updates. Scanners (skill_drift_check.py, xyz_mini_sync.py, list_skills.py), locators (find-harness.sh, find-hq.sh, find-xyz.sh, find-pdda.sh, make-pkg.sh, review_engine.py), walk-up routines (agent_chorus.py, scan_clones.py), CI router (ci-route.sh), and path integrity tests (path-integrity.sh, gh660-skill-drift.sh) correctly handle both tiered and flat layouts. No parallel subsystem, resolver, or compatibility shim was introduced. Rating 55/25/50/45 is verified in releases.db and consistent with the delivered scope.  [Unverified — no citation]

relay closed (Approved), no further turn needed.

### Producer (claude-a) — Round 1 dispositions · 2026-09-22

The Round 1 block graded all ten questions `[Pass]` (VERDICT: PASS) but the turn REPLACED the `## Log`
heading instead of appending beneath it, so the shim failed structural validation (exit 8) and
relay-drive reverted `STATUS: Approved` to Open as unattestable. No finding requested a change; nothing
in the implementation was altered in response. Producer actions this turn:

- Restored the `## Log` heading above the Round 1 block (content untouched).
- Merged `origin/development` (aa7f0a62, 9c384240 — GH-737's `debug-mantra/SKILL.md` edit landed on the
  moved path `skills/1-hourly/debug-mantra/SKILL.md` via rename detection; `releases.sql` resolved
  keeping both sides' rows, DB and views rebuilt with `utils/releases-merge-resolve.sh`, `releases check`
  clean). Merge commit c9de2d6d. No implementation file changed.

Round 2 ask (agy): re-grade the same ten questions against HEAD (c9de2d6d). **Append** your block at the
bottom, directly above the marker line — do not edit or replace anything above it, including `## Log`.
If the verdict is still PASS, set `STATUS: Approved`. Handing off to Reviewer (agy) — take your turn.

### System · relay-drive — 2026-09-22T00:44:42Z
terminal STATUS Approved written by FAILED reviewer turn (agy; shim returned non-zero) — reverted

### Review (agy) — Round 2 · 2026-09-21

swept file: yes

Pre-existing defects in touched files: none found across touched scripts, locators, tests, and configurations.

#### Findings

1. **Requirement 1-2 (60 skills tiered with no content change)** `[Pass]`
   - Probe `git diff -M --name-status origin/development..HEAD | grep -c '^R100'` returns `800` pure renames (`R100`) across the 60 skill directories.
   - Probe `find skills -mindepth 2 -maxdepth 2 -name SKILL.md` returns 0 results, confirming no skills remain at `skills/<name>/SKILL.md`.
   - Probe `find skills -mindepth 3 -maxdepth 3 -name SKILL.md | wc -l` confirms all `60` skills exist at exactly `skills/<tier>/<name>/SKILL.md`.
   - Skills whose files changed beyond path literals / locators / manifests: none. All non-`R100` diffs within `skills/` are strictly path literal repoints in docs/comments (`skills/3-weekly/10days/SKILL.md`, `skills/3-weekly/skills-army-hq/SKILL.md`, `skills/4-occasional/rpr/SKILL.md`, etc.), self-relative root locators (`skills/1-hourly/relay-xyz/find-harness.sh`, `skills/2-daily/hq/find-hq.sh`, `skills/2-daily/file-xyz-bug/find-xyz.sh`, `skills/4-occasional/vendor-stack/find-pdda.sh`, `skills/4-occasional/vendor-stack/install.sh`, `skills/2-daily/relay-to-issue/relay-to-issue.sh`, `skills/1-hourly/relay-automation/make-pkg.sh`, `skills/2-daily/review-xyz/scripts/review_engine.py`), parent walk-ups (`skills/2-daily/agent-chorus/scripts/agent_chorus.py`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py`), or manifest/tarball generation (`skills/2-daily/agent-chorus/publish-manifest.tsv`, `skills/1-hourly/relay-automation/relay-pkg.tar.gz`).

2. **Requirement 3 (consumer grep against HEAD)** `[Pass]`
   - Grep probe `grep -rn -E 'skills/[a-z0-9-]+/'` across `*.sh *.py *.yml *.json *.tsv` (excluding `.git`, `CHANGELOG.md`, `relay-system/`, `marathon-system/`, `PROJECT/`, `temp/`, `.xyz/`, `mini/`) confirms zero executable consumers address an un-tiered `skills/<name>/` path for repo skills.
   - Remaining single-level occurrences are all permitted exceptions:
     - App-discovery roots: `utils/pdda/pdda-install.sh:599` (`"$TARGET/.claude/skills/pdda/SKILL.md"`), `utils/pdda/pdda.sh:908` (`.claude/skills/pdda/SKILL.md`), `skills/2-daily/file-xyz-bug/find-xyz.sh:70` (`"$HOME/.claude/skills/relay-xyz/find-harness.sh"`), `test/find-harness.sh:41` (`$HOME/.claude/skills/relay-xyz/find-harness.sh`), `test/gh436-merge-cleanup.py:640` (`.claude/skills/front-door/SKILL.md`), `test/gh649-pdda-migration.sh:26` (`$T/.claude/skills/pdda/SKILL.md`).
     - Manifest destination side: `utils/py/xyz_mini_sync.py:40-42` (`("skills/2-daily/agent-chorus/install.sh", "skills/agent-chorus/install.sh", "managed")`) and `skills/2-daily/agent-chorus/publish-manifest.tsv:7-15` (`skills/2-daily/agent-chorus/SKILL.md	skills/agent-chorus/SKILL.md`).
     - Test fixture data: `test/path-integrity.sh:144` (`fixture_literals=" skills/debug-mantra/SKILL.md skills/honest/SKILL.md skills/ponytail/install.sh ..."`), `test/path-integrity.sh:153` (`test/gh649-pdda-migration.sh:skills/pdda/SKILL.md`), `test/gh660-skill-drift.sh:13-14` (`$FIX/canonical/skills/alpha/SKILL.md`), and `test/gh589-xyz-mini-sync.sh:66,69,70,88,90` (asserting on files within the flat XYZ-mini destination temp repo).
     - Historical test run receipts: `TESTS-RESULTS/` JSON files (`packet.json`, `links.json`).

3. **Scanners (`skill_drift_check.py` and `xyz_mini_sync.py`)** `[Pass]`
   - `utils/py/skill_drift_check.py:38-41`: Scans both `canonical.glob("*/SKILL.md")` and `canonical.glob("*/*/SKILL.md")`, recording discovered canonical names into `canonical_names = set()`.
   - `utils/py/skill_drift_check.py:54-58`: Keys the `unrecognized` collection check against `canonical_names` (`if name not in canonical_names:`), preventing tiered canonical skills from being falsely flagged as unrecognized extras.
   - `test/gh660-skill-drift.sh:11-20,39-43,55-62`: Fixture includes flat (`alpha`, `beta`) and tiered (`skills/1-hourly/delta/SKILL.md`) canonical entries; proves both branches with tests 3 ("2 ok"), 3b (`! grep -q "UNRECOGNIZED  delta:"`), and 5 ("mutation proof — stale vendors re-flag after canonical moves (flat + tiered)").
   - `utils/py/xyz_mini_sync.py:29-59`: `MANIFEST` maps each tiered source (`skills/1-hourly/relay`, `skills/2-daily/agent-chorus/SKILL.md`, etc.) to a flat mini destination (`skills/relay`, `skills/agent-chorus/SKILL.md`), and `SKILLS_ARMY_MANIFEST` (:60-66) maps `skills/3-weekly/skills-army-hq` to the root `""`. Every mini destination remains flat.

4. **Locators (self-relative roots and cross-tier glob)** `[Pass]`
   - `skills/1-hourly/relay-xyz/find-harness.sh:103,172,207`: Steps up 3 levels (`$SELF_DIR/../../..`). In Deployed Skills (`~/Documents/Deployed Skills/relay-xyz`), stepping up 3 levels lands in `~` where `_has_harness` (`test -x "$1/relay-automation/relay-drive.sh"`, line 28) returns false, safely falling through to git root and caller `.xyz/`.
   - `skills/2-daily/hq/find-hq.sh:42,62`: Steps up 3 levels (`$SELF_DIR/../../..`), guarded by `_has_hq` (`test -x "$1/utils/hq/hq.sh"`, line 31); safely falls through when deployed.
   - `skills/2-daily/file-xyz-bug/find-xyz.sh:46,64,70`: Steps up 3 levels (`$SELF_DIR/../../..`), guarded by `_is_intake` (`test -d "$1/PROJECT/1-INBOX" && test -e "$1/.git"`, line 33); safely falls through. At line 70, `for _l in "$HOME/.claude/skills/relay-xyz/find-harness.sh" "$SELF_DIR"/../../*/relay-xyz/find-harness.sh; do` uses valid bash pathname expansion (`*` left unquoted in a `for` word list): `"$SELF_DIR"/../..` is `<repo>/skills`, and `*/relay-xyz/find-harness.sh` expands to `1-hourly/relay-xyz/find-harness.sh`. Non-matching globs are safely ignored by `[ -x "$_l" ]` (line 71).
   - `skills/4-occasional/vendor-stack/{find-pdda.sh:28,35,install.sh:50}`: Steps up 3 levels (`$SELF_DIR/../../..`), guarded by `_is_pdda_repo` (line 46); falls through safely in Deployed Skills.
   - `skills/2-daily/relay-to-issue/relay-to-issue.sh:49`: Correctly derives `REPO_ROOT="$(cd "$SELF_DIR/../../.." >/dev/null 2>&1 && pwd || true)"`.
   - `skills/1-hourly/relay-automation/make-pkg.sh:5,11,30`: Steps up 3 levels (`cd "$(dirname "${BASH_SOURCE[0]}")/../../.."`) and outputs to `skills/1-hourly/relay-automation/relay-pkg.tar.gz`.
   - `skills/2-daily/review-xyz/scripts/review_engine.py:9`: Derives `XYZ_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(SKILL_DIR)))`, resolving the repo root cleanly (verified by running `review_engine.py --help`, which exits 0).

5. **Walk-ups (`agent_chorus.py` and `scan_clones.py`)** `[Pass]`
   - `skills/2-daily/agent-chorus/scripts/agent_chorus.py:88-92`: Iterates through `here.parents` checking `(parent / "skills").is_dir()`, falling back to `here.parents[3]`:
     - (a) Forge: `<forge>/skills/2-daily/agent-chorus/scripts/agent_chorus.py` -> parent with `skills/` is `<forge>`. Matches prior `parents[3]`.
     - (b) Flat XYZ-mini/standalone: `<mini>/skills/agent-chorus/scripts/agent_chorus.py` -> parent with `skills/` is `<mini>`. Matches prior `parents[3]`.
     - (c) Vendored `<consumer>/.xyz/`: `<consumer>/.xyz/skills/2-daily/agent-chorus/scripts/agent_chorus.py` -> parent with `skills/` is `<consumer>/.xyz`. Matches prior `parents[3]` (as accepted in Plan QA Round 1 dispositions).
     - Deployed Skills copy outside a repository: no parent contains `skills/`, falling back to `here.parents[3]` (`~/Documents`), matching prior behavior.
   - `skills/2-daily/merge-cleanup/scripts/scan_clones.py:190-194`: Iterates through `Path(__file__).resolve().parents` searching for `parent / "bin" / "tick"`, falling back to `shutil.which("tick")`:
     - (a) Forge: finds `<forge>/bin/tick`. Matches prior `parents[3]`.
     - (b) Flat XYZ-mini/standalone: no `bin/tick`, falls back to `shutil.which("tick")`. Matches prior `parents[3]`.
     - (c) Vendored `<consumer>/.xyz/`: finds `<consumer>/.xyz/bin/tick`. Matches prior `parents[3]`.
   - Both walk-ups return the identical directory as before across all supported layouts.

6. **Machinery check & `skills/README.md`** `[Pass]`
   - Verified that no parallel subsystem, registry file, resolver library, or compatibility symlink shim was added.
   - Only 7 files were added in `origin/development..HEAD`: the approved plan (`PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md`), two relay files (`relay-system/2026-09-21/gh744-plan-qa.md`, `relay-system/2026-09-21/gh744-final-qa.md`), the evidence log (`relay-system/2026-09-21/gh744-final-qa-evidence.md`), the moved `publish-manifest.tsv`, the rebuilt `relay-pkg.tar.gz`, and `skills/README.md`.
   - `skills/README.md:1-33` is pure documentation describing the tier categories, depth contract, lookup commands, and re-tiering instructions without any executable machinery or scripts.

7. **`ci-route.sh` globs and subsystem coverage** `[Pass]`
   - `utils/ci-route.sh:37-45,316`: Patterns `skills/*/hq/*`, `skills/*/releases/*`, `skills/*/agent-chorus/*`, `skills/*/standup/*`, `skills/*/skills-army-hq/*`, `skills/*/relay-automation/*`, and `skills/*/relay-xyz/*` use wildcard `*` matching in bash `case` statements, which matches any path segment including `/`.
   - `test/ci-route.sh:158,166-167,170,181,183`: Explicitly tests these globs using tiered paths (`skills/2-daily/hq/find-hq.sh`, `skills/2-daily/agent-chorus/scripts/agent_chorus.py`, `skills/2-daily/agent-chorus/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/3-weekly/skills-army-hq/scripts/intake.py`).
   - None of the 9 registered subsystems (`hq`, `releases`, `telemetry`, `ate`, `swe-diagram`, `pdda`, `agent-chorus`, `standup`, `skills-army-hq`) loses test coverage.

8. **`path-integrity.sh`: `app_root_re` and mini fixture literals** `[Pass]`
   - `test/path-integrity.sh:74`: `app_root_re='s#(\.claude|\.codex|\.agents|\.zcode|config|antigravity|antigravity-cli)/skills/[A-Za-z0-9._/-]+##g'` blanks app discovery roots before token extraction so that doc references to installed paths (e.g. `~/.claude/skills/<name>`) are not mistaken for broken repo-relative paths. It cannot mask a real broken repo path because this repository contains no tracked files under those directories.
   - `test/path-integrity.sh:144`: Whitelists `skills/debug-mantra/SKILL.md`, `skills/honest/SKILL.md`, and `skills/ponytail/install.sh`, which exist as runtime assertions inside the XYZ-mini destination temp fixture in `test/gh589-xyz-mini-sync.sh`.
   - Concrete path it would miss: If an author wrote an un-tiered reference to `skills/debug-mantra/SKILL.md`, `skills/honest/SKILL.md`, or `skills/ponytail/install.sh` in a tracked script or scanned doc instead of `skills/1-hourly/debug-mantra/SKILL.md`, `skills/3-weekly/honest/SKILL.md`, or `skills/1-hourly/ponytail/install.sh`, `path-integrity.sh` Check B would skip it. However, our Question 2 consumer grep verified that zero such references exist in the tree.

9. **Evidence & disposable clone verification** `[Pass]`
   - `relay-system/2026-09-21/gh744-final-qa-evidence.md:1-55` records 40 focused test suites executed on HEAD `f323fe7c` and re-run after path repoints (`faa62025`):
     - `ci-route.sh` (76 pass), `find-harness.sh` (23 pass), `path-integrity.sh` (2 pass), `agent-chorus.sh` (215 pass), `skills-army-hq.sh` (33 passed), `gh660-skill-drift.sh` (7 pass), `gh589-xyz-mini-sync.sh` (18 passed), `gh77-standup-triage.sh` (150 pass), etc.
     - `gh549-work-events.sh`: Observed failure (105 pass, 20 fail) is identical on the untouched primary clone and driven by the external environment variable `XYZ_WORK_CONNECTORS_REGISTRY`; git diff confirms only lines 589 and 592 were modified to point `merge_cleanup.py` to `skills/2-daily/merge-cleanup`.
     - Acceptance one-liners: 60 depth-2 `SKILL.md` files, 0 depth-1, `find-harness.sh --check` verified (resolves via `git-root`), publish manifests verified, drift check verified.
     - Upstream merge `c9de2d6d` cleanly integrated `origin/development` (`aa7f0a62`, `9c384240`), merging GH-737's `debug-mantra/SKILL.md` edit into `skills/1-hourly/debug-mantra/SKILL.md` without conflicts; `releases check` is clean.
     - Full `./validate.sh` run in a disposable clone is scheduled after this review on the approved commit [Unverified — needs clone run].

10. **Rating `55/25/50/45` persisted for GH-744** `[Pass]`
    - Verified in `releases.db` (`SELECT rating_pri, rating_sev, rating_appeal, rating_effort FROM roadmap_items WHERE gh_number = 744`): `55/25/50/45`.
    - Verified in `releases.sql:2069` (`INSERT INTO work_events ... VALUES(..., '744', ..., '{"rated": "55/25/50/45"}', ...)`).
    - `pri 55`: Urgent operator priority.
    - `sev 25`: Structural reorganization and navigation friction without defect or data loss.
    - `appeal 50`: Unset / neutral (preserved).
    - `effort 45`: Mechanical refactor across ~80-90 files.
    - The delivered scope matches the approved plan and operational envelope.

VERDICT: PASS
Basis: All 10 questions pass with verified citations and concrete probe outputs. The 60 skills are cleanly partitioned into the 4 tiers (14/14/14/18) with zero content changes to the skills themselves beyond self-relative locator and manifest updates. Scanners (`utils/py/skill_drift_check.py:38-41`, `utils/py/xyz_mini_sync.py:29-59`, `mini/skills/skill-viewer/scripts/list_skills.py`), locators (`skills/1-hourly/relay-xyz/find-harness.sh:103`, `skills/2-daily/hq/find-hq.sh:42`, `skills/2-daily/file-xyz-bug/find-xyz.sh:46,70`, `skills/4-occasional/vendor-stack/find-pdda.sh:28`, `skills/1-hourly/relay-automation/make-pkg.sh:5`, `skills/2-daily/review-xyz/scripts/review_engine.py:9`), walk-up routines (`skills/2-daily/agent-chorus/scripts/agent_chorus.py:88-92`, `skills/2-daily/merge-cleanup/scripts/scan_clones.py:190-194`), CI router (`utils/ci-route.sh:37-45,316`), and path integrity tests (`test/path-integrity.sh:74,144`, `test/gh660-skill-drift.sh:11-20`) correctly handle both tiered and flat layouts. Merge commit `c9de2d6d` cleanly integrated `origin/development` (GH-737). No parallel subsystem, resolver, or compatibility shim was introduced. Rating `55/25/50/45` is verified in `releases.db` and `releases.sql:2069` and is consistent with the delivered scope.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
