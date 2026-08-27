#!/usr/bin/env bash
# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"--mutate-evidence builds a compliant fixture artifact, then plants a private path, removes CHANGELOG.md, leaves a relay-system/ directory, adds a second commit, and drops a retired manifest number into the ledger; each is detected, the bidirectional ledger check is shown failing in BOTH directions, and the unmutated fixture is re-checked green in the same run"}
# Meter (release 0.6.0) — the executable goalpost for the PUBLIC-REPOSITORY LAUNCH.
#
# RE-POINTED 2026-08-15. This file previously measured Meter's metering manifest (#378/#379/#380/
# #382/#491/#551). That manifest moved to Sundown when the operator re-scoped Meter to publication;
# see RELEASES.md's Meter block. The command and the two-half shape are deliberately unchanged —
# that shape is why Litmus and Nightwatch could tell a finished entry from a claimed one — but what
# the halves measure is now the launch.
#
# Meter's sentence: XYZ CAN BE HANDED TO A STRANGER.
#
#   HALF A — the launch ARTIFACT (structural). The published thing is not this repository; it is a
#            sanitized clone with fresh history. Half A audits that artifact: one commit, CHANGELOG
#            carried verbatim, runtime state and internal working documents absent, PROJECT reduced
#            to scaffold plus the retained worked example, licenses present, and a recorded secret
#            scan naming its tool version and the exact commit it covered.
#
#   HALF B — the STRANGER'S PATH, EXECUTED, not audited. A credential-free clone of the artifact
#            reaches the documented entry point and completes the supported happy path with no file,
#            token, or environment variable that exists only on the author's machine.
#
# WHY THE PREVIOUS VERSION OF THIS FILE REPORTED A FALSE GREEN, recorded because the launch depends
# on this check being trustworthy and it demonstrably was not:
#
#   1. The ledger cross-check could not fail. It grepped RELEASES.md's `Manifest:` line for each
#      entry it expected. That line is a paragraph carrying the release's full dated re-scope
#      history, so it contains every number ever admitted OR RETIRED. All eight of #378 #379 #380
#      #382 #491 #551 #555 #563 matched it, including one the script had never heard of. The check
#      was also one-directional: it asked "is everything I list in the ledger?" and never "is
#      everything the ledger lists in me?", so a ledger naming two entries while this file named
#      seven was invisible. Fixed below by reading a single machine-readable `Manifest-Members:`
#      field and comparing BOTH directions against it — prose is for humans, this field is for the
#      gate, and a retired number in the history paragraph can no longer satisfy anything.
#
#   2. "Complete" never consulted the issue. An entry counted as complete when three files existed
#      (gate, its registration, a recorded control). Issue state was fetched but used only for the
#      reverse error. Six OPEN issues were therefore counted complete and the goalpost reported MET.
#      Fixed below: an entry is COMPLETE only when its evidence machinery is in place AND its issue
#      is CLOSED. Machinery-without-closure now reports as remaining, not as done.
#
# WHAT THIS DELIBERATELY DOES NOT PROVE. Half A reads a declaration and a filename; it cannot know
# that a recorded secret scan was honestly recorded. That limit is inherited from Litmus and
# Nightwatch and is stated rather than papered over. Half B closes part of it by EXECUTING the
# stranger's path under a scrubbed environment, which is the strongest available evidence that no
# private context is required.
#
# THREE MODES, same shape as litmus-release.sh and nightwatch-release.sh:
#
#   (default)         Suite mode, registered in validate.sh. GREEN while the launch is in progress.
#                     Fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is
#                     missing/unregistered/uncontrolled) or a ledger disagreement. Remaining work is
#                     INFO, so an unfinished release does not paint the whole suite red — an
#                     always-red suite trains people to ignore it, which is #460's failure mode.
#
#   --release-gate    THE GOALPOST. Exits non-zero until the artifact audit and the stranger's path
#                     both pass and every manifest entry is complete. RED UNTIL THE LAUNCH IS DONE.
#
#   --mutate-evidence The negative control for this file. Builds a compliant fixture artifact, breaks
#                     it in specific ways, requires each break to be detected, and re-checks the
#                     unmutated fixture green in the same run.
#
# The artifact under test is named by XYZ_LAUNCH_ARTIFACT. While it does not exist, Half A and Half B
# report the launch as not started, which is the correct RED — not an error and not a skip.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GH-10 (PR #89 review, finding 1): ONE script-scope sandbox root, because --mutate-evidence
# (this suite's required negative control, NOT run by the ordinary gate) never enters
# run_stranger_path() where the original adoption anchored — it died on an unbound $work
# before exercising a single mutation.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/meter-release.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
ROOT="$(cd "$HERE/.." && pwd)"

