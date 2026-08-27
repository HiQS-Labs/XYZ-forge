#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# GH-401: this audit exists for GH-209 — "every test invocation of the marathon driver is
# MARATHON_ROOT-scoped" — but its scope was two hardcoded filenames. An unscoped `--dry-run`
# invocation in test/gh268-relay-cue-and-target-checks.sh therefore wrote phases/p1/RELAY.md into
# the HARNESS repo on every `bash validate.sh`, and the audit reported PASS the whole time: it was
# out of reach because of its FILENAME, not because it was safe. A guard whose coverage is a literal
# list silently stops covering the thing it was written for the moment someone adds a file.
#
# GH-273: the same blindness applied to SPELLINGS. GH-195 let test/gh115-round-cap.sh commit a live
# transcript onto the real clone because a direct `python3 utils/py/marathon_drive.py` call was
# invisible to a matcher that only knew `bash <driver>.sh`. The matcher now recognizes the Python
# twins (marathon_drive.py / relay_drive.py) and the relay-drive.sh pair — in PROGRAM position
# only, because `python3 - "<path>" <<'PY'` (gh390/gh322/gh342 shapes) READS the driver without
# running it, and a whole-line keyword match would flag comments, assignments, and echo strings.
#
# Audit every test script instead, and let discover_file_metadata/find_invocation_target decide what
# is actually an invocation — a file with none is simply skipped. The audit excludes only itself:
# it necessarily contains the driver path literals it matches on, so it would self-report.
FILES=()
for candidate in "$HERE"/*.sh; do
  [ "$candidate" = "${BASH_SOURCE[0]}" ] && continue
  [ "$(basename "$candidate")" = "$(basename "${BASH_SOURCE[0]}")" ] && continue
  FILES+=("$candidate")
done

safe_vars=()
alias_names=()
alias_targets=()
failures=0
checked=0

add_safe_var() {
  local candidate="$1"
  local existing
  for existing in "${safe_vars[@]}"; do
    [ "$existing" = "$candidate" ] && return 0
  done
  safe_vars+=("$candidate")
}

reset_safe_vars() {
  # A and B are the _setup.sh fixture vars; WORK is the sandbox root itself — every
  # fixture-guard assertion already refuses to operate outside it.
  safe_vars=(A B WORK)
}

is_safe_var() {
  local candidate="$1"
  local existing
  for existing in "${safe_vars[@]}"; do
    [ "$existing" = "$candidate" ] && return 0
  done
  return 1
}

reset_aliases() {
  alias_names=()
  alias_targets=()
}

set_alias() {
  local name="$1"
  local target="$2"
  local i
  for ((i = 0; i < ${#alias_names[@]}; i++)); do
    if [ "${alias_names[$i]}" = "$name" ]; then
      alias_targets[$i]="$target"
      return 0
    fi
  done
  alias_names+=("$name")
  alias_targets+=("$target")
}

get_alias_target() {
  local name="$1"
  local i
  for ((i = 0; i < ${#alias_names[@]}; i++)); do
    if [ "${alias_names[$i]}" = "$name" ]; then
      printf '%s\n' "${alias_targets[$i]}"
      return 0
    fi
  done
  return 1
}

line_has_safe_cwd() {
  local line="$1"
  local candidate
  if [[ "$line" =~ cd[[:space:]]+\"\$([A-Z][A-Z0-9_]*)\" ]]; then
    candidate="${BASH_REMATCH[1]}"
    is_safe_var "$candidate"
    return $?
  fi
  return 1
}

discover_file_metadata() {
  local file="$1"
  local line name target

  reset_safe_vars
  reset_aliases

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=\"\$WORK/ ]]; then
      add_safe_var "${BASH_REMATCH[1]}"
    fi

    # GH-273: transitive safety — `R1="$A/relay1.md"` (poll-relay) or
    # `DRIVE="$A/relay-automation/relay-drive.sh"` derives entirely from an
    # already-safe var, so the derived var is safe too. Registration is in file
    # order, matching how fixtures are built before they are used.
    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=\"\$([A-Z][A-Z0-9_]*)/ ]] && is_safe_var "${BASH_REMATCH[2]}"; then
      add_safe_var "${BASH_REMATCH[1]}"
    fi

    # GH-273: the Python twins are the default runtime — a variable pointing at
    # utils/py/marathon_drive.py or relay_drive.py is the same driver the .sh
    # spellings wrap, so it registers the same way.
    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=.*(relay-automation/(marathon|marathon-drive|relay-drive)\.sh|utils/py/(marathon_drive|relay_drive)\.py) ]]; then
      name="${BASH_REMATCH[1]}"
      target="${BASH_REMATCH[2]}"
      set_alias "$name" "$target"
    fi
  done < "$file"
}

find_invocation_target() {
  local line="$1"
  local rest var target

  if [[ "$line" == *'./.xyz/relay-automation/marathon-drive.sh'* ]]; then
    printf '%s\n' "marathon-drive"
    return 0
  fi

  if [[ "$line" == *'./.xyz/relay-automation/marathon.sh'* ]]; then
    printf '%s\n' "marathon"
    return 0
  fi

  # GH-273: direct `python3 "<path>/marathon_drive.py"` / relay_drive.py — PROGRAM
  # position only (the quoted path must be the token right after the interpreter), so
  # the `python3 - "<path>" <<'PY'` heredoc-argv shape that merely READS the driver
  # (gh390/gh322/gh342) never matches.
  if [[ "$line" =~ python3?[[:space:]]+\"[^\"]*(utils/py/|/|^)(marathon_drive|relay_drive)\.py\" ]]; then
    printf '%s\n' "${BASH_REMATCH[2]}"
    return 0
  fi

  # GH-273: same for a direct `bash "<path>/relay-automation/<driver>.sh` beyond the
  # vendored ./.xyz literals above (gh376 drives "$WT/relay-automation/relay-drive.sh").
  if [[ "$line" =~ bash[[:space:]]+\"[^\"]*relay-automation/(marathon-drive|relay-drive|marathon)\.sh\" ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  rest="${line#*bash \"\$}"
  if [ "$rest" != "$line" ]; then
    var="${rest%%\"*}"
    target="$(get_alias_target "$var" || true)"
    if [ -n "$target" ]; then
      printf '%s\n' "$target"
      return 0
    fi
  fi

  rest="${line#*python3 \"\$}"
  if [ "$rest" != "$line" ]; then
    var="${rest%%\"*}"
    target="$(get_alias_target "$var" || true)"
    if [ -n "$target" ]; then
      printf '%s\n' "$target"
      return 0
    fi
  fi

  return 1
}

# GH-273: a driver invocation's scoping often lives on the CONTINUATION group, not the
# program line — `python3 "$DRIVER" \` followed by `--phase-brief "$A/brief.md"`. Answer
# for the whole logical line.
invocation_group() {  # <idx> <lines...> -> "start:end"
  local idx="$1"; shift
  local -a lines=("$@")
  local start="$idx" end="$idx"
  while [ "$start" -gt 0 ] && [[ "${lines[$((start - 1))]}" =~ \\[[:space:]]*$ ]]; do
    start=$((start - 1))
  done
  while [ "$end" -lt "$((${#lines[@]} - 1))" ] && [[ "${lines[$end]}" =~ \\[[:space:]]*$ ]]; do
    end=$((end + 1))
  done
  printf '%s:%s\n' "$start" "$end"
}

group_has_safe_cwd() {  # <group-text>
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    line_has_safe_cwd "$line" && return 0
  done <<< "$1"
  return 1
}

# A driver flag whose value anchors the run's outputs to a $WORK-derived fixture
# (gh115's `--relay-file "$A/relay.md"`, gh438's `--phases-dir "$A/phases"`).
group_has_safe_anchor_arg() {  # <group-text>
  local g="$1" var
  while [[ "$g" =~ --(phase-brief|phases-dir|relay-file|artifact|target-root)[[:space:]]+\"\$([A-Z][A-Z0-9_]*) ]]; do
    var="${BASH_REMATCH[2]}"
    is_safe_var "$var" && return 0
    g="${g#*${BASH_REMATCH[0]}}"
  done
  return 1
}

# A scoping env assignment (gh378's inline `MARATHON_ROOT="$ROOT" \` where ROOT is the
# $WORK fixture repo, gh115's file-scope `export MARATHON_ROOT="$A"`).
group_has_safe_scoping_env() {  # <group-text>
  local g="$1" var
  while [[ "$g" =~ (MARATHON_ROOT|RELAY_TARGET_ROOT|TICK_REPO_ROOT)[[:space:]]*=[[:space:]]*\"\$([A-Z][A-Z0-9_]*) ]]; do
    var="${BASH_REMATCH[2]}"
    is_safe_var "$var" && return 0
    g="${g#*${BASH_REMATCH[0]}}"
  done
  return 1
}

# The invoked driver itself lives under a $WORK-derived path (gh376's
# `python3 "$WT/utils/py/relay_drive.py"`, gh331's fixture copy): the driver resolves its
# repo from its own location, so the run is fixture-local by construction.
line_invokes_fixture_resident_driver() {  # <line>
  local line="$1" var
  while [[ "$line" =~ \"\$([A-Z][A-Z0-9_]*)[^\"]*(marathon_drive|relay_drive)\.py\" ]]; do
    var="${BASH_REMATCH[1]}"
    is_safe_var "$var" && return 0
    line="${line#*${BASH_REMATCH[0]}}"
  done
  while [[ "$line" =~ \"\$([A-Z][A-Z0-9_]*)[^\"]*relay-automation/(marathon-drive|relay-drive|marathon)\.sh\" ]]; do
    var="${BASH_REMATCH[1]}"
    is_safe_var "$var" && return 0
    line="${line#*${BASH_REMATCH[0]}}"
  done
  return 1
}

check_invocation_safety() {
  local idx="$1"
  shift
  local -a lines=("$@")
  local start j boundary_found=0
  local line="${lines[$idx]}"
  local group_text="" span gstart gend

  # GH-273: the invocation's continuation group, computed first — a driver call's
  # scoping often lives on the lines above (env-prefix blocks) or below (args).
  span="$(invocation_group "$idx" "${lines[@]}")"
  gstart="${span%%:*}"
  gend="${span##*:}"
  for ((j = gstart; j <= gend; j++)); do
    group_text+="${lines[$j]} "
  done

  if [[ "$line" == *'MARATHON_ROOT='* ]]; then
    return 0
  fi

  # GH-273: a bare MARATHON_ROOT= anywhere in the continuation group — the original
  # continuation rule, extended to the args that follow the program token (gh402's
  # subshell env-prefix blocks, gh391's `if MARATHON_ROOT=... \` lines).
  if [[ "$group_text" == *'MARATHON_ROOT='* ]]; then
    return 0
  fi

  if line_has_safe_cwd "$line"; then
    return 0
  fi

  if group_has_safe_cwd "$group_text" \
     || group_has_safe_scoping_env "$group_text" \
     || group_has_safe_anchor_arg "$group_text" \
     || line_invokes_fixture_resident_driver "$line"; then
    return 0
  fi

  # File-scope scoping exports (gh115's `export MARATHON_ROOT="$A"` two lines above the
  # invocation): an EXPORTED root persists for every later line, but only when its VALUE
  # is fixture-derived — a nearby `MARATHON_ROOT="$REAL_REPO"` must not whitelist a
  # later invocation, so unsafe-valued assignments never count here.
  local wstart=$((idx > 40 ? idx - 40 : 0))
  for ((j = idx - 1; j >= wstart; j--)); do
    group_has_safe_scoping_env "${lines[$j]} " && return 0
    line_has_safe_cwd "${lines[$j]}" && return 0
  done

  for ((j = idx - 1; j >= wstart; j--)); do
    if [[ "${lines[$j]}" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)[[:space:]]*\{ ]]; then
      start="$j"
      boundary_found=1
      break
    fi
    if [[ "${lines[$j]}" =~ ^[[:space:]]*\([[:space:]]*$ ]]; then
      start="$j"
      boundary_found=1
      break
    fi
  done

  [ "$boundary_found" -eq 1 ] || return 1

  for ((j = start; j < idx; j++)); do
    if [[ "${lines[$j]}" == *'MARATHON_ROOT='* ]]; then
      return 0
    fi
    if line_has_safe_cwd "${lines[$j]}"; then
      return 0
    fi
  done

  return 1
}

audit_file() {
  local file="$1"
  local -a lines=()
  local line target idx

  discover_file_metadata "$file"

  while IFS= read -r line || [ -n "$line" ]; do
    lines+=("$line")
  done < "$file"

  for ((idx = 0; idx < ${#lines[@]}; idx++)); do
    target="$(find_invocation_target "${lines[$idx]}" || true)"
    [ -z "$target" ] && continue
    checked=$((checked + 1))
    if check_invocation_safety "$idx" "${lines[@]}"; then
      printf 'PASS: %s:%d %s invocation is rooted or fixture-local\n' \
        "${file#$HERE/}" "$((idx + 1))" "$target"
    else
      printf 'FAIL: %s:%d %s invocation lacks MARATHON_ROOT and fixture-local cwd\n' \
        "${file#$HERE/}" "$((idx + 1))" "$target" >&2
      failures=$((failures + 1))
    fi
  done
}

for file in "${FILES[@]}"; do
  audit_file "$file"
done

if [ "$checked" -eq 0 ]; then
  echo "FAIL: no real marathon script invocations found to audit" >&2
  exit 1
fi

if [ "$failures" -ne 0 ]; then
  echo "FAIL: $failures unsafe marathon invocation(s) found" >&2
  exit 1
fi

echo "PASS: audited $checked real marathon invocation(s)"

# ── the driver commits phase artifacts, so they must not be gitignored ────────────────────────────
# marathon_drive.py stages phase output with `git add --` and check=True at three sites
# (ESCALATION.md, the transcript, RELAY.md — line numbers deliberately not cited; they have drifted
# twice already and a stale citation reads as precision it does not have). `git add` on an EXPLICIT path that .gitignore covers
# exits 1 — "The following paths are ignored ... Use -f if you really want to add them" — so
# check=True raises CalledProcessError and the phase dies while trying to record itself.
#
# Not hypothetical: `/phases/` was added to .gitignore on 2026-08-09 to stop the #401/#461 churn, and
# it would have crashed the first new same-repo phase. Reverted the same day; this assertion is what
# makes the revert stick. Verified directly before writing it: in a scratch repo ignoring /phases/,
# `git add -- phases/newrun/RELAY.md` exits 1.
#
# If phase records should stop being committed, that is a driver change (and a #388 durability
# question), not a .gitignore line — the ignore alone breaks the write without removing the intent.
#
# GH-484: the default moved to marathon-system/, so the NEW default is now the path that actually
# matters. phases/ stays probed too — the driver no longer writes there, but a fleet repo whose
# vendored .xyz/ has not re-synced still does, and this repo's committed pre-flip records live
# there. An ignore rule on either name is a live crash for someone.
audit_root="$(cd "$(dirname "$0")/.." && pwd)"
ignore_violations=0
for probe in marathon-system/audit-probe/RELAY.md marathon-system/audit-probe/ESCALATION.md \
             phases/audit-probe/RELAY.md phases/audit-probe/ESCALATION.md; do
  if git -C "$audit_root" check-ignore -q "$probe" 2>/dev/null; then
    echo "FAIL: .gitignore covers $probe, but the driver stages it with \`git add --\` + check=True — a new same-repo phase would exit 1 while recording itself" >&2
    ignore_violations=$((ignore_violations + 1))
  fi
done
if [ "$ignore_violations" -ne 0 ]; then
  exit 1
fi
echo "PASS: phase artifacts the driver commits are not gitignored (git add -- would exit 1 if they were)"
