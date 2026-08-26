---
title: "GH-197: two-tier xyz-vendor.sh — Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP"
status: active
created: 2026-08-23
updated: 2026-08-23
owner: orchestrator (Claude Code)
goal: >
  Make xyz-vendor.sh two-tier (core harness by default, RELEASES machinery as an
  explicit opt-in overlay), mechanize the Tier 2 onboarding SOP proven by hand on
  LTVera-Pandas, and migrate the 9 existing vendored repos without stripping live
  adopters.
gh_issue: 197
source: https://github.com/HiQS-Labs/XYZ-forge/issues/197
branch: gh-197/vendor-tier-split
doc_type: capture
effort: 3
complexity: 3
risk: 3
related:
  - "#105 — parent; its 2026-08-20 'always in the payload' operator decision is superseded by this doc (operator call 2026-08-23)"
  - "#312 — preserve-list contract in materialize_vendor(); the overlay must be audited against it"
  - "#77 — full-mirror-not-curated-manifest lesson; drives the deny-list mechanism"
  - "#564 / #195 — fixture containment rules all new tests follow"
  - "#49 — test/xyz-vendor.sh surface suite this work extends"
---

# GH-197 — Two-tier vendor split (GH-105 follow-up)

## Status

| What was just completed | What's next |
|---|---|
| Plan QA'd via relay-xyz (CommandCode Ox Alpha, `stealth/ox-alpha`): **Approved r1**, 2 Nits folded in — `relay-system/2026-08-23/gh-197-vendor-tier-split-plan-qa.md` | Cut `gh-197/vendor-tier-split` and execute Phase 1 (overlay audit) |

