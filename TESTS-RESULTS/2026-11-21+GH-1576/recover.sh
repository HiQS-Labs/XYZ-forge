#!/usr/bin/env bash
# GH-1576 F4 manual end-to-end check (not a suite, GH-831): a closeout refused by the wiring check is
# recoverable through the documented `resume` command.
#
#   recover.sh <label> <code-rev> <source-clone> <out-dir>
#
# It reuses the hermetic fixture of test/gh267-express-skill.sh (fake `gh` on PATH, local bare remote,
# the real express driver) by taking that suite's own setup, verbatim, from the revision under test,
# and appending the scenario below. The scenario lands a fix, then runs the REAL `closeout()` in a
# clone whose pre-push stub is gone, so the closeout is refused by the wiring check. It then repairs the
# wiring and runs the documented recovery, `express.py resume`. Rows go to <out-dir>/provenance.jsonl.
# Red = c541204bc (resume rejects the retained closeout as a dirty tree). Green = the repaired head.
set -uo pipefail
LABEL="$1"; REV="$2"; SRC="$3"; OUT="$4"
W="$(mktemp -d "${TMPDIR:-/tmp}/gh1576-recover-$LABEL.XXXXXX")"
trap 'rm -rf "$W"' EXIT
mkdir -p "$OUT"
git clone -q "$SRC" "$W/code" && git -C "$W/code" checkout -q "$REV" || { echo "cannot check out $REV"; exit 2; }
REVSHA="$(git -C "$W/code" rev-parse HEAD)"
RUN_NAME="gh1576-recover-run.sh"   # generated at run time; not a path that exists in the tree
RUN="$W/code/test/$RUN_NAME"
# The suite's setup, up to (not including) its first case.
sed -n '1,/^echo "== refusals =="/p' "$W/code/test/gh267-express-skill.sh" | sed '$d' > "$RUN"
export GH1576_PROV="$OUT/provenance.jsonl" GH1576_LABEL="$LABEL" GH1576_REV="$REVSHA"
cat >> "$RUN" <<'SCENARIO'
ERR="$WORK/err"; : > "$ERR"
remote_dev() { git --git-dir="$REMOTE" rev-parse development; }
rec() { # scenario result detail origin_before origin_after
  python3 - "$GH1576_LABEL" "$GH1576_REV" "$@" >> "$GH1576_PROV" <<'PY'
import json, sys
k = ["label", "code_rev", "scenario", "result", "detail", "origin_before", "origin_after"]
d = dict(zip(k, sys.argv[1:])); d["boundary"] = "express resume of a refused closeout (end-to-end)"
print(json.dumps(d, sort_keys=True))
PY
  echo "  [$1] result=$2 origin $4 -> $5 :: $3"
}
echo "== GH-1576 F4: closeout refused by the wiring check, recovered through resume =="
new_task_branch
printf 'fixed-1576\n' > "$FX/utils/py/foo.py"
python3 "$DRIVER" --root "$FX" docs --issue 999 --suite test/gh999-demo.sh --summary "gh1576 recovery" >/dev/null 2>"$ERR" || bad "docs failed: $(cat "$ERR")"
python3 "$DRIVER" --root "$FX" ledger --issue 999 >/dev/null 2>"$ERR" || bad "ledger failed: $(cat "$ERR")"
git -C "$FX" add -A && git -C "$FX" commit -qm "fix(GH-999): landing for the GH-1576 recovery witness [express]

Closes #999"
LAND_SHA="$(git -C "$FX" rev-parse HEAD)"
git -C "$FX" push -q origin HEAD:development
git -C "$FX" checkout -q development && git -C "$FX" pull -q --ff-only origin development
O0="$(remote_dev)"

# The wiring is lost before the closeout (the stub is gone), then the REAL closeout() runs.
rm -f "$FX/.git/hooks/pre-push"
CHK="$(cd "$FX" && bash githooks/install.sh --check >/dev/null 2>&1; echo $?)"
CO="$(python3 - "$DRIVER" "$FX" "$LAND_SHA" 2>"$WORK/closeout.err" <<'PY' | tail -1
import argparse, importlib.util, sys
spec = importlib.util.spec_from_file_location("express", sys.argv[1]); express = importlib.util.module_from_spec(spec); spec.loader.exec_module(express)
ns = argparse.Namespace(issue=999, repo="H/H", release=None)
state = {"suite_rc": 0, "paths": ["utils/py/foo.py"], "insertions": 1}
try: express.closeout(sys.argv[2], ns, sys.argv[3], "test/gh999-demo.sh", state); print("CLOSEOUT=completed")
except SystemExit as e: print("CLOSEOUT=exit-%s" % e.code)
PY
)"
DIRTY="$(git -C "$FX" status --porcelain | tr '\n' ';')"
AHEAD="$(git -C "$FX" rev-list --count origin/development..HEAD)"
RECEIPT_N="$(cat "$FX"/TESTS-RESULTS/*+GH-999-express/provenance.jsonl 2>/dev/null | wc -l | tr -d ' ')"
rec "closeout with the stub gone (install --check rc=$CHK)" "$CO" "dirty=[$DIRTY] local-commits-ahead-of-origin=$AHEAD receipt-lines=$RECEIPT_N" "$O0" "$(remote_dev)"

