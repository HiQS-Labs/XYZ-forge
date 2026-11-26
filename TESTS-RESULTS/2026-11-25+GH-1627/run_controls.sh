#!/usr/bin/env bash
# GH-1627 manual controls — NOT a suite, not registered in validate.sh (AGENTS.md "No new tests", GH-831).
# Runs the plan's (a)-(f) rows against BASE and CANDIDATE in ONE disposable full clone, then writes
# summary.txt and provenance.jsonl beside this script's evidence dir.
#
#   run_controls.sh <qualification-clone> <evidence-dir> <base-sha> [rows]     rows: space list of a b c d e f (default all)
#
# Honest "failing python3": the real Homebrew python3 (3.14, no mypy) first on PATH — the reported incident, no shim.
# The prepared venv is the real ~/.cache/xyz-forge-test-venv. Mutating runs happen only in the clone.
set -u
CLONE="$1"; OUT="$2"; BASE="$3"; ROWS="${4:-a b c d e f}"
VENV_BIN="$HOME/.cache/xyz-forge-test-venv/bin"
FAIL_PATH="/opt/homebrew/bin:$PATH"           # python3 here is the toolchain-less Homebrew 3.14
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh1627-controls.XXXXXX")"
mkdir -p "$OUT/raw" "$WORK/emptyhome" "$WORK/badhome/.cache/xyz-forge-test-venv/bin" "$WORK/healthybin" "$WORK/bare"
printf '#!/usr/bin/env bash\nexit 1\n' > "$WORK/badhome/.cache/xyz-forge-test-venv/bin/python3"; chmod +x "$WORK/badhome/.cache/xyz-forge-test-venv/bin/python3"
# healthy python3 at a path distinct from the venv; logs every call, then runs the venv interpreter (venv resolved via its own bin).
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/healthy.calls"\nexec "%s/python3" "$@"\n' "$WORK" "$VENV_BIN" > "$WORK/healthybin/python3"; chmod +x "$WORK/healthybin/python3"
git init -q --bare "$WORK/bare"
SUMMARY="$OUT/summary.txt"; : > "$SUMMARY"; PROV="$OUT/provenance.jsonl"
pass=0; fail=0
CAND="$(git -C "$CLONE" rev-parse HEAD)"
want() { case " $ROWS " in *" $1 "*) return 0;; esac; return 1; }
rec() { # id desc rc outfile sha
  python3 - "$@" <<'PY' >> "$PROV"
import hashlib,json,sys,datetime
i,d,rc,f,sha=sys.argv[1:6]
h=hashlib.sha256(open(f,'rb').read()).hexdigest() if f and __import__('os').path.exists(f) else None
print(json.dumps({"ts":datetime.datetime.utcnow().isoformat()+"Z","id":i,"desc":d,"rc":int(rc),"output":f.split('/TESTS-RESULTS/')[-1] if f else None,"output_sha256":h,"checkout":sha}))
PY
}
check() { # id description condition-rc
  if [ "$3" -eq 0 ]; then pass=$((pass+1)); echo "PASS $1: $2" | tee -a "$SUMMARY"; else fail=$((fail+1)); echo "FAIL $1: $2" | tee -a "$SUMMARY"; fi
}
run() { # id desc env-prefix-words -- command...   (stdout+stderr -> raw/<id>.out ; rc in $RC)
  local id="$1" desc="$2"; shift 2
  local f="$OUT/raw/$id.out"
  ( cd "$CLONE" && env "$@" ) > "$f" 2>&1; RC=$?
  rec "$id" "$desc" "$RC" "$f" "$(git -C "$CLONE" rev-parse --short HEAD)"
}
ctx() { # fresh attempt context for a nested run (gh251 technique): prints export line value
  ( cd "$CLONE" && python3 utils/py/gate_receipt.py attempt-start --repo "$CLONE" --accounting-root "$WORK" --task "$1" ) 2>/dev/null
}
co() { git -C "$CLONE" checkout -q --detach "$1"; }
PATHS_FILE="$WORK/paths.txt"; printf 'skills/3-weekly/skills-army-hq/scripts/sync.py\n' > "$PATHS_FILE"

