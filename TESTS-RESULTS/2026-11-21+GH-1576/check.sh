#!/usr/bin/env bash
# GH-1576 manual red/green witness. NOT a suite (GH-831): run by hand, output kept beside it.
#
#   check.sh <label> <code-rev> <source-clone> <out-dir>
#
# Builds a disposable local bare origin from <source-clone>, then drives each changed push boundary
# from FRESH clones that never ran `githooks/install.sh` (hooks do not travel with a clone). The
# code under test is <code-rev> checked out in its own scratch clone: red = the base revision,
# green = the changed revision. Per boundary it records the origin ref before and after, the exit
# status / returned value, `install.sh --check`, and whether git ran hooks/pre-push (GIT_TRACE).
# The hook-ran runs set XYZ_SKIP_PREPUSH=1, so they prove the stub was INVOKED, not that a gate
# passed; one real-gate run is recorded separately (see README.md).
set -uo pipefail
LABEL="$1"; REV="$2"; SRC="$3"; OUT="$4"
W="$(mktemp -d "${TMPDIR:-/tmp}/gh1576-$LABEL.XXXXXX")"
mkdir -p "$OUT"
LOG="$OUT/$LABEL.log"; PROV="$OUT/provenance.jsonl"; : > "$LOG"
say() { printf '%s\n' "$*" | tee -a "$LOG"; }
git clone -q --bare "$SRC" "$W/origin.git"
git clone -q "$W/origin.git" "$W/code" && git -C "$W/code" checkout -q "$REV" || { say "cannot check out $REV"; exit 2; }
CODE="$W/code"; ORIGIN="$W/origin.git"
REVSHA="$(git -C "$CODE" rev-parse HEAD)"
say "== $LABEL: code rev $REVSHA, scratch $W =="

oref() { git --git-dir="$ORIGIN" rev-parse --verify -q "refs/heads/$1" || echo none; }
chk()  { (cd "$1" && bash githooks/install.sh --check >/dev/null 2>&1); echo $?; }
newclone() { git clone -q "$ORIGIN" "$W/$1"; git -C "$W/$1" config user.name witness; git -C "$W/$1" config user.email w@w; git -C "$W/$1" checkout -q development; }
hookran() { if [ -f "$1" ]; then grep -c 'hooks/pre-push' "$1" || true; else echo 0; fi; }
record() { # boundary scenario rc detail before after check traced
  python3 - "$LABEL" "$REVSHA" "$@" >> "$PROV" <<'PY'
import json, sys
k = ["label", "code_rev", "boundary", "scenario", "result", "detail", "origin_before", "origin_after", "install_check_rc", "pre_push_invocations"]
print(json.dumps(dict(zip(k, sys.argv[1:])), sort_keys=True))
PY
  say "  [$1 / $2] result=$3 origin $5 -> $6 install-check-rc=$7 pre-push-invocations=$8 :: $4"
}

SAMPLE="$SRC/TESTS-RESULTS/2026-11-19+kickstart-a6590cb2/run-record.md"
KS="$CODE/skills/1-hourly/kickstart/scripts/run_record.py"

# ---- kickstart `checkpoint --push` ---------------------------------------------------------
ks() { # name branch scenario [ENV=val ...]
  local n="$1" b="$2" sc="$3"; shift 3
  local before after rc out t="$W/trace-$n.log"
  before="$(oref "$b")"
  out="$(env GIT_TRACE="$t" "$@" python3 "$KS" checkpoint --record "$SAMPLE" --clone "$W/$n" --primary "$SRC" --branch "$b" --dest "runs/gh1576-$n.md" --push 2>&1)"; rc=$?
  after="$(oref "$b")"
  record "kickstart:590 checkpoint --push" "$sc" "rc=$rc" "$(printf '%s' "$out" | tr '\n' ' ' | cut -c1-230)" "$before" "$after" "$(chk "$W/$n")" "$(hookran "$t")"
}
newclone k1; ks k1 gh1576-k1 "unwired clone"
newclone k2; (cd "$W/k2" && bash githooks/install.sh >/dev/null 2>&1); ks k2 gh1576-k2 "wired after install" XYZ_SKIP_PREPUSH=1
ks k2 gh1576-k2 "rerun, head already pushed" XYZ_SKIP_PREPUSH=1
newclone k3; git -C "$W/k3" rm -q githooks/install.sh && git -C "$W/k3" commit -q -m "drop installer"; ks k3 gh1576-k3 "installer missing"

