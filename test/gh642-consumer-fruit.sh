#!/usr/bin/env bash
# GH-642 — consumer-repo fruit: make the foreign-repo marathon SOP turnkey.
# Covers:
#   xyz-vendor.sh ignore rules land in the repo-local info/exclude, never the target .gitignore
#     (normal clone / linked worktree / --separate-git-dir shapes; idempotent; direction-2 intact),
#   claude-turn.py Opus-class default-budget warning (source pin + compile),
#   marathon_drive.resolve_force_relay_task (spent → -R2…; open → unchanged; explicit → unchanged;
#     malformed → fail; missing tick → fail),
#   rtl_worktree_begin copies (not symlinks) ROOT/node_modules into the worktree,
#   xyz_init_clone.py e2e against a local bare remote (name, -r2 retry, refusals, vendor, hooks),
#   swarm_preflight.py zero-criteria stderr warning (source pin + compile).
source "$(dirname "$0")/_setup.sh" gh642-consumer-fruit

ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/relay-automation/xyz-vendor.sh"
PYCLAUDE="$ROOT/utils/py/claude-turn.py"
PYDRIVE="$ROOT/utils/py/marathon_drive.py"
PYINIT="$ROOT/utils/py/xyz_init_clone.py"
PYPREFLIGHT="$ROOT/utils/py/swarm_preflight.py"
RTL="$ROOT/relay-automation/relay-turn-lib.sh"

# --- item 1: vendor ignore rules → repo-local info/exclude --------------------------------------
mkrepo() {  # <name> [git-init-extra...] -> canonical path of a fresh git repo
  local d="$WORK/$1"; mkdir -p "$d"; git init -q "$d"; shift
  [ $# -gt 0 ] && git -C "$d" "$@"
  ( cd "$d" && pwd -P )
}

R1="$(mkrepo r1-normal)"
printf 'node_modules/\n' > "$R1/.gitignore"
"$VENDOR" --no-register "$R1" >/dev/null 2>&1 && pass "vendor runs on a normal clone" || fail "vendor failed on normal clone"
grep -Fqx '.xyz/' "$R1/.git/info/exclude" && pass "exclude: .xyz/ in info/exclude" || fail ".xyz/ missing from info/exclude"
grep -Fqx '/.tick/' "$R1/.git/info/exclude" && pass "exclude: /.tick/ in info/exclude" || fail "/.tick/ missing from info/exclude"
grep -Fqx '.xyz/' "$R1/.gitignore" && fail "exclude: .gitignore was modified (must stay untouched)" || pass "exclude: target .gitignore untouched"
grep -Fqx 'node_modules/' "$R1/.gitignore" && pass "exclude: pre-existing .gitignore rule preserved" || fail "pre-existing .gitignore rule lost"

# idempotent re-run: no duplicate exclude lines
"$VENDOR" --no-register "$R1" >/dev/null 2>&1
[ "$(grep -c '^\.xyz/$' "$R1/.git/info/exclude")" = 1 ] && pass "exclude: idempotent re-run (1 .xyz/ line)" || fail "exclude: duplicate lines after re-run"

# linked-worktree shape: vendor inside a worktree of a bare-parented repo
BR="$WORK/r2-bare.git"; git init -q --bare "$BR"
WT="$WORK/r2-wt"
git -C "$R1" push -q "$BR" HEAD 2>/dev/null
git clone -q "$BR" "$WT-main" 2>/dev/null
git -C "$WT-main" worktree add -q "$WT" 2>/dev/null
if [ -d "$WT/.git" ] || [ -f "$WT/.git" ]; then
  "$VENDOR" --no-register "$WT" >/dev/null 2>&1 && pass "vendor runs inside a linked worktree" || fail "vendor failed inside a linked worktree"
  exclude_wt="$(git -C "$WT" rev-parse --git-path info/exclude)"
  grep -Fqx '.xyz/' "$exclude_wt" && pass "exclude: worktree target writes to its resolved info/exclude" || fail "worktree exclude not written ($exclude_wt)"
else
  fail "worktree fixture not created — worktree-shape case skipped as a failure"
fi

# --separate-git-dir shape
SG="$WORK/r3-sg"; SGD="$WORK/r3-gitdir"
git init -q --separate-git-dir "$SGD" "$SG"
"$VENDOR" --no-register "$SG" >/dev/null 2>&1 && pass "vendor runs with --separate-git-dir" || fail "vendor failed with --separate-git-dir"
grep -Fqx '.xyz/' "$SGD/info/exclude" && pass "exclude: separate-git-dir target writes to its info/exclude" || fail "separate-git-dir exclude not written"

# non-git target: fallback to .gitignore so the rules stay operator-visible (plan item 1)
NG="$WORK/non-git"; mkdir -p "$NG"
"$VENDOR" --no-register "$NG" >/dev/null 2>&1 && pass "vendor runs on a non-git directory" || fail "vendor failed on non-git dir"
grep -Fqx '.xyz/' "$NG/.gitignore" && pass "non-git fallback: rules land in .gitignore" || fail "non-git fallback rules missing"

# direction 2 intact: a repo blocking marathon-commit paths still gets the advisory, never an edit
B4="$(mkrepo r4-blocked)"; printf '/relay-system\n' > "$B4/.gitignore"
out="$( "$VENDOR" --no-register "$B4" 2>&1 )"
grep -q "WARNING" <<<"$out" && pass "direction 2 intact: blocking rule still warns" || fail "direction 2 warning vanished"
grep -Fqx '/relay-system' "$B4/.gitignore" && pass "direction 2 intact: blocking rule preserved" || fail "blocking rule was edited"

# --- item 2: claude-turn.py Opus-budget warning -------------------------------------------------
python3 -m py_compile "$PYCLAUDE" && pass "claude-turn.py compiles" || fail "claude-turn.py does not compile"
py_warn() {  # <model> <budget> -> prints the warning stdout/stderr capture marker when it fires
  python3 - "$PYCLAUDE" "$1" "$2" <<'PYW'
import importlib.util, io, sys
spec = importlib.util.spec_from_file_location("claude_turn", sys.argv[1])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
buf = io.StringIO()
mod.warn_opus_budget(sys.argv[2], sys.argv[3], stream=buf)
print("WARNED" if buf.getvalue() else "SILENT")
PYW
}
[ "$(py_warn claude-opus-4-8 0.50)" = "WARNED" ] && pass "Opus warning fires for opus + default budget" || fail "Opus warning did not fire"
[ "$(py_warn claude-opus-4-8 5.00)" = "SILENT" ] && pass "Opus warning silent when budget raised" || fail "Opus warning fired despite raised budget"
[ "$(py_warn claude-sonnet-4-6 0.50)" = "SILENT" ] && pass "Opus warning silent for Sonnet" || fail "Opus warning fired for Sonnet"

# --- item 3: marathon_drive.resolve_force_relay_task --------------------------------------------
python3 -m py_compile "$PYDRIVE" && pass "marathon_drive.py compiles" || fail "marathon_drive.py does not compile"
STUB="$WORK/stub-tick"; mkdir -p "$STUB"
cat > "$STUB/tick" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "info MARATHON-P1-TURN")    printf 'id:       MARATHON-P1-TURN\nstatus:   done\n'; exit 0;;
  "info MARATHON-P1-TURN-R2") printf 'id:       MARATHON-P1-TURN-R2\nstatus:   claimed\n'; exit 0;;
  "info MARATHON-P1-TURN-R3") echo "task not found" >&2; exit 1;;
  "info MAL")                 printf 'id:       MAL\nstatus:   done\n'; exit 0;;
  "info MAL-R2")              printf 'no parseable status here\n'; exit 0;;
  "info GARBAGE")             printf 'no parseable status here\n'; exit 0;;
  *)                          echo "task not found" >&2; exit 1;;
