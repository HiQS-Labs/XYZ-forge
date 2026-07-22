---
gh_issue: 281
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/281
title: "Sentinel Tier-1 Stage-0 — bundled opt-in debug-capture scripts (no self-edit, no network)"
slug: sentinel-tier1-stage0
status: Active
created: 2026-07-22
updated: 2026-07-22
owner: Noel (operator) · Claude (orchestrator/reviewer)
branch: main
doc_type: bugfix
goal: >
  Ship the three standalone, zero-network Tier-1 debug-capture scripts (harvest-findings.sh,
  finding-new.sh, sentinel-network-guard.sh) plus their tests and the debug.log .gitignore line —
  the headlessly-buildable slice of GH-281 that never touches the running driver.
effort: 2
complexity: 2
risk: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not the Stage-0 hooks inside marathon-drive.sh (self-edit of the running driver — orchestrator-only, out of the headless lane)
  - Not Tier 2 (Gemma triage overlay, GitHub egress, nightly batch) — that stays hand-built behind the human gate
  - Not registering the new tests into validate.sh (shared gate file — orchestrator step after the builder lane lands)
related:
  - PROJECT/1-INBOX/GH-281-SENTINEL-DEBUG-FLYWHEEL.md   # the full-scope capture + governance adjudication this slice is carved from
---

# GH-281 · Sentinel Tier-1 Stage-0 (standalone bundled scripts)

The marathon-buildable slice of GH-281, carved out per the parent capture's finding #1/#3b and the
DO-NOT-BUILD / measured-gap adjudication. This is **only** the three new, self-contained, zero-network
Tier-1 scripts plus their tests and the `.gitignore` line — the files Agy + Codex can build headlessly
without touching the driver that is running them. The `marathon-drive.sh` Stage-0 hooks and the
`validate.sh` test registration are deliberately **excluded** from the builder lane (see Non-goals and
Scope) and handled by the orchestrator afterward, because editing the driver mid-run is self-modification
and `validate.sh` is a shared gate file.

## Status

| What was just completed | What's next |
|---|---|
| Carved Tier-1 Stage-0 into its own 2-WORKING doc with a Swarm Preflight Contract; verified preflight-ready. | Operator attests ratings, then fire Agy/Codex on the builder lane; orchestrator reviews, then wires the driver hooks + validate.sh and takes over integration testing. |

## Why this is risk:2, not the parent's risk:4

The parent GH-281 is risk:4 because it spans Tier 2 — network/LLM/GitHub egress and semi-autonomous
unattended fixing. **This slice carries none of that.** It adds three new files that: (1) write only a
single local, gitignored file; (2) make zero network calls (a CI guard enforces it); (3) never touch the
running driver. It ships dormant behind `XYZ_DEBUG_LOG` (default off) and is byte-inert until the
orchestrator wires the hooks. Rating the carved slice on its own merits — not inheriting the parent's
Tier-2 risk — is the whole point of carving. `ratings_provisional: true` stays set: the operator's
explicit go-to-fire is the attestation (route-to-human by design; nothing here auto-selects).

## Scope — builder lane vs. orchestrator-only

**Builder lane (Agy + Codex, headless — `lanes.agy_safe`):** the self-contained files, each fully
testable in isolation.

| File | Source spec | Testable alone? |
|---|---|---|
| `relay-automation/harvest-findings.sh` | issue §1.4 (verbatim) | yes — feed a relay with 2 Side Finding blocks → 2 JSONL lines |
| `relay-automation/finding-new.sh` | issue §1.5 (verbatim) | yes — run it → 1 valid JSONL line |
| `relay-automation/hooks/sentinel-network-guard.sh` | issue §0.5 / §4 (new; follows `hooks/security-scan.sh` shape) | yes — grep bundled paths for `curl/wget/nc/gh /dev/tcp/http`, nonzero on hit |
| `test/sentinel-tier1.sh` | acceptance §1.7 #3, #5 (harvest + finding-new + JSONL-validity) | it IS the gate |
| `test/sentinel-network-guard.sh` | acceptance §1.7 #6 (follows `test/security-scan.sh`) | it IS the gate |
| `.gitignore` (+`debug.log`) | issue §1.6 | acceptance §1.7 (file never committed) |

**Orchestrator-only (Claude, after the builder lane — NOT in the headless marathon):**

