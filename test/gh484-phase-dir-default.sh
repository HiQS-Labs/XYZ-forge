#!/usr/bin/env bash
# test/gh484-phase-dir-default.sh — GH-484 regression.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh484-phase-dir-default.sh; pre-fix revision: marathon_drive.py/marathon-drive.sh before the GH-484 flip, where the phases-dir default was os.path.join(root,'phases') / \"$ROOT/phases\" and the dirty-tree exclusion was the literal 'phases/' (Python) and the awk regex /^phases\\// (Bash); pre-fix result: case (1) writes marathon-system/ never appears and phases/p1/RELAY.md is created instead, and case (3) reports the nested phase output as a stray dirty file so --require-clean hard-stops; post-fix result: 8/0"}
#
# Two properties, one file.
#
# (A) THE DEFAULT. The phase-output directory defaults to `marathon-system/`, matching the
#     `relay-system/` naming already in the tree. `--phases-dir` / PHASES_DIR override it exactly as
#     before — only the default value moved. Both twins must agree, because marathon.sh computes its
#     OWN default independently (marathon.sh:167) and forwards it explicitly on every phase; a flip
#     applied to only one of the two would silently split a marathon.sh run from a direct
#     marathon-drive run.
#
# (B) THE CONTAINMENT LITERAL. The dirty-tree pre-flight excluded a hardcoded "phases/" rather than
#     the CONFIGURED directory, so it was already wrong before this rename for anyone passing
#     --phases-dir: their own phase output was reported as a stray file, and --require-clean
#     hard-stopped on it. The comparison must be the full repo-relative path, not a basename —
#     `--phases-dir state/marathon-runs` emits `state/marathon-runs/...` in git porcelain, which a
#     basename match on `marathon-runs/` would not exclude. Case (3) is the falsifiable one: it
#     passes a NESTED override and asserts the phase output is not called stray.
#
# WHY XYZ_PYTHON=0 IS FORCED: marathon-drive.sh execs the Python twin by default
# (`"${XYZ_PYTHON-1}" == "1"`, GH-264), so an ordinary pair of invocations tests Python twice and
# never reaches the edited Bash lines at all. The shim's own header comment still claims the
# opposite ("Default (unset/0) runs the canonical Bash implementation") — it predates the GH-264
# flip and contradicts the code one line below it. Do not let it talk you out of forcing this.
source "$(dirname "$0")/_setup.sh" gh484-phase-dir-default
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRV="$ROOT/relay-automation/marathon-drive.sh"

mk_repo() {  # <dir>
  mkdir -p "$1"; git init -q "$1"
  git -C "$1" config user.email gh484@t; git -C "$1" config user.name gh484
  printf 'x\n' > "$1/seed.txt"
  git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -q -m init
}

# Stub both agents — a test of path resolution must not depend on which agents are installed
# (GH-117: naming a real binary passed locally and exited 2 on CI).
STUB="$WORK/stub"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB"; chmod +x "$STUB"
BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"

# `--dry-run` reports the resolved phase path without writing it or driving a relay, which is all
# these cases need. The render report names the file it WOULD write, so the assertions read that
# rather than the filesystem — and gh401 separately pins that a dry run writes nothing at all.
drive() {  # <marathon-root> <extra-args…> ; echoes combined output
  local mroot="$1"; shift
  MARATHON_ROOT="$mroot" CLAUDE_BIN="$STUB" AGY_BIN="$STUB" \
    bash "$DRV" --phase-brief "$BRIEF" --reviewer agy --builder claude --dry-run "$@" 2>&1
}

# ── (1) default resolves to marathon-system/, in BOTH twins ──────────────────────────────────────
for mode in python bash; do
  M="$WORK/default-$mode"; mk_repo "$M"
  if [ "$mode" = bash ]; then out="$(XYZ_PYTHON=0 drive "$M")"; else out="$(XYZ_PYTHON=1 drive "$M")"; fi
  printf '%s' "$out" | grep -Fq "$M/marathon-system/p1/RELAY.md" \
    && pass "($mode) no --phases-dir → resolves under marathon-system/" \
    || fail "($mode) default did not resolve to $M/marathon-system/p1/RELAY.md: $out"
  printf '%s' "$out" | grep -Fq "$M/phases/p1/RELAY.md" \
    && fail "($mode) default still resolves to the OLD phases/ path: $out" \
    || pass "($mode) the old phases/ default is gone, not merely shadowed"
