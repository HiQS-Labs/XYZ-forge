# AgentChorus experiments (Gen 2)

How the telemetry pilot (#193) is run, measured, and stopped. Companion to `TELEMETRY.md`.

## Declared pilot window (the clock everything waits on)

**2026-08-24 .. 2026-09-08** — telemetry default-ON (hard override `AGENT2AGENT_TELEMETRY=0`
anytime; `telemetry purge` for complete revocation). After the window, telemetry reverts to
opt-in. **Early exit:** the pilot stops early if (a) `telemetry audit` ever FAILs on a real
discussion (content leak — fix before resuming), or (b) the operator calls it. Early exit is
recorded as a comment on #193 with the date and reason.

## The experiments (run after the baseline, not before)

1. **Citation resolvability baseline** — `verify-citations` (Phase 2) over the pilot corpus.
   Metric: % resolvable, drift-vs-hallucination split (ref-pinned).
2. **Outcome tracking pilot** — record `outcome` for every closed discussion in the window;
   `telemetry aggregate` gives implementation rate + per-model durability (from `--agent SEAT=MODEL`
   attribution). Baseline review at ≥10 closed discussions.
3. **Status-quo bias detection** — CONDITIONED on the `--stance` operator prior (Phase 3): the
   >80%-keeps threshold is only meaningful within a stance class. Without the prior, the number
   measures the asker, not the process.
4. **Steelman effect** — `--require-adversarial` (Phase 3) A/B: presence is necessary-not-
   sufficient; hand-rate steelman quality on a small sample; steelman claims must cite.
5. **Doorbell reliability** — `watch_transition` / `stale_watch_detected` events (Phase 2
   completes the set): operational friction, separate from decision quality.

## Ordering rule

Phases 2-3 flags exist to be *measured against the baseline corpus*, not shipped on faith: the
baseline review (≥10 telemetry-active closed discussions, written up on #193) gates any move of
an experiment toward default.
