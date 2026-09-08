# Flightdeck layouts

- **Layout A**: `layout-a.html` — exact copy of the operator-approved dashboard, frozen on 2026-09-08. Open directly in a browser. Its SHA-256 is recorded in `layout-a.sha256`. Preserve this file when iterating on other layouts.
- **Current entry**: `index.html`.
- **Layout B**: `layout-b.html` — three tall repo cards, swipe navigation and last-hour activity. Click a card to spotlight it and dim the surroundings. Click the spotlighted repo again to zoom into Layout C. Click the background or press Escape to clear the spotlight. Horizontal navigation also clears the spotlight. Keyboard users can Tab to a repo name and press Enter/Space to spotlight, then again to zoom in. X returns to the frozen Layout A.

- **Layout C**: `layout-c.html?repo=ltvera` — issues within the selected repo, using the same tall cards and gestures. Each issue shows its agents, last-hour activity, next action and lane-linked PRs. Fewer cards are centered. X or Escape zooms out to the same repo and carousel position in B. Workspace folders are explicitly shared repo context; issue ownership is unknown.

All displayed activity is sample data. Live telemetry and the Swift app are later work.

The current entry links to B and shares `demo-data.js` with it. Frozen A is self-contained. Original `verification.json` describes A at commit `2a8f0c6`; `layout-b-verification.json` describes B and records the shared dependency hash.

B and C share `focus-cards.css`, `focus-cards.js` and `demo-data.js`; A remains self-contained. Layout C defaults to the LTVera sample when opened directly.