done

# ── (2) a NESTED --phases-dir still overrides, in BOTH twins ─────────────────────────────────────
# Nested on purpose: a basename-only comparison would appear to work for a single-segment override
# and fail here, which is exactly the design error this case exists to catch.
for mode in python bash; do
  M="$WORK/override-$mode"; mk_repo "$M"
  if [ "$mode" = bash ]; then out="$(XYZ_PYTHON=0 drive "$M" --phases-dir "$M/state/marathon-runs")"
  else out="$(XYZ_PYTHON=1 drive "$M" --phases-dir "$M/state/marathon-runs")"; fi
  printf '%s' "$out" | grep -Fq "$M/state/marathon-runs/p1/RELAY.md" \
    && pass "($mode) nested --phases-dir overrides the default" \
    || fail "($mode) nested override ignored: $out"
done

# ── (3) the dirty-tree exclusion tracks the CONFIGURED dir, not a literal ────────────────────────
# THE FALSIFIABLE CASE. Seed TWO untracked things: the phase's own output under a nested
# --phases-dir (must be excluded) and an unrelated stray file (must be reported). --dry-run is NOT
# used — the clean check is deliberately skipped on a dry run, which would make this vacuous.
# --pre-advance-cmd true is required: the driver probes the default gate (bash validate.sh) and
# dies before Step 0 in a fixture repo that has none, which ALSO makes this vacuous. The first
# version of this case had exactly that defect and passed against pre-fix code; the stray-file
# assertion below is the positive control that makes the green state mean one thing.
#
# The phase output must be TRACKED-then-modified, not merely untracked. `git status --porcelain`
# collapses an untracked directory to a single `?? state/` line, so an untracked fixture never
# emits a path the prefix comparison can act on and the case passes either way. The driver commits
# its phase artifacts (`git add --`), so tracked-then-modified — ` M state/marathon-runs/p1/RELAY.md`
# — is both the shape a real second/resumed run produces and the one that exercises the fix.
for mode in python bash; do
  M="$WORK/clean-$mode"; mk_repo "$M"
  mkdir -p "$M/state/marathon-runs/p1"
  printf 'STATUS: Open\n' > "$M/state/marathon-runs/p1/RELAY.md"
  git -C "$M" add -A >/dev/null 2>&1; git -C "$M" commit -q -m "track prior phase output"
  printf 'STATUS: Approved\n' > "$M/state/marathon-runs/p1/RELAY.md"
  printf 'unrelated\n' > "$M/stray-note.txt"
  # MARATHON_ROOT stays a literal assignment on the invocation itself rather than an `env` array:
  # test/marathon-root-audit.sh (GH-209) parses these statically and cannot see through an array,
  # so the array form reads to it as an UNSCOPED driver call — the exact thing that audit exists to
  # catch. It flagged this line on the first run; the audit was right.
  if [ "$mode" = bash ]; then PYV=0; else PYV=1; fi
  out="$(MARATHON_ROOT="$M" CLAUDE_BIN="$STUB" AGY_BIN="$STUB" XYZ_PYTHON="$PYV" \
          bash "$DRV" --phase-brief "$BRIEF" --reviewer agy --builder claude \
          --phases-dir "$M/state/marathon-runs" --pre-advance-cmd true --require-clean 2>&1)"; rc=$?

  # POSITIVE CONTROL first: the clean check must actually have RUN and named the stray file.
  # Without this, "the phase dir was not reported" also passes for a driver that exited earlier.
  printf '%s' "$out" | grep -Fq "stray-note.txt" \
    && pass "($mode) the dirty-tree check ran and reported the unrelated stray file (control)" \
    || fail "($mode) the clean check never ran or never reported stray-note.txt, so the exclusion assertion below would be vacuous (rc=$rc): $out"

  printf '%s' "$out" | grep -Fq "state/marathon-runs" \
    && fail "($mode) the configured phase dir was reported as a stray file — the exclusion is still a literal (rc=$rc): $out" \
    || pass "($mode) a nested --phases-dir is excluded from the dirty-tree check"
done

exit 0
