'use strict';

// cost.js — pure, deterministic extractors for the Phase-1 cost signals
// (COST-OBSERVABILITY-PLAN). No I/O, no clock, no network — just parse a CLI's
// structured output into {tokens_in, tokens_out, tokens_total}. Pure so it's
// trivially testable and the analyzer can trust it the same way it trusts the
// event-log math.

// Parse the token stats from `gemini -o json` output (validated against gemini-cli 0.46.0).
// Shape: { stats: { models: { "<model>": { tokens: { input, prompt, candidates, total, ... } } } } }
// Sums across ALL models used in the turn (a single turn may route across a flash + a main model).
//
//   tokens_in    = Σ tokens.input         (prompt/context fed in)
//   tokens_total = Σ tokens.total         (input + candidates + thoughts, per the CLI's own sum)
//   tokens_out   = tokens_total - tokens_in   (generated: candidates + reasoning "thoughts")
//
// Accepts a JSON string or an already-parsed object. Returns null when the input has no parseable
// model-token stats (e.g. a non-json transcript or a stub) — the caller treats null as "not
// captured" and emits the loud-partial signal rather than a fake zero.
function parseGeminiStats(input) {
  let obj = input;
  if (typeof input === 'string') {
    try { obj = JSON.parse(input); } catch { return null; }
  }
  const models = obj && obj.stats && obj.stats.models;
  if (!models || typeof models !== 'object') return null;

  let tokensIn = 0;
  let tokensTotal = 0;
  let sawTokens = false;
  for (const name of Object.keys(models)) {
    const t = models[name] && models[name].tokens;
    if (!t || typeof t !== 'object') continue;
    const input_ = Number(t.input) || 0;
    const total = Number(t.total) || 0;
    tokensIn += input_;
    tokensTotal += total;
    sawTokens = true;
  }
  if (!sawTokens) return null;

  return {
    tokens_in: tokensIn,
    tokens_total: tokensTotal,
    tokens_out: Math.max(0, tokensTotal - tokensIn),
  };
}

module.exports = { parseGeminiStats };
