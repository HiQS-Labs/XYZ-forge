#!/usr/bin/env bash
# ci-local.sh — run the tier1 CI job on this machine, step for step.
#
# WHY THIS EXISTS: GitHub Actions is metered. Every push burned budget to learn things a laptop can
# tell you for free, and when the budget ran out `gh pr checks` started reporting `fail` in 2 seconds
# on every commit — not a test failure, but "the job was not started because recent account payments
# have failed". A red check that means nothing is worse than no check, because a real break looks
# identical. This runs the same steps locally so the signal keeps existing.
#
# It follows .github/workflows/ci.yml's job in ORDER and CONTENT, but NOT in coverage — see the
# section below. test/ci-workflow.sh pins the parts that must not drift.
#
# ─────────────────────────────────────────────────────────────────────────────────────────────────
# THIS RUNS ON THE PLATFORM WE SHIP TO. THE HOSTED UBUNTU JOB DOES NOT. (GH-509)
# ─────────────────────────────────────────────────────────────────────────────────────────────────
# XYZ is a local developer toolkit for macOS developers. Linux and Windows support are on the roadmap
# and are not here yet. So the direction of the old caveat here — "a green local run does not mean a
# green ubuntu run" — was true but pointed at the less useful risk. Reversed and stated properly:
#
#   * A green run HERE is the best evidence we have about what users experience, because your machine
#     is the shipping platform with the real toolchain.
#   * A green run on hosted UBUNTU says little. That job is an advisory portability canary; its red
#     means "would not work on a platform we do not support yet", not "broken".
#
# This script therefore runs MORE than the hosted job, on purpose. It does not skip
# `registry-lock-concurrency.sh` — the workflow's own comment says that suite "passes locally" and
# flakes only under contended Linux CI, so skipping it here discarded real macOS signal to imitate a
# machine no user has.
#
# THE HONEST LIMIT IS NOW ELSEWHERE, and it is not about platform. This run is SELF-REPORTED: it
# proves someone ran the suite, not that they ran it on the code they are shipping. That is what the
# hosted macOS boundary job buys — a clean machine, and evidence not produced by the claimant.
# ─────────────────────────────────────────────────────────────────────────────────────────────────
#
# Usage:
#   ./ci-local.sh              # every step (~15-20 min; the suite dominates)
#   ./ci-local.sh --fast       # everything EXCEPT the full validate.sh suite (~1 min)
#   ./ci-local.sh --base REF   # also run the frozen-twin guard against REF (CI does this on PRs only)
#   ./ci-local.sh --probe      # GH-509: the UNCONFIGURED-MAC probe (see below)
#
# ── --probe: what a new adopter's machine actually looks like (GH-509 / GH-520) ──────────────────
# Runs with `codex`, `agy` and `aider` stripped from PATH, simulating a Mac where XYZ has just been
# installed and none of the agent CLIs are set up yet. That is a real audience, not a hypothetical:
# GH-380 describes someone installing Claude Code specifically to run the swarm, with nothing else on
# the box.
#
# It is also the only cheap way to catch a whole defect class. On 2026-08-12 three suites passed here
# and failed in CI purely because those binaries exist on this machine and not on a runner (#520).
# This probe reproduced all three in ~90 seconds. It is NOT a Linux check — it is a
# "does-this-work-before-the-operator-has-installed-everything" check, and it belongs on the same
# platform we ship to.
#
# ── The per-commit record, and what it is NOT (GH-509) ───────────────────────────────────────────
# A successful full run writes `.gate-evidence/<sha>.txt`. That answers exactly one question — "has
# anyone run the whole suite against THIS commit?" — so an agent or operator can tell a verified HEAD
# from an unverified one without re-running 15 minutes of tests on a hunch.
#
# It is deliberately NOT promotion evidence. An earlier draft of the GH-509 plan let a local record
# qualify a commit for promotion; the agy review called that circular and was right — if a
# self-reported record satisfies the boundary, the boundary is optional and buys nothing. Promotion
# needs the hosted macOS run. This record is for the day-to-day question, not the release question.
#
# Refused from a dirty tree, and that refusal is the whole integrity story: a record keyed to a
# commit hash while uncommitted edits sit in the tree would name a state that was never tested.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE" || exit 1

