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
