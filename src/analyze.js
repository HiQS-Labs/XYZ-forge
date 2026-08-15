'use strict';

const { readAllEvents } = require('./events');
const { setsOverlap } = require('./paths'); // GH-4: collision detection (overlapping concurrent claims)

// Run 2: event-log-only analyzer.
//
// The git transport was removed, so there are no work commits to attribute —
// per-commit drift and file-collision detection are deferred (the coordinator
// inspects `git diff` by hand for the PoC). Everything here is derived purely
// from .tick/events/. The primary metric is concurrent-claim time: how much of
// the run window had two agents holding active claims at once.

function toMs(ts) {
  const t = Date.parse(ts);
  return Number.isFinite(t) ? t : null;
}

function humanDuration(ms) {
  if (!ms || ms < 0) return '0s';
  const totalS = Math.round(ms / 1000);
  const h = Math.floor(totalS / 3600);
  const m = Math.floor((totalS % 3600) / 60);
  const s = totalS % 60;
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}

/**
 * Derives per-(agent, task) claim windows from the event timeline. A window
 * opens at `task.claimed` and closes at the next terminal event for that task
 * (`task.released` / `task.done` / `task.circuit_break`). At most one window
 * is open per task at a time (claim.js refuses a second concurrent claimer).
 * @param {Object[]} events - task.* events, chronological order
 * @returns {Object[]} windows: `{task, agent, paths, openedAt, closedAt, closedBy}`
 *   (`closedAt: null, closedBy: 'still_open'` for a window with no terminal event yet)
 */
function buildClaimWindows(events) {
  const windows = [];
  const byTask = new Map();
  for (const ev of events) {
    if (!byTask.has(ev.task)) byTask.set(ev.task, []);
    byTask.get(ev.task).push(ev);
  }

  for (const [taskId, evs] of byTask) {
    let open = null;
    for (const ev of evs) {
      if (ev.type === 'task.claimed') {
        if (!open) {
          // GH-4: `paths` is the LATEST scope (current claim); `pathsUnion` is every path the window
          // ever held (claim + all its scope_changed). Collision detection uses the union so a scope
          // change mid-window can't hide an overlap that existed while both windows were open (a
          // conservative over-approximation — it never MISSES a real overlap; per PR #101 review).
          open = { task: taskId, agent: ev.agent, paths: ev.paths || [], pathsUnion: (ev.paths || []).slice(), openedAt: ev.ts };
        }
      } else if (ev.type === 'task.scope_changed') {
        if (open && open.agent === ev.agent && ev.paths) {
          open.paths = ev.paths;
          for (const p of ev.paths) if (!open.pathsUnion.includes(p)) open.pathsUnion.push(p);
        }
      } else if (
        ev.type === 'task.released' ||
        ev.type === 'task.done' ||
        ev.type === 'task.circuit_break'
      ) {
        if (open) {
          windows.push({ ...open, closedAt: ev.ts, closedBy: ev.type });
          open = null;
        }
      }
    }
    if (open) windows.push({ ...open, closedAt: null, closedBy: 'still_open' });
  }
  return windows;
}

/**
 * Concurrent-claim-time metric (Run 2, P4): how much of the run window had
 * >= 2 distinct agents each holding >= 1 active claim simultaneously. The
 * primary success metric — per-agent task counts can be fooled by a lopsided
 * split, this can't. An agent may hold up to 2 claims at once (the cap), so
 * this measures distinct *agents* with an open window, not raw overlap.
 * @param {Object[]} windows - as returned by {@link buildClaimWindows}
 * @param {string} runStart - ISO timestamp of the run window start
 * @param {string} runEnd - ISO timestamp of the run window end
 * @returns {{concurrent_ms: number, run_window_ms: number, concurrent_pct: number|null}}
 */