esac
STUB
chmod +x "$STUB/tick"
run_resolve() {  # <tick-path> <base> <force> <explicit> -> "exit:<rc> out:<last-stdout-line>" (stderr NOT suppressed)
  python3 - "$PYDRIVE" "$1" "$2" "$3" "$4" <<'PY'
import importlib.util, sys
path, tick, base, force, explicit = sys.argv[1:6]
spec = importlib.util.spec_from_file_location("marathon_drive", path)
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
try:
    print("out:" + mod.resolve_force_relay_task(base, tick, force == "True", explicit == "True"))
except SystemExit as e:
    print(f"exit:{e.code}")
PY
}
RES="$(run_resolve "$STUB/tick" MARATHON-P1-TURN True False 2>/dev/null)"
[ "$RES" = "out:MARATHON-P1-TURN-R3" ] && pass "spent default → skips claimed -R2, takes first free -R3" || fail "monotonic scan wrong: $RES"
ERR="$(run_resolve "$STUB/tick" MARATHON-P1-TURN True False 2>&1 >/dev/null)"
grep -q "using fresh relay task MARATHON-P1-TURN-R3" <<<"$ERR" && pass "fresh-id announcement is on stderr (plan contract)" || fail "announcement not on stderr: $ERR"
RES="$(run_resolve "$STUB/tick" MARATHON-P1-TURN False False 2>/dev/null)"
[ "$RES" = "out:MARATHON-P1-TURN" ] && pass "no --force → base id unchanged" || fail "without force the id changed: $RES"
RES="$(run_resolve "$STUB/tick" MARATHON-P1-TURN True True 2>/dev/null)"
[ "$RES" = "out:MARATHON-P1-TURN" ] && pass "explicit --relay-task → never rewritten" || fail "explicit id was rewritten: $RES"
RES="$(run_resolve "$STUB/tick" GARBAGE True False 2>/dev/null)"
[ "$RES" = "exit:2" ] && pass "malformed base info (existing tick) → refuses exit 2" || fail "malformed base not refused: $RES"
RES="$(run_resolve "$STUB/tick" MAL True False 2>/dev/null)"
[ "$RES" = "exit:2" ] && pass "malformed info mid-scan → refuses exit 2 (no unbounded loop)" || fail "malformed candidate not refused: $RES"
RES="$(run_resolve "/nonexistent/tick" MAL True False 2>/dev/null)"
[ "$RES" = "exit:2" ] && pass "missing tick binary → refuses exit 2 (no free-id guess)" || fail "missing tick not refused: $RES"

