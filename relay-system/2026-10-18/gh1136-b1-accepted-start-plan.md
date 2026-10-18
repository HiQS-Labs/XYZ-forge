# RELAY · GH-1136 plan QA: B1 replay keeps accepted-start on added rows
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1136-b1-accepted-start-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1136-B1-ACCEPTED-START.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1136-B1-ACCEPTED-START.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Plan QA request.** Read the seeded plan (canonical `PROJECT/2-WORKING/GH-1136-B1-ACCEPTED-START.md`), then the following:
- `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` (whole file)
- `utils/py/releases_app.py:1640-1700,3900-3990` (the accepted-start writer)
- issue #1136

**Envelope:**
- No new test file or case (GH-831).
- Fix through the existing writer only.
- B1 keeps its fail-closed contract.

**Questions (cite file:line):**
1. Is the add-branch-only scope right? Confirm that an *updated* row's `status_label` change already hands off via `REPLAYABLE_COLUMNS`.
2. gid lookup: is `roadmap list --json` matched on `gh_number`+`issue_url` a unique, safe selector in a multi-repo ledger? Is there an existing helper the replay should use instead?
3. A closed native issue makes `--accepted-start` refuse. Should the replay **fail** (handoff, as planned) or **skip with a logged warning**? Weigh this against B1's "stops at the first refusal" contract.
4. Are manual controls (a)–(d) sufficient and non-vacuous? Is stubbing `read_native_issue` at the subprocess boundary acceptable?
5. The GH-1112 data repair: is the CLI write in the PR the right vehicle, and is losing the original start time acceptable?

End with a line that is exactly `VERDICT: PASS|FAIL|PARKED` (no bold, no prefix), a `swept file:` line, and set `STATUS: Approved` only on PASS.

### Reviewer · Round 1

**Ship — plan approved for implementation.**

Basis: the existing writer can restore explicit admission without widening the classifier or bypassing identity/native-state checks. This approves the plan, not implemented behavior or merge readiness. Graded against the Producer's envelope and five questions; Setup's Definition of Done remains an unfilled template.

swept file: yes

Read the entire seeded artifact (lines 1–68) and entire `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` (lines 1–649), including existing classifier, replay, resolver and pre-merge gate. No additional actionable pre-existing defect found in that bounded sweep. Graph evidence was provisional: `XYZ-forge` generation `2026-09-01T15:54:30Z` points at the primary checkout; coverage reports ledger_merge `not_tracked` and releases_app `metadata_changed`. Current source reads supersede that stale index.

