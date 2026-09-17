// Pure work-context selection shared by the browser and the manual harness.
function numbers(item) {
  return [...new Set([...(item.issues || []), item.issue].filter(n => Number.isInteger(n) && n > 0))];
}
function laneIssues(lane, repo = {}) {
  const prs = repo.prs || [];
  const result = numbers(lane);
  (lane.prs || []).forEach(number => {
    const pr = prs.find(item => item.number === number);
    if (pr) result.push(...numbers(pr));
  });
  return [...new Set(result)];
}
function issueStatus(issue, now = Date.now(), sourceHealthy = true) {
  const evidence = issue.work_evidence || [];
  const stamp = value => typeof value === 'string' && /(Z|[+-]\d{2}:\d{2})$/.test(value) ? Date.parse(value) : NaN;
  const fresh = (value, seconds) => Number.isFinite(stamp(value)) && now >= stamp(value) && now - stamp(value) <= seconds * 1000;
  const localLabel = evidence.some(e => e.status_label === 'in-progress');
  const nativeFresh = !issue.native_conflict && issue.native_identity_valid === true && ['open', 'closed'].includes(issue.state) && fresh(issue.fetched_at, issue.native_max_age_seconds || 7200);
  const nativeLabel = Array.isArray(issue.labels) && issue.labels.includes('in-progress');
  const result = (kind, label, reason) => ({kind, label, reason, native_at: issue.fetched_at || null,
    established_at: evidence.find(e => e.start)?.start.at || null});
  if (!sourceHealthy) return result('unknown', 'Read unavailable', 'Dashboard read failed or snapshot expired; verify recorded status');
  if (nativeFresh && issue.state === 'closed') {
    const label = issue.state_reason === 'not_planned' ? 'Cancelled' : issue.state_reason === 'completed' ? 'Completed' : 'Closed';
    return result('closed', label, localLabel || nativeLabel ? 'Closed; label cleanup pending' : 'Native issue is closed');
  }
  if (issue.native_conflict) return result('unknown', 'Conflicting observations', 'Equal-time native cache records disagree');
  if (issue.native_identity_valid === false) return result('unknown', 'Unavailable', 'Native issue identity does not agree');
  if (!nativeFresh) return result('unknown', 'Unverified', 'Native issue state is missing, stale or invalid');
  if (!Array.isArray(issue.labels)) return result('unknown', 'Unavailable', 'Cached GitHub labels are unavailable');
  if (!evidence.length) return result('unknown', 'Context only', nativeLabel ? 'GitHub label has no established XYZ start' : 'No configured XYZ evidence');
  if (evidence.some(e => !e.supported || e.error || e.roots_complete === false)) return result('unknown', 'Unavailable', 'XYZ evidence is unsupported or incomplete');
  if (evidence.some(e => !fresh(e.read_at, 300))) return result('unknown', 'Stale evidence', 'XYZ observation has expired');
  const signatures = new Set(evidence.map(e => JSON.stringify([e.status_label, e.start?.at || null, e.start?.event || null, e.lifecycle?.at || null, e.lifecycle?.event || null])));
  if (signatures.size > 1) return result('conflict', 'Conflicting records', 'Configured XYZ ledgers disagree');
  const established = evidence.every(e => e.status_label === 'in-progress' &&
    ['in_flight', 'jog_running', 'jog_leased'].includes(e.start?.event) &&
    Number.isFinite(stamp(e.start?.at)) && stamp(e.start.at) <= now);
  if (localLabel !== nativeLabel) return result('conflict', 'Label mismatch', 'XYZ and cached GitHub labels disagree');
  if (localLabel && !established) return result('unknown', 'Unverified label', 'No genuine unsuperseded task start');
  if (established && nativeLabel && issue.state === 'open') return result('in-progress', 'In progress',
    evidence.some(e => e.start.freshness === 'stale') ? 'Established work; old start, current execution unverified' : 'Explicit start and cached GitHub agree; execution not inferred');
  return result('context', 'Not marked active', 'Absent label is not completion');
}
function issueCards(repo, now = Date.now(), sourceHealthy = true) {
  const start = new Date(now); start.setHours(0, 0, 0, 0);
  // Keep workday context across quiet hours; the activity timeline stays one hour.
  const today = value => {
    const time = Date.parse(value);
    return Number.isFinite(time) && time >= start.getTime() && time <= now + 60000;
  };
  const byNumber = new Map();
  const add = (number, at, reason) => {
    if (!Number.isInteger(number) || number <= 0) return;
    const issue = (repo.issues || []).find(value => value.number === number);
    const recorded = issue?.work_evidence?.some(e => e.status_label === 'in-progress' || e.start || e.lifecycle || e.error);
    if (issue && issue.state && issue.state !== 'open' && !recorded) return;
    const prior = byNumber.get(number);
    const candidate = {number, title: issue?.title || `Issue #${number}`, inferred: !issue,
      context_at: at, context_reason: reason, workflow: issueStatus(issue || {}, now, sourceHealthy)};
    if (!prior || Date.parse(at) > Date.parse(prior.context_at)) byNumber.set(number, candidate);
  };
  (repo.issues || []).filter(i => (i.work_evidence || []).some(e => e.status_label === 'in-progress' || e.start || e.lifecycle || e.error))
    .forEach(i => add(i.number, i.work_evidence.find(e => e.start)?.start.at || null, 'Established XYZ evidence'));
  (repo.issues || []).filter(i => today(i.updated_at)).forEach(i => add(i.number, i.updated_at, 'Issue updated today'));
  (repo.lanes || []).filter(l => today(l.last_prompt_at)).forEach(l =>
    laneIssues(l, repo).forEach(n => add(n, l.last_prompt_at, 'Agent intent today')));
  (repo.events || []).filter(e => today(e.occurred_at)).forEach(e =>
    laneIssues(e, repo).forEach(n => add(n, e.occurred_at, 'Progress observed today')));
  (repo.prs || []).filter(p => p.state === 'open' && !p.is_merged).forEach(p =>
    numbers(p).forEach(n => add(n, p.updated_at, `Open PR #${p.number} · ${p.issue_basis || 'cached link'}`)));
  return [...byNumber.values()].sort((a,b) => (Number(b.workflow.kind === 'in-progress') - Number(a.workflow.kind === 'in-progress')) ||
    (Date.parse(b.context_at) || 0) - (Date.parse(a.context_at) || 0));
}
export {numbers, laneIssues, issueCards, issueStatus};
