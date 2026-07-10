---
gh_issue: 192
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/192
title: "HQ: bridge marathon-scan.sh's preflight-ready output into the Obsidian daily rollup"
goal: Fold marathon-scan.sh's cross-repo preflight readiness into rollup.sh's Obsidian daily note
status: Shipped — merged to `main` via PR #196 (2026-07-10); #192 closed
created: 2026-07-09
updated: 2026-07-10
owner: noel
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 4
ratings_provisional: true
non_goals:
  - Not re-litigating GH-158's marathon-scan classification logic itself
  - Not re-litigating GH-27's rollup synthesis prompt/format
  - "Not fixing hq_repo_resolve()'s double-candidate bug: checked in Phase 2, already fixed by GH-159 (PR #179, 2026-07-08) with an existing passing regression test (test/hq.sh:41) — confirmed via a live synthetic reproduction, nothing to do"
related:
  - utils/hq/marathon-scan.sh
  - utils/hq/rollup.sh
  - utils/hq/hq-lib.sh
  - PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md
  - PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md
roadmap_exempt: false
---

# GH-192 · HQ: bridge marathon-scan.sh's preflight-ready output into the Obsidian daily rollup

## Status

| What was just completed | What's next |
|---|---|
| Phase 3 shipped: ran `/consult` (Codex + agy) on PR #196. agy's review was mechanically flagged by the isolation-breach detector for citing the real repo path (known false-positive pattern, GH-183/GH-187) but its content was legitimate and read anyway. Reconciled finding: Codex caught a real `[Blocker]` neither I nor agy had — `agy` was still hard-required unconditionally at startup, so a machine with no `agy` on PATH at all would exit before ever reaching the marathon section, undermining the "always reaches Obsidian" claim. Fixed: the `agy` check is now lazy (only checked when the ROADMAP scrape is non-empty). Also fixed two `[Should]` findings both models converged on: `MARATHON_TMP` cleanup now uses an EXIT trap instead of one `rm -f` at the end (survives an unexpected early abort); added a `MARATHON_SCAN_BIN` test seam + a real failure-path test. `test/hq-rollup.sh` extended to 21/21 (4 cases: populated ROADMAP, empty ROADMAP, marathon-scan.sh failing, agy entirely absent). Full `bash validate.sh` re-run: still only the 2 pre-existing unrelated reds. Re-dogfooded live against the operator's real vault once more. `pdda.sh run` clean. | All 4 phases complete. Merge PR #196 to `main`, then close #192. |

## Problem

`utils/hq/marathon-scan.sh` (GH-158) already polls every PDDA-known repo's
`PROJECT/2-WORKING/*marathon*.md` docs and preflights each active lane (ready /
blocked-not-promoted / blocked-other / stale-already-landed / ambiguous) — but it writes its
aggregate report to `PROJECT/2-WORKING/HQ-MARATHON-<date>.md` in the hub repo, not to Obsidian.

Separately, `utils/hq/rollup.sh` (GH-27) already writes to the operator's Obsidian vault
(`$HQ_OBSIDIAN_VAULT/HQ-Daily-Rollup.md`, default `~/Documents/Noel Saw/Dashboards/HQ-Daily-Rollup.md`)
— but it only scrapes generic `ROADMAP.md` "queue"/"parked"/"in progress"/"next-up" sections via
`agy` synthesis. It has no concept of preflight/ready-marathon classification, and it fully
overwrites `HQ-Daily-Rollup.md` on every run (`agy -p ... > "$OUT_FILE"`), so anything else that
also wrote there would get clobbered on the next rollup pass.

Net effect: there is no single script today that gives the operator a "which marathons are
actually ready to fire, across every known repo" view inside their daily Obsidian note. The two
features were deliberately kept separate — GH-158's own non-goals state "Not a replacement for
`utils/hq/rollup.sh` (GH-27) — that's a ROADMAP-wide Obsidian summary; this is marathon-specific
and preflight-aware."

Confirmed live on 2026-07-09 (this capture): ran `marathon-scan.sh --out <scratch>` directly.
On this device `hq_known_repos` currently resolves only `sleuth-app` (the rebalance-OS sqlite
registry and the `git-pulse-sync/pdda` registry dir are both unavailable here), which scanned 1
marathon doc, preflighted 5 active lanes, all `blocked-other`. Confirms the script runs and
classifies correctly; the registry thinness is a device-local fact, not a defect in this capture.

## Approach — decided

Option (a): `rollup.sh` shells out to `marathon-scan.sh` itself and appends its aggregate report
as a new section of the same `HQ-Daily-Rollup.md`, rather than (b) a second file in the vault.
This is what the operator actually asked for — one file with the marathon-readiness list in it.

