# Marathon Phase gh172-vendored-e2e
STATUS: Approved
NEXT: agy

<!-- marathon-drive: task=MARATHON-GH172-VENDORED-E2E-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "Phase brief: GH-172 vendored .xyz E2E regression coverage (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-16
updated: 2026-07-16
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh172-vendored-e2e phase —
  not itself an active-doc capture; the canonical capture doc is GH-172-VENDORED-ROOT-AUDIT.md one
  level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-16. | Fire this phase via the marathon, after gh172-python-audit lands. |

## Phase: gh172-vendored-e2e — vendored consumer-repo regression coverage, both language paths

Full context: [GH-172-VENDORED-ROOT-AUDIT.md](../GH-172-VENDORED-ROOT-AUDIT.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/172

### Start here

Read both prior findings docs in this folder (`GH-172-BASH-AUDIT-FINDINGS.md`,
`GH-172-PYTHON-AUDIT-FINDINGS.md`) — any gap they fixed needs a regression case here so it can't
silently regress.

### What to build (extend `test/marathon-drive.sh`)

- A vendored `.xyz` consumer-repo case for the real `marathon-drive.sh → relay-drive.sh → shim`
  chain, covering **both the builder and reviewer legs** (i.e. exercise both a codex-as-builder and an
  agy-as-reviewer turn shape in the vendored fixture, not just one).
- A Python-path vendored regression (`XYZ_PYTHON=1`) equivalent to the Bash regression above — same
  chain, same vendored-consumer shape, run through the Python port.
- Assert no stray `.xyz/.tick` event log is created in either mode unless explicitly intended by the
  test fixture.
- Assert all claim/release/done events land in the real consumer repo's `.tick`, not the harness's own.

Follow this repo's existing test-file conventions in `test/marathon-drive.sh` (fixture setup via
`_setup.sh`-style helpers, stub `MARATHON_DRIVE`/driver plumbing to avoid invoking the real long-running
driver in a unit test, same assertion style as neighboring cases).

### Acceptance / done means

- New vendored-consumer cases exist in `test/marathon-drive.sh` for both Bash and `XYZ_PYTHON=1`
  chains, covering both builder and reviewer legs.
- Both new cases pass; `bash test/marathon-drive.sh` fully green.
- Full `bash validate.sh` green (or unchanged from before your change — the pre-existing `#208`
  environment red is expected and not yours to fix).
- Do not invoke the real `relay-drive.sh`/`marathon-drive.sh` against this repo's own live `.tick/` —
  route through the same stubbed/fixture pattern the rest of `test/marathon-drive.sh` already uses.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): test/marathon-drive.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH172-VENDORED-E2E-TURN --agent codex --paths "phases/gh172-root-audit--gh172-vendored-e2e/RELAY.md,test/marathon-drive.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH172-VENDORED-E2E-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH172-VENDORED-E2E-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh172-root-audit--gh172-vendored-e2e/RELAY.md and test/marathon-drive.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: test/marathon-drive.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH172-VENDORED-E2E-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH172-VENDORED-E2E-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh172-root-audit--gh172-vendored-e2e/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex
Files touched: `test/marathon-drive.sh`, `phases/gh172-root-audit--gh172-vendored-e2e/RELAY.md`

Key decisions:
- Kept the existing GH-171/GH-172 vendored cap-path regressions intact and added separate approval-path cases instead of replacing them.
- Added shared vendored-fixture helpers, then asserted the full consumer-repo tick stream for both Bash and `XYZ_PYTHON=1`: `task.created`, builder `task.claimed`, builder `task.released -> agy`, reviewer `task.claimed`, reviewer `task.done`.
- Kept the stray-log guard explicit in both approval-path cases: `.xyz/.tick/events` must stay absent.

Verification:
- `bash test/marathon-drive.sh` -> `101 pass, 0 fail`

### Round 1 · Reviewer · agy
**Verdict:** Approved
The builder successfully implemented the vendored regression tests for both Bash and Python chains including the builder and reviewer legs. The tests run cleanly and no stray events leak into `.xyz/.tick`.
