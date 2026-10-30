# RELAY · GH-1257 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-29.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh1257-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1257-BACKLOG-WAVE-PILOT.md`
- Also read (the code the plan cites): utils/py/harness.py (factory-primitive: TOOLS, rules_decide, execute_tool, init_instance, _snapshot, _validate, _run_tool, _verify_output, run_tick, status); utils/py/_marathon_plan.py (Engine init, _resolve_gh, _gh_state, _file_existed_at_base_ref, _branches, _load_ledger_from_db, run); utils/py/marathon_plan.py; PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md; issues #1248 and #1257.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-29
- Operational envelope: a local, single-operator, read-only experiment on an unmerged spike branch. Grade against the plan's stated requirements and commensurate complexity; do not demand multi-tenant or enterprise machinery. XYZ-forge forbids new test suites (AGENTS.md, GH-831): verification is existing suites plus manual controls under `TESTS-RESULTS/`.
- Definition of Done: the plan is grounded in the actual code paths; it extends the existing executive and the existing planner (no second planner, writer or suite); its read-only and offline claims hold; its acceptance criteria are falsifiable; ordering, rollback and blast radius are sufficient; the rating 60/35/50/45 is reasonable.
- Questions:
  1. Is splitting `Engine.run` into `compute()` + render, and extracting `_pack_waves`, truly behaviour-preserving, and do `test/marathon-plan.sh`, `test/gh698-planner-db-ratings.sh` and `test/gh362-marathon-plan-link-bullets.sh` cover that? Is there a smaller way to reuse the engine?
  2. Inside the `sandbox-exec` profile (harness.py `_run_tool`), will `Engine` work offline: `router_audit.parse_pdda_mode`, the read-only `git cat-file` / `git branch` subprocesses, the stub gh mode? Anything that writes or needs network?
  3. Is the init-time backlog seed (SQLite backup copy of `releases.db`, one read-only `gh issue view` per candidate, per-instance manifest) consistent with `_snapshot`'s slot-synchronisation check and with the "repository byte-identical" claim?
  4. Is the draft write set (existing repo paths cited in the issue body or capture doc, each with its source line; otherwise `needs-recon`) a sound, honest heuristic for this pilot? Is the provisional wave packing clearly separated from the planner's real waves?
  5. Is the `_verify_output` → `uncertain` + quarantine change correct relative to `_reconcile` and the issue's no-retry rule?
  6. Is anything required missing, or anything planned that should be cut?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**VERDICT: FAIL**

**Basis:** Revise the plan before implementation. Reusing `Engine` and the existing executive is the right bounded approach, but the proposed integration omits consumption and complete output verification, and provisional packing inherits a dependency fallback that is unsafe to describe as disjoint waves. These are plan findings from source inspection, not claimed runtime reproductions.

swept file: yes

Read the entire GH-1257 plan, the cited GH-1248 plan, both live issue bodies, the planner engine/wrapper and the relevant executive paths. Pre-existing defects relevant to the new tool are included below. Graph tools were unavailable; direct source reads were used. No git commands, suites, executable fixtures or harness runs were performed.

- **[Should] F1 — Complete the plan-request lifecycle and revision identity (plan steps 2–3; `utils/py/harness.py:597`).** Adding the four named dispatch/validation hooks leaves `consumed=[]` for `plan-draft`: only note, summarize and probe populate it. Thus the oldest successful request remains eligible at the next slot, starving later candidates. Specify `inbox_id` as the intent argument (so existing reconciliation can recover it), and consume it in the same `finish` transaction as the verified receipt. Define request identity from issue number plus frozen revision/hash; AC4 currently checks completed *tick* replay whereas issue #1257 requires completed *issue revision* replay.
  Observed input: the exhaustive consumption branch at `harness.py:597–606`, together with plan line 79's new `plan-draft` tool and oldest-pending rule.
  Affected scope: successful plan-request completion and repeat delivery of the same frozen issue revision within an instance.
  Falsifier: in the disposable clone, seed two requests; slots 1 and 2 must consume different IDs, slot 3 must not draft either again, and replaying the same revision must create no second brief. Distinct revisions must remain distinguishable.

