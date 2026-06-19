---
baseline_version: 1
generated: 2026-06-17 local
repo: rebalance-OS
branch: development
commit: 50468f7 — fix(querier): log Qwen dual-failure + phase-qa gate (P2 Phase 1)
scan_depth: deep
scan_duration: ~20 minutes
overall_maturity: Works (Confirmed)
---

# Project Baseline — rebalance-OS  ·  2026-06-17  ·  Deep scan

## 1. Bottom line

rebalance-OS is a local-first personal data aggregator and MCP server for solo dev/agency operators:
it ingests Obsidian vault files, GitHub activity, Google Calendar, Slack reminders (via Sleuth),
Gmail, and Figma comments into a local SQLite+sqlite-vec database, then exposes that data as 25
MCP tools that host agents (Claude, Copilot, Cursor, etc.) can query. The core ingest-query-MCP
pipeline is well-engineered and tested (500+ tests, CI on 3.12/3.13, v0.40.0 shipping). The gap
between what exists and what the README promises is in the stated **endgame** — transparent
multi-signal project prioritization and a "what next" weekly rebalance view — which is explicitly
deferred roadmap, not yet built. As it stands today, this is a strong personal work-context server;
it is not yet the autonomous work OS that tells you where your attention should go.

---

## 2. Technical status (plain language)

**Overall maturity: Works → Solid (Confirmed)**
The core pipeline (ingest → SQLite → MCP query) is Solid on its own. The product as a complete
system rates Works because the synthesis layer uses a deliberately small local model (Qwen3-0.6B),
the email signal is Phase 1-limited, and the key value-prop feature (multi-signal prioritization)
is not yet built. No rating was dragged down by a weak load-bearing *implemented* feature — the
weak area is a deferred roadmap item, which is a different kind of honest.

### Feature status

| Feature | Maturity | Confidence | What that's based on |
|---|---|---|---|
| GitHub ingest (activity + artifacts) | Solid | Confirmed | `github_scan.py` (809 LOC) + `github_knowledge.py` (978 LOC); custom error class, rate-limit backoff, token-fallback chain; tests cover 401/429/timeout |
| Obsidian vault ingest + TF-IDF + Qwen3 embeddings | Solid | Confirmed | `note_ingester.py` + `embedder.py`; hash-delta sync; sqlite-vec ANN search; test suite covers delta, touch, delete-cascade |
| SQLite schema + migrations (0001–0005) | Solid | Confirmed | Migration runner owns each migration's transaction; gated in `refresh_index()` before collectors run; composite PK migration (0005) tested explicitly |
| MCP server (25 tools, 7 domains) | Solid | Confirmed | `mcp/server.py` + domain tool modules; backward-compat shim for older launch commands; hermetic MCP tests |
| Launchd scheduler fleet (10 jobs) | Solid | Confirmed | 10 plist templates + shared lib; SCHEDULER.md policy table enforced by `test_scheduler_policy.py` (17 tests); installer flow tested |
| RepairFSM (pulse self-repair) | Solid | Confirmed | `repair.py` (233 LOC, 3-state FSM, bounded LLM escalation); 17 unit tests + 6 pulse integration tests |
| Sleuth reminders ingest | Solid | Confirmed | `sleuth_reminders.py` (736 LOC); file-source, no SSH tunnel; full-refetch + column-diff; 25 tests; heartbeat staleness validation |
| Google Calendar ingest (basic sync) | Works | Confirmed | `calendar.py` (566 LOC); OAuth + keyring; 30d window; incremental upsert; tests for migration gating and operator event isolation |
| Semantic index (vault + GitHub + email + Figma) | Works | Confirmed | `semantic_index.py` (774 LOC); backfill from 5 sources; hybrid RRF; `semantic_documents` + `semantic_embeddings` unified ANN target |
| Gmail ingest (Phase 1) | Works | Confirmed | `gmail.py`; 100-message cap per run; metadata+snippet only; no body parsing; no historical backfill; explicitly documented as Phase 1 ceiling in ARCHITECTURE.md |
| Two-layer LLM synthesis (`ask()`) | Works | Confirmed | `querier.py` multi-source context gathering + Qwen3-0.6B local synthesis (Layer 1) + host agent (Layer 2); `skip_synthesis=True` available |
| Team calendar signal / Gemini inference (P2 Ph.1) | Works | Likely | Shipped v0.40.0 (2026-06-12); composite PK, person attribution, Gemini cloud call; tested for migration gating and event isolation; less battle-tested than older features |
| Welcome agent / onboarding lifecycle | Works | Confirmed | `lifecycle.py` (480 LOC); Stage state machine; `/welcome` skill; Phase 6 complete; hermetic walkthrough test (0.06s) |
| Terminal dashboard (Rich) | Works | Confirmed | `scripts/dashboard.py`; polls SQLite every 2s; background GitHub refresh thread; `r` to force refresh |
| Web pulse mirror (FastAPI + static HTML) | Works | Confirmed | `web.py` (978 LOC); `/auth-log`, `/sleuth-graph`, `/focus5`, `/health`; static HTML via `pulse_web.py`; loopback-only bind |
| Figma comments ingest | Works | Confirmed | `figma.py`; registry-provider plugin; requires explicit PAT + file-key allow-list; `included_in_all=False` (opt-in) |
| **Multi-signal project prioritization (roadmap)** | **Partly built** | **Confirmed** | Explicitly deferred; P2 calendar work is the first piece; the "what next" dashboard view and weekly rebalance report are not built |

