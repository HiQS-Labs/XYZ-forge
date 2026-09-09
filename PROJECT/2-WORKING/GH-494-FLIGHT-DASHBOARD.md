---
gh_issue: 494
source: https://github.com/HiQS-Labs/XYZ-forge/issues/494
title: Flightdeck — HTML consumer app and future Swift plan
status: HTML v1 implemented — partial-data pilot awaiting operator acceptance
created: 2026-09-08
updated: 2026-09-08
owner: Codex
goal: Help the operator remember and advance concurrent repository lanes each hour.
doc_type: project
branch: feat/flight-dashboard-mockup
effort: 3
complexity: 4
risk: 3
phases: 5
reversibility: Costly — shared read API and optional source-owned schema/export extensions; additive rollout and rollback required
---

# Flightdeck — HTML consumer app and future Swift plan

## Status

| What was just completed | What's next |
|---|---|
| HTML v1 now serves tokenized Layouts A/B/C from one source-neutral snapshot; Rebalance, CLIO and Git Pulse read live while topology and continuity report unavailable. Focused contract, server, token and interaction checks pass. | Clear the ambient security dialog and rerun the disposable-clone repository gate, then complete independent code review and begin an operator pilot. Exact checkout counts and attested milestone coverage remain blocked on existing producer outputs. |

## Table of contents

