#!/usr/bin/env bash
#
# release-lanes.sh — GH-284 Phase 4: turn a releases.db release into marathon input, and report
# what of it actually landed on trunk.
#
# Phase 3 gave a release a join key (`Milestone:` — a GitHub milestone TITLE). This is the half that
# uses it, in both directions of the GH-284 loop:
#
#   seed    release -> milestone -> its OPEN issues, as marathon candidates.
#           Emitted in the SAME JSON-lines shape as skills/10days/scan-issues.sh, because
#           release-driven selection is that pipeline with a different seed set, not a new pipeline.
#
#   rollup  milestone -> per-issue landed/mentioned/absent against the DERIVED trunk, plus an
#           "N/M landed" headline. Computed from git ancestry, not from anyone's memory.
#
# Usage:
#   utils/release-lanes.sh seed   [--milestone TITLE | --release NAME] [--limit N]
#   utils/release-lanes.sh rollup [--milestone TITLE | --release NAME] [--trunk REF] [--json]
#
# Milestone resolution, in order: --milestone wins; else --release NAME matches a releases.db release
# by version or codename; else the single in-progress release that carries a milestone.
#
# `rollup` derives trunk from origin/HEAD (never a hardcoded branch name). In this repo that is
# `origin/main`, which is the release trunk — but day-to-day work lands on `development` first, so
# "has it landed?" usually means "on development". `--trunk origin/development` asks that. The
# default stays derived so the tool is portable to a repo with one branch.
#
# Exit: 0 ok · 2 usage · 3 milestone unresolvable, or gh unavailable/unauthenticated · 4 the
# milestone is empty (deliberately NOT 0 — "nothing found" must not read as success).
#
# Requires: gh (authenticated). Run with the Bash sandbox disabled; gh needs keychain/TLS access.
set -uo pipefail
# strict-mode: -e exempt — reporting tool; gh/git probes are expected-nonzero-safe and handled explicitly.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASES_DB="${RELEASES_DB:-$ROOT/releases.db}"

die()  { printf 'release-lanes: %s\n' "$*" >&2; exit 2; }
# $1 is the message, $2 the exit code. Deliberately NOT "$*": that appended the exit code to the
# message the operator reads ("...(Exit 4, not 0.) 4").
fail() { printf 'release-lanes: %s\n' "$1" >&2; exit "${2:-3}"; }
log()  { printf 'release-lanes: %s\n' "$*" >&2; }

# ── argument parsing ────────────────────────────────────────────────────────────────────────────
VERB="${1:-}"; [[ -n "$VERB" ]] || die "usage: release-lanes.sh <seed|rollup> [--milestone TITLE | --release NAME]"
case "$VERB" in
  seed|rollup) shift ;;
  --help|-h) sed -n '2,26p' "$0"; exit 0 ;;
  *) die "unknown verb: $VERB (expected 'seed' or 'rollup')" ;;
esac

MILESTONE="" RELEASE="" LIMIT=200 AS_JSON=0 TRUNK_OVERRIDE=""
while (($#)); do
  case "$1" in
    --milestone) MILESTONE="${2:?--milestone needs a title}"; shift 2 ;;
    --release)   RELEASE="${2:?--release needs a name}";      shift 2 ;;
    --limit)     LIMIT="${2:?--limit needs a number}";        shift 2 ;;
    --trunk)     TRUNK_OVERRIDE="${2:?--trunk needs a ref}";  shift 2 ;;
    --json)      AS_JSON=1; shift ;;
    --help|-h)   sed -n '2,26p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ "$LIMIT" =~ ^[0-9]+$ ]] || die "--limit must be a number, got: $LIMIT"
[[ -z "$MILESTONE" || -z "$RELEASE" ]] || die "--milestone and --release are mutually exclusive"

