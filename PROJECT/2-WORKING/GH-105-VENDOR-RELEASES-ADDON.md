---
gh_issue: 105
source: https://github.com/HiQS-Labs/XYZ-forge/issues/105
title: "Vendor the RELEASES DB system + HTML timeline generator into the .xyz payload as an optional add-on"
status: Active
created: 2026-08-20
updated: 2026-08-28
owner: noel
doc_type: feedback
release: 0.9.0 Cargo (sole frozen manifest entry, sequenced before Meter by operator decision 2026-08-20)
goal: >
  Ship the RELEASES subsystem and timeline generator in every vendored .xyz payload as an
  opt-in, zero-default add-on.
fix_probes:
  - path_absent:test/gh105-vendor-releases-addon.sh
effort: 2
complexity: 2
risk: 2
phases: 1
---
## Status

| What was just completed | What's next |
|---|---|
| Promoted to active working contract via jog | Execute implementation and verify probes |

# GH-105: Vendor the RELEASES DB + timeline generator into `.xyz/` (optional add-on)

## Context & Cross-References
- **Tracking Issue:** [#105](https://github.com/HiQS-Suite/XYZ-forge/issues/105)
- **Release:** 0.9.0 "Cargo" (target 2026-09-19, sequenced before Meter by operator decision 2026-08-20) — sole frozen manifest entry.
- **Builds on:** GH-32 (RELEASES app) · GH-69 (roadmap shadow) · GH-103 / PR #104 (timeline viewer) · GH-312 (vendor preserve list) · interacts with the #75 dashboard-verb fold-in decision.

## Why
A repo that adopts the vendored XYZ harness gets coordination but no release ledger. Shipping the RELEASES subsystem inside every `.xyz/` payload (operator decision: always present, not flag-gated) makes the ledger a zero-download, opt-in capability — "when you're ready," never wired by default, matching RELEASES.md's own OPTIONAL philosophy (GH-381).

## Scope
- `xyz-vendor.sh materialize_vendor()` ships: `utils/py/releases_app.py` (+ machinery), `utils/releases-merge-resolve.sh`, `RELEASES-DB-FAQS.md`, `utils/timeline/` (exporter + `RELEASES.html`).
- Target-repo state (`releases.db`/`releases.sql`/`RELEASES.md`) lives at the target root; any `.xyz/`-resident runtime state joins the GH-312 preserve list.
- A short documented "enable the ledger" recipe; `find-harness.sh`/skill docs gain a one-line pointer.

## Key Concepts
1. **Payload, not plumbing** — files always present, zero behavior until `releases init` is run by the user.
2. **State outlives updates** — `xyz-sync.sh update` must preserve the target's ledger (GH-312 rule).
3. **The exit criterion is the gate** — authored before any member work, per the Litmus/Nightwatch ordering (see the Cargo block in RELEASES.md).

## Provisional triage
cx/risk/eff 2/1/2 — additive to the vendor script; blast radius is the `.xyz/` payload size and the preserve list.

## Non-goals

- No flag-gating of the payload presence (operator decision: always present).
- No changes to writer authority: the CLI dual path stays the only writer.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [ { "type": "path_absent", "path": "test/gh105-vendor-releases-addon.sh" } ],
  "artifacts": [
    "relay-automation/xyz-vendor.sh",
    "relay-automation/xyz-sync.sh",
    "RELEASES-DB-FAQS.md",
    "test/find-harness.sh",
    "test/gh105-vendor-releases-addon.sh"
  ],
  "artifacts_new": [ "test/gh105-vendor-releases-addon.sh" ]
}
```

## Acceptance criteria — the build is DONE when these hold

- [ ] `bash relay-automation/xyz-vendor.sh materialize` (or the documented invocation) ships
      `utils/py/releases_app.py`, `utils/releases-merge-resolve.sh`, `RELEASES-DB-FAQS.md`,
      and `utils/timeline/` (exporter + `RELEASES.html`) into the vendored `.xyz/` payload.
- [ ] Target-repo ledger state stays at the target root; any `.xyz/`-resident runtime state
      the subsystem creates is on the GH-312 preserve list so `xyz-sync.sh update` preserves it.
- [ ] `RELEASES-DB-FAQS.md` (or the payload docs) carry a short "enable the RELEASES ledger"
      recipe (`releases init`, optional `RELEASES.md` authoring); nothing runs until invoked.
- [ ] `test/find-harness.sh` (or the equivalent discovery surface) names the vendored RELEASES
      add-on with a one-line pointer.
- [ ] `bash test/gh105-vendor-releases-addon.sh` exists and pins the payload (a vendored
      fixture contains the RELEASES files; a sync/update round-trip preserves target ledger
      state).
- [ ] Existing vendored installs without ledger state behave exactly as before (zero behavior
      until `releases init`).

## Lessons Learned (For Future Agents)
- (to be filled before completion)
