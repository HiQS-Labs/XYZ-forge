---
Goal: Final QA for GH-1409 (vendored-smoke base-pinning of judge files)
Date: 2026-11-10
NEXT: codex
STATUS: Approved
---

# Context

Review the completed implementation against its approved plan,
`PROJECT/2-WORKING/GH-1409-VENDORED-SMOKE-BASE-PIN.md` (plan QA approved and attested in
`relay-system/2026-11-10/gh1409-plan-qa.md`, round 4).

**Operational envelope.** Same as plan QA: a public single-maintainer repo; the goal is to stop a PR from
weakening vendored-smoke's own judge files in the same change. The operator accepted the `ci.yml`
self-edit loophole and dropped CODEOWNERS. `AGENTS.md` forbids new tests, suites and gate machinery
(GH-831); a new test file or registry entry in the diff would itself be a finding. Grade against R1–R5
and commensurate complexity.

Branch diff vs base `089eac1b` (stat): `.github/workflows/ci.yml` (+41/-4), the plan doc, receipts under
`TESTS-RESULTS/2026-11-10+GH-1409/` (SUMMARY.md, control-results.txt, controls-procedure.md,
provenance.jsonl), the plan-QA relay thread, and `releases.db`/`releases.sql` (the ledger row for #1409,
created through `releases_app.py roadmap pickup/repoint/update --accepted-start`).

The ci.yml diff (you cannot run git in this turn, so it is embedded):

```diff
diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
index a9642e700..ff90691aa 100644
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -539,6 +539,44 @@ jobs:
           git config --global user.email "ci@runner.invalid"
           git config --global user.name "CI Runner"
 
+      # GH-1409: on a PR, run this job's judge files from the PR base, not the PR's own copies, so a
+      # PR cannot weaken them in the same change. Each judge resolves paths from its own location, so
+      # restoring it in place keeps it scanning the candidate tree; xyz-vendor.sh then copies the base
+      # suites into .xyz/test. A maintainer `judge-change` label (read live, so re-run after labelling)
+      # skips the pin for an intended judge edit. Residual by decision: a PR can still edit this file.
+      - name: Pin judge files to PR base (GH-1409)
+        if: github.event_name == 'pull_request'
+        env:
+          GH_TOKEN: ${{ github.token }}
+          PR_NUMBER: ${{ github.event.pull_request.number }}
+        run: |
+          set -euo pipefail
+          git rev-parse --verify -q 'HEAD^2' >/dev/null || { echo "::error::HEAD is not a PR merge commit"; exit 1; }
+          BASE_SHA="$(git rev-parse 'HEAD^1')"
+          echo "BASE_SHA=$BASE_SHA" >> "$GITHUB_ENV"
+          echo "base=$BASE_SHA pr_head=$(git rev-parse 'HEAD^2') tested_merge=$(git rev-parse HEAD)"
+          if gh pr view "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --json labels --jq '.labels[].name' | grep -qx judge-change; then
+            echo "::warning::judge-change label: running this PR's own judge files"
+            exit 0
+          fi
+          B=utils/pdda/inventory_ratchet_baseline.json
+          git show "$BASE_SHA:$B" | python3 -c '
+          import json, sys
+          base, head = json.load(sys.stdin), json.load(open(sys.argv[1]))
+          files = lambda d: {b.split(":")[0] for b in d.get("sqlite_bypasses", [])}
+          grown = sorted(set(head.get("scripts", [])) - set(base.get("scripts", []))) + sorted(files(head) - files(base))
+          more = lambda k: len(set(head.get(k, []))) > len(set(base.get(k, [])))
+          if grown or more("sqlite_bypasses") or head.get("sqlite_bypasses_count", 0) > base.get("sqlite_bypasses_count", 0):
+              sys.exit("inventory baseline grew vs PR base: " + (", ".join(grown) or "bypass count"))
+          ' "$B"
+          if git diff -U0 "$BASE_SHA" HEAD -- '*.py' '*.sh' ':!test/**' | grep -E '^\+[^+].*SQLITE-(BYPASS|GATEWAY)-OK:'; then
+            echo "::error::new SQLITE-*-OK suppression marker added (label judge-change if intended)"; exit 1
+          fi
+          git checkout "$BASE_SHA" -- utils/pdda/check_inventory_ratchet.py \
+            test/gh421-auto-wave-reconcile.sh test/gh308-frozen-twin-guard.sh \
+            test/gh396-find-harness-roots.sh test/gh393-deepseek-readiness.sh \
+            test/gh358-wave-reconcile-vendored-paths.sh test/gh292-worktree-vendored-discovery.sh
+
       # GH-777 / #1182: the inventory ratchet (a new loose script under utils/, scripts/ or bin/, or
       # a new sqlite3.connect outside the canonical gateway) used to run only in the full gate, so
       # #1176 merged green here and then turned development's wave-reconcile RED. It is a one-second
@@ -550,10 +588,9 @@ jobs:
         run: bash test/gh421-auto-wave-reconcile.sh
       # GH-308 / GH-459: Frozen Bash twin guard runs on PRs against the PR base SHA.
       # Sited in vendored-smoke because this job triggers on pull_request with fetch-depth: 0.
+      # BASE_SHA is the merge ref's first parent, exported by the GH-1409 pin step above.
       - name: Frozen Bash twin guard (GH-308)
         if: github.event_name == 'pull_request'
-        env:
-          BASE_SHA: ${{ github.event.pull_request.base.sha }}
         run: |
           set -euo pipefail
           bash test/gh308-frozen-twin-guard.sh --check --base "$BASE_SHA" --allow-exceptions
```