# ── milestone resolution ────────────────────────────────────────────────────────────────────────
# Reads releases.db directly (GH-568) instead of parsing legacy markdown prose.
resolve_milestone() {
  [[ -n "$MILESTONE" ]] && { printf '%s' "$MILESTONE"; return 0; }
  [[ -f "$RELEASES_DB" ]] || fail "releases.db not found at $RELEASES_DB"
  RELEASE="$RELEASE" python3 - "$RELEASES_DB" <<'PYEOF'
import os
import sqlite3
import sys

want = os.environ.get("RELEASE", "").strip()
db_path = sys.argv[1]

def emit(msg, code):
    print(msg, file=sys.stderr)
    raise SystemExit(code)

try:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
except Exception as e:
    emit(f"release-lanes: cannot open releases.db at {db_path}: {e}", 3)

try:
    if want:
        cur = conn.execute(
            "SELECT version, codename, status, milestone FROM releases WHERE version = ? OR codename = ?",
            (want, want)
        )
        hits = cur.fetchall()
        if not hits:
            emit(f"release-lanes: no release matches --release {want!r} in releases.db "
                 f"(matched against version and codename)", 3)
        if len(hits) > 1:
            emit(f"release-lanes: --release {want!r} matches {len(hits)} releases — disambiguate with "
                 f"--milestone", 3)
        ms = hits[0]["milestone"]
        if not ms or not ms.strip():
            # Phase 3's own wording. A release with no join key cannot resolve to an issue set, and
            # returning an empty list here would look identical to a milestone with no open issues.
            emit(f"release-lanes: release {want!r} has no Milestone: — it cannot resolve to an issue "
                 f"set. Add the GitHub milestone title to its release record in releases.db.", 3)
        print(ms.strip())
        raise SystemExit(0)

    # No --release: fall back to the in-progress releases that carry a milestone. "shipped" and "cut" are excluded.
    cur = conn.execute(
        "SELECT version, codename, status, milestone FROM releases WHERE status NOT IN ('shipped', 'cut') AND milestone IS NOT NULL AND trim(milestone) != ''"
    )
    live = cur.fetchall()
    if not live:
        emit("release-lanes: no in-progress release in releases.db carries a Milestone:. Pass --milestone "
             "explicitly, or add the join key to the release you mean.", 3)
    if len(live) > 1:
        names = ", ".join(sorted(set(b["milestone"].strip() for b in live if b["milestone"])))
        emit(f"release-lanes: multiple in-progress releases carry milestones ({names}) — pass --release or "
             f"--milestone to pick one", 3)

    ms = live[0]["milestone"]
    print(ms.strip())
    raise SystemExit(0)
except sqlite3.Error as e:
    emit(f"release-lanes: query failed on {db_path}: {e}", 3)
PYEOF
}

require_gh() {
  command -v gh >/dev/null 2>&1 \
    || fail "gh CLI not found on PATH. This command reads GitHub; it has no offline mode."
  gh auth status >/dev/null 2>&1 \
    || fail "gh is not authenticated (gh auth status failed). Refusing to emit a partial list that
  could be mistaken for a complete one."
}

# Derived, never the literal 'development' — same rule the GH-284 P2 run log follows. An explicit
# --trunk wins, so asking "landed on development?" does not require hardcoding anything in here.
trunk_ref() {
  local ref branch
  [[ -n "$TRUNK_OVERRIDE" ]] && { printf '%s' "$TRUNK_OVERRIDE"; return 0; }
  ref="$(git -C "$ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -n "$ref" && "$ref" != "origin/HEAD" ]]; then printf '%s' "$ref"; return 0; fi
  branch="$(git -C "$ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  [[ -n "$branch" ]] && printf '%s' "$branch"
}

