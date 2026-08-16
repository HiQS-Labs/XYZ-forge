#!/usr/bin/env bash
#
# relay-to-issue.sh — turn a finished relay thread into a GitHub issue.
#
# Deterministic plumbing for the /relay-to-issue skill. The LLM reads the relay
# thread and writes the issue title + body (the judgment); THIS script does the
# mechanical, repeatable parts so they can't drift: locate the thread, resolve
# WHICH repo the relay was about, dedup against an already-filed issue, preflight
# `gh`, create the issue, and stamp the URL back into the thread (provenance +
# dedup in one move).
#
# Subcommands:
#   resolve   Print machine-readable facts about a thread (paths, target repo,
#             dedup status, gh auth). The skill calls this FIRST, then reads it.
#   file      Create the issue from a title + body file, then stamp the thread.
#
# Usage:
#   relay-to-issue.sh resolve [--thread <path|slug>] [--repo owner/name]
#   relay-to-issue.sh file    --thread <path> --title <t> --body-file <f>
#                             [--repo owner/name] [--labels a,b] [--inbox]
#                             [--force] [--dry-run]
#
# Target-repo resolution (first hit wins; reported as TARGET_SOURCE):
#   1. --repo owner/name                          explicit
#   2. thread header `TARGET-REPO: owner/name`    declared
#   3. exactly ONE git repo across all absolute   inferred
#      paths cited in the thread  → its origin
#   4. no absolute paths cited    → current repo  current-repo
#      origin (a same-repo relay)
#   Multiple distinct repos cited with no override → ambiguous (exit 3); pass
#   --repo or add a `TARGET-REPO:` header. We never auto-post to a guessed repo.
#
# Self-locating + symlink-safe (the skill is usually symlinked into
# ~/.claude/skills/relay-to-issue). bash 3.2-safe (macOS default). set -u.
# Read-only EXCEPT: `gh issue create`, the provenance stamp appended to the
# thread, and (with --inbox) one pointer doc in PROJECT/1-INBOX/.
set -u

die() { echo "relay-to-issue: $1" >&2; exit "${2:-1}"; }

# --- resolve this script's real directory (symlink-safe; bash 3.2 / macOS) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/relay-to-issue
REPO_ROOT="$(cd "$SELF_DIR/../.." >/dev/null 2>&1 && pwd || true)"
[ -n "$REPO_ROOT" ] || die "cannot resolve repo root from $SELF_DIR" 1
RELAY_DIR="$REPO_ROOT/relay-system"

# ---------------------------------------------------------------------------
# small helpers
# ---------------------------------------------------------------------------
_mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }

# first value of a `Key: value` header line
_field() { sed -n "s/^[[:space:]]*$1:[[:space:]]*//p" "$2" 2>/dev/null | head -1; }

# convert a git remote URL to owner/name (or empty)
_slugify_origin() {
  local u="${1:-}"
  u="${u%.git}"
  case "$u" in
    git@*:*)          printf '%s\n' "${u#*:}" ;;
    ssh://*)          u="${u#ssh://}"; u="${u#*/}"; printf '%s\n' "$u" ;;
    https://*|http://*) u="${u#*://}"; u="${u#*/}"; printf '%s\n' "$u" ;;
    *)                printf '%s\n' "" ;;
  esac
}

_repo_slug() {  # $1 = a dir inside a git repo → owner/name
  local url
  url="$(git -C "$1" remote get-url origin 2>/dev/null || true)"
  [ -n "$url" ] && _slugify_origin "$url"
}

_git_root() {   # $1 = a path → its git toplevel (or empty)
  local p="$1"
  [ -e "$p" ] || p="$(dirname "$p")"
  git -C "$p" rev-parse --show-toplevel 2>/dev/null || true
}

# distinct owner/name for every absolute path cited in the thread
_infer_repos() {
  grep -oE '/(Users|home)/[A-Za-z0-9._/@+-]+' "$1" 2>/dev/null \
    | sort -u \
    | while IFS= read -r p; do
        gr="$(_git_root "$p")"; [ -n "$gr" ] || continue
        slug="$(_repo_slug "$gr")"; [ -n "$slug" ] && printf '%s\n' "$slug"
      done | sort -u
}

_filed_url() {  # already-stamped issue URL, or empty
  grep -oE 'relay-to-issue: filed https://[^ ]+' "$1" 2>/dev/null | head -1 | awk '{print $3}'
}

_gh_auth() { command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; }