1. [Phase 1 — Connector contract and passive endpoint](#phase-1--connector-contract-and-passive-endpoint)
2. [Phase 2 — Fully tokenized production design](#phase-2--fully-tokenized-production-design)
3. [Phase 3 — HTML app, navigation and refresh](#phase-3--html-app-navigation-and-refresh)
4. [Phase 4 — Coverage gaps, verification and pilot](#phase-4--coverage-gaps-verification-and-pilot)
5. [Phase 5 — Future Swift app](#phase-5--future-swift-app)
6. [Completion and deferred work](#completion-and-deferred-work)

## Phase 1 — Connector contract and passive endpoint

**Goal:** One source-neutral, read-only response supplies the dashboard through
independent incoming connector plugins. A UI refresh never collects data.

### Decision and ownership

Flightdeck core is a **consumer and aggregator**, independent of Rebalance, CLIO,
Git Pulse and Daily/Shutdown. Each external system remains owner of its data, but no
one source is required for Flightdeck to start or render. Missing, disabled or failed
connectors yield explicit unavailable/partial capabilities; other connectors and
saved selections continue working.

Build a small Flightdeck-owned Python loopback host in XYZ with `/flightdeck/` and
`GET /flightdeck.json`. It loads a static registry of incoming connector modules,
asks each enabled connector for already-produced data, normalizes their batches and
serves one snapshot. This host is warranted because a browser cannot safely read
SQLite and configured local files directly. It is not a collector, scheduler or
second source of truth. Other agents' current checkouts and running jobs remain
untouched.

The existing mockups are reference artifacts. All three stay byte-identical during
this plan and production build; import the approved design once into production
assets, with provenance, rather than maintaining two production copies. Frozen
Layout A is additionally pinned by `layout-a.sha256`.

Grounding: [Recon Map](recon-flightdeck-consumer.md). `RB:` citations in that map
refer to Rebalance commit `0bffc4d`; current mockup baseline is XYZ `c7e4bce`.
Re-anchor source paths/HEAD at execution. The recon grounds the first-party
connectors; it does not make those producers architectural dependencies.

### Data reuse and actual gaps

| Dashboard requirement | First-party connector | What is actually missing / permitted work |
|---|---|---|
| Repo/project names and aliases | `rebalance` reads registry/mirror data | Normalize explicit identities; never equate two repos just by basename. |
| Issue titles/state, open PRs, checks and links | `rebalance` reads existing GitHub corpus tables/helpers | Expose omitted fetched times/full SHAs and bounded completeness. No new GitHub fetching. |
| Last-hour commits | `git_pulse` reads synced TSV/health files; `rebalance` may contribute cached commits | Retain source/device and deduplicate centrally by canonical repo + full SHA. |
| Names of agents, requested task and recent attention | `clio` reads existing JSONL directly, without requiring Rebalance ingest | Normalize branch/machine/session when present. No new prompt writer/tailer. |
| Next actions and handoff context | `rebalance` reads ranked actions; `clio` and `continuity` contribute intent/notes | Deterministic central presentation. No model call or reranking on refresh. |
| Full clone/worktree names and counts | `topology` reads persisted Daily/Shutdown scanner output | **Current saved feed is insufficient.** First persist/export the existing scanner result through its owner. Do not write another scanner. |
| Meaningful agent milestones | Existing structured completion evidence, if a repo/issue join can be verified | Completeness not established. Display unknown until an existing writer exposes attested completion; prompts do not substitute. |
| Producer freshness and coverage | Every connector reports source watermarks/coverage | Adapt existing health fields; a fresh heartbeat is not complete coverage. |
| 6 PM wrap-up | Existing cached PR/issue/action data plus operator timezone | New display and selection logic only; no merge, QA runner, cleanup or scheduler. |

CLIO's concrete path is the installed shared capture hook/tailers documented by
`RB:utils/CLIO/INSTALL.md`, with output `~/.claude/prompt-log.jsonl`, then existing
`ingest/clio.py` → `clio_prompts`. Its Markdown export is a presentation artifact.
The Git Pulse sync folder's `CLIO/README.md` describes an optional daily synthesis;
it does **not** demonstrate that raw prompts are synced there. V1 prompt coverage
is device-local unless existing cross-device publication is independently verified.
The `clio` connector depends on the documented JSONL record shape and configured
path, not on CLIO being installed or running; fixture/file-compatible producers can
satisfy it. Rebalance is likewise one optional corpus connector, not Flightdeck's
database, host or mandatory source.

### New code budget and read boundary

Proposed XYZ files are **new paths**, not claims they already exist:
`src/flightdeck/` for the host, aggregation and connector modules, and
`web/flightdeck/` for production assets/tokens, plus focused tests. Use Python
stdlib HTTP/SQLite/file APIs and browser JavaScript; no UI framework, Node server,
message bus, dynamic plugin loader, package marketplace or Flightdeck database.

### Minimal module boundary

Keep the production app modular at the seams that are likely to change, without
turning every card or helper into an abstraction. V1 has five responsibilities:

| Responsibility | Smallest durable boundary | Must not own |
|---|---|---|
| Connector | One module per incoming source implementing the same small read protocol | UI, cross-source joins, readiness classification, scheduling or collection |
| Aggregation | One module validates connector batches, correlates identities and returns the versioned snapshot | Source-specific parsing, HTML, theme values or polling |
| Data client | One browser module for bounded GET, validation, last-good cache and freshness | Repo correlation, readiness policy or DOM rendering |
| App state | One browser module for route/selection/scroll/spotlight and refresh state | CSS values, source reads or per-layout duplicate state |
| Views | One browser module with small render functions for A/B/C/detail | Data fetching, independent stores or a component framework |

Use plain ES modules and functions. Split a file only when it has a second owner,
must be tested independently at a trust boundary, or becomes materially harder to
read; file size alone is not a reason. A one-use card class, interface/factory,
dependency-injection container, event bus, generic plugin framework and generic
design-system package are out of scope. The connector batch is the only
source-to-aggregator contract. The JSON snapshot is the only host-to-client
contract. App state is the only cross-view runtime contract. Semantic tokens are
the only styling contract. These four seams make later replacement possible
without unrelated extension points.

### Incoming connector protocol and first-party set

A connector is a Python module registered by ID in one checked-in dictionary. It
exports immutable metadata (`id`, `schema_version`, `capabilities`) and one bounded
`read(config, deadline)` function returning a `ConnectorBatch`. The batch contains
source status/coverage/watermarks plus normalized repos, checkouts, issues, PRs,
lanes and events. Unsupported fields are absent with a reason; connectors never
invent empty totals. Configuration names allowlisted paths/DBs and enablement only.

Build these first-party connectors in the initial implementation:

| Connector | Reads | Can be omitted independently |
|---|---|---|
| `rebalance` | Rebalance read-only DB/cached actions and GitHub corpus | Yes; issue/PR/action capabilities become unavailable unless another connector supplies them |
| `clio` | CLIO-compatible prompt JSONL | Yes; prompt/intent context disappears, progress still comes from attested sources |
| `git_pulse` | Git Pulse sync TSV and device health | Yes; commit/device coverage reflects remaining sources |
| `topology` | Versioned persisted Daily/Shutdown scanner result | Yes; checkout counts become unknown |
| `continuity` | Existing Daily/Shutdown handoff/milestone output when structured and attributable | Yes; unattested milestones remain unknown |

This is an incoming adapter boundary, not a runtime extension ecosystem. Adding a
connector means adding one module, one registry entry and contract fixtures, then
restarting the local host. No directory scanning, entry-point discovery, arbitrary
third-party code loading, hot reload, lifecycle callbacks or connector-to-connector
calls in v1. Revisit discovery only when a real separately distributed connector
cannot reasonably be registered in the repository.

Shared policy stays in aggregation when it affects truth: identity, joins, coverage,
progress and QA classification. Connectors parse and attribute; they do not decide
cross-source truth. The browser owns presentation and navigation.
Swift consumes the same snapshot rather than importing browser modules; native
views may reimplement presentation only after the HTML behavior is accepted.

The `rebalance` connector reuses `db_connection_readonly` (`mode=ro`) and existing
query helpers where import boundaries permit. Otherwise it issues minimal read-only
queries against the documented schema. Preserve canonical mirror/dedup semantics,
and pin them with shared fixtures so another corpus connector can produce equivalent
identity. Do not import the Rebalance web host or start its services.

Do not wrap `/focus-5.json` wholesale: it probes Git and provides a top-five
selection. Do not call source refresh, `sync_clio_prompts`, live ranking,
`get_index_status` schema assurance, `collect_pulse_snapshot`, `publish_pulse`,
`git ls-remote`, or POST `/api/refresh` while servicing Flightdeck. Missing inputs
produce explicit partial/unavailable responses, never an implicit bootstrap.

Read the configured sync folder using supported pure path resolution and existing
parsers. Never source config shell code just to discover a directory. Bound reads
to configured roots; resolve symlinks/pointers, validate schema, reject escaping
paths, truncated records and unsupported versions. No calendar/email raw content is
needed for this app. No arbitrary filesystem browser or shell command endpoint.

### Versioned view contract

`schema_version=1`; additive fields tolerated, unsupported major version rejected.
Expose UTC instants; local timezone conversion belongs at the display edge.

| Object | Required semantics |
|---|---|
| Snapshot | `generated_at`, `snapshot_id`, `sources[]`, `repos[]`, `coverage`, `truncated`. One bounded response per cycle; no pagination in v1. Generation means projection time, not new work. |
| Source | Stable source/device ID, latest successful observation/ingest time, `coverage_from`, `observed_through`, `fresh_until` (nullable), expected producer schedule when known, `coverage=complete/partial/unknown`, `availability=ok/stale/unavailable`, errors without private content. |
| Repo | Canonical host/owner/repo key, display name, source aliases, participating devices, selected/carry-forward state, source refs. Forks remain separate unless an existing explicit identity mapping says otherwise. |
| Checkout | Canonical repo key, device, normalized local path/common Git dir, `kind=full_clone/linked_worktree`, branch, observed time and provenance. Incomplete inventory returns exact count `null` plus known members/count. |
| Issue | Repo key + issue number; title/state; linked lanes; last-hour progress and intent shown separately; evidence/confidence for inferred associations. |
| Agent lane | Source agent/session ID where available, repo/issue association, requested task, `last_prompt_at`, `last_meaningful_progress_at`, next action and coverage. Agent application name is not proof a process is running. |
| Progress event | Stable source event ID, kind, occurred/observed times, canonical repo, full SHA or issue/PR key, optional attested lane, confidence/source refs. Unknown joins remain unknown. |
| PR | Repo+number, cached title/state/draft, head SHA, checks/reviews tied to that SHA, fetched time, freshness/completeness, linked issue keys. Cached readiness is advisory. |

Correlation order: explicit repo/issue links → existing canonical aliases and
repo-bound branch/CLIO references → unresolved. Never treat an unqualified `#123`
as globally unique. Basename collisions must not merge records. Dedup commits by
canonical repo + full SHA; short-only Pulse SHA matching must be unambiguous or
remain separate uncertain evidence. Collapse the same event observed on two devices
without collapsing their distinct physical clones. Group issue cards by repo+issue,
not agent; several agents may work on one issue.

Open issues alone do not establish active work. Default lanes combine operator
selection/carry-forward with recent attested work or clearly labeled CLIO intent.
Preserve quiet selected repos; do not rotate them away automatically. A missing repo
must be recoverable from selection/coverage diagnostics, not silently excluded by a
top-five ranking filter.

Query bounds: selected repo allowlist, default last 24 hours of detail plus latest
known progress anchor per selected lane; last-hour display filters `0 <= age < 60m`.
V1 uses one bounded snapshot, **no pagination/cursor protocol**. Caps are 100 repos,
2,000 issues/PRs, 5,000 events and 2 MiB serialized output per cycle; the whole
projection/read cycle has a 6-second deadline. Stable repo/key/time ordering makes
truncation reproducible; selected repos have priority. Read SQLite in one read-only
transaction and materialize each external source once per cycle with its own
observation watermark. If a file changes during the bounded read, mark that source
partial rather than combining its versions. Cross-source observation times may
legitimately differ; they are never represented as one source observation time.

`snapshot_id` is an opaque server-boot ID plus monotonic response sequence. Within
one boot, reject older sequences; on a different boot accept only the response to
the currently active request. A local request-generation counter invalidates late
responses from prior foreground/manual cycles. Do not order opaque boot IDs or
wall-clock generation timestamps. Unknown pagination fields never trigger another
request. An exhausted row/byte/time budget returns a bounded partial response or
explicit failure; retain last-good data on failure. An exact total is allowed only
for a completely read scope, otherwise return `null` and a known-subset count.
Never report zero from an unqueried/failed/truncated source. This deliberately avoids
an unbounded multi-page cycle or mixed-page revisions; broader history is deferred.

### Phase 1 — delivery and QA

- [ ] Commit the contract, synthetic fixtures and source mapping; every requested field is populated, nullable with a reason, or listed in the gap register below.
- [x] Add the Flightdeck host, static connector registry, aggregation and explicit routes; zero enabled connectors and any one connector missing return honest capability states without preventing the app shell from loading.
- [x] Implement and contract-test `rebalance`, `clio`, `git_pulse`, `topology` and `continuity`; disable each independently and prove remaining connector fixtures still render without conditional core code.
- [ ] Prove passive reads: source/DB/sync files unchanged; spy collectors, Git subprocesses, network clients and ingestion functions and assert zero calls during repeated GETs. Negative control deliberately calls a forbidden path and fails the guard.
- [ ] Test basename collisions, mirror aliases, duplicate SHAs, multiple agents per issue, unlinked PRs, stale checks on another head, and more than 10 PRs. Assert nonempty inputs before checking totals.
- [ ] Verify aggregate row/byte/time exhaustion, a source changing mid-read, late/out-of-order responses and server restart. Unexpected/repeated cursor fields cause zero additional requests; truncation refuses exact totals. Disable the budget guard as a failing control and retain the red receipt.
- [ ] Cap pointer/file/query sizes and record invalid-schema/permission/partial-file failures. No malformed input becomes a healthy empty list.
- [ ] Run focused tests and independent review; commit receipts/provenance in the implementation PR. Keep existing source schedules and consumers unchanged.

## Phase 2 — Fully tokenized production design

**Goal:** Change color palette, fonts, scale, spacing, shape and motion centrally,
without editing individual card/layout rules or JavaScript rendering logic.

Current designs are only partially tokenized: shared B/C CSS contains 53 literal
hex-color occurrences and 49 font-size declarations; working A contains 71 and 102.
Those are measured reference-state counts, not production quality claims. No HTML
mockup styles are changed by this planning task.

### One token source, all views and appearances

Create `web/flightdeck/design-tokens.json` as the canonical typed token source.
A small stdlib generator produces CSS custom properties and responsive overrides;
its only present purpose is deterministic token validation/output. No general design
system framework or runtime style editor. Future Swift decoding/code generation
uses this same source rather than maintaining a second palette.

| Family | Examples of centralized values |
|---|---|
| Palette and semantic roles | Canvas/surface/raised surface/text/muted/border/focus; progress/waiting/unknown; repo accents; overlay and fade endpoints; every gradient stop. |
| Typography | UI/mono font stacks, sizes, weights, line height, letter spacing, numeric styles; fallbacks for unavailable fonts. |
| Geometry and density | Spacing scale, card padding/gap/width limits, sidebar width, icon/control sizes, border widths/radii, viewport gutters, visible-card counts, breakpoints. |
| Effects | Shadows, spotlight dimming, opacity, backdrop treatments and mask stops. |
| Motion | Transition durations/easing, navigation motion; reduced-motion override. |
| Themes | Semantic light/dark mappings plus system preference; shared meaning for red/amber/green/unknown. |

Use base values → semantic aliases; component-specific aliases only where a real
component needs an independent value. Structural constants such as `0`, `100%`,
`auto`, intrinsic layout keywords and data-driven chart quantities are permitted;
visual design values are token references. Enumerate those narrow exceptions in the
validator instead of allowing arbitrary inline styles. Repo data supplies an accent
key, never a raw color or arbitrary CSS. Status data supplies meaning, not color.

“Fully tokenized” applies to changeable **visual decisions**, not every CSS token or
runtime value. Tokenize palette roles, typography, density, card geometry, effects,
motion and named responsive thresholds. Keep layout mechanics such as grid/flex
keywords, percentages, content-driven sizes, stacking structure and accessibility
state in CSS; keep repo/status/content values in data. Do not create a token for a
value used once unless it expresses a product-wide choice or is required for
light/dark or Swift parity. Promote a repeated literal into the token source when a
second real use needs coordinated change. This keeps theme changes centralized
without replacing readable CSS with hundreds of one-off indirections.

The token pipeline is deliberately one-way and narrow:
`design-tokens.json` → one stdlib validation/generation command → committed CSS
variables and, in Phase 5 only, Swift values. The app never edits tokens at runtime.
Generated files carry a source hash and are never hand-edited. Avoid a general token
schema language: support only the concrete scalar types and light/dark mappings used
by Flightdeck, then extend the validator when a real token requires another type.

CSS variables cannot be used directly in media-query conditions. Generate literal
breakpoint rules from the same token source, with responsive variable assignments;
no second hand-maintained breakpoint table. Reject unknown types, invalid units,
missing references and alias cycles; deterministic `--check` verifies generated CSS
matches the token source. See [CSS custom-property constraints](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties).

Light/dark/system is a requirement for the **production HTML app and future Swift
app**, while the saved mockups remain unchanged. Default to the approved dark
appearance; offer system-following and manual light/dark selection in Layout A's
settings. Persist locally. B/C keep their cards-and-X presentation without added
permanent controls. Appearance changes preserve selection, scroll, spotlight and
source data; they do not refresh a producer. Font/scale changes must retain readable
cards and overflow handling rather than force all content into a fixed height.

### Phase 2 — delivery and QA

- [x] Production A/B/C use the same semantic tokens; inline literal colors/fonts/spacing and token fallbacks cannot bypass them. Keep saved mockups/reference checksums unchanged.
- [x] Generate CSS and token reference documentation; validate types/aliases and output freshness. Add one intentional hardcoded card color/font size and observe the token audit fail.
- [ ] Switch palette, UI font, mono font, spacing scale and radius using token edits alone; all three layouts visibly change without component edits.
- [ ] Verify module ownership: views cannot fetch, the client cannot classify QA/progress, and no layout creates a second state store. A deliberate forbidden import must fail the smallest architecture check.
- [ ] Review the token inventory for one-use indirection: every component token either coordinates multiple uses, enables theme/Swift parity, or is removed in favor of a semantic token/readable CSS.
- [ ] Render light and dark at 1920×1080, a typical laptop width and 390×844; verify text contrast (4.5:1 normal, 3:1 large) and visible focus/control boundaries. A deliberately low-contrast pair must fail the contrast check.
- [ ] Check system-theme transitions, manual override persistence, unavailable-font fallback, larger text, reduced motion and both carousel fades. Center cards stay unfaded; selected card remains legible.
- [ ] Commit generated output, token fixtures and actual screenshots/receipts; independent visual approval is required before calling the tokenized design complete.

## Phase 3 — HTML app, navigation and refresh

**Goal:** The operator can keep 6–7 repos visible, remember each agent's next action,
and zoom into issues using real cached inputs without losing context on refresh.

### View behavior

| View | Required behavior |
|---|---|
| A — overview | All 6–7 selected repos on a 1920×1080 second monitor; agents/issue context, physical checkout names/counts, PR QA queue, search/attention filters, source freshness and 6 PM wrap-up. More repos can scroll; do not hide them. |
| B — repo focus | Three tall full cards with neighboring peeks at desktop size; edge-only fades, no extra persistent chrome beyond cards/X. First click spotlights, second click on that repo opens C. |
| C — issues | Same tall cards, one per repo-bound issue with agents, last-hour activity/intent, next action and related PRs. One/two cards are centered; more cards swipe. No invented filler issues. |
| Detail/handoff | Existing A detail concept: named agent/session context and a copyable, editable handoff prompt. Show evidence time and association confidence. No automatic message to an agent. |

Use one route/state owner with explicit `view`, `repoId`, `issueId`, `spotlightId`,
per-view scroll and optional detail state. Browser Back/Forward and Escape use the
same transitions. Escape closes a detail/spotlight first, then C → B → A one level
per press; ignore auto-repeat. X closes a layout (C → B; B → A). Preserve the parent
repo, spotlight and scroll when zooming out. An issue click in C may spotlight;
there is no deeper implemented level. Source refresh and theme change never navigate.

Retain native horizontal scrolling/snap, mouse drag, keyboard arrows/Home/End,
one-finger/trackpad navigation and parallel two-contact translation that yields to
pinch zoom. Dragging must not activate a card. Long card contents scroll vertically.
Test real Mac trackpad and a touch device before claiming hardware support; existing
mockup gesture evidence is browser emulation only.

### Progress, intent and readiness

Meaningful progress is an attested commit, substantive review/check/lifecycle change,
or explicitly completed milestone from an existing source. `updated_at`, a prompt,
a heartbeat, a file read and a dashboard refresh are not progress by themselves.
Preserve `last_prompt_at` for recent intent separately. Repo health must not let a
recently active lane hide an older waiting lane.

Colors are **as-of observation verdicts**, never a claim of continuous surveillance.
For a lane, use the minimum `observed_through` across its required progress sources
as watermark W; never use consumer time or a heartbeat. Require complete relevant
coverage from the known progress anchor through W. For a red verdict, complete
coverage of at least [W−120m, W] plus an anchor at/before W−120m is sufficient.
Calculate age = W − last meaningful progress: green <60m, amber 60–119m, red ≥120m.
Show “as of W” beside the verdict and separately show the live last-progress age.
An observation ending before now does not cover the gap after W. With no known
progress anchor, incomplete coverage, unknown watermark or a future/invalid anchor,
show unknown; a prompt does not establish a progress anchor.

Each connector supplies `fresh_until` from its verified expected maximum active
interval plus a 25% grace (hourly sources: 75 minutes after W). Inactive overnight
hours do not extend that cutoff. If the schedule/maximum lag is unknown, freshness
is unknown and no definitive inactivity color is assigned until an owner-backed
cutoff is configured; CLIO capture cadence cannot substitute for ingest cadence.
At the earliest required-source cutoff, color becomes stale/unknown, retaining the
historical as-of verdict in detail. Reevaluate expiry every UI clock tick even if
GETs stop; never let an old complete snapshot turn newly red as wall time passes.
Partial/missing coverage likewise suppresses a definitive inactivity verdict.
Unknown is never healthy or zero. Prompt-only issues appear as inferred/requested
work, separate from “progress this hour.”

The QA queue is a deterministic cached classification. Evaluate this table top to
bottom; first matching row wins. Closed/merged PRs leave the active queue. All
remaining rows concern open PRs; carry head SHA, evidence times and reasons through
to the UI. “Current head” always means the latest cached head, not a live guarantee.

| Predicate, in precedence order | Category |
|---|---|
| Fresh evidence at cached head explicitly shows merge conflict, required-check failure or effective changes-requested review | Blocked |
| Draft PR | Needs QA — draft; never ready |
| Head missing/mismatched, freshness unknown/expired, incomplete check/review data, unknown required policy, or contradictory unresolved review evidence | Needs QA — verification needed; readiness unknown |
| Known required checks are complete and passing, required review remains pending/requested, no blockers | Review requested |
| Known required QA/check evidence pending or absent | Needs QA |
| Non-draft, mergeability affirmative, all known required checks/QA passed and required approvals satisfied for this head, no unresolved review request/blocker, complete fresh evidence and known requirements | Ready candidate — cached/advisory |
| Anything else | Needs QA — verification needed |

A fresh review request with QA still pending is Needs QA first. A stale old-head
failure is unknown evidence, not a current blocker. Empty checks pass only if an
existing explicit policy proves no checks are required. Likewise “no reviews” is
not approval unless the cached policy explicitly requires none. If required policy
or exact-head approvals are absent from the existing corpus, ready candidates may
remain empty: surface the missing evidence, never invent policy or fetch it from
this consumer. Effective review disposition must be determinable from cached ordered
events; unresolved conflicts go to verification. Source expiry recomputes categories
without another GET. The app neither authorizes nor executes merges; link to the PR
or copy a scoped handoff. Avoid destructive Git/process actions in v1.

6 PM means the operator's local daily wrap-up: QA/merge ready work and carry forward
unfinished lanes. Store instants in UTC and one configured IANA timezone. Show the
countdown before 18:00, “Wrap-up time” afterward, and the next day's countdown only
on local date rollover. Test daylight-saving transitions and sleep/wake. No automatic
merge, cleanup, task closure or loss of carry-forward state at the deadline.

### Refresh contract

| Layer | Initial behavior |
|---|---|
| HTML data reads | GET the Flightdeck snapshot every **150 seconds** while visible; immediate read on launch/foreground and manual “Read latest”. |
| Visual clocks | Recompute from event timestamps every second while visible; no source reads and no clock reset on zoom. |
| Background tab | Pause UI polling; refresh immediately when visible. No promise of browser timer delivery while hidden/asleep. |
| Upstream writers | Connectors report observed schedules where known. Current first-party sources include Git Pulse hourly, GitHub/Focus5 hourly at :45 and CLIO-compatible hook/tailers; Flightdeck does not require or control those schedules. |
| Faster source telemetry | Only a separately scoped configuration/extension to an existing producer after measured need. Never a dashboard-owned collector. |

Freshness labels expose last successful source observation, last consumer read and
last meaningful progress separately. A 150-second UI poll is **not** a 150-second
source-freshness SLA. Source-specific schedules include inactive hours; a stale
source remains visibly stale even when its next run is intentionally tomorrow.

One request in flight, 6-second timeout, no overlapping cycles. A failed request
retains the last valid snapshot and its original timestamps; show failure/time.
After three consecutive failures pause automated retries until foreground/manual
retry; no tight loop. Reject late/older responses using the Phase 1 boot/sequence and request-generation rules. Bound cache size
and lifetime; local display cache contains sanitized summaries, not raw prompts,
tokens or full email/calendar content. Stale cache cannot satisfy current readiness.

### Phase 3 — delivery and QA

- [x] Wire production A/B/C to the shared contract; demo mode remains clearly labeled and never silently substitutes for unavailable live data.
- [ ] Verify full navigation, keyboard/gesture paths, source refresh, theme change and parent scroll restoration; hold Escape and prove it does not skip levels.
- [ ] Verify 59/60 and 119/120 minute boundaries, unrelated prompt arrival, a source heartbeat, partial coverage, clock change, and zoom after aging. Mutate the progress clock to consumer time and observe the test fail.
- [ ] Verify complete-but-stale snapshots, W before the evaluated wall time, no progress anchor and expiry without GETs. Ignoring W must fail a fixture; retain the red receipt.
- [ ] Cover every QA table category, empty checks with/without known policy, draft, missing requirements, changes-requested, wrong-head evidence and source expiry. A mutation that treats missing requirements as passing must fail.
- [ ] Verify 17:59/18:00/18:01, local midnight and DST cases; carry-forward lanes survive restart and date rollover.
- [ ] Verify unavailable/empty/truncated inputs, schema errors, out-of-order responses, three-failure stop, foreground recovery and a retained stale snapshot.
- [ ] Verify handoff copy/context is correctly issue/agent-scoped and treats source text as data; HTML-escape text, allowlist link schemes, never execute embedded prompt instructions.
- [ ] Record browser screenshots and event/traffic traces against final hashes. Every acceptance criterion has a nonempty fixture and a failing control where applicable.

## Phase 4 — Coverage gaps, verification and pilot

**Goal:** A daily-use HTML release meets the operator's requirements with measured
coverage, while source deficiencies are fixed only in their existing owner paths.

### Gap disposition — tell the operator before adding source work

| Gap | Already exists | Smallest allowed response | Release consequence |
|---|---|---|---|
| Missing complete topology | Existing scanner serializes full clones and linked worktrees; current sync feed does not | First locate/validate an existing saved output. If absent, add atomic versioned output persistence to that scanner's existing invocation, and reuse its established publication path if needed. No new discovery engine. | Exact clone/worktree requirement stays incomplete until fresh, complete evidence exists; pilot may display unknown/known-subset counts. |
| Git Pulse Studio coverage | Writer heartbeat lists 49 configured / 3 scanned / 46 missing | Existing producer owner reviews configured paths and deployed version. Fix config/coverage in that lane; dashboard never repairs it. | No definitive inactivity/zero claims for uncovered repos. |
| CLIO-compatible branch/device data | Raw JSONL records them, but producers may omit either field | `clio` parses fields when present and labels unresolved joins; compatible alternative JSONL can replace the installed writer. | Agent/task intent can ship without invented fields; unresolved repo/device joins remain labeled. |
| Prompt-source lag | Existing writer timestamps plus connector read time | Report capture/read lag from records. Adjust an external producer only in its own separately reviewed work. | Clearly distinguish source event age from connector read age. |
| Milestone completeness | Generic completion/continuity outputs exist, issue-linked evidence unproven | Reuse a verified structured existing record; otherwise unknown. Optional additive fields on existing completion writer only after a concrete example is missing. | Do not fabricate completion, liveness or comprehensive agent coverage. |
| Faster Git/GitHub updates | Existing hourly jobs | Measure API/runtime cost and ask for the desired source freshness before proposing a shorter existing schedule. | 150s read cadence remains truthful; no source-cadence guarantee until measured. |

A new collector requires a written delta first: missing field, required user behavior,
all existing writers/adapters checked, why extending each is insufficient, owner,
write set, cadence/cost, rollback and operator decision. **This plan authorizes no
new collector by default.** Unknown data may enable a useful pilot but cannot be
used to mark an unmet mandatory requirement complete.

### Boundaries, observability and rollback

| Change | Undo class / shield | Tripwire and rollback |
|---|---|---|
| New HTML/static route | Easy; opt-in route, existing Pulse/Focus5 unchanged | Any existing route regression: disable Flightdeck route/assets and retain existing views. |
| Flightdeck host/aggregation | Costly; additive loopback app with no source writes | Any write, Git probe or network collection from GET: fail test and stop the host; source corpora remain untouched. |
| Individual connector | Easy; one registry entry and isolated source adapter | Parse, latency or provenance regression: disable that connector; app and other capabilities remain available. |
| Existing scanner output persistence | Costly; write only owner-configured output, atomic replace, last-good retained | Invalid output, overlap or changed repo state: stop that output step; preserve prior snapshot and report coverage. No app-triggered scan. |
| Future Swift client | Easy for initial shell; HTML path retained | Contract/rendering regression: return to browser app; source data remains in place. |

Right-sized diagnostics: the Flightdeck host logger emits a `flightdeck` request ID,
source status/age, row counts, duration and error code. No prompt bodies or secrets.
Client shows data freshness and last successful read; error details are accessible
from A rather than permanent extra controls in B/C. Bounded browser error history
is diagnostic only, not a second activity ledger. Use **debug-mantra** for execution
debugging; cap any investigation/review loop at three rounds, then record the
specific unresolved condition. Do not add an observability platform or 3-Eyes.

Loopback-only serving, same-origin UI/data, explicit Host/origin handling and a
restrictive content-security policy. No wildcard CORS, LAN bind, tunnel or credential
exposure. Read paths are configured allowlisted roots; preferences have a separate
single writer. Existing source contracts/schemas remain owned by their repositories.
XYZ governance applies to the host and connectors; source-owned changes also follow
the producer repository's own gateway/test rules.

### Phase 4 — delivery and QA

- [ ] Execute any required source extensions in separate owner-repo intake/PRs; resolve the gap register with evidence before declaring full inventory/readiness coverage.
- [ ] Run contract, parser, read-only boundary, UI and token checks on final committed code; run applicable owner-repo gates in disposable full clones. Preserve config/remotes/HEAD identity around mutation-heavy suites.
- [ ] Pilot one repo, then the operator's selected 6–7 repos across a full workday including wrap-up and sleep/wake. Measure source coverage/latency, not just HTTP success.
- [ ] Demonstrate the complete user loop: remembered repo → correct agent/issue → source-backed next action → copied handoff → newly observed result without losing other lanes.
- [ ] Proposed targets: cached response p95 under 500ms on the pilot dataset; warm view switch under 100ms; no overlapping reads; complete snapshot no larger than 2 MiB. Measure and report rather than claim these as current results.
- [ ] Confirm no producer runs/schedule changes attributable to UI refresh, no dropped quiet selected repo, no false zero from unavailable sources, and no copied private prompts in committed fixtures.
- [ ] Independent final review, operator visual acceptance in both appearances, committed provenance and ready implementation PRs. Keep the browser release available throughout later Swift work.

## Phase 5 — Future Swift app

**Goal:** Deliver a macOS app that consumes the same verified Flightdeck contract and
uses the same design tokens, without moving collection/ranking into Swift.

Start only after the HTML pilot is accepted. Two explicit milestones avoid calling
a web wrapper a fully native UI conversion:

- [ ] **5A — Swift macOS shell:** use SwiftUI/AppKit window lifecycle with a WKWebView hosting the accepted HTML app. Add app identity, remembered second-monitor window/fullscreen placement, and correct keyboard/trackpad behavior. Keep the loopback origin restriction; do not start collectors when the app launches. This is a native shell around the HTML UI, not a native rewrite of the cards.
- [ ] **5B — Native SwiftUI views, separately approved if needed:** replace A/B/C/detail view rendering one view at a time against the same versioned JSON fixtures, token values and navigation semantics. Use URLSession/Codable and the existing Focus5 client/cache pattern as precedent. Keep canonical correlation, coverage and readiness logic in Flightdeck aggregation; no direct divergent connector, SQLite or Git access. Retain HTML fallback until parity passes.

The existing Focus5 client demonstrates a JSON-only boundary, loopback validation,
6-second requests and last-known cache behavior. Its 90-second polling is precedent,
not an instruction to change Flightdeck's 150-second consumption cadence. Do not
inherit the whole Focus5 refresh path, which also reads notes/reminders and whose
server endpoint may probe Git. Point Swift only to the Flightdeck-owned
`/flightdeck.json`; Swift never loads or selects source connectors directly.

Reuse `design-tokens.json` for Swift colors, typography, spacing, radii, shadows and
motion. Preserve semantic light/dark/system behavior; map system font and layout
units explicitly rather than pretending CSS pixels and native points are identical.
Generate/decode the Swift token representation only when this phase starts. Store
native preferences in UserDefaults behind the same preference semantics; never
write appearance changes into source data. No two active polling owners in shell
mode: the web client owns polling; native rendering later uses the native client.

### Phase 5 — QA checklist

- [ ] Both HTML-shell and any native view consume identical fixture revisions and yield matching repo/issue totals, freshness/unknown state, PR head checks and 6 PM behavior.
- [ ] Light/dark/system, font sizing, accessibility labels/focus, Escape/Back, zoom/scroll restoration, trackpad and real touch requirements are verified on target hardware.
- [ ] Offline startup, server-unavailable state, cache expiry, three-failure pause, wake recovery and unsupported schema behave as in HTML; no silent ingestion startup.
- [ ] Native renderings pass token parity checks; changing one source token updates HTML and generated/native values. Deliberately divergent token value fails the comparison.
- [ ] Independent macOS QA and packaging/signing review precede distribution. HTML remains available as rollback. No data migration or source teardown is required for conversion.

## Completion and deferred work

The grounded plan and Recon Map are complete. HTML v1 is now implemented as the
partial-data pilot described above; unchecked acceptance items remain open and
phase 5 has not started.

HTML release completion requires all mandatory data/UI requirements and phases 1–4
QA, including fresh complete topology if exact counts are claimed. A partial-data
pilot must be labeled as such. Phase 5 is future work with its own approval boundary.
The initial five passive incoming connectors are part of the build; they adapt
existing outputs and do not collect. No new collector is currently justified. No automatic merge/cleanup, agent messaging,
cloud-hosted private feeds, new supervisor, general theme editor or fabricated
agent-liveness detection is included.

Task-priority rationale remains the existing GH-494 design/planning rating
65/45/50/80 with no operator override; this plan is not an incident or a new ranking
system. Frontmatter effort/complexity/risk describe the proposed larger build.
Owner-repo implementation tasks receive their own grounded ratings when opened.

Reference artifacts: [layout guide](../../docs/mockups/flight-dashboard/LAYOUTS.md),
[frozen A](../../docs/mockups/flight-dashboard/layout-a.html),
[B](../../docs/mockups/flight-dashboard/layout-b.html),
[C](../../docs/mockups/flight-dashboard/layout-c.html),
[design provenance](../../docs/mockups/flight-dashboard/provenance.jsonl).
Plan review: [consumer contract approved in round 2](../../relay-system/2026-09-08/gh494-consumer-plan.md), [modularity and tokenization approved by Agy in round 1](../../relay-system/2026-09-08/gh494-modularity-token-qa.md), and the subsequent [source-neutral connector revision approved by Agy in round 1](../../relay-system/2026-09-08/gh494-connector-architecture-qa.md); all review drivers exited 0. This is document review, not runtime verification.

Historical design decisions remain in Git history and the existing review threads;
this document is the single current implementation plan.

## Session visibility mitigation

The verified session context/status gaps and this phase's mitigation are tracked in [GH-494 session context plan](GH-494-SESSION-CONTEXT-PLAN.md), grounded in [the session Recon Map](recon-flightdeck-session-context.md). Implementation is pending plan QA; the existing Rebalance reader already exposes all three reported Claude sessions.
