# Flightdeck issue visibility verification

Manual experimental harness and 16 focused Python tests pass on macOS. No CI/CD
registration was added. Source hashes and exact commands are in provenance.jsonl.

Before adapter repair, the expanded harness failed its continuous-session #440
assertion (empty issues after 182-minute context with intermediate follow-ups).
After adapter repair, the unchanged production selector failed PR-lane resolution
at manual_checks.mjs:14 (expected [440], got []). The repaired selector passes.
The retained negative controls remove the sole attribution link and require the
assertion to fail, preventing empty inputs or fallback sources from masking loss.

Browser checks (Playwright, local loopback): fixture view C rendered exactly
332/390/421/440; #440 showed 2 lanes, 1 PR and 2 checkouts. Its handoff opened,
Escape closed the dialog while retaining C, another Escape returned to B, and
the clickable Home breadcrumb returned to A. One missing favicon returned 404;
no application JavaScript error was observed. Live view C at 13:13 PDT rendered
255/417/421/431/434/440/441/443; #440 linked both Codex and Claude to PR442.
No private prompt bodies or source database contents are retained in these receipts.

The prior full repository gate remains not green; this is focused experimental
validation, not merge readiness. The independent CLIO initial-prompt capture loss
is documented in the Recon Map and is not claimed fixed by these consumer checks.
