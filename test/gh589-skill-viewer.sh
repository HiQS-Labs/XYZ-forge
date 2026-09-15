#!/usr/bin/env bash
# gh589-skill-viewer.sh — the XYZ mini skill viewer reports exactly what is on disk (GH-589).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
VIEWER="$REPO/mini/skills/skill-viewer/scripts/list_skills.py"
echo "== test: gh589-skill-viewer =="
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh589-viewer.XXXXXX")"
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

# 1. against this repo: count equals ls | wc -l and the name set equals the folder set
skill_files=("$REPO"/skills/*/SKILL.md)
expected="${#skill_files[@]}"
out="$(python3 "$VIEWER" --root "$REPO" 2>"$WORK/err")"; rc=$?
got="$(printf '%s\n' "$out" | tail -1 | awk '{print $1}')"
[ $rc -eq 0 ] && [ "$got" = "$expected" ] && pass "forge: viewer count $got == ls count $expected (rc=0)" || fail "forge: rc=$rc got=$got expected=$expected $(cat "$WORK/err" | head -3)"
names_fs="$(for f in "${skill_files[@]}"; do basename "$(dirname "$f")"; done | sort | tr '\n' ' ')"
names_v="$(python3 "$VIEWER" --root "$REPO" --json | python3 -c 'import json,sys; print(" ".join(sorted(s["name"] for s in json.load(sys.stdin)["skills"]))+" ")')"
[ "$names_fs" = "$names_v" ] && pass "forge: viewer name set equals the folder set" || fail "forge: name set mismatch"

# 1b. shakedown regression: CWD inside a DIFFERENT git repo, no --root → still this repo's count
O="$WORK/other"; git init -q "$O"
got_o="$(cd "$O" && python3 "$VIEWER" | tail -1 | awk '{print $1}')"
[ "$got_o" = "$expected" ] && pass "foreign-repo CWD: viewer resolves its own repo ($got_o)" || fail "foreign-repo CWD: got=$got_o expected=$expected"
# red control for 1b: a copy of the viewer with the cwd anchor removed lists the foreign repo (0)
cp "$VIEWER" "$WORK/mut_viewer.py"; sed -i.bak 's/cwd=here, //' "$WORK/mut_viewer.py"
got_m="$(cd "$O" && python3 "$WORK/mut_viewer.py" 2>/dev/null | tail -1 | awk '{print $1}')"
[ "$got_m" != "$expected" ] && pass "red: un-anchored viewer copy reports the foreign repo ($got_m) — control goes red" || fail "red: mutant still reported $got_m"

# 2. synthetic repo: block-scalar, JSON-quoted and single-quoted descriptions parse; expected set asserted
S="$WORK/synth"; for n in alpha beta gamma; do mkdir -p "$S/skills/$n"; done
a=alpha; b2=beta; g=gamma
printf -- '---\nname: alpha\ndescription: >-\n  first line\n  second line\n---\n' >"$S/skills/$a/SKILL.md"
printf -- '---\nname: beta\ndescription: "quoted \\"beta\\" text"\n---\n' >"$S/skills/$b2/SKILL.md"
printf -- "---\nname: gamma\ndescription: 'it''s gamma'\n---\n" >"$S/skills/$g/SKILL.md"
j="$(python3 "$VIEWER" --root "$S" --json)"; rc=$?
python3 - "$j" <<'PY' && pass "synthetic: three frontmatter styles parse to the expected set" || fail "synthetic: parse mismatch: $j"
import json,sys; d=json.loads(sys.argv[1]); m={s["name"]:s["description"] for s in d["skills"]}
assert m=={"alpha":"first line second line","beta":'quoted "beta" text',"gamma":"it's gamma"}, m
assert not d["errors"]
PY
[ "$(python3 "$VIEWER" --root "$S" | tail -1)" = "3 skills" ] && pass "synthetic: trailing count line is '3 skills'" || fail "synthetic: count line"

# 3. red controls: no frontmatter → exit 1 and named; empty skills dir → exit 2
b=broken; mkdir -p "$S/skills/$b"; printf 'no frontmatter here\n' >"$S/skills/$b/SKILL.md"
python3 "$VIEWER" --root "$S" >/dev/null 2>"$WORK/broken.err"; rc=$?
[ $rc -eq 1 ] && grep -q "$b/SKILL.md" "$WORK/broken.err" && pass "red: missing frontmatter → exit 1, file named" || fail "red: rc=$rc $(cat "$WORK/broken.err")"
E="$WORK/empty"; mkdir -p "$E/skills"
python3 "$VIEWER" --root "$E" >/dev/null 2>&1; rc=$?
[ $rc -eq 2 ] && pass "red: empty skills dir → exit 2 (two empty inventories cannot pass)" || fail "red: empty dir rc=$rc"

echo "gh589-skill-viewer: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
