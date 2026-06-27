---
baseline_version: 2
generated: 2026-06-18 ~03:30 local
repo: sleuth-app
branch: feat/snapshot-slack-relay (repo HEAD 61dfa69)
production_commit: 878d2e8 — Merge PR #326 from NeochromeTeam/development (deployed v1.4.197)
scan_depth: deep (read-only, source verified) + live production verification
scan_duration: ~35 min
overall_maturity: Proven (core) — Confirmed
production_status: LIVE — service active since 2026-06-17 15:02 UTC, 7 workspaces, host up 253 days
---

# Project Baseline — sleuth-app · 2026-06-18 · Deep scan + production verification

> This document has two firewalled halves. **Sections 1–2 are technical truth** (hand them to an
> engineer). **Section 3 is graded marketing positioning, Section 4 is forward-looking roadmap**
> (hand those to marketing). Never present a Section-4 aspiration as a shipped Section-2 capability.

## 1. Bottom line

Sleuth is a **production-proven, multi-tenant Slack assistant** that turns natural-language messages into scheduled reminders and acts as a ChatGPT-style teammate inside Slack. This is not a prototype: it has been in **daily use for roughly 2.5 years by a 10-person team**, and a live check of the production server confirms it running right now across **7 Slack workspaces** on a host with **253 days of uptime**. The core — natural-language reminder scheduling, the reminder state machine, the in-Slack AI assistant, and the 54-command routing layer — is genuinely mature and battle-tested.

The honest edges are all in the *newer, additive* work, not the load-bearing core: the event-sourced persistence overhaul (P3) is real and partially deployed but deliberately **non-authoritative** — it drives no production behavior yet and is not a "system of record." Two advertised-adjacent integrations are early — **Notion is search-only and untested**, and the **plugin system ships exactly one demo plugin**. None of that undercuts the headline product; it just means a few specific claims need careful wording.

## 2. Technical status (plain language)

**Overall maturity:** **Proven** for the load-bearing product (2.5 years of daily production use, verified live across 7 workspaces), with a **Solid** supporting cast and a small number of **Partly built** additive edges. The mutable-JSON persistence remains the one structural caveat — durable against graceful restarts, not against a hard kill mid-write (no `fsync` anywhere). · confidence: **Confirmed**

### Production reality (directly observed via SSH, 2026-06-18 ~03:26 UTC)

