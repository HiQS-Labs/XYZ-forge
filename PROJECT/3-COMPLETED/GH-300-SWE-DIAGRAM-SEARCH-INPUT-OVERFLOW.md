---
gh_issue: 300
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/300
title: "swe-diagram: search input grows and overflows past canvas edge when typing (WebKit)"
status: "SHIPPED — fixed 2026-07-23, pending operator confirmation in Safari."
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
| Root-caused and fixed: `.swe-search-input` (`utils/swe-diagram/assets/template.html`) uses `type="search"` but never reset `-webkit-appearance`, so WebKit's native searchfield decoration (reserved space for its own cancel button once text is present) can override the explicit CSS width under `box-sizing: border-box`. Added `-webkit-appearance: none; appearance: none;` plus explicit `::-webkit-search-cancel-button`/`::-webkit-search-decoration` resets; rebuilt every `ARCHITECTURE/*.html` output. | Operator to confirm in an actual Safari window — this environment has no Safari automation, so the fix was verified for no-regression in headless Chrome only (Chrome doesn't reproduce the underlying bug). |

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