# ---- merge-cleanup: push_resolved_head, provisioning, post-merge writes --------------------
MC_DIR="$CODE/skills/2-daily/merge-cleanup/scripts"
mc() { # scenario-name clone-dir mode
  python3 - "$MC_DIR" "$W" "$ORIGIN" "$@" <<'PY'
import os, subprocess, sys, tempfile
from pathlib import Path
mc_dir, W, origin, scen, mode = sys.argv[1:6]
sys.path.insert(0, mc_dir)
import merge_cleanup as mc
def git(*a, cwd=None): return subprocess.run(["git", *a], cwd=cwd, capture_output=True, text=True)
def oref(b):
    r = subprocess.run(["git", "--git-dir", origin, "rev-parse", "--verify", "-q", f"refs/heads/{b}"], capture_output=True, text=True)
    return r.stdout.strip() or "none"
def chk(c): return subprocess.run(["bash", "githooks/install.sh", "--check"], cwd=str(c), capture_output=True).returncode
def hooks(t): return open(t).read().count("hooks/pre-push") if os.path.exists(t) else 0
trace = f"{W}/trace-{scen}.log"
os.environ["GIT_TRACE"] = trace
if mode == "repair-unwired":            # a bare fresh clone, never wired
    subprocess.run(["git", "clone", "-q", origin, f"{W}/{scen}"], check=True); c = Path(f"{W}/{scen}")
    skip = False
elif mode == "repair-provisioned":      # a clone made by the tool's own provisioning step
    prim = Path(f"{W}/{scen}-primary"); subprocess.run(["git", "clone", "-q", origin, str(prim)], check=True)
    tip = git("rev-parse", "origin/development", cwd=str(prim)).stdout.strip()
    pr = {"number": 1, "headRefOid": tip, "headRefName": "development"}   # fetch fallback needs a real ref
    work = Path(tempfile.mkdtemp(prefix=scen, dir=W))
    prep = mc.prepare_landing_clone(pr, prim, "development", work)
    if not prep.get("clone") or prep.get("error"):
        print(f"RESULT=provisioning-refused DETAIL={' '.join(str(prep.get('error')).split())} BEFORE=none AFTER=none CHK=n/a HOOKS=0"); sys.exit(0)
    c = prep["clone"]; skip = True
if mode.startswith("repair"):
    for k, v in (("user.name", "w"), ("user.email", "w@w")): git("config", k, v, cwd=str(c))
    git("checkout", "-q", "--detach", "origin/development", cwd=str(c))
    Path(c, f"witness-{scen}.txt").write_text(scen + "\n"); git("add", ".", cwd=str(c)); git("commit", "-q", "-m", "repair", cwd=str(c))
    sha = git("rev-parse", "HEAD", cwd=str(c)).stdout.strip()
    pr = {"number": 1, "headRefOid": "x", "headRefName": "gh1576-" + scen}
    mc.refresh_pr = lambda n, p: {"state": "OPEN", "isDraft": False, "headRefOid": "x"}
    if skip: os.environ["XYZ_SKIP_PREPUSH"] = "1"
    before = oref("gh1576-" + scen)
    ok, msg = mc.push_resolved_head(pr, Path(c), sha, Path(c))
    after = oref("gh1576-" + scen)
    print(f"RESULT=ok={ok} DETAIL={" ".join(msg.split())[:200]} BEFORE={before} AFTER={after} CHK={chk(c)} HOOKS={hooks(trace)}")
else:                                    # post-merge writes (the :1534 push) on a primary-style clone
    subprocess.run(["git", "clone", "-q", origin, f"{W}/{scen}"], check=True); c = Path(f"{W}/{scen}")
    git("checkout", "-q", "development", cwd=str(c))
    for k, v in (("user.name", "w"), ("user.email", "w@w")): git("config", k, v, cwd=str(c))
    if mode == "post-wired":
        subprocess.run(["bash", "githooks/install.sh"], cwd=str(c), capture_output=True); os.environ["XYZ_SKIP_PREPUSH"] = "1"
    Path(c, f"witness-{scen}.txt").write_text(scen + "\n")
    before = oref("development")
    ok = mc.commit_and_push_phase5_writes(0, Path(c), "development", commit_msg="chore: gh1576 witness")
    after = oref("development")
    print(f"RESULT=ok={ok} DETAIL=post-merge-writes BEFORE={before} AFTER={after} CHK={chk(c)} HOOKS={hooks(trace)}")
PY
}
mcrec() { # boundary scenario <python output line>
  local line="$3" f; case "$line" in RESULT=*) ;; *) say "  RAW[$1 / $2]: $line";; esac
  f() { printf '%s' "$line" | sed -n "s/.*$1=\\([^ ]*\\).*/\\1/p"; }
  record "$1" "$2" "$(f RESULT)" "$(printf '%s' "$line" | sed -n 's/.*DETAIL=\(.*\) BEFORE=.*/\1/p')" "$(f BEFORE)" "$(f AFTER)" "$(f CHK)" "$(f HOOKS)"
}
mcrec "merge-cleanup:1048 push_resolved_head" "unwired clone"            "$(mc m1 repair-unwired 2>&1 | tail -1)"
mcrec "merge-cleanup:964+1048 provisioning then repair push" "tool-provisioned clone" "$(mc m2 repair-provisioned 2>&1 | tail -1)"
mcrec "merge-cleanup:1534 post-merge writes" "unwired clone"             "$(mc p1 post-unwired 2>&1 | tail -1)"
mcrec "merge-cleanup:1534 post-merge writes" "wired clone"               "$(mc p2 post-wired 2>&1 | tail -1)"

