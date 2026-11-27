---
Goal: Independent preparation QA — Conveyor packets for #1626 and #792 (Day 3 Flywheel, ledger #1611)
Date: 2026-11-27
NEXT: claude-a
STATUS: Open
---

# Context

Review two **preparation packets**. Do not review an implementation: none exists, and none may be written in this turn. Each packet is a capture doc with a `## Swarm Preflight Contract`, a retained readiness probe, probe-proof evidence and a PRS ledger row. Jog or start-task will consume them later as one-turn build tasks. The question is whether each packet is truthful, independent and safe to hand to that consumer.

Operational envelope: local developer tooling in XYZ-forge (single repo, local CLI). Commensurate complexity applies. XYZ-forge forbids new test suites and gate machinery (GH-831), so never ask for one. A retained manual probe under `TESTS-RESULTS/` is the sanctioned shape.

Read in full:
- `PROJECT/1-INBOX/GH-1626-DRY-RUN-SCRATCH-PRUNE.md`
- `TESTS-RESULTS/2026-11-27+GH-1626/readiness_probe.py`, `SUMMARY.md`, `simulated-fix.patch`, `probe-proof/*/`
- `PROJECT/1-INBOX/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md`
- `TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py`, `SUMMARY.md`, `simulated-fix.patch`, `probe-proof/*/`
- Source seams: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (lines 333-430, 1961-2013, 2535-2546, 3085-3097) and `utils/py/gen4_campaign.py` (lines 84-97, 340-350)
- Contract parser rules: `skills/1-hourly/conveyor/SKILL.md` step 3 (probe polarity) and `relay-automation/CONTRACT.example.md`

Issue text (live, quoted):
- #1626 suggested fix: "Pass `dry_run` to `prune_retained_scratch` and, in a dry run, report what *would* be removed without removing it, or skip the call when `dry_run` is true."
- #792 acceptance (plain bullets in the issue): "The overlapping call refuses with zero `makedirs`/`rmtree`/`subprocess` calls (red control: the current order records a delete first)." / "A disjoint candidate still clones as before." / "The existing self-test at `gen4_campaign.py:348` (`make_sandbox(host, os.path.join(host, "inside"))`) still refuses."

You MAY run each probe read-only (`export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 TESTS-RESULTS/2026-11-27+GH-<N>/readiness_probe.py`). Both write only under a fresh mkdtemp fixture inside `$TMPDIR` and delete it afterwards. Read them first. Do NOT run `test/*.sh`, `validate.sh` or pytest here.

Questions:

1. **Rejection of unfixed work.** Each probe is the `fix_probes` entry with `expect_nonzero: true`. What stops an unchanged or unfixed tree from being reported as delivered, and where is the observed rejection? Cite the `probe-proof/1-*` and `3-comment-only-edit` exit codes. Is there a fake fix that reads as landed but leaves the defect? For #1626: "delete pruning entirely" and "fix only `prune_retained_scratch` but not the call site". For #792: "catch the exception" and "only reorder `makedirs`".
2. **False negatives.** Would a correct fix in either shape the issues allow read as unfixed? For #1626, that means skipping the call vs. passing `dry_run` and reporting only. Check the probe's stubs (merge policy, origin, `pgrep`, lsof) and whether `land_prs([], …)` with an empty queue exercises the same `finally` path as a real dry run.
3. **Contract shape.** Are `target`, `gate`, `artifacts` and `fix_probes` valid for the parser, and is each gate an existing suite that covers the seam (`test/gh436-merge-cleanup.sh`, `test/gh-gen4-phase5-campaign.sh`)? Are the artifacts the smallest write set? Are the two write sets disjoint from each other, and from open PR #1607 (which edits `merge_cleanup.py` only inside `main()` / `_primary_blocks`, hunks at `:36` and `:2699-3062`)?
4. **Acceptance truthfulness.** #792's capture declares the three verbatim criteria as `[added]` because Preflight parses only checkbox bullets (filed as #1646). Is that declaration accurate and the minimum needed, and is the wording unchanged? #1626's three `[added]` criteria: are they faithful to the issue's suggested fix, without narrowing or widening scope?
5. **Probe safety.** Can either probe touch anything outside its mkdtemp fixture (real `$TMPDIR` siblings, the repo, the network, or `gh`)? In particular, does the #1626 probe redirect `tempfile.tempdir` before `merge_cleanup` first calls `gettempdir()`?
6. **Honesty of records.** Do the captures' recon, attempt history (0 attempts, no rows/PRs) and rating rationale match the evidence? Does anything overclaim readiness? Neither packet is enqueued or labelled, and neither may be.

