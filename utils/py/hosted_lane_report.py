#!/usr/bin/env python3
"""hosted_lane_report.py — one labelled issue tracks the hosted wave-reconcile lane (GH-684).

Runs as the last step of .github/workflows/wave-reconcile.yml (`if: always()`), after the job's
own status is known, and reads the reconcile step's log from $RUNNER_TEMP. It never touches the
repository tree and never writes anywhere but GitHub issues carrying its label:

  status != success  OR  any `wave-reconcile: SKIPPED …` line (in either log)
      -> exactly one open issue labelled hosted-reconcile-attention: create it if none is open,
         otherwise comment on it. The body carries the run URL, the job status, the terminal error
         of the step that failed (or says none was captured) and every skip line.
  status == success  AND  no skip lines
      -> if such an issue is open, comment "green" and close it; otherwise no mutating call.

`job.status` (not the reconcile step's outcome) is what the workflow passes, so a successful
reconcile followed by a rejected fast-forward push still reports as red. The skip literal is
imported from wave_reconcile so the emitter and this consumer cannot drift. stdlib + `gh` only.

Attribution (GH-741): the reconcile log of a `--qualify` run contains the whole test suite's
output, and gh421's unit tests deliberately print `wave-reconcile: ERROR — …` lines that end in
`ok`. The last such line is the run's failure only when the reconcile step itself failed. So the
terminal error is chosen by step outcome (`steps.<id>.outcome`, passed by the workflow):
reconcile step not `success` -> its last `wave-reconcile: ERROR — ` line; else publish step not
`success` -> the publish log's last `hosted-lane-publish: ERROR — ` line (falling back to its last
non-empty line, e.g. a raw `git` rejection); else none. Without outcomes (older callers) the
reconcile-log scan is used as before.
"""
import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wave_reconcile import SKIP_MARKER  # noqa: E402  — one literal, shared with the emitter

DEFAULT_LABEL = "hosted-reconcile-attention"
ERROR_PREFIX = "wave-reconcile: ERROR — "
PUBLISH_ERROR_PREFIX = "hosted-lane-publish: ERROR — "
SKIP_PREFIX = "wave-reconcile: " + SKIP_MARKER
TITLE = "Hosted wave-reconcile lane needs attention"


def gh(*args):
    """Run one gh command; stdout on success, a clear error on failure."""
    result = subprocess.run(["gh", *args], capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise SystemExit(f"hosted-lane-report: gh {' '.join(args[:2])} failed (exit {result.returncode}): "
                         f"{result.stderr.strip()}")
    return result.stdout


def read_log(path):
    """The log is optional evidence: a run that died before the tee still gets reported."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return [line.rstrip("\n") for line in f]
    except OSError:
        return []


def summarize(lines):
    """(last terminal error line or None, every skip line in order)."""
    errors = [line for line in lines if line.startswith(ERROR_PREFIX)]
    skips = [line for line in lines if line.startswith(SKIP_PREFIX)]
    return (errors[-1] if errors else None), skips


def terminal_error(reconcile_outcome, reconcile_lines, publish_outcome, publish_lines):
    """(step, message) for the step that failed, or (None, None). GH-741.

    A green reconcile step's ERROR lines are test output, never the cause of a later failure, so
    they are only consulted when that step itself was not `success`. `None` outcomes (an older
    workflow) keep the reconcile-log scan.
    """
    if reconcile_outcome is None or reconcile_outcome != "success":
        error, _ = summarize(reconcile_lines)
        if error:
            return "reconcile", error[len(ERROR_PREFIX):]
        if reconcile_outcome is not None:
            return "reconcile", None
    if publish_outcome is not None and publish_outcome != "success":
        errors = [line for line in publish_lines if line.startswith(PUBLISH_ERROR_PREFIX)]
        if errors:
            return "publish", errors[-1][len(PUBLISH_ERROR_PREFIX):]
        tail = [line for line in publish_lines if line.strip()]
        return "publish", (tail[-1].strip() if tail else None)
    return None, None


def open_issue_number(label):
    """The one open issue carrying the label, or None. Discovery only; never mutates."""
    out = gh("issue", "list", "--label", label, "--state", "open", "--json", "number", "--limit", "5")
    numbers = sorted(int(item["number"]) for item in json.loads(out or "[]"))
    return numbers[0] if numbers else None


def body_for(status, run_url, error, skips, step=None):
    lines = [f"Run: {run_url}", f"Job status: `{status}`", ""]
    where = f" (step: {step})" if step else ""
    lines.append(f"Terminal error{where}: `{error}`" if error
                 else f"Terminal error{where}: none captured (the run may have failed before or after the reconcile step).")
    if skips:
        lines += ["", f"Skipped backlog item(s) ({len(skips)}) — fix the doc and the next run retries:"]
        lines += [f"- `{line[len('wave-reconcile: '):]}`" for line in skips]
    lines += ["", "This issue is opened and closed by `utils/py/hosted_lane_report.py` (GH-684); "
              "it closes itself on the next green run with no skips."]
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--status", required=True, help="the job's status (success|failure|cancelled)")
    parser.add_argument("--log", required=True, help="path of the tee'd reconcile log (may be missing)")
    parser.add_argument("--run-url", required=True, help="URL of this workflow run")
    parser.add_argument("--label", default=DEFAULT_LABEL)
    # GH-741: step outcomes decide which log's error is the run's cause; both logs supply skips.
    parser.add_argument("--reconcile-outcome", help="steps.reconcile.outcome (success|failure|cancelled|skipped)")
    parser.add_argument("--publish-outcome", help="steps.publish.outcome")
    parser.add_argument("--publish-log", help="path of the tee'd publish log (may be missing)")
    args = parser.parse_args(argv)

    reconcile_lines = read_log(args.log)
    publish_lines = read_log(args.publish_log) if args.publish_log else []
    step, error = terminal_error(args.reconcile_outcome, reconcile_lines, args.publish_outcome, publish_lines)
    skips = summarize(reconcile_lines)[1] + summarize(publish_lines)[1]
    attention = args.status != "success" or bool(skips)
    number = open_issue_number(args.label)

    if attention:
        body = body_for(args.status, args.run_url, error, skips, step)
        if number is None:
            gh("label", "create", args.label, "--force", "--color", "B60205",
               "--description", "the hosted wave-reconcile lane is red or skipped a backlog item (GH-684)")
            gh("issue", "create", "--title", TITLE, "--label", args.label, "--body", body)
            print(f"hosted-lane-report: opened a {args.label} issue ({args.status}, {len(skips)} skipped)")
        else:
            gh("issue", "comment", str(number), "--body", body)
            print(f"hosted-lane-report: commented on #{number} ({args.status}, {len(skips)} skipped)")
        return 0

    if number is not None:
        gh("issue", "comment", str(number), "--body", f"Green at {args.run_url} — no skipped items. Closing.")
        gh("issue", "close", str(number))
        print(f"hosted-lane-report: lane green; closed #{number}")
    else:
        print("hosted-lane-report: lane green; nothing open")
    return 0


if __name__ == "__main__":
    sys.exit(main())
