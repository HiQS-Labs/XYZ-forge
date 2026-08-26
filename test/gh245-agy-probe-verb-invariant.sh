#!/usr/bin/env bash
# gh1-adoption-guard: exempt — static source audit only; mentions agy probe verbs as DATA,
# creates no filesystem fixtures outside its own mktemp negative-control sandbox.
#
# test/gh245-agy-probe-verb-invariant.sh — GH-245 regression guard.
#
# WHY THIS EXISTS (the recurrence this pins shut):
# The agy auth pre-flight verb had no invariant binding its call sites together, so the SAME defect
# was found and fixed three separate times, each fix landing on one site while a sibling kept it:
#
#   GH-130  fixed agy-turn.py  (non-zero `whoami` no longer fatal)   — consult.py left broken
#   #135    fixed consult.py   — its body says outright: "consult.py still carries the exact
#                                defect #130 fixed in agy-turn.py"
#   #221    fixed both         — probe `models`, not `whoami`; agy >=1.1.19 removed `whoami`
#
# The failure mode is quiet: the affected lane loses its agy seat and the remedy text blames the
# operator's credentials ("Run `agy login`") for something that has nothing to do with auth. A
# consult was observed failing (`agy auth pre-flight failed (exit 2)`) while an agy-turn relay lane
# on the SAME vendored copy and the SAME agy binary succeeded — purely because of this divergence.
#
# WHAT IS CHECKED (two invariants, both static):
#   1. AGREEMENT — every `[agy_bin, "<verb>"]` probe under utils/py/ uses the SAME verb. A fix that
#      lands on one site and misses another fails here instead of shipping.
#   2. LIVENESS  — that verb is not a known-removed subcommand (`whoami`, removed in agy >=1.1.19).
#
# WHY STATIC AND NOT AN EXECUTION PROBE: `agy models` has been observed to hang past 120s (cf. #237),
# so shelling out to the real CLI would make this suite flaky for the same reason the runtime path
# already degrades to `unverifiable`. This audit needs no agy binary and no network.
#
# SCOPE — the Bash twins are deliberately NOT audited. relay-automation/consult.sh and agy-turn.sh
# still probe `whoami`, and that is correct by policy: AGENTS.md:183-201 freezes the twelve Bash
# twins ("put behavior fixes in the named Python twin, not the Bash body"), enforced by
# test/gh308-frozen-twin-guard.sh. They are XYZ_PYTHON=0 fallbacks. Auditing them would demand an
# edit the frozen-twin guard rejects — an unfixable failure. Python is the canonical layer and the
# only one where a fix is permitted, so it is the only one this invariant covers.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh245-agy-probe-verb-invariant =="

# Known-removed agy subcommands. `whoami` was removed in agy >=1.1.19 (#221); a probe using it
# exits 2 with `Error: unexpected argument "whoami".` on every invocation, forever.
DEAD_VERBS="whoami"

# Collect probe verbs from a directory tree. Matches the real invocation shape only —
# `[agy_bin, "<verb>"]` inside a subprocess call — so prose ABOUT the bug (comments in consult.py
# and rtl.py that name `whoami` while explaining the history) is never mistaken for a live probe.
# Emits "<file>:<line>:<verb>" per hit.
#
# A leading `-` is excluded deliberately: agy SUBCOMMANDS are bare words (`models`, `agents`), while
# the real advisory invocation leads with a flag — `[agy_bin, "--dangerously-skip-permissions", …]`
# at consult.py:529. Without this the guard flags that live call as a disagreeing "probe verb",
# which it is not. Caught by this test's own first run.
collect_probes() {  # <root-dir>
  local root="$1"
  python3 - "$root" <<'PY'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
# agy_bin / AGY_BIN as the program, followed by a quoted SUBCOMMAND as the first argument.
# `[A-Za-z0-9_]` first char excludes flags (see the note above the caller).
pat = re.compile(r'''\[\s*(?:agy_bin|AGY_BIN)\s*,\s*["']([A-Za-z0-9_][A-Za-z0-9_-]*)["']''')
for p in sorted(root.rglob("*.py")):
    for i, line in enumerate(p.read_text(errors="ignore").splitlines(), 1):
        stripped = line.lstrip()
        if stripped.startswith("#"):
            continue  # a comment mentioning a verb is documentation, not a probe
        m = pat.search(line)
        if m:
            print(f"{p}:{i}:{m.group(1)}")
PY
}

