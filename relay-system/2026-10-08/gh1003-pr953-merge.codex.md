# RELAY · GH-1003 PR 953 caller merge-resolution QA
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
6. **Commit only the relay file** (`relay(gh-1003-pr-953-caller-merge-resolution-qa): <role> r<N>`); no push. **Stop** and report one line.
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

Goal: independently verify only the merge resolution for PR #953. Operational envelope: existing local XYZ toolkit, three-file documentation/ledger conflict. No runtime code edits, new suite, or new gate machinery are authorized in this repair. Review at candidate a5abfacb2e80bfe65ee7dbc68666eb676343ad6f; original PR head e257d31f6ae0b4719c661ec35ed9ac59613abcd8; integration parent 38ac9ee43bdedbd25be0cfec2029b0a27abd70a1. The earlier original feature reviews remain their own receipts.

Read CHANGELOG.md, the old parent versions via git show, the semantic ledger delta (releases.sql; derived releases.db), and TESTS-RESULTS/2026-10-08+GH-1003/pr-953/ in full. Existing writer replay remints row IDs, positions, timestamps and receipt chains. Original in-progress status_label admissions were explicitly reaffirmed using --accepted-start at current time, never backdated.

Questions:
1. Do every original parent changelog entry and every added section survive byte-for-byte in their relative order? Parent differences are insertions only; a controlled deleted PR heading failed the preservation check.
2. Does the ledger keep integration history/generation and retain each PR-added row's issue identity, title, doc path, section, marker, ratings and status_label via supported writer verbs? Flag unintended dropped rows, fabricated historical timestamps, SQL hand edits or duplicate issue identities.
3. Is resolution confined to CHANGELOG, ledger artifacts and committed merge evidence? Does any code delta beyond the normal three-way merge warrant concern?
4. Are the evidence claims accurate and limited to the checks they record? Final-head validation will run in a separate disposable full clone; do not run validate.sh, test/*.sh or pytest in the relay worktree.

Return a concrete Approved / Changes requested verdict with file:line evidence and observed input/falsifier for findings. Edit only this relay transcript. Do not fix the artifacts.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: Changes requested for one incidental generated-view change outside the bounded resolution. Changelog preservation and semantic ledger replay pass; final-head validation remains the separate clone gate.
swept file: yes

Scope: complete candidate CHANGELOG bytes, complete SQL dump, all derived DB tables, both parent snapshots and merge ancestry, and all three committed merge-evidence files were inspected. Historical feature behavior remains covered by its earlier receipts. Graph tools were unavailable; stored objects were read directly with SHA-1 verification, without invoking git. No other pre-existing defect was found within these merge-preservation and ledger-consistency checks.

- [Should] Exclude the incidental generated `LEADERBOARD.md` change from this resolution; retain the integration parent's view and let hosted reconciliation regenerate it. `LEADERBOARD.md:1` says `<!-- releases-app generation: 1489 -->`, whereas `releases.sql:3` and `releases.sql:16` say 1491. This view differs from the integration parent and is already present in initial merge `8e185b47`; it is not an original PR feature change or an unambiguous three-way result. The binding policy at `AGENTS.md:54` says hosted reconciliation owns views and “Task branches do not commit routine views.” This is a scope/governance finding, not a runtime-code defect.
  Observed input: candidate `a5abfacb` carries the generation-1489 generated view alongside generation-1491 ledger artifacts; integration `38ac9ee4` carried generation 1481. The whole-tree object comparison reports `LEADERBOARD.md` as the only departure from an unambiguous three-way result outside the three committed evidence files.
  Affected scope: the routine generated view bundled into this PR's documentation/ledger conflict resolution only.
  Falsifier: after excluding this incidental view delta, the candidate view should equal the integration parent's bytes until hosted reconciliation writes a new version; the ledger and both restored PR rows should remain unchanged. Explicit task authorization for committing this generated view would also invalidate the governance objection; none appears in the bounded request.
  Probe: `python3 .relay-scratch/tmp/review_probe.py`, exit 0, reports `departures from unambiguous three-way ['LEADERBOARD.md', ...three merge-evidence paths...]`. The narrow read-only SQLite/header probe, exit 0, reports `view header: <!-- releases-app generation: 1489 -->` and `ledger generation: 1491`.
- [Pass] Both entire parent changelogs survive byte-for-byte in relative order: PR 3619 -> 3673 lines, integration 3639 -> 3673, with `noninsert []` for each. Removing the PR's ATE heading makes PR preservation false while leaving integration preservation true, an appropriate independent red control. Citations: `CHANGELOG.md:53`, `CHANGELOG.md:138`, `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/merge-proof.txt:1`. Probe: `python3 .relay-scratch/tmp/review_probe.py`, exit 0; decisive output `added 54` against PR and `added 34` against integration; `deleted PR heading red control pr preserved False`.
- [Pass] PR semantic delta is exactly two added roadmap rows, with no changed or removed base rows. All 334 integration rows remain identical; candidate has 336, with no duplicate `(repo_id, gh_number)` identities. Required issue/title/doc/section/marker/rating/status fields for GH-949 and GH-912 have `differences {}`. All other integration tables remain unchanged except the generation setting, ten added receipts and eight added work events. Citations: `releases.sql:827`, `releases.sql:828`, `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/ledger-readback.txt:7`. Probe: `python3 .relay-scratch/tmp/review_probe.py`, exit 0; `PR row delta 2 changed [] removed []`, `integration missing or changed []`, `duplicates []`; full-table read-only comparison exits 0 with zero removals outside the generation setting.
- [Pass] Supported-writer replay is consistent with the recorded receipts and current-time start admissions. Generation progresses from integration 1481 to candidate 1491; integration receipt/event history survives. The canonical writer's read-only `dump_text` output exactly equals the entire SQL file, SQLite integrity is `ok`, foreign-key violations are empty, and the latest business digest matches. Chain count is 1678 excluding ship-evidence receipts, with 170 breaks and 170 reanchored, matching the readback; there are 1682 total receipts. Citations: `releases.sql:2521`, `releases.sql:2529`, `releases.sql:3171`, `releases.sql:3172`, `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/ledger-readback.txt:9`. Probe: `python3 .relay-scratch/tmp/detail_probe.py`, exit 0; `canonical writer dump equals SQL 1491 latest digest matches True`, `chain receipts 1678 breaks 170 reanchored 170`. This establishes consistency, not an audit of every shell command used during repair.
- [Pass] No additional runtime code resolution was found in the complete tree comparison. Relative to the initial merge, candidate changes only `releases.db`, `releases.sql` and two merge-evidence files; the normal merge preserves the parent code changes. All three reviewed evidence files match their candidate committed blobs. Citations: `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/merge-proof.txt:1`, `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/provenance.jsonl:1`. Probe: `python3 .relay-scratch/tmp/review_probe.py`, exit 0; `repair delta versus initial merge` contains only those four paths and `committed evidence matches` is printed for all three receipts.
- [Unverified — needs clone run] Final-head validation was deliberately not run here. `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/provenance.jsonl:1` accurately limits its claims to merge proof and leaves that gate pending. Approval of feature behavior, promotion or teardown is not established by this review.

Handing off to Producer (merge-cleanup) — address the generated-view scope finding, then obtain renewed independent QA and the final-head clone gate. The one-round relay is Escalated; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
