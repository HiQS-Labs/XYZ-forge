---
gh_issue: 494
source: https://github.com/HiQS-Labs/XYZ-forge/issues/494
title: Flightdeck — HTML consumer app and future Swift plan
status: Plan in review — implementation not started
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
| Layouts A/B/C and Escape navigation saved; existing Rebalance, Git Pulse, CLIO and Swift consumer paths traced. | Review this plan; then authorize implementation in fresh owner-repo clones. No collectors or production app code are built by this planning task. |

## Table of contents

1. [Phase 1 — Existing data contract and passive endpoint](#phase-1--existing-data-contract-and-passive-endpoint)
2. [Phase 2 — Fully tokenized production design](#phase-2--fully-tokenized-production-design)
3. [Phase 3 — HTML app, navigation and refresh](#phase-3--html-app-navigation-and-refresh)
4. [Phase 4 — Coverage gaps, verification and pilot](#phase-4--coverage-gaps-verification-and-pilot)
5. [Phase 5 — Future Swift app](#phase-5--future-swift-app)
6. [Completion and deferred work](#completion-and-deferred-work)

## Phase 1 — Existing data contract and passive endpoint

**Goal:** One read-only, source-attributed response supplies the dashboard using
existing Rebalance, Git Pulse and CLIO outputs. A UI refresh never collects data.

### Decision and ownership

The dashboard is a **consumer**. Rebalance remains the corpus/query owner, Git Pulse
remains the Git observation/sync writer, CLIO remains the prompt writer, and
Daily/Shutdown remain continuity producers. No new GitHub connector, Git scanner,
prompt tailer, database, scheduler, supervisor or daemon is justified by this recon.

Use the existing Rebalance Pulse host on loopback `:8767`. Add `/flightdeck/` and a
shared `GET /flightdeck.json` projection there, rather than a second web server.
The production feature belongs in **Rebalance** because its existing read layer,
host and source contracts live there. XYZ GH-494 remains the design/plan reference;
create linked implementation intake in Rebalance under its own governance when
execution starts. Other agents' current checkouts and running jobs remain untouched.

The existing mockups are reference artifacts. All three stay byte-identical during
this plan and production build; import the approved design once into production
assets, with provenance, rather than maintaining two production copies. Frozen
Layout A is additionally pinned by `layout-a.sha256`.

Grounding: [Recon Map](recon-flightdeck-consumer.md). `RB:` citations in that map
refer to Rebalance commit `0bffc4d`; current mockup baseline is XYZ `c7e4bce`.
Re-anchor source paths/HEAD at execution. This is the consumer-first replacement for
the earlier conversational suggestion to build a new local collector.

### Data reuse and actual gaps

| Dashboard requirement | Existing source to consume | What is actually missing / permitted work |
|---|---|---|
| Repo/project names and aliases | Rebalance `registry.get_projects(conn=...)` and existing mirror resolution | New projection composition only; never equate two repos just by basename. |
| Issue titles/state, open PRs, checks and links | Existing `github_items`, `github_check_runs`, `github_links` and read helpers | Expose omitted fetched times/full SHAs and bounded pagination/completeness. No new GitHub fetching. |
| Last-hour commits | Existing cached commit queries plus synced Git Pulse TSV | Adapt/promote existing parser if needed; retain source/device and avoid duplicate commit counting. |
| Names of agents, requested task and recent attention | Existing CLIO JSONL writer and Rebalance `clio_prompts` projection | Consume cached projection. Branch/machine already captured but dropped by ingest: additive projection/backfill only if needed for joins. No new prompt writer/tailer. |
| Next actions and handoff context | Persisted ranked next actions, CLIO intent, existing continuity notes | Passive cache access and deterministic presentation. No model call or reranking on refresh. |
| Full clone/worktree names and counts | Existing cached RepoSignals plus existing Daily/Shutdown scanner output when persisted | **Current synced feed is insufficient.** If no configured current output is found, persist/export the existing scanner result through its owner. Do not write another scanner. |
| Meaningful agent milestones | Existing structured completion evidence, if a repo/issue join can be verified | Completeness not established. Display unknown until an existing writer exposes attested completion; prompts do not substitute. |
| Producer freshness and coverage | Git Pulse device YAML, corpus fetched times/coverage, CLIO synced time, cached scan probed time | Expose coverage counts currently omitted by health reader. A fresh heartbeat is not complete coverage. |
| 6 PM wrap-up | Existing cached PR/issue/action data plus operator timezone | New display and selection logic only; no merge, QA runner, cleanup or scheduler. |

CLIO's concrete path is the installed shared capture hook/tailers documented by
`RB:utils/CLIO/INSTALL.md`, with output `~/.claude/prompt-log.jsonl`, then existing
`ingest/clio.py` → `clio_prompts`. Its Markdown export is a presentation artifact.
The Git Pulse sync folder's `CLIO/README.md` describes an optional daily synthesis;
it does **not** demonstrate that raw prompts are synced there. V1 prompt coverage
is device-local unless existing cross-device publication is independently verified.

### New code budget and read boundary

Proposed owner-repo files are **new paths**, not claims they already exist:
`src/rebalance/lib/flightdeck.py` for the bounded projection,
`web/flightdeck/` for production assets and tokens, and focused owner-repo tests.
Use the installed Python/HTTP stack and browser JavaScript; no UI framework,
standalone Node server, message bus, plugin framework or second SQLite store.

Reuse `db_connection_readonly` (`mode=ro`) at the boundary. Extend existing query
helpers with optional supplied read-only connections/additive fields where needed;
preserve their canonical mirror/dedup behavior. One projection entry point composes
those helpers; do not create a parallel identity or ranking implementation.

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
| Snapshot | `generated_at`, `snapshot_id`, `sources[]`, `repos[]`, `coverage`, `truncated`, `next_cursor`. Generation means projection time, not new work. |
| Source | Stable source/device ID, latest successful observation/ingest time, expected producer schedule when known, `coverage=complete/partial/unknown`, `availability=ok/stale/unavailable`, errors without private content. |
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
Proposed caps: 100 repos, 2,000 issues/PRs and 5,000 events per response, 2 MiB response,
explicit pagination/truncation. Fetch all pages needed for a displayed exact total
or show partial. Never report zero from an unqueried/failed/truncated source.

### Phase 1 — delivery and QA

- [ ] Commit the contract, synthetic fixtures and source mapping; every requested field is populated, nullable with a reason, or listed in the gap register below.
- [ ] Add the shared projection and explicit route on the existing host; a configured empty/missing corpus returns an honest state without source bootstrap.
- [ ] Prove passive reads: source/DB/sync files unchanged; spy collectors, Git subprocesses, network clients and ingestion functions and assert zero calls during repeated GETs. Negative control deliberately calls a forbidden path and fails the guard.
- [ ] Test basename collisions, mirror aliases, duplicate SHAs, multiple agents per issue, unlinked PRs, stale checks on another head, and more than 10 PRs. Assert nonempty inputs before checking totals.
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

- [ ] Production A/B/C use the same semantic tokens; inline literal colors/fonts/spacing and token fallbacks cannot bypass them. Keep saved mockups/reference checksums unchanged.
- [ ] Generate CSS and token reference documentation; validate types/aliases and output freshness. Add one intentional hardcoded card color/font size and observe the token audit fail.
- [ ] Switch palette, UI font, mono font, spacing scale and radius using token edits alone; all three layouts visibly change without component edits.
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

With sufficient relevant coverage: green <60m, amber 60–119m, red ≥120m without
meaningful progress. Partial/missing coverage suppresses a definitive inactivity
verdict and adds an explicit coverage state; preserve any known timestamp as
last-known evidence. Unknown is never equivalent to healthy or zero. Prompt-only
issues appear as inferred/requested work, separate from “progress this hour.”

The QA queue distinguishes cached needs-QA, review requested, blocked and ready
candidates. Exact current head/check evidence, source age and missing coverage must
be visible; the app does not authorize or execute merges. Link to the existing PR
or copy a scoped handoff for the agent. Avoid destructive Git/process actions in v1.

6 PM means the operator's local daily wrap-up: QA/merge ready work and carry forward
unfinished lanes. Store instants in UTC and one configured IANA timezone. Show the
countdown before 18:00, “Wrap-up time” afterward, and the next day's countdown only
on local date rollover. Test daylight-saving transitions and sleep/wake. No automatic
merge, cleanup, task closure or loss of carry-forward state at the deadline.

### Refresh contract

| Layer | Initial behavior |
|---|---|
| HTML data reads | GET existing-output projection every **150 seconds** while visible; immediate read on launch/foreground and manual “Read latest”. |
| Visual clocks | Recompute from event timestamps every second while visible; no source reads and no clock reset on zoom. |
| Background tab | Pause UI polling; refresh immediately when visible. No promise of browser timer delivery while hidden/asleep. |
| Upstream writers | Keep installed schedules: Git Pulse hourly; GitHub/Focus5 hourly at :45; CLIO hook/60s tailers; Markdown exporter 300s. Rebalance CLIO ingest freshness is separately measured. |
| Faster source telemetry | Only a separately scoped configuration/extension to an existing producer after measured need. Never a dashboard-owned collector. |

Freshness labels expose last successful source observation, last consumer read and
last meaningful progress separately. A 150-second UI poll is **not** a 150-second
source-freshness SLA. Source-specific schedules include inactive hours; a stale
source remains visibly stale even when its next run is intentionally tomorrow.

One request in flight, 6-second timeout, no overlapping cycles. A failed request
retains the last valid snapshot and its original timestamps; show failure/time.
After three consecutive failures pause automated retries until foreground/manual
retry; no tight loop. Reject out-of-order/older snapshot revisions. Bound cache size
and lifetime; local display cache contains sanitized summaries, not raw prompts,
tokens or full email/calendar content. Stale cache cannot satisfy current readiness.

### Phase 3 — delivery and QA

- [ ] Wire production A/B/C to the shared contract; demo mode remains clearly labeled and never silently substitutes for unavailable live data.
- [ ] Verify full navigation, keyboard/gesture paths, source refresh, theme change and parent scroll restoration; hold Escape and prove it does not skip levels.
- [ ] Verify 59/60 and 119/120 minute boundaries, unrelated prompt arrival, a source heartbeat, partial coverage, clock change, and zoom after aging. Mutate the progress clock to consumer time and observe the test fail.
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
| CLIO branch/device loss | Raw JSONL already records them; DB projection drops them | Additive existing CLIO migration and idempotent backfill from existing JSONL, if required for reliable joins. Use existing ingest orchestration. | Agent/task intent can ship without invented fields; unresolved repo/device joins remain labeled. |
| CLIO ingest lag | Existing writer and ingest adapter | Measure active DB lag; adjust existing ingest recipe/schedule only as separately reviewed source work if freshness target requires it. | Clearly distinguish capture age from cached projection age. |
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
| Shared read helper/projection | Costly; additive fields and supplied read-only connection | Any write, Git probe, network collection or schema assurance from GET: fail test and disable new endpoint. Revert helper extension; corpus untouched. |
| Existing CLIO additive migration | Costly; owner-repo migration, backup and idempotent backfill | Count/provenance loss: stop ingestion extension, restore prior reader; leave harmless added columns rather than destructive rollback. |
| Existing scanner output persistence | Costly; write only owner-configured output, atomic replace, last-good retained | Invalid output, overlap or changed repo state: stop that output step; preserve prior snapshot and report coverage. No app-triggered scan. |
| Future Swift client | Easy for initial shell; HTML path retained | Contract/rendering regression: return to browser app; source data remains in place. |

Right-sized diagnostics: existing server logger emits a `flightdeck` request ID,
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
Rebalance AGENTS already requires DRY/SOLID; follow its existing gateway/test rules.

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
- [ ] **5B — Native SwiftUI views, separately approved if needed:** replace A/B/C/detail view rendering one view at a time against the same versioned JSON fixtures, token values and navigation semantics. Use URLSession/Codable and the existing Focus5 client/cache pattern as precedent. Keep canonical correlation, coverage and readiness logic in Rebalance; no direct divergent SQLite or Git access. Retain HTML fallback until parity passes.

The existing Focus5 client demonstrates a JSON-only boundary, loopback validation,
6-second requests and last-known cache behavior. Its 90-second polling is precedent,
not an instruction to change Flightdeck's 150-second consumption cadence. Do not
inherit the whole Focus5 refresh path, which also reads notes/reminders and whose
server endpoint may probe Git. Point Swift to `/flightdeck.json` only.

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

This planning deliverable is complete when the grounded plan and Recon Map are
reviewed, committed and pushed. **That does not mark phases 1–5 implemented.**
The earlier hold on writing the final plan is superseded by the operator's explicit
request for this HTML-first plan; runtime implementation still awaits its own start.

HTML release completion requires all mandatory data/UI requirements and phases 1–4
QA, including fresh complete topology if exact counts are claimed. A partial-data
pilot must be labeled as such. Phase 5 is future work with its own approval boundary.
No new collector is currently justified. No automatic merge/cleanup, agent messaging,
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
Historical design decisions remain in Git history and the existing review threads;
this document is the single current implementation plan.
