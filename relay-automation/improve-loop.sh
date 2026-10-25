#!/usr/bin/env bash
# improve-loop.sh — the Part C champion/challenger hill-climb loop (#50).
#
# Composes the six primitives into the metric-driven optimization loop the LOOPS.md endgame describes:
#   oracle-guard.sh   pre-flight: the builder's write surface is disjoint from the oracle (un-gameable)
#   measure.sh        deterministic scalar metric (the thing we hill-climb)
#   heldout-check.sh  anti-gaming veto (visible gain + held-out loss = rejected)
#   champion.sh       accept-on-improve / rollback-on-regress / provenance
#   loop-stop.sh      guaranteed halt (target | cap | budget | plateau)
#   loop-cost.sh      honest per-iteration spend
#
# Each iteration: build a challenger (--build-cmd, pluggable — a real agent via marathon-drive, or any
# script that edits --artifact) -> oracle gate (--oracle-cmd) -> measure visible (+ held-out) ->
# anti-gaming veto -> champion judge. An ACCEPTED challenger becomes the champion (its --artifact kept
# + snapshotted); a REJECTED one is rolled back to the champion snapshot. A losing run therefore ships
# the champion, never a worse artifact (no-regress). Emits the champion metric + the provenance path.
#
# v1 optimizes a SINGLE tracked file (--artifact); snapshot/rollback is a file copy (no git commits).
# Usage:
#   improve-loop.sh --artifact F --measure-cmd CMD --oracle-cmd CMD --build-cmd CMD
#                   --max-iterations N [--goal max|min] [--state-dir D]
#                   [--target T] [--max-total-budget B] [--plateau K]
#                   [--held-cmd CMD] [--oracle-paths CSV] [--agent A] [--currency seconds|tokens]
# Exit: 0 ran to a halt (champion emitted) · 2 usage · 3 baseline failed the oracle · 4 pre-flight (oracle-guard) failed.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
MEASURE="$HERE/measure.sh"; ORACLEG="$HERE/oracle-guard.sh"; CHAMP="$HERE/champion.sh"
STOP="$HERE/loop-stop.sh"; HELD="$HERE/heldout-check.sh"; COST="$HERE/loop-cost.sh"

ARTIFACT="" MEASURE_CMD="" ORACLE_CMD="" BUILD_CMD="" HELD_CMD=""
GOAL=max MAXIT="" TARGET="" MAXBUD=0 PLATEAU=0 STATE_DIR="" ALLOW="" ORACLE_PATHS="" AGENT=loop CURRENCY=seconds
while [ $# -gt 0 ]; do
  case "$1" in
    --artifact) ARTIFACT="${2:-}"; shift 2 ;;
    --measure-cmd) MEASURE_CMD="${2:-}"; shift 2 ;;
    --oracle-cmd) ORACLE_CMD="${2:-}"; shift 2 ;;
    --build-cmd) BUILD_CMD="${2:-}"; shift 2 ;;
    --held-cmd) HELD_CMD="${2:-}"; shift 2 ;;
    --goal) GOAL="${2:-max}"; shift 2 ;;
    --max-iterations) MAXIT="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --max-total-budget) MAXBUD="${2:-0}"; shift 2 ;;
    --plateau) PLATEAU="${2:-0}"; shift 2 ;;
    --state-dir) STATE_DIR="${2:-}"; shift 2 ;;
    --allow) ALLOW="${2:-}"; shift 2 ;;
    --oracle-paths) ORACLE_PATHS="${2:-}"; shift 2 ;;
    --agent) AGENT="${2:-loop}"; shift 2 ;;
    --currency) CURRENCY="${2:-seconds}"; shift 2 ;;
    -h|--help) /usr/bin/grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "improve-loop.sh: unexpected arg: $1" >&2; exit 2 ;;
  esac
done
for req in ARTIFACT MEASURE_CMD ORACLE_CMD BUILD_CMD MAXIT; do
  eval "v=\${$req}"; [ -n "$v" ] || { echo "improve-loop.sh: --$(echo "$req" | tr A-Z_ a-z- | sed 's/^-//') is required" >&2; exit 2; }
