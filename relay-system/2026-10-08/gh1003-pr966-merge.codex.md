# RELAY · GH-1003 PR 966 caller merge-resolution QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-08.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1003-pr-966-caller-merge-resolution-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: merge-cleanup
- Started: 2026-10-08
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.


## Bounded review request

Goal: independently verify only the merge resolution for PR #966. Operational envelope: local XYZ toolkit, three-file documentation/ledger conflict. No runtime code edits, new suites, or gate machinery are authorized. Review candidate 3283b42d1ca138bfc1d5e3cc43bccb7eec6489f0; original PR head 89dc6608538de82541fa4b78f43b1a87bbe7f125; integration parent 38ac9ee43bdedbd25be0cfec2029b0a27abd70a1. Earlier feature reviews remain separate receipts.

Read CHANGELOG.md and both parent versions via git show, the semantic ledger delta (releases.sql and derived releases.db), and TESTS-RESULTS/2026-10-08+GH-1003/pr-966/ in full. Existing writer replay remints GIDs, positions, timestamps and receipt chains. Original in-progress status_label admissions were reaffirmed using qualified --accepted-start at current time, never backdated.

Questions:
1. Do all original parent changelog entries and added sections survive byte-for-byte and in relative order? Differences were insertions only; controlled deletion of the PR heading failed preservation.
2. Does the ledger keep integration history/generation and retain every PR-added row's issue identity, title, doc, section/marker, ratings and status_label through existing writer verbs? Flag dropped rows, fabricated historical timestamps, SQL hand edits or duplicate identities.
3. Is resolution confined to CHANGELOG, ledger artifacts and committed merge evidence? Does any code delta beyond the normal three-way merge warrant concern?
4. Are evidence claims limited and accurate? Final-head validation runs in another disposable full clone; do not run validate.sh, test/*.sh or pytest in the relay worktree.

Return Approved / Changes requested with file:line evidence and concrete observed inputs/falsifiers. Edit only this transcript; do not fix artifacts.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: Changes requested for one routine generated-view delta outside the stated three-file resolution. Changelog preservation and ledger replay pass the bounded checks; this is not a runtime-code rejection. The one-round limit is exhausted, so the header is Escalated.
swept file: yes

Scope: entire candidate/parent CHANGELOG byte streams, all tables in both parent ledgers and the candidate, complete canonical SQL/DB equivalence, all three committed merge-evidence files, and complete tree-path lineage. Historical feature behavior is outside this merge-only review. No additional pre-existing defect affecting this resolution was found. The repeated GH-111 URL is inherited in all versions and includes a checklist row with NULL issue number; there are no duplicate qualified issue-number identities. Existing migration/target-date warnings remain disclosed in `TESTS-RESULTS/2026-10-08+GH-1003/pr-966/ledger-readback.txt:8` and `:16`. Graph MCP tools were unavailable; parent objects were read directly, with their SHA-1 identities checked, without invoking Git.

- [Should] **Remove the routine leaderboard update from this task branch.** `LEADERBOARD.md:1` says `<!-- releases-app generation: 1489 -->`, while `releases.sql:3` says `-- generation: 1490`. Beyond the changelog, ledger pair and new merge evidence, this generated view is the extra nontrivial path relative to the parents. Its integration-parent header was generation 1481; the candidate adds the two replayed issues and renumbers subsequent display rows. `AGENTS.md:54`–`:56` assigns these views to hosted reconciliation and says “branches do not commit routine views.” Concrete fix: retain integration-parent `LEADERBOARD.md` in the merge candidate and let hosted reconciliation update it after landing; do not repair it by committing another regenerated view.
  Observed input: candidate `3283b42d1ca138bfc1d5e3cc43bccb7eec6489f0`, `LEADERBOARD.md:1` = generation 1489; integration parent `38ac9ee43bdedbd25be0cfec2029b0a27abd70a1`, same file = generation 1481. Probe `python3 .relay-scratch/tmp/ledger_analysis.py` exited 0; a Python `difflib`/ordinal-normalization comparison exited 0 and printed only the replaced generation header and added GH-964/GH-967 rows as content differences. Candidate view equals the intermediate merge view, so the final accepted-start write did not refresh this header.
  Affected scope: this candidate's generated `LEADERBOARD.md` delta only; preserve the two authoritative roadmap additions and all normal PR feature paths.
  Falsifier: candidate leaderboard blob equals the integration-parent blob, or an explicit operator exception authorizes this routine view commit. Equality should eliminate this finding; neither condition is present in the supplied request.

- [Pass] **Both parent changelogs survive intact and in relative order.** `CHANGELOG.md:3`, `:49` and `:1202` retain the integration entries, PR heading and added Unreleased section. Probe `python3 .relay-scratch/tmp/merge_analysis.py` printed `complete byte-line subsequence pr 3601 (True, 3601)` and `integration 3639 (True, 3639)`; every changelog opcode was `insert`. In-memory deletion of the exact GH-964 heading printed `(False, 2)`. That combined script subsequently exited 1 because an empty SQLite database lacks the schema required by this insert-only dump; this was a probe setup error, not an artifact failure. The ledger was then examined by deserializing complete DB images in memory. No fix requested.

- [Pass] **Integration history and both PR-added roadmap identities are retained.** `releases.sql:827` and `:828` preserve issue URL/number, title, raw text, doc, section/marker, all ratings and status_label for GH-964/GH-967. Probe `python3 .relay-scratch/tmp/ledger_analysis.py` exited 0: every integration table has zero removed rows except the generation setting; additions are exactly two roadmap rows, nine receipts and seven work events. Generation advances 1481 → 1490. The only original-row differences are numeric ID, GID and writer timestamps. A separate in-memory parent/base probe exited 0 and printed `PR-added roadmap identities [(964, .../issues/964), (967, .../issues/967)]`, `qualified duplicate issues []`; deleting either candidate row made `identity preservation False`. No fix requested.

- [Pass] **Dump, receipt chain and current-time admission agree.** A read-only probe using `sqlite3.connect(':memory:'); deserialize(Path('releases.db').read_bytes())`, followed by `releases_app.dump_text(c,1490)` and `business_digest(c)`, exited 0 and printed `canonical DB-to-SQL exact bytes True bytes 1357848` and `receipt-chain 1677 breaks 170 tolerated 170 business digest matches True`. SQLite integrity returned `ok` and foreign-key checks returned no rows. `releases.sql:2529` and `:3170` pair the final qualified accepted-start receipt/event at `2026-10-09T06:52:00Z`, matching `TESTS-RESULTS/2026-10-08+GH-1003/pr-966/provenance.jsonl:2`. All integration receipts/events remain byte-for-byte equivalent as database rows. This supports the writer-shaped replay and shows no receipt-less SQL mutation or backdated admission; it does not independently prove the producer's command execution history. No fix requested.

- [Pass] **No additional runtime-code resolution.** Whole-tree object comparison against merge base `8853cd6a134eef722e28079b7fc199b373e65f9e` and both named parents found only CHANGELOG, the ledger pair, three new evidence files and the leaderboard as nontrivial/extra paths. All runtime-code paths take an unchanged parent blob; in particular `skills/2-daily/xyz-mod/mod/hooks/register.ts:1` belongs to the ordinary PR addition. Probe `python3 .relay-scratch/tmp/merge_analysis.py` produced that complete path classification before its unrelated empty-schema probe error described above. No code fix requested.

- [Unverified — needs clone run] **Final-head validation remains pending.** `TESTS-RESULTS/2026-10-08+GH-1003/pr-966/provenance.jsonl:1` explicitly limits its claim to merge proof and leaves the final-head gate pending; the complete evidence directory contains only merge-proof, ledger-readback and provenance. No suite, pytest, executable fixture, Git command or artifact mutation was run here. Producer must obtain the required final-head gate in a disposable full clone after addressing the view delta; this transcript does not attest merge readiness.

Handing off to Producer (merge-cleanup) — remove the routine view delta, retain the passing resolution, and obtain final-head disposable-clone evidence. The relay is Escalated, not Approved; no automatic approval is granted.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
