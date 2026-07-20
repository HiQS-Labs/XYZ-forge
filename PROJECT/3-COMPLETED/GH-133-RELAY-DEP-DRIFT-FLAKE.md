---
gh_issue: 133
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/133
title: "flaky: relay-dep-drift.sh case 4 'turn still committed' fails ~1-in-3, reproducible on untouched main"
status: Closed — Proposed (1-INBOX — not yet active)
created: 2026-07-05
updated: 2026-07-05
owner: noel
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not touching the drift-detection logic itself (`rtl_drift_brief`/`rtl_enforce`) — the drift
    events themselves assert fine; only the commit-presence assertion after them flakes.
  - Not a broader flaky-test sweep — `oracle-guard.sh`/`improve-loop-qa.sh` are a separate,
    already-documented order-dependent flake family (see ROADMAP 2026-07-04 status note).
related:
  - test/relay-dep-drift.sh
  - relay-automation/relay-turn-lib.sh
  - test/worktree-isolation.sh   # documents the same SIGPIPE-prone `| grep -q` pattern in comments
---

# GH-133 · flaky: relay-dep-drift.sh case 4 "turn still committed" fails ~1-in-3

**Why:** `validate.sh` intermittently fails on `test/relay-dep-drift.sh` only, always on the same
assertion — case 4's `"turn still committed (warn-only, non-blocking)"`
([test/relay-dep-drift.sh:86](../../test/relay-dep-drift.sh#L86)):

```bash
ok "turn still committed (warn-only, non-blocking)" "git -C '$D2' log --oneline | grep -q 'RELAY-T'"
```

Characterization already done (2026-07-04, captured in the issue): 5 standalone runs on the branch
gave 2 failures (same assertion); 5 standalone runs on **untouched `main`** gave 1 failure — a
zero-diff confirmation the flake pre-exists any recent lane, using the same method as the GH-114
confirmation. It also flakes **standalone** (not just under suite ordering), so it's state/timing
inside the fixture, not test ordering — a different family from the `oracle-guard.sh` /
`improve-loop-qa.sh` order-dependent flakes.

The assertion uses the exact `git log --oneline | grep -q` pattern that `test/worktree-isolation.sh`'s
own comment already documents as SIGPIPE-prone (`grep -q` can close its end of the pipe as soon as it
finds a match, sending `git log`'s writer a SIGPIPE under `pipefail`) — but the 2-commit fixture here
makes that explanation uncertain: it isn't proven whether the commit itself is sometimes absent (a
real containment/timing bug) or only the check misfires (a test-hygiene bug). Needs a real trace
before choosing a fix.

## Fix direction (not yet chosen)

1. **If it's the SIGPIPE explanation:** avoid the pipe — capture the log output to a variable first
   (`out="$(git -C "$D2" log --oneline)"; grep -q 'RELAY-T' <<<"$out"`), matching the fix class already
   used elsewhere for this pattern.
2. **If the commit is genuinely sometimes missing:** trace `rtl_enforce`'s commit path in the fixture
   to find the real race, which would make this a containment-timing bug, not test hygiene — escalate
   complexity/risk accordingly if so.

Step 1 is cheap and safe regardless; do it first, then re-run the 5×5 standalone-on-main
characterization to see whether the flake rate actually drops to confirm which explanation was right.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash test/relay-dep-drift.sh","fix_probes":[{"type":"grep_present","path":"test/relay-dep-drift.sh","pattern":"log --oneline \\| grep -q"}],"artifacts":["test/relay-dep-drift.sh"],"remediation":{"source":"self#fix-direction","criteria":"Case 4's commit-presence assertion no longer uses the SIGPIPE-prone `| grep -q` pipe (or the real timing race behind it is fixed); a 5x5 standalone-on-main re-run shows zero flakes."},"lanes":{"orchestrator_only":[]}}
```
