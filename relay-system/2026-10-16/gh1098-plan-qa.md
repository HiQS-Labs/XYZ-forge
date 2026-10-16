---
Goal: Plan QA — GH-1098 Shift outer loop Phase 3 (Scope A: four surgical fixes)
Date: 2026-10-16
NEXT: codex (Reviewer)
STATUS: Open
---

# Context

Adjudicate the plan in `PROJECT/1-INBOX/GH-1098-SHIFT-PHASE3.md` against issue #1098 Scope A (A1–A4). The plan is the artifact; no code has been written yet.

Operational envelope: local developer harness (XYZ-forge jog/marathon supervisor), single repo, one operator. Four edits of ≤ 15 lines each in two files. **No new tests, suites, registry entries or gate machinery (AGENTS.md "No new tests", GH-831)** — verification is existing suites plus manual checks recorded under `TESTS-RESULTS/`. Grade against the stated requirements and commensurate complexity; do not request enterprise fail-safes, new config surfaces, or refactors.

Read in full:
- `PROJECT/1-INBOX/GH-1098-SHIFT-PHASE3.md` (plan, verification table, Preflight Bet Check, contract)
- `utils/py/jog_run.py` lines 515–610 (`run_marathon_phase`: preflight resolution, dispatch env) and 1177–1245 (`promote_contract_to_working`)
- `utils/py/swarm_preflight.py` lines 1095–1140 (invocation builder), 1386–1395 (`gate_cmd`), ~1834 (packet `Gate:` line)
- `utils/py/harness_paths.py` lines 30–60 (`harness_home` precedence)
- `utils/py/agy-turn.py` lines 15–25 and 400–470 (idle bound, wall cap)
- `validate.sh` lines 780–900 (`--auto` classification, fail-closed)
- `utils/pdda/pdda.sh` line 40 (required 2-WORKING keys)

Evidence from Phase 2 the plan cites: issue #1081 comments of 2026-10-16 (runs 1–5), issue #1093.

Questions:

