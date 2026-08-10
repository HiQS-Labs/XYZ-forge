---
title: "Phase brief: GH-416 gh416-pdda-sync-policy (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-08
updated: 2026-08-08
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh416-pdda-sync-policy
  phase of MARATHON-2026-08-08-LITMUS-WAVE-2 — not itself an active-doc capture; the canonical
  capture doc is GH-416-PDDA-SYNC-DELETED-GUARDRAILS.md two levels up.
roadmap_exempt: true
---

# Brief — GH-416: a stated review policy for the next dependency sync

## Status

| What was just completed | What's next |
|---|---|
| **Four of five acceptance criteria already shipped** in PR #413 (2026-08-03). Contract authored, verified READY, scoped to criterion 5 only. | Fire as phase 1 of 3 — first, because it is the only lane in this marathon whose write-set cannot affect the marathon that is running it. |

**Parent doc:** `PROJECT/2-WORKING/GH-416-PDDA-SYNC-DELETED-GUARDRAILS.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/416

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block**, copied verbatim
from the issue. Do not work from a paraphrase — see GH-400.

**Only criterion 5 is in scope.** Criteria 1-4 shipped in PR #413 and are live in the tree. Do not
re-implement them; do not "verify" them by rewriting them. If you believe one of them regressed, say
so in your turn output and stop — a silent re-fix of shipped code is the failure mode here.

## What happened

A dependency sync deleted three shipped guardrails and left CI red for two days. The deletions were
not malicious and not obviously wrong at review time: a sync that reconciles a vendored or generated
set against an upstream can legitimately remove files, and nothing distinguished "this file is stale"
from "this file is a guardrail somebody added on purpose."

PR #413 fixed the mechanics. What it did not do is say **what a reviewer must check the next time a
sync proposes a deletion** — which is the whole of criterion 5, and the reason this issue is still
open.

## What to build

A policy document at `PROJECT/PDDA-SYNC-POLICY.md`, referenced from `AGENTS.md` so an agent meets it
without going looking. It must be concrete enough that a reviewer can execute it:

- What a sync is allowed to delete without an explicit sign-off, and what it is not.
- How a reviewer distinguishes a stale artifact from a deliberately-added guardrail — the actual
  signal, not "use judgement." Consider: is it registered in `validate.sh`? does it carry a
  `GH-<n>` reference? does `git log` show it added by a fix commit rather than by a sync?
- What the reviewer does when the signal is ambiguous. "Ask" is an acceptable answer; "assume stale"
  is not, because that is exactly what happened.
- Who or what enforces it, and what happens when the policy is not followed. A policy nothing checks
  is a preference.

`AGENTS.md` gains a pointer, not a copy. Two copies of a policy drift, and this release exists
because a second copy of something was silently wrong (GH-441).

## Litmus tests for this lane

- **A policy that only describes what went wrong is not a policy.** The output has to tell the next
  reviewer what to *do*, in a form they can follow at 11pm on a red CI.
- **Do not add a new automated check as a substitute.** Criterion 5 asks for a stated review policy.
  If a check is genuinely cheap and honest, propose it in your turn output for a follow-up issue —
  do not build it inside this lane and call the policy done.
- **Do not touch `validate.sh` or any test.** The write-set is exactly two documents. Anything else
  is off-lane and the turn will correctly fail (exit 6).

## Scope

`PROJECT/PDDA-SYNC-POLICY.md` (new) and `AGENTS.md` (a pointer). Documents only — this lane executes
nothing and is the reason it runs first.
