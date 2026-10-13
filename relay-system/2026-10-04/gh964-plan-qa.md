# RELAY · GH-964 plan QA: Claude Code mod /xyz-status
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-04.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-964-plan-qa-claude-code-mod-xyz-status): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-964-CLAUDE-CODE-MODS.md` (the plan; no code exists yet).
  Requirements source: issue https://github.com/HiQS-Labs/XYZ-forge/issues/964 (body transcribed in the plan).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-04
- Definition of Done: the plan is grounded in the real paths it cites, covers the issue's acceptance
  list (or names what it defers and why), extends existing read-only commands instead of re-implementing
  them, has a falsifiable manual diagnostic with a red control, and adds no test suite (GH-831).

**Operational envelope.** A single operator's local developer tool: an optional, read-only Claude Code
mod loaded with `--plugin-dir`, about 60 lines of TypeScript plus a skill doc. Grade against that.
Do not ask for enterprise machinery, retries, caching, telemetry, installers or new tests (AGENTS.md
"No new tests", GH-831: a request for a new suite is itself out of scope).

**Paths to read** (all in this clone): the plan; `AGENTS.md` (No new tests rail); `utils/ci-route.sh`
lines 40–70 (routing of non-core `skills/**`); `relay-automation/marathon-ls.sh` (header);
`bin/tick` (`claims` verb); `skills/2-daily/xyz/SKILL.md` (the existing `/xyz` name);
`test/gh589-skill-viewer.sh` (what a new skill folder must satisfy). The mod API facts in the plan's
Recon come from Claude Code 2.1.289's bundled typings, not in this repo; treat them as stated input.

**Questions.**
1. Are the three data sources (`gh run list --workflow wave-reconcile.yml`, `bin/tick claims`,
   `relay-automation/marathon-ls.sh`) real, read-only, and the right existing commands for "what is in
   flight"? Is any better existing reader missed?
2. Is dropping the issue's "open relay threads with STATUS" (beyond what `marathon-ls.sh` shows) and the
   optional `/xyz row N` a reasonable, stated deferral, or does it leave an acceptance item unmet?
3. Is the naming right (`/xyz-status` command, `xyz-mod` skill folder) given `skills/2-daily/xyz/`?
4. Does placing the mod under `skills/2-daily/xyz-mod/mod/` route as docs/Small per `utils/ci-route.sh`,
   and does it trip `test/gh589-skill-viewer.sh` or any other existing suite?
5. Is the manual diagnostic falsifiable (does the red control actually go red), and does it stay inside
   GH-831 (no new suite, no registry entry)?
6. Anything over- or under-built for the envelope above? Cite `file:line` for every disagreement.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The small, optional mod is a reasonable experiment, but the diagnostic can count failed readers as green, repo-root assumptions are unstated, and required acceptance evidence is missing. Fix these in the plan before building; no new suite or machinery is requested.
swept file: yes

Reviewed the entire 109-line plan, including frontmatter, recon, implementation steps, non-goals and risks. No additional pre-existing plan defects found beyond the findings below. Mod API facts are supplied input, not independently validated here. Source evidence is from this checkout. Graph tooling became available after initial discovery: both `list_projects` pages contain no index for this checkout; nearest `XYZ-forge` index belongs to another checkout, generation `2026-09-01T15:54:30Z`. Coverage reports changed/missing/untracked paths and excluded `bin/`; source reads supersede it. A subsequent stale-index symbol search did not return and was terminated; no exhaustive absence claim about other readers is made.

- **[Should] F1 — Make the manual diagnostic actually reject unhealthy output.** `PROJECT/2-WORKING/GH-964-CLAUDE-CODE-MODS.md:84` says each reader “exits 0 (or reports its error)”; lines 86–88 merely require the mutant section to print an error and then say “red control red.” Error rendering is correct runtime behavior, but it does not specify a failed diagnostic assertion. The issue's Proposed shape explicitly requires exit 0 **and non-empty output**, and Acceptance says an unknown path “makes it fail.” Cheapest fix: define a healthy check per reader (rc=0, non-empty result), name its FAIL result for the missing-script mutation, retain useful error text and the other sections, restore the local edit, and record healthy/mutant/restored outcomes with provenance. A written manual checklist is sufficient; no diagnostic runner is required.
  Observed input: the planned missing-script mutation at plan:86, combined with the “or reports its error” success alternative at plan:84.
  Affected scope: manual diagnostic verdicts for a failed, missing, timed-out, or empty-output reader; normal `/xyz-status` error display should still work.
  Falsifier: the documented diagnostic records a nonzero reader exit or empty output as FAIL, and the missing-script control fails that same healthy assertion while the restored reader passes. If already specified, this request is unnecessary; it is absent in the seeded plan.

- **[Should] F2 — State and verify the repo-root contract.** Plan:70 sets process cwd to session cwd while plan:41–42 uses relative `bin/tick` and `relay-automation/marathon-ls.sh`. A session launched in `src/` cannot resolve either. `bin/tick:18` also honors inherited `TICK_REPO_ROOT`, whereas `relay-automation/marathon-ls.sh:33` anchors its hub to the script location; the sections can therefore refer to different checkouts. Cheapest fix: explicitly require launching from the intended Forge root with `TICK_REPO_ROOT` pinned to it (or resolve/pin it in the mod), identify the monitored root in output, and add one manual root/subdirectory or worktree check. Do not introduce an installer or discovery framework.
  Observed input: session cwd `<repo>/src`, with the exact relative argv paths from plan:41–42. Read-only probe: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` with body `from pathlib import Path; root=Path.cwd(); [print(f"cwd={cwd.name} argv0={command} exists={(cwd/command).is_file()}") for cwd in (root,root/'src') for command in ('bin/tick','relay-automation/marathon-ls.sh')]`, then `PY`. Exit 0; decisive output: `cwd=src argv0=bin/tick exists=False` and `cwd=src argv0=relay-automation/marathon-ls.sh exists=False`; both root cases were `True`.
  Affected scope: local readers invoked outside the intended root, or with a conflicting inherited tick root. Root-only operation is acceptable if stated and verified.
  Falsifier: a root-only launch contract plus a manual run showing all sections refer to that root, or absolute reader paths and explicit root selection that work from `src/`; either resolves the request.

- **[Should] F3 — Map the remaining issue acceptance items to steps or explicit deferrals.** The fetched [GH-964 body](https://github.com/HiQS-Labs/XYZ-forge/issues/964) requires hosted “wave-reconcile and gate runs,” main-machine version/update and `/plugin` showing an active mod, turn-free replies in **both terminal and VS Code**, and a recorded keep/extend/drop decision. Plan:39 queries only `wave-reconcile.yml`; the other hosted workflow exists at `.github/workflows/ci.yml:98`. Plan:82 checks a version and plan:85 says only “a live session”; activation, both surfaces and the decision have no step. The Setup claim that the issue body is transcribed in the plan is also false. Cheapest fix: add a short acceptance mapping with those checks and the issue's source requirements; reuse `gh run list` for hosted gate visibility or explicitly defer it with a reason. Label `--limit 5` output as recent/bounded rather than a complete in-flight inventory. Preserve the existing justified naming change and stated deferrals.
  Observed input: planned argv `gh run list --workflow wave-reconcile.yml --branch development --limit 5` (plan:39), which selects no `ci.yml` runs, and the issue's quoted acceptance requirements above versus plan:80–90.
  Affected scope: what the experimental command promises to show and what evidence permits calling the experiment complete.
  Falsifier: an acceptance mapping covering both hosted workflow kinds, both UI surfaces, activation/version, and the go/no-go result, or an explicit reasoned deferral for an omitted item. This is plan QA, not a claim that a nonexistent implementation has failed at runtime.

- **[Pass] Existing readers, naming and small scope are grounded.** `bin/tick:403` folds events without writing the snapshot; `relay-automation/marathon-ls.sh:20` states no writes and its body reads registry/locks/events. Hosted listing is the same reader family used by `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:451` (not literally the same argv: that reader uses JSON and limit 20). `skills/2-daily/xyz/SKILL.md:2` owns `xyz`, supporting `/xyz-status` plus folder/frontmatter name `xyz-mod`. Plan:44–46 and :94 explicitly defer undriven relay STATUS listing and optional row lookup; acceptable for this experiment if the acceptance mapping records the remaining coverage gap. `marathon-ls.sh:115` reads `marathon-system/` and `phases/`, not general `relay-system/` thread STATUS.

- **[Pass] Proposed paths route as docs, with no new suite.** Probe command: `printf '%s\n' skills/2-daily/xyz-mod/mod/.claude-plugin/plugin.json skills/2-daily/xyz-mod/mod/hooks/hooks.json skills/2-daily/xyz-mod/mod/hooks/register.ts skills/2-daily/xyz-mod/SKILL.md ARCHITECTURE.md CHANGELOG.md TESTS-RESULTS/2026-10-04+GH-964/provenance.jsonl | bash utils/ci-route.sh pull_request`. Exit 0; decisive output: `docs_only=true`, `full_required=false`, `route=docs`, `tier=1`, `tier_reason=docs-only`. This matches `utils/ci-route.sh:63`. `test/gh589-skill-viewer.sh:18` derives its inventory dynamically; its viewer requires frontmatter name equal to folder at `mini/skills/skill-viewer/scripts/list_skills.py:91`. Use `name: xyz-mod` and a non-empty description. Plan:57 excludes new tests, consistent with `AGENTS.md:142`.

- **[Nit] Distinguish docs tier from the Small registry in plan:90.** `validate.sh:1061` makes tier 1 the docs gate; `validate.sh:933` enables the additional Small behavior for `--sequential --subsystem small`. `--auto` choosing tier 1 does not itself mean the Small registry ran. State which is expected, without adding a gate.

- **[Unverified — needs clone run]** No gate, test suite, executable fixture or live mod diagnostic was run here. Final build evidence must establish actual load/activation, safe declared calls, independent reader-error handling (including process exceptions), and no model turn on the required surfaces. No claim that other existing suites pass or that no better reader exists follows from this review.

Handing off to Producer (claude-a) — disposition F1–F3, revise the plan, and open Round 2 for review. No artifact/source edits or git commands performed by this reviewer; the harness owns the relay-file commit.

### Producer · Round 1 · claude-a

- **F1 — Implemented.** Plan step 4 now defines healthy as exit 0 **and** non-empty stdout, anything else FAIL; checks D1–D6 are named; red control R1 records healthy / mutant FAIL / restored healthy. Still a written checklist, no runner.
- **F2 — Implemented.** Step 1: the mod resolves the root with `git rev-parse --show-toplevel` from the session cwd, prints it first, runs readers by absolute path with `cwd` = root and `TICK_REPO_ROOT` = root; outside a repo it says so and stops. D6 checks a session started in `src/`.
- **F3 — Implemented.** Hosted reader is now `gh run list --branch development --limit 8` (no workflow filter, so `ci.yml` gate runs show too), labelled "recent 8". New "Acceptance mapping" table maps every issue item to a step (D1 version, D4 `/plugin` active, D5 terminal + VS Code with no turn, step 6 go/no-go) or an explicit deferral. Setup's "body transcribed" claim was loose; the mapping table now carries the issue's acceptance list.
- **Nit — Implemented.** Step 5 states tier 1 docs gate (`pdda.sh run`) locally; the Small registry is the hosted reconcile's run, not claimed locally.

Round 2: please re-review the revised plan (same artifact).

### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: F1–F3 and the tier wording are resolved in the plan. The optional, read-only experiment reuses existing readers, names its reduced acceptance scope, and defines a falsifiable manual diagnostic without adding a suite. Approval is permission to build this plan, not runtime or merge-readiness evidence.
swept file: yes

Read the entire revised 138-line plan, including frontmatter, Status, Recon, bet, ordered steps, acceptance mapping, non-goals, risks and ratings. No additional pre-existing plan defects found; the optional wording nit below is the only remaining disagreement. Mod API facts remain supplied input, not independently validated. Verify-tier graph availability check: `list_projects(limit=100)` returned all 77 projects with `has_more=false`, none for this checkout. The nearest `XYZ-forge` graph is a different checkout with generation `2026-09-01T15:54:30Z`; one coverage call covering all material evidence paths reported changed/missing/untracked metadata and excluded `bin/`. Current source reads supersede that stale graph. No exhaustive claim about the absence of a better reader or relay lister is made.

- **[Pass] F1 resolved — explicit healthy assertion and red control.** `PROJECT/2-WORKING/GH-964-CLAUDE-CODE-MODS.md:88` requires exit 0 **and** non-empty stdout, with anything else FAIL. Lines 99–102 require the missing-path section to FAIL, the other two to remain healthy, and healthy / mutant / restored outcomes to be recorded. Lines 77–80 cover nonzero exits, thrown process calls, empty output and continued replies from independent sections. This is a written manual check, consistent with `AGENTS.md:142`–153; no new suite or runner is planned.

- **[Pass] F2 resolved at plan level — root contract is explicit.** Plan:72–79 resolves the session's git root, prints it, uses that cwd and pins `TICK_REPO_ROOT`; D6 at plan:97 checks launch from `src/`. The pin matches the env-first resolution at `bin/tick:18`–20 and ensures the intended root is used for claims. `relay-automation/marathon-ls.sh:32`–33 anchors its hub to its own script path; the planned absolute repo-local path keeps that hub aligned. Actual subdirectory behavior and inherited-env override still require implementation evidence.

- **[Pass] F3 resolved — requirements have an explicit disposition.** Plan:39–42 removes the workflow filter and labels the view “recent 8”; `.github/workflows/ci.yml:98`–103 establishes development as a hosted trigger branch. Plan:90–107 includes version, validation, active `/plugin`, both terminal and VS Code with no model turn, and the keep/extend/drop record. Plan:109–119 maps the fetched [GH-964 acceptance list](https://github.com/HiQS-Labs/XYZ-forge/issues/964) and explicitly defers general relay STATUS and optional row lookup. Accept those deferrals for this exploration: the recent-run view is bounded, and driver state is only partial relay coverage; do not claim full issue acceptance or a complete in-flight inventory when reporting the experiment.

- **[Pass] Reader reuse, naming and containment fit the stated envelope.** `bin/tick:403`–455 reads/folds claims and prints a non-empty no-claims message without writing a snapshot. `relay-automation/marathon-ls.sh:178`–199 reads its hub and registry; lines 115–124 inspect marathon/phases relay paths, consistent with the stated general-thread deferral. `skills/2-daily/xyz/SKILL.md:2` owns `xyz`, supporting the distinct `/xyz-status` command and `xyz-mod` skill folder at plan:35–37. Plan:58–64 excludes tool/prompt mutation, timers and installers, and states an Easy rollback by unloading/removing the optional mod.

- **[Pass] Routing and viewer constraints remain grounded.** `utils/ci-route.sh:63`–69 classifies the proposed unmapped non-core skill paths as docs. Plan:103–106 now distinguishes the tier-1 docs gate from hosted Small qualification. `test/gh589-skill-viewer.sh:18`–25 derives inventory dynamically; `mini/skills/skill-viewer/scripts/list_skills.py:91` requires folder/name equality. Use `name: xyz-mod` and a non-empty description in the new skill; no fixed-count update is needed. No suite was executed here, so this does not attest a green gate.

- **[Nit] Clarify which readers are repo-local.** Plan:74 says all “three readers” run by absolute path “under that root,” but plan:39 uses installed `gh`, which ordinarily lives on PATH rather than inside Forge. Cheapest clarification while implementing: the two repo-local readers use absolute paths under root; `gh` is resolved from PATH and runs with cwd=root. The intended behavior is clear enough to approve; no extra executable discovery mechanism is requested.

- **[Unverified — needs clone run]** There is no mod implementation yet. D1–D6/R1, plugin activation on both surfaces, absence of a model turn, process error handling, and gate results remain future execution evidence. No `validate.sh`, `test/*.sh`, pytest, executable fixture, or git command was run. This turn used read-only source/issue/coverage queries and edited only this relay file; the harness owns its commit.

Relay closed (Approved), no further review turn needed. Producer (claude-a) may build the approved plan and retain the required manual diagnostic receipts.


### Attestation · relay-drive — 2026-10-05T05:10:23Z
task: RELAY-gh964-plan-qa
reviewer: codex
status: Approved
reviewed-head: 6afe2c5f6c304966a974cb97643359337eeebfec
added-range: 17128+5337
added-sha256: 11a1a5dbc13d1dc5453b5af1ae20aa6c6c89e3a68e8f1b56b7dd12266ded7b62
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
