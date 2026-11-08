#!/usr/bin/env bash
# GH-1031 runtime controls against PR 1024's fixed branch. Stages: prepare | baseline | hookA | hookB
# Runs the real planner (weekly-prepare, then weekly-reconcile) in disposable full clones.
set -u
STAGE="${1:?stage}"
SRC=/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/pr1024-rt      # source_root == harness (fixed branch)
W=/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/wk1031           # disposable roots
OUT=/private/tmp/claude-501/pr1024-rt-run                                  # receipts (sandbox-readable)
PC="$SRC/skills/3-weekly/weekly-planner/scripts/planner_core.py"
REPO=HiQS-Labs/XYZ-forge
D1=2026-10-17; D2=2026-10-18
export XYZ_HARNESS="$SRC" PYTHONDONTWRITEBYTECODE=1
mkdir -p "$W" "$OUT"
log(){ echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$OUT/run.log"; }
SINCE_FILE="$W/since.txt"

if [ "$STAGE" = prepare ]; then
  rm -rf "$W"; mkdir -p "$W/hooksA" "$W/hooksB"; : > "$OUT/run.log"
  python3 -c 'from datetime import datetime,timezone,timedelta;print((datetime.now(timezone.utc)-timedelta(days=7)).isoformat())' > "$SINCE_FILE"
  cat > "$W/hooksA/pre-commit" <<'EOF'
#!/bin/sh
# control (a): a hook stages extra content into the ancestry merge commit only
GD=$(git rev-parse --git-dir); [ -f "$GD/MERGE_HEAD" ] || exit 0
echo sabotage > HOOK-PLANTED.md && git add HOOK-PLANTED.md
EOF
  cat > "$W/hooksB/pre-commit" <<'EOF'
#!/bin/sh
# control (b): the ancestry merge commit acquires a third parent, tree unchanged
GD=$(git rev-parse --git-dir); [ -f "$GD/MERGE_HEAD" ] || exit 0
git rev-parse HEAD~1 >> "$GD/MERGE_HEAD"
EOF
  chmod +x "$W"/hooks*/pre-commit
  log "git $(git --version); planner $(git -C "$SRC" rev-parse --short HEAD) on $(git -C "$SRC" branch --show-current)"
  log "weekly-prepare D1=$D1 -> $W/pred"
  python3 "$PC" --repo-root "$SRC" --gh-repo "$REPO" --mode weekly-prepare --prepare-root "$W/pred" \
    --planning-date "$D1" --target-ref development --since "$(cat "$SINCE_FILE")" \
    --initial-backfill updated-only --overlap-hours 2 --apply > "$OUT/prepare.json" 2> "$OUT/prepare.err"
  # updated-only: all-open refuses on two pre-existing ledger rows (#61, #67) with no capture doc
  # ("existing canonical row has no capture; explicit reconciliation required") — unrelated to GH-1031.
  log "prepare rc=$? complete=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("complete"))' "$OUT/prepare.json" 2>/dev/null)"
  [ -d "$W/pred/.git" ] || { log "no predecessor clone; abort"; exit 1; }
  log "pred branch=$(git -C "$W/pred" branch --show-current) head=$(git -C "$W/pred" rev-parse HEAD) clean=$(git -C "$W/pred" status --short | wc -l | tr -d ' ')"
  for s in baseline hookA hookB; do cp -R "$W/pred" "$W/pred-$s"; done
  log "predecessor copies made"
  exit 0
fi

PRED="$W/pred-$STAGE"; NEW="$W/new-$STAGE"
PRED_HEAD=$(git -C "$PRED" rev-parse HEAD)
cat > "$W/auth-$STAGE.json" <<EOF
{"schema":"weekly/authorities@1","roots":[{"id":"pred","root":"$PRED","repository":"$REPO","contexts":[]}]}
EOF
case "$STAGE" in
  baseline) HOOKENV=() ;;
  hookA)    HOOKENV=(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0="$W/hooksA") ;;
  hookB)    HOOKENV=(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0="$W/hooksB") ;;
  *) echo "unknown stage"; exit 2 ;;
esac
log "weekly-reconcile [$STAGE] pred=$PRED head=$PRED_HEAD -> $NEW"
env ${HOOKENV[@]+"${HOOKENV[@]}"} python3 "$PC" --repo-root "$SRC" --gh-repo "$REPO" --mode weekly-reconcile \
  --prepare-root "$NEW" --planning-date "$D2" --target-ref development --since "$(cat "$SINCE_FILE")" \
  --initial-backfill updated-only --overlap-hours 2 --authority-file "$W/auth-$STAGE.json" \
  --predecessor-root "$PRED" --expected-predecessor-head "$PRED_HEAD" --apply > "$OUT/$STAGE.json" 2> "$OUT/$STAGE.err"
RC=$?
log "[$STAGE] rc=$RC status=$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));print(d.get("status"),d.get("complete"),"|",d.get("error",""))' "$OUT/$STAGE.json" 2>/dev/null)"
if [ -d "$NEW/.git" ]; then
  log "[$STAGE] new HEAD parents: $(git -C "$NEW" rev-list --parents -n1 HEAD)"
  log "[$STAGE] new HEAD subject: $(git -C "$NEW" log -1 --format=%s)"
  log "[$STAGE] HOOK-PLANTED in HEAD tree: $(git -C "$NEW" ls-tree --name-only HEAD | grep -c HOOK-PLANTED)"
  log "[$STAGE] MERGE_HEAD present: $([ -f "$NEW/.git/MERGE_HEAD" ] && echo yes || echo no); dirty=$(git -C "$NEW" status --short | wc -l | tr -d ' ')"
  git -C "$NEW" log --format='%h parents=%p %s' -10 > "$OUT/$STAGE.gitlog.txt"
fi
cp "$PRED/.git/weekly-$D1.json" "$OUT/$STAGE.receipt.json" 2>/dev/null
log "[$STAGE] receipt phase=$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));print(d.get("phase"),"pending_merge=",d.get("pending_merge"))' "$OUT/$STAGE.receipt.json" 2>/dev/null)"
exit 0