Flag anything wrong, missing, mis-scoped or over/under-engineered, citing `file:line`. Every [Blocker] or [Should] that asks for a behavior change needs `Observed input:`, `Affected scope:` and `Falsifier:` lines. Write your verdict below. Change STATUS to Approved only if both packets pass; otherwise leave it Open and hand back with numbered findings.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex preparation QA — 2026-11-27

**Verdict: Changes requested.** Both packets have valid basic contracts and retained before/after controls. Close the probe coverage and isolation gaps before handing these packets to an execution consumer.

1. **[Should] GH-1626: make the manual probe discriminate on a nonempty landing queue.**
   - Observed input: `TESTS-RESULTS/2026-11-27+GH-1626/readiness_probe.py:67-74` always calls `land_prs([], ...)`, but `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:3092-3097` only calls it with a nonempty queue. Both reach the same `finally` once in `_land_prs_loop` (`:1965-1966, :2046-2048, :2529-2545`), so today's defect reproduces. A partial guard such as `if not dry_run or ordered_prs:` at `:2545` nevertheless passes both probe arms and still prunes on every real dry-run landing. The probe also prints the landing return codes without testing them (`readiness_probe.py:78-89`).
   - Affected scope: the existing manual probe and its retained controls. Use one fixture PR and stub its refresh to a deterministic draft/hold response so both arms reach the same cleanup without performing a landing or calling GitHub. Require both landing calls to complete successfully before crediting folder state.
   - Falsifier: from a disposable full clone, the current probe command with the nonempty fixture exits 1 on base, on a comment-only edit and on the empty-queue-only guard. Both issue-sanctioned fix shapes exit 0, with successful landing returns and execute-side pruning. Deleting the call entirely still fails.

2. **[Should] GH-792: align the remediation string and the probe with the reverse-descendant behavior in the plan.**
   - Observed input: `PROJECT/1-INBOX/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md:51` explicitly requires the reverse-descendant clause and `simulated-fix.patch:17-19` implements it. The contract at capture `:96` only names the existing check, which tests equality and clone-inside-source at `utils/py/gen4_campaign.py:95-97`. The probe inputs at `TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py:51-105` exercise equality, a disjoint pair, and clone-inside-source. Moving only the old predicate first satisfies all three. For source `<base>/clone/nested` and a fixture checkout already at `<base>/clone`, that predicate still falls through to the delete at `gen4_campaign.py:92-93`. This input is within the packet's own promised disjointness rule.
   - Affected scope: the existing manual probe and the one-function contract. Include reverse containment in the contract and test it with the same zero-call recorder, or explicitly resolve the discrepancy between the issue's narrowly worded fix and the packet's broader plan.
   - Falsifier: with a checkout at the candidate clone path and a source fixture nested below it, the early equality/forward-only variant must fail the probe. The symmetric variant must refuse with zero recorded calls and both fixture checkouts intact. The disjoint and existing self-test cases still pass.

3. **[Should] GH-792: make the probe's Git subprocesses inherit fixture-local settings.**
   - Observed input: `TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py:15,32-43` promises fixture-only local Git but forwards ambient Git settings into `init`, repo configuration and `commit`. For example, an inherited `GIT_DIR` redirects repository metadata despite `-C`, and an inherited `core.hooksPath` can make fixture commits execute code from outside the fixture. The clone at `utils/py/gen4_campaign.py:94` also inherits settings, including URL rewrite rules. The recorder runs subprocesses through unchanged at `readiness_probe.py:58-66`.
   - Affected scope: probe setup and teardown. Isolate Git environment/config and disable inherited hooks for the entire fixture run, including the product clone. Keep the genuine local-clone positive control. I did not rerun this probe in the relay worktree.
   - Falsifier: in a disposable full clone with a scratch-only external Git directory or a harmless hook writing a scratch sentinel, run the revised probe with those settings present. The outside fixture directory and sentinel remain unchanged, and base/fixed exit 1/0 still distinguishes behavior.

