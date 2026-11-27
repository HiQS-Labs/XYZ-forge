# GH-1656 final QA — non-ledger GitHub conflict: local-merge rung or a precise stop
STATUS: Open
NEXT: codex (Reviewer)

## Context

Final independent review of the completed implementation for
https://github.com/HiQS-Labs/XYZ-forge/issues/1656, against its plan
`PROJECT/2-WORKING/GH-1656-NON-LEDGER-CONFLICT.md` (approved by you in
`relay-system/2026-11-27/gh1656-plan-qa.md`, round 4).

**Operational envelope:** a local operator CLI that lands this repo's own PRs. Grade against the
stated requirements and commensurate complexity. Repo rule (`AGENTS.md`, GH-831): no new suites or
registry entries — the cases live in the existing `test/gh534_phase_b_tests.py`. A new test file or
registry entry in the diff would be a finding.

Diff: `git diff 52813e56f..HEAD -- skills/ test/` (base `52813e56f`). Files:
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` — `land_via_local_merge`, B1 handoff
  message, dry-run preview, final-eligibility routing, `_record_merge_outcome(rung=)`,
  `merged_head` on rung landings.
- `skills/2-daily/merge-cleanup/scripts/batch_record.py` — `rung` / `rung_oid`, status rendering.
- `skills/2-daily/merge-cleanup/SKILL.md` — one Phase 5 bullet.
- `test/gh534_phase_b_tests.py` — stub refusal + ancestry-inferred MERGED (`infer_merged`,
  `confirm_lag`, `confirm_withheld`, `confirm_oid`), `TestGh1656NonLedgerConflict` (13 cases).
- Evidence: `TESTS-RESULTS/2026-11-27+GH-1656/` (red on base, green on candidate, all
  merge-cleanup suites in a disposable clone, a mutation control, and a smoke of the real CLI with
  a real pre-push hook).

**One deliberate deviation from the plan, for your adjudication:** step 3 said a final live
`mergeable` other than MERGEABLE/CONFLICTING stops. The implementation routes only `CONFLICTING`
to the rung/stop and leaves every other value on the unchanged `execute_pr_merge` path with
`--match-head-commit`. Reason: GitHub recomputes mergeability after each landing, so a PR that was
MERGEABLE can read UNKNOWN at the final refresh; `gh pr merge` already decides for itself there, and
stopping would regress the normal path that works today. The R3 dry-run requirement for UNKNOWN is
unchanged (the GH-736 poll stops the dry run).

Questions:

1. Is each requirement met in code, with the cited observed rejection on base? R1 (rung lands a
   CONFLICTING clean PR under `merge`), R2 (dirty → message, squash → stop, both before
   `gh pr merge`), R3 (dry run never says Would merge for CONFLICTING or UNKNOWN), R4 (batch row
   names the rung). Cite `file:line`.
2. Does `land_via_local_merge` match the approved contract: MERGE_HEAD-aware abort, parents/tree
   equality before any push, `XYZ_SKIP_PREPUSH` stripped, exact-base lease, ambiguous-push readback
   via ancestry (1 = rejected, other failure = unknown), single push, confirmation requiring MERGED +
   pin + base + merge commit == candidate?
3. Post-push stops: no `merge_oid`, no reconcile, no next PR, rung + candidate recorded, the stop
   line naming candidate/pin/target and `--reconcile-pr N`. Does the finalizer's `stopped: …`
   status carry it (`merge_cleanup.py` `_record_batch_outcomes`)?
4. Test honesty: do the stub changes mirror GitHub (refusal only for a forced CONFLICTING PR;
   MERGED only from real ancestry, opt-in per test) without weakening existing controls? Does each
   new case observe the real seam (bare origin, real push, real hook) rather than a mock?
5. The deviation above — accept or reject, with a falsifier if rejecting.
6. Anything over-built, duplicated (a second writer or push path), or missing?

Rules: `[Blocker]`/`[Should]` asking for a behaviour change need `Observed input:`,
`Affected scope:`, `Falsifier:`. Read-only probes under `.relay-scratch/` only; no test suites in
the relay worktree. Set `STATUS: Approved` only if it is ready to publish.


## Log

### Reviewer (codex) — Round 1

**Verdict: Changes requested.** The actual Forge hook rejects the detached candidate before it reaches the pre-push suites. The bare-origin fixture and the smoke both use substitute hooks, so their green results do not clear R1 for Forge.

1. **[Blocker] Make the local merge candidate eligible for the existing Forge hook.**

   **Observed input:** `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1122–1126` installs the landing clone's Forge hook. The rung detaches at the gated base, creates a new candidate there, then pushes `HEAD:refs/heads/development` without reserving a qualification attempt (`1223–1243`). The installed stub forwards the push's source ref, candidate SHA and destination to `gate_receipt.py admit` before it delegates to the actual gate (`githooks/install.sh:153–160,178–190`). The source is `HEAD` and the checkout has no current branch, so the administrative-branch exemption cannot apply. The detached integration-tip exemption only admits a SHA already named by one of the local or origin administrative refs. At pre-push time those refs still point at the base or another older commit, while detached HEAD is the newly created candidate (`utils/py/gate_receipt.py:92–129`). Admission exits 2 on refusal (`339,368–370`), leaving origin unchanged.

   The following narrow read-only probe ran against the seeded admission function, supplying the detached-branch and admin-ref readbacks in memory, with no Git calls.

   ```sh
   python3 -B -c 'import sys; from unittest.mock import patch; sys.path.insert(0, "utils/py"); import gate_receipt as g; c="c"*40; git=lambda _,*a: "" if a[0]=="branch" else c if a[1]==c+"^{commit}" else "b"*40; exec("with patch.dict(g.os.environ, {}, clear=True), patch.object(g, \"attempt_git\", git):\n g.attempt_admission(\".\", c, \"HEAD\", destination_ref=\"refs/heads/development\")")'
   ```

   Exit 1. Decisive output: `ValueError: task qualification has no attempt reservation; use gate_receipt.py attempt-start` at `gate_receipt.py:129`.

   **Affected scope:** R1 with the repository's installed hook and an ordinary operator environment. Use the existing administrative publication path in the disposable landing clone or another existing admission path that covers this exact candidate. Preserve the tree and parent checks, exact-base lease, one push and full hook enforcement. The fixture stubs wiring at `test/gh534_phase_b_tests.py:225–232`. Its rejecting-hook test uses a shell replacement (`861–879`), and `TESTS-RESULTS/2026-11-27+GH-1656/smoke.py:20–32` installs a hook that logs the environment then exits 0. Both prove their stated seams, while the rejection in Forge's admission code needs a real-hook witness.

   **Falsifier:** In a disposable full clone, the rung with the installed Forge hook admits the exact candidate under a clean environment and reaches the normal gate. With that gate green, bare origin advances from the captured base to the exact candidate. The lease and rejecting-hook controls still hold.

   **Clone probe:** Run the following from a disposable full clone of the candidate with the normal gate toolchain. The current implementation is expected to fail before the suites with the missing-reservation diagnostic and the final line showing the old base at origin. After the fix, replay the rung's actual publication shape using the real installer and retain the gate and ref evidence. [Unverified — needs clone run]

   ```bash
   set -eu
   unset XYZ_SKIP_PREPUSH XYZ_ATTEMPT_CONTEXT MERGE_CLEANUP_RECORD GITHUB_ACTIONS
   probe=$(mktemp -d "${TMPDIR:-/tmp}/gh1656-real-hook.XXXXXX")
   test -d "$probe"
   base=$(git rev-parse --verify HEAD)
   git clone -q --bare --no-local "$PWD" "$probe/origin.git"
   git -C "$probe/origin.git" update-ref refs/heads/development "$base"
   git clone -q --branch development "$probe/origin.git" "$probe/landing"
   cd "$probe/landing"
   git config user.name "GH-1656 probe"
   git config user.email gh1656-probe@example.invalid
   bash githooks/install.sh
   bash githooks/install.sh --check
   git checkout -q --detach "$base"
   git commit -q --allow-empty -m "GH-1656 probe pin"
   pin=$(git rev-parse HEAD)
   git checkout -q --detach "$base"
   git merge --no-ff --no-edit "$pin"
   candidate=$(git rev-parse HEAD)
   rc=0
   git push --force-with-lease="refs/heads/development:$base" origin HEAD:refs/heads/development >"$probe/push.log" 2>&1 || rc=$?
   cat "$probe/push.log"
   remote=$(git --git-dir="$probe/origin.git" rev-parse refs/heads/development)
   printf 'push_rc=%s base=%s candidate=%s origin=%s\n' "$rc" "$base" "$candidate" "$remote"
   ```

2. **[Should] Give the operator an executable recovery instruction after confirmation times out.**

   **Observed input:** `merge_cleanup.py:2525–2528` tells the operator to run `--reconcile-pr N` after checking the candidate and head. `2780–2784,2851` make execution opt-in and default the target to development. The recovery handler passes through dry-run mode and skips durable reconciliation writes and batch updates in that mode (`2986–3005`). The stop prints the target, but the instruction only asks the operator to check the merge commit and head.

   **Affected scope:** The new unconfirmed-publication diagnostic and its final batch-row copy. Include `--execute` and the same `--integration-branch` in the recovery instruction. Require the operator to verify MERGED, candidate, pin and target before using it. Keep the mismatch outcome on investigation and the unknown outcome on publication verification.

   **Falsifier:** The confirmation-withheld case gives an executable recovery command with the original target and all three identity checks. Following it after the exact response reconciles and updates the batch row once, including the original rung label.

**Remaining review**

- **R1/R2:** The landing simulation precedes the ledger gate (`merge_cleanup.py:1135–1141,2369–2379`). Final eligibility checks state, target and pin before routing final CONFLICTING to the rung under merge policy, or stopping before stacked-dependent edits under squash/rebase (`2466–2512`). The B1 handoff reports non-ledger dirty paths and skips the affected PR (`2282–2294`). The base receipt shows the clean case reaching the GitHub-style refusal at `red-base.log:77–86`, squash reaching the same refusal at `88–95`, and dirty handoff missing the new diagnostic at `119–126`.
- **R3/R4:** The bounded initial poll and undecided stop precede the dry-run preview (`merge_cleanup.py:1971–1985,2196–2199,2454–2465`). The conflict preview was red on base (`red-base.log:128–135`), with persistent UNKNOWN an unchanged control (`test/gh534_phase_b_tests.py:1038–1045`). Exact rung identity goes through the existing touched outcome fields and renders only when `merge_oid == rung_oid` (`batch_record.py:123–142,291–312,380–389`). The isolated renderer was red on base (`red-base.log:185–193`) and the candidate two-PR case asserts the published issue body (`test/gh534_phase_b_tests.py:834–848`).
- **Publication and stops:** The source handles optional MERGE_HEAD and compares both parents and the gated tree before the push. The push strips `XYZ_SKIP_PREPUSH` and leases the exact base. On nonzero it fetches the destination and interprets ancestry 0 as published, 1 as refused and other or missing evidence as unknown, with a single push call. Confirmation requires MERGED plus matching head, base and merge OID (`merge_cleanup.py:1215–1265`). Unknown, unconfirmed and mismatch set rung/candidate fields, log candidate/pin/target and return before the tail; the confirmed branch passes the candidate to hosted lookup. The finalizer moves the logged reason into the current row's stopped status and syncs the batch (`461–464,2032–2079,2513–2563`). The recovery command is appropriate after exact confirmation. The explicit mismatch/unknown diagnostics correctly prioritize investigation or readback.
- **Test evidence:** The forced-CONFLICTING refusal and opt-in ancestry inference preserve existing false-success controls (`test/gh534_phase_b_tests.py:74–108,163,579–587,784–790`). Bare-origin reads and the lease/lost-ack controls exercise real pushes; the hosted test isolates the lookup seam and the receipt records its failing mutation. The fixture's R1 assertions check parents, not tree identity. The smoke only prints parents and hook hits and compares the adjacent-run ref with another sample taken after that run (`smoke.py:55–70`). For the hook witness above, assert the published parents and tree, require gate evidence, and capture the adjacent path's before/after refs across the run. The earlier base log contains fixture errors disclosed in its README, so its red evidence is limited to the decisive assertions above.
- **Plan deviation:** Accept final UNKNOWN on the existing GitHub-managed path. The initial undecided stop remains, and this later route still carries the exact-head check and requires GitHub to report a matching MERGED result (`merge_cleanup.py:2196–2199,2502–2538,550–580`). Routing only final CONFLICTING to local publication preserves the server's decision on the ordinary path.
- **Scope:** The explicit leased push serves the case the GitHub merge path refuses. It shares the existing hook, batch writer and reconciliation tail. The R1 admission repair should use the existing gate rather than add another writer or gate.

**Evidence limits:** Verify-tier source review against the seeded worktree. The nearest indexed Forge clone was from generation `2026-11-26T04:31:47Z`, predating the rung. The graph trace call was denied, so the findings use direct source reads and the narrow admission probe above. The producer's focused receipts name `c620786b7`; no reviewer phase gate was specified or run, and real-hook publication awaits the clone probe.

### Producer (claude-a), round 1 dispositions

1. **[Blocker] Accepted — reproduced, fixed, witnessed on the real hook.** Your clone probe,
   committed as `TESTS-RESULTS/2026-11-27+GH-1656/real-hook-probe.sh`, ran against Forge's real
   installer: the detached shape is refused (`gate-attempt: REFUSED — task qualification has no
   attempt reservation`, origin unchanged; `real-hook-detached.log`). Fix in `c901c5f9f`: after
   the parent/tree checks, the rung checks out local `<branch>` at the candidate (verified) and
   pushes `refs/heads/<branch>:refs/heads/<branch>` with the same lease. This is the hook's existing
   administrative admission, the same shape as `commit_and_push_phase5_writes`; no new admission
   path or writer. Same probe, branch shape: admitted, `pre-push: full gate GREEN in 1438s —
   pushing.`, origin = exact candidate (`real-hook-branch.log`). Focused class 13/13 green after.
2. **[Should] Accepted.** The unconfirmed stop now prints the identity to verify (MERGED into
   `<branch>`, head `<pin>`, merge commit `<candidate>`) and the exact command
   `merge_cleanup.py --primary <p> --integration-branch <branch> --reconcile-pr N --execute`.
   Mismatch keeps "investigate", unknown keeps "verify origin/<branch>".
   Smoke strengthened per your note: published tree == gated merge tree, one hook run with the
   override stripped, origin before == after across the adjacent re-run (`smoke.log`, PASS).
   Plan deviation: thank you — accepted as recorded.

### Reviewer (codex) — Round 2

**Verdict: Changes requested.** The real-hook blocker is resolved for Forge's `development` branch. The confirmation-timeout recovery command still fails for the documented primary path.

1. **[Pass] Installed-hook admission.** `merge_cleanup.py:1232–1247` verifies the parents and gated tree, puts the candidate on the local integration ref, checks hook wiring, and pushes that ref once with the original exact-base lease and `XYZ_SKIP_PREPUSH` stripped. This matches the administrative admission in `utils/py/gate_receipt.py:92–111`. The real installer replay uses both source ref forms (`TESTS-RESULTS/2026-11-27+GH-1656/real-hook-probe.sh:18–37`). The detached control returned `push_rc=1`, `published=no` with the missing-reservation diagnostic (`real-hook-detached.log:2–3`). The branch replay recorded `pre-push: full gate GREEN in 1438s — pushing.`, `push_rc=0`, and identical candidate and origin OIDs (`real-hook-branch.log:16–17`). The CLI smoke separately witnessed exact published parents and tree, zero `pr merge` calls for the rung, one hook invocation with the override unset, and an unchanged origin across the adjacent run (`smoke.log:19–30`). The accepted final-UNKNOWN deviation and the round-one R2–R4 conclusions still stand.

2. **[Should] Make the printed recovery command runnable from the operator's shell.**

   **Observed input:** `merge_cleanup.py:2529–2534` now names MERGED, the target, pin and merge commit and supplies `--execute`. It interpolates the primary path directly into shell text and starts with `merge_cleanup.py`. The skill's documented invocation uses `python3` and quotes the primary path (`skills/2-daily/merge-cleanup/SKILL.md:703`). The file lacks an executable bit in the seeded worktree. This read-only probe evaluated the seeded string expression and tokenized the result without calling the CLI.

   ```sh
   export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
   mkdir -p "$TMPDIR"
   python3 -B - <<'PY'
   import ast
   import shlex
   from pathlib import Path

   source = Path("skills/2-daily/merge-cleanup/scripts/merge_cleanup.py")
   tree = ast.parse(source.read_text())
   expression, = [
       node.value.orelse for node in ast.walk(tree)
       if isinstance(node, ast.Assign)
       and any(isinstance(target, ast.Name) and target.id == "nxt" for target in node.targets)
       and isinstance(node.value, ast.IfExp)
       and "--reconcile-pr" in ast.unparse(node.value)
   ]
   primary = "/Users/noelsaw/Documents/GH Repos/XYZ-forge"
   text = eval(compile(ast.Expression(expression), str(source), "eval"), {
       "p_num": 19, "branch": "development", "pinned": "a" * 40, "cand": "b" * 40, "primary_repo": primary
   })
   command = text.split(chr(96))[1]
   argv = shlex.split(command)
   actual = argv[argv.index("--primary") + 1]
   print("command:", command)
   print("parsed --primary:", actual)
   print("expected --primary:", primary)
   assert actual == primary, "recovery command splits the primary path"
   PY
   ```

   Exit 1. Decisive output `parsed --primary: /Users/noelsaw/Documents/GH` and `expected --primary: /Users/noelsaw/Documents/GH Repos/XYZ-forge`, followed by `AssertionError: recovery command splits the primary path`.

   **Affected scope:** Confirmation-timeout recovery after the rung has already published, including the command carried into the stopped batch row by `merge_cleanup.py:2054–2071`. Render actual argv with shell quoting and identify the Python interpreter and script path. Preserve the identity checks and the mismatch and unknown stop behavior.

   **Falsifier:** With the documented space-containing primary path, the stop emits a command whose shell tokens include one complete primary path, the original integration branch, `--reconcile-pr 19` and `--execute`, and whose interpreter and script resolve from a foreign working directory. In the existing confirmation-withheld fixture, once exact MERGED appears, executing the recovery command reconciles the correct PR and retains the rung label. The current fixture ends at the stop (`test/gh534_phase_b_tests.py:955–978`), and the renderer control from round one covers label identity independently.

**Evidence limits:** The Forge graph is from generation `2026-11-26T04:31:47Z` in a different checkout. Coverage and symbol lookup were followed by direct reads of the seeded code. The committed real-hook and updated CLI smoke receipts identify source `95f2d61db7de7d5264e3449eda65fd0c2fc10791` in `provenance.jsonl:5–7`. The probe proves the installed hook and branch-ref publication seam against a bare origin. No reviewer phase gate was specified or run.


### Producer (claude-a), round 2 dispositions

2. **[Should] Accepted.** The recovery command is now `shlex.join([sys.executable,
   <resolved merge_cleanup.py>, "--primary", <primary>, "--integration-branch", <branch>,
   "--reconcile-pr", N, "--execute"])`, so a primary path with spaces stays one token and the
   interpreter/script resolve from any directory. The confirmation-withheld case now shlex-splits
   the printed command and asserts the full `--primary`, `--reconcile-pr N`, `--execute` and an
   existing script path. Focused class 13/13 green (`green-focused.log`). Executing recovery end to
   end is the existing `--reconcile-pr` path, unchanged here; the rung label across that write is
   covered by the renderer control (`merge_oid == rung_oid`).

### Reviewer (codex) — Round 3

VERDICT: PASS
Basis: The recovery command preserves the primary path and original target, and its interpreter and script resolve from a foreign working directory. The installed-hook blocker was cleared in round 2.

**[Pass] Confirmation-timeout recovery command.** `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2529–2537` quotes the argument list with `shlex.join`, supplies an absolute script path and `sys.executable`, names the MERGED state and landing identity, and exits before the merge and reconciliation tail. The stop includes full candidate and pin OIDs. Mismatch still directs investigation. The fixture checks the parsed primary path, PR number, execute flag, and script path at `test/gh534_phase_b_tests.py:975–982`.

The following read-only probe evaluated the seeded expression and invoked the printed interpreter and script with `--help` from scratch.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 -B - <<'PY'
import ast
import os
import shlex
import subprocess
import sys
from pathlib import Path

source = Path("skills/2-daily/merge-cleanup/scripts/merge_cleanup.py").resolve()
expression, = [
    node.value for node in ast.walk(ast.parse(source.read_text()))
    if isinstance(node, ast.Assign)
    and any(isinstance(t, ast.Name) and t.id == "nxt" for t in node.targets)
    and isinstance(node.value, ast.IfExp) and "--reconcile-pr" in ast.unparse(node.value)
]
evaluate = compile(ast.Expression(expression), str(source), "eval")
primary = "/Users/noelsaw/Documents/GH Repos/XYZ-forge"
branch = "development"
context = dict(sys=sys, Path=Path, shlex=shlex, __file__=str(source),
               outcome="unconfirmed", p_num=19, branch=branch, pinned="a"*40,
               cand="b"*40, primary_repo=primary)
message = eval(evaluate, context)
argv = shlex.split(message.split(chr(96))[1])
assert argv == [sys.executable, str(source), "--primary", primary,
                "--integration-branch", branch, "--reconcile-pr", "19", "--execute"], argv
assert "MERGED into development at head aaaaaaaaaa with merge commit bbbbbbbbbb" in message
assert eval(evaluate, dict(context, outcome="mismatch")) == "investigate before reconciling"
result = subprocess.run([*argv[:2], "--help"], cwd=os.environ["TMPDIR"],
                        capture_output=True, text=True)
assert result.returncode == 0 and "--reconcile-pr" in result.stdout, result.stderr
print("argv:", argv)
print(f"foreign-cwd CLI --help = {result.returncode}; identity and mismatch text passed")
PY
```

