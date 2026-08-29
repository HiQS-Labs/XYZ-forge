#!/usr/bin/env bash
# gh291-contract-goldens.sh — GH-291 Scope 2: golden @1 conformance fixtures.
#
# Pins, against the committed goldens in test/fixtures/contracts/:
#   - producer fidelity: build_marathon_invocation_artifact (root + vendored layouts) and
#     the marathon-drive result writer still emit exactly the recorded @1 structure
#   - loader conformance: load_marathon_invocation / load_marathon_result accept the goldens
#     (invocation path fields adapted to the local fixture) and refuse documented mutations
#     with named errors
#   - future-schema refusal: a @2 receipt in the ledger parks with the load error named,
#     with zero Tick mutation and no dispatch
#
# The goldens are the recorded @1 shape; any producer change that alters the contract shows
# up as a fixture diff and must land as a deliberate fixture update in the same PR (the
# Scope-5 widen->flip->narrow ladder in MACHINE-CONTRACTS.md). Re-record deliberately with:
#   GH291_RECORD=1 bash test/gh291-contract-goldens.sh
#
# Result goldens arm the writer's _RESULT state directly and call write_terminal_result —
# they pin the WRITER's output shape; receipts produced through full drive flows are pinned
# by test/gh280-jog-marathon-adapter.sh sections C/D.
source "$(dirname "$0")/_setup.sh" gh291-contract-goldens
REPO="$(cd "$(dirname "$0")/.." && pwd)"
GOLDEN_DIR="$REPO/test/fixtures/contracts"

has() { grep -Fq -- "$2" <<<"$1"; }   # GH-139/GH-472: capture-then-match

command -v python3 >/dev/null 2>&1 || { echo 'python3 required' >&2; exit 1; }
[ -f "$GOLDEN_DIR/invocation-at1-root.json" ] || { echo "missing goldens in $GOLDEN_DIR" >&2; exit 1; }

FIX="$WORK/fix"; mkdir -p "$FIX/relay-automation" "$FIX/packet" "$FIX/.xyz/relay-automation" "$WORK/consumer"
printf '#!/usr/bin/env bash\nexit 0\n' > "$FIX/relay-automation/marathon-drive.sh"; chmod +x "$FIX/relay-automation/marathon-drive.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$FIX/.xyz/relay-automation/marathon-drive.sh"; chmod +x "$FIX/.xyz/relay-automation/marathon-drive.sh"
printf '# fixture packet\n' > "$FIX/packet/packet.md"

# gh stub: canned PR 42 for the approved receipt's identity probes
STUB_BIN="$WORK/stub-bin"; mkdir -p "$STUB_BIN"
cat > "$STUB_BIN/gh" <<'EOF'
#!/usr/bin/env bash
set -u
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "list" ]; then
  printf '[{"number":42,"url":"https://example.invalid/x/pr/42","state":"OPEN"}]\n'
  exit 0
fi
exit 1
EOF
chmod +x "$STUB_BIN/gh"

export REPO FIX CONSUMER="$WORK/consumer" RLIB="$REPO/utils/py"

# comparator: normalize volatile fields (timestamps; fixture-root paths), structural diff
cat > "$WORK/compare.py" <<CMP
import json, os, sys
FIX, WORK = "$FIX", "$WORK"

def normalize(obj):
    if isinstance(obj, dict):
        # volatile keys: run timestamps, and the receipt's live git probe (head_sha is the
        # fixture repo's HEAD — presence and string type are what the contract pins)
        return {k: normalize(v) for k, v in sorted(obj.items()) if k not in
                ("generated_at", "timestamps", "head_sha")}
    if isinstance(obj, list):
        return [normalize(v) for v in obj]
    if isinstance(obj, str):
        return obj.replace(FIX, "<FIX>").replace(WORK, "<WORK>")
    return obj

