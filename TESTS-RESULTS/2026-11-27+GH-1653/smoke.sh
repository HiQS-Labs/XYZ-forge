#!/usr/bin/env bash
# GH-1653 manual smoke (GH-1088), not a suite (GH-831). Drives Jog's real receipt publication
# (`publish_jog_receipt`) through the REAL installed pre-push stub (`githooks/install.sh`) in a
# disposable clone pushing to a local bare remote.
#   refused:       booked publication whose push cannot reach the remote -> 1 failed row, remote unchanged
#   main path:     resume of that approved receipt -> books a 2nd row, pushes the bundle through the
#                  installed stub (admission + full gate), archives [failed, completed]
#   adjacent path: the same publication again (a rerun/resume) -> already published, no booking
#   control:       an unreserved task push from the same clone is refused by the installed stub
# Usage: smoke.sh <source clone at the commit under test> <empty work dir>
set -u
SRC="$1"; W="$2"
mkdir -p "$W" && cd "$W" || exit 2
git clone -q --bare --no-local "$SRC" remote.git || exit 2
git clone -q remote.git exec || exit 2
mkdir -p coord
git -C exec config user.name gh1653-smoke
git -C exec config user.email gh1653-smoke@test.invalid
( cd exec && bash githooks/install.sh >/dev/null && bash githooks/install.sh --check ) || { echo "hook not wired"; exit 2; }
git -C exec checkout -q -b marathon/gh1653-smoke "$(git -C "$SRC" rev-parse HEAD)"   # the commit under test
git -C exec commit -q --allow-empty -m "smoke: approved lane head"
HEAD_SHA="$(git -C exec rev-parse HEAD)"
mkdir -p exec/.xyz/receipts
printf '{"sha": "%s", "gate": "smoke", "mode": "marathon", "exit_code": 0}\n' "$HEAD_SHA" \
  > "exec/.xyz/receipts/$HEAD_SHA.json"
cat > result.json <<JSON
{"schema": "marathon-drive/result@1", "execution_id": "gh1653-smoke1", "generated_at": "2026-11-27T00:00:01Z",
 "outcome": "approved", "reason": "approved, gate passed", "exit_code": 0, "approval_preserved": false,
 "issue": "1653", "phase": "p", "lane": "p", "token": "T", "attempt": {"count": 1, "max": 2},
 "builder": "codex", "reviewer": "agy", "target_repo": {"path": "$W/exec", "origin_url": null},
 "base_branch": "development", "head_branch": "marathon/gh1653-smoke", "head_sha": "$HEAD_SHA",
 "branch_redirect": true, "gate": {"cmd": "true", "result": "green", "exit": 0, "receipt_path": null},
 "acceptance": {"checked": false, "unmet_count": 0}, "pr": {"number": null, "url": null, "state": null},
 "pr_note": null, "relay_status": "Approved",
 "timestamps": {"started_at": "2026-11-27T00:00:00Z", "finished_at": "2026-11-27T00:00:01Z"}}
JSON
publish() {
  ( cd exec && env -u XYZ_ATTEMPT_CONTEXT PYTHONPATH="$W/exec/utils/py" python3 - "$W" <<'PY'
import json, sys
import jog_run
w = sys.argv[1]
receipt = json.load(open(w + "/result.json"))
print("published:", jog_run.publish_jog_receipt(w + "/exec", receipt, w + "/result.json",
                                                base_ref="development", accounting_root=w + "/coord"))
PY
  )
}
rows() { cat coord/.tick/attempts/GH-1653-jog-publish 2>/dev/null | wc -l | tr -d ' '; }
archived() { cat coord/.tick/attempt-history/GH-1653-jog-publish-*/attempts 2>/dev/null | python3 -c 'import json,sys; print([(r["state"], r["id"][:8]) for r in map(json.loads, filter(str.strip, sys.stdin))])'; }

oid() { git --git-dir=remote.git rev-parse -q --verify refs/heads/marathon/gh1653-smoke || echo absent; }
live() { cat coord/.tick/attempts/GH-1653-jog-publish 2>/dev/null | python3 -c 'import json,sys; print([(r["state"], r["id"][:8]) for r in map(json.loads, filter(str.strip, sys.stdin))])'; }

echo "== refused publication: the push cannot reach the remote after booking"
echo "remote lane OID before: $(oid)"
mv remote.git remote.git.away
publish; echo "exit=$?"
mv remote.git.away remote.git
echo "remote lane OID after: $(oid)  live rows: $(live)"

echo "== main path (resume after the refusal): publish through the installed pre-push stub"
publish; echo "exit=$?"
echo "remote lane OID: $(oid)  local HEAD: $(git -C exec rev-parse HEAD)"
echo "remote lane subject: $(git --git-dir=remote.git log -1 --format=%s refs/heads/marathon/gh1653-smoke 2>&1)"
echo "live rows: $(rows)  archived: $(archived)"

echo "== adjacent path: same publication again (rerun/resume)"
publish; echo "exit=$?"
echo "live rows: $(rows)  archived: $(archived)"

echo "== control: unreserved task push from the same clone"
git -C exec checkout -q -b gh1653-smoke-neg && git -C exec commit -q --allow-empty -m "unreserved"
env -u XYZ_ATTEMPT_CONTEXT -u MERGE_CLEANUP_RECORD git -C exec push origin HEAD:refs/heads/gh1653-smoke-neg 2>&1 | tail -3
echo "push exit=${PIPESTATUS[0]}  remote has neg ref: $(git --git-dir=remote.git rev-parse -q --verify refs/heads/gh1653-smoke-neg || echo no)"