# --- item 4: rtl_worktree_begin copies node_modules ---------------------------------------------
bash -n "$RTL" && pass "relay-turn-lib.sh parses" || fail "relay-turn-lib.sh does not parse"
grep -q 'cp -R "$RTL_ROOT/node_modules" "$wt/node_modules"' "$RTL" && pass "worktree deps are a COPY (containment: no symlink into ROOT)" || fail "worktree deps are not a copy"
FIX="$WORK/rtl-fixture"; mkdir -p "$FIX"; git -C "$FIX" init -q
mkdir -p "$FIX/node_modules/pkg"; printf 'x' > "$FIX/node_modules/pkg/index.js"
printf 'relay\n' > "$FIX/RELAY.md"
# rtl_worktree_begin cuts at HEAD — the fixture needs at least one commit or the add fails.
( cd "$FIX" && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1 )
out="$(cd "$FIX" && bash -c '
  source "'"$RTL"'"
  RTL_ROOT="'"$FIX"'"
  RTL_ALLOW=("RELAY.md"); RTL_WT_USED=0
  wt="$(rtl_worktree_begin)" || exit 9
  if [ -d "$wt/node_modules" ] && [ ! -L "$wt/node_modules" ] && [ -f "$wt/node_modules/pkg/index.js" ]; then
    printf 'marker\n' > "$wt/node_modules/pkg/marker.txt"
    if [ ! -e "'"$FIX"'/node_modules/pkg/marker.txt" ]; then echo "ROOT-CLEAN"; else echo "ROOT-LEAK"; fi
    echo "COPY-OK $wt"; git -C "'"$FIX"'" worktree remove --force "$wt" 2>/dev/null
  else
    echo "COPY-BAD $wt"; [ -L "$wt/node_modules" ] && echo "IS-SYMLINK"
  fi
')"
grep -q "COPY-OK" <<<"$out" && ! grep -q "IS-SYMLINK" <<<"$out" && grep -q "ROOT-CLEAN" <<<"$out" \
  && pass "isolated worktree receives a real node_modules COPY; turn writes cannot reach ROOT" \
  || fail "worktree deps copy broken: $out"

# --- item 5: xyz_init_clone.py e2e --------------------------------------------------------------
python3 -m py_compile "$PYINIT" && pass "xyz_init_clone.py compiles" || fail "xyz_init_clone.py does not compile"
SRC="$WORK/init-src"; mkdir -p "$SRC/githooks"
git -C "$SRC" init -q
printf '#!/usr/bin/env bash\nprintf "#!/bin/sh\\nexit 0\\n" > .git/hooks/pre-push\nchmod +x .git/hooks/pre-push\nexit 0\n' > "$SRC/githooks/install.sh"; chmod +x "$SRC/githooks/install.sh"
( cd "$SRC" && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1 )
BARE="$WORK/init-bare.git"; git clone -q --bare "$SRC" "$BARE"
export XYZ_REGISTRY="$WORK/init-registry.tsv"
CL="$WORK/init-clones"
python3 "$PYINIT" "file://$BARE" --umbrella 99 --slug demo-one --dir "$CL" >/dev/null 2>&1 \
  && pass "init-clone: e2e run exits 0" || fail "init-clone e2e failed"