| Fact | Value |
|---|---|
| Service state | `active (running)`, since 2026-06-17 15:02 UTC |
| Deployed version | **1.4.197** (repo is at 1.4.198 — prod trails by one patch; the undeployed delta is default-OFF and behavior-neutral) |
| Production branch/commit | `main` @ `878d2e8` (merge PR #326) |
| Workspaces served | **7** — OCUX, Turn7, abk-alumni-network, josetest, neochrome, planning, uclauxiii |
| Host uptime / load | 253 days / load avg ~0.00 (stable host, light traffic) |

### Feature status

Confidence grades: **Confirmed** = source read and verified wired into the runtime path (and/or directly observed in production). **Likely** = strong corroborating signal, not independently re-run this session. Tests were **not executed** this session, so any "tests pass" claim is Likely, not Confirmed.

| Feature | Maturity | Confidence | What that's based on |
|---|---|---|---|
| NL → reminder scheduling (parse → FSM → Slack) | **Proven** | Confirmed | Core product; 2.5 yrs daily use; live in 7 prod workspaces; FSM verified in source |
| Reminder lifecycle (✅ complete / 🗑 cancel / ⏰ schedule / snooze) | **Proven** | Confirmed | Single-chokepoint FSM (`#TransitionReminderState`); `.State` mutated nowhere else in `src/`; in daily prod use |
| In-Slack AI assistant (chat, Q&A, calculations) | **Proven** | Confirmed | 2.5 yrs daily use; multi-provider dispatch verified; OpenAI path is the long-proven one |
| Command catalog + NL routing (54 commands) | **Solid** | Confirmed | 54 curated catalog entries; layered first-match-wins + regex aliases + LLM intent resolver, all wired into the live mention path |
| Tri-provider AI (OpenAI · Anthropic · Gemini) | **Solid** | Confirmed | All three instantiated and callable; prefix routing (`claude-*`/`gemini-*`/`gpt-*`); provider-aware defaults. Caveat: web-search has no Anthropic path (OpenAI/Gemini only) |
| Per-channel model switching | **Solid** | Confirmed | `set/clear/show-channel-model`; runtime-config-grounded "what model are you?" guard |
| Durable completion history (CompletionStore) | **Solid** | Confirmed | Dedupe + 365-day prune + flush-on-shutdown + reload-survival, verified in source; wired at the FSM completion hook. Caveat: plain `fs.writeFile`, no `fsync` |
| Sourced web search (OpenAI + Gemini) | **Solid** | Confirmed | Real Responses-API + `googleSearch` tool paths; freshness auto-routing; NL aliases |
| GitHub auto-complete sync (issue/PR → reminder) | **Solid** | Confirmed | Real 30-min polling loop against GitHub REST; auto-completes when linked items close/merge; PAT-gated; tested |
| GitHub comment relay (Slack thread → issue comment) | **Solid** | Confirmed | Real POST to issue-comments endpoint; stop-triggers; persisted state; tested |
| Semantic thread recall / RAG (`recall`, `remember above`) | **Solid** | Confirmed | Real `sqlite-vec` cosine k-NN + channel-name keyword hybrid; Gemini embeddings; workspace-isolated; tested |
| Slack write observability (audit IDs) | **Solid** | Confirmed | Every outbound post/upload flows through one audited boundary with correlation IDs. Caveat: kill-switch is a code constant, not an env flag |
| Remote workspace management (Web API, `:2020`) | **Solid** | Confirmed | ~14 real Express routes behind auth; workspace create/read/update/delete persist to disk |
| Rebalance export (`?format=rebalance` → rebalanceOS) | **Solid** | Confirmed | Purpose-built display projection with rendered labels/sections/permalinks; not a raw dump |
| summarize-week recap command | **Solid** | Confirmed | CompletionStore-backed; live in prod (1.4.197); flag-gated projection variant is NOT in prod yet |
| Append-only event ledger (non-authoritative) | **Solid** | Confirmed | Live in prod since the 15:02 restart; emits all 5 lifecycle events; append never blocks/rejects; per-workspace serialized; corrupt-tail tolerant. **Writes nothing authoritative** |
| Build-time FSM contract validator | **Works** | Confirmed | `validate:fsm` is real and correct — but **not CI-gated** and not in `pretest`; runs only when invoked manually |
| New Relic APM instrumentation | **Works** | Confirmed | `require('newrelic')` is the first executable line; distributed tracing on. Caveat: license key is a hardcoded **personal/test** key |
| Notion integration | **Partly built** | Confirmed | Wired into runtime and reachable (`notion search …`), but **search-only, token-gated, and has zero tests** |
| Plugin system | **Partly built** | Confirmed | Real loader with path-traversal guard and lifecycle — but **exactly one plugin ships** (`echo-command`, a labeled reference sample) |
| P3 summarize-week projection (pure fold) | **Partly built** | Confirmed | Projection + shadow-diff harness implemented and unit-tested; cutover behind a **default-OFF** flag, never flipped, never shadow-diffed on real data |
| Event log as authoritative system of record | **Just an idea** | Confirmed | Deliberately non-authoritative; mutate-first, fire-and-forget; authority flip held behind a stop-and-re-decide gate. Nothing in prod reads it as truth |

### What's solid (genuinely safe to rely on)

- **The reminder engine and its state machine.** `.State` is mutated in exactly one place (`#TransitionReminderState`) plus two annotated legacy backfills — verified across the whole `src/` tree. Creation funnels through one factory. ~16 lifecycle transitions, all through the chokepoint. This is the disciplined heart of the product and it has 2.5 years of daily production behind it.
- **The breadth of the assistant.** 54 commands, tri-provider AI, per-channel model switching, sourced web search across two vendors, semantic recall, GitHub two-way sync — all verified wired into the live path, not scaffolding.
- **Operational maturity.** Multi-tenant in reality (7 workspaces), running on a 253-day-uptime host, with completion history that survives restarts and full audit instrumentation on every outbound Slack write.
- **Test breadth.** 67 test files covering FSM invariants, fake-timer lifecycle cycles, the command catalog, AI providers, and every integration above (suite not re-run this session, so "passing" is Likely).

### What's thin or risky (the honest caveats)

- **No `fsync` anywhere.** Both the completion store and the event ledger use plain `fs.writeFile`/`appendFile`. Durable against a graceful deploy/restart (the stated goal), **not** against a hard kill mid-write. "Crash-safe" is not a claim this codebase can make today.
- **The FSM validator is not CI-gated.** It exists and is correct, but CI runs `npm test` + an unrelated grep, never `validate:fsm`. The contract holds today by discipline, not by an enforced gate.
- **Event-sourcing is groundwork, not a system of record.** The ledger writes in prod but is authoritative for nothing; the one read-back path is behind a default-OFF flag that isn't even deployed (prod is 1.4.197). Do not describe Sleuth as "event-sourced" in the present tense.
- **Notion and plugins are early.** Notion is search-only, token-gated, and untested. The plugin system is a real loader with a single demo plugin — there is no plugin catalog.
- **New Relic runs on a personal/test license key** hardcoded as a fallback. Fine internally; not a customer-facing observability story.

### What I could not verify (read-only, no execution)

- Whether the test suite and `tsc` build pass on HEAD (not run this session — Deep scan stayed read-only by request).
- The 2.5-year usage history is owner-attested; corroborated by the 253-day host uptime and 7 live workspaces, but tenure itself was not independently reconstructed from logs.
- Actual per-workspace activity levels (which of the 7 are active vs. dormant/test — `josetest` is clearly a test workspace).
- Whether the summarize-week shadow-diff has been run against a real calendar week (memory + CHANGELOG say not yet).

## 3. Defensible positioning ⚠️ NOT technical truth

> Framing for external use. Each claim is graded. Do not reuse a claim without its grade, and never
> present a "Say with care" or "Don't say yet" item as a confirmed capability.

**Say now** — Confirmed; safe in a sales call, deck, audit, or homepage:
- "In daily production use for ~2.5 years by a working team." ← owner-attested + 253-day host + 7 live workspaces
- "Multi-tenant — running across multiple Slack workspaces in production today." ← SSH-verified: 7 workspaces live
- "Turns natural-language messages into scheduled Slack reminders, with a disciplined reminder state machine." ← core product, verified in source + prod
- "A ChatGPT-style assistant inside Slack — 54 commands, Q&A, calculations, sourced web search." ← verified
- "Powered by your choice of OpenAI, Anthropic, or Gemini, switchable per channel." ← tri-provider routing verified
- "Auto-completes reminders from GitHub issue/PR state, and relays Slack thread replies back to GitHub." ← verified, tested
- "Semantic recall of past Slack threads via vector search." ← `sqlite-vec` hybrid recall verified
- "Durable, self-owned completion history and full audit trails on every outbound message." ← verified
- "Remotely manageable workspaces over a secured HTTP API." ← ~14 routes verified

**Say with care** — Likely or scope-bounded; true today but hedge the wording:
- "Extensible via a plugin architecture." ← real loader, but only a reference plugin ships — say "plugin architecture," never "plugin ecosystem/marketplace"
- "Notion search inside Slack (beta)." ← real but search-only, token-gated, untested — label beta
- "Backed by 1,100+ automated tests." ← CHANGELOG-cited; 67 test files confirmed, suite not re-run this session
- "An append-only event ledger captures every reminder lifecycle change — groundwork for event-sourcing." ← true and live, but say *groundwork*, not *event-sourced*
- "Instrumented with New Relic APM." ← true; do not imply a per-tenant/customer-facing observability product (personal key)

**Don't say yet** — Unverified or contradicted by the code; would not survive scrutiny:
- "Event-sourced, replayable system of record." ← the ledger is non-authoritative and reads drive nothing in prod
- "Crash-proof / zero-data-loss durability." ← no `fsync` anywhere; durable only against graceful restart
- "Proven at scale / high-volume." ← in-house single deployment, load ~0.00 — proven for *reliability and longevity*, not *scale*
- "A plugin marketplace / ecosystem." ← one demo plugin
- "Enterprise-grade observability." ← personal/test New Relic key
- "CI-enforced architectural invariants." ← the FSM validator exists but is not in CI

## 4. Where it's going  ▶ ROADMAP — forward-looking, NOT shipped

> This section is aspiration and direction. Everything here is *intended or in progress*, not a
> current capability. It exists so marketing can carry the vision forward **without** implying any of
> it ships today. When in doubt, phrase as "designed to" / "on the roadmap" / "in progress."

- **Event-sourced core (P3) — in progress, staged rollout.** The durable, append-only event ledger is already live in production as a non-authoritative side log; a pure-replay projection and a shadow-diff parity tool are built and tested. The path forward: validate the projection against a real calendar week, flip the summarize-week read path, then graduate the ledger toward source-of-truth — each step deliberately gated. The destination is reminders you can rebuild and audit from an immutable log; today it's the foundation for that, not the finished system.
- **Durability hardening.** Move the authoritative and ledger writes to real `fsync` + atomic rename, so the durability story extends from "survives graceful restarts" to "survives hard kills."
- **Enforced architecture.** Promote the FSM contract validator (and event-schema validation) into CI so the invariants are gate-enforced, not discipline-enforced.
- **A real plugin ecosystem.** The loader, security boundary, and lifecycle exist and ship with a reference plugin; the roadmap is a catalog of real first- and third-party plugins on top of it.
- **Deeper integrations.** Notion beyond search (read/write/database queries, with tests); broader two-way tooling.
- **Scale-out.** Today's strength is in-house reliability across 7 workspaces on a light-load host. The aspiration is multi-customer scale — which is a load, isolation, and observability story still to be proven.
- **Ecosystem positioning.** Sleuth already publishes a rendered reminder export consumed by the rebalanceOS / HiQS productivity system. The direction is to position Sleuth as the **Slack-native capture-and-scheduling layer of a larger productivity ecosystem**, with the event ledger as the clean integration spine.

## 5. How this baseline was built

- Depth: **Deep (read-only)** + **live production verification** · Duration: ~35 min
- Sources read directly (source-level verification via four parallel review agents):
  - Reminder core & persistence: `src/reminders-module.js`, `src/completion-store.js`, `src/event-store.js`, `scripts/validate-fsm-invariants.js`
  - P3 event-sourced core: `src/summarize-week-projection.js`, `deploy/reminders-export/events-projection.js`, `src/reminders-app-mention-handler.js`, `scripts/summarize-week-shadow-diff.js`, `scripts/replay.js`
  - Slack/AI/command/web-API: `src/workspace-ai.js`, `src/ai-providers/*`, `src/slack-app.js`, `src/web-api.js`, `src/command-catalog.js`, `src/command-intent-resolver.js`, `data/static/ai/command-catalog.json`
  - Integrations: `src/notion-module.js`, `src/thread-memory.js`, `src/plugin-loader.js`, `src/plugins/*`, `src/github-sync-module.js`, `src/github-comment-relay.js`, `src/app.js`
  - Docs: `README.md`, `CHANGELOG.md` (1.4.180–1.4.198), `package.json`
- Production check (read-only): SSH to the Vultr host — `systemctl` service state, deployed version, git HEAD/branch, workspace file census, host uptime. No writes, no service changes.
- Commands run: source-reads only; one read-only production SSH. **No tests, no build, no migrations executed.**
- Skipped / out of scope: executing the test suite or `tsc`; per-workspace activity profiling; independent reconstruction of the 2.5-year usage history; CHANGELOG before 1.4.180.

---
*Prior Express-scan baseline (v1, 2026-06-17) superseded by this verified Deep scan. Maturity drift since v1: the core moved Likely → Confirmed and Solid → Proven on the strength of source verification + live production confirmation + the 2.5-year usage history; the event-sourced and integration edges were pinned more precisely (most stayed where v1 had them, with sharper caveats).*

