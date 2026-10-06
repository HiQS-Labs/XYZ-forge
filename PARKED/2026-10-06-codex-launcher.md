# Local Codex launcher points to an obsolete binary

Observed during GH-981 plan QA: the installed shell launcher exits 126 because its target under the desktop application bundle no longer exists. The installed `codex-cli/bin/codex` binary works (`codex-cli 0.160.0`). The review succeeded using the harness's per-run `CODEX_BIN` override.

This is device installation maintenance outside the dashboard spike; no launcher or harness changes were made. Next check: compare the installed launcher with the desktop app's current supported CLI installation route before replacing it. Evidence: the dated GH-981 plan receipt records successful review after the local override; reproduction captured under task temp/gh981/review-launch.txt.
