# RELAY · GH-32 RELEASES app PRD review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-18.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 4 / 4

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
6. **Commit only the relay file** (`relay(gh32-releases-app-prd-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md** — the PRD for the SQLite-backed RELEASES app (read it in full; also read GH-28's capture doc PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md for the predecessor context, and utils/pdda/pdda.sh check_releases() + PROJECT/PDDA.md's "RELEASES.md — release ledger" section for the consumers the PRD claims stay unchanged).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-08-18
- Definition of Done — grade the PRD against these five questions:
  1. **Schema soundness**: do the tables/constraints actually enforce the two SOPs and the GH-28 thresholds, or are there writable states that bypass them? Is the global_id design (identity-not-hash, additive-only migrations, no EAV) the right corner-avoidance for a future PDDA home?
  2. **Phase 0 transition realism**: is lenient-mode (warn-and-write on legacy debt, refuse new structural corruption) drawn at the right line? Is the 2-week dogfood exit gate meaningful or theater? Does side-by-side generation (RELEASES.generated.md, no overwrite) actually protect the current consumers?
  3. **Consumer-compatibility claim**: the PRD claims pdda.sh releases, ballast-release.sh Half A, and /releases keep working with zero changes because the generator emits the existing block format. Verify against the actual parser (pdda-lib.sh's field parser) — is byte-stable regeneration of the CURRENT file's blocks actually achievable given multi-paragraph Description continuations (Sundown block), or does the round-trip claim need qualification?
  4. **Git story for the committed DB**: does the DB + releases.sql dump + consistency-check design actually survive concurrent sessions committing on one branch (this repo routinely has 2-3 live sessions), or is there a merge/race hole?
  5. **Scope discipline**: anything in v1 that should be cut (YAGNI), anything deferred that v1 secretly depends on?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

Pre-existing defects found: yes — the findings below cover the whole PRD, not only its latest edits.

Verdict: Changes requested

- **[Blocker] Schema soundness — the two SOPs and the rescope trail are not schema-enforced.**
  `TEXT NOT NULL` still admits `''`, arbitrary text, and unregistered `TMP-*` values; `temp_ids` is not
  referenced by either tracking column; SQLite foreign keys are ineffective unless every connection
  enables them; enum `CHECK`s constrain only the current value, not transitions; and
  `manifest_items.state_changed` is one overwriteable cell with no cut-reason column while rows remain
  deletable (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:87-129,166-169`). **Concrete fix:** model a
  normalized issue reference (real URL XOR registered temp ID) and point releases/marathons/items to it
  with FKs; require and self-check `PRAGMA foreign_keys=ON`; add transition/delete triggers plus an
  append-only manifest-state event table containing timestamp and reason; add non-empty/date/format
  constraints, or narrow every “schema-enforced” claim to “CLI-enforced” and make the consistency gate
  detect direct-write violations.

- **[Blocker] Global identity is correctly identity-not-hash, but eight hex digits are not globally
  safe across independent databases.** DB-local `UNIQUE` cannot detect the same 32-bit ID generated in
  two repos, yet the UI and future links treat it as cross-repo identity
  (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:65-72,80-121`). **Concrete fix:** keep integer PKs
  internal, use a 128-bit UUID/ULID-style immutable global ID with prefix/shape constraints, address
  rows externally by that ID (not `--id N`), and make aggregation fail loudly on any duplicate. **[Pass]**
  The identity-not-content-hash choice and additive/no-EAV direction are sound
  (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:65-72,137-151`).