Radar class: Grow (vendoring surface). Not in any frozen release manifest;
#105 is the sole frozen entry of 0.9.0 "Cargo" — reconcile manifest membership
at closeout (this work delivers #105's payload under a changed contract).

## Why (and what changed since #105)

`VENDOR_DIRS="relay-automation bin src utils test skills"`
([xyz-vendor.sh:326](relay-automation/xyz-vendor.sh#L326)) mirrors **all** of
`utils/`, so every vendored repo already silently receives the RELEASES
machinery today. #105 (2026-08-20) decided "always in the payload, never wired
by default." Operator call 2026-08-23 supersedes that: the payload itself
becomes opt-in (Tier 2), because most vendored repos never adopt the ledger and
should not carry ~500K of machinery plus its merge story.

Key facts from the code audit:

- The harness core has **no** imports/calls into the releases set (grep sweep
  of `utils/marathon-plan.sh`, `utils/swarm-preflight.sh`,
  `utils/py/marathon_drive.py`, `relay-automation/*`, `bin/*`, `src/*` — one
  comment-only mention of `release-lanes.sh` in `utils/marathon-plan.sh:209`,
  no code path).
  Consumers are `skills/releases/`, `skills/standup/`, tests, and ROADMAP
  governance — all harness-repo-side, not vendored-runtime-side. The split is
  clean.
- `RELEASES-DB-FAQS.md` sits at the repo root, outside every `VENDOR_DIRS`
  entry — today it never ships at all, though #105 scopes it in ("the merge
  story travels with the DB"). Tier 2 must add it explicitly.
- Tests load `releases_app.py` via `importlib` path-based loading, so no
  package/import relocation issues.

## Tier definitions

**Tier 1 (default)** — core harness only: `relay-automation/ bin/ src/ test/
skills/` plus `utils/` minus the `RELEASES_OVERLAY` manifest.

**Tier 2 (opt-in)** — `xyz-vendor.sh <target> --with-releases` (flag joins the
existing `while/case` arg loop at
[xyz-vendor.sh:36-51](relay-automation/xyz-vendor.sh#L36-L51), same pattern as
`--no-register`). Ships the overlay into `.xyz/` plus root-level
`RELEASES-DB-FAQS.md`.

**Provisional `RELEASES_OVERLAY` manifest** (Phase 1 confirms):

- `utils/py/releases_app.py`
- `utils/py/releases_cycle.py`
- `utils/releases-merge-resolve.sh`
- `utils/release-lanes.sh` (ci-route maps it to the `releases` subsystem)
- `utils/timeline/` (whole dir: `export_timeline.py`, `RELEASES.html`, README)
- `RELEASES-DB-FAQS.md` (root file → staged into `.xyz/` docs location, Tier 2 only)

Deliberately **excluded** from the overlay (stay Tier 1): `utils/roadmap-dashboard.sh`,
`utils/leaderboard.sh` — they read the ledger but ci-route maps them to `hq`,
and they degrade gracefully without a DB. Phase 1 re-checks this call.

**Mechanism — deny-list, not allow-list.** Tier 1 remains a full mirror (the
GH-77 lesson in the rationale block at
[xyz-vendor.sh:314-325](relay-automation/xyz-vendor.sh#L314-L325): curated
allow-lists silently dropped newly added lanes). `materialize_vendor()` removes
the `RELEASES_OVERLAY` paths from `$STAGE_DIR` before the atomic swap;
`--with-releases` skips the removal. A new `utils/` file defaults to shipping
in Tier 1 unless explicitly added to the overlay manifest.

## Migration — the 9 existing vendored repos

Re-vendor must not strip RELEASES files from an adopted repo (LTVera-Pandas is
live). **Decision: auto-detect adoption** — `releases.db` present at the target
root ⇒ treat as Tier 2 regardless of flags (sticky), and say so on stdout.
Rationale for auto-detect over a registry `tier` column: the registry write
fails open under lock contention
([xyz-vendor.sh:171](relay-automation/xyz-vendor.sh#L171) skips the update and
the vendor still succeeds), so `~/.config/xyz/registry.tsv` cannot be a source
of truth. A registry `tier` column may be added later as informational only —
out of scope here.

The other 8 vendored repos have no `releases.db`, so their next `xyz-sync.sh
update` drops the overlay from `.xyz/` — the intended behavior change; their
root state is untouched because they have none.

## GH-312 constraint

The overlay's runtime state (`releases.db`, `releases.sql`, `RELEASES.md`,
`RELEASES-PREVIEW.html`) lives at the target ROOT, not under `.xyz/` — so
nothing new should join the preserve loop at
[xyz-vendor.sh:373](relay-automation/xyz-vendor.sh#L373). Phase 1 audits every
write path in `releases_app.py` / `export_timeline.py` for `.xyz/`-resident
state; Phase 4 pins the "overlay writes nothing under `.xyz/`" invariant with a
test either way.

## Plan

1. **Overlay audit** — confirm the provisional manifest above: grep the overlay
   scripts' write paths for anything landing under `.xyz/` (GH-312), confirm
   `roadmap-dashboard.sh`/`leaderboard.sh` stay Tier 1, and record the final
   `RELEASES_OVERLAY` list in `relay-automation/xyz-vendor.sh`.
2. **Tier split in `relay-automation/xyz-vendor.sh`** — add `--with-releases`
   to the arg loop; add the `RELEASES_OVERLAY` manifest + deny-list removal in
   `materialize_vendor()`; auto-detect `releases.db` at target root (sticky
   Tier 2); stamp the resolved tier into `.xyz/VERSION`; fix the `:314-325`
   comment drift (`utils` missing from the rationale block).
3. **Onboarding SOP script `relay-automation/xyz-releases-onboard.sh`** —
   mechanize LTVera-Pandas `ad0d816`: (a) `releases init` + `import` from
   legacy `RELEASES.md`, refusing if `releases.db` exists; (b) gitignore
   audit + `!releases.db` carve-out; (c) prepend the app-managed banner to
   `RELEASES.md`; (d) `reconcile --map` MIG- refs → GH_URLs, detecting the
   shared-tracking-URL collision (one URL reused across releases) and
   **stopping with a report** — never auto-filing issues in the target repo;
   (e) `releases check` clean, print the exact commit command, never commit.
4. **Tests** — extend `test/xyz-vendor.sh` + new `test/gh197-vendor-tier-split.sh`,
   fixture-scoped per GH-564/GH-195 (`_setup.sh` sandbox, `fixture_guard` at
   use boundaries, `XYZ_REGISTRY` pinned to `$WORK`): tier-1-default,
   tier-2-overlay (incl. `RELEASES-DB-FAQS.md`), onboarding happy path,
   gitignore carve-out (appended exactly once, only when a `*.db` rule exists),
   shared-tracking-URL refusal (nonzero, no issue filed), re-vendor-preserves-
   adoption, overlay-writes-nothing-under-`.xyz` pin. Also close today's gap:
   `utils/` is asserted only by `*.sh` count — add `utils/py`/`utils/timeline`
   assertions.
5. **Docs** — `skills/relay-xyz/SKILL.md` install-path table
   ([SKILL.md:173-175](skills/relay-xyz/SKILL.md#L173-L175)) → tier table
   (`install.sh` tick-only / Tier 1 / Tier 2) + refresh the GH-312 paragraph;
   `relay-automation/README.md` new `## Vendoring tiers` section + `Components`
   row update; SOP usage doc beside the scripts in `relay-automation/`.
6. **Gate + closeout** — full gate green in a disposable clone; PR into
   `development`; wave-reconcile-ready; append
   `## Lessons Learned (For Future Agents)` at closeout.

## Acceptance

- [ ] `xyz-vendor.sh <target>` (no flag) lands `.xyz/` with zero overlay files; harness runnability sanity (`bin/tick`, `relay-turn-lib.sh`) still passes
- [ ] `xyz-vendor.sh <target> --with-releases` lands the full overlay incl. `RELEASES-DB-FAQS.md`
- [ ] `releases.db` at target root forces Tier 2 on re-vendor with no flag (LTVera-Pandas-shaped fixture)
- [ ] `xyz-releases-onboard.sh` happy path: legacy `RELEASES.md` → imported DB, banner prepended, `releases check` clean, commit command printed, no commit made
- [ ] Gitignore carve-out appended exactly once, only when a `*.db`-style rule exists
- [ ] Shared-tracking-URL collision → report + nonzero stop; no issue auto-filed in the target repo
- [ ] Test pins that the overlay writes nothing under `.xyz/` (GH-312)
- [ ] `VENDOR_DIRS` rationale comment names `utils`
- [ ] SKILL.md tier table + README `## Vendoring tiers` landed; SOP doc lives in `relay-automation/`
- [ ] Full gate green in a disposable clone (separate full clone, not a linked worktree — GH-564); ROADMAP synced (`releases_app.py roadmap sync`)

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh197-vendor-tier-split.sh" },
    { "type": "path_absent", "path": "relay-automation/xyz-releases-onboard.sh" },
    { "type": "grep_absent", "path": "relay-automation/xyz-vendor.sh", "pattern": "with-releases" }
  ],
  "artifacts":     [
    "relay-automation/xyz-vendor.sh",
    "test/xyz-vendor.sh",
    "skills/relay-xyz/SKILL.md",
    "relay-automation/README.md",
    "relay-automation/xyz-releases-onboard.sh",
    "test/gh197-vendor-tier-split.sh"
  ],
  "artifacts_new": [
    "relay-automation/xyz-releases-onboard.sh",
    "test/gh197-vendor-tier-split.sh"
  ],
  "remediation":   { "source": "self#plan", "criteria": "Default vendor lands no RELEASES overlay file; --with-releases or releases.db-at-root lands all of them; onboarding SOP refuses shared tracking URLs and never commits; full gate green in a disposable clone." },
  "lanes":         { "agy_safe": [ "test/", "skills/relay-xyz/" ], "orchestrator_only": [ "relay-automation/", ".tick/" ] }
}
```

## Out of scope / parked

- `utils/ci-route.sh::subsystem_of()` maps neither `utils/releases-merge-resolve.sh` nor `utils/timeline/*` to `releases` (edits fail closed to tier 3) — separate fix.
- Registry `tier` column (informational) — later, if ever.
- #75 dashboard-verb fold-in interaction — unchanged from #105.

## Merge evidence

- PR #210 merged 2026-08-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
