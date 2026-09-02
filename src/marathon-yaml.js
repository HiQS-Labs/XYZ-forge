'use strict';

// marathon-yaml.js — zero-dep reader for the CONSTRAINED MARATHON.yaml subset (Phase 4 / M5).
// Not a general YAML parser: it understands exactly the structure the spec defines —
//   name: <marathon name>
//   phases:
//     - id: p1
//       name: <phase name>
//       reviewer: codex | agy (or codex*/agy*)
//       max_review_rounds: <int>
//       depends_on: <phase id>        (optional)
// Disambiguation is by indent: a top-level `name:` (indent 0) is the marathon name; an indented
// `name:` is a phase field. Anything outside this shape is a parse error, on purpose — better a loud
// failure than a silently-misread orchestration plan.

// brief = path to the phase's task markdown; artifact = comma-separated repo-relative file(s) the
// builder may create/edit. Both optional in the schema but the orchestrator needs `brief` to run a phase.
const PHASE_FIELDS = new Set(['id', 'name', 'reviewer', 'max_review_rounds', 'depends_on', 'brief', 'artifact']);

function stripQuotes(v) {
  if (v.length >= 2 && ((v[0] === '"' && v.endsWith('"')) || (v[0] === "'" && v.endsWith("'")))) {
    return v.slice(1, -1);
  }
  return v;
}

// Split "key: value" into [key, value]; returns null if not a key:value line.
function splitKV(s) {
  const i = s.indexOf(':');
  if (i < 0) return null;
  const key = s.slice(0, i).trim();
  let val = s.slice(i + 1).trim();
  // drop trailing inline comment (only when clearly separated — ` #...`)
  const c = val.indexOf(' #');
  if (c >= 0) val = val.slice(0, c).trim();
  return [key, stripQuotes(val)];
}

function indentOf(line) {
  let n = 0;
  while (n < line.length && line[n] === ' ') n++;
  return n;
}

/**
 * Parses the constrained MARATHON.yaml subset (a top-level `name:` plus a
 * `phases:` list — see the file header for the exact grammar). Not a general
 * YAML parser; anything outside the documented shape throws, on purpose.
 * @param {string} text - raw MARATHON.yaml file contents
 * @returns {{name: string, phases: Object[]}}
 * @throws {Error} on any line outside the documented grammar (unknown field, malformed key:value, etc.)
 */
function parseMarathonYaml(text) {
  const out = { name: '', phases: [] };
  let inPhases = false;
  let cur = null; // current phase being filled
  const lines = String(text).split(/\r?\n/);
  for (let ln = 0; ln < lines.length; ln++) {
    const raw = lines[ln];
    const noComment = raw.replace(/^(\s*)#.*$/, '$1'); // whole-line comment → blank (keep indent token)
    if (noComment.trim() === '') continue;
    const indent = indentOf(raw);
    const trimmed = raw.trim();

    if (indent === 0) {
      if (trimmed === 'phases:') { inPhases = true; cur = null; continue; }
      const kv = splitKV(trimmed);
      if (kv && kv[0] === 'name') { out.name = kv[1]; inPhases = false; continue; }
      throw new Error(`line ${ln + 1}: unexpected top-level line: ${trimmed}`);
    }

    if (!inPhases) throw new Error(`line ${ln + 1}: indented line outside phases: ${trimmed}`);

    if (trimmed.startsWith('- ')) {
      cur = { id: '', name: '', reviewer: '', max_review_rounds: '', depends_on: '', brief: '', artifact: '' };
      out.phases.push(cur);
      const rest = trimmed.slice(2).trim(); // inline first field, e.g. "id: p1"
      if (rest) {
        const kv = splitKV(rest);
        if (!kv) throw new Error(`line ${ln + 1}: malformed list item: ${trimmed}`);
        if (!PHASE_FIELDS.has(kv[0])) throw new Error(`line ${ln + 1}: unknown phase field '${kv[0]}'`);
        cur[kv[0]] = kv[1];
      }
      continue;
    }

    // an indented field line belonging to the current phase
    if (!cur) throw new Error(`line ${ln + 1}: phase field before any '- id:' item: ${trimmed}`);
    const kv = splitKV(trimmed);
    if (!kv) throw new Error(`line ${ln + 1}: malformed phase field: ${trimmed}`);
    if (!PHASE_FIELDS.has(kv[0])) throw new Error(`line ${ln + 1}: unknown phase field '${kv[0]}'`);
    cur[kv[0]] = kv[1];
  }
  return out;
}

/**
 * Validates a parsed marathon plan and resolves `depends_on` into a
 * deterministic topological execution order (authoring order preserved among
 * equally-ready phases).
 * @param {{phases: Object[]}} plan - as returned by {@link parseMarathonYaml}
 * @returns {Object[]} phases in execution order
 * @throws {Error} on an empty plan, duplicate id, missing required field, bad
 *   `reviewer`, or an unknown/self/cyclic `depends_on`
 */
function resolveOrder(plan) {
  const phases = plan.phases || [];
  if (phases.length === 0) throw new Error('no phases defined');
  const byId = new Map();
  for (const p of phases) {
    if (!p.id) throw new Error('a phase is missing its id');
    if (byId.has(p.id)) throw new Error(`duplicate phase id: ${p.id}`);
    if (!p.reviewer) throw new Error(`phase ${p.id}: missing reviewer`);
    // GH-346 Phase 2 (allowlist #6): `gemini` removed — phantom entry, no such shim in this tree.
    // Kept byte-aligned with the duplicate implementation in bin/marathon-yaml; the allowlist test
    // pins both, since the recon that found the other six allowlists missed this seventh copy.
    if (!/^(codex|agy)/.test(p.reviewer)) {
      throw new Error(`phase ${p.id}: reviewer '${p.reviewer}' must start with codex or agy`);
    }
    if (p.depends_on === p.id) throw new Error(`phase ${p.id}: depends_on itself`);
    byId.set(p.id, p);
  }
  for (const p of phases) {
    if (p.depends_on && !byId.has(p.depends_on)) {
      throw new Error(`phase ${p.id}: depends_on unknown phase '${p.depends_on}'`);
    }
  }
  // Topological sort (single-parent depends_on chain, but handle a general DAG deterministically:
  // preserve authoring order among ready nodes).
  const order = [];
  const done = new Set();
  const remaining = phases.slice();
  let guard = 0;
  while (remaining.length) {
    if (guard++ > phases.length + 1) throw new Error('dependency cycle detected');
    let progressed = false;
    for (let i = 0; i < remaining.length; i++) {
      const p = remaining[i];
      if (!p.depends_on || done.has(p.depends_on)) {
        order.push(p);
        done.add(p.id);
        remaining.splice(i, 1);
        progressed = true;
        break; // restart scan to keep authoring order deterministic
      }
    }
    if (!progressed) throw new Error('dependency cycle detected');
  }
  return order;
}

module.exports = { parseMarathonYaml, resolveOrder };
