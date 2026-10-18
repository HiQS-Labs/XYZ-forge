---
gh_issue: 1157
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1157
title: "skills-army-hq: hard rules first in SKILL.md — refusals are findings, status first/last, per-device root and canonical, rename propagation"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-18
doc_type: feedback
effort: 1
complexity: 1
risk: 1
phases: 1
related:
  - GH-961 (device-agnostic publisher — owns publisher policy; not re-decided here)
  - GH-958 (status exit-code semantics — not changed here)
  - GH-1046 / PR #1047 (copies-not-links prose this builds on)
  - GH-960 / PR #1097 (duplicate-clone and stale-collection warnings in sync)
  - GH-660 (drift guard), GH-672 (one collection per device)
context_tags: [skills-army-hq, docs, deployment-drift]
---

# GH-1157 — Skills Army HQ: hard rules first

## Observed problem (issue #1157, verified 2026-10-18 on the Mac mini)

Every few weeks an agent "repairs" a device's Skills Army deployment by hand. The audit in the
issue found the scripts already refuse the dangerous moves (`intake.py:295` symlinked payload,
`sync.py:133/137` unowned/foreign links); the repairs come from upstream of the scripts:

- the drift checker's default canonical fell back to a clone `development [ahead 3, behind 657]`,
  so 12 `WARN DRIFTED` lines measured the baseline, not the deployment (8 of the 12 were current);
- 22/45 machine-local receipts were stale after another device published through Git Pulse Sync,
  and `sync.py --status` has no receipt-vs-bytes check, so it exited 0;
- nothing invokes Skills Army after a Pulse pull, so three published retirements left old-name
  links dangling on another device until someone tripped over them;
- the documented default root `~/git-pulse-sync/Deployed Skills` did not exist on the device and
  `XYZ_SKILLS_ROOT` was unset, so every documented command failed with "No such file" — the
  moment agents start improvising;
- the prohibition that matters sat mid-paragraph (SKILL.md line 45) and the frontmatter
  description led with "global app symlinks".

Review on the issue (dot, comment 6254659313; adjudicated in comment 6254888394) added two
corrections this plan adopts: `intake.py --apply update` has **no** drift gate — it copies and
commits immediately and app links expose the bytes at once, so `sync.py`'s later refusal cannot
undo a downgrade; and there is **no supported stale-receipt refresh** (`catalog` is `setdefault`,
an identical `update` returns `Unchanged`), so a done-bar must not force a clean provenance report.

## Asks / acceptance criteria

Prose-only change to `skills/3-weekly/skills-army-hq/SKILL.md`:

1. A **"Hard rules (read first)"** section immediately after the H1, before "How deployment
   works", with five rules: (a) only `intake.py`/`sync.py` mutate the collection and app links —
   refusing a symlinked payload is a finding, not a bug; (b) a refusal or `WARN` is a finding to
   report, never silenced with `--adopt`, `--allow-drift`, migration flags, deletion or receipt
   edits without the operator's approval; (c) status first, status last — `sync.py --status` +
   `intake.py list` at the start and end of every task and after every Pulse pull, read as the
   starting checklist for links and SKILL.md drift, not as a provenance report; (d) root and
   canonical are per-device and resolved before any command, a missing default root is
   stop-and-report, a stale canonical makes current skills look drifted and re-vendoring from it
   downgrades them because intake applies immediately with no drift gate — verify source repo,
   branch, clean state, intended merged revision and whole-folder diff before any intake apply;
   (e) a published rename/retirement is not applied on a device until `remove OLD`, then
   `catalog`/`add NEW`, then `sync` run there.
2. A **"Definition of done"** right after the rules: report four facets separately — payload/source
   parity (whole-folder diff; the checker compares `SKILL.md` only), receipts (matching / stale /
   missing / source-unverified; stale is a valid reported partial result because no supported
   refresh exists), owned-link health with foreign entries preserved, app discovery reported
   separately — plus the verified source revision, root, and targets updated/skipped.
3. Read-only audits run with `python3 -B` / `PYTHONDONTWRITEBYTECODE=1` so an import of
   `scripts/intake.py` cannot write `__pycache__` into the payload it measures.
4. Frontmatter `description` leads with routing and the generated-collection invariant, not with
   "global app symlinks".
5. The buried sentence "Exactly these two scripts own mutation; do not hand-edit receipts or
   imitate their filesystem operations" is folded into rule (a), not duplicated.
