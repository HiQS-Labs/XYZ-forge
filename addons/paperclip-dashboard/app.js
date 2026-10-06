import {snapshotFresh, sourceStatus, progressTone, PROGRESS_HELP} from '/shared/presentation.mjs';
import {issueCards, laneIssues} from '/shared/issue-context.mjs';
import {demoSnapshot} from './demo.mjs';

const $ = id => document.getElementById(id);
const params = new URLSearchParams(location.search);
const demo = document.body.dataset.mode !== 'live' || params.get('mode') === 'demo';
const scenario = demo ? params.get('scenario') || '' : '';
const state = {snapshot: null, repo: '', section: 'work', search: '', selected: '', failures: 0, error: '', busy: false};
const titles = {work: 'Overview', lanes: 'Agent lanes', prs: 'Pull requests'};
const paths = {grid: 'M3 3h7v7H3z M14 3h7v7h-7z M3 14h7v7H3z M14 14h7v7h-7z',
  lanes: 'M4 6h16 M4 12h16 M4 18h16', branch: 'M7 3v13a4 4 0 0 0 8 0V8 M15 8l-3-3 M15 8l3-3',
  refresh: 'M20 7a9 9 0 1 0 1 8 M20 3v5h-5', search: 'M16 16l5 5 M17 10a7 7 0 1 1-14 0 7 7 0 0 1 14 0',
  moon: 'M20 15A9 9 0 0 1 9 3a9 9 0 1 0 11 12', collapse: 'M8 5l-6 7 6 7 M13 4h8v16h-8z'};
