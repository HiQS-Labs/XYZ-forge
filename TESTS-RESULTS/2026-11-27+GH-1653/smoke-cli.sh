#!/usr/bin/env bash
# GH-1653 manual smoke (GH-1088), not a suite (GH-831): the public `jog resume` command after a
# refused publication, through the REAL installed pre-push stub (`githooks/install.sh`), in
# disposable clones pushing to a local bare remote. A coordinator clone holds the queue row and a
# hand-built approved execution (the shape Marathon leaves); the execution clone holds the lane.
#   1 refused:  `jog resume` books, its push cannot reach the remote -> exit != 0, 1 failed row,
#               remote lane OID unchanged
#   2 resume:   `jog resume` again -> exit 0, books a 2nd row, pushes the bundle through the installed
#               stub, saves the receipt, archives [failed, completed]
#   3 rerun:    `jog resume` again -> exit 0, re-projects, books nothing, ref unchanged
#   4 control:  an unreserved task push from the execution clone is refused by the installed stub
# Exits nonzero if any expectation fails. Usage: smoke-cli.sh <source clone at commit> <empty dir>
set -u
SRC="$1"; W="$2"; FAILS=0
check() { if eval "$2"; then echo "  OK: $1"; else echo "  NOT OK: $1"; FAILS=$((FAILS+1)); fi; }
mkdir -p "$W" && cd "$W" || exit 2
HEAD_SRC="$(git -C "$SRC" rev-parse HEAD)"
git clone -q --bare --no-local "$SRC" remote.git || exit 2
git --git-dir=remote.git update-ref refs/heads/development "$HEAD_SRC"   # lane base = commit under test
for c in coord exec; do
  git clone -q -b development remote.git "$c" || exit 2
  git -C "$c" config user.name gh1653-smoke; git -C "$c" config user.email gh1653-smoke@test.invalid
done
( cd exec && bash githooks/install.sh >/dev/null && bash githooks/install.sh --check ) || { echo "hook not wired"; exit 2; }
KEY="$(cd coord && PYTHONPATH=utils/py python3 -c 'import sys; from harness_paths import primary_config_key; print(primary_config_key(sys.argv[1]))' "$W/coord")"
git -C coord config "$KEY" "$W/coord"
python3 coord/utils/py/releases_app.py --root "$W/coord" jog add 1653 >/dev/null 2>&1 \
  || { echo "jog add failed"; python3 coord/utils/py/releases_app.py --root "$W/coord" jog add 1653; exit 2; }
GID="$(sqlite3 coord/releases.db "SELECT global_id FROM jog_queue WHERE gh_number = 1653;")"
[ -n "$GID" ] || { echo "no queue row"; exit 2; }

git -C exec checkout -q -b marathon/gh1653-cli
git -C exec commit -q --allow-empty -m "smoke: approved lane head"
APPROVED="$(git -C exec rev-parse HEAD)"
mkdir -p exec/.xyz/receipts
printf '{"sha": "%s", "gate": "smoke", "mode": "marathon", "exit_code": 0}\n' "$APPROVED" > "exec/.xyz/receipts/$APPROVED.json"
PKT="$W/coord/.tick/jog/$GID/gh1653-cli1/preflight"; mkdir -p "$PKT"
printf 'packet\n' > "$PKT/packet.md"
cat > "$PKT/marathon-result.json" <<JSON
{"schema": "marathon-drive/result@1", "execution_id": "gh1653-cli1", "generated_at": "2026-11-27T00:00:01Z",
 "outcome": "approved", "reason": "approved, gate passed", "exit_code": 0, "approval_preserved": false,
 "issue": "1653", "phase": "p", "lane": "p", "token": "T", "attempt": {"count": 1, "max": 2},
 "builder": "codex", "reviewer": "agy", "target_repo": {"path": "$W/exec", "origin_url": null},
 "base_branch": "development", "head_branch": "marathon/gh1653-cli", "head_sha": "$APPROVED",
 "branch_redirect": true, "gate": {"cmd": "true", "result": "green", "exit": 0, "receipt_path": null},
 "acceptance": {"checked": false, "unmet_count": 0}, "pr": {"number": null, "url": null, "state": null},
 "pr_note": null, "relay_status": "Approved",
 "timestamps": {"started_at": "2026-11-27T00:00:00Z", "finished_at": "2026-11-27T00:00:01Z"}}
