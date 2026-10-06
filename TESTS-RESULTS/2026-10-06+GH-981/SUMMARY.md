# GH-981 spike verification

The synthetic dashboard is usable for operator visual review. Optional demo/live boundaries and existing fixture/manual checks passed. Independent final QA and the required full gate follow this checkpoint; no merge readiness is claimed.

- Browser: desktop, 430 CSS-pixel compact container, dark and collapsed screenshots; filters, keyboard row selection, Escape, selectable handoff, empty/stale/partial/failure/hostile scenarios inspected through native Safari. Compact preview is not device emulation. Retained screenshots use synthetic records in a separate window, avoiding other open task tabs.
- Observed red keyboard control: selection originally moved focus to the document after a full render. The renderer now restores focus to the matching generated control; Option-Tab/Return was rechecked and retained row focus. Expiry recomputation keeps the handoff textarea present.
- HTTP manual boundary: demo snapshot GET forbidden, asset allowlist nonempty, traversal/foreign Host rejected, loopback-only bind and shared CSP/no-store headers passed. Explicit live fixture snapshot was nonempty; source files stayed byte-identical. Forced aggregator exception returned 503. The source-immutability assertion failed after deliberately changing a disposable fixture, then passed when the original bytes were restored.
- Existing `python3 -m src.flightdeck.manual_harness --check`: passed, including its negative controls and source immutability assertions.
- Existing `python3 -m pytest -q test/flightdeck`: **34 passed, 5 failed**. All failures reach unchanged `utils/py/releases_cycle.py` and its `os.waitid` call; this Darwin Python3.9.6 has no `os.waitid`. It is a pre-existing implementation/environment incompatibility, not a green focused suite. The add-on renderer and its bounded fixture path are verified separately. No gate or tests were weakened.
- PDDA frontmatter/status-table/roadmap-coverage: zero errors/warnings at checkpoint. The route classifier selects **tier 3** for the unmapped optional launcher; no mapping was added.
- Existing core Flightdeck source/UI files and dependency/startup files remain unchanged. Upstream MIT notice is byte-identical.

The one-off boundary probe lived under ignored `temp/`; it is not a new suite or gate. Its output is retained, including the deliberate failure trace. Public evidence contains no live prompt/task records. Machine-specific checkout prefixes in command logs are replaced with `$GATE_CLONE`.

Merge decision remains keep/revise/abandon after viewing. Outstanding: final peer QA, qualifying gate and PR publication/status.