- **[Should] F2 — Close the other ambiguous-attempt retry path (plan step 4; `utils/py/harness.py:584`).** The proposed fix covers rc=0 followed by bad verification, but timeout/nonzero returns bypass verification and finish `failed` without quarantining. With the new multi-file tool, a process can write its brief and then time out or fail while refreshing the proposal. The input is then selectable again. Specify conservative `uncertain` plus quarantine for such ambiguous `plan-draft` attempts; retain the original rc/error in the tool-run record. This can be scoped to the new tool without changing proven no-effect failures of the synthetic tools.
  Observed input: `completed.timed_out or completed.rc != 0` at `harness.py:584–590` records `failed`; `rules_decide` permits another attempt until two failures (`harness.py:158–185`). The proposed writer at plan lines 81–82 writes four files sequentially.
  Affected scope: plan-draft attempts that may have published any output before a timeout or nonzero termination.
  Falsifier: a clone control that writes the brief and then terminates unsuccessfully must leave the input quarantined and absent from later decisions; a documented provably pre-launch rejection need not become uncertain.

- **[Should] F3 — Define verification and cumulative-publication semantics for all four outputs (plan steps 3–4).** `_verify_output` currently validates only `<tick>.json` for a non-note tool and only checks tick/status (`utils/py/harness.py:476–489`). A missing Markdown brief or corrupt proposal therefore does not fail it. Extend this existing verifier for the new tool, bind outputs to the requested issue/revision and source hashes, and record hashes covering all required artifacts. State how subsequent proposals select completed, verified drafts and exclude partial/quarantined attempts; do not treat every file in `out/plan-draft` as accepted evidence. Publishing the cumulative pair through temporary files and replacement is sufficient for this single-operator pilot; no new store or gate is needed.
  Observed input: the four required output paths at plan lines 81–82 versus the one-path verifier at `harness.py:477`; the schema `{"tick_id":"slot_001","status":"ok"}` satisfies the current non-note checks without any brief content or proposal.
  Affected scope: plan-draft verification, receipts, and rebuilding a proposal after an interrupted attempt.
  Falsifier: clone controls deleting each required file or corrupting its identity/content must prevent completion; after a crash, a later proposal must contain only accepted revisions and explicitly account for excluded attempts.

- **[Should] F4 — Bound the extracted packer's existing mutation and no-progress behavior (plan lines 72, 82).** The current packer assigns `r["wave"]` in place (`_marathon_plan.py:1175–1177`), and on no progress it appends **all deferred lanes as one wave** (`:1164–1169`), even when dependency checks prevented placement. Merely adding drafted records to `active` does not rerun blocked-dependency propagation or calculate their zones/seams from their draft paths. Specify a separate copied provisional record set, reuse the existing classification/zone/seam helpers, and hold unresolved/cyclic candidates out rather than inheriting that fallback into the proposal. Keep the normal CLI's behavior-preserving extraction separate from this provisional admission policy; do not silently change CLI semantics in this refactor.
  Observed input: the actual no-progress branch `if len(wave) == 0: waves.append(deferred)` and in-place wave assignment, plus plan line 82's instruction to add every sourced draft to `_pack_waves`.
  Affected scope: provisional packing when dependencies cannot be placed, and actual/provisional records shared by reference.
  Falsifier: clone controls with a held prerequisite or a two-lane cycle must yield held reasons, never a forced same-wave placement; provisional packing must leave actual waves and their wave fields unchanged, and a newly introduced shared spine must appear in provisional seams.

- **[Should] F5 — Restore the issue's brief and seed contract explicitly (plan steps 2–3 and AC2).** Issue #1257 Scope 2 requires “scope, acceptance criteria, existing plan refs, proposed lanes, declared write sets, dependencies and open questions”; the planned field list at line 81 omits scope/acceptance/open questions. Copy those from cited source spans, or mark missing evidence explicitly, without inventing steps. Scope 1 also says open **queued** candidates and source hashes/timestamps frozen into the manifest: line 75 admits both ready/needs-contract regardless of ledger section before GitHub state is known, and line 81 records `updatedAt` without specifying an issue-content hash. Restrict selection to Queue / parked intake; classify CLOSED/failed snapshot candidates honestly after the init read rather than calling them open. Specify issue-content hashes and the source revision/doc hashes in the manifest, with mismatch handling if live docs change. Use the canonical read-only gateway for the backup source as requested by the issue.
  Observed input: plan lines 75–77 and 81, contrasted with live issue #1257 Scope 1–2 and AC2 (“each with source hashes”); the engine retains `section` separately from `state` (`_marathon_plan.py:902`).
  Affected scope: seeded plan requests and the evidence-linked brief schema for the at-most-ten-candidate pilot.
  Falsifier: an in-progress row must not be seeded as queued; a CLOSED snapshot must be excluded with a reason; changing source body/doc bytes must change the recorded fingerprint or stop a mismatched draft; a source lacking acceptance criteria must visibly report that absence.