function computeParallelism(windows, runStart, runEnd) {
  const startMs = toMs(runStart);
  const endMs = toMs(runEnd);
  if (startMs === null || endMs === null || endMs <= startMs) {
    return { concurrent_ms: 0, run_window_ms: 0, concurrent_pct: null };
  }

  const intervals = [];
  for (const w of windows) {
    const o = toMs(w.openedAt);
    if (o === null) continue;
    let c = w.closedAt ? toMs(w.closedAt) : endMs;
    if (c === null) c = endMs;
    const start = Math.max(o, startMs);
    const end = Math.min(c, endMs);
    if (end > start) intervals.push({ agent: w.agent, start, end });
  }

  const points = new Set([startMs, endMs]);
  for (const iv of intervals) { points.add(iv.start); points.add(iv.end); }
  const sorted = Array.from(points).sort((a, b) => a - b);

  let concurrentMs = 0;
  for (let i = 0; i < sorted.length - 1; i++) {
    const segStart = sorted[i];
    const segEnd = sorted[i + 1];
    if (segEnd <= segStart) continue;
    const agents = new Set();
    for (const iv of intervals) {
      if (iv.start <= segStart && iv.end >= segEnd) agents.add(iv.agent);
    }
    if (agents.size >= 2) concurrentMs += segEnd - segStart;
  }

  const runMs = endMs - startMs;
  return {
    concurrent_ms: concurrentMs,
    run_window_ms: runMs,
    concurrent_pct: runMs > 0 ? Math.round((concurrentMs / runMs) * 100) : null,
  };
}

// GH-4: the run verdict must NOT gate on a fixed per-agent `done` count — a clean 2-lane / 2-agent
// split gives 1 done each by construction, so ">= 2 done/agent" fails a flawless run. Gate instead on
// what actually signals a good concurrent run: enough concurrency, zero parked suspects, every claimed
// lane reached done, and zero collisions. This also unblocks work-stealing: a fast agent that `take`s a
// second item from another lane (turning idle tail-time into real parallel work) produces an *imbalanced*
// per-agent count that the old bar punished but this verdict rewards.
const DEFAULT_CONCURRENCY_TARGET_PCT = 50;
const _envConcTarget = Number(process.env.TICK_CONCURRENCY_TARGET_PCT);
// Finite, in [0,100]. 0 disables the concurrency gate (operator escape hatch); clamp the top so a
// stray >100 (e.g. 120) can't silently make PASS impossible — per the PR #101 cross-model review.
const CONCURRENCY_TARGET_PCT = Number.isFinite(_envConcTarget) && _envConcTarget >= 0
  ? Math.min(_envConcTarget, 100)
  : DEFAULT_CONCURRENCY_TARGET_PCT;

/**
 * Collisions = pairs of time-overlapping claim windows held by DIFFERENT agents whose paths overlap.
 * The claim lock should make this impossible, so a non-zero count is a real containment failure — the
 * verdict's "zero collisions" gate verifies the invariant held rather than assuming it.
 * @param {Object[]} windows - as returned by {@link buildClaimWindows}
 * @returns {Object[]} `{tasks:[a,b], agents:[a,b]}` collision pairs
 */
function computeCollisions(windows) {
  const iv = windows
    .map(w => {
      // Null-safe close: an unparseable closedAt must NOT coerce to 0 in Math.min (that would make the
      // no-overlap test always true — a silent false negative; caught in the PR #101 review). Fall back
      // to Infinity (treat as open through run end). Use pathsUnion so a scoped-away overlap still counts.
      const cm = w.closedAt ? toMs(w.closedAt) : null;
      return { task: w.task, agent: w.agent, paths: w.pathsUnion || w.paths || [], o: toMs(w.openedAt), c: cm !== null ? cm : Infinity };
    })
    .filter(w => w.o !== null);
  const collisions = [];
  for (let i = 0; i < iv.length; i++) {
    for (let j = i + 1; j < iv.length; j++) {
      const a = iv[i], b = iv[j];
      if (a.agent === b.agent) continue;
      if (Math.min(a.c, b.c) <= Math.max(a.o, b.o)) continue; // no time overlap
      if (setsOverlap(a.paths, b.paths)) collisions.push({ tasks: [a.task, b.task], agents: [a.agent, b.agent] });
    }
  }
  return collisions;
}

/**
 * Per-agent idle-tail (lane balance): the wall-clock between an agent's LAST event and the run end.
 * A large tail is the imbalance signal (fix 3) — the fast agent finished and idled while a slower lane
 * ran on. Sorted worst-first.
 * @param {Object[]} events - task.* events
 * @param {string} runEnd - ISO run-window end
 * @param {string[]} agentNames - agents to report (dispatcher already excluded)
 * @returns {Object[]} `{agent, last_event, idle_tail_ms}` worst tail first
 */
