'use strict';

const $ = id => document.getElementById(id);
const refs = {
  repos: $('repos'), sourceStrip: $('sourceStrip'), empty: $('empty'), template: $('repoTemplate'),
  detail: $('detail'), detailTitle: $('detailTitle'), detailEyebrow: $('detailEyebrow'), detailBody: $('detailBody'),
  viewTitle: $('viewTitle'), focusMode: $('focusMode'), closeView: $('closeView'), theme: $('theme'),
  fadeLeft: $('fadeLeft'), fadeRight: $('fadeRight'), breadcrumbs: $('breadcrumbs')
};
const state = {snapshot: null, view: 'a', repoId: null, spotlightId: null, failures: 0, request: 0, theme: localStorage.getItem('flightdeck-theme') || 'system'};
const accents = ['accent-1', 'accent-2', 'accent-3', 'accent-4', 'accent-5', 'accent-6', 'accent-7'];

function node(tag, className, text) {
  const el = document.createElement(tag);
  if (className) el.className = className;
  if (text !== undefined && text !== null) el.textContent = String(text);
  return el;
}
function ageMinutes(value) {
  const time = value ? Date.parse(value) : NaN;
  if (!Number.isFinite(time) || time > Date.now() + 60000) return null;
  return Math.max(0, Math.floor((Date.now() - time) / 60000));
}
function ageLabel(value) {
  const age = ageMinutes(value);
  if (age === null) return 'unknown';
  if (age < 60) return `${age}m`;
  return `${Math.floor(age / 60)}h ${String(age % 60).padStart(2, '0')}m`;
}
function initials(name) {
  return name.split(/\s+/).filter(Boolean).slice(0, 2).map(word => word[0]).join('').toUpperCase() || '•';
}
function sourcesFor(repo) {
  return [...new Set([...(repo.source_refs || []), ...(repo.events || []).map(event => event.source_ref), ...(repo.lanes || []).map(lane => lane.source_ref)].filter(Boolean))];
}
function health(repo) {
  const age = ageMinutes(repo.last_progress_at);
  const intentAge = ageMinutes(repo.last_intent_at);
  if (age !== null && age < 60) return {tone: 'green', label: 'Progress this hour', detail: `${ageLabel(repo.last_progress_at)} ago`};
  if (intentAge !== null && intentAge < 60) return {tone: 'green', label: 'Agent active · progress pending', detail: `Prompt ${ageLabel(repo.last_intent_at)} ago`};
  const relevant = (state.snapshot?.sources || []).filter(source => sourcesFor(repo).includes(source.id));
  const complete = relevant.length > 0 && relevant.every(source => source.availability === 'ok' && source.coverage === 'complete');
  if (age !== null && age < 120) return {tone: 'amber', label: 'Quiet · check in', detail: `${ageLabel(repo.last_progress_at)} since progress`};
  if (!complete || age === null) return {tone: 'unknown', label: 'No recent progress observed', detail: age === null ? 'Attested progress feed has no anchor' : `Last seen ${ageLabel(repo.last_progress_at)} ago · partial sources`};
  if (age < 120) return {tone: 'amber', label: 'Check in with this lane', detail: `${ageLabel(repo.last_progress_at)} ago`};
  return {tone: 'red', label: 'No covered progress for 2h', detail: `${ageLabel(repo.last_progress_at)} ago`};
}
function recent(items, field, minutes = 60) {
  return (items || []).filter(item => {
    const age = ageMinutes(item[field]);
    return age !== null && age < minutes;
  });
}
function addMetric(parent, value, label) {
  const box = node('div', 'metric');
  box.append(node('strong', '', value), node('span', '', label));
  parent.append(box);
}
function addEmpty(parent, text) { parent.append(node('p', 'empty-copy', text)); }
function addTimeline(parent, events) {
  if (!events.length) return addEmpty(parent, 'No attested progress recorded in this hour.');
  events.slice(0, 4).forEach(event => {
    const row = node('div', 'row');
    row.append(node('time', '', `${ageLabel(event.occurred_at)} ago`), node('p', '', event.summary || event.kind || 'Activity'));
    parent.append(row);
  });
}
function laneIssues(lane) {
  return [...new Set([...(lane.issues || []), lane.issue].filter(Number.isInteger))];
}
function addIssues(parent, issues, lanes) {
  const byNumber = new Map();
  issues.forEach(issue => byNumber.set(issue.number, issue));
  lanes.forEach(lane => laneIssues(lane).forEach(number => {
    if (!byNumber.has(number)) byNumber.set(number, {number, title: lane.task, inferred: true});
  }));
  if (!byNumber.size) return addEmpty(parent, 'No source-linked issue context.');
  [...byNumber.values()].slice(0, 4).forEach(issue => {
    const row = node('div', 'row');
    const badge = node('span', 'badge', `#${issue.number}`);
    const copy = node('p', '', issue.title || 'Issue');
    if (issue.inferred) copy.append(node('small', '', 'Inferred from agent intent'));
    row.append(badge, copy); parent.append(row);
  });
}
function addPrs(parent, prs) {
  if (!prs.length) return addEmpty(parent, 'PR inventory unavailable or empty.');
  prs.slice(0, 4).forEach(pr => {
    const row = node('div', 'row');
    row.append(node('span', `badge ${pr.readiness || 'needs-qa'}`, `#${pr.number}`));
    const copy = node('p', '', pr.title || 'Pull request');
    copy.append(node('small', '', pr.readiness_reason || 'Verification needed'));
    row.append(copy); parent.append(row);
  });
}
function repoCard(repo, index, total, issue = null) {
  const card = refs.template.content.firstElementChild.cloneNode(true);
  const cardId = issue ? `${repo.id}#${issue.number}` : repo.id;
  const events = recent(repo.events || [], 'occurred_at').filter(event => !issue || event.issue === issue.number);
  const allLanes = issue ? (repo.lanes || []).filter(lane => laneIssues(lane).includes(issue.number)) : (repo.lanes || []);
  const lanes = issue ? allLanes : recent(allLanes, 'last_prompt_at');
  const issues = issue ? [issue] : recent(repo.issues || [], 'updated_at');
  const prs = issue ? (repo.prs || []).filter(pr => pr.issue === issue.number) : (repo.prs || []);
  const status = health(repo);
  card.dataset.cardId = cardId;
  card.dataset.repoId = repo.id;
  if (issue) card.dataset.issue = String(issue.number);
  card.classList.add(accents[index % accents.length]);
  card.classList.toggle('is-focused', state.spotlightId === cardId);
  card.querySelector('.repo-mark').textContent = issue ? `#${issue.number}` : initials(repo.name);
  card.querySelector('.position').textContent = `${String(index + 1).padStart(2, '0')} / ${String(total).padStart(2, '0')}`;
  card.querySelector('.repo-name').textContent = issue ? (issue.title || `Issue #${issue.number}`) : repo.name;
  card.querySelector('.repo-summary').textContent = issue ? repo.name : (repo.summary || 'Keep this lane visible and moving.');
  const healthEl = card.querySelector('.health');
  healthEl.classList.add(status.tone);
  healthEl.querySelector('strong').textContent = status.label;
  healthEl.querySelector('span').textContent = status.detail;
  const nextAction = lanes[0]?.task || repo.next_actions?.[0]?.title || 'Re-establish context with this lane.';
  card.querySelector('.next-action strong').textContent = nextAction;
  const metrics = card.querySelector('.metrics');
  addMetric(metrics, repo.checkout_count ?? (repo.known_checkout_count ? `${repo.known_checkout_count}+` : '—'), 'checkouts');
  addMetric(metrics, lanes.length, 'agent lanes');
  addMetric(metrics, prs.length, 'cached open PRs');
  card.querySelector('.hour-count').textContent = `${events.length} updates`;
  addTimeline(card.querySelector('.timeline'), events);
  card.querySelector('.issues-title').textContent = issue ? 'Agents on issue' : 'Issues in flight';
  card.querySelector('.issue-count').textContent = issue ? `${lanes.length} lanes` : `${issues.length} observed`;
  if (issue) {
    const issueBox = card.querySelector('.issues');
    if (!lanes.length) addEmpty(issueBox, 'No agent lane linked to this issue.');
    lanes.slice(0, 4).forEach(lane => {
      const row = node('div', 'row');
      row.append(node('span', 'badge', lane.agent || 'Agent'), node('p', '', lane.task || 'Intent unavailable'));
      issueBox.append(row);
    });
  } else addIssues(card.querySelector('.issues'), issues, lanes);
  card.querySelector('.pr-count').textContent = `${prs.length} cached`;
  addPrs(card.querySelector('.prs'), prs);
  card.querySelector('.connector-evidence').textContent = sourcesFor(repo).join(' · ') || 'source unknown';
  card.querySelector('.details').addEventListener('click', event => { event.stopPropagation(); openDetail(repo, issue); });
  card.addEventListener('click', () => activateCard(cardId, repo));
  card.addEventListener('keydown', event => {
    if ((event.key === 'Enter' || event.key === ' ') && event.target === card) { event.preventDefault(); activateCard(cardId, repo); }
  });
  return card;
}
function activateCard(cardId, repo) {
  if (state.spotlightId !== cardId) {
    state.spotlightId = cardId;
    render();
    document.querySelector(`[data-card-id="${CSS.escape(cardId)}"]`)?.focus();
    return;
  }
  if (state.view === 'b') navigate('c', repo.id);
  else if (state.view === 'a') openDetail(repo);
}
function selectedRepos() {
  const repos = state.snapshot?.repos || [];
  const saved = JSON.parse(localStorage.getItem('flightdeck-repos') || '[]');
  const selected = Array.isArray(saved) ? saved.map(id => repos.find(repo => repo.id === id)).filter(Boolean) : [];
  return [...selected, ...repos.filter(repo => !selected.includes(repo))].slice(0, 7);
}
function issueCards(repo) {
  const byNumber = new Map(recent(repo.issues || [], 'updated_at').map(issue => [issue.number, issue]));
  recent(repo.lanes || [], 'last_prompt_at').forEach(lane => laneIssues(lane).forEach(number => {
    if (!byNumber.has(number)) byNumber.set(number, {number, title: lane.task, inferred: true});
  }));
  return [...byNumber.values()];
}
function renderSources() {
  refs.sourceStrip.replaceChildren();
  (state.snapshot?.sources || []).forEach(source => {
    const pill = node('span', `source-pill ${source.availability}`);
    pill.title = source.error || `Coverage: ${source.coverage}; observed ${source.observed_through || 'unknown'}`;
    pill.append(node('i'), node('span', '', `${source.id} · ${source.availability}`));
    refs.sourceStrip.append(pill);
  });
}
function renderBreadcrumbs() {
  refs.breadcrumbs.replaceChildren();
  const repo = (state.snapshot?.repos || []).find(item => item.id === state.repoId);
  const levels = state.view === 'a'
    ? [{label: 'Home'}]
    : state.view === 'b'
      ? [{label: 'Home', view: 'a'}, {label: 'Repository Focus'}]
      : [{label: 'Home', view: 'a'}, {label: 'Repository Focus', view: 'b', repoId: state.repoId}, {label: `${repo?.name || 'Repository'} Issues`}];
  levels.forEach((level, index) => {
    if (index) refs.breadcrumbs.append(node('span', 'breadcrumb-separator', '›'));
    if (level.view) {
      const button = node('button', 'breadcrumb-link', level.label);
      button.type = 'button';
      button.addEventListener('click', () => navigate(level.view, level.repoId || null));
      refs.breadcrumbs.append(button);
    } else {
      const current = node('span', 'breadcrumb-current', level.label);
      current.setAttribute('aria-current', 'page');
      refs.breadcrumbs.append(current);
    }
  });
}
function render() {
  document.body.classList.toggle('focus-view', state.view === 'b');
  document.body.classList.toggle('issue-view', state.view === 'c');
  document.body.classList.toggle('spotlight', Boolean(state.spotlightId));
  refs.closeView.hidden = state.view === 'a';
  refs.fadeLeft.hidden = refs.fadeRight.hidden = state.view === 'a';
  refs.focusMode.hidden = state.view !== 'a';
  renderBreadcrumbs();
  renderSources();
  refs.repos.replaceChildren();
  let cards = [];
  if (state.view === 'c') {
    const repo = (state.snapshot?.repos || []).find(item => item.id === state.repoId);
    refs.viewTitle.textContent = repo ? `${repo.name} issues` : 'Repository unavailable';
    cards = repo ? issueCards(repo).map((issue, index, all) => repoCard(repo, index, all.length, issue)) : [];
  } else {
    const repos = selectedRepos();
    refs.viewTitle.textContent = state.view === 'b' ? 'Repository focus' : 'Active repositories';
    cards = repos.map((repo, index) => repoCard(repo, index, repos.length));
  }
  cards.forEach(card => refs.repos.append(card));
  if (!cards.length && state.view === 'c') {
    const repo = (state.snapshot?.repos || []).find(item => item.id === state.repoId);
    $('emptyTitle').textContent = 'No issue-linked activity this hour.';
    $('emptyCopy').textContent = repo ? `${repo.name} remains selected. Recent source data did not establish an active issue; older context is preserved in the overview.` : 'The selected repository is unavailable in this snapshot.';
  } else {
    $('emptyTitle').textContent = 'Flightdeck is ready for connectors.';
    $('emptyCopy').textContent = 'Start or configure any incoming connector. The dashboard itself remains available.';
  }
  refs.empty.hidden = cards.length > 0;
  refs.repos.hidden = cards.length === 0;
}
function navigate(view, repoId = null, replace = false) {
  state.view = view; state.repoId = repoId; state.spotlightId = view === 'b' ? repoId : null;
  const url = new URL(location.href); url.search = ''; url.searchParams.set('view', view); if (repoId) url.searchParams.set('repo', repoId);
  history[replace ? 'replaceState' : 'pushState']({view, repoId}, '', url);
  render();
}
function backOneLevel() {
  if (refs.detail.open) return refs.detail.close();
  if (state.spotlightId) { state.spotlightId = null; render(); return; }
  if (state.view === 'c') return navigate('b', state.repoId);
  if (state.view === 'b') return navigate('a');
}
function openDetail(repo, issue = null) {
  const lanes = issue ? (repo.lanes || []).filter(lane => lane.issue === issue.number) : (repo.lanes || []);
  const lane = lanes[0];
  refs.detailEyebrow.textContent = `${repo.name}${issue ? ` · #${issue.number}` : ''}`;
  refs.detailTitle.textContent = lane?.agent ? `Continue with ${lane.agent}` : 'Re-establish this lane';
  refs.detailBody.replaceChildren();
  const summary = node('section', 'drawer-section');
  const action = lane?.task || repo.next_actions?.[0]?.title || issue?.title || repo.summary || 'No agent context is available.';
  summary.append(node('h3', '', 'Current context'), node('p', '', action));
  const handoff = node('section', 'drawer-section');
  handoff.append(node('h3', '', 'Copyable handoff'));
  const text = node('textarea'); text.readOnly = true;
  text.value = `Resume ${repo.name}${issue ? ` issue #${issue.number}` : ''}.\n\nLast known context: ${action}\nLast meaningful progress: ${repo.last_progress_at || 'unknown'}.\n\nConfirm the current branch, issue and PR head before continuing. Report the next concrete milestone.`;
  const copy = node('button', 'details copy', 'Copy handoff'); copy.type = 'button';
  copy.addEventListener('click', async () => {
    try { await navigator.clipboard.writeText(text.value); copy.textContent = 'Copied'; }
    catch { text.select(); copy.textContent = 'Selected — press ⌘C'; }
  });
  handoff.append(text, copy); refs.detailBody.append(summary, handoff); refs.detail.showModal();
}
async function refresh(manual = false) {
  if (document.hidden && !manual) return;
  const request = ++state.request;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 6000);
  try {
    const response = await fetch('/flightdeck.json', {cache: 'no-store', signal: controller.signal});
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const snapshot = await response.json();
    if (request !== state.request || snapshot.schema_version !== 1 || !Array.isArray(snapshot.repos)) return;
    state.snapshot = snapshot; state.failures = 0;
    sessionStorage.setItem('flightdeck-last-good', JSON.stringify(snapshot)); render();
  } catch (error) {
    state.failures += 1;
    if (!state.snapshot) {
      try { state.snapshot = JSON.parse(sessionStorage.getItem('flightdeck-last-good')); } catch { state.snapshot = null; }
    }
    render();
  } finally { clearTimeout(timer); }
}
function applyTheme() {
  document.documentElement.dataset.theme = state.theme === 'system' ? '' : state.theme;
  refs.theme.textContent = `Theme: ${state.theme}`;
}
function cycleTheme() {
  state.theme = state.theme === 'system' ? 'dark' : state.theme === 'dark' ? 'light' : 'system';
  localStorage.setItem('flightdeck-theme', state.theme); applyTheme();
}
function updateCountdown() {
  const now = new Date(); const target = new Date(now); target.setHours(18, 0, 0, 0);
  if (now >= target) { $('countdownLabel').textContent = 'Daily wrap-up'; $('countdown').textContent = 'QA · MERGE · PRESERVE'; return; }
  const seconds = Math.floor((target - now) / 1000);
  $('countdown').textContent = [Math.floor(seconds / 3600), Math.floor(seconds % 3600 / 60), seconds % 60].map(value => String(value).padStart(2, '0')).join(':');
}
function installDrag() {
  let start = null; let dragged = false;
  refs.repos.addEventListener('pointerdown', event => { if (state.view !== 'a') { start = {x: event.clientX, left: refs.repos.scrollLeft}; dragged = false; } });
  refs.repos.addEventListener('pointermove', event => {
    if (!start) return;
    if (Math.abs(event.clientX - start.x) > 6) dragged = true;
    refs.repos.scrollLeft = start.left - (event.clientX - start.x);
  });
  refs.repos.addEventListener('pointerup', () => { start = null; });
  refs.repos.addEventListener('pointercancel', () => { start = null; dragged = false; });
  refs.repos.addEventListener('click', event => {
    if (!dragged) return;
    event.preventDefault(); event.stopPropagation(); dragged = false;
  }, true);
}

refs.focusMode.addEventListener('click', () => navigate('b'));
refs.closeView.addEventListener('click', backOneLevel);
refs.theme.addEventListener('click', cycleTheme);
$('retry').addEventListener('click', () => refresh(true));
document.addEventListener('keydown', event => { if (event.key === 'Escape' && !event.repeat) { event.preventDefault(); backOneLevel(); } });
window.addEventListener('popstate', () => { const url = new URL(location.href); state.view = url.searchParams.get('view') || 'a'; state.repoId = url.searchParams.get('repo'); state.spotlightId = null; render(); });
document.addEventListener('visibilitychange', () => { if (!document.hidden) refresh(true); });

const initial = new URL(location.href); state.view = ['a', 'b', 'c'].includes(initial.searchParams.get('view')) ? initial.searchParams.get('view') : 'a'; state.repoId = initial.searchParams.get('repo');
applyTheme(); installDrag(); updateCountdown(); refresh(true);
setInterval(updateCountdown, 1000);
setInterval(() => { if (state.failures < 3) refresh(); }, 150000);
