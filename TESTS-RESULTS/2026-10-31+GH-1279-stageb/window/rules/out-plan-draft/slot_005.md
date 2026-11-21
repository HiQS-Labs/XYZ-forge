# Plan draft: #223 pre-push gate: push double-applies through ref lock — retry reports own success as remote rejection

> draft; preflight and independent plan QA outstanding

- Request: `gh-223-da256c1e74de` (tick `slot_005`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 80/75/65/60
- Capture doc: PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md (sha256 d500e0572ff674e6720e86255f1ed240ab5b2ffe2b9fb5afb0202b4c1d08e28b)
- Issue sha256: da256c1e74de98f6d1070b3059a71a8a955e87e79ba10605d230e8d2ae6ecc25 (updated 2026-09-25T01:24:50Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md:L48 (Phase 0 — Explore & scope)_

> Discovery phase: its findings are written back into this doc before its QA gate can pass.

### Checklist
- [ ] Ground the idea in the real code/trace it touches (git trace of a gated push; hook path audit)
- [ ] Name the concrete deliverable + its write-set (needed before it can be a marathon lane)
- [ ] Decide the tool shape — reuse an existing command/script before new infrastructure (/ponytail)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The scope is grounded in real code/history, not a hypothetical
- [ ] Composes with existing commands rather than adding a parallel path
- [ ] A human checkpoint remains before anything fires

_Source: PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md:L18 (frontmatter goal)_

A gate-green push either succeeds silently or fails truthfully: the double-send is diagnosed (git retry vs hook re-entry) and either eliminated or detected-and-reported as "already landed", so no landed push ever presents as a rejection.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `validate.sh` (issue#223:L12)

## Unresolved file names

- none

## Contract probes

- none
