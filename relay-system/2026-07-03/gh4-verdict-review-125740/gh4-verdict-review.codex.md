Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f298e-ed95-74d2-a904-835dc55dc9fc
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Review: GH-4 analyze verdict + work-stealing (PR #101)

Read ONLY these files directly (they are at the repo root of your worktree; do NOT search the wider
filesystem): **`src/analyze.js`** (the GH-4 additions: `computeCollisions`, `computeBalance`,
`computeVerdict`, `CONCURRENCY_TARGET_PCT`, their wiring into the report + `renderHuman`) and
**`src/take.js`** (the work-stealing candidate filter) and **`test/workstealing-verdict.sh`**.

## Context
The run success bar was "concurrency% AND each agent >= 2 done". A clean 2-lane/2-agent split gives 1
done each by construction, so a flawless run failed. Fix: (1) `tick analyze` emits a **verdict** gating
on concurrency% + zero-parked + all-lanes-done + zero-collisions, NOT per-agent done count; (2)
work-stealing via the existing `take` (a free agent pulls a collision-free `open` task from any lane);
(3) a lane-balance idle-tail line + a collisions metric.

## Answer these — graded [Blocker]/[Should]/[Nit]/[Pass], cite `src/analyze.js:LINE`

1. **Verdict correctness.** Is `computeVerdict` right? Specifically `all_lanes_done`: it treats a task
   as done iff a `task.done` exists, so a `circuit_broken` or still-open claimed lane => not done =>
   FAIL. Is that the correct semantics, or does it FALSE-FAIL a legitimate run — e.g. a task that was
   `released`/handed-off (so the window closed by release) and then `done` by ANOTHER agent (different
   window, same task id)? Does `claimedTasks` (built from window task ids) vs `doneTaskIds` handle
   handoff/re-claim correctly?
2. **Collision detection.** `computeCollisions` flags time-overlapping windows of DIFFERENT agents
   with overlapping paths. Still-open windows use `c = Infinity`. Any false positive (e.g. a released
   window whose `closedAt` is the release ts — correct) or false negative? Is comparing
   `Math.min(a.c,b.c) <= Math.max(a.o,b.o)` the right no-overlap test? Should it bound Infinity to
   runEnd? Could a legitimate reap/handoff (same task, sequential windows, different agents) be
   mis-flagged as a collision?
3. **Work-stealing collision-safety.** In `take.js`, the candidate filter excludes any `open` task
   whose paths overlap ANY active claim (other agents AND self). Is that airtight against a fast agent
   stealing a task that overlaps a live lane? Any TOCTOU or path-normalization gap?
4. **Env target.** `Number.isFinite(n) && n >= 0` for `TICK_CONCURRENCY_TARGET_PCT` — note `0` is
   accepted (means "don't gate on concurrency"). Intended? Any footgun (e.g. `>100` making pass
   impossible — is that a legitimate operator choice or a trap)?
5. **Consumer safety / determinism.** The report gains `verdict`/`collisions`/`balance` fields. Does
   that break `watchdog.sh`/`poll.sh` (which read `parked_suspects`) or any JSON consumer? Still a pure
   function of the event set (modulo the two env knobs)?

Be specific and adversarial; say [Pass] with a reason where a case is genuinely handled. End with a
one-line RECOMMENDATION (merge as-is / merge with nits / changes required).
hook: SessionStart
hook: SessionStart Completed
codex
Reading the three requested files directly and checking the verdict/collision/work-stealing logic against the stated success semantics.
exec
/bin/zsh -lc 'nl -ba src/take.js' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109
exec
/bin/zsh -lc 'nl -ba src/analyze.js' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109
 succeeded in 0ms:
     1	'use strict';
     2	
     3	const { appendEvent, readAllEvents } = require('./events');
     4	const { project, fold, nextEpoch, activeClaimsForAgent, MAX_ACTIVE_CLAIMS_PER_AGENT } = require('./project');
     5	const { setsOverlap } = require('./paths');
     6	const { withClaimLock } = require('./lock');
     7	
     8	// Atomic next+claim under one lock. Eliminates the TOCTOU gap between
     9	// `tick next` and `tick claim` where another agent can snatch the task
    10	// between the two calls.
    11	//
    12	// Uses the task's own declared paths as the claim paths (the agent can call
    13	// `tick scope` afterward if they need to narrow or expand).
    14	/**
    15	 * Atomically picks the next available task for `agent` and claims it.
    16	 * @param {string} repoRoot - absolute path to the repo root
    17	 * @param {Object} opts
    18	 * @param {string} opts.agent - the claiming agent
    19	 * @returns {{won: true, task: string, priority: number, handoff: boolean}
    20	 *         | {won: false, noTask: true}
    21	 *         | {limitReached: true, holding: string[]}}
    22	 */
    23	function take(repoRoot, { agent }) {
    24	  return withClaimLock(repoRoot, () => {
    25	    const events = readAllEvents(repoRoot);
    26	    const tasks = fold(events);
    27	
    28	    const held = activeClaimsForAgent(tasks, agent);
    29	    if (held.length >= MAX_ACTIVE_CLAIMS_PER_AGENT) {
    30	      return { limitReached: true, holding: held };
    31	    }
    32	
    33	    // Exclude paths held by ANY active claim — other agents (lane separation)
    34	    // *and* this agent's own (anti-gaming: stops one agent reserving two
    35	    // overlapping tasks in the same half and working them serially, which
    36	    // would inflate the concurrent-claim metric without real parallel work).
    37	    const claimedPaths = [];
    38	    for (const t of tasks.values()) {
    39	      if (t.status === 'claimed') {
    40	        for (const p of t.claim.paths) claimedPaths.push(p);
    41	      }
    42	    }
    43	
    44	    const candidates = [];
    45	    for (const t of tasks.values()) {
    46	      if (t.status !== 'open') continue;
    47	      if (setsOverlap(t.paths, claimedPaths)) continue;
    48	      if (t.handoff_to && t.handoff_to !== agent) continue;
    49	      candidates.push(t);
    50	    }
    51	
    52	    const handoffs = candidates.filter(t => t.handoff_to === agent);
    53	    let chosen;
    54	    if (handoffs.length) {
    55	      handoffs.sort((a, b) => b.priority - a.priority || a.id.localeCompare(b.id));
    56	      chosen = handoffs[0];
    57	    } else {
    58	      candidates.sort((a, b) => b.priority - a.priority || a.id.localeCompare(b.id));
    59	      chosen = candidates[0] || null;
    60	    }
    61	
    62	    if (!chosen) return { won: false, noTask: true };
    63	
    64	    appendEvent(repoRoot, { type: 'task.claimed', task: chosen.id, agent, paths: chosen.paths, epoch: nextEpoch(events, chosen.id) });
    65	    project(repoRoot);
    66	    return { won: true, task: chosen.id, priority: chosen.priority, handoff: chosen.handoff_to === agent };
    67	  });
    68	}
    69	
    70	module.exports = { take };

 succeeded in 0ms:
     1	'use strict';
     2	
     3	const { readAllEvents } = require('./events');
     4	const { setsOverlap } = require('./paths'); // GH-4: collision detection (overlapping concurrent claims)
     5	
     6	// Run 2: event-log-only analyzer.
     7	//
     8	// The git transport was removed, so there are no work commits to attribute —
     9	// per-commit drift and file-collision detection are deferred (the coordinator
    10	// inspects `git diff` by hand for the PoC). Everything here is derived purely
    11	// from .tick/events/. The primary metric is concurrent-claim time: how much of
    12	// the run window had two agents holding active claims at once.
    13	
    14	function toMs(ts) {
    15	  const t = Date.parse(ts);
    16	  return Number.isFinite(t) ? t : null;
    17	}
    18	
    19	function humanDuration(ms) {
    20	  if (!ms || ms < 0) return '0s';
    21	  const totalS = Math.round(ms / 1000);
    22	  const h = Math.floor(totalS / 3600);
    23	  const m = Math.floor((totalS % 3600) / 60);
    24	  const s = totalS % 60;
    25	  if (h > 0) return `${h}h ${m}m`;
    26	  if (m > 0) return `${m}m ${s}s`;
    27	  return `${s}s`;
    28	}
    29	
    30	/**
    31	 * Derives per-(agent, task) claim windows from the event timeline. A window
    32	 * opens at `task.claimed` and closes at the next terminal event for that task
    33	 * (`task.released` / `task.done` / `task.circuit_break`). At most one window
    34	 * is open per task at a time (claim.js refuses a second concurrent claimer).
    35	 * @param {Object[]} events - task.* events, chronological order
    36	 * @returns {Object[]} windows: `{task, agent, paths, openedAt, closedAt, closedBy}`
    37	 *   (`closedAt: null, closedBy: 'still_open'` for a window with no terminal event yet)
    38	 */
    39	function buildClaimWindows(events) {
    40	  const windows = [];
    41	  const byTask = new Map();
    42	  for (const ev of events) {
    43	    if (!byTask.has(ev.task)) byTask.set(ev.task, []);
    44	    byTask.get(ev.task).push(ev);
    45	  }
    46	
    47	  for (const [taskId, evs] of byTask) {
    48	    let open = null;
    49	    for (const ev of evs) {
    50	      if (ev.type === 'task.claimed') {
    51	        if (!open) {
    52	          open = { task: taskId, agent: ev.agent, paths: ev.paths || [], openedAt: ev.ts };
    53	        }
    54	      } else if (ev.type === 'task.scope_changed') {
    55	        if (open && open.agent === ev.agent && ev.paths) open.paths = ev.paths;
    56	      } else if (
    57	        ev.type === 'task.released' ||
    58	        ev.type === 'task.done' ||
    59	        ev.type === 'task.circuit_break'
    60	      ) {
    61	        if (open) {
    62	          windows.push({ ...open, closedAt: ev.ts, closedBy: ev.type });
    63	          open = null;
    64	        }
    65	      }
    66	    }
    67	    if (open) windows.push({ ...open, closedAt: null, closedBy: 'still_open' });
    68	  }
    69	  return windows;
    70	}
    71	
    72	/**
    73	 * Concurrent-claim-time metric (Run 2, P4): how much of the run window had
    74	 * >= 2 distinct agents each holding >= 1 active claim simultaneously. The
    75	 * primary success metric — per-agent task counts can be fooled by a lopsided
    76	 * split, this can't. An agent may hold up to 2 claims at once (the cap), so
    77	 * this measures distinct *agents* with an open window, not raw overlap.
    78	 * @param {Object[]} windows - as returned by {@link buildClaimWindows}
    79	 * @param {string} runStart - ISO timestamp of the run window start
    80	 * @param {string} runEnd - ISO timestamp of the run window end
    81	 * @returns {{concurrent_ms: number, run_window_ms: number, concurrent_pct: number|null}}
    82	 */
    83	function computeParallelism(windows, runStart, runEnd) {
    84	  const startMs = toMs(runStart);
    85	  const endMs = toMs(runEnd);
    86	  if (startMs === null || endMs === null || endMs <= startMs) {
    87	    return { concurrent_ms: 0, run_window_ms: 0, concurrent_pct: null };
    88	  }
    89	
    90	  const intervals = [];
    91	  for (const w of windows) {
    92	    const o = toMs(w.openedAt);
    93	    if (o === null) continue;
    94	    let c = w.closedAt ? toMs(w.closedAt) : endMs;
    95	    if (c === null) c = endMs;
    96	    const start = Math.max(o, startMs);
    97	    const end = Math.min(c, endMs);
    98	    if (end > start) intervals.push({ agent: w.agent, start, end });
    99	  }
   100	
   101	  const points = new Set([startMs, endMs]);
   102	  for (const iv of intervals) { points.add(iv.start); points.add(iv.end); }
   103	  const sorted = Array.from(points).sort((a, b) => a - b);
   104	
   105	  let concurrentMs = 0;
   106	  for (let i = 0; i < sorted.length - 1; i++) {
   107	    const segStart = sorted[i];
   108	    const segEnd = sorted[i + 1];
   109	    if (segEnd <= segStart) continue;
   110	    const agents = new Set();
   111	    for (const iv of intervals) {
   112	      if (iv.start <= segStart && iv.end >= segEnd) agents.add(iv.agent);
   113	    }
   114	    if (agents.size >= 2) concurrentMs += segEnd - segStart;
   115	  }
   116	
   117	  const runMs = endMs - startMs;
   118	  return {
   119	    concurrent_ms: concurrentMs,
   120	    run_window_ms: runMs,
   121	    concurrent_pct: runMs > 0 ? Math.round((concurrentMs / runMs) * 100) : null,
   122	  };
   123	}
   124	
   125	// GH-4: the run verdict must NOT gate on a fixed per-agent `done` count — a clean 2-lane / 2-agent
   126	// split gives 1 done each by construction, so ">= 2 done/agent" fails a flawless run. Gate instead on
   127	// what actually signals a good concurrent run: enough concurrency, zero parked suspects, every claimed
   128	// lane reached done, and zero collisions. This also unblocks work-stealing: a fast agent that `take`s a
   129	// second item from another lane (turning idle tail-time into real parallel work) produces an *imbalanced*
   130	// per-agent count that the old bar punished but this verdict rewards.
   131	const DEFAULT_CONCURRENCY_TARGET_PCT = 50;
   132	const _envConcTarget = Number(process.env.TICK_CONCURRENCY_TARGET_PCT);
   133	const CONCURRENCY_TARGET_PCT = Number.isFinite(_envConcTarget) && _envConcTarget >= 0
   134	  ? _envConcTarget
   135	  : DEFAULT_CONCURRENCY_TARGET_PCT;
   136	
   137	/**
   138	 * Collisions = pairs of time-overlapping claim windows held by DIFFERENT agents whose paths overlap.
   139	 * The claim lock should make this impossible, so a non-zero count is a real containment failure — the
   140	 * verdict's "zero collisions" gate verifies the invariant held rather than assuming it.
   141	 * @param {Object[]} windows - as returned by {@link buildClaimWindows}
   142	 * @returns {Object[]} `{tasks:[a,b], agents:[a,b]}` collision pairs
   143	 */
   144	function computeCollisions(windows) {
   145	  const iv = windows
   146	    .map(w => ({ task: w.task, agent: w.agent, paths: w.paths || [], o: toMs(w.openedAt), c: w.closedAt ? toMs(w.closedAt) : Infinity }))
   147	    .filter(w => w.o !== null);
   148	  const collisions = [];
   149	  for (let i = 0; i < iv.length; i++) {
   150	    for (let j = i + 1; j < iv.length; j++) {
   151	      const a = iv[i], b = iv[j];
   152	      if (a.agent === b.agent) continue;
   153	      if (Math.min(a.c, b.c) <= Math.max(a.o, b.o)) continue; // no time overlap
   154	      if (setsOverlap(a.paths, b.paths)) collisions.push({ tasks: [a.task, b.task], agents: [a.agent, b.agent] });
   155	    }
   156	  }
   157	  return collisions;
   158	}
   159	
   160	/**
   161	 * Per-agent idle-tail (lane balance): the wall-clock between an agent's LAST event and the run end.
   162	 * A large tail is the imbalance signal (fix 3) — the fast agent finished and idled while a slower lane
   163	 * ran on. Sorted worst-first.
   164	 * @param {Object[]} events - task.* events
   165	 * @param {string} runEnd - ISO run-window end
   166	 * @param {string[]} agentNames - agents to report (dispatcher already excluded)
   167	 * @returns {Object[]} `{agent, last_event, idle_tail_ms}` worst tail first
   168	 */
   169	function computeBalance(events, runEnd, agentNames) {
   170	  const endMs = toMs(runEnd);
   171	  const balance = [];
   172	  for (const name of agentNames) {
   173	    let last = null, lastTs = null;
   174	    for (const e of events) {
   175	      if (e.agent !== name) continue;
   176	      const t = toMs(e.ts);
   177	      if (t !== null && (last === null || t > last)) { last = t; lastTs = e.ts; }
   178	    }
   179	    if (last === null) continue;
   180	    balance.push({ agent: name, last_event: lastTs, idle_tail_ms: endMs !== null ? Math.max(0, endMs - last) : 0 });
   181	  }
   182	  balance.sort((a, b) => b.idle_tail_ms - a.idle_tail_ms || a.agent.localeCompare(b.agent));
   183	  return balance;
   184	}
   185	
   186	/**
   187	 * The run verdict (GH-4): pass/fail/incomplete on concurrency + parked + all-lanes-done + collisions,
   188	 * deliberately NOT on per-agent done counts.
   189	 * @returns {{verdict: 'pass'|'fail'|'incomplete', checks: Object, reasons: string[]}}
   190	 */
   191	function computeVerdict(parallelism, parkedSuspects, windows, doneTaskIds, collisions) {
   192	  const claimedTasks = new Set(windows.map(w => w.task));
   193	  const undone = Array.from(claimedTasks).filter(t => !doneTaskIds.has(t)).sort();
   194	  const pct = parallelism.concurrent_pct;
   195	  const checks = {
   196	    concurrency_pct: pct,
   197	    concurrency_target_pct: CONCURRENCY_TARGET_PCT,
   198	    concurrency_ok: pct !== null && pct >= CONCURRENCY_TARGET_PCT,
   199	    parked_ok: parkedSuspects.length === 0,
   200	    all_lanes_done: claimedTasks.size > 0 && undone.length === 0,
   201	    undone_tasks: undone,
   202	    no_collisions: collisions.length === 0,
   203	    collisions: collisions.length,
   204	  };
   205	  const reasons = [];
   206	  if (!checks.concurrency_ok) {
   207	    reasons.push(pct === null ? 'concurrency not computable' : `concurrency ${pct}% < ${CONCURRENCY_TARGET_PCT}% target`);
   208	  }
   209	  if (!checks.parked_ok) reasons.push(`${parkedSuspects.length} parked-claim suspect(s)`);
   210	  if (!checks.all_lanes_done) reasons.push(claimedTasks.size === 0 ? 'no lanes claimed' : `lanes not done: ${undone.join(', ')}`);
   211	  if (!checks.no_collisions) reasons.push(`${collisions.length} collision(s)`);
   212	  let verdict;
   213	  if (pct === null) verdict = 'incomplete';
   214	  else verdict = reasons.length === 0 ? 'pass' : 'fail';
   215	  return { verdict, checks, reasons };
   216	}
   217	
   218	// Parked-claim detection (Run 3). A claim window is a "parked-claim suspect" if
   219	// the holding agent showed no work-activity for longer than the threshold at any
   220	// point in the window. Activity points are: the claim itself (openedAt), every
   221	// `task.*` event the agent emitted for that task inside the window, and the window
   222	// close. The largest gap between consecutive activity points is the parked gap.
   223	// This reads only .tick/events/ — no git author / timestamp dependency (Run 2
   224	// removed distinct git identity). The criterion disqualifies a run with any
   225	// parked-claim suspect.
   226	//
   227	// GH-3: liveness is ANY `task.*` event from the agent, not just `task.heartbeat` —
   228	// an autonomous subagent in one long atomic tool call can't interleave a `tick ping`
   229	// (no yield point), but a `task.scope_changed`/`task.commented`/re-claim still proves
   230	// it's alive. The heartbeat-only signal false-flagged a fully-active run as parked.
   231	// The threshold is operator-tunable via TICK_PARKED_THRESHOLD_MS (default 10 min) so
   232	// an autonomous-agent marathon can raise it without a code change.
   233	const DEFAULT_PARKED_THRESHOLD_MS = 10 * 60 * 1000; // 10 minutes
   234	// Require a FINITE positive number: unset/empty/0/negative/non-numeric fall back to the default,
   235	// and — per the cross-model review of PR #100 — Infinity/NaN are rejected too, so a stray
   236	// `TICK_PARKED_THRESHOLD_MS=Infinity` can't silently make `maxGap > threshold` impossible (disabling
   237	// the gate entirely). A large FINITE value is still honored — that is a legitimate operator suppress.
   238	const _envParkedThresholdMs = Number(process.env.TICK_PARKED_THRESHOLD_MS);
   239	const PARKED_THRESHOLD_MS = Number.isFinite(_envParkedThresholdMs) && _envParkedThresholdMs > 0
   240	  ? _envParkedThresholdMs
   241	  : DEFAULT_PARKED_THRESHOLD_MS;
   242	
   243	/**
   244	 * Flags claim windows with no work-activity heartbeat for longer than
   245	 * `thresholdMs` at any point — a "parked-claim suspect", which disqualifies a
   246	 * run (Run 3 criterion). Activity points: the claim itself, every
   247	 * any `task.*` event the agent emitted for that task inside the window (GH-3), and
   248	 * the window close.
   249	 * @param {Object[]} windows - as returned by {@link buildClaimWindows}
   250	 * @param {Object[]} events - task.* events (agent activity read from here)
   251	 * @param {string} runEnd - ISO timestamp used as the close time for still-open windows
   252	 * @param {number} [thresholdMs] - defaults to {@link PARKED_THRESHOLD_MS} (10 minutes, TICK_PARKED_THRESHOLD_MS-tunable)
   253	 * @returns {Object[]} suspects: `{task, agent, max_gap_ms, heartbeats, activity, opened_at, closed_at}`
   254	 */
   255	function findParkedClaims(windows, events, runEnd, thresholdMs = PARKED_THRESHOLD_MS) {
   256	  const endMs = toMs(runEnd);
   257	  const suspects = [];
   258	  for (const w of windows) {
   259	    const openMs = toMs(w.openedAt);
   260	    if (openMs === null) continue;
   261	    const closeMs = w.closedAt ? toMs(w.closedAt) : endMs;
   262	    if (closeMs === null || closeMs <= openMs) continue;
   263	
   264	    // GH-3: liveness = ANY task.* event from the holding agent for this task inside
   265	    // the window (not just task.heartbeat). The claim open and window close already
   266	    // bound it; these are the intermediate proofs the agent was alive.
   267	    const activityTs = events
   268	      .filter(e => e.agent === w.agent && e.task === w.task &&
   269	        typeof e.type === 'string' && e.type.startsWith('task.'))
   270	      .map(e => toMs(e.ts))
   271	      .filter(t => t !== null && t > openMs && t < closeMs);
   272	    // Reported heartbeat count stays the real task.heartbeat count (for the message).
   273	    const beats = events.filter(e =>
   274	      e.type === 'task.heartbeat' && e.task === w.task && e.agent === w.agent &&
   275	      (() => { const t = toMs(e.ts); return t !== null && t >= openMs && t <= closeMs; })()
   276	    ).length;
   277	
   278	    const points = [openMs, ...activityTs, closeMs].sort((a, b) => a - b);
   279	    let maxGap = 0;
   280	    for (let i = 0; i < points.length - 1; i++) {
   281	      maxGap = Math.max(maxGap, points[i + 1] - points[i]);
   282	    }
   283	    if (maxGap > thresholdMs) {
   284	      suspects.push({
   285	        task: w.task,
   286	        agent: w.agent,
   287	        max_gap_ms: maxGap,
   288	        heartbeats: beats,
   289	        activity: activityTs.length,
   290	        opened_at: w.openedAt,
   291	        closed_at: w.closedAt || null,
   292	      });
   293	    }
   294	  }
   295	  return suspects;
   296	}
   297	
   298	const RUN_TYPES = new Set(['symmetric', 'asymmetric']);
   299	
   300	// Cost section (Phase 2, COST-OBSERVABILITY-PLAN). Pure function of the cost.* events (which the
   301	// coordination math deliberately ignores) + the claim windows. Reports tokens / wall-clock /
   302	// human-minutes and cost-per-unit-of-work. `runType` is operator-set (never auto-guessed): we do
   303	// not infer whether a comparison is fair, so an unset value reports 'unspecified'.
   304	function computeCost(allEvents, windows, doneTaskIds, runWindowMs, runType) {
   305	  const doneCount = doneTaskIds.size;
   306	  const tokenEvents = allEvents.filter(e => e.type === 'cost.tokens');
   307	  const humanEvents = allEvents.filter(e => e.type === 'cost.human');
   308	
   309	  const byAgent = {};
   310	  let inT = 0, outT = 0, totT = 0;
   311	  const instrumentedTasks = new Set();
   312	  for (const e of tokenEvents) {
   313	    const i = Number(e.tokens_in) || 0;
   314	    const o = Number(e.tokens_out) || 0;
   315	    const t = Number(e.tokens_total);
   316	    const tt = Number.isFinite(t) ? t : i + o;
   317	    inT += i; outT += o; totT += tt;
   318	    if (!byAgent[e.agent]) byAgent[e.agent] = { tokens_in: 0, tokens_out: 0, tokens_total: 0 };
   319	    byAgent[e.agent].tokens_in += i;
   320	    byAgent[e.agent].tokens_out += o;
   321	    byAgent[e.agent].tokens_total += tt;
   322	    if (e.task) instrumentedTasks.add(e.task);
   323	  }
   324	
   325	  const humanMinutesTotal = humanEvents.reduce((s, e) => s + (Number(e.human_minutes) || 0), 0);
   326	
   327	  // Per-task + per-agent wall-clock from CLOSED claim windows (still-open windows have no duration).
   328	  const walltimeByTask = {};
   329	  const walltimeByAgent = {};
   330	  for (const w of windows) {
   331	    const o = toMs(w.openedAt);
   332	    const c = w.closedAt ? toMs(w.closedAt) : null;
   333	    if (o === null || c === null) continue;
   334	    const d = Math.max(0, c - o);
   335	    walltimeByTask[w.task] = (walltimeByTask[w.task] || 0) + d;
   336	    walltimeByAgent[w.agent] = (walltimeByAgent[w.agent] || 0) + d;
   337	  }
   338	
   339	  // Coverage measures how many DONE-tasks carry token data — that's what makes per-done trustworthy.
   340	  // (Tokens spent on not-yet-done tasks still count toward the total spend, but not toward coverage.)
   341	  // instrumentedDone < doneCount => tokens are a FLOOR, and the renderers must say so
   342	  // (Gemini r1 [Should] — never let a floor read as an exact sum).
   343	  let instrumentedCount = 0;
   344	  for (const id of doneTaskIds) if (instrumentedTasks.has(id)) instrumentedCount++;
   345	  const partial = instrumentedCount < doneCount;
   346	  const perDone = doneCount > 0;
   347	
   348	  return {
   349	    run_type: RUN_TYPES.has(runType) ? runType : 'unspecified',
   350	    tokens: {
   351	      tokens_in: inT, tokens_out: outT, tokens_total: totT,
   352	      by_agent: byAgent,
   353	      instrumented_tasks: instrumentedCount,
   354	      done_tasks: doneCount,
   355	      coverage: `${instrumentedCount}/${doneCount}`,
   356	      partial,
   357	    },
   358	    walltime: {
   359	      run_window_ms: runWindowMs,
   360	      by_task: walltimeByTask,
   361	      by_agent: walltimeByAgent,
   362	    },
   363	    human_minutes_total: humanMinutesTotal,
   364	    per_unit: {
   365	      // Floor when partial — flagged via tokens.partial so renderers prefix a "≥".
   366	      tokens_per_done: perDone ? Math.round(totT / doneCount) : null,
   367	      walltime_per_done_ms: perDone ? Math.round(runWindowMs / doneCount) : null,
   368	    },
   369	  };
   370	}
   371	
   372	/**
   373	 * Reads the full event log and computes the coordination + cost report:
   374	 * per-agent activity counts, the concurrent-claim-time metric, parked-claim
   375	 * suspects, and (from `cost.*` events) token/wall-clock/human-minute spend.
   376	 * @param {string} repoRoot - absolute path to the repo root
   377	 * @returns {Object} report — see {@link renderHuman}/{@link renderMd} for the rendered shape
   378	 */
   379	function analyze(repoRoot) {
   380	  const allEvents = readAllEvents(repoRoot);
   381	  // Coordination metrics are computed from task.* events only. cost.* events (tokens/human-minutes)
   382	  // are a separate Phase-2 concern — excluding them here keeps every coordination number (counts,
   383	  // run window, parked-claims) byte-identical to pre-cost runs. (COST-OBSERVABILITY-PLAN, Phase 1 QA.)
   384	  const events = allEvents.filter(e => typeof e.type === 'string' && e.type.startsWith('task.'));
   385	  const windows = buildClaimWindows(events);
   386	
   387	  const perAgent = new Map();
   388	  function ensureAgent(name) {
   389	    if (!perAgent.has(name)) {
   390	      perAgent.set(name, {
   391	        agent: name,
   392	        claims: 0,
   393	        scope_changes: 0,
   394	        dones: 0,
   395	        releases: 0,
   396	        handoffs: 0,
   397	        breaks: 0,
   398	        comments: 0,
   399	        heartbeats: 0,
   400	      });
   401	    }
   402	    return perAgent.get(name);
   403	  }
   404	
   405	  for (const ev of events) {
   406	    const a = ensureAgent(ev.agent);
   407	    switch (ev.type) {
   408	      case 'task.claimed': a.claims++; break;
   409	      case 'task.scope_changed': a.scope_changes++; break;
   410	      case 'task.done': a.dones++; break;
   411	      case 'task.released': a.releases++; if (ev.to_agent) a.handoffs++; break;
   412	      case 'task.circuit_break': a.breaks++; break;
   413	      case 'task.commented': a.comments++; break;
   414	      case 'task.heartbeat': a.heartbeats++; break;
   415	    }
   416	  }
   417	  // The dispatcher only seeds task.created events — drop it from per-agent.
   418	  perAgent.delete('dispatcher');
   419	
   420	  const eventTs = events.map(e => e.ts).sort();
   421	  const window = {
   422	    earliest_event: eventTs[0] || null,
   423	    latest_event: eventTs[eventTs.length - 1] || null,
   424	    total_events: events.length,
   425	  };
   426	
   427	  const parallelism = computeParallelism(windows, window.earliest_event, window.latest_event);
   428	  const parked_suspects = findParkedClaims(windows, events, window.latest_event);
   429	
   430	  const doneTaskIds = new Set(events.filter(e => e.type === 'task.done').map(e => e.task));
   431	  const cost = computeCost(allEvents, windows, doneTaskIds, parallelism.run_window_ms, process.env.TICK_RUN_TYPE);
   432	
   433	  // GH-4: collisions, lane balance, and a lane-count-independent verdict.
   434	  const collisions = computeCollisions(windows);
   435	  const balance = computeBalance(events, window.latest_event, Array.from(perAgent.keys()));
   436	  const verdict = computeVerdict(parallelism, parked_suspects, windows, doneTaskIds, collisions);
   437	
   438	  return {
   439	    window,
   440	    parallelism,
   441	    parked_suspects,
   442	    collisions,
   443	    balance,
   444	    verdict,
   445	    agents: Array.from(perAgent.values()).sort((a, b) => a.agent.localeCompare(b.agent)),
   446	    event_counts: {
   447	      created: events.filter(e => e.type === 'task.created').length,
   448	      claimed: events.filter(e => e.type === 'task.claimed').length,
   449	      released: events.filter(e => e.type === 'task.released').length,
   450	      scope_changed: events.filter(e => e.type === 'task.scope_changed').length,
   451	      heartbeat: events.filter(e => e.type === 'task.heartbeat').length,
   452	      done: events.filter(e => e.type === 'task.done').length,
   453	      circuit_break: events.filter(e => e.type === 'task.circuit_break').length,
   454	      commented: events.filter(e => e.type === 'task.commented').length,
   455	    },
   456	    cost,
   457	  };
   458	}
   459	
   460	/**
   461	 * Renders an {@link analyze} report as plain-text, for terminal output.
   462	 * @param {Object} report - as returned by {@link analyze}
   463	 * @returns {string}
   464	 */
   465	function renderHuman(report) {
   466	  const out = [];
   467	  out.push('=== tick analyze ===');
   468	  out.push(`window: ${report.window.earliest_event || '(none)'} → ${report.window.latest_event || '(none)'}`);
   469	  out.push(`events: ${report.window.total_events} (` +
   470	    Object.entries(report.event_counts).map(([k, v]) => `${k}:${v}`).join(', ') + ')');
   471	  const p = report.parallelism;
   472	  if (p && p.concurrent_pct !== null) {
   473	    out.push(`concurrent-claim time: ${humanDuration(p.concurrent_ms)} of ${humanDuration(p.run_window_ms)} run window (${p.concurrent_pct}%)`);
   474	  } else {
   475	    out.push('concurrent-claim time: not computable (run window too short)');
   476	  }
   477	  const ps = report.parked_suspects || [];
   478	  if (ps.length) {
   479	    out.push(`parked-claim suspects: ${ps.length} (DISQUALIFIES run)`);
   480	    for (const s of ps) {
   481	      out.push(`  ${s.task} (${s.agent}): max ${humanDuration(s.max_gap_ms)} with no heartbeat, ${s.heartbeats} beat(s)`);
   482	    }
   483	  } else {
   484	    out.push('parked-claim suspects: none');
   485	  }
   486	  // GH-4: collisions, lane balance, and the lane-count-independent verdict.
   487	  const cols = report.collisions || [];
   488	  if (cols.length) {
   489	    out.push(`collisions (overlapping concurrent claims): ${cols.length}`);
   490	    for (const x of cols) out.push(`  ${x.tasks.join(' ↔ ')} (${x.agents.join(' / ')})`);
   491	  } else {
   492	    out.push('collisions (overlapping concurrent claims): 0');
   493	  }
   494	  const bal = report.balance || [];
   495	  if (bal.length && bal[0].idle_tail_ms > 0) {
   496	    out.push(`lane balance: ${bal[0].agent} idle ${humanDuration(bal[0].idle_tail_ms)} tail (finished first) — a fast agent can \`tick take\` a free lane to fill it`);
   497	  } else if (bal.length) {
   498	    out.push('lane balance: even (no idle tail)');
   499	  }
   500	  const v = report.verdict;
   501	  if (v) {
   502	    out.push(v.verdict === 'pass'
   503	      ? 'VERDICT: PASS (concurrency + zero-parked + all-lanes-done + zero-collisions; NOT gated on per-agent done count)'
   504	      : `VERDICT: ${v.verdict.toUpperCase()} — ${v.reasons.join('; ') || 'run window too short'}`);
   505	  }
   506	  out.push('');
   507	  out.push('--- per agent ---');
   508	  for (const a of report.agents) {
   509	    out.push(`[${a.agent}]`);
   510	    out.push(`  claims: ${a.claims}, done: ${a.dones}, heartbeats: ${a.heartbeats}`);
   511	    out.push(`  released: ${a.releases} (${a.handoffs} as handoff), broken: ${a.breaks}, scope_changes: ${a.scope_changes}, commented: ${a.comments}`);
   512	    out.push('');
   513	  }
   514	  const c = report.cost;
   515	  if (c) {
   516	    const tk = c.tokens;
   517	    const ge = tk.partial ? '≥' : '';
   518	    out.push('--- cost ---');
   519	    out.push(`run type: ${c.run_type}`);
   520	    out.push(`tokens: ${ge}${tk.tokens_total} total (${ge}${tk.tokens_in} in / ${ge}${tk.tokens_out} out)` +
   521	      (tk.partial ? ` — PARTIAL, floor only: ${tk.coverage} done-tasks instrumented` : ''));
   522	    out.push(`human minutes (self-reported): ${c.human_minutes_total}`);
   523	    out.push(`wall-clock (run window): ${humanDuration(c.walltime.run_window_ms)}`);
   524	    if (c.per_unit.tokens_per_done !== null) {
   525	      out.push(`per done-task: ${ge}${c.per_unit.tokens_per_done} tokens, ${humanDuration(c.per_unit.walltime_per_done_ms)} wall-clock`);
   526	    } else {
   527	      out.push('per done-task: n/a (0 tasks done)');
   528	    }
   529	    out.push('');
   530	  }
   531	  return out.join('\n');
   532	}
   533	
   534	/**
   535	 * Renders an {@link analyze} report as markdown, for embedding in a doc/PR.
   536	 * @param {Object} report - as returned by {@link analyze}
   537	 * @returns {string}
   538	 */
   539	function renderMd(report) {
   540	  const out = [];
   541	  out.push('## Auto-analyzed (tick analyze)');
   542	  out.push('');
   543	  out.push(`- **Run window:** \`${report.window.earliest_event || '(none)'}\` → \`${report.window.latest_event || '(none)'}\``);
   544	  out.push(`- **Total events:** ${report.window.total_events} (${Object.entries(report.event_counts).filter(([_, v]) => v).map(([k, v]) => `${k}: ${v}`).join(', ') || 'none'})`);
   545	  const p = report.parallelism;
   546	  if (p && p.concurrent_pct !== null) {
   547	    out.push(`- **Concurrent-claim time (primary metric):** both agents held an active claim simultaneously for ${humanDuration(p.concurrent_ms)} of the ${humanDuration(p.run_window_ms)} run window (**${p.concurrent_pct}%**)`);
   548	  } else {
   549	    out.push('- **Concurrent-claim time (primary metric):** not computable (run window too short)');
   550	  }
   551	  const ps = report.parked_suspects || [];
   552	  if (ps.length) {
   553	    out.push(`- **Parked-claim suspects (DISQUALIFIES run):** ${ps.length} — ` +
   554	      ps.map(s => `${s.task}/${s.agent} (${humanDuration(s.max_gap_ms)} gap, ${s.heartbeats} beat(s))`).join('; '));
   555	  } else {
   556	    out.push('- **Parked-claim suspects:** none');
   557	  }
   558	  out.push('');
   559	  out.push('### Per-agent');
   560	  out.push('');
   561	  for (const a of report.agents) {
   562	    out.push(`#### ${a.agent}`);
   563	    out.push('');
   564	    out.push(`- **Tasks claimed:** ${a.claims}`);
   565	    out.push(`- **Tasks completed (\`tick done\`):** ${a.dones}`);
   566	    out.push(`- **Used \`tick scope\`:** ${a.scope_changes > 0 ? `yes (${a.scope_changes})` : 'no'}`);
   567	    out.push(`- **Used \`tick break\`:** ${a.breaks > 0 ? `yes (${a.breaks})` : 'no'}`);
   568	    out.push(`- **Releases:** ${a.releases} (${a.handoffs} as handoff), comments: ${a.comments}`);
   569	    out.push(`- **Heartbeats (\`tick ping\`):** ${a.heartbeats}`);
   570	    out.push('');
   571	  }
   572	  const c = report.cost;
   573	  if (c) {
   574	    const tk = c.tokens;
   575	    const ge = tk.partial ? '≥' : '';
   576	    out.push('### Cost');
   577	    out.push('');
   578	    out.push(`- **Run type:** \`${c.run_type}\`` +
   579	      (c.run_type === 'unspecified' ? ' _(set `TICK_RUN_TYPE=symmetric|asymmetric` — comparisons across run types are not apples-to-apples)_' : ''));
   580	    out.push(`- **Tokens:** ${ge}${tk.tokens_total} total (${ge}${tk.tokens_in} in / ${ge}${tk.tokens_out} out)` +
   581	      (tk.partial
   582	        ? ` — ⚠️ **PARTIAL (floor only):** ${tk.coverage} done-tasks instrumented; treat as a lower bound, not an exact sum`
   583	        : ''));
   584	    out.push(`- **Human minutes (self-reported):** ${c.human_minutes_total}`);
   585	    out.push(`- **Wall-clock (run window):** ${humanDuration(c.walltime.run_window_ms)}`);
   586	    if (c.per_unit.tokens_per_done !== null) {
   587	      out.push(`- **Cost per done-task:** ${ge}${c.per_unit.tokens_per_done} tokens, ${humanDuration(c.per_unit.walltime_per_done_ms)} wall-clock`);
   588	    } else {
   589	      out.push('- **Cost per done-task:** n/a (0 tasks done)');
   590	    }
   591	    out.push('');
   592	  }
   593	  out.push('> Drift / file-collision detection is deferred — the git transport was');
   594	  out.push('> removed for the PoC, so there are no work commits to attribute. The');
   595	  out.push('> coordinator inspects `git diff` by hand.');
   596	  out.push('');
   597	  return out.join('\n');
   598	}
   599	
   600	module.exports = { analyze, renderHuman, renderMd, buildClaimWindows, computeParallelism, findParkedClaims, PARKED_THRESHOLD_MS };

exec
/bin/zsh -lc 'nl -ba test/workstealing-verdict.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# GH-4: work-stealing (via the existing `tick take` candidate filter) + a lane-count-independent
     3	# `tick analyze` verdict. The scenario a clean 2-lane split can't satisfy under the OLD ">=2 done/agent"
     4	# bar: beta finishes its lane fast and STEALS a third task from a free lane (turning idle tail-time into
     5	# real parallel work), producing an imbalanced 2-vs-1 done count that the OLD bar failed — but the NEW
     6	# verdict PASSES on concurrency + zero-parked + all-lanes-done + zero-collisions.
     7	source "$(dirname "$0")/_setup.sh" workstealing-verdict
     8	
     9	tick_a init >/dev/null
    10	# 3 tasks in 3 disjoint lanes so a free agent can steal the third collision-free.
    11	TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created A1 --agent dispatcher --priority 10 --paths "a/**" >/dev/null
    12	TICK_TS=2026-05-04T10:00:00.100Z tick_a log task.created B1 --agent dispatcher --priority  8 --paths "b/**" >/dev/null
    13	TICK_TS=2026-05-04T10:00:00.200Z tick_a log task.created C1 --agent dispatcher --priority  5 --paths "c/**" >/dev/null
    14	
    15	# alice + beta start together (concurrency); take picks highest-priority collision-free open task.
    16	TICK_TS=2026-05-04T10:01:00.000Z tick_a take --agent alice >"$WORK/a1.out"
    17	grep -q "won: A1" "$WORK/a1.out" && pass "alice take -> A1 (highest priority)" || fail "alice take: $(cat "$WORK/a1.out")"
    18	TICK_TS=2026-05-04T10:01:00.000Z tick_a take --agent beta >"$WORK/b1.out"
    19	grep -q "won: B1" "$WORK/b1.out" && pass "beta take -> B1 (A1 already claimed by alice)" || fail "beta take: $(cat "$WORK/b1.out")"
    20	
    21	# beta finishes its lane fast, then STEALS C1 from the free lane (the work-stealing move).
    22	TICK_TS=2026-05-04T10:03:00.000Z tick_a done B1 --agent beta >/dev/null
    23	TICK_TS=2026-05-04T10:03:01.000Z tick_a take --agent beta >"$WORK/steal.out"
    24	grep -q "won: C1" "$WORK/steal.out" \
    25	  && pass "WORK-STEALING: free agent beta takes C1 from another lane (collision-free)" \
    26	  || fail "beta failed to steal C1: $(cat "$WORK/steal.out")"
    27	
    28	# beta must NOT be able to steal a task overlapping a live claim — prove the steal stays collision-safe.
    29	# (alice still holds a/**; there is no open task now, so a further take yields nothing.)
    30	TICK_TS=2026-05-04T10:03:02.000Z tick_a take --agent beta >"$WORK/nomore.out"
    31	grep -q "no available task" "$WORK/nomore.out" && pass "no collision-unsafe steal (board drained for beta)" || fail "unexpected: $(cat "$WORK/nomore.out")"
    32	
    33	TICK_TS=2026-05-04T10:05:00.000Z tick_a done A1 --agent alice >/dev/null
    34	TICK_TS=2026-05-04T10:06:00.000Z tick_a done C1 --agent beta  >/dev/null
    35	
    36	tick_a analyze --format json >"$WORK/an.json"
    37	
    38	# The crux: imbalanced per-agent done (beta 2, alice 1) — the OLD ">=2 done/agent" bar FAILS alice —
    39	# yet the verdict PASSES.
    40	node -e '
    41	  const r = JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
    42	  const v = r.verdict, c = v.checks;
    43	  const fail = (m) => { console.error("ASSERT: "+m); process.exit(1); };
    44	  if (v.verdict !== "pass") fail("verdict expected pass, got "+v.verdict+" reasons="+JSON.stringify(v.reasons));
    45	  if (!c.all_lanes_done) fail("all_lanes_done should be true (A1,B1,C1 all done)");
    46	  if (!c.no_collisions) fail("no_collisions should be true, got "+c.collisions);
    47	  if (!c.parked_ok) fail("parked_ok should be true");
    48	  if (!c.concurrency_ok) fail("concurrency should meet target, got "+c.concurrency_pct+"%");
    49	  const by = Object.fromEntries(r.agents.map(a => [a.agent, a.dones]));
    50	  if (by.beta !== 2) fail("beta should have 2 done (stole C1), got "+by.beta);
    51	  if (by.alice !== 1) fail("alice should have 1 done, got "+by.alice);
    52	  // the whole point: an imbalanced 2-vs-1 split still PASSES (not gated on per-agent done count).
    53	' "$WORK/an.json" \
    54	  && pass "VERDICT: PASS on an imbalanced 2-vs-1 done split (concurrency + all-done + 0 collisions; NOT per-agent done)" \
    55	  || fail "verdict/agent-count assertions failed (see ASSERT above)"
    56	
    57	# The balance report surfaces the idle tail (imbalance signal, fix 3).
    58	tick_a analyze | grep -qE "lane balance:" && pass "analyze surfaces a lane-balance line (idle-tail imbalance signal)" || fail "no lane balance line in human output"
    59	
    60	echo "  $TEST_NAME: $PASS pass, $FAIL fail"

codex
**Answer**

Changes required. `computeVerdict` mostly fixes the old false-fail and the `take` lock/filter is sound at claim time, but the new collision gate is not reliable because claim windows collapse all `scope_changed` path edits into one final path snapshot, so `zero-collisions` can both miss real overlaps and invent ones that never coexisted.

**Findings**

- [Blocker] `computeCollisions` is path-time incorrect when a claim’s scope changes. `buildClaimWindows` mutates one window’s `paths` in place on `task.scope_changed` instead of splitting the window at the change ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:55)), and `computeCollisions` then evaluates overlap using that single final snapshot for the whole window ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:146), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:154)). That means:
  false negative: window overlaps early, then narrows before close;
  false positive: window starts narrow, then expands later, but gets treated as broad from `openedAt`.
  Because verdict hard-gates on `no_collisions` ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:202), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:214)), this is not a cosmetic metric bug.

