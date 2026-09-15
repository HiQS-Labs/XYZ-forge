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

# direction 2 intact: a repo blocking marathon-commit paths still gets the advisory, never an edit
B4="$(mkrepo r4-blocked)"; printf '/relay-system\n' > "$B4/.gitignore"
out="$( "$VENDOR" --no-register "$B4" 2>&1 )"
grep -q "WARNING" <<<"$out" && pass "direction 2 intact: blocking rule still warns" || fail "direction 2 warning vanished"
grep -Fqx '/relay-system' "$B4/.gitignore" && pass "direction 2 intact: blocking rule preserved" || fail "blocking rule was edited"

# --- item 2: claude-turn.py Opus-budget warning -------------------------------------------------
python3 -m py_compile "$PYCLAUDE" && pass "claude-turn.py compiles" || fail "claude-turn.py does not compile"
grep -q 'model.startswith("claude-opus")' "$PYCLAUDE" && grep -q 'CLAUDE_MAX_BUDGET' "$PYCLAUDE" \
  && pass "Opus-budget warning guards on model class + default budget" || fail "Opus-budget warning guard missing"

# --- item 3: marathon_drive.resolve_force_relay_task --------------------------------------------
python3 -m py_compile "$PYDRIVE" && pass "marathon_drive.py compiles" || fail "marathon_drive.py does not compile"
STUB="$WORK/stub-tick"; mkdir -p "$STUB"
cat > "$STUB/tick" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "info MARATHON-P1-TURN")    printf 'id:       MARATHON-P1-TURN\nstatus:   done\n';;
  "info MARATHON-P1-TURN-R2") echo "task not found" >&2; exit 1;;
  "info MARATHON-P1-TURN-R3") printf 'id:       MARATHON-P1-TURN-R3\nstatus:   open\n';;
  "info GARBAGE")             printf 'no status key here\n';;
  *) echo "task not found" >&2; exit 1;;
esac
STUB
chmod +x "$STUB/tick"
run_resolve() {  # <tick-path> <force> <explicit> -> resolved id (last stdout line; log() may also print)
  python3 - "$PYDRIVE" "$1" "$2" "$3" <<'PY'
import importlib.util, sys
path, tick, force, explicit = sys.argv[1:5]
spec = importlib.util.spec_from_file_location("marathon_drive", path)
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
print(mod.resolve_force_relay_task("MARATHON-P1-TURN", tick, force == "True", explicit == "True"))
PY
}
out="$(run_resolve "$STUB/tick" True False 2>/dev/null | tail -1)"
[ "$out" = "MARATHON-P1-TURN-R2" ] && pass "spent default + --force → first free -R2" || fail "expected -R2, got: $out"
out="$(run_resolve "$STUB/tick" False False 2>/dev/null | tail -1)"
[ "$out" = "MARATHON-P1-TURN" ] && pass "no --force → base id unchanged" || fail "without force the id changed: $out"
out="$(run_resolve "$STUB/tick" True True 2>/dev/null | tail -1)"
[ "$out" = "MARATHON-P1-TURN" ] && pass "explicit --relay-task → never rewritten" || fail "explicit id was rewritten: $out"
out="$(python3 - "$PYDRIVE" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("marathon_drive", sys.argv[1])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
try:
    mod.resolve_force_relay_task("GARBAGE", "$STUB/tick", True, False)
except SystemExit as e:
    print(f"exit-{e.code}")
PY
)"
[ "$out" = "exit-2" ] && pass "malformed tick info → refuses (exit 2)" || fail "malformed info not refused: $out"
out="$(run_resolve "/nonexistent/tick" True False 2>/dev/null)"
[ -z "$out" ] && pass "missing tick binary → fails fast (no free-id guess)" || fail "missing tick did not fail: $out"

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
    echo "COPY-OK $wt"; git -C "'"$FIX"'" worktree remove --force "$wt" 2>/dev/null
  else
    echo "COPY-BAD $wt"; [ -L "$wt/node_modules" ] && echo "IS-SYMLINK"
  fi