function computeBalance(events, runEnd, agentNames) {
  const endMs = toMs(runEnd);
  const balance = [];
  for (const name of agentNames) {
    let last = null, lastTs = null;
    for (const e of events) {
      if (e.agent !== name) continue;
      const t = toMs(e.ts);
      if (t !== null && (last === null || t > last)) { last = t; lastTs = e.ts; }
    }
    if (last === null) continue;
    balance.push({ agent: name, last_event: lastTs, idle_tail_ms: endMs !== null ? Math.max(0, endMs - last) : 0 });
  }
  balance.sort((a, b) => b.idle_tail_ms - a.idle_tail_ms || a.agent.localeCompare(b.agent));
  return balance;
}

/**
 * The run verdict (GH-4): pass/fail/incomplete on concurrency + parked + all-lanes-done + collisions,
 * deliberately NOT on per-agent done counts.
 * @returns {{verdict: 'pass'|'fail'|'incomplete', checks: Object, reasons: string[]}}
 */
function computeVerdict(parallelism, parkedSuspects, windows, doneTaskIds, collisions) {
  const claimedTasks = new Set(windows.map(w => w.task));
  const undone = Array.from(claimedTasks).filter(t => !doneTaskIds.has(t)).sort();
  const pct = parallelism.concurrent_pct;
  const checks = {
    concurrency_pct: pct,
    concurrency_target_pct: CONCURRENCY_TARGET_PCT,
    concurrency_ok: pct !== null && pct >= CONCURRENCY_TARGET_PCT,
    parked_ok: parkedSuspects.length === 0,
    all_lanes_done: claimedTasks.size > 0 && undone.length === 0,
    undone_tasks: undone,
    no_collisions: collisions.length === 0,
    collisions: collisions.length,
  };
  const reasons = [];
  if (!checks.concurrency_ok) {
    reasons.push(pct === null ? 'concurrency not computable' : `concurrency ${pct}% < ${CONCURRENCY_TARGET_PCT}% target`);
  }
  if (!checks.parked_ok) reasons.push(`${parkedSuspects.length} parked-claim suspect(s)`);
  if (!checks.all_lanes_done) reasons.push(claimedTasks.size === 0 ? 'no lanes claimed' : `lanes not done: ${undone.join(', ')}`);
  if (!checks.no_collisions) reasons.push(`${collisions.length} collision(s)`);
  let verdict;
  if (pct === null) verdict = 'incomplete';
  else verdict = reasons.length === 0 ? 'pass' : 'fail';
  return { verdict, checks, reasons };
}

// Parked-claim detection (Run 3). A claim window is a "parked-claim suspect" if
// the holding agent showed no work-activity for longer than the threshold at any
// point in the window. Activity points are: the claim itself (openedAt), every
// `task.*` event the agent emitted for that task inside the window, and the window
// close. The largest gap between consecutive activity points is the parked gap.
// This reads only .tick/events/ — no git author / timestamp dependency (Run 2
// removed distinct git identity). The criterion disqualifies a run with any
// parked-claim suspect.
//
// GH-3: liveness is ANY `task.*` event from the agent, not just `task.heartbeat` —
// an autonomous subagent in one long atomic tool call can't interleave a `tick ping`
// (no yield point), but a `task.scope_changed`/`task.commented`/re-claim still proves
// it's alive. The heartbeat-only signal false-flagged a fully-active run as parked.
// The threshold is operator-tunable via TICK_PARKED_THRESHOLD_MS (default 10 min) so
// an autonomous-agent marathon can raise it without a code change.
const DEFAULT_PARKED_THRESHOLD_MS = 10 * 60 * 1000; // 10 minutes
// Require a FINITE positive number: unset/empty/0/negative/non-numeric fall back to the default,
// and — per the cross-model review of PR #100 — Infinity/NaN are rejected too, so a stray
// `TICK_PARKED_THRESHOLD_MS=Infinity` can't silently make `maxGap > threshold` impossible (disabling
// the gate entirely). A large FINITE value is still honored — that is a legitimate operator suppress.
const _envParkedThresholdMs = Number(process.env.TICK_PARKED_THRESHOLD_MS);
const PARKED_THRESHOLD_MS = Number.isFinite(_envParkedThresholdMs) && _envParkedThresholdMs > 0
  ? _envParkedThresholdMs
  : DEFAULT_PARKED_THRESHOLD_MS;

