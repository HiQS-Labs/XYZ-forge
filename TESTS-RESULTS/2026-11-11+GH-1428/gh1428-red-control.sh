#!/usr/bin/env bash
# GH-1428 manual check (not a suite): drive relay_drive.py against the real GH-955 builder block and
# a scripted reviewer turn, on the pre-fix base and the fix commit. Usage:
#   gh1428-red-control.sh <xyz-clone> <base-sha> <fix-sha> <builder.md> <reviewer.md> <workdir>
set -u
SRC="$1" BASE="$2" FIX="$3" BLD="$4" REV="$5" W="$6"
rm -rf "$W"; mkdir -p "$W"
for v in base fix; do
  sha=$BASE; [ "$v" = fix ] && sha=$FIX
  mkdir -p "$W/$v"; git -C "$SRC" archive "$sha" utils relay-automation bin src package.json | tar -x -C "$W/$v"
  git -C "$W/$v" init -q && git -C "$W/$v" add -A && git -C "$W/$v" commit -qm seed
done

STUB="$W/reviewer.sh"   # plays the reviewer: appends REVIEW_TEXT, sets STATUS: Approved, tick done
cat >"$STUB" <<'EOF'
#!/usr/bin/env bash
f="$RELAY_FILE"
printf '\n%s\n' "$(cat "$REVIEW_TEXT_FILE")" >>"$f"
perl -pi -e 's/^STATUS:.*/STATUS: Approved/; s/^NEXT:.*/NEXT: done/' "$f"
"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths relay.md >/dev/null 2>&1
"$TICK_BIN" done "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
exit 0
EOF
chmod +x "$STUB"

run() { # <label> <harness base|fix> <gate-env-or-empty> <extra reviewer line or empty>
  local label="$1" h="$W/$2" gate="$3" extra="$4" A="$W/repo-$1"
  mkdir -p "$A"; printf '.tick/\n' >"$A/.gitignore"
  { printf '# Marathon Phase gh-955\nSTATUS: Open\nNEXT: claude-reviewer (Reviewer)\n\n'; cat "$BLD"; } >"$A/relay.md"
  git -C "$A" init -q && git -C "$A" add -A && git -C "$A" commit -qm seed
  { cat "$REV"; [ -n "$extra" ] && printf '%s\n' "$extra"; } >"$W/review-$label.md"
  local T="$h/bin/tick" task="GH1428-$label"
  TICK_REPO_ROOT="$A" "$T" init >/dev/null 2>&1
  TICK_REPO_ROOT="$A" "$T" log task.created "$task" --agent marathon >/dev/null
  TICK_REPO_ROOT="$A" "$T" claim "$task" --agent marathon --paths relay.md >/dev/null
  TICK_REPO_ROOT="$A" "$T" release "$task" --agent marathon --to claude-reviewer >/dev/null
  ( cd "$h" && env -u RELAY_DRIVER_LOCKED -u MARATHON_REVIEWER_GATE_CMD ${gate:+MARATHON_REVIEWER_GATE_CMD="$gate"} \
      RELAY_TARGET_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$T" XYZ_ROOT="$h" RELAY_WORKTREE_ISOLATION=0 \
      REVIEW_TEXT_FILE="$W/review-$label.md" \
      python3 "$h/utils/py/relay_drive.py" --relay-file "$A/relay.md" --relay-task "$task" \
      --agent-cmd "$STUB" --reviewer claude-reviewer --builder codex --review-once >"$W/out-$label.log" 2>&1 )
  local rc=$? reason rec
  reason="$(cat "$h/.relay-scratch/escalation-reason" 2>/dev/null)"; rm -f "$h/.relay-scratch/escalation-reason"
  rec="$(git -C "$A" rev-parse --absolute-git-dir)/relay-attest/$task.json"
  printf '%-34s rc=%s reason=%-20s gate_run=%s trailer=%s\n' "$label" "$rc" "${reason:--}" \
    "$( [ -f "$rec" ] && python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("gate_run","(absent)"))' "$rec" || echo '(no record)')" \
    "$(grep -m1 '^gate-run:' "$A/relay.md" || echo '-')"
}

G='.venv/bin/pytest -q tests/test_dashboard_snapshot_refresh_filter.py'
run base-red-control          base "$G" ""
run fix-armed-no-declaration  fix  "$G" ""
run fix-armed-gate-no         fix  "$G" "gate run: no — DB unreachable"
run fix-armed-yes-exit1       fix  "$G" "gate run: yes — exit 1"
run fix-armed-yes-exit124     fix  "$G" "gate run: yes — exit 124"
run fix-armed-yes-no-exit     fix  "$G" "gate run: yes"
run fix-armed-yes-exit0       fix  "$G" "gate run: yes — exit 0"
run fix-unarmed-generic       fix  ""   ""
