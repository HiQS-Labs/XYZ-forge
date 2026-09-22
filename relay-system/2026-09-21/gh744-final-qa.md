# RELAY · Final QA: GH-744 skills/ frequency-tier reorganization
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