**The marathon section is appended verbatim, not passed through `agy`.** `marathon-scan.sh`'s
classifications (ready/blocked-not-promoted/blocked-other/stale-already-landed/ambiguous) are the
one deterministic, structured signal in this whole pipeline — running them through an LLM
synthesis pass risks paraphrasing a verdict into something subtly wrong. Only the existing
ROADMAP queue/parked scrape (already free-text prose) goes through `agy`; the marathon table is
copied in as-is underneath a `## Marathon Readiness (cross-repo preflight)` heading.

This changes one existing behavior: today, if no ROADMAP items are found, `rollup.sh` prints a
message and exits without writing `OUT_FILE` at all. Now it always writes `OUT_FILE` — with a
"no active/parked items" placeholder in the ROADMAP section if that scrape was empty — so the
marathon-readiness section still reaches Obsidian on a quiet ROADMAP day. Intentional, not a bug.

Failure handling: `agy` stays a hard requirement (`command -v agy` gate, unchanged) since the
ROADMAP section fundamentally needs it. `marathon-scan.sh` only needs `node` (already required by
`rollup.sh`); if it exits non-zero for any reason, the marathon section is written as a visible
"_marathon scan failed (exit N)_" note rather than silently omitted — no silent gaps.

Known pre-existing gaps noted for whoever reads this later, not fixed here:
- GH-158's acceptance criteria record that a live `marathon-scan.sh` run once silently dropped
  sleuth-app due to a `hq_repo_resolve()` bug (same path twice as candidates, tripping its
  ambiguity check) — separate issue if still live.
- Cross-repo completeness is bounded by which registries are populated on the device the script
  runs from (rebalance sqlite db, `git-pulse-sync/pdda` dir, `~/.config/xyz/registry.tsv`).
- `test/hq-marathon-scan.sh` already exists (GH-158, 11/11 green) but was never added to
  `validate.sh`'s `TESTS` array — fixing that alongside adding the new `test/hq-rollup.sh`, since
  it's the same area and a one-line registration.

## Phase 0 — Bridge rollup.sh into marathon-scan.sh, hermetic test, validate.sh registration

### Checklist

