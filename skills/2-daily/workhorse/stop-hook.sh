#!/usr/bin/env bash
# stop-hook.sh — Claude Code Stop hook for /workhorse (GH-911, GH-983). Wired from SKILL.md frontmatter.
#
# Blocks the stop while this session's run checklist (<repo-root>/.workhorse/<session_id>.md) still has an
# open `- [ ]` line, or a ticked `- [x]` line that carries no `evidence:` pointer, so a direct /workhorse
# run keeps going until its queue is resolved WITH evidence. Everything else (no checklist, other session,
# bad input, missing python3/git) fails OPEN: exit 0, no output, stop allowed.
# Loop safety is the harness's 8-consecutive-continuation cap plus the `[!]` hand-back in the checklist.
# `[-]` is for optional/user-deferred items only (SKILL.md Rung 0) and is never offered as an escape here.
# This is a syntax gate: it checks that evidence was RECORDED, not that it is TRUE (SKILL.md owns that).

command -v python3 >/dev/null 2>&1 || exit 0

# The heredoc below is python's stdin, so hand the hook's JSON input over in the environment.
WORKHORSE_HOOK_INPUT="$(cat)" python3 - <<'PY' || exit 0
import json, os, re, subprocess, sys

try:
    data = json.loads(os.environ.get("WORKHORSE_HOOK_INPUT", ""))
    sid = data.get("session_id")
    cwd = data.get("cwd")
except Exception:
    sys.exit(0)
if not isinstance(sid, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", sid):
    sys.exit(0)

roots = []
if isinstance(cwd, str) and cwd:
    try:
        top = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, timeout=5).stdout.strip()
        if top:
            roots.append(top)
    except Exception:
        pass
if os.environ.get("CLAUDE_PROJECT_DIR"):
    roots.append(os.environ["CLAUDE_PROJECT_DIR"])

TICKED = re.compile(r"-\s\[[xX]\]")
EVIDENCE = re.compile(r"evidence:\s*\S", re.IGNORECASE)

def preview(items):
    return "\n".join(items[:5]) + ("\n…" if len(items) > 5 else "")

for root in roots:
    path = os.path.join(root, ".workhorse", sid + ".md")
    try:
        with open(path, encoding="utf-8") as fh:
            lines = [l.strip() for l in fh]
    except Exception:
        continue
    open_items = [l for l in lines if l.startswith("- [ ]")]
    unevidenced = [l for l in lines if TICKED.match(l) and not EVIDENCE.search(l)]
    reasons = []
    if open_items:
        reasons.append("still has %d open item(s):\n%s\nContinue with the next open item."
                       % (len(open_items), preview(open_items)))
    if unevidenced:
        reasons.append("has %d ticked item(s) with no evidence pointer:\n%s\n"
                       "Append ` — evidence: <path, commit, URL, or quoted output>` to each after verifying it, "
                       "or reopen it as `- [ ]` if it is not actually done."
                       % (len(unevidenced), preview(unevidenced)))
    if reasons:
        print(json.dumps({"decision": "block", "reason":
            "/workhorse run checklist %s %s\n"
            "To hand back to the operator instead, mark the item [!] with the exact blocker or decision "
            "needed. [-] is only for optional or explicitly user-deferred items, never required scope."
            % (path, "\n".join(reasons))}))
    sys.exit(0)
PY
exit 0
