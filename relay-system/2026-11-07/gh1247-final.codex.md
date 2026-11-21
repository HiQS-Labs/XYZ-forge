# RELAY · GH-1247 GH-1362 final implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-07.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1247-gh-1362-final-implementation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1247-RETIRE-REMOTE-TAGS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1247-RETIRE-REMOTE-TAGS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-07
- Definition of Done: Review complete diff from 3bf02f73ce0cb11a82f970357209980f808ccb3c to HEAD, especially full scan_clones.py. GH-1247 requires exact unpeeled remote tag identity, local-only/different preservation and query failure closed. GH-1362 requires trusted deployed harness lookup without executing an audited checkout, retaining unknown/active claim preservation. GH-1359 is research only and must remain open, with no schedule or broad deletion. Verify plan/ratings, source ownership, minimal extension of existing subsystem, evidence and no new suites/gates. Read TESTS-RESULTS/2026-11-07+GH-1247/SUMMARY.md and provenance/logs, both capture docs, and plan QA. The existing gh436 suite and manual controls passed; full classified gate intentionally follows approval. Grade the local operator-tool envelope, not speculative multi-tenant requirements. Run no mutation-heavy suites in your review worktree. Write only this relay receipt. Review whole changed production file; distinguish existing unrelated issues from blockers of this scoped fix.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Ship with the already-planned final classified gate outstanding. Reviewed the base-to-HEAD change inventory using read-only libgit2 object/tree access (no git command), the entire changed production file, seeded artifact, captures, plan receipt, ratings and retained evidence. No blocking scoped defect or additional blocking pre-existing defect found in scan_clones.py. This approves implementation review, not deployment, deletion or merge readiness.
swept file: yes

- [Pass] Exact tag recovery is checked before ancestry: `skills/2-daily/merge-cleanup/scripts/scan_clones.py:621` requests `ls-remote --refs --tags origin`; lines 638–644 compare full names and unpeeled IDs and preserve mismatches. Failure/malformed advertisements return through failed_query (lines 624–634), consumed as PRESERVE_UNVERIFIED_QUERY (lines 1165–1169). One advertisement serves all local tags. Branch/detached provenance remains unchanged.
- [Pass] Independent narrow probe imported the production module with PYTHONDONTWRITEBYTECODE=1 and patched only run_git; no subprocess or fixture executable ran. Command: `python3 - <<'PY'` calling `classify_local_refs(Path('/not-used'))` for local `refs/tags/ann` at `'a'*40`, advertisements of the same ID, `'b'*40`, empty output, `broken\n`, and exit 1; the mock raised if a tag reached merge-base. Exit 0; decisive output: `exact ... landed`, `different-annotation ... unlanded`, `empty-origin ... unlanded`, `malformed ... ok: False`, `query-failure ... ok: False`, and `5 non-mutating classifier controls PASS; no subprocess launched`. Each case made one ls-remote call. This is a controlled classifier probe, not a real Git/retirement integration run.
- [Pass] Deployed lookup extends the existing owner: `scan_clones.py:254–287` retains explicit override, own installation and PATH, adds operator XYZ_HARNESS and canonical-origin-checked device configuration, and does not search the audited CWD. Explicit environment is treated as operator authority in this local-tool scope. `inspect_tick_claims` still pins TICK_REPO_ROOT and preserves unavailable/malformed responses (lines 330–357); active/unknown claims remain binding at lines 1123–1133. Retained `candidate.log` records idle, active, foreign-config, missing and broken-override outcomes; no audited-checkout executable is newly selected by discovery.
- [Pass] Production changes are confined to these two existing functions; no new suite, dependency, gate, scheduler or teardown path. Existing downstream fresh reinspection is retained at `merge_cleanup.py:1013–1029,1743–1749`. `TESTS-RESULTS/2026-11-07+GH-1247/provenance.jsonl` identifies base/candidate, mocks and separate-clone scope; `gh436.log:4265–4267` records “Ran 205 tests” / “OK”. The baseline log witnesses the reported false preservation and ancestry false-safe control; candidate.log records corrected outcomes. These are inspected producer receipts, not tests rerun by this reviewer.
- [Pass] SQLite read-only query `select gh_number,rating_pri,rating_sev,rating_appeal,rating_effort,status_label from roadmap_items where gh_number in ('1247','1359','1362')` exited 0 and returned 1247=75/60/50/80, 1362=75/60/50/85, 1359=70/45/50/45, all in-progress. Research boundaries are explicit in `PROJECT/1-INBOX/GH-1359-CLONE-RETIREMENT-GAPS.md:20–37`: unknown T3 ownership, remaining terminal receipts, no schedule, no research-driven purge, and no closure of #1359. The source map agrees with Express's reminder at `utils/py/express.py:1207–1209` and Marathon's cost-summary reminder at `utils/py/marathon_drive.py:1812–1841`.
- [Nit] The active artifact's Phase 0 checklists remain unchecked and its status/issue rows still describe verification or “Plan QA” as next despite retained focused evidence. Update those bookkeeping cells during normal closeout after the final gate; preserve the historical incident section.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest or executable fixtures were run here. SUMMARY.md explicitly leaves the classified gate pending; run that gate in the disposable full clone against the final committed state before claiming readiness.
- [Unverified — source access] Live `gh issue view N --repo HiQS-Labs/XYZ-forge --json body,state` for N=1362,1359,1247 each failed with “error connecting to api.github.com” (combined command exit 1). Live issue completeness/state is not attested; review uses local captures and the scoped Definition of Done. Graph search also returned “MCP tool call requires approval, but approval policy is never”; direct reads were the fallback.

Relay closed (Approved), no further turn needed. The producer/harness owns the final gate and relay-file commit.


### Attestation · relay-drive — 2026-11-08T00:00:09Z
task: RELAY-gh1247-final
reviewer: codex
status: Approved
reviewed-head: 9ebb1ac02dfe9a02c4618c15448dcc6d341aa90e
added-range: 6817+4784
added-sha256: da5a744b65a0a3e167ce0c3afd0f389226cf20d3a748effd251b497734df368c
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