- **[Blocker] Phase 0 cannot implement the stated lenient boundary or prove its exit gate.** The schema
  has no per-repo enforcement setting; `tracking_issue_url NOT NULL` conflicts with importing missing
  legacy tracking issues; lenient mode says both “warn and write” new threshold violations and
  “legacy debt, not new corruption”; and two quiet weeks do not prove the CLI was the sole writer
  (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:96-111,213-227,240-244`). **Concrete fix:** add the
  settings schema, a one-shot import path that records each grandfathered violation and its disposition,
  keep ordinary post-import writes strict on structural rules, and add an append-only operation/audit
  receipt plus a minimum exercised-operation matrix to the exit gate; zero-change days must not count as
  dogfood evidence.

- **[Blocker] The zero-change consumer and current-file round-trip claims are false with this schema.**
  The DB has nowhere to retain `Iterations`, the three QA fields, `Manifest-Members`, `Shipped`, or
  arbitrary continuation/history lines, while the parser consumes Iterations/QA positionally
  (`utils/pdda/pdda-lib.sh:454-499`), Ballast Half A requires `Manifest-Members`
  (`test/ballast-release.sh:165-187`), and Sundown contains two continuation paragraphs
  (`RELEASES.md:198-200`). Requiring full issue URLs also cannot import today's bare-number manifests
  “as-is” (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:114-121,171-179,220-226`). **Concrete fix:**
  publish an explicit lossless import/render mapping for every current label and unknown continuation,
  preserve ordered legacy lines until each is dispositioned, and add a byte-for-byte fixture for the
  current 207-line ledger plus focused assertions for `pdda releases`, `releases-current`, Ballast Half
  A, and `/releases`; otherwise qualify “round-trip” as a documented normalized migration and drop the
  zero-change/byte-stable-current-file claim.

- **[Blocker] The committed-DB Git story has an unclosed race and unclear authority.** A SQLite
  transaction serializes the DB only; it does not atomically cover DB + SQL dump + generated Markdown,
  so two sessions can overwrite one another's dump or commit another session's state. The PRD also
  calls the DB source of truth but makes the dump authoritative during merges, and integer PKs make
  independently edited dumps collision-prone (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:39-47,
  155-163`). **Concrete fix:** specify one repo-scoped writer claim/lock spanning transaction, dump,
  generation, and atomic replacements; use optimistic preimage checks; reject leftover WAL/journal or
  mismatched artifacts; omit device-local `local_path` from committed data; and define a tested
  conflict procedure in which a global-ID-keyed logical dump is merged and the DB is rebuilt atomically
  with a recoverable backup.

- **[Should] V1 carries one speculative subsystem and one hidden Phase-4 dependency.** Marathons do
  not run from this system until v3, yet v1 creates their table/SOP with no marathon CRUD acceptance;
  meanwhile the UI criterion requires at least two registered repo DBs although sibling-repo rollout
  is Phase 4 and excluded from v1 (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:87-94,188-202,
  228-253`). **Concrete fix:** defer the marathon table/SOP to the promised additive migration unless
  a real v1 reader/writer is named, and make the two-repo UI proof use two disposable registered fixture
  repos (or explicitly admit one sibling pilot into v1).

Handing off to Producer — go to the Producer window and say “take your turn”; address every finding
with an Implemented / Modified / Declined disposition before revising the PRD.

### Producer · Round 1 dispositions

swept file: yes

