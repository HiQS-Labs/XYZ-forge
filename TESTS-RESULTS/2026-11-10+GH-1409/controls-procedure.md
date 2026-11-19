# Controls procedure (manual check, not a suite; GH-831)

Run in a disposable full clone whose origin was repointed to a nonexistent path, with HOME sandboxed:
`bash controls.sh <verify-clone> <out-dir>`. The label-red3 discriminator ran the same harness with only the
red3 and label-red3 scenarios.

```bash
#!/usr/bin/env bash
# GH-1409 manual controls (not a suite; GH-831). Runs in a disposable full clone.
# Usage: gh1409-controls.sh <verify-clone> <out-dir>
# Each scenario: base = verify clone's HEAD; a throwaway PR commit; a --no-ff merge (HEAD^1=base,
# HEAD^2=PR), then the vendored-smoke steps extracted verbatim from .github/workflows/ci.yml.
set -uo pipefail
V="$1"; OUT="$2"; mkdir -p "$OUT"
cd "$V" || exit 2
BASE="$(git rev-parse HEAD)"
STUB="$(mktemp -d)"
cat > "$STUB/gh" <<'EOF'
#!/usr/bin/env bash
# stub: `gh pr view N --json labels --jq ...` prints $STUB_LABELS one per line
printf '%s\n' ${STUB_LABELS:-}
EOF
chmod +x "$STUB/gh"

step() { # print the run: body of the vendored-smoke step whose name starts with $1
  python3 - "$1" <<'PY'
import sys, yaml
wf = yaml.safe_load(open(".github/workflows/ci.yml"))
for s in wf["jobs"]["vendored-smoke"]["steps"]:
    if s.get("name", "").startswith(sys.argv[1]):
        print(s["run"]); break
else:
    sys.exit("step not found: " + sys.argv[1])
PY
}

run_scenario() { # name, labels, mutate-fn
  local name="$1" labels="$2" fn="$3" log="$OUT/$1.log" rc_pin rc_ratchet rc_suites
  git checkout -q -f "$BASE" && git clean -qfd -e .tick >/dev/null
  git checkout -q -B "pr-$name" "$BASE"
  "$fn"
  git add -A && git commit -qm "control $name" --allow-empty
  git checkout -q --detach "$BASE"
  git merge -q --no-ff --no-edit "pr-$name" || { echo "merge failed" >"$log"; return; }
  local genv; genv="$(mktemp)"
  {
    echo "== scenario $name base=$BASE merge=$(git rev-parse HEAD) labels='${labels}'"
    PIN="$(step 'Pin judge files to PR base')"
    env GITHUB_ENV="$genv" GITHUB_REPOSITORY=HiQS-Labs/XYZ-forge PR_NUMBER=0 GH_TOKEN=x \
        STUB_LABELS="$labels" PATH="$STUB:$PATH" bash -c "$PIN"; rc_pin=$?
    echo "pin_step_exit=$rc_pin"
    set -a; . "$genv"; set +a
    if [ "$rc_pin" = 0 ]; then
      python3 utils/pdda/check_inventory_ratchet.py --check; rc_ratchet=$?
      echo "ratchet_exit=$rc_ratchet"
      if [ "${RUN_SUITES:-0}" = 1 ]; then
        bash -c "$(step 'Vendor harness into scratch repo')"; rc_suites=$?
        echo "vendored_suites_exit=$rc_suites"
      fi
    fi
    echo "pinned_file_status:"; git status --short -- utils/pdda test | head -10
  } >"$log" 2>&1
  grep -E '^(== |pin_step_exit|ratchet_exit|vendored_suites_exit)' "$log"
}

m_red1()  { python3 - <<'PY'
import json; p="utils/pdda/inventory_ratchet_baseline.json"; d=json.load(open(p))
d["scripts"].append("utils/zz-dummy.sh"); d["total_scripts"]+=1
open(p,"w").write(json.dumps(d,indent=2)+"\n")
PY
printf '#!/usr/bin/env bash\n' > utils/zz-dummy.sh; }
m_red1b() { python3 - <<'PY'
import json; p="utils/pdda/inventory_ratchet_baseline.json"; d=json.load(open(p))
f=d["sqlite_bypasses"][0].split(":")[0]; d["sqlite_bypasses"].append(f+":999999")
open(p,"w").write(json.dumps(d,indent=2)+"\n")
PY
}
m_red2()  { # move one marker: strip it from one marked line, add a new marked connect elsewhere
  local f; f="$(git grep -l 'SQLITE-BYPASS-OK:' -- '*.py' ':!test/**' | head -1)"
  sed -i '' '/SQLITE-BYPASS-OK:/{s/SQLITE-BYPASS-OK:/SQLITE-MOVED:/;}' "$f" 2>/dev/null || true
  printf 'import sqlite3\nc = sqlite3.connect(":memory:")  # SQLITE-BYPASS-OK: control\n' >> utils/py/releases_app.py; }
m_red3()  { # break find-harness-roots resolution and neuter its suite
  printf '#!/usr/bin/env bash\nexit 0\n' > test/gh396-find-harness-roots.sh
  # vendored consumers now resolve TICK_REPO_ROOT to the harness, not the consumer (only gh396 asserts this)
  sed -i '' 's|^\[ "\$VENDORED" = 1 \] \&\& TICK_REPO_ROOT="\$CALLER_ROOT"|[ "$VENDORED" = 1 ] \&\& TICK_REPO_ROOT="$HARNESS"|' skills/1-hourly/relay-xyz/find-harness.sh
  grep -q 'TICK_REPO_ROOT="\$HARNESS"$' skills/1-hourly/relay-xyz/find-harness.sh && ! grep -q 'TICK_REPO_ROOT="\$CALLER_ROOT"' skills/1-hourly/relay-xyz/find-harness.sh || { echo "red3 mutation did not apply" >&2; exit 9; }; }
m_green() { # retire one script and lock the shrink in with the PR's own ratchet
  git rm -q "$(python3 -c 'import json;print(json.load(open("utils/pdda/inventory_ratchet_baseline.json"))["scripts"][-1])')"
  python3 utils/pdda/check_inventory_ratchet.py --update-baseline; }

run_scenario red1   ""            m_red1
run_scenario red1b  ""            m_red1b
run_scenario red2   ""            m_red2
RUN_SUITES=1 run_scenario red3 "" m_red3
RUN_SUITES=1 run_scenario green "" m_green
run_scenario label  "judge-change" m_red1
git checkout -q -f "$BASE"; git clean -qfd -e .tick >/dev/null
rm -rf "$STUB"
```
