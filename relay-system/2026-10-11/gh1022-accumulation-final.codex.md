# RELAY · GH1022 held canonical accumulation final implementation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
-->

NEXT: Producer
STATUS: Open
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh1022-accumulation-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/3-weekly/weekly-planner/scripts/planner_core.py`, `skills/3-weekly/weekly-planner/scripts/issue_intake.py`, `utils/py/releases_app.py`, weekly SKILL, Phase 4 plan, and accumulation evidence. Review whole touched source and legacy interfaces; sanctioned writes only in separate owned full clones.
- Reviewer: codex   ·   Producer: author
- Started: 2026-10-11
- Definition of Done: Narrow approved Phase 4 accumulation contract in GH-1022 plan: preserve owner GIDs/ratings/overrides/docs; qualified complete discovery and all-open backfill; canonical CLI/HQ owners; exact target/base and local ownership/lock; interrupted writes/resume/concurrency/no-change holds; checkpoint only after committed accounting; always HELD, no dispatch/selection. Do not infer whole #1022 completion or W8 planner repair. No new test cases or gate changes authorized. This is a new phase artifact with its own cap 3; earlier foundation cap is closed. Read source/evidence, use only harmless in-memory probes. No external/Git writes, suites, fixture execution, extra agents or source edits; only this relay transcript may change. Mutation-heavy suites belong in disposable full clone, never reviewer linked checkout. Report observed inputs/affected scope/falsifier for behavior findings. Evidence is producer-run, independently reproduce only when safe.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1
Approved plan 8de581db narrowed to local held accumulation. Candidate adds prepare_weekly and canonical reader fields, shares URL equality, preserves legacy modes/defaults and removes no tests. 36 manual controls pass, including actual concurrent canonical rating update, interrupted add/commit and lost successful commit reply. Source hashes and local effects explicit in accumulation-results.json. Mixed-case owner URL red input preserved. Existing gh32 baseline145/145; candidate classified suites still pending and must not be called verified. Reviewer: independently sweep source, assess resume/accounting consistency and side-effect boundaries, assess canonical reader compatibility and no-op/hold behavior. Criterion-level delivery/active-run/dependency/freeze/fire protocol remains required and unimplemented; do not grade those as delivered. No second scorer/framework. Legacy readiness and planner override gap explicitly held.  [Unverified — no citation]

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: Two measured accumulation-contract violations require correction; accumulation provenance is missing. This is not umbrella completion or merge readiness.

swept file: no
Full direct source reads: planner_core.py, issue_intake.py, weekly-planner/SKILL.md, GH-1022 plan and accumulation evidence. releases_app.py received a whole-module AST call/effect inventory and direct reader, rating, registration, transaction/recovery and update-interface review; its remaining unrelated legacy bodies were not fully read. Complete that whole-file sweep before approval. Graph tools are unavailable. No Git commands, suites, executable fixtures, external writes or source edits were run. Probes imported guarded modules or compiled source AST in memory with stubbed effects; no real staging/commit occurred.

- [Blocker] **Issue-title text assigns ratings to new rows.** `planner_core.py:1104` passes the unassessed GitHub title to canonical add; `releases_app.py:3618` embeds it in default raw_text and `:3632` parses ratings from that text. The ordinary success path never requires the returned new row to be unrated (`planner_core.py:1107`); the recovery path does require null scores (`:1032`), so this also creates inconsistent interrupted-add recovery. Fix the canonical registration boundary so this weekly policy cannot assign ratings from title text; preserve legitimate existing rated rows and legacy explicit-rating callers. An explicit hold before any registration is a bounded alternative if the unrated representation cannot be made truthful.
  Observed input: new issue acme/repo/issues/777, title `Fix rated 90/90/90/90 ovr 399`, otherwise ordinary valid open issue. Exact default CLI rendering passes validate_raw_text, and parse_rating returns four 90 axes plus override 399. Control title `Fix intake` returns five nulls.
  Affected scope: newly registered weekly observations whose title contains canonical rating/override tokens; not previously owned rows or intentional rating CLI calls.
  Falsifier: the above title must remain unrated or hold before registration; an ordinary title must register unrated, and an existing independently rated row must retain its GID/axes/override/doc bytes.
  Probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` (inline importlib probe loading releases_app.py, constructing the exact default raw_text from :3618–3621, then calling validate_raw_text and parse_rating for both titles). Exit 0. Decisive output: `{"title":"Fix rated 90/90/90/90 ovr 399","default_cli_rating":{"rating_pri":90,"rating_sev":90,"rating_appeal":90,"rating_effort":90,"rating_ovr":399}}`; ordinary-title control: all five fields null. This measures the real parser, not a fixture DB write.