- [Pass] **Q1 — add-only scope is right.** `ledger_merge.py:236-243` accepts an added row without a column diff, while updates subtract `REPLAYABLE_COLUMNS` and hand off unsupported differences; `status_label` is absent from that set (`:52-54`). `replay_ops` currently emits only add/rate/section-marker writes for additions (`:301-330`). `_sync_status_labels` initializes a newly added label to NULL and grants it only for accepted-start (`utils/py/releases_app.py:1643-1655`). Root cause: admission metadata on an added row is never replayed; fix site: add replay; why here: reuse the authoritative admission writer rather than weakening its contract.
- [Pass] **Q2 — lookup is safe with exactly-one matching and writer validation.** `roadmap list --json` exposes `global_id`, `gh_number`, and `issue_url` (`releases_app.py:4443-4457`). Use that public contract, check command success and JSON shape, require exactly one match and a nonempty gid, and return False with a diagnostic on failure. `resolve_roadmap_identity` (`:5440-5455`) qualifies ownership; it is not a gid lookup helper. The accepted-start handler already invokes it and refuses invalid ownership (`:3943-3956`), so duplicating it in replay buys nothing. This does not promise general multi-repo replay: existing `add` rejects duplicate numbers globally and assigns the first repo (`:3652-3667`); those refusals remain handoffs.
- [Nit] **Make number normalization explicit at artifact line 40.** Parsed dump numbers are strings (`ledger_merge.py:86-87`), while JSON numbers come directly from SQLite integers (`releases_app.py:4446`). Compare `str(candidate["gh_number"]) == str(gh)` with the exact issue URL. A direct Python equality would miss a valid row. Narrow read-only probe (exit 0): `python3 -` with `sqlite3.connect('file:releases.db?mode=ro&immutable=1', uri=True)`, selecting `global_id,gh_number,issue_url,status_label` for 1112 and 1136, printed `DB/JSON number type: int dump number is SQL token text; direct equality: False`. GH-1112's returned gid was `rmi-01M56GEJJR4PXDB80R4JG60NG1`, label `None`. The same probe AST-read `REPLAYABLE_COLUMNS` and printed `status_label replayable: False`. No repository code, fixture or writer was executed.
- [Pass] **Q3 — retain fail-closed handoff for closed issues.** The writer refuses a non-open native issue (`releases_app.py:3954-3960`); replay stops at the first refusal (`ledger_merge.py:293-294`) and its caller converts False into a handoff before resolution/commit (`:571-575`). Skip-with-warning would report success while discarding the exact metadata this plan exists to retain. Partial writes remain in the disposable landing clone for operator disposition.
- [Pass] **Q4 — (a)–(d) are adequate planned controls for the bounded change, with real writer behavior.** Artifact lines 52–56 specify a durable transcript/provenance destination, positive result, base red control, unlabeled compatibility and closed-issue refusal. Stub the external `gh api` boundary using `RELEASES_GH_BIN` (clear/override `XYZ_LABELS_GH_BIN`, which takes precedence), return matching `number`, `html_url`, `state`, and `labels`, and let `read_native_issue` plus the writer run unchanged (`releases_app.py:5472-5485`). Patching a parent-process function alone will not affect the child writer. Keep nonempty row assertions, assert replay success for (a)/(c), and record the failing base assertion for (b). Existing wrapper `test/gh436-merge-cleanup.sh:11` invokes the Python suite, whose lines 870–872 import phase A/B/C coverage. No new suite or case is needed.
- [Pass] **Q5 — use the CLI repair in this PR; disclosed timestamp loss is acceptable.** The specified gid currently belongs to GH-1112 with NULL label (`releases.sql:874`; read-only probe above). Accepted-start uses the receipt-backed `perform_write` (`releases_app.py:4041-4043`) and stamps `now_iso()` (`:4015-4020`); preserving historical time would expand the writer contract beyond artifact lines 45 and 62. Recheck live open state and gid ownership at repair time, and retain the PR disclosure of the repair-time start. The plan's rollback is suitable for code; a code revert alone does not undo the committed data repair.
- [Unverified — needs clone run] Controls (a)–(d), existing suites and the final pre-push gate are future implementation evidence; none was run here. [Unverified — network unavailable] `gh issue view 1136 --repo HiQS-Labs/XYZ-forge --json number,title,state,body` exited 1: `error connecting to api.github.com`. The live issue text and GH-1112 open-state assertion therefore remain unverified in this turn. Neither limitation blocks this source-grounded plan approval; the actual repair must still pass the native-state writer check.

Alternatives considered: do nothing retains silent loss; skip a closed issue violates refusal semantics; direct SQL duplicates the writer and bypasses its receipts/identity checks. Replaying the existing accepted-start verb is the smallest sound choice. Scope remains add replay plus the named data repair; no source or artifact was changed by this review.

relay closed (Approved), no further turn needed. Producer may implement the approved plan and obtain final QA after clone verification.

VERDICT: PASS


### Attestation · relay-drive — 2026-10-18T17:05:13Z
task: RELAY-gh1136-b1-accepted-start-plan
reviewer: codex
status: Approved
reviewed-head: 976ffad5eb94eaac6ba837c87742051154b4fb43
added-range: 6862+6198
added-sha256: f6c5060a9af02bcf006d4e7ddfd0da63cca83397e3f8bca027a1f90868ad8999
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