done
[ -f "$ARTIFACT" ] || { echo "improve-loop.sh: --artifact not found: $ARTIFACT" >&2; exit 2; }
# The halt guarantee: --max-iterations must be a positive integer HERE (not just non-empty) — otherwise
# loop-stop.sh would exit 2 every tick and the while-loop would spin forever (it's the backstop that
# fires when nothing else does). Validate at the orchestrator, fail closed.
printf '%s' "$MAXIT" | /usr/bin/grep -qE '^[0-9]+$' && [ "$MAXIT" -ge 1 ] \
  || { echo "improve-loop.sh: --max-iterations must be a positive integer (the halt guarantee) — got '$MAXIT'" >&2; exit 2; }
case "$GOAL" in max|min) ;; *) echo "improve-loop.sh: --goal must be max|min" >&2; exit 2 ;; esac
# Fail closed on an un-enforceable budget: token spend is uncounted for the cost-blind agy lane
# (loop-cost emits a floor), so a token budget could silently never fire. Refuse the combination.
if [ "$MAXBUD" != 0 ] && [ "$CURRENCY" = tokens ] && [ "$AGENT" = agy ]; then
  echo "improve-loop.sh: cannot enforce --max-total-budget in tokens for the cost-blind agy lane — use --currency seconds" >&2; exit 2