- [Pass] The `all_lanes_done` handoff case is handled correctly for the semantics you described. Verdict checks claimed task ids from all windows against the set of any `task.done` ids ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:192), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:193)), so a `released` window later completed by another agent still passes. A still-open or circuit-broken claim with no later `task.done` correctly fails ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:200)). The only caveat is that this is task-id based, not epoch based, so if the same task id can somehow have multiple independent lifecycles, one `task.done` would satisfy them all.

- [Pass] The time-overlap test itself is right for closed/released sequential windows. `Math.min(a.c, b.c) <= Math.max(a.o, b.o)` means “one interval ends at or before the other starts,” so adjacency at the same timestamp is non-overlap ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:153)). A release-then-reclaim handoff at the same instant should not be mis-flagged. I would not block on `Infinity` vs `runEnd`; with an analyzed event set, no later window can start after the run’s latest event anyway.

- [Pass] `take` closes the important TOCTOU at steal time. Candidate selection, claim-state read, and `task.claimed` append all happen under `withClaimLock(...)` ([src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:24), [src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:64)), and the filter excludes any open task overlapping any active claim, including self-held claims ([src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:37), [src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:47)). That is airtight for “don’t steal an already-overlapping open task.”

- [Should] Work-stealing safety is only as strong as current path declarations. `take` uses the open task’s declared `t.paths` and current active `t.claim.paths` ([src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:40), [src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:47)); it cannot stop a later `task.scope_changed` from expanding a live claim into another live lane. Given the collision metric bug above, that later overlap may also be analyzed incorrectly.

