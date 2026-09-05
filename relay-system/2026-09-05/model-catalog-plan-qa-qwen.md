# RELAY · Sharpen: Model-catalog plan r2 (post-agy fold) — DeepSeek/Qwen sharpening pass
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-05.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(model-catalog-plan-qa-qwen): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/PROJECT.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/Model-catalog/PROJECT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: deepseek   ·   Producer: claude-a
- Started: 2026-09-05
- Definition of Done: the plan revision is sharper than r1 — every folded change from relay r1 is
  correct and complete; remaining gaps are named with concrete fixes; an agent in either consumer
  repo could execute Phases 1–2 as written.

This is relay round 2 for the Model-catalog plan (issue #1). Round 1 (agy) flagged: uniqueness under
punctuation-folding, compile-to-YAML for Phase 1, refusal-vs-passthrough wording, governance,
flagged-row provenance — all folded into this revision. Your job is to SHARPEN, not re-litigate r1.

Adjudicate the revised plan in **.relay-artifacts/PROJECT.md**. Questions (answer each, cite the
plan section):

1. Provenance classification: the plan backfills `verified_on: 2026-09-04` for exactly the seven
   GH-168 Rev 4 pins and leaves all other rows `null`. Is that line drawn honestly? Any row you
   would classify differently?
2. Phase 1's compile-to-YAML shape (generated artifact + CI drift check, resolver untouched): sound,
   or does it create a silent-divergence path the drift check misses?
3. Versioning: what does a BREAKING change mean for a data-only catalog (semantic change to an
   existing row vs additive row vs schema change)? Should consumers pin exact versions and what
   should the sync PR cadence be?
4. Phase 2 for AEGIS-Sleuth: GH-168 says its loader may keep optional provenance columns in the
   JSON and ignore them. Given that, is "build-time sync into command-normalization.json" vs
   "consume the catalog directly" even a real fork — or is one obviously right?
5. Public-repo hazards the plan still misses: license choice for a data repo, contribution flow
   friction, or anything else that bites once this is public?
6. Name any failure mode in the merged data itself: 60 rows from two ecosystems, two ID spaces,
   vendor-default rows (`gpt` → `gpt-5.6-terra`), a flagged stale row. What breaks first in
   production?

FORMAT REQUIREMENT: end your findings with a verdict line EXACTLY of the form `VERDICT: Approved`
or `VERDICT: Changes requested` (plain text, no markdown bold) — the harness validator matches that
literal line and rejects the turn without it.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with concrete fixes, then the
verdict line. Do not edit the artifact.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — deepseek (qwen3.8-max) — round 1 — 2026-09-05

swept file: yes — all 230 lines of `.relay-artifacts/PROJECT.md` (frontmatter → Review record), plus
read-only cross-checks against this XYZ-forge worktree. Containment: no artifact edit, no other file
touched, no git, no gate runs.

Verification basis (read-only, cited where used below):
- XYZ resolver is a 4-tier matcher: "first match in file order wins each tier", tier 4 = "squashed
  substring fallback (either direction contains the other)" — `relay-automation/resolve-model-alias.sh:20-24,117`;
  squash folds punctuation — `:42`.
- 7 shipped rows — `relay-automation/openrouter-model-aliases.yml:15-21`; hand-add flow (line + test
  assertion) — `yml:12-13`.
- `MODEL_ALIASES_FILE` seam real — `resolve-model-alias.sh:32`, `utils/py/profile_resolve.py:252`,
  `test/model-alias.sh:52-99`; assertions are hand-written and drive the real resolver — `test/model-alias.sh:14-38`.
- Not a frozen twin: the 12 paths in `test/gh308-frozen-twin-guard.sh:14-31` do not include
  `resolve-model-alias.sh` — plan:218-220 correct.
- Cache-declined receipt: "alias-resolution caching measured (98ms hit / 279ms miss) and declined" —
  `TESTS-RESULTS/2026-09-01+GH-365/SUMMARY.md:25` (GH-377 step 7, superseding GH-365) — plan:56-58 accurate.
- Sleuth-side facts (53 pins, GH-168 rev4, `command-normalization.json`) are NOT verifiable from this
  repo; reviewed against the plan's own text — that is where Q1's ambiguity lives.

Answers (plan lines cited):

1. **Provenance line.** Honest in spirit (evidence-gated backfill, plan:103) but self-contradictory on
   the referent: Problem §2 (plan:30-31) says all 53 pins were "seeded by an operator-supplied
   Perplexity pass (GH-168 Rev 4)", while plan:103 backfills "only for the seven GH-168 Rev 4 pins".
   The only consistent reading — the 7 with per-pin source URLs recorded — is never stated, so a
   Phase 0 executor cannot classify rows from this doc; and two different "seven"s (XYZ's 7
   OpenRouter rows, plan:23; Sleuth's 7 Rev-4 pins, plan:103) go undisambiguated. No other
   reclassification: `null` for hand-maintained XYZ rows and bulk-seeded Sleuth rows is the honest
   default; flagged→null (plan:103) is right for `unverified-generation` (see F11 for `disputed`). → F1.
2. **Compile-to-YAML.** Sound architecture (Phase 1 §1-3, plan:146-158) — it matches the shipped
   resolver's actual behavior and stays GH-551-clean (renderer can live in the catalog repo; XYZ-side
   checks land in `test/`, out of scope). But it leaves two silent-divergence paths the drift check
   misses: (a) nothing binds the vendored copy to the upstream tag it claims — Governance
   (plan:186-187) calls that drift "a bug in the consumer's sync" yet no check can detect it; (b) row
   ORDER is behaviorally load-bearing (tier 4, file-order-wins, resolver:20,117) but unspecified, so a
   reorder changes resolution without changing any row's content. Plus the Accept line contradicts
   step 3 on "generated assertions". → F2/F3/F4.
3. **Versioning.** The plan is titled "one versioned catalog" but defines no versioning policy
   anywhere — `version: 1.0.0` (plan:69), "records which catalog version" (plan:126),
   "version-bump/sync PR" (plan:191) all presume a bump taxonomy that does not exist. Proposed
   taxonomy (folded into F5): MAJOR = reader-contract change (schema URI/fields, vocabulary removal,
   uniqueness/normalization rules, row removal — anything that makes a previously-resolving alias
   miss); MINOR = any resolution-affecting change (row added; `replace`/`target`/`flags` changed —
   including corrections: a repin changes what an input resolves to); PATCH = provenance-only metadata
   (`source`, `verified_on`), zero resolution change. Consumers pin EXACT versions (not ranges) — the
   two-PR governance already presumes it; say so. Cadence: event-driven sync PRs (consumer needs a
   row change; dispute adjudicated; MAJOR upgrade) + a periodic age audit — Phase 2 §2 (plan:171-172)
   builds the probe for Sleuth; XYZ should get the parity report in CI, else its 7 rows sit
   `verified_on: null` forever with no freshness signal. Tag each release so "resolved by catalog
   vX.Y.Z" names an immutable commit — Decision record (plan:59-60) already demands that property. → F5.
4. **Phase 2 fork.** Not a real fork — build-time sync is obviously right, for the same reason Phase 1
   chose compile-to-YAML: the loader stays untouched (GH-168 already allows optional provenance
   columns it ignores), deploy stays hermetic (one data file, no new runtime read path), and both
   consumers end with the same shape (generated data file + provenance riding along). "Consume the
   catalog directly" = teaching Sleuth's loader a new schema = the live-resolver change Phase 1
   explicitly refused (plan:151-154). Decide it in the plan; the only genuine open question is where
   run-diagnostics reads `verified_on`/`flags` from — the synced file's optional columns or the pinned
   catalog copy. Name one. → F6.
5. **Public hazards.** License is the miss: a data-only repo with no explicit license means neither
   consumer can legally vendor it, and Phase 0 accept only says "no secrets" (plan:141-142). Also no
   evidence bar for external rows, and `source` strings cite issue-internal refs (GH-120, GH-168 rev4;
   plan:77,86) that must be publicly resolvable or self-contained. → F8.
6. **What breaks first in the merged data.** (1) Tier-4 capture: the schema rules (plan:106-113) and
   contract item 5 (plan:128-129, "an exact model ID is never a declared key, so it passes through
   untouched — falls out of the data, no special guard needed") do NOT model the shipped resolver.
   Concrete: squash("glm-5.2")="glm52" ⊆ squash("z-ai/glm-5.2")="zaiglm52", so an exact-ID query
   `z-ai/glm-5.2` IS captured by tier 4 (resolver:42,117-124) — benign today only because
   replace==query; the first pin correction (`glm-5.2` → `z-ai/glm-5.3`) turns every old exact-ID
   query into a silent redirection. (2) Flag semantics: no contract line says what a resolver DOES
   with a flagged row, so Sleuth could refuse `gemini pro` while XYZ resolves it — drift on the one
   row both consumers know is questionable. (3) Vendor-default `gpt` → `gpt-5.6-terra` ages into a
   terminal refusal that reads "unknown model" when the flagship rotates — correct per Non-goals
   (plan:208) but only Sleuth gets the age probe. → F2/F7, F9.

Findings:

- [Should] F1 (Q1) — `verified_on` antecedent ambiguity, 7 vs 53 (plan:30-31 vs plan:103). Fix:
  reword plan:103 to "backfilled `2026-09-04` only for the seven Sleuth-native pins re-verified in
  GH-168 Rev 4 **with per-pin source URLs recorded**; the other 46 bulk-seeded pins and all seven XYZ
  OpenRouter rows stay `null`", and qualify Problem §2 so "seeded by … (GH-168 Rev 4)" no longer
  implies all 53 earned the date. State the rule: `verified_on` requires recorded per-pin evidence;
  a bulk pass without per-pin URLs does not qualify.
- [Should] F2 (Q2/Q6) — schema rules + contract item 5 don't model XYZ's real 4-tier resolver
  (plan:106-113,128-129 vs resolver:20-24,42,117). Fix, three parts: (a) scope the fold-collision
  rule to same-`target` rows — a cross-target fold pair (openrouter `gpt 5.5` vs native `gpt5.5` →
  different IDs) is valid data no consumer ever sees together; a literal reading fails it in CI.
  (b) Add a tier-4 capture CI rule: for any rows A,B where squash(A.match) ⊆ squash(B.replace) and
  A.replace ≠ B.replace → fail (this also makes contract item 5's exact-ID pass-through structural
  instead of data luck — see Q6(1) example); alternatively reword item 5 to admit tier-4 capture and
  require the guard XYZ-side. (c) Declare row order behaviorally load-bearing (file-order-wins,
  resolver:20) and pin the renderer's output order deterministically (e.g., squash-length descending,
  then lexicographic) — this doubles as the byte-equality drift check's determinism prerequisite.
- [Should] F3 (Q2) — "generated assertions" contradicts step 3's tautology ban in two places: Phase 1
  Accept (plan:162-163, "caught by the generated assertions") and Blast radius (plan:200, "the
  generated assertions are strictly more coverage"), while plan:155-158 forbids generated assertions.
  Fix: Accept → "flipping a row in the vendored copy is caught by the CI drift check (render ≠
  committed YAML); the hand-written resolver assertions still drive the real resolver"; Blast radius
  → "the drift check plus retained hand-written assertions are strictly more coverage than today's
  hand-add flow".
- [Should] F4 (Q2/DoD) — Phase 1 step 1's fork is undecided and unnamed: "vendors it or pins the
  catalog" (plan:149-150) has no tie-breaker, no vendored path is named, yet step 4 (plan:159-160)
  reads the vendored copy's `version` field and Governance (plan:186-187) presumes a detectable pin.
  Fix — one decided shape: vendor `catalog.json` byte-identical to tag `vX.Y.Z` at a named path
  (e.g., `relay-automation/model-catalog/catalog.json`), plus a pin record (tag + sha256) that CI
  verifies; vendor the renderer at the same tag; drift check re-renders committed YAML from the
  committed copy. That closes the copy↔upstream edge no current check covers.
- [Should] F5 (Q3) — no versioning policy exists (see answer 3 for the full taxonomy). Fix: add a
  "Versioning & cadence" section: MAJOR/MINOR/PATCH taxonomy as in answer 3; consumers pin exact
  versions; git tag every release; catalog CI rejects a `data/catalog.json` PR that doesn't bump
  `version` + `updated`; sync PRs are event-driven with a periodic `verified_on`-age audit on BOTH
  consumer sides.
- [Should] F6 (Q4) — decide Phase 2 now: build-time sync into `command-normalization.json` carrying
  GH-168's optional provenance columns (`source`, `verified_on`, `flags`) so run-diagnostics
  (plan:171-172) reads them from the synced file; loader untouched; deploy hermetic. Demote "direct
  dependency" to a gated alternative needing a new decision (Phase 3 pattern, plan:177-182). If the
  sync will NOT carry the columns, say diagnostics reads the pinned catalog copy instead — as written
  the data source for the pin audit is unnamed.
- [Should] F7 (Q6) — flag semantics at resolution time are unspecified: the Consumer contract
  (plan:115-129) never says whether a flagged row resolves, warns, or refuses, so the two consumers
  can diverge on `gemini pro` — the exact drift this repo exists to kill. Fix: add contract item 6:
  "flagged rows resolve normally; `flags` are advisory metadata (logged, surfaced in diagnostics),
  never terminal" — or the intended alternative, but stated.
- [Should] F8 (Q5) — public-repo gaps: no license anywhere; Phase 0 accept (plan:141-142) covers
  secrets only. Fix: add License + Contributing section — CC0-1.0 (or MIT) covering data + renderer,
  chosen before going public; evidence bar for external rows (`source` = first-party provider URL +
  access date; `verified_on` is maintainer-set only); audit that every `source` string resolves
  publicly (no private-repo issue refs).
- [Nit] F9 (Q6) — contract item 1 (plan:117-119) should require case-folded lookup input: `match` is
  lower-cased (plan:98) but Phase 2's Accept resolves "ChatGPT" (plan:174) — make consumer-side
  case-folding explicit so the accept doesn't depend on unstated loader behavior.
- [Nit] F10 — Phase 0 dedupe wording: "dedupe on `(match, target)`" (plan:136) vs "minus exact
  duplicates" (plan:141). Align on `(match, target)`; add the conflict rule (same key from both
  sources, different `replace` → `flags: ["disputed"]` per Governance, plan:188-190); record the
  final row count in the PR so the 7+53 reconciliation is checkable.
