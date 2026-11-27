# Marathon Phase gh-792-gen4-sandbox-disjoint-first
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-792-GEN4-SANDBOX-DISJOINT-FIRST-TURN builder=codex reviewer=agy round-cap=2 -->

## Phase Brief

# Marathon preflight packet — gh-792-gen4-sandbox-disjoint-first

- Generated: 2026-11-27T16:52:54Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/flywheel-day3-exec/PROJECT/2-WORKING/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md 
- Target root: /Users/noelsaw/flywheel-day3-exec (development @ c511b0bb4)
- Suggested branch: `marathon/gh-792-gen4-sandbox-disjoint-first-2026-11-27` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/gh-gen4-phase5-campaign.sh`

- Artifacts: utils/py/gen4_campaign.py,TESTS-RESULTS/2026-11-27+GH-792/delivery.md,test/gh-gen4-phase5-campaign.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 409 LOC across 3 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh-gen4-phase5-campaign.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/flywheel-day3-exec/PROJECT/2-WORKING/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #792](https://github.com/HiQS-Labs/XYZ-forge/issues/792) — 0 issue criteria reconciled: 3 deviation(s) declared and accounted for.*
- [ ] The overlapping call refuses with zero `makedirs`/`rmtree`/`subprocess` calls (red control: the current order records a delete first).
- [ ] A disjoint candidate still clones as before.
- [ ] The existing self-test at `gen4_campaign.py:348` (`make_sandbox(host, os.path.join(host, "inside"))`) still refuses.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/gen4_campaign.py,TESTS-RESULTS/2026-11-27+GH-792/delivery.md,test/gh-gen4-phase5-campaign.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/gh-gen4-phase5-campaign.sh`, and NOT `test/gh-gen4-phase5-campaign.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-792-gen4-sandbox-disjoint-first RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex --round-cap 2 \
  --artifact utils/py/gen4_campaign.py,TESTS-RESULTS/2026-11-27+GH-792/delivery.md,test/gh-gen4-phase5-campaign.sh \
  --pre-advance-cmd 'bash test/gh-gen4-phase5-campaign.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/gen4_campaign.py,TESTS-RESULTS/2026-11-27+GH-792/delivery.md,test/gh-gen4-phase5-campaign.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
   If a verification the brief asks for could not run (e.g. your sandbox denied a local service), put it on its own line: `unverified: <what> — <why>` (GH-1428).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/flywheel-day3-exec/bin/tick
   - /Users/noelsaw/flywheel-day3-exec/bin/tick claim MARATHON-GH-792-GEN4-SANDBOX-DISJOINT-FIRST-TURN --agent codex --paths "marathon-system/gh-792-gen4-sandbox-disjoint-first/RELAY.md,utils/py/gen4_campaign.py,TESTS-RESULTS/2026-11-27+GH-792/delivery.md,test/gh-gen4-phase5-campaign.sh"
   - /Users/noelsaw/flywheel-day3-exec/bin/tick ping MARATHON-GH-792-GEN4-SANDBOX-DISJOINT-FIRST-TURN --agent codex
   - /Users/noelsaw/flywheel-day3-exec/bin/tick release MARATHON-GH-792-GEN4-SANDBOX-DISJOINT-FIRST-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-792-gen4-sandbox-disjoint-first/RELAY.md and utils/py/gen4_campaign.py,TESTS-RESULTS/2026-11-27+GH-792/delivery.md,test/gh-gen4-phase5-campaign.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/gen4_campaign.py,TESTS-RESULTS/2026-11-27+GH-792/delivery.md,test/gh-gen4-phase5-campaign.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/flywheel-day3-exec/bin/tick release MARATHON-GH-792-GEN4-SANDBOX-DISJOINT-FIRST-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/flywheel-day3-exec/bin/tick done MARATHON-GH-792-GEN4-SANDBOX-DISJOINT-FIRST-TURN --agent agy
3a. GATE EVIDENCE (GH-1428): this phase's gate (`bash test/gh-gen4-phase5-campaign.sh`) is not a focused file-only command, so it runs only in the harness after your turn — do NOT run it. Declare a literal `gate run: no — harness gate` line in your review block.
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/flywheel-day3-exec/bin/tick
   Edit ONLY marathon-system/gh-792-gen4-sandbox-disjoint-first/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines. `Observed input:` accepts two strict, non-speculative forms:
   (1) Form 1 (observed failure or concrete `fileA:line` vs `fileB:line` artifact contradiction), or
   (2) Form 2 (unrunnable runtime hazard trace, permitted ONLY when verification requires an external service,
   multi-process concurrency, or browser/container runtime forbidden here: hop-by-hop `file:line` trace plus
   an exact `Clone probe:` command/script for the Builder's disposable full clone).
   Default severity for an unexecuted Form 2 hazard is `[Should]`; a `[Blocker]` must cite an observed failure
   (Form 1), and an unexecuted Form 2 hazard stays `[Should]` until a probe reproduces it. Read the probe before
   running it — refuse any probe that reaches the network, credentials, or paths outside the disposable clone
   and record the refusal as `[Unverified — clone probe failed/unavailable]` — then any Form 2 finding remains
   pending probe verification until the Builder executes safe `Clone probe:` commands (reproduced → fix +
   before/after output; falsified → `Declined — falsified by clone probe: <cmd → exit + output>`;
   errored/refused/unavailable → stays OPEN as `[Unverified — clone probe failed/unavailable]`, blocking
   `STATUS: Approved` until re-run cleanly or escalated/parked).
   A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
   This includes earlier [Nit] findings; only a newly raised [Nit] on an Approved verdict remains optional.
   The falsifier names the fixture or data and its expected result.
   The Builder may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

- Moved the resolved-path overlap guard in `utils/py/gen4_campaign.py` ahead of directory creation, clone deletion, and the clone subprocess. The guard refuses equality and containment in either direction.
- Added `TESTS-RESULTS/2026-11-27+GH-792/delivery.md` with the retained red and green probe results. Parsed the delivered Python source and confirmed its blob ID matches the retained symmetric-fix postimage. The existing campaign suite remains the gate.

unverified: fresh readiness probe and campaign self-test — this turn prohibits running the probe and gate. The harness is configured to run the campaign gate after the turn.

### Round 1 · Reviewer · agy

swept file: yes
gate run: no — harness gate

Reviewed all three artifact files in full (`utils/py/gen4_campaign.py` L1–409, `TESTS-RESULTS/2026-11-27+GH-792/delivery.md` L1–20, and `test/gh-gen4-phase5-campaign.sh` L1–92) against `PROJECT/2-WORKING/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md` and the retained preparation proof under `TESTS-RESULTS/2026-11-27+GH-792/`.

#### Verification performed (non-mutating)
- **AST parse, executable bit, and blob SHA-1 check** (exit `0`): `utils/py/gen4_campaign.py` parses cleanly, preserves mode `0o100755`, and hashes to git blob `604cc8c03fa5634cf1076103c36ca27e2ac159b8`, matching the `604cc8c03` postimage of `TESTS-RESULTS/2026-11-27+GH-792/review-round2-fixes/symmetric-fix.patch`.
- **Mock-only `make_sandbox` probe** (monkey-patched `os.makedirs`, `shutil.rmtree`, `subprocess.run`, `os.path.isdir`, zero disk/git writes; exit `0`):
  - `equal` (`<base>/clone`, `<base>`): raised `RuntimeError`, `calls=[]`.
  - `reverse-containment` (`<base>/clone/nested`, `<base>`): raised `RuntimeError`, `calls=[]`.
  - `descendant-348` (`<base>/host`, `<base>/host/inside`): raised `RuntimeError`, `calls=[]`.
  - `same-root-as-repo` (`<base>/host`, `<base>/host`) and `root-repo` (`/`, `<base>`): raised `RuntimeError`, `calls=[]`.
  - `prefix-sibling-disjoint` (`<base>/clone2`, `<base>`), `disjoint-fresh` (`<base>/src`, `<base>/sb`), and `disjoint-existing-clone` (`<base>/src`, `<base>/sb` with `.git`): proceeded through the existing `makedirs` → optional `rmtree` → `git clone` path unchanged.
- **Acceptance & receipt check**:
  - `utils/py/gen4_campaign.py:90-97` resolves `repo` and `clone` and rejects equality or containment in either direction before `makedirs`, `rmtree`, or `subprocess.run`.
  - `utils/py/gen4_campaign.py:348` (`make_sandbox(host, os.path.join(host, "inside"))`) remains on line 348 and still raises `RuntimeError`.
  - `TESTS-RESULTS/2026-11-27+GH-792/delivery.md` accurately summarizes the change, cites the verified blob SHA-1, links valid relative retained receipts (`review-round2-fixes/symmetric-fix.patch`, `base.txt` rc=1, `symmetric-fix.txt` rc=0, verified against `matrix.txt` and `provenance.jsonl`), and honestly discloses that runtime execution of the readiness probe and campaign gate was deferred to the harness.
  - `test/gh-gen4-phase5-campaign.sh`, `readiness_probe.py`, and retained proof files were left untouched per the capture doc's `non_goals`.
- **Runtime gate / readiness probe status**: `[Unverified — needs clone run]` for a fresh post-edit execution of `bash test/gh-gen4-phase5-campaign.sh` (runs in the harness after this turn) and `python3 TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py` (pre-verified byte-identically on blob `604cc8c03` in `review-round2-fixes/symmetric-fix.txt`).

#### Whole-file sweep findings (non-blocking `[Nit]`, pre-existing / out-of-scope per `non_goals`)
- `[Nit]` `utils/py/gen4_campaign.py:87-93`: if `sandbox_root` is `None` and `TMPDIR` points inside `repo`, `tempfile.mkdtemp` creates an empty `gen4-campaign.*` directory before the disjointness check raises `RuntimeError` (leaks the empty temp dir; no deletion occurs and explicit `sandbox_root` calls are unaffected).
- `[Nit]` `utils/py/gen4_campaign.py:338` (pre-existing, out of scope): `host_identity(host) == host_identity(host)` in `run_suite` is a tautology (relies on `not s["host_violations"]` rather than a pre-run snapshot).
- `[Nit]` `utils/py/gen4_campaign.py:126,134-139` (pre-existing, out of scope): `log` handle and `created_tmp` are not released via `try...finally` when `make_sandbox` or the baseline cleanliness check raises.
- `[Nit]` `test/gh-gen4-phase5-campaign.sh:10,17` (pre-existing, out of scope): `fixture-guard.sh` is sourced twice (benign); line 89 `rm -rf "$ROOT/.gen4-vacuous"` is now a harmless no-op since the descendant refusal no longer creates that directory.

**Verdict:** Approved

relay closed, no further turn needed

### Attestation · relay-drive — 2026-11-27T16:58:27Z
task: MARATHON-GH-792-GEN4-SANDBOX-DISJOINT-FIRST-TURN
reviewer: agy
status: Approved
reviewed-head: c9f85ccbae3347f5486eb33d0a0dfb75587837c3
added-range: 12054+3997
added-sha256: d1a3252c8102a606991ed862abac041ca045bda03c1544a97ac1a71dc4b9230b
config-sha256: ffa956d5b2f314e9749b86eee9b8f8a50ba212cf63b71773b8f6536be00f7233
gate-run: no
