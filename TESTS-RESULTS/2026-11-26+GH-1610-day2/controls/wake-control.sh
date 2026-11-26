#!/usr/bin/env bash
# GH-1610 Day 2 manual controls (a driver, not a suite; nothing here is registered with the gate).
#
# One disposable fixture, TWO queue rows behind each other, one supervised wake:
#   releases jog run --target-root <FT> --builder codex --reviewer agy --max-tasks 2 --supervise-until <epoch>
# Row 1 (GH-901) is put into one case; row 2 (GH-902) is always a ready successor. Only the worker edge
# (relay-drive) is stubbed and counted per issue; Jog -> Preflight -> Marathon are the real code.
#
# usage: CASE=<case> [EXPECT_SUCC=<0|1>] [EXPECT_R1=<status prefix>] bash wake-control.sh <repo-under-test-root>
# cases:
#   task-local  row 1 passes review, its own gate runs red (exit 5 pre-advance-failed)  -> successor expected once
#   exhausted   row 1 pending with its native lane history already at the cap (2/2)     -> successor expected once
#   hold        row 1 capture carries a human HELD: marker                               -> successor expected once
#   shared      row 1 worker edge crashes (exit 9, a shared/unclassified stop)           -> successor expected ZERO times
#   refusal     row 1 capture acceptance differs from the live issue (Preflight NOT-READY, parked) -> successor expected ZERO times
# The assertion prints one `ASSERT ...` line. EXPECT_SUCC overrides the case default so that an assertion
# can be turned into a red control (a wrong expectation must print FAIL).
REPO="${1:?usage: CASE=<case> bash wake-control.sh <repo-under-test-root>}"
CASE="${CASE:?CASE required}"
source "$REPO/test/_setup.sh" gh1610-wake
unset MARATHON_LANE_NS MARATHON_ROOT MARATHON_RELAY_DRIVE MARATHON_AGENT_CMD TICK_BIN

STUB_BIN="$WORK/stub-bin"; mkdir -p "$STUB_BIN"
GH_STUB_LOG="$WORK/gh-stub-calls.log"; export GH_STUB_LOG
REAL_GIT="$(command -v git)"; GH280_REAL_GIT="$REAL_GIT"; GH280_REMOTE="$REMOTE"; export GH280_REAL_GIT GH280_REMOTE

# gh shim: both fixture issues are OPEN with the acceptance their captures carry; no PRs; anything else exits 1.
cat > "$STUB_BIN/gh" <<'GH_EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${GH_STUB_LOG:?}"
if [ "${1:-}" = auth ]; then exit 0; fi
if [ "${1:-}" = issue ] && [ "${2:-}" = view ]; then
  printf '%s\n' '{"state":"OPEN","closedAt":null,"body":"## Acceptance\n- [ ] artifact updated and gate green\n","labels":[]}'
  exit 0
fi
if [ "${1:-}" = pr ] && [ "${2:-}" = list ]; then echo '[]'; exit 0; fi
exit 1
GH_EOF
chmod +x "$STUB_BIN/gh"
cat > "$STUB_BIN/git" <<'GIT_EOF'
#!/usr/bin/env bash
fixture_root="$PWD"; [ "${1:-}" != -C ] || fixture_root="$2"
for command in "$@"; do
  case "$command" in fetch|push|ls-remote)
    transport="$GH280_REMOTE"
    if [ "$command" = fetch ]; then
      fixture_remote="$("$GH280_REAL_GIT" -C "$fixture_root" config --get gh280.fixtureRemote || true)"
      [ -z "$fixture_remote" ] || transport="$fixture_remote"
    fi
    exec "$GH280_REAL_GIT" -c "url.$transport.insteadOf=https://github.com/example/example.git" "$@" ;;
  esac
done
exec "$GH280_REAL_GIT" "$@"
GIT_EOF
chmod +x "$STUB_BIN/git"
export PATH="$STUB_BIN:$PATH"

# worker edge: one line per call naming the issue it was dispatched for; exit code chosen per issue
STUB_RD="$WORK/relay-drive.sh"
cat > "$STUB_RD" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
issue=unknown
case "$*" in *gh-901*|*GH-901*|*gh901*) issue=901 ;; *gh-902*|*GH-902*|*gh902*) issue=902 ;; esac
printf '%s %s\n' "$issue" "$*" >> "$WORK/relay-drive-calls"
rc="${RD_EXIT_902:-9}"; [ "$issue" != 901 ] || rc="${RD_EXIT_901:-0}"
if [ "$rc" -eq 0 ]; then
  bash "$ATTEST_STUB" "$@"
  # the real worker commits its turn; the attest stub only edits the tracked relay file, which would leave the
  # execution clone with tracked changes and make the NEXT dispatch's alignment hold for a fixture-only reason
  tr=""; prev=""; for a in "$@"; do [ "$prev" != --target-root ] || tr="$a"; prev="$a"; done
  [ -z "$tr" ] || { git -C "$tr" commit -aqm "stub worker turn" >/dev/null 2>&1 || true; }