# Locate a thread file. Empty arg = newest. Else a path, a slug, or date/slug.
_resolve_thread() {
  local arg="${1:-}" f=""
  if [ -z "$arg" ]; then
    f="$(find "$RELAY_DIR" -type f -name '*.md' ! -name 'baton-pattern.md' 2>/dev/null \
         | while IFS= read -r p; do printf '%s\t%s\n' "$(_mtime "$p")" "$p"; done \
         | sort -rn | head -1 | cut -f2-)"
  elif [ -f "$arg" ]; then
    f="$arg"
  else
    f="$(find "$RELAY_DIR" -type f -name '*.md' 2>/dev/null \
         | grep -E "/${arg%.md}\.md$" | head -1)"
    [ -n "$f" ] || f="$(find "$RELAY_DIR" -type f -path "*${arg}*" -name '*.md' 2>/dev/null | head -1)"
  fi
  [ -n "$f" ] && [ -f "$f" ] || return 1
  ( cd "$(dirname "$f")" >/dev/null 2>&1 && printf '%s/%s\n' "$(pwd)" "$(basename "$f")" )
}

# Sets TARGET + TARGET_SOURCE (+ TARGET_CANDIDATES on ambiguity).
# rc: 0 resolved · 2 unresolvable · 3 ambiguous
TARGET=""; TARGET_SOURCE=""; TARGET_CANDIDATES=""
_resolve_target() {
  local f="$1" explicit="${2:-}" decl repos n cur
  if [ -n "$explicit" ]; then TARGET="$explicit"; TARGET_SOURCE="explicit"; return 0; fi
  decl="$(_field 'TARGET-REPO' "$f")"
  if [ -n "$decl" ]; then TARGET="$decl"; TARGET_SOURCE="declared"; return 0; fi
  repos="$(_infer_repos "$f")"
  n="$(printf '%s' "$repos" | grep -c .)"
  if [ "$n" -eq 1 ]; then TARGET="$repos"; TARGET_SOURCE="inferred"; return 0; fi
  if [ "$n" -eq 0 ]; then
    cur="$(_repo_slug "$REPO_ROOT")"
    if [ -n "$cur" ]; then TARGET="$cur"; TARGET_SOURCE="current-repo"; return 0; fi
    return 2
  fi
  TARGET_CANDIDATES="$(printf '%s' "$repos" | tr '\n' ' ')"
  return 3
}

# ---------------------------------------------------------------------------
# subcommand: resolve
# ---------------------------------------------------------------------------
cmd_resolve() {
  local thread="" repo=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --thread) thread="${2:-}"; shift 2 ;;
      --repo)   repo="${2:-}"; shift 2 ;;
      *) die "resolve: unknown arg '$1'" 2 ;;
    esac
  done

  local f; f="$(_resolve_thread "$thread")" \
    || die "no relay thread found (looked in $RELAY_DIR; pass --thread <path|slug>)" 1

  local title status round filed head
  title="$(sed -n '1s/^#[[:space:]]*//p' "$f")"
  status="$(_field 'STATUS' "$f")"
  round="$(_field 'ROUND' "$f")"
  filed="$(_filed_url "$f")"
  head="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"

  _resolve_target "$f" "$repo"; local rc=$?

  printf 'THREAD: %s\n' "$f"
  printf 'SLUG: %s\n' "$(basename "$f" .md)"
  printf 'DATE: %s\n' "$(basename "$(dirname "$f")")"
  printf 'TITLE: %s\n' "${title:-(none)}"
  printf 'STATUS: %s\n' "${status:-(none)}"
  printf 'ROUND: %s\n' "${round:-(none)}"
  printf 'HEAD: %s\n' "$head"
  if [ "$rc" -eq 3 ]; then
    printf 'TARGET_REPO: AMBIGUOUS\n'
    printf 'TARGET_SOURCE: ambiguous\n'
    printf 'TARGET_CANDIDATES: %s\n' "$TARGET_CANDIDATES"
  elif [ "$rc" -eq 2 ]; then
    printf 'TARGET_REPO: UNRESOLVED\n'
    printf 'TARGET_SOURCE: unresolved\n'
  else
    printf 'TARGET_REPO: %s\n' "$TARGET"
    printf 'TARGET_SOURCE: %s\n' "$TARGET_SOURCE"
  fi
  printf 'ALREADY_FILED: %s\n' "${filed:-NONE}"
  if _gh_auth; then printf 'GH_AUTH: ok\n'; else printf 'GH_AUTH: missing\n'; fi
  [ "$rc" -eq 0 ] && return 0 || return "$rc"
}