- `relay-automation/marathon-drive.sh` — the six Stage-0 hooks (§1.3): opt-in defaults, `xyz_debug_log_append()`, escalation/lane-park/stale-lock hooks, Side Finding prompt text, harvest hook. **Self-edit of the running driver → applied by hand and reviewed.**
- `validate.sh` — register `sentinel-tier1.sh` + `sentinel-network-guard.sh` in the `TESTS=(…)` array. Shared gate file.
- Integration acceptance §1.7 #1, #2, #4 (default-off byte-identity; each red path appends once; `lane-attempt-cap.sh` still passes) — the **iterative-testing takeover**, exercised against the live driver once the hooks land.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "relay-automation/harvest-findings.sh" },
    { "type": "path_absent", "path": "relay-automation/finding-new.sh" },
    { "type": "path_absent", "path": "relay-automation/hooks/sentinel-network-guard.sh" },
    { "type": "path_absent", "path": "test/sentinel-tier1.sh" },
    { "type": "path_absent", "path": "test/sentinel-network-guard.sh" },
    { "type": "grep_absent", "path": ".gitignore", "pattern": "debug\\.log" }
  ],
  "artifacts": [
    "relay-automation/harvest-findings.sh",
    "relay-automation/finding-new.sh",
    "relay-automation/hooks/sentinel-network-guard.sh",
    "test/sentinel-tier1.sh",
    "test/sentinel-network-guard.sh",
    ".gitignore",
    "validate.sh"
  ],
  "artifacts_new": [
    "relay-automation/harvest-findings.sh",
    "relay-automation/finding-new.sh",
    "relay-automation/hooks/sentinel-network-guard.sh",
    "test/sentinel-tier1.sh",
    "test/sentinel-network-guard.sh"
  ],
  "remediation": {
    "source": "issue#281 §1.4 §1.5 §1.6 §0.5",
    "criteria": "harvest-findings.sh extracts every `### Side Finding` block from a relay file into valid PDDA-output-contract JSONL on debug.log (read-only on the relay, no network); finding-new.sh appends one valid JSONL finding; sentinel-network-guard.sh exits nonzero when a bundled path contains curl/wget/nc/gh/dev-tcp/http; .gitignore ignores debug.log; test/sentinel-tier1.sh and test/sentinel-network-guard.sh cover these and pass; every emitted line parses as JSON."
  },
  "lanes": {
    "agy_safe": [
      "relay-automation/harvest-findings.sh",
      "relay-automation/finding-new.sh",
      "relay-automation/hooks/sentinel-network-guard.sh",
      "test/sentinel-tier1.sh",
      "test/sentinel-network-guard.sh",
      ".gitignore",
      "validate.sh"
    ],
    "orchestrator_only": [
      "relay-automation/marathon-drive.sh"
    ]
  }
}
```

## Phase 1

- [ ] Add `relay-automation/harvest-findings.sh` verbatim from issue §1.4 (executable; read-only on the relay; append-only on debug.log; no network).
- [ ] Add `relay-automation/finding-new.sh` verbatim from issue §1.5 (executable; validates `--severity`; no network).
- [ ] Add `relay-automation/hooks/sentinel-network-guard.sh` — grep bundled paths for `curl`, `wget`, `nc`, `gh `, `/dev/tcp`, `http`; exit nonzero + fail-loud to stderr on any hit outside the marked overlay dir (shape mirrors `relay-automation/hooks/security-scan.sh`).
- [ ] Add `test/sentinel-tier1.sh` — bad/good fixtures for harvest (2 Side Findings → 2 lines, `scope`/`probe` intact) and finding-new (1 line), plus `python3 -c` JSONL-validity over the output (acceptance §1.7 #3, #5).
- [ ] Add `test/sentinel-network-guard.sh` — BAD fixture (a `curl` in a bundled path) trips it; clean fixture passes (acceptance §1.7 #6).
- [ ] Add `debug.log` to `.gitignore` under a `# Sentinel Tier 1 debug capture` comment (issue §1.6).
- [ ] Gate green: `bash test/sentinel-tier1.sh && bash test/sentinel-network-guard.sh`.

## Orchestrator follow-on (out of this lane)

1. Apply the six §1.3 Stage-0 hooks to `relay-automation/marathon-drive.sh` by hand; review the diff against the issue anchors.
2. Register both new tests in the `validate.sh` `TESTS=(…)` array.
3. Run integration acceptance §1.7 #1 (default-off byte-identity), #2 (each red path appends once), #4 (`test/lane-attempt-cap.sh` still passes) against the live driver — the iterative-testing takeover.
4. Full-suite `bash validate.sh` green before any PR into `development`.