- [Should] `TICK_CONCURRENCY_TARGET_PCT=0` looks like an intentional “disable concurrency gate” escape hatch and is mechanically fine ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:133), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:198)). The footgun is `>100`: it is accepted silently and makes `concurrency_ok` impossible. Unlike the parked-threshold knob, there is no sanity bound or explicit warning. If that is meant as an operator override, it should be documented; otherwise clamp or reject it.

- [Pass] The report shape change is additive, not mutative: existing keys like `parked_suspects` are preserved and new fields are appended ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:438)). From these files alone, JSON consumers that read named fields should remain safe. The result is still a pure function of the event set plus the two env knobs (`TICK_CONCURRENCY_TARGET_PCT`, `TICK_PARKED_THRESHOLD_MS`, and separately `TICK_RUN_TYPE`) ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:132), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:238), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:431)). I do not see a compatibility break here from the files provided.

- [Should] The test only proves the happy path of three static, disjoint lanes and the new verdict on a 2-vs-1 split ([test/workstealing-verdict.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/test/workstealing-verdict.sh:10), [test/workstealing-verdict.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/test/workstealing-verdict.sh:44)). It does not exercise the risky cases this PR introduces: handoff/release followed by another agent’s `done`, still-open windows, or any `scope_changed` collision scenario.

