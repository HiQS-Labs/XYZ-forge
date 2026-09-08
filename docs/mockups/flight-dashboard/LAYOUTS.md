# Flightdeck layouts

- **Layout A**: `layout-a.html` — exact copy of the operator-approved dashboard, frozen on 2026-09-08. Open directly in a browser. Its SHA-256 is recorded in `layout-a.sha256`. Preserve this file when iterating on other layouts.
- **Current entry**: `index.html`.
- **Layout B**: `layout-b.html` — three tall repo cards, swipe navigation and last-hour activity. X returns to the frozen Layout A.

All displayed activity is sample data. Live telemetry and the Swift app are later work.

The current entry links to B and shares `demo-data.js` with it. Frozen A is self-contained. Original `verification.json` describes A at commit `2a8f0c6`; `layout-b-verification.json` describes B and records the shared dependency hash.
