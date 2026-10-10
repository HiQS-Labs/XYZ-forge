#!/usr/bin/env bash
# GH-1002 B2/B3 manual check (not a registered suite).
# Usage: bash cap_order_check.sh <harness-dir>   (a checkout whose relay-automation/ bin/ src/ utils/ to test)
# Builds a throwaway consumer repo with that harness installed at the root, then fires the Python
# marathon-drive against a hand-seeded .tick/attempts/p1 and prints one PASS/FAIL line per case.
set -u
H="$(cd "$1" && pwd)"
W="$(mktemp -d "${TMPDIR:-/tmp}/gh1002-cap.XXXXXX")"; trap 'rm -rf "$W"' EXIT
fails=0
chk() { if [ "$2" = 1 ]; then echo "PASS: $1"; else echo "FAIL: $1"; fails=$((fails + 1)); fi; }

git init -q --bare -b main "$W/remote.git"
git clone -q "$W/remote.git" "$W/seed" 2>/dev/null
git -C "$W/seed" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$W/seed" push -q origin HEAD:main
R="$W/repo"; git clone -q "$W/remote.git" "$R"
git -C "$R" config user.email t@t; git -C "$R" config user.name t
for d in relay-automation bin src utils; do cp -R "$H/$d" "$R/$d"; done
printf '.tick/\n__pycache__/\n' > "$R/.gitignore"
git -C "$R" add -A >/dev/null; git -C "$R" commit -q -m "fixture init"

printf '#!/usr/bin/env bash\nexit 3\n' > "$W/rd.sh"; chmod +x "$W/rd.sh"   # relay-drive: no progress
printf '#!/usr/bin/env bash\nexit 0\n' > "$W/ok";    chmod +x "$W/ok"
printf '## Brief\nDo nothing.\n' > "$W/brief.md"
md() { (cd "$R" && env -u XYZ_HARNESS -u MARATHON_ROOT XYZ_PYTHON=1 MARATHON_RELAY_DRIVE="$W/rd.sh" \
  CODEX_BIN="$W/ok" AGY_BIN="$W/ok" bash "$R/relay-automation/marathon-drive.sh" \
  --phases-dir "$R/marathon-system" --phase-brief "$W/brief.md" --phase-id p1 \
  --reviewer agy --builder codex --pre-advance-cmd "bash $W/ok" "$@"); }
seed() { mkdir -p "$R/.tick/attempts"; : > "$R/.tick/attempts/p1"; i=0; while [ $i -lt "$1" ]; do echo fire >> "$R/.tick/attempts/p1"; i=$((i + 1)); done; }
lines() { [ -f "$R/.tick/attempts/p1" ] && wc -l < "$R/.tick/attempts/p1" | tr -d ' ' || echo 0; }
heads() { git -C "$R" rev-list --count HEAD; }

# B3: dry-run at cap, without and with --force — read-only
seed 2; h0=$(heads); b0=$(shasum "$R/.tick/attempts/p1")
out="$(md --dry-run 2>&1)"
chk "dry-run at cap prints attempts 2/2 and PARK forecast" "$(grep -q 'attempts 2/2 — next live fire would PARK' <<<"$out" && echo 1)"
out="$(md --dry-run --force 2>&1)"
chk "dry-run --force at cap prints proceed forecast" "$(grep -q 'attempts 2/2 — --force set: next live fire proceeds' <<<"$out" && echo 1)"
chk "dry-runs leave attempts bytes and HEAD unchanged" "$([ "$(shasum "$R/.tick/attempts/p1")" = "$b0" ] && [ "$(heads)" = "$h0" ] && echo 1)"

# B2: live fire at cap parks with no new commit and no new attempt line
md >/dev/null 2>&1; rc=$?
chk "live fire at cap exits 8 (rc=$rc)" "$([ $rc -eq 8 ] && echo 1)"
chk "parked fire adds no commit (HEAD count $h0 -> $(heads))" "$([ "$(heads)" = "$h0" ] && echo 1)"
chk "parked fire adds no attempt line ($(lines))" "$([ "$(lines)" = 2 ] && echo 1)"

# inherited LANE_ATTEMPT_COUNTED=1 at cap still parks
LANE_ATTEMPT_COUNTED=1 md >/dev/null 2>&1; rc=$?
chk "inherited LANE_ATTEMPT_COUNTED=1 at cap still exits 8 (rc=$rc)" "$([ $rc -eq 8 ] && echo 1)"

# under cap: exactly one attempt appended
seed 0; md > "$W/under.log" 2>&1; rc=$?; [ "$rc" = 2 ] && tail -5 "$W/under.log" | sed "s/^/    | /"
chk "under-cap fire appends exactly one attempt (now $(lines), rc=$rc)" "$([ "$(lines)" = 1 ] && echo 1)"

# forced at cap: proceeds and appends exactly one
seed 2; md --force >/dev/null 2>&1; rc=$?
chk "forced at-cap fire proceeds (rc=$rc != 8) and appends one (now $(lines))" "$([ $rc -ne 8 ] && [ "$(lines)" = 3 ] && echo 1)"

echo "cap_order_check: $fails failure(s)"
[ "$fails" -eq 0 ]
