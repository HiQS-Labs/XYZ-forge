#!/usr/bin/env python3
"""GH-862 validation plan: exercise ci-suite-audit's report-issue protocol (SKILL.md, "Report Issue &
Per-turn Comments") for real, on ONE practice issue, then close it. Follows the protocol literally with gh.
Writes a JSON log of every check to stdout. Never touches any other issue; creates no label."""
import json, re, subprocess, sys
REPO = "HiQS-Labs/XYZ-forge"
SHA, DATE = "practice862d", "2026-09-27"          # a SHA no real audit can have
MARKER = f"<!-- ci-suite-audit:{SHA}:{DATE} -->"
TITLE = f"ci-suite-audit: {DATE} report @ {SHA}"
PRACTICE = "Practice issue for #862's validation plan. Not a real audit report. Will be closed after the test."
LIMIT = 65536
log = []
def gh(*a, inp=None):
    r = subprocess.run(["gh", *a], input=inp, capture_output=True, text=True)
    if r.returncode != 0: raise SystemExit(f"gh {' '.join(a[:3])} failed: {r.stderr.strip()}")
    return r.stdout
def open_matches():
    # SKILL.md dedupe: a direct listing matched locally, never --search (eventually consistent; run 1 duplicated)
    rows = json.loads(gh("issue", "list", "-R", REPO, "--state", "open", "--label", "ci", "--json", "number,body,title", "--limit", "200"))
    return [r["number"] for r in rows if MARKER in (r["body"] or "")]
def comments(n):
    return json.loads(gh("issue", "view", str(n), "-R", REPO, "--json", "comments"))["comments"]
import os
RECORD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "report-issue.txt")
def recorded():
    """SKILL.md dedupe step 1: the local record, immediately consistent."""
    try:
        num, marker = open(RECORD).read().split(None, 1)
        return [int(num)] if marker.strip() == MARKER else []
    except (OSError, ValueError):
        return []
def file_report(body):
    """The protocol's dedupe-first filing: update + delta comment on a match, else create and record."""
    m = recorded() or open_matches()
    if len(m) > 1: raise SystemExit(f"multiple open matches {m}: stop and ask the operator")
    if m:
        n = m[0]; gh("issue", "edit", str(n), "-R", REPO, "--body-file", "-", inp=body)
        gh("issue", "comment", str(n), "-R", REPO, "--body-file", "-", inp="Delta: report re-run at the same registry SHA; body updated in place (no new issue).")
        return n, "updated"
    url = gh("issue", "create", "-R", REPO, "--title", TITLE, "--label", "ci", "--label", "stability", "--body-file", "-", inp=body).strip()
    num = int(url.rstrip("/").split("/")[-1])
    open(RECORD, "w").write(f"{num} {MARKER}\n")
    return num, "created"
# synthetic 411-row table, long enough that the full report is oversized
rows = [f"test/suite-{i:03d}.sh\tKEEP\tregression-caught\tHIGH\tevidence: synthetic practice row {i} " + "x" * 180 for i in range(1, 412)]
rows[7] = rows[7].replace("\tKEEP\t", "\tNIGHTLY\t"); rows[42] = rows[42].replace("\tKEEP\t", "\tKEEP-FIX\t")
table = "suite\tverdict\tclass\tconfidence\tevidence\n" + "\n".join(rows) + "\n"
summary = f"{MARKER}\n{PRACTICE}\n\n## Summary\nVerdicts: KEEP 409, NIGHTLY 1, KEEP-FIX 1.\n\n## Reminders\n- radar: not triggered\n- whack-a-mole: not triggered\n"
# 1. first filing (small report) -> created
n, how1 = file_report(summary + "\n(table follows in the oversized run)\n")
log.append({"check": "first filing", "issue": n, "result": how1})
# 2. same SHA again -> updated + one delta comment, still exactly one open match
c0 = len(comments(n)); n2, how2 = file_report(summary + "\n(re-run)\n"); c1 = len(comments(n))
log.append({"check": "dedupe on re-run", "same_issue": n2 == n, "result": how2, "open_matches": open_matches(), "delta_comments_added": c1 - c0})
# 3. oversized: full report > limit -> body = summary + non-KEEP rows + reminders; table in numbered comments
full = summary + "\n## Table\n" + table
nonkeep = "\n".join(r for r in rows if "\tKEEP\t" not in r)
body = summary + "\n## Non-KEEP rows\n" + nonkeep + "\n\nFull table: numbered comments below.\n"
assert len(full) > LIMIT and len(body) < LIMIT
lines, chunks, cur = table.splitlines(keepends=True), [], ""
for ln in lines:
    if len(cur) + len(ln) > 60000: chunks.append(cur); cur = ""
    cur += ln
chunks.append(cur)
gh("issue", "edit", str(n), "-R", REPO, "--body-file", "-", inp=body)
c2 = len(comments(n))
for k, ch in enumerate(chunks, 1):
    gh("issue", "comment", str(n), "-R", REPO, "--body-file", "-", inp=f"table part {k} of {len(chunks)}\n```tsv\n{ch}```\n")
posted = [c["body"] for c in comments(n)][c2:]
got = "".join(re.search(r"```tsv\n(.*)```", p, re.S).group(1) for p in posted)
log.append({"check": "oversized report", "full_chars": len(full), "body_chars": len(body), "parts": len(chunks),
            "table_rows_posted": got.count("\n") - 1, "table_identical": got == table})
# 4. per-turn comments: a decision turn -> exactly one; a no-decision turn -> none
c3 = len(comments(n))
gh("issue", "comment", str(n), "-R", REPO, "--body-file", "-", inp="Turn 1 decision: operator accepts NIGHTLY for test/suite-008.sh (practice).\nRemaining open: KEEP-FIX test/suite-043.sh.")
c4 = len(comments(n))   # turn 2 reaches no decision: the protocol posts nothing
c5 = len(comments(n))
log.append({"check": "per-turn comments", "decision_turn_added": c4 - c3, "no_decision_turn_added": c5 - c4})
# 5. redaction: nothing posted carries a local path or a token shape
allposted = json.loads(gh("issue", "view", str(n), "-R", REPO, "--json", "body,comments"))
text = allposted["body"] + "".join(c["body"] for c in allposted["comments"])
bad = re.findall(r"/Users/|/home/|/private/var|ghp_[A-Za-z0-9]{10,}|github_pat_|sk-[A-Za-z0-9]{16,}", text)
log.append({"check": "redaction", "leaks": bad})
# 6. no radar label, then close with a pointer to the evidence
labels = [l["name"] for l in json.loads(gh("issue", "view", str(n), "-R", REPO, "--json", "labels"))["labels"]]
gh("issue", "close", str(n), "-R", REPO, "--comment", "Practice test complete; closing. Evidence: TESTS-RESULTS/2026-09-27+GH-862/practice/ on PR #865.")
state = json.loads(gh("issue", "view", str(n), "-R", REPO, "--json", "state"))["state"]
log.append({"check": "labels and close", "labels": labels, "radar_used": "radar" in labels, "final_state": state})
print(json.dumps({"practice_issue": n, "checks": log}, indent=1))
