#!/usr/bin/env bash
set -uo pipefail
HARNESS="/Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-followup"
W="$(mktemp -d /tmp/p5-vendored.XXXXXX)"
CON="$W/consumer"; FCW="$W/foreign-cwd"; AG="$W/agents"; SB="$W/stub-bin"
mkdir -p "$CON" "$FCW" "$AG" "$SB"

# consumer repo with the harness vendored under .xyz/ (post-flip code)
git init -q -b development "$CON"
git -C "$CON" config user.email p5@test.invalid; git -C "$CON" config user.name p5
mkdir -p "$CON/.xyz"
for d in relay-automation bin src utils; do cp -R "$HARNESS/$d" "$CON/.xyz/$d"; done
mkdir -p "$CON/src" "$CON/test" "$CON/PROJECT/2-WORKING"
printf 'module.exports = 1\n' > "$CON/src/feature.js"
printf '#!/usr/bin/env bash\nexit 0\n' > "$CON/test/fixture-gate.sh"; chmod +x "$CON/test/fixture-gate.sh"
printf '.tick/\n.xyz/__pycache__/\n__pycache__/\n' > "$CON/.gitignore"

cat > "$CON/PROJECT/2-WORKING/GH-901-FIXTURE-LANE.md" <<'DOC'
---
gh_issue: 901
source: https://github.com/example/example/issues/901
title: "GH-280 vendored default-path fixture"
status: "Active"
created: 2026-08-29
updated: 2026-08-29
owner: test
doc_type: bugfix
goal: prove the post-flip default executor dispatches marathon in a vendored install
fix_probes:
  - bash test/fixture-gate.sh
---

# Fixture lane

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/fixture-gate.sh",
  "fix_probes": [ { "type": "path_absent", "path": "notes/landing-note.txt" } ],
  "artifacts": [ "src/feature.js" ]
}
```

## Acceptance

- [ ] vendored default run dispatches the marathon executor with no --executor flag
DOC

# stub agents (find-based, land the declared artifact) + canned gh (no PRs)
cat > "$AG/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
relay="$(find "$PWD/marathon-system" -name RELAY.md -type f | head -1)"
printf '\n### Round 1 · Builder · %s (stub)\nImplemented: vendored default-path fixture update\n' "${RELAY_AGENT:-codex}" >> "$relay"
printf 'module.exports = 2\n' > "$PWD/src/feature.js"
exit 0
EOF
cat > "$AG/agy" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in whoami|models) printf 'agy-stub\n'; exit 0 ;; esac
relay="$(find "$PWD/marathon-system" -name RELAY.md -type f | head -1)"
printf 'agy review stub\n'
sed -i.bak 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "$relay"; rm -f "$relay.bak"
printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Approved\nBasis: fixture\n' "${RELAY_AGENT:-agy}" >> "$relay"
exit 0
EOF
chmod +x "$AG/codex" "$AG/agy"
cat > "$SB/gh" <<'EOF'
#!/usr/bin/env bash
set -u
if [ "${1:-}" = "auth" ]; then exit 0; fi
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "list" ]; then printf '[]\n'; exit 0; fi
exit 1
EOF
chmod +x "$SB/gh"

git -C "$CON" add -A && git -C "$CON" commit -qm "fixture state"
python3 "$CON/.xyz/utils/py/releases_app.py" --root "$CON" init >/dev/null 2>&1
python3 "$CON/.xyz/utils/py/releases_app.py" --root "$CON" jog add 901 >/dev/null 2>&1

echo "=== VENDORED DEFAULT RUN (no --executor flag) ==="
( cd "$FCW" && PATH="$AG:$SB:$PATH" CODEX_BIN="$AG/codex" AGY_BIN="$AG/agy" \
  python3 "$CON/.xyz/utils/py/releases_app.py" --root "$CON" jog run \
    --builder codex --reviewer agy 2>&1 ); rc=$?
echo "=== exit=$rc ==="
echo "--- queue row ---"
python3 - "$CON/releases.db" <<'PY'
import sqlite3, sys
r = sqlite3.connect(sys.argv[1]).execute("SELECT status, substr(failure_reason,1,90) FROM jog_queue WHERE gh_number=901").fetchone()
print(r)
PY
echo "--- receipt ---"
find "$CON/.tick/jog" -name marathon-result.json -exec python3 -c '
import json,sys,os
d=json.load(open(sys.argv[1]))
print("outcome:", d["outcome"], "| gate:", d["gate"]["result"], "| target_is_consumer:", os.path.realpath(d["target_repo"]["path"]))
print("drive:", d.get("base_branch"), "| pr:", d["pr"]["number"])' {} \;
echo "--- foreign cwd clean ---"
ls -A "$FCW" | wc -l
echo "WORKDIR=$W"