JSON
cat > "$PKT/marathon-invocation.json" <<JSON
{"schema": "swarm-preflight/marathon-invocation@1", "argv": ["$W/exec/relay-automation/marathon-drive.sh"],
 "env": {}, "harness_root": "$W/exec", "target_root": "$W/exec", "packet_path": "$PKT/packet.md",
 "issue": "1653", "phase": "p", "lane": "p", "gate": "true", "builder": "codex", "reviewer": "agy",
 "base_ref": "development", "result_path": "$PKT/marathon-result.json", "packet_dir": "$PKT",
 "artifacts": [], "drive_command": "marathon-drive.sh"}
JSON
cat > "coord/.tick/jog/$GID/state.json" <<JSON
{"schema": "jog/execution-state@1", "gid": "$GID", "gh_number": 1653,
 "executions": [{"execution_id": "gh1653-cli1", "mode": "run", "started_at": "2026-11-27T00:00:00Z",
                 "status": "receipt-publication-failed", "packet_dir": "$PKT",
                 "result_path": "$PKT/marathon-result.json"}]}
JSON
resume() { env -u XYZ_ATTEMPT_CONTEXT python3 coord/utils/py/releases_app.py --root "$W/coord" jog resume 1653 2>&1; }
oid() { git --git-dir=remote.git rev-parse -q --verify refs/heads/marathon/gh1653-cli || echo absent; }
rows() { cat "coord/.tick/attempts/GH-1653-jog-publish" 2>/dev/null | python3 -c 'import json,sys; print(",".join(r["state"] for r in map(json.loads, filter(str.strip, sys.stdin))) or "-")'; }
arch() { cat coord/.tick/attempt-history/GH-1653-jog-publish-*/attempts 2>/dev/null | python3 -c 'import json,sys; print(",".join(r["state"] for r in map(json.loads, filter(str.strip, sys.stdin))) or "-")'; }

echo "== 1 refused publication (remote unreachable after booking)"
O0="$(oid)"; mv remote.git remote.git.away
OUT1="$(resume)"; RC1=$?; mv remote.git.away remote.git
echo "$OUT1" | tail -3; echo "  rc=$RC1 oid_before=$O0 oid_after=$(oid) live=$(rows) archived=$(arch)"
check "refused resume exits nonzero" '[ "$RC1" -ne 0 ]'
check "one failed row consumed" '[ "$(rows)" = failed ]'
check "remote lane OID unchanged" '[ "$(oid)" = "$O0" ]'

echo "== 2 jog resume publishes through the installed stub"
OUT2="$(resume)"; RC2=$?
echo "$OUT2" | tail -4; echo "  rc=$RC2 oid=$(oid) head=$(git -C exec rev-parse HEAD) live=$(rows) archived=$(arch)"
check "resume exits 0" '[ "$RC2" -eq 0 ]'
check "remote lane at the bundle commit" '[ "$(oid)" = "$(git -C exec rev-parse HEAD)" ]'
check "bundle subject on remote" '[ "$(git --git-dir=remote.git log -1 --format=%s refs/heads/marathon/gh1653-cli)" = "jog: publish gh1653-cli1 approved execution receipts" ]'
check "budget archived as failed,completed" '[ "$(arch)" = failed,completed ] && [ "$(rows)" = - ]'
check "receipt saved in state" 'python3 -c "import json,sys; sys.exit(0 if json.load(open(sys.argv[1]))[\"executions\"][-1].get(\"committed_receipt\") else 1)" "coord/.tick/jog/$GID/state.json"'
O2="$(oid)"

echo "== 3 rerun re-projects without booking"
OUT3="$(resume)"; RC3=$?
echo "$OUT3" | tail -2; echo "  rc=$RC3 oid=$(oid) live=$(rows) archived=$(arch)"
check "rerun exits 0 and re-projects" '[ "$RC3" -eq 0 ] && case "$OUT3" in *re-projected*) true;; *) false;; esac'
check "rerun booked nothing, ref unchanged" '[ "$(rows)" = - ] && [ "$(arch)" = failed,completed ] && [ "$(oid)" = "$O2" ]'

echo "== 4 control: unreserved task push"
git -C exec checkout -q -b gh1653-cli-neg && git -C exec commit -q --allow-empty -m "unreserved"
OUT4="$(env -u XYZ_ATTEMPT_CONTEXT -u MERGE_CLEANUP_RECORD git -C exec push origin HEAD:refs/heads/gh1653-cli-neg 2>&1)"; RC4=$?
echo "$OUT4" | tail -2
check "unreserved push refused by admission" '[ "$RC4" -ne 0 ] && case "$OUT4" in *"no attempt reservation"*) true;; *) false;; esac'
check "remote has no unreserved ref" '! git --git-dir=remote.git rev-parse -q --verify refs/heads/gh1653-cli-neg >/dev/null'
echo "== smoke-cli: $FAILS expectation(s) failed"
exit "$FAILS"