fi
ALLOW="${ALLOW:-$ARTIFACT}"
# GH-430: the loop's only audit trail (provenance.jsonl) must survive the run. A process-scoped
# ${TMPDIR:-/tmp} default evaporates the moment the process exits, so proof cited in an issue/PR/
# ROADMAP entry can never be checked later. Default into a TRACKED in-repo path instead — NOT under
# .tick/ (gitignored, so rtl_enforce gives it zero containment protection per GH-396) and NOT under
# any other gitignored directory. An explicit --state-dir still wins (parsed above, ~line 45).
STATE_DIR="${STATE_DIR:-$HERE/state/improve-loop.$$}"
mkdir -p "$STATE_DIR"
SNAP="$STATE_DIR/champion.artifact"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$REPO_ROOT" ]; then
  _r_phys="$(cd "$REPO_ROOT" 2>/dev/null && pwd -P)"
  _a_phys="$(cd "$(dirname "$ARTIFACT")" 2>/dev/null && pwd -P)/$(basename "$ARTIFACT")"
  case "$_a_phys" in
    "$_r_phys"/*) ;;
    *)
      _a_top="$(git -C "$(dirname "$ARTIFACT")" rev-parse --show-toplevel 2>/dev/null || true)"
      REPO_ROOT="$_a_top"
      ;;
  esac
fi
if [ -z "$REPO_ROOT" ]; then
  # GH-1221: run from outside Git — guard the repository that holds the artifact instead.
  REPO_ROOT="$(git -C "$(dirname "$ARTIFACT")" rev-parse --show-toplevel 2>/dev/null || true)"
fi

# GH-1221: pre/post-build snapshot, content manifest, and off-ALLOW violation check + restore.
# Captures git status --porcelain -z --untracked-files=all --ignored AND a NUL-safe content+mode
# manifest + byte backup for every pre-existing path outside ALLOW and outside STATE_DIR.
il_build_guard() {
  [ -n "$REPO_ROOT" ] || return 0
  python3 - "$1" "$REPO_ROOT" "$STATE_DIR" "$ALLOW" <<'PYEOF'
import os, sys, subprocess, hashlib, shutil, json

mode, root_arg, state_arg, allow_csv = sys.argv[1:5]
root = os.path.realpath(root_arg)
state_real = os.path.realpath(state_arg)
snap_dir = os.path.join(state_arg, ".gh1221_snap")

state_rel = None
if state_real == root:
    state_rel = ""
elif state_real.startswith(root + os.sep):
    state_rel = state_real[len(root) + 1:].replace(os.sep, "/")

allow_entries = []
for raw in allow_csv.split(","):
    s = raw.strip()
    if not s:
        continue
    has_glob = any(c in s for c in "*?[")
    trailing_slash = s.endswith("/")
    p_abs = os.path.abspath(s)
    p_real = os.path.realpath(p_abs)
    for cand in (p_real, p_abs):
        if cand == root:
            rel = ""
        elif cand.startswith(root + os.sep):
            rel = cand[len(root) + 1:].replace(os.sep, "/")
        else:
            continue
        is_dir = trailing_slash or (not has_glob and os.path.isdir(cand))
        allow_entries.append((rel.rstrip("/"), is_dir, has_glob))

def glob_match(rel, pat):
    re_s = "^"
    i = 0
    while i < len(pat):
        ch = pat[i]
        if ch == "*":
            if i + 1 < len(pat) and pat[i + 1] == "*":
                re_s += ".*"
                i += 1
                if i + 1 < len(pat) and pat[i + 1] == "/":
                    i += 1
            else:
                re_s += "[^/]*"
        elif ch == "?":
            re_s += "[^/]"
        elif ch in ".+^$()[]{}|\\":
            re_s += "\\" + ch
        else:
            re_s += ch
        i += 1
    re_s += "$"
    import re
    return bool(re.match(re_s, rel))

def is_exempt(rel):
    rel = rel.rstrip("/")
    if rel == ".git" or rel.startswith(".git/"):
        return True
    if state_rel is not None:
        if state_rel == "" or rel == state_rel or rel.startswith(state_rel + "/"):
            return True
    for a_rel, is_dir, has_glob in allow_entries:
        if a_rel == "":
            return True
        if has_glob:
            if glob_match(rel, a_rel):
                return True
        elif is_dir:
            if rel == a_rel or rel.startswith(a_rel + "/"):
                return True
        else:
            if rel == a_rel:
                return True
    return False

def is_allow_ancestor(rel):
    """A directory that only exists to hold an allowed path is structure, not an off-ALLOW write."""
    rel = rel.rstrip("/")
    for a_rel, is_dir, has_glob in allow_entries:
        if has_glob:
            lit = a_rel[:min([i for i, c in enumerate(a_rel) if c in "*?["] or [len(a_rel)])]
            lit = lit.rsplit("/", 1)[0] if "/" in lit else ""
            if not lit or rel == lit or lit.startswith(rel + "/"):
                return True
        elif a_rel and a_rel.startswith(rel + "/"):
            return True
    return False

def get_porcelain():
    p = subprocess.run(
        ["git", "-C", root, "status", "--porcelain", "-z", "--untracked-files=all", "--ignored"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    if p.returncode != 0:
        sys.exit(1)
    return p.stdout

def get_tracked():
    p = subprocess.run(
        ["git", "-C", root, "ls-files", "-z"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    if p.returncode != 0:
        sys.exit(1)
    return [x.decode("utf-8", errors="surrogateescape") for x in p.stdout.split(b"\0") if x]

def get_index_stage_map():
    p = subprocess.run(
        ["git", "-C", root, "ls-files", "--stage", "-z"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    if p.returncode != 0:
        sys.exit(1)
    out = {}
    for rec in p.stdout.split(b"\0"):
        if not rec or b"\t" not in rec:
            continue
        meta, path_b = rec.split(b"\t", 1)
        path = path_b.decode("utf-8", errors="surrogateescape")
        out.setdefault(path, []).append(meta.decode("ascii", errors="replace"))
    return out

def parse_porcelain_paths(raw):
    fields = raw.split(b"\0")
    i = 0
    out = []
    while i < len(fields):
        f = fields[i]
        if not f:
            i += 1
            continue
        xy = f[:2].decode("latin1")
        path = f[3:].decode("utf-8", errors="surrogateescape")
        out.append((xy, path))
        if xy[0] in ("R", "C") and i + 1 < len(fields):
            src = fields[i + 1].decode("utf-8", errors="surrogateescape")
            out.append((xy, src))
            i += 2
        else:
            i += 1
    return out

def scan_tree():
    manifest = {}
    for dirpath, dirnames, filenames in os.walk(root, topdown=True, followlinks=False):
        rel_dir = "" if dirpath == root else dirpath[len(root) + 1:].replace(os.sep, "/")
        if rel_dir and is_exempt(rel_dir):
            dirnames[:] = []
            continue
        kept_dirs = []
        for d in sorted(dirnames):
            d_rel = d if not rel_dir else f"{rel_dir}/{d}"
            if is_exempt(d_rel):
                continue
            full_d = os.path.join(dirpath, d)
            if is_allow_ancestor(d_rel) and not os.path.islink(full_d):
                kept_dirs.append(d)
                continue
            st = os.lstat(full_d)
            if os.path.islink(full_d):
                target = os.readlink(full_d)
                h = hashlib.sha256(os.fsencode(target)).hexdigest()
                manifest[d_rel] = {"type": "symlink", "mode": st.st_mode & 0o7777, "hash": h}
            else:
                manifest[d_rel] = {"type": "dir", "mode": st.st_mode & 0o7777, "hash": "-"}
                kept_dirs.append(d)
        dirnames[:] = kept_dirs
        for fn in sorted(filenames):
            f_rel = fn if not rel_dir else f"{rel_dir}/{fn}"
            if is_exempt(f_rel):
                continue
            full_f = os.path.join(dirpath, fn)
            st = os.lstat(full_f)
            if os.path.islink(full_f):
                target = os.readlink(full_f)
                h = hashlib.sha256(os.fsencode(target)).hexdigest()
                manifest[f_rel] = {"type": "symlink", "mode": st.st_mode & 0o7777, "hash": h}
            elif os.path.isfile(full_f):
                h_obj = hashlib.sha256()
                with open(full_f, "rb") as fp:
                    while True:
                        chunk = fp.read(65536)
                        if not chunk:
                            break
                        h_obj.update(chunk)
                manifest[f_rel] = {"type": "file", "mode": st.st_mode & 0o7777, "hash": h_obj.hexdigest()}
    return manifest

if mode == "before":
    if os.path.exists(snap_dir):
        shutil.rmtree(snap_dir)
    os.makedirs(os.path.join(snap_dir, "files"), exist_ok=True)
    porc = get_porcelain()
    idx_map = get_index_stage_map()
    tracked_set = set(get_tracked())
    pre_dirty = {p.rstrip("/") for _, p in parse_porcelain_paths(porc)}
    clean_tracked = sorted(tracked_set - pre_dirty)
    with open(os.path.join(snap_dir, "porcelain.bin"), "wb") as f:
        f.write(porc)
    manifest = scan_tree()
    with open(os.path.join(snap_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump({
            "manifest": manifest,
            "clean_tracked": clean_tracked,
            "index_stage": idx_map,
        }, f, sort_keys=True)
    with open(os.path.join(snap_dir, "manifest.nul"), "wb") as f:
        for rel, info in sorted(manifest.items()):
            rec = f"{info['type']} {info['mode']:04o} {info['hash']}\t{rel}\0"
            f.write(rec.encode("utf-8", errors="surrogateescape"))
    for rel, info in manifest.items():
        src = os.path.join(root, rel)
        dst = os.path.join(snap_dir, "files", rel)
        if info["type"] == "dir":
            os.makedirs(dst, exist_ok=True)
        elif info["type"] == "symlink":
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            os.symlink(os.readlink(src), dst)
        elif info["type"] == "file":
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(src, dst, follow_symlinks=False)
    sys.exit(0)

elif mode == "after":
    manifest_path = os.path.join(snap_dir, "manifest.json")
    porc_path = os.path.join(snap_dir, "porcelain.bin")
    if not os.path.isfile(manifest_path) or not os.path.isfile(porc_path):
        print("snapshot-missing")
        sys.exit(1)
    with open(manifest_path, "r", encoding="utf-8") as f:
        saved = json.load(f)
    pre_manifest = saved["manifest"]
    clean_tracked_set = set(saved.get("clean_tracked", []))
    pre_idx_map = saved.get("index_stage", {})
    with open(porc_path, "rb") as f:
        pre_porc = f.read()
    post_porc = get_porcelain()
    post_idx_map = get_index_stage_map()
    post_manifest = scan_tree()

    violated = set()
    all_keys = set(pre_manifest.keys()) | set(post_manifest.keys())
    for k in all_keys:
        if pre_manifest.get(k) != post_manifest.get(k):
            violated.add(k)

    for k in (set(pre_idx_map.keys()) | set(post_idx_map.keys())):
        k_clean = k.rstrip("/")
        if not is_exempt(k_clean) and pre_idx_map.get(k) != post_idx_map.get(k):
            violated.add(k_clean)

    pre_porc_set = set(parse_porcelain_paths(pre_porc))
    post_porc_set = set(parse_porcelain_paths(post_porc))
    for xy, p in (post_porc_set - pre_porc_set):
        p_clean = p.rstrip("/")
        if not is_exempt(p_clean):
            violated.add(p_clean)

    if not violated:
        shutil.rmtree(snap_dir, ignore_errors=True)
        sys.exit(0)

    # Restore: (1) remove only paths that are new since the build started
    new_paths = sorted([k for k in post_manifest if k not in pre_manifest], key=lambda x: x.count("/"), reverse=True)
    for k in new_paths:
        target = os.path.join(root, k)
        if os.path.islink(target) or os.path.isfile(target):
            try: os.unlink(target)
            except OSError: pass
        elif os.path.isdir(target):
            for dp, dns, fns in os.walk(target, topdown=False):
                for fn in fns:
                    fp = os.path.join(dp, fn)
                    if not is_exempt(os.path.relpath(fp, root).replace(os.sep, "/")):
                        try: os.unlink(fp)
                        except OSError: pass
                try: os.rmdir(dp)
                except OSError: pass

    # Restore: (2) pre-existing paths whose state changed
    changed_pre = sorted(
        [k for k in pre_manifest if post_manifest.get(k) != pre_manifest[k]],
        key=lambda x: x.count("/")
    )
    for k in changed_pre:
        info = pre_manifest[k]
        target = os.path.join(root, k)
        backup = os.path.join(snap_dir, "files", k)
        if info["type"] == "dir":
            if os.path.islink(target) or os.path.isfile(target):
                os.unlink(target)
            os.makedirs(target, exist_ok=True)
            os.chmod(target, info["mode"])
        elif info["type"] == "symlink":
            if os.path.isdir(target) and not os.path.islink(target):
                shutil.rmtree(target)
            elif os.path.lexists(target):
                os.unlink(target)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            os.symlink(os.readlink(backup), target)
        elif info["type"] == "file":
            if os.path.isdir(target) and not os.path.islink(target):
                shutil.rmtree(target)
            elif os.path.islink(target):
                os.unlink(target)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            if k in clean_tracked_set:
                r = subprocess.run(["git", "-C", root, "checkout", "HEAD", "--", k],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                if r.returncode != 0 or not os.path.isfile(target):
                    shutil.copy2(backup, target, follow_symlinks=False)
            else:
                shutil.copy2(backup, target, follow_symlinks=False)
            os.chmod(target, info["mode"])

    # Restore directory modes bottom-up in case file restores inside them altered dir mtime/mode
    for k in sorted([k for k in changed_pre if pre_manifest[k]["type"] == "dir"], key=lambda x: x.count("/"), reverse=True):
        target = os.path.join(root, k)
        if os.path.isdir(target) and not os.path.islink(target):
            try: os.chmod(target, pre_manifest[k]["mode"])
            except OSError: pass

    # Restore pre-build index entries for off-ALLOW paths only; staged changes to allowed paths stay.
    idx_lines = []
    for k in sorted(set(pre_idx_map) | set(post_idx_map)):
        if is_exempt(k.rstrip("/")) or pre_idx_map.get(k) == post_idx_map.get(k):
            continue
        oid_len = next((len(meta.split()[1]) for metas in pre_idx_map.values() for meta in metas), 40)
        idx_lines.append(f"0 {'0' * oid_len}\t{k}")
        idx_lines.extend(f"{meta}\t{k}" for meta in pre_idx_map.get(k, []))
    if idx_lines:
        subprocess.run(["git", "-C", root, "update-index", "-z", "--index-info"],
                       input=b"".join(l.encode("utf-8", errors="surrogateescape") + b"\0" for l in idx_lines),
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    shutil.rmtree(snap_dir, ignore_errors=True)
    print(", ".join(sorted(violated)))
    sys.exit(1)
PYEOF
}

log(){ echo "improve-loop: $*"; }

# --- pre-flight: oracle-immutability (the builder must not be able to edit the oracle) ---------------
if [ -n "$ORACLE_PATHS" ]; then
  if ! bash "$ORACLEG" --allow "$ALLOW" --oracle "$ORACLE_PATHS" >/dev/null 2>&1; then
    echo "improve-loop: PRE-FLIGHT FAILED — builder write surface ($ALLOW) overlaps the oracle ($ORACLE_PATHS)" >&2
    bash "$ORACLEG" --allow "$ALLOW" --oracle "$ORACLE_PATHS" >&2 2>&1 || true
    exit 4
  fi
  log "pre-flight OK — builder write surface disjoint from the oracle"
fi

# --- baseline: the oracle MUST already pass; measure metric0 ----------------------------------------
log "measuring baseline (oracle must pass)…"
if ! eval "$ORACLE_CMD" >/dev/null 2>&1; then echo "improve-loop: baseline FAILS the oracle — refusing to optimize a broken artifact" >&2; exit 3; fi
BASE="$(bash "$MEASURE" -c "$MEASURE_CMD")" || { echo "improve-loop: baseline measure failed" >&2; exit 3; }
bash "$CHAMP" init "$STATE_DIR" --metric "$BASE" --goal "$GOAL" >/dev/null
cp "$ARTIFACT" "$SNAP"
HELD_CUR=""
if [ -n "$HELD_CMD" ]; then HELD_CUR="$(bash "$MEASURE" -c "$HELD_CMD")" || HELD_CUR=""; fi
log "baseline metric=$BASE goal=$GOAL${HELD_CUR:+ held=$HELD_CUR}"

# --- the hill-climb ---------------------------------------------------------------------------------
STOP_REASON=""; SPEND_FLOORED=0
while :; do
  IT="$(bash "$CHAMP" state "$STATE_DIR" --field iteration)"
  SP="$(bash "$CHAMP" state "$STATE_DIR" --field spent)"
  MC="$(bash "$CHAMP" state "$STATE_DIR" --field metric)"
  NI="$(bash "$CHAMP" state "$STATE_DIR" --field no-improve)"
  dec="$(bash "$STOP" --iteration "$IT" --max-iterations "$MAXIT" --spent "$SP" --max-total-budget "$MAXBUD" \
          --metric "$MC" ${TARGET:+--target "$TARGET"} --goal "$GOAL" --no-improve "$NI" --plateau "$PLATEAU")"; src=$?
  # Drive on the EXIT CODE, not string-parsing: 0 CONTINUE · 10 STOP · anything else is a stop-evaluator
  # error — abort (fail closed) rather than spin forever, which is the whole point of the halt guarantee.
  case "$src" in
    0) : ;;
    10) STOP_REASON="${dec#STOP }"; break ;;
    *) echo "improve-loop: stop-condition evaluator errored (exit $src): $dec — aborting" >&2; exit 2 ;;
  esac

  # GH-1221: snapshot pre-build tree state; fail closed if snapshot fails
  snap_ok=1
  if ! il_build_guard before >/dev/null 2>&1; then
    snap_ok=0
    log "iter $((IT+1)): pre-build snapshot failed — rejecting iteration (fail closed)"
  fi

  # build a challenger, timed (wall-clock = the universal exact cost)
  t0=$(date +%s)
  if [ "$snap_ok" = 1 ]; then
    eval "$BUILD_CMD" >/dev/null 2>&1 || true
  fi
  t1=$(date +%s); elapsed=$((t1 - t0))
  # Keep loop-cost's exact|floor honesty flag (its last stderr line) instead of dropping it: a floored
  # spend is a LOWER bound, so cumulative budget accounting under-counts and --max-total-budget could
  # silently never fire. Track it and surface it in the halt line.
  SPENT_IT="$(bash "$COST" --agent "$AGENT" --currency "$CURRENCY" --wall-clock-sec "$elapsed" 2>"$STATE_DIR/.costerr")" || SPENT_IT="$elapsed"
  [ "$(tail -1 "$STATE_DIR/.costerr" 2>/dev/null)" = floor ] && SPEND_FLOORED=1

  reason_extra=""
  if [ "$snap_ok" = 0 ]; then
    op=0; M="$MC"; reason_extra=" (pre-build snapshot failed)"
  elif ! VIOL_PATHS="$(il_build_guard after 2>/dev/null)"; then
    log "iter $((IT+1)): off-ALLOW write violation (${VIOL_PATHS:-unknown}) — restored snapshot"
    op=0; M="$MC"; reason_extra=" (off-ALLOW write: ${VIOL_PATHS:-unknown})"
  else
    # oracle gate
    op=1; eval "$ORACLE_CMD" >/dev/null 2>&1 || op=0
    M="$MC"
    if [ "$op" = 1 ]; then M="$(bash "$MEASURE" -c "$MEASURE_CMD" 2>/dev/null)" || { op=0; M="$MC"; }; fi

    # anti-gaming veto (only meaningful when the oracle passed and we have a held-out metric)
    if [ "$op" = 1 ] && [ -n "$HELD_CMD" ]; then
      HA="$(bash "$MEASURE" -c "$HELD_CMD" 2>/dev/null)" || HA="$HELD_CUR"
      if [ -n "$HELD_CUR" ] && [ -n "$HA" ]; then
        if ! bash "$HELD" --visible-before "$MC" --visible-after "$M" --held-before "$HELD_CUR" --held-after "$HA" --goal "$GOAL" >/dev/null 2>&1; then
          op=0; reason_extra=" (held-out anti-gaming veto)"   # treat gaming as an oracle failure
        fi
      fi
    fi
  fi

  # judge: accept (exit 0) keeps the artifact + snapshot; reject (exit 11) rolls back to the champion
  if bash "$CHAMP" judge "$STATE_DIR" --oracle-pass "$op" --metric "$M" --spent "$SPENT_IT" >/dev/null; then
    cp "$ARTIFACT" "$SNAP"                                   # accepted -> new champion
    [ -n "$HELD_CMD" ] && HELD_CUR="${HA:-$HELD_CUR}"
    log "iter $((IT+1)): ACCEPT metric=$M spent=$SPENT_IT"
  else
    cp "$SNAP" "$ARTIFACT"                                   # rejected -> restore the champion
    log "iter $((IT+1)): reject (metric=$M, oracle_pass=$op)$reason_extra — rolled back to champion"
  fi
done

# --- halt: emit the champion ------------------------------------------------------------------------
cp "$SNAP" "$ARTIFACT"                                       # ensure the tree holds the champion
FINAL="$(bash "$CHAMP" state "$STATE_DIR" --field metric)"
ITERS="$(bash "$CHAMP" state "$STATE_DIR" --field iteration)"
SPENT="$(bash "$CHAMP" state "$STATE_DIR" --field spent)"
SPEND_NOTE=""; [ "$SPEND_FLOORED" = 1 ] && SPEND_NOTE=" (floor — a lower bound; some iterations had uncounted spend)"
log "HALT ($STOP_REASON) — champion metric=$FINAL after $ITERS iterations, spent=$SPENT$SPEND_NOTE"
log "provenance: $STATE_DIR/provenance.jsonl"
printf 'CHAMPION %s\n' "$FINAL"
exit 0