6. One `--root` example line in the Commands block, since the prose says `--root` exists but no
   example shows it.
7. Everything else in the file is left intact except item 8; the existing "Immediate symlink
   read-through boundary" bullet is preserved (rule (d) elevates it, it does not contradict it).
8. **Narrow correction of a pre-existing error (found in plan QA round 1).** Lines 29–30 say intake
   "refuses over unrelated changes". The code applies the transaction first and only then has
   `commit_skill` decline the automatic commit (`scripts/intake.py:845–851`, `:466–471`), printing
   `WARN not committed` and returning 0 (`:855–858`) — the payload is already replaced and readable
   through app links. Reword to: applies the payload, then declines the automatic commit and warns
   when unrelated uncommitted changes exist. No script change.

## Recon (Step 4 — documentation-only; instruction/consumer path traced, no runtime recon manufactured)

- **Consumers of this file.** Every device's collection receives it through
  `intake.py update skills-army-hq --source <forge>/skills/3-weekly/skills-army-hq` (publish-from-
  source, SOP step 1); apps read it through the per-device symlinks; `sync.py` compares the
  vendored `SKILL.md` bytes with this canonical file (GH-660). The downstream child repo receives
  the folder as a managed entry of `utils/py/xyz_mini_sync.py` (line 101, GH-955); publication
  there is the existing push-downstream flow, not this PR.
- **Gate route.** `utils/ci-route.sh` → `is_docs_surface()` matches `*.md` before the subsystem
  check, so this path is a **docs surface, tier 1** (the registry comment names `skills/**/SKILL.md`
  explicitly; `test/ci-route.sh:173` pins the same for agent-chorus's SKILL.md). The local gate is
  `utils/pdda/pdda.sh run`; the push hook routes it as docs.
- **Suites touching the file.** No assertion pins the prose. Existence, identity and copy-parity
  checks remain applicable and are compatible with this change as long as the literal
  `name: skills-army-hq` line stays intact: `test/test_deploy_skills.py:174,198,551` (exists),
  `:205` (rewrites that literal to test identity), `test/gh620-skills-army-mini-sync.sh:190–194`
  (installed manager tree byte-identical to the canonical tree from the same source; an identical
  update prints `Unchanged`). `test/gh660-skill-drift.sh` uses fixtures. No suite needs editing
  (GH-831: none added).
- **Prior art (`prior_art_recon.py --query skills-army-hq`).** Open PRs: 0. Merged: #1047
  (GH-1046, 2026-10-13: copies-not-links prose) and #1097 (GH-960, 2026-10-18: duplicate Pulse
  clone / stale collection warnings) — adjacent, neither adds the rules above; adjudicated as not
  an existing fix. Open/parked: #961 (publisher device-agnostic — owns publisher policy, so this
  PR does not touch "single designated publisher"), #958 (status exit-code semantics — unchanged
  here).

## Plan (Step 5)

**Subsystem extended:** the skill's own instruction file; canonical writer is the forge repo
(publish-from-source). No parallel document, no new script, no new test.

**Smallest affected surface:** one file, `skills/3-weekly/skills-army-hq/SKILL.md`, plus this
capture doc and the ledger row.