- **[Pass] Reuse and scope are proportionate.** The plan's “No new module, writer or suite” (line 70), rules-only decider and deferred adapters/watchdog match this pilot. A compute/render split is justified because the current JSON report emits findings and a summary, not the full classified records (`_marathon_plan.py:1251`). The three named existing suites cover sequencing/caps/dependencies, DB ratings, and ledger grammar (`test/marathon-plan.sh:101`, `test/gh698-planner-db-ratings.sh:160`, `test/gh362-marathon-plan-link-bullets.sh:61`). Their future passing result alone will not establish complete equivalence; retain a fixed-input base/candidate report, rendered-doc and exit-code comparison in the planned manual evidence, with no new suite.
- **[Pass] Offline design and slot manifest fit the existing seams by inspection.** `router_audit.py:41` only reads `.pdda-mode`; `_load_ledger_from_db` uses `mode=ro` (`_marathon_plan.py:770`); gh stub avoids live calls (`:441`, `:470`), and `deep=False` skips preflight (`:1022`). `gh_force="off"` takes precedence over a stub, so use stub mode with a valid frozen map when snapshot state is intended. `_snapshot` hashes all available IDs regardless of consumption (`harness.py:369`), so a per-instance slots manifest is compatible. The sandbox permits only output/tmp writes (`harness.py:464`). **[Unverified — needs clone run]** actual Seatbelt/Python/git-read compatibility, byte-identical repository evidence and all suite results remain implementation gates. No runtime success is asserted.
- **[Pass] Draft heuristic, rollback and rating are reasonable at this scope.** The explicit warning that sourced paths “can be incomplete” (plan line 101), mandatory draft label (line 83), no dispatch (frontmatter non-goals), and branch abandonment rollback (line 104) bound this experiment. `60/35/50/45` has a coherent medium-effort rationale (line 108). Preserve those limits; add an explicit Easy reversibility label if desired. Normalize cited paths to repository-contained paths and retain line provenance when implementing the existing heuristic; the issue's path-escape control remains required.

Review evidence: `gh issue view 1257 --repo HiQS-Labs/XYZ-forge --json number,state,title,body` exited 1 with “error connecting to api.github.com”; the read-only GitHub connector `github_fetch_issue(repository_full_name="HiQS-Labs/XYZ-forge", issue_number=1257)` and the corresponding #1248 call both succeeded and returned the issue bodies used above. Source reads exited 0. Scratch only under `.relay-scratch/`; no runtime probe results are being claimed.

Handing off to Producer (claude-a) — address or disposition F1–F5 in the plan, then open round 2; go to the Producer window and say 'take your turn'.

### Producer · Round 2 · claude-a

All five findings were checked against the cited lines and accepted. The plan (PROJECT/1-INBOX/GH-1257-BACKLOG-WAVE-PILOT.md, Plan steps 1–4 and AC2–AC4) is revised:

- **F1 — Implemented.** `plan-draft` args are exactly `{"inbox_id"}`; the request is consumed in the same `finish` transaction as the verified receipt (new branch beside harness.py:597–606). Request id is `gh-<n>-<12 hex of issue hash>`, so a changed issue is a distinct request and replaying a consumed id cannot redraft. AC2/AC4 now test request consumption and request replay, not tick replay.
- **F2 — Implemented, scoped to `plan-draft`.** Timeout or nonzero exit after the tool started becomes `uncertain` + quarantine, with rc/error kept in `tool_runs`. Synthetic tools keep today's `failed` path, so the 12-hour evidence stays valid.
- **F3 — Implemented.** `_verify_output` checks all four files for `plan-draft` (exist, parse, tick id and request id). The proposal is written via temp + replace and rebuilt from the current brief plus the briefs of accepted requests, whose paths the harness passes from completed `plan-draft` tool runs. Partial or quarantined attempts are excluded and named.
- **F4 — Implemented.** `_pack_waves(active, deduped, force_tail=True)` keeps the CLI's no-progress fallback; provisional packing passes `force_tail=False` and gets unplaceable lanes back as held. Provisional packing runs on copied records using the engine's zone and seam helpers, so actual waves and their `wave` fields are untouched. Step 1 adds a recorded base-vs-candidate report, rendered-doc and exit-code comparison.
- **F5 — Implemented.** Selection is limited to `Queue / parked intake`; CLOSED or unreadable issues are excluded with a reason after the init read. The manifest records DB, issue and doc hashes; a doc-hash mismatch at tick time fails the tool rather than drafting from changed input. The brief adds scope, acceptance criteria and open questions copied from headed source sections with line provenance, or listed as missing. The backup source opens through `releases_app.connect(readonly=True)`.
- Noted from [Pass]: use stub mode (not `gh_force=off`) with the frozen map; normalize cited paths to repository-contained paths.

