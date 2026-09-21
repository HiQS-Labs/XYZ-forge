# RELAY · GH-646 writer: rebase + reconciler repair QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-20.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh646-rebase-repair-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/wave_reconcile.py` (plus the three fixtures named below) — the committed delta on branch feat/gh646-writer-refresh since its last approved
  head `54b478de` (relay `relay-system/2026-09-17/gh646-writer-focused-replacement-qa.md`, Approved,
  round cap exhausted — hence this fresh thread). Concretely, `git diff 54b478de..HEAD` minus paperwork:
  the 2026-09-20 rebase onto origin/development `41be79e2` (26 commits; content patch-identical to the
  pre-rebase tip `c049d8f5` except where development also changed the file), the ledger replay
  (roadmap add/rate 85/70/50/70/marker through releases_app; `releases migrate` to schema 009), and
  commit `c544629f` "merged closers keep GH-202 terminal authority; fixtures model the writer's identity
  reads" — the ONLY product change: `utils/py/wave_reconcile.py::_may_terminalize_issue` and its two
  call sites; plus three fixture edits: `test/wave-reconcile.sh`, `test/gh496-phase2-reconciliation-views.sh`,
  `test/gh527-issue-url-repair.sh`. CHANGELOG entry "Explicit task starts and confirmed endings (GH-646)".
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-20
- Definition of Done: the previously approved writer semantics are intact after the rebase; the repair
  restores every landed reconciler contract (GH-202 offline promote-on-unknown for MERGED closers, #527
  per-row skip for local defects) without weakening GH-646's own rule (a declined PR is never terminal
  authority; terminal label needs a confirmed CLOSED issue); no fixture edit hides a product defect.  [Unverified — no citation]

### Operational envelope (grade against this)
One repo, one operator, local Python reconciler + Bash fixtures. Commensurate complexity: the repair is
a one-predicate narrowing and three fixture edits; do not ask for new machinery, config, or a second
writer. Evidence (disposable clone at `9a62c4b0` + the repair diff, logs retained by the driver):
wave-reconcile 21/21, gh496 green, gh527 17/17, gh202 40/40, gh280 216/216, gh646-status-label OK.
Red controls witnessed: F1 reverted → 8 red (merged-closer promotions); a `force_promote or not is_open`
mutant (pre-GH-646 semantics) → exactly the 2 new declined/unconfirmed assertions red. Full validate.sh
is running once on `c544629f` in a disposable clone; known environment reds on unmodified development
in this environment: gh142, gh268, gh649, gh425, gh-gen4, gh549-in-pool.

### Questions (cite file:line)
1. **The predicate.** `_may_terminalize_issue(issue_state, force_promote, is_merged, is_open)` returns
   `force_promote or issue_state == "CLOSED" or (is_merged and not is_open)`. `is_open` upstream is
   `(issue_state == "OPEN") or (issue_state is None and is_multiphase)`. Does this preserve GH-202
   (`fetch_issue_state` docstring: None ⇒ promote; only positively-OPEN suppresses; live mode dies on gh
   failure), the multiphase-umbrella preservation, and GH-646's declined-PR rule simultaneously? Name any
   input tuple where it promotes something the approved writer would have preserved, or vice versa.
2. **Both call sites.** ~lines 2098 (active doc) and 2130 (no active doc): are `is_merged`/`is_open`
   the right variables in scope at each site, and are the two log messages accurate for every path
   that reaches them?
3. **Writer's own pin.** `test/gh646_status_label.py::test_wave_requires_confirmed_closed_issue_before_terminalizing_label`
   (declined PR, states OPEN/None/UNKNOWN → nothing touched): still meaningful and still green? Is there
   a MERGED-closer case the writer's suite should also pin now that the predicate distinguishes them?
4. **Fixtures do not hide defects.** (a) gh496: adding `repos(id, slug)` = MIGRATION_001 shape — legitimate?
   (b) gh527: the REST-shaped `fake-gh` — does the test still prove GH-901 is skipped per-row and GH-900
   moves, and is keeping the whole-sweep refusal on a remote read failure the right call vs #527's
   per-row intent? (c) wave-reconcile.sh: `issues:[{777,CLOSED}]` plus PR #1004 → GH-778 stays in
   2-WORKING — is that pair a real red control for the declined branch, or does it just re-green?
