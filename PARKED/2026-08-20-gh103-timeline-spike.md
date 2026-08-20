# Parked — GH-103 timeline spike session, 2026-08-20

Items deliberately NOT continued in this session, filed here so they stop resurfacing in chat.
Each carries enough context to pick up cold; real homes are the linked issues/files.

- **#75 fold-in decision.** The GH-103 exporter (`utils/timeline/export_timeline.py`) is
  effectively the rendering prototype for the queued `releases dashboard` verb
  ([#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75)). Open call: fold it into
  `releases_app.py` as the verb's body, or keep it standalone with the `data.json` contract as
  the seam. Decide when #75 is picked up; nothing blocks on it.

- **RELEASES-PREVIEW.html staleness guard.** The committed snapshot (operator decision) has no
  freshness check, unlike ROADMAP-DASHBOARD.md. Flagged [Blocker] by the agy QA relay r1
  (relay-system/2026-08-20/gh103-branch-qa.md); deferred because the dashboard pattern can't be
  copied verbatim — the bake embeds `generatedAtDisplay`, so `git diff --exit-code` always fails.
  Prerequisite: a deterministic bake mode (omit/pin the timestamp), then wire the check.

- **`--check-drift` guard wiring.** `export_timeline.py --check-drift` (exit 1 on
  RELEASES.md-vs-DB drift, band-aware, writes nothing) exists but is wired into no check lane.
  Candidate homes: `utils/pdda/pdda.sh releases` (warn-only lane) or the pre-push tier registry
  (`utils/ci-route.sh`). Both are protected governance surfaces — operator decision, proposed
  rather than patched from the GH-103 spike branch.

- **Duplicate GH-10 entry blocks `roadmap sync`.** `releases_app.py roadmap sync` refuses:
  GH-10 appears twice in `ROADMAP.md`'s queue (one "✅ BUILT 2026-08-19", one "⏸ stood down
  2026-08-19"). Pre-existing on `development`; merging the two entries is an operator call.
  Until then the GH-69 shadow cannot re-sync.

- **The durable drift fix is GH-32 Phase 2, not more guards.** The strict flip (DB becomes the
  writer's source; `gen` generates RELEASES.md) retires the manual dual-write that produced the
  Bulwark/Daybreak gap. Tracked in
  [GH-32-RELEASES-APP-SQLITE.md](../PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) · #32.
  24 grandfather entries still pending disposition (`releases_app.py check`).