def structural_diff(a, b, path=""):
    diffs = []
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            if k not in a: diffs.append(f"{path}.{k}: missing in produced")
            elif k not in b: diffs.append(f"{path}.{k}: missing in golden")
            else: diffs.extend(structural_diff(a[k], b[k], f"{path}.{k}"))
    elif isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            diffs.append(f"{path}: list length {len(a)} != {len(b)}")
        for i, (x, y) in enumerate(zip(a, b)):
            diffs.extend(structural_diff(x, y, f"{path}[{i}]"))
    elif a != b:
        diffs.append(f"{path}: produced={a!r} golden={b!r}")
    return diffs

produced = normalize(json.load(open(sys.argv[1])))
golden = normalize(json.load(open(sys.argv[2])))
d = structural_diff(produced, golden)
if d:
    print("STRUCTURAL DRIFT vs golden:")
    for line in d[:12]:
        print("  " + line)
    sys.exit(1)
print("CONFORMANT")
CMP

conforms() {  # <produced> <golden> <label>
  local out
  out="$(python3 "$WORK/compare.py" "$1" "$2" 2>&1)"
  has "$out" "CONFORMANT" && pass "$3" || fail "$3: $out"
}

# ── 1. invocation producer fidelity (root + vendored layouts) ────────────────────────────────
gen_invocation() {  # <mode: root|vendored> <outfile>
  MODE="$1" OUT="$2" python3 - <<'PY'
import json, os, sys
sys.path.insert(0, os.environ["RLIB"])
from swarm_preflight import build_marathon_invocation_artifact
fix, mode, out = os.environ["FIX"], os.environ["MODE"], os.environ["OUT"]
if mode == "root":
    art = build_marathon_invocation_artifact(
        "2026-08-29T00:00:00Z", fix, "relay-automation/marathon-drive.sh", fix,
        os.path.join(fix, "packet"), "gh901-p", "bash %s/gate.sh" % fix,
        "docs/A.md,src/b.js", 901, "development", "codex", "agy")
else:
    art = build_marathon_invocation_artifact(
        "2026-08-29T00:00:00Z", fix, ".xyz/relay-automation/marathon-drive.sh",
        os.environ["CONSUMER"], os.path.join(fix, "packet"), "gh901-p",
        "bash %s/gate.sh" % fix, "docs/A.md", 901, "development", "agy", "codex")
json.dump(art, open(out, "w"), indent=2)
PY
}

gen_invocation root "$WORK/inv-root.json"
conforms "$WORK/inv-root.json" "$GOLDEN_DIR/invocation-at1-root.json" \
  "F1 root invocation: producer output conforms to the @1 golden"
gen_invocation vendored "$WORK/inv-vendored.json"
conforms "$WORK/inv-vendored.json" "$GOLDEN_DIR/invocation-at1-vendored.json" \
  "F2 vendored invocation: producer output conforms to the @1 golden"

# ── 2. invocation loader: adapted goldens accepted, documented mutations refused ─────────────
cat > "$WORK/inv_load.py" <<'LOAD'
import copy, json, os, sys
sys.path.insert(0, os.environ["RLIB"])
from jog_run import load_marathon_invocation, ContractError
golden_dir, fix, work = sys.argv[1], sys.argv[2], sys.argv[3]
PATH_FLAG_VALUES = {"--phase-brief", "--result-file", "--pre-advance-cmd", "--target-root", "--artifact"}

def adapted(name, consumer=None):
    d = json.load(open(os.path.join(golden_dir, name)))
    vendored = "vendored" in name
    drive = os.path.join(fix, ".xyz/relay-automation/marathon-drive.sh") if vendored \
        else os.path.join(fix, "relay-automation/marathon-drive.sh")
    d["harness_root"] = fix
    d["harness_home"] = os.path.join(fix, ".xyz") if vendored else fix
    d["target_root"] = consumer or fix
    d["drive_command"] = drive
    d["packet_dir"] = os.path.join(fix, "packet")
    d["packet_path"] = os.path.join(fix, "packet", "packet.md")
    d["result_path"] = os.path.join(fix, "packet", "marathon-result.json")
    argv, subs = [drive], {"--phase-brief": d["packet_path"], "--result-file": d["result_path"],
                           "--pre-advance-cmd": "bash %s/gate.sh" % fix}
    if consumer:
        subs["--target-root"] = consumer
    i = 1
    while i < len(d["argv"]):
        flag = d["argv"][i]
        if flag in subs:
            argv += [flag, subs[flag]]; i += 2
        else:
            argv.append(flag); i += 1
    d["argv"] = argv
    return d