# The wiring is repaired. Round-5 negative controls: with the retained closeout still pending, neither a
# preview nor a request for another repository may add, commit or push; tree, HEAD, origin and index stay put.
(cd "$FX" && bash githooks/install.sh) >/dev/null 2>&1
neg() { # name scenario resume-args...
  local name="$1" what="$2"; shift 2
  local H S O X T="$WORK/trace-$name.log"; : > "$T"
  H="$(git -C "$FX" rev-parse HEAD)"; O="$(remote_dev)"
  S="$({ git -C "$FX" status --porcelain; git -C "$FX" diff; } | shasum | cut -c1-16)"
  env GIT_TRACE="$T" python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh "$@" >"$WORK/$name.out" 2>"$WORK/$name.err"; local RC=$?
  local MUT STAGED
  MUT="$(grep -cE 'built-in: git (add|commit|push)' "$T")"
  STAGED="$(git -C "$FX" diff --cached --name-only | wc -l | tr -d ' ')"
  rec "$what" "rc=$RC" "mutating-git-calls(add/commit/push)=$MUT staged-paths=$STAGED head-unchanged=$([ "$(git -C "$FX" rev-parse HEAD)" = "$H" ] && echo yes || echo NO) tree-unchanged=$([ "$({ git -C "$FX" status --porcelain; git -C "$FX" diff; } | shasum | cut -c1-16)" = "$S" ] && echo yes || echo NO) origin-unchanged=$([ "$(remote_dev)" = "$O" ] && echo yes || echo NO); $(cat "$WORK/$name.out" "$WORK/$name.err" | tail -1 | cut -c1-110)" "$O" "$(remote_dev)"
}
if [ "${GH1576_NEG_ONLY:-}" = dry ]; then neg negdry "negative control: resume --dry-run with the retained closeout pending"  --dry-run; exit 0; fi
if [ "${GH1576_NEG_ONLY:-}" = repo ]; then neg negrepo "negative control: resume --repo wrong/repo with the retained closeout pending" --repo wrong/repo; exit 0; fi
neg negdry "negative control: resume --dry-run with the retained closeout pending"  --dry-run
neg negrepo "negative control: resume --repo wrong/repo with the retained closeout pending" --repo wrong/repo

# Negative control: the repaired clone, but an unrelated file is also dirty -> resume must still refuse.
touch "$FX/unrelated-1576.txt"
H1="$(git -C "$FX" rev-parse HEAD)"
python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh >"$WORK/resume-neg.log" 2>"$ERR"; NRC=$?
rec "resume with an unrelated dirty file (hook repaired)" "rc=$NRC" "head-moved=$([ "$(git -C "$FX" rev-parse HEAD)" = "$H1" ] && echo no || echo YES); $(tail -1 "$ERR" | cut -c1-140)" "$O0" "$(remote_dev)"
rm -f "$FX/unrelated-1576.txt"

# The documented recovery: the same resume command, wiring repaired, nothing else dirty.
python3 "$DRIVER" --root "$FX" resume --issue 999 --suite test/gh999-demo.sh >"$WORK/resume.log" 2>"$ERR"; RRC=$?
LEFT="$(git -C "$FX" status --porcelain | wc -l | tr -d ' ')"
COMMITTED="$(git -C "$FX" ls-tree -r HEAD --name-only | grep -c 'GH-999-express/provenance.jsonl')"
RECEIPT_N2="$(cat "$FX"/TESTS-RESULTS/*+GH-999-express/provenance.jsonl 2>/dev/null | wc -l | tr -d ' ')"
SYNC="$([ "$(git -C "$FX" rev-parse HEAD)" = "$(remote_dev)" ] && echo yes || echo NO)"
ISSUE="$(grep -c '"state":"CLOSED"' "$GH_STATE/issue-999.json")"
SHIPPED="$(python3 -c "import sqlite3,sys; print(sqlite3.connect(sys.argv[1]).execute('select state from manifest_items where id=1').fetchone()[0])" "$FX/releases.db")"
DOC="$([ -f "$FX/PROJECT/3-COMPLETED/GH-999-DEMO-HOTFIX.md" ] && echo moved || echo NOT-moved)"
rec "resume after the hook repair (documented recovery)" "rc=$RRC" "tree-dirty-lines=$LEFT receipt-committed=$COMMITTED receipt-lines=$RECEIPT_N2(was $RECEIPT_N, not regenerated) origin-in-sync=$SYNC issue-closed=$ISSUE manifest=$SHIPPED doc=$DOC; $(tail -1 "$ERR" | cut -c1-120)" "$O0" "$(remote_dev)"
SCENARIO
bash "$RUN" > "$OUT/recover-$LABEL.log" 2>&1
echo "recover.sh $LABEL: exit $? (log: recover-$LABEL.log)"
/usr/bin/grep -E '^\s+\[' "$OUT/recover-$LABEL.log" | cut -c1-420