Exit 0. Decisive output: the parsed argv contained `--primary`, `/Users/noelsaw/Documents/GH Repos/XYZ-forge` as one argument, `--integration-branch`, `development`, `--reconcile-pr`, `19`, and `--execute`; `foreign-cwd CLI --help = 0; identity and mismatch text passed`. Round 2's equivalent token check failed on the split primary path.

`merge_cleanup.py:2980–3012` sends the confirmed PR through the existing reconciliation path and updates the unfinished batch with the returned merge OID. The update preserves the saved rung fields, and `batch_record.py:291–312,380–389` renders the label only for the exact recorded candidate. I traced this path in source. The probe stopped at CLI dispatch with `--help`.

**Evidence limits.** The earlier R1–R4 and final-UNKNOWN adjudications stand. The retained real-hook receipt covers branch-ref publication at `95f2d61db7de7d5264e3449eda65fd0c2fc10791`. The focused log shows 13 tests passing, and the producer reports a rerun after the quoting fix. The seeded provenance still lists the earlier focused revision for that log. The read-only probe independently verifies the latest quoting change. The graph generation `2026-11-26T04:31:47Z` belongs to a different checkout and predates the change. Seeded source and receipts supplied the review evidence. No reviewer phase gate was specified or run.

### Producer (claude-a), note after round 3

relay-drive refused to attest the round-3 PASS (`review-body-rewritten`): the round-3 block was
inserted above the previous turn marker instead of appended at the end. No code changed since
`464e27090`. Please re-confirm the round-3 verdict by **appending** a short block at the very end
of this file (do not edit anything above it), with your final `VERDICT:` line and `STATUS`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Reviewer (codex) — Round 4 confirmation

VERDICT: PASS

I reconfirm round 3 against the seeded source. The retained Forge-hook receipt shows one successful branch-ref push and exact candidate at origin. The smoke records the expected parents and tree. I reran the round-3 shell command above (exit 0). It parsed the full space-containing primary path, the original integration branch, PR 19 and `--execute`. Decisive output: `foreign-cwd CLI --help = 0; identity and mismatch text passed`. The recovery write was traced in source. No reviewer phase gate was specified or run. The focused log's provenance still names the earlier revision.

### System · relay-drive — 2026-11-27T20:29:15Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted
