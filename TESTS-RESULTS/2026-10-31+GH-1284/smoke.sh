#!/bin/bash
# Manual evidence for GH-1284. Usage: smoke.sh <disposable *-verify clone>. Runs nothing elsewhere.
set -u
CLONE=$(cd "${1:?usage: smoke.sh <disposable *-verify clone>}" && pwd -P) || exit 2
case "$CLONE" in *-verify) ;; *) echo "refused: $CLONE is not a disposable *-verify clone" >&2; exit 2 ;; esac
[ -f "$CLONE/utils/py/harness.py" ] || { echo "refused: no utils/py/harness.py in $CLONE" >&2; exit 2; }
cd "$CLONE" || exit 2
RT="$CLONE/temp/factory-primitive"
clean(){ case "$RT" in "$CLONE"/temp/factory-primitive) rm -rf "$RT" ;; *) echo "refused cleanup: $RT" >&2; exit 2 ;; esac; }
clean
db(){ [ -f "temp/factory-primitive/$1/instances/C/state.db" ] && echo "  state.db after: yes" || echo "  state.db after: no"; }
run(){ echo "\$ factory-primitive $*"; python3 utils/py/harness.py factory-primitive "$@" >"$TMPDIR/o" 2>"$TMPDIR/e"; rc=$?; echo "  rc=$rc $(tail -c 160 "$TMPDIR/e" | tr '\n' ' ')$(head -c 100 "$TMPDIR/o" | tr '\n' ' ')"; }
echo "# patched harness sha256: $(shasum -a 256 utils/py/harness.py | cut -c1-16)"
echo "## main path (GH-1280 D1 sequence)"
run --run-root temp/factory-primitive/m1 status; db m1
run --run-root temp/factory-primitive/m1 init --daily-cap 1 --max-call-cost 0
run --run-root temp/factory-primitive/m1 status
run --run-root temp/factory-primitive/m1 tick --slot 1
echo "## adjacent: tick or packet first on a fresh root, then init"
run --run-root temp/factory-primitive/a1 tick --slot 1; db a1
run --run-root temp/factory-primitive/a2 packet --wave 1 --reviewer codex; db a2
run --run-root temp/factory-primitive/a1 init --daily-cap 1 --max-call-cost 0
echo "## rerun: tick same slot again on initialized root"
run --run-root temp/factory-primitive/m1 tick --slot 1
echo "## red control: unpatched harness (origin/development)"
cp utils/py/harness.py "$TMPDIR/patched.py"; git show origin/development:utils/py/harness.py > utils/py/harness.py
run --run-root temp/factory-primitive/r1 status; db r1
run --run-root temp/factory-primitive/r1 init --daily-cap 1 --max-call-cost 0
cp "$TMPDIR/patched.py" utils/py/harness.py
clean
