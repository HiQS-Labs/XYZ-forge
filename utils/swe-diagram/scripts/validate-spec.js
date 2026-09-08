#!/usr/bin/env node
'use strict';
// swe-diagram spec validator.
//
// build-diagram.sh fails on invalid JSON but NOT on graph semantics: an edge whose source or target
// names no node is dropped silently by the renderer, so a spec can ship a picture that is quietly
// missing a relationship nobody notices is gone. ARCHITECTURE/README.md warns a human to check this
// by hand; this makes it mechanical.
//
//   node utils/swe-diagram/scripts/validate-spec.js ARCHITECTURE/*.json
//
// Exits 0 when every spec is clean, 1 when any ERROR is found. WARNINGs never fail the run — the
// node-count band is guidance from the README, not a contract, and system-diagram.json is
// deliberately over it.

var fs = require('fs');

var NODE_TYPES = ['service', 'ui', 'api', 'database', 'queue', 'external', 'job', 'storage',
                  'commit', 'merge'];
var EDGE_KINDS = ['sync', 'async', 'data', 'branch', 'merge'];
var LAYOUTS = ['layered', 'top-down', 'hub-ring', 'trust-clustered', 'git-lanes'];
var BAND_MIN = 8, BAND_MAX = 25;

function validate(spec) {
  var errors = [], warnings = [];

  // JSON.parse happily returns null, a string, a number or an array — all of which are valid JSON
  // and none of which is a spec. Dereferencing one throws, and a throw here aborts the whole batch,
  // so every file after it in argv goes unvalidated. Reject the root shape before touching it.
  if (spec === null || typeof spec !== 'object' || Array.isArray(spec)) {
    return { errors: ['spec root is not a JSON object (got ' +
                      (spec === null ? 'null' : Array.isArray(spec) ? 'array' : typeof spec) + ')'],
             warnings: [], nodes: 0, edges: 0 };
  }

  var nodes = Array.isArray(spec.nodes) ? spec.nodes : [];
  var edges = Array.isArray(spec.edges) ? spec.edges : [];
  var groups = Array.isArray(spec.groups) ? spec.groups : [];

  if (!nodes.length) errors.push('spec has no nodes');

  // Duplicate ids make every later lookup ambiguous, so check before building the id set.
  var seen = Object.create(null), ids = Object.create(null);
  nodes.forEach(function (n, i) {
    if (!n || typeof n.id !== 'string' || !n.id) { errors.push('node[' + i + '] has no id'); return; }
    if (seen[n.id]) errors.push('duplicate node id: ' + n.id);
    seen[n.id] = true; ids[n.id] = true;
    if (n.type && NODE_TYPES.indexOf(n.type) === -1) {
      warnings.push('node ' + n.id + ' has type "' + n.type + '" — renders gray');
    }
  });

  // THE check this file exists for: a dangling endpoint is dropped silently at render time.
  edges.forEach(function (e, i) {
    if (!e || typeof e.source !== 'string' || typeof e.target !== 'string') {
      errors.push('edge[' + i + '] is missing source or target'); return;
    }
    if (!ids[e.source]) errors.push('dangling edge source "' + e.source + '" (-> ' + e.target + ')');
    if (!ids[e.target]) errors.push('dangling edge target "' + e.target + '" (<- ' + e.source + ')');
    if (e.kind && EDGE_KINDS.indexOf(e.kind) === -1) {
      warnings.push('edge ' + e.source + '->' + e.target + ' has kind "' + e.kind + '" — falls back to sync');
    }
  });

  // Duplicate ids collapse in the lookup map, so a group or lane declared twice validates as one
  // and the second declaration's label silently wins — same failure mode as a duplicate node id.
  var gids = Object.create(null);
  groups.forEach(function (g, i) {
    if (!g || typeof g.id !== 'string' || !g.id) { errors.push('group[' + i + '] has no id'); return; }
    if (gids[g.id]) errors.push('duplicate group id: ' + g.id);
    gids[g.id] = true;
  });
  nodes.forEach(function (n) {
    if (n && n.group && !gids[n.group]) errors.push('node ' + n.id + ' references unknown group "' + n.group + '"');
  });
  // Not an error: groups render as swimlanes only under layered/top-down and are skipped elsewhere,
  // so an empty group is dead weight rather than a broken picture.
  Object.keys(gids).forEach(function (g) {
    if (!nodes.some(function (n) { return n && n.group === g; })) warnings.push('group "' + g + '" has no member nodes');
  });

  if (spec.layout && LAYOUTS.indexOf(spec.layout) === -1) {
    errors.push('unknown layout "' + spec.layout + '"');
  }
  if (spec.layout === 'git-lanes') {
    var lanes = Object.create(null);
    (Array.isArray(spec.lanes) ? spec.lanes : []).forEach(function (l) {
      if (!l || !l.id) return;
      if (lanes[l.id]) errors.push('duplicate lane id: ' + l.id);
      lanes[l.id] = true;
    });
    nodes.forEach(function (n) {
      if (n && n.lane && !lanes[n.lane]) errors.push('node ' + n.id + ' references unknown lane "' + n.lane + '"');
    });
  }
  if (spec.hub && !ids[spec.hub]) errors.push('spec.hub "' + spec.hub + '" names no node');

  // An isolated node draws as a floating box with no relationship — usually a rename that missed
  // its edges. git-lanes is exempt: a lane can legitimately hold a single tip commit.
  if (spec.layout !== 'git-lanes') {
    nodes.forEach(function (n) {
      if (!n || !n.id) return;
      var touched = edges.some(function (e) { return e && (e.source === n.id || e.target === n.id); });
      if (!touched) warnings.push('node "' + n.id + '" has no edges — it will float unconnected');
    });
    if (nodes.length < BAND_MIN || nodes.length > BAND_MAX) {
      warnings.push('node count ' + nodes.length + ' is outside the ' + BAND_MIN + '-' + BAND_MAX +
                    ' band ARCHITECTURE/README.md asks for');
    }
  }
  return { errors: errors, warnings: warnings, nodes: nodes.length, edges: edges.length };
}

if (require.main === module) {
  var files = process.argv.slice(2);
  if (!files.length) { console.error('usage: validate-spec.js <spec.json> [...]'); process.exit(2); }
  var failed = 0;
  files.forEach(function (f) {
    var spec;
    try { spec = JSON.parse(fs.readFileSync(f, 'utf8')); }
    catch (e) { console.error(f + ': ERROR unreadable/invalid JSON — ' + e.message); failed++; return; }
    var r = validate(spec);
    r.errors.forEach(function (m) { console.error(f + ': ERROR ' + m); });
    r.warnings.forEach(function (m) { console.error(f + ': warn  ' + m); });
    if (r.errors.length) failed++;
    else console.log(f + ': ok (' + r.nodes + ' nodes, ' + r.edges + ' edges, ' +
                     r.warnings.length + ' warning(s))');
  });
  process.exit(failed ? 1 : 0);
}

module.exports = { validate: validate };
