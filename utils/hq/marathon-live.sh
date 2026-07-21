#!/usr/bin/env bash
# utils/hq/marathon-live.sh — read-only cross-repo LIVE marathon status (GH-218).
#
# Answers "what marathons are running right now?" across every XYZ-vendored repo on this machine, by
# COMPOSING existing local primitives — it stands up no new per-repo infrastructure (no MCP server):
#   - repo discovery : hq_known_repos + hq_repo_resolve (utils/hq/hq-lib.sh), the SAME enumeration
#                      marathon-scan.sh already uses. No new discovery code.
#   - live claim     : each repo's OWN `tick project` regenerates its `.tick/STATE.md` from its event
#                      log; the `## Claimed` section names the task id + claimant currently holding work
#                      (the live signal the doc-status scanner marathon-scan.sh cannot see).
#   - is-it-really-driving : cross-checked against the driver lock file (`.git/relay-driver.lock` or a
#                      vendored `.xyz/.relay-driver.lock`) and any `marathon/*`-branch worktree with a
#                      commit inside the activity window — a claim without either is "claimed, not driving".
#
# Emits one compact Markdown table: repo | marathon/lane | task | claimant | live | last activity.
# Read-only over every target repo (the only write is the aggregate report itself), matching
# marathon-scan.sh's safety posture. Phase 2 (rollup.sh) embeds this report verbatim.
#
# Usage:
#   utils/hq/marathon-live.sh
#   utils/hq/marathon-live.sh --out PROJECT/2-WORKING/HQ-MARATHON-LIVE-2026-07-19.md --window 30
#
# Test seams (mirror marathon-scan.sh):
#   HQ_MARATHON_LIVE_TODAY   pin the report date (YYYY-MM-DD)
#   HQ_MARATHON_LIVE_NOW     pin the generated-at timestamp
#   HQ_MARATHON_LIVE_NOW_EPOCH  pin "now" (unix seconds) for the worktree activity-window math
#   HQ_MARATHON_LIVE_WINDOW_MIN default activity window in minutes (default 30; --window overrides)

set -uo pipefail
# strict-mode: -e exempt — analysis tool with expected-nonzero probes (repo resolution, tick, git in a
# non-repo fixture); every such failure is handled explicitly. See GUIDING-PRINCIPLES.md#strict-mode-policy.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
# shellcheck source=utils/hq/hq-lib.sh
. "$HERE/hq-lib.sh"

TODAY="${HQ_MARATHON_LIVE_TODAY:-"$(date -u +%Y-%m-%d)"}"
NOW="${HQ_MARATHON_LIVE_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
NOW_EPOCH="${HQ_MARATHON_LIVE_NOW_EPOCH:-"$(date +%s)"}"
WINDOW_MIN="${HQ_MARATHON_LIVE_WINDOW_MIN:-30}"
OUT=""

usage() {
  cat <<'EOF'
Usage: utils/hq/marathon-live.sh [--out FILE] [--window MINUTES]

Enumerate XYZ-vendored repos, regenerate each repo's own tick STATE.md, and report every LIVE
marathon claim (repo, marathon/lane, task, claimant, live-or-stalled, last activity) as one aggregate
Markdown table written in the hub repo. Read-only over every target repo.
EOF
}

while (($# > 0)); do
  case "$1" in
    --out) OUT="${2:-}"; shift 2 ;;
    --window) WINDOW_MIN="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; echo "hq marathon-live: unknown argument: $1" >&2; exit 2 ;;
  esac
done

case "$WINDOW_MIN" in ''|*[!0-9]*) echo "hq marathon-live: --window must be a whole number of minutes" >&2; exit 2 ;; esac