Handing off to Reviewer (codex) — re-review the revised plan; go to the Reviewer window and say 'take your turn'.

### Reviewer · Round 2

**VERDICT: FAIL**

**Basis:** Two bounded plan corrections remain: make missing scope an admission failure, and finish F3's content verification and multi-artifact receipt contract. The design still fits the single-operator pilot; these changes require no new planner, suite or subsystem. This is plan QA, not an implementation or runtime verdict.

swept file: yes

Re-read the entire revised GH-1257 plan, GH-1248 plan, live issue bodies, the executive lifecycle and the cited planner/wrapper paths. The relevant pre-existing weak verifier remains covered by F3 below; no additional unrelated pre-existing defect is asserted. Graph tools are unavailable, so evidence is direct source inspection.

- **[Should] F6 — Explicitly hold missing-scope drafts out of provisional waves (plan:82–83, AC2–AC3).** The brief now lists absent scope, but the admission rule only holds absent paths or unplaceable dependencies. A cited existing path does not establish scope. Issue #1257 Scope 2 says “unknown scope never enters a parallel wave,” and its AC3 requires a missing-scope control. Add that predicate before provisional packing; retain the brief and sourced paths as evidence, with a held reason. Specify a recorded manual control with a sourced path but no scope; do not discharge this control merely by saying the real sample lacked the case.
  Observed input: plan:82 explicitly permits scope to be “listed as missing” while constructing a write set from cited existing paths; plan:83 packs those briefs and plan:95 only explicitly holds no-write-set/unplaceable/cyclic records. The observed omission is in this plan, not a claimed execution failure.
  Affected scope: a candidate whose issue and capture doc provide no sourced scope, even if either mentions an existing repository path.
  Falsifier: in the disposable clone, a missing-scope candidate mentioning `utils/py/harness.py` must remain held; a comparable candidate with sourced scope and the same path must remain eligible subject to normal conflicts/dependencies. If this distinction is already specified elsewhere, cite it.

- **[Should] F3 — Partially addressed; specify content binding and hashes for the full output set (plan:82,85; `utils/py/harness.py:483–486,591–606`).** Four-file presence and matching tick/request IDs fix the missing-file case but still allow valid JSON with a wrong issue hash or omitted brief fields. The existing receipt stores one output hash, and the revised plan never says how all four artifacts are covered. Specify a small required schema tying the JSON brief to the frozen issue/doc fingerprints and required fields (including explicit missing values), agreement with the Markdown rendering, and a receipt containing each artifact's hash or an aggregate manifest hash covering all four. The cumulative pair is mutable: hash each verified version at completion, without later treating the current shared path as immutable evidence for an earlier receipt. Ship the writer and verifier contract together, scoped to this tool.
  Observed input: plan:85's exhaustive stated checks are “exist, parse, and carry the tick id and request id”; plan:82 requires issue/source hashes and planning content, but no verifier comparison is stated. Current `harness.py:484` validates only tick/status, and `:486` returns one file hash.
  Affected scope: accepting a plan-draft output set and recording evidence for its completion; existing synthetic tools retain their current contract.
  Falsifier: clone controls that preserve tick/request IDs but change the issue fingerprint, remove required planning content, or make Markdown disagree with JSON must prevent completion and quarantine. A valid four-file set must complete with verifiable hash coverage of all four; the next proposal refresh must not invalidate the earlier receipt's attribution.

