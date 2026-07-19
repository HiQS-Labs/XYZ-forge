#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

function usage(message) {
  if (message) process.stderr.write(`git-history-to-json: ${message}\n`);
  process.stderr.write(
    'usage: git-history-to-json.js [--repo PATH] [--limit N] [--output FILE] [--title TITLE]\n'
  );
  process.exit(2);
}

const args = process.argv.slice(2);
let repo = process.cwd();
let limit = 20;
let output = 'ARCHITECTURE/git-history-diagram.json';
let title = null;
for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === '--repo') repo = args[++i] || usage('missing value for --repo');
  else if (arg === '--limit') limit = Number(args[++i]);
  else if (arg === '--output') output = args[++i] || usage('missing value for --output');
  else if (arg === '--title') title = args[++i] || usage('missing value for --title');
  else if (arg === '-h' || arg === '--help') usage();
  else usage(`unknown argument: ${arg}`);
}
if (!Number.isInteger(limit) || limit < 1 || limit > 200) usage('--limit must be an integer from 1 to 200');

repo = path.resolve(repo);
function git(gitArgs, allowFailure) {
  const result = spawnSync('git', ['-C', repo].concat(gitArgs), { encoding: 'utf8' });
  if (result.status !== 0 && !allowFailure) {
    const detail = (result.stderr || result.stdout || '').trim();
    throw new Error(`git ${gitArgs.join(' ')} failed${detail ? `: ${detail}` : ''}`);
  }
  return result.status === 0 ? result.stdout : '';
}

try {
  git(['rev-parse', '--git-dir']);
} catch (err) {
  process.stderr.write(`git-history-to-json: ${err.message}\n`);
  process.exit(1);
}

const currentBranch = git(['symbolic-ref', '--quiet', '--short', 'HEAD'], true).trim();
const refLines = git([
  'for-each-ref', '--format=%(refname)\t%(objectname)', 'refs/heads', 'refs/remotes'
]).trim().split('\n').filter(Boolean);

const localByName = {};
const rawRefs = [];
for (const line of refLines) {
  const tab = line.indexOf('\t');
  if (tab === -1) continue;
  const full = line.slice(0, tab);
  const sha = line.slice(tab + 1);
  if (/^refs\/remotes\/[^/]+\/HEAD$/.test(full)) continue;
  if (full.startsWith('refs/heads/')) {
    const name = full.slice('refs/heads/'.length);
    const ref = { id: name, label: name, full, sha, local: true };
    localByName[name] = ref;
    rawRefs.push(ref);
  }
}
for (const line of refLines) {
  const tab = line.indexOf('\t');
  if (tab === -1) continue;
  const full = line.slice(0, tab);
  const sha = line.slice(tab + 1);
  if (!full.startsWith('refs/remotes/') || /^refs\/remotes\/[^/]+\/HEAD$/.test(full)) continue;
  const short = full.slice('refs/remotes/'.length);
  const slash = short.indexOf('/');
  if (slash === -1) continue;
  const remote = short.slice(0, slash);
  const branch = short.slice(slash + 1);
  const local = localByName[branch];
  if (remote === 'origin' && local && local.sha === sha) continue;
  const id = remote === 'origin' && !local ? branch : `${remote}/${branch}`;
  rawRefs.push({ id, label: id, full, sha, local: false });
}

// Collapse duplicate refs that resolve to the same visible lane and commit,
// preferring a local branch over its remote-tracking twin.
const refByKey = {};
for (const ref of rawRefs) {
  const key = `${ref.id}\0${ref.sha}`;
  if (!refByKey[key] || ref.local) refByKey[key] = ref;
}
const refs = Object.values(refByKey);

const historyRefs = Array.from(new Set(refs.map(ref => ref.full).filter(Boolean)));
if (!historyRefs.length) {
  process.stderr.write('git-history-to-json: repository has no branch refs\n');
  process.exit(1);
}
const newestFirst = git([
  'rev-list', '--topo-order', '--date-order', `--max-count=${limit}`
].concat(historyRefs)).trim().split('\n').filter(Boolean);
if (!newestFirst.length) {
  process.stderr.write('git-history-to-json: repository has no commits\n');
  process.exit(1);
}
const commits = newestFirst.slice().reverse(); // oldest -> newest for left-to-right rendering
const selected = new Set(commits);

function metadata(sha) {
  const raw = git(['show', '-s', '--format=%H%x00%P%x00%h%x00%an%x00%aI%x00%s', sha]).trimEnd();
  const fields = raw.split('\0');
  return {
    sha: fields[0],
    parents: fields[1] ? fields[1].split(' ') : [],
    short: fields[2],
    author: fields[3],
    authoredAt: fields[4],
    subject: fields.slice(5).join('\0')
  };
}
const meta = {};
for (const sha of commits) meta[sha] = metadata(sha);

