// Synthetic observations only. No local readers are consulted by this module.
export function demoSnapshot(now = Date.now(), scenario = '') {
  const at = minutes => new Date(now - minutes * 60000).toISOString();
  const issue = (number, title, active = true) => ({number, title, state: 'open',
    native_identity_valid: true, fetched_at: at(1), updated_at: at(2),
    labels: active ? ['in-progress'] : [], work_evidence: active ? [{supported: true,
      roots_complete: true, read_at: at(1), status_label: 'in-progress',
      start: {event: 'in_flight', at: at(80), freshness: 'stale'}}] : []});
  const repos = [
    {id: 'demo:forge', name: 'XYZ Forge', issues: [issue(101, 'Keep the marathon moving'), issue(102, 'Make handoffs easier to inspect')],
      lanes: [{id: 'demo:codex', agent: 'Codex', task: 'Review the next handoff', issue: 101, last_prompt_at: at(4)},
        {id: 'demo:agy', agent: 'Agy', task: 'Check the containment boundary', issue: 102, last_prompt_at: at(12)}],
      prs: [{number: 41, title: 'Clarify the handoff receipt', state: 'open', issue: 101, updated_at: at(9), readiness: 'needs-qa'}],
      events: [{summary: 'Review receipt recorded', occurred_at: at(6), issue: 101}, {summary: 'Containment change observed', occurred_at: at(17), issue: 102}]},
    {id: 'demo:rebalance', name: 'Rebalance', issues: [issue(201, 'Reconnect work to its next action'), issue(202, 'Explore the daily overview', false)],
      lanes: [{id: 'demo:planner', agent: 'Codex', task: 'Trace the next-action source', issue: 201, last_prompt_at: at(23)}],
      prs: [{number: 52, title: 'Expose source freshness', state: 'open', issue: 201, updated_at: at(25), readiness: 'needs-qa'}],
      events: [{summary: 'Source mapping updated', occurred_at: at(28), issue: 201}]},
    {id: 'demo:catalog', name: 'AI Catalog', issues: [issue(301, 'Refresh the model comparison')], lanes: [], prs: [],
      events: [{summary: 'Catalog observation received', occurred_at: at(38), issue: 301}]}
  ];
  const snapshot = {schema_version: 1, snapshot_id: 'synthetic-preview', generated_at: at(0),
    coverage: 'partial', truncated: false, repos, sources: [
      {id: 'xyz_work', availability: 'ok', coverage: 'partial', observed_through: at(1)},
      {id: 'clio', availability: 'ok', coverage: 'partial', observed_through: at(4)},
      {id: 'git_pulse', availability: 'ok', coverage: 'partial', observed_through: at(6)},
      {id: 'topology', availability: 'disabled', coverage: 'none'}]};
  if (scenario === 'empty') snapshot.repos = [];
  if (scenario === 'stale') snapshot.generated_at = at(6);
  if (scenario === 'partial') snapshot.sources[0].error = 'issue-cap';
  if (scenario === 'hostile') repos[0].issues[0].title = '<img src=x onerror=alert(1)> & "literal source text"';
  return snapshot;
}