4. **[Should] Keep the existing proof inputs out of the builder's write set.**
   - Observed input: GH-1626 capture `:84-92` and GH-792 capture `:83-91` grant each whole evidence directory, including the exact script whose exit 0 is the landed decision in `utils/py/swarm_preflight.py:283-293`. The prepared-head receipts' `lane_plan.codex_lane` (GH-1626 JSON `:105-115`, GH-792 JSON `:103-113`) carry those directories into the lane. Replacing either probe with unconditional success would therefore make an unchanged source read landed from within the declared write set. More broadly, automatic inference also includes `test/gh549-work-events.sh` for #1626 and the existing phase-5 suite for #792.
   - Affected scope: each declared artifact list and effective lane disclosure. Keep the one product path, and use exact paths for any necessary delivery evidence, following the existing contract rules for new files. Preserve seeded probe/simulation receipts as review inputs. Document inferred test allowances and keep suite edits outside this task.
   - Falsifier: the resolved lane permits the narrow implementation and required evidence output but gives the builder no write scope over either readiness script or its historical proof. The existing probes still resolve and run from the evaluated ref.

5. **[Should] Correct the attempt-history wording and identify the readiness ref precisely.**
   - Observed input: the capture histories at GH-1626 `:61-63` and GH-792 `:60-62` say `work_events: none`. `releases.sql:6164-6165` and immutable SQLite reads of both this checkout and the primary show a `parked` event per issue from prep pickup. No `jog_queue` rows were found. The ratings in `releases.sql:1066-1067` match the captures. Each prepared-head receipt names `42f85a3ecbcf5b47776efd7b94c6a416275eb702` as its evaluated local `development` at JSON `:54-56`. GitHub-origin issue fetch verifies the issue lookup while that proof ref is still the local prepared head. Both captured Status tables mention publication followed by explicit pickup, with integration availability omitted. `utils/py/swarm_preflight.py:1560-1593,1727-1728` evaluates probes and artifact existence at the resolved ref. `utils/py/jog_run.py:2770-2789` aligns the execution clone to fetched development.
   - Affected scope: receipt and handoff wording. Record the preparation-only parked events and distinguish zero execution attempts from zero events. State that the packets are held pending preparation approval/publication and integration availability. Follow Conveyor's existing exact-integration-ref reread before calling them ready (`skills/1-hourly/conveyor/SKILL.md:105-109`).
   - Falsifier: the history reconciles the two parked rows with zero queue or native execution attempts. Any eventual published-ready claim cites a fresh successful preflight whose evaluated SHA is fetched integration and contains both the capture and its probe.

### Review evidence

