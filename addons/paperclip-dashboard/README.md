# Optional Paperclip-inspired dashboard

A standalone, read-only visual spike for XYZ Forge. It does not start automatically and adds no build dependencies. See [ATTRIBUTION.md](ATTRIBUTION.md) for the pinned source and borrowing record.

## Implementation provenance

This is a Paperclip-inspired, independently authored implementation: visual review and upstream source inspection informed the layout, navigation, metric cards, filtering and activity patterns. No Paperclip implementation code was copied or imported. The add-on code was authored for XYZ Forge and reuses existing XYZ Flightdeck data/status modules; the upstream MIT license notice is retained verbatim.

“Partial clean-room” can describe the intent informally—borrow presentation ideas and write custom code—but this spike did not use a formal clean-room process: the implementer inspected upstream source, and there was no separation between source reviewers and implementers. We therefore describe it as independently authored, pattern-inspired code rather than claim clean-room provenance. The pinned references and attribution remain documented in [ATTRIBUTION.md](ATTRIBUTION.md).

From the repository root:

```sh
python3 addons/paperclip-dashboard/preview.py
```

Open **http://127.0.0.1:8769/**. The default is a labelled synthetic demo; it does not configure or invoke local source readers. Stop with Ctrl-C. Use `--port 8771` if that port is occupied.

To opt in to the existing local Flightdeck projection:

```sh
python3 addons/paperclip-dashboard/preview.py --live
```

Live mode uses the existing `FLIGHTDECK_*` configuration and aggregator. See [Flightdeck setup](../../web/flightdeck/README.md). It binds only to `127.0.0.1`; there is no tunnel, public host option or producer write endpoint. Live data stays in browser memory and is never persisted by the add-on. Browser storage contains only theme/sidebar preferences.

Use repository buttons, Work/Lanes/Pull requests views and the text filter to explore. Select a row to inspect evidence context. Prepare handoff reveals selectable text without copying automatically or sending anything. Escape clears the text filter and selection. Appearance and sidebar controls are local preferences.

For visual/manual review, the synthetic demo accepts `?scenario=empty`, `stale`, `failure`, `partial` or `hostile`. `?compact=1` uses a 430 CSS-pixel container and the same responsive rules as a narrow window; it is a compact-layout preview, not device emulation. `?mode=demo` explicitly selects synthetic records even on a live server. Scenario parameters are ignored in live data mode.

Snapshots expire after five minutes; recorded facts remain visible while work status becomes unverified. Reads poll every 150 seconds, time out after 15 seconds and pause after three consecutive failures. Read latest retries manually. All counts describe displayed observations within source coverage. Agent observations do not establish running processes, progress is unmeasured, and every PR requires current-head verification.

This is an evaluation renderer, not a migration of Paperclip's application. It borrows the navigation/card/activity patterns and leaves Paperclip's company model, task writers, agent runtime, billing and control APIs behind. The existing Flightdeck remains the baseline. Decide keep/revise/abandon after viewing the spike; no merge is implied.