/**
 * Flags claim windows with no work-activity heartbeat for longer than
 * `thresholdMs` at any point — a "parked-claim suspect", which disqualifies a
 * run (Run 3 criterion). Activity points: the claim itself, every
 * any `task.*` event the agent emitted for that task inside the window (GH-3), and
 * the window close.
 * @param {Object[]} windows - as returned by {@link buildClaimWindows}
 * @param {Object[]} events - task.* events (agent activity read from here)
 * @param {string} runEnd - ISO timestamp used as the close time for still-open windows
 * @param {number} [thresholdMs] - defaults to {@link PARKED_THRESHOLD_MS} (10 minutes, TICK_PARKED_THRESHOLD_MS-tunable)
 * @returns {Object[]} suspects: `{task, agent, max_gap_ms, heartbeats, activity, opened_at, closed_at}`
 */
function findParkedClaims(windows, events, runEnd, thresholdMs = PARKED_THRESHOLD_MS) {
  const endMs = toMs(runEnd);
  const suspects = [];
  for (const w of windows) {
    const openMs = toMs(w.openedAt);
    if (openMs === null) continue;
    const closeMs = w.closedAt ? toMs(w.closedAt) : endMs;
    if (closeMs === null || closeMs <= openMs) continue;

    // GH-3: liveness = ANY task.* event from the holding agent for this task inside
    // the window (not just task.heartbeat). The claim open and window close already
    // bound it; these are the intermediate proofs the agent was alive.
    const activityTs = events
      .filter(e => e.agent === w.agent && e.task === w.task &&
        typeof e.type === 'string' && e.type.startsWith('task.'))
      .map(e => toMs(e.ts))
      .filter(t => t !== null && t > openMs && t < closeMs);
    // Reported heartbeat count stays the real task.heartbeat count (for the message).
    const beats = events.filter(e =>
      e.type === 'task.heartbeat' && e.task === w.task && e.agent === w.agent &&
      (() => { const t = toMs(e.ts); return t !== null && t >= openMs && t <= closeMs; })()
    ).length;

    const points = [openMs, ...activityTs, closeMs].sort((a, b) => a - b);
    let maxGap = 0;
    for (let i = 0; i < points.length - 1; i++) {
      maxGap = Math.max(maxGap, points[i + 1] - points[i]);
    }
    if (maxGap > thresholdMs) {
      suspects.push({
        task: w.task,
        agent: w.agent,
        max_gap_ms: maxGap,
        heartbeats: beats,
        activity: activityTs.length,
        opened_at: w.openedAt,
        closed_at: w.closedAt || null,
      });
    }
  }
  return suspects;
}

const RUN_TYPES = new Set(['symmetric', 'asymmetric']);