- [Nit] F11 — flagged ⇒ `verified_on: null` (plan:103) is right for `unverified-generation` but
  erases honest history for `disputed`: a pin verified 2026-09-04 and disputed 2026-09-10 loses its
  date. Scope the null-rule to `unverified-generation`, or keep it and note the dispute date lives in
  the PR/commit, not the row.
- [Nit] F12 — r1's raw block is cited as uncommitted (plan:224-226). Under XYZ's own evidence rule
  (AGENTS.md, GH-430: "a path you merely ran and can no longer show counts as no claim at all"),
  commit the agy relay file in XYZ-forge or inline the raw r1 findings in the Review record.
- [Pass] F13 — all five r1 folds are present and faithful: uniqueness-under-normalization with the
  same-`replace` carve-out (plan:106-113 — and the `gpt 5.5`/`gpt5.5` example is technically correct
  against the real squash tier, resolver:42 — both fold to `gpt55`); compile-to-YAML + resolver
  untouched (plan:146-158); miss→pass-through→validate→refuse (plan:120-123); governance + two-PR
  cost (plan:184-192); flagged→null (plan:103).
- [Pass] F14 — the plan's XYZ-side factual claims verify against this worktree: 7 rows
  (yml:15-21); hand-add flow (yml:12-13); seam real (resolver:32; profile_resolve.py:252;
  model-alias.sh:52-99); resolver not a frozen twin (guard:14-31); cache measured-and-declined
  (SUMMARY.md:25); tests hand-written driving the real resolver (model-alias.sh:14-38).
- [Pass] F15 — whole-file sweep found no further pre-existing defects: frontmatter coherent
  (`phases: 4` = Phase 0-3); provider vocabulary incl. `stealth` (plan:101) matches a shipped row
  (yml:21); Non-goals/Blast-radius/Review-record sections internally consistent apart from the
  findings above. Sleuth-side claims remain unverifiable from this repo and were reviewed against the
  plan's text only — stated explicitly per GH-268.

No Blockers: the architecture (data-only repo, compile-to-legacy-shape, untouched resolvers, pinned
provenance) is sound and every gap above is a spec/wording fix. But F1-F8 must land before an
executor can run Phases 0-2 "as written" (DoD) — most sharply F2, whose contract item 5 is
contradicted by the shipped resolver it binds.

Handoff: handing off to Producer (claude-a) — go to the other window and say "take your turn":
log a disposition for every open finding (Implemented / Modified / Declined + why), edit
`.relay-artifacts/PROJECT.md`, bump ROUND, and flip NEXT back to Reviewer.

VERDICT: Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
