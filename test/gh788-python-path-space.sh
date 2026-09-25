#!/usr/bin/env bash
# test/gh788-python-path-space.sh — GH-788: an interpreter under a path with a space.
#
# `'#!' + sys.executable` stubs fail with ENOEXEC and unquoted `f"{sys.executable} …"` command strings
# split in two whenever Python lives under a spaced path (a venv in `…/GH Repos/…`). This suite pins:
#   1. test/lib/pystub.launcher() runs the EXACT selected interpreter — ordinary and spaced — with an
#      empty PATH, a spaced stub path and a spaced argument; it refuses a path it cannot embed;
#   2. red control: a bare `#!<spaced interpreter>` stub still fails (the defect is real);
#   3. fuzz_engine.build_argv keeps a shlex-quoted spaced interpreter as one argv word (red: unquoted splits);
#   4. ratchet: no tracked bare-shebang or unquoted-interpreter sites remain, and the same matcher
#      flags a planted sample; a scan error is a failure, never "zero sites".
source "$(dirname "$0")/_setup.sh" gh788-python-path-space

REPO="$(cd "$(dirname "$0")/.." && pwd)"
echo "== test: gh788-python-path-space =="

# --- 1–3: runtime behaviour ------------------------------------------------------------------
out="$(PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$REPO/test/lib:$REPO/utils/py" python3 - "$WORK" <<'PY' 2>&1
import os, subprocess, sys, tempfile
import pystub, fuzz_engine

_tmp = tempfile.TemporaryDirectory(dir="/tmp", prefix="gh788.")  # /tmp: the "ordinary" path must hold no space; removed at exit
work = _tmp.name
real = os.path.realpath(sys.executable)

def interpreter(dirname):
    """A stand-in interpreter that records which path was executed, then runs the real Python."""
    d = os.path.join(work, dirname); os.makedirs(d)
    p = os.path.join(d, "python3")
    with open(p, "w") as f:
        f.write('#!/bin/sh\nprintf %s "$0" > "$GH788_MARK"\nexec "$GH788_REAL" "$@"\n')
    os.chmod(p, 0o755)
    return p

def run(stub, args, mark):
    env = {"PATH": "", "GH788_MARK": mark, "GH788_REAL": real}
    return subprocess.run([stub] + args, capture_output=True, text=True, env=env, timeout=60)

body = "import sys\nprint('|'.join(sys.argv[1:]))\n"
os.makedirs(os.path.join(work, "stub dir"))
for label, interp in (("ordinary", interpreter("plain")), ("spaced", interpreter("py with space"))):
    stub = os.path.join(work, "stub dir", f"{label} stub")
    header = pystub.launcher(interp)
    compile(header + "pass\n", "<header>", "exec")
    with open(stub, "w") as f:
        f.write(header + body)
    os.chmod(stub, 0o755)
    mark = os.path.join(work, f"{label}.mark")
    r = run(stub, ["x y", "z"], mark)
    ran = open(mark).read() if os.path.exists(mark) else "<nothing ran>"
    ok = r.returncode == 0 and r.stdout.strip() == "x y|z" and ran == interp
    print(("PASS" if ok else "FAIL") + f": launcher runs the exact {label} interpreter with PATH='' and argv 'x y'"
          + ("" if ok else f" (rc={r.returncode} out={r.stdout!r} err={r.stderr[-200:]!r} ran={ran!r})"))

for bad in ("/tmp/it's/python3", "/tmp/py\rpath/python3", "/tmp/py\\path/python3", ""):
    try:
        pystub.launcher(bad)
        print(f"FAIL: launcher accepted an unembeddable path {bad!r}")
    except ValueError:
        pass
else:
    print("PASS: launcher refuses paths it cannot embed (quote, CR, backslash, empty)")

# Red control: the pre-fix construction still fails with the spaced interpreter.
spaced = os.path.join(work, "py with space", "python3")
bare = os.path.join(work, "bare-stub")
with open(bare, "w") as f:
    f.write("#!" + spaced + "\n" + body)
os.chmod(bare, 0o755)
try:
    r = run(bare, ["x"], os.path.join(work, "bare.mark"))
    print(("PASS" if r.returncode != 0 else "FAIL") + f": red control — bare spaced shebang does not run (rc={r.returncode})")
