#!/usr/bin/env bash
# test/lib/vendored-fixture.sh — GH-396 Phase 0: ONE builder for a vendored-`.xyz/` fixture.
#
# Before this file, 21 of 329 registered suites each open-coded their own `.xyz/` construction and no
# two agreed on what a "vendored install" looks like (recon map §Build). This is the shared seam.
#
# Source it AFTER fixture_guard_init has pinned $WORK (GH-10), then call:
#
#   make_vendored_fixture <dir> [--stub|--real] [--stale <sha>] [--tier 1|2]
#                               [--symlink-inside|--symlink-outside] [--worktree <path>]
#
# Prints nothing; sets these for the caller:
#   $VF_REPO      — the consumer repo root (a real git repo with one commit)
#   $VF_HARNESS   — the path a locator should resolve to as HARNESS (usually $VF_REPO/.xyz)
#   $VF_LINK      — the symlink path when --symlink-* was given, else ""
#   $VF_WORKTREE  — the linked worktree root when --worktree was given, else ""
#
# --stub (default) plants the two marker files find-harness.sh probes (`relay-automation/relay-drive.sh`
#   executable + `bin/tick`) and a `VERSION` file. Milliseconds. Right for locator tests.
# --real runs the shipped `relay-automation/xyz-vendor.sh --no-register` — the six VENDOR_DIRS, ~MBs,
#   seconds. Right for integration tests that execute vendored tools.
#
# SAFETY — the reason this file exists rather than a one-liner: xyz-vendor.sh:411-412 is
#   `rm -rf "$VENDOR_DIR" && mv "$STAGE_DIR" "$VENDOR_DIR"`. Pointed at the harness's own checkout it
#   destroys the real .xyz/. So <dir> MUST resolve under $WORK (fixture-guard's pinned sandbox root),
#   and MUST NOT resolve inside the harness checkout this file ships in. Both are enforced below, and
#   the refusal is loud (exit 1 with the two paths named) — a bypass that says nothing is
#   indistinguishable from no guard (validate.sh:41-52).
#
# bash 3.2-safe: no readlink -f, no associative arrays, no ${var,,}.

_vf_here="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_vf_harness_root="$(cd -P "$_vf_here/../.." && pwd)"

_vf_die() { printf 'vendored-fixture: %s\n' "$*" >&2; return 1; }