echo "# GH-1627 controls — base=$BASE candidate=$CAND clone=$CLONE $(date -u +%FT%TZ)" | tee -a "$SUMMARY"
echo "# failing python3: $(PATH="$FAIL_PATH" python3 --version 2>&1) at $(PATH="$FAIL_PATH" command -v python3); venv: $("$VENV_BIN/python3" --version 2>&1)" | tee -a "$SUMMARY"

for side in base cand; do
  if [ "$side" = base ]; then co "$BASE"; else co "$CAND"; fi
  # ---- a: failing python3 + healthy venv ----------------------------------------------------------
  if want a; then
    run "a-printmode-$side" "a: failing python3 first, real venv present: validate.sh --print-mode ($side)" PATH="$FAIL_PATH" bash validate.sh --print-mode
    echo "$RC" > "$WORK/a-pm-$side.rc"
    C="$(ctx "gh1627-a-$side")"
    run "a-tier2-$side" "a: failing python3 first, real venv present: tier-2 run (skills-army-hq paths) ($side)" PATH="$FAIL_PATH" XYZ_ATTEMPT_CONTEXT="$C" bash validate.sh --paths-file "$PATHS_FILE"
    echo "$RC" > "$WORK/a-t2-$side.rc"
  fi
  # ---- b1/b2: venv missing / failing: output must equal base --------------------------------------
  if want b; then
    run "b1-$side" "b1: failing python3 first, venv missing ($side)" HOME="$WORK/emptyhome" PATH="$FAIL_PATH" bash validate.sh --print-mode
    echo "$RC" > "$WORK/b1-$side.rc"
    run "b2-$side" "b2: failing python3 first, venv present but failing ($side)" HOME="$WORK/badhome" PATH="$FAIL_PATH" bash validate.sh --print-mode
    echo "$RC" > "$WORK/b2-$side.rc"
  fi
  # ---- c: healthy python3 at a distinct path, real venv also present ------------------------------
  if want c; then
    : > "$WORK/healthy.calls"
    run "c-printmode-$side" "c: healthy python3 at a distinct path first, venv present: --print-mode ($side)" PATH="$WORK/healthybin:$PATH" bash validate.sh --print-mode
    echo "$RC" > "$WORK/c-$side.rc"; cp "$WORK/healthy.calls" "$OUT/raw/c-healthy-calls-$side.txt"
  fi
  # ---- e: merge-cleanup's own pre-flight probe ----------------------------------------------------
  if want e; then
    e_probe() { # name home path
      run "e-$1-$side" "e($1): merge_cleanup.gate_toolchain_fault_reason ($side)" HOME="$2" PATH="$3" \
        "$VENV_BIN/python3" -c "import sys; from pathlib import Path; sys.path.insert(0,'skills/2-daily/merge-cleanup/scripts'); import merge_cleanup as m; print('REASON=' + repr(m.gate_toolchain_fault_reason(Path('.'))))"
    }
    e_probe a "$HOME" "$FAIL_PATH"
    e_probe b1 "$WORK/emptyhome" "$FAIL_PATH"
    e_probe b2 "$WORK/badhome" "$FAIL_PATH"
    e_probe c "$HOME" "$WORK/healthybin:$PATH"
  fi
done

if want a; then
  b="$OUT/raw/a-printmode-base.out"; c="$OUT/raw/a-printmode-cand.out"
  [ "$(cat "$WORK/a-pm-base.rc")" -eq 3 ] && grep -q "ENVIRONMENT FAULT: python3" "$b"; check a-base-red "base --print-mode exits 3 with the fault (red control)" $?
  [ "$(cat "$WORK/a-pm-cand.rc")" -eq 0 ] && [ "$(grep -c 'GH-1627' "$c")" -eq 1 ] && grep -q "using $VENV_BIN/python3" "$c" && ! grep -q "ENVIRONMENT FAULT: python3" "$c"; check a-cand-printmode "cand --print-mode exits 0, exactly one GH-1627 notice naming the venv python" $?
  [ "$(cat "$WORK/a-t2-base.rc")" -eq 3 ] && ! grep -q "Running python3 -m pytest" "$OUT/raw/a-tier2-base.out"; check a-base-tier2 "base tier-2 run exits 3 before any suite" $?
  [ "$(cat "$WORK/a-t2-cand.rc")" -eq 0 ] && [ "$(grep -c 'GH-1627' "$OUT/raw/a-tier2-cand.out")" -eq 1 ] \
    && grep -q "Running python3 -m pytest" "$OUT/raw/a-tier2-cand.out" && grep -q "+ python:test_python_layer.py" "$OUT/raw/a-tier2-cand.out"; check a-cand-tier2 "cand tier-2 run exits 0, one notice, pytest layer ran and passed" $?
  grep -Eq "Python 3\.12\.[0-9]+" "$OUT/raw/a-tier2-cand.out"; check a-cand-venv-child "a suite child reports the venv's Python 3.12 (pytest header)" $?