function icon(name) {
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  for (const [key, value] of Object.entries({viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '1.6', 'aria-hidden': 'true'})) svg.setAttribute(key, value);
  const path = document.createElementNS(svg.namespaceURI, 'path'); path.setAttribute('d', paths[name] || paths.grid); svg.append(path); return svg;
}
function el(tag, className = '', text = '') {const node = document.createElement(tag); node.className = className; node.textContent = text; return node;}
function chip(text, tone = 'unknown') {const node = el('span', 'chip', text); node.dataset.tone = tone; return node;}
function ago(value) {const delta = Date.now() - Date.parse(value); return Number.isFinite(delta) && delta >= 0 ? delta < 60000 ? 'Just observed' : `${Math.floor(delta / 60000)}m ago` : 'Time unavailable';}
function empty(text) {return el('div', 'empty', text);}
function prefs(key, value) {try {if (value === undefined) return localStorage.getItem(key); localStorage.setItem(key, value);} catch {} return null;}
document.documentElement.dataset.theme = prefs('paperclip-preview-theme') || 'light';
document.body.classList.toggle('collapsed', prefs('paperclip-preview-collapsed') === 'true');
document.body.classList.toggle('compact-preview', params.get('compact') === '1');
document.querySelectorAll('[data-icon]').forEach(node => node.append(icon(node.dataset.icon)));
$('theme').append(icon('moon')); $('collapse').append(icon('collapse'));
$('theme').onclick = () => {const theme = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark'; document.documentElement.dataset.theme = theme; prefs('paperclip-preview-theme', theme);};
function collapseLabel() {$('collapse').setAttribute('aria-expanded', String(!document.body.classList.contains('collapsed'))); $('collapse').setAttribute('aria-label', document.body.classList.contains('collapsed') ? 'Expand sidebar' : 'Collapse sidebar');}
$('collapse').onclick = () => {document.body.classList.toggle('collapsed'); prefs('paperclip-preview-collapsed', String(document.body.classList.contains('collapsed'))); collapseLabel();}; collapseLabel();
document.querySelectorAll('[data-section]').forEach(button => button.onclick = () => {state.section = button.dataset.section; state.selected = ''; render();});
$('search').oninput = event => {state.search = event.target.value; render();};
document.addEventListener('keydown', event => {if (event.key === 'Escape') {state.search = ''; $('search').value = ''; state.selected = ''; render();}});
function scope() {return (state.snapshot?.repos || []).filter(repo => !state.repo || repo.id === state.repo);}
function healthy() {return !state.error && snapshotFresh(state.snapshot);}
function items(section = state.section) {
  return scope().flatMap(repo => (section === 'work' ? issueCards(repo, Date.now(), healthy()) : repo[section] || []).map(item => ({...item, repo,
    key: `${repo.id}:${section}:${item.number || item.id}`, section})));
}
function select(item) {state.selected = item.key; render();}
function render() {
  const repos = state.snapshot?.repos || [], visible = scope();
  $('title').textContent = titles[state.section]; $('crumb').textContent = state.repo ? repos.find(repo => repo.id === state.repo)?.name || 'Repository' : titles[state.section];
  $('mode').textContent = demo ? 'Synthetic demo' : 'Local reads';
  $('readNotice').textContent = state.error ? `${state.error} ${state.failures >= 3 ? 'Automatic reads paused. Use Read latest to retry.' : 'Use Read latest to retry.'}` :
    !snapshotFresh(state.snapshot) ? 'Snapshot expired. Recorded facts remain visible; work status needs a fresh read.' :
    demo ? `Synthetic observations for design review. No local data is read.${scenario ? ` Scenario: ${scenario}.` : ''}` : 'Read-only local snapshot. Source coverage and recorded status do not establish execution or PR readiness.';
  $('readNotice').dataset.tone = state.error ? 'failed' : snapshotFresh(state.snapshot) ? 'unknown' : 'stale';
  $('refresh').disabled = state.busy;
  document.querySelectorAll('[data-section]').forEach(button => {button.classList.toggle('active', button.dataset.section === state.section); button.setAttribute('aria-pressed', String(button.dataset.section === state.section));});
  $('repoNav').replaceChildren();
  for (const repo of [{id: '', name: 'All repositories'}, ...repos]) {
    const button = el('button', `nav-item repo-item${state.repo === repo.id ? ' active' : ''}`);
    button.append(el('span', 'repo-mark', repo.id ? repo.name.slice(0, 1) : '•'), el('span', 'nav-label', repo.name)); button.setAttribute('aria-label', repo.name); button.setAttribute('aria-pressed', String(state.repo === repo.id));
    button.onclick = () => {state.repo = repo.id; state.selected = ''; render();}; $('repoNav').append(button);
  }
  $('laneCount').textContent = String(items('lanes').length); $('prCount').textContent = String(items('prs').length);
  $('metrics').replaceChildren();
  const counts = [['Repositories shown', visible.length, 'Within configured coverage'], ['Established work', healthy() ? items('work').filter(item => item.workflow.kind === 'in-progress').length : '—', 'Recorded status · execution unverified'], ['Lane observations', items('lanes').length, 'Recorded intent · liveness unknown'], ['Cached pull requests', items('prs').length, 'Current-head verification required']];
  counts.forEach(([label, count, help]) => {const card = el('div', 'metric'); card.append(el('p', 'metric-label', label), el('strong', 'metric-value', String(count)), el('p', 'metric-help', help)); $('metrics').append(card);});
  $('coverage').textContent = `Displayed observations only · Coverage: ${state.snapshot?.coverage || 'unavailable'}${state.snapshot?.truncated ? ' · Capped' : ''}${healthy() ? '' : ' · Read unavailable or expired'}`;
  $('laneCards').replaceChildren();
  items('lanes').slice(0, 4).forEach((lane, index) => {const card = el('button', 'lane-card'); card.onclick = () => {state.section = 'lanes'; select(lane);};
    const head = el('div', 'lane-top'); head.append(el('span', 'agent-avatar', (lane.agent || '?').slice(0, 1)), el('strong', '', lane.agent || 'Agent unspecified'), chip('Observed')); card.append(head, el('p', 'lane-task', lane.task || 'Intent unavailable'), el('p', 'lane-meta', `${lane.repo.name} · ${ago(lane.last_prompt_at)}`), el('p', 'lane-progress', 'Progress unmeasured')); $('laneCards').append(card);});
  if (!items('lanes').length) $('laneCards').append(empty('No lane observations in this scope.'));
  const rows = items().filter(item => `${item.title || item.task || ''} ${item.number || ''} ${item.repo.name} ${item.agent || ''}`.toLowerCase().includes(state.search.toLowerCase()));
  $('workList').replaceChildren();
  for (const item of rows) {const row = el('button', 'work-row'); row.setAttribute('aria-pressed', String(state.selected === item.key)); row.onclick = () => select(item);
    const copy = el('span', 'row-copy'); copy.append(el('strong', '', item.title || item.task || 'Untitled observation'), el('small', '', `${item.repo.name} · ${item.section === 'lanes' ? item.agent || 'Agent' : `#${item.number}`}`));
    row.append(el('span', 'work-symbol', item.section === 'lanes' ? '↳' : '#'), copy,
      chip(item.section === 'work' ? item.workflow.label : item.section === 'prs' ? 'Verify current head' : 'Observed', item.section === 'work' ? item.workflow.kind : 'unknown'), el('span', 'row-time', ago(item.context_at || item.last_prompt_at || item.updated_at))); $('workList').append(row);}
  if (!rows.length) $('workList').append(empty(state.search ? 'No observations match this filter.' : state.error ? 'No snapshot available. Retry the read.' : 'No work observations in this scope.'));
  const selected = rows.find(item => item.key === state.selected) || (!state.selected ? rows[0] : null); renderDetail(selected);
  $('activity').replaceChildren();
  const events = visible.flatMap(repo => (repo.events || []).map(event => ({...event, repo}))).sort((a, b) => Date.parse(b.occurred_at) - Date.parse(a.occurred_at));
  events.slice(0, 6).forEach(event => {const row = el('div', 'activity-row'); const copy = el('div'); copy.append(el('strong', '', event.summary || event.kind || 'Observation'), el('small', '', event.repo.name)); row.append(el('span', 'activity-dot'), copy, el('time', '', ago(event.occurred_at))); $('activity').append(row);});
  if (!events.length) $('activity').append(empty('No recent activity observations.'));
  $('sources').replaceChildren();
  for (const source of state.snapshot?.sources || []) {const status = sourceStatus(source, healthy()); const node = chip(`${source.id} · ${status.label}`, status.tone); node.title = status.help; $('sources').append(node);}
  $('updated').textContent = state.snapshot ? `Snapshot ${ago(state.snapshot.generated_at)}` : 'No snapshot';
}
function renderDetail(item) {
  $('detail').replaceChildren();
  if (!item) {$('detail').append(empty('Select an observation to inspect its context.')); return;}
  $('detail').append(el('p', 'eyebrow', 'WORK CONTEXT'), el('h2', '', item.title || item.task || 'Observation'), el('p', 'detail-repo', item.repo.name));
  const status = item.section === 'work' ? item.workflow.label : item.section === 'prs' ? 'Current-head QA required' : 'Observed intent';
  $('detail').append(chip(status, item.workflow?.kind || 'unknown'), el('p', 'detail-reason', item.workflow?.reason || (item.section === 'prs' ? 'Cached PR state is context. Inspect the current head and verification receipts before merging.' : 'An agent prompt is recorded intent. It does not establish a running process.')));
  const fields = [['Observation', item.context_at || item.last_prompt_at || item.updated_at || 'Unavailable'], ['Progress', 'Unmeasured'], ['Data', demo ? 'Synthetic demo' : 'Local snapshot'], ['Coverage', state.snapshot?.coverage || 'Unknown']];
  if (item.section === 'lanes') fields.push(['Issue context', laneIssues(item, item.repo).map(number => `#${number}`).join(', ') || 'Unavailable']);
  const dl = el('dl', 'detail-facts'); fields.forEach(([label, value]) => dl.append(el('dt', '', label), el('dd', '', value))); $('detail').append(dl);
  const help = el('p', 'detail-help', PROGRESS_HELP); help.dataset.tone = progressTone(); $('detail').append(help);
  const button = el('button', 'button handoff-button', 'Prepare handoff');
  button.onclick = () => {const text = el('textarea', 'handoff-text'); text.readOnly = true; text.setAttribute('aria-label', 'Copyable handoff context'); text.value = `${demo ? 'SYNTHETIC DEMO\n' : ''}${item.repo.name}: ${item.title || item.task}\n${status}\nObserved: ${fields[0][1]}\nProgress unmeasured; verify current state and PR head before acting.`; button.replaceWith(text); text.focus(); text.select();}; $('detail').append(button);
}
async function read() {
  if (state.busy) return;
  state.busy = true; render(); const controller = new AbortController(); const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    let snapshot;
    if (demo) {if (scenario === 'failure') throw new Error('Simulated source read failure.'); snapshot = demoSnapshot(Date.now(), scenario);}
    else {const response = await fetch('/flightdeck.json', {cache: 'no-store', signal: controller.signal}); if (!response.ok) throw new Error(`Snapshot read failed (HTTP ${response.status}).`); snapshot = await response.json();}
    if (snapshot.schema_version !== 1 || !Array.isArray(snapshot.repos) || !Array.isArray(snapshot.sources)) throw new Error('Unsupported snapshot contract.');
    state.snapshot = snapshot; state.error = ''; state.failures = 0;
    if (!snapshot.repos.some(repo => repo.id === state.repo)) state.repo = '';
  } catch (error) {state.failures++; state.error = error.name === 'AbortError' ? 'Snapshot read timed out.' : error.message || 'Snapshot read failed.';}
  finally {clearTimeout(timeout); state.busy = false; render();}
}
$('refresh').onclick = read;
setInterval(() => {if (state.failures < 3) read();}, 150000);
setInterval(render, 30000);
read();
