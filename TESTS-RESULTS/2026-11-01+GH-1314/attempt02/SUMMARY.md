# Attempt 02 — historical status/init calibration matched both controls

The reviewed correction completed in **12.14999794960022 seconds** of the 600-second
setup-through-result envelope. Launcher and helper exited 0. Eight candidate CLI
invocations were captured once, with no timeout, forced kill or observed surviving
owned group. No inconclusive artifact exists. Independent local inspection checked
raw outputs, hashes, inventories, config/canary/telemetry and reversed fresh-root replay.
Independent parent acceptance remains pending; this is narrow historical evidence.

| Sequence | Bad status / init | Good status / init |
|---|---|---|
| r1 (bad then good) | status rc 0 creates DB; init rc 2 refuses | status rc 2 creates nothing; init rc 0 succeeds |
| r2 (good then bad) | same defect reproduced | same correct behavior reproduced |

Bad init stderr: `factory-primitive: instance already initialized; use a new run root`.
Good status stderr: `factory-primitive: instance not initialized; run init first`.
All success stderr and refusal stdout streams were empty as specified. Good init
reports initialized with the correct instance path, config caps 1/0, matching fixture
identities, canary bytes `do-not-modify\n`, and init/ok telemetry for 27 scenario items.

Both HOME and TMPDIR remained empty. Across every command, inactive candidate and Git
metadata inventories were unchanged. Runtime changes were confined to the declared
run-root directories, DB/SQLite sidecars and successful-init files; refusal/read steps
on the fixed status and bad init changed nothing. No tick, actor repair, provider/model
call, new CI case, workflow or full suite. Spend: $0. Shutdown escalation was not exercised.

## Proven setup correction

The original setup used `/usr/bin/git` under candidate TMPDIR. Isolated diagnostic
`/usr/bin/git --version` created a 491-byte xcrun_db with the exact original SHA-256
`4d62589acad172d2e1d4c689d2fb2a0c7381614fdf5df35a8bb7cc8fd51b1f64`.
Direct CLT Git produced the same version and no files. Python shim likewise creates
its discovery cache, while the resolved Python control leaves TMPDIR empty. The
correction uses direct binaries and a separate retained setup scratch, then creates
new candidate HOME/TMPDIR after setup. No file was allowlisted or erased.

## Provenance and retained proof

`helper.txt` is exact approved helper 4250cb90eff905f851b5cc6d18f3b7c7932f68058e0470846eaedb8f5657d753.
`launcher.txt` is exact corrected/frozen launcher 8fbefd93a70dd2341b73a2a6e840e5962bcaec4e168c13b46c6a27efdfee3847.
Raw protocol hash: 2dff5b6d5505b182cd4ed51e32a2be87c24534382deea3b9aea066a1bfb9370f.
Parent conditional approval and shutdown correction are recorded in launch config
before observations. Python 3.9 interpreter and SQLite 3.54.0 identities plus Git binary
hash are recorded. Source/fixture hashes are in identity.sanitized.json.

All raw output/state receipts are retained locally. Published argv/output/config paths
are labeled placeholders. RAW-EVIDENCE-SHA256.json binds originals; SHA256SUMS.json binds
published derivatives. The deterministic gzip retains ALL 16 sanitized before/after inventories as one
complete baseline plus ordered lossless deltas, avoiding roughly 55 MB of redundant
snapshots. Every snapshot was independently reconstructed equal to its original parsed
JSON. Decompress as JSON: first baseline initializes each area, then each delta removes
listed paths and updates set paths. Per-snapshot canonical hashes verify reconstruction.
independent-inspection.json provides the small changed-path table for review.

## Limits

This distinguishes the two fixed historical revisions only. It does not implement
actor repair, immutable oracle permissions or generalized semantic verification.
Same-user controls are supervised; inventories cover declared paths only, and process
groups do not establish global descendant containment. Blocking I/O can delay deadline
observation. No forced shutdown occurred, so graceful/fallback cleanup is unproven here.
Attempt 01 remains immutable and inconclusive; it is not relabeled or hidden.
