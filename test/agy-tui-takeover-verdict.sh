#!/usr/bin/env bash
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/agy-tui-takeover-verdict.sh. The pre-fix revision is replayed by calling agy_auth_timeout_verdict with AGY_TUI_TAKEOVER_MARKERS emptied, which is exactly what the classifier looked like before this change. Pre-fix result: a timeout whose capture is agy 1.1.16's mute terminal-takeover escape sequence classifies 'failed', so agy-turn exits 5 and the lane is blocked on a machine where 'agy -p' answers in 14s. Post-fix result: the same capture classifies 'unverifiable' and the lane proceeds, while a takeover carrying a readable login prompt and a silent timeout both still block. All observed in one run."}
# agy 1.1.16 changed the SHAPE of the headless-auth failure, and the change re-opened GH-375.
#
# Measured on Linux, 2026-08-20, against agy 1.1.16:
#
#   $ agy --help          -> subcommands: agent agents changelog help install mcp models
#                            plugin plugins update          <- no `whoami`, and no `login` either
#   $ agy whoami          -> falls through to the INTERACTIVE TUI. Writes its terminal-takeover
#                            escape codes, then blocks. Ignores SIGTERM: `timeout 8 agy whoami`
#                            was still alive at 248s; only SIGKILL ends it.
#   $ agy models          -> rc=0 in 7.6-8.5s, real model list fetched from the backend
#   $ agy -p "..."        -> rc=0 in 14s, correct answer                    <- the lane WORKS
#
# So the capture at timeout is escape codes and no prose. The pre-existing classifier matched TTY
# prose only, read that as "timed out with no TTY diagnostic", and returned fatal -- blocking a lane
# whose builder demonstrably works. Third occurrence of the same false-block direction GH-375 and its
# follow-up were both written to prevent, arriving through a new spelling rather than a new branch.
#
# The follow-up's rule is preserved verbatim: reclassify ONLY on positive evidence of the TTY cause.
# A terminal takeover IS that evidence. The "and nothing readable survives stripping" half is what
# keeps the fatal cases fatal:
#   (1) timeout + mute terminal takeover        -> unverifiable, lane proceeds   <- NEW
#   (2) timeout + NO output                     -> still fatal
#   (3) timeout + takeover + a login prompt     -> still fatal   <- readable text disqualifies it
#   (4) timeout + TTY prose (bubbletea wording) -> unverifiable, unchanged
set -euo pipefail

source "$(dirname "$0")/_setup.sh" agy-tui-takeover-verdict
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
export PYTHONPATH="$ROOT_REPO/utils/py${PYTHONPATH:+:$PYTHONPATH}"

ESC=$'\033'
# The exact prefix agy 1.1.16 wrote before blocking, captured from
# evidence/marathons/run-1/00e-agy-preflight-verdict.log.
TAKEOVER="${ESC}[?2026\$p${ESC}[?2027\$p${ESC}[>4m${ESC}[=0;1u${ESC}[?1049h${ESC}[?25l${ESC}[?5W${ESC}[?2004h${ESC}[>4;2m${ESC}[=1;1u${ESC}[?u${ESC}[H${ESC}[2J"
TTY_LINE='CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured'
RAWMODE_LINE='CLI error: error entering raw mode: input/output error'
LOGIN_LINE='To authenticate, visit https://example.invalid/device and enter code ABCD-1234'

verdict() {  # <file> -> "<severity>|<detail>"
  python3 -c 'import sys; from rtl import agy_auth_timeout_verdict as v; s,d = v(sys.argv[1]); print(f"{s}|{d}")' "$1"
}

# ── (1) the new case ──────────────────────────────────────────────────────────────────────
printf '%s' "$TAKEOVER" > "$WORK/takeover.txt"
got="$(verdict "$WORK/takeover.txt")"
[ "${got%%|*}" = "unverifiable" ] \
  && pass "timeout + a mute terminal takeover -> unverifiable (the lane proceeds)" \
  || fail "expected unverifiable for agy 1.1.16's takeover capture, got '${got%%|*}'"

# ── (2) silence must stay fatal ───────────────────────────────────────────────────────────
: > "$WORK/empty.txt"
got="$(verdict "$WORK/empty.txt")"
[ "${got%%|*}" = "failed" ] \
  && pass "timeout + NO output -> still fatal (unchanged)" \
  || fail "a silent timeout must stay fatal, got '${got%%|*}'"

# ── (3) a takeover that says something readable must stay fatal ───────────────────────────
# This is the assertion that keeps the widening honest. An interactive login prompt drawn INSIDE a
# TUI is still an interactive login prompt, and it is the exact failure this branch exists to catch.
printf '%s%s\n' "$TAKEOVER" "$LOGIN_LINE" > "$WORK/takeover-login.txt"
got="$(verdict "$WORK/takeover-login.txt")"
[ "${got%%|*}" = "failed" ] \
  && pass "timeout + takeover + a readable login prompt -> still fatal (readable text disqualifies)" \
  || fail "a login prompt inside a TUI must stay fatal, got '${got%%|*}'"

# ── (4) the old prose path is untouched ───────────────────────────────────────────────────
printf '%s\n' "$TTY_LINE" > "$WORK/tty.txt"
got="$(verdict "$WORK/tty.txt")"
[ "${got%%|*}" = "unverifiable" ] \
  && pass "timeout + the bubbletea TTY diagnostic -> unverifiable (GH-375 follow-up, unchanged)" \
  || fail "the prose TTY path regressed, got '${got%%|*}'"

# ── (5) agy 1.1.16's new prose wording is recognised too ──────────────────────────────────
printf '%s\n' "$RAWMODE_LINE" > "$WORK/rawmode.txt"
got="$(verdict "$WORK/rawmode.txt")"
[ "${got%%|*}" = "unverifiable" ] \
  && pass "timeout + 'error entering raw mode' -> unverifiable (agy 1.1.16 wording)" \
  || fail "the 1.1.16 TTY wording must read as a TTY failure, got '${got%%|*}'"

# ── the classifier itself ─────────────────────────────────────────────────────────────────
got="$(python3 -c 'from rtl import agy_tui_takeover_only as t; print(t("plain text, no escapes"))')"
[ "$got" = "False" ] \
  && pass "plain text is not a takeover" \
  || fail "plain text must not classify as a terminal takeover, got '$got'"

got="$(python3 -c 'import sys; from rtl import strip_ansi; print(repr(strip_ansi(sys.argv[1])))' "$TAKEOVER")"
[ "$got" = "''" ] \
  && pass "strip_ansi leaves nothing readable in a pure takeover sequence" \
  || fail "strip_ansi left residue in a pure escape sequence: $got"

# ── pre-fix replay: prove this test would have caught it ──────────────────────────────────
# Neutralise ONLY the new marker tuple — that is precisely the pre-fix classifier — and confirm the
# takeover capture goes back to blocking the lane.
got="$(python3 - "$WORK/takeover.txt" <<'PY'
import sys
import rtl
rtl.AGY_TUI_TAKEOVER_MARKERS = ()
s, _ = rtl.agy_auth_timeout_verdict(sys.argv[1])
print(s)
PY
)"
[ "$got" = "failed" ] \
  && pass "pre-fix replay: without the takeover markers the same capture blocks the lane (exit 5)" \
  || fail "pre-fix replay did not reproduce the block, got '$got'"

echo "agy-tui-takeover-verdict: $PASS pass, $FAIL fail"