All six findings dispositioned; the PRD (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md`) is
substantially revised — re-review the whole document, not a diff.

- **[Blocker] schema enforcement** — **Implemented.** Normalized `issue_refs` table (URL XOR temp-ID
  via CHECK, both shape-constrained by GLOB), all three consumers now FK it; `temp_ids` table
  eliminated (folded into `issue_refs`); `PRAGMA foreign_keys=ON` asserted per connection by the CLI;
  non-empty/date/format CHECKs added; the overwriteable `state_changed` cell replaced by an
  append-only `manifest_state_events` table where a cut REQUIRES a reason; and every enforcement
  claim in the doc is now split schema-enforced vs CLI-enforced, with bypass DETECTION (op_receipts
  vs change diff) explicitly claimed instead of prevention.
- **[Blocker] global-ID width** — **Implemented.** 128-bit ULID with type prefix; integer PKs
  internal-only; external addressing via `--gid`; aggregator fails loudly on cross-DB duplicates
  (also now a named negative control in acceptance).
- **[Blocker] Phase 0 contradictions** — **Implemented.** `settings` table added (per-repo
  enforcement mode); one-shot `releases import` records every grandfathered violation with required
  disposition; the lenient/strict rule table now states structural rules refuse in BOTH modes
  (lenient tolerates imported legacy debt, never new corruption — the contradiction is gone);
  `op_receipts` append-only log added; exit gate rewritten: sole-writer proof via receipts + an
  exercised-operation matrix, zero-change days count for nothing.
- **[Blocker] round-trip claim false** — **Implemented (claim qualified + mechanism added).**
  `legacy_lines` table preserves unmapped/continuation lines verbatim in order; QA fields became real
  columns; `Manifest-Members:` is generated from `manifest_items`; byte-for-byte fixture on the
  current 207-line ledger is an acceptance criterion with focused assertions for pdda releases,
  releases-current, Ballast Half A, and /releases; bare-number sibling manifests import as
  legacy_lines (rebalanceOS's retired-tracker numbers are the reason they can't auto-convert).
- **[Blocker] git story race** — **Implemented.** Repo-scoped writer lock (`.git/releases-app.lock`,
  existing driver-lock idiom) spanning txn→dump→generate→atomic renames; optimistic preimage check on
  the dump hash; stale WAL/journal refusal; conflict procedure = merge the global-ID-keyed logical
  dump, rebuild DB atomically with .bak; `local_path` removed from committed data (UI resolves paths
  from the per-device hq registry); DB-vs-dump authority split stated precisely (DB at runtime, dump
  at merge boundaries).
- **[Should] speculative marathons table + hidden two-repo dependency** — **Modified.** Marathons
  table STAYS (the tracking-issue SOP is an explicit operator decision, and deferring the table would
  orphan `releases.marathon_id`) but gains v1 CRUD (`releases marathon add|list`) and acceptance
  coverage, addressing the writeless-table objection; the Phase-3 two-repo UI proof now uses two
  disposable fixture repos, removing the Phase-4 dependency.
- **New since your review (operator, same day):** a light-touch duplication guard section — exact
  dupes structurally refused; shared-manifest-issue across non-cut releases and cross-repo codename
  collisions warn-only in both modes.

Verdict request: re-review the revised PRD.

Handing off to Reviewer — take your turn.

### Reviewer · Round 2

swept file: yes

Pre-existing defects found: yes — this was a whole-PRD and named-consumer sweep, not a diff review.

Verdict: Changes requested

- **[Blocker] Phase 0 still cannot import the current ledger under the proposed schema.** Every current
  block lacks the new `Tracking Issue:` field, while `tracking_ref_id` is non-null; the documented
  ledger contract makes all fields except `Release:` optional, but the DB also requires `status` and
  `description`. Lenient mode refuses structural violations and the only grandfather mechanism records
  debt rather than providing schema-valid values (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:66-72,
  123-140,247-254,298-306`; `PROJECT/PDDA.md:657-675`; `PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:97-100`).
  **Concrete fix:** define a pre-import mapping/disposition stage that supplies a real tracking URL (or
  an explicitly migration-scoped placeholder distinct from the GitHub-down fallback) for every block,
  and define lossless presence/default semantics for every newly required field; alternatively use a
  nullable grandfather table/column that ordinary writes cannot create and require its elimination
  before the strict flip.

- **[Blocker] Several stated schema guarantees are still only comments or CLI convention.** Prefix-only
  checks such as `global_id GLOB 'rel-*'` accept any length and alphabet, despite the claimed 26-character
  ULID shape; `manifest_state_events` has no enum/transition or update/delete guard; a direct update can
  set an item to `cut` without any reason event; and `op_receipts(op,target_gid,at)` contains no parent or
  resulting state digest with which `check` could detect a receipt-less mutation
  (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:76-83,98-176,241-253`). **Concrete fix:** add exact
  length/alphabet checks for every typed GID, enforce or explicitly classify event append-only/transition
  rules as CLI-only, couple item state and its event in one transaction, and record a transaction ID plus
  canonical before/after state digests (or narrow bypass detection to what can actually be proven).

- **[Blocker] Byte-stable regeneration and zero-change consumer compatibility remain impossible as
  specified.** `legacy_lines` is release-scoped, so it cannot retain this file's 86-line preamble; mapped
  fields retain neither source position nor lexical form; and Phase 0 adds a generated header while also
  requiring byte equality (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:162-169,255-274,320-323`;
  `RELEASES.md:1-87`). More importantly, `/releases` is not only a reader: its clean/plan/anchor/publish
  routes directly patch `RELEASES.md`, which conflicts with CLI-only writes and a generated read-only file
  (`skills/releases/SKILL.md:100-184`). **Concrete fix:** preserve document-level preamble/separators and
  ordered raw spellings (or qualify the fixture as a defined normalized payload and test that); reconcile
  the header with that definition; and change the claim to read-consumer compatibility while explicitly
  migrating every `/releases` mutation route to the new CLI before Phase 2.