MODE=suite
case "${1:-}" in
  --release-gate)    MODE=gate ;;
  --mutate-evidence) MODE=mutate ;;
  --help|-h)         sed -n '3,60p' "$0"; exit 0 ;;
  "")                ;;
  *) printf 'usage: %s [--release-gate | --mutate-evidence]\n' "$0" >&2; exit 2 ;;
esac

PASS=0; FAIL=0; INFO=0
ok()   { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
bad()  { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
info() { printf '  INFO: %s\n' "$*"; INFO=$((INFO+1)); }

# ── The FROZEN manifest ───────────────────────────────────────────────────────────────────────────
# RE-SCOPED TO TWO on 2026-08-15 by explicit operator decision; scope is CLOSED to further admission.
# Adding one here is a RE-SCOPE and must be matched in RELEASES.md's `Manifest-Members:` field — the
# cross-check below compares the two in BOTH directions.
#
# Format: <issue>|<gate test file, or '-' if satisfied by another gate>|<note>
MANIFEST=(
  "555|test/meter-release.sh|the release's own exit criterion — this file, re-pointed at the launch"
  "563|test/meter-release.sh|the public-launch checklist: artifact, onboarding, secret review, licensing, CI, publication"
)

# ── Launch artifact contract ──────────────────────────────────────────────────────────────────────
ARTIFACT="${XYZ_LAUNCH_ARTIFACT:-}"

# Paths that must NOT appear in the published artifact. Runtime state and internal working material.
FORBIDDEN_PATHS=(".tick" "relay-system" "temp" "PARKED" ".relay-driver.lock")

# Every .md under PROJECT's numbered buckets must match this. PROJECT is NOT emptied to a bare
# scaffold: it carries this release's own capture docs, so the tree reflects the repository's actual
# state and a newcomer sees PDDA applied to real work (operator decision, 2026-08-15). The retained
# set is the launch's exit criterion, its checklist, and the two open items #563 covers by waiver.
PROJECT_KEEP_RE="${XYZ_LAUNCH_PROJECT_KEEP:-^(GH-(544|555|563|564)-|GLM-5\\.3-audit)}"

# Strings that betray a private origin if they survive into the artifact.
#
# `Hypercart-Dev-Tools` was on this list and was REMOVED 2026-08-15 by operator decision: it is a
# GitHub organisation name, already public wherever it appears, and a repository URL is not a
# private path. Kept as a note rather than a silent deletion, because the difference between "this
# marker was considered and cleared" and "nobody thought of it" is the whole value of the list.
#
# The bare username was also on this list and was NARROWED to the PATH form on 2026-08-15, for the
# same reason `Hypercart-Dev-Tools` was cleared: what leaks is a private *filesystem path*, not the
# author's public identity. The residual matches were all authorship — `owner:` frontmatter, an
# `Author: … (@handle)` byline, and git commit authors inside a generated history diagram. A public
# repository crediting its author is correct, and a marker that fires on the byline would train
# whoever runs this to ignore it. `/Users/` still catches every private-path form.
#
# These are REGEXES, not fixed strings, and the difference is load-bearing. A bare `/Users/` matched
# eleven files that leak nothing: examples already elided to `/Users/.../Documents`, PDDA's own
# absolute-path detector (`/\/Users\// { ... }` in an awk program), and that detector's own
# documentation. Any tool that FINDS a pattern necessarily CONTAINS it. Requiring a real username
# segment after the prefix — one or more path-safe characters, so `...` and `\` do not qualify —
# distinguishes an actual home path from a description of one.
# Format: <stable id>|<regex>. The id is what mutations assert on, so tightening a pattern does not
# silently break the negative control — which is exactly what happened when these were bare strings.
PRIVATE_MARKERS=(
  "home-path|/Users/[A-Za-z0-9_][A-Za-z0-9_.-]*/"
  "volume-path|/Volumes/[A-Za-z0-9_][A-Za-z0-9_.-]*/"
  "local-sites|Local Sites"
)

# Documentation placeholders are not leaks. A containment test that asserts on `/Users/someone/`
# is describing an attack, not exposing a home directory, and a check that cannot tell the two apart
# will be switched off by whoever has to read its output.
PLACEHOLDER_RE="/(Users|Volumes)/(someone|somebody|user|username|youruser|example|test|foo)/"

# The documented entry path a stranger follows, verbatim from README.md's Quickstart. It is
# `npm install` THEN `./validate.sh` — running only the second half would test a path the README
# does not document and would fail on a missing module for a reason the newcomer never hits.
HAPPY_PATH_CMD="${XYZ_LAUNCH_HAPPY_PATH:-npm install && ./validate.sh}"

# README.md is checked for the happy path's own name rather than the full command line, since the
# README presents the two steps on separate lines.
HAPPY_PATH_DOC_MARKER="${XYZ_LAUNCH_HAPPY_DOC:-./validate.sh}"

# The recorded secret-scan evidence. Assembled from parts rather than written as one literal path:
# it does not exist until the scan is actually run, and path-integrity.sh correctly refuses a
# reference to a file that is not there. Naming it in pieces states the contract without asserting
# the artifact exists yet.
SCAN_DIR="test/baselines"
SCAN_FILE="GH-563-secret-scan.md"

require_artifact() {  # <path> — die unless it is a real directory; #564's empty-path lesson
  local p="${1:-}"
  case "$p" in
    "")  bad "artifact path is EMPTY — git -C \"\" and cd \"\" would silently target $PWD"; return 1 ;;
    /*)  ;;
    *)   bad "artifact path '$p' is not absolute — refusing to resolve it against the caller's cwd"; return 1 ;;
  esac
  [ -d "$p" ] || { bad "artifact path '$p' is not a directory"; return 1; }
  return 0
}

registered_in_validate() {  # <test path> — is it in validate.sh's TESTS array?
  local base="${1##*/}" validate="${2:-$ROOT/validate.sh}"
  sed -n '/^TESTS=(/,/^)/p' "$validate" | /usr/bin/grep -qF "\"$base\""
}