[ -d "$CL/marathon-gh-99-demo-one/.xyz/relay-automation" ] && pass "init-clone: vendored harness landed" || fail "init-clone: .xyz missing"
[ -f "$CL/marathon-gh-99-demo-one/.xyz/utils/py/releases_app.py" ] && pass "init-clone: Tier 2 confirmed (releases_app.py present)" || fail "init-clone: Tier 2 overlay missing (releases_app.py)"
grep -Fqx '.xyz/' "$CL/marathon-gh-99-demo-one/.git/info/exclude" && pass "init-clone: excludes landed in info/exclude" || fail "init-clone: excludes missing"
[ -x "$CL/marathon-gh-99-demo-one/.git/hooks/pre-push" ] || [ -f "$CL/marathon-gh-99-demo-one/.git/hooks/pre-push" ] \
  && pass "init-clone: cloned-repo hooks installed" || fail "init-clone: hooks not installed"
[ -d "$CL/marathon-gh-99-demo-one-r2" ] && fail "init-clone: spurious -r2 clone without re-run" || true
python3 "$PYINIT" "file://$BARE" --umbrella 99 --slug demo-one --dir "$CL" >/dev/null 2>&1 \
  && pass "init-clone: re-run on occupied derived name retries with -r2" || fail "init-clone: occupied-name retry failed"
[ -d "$CL/marathon-gh-99-demo-one-r2" ] && pass "init-clone: -r2 destination created" || fail "init-clone: -r2 destination missing"
[ -f "$CL/marathon-gh-99-demo-one/githooks/install.sh" ] && [ -d "$CL/marathon-gh-99-demo-one/.xyz" ] \
  && pass "init-clone: original clone untouched by re-run" || fail "init-clone: original clone disturbed"
python3 "$PYINIT" "file://$BARE" --dir "$CL/nowhere" >/dev/null 2>&1 \
  && fail "init-clone: missing --umbrella was not refused" || pass "init-clone: --umbrella required"
python3 "$PYINIT" "file://$BARE" --umbrella 5 --slug "Bad_Slug" --dir "$CL/nowhere2" >/dev/null 2>&1 \
  && fail "init-clone: invalid slug was not refused" || pass "init-clone: invalid slug refused"
python3 "$PYINIT" "file://$BARE" --umbrella 77 --slug a-b-c --dir "$CL/boundary" >/dev/null 2>&1 \
  && pass "slug: three lowercase words accepted" || fail "slug: three-word slug refused"
python3 "$PYINIT" "file://$BARE" --umbrella 78 --slug a-b-c-d --dir "$CL/boundary" >/dev/null 2>&1 \
  && fail "slug: four-word slug was accepted" || pass "slug: four-word slug refused"

# --- item 6: preflight zero-criteria warning ----------------------------------------------------
python3 -m py_compile "$PYPREFLIGHT" && pass "swarm_preflight.py compiles" || fail "swarm_preflight.py does not compile"
py_zc() {  # <acc_mode> <items_csv-present 1|0> <fmt> -> marker when the warning fires
  python3 - "$PYPREFLIGHT" "$1" "$2" "$3" <<'PYZ'
import importlib.util, io, sys
spec = importlib.util.spec_from_file_location("swarm_preflight", sys.argv[1])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
buf = io.StringIO()
mod.warn_zero_criteria(sys.argv[2], ["x"] if sys.argv[3] == "1" else [], "DOC.md", sys.argv[4], stream=buf)
print("WARNED" if buf.getvalue() else "SILENT")
PYZ
}
[ "$(py_zc acceptance-section 0 text)" = "WARNED" ] && pass "zero-criteria warning fires (acceptance-section, 0 items, text)" || fail "zero-criteria warning did not fire"
[ "$(py_zc acceptance-section 1 text)" = "SILENT" ] && pass "zero-criteria warning silent when items exist" || fail "zero-criteria warning fired despite items"
[ "$(py_zc whole-document 0 text)" = "SILENT" ] && pass "zero-criteria warning silent outside acceptance-section mode" || fail "warning fired for non-acceptance mode"
[ "$(py_zc acceptance-section 0 json)" = "SILENT" ] && pass "zero-criteria warning silent for json format" || fail "warning fired for json"
# ordering pin: the warn call site must precede the dry-run exit (moving it after = regression)
wc_line=$(grep -n "warn_zero_criteria(acc_mode" "$PYPREFLIGHT" | head -1 | cut -d: -f1)
dry_line=$(grep -n "if args.dry_run:" "$PYPREFLIGHT" | head -1 | cut -d: -f1)
[ -n "$wc_line" ] && [ -n "$dry_line" ] && [ "$wc_line" -lt "$dry_line" ] \
  && pass "zero-criteria warning precedes the dry-run exit" || fail "warning call site moved after dry-run exit"
grep -q "Acceptance section with no " utils/swarm-preflight.sh 2>/dev/null \
  && fail "bash fallback was edited (frozen twin — keep fixes in the Python twin)" \
  || pass "frozen bash fallback untouched (GH-308)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
