'use strict';

// A ledger line is:  <ISO date> | <account> | <amount><CUR> | <memo>
// Example:           2026-01-04 | assets:cash | -125.40USD | coffee beans
const LINE_RE = /^(\d{4}-\d{2}-\d{2})\s*\|\s*([a-z0-9:_-]+)\s*\|\s*(-?\d+(?:\.\d+)?)([A-Z]{3})\s*\|\s*(.*)$/;

function parseLine(line, lineNo) {
  const trimmed = line.trim();
  if (trimmed === '' || trimmed.startsWith('#')) return null;

  const m = LINE_RE.exec(trimmed);
  if (!m) {
    const err = new Error(`unparseable ledger line at ${lineNo}: ${trimmed}`);
    err.code = 'E_PARSE';
    err.lineNo = lineNo;
    throw err;
  }

  return {
    date: m[1],
    account: m[2],
    amount: Number(m[3]),
    currency: m[4],
    memo: m[5].trim(),
    lineNo,
  };
}

function parse(text) {
  const out = [];
  const lines = String(text).split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const entry = parseLine(lines[i], i + 1);
    if (entry) out.push(entry);
  }
  return out;
}

module.exports = { parse, parseLine, LINE_RE };
