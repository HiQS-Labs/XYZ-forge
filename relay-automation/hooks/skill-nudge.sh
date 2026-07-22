#!/usr/bin/env bash
#
# skill-nudge.sh — non-blocking, prompt-time pointers to existing marathon skills.
#
# UserPromptSubmit is intentionally used instead of SessionStart: the nudge is relevant only
# when the operator is about to repeat marathon lifecycle ceremony. The deliberately narrow
# keyword table is:
#   - add ... to [the] marathon / fire [the] marathon -> marathon-triage
#   - preflight sweep / preflight all / dry-run each plan -> marathon-triage
#   - commit and push + close ... issue(s), move ... to 3-COMPLETED, or PDDA sweep
#       -> loose-ends + marathon-cleanup
# Unrelated prompts stay silent so this remains a useful pointer rather than a general nag.
#
# Contract:
#   - ALWAYS non-blocking: exit 0, never changes files, never asks-then-acts.
#   - On a match, emit one UserPromptSubmit additionalContext line; otherwise emit nothing.
#   - Opt out with XYZ_NO_SKILL_NUDGE=1.
#   - Fail-open: missing Python, malformed JSON, or an unexpected payload -> silent exit 0.
set -u

if [ -n "${XYZ_NO_SKILL_NUDGE:-}" ]; then
  cat >/dev/null 2>&1 || true
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  cat >/dev/null 2>&1 || true
  exit 0
fi

python3 -c '
import json
import re
import sys


def natural_join(items):
    if len(items) == 1:
        return items[0]
    return ", ".join(items[:-1]) + " and " + items[-1]


try:
    event = json.load(sys.stdin)
    prompt = event.get("prompt", "")
    if not isinstance(prompt, str):
        raise ValueError("prompt must be a string")

    normalized = " ".join(prompt.lower().split())
    skills = []

    triage_match = any(
        (
            re.search(r"\badd\b.*\bto\b.*\bmarathon\b", normalized),
            re.search(r"\bfire (?:the )?marathon\b", normalized),
            re.search(r"\bpreflight (?:sweep|all)\b", normalized),
            re.search(r"\bdry[- ]run each plan\b", normalized),
        )
    )
    if triage_match:
        skills.append("marathon-triage")

    commit_and_push = re.search(r"\bcommit(?: and |\s*&\s*)push\b", normalized)
    closeout_detail = any(
        (
            re.search(r"\bclose\b.*\bissues?\b", normalized),
            re.search(r"\bmove\b.*\bto 3[- ]completed\b", normalized),
            re.search(r"\bpdda sweep\b", normalized),
        )
    )
    if commit_and_push and closeout_detail:
        skills.extend(("loose-ends", "marathon-cleanup"))

    if skills:
        names = natural_join(skills)
        refs = natural_join([f"skills/{skill}/SKILL.md" for skill in skills])
        verb = "does" if len(skills) == 1 else "do"
        context = f"BTW: {names} already {verb} this — see {refs}."
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": context,
            }
        }, separators=(",", ":")))
except Exception:
    pass
' 2>/dev/null || true

exit 0
