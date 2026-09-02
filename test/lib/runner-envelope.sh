#!/usr/bin/env bash
# runner-envelope.sh — the ONE scratch/identity envelope shared by validate.sh and ci-local.sh.
#
# WHY THIS EXISTS (GH-365 step 1): the two runners each half-owned a containment story.
# validate.sh pointed the harness registry at a throwaway copy (GH-205) but ci-local.sh — the
# run that writes the qualifying evidence record — ran the SAME registered suites against the
# TRACKED harnesses.db, so a green qualifying run dirtied the tree and gate-record.sh then
# refused to retain its own evidence. And the identity bracket captured git identity but not
# tracked-tree/worktree/lock state, so a run could end drifted in ways no receipt named.
#
# ONE implementation, sourced by both runners — never a second copy (GH-365 step 1: "factor the
# existing validate.sh harness-registry scratch setup into one runner helper"). A runner that
# cannot find this file fails closed rather than improvising a private envelope.
#
# Contract (all functions take <here> = the runner's repo root, <label> = runner name for messages):
#   runner_envelope_begin <here> <label>
#     1. Harness-registry scratch: a pre-set XYZ_HARNESS_DB (an operator's or a hermetic suite's
#        own) is respected and wins; otherwise the tracked harnesses.db/.sql are copied to a
#        throwaway dir and XYZ_HARNESS_DB is exported at it, so harness_app.py's artifacts (db,
#        dump, registry md, blog docs) land in scratch, never in the tree (GH-205).
#     2. Pre-run state snapshot into $RUNNER_ENVELOPE_STATE:
#          identity   — test/lib/clone-identity.sh capture (HEAD/bare/remote/user/branch)
#          tree       — git status --porcelain (pre-existing dirt is recorded, not forbidden)
#          worktrees  — git worktree list --porcelain
#          locks      — relay-driver.lock presence + holder line (GH-42/GH-448 resolution shape)
#   runner_envelope_assert <here> <label>  ->  0 clean · 1 identity drift · 2 envelope drift
#        Identity drift is the GH-1 hard failure (every result from the clone is invalid,
#        GH-567). Envelope drift (tree/worktrees/locks changed UNDER the run) leaves the suite
#        verdict standing but marks the run's evidence record invalid — and names exactly what
#        drifted, which is the diagnostic the XYZ_HARNESS_DB bypass audit runs on.
#   runner_envelope_scrub   — EXIT-trap cleanup for both mktemp dirs. GH-177 discipline: each
#        path was born from mktemp under ${TMPDIR:-/tmp} with this file's prefixes and is
#        re-verified non-empty, a directory, and lexically inside that root before rm -rf.
#
# Read-only by construction outside its own scratch/state dirs: every probe is a query.

set -u

_re_lib_dir() { echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; }

_re_tree() {  # <repo> — tracked-tree state, sorted for stable diffs
  git -C "$1" status --porcelain 2>/dev/null | LC_ALL=C sort
}

_re_worktrees() {  # <repo> — registered worktrees
  git -C "$1" worktree list --porcelain 2>/dev/null
}

_re_locks() {  # <repo> — driver-lock state (the GH-42 per-clone lock; GH-448 resolution shape)
  local gd
  gd="$(git -C "$1" rev-parse --absolute-git-dir 2>/dev/null)" || { echo "gitdir: unresolvable"; return 0; }
  if [ -f "$gd/relay-driver.lock" ]; then
    printf 'relay-driver.lock: present (%s)\n' "$(head -c 200 "$gd/relay-driver.lock" 2>/dev/null | tr '\n' ' ')"
  else
    printf 'relay-driver.lock: absent\n'
  fi
}