# Refuse unless <dir> is under $WORK and NOT under the harness checkout. Both checks are on
# PHYSICAL paths so a symlink cannot smuggle the harness root past the guard.
_vf_assert_safe_target() {
  _t="$1"
  [ -n "${WORK:-}" ] || { _vf_die "\$WORK is unset — call fixture_guard_init first (GH-10)"; return 1; }
  _work_p="$(cd -P "$WORK" 2>/dev/null && pwd)" || { _vf_die "\$WORK does not exist: $WORK"; return 1; }
  mkdir -p "$_t" || return 1
  _t_p="$(cd -P "$_t" && pwd)"
  case "$_t_p/" in
    "$_work_p"/*) ;;
    *) _vf_die "REFUSING: target $_t_p is not under the fixture sandbox $_work_p"; return 1 ;;
  esac
  case "$_t_p/" in
    "$_vf_harness_root"/*) _vf_die "REFUSING: target $_t_p is inside the harness checkout $_vf_harness_root — xyz-vendor.sh's rm -rf would hit the real tree"; return 1 ;;
  esac
  return 0
}

_vf_init_repo() {
  git -C "$1" init -q -b main
  git -C "$1" config user.email vf@test
  git -C "$1" config user.name vf
  printf '.xyz/\n' > "$1/.gitignore"
  git -C "$1" add .gitignore
  git -C "$1" commit -qm "vendored-fixture: seed"
}

_vf_stub_harness() {
  # The exact two markers find-harness.sh's _has_vendored_harness probes, plus VERSION.
  mkdir -p "$1/relay-automation" "$1/bin"
  printf '#!/usr/bin/env bash\n:\n' > "$1/relay-automation/relay-drive.sh"
  printf '#!/usr/bin/env bash\n:\n' > "$1/bin/tick"
  chmod +x "$1/relay-automation/relay-drive.sh" "$1/bin/tick"
}

_vf_write_version() {
  # Mirrors xyz-vendor.sh:382-386 — four keys, this order.
  printf 'source_commit=%s\ntick_version=0.2.0\nvendored_utc=%s\ntier=%s\n' \
    "$1" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$2" > "$3/VERSION"
}

make_vendored_fixture() {
  VF_REPO="" VF_HARNESS="" VF_LINK="" VF_WORKTREE=""
  _dir="" _mode="stub" _stale="" _tier="1" _link="" _wt=""
  _dir="${1:-}"; shift || true
  [ -n "$_dir" ] || { _vf_die "usage: make_vendored_fixture <dir> [--stub|--real] [--stale <sha>] [--tier 1|2] [--symlink-inside|--symlink-outside] [--worktree <path>]"; return 1; }
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --stub) _mode=stub; shift ;;
      --real) _mode=real; shift ;;
      --stale) _stale="${2:-}"; shift 2 ;;
      --tier) _tier="${2:-1}"; shift 2 ;;
      --symlink-inside) _link=inside; shift ;;
      --symlink-outside) _link=outside; shift ;;
      --worktree) _wt="${2:-}"; shift 2 ;;
      *) _vf_die "unknown option: $1"; return 1 ;;
    esac
  done

  _vf_assert_safe_target "$_dir" || return 1
  VF_REPO="$(cd -P "$_dir" && pwd)"
  _vf_init_repo "$VF_REPO"

  # Where the harness bytes actually live, and where .xyz points.
  case "$_link" in
    "")       _target="$VF_REPO/.xyz" ;;
    inside)   _target="$VF_REPO/vendor/xyz"; mkdir -p "$VF_REPO/vendor" ;;
    outside)  _target="$WORK/outside-$(basename "$VF_REPO")-xyz"; mkdir -p "$_target" ;;
  esac

  case "$_mode" in
    stub)
      mkdir -p "$_target"
      _vf_stub_harness "$_target"
      _sha="${_stale:-$(git -C "$_vf_harness_root" rev-parse HEAD 2>/dev/null || echo 0000000000000000000000000000000000000000)}"
      _vf_write_version "$_sha" "$_tier" "$_target"
      ;;
    real)
      # xyz-vendor.sh vendors into <target-repo>/.xyz — it owns the basename. For a symlinked
      # layout we vendor into a scratch repo and move the result.
      if [ -n "$_link" ]; then
        _scratch="$WORK/vf-real-scratch-$$"
        mkdir -p "$_scratch"; _vf_init_repo "$_scratch"
        _vf_assert_safe_target "$_scratch" || return 1
        bash "$_vf_harness_root/relay-automation/xyz-vendor.sh" "$_scratch" --no-register >/dev/null 2>&1 \
          || { _vf_die "xyz-vendor.sh failed on scratch $_scratch"; return 1; }
        rm -rf "$_target"; mv "$_scratch/.xyz" "$_target"; rm -rf "$_scratch"
      else
        _args="--no-register"; [ "$_tier" = 2 ] && _args="$_args --with-releases"
        # shellcheck disable=SC2086
        bash "$_vf_harness_root/relay-automation/xyz-vendor.sh" "$VF_REPO" $_args >/dev/null 2>&1 \
          || { _vf_die "xyz-vendor.sh failed on $VF_REPO"; return 1; }
      fi
      if [ -n "$_stale" ]; then _vf_write_version "$_stale" "$_tier" "$_target"; fi
      ;;
  esac

  if [ -n "$_link" ]; then
    ln -s "$_target" "$VF_REPO/.xyz"
    VF_LINK="$VF_REPO/.xyz"
  fi
  VF_HARNESS="$VF_REPO/.xyz"

  if [ -n "$_wt" ]; then
    git -C "$VF_REPO" worktree add -q -b "vf-linked-$$" "$_wt" HEAD || { _vf_die "worktree add failed: $_wt"; return 1; }
    VF_WORKTREE="$(cd -P "$_wt" && pwd)"
  fi
  return 0
}

# Tear down a fixture built by make_vendored_fixture (worktree first, then the repo).
remove_vendored_fixture() {
  [ -n "${VF_WORKTREE:-}" ] && git -C "$VF_REPO" worktree remove --force "$VF_WORKTREE" >/dev/null 2>&1 || true
  [ -n "${VF_REPO:-}" ] && rm -rf "$VF_REPO"
  VF_REPO="" VF_HARNESS="" VF_LINK="" VF_WORKTREE=""
}
