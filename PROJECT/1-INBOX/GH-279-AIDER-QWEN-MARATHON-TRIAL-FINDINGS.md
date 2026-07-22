---
gh_issue: 279
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/279
title: "aider-qwen marathon trial — consolidated run issues (edit-format mismatch, empty-artifact escape, watchdog blast-radius, failure-tally gap)"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-07-22
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 1
---

# GH-279 · aider-qwen marathon trial — consolidated run issues

Punch list of harness defects surfaced while trialing `aider-qwen` (Aider + `qwen3.8-max-preview`) as a
marathon builder against `codex` as reviewer, on the GH-268 Phase 1 installer lanes (2026-07-22). The
builder/reviewer wiring itself is sound (one lane landed cleanly); these are the harness-side gaps found
along the way, independent of which model ends up being the reliable builder (see GH-280 for that
question).

Items (full detail in the GitHub issue):
1. Aider↔Qwen edit-format mismatch → empty artifacts (root cause is GH-280's subject, not fixed here)
2. Chat-membership confusion on multi-file turns → no-op builder turns
3. Per-turn timeout default drift across `aider-turn.py`/`aider-turn.sh`/skill docs (300s/600s/900s)
4. Empty/no-op builder turns commit empty stubs that read as "artifacts appeared" to a weak gate
5. Marathon failure-watchdog gaps: cross-repo kill blast-radius, and round-cap/escalated lanes not
   counted as failures by a naive log-grep tally
6. Minor: API key visible in `ps` args; `timeout(1)` absent on macOS

Does not own the "is Qwen usable at all" question — that is GH-280's controlled experiment. This issue
is fix-the-punch-list scoped: each item above is independently actionable without waiting on GH-280's
result.