- **Probe polarity and controls.** For each issue, `probe-proof/1-unfixed-at-prepared-commit/probe-<N>.rc:1` and `probe-proof/3-comment-only-edit/probe-<N>.rc:1` contain exit 1. The corresponding Preflight exits are 0 with probe verdict `unfixed`, meaning ready to attempt on that proof ref. Both simulated-fix probe receipts record exit 0 and Preflight exit 4 with verdict `landed`. Jog's lint exit 0 validates shape only (`utils/py/jog_run.py:1755-1760,1788-1795`). The delivery recheck requires landed probes (`utils/py/marathon_drive.py:2720,2789`). GH-1626 rejects removal of pruning through the execute positive control (exit 2 if dry-run preservation passes) and rejects a helper-only change whose unchanged caller supplies no dry-run signal and still deletes (exit 1). Either a caller-side skip or reporting-only helper can satisfy both filesystem assertions. GH-792 rejects catching the post-delete error because the source and call trace have changed, and rejects moving only `makedirs` because deletion/clone still precede refusal (`readiness_probe.py:76-85`). A launch/import error can also read unfixed under the current polarity, so a mechanical READY alone is weaker than the retained decisive probe output.
- **GH-1626 local reproduction and safety.** Ran `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 TESTS-RESULTS/2026-11-27+GH-1626/readiness_probe.py` after creating the scratch temp dir. Exit **1**. Decisive output: `Scratch pruning: removed 1 old retained clone folder(s)`, `dry-run:  land_prs rc=0 old-folder-kept=False`, `execute:  land_prs rc=0 old-folder-kept=False`, and `UNFIXED: a landing dry run pruned a retained scratch folder (GH-1626)`. The first fixture allocation uses inherited scratch; `readiness_probe.py:29-46` sets both `TMPDIR` and cached `tempfile.tempdir` before importing merge-cleanup. The real scan at `merge_cleanup.py:400-406` stays within that root. Capability and policy, origin, pgrep and lsof are stubbed. The planted child has no `.git`, so `merge_cleanup.py:313-329` starts no Git subprocess, and the empty loop and `resume=False` avoid per-PR and resume lookups. The control exercises pruning with the handle gate open. Live handle discovery is outside its evidence.
- **Gate and overlap.** Both target/gate/probe shapes parsed on the proof ref. `test/gh436-merge-cleanup.sh:11` invokes the existing orchestration suite. It exercises Phase 5, while the retained probe measures the old-folder behavior. `test/gh-gen4-phase5-campaign.sh:29-34,83-89` covers the self-test and CLI descendant refusal; the retained probe measures the equal-path deletion and ordering. The simulated-fix suite receipts report 227 successful tests and 17 passed/0 failed, respectively (`provenance.jsonl:13` for each). I did not execute either suite in this turn. The two declared implementation sets and the observed inferred suites are disjoint from each other. Open PR #1607 at `6d673caf9fc005ca1e64f42b5ff050b0ce02dda8` shares the #1626 source file but its hunks at old `:36,2699-3052` do not touch `:333-430` or `:2545`. Its diff also changes `scan_clones.py`, ledger files and project docs; describe the shared preparation-ledger files separately from source-hunk independence. [PR #1607](https://github.com/HiQS-Labs/XYZ-forge/pull/1607)
- **Acceptance and bounded scope.** GH-792's three checkboxes match the live issue wording. `utils/py/swarm_preflight.py:576,624-627,985-1005` explains why the issue parses to an empty list. All three `[added]` declarations are required by the current parser. The initial GitHub-origin receipt exits 5 with `diverged`, then the prepared-head receipt exits 0 with `match` and three declarations. GH-1626's acceptance preserves both issue-sanctioned shapes, existing execute semantics and the requested suite/manual evidence. Its frontmatter `:17-19` should say **no pre-existing retained scratch is deleted**. The current-run work directory still gets created at `merge_cleanup.py:2025` and removed on a clean run at `:2535-2536`, including on the simulated skip-call fix. That separate cleanup is outside the issue's proposed fix. [Issue #1626](https://github.com/HiQS-Labs/XYZ-forge/issues/1626), [issue #792](https://github.com/HiQS-Labs/XYZ-forge/issues/792), [parser issue #1646](https://github.com/HiQS-Labs/XYZ-forge/issues/1646)
- **Recon and ratings.** The recorded main call paths and the destructive operations match the seeded source. The ratings are provisional and consistent with the narrow fixes, one reported #1626 incident and #792's review-found input. GitHub shows both issues open, zero comments and no readiness label (#792 has its existing `bug` label). PR search surfaced related #1625/#788 work and no implementation PR for either issue. No queue or label changes were made. Graph evidence came from the nearest indexed Forge clone (generation 2026-11-26); the review cites the seeded worktree's source and receipts.

## Producer response — round 1 (Claude, 2026-11-27)

All five findings accepted and fixed in `db8a09385`, with the proof re-run in a fresh disposable full clone with a GitHub origin. Current proof is in `TESTS-RESULTS/2026-11-27+GH-<N>/probe-proof-r1/`; per-finding evidence is in `TESTS-RESULTS/2026-11-27+GH-<N>/review-round1-fixes/README.md`.

1. **F1 fixed.** The #1626 probe drives `land_prs` with one fixture PR whose refresh is stubbed to a draft. It credits folder state only when both calls return 0 with exactly one refresh. Matrix: base 1, skip-call fix 0, report-only fix 0, your `if not dry_run or ordered_prs:` fake 1, deleting the call 2, comment-only edit 1.
2. **F2 fixed.** The #792 probe adds reverse containment (a checkout at `<base2>/clone`, source at `<base2>/clone/nested`), with zero recorded calls and both checkouts intact. Goal and remediation criteria name all three overlap shapes. The forward-only early check now exits 1; the symmetric fix exits 0.
3. **F3 fixed.** `isolate_git()` covers the whole process, including the product's clone. Under a hostile `GIT_DIR` and a global hook config, the fixed tree exits 0 with no sentinel and `outside.git` unchanged. Negative control: the pre-isolation probe ran the hook twice.
4. **F4 fixed.** Each artifact list is the product file plus a new `TESTS-RESULTS/2026-11-27+GH-<N>/delivery.md`, listed in `artifacts_new` with a `path_absent` probe. The probe and proof are outside the lane. Inferred suites are documented, and editing them is a non-goal.
5. **F5 fixed.** History records the preparation `parked` event and zero execution attempts. Status says held pending review approval, publication, merge, then a fresh preflight at the fetched integration ref. No readiness is claimed from the proof ref.

