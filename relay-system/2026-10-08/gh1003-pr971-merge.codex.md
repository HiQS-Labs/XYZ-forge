# RELAY · GH-1003 PR 971 caller merge-resolution QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-08.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-1003-pr-971-caller-merge-resolution-qa): <role> r<N>`); no push. **Stop** and report one line.
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

Goal: independently verify only the merge resolution for PR #971. Operational envelope: local XYZ toolkit, three-file documentation/ledger conflict. No runtime code edits, new suites, or gate machinery are authorized. Review candidate bf746fb42ecdd38810d8b6b652a20724181f9df0; original PR head 407d5a0e92aef56d6928a366a9240d962add336e; integration parent 38ac9ee43bdedbd25be0cfec2029b0a27abd70a1. Earlier feature reviews remain separate receipts.

Read CHANGELOG.md and both parent versions via git show, the semantic ledger delta (releases.sql and derived releases.db), and TESTS-RESULTS/2026-10-08+GH-1003/pr-971/ in full. Existing writer replay remints GIDs, positions, timestamps and receipt chains. Original in-progress status_label admissions were reaffirmed using qualified --accepted-start at current time, never backdated.

Questions:
1. Do all original parent changelog entries and added sections survive byte-for-byte and in relative order? Differences were insertions only; controlled deletion of the PR heading failed preservation.
2. Does the ledger keep integration history/generation and retain every PR-added row's issue identity, title, doc, section/marker, ratings and status_label through existing writer verbs? Flag dropped rows, fabricated historical timestamps, SQL hand edits or duplicate identities.
3. Is resolution confined to CHANGELOG, ledger artifacts and committed merge evidence? Does any code delta beyond the normal three-way merge warrant concern?
4. Are evidence claims limited and accurate? Final-head validation runs in another disposable full clone; do not run validate.sh, test/*.sh or pytest in the relay worktree.

Return Approved / Changes requested with file:line evidence and concrete observed inputs/falsifiers. Edit only this transcript; do not fix artifacts.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approved for bounded merge-resolution QA at `bf746fb42ecdd38810d8b6b652a20724181f9df0`: parent preservation, ledger integrity and resolution scope pass. Final-head validation remains pending in a disposable full clone; this approval does not attest that gate.
swept file: yes

Scope: swept complete parent/candidate changelog bytes, every row of all 16 ledger tables, the complete committed merge-evidence directory and commit-tree identities; reviewed material merged spans and the dump/receipt implementation. Historical runtime claims were not rerun. No additional pre-existing defect affecting this bounded merge found; nine inherited ledger advisories remain visible at `TESTS-RESULTS/2026-10-08+GH-1003/pr-971/ledger-readback.txt:5-15`. Nearest graph: another XYZ-forge checkout, generation `2026-09-01T15:54:30Z`; coverage reported excluded/stale/missing artifacts, so direct candidate bytes supply the evidence. No git process, suite, pytest or executable fixture was run; only this transcript changed outside scratch.

- [Pass] **Both complete changelog parents survive byte-for-byte in relative order.** `CHANGELOG.md:3-47` retains integration entries, `CHANGELOG.md:49-59` retains GH-970, and `CHANGELOG.md:1198-1205` retains the integration hotfix section at its original relative location. Probe command: `python3 - <<'PY'` using `all(any(x == y for y in it) for x in old)` over an iterator of candidate byte lines including line endings. Exit **0**; decisive output: `"pr lines 3597 candidate 3651 ordered-byte-line-preservation True"`, `"integration lines 3639 candidate 3651 ordered-byte-line-preservation True"`. Deleting the exact GH-970 heading in memory produced `"red control heading deletion False"`. Parent objects were read directly with complete object SHA-1 verification.

- [Pass] **Integration history is retained and the sole PR-added row keeps its business fields.** `releases.sql:827` preserves issue **970**, title, URL, doc, section, marker, raw text, ratings **55/40/50/85** and the original NULL `status_label`. This PR has no added in-progress admission needing accepted-start replay. Probe command: `python3 - <<'PY'`, opening the base, both parents and candidate DBs with `sqlite3.connect('file:'+path+'?mode=ro&immutable=1', uri=True)`; full-table comparison plus GH-970 comparison excluding only ID/GID/position/timestamps. Exit **0**; output: `"integration full-table row preservation 3109 unchanged rows; only generation setting replaced"`, `"replayed issue 970 semantic fields equal; status_label None"`, `"duplicate issue identities []"`. Fresh replay timestamps are `2026-10-09T06:51:04Z`; add/rate/update receipts appear at `releases.sql:2521-2523`, matching work events at `releases.sql:3159-3161`. A 55-to-56 in-memory rating mutation yielded `"red control rating mutation rejected True"`. Receipts are consistent with existing writer verbs; summary provenance alone does not independently record exact writer argv.

- [Pass] **Canonical SQL, DB generation and receipt evidence agree.** `releases.sql:3` and `releases.sql:16` name generation **1486**, matching `TESTS-RESULTS/2026-10-08+GH-1003/pr-971/ledger-readback.txt:3-4`. Probe command: `python3 - <<'PY'`, AST-extracting only pure dump/digest functions; checking `dump_text(conn, 1486) == Path('releases.sql').read_text()` and folding `SELECT * FROM op_receipts WHERE op != 'ship-evidence' ORDER BY id`. Exit **0**; output: `"canonical dump exact-byte parity True generation 1486"`, `"foreign_key_check []"`, `"integrity_check ok"`, `"receipts counted by checker 1673 all receipt rows 1677 breaks 170 tolerated 170 digest matches True"`. Four excluded ship-evidence rows explain the count under `utils/py/releases_app.py:5744-5747`; no divergence was observed.

- [Pass] **No runtime code resolution is introduced; the additional view is a faithful ledger projection.** SHA-verified commit/tree probe command: `python3 - <<'PY'`, comparing every candidate leaf against ordinary unchanged-parent/changed-parent selection from common ancestor `442ea913ee5e2fb3d6e050a63c6d90ff07865eb6`. Exit **0**; output: `"both-parent changed paths ['CHANGELOG.md', 'releases.db', 'releases.sql']"`. Other deviations are the three committed merge-evidence files and generated `LEADERBOARD.md` (generation **1486** at `LEADERBOARD.md:1`, added GH-970 at `LEADERBOARD.md:174`). Full-view comparison ignoring displayed ranks yielded `"LEADERBOARD dropped or modified data rows []"` and exactly one added data row, GH-970. Candidate follow-up changes only ledger-readback/provenance evidence; all three evidence files match committed candidate blobs. `TESTS-RESULTS/2026-10-08+GH-1003/pr-971/provenance.jsonl:1` explicitly limits the claim to merge proof and leaves final-head validation pending, accurately.

Required fixes: none. [Unverified — needs clone run] The harness must supply final-head validation before landing.

Relay closed (Approved), no further review turn needed. Handing the completed result to Producer **merge-cleanup** for the separate final-head gate and landing decision.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