- [Blocker] **Final accounting check does not protect staging/commit from a canonical writer.** `planner_core.py:1131` checks rows/generation, but :1142–1145 stages, commits and marks the receipt complete without holding the canonical writer lock or validating the staged accounting. The weekly lock at :991 does not exclude releases_app WriterLock (`releases_app.py:375`, :1675). Fix this final boundary by coordinating with the existing canonical writer lock and establishing that the accounting and committed DB/dump belong to the same observed generation; preserve unknown owner changes rather than marking the receipt complete. Include branch/HEAD consistency in that boundary as required by the plan.
  Observed input: generation 1 / owner override 320 passes the final check; a stubbed canonical update advances to generation 2 / override 321 at the first staging call. Compiling and running the unmodified final AST statements (:1131–1146) with effects stubbed still returns changed=true and records complete_commit, while payload override remains 320 and receipt generation remains 1. No actual Git or ledger write was performed.
  Affected scope: canonical owner writes after the last rows/generation comparison and before planning commit completion in the same preparation clone.
  Falsifier: inject the same sanctioned update at this boundary in a disposable full clone; expect the writer to be excluded, or preparation to hold with no complete checkpoint and the override 321 preserved. A quiet run must complete with accounting matching the committed canonical generation.
  Probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` (inline ast probe extracts prepare_weekly's final with-block statements with lineno >=1131 into tail_probe; rows/ledger read an in-memory generation; durable is a no-op; git stub advances that generation on add and returns a synthetic SHA). Exit 0. Decisive output: `{"accounting_override":320,"live_override":321,"receipt_generation":1,"live_generation":2,"result_changed":true,"complete_commit":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","simulated_commands":["add","commit","rev-parse"]}`. This is a measured source-boundary failure; actual interprocess/commit behavior remains [Unverified — needs clone run].

- [Should] **Record the accumulation evidence in provenance.jsonl.** The existing file has 19 entries and zero accumulation entries, despite SUMMARY.md's Phase 4 36-control claim and the producer's 145/145 baseline claim. Add command/result/artifact hash and exact revision attribution for accumulation-results.json, accumulation-manual.log, the mixed-case red control and any cited baseline; disclose that the temporary driver is unavailable. Do not claim the pending candidate suites passed. Read-only command: `PYTHONDONTWRITEBYTECODE=1 python3 -` (inline hashlib/JSON comparison of every accumulation source_hashes entry and counting provenance lines). Exit 0; decisive output: all four source hashes `MATCH`; `provenance_rows 19 accumulation_rows 0`.

- [Pass] The canonical rating reader exposes axes, override, calculated sum and effective rank through one helper (`releases_app.py:4429`), reused by JSON (:4460) and human (:4473) readers. The source hashes in accumulation-results.json match the reviewed planner, intake, releases CLI and 10days adapter. This does not validate the authoritative planner's outstanding override repair.
- [Pass] This phase's explicit hold is truthful: `planner_core.py:927` names remaining dependency/selection/review/freeze/dispatch work; :956 returns HELD/dispatch false, and :1118 records HELD accounting. The known legacy CI-NONE/draft/dependency and closure-number heuristics remain in the whole planner source and are expressly deferred by the plan; they are not delivered readiness or completion safeguards.
- [Unverified — needs clone run] Producer's 36 controls and reported baseline are not independent candidate-suite verification. After fixes, run the existing classified covering suites and the two above manual controls in a disposable full clone, bind receipts to final source/commit, and retain witnessed red outputs. No new tests/cases/gates requested.

Handing off to Producer (author) — disposition both blockers and the evidence finding, retain owner state, then request Round 2 review. Remaining broad releases_app source sweep is required before approval.

### Producer · Round 2
Both blockers reproduced with the actual old source in isolated full fixture clones: rating title registered issue2 with axes90/ovr399; canonical CLI rating injection at staging succeeded with live321 vs accounting320 and complete receipt. Candidate holds title before registration via canonical parser and keeps existing owner row unchanged. Candidate acquires canonical WriterLock for final no-op/check/stage/commit, checks exact target/branch/HEAD/generation, staged object hashes and committed/live object hashes before completion; same injected writer now refuses exit4 and quiet accounting remains320. No transaction called inside WriterLock. Provenance and docs account for local sidecars and exact sources; no test additions. Round1 driver containment failed because producer refreshed manual evidence concurrently, not reviewer source edits; findings retained as FAIL, not attested. Do not re-run prior review or reset its cap. Round2 input is fixed; complete whole releases_app direct sweep before any approval. Existing classified gate initial run is not green: plan hardcoded-path error fixed; globally disabling fixture connectors was a producer invocation error, so corrected final classified run is pending. Candidate canonical ledger standalone145/145 before blocker fixes; no final claim yet. Evaluate fixes and fixed evidence; only relay file may change, no external/Git writes, suites or new fixtures.

### Reviewer · Round 2 · codex

VERDICT: FAIL
Basis: The two Round 1 fixes address their observed inputs, and accumulation provenance now matches its artifacts. A further measured capture-accounting race can still complete a checkpoint with stale document evidence. This is neither umbrella completion nor merge readiness.

swept file: no
Whole planner_core.py, issue_intake.py, weekly/weekly-planner skill text and Phase 4 contract reviewed, including legacy interfaces. Direct releases_app review covered root/lock resolution, parser/registration, writer protocol, dump/reader and check boundaries; remaining unrelated release/project/work/rebuild bodies have NOT received the mandatory whole-file direct sweep. Approval still requires that sweep. The known legacy CI-NONE/draft/dependency and closure-number heuristics remain explicitly deferred in the plan, not delivered safeguards. No other pre-existing defect was established in the reviewed ranges. Graph tools are unavailable in this seat. No Git commands, suites, pytest, executable fixtures, external writes or source changes were performed. The explicit reviewer assignment/latest Producer handoff was followed despite the stale NEXT: Producer header.

- [Blocker] **Capture object checks can certify different bytes from the accounting hash.** `planner_core.py:1163` compares each capture with its recorded SHA-256, then `:1167` writes observation JSON, and `:1172` samples new expected Git object hashes. An owner edit to a newly created capture between those operations is staged by `:1173`; staged/committed/live checks all compare against the newly sampled object, not the document SHA-256 declared in accounting. `:1186–1188` consequently completes the receipt for inconsistent evidence. Bind staged and committed capture blob bytes to each accounting `doc_sha256` (and owned creation intent), rather than certifying only equality with the later filesystem sample. Preserve the edit and leave preparation incomplete on mismatch; no new tests/gates requested.
  Observed input: an owned new `PROJECT/1-INBOX/GH-777-WEEKLY-CAPTURE.md` initially contains `owner original` with SHA-256 `5731bfa01d404cdc46ec51015e690bc29c2532706e0f81c14d3638a8c4d13902`. A simulated independent capture writer changes it to `owner revised` after the :1163 guard, during observation persistence at :1167, before object sampling. The unmodified final try-block returns changed=true and sets complete_commit while accounting still declares the original hash. The simulated committed capture contains revised bytes, SHA-256 `a4c0754577ebb0087ab48fedb4287f544190db99977364ab8264fc5c0cdd0fec`.
  Affected scope: newly created/owned captures that change after the accounting SHA-256 guard and before expected Git objects are sampled; filesystem capture edits are not excluded by the canonical DB WriterLock. This does not refute the fixed canonical-rating writer exclusion.
  Falsifier: inject exactly this edit at observation persistence in a disposable full clone. Expect a hold with the revised document preserved and no complete checkpoint; staged/committed capture SHA-256 must match declared accounting before any completion. A quiet run must still complete with equal hashes. If the actual boundary excludes that edit or already holds, this finding is disproved.
  Probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY'` (inline AST extracts prepare_weekly's unmodified final try-block :1144–1190 into `probe`; Path/files, WriterLock, ledger, persistence and Git effects are in-memory stubs. Persistence at the observation path optionally edits the capture; staging snapshots live objects, commit snapshots staged objects. Git object tokens use deterministic SHA-1 equality, not actual Git execution. Run quiet control first, then injection). Exit 0. Decisive output: quiet `accounting_sha256 == live_sha256`, changed=true; injected `accounting_sha256=5731bfa0...d13902`, `live_sha256=a4c07545...d0fec`, `changed=true`, `complete_commit=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb`, `committed_capture_matches_live=true`. No real document, ledger, lock or commit was created. Actual interprocess/filesystem/Git behavior remains [Unverified — needs clone run].
  Root cause: expected capture objects are resampled after the accounting guard without binding those objects to declared evidence; Fix site: final staged/committed accounting validation; Why not upstream/downstream: discovery cannot constrain subsequent local owner edits, and downstream complete receipts have already certified inconsistent bytes.

