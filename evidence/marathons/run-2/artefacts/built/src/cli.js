'use strict';

const { parse } = require('./parse');
const { validate } = require('./validate');
const { summarize } = require('./index');

function write(target, text) {
  if (!target) return;
  if (typeof target.write === 'function') {
    target.write(text);
  } else if (typeof target === 'function') {
    target(text);
  } else if (Array.isArray(target)) {
    target.push(text);
  }
}

/**
 * Runs the ledgerkit command line logic with injected IO.
 *
 * @param {Array<string>} argv Command-line arguments (without node / script prefix).
 * @param {object} io Injected IO handlers: { stdout, stderr, readFile }.
 * @returns {number} Exit code:
 *   0: clean (balanced, no validation problems)
 *   1: validation problems
 *   2: usage error (missing file, unknown flag, unreadable file)
 *   3: parse error (E_PARSE from parser)
 */
function run(argv, io) {
  if (!io) {
    return 2;
  }

  if (!Array.isArray(argv)) {
    write(io.stderr, 'Usage: ledgerkit <file> [--json] [--summary]\n');
    return 2;
  }

  let file = null;
  let isJson = false;
  let isSummary = false;

  for (const arg of argv) {
    if (arg === '--json') {
      isJson = true;
    } else if (arg === '--summary') {
      isSummary = true;
    } else if (typeof arg === 'string' && arg.startsWith('-')) {
      write(io.stderr, `Unknown flag: ${arg}\nUsage: ledgerkit <file> [--json] [--summary]\n`);
      return 2;
    } else {
      if (file !== null) {
        write(io.stderr, `Unexpected extra argument: ${arg}\nUsage: ledgerkit <file> [--json] [--summary]\n`);
        return 2;
      }
      file = arg;
    }
  }

  if (!file) {
    write(io.stderr, 'Usage: ledgerkit <file> [--json] [--summary]\n');
    return 2;
  }

  if (typeof io.readFile !== 'function') {
    write(io.stderr, 'io.readFile is required\n');
    return 2;
  }

  let rawContent;
  try {
    rawContent = io.readFile(file, 'utf8');
    if (rawContent === undefined || rawContent === null) {
      write(io.stderr, `File not found: ${file}\n`);
      return 2;
    }
  } catch (err) {
    write(io.stderr, `Error reading file ${file}: ${err.message || err}\n`);
    return 2;
  }

  const text = typeof rawContent === 'string' ? rawContent : rawContent.toString('utf8');

  let entries;
  try {
    entries = parse(text);
  } catch (err) {
    if (err && err.code === 'E_PARSE') {
      write(io.stderr, `Parse error on line ${err.lineNo}: ${err.message}\n`);
      return 3;
    }
    throw err;
  }

  const validation = validate(entries);
  const summary = summarize(entries);

  if (isJson) {
    const payload = {
      ok: validation.ok,
      entries,
      problems: validation.problems,
      summary,
    };
    write(io.stdout, JSON.stringify(payload) + '\n');
    return validation.ok ? 0 : 1;
  }

  if (isSummary) {
    for (const row of summary) {
      write(io.stdout, `${row.account} ${row.currency} ${row.total}\n`);
    }
    return validation.ok ? 0 : 1;
  }

  // Default mode: human-readable report
  if (validation.ok) {
    write(io.stdout, `OK: ${entries.length} entries, balanced\n`);
    return 0;
  } else {
    for (const problem of validation.problems) {
      write(io.stdout, `${problem.message}\n`);
    }
    return 1;
  }
}

module.exports = { run };
