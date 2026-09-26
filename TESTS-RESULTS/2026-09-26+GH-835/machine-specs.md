# Machine specs — GH-835 full-gate re-measure (2026-09-26)

Agent / model ID: ZCode on GLM-5.3-Flash Max (user-directed addition to the spec record)

| Item | Value |
|---|---|
| Model name | Mac Studio |
| Model identifier | Mac13,1 |
| Chip | Apple M1 Max (arm64) |
| CPU cores | 10 (8 performance + 2 efficiency) |
| Gate width auto-picked | 4 (cores/2 = 5, capped at 4 — GH-35 balanced default) |
| Memory | 64 GB |
| Disk | 926 GB APFS volume (86 GiB free at run start) |
| macOS | 15.6.1 (Build 24G90) |
| Kernel | darwin 24.6.0 |
| Python (gate) | 3.14.7 (/opt/homebrew/bin/python3, requests/yaml/pytest importable) |
| php | 8.3.29 (/opt/homebrew/bin/php, as in the prior GH-831 runs) |
| bash | 3.2.57 (system) |

Both full-gate runs on 2026-09-26 (see provenance.jsonl) ran on this device.
