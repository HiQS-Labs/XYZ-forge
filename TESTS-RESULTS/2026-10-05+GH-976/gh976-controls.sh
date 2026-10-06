#!/usr/bin/env bash
# GH-976 manual controls A–E. Usage: gh976-controls.sh <harness-root> <case>
# Each case builds a fixture repo under $TMPDIR, seeds a tick token, and dispatches a stub that
# commits INSIDE the turn and keeps handing the token off; never approves; --round-cap 2.
# Prints EXPECT/GOT lines and exits 0 when the candidate-side expectation holds, 10 when not.
set -u
ROOT="${1:?harness root}"; CASE="${2:?case A|B|C|D|E}"
W="$(mktemp -d "${TMPDIR:-/tmp}/gh976-$CASE.XXXXXX")"; trap 'rm -rf "$W"' EXIT
A="$W/repo"; mkdir -p "$A/relay-system" "$A/notes" "$A/src"; git -C "$A" init -q -b main
git -C "$A" config user.email t@t; git -C "$A" config user.name t
RELAY="$A/relay.md"; [ "$CASE" = B ] && RELAY="$A/notes/thread.md"
printf 'STATUS: Open\nNEXT: test (Builder)\n# relay body\n' >"$RELAY"
printf '.tick/\n' >"$A/.gitignore"; echo seed >"$A/relay-system/receipt.md"; echo seed >"$A/src/repair.py"
git -C "$A" add -A && git -C "$A" commit -q -m seed
export TICK="$ROOT/bin/tick" TICK_BIN="$ROOT/bin/tick" TICK_REPO_ROOT="$A" RELAY_TARGET_ROOT="$A" FIXTURE_REPO="$A" CASE
export XYZ_HARNESS_LOGGING=0 XYZ_DEVICE_CONFIG_PATH=/dev/null
STUB="$W/agent"; cat >"$STUB" <<'S'
#!/usr/bin/env bash
"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths relay.md >/dev/null 2>&1
R="${FIXTURE_REPO:-$RELAY_TARGET_ROOT}"
n=1; [ -f "$R/.stub_count" ] && n=$(cat "$R/.stub_count"); echo $((n+1)) >"$R/.stub_count"
case "$CASE" in
  A) echo "turn $n" >> "$R/relay-system/receipt.md"; paths="relay-system/receipt.md" ;;
  B) echo "turn $n" >> "$RELAY_FILE"; paths="$RELAY_FILE" ;;
  C|E) echo "turn $n" >> "$R/src/repair.py"; paths="src/repair.py" ;;
  D) echo "turn $n" >> "$R/relay-system/receipt.md"; echo "turn $n" >> "$R/src/repair.py"; paths="relay-system/receipt.md src/repair.py" ;;
esac
# The driver refreshes the git index concurrently (index.lock); retry briefly like a real shim would.
ok=0; for try in 1 2 3 4 5 6 7 8; do
  if git -C "$R" add $paths 2>>"$R/.stub.log" && git -C "$R" commit -q -m "relay(X): $RELAY_AGENT turn ($CASE) $n" 2>>"$R/.stub.log"; then ok=1; break; fi
  sleep 0.5
done
[ "$ok" = 1 ] || echo "COMMIT FAILED after retries agent=$RELAY_AGENT turn=$n" >>"$R/.stub.log"
if [ "$RELAY_AGENT" = test ]; then n2=other; else n2=test; fi
"$TICK_BIN" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to "$n2" >/dev/null 2>&1
S
chmod +x "$STUB"
"$TICK" init >/dev/null; "$TICK" log task.created T --agent d >/dev/null
"$TICK" claim T --agent d --paths relay.md >/dev/null; "$TICK" release T --agent d --to test >/dev/null
# E: point the driver's HEAD sampling at a non-git dir so before/after SHAs are empty
[ "$CASE" = E ] && { export RELAY_TARGET_ROOT="$W/notgit"; mkdir -p "$W/notgit"; }
out="$(python3 "$ROOT/utils/py/relay_drive.py" --relay-file "$RELAY" --agent-cmd "$STUB" --relay-task T --round-cap 2 --reviewer test --builder other 2>&1)"; rc=$?
[ -n "$out" ] || { echo "GOT: empty output"; exit 10; }
ext=$(grep -c "bounded extension granted" <<<"$out"); rec=$(grep -c "Extension · System" "$RELAY")
reason=$(grep -oE "cap-stalled|cap-progressing-extended" <<<"$out" | tail -1)
turns=$(git -C "$A" rev-list --count HEAD 2>/dev/null); turns=$((turns-1))
grep -q "COMMIT FAILED" "$A/.stub.log" 2>/dev/null && { echo "STUB LOG:"; cat "$A/.stub.log"; }
echo "GOT: rc=$rc reason=${reason:-none} extensions=$ext extension_records=$rec stub_turns=$turns"
case "$CASE" in
  A|B|E) echo "EXPECT: rc=4 reason=cap-stalled extensions=0 extension_records=0 stub_turns=2"
         [ "$rc" = 4 ] && [ "$reason" = cap-stalled ] && [ "$ext" = 0 ] && [ "$rec" = 0 ] && [ "$turns" = 2 ] && exit 0; exit 10 ;;
  C|D)   echo "EXPECT: rc=4 reason=cap-progressing-extended extensions>=1 extension_records>=1 stub_turns=4"
         [ "$rc" = 4 ] && [ "$reason" = cap-progressing-extended ] && [ "$ext" -ge 1 ] && [ "$rec" -ge 1 ] && [ "$turns" = 4 ] && exit 0; exit 10 ;;
esac