**Non-goals (explicitly out of scope, tracked elsewhere):** any change to `intake.py`/`sync.py`
(receipt-stale detection and a selective receipt refresh are #1157 rung 4, separately approved);
hook installation or Git Pulse Sync post-pull integration (#1157 rung 3); device configuration
(`XYZ_SKILLS_ROOT`, `targets.json` canonical) on any machine; publisher policy (#961); status
exit-code semantics (#958); downstream child publication (push-downstream); any device repair.

**Dependencies:** none. **Risks / rollback:** Easy — a single-file prose revert; deployed copies
change only when a device re-vendors through intake, so no live deployment changes on merge.

### Verification scope (no new tests — GH-831)

- Docs gate: `utils/pdda/pdda.sh run` → zero errors.
- Ledger: `python3 utils/py/releases_app.py check` → clean after the roadmap writes.
- Manual read-only check: parse the edited folder with the deployment tooling's own reader
  (`intake.py`'s `package_info`, run with `python3 -B` from a scratch copy outside the repo) →
  prints `name: skills-army-hq` and the new description.
  **Red control:** the same parse on a scratch copy with the `name:` line removed → refused.
- **Evidence is durable, per AGENTS.md (GH-430):** the parse output, the red-control output and the
  gate results are recorded under `TESTS-RESULTS/2026-10-18+GH-1157/` (`SUMMARY.md`, the captured
  outputs, and `provenance.jsonl` with one `{at, base, candidate, artifact, sha256, qualification}`
  line per artifact, `base` = the `origin/development` SHA the branch was cut from, `candidate` = the
  implementation commit) and committed in the implementation PR, which links it. This is an evidence
  artifact, not a test or runner. Explicit test non-scope: no suite, no fixture, no runner.

**Smallest affected surface, restated:** `skills/3-weekly/skills-army-hq/SKILL.md` (the only
runtime change), this capture doc, the ledger row, the relay receipts, and the evidence folder.

### Ordered implementation

1. Park + rate the row (`roadmap add`, `roadmap rate --rated 60/55/50/90`) → `roadmap list --json`
   shows the row with the rating; `releases check` clean.
2. Codex relay plan QA via `relay-xyz` on this doc → `Approved` (cap: 3 rounds).
3. Promote to `PROJECT/2-WORKING` (SOP Step 1b: `git mv`, full frontmatter with `updated:`, status
   table, `roadmap repoint`, `roadmap update --raw-text`), then admit with
   `roadmap update --gid <row> --accepted-start` → `releases check` clean, `pdda.sh run` 0 errors.
4. Edit `SKILL.md` per the asks → frontmatter parse check green, red control witnessed.
5. `utils/pdda/pdda.sh run` → 0 errors.
6. Final Codex relay QA on the committed diff and evidence → `Approved`.
7. Push through the pre-push gate (expect the docs route), open the PR against `development`,
   verify base/head/scope, retire the task checkout through merge-cleanup's published-PR mode.
   **Stop there** — merge is the operator's checkpoint.

### Preflight bet check (solution-fit)

- **Outcome sought:** agents stop improvising in the deployment folder, report refusals and
  warnings instead of forcing them, and surface device drift at task start — on every device and
  in headless lanes, not only where an operator remembers to paste a prompt.
- **Smallest viable bet:** the rules at the top of the one file every agent reads before touching
  the deployment. Not built: script changes, hooks, device config, tests.
- **Alternatives rejected:** a paste-in prompt alone (does not reach headless lanes or other
  devices, and is a second source of truth that drifts from the skill); making `sync.py --status`
  report stale receipts (the right eventual move, but a code change with its own design — rung 4);
  a Pulse post-pull hook (an integration question, not an existing capability — rung 3).
- **Rollback / containment:** revert one file; nothing deployed changes until re-vendored.

## Rating (RELEASES, 2026-10-18)

`rated 60/55/50/90` — `pri` 60: severity-led, plus steady recurrence and the operator scheduling it
today. `sev` 55: recurring, work-blocking repairs of device deployment state and a real path to
*downgrading* deployed skills from a stale canonical; no data loss, recoverable through supported
commands. `appeal` 50: neutral, no operator preference stated. `effort` 90 (cheapness): one prose
file, docs gate only.

Recurrence (forge issues titled `skills-army-hq`, distinct incidents): last 14 days (2026-10-04 →
10-18): #1157 (this), #1046 (copies vs links confusion; fixed by #1047 on 10-13) — 2; preceding 14
days (09-20 → 10-04): #960 (duplicate Pulse clone, fixed by #1097 on 10-18), #961 (publisher
device-agnostic) — 2. Steady, not rising. Coverage limit: incidents tracked outside this repo
(Rebalance, the operator's personal tracker) are not counted.

## Plan QA log

- **Round 1 (Codex, `relay-system/2026-10-18/gh1157-plan-qa.md`): FAIL** — Q1 script facts, Q2
  routing, Q4–Q6 fit/scope/DRY, Q7 check design and Q8 rating all `[Pass]` with citations.
  Dispositions: `[Should]` pre-existing "refuses over unrelated changes" error at `SKILL.md:29–30` →
  **Implemented** as ask item 8 (verified: `scripts/intake.py:845–851` transacts before
  `commit_skill`, `:466–471` declines, `:855–858` warns and returns 0). `[Should]` durable evidence →
  **Implemented**: verification recorded under `TESTS-RESULTS/2026-10-18+GH-1157/` with
  `provenance.jsonl`, committed in the PR. `[Nit]` suite coverage overcompressed → **Implemented**
  (recon reworded; verified `test/gh620-skills-army-mini-sync.sh:190–194`,
  `test/test_deploy_skills.py:205`).
- Round 2: pending.