- **[Pass] F1, F2 and F4 are addressed at plan level.** Plan:77,79 specifies revision-based request IDs and transactional consumption; plan:85 scopes timeout/nonzero/verification ambiguity to uncertain + quarantine; plan:72,83 preserves the CLI fallback while using copied provisional records and `force_tail=False`. Those directly cover `harness.py:597–606` and `_marathon_plan.py:1164–1177`. Plan:72 adds the fixed-input report/render/exit-code comparison needed beyond the three existing suites.
- **[Pass] F5's main seed and brief corrections are present.** Plan:74–82 now specifies the read-only gateway backup, Queue-only selection, CLOSED/unreadable exclusions, issue/doc fingerprints, doc mismatch handling and sourced-or-explicitly-missing sections. `releases_app.py:432–448` supports the proposed read-only connection.
- **[Nit] Pin the init-time engine's gh mode too (plan:75).** Before the frozen map exists, explicitly use `gh_force="off"`, `deep=False` for candidate selection. Otherwise Engine defaults to live and can call `gh issue view` for every ledger record before the intended one snapshot per selected candidate (`_marathon_plan.py:435–475`). The tick engine should keep the specified stub mode.
- **[Nit] Restore an explicit path-escape control in AC5.** “Repository-contained paths” at plan:82 is the right requirement, but plan:97 omits issue #1257 AC5's path-escape rejection check. Record a manual traversal/symlink escape control alongside the existing sandbox controls in the disposable clone.
- **[Pass] Scope and rating remain proportionate.** “No new module, writer or suite” (plan:70), no dispatch/adapters (plan:20–24), incomplete-write-set warning (plan:102), branch abandonment (plan:105) and the 60/35/50/45 rationale (plan:109) remain appropriate. Offline/read-only behavior still needs execution evidence; source inspection is not sandbox verification.

Evidence ledger: `nl -ba PROJECT/1-INBOX/GH-1257-BACKLOG-WAVE-PILOT.md` exited 0 and showed the quoted admission/verifier rules at 82–85 and ACs at 94–97. `nl -ba utils/py/harness.py | sed -n '476,490p;580,611p'` exited 0 and showed the current tick/status-only check and single-hash receipt. `nl -ba utils/py/_marathon_plan.py | sed -n '435,482p;1120,1188p'` exited 0 and showed default-live gh and the forced-tail mutation. Read-only GitHub connector fetches for #1257 and #1248 succeeded. Inspected LESSONS-LEARNED.md:38–43 on shipping verifier requirements with their producer. No git commands, suites, fixtures, harness execution or runtime probes were run. **[Unverified — needs clone run]** suite parity, Seatbelt compatibility, repository byte identity and all proposed manual controls remain implementation gates.

Root cause: the revised plan specifies output production more fully than admission and verification; Fix site: plan steps 3–4 and their existing manual controls; Why not upstream/downstream: these are plan contract gaps to close before implementation, not grounds for a new validator subsystem.

Handing off to Producer (claude-a) — address or disposition F6 and the remaining F3 requirements, note the two nits, then open round 3; go to the Producer window and say 'take your turn'.

### Producer · Round 3 · claude-a

Both remaining findings and both nits accepted; plan steps 2–4 and AC3/AC5 revised.

- **F6 — Implemented.** Provisional packing admits a brief only with both sourced scope and a sourced write set; otherwise it is held as `missing-scope`. AC3 now requires a recorded manual control: same cited path, with and without sourced scope.
- **F3 — Implemented.** The brief JSON has a fixed required key set with explicit null/missing values; Markdown is rendered from JSON by one function. For `plan-draft`, `_verify_output` checks required keys, request/issue/doc hashes against the manifest, a byte-for-byte re-render of the Markdown, and that the proposal names the current tick and request. The receipt records a hash per file, and `output_sha256` becomes a hash over the four, so a later proposal rewrite does not alter an earlier receipt's attestation. Controls added: wrong issue hash, removed key, Markdown/JSON mismatch.
- **Nit (init gh mode) — Implemented.** Init-time selection uses `gh_force="off"`, `deep=False`; ticks use stub mode.
- **Nit (path escape) — Implemented.** AC5 adds a `../` traversal and symlink-out control for cited paths.

Handing off to Reviewer (codex) — final round 3 of 3; go to the Reviewer window and say 'take your turn'.

### Reviewer · Round 3

**VERDICT: PASS**

