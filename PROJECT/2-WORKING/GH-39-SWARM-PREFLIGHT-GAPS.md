---
title: Swarm preflight gaps — validate the gate/artifacts/auth + bake a scope-locked brief
status: Active (2-WORKING)
created: 2026-06-28
updated: 2026-06-28
owner: noelsaw1
branch: main
gh_issue: 39
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/39
related: PR #38 (utils/queue-plan.sh — the pre-pre-flight stage; reuses swarm-preflight contract/fix_probes)
doc_type: project
complexity: medium
risk: medium
effort: medium
ratings_provisional: true
goal: >
  Close the gaps that let a "ready" swarm-preflight packet still fail the marathon mid-air: verify the
  gate/artifacts/auth at preflight time, warn on cross-lane ALLOW_PATHS collisions, and bake a TIGHT,
  scope-locked brief (inlined acceptance criteria) so the builder doesn't wander off-task.
---

## Status

| What was just completed | What's next |
|---|---|
| Captured by agy (1-INBOX) + **expanded from the GH-36 marathon dogfood** and promoted to a 2-WORKING capture doc with a Swarm Preflight Contract (2026-06-28). Several of these gaps were hit live this session (auth-health, brief-wander, cross-lane collision). | Fire as a scoped marathon lane (single artifact `utils/swarm-preflight.sh`; **not** self-blocking like GH-36). Builder Codex or agy; agy reviewer. Ensure no other relay is active first (concurrent-commit collisions seen 2026-06-28). |

## Why now — every gap below was hit live this session
The first real marathon dogfood (GH-36, 2026-06-28) exercised the preflight→marathon path end-to-end and
tripped several of these gaps in practice — this doc is the synthesis of agy's static review **and** that
field evidence.

## Gaps

### A — Preflight validation (agy's original findings)
1. **Gate command not executed.** `swarm-preflight` checks `gate` is non-empty but never runs it on the
   pristine ref worktree. A typo, or a gate that already *passes* before the fix (so it can't prove the
   fix), slips through and breaks the marathon loop.
2. **Artifact paths not verified.** `artifacts` is checked non-empty, but the paths aren't checked for
   existence/validity in the target repo — a stale or mistyped artifact path emits "ready" and fails later.
3. **No auth/presence health check.** Nothing verifies `codex`/`agy` are present **and authenticated**
   before emitting `ready`. *(Hit live: I had to hand-probe agy auth before the GH-36 review to avoid the
   GH-37 300s hang — preflight should do this.)*
4. **Cross-packet ALLOW_PATHS collisions unseen.** Packets are evaluated individually, so preflight can't
   warn when two staged lanes overlap on `ALLOW_PATHS`. *(This is exactly the collision-map the [QUEUE](QUEUE-2026-06-27.md)
   builds by hand — preflight should enforce it.)*
5. **`command` probe sandboxing.** `command`-type fix-probes run via `execSync` in the orchestrator shell,
   so they fail when deps/secrets aren't loaded there — a false "blocked".

### B — Brief quality (from the GH-36 dogfood)
6. **The packet brief is too thin / not scope-locked.** `packet.md` *references* the capture doc instead
   of **inlining** the acceptance criteria, and carries no explicit scope-lock. *(Hit live: GH-36 v1's
   Codex burned ~38k tokens on roadmap/PDDA analysis and tried to file an issue instead of editing the one
   shim, then failed on containment. v2 only worked after I hand-wrote a tight, scope-locked brief.)*
7. **No self-block / lane-flag hint (stretch).** GH-36 was self-blocking — the default `-s workspace-write`
   couldn't claim the token, so the default lane could never build the fix. Preflight could flag when the
   artifact is on the turn's own execution path and recommend the lane flags. *(Lower priority; note it.)*

## Acceptance criteria
- [ ] `swarm-preflight` **executes the gate** on the ref worktree and confirms it is runnable (and, for a
  fix-required candidate, that it currently *fails* — proving the fix is still needed).
- [ ] Artifact paths are checked for existence/validity in the target repo before `ready`.
- [ ] Basic `codex`/`agy` **auth + presence** check before emitting `ready` (skip/flag the lane, don't hang).
- [ ] Warn on **cross-packet ALLOW_PATHS collisions** when multiple packets are staged in the output dir.
- [ ] The emitted brief **inlines the acceptance criteria + a scope-lock** ("edit ONLY these files; do not
  analyze the roadmap or file issues") so the builder beelines to the artifact. *(Gap 6 — the highest-value
  one by field evidence.)*
- [ ] `bash validate.sh` green; default packet shape stays backward-compatible.

## Lane note (eat our own dogfood — scope-locked)
Edit **ONLY** `utils/swarm-preflight.sh` (+ its test). Do **NOT** touch `relay-turn-lib.sh`, `bin/`,
`.tick/`, or `marathon-drive.sh`. This is control-plane but **not** the containment kernel, and **not**
self-blocking (unlike GH-36). Builder Codex or agy; agy reviewer (auth-verified first).

## Swarm Preflight Contract
```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/swarm-preflight.sh", "pattern": "GH-38" } ],
  "artifacts":   [ "utils/swarm-preflight.sh" ],
  "remediation": { "source": "self#acceptance-criteria", "criteria": "Preflight executes the gate, verifies artifact paths + codex/agy auth, warns on cross-packet ALLOW_PATHS collisions, and bakes a scope-locked brief with inlined acceptance criteria. validate.sh green; default packet backward-compatible." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ "bin/", ".tick/", "relay-automation/relay-turn-lib.sh", "relay-automation/marathon-drive.sh" ] }
}
```

## Relationship to PR #38 (`utils/queue-plan.sh`)
Open PR **#38** adds a **pre-pre-flight** stage — `queue-plan.sh` reviews the ROADMAP ledger, validates
each item is still real, ranks by new PDDA complexity/risk/effort ratings, and writes a collision-aware
sequenced queue (≤1 kernel lane/wave). The pipeline becomes **queue-plan → swarm-preflight → marathon**.
- **Complementary, mostly disjoint:** GH-39 hardens `swarm-preflight.sh` (the *next* stage); PR #38 adds a
  new `queue-plan.sh`. Different files.
- **One real overlap — gap A4 (cross-packet collisions):** PR #38 already computes collision-aware *waves*.
  If #38 merges first, A4 here may reduce to "surface #38's collision check at swarm-preflight time" or be
  dropped. **Sequence #38 first**, then re-scope A4.
- PR #38 also bumps `validate.sh` to 55/55 and adds a PDDA ratings contract — rebase GH-39 onto it before
  building so the test counts and frontmatter contract align.

## Provenance
Original 5 gaps + 4 acceptance criteria authored by **agy** (1-INBOX intake). Gaps B6/B7 + the acceptance
additions + the contract synthesized from the **GH-36 marathon dogfood** (2026-06-28) — see
[GH-36 capture](../3-COMPLETED/GH-36-HEADLESS-CODEX-TICK-SANDBOX.md) "process findings".