# ── Invariant 1 + 2, against the real tree ────────────────────────────────────
PROBES="$(collect_probes "$REPO/utils/py")"

if [ -z "$PROBES" ]; then
  # Not a vacuous pass: zero probes means the shape moved and this guard is auditing nothing,
  # which is exactly how a guard silently stops guarding (cf. GH-368, GH-38).
  fail "no [agy_bin, <verb>] probes found under utils/py — the guard is auditing nothing; update its pattern"
  echo "  gh245-agy-probe-verb-invariant: $PASS passed, $FAIL failed"
  exit 1
fi

VERBS="$(echo "$PROBES" | awk -F: '{print $NF}' | sort -u)"
N_VERBS="$(grep -c . <<<"$VERBS")"
N_SITES="$(grep -c . <<<"$PROBES")"

if [ "$N_VERBS" -ne 1 ]; then
  fail "agy probe verbs DISAGREE across call sites ($(echo "$VERBS" | paste -sd, -)) — a fix landed on one site and missed a sibling:"
  echo "$PROBES" | sed "s|^$REPO/|    |" >&2
else
  pass "all $N_SITES agy probe site(s) agree on verb '$VERBS'"
fi

for dead in $DEAD_VERBS; do
  # capture-then-match, not pipe-into-grep -q (GH-139: the pipe shape races SIGPIPE under pipefail)
  if grep -qx "$dead" <<<"$VERBS"; then
    fail "agy probe uses removed subcommand '$dead' — agy >=1.1.19 exits 2 with a usage error (#221)"
    echo "$PROBES" | grep ":$dead\$" | sed "s|^$REPO/|    |" >&2
  fi
done
[ "$FAIL" -eq 0 ] && pass "probe verb is not a known-removed subcommand ($DEAD_VERBS)"

# ── Negative control: prove the guard DETECTS, rather than merely passing ──────
# Without this, a guard whose pattern silently stopped matching would look identical to a clean
# tree. Build a throwaway sandbox reproducing the pre-#221 divergence (one site on `whoami`) and
# assert the collector sees both verbs.
CTL="$(mktemp -d)"
if [ -z "$CTL" ] || [ ! -d "$CTL" ]; then
  fail "negative control: mktemp -d failed"
else
  trap 'rm -rf "$CTL"' EXIT
  mkdir -p "$CTL/py"
  cat > "$CTL/py/agy-turn.py" <<'EOF'
subprocess.run([agy_bin, "models"], timeout=secs, check=True)
EOF
  cat > "$CTL/py/consult.py" <<'EOF'
# historical: agy 1.1.18 has no `whoami` subcommand — this comment must NOT be counted
subprocess.run([agy_bin, "whoami"], timeout=secs, check=True)
EOF
  CTL_VERBS="$(collect_probes "$CTL/py" | awk -F: '{print $NF}' | sort -u | paste -sd, -)"
  if [ "$CTL_VERBS" = "models,whoami" ]; then
    pass "negative control: pre-#221 divergence is detected (saw '$CTL_VERBS')"
  else
    fail "negative control: expected to detect 'models,whoami', saw '$CTL_VERBS' — the collector pattern no longer matches the real invocation shape"
  fi

  # And prove the comment-skip is real: a file whose ONLY mention of a dead verb is a comment
  # must contribute no probe at all.
  mkdir -p "$CTL/py2"
  cat > "$CTL/py2/rtl.py" <<'EOF'
# `Error: unexpected argument "whoami".` — prose about the bug, not a probe
#   subprocess.run([agy_bin, "whoami"])
EOF
  if [ -z "$(collect_probes "$CTL/py2")" ]; then
    pass "negative control: commented-out / prose mentions of a verb are not counted as probes"
  else
    fail "negative control: a comment-only mention was counted as a live probe (false positive)"
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  gh245-agy-probe-verb-invariant: $PASS passed, $FAIL failed"
  exit 1
fi
echo "  gh245-agy-probe-verb-invariant: $PASS passed, $FAIL failed"
exit 0
