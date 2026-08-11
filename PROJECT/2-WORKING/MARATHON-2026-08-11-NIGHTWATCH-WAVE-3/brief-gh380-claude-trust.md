---
title: "Phase brief: GH-380 gh380-claude-trust (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-11
updated: 2026-08-11
owner: noel
goal: >
  Phase-brief input consumed by the marathon driver for the gh380-claude-trust phase of
  MARATHON-2026-08-11-NIGHTWATCH-WAVE-3 — not itself an active-doc capture; the canonical capture doc
  is GH-380-CLAUDE-BUILDER-TRUST-SILENT-DEGRADE.md two levels up.
roadmap_exempt: true
---

# Brief — GH-380: surface the trust warning a claude builder currently swallows

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 in the Nightwatch batch-2 doc fan-out. Issue had **no acceptance criteria**; five were authored in a separately labelled block. One of the issue's two evidence claims was found stale against source — see "What was corrected". Preflight 2026-08-11: **ready (exit 0)**, issue **OPEN**. | Fire as phase 2 of 3. |

**Parent capture doc:** `PROJECT/2-WORKING/GH-380-CLAUDE-BUILDER-TRUST-SILENT-DEGRADE.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/380

## Acceptance

**Read the acceptance criteria from the parent capture doc's authored acceptance block.** The issue
carries none. This brief's prose is context, not the contract.

## The defect

A claude builder pointed at a target repo that was never pre-trusted **silently degrades to default
permissions**. The CLI does emit a warning about it — and nothing surfaces that line anywhere an
operator will see. The turn proceeds, produces weaker work than intended, and reports success.

## What was corrected before you start — this is the important part

**The issue describes the DEAD half of a frozen twin pair.** Its evidence table says the warning
lands in `$TMPDIR/claude-turn-<pid>.json` and is "never copied into the phase directory."

- That is **true** of `relay-automation/claude-turn.sh:159` — the **FROZEN Bash** shim.
- It is **false** of the path that actually runs. `utils/py/claude-turn.py:72` calls
  `rtl_default_log()` (`utils/py/rtl.py:307-324`), which already writes a persistent in-repo
  `relay-system/logs/<date>/…` transcript, as of commit `7812710` — confirmed an ancestor of HEAD.

`XYZ_PYTHON` defaults to Python, so the Python shim is what runs.

**Therefore the issue's suggested fix #4 — "preserve the turn log" — is ALREADY SHIPPED and is out of
scope.** Do not re-implement it. If you find yourself adding transcript persistence, you are building
something that exists.

**What is untouched and IS the job:** nothing surfaces the trust *warning line itself* in a place an
operator reads. The log now survives; the signal is still buried in it.

## The trap this lane is most likely to fall into

**Silently auto-trusting the directory.** The issue's own suggested fix says *"print … and
continue"* — not "set `hasTrustDialogAccepted`". A builder that makes the warning go away by granting
trust has inverted the fix: it removes the *signal* instead of surfacing it, and it does so by
widening permissions without an operator ever deciding to. That is strictly worse than the bug.

**Second trap: changing the exit contract.** `claude-turn`'s existing exit codes (0/3/5/6/7) must
stay exactly as they are. This is an observability change. A trust warning is **not** grounds to fail
a turn — the turn still works, it just works with fewer permissions than the operator expected.

## Write-set

- `utils/py/claude-turn.py` — the Python (authoritative) half **only**

**Do NOT touch `relay-automation/claude-turn.sh`.** It is the frozen half of twin pair
`claude-turn.sh : claude-turn.py` (`test/gh308-frozen-twin-guard.sh`). Editing it requires a
`Frozen-twin-exception:` trailer and is explicitly out of scope for this lane — the Python-only
write-set is what keeps this lane fireable at all.

## Containment note

`validate.sh` runs `test/claude-turn.sh`, so this file **is executed inside every phase's
pre-advance gate**. That makes the lane *contained*, not inert: a defect here turns this phase's own
gate red rather than wedging a later turn. Do not assume a broken change will be caught downstream —
it will be caught by your own gate, which is the intended behaviour.

## Adjacent, and NOT this lane

`marathon_drive.py:238-260`'s binary probe (GH-117) fail-fasts on a missing claude binary before any
tick mutation. It is **PATH-only and never trust-aware**, so it neither blocks nor interacts with
this fix. Verified. Leave it alone.
