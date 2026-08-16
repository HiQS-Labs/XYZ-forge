#!/usr/bin/env bash
#
# xyz-vendor-reminder.sh — non-blocking reminder that vendored .xyz/ harness copies
# (GH-49) still exist, so they don't rot silently. Reads the machine-local install
# registry and, if any *vendored* copy is still on disk, prints a short heads-up.
#
# Wiring (.claude/settings.json) — SessionStart is the channel whose stdout Claude Code
# injects as visible context, so the reminder is actually seen (a SessionEnd hook's output
# is not surfaced live). "After the session is done" therefore surfaces at the START of the
# next session — which is exactly when cleaning up a leftover copy is actionable:
#   "hooks": { "SessionStart": [ { "hooks": [ { "type": "command",
#     "command": "bash relay-automation/hooks/xyz-vendor-reminder.sh" } ] } ] }
# For cross-repo coverage, copy that one-liner into ~/.claude/settings.json too (the registry
# is global; this repo's settings only fire when Claude Code is opened in the harness clone).
#
# Contract:
#   - ALWAYS non-blocking: exit 0, never deletes anything, never asks-then-acts. It only
#     surfaces the fact + the exact xyz-sync remedy; the operator decides (GUIDING #8).
#   - Silent unless at least one vendored .xyz/ copy exists ON DISK (a pruned/moved copy
#     doesn't nag). Opt out entirely with XYZ_NO_VENDOR_REMINDER=1.
#   - Registry is the GH-62 ~/.config/xyz/registry.tsv (override $XYZ_REGISTRY); a vendored
#     row is one whose install_dir basename is ".xyz" (written by xyz-vendor.sh).
#   - Fail-open: any parse/read error → silent exit 0. Reads (and discards) stdin so an
#     event payload on stdin never breaks the pipe.
set -u

# Consume any hook-event JSON on stdin (we don't need its fields); never block on it.
cat >/dev/null 2>&1 || true

[ -n "${XYZ_NO_VENDOR_REMINDER:-}" ] && exit 0

REG="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"
[ -f "$REG" ] || exit 0

# Emit the on-disk vendored .xyz/ paths (tab col 1, basename == .xyz, dir exists). awk splits
# the path itself; -F '\t' keeps embedded spaces intact.
present="$(awk -F '\t' '
  /^#/ { next }
  NF == 0 { next }
  {
    dir = $1
    n = split(dir, parts, "/")
    if (parts[n] == ".xyz") print dir
  }
' "$REG" 2>/dev/null | while IFS= read -r d; do [ -d "$d" ] && printf '%s\n' "$d"; done)"

[ -n "$present" ] || exit 0

count="$(printf '%s\n' "$present" | grep -c .)"
noun="copy"; [ "$count" -gt 1 ] && noun="copies"

{
  printf 'xyz-vendor reminder — %s vendored .xyz/ harness %s still on disk:\n' "$count" "$noun"
  printf '%s\n' "$present" | sed 's/^/  • /'
  printf 'Review: relay-automation/xyz-sync.sh list   ·   Remove: relay-automation/xyz-sync.sh delete <dir> --yes\n'
  printf '(GH-49 vendored fallbacks are opt-in; silence this with XYZ_NO_VENDOR_REMINDER=1.)\n'
}

exit 0
