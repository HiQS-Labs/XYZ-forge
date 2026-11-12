---
title: Codify Jog preparation and truthful dispatch readiness
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1439
status: in-progress
owner: Codex
goal: Make existing Jog preparation reusable without misreporting dry-run as execution readiness
risk: 1
phases: 1
---

# GH-1439 — Jog preparation

## Status

| What was just completed | What's next |
|---|---|
| LTVera1014 preparation landed; gaps traced to skill handoff and environment assumptions | Codify existing commands in Jog, link consumers, independently review and publish |

## Grounded plan

Outcome: the next session should follow one existing preparation owner instead of reconstructing LTVera1014's clone/environment/auth sequence from chat. Simple documentation change; plan QA may be skipped under start-task Step6, final independent QA required. No runtime gate, new runner, import format, tests, schema, provider call or deployment change. Easy reversal: revert the skill instruction diff. Primary and live factory processes remain untouched.

1. Extend Jog's existing conversational preparation route and add one ordered procedure with a compact reusable readiness record. Reuse current helpers; never imply receipt generation or capacity probing is already automatic.
2. Link Flywheel and start-marathon to the Jog-owned handoff for serial queues, retaining each engine's existing authorization and ownership.
3. Replay original/final GH1014 evidence against the instruction claims; missing environment or unpublished target must not mean dispatch-ready, and a green dry-run must not certify provider capacity. Independent final QA; normal documentation qualification and PR.

An issue-only checklist already exists in1418 but is not a reusable skill entry point; copying another checklist into every consumer would perpetuate drift. Runtime enhancements are deferred until a specific existing check cannot serve the preparation path. No global install in this task; Skills Army HQ remains deployment owner after reviewed publication/authorization.

## Acceptance

- [ ] Jog owns one reusable preparation recipe and concise readiness record.
- [ ] Contract, environment, integration and dispatch evidence are distinguished without a new state machine.
- [ ] Consumers link to this owner; no duplicate runner/checklist or changed authorization.
- [ ] GH1014 negative/positive evidence replay and independent final review recorded.

## Recon

`skills/2-daily/jog/SKILL.md` currently goes directly from capture/enqueue to execution lifecycle. `jog_run.validate_marathon_executor` and target checks exist; dry-run skips live capacity. `harness_paths.require_primary`, native promotion lint, Swarm generated packets, checkpoint clone and gate_env already own their boundaries. `start-marathon` owns multi-lane planning, not this serial queue. `flywheel` is the supervisor, not another engine. LTVera app/Buffer dependency pins conflict, proving one global Python environment is not a safe default. #1436 malformed-contract work is separate.

## Ratings

Provisional pri60/sev45/appeal50/effort80: repeated operator preparation overhead, no new data-loss claim, neutral appeal and small source-skill edit.
