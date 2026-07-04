#!/usr/bin/env node
'use strict';

// deep-research.mjs — provider-agnostic grounded-search adapter (GH-87). First backend: Agy Gemini
// Search via the `agy` CLI, wrapped so a second backend can be added later without changing the
// normalized {answer, citations, query, provider, model, raw} contract or the harness's default
// model-provider config. Fail-closed: any backend failure prints a typed error to stderr and exits
// non-zero — never a silent fallback to a different provider. Node stdlib only, no new deps.
//
// Usage:
//   node relay-automation/deep-research.mjs --query "..." [--search-context-size low|medium|high] \
//     [--temperature 0.0] [--max-tokens N]
//
// Env:
//   AGY_BIN                    agy binary (default: agy; tests inject a stub)
//   DEEP_RESEARCH_TIMEOUT_MS   wall-clock cap in ms (default: 120000)
//
// Exit: 0 = normalized JSON on stdout · 1 = typed error JSON on stderr (CLI missing, timeout, non-zero
// exit, empty output) · 2 = usage error.

import { execFile } from 'node:child_process';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const PROVIDER = 'agy';
const MODEL = 'gemini';
const SEARCH_CONTEXT_SIZES = ['low', 'medium', 'high'];

function usageError(message) {
  process.stderr.write(`deep-research: ${message}\n`);
  process.stderr.write(
    'Usage: deep-research.mjs --query "..." [--search-context-size low|medium|high] ' +
      '[--temperature N] [--max-tokens N]\n'
  );
  process.exit(2);
}

function parseArgs(argv) {
  const out = { query: '', searchContextSize: 'medium', temperature: 0, maxTokens: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case '--query':
        out.query = argv[++i] ?? '';
        break;
      case '--search-context-size':
        out.searchContextSize = argv[++i] ?? '';
        break;
      case '--temperature':
        out.temperature = Number(argv[++i]);
        break;
      case '--max-tokens':
        out.maxTokens = Number(argv[++i]);
        break;
      default:
        usageError(`unknown argument: ${a}`);
    }
  }
  return out;
}

function validateArgs(args) {
  if (!args.query) usageError('--query is required');
  if (!SEARCH_CONTEXT_SIZES.includes(args.searchContextSize)) {
    usageError(`--search-context-size must be one of ${SEARCH_CONTEXT_SIZES.join('|')}, got "${args.searchContextSize}"`);
  }
  if (!Number.isFinite(args.temperature)) usageError('--temperature must be a number');
  if (args.maxTokens !== null && (!Number.isFinite(args.maxTokens) || args.maxTokens <= 0)) {
    usageError('--max-tokens must be a positive number');
  }
}

// Factual, citation-oriented system prompt: forbids fabricated URLs/titles/quotes and disclaims any
// need for file/shell tools, since this adapter must stay side-effect free.
const SYSTEM_PROMPT = `You are a factual, citation-oriented grounded-search assistant. Answer ONLY \
using information you can verify via web search grounding. Every claim must be backed by a real, \
verifiable citation (URL + title). NEVER fabricate a URL, a title, or a quote — if you cannot find a \
citation, say so instead of inventing one. Do not use file or shell tools; you have no reason to write \
or modify any file for this task.`;

const DEPTH_HINT = {
  low: 'Answer briefly, citing 1-3 sources.',
  medium: 'Answer with moderate depth, citing 2-5 sources.',
  high: 'Answer thoroughly, citing as many relevant sources as are genuinely available.',
};

function buildPrompt({ query, searchContextSize }) {
  return `${SYSTEM_PROMPT}\n${DEPTH_HINT[searchContextSize]}\n\n=== QUERY ===\n${query}\n\nRespond with \
a direct ANSWER, followed by a line reading "CITATIONS:" and then one citation per line formatted as \
"- <title> — <url>".`;
}

// Pull citations out of a "CITATIONS:" section (falls back to scanning the whole answer for bare
// URLs, so a model that skips the requested heading still yields citations rather than none).
function extractCitations(text) {
  const citations = [];
  const seen = new Set();
  const section = text.split(/^\s*CITATIONS:?\s*$/im)[1] ?? text;
  const urlRe = /https?:\/\/[^\s)>\]]+/g;
  let match;
  while ((match = urlRe.exec(section)) !== null) {
    const url = match[0].replace(/[.,;:]+$/, '');
    if (seen.has(url)) continue;
    seen.add(url);
    const lineStart = section.lastIndexOf('\n', match.index) + 1;
    const line = section.slice(lineStart, match.index);
    const titleMatch = line.match(/-\s*(.+?)\s*[-–—]\s*$/);
    citations.push({ url, title: titleMatch ? titleMatch[1].trim() : null });
  }
  return citations;
}

async function runAgy(args) {
  const bin = process.env.AGY_BIN || 'agy';
  const timeoutMs = Number(process.env.DEEP_RESEARCH_TIMEOUT_MS || 120000);
  const prompt = buildPrompt(args);

  // Run in a throwaway tmpdir (not the caller's repo) so this tool stays side-effect free even if
  // the model attempts a file write despite the system prompt's instruction not to.
  const workDir = await mkdtemp(join(tmpdir(), 'deep-research-'));
  try {
    const { stdout } = await new Promise((resolve, reject) => {
      execFile(
        bin,
        // --dangerously-skip-permissions: a non-interactive grounded search MUST auto-approve agy's
        // web-search/grounding tool. Without it, `agy -p` blocks on a permission prompt that never
        // comes in print mode and hangs until --print-timeout (observed against real agy 2026-07-04;
        // the stub tests never caught it). Safe here: the run is confined to the throwaway tmpdir
        // below and the system prompt forbids file/shell tools.
        ['-p', prompt, '--dangerously-skip-permissions', '--print-timeout', `${Math.ceil(timeoutMs / 1000)}s`],
        { cwd: workDir, timeout: timeoutMs, killSignal: 'SIGKILL', encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
        (err, stdout, stderr) => (err ? reject(Object.assign(err, { stdout, stderr })) : resolve({ stdout, stderr }))
      );
    });
    const answer = stdout.trim();
    if (!answer) throw Object.assign(new Error('agy returned no output'), { emptyOutput: true });
    return {
      answer,
      citations: extractCitations(answer),
      query: args.query,
      provider: PROVIDER,
      model: MODEL,
      raw: { stdout, config: { searchContextSize: args.searchContextSize, temperature: args.temperature, maxTokens: args.maxTokens } },
    };
  } finally {
    await rm(workDir, { recursive: true, force: true }).catch(() => {});
  }
}

function classifyError(err) {
  if (err.code === 'ENOENT') return 'binary_missing';
  if (err.killed || err.signal) return 'timeout';
  if (err.emptyOutput) return 'empty_output';
  return 'backend_error';
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  validateArgs(args);

  const start = Date.now();
  try {
    const result = await runAgy(args);
    const latencyMs = Date.now() - start;
    process.stdout.write(JSON.stringify(result) + '\n');
    process.stderr.write(
      `deep-research: ok provider=${PROVIDER} model=${MODEL} latency_ms=${latencyMs} citations=${result.citations.length}\n`
    );
    process.exit(0);
  } catch (err) {
    const kind = classifyError(err);
    const latencyMs = Date.now() - start;
    process.stderr.write(JSON.stringify({ error: kind, message: err.message, provider: PROVIDER, query: args.query }) + '\n');
    process.stderr.write(`deep-research: FAILED provider=${PROVIDER} kind=${kind} latency_ms=${latencyMs}\n`);
    process.exit(1);
  }
}

main();