# ── seed ────────────────────────────────────────────────────────────────────────────────────────
cmd_seed() {
  local ms; ms="$(resolve_milestone)" || exit $?
  require_gh
  log "seeding from milestone: $ms"
  local out
  # Same fields and the same sort as skills/10days/scan-issues.sh, so the downstream /10days
  # pipeline consumes this without knowing which seed source produced it.
  out="$(gh issue list --milestone "$ms" --state open --limit "$LIMIT" \
          --json number,title,createdAt,updatedAt,labels,url \
          --jq 'sort_by(.number) | .[] | {number, title, createdAt, updatedAt, url, labels: [.labels[].name]}' 2>&1)" \
    || fail "gh issue list failed for milestone '$ms': $out"
  if [[ -z "${out//[[:space:]]/}" ]]; then
    fail "milestone '$ms' has no OPEN issues — nothing to seed a marathon with. Either the milestone
  is empty or no milestone by that title exists (gh returns an empty list for both). Exit 4, not 0:
  an empty candidate list must not read as a successful selection." 4
  fi
  printf '%s\n' "$out"
}

# ── rollup ──────────────────────────────────────────────────────────────────────────────────────
# landed    a trunk commit's CONVENTIONAL SCOPE claims the issue: `type(GH-N…):` or a leading `GH-N`.
# mentioned the issue appears somewhere on trunk, but no commit claims to implement it. This is the
#           bucket that needs eyes — #319/#320 were really fixed, inside a marathon commit whose
#           subject claims no issue, so a flat landed/not-landed binary would report them as a clean
#           "not done" and be believed.
# absent    no trunk reference at all.
#
# A bare `#N` is NOT evidence of landing: in a subject it is the squash-merge PR number, a different
# namespace, so accepting it would land issue 326 off PR #326.
cmd_rollup() {
  local ms; ms="$(resolve_milestone)" || exit $?
  require_gh
  local trunk; trunk="$(trunk_ref)"
  [[ -n "$trunk" ]] || fail "could not derive a trunk ref (no origin/HEAD and no current branch)"
  git -C "$ROOT" rev-parse --verify "${trunk}^{commit}" >/dev/null 2>&1 \
    || fail "derived trunk ref '$trunk' does not resolve to a commit"
  log "milestone: $ms   ·   trunk (derived): $trunk"

  local issues
  issues="$(gh issue list --milestone "$ms" --state all --limit "$LIMIT" \
             --json number,title,state,url --jq 'sort_by(.number)' 2>&1)" \
    || fail "gh issue list failed for milestone '$ms': $issues"
  # Bail BEFORE rendering. The first cut printed "NoSuchMilestone: 0/0 landed on origin/main" and
  # only then exited 4 — a report that reads like a fact about a milestone that may not even exist.
  # gh returns an empty list for an unknown milestone rather than erroring, so the two cases are
  # indistinguishable here and the message says so instead of guessing.
  if [[ "$(printf '%s' "$issues" | tr -d '[:space:]')" == "[]" || -z "${issues//[[:space:]]/}" ]]; then
    fail "milestone '$ms' contains no issues — nothing to roll up. Either the milestone is empty or
  no milestone by that title exists (gh returns an empty list for both). Exit 4, not 0: an empty
  rollup must not read as a successful one." 4
  fi

  local subjects bodies
  subjects="$(git -C "$ROOT" log "$trunk" --format='%h%x1f%s' 2>/dev/null)"
  bodies="$(git -C "$ROOT" log "$trunk" --format='%h%x1f%s%x1f%b%x1e' 2>/dev/null)"

  # ISSUES goes through the ENVIRONMENT, not stdin: the heredoc below already owns stdin. Feeding
  # both would put the JSON in front of the program text and python would die on it — the exact
  # SC2259 collision that silently broke the GH-284 P2 run log for a release (#322).
  MS="$ms" TRUNK="$trunk" SUBJECTS="$subjects" BODIES="$bodies" AS_JSON="$AS_JSON" ISSUES="$issues" \
    python3 - <<'PYEOF'
import json
import os
import re
import sys

issues = json.loads(os.environ.get("ISSUES") or "[]")
ms, trunk = os.environ["MS"], os.environ["TRUNK"]
as_json = os.environ.get("AS_JSON") == "1"

subjects = [ln.split("\x1f", 1) for ln in os.environ["SUBJECTS"].splitlines() if "\x1f" in ln]
records = [r for r in os.environ["BODIES"].split("\x1e") if r.strip()]

def claims(subject, n):
    # `type(GH-N):`, `type(GH-N P3):`, `feat(GH-N)!:` — the conventional scope, which is a CLAIM to
    # implement the issue — or a leading bare `GH-N`.
    return re.match(rf'^[A-Za-z]+\(GH-0*{n}(?:[^0-9)][^)]*)?\)!?:', subject) is not None \
        or re.match(rf'^GH-0*{n}(?:[^0-9]|$)', subject) is not None

def mentions(text, n):
    return re.search(rf'GH-0*{n}(?:[^0-9]|$)', text) is not None

# GH-332: a commit claiming an issue answers "has anyone worked on this?", NOT "is this finished?".
# Quicksilver reported `1/1 landed` off #308 — an OPEN multi-phase epic — because its only claiming
# commit was `GH-308: re-scope Phase 0/1 …`, i.e. planning, not delivery. The issue's CLOSED/OPEN
# state is the human's own signal that it is done, and this script was already fetching it and
# throwing it away. Landing now needs BOTH: a commit that claims the issue, and a closed issue.
#
# Commit TYPE is deliberately NOT filtered (the open question in #332). Requiring fix/feat and
# rejecting docs/chore would add false negatives for genuinely doc-only issues, and it is the weaker
# signal of the two — a human closing the issue outranks a commit-message prefix. The type stays
# visible either way, because the evidence line prints the whole subject.
rows, counts = [], {"landed": 0, "claimed-but-open": 0, "mentioned": 0, "absent": 0}
for issue in issues:
    n = issue["number"]
    closed = str(issue.get("state", "")).upper() == "CLOSED"
    hit = next((f'{h} {s}' for h, s in subjects if claims(s, n)), "")
    if hit and closed:
        state = "landed"
    elif hit:
        state = "claimed-but-open"
    elif any(mentions(r, n) for r in records):
        state = "mentioned"
    else:
        state = "absent"
    counts[state] += 1
    rows.append({"number": n, "title": issue["title"], "issue_state": issue["state"],
                 "landed_state": state, "evidence": hit, "url": issue["url"]})

total = len(rows)
if as_json:
    print(json.dumps({"milestone": ms, "trunk": trunk, "total": total,
                      "counts": counts, "issues": rows}, indent=2))
else:
    label = {"landed": "LANDED   ", "claimed-but-open": "IN FLIGHT",
             "mentioned": "MENTIONED", "absent": "ABSENT   "}
    for r in rows:
        print(f'  {label[r["landed_state"]]}  #{r["number"]:<5} {r["title"][:68]}')
        if r["evidence"]:
            print(f'                 └─ {r["evidence"][:88]}')
    print()
    print(f'{ms}: {counts["landed"]}/{total} landed on {trunk}')
    if counts["claimed-but-open"]:
        # Reported separately and NOT counted as landed. This is #332's whole point: a commit
        # claiming an open issue is work in progress, and rolling it into "landed" is how a release
        # that has barely started reports as finished.
        print(f'  {counts["claimed-but-open"]} claimed by a commit but still OPEN — an epic '
              f'mid-flight, or nobody closed it')
    if counts["mentioned"]:
        # Named explicitly. This bucket is the whole reason the report is not a binary: a commit
        # touched the issue without claiming it, which no count of "landed" can express.
        print(f'  {counts["mentioned"]} mentioned on trunk but claimed by no commit — these need '
              f'eyes, not a tally')
    if counts["absent"]:
        print(f'  {counts["absent"]} with no trunk reference at all')

raise SystemExit(0)
PYEOF
  return $?
}

case "$VERB" in
  seed)   cmd_seed ;;
  rollup) cmd_rollup ;;
esac