def try_load(obj, tag):
    p = os.path.join(work, "candidate.json")
    json.dump(obj, open(p, "w"))
    try:
        load_marathon_invocation(p)
        print(f"{tag}: ACCEPTED")
    except ContractError as exc:
        print(f"{tag}: REFUSED {exc}")

try_load(adapted("invocation-at1-root.json"), "G1-golden-root")
try_load(adapted("invocation-at1-vendored.json", consumer=os.path.join(work, "consumer")), "G2-golden-vendored")
root = adapted("invocation-at1-root.json")
m = copy.deepcopy(root); m["schema"] = "swarm-preflight/marathon-invocation@2"
try_load(m, "M1-future-schema")
m = copy.deepcopy(root); del m["schema"]
try_load(m, "M2-missing-schema")
m = copy.deepcopy(root); m["argv"][0] = "relay-automation/marathon-drive.sh"
try_load(m, "M3-relative-argv0")
m = copy.deepcopy(root); del m["base_ref"]
try_load(m, "M4-missing-required-field")
m = copy.deepcopy(root); m["env"] = ["not", "a", "dict"]
try_load(m, "M5-env-not-object")
LOAD
python3 "$WORK/inv_load.py" "$GOLDEN_DIR" "$FIX" "$WORK" > "$WORK/load-results.txt" 2>&1

grep -q 'G1-golden-root: ACCEPTED' <<<"$(cat "$WORK/load-results.txt")" \
  && pass "G1 loader accepts the adapted root golden" || fail "G1 golden rejected: $(cat "$WORK/load-results.txt")"
grep -q 'G2-golden-vendored: ACCEPTED' <<<"$(cat "$WORK/load-results.txt")" \
  && pass "G2 loader accepts the adapted vendored golden" || fail "G2 vendored golden rejected"
has "$(grep 'M1-future-schema' "$WORK/load-results.txt")" "REFUSED" \
  && has "$(grep 'M1-future-schema' "$WORK/load-results.txt")" "@2" \
  && pass "M1 future schema @2 refused with the version named" || fail "M1 future schema mishandled"
grep -q 'M2-missing-schema: REFUSED' <<<"$(cat "$WORK/load-results.txt")" \
  && pass "M2 missing schema key refused" || fail "M2 missing schema accepted"
grep -q 'M3-relative-argv0: REFUSED' <<<"$(cat "$WORK/load-results.txt")" \
  && pass "M3 relative argv[0] refused" || fail "M3 relative argv accepted"
grep -q 'M4-missing-required-field: REFUSED' <<<"$(cat "$WORK/load-results.txt")" \
  && pass "M4 missing required field refused" || fail "M4 missing field accepted"
grep -q 'M5-env-not-object: REFUSED' <<<"$(cat "$WORK/load-results.txt")" \
  && pass "M5 non-object env refused" || fail "M5 bad env accepted"

# ── 3. result goldens: writer fidelity + loader conformance + mutations ──────────────────────
git init -q -b development "$WORK/rrepo" && git -C "$WORK/rrepo" config user.email t@i.invalid && git -C "$WORK/rrepo" config user.name t
printf 'x\n' > "$WORK/rrepo/f" && git -C "$WORK/rrepo" add -A && git -C "$WORK/rrepo" commit -qm init