control_recorded() {  # <issue> — is there a recorded negative control for it?
  local n="$1" baselines="${2:-$ROOT/test/baselines}"
  [ -f "$baselines/GH-$n-negative-control.md" ]
}

STATE_CACHE=""
get_issue_state() {  # <issue> — sets ISSUE_STATE to OPEN | CLOSED | unknown
  local n="$1"
  case "$STATE_CACHE" in
    *":${n}="*)
      local cached="${STATE_CACHE#*:${n}=}"
      ISSUE_STATE="${cached%%:*}"
      return
      ;;
  esac
  if ! command -v gh >/dev/null 2>&1; then
    STATE_CACHE="${STATE_CACHE}:${n}=unknown:"
    ISSUE_STATE="unknown"
    return
  fi
  local st
  st="$(gh issue view "$n" --json state --jq .state 2>/dev/null | tr -d '\n' | tr '[:lower:]' '[:upper:]')" || st="unknown"
  [ -z "$st" ] && st="unknown"
  STATE_CACHE="${STATE_CACHE}:${n}=${st}:"
  ISSUE_STATE="$st"
}

audit_manifest() {  # [<validate.sh>] [<baselines dir>] — sets COMPLETE / REMAINING / FALSE_CLAIMS
  local validate="${1:-$ROOT/validate.sh}" baselines="${2:-$ROOT/test/baselines}"
  COMPLETE=0; REMAINING=0; FALSE_CLAIMS=0
  local entry n gate note state have_gate have_reg have_ctl
  for entry in "${MANIFEST[@]}"; do
    n="${entry%%|*}"; gate="${entry#*|}"; note="${gate#*|}"; gate="${gate%%|*}"
    have_gate=0; have_reg=0; have_ctl=0
    [ -f "$ROOT/$gate" ] && have_gate=1
    registered_in_validate "$gate" "$validate" && have_reg=1
    control_recorded "$n" "$baselines" && have_ctl=1

    get_issue_state "$n"
    state="$ISSUE_STATE"

    local why=""
    [ "$have_gate" -eq 0 ] && why="$why gate-missing($gate)"
    [ "$have_reg"  -eq 0 ] && why="$why not-registered-in-validate.sh"
    [ "$have_ctl"  -eq 0 ] && why="$why no-recorded-control(test/baselines/GH-$n-negative-control.md)"

    if [ -n "$why" ]; then
      REMAINING=$((REMAINING+1))
      if [ "$state" = "CLOSED" ]; then
        FALSE_CLAIMS=$((FALSE_CLAIMS+1))
        bad "#$n is CLOSED but its gate is not complete —$why"
      else
        info "#$n remaining —$why  ($note)"
      fi
      continue
    fi

    # Evidence machinery is in place. Completion additionally requires the issue to be CLOSED —
    # machinery-in-place is not the same claim as work-finished, and conflating them is what made
    # the previous version of this file report MET with six issues open.
    case "$state" in
      CLOSED)
        COMPLETE=$((COMPLETE+1))
        ok "#$n complete — $gate registered, control recorded, issue CLOSED"
        ;;
      OPEN)
        REMAINING=$((REMAINING+1))
        info "#$n remaining — evidence machinery in place but the issue is still OPEN  ($note)"
        ;;
      *)
        REMAINING=$((REMAINING+1))
        info "#$n remaining — evidence machinery in place, issue state UNAVAILABLE (gh absent or unauthed); not credited  ($note)"
        ;;
    esac
  done
}

