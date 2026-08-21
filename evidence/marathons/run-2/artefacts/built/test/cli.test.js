'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { run } = require('../src/cli');

function createFakeIO(files = {}) {
  let stdoutData = '';
  let stderrData = '';
  return {
    stdout: {
      write(chunk) {
        stdoutData += chunk;
      },
    },
    stderr: {
      write(chunk) {
        stderrData += chunk;
      },
    },
    readFile(filename) {
      if (Object.prototype.hasOwnProperty.call(files, filename)) {
        return files[filename];
      }
      const err = new Error(`ENOENT: no such file or directory, open '${filename}'`);
      err.code = 'ENOENT';
      throw err;
    },
    getStdout() {
      return stdoutData;
    },
    getStderr() {
      return stderrData;
    },
  };
}

const CLEAN_LEDGER = [
  '2026-01-04 | assets:cash | -125.40USD | coffee beans',
  '2026-01-04 | expenses:food | 125.40USD | coffee beans',
].join('\n');

const UNBALANCED_LEDGER = [
  '2026-01-04 | assets:cash | -125.40USD | coffee beans',
  '2026-01-04 | expenses:food | 120.00USD | coffee beans',
].join('\n');

const MULTI_ACCOUNT_LEDGER = [
  '2026-01-04 | assets:cash | -100.00USD | a',
  '2026-01-05 | assets:cash | -25.00USD | b',
  '2026-01-04 | expenses:food | 100.00USD | a',
  '2026-01-05 | expenses:food | 25.00USD | b',
].join('\n');

const INVALID_LINE_LEDGER = [
  '2026-01-04 | assets:cash | -100.00USD | ok',
  'this is not a valid ledger line',
  '2026-01-04 | expenses:food | 100.00USD | ok',
].join('\n');

test('exit code 0: default mode on balanced ledger prints OK summary', () => {
  const io = createFakeIO({ 'ledger.txt': CLEAN_LEDGER });
  const code = run(['ledger.txt'], io);

  assert.strictEqual(code, 0);
  assert.strictEqual(io.getStdout(), 'OK: 2 entries, balanced\n');
  assert.strictEqual(io.getStderr(), '');
});

test('exit code 0: default mode on empty file prints OK: 0 entries', () => {
  const io = createFakeIO({ 'empty.txt': '# Just a comment\n\n' });
  const code = run(['empty.txt'], io);

  assert.strictEqual(code, 0);
  assert.strictEqual(io.getStdout(), 'OK: 0 entries, balanced\n');
  assert.strictEqual(io.getStderr(), '');
});

test('exit code 1: default mode on unbalanced ledger prints problem line', () => {
  const io = createFakeIO({ 'unbalanced.txt': UNBALANCED_LEDGER });
  const code = run(['unbalanced.txt'], io);

  assert.strictEqual(code, 1);
  assert.match(io.getStdout(), /2026-01-04 USD does not balance: delta -5\.4000/);
  assert.strictEqual(io.getStderr(), '');
});

test('exit code 2: usage error when file argument is missing', () => {
  const io1 = createFakeIO();
  const code1 = run([], io1);
  assert.strictEqual(code1, 2);
  assert.match(io1.getStderr(), /Usage: ledgerkit <file>/);
  assert.strictEqual(io1.getStdout(), '');

  const io2 = createFakeIO();
  const code2 = run(['--json'], io2);
  assert.strictEqual(code2, 2);
  assert.match(io2.getStderr(), /Usage: ledgerkit <file>/);

  const io3 = createFakeIO();
  const code3 = run(['--summary'], io3);
  assert.strictEqual(code3, 2);
  assert.match(io3.getStderr(), /Usage: ledgerkit <file>/);
});

test('exit code 2: usage error when unknown flag is provided', () => {
  const io = createFakeIO({ 'ledger.txt': CLEAN_LEDGER });
  const code = run(['ledger.txt', '--unknown-flag'], io);

  assert.strictEqual(code, 2);
  assert.match(io.getStderr(), /Unknown flag: --unknown-flag/);
  assert.match(io.getStderr(), /Usage: ledgerkit <file>/);
  assert.strictEqual(io.getStdout(), '');
});

test('exit code 2: usage error when multiple file arguments are passed', () => {
  const io = createFakeIO({ 'a.txt': CLEAN_LEDGER, 'b.txt': CLEAN_LEDGER });
  const code = run(['a.txt', 'b.txt'], io);

  assert.strictEqual(code, 2);
  assert.match(io.getStderr(), /Unexpected extra argument: b\.txt/);
  assert.match(io.getStderr(), /Usage: ledgerkit <file>/);
  assert.strictEqual(io.getStdout(), '');
});

