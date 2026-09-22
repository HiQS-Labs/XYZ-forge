#!/usr/bin/env bash
# test/gh678-installer-live-links.sh — GH-678: no skill installer may replace a live symlink it does
# not own; a dangling one is still cleaned. Every run is contained in a sandbox HOME.
source "$(dirname "$0")/_setup.sh" gh678-installer-live-links

REPO="$(cd "$(dirname "$0")/.." && pwd)"
echo "== test: gh678-installer-live-links =="

FOREIGN="$WORK/foreign-owner"          # stands in for a managed collection or another clone
mkdir -p "$FOREIGN"; echo "foreign" > "$FOREIGN/SKILL.md"
n=0
for installer in "$REPO"/skills/*/*/install.sh; do   # skills/<tier>/<name> (GH-744)
  skill="$(basename "$(dirname "$installer")")"
  n=$((n+1))
  H="$WORK/home-$skill"; A="$H/apps"
  mkdir -p "$A/claude" "$A/codex" "$A/gemcfg" "$A/antigrav" "$A/antigravcli" "$A/agents"
  # Every target variable the 22 installers read, all inside the sandbox; HOME too, so a target
  # added later without a matching variable still cannot escape (the GH-678 leak shape).
  run() { HOME="$H" CLAUDE_SKILLS_DIR="$A/claude" CODEX_SKILLS_DIR="$A/codex" \
          GEMINI_CONFIG_SKILLS_DIR="$A/gemcfg" ANTIGRAVITY_SKILLS_DIR="$A/antigrav" \
          ANTIGRAVITY_CLI_SKILLS_DIR="$A/antigravcli" AGENTS_SKILLS_DIR="$A/agents" \
          bash "$installer" >"$WORK/out-$skill" 2>&1; }

  # 1. live foreign link: refused, untouched, nonzero exit
  ln -s "$FOREIGN" "$A/claude/$skill"
  run; rc=$?
  if [ "$rc" -ne 0 ] && [ "$(readlink "$A/claude/$skill")" = "$FOREIGN" ]; then
    pass "$skill: refuses a live foreign link (exit $rc, link untouched)"
  else
    fail "$skill: replaced or accepted a live foreign link (exit $rc, now -> $(readlink "$A/claude/$skill" 2>/dev/null)): $(tail -3 "$WORK/out-$skill")"
  fi

  # 2. dangling link: replaced with this installer's own directory, exit 0
  rm -f "$A/claude/$skill"; ln -s "$WORK/nowhere/$skill" "$A/claude/$skill"
  run; rc=$?
  if [ "$rc" -eq 0 ] && [ "$(readlink "$A/claude/$skill")" -ef "$(dirname "$installer")" ]; then
    pass "$skill: replaces a dangling link"
  else
    fail "$skill: dangling link not replaced (exit $rc, now -> $(readlink "$A/claude/$skill" 2>/dev/null)): $(tail -3 "$WORK/out-$skill")"
  fi


done
[ "$n" -gt 0 ] && pass "matrix covered all $n discovered installers" || fail "no installers discovered"