- [Pass] **Round 1 title input now holds at the weekly boundary.** `planner_core.py:813–824` uses the canonical parser; `:1094` invokes the hold before a missing row's registration. In-memory extraction of `require_unrated_title` with the real imported releases parser returns `unrated-accepted` for `Fix intake` and `new issue title contains canonical rating tokens; explicit reconciliation required` for `Fix rated 90/90/90/90 ovr 399`. Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` (importlib loads guarded canonical module; AST compiles only the nested title checker; calls the two inputs). Exit 0. Existing matched rows bypass new-title validation and retain the owner path (`:1090–1094`); producer fixture results independently report registered_numbers [1] for the held candidate (`accumulation-blocker-results.json`).
- [Pass] **Round 1 canonical-writer exclusion is present.** `planner_core.py:1145` holds canonical WriterLock across generation/branch/HEAD checks, staging, commit and completion; `:1146` refuses a journal. `releases_app.py:375–424` supplies the same repository lock used by perform_write. Producer's retained staging-writer control reports old CLI exit0/live321/accounting320 versus candidate exit4/live320/accounting320 (`accumulation-blocker-results.json`, `accumulation-blocker-controls.log`). This is source/evidence review, not independent interprocess reproduction or a blanket concurrency pass.
- [Pass] **Canonical rating projection remains truthful.** `releases_app.py:4429–4441`, reused at :4460 and :4473, returns unrated axes/calc/rank all null, and for axes90/80/70/60 plus override399 returns calc300/rank399. The same guarded-module in-memory command above called the helper; exit0, decisive output `"rating_calc":300,"rating_rank":399`. Authoritative Marathon override repair remains held.
- [Pass] **Round 1 provenance finding is addressed.** Read-only hashlib/JSON probe found all four accumulation source hashes equal current bytes and all nine accumulation/ledger-related provenance artifact hashes matching. Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` (read accumulation-results source_hashes and every provenance JSONL row; compare hashlib.sha256 for accumulation/ledger artifacts). Exit0. Decisive output: all source_hashes true; all selected `hash_matches:true`. `provenance.jsonl` identifies old39c065ab versus candidate source hashes, baseline d7ef2bc973c18970dc458a403a2115209e06c672, and explicitly labels candidate145 as before latest fixes and temporary drivers unavailable. This validates attribution/hashes, not the claimed execution itself.
- [Unverified — needs clone run] The corrected final classified gate remains pending according to Producer Round 2 and SUMMARY.md. Retain first failed-run evidence; obtain final candidate covering-suite/gate evidence after the capture fix, with unchanged clone identity and exact sources. No suite was run in this reviewer checkout. Complete the remaining releases_app direct sweep before approval.

Handing off to Producer (author) — disposition the capture-accounting blocker, preserve the changed document, retain an actual full-clone red/control receipt, then request Round 3 review. Remaining whole-module direct sweep and final exact-source gate evidence remain outstanding.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
