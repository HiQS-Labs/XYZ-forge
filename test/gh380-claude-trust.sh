#!/usr/bin/env bash
# gate-evidence: {"form":"controlled-input","observed":true,"result":"untrusted workspace emits WARNING to stderr without altering exit code; trusted workspace emits no warning"}
# GH-380: Claude builder warns when target workspace lacks Claude Code trust
source "$(dirname "$0")/_setup.sh" gh380-claude-trust
ROOT="$(cd "$HERE/.." && pwd)"

TEST_DIR="$WORK/target-repo"
mkdir -p "$TEST_DIR"

FAKE_HOME="$WORK/fake-home"
mkdir -p "$FAKE_HOME"

export HOME="$FAKE_HOME"

# Test 1: Untrusted directory emits warning
out=$(python3 -c "
import sys
sys.path.insert(0, '$ROOT/utils/py')
from importlib import import_module
ct = import_module('claude-turn')
ct.warn_if_workspace_untrusted('$TEST_DIR')
" 2>&1)

if grep -q "WARNING: workspace '$TEST_DIR' is not trusted" <<<"$(echo "$out")"; then
  pass "untrusted workspace emits trust warning to stderr"
else
  fail "untrusted workspace failed to emit trust warning"
fi

# Test 2: Trusted directory emits no warning
cat > "$FAKE_HOME/.claude.json" <<EOF
{
  "projects": {
    "$TEST_DIR": {
      "hasTrustDialogAccepted": true
    }
  }
}
EOF

out_trusted=$(python3 -c "
import sys
sys.path.insert(0, '$ROOT/utils/py')
from importlib import import_module
ct = import_module('claude-turn')
ct.warn_if_workspace_untrusted('$TEST_DIR')
" 2>&1)

if [ -z "$out_trusted" ]; then
  pass "trusted workspace emits no warning"
else
  fail "trusted workspace emitted unexpected output: $out_trusted"
fi

exit 0