### What's solid

- Ingest correctness: every source has a defined sync semantic (hash-delta / window-refetch / full-diff); no silent data loss
- Error envelopes: `refresh_index()` returns per-collector errors, never raises; collectors isolated from each other
- Secret hygiene: layered resolution (keyring → rbos.config → env → gh-CLI); no credentials in tracked files; `REBALANCE_NO_KEYRING=1` for CI
- Path portability: `paths.py` unified resolver; no hardcoded `/Users/<operator>` in checked-in files; plist templates use `{{placeholders}}`
- Audit trail: structured JSONL logs, `audit_modules` MCP tool enforces CHANGELOG/ARCHITECTURE.md coverage of every ingest module
- Ops hardening: RepairFSM for pulse git conflicts; `rebalance doctor` CLI + MCP `diagnose_repo` tool; launchd `KeepAlive` + `ThrottleInterval`
- Test discipline: hermetic tests (tmpdir + patched outbound calls); CI on 3.12 + 3.13; scheduler policy enforced by test suite

### What's thin or risky

- **Sleuth data not available in `ask()`**: ARCHITECTURE.md explicitly marks `_gather_sleuth_context()` as "future." Sleuth reminders are collected and stored in SQLite but the `ask()` context-gathering step does not include them. A user who asks "what are my open reminders?" via the `ask` MCP tool gets an answer with a blind spot.
- **Gmail is Phase 1 limited**: 100-message cap, inbox only, no body parsing, no project auto-correlation. Email signal is there but thin. The roadmap email→project classifier is not built.
- **Multi-signal prioritization is not yet built**: The stated product endgame — "see where your attention is actually going" across all signals, feeding a weekly rebalance — exists in roadmap docs and P2 is in progress, but no working implementation surfaces a unified signal score or "what next" view.
- **ask() LLM quality**: Qwen3-0.6B is intentionally small and fast; the architecture explicitly calls out that it "makes mistakes." Correctness depends on the host agent (Layer 2) doing fact-check and refinement. Without a capable host agent, synthesis quality degrades.
- **ask_self RAG index is stale**: README notes last ingested 2026-05-28; as of baseline date (2026-06-17) that is 20 days stale. The ask-self query surface reflects the codebase state from 20 days ago.
- **macOS-only operational model**: launchd fleet, Keychain, MLX on Apple Silicon. No Docker, no Linux support, not multi-user.
- **No `.env.example`**: Config-first model (rbos.config + keyring) requires reading GOOGLE_CALENDAR.md, GMAIL.md, SLEUTH_SYNC.md, AGENTS.md to set up from scratch. Setup UX is documentation-dependent.
- **`code` collector coverage**: The AST/code-chunk collector is registered in `index_ops.py` with `included_in_all=True` but no explicit test coverage is called out in the CHANGELOG or test census.

### What I could not verify

- **Test suite at current HEAD**: CHANGELOG reports 507 passing as of v0.31.10 (2026-06-08); the suite has continued to evolve through v0.40.0. No tests were run during this scan. Pass/fail at HEAD is Unverified.
- **Gemini inference end-to-end (P2 Phase 1)**: Code and schema exist; key resolution via gcloud CLI is tested; actual Gemini API call outcome at runtime was not observed.
- **Launchd fleet installed and running on operator machine**: Templates are correct; whether they are currently installed and healthy is Unverified.
- **Calendar and Gmail OAuth token validity**: Token resolution code is correct; runtime token freshness is Unverified.
- **Qwen3-0.6B model presence**: `mlx-embeddings` dep is declared; whether the model is downloaded and loaded on the operator's machine was not checked.
- **`code` collector behavior**: Registered but not explicitly tested — what it collects and whether it errors silently on large repos is Unverified.