# ---- jog: the guard both pushes call (publish_jog_receipt:1209, _push:2320) ----------------
newclone j1; newclone j2; (cd "$W/j2" && bash githooks/install.sh >/dev/null 2>&1); newclone j3; rm -f "$W/j3/githooks/install.sh"
jog() { python3 - "$CODE/utils/py" "$1" <<'PY'
import sys; sys.path.insert(0, sys.argv[1]); import jog_run
g = getattr(jog_run, "_require_gate_wired", None)
if g is None: print("RESULT=no-guard-exists DETAIL=jog_run has no gate check before its pushes"); sys.exit(0)
try: g(sys.argv[2]); print("RESULT=allowed DETAIL=guard returned")
except jog_run.ContractError as e: print("RESULT=refused DETAIL=" + " ".join(str(e).split())[:160])
PY
}
for pair in "j1:unwired clone" "j2:wired clone" "j3:installer missing"; do
  n="${pair%%:*}"; line="$(jog "$W/$n" 2>&1 | tail -1)"
  record "jog:1209,2320 guard" "${pair#*:}" "$(printf '%s' "$line" | sed -n 's/RESULT=\([^ ]*\).*/\1/p')" "$(printf '%s' "$line" | sed -n 's/.*DETAIL=//p')" n/a n/a "$(chk "$W/$n")" n/a
done

# jog `_push` (:2320) driven for real: JogCheckpoint._push on a publication clone, bypassing only its journal.
jp() { # name wired?
  local n="$1" t="$W/trace-$1.log" before after line
  newclone "$n-root"; newclone "$n"; [ "$2" = yes ] && (cd "$W/$n" && bash githooks/install.sh >/dev/null 2>&1)
  git -C "$W/$n-root" config user.name w; git -C "$W/$n-root" config user.email w@w
  echo "$n" > "$W/$n-root/jog-$n.txt"; git -C "$W/$n-root" add . && git -C "$W/$n-root" commit -q -m "jog checkpoint $n"
  local commit; commit="$(git -C "$W/$n-root" rev-parse HEAD)"; before="$(oref development)"
  line="$(env GIT_TRACE="$t" XYZ_SKIP_PREPUSH=1 python3 - "$CODE/utils/py" "$W/$n-root" "$W/$n" "$commit" <<'PY' 2>&1 | tail -1
import sys; sys.path.insert(0, sys.argv[1]); import jog_run
o = jog_run.JogCheckpoint.__new__(jog_run.JogCheckpoint); o.root, o.publication = sys.argv[2], sys.argv[3]; o.check_publication = lambda: None
try: o._push(sys.argv[4]); print("RESULT=pushed DETAIL=JogCheckpoint._push returned")
except jog_run.ContractError as e: print("RESULT=refused DETAIL=" + " ".join(str(e).split())[:160])
PY
)"
  after="$(oref development)"
  record "jog:2320 JogCheckpoint._push" "$3" "$(printf '%s' "$line" | sed -n 's/RESULT=\([^ ]*\).*/\1/p')" "$(printf '%s' "$line" | sed -n 's/.*DETAIL=//p')" "$before" "$after" "$(chk "$W/$n")" "$(hookran "$t")"
}
jp jp1 no "unwired publication clone"
jp jp2 yes "wired publication clone (XYZ_SKIP_PREPUSH=1: stub invoked, not a gate result)"

# ---- express closeout push (:1284) ---------------------------------------------------------
ex() { # name wired? -> run persist_closeout from an express clone
  local n="$1" t="$W/trace-$1.log" before after line
  newclone "$n"; [ "$2" = yes ] && (cd "$W/$n" && bash githooks/install.sh >/dev/null 2>&1)
  mkdir -p "$W/$n/TESTS-RESULTS/gh1576-$n"; echo "$n" > "$W/$n/TESTS-RESULTS/gh1576-$n/receipt.md"
  before="$(oref development)"
  line="$(env GIT_TRACE="$t" python3 - "$CODE/utils/py" "$W/$n" "TESTS-RESULTS/gh1576-$n/receipt.md" <<'PY' 2>&1 | tail -1
import sys; sys.path.insert(0, sys.argv[1]); import express as ex
try:
    ok = ex.persist_closeout(sys.argv[2], "chore: gh1576 witness", extra_paths=(sys.argv[3],)); print("RESULT=ok=%s DETAIL=closeout persisted" % ok)
except SystemExit as e: print("RESULT=refused DETAIL=exit %s" % e.code)
PY
)"
  after="$(oref development)"
  record "express:1284 closeout" "$3" "$(printf '%s' "$line" | sed -n 's/RESULT=\([^ ]*\).*/\1/p')" "$(printf '%s' "$line" | sed -n 's/.*DETAIL=//p')" "$before" "$after" "$(chk "$W/$n")" "$(hookran "$t")"
}
ex e1 no "unwired clone"
ex e2 yes "wired clone (express's own push sets XYZ_SKIP_PREPUSH, so this is wiring evidence only)"
say "== $LABEL done; provenance appended to $PROV =="
