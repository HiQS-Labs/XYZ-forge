'use strict';

// Conservative path-overlap detection for the spike.
// Two glob patterns "overlap" if there exists at least one path matching both.
// We don't fully decide intersection of arbitrary globs; we use a sound but
// conservative test: convert each pattern to a literal prefix (text up to the
// first wildcard char), then declare overlap iff one prefix is a prefix of the
// other. This may report overlap when there isn't one (false positive = safer)
// but never misses a real overlap.

/**
 * The literal (non-wildcard) prefix of a glob pattern — the text before the
 * first `*`, `?`, `[`, or `{`.
 * @param {string} glob
 * @returns {string}
 */
function literalPrefix(glob) {
  const m = glob.match(/^([^*?[{]*)/);
  return m ? m[1] : '';
}

/**
 * Conservative overlap test between two glob patterns: true if either
 * pattern's literal prefix is a prefix of the other's. Sound but not exact —
 * may false-positive (safer for claim exclusivity), never false-negatives a
 * real overlap.
 * @param {string} a
 * @param {string} b
 * @returns {boolean}
 */
function patternsOverlap(a, b) {
  const pa = literalPrefix(a);
  const pb = literalPrefix(b);
  return pa.startsWith(pb) || pb.startsWith(pa);
}

/**
 * True if any pattern in `setA` overlaps (per {@link patternsOverlap}) any
 * pattern in `setB`.
 * @param {string[]} setA
 * @param {string[]} setB
 * @returns {boolean}
 */
function setsOverlap(setA, setB) {
  if (!setA || !setB || !setA.length || !setB.length) return false;
  for (const a of setA) {
    for (const b of setB) {
      if (patternsOverlap(a, b)) return true;
    }
  }
  return false;
}

// Glob-to-regex for matching a literal file path against a glob pattern.
// Handles **, *, ?. No brace/char-class support — keep it small for the spike.
/**
 * Compiles a glob pattern (`**`, `*`, `?`) into an anchored RegExp for
 * matching a literal file path. No brace/char-class support.
 * @param {string} glob
 * @returns {RegExp}
 */
function globToRegex(glob) {
  let re = '';
  for (let i = 0; i < glob.length; i++) {
    const ch = glob[i];
    if (ch === '*') {
      if (glob[i + 1] === '*') {
        re += '.*';
        i++;
        // consume optional trailing slash so foo/** matches foo (no trailing /)
        if (glob[i + 1] === '/') i++;
      } else {
        re += '[^/]*';
      }
    } else if (ch === '?') {
      re += '[^/]';
    } else if ('.+^$()[]{}|\\'.includes(ch)) {
      re += '\\' + ch;
    } else {
      re += ch;
    }
  }
  return new RegExp('^' + re + '$');
}

/**
 * True if `file` matches any pattern in `globs` (via {@link globToRegex}).
 * @param {string} file - literal file path
 * @param {string[]} globs
 * @returns {boolean}
 */
function matchesAny(file, globs) {
  if (!globs || !globs.length) return false;
  return globs.some(g => globToRegex(g).test(file));
}

module.exports = { patternsOverlap, setsOverlap, literalPrefix, globToRegex, matchesAny };
