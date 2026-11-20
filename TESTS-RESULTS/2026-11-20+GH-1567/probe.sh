#!/usr/bin/env bash
# GH-1567 manual red-control + smoke probe (not a test suite; GH-831). Usage: probe.sh <task-clone> <base-sha>
# Builds a BASE clone (origin/development) and a FIXED clone (task HEAD) as canonical-looking XYZ-forge clones in a
# temp dir, then drives the scanner (copied OUTSIDE harness ancestry) and find-harness.sh --check from a vendored repo.
set -u
TASK="$1"; BASE="$2"
T="$(mktemp -d "${TMPDIR:-/tmp}/gh1567-probe.XXXXXX")"; [ -d "$T" ] || exit 1
echo "probe dir: $T"
CANON=https://github.com/HiQS-Labs/XYZ-forge.git
for v in base fixed; do
  mkdir -p "$T/$v"; git clone -q --no-local "$TASK" "$T/$v/XYZ-forge" && git -C "$T/$v/XYZ-forge" remote set-url origin "$CANON"
done
git -C "$T/base/XYZ-forge" checkout -q "$BASE"
git -C "$T/fixed/XYZ-forge" checkout -q "$(git -C "$TASK" rev-parse HEAD)"
echo "base=$(git -C "$T/base/XYZ-forge" rev-parse --short HEAD) fixed=$(git -C "$T/fixed/XYZ-forge" rev-parse --short HEAD)"
# scanner copies live outside any harness ancestry (so the own-ancestor bin/tick lookup finds nothing)
for v in base fixed; do mkdir -p "$T/scan-$v"; cp "$T/$v/XYZ-forge"/skills/2-daily/merge-cleanup/scripts/*.py "$T/scan-$v/"; done
# audited repo: a .tick/ dir, no locks
A="$T/audited"; mkdir -p "$A/.tick/events"; git -C "$A" init -q
mkdir -p "$T/home" "$T/cfg" "$T/emptybin" "$T/nodebin"
ln -s "$(command -v node)" "$T/nodebin/node"   # tick is a node script; PATH still has no `tick`
scan() { # <variant> <label>
  env -i HOME="$T/home" XDG_CONFIG_HOME="$T/cfg" PATH="$T/emptybin:/usr/bin:/bin" "$(command -v python3)" -I - "$T/scan-$1" "$A" <<'PY'
import sys, pathlib
sys.path.insert(0, sys.argv[1])
import scan_clones as sc
print("  _tick_binary():", sc._tick_binary())
r = sc.inspect_tick_claims(pathlib.Path(sys.argv[2]))
print("  inspect_tick_claims:", r)
d = r["details"]
print("  names remedy (~/.config/xyz/harness + XYZ_HARNESS):", "~/.config/xyz/harness" in d and "XYZ_HARNESS" in d, "| verified:", r["verified"])
PY
}
echo "== A. scanner, no config (RED control on base; fixed must name the remedy and stay verified=False) =="
echo "-- base"; scan base; echo "-- fixed"; scan fixed
# vendored consumer repo
V="$T/vrepo"; mkdir -p "$V/.xyz/relay-automation" "$V/.xyz/bin"; git -C "$V" init -q
printf '#!/bin/sh\n' > "$V/.xyz/relay-automation/relay-drive.sh"; chmod +x "$V/.xyz/relay-automation/relay-drive.sh"
printf '#!/bin/sh\nexit 0\n' > "$V/.xyz/bin/tick"; chmod +x "$V/.xyz/bin/tick"
check() { (cd "$V" && env -i HOME="$T/home" XDG_CONFIG_HOME="$T/cfg" PATH=/usr/bin:/bin bash "$T/$1/XYZ-forge/skills/1-hourly/relay-xyz/find-harness.sh" --check 2>&1 | grep -v 'CLI\|case-collision'); echo "  exit=$?"; }
echo "== B. find-harness --check from a vendored repo, no config =="
echo "-- base"; check base; echo "-- fixed"; out="$(check fixed)"; echo "$out"
hint="$(printf '%s\n' "$out" | sed -n 's/^  save this harness on this Mac: //p')"
echo "== C. run the printed save command under the isolated config; assert saved bytes; config supplies scanner resolution =="
echo "  hint: $hint"
[ -n "$hint" ] && env HOME="$T/home" XDG_CONFIG_HOME="$T/cfg" bash -c "$hint"
echo "  saved: $(cat "$T/cfg/xyz/harness" 2>/dev/null)  expected: $T/fixed/XYZ-forge"
echo "  --check after save:"; check fixed
echo "  fixed scanner after save (bin/tick resolved via config; fixed clone has bin/tick):"
env -i HOME="$T/home" XDG_CONFIG_HOME="$T/cfg" PATH="$T/nodebin:/usr/bin:/bin" "$(command -v python3)" -I - "$T/scan-fixed" "$A" "$(cd -P "$T/fixed/XYZ-forge" && pwd)/bin/tick" <<'PY'
import sys, pathlib
sys.path.insert(0, sys.argv[1]); import scan_clones as sc
t = sc._tick_binary(); print("  _tick_binary():", t, "| equals saved harness tick:", t == sys.argv[3])
r = sc.inspect_tick_claims(pathlib.Path(sys.argv[2])); print("  inspect_tick_claims:", r)
PY
echo "== D. adjacent: invalid config content, then no canonical live harness (copied script outside any clone) =="
printf '/missing/XYZ-forge\n' > "$T/cfg/xyz/harness"; echo "-- invalid config"; check fixed
rm -f "$T/cfg/xyz/harness"
mkdir -p "$T/copied"; cp "$T/fixed/XYZ-forge/skills/1-hourly/relay-xyz/find-harness.sh" "$T/copied/"
echo "-- copied script, no live harness reachable"
(cd "$V" && env -i HOME="$T/home" XDG_CONFIG_HOME="$T/cfg" PATH=/usr/bin:/bin bash "$T/copied/find-harness.sh" --check 2>&1 | grep -v 'CLI'); echo "  exit=$?"
echo "probe dir kept: $T"
