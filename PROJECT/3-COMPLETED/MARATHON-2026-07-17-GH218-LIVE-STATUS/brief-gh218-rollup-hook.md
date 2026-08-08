---
title: "Phase brief: GH-218 rollup.sh live-status hook (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-17
updated: 2026-07-17
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh218-rollup-hook
  phase — not itself an active-doc capture; the canonical capture doc is
  GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-17. | Fire this phase via the marathon, after Phase 1 (`marathon-live.sh`) has landed. |

## Phase: gh218-rollup-hook — embed marathon-live.sh's report in the Obsidian rollup

Full context: [GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md](../GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/218

### Do NOT build a second Obsidian writer

`utils/hq/rollup.sh` already has a working, tested pattern for embedding a sibling script's report
verbatim as a new section (added for GH-192, embedding `marathon-scan.sh`'s report under
`## Marathon Readiness (cross-repo preflight)` — see `rollup.sh` around its `MARATHON_SCAN_BIN`
variable and the awk heading-demote block just above the final `OUT_FILE` write). Copy that exact
pattern for the new script; do not invent a different mechanism.

### What to build

In `utils/hq/rollup.sh`:
1. Add a `MARATHON_LIVE_BIN="${MARATHON_LIVE_BIN:-$HERE/marathon-live.sh}"` variable (mirrors the
   existing `MARATHON_SCAN_BIN` — this is also your test seam for the failure path).
2. After the existing marathon-scan embed block, add an equivalent block: run
   `bash "$MARATHON_LIVE_BIN" --out <tmp file>`, on success awk-demote its headings by 2 levels the
   same way, on failure fall back to a one-line `_live-status scan failed (exit N): ...__` note —
   copy the existing marathon-scan block's error-handling shape exactly, just pointed at the new
   script and variable.
3. Append it as a new section, `## Live Marathons (cross-repo, right now)`, after the existing
   `## Marathon Readiness` section, in the same final `{ ... } > "$OUT_FILE"` block.

### Test

Extend `test/hq-rollup.sh` with a new case (or cases) mirroring its existing `marathon-scan.sh`
success/failure cases, but for the new `MARATHON_LIVE_BIN` seam: stub `marathon-live.sh` to succeed
(assert the new section + demoted headings appear) and to fail (assert the fallback note appears,
and that the rest of the rollup — ROADMAP section, existing marathon-readiness section — is
unaffected).

### Acceptance / done means

- `rollup.sh` gains exactly one new embed block, structurally identical to the existing
  marathon-scan one, pointed at the new script.
- `test/hq-rollup.sh` extended, all green.
- `bash validate.sh` green (or unchanged from before your change).
- No new Obsidian-writing code path was introduced — this reuses the existing mechanism only.
