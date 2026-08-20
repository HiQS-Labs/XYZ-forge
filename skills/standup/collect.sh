#!/usr/bin/env bash
set -uo pipefail

FIXTURE_DIR=""
while [[ $# -gt 0 ]]; do
  case $1 in
    # `$2` under `set -u` is an unbound-variable abort on a bare `--fixture`, which surfaces as a
    # bash error and exit 1 rather than the interface SKILL.md publishes ("2 usage or a contract
    # violation"). Validate the operand before consuming it.
    --fixture)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "collect.sh: --fixture requires a directory operand" >&2; exit 2
      fi
      FIXTURE_DIR="$2"; shift 2 ;;
    *) echo "collect.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

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
    '   "2": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "3": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "7": {"status": "degraded", "degraded_id": "D5", "candidates": []}' \
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

# Decode one `git status --porcelain` stream into `XY<TAB>base64(path)` lines.
#
# Slicing `${line:3}` in bash is wrong for two ordinary cases, and both were shipped:
#   * C-QUOTING — a name containing a quote, backslash, newline or non-ASCII byte arrives wrapped in
#     double quotes with backslash escapes. The slice yields the ESCAPED DISPLAY STRING, so every
#     downstream use addresses a file that does not exist: the fixture stat lookup misses, a live
#     getmtime fails, and the lens degrades D5 — clearing EVERY candidate it had already collected.
#     One oddly-named file could therefore blank the whole working-tree lens.
#   * RENAMES — `R  old -> new` is one field to the slice, so the "path" is the literal string
#     `old -> new`, which cannot be statted either, with the same blast radius.
# Both contradict the lens-2 predicate ("any modified or untracked non-ignored path") by dropping
# items the contract requires, and they do it by degrading rather than visibly.
#
# Decode in python, which has the C-escape grammar built in, and hand back base64 so a path
# containing any byte at all survives the trip through the shell. (Filenames cannot contain NUL, so a
# bash variable can hold the decoded result safely.)
#
# ROUND 6 — this is now a STRICT, ERROR-PROPAGATING boundary, not a best-effort translator. That
# change was the reviewer's structural recommendation over three more edge-case patches, and it is
# the right one: every previous round added a case, and every added case left a neighbouring one
# open. A parser that returns "nothing" for input it does not understand is indistinguishable from a
# parser that correctly found nothing, and this whole lens exists to make that distinction.
#
# The contract is now: EVERY row is understood and emitted, or the decoder FAILS and the lens
# degrades. There is no third outcome. Three inputs used to take one:
#   * a row with a status field and no pathname (` M`) emitted nothing and left the lens `ok`;
#   * an undecodable quoted name (`"\400.txt"`) crashed the decoder, whose exit status was swallowed
#     by process substitution, so the lens read as a clean tree;
#   * a legal NEWLINE-containing pathname decoded correctly and then broke the one-line output
#     contract downstream — triage.py escapes the em-dash delimiter but not newlines, so a single
#     candidate rendered as several physical lines and could fabricate apparent output lines.
# The first two now exit non-zero. The third is emitted with a sanitised single-line display and an
# `inspect:` close, because the contract says never drop an item — the operator still learns the file
# is there, and gets asked to look at it rather than handed a command built from an unrenderable name.
porcelain_rows() {
  python3 -c '
import base64, re, sys
UNRENDERABLE = re.compile(r"[\x00-\x1f\x7f]")   # newline, CR, tab, and every other control byte
out = []
for line in sys.stdin.read().split("\n"):
    if not line.strip():
        continue
    # Porcelain is exactly "XY<space>PATH". Anything shorter, or without the separator, is not a row
    # this parser understands -- and understanding it is the whole job.
    if len(line) < 4 or line[2] != " ":
        sys.stderr.write("porcelain_rows: malformed row: %r\n" % line)
        sys.exit(1)
    xy, rest = line[:2], line[3:]
    # A rename/copy record names both sides; the CURRENT path is what an operator acts on.
    if xy and xy[0] in ("R", "C") and " -> " in rest:
        rest = rest.split(" -> ", 1)[1]
    if rest.startswith("\"") and rest.endswith("\"") and len(rest) >= 2:
        # Same grammar C uses, which is what git emits here: \n, \t, \\, \", and \ooo octal BYTES.
        # The octal escapes are the subtle part. git quotes a UTF-8 filename byte by byte, so `é.txt`
        # arrives as "\303\251.txt". `unicode_escape` turns those into the CODE POINTS U+00C3 U+00A9;
        # encoding that back as UTF-8 gives four bytes (C3 83 C2 A9), not the two the filename
        # actually has. The path then does not exist, the stat misses, and the lens degrades — the
        # exact failure this decoder was written to remove, one layer deeper.
        # `latin-1` is the inverse map: it takes code points 0x00-0xFF straight back to the single
        # bytes git escaped, recovering the original byte string. Then decode it as UTF-8 once.
        try:
            raw = rest[1:-1].encode("latin-1", "backslashreplace").decode("unicode_escape")
            pathbytes = raw.encode("latin-1")
        except (UnicodeDecodeError, UnicodeEncodeError) as exc:
            sys.stderr.write("porcelain_rows: undecodable quoted path %r (%s)\n" % (rest, exc))
            sys.exit(1)
    else:
        pathbytes = rest.encode("utf-8", "surrogateescape")
    if not pathbytes:
        sys.stderr.write("porcelain_rows: row carries a status but no pathname: %r\n" % line)
        sys.exit(1)
    display = pathbytes.decode("utf-8", "replace")
    flag = "unrenderable" if UNRENDERABLE.search(display) else "ok"
    out.append("%s\t%s\t%s\n" % (xy, flag, base64.b64encode(pathbytes).decode("ascii")))
sys.stdout.write("".join(out))
'
}

