#!/usr/bin/env bash
# test/gh401-dry-run-no-mutation.sh — GH-401 regression.
#
# `marathon-drive --dry-run` used to RENDER AND WRITE phases/<id>/RELAY.md before reaching its exit,
# so a dry run mutated the working tree. Unscoped (no MARATHON_ROOT, no --phases-dir) that landed on
# the HARNESS repo's own tracked phases/p1/RELAY.md: `bash validate.sh` left the tree dirty, the diff
# churned to a different value on every machine (it embeds the absolute bin/tick path), and the
# rendered artifact was committed at least once that way (f83b929, #325).
#
# A dry run being side-effect free is the entire contract of the flag, and it is the flag someone
# reaches for precisely when they are unsure what a command will do.
#
# WHY A FIXTURE ROOT, NOT THE UNSCOPED REPRO: the write is unconditional on which root it resolves to,
# so aiming the same code path at a throwaway MARATHON_ROOT proves the same property — and a
# regression can never dirty the real repo just by running the suite (which is how the polluted file
# got committed in the first place). The static half of this fix — that no test invokes the driver
# unscoped at all — is test/marathon-root-audit.sh, whose scope GH-401 widened from two hardcoded
# filenames to every test script.
source "$(dirname "$0")/_setup.sh" gh401-dry-run-no-mutation
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRV="$ROOT/relay-automation/marathon-drive.sh"

mk_repo() {  # <dir>
  mkdir -p "$1"; git init -q "$1"
  git -C "$1" config user.email gh401@t; git -C "$1" config user.name gh401
  printf 'x\n' > "$1/seed.txt"
  git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -q -m init
}

MROOT="$WORK/mroot"; mk_repo "$MROOT"
TGT="$WORK/target";  mk_repo "$TGT"
BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"

before="$(git -C "$MROOT" status --porcelain)"
out="$(MARATHON_ROOT="$MROOT" bash "$DRV" --target-root "$TGT" --phase-brief "$BRIEF" \
        --reviewer agy --builder codex --dry-run 2>&1)"; rc=$?
after="$(git -C "$MROOT" status --porcelain)"

[ "$rc" -eq 0 ] && pass "--dry-run exits 0" || fail "--dry-run exited $rc: $out"

[ "$before" = "$after" ] \
  && pass "--dry-run leaves the marathon root's git status unchanged" \
  || fail "--dry-run dirtied the marathon root (porcelain: $after)"

[ ! -e "$MROOT/phases" ] \
  && pass "--dry-run creates no phases/ directory" \
  || fail "--dry-run created $MROOT/phases — the mkdir is back above the dry-run exit"

# POSITIVE CONTROL. Without this the two assertions above would also pass for a driver that died
# long before the render — "nothing was written" would prove nothing about the write being skipped
# deliberately. This repo has shipped three separate assertions that could not fail (#333, #348,
# #351); an assertion whose green state has two explanations is the same defect in slower motion.
printf '%s' "$out" | grep -Fq "would be rendered" \
  && pass "--dry-run still performs the render and reports it (the write, and only the write, is skipped)" \
  || fail "--dry-run printed no render report — it exited before the render, so the no-mutation assertions above are vacuous: $out"

exit 0
