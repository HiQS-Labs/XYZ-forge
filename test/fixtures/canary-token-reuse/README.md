# Token-reuse canary — GH-40 Phase 2 · SEALED by GH-41

> **RESOLVED 2026-07-03 (GH-41).** The kernel now catches this. `foldWithMeta` seals an authorized
> terminal, so the injected post-`done` reclaim folds to `done` + one `claim-after-terminal` rejection
> instead of silently resurrecting the token. `verify-fixture.sh`'s oracle is **inverted** to assert
> the seal (see [decisions/2026-07-02-terminality-seal.md](../../../decisions/2026-07-02-terminality-seal.md)).
> The double-blind framing below is retained as the historical GH-40 record.

A **double-blind Reviewer canary** seeded from real telemetry: can a Reviewer reading a captured
`.tick/events/` stream catch a *silent* FSM violation the kernel itself does not flag — a `done` task
token reopened by a higher-epoch reclaim?

This is the second GH-40 fixture (Phase 2), and the first one **derived from a captured event
stream** rather than a source-file poison. Tracked by
[PROJECT/2-WORKING/GH-40-DOUBLE-BLIND-REVIEWER.md](../../../PROJECT/2-WORKING/GH-40-DOUBLE-BLIND-REVIEWER.md)
· issue [#40](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/40).

## Files

| File | Role | Reviewer may see it? |
|---|---|---|
| `events/` | The mutated stream: 7 real RELAY-TURN events + 1 injected epoch-4 claim | **Yes** (blind input) |
| `CANDIDATE.md` | The audit task as presented — stream + instructions, **no answer** | **Yes** |
| `EXPECTED.md` | Answer key: the anomaly, why the kernel misses it, grading | **No** — keep out of context |
| `verify-fixture.sh` | Proves the canary is real & latent (fold → silent resurrection, kernel logs nothing) | n/a |

## The anomaly (what makes it a fair test)

The first 7 events are a **real** captured RELAY-TURN lifecycle (claude→agy→claude, epochs 1→2→3,
ending `task.done`). The 8th event — the only mutation — is a `task.claimed` on the same token at
**epoch 4, after** the `done`. Folding the stream:

- status flips `done` → **`claimed`** (the task resurrects);
- the epoch-3 `done` is silently superseded — **0 rejections logged**.

The epoch fence (`src/project.js`) stops *lower*-epoch zombie writers but has no guard against a
*higher*-epoch reclaim of a completed token. So the violation is **silent**: no fence fires, no audit
trace. A Reviewer that only reads the kernel's output ("status: claimed, nothing rejected") sees
nothing wrong — it must reason about the protocol to catch it. That is the gate.

## Hard rule (why this fixture is legitimate)

Per GH-40, canaries are **derived from real artifacts, never hand-authored**. The base stream is 7
real events copied verbatim from `.tick/events/`; exactly one event is injected, byte-schema-valid
`0.2.0`. If the kernel changes so it *does* catch token reuse, `verify-fixture.sh` will fail —
re-derive or retire the canary before it can grade a Reviewer.

## Run it

```bash
# 1. Prove the canary is real & latent (fold mutated vs control stream; read-only, fast):
bash test/fixtures/canary-token-reuse/verify-fixture.sh

# 2. Double-blind Reviewer run: hand a fresh agent ONLY CANDIDATE.md + repo access, grade vs EXPECTED.md.
```

A run log of the first double-blind grading lives in the GH-40 working doc.
