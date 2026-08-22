---
gh_issue: 135
source: https://github.com/HiQS-Suite/XYZ-forge/issues/135
title: "fix(consult): agy auth pre-flight still fatal on a non-zero whoami exit — the #130 gap"
status: Active (2-WORKING — built 2026-08-22)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: bugfix
effort: 1
complexity: 2
risk: 2
goal: >
  Route consult.py's non-zero whoami probe exits through the shared three-state verdict
  (rtl.agy_auth_output_verdict), so a CLI that rejects the subcommand (agy 1.1.18 usage error,
  exit 2) is classified unverifiable and non-blocking instead of killing the consult's agy seat
  with a wrong "run agy login" remedy. Genuine credentials errors and silent non-zero exits stay
  fatal.
---

# GH-135: consult.py's agy auth pre-flight — the #130 gap

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-22 on `fix/gh135-140-followups-2026-08-22`** — `consult.py`'s `CalledProcessError` branch now runs the captured output through `agy_auth_output_verdict`; usage errors write a NOTE into the consult log and return True, everything else keeps the fatal branch with the remedy text. Pinned by `test/synthetic/gh130-agy-auth-whoami.sh` case 6 (usage stub → True + NOTE; credentials stub → False + remedy). | Land with the GH-135..140 follow-up PR; the issue closes when that PR merges. |

## The defect

Identical shape to #130 in `agy-turn.py`, unfixed in the sibling caller: `subprocess.run([agy_bin,
"whoami"], check=True)` raising `CalledProcessError` went to a branch that wrote "auth pre-flight
failed (exit N). Run `agy login` …" and returned False — on a machine whose auth was never in
question. The exit-0 path already used the shared verdict, so only the non-zero branch needed the
same routing.

## Verification

`bash test/synthetic/gh130-agy-auth-whoami.sh` — 11/0 including the four case-6 assertions;
control: case 6's first assertion fails on the pre-fix tree (the exact #135 defect).
