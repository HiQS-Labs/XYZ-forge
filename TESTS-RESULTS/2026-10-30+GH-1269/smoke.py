"""GH-1269 manual smoke (GH-1088; evidence script, NOT a registered suite — GH-831).

Usage: python3 smoke.py [<ledger_merge.py to load>]   (default: this checkout's copy)

Drives ledger_merge.union_changelog the way B1 calls it (base = merge base, ours = PR head,
theirs = integration tip; merge_cleanup.py merges origin/<integration> into the PR clone).
The fixture mirrors LTVera PR #874: the integration side added six same-date sections in an
order that is not descending by heading text; the PR added one newer section.
Exit 0 only when every case passes.
"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    REPO, "skills", "2-daily", "merge-cleanup", "scripts", "ledger_merge.py")
sys.path.insert(0, os.path.dirname(os.path.abspath(path)))
spec = importlib.util.spec_from_file_location("ledger_merge_under_test", path)
lm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lm)

PRE = "# Changelog\n\nIntro line.\n\n"
OLD = "## 2026-10-28 — older entry\n\nOlder bytes stay exact.\n"


def sec(heading, body):
    return f"## {heading}\n\n{body}\n\n"


# Integration (development 3c936bea) order, copied from the #1269 heading table shape.
DEV_ADDS = "".join([
    sec("2026-10-29 — GH-867 QA follow-up", "867 QA."),
    sec("2026-10-29 — GH-867 heartbeat", "867."),
    sec("2026-10-29 — GH-866 typing", "866 typing."),
    sec("2026-10-29 — GH-866 store", "866."),
    sec("2026-10-29 — GH-866 resumed", "866 resumed."),
    sec("2026-10-29 — GH-776 klaviyo", "776."),
])
PR_ADD = sec("2026-10-30 — GH-818 landing", "818.")

base = PRE + OLD
theirs = PRE + DEV_ADDS + OLD
ours = PRE + PR_ADD + OLD
expected = PRE + PR_ADD + DEV_ADDS + OLD

failures = 0


def case(label, fn):
    global failures
    try:
        ok, detail = fn()
    except Exception as exc:  # a refusal is a result to report, not a crash
        ok, detail = False, f"raised {type(exc).__name__}: {exc}"
    failures += 0 if ok else 1
    print(f"[{'PASS' if ok else 'FAIL'}] {label}\n       {detail}")


def main_path():
    out = lm.union_changelog(base, ours, theirs)
    heads = [l[3:].split(" — ")[1] for l in out.splitlines() if l.startswith("## 2026-10-29")]
    return out == expected, f"integration same-date order in output: {heads}"


def next_attempt():
    # Attempt 2: the merge base is now the integration tip; theirs is unchanged.
    first = lm.union_changelog(base, ours, theirs)
    again = lm.union_changelog(theirs, first, theirs)
    return again == first, "re-resolving the repaired head against the same tip is a no-op"


def next_attempt_with_new_integration_section():
    # Adjacent: integration moved on with one more section before attempt 2.
    first = lm.union_changelog(base, ours, theirs)
    theirs2 = PRE + sec("2026-10-30 — GH-880 later", "880.") + DEV_ADDS + OLD
    out = lm.union_changelog(theirs, first, theirs2)
    return out == PRE + PR_ADD + theirs2[len(PRE):], "PR block prepended; new integration text verbatim"


def identical_on_both_sides():
    # The PR already carries an integration addition byte-for-byte (an earlier sync): not duplicated.
    ours_synced = PRE + PR_ADD + DEV_ADDS + OLD
    out = lm.union_changelog(base, ours_synced, theirs)
    return out == expected and out.count("818.") == 1 and out.count("776.") == 1, "no duplicate blocks"


def divergent_same_heading_still_hands_off():
    ours_bad = PRE + sec("2026-10-29 — GH-776 klaviyo", "different body.") + OLD
    try:
        lm.union_changelog(base, ours_bad, theirs)
    except ValueError as exc:
        return "same heading" in str(exc), f"ValueError: {exc}"
    return False, "no refusal"


case("main: LTVera #874 shape keeps development's same-date order", main_path)
case("adjacent: attempt 2 on the repaired head does not refuse its own output", next_attempt)
case("adjacent: attempt 2 after development gained a section", next_attempt_with_new_integration_section)
case("adjacent: block already present on both sides is kept once", identical_on_both_sides)
case("guard: different bodies under one heading still hand off", divergent_same_heading_still_hands_off)
print(f"loaded: {os.path.relpath(path, REPO) if path.startswith(REPO) else path}")
print(f"result: {'PASS' if failures == 0 else f'FAIL ({failures})'}")
sys.exit(1 if failures else 0)