- [x] Add an `AGY_BIN="${AGY_BIN:-agy}"` test seam to `rollup.sh` (matches the `CODEX_BIN`/
      `GEMINI_BIN`/`AIDER_BIN` convention already used by `consult.sh`'s tests).
- [x] Restructure `rollup.sh`: capture the `agy` synthesis into a variable instead of redirecting
      straight to `OUT_FILE`; always run `marathon-scan.sh --out <tmp>` and capture its output;
      write both sections to `OUT_FILE` in one final write, regardless of whether the ROADMAP
      scrape found anything.
- [x] Add `test/hq-rollup.sh`: stub `agy` via `AGY_BIN`, reuse `marathon-scan.sh`'s existing fixture
      pattern (`HQ_XYZ_REGISTRY`/`HQ_PDDA_REGISTRY_DIR`/`HQ_SEARCH_ROOTS`) for a real (non-stubbed)
      marathon classification. Cover: (1) populated ROADMAP + a marathon lane — both sections
      present; (2) empty ROADMAP + a marathon lane — file still written, placeholder + marathon
      section both present. 12/12 assertions pass.
- [x] Register `hq-rollup.sh` and the pre-existing `hq-marathon-scan.sh` in `validate.sh`'s `TESTS`
      array.
- [x] Full `bash validate.sh` green — 109/111 (2 pre-existing, unrelated reds: `acorn-extract.sh`
      missing the `acorn` npm module, `python:test_python_layer.py` missing `pytest`).

### QA checklist — Phase 0

- [x] The marathon section is never routed through `agy` — verified by asserting the stub-agy
      output only appears in the ROADMAP section of the test fixture, and the real marathon-scan
      table text appears byte-for-byte in the marathon section.
- [x] The "no ROADMAP items" case still produces a written file with the marathon section intact
      (the one deliberate behavior change from today).
- [x] `rollup.sh`'s own `agy`/`node` hard-requirement checks are unchanged.

## Phase 1 — Dogfood against the real `agy` CLI and real repo registries

Phase 0 only proves the bridge against a stubbed `agy` and fixture repos. Phase 1 runs the real
`utils/hq/rollup.sh` — real `agy`, real `hq_known_repos`/`hq_repo_resolve`, real
`marathon-scan.sh` — to confirm the merged note actually reads well and the integration holds up
outside the test harness.

Safety note: the operator's real `HQ-Daily-Rollup.md` (`~/Documents/Noel Saw/Dashboards/`) already
has content from a prior manual rollup. The first real run is pointed at a scratch
`HQ_OBSIDIAN_VAULT` override, not the live file, so the operator can review the output before
anything real gets overwritten.

### Checklist

- [x] Run `rollup.sh` for real with `HQ_OBSIDIAN_VAULT` overridden to a scratch dir — real `agy`,
      real registries, real `marathon-scan.sh` — and capture the result. Found 3 real repos
      (rebalance-OS, sleuth-app, xyz-3-agents-swarm), 6 marathon docs, 2 active lanes preflighted.
- [x] Review the merged note's shape: ROADMAP section reads sensibly (agy grouped by repo,
      concise); Marathon Readiness section appends cleanly. One cosmetic nit found (H1-under-H2
      heading nesting from marathon-scan's own report title) — accepted as-is, operator declined
      the fix-first option.
- [x] Get explicit operator go-ahead before pointing a run at the real
      `~/Documents/Noel Saw/Dashboards/HQ-Daily-Rollup.md` — asked via AskUserQuestion, operator
      chose "run it now."
- [x] Live run completed: `~/Documents/Noel Saw/Dashboards/HQ-Daily-Rollup.md` now 63 lines, both
      sections confirmed present (`## Marathon Readiness (cross-repo preflight)`, `## Net result`).
- [x] Live-environment gap noted, not fixed (per non-goals): `git-pulse-sync/pdda/` registry dir
      was empty earlier in this session and populated itself between checks (external device sync,
      unrelated to this change) — explains why an earlier manual `hq_known_repos` check saw only
      1 repo while this dogfood run saw 3. Not a defect in this work.

## Phase 2 — Heading nit + verify the hq_repo_resolve() bug is actually still live

Operator picked "also fix `hq_repo_resolve()`'s double-candidate bug" for Phase 2 scope. Before
writing any fix, checked whether it's actually still live — it isn't.

**Verification, not assumption:** read `hq_xyz_lookup()` (`utils/hq/hq-lib.sh`) and found it
already dedupes registry rows by resolved `coord` path, preferring the vendored `.xyz` install —
exactly GH-159's fix (PR #179, merged `39729a0`, 2026-07-08). Reproduced the exact symptom live:
built a synthetic XYZ registry with two rows resolving to the same coord (one legacy install, one
vendored `.xyz`) and ran `hq.sh resolve` against it — resolved cleanly (`RESOLVED_VIA=exact`), no
ambiguity, vendored install correctly preferred. `test/hq.sh:41` already pins this exact case as a
named GH-159 regression, and it was already green in Phase 0/1's `validate.sh` runs. **Nothing to
fix — the non-goal's hedge ("separate issue if still live") is resolved: it isn't live.**

Redirected the remaining Phase 2 work to the one thing still actually in scope: the H1-under-H2
heading nit accepted as a known cosmetic issue at the end of Phase 1.

### Checklist

- [x] Verify `hq_repo_resolve()`'s double-candidate bug before fixing anything — confirmed already
      fixed by GH-159, with a live synthetic reproduction and an existing passing regression test.
      No code change made for this; would have been fixing an already-fixed bug.
- [x] Fix the heading nit: `rollup.sh`'s marathon-section awk now demotes every heading in the
      embedded `marathon-scan.sh` report by 2 levels (`#` → `###`, `##` → `####`, fence-aware) so
      the report's own H1 title nests under this section's `## Marathon Readiness` H2 instead of
      sitting at a sibling level to its own subheadings.
- [x] Extend `test/hq-rollup.sh`: assert the embedded report's title now reads `### HQ MARATHON`
      and that no bare `# HQ MARATHON` (undemoted H1) leaks through. 14/14 assertions pass.
- [x] Full `bash validate.sh` re-run: still 109/111 (same 2 pre-existing, unrelated reds).
- [x] Re-dogfooded live against the operator's real `HQ-Daily-Rollup.md` to confirm the heading fix
      actually landed in the real file, not just the test fixture.

### QA checklist — Phase 2

- [x] No code was written to "fix" a bug that turned out to already be fixed — verified first,
      only acted on what was actually still broken.
- [x] The heading fix is scoped to the embedded report only; `marathon-scan.sh`'s own standalone
      output (`PROJECT/2-WORKING/HQ-MARATHON-<date>.md` in the hub repo) is untouched — the demotion
      only happens inside `rollup.sh`'s awk pipeline, not in `marathon-scan.sh` itself.

## Phase 3 — /consult (Codex + agy) on PR #196, then fix what it found

Ran `relay-automation/consult.sh` against PR #196's branch, asking both advisors to independently
review `utils/hq/rollup.sh`, `test/hq-rollup.sh`, and the `validate.sh` registrations for
correctness, test coverage, design, and merge readiness. Transcripts:
`relay-system/2026-07-10/pr196-review-100519/`.

**Degrade**: agy answered but was mechanically stamped `FAIL` by the isolation-breach detector for
citing the real repo root in its file-link citations instead of the isolation worktree path — a
known false-positive pattern (GH-183, GH-187). Read the transcript anyway; its content was a
legitimate, well-cited review, just auto-flagged by a containment check that isn't about content
quality. Codex's answer also got a mechanical `NO FIRSTHAND VERIFICATION CITED` stamp despite every
finding carrying a `file:line` citation — treated as a possible false positive on that detector too,
verified content directly rather than trusting or discarding either stamp blindly.

**Reconciled disagreement**: Codex said block the merge; agy said mergeable-with-follow-ups. The
actual substance: Codex caught a real `[Blocker]` agy missed — `command -v "$AGY_BIN"` was still an
unconditional startup check (old lines 13-14), before the script knew whether the ROADMAP scrape
would even need `agy`. On a machine with no `agy` on `PATH` at all, `rollup.sh` would exit 2 before
ever reaching the marathon-scan section — meaning the PR's own headline claim ("marathon readiness
always reaches Obsidian, even on a quiet day") was only true if `agy` happened to be installed, not
truly decoupled. Independently verified by reading the code directly (not just trusting the
transcript) before agreeing with Codex's severity call.

**Convergent findings** (both models, independently): the `marathon_log="$(...)" || marathon_rc=$?`
capture pattern is correct under `set -euo pipefail`; verbatim-appending the marathon section (not
routing it through `agy`) is the right design; registering both HQ tests in `validate.sh` was
correct and overdue; `test/hq-rollup.sh` never exercised `marathon-scan.sh`'s own failure path.

**agy-only finding**: `MARATHON_TMP` was only cleaned up via one `rm -f` at the end — an unexpected
early abort would leak it. Given `utils/hq/` ships an hourly-scan plist template, this could
genuinely accumulate over time.

### Checklist

- [x] Fix the `[Blocker]`: moved the `command -v "$AGY_BIN"` check from unconditional startup into
      the `if [ -s "$RAW_FILE" ]` branch — `agy` is now only required when the ROADMAP scrape
      actually needs synthesizing. `node`'s check stays unconditional (correctly — both the
      ROADMAP-scan loop and `marathon-scan.sh` itself need it regardless of ROADMAP content).
