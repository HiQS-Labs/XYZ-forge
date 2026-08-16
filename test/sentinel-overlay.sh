#!/usr/bin/env bash
# test/sentinel-overlay.sh — GH-281 Tier-2 overlay safety + behavior (issue §2, revised posture).
#   A. static guard   — call-home primitives appear ONLY in the wrappers lib/classify.sh, lib/gh.sh.
#   B. inert-by-default — with no runtime.env, every entrypoint no-ops AND invokes zero egress binaries
#                         (proved by fail-loud ollama/gh/curl/wget stubs on PATH that are never called).
#   C. triage dry-run — a deterministic classify stub drafts a pdda-valid 1-INBOX doc, no egress.
#   D. probe-lint     — a bug-detecting probe passes; an inverted probe fails.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OV="$HERE/../sentinel-overlay"
[ -d "$OV" ] || { echo "  FAIL: overlay dir missing: $OV" >&2; exit 1; }
pass(){ echo "  PASS: $*"; }
fail(){ echo "  FAIL: $*" >&2; exit 1; }
echo "== test: sentinel-overlay =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-overlay.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# --- A. static egress guard ---------------------------------------------------
EGRESS='(^|[^[:alnum:]_])(curl|wget|ollama)([^[:alnum:]_]|$)|/dev/tcp|(^|[^[:alnum:]_])gh[[:space:]]|(^|[^[:alnum:]_])git[[:space:]]+push'
bad=0
while IFS= read -r f; do
  case "$f" in */lib/classify.sh|*/lib/gh.sh) continue;; esac
  if grep -nE "$EGRESS" "$f" >/dev/null 2>&1; then
    echo "    egress token outside a wrapper in: $f" >&2; grep -nE "$EGRESS" "$f" >&2; bad=1
  fi
done < <(find "$OV" -name '*.sh' -type f)
[ "$bad" = 0 ] && pass "call-home primitives confined to lib/classify.sh + lib/gh.sh" || fail "egress leaked outside the wrappers"

# --- B. inert-by-default: zero egress with no runtime.env ---------------------
BIN="$WORK/bin"; mkdir -p "$BIN"
CALLED="$WORK/called"; : > "$CALLED"
for cmd in ollama gh curl wget nc; do
  { printf '#!/usr/bin/env bash\n'; printf 'echo "%s $*" >> "%s"\nexit 1\n' "$cmd" "$CALLED"; } > "$BIN/$cmd"
  chmod +x "$BIN/$cmd"
done
export SENTINEL_CONFIG="$WORK/nonexistent-runtime.env"     # guarantees inert
printf '%s\n' '{"timestamp":"t","severity":"error","check":"marathon.escalation","scope":"harness","repo":"r","message":"boom","action":"triage","probe":"false"}' > "$WORK/debug.log"
mkdir -p "$WORK/inbox" "$WORK/working"
ri(){ PATH="$BIN:$PATH" SENTINEL_DEBUG_LOG="$WORK/debug.log" SENTINEL_INBOX="$WORK/inbox" SENTINEL_WORKING="$WORK/working" "$@"; }

ri bash "$OV/sentinel-triage.sh"      >/dev/null 2>&1 || fail "triage errored when inert"
ri bash "$OV/sentinel-nightly.sh"     >/dev/null 2>&1 || fail "nightly errored when inert"
ri bash "$OV/pr-emit.sh" --branch x   >/dev/null 2>&1 || fail "pr-emit errored when inert"
ri bash "$OV/adversarial-review.sh" --diff-file "$WORK/debug.log" >/dev/null 2>&1 || fail "adversarial errored when inert"
ri bash "$OV/morning-report.sh"       >/dev/null 2>&1 || fail "morning-report errored when inert"
[ ! -s "$CALLED" ] && pass "inert-by-default: no egress binary invoked with no runtime.env" || { echo "    called:" >&2; cat "$CALLED" >&2; fail "an egress binary was called while inert"; }
[ -z "$(ls -A "$WORK/inbox" 2>/dev/null)" ] && pass "inert triage drafted nothing (no stub)" || fail "inert triage wrote a doc"

# --- C. triage dry-run with a deterministic stub (no config => no egress) ------
STUB="$WORK/stub.sh"; { printf '#!/usr/bin/env bash\ncat >/dev/null; echo bug\n'; } > "$STUB"; chmod +x "$STUB"
PATH="$BIN:$PATH" SENTINEL_CONFIG="$WORK/nope.env" SENTINEL_CLASSIFY_STUB="bash $STUB" \
  SENTINEL_DEBUG_LOG="$WORK/debug.log" SENTINEL_INBOX="$WORK/inbox2" \
  bash "$OV/sentinel-triage.sh" >/dev/null 2>&1 || fail "triage dry-run errored"
doc="$(find "$WORK/inbox2" -name 'F-*.md' 2>/dev/null | head -1)"
[ -n "$doc" ] || fail "triage dry-run drafted no doc"
grep -q 'sentinel-key:' "$doc" || fail "drafted doc missing dedupe marker"
grep -q 'Swarm Preflight Contract' "$doc" || fail "drafted doc missing contract"
bash "$HERE/../utils/pdda/pdda.sh" frontmatter "$doc" >/dev/null 2>&1 \
  && pass "triage dry-run drafts a pdda-valid 1-INBOX doc" || { bash "$HERE/../utils/pdda/pdda.sh" frontmatter "$doc" >&2; fail "drafted doc fails pdda frontmatter"; }
[ ! -s "$CALLED" ] && pass "triage dry-run made zero egress calls" || fail "dry-run leaked egress"
# dedupe: a second run over the same finding must not draft a duplicate
PATH="$BIN:$PATH" SENTINEL_CONFIG="$WORK/nope.env" SENTINEL_CLASSIFY_STUB="bash $STUB" \
  SENTINEL_DEBUG_LOG="$WORK/debug.log" SENTINEL_INBOX="$WORK/inbox2" \
  bash "$OV/sentinel-triage.sh" >/dev/null 2>&1 || true
[ "$(find "$WORK/inbox2" -name 'F-*.md' | wc -l | tr -d ' ')" -eq 1 ] && pass "triage dedupes on re-run" || fail "triage re-drafted a duplicate"

# --- D. probe-lint polarity ---------------------------------------------------
# shellcheck disable=SC1091
. "$OV/lib/probe-lint.sh"
C1="$WORK/c1.json"; printf '{"fix_probes":[{"type":"path_absent","path":"nope-%s.txt"}]}' "$$" > "$C1"
sentinel_probe_lint "$C1" "$WORK" && pass "probe-lint: bug-detecting probe passes" || fail "probe-lint rejected a valid bug-probe"
C2="$WORK/c2.json"; : > "$WORK/exists.txt"; printf '{"fix_probes":[{"type":"path_absent","path":"exists.txt"}]}' > "$C2"
if sentinel_probe_lint "$C2" "$WORK"; then fail "probe-lint accepted an inverted probe"; else pass "probe-lint: inverted probe (file present) fails"; fi

echo "sentinel-overlay: all checks passed"
