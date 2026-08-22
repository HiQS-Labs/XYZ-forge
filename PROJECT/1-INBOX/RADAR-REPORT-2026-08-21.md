---
title: Radar Report — 2026-08-21
status: Active
created: 2026-08-21
updated: 2026-08-21
owner: operator
goal: >
  Windowed (repo-lifetime) strategic read: flow distribution, recurring-defect clusters, and
  release-plan alignment for XYZ-forge as of 2026-08-21/22.
doc_type: report
---

# Radar Report — XYZ-forge — 2026-08-21

## Window

Repo history is **younger than the default 21-day window** — first commit 2026-08-15, "now" ≈
2026-08-22T06:23Z (2026-08-21 23:23 PDT). Window used: **2026-08-15 → 2026-08-22 (full repo
lifetime, 7 days)**. No prior window of equal length exists, so **there is no trend line** — this
is a single baseline read, not a comparison. Per the degradation table, recurrence (Lens 2) is also
structurally young: little time has passed for anything to recur twice.

**`gh` was unreachable for the second half of this run** ("error connecting to api.github.com").
Confirmed working earlier in this session (PRs #133/#147 were merged via `gh` moments before), so
this is a transient outage, not an auth/config problem. Cost: Lens 2 signals 3–4 (issue-text
similarity, false-close/reopen), the Step 2b open-PR collision check (see note below — answered
from this session's own prior `gh pr list`), and Lens 3's milestone→issue join. Everything else in
this report is git/file-based and unaffected.

## Lens 1 — Flow distribution

Tally proven: `git log --no-merges` over the window emitted **380** subjects; `git rev-list
--no-merges --count` independently confirms **380**. Bucket counts sum to 380.

| Bucket | Count | Share of RGT denominator |
|---|---:|---:|
| Harness (excluded from denominator) | 168 | — (44.2% of all 380 commits) |
| Run | 148 → **173 adjusted** | 69.8% → **81.6% adjusted** |
| Grow | 36 → **38 adjusted** | 17.0% → **17.9% adjusted** |
| Transform | 0 | 0% (rgt: adoption: **0 docs** — nobody has declared any) |
| Unclassified | 28 → **1 adjusted** | 13.2% → **0.5% adjusted** |

RGT denominator = 212 (Run+Grow+Transform+Unclassified), same in both reads — only the split moves.

**Adjusted read**: of the 28 mechanically-Unclassified commits, 25 are ordinary `fix`/`chore`/`docs`
work that just used a non-conventional subject (`release(0.7.1): …`, `Ballast 0.7.0: …`, `GH-1: …`),
2 are unprefixed `feat`-shaped work ("Add timed Agent2Agent invitations", "skills: install
relay-xyz…"), and exactly 1 (`XYZ: initial public release`) is genuinely uncategorizable — the
repo's own root commit.

**Malformed-prefix family, recurring (source-fixable):** `GH-<n>: <subject>` used as if the issue
number were the commit type, seen **5 times** (`GH-23:`, `GH-15:`, `GH-5:` ×2, `GH-1:`) — all from
the repo's first two days (2026-08-15/16). The fix is the convention, not a smarter parser: these
should be `fix(GH-23): …` etc.

## Lens 2 — Recurring-defect radar

**Signal 1 (`related:` frontmatter)** — yield: 8 of 40 `PROJECT/**/GH-*.md` docs carry the key (2
in scalar-bracket form, 6 in block-array form; both shapes parsed). One doc (GH-555) only
self-cites its own issue number — noise, dropped. Genuine kinship found:

- **GH-1 ↔ GH-564 ↔ GH-559 ↔ GH-177** — explicitly cross-referenced as "same family": fixture/suite
  containment escapes (a suite resolving or removing files outside its sandbox; `mktemp` resolving
  to the repo root instead of an isolated temp dir).
- **GH-90 ↔ GH-91** — a containment false-positive (a legitimate directory on `ALLOW_PATHS`
  misread as a violation) that led directly to needing a sanctioned scratch-dir facility.

**Signal 2 (shared seam, `fix:` commits by touched file)** — yield: high touch-counts on
`validate.sh` (13), `CHANGELOG.md`/`ROADMAP.md`/`ROADMAP-DASHBOARD.md`/`releases.db`/`releases.sql`
(4–8 each) pass the mechanical ≥2-days/≥2-issues discriminator, but on inspection **these are
central ledger/registry files that nearly every unrelated PR touches once** — 12 different,
unrelated issue numbers each edited `validate.sh` once (GH-90, GH-91, GH-57, GH-35, GH-45, GH-52,
GH-53, GH-54, GH-23, GH-15, GH-14, #135) — file centrality, not a shared defect. **Reported as a
non-finding on purpose**: signal 2's mechanical discriminator alone is insufficient in a repo with
central ledger files; this run adds "is it a registry/ledger file everyone touches" as a required
manual check before trusting the discriminator.

One real signal-2 cluster survived that check: **`utils/py/{relay_drive,marathon_drive,agy-turn,
consult}.py`** — Wave 1 of the harness driver/relay hardening (#129, #130, #131, PR #134) was
immediately followed by a second wave of 6 more fixes on the same subsystem (#135–#140, PR #145),
landing within about a day of each other. Two distinct PRs, two distinct issue sets, same seam.

**Signal 3 (issue-text similarity)** — unavailable this run (`gh` outage).
**Signal 4 (false close → reopen)** — text half checked: 0 doc-only-closure hits in
`PROJECT/3-COMPLETED` and `PROJECT/4-MISC`. The `gh api` reopen half is unavailable (outage). Report
as **available-but-empty on the text half, unavailable on the API half** — not a clean sweep.
**Signal 5 (`reported_from:` cross-repo)** — structurally unavailable: 0 docs carry the key.
**Signal 6 (operational evidence)** — one `temp/logs/` artifact exists; not deep-dived this run
(time-boxed). Independent corroboration instead came from **this session's own tool output**: a
repo hook (`relay-automation/hooks/gh177-sandbox-test-guard.sh`) refused a sandboxed test run mid-
session, citing "sandbox-broken mktemp fed the destructive EXIT trap that wiped this repo twice" —
this is a live, still-guarded-against instance of exactly the GH-1/90/91/177/559/564 family above,
observed directly rather than inferred from history.

### Targets

1. **RADAR-class-fixture-containment** — 6 issues (GH-1, GH-90, GH-91, GH-177, GH-559, GH-564) over
   the repo's first week, explicitly self-declared as one family, **plus a live third repo-wipe
   near-miss caught by this session's own guard hook**. Class: test/build machinery escaping its
   sandbox (bad `mktemp` root resolution, containment false-positives). Blast radius: the whole
   suite-running path (this repo's own gate refuses to run under a sandboxed shell over it). A
   single durable fix (root-anchor every `mktemp` call, verified in a real sandboxed CI runner) would
   retire the family instead of relying on a growing list of individually-patched suites.
2. **RADAR-class-harness-driver-relay-seam** — 9 issues over 2 sequential PRs within ~1 day
   (#129–131 then #135–140), same subsystem (`relay_drive.py`, `marathon_drive.py`, `agy-turn.py`,
   `consult.py`). Class: the relay/marathon driver's own turn-taking, auth-probe, and root-resolution
   logic. Not necessarily still active — 2 waves in 1 day reads as a hardening push converging, not
   an open wound — but worth one more look before calling it closed.

## Lens 3 — Release recalibration

`RELEASES.md` is real content, not the installer seed (9 blocks: 4 Shipped, 5 Draft). Milestone→
issue join is **unavailable this run** (`gh` outage) — read from `Description:` prose instead, as
directed for that fallback.

Draft (unshipped) blocks: **Plumbline** (0.4.0, reflection/self-improvement), **Lantern** (0.5.0,
failure legibility — milestone explicitly "not created yet"), **Meter** (0.6.0, public-clone
stranger path), **Sundown** (0.8.0, retire Bash twins), **Cargo** (0.9.0, ship the RELEASES DB +
timeline generator inside vendored `.xyz/`).

Both Lens-2 targets are **UNCLAIMED** by any draft block:
- Fixture-containment hardening doesn't fit Lantern's stated scope (Lantern is explicitly "not a
  lifecycle invariant" issue — containment IS a lifecycle invariant) or any other draft block.
- The harness-driver/relay seam isn't named in Sundown, Cargo, or any other block either, despite
  being the single largest fix cluster in the window.

## Step 2b — Open-PR collision check

Answered from this session's own state, not a fresh `gh` call (`gh` was reachable minutes earlier
in this session, when both open PRs — #133, #147 — were merged into `development`): **zero open
PRs** as of this run. No collision risk to report; nothing to schedule around.

## Checklist (for Sink B — blocked this run)

`gh issue list --label radar` could not run (`gh` outage). The checklist below is the content that
Sink B would carry; **it has not been created or updated on GitHub**. Re-run the persistence step
once `gh` is reachable — do not skip it silently.

```md
## RADAR-class-fixture-containment — 6 issues over 7 days · first-seen: 2026-08-21 · runs: 1

- [ ] Root-anchor every `mktemp` call used by test/build machinery so it cannot resolve into the
      repo root under a sandboxed shell — the shared defect behind GH-1, GH-90, GH-91, GH-177,
      GH-559, GH-564, and the live guard hit in this session
- [ ] Add a sandboxed-CI regression asserting the repo survives a suite run under the exact
      sandbox conditions that caused the two historical wipes
- [ ] Bind this class to a release/milestone (currently unclaimed by RELEASES.md) so it stops
      relying on ad-hoc catches

## RADAR-class-harness-driver-relay-seam — 9 issues over ~1 day · first-seen: 2026-08-21 · runs: 1

- [ ] Confirm Wave 2 (#135-140, PR #145) is the close of this hardening push, not the start of a
      third wave — recheck `relay_drive.py`/`marathon_drive.py`/`agy-turn.py`/`consult.py` for
      open follow-ups before treating it as settled
```