- **[Blocker] The Git story still lacks a crash-safe, observable multi-artifact commit.** In a linked
  worktree `.git` is a file, so the literal `.git/releases-app.lock` path is invalid. Even where the lock
  resolves, readers take no lock and can observe the DB after COMMIT but before the dump/Markdown renames;
  a crash in that interval leaves a mismatch whose only documented rebuild direction (dump to DB) can
  discard the committed operation. The claimed global-ID-only merge also omits a logical-dump encoding for
  event, receipt, migration, setting, and legacy-line rows that have integer identities/FKs
  (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:46-55,153-176,195-213`). **Concrete fix:** resolve and
  validate the git common-dir for the lock; make readers lock/retry against a committed generation marker;
  stage all outputs with a recovery journal and specify recovery at every rename boundary; define the
  canonical dump grammar with no unstable integer references; and add crash-at-each-boundary plus
  concurrent-branch-merge negative controls.

- **[Should] The dogfood exit lost its duration and makes rare operations performative.** “Across the
  window” names no minimum window, while requiring every operation on real work encourages an artificial
  `ship` and a temp-ref `reconcile` even if no release ships and GitHub never goes down
  (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:298-309`). **Concrete fix:** restore an explicit minimum
  (the proposed two weeks), require a minimum count of accepted real write transactions from at least two
  sessions plus a witnessed contention case, and exercise rare/destructive operations in disposable
  fixture DBs rather than manufacturing them in the real ledger.

- **[Pass] Scope discipline is now explicit:** Phase 3 uses two disposable fixture repos, sibling rollout
  remains Phase 4, and the high-blast-radius driver integration is deferred to v3
  (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:276-294,312-316`). The identity-not-hash and additive/no-EAV
  direction also remains sound once the GID checks are made real (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:76-83,215-225`).

Handing off to Producer — go to the Producer window and say “take your turn”; disposition every Round 2
finding before revising the PRD.

### Producer · Round 2 dispositions

swept file: yes

All five R2 findings dispositioned; PRD revised again — the affected sections are SOPs (new item 4),
Schema (issue_refs, triggers, doc_lines, op_receipts digest chain, GID shape note), Git story
(rewritten, 7 points), Generator contract (rewritten), and the Phase 0 exit gate.

- **[Blocker] import cannot satisfy the schema** — **Implemented.** New `MIG-XXXXXX` import-only
  placeholder refs (distinct prefix from the GitHub-down `TMP-` fallback; ordinary writes refuse the
  shape; Phase 2 requires zero surviving MIG refs). Import supplies recorded defaults for
  newly-required fields legacy blocks omit — every default is a grandfather-ledger entry.
- **[Blocker] guarantees only comments/convention** — **Implemented.** Exact-shape GID checks
  (prefix + exactly 26 Crockford base32 chars, schema-refused); append-only enforced by
  RAISE(ABORT) triggers on manifest_state_events AND op_receipts; from/to state enums CHECKed;
  transition legality + state/event coupling explicitly classified CLI-enforced (one transaction);
  op_receipts gained txn_id + before/after canonical-dump digests so `check` proves receipt-less
  mutation by digest-chain mismatch — detection claims now match what is actually provable.
- **[Blocker] byte-stability + /releases writes** — **Implemented.** Document-level `doc_lines`
  table holds the 86-line preamble and separators; import records per-block field order and the
  generator replays it; NO header during Phase 0 (fixture is exact byte equality), header added and
  fixture re-pinned at the Phase 2 flip; compatibility claim narrowed to READ-consumer only; a new
  Phase 2 entry gate migrates every /releases mutating route (clean/plan/anchor/publish) to call
  this CLI before the file flips.
- **[Blocker] git story gaps** — **Implemented.** Lock path resolved via the git common-dir using
  the existing GH-448 resolver idiom (linked-worktree safe); reader consistency via a generation
  marker stamped into DB+dump+file with retry-then-report semantics; staged temp-name writes with a
  crash-recovery journal defined at every rename boundary (committed DB txns never discarded by
  recovery); canonical dump grammar specified for every non-GID table (parent GID + stable ordinal,
  txn_id, natural keys — integer PKs never in the dump); crash-at-each-boundary and
  concurrent-branch-merge negative controls added to acceptance.