# ── GH-45: REFUSE to run from a linked git worktree ─────────────────────────────────────────────
# Same guard, same reason, same override as validate.sh's (kept inline in both rather than a new
# shared .sh — GH-551; both copies are pinned by test/gh35-test-tiers.sh): this script runs the
# SAME suite validate.sh does, so running it from a worktree exposes the parent clone's shared
# .git to exactly the fixture-escape damage validate.sh refuses (2026-08-19 incident, GH-564).
if [ "${XYZ_ALLOW_WORKTREE_GATE:-0}" != "1" ]; then
  _wt_abs_git="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
  _wt_common="$(git rev-parse --git-common-dir 2>/dev/null || true)"
  _wt_common_abs=""
  [ -n "$_wt_common" ] && _wt_common_abs="$(cd "$_wt_common" 2>/dev/null && pwd -P || true)"
  if [ -n "$_wt_abs_git" ] && [ -n "$_wt_common_abs" ] && [ "$_wt_abs_git" != "$_wt_common_abs" ]; then
    cat >&2 <<'WTREFUSE'
ci-local: REFUSING — this is a linked git worktree, which shares the parent clone's
  .git (config, refs, objects). The suite this script runs can reach the PARENT clone,
  not a fixture: an observed run set core.bare=true, repointed origin at a deleted temp
  path, deleted every refs/remotes/origin/*, and overwrote development with fixture
  commits. Run the qualifying gate from a normal clone. Override with
  XYZ_ALLOW_WORKTREE_GATE=1 only if you accept that blast radius.
WTREFUSE
    exit 2
  fi
else
  echo "ci-local: XYZ_ALLOW_WORKTREE_GATE=1 — running from a linked worktree at the operator's explicit request; the parent clone's .git is exposed (GH-45)." >&2
fi
unset _wt_abs_git _wt_common _wt_common_abs

FAST=0
BASE=""
PROBE=0
while (($#)); do
  case "$1" in
    --fast) FAST=1; shift ;;
    --probe) PROBE=1; shift ;;
    --base) BASE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
    *) echo "ci-local: unknown argument: $1" >&2; exit 2 ;;
  esac
done

# GH-509/GH-520 — strip the agent CLIs from PATH for the probe. Done by rebuilding PATH without the
# directories that hold them, rather than by unsetting *_BIN vars: the failure being reproduced is a
# binary that is not on PATH at all, and a shim that falls back to a PATH lookup would defeat a
# variable-only approach.
if [ "$PROBE" -eq 1 ]; then
  probe_dirs=""
  for c in codex agy aider; do
    p="$(command -v "$c" 2>/dev/null || true)"
    [ -n "$p" ] && probe_dirs="$probe_dirs $(dirname "$p")"
  done
  if [ -n "$probe_dirs" ]; then
    new_path=""
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      skip=0
      for pd in $probe_dirs; do [ "$d" = "$pd" ] && { skip=1; break; }; done
      [ "$skip" -eq 1 ] && continue
      new_path="${new_path:+$new_path:}$d"
    done < <(printf '%s\n' "${PATH//:/$'\n'}")
    PATH="$new_path"; export PATH
  fi
  # Assert the condition rather than assume it. A probe that silently ran with the binaries still
  # present would report green and mean nothing — the exact shape of failure this repo keeps paying
  # for, and the reason GH-520's control aborts on the same check.
  still=""
  for c in codex agy aider; do command -v "$c" >/dev/null 2>&1 && still="$still $c"; done
  if [ -n "$still" ]; then
    echo "ci-local --probe: ABORT — still on PATH:$still (the probe would be meaningless)" >&2
    exit 2
  fi
  printf '\033[33mmode: --probe (codex/agy/aider stripped from PATH — simulating a fresh Mac)\033[0m\n'
fi

PASSED=(); FAILED=()

# GH-536: where the suite transcript and per-suite verdicts land, so gate-record.sh can hash the
# first and embed the second. Per-PID so two concurrent runs on one machine cannot cross-write.
GATE_SUITE_LOG="${TMPDIR:-/tmp}/ci-local-suite-$$.log"
GATE_VERDICTS="${TMPDIR:-/tmp}/ci-local-verdicts-$$.txt"
trap 'rm -f "$GATE_SUITE_LOG" "$GATE_VERDICTS"' EXIT
# GH-365 step 2: retained JSONL telemetry, same lib and schema validate.sh uses. rt_begin is
# deferred to the run section (mode is known there); stage timing is wired once, here, so every
# step() below is timed uniformly without per-step ceremony.
. "$HERE/test/lib/runner-telemetry.sh"
step() {  # <name> — everything after is the step body, run in a subshell
  local name="$1" _s; shift
  _s="$(rt_now_ms)"
  printf '\n\033[1m=== %s\033[0m\n' "$name"
  if "$@"; then PASSED+=("$name"); rt_emit stage stage "$name" "$_s" "$(rt_now_ms)" 0
  else FAILED+=("$name"); rt_emit stage stage "$name" "$_s" "$(rt_now_ms)" 1; printf '\033[31mFAILED: %s\033[0m\n' "$name" >&2; fi
}

# ── 1. prerequisites ─────────────────────────────────────────────────────────────────────────────
# CI apt-installs shellcheck; locally it is the operator's to provide. Checked up front so the run
# does not get 15 minutes in before discovering a missing binary.
check_prereqs() {
  local missing=0 c
  for c in shellcheck bash node python3 npm git; do
    if command -v "$c" >/dev/null 2>&1; then
      printf '  ok       %s\n' "$c"
    else
      printf '  MISSING  %s\n' "$c" >&2; missing=1
    fi
  done
  [ "$missing" -eq 0 ] || {
    echo "  shellcheck: brew install shellcheck   (CI apt-installs it; this is the only extra dep)" >&2
    return 1
  }
  return 0
}

# ── 2-5. the cheap static checks, verbatim from the workflow ─────────────────────────────────────
# GH-365 step 5 census: THIS is the one local scan site for the shellcheck BINARY (the hosted
# job in ci.yml is the other); no registered suite executes it — everything else in test/ is
# directives. Parallel at the balanced four-worker width (the same policy validate.sh's pool
# uses): one process per file, so per-file diagnostics are IDENTICAL to the serial shape — only
# their interleaving in the aggregate stream can differ. (A comment here must never START with
# the word "shellcheck" — the scanner parses that prefix as a directive and the scan itself goes
# red on SC1072/SC1073; observed on the first qualifying run at 76174765.) XYZ_SHELLCHECK_JOBS=1
# restores the exact serial shape (xargs -P 1); xargs aggregates per-file failures nonzero.
shellcheck_tracked() {
  # severity=error, matching the workflow's deliberate choice to land green before tightening.
  git ls-files -z -- '*.sh' | xargs -0 -P "${XYZ_SHELLCHECK_JOBS:-4}" -n 1 shellcheck -S error
}

bash_syntax_tracked() {
  local rc=0 file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    bash -n "$file" || rc=1
  done < <(git ls-files -- '*.sh')
  return $rc
}

node_syntax_tracked() {
  local rc=0 file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    node --check "$file" || rc=1
  done < <(git ls-files -- 'src/*.js' 'bin/*.js')
  return $rc
}

settings_json_valid() {
  local rc=0 file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    python3 -m json.tool "$file" >/dev/null || rc=1
  done < <(git ls-files -- '.claude/settings*.json')
  return $rc
}

# ── 6. PDDA ──────────────────────────────────────────────────────────────────────────────────────
pdda_gate() {
  utils/pdda/pdda.sh run || return 1
  # Warn-only by contract — it reports, it never gates. Kept outside the sync-managed utils/pdda/
  # tree because a 2026-08-03 upstream sync silently deleted three of these checks.
  utils/pdda-local-checks.sh run || true
  return 0
}

# ── 7. frozen twin guard — PR-only in CI, so opt-in here ─────────────────────────────────────────
frozen_twin_guard() {
  bash test/gh308-frozen-twin-guard.sh --check --base "$BASE" --allow-exceptions
}

# ── 8. npm + acorn-extract ───────────────────────────────────────────────────────────────────────
# A fresh clone has no node_modules, so acorn-extract dies with MODULE_NOT_FOUND. CI proves the
# README Quickstart path from scratch (GH-230); the same install is what makes a fresh checkout
# gate-ready at all — a marathon has already halted on exactly this.
npm_and_acorn() {
  npm ci || return 1
  bash test/acorn-extract.sh
}

# ── 9. the suite ─────────────────────────────────────────────────────────────────────────────────
# TESTS is parsed out of validate.sh exactly the way the workflow parses it, so the two cannot drift
# on WHICH tests run — only on the environment they run in.
#
# NOTE: `git config --global` is what CI does before this step, to supply the user identity and
# init.defaultBranch that fixture-driven tests assume. That is deliberately NOT done here: a dev
# machine already has both, and silently rewriting an operator's global git config is not something
# a test runner should do. If a fixture test fails on a bare machine, set them yourself.
validate_suite() {
  # GH-509: THIS SKIP LIST IS DELIBERATELY SHORTER THAN THE WORKFLOW'S, and that is the point.
  #
  # It used to mirror CI's, including `registry-lock-concurrency.sh`. That suite's own skip comment
  # in the workflow reads "flaky under CI load … PASSES LOCALLY" — it fails on a contended shared
  # Linux runner, a machine no XYZ user will ever have. Skipping it here threw away real signal about
  # the platform we actually ship to, in order to stay faithful to a platform we do not.
  #
  # Only ONE skip survives, and it is not a platform concession: acorn-extract.sh already ran in the
  # npm step above, so running it again would be duplicated work rather than dropped coverage.
  local skip_tests=(
    "acorn-extract.sh"                # already run above (needs npm ci first) — duplicate, not dropped
  )
  local all_tests=() line t s skip rc=0
  while IFS= read -r line; do
    [ -n "$line" ] && all_tests+=("$line")
  done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')

  [ "${#all_tests[@]}" -gt 0 ] || { echo "  could not parse TESTS from validate.sh" >&2; return 1; }
  echo "  ${#all_tests[@]} suites declared in validate.sh"

  # GH-536: capture the transcript and a per-suite verdict list so the evidence record can carry an
  # output hash and individual verdicts instead of a bare `result: green`.
  #
  # `tee -a` keeps the operator's live output intact — a 15-minute run that goes silent to build a
  # log would be a bad trade. `${PIPESTATUS[0]}` is load-bearing: with a pipe, `$?` is tee's status,
  # so a failing suite would look green. `set -o pipefail` is already on, but reading PIPESTATUS
  # directly says which element is being tested rather than relying on a shell option set 150 lines
  # away.
  : > "$GATE_SUITE_LOG"
  : > "$GATE_VERDICTS"
  _one="${TMPDIR:-/tmp}/ci-local-onesuite-$$.log"   # GH-365: per-suite capture for telemetry bytes/hash
  for t in "${all_tests[@]}"; do
    skip=0
    for s in "${skip_tests[@]}"; do [ "$t" = "$s" ] && { skip=1; break; }; done
    [ "$skip" -eq 1 ] && { echo "SKIP (already run above): $t"; printf '%s\tskip\n' "$t" >> "$GATE_VERDICTS"; rt_emit suite stage "$t" "$(rt_now_ms)" "$(rt_now_ms)" 0 "verdict=skip-duplicate"; continue; }
    echo "=== $t ===" | tee -a "$GATE_SUITE_LOG"
    _s="$(rt_now_ms)"
    # Two tees: the first APPENDS the shared transcript, the second writes the per-suite capture
    # (truncated fresh). BSD tee does NOT permute options — the earlier single
    # `tee "$_one" -a "$GATE_SUITE_LOG"` treated -a as a FILENAME (empirically confirmed:
    # `printf hi | tee ./one -a ./two` leaves a file named '-a' in CWD), creating that stray file
    # in the repo root on every suite. The GH-365 envelope's tree bracket caught it and refused
    # to attest two qualifying runs before the shape was pinned.
    bash "test/$t" 2>&1 | tee -a "$GATE_SUITE_LOG" | tee "$_one"
    _rc="${PIPESTATUS[0]}"
    if [ "$_rc" -eq 0 ]; then
      printf '%s\tpass\n' "$t" >> "$GATE_VERDICTS"
    else
      rc=1
      printf '%s\tFAIL\n' "$t" >> "$GATE_VERDICTS"
      echo "  ^^ FAILED: $t" >&2
    fi
    rt_suite sequential "$t" "$_s" "$(rt_now_ms)" "$_rc" "$_one"
  done
  rm -f "$_one"

  # GH-377 review blocker 1: the qualifying run must execute the AUTHORITATIVE tier-3 set, not a
  # .sh-only subset. validate.sh owns three non-TESTS lanes; this runner supplies its own envelope
  # bracket (the identity half of lane two), but Python and gamma-poison were historically omitted
  # while the output said "full suite" and the record claimed qualifying evidence. They are part of
  # the loop now, recorded in the verdicts under validate.sh's own PASSED labels so the record and
  # the summary agree on the denominator.
  _s="$(rt_now_ms)"
  if python3 -m pytest "$HERE/test/test_python_layer.py"; then
    printf '%s\tpass\n' "python:test_python_layer.py" >> "$GATE_VERDICTS"
  else
    rc=1
    printf '%s\tFAIL\n' "python:test_python_layer.py" >> "$GATE_VERDICTS"
    echo "  ^^ FAILED: python:test_python_layer.py" >&2
  fi
  rt_emit suite sequential "python:test_python_layer.py" "$_s" "$(rt_now_ms)" "$?"

  _s="$(rt_now_ms)"
  if git apply --check "$HERE/test/fixtures/gamma-poison/poison.patch" 2>/dev/null; then
    printf '%s\tpass\n' "gamma-poison-staleness-probe" >> "$GATE_VERDICTS"
  else
    rc=1
    printf '%s\tFAIL\n' "gamma-poison-staleness-probe" >> "$GATE_VERDICTS"
    echo "  ^^ FAILED: gamma-poison-staleness-probe" >&2
  fi
  rt_emit suite sequential "gamma-poison-staleness-probe" "$_s" "$(rt_now_ms)" "$?"
  return $rc
}

# ── 10. GH-10/GH-365: the shared envelope bracket — assert half ─────────────────────────────────
# The qualifying run writes the gate-evidence record, so it carries the same clone-identity
# bracket validate.sh has, from the SAME shared helper (GH-365 step 1): identity drift fails the
# run (the GH-564 incident), and envelope drift (tracked tree / worktrees / driver lock changed
# under the run) is named and also fails — a qualifying run that cannot retain attributable
# evidence must not exit green (the failure mode #365 exists to prevent).
ci_local_envelope_assert() {
  runner_envelope_assert "$HERE" "ci-local.sh"
  local rc=$?
  RT_ENVELOPE_RC="$rc"; RT_ENVELOPE_DRIFT="${RUNNER_ENVELOPE_DRIFT_FACETS:-none}"
  return "$rc"
}

# ── run ──────────────────────────────────────────────────────────────────────────────────────────
printf '\033[1mci-local — mirroring .github/workflows/ci.yml tier1\033[0m\n'
printf 'repo: %s\n' "$HERE"
printf 'HEAD: %s\n' "$(git log --oneline -1 2>/dev/null)"
[ "$FAST" -eq 1 ] && printf '\033[33mmode: --fast (full validate.sh suite SKIPPED)\033[0m\n'
# GH-365 step 2: open the retained telemetry record for THIS run (same schema as validate.sh).
# The registered denominator is parsed here, once, exactly the way validate_suite parses TESTS —
# so run.start carries the explicit denominator instead of inheriting a stale section count.
_declared="$(sed -n '/^TESTS=(/,/^)/p' "$HERE/validate.sh" | grep -oE '"[^"]+\.sh"' | wc -l | tr -d ' ')"
if [ "$FAST" -eq 1 ]; then
  rt_begin "$HERE" "ci-local" "fast" 1 3 "$_declared"
else
  rt_begin "$HERE" "ci-local" "sequential" 1 3 "$_declared"
fi

step "prerequisites"                check_prereqs
step "shellcheck tracked scripts"   shellcheck_tracked
step "bash syntax"                  bash_syntax_tracked
step "node syntax"                  node_syntax_tracked
step "settings JSON"                settings_json_valid
step "PDDA deterministic gate"      pdda_gate
if [ -n "$BASE" ]; then
  step "frozen twin guard"          frozen_twin_guard
else
  printf '\n\033[33mSKIP: frozen twin guard — CI runs it on pull_request only. Pass --base <ref> to run it.\033[0m\n'
fi
step "npm ci + acorn-extract"       npm_and_acorn
# GH-10/GH-1 + GH-365 step 1: the qualifying run gets the SAME envelope validate.sh uses, from
# the ONE shared helper — harness-registry scratch (XYZ_HARNESS_DB) AND the identity bracket AND
# the tree/worktree/lock bracket. Before GH-365, this run executed the registered suites with no
# scratch envelope at all: harness_app.py writes landed in the TRACKED harnesses.db, the tree
# went dirty, and gate-record.sh then refused to retain the record for exactly the run that
# needed it. Fail closed if the helper is missing — never a second inline envelope.
if [ "$FAST" -eq 0 ]; then
  if [ ! -f "$HERE/test/lib/runner-envelope.sh" ]; then
    echo "ci-local: test/lib/runner-envelope.sh is missing — the shared GH-365 runner envelope cannot be set up; refusing." >&2
    exit 1
  fi
  . "$HERE/test/lib/runner-envelope.sh"
  runner_envelope_begin "$HERE" "ci-local.sh" || exit 1
  RELAY_SELF_SUFFICIENCY_SKIP=1 step "validate.sh suite" validate_suite
  step "clone-identity invariant (GH-1)" ci_local_envelope_assert
  runner_envelope_scrub
fi

# ── report ───────────────────────────────────────────────────────────────────────────────────────
printf '\n\033[1m─── ci-local summary ───\033[0m\n'
for s in "${PASSED[@]}"; do printf '  \033[32m+\033[0m %s\n' "$s"; done
if [ "${#FAILED[@]}" -gt 0 ]; then
  for s in "${FAILED[@]}"; do printf '  \033[31m-\033[0m %s\n' "$s"; done
  printf '\n\033[31mci-local: %d step(s) failed\033[0m\n' "${#FAILED[@]}"
  printf 'This ran on macOS — the platform XYZ ships to — so a failure here is a real defect for\n'
  printf 'real users. Do not wait for hosted CI to confirm it; the ubuntu job is advisory (GH-509).\n'
  rt_summary "${#PASSED[@]}" "${#FAILED[@]}" "$(( ${#PASSED[@]} + ${#FAILED[@]} ))" "declared=$_declared" "recorded=no"
  exit 1
fi
printf '\n\033[32mci-local: all steps passed\033[0m\n'
printf 'Green on the shipping platform, with the full suite — including the one hosted ubuntu skips.\n'
printf 'NOT a promotion qualification: this run is self-reported. Promotion needs a hosted macOS run\n'
printf 'for this exact commit (GH-509 §6) — a clean machine, and evidence you did not produce.\n'

# ── GH-509: record that THIS COMMIT was verified here ────────────────────────────────────────────
# Only a full run earns a record. A --fast or --probe run deliberately does not exercise the suite,
# so recording one would make a partial run indistinguishable from a complete one — which is the
# whole failure mode this file keeps warning about in other contexts.
#
# GH-365 step 1: a REFUSED record now fails the qualifying run instead of passing silently
# (`|| true` used to swallow it). The record is the product of this run: a green exit with no
# retained evidence is precisely the "cannot retain its evidence" failure #365 exists to prevent.
# gate-record's own refusal names what made the tree dirty (exit 3) or why no commit was found
# (exit 4); the envelope assert above has already named any drift that explains it.
if [ "$FAST" -eq 0 ] && [ "$PROBE" -eq 0 ]; then
  printf '\n'
  # Delegated rather than inlined, so the REFUSAL has a test that does not cost a 15-minute suite run.
  _gr_rc=0
  bash utils/gate-record.sh --suite-log "$GATE_SUITE_LOG" --verdicts "$GATE_VERDICTS" || _gr_rc=$?
  rt_emit stage stage "gate-record" "$(rt_now_ms)" "$(rt_now_ms)" "$_gr_rc"
  if [ "$_gr_rc" -ne 0 ]; then
    printf '\033[31mci-local: gate-record refused (exit %d) — this qualifying run leaves NO evidence record, so it cannot exit green (GH-365).\033[0m\n' "$_gr_rc" >&2
    rt_summary "${#PASSED[@]}" "${#FAILED[@]}" "$(( ${#PASSED[@]} + ${#FAILED[@]} ))" "declared=$_declared" "recorded=refused-$_gr_rc"
    exit 1
  fi
fi
[ -n "${RT_FILE:-}" ] && echo "telemetry: $RT_FILE"
rt_summary "${#PASSED[@]}" "${#FAILED[@]}" "$(( ${#PASSED[@]} + ${#FAILED[@]} ))" "declared=$_declared" "recorded=yes"
exit 0