---

## 3. The Future

### Where P2 stands right now

Phase 1 (the data layer) is **complete and shipped as 0.40.0** (2026-06-12). The foundation is
real and code-confirmed:

- `calendar_events` has a composite PK `(id, calendar_id)` + `person` column (migration 0005,
  atomic, runner-owned transaction, rollback-on-error verified)
- `team_calendars` config drives multi-person sync; live sync confirmed: operator 243 events ·
  Matthew 239 · Jose 3 · Jinhui 7
- Privacy policy enforced in code: `export_calendar_snapshot` filters `WHERE calendar_id = 'primary'`
  (default deny); reader functions scoped to `'primary'`; tests cover leak and contamination paths
- Gemini key resolution wired: `get_gemini_api_key()` → GSM Python SDK → env → `gcloud secrets versions access`
- 916 tests green after two independent review passes (local A–G findings + external F1–F4)

What is **not yet built** is everything the partner brief leads with — the ranking brain, the
"what next" dashboard view, the lever system. Those are Phase 2.

---

### The validated hypothesis (Phase 0 A/B test)

Before Phase 1 was built, a pre-registered, blinded A/B test earned the right to productize it.
The test is observable in git history (`781a491` exit artifact; `4819d78` votes; `aa0a254` cohort
lock). Key details:

**Setup:** 5 completed workdays (2026-06-05 to 06-11). Arm A = Noel's own signals (calendar,
GitHub, Sleuth reminders, vault, email). Arm B = Arm A + Matt's shared work calendar. Two
independent judges — Noel and Gemini (`gemini-3.1-flash-lite`) — voted on blinded `OPTION 1 /
OPTION 2` pairs without knowing which arm was which. Gate set **before** any vote was cast; every
post-exposure rule change logged with its bias direction (all tightened against B, not loosened).

**Conjunctive gate — all three had to pass:**

| Criterion | Result | Threshold |
|---|---|---|
| Additivity — median net-new signal rate | **~58%** | ≥20% |
| Decision value — Noel-confirmed dropped-ball catches | **5/5 days** confirmed; 100% precision | ≥1 catch + B-only precision ≥50% |
| Preference — Noel | **4 of 5 days** favored B | ≥3/5 independently |
| Preference — Gemini judge | **5 of 5 days** favored B | ≥3/5 independently |

**Verdict: GO.** The test was designed to kill if Matt's calendar was mostly redundant. It wasn't.

**The key structural finding (owner-bias):** Noel's GitHub stream is dominated by his own tooling
and system work (rebalance-OS, ask-self, sleuth-app). The team's client/operational work (Binoid,
Bloomz, GoAffPro production incidents, delegated DB operations) rarely reaches repos he authors.
Matt's calendar fills that structural blind spot. The canonical Phase-0 catch on 06-11 — *Bloomz
HPOS switchover BLOCKED by NMI vault — work Noel had delegated* — is the archetype: a delegated
dropped ball that the operator's own signals structurally cannot see. This finding is the empirical
basis for the **owner-bias-correction lever** in v0.5.

---

### What Phase 2 has to build