- **[Should] exit-gate duration/performativity** — **Implemented.** Explicit 2-week minimum
  restored; >=10 accepted real write transactions from >=2 distinct sessions; one witnessed
  lock-contention case; everyday ops exercised on real work while rare/destructive ops (ship,
  reconcile, --rebuild) run in disposable fixture DBs — nothing manufactured in the real ledger.

Verdict request: re-review. Round 3 of 4 — if findings remain that are genuinely design-level (not
implementation detail a build phase would settle), grade them; implementation-detail nits can be
recorded as notes for the build phase rather than blocking the PRD.

Handing off to Reviewer — take your turn.

### Reviewer · Round 3

swept file: yes

Pre-existing defects found: yes — this was another whole-PRD, current-ledger, predecessor-contract,
and named-consumer sweep; the findings below are design-level gaps that remain after the R2 revision.

Verdict: Changes requested

- **[Blocker] The schema still has no representation for two kinds of state the import and byte-stable
  generator require.** The PRD requires a grandfather ledger containing every inferred default and its
  disposition, but no such table exists in the complete v1 schema. It also says import records mapped
  fields' presence, order, and lexical spelling, yet `doc_lines` stores only release-less segments and
  `legacy_lines` only unmapped release lines; there is no per-release mapped-field layout/presence table
  (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:73-82,95-209,313-319`). This is observable in the
  current input: `Status: Shipped` must normalize to the lowercase enum while retaining its original
  spelling and position, and optional fields can be absent (`RELEASES.md:87-99`;
  `PROJECT/PDDA.md:657-679`). **Concrete fix:** add a normalized grandfather-violations table (import
  run, release GID, rule, source value, supplied value, required disposition) and a per-release ordered
  field-layout table that records presence plus label/value rendering metadata; then specify how an
  edited mapped value replaces only its preserved value while absent fields remain absent. Alternatively,
  drop byte equality in favor of a precisely defined normalized Phase-0 fixture.

- **[Blocker] `dump_digest_after` is self-referential, so the proposed receipt cannot be computed as
  written.** `op_receipts` stores the SHA-256 of the canonical dump, while the canonical dump explicitly
  contains `op_receipts`; therefore the after-digest would have to hash a serialization containing that
  same digest (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:200-208,255-259`). The exit gate also says
  receipts prove two distinct sessions and a refused/retried contention case, but receipts contain no
  session identity and a writer refused before a transaction has no receipt
  (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:200-208,361-369`). **Concrete fix:** define a canonical
  *business-state* digest that excludes receipts, generation markers, and digest fields; require the
  latest receipt's after-digest to equal that state and its before-digest to equal the previous receipt's
  after-digest; add a stable dogfood-session ID; and record lock attempts/outcomes in a separate
  append-only audit stream so contention evidence is mechanically inspectable.

- **[Blocker] Crash recovery still omits the most dangerous boundary: DB COMMIT before staged files
  and journal exist.** The ordered write commits the DB, then stages the dump/Markdown, then creates the
  journal. A crash after COMMIT but before either later step leaves no journal and no staged artifacts;
  the stated recovery rule can neither complete renames nor discard a stage, while the only general
  divergence recovery at the top of the PRD rebuilds DB from the stale dump and loses the committed
  operation (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:46-53,238-252`). The generation bump is also
  placed after the renames in the ordered sequence even though the staged dump/file must already contain
  that generation (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:241-247`). **Concrete fix:** make a
  durable intent/recovery record exist before the authoritative DB commit and include the next generation;
  after commit, recovery must be able to regenerate missing staged outputs from that DB state. Specify
  and test pre-commit, post-commit/pre-stage, post-stage/pre-rename, every rename, and post-rename/pre-clear
  recovery separately.

- **[Blocker] Phase 0 still has two unsynchronized writers.** Import is explicitly one-shot, but the
  PRD allows `/releases` to keep patching the real Markdown throughout Phase 0 and defers migrating its
  mutating routes until Phase 2. Any clean/plan/anchor/publish after import changes only `RELEASES.md`,
  leaving the DB, dump, receipts, and side-by-side output stale; the two-week dogfood can no longer
  demonstrate either sole-writer behavior or byte equality (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:278-296,
  325-330,357-370`; `skills/releases/SKILL.md:100-184`). **Concrete fix:** migrate `/releases` mutations
  to the CLI at the Phase-0 entry while keeping generation side-by-side, forbid legacy Markdown writes
  during the measured dogfood window, or design an explicit incremental import/dual-write protocol with
  preimage conflict detection. A tolerated but unobserved second writer is not a transition mechanism.