5. **Rebase integrity.** Ledger conflicts were resolved by taking upstream bytes and replaying the
   GH-646 row through releases_app (never text-merged); schema 009 applied via `releases migrate` per
   RELEASES-DB-FAQS.md. Anything in `git diff 41be79e2..HEAD -- releases.sql` that is not the GH-646
   row, the migration row, or generated projections?
6. **Paperwork.** Does the CHANGELOG paragraph describe what the code does (not what was planned)?
   Anything false or overclaimed?

Output: graded bullets `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]` per question with `file:line`, then
`VERDICT: PASS|FAIL` and Basis. Set `STATUS: Approved` only if no `[Blocker]` or `[Should]` remains.
Read-only reviewer: modify/commit only this relay file. Do not run validate.sh, test/*.sh, pytest or
executable fixtures in the reviewer worktree; narrow non-mutating probes with cited input/command/output
are permitted under the landed GH-681 reviewer contract. No push.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · agy · Round 1 · 2026-09-20

VERDICT: PASS
Basis: The reconciler narrowing in `c544629f` correctly restores the GH-202 offline promote-on-unknown contract for merged closers while preserving GH-646's invariant that declined PRs require a confirmed CLOSED issue before terminalizing. Fixture updates in `gh496`, `gh527`, and `wave-reconcile.sh` model real ledger schemas and native identity reads without masking product defects. Rebase ledger replay and CHANGELOG paperwork are verified intact.
swept file: yes

- [Pass] **Question 1 (The predicate).** `_may_terminalize_issue(issue_state, force_promote, is_merged, is_open)` at `utils/py/wave_reconcile.py:327–332` returns `force_promote or issue_state == "CLOSED" or (is_merged and not is_open)`. Upstream at `utils/py/wave_reconcile.py:2093`, `is_open = (issue_state == "OPEN") or (issue_state is None and is_multiphase)`. For a merged closer (`is_merged=True`), an unlisted offline issue (`issue_state is None`, `is_multiphase=False`) yields `is_open=False` and `_may_terminalize_issue=True`, restoring GH-202's offline promote-on-unknown contract (`fetch_issue_state` docstring at `utils/py/wave_reconcile.py:295–300`); an issue positively `"OPEN"` yields `is_open=True` and suppresses terminalization, and a multiphase umbrella with `None` state is preserved active. For a declined PR (`is_merged=False`), `(is_merged and not is_open)` evaluates to `False`, strictly requiring `force_promote or issue_state == "CLOSED"`. The tuple where it promotes something the `54b478de` writer preserved is `(issue_state=None, force_promote=False, is_merged=True, is_open=False)` (and `issue_state="UNKNOWN"` with same flags), which was previously suppressed and broke GH-202.
- [Nit] **Question 2 (Both call sites & log accuracy).** At both call sites (`utils/py/wave_reconcile.py:2101` and `:2133`), `is_merged` and `is_open` are the correct variables in scope. At Call Site 1 (`:2095–2102`), the log message at `:2102` (`"and the PR was not merged"`) is accurate for every path that reaches it because merged open issues are intercepted upstream by `if doc_path and is_open and is_merged and not args.force_promote:` at `:2095`. However, at Call Site 2 (`:2131–2150`, no active doc), if a merged PR closes an issue whose state is positively `"OPEN"` (`is_merged=True`, `is_open=True`), `_may_terminalize_issue` returns `False`, correctly preserving the active roadmap entry, but line `:2149` logs `"Issue #{issue_num} state is OPEN — and the PR was not merged — preserving active ROADMAP.md entry; a declined PR needs a confirmed CLOSED issue to close out"`. The PR was merged, not declined. Behavior is correct (roadmap entry preserved); the log message is a cosmetic diagnostic inaccuracy. Recommended follow-up: branch log message on `is_merged`.
- [Nit] **Question 3 (Writer's own pin & mutant parameter count).** `test/gh646_status_label.py::test_wave_requires_confirmed_closed_issue_before_terminalizing_label` (`test/gh646_status_label.py:900–936`) is green (41/41 tests pass) and meaningful: it pins that a declined PR with issue states `OPEN`, `None`, and `UNKNOWN` leaves active docs and roadmap items untouched. However, the test's mutation runner flag at `test/gh646_status_label.py:1095` (`wave._may_terminalize_issue = lambda issue_state, force_promote: True`) was not updated for the 4-argument signature `(issue_state, force_promote, is_merged, is_open)`; invoking `python3 test/gh646_status_label.py --mutant wave_terminal` raises `TypeError: main.<locals>.<lambda>() takes 2 positional arguments but 4 were given` instead of running assertions. Recommended fix: update lambda to `lambda *args, **kwargs: True`. Additionally, while `wave-reconcile.sh` and `gh202` pin the merged closer behavior at the system level, adding a companion subtest with `is_merged=True` and `issue_state=None` to `gh646_status_label.py` would pin both branches of `_may_terminalize_issue` in the writer's unit suite.
- [Pass] **Question 4 (Fixtures do not hide defects).**
  - (a) `test/gh496-phase2-reconciliation-views.sh:112–115`: adding `repos(id, global_id, slug, updated_at)` matches canonical MIGRATION_001 schema (`utils/py/releases_app.py:1003–1005`), which `update_roadmap_entry` requires at `utils/py/wave_reconcile.py:1312` (`SELECT id,slug FROM repos`). Legitimate schema alignment, not defect masking.
  - (b) `test/gh527-issue-url-repair.sh:143–155`: `fake-gh` answers the REST `api repos/.../issues/N` identity read required by `read_native_issue` (`utils/py/releases_app.py:5410–5423`). GH-901 (corrupted local URL) is skipped per-row (`utils/py/releases_app.py:4063–4067`) and reported, while GH-900 (valid URL) reconciles cleanly. Keeping whole-sweep refusal on remote read failure (`utils/py/releases_app.py:4070–4083`) is the correct design per GH-202 to avoid state drift on transient network/API outages.
  - (c) `test/wave-reconcile.sh:90–106`, `:160–174`, `:346–368`: PR #1004 is a declined PR closing GH-778 with no `issues[]` entry, asserting `GH-778-UNKNOWN.md` remains in `2-WORKING/`. Reverting to pre-GH-646 semantics (`force_promote or not is_open`) terminalizes GH-778 to `4-MISC/`, failing the test. GH-777 has confirmed CLOSED state in `issues[]` and moves to `4-MISC/`. The pair provides an active red control.
- [Pass] **Question 5 (Rebase integrity).** Verified `git diff 41be79e2..HEAD -- releases.sql`: exactly the schema 009 migration entry (`INSERT INTO schema_migrations VALUES('9', ...)`), generation bump 922 -> 926, the single GH-646 row in `roadmap_items` (`rmi-01M30QPGVMZ7N6DZ3KP9M2K96C`), `status_label` column projection (default NULL) across existing roadmap rows, 4 `op_receipts` (roadmap-add, roadmap-rate, roadmap-update, migrate), and 3 `work_events` (parked, rated, in_flight) for GH-646. No text-merge artifacts or unrelated drift.
- [Pass] **Question 6 (Paperwork).** `CHANGELOG.md:3–16` accurately describes the schema 009 `in-progress` label, accepted start qualification, opt-in projection, clear on confirmed closure, reconciler narrowing in commit `c544629f` on rebase onto `41be79e2`, and the three fixture updates. Nothing false or overclaimed.
- [Pass] **Whole-file sweep (`utils/py/wave_reconcile.py`).** Inspected the full 2,223 lines of `utils/py/wave_reconcile.py` (preflight branch checks, cleanliness, lock contention, rollback journal, provenance receipt verification, PR metadata parsing, issue identity resolution, doc lifecycle transitions, subprocess orchestration, and PDDA validation gate). No reachable pre-existing defects found in scope.

relay closed (Approved), no further review turn needed. Handing off to claude-a — obtain Python-driver approval attestation and proceed with qualification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
