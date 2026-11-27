# shellcheck shell=bash
# ── GH-1653 R1-S5 two-resume clone probe (temporary insert; reviewer's script, binding patched) ──
attempt="$FR/.tick/attempts/GH-901-jog-publish"
echo "PROBE: seeded rows before=$(wc -l < "$attempt" | tr -d ' ')"
rm -f "$WORK/gh1653-reserved" "$WORK/gh1653-reserved.continue"
LANE_MAX_ATTEMPTS=3 PYTHONPATH="$FR/utils/py" python3 - "$FR" "$WORK/gh1653-reserved" \
    >"$WORK/gh1653-a.log" 2>&1 <<'PYPROBE' &
import pathlib, runpy, sys, time
import gate_receipt
root, marker = sys.argv[1:]
ready = pathlib.Path(marker)
start = gate_receipt.manual_attempt_start
def hold_after_reserve(*args, **kwargs):
    result = start(*args, **kwargs)
    if result[1] is not None:
        ready.touch()
        for _ in range(300):
            if pathlib.Path(str(ready) + ".continue").exists():
                return result
            time.sleep(0.1)
        raise RuntimeError("publication probe timed out waiting for second resume")
    return result
gate_receipt.manual_attempt_start = hold_after_reserve
app = root + "/utils/py/releases_app.py"
sys.argv = [app, "--root", root, "jog", "resume", "901"]
runpy.run_path(app, run_name="__main__")
PYPROBE
first=$!
for _ in $(seq 1 150); do
  test ! -f "$WORK/gh1653-reserved" || break
  sleep 0.1
done
if ! test -f "$WORK/gh1653-reserved"; then
  wait "$first"; echo "PROBE: A never reserved"; cat "$WORK/gh1653-a.log"
else
  b_rc=0
  LANE_MAX_ATTEMPTS=3 python3 "$FR/utils/py/releases_app.py" --root "$FR" jog resume 901 \
    >"$WORK/gh1653-b.log" 2>&1 || b_rc=$?
  rows_during_b="$(wc -l < "$attempt" | tr -d ' ')"
  touch "$WORK/gh1653-reserved.continue"
  a_rc=0
  wait "$first" || a_rc=$?
  echo "PROBE: resume A exit=$a_rc B exit=$b_rc rows_while_A_held=$rows_during_b total_rows=$(wc -l < "$attempt" | tr -d ' ')"
  echo "PROBE: --- A log ---"; cat "$WORK/gh1653-a.log"
  echo "PROBE: --- B log ---"; cat "$WORK/gh1653-b.log"
fi
echo "PROBE: done"
exit 0