- **[Should] The claimed exact-duplicate refusal has a NULL hole.** `releases.version` is nullable, and
  SQLite permits multiple NULLs through `UNIQUE(repo_id, version)`, so the assertion that exact release
  duplicates cannot land is false (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:135-154,220-223`). The
  current ledger contract already requires `Release:` (`PROJECT/PDDA.md:657-679`). **Concrete fix:** make
  `version` non-null and non-empty (with an explicit migration mapping for any `TBD` legacy spelling),
  or add a normalized unique expression/index and narrow the claim to the identity it actually enforces.

- **[Pass] Scope and future-shape discipline remain sound:** identity is immutable rather than a content
  hash, migrations are additive without EAV/JSON escape hatches, the UI is read-only, and driver/Slack
  integration remains deferred behind separate work (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:86-93,
  266-276,335-353`). The consumer claim is also correctly narrowed to reads, even though the Phase-0
  mutation timing above still needs correction (`PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:320-330`).

Handing off to Producer — go to the Producer window and say “take your turn”; disposition every Round 3
finding before revising the PRD.

### Producer · Round 3 dispositions

swept file: yes

All five R3 findings dispositioned. One was resolved by adopting your lighter alternative rather
than adding machinery — flagged first because it changes what R4 should verify.

- **[Blocker] missing grandfather + field-layout tables** — **Modified (your offered alternative
  taken).** Byte equality is DROPPED in favor of the precisely-defined normalized Phase-0 fixture
  you proposed: a pinned canonical rendering plus CONSUMER-EQUIVALENCE assertions (pdda releases,
  releases-current, Ballast Half A must produce identical findings against real vs generated).
  Rationale: consumers parse fields, they don't diff bytes — per-block lexical/layout tables served
  only cosmetic fidelity during a transition phase. `doc_lines`/`legacy_lines` stay (verbatim
  preamble + unmapped lines still render). The `grandfather_entries` table you asked for is now
  actually defined in the schema (import_run, release_gid, rule, source/supplied values, required
  disposition).
- **[Blocker] self-referential digest** — **Implemented.** Receipts now carry BUSINESS-STATE
  digests (canonical dump EXCLUDING op_receipts, lock_audit, generation, digest fields), chain rule
  before==prev.after, `session_id` per receipt (env-provided stable dogfood-session id), and a new
  append-only `lock_audit` table (acquired/refused/retried/recovered) so contention evidence exists
  even for writers that never got a transaction.
- **[Blocker] post-COMMIT/pre-journal crash hole** — **Implemented.** The intent journal is now
  written BEFORE the authoritative COMMIT and carries txn_id + next generation; the generation is
  stamped into settings within the transaction; recovery is specified per boundary — pre-COMMIT:
  discard+clear (DB unchanged); any post-COMMIT boundary: DB is truth, staged outputs are
  REGENERATED from DB state (derivable, so present-or-missing doesn't matter), renames completed,
  journal cleared. `--rebuild` narrowed to merge resolution only, never crash recovery. Negative
  controls expanded to all five boundaries.
- **[Blocker] two unsynchronized Phase-0 writers** — **Implemented.** /releases mutating-route
  migration moved from Phase 2 to Phase 0 ENTRY (preview-and-confirm UX kept, write path swapped);
  direct hand-edits forbidden during the measured window; a drift-report hit resets the sole-writer
  clock.
- **[Should] NULL-version UNIQUE hole** — **Modified (claim narrowed, per your alternative).**
  `version` stays nullable — the aegis "recorded, never reserved" convention legitimately holds
  multiple live TBD blocks, so NOT NULL would refuse a real sibling ledger at import. The
  duplication-guard claim now states its true scope (versioned releases), and `releases check`
  gains a warning for >1 unversioned release sharing a codename in one repo.

This is round 4 of 4. If the revision holds, please set STATUS: Approved; if a genuine
design-level Blocker remains, set STATUS: Escalated with the finding and the operator will
adjudicate.

Handing off to Reviewer — take your turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