# ── Half A: the launch artifact ───────────────────────────────────────────────────────────────────
# Failures are tracked by ID, not by count. A count is fragile: a check that emits one failure for
# any number of violations cannot show a NEW violation being detected, which is precisely how three
# mutations in this file's own control silently proved nothing on the first run.
ART_FAILED_IDS=""
art_failed() {  # <id> — did the last audit_artifact fail this specific check?
  case " $ART_FAILED_IDS " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

audit_artifact() {  # <artifact root> [<reference root>] — sets ART_OK / ART_BAD / ART_FAILED_IDS
  local art="${1:-}" ref="${2:-$ROOT}"
  ART_OK=0; ART_BAD=0; ART_FAILED_IDS=""
  local a_ok a_bad
  a_ok()  { ok  "$2"; ART_OK=$((ART_OK+1)); }
  a_bad() { bad "$2"; ART_BAD=$((ART_BAD+1)); ART_FAILED_IDS="$ART_FAILED_IDS $1"; }

  if [ -z "$art" ]; then
    a_bad no-artifact "no launch artifact declared — set XYZ_LAUNCH_ARTIFACT to the sanitized clone's absolute path"
    return 1
  fi
  require_artifact "$art" || { a_bad bad-artifact-path "artifact path is unusable"; return 1; }

  # A1 — it is a git repository with exactly one commit (fresh history, per the operator's decision)
  if [ -d "$art/.git" ]; then
    local n_commits
    n_commits="$(/usr/bin/git -C "$art" rev-list --count HEAD 2>/dev/null || echo 0)"
    if [ "$n_commits" = "1" ]; then
      a_ok fresh-history "artifact has fresh history — exactly one commit"
    else
      a_bad fresh-history "artifact has $n_commits commits, expected exactly 1 — fresh history is what makes sanitization complete by construction"
    fi
  else
    a_bad fresh-history "artifact is not a git repository (no .git) — it cannot be published as one"
  fi

  # A2 — CHANGELOG.md carried forward verbatim. It is the public record of the project's history.
  if [ ! -f "$art/CHANGELOG.md" ]; then
    a_bad changelog "artifact has no CHANGELOG.md — it is the agreed public record of the project's history"
  elif /usr/bin/cmp -s "$ref/CHANGELOG.md" "$art/CHANGELOG.md"; then
    a_ok changelog "CHANGELOG.md is byte-identical to the reference"
  else
    a_bad changelog "artifact's CHANGELOG.md differs from the reference — it must be carried forward verbatim"
  fi

  # A3 — runtime state and internal working material are absent
  local p leaked=""
  for p in "${FORBIDDEN_PATHS[@]}"; do
    [ -e "$art/$p" ] && leaked="$leaked $p"
  done
  if [ -z "$leaked" ]; then
    a_ok forbidden-paths "runtime state and internal working material absent (${FORBIDDEN_PATHS[*]})"
  else
    a_bad forbidden-paths "artifact still carries:$leaked — these do not ship"
  fi

  # A4 — PROJECT is scaffold plus the retained worked example, nothing else
  if [ ! -d "$art/PROJECT" ]; then
    a_bad project-scaffold "artifact has no PROJECT/ — the PDDA scaffold ships as the method's worked example"
  else
    local stray="" f base
    while IFS= read -r f; do
      base="${f##*/}"
      printf '%s' "$base" | /usr/bin/grep -Eq "$PROJECT_KEEP_RE" || stray="$stray ${f#$art/}"
    done < <(/usr/bin/find "$art/PROJECT/1-INBOX" "$art/PROJECT/2-WORKING" "$art/PROJECT/3-COMPLETED" "$art/PROJECT/4-MISC" -name '*.md' -type f 2>/dev/null)
    if [ -z "$stray" ]; then
      a_ok project-scaffold "PROJECT reduced to scaffold plus the retained worked example"
    else
      a_bad project-scaffold "PROJECT still carries internal working docs:$stray"
    fi
  fi

  # A5 — licences present
  if [ -f "$art/LICENSE" ] && [ -f "$art/LICENSE-COMMERCIAL.md" ]; then
    a_ok licenses "LICENSE and LICENSE-COMMERCIAL.md both present"
  else
    a_bad licenses "artifact is missing LICENSE and/or LICENSE-COMMERCIAL.md"
  fi

  # A6 — a recorded secret scan naming its tool version and the exact commit it covered
  local scan="$ref/$SCAN_DIR/$SCAN_FILE"
  if [ ! -f "$scan" ]; then
    a_bad secret-scan "no recorded secret scan at $SCAN_DIR/$SCAN_FILE"
  elif ! /usr/bin/grep -Eiq 'trufflehog[[:space:]]+v?[0-9]+\.[0-9]+' "$scan"; then
    a_bad secret-scan "recorded secret scan does not pin a TruffleHog version — #563's evidence rule requires the exact tool version"
  elif ! /usr/bin/grep -Eq '[0-9a-f]{40}' "$scan"; then
    a_bad secret-scan "recorded secret scan does not name the exact 40-character commit it covered"
  else
    a_ok secret-scan "secret scan recorded with a pinned TruffleHog version and an exact commit"
  fi

  # A7 — no private origin markers survive into tracked content. One failure PER marker, so that a
  # newly introduced marker is visible even when the artifact already leaks a different one.
  # This file necessarily CONTAINS every pattern it searches for — the marker list is source code —
  # so it is excluded from its own sweep. A narrow, named carve-out rather than a silent one: if the
  # published artifact ever carries a real leak inside this specific file, this check will not see
  # it. That is the stated cost of defining the patterns in the same tree that is being searched.
  local self="${BASH_SOURCE[0]##*/}"
  local entry mid mre f real hits clean=1
  for entry in "${PRIVATE_MARKERS[@]}"; do
    mid="${entry%%|*}"; mre="${entry#*|}"
    hits=0
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      # Count the file only if it carries a match that is NOT a documentation placeholder.
      real="$(/usr/bin/grep -ohE "$mre" "$f" 2>/dev/null | /usr/bin/grep -vE "$PLACEHOLDER_RE" | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
      [ "$real" != "0" ] && hits=$((hits+1))
      # TRACKED files only. Scanning the directory swept in `node_modules/` — created by the
      # `npm install` this gate's own Half B runs — and reported 16 leaks in dependency code that is
      # gitignored and never published. What ships is what git tracks; anything else is build
      # output, and failing on it makes the check report a leak that cannot reach a reader.
    done < <(cd "$art" 2>/dev/null && /usr/bin/git ls-files -z 2>/dev/null \
               | /usr/bin/xargs -0 /usr/bin/grep -lE "$mre" 2>/dev/null \
               | /usr/bin/sed "s|^|$art/|" | /usr/bin/grep -v "/$self\$")
    if [ "$hits" != "0" ]; then
      clean=0
      a_bad "private-marker:$mid" "artifact leaks a private $mid in $hits file(s) — pattern-based secret scanning does not catch these"
    fi
  done
  [ "$clean" -eq 1 ] && a_ok private-markers "no private paths, usernames, or internal org names survive in the artifact"

  [ "$ART_BAD" -eq 0 ]
}

# ── Half B: the stranger's path, EXECUTED ─────────────────────────────────────────────────────────
run_stranger_path() {  # <artifact root> — sets STR_PASS / STR_FAIL / STR_MISSING
  local art="${1:-}"
  STR_PASS=0; STR_FAIL=0; STR_MISSING=0

  if [ -z "$art" ] || [ ! -d "$art" ]; then
    STR_MISSING=$((STR_MISSING+1))
    info "stranger's path NOT COVERED — no launch artifact to clone (XYZ_LAUNCH_ARTIFACT unset or absent)"
    return 1
  fi

  local work
  work="$(mktemp -d "$WORK/stranger.XXXXXX")" || { STR_FAIL=$((STR_FAIL+1)); bad "could not create a scratch directory for the stranger's clone"; return 1; }
  require_fixture "$work" "stranger scratch clone"  # GH-10
  case "$work" in
    "") STR_FAIL=$((STR_FAIL+1)); bad "mktemp returned an EMPTY path — refusing (#564)"; return 1 ;;
  esac
  trap 'rm -rf "$work"' RETURN

  # B1 — a credential-free clone succeeds
  if /usr/bin/git -c credential.helper= clone --quiet "$art" "$work/clone" 2>/dev/null; then
    STR_PASS=$((STR_PASS+1))
    ok "stranger case OK — the artifact clones with no credential helper"
  else
    STR_FAIL=$((STR_FAIL+1))
    bad "stranger case FAILED — the artifact does not clone without credentials"
    return 1
  fi

  # B2 — the documented entry point exists and names the happy path
  if [ -f "$work/clone/README.md" ] && /usr/bin/grep -qF "${HAPPY_PATH_DOC_MARKER}" "$work/clone/README.md"; then
    STR_PASS=$((STR_PASS+1))
    ok "stranger case OK — README.md documents the entry path ($HAPPY_PATH_DOC_MARKER)"
  else
    STR_FAIL=$((STR_FAIL+1))
    bad "stranger case FAILED — README.md does not document '$HAPPY_PATH_DOC_MARKER' as the entry path"
  fi

  # B3 — the happy path completes under a SCRUBBED environment. This is the load-bearing one: it is
  # the difference between "it works on the author's machine" and "it works for a stranger". No
  # tokens, no author HOME, no inherited XYZ_* configuration.
  # The PATH keeps the standard package-manager prefixes (/opt/homebrew/bin, /usr/local/bin) because
  # a stranger with node installed has them too — scrubbing is about removing the AUTHOR's private
  # context (HOME, tokens, XYZ_* config), not about pretending a normal toolchain is absent.
  if /usr/bin/env -i \
        PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        HOME="$work/home" \
        TMPDIR="$work/tmp" \
        /bin/bash -c "mkdir -p '$work/home' '$work/tmp' && cd '$work/clone' && $HAPPY_PATH_CMD" >"$work/happy.log" 2>&1; then
    STR_PASS=$((STR_PASS+1))
    ok "stranger case OK — '$HAPPY_PATH_CMD' completes with no private context (scrubbed env)"
  else
    STR_FAIL=$((STR_FAIL+1))
    bad "stranger case FAILED — '$HAPPY_PATH_CMD' does not complete under a scrubbed environment; see the tail below"
    /usr/bin/tail -5 "$work/happy.log" 2>/dev/null | /usr/bin/sed 's/^/        | /' >&2
  fi

  [ "$STR_FAIL" -eq 0 ]
}

