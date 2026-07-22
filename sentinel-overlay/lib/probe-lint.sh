#!/usr/bin/env bash
# probe-lint.sh — deterministic gate: every fix_probe in a Swarm Preflight Contract must CURRENTLY
# detect the bug (polarity: bug present / fix not landed) before a Gemma-drafted doc may leave 1-INBOX.
# No network, no LLM. Mirrors the GH-239 probe polarity that swarm-preflight enforces downstream.
set -u

# sentinel_probe_lint <contract.json> [<root>]  -> 0 if all probes detect the bug, else 1 (2 on usage)
sentinel_probe_lint() {
  local contract="$1" root="${2:-.}"
  [ -f "$contract" ] || { echo "probe-lint: contract not found: $contract" >&2; return 2; }
  command -v python3 >/dev/null 2>&1 || { echo "probe-lint: python3 required" >&2; return 2; }
  python3 - "$contract" "$root" <<'PY'
import json, os, subprocess, sys
contract, root = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(contract))
except Exception as e:
    print(f"probe-lint: invalid contract JSON: {e}", file=sys.stderr); sys.exit(2)
probes = data.get("fix_probes", [])
if not probes:
    print("probe-lint: no fix_probes to lint", file=sys.stderr); sys.exit(1)
bad = 0
for p in probes:
    t = p.get("type"); path = p.get("path", ""); pat = p.get("pattern", "")
    ap = os.path.join(root, path) if path else None
    detects = False
    if t == "path_absent":      detects = not os.path.exists(ap)
    elif t == "path_present":   detects = os.path.exists(ap)
    elif t == "grep_absent":    detects = (not os.path.exists(ap)) or (pat not in open(ap, errors="ignore").read())
    elif t == "grep_present":   detects = os.path.exists(ap) and (pat in open(ap, errors="ignore").read())
    elif t == "command":
        rc = subprocess.run(["bash", "-c", p.get("command", "false")], cwd=root).returncode
        detects = (rc != 0)     # command probe: nonzero exit == bug still present
    else:
        print(f"probe-lint: unknown probe type: {t}", file=sys.stderr); bad += 1; continue
    if not detects:
        print(f"probe-lint: probe does NOT detect the bug (inverted polarity / already fixed?): {p}", file=sys.stderr)
        bad += 1
sys.exit(1 if bad else 0)
PY
}