// Cost section (Phase 2, COST-OBSERVABILITY-PLAN). Pure function of the cost.* events (which the
// coordination math deliberately ignores) + the claim windows. Reports tokens / wall-clock /
// human-minutes and cost-per-unit-of-work. `runType` is operator-set (never auto-guessed): we do
// not infer whether a comparison is fair, so an unset value reports 'unspecified'.
function computeCost(allEvents, windows, doneTaskIds, runWindowMs, runType) {
  const doneCount = doneTaskIds.size;
  const tokenEvents = allEvents.filter(e => e.type === 'cost.tokens');
  const humanEvents = allEvents.filter(e => e.type === 'cost.human');

  const byAgent = {};
  let inT = 0, outT = 0, totT = 0;
  const instrumentedTasks = new Set();
  for (const e of tokenEvents) {
    const i = Number(e.tokens_in) || 0;
    const o = Number(e.tokens_out) || 0;
    const t = Number(e.tokens_total);
    const tt = Number.isFinite(t) ? t : i + o;
    inT += i; outT += o; totT += tt;
    if (!byAgent[e.agent]) byAgent[e.agent] = { tokens_in: 0, tokens_out: 0, tokens_total: 0 };
    byAgent[e.agent].tokens_in += i;
    byAgent[e.agent].tokens_out += o;
    byAgent[e.agent].tokens_total += tt;
    if (e.task) instrumentedTasks.add(e.task);
  }

  const humanMinutesTotal = humanEvents.reduce((s, e) => s + (Number(e.human_minutes) || 0), 0);

  const memoryEvents = allEvents.filter(e => e.type === 'cost.memory');
  let peakCompressorMb = null;
  let minSwapFreeMb = null;
  const memoryByAgent = {};
  for (const e of memoryEvents) {
    if (Number.isFinite(Number(e.compressor_mb))) {
      peakCompressorMb = Math.max(peakCompressorMb || 0, Number(e.compressor_mb));
    }
    if (Number.isFinite(Number(e.swap_free_mb))) {
      minSwapFreeMb = minSwapFreeMb === null ? Number(e.swap_free_mb) : Math.min(minSwapFreeMb, Number(e.swap_free_mb));
    }
    if (e.agent && Number.isFinite(Number(e.peak_rss_mb))) {
      memoryByAgent[e.agent] = Math.max(memoryByAgent[e.agent] || 0, Number(e.peak_rss_mb));
    }
  }

  // Per-task + per-agent wall-clock from CLOSED claim windows (still-open windows have no duration).
  const walltimeByTask = {};
  const walltimeByAgent = {};
  for (const w of windows) {
    const o = toMs(w.openedAt);
    const c = w.closedAt ? toMs(w.closedAt) : null;
    if (o === null || c === null) continue;
    const d = Math.max(0, c - o);
    walltimeByTask[w.task] = (walltimeByTask[w.task] || 0) + d;
    walltimeByAgent[w.agent] = (walltimeByAgent[w.agent] || 0) + d;
  }

  // Coverage measures how many DONE-tasks carry token data — that's what makes per-done trustworthy.
  // (Tokens spent on not-yet-done tasks still count toward the total spend, but not toward coverage.)
  // instrumentedDone < doneCount => tokens are a FLOOR, and the renderers must say so
  // (Gemini r1 [Should] — never let a floor read as an exact sum).
  let instrumentedCount = 0;
  for (const id of doneTaskIds) if (instrumentedTasks.has(id)) instrumentedCount++;
  const partial = instrumentedCount < doneCount;
  const perDone = doneCount > 0;

  return {
    run_type: RUN_TYPES.has(runType) ? runType : 'unspecified',
    tokens: {
      tokens_in: inT, tokens_out: outT, tokens_total: totT,
      by_agent: byAgent,
      instrumented_tasks: instrumentedCount,
      done_tasks: doneCount,
      coverage: `${instrumentedCount}/${doneCount}`,
      partial,
    },
    walltime: {
      run_window_ms: runWindowMs,
      by_task: walltimeByTask,
      by_agent: walltimeByAgent,
    },
    human_minutes_total: humanMinutesTotal,
    memory: {
      compressor_peak_mb: peakCompressorMb,
      swap_free_min_mb: minSwapFreeMb,
      by_agent: memoryByAgent,
    },
    per_unit: {
      // Floor when partial — flagged via tokens.partial so renderers prefix a "≥".
      tokens_per_done: perDone ? Math.round(totT / doneCount) : null,
      walltime_per_done_ms: perDone ? Math.round(runWindowMs / doneCount) : null,
    },
  };
}

/**
 * Reads the full event log and computes the coordination + cost report:
 * per-agent activity counts, the concurrent-claim-time metric, parked-claim
 * suspects, and (from `cost.*` events) token/wall-clock/human-minute spend.
 * @param {string} repoRoot - absolute path to the repo root
 * @returns {Object} report — see {@link renderHuman}/{@link renderMd} for the rendered shape
 */