Round-1 proof (`probe-proof-r1/`): unfixed 0 READY / probe 1; simulated fix plus delivery receipt 4 STALE / probe 0; comment-only edit 0 READY / probe 1; Jog lint 0 in every state. Issue fetched: #1626 `no-issue-section` (advisory), #792 `match`. Frontmatter note fixed. #1607 overlap wording unchanged: its source hunks are disjoint. This preparation PR will touch the shared ledger files `releases.db`/`releases.sql`, which any merge reconciles.

Please re-review the round-1 changes: the two probes, both captures' contracts and Status, and `probe-proof-r1/`. Approve if both packets now pass.

## Codex preparation QA — round 2, 2026-11-27

**Verdict: Changes requested.** GH-1626's revised behavioral evidence passes preparation review. GH-792 still has one coverage gap against its explicit three-shape, zero-mutation contract. Both packets remain held.

1. **[Should] GH-792: require zero mutation calls for the clone-inside-source case, too.**
   - Observed input: `PROJECT/1-INBOX/GH-792-GEN4-SANDBOX-DISJOINT-FIRST.md:18-21,113` requires all three overlap shapes to refuse before mutation. `TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py:84-112,122-138` checks the call trace for equality and source-inside-clone. The recorder has been restored by the time the probe reaches clone-inside-source at `readiness_probe.py:149-162`. That arm accepts any `RuntimeError` and only rechecks the original sentinel and `.git`. An early guard for equality and source-inside-clone, leaving the old forward guard after the mutations in `utils/py/gen4_campaign.py:90-97`, can therefore still create `host/inside/clone` and pass. The existing suite catches the refusal, too, and its CLI arm removes the descendant path without checking prior side effects (`gen4_campaign.py:346-351`, `test/gh-gen4-phase5-campaign.sh:83-89`).
   - Affected scope: the existing GH-792 manual probe and its red control. Record the same three calls in the descendant arm and require the proposed sandbox root to remain absent, with the original source intact. Keep the disjoint control and existing suite.
   - Falsifier: equality and reverse containment refuse early, but the old forward refusal runs after clone. The revised probe must reject that partial fix specifically on the forward arm. The symmetric correction still passes and the other controls retain their polarity.
   - Local evidence: the following scratch-only simulation extracts the seeded function bodies and substitutes fixture creation for Git. It tests the missing assertion with the product's ordering intact. Shell exit **0** observed, with `descendant: refused`, `FIXED: overlap refuses before any mutation; disjoint and descendant behavior kept`, and `probe_rc=0 descendant_clone_created=True`. No subprocess or product Git command ran.

   ```bash
   export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
   python3 - <<'PY'
   import ast
   import os
   import shutil
   from pathlib import Path
   from tempfile import TemporaryDirectory
   from types import SimpleNamespace

   probe_path = Path("TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py")
   nodes = ast.parse(probe_path.read_text()).body
   selected = [n for n in nodes if isinstance(n, ast.FunctionDef) and n.name in {"main", "rec2", "intact"}]
   source = Path("utils/py/gen4_campaign.py").read_text()
   sandbox = next(n for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.name == "make_sandbox")
   original = ast.get_source_segment(source, sandbox)
   partial = original.replace("    os.makedirs(sandbox_root, exist_ok=True)\n    clone = os.path.join(sandbox_root, \"clone\")",
       "    clone = os.path.join(sandbox_root, \"clone\")\n"
       "    rh, rc_ = os.path.realpath(repo), os.path.realpath(clone)\n"
       "    if rc_ == rh or rh.startswith(rc_.rstrip(os.sep) + os.sep):\n"
       "        raise RuntimeError('early overlap refusal')\n"
       "    os.makedirs(sandbox_root, exist_ok=True)")
   assert partial != original
   sentinel = "gh792 sentinel\n"

   def make_repo(path):
       (path / ".git").mkdir(parents=True)
       (path / "sentinel.txt").write_text(sentinel)

   def clone_stub(argv, **kwargs):
       assert argv[:4] == ["git", "clone", "-q", "--no-hardlinks"]
       make_repo(Path(argv[-1]))

   g = SimpleNamespace(os=SimpleNamespace(path=os.path, sep=os.sep, makedirs=os.makedirs),
                       shutil=SimpleNamespace(rmtree=shutil.rmtree),
                       subprocess=SimpleNamespace(run=clone_stub))
   product = dict(vars(g))
   exec("from __future__ import annotations\n" + partial, product)
   g.make_sandbox = product["make_sandbox"]
   with TemporaryDirectory() as folder:
       fx = Path(folder)
       env = dict(Path=Path, SENTINEL=sentinel, make_repo=make_repo, g=g)
       exec(compile(ast.Module(body=selected, type_ignores=[]), str(probe_path), "exec"), env)
       result = env["main"](fx)
       leaked = (fx / "host/inside/clone").is_dir()
       print(f"probe_rc={result} descendant_clone_created={leaked}")
       assert result == 0 and leaked
   PY
   ```

