#!/usr/bin/env bash
# GH-1465 manual check (not a suite; adapted from TESTS-RESULTS/2026-11-11+GH-1428/gh1428-red-control.sh):
# drive relay_drive.py against the real GH-955 builder block and a scripted reviewer turn, on the
# pre-fix base and the fix commit, with a gate command the DRIVER must run. Usage:
#   gh1465-red-control.sh <xyz-clone> <base-sha> <fix-sha> <builder.md> <reviewer.md>
set -u
SRC="$1" BASE="$2" FIX="$3" BLD="$4" REV="$5"
W="$(mktemp -d "${TMPDIR:-/tmp}/gh1465.XXXXXX")" || exit 2
for v in base fix; do
  sha=$BASE; [ "$v" = fix ] && sha=$FIX
  mkdir -p "$W/$v"; git -C "$SRC" archive "$sha" utils relay-automation bin src package.json | tar -x -C "$W/$v"
  git -C "$W/$v" init -q && git -C "$W/$v" add -A && git -C "$W/$v" commit -qm seed
done
sed 's/[Uu]nverified/checked/g' "$BLD" >"$W/builder-clean.md"   # a builder block that declares nothing unverified

STUB="$W/reviewer.sh"   # plays the reviewer: appends REVIEW_TEXT, sets STATUS: Approved, tick done
cat >"$STUB" <<'STUBEOF'
#!/usr/bin/env bash
f="$RELAY_FILE"
printf '\n%s\n' "$(cat "$REVIEW_TEXT_FILE")" >>"$f"
perl -pi -e 's/^STATUS:.*/STATUS: Approved/; s/^NEXT:.*/NEXT: done/' "$f"
"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths relay.md >/dev/null 2>&1
"$TICK_BIN" done "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
exit 0
STUBEOF
chmod +x "$STUB"

run() { # <label> <harness base|fix> <gate-env-or-empty> <extra reviewer line or empty> <builder file>
  local label="$1" h="$W/$2" gate="$3" extra="$4" bld="$5" A="$W/repo-$1"
  mkdir -p "$A"; printf '.tick/\n' >"$A/.gitignore"
  printf '#!/usr/bin/env bash\necho "gate ran in $(basename "$PWD") RELAY_ROLE=${RELAY_ROLE:-scrubbed}"; exit "${1:-0}"\n' >"$A/gate.sh"
  { printf '# Marathon Phase gh-955\nSTATUS: Open\nNEXT: claude-reviewer (Reviewer)\n\n'; cat "$bld"; } >"$A/relay.md"
  git -C "$A" init -q && git -C "$A" add -A && git -C "$A" commit -qm seed
  { cat "$REV"; [ -n "$extra" ] && printf '%s\n' "$extra"; } >"$W/review-$label.md"
  local T="$h/bin/tick" task="GH1465-$label"
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
  printf '%-30s rc=%s reason=%-19s record=%s trailer=%s residue=%s\n' "$label" "$rc" "${reason:--}" \
    "$( [ -f "$rec" ] && python3 -c 'import json,sys;r=json.load(open(sys.argv[1]));print("gate_run:%s,gate_exit:%s,gate_cmd:%s" % (r.get("gate_run","(absent)"),r.get("gate_exit","(absent)"),r.get("gate_cmd","(absent)")))' "$rec" || echo '(none)')" \
    "$(grep -m1 '^driver-gate:' "$A/relay.md" || echo '-')" \
    "$(git -C "$A" status --porcelain --untracked-files=all | tr '\n' ' ')"
  grep -h 'driver-run gate\|  | ' "$W/out-$label.log" | sed "s#$W#<scratch>#g; s/^/    /"
  if [ -f "$rec" ] && [ "$2" = fix ]; then   # the record still validates against its own trailer
    ( cd "$h/utils/py" && python3 -c 'import sys,relay_attest as a; r,why=a.load(sys.argv[1],expected_reviewer="claude-reviewer",relay_file=sys.argv[2],target_repo=sys.argv[3]); print("    load:", "ok" if r else "REFUSED "+why)' "$task" "$A/relay.md" "$A" )
  fi
}

Y="gate run: yes — exit 0"
run base-declared-yes-gate-red   base "bash gate.sh 1" "$Y" "$BLD"                # red control: pre-fix trusts the declaration
run fix-declared-yes-gate-red    fix  "bash gate.sh 1" "$Y" "$BLD"                # same input, driver runs the gate
run fix-clean-builder-gate-red   fix  "bash gate.sh 1" "$Y" "$W/builder-clean.md" # refused even when nothing was declared unverified
run fix-undeclared-gate-green    fix  "bash gate.sh 0" ""   "$BLD"                # green gate attests without any declaration
run fix-gate-green-leaves-file   fix  "touch gate-residue.txt" "" "$BLD"          # residue in the tree does not fail the driver
run fix-gate-not-runnable        fix  "./no-such-gate" ""   "$BLD"                # exit 127 refuses
run fix-unarmed-generic          fix  ""               ""   "$BLD"                # no gate configured: unchanged
