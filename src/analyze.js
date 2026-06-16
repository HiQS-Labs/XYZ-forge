'use strict';

const { readAllEvents } = require('./events');

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

// Per-(agent, task) claim windows from the event timeline. A window opens at
// task.claimed and closes at the next terminal event for that task
// (task.released / task.done / task.circuit_break). With the git transport
// gone there is no tie-breaker and no auto-release — claim.js refuses a second
// claimer outright — so at most one window is open per task at a time.
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
          open = { task: taskId, agent: ev.agent, paths: ev.paths || [], openedAt: ev.ts };
        }
      } else if (ev.type === 'task.scope_changed') {
        if (open && open.agent === ev.agent && ev.paths) open.paths = ev.paths;
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

// Concurrent-claim-time metric (Run 2, P4). How much of the run window had
// >= 2 distinct agents each holding >= 1 active claim simultaneously. This is
// the primary success metric — per-agent task counts can be fooled by a
// lopsided split, this can't. An agent may hold up to 2 claims at once (the
// cap), so we measure distinct *agents* with an open window, not raw overlap.
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

// Parked-claim detection (Run 3). A claim window is a "parked-claim suspect" if
// the holding agent showed no work-activity heartbeat for longer than the
// threshold at any point in the window. Activity points are: the claim itself
// (openedAt), every task.heartbeat the agent emitted for that task inside the
// window, and the window close. The largest gap between consecutive activity
// points is the parked gap. This reads only .tick/events/ — no git author /
// timestamp dependency (Run 2 removed distinct git identity). The redefined Run
// 3 criterion disqualifies a run with any parked-claim suspect.
const PARKED_THRESHOLD_MS = 10 * 60 * 1000; // 10 minutes

function findParkedClaims(windows, events, runEnd, thresholdMs = PARKED_THRESHOLD_MS) {
  const endMs = toMs(runEnd);
  const suspects = [];
  for (const w of windows) {
    const openMs = toMs(w.openedAt);
    if (openMs === null) continue;
    const closeMs = w.closedAt ? toMs(w.closedAt) : endMs;
    if (closeMs === null || closeMs <= openMs) continue;

    const beats = events
      .filter(e => e.type === 'task.heartbeat' && e.task === w.task && e.agent === w.agent)
      .map(e => toMs(e.ts))
      .filter(t => t !== null && t >= openMs && t <= closeMs);

    const points = [openMs, ...beats, closeMs].sort((a, b) => a - b);
    let maxGap = 0;
    for (let i = 0; i < points.length - 1; i++) {
      maxGap = Math.max(maxGap, points[i + 1] - points[i]);
    }
    if (maxGap > thresholdMs) {
      suspects.push({
        task: w.task,
        agent: w.agent,
        max_gap_ms: maxGap,
        heartbeats: beats.length,
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
    per_unit: {
      // Floor when partial — flagged via tokens.partial so renderers prefix a "≥".
      tokens_per_done: perDone ? Math.round(totT / doneCount) : null,
      walltime_per_done_ms: perDone ? Math.round(runWindowMs / doneCount) : null,
    },
  };
}

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
  const window = {
    earliest_event: eventTs[0] || null,
    latest_event: eventTs[eventTs.length - 1] || null,
    total_events: events.length,
  };

  const parallelism = computeParallelism(windows, window.earliest_event, window.latest_event);
  const parked_suspects = findParkedClaims(windows, events, window.latest_event);

  const doneTaskIds = new Set(events.filter(e => e.type === 'task.done').map(e => e.task));
  const cost = computeCost(allEvents, windows, doneTaskIds, parallelism.run_window_ms, process.env.TICK_RUN_TYPE);

  return {
    window,
    parallelism,
    parked_suspects,
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

function renderHuman(report) {
  const out = [];
  out.push('=== tick analyze ===');
  out.push(`window: ${report.window.earliest_event || '(none)'} → ${report.window.latest_event || '(none)'}`);
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
    out.push('');
  }
  return out.join('\n');
}

function renderMd(report) {
  const out = [];
  out.push('## Auto-analyzed (tick analyze)');
  out.push('');
  out.push(`- **Run window:** \`${report.window.earliest_event || '(none)'}\` → \`${report.window.latest_event || '(none)'}\``);
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
    out.push('');
  }
  out.push('> Drift / file-collision detection is deferred — the git transport was');
  out.push('> removed for the PoC, so there are no work commits to attribute. The');
  out.push('> coordinator inspects `git diff` by hand.');
  out.push('');
  return out.join('\n');
}

module.exports = { analyze, renderHuman, renderMd, buildClaimWindows, computeParallelism, findParkedClaims, PARKED_THRESHOLD_MS };