runner_envelope_begin() {
  local here="$1" label="$2"
  RUNNER_ENVELOPE_SCRATCH=""
  RUNNER_ENVELOPE_STATE=""
  if [ -z "${XYZ_HARNESS_DB:-}" ]; then
    RUNNER_ENVELOPE_SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/runner-envelope.XXXXXX")"
    if [ -z "$RUNNER_ENVELOPE_SCRATCH" ] || [ ! -d "$RUNNER_ENVELOPE_SCRATCH" ]; then
      echo "runner-envelope: mktemp -d for harness scratch failed — refusing to run ungated" >&2
      return 1
    fi
    cp "$here/harnesses.db"  "$RUNNER_ENVELOPE_SCRATCH/harnesses.db"  2>/dev/null || true
    cp "$here/harnesses.sql" "$RUNNER_ENVELOPE_SCRATCH/harnesses.sql" 2>/dev/null || true
    export XYZ_HARNESS_DB="$RUNNER_ENVELOPE_SCRATCH/harnesses.db"
  fi
  RUNNER_ENVELOPE_STATE="$(mktemp -d "${TMPDIR:-/tmp}/runner-state.XXXXXX")"
  if [ -z "$RUNNER_ENVELOPE_STATE" ] || [ ! -d "$RUNNER_ENVELOPE_STATE" ]; then
    echo "runner-envelope: mktemp -d for state snapshot failed — refusing to run unbracketed" >&2
    return 1
  fi
  if ! bash "$(_re_lib_dir)/clone-identity.sh" capture "$RUNNER_ENVELOPE_STATE/identity" "$here"; then
    echo "runner-envelope: could not capture clone identity — refusing to run the suite blind (GH-1)" >&2
    return 1
  fi
  _re_tree "$here"      > "$RUNNER_ENVELOPE_STATE/tree"
  _re_worktrees "$here" > "$RUNNER_ENVELOPE_STATE/worktrees"
  _re_locks "$here"     > "$RUNNER_ENVELOPE_STATE/locks"
  echo "runner-envelope: $label — harness registry at scratch ($XYZ_HARNESS_DB), envelope state captured"
}

runner_envelope_assert() {
  local here="$1" label="$2" facet drifted=0
  RUNNER_ENVELOPE_DRIFT_FACETS=""
  [ -n "${RUNNER_ENVELOPE_STATE:-}" ] && [ -d "$RUNNER_ENVELOPE_STATE" ] || {
    echo "runner-envelope: no state snapshot captured (internal error) — cannot attest $label" >&2
    return 1
  }
  # Identity first, on the existing GH-1 machinery: its own diff names the drift (GH-567).
  if ! bash "$(_re_lib_dir)/clone-identity.sh" assert "$RUNNER_ENVELOPE_STATE/identity" "$here"; then
    RUNNER_ENVELOPE_DRIFT_FACETS="identity"
    return 1
  fi
  for facet in tree worktrees locks; do
    "_re_$facet" "$here" > "$RUNNER_ENVELOPE_STATE/$facet.post"
    if ! diff -u "$RUNNER_ENVELOPE_STATE/$facet" "$RUNNER_ENVELOPE_STATE/$facet.post" \
         > "$RUNNER_ENVELOPE_STATE/$facet.diff" 2>&1; then
      drifted=1
      RUNNER_ENVELOPE_DRIFT_FACETS="${RUNNER_ENVELOPE_DRIFT_FACETS:+$RUNNER_ENVELOPE_DRIFT_FACETS }$facet"
      echo "runner-envelope: $facet DRIFT under $label — the run changed it; this run's evidence record is INVALID (GH-365):" >&2
      sed -n '1,20p' "$RUNNER_ENVELOPE_STATE/$facet.diff" >&2
    fi
  done
  [ "$drifted" -eq 0 ] && echo "runner-envelope: clean — identity, tracked tree, worktrees, and driver lock unchanged under $label"
  [ "$drifted" -eq 0 ] && return 0 || return 2
}

runner_envelope_scrub() {
  local d
  for d in "${RUNNER_ENVELOPE_SCRATCH:-}" "${RUNNER_ENVELOPE_STATE:-}"; do
    [ -n "$d" ] && [ -d "$d" ] || continue
    case "$d" in
      "${TMPDIR:-/tmp}"/runner-envelope.*|"${TMPDIR:-/tmp}"/runner-state.*) rm -rf "$d" ;;
      *) echo "runner-envelope: scrub refusing unproven path '$d' (GH-177)" >&2 ;;
    esac
  done
}
