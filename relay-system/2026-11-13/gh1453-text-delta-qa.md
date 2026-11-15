# RELAY · GH-1453 text delta QA
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
6. **Commit only the relay file** (`relay(gh1453-text-delta-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the text changes made **after** final QA approval, `git diff 2ed9abb57 07490ab50 -- skills/2-daily/jog/SKILL.md PROJECT/2-WORKING/GH-1453-JOG-LOCAL-RECONCILE.md CHANGELOG.md` (if you cannot run git, read the current files: the skill section "Checkpoint publication (`--checkpoint-root`)", the plan doc's Recon bullet "Where the stop came from", Plan steps 8 and 10, and the GH-1453 CHANGELOG entry). No file under `utils/` changed.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-13
- Why this round exists: the code and evidence were approved in `relay-system/2026-11-13/gh1453-final-qa.md` (round 3, attested at `2ed9abb57`). The operator then directed four text changes. The operator has allowed **one** review round on them; the Producer adjudicates your findings afterwards. Write everything you have in this one turn.
- The operator's four directions: (1) fix the source sentences that produced the stop (two hand-written lines on a downstream issue), not only the skill; (2) make the skill a **closed list**: "these are the only stops, by exact error string; anything else, continue", replacing a sentence that banned asking for a "quiet window", because a ban on one phrase does not stop the next invented rule; (3) define "competing writer" once, in the Jog skill, and tell run-directive authors to cite it instead of restating it; (4) correct the Observed record: the wording came from the operator's own issue checklist and directive, and the hold was 47 minutes, not a day.
- Operational envelope: skill and plan prose read by coding agents and by people writing run directives. Grade whether an agent reading the skill would act correctly. No new tests or machinery (GH-831).
- Definition of Done: the skill text is true of `utils/py/jog_run.py` `JogCheckpoint`, the closed list cannot be read as permitting an invented stop, and the definition of "competing writer" matches what the code enforces.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading source.
Read ONLY the skill section "Checkpoint publication (`--checkpoint-root`)". Then write, at the top of your block: **What this section tells an agent to do**, **What counts as a stop, per this section**, **What it's not**, and **Input boundary**.

### Step B: source-backed validation
Read `utils/py/jog_run.py` `JogCheckpoint` (and `JogSupervisorLock` and its use in `jog_run_main`), then answer with `file:line`:

1. Closed list: is every Jog-authored checkpoint stop in the code on the list, and is every listed message in the code? Is there any other way a `--checkpoint-root` run stops for a remote-related reason that the "anything else: continue" sentence would wrongly tell an agent to ignore (for example a stop printed without the `jog: checkpoint held:` prefix, a `SystemExit` from `_require_jog_primary`, or a traceback)? Name each with its line.
2. "Competing writer": the section says the supervisor lock refuses a second `jog run` in the same primary clone and the replay check stops on an operator queue verb on the wake's rows. Is each half true? Cite the lock and the check. Does the definition leave out a real competing-writer case, such as a second primary-pinned clone on another machine writing the same queue rows and pushing them?
3. Does "anything that is not on it is not a stop ... continue" overreach: could it be read as telling an agent to continue past a failed task, a failed gate, or a non-checkpoint Jog refusal? If so, give the smallest wording change that scopes it to checkpoint publication.
4. Is the instruction to directive authors ("cite this section; do not restate or paraphrase") placed where a directive author would find it, and is it consistent with the rest of the skill?
5. Plan step 10's two replacement sentences for the downstream issue: are they accurate against the skill and code, and do they avoid restating a stop condition in their own words?
6. Is the corrected account in the plan doc ("Where the stop came from") internally consistent with the rest of the doc and the CHANGELOG entry?

Write graded findings, then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

**What this section tells an agent to do:** run the bounded wake from primary local state, let publication reconcile moved development, cite this section in directives, and retry the same command after fixing a reported hold.
**What counts as a stop, per this section:** only a Jog-emitted `jog: checkpoint held:` message with exit 2 from the listed checkpoint reasons, plus the subsequent Git-command-failure category.
**What it's not:** predicted conflicts, remote movement alone, or unrelated sessions' ledger commits.
**Input boundary:** a `jog run --checkpoint-root <publication-clone> --max-tasks N` wake, its own queue rows in the primary, and its publication clone. The unqualified “Anything that is not on it is not a stop … continue” appears broader than that boundary.
_Step A recorded before reading implementation; source-backed findings follow._

swept file: no
Scope: read the entire Jog skill and GH-1453 plan, the entire GH-1453 CHANGELOG entry, all of `JogCheckpoint`, `JogSupervisorLock` and `jog_run_main`, and relevant primary/target/Git helpers. Historical CHANGELOG entries and unrelated `jog_run.py` functions were not exhaustively swept. Graph tools were unavailable; direct source reads supplied the evidence. Pre-existing prose defects found in the reviewed sections are included below; this is not a claim that the entire underlying runner has no other defects. No Git command, gate, test suite, pytest, or executable fixture was run.

- **[Should] F1 — Scope “continue” and make the closed list describe actual message families.** `skills/2-daily/jog/SKILL.md:192-195` says “Anything that is not on it is not a stop … continue.” Real refusals outside that list include the primary refusal at `jog_run.py:2537` (via `releases_app.py:4717-4722` and `harness_paths.py:177-184`), origin-mismatched execution target at `jog_run.py:543-544,2539-2542`, live supervisor lock at `:1530-1536,2550-2551`, execution-clone dirty exception at `:2619-2620` (outside the checkpoint handlers), and failed task / gate-derived park at `:2687-2693`. These must not become instructions to ignore observed failures. The class's named literal reasons are represented, and every listed fragment occurs in the code, but several are **prefixes**, not exact messages: e.g. `:2264-2265` appends `3 reconcile attempts; rerun the same command`, and `:2402-2403` appends the operation, issue and exit. Also `:2341-2345` converts `OSError`, `sqlite3.Error`, and `subprocess.SubprocessError` to `ContractError(str(exc))`; therefore “Any other message … is a git command that failed” (`SKILL.md:227-228`) is false. Missing/unreadable origin configuration in `primary_config_key` (`harness_paths.py:158-159`, called at `jog_run.py:2132`) can raise `CalledProcessError` before a checkpoint handler can normalize it; filesystem/JSON/SQLite failures in `begin` (`:2183,2206-2208`) can likewise produce a traceback. Smallest correction: say “For checkpoint publication, do not invent a hold from predicted remote movement; follow Jog's observed outcome. This list does not override task/gate failures, other Jog refusals, or unexpected errors.” Identify the enumerated entries as exact fixed prefixes with diagnostic suffixes (or full templates), and explicitly treat an unrecognized emitted error as an error to report, not permission to continue. Preserve the prohibition on invented stops; no new runtime machinery requested.
  Observed input: `jog_run.py:2341-2345` accepts non-Git exception text; `:2687-2689` prints `jog: stopping queue execution on task failure.`, a concrete unlisted outcome. Read command `nl -ba utils/py/jog_run.py | sed -n '2299,2767p'`, exit 0, decisive spans: `raise ContractError(str(exc)) from exc` and `print("jog: stopping queue execution on task failure.")`.
  Affected scope: only the skill/plan closed-list prose and its interpretation; checkpoint publication policy must not replace unrelated execution/error handling.
  Falsifier: a failed task or primary/target refusal must still halt its affected operation; a merely predicted conflict with no emitted failure must not halt a wake. An explicit exclusion already attached to “continue” would remove the scope finding; none is present.

- **[Should] F2 — The writer definition understates the protected input and overstates local replay detection.** `SKILL.md:179-183` restricts a competing writer to the same primary clone. The overlap check instead compares remote values with the saved start values for every touched issue, regardless of which clone/machine wrote them (`jog_run.py:2385-2392`). A second device can have its own primary pin (`harness_paths.py:156-174`) and local supervisor lock (`rtl.py:983-994`), push a change to the same queue row, and trigger that check. Conversely, the assertion “the replay check … stops on” an operator verb is conditional: replay is called only when development diverged and its ledger changed (`jog_run.py:2251-2267,2323-2325`); an unmoved branch goes straight to `_push`. Correction: define overlap once by the wake's own queue rows, including remote writers, distinguish the clone-local supervisor lock, and qualify unsupported-receipt detection as occurring when replay is required. Do not introduce a global coordinator or quiet-window requirement.
  Observed input: existing A3 evidence explicitly records a remote overlap on GH-1315, with a named hold and exit 2 (`TESTS-RESULTS/2026-11-13+GH-1453/SUMMARY.md:18`); `jog_run.py:2389` uses `remote.get(gh) != start.get(gh)`, without a same-clone predicate.
  Affected scope: changes to this wake's touched rows, versus disjoint remote ledger writes; local operator receipts only on the replay path.
  Falsifier: the recorded A3 no-overlap control (`SUMMARY.md:19`) must reconcile, while the recorded remote same-row case must hold. An unmoved remote must not be described as running replay. These are source/evidence checks, not freshly executed clone checks.

- **[Should] F3 — Step 10 duplicates the definition it promises to cite.** `PROJECT/2-WORKING/GH-1453-JOG-LOCAL-RECONCILE.md:244-247` proposes “as the Jog skill defines it (a second process writing this run's own queue rows in the same primary clone)”. The parenthesis is a paraphrase, contradicting both its own expected result and `SKILL.md:183-184`. The prerequisite replacement (`plan:241-243`) also restates exclusions rather than only pointing to the canonical conditions. Correction: keep the coordinator/gate operational constraint and replace the stop-policy text with a link to the Jog checkpoint section; remove the parenthetical definition and duplicated exclusion.
  Observed input: the exact parenthetical at `plan:245-246`, immediately followed by “expect neither sentence to restate a Jog stop condition in its own words.”
  Affected scope: the two proposed downstream replacement sentences only; do not edit the downstream issue in this review.
  Falsifier: the proposed sentences contain a resolvable canonical section reference and no copied definition/exclusion; currently the quoted parenthesis disproves that.

- **[Should] F4 — The universal retry promise is false for start-time holds.** `SKILL.md:230-234` says rerunning “retries publication first and dispatches no task” for all stops, including the start list. A fresh wake with no journal that fails `checkpoint requires a local origin/development ref` (`jog_run.py:2201-2202`) has not saved state; after repair, `begin()` saves a new running journal and returns True (`:2205-2209`), so dispatch is possible. Only the committed-journal branch calls `finish()` and returns False before dispatch (`:2182-2189,2575-2577`).
  Observed input: fresh wake/no journal plus absent local tracking ref, the literal start refusal at `jog_run.py:2202`.
  Affected scope: the “At a stop” recovery paragraph; distinguish pre-start refusals from a retained unpublished checkpoint.
  Falsifier: after fixing that pre-start refusal, a successful rerun may execute the scheduled tasks; after a committed publication hold it must retry publication without dispatch. Correction: limit the no-dispatch promise to retained unpublished checkpoints and state that a pre-start refusal reruns admission.

- **[Should] F5 — CHANGELOG's “only when” contradicts the closed list.** `CHANGELOG.md:10-13` says it stops only on same-row overlap, non-ledger conflict, or unreplayable writes. The concrete publication-clone dirty refusal at `jog_run.py:2275-2276`, already listed at `SKILL.md:223`, is a counterexample. Correction: describe those three as examples and point to the canonical section for the full list; do not create a second list.
  Observed input: `checkpoint publication clone is dirty; preserve it before retry` (`jog_run.py:2276`), absent from CHANGELOG's exclusive three-case statement.
  Affected scope: GH-1453 entry's exclusive stop claim.
  Falsifier: a dirty publication clone still refuses even without row overlap, file conflicts or unreplayable writes; the changelog must allow that outcome.

- **[Nit] F6 — “Contacts origin/development once” should say “only during publication.”** `SKILL.md:175` suggests a single contact; `jog_run.py:2247,2257,2268` fetches repeatedly, and `:2285-2286` reads the live ref during push. The intended phase boundary is sound, but “once” is inaccurate on retry/reconcile paths. Correct the word without adding a stop condition.
- **[Pass] Directive-author placement is discoverable.** The instruction is next to the definition at `SKILL.md:179-184` inside the clearly titled checkpoint section. Its cite-only policy is coherent; F3 concerns the proposed consumer text, not its placement.
- **[Pass] The corrected attribution and duration are internally consistent.** The plan's rating records 17:24–18:11 UTC and “47 minutes” (`plan:45-47`); “Where the stop came from” quotes the two source sentences and repeats 47 minutes (`:90-97`); step 10 explicitly identifies both as the operator's own text (`:238-240`). The GH-1453 CHANGELOG entry makes no conflicting authorship/duration claim. This establishes internal consistency only, not an independent verification of the downstream issue history.

**VERDICT: FAIL**
**Basis:** The prose still permits an agent to ignore real emitted failures, narrows the writer definition beyond the remote overlap check, and duplicates that definition in the proposed downstream fix. F4 and F5 are additional concrete prose/code contradictions. Findings request text corrections only. Runtime behavior and gates were not re-certified in this turn; any claim requiring execution remains **[Unverified — needs clone run]**.

Handing off to Producer (claude-a) — adjudicate these findings under the operator's one-round limit; no second reviewer round is implied.

### Producer · adjudication (operator's one-round limit; no further Reviewer turn)

The operator allowed one Codex round on this text and asked the Producer to adjudicate. Every finding is accepted. The corrected wording below has not been seen by Codex; that is stated in the plan doc ("Text review after approval") and will be stated in the PR.

- **F1 — Implemented, and it narrows the operator's literal wording.** The operator's instruction was "these are the only stops, by exact error string; anything else, continue". Your counter-inputs stand: `jog: stopping queue execution on task failure.`, the primary-pin and execution-clone refusals, the supervisor lock, and tracebacks from `begin()` are real outcomes outside the list, and several entries are fixed message starts with appended detail. The skill now says: for checkpoint publication a stop exists only when Jog prints `jog: checkpoint held:`; the list is closed and nobody adds to it; each entry is the fixed start of a message; a predicted conflict with no failed command is not a stop, continue; the list does not override a failed task or gate, another Jog refusal, or an unexpected error, which are reported verbatim and are never permission to continue. The catch-all now covers file and database errors as well as `git`. The operator's intent (no invented stops) is kept; the literal "anything else, continue" is not, and the plan doc records that difference for the operator.
- **F2 — Implemented.** The definition is now "anything else that changes this wake's own queue rows while the wake runs, from this clone or from another clone or machine", followed by how Jog handles each case: second `jog run` in the same primary (supervisor lock), same rows pushed from elsewhere (overlap stop at publication), operator queue verb in this primary (a stop when publication has to replay, that is when `development` moved).
- **F3 — Implemented, including on the downstream issue.** Plan step 10's sentences are reduced to a citation with no definition and no exclusion. The two sentences on LTVera-Pandas issue 1014 had already been edited with the first wording on the operator's go; they are now re-edited to the citation-only form. You asked that the downstream issue not be edited in this review: that edit is the operator's own text, made on the operator's explicit instruction, and leaving the inaccurate parenthetical there would have kept a second definition alive.
- **F4 — Implemented.** "At a stop" now separates a publication stop (rerun retries publication first, no dispatch) from a start stop (nothing ran, no journal; the rerun is an ordinary start and may dispatch).
- **F5 — Implemented.** The CHANGELOG entry names the three moved-branch cases as the main ones and points to the skill section for the full list.
- **F6 — Implemented.** "once" is now "only during publication".

A6 was rerun on the corrected text: 22 listed message starts all found in `JogCheckpoint`, all 23 `ContractError` literals listed, closed-list, scope and definition sentences present (`TESTS-RESULTS/2026-11-13+GH-1453/a6-skill-text.log`). No file under `utils/` changed in this thread.

Header left as the Reviewer set it (`STATUS: Escalated`): the Reviewer's verdict was FAIL and no Reviewer approval of the corrected text exists.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
