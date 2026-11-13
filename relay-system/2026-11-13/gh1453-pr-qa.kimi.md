# RELAY · GH-1453 PR 1454 QA (Kimi)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1453-pr-qa.kimi): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: pull request 1454 as pushed, head `e93925f31`, against base `6c0c76bb5` (`development`). In this worktree: `git diff 6c0c76bb5 e93925f31 -- utils/py/jog_run.py skills/2-daily/jog/SKILL.md CHANGELOG.md LESSONS-LEARNED.md` (if git is unavailable to you, read the current files; they are at that head apart from this thread). Product code is one file: `utils/py/jog_run.py`, class `JogCheckpoint` and its two call sites in `jog_run_main`.
- Reviewer: kimi (`kimi-code/k3.1-pro`)   ·   Producer: claude
- Started: 2026-11-13
- You are a **fresh, independent second reviewer**. Codex reviewed the plan and the code earlier (`relay-system/2026-11-13/gh1453-plan-qa.md`, `gh1453-final-qa.md`, `gh1453-text-delta-qa.md`). Do not defer to those threads; read them only after forming your own view, to check whether anything they passed is wrong. Two parts of this PR have had **no** independent review and deserve the most attention: (a) commit `0e8ade643`, which switched three read-only ledger reads in `JogCheckpoint` from `sqlite3.connect(...mode=ro)` to `releases_app.connect(path, readonly=True)` after the gate refused new direct connect sites; (b) the final wording of the skill section "Checkpoint publication (`--checkpoint-root`)" and of the plan doc's "Text review after approval", which were corrected after Codex's last round.
- What the PR claims: a `jog run --checkpoint-root` wake starts from the primary's local state, and at publication reconciles a `development` that moved meanwhile (merge it, take the remote ledger, replay the wake's own `jog-lease` / `jog-<status>` writes read from `op_receipts`, run `utils/releases-merge-resolve.sh`, publish), stopping only with `jog: checkpoint held: <message>` and exit 2. Plan of record: `PROJECT/2-WORKING/GH-1453-JOG-LOCAL-RECONCILE.md`. Evidence: `TESTS-RESULTS/2026-11-13+GH-1453/` (`SUMMARY.md`, `candidate-A1-A14.log`, `base-red-controls.log`, `a6-skill-text.log`, driver `fixture-checks.py.txt`).
- Operational envelope: a local developer CLI, one operator per primary clone, other sessions pushing to the same `development`. Grade against the issue's acceptance and commensurate complexity, not enterprise or multi-tenant threat models. The repo forbids new tests, suites or gate machinery (AGENTS.md *No new tests*, GH-831); do not ask for one. You may run narrow read-only probes under `.relay-scratch/`; do not run `validate.sh`, `test/*.sh`, pytest or the fixture driver here, and mark anything that needs them `[Unverified — needs clone run]`.
- Definition of Done: the code does what the PR claims without a path that loses ledger rows, publishes a wrong ledger, or leaves the primary dirty or mid-merge; the skill text is true of the code.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading source or the earlier threads.
Read ONLY the plan doc's `## Plan`, `## Acceptance`, `## Risks`, `## Implementation notes`, `## Text review after approval`, `## Gate-driven change after approval`. Then write at the top of your block: **What this delivers**, **How the existing system works, per this document**, **What it's not**, **Input boundary**.

### Step B: source-backed validation
Read `utils/py/jog_run.py` `JogCheckpoint` in full and `jog_run_main`'s two checkpoint call sites; `utils/py/releases_app.py` `connect` (about line 432), `perform_write`, `jog_acquire_lease`, `jog_set_status`, `_rebuild`; `utils/releases-merge-resolve.sh`; the skill section; the evidence logs and driver. Answer each with `file:line`:

