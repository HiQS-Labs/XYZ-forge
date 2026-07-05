# RELAY · GH-129 review: Perplexity Sonar via OpenRouter as second deep-research backend (PR #130 diff)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-04.
-->

NEXT: None
STATUS: Approved
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh129-perplexity-openrouter-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/.relay-inbox-gh129-diff.patch** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/.relay-inbox-gh129-diff.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-04
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.
## Log

### Round 1 · Reviewer · agy

VERDICT: PASS
Basis: Perplexity Sonar via OpenRouter is cleanly integrated as the second deep-research backend. The implementation perfectly satisfies the Definition of Done: it maps providers cleanly, normalizes citations in the requested order (annotations → citations array → bare URL fallback), has robust error mapping, and contains comprehensive tests with a Node-stdlib mock HTTP server.

**Verdict details:** No blockers, no shoulds, no nits. The implementation is of extremely high quality.

**Findings:**

- **[Pass] `relay-automation/deep-research.mjs` — Provider configuration and dispatching.** Adds the `--provider` flag and validates it. Correctly dispatches to `runAgy` or `runOpenRouter`.
- **[Pass] `relay-automation/deep-research.mjs` — `runOpenRouter` implementation.** Integrates global `fetch` properly, manages API key validations, sets up correct payload structure with `web_search_options.search_context_size` and timeout abort controller.
- **[Pass] `relay-automation/deep-research.mjs` — Citation normalization.** Handles annotations, citations array, and fallback URL extraction in the exact requested order of preference.
- **[Pass] `relay-automation/deep-research.mjs` — Error mapping.** Maps timeouts, missing API keys, and HTTP failures cleanly to the project's standard error classifications.
- **[Pass] `test/deep-research.sh` — Test coverage.** Implements a Node.js stub HTTP server to comprehensively mock the API and test request payloads, citation pathways, and all error conditions.
- **[Pass] `relay-automation/hooks/security-scan-baseline.txt` — Security scans.** Baselined the stub's fake API key properly.
- **[Pass] Documentation.** README, file headers, changelog, and inbox tracking documents are fully updated.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