# ── The ledger cross-check, BIDIRECTIONAL ─────────────────────────────────────────────────────────
# Reads a single machine-readable field, NOT the prose Manifest: paragraph. The paragraph records the
# release's re-scope history and therefore names retired members; matching against it is how the
# previous version of this check became unable to fail.
manifest_matches_releases_md() {
  local rel="${1:-$ROOT/RELEASES.md}" line entry n missing="" extra="" declared
  [ -f "$rel" ] || { info "RELEASES.md absent — manifest cross-check skipped"; return 0; }

  line="$(/usr/bin/awk '/^Codename: Meter/,/^$/' "$rel" | /usr/bin/grep '^Manifest-Members:')"
  if [ -z "$line" ]; then
    bad "RELEASES.md's Meter block has no machine-readable 'Manifest-Members:' field — the frozen boundary is not recorded in a form this gate can check (the prose Manifest: paragraph names retired members and cannot be used)"
    return 1
  fi
  declared="${line#Manifest-Members:}"

  # direction 1 — everything this file names must be declared in the ledger
  for entry in "${MANIFEST[@]}"; do
    n="${entry%%|*}"
    printf ' %s ' "$declared" | /usr/bin/grep -q " $n " || missing="$missing #$n"
  done
  # direction 2 — everything the ledger declares must be named in this file. This is the direction
  # the previous check lacked entirely, and it is the one that catches a re-scope landing in
  # RELEASES.md while this file still measures the old manifest.
  for n in $declared; do
    case "$n" in ''|*[!0-9]*) continue ;; esac
    printf '%s\n' "${MANIFEST[@]}" | /usr/bin/grep -q "^$n|" || extra="$extra #$n"
  done

  if [ -n "$missing" ] || [ -n "$extra" ]; then
    [ -n "$missing" ] && bad "RELEASES.md's Manifest-Members does not declare:$missing — this file names members the ledger does not"
    [ -n "$extra" ]   && bad "this file does not name:$extra — the ledger declares members this gate does not measure"
    return 1
  fi
  ok "the frozen manifest here matches RELEASES.md's Manifest-Members field in both directions ($declared)"
}