# ---------------------------------------------------------------------------
# subcommand: file
# ---------------------------------------------------------------------------
cmd_file() {
  local thread="" repo="" title="" body="" labels="" inbox=0 force=0 dry=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --thread)    thread="${2:-}"; shift 2 ;;
      --repo)      repo="${2:-}"; shift 2 ;;
      --title)     title="${2:-}"; shift 2 ;;
      --body-file) body="${2:-}"; shift 2 ;;
      --labels)    labels="${2:-}"; shift 2 ;;
      --inbox)     inbox=1; shift ;;
      --force)     force=1; shift ;;
      --dry-run)   dry=1; shift ;;
      *) die "file: unknown arg '$1'" 2 ;;
    esac
  done
  [ -n "$thread" ] || die "file: --thread is required" 2
  [ -n "$title" ]  || die "file: --title is required" 2
  [ -n "$body" ]   || die "file: --body-file is required" 2

  local f; f="$(_resolve_thread "$thread")" || die "thread not found: $thread" 1
  [ -f "$body" ] || die "body file not found: $body" 2

  local existing; existing="$(_filed_url "$f")"
  if [ -n "$existing" ] && [ "$force" -ne 1 ]; then
    die "already filed for this thread: $existing  (re-run with --force to file again)" 4
  fi

  _resolve_target "$f" "$repo"; local rc=$?
  [ "$rc" -eq 3 ] && die "target repo ambiguous — pass --repo owner/name (candidates: $TARGET_CANDIDATES)" 3
  [ "$rc" -eq 2 ] && die "could not resolve a target repo — pass --repo owner/name" 3
  [ -n "$TARGET" ] || die "no target repo resolved" 3

  _gh_auth || die "gh is not authenticated — run: gh auth login" 5
  gh repo view "$TARGET" >/dev/null 2>&1 || die "cannot access repo '$TARGET' (gh repo view failed)" 5

  if [ "$dry" -eq 1 ]; then
    echo "DRY-RUN: would file into $TARGET (source: $TARGET_SOURCE)"
    echo "  title : $title"
    echo "  body  : $body"
    echo "  labels: ${labels:-(none)}"
    return 0
  fi

  # labels → repeated --label flags (bash 3.2-safe empty-array guard)
  local label_args=()
  if [ -n "$labels" ]; then
    local _l; IFS=',' read -ra _l <<<"$labels"
    local x; for x in "${_l[@]}"; do
      x="$(printf '%s' "$x" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [ -n "$x" ] && label_args+=(--label "$x")
    done
  fi

  local out url
  out="$(gh issue create -R "$TARGET" --title "$title" --body-file "$body" \
           ${label_args[@]+"${label_args[@]}"} 2>&1)" \
    || die "gh issue create failed: $out" 5
  url="$(printf '%s\n' "$out" | grep -oE 'https://github.com/[^ ]+/issues/[0-9]+' | head -1)"
  [ -n "$url" ] || die "issue created but could not capture URL from: $out" 5

  # provenance + dedup stamp (appended at EOF — relay is closed, no more turns)
  local head today
  head="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  today="$(date +%Y-%m-%d)"
  printf '\n<!-- relay-to-issue: filed %s @ %s on %s -->\n' "$url" "$head" "$today" >> "$f"

  # optional ledger loopback — only when the issue landed in THIS repo
  if [ "$inbox" -eq 1 ]; then
    local cur; cur="$(_repo_slug "$REPO_ROOT")"
    if [ "$TARGET" = "$cur" ]; then
      local num slug up inboxdoc
      num="${url##*/}"
      slug="$(basename "$f" .md)"
      up="$(printf '%s' "$slug" | tr '[:lower:]' '[:upper:]')"
      inboxdoc="$REPO_ROOT/PROJECT/1-INBOX/GH-${num}-${up}.md"
      if [ ! -e "$inboxdoc" ]; then
        {
          printf -- '---\n'
          printf 'gh_issue: %s\n' "$num"
          printf 'source: %s\n' "$url"
          printf 'title: "relay follow-ups: %s"\n' "$slug"
          printf 'status: Active\n'
          printf 'created: %s\n' "$today"
          printf 'updated: %s\n' "$today"
          printf 'owner: relay-to-issue (auto)\n'
          printf 'doc_type: gh-issue-capture\n'
          printf 'goal: >\n'
          printf '  Track the checklist filed from relay thread %s. The live issue is the\n' "$slug"
          printf '  discussion surface; follow the normal 1-INBOX -> 2-WORKING flow.\n'
          printf -- '---\n\n'
          printf '# GH-%s — relay follow-ups: %s\n\n' "$num" "$slug"
          printf '> Auto-captured by `relay-to-issue` from `%s`. See [issue #%s](%s).\n' \
            "relay-system/$(basename "$(dirname "$f")")/$(basename "$f")" "$num" "$url"
        } > "$inboxdoc"
        echo "relay-to-issue: inbox pointer → ${inboxdoc#$REPO_ROOT/}" >&2
      fi
    else
      echo "relay-to-issue: --inbox skipped (issue is in $TARGET, not the local repo $cur)" >&2
    fi
  fi

  echo "$url"
}

# ---------------------------------------------------------------------------
# dispatch
# ---------------------------------------------------------------------------
case "${1:-}" in
  resolve) shift; cmd_resolve "$@" ;;
  file)    shift; cmd_file "$@" ;;
  -h|--help|"")
    sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *) die "unknown subcommand '$1' (use: resolve | file | --help)" 2 ;;
esac