# One-line display for a path that cannot be shown as it is. Control bytes become their escapes, so
# the item still names the file recognisably without ever emitting a physical newline.
sanitize_path() {
  printf '%s' "$1" | python3 -c '
import sys
s = sys.stdin.buffer.read().decode("utf-8", "replace")
sys.stdout.write("".join(
    {"\n": "\\n", "\r": "\\r", "\t": "\\t"}.get(c, "\\x%02x" % ord(c)) if (ord(c) < 32 or ord(c) == 127) else c
    for c in s))
'
}

lens2_status="ok"
lens2_deg="null"
lens2_cands="[]"

set +e
out=$(run_mock "lens2" git status --porcelain)
rc2=$?
set -e
if [[ $rc2 -eq 0 ]]; then
  cands="[]"
  # Capture the decoder's output AND its exit status. Reading it through process substitution
  # discarded the status, so a decoder that died on malformed input produced an empty stream that the
  # loop read as "clean tree" — a parse failure wearing the same face as a clean result.
  set +e
  rows="$(printf '%s\n' "$out" | porcelain_rows 2>/dev/null)"
  rc_rows=$?
  set +e
  if [[ $rc_rows -ne 0 ]]; then
    lens2_status="degraded"; lens2_deg="\"D5\""; lens2_cands="[]"
  else
  while IFS=$'\t' read -r st flag b64; do
    [[ -z "${b64:-}" ]] && continue
    path="$(printf '%s' "$b64" | base64 -d 2>/dev/null)"
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
      close_str="inspect: $disp (name contains control characters; resolve the path by hand)"
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
      close="git push"
      close_kind="command"
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
        if [[ "$ahead" -gt 0 ]]; then rev="@{upstream}..HEAD"; else rev="HEAD..@{upstream}"; fi
        set +e
        d=$(run_mock "lens3_date" git log -1 --format=%ct "$rev" 2>/dev/null)
        rc_d=$?
        set -e
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

branch_json=$(jq -Rn --arg b "$branch" '$b')

cat <<EOF
{"repo": {"branch": $branch_json},
 "lenses": {
   "2": {"status": "$lens2_status", "degraded_id": $lens2_deg, "candidates": $lens2_cands},
   "3": {"status": "$lens3_status", "degraded_id": $lens3_deg, "candidates": $lens3_cands},
   "7": {"status": "$lens7_status", "degraded_id": $lens7_deg, "candidates": $lens7_cands}
 }
}
EOF

# `skills/standup/SKILL.md` publishes "Exit 0 clean · 2 usage or a contract violation · 3 one or more
# lenses degraded". Only the jq preflight honoured that; an ordinary degraded lens set its status in
# the document and then exited 0, so a caller checking the exit code was told the collection
# succeeded after a bounded read had failed. The document is the same either way — this is about the
# out-of-band signal a caller can act on without parsing JSON.
if [[ "$lens2_status" != "ok" || "$lens3_status" != "ok" || "$lens7_status" != "ok" ]]; then
  exit 3
fi
