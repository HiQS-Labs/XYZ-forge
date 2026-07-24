---
gh_issue: 300
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/300
title: "swe-diagram: search input grows and overflows past canvas edge when typing (WebKit)"
status: "SHIPPED — two distinct root causes fixed 2026-07-23; the first (WebKit appearance) still pending operator confirmation in Safari, the second (picker staleness) verified quantitatively."
created: 2026-07-23
updated: 2026-07-23
owner: unassigned
doc_type: bugfix
goal: >
  Stop the swe-diagram search input from growing past its declared 180px width and overflowing
  past the canvas edge on WebKit browsers when text is typed into it.
---

# GH-300 · swe-diagram search input overflow (WebKit)

## Status
| What was just completed | What's next |
|---|---|
| **Two distinct bugs fixed, same symptom family.** (1) WebKit `-webkit-appearance` reset (see below) — verified no-regression in Chrome only. (2) **Operator re-reported after (1) shipped**: the search box still visibly touched the font-picker dropdown on first keystroke, no resize needed to trigger it — a second, browser-agnostic bug (font-picker position going stale), root-caused and fixed, verified quantitatively via headless-Chrome bounding-rect measurement (not just a screenshot): gap was a constant 8px before typing, went to -22px (overlap) immediately after typing with the WebKit fix alone, and is now a constant 8px with both fixes applied. | Operator to confirm bug (1) — the WebKit appearance reset — in an actual Safari window; bug (2) is confirmed fixed by direct measurement, browser-independent. |

## Bug
Reported live by the operator against `ARCHITECTURE/system-diagram.html`, opened in the IDE:
typing into the top-right search box ("Filter nodes...") visibly grows the field wider than its
180px CSS width and clips it past `.swe-canvas`'s `overflow: hidden` edge.

## Root cause
`searchInput.type = 'search'` (`utils/swe-diagram/assets/renderer.js`) opts the field into
WebKit's native `-webkit-appearance: searchfield` rendering. That native chrome reserves
intrinsic space for its own cancel-button decoration once the field has text, which can win over
an explicit CSS `width`. The renderer already ships its own custom `.swe-search-clear` "×"
button (`swe-search-active` toggles its visibility), so the native decoration was pure downside —
duplicated affordance plus the overflow bug.

## Fix
`utils/swe-diagram/assets/template.html`: added `-webkit-appearance: none; appearance: none;` to
`.swe-search-input`, and explicitly zeroed out `::-webkit-search-cancel-button` /
`::-webkit-search-decoration`. Rebuilt every generated `ARCHITECTURE/*.html` via
`build-diagram.sh` (the fix lives in the template, inlined at build time — each output needed
regenerating).

## Verification
- `test/swe-diagram.sh` 42/42 (CSS-only change, no layout-function coupling).
- Headless-Chrome regression check: injected a script that focuses the search input, sets its
  value, and dispatches an `input` event, then screenshotted — field stays at 180px, custom clear
  button shows, filtering still dims non-matching nodes correctly. Chrome does not exhibit the
  underlying WebKit bug, so this proves no regression there, not that the fix works in Safari.
- **Not verified:** an actual Safari re-test of the original repro. The fix is the standard,
  well-documented idiom for this exact class of WebKit `input[type=search]` quirk, but is flagged
  here rather than claimed as confirmed.

## Bug 2 (found on re-report): font-picker dropdown touches the search box on first keystroke

The operator re-reported after Bug 1 shipped: the search box still visibly touches/overlaps the
`Default` font-picker dropdown immediately on the first character typed — no resize needed — but
resizing the window afterward fixes it. That "resize fixes it" detail was the key clue.

### Root cause
`positionPicker()` (`utils/swe-diagram/assets/template.html`) sets the picker's `right` offset from
`.swe-search`'s current `offsetWidth`, but only runs on page load, font-picker `change`, and
`window` `resize`. It never runs on the search box's own `input` event. `.swe-search` is a
right-anchored flex row (`position: absolute; right: 16px`) containing the input plus a custom
clear button (`.swe-search-clear`) that's `display: none` until the box has text
(`.swe-search-active` class). Typing a character makes the clear button appear, growing
`.swe-search`'s rendered width — and because it's right-anchored, that growth extends the box
**leftward**, toward the picker, which never gets told to move. A window resize incidentally fires
the resize listener, which recomputes the picker's position from the *now-current* (already grown)
search width — correctly relocating it and masking the bug, which is exactly the behavior
reported.

Quantified via headless-Chrome bounding-rect measurement (`window.dispatchEvent` a synthetic
`input` event, read `getBoundingClientRect()` before/after):

| State | search.left | picker.right | gap |
|---|---|---|---|
| Before typing | 1004 | 996 | 8px (healthy) |
| After typing, no resize | 974 | 996 | **-22px (overlap)** |
| After typing + synthetic resize | 974 | 966 | 8px (restored) |

### Fix
`utils/swe-diagram/assets/renderer.js`: the search `input` handler and the clear button's `click`
handler (the two places that toggle `swe-search-active`) now also dispatch a
`swe-search-resize` `CustomEvent` on `mount` (the persistent `#diagram` node — not wiped by a
font-swap re-render, unlike its children). `template.html` listens for that event and calls
`positionPicker()`, alongside the existing load/change/resize triggers. This keeps
`renderer.js` and the font-picker script decoupled (the renderer has no knowledge the picker
exists; it only announces "my search UI's width may have changed").

### Verification
- Re-ran the same bounding-rect measurement after the fix: gap is a constant 8px both before and
  after typing, with **no resize needed** — matches the operator's exact repro path.
- `test/swe-diagram.sh` 42/42.
- Visual screenshot confirms a clean gap between the picker and search box on first keystroke.
- This fix is plain DOM sizing/event logic, not a WebKit-specific quirk — the Chrome verification
  here is a direct, browser-independent confirmation, unlike Bug 1's fix.

### Tooling note
The operator asked to debug this via Playwright in `~/bin/ai-ddtk`. That path doesn't exist;
`~/Documents/GitHub-Repos/AI-DDTK-Fix-Iterate-Loop` is presumably what was meant, but its
Playwright tooling (`bin/pw-auth`) is WordPress-auth-focused, and Playwright itself isn't actually
installed there (or globally) — using it would have meant a fresh `npm install` plus a browser
download. Used the existing headless-Chrome harness from GH-299 instead (already proven, zero new
dependencies), which was sufficient to root-cause and numerically verify both bugs above.