function analyze(repoRoot) {
  const allEvents = readAllEvents(repoRoot);
  // Coordination metrics are computed from task.* events only. cost.* events (tokens/human-minutes)
  // are a separate Phase-2 concern — excluding them here keeps every coordination number (counts,
  // run window, parked-claims) byte-identical to pre-cost runs. (COST-OBSERVABILITY-PLAN, Phase 1 QA.)
  const events = allEvents.filter(e => typeof e.type === 'string' && e.type.startsWith('task.'));
  const windows = buildClaimWindows(events);

  const perAgent = new Map();
  function ensureAgent(name) {
    if (!perAgent.has(name)) {
      perAgent.set(name, {
        agent: name,
        claims: 0,
        scope_changes: 0,
        dones: 0,
        releases: 0,
        handoffs: 0,
        breaks: 0,
        comments: 0,
        heartbeats: 0,
      });
    }
    return perAgent.get(name);
  }

  for (const ev of events) {
    const a = ensureAgent(ev.agent);
    switch (ev.type) {
      case 'task.claimed': a.claims++; break;
      case 'task.scope_changed': a.scope_changes++; break;
      case 'task.done': a.dones++; break;
      case 'task.released': a.releases++; if (ev.to_agent) a.handoffs++; break;
      case 'task.circuit_break': a.breaks++; break;
      case 'task.commented': a.comments++; break;
      case 'task.heartbeat': a.heartbeats++; break;
    }
  }
  // The dispatcher only seeds task.created events — drop it from per-agent.
  perAgent.delete('dispatcher');

  const eventTs = events.map(e => e.ts).sort();
  // GH-93: `earliest_event`/`latest_event` (below) span the WHOLE .tick/events/ log, which
  // accumulates across every run with no run-scoping — leftover events from a prior marathon
  // widen that span far outside the actual run. SKILL.md documents the correct metric as
  // work-bounded (first `task.claimed` -> last `task.done`); this computes that window from the
  // task.* events already filtered above, so a genuinely concurrent run doesn't misreport as ~0%
  // just because the whole-log span is stale-widened. Falls back to the whole-log span (today's
  // existing behavior) when the log has no claim or no done event yet (a run still in progress,
  // or an empty log) rather than computing a window from a missing timestamp.
  const claimTs = events.filter(e => e.type === 'task.claimed').map(e => e.ts).sort();
  const doneTs = events.filter(e => e.type === 'task.done').map(e => e.ts).sort();
  const hasWorkBoundedWindow = claimTs.length > 0 && doneTs.length > 0;
  const workBoundStart = hasWorkBoundedWindow ? claimTs[0] : (eventTs[0] || null);
  const workBoundEnd = hasWorkBoundedWindow ? doneTs[doneTs.length - 1] : (eventTs[eventTs.length - 1] || null);

  const window = {
    earliest_event: eventTs[0] || null,
    latest_event: eventTs[eventTs.length - 1] || null,
    // GH-93: work-bounded window (first task.claimed -> last task.done) — the metric SKILL.md
    // prescribes and the one concurrent_pct/the verdict gate are actually computed from. Kept
    // alongside earliest_event/latest_event (not replacing them) so the whole-log span stays
    // visible and the discrepancy, if any, is never hidden.
    work_bound_start: workBoundStart,
    work_bound_end: workBoundEnd,
    total_events: events.length,
  };

  const parallelism = computeParallelism(windows, window.work_bound_start, window.work_bound_end);
  const parked_suspects = findParkedClaims(windows, events, window.latest_event);

  const doneTaskIds = new Set(events.filter(e => e.type === 'task.done').map(e => e.task));
  const cost = computeCost(allEvents, windows, doneTaskIds, parallelism.run_window_ms, process.env.TICK_RUN_TYPE);

  // GH-4: collisions, lane balance, and a lane-count-independent verdict.
  const collisions = computeCollisions(windows);
  const balance = computeBalance(events, window.latest_event, Array.from(perAgent.keys()));
  const verdict = computeVerdict(parallelism, parked_suspects, windows, doneTaskIds, collisions);

  return {
    window,
    parallelism,
    parked_suspects,
    collisions,
    balance,
    verdict,
    agents: Array.from(perAgent.values()).sort((a, b) => a.agent.localeCompare(b.agent)),
    event_counts: {
      created: events.filter(e => e.type === 'task.created').length,
      claimed: events.filter(e => e.type === 'task.claimed').length,
      released: events.filter(e => e.type === 'task.released').length,
      scope_changed: events.filter(e => e.type === 'task.scope_changed').length,
      heartbeat: events.filter(e => e.type === 'task.heartbeat').length,
      done: events.filter(e => e.type === 'task.done').length,
      circuit_break: events.filter(e => e.type === 'task.circuit_break').length,
      commented: events.filter(e => e.type === 'task.commented').length,
    },
    cost,
  };
}

/**
 * Renders an {@link analyze} report as plain-text, for terminal output.
 * @param {Object} report - as returned by {@link analyze}
 * @returns {string}
 */