**Recommendation**

Changes required: fix collision accounting to be scope-time aware, then add tests for handoff and scope-changed windows before merging.
tokens used
20,871
**Answer**

Changes required. `computeVerdict` mostly fixes the old false-fail and the `take` lock/filter is sound at claim time, but the new collision gate is not reliable because claim windows collapse all `scope_changed` path edits into one final path snapshot, so `zero-collisions` can both miss real overlaps and invent ones that never coexisted.

**Findings**

- [Blocker] `computeCollisions` is path-time incorrect when a claim’s scope changes. `buildClaimWindows` mutates one window’s `paths` in place on `task.scope_changed` instead of splitting the window at the change ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:55)), and `computeCollisions` then evaluates overlap using that single final snapshot for the whole window ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:146), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:154)). That means:
  false negative: window overlaps early, then narrows before close;
  false positive: window starts narrow, then expands later, but gets treated as broad from `openedAt`.
  Because verdict hard-gates on `no_collisions` ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:202), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:214)), this is not a cosmetic metric bug.

- [Pass] The `all_lanes_done` handoff case is handled correctly for the semantics you described. Verdict checks claimed task ids from all windows against the set of any `task.done` ids ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:192), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:193)), so a `released` window later completed by another agent still passes. A still-open or circuit-broken claim with no later `task.done` correctly fails ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:200)). The only caveat is that this is task-id based, not epoch based, so if the same task id can somehow have multiple independent lifecycles, one `task.done` would satisfy them all.

