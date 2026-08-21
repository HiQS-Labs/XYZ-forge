#!/usr/bin/env bash
set -uo pipefail

FIXTURE_DIR=""
SESSION_FILE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    # `$2` under `set -u` is an unbound-variable abort on a bare `--fixture`, which surfaces as a
    # bash error and exit 1 rather than the interface SKILL.md publishes ("2 usage or a contract
    # violation"). Validate the operand before consuming it.
    --fixture)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "collect.sh: --fixture requires a directory operand" >&2; exit 2
      fi
      export FIXTURE_DIR="$2"; shift 2 ;;
    --session)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "collect.sh: --session requires a file operand" >&2; exit 2
      fi
      SESSION_FILE="$2"; shift 2 ;;
    *) echo "collect.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ -z "$SESSION_FILE" && -z "$FIXTURE_DIR" ]]; then
  SESSION_FILE="$REPO_ROOT/.standup-transcript.json"
fi

# `jq` is this collector's only external dependency beyond git and coreutils, and it is load-bearing:
# every candidate and the branch name are JSON-encoded through it, precisely so a path or ref
# containing a quote cannot produce invalid JSON at exit 0. Nothing else under skills/, utils/ or
# relay-automation/ uses jq, and the repo's own quickstart asks only for Node and git — so on a clone
# where it is absent the collector would die at the first `jq -n` with exit 127 and print NOTHING.
#
# That is the failure this whole design exists to prevent, one level up: the consumer reads stdin, and
# an empty stdin is indistinguishable from "the session is clean". Degrade LOUDLY instead — emit a
# well-formed document that triage.py can still consume, with every lens carrying D5 ("a lens cannot
# supply all six fields", the spec's degradation table), and exit non-zero so a caller that checks
# knows. Hand-written rather than built with jq for the obvious reason.
if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' '{"repo": {"branch": "unknown"},' \
    ' "lenses": {' \
    '   "1": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "2": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "3": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "4": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "5": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "6": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "7": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "8": {"status": "degraded", "degraded_id": "D5", "candidates": []}' \
    ' }' \
    '}'
  echo "collect.sh: jq is required and was not found on PATH — every lens degraded (D5)." >&2
  exit 3
fi

# Under --fixture every read must come from the fixture. Falling through to the live `git rev-parse`
# when `branch.txt` is absent let a lens-3 candidate take its key and its no-upstream close text from
# whatever branch the REVIEWER happened to be standing on — the fixture then asserted something about
# the machine rather than about the collector. Every other missing bounded input degrades; so does
# this one. BRANCH_KNOWN carries the verdict to lens 3, the only consumer.
BRANCH_KNOWN=1
if [[ -n "$FIXTURE_DIR" ]]; then
  if [[ -f "$FIXTURE_DIR/branch.txt" ]]; then
    branch=$(cat "$FIXTURE_DIR/branch.txt")
    # A present-but-EMPTY file is not a branch name. Without this the live read's own non-empty check
    # was applied to one path and not the other, and lens 3 emitted an `ok` candidate keyed `branch:`
    # whose no-upstream close read `inspect: branch  (push state unknown, no upstream)`.
    [[ -n "$branch" ]] || BRANCH_KNOWN=0
  else
    branch="unknown"; BRANCH_KNOWN=0
  fi
else
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || { branch="unknown"; BRANCH_KNOWN=0; }
  [[ -n "$branch" ]] || { branch="unknown"; BRANCH_KNOWN=0; }
fi

run_mock() {
  local id="$1"
  shift
  if [[ -n "$FIXTURE_DIR" ]]; then
    if [[ -f "$FIXTURE_DIR/$id.rc" ]]; then
      local rc=$(cat "$FIXTURE_DIR/$id.rc")
      [[ -f "$FIXTURE_DIR/$id.txt" ]] && cat "$FIXTURE_DIR/$id.txt"
      return $rc
    fi
    if [[ -f "$FIXTURE_DIR/$id.txt" ]]; then
      cat "$FIXTURE_DIR/$id.txt"
      return 0
    fi
    echo "Missing fixture: $id" >&2
    return 1
  fi
  "$@"
}

# Single-quote a value for safe use inside a shell command line. A `close` is never executed by this
# collector, but it is a recommendation the operator (or an agent) may run verbatim — so a path
# containing `$(...)`, a backtick or a quote must not become executable substitution when they do.
# Single quotes disable every expansion; the only character needing care is the single quote itself,
# closed and reopened around an escaped literal.
shq() { printf "'%s'" "${1//\'/\'\\\'\'}"; }