except OSError as e:
    print(f"PASS: red control — bare spaced shebang does not run ({e.__class__.__name__})")

import shlex
tool = "/tmp/tool with space.py"
quoted = fuzz_engine.build_argv(f"{shlex.quote(spaced)} {shlex.quote(tool)} {{mutant}}", ["x y"])
unquoted = fuzz_engine.build_argv(f"{spaced} {shlex.quote(tool)} {{mutant}}", ["x y"])
print(("PASS" if quoted == [spaced, tool, "x y"] else f"FAIL (got {quoted})") + ": build_argv keeps a quoted spaced interpreter as one word")
print(("PASS" if unquoted[0] != spaced else f"FAIL (got {unquoted})") + ": red control — an unquoted spaced interpreter splits")
PY
)"
while IFS= read -r line; do
  case "$line" in PASS:*) pass "${line#PASS: }" ;; FAIL*) fail "${line}" ;; esac
done <<<"$out"
grep -q '^PASS: build_argv' <<<"$out" || fail "runtime block did not report (python error?)"

# --- 4: ratchet --------------------------------------------------------------------------------
# One matcher for the tree scan and the planted sample. Patterns are assembled from pieces so this
# file never matches itself.
Q="['\"]"
BARE="${Q}#!${Q} *\\+ *sys\\.executable"
UNQ="f${Q}\\{sys\\.executable\\} "
BASHPY='--target "\$PY '   # bash suites: the shell-quoted form is $PYQ (gen4 phase3/4)
scan() {  # scan <dir> <git-grep path args...>; echoes matches; rc 0 = match, 1 = none, else error
  local dir="$1"; shift
  git -C "$dir" grep -n -E -e "$BARE" -e "$UNQ" -e "$BASHPY" "$@"
}
# This suite holds the planted samples, so it is the one file excluded from the tree scan.
hits="$(scan "$REPO" -- test utils relay-automation skills ':(exclude)test/gh788-python-path-space.sh')"; rc=$?
case "$rc" in
  1) pass "ratchet: no bare-shebang or unquoted-interpreter sites in test/ utils/ relay-automation/ skills/" ;;
  0) fail "ratchet: GH-788 sites remain — use pystub.launcher() / shlex.quote(sys.executable):"$'\n'"$hits" ;;
  *) fail "ratchet: scan error (git grep rc=$rc) — not treated as zero sites" ;;
esac

PLANT="$WORK/planted.py"
printf '%s\n' "stub.write_text('#!' + sys.executable + '\\n')" > "$PLANT"
scan "$WORK" --no-index -- planted.py >/dev/null; rc=$?
[ "$rc" -eq 0 ] && pass "ratchet red control: flags a planted bare shebang" || fail "ratchet missed a planted bare shebang (rc=$rc)"
printf '%s\n' 'fuzz(f"{sys.executable} tool.py {{mutant}}")' > "$PLANT"
scan "$WORK" --no-index -- planted.py >/dev/null; rc=$?
[ "$rc" -eq 0 ] && pass "ratchet red control: flags a planted unquoted interpreter" || fail "ratchet missed a planted unquoted interpreter (rc=$rc)"
printf '%s\n' 'python3 "$FUZZ" --mode fuzz --target "$PY tool.py {mutant}"' > "$PLANT"
scan "$WORK" --no-index -- planted.py >/dev/null; rc=$?
[ "$rc" -eq 0 ] && pass "ratchet red control: flags a planted unquoted \$PY fuzz target" || fail "ratchet missed a planted unquoted \$PY fuzz target (rc=$rc)"
printf '%s\n' 'subprocess.run([sys.executable, "tool.py"])' 'fuzz(f"{shlex.quote(sys.executable)} tool.py {{mutant}}")' 'python3 "$FUZZ" --target "$PYQ tool.py {mutant}"' > "$PLANT"
scan "$WORK" --no-index -- planted.py >/dev/null; rc=$?
[ "$rc" -eq 1 ] && pass "ratchet ignores safe argv lists and quoted interpreters" || fail "ratchet flagged a safe form (rc=$rc)"

echo "  gh788-python-path-space: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