2. **[Nit] Correct two stale evidence descriptions.** GH-1626's capture at `PROJECT/1-INBOX/GH-1626-DRY-RUN-SCRATCH-PRUNE.md:52` describes the current probe with an empty queue. Name that reproduction as round-0 history or show the current one-PR call at `TESTS-RESULTS/2026-11-27+GH-1626/readiness_probe.py:90-94`. Both `SUMMARY.md:11` notes under the issue evidence directories should distinguish the delivery-file probe's individual `unfixed` verdict from the aggregate `AMBIGUOUS` exit 7 when the behavioral probe is landed but the receipt is missing (`utils/py/swarm_preflight.py:265-266,299-305,1641-1643,1943`). Delivery requires both probes landed (`utils/py/marathon_drive.py:2713-2720,2778-2789`).

### Round-1 dispositions and proof read-back

- **F1 verified.** With `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"` set, `python3 TESTS-RESULTS/2026-11-27+GH-1626/readiness_probe.py` exited **1**. Both arms logged `land_prs rc=0 refreshed=[9] old-folder-kept=False` and the probe reported `UNFIXED: a landing dry run pruned a retained scratch folder (GH-1626)`. The draft branch reaches the shared `finally` without a landing or GitHub lookup (`merge_cleanup.py:1965-1966,2084-2096,2531-2545`). Both allowed fix shapes pass the retained controls, and deletion of the prune call fails the execute arm (`review-round1-fixes/README.md:5-14` under GH-1626).
- **F2's reverse case and F3's Git isolation verified by source and retained receipts.** The GH-792 contract now names reverse containment. The retained forward-only control fails, and the symmetric control logs zero calls for equality and reverse containment. `readiness_probe.py:58-70,165-169` clears inherited Git settings before any fixture Git or product clone. The producer's hostile-environment receipts show the sentinel absent with isolation and present on the old control. I did not rerun the Git-backed case or either existing suite in this worktree. Finding 1 concerns the separate forward-case ordering assertion.
- **F4 and F5 verified.** The embedded contract fields in all six round-1 Preflight JSON receipts match the captures. The effective lanes each contain the product path, an exact `delivery.md` and the disclosed inferred suite. Each round-1 base and comment-only receipt has Preflight/probe/Jog lint exits `0/1/0`. Each simulation plus delivery receipt has `4/0/0`. The base evaluated proof SHA is `db8a09385c3aee9e6d77eafe0201c3ff257584ed`; the Status tables reserve the readiness claim for a fresh preflight at fetched integration after publication and merge. Immutable SQLite read-back also confirmed one `parked` event per issue, no Jog rows and ratings `70/65/50/90` and `50/60/50/90`. The accepted criteria and source-hunk overlap disposition from round 1 remain in force. Source references use the seeded worktree. The nearest graph's generation is 2026-11-26, and the probes are absent from that index, so I checked the local source directly.

## Producer response — round 2 (Claude, 2026-11-27)

Both items fixed in `b32919635`, with a fresh proof in `TESTS-RESULTS/2026-11-27+GH-<N>/probe-proof-r2/` (GitHub origin, issue fetched).

1. **F1 fixed.** The #792 descendant arm now records `makedirs`/`rmtree`/`subprocess` calls. It requires zero calls and `<host>/inside` never created. Matrix (`TESTS-RESULTS/2026-11-27+GH-792/review-round2-fixes/`):
   - your fake (equality and reverse early, forward check after clone): **1**, failing on the descendant arm with `mutation calls=['makedirs', 'subprocess']` and `host/inside` created
   - symmetric fix: 0
   - forward-only check moved early: 1 (reverse arm)
   - base: 1
2. **Nit fixed.** The #1626 capture's observed line describes the one-PR probe. Both SUMMARY notes say a fix without `delivery.md` is AMBIGUOUS (exit 7). That is now witnessed by state `2b-simulated-fix-no-receipt`: Preflight 7, probe 0.

Round-2 proof, per issue (Preflight / probe / Jog lint): unfixed 0/1/0; simulated fix plus receipt 4/0/0; fix without receipt 7/0/0; comment-only edit 0/1/0. Issue fidelity: #1626 `no-issue-section` (advisory), #792 `match`.

Please re-review the round-2 delta and approve if both packets pass.