1. **Grounding.** For each of A1–A4, is the cited file/line/symbol the real seam, and does the proposed ≤15-line edit actually change the observed failure? Cite file:line where a claim is wrong.
2. **A1 completeness.** The plan prefers `root/utils/py/swarm_preflight.py` and exports `SWARM_PREFLIGHT_ROOT=root`. Does `swarm_preflight.py` honour `SWARM_PREFLIGHT_ROOT` for the doc glob and probe evaluation (not only `compute_default_root`)? Is the retry path at ~1728 covered? Is "log, don't refuse" on `harness_home() != root` the right call for vendored `.xyz/` installs?
3. **A2 minimality.** Filling `updated/owner/goal` at promotion (goal from `title` plus a visible marker) versus refusing promotion with the missing keys named: which is the smaller correct fix given unattended jog runs? Does the hoisted frontmatter rewrite risk touching docs that already carry the keys?
4. **A3 scope.** Setting `RELAY_TURN_IDLE_S` to the wall cap in jog's dispatch env (operator export still wins) — does it reach `agy-turn.py` through `marathon-drive` → `relay-drive` → shim unchanged? Any suite that pins the 300 s default and would go red? Is builder-only vs all-turns a real distinction here?
5. **A4 safety.** Rewriting the default full gate (`bash ci-local.sh` / `bash validate.sh` / `./validate.sh`) to `./validate.sh --auto <target.ref>` in the preflight packet: does `validate.sh --auto` run the right diff inside the marathon lane (what is HEAD at gate time, what is the base), does it fail closed to tier 3 when unclassifiable, and does the full gate still run on the pre-push hook so nothing lands with less than today? Should the rewrite be recorded anywhere besides the packet line?
6. **Verification table.** Are the named existing suites the ones that actually cover each seam? Is each red control real (reproducible on the parent commit) rather than illustrative?
7. **Rating.** `75/55/50/55` — grounded in the cited recurrence (one day's window, prior trend unknown)? Appeal neutral at 50 with no operator override?
8. **Over/under-build.** Flag anything in the plan that is speculative machinery, and anything the issue requires that the plan omits.

Rules for findings (GH-681): a `[Blocker]` or `[Should]` that asks for a behaviour change carries `Observed input:`, `Affected scope:` and `Falsifier:` lines; a `[Blocker]` cites an observed failure. Measure read-only only; no `validate.sh`/`test/*` runs in the relay worktree.

Write your verdict below (`**Verdict:** Approved` or `**Verdict:** Changes requested`) and set STATUS accordingly.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — 2026-10-16

**Verdict:** Changes requested

The two-file approach is appropriately small. A1 and A3 identify real seams; A2 should fill absent metadata rather than stop unattended promotion. A4 can reuse `validate.sh --auto`, but its safety explanation and the verification table need corrections before implementation. No source/artifact edits or suite runs were made.

### Findings

1. **[Should] Make the measured-run acceptance achievable without silently expanding Scope A.** Scope C repeats the issue's ≥2 PR-ready items from one unattended invocation with no auto-merge. Current `jog_project_marathon_outcome` returns `parked` at the first approved PR (`utils/py/jog_run.py:405–426`), and the supervisor immediately breaks (`:1717–1725`). `--max-tasks 3` is a ceiling, not permission to continue past that boundary. None of A1–A4 changes this. Resolve the acceptance contradiction explicitly with the operator/issue before claiming Scope C can pass; do not slip a queue-policy change into these four fixes.
   Observed input: Scope C's `releases jog run --reviewer codex --builder agy --max-tasks 3`, without `--auto-merge`.
   Affected scope: Scope C and goal/exit criterion 1; Scope A implementation need not grow.
   Falsifier: a source path or disposable-clone receipt showing the same invocation dispatching a second unfixed item after its first PR-ready result, without landing or operator intervention.
   Evidence command: `nl -ba utils/py/jog_run.py | sed -n '397,429p;1710,1728p'`; exit 0; decisive output: `return "parked", note`, followed by `jog: advancing halted at landing boundary.` and `break`.

2. **[Should] Replace the vacuous A2/A4 controls with reproducible before/after inputs.** The current GH-942 capture already contains `updated`, `owner`, and `goal`; unmodified promotion of that file cannot demonstrate three missing-key failures. In the disposable verification clone, deliberately remove those keys from a scratch capture before promotion, including a case with an existing Status table, and retain the failing parent and passing candidate results. A4's explicit custom-tier passthrough is a compatibility check that passes on the parent too. Its red control must instead use a default full gate and assert the actual dispatched `--pre-advance-cmd`/JSON `gate` is routed: parent should retain the full command, candidate should change it. Keep custom passthrough as the additional control. No new suite is needed.
   Observed input: verification table A2 names “GH-942's current doc”; A4 names explicit-tier passthrough as its red control.
   Affected scope: manual verification recipe only, under the already planned `TESTS-RESULTS/2026-10-16+GH-1098/`, with committed `provenance.jsonl`.
   Falsifier: the exact seeded parent input demonstrably lacks all three keys, and the stated A4 assertion fails on the parent for the intended routing reason.
   Read-only probe (exit 0): `python3` with `yaml.safe_load(next(Path('PROJECT/1-INBOX').glob('GH-942-*.md')).read_text().split('---',2)[1])`, then print absent keys from `('updated','owner','goal')`; decisive output: `GH942 missing: []`.

3. **[Should] Correct A4's full-push-gate guarantee and state the actual approval boundary.** `githooks/pre-push:258–286` runs docs-only or tier-2 gates for eligible pushes; only the fallback at `:291–299` runs full validation. Thus keeping the hook unchanged preserves today's push policy, but does not ensure the full gate runs on every routed lane. Replace the false guarantee in requirements/risk/verification prose with the existing tiered policy and name the qualifying evidence actually required before landing. If an unconditional full push gate is an issue requirement, resolve that discrepancy explicitly rather than treating it as already implemented. No new hook machinery is requested.
   Observed input: A4 says “the full gate stays on the pre-push hook”; issue #1098 also says “full gate still runs on push.”
   Affected scope: A4 safety rationale and manual evidence expectations, especially GH-960-shaped tier-2 diffs.
   Falsifier: the final candidate's installed hook demonstrably executes full validation for that eligible tier-2 push, or the requirement is explicitly reconciled to the current policy.
   Evidence command: `nl -ba githooks/pre-push | sed -n '250,278p'` and `sed -n '275,307p' githooks/pre-push`; exit 0; decisive output: `elif [ "$_route" = "fast" ] && [ "$_tier" = "2" ] ...`, `run_tier2_gate`, then exit 0 on success.

4. **[Should] Reconcile A3's role scope with the issue instead of calling it builder-only.** `env.setdefault(...)` at jog dispatch propagates to every agy turn in that invocation. An agy reviewer is supported and receives the same raised bound; `agy-turn.py` is a shim for either role. Issue #1098 explicitly says reviewer turns keep their default. With Scope C's codex reviewer, the proposed implementation is adequate for the measured case, but that does not establish the generic builder-only claim. State the deliberate all-agy-turns adjustment and reconcile it with the issue, or specify the smallest existing role-aware seam if preserving reviewer defaults is mandatory. Do not add a config surface.
   Observed input: jog with `--builder codex --reviewer agy` and no operator idle export.
   Affected scope: all agy turns dispatched by jog, not non-jog relays; operator export remains respected.
   Falsifier: a role-dependent reset before the reviewer shim, or explicit acceptance of the narrowed requirement/all-agy-turns policy.
   Evidence: `utils/py/marathon_drive.py:3387` copies the inherited environment for relay-drive; `utils/py/relay_drive.py:830–840` sets role metadata; `utils/py/agy-turn.py:462` reads the same `RELAY_TURN_IDLE_S` without role selection. Source reads/`rg` exited 0.

### Answers and implementation notes

- **A1:** root-first script selection plus explicit env is sufficient for the reported wrong-doc failure: `swarm_preflight.py:1199` selects root, `:1235` globs its docs, `:1204–1210` selects target repo, and `:1339–1363` evaluates probes in a detached worktree at that repo's target ref. The path around jog `:1728` is the legacy executor path, not the marathon retry path; marathon retry uses `run_marathon_phase`. Pin the env on the legacy call too if retaining it. Logging an external harness is sensible for vendored layouts; #1093 explicitly allows root pinning OR refusal. #1098's extra non-vendored refusal requirement should be recorded as intentionally superseded once root pinning removes the wrong-tree judgment, not imposed indiscriminately on `.xyz`.
- **A2:** filling missing keys is the smallest unattended fix; refusing only moves the observed stop earlier. Hoisting status/date updates is appropriate, while existing owner/goal and the existing Status table should remain intact. Put the HTML marker after the frontmatter delimiter (or use a YAML `#` comment inside). A pure in-memory PyYAML probe of the proposed standalone HTML line exited 0 but parsed it as an extra mapping key: `{'<!-- jog': 'goal auto-filled from title; refine -->'}`. It is not a YAML comment. This is a small implementation clarification, not a request for a parser/refactor.
- **A3:** inherited env reaches marathon-drive → relay-drive → shim. `test/gh492-idle-kill.sh:160–165` pins the explicit disable behavior, and gh114 sets an explicit small idle threshold; the inspected sections do not pin jog's ambient 300 s default. Suites are regression coverage, not proof of jog env propagation. The 900 s default still cannot promise the cited ~20-minute build will finish; success must be measured, not inferred from removing the 300 s kill.
- **A4:** normalize `gate_cmd` before invocation construction, not just the Markdown line. The current single variable feeds text, JSON `gate`, and argv `--pre-advance-cmd` (`swarm_preflight.py:1111,1132,1645,1722,1834`), so no new writer is needed. Quote the ref as one shell argument. `validate.sh:869–887` compares the supplied ref against the working tree, including committed candidate changes and pending edits; it is not a per-artifact route. Marathon gates run after relay approval in the target checkout (`marathon_drive.py:2336,2691–2692`). This is safe conservative routing, but unrelated changes versus `development` can select full. In particular, running Scope C from the unmerged Scope A branch can include the harness fixes themselves and defeat the intended tier-2 timing measurement. Prefer the issue's post-landing development run, or make that limitation explicit.
- **Fail closed:** classifier failure selects tier 3 (`validate.sh:891–894`); empty input selects full in `utils/ci-route.sh:452–457`. These are source observations, not executed gate evidence.
- **Rating:** 75/55/50/55 is reasonable as a prioritization judgment with the one-day recurrence denominators and unknown prior trend stated. Appeal 50 has no override. Live issue #1081's runs 2–5 comment confirms the reported failures; it reports one PR-ready item, not evidence the proposed future batch criterion works.

### Evidence limits / recon ledger

Read the plan in full and the requested source sections, then traced the invocation/env/gate consumers named above. Graph lookup: all `list_projects` pages (84 entries) contain no project rooted at this relay checkout. Nearest canonical `XYZ-forge` is ready but its coverage metadata reports indexed_at `2026-09-01T15:54:30Z`; returned jog symbol line numbers differ from this seed. Coverage was checked for the runtime/gate paths; treated canonical graph results as provisional and used exact local source for every material claim. No index was created or modified.

Read-only GitHub queries (each exit 0): `gh issue view 1098 --repo HiQS-Labs/XYZ-forge --json body,comments`; same for #1093; #1081 with `--json comments`. Decisive historical comment: https://github.com/HiQS-Labs/XYZ-forge/issues/1081#issuecomment-6208473721. Historic raw logs remain runner-local; their execution was not reproduced here.

**[Unverified — needs clone run]** All suites, actual promotion, preflight execution, wall/idle behavior and routed gate duration. Only source inspection, remote read-only queries and in-memory YAML probes ran here. Existing suites plus nonempty manual receipts and witnessed red controls in the disposable clone remain required. Root cause: dispatch/promotion/default gate choices are made upstream of the failed turns; fix sites: existing jog and preflight writers; no parallel supervisor or new gate is justified.

### Round 1 · Producer · claude

All four `[Should]` findings and both implementation notes accepted; plan revised in `PROJECT/1-INBOX/GH-1098-SHIFT-PHASE3.md` (same commit as this block).

| Finding | Disposition | Where in the plan |
|---|---|---|
| 1 Scope C contradicts the landing boundary | **Accepted.** Criterion rewritten: ≥ 2 of 3 PR-ready across ≤ 3 `jog run` invocations, each started only after the prior stopped at its boundary, zero operator edits between. No queue-policy change in A1–A4; added to Non-goals. #1098 criterion 1 recorded as reconciled. | "Scope C", "Non-goals" |
| 2 Vacuous A2/A4 controls | **Accepted.** A2: two seeded scratch captures with the three keys stripped (with/without Status table) plus a third that keeps existing `owner`/`goal` byte-for-byte; parent shows 6 errors. A4: red control asserts the invocation JSON `gate` and `--pre-advance-cmd` argv are rewritten on the candidate and not on the parent; explicit-tier passthrough demoted to a compatibility check. | "Verification" table |
| 3 "Full gate on push" is false | **Accepted.** Prose corrected: `githooks/pre-push:258–299` is tiered; A4 makes the pre-advance gate consistent with push, adds/removes nothing; landing evidence = hook's routed gate + hosted checks. #1098 wording recorded as reconciled. `githooks/pre-push` added to Non-goals. | A4 row, "Verification" footer, "Non-goals" |
| 4 A3 is not builder-only | **Accepted.** Stated as a deliberate all-agy-turns-in-jog policy; role-aware variant named and declined as new machinery (`relay_drive.py` seam). #1098 wording recorded as reconciled. | A3 row, "Non-goals" |
| Note A1 second site | **Accepted.** Second site is the legacy relay-executor call (~:1728), not a marathon retry path; env pin added there; retry verbs covered via `run_marathon_phase`. "Refuse loudly" recorded as superseded by pin-and-log per #1093. | A1 row |
| Note A2 marker | **Accepted.** Marker is a YAML `#` comment line, not an HTML comment. | A2 row |

Re-review requested on the revised plan only. Handing off to codex — codex, take your turn.


### Round 2 · Reviewer · codex

**Verdict:** Changes requested

The revised A1–A4 implementation approach is suitable for this small local harness change. The missing-key seeds, actual default-gate red control, YAML comment, legacy-call env pin, and explicit all-agy-turns scope address the earlier design findings. Two bounded plan corrections remain; neither asks for more code, tests, flags, or queue machinery.

1. **[Should] Finish reconciling the acceptance contract throughout the artifact.** PROJECT/1-INBOX/GH-1098-SHIFT-PHASE3.md:9 still requires two PR-ready items from **one** invocation, while :95 explicitly says that is unreachable and replaces it with up to three invocations. :43 still promises the full gate on push, while :52 correctly describes the tiered hook. Update the goal and A4 requirement to agree with the revised detailed sections. Distinguish a proposed reconciliation from externally accepted issue requirements; the producer response alone does not establish operator/issue acceptance.
   Observed input: the revised plan contains the old goal/full-push guarantee and their replacements simultaneously.
   Affected scope: plan frontmatter goal, Requirements A4, and claims that issue requirements have been reconciled; no source change.
   Falsifier: one consistent acceptance contract throughout, with changed issue requirements either backed by an acceptance reference or explicitly described as proposed adjustments.
   Evidence command: read-only python3 using Path("PROJECT/1-INBOX/GH-1098-SHIFT-PHASE3.md").read_text().splitlines(), printing lines starting with goal:, - **A4**, and **Exit criterion 1 reconciled; exit 0. Decisive output: line 9 says "One unattended ... >= 2 of 3"; line 95 says that condition is "unreachable by design"; line 43 says "the full gate stays on the pre-push hook". Hook source confirms eligible tier-2 success exits without the full fallback (githooks/pre-push:267–281).

2. **[Should] Specify a Scope C baseline that can measure the routed-gate claim.** Scope C still says to clone **this branch** (:91–93), while the contract base remains development. The plan itself says these harness edits route full (:82). validate.sh --auto development classifies all tracked differences against that ref, including unmerged harness changes, not just the GH-960-shaped task. The setup risks deliberately selecting the same full gate whose duration it intends to avoid. Use the post-landing development baseline for Scope C, or label the branch-based run provisional and defer the tier-2 duration claim until that baseline exists. Correct A4's base..HEAD description to include tracked working-tree changes; the implementation uses a single-ref diff.
   Observed input: Scope C starts on the unmerged A1–A4 branch, target.ref is development, and A4 acceptance expects the GH-960-shaped gate inside 1800 s.
   Affected scope: Scope C setup and A4 measurement interpretation only; route and gate guard stay unchanged.
   Falsifier: the specified baseline already contains A1–A4 in the compared development ref, or a disposable-clone receipt lists the complete compared paths and demonstrates those harness changes do not force tier 3.
   Evidence commands: nl -ba validate.sh | sed -n '871,895p'; nl -ba utils/py/marathon_drive.py | sed -n '2328,2343p;2682,2696p;3210,3295p'; exit 0. Decisive output: _auto_head="" for a single supplied ref, then git diff --no-renames --name-only "$_auto_base"; gate runs after relay approval in the target checkout; branch guard returns when current branch is not protected (:3233–3234), so it does not re-anchor an existing task branch onto development. This is a source-grounded measurement risk, not an executed failure.

Implementation notes retained: quote target.ref as one shell argument when constructing A4's command; preserve existing owner/goal and Status table in A2. The new seeded A2/A4 controls are meaningful recipes, not yet witnessed passes. A1 must demonstrate the clone target and successful dispatch, rather than treating any non-6 refusal alone as success. Rating remains reasonable with its stated one-day evidence limit.

Evidence/containment: read the revised plan in full and requested source sections. Verify-tier intent. list_projects(limit=100) returned all 84 projects (has_more=false), none rooted at this checkout. Canonical XYZ-forge graph lookup returned three relevant jog symbols, but coverage generation remains 2026-09-01T15:54:30Z, with changed metadata for jog, preflight, agy, marathon/relay drivers, validate, hook and PDDA, and untracked harness_paths metadata. Used exact local source fallback rather than treating that graph as current; no index mutation.

Fresh read-only remote query gh issue view 1098 --repo HiQS-Labs/XYZ-forge --json body,comments failed with exit 1: "error connecting to api.github.com". Its redirected scratch file was empty and was not used as evidence; the subsequent JSON read also failed. This turn therefore does not attest current remote acceptance of the proposed requirement adjustments. Earlier historical receipts remain as recorded above.

**[Unverified — needs clone run]** Runtime dispatch, promotions, env propagation under execution, suites and actual routed-gate duration. No validate, test suite, pytest, executable fixture, or git command was run. Only this relay file was edited; scratch stayed under .relay-scratch/.

Handing back to claude for the two plan corrections.

### Round 2 · Producer · claude

Both `[Should]` findings accepted; plan revised in the same commit.

| Finding | Disposition | Where |
|---|---|---|
| 1 Acceptance contract inconsistent across the artifact | **Accepted.** Frontmatter `goal` now states the ≤3-invocation criterion and the post-landing baseline; Requirements A3/A4 rewritten to the reconciled form (A4 no longer claims a full push gate). The three issue adjustments are labelled **proposed**, with an acceptance reference: https://github.com/HiQS-Labs/XYZ-forge/issues/1098#issuecomment-6218983571 (posted this round; operator accepts or objects there). The plan states nothing is treated as accepted until then. | `goal:`, "Requirements", "Scope C" |
| 2 Scope C baseline cannot measure the routed gate | **Accepted.** Scope C now runs from a `-verify` clone of post-landing `development`; a branch-based early run is labelled provisional with criterion 4 reported "not measurable", never met. | "Scope C" |
| Note: quote `target.ref`; preserve owner/goal + Status; A1 needs clone target_root AND successful dispatch | **Accepted**, recorded in A2/A4 rows and Scope C. | A2, A4, "Scope C" |

Round 3 is the last within the cap. Handing off to codex — codex, take your turn.
