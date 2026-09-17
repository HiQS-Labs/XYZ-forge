# RELAY · GH653 GH665 final fixture code QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh653-gh665-final-fixture-code-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh642-consumer-fruit.sh** (embedded below — read it here).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-17

### Artifact — gh642-consumer-fruit.sh
```
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
set -e

ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/relay-automation/xyz-vendor.sh"
PYCLAUDE="$ROOT/utils/py/claude-turn.py"
PYDRIVE="$ROOT/utils/py/marathon_drive.py"
PYINIT="$ROOT/utils/py/xyz_init_clone.py"
PYPREFLIGHT="$ROOT/utils/py/swarm_preflight.py"
RTL="$ROOT/relay-automation/relay-turn-lib.sh"

# --- item 1: vendor ignore rules → repo-local info/exclude --------------------------------------
mkrepo() {  # <name> [git-init-extra...] -> guarded path of a fresh git repo
  local name="${1:-}" d
  case "$name" in
    ''|.|..|*/*) echo "mkrepo: REFUSING invalid fixture name '$name'" >&2; return 2 ;;
  esac
  d="$WORK/$name"
  mkdir -p "$d" || { echo "mkrepo: REFUSING failed creation" >&2; return 2; }
  require_fixture "$d" mkrepo
  git init -q "$d" || { echo "mkrepo: REFUSING failed git init" >&2; return 2; }
  shift
  if [ $# -gt 0 ]; then git -C "$d" "$@" || return 2; fi
  printf '%s\n' "$d"
}

# GH-653/GH-665: failed substitutions must never seed the caller's checkout.
# Keep the caller inside _setup's sandbox, but outside the smaller guarded root.
require_fixture "$A" guard-caller
GUARD_ROOT="$WORK/guard-root"; mkdir -p "$GUARD_ROOT"
require_fixture "$GUARD_ROOT" guard-root
ln -s "$A" "$GUARD_ROOT/escape"
caller_before="$(git -C "$A" rev-parse HEAD)"
caller_identity="$(git -C "$A" rev-parse --absolute-git-dir --is-bare-repository)"
for fault in empty traversal symlink mkdir-failure init-failure; do
  rc=0
  (
    cd "$A" || exit 2
    WORK="$GUARD_ROOT"; fixture_guard_init "$WORK"
    name=failed
    case "$fault" in
      empty) name='' ;;
      traversal) name='../agent-a' ;;
      symlink) name=escape ;;
      mkdir-failure) mkdir() { return 17; } ;;
      init-failure) git() { if [ "$1" = init ]; then return 18; else command git "$@"; fi; } ;;
    esac
    R1="$(mkrepo "$name")" || exit 2
    require_fixture "$R1" seed-repo
    git -C "$R1" -c user.name=fixture -c user.email=fixture@test.invalid commit -q --allow-empty -m 'must not seed caller'
  ) > "$GUARD_ROOT/refusal.log" 2>&1 || rc=$?
  out="$(<"$GUARD_ROOT/refusal.log")"
  [ "$rc" -eq 2 ] && pass "fixture guard refuses $fault" || fail "fixture guard accepted $fault (rc=$rc): $out"
  [ "$(git -C "$A" rev-parse HEAD)" = "$caller_before" ] \
    && [ "$(git -C "$A" rev-parse --absolute-git-dir --is-bare-repository)" = "$caller_identity" ] \
    && [ -z "$(git -C "$A" status --porcelain)" ] \
    && pass "caller identity/HEAD/tree unchanged after $fault" || fail "caller changed after $fault"
done

R1="$(mkrepo r1-normal)" || exit 2
require_fixture "$R1" seed-repo
git -C "$R1" -c user.name=fixture -c user.email=fixture@test.invalid commit -q --allow-empty -m 'seed vendor fixture' || exit 2
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
BR="$WORK/r2-bare.git"; mkdir -p "$BR"; require_fixture "$BR" bare-repo
git init -q --bare "$BR"
WT="$WORK/r2-wt"
mkdir -p "$WT-main" "$WT"
require_fixture "$R1" push-source
require_fixture "$WT-main" clone-target
require_fixture "$WT" worktree-target
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
mkdir -p "$SG" "$SGD"
require_fixture "$SG" separate-worktree
require_fixture "$SGD" separate-gitdir
git init -q --separate-git-dir "$SGD" "$SG"
"$VENDOR" --no-register "$SG" >/dev/null 2>&1 && pass "vendor runs with --separate-git-dir" || fail "vendor failed with --separate-git-dir"
grep -Fqx '.xyz/' "$SGD/info/exclude" && pass "exclude: separate-git-dir target writes to its info/exclude" || fail "separate-git-dir exclude not written"

# non-git target: fallback to .gitignore so the rules stay operator-visible (plan item 1)
NG="$WORK/non-git"; mkdir -p "$NG"
require_fixture "$NG" non-git-target
"$VENDOR" --no-register "$NG" >/dev/null 2>&1 && pass "vendor runs on a non-git directory" || fail "vendor failed on non-git dir"
grep -Fqx '.xyz/' "$NG/.gitignore" && pass "non-git fallback: rules land in .gitignore" || fail "non-git fallback rules missing"

# direction 2 intact: a repo blocking marathon-commit paths still gets the advisory, never an edit
B4="$(mkrepo r4-blocked)" || exit 2
require_fixture "$B4" blocked-target
printf '/relay-system\n' > "$B4/.gitignore"
out="$( "$VENDOR" --no-register "$B4" 2>&1 )"
grep -q "WARNING" <<<"$out" && pass "direction 2 intact: blocking rule still warns" || fail "direction 2 warning vanished"
grep -Fqx '/relay-system' "$B4/.gitignore" && pass "direction 2 intact: blocking rule preserved" || fail "blocking rule was edited"

# --- item 2: claude-turn.py Opus-budget warning -------------------------------------------------
python3 -m py_compile "$PYCLAUDE" && pass "claude-turn.py compiles" || fail "claude-turn.py does not compile"
py_warn() {  # <model> <budget> -> prints the warning stdout/stderr capture marker when it fires
  python3 - "$PYCLAUDE" "$1" "$2" <<'PYW'
import importlib.util, io, os, sys
sys.path.insert(0, os.path.dirname(sys.argv[1]))
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
# DEFAULT-stream contract: with no stream= injection the message must land on stderr, not stdout.
DBG="$(mktemp -d "$WORK/warnings.XXXXXX")" || exit 2
require_fixture "$DBG" warning-output
python3 - "$PYCLAUDE" "$DBG/out.txt" "$DBG/err.txt" <<'PYD'
import importlib.util, os, sys
sys.path.insert(0, os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("claude_turn", sys.argv[1])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
out, err = open(sys.argv[2], "w"), open(sys.argv[3], "w")
mod.warn_opus_budget("claude-opus-4-8", "0.50", stream=None) if False else None
_saved_out, sys.stdout = sys.stdout, out
_saved_err, sys.stderr = sys.stderr, err
mod.warn_opus_budget("claude-opus-4-8", "0.50")
sys.stdout, sys.stderr = _saved_out, _saved_err
out.close(); err.close()
PYD
grep -q "Opus-class" "$DBG/err.txt" && ! grep -q "Opus-class" "$DBG/out.txt" \
  && pass "Opus warning defaults to stderr (not stdout)" || fail "Opus warning default stream wrong"
# runtime call pin: main() must invoke the helper (removing the call must go red)
grep -qE '^    warn_opus_budget\(model, max_budget\)' "$PYCLAUDE" \
  && pass "main() calls warn_opus_budget (runtime call pinned)" || fail "main() no longer calls warn_opus_budget"

# --- item 3: marathon_drive.resolve_force_relay_task --------------------------------------------
python3 -m py_compile "$PYDRIVE" && pass "marathon_drive.py compiles" || fail "marathon_drive.py does not compile"
STUB="$WORK/stub-tick"; mkdir -p "$STUB"
require_fixture "$STUB" tick-stub
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
FIX="$WORK/rtl-fixture"; mkdir -p "$FIX"; require_fixture "$FIX" rtl-fixture
git -C "$FIX" init -q
mkdir -p "$FIX/node_modules/pkg"; printf 'x' > "$FIX/node_modules/pkg/index.js"
printf 'relay\n' > "$FIX/RELAY.md"
# rtl_worktree_begin cuts at HEAD — the fixture needs at least one commit or the add fails.
( cd "$FIX" && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1 )
RTLTMP="$WORK/rtl-temp"; mkdir -p "$RTLTMP"; require_fixture "$RTLTMP" rtl-temp
out="$(cd "$FIX" && TMPDIR="$RTLTMP" bash -c '
  source "'"$RTL"'"
  source "'"$ROOT"'/test/lib/fixture-guard.sh"
  fixture_guard_init "$TMPDIR"
  RTL_ROOT="'"$FIX"'"
  RTL_ALLOW=("RELAY.md"); RTL_WT_USED=0
  wt="$(rtl_worktree_begin)" || exit 9
  require_fixture "$wt" isolated-worktree
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
require_fixture "$SRC" init-source
git -C "$SRC" init -q
printf '#!/usr/bin/env bash\nprintf "#!/bin/sh\\nexit 0\\n" > .git/hooks/pre-push\nchmod +x .git/hooks/pre-push\nexit 0\n' > "$SRC/githooks/install.sh"; chmod +x "$SRC/githooks/install.sh"
( cd "$SRC" && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1 )
BARE="$WORK/init-bare.git"; mkdir -p "$BARE"; require_fixture "$BARE" init-bare
git clone -q --bare "$SRC" "$BARE"
export XYZ_REGISTRY="$WORK/init-registry.tsv"
CL="$WORK/init-clones"
mkdir -p "$CL"; require_fixture "$CL" init-clones
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
import importlib.util, io, os, sys
sys.path.insert(0, os.path.dirname(sys.argv[1]))
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
# DEFAULT-stream contract for the zero-criteria warning as well.
python3 - "$PYPREFLIGHT" "$DBG/zout.txt" "$DBG/zerr.txt" <<'PYZ'
import importlib.util, os, sys
sys.path.insert(0, os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("swarm_preflight", sys.argv[1])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
out, err = open(sys.argv[2], "w"), open(sys.argv[3], "w")
_saved_out, sys.stdout = sys.stdout, out
_saved_err, sys.stderr = sys.stderr, err
mod.warn_zero_criteria("acceptance-section", [], "DOC.md", "text")
sys.stdout, sys.stderr = _saved_out, _saved_err
out.close(); err.close()
PYZ
grep -q "Acceptance section with no" "$DBG/zerr.txt" && ! grep -q "Acceptance section with no" "$DBG/zout.txt" \
  && pass "zero-criteria warning defaults to stderr (not stdout)" || fail "zero-criteria warning default stream wrong"
# ordering pin v2: the INDENTED runtime call inside main() must precede the dry-run exit — the
# column-0 `def warn_zero_criteria` line must NOT satisfy this (round-3 tautology fix).
call_line=$(grep -n '^    warn_zero_criteria(acc_mode' "$PYPREFLIGHT" | head -1 | cut -d: -f1)
dry_line=$(grep -n '^    if args.dry_run:' "$PYPREFLIGHT" | head -1 | cut -d: -f1)
[ -n "$call_line" ] && [ -n "$dry_line" ] && [ "$call_line" -lt "$dry_line" ] \
  && pass "zero-criteria runtime call (indented) precedes the dry-run exit" || fail "runtime call moved/removed relative to dry-run exit (call=$call_line dry=$dry_line)"
grep -q "Acceptance section with no " utils/swarm-preflight.sh 2>/dev/null \
  && fail "bash fallback was edited (frozen twin — keep fixes in the Python twin)" \
  || pass "frozen bash fallback untouched (GH-308)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer R1 — final fixture code review

VERDICT: PARKED
Basis: awaiting independent whole-file source review.

Review the COMPLETE current test/gh642-consumer-fruit.sh and its base diff, shared fixture guard/setup contracts (unchanged), negative-controls.py, shared plan/GH-665 adapter, CHANGELOG, and committed verification README/transcripts. The embedded artifact is the actual repaired suite, not a proposal. Review-only: do not run mutation-heavy tests or mutate Git/source in this valued clone; the harness owns the thread commit. Do not edit any artifact besides this thread. All tests were run in disposable full clones, never this clone or linked worktrees.

Grade guard-before-seed, checked construction/substitution under Bash 3.2, physical path ownership at writes/cleanup, five refusal/caller-preservation cases, real worktree and RTL-copy coverage, bounded temporary roots, and negative-control validity. Sweep pre-existing writes in the whole touched file; report any remaining safety defect with exact source citations. Preserve source/test scope: one existing test plus witness/evidence/docs/CLI ledger receipts, no runtime/shared-guard/setup/frozen-twin changes. Use commensurate QA, not speculative OS sandbox/process supervision requirements.

Definition of Done: code safe within the existing owned-fixture contract, unchanged real feature assertions, original-base red and repaired 62/62, guard-disabled and caller-damage controls failing at the intended assertions, static/full fixture gate receipts auditable with source/hash/exit provenance and clone identity preserved. Read the current README for gate status and exact pins. Combined #669 verification is a separate conditional integration record, not qualification of its published draft; its pending run is not a code-review blocker for this fixture-only repair. Neither merging, promotion, closing issues nor #661 resumption is authorized. PASS means bounded fixture code Approved, not these separate permissions. Give graded precise blockers if unsatisfied; cap3.

### Reviewer R1 — codex final source QA

VERDICT: PASS
Basis: bounded fixture repair satisfies the Producer R1 Definition of Done within the existing owned-fixture contract. Whole current suite, shared guard/setup, negative-control witness, shared plan/adapter, CHANGELOG and retained transcripts reviewed. No remaining pre-existing safety defect found in the touched suite. This is source/evidence review, not a new test run or permission to merge/promote/close issues/resume #661.

swept file: yes

- [Pass] Construction and seeding fail closed under the Bash 3.2 command-substitution semantics: invalid names refuse, mkdir/init have explicit failure returns, physical ownership is checked before init, and both mkrepo substitutions are checked before guarded writes (test/gh642-consumer-fruit.sh:24–35, :59–61, :71–74, :120–122). The explicit checks do not rely on inherited errexit. Fix: none.
- [Pass] All five controlled faults assert exit 2 plus caller HEAD/git-dir/bare state/clean tree preservation (test/gh642-consumer-fruit.sh:40–68). The caller remains inside the outer owned sandbox while outside guard-root; the symlink control therefore cannot reach a valued checkout. Fix: none.
- [Pass] Whole-file write/cleanup sweep: bare, linked-worktree, separate-git-dir, non-git, stub, RTL and init-clone fixture targets are guarded descendants before their dangerous uses; warning output uses a checked mktemp under WORK; RTL uses a separately guarded temporary root and guards its returned worktree before marker writes/removal (test/gh642-consumer-fruit.sh:86–116, :144–146, :167–169, :212–250). Shared require_fixture physically resolves traversal/symlinks and exits 2 on refusal (test/lib/fixture-guard.sh, quoted span: “OUTSIDE the resolved fixture root”). No speculative concurrent path replacement threat model added. Fix: none.
- [Pass] Real feature coverage retained: seed precedes push/clone/worktree add, and RTL marker checks test copy isolation (test/gh642-consumer-fruit.sh:71–99, :225–237). Nonempty baseline.log ends “worktree fixture not created”; repaired.log ends “62 pass, 0 fail” and includes linked-worktree and ROOT copy assertions. Fix: none.
- [Pass] Negative controls mutate the actual suite in memory, require a unique anchor, preserve the original Bash $0, and propagate its exit status (TESTS-RESULTS/2026-09-17+GH-653-GH-665/negative-controls.py:12–27). guard-disabled.log records “fixture guard accepted symlink (rc=0)”; caller-damaged.log records “caller changed after empty”. Both log source hashes match the current suite hash independently read this turn: 38be8fac37eb657ec65d174e77d502f1b26b4916bbc249d3d5e046131c8d4f09. Witness hash also matches README: c3f53eb85350410c52682a370b89df24821e83ca20c21e567af0eb79f54c99e6. Fix: none.
- [Pass] Retained static/full gate evidence is consistent with the bounded approval: ci-fast.log pins HEAD 82f786f9 and explicitly skips the full suite; prepush.log:295 records this suite rc=0, :439 records unchanged runner identity/tree/worktrees/lock, :449 records 393/393, and :843 records normal gated push GREEN. README.md:9–33 supplies source pins and exit attribution; :44–53 preserves pending hosted/combined qualification boundaries. Fix: none.
- [Nit] The Setup Definition of Done still says “<fill in the acceptance criteria the Reviewer grades against>”; Producer R1 supplies the actual criteria. Fix: use those criteria in Setup when scaffolding future relays; no source change required.

Review limits: no Git commands, base diff extraction, test execution or external live PR-state verification performed, as required by this turn's containment instructions. Original-base behavior and unchanged-scope claims are assessed from the retained evidence and cited source, not independently retrieved Git history. No artifact/source edits made; harness owns the relay commit.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