fi
exit "$rc"
STUB_EOF
chmod +x "$STUB_RD"
STUB_CODEX="$WORK/stub-codex"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CODEX"; chmod +x "$STUB_CODEX"
STUB_AGY="$WORK/stub-agy";     printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY";     chmod +x "$STUB_AGY"

write_capture_doc() {  # <path> <issue> <slug title> <gate command>
  cat > "$1" <<DOC_EOF
---
gh_issue: $2
source: https://github.com/example/example/issues/$2
title: "GH-1610 fixture $3"
status: "Active"
created: 2026-11-26
updated: 2026-11-26
owner: test
doc_type: bugfix
---

# GH-$2 fixture $3

## Acceptance
- [ ] artifact updated and gate green

## Swarm Preflight Contract
\`\`\`json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "$4",
  "fix_probes": [ { "type": "path_absent", "path": "notes/landing-note-$2.txt" } ],
  "artifacts": [ "src/feature.js" ]
}
\`\`\`
DOC_EOF
}
DOC1="GH-901-FIXTURE-LANE.md"; DOC2="GH-902-FIXTURE-SUCCESSOR.md"

setup_fixture() {  # <root>
  local root="$1"
  git clone -q "$REMOTE" "$root"
  git -C "$root" config user.email gh280@test.invalid
  git -C "$root" config user.name gh280
  git -C "$root" remote set-url origin https://github.com/example/example.git
  for d in relay-automation bin src utils; do cp -R "$REPO/$d" "$root/$d"; done
  mkdir -p "$root/skills/1-hourly/kickstart/scripts"
  cp "$REPO/skills/1-hourly/kickstart/scripts/build_queue.py" "$root/skills/1-hourly/kickstart/scripts/build_queue.py"
  mkdir -p "$root/src" "$root/test" "$root/PROJECT/2-WORKING" "$root/githooks"
  printf 'module.exports = 1\n' > "$root/src/feature.js"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$root/test/fixture-gate.sh"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$root/test/fixture-gate-red.sh"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$root/githooks/install.sh"
  local gate1="bash test/fixture-gate.sh"; [ "$CASE" != task-local ] || gate1="bash test/fixture-gate-red.sh"
  write_capture_doc "$root/PROJECT/2-WORKING/$DOC1" 901 lane "$gate1"
  write_capture_doc "$root/PROJECT/2-WORKING/$DOC2" 902 successor "bash test/fixture-gate.sh"
  [ "$CASE" != refusal ] || python3 - "$root/PROJECT/2-WORKING/$DOC1" <<'PYEOF'
import pathlib, sys
p = pathlib.Path(sys.argv[1]); t = p.read_text()
p.write_text(t.replace("## Swarm Preflight Contract", "- [ ] additional requirement the live issue does not carry\n\n## Swarm Preflight Contract"))
PYEOF
  [ "$CASE" != hold ] || printf '\nHELD: owner decision required. Do not execute until owner approves the target.\n' >> "$root/PROJECT/2-WORKING/$DOC1"
  printf '.tick/\n.xyz/\n__pycache__/\n' > "$root/.gitignore"
  python3 "$REPO/utils/py/releases_app.py" --root "$root" init >/dev/null 2>&1
  git -C "$root" checkout -q -b development
  local pin
  pin="$(PYTHONPATH="$REPO/utils/py" python3 -c 'import sys; from harness_paths import primary_config_key; print(primary_config_key(sys.argv[1]))' "$root")"
  git -C "$root" config "$pin" "$root"
  python3 "$REPO/utils/py/releases_app.py" --root "$root" jog add 901 >/dev/null 2>&1
  python3 "$REPO/utils/py/releases_app.py" --root "$root" jog add 902 >/dev/null 2>&1
  git -C "$root" add -A >/dev/null 2>&1
  git -C "$root" commit -q -m "fixture init" >/dev/null 2>&1
  git -C "$root" checkout -q -B main >/dev/null 2>&1
}

trap 'printf "Fixture retained: %s\n" "$WORK"' EXIT
FR="$WORK/root-install"; setup_fixture "$FR"
git -C "$FR" checkout -q development
git -C "$FR" merge -q main
FT="$WORK/root-execution"
git clone -q --no-local "$FR" "$FT"
git -C "$FT" branch --no-track main origin/main
git -C "$FT" remote set-url origin "$(git -C "$FR" remote get-url origin)"
git -C "$FT" config gh280.fixtureRemote "$FR"
git -C "$FT" config user.name gh280
git -C "$FT" config user.email gh280@test.invalid

q() { python3 -c 'import sqlite3,sys; print(sqlite3.connect(sys.argv[1]).execute(sys.argv[2]).fetchone()[0])' "$FR/releases.db" "$1"; }
rows() { python3 -c 'import sqlite3,sys; print(sqlite3.connect(sys.argv[1]).execute("select gh_number,status,attempt_count,coalesce(failure_reason,\"\") from jog_queue order by position").fetchall())' "$FR/releases.db"; }
calls_for() { [ -f "$WORK/relay-drive-calls" ] || { echo 0; return; }; grep -c "^$1 " "$WORK/relay-drive-calls" || true; }

if [ "$CASE" = exhausted ]; then   # row 1's native lane history is already at the cap (2/2)
  mkdir -p "$FT/.tick/attempts"
  printf '2026-11-26T00:00:00Z synthetic-prior-attempt-1\n2026-11-26T00:01:00Z synthetic-prior-attempt-2\n' > "$FT/.tick/attempts/gh-901-fixture-lane"
  cp "$FT/.tick/attempts/gh-901-fixture-lane" "$WORK/native-before"
fi
RD1=0; RD2=9
[ "$CASE" != shared ] || RD1=9
end_epoch="$(python3 -c 'import time; print(int(time.time())+900)')"
printf '== wake: CASE=%s start=%s deadline_epoch=%s\n' "$CASE" "$(date -u +%FT%TZ)" "$end_epoch"
printf 'queue before: %s\n' "$(rows)"
env -u MARATHON_ALLOW_TRUNK_COMMIT RD_EXIT_901="$RD1" RD_EXIT_902="$RD2" MARATHON_RELAY_DRIVE="$STUB_RD" CODEX_BIN="$STUB_CODEX" AGY_BIN="$STUB_AGY" \
  SP_SUGGESTED_BRANCH="marathon/gh901-fixture" \
  python3 "$FR/utils/py/releases_app.py" --root "$FR" jog run --target-root "$FT" --builder codex --reviewer agy \
  --max-tasks 2 --supervise-until "$end_epoch" </dev/null
rc=$?
printf 'jog exit=%s\n' "$rc"
c1="$(calls_for 901)"; c2="$(calls_for 902)"
printf 'worker edge calls: GH-901=%s GH-902=%s\n' "$c1" "$c2"; [ ! -f "$WORK/relay-drive-calls" ] || cut -c1-160 "$WORK/relay-drive-calls"
printf 'queue after: %s\n' "$(rows)"
r1="$(q 'select status from jog_queue where gh_number=901')"; a1="$(q 'select attempt_count from jog_queue where gh_number=901')"
r1reason="$(q 'select coalesce(failure_reason,"") from jog_queue where gh_number=901')"
hist=na
if [ "$CASE" = exhausted ]; then
  if cmp -s "$WORK/native-before" "$FT/.tick/attempts/gh-901-fixture-lane"; then hist=yes; else hist=NO; fi
  echo "native lane history of GH-901 unchanged=$hist"
  # MUTATE=history|failed: red controls for the retention assertions (applied after the run)
  case "${MUTATE:-}" in
    history) echo mutated >> "$FT/.tick/attempts/gh-901-fixture-lane"; cmp -s "$WORK/native-before" "$FT/.tick/attempts/gh-901-fixture-lane" && hist=yes || hist=NO ;;
    failed) r1=failed ;;
  esac
fi

# expectations: successor dispatch count, and that row 1 is never re-dispatched (0 calls for exhausted/hold,
# at most 1 for the others) and ends in a non-pending, non-completed state
case "$CASE" in shared|refusal) want_succ=0 ;; *) want_succ=1 ;; esac
want_succ="${EXPECT_SUCC:-$want_succ}"
ok=1
[ "$c2" = "$want_succ" ] || ok=0
case "$CASE" in exhausted|hold|refusal) [ "$c1" = 0 ] || ok=0 ;; *) [ "$c1" -le 1 ] || ok=0 ;; esac
case "$CASE" in exhausted) [ "$r1" = parked ] && [ "$hist" = yes ] || ok=0 ;; *) case "$r1" in parked|failed) ;; *) ok=0 ;; esac ;; esac
[ "$CASE" != hold ] || { [ "$a1" = 0 ] && case "$r1reason" in "hold: capture body HELD: marker"*) true ;; *) false ;; esac || ok=0; }
if [ "$ok" = 1 ]; then printf 'ASSERT case=%s successor_calls=%s PASS (row1=%s: %s)\n' "$CASE" "$c2" "$r1" "$r1reason"
else printf 'ASSERT case=%s want_successor_calls=%s FAIL (calls 901=%s 902=%s; row1=%s: %s)\n' "$CASE" "$want_succ" "$c1" "$c2" "$r1" "$r1reason"; fi
