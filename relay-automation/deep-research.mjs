#!/usr/bin/env node
'use strict';

// deep-research.mjs — provider-agnostic grounded-search adapter (GH-87). Backends: Agy Gemini
// Search via the `agy` CLI (default), and Perplexity Sonar grounded search via OpenRouter's
// chat-completions API (GH-129, `--provider openrouter`) — the repo's established OpenAI-compatible
// gateway (same OPENROUTER_API_KEY convention as the Aider lane). Both normalize to the same
// {answer, citations, query, provider, model, raw} contract without touching the harness's default
// model-provider config. Fail-closed: any backend failure prints a typed error to stderr and exits
// non-zero — never a silent fallback to a different provider. Node stdlib only, no new deps.
//
// Usage:
//   node relay-automation/deep-research.mjs --query "..." [--provider agy|openrouter] \
//     [--search-context-size low|medium|high] [--temperature 0.0] [--max-tokens N]
//
// Env:
//   AGY_BIN                          agy binary (default: agy; tests inject a stub)
//   DEEP_RESEARCH_TIMEOUT_MS         wall-clock cap in ms (default: 120000)
//   OPENROUTER_API_KEY               required for --provider openrouter (fail-closed if missing)
//   DEEP_RESEARCH_OPENROUTER_MODEL   OpenRouter model slug (default: perplexity/sonar)
//   OPENROUTER_BASE_URL              OpenRouter API base (default: https://openrouter.ai/api/v1;
//                                    tests inject a local stub HTTP server)
//
// Exit: 0 = normalized JSON on stdout · 1 = typed error JSON on stderr (CLI missing, API key missing,
// timeout, non-zero exit / non-200, empty output) · 2 = usage error.

import { spawn } from 'node:child_process';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const AGY_PROVIDER = 'agy';
const AGY_MODEL = 'gemini';
const OPENROUTER_PROVIDER = 'openrouter';
const OPENROUTER_DEFAULT_MODEL = 'perplexity/sonar';
const OPENROUTER_DEFAULT_BASE_URL = 'https://openrouter.ai/api/v1';
const PROVIDERS = [AGY_PROVIDER, OPENROUTER_PROVIDER];
const SEARCH_CONTEXT_SIZES = ['low', 'medium', 'high'];

function usageError(message) {
  process.stderr.write(`deep-research: ${message}\n`);
  process.stderr.write(
    'Usage: deep-research.mjs --query "..." [--provider agy|openrouter] ' +
      '[--search-context-size low|medium|high] [--temperature N] [--max-tokens N]\n'
  );
  process.exit(2);
}

function parseArgs(argv) {
  const out = { query: '', provider: AGY_PROVIDER, searchContextSize: 'medium', temperature: 0, maxTokens: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case '--query':
        out.query = argv[++i] ?? '';
        break;
      case '--provider':
        out.provider = argv[++i] ?? '';
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
  if (!PROVIDERS.includes(args.provider)) {
    usageError(`--provider must be one of ${PROVIDERS.join('|')}, got "${args.provider}"`);
  }
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
    // spawn, NOT execFile: execFile silently IGNORES the `stdio` option, so agy's stdin was left an
    // OPEN pipe that never EOF'd — real `agy -p` then blocks reading stdin until --print-timeout and
    // the whole call hangs (measured 2026-07-04: execFile 75s→timeout/0-bytes vs spawn 10s→ok). The
    // stub tests never caught it because the stub does not read stdin. spawn honors stdio:['ignore',…]
    // so stdin is /dev/null (immediate EOF) and the run is non-interactive.
    // --dangerously-skip-permissions: a non-interactive grounded search MUST auto-approve agy's
    // web-search/grounding tool, or print mode blocks on a permission prompt that never comes. Safe
    // here: the run is confined to the throwaway tmpdir below and the system prompt forbids file/shell
    // tools. --print-timeout mirrors our own wall-clock cap as agy's internal ceiling.
    const stdout = await new Promise((resolve, reject) => {
      const child = spawn(
        bin,
        ['-p', prompt, '--dangerously-skip-permissions', '--print-timeout', `${Math.ceil(timeoutMs / 1000)}s`],
        { cwd: workDir, timeout: timeoutMs, killSignal: 'SIGKILL', stdio: ['ignore', 'pipe', 'pipe'] }
      );
      let out = '';
      let err = '';
      child.stdout.setEncoding('utf8');
      child.stdout.on('data', (d) => { out += d; });
      child.stderr.setEncoding('utf8');
      child.stderr.on('data', (d) => { err += d; });
      // 'error' fires for spawn failures (e.g. ENOENT when the binary is missing) → binary_missing.
      child.on('error', (e) => reject(Object.assign(e, { stdout: out, stderr: err })));
      child.on('close', (code, signal) => {
        // Node kills the child with killSignal after the timeout → a non-null signal here → classified
        // as a timeout by classifyError (err.signal). A non-zero exit with no signal is a backend_error.
        if (signal) { reject(Object.assign(new Error(`agy killed by ${signal} (timeout ${timeoutMs}ms)`), { killed: true, signal, stdout: out, stderr: err })); return; }
        if (code !== 0) { reject(Object.assign(new Error(`agy exited ${code}: ${err.trim()}`), { exitCode: code, stdout: out, stderr: err })); return; }
        resolve(out);
      });
    });
    const answer = stdout.trim();
    if (!answer) throw Object.assign(new Error('agy returned no output'), { emptyOutput: true });
    return {
      answer,
      citations: extractCitations(answer),
      query: args.query,
      provider: AGY_PROVIDER,
      model: AGY_MODEL,
      raw: { stdout, config: { searchContextSize: args.searchContextSize, temperature: args.temperature, maxTokens: args.maxTokens } },
    };
  } finally {
    await rm(workDir, { recursive: true, force: true }).catch(() => {});
  }
}