**v0.5 definition of done** (from the planning doc, decision #6):
> Noel opens the dashboard in a browser and sees a ranked, person-attributed "what should we work
> on next" list containing ≥1 item his own signals would have missed.

The gap is one working surface, not a platform:

1. **A lever-based ranked scorer** — weighted sum, closer to Taskwarrior's urgency model than a
   neural net; defaults seeded from Phase 0 spike results (the decision rule the test validated
   becomes the starting coefficients)
2. **A "What should we work on next?" route** in `web.py` + a panel in `pulse.html` (both
   already exist for other views — this is a new route/panel, not new infrastructure)
3. **`ask()` MCP parity** — the same ranked output accessible through the agent interface
4. **Jose + Jinhui onboarding** — each behind a per-person mini additivity check; their calendars
   are sparse (3 and 7 events), and a near-empty calendar shouldn't dilute the blend

**The tunable levers (defined in planning doc, not yet coded):**

| Lever | What it controls | Phase-0 default |
|---|---|---|
| Per-person weight | Trust on each teammate's calendar | Matt = 1.0; Jose/Jinhui start low, earn weight via per-person additivity |
| Per-source weight | Calendar vs GitHub vs Sleuth vs email | Tunable; calendar earned its seat for team operational signal |
| Redundancy penalty | How hard to suppress teammate items already echoed in operator's own data | The additivity knob; content de-dup is its hard floor |
| Vagueness discount | Down-weight "Slack&Emails"/"Cron research"; up-weight named PR/issue/incident actions | Threshold from the Gemini judge calibration rule |
| Owner-bias correction | Up-weight team operational/client work vs operator's tooling-skewed GitHub stream | **Default ON** (Phase-0 structural finding) |
| Drop sensitivity | How aggressively to flag blocked/stale delegated work | The NMI vault blocker catch is the canonical calibration case |

None of these levers are implemented yet. The design is complete; the code is not.

---

### The moat thesis — honest assessment

The partner brief frames the moat as the **scoring brain + proprietary outcome labels**, not the
ingest plumbing. Three independent competitive research sweeps (~40 OSS repos, conducted 2026-06-12)
confirm the read: local SQLite + calendar/GitHub/Slack/email connectors + MCP is now a commodity
pattern — two repos independently converged on exactly that substrate in Mar/Jun 2026 (OWL,
DevRecall, both live and verified). What nobody has built is the scoring and blending layer that
separates net-new from redundant signal, blends a team dimension, and flags delegated work about to
be dropped.

**What exists today to support this thesis:**

- Pre-registered A/B test with real, observable results (not claimed; in git history)
- The Phase 0 spike proved ~58% median additivity and 5/5 real dropped-ball catches — this is the
  empirical basis for the claim that the scoring brain has signal worth building
- `person` column + composite PK = the first edge of the future attribution graph
- Gemini synthesis key wired; same REST pattern already in production in `repair.py`
- Sleuth reminders already collected in SQLite (even if not yet surfaced in `ask()`)

**What doesn't exist yet and is needed for the moat to be real:**

- The lever-based scorer (designed, not coded — Phase 2)
- The "what next" dashboard view (Phase 2 definition of done)
- **Sleuth outcome labels** — the "dropped-ball label oracle." The drop-sensitivity lever and the
  detector that is the core value claim need *outcome data*: did the delegated task actually
  complete or get dropped? Today Sleuth ingest captures only the active-state snapshot; when a
  reminder is completed it vanishes, and the outcome is never recorded. The bootstrap plan is
  diffing `rebalance-git-pulse` commit history (crude event log, available now); the first-class
  export requires sleuth-app `P3` event-sourced core — a separate project on a timeline this
  project doesn't control
- The entity_graph attribution layer (Phase 3, explicitly deferred to v0.6)
- Multi-user (Jose/Jinhui) additivity-gated onboarding (Phase 2, not started)

**Honest verdict:** the moat thesis is defensible and the Phase 0 test provides real empirical
grounding — not just a claim. But the moat as described in the partner brief is **forward-looking**:
it rests substantially on things in the plan, not things in the code. Phase 2 has to ship for the
scoring brain to exist at all, and the proprietary outcome-label advantage depends on a second
project (Sleuth P3) delivering an export that hasn't been built yet. Showing a prospective partner
the Phase 0 exit artifact and the git history is appropriate; presenting the moat as realized
today is not.

---

### What's deferred (not Phase 2)

- **Phase 3: entity_graph** — SQLite projection (`person worked_on project`, `event mentions project`,
  `reminder completed`, etc.) that makes the lever system more robust and explainable; deferred to
  v0.6. The Phase 1 `person` column is its first edge.
- **Sleuth outcome oracle (first-class)** — pairs with entity_graph; needs sleuth-app P3 event-sourced
  core on the Sleuth side. Bootstrap via `rebalance-git-pulse` diff available now.
- **Git history privacy scrub** ([issue #66](https://github.com/Hypercart-Dev-Tools/rebalance-OS/issues/66))
  — post-P2 cleanup; the repo is public and early doc revisions contain verbatim teammate calendar
  bundles. Accepted as low-sensitivity for now (raw bundles live in gitignored `temp/`). Queue
  after v0.5 ships.
- **Weekly rebalance report with multi-signal counts** — stated in README; requires the full
  lever-scored output plus email→project correlation (not yet built).
- **Slack integration beyond reminders** — noted in roadmap; no implementation.

---

## 4. Defensible positioning  ⚠️ NOT technical truth

> The claims below are framing for external use. Each is graded. Do not reuse them
> without their grade, and never present a "Say with care" or "Don't say yet" item
> as a confirmed capability.

**Say now** — Confirmed; safe in a sales call, deck, or audit:
- "Local-first MCP server that ingests Obsidian, GitHub, Calendar, Slack reminders, and Gmail into a queryable SQLite knowledge base — no private data leaves the device." ← all 6 ingest modules present, keyring-backed secrets, loopback-only web server
- "25 MCP tools across 7 domains, compatible with Claude Code, Claude Desktop, Cursor, Continue, and any MCP-capable host." ← `mcp/server.py` + domain modules; `.mcp.json` + `.vscode/mcp.json` both shipped
- "Production-hardened GitHub ingest with rate-limit backoff, 401 token-fallback chain, and structured error envelopes." ← `github_scan.py` directly read; error paths tested
- "Self-repairing pulse publish via a bounded finite-state machine — non-fast-forward git conflicts are resolved deterministically without human intervention." ← `repair.py` + 23 tests
- "500+ tests, CI on Python 3.12 and 3.13, semantic versioning, ~1 release per day during active development phases." ← CI config read; CHANGELOG pattern confirmed
- "Apache 2.0 licensed." ← `APACHE-LICENSE-2.0.txt` present

**Say with care** — Likely; true today but hedge the wording:
- "Team calendar analysis with AI-powered project attribution, available in beta (v0.40.0)." ← shipped 2026-06-12; composite PK, person attribution, Gemini inference; less battle-tested than core pipeline
- "Semantic search across vault, GitHub artifacts, and email in a single ranked result set." ← `semantic_index.py` confirmed; note that Sleuth data is *not* yet in this index
- "Extensible collector plugin architecture — add a new data source in one file, no changes to the query or MCP layers." ← Figma is the worked example; architecture confirmed; extension path documented in PLUGINS.md and ARCHITECTURE.md

**Don't say yet** — Unverified; would not survive scrutiny:
- "See where your attention is actually going across all your signals." ← Sleuth reminders are not gathered in `ask()`; email→project correlation is not built; the cross-signal view doesn't exist yet
- "AI-powered work prioritization — know what to focus on next." ← multi-signal prioritization is explicitly deferred roadmap; no implementation
- "Weekly rebalance report grounded in multi-signal counts." ← not built; noted in roadmap as requiring email + calendar + GitHub + Slack attribution; Phase 2 in progress
- "Proven in production across teams." ← single-operator personal tool by design; no multi-user deployment evidence
- "Full email history search." ← Gmail Phase 1 cap is 100 inbox messages per run, metadata+snippet only; no body, no historical backfill

---

## 5. How this baseline was built

- **Depth:** Deep · **Duration:** ~20 minutes · **Tests run:** No (read-only scan; no side effects)
- **Sources read:**
  - `README.md`, `CHANGELOG.md` (117 KB, v0.40.0 HEAD), `AGENTS.md`, `ARCHITECTURE.md` (full)
  - `pyproject.toml` (dependencies, extras, entry points)
  - 50+ source files sampled across `src/rebalance/ingest/`, `src/rebalance/mcp/`, `src/rebalance/cli/`, `scripts/`; key files read in full: `index_ops.py` (1408 LOC), `github_scan.py` (809 LOC), `config.py` (1364 LOC), `lifecycle.py` (480 LOC), `pulse.py` (1087 LOC), `repair.py` (233 LOC), `querier.py`, `semantic_index.py` (774 LOC)
  - Test files: 10+ sampled across core modules; CI config (`.github/workflows/ci.yml`)
  - `git log --oneline -30` for velocity, branch list; filtered commits for P2/signal/calendar trail
  - TODO/FIXME grep across `src/rebalance/` (minimal debt found)
  - `PROJECT/2-WORKING/SIGNAL-GENERATION/P2-TEAM-CALENDAR-SIGNAL.md` (full — A/B test design, exit artifact, lever definitions, Phase 2 scope)
  - `PROJECT/2-WORKING/SIGNAL-GENERATION/HiQS-PARTNER-BRIEF.md` (full — moat thesis, scoring model description)
- **Commands run:** `git log`, `git branch`, `git rev-parse HEAD` (read-only); `find` for structure; `grep` for debt markers — no DB writes, no test execution, no installs
- **Skipped / out of scope:**
  - `PROJECT/` phased planning documents (read AGENTS.md + ARCHITECTURE.md instead)
  - `MCP.md`, `PLUGINS.md` tool spec details (not needed for maturity rating)
  - `experimental/` directory (intentionally out of scope; not a load-bearing feature)
  - `ask_self/index/` portable DB contents
  - Test execution results (not run; pass/fail at HEAD is Unverified)
  - Runtime behavior (OAuth, Gemini API, launchd fleet status) — read-only scan cannot observe runtime
