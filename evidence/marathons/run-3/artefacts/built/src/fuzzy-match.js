'use strict';

/**
 * Compute normalized string similarity using trigrams (Jaccard index).
 */
function trigramSimilarity(a, b) {
  if (!a && !b) return 1;
  if (!a || !b) return 0;
  const trigrams = (s) => {
    const set = new Set();
    const padded = `  ${s.toLowerCase()}  `;
    for (let i = 0; i < padded.length - 2; i++) {
      set.add(padded.slice(i, i + 3));
    }
    return set;
  };
  const ta = trigrams(a);
  const tb = trigrams(b);
  let intersection = 0;
  for (const t of ta) {
    if (tb.has(t)) intersection++;
  }
  const union = ta.size + tb.size - intersection;
  return union === 0 ? 1 : intersection / union;
}

/**
 * Score how well two transaction entries match.
 * Returns a number in [0, 1].
 */
function scoreMatch(a, b, options) {
  const {
    amountTolerance = 0.01,
    dateTolerance = 2,
    memoWeight = 0.5,
    amountWeight = 0.35,
    dateWeight = 0.15,
  } = options;

  // --- Amount score ---
  const rawA = Number(a.amount);
  const rawB = Number(b.amount);
  // Hard reject: opposite-sign amounts are opposite-direction transactions.
  if (rawA !== 0 && rawB !== 0 && Math.sign(rawA) !== Math.sign(rawB)) return 0;
  const amtA = Math.abs(rawA);
  const amtB = Math.abs(rawB);
  const amtMax = Math.max(amtA, amtB);
  const amtDiff = Math.abs(amtA - amtB);
  let amountScore;
  if (amtMax === 0) {
    amountScore = amtDiff === 0 ? 1 : 0;
  } else {
    const relDiff = amtDiff / amtMax;
    // Hard cut-off: if relative diff > tolerance * 5, refuse to match.
    if (relDiff > amountTolerance * 5) return 0;
    // Zero tolerance: exact match → 1, any diff → 0 (avoids 0/0 NaN).
    amountScore = amountTolerance === 0
      ? (relDiff === 0 ? 1 : 0)
      : Math.max(0, 1 - relDiff / amountTolerance);
  }

  // --- Date score ---
  const dateA = a.date instanceof Date ? a.date : new Date(a.date);
  const dateB = b.date instanceof Date ? b.date : new Date(b.date);
  const daysDiff = Math.abs((dateA - dateB) / 86400000);
  if (daysDiff > dateTolerance * 3) return 0;
  // Zero tolerance: exact match → 1, any diff → 0 (avoids 0/0 NaN).
  const dateScore = dateTolerance === 0
    ? (daysDiff === 0 ? 1 : 0)
    : Math.max(0, 1 - daysDiff / dateTolerance);

  // --- Memo score ---
  const memoScore = trigramSimilarity(
    String(a.memo || a.description || ''),
    String(b.memo || b.description || ''),
  );

  return amountWeight * amountScore + dateWeight * dateScore + memoWeight * memoScore;
}

/**
 * fuzzyMatch(ledgerA, ledgerB, options?) → { matched, unmatchedA, unmatchedB }
 *
 * Each entry must have: amount (number), date (Date|string), memo or description (string).
 * Matched entries: { a, b, confidence }   where confidence ∈ [0,1].
 * minConfidence (default 0.4) controls the minimum score to form a pair.
 */
function fuzzyMatch(ledgerA, ledgerB, options = {}) {
  const { minConfidence = 0.4 } = options;

  // Build a matrix of scores.
  const scores = ledgerA.map((a) =>
    ledgerB.map((b) => scoreMatch(a, b, options)),
  );

  const usedA = new Set();
  const usedB = new Set();
  const matched = [];

  // Greedy: repeatedly pick the highest-scoring remaining pair.
  while (true) {
    let bestScore = -Infinity;
    let bestI = -1;
    let bestJ = -1;
    for (let i = 0; i < ledgerA.length; i++) {
      if (usedA.has(i)) continue;
      for (let j = 0; j < ledgerB.length; j++) {
        if (usedB.has(j)) continue;
        if (scores[i][j] >= minConfidence && scores[i][j] > bestScore) {
          bestScore = scores[i][j];
          bestI = i;
          bestJ = j;
        }
      }
    }
    if (bestI === -1) break;
    usedA.add(bestI);
    usedB.add(bestJ);
    matched.push({ a: ledgerA[bestI], b: ledgerB[bestJ], confidence: bestScore });
  }

  const unmatchedA = ledgerA.filter((_, i) => !usedA.has(i));
  const unmatchedB = ledgerB.filter((_, j) => !usedB.has(j));

  return { matched, unmatchedA, unmatchedB };
}

module.exports = { fuzzyMatch };