function renderHuman(report) {
  const out = [];
  out.push('=== tick analyze ===');
  out.push(`window (whole log): ${report.window.earliest_event || '(none)'} → ${report.window.latest_event || '(none)'}`);
  out.push(`window (work-bounded, first claimed → last done): ${report.window.work_bound_start || '(none)'} → ${report.window.work_bound_end || '(none)'}`);
  out.push(`events: ${report.window.total_events} (` +
    Object.entries(report.event_counts).map(([k, v]) => `${k}:${v}`).join(', ') + ')');
  const p = report.parallelism;
  if (p && p.concurrent_pct !== null) {
    out.push(`concurrent-claim time: ${humanDuration(p.concurrent_ms)} of ${humanDuration(p.run_window_ms)} run window (${p.concurrent_pct}%)`);
  } else {
    out.push('concurrent-claim time: not computable (run window too short)');
  }
  const ps = report.parked_suspects || [];
  if (ps.length) {
    out.push(`parked-claim suspects: ${ps.length} (DISQUALIFIES run)`);
    for (const s of ps) {
      out.push(`  ${s.task} (${s.agent}): max ${humanDuration(s.max_gap_ms)} with no heartbeat, ${s.heartbeats} beat(s)`);
    }
  } else {
    out.push('parked-claim suspects: none');
  }
  // GH-4: collisions, lane balance, and the lane-count-independent verdict.
  const cols = report.collisions || [];
  if (cols.length) {
    out.push(`collisions (overlapping concurrent claims): ${cols.length}`);
    for (const x of cols) out.push(`  ${x.tasks.join(' ↔ ')} (${x.agents.join(' / ')})`);
  } else {
    out.push('collisions (overlapping concurrent claims): 0');
  }
  const bal = report.balance || [];
  if (bal.length && bal[0].idle_tail_ms > 0) {
    out.push(`lane balance: ${bal[0].agent} idle ${humanDuration(bal[0].idle_tail_ms)} tail (finished first) — a fast agent can \`tick take\` a free lane to fill it`);
  } else if (bal.length) {
    out.push('lane balance: even (no idle tail)');
  }
  const v = report.verdict;
  if (v) {
    out.push(v.verdict === 'pass'
      ? 'VERDICT: PASS (concurrency + zero-parked + all-lanes-done + zero-collisions; NOT gated on per-agent done count)'
      : `VERDICT: ${v.verdict.toUpperCase()} — ${v.reasons.join('; ') || 'run window too short'}`);
  }
  out.push('');
  out.push('--- per agent ---');
  for (const a of report.agents) {
    out.push(`[${a.agent}]`);
    out.push(`  claims: ${a.claims}, done: ${a.dones}, heartbeats: ${a.heartbeats}`);
    out.push(`  released: ${a.releases} (${a.handoffs} as handoff), broken: ${a.breaks}, scope_changes: ${a.scope_changes}, commented: ${a.comments}`);
    out.push('');
  }
  const c = report.cost;
  if (c) {
    const tk = c.tokens;
    const ge = tk.partial ? '≥' : '';
    out.push('--- cost ---');
    out.push(`run type: ${c.run_type}`);
    out.push(`tokens: ${ge}${tk.tokens_total} total (${ge}${tk.tokens_in} in / ${ge}${tk.tokens_out} out)` +
      (tk.partial ? ` — PARTIAL, floor only: ${tk.coverage} done-tasks instrumented` : ''));
    out.push(`human minutes (self-reported): ${c.human_minutes_total}`);
    out.push(`wall-clock (run window): ${humanDuration(c.walltime.run_window_ms)}`);
    if (c.per_unit.tokens_per_done !== null) {
      out.push(`per done-task: ${ge}${c.per_unit.tokens_per_done} tokens, ${humanDuration(c.per_unit.walltime_per_done_ms)} wall-clock`);
    } else {
      out.push('per done-task: n/a (0 tasks done)');
    }
    if (c.memory && (c.memory.compressor_peak_mb !== null || c.memory.swap_free_min_mb !== null || Object.keys(c.memory.by_agent).length > 0)) {
      const memBits = [];
      if (c.memory.compressor_peak_mb !== null) memBits.push(`compressor peak: ${c.memory.compressor_peak_mb}MB`);
      if (c.memory.swap_free_min_mb !== null) memBits.push(`swap free min: ${c.memory.swap_free_min_mb}MB`);
      if (memBits.length) out.push(`memory: ${memBits.join(', ')}`);
      if (Object.keys(c.memory.by_agent).length > 0) {
        const agentRss = Object.entries(c.memory.by_agent).map(([a, rss]) => `${a}: ${rss}MB peak RSS`).join(', ');
        out.push(`  turn peak RSS: ${agentRss}`);
      }
    }
    out.push('');
  }
  return out.join('\n');
}

/**
 * Renders an {@link analyze} report as markdown, for embedding in a doc/PR.
 * @param {Object} report - as returned by {@link analyze}
 * @returns {string}
 */