# Decode a `git status --porcelain -z` stream into `XY<TAB>flag<TAB>base64(path)` lines.
#
# ROUND 8 — this now reads the -z format, which is what should have happened in round 4. The reviewer
# recommended a machine-safe representation then and again now; I took the cheaper path twice, and
# rounds 4, 5 and 7 were each spent on a different bug in hand-parsing the TEXT format\'s C-quoting.
# That is the whole argument: git provides -z precisely so tools do not parse that grammar.
#
# What -z removes, permanently rather than case by case:
#   * NO C-QUOTING. Pathnames are raw bytes, so there is no escape grammar to implement, no octal
#     round-trip to get wrong, no core.quotePath dependence, and no unterminated-quote case.
#   * UNAMBIGUOUS RENAMES. A rename/copy is two NUL-terminated fields, destination first. The text
#     format joins them with " -> ", which is legal INSIDE a pathname — so `old -> part.md` split in
#     the wrong place, and no amount of care in a splitter fixes an ambiguous grammar.
#   * The XY field is read positionally, so an UNSTAGED rename (" R") is handled by the same code as
#     a staged one ("R "). Testing `xy[0]` alone silently missed the unstaged form entirely.
#
# The contract is unchanged and now much easier to hold: every entry is understood and emitted, or
# this exits non-zero and the lens degrades. There is no third outcome.
porcelain_rows() {
  python3 -c '
import base64, re, sys

UNRENDERABLE = re.compile(rb"[\x00-\x1f\x7f]")   # newline, CR, tab, and every other control byte
# Porcelain v1 status grammar, not two independently permissive characters. `?` and `!` occur ONLY
# as the doubled pairs `??` (untracked) and `!!` (ignored); a pair like `?M`, `M?` or `?!` is
# something git cannot emit, and accepting it let a fabricated live_state reach an ok candidate.
# Everything else is X=index, Y=worktree, each drawn from the code set, and never both blank.
# The code set INCLUDES `T` (type changed, e.g. a file replaced by a symlink). Leaving it out made a
# legitimate record degrade the lens -- a false D5 on valid input, which is the regression in the
# opposite direction and strictly worse than the over-acceptance the validator was added to stop.
CODES = b" MTADRCU"
def valid_status(xy):
    if xy in (b"??", b"!!"):
        return True
    if xy == b"  ":
        return False
    return xy[0:1] in [bytes([c]) for c in CODES] and xy[1:2] in [bytes([c]) for c in CODES]

data = sys.stdin.buffer.read()
# -z TERMINATES every entry with NUL; it does not separate them. A stream whose last entry has no
# terminator is TRUNCATED -- the read was cut short -- and a truncated bounded read is a failed one,
# not a shorter list of findings. Without this check the final partial entry was accepted whole.
if data and not data.endswith(b"\0"):
    sys.stderr.write("porcelain_rows: stream does not end with NUL (truncated read)\n")
    sys.exit(1)
fields = data.split(b"\0")
if fields and fields[-1] == b"":
    fields.pop()            # trailing NUL after the last entry

out = []
i = 0
while i < len(fields):
    entry = fields[i]; i += 1
    if entry == b"":
        sys.stderr.write("porcelain_rows: empty entry in stream\n")
        sys.exit(1)
    # Every entry is exactly XY<space>PATH. A whitespace-only or truncated record is NOT a clean
    # tree; it is input this parser does not understand, and understanding it is the whole job.
    if len(entry) < 4 or entry[2:3] != b" ":
        sys.stderr.write("porcelain_rows: malformed entry: %r\n" % entry)
        sys.exit(1)
    xy, path = entry[:2], entry[3:]
    if not valid_status(xy):
        sys.stderr.write("porcelain_rows: unrecognised status field %r\n" % xy)
        sys.exit(1)
    # A rename/copy carries its SOURCE as the next NUL-terminated field. Consume it: the destination
    # is what an operator acts on, and leaving the source in the stream would parse it as an entry.
    # Positional, so an unstaged " R" is handled identically to a staged "R ".
    if b"R" in xy or b"C" in xy:
        if i >= len(fields):
            sys.stderr.write("porcelain_rows: rename entry %r with no source field\n" % entry)
            sys.exit(1)
        # The source field is REQUIRED and cannot be empty. Consuming it without looking let
        # `R  dest\0\0` through as a confident candidate whose required source was absent.
        if fields[i] == b"":
            sys.stderr.write("porcelain_rows: rename entry %r with an empty source field\n" % entry)
            sys.exit(1)
        i += 1
    if not path:
        sys.stderr.write("porcelain_rows: entry carries a status but no pathname: %r\n" % entry)
        sys.exit(1)
    # A legal git pathname is a byte string, NOT necessarily valid UTF-8. Classifying on control
    # bytes alone let `name\xff` take the ordinary command path, where the raw byte reached
    # `jq --arg` in the key, the evidence and the CLOSE COMMAND -- producing a normalised or invalid
    # JSON string and a runnable command addressing a DIFFERENT pathname. That is the same dangerous-
    # addressing class the -z rewrite and the trailing-LF sentinel each removed, re-entering at the
    # byte-to-text crossing, which is where every one of these has appeared.
    # A name that cannot be rendered as text is unrenderable for the same reason a newline is: it
    # gets an escaped display and an inspect close, never a command built from it.
    try:
        path.decode("utf-8")
    except UnicodeDecodeError:
        flag = "unrenderable"
    else:
        flag = "unrenderable" if UNRENDERABLE.search(path) else "ok"
    out.append("%s\t%s\t%s\n" % (xy.decode("latin-1"), flag,
                                 base64.b64encode(path).decode("ascii")))
sys.stdout.write("".join(out))
'
}

# One-line display for a path that cannot be shown as it is. Control bytes become their escapes, so
# the item still names the file recognisably without ever emitting a physical newline.
# `backslashreplace`, NOT `replace`: the latter maps every undecodable byte to U+FFFD, so two
# different pathnames render identically — acceptable for a glyph, useless for naming a file the
# operator has to go and find. Escaped as \xNN, the display identifies exactly one path.
sanitize_path() {
  printf '%s' "$1" | python3 -c '
import sys
s = sys.stdin.buffer.read().decode("utf-8", "backslashreplace")
sys.stdout.write("".join(
    {"\n": "\\n", "\r": "\\r", "\t": "\\t"}.get(c, "\\x%02x" % ord(c)) if (ord(c) < 32 or ord(c) == 127) else c
    for c in s))
'
}

lens2_status="ok"
lens2_deg="null"
lens2_cands="[]"

