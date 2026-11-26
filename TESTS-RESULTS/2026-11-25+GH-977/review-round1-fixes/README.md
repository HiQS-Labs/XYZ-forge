# Codex round-1 findings F1, F3: controls (2026-11-25)

Run in the disposable verify clone against `e331a4d98` (probe-hardened), python3.12, no network.

- F1 falsifiers (`probe-977-f1-refuse.txt`, `probe-977-f1-noop.txt`): an update that refuses, and one that exits 0 without persisting, both read unfixed (probe exit 1). `probe-977-simfix.txt` (exit 0) is the real preserve shape; `probe-977-comment.txt` (exit 1) a comment-only edit.
- F3 (`f3_clone_probe.py`, the reviewer's offline-connector probe with the probe path parameterised via `PROBE_REL`): the pre-hardening probe (commit `b1539feb1`) produced 2 connector events for issue 977 (`f3-temp-old_probe_977.py.txt`: escape reproduced); the hardened probe produced 0 (`f3-2026-11-25+GH-977-readiness_probe.py.txt`). On this machine `github_board` is `enabled: false` in the real device config, so no board call ever happened from the earlier runs.
