#!/usr/bin/env node
'use strict';
// Overlay the staged XYZ marathon plans onto the generated git-lanes diagram as a
// "fire queue": pending nodes to the right of the real history, color-coded by
// whether they are actually ready to fire.
//
//   type "job"      (green)   → READY: preflight/contracts green, only needs GO
//   type "queue"    (magenta) → GATED: waiting on operator decision / upstream feedback
//   type "external" (gray)    → OWED:  capture docs / preflight contracts still owed
//
// Re-run after regenerating git-history-diagram.json. Source of truth for each
// plan's readiness is its own status: frontmatter in PROJECT/2-WORKING/.

const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, 'git-history-diagram.json');
const spec = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

// Development tip = the point the fire queue cuts from.
const devTip = spec.nodes
  .filter(n => n.lane === 'development')
  .sort((a, b) => b.order - a.order)[0];
if (!devTip) throw new Error('no development lane node found — regenerate the base JSON');
const maxOrder = Math.max(...spec.nodes.map(n => n.order));

// Staged marathon plans (PROJECT/2-WORKING/), ready-first left → right.
const QUEUE = [
  {
    id: 'mplan-L', label: 'Plan L — post-marathon follow-up (3 lanes)',
    readiness: 'job', gh: 'GH-251/241/218',
    status: '3 lanes, all contracts preflight exit 0; not yet fired',
    file: 'PROJECT/2-WORKING/MARATHON-PLAN-2026-07-19-L-POST-MARATHON-FOLLOWUP.md'
  },
  {
    id: 'mplan-H', label: 'Plan H — cross-repo live marathon status (GH-218)',
    readiness: 'job', gh: 'GH-218',
    status: 'Both phases fireable, contract verified ready via --dry-run',
    file: 'PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md'
  },
  {
    id: 'mplan-K', label: 'Plan K — ddb6c40 shim-root regression',
    readiness: 'queue', gh: 'GH-255',
    status: 'Triaged, NOT fired — live regression on development, operator gate required',
    file: 'PROJECT/2-WORKING/MARATHON-PLAN-2026-07-19-K-POST-DDB6C40-REGRESSION.md'
  },
  {
    id: 'mplan-I', label: 'Plan I — provenance vs summary coordination',
    readiness: 'queue', gh: 'GH-226',
    status: 'Active — waiting on Jedi feedback and/or operator GO',
    file: 'PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-I-PROVENANCE-SUMMARY-COORDINATION.md'
  },
  {
    id: 'mplan-J', label: 'Plan J — vendored-consumer DX gaps',
    readiness: 'external', gh: 'GH-238/239',
    status: 'Triaged, not yet fired — capture docs + preflight contracts still owed',
    file: 'PROJECT/2-WORKING/MARATHON-PLAN-2026-07-18-J-VENDORED-CONSUMER-DX.md'
  }
];

const READY_LABEL = {
  job: 'READY TO FIRE', queue: 'GATED', external: 'WORK OWED'
};

// One dedicated lane below the real branches.
spec.lanes.push({ id: 'fire-queue', label: '🔥 Fire queue', order: spec.lanes.length });

QUEUE.forEach((m, i) => {
  const order = maxOrder + 2 + i; // leave a gap after the newest real commit
  spec.nodes.push({
    id: m.id,
    label: m.label,
    type: m.readiness,
    lane: 'fire-queue',
    order,
    tech: `${m.gh} · ${READY_LABEL[m.readiness]}`,
    description: `${READY_LABEL[m.readiness]} — ${m.gh}\n${m.status}\n${m.file}`
  });
  // Dashed branch edge from the development tip: "this cuts from here when fired."
  spec.edges.push({
    source: devTip.id,
    target: m.id,
    kind: 'branch',
    label: m.readiness === 'job' ? 'ready ▸' : undefined
  });
});

spec.title = 'xyz-3-agents-swarm — Git Lanes + Fire Queue';
spec.sources = (spec.sources || []).concat([
  'PROJECT/2-WORKING/MARATHON-PLAN-*.md status: frontmatter (fire-queue readiness)'
]);
spec.history_note = (spec.history_note || '') +
  ' Fire-queue nodes are staged marathon plans (not yet branches); readiness reflects each plan\'s status: frontmatter as of ' +
  spec.generated + '.';

fs.writeFileSync(jsonPath, JSON.stringify(spec, null, 2) + '\n');
process.stdout.write(
  `augmented: +1 lane, +${QUEUE.length} queued nodes, +${QUEUE.length} branch edges ` +
  `(${QUEUE.filter(m => m.readiness === 'job').length} ready to fire)\n`
);