fi
if want b; then
  for n in b1 b2; do
    [ "$(cat "$WORK/$n-base.rc")" -eq 3 ] && [ "$(cat "$WORK/$n-cand.rc")" -eq 3 ] && cmp -s "$OUT/raw/$n-base.out" "$OUT/raw/$n-cand.out"; check "$n" "$n: base and candidate stdout+stderr byte-identical, both exit 3" $?
  done
  grep -q "version 3.14" "$OUT/raw/b2-cand.out" && ! grep -q "$WORK/badhome" "$OUT/raw/b2-cand.out"; check b2-names-path "b2: fault names the PATH interpreter (3.14), not the failing venv" $?
fi
if want c; then
  [ "$(cat "$WORK/c-base.rc")" -eq 0 ] && [ "$(cat "$WORK/c-cand.rc")" -eq 0 ] && cmp -s "$OUT/raw/c-printmode-base.out" "$OUT/raw/c-printmode-cand.out" && ! grep -q "GH-1627" "$OUT/raw/c-printmode-cand.out"; check c "c: healthy distinct python3: identical output, no notice, exit 0" $?
  [ -s "$OUT/raw/c-healthy-calls-cand.txt" ]; check c-used-path-python "c: the PATH python3 (not the venv path) answered the probe calls" $?
fi
if want e; then
  grep -q "REASON='.*ENVIRONMENT FAULT" "$OUT/raw/e-a-base.out"; check e-a-base "e(a) base: probe returns the fault line (red control)" $?
  grep -q "REASON=''" "$OUT/raw/e-a-cand.out"; check e-a-cand "e(a) cand: probe returns '' — landing is not deferred" $?
  for n in b1 b2; do
    grep -q "REASON='.*ENVIRONMENT FAULT" "$OUT/raw/e-$n-cand.out" && cmp -s "$OUT/raw/e-$n-base.out" "$OUT/raw/e-$n-cand.out"; check "e-$n" "e($n): probe returns the same fault line as base" $?
  done
  grep -q "REASON=''" "$OUT/raw/e-c-base.out" && grep -q "REASON=''" "$OUT/raw/e-c-cand.out"; check e-c "e(c): healthy PATH python: '' on base and candidate" $?
fi