- [x] Fix cleanup: `MARATHON_TMP` now cleaned via `trap 'rm -f "$MARATHON_TMP"' EXIT` set right
      after `mktemp`, replacing the single end-of-script `rm -f`.
- [x] Add a `MARATHON_SCAN_BIN="${MARATHON_SCAN_BIN:-$HERE/marathon-scan.sh}"` test seam (same
      pattern as `AGY_BIN`) so the failure path is actually testable without depending on the real
      `marathon-scan.sh` ever failing under a fixture.
- [x] Extend `test/hq-rollup.sh`: Case C (marathon-scan.sh exits non-zero — asserts the visible
      failure banner, not a silent drop) and Case D (agy entirely absent from `PATH`, ROADMAP
      empty — the direct regression test for the Blocker fix). 21/21 total.
- [x] Full `bash validate.sh` re-run: still only the 2 pre-existing, unrelated reds.
- [x] Re-dogfooded live against the operator's real `HQ-Daily-Rollup.md` once more post-fix.

### QA checklist — Phase 3

- [x] Didn't accept either advisor's mechanical PASS/FAIL stamp at face value — read agy's
      FAIL-flagged content directly (legitimate, just a containment-detector false positive) and
      independently re-verified Codex's Blocker claim against the actual code before agreeing with it.
- [x] The Blocker fix has a direct regression test (Case D), not just a code change taken on faith.
- [x] Pre-existing, out-of-scope item noted but not fixed: agy also flagged `RAW_FILE`'s static,
      non-`mktemp`-randomized filename under the system temp directory (that line predates this PR)
      as a concurrent-instance collision risk — real, but unrelated to this PR's diff.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"path_absent","path":"test/hq-rollup.sh"}],"artifacts":["utils/hq/rollup.sh","test/hq-rollup.sh","validate.sh"],"remediation":{"source":"self","criteria":"Fix per plan"},"lanes":{"orchestrator_only":[]}}
```