function lanePriority(ref) {
  const name = ref.id;
  if (name === 'main' || name === 'master') return [0, name];
  if (name === 'development' || name === 'develop') return [1, name];
  if (/^(feat|feature)\//.test(name)) return [2, name];
  if (/^(fix|bugfix|hotfix)\//.test(name)) return [3, name];
  if (name === currentBranch) return [4, name];
  return [5, name];
}
function compareRefs(a, b) {
  const pa = lanePriority(a), pb = lanePriority(b);
  return pa[0] - pb[0] || pa[1].localeCompare(pb[1]);
}
refs.sort(compareRefs);

const firstParent = {};
for (const ref of refs) {
  firstParent[ref.id] = new Set(
    git(['rev-list', '--first-parent', '--max-count=5000', ref.full]).trim().split('\n').filter(Boolean)
  );
}

function contains(ref, sha) {
  const result = spawnSync('git', ['-C', repo, 'merge-base', '--is-ancestor', sha, ref.full]);
  return result.status === 0;
}
function chooseLane(sha) {
  const exact = refs.filter(ref => ref.sha === sha);
  if (exact.length) return exact.sort(compareRefs)[0].id;
  const first = refs.filter(ref => firstParent[ref.id].has(sha));
  if (first.length) return first.sort(compareRefs)[0].id;
  const reachable = refs.filter(ref => contains(ref, sha));
  if (reachable.length) return reachable.sort(compareRefs)[0].id;
  return 'unresolved';
}

const laneForCommit = {};
for (const sha of commits) laneForCommit[sha] = chooseLane(sha);
const usedLaneIds = new Set(Object.values(laneForCommit));
for (const stable of ['main', 'master', 'development', 'develop']) {
  if (refs.some(ref => ref.id === stable)) usedLaneIds.add(stable);
}
if (usedLaneIds.has('unresolved') && !refs.some(ref => ref.id === 'unresolved')) {
  refs.push({ id: 'unresolved', label: 'unresolved', full: '', sha: '', local: false });
}
const usedRefs = refs.filter(ref => usedLaneIds.has(ref.id)).sort(compareRefs);
const lanes = usedRefs.map((ref, order) => ({
  id: ref.id,
  label: ref.label,
  order,
  tip: ref.sha || undefined,
  current: ref.id === currentBranch || undefined
}));

const nodes = commits.map((sha, order) => {
  const info = meta[sha];
  const tipRefs = refs.filter(ref => ref.sha === sha).map(ref => ref.id).sort();
  const tags = git(['tag', '--points-at', sha], true).trim().split('\n').filter(Boolean);
  const labels = tipRefs.concat(tags.map(tag => `tag:${tag}`));
  const merge = info.parents.length > 1;
  return {
    id: sha,
    label: info.subject,
    type: merge ? 'merge' : 'commit',
    lane: laneForCommit[sha],
    order,
    tech: `${info.short} · ${info.authoredAt.slice(0, 10)}`,
    author: info.author,
    refs: labels,
    description: `${info.subject}\n${info.sha}\n${info.author} · ${info.authoredAt}${labels.length ? `\n${labels.join(', ')}` : ''}`
  };
});

const edges = [];
for (const sha of commits) {
  const info = meta[sha];
  info.parents.forEach((parent, index) => {
    if (!selected.has(parent)) return;
    const crossesLane = laneForCommit[parent] !== laneForCommit[sha];
    edges.push({
      source: parent,
      target: sha,
      kind: index > 0 ? 'merge' : (crossesLane ? 'branch' : 'sync'),
      label: index > 0 ? 'merge' : (crossesLane ? 'branch' : undefined)
    });
  });
}

const repoName = path.basename(repo);
const spec = {
  title: title || `${repoName} — Recent Git History`,
  generated: new Date().toISOString().slice(0, 10),
  layout: 'git-lanes',
  sources: [
    `git rev-list <local+remote branch refs> --topo-order --date-order --max-count=${limit}`,
    'git for-each-ref refs/heads refs/remotes',
    'git show --format commit metadata and parents'
  ],
  history_note: 'Lanes are inferred from current local and remote-tracking refs. Deleted branch names and squash/rebase provenance cannot be reconstructed from Git ancestry alone.',
  lanes,
  nodes,
  edges
};

const outputPath = path.isAbsolute(output) ? output : path.join(repo, output);
fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(spec, null, 2)}\n`);
process.stdout.write(`wrote ${outputPath} (${nodes.length} commits, ${lanes.length} lanes, ${edges.length} edges)\n`);