- [Pass] The time-overlap test itself is right for closed/released sequential windows. `Math.min(a.c, b.c) <= Math.max(a.o, b.o)` means “one interval ends at or before the other starts,” so adjacency at the same timestamp is non-overlap ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:153)). A release-then-reclaim handoff at the same instant should not be mis-flagged. I would not block on `Infinity` vs `runEnd`; with an analyzed event set, no later window can start after the run’s latest event anyway.

- [Pass] `take` closes the important TOCTOU at steal time. Candidate selection, claim-state read, and `task.claimed` append all happen under `withClaimLock(...)` ([src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:24), [src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:64)), and the filter excludes any open task overlapping any active claim, including self-held claims ([src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:37), [src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:47)). That is airtight for “don’t steal an already-overlapping open task.”

- [Should] Work-stealing safety is only as strong as current path declarations. `take` uses the open task’s declared `t.paths` and current active `t.claim.paths` ([src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:40), [src/take.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/take.js:47)); it cannot stop a later `task.scope_changed` from expanding a live claim into another live lane. Given the collision metric bug above, that later overlap may also be analyzed incorrectly.

- [Should] `TICK_CONCURRENCY_TARGET_PCT=0` looks like an intentional “disable concurrency gate” escape hatch and is mechanically fine ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:133), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:198)). The footgun is `>100`: it is accepted silently and makes `concurrency_ok` impossible. Unlike the parked-threshold knob, there is no sanity bound or explicit warning. If that is meant as an operator override, it should be documented; otherwise clamp or reject it.

- [Pass] The report shape change is additive, not mutative: existing keys like `parked_suspects` are preserved and new fields are appended ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:438)). From these files alone, JSON consumers that read named fields should remain safe. The result is still a pure function of the event set plus the two env knobs (`TICK_CONCURRENCY_TARGET_PCT`, `TICK_PARKED_THRESHOLD_MS`, and separately `TICK_RUN_TYPE`) ([src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:132), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:238), [src/analyze.js](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/src/analyze.js:431)). I do not see a compatibility break here from the files provided.

- [Should] The test only proves the happy path of three static, disjoint lanes and the new verdict on a 2-vs-1 split ([test/workstealing-verdict.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/test/workstealing-verdict.sh:10), [test/workstealing-verdict.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-15410-24109/test/workstealing-verdict.sh:44)). It does not exercise the risky cases this PR introduces: handoff/release followed by another agent’s `done`, still-open windows, or any `scope_changed` collision scenario.

**Recommendation**

Changes required: fix collision accounting to be scope-time aware, then add tests for handoff and scope-changed windows before merging.
