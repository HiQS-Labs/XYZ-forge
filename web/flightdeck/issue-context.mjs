// Pure work-context selection shared by the browser and the manual harness.
function numbers(item) {
  return [...new Set([...(item.issues || []), item.issue].filter(n => Number.isInteger(n) && n > 0))];
}
function laneIssues(lane, repo = {}) {
  const prs = repo.prs || [];
  const result = numbers(lane).flatMap(number => {
    const pr = prs.find(item => item.number === number);
    return pr ? numbers(pr) : [number];
  });
  (lane.prs || []).forEach(number => {
    const pr = prs.find(item => item.number === number);
    if (pr) result.push(...numbers(pr));
  });
  return [...new Set(result)];
}
function issueCards(repo, now = Date.now()) {
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
    if (issue && issue.state && issue.state !== 'open') return;
    const prior = byNumber.get(number);
    const candidate = {number, title: issue?.title || `Issue #${number}`, inferred: !issue,
      context_at: at, context_reason: reason};
    if (!prior || Date.parse(at) > Date.parse(prior.context_at)) byNumber.set(number, candidate);
  };
  (repo.issues || []).filter(i => today(i.updated_at)).forEach(i => add(i.number, i.updated_at, 'Issue updated today'));
  (repo.lanes || []).filter(l => today(l.last_prompt_at)).forEach(l =>
    laneIssues(l, repo).forEach(n => add(n, l.last_prompt_at, 'Agent intent today')));
  (repo.events || []).filter(e => today(e.occurred_at)).forEach(e =>
    laneIssues(e, repo).forEach(n => add(n, e.occurred_at, 'Progress observed today')));
  (repo.prs || []).filter(p => p.state === 'open' && !p.is_merged).forEach(p =>
    numbers(p).forEach(n => add(n, p.updated_at, `Open PR #${p.number} · ${p.issue_basis || 'cached link'}`)));
  return [...byNumber.values()].sort((a,b) => (Date.parse(b.context_at) || 0) - (Date.parse(a.context_at) || 0));
}
export {numbers, laneIssues, issueCards};