')"
grep -q "COPY-OK" <<<"$out" && ! grep -q "IS-SYMLINK" <<<"$out" \
  && pass "isolated worktree receives a real (non-symlink) node_modules copy" \
  || fail "worktree deps copy broken: $out"

# --- item 5: xyz_init_clone.py e2e --------------------------------------------------------------
python3 -m py_compile "$PYINIT" && pass "xyz_init_clone.py compiles" || fail "xyz_init_clone.py does not compile"
SRC="$WORK/init-src"; mkdir -p "$SRC/githooks"
git -C "$SRC" init -q
printf '#!/usr/bin/env bash\nexit 0\n' > "$SRC/githooks/install.sh"; chmod +x "$SRC/githooks/install.sh"
( cd "$SRC" && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1 )
BARE="$WORK/init-bare.git"; git clone -q --bare "$SRC" "$BARE"
export XYZ_REGISTRY="$WORK/init-registry.tsv"
CL="$WORK/init-clones"
python3 "$PYINIT" "file://$BARE" --umbrella 99 --slug demo-one --dir "$CL" >/dev/null 2>&1 \
  && pass "init-clone: e2e run exits 0" || fail "init-clone e2e failed"
[ -d "$CL/marathon-gh-99-demo-one/.xyz/relay-automation" ] && pass "init-clone: vendored harness landed (Tier 2)" || fail "init-clone: .xyz missing"
grep -Fqx '.xyz/' "$CL/marathon-gh-99-demo-one/.git/info/exclude" && pass "init-clone: excludes landed in info/exclude" || fail "init-clone: excludes missing"
[ -x "$CL/marathon-gh-99-demo-one/.git/hooks/pre-push" ] || [ -f "$CL/marathon-gh-99-demo-one/.git/hooks/pre-push" ] \
  && pass "init-clone: cloned-repo hooks installed" || fail "init-clone: hooks not installed"
[ -d "$CL/marathon-gh-99-demo-one-r2" ] && fail "init-clone: spurious -r2 clone without re-run" || true
python3 "$PYINIT" "file://$BARE" --umbrella 99 --slug demo-one --dir "$CL" >/dev/null 2>&1 \
  && pass "init-clone: re-run on occupied derived name retries with -r2" || fail "init-clone: occupied-name retry failed"
[ -d "$CL/marathon-gh-99-demo-one-r2" ] && pass "init-clone: -r2 destination created" || fail "init-clone: -r2 destination missing"
python3 "$PYINIT" "file://$BARE" --umbrella 99 --slug demo-one --dir "$CL/marathon-gh-99-demo-one" >/dev/null 2>&1 \
  && fail "init-clone: existing --dir was not refused" || pass "init-clone: existing --dir refused"
python3 "$PYINIT" "file://$BARE" --dir "$CL/nowhere" >/dev/null 2>&1 \
  && fail "init-clone: missing --umbrella was not refused" || pass "init-clone: --umbrella required"
python3 "$PYINIT" "file://$BARE" --umbrella 5 --slug "Bad_Slug" --dir "$CL/nowhere2" >/dev/null 2>&1 \
  && fail "init-clone: invalid slug was not refused" || pass "init-clone: invalid slug refused"

# --- item 6: preflight zero-criteria warning ----------------------------------------------------
python3 -m py_compile "$PYPREFLIGHT" && pass "swarm_preflight.py compiles" || fail "swarm_preflight.py does not compile"
grep -q "Acceptance section with no " "$PYPREFLIGHT" && grep -q "acc_mode == \"acceptance-section\" and not acc_items" "$PYPREFLIGHT" \
  && pass "zero-criteria stderr warning pinned (guard + message)" || fail "zero-criteria warning not found"
grep -q "Acceptance section with no " utils/swarm-preflight.sh 2>/dev/null \
  && fail "bash fallback was edited (frozen twin — keep fixes in the Python twin)" \
  || pass "frozen bash fallback untouched (GH-308)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