OUT="${OUT:-$ROOT/PROJECT/2-WORKING/HQ-MARATHON-LIVE-$TODAY.md}"
[[ "$OUT" = /* ]] || OUT="$ROOT/$OUT"
mkdir -p "$(dirname "$OUT")"

ROWS="$(mktemp "${TMPDIR:-/tmp}/hq-marathon-live-rows.XXXXXX")"
trap 'rm -f "$ROWS"' EXIT

# tsv_escape/pipe-escape a cell for a Markdown table (| would break the column).
md_cell() { printf '%s' "$1" | sed 's/|/\\|/g'; }

# Resolve a repo's own tick binary (native, then vendored) — same precedence find-harness.sh uses.
resolve_tick() {
  local repo_path="$1"
  if [[ -x "$repo_path/bin/tick" ]]; then printf '%s' "$repo_path/bin/tick"; return 0; fi
  if [[ -x "$repo_path/.xyz/bin/tick" ]]; then printf '%s' "$repo_path/.xyz/bin/tick"; return 0; fi
  return 1
}

# Derive a human "marathon/lane" label from a claimed task id (e.g. MARATHON-GH208-FOO-TURN -> GH208-FOO).
lane_of() {
  local task="$1"
  task="${task#MARATHON-}"; task="${task#RELAY-}"
  task="${task%-TURN}"
  printf '%s' "$task"
}

# Is the driver lock present for this repo (native or vendored)? Prints the lock path or nothing.
driver_lock_path() {
  local repo_path="$1"
  [[ -e "$repo_path/.git/relay-driver.lock" ]] && { printf '%s' "$repo_path/.git/relay-driver.lock"; return 0; }
  [[ -e "$repo_path/.xyz/.relay-driver.lock" ]] && { printf '%s' "$repo_path/.xyz/.relay-driver.lock"; return 0; }
  return 1
}

# Newest marathon/*-branch worktree commit epoch within the repo, or empty. Best-effort — a fixture
# .git that is not a real repo simply yields nothing (guarded), never an error.
newest_marathon_worktree_epoch() {
  local repo_path="$1" wt="" br="" best="" ct
  while IFS= read -r line; do
    case "$line" in
      worktree\ *) wt="${line#worktree }" ;;
      branch\ *)
        br="${line#branch }"
        if [[ "$br" == refs/heads/marathon/* && -n "$wt" ]]; then
          ct="$(git -C "$wt" log -1 --format=%ct 2>/dev/null || true)"
          if [[ -n "$ct" && ( -z "$best" || "$ct" -gt "$best" ) ]]; then best="$ct"; fi
        fi
        ;;
    esac
  done < <(git -C "$repo_path" worktree list --porcelain 2>/dev/null || true)
  printf '%s' "$best"
}

window_secs=$(( WINDOW_MIN * 60 ))
repos_scanned=0
live_count=0
stalled_count=0
idle_count=0

while IFS= read -r repo; do
  [[ -n "$repo" ]] || continue
  fields="$(hq_repo_resolve "$repo")"
  repo_path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
  [[ -n "$repo_path" && -d "$repo_path" ]] || continue
  repos_scanned=$((repos_scanned + 1))

  # Regenerate this repo's STATE.md from its own event log (writes only .tick/, coordination state —
  # never touched code). Best-effort: a repo with no tick binary / no events is simply reported idle.
  tick_bin="$(resolve_tick "$repo_path" || true)"
  if [[ -n "$tick_bin" ]]; then
    ( cd "$repo_path" && TICK_REPO_ROOT="$repo_path" "$tick_bin" project ) >/dev/null 2>&1 || true
  fi

  # Liveness signals for the whole repo (shared by each claimed task in it).
  lock_path="$(driver_lock_path "$repo_path" || true)"
  wt_epoch="$(newest_marathon_worktree_epoch "$repo_path")"
  recent_wt=0
  if [[ -n "$wt_epoch" ]] && (( NOW_EPOCH - wt_epoch <= window_secs )); then recent_wt=1; fi
  is_driving=0
  [[ -n "$lock_path" || "$recent_wt" == 1 ]] && is_driving=1

  # Last-activity display: newest marathon worktree commit, else the driver-lock mtime, else em dash.
  last_activity="—"
  if [[ -n "$wt_epoch" ]]; then
    last_activity="$(date -u -r "$wt_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$wt_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'epoch:%s' "$wt_epoch")"
  elif [[ -n "$lock_path" ]]; then
    lk_epoch="$(stat -f %m "$lock_path" 2>/dev/null || stat -c %Y "$lock_path" 2>/dev/null || true)"
    [[ -n "$lk_epoch" ]] && last_activity="$(date -u -r "$lk_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$lk_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'epoch:%s' "$lk_epoch")"
  fi

  # Parse the `## Claimed` section of STATE.md: `- <task> by <agent>[ paths: ...]`.
  state_file="$repo_path/.tick/STATE.md"
  claimed_any=0
  if [[ -f "$state_file" ]]; then
    while IFS= read -r cl; do
      # cl is a claimed line body: "<task> by <agent> paths: [...]" (paths optional)
      task="${cl%% by *}"
      rest="${cl#* by }"
      agent="${rest%% paths:*}"; agent="${agent%% }"; agent="${agent# }"
      [[ -n "$task" && "$task" != "$cl" ]] || continue   # require the " by " separator
      claimed_any=1
      if [[ "$is_driving" == 1 ]]; then
        live="🟢 live"; live_count=$((live_count + 1))
      else
        live="🟡 claimed, not driving"; stalled_count=$((stalled_count + 1))
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(md_cell "$repo")" "$(md_cell "$(lane_of "$task")")" "$(md_cell "$task")" \
        "$(md_cell "$agent")" "$live" "$(md_cell "$last_activity")" >>"$ROWS"
    done < <(awk '
      /^## Claimed[[:space:]]*$/ { inc=1; next }
      /^## / { inc=0 }
      inc && /^- / { sub(/^- /, ""); print }
    ' "$state_file")
  fi

  if [[ "$claimed_any" == 0 ]]; then
    idle_count=$((idle_count + 1))
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$(md_cell "$repo")" "—" "—" "—" "⚪ idle" "$(md_cell "$last_activity")" >>"$ROWS"
  fi
done < <(hq_known_repos)

{
  cat <<EOF
---
title: HQ MARATHON LIVE — $TODAY (cross-repo, right now)
status: Active
created: $TODAY
updated: $TODAY
owner: noel@neochro.me
doc_type: report
generated_by: utils/hq/marathon-live.sh (GH-218)
roadmap_exempt: true
---

# HQ Marathon — Live cross-repo status ($NOW)

Read-only snapshot of every XYZ-vendored repo's live \`tick\` claim, cross-checked against its driver
lock and \`marathon/*\` worktree activity (window: ${WINDOW_MIN}m). "🟢 live" = a claim WITH a held
driver lock or a recently-active marathon worktree; "🟡 claimed, not driving" = a claim with neither
(likely stalled); "⚪ idle" = nothing claimed.

- Repos scanned: $repos_scanned
- Live claims: $live_count
- Claimed but not driving: $stalled_count
- Idle repos: $idle_count

| Repo | Marathon / lane | Task | Claimant | Live | Last activity |
|---|---|---|---|---|---|
EOF
  if [[ -s "$ROWS" ]]; then
    while IFS=$'\t' read -r c_repo c_lane c_task c_agent c_live c_last; do
      printf '| %s | %s | %s | %s | %s | %s |\n' "$c_repo" "$c_lane" "$c_task" "$c_agent" "$c_live" "$c_last"
    done <"$ROWS"
  else
    printf '| _(no XYZ-vendored repos resolved)_ | | | | | |\n'
  fi
} > "$OUT"

echo "hq marathon-live: ✓ wrote $OUT ($live_count live, $stalled_count claimed-not-driving, $idle_count idle across $repos_scanned repos)"