# The -z stream is NUL-separated, and command substitution CANNOT carry a NUL — bash strips them
# silently, which would rejoin adjacent entries into one nonsense path. So the raw stream goes to a
# file and only the decoder's base64 output (NUL-free by construction) ever enters a variable.
LENS2_Z="$(mktemp "${TMPDIR:-/tmp}/standup-lens2.XXXXXX")"
trap 'rm -f "$LENS2_Z"' EXIT
set +e
run_mock "lens2" git status --porcelain -z >"$LENS2_Z" 2>/dev/null
rc2=$?
set -e
if [[ $rc2 -eq 0 ]]; then
  cands="[]"
  # Capture the decoder's output AND its exit status. Reading it through process substitution
  # discarded the status, so a decoder that died on malformed input produced an empty stream that the
  # loop read as "clean tree" — a parse failure wearing the same face as a clean result.
  set +e
  rows="$(porcelain_rows <"$LENS2_Z" 2>/dev/null)"
  rc_rows=$?
  set +e
  if [[ $rc_rows -ne 0 ]]; then
    lens2_status="degraded"; lens2_deg="\"D5\""; lens2_cands="[]"
  else
  while IFS=$'\t' read -r st flag b64; do
    [[ -z "${b64:-}" ]] && continue
    # The sentinel is load-bearing. Command substitution strips ALL trailing newlines from its
    # output, so a legal pathname ending in LF silently lost it here -- undoing the whole raw-byte
    # boundary at the last step, and addressing a DIFFERENT (possibly existing) file. Appending a
    # byte and removing it again is the only way to carry a trailing newline through `$( )`.
    path="$(printf '%s' "$b64" | base64 -d 2>/dev/null; printf 'X')"
    path="${path%X}"
    [[ -n "$path" ]] || { lens2_status="degraded"; lens2_deg="\"D5\""; lens2_cands="[]"; break; }
    # exclude untracked paths under PARKED/
    if [[ "$st" == "??" && "$path" == PARKED/* ]]; then
      continue
    fi
    disp="$path"
    if [[ "$flag" == "unrenderable" ]]; then
      # A legal pathname may contain a newline. Decoding it correctly is right; then EMITTING it
      # breaks the skill's one-line output contract, because triage.py escapes the em-dash delimiter
      # and nothing else — one candidate would render as several physical lines and could fabricate
      # apparent output lines or blow the screen cap. triage.py is out of scope, and it should be:
      # the collector is what knows the path is unrenderable, so the collector is what must not emit
      # it raw. Never dropped (that is the silent-ok failure) — shown escaped, with an inspect close.
      disp="$(sanitize_path "$path")"
      close_str="inspect: $disp (name is not renderable as one line of text; resolve the path by hand)"
      close_k="inspect"
    else
      # `path` is the DECODED filename, so a `git add` built from it addresses the real file whatever
      # bytes it contains — single-quoting makes any `$(...)`, backtick or quote inert, and `--` ends
      # option parsing so a legal path beginning with `-` is not read as a flag.
      close_str="git add -- $(shq "$path") && git commit -m $(shq "updated $path")"
      close_k="command"
    fi
    # The lens table requires FILE MTIME as this candidate's staleness. It is not optional and it is
    # not allowed to quietly become null: an absent measure sorts to the very end of its tier
    # (UNKNOWN_AGE), so a silently-unmeasured item is a silently-deprioritised one.
    # Under --fixture the read must be HERMETIC. Reading the real CWD there made a fixture's result
    # depend on whether the reviewer's checkout happened to contain the named path — the fixture
    # asserted nothing about the collector, only about the machine it ran on.
    if [[ -n "$FIXTURE_DIR" ]]; then
      # `stat_b64_<base64>.txt` first: a path with a newline or a slash-heavy name cannot always be
      # spelled as a readable fixture filename, and the base64 key always can. The readable form is
      # kept because it is the common case and a fixture should be legible.
      if [[ -f "$FIXTURE_DIR/stat_b64_${b64}.txt" ]]; then
        mtime=$(cat "$FIXTURE_DIR/stat_b64_${b64}.txt")
      elif [[ -f "$FIXTURE_DIR/stat_${path//\//_}.txt" ]]; then
        mtime=$(cat "$FIXTURE_DIR/stat_${path//\//_}.txt")
      else
        lens2_status="degraded"; lens2_deg="\"D5\""; lens2_cands="[]"; break
      fi
    else
      mtime=$(python3 -c "import os, sys; print(int(os.path.getmtime(sys.argv[1])))" "$path" 2>/dev/null) || mtime=""
      # A real stat failure is the normal status/stat race (the file was removed between the two
      # reads) or a permission error. Either way the lens cannot supply all six fields for this
      # candidate, which is D5 by definition — not an item with unknown staleness.
      if [[ -z "$mtime" ]]; then
        lens2_status="degraded"; lens2_deg="\"D5\""; lens2_cands="[]"; break
      fi
    fi
    # Validate BEFORE jq sees it. A non-integer mtime (a corrupt fixture, a stat that printed
    # something unexpected) made jq's `tonumber` fail; `set +e` is active here, so `cand` and `cands`
    # silently became EMPTY while the lens stayed `ok` — and the final heredoc then emitted invalid
    # JSON at exit 0. Malformed input must degrade, never leak past the boundary as broken output.
    if [[ ! "$mtime" =~ ^[0-9]+$ ]]; then
      lens2_status="degraded"; lens2_deg="\"D5\""; lens2_cands="[]"; break
    fi
    cand=$(jq -n \
      --arg key "path:$disp" \
      --arg what "commit or discard $disp" \
      --arg evtype "path" \
      --arg evpay "$disp" \
      --arg close "$close_str" \
      --arg close_kind "$close_k" \
      --arg lstate "$st" \
      --arg mtime "$mtime" \
      '{
        key: $key,
        what: $what,
        evidence_type: $evtype,
        evidence_payload: $evpay,
        staleness: ($mtime | tonumber),
        close: $close,
        close_kind: $close_kind,
        live_state: $lstate
      }')
    cands=$(echo "$cands" | jq --argjson c "$cand" '. + [$c]')
  done <<< "$rows"
  [[ "$lens2_status" == "ok" ]] && lens2_cands="$cands"
  fi
else
  lens2_status="degraded"
  lens2_deg="\"D5\""
fi

lens3_status="ok"
lens3_deg="null"
lens3_cands="[]"

set +e
out=$(run_mock "lens3" git rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null)
rc3=$?
set -e
if [[ $rc3 -eq 0 ]]; then
  # Identical strictness to the fallback below. Taking $1 and $2 and ignoring the rest let
  # `1 2 trailing-garbage` through as a confident `counts:2/1@tracked`. The round-5 pin for this
  # passed for the WRONG REASON — its fixture supplied no date, so the malformed result was caught
  # later by the missing-date degradation rather than here. That fixture now carries a valid date, so
  # this guard is what the assertion actually measures.
  read -r behind ahead extra_fields <<<"$(printf '%s' "$out" | tr -s '[:space:]' ' ')"
  if [[ -z "${extra_fields:-}" && -n "${ahead:-}" && -n "${behind:-}" && "$behind" =~ ^[0-9]+$ && "$ahead" =~ ^[0-9]+$ ]]; then
    up_state="tracked"
  else
    lens3_status="degraded"
    lens3_deg="\"D5\""
  fi
elif [[ $rc3 -eq 128 ]]; then
  set +e
  out=$(run_mock "lens3_fallback" git rev-list --left-right --count "development...HEAD" 2>/dev/null)
  rc_fall=$?
  set -e
  if [[ $rc_fall -eq 0 ]]; then
    # `git rev-list --left-right --count` has a two-integer result contract. Taking $1 and $2 and
    # ignoring the rest let `1 2 trailing-garbage` pass both integer checks and emit a confident
    # `counts:2/1@tracked` -- a bounded read parsed incompletely is still a malformed read, and the
    # rule is that it degrades rather than becoming a finding.
    read -r behind ahead extra_fields <<<"$(printf '%s' "$out" | tr -s '[:space:]' ' ')"
    if [[ -z "${extra_fields:-}" && -n "${ahead:-}" && -n "${behind:-}" && "$behind" =~ ^[0-9]+$ && "$ahead" =~ ^[0-9]+$ ]]; then
      up_state="no-upstream"
    else
      lens3_status="degraded"
      lens3_deg="\"D5\""
    fi
  else
    lens3_status="degraded"
    lens3_deg="\"D5\""
  fi
else
  lens3_status="degraded"
  lens3_deg="\"D5\""
fi

if [[ "$lens3_status" == "ok" ]]; then
  if [[ -n "${ahead:-}" && -n "${behind:-}" ]] && [[ "$ahead" -gt 0 || "$behind" -gt 0 ]]; then
    if [[ "$up_state" == "no-upstream" ]]; then
      close="inspect: branch $branch (push state unknown, no upstream)"
      close_kind="inspect"
    else
      # The close must follow the DIRECTION of the divergence. Selecting on up_state alone sent a
      # behind-only branch to `git push`, which is a non-fast-forward that does not close the finding
      # — a recommendation that cannot work is worse than none, because the operator runs it first.
      # The lens table names both actions for the tracked case; when both sides diverge, the order
      # matters (rebase onto upstream, then publish).
      close_kind="command"
      if   [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then close="git pull --rebase && git push"
      elif [[ "$behind" -gt 0 ]];                   then close="git pull --rebase"
      else                                               close="git push"
      fi
    fi
    clean_tree=true
    set +e
    out_status=$(run_mock "lens3_status" git status --porcelain 2>/dev/null)
    rc_status=$?
    set -e
    if [[ $rc_status -ne 0 ]]; then
      lens3_status="degraded"
      lens3_deg="\"D5\""
      lens3_cands="[]"
    elif (( BRANCH_KNOWN == 0 )); then
      # The candidate's key IS `branch:<name>`, and the no-upstream close names the branch. Without a
      # branch there are not six honest fields, so this is D5 — not an item keyed `branch:unknown`.
      lens3_status="degraded"
      lens3_deg="\"D5\""
      lens3_cands="[]"
    else
      if [[ -n "$out_status" ]]; then
        clean_tree=false
      fi
      # Lens-table staleness for lens 3: with an upstream, the committer date of the oldest unpushed
      # commit, or for behind-only the newest upstream commit. NO-UPSTREAM IS UNKNOWN — that is the
      # settled decision, not a gap: divergence from the trunk does not establish push state, so
      # there is no honest date to report.
      stale3="null"
      if [[ "$up_state" == "tracked" ]]; then
        # AHEAD (including ahead-and-behind): the OLDEST unpushed commit. That is the one that has
        # been sitting unpublished longest, which is what staleness means here; the newest one would
        # make a branch look fresh the moment you commit to it, hiding exactly the rot being ranked.
        # `git log` is newest-first, so `-1` returned the wrong end — take the last line instead.
        # BEHIND-only: the newest upstream commit, i.e. how long you have been out of date.
        if [[ "$ahead" -gt 0 ]]; then rev="@{upstream}..HEAD"; else rev="HEAD..@{upstream}"; fi
        set +e
        dates=$(run_mock "lens3_date" git log --format=%ct "$rev" 2>/dev/null)
        rc_d=$?
        set -e
        # `|| true` is load-bearing, not defensive noise: a no-match `grep` exits 1, and `set -e` is
        # active here, so an unreadable date aborted the whole script mid-document — emitting NO JSON
        # at all. That is the silent-ok failure in its purest form (the consumer reads empty stdin as
        # a clean session), reintroduced by the fix for the staleness ordering. Let the empty value
        # through so the degradation check below can do its job.
        # Validate the COMPLETE result before choosing a value from it. Filtering with `grep` and
        # taking an end silently DISCARDED malformed lines: a truncated or partly-garbage `git log`
        # then yielded a confident staleness for a branch whose history was never fully read. Every
        # line must be a timestamp, and there must be at least as many as the counts claim — fewer
        # means the read was cut short, which is a failed bounded read, not a finding.
        want=$(( ahead > 0 ? ahead : behind ))
        n_lines=0; n_ok=0
        while IFS= read -r _line; do
          [[ -z "$_line" ]] && continue
          n_lines=$((n_lines+1))
          [[ "$_line" =~ ^[0-9]+$ ]] && n_ok=$((n_ok+1))
        done <<<"$dates"
        if (( n_lines != n_ok || n_ok < want )); then
          d=""
        elif [[ "$ahead" -gt 0 ]]; then
          d="$(printf '%s\n' "$dates" | grep -E '^[0-9]+$' | tail -1 || true)"   # oldest unpushed
        else
          d="$(printf '%s\n' "$dates" | grep -E '^[0-9]+$' | head -1 || true)"   # newest upstream
        fi
        if [[ $rc_d -ne 0 || ! "$d" =~ ^[0-9]+$ ]]; then
          # The counts said there IS a divergent commit, so its date must be readable. If it is not,
          # the lens cannot supply all six fields — degrade rather than emit an item whose required
          # staleness is quietly absent.
          lens3_status="degraded"; lens3_deg="\"D5\""; lens3_cands="[]"
        else
          stale3="$d"
        fi
      fi
    fi
    if [[ "$lens3_status" == "ok" ]]; then
      cand=$(jq -n \
        --arg key "branch:$branch" \
        --arg what "sync branch" \
        --arg evtype "counts" \
        --arg evpay "${ahead}/${behind}@${up_state}" \
        --arg close "$close" \
        --arg lstate "${ahead}/${behind}/${up_state}" \
        --arg ahead "$ahead" \
        --arg behind "$behind" \
        --arg upstate "$up_state" \
        --arg close_kind "$close_kind" \
        --arg stale "$stale3" \
        --argjson clt "$clean_tree" \
        '{
          key: $key,
          what: $what,
          evidence_type: $evtype,
          evidence_payload: $evpay,
          staleness: ($stale | if . == "null" then null else tonumber end),
          close: $close,
          close_kind: $close_kind,
          live_state: $lstate,
          ahead: ($ahead | tonumber),
          behind: ($behind | tonumber),
          upstream_state: $upstate,
          clean_tree: $clt
        }')
      lens3_cands="[$cand]"
    fi
  fi
fi

lens7_status="ok"
lens7_deg="null"
lens7_cands="[]"

set +e
out=$(run_mock "lens7" python3 utils/py/releases_app.py roadmap sync --dry-run 2>/dev/null)
rc7=$?
set -e
if [[ $rc7 -eq 0 ]]; then
  # Validate the COMPLETE summary line the real producer emits (utils/py/releases_app.py:2073-2076):
  #   roadmap sync: N in ROADMAP.md -> +A added, ~U updated, -R removed, K unchanged
  # The previous form accepted any nonempty stdout that merely lacked "already in sync", then let each
  # count extraction fall back to 0 — so unrecognised output produced a confident `counts:+0~0-0`
  # candidate claiming a divergence of size zero. Unparseable output is D4 ("no ROADMAP / no ledger"),
  # never a fabricated finding.
  # ANCHORED to the whole first line, and to the literal filename and one of the producer's two real
  # suffixes. The previous form searched for an unanchored fragment with `.*` where the filename
  # belongs, so a line like
  #   `diagnostic: roadmap sync: 21 in not-ROADMAP -> +2 added, ~1 updated, -0 removed, 18 unchanged`
  # still produced a confident `ok` `+2~1-0` candidate. Finding a convenient substring inside
  # arbitrary text is not validating the producer's summary — it is the same fabrication the anchor is
  # here to stop, one layer in.
  first_line="${out%%$'\n'*}"
  if [[ "$first_line" =~ ^roadmap\ sync:\ [0-9]+\ in\ ROADMAP\.md\ -\>\ \+([0-9]+)\ added,\ ~([0-9]+)\ updated,\ -([0-9]+)\ removed,\ [0-9]+\ unchanged\ —\ (already\ in\ sync\;\ no\ write,\ generation\ unchanged|DRY\ RUN,\ nothing\ written)$ ]]; then
    a="${BASH_REMATCH[1]}"; u="${BASH_REMATCH[2]}"; r="${BASH_REMATCH[3]}"
    if [[ "$a" -gt 0 || "$u" -gt 0 || "$r" -gt 0 ]]; then
      evpay="+${a}~${u}-${r}"
      # Lens-table staleness: ROADMAP.md mtime. Same rule as lens 2 — required, so an unreadable
      # mtime degrades rather than silently becoming unknown.
      set +e
      m7=$(run_mock "lens7_mtime" python3 -c 'import os;print(int(os.path.getmtime("ROADMAP.md")))' 2>/dev/null)
      rc_m7=$?
      set -e
      if [[ $rc_m7 -ne 0 || ! "$m7" =~ ^[0-9]+$ ]]; then
        lens7_status="degraded"; lens7_deg="\"D4\""
      else
        cand=$(jq -n \
          --arg key "ledger:roadmap" \
          --arg what "sync ROADMAP ledger" \
          --arg evtype "counts" \
          --arg evpay "$evpay" \
          --arg close "python3 utils/py/releases_app.py roadmap sync && bash utils/roadmap-dashboard.sh" \
          --arg lstate "$evpay" \
          --arg stale "$m7" \
          '{
            key: $key,
            what: $what,
            evidence_type: $evtype,
            evidence_payload: $evpay,
            staleness: ($stale | tonumber),
            close: $close,
            close_kind: "command",
            live_state: $lstate
          }')
        lens7_cands="[$cand]"
      fi
    fi
  else
    lens7_status="degraded"; lens7_deg="\"D4\""
  fi
else
  lens7_status="degraded"
  lens7_deg="\"D4\""
fi

# ── Lens 1: Conversation ──────────────────────────────────────────────────────────────────────────
lens1_status="ok"
lens1_deg="null"
lens1_cands="[]"
if [[ -n "$FIXTURE_DIR" && -f "$FIXTURE_DIR/session.json" ]]; then
  SESSION_FILE="$FIXTURE_DIR/session.json"
fi

if [[ -n "$SESSION_FILE" && -f "$SESSION_FILE" ]]; then
  out1=$(python3 -c '
import sys, json, hashlib, re
try:
    with open(sys.argv[1], "r") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError()
    if len(data) == 0:
        raise ValueError()
    for item in data:
        if not isinstance(item, dict):
            raise ValueError()
except Exception:
    print("D6")
    sys.exit(0)

cands = []
for item in data:
    if item.get("completed") or item.get("parked"):
        continue
    quote = item.get("quote")
    what = item.get("what")
    close = item.get("close")
    if not isinstance(quote, str) or not isinstance(what, str) or not isinstance(close, str):
        print("D6")
        sys.exit(0)
        
    norm = re.sub(r"[^\w\s]", "", quote.lower())
    norm = re.sub(r"\s+", " ", norm).strip()
    if not norm:
        print("D6")
        sys.exit(0)
        
    sha = hashlib.sha256(norm.encode("utf-8")).hexdigest()[:12]
    cands.append({
        "key": f"conv:{sha}",
        "what": what,
        "evidence_type": "quote",
        "evidence_payload": norm,
        "staleness": 0,
        "close": close,
        "close_kind": "inspect" if close.startswith("inspect:") else "command",
        "live_state": norm
    })
print(json.dumps(cands))
' "$SESSION_FILE")
  if [[ "$out1" == "D6" ]]; then
    lens1_status="degraded"; lens1_deg="\"D6\""
  else
    lens1_cands="$out1"
  fi
else
  lens1_status="degraded"; lens1_deg="\"D6\""
fi

# ── Lens 4: Open PRs ──────────────────────────────────────────────────────────────────────────────
lens4_status="ok"
lens4_deg="null"
lens4_cands="[]"

set +e
out4=$(run_mock "lens4" gh pr list --limit 51 --json number,title,updatedAt,isDraft,mergeStateStatus 2>/dev/null)
rc4=$?
set -e

if [[ $rc4 -ne 0 ]]; then
  lens4_status="degraded"
  lens4_deg="\"D1\""
else
  out4_processed=$(python3 -c '
import sys, json, time, datetime, os
try:
    data = json.loads(sys.argv[1])
except Exception:
    print("D5")
    sys.exit(0)

if not isinstance(data, list):
    print("D5")
    sys.exit(0)

is_truncated = False
if len(data) == 51:
    is_truncated = True
    data = data[:50]

cands = []
now_ts = time.time()
env_now = os.environ.get("STANDUP_STAMP", "")
if env_now and len(env_now) >= 10:
    try:
        now_ts = datetime.datetime.strptime(env_now[:10], "%Y-%m-%d").timestamp()
    except Exception:
        pass

for pr in data:
    try:
        if "number" not in pr or "title" not in pr or "updatedAt" not in pr or "isDraft" not in pr or "mergeStateStatus" not in pr:
            raise ValueError()
        num = pr["number"]
        if not isinstance(num, int): raise ValueError()
        title = pr["title"]
        if not isinstance(title, str): raise ValueError()
        is_draft = pr["isDraft"]
        if not isinstance(is_draft, bool): raise ValueError()
        merge_state = pr["mergeStateStatus"]
        if not isinstance(merge_state, str): raise ValueError()
        updated_at = pr["updatedAt"]
        if not isinstance(updated_at, str): raise ValueError()
        
        dt = datetime.datetime.strptime(updated_at, "%Y-%m-%dT%H:%M:%SZ")
        stale_ts = dt.replace(tzinfo=datetime.timezone.utc).timestamp()
        
        stale_days = int((now_ts - stale_ts) / 86400)
        updated_date = updated_at[:10]
        
        cands.append({
            "key": f"pr:{num}",
            "what": f"review PR {num}",
            "evidence_type": "pr",
            "evidence_payload": f"{num}+{merge_state}",
            "staleness": int(stale_ts),
            "stale_days": stale_days,
            "merge_state": merge_state,
            "live_state": f"{merge_state}/{str(is_draft).lower()}/{updated_date}",
            "close": f"gh pr review {num}",
            "close_kind": "command"
        })
    except Exception:
        print("D5")
        sys.exit(0)

res = {"cands": cands, "trunc": is_truncated}
print(json.dumps(res))
' "$out4")

  if [[ "$out4_processed" == "D5" ]]; then
    lens4_status="degraded"
    lens4_deg="\"D5\""
  else
    trunc=$(echo "$out4_processed" | jq -r '.trunc')
    lens4_cands=$(echo "$out4_processed" | jq -c '.cands')
    if [[ "$trunc" == "true" ]]; then
      lens4_status="degraded"
      lens4_deg="\"D2\""
    fi
  fi
fi

# ── Lens 5: Issue state ───────────────────────────────────────────────────────────────────────────
lens5_status="ok"
lens5_deg="null"
lens5_cands="[]"

out5_processed=$(python3 -c '
import sys, os, json, re, sqlite3, time, datetime

def get_bounded_set(fx, session_file, repo_root):
    nums = set()
    
    if fx:
        mock_set = os.path.join(fx, "lens5_bounded_set.txt")
        if os.path.exists(mock_set):
            with open(mock_set) as f:
                for line in f:
                    if line.strip().isdigit():
                        nums.add(int(line.strip()))
        
    if os.path.exists(session_file):
        try:
            with open(session_file) as f:
                data = json.load(f)
                if isinstance(data, list):
                    for item in data:
                        for k in ["quote", "what", "close"]:
                            v = str(item.get(k, ""))
                            for m in re.finditer(r"(?:#|GH-|issue\s+)(\d+)", v, re.IGNORECASE):
                                nums.add(int(m.group(1)))
        except Exception:
            pass

    roadmap_path = os.path.join(fx, "ROADMAP.md") if fx else os.path.join(repo_root, "ROADMAP.md")
    try:
        with open(roadmap_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        in_sec = False
        for line in lines:
            if line.startswith("### "):
                in_sec = ("Queue / parked intake" in line or "In progress" in line)
            elif in_sec and line.startswith("- **"):
                m = re.search(r"GH-(\d+)", line)
                if m:
                    nums.add(int(m.group(1)))
    except Exception:
        print("D5")
        sys.exit(0)

    db_path = os.path.join(fx, "releases.db") if fx else os.path.join(repo_root, "releases.db")
    try:
        db_uri = f"file:{db_path}?mode=ro"
        c = sqlite3.connect(db_uri, uri=True)
        rows = c.execute("SELECT i.url FROM manifest_items mi JOIN releases r ON r.id = mi.release_id JOIN issue_refs i ON i.id = mi.issue_ref_id WHERE r.status IN (?, ?) AND i.url IS NOT NULL", ("draft", "active")).fetchall()
        for r in rows:
            m = re.search(r"issues/(\d+)$", r[0])
            if m:
                nums.add(int(m.group(1)))
    except Exception:
        print("D5")
        sys.exit(0)
    
    return sorted(list(nums))

def run_mock(id, cmd, fx):
    import subprocess
    if fx:
        rc_file = os.path.join(fx, f"{id}.rc")
        txt_file = os.path.join(fx, f"{id}.txt")
        if os.path.exists(rc_file):
            with open(rc_file) as f: rc = int(f.read().strip())
            out = ""
            if os.path.exists(txt_file):
                with open(txt_file) as f: out = f.read()
            return rc, out
        if os.path.exists(txt_file):
            with open(txt_file) as f: out = f.read()
            return 0, out
        return 1, f"Missing fixture: {id}\n"
    proc = subprocess.run(cmd, shell=False, capture_output=True, text=True)
    return proc.returncode, proc.stdout + proc.stderr

fx = sys.argv[1]
session_file = sys.argv[2]
repo_root = sys.argv[3]

rc_gh, out_gh = run_mock("lens5_gh_check", ["gh", "--version"], fx)
if rc_gh != 0:
    print("D1")
    sys.exit(0)

cands = []
nums = get_bounded_set(fx, session_file, repo_root)

for num in nums:
    rc, out = run_mock(f"lens5_gh_issue_{num}", ["gh", "issue", "view", str(num), "--json", "number,state,title,updatedAt"], fx)
    if rc != 0:
        print("D1")
        sys.exit(0)
    try:
        data = json.loads(out)
        if "number" not in data or "state" not in data or "title" not in data or "updatedAt" not in data:
            print("D5")
            sys.exit(0)
        if data["number"] != num:
            print("D5")
            sys.exit(0)
        
        number_val = data["number"]
        if not isinstance(number_val, int): raise ValueError()
        state = data["state"]
        if not isinstance(state, str): raise ValueError()
        title = data["title"]
        if not isinstance(title, str): raise ValueError()
        updated_at = data["updatedAt"]
        if not isinstance(updated_at, str): raise ValueError()
        
        dt = datetime.datetime.strptime(updated_at, "%Y-%m-%dT%H:%M:%SZ")
        stale_ts = dt.replace(tzinfo=datetime.timezone.utc).timestamp()
        stale_ts = int(stale_ts)
            
        updated_date = updated_at[:10]
        cands.append({
            "key": f"issue:{num}",
            "what": f"triage issue {num}",
            "evidence_type": "issue",
            "evidence_payload": f"{num}+{state}@none",
            "staleness": stale_ts,
            "live_state": f"{state}/{updated_date}",
            "close": f"gh issue view {num}",
            "close_kind": "command"
        })
    except Exception:
        print("D5")
        sys.exit(0)

print(json.dumps(cands))
' "${FIXTURE_DIR:-}" "${SESSION_FILE:-}" "$REPO_ROOT")
if [[ "$out5_processed" == "D1" ]]; then
  lens5_status="degraded"
  lens5_deg="\"D1\""
elif [[ "$out5_processed" == "D5" ]]; then
  lens5_status="degraded"
  lens5_deg="\"D5\""
else
  lens5_cands="$out5_processed"
fi

# ── Lens 6: RELEASES ledger ───────────────────────────────────────────────────────────────────────
lens6_status="ok"
lens6_deg="null"
lens6_cands="[]"
out6=$(python3 -c '
import sys, os, time, json, re, calendar, datetime

def main():
    def parse_date(d):
        try:
            dt = datetime.datetime.strptime(d, "%Y-%m-%d")
            return calendar.timegm(dt.utctimetuple())
        except Exception:
            return None

    def run_mock(id, cmd):
        import os, subprocess
        fx = os.environ.get("FIXTURE_DIR", "")
        if fx:
            rc_file = os.path.join(fx, f"{id}.rc")
            txt_file = os.path.join(fx, f"{id}.txt")
            if os.path.exists(rc_file):
                with open(rc_file) as f: rc = int(f.read().strip())
                out = ""
                if os.path.exists(txt_file):
                    with open(txt_file) as f: out = f.read()
                return rc, out
            if os.path.exists(txt_file):
                with open(txt_file) as f: out = f.read()
                return 0, out
            return 1, f"Missing fixture: {id}\n"
        proc = subprocess.run(cmd, shell=False, capture_output=True, text=True)
        return proc.returncode, proc.stdout + proc.stderr

    rc_chk, out_chk = run_mock("lens6_check", ["python3", "utils/py/releases_app.py", "check"])
    rc_nxt, out_nxt = run_mock("lens6_next", ["python3", "utils/py/releases_app.py", "next"])
    rc_drf, out_drf = run_mock("lens6_draft", ["python3", "utils/py/releases_app.py", "list", "--status", "draft"])
    rc_act, out_act = run_mock("lens6_active", ["python3", "utils/py/releases_app.py", "list", "--status", "active"])

    if (rc_chk not in (0, 1, 2)) or (rc_nxt != 0) or (rc_drf != 0) or (rc_act != 0):
        print("D5")
        sys.exit(0)

    cands = []
    versions = []

    def parse_list(out):
        for line in out.splitlines():
            if not line.strip(): continue
            parts = line.split()
            if len(parts) >= 2 and parts[0].startswith("rel-") and parts[1] != "-":
                versions.append(parts[1])
            else:
                print("D5")
                sys.exit(0)

    parse_list(out_drf)
    parse_list(out_act)

    seen_keys = set()

    for v in versions:
        rc_show, out_show = run_mock(f"lens6_show_{v.replace(chr(46), chr(95))}", ["python3", "utils/py/releases_app.py", "show", "--version", v])
        if rc_show != 0 or not out_show.startswith("GID:"):
            print("D5")
            sys.exit(0)
            
        show_fields = {}
        for line in out_show.splitlines():
            if ":" in line:
                k, val = line.split(":", 1)
                show_fields[k.strip()] = val.strip()
                
        st = show_fields.get("Status")
        td = show_fields.get("Target Date")
        if st == "active" and td and td != "None" and parse_date(td):
            target_ts = parse_date(td)
            now_ts = int(time.time())
            env_now = os.environ.get("RELEASES_APP_NOW", "")
            if env_now:
                now_ts = parse_date(env_now[:10]) or now_ts
            if now_ts > target_ts:
                rule_name = "release-target-passed"
                key = f"rule:{rule_name}:{v}"
                if key not in seen_keys:
                    cands.append({
                        "key": key,
                        "what": f"ship {v}",
                        "evidence_type": "rule",
                        "evidence_payload": f"{rule_name}@{v}",
                        "rule_name": rule_name,
                        "staleness": target_ts,
                        "close": f"python3 utils/py/releases_app.py ship {v}",
                        "close_kind": "command",
                        "live_state": f"warn: rule={rule_name}: release {v} is active past target of {td}"
                    })
                    seen_keys.add(key)

    for line in out_chk.splitlines():
        if line.startswith("FAIL: rule="):
            rule_str = line.split(":", 2)[1].strip()
            rule_name = rule_str[5:]
            key = f"rule:{rule_name}:db"
            if key not in seen_keys:
                cands.append({
                    "key": key,
                    "what": f"resolve {rule_name.replace(chr(45), chr(32))}",
                    "evidence_type": "rule",
                    "evidence_payload": f"{rule_name}@db",
                    "rule_name": rule_name,
                    "staleness": None,
                    "close": "python3 utils/py/releases_app.py check --rebuild",
                    "close_kind": "command",
                    "live_state": line.strip()
                })
                seen_keys.add(key)
        elif line.startswith("warn: rule="):
            m = re.search(r"warn: rule=([^:]+):\s*([^\s]+)\s+.*?target of ([0-9]{4}-[0-9]{2}-[0-9]{2})", line)
            if m:
                rule_name = m.group(1)
                v = m.group(2)
                td = parse_date(m.group(3))
                key = f"rule:{rule_name}:{v}"
                if key not in seen_keys:
                    cands.append({
                        "key": key,
                        "what": f"ship {v}" if "overdue" in rule_name or "target" in rule_name else f"resolve {rule_name.replace(chr(45), chr(32))}",
                        "evidence_type": "rule",
                        "evidence_payload": f"{rule_name}@{v}",
                        "rule_name": rule_name,
                        "staleness": td,
                        "close": f"python3 utils/py/releases_app.py ship {v}",
                        "close_kind": "command",
                        "live_state": line.strip()
                    })
                    seen_keys.add(key)
            else:
                parts = line.split(":", 2)
                rule_name = parts[1].strip()[5:]
                key = f"rule:{rule_name}:db"
                if key not in seen_keys:
                    cands.append({
                        "key": key,
                        "what": f"resolve {rule_name.replace(chr(45), chr(32))}",
                        "evidence_type": "rule",
                        "evidence_payload": f"{rule_name}@db",
                        "rule_name": rule_name,
                        "staleness": None,
                        "close": "python3 utils/py/releases_app.py check",
                        "close_kind": "command",
                        "live_state": line.strip()
                    })
                    seen_keys.add(key)
    print(json.dumps(cands))

try:
    main()
except Exception:
    print("D5")
    sys.exit(0)
')
if [[ "$out6" == "D5" ]]; then
  lens6_status="degraded"; lens6_deg="\"D5\""
else
  lens6_cands="$out6"
fi

# ── Lens 8: PARKED ────────────────────────────────────────────────────────────────────────────────
lens8_status="ok"
lens8_deg="null"
lens8_cands="[]"
out8=$(python3 -c '
import os, sys, json, glob, re
fx = os.environ.get("FIXTURE_DIR", "")
parked_dir = os.path.join(fx, "PARKED") if fx else "PARKED"

if not os.path.isdir(parked_dir):
    print("D3")
    sys.exit(0)

PARK_RE = re.compile(r"^- \[([^\]]+)\](.*)— check: (\{.*?\}) — close: (.*?)(?: —|$)")
def run_probe(chk, key):
    import subprocess
    kind = chk.get("kind")
    args = chk.get("args", [])
    if kind == "test-e" and args:
        if fx:
            rc_file = os.path.join(fx, f"lens8_test_e_{key.replace(chr(58), chr(95))}.rc")
            if os.path.exists(rc_file):
                with open(rc_file) as f:
                    rc = int(f.read().strip())
                    return rc == 0, f"exit {rc}"
            return False, "missing fixture"
        ex = os.path.exists(args[0])
        return ex, "exists" if ex else "missing"
    elif kind == "gh-issue-state" and args:
        if fx:
            txt_file = os.path.join(fx, f"lens8_gh_{args[0]}.txt")
            if os.path.exists(txt_file):
                with open(txt_file) as f: out = f.read()
                return "CLOSED" in out, "CLOSED" if "CLOSED" in out else "OPEN"
            return False, "missing fixture"
        print("D3")
        sys.exit(0)
    elif kind == "releases-check":
        if fx:
            rc_file = os.path.join(fx, "lens8_releases_check.rc")
            if os.path.exists(rc_file):
                with open(rc_file) as f:
                    rc = int(f.read().strip())
                    return rc == 0, f"exit {rc}"
            return False, "missing fixture"
        try:
            rc = subprocess.run(["python3", "utils/py/releases_app.py", "check"], capture_output=True).returncode
            return rc == 0, f"exit {rc}"
        except Exception:
            return False, "error"
    elif kind == "git-log" and args:
        if fx:
            rc_file = os.path.join(fx, f"lens8_git_log.rc")
            if os.path.exists(rc_file):
                with open(rc_file) as f:
                    rc = int(f.read().strip())
                    return rc == 0, f"exit {rc}"
            return False, "missing fixture"
        try:
            rc = subprocess.run(["git", "log", "--oneline", "-1", str(args[0])], capture_output=True).returncode
            return rc == 0, f"exit {rc}"
        except Exception:
            return False, "error"
    else:
        print("D3")
        sys.exit(0)

cands = []
try:
    for path in glob.glob(os.path.join(parked_dir, "*.md")):
        with open(path, "r", encoding="utf-8") as fh:
            for line in fh:
                line_str = line.strip()
                if not line_str.startswith("- ["):
                    continue
                m = PARK_RE.match(line_str)
                if not m:
                    print("D3")
                    sys.exit(0)
                key, rest, check_str, close_str = m.groups()
                try:
                    chk = json.loads(check_str)
                    if not isinstance(chk, dict) or "kind" not in chk:
                        raise ValueError()
                    if "args" in chk and not isinstance(chk["args"], list):
                        raise ValueError()
                except Exception:
                    print("D3")
                    sys.exit(0)
                
                first_seen = None
                fs_m = re.search(r"first seen: ([0-9]+)", line_str)
                if fs_m:
                    first_seen = int(fs_m.group(1))
                
                try:
                    is_done, state_str = run_probe(chk, key)
                except Exception:
                    print("D3")
                    sys.exit(0)
                    
                if is_done:
                    cands.append({
                        "key": f"park:{key}",
                        "what": f"close parked item {key}",
                        "evidence_type": "park",
                        "evidence_payload": key,
                        "staleness": first_seen,
                        "close": close_str,
                        "close_kind": "command" if not close_str.startswith("inspect:") else "inspect",
                        "live_state": state_str
                    })
except Exception:
    print("D3")
    sys.exit(0)
print(json.dumps(cands))
')
if [[ "$out8" == "D3" ]]; then
  lens8_status="degraded"; lens8_deg="\"D3\""
else
  lens8_cands="$out8"
fi

branch_json=$(jq -Rn --arg b "$branch" '$b')

cat <<EOF
{"repo": {"branch": $branch_json},
 "lenses": {
   "1": {"status": "$lens1_status", "degraded_id": $lens1_deg, "candidates": $lens1_cands},
   "2": {"status": "$lens2_status", "degraded_id": $lens2_deg, "candidates": $lens2_cands},
   "3": {"status": "$lens3_status", "degraded_id": $lens3_deg, "candidates": $lens3_cands},
   "4": {"status": "$lens4_status", "degraded_id": $lens4_deg, "candidates": $lens4_cands},
   "5": {"status": "$lens5_status", "degraded_id": $lens5_deg, "candidates": $lens5_cands},
   "6": {"status": "$lens6_status", "degraded_id": $lens6_deg, "candidates": $lens6_cands},
   "7": {"status": "$lens7_status", "degraded_id": $lens7_deg, "candidates": $lens7_cands},
   "8": {"status": "$lens8_status", "degraded_id": $lens8_deg, "candidates": $lens8_cands}
 }
}
EOF

# `skills/standup/SKILL.md` publishes "Exit 0 clean · 2 usage or a contract violation · 3 one or more
# lenses degraded". Only the jq preflight honoured that; an ordinary degraded lens set its status in
# the document and then exited 0, so a caller checking the exit code was told the collection
# succeeded after a bounded read had failed. The document is the same either way — this is about the
# out-of-band signal a caller can act on without parsing JSON.
if [[ "$lens1_status" != "ok" || "$lens2_status" != "ok" || "$lens3_status" != "ok" || "$lens4_status" != "ok" || "$lens5_status" != "ok" || "$lens6_status" != "ok" || "$lens7_status" != "ok" || "$lens8_status" != "ok" ]]; then
  exit 3
fi