gen_result() {  # <variant: approved|refused> <outfile>
  MODE="$1" OUT="$2" RREPO="$WORK/rrepo" PATH="$STUB_BIN:$PATH" python3 - <<'PY'
import os, sys
sys.path.insert(0, os.environ["RLIB"])
import marathon_drive as md
mode, out = os.environ["MODE"], os.environ["OUT"]
r = md._RESULT
r.update({"armed": True, "path": out,
          "execution_id": "gh901-exec1", "started_at": "2026-08-29T00:00:00Z",
          "phase": "p", "builder": "codex", "reviewer": "agy",
          "root": os.environ["RREPO"], "target_repo_path": os.environ["RREPO"],
          "lane": "MARATHON-GH-901", "token": "GH-901-2026-08-29",
          "attempt_max": 2, "phases_dir": os.path.join(os.environ["RREPO"], "phases"),
          "brief_name": "GH-901"})
if mode == "approved":
    r.update({"gate_cmd": "bash gate.sh", "gate_result": "green", "gate_exit": 0,
              "head_branch": "marathon/gh901-lane",
              "acceptance": {"checked": True, "unmet_count": 0}})
    md.write_terminal_result(0)
else:
    r.update({"reason": "gate-missing"})
    md.write_terminal_result(2)
PY
}

gen_result approved "$WORK/res-approved.json"
conforms "$WORK/res-approved.json" "$GOLDEN_DIR/result-at1-approved.json" \
  "F3 approved receipt: writer output conforms to the @1 golden"
gen_result refused "$WORK/res-refused.json"
conforms "$WORK/res-refused.json" "$GOLDEN_DIR/result-at1-refused.json" \
  "F4 refused receipt: writer output conforms to the @1 golden"

cat > "$WORK/res_load.py" <<'LOAD'
import copy, json, os, sys
sys.path.insert(0, os.environ["RLIB"])
from jog_run import load_marathon_result, ContractError
golden_dir, work = sys.argv[1], sys.argv[2]

def try_load(obj, tag):
    p = os.path.join(work, "candidate2.json")
    json.dump(obj, open(p, "w"))
    try:
        load_marathon_result(p)
        print(f"{tag}: ACCEPTED")
    except ContractError as exc:
        print(f"{tag}: REFUSED {exc}")

approved = json.load(open(os.path.join(golden_dir, "result-at1-approved.json")))
try_load(approved, "G3-golden-approved")
try_load(json.load(open(os.path.join(golden_dir, "result-at1-refused.json"))), "G4-golden-refused")
n = copy.deepcopy(approved); n["schema"] = "marathon-drive/result@2"
try_load(n, "N1-future-schema")
n = copy.deepcopy(approved); del n["head_sha"]
try_load(n, "N2-missing-required-key")
n = copy.deepcopy(approved); n["exit_code"] = True
try_load(n, "N3-bool-exit-code")
n = copy.deepcopy(approved); n["gate"] = "green"
try_load(n, "N4-scalar-gate")
LOAD
python3 "$WORK/res_load.py" "$GOLDEN_DIR" "$WORK" > "$WORK/load-results2.txt" 2>&1

grep -q 'G3-golden-approved: ACCEPTED' <<<"$(cat "$WORK/load-results2.txt")" \
  && pass "G3 loader accepts the approved golden verbatim" || fail "G3 approved golden rejected: $(cat "$WORK/load-results2.txt")"
grep -q 'G4-golden-refused: ACCEPTED' <<<"$(cat "$WORK/load-results2.txt")" \
  && pass "G4 loader accepts the refused golden verbatim" || fail "G4 refused golden rejected"
has "$(grep 'N1-future-schema' "$WORK/load-results2.txt")" "REFUSED" \
  && has "$(grep 'N1-future-schema' "$WORK/load-results2.txt")" "@2" \
  && pass "N1 future schema @2 refused with the version named" || fail "N1 future schema mishandled"
grep -q 'N2-missing-required-key: REFUSED' <<<"$(cat "$WORK/load-results2.txt")" \
  && pass "N2 missing required key refused" || fail "N2 missing key accepted"
grep -q 'N3-bool-exit-code: REFUSED' <<<"$(cat "$WORK/load-results2.txt")" \
  && pass "N3 bool exit_code refused (bool is not int)" || fail "N3 bool accepted"
grep -q 'N4-scalar-gate: REFUSED' <<<"$(cat "$WORK/load-results2.txt")" \
  && pass "N4 scalar gate field refused" || fail "N4 scalar gate accepted"

