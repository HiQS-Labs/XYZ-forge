# RELAY · GH-32 RELEASES app PRD review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-18.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
