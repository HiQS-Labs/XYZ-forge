#!/usr/bin/env bash
# GH-1270 init and packet controls. Run from the -verify clone root (disposable).
set -u
export PYTHONDONTWRITEBYTECODE=1
H="python3 utils/py/harness.py factory-primitive"

# Delivered-but-open at init: a gh shim reports one merged PR that closes a seeded candidate.
REAL_GH="$(command -v gh)"
SHIM="$(mktemp -d)"
TARGET=$(python3 -c "import json;m=json.load(open('temp/factory-primitive/pilot-2c/instances/C/backlog/manifest.json'));print(sorted(m['requests'].values(),key=lambda q:q['slot'])[0]['issue'])")
cat > "$SHIM/gh" <<SH
#!/usr/bin/env bash
if [ "\$1 \$2" = "pr list" ]; then echo '[{"number":99999,"title":"control","body":"Closes #$TARGET"}]'; exit 0; fi
exec "$REAL_GH" "\$@"
SH
chmod +x "$SHIM/gh"
rm -rf temp/factory-primitive/ctl-delivered
PATH="$SHIM:$PATH" $H --run-root temp/factory-primitive/ctl-delivered init --from-prs --limit 3 >/dev/null
echo "CONTROL delivered-at-init | target #$TARGET excluded=$(python3 -c "import json;m=json.load(open('temp/factory-primitive/ctl-delivered/instances/C/backlog/manifest.json'));print([e for e in m['excluded'] if e['issue']==$TARGET])")"
rm -rf "$SHIM"

# Packet refuses a proposal written by a failed (uncertain) tick; a clean run emits.
R=temp/factory-primitive/ctl-packet
rm -rf $R
$H --run-root $R init --from-prs --limit 2 >/dev/null
echo "CONTROL tick1 | $($H --run-root $R tick --slot 1)"
echo "CONTROL packet-after-clean-tick | $($H --run-root $R packet --wave 1 2>&1 | cut -c1-160)"
echo "CONTROL tick2-fail-after-output | $($H --run-root $R tick --slot 2 --fault fail-after-output)"
out="$($H --run-root $R packet --wave 1 2>&1)"; rc=$?
echo "CONTROL packet-after-uncertain-tick | rc=$rc | $(printf %s "$out" | tail -1 | cut -c1-200)"
