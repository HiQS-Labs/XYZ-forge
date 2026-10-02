# RELAY · GH854 dispositions final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
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
6. **Commit only the relay file** (`relay(gh854-dispositions-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **final-review-packet.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01

### Artifact — final-review-packet.md
````
Independent final QA for GH854 approved gate dispositions. Review the actual code/config selection diff below and available committed evidence. No git commands or mutation-heavy tests; only edit the relay file. Full task-branch push gate and hosted result follow this QA and are not yet claimed. User explicitly requested deferrals with real blocker triggers, canonical854 codification, and implementing the disposition. No further root-cause hunting authorized by this scope. No runtime behavior modules changed, no new tests/runners. Read entire touched files as relevant to the approved acceptance; don't expand into unrelated pre-existing policy rewrites. Check retained suites/runtime identical, current registry408 vs410, twoexempts and coherent ATE/Ubuntu selections. Four focused suites passed incl gh35,gh379,ci-workflow,gh306, and gh306 red control named both missingexemptions; committed provenance/identity available. Deferred916/917/918 stayopen;909closedfixedwithregression retained. Development count1/3, hosted3/3 unchanged. PlanQA attestedApproved after protocol corrections. Max3 finalQA turns.
IMPORTANT terminal protocol: do NOT call tick release or tick done. Leave token ownership with codex; codex-turn shim and supervisor own terminal closure. Only edit relay file and state verdict. Do not claim token handed back. No writes to plan/source.

# Approved gate dispositions — verification

Tested source9c77b309f36bab29d6e486d203b2f7218f86dc86 in a separate disposable full clone. Four existing focused checks passed; gh306 red control failed with both missing-exemption names and restored bytes passed. Clone identity remained intact. No new suite, test registry addition, gate machinery or runtime fix.

ci-workflow.sh.log:
Summary
  passed: 57
  failed: 0

gh306-red-missing-exemptions.log:
  PASS:   and the exempt helper in the same dir is NOT flagged
  PASS: a fully-registered-or-exempt dir yields an EMPTY drift report (control: the guard is not trigger-happy)
  gh306-registry-bidirectional: 9 pass, 1 fail

gh306-registry-bidirectional.sh.log:
  PASS:   and the exempt helper in the same dir is NOT flagged
  PASS: a fully-registered-or-exempt dir yields an EMPTY drift report (control: the guard is not trigger-happy)
  gh306-registry-bidirectional: 10 pass, 0 fail

gh35-test-tiers.sh.log:
  PASS:   with the same consequence message and override
  PASS: GH-45: an absolute-path invocation whose HERE is the worktree is still refused (exit 2)
  gh35-test-tiers: 72 pass, 0 fail

gh379-canary-uses-validate.sh.log:
  PASS: a quarantined run disqualifies itself as promotion evidence
  PASS: boundary-macos still pins --sequential (it is the promotion boundary, not the canary)
  gh379-canary-uses-validate: 36 pass, 0 fail

Selection preservation receipt records410→408, unchanged Small and byte-identical retained suite/runtime files. These are focused checks, not a full gate or development qualification. Full push gate and hosted exact-head check are still outstanding.


## Implementation diff
```diff
diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
index 4f6b855d..7d6ab90b 100644
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -449,12 +449,12 @@ jobs:
       # binary happened to be on the developer's own PATH, masking the gap; ubuntu CI has no such
       # binary. path-integrity.sh/archive-writers.sh/relay-file-seeding-visibility.sh/xyz-vendor.sh/
       # hq.sh/relay-pkg-freshness.sh all passed cleanly once re-tested for real — no ubuntu-specific
-      # bug in any of them. Only registry-lock-concurrency.sh (GH-72, a documented 16-concurrent-writer
-      # lock-contention flake under CI load, unrelated to this issue) stays skipped.
+      # bug in any of them. Registry concurrency is now unregistered by operator disposition
+      # (GH-854/GH-917); its retained manual suite must not appear in --skip.
       # GH-379: this step CALLS validate.sh. It must never go back to iterating suites itself.
       #
       # It used to scrape the TESTS array out of validate.sh with sed/grep and run a serial
-      # for-loop, in order to carry the three skips below. That cost three things at once:
+      # for-loop, in order to carry the then-current skips. That cost three things at once:
       #   * PARALLELISM — GH-528 measured 946.0s -> 184.3s at --parallel 8 with byte-identical
       #     pass/fail sets. The serial loop threw all of it away; the step measured 13m 14s, 88%
       #     of this job's wall and 100% of the repo's sampled runner-minute bill.
@@ -483,7 +483,7 @@ jobs:
       # No tier or path selector may be added here: the three non-shell lanes are tier-3 lanes, so
       # narrowing the run set would silently retract this issue's headline coverage claim.
       # test/gh379-canary-uses-validate.sh asserts all of this, selector by selector.
-      - name: Run validate.sh suite (minus a documented flaky test)
+      - name: Run validate.sh suite (with documented skips)
         if: steps.route.outputs.route == 'full'
         env:
           RELAY_SELF_SUFFICIENCY_SKIP: "1"
@@ -491,7 +491,6 @@ jobs:
           set -euo pipefail
           ./validate.sh --parallel 6 \
             --skip acorn-extract.sh \
-            --skip registry-lock-concurrency.sh \
             --skip pdda-repo-contract.sh
 
       # GH-509 Phase 2 — the canary's verdict, written where a human and a script can both find it.
diff --git a/AGENTS.md b/AGENTS.md
index c98bcd5f..d6b1d18d 100644
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -410,8 +410,8 @@ local change.
 - **The local macOS run is the gate; hosted ubuntu is advisory (GH-509).** XYZ is a developer toolkit
   for **macOS**; Linux and Windows are on the roadmap and not here yet. So `./validate.sh` (or
   `./ci-local.sh`) on your Mac is the highest-fidelity evidence available — it is the shipping
-  platform with the real toolchain — and it runs a **superset** of the hosted job, including
-  `registry-lock-concurrency.sh`, which CI skips for a contended-Linux flake. The hosted `canary-ubuntu`
+  platform with the real toolchain. Operator-retired suites stay out of both runners;
+  their retained manual files are listed in gh306 EXEMPT (GH-854). The hosted `canary-ubuntu`
   job is `continue-on-error: true`: its red means *portability drift*, not breakage, and must not be
   reported as a broken commit. Two consequences that bite: **never defer a test run to CI** — CI is
   advisory and tests the wrong OS; and **a green local run is self-reported**, so it does not qualify a
diff --git a/CHANGELOG.md b/CHANGELOG.md
index bd0afac5..1d3719dc 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,9 @@
 # Changelog
 
+## 2026-10-01 — Scope CI blockers to approved priorities (GH-854)
+
+The operator deferred unexplained live relay (#916), installation-registry (#917), and Gen4 oracle (#918) follow-ups until their issue-specific blocker triggers. Registry concurrency and the shared-root domain-oracle suite no longer gate every change: the existing TESTS/EXEMPT mechanism retains their files for direct manual use. The ATE subset and Ubuntu skip list agree with the retirement. Completion regression coverage remains after #909/#910; live relay stays opt-in under #836 D2. This accepts reduced automatic coverage on unrelated changes and does not claim the historical failures fixed. Reverse the registry, exemptions, ATE member and canary skip together to undo the change. The October 8 audit and stabilization counters remain separate; verification receipts live under `TESTS-RESULTS/2026-10-01+GH-854/dispositions/`.
+
 ## 2026-10-01 — Successful completion appends retain mutual exclusion (GH-909)
 
 A controlled handoff showed a stale waiter deleting a live successor’s PID-directory lock: all three writers returned success, but only two records survived. The existing completion writer now holds a stable-inode OS advisory lock through its atomic JSON transaction, preserving bounded per-holder wait and the absolute queue cap. The three covering fixtures use real OS locks. Upgrade and rollback require stopping and retiring old writers sharing the records path; mixed protocols are unsupported. Evidence is retained under `TESTS-RESULTS/2026-10-01+GH-909/`. The full-gate follow-up witnessed a quiet-grep SIGPIPE false-red in gh268 (#853). Because it is outside Small, standing policy turns it off through TESTS removal and gh306 EXEMPT; its file stays unchanged. A consuming-grep diagnostic demonstrated the cause but is not shipped. This fixes a proven loss mechanism; the exact historical CI interleaving and separate relay/registry flakes remain unproven.
diff --git a/PROJECT/2-WORKING/GH-854-GATE-DISPOSITIONS.md b/PROJECT/2-WORKING/GH-854-GATE-DISPOSITIONS.md
new file mode 100644
index 00000000..8368127c
--- /dev/null
+++ b/PROJECT/2-WORKING/GH-854-GATE-DISPOSITIONS.md
@@ -0,0 +1,46 @@
+---
+gh_issue: 854
+source: https://github.com/HiQS-Labs/XYZ-forge/issues/854
+title: "GH-854: execute approved gate dispositions"
+status: Working
+created: 2026-10-01
+updated: 2026-10-01
+owner: "XYZ Forge maintainers"
+goal: "Apply the operator-approved check dispositions without changing runtime behavior."
+doc_type: bugfix
+---
+# GH-854 — execute approved gate dispositions
+
+## Status
+| What was just completed | What's next |
+|---|---|
+| Approved selection changes implemented; four focused suites and missing-exemption red control passed with intact clone identity. | Independent final QA, full push gate, hosted exact-head check and ready PR. |
+
+The [canonical ordered stabilization list](https://github.com/HiQS-Labs/XYZ-forge/issues/854#issuecomment-5915099783) owns overall progress. This bounded execution document owns only the approved registry change; it does not duplicate the full stabilization plan or October 8 audit.
+
+## Decision and evidence
+Operator requested each unresolved item be tracked and deferred until a true blocker, then authorized executing the triangulated dispositions. #916 tracks unexplained live relay exit6, #917 the installation registry15/16 diagnostic, and #918 the Gen4 shared-root oracle16/1 failure. #909 stays closed: #910 repaired witnessed completion-record loss, and its existing regression coverage stays. Deferral accepts reduced automatic coverage for unrelated changes; it is not proof of harmlessness or root-cause resolution. See each issue for exact resume triggers.
+
+Base development: `1b40d57c36c70eb045341ec95403de93ba056b92`. The [bounded source recon](../../TESTS-RESULTS/2026-10-01+GH-854/dispositions/recon.md) records consumers, preserved runtime contracts, observed failures and unknowns. Registry410 before change. Every affected suite is outside Small; domain-oracle additionally appears in the ATE selection list. Ubuntu names the registry suite in --skip; unregistered skips are rejected, requiring a companion workflow edit. No gate runs in this valuable task clone.
+
+## Preservation, reversibility and scope
+Easy to reverse: restore the two TESTS entries, remove their EXEMPT entries, restore the ATE member and corresponding Ubuntu skip together. Keep both suite files and all runtime modules byte-for-byte. Keep Small, containment, token ownership, commit-bound attestation, resume, escalation and completion regression coverage. Do not add tests, guards, runners, lanes, telemetry stages or runtime fixes. No module deletion, data migration, fixture repair, automatic audit, merge, deploy or clone cleanup is part of this change. Existing #836 D2 RELAY_SELF_SUFFICIENCY_SKIP=1 applies to subsequent local qualification; direct validate defaults stay unchanged.
+
+## Ordered execution and acceptance
+1. Cross-model consult and independent Codex plan QA -> disposition scope and companion selections reviewed; three-round QA cap.
+2. Admit the exact roadmap row; remove registry-lock-concurrency.sh and gh-gen4-phase1-domain-oracles.sh from TESTS; add explicit gh306 exemptions; remove oracle from ATE subset and registry from Ubuntu skip; correct obsolete ci-local/ci-workflow assertions/comments and AGENTS.md local-registry example -> registry408, no runtime change.
+3. In a separate disposable full clone, run existing gh306, gh35 tier coverage, gh379 and ci-workflow checks; witness gh306 red by omitting exemptions, then restore saved bytes -> red names missing entries, green with explicit exemptions; record provenance and identity.
+4. Independent final Codex QA of final diff and focused evidence -> Approved within three rounds; then one full task-branch push gate under caffeinate, serial on host, intact identity, zero retry activity in telemetry and transcript, not merely exit0 -> committed full evidence and exact-head hosted result.
+5. Ready PR to development and #854 update -> operator landing decision remains required by #854. After approved landing, two clean development4-wide runs in fresh clones; stop on failure/drift. Task-branch gate never increments development count.
+
+## Deferred follow-ups and unchanged counters
+[#916](../1-INBOX/GH-916-LIVE-RELAY-DEFERRED.md), [#917](../1-INBOX/GH-917-INSTALL-REGISTRY-DEFERRED.md), [#918](../1-INBOX/GH-918-GEN4-ORACLE-DEFERRED.md) remain deferred/open. Live compatibility can be run deliberately with existing opt-in; retained installer/oracle suites can be run directly when their actual contracts change. No independent expected October8 registry count is invented. #854 local1/3, hostedPR-closed3/3; #853 quiet interval remains unmet. Automation stays paused.
+
+## Rating
+70/50/50/85: current operator-selected CI unblock, bounded coverage tradeoff, neutral appeal, small selection change. No override. This row covers disposition implementation, not closing all umbrella acceptance criteria.
+
+## Consult reconciliation
+Codex and agy both answered; source-only advice, no runtime verification claimed. Codex found no blocker and requested existing gh35 coverage, explicit zero-retry acceptance, and truthful adjacent workflow prose; all accepted. Agy found the stale AGENTS.md local-registry example in addition to workflow prose; accepted as a narrow documentation correction, with no policy expansion. No disagreement on the approved retirement or preserved runtime scope. Raw receipts: relay-system/2026-10-01/gh854-dispositions-plan-221120/.
+
+## Plan QA and unstuck receipt
+Independent plan QA attested Approved against ffe982b5739a in relay-system/2026-10-01/gh854-dispositions-plan-qa2.md. Initial attempts failed the harness protocol (producer concurrent plan edit; premature token release), not substantive plan review. Frozen inputs and terminal token closure corrected the failures in the final allowed plan turn. No production edits preceded valid approval; no review-cap extension or harness change.
diff --git a/ci-local.sh b/ci-local.sh
index 91ba14c0..3341b201 100755
--- a/ci-local.sh
+++ b/ci-local.sh
@@ -22,10 +22,8 @@
 #   * A green run on hosted UBUNTU says little. That job is an advisory portability canary; its red
 #     means "would not work on a platform we do not support yet", not "broken".
 #
-# This script therefore runs MORE than the hosted job, on purpose. It does not skip
-# `registry-lock-concurrency.sh` — the workflow's own comment says that suite "passes locally" and
-# flakes only under contended Linux CI, so skipping it here discarded real macOS signal to imitate a
-# machine no user has.
+# This script runs the current registry with only the already-run npm suite skipped.
+# Operator-retired suites are recorded in gh306 EXEMPT (GH-854); local runs do not restore them.
 #
 # THE HONEST LIMIT IS NOW ELSEWHERE, and it is not about platform. This run is SELF-REPORTED: it
 # proves someone ran the suite, not that they ran it on the code they are shipping. That is what the
@@ -258,10 +256,8 @@ npm_and_acorn() {
 validate_suite() {
   # GH-509: THIS SKIP LIST IS DELIBERATELY SHORTER THAN THE WORKFLOW'S, and that is the point.
   #
-  # It used to mirror CI's, including `registry-lock-concurrency.sh`. That suite's own skip comment
-  # in the workflow reads "flaky under CI load … PASSES LOCALLY" — it fails on a contended shared
-  # Linux runner, a machine no XYZ user will ever have. Skipping it here threw away real signal about
-  # the platform we actually ship to, in order to stay faithful to a platform we do not.
+  # Registry membership comes from validate.sh; operator-retired manual suites stay out
+  # of both runners (GH-854/GH-917/GH-918). Ubuntu also skips its repo-contract check.
   #
   # Only ONE skip survives, and it is not a platform concession: acorn-extract.sh already ran in the
   # npm step above, so running it again would be duplicated work rather than dropped coverage.
diff --git a/test/ci-workflow.sh b/test/ci-workflow.sh
index 5551a094..39a20cca 100644
--- a/test/ci-workflow.sh
+++ b/test/ci-workflow.sh
@@ -408,14 +408,8 @@ if [ -f "$CI_LOCAL" ]; then
     pass "ci-local.sh no longer re-derives the registry at all (GH-379 follow-up landed)"
   fi
 
-  # (2) The skip lists must now DIFFER, and this assertion was inverted on 2026-08-12 (GH-509).
-  #
-  # It previously required the two files to skip the SAME tests. Under the macOS reframe that pinned
-  # the wrong invariant: `registry-lock-concurrency.sh` is skipped in CI for a contended-Linux-runner
-  # flake, and the workflow's own comment says it "passes locally". Requiring local to skip it too
-  # discarded real signal about the platform we ship to, in order to imitate one we do not.
-  #
-  # Local must run MORE than hosted ubuntu, not the same.
+  # (2) Both runners avoid repeating the npm suite. Operator-retired registry concurrency
+  # is no longer a local/Ubuntu distinction (GH-854/GH-917); gh306 owns exemptions.
   # GH-379: the workflow now expresses its skips as validate.sh's `--skip <name>` rather than a
   # quoted array member, so match either idiom. What matters is that BOTH still skip it — the
   # intent (it already ran in the npm step; duplicate work, not lost coverage) is unchanged.
@@ -426,12 +420,6 @@ if [ -f "$CI_LOCAL" ]; then
     fail "acorn-extract.sh skip drift — it is duplicate work in both files and should be skipped in both"
   fi
 
-  if grep -qF '"registry-lock-concurrency.sh"' "$CI_LOCAL"; then
-    fail "GH-509: ci-local.sh skips registry-lock-concurrency.sh — that suite PASSES on macOS and is skipped in CI only for a contended-Linux flake; local must not imitate a platform we do not ship to"
-  else
-    pass "ci-local.sh runs registry-lock-concurrency.sh (skipped in CI for a Linux-only flake)"
-  fi
-
   # (3) The honesty notice, also inverted. The old caveat warned that a green local run is not a green
   # ubuntu run — true, but the less useful direction now: local IS the shipping platform. The limit
   # worth pinning is that a local run is SELF-REPORTED, which is what the hosted macOS boundary buys
diff --git a/test/gh306-registry-bidirectional.sh b/test/gh306-registry-bidirectional.sh
index c15f03bf..46d026ee 100644
--- a/test/gh306-registry-bidirectional.sh
+++ b/test/gh306-registry-bidirectional.sh
@@ -45,6 +45,8 @@ echo "== test: gh306-registry-bidirectional =="
 # exemptions are how this list rots into covering nothing), so the list is pinned in BOTH
 # directions below, like the registry it carves holes into.
 EXEMPT=(
+  "registry-lock-concurrency.sh" # GH-854 / GH-917: operator-deferred installer stress; retained for targeted manual use
+  "gh-gen4-phase1-domain-oracles.sh" # GH-854 / GH-918: operator-deferred shared-root oracle; retained for targeted manual use
   "gh268-relay-cue-and-target-checks.sh" # GH-853 / AGENTS: observed pipefail false-red outside Small; turned off, file retained
   "_setup.sh"                    # sourced by ~150 suites (shared tick fixture setup) — never executed directly
   "_scratch-repo.sh"             # sourced hardened scratch-repo helper (GH-44) — never executed directly
diff --git a/utils/ci-route.sh b/utils/ci-route.sh
index 686e396f..420a5d3f 100755
--- a/utils/ci-route.sh
+++ b/utils/ci-route.sh
@@ -25,7 +25,7 @@ SUBSYSTEMS="hq releases telemetry ate swe-diagram pdda agent-chorus standup skil
 SUBSYSTEM_TESTS_hq="hq.sh hq-park.sh hq-park-synthesis.sh hq-dispatch.sh hq-next.sh hq-locator.sh hq-hardening.sh hq-promote.sh hq-marathon-scan.sh hq-rollup.sh hq-marathon-live.sh gh238-hq-releases-mode.sh gh239-hq-status-releases-mode.sh"
 SUBSYSTEM_TESTS_releases="gh32-releases-app.sh gh103-timeline-exporter.sh gh32-releases-artifacts.sh gh53-releases-merge-resolve.sh gh54-merged-dump-refusals.sh gh57-live-merge-resolve.sh gh69-roadmap-shadow.sh gh32-release-target-advisory.sh gh39-releases-project-sync.sh gh153-releases-sidebar-rollup.sh releases-skill.sh gh284-p3-release-milestone.sh gh284-p4-release-lanes.sh litmus-release.sh nightwatch-release.sh meter-release.sh ballast-release.sh gh57-releases-fuzz.sh gh257-roadmap-ledger-fixes.sh gh269-roadmap-retired.sh gh549-work-events.sh gh567-roadmap-dashboard-retired.sh gh568-releases-md-retired.sh gh646-status-label.sh"
 SUBSYSTEM_TESTS_telemetry="xyz-completion.sh gh358-lock-instrumentation.sh archive-telemetry.sh gh496-telemetry-isolation.sh"
-SUBSYSTEM_TESTS_ate="ate-run-variations.sh gh298-ate-gen4-ci-smoke.sh gh-gen4-phase1-domain-oracles.sh gh-gen4-phase2-adaptive-ate.sh gh-gen4-phase3-fuzz-engine.sh gh-gen4-phase4-repro-synth.sh gh-gen4-phase5-campaign.sh gh478-runaway-guard.sh gh712-jev-triage.sh synthetic/gh102-telemetry-schema.sh gh142-ate-exit-contract.sh"
+SUBSYSTEM_TESTS_ate="ate-run-variations.sh gh298-ate-gen4-ci-smoke.sh gh-gen4-phase2-adaptive-ate.sh gh-gen4-phase3-fuzz-engine.sh gh-gen4-phase4-repro-synth.sh gh-gen4-phase5-campaign.sh gh478-runaway-guard.sh gh712-jev-triage.sh synthetic/gh102-telemetry-schema.sh gh142-ate-exit-contract.sh"
 SUBSYSTEM_TESTS_swe_diagram="swe-diagram.sh"
 SUBSYSTEM_TESTS_pdda="gh649-pdda-migration.sh pdda-changelog.sh pdda-install-startup-docs.sh pdda-roadmap-coverage.sh pdda-repo-contract.sh pdda-local-checks.sh gh400-acceptance-fidelity.sh gh400-source-url.sh gh422-backfill-source-url.sh gh425-source-url-slug.sh wave-reconcile.sh gh202-wave-reconcile-issue-state.sh gh232-wave-reconcile-multiphase.sh gh358-wave-reconcile-vendored-paths.sh gh496-phase2-reconciliation-views.sh"
 SUBSYSTEM_TESTS_agent_chorus="agent-chorus.sh agent-chorus-bridge.sh gh233-agent-chorus-concurrency.sh"
diff --git a/validate.sh b/validate.sh
index ec4d00f3..15a6d0ff 100755
--- a/validate.sh
+++ b/validate.sh
@@ -644,7 +644,6 @@ TESTS=(
   "sentinel-overlay.sh"         # GH-281 (Tier-2 overlay: static egress guard + inert-by-default proof)
   "checkjs.sh"
   "acorn-extract.sh"             # GH-169
-  "registry-lock-concurrency.sh"
   "marathon-monitor.sh"          # GH-88 (cross-repo marathon monitor)
   "signal-triage.sh"             # GH-63 (signal triage stage)
   # GH-40 double-blind Reviewer canaries — each verify-fixture.sh drives the real kernel and exits
@@ -677,7 +676,6 @@ TESTS=(
   "gh693-lessons-learned-advisory.sh" # GH-693 (Lessons Learned is a WARN, never a promotion gate: explicit, --pre-merge, catch-up; frontmatter control)
   "gh306-registry-bidirectional.sh" # GH-306 (exists→registered registry half; self-demonstrating — see the suite header)
   "gh298-ate-gen4-ci-smoke.sh"      # GH-298 (ATE Gen 4 CI smoke — fuzz/oracle wiring against the real runner)
-  "gh-gen4-phase1-domain-oracles.sh" # GH-299 Phase 1 (Gen 4 semantic domain oracles: zero-state, containment, idempotence, crash-recovery; +/- controls)
   "gh-gen4-phase2-adaptive-ate.sh"   # GH-299 Phase 2 (Gen 4 constraint-aware pairwise ATE + calibrated $0 Tier-1 triage; independent coverage walk)
   "gh-gen4-phase3-fuzz-engine.sh"    # GH-299 Phase 3 (Gen 4 seeded mutational fuzz engine: replay, novelty-capped corpus, cross-twin parity)
   "gh-gen4-phase4-repro-synth.sh"    # GH-299 Phase 4 (Gen 4 clustered reproducer synthesis: 1 suite per root cause, ddmin, falsification)
@@ -768,7 +766,7 @@ while [ $# -gt 0 ]; do
     --skip)
       # GH-379: the canary hand-rolled its own runner partly to get a skip list. A skip is a real
       # reduction in coverage, so it is spelled out loud rather than buried in a CI for-loop.
-      [ $# -ge 2 ] || _err2 "--skip requires a suite name (e.g. --skip registry-lock-concurrency.sh)"
+      [ $# -ge 2 ] || _err2 "--skip requires a suite name (e.g. --skip acorn-extract.sh)"
       SKIP_SUITES+=("$2")
       shift 2 ;;
     --parallel|--max-parallel)

```
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1
VERDICT: PASS
Basis: Approved for the bounded disposition implementation and focused evidence in Setup. The generic Definition of Done remains a scaffold placeholder; the embedded packet and GH-854 execution document supply the concrete acceptance reviewed here. No blocking implementation defect found, including in the pre-existing selection/runner paths swept. This approval does not qualify a landing, promotion, or completion of umbrella GH-854.

swept file: yes

- [Pass] Selection changes use the existing mechanism: two explicit exemptions at test/gh306-registry-bidirectional.sh:48-49, oracle removed from ATE at utils/ci-route.sh:28, and only registered Ubuntu skips at .github/workflows/ci.yml:493-494. Completion regression remains registered at validate.sh:579 and utils/ci-route.sh:27. No fix requested.
- [Pass] Read-only probe: command `python3 - <<'PY'` with standard-library Path/re/json/hashlib assertions over TESTS, EXEMPT, all SUBSYSTEM_TESTS values, workflow skips, selection-preservation.json, identity.json, provenance.jsonl and nonempty focused logs; exit 0. Decisive output: “registry=408 unique; retired=2 exempt; all subsystem members registered; Ubuntu skips=acorn-extract.sh,pdda-repo-contract.sh” and “preserved hashes=6/6; identity before=after; focused provenance=5 matching SHA/expected rc; red names both retirements; four green logs nonempty”. The six current file digests match TESTS-RESULTS/2026-10-01+GH-854/dispositions/selection-preservation.json's preserved_sha256 map; its base comparison and Small-byte preservation are producer receipts, not an independently rerun base comparison. No git invoked.
- [Pass] Focused clone-run evidence, inspected rather than rerun here: gh306 10/0 (focused/gh306-registry-bidirectional.sh.log:12), gh35 72/0 (focused/gh35-test-tiers.sh.log:74), gh379 36/0 (focused/gh379-canary-uses-validate.sh.log:39), ci-workflow 57/0 (focused/ci-workflow.sh.log:62-63), all under TESTS-RESULTS/2026-10-01+GH-854/dispositions/. The red control names both retired suites at focused/gh306-red-missing-exemptions.log:3-5 and ends 9/1 at line 14; focused/provenance.jsonl records red rc=1 and four rc=0 runs at source 9c77b309f36bab29d6e486d203b2f7218f86dc86. focused/identity.json contains identical before/after identity. No further focused run requested.
- [Pass] Static syntax command `bash -n validate.sh ci-local.sh utils/ci-route.sh test/ci-workflow.sh test/gh306-registry-bidirectional.sh`; exit 0, no output. This parsed the files without executing gates or fixtures.
- [Pass] Deferrals retain actual blocker triggers: PROJECT/1-INBOX/GH-916-LIVE-RELAY-DEFERRED.md:18, GH-917-INSTALL-REGISTRY-DEFERRED.md:20 and GH-918-GEN4-ORACLE-DEFERRED.md:18. PROJECT/2-WORKING/GH-854-GATE-DISPOSITIONS.md:33 explicitly owes the full serial task gate with zero retries and exact-head hosted result; line 37 preserves local1/3, hosted3/3 and paused automation. No claim of historical root-cause resolution or increased counters. No fix requested.
- [Nit] Pre-existing prose at ci-local.sh:249-250 still says the workflow parses TESTS “exactly the way” ci-local does, although .github/workflows/ci.yml:491 calls validate directly. Optional fix: describe ci-local's retained parser and the common authoritative registry. This does not affect selection or block this approval.
- [Unverified — needs clone run] Full push gate and hosted final-head execution were not run in this reviewer worktree and remain outstanding by the packet's own acceptance ordering. Producer/supervisor should execute the already-planned qualification after QA; approval here is not merge readiness.

Sweep covered the embedded packet and complete touched selection/runner/test files, the GH-854 working doc, adjacent governance/changelog context, deferred intake and available receipts. No additional pre-existing correctness defect found within this bounded acceptance. Graph inventory contained no project for this worktree; canonical graph generation 2026-09-30T07:57:23Z was not treated as current-worktree proof. Coverage checked for touched paths; the new working doc was missing there, so current source reads supplied the evidence. No artifact/source edits, test execution, or external posting.

Terminal protocol follows the current user's explicit instructions over the conflicting embedded packet note: NEXT becomes Producer, STATUS becomes Approved, and the env-pinned token is completed with done. The harness owns the relay-only commit.

relay closed (Approved), no further turn needed. Producer/supervisor next performs the outstanding qualification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