test('exit code 2: usage error when file does not exist', () => {
  const io = createFakeIO({});
  const code = run(['missing.txt'], io);

  assert.strictEqual(code, 2);
  assert.match(io.getStderr(), /Error reading file missing\.txt/);
  assert.strictEqual(io.getStdout(), '');
});

test('exit code 3: parse error (E_PARSE) reports failing line number on stderr', () => {
  const io = createFakeIO({ 'bad.txt': INVALID_LINE_LEDGER });
  const code = run(['bad.txt'], io);

  assert.strictEqual(code, 3);
  assert.match(io.getStderr(), /Parse error on line 2/i);
  assert.strictEqual(io.getStdout(), '');
});

test('non-E_PARSE error thrown during parse is not caught as code 3 and propagates', () => {
  const customError = new Error('non-parse failure');
  customError.lineNo = 42;

  const mockContent = {
    toString() {
      return {
        [Symbol.toPrimitive]() {
          throw customError;
        },
      };
    },
  };

  const io = {
    stdout: () => {},
    stderr: () => {},
    readFile: () => mockContent,
  };

  assert.throws(
    () => {
      run(['file.txt'], io);
    },
    (err) => err === customError
  );
});

test('mode --summary: prints summarize table one line per row (clean)', () => {
  const io = createFakeIO({ 'ledger.txt': MULTI_ACCOUNT_LEDGER });
  const code = run(['ledger.txt', '--summary'], io);

  assert.strictEqual(code, 0);
  assert.strictEqual(
    io.getStdout(),
    'assets:cash USD -125\nexpenses:food USD 125\n'
  );
  assert.strictEqual(io.getStderr(), '');
});

test('mode --summary: returns exit code 1 when ledger has validation problems', () => {
  const io = createFakeIO({ 'unbalanced.txt': UNBALANCED_LEDGER });
  const code = run(['unbalanced.txt', '--summary'], io);

  assert.strictEqual(code, 1);
  assert.strictEqual(
    io.getStdout(),
    'assets:cash USD -125.4\nexpenses:food USD 120\n'
  );
  assert.strictEqual(io.getStderr(), '');
});

test('mode --json: prints single JSON object with ok, entries, problems, summary (clean)', () => {
  const io = createFakeIO({ 'ledger.txt': CLEAN_LEDGER });
  const code = run(['ledger.txt', '--json'], io);

  assert.strictEqual(code, 0);
  assert.strictEqual(io.getStderr(), '');

  const parsed = JSON.parse(io.getStdout().trim());
  assert.strictEqual(parsed.ok, true);
  assert.strictEqual(parsed.entries.length, 2);
  assert.deepStrictEqual(parsed.problems, []);
  assert.deepStrictEqual(parsed.summary, [
    { account: 'assets:cash', currency: 'USD', total: -125.4 },
    { account: 'expenses:food', currency: 'USD', total: 125.4 },
  ]);
});

test('mode --json: prints single JSON object and returns 1 when problems exist', () => {
  const io = createFakeIO({ 'unbalanced.txt': UNBALANCED_LEDGER });
  const code = run(['unbalanced.txt', '--json'], io);

  assert.strictEqual(code, 1);
  assert.strictEqual(io.getStderr(), '');

  const parsed = JSON.parse(io.getStdout().trim());
  assert.strictEqual(parsed.ok, false);
  assert.strictEqual(parsed.entries.length, 2);
  assert.strictEqual(parsed.problems.length, 1);
  assert.strictEqual(parsed.problems[0].code, 'E_UNBALANCED');
  assert.ok(Math.abs(parsed.problems[0].delta - (-5.4)) < 0.0001);
});

test('mode --json wins over --summary flag when both are passed', () => {
  const io1 = createFakeIO({ 'ledger.txt': CLEAN_LEDGER });
  const code1 = run(['ledger.txt', '--summary', '--json'], io1);
  assert.strictEqual(code1, 0);
  const parsed1 = JSON.parse(io1.getStdout().trim());
  assert.strictEqual(parsed1.ok, true);

  const io2 = createFakeIO({ 'ledger.txt': CLEAN_LEDGER });
  const code2 = run(['ledger.txt', '--json', '--summary'], io2);
  assert.strictEqual(code2, 0);
  const parsed2 = JSON.parse(io2.getStdout().trim());
  assert.strictEqual(parsed2.ok, true);
});

test('supports functional io.stdout and io.stderr', () => {
  let stdoutData = '';
  let stderrData = '';
  const io = {
    stdout: (msg) => { stdoutData += msg; },
    stderr: (msg) => { stderrData += msg; },
    readFile: () => CLEAN_LEDGER,
  };

  const code = run(['ledger.txt'], io);
  assert.strictEqual(code, 0);
  assert.strictEqual(stdoutData, 'OK: 2 entries, balanced\n');
  assert.strictEqual(stderrData, '');
});