**Basis:** Approve the plan for implementation in the stated local, read-only spike envelope. F1–F6 and both round-2 nits are addressed at plan level. The engine/executive reuse, bounded seed, explicit provisional admission and scoped ambiguity handling are proportionate. This is plan approval, not an implementation, sandbox or gate attestation.

swept file: yes

Re-read the entire GH-1257 plan, the GH-1248 plan, both live issue bodies, and the cited executive/planner/wrapper paths. Relevant pre-existing weaknesses (single-output verification, retry after ambiguous failure, consumption omission for a new tool, forced-tail packing and in-place wave mutation) remain explicitly covered by the plan; no additional material pre-existing defect was found in the reviewed scope. Graph tools are unavailable in this session; direct source reads provide the evidence, without a graph completeness claim.

- **[Pass] F6 closes missing-scope admission.** Plan `PROJECT/1-INBOX/GH-1257-BACKLOG-WAVE-PILOT.md:83` requires “both sourced scope and a sourced write set” and holds missing scope even with existing paths. AC3 at `:95` specifies the paired same-path control with and without scope. This directly addresses issue #1257's “unknown scope never enters a parallel wave.”
- **[Pass] F3 now binds production, verification and receipts together.** Plan `:85` specifies required brief keys with explicit missing evidence, manifest-matched request/issue/doc fingerprints, byte-for-byte Markdown re-rendering, proposal identity, and per-file plus aggregate hashes. Its corruption controls cover wrong hashes, removed keys and Markdown disagreement. This extends the existing `_verify_output` and receipt seams (`utils/py/harness.py:474–486,591–606`) without a second validator subsystem. A later cumulative proposal is a new version; the earlier receipt attests its recorded hashes, not the current bytes at that shared path. Runtime enforcement remains to be measured.
- **[Pass] The remaining lifecycle and planner corrections remain intact.** Plan `:77–79,85` specifies revision identity, transactional request consumption and uncertain/quarantine for ambiguous attempts; `_reconcile` already reads `inbox_id` (`utils/py/harness.py:435–441`) and `finish` owns transactional consumption (`:113–125`). Plan `:72,83` preserves normal CLI forced-tail behavior while using copied provisional records, existing zone/seam logic and a non-forcing packer. This addresses the current forced-tail and mutation branches (`utils/py/_marathon_plan.py:1164–1189`).
- **[Pass] Init and tick boundaries are sufficiently specified.** Plan `:74–81` uses the read-only gateway backup, Queue-only candidates, init `gh_force="off"`, tick stub mode and `deep=False`, CLOSED/unreadable exclusions, source fingerprints and doc mismatch rejection. These match `releases_app.py:432–446`, `_marathon_plan.py:435–470,766–807,1022–1030` and the slot digest seam at `harness.py:367–377`. AC5 (`plan:97`) now includes traversal and symlink escape controls. No new network or write authority is requested.
- **[Pass] Verification, scope and rating are commensurate.** Plan `:72,87,91–98` retains existing suites and recorded manual controls, including fixed-input base/candidate report/render/exit-code comparison. Existing coverage is visible at `test/marathon-plan.sh:101–128`, `test/gh698-planner-db-ratings.sh:160–168` and `test/gh362-marathon-plan-link-bullets.sh:55–81`; it is not complete equivalence proof. No new planner/module/suite (`plan:70`), deferred adapters/watchdog (`:64`), draft limitations (`:102`), branch abandonment (`:105`) and the 60/35/50/45 rationale (`:109`) remain appropriate.

Evidence ledger: source reads exited 0. In particular, `nl -ba PROJECT/1-INBOX/GH-1257-BACKLOG-WAVE-PILOT.md` showed `:83`'s “both sourced scope and a sourced write set” and `:85`'s “receipt records a hash per file”; `nl -ba utils/py/harness.py | sed -n '45,240p;285,379p'` showed consumption and receipt writes inside the same `with conn` at `:117–124`. Read-only connector calls `github_fetch_issue(repository_full_name="HiQS-Labs/XYZ-forge", issue_number=1257)` and the corresponding #1248 call both succeeded. Inspected `LESSONS-LEARNED.md:38–43`; the tightened verifier and its producer are planned together. No git command, suite, executable fixture or harness was run, and no runtime probe success is claimed.

**[Unverified — needs clone run]** Actual compute/render parity, Seatbelt/Python/git compatibility, byte-identical repository evidence, all negative controls and required gates remain implementation acceptance work in a disposable full clone. Approval does not discharge those checks.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
