#!/usr/bin/env bash
# GH-660: skill_drift_check names vendored SKILL.md copies that diverge from
# canonical skills/, stays silent on identical vendors, and treats
# collection-only extras as informational — with a mutation proof.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="$ROOT/utils/py:${PYTHONPATH:-}"

FIX="$(mktemp -d)"; trap 'rm -rf "$FIX"' EXIT
mkdir -p "$FIX/canonical/skills/alpha" "$FIX/canonical/skills/beta" "$FIX/canonical/skills/1-hourly/delta" \
         "$FIX/collection/alpha" "$FIX/collection/beta" "$FIX/collection/gamma" "$FIX/collection/delta"
printf 'canonical alpha\n' > "$FIX/canonical/skills/alpha/SKILL.md"
printf 'canonical beta\n'  > "$FIX/canonical/skills/beta/SKILL.md"
printf 'canonical delta\n' > "$FIX/canonical/skills/1-hourly/delta/SKILL.md"   # GH-744: tiered canonical
printf 'canonical alpha\n' > "$FIX/collection/alpha/SKILL.md"   # identical vendor
printf 'stale beta\n'      > "$FIX/collection/beta/SKILL.md"    # DRIFTED
printf 'foreign\n'         > "$FIX/collection/gamma/SKILL.md"   # unrecognized extra
printf 'canonical delta\n' > "$FIX/collection/delta/SKILL.md"   # identical vendor of a TIERED canonical

pass=0; fail=0
assert() {  # <desc> <expected-rc> <out-substring...>
  local desc="$1" want_rc="$2" needle="$3" rc=0 out
  out="$(python3 "$ROOT/utils/py/skill_drift_check.py" \
    --canonical "$FIX/canonical" --collection "$FIX/collection")" && rc=0 || rc=$?
  if [ "$rc" -eq "$want_rc" ] && grep -q "$needle" <<<"$out"; then
    pass=$((pass+1)); echo "  PASS: $desc"
  else
    fail=$((fail+1)); echo "  FAIL: $desc (rc=$rc want=$want_rc; needle='$needle' missing)"
    echo "$out" | sed 's/^/    | /'
  fi
}

# 1. drifted vendor named, exit 1, clean vendor not in the drift list.
assert "drifted vendor named with canonical path" 1 "DRIFTED  beta:"
# 2. collection-only extra is informational, never a failure cause.
assert "unrecognized extra reported informationally" 1 "UNRECOGNIZED  gamma:"
# 3. identical vendor present and counted ok.
assert "identical vendors counted ok (flat alpha + tiered delta)" 1 "2 ok"
# 3b. GH-744: a tiered canonical skill is recognised, never reported as a collection-only extra.
out="$(python3 "$ROOT/utils/py/skill_drift_check.py" --canonical "$FIX/canonical" --collection "$FIX/collection")" || true
! grep -q "UNRECOGNIZED  delta:" <<<"$out" && pass=$((pass+1)) && echo "  PASS: tiered delta recognised" \
  || { fail=$((fail+1)); echo "  FAIL: tiered delta reported unrecognized: $out"; }

# 4. clean tree (remove the drifted vendor) → exit 0.
rm "$FIX/collection/beta/SKILL.md"
out="$(python3 "$ROOT/utils/py/skill_drift_check.py" \
  --canonical "$FIX/canonical" --collection "$FIX/collection")" && rc=0 || rc=$?
[ "$rc" -eq 0 ] && grep -q "0 drifted" <<<"$out" \
  && pass=$((pass+1)) && echo "  PASS: no drifted vendors -> exit 0" \
  || { fail=$((fail+1)); echo "  FAIL: clean tree must exit 0 (got $rc): $out"; }

# 5. Mutation proof: a check that cannot fail is not a check — mutate canonical
#    beta and the SAME vendor must now be flagged (fixture proven load-bearing).
printf 'canonical beta v2\n' > "$FIX/canonical/skills/beta/SKILL.md"
printf 'canonical delta v2\n' > "$FIX/canonical/skills/1-hourly/delta/SKILL.md"   # GH-744: tiered mutation
printf 'stale beta\n' > "$FIX/collection/beta/SKILL.md"   # restore the vendor test 4 removed
out="$(python3 "$ROOT/utils/py/skill_drift_check.py" \
  --canonical "$FIX/canonical" --collection "$FIX/collection")" && rc=0 || rc=$?
[ "$rc" -eq 1 ] && grep -q "DRIFTED  beta:" <<<"$out" && grep -q "DRIFTED  delta:" <<<"$out" \
  && pass=$((pass+1)) && echo "  PASS: mutation proof — stale vendors re-flag after canonical moves (flat + tiered)" \
  || { fail=$((fail+1)); echo "  FAIL: mutation proof (rc=$rc): $out"; }

# 6. --json carries the same verdict machine-readably. Capture first: the
# checker exits 1 on drift and pipefail would swallow the parser's verdict.
json_out="$(python3 "$ROOT/utils/py/skill_drift_check.py" --canonical "$FIX/canonical" \
  --collection "$FIX/collection" --json)" || true
printf '%s' "$json_out" | python3 -c '
import json, sys
r = json.load(sys.stdin)
assert sorted(e["skill"] for e in r["drifted"]) == ["beta", "delta"], r
assert r["unrecognized"][0]["skill"] == "gamma", r
' && pass=$((pass+1)) && echo "  PASS: --json verdict matches" \
  || { fail=$((fail+1)); echo "  FAIL: --json verdict mismatch"; }

echo "gh660-skill-drift: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