Evidence to read: `TESTS-RESULTS/2026-11-10+GH-1409/SUMMARY.md`, `control-results.txt`, `provenance.jsonl`,
`controls-procedure.md`. The full qualifying gate (`ci-local.sh`) is running in a disposable clone at the
receipts commit; its result will be added to the PR and is not part of this packet.

# Questions

1. Does the step in the diff implement R1–R5 as approved, including R2's effective-cardinality comparison?
   Cite `ci.yml` lines from the working tree.
2. Is the shell/Python quoting now sound (the green control caught one quoting defect, fixed)? Any other
   quoting or `set -euo pipefail` pitfall, for example in the `git show | python3 -c` pipe or the
   `git diff | grep` condition?
3. Do the receipts substantiate the claims: does each red fail for its intended reason, and does the
   label + Red 3 discriminator show that the pin is what catches Red 3? Is anything over-claimed (live label
   behaviour is explicitly unverified)?
4. Did a duplicate subsystem, new suite, new script or registry entry slip in? `controls-procedure.md`
   holds the manual procedure as a fenced block in Markdown, not an executable suite.
5. Does the persisted rating (`rated 25/30/50/70`, operator-set) still match the evidence?

Every `[Blocker]` or `[Should]` requesting a behaviour change needs `Observed input:`, `Affected scope:` and
`Falsifier:` lines. Add exactly one block headed `### Codex final QA — round 1`, ending with exactly:

    VERDICT: PASS
    Basis: <one line>

(or `VERDICT: FAIL` with findings). Set `STATUS: Approved` when passing.

## Log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->


### Codex final QA — round 1

**Ship with conditions: final implementation QA passes; hosted verification and full-gate completion remain outstanding.** No blocking implementation finding against the approved R1–R5 contract.

- R1: `ci.yml:548,554-557` restricts the step to PRs, rejects a missing second parent, derives the base from the tested merge's first parent, exports it and logs all three SHAs. The frozen guard consumes that export at `:592-596`.
- R2: `ci.yml:563-571` compares added scripts, added bypass files, distinct bypass-entry cardinality and declared bypass count. The `set` cardinality closes the previously identified same-file inflation route; shrink and equality remain permitted.
- R3: `ci.yml:572-574` checks added Python/shell lines outside `test/`, including moved markers. R4: `:575-578` restores exactly the seven judges in place; the downstream ratchet, reconciliation, frozen guard and vendored suites use those paths (`:584-619`). The PR baseline stays intact.
- R5: `ci.yml:549-560` supplies the token and PR number, reads labels live and warns before skipping R2–R4. A failed label lookup in this conditional takes the conservative pin path; it does not grant the exception. Actual hosted lookup permissions and rerun behavior remain **[Unverified — needs hosted run]**.

Quoting check: narrow non-mutating probe extracted the pin step from the working workflow and ran `subprocess.run(['bash','-n'], input=body, text=True, capture_output=True)`, then `ast.parse` on its inline Python. Outer command exit 0; decisive output: `bash -n extracted pin step: rc=0` and `inline Python ast.parse: OK`. The single-quoted Python shell argument contains double-quoted Python literals; stdin remains available for `git show` JSON. The standalone JSON pipeline fails under pipefail on extraction/parse failure. The marker grep lacks `-q`, so it consumes the diff rather than causing an early-match SIGPIPE. Like other shell conditionals, a producer error in the marker pipeline would take its false branch; no concrete reachable bypass was demonstrated for this fixed invocation and checked merge/base.

Receipts: `control-results.txt` and `provenance.jsonl` agree on intended nonzero failures for Red 1 (dummy script), Red 1b (distinct entry with unchanged declared count), and Red 2 (added marker). Red 3 passes pin/ratchet but fails the restored gh396 on consumer-root discovery; Label + Red 3 passes the vendored suites with the neutered judge, discriminating the effect of pinning. Green records pin/ratchet/suites all 0. Label records the visible warning and pin 0. The manual procedure extracts actual workflow bodies and explicitly stubs labels. Existing focused-suite receipts report ci-workflow 0 and gh308 38 pass/0 fail at `69030ddab`; these are reviewed producer receipts, not fresh suite executions by this reviewer.

The supplied diff introduces one inline workflow step, no duplicate subsystem, suite, executable script or registry entry. `controls-procedure.md` is documentation. Read-only SQLite inspection (`sqlite3.connect('file:releases.db?mode=ro', uri=True)`, outer exit 0) confirmed GH-1409's persisted `rating_pri=25`, `rating_sev=30`, `rating_appeal=50`, `rating_effort=70`, with matching raw text. That operator-set latent-risk/cheap-change rating remains consistent with the evidence; this review establishes no incident or trend that warrants changing it.

Evidence limits: SUMMARY's hosted main-path paragraph describes the intended PR check receipt, not an observed hosted success in this packet. Do not cite it as completed smoke evidence until that run exists. Full qualifying gate completion is **[Unverified — needs clone run]**; the separately running gate and hosted PR run must supply their own final-commit receipts before merge readiness. The accepted workflow-self-edit and unpinned-helper residuals remain within the approved scope.

Only this relay file was edited. No git commands, suites, executable fixtures or source mutations were run this turn.

VERDICT: PASS
Basis: Working workflow implements approved R1–R5; syntax probes and discriminating recorded controls support the scoped verdict, with full-gate and hosted evidence explicitly outstanding.

### Attestation · relay-drive — 2026-11-10T22:16:41Z
task: RELAY-gh1409-final-qa
reviewer: codex
status: Approved
reviewed-head: bb598e8f06df9a5425aef82a4b9ae7eddb1f0fd9
added-range: 6929+4235
added-sha256: 756b6149e4554530c1732b24a5012514e4ba3e717ce381ecf7a1fe2a7a2d456f