# ---- d: a real git push through the installed hook (full gate: a path-URL push classifies full) ---------
if want d; then
  git -C "$CLONE" remote remove bare 2>/dev/null; git -C "$CLONE" remote add bare "$WORK/bare"
  # base: BASE + a comment-only code change so the hook cannot take the docs route
  co "$BASE"; git -C "$CLONE" checkout -q -B d-base; printf '# gh1627 control (base push)\n' >> "$CLONE/skills/2-daily/merge-cleanup/scripts/merge_cleanup.py"
  git -C "$CLONE" -c user.name=ctl -c user.email=ctl@example.invalid commit -qam "gh1627 control: base push"
  C="$(ctx gh1627-d-base)"
  run d-base "d: real git push through the hook, failing python3 first, BASE gate" PATH="$FAIL_PATH" XYZ_ATTEMPT_CONTEXT="$C" git push bare d-base:refs/heads/d-base
  echo "$RC" > "$WORK/d-base.rc"
  git ls-remote "$WORK/bare" refs/heads/d-base > "$OUT/raw/d-base.lsremote" 2>&1
  [ "$(cat "$WORK/d-base.rc")" -ne 0 ] && [ ! -s "$OUT/raw/d-base.lsremote" ] && grep -q "ENVIRONMENT FAULT: python3" "$OUT/raw/d-base.out" && grep -q "RED (exit 3)" "$OUT/raw/d-base.out"; check d-base "d base: hook refuses (inner exit 3, fault line), remote ref not advanced (red control)" $?
  # candidate: push the candidate commit itself (it changes validate.sh, so the gate must run)
  co "$CAND"; git -C "$CLONE" checkout -q -B d-cand
  C="$(ctx gh1627-d-cand)"
  run d-cand "d: real git push through the hook, failing python3 first, CANDIDATE gate" PATH="$FAIL_PATH" XYZ_ATTEMPT_CONTEXT="$C" git push bare d-cand:refs/heads/d-cand
  echo "$RC" > "$WORK/d-cand.rc"
  git ls-remote "$WORK/bare" refs/heads/d-cand > "$OUT/raw/d-cand.lsremote" 2>&1
  [ "$(cat "$WORK/d-cand.rc")" -eq 0 ] && grep -q "GH-1627" "$OUT/raw/d-cand.out" && ! grep -q "ENVIRONMENT FAULT: python3" "$OUT/raw/d-cand.out" \
    && grep -q "full gate GREEN" "$OUT/raw/d-cand.out" && ! grep -q "reusing\|receipt for" "$OUT/raw/d-cand.out" && grep -q "$CAND" "$OUT/raw/d-cand.lsremote"; check d-cand "d cand: hook ran the full gate on the venv (notice, GREEN, no receipt reuse), push exit 0, ls-remote shows $CAND" $?
fi

# ---- f: existing suites ----------------------------------------------------------------------------------
if want f; then
  co "$BASE"
  for t in gh251-validate-pytest-skip gh732-l3-gate-summary; do
    run "f-$t-base" "f: $t on BASE (venv first on PATH, the old workaround)" PATH="$VENV_BIN:$PATH" bash "test/$t.sh"; echo "$RC" > "$WORK/f-$t-base.rc"
  done
  co "$CAND"
  for t in gh251-validate-pytest-skip gh732-l3-gate-summary gh268-relay-cue-and-target-checks gh436-merge-cleanup gh645-merge-cleanup-xyz-tools gh674-merge-cleanup-hosted-lookup; do
    [ -f "$CLONE/test/$t.sh" ] || { echo "SKIP f-$t: no such suite" | tee -a "$SUMMARY"; continue; }
    run "f-$t-cand" "f: $t on CANDIDATE (toolchain-less python3 first: relies on the selector)" PATH="$FAIL_PATH" bash "test/$t.sh"; echo "$RC" > "$WORK/f-$t-cand.rc"
    [ "$RC" -eq 0 ] && ! grep -q "FAIL" "$OUT/raw/f-$t-cand.out"; check "f-$t" "f: $t green on candidate" $?
  done
  [ "$(cat "$WORK/f-gh251-validate-pytest-skip-base.rc")" -eq 0 ] && ! grep -q "FAIL" "$OUT/raw/f-gh251-validate-pytest-skip-base.out"; check f-gh251-base "f: gh251 green on base" $?
  # why the HOME= isolation is needed: candidate selector + the UNADJUSTED gh251 on a machine that has the venv
  git -C "$CLONE" show "$BASE:test/gh251-validate-pytest-skip.sh" > "$CLONE/test/gh251-validate-pytest-skip.sh"
  run f-gh251-unadjusted "f: CANDIDATE selector + UNADJUSTED (base) gh251 with the venv present" PATH="$FAIL_PATH" bash test/gh251-validate-pytest-skip.sh
  git -C "$CLONE" checkout -q -- test/gh251-validate-pytest-skip.sh
  grep -q "FAIL" "$OUT/raw/f-gh251-unadjusted.out"; check f-gh251-unadjusted-red "f: the unadjusted gh251 goes red with the selector present (shows the HOME= edit is required)" $?
  run f-pdda "f: docs gate (pdda.sh run) on CANDIDATE" PATH="$FAIL_PATH" bash utils/pdda/pdda.sh run
  [ "$RC" -eq 0 ]; check f-pdda "f: pdda.sh run exits 0" $?
fi

echo "# done: $pass pass, $fail fail" | tee -a "$SUMMARY"
echo "$WORK" > "$OUT/raw/WORKDIR.txt"
exit $((fail > 0))
