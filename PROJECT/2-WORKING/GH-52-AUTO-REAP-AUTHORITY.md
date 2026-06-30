---
title: Part B / R2 — auto-reap authority (flip watchdog --allow-reap from stub to real)
status: Captured (1-INBOX)
created: 2026-06-29
updated: 2026-06-29
owner: noel
branch: main
gh_issue: 52
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/52
parent: PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md
doc_type: project
complexity: medium
risk: medium
effort: medium
ratings_provisional: true
goal: >
  Close the recovery half of G1 (mid-turn-kill): detection already flags a parked suspect and emits a
  JSON escalation, but watchdog.sh --allow-reap only fires a STUB. R2 defines who may reap and on what
  evidence (a decision record), then flips --allow-reap to a real, idempotent re-offer of the orphaned
  token — exactly once, never reaping a live/heartbeating claim.
---

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-06-29 as the one proof-sized Part B Phase-2 slice (per ROADMAP next-up). Detection half (G1) shipped 2026-06-18 (`test/chaos-midturn-kill.sh` flags `parked_suspect` + one JSON escalation); the `--allow-reap` recovery half is still a stub. | Promote to `2-WORKING`, then fire via `swarm-preflight --gh-issue 52 → marathon-drive` (Opus builder — decision-record + kernel-adjacent; agy/Codex reviewer). **NOT a same-repo `--target-root .` lane** (GH-51 [1]): omit `--target-root` so containment normalization stays correct. |

## Why this slice (alignment)
Per GUIDING-PRINCIPLES priority (**containment > coordination correctness > signal quality**): R2 is
**coordination correctness**, builds on shipped detection, and — unlike G2 dup-token (kernel epoch
fencing) — does not touch the projection fence, so it is the lowest-risk Phase-2 needle-mover. G4
(concurrent-pollers) already has a passing proof (`test/chaos-concurrent-pollers.sh` 20/20); reconcile
its stale checklist box separately.

## Asks (acceptance criteria)
- [ ] Decision record under `decisions/` naming the reap authority (the single `--watchdog-authority` holder) + the evidence bar (zero heartbeats past the parked-suspect gap threshold; never a heartbeating claim).
- [ ] `watchdog.sh --allow-reap` performs a REAL reap of a confirmed parked suspect (not a stub) — re-offers the orphaned token via the `tick` reap/release path.
- [ ] Re-offer is **exactly once** and idempotent (a second pass with the suspect already reaped is a no-op).
- [ ] A live/heartbeating claim is NEVER reaped (false-positive guard asserted).
- [ ] Containment unchanged; `bash validate.sh` green.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/watchdog.sh", "pattern": "allow-reap.*real|reap_real|REAP_REAL", "note": "R2 flips --allow-reap from stub to a real reap; the real path is absent today → fix still required" }
  ],
  "artifacts": [
    "relay-automation/watchdog.sh",
    "test/chaos-midturn-kill.sh",
    "test/watchdog-liveness.sh"
  ],
  "remediation": "Define reap authority + evidence in a decisions/ record, then flip watchdog.sh --allow-reap from stub to a real, idempotent re-offer of the orphaned token (tick reap/release): re-offer EXACTLY ONCE on a confirmed parked suspect (zero heartbeats past the gap threshold), no-op on a second pass, and NEVER reap a live/heartbeating claim. Extend the chaos/watchdog tests to assert exactly-once re-offer + the live-claim false-positive guard. Do NOT modify the epoch-fencing projection kernel (src/) or the relay containment core (relay-turn-lib.sh). Verify with ONLY the specific changed tests in-turn (NOT the full validate.sh — it can trip containment); the harness runs the gate after the turn. NOTE: fire this WITHOUT --target-root (same-repo lane; GH-51 [1]).",
  "lanes": {
    "orchestrator_only": ["relay-automation/watchdog.sh"],
    "note": "kernel-adjacent (reap path + decision record). Opus builder per the model-assignment note. src/ epoch fence + relay-turn-lib.sh are OUT of scope."
  }
}
```

## Pointers
- Parent frontier + checklist: [ADVERSARIAL-HARDENING.md](../2-WORKING/ADVERSARIAL-HARDENING.md) (Phase 2, R2 + G1).
- Phase 1 decision-record template: [decisions/2026-06-18-epoch-fencing.md](../../decisions/2026-06-18-epoch-fencing.md).
- Containment caveat for the fire: [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51) [1] — same-repo lanes must omit `--target-root`.