// GH-129: Perplexity Sonar grounded search via OpenRouter. Perplexity's native
// web_search_options.search_context_size maps 1:1 onto --search-context-size; its citations arrive
// as message.annotations url_citation entries and/or a top-level citations[] array of URL strings,
// with the bare-URL scan kept as the last-resort fallback. Same fail-closed posture as runAgy:
// typed errors, no silent cross-provider fallback.
async function runOpenRouter(args) {
  const apiKey = process.env.OPENROUTER_API_KEY || '';
  if (!apiKey) throw Object.assign(new Error('OPENROUTER_API_KEY is not set'), { missingApiKey: true });
  const model = process.env.DEEP_RESEARCH_OPENROUTER_MODEL || OPENROUTER_DEFAULT_MODEL;
  const baseUrl = (process.env.OPENROUTER_BASE_URL || OPENROUTER_DEFAULT_BASE_URL).replace(/\/+$/, '');
  const timeoutMs = Number(process.env.DEEP_RESEARCH_TIMEOUT_MS || 120000);

  const body = {
    model,
    messages: [
      { role: 'system', content: `${SYSTEM_PROMPT}\n${DEPTH_HINT[args.searchContextSize]}` },
      { role: 'user', content: args.query },
    ],
    temperature: args.temperature,
    web_search_options: { search_context_size: args.searchContextSize },
  };
  if (args.maxTokens !== null) body.max_tokens = args.maxTokens;

  // AbortController mirrors runAgy's wall-clock cap; an abort surfaces as err.name === 'AbortError'
  // → classified 'timeout'. A refused/unreachable gateway surfaces as fetch's TypeError → backend_error.
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  let res;
  let text;
  try {
    res = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    text = await res.text();
  } finally {
    clearTimeout(timer);
  }
  if (!res.ok) {
    throw Object.assign(new Error(`openrouter HTTP ${res.status}: ${text.slice(0, 300)}`), { httpStatus: res.status });
  }
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error(`openrouter returned non-JSON body: ${text.slice(0, 300)}`);
  }

  const message = data?.choices?.[0]?.message ?? {};
  const answer = (typeof message.content === 'string' ? message.content : '').trim();
  if (!answer) throw Object.assign(new Error('openrouter returned no answer content'), { emptyOutput: true });

  const citations = [];
  const seen = new Set();
  const push = (url, title) => {
    if (!url || seen.has(url)) return;
    seen.add(url);
    citations.push({ url, title: title ?? null });
  };
  for (const a of Array.isArray(message.annotations) ? message.annotations : []) {
    if (a?.type === 'url_citation') push(a.url_citation?.url, a.url_citation?.title ?? null);
  }
  for (const u of Array.isArray(data.citations) ? data.citations : []) {
    if (typeof u === 'string') push(u, null);
  }
  if (citations.length === 0) for (const c of extractCitations(answer)) push(c.url, c.title);

  return {
    answer,
    citations,
    query: args.query,
    provider: OPENROUTER_PROVIDER,
    model,
    raw: { response: data, config: { searchContextSize: args.searchContextSize, temperature: args.temperature, maxTokens: args.maxTokens } },
  };
}

function classifyError(err) {
  if (err.code === 'ENOENT') return 'binary_missing';
  if (err.missingApiKey) return 'missing_api_key';
  if (err.killed || err.signal || err.name === 'AbortError' || err.name === 'TimeoutError') return 'timeout';
  if (err.emptyOutput) return 'empty_output';
  return 'backend_error';
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  validateArgs(args);

  const start = Date.now();
  try {
    const result = args.provider === OPENROUTER_PROVIDER ? await runOpenRouter(args) : await runAgy(args);
    const latencyMs = Date.now() - start;
    process.stdout.write(JSON.stringify(result) + '\n');
    process.stderr.write(
      `deep-research: ok provider=${result.provider} model=${result.model} latency_ms=${latencyMs} citations=${result.citations.length}\n`
    );
    process.exit(0);
  } catch (err) {
    const kind = classifyError(err);
    const latencyMs = Date.now() - start;
    process.stderr.write(JSON.stringify({ error: kind, message: err.message, provider: args.provider, query: args.query }) + '\n');
    process.stderr.write(`deep-research: FAILED provider=${args.provider} kind=${kind} latency_ms=${latencyMs}\n`);
    process.exit(1);
  }
}

main();