1. **The unreviewed gateway change.** `connect(path, readonly=True)` builds `file:<quoted abspath>?mode=ro`, sets `row_factory = sqlite3.Row`, runs `PRAGMA foreign_keys = ON`, and calls `refuse()` (a `SystemExit`) when the file is missing or the pragma does not take. For each of the three call sites (`_queue`, `_anchor`, `_replay`'s read of the extracted source DB): is behaviour unchanged from a plain read-only connect? Check tuple-unpacking of `sqlite3.Row`, the JSON round-trip of the `queue` snapshot, paths containing spaces or `#`/`?`, and whether a `SystemExit` from `connect` can now escape `_reconcile`'s `except` (which does not catch `SystemExit`) and leave a merge open. If it can, say exactly which call, and whether the recorded-ownership restore on rerun covers it.
2. **Correctness of the reconcile.** Trace `finish()` → `_reconcile()` → `_replay()` → `_push()`. Find any path that (a) publishes the wake's ledger over the remote's without replay, (b) replays the same receipts twice into one ledger, (c) drops a remote row, (d) commits with the primary dirty, (e) leaves `MERGE_HEAD` behind on a handled failure, or (f) lets the journal and `HEAD` disagree after a stop. Give the concrete sequence or say none found.
3. **The overlap rule.** `_replay` compares, for each queue row the wake wrote, the remote row's `(status, attempt_count, failure_reason)` with the values recorded at start. Name a remote change to one of the wake's rows that this comparison misses (for example a change to `position`, `lease_pid`, or a row deleted and re-added with the same three values) and say whether missing it can corrupt the published queue.
4. **Receipt identification.** The wake's writes are the `op_receipts` rows with `id` greater than the anchor row's `id`, in the source commit's database. Can a write made by another process in the same primary during the wake, or a `releases check` recovery, make this set wrong in a way the op whitelist (`lease`, `completed`, `parked`, `failed`, `pending`) does not catch?
5. **Merge ownership.** `finish()` restores an open merge only when `MERGE_HEAD` equals the journal's `merging` and `HEAD` equals the journal's `commit`. Can it abort a merge that is not this wake's, or refuse one that is?
6. **Evidence.** Does each of A1–A14 in `candidate-A1-A14.log` observe the behaviour it names, reading from the right place? Is any red control in `base-red-controls.log` red for an incidental reason? The existing suites were run before the last code changes: is that a real gap for this diff?
7. **Skill text.** Is every sentence of the "Checkpoint publication" section true of the code? In particular the definition of "competing writer" (three cases), the scope sentence about what the closed list does not override, and "At a stop" (start stop versus publication stop). Is any Jog-authored checkpoint stop missing from the list?
8. **Anything the earlier reviews passed that you think is wrong**, and anything over-built for this problem.

Write graded findings (`[Blocker]` / `[Should]` / `[Nit]` / `[Pass]`), each behaviour-change request with `Observed input:`, `Affected scope:`, `Falsifier:`. Then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · kimi

- **What this delivers:** an opt-in Jog checkpoint that starts from committed local state, then publishes directly when `development` is unmoved or merges a moved remote and replays only this wake's ledger operations before publishing. A committed but unpublished wake retries publication without dispatching more work; handled failures stop with a stable checkpoint message and leave a retryable journal.
- **How the existing system works, per this document:** `.tick/jog/checkpoint.json` records the base, immutable replay-source commit, starting receipt anchor and queue snapshot, plus the current publication head. At publication Jog fetches `origin/development`; if it moved, Jog merges in the primary, takes the remote SQL dump, rebuilds, checks overlap, replays whitelisted wake receipts through the canonical writers, resolves the ledger/views, commits once and pushes through the publication clone. Open-merge failures are restored; failures after a merge commit retain that commit for retry.
- **What it's not:** this is not a general multi-writer transaction system, a force-push/reset recovery, or a replay of arbitrary ledger operations. It does not automatically reconcile an orphan-lease scan or operator queue verbs, does not promise to preserve the wake's queue positions for untouched rows, and does not turn predicted conflicts or unrelated task/gate/other-Jog errors into checkpoint stops.
- **Input boundary:** a fresh wake requires the primary pin, a local `origin/development` ref, no unpublished local commit, and no dirt outside the owned ledger/view files. Replay accepts only post-anchor `jog-lease` and `jog-completed`/`parked`/`failed`/`pending` receipts from the source commit, and only when each targeted remote row still matches its recorded start `(status, attempt_count, failure_reason)`; non-checkpoint failures remain outside the closed checkpoint-stop list.

swept file: yes

Scope: read all of `utils/py/jog_run.py`, the required `releases_app.py` writers/rebuild/gateway, the full resolver, the final skill text, the manual driver and all retained logs. I formed the findings before reading the three earlier review threads. No additional pre-existing runtime defect was established outside the findings below.

### Findings

- **[Should] F1 — the new gateway can bypass open-merge cleanup with `SystemExit`.** `connect(..., readonly=True)` calls `refuse()` for a missing DB or failed foreign-key pragma (`utils/py/releases_app.py:432-446`), and `refuse()` raises `SystemExit` (`:209-211`). The reads in `_replay` (`utils/py/jog_run.py:2360-2361,2387,2404`) run inside `_reconcile`, whose handler excludes `SystemExit` (`:2341-2345`); unlike the writer calls at `:2394-2403`, these reads have no conversion. The observed result is a traceback with the merge left open, not the promised cleaned checkpoint stop. The recorded `merging` target does let a rerun restore it at `:2213-2222`, but that does not make the initial stop clean.
  Observed input: an open recorded merge followed by `_queue()` on a missing DB. Probe: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 .relay-scratch/tmp/gh1453-systemexit-probe.py`, exit **0**; decisive output: `{"during_reconcile_exception": "SystemExit", "exit_code": 3, "abort_called": false, "journal_merging": "live"}` and `{"recorded_retry_abort_called": true, "journal_merging_after_restore": null}`. The probe used the real class and gateway with git effects intercepted; no real merge ran.
  Affected scope: missing-file or pragma refusals from any gateway read during `_replay`; `_anchor()` at `:2172-2178` is before a merge and has no restore obligation.
  Falsifier: inject the same refusal in the existing disposable manual fixture; a correct fix prints `jog: checkpoint held:`, exits 2, removes `MERGE_HEAD`/backup, restores the checkpoint tree, and remains retryable. Normal reads must retain the passing compatibility behavior below. Fix: convert `SystemExit` at the `_reconcile` boundary and run the existing abort/save path. **[Unverified — needs clone run]** for the filesystem-level outcome.
- **[Should] F2 — the final “competing writer” prose promises stops that the comparison and whitelist do not provide.** First, a remote `jog bump GH-N` on a pending row at position 2 changes its position to 1 while leaving `(status, attempt_count, failure_reason) = ('pending', 0, NULL)` unchanged (`utils/py/releases_app.py:4880-4887`). `_queue` snapshots only that triple (`utils/py/jog_run.py:2161-2168`), so `:2387-2392` does not stop, contrary to `skills/2-daily/jog/SKILL.md:179-183`. I found no queue corruption from this miss: the remote order is retained and the canonical status writer adjusts positions (`releases_app.py:5124-5128`), but the broad stop claim is false. Second, `jog resume` can write a supported `jog-parked`/`jog-completed` receipt through `jog_set_status` (`utils/py/jog_run.py:797-804`; `utils/py/releases_app.py:5132-5133`). `_replay` accepts that receipt at `utils/py/jog_run.py:2376-2384`, so an operator queue verb in the primary does not necessarily stop as `SKILL.md:183-184` says; it can be included in the replay set.
  Observed input: (a) the position-2 row above, remote-bumped after the wake snapshot; (b) a valid terminal Marathon result re-projected by `jog resume` after the anchor, producing a whitelisted status receipt.
  Affected scope: same-row position/lease-only remote changes and supported lease/status writes by another process in the primary. Ordinary `releases check` crash recovery adds no `op_receipts` row (`utils/py/releases_app.py:1954-1965`), so it does not itself enlarge the set; an unsupported local op is stopped by the whitelist.
  Falsifier: a remote bump with an unchanged triple either must produce the documented overlap stop or the text must explicitly limit overlap to the triple; a supported `jog resume` receipt either must stop or be documented as replayed. Prefer the narrow wording correction rather than a new session-identity framework. A3's status-overlap stop and disjoint control must remain unchanged.
- **[Should] F3 — “At a stop” still gets the start/publication distinction wrong for a retained journal.** `skills/2-daily/jog/SKILL.md:243-245` says that after a start stop no journal was kept and rerun is an ordinary start that may dispatch. A committed, unpublished journal can already exist when the constructor rejects an invalid publication root (`utils/py/jog_run.py:2126-2134`), which the skill lists as an “At start” stop (`SKILL.md:206-212`). After fixing the root, `begin()` sees `phase == "committed"`, calls `finish()`, and returns False (`utils/py/jog_run.py:2182-2189`), so the CLI returns before dispatch (`:2575-2577`).
  Observed input: retained `phase: "committed"` journal plus `checkpoint root must be a separate full clone with the same origin` on the next invocation.
  Affected scope: every listed start refusal that occurs before a fresh journal replaces an existing one, including constructor and `check_owned()` refusals.
  Falsifier: with the retained committed journal above, a corrected rerun must retry publication without dispatch; only a genuinely fresh start with no retained unpublished journal may dispatch. Fix the prose to that distinction; no code change is needed.
- **[Should] F4 — CHANGELOG retains the unsafe wording the final skill correction removed.** `CHANGELOG.md:16-18` still says “closed list ... by exact message (anything else: continue)”. The actual list contains message starts with appended details (`skills/2-daily/jog/SKILL.md:195-199`), and observed failures such as a live supervisor-lock refusal (`utils/py/jog_run.py:1530-1536`) or failed task (`:2687-2693`) must not be continued past, as the corrected skill itself states at `SKILL.md:201-204`. Fix the changelog to say fixed message prefixes, no invented checkpoint stops, and other observed errors are reported; keep it scoped like the skill.
- **[Nit] F5 — recorded merge ownership still has one same-identity ambiguity.** After a crash leaves `state['merging'] = X`, an operator can abort that merge, manually open a different merge of the same X while HEAD remains the journal commit, and rerun. The checks at `utils/py/jog_run.py:2213-2222` will abort the operator's replacement, although A14 covers only a different target (`TESTS-RESULTS/2026-11-13+GH-1453/fixture-checks.py.txt:505-531`). The earlier review noticed and accepted this under the single-operator envelope; I agree that no new ownership framework is warranted, but the skill's absolute “Jog only restores a merge it opened itself” (`skills/2-daily/jog/SKILL.md:224-225`) should say “a merge matching its recorded target and HEAD” or explicitly disclose this limit.
- **[Nit] F6 — A6's provenance names a pre-final-text revision.** `TESTS-RESULTS/2026-11-13+GH-1453/provenance.jsonl:3` records `tested_rev: 33c8682c3...`, while the plan says the corrected wording came after that review (`PROJECT/2-WORKING/GH-1453-JOG-LOCAL-RECONCILE.md:361-380`) and `SUMMARY.md:25` calls this the final wording. Correct the receipt to the actual final-text revision (or separate code and text revisions); the log itself is nonempty and checks both directions.

### Source-backed checks that passed

- **[Pass] Normal gateway behavior is unchanged.** `connect` percent-quotes the absolute path and enables URI read-only mode (`utils/py/releases_app.py:437-445`); `sqlite3.Row` supports the tuple unpacking used at `utils/py/jog_run.py:2167-2168,2175-2176,2376`, and `_queue` already returns JSON-compatible lists. Read-only probe command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -` (copying the seeded DB only into scratch and calling `releases_app.connect`), exit **0**. For both `plain.db` and `space # question?.db`, decisive output was `row_type: Row`, `tuple_unpacked: [1315, "pending", 0, null]`, with the same JSON round trip; the missing-path control returned `missing_path_system_exit: 3`, which feeds F1.
- **[Pass] No additional normal-path reconcile loss or duplication found.** When the remote dump changed, `_replay` replaces the local dump with the remote bytes before rebuild (`utils/py/jog_run.py:2323-2325,2351-2356`), so the wake cannot simply overwrite the remote ledger. Every attempt rereads receipts from immutable `source` (`:2357-2374`) onto the newest remote dump, avoiding cumulative replay; final touched/untouched triples are checked at `:2404-2409`. Code-only movement intentionally retains checkpoint ledger bytes (`:2323-2326`). Dirt is refused before checkpointing and after a recorded commit (`:2223-2238`); handled open-merge failures stage/abort/clear (`:2299-2305,2341-2345`), post-commit stops retain the journal head (`:2346-2348`), and the first-parent/message rule covers commit-before-save (`:2224-2232`). F1 is the exception to the handled-failure result; no other concrete skipped replay, double replay, dropped remote row, dirty commit, stale `MERGE_HEAD`, or journal/HEAD disagreement was found.
- **[Pass] The acceptance logs observe their named behaviors from the intended artifacts.** A1/A2/A7 read the bare origin's DB and include a different base observer value (`candidate-A1-A14.log:3-30,83-97`; `fixture-checks.py.txt:157-170,227-235`). A3 measures named overlap, exit 2/no traceback, restored tree and unchanged remote (`candidate-A1-A14.log:32-48`); A4 parent/subject/output (`:74-81`); A5 no-dispatch retry (`:50-62`); A6 both text directions (`a6-skill-text.log:1-52`); A7 two reconciles and attempt count 1 (`candidate-A1-A14.log:83-97`); A8 merge parents and byte-equal ledgers (`:99-109`); A9 adopted-view commit plus foreign-dirt refusal (`:111-118`); A10 unchanged receipts/running B and same published merge (`:120-138`); A11 partial-output restore and retry (`:140-153`); A12 regenerated conflicted view (`:155-168`); A13 recorded open merge followed by clean publication (`:170-185`); A14 preservation of a different-target operator merge (`:187-196`). A13 uses injected `KeyboardInterrupt`, A11 direct partial writes, and A3 direct-class tracebacks are separately normalized through the CLI, all accurately disclosed in `SUMMARY.md:48-63`.
- **[Pass] Red controls and existing-suite scope are truthful.** Base A1 rejects the moved push with a committed journal, A2 hits the old equality check, A9 refuses the adopted view, and A10 shows the orphan receipt/row reset; A4 passes as preservation (`base-red-controls.log:3-44`). These are the intended mechanisms, not incidental setup failures. The old suites do not exercise `--checkpoint-root` (`SUMMARY.md:65-69`), so their pre-fix timestamp is not a hidden checkpoint-coverage gap: A1–A14 were rerun on the gateway revision. They only support the unchanged surrounding Jog code; the final full gate remains required.
- **[Pass] The closed list is mechanically complete, and the implementation is proportionate.** All 23 `ContractError` literals are represented by the 22 listed prefixes (`a6-skill-text.log:1-47`); F1–F4 concern exception cleanup and semantic prose, not a missing literal. Reuse of `JogCheckpoint`, canonical writers and the existing resolver (`utils/py/jog_run.py:2394-2403,2326-2334`) is commensurate; no new subsystem, suite or gate is needed. Apart from the explicitly bounded F5 case, I found nothing in the earlier approvals that should be reversed.

**VERDICT: FAIL**

**Basis:** F1 leaves an open merge and traceback on a newly introduced gateway refusal. F2–F4 make the final user-facing stop contract false for concrete supported inputs. Normal reconciliation and the retained A1–A14 evidence are otherwise strong, and no broader redesign is justified. Because this is round 1 / 1 without approval, the relay is Escalated to the Producer.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