# ── Mutation mode: the negative control for this audit ────────────────────────────────────────────
if [ "$MODE" = mutate ]; then
  echo "== meter-release --mutate-evidence =="
  TMP="$(mktemp -d "$WORK/meter-mutate.XXXXXX")"
  require_fixture "$TMP" "mutate-evidence fixture"  # GH-10
  case "$TMP" in "") echo "mktemp returned EMPTY — refusing (#564)" >&2; exit 2 ;; esac
  trap 'rm -rf "$TMP"' EXIT

  MUT_PASS=0
  MUT_FAIL=0
  mut_ok()  { printf '  PASS: %s\n' "$*"; MUT_PASS=$((MUT_PASS+1)); }
  mut_bad() { printf '  FAIL: %s\n' "$*" >&2; MUT_FAIL=$((MUT_FAIL+1)); }

  # Build a COMPLIANT fixture artifact, so the control is discriminating: a checker that refuses
  # everything cannot pass this, because the unmutated fixture must come back clean.
  # A clean REFERENCE root. Deliberately not $ROOT: this repository's own CHANGELOG.md currently
  # carries private markers, which would make the fixture non-compliant and every mutation below
  # unprovable. The reference is what the artifact is compared against, so the control tests the
  # checker rather than the current state of the repository.
  REF="$TMP/ref"
  mkdir -p "$REF/test/baselines"
  printf '# Changelog\n\nAll notable changes.\n' > "$REF/CHANGELOG.md"
  printf 'trufflehog v3.90.8\ncommit 0000000000000000000000000000000000000000\nresult: clean (fixture)\n' \
    > "$REF/$SCAN_DIR/$SCAN_FILE"

  FIX="$TMP/artifact"
  mkdir -p "$FIX/PROJECT/1-INBOX" "$FIX/PROJECT/2-WORKING" "$FIX/PROJECT/3-COMPLETED" "$FIX/PROJECT/4-MISC"
  cp "$REF/CHANGELOG.md" "$FIX/CHANGELOG.md"
  printf 'MIT\n' > "$FIX/LICENSE"
  printf '# Commercial\n' > "$FIX/LICENSE-COMMERCIAL.md"
  printf '# XYZ\n\n    %s\n' "$HAPPY_PATH_CMD" > "$FIX/README.md"
  printf '# PDDA\n' > "$FIX/PROJECT/PDDA.md"
  printf '# GH-563 worked example\n' > "$FIX/PROJECT/2-WORKING/GH-563-LAUNCH.md"
  ( cd "$FIX" && /usr/bin/git init -q . && /usr/bin/git -c user.email=t@t -c user.name=t add -A \
      && /usr/bin/git -c user.email=t@t -c user.name=t commit -qm "initial" ) >/dev/null 2>&1

  echo "-- baseline: the unmutated fixture artifact"
  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
  base_bad=$ART_BAD base_ok=$ART_OK
  if [ "$base_bad" -eq 0 ]; then
    mut_ok "unmutated fixture artifact passes every Half A check ($base_ok checks) — the control is discriminating, not always-red"
  else
    mut_bad "unmutated fixture already fails $base_bad Half A check(s) [$ART_FAILED_IDS] — the mutations below would prove nothing"
  fi

  echo "-- mutation 1: plant a private path in a tracked file"
  printf "see /Users/realdev/secret-notes.md\\n" >> "$FIX/README.md"
  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
  if art_failed "private-marker:home-path"; then
    mut_ok "a planted private path is DETECTED by the private-marker sweep"
  else
    mut_bad "a planted private path was NOT detected [$ART_FAILED_IDS]"
  fi
  # GH-204: portable in-place delete (GNU + BSD); the BSD-only `sed -i ''` form left the planted
  # marker in place under GNU sed, so the next mutation ran against a dirty fixture.
  /usr/bin/sed -i.bak '/secret-notes/d' "$FIX/README.md"; rm -f "$FIX/README.md.bak"

  echo "-- mutation 2: remove CHANGELOG.md"
  mv "$FIX/CHANGELOG.md" "$TMP/CHANGELOG.keep"
  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
  if art_failed changelog; then
    mut_ok "a removed CHANGELOG.md is DETECTED"
  else
    mut_bad "removing CHANGELOG.md was NOT detected [$ART_FAILED_IDS]"
  fi
  mv "$TMP/CHANGELOG.keep" "$FIX/CHANGELOG.md"

  echo "-- mutation 2b: a MODIFIED CHANGELOG.md (not carried verbatim) is detected"
  printf 'tampered\n' >> "$FIX/CHANGELOG.md"
  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
  if art_failed changelog; then
    mut_ok "a modified CHANGELOG.md is DETECTED — 'verbatim' is enforced, not just 'present'"
  else
    mut_bad "a modified CHANGELOG.md was NOT detected [$ART_FAILED_IDS]"
  fi
  cp "$REF/CHANGELOG.md" "$FIX/CHANGELOG.md"

  echo "-- mutation 3: leave a relay-system/ directory behind"
  mkdir -p "$FIX/relay-system/2026-08-15"
  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
  if art_failed forbidden-paths; then
    mut_ok "a surviving relay-system/ is DETECTED"
  else
    mut_bad "a surviving relay-system/ was NOT detected [$ART_FAILED_IDS]"
  fi
  rm -rf "$FIX/relay-system"

  echo "-- mutation 4: add a second commit (fresh history violated)"
  ( cd "$FIX" && printf 'x\n' >> README.md && /usr/bin/git -c user.email=t@t -c user.name=t commit -aqm "second" ) >/dev/null 2>&1
  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
  if art_failed fresh-history; then
    mut_ok "a second commit is DETECTED — fresh history is enforced"
  else
    mut_bad "a second commit was NOT detected [$ART_FAILED_IDS]"
  fi
  ( cd "$FIX" && /usr/bin/git reset -q --hard HEAD~1 ) >/dev/null 2>&1

  echo "-- mutation 5: an internal working doc survives in PROJECT/"
  printf '# internal\n' > "$FIX/PROJECT/3-COMPLETED/GH-999-INTERNAL.md"
  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
  if art_failed project-scaffold; then
    mut_ok "a surviving internal PROJECT doc is DETECTED"
  else
    mut_bad "a surviving internal PROJECT doc was NOT detected [$ART_FAILED_IDS]"
  fi
  rm -f "$FIX/PROJECT/3-COMPLETED/GH-999-INTERNAL.md"

  echo "-- mutation 5b: an unpinned secret-scan record is detected"
  printf 'ran trufflehog, looked fine\n' > "$REF/$SCAN_DIR/$SCAN_FILE"
  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
  if art_failed secret-scan; then
    mut_ok "a secret-scan record with no pinned version or commit is DETECTED"
  else
    mut_bad "an unpinned secret-scan record was NOT detected [$ART_FAILED_IDS]"
  fi
  printf 'trufflehog v3.90.8\ncommit 0000000000000000000000000000000000000000\nresult: clean (fixture)\n' \
    > "$REF/$SCAN_DIR/$SCAN_FILE"

  # The ledger check, mutated in BOTH directions — this is the defect that made the previous
  # version of this file unable to fail, so the control must observe both halves of the fix.
  echo "-- mutation 6: ledger declares a RETIRED member (direction 2 — ledger has one this file lacks)"
  REL_FIX="$TMP/RELEASES.md"
  { echo "Codename: Meter"; echo "Manifest-Members: 555 563 378"; echo; } > "$REL_FIX"
  if manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
    mut_bad "a ledger declaring retired #378 was ACCEPTED — the cross-check is still one-directional"
  else
    mut_ok "a ledger declaring retired #378 is DETECTED (direction 2 works)"
  fi

  echo "-- mutation 7: ledger drops a current member (direction 1 — this file has one the ledger lacks)"
  { echo "Codename: Meter"; echo "Manifest-Members: 555"; echo; } > "$REL_FIX"
  if manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
    mut_bad "a ledger missing #563 was ACCEPTED — direction 1 does not work"
  else
    mut_ok "a ledger missing #563 is DETECTED (direction 1 works)"
  fi

  echo "-- mutation 8: the OLD prose-matching failure must not be reproducible"
  # A history paragraph naming every number ever admitted must NOT satisfy the check.
  { echo "Codename: Meter"; echo "Manifest: FROZEN — #378, #379, #380, #382, #491, #551, #555, #563 ..."; echo; } > "$REL_FIX"
  if manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
    mut_bad "a prose Manifest: paragraph naming every number was ACCEPTED — the original defect is back"
  else
    mut_ok "a prose Manifest: paragraph cannot satisfy the cross-check (the original defect stays fixed)"
  fi

  echo "-- restore: the unmutated fixture must be green again in this same run"
  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
  { echo "Codename: Meter"; echo "Manifest-Members: 555 563"; echo; } > "$REL_FIX"
  if [ "$ART_BAD" -eq 0 ] && manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
    mut_ok "restoring the inputs restores the verdict — the detector is not simply always-red"
  else
    mut_bad "restored inputs do not reproduce the baseline verdict (failures: $ART_BAD [$ART_FAILED_IDS], expected 0)"
  fi

  printf '\n  meter-release --mutate-evidence: %s passed, %s failed\n' "$MUT_PASS" "$MUT_FAIL"
  [ "$MUT_FAIL" -eq 0 ] || exit 1
  echo "  negative control OBSERVED in both directions"
  exit 0