# ── 4. future-schema receipt in the ledger: parks with the cause named, zero Tick mutation ──
Q="$WORK/qroot"; mkdir -p "$Q"
git -C "$Q" init -q -b development; git -C "$Q" config user.email q@i.invalid; git -C "$Q" config user.name q
python3 "$RLIB/releases_app.py" --root "$Q" init >/dev/null 2>&1
python3 "$RLIB/releases_app.py" --root "$Q" jog add 901 >/dev/null 2>&1
QGID="$(python3 - "$Q/releases.db" <<'PY'
import sqlite3, sys
print(sqlite3.connect(sys.argv[1]).execute(
    "SELECT global_id FROM jog_queue WHERE gh_number = 901").fetchone()[0])
PY
)"
mkdir -p "$Q/.tick/jog/$QGID/gh901-exec1"
sed 's/marathon-drive\/result@1/marathon-drive\/result@2/' "$GOLDEN_DIR/result-at1-approved.json" \
  > "$Q/.tick/jog/$QGID/gh901-exec1/marathon-result.json"
cat > "$Q/.tick/jog/$QGID/state.json" <<JSEOF
{"schema": "jog/execution-state@1", "gid": "$QGID", "gh_number": 901,
 "executions": [{"execution_id": "gh901-exec1", "mode": "run", "started_at": "2026-08-29T00:00:00Z",
                 "status": "dispatched",
                 "packet_dir": "$Q/.tick/jog/$QGID/gh901-exec1/preflight",
                 "result_path": "$Q/.tick/jog/$QGID/gh901-exec1/marathon-result.json"}]}
JSEOF
Z_OUT="$( cd "$Q" && python3 "$RLIB/releases_app.py" --root "$Q" jog resume 901 2>&1)"; rc=$?
[ "$rc" -eq 1 ] && has "$Z_OUT" "supports only" && has "$Z_OUT" "@2" \
  && pass "Z1 future-schema receipt parks with the schema error named (exit 1)" \
  || fail "Z1 rc=$rc: $Z_OUT"
[ ! -e "$Q/.tick/events" ] \
  && pass "Z2 zero Tick mutation (no events dir, nothing dispatched)" \
  || fail "Z2 tick events appeared under a refused future-schema load"
QROW="$(python3 - "$Q/releases.db" <<'PY'
import sqlite3, sys
print(sqlite3.connect(sys.argv[1]).execute(
    "SELECT status FROM jog_queue WHERE gh_number = 901").fetchone()[0])
PY
)"
has "$QROW" "parked" \
  && pass "Z3 queue row parked (queue bookkeeping is Jog's own surface)" || fail "Z3 row: $QROW"

# ── record mode: rewrite the committed goldens from this run's producers ────────────────────
if [ "${GH291_RECORD:-0}" = "1" ]; then
  python3 - "$WORK" "$GOLDEN_DIR" <<'PY'
import json, os, sys
work, golden_dir = sys.argv[1], sys.argv[2]

def path_tokens(obj):
    # Commit goldens in NORMALIZED form: machine-specific roots become tokens so the
    # comparator (which tokenizes both sides) is portable. Everything else stays recorded.
    if isinstance(obj, dict):
        return {k: path_tokens(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [path_tokens(v) for v in obj]
    if isinstance(obj, str):
        # Identical mapping/order to compare.py so recorded goldens compare cleanly.
        return obj.replace(os.path.join(work, "fix"), "<FIX>").replace(work, "<WORK>")
    return obj

for src, dst in (("inv-root.json", "invocation-at1-root.json"),
                 ("inv-vendored.json", "invocation-at1-vendored.json"),
                 ("res-approved.json", "result-at1-approved.json"),
                 ("res-refused.json", "result-at1-refused.json")):
    d = json.load(open(os.path.join(work, src)))
    json.dump(path_tokens(d), open(os.path.join(golden_dir, dst), "w"), indent=2)
    open(os.path.join(golden_dir, dst), "a").write("\n")
print("goldens re-recorded (path-normalized) in " + golden_dir)
PY
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
