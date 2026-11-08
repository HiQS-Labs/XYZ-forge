#!/usr/bin/env bash
# GH-1261 init controls: list failure with N>0, no list call with N=0, and --unregistered 0 candidate-set
# parity with the Phase 2A base (b1dd41a8). Run from the -verify clone root (disposable).
set -u
export PYTHONDONTWRITEBYTECODE=1
REAL_GH="$(command -v gh)"
SHIM="$(mktemp -d)"
cat > "$SHIM/gh" <<SH
#!/usr/bin/env bash
echo "gh \$*" >> "$SHIM/calls.log"
[ "\$1 \$2" = "issue list" ] && { echo "shim: list refused" >&2; exit 1; }
exec "$REAL_GH" "\$@"
SH
chmod +x "$SHIM/gh"
run() { PATH="$SHIM:$PATH" python3 utils/py/harness.py factory-primitive --run-root "temp/factory-primitive/$1" init --from-prs --limit 10 "${@:2}"; }
out="$(run ctl-n1 --unregistered 1 2>&1)"; rc=$?
echo "CONTROL list-fails-N1 | rc=$rc state.db=$([ -f temp/factory-primitive/ctl-n1/instances/C/state.db ] && echo present || echo absent) | $(printf %s "$out" | tail -1 | cut -c1-80)"
: > "$SHIM/calls.log"
run ctl-n0 --unregistered 0 >/dev/null 2>&1; echo "CONTROL n0-rc | rc=$?"
echo "CONTROL n0-list-calls | $(grep -c 'issue list' "$SHIM/calls.log")"
git show b1dd41a8:utils/py/harness.py > utils/py/_base_harness_gh1261.py
PATH="$SHIM:$PATH" python3 utils/py/_base_harness_gh1261.py factory-primitive --run-root temp/factory-primitive/ctl-base init --from-prs --limit 10 >/dev/null 2>&1
rm -f utils/py/_base_harness_gh1261.py
order() { python3 -c "import json,sys; m=json.load(open(sys.argv[1])); print([q['issue'] for q in sorted(m['requests'].values(), key=lambda q: q['slot'])])" "$1"; }
B=temp/factory-primitive/ctl-base/instances/C/backlog/manifest.json
N=temp/factory-primitive/ctl-n0/instances/C/backlog/manifest.json
if [ -f "$B" ]; then
  echo "CONTROL parity-base | $(order $B)"
  echo "CONTROL parity-n0   | $(order $N)"
  [ "$(order $B)" = "$(order $N)" ] && echo "CONTROL parity | identical" || echo "CONTROL parity | DIFFERENT"
else
  echo "CONTROL parity | base run did not produce a manifest"
fi
rm -rf "$SHIM"
