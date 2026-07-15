#!/usr/bin/env bash
set -euo pipefail
#
# new-relay.sh — scaffold a single-artifact review relay thread (GH-31 Phase 4).
#
# Emits a relay thread the harness can drive: NEXT:/STATUS: header, a "▶ TAKE YOUR TURN" block, a
# Setup that names the artifact under review, ground rules, and an empty Log with the next-turn marker.
#
# Two artifact modes:
#   (default, reference) — the Setup points at .relay-artifacts/<basename>, the read-only path that
#       `relay-drive.sh --artifact-file <source>` seeds into the isolated worktree (GH-31 Phase 2 / #15).
#   --embed              — inline the artifact's bytes in a FENCE-SAFE code block (GH-31 Phase 3): the
#       fence is chosen LONGER than the longest backtick run inside the file, so an artifact that itself
#       contains ```fenced``` markdown can't break out of the block.
#
# Usage:
#   relay-automation/new-relay.sh --title T --reviewer AGENT [--artifact-file P] [--embed]
#       [--producer AGENT] [--round-cap N] [--slug S] [--out PATH | --print]
#
# Exit: 0 ok · 2 usage.

die() { printf 'new-relay: %s\n' "$*" >&2; exit 2; }

TITLE="" REVIEWER="" PRODUCER="claude-a" ARTIFACT="" EMBED=0 ROUND_CAP=4 SLUG="" OUT="" PRINT=0
while (($# > 0)); do
  case "$1" in
    --title) TITLE="${2:-}"; shift 2 ;;
    --reviewer) REVIEWER="${2:-}"; shift 2 ;;
    --producer) PRODUCER="${2:-}"; shift 2 ;;
    --artifact-file) ARTIFACT="${2:-}"; shift 2 ;;
    --embed) EMBED=1; shift ;;
    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
    --slug) SLUG="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --print) PRINT=1; shift ;;
    --help) sed -n '2,30p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ -n "$TITLE" ]]    || { die "--title is required"; }
[[ -n "$REVIEWER" ]] || { die "--reviewer is required"; }
(( EMBED == 0 )) || [[ -n "$ARTIFACT" ]] || die "--embed requires --artifact-file"
# --embed reads the file now, so it must exist. Reference mode only records the path (the artifact
# may not exist yet — relay-drive seeds it at turn time), so it is NOT required to exist at scaffold.
(( EMBED == 0 )) || [[ -f "$ARTIFACT" ]] || die "artifact file not found (required for --embed): $ARTIFACT"

# Fence longer than the longest backtick run inside <file>, min 3 (GH-31 Phase 3 — fence-collision safe).
fence_for() {
  local f="$1" longest=0
  longest="$(grep -oE '`+' "$f" 2>/dev/null | awk '{ if (length>m) m=length } END { print m+0 }' || true)"
  [[ -n "$longest" ]] || longest=0
  local n=$((longest + 1)); (( n < 3 )) && n=3
  printf '%*s' "$n" '' | tr ' ' '`'
}

slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//'; }
[[ -n "$SLUG" ]] || SLUG="$(slugify "$TITLE")"
TODAY="$(date +%F)"

art_base=""; [[ -n "$ARTIFACT" ]] && art_base="$(basename "$ARTIFACT")"

emit() {
  cat <<EOF
# RELAY · $TITLE
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on $TODAY.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / $ROUND_CAP

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** \`NEXT\` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (\`[Blocker]\`/\`[Should]\`/\`[Nit]\`/\`[Pass]\`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any \`[Pass]\` or "verified"/"confirmed" finding MUST
     carry a quoted span or a \`file:line\` citation — an uncited one is mechanically downgraded to
     \`[Unverified — no citation]\` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip \`NEXT\`; set \`STATUS\` (\`Approved\` closes — Reviewer only; else \`Open\`);
   the Producer bumps \`ROUND\` when opening a new cycle. If the max \`ROUND\` ends without \`Approved\`,
   set \`STATUS: Escalated\`.
6. **Commit only the relay file** (\`relay($SLUG): <role> r<N>\`); no push. **Stop** and report one line.

## Setup
EOF

  if (( EMBED )); then
    local fence; fence="$(fence_for "$ARTIFACT")"
    cat <<EOF
- Artifact under review: **$art_base** (embedded below — read it here).
- Reviewer: $REVIEWER   ·   Producer: $PRODUCER
- Started: $TODAY

### Artifact — $art_base
$fence
$(cat "$ARTIFACT")
$fence
EOF
  elif [[ -n "$ARTIFACT" ]]; then
    cat <<EOF
- Artifact under review: **.relay-artifacts/$art_base** — the read-only path that
  \`relay-drive.sh --artifact-file $ARTIFACT\` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: $REVIEWER   ·   Producer: $PRODUCER
- Started: $TODAY
EOF
  else
    cat <<EOF
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: $REVIEWER   ·   Producer: $PRODUCER
- Started: $TODAY
EOF
  fi

  cat <<EOF
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if \`NEXT\` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
EOF
}

if (( PRINT )); then
  emit
  exit 0
fi

# GH-30 Phase 3: when XYZ_ARCHIVE_ROOT is set, default the thread location through the transcript-root
# resolver so a scaffolded thread lands in the archive ($XYZ_ARCHIVE_ROOT/relay-system/<slug>/…) — the
# same redirect the other transcript writers already honor (Phase 2). Unset var → byte-for-byte the
# prior relative "relay-system/$TODAY/$SLUG.md" default (kept so the default path stays cwd-relative).
# An explicit --out still wins (resolver not consulted). The resolver fails loud on a set-but-invalid
# archive, so a bad var never silently writes into the cwd.
if [[ -z "$OUT" ]]; then
  if [[ -n "${XYZ_ARCHIVE_ROOT:-}" ]]; then
    # shellcheck source=relay-turn-lib.sh
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/relay-turn-lib.sh"
    _nr_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    _nr_base="$(rtl_transcript_root "$_nr_root")" || exit 1
    OUT="$_nr_base/$TODAY/$SLUG.md"
  else
    OUT="relay-system/$TODAY/$SLUG.md"
  fi
fi
mkdir -p "$(dirname "$OUT")"
emit >"$OUT"
printf 'new-relay: wrote %s (NEXT: Reviewer, reviewer=%s%s)\n' "$OUT" "$REVIEWER" "$( ((EMBED)) && printf ', embedded' || true )" >&2
printf '%s\n' "$OUT"