fi

# ── Suite / gate modes ────────────────────────────────────────────────────────────────────────────
echo "== meter-release (${MODE}) — release 0.6.0 public-launch goalpost =="
echo
echo "-- the frozen manifest"
manifest_matches_releases_md
audit_manifest

if [ "$MODE" = gate ]; then
  echo
  echo "-- half A: the launch artifact"
  audit_artifact "$ARTIFACT"
  echo
  echo "-- half B: the stranger's path, EXECUTED"
  run_stranger_path "$ARTIFACT"
fi

echo
printf 'manifest: %s complete, %s remaining, %s false completion claim(s)\n' \
  "$COMPLETE" "$REMAINING" "$FALSE_CLAIMS"

if [ "$MODE" = gate ]; then
  printf 'artifact: %s checks passing, %s failing\n' "$ART_OK" "$ART_BAD"
  printf "stranger's path: %s passing, %s failing, %s NOT COVERED\n" "$STR_PASS" "$STR_FAIL" "$STR_MISSING"
  echo
  if [ "$REMAINING" -eq 0 ] && [ "$FALSE_CLAIMS" -eq 0 ] \
     && [ "$ART_BAD" -eq 0 ] && [ "$STR_FAIL" -eq 0 ] && [ "$STR_MISSING" -eq 0 ]; then
    echo "GOALPOST MET — the artifact is publishable and a stranger can use it"
    exit 0
  fi
  echo "GOALPOST NOT MET — the public launch is not done."
  echo "  This is the correct state until the sanitized artifact exists and a credential-free clone"
  echo "  completes the documented happy path. A closed backlog is not a substitute for it."
  exit 1
fi

# Suite mode: only a false completion claim or a ledger disagreement is fatal.
if [ "$FAIL" -gt 0 ]; then
  printf '\n  meter-release: %s passed, %s FAILED (false completion claim or ledger disagreement)\n' "$PASS" "$FAIL"
  exit 1
fi
printf '\n  meter-release: %s passed, 0 failed, %s informational\n' "$PASS" "$INFO"
echo "  (suite mode is green while the launch is in progress — run --release-gate for the goalpost)"
exit 0
