# RELAY · GH-1100 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-16.
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
6. **Commit only the relay file** (`relay(gh1100-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/jog_run.py` diff against ccb900746c5c2d011522299246f111ce0a49db0f; plan/recon under PROJECT/2-WORKING; TESTS-RESULTS/2026-10-16+GH-1100/; prior plan review relay
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-16
- Definition of Done: Issue #1100: Jog must explicitly target packet root and keep phase/tooling/coordination writes in its selected clone despite ambient primary XYZ_HARNESS. Check run/retry-build/gate-retry, old stored packets, explicit target preservation, .xyz behavior, ratings and no-new-tests rule. Verify 223-check focused evidence and red controls substantiate acceptance. Grade operator-controlled local harness and commensurate complexity. Required full gate runs ONCE at push boundary after source approval; keep this pending condition explicit, do not claim publication ready yet. Read-only review, only relay writable; no mutation-heavy suites in worktree.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · codex-producer · 2026-10-16
**Did:** Implemented the approved plan in d6c7e9b0: explicit target fallback and one shared small env adapter used at both dispatch sites. Root policy is applied after packet env merge; packet inputs are unchanged.
**Review this:** Whole changed adapter and its actual consumers. Check executable-parent derivation, stored packet compatibility, retry gates and selected phase root. No global resolver or frozen twin edits, no new suite/registry entry. Existing review findings: none open.
**Verification:** Base red and target-only red fail as intended; candidate probe passes; real Marathon --dry-run renders clone-local phase path; existing gh280 suite 223 pass/0 fail and repository identity unchanged. Provenance/logs committed under TESTS-RESULTS. PDDA recon-format failures fixed; three affected checks rerun green. Full required gate pending final approval/push.
**Commit:** d6c7e9b0 (runtime); review latest committed documentation/evidence as well.

### Reviewer · Round 1 · codex · 2026-10-16
**Ship with conditions — source approved; publication gate pending.**
swept file: yes
**VERDICT: PASS**
**Basis:** Read all 1,821 lines of jog_run.py, the complete plan/recon, prior plan review and retained verification artifacts, and current material producer/resolver/driver consumers. No additional concrete pre-existing defect found in the swept file. This approves source under the local operator-controlled harness contract; it does not establish publication or merge readiness.

- [Pass] Target policy is explicit and preserves packet inputs: utils/py/jog_run.py:491–514 copies argv and appends target_root only when the packet lacks --target-root. Existing reviewer/builder, phase-id and require-clean policies remain in that adapter. The packet producer's two supported layouts are rooted executable paths (utils/py/swarm_preflight.py:1098–1111), so executable-parent derivation fits both root and lexical .xyz installs without requiring optional harness_home.
- [Pass] Root policy is applied after packet-env merge at utils/py/jog_run.py:517–525. It pins tooling through XYZ_HARNESS and coordination through MARATHON_ROOT. The actual consumer resolves these separately at utils/py/marathon_drive.py:1121–1128, places default phases under root at :1368 and propagates target into relay-drive and shim guard roots at :3384–3416. This directly addresses the recorded ambient-primary XYZ_HARNESS failure without changing the global resolver.
- [Pass] Run and retry-build use the shared environment adapter at utils/py/jog_run.py:606; retry-build delegates to run_marathon_phase at :875. Stored-packet gate retry uses the same argv/env policy at :805–810. The existing driver-lock export remains in both dispatches, and run retains its idle-bound setdefault at :614. No new retry mechanism or schema is needed.
- [Pass] Independent non-mutating probe: command `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` AST-extracted the current build_marathon_invocation_artifact plus both current adapters into an os-only namespace with MARATHON_INVOCATION_SCHEMA supplied, then generated root/vendored/explicit packets, removed harness_home, supplied stale packet and ambient root env, and asserted exactly one correct target, selected tooling/coordination roots, removed require-clean and unchanged input. Exit 0; decisive output: `root: PASS target, tooling, coordination, packet-env precedence, legacy packet, immutable input`, with identical PASS lines for vendored and explicit; AST call checks printed `run_marathon_phase: shared argv/env adapters present` and `_jog_retry_gate_locked: shared argv/env adapters present`. An initial extraction exited 1 on missing namespace constant MARATHON_INVOCATION_SCHEMA; supplying that unchanged constant corrected the probe. No application entry point, fixture or subprocess was executed.
- [Pass] Retained falsification evidence is substantive: TESTS-RESULTS/2026-10-16+GH-1100/red-control.txt ends `AssertionError: missing explicit --target-root`; target-only-control.txt ends `AssertionError: driver harness root redirected to ambient primary`; green-control.txt reports all root/vendored/explicit cases passing. provenance.jsonl records exits 1/1/0, and probe-command.txt shows nonempty, unique dispatch assertions with subprocess/state writes intercepted. driver-dry-run.txt places the rendered relay beneath the disposable gate clone's marathon-system/gh1100-dry-root. These support argument/root behavior, not a live builder acceptance claim.
- [Pass] Saved focused evidence was inspected, not rerun here: command `python3 - <<'PY'` read gh280.log.gz with gzip and compared the two focused-identity JSON files, exit 0. Decisive output: `suite bytes 13558`, `gh280-jog-marathon-adapter: 223 pass, 0 fail`, `identities match: True`; recorded HEAD is d6c7e9b0615aaa68949fe971c2a5bbafb884faf9, bare=false, origin=the task clone. The suite is nonempty and its receipt names the runtime revision (provenance.jsonl focused-suite row).
- [Pass] Complexity and rating are commensurate: one small shared adapter, existing argv policy, no new suite/registry/gate requested by the implementation plan. releases.sql:867 carries 80/85/50/90 with NULL override, matching plan's Rating section; CHANGELOG.md:3–7 records the containment bet and rollback. The seeded evidence reports no suite/registry changes; no independent git diff was run because this turn prohibits git.
- [Unverified — needs clone run] The required full gate remains pending and must run once at the push boundary in disposable full-clone isolation against the final state, followed by actual hosted-check/PR inspection. This worktree review ran no validate.sh, test/*.sh, pytest, executable fixtures or builders. The saved focused run is not a substitute for that gate.
- Evidence limits: bounded Verify review; graph project XYZ-forge generation 2026-09-01T15:54:30Z belongs to the primary checkout, not this worktree. Search returned all nine matching Marathon symbols with no remaining page; coverage for jog_run.py/swarm_preflight.py/marathon_drive.py reported changed metadata, so material claims use current direct source. No repository-wide audit, external issue refresh, arbitrary packet executable support, or override-neutralization claim. Explicit TICK_BIN/TICK_REPO_ROOT/MARATHON_RELAY_DRIVE/MARATHON_AGENT_CMD remain operator overrides outside the ambient-XYZ_HARNESS acceptance case.

Relay closed (Approved), no further review turn needed. Producer owns the pending disposable-clone publication gate and PR checks; harness owns the relay-only commit.


### Attestation · relay-drive — 2026-10-17T03:21:26Z
task: RELAY-gh1100-final
reviewer: codex
status: Approved
reviewed-head: b92d66c8cc7b7c2ee6f430ba731365b94edc52f4
added-range: 6920+5675
added-sha256: cccfc8444c7167daac95dae8265c2901a4a6ed2bc635489f54ddff8576cbd023
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
