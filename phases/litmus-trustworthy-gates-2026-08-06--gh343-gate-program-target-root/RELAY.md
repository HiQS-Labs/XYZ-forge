# Marathon Phase gh343-gate-program-target-root
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "Phase brief: GH-343 gh343-gate-program-target-root (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-06
updated: 2026-08-06
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the
  gh343-gate-program-target-root phase of MARATHON-2026-08-06-LITMUS — not itself an active-doc
  capture; the canonical capture doc is GH-343-GATE-PROGRAM-TARGET-ROOT.md two levels up.
roadmap_exempt: true
---

# Brief — GH-343: a gate program's verdict must not depend on where the operator was standing

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and verified READY. Acceptance criteria were authored on the issue (it had none) and revised after an adversarial codex+agy review, which caught that "the two branches agree" was satisfiable by making the correct branch wrong. | Fire as marathon phase 2 of 4, after gh419. |

**Parent doc:** `PROJECT/2-WORKING/GH-343-GATE-PROGRAM-TARGET-ROOT.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/343

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block**, copied
verbatim from the issue. Do not work from a paraphrase — see GH-400.

Two of those criteria are traps, and both were added by the adversarial review because the first
draft could be satisfied without fixing anything:

- Making the two branches merely **agree** — by resolving both against the working directory —
  **fails** the criterion rather than satisfying it.
- The regression test must be **observed failing** against the pre-fix revision, with a durable
  record of the reproducer command, the pre-fix revision, and both results. "A sentence asserting a
  negative control happened is not the record" — per #419, which lands in phase 1 of this marathon.

## The defect (verified in source)

`utils/py/swarm_preflight.py:715-732`. The two branches disagree about what a gate path is relative
to:

```python
if g0 in ["bash", "sh"]:
    ...
    if not script or not os.path.isfile(os.path.join(target_root, script)):   # target-relative ✅
        ready, ready_next = 0, f"gate script not found at target.ref: {script or ''}"
elif not shutil.which(g0):                                                     # cwd / PATH ❌
    ready, ready_next = 0, f"command '{g0}' not found in PATH"
```

`shutil.which()` on a string containing a path separator tests that path against the **process's**
working directory. So a contract whose `gate` names `.venv/bin/python` — the natural way to say
"this repo's virtualenv" — reads:

```
readiness : ready=0 — next: command '.venv/bin/python' not found in PATH
verdict   : NOT-READY (exit 5)
```

…from the harness clone, and `ready (exit 0)` from the target repo. Same contract, same file, same
gate command passing in both cases. Only the readiness *check* differs.

**Not a GH-308 regression.** Before GH-308 the Python lane exempted `bash`/`node`/`npm`/`python3`
from the PATH check; a target-relative interpreter was never in that list, so it failed identically.
GH-308 removed the exemptions — correctly, an absent `npm` was passing as ready — and did not touch
this case.

## Why it matters

- **A false NOT-READY silently drops an issue from a sweep.** `/10days` Step 6 treats any non-zero
  exit as a reason to drop, and exit 5 reads as "not marathon-ready" — indistinguishable from a real
  verdict.
- **The gate command is meant to run in the target.** `marathon-drive` executes the pre-advance gate
  with cwd at the target root, so a target-relative program path is correct at execution time.
- **Live blast radius:** 11 of 40 capture docs in `Hypercart-Dev-Tools/rebalance-OS`'s
  `PROJECT/2-WORKING` reference `.venv/bin/python`.

## What to build

Resolve a separator-containing gate program against `target_root` before falling back to a PATH
lookup, mirroring what the `bash`/`sh` branch already does. Two smaller points fold in, both carried
by the acceptance:

- **Executability, not existence.** The `bash`/`sh` branch checks `os.path.isfile`, so a
  non-executable gate script currently passes readiness and fails at execution time.
- **Name which root was searched.** "not found in PATH" is accurate for a bare command and
  misleading for a path — that wording is what made this undiagnosable in one read.

## Scope

`utils/py/swarm_preflight.py` only. The frozen Bash twin `utils/swarm-preflight.sh` must be
**byte-unchanged** (GH-308) — that is an explicit acceptance criterion, not an inference, and
`test/gh308-frozen-twin-guard.sh` will enforce it.

Register `test/gh343-gate-program-target-root.sh` in `validate.sh`'s `TESTS` array; the suite does
not glob `test/`.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/swarm_preflight.py,test/gh343-gate-program-target-root.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh343-gate-program-target-root/RELAY.md,utils/py/swarm_preflight.py,test/gh343-gate-program-target-root.sh,validate.sh"
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick ping MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN --agent codex
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick release MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/litmus-trustworthy-gates-2026-08-06--gh343-gate-program-target-root/RELAY.md and utils/py/swarm_preflight.py,test/gh343-gate-program-target-root.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/swarm_preflight.py,test/gh343-gate-program-target-root.sh,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick release MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick done MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick
   Edit ONLY phases/litmus-trustworthy-gates-2026-08-06--gh343-gate-program-target-root/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