function renderMd(report) {
  const out = [];
  out.push('## Auto-analyzed (tick analyze)');
  out.push('');
  out.push(`- **Run window (whole log):** \`${report.window.earliest_event || '(none)'}\` → \`${report.window.latest_event || '(none)'}\``);
  out.push(`- **Run window (work-bounded, first claimed → last done):** \`${report.window.work_bound_start || '(none)'}\` → \`${report.window.work_bound_end || '(none)'}\``);
  out.push(`- **Total events:** ${report.window.total_events} (${Object.entries(report.event_counts).filter(([_, v]) => v).map(([k, v]) => `${k}: ${v}`).join(', ') || 'none'})`);
  const p = report.parallelism;
  if (p && p.concurrent_pct !== null) {
    out.push(`- **Concurrent-claim time (primary metric):** both agents held an active claim simultaneously for ${humanDuration(p.concurrent_ms)} of the ${humanDuration(p.run_window_ms)} run window (**${p.concurrent_pct}%**)`);
  } else {
    out.push('- **Concurrent-claim time (primary metric):** not computable (run window too short)');
  }
  const ps = report.parked_suspects || [];
  if (ps.length) {
    out.push(`- **Parked-claim suspects (DISQUALIFIES run):** ${ps.length} — ` +
      ps.map(s => `${s.task}/${s.agent} (${humanDuration(s.max_gap_ms)} gap, ${s.heartbeats} beat(s))`).join('; '));
  } else {
    out.push('- **Parked-claim suspects:** none');
  }
  out.push('');
  out.push('### Per-agent');
  out.push('');
  for (const a of report.agents) {
    out.push(`#### ${a.agent}`);
    out.push('');
    out.push(`- **Tasks claimed:** ${a.claims}`);
    out.push(`- **Tasks completed (\`tick done\`):** ${a.dones}`);
    out.push(`- **Used \`tick scope\`:** ${a.scope_changes > 0 ? `yes (${a.scope_changes})` : 'no'}`);
    out.push(`- **Used \`tick break\`:** ${a.breaks > 0 ? `yes (${a.breaks})` : 'no'}`);
    out.push(`- **Releases:** ${a.releases} (${a.handoffs} as handoff), comments: ${a.comments}`);
    out.push(`- **Heartbeats (\`tick ping\`):** ${a.heartbeats}`);
    out.push('');
  }
  const c = report.cost;
  if (c) {
    const tk = c.tokens;
    const ge = tk.partial ? '≥' : '';
    out.push('### Cost');
    out.push('');
    out.push(`- **Run type:** \`${c.run_type}\`` +
      (c.run_type === 'unspecified' ? ' _(set `TICK_RUN_TYPE=symmetric|asymmetric` — comparisons across run types are not apples-to-apples)_' : ''));
    out.push(`- **Tokens:** ${ge}${tk.tokens_total} total (${ge}${tk.tokens_in} in / ${ge}${tk.tokens_out} out)` +
      (tk.partial
        ? ` — ⚠️ **PARTIAL (floor only):** ${tk.coverage} done-tasks instrumented; treat as a lower bound, not an exact sum`
        : ''));
    out.push(`- **Human minutes (self-reported):** ${c.human_minutes_total}`);
    out.push(`- **Wall-clock (run window):** ${humanDuration(c.walltime.run_window_ms)}`);
    if (c.per_unit.tokens_per_done !== null) {
      out.push(`- **Cost per done-task:** ${ge}${c.per_unit.tokens_per_done} tokens, ${humanDuration(c.per_unit.walltime_per_done_ms)} wall-clock`);
    } else {
      out.push('- **Cost per done-task:** n/a (0 tasks done)');
    }
    if (c.memory && (c.memory.compressor_peak_mb !== null || c.memory.swap_free_min_mb !== null || Object.keys(c.memory.by_agent).length > 0)) {
      const memBits = [];
      if (c.memory.compressor_peak_mb !== null) memBits.push(`compressor peak: ${c.memory.compressor_peak_mb}MB`);
      if (c.memory.swap_free_min_mb !== null) memBits.push(`swap free min: ${c.memory.swap_free_min_mb}MB`);
      if (memBits.length) out.push(`- **Memory:** ${memBits.join(', ')}`);
      if (Object.keys(c.memory.by_agent).length > 0) {
        const agentRss = Object.entries(c.memory.by_agent).map(([a, rss]) => `${a}: ${rss}MB peak RSS`).join(', ');
        out.push(`- **Turn peak RSS:** ${agentRss}`);
      }
    }
    out.push('');
  }
  out.push('> Drift / file-collision detection is deferred — the git transport was');
  out.push('> removed for the PoC, so there are no work commits to attribute. The');
  out.push('> coordinator inspects `git diff` by hand.');
  out.push('');
  return out.join('\n');
}

module.exports = { analyze, renderHuman, renderMd, buildClaimWindows, computeParallelism, findParkedClaims, PARKED_THRESHOLD_MS };
