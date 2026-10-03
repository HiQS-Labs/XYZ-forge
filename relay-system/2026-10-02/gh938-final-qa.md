# RELAY · GH-938 (XYZ-forge) relay-xyz managed-setup docs — FINAL QA on committed diff + evidence
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh-938-xyz-forge-relay-xyz-managed-setup-docs-final-qa-on-committed-diff-evidence): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh938-final-qa-artifact.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-02

### Artifact — gh938-final-qa-artifact.md
`````
# GH-938 FINAL QA packet (XYZ-forge) — committed diff fix/gh938-relay-xyz-managed-setup @ c7519fc6 vs origin/development 5212dae4

## What to review
The committed implementation of the plan you approved in relay-system/2026-10-02/gh938-plan-qa.codex.md
(R2/R3 PASS). Your worktree is an OLDER harness checkout; rely only on the quoted bytes below.

## Requirements (binding, unchanged from plan QA)
1. Docs-only: SKILL.md "First-time setup" skips install.sh when ~/.claude/skills/relay-xyz resolves into a
   Skills Army "Deployed Skills" collection (readlink check); point to find-harness.sh --check and
   ~/.config/xyz/harness, command-scoped XYZ_HARNESS fallback. install.sh detection deferred.
2. No new test suites / TESTS entries (GH-831). find-harness.sh :41/:43 pins, path-integrity, gh278,
   gh346, gh681 stay true. Evidence: existing suites + full ./validate.sh, or recorded manual checks under
   TESTS-RESULTS/ with provenance.jsonl.
3. Plan carries the post-merge deployment checklist (reviewed already; only rewrap since).
4. Full-gate failures must be attributed (diff vs environment) with evidence.

## Operational envelope
One-section markdown edit, single-operator fleet. Grade proportionately. Behaviour-change requests need
Observed input / Affected scope / Falsifier (GH-681).

## Questions
Q1. Does the SKILL.md diff match the approved draft and requirement 1, with no wrong claim?
Q2. Are the pins still true (see focused logs/red controls), and is the evidence complete and honest
    (provenance rows, sha256, base attribution of the 11 full-gate failures)?
Q3. Is the ledger change (releases.sql) only the GH-938 row admission/intake? CHANGELOG entry accurate?
Q4. Anything that should block a READY PR (not merge)?

---
## A. git diff --stat 5212dae4..c7519fc6
```
 CHANGELOG.md                                       |   14 +
 .../2-WORKING/GH-938-RELAY-XYZ-MANAGED-SETUP.md    |  205 ++
 TESTS-RESULTS/2026-10-02+GH-938/SUMMARY.md         |   27 +
 .../base-5212dae4/base-attrib.log                  |   11 +
 .../base-gh123-lock-progress-bound.log             |    8 +
 .../base-gh280-jog-marathon-adapter.log            |  121 +
 .../base-gh390-timeout-attribution.log             |   15 +
 .../base-gh399-packet-acceptance-continuation.log  |   18 +
 .../base-5212dae4/base-gh402-board-sync.log        |   55 +
 .../base-5212dae4/base-gh436-merge-cleanup.log     | 3444 ++++++++++++++++++++
 .../base-5212dae4/base-gh492-idle-kill.log         |   19 +
 .../base-5212dae4/base-gh505-relay-attest.log      |   64 +
 .../base-5212dae4/base-gh544-pre-push-gate.log     |   61 +
 .../base-gh610-claude-subscription.log             |   24 +
 .../base-5212dae4/base-swarm-preflight.log         |  230 ++
 .../2026-10-02+GH-938/focused-find-harness.log     |   53 +
 .../focused-gh278-turn-timeout-parity.log          |   15 +
 .../focused-gh346-gateway-allowlists.log           |   62 +
 .../focused-gh678-installer-live-links.log         |   54 +
 .../focused-gh681-reviewer-probe-rules.log         |   30 +
 .../2026-10-02+GH-938/focused-path-integrity.log   |   25 +
 .../2026-10-02+GH-938/grep-wording-red-green.log   |    5 +
 .../2026-10-02+GH-938/prior-art-recon.txt          |    9 +
 TESTS-RESULTS/2026-10-02+GH-938/provenance.jsonl   |   12 +
 .../2026-10-02+GH-938/red-find-harness.log         |   53 +
 .../2026-10-02+GH-938/red-path-integrity.log       |   23 +
 TESTS-RESULTS/2026-10-02+GH-938/validate-full.log  | 1275 ++++++++
 relay-system/2026-10-02/gh938-plan-qa.codex.md     | 1146 +++++++
 releases.db                                        |  Bin 1134592 -> 1138688 bytes
 releases.sql                                       |   12 +-
 skills/1-hourly/relay-xyz/SKILL.md                 |   24 +-
 31 files changed, 7107 insertions(+), 7 deletions(-)
```

## B. Diff of SKILL.md, CHANGELOG.md, releases.sql (text), plan doc
````diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index d1184116..ac27b621 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,6 +1,20 @@
 # Changelog
 
 
+## 2026-10-02 — relay-xyz setup skips install.sh on Skills Army-managed Macs (GH-938)
+
+The relay-xyz "First-time setup" told every machine to run `install.sh`. On a Mac where Skills Army HQ
+already links `relay-xyz` from its `Deployed Skills` collection, that step exits 1 on the live link and
+can add links in app roots the collection does not target, against Skills Army HQ's rule not to run
+copied `install.sh` files.
+
+The section now starts with a `readlink` check. A link into `Deployed Skills/relay-xyz` means skip
+`install.sh`, leave links to Skills Army HQ (`sync.py`), and go to the locator's `--check`; if no
+harness resolves, save the clone in `~/.config/xyz/harness` or prefix one command with `XYZ_HARNESS`.
+Machines without that link keep the existing `install.sh` step. Docs only: `install.sh` itself does
+not yet detect a managed collection (deferred). Deployment to the Macs follows the post-merge checklist
+in `PROJECT/2-WORKING/GH-938-RELAY-XYZ-MANAGED-SETUP.md`.
+
 ## 2026-10-01 — Scope CI blockers to approved priorities (GH-854)
 
 The operator deferred unexplained live relay (#916), installation-registry (#917), and Gen4 oracle (#918) follow-ups until their issue-specific blocker triggers. Registry concurrency and the shared-root domain-oracle suite no longer gate every change: the existing TESTS/EXEMPT mechanism retains their files for direct manual use. The ATE subset and Ubuntu skip list agree with the retirement. A subsequent pooled setup failure also retires the non-Small ungated-warning fixture suite under standing #853 policy (#920); its isolated six assertions passed, but the historical copy error remains unknown. Its file, warning and hook enforcement remain unchanged. The Small Ballast manifest audit recognizes explicit retirement as outstanding rather than a false closure; it still rejects missing files/controls and gives no release-completion credit. Completion regression coverage remains after #909/#910; live relay stays opt-in under #836 D2. This accepts reduced automatic coverage on unrelated changes and does not claim the historical failures fixed. Reverse the registry, exemptions, ATE member and canary skip together to undo the change. The October 8 audit and stabilization counters remain separate; verification receipts live under `TESTS-RESULTS/2026-10-01+GH-854/dispositions/`.
diff --git a/PROJECT/2-WORKING/GH-938-RELAY-XYZ-MANAGED-SETUP.md b/PROJECT/2-WORKING/GH-938-RELAY-XYZ-MANAGED-SETUP.md
new file mode 100644
index 00000000..7ae30101
--- /dev/null
+++ b/PROJECT/2-WORKING/GH-938-RELAY-XYZ-MANAGED-SETUP.md
@@ -0,0 +1,205 @@
+---
+gh_issue: 938
+source: https://github.com/HiQS-Labs/XYZ-forge/issues/938
+title: "relay-xyz SKILL.md: First-time setup tells Skills Army-managed Macs to run install.sh"
+status: active
+created: 2026-10-02
+updated: 2026-10-02
+owner: XYZ Forge maintainers
+doc_type: bugfix
+branch: fix/gh938-relay-xyz-managed-setup
+effort: 1
+complexity: 1
+risk: 1
+phases: 1
+non_goals:
+  - No change to install.sh (managed-collection detection is deferred; see Deferred)
+  - No change to find-harness.sh, Skills Army HQ scripts, or any app link
+  - No new test suite or validate.sh TESTS entry (GH-831)
+  - No deployment to any Mac in this PR; deployment is the post-merge checklist below
+goal: >
+  A machine whose relay-xyz link already resolves into a Skills Army HQ Deployed Skills collection
+  is told to skip install.sh and go to the locator, so following the skill creates no unmanaged links.
+---
+
+# GH-938: relay-xyz first-time setup on Skills Army-managed Macs
+
+## Status
+
+| What was just completed | What's next |
+|---|---|
+| Intake parked (rated 40/35/50/85), recon at `5212dae4`, plan written. Codex plan QA (relay-xyz, 3 rounds): R1 FAIL (`Unchanged` stopped the checklist; fixed), R2 and R3 PASS; harness attestation refused both PASSes on mechanics (`review-body-rewritten`, then `close-mismatch`), so the receipt is content-approved but unattested: `relay-system/2026-10-02/gh938-plan-qa.codex.md`. Admitted (`--accepted-start`, In progress 🚧). SKILL.md "First-time setup" rewritten. Focused suites green with red controls; full `./validate.sh` at `204750c5`: 399/410, the 11 failures reproduce on base `5212dae4` (environment) — `TESTS-RESULTS/2026-10-02+GH-938/`. | Final Codex QA on the diff, ready PR; after merge, the checklist below. |
+
+## Rating — 2026-10-02: `40/35/50/85` (priority/severity/appeal/effort)
+
+- **Severity 35:** Following the documented step on a managed Mac fails (exit 1 on live links) and can
+  create app links Skills Army HQ does not own, in roots it does not target. Nothing is lost and the
+  links are removable; the skill already works there. Recoverable, low reach (operator Macs).
+- **Priority 40:** Operator asked for it now as the follow-on to #856's deployment. Recurrence window
+  2026-09-19–10-02: #856 (adjacent: locator assumed the install.sh layout) and #938. Preceding window
+  2026-09-05–18: #678 (installers replaced managed links) and #660 (deployed-skill drift). Same
+  family (repo docs/installers assuming the pre-Skills-Army layout), no rising rate.
+- **Appeal 50:** Neutral; no operator score given.
+- **Effort 85:** One markdown section. Cheap to write; the full gate (relay-xyz is a full-gate path)
+  is the main cost.
+
+## Recon — observed at `5212dae4` (origin/development, 2026-10-02)
+
+- `skills/1-hourly/relay-xyz/SKILL.md:65-79` ("First-time setup on a new clone or machine") tells
+  every clone/machine to run `bash skills/1-hourly/relay-xyz/install.sh` and says it "replaces a
+  stale/dangling symlink". No exception for managed machines.
+- `skills/1-hourly/relay-xyz/install.sh:42-70`: a live link that is not this copy is refused
+  (GH-678) and the script exits 1; absent roots (`~/.codex/skills`, `~/.gemini/antigravity/skills`,
+  `~/.gemini/antigravity-cli/skills`) get `mkdir -p` and a new link to whichever copy ran it.
+- Skills Army HQ (`skills/3-weekly/skills-army-hq/SKILL.md`): "Do not run copied `install.sh`
+  files"; only `intake.py`/`sync.py` mutate the collection or app links. Deployed SOP (GH-672): app
+  links point into the device's Pulse checkout `Deployed Skills/`.
+- Since #856/#936, `find-harness.sh` (same folder) resolves a copied deployment via the per-device
+  config `${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness` or a bounded clone search, and `--check`
+  prints the command that saves the config. `SKILL.md:81-111` already documents this; the setup
+  section just never routes managed machines there.
+- Mac Mini observation (2026-10-02 ~6:50 PM PT, read-only): `~/.claude/skills`, `~/.agents/skills`,
+  `~/.gemini/config/skills`, `~/.zcode/skills`, `~/.grok-bot/skills` → `relay-xyz` all resolve to
+  `~/Documents/GitHub/rebalance-git-pulse/Deployed Skills/relay-xyz`; the three install.sh-only
+  roots above have no `relay-xyz` entry; `sync.py --status` clean.
+- Consumers of this file that the edit must keep true:
+  - `test/find-harness.sh:40-43` — SKILL.md contains `$HOME/.claude/skills/relay-xyz/find-harness.sh`,
+    and has no line that is exactly `bash skills/1-hourly/relay-xyz/find-harness.sh --check`.
+  - `test/path-integrity.sh` Check B scans this file for repo-path tokens (`skills/…`, `test/…`,
+    `relay-automation/…`, `bin/…` ending `.sh`/`.md`/`.tar.gz`); every token must resolve. App
+    discovery paths (`~/.claude/skills/…` etc.) are blanked first.
+  - `test/gh278-turn-timeout-parity.sh:60`, `test/gh346-gateway-allowlists.sh:401`,
+    `test/gh681-reviewer-probe-rules.sh:94-101` grep other sections (timeouts, deepseek, reviewer
+    rules); untouched by this edit.
+  - `utils/ci-route.sh:67,342` and `test/ci-route.sh:176`: every relay-xyz file is a full-gate path,
+    so this landing qualifies on the Large tier (full registry).
+- No twin/mirror of this section: the phrase appears only in this SKILL.md, CHANGELOG history and an
+  old relay thread. Deployed copies are produced by Skills Army HQ after merge, not by this PR.
+- Observed, out of scope: `SKILL.md:207-209` says `install.sh` "writes only into `~/.claude/skills/`";
+  it writes five app roots. Recorded for the deferred install.sh follow-up, not edited here.
+
+## Plan (one phase)
+
+1. Rewrite only the "First-time setup" section of `skills/1-hourly/relay-xyz/SKILL.md`:
+   - Lead with a check: `readlink ~/.claude/skills/relay-xyz` (or the same entry in the app's skills
+     root).
+   - **Managed** (resolves into a `Deployed Skills/relay-xyz` folder): skip `install.sh`; Skills Army
+     HQ owns the links (`sync.py`); go to the locator, run its `--check`; if no harness resolves,
+     save the canonical clone with the command `--check` prints (`~/.config/xyz/harness`), or prefix
+     one command with `XYZ_HARNESS=…`. No shell startup exports.
+   - **Not managed** (no link, or a dangling one): keep the existing `install.sh` instruction, which
+     is still correct for a maintained primary clone.
+   - Keep the two `test/find-harness.sh` pins true; add no unresolvable repo-path tokens.
+   Verify inline: `bash test/find-harness.sh`, `bash test/path-integrity.sh`,
+   `bash test/gh681-reviewer-probe-rules.sh`, `bash test/gh346-gateway-allowlists.sh`,
+   `bash test/gh278-turn-timeout-parity.sh` green; `utils/pdda/pdda.sh run` 0 errors.
+2. CHANGELOG entry (PDDA rules); update this doc's Status.
+3. Full gate once on the final approved commit, in a disposable full clone (relay-xyz is full-gate);
+   receipt and `provenance.jsonl` under `TESTS-RESULTS/2026-10-02+GH-938/`.
+4. Final Codex relay QA on the diff; ready PR to `development` with `Closes #938` and the checklist.
+
+## Acceptance and falsifiers
+
+- **Wording present (falsifiable):** `grep -n 'Deployed Skills' skills/1-hourly/relay-xyz/SKILL.md`
+  finds the managed-skip instruction inside the First-time setup section, before the `install.sh`
+  command. Red control: the same grep on `5212dae4` finds no such line in that section.
+- **Pins stay true:** `test/find-harness.sh` and `test/path-integrity.sh` pass. Red control for the
+  path scan (manual, recorded): temporarily add a bogus `skills/1-hourly/relay-xyz/nope.sh` token,
+  see `path-integrity.sh` fail, revert.
+- **Behaviour unchanged:** no change to any `.sh`; `git diff --stat origin/development` lists only
+  SKILL.md, CHANGELOG.md, this doc, the ledger dump/DB, the TESTS-RESULTS receipt and the
+  `relay-system/2026-10-02/gh938-*.codex.md` review receipts.
+- **Gate:** full `./validate.sh` on the final approved commit; failures attributable to this diff
+  block the PR; pre-existing/environment failures are recorded as such with evidence.
+- **Deployment (after merge, not this PR):** the Mini checks in the checklist below pass; #938 closes
+  only after them.
+
+## Risks and rollback
+
+- Risk: wording breaks a grep-based suite reading this file → caught by the focused suites above and
+  the full gate. Rollback: revert the PR (docs-only, Easy). Deployed copies roll back per the
+  checklist's rollback step.
+
+## Deferred
+
+- `install.sh` managed-collection detection (skip and exit 0 when a live app link resolves into a
+  collection with `.deploy-skills.json`) and the `SKILL.md:207-209` wording. Deferred: behaviour
+  change to an installer that `test/gh678-installer-live-links.sh` pins for every skill, and the new
+  path has no existing covering suite (GH-831 forbids adding one).
+
+## Post-merge deployment checklist
+
+Not executed by this PR. Run in order; stop at the first failure. `C` = the device's collection
+(`<Pulse checkout>/Deployed Skills`); on the Mini the Pulse checkout is
+`~/Documents/GitHub/rebalance-git-pulse`, on the Mac Studio `~/git-pulse-sync` (or `$XYZ_SKILLS_ROOT`).
+
+1. **Landing.** `gh pr view <PR> -R HiQS-Labs/XYZ-forge --json state,mergeCommit` → `MERGED`; note
+   `<sha>`. `gh run list -R HiQS-Labs/XYZ-forge --workflow CI --commit <sha>` → the push run
+   completed `success` (the ubuntu canary is advisory; record any red). `gh run list -R
+   HiQS-Labs/XYZ-forge --workflow "Wave reconciliation" --limit 5` → the `pull_request` run for this
+   PR (or the next scheduled run) completed `success`; no open `hosted-reconcile-attention` issue
+   for it.
+2. **Choose the publisher.** Per the operator ruling recorded in CHANGELOG (GH-881), any device may
+   publish, but exactly one device publishes this change. It needs a clean canonical clone on
+   `development`: `git -C <clone> status -sb` shows no local commits or changes, then
+   `git -C <clone> pull --ff-only`, and `git -C <clone> rev-parse HEAD` contains `<sha>`
+   (`git -C <clone> merge-base --is-ancestor <sha> HEAD`). The Mini's `~/Documents/GitHub/XYZ-forge`
+   does not qualify today (local relay commits, behind origin); use the Mac Studio's clone, or settle
+   the Mini clone first.
+3. **Publish (on the publisher).**
+   - Record the prior receipt first (rollback anchor): `python3 "$C/intake.py" --root "$C" list` →
+     note relay-xyz's `digest`, `repository` and `commit` (on the Mini today: `rebalance-git-pulse`
+     @ `1636d8df`).
+   - Preview: `python3 "$C/intake.py" --root "$C" update relay-xyz --source
+     "<clone>/skills/1-hourly/relay-xyz"`. Expect `before`/`after` digests and `commit` = `<clone>`
+     HEAD. `--source` is required: the Mini's receipt records the collection itself as source, which
+     `intake.py` refuses (overlap). If it prints `Unchanged: relay-xyz`, the payload is already
+     published: skip apply and commit, find the existing publish commit with
+     `git -C <pulse> log -1 --format=%H -- "Deployed Skills/relay-xyz"` (confirm its message names
+     `<sha>` or this PR; if it cannot be identified, record that on #938 instead of claiming a
+     publish), and continue at step 4.
+   - Apply: the same command with `--apply` before `update`. It writes a verified backup ZIP under
+     `$C/backups/`.
+   - Verify: `python3 "$C/intake.py" --root "$C" list` shows the relay-xyz receipt digest equal to the
+     preview's `after`, `commit` = `<clone>` HEAD, `dirty: false`.
+     `python3 "$C/sync.py" --root "$C" --status --canonical "<clone>"` → no errors, relay-xyz not
+     `DRIFTED`.
+   - Commit immediately (the Pulse writer cannot rebase a dirty tracked tree):
+     `git -C <pulse> add -- "Deployed Skills/relay-xyz"` (plus `"Deployed Skills/README.md"` if the
+     apply changed it), `git -C <pulse> commit -m "vendor: publish relay-xyz from XYZ-forge@<sha>
+     (PR #<PR>, GH-938)"`, then push through the Pulse workflow (`git -C <pulse> push`, or the next
+     Pulse cycle). `git -C <pulse> status -sb` shows nothing ahead.
+4. **Mac Mini.**
+   - `git -C ~/Documents/GitHub/rebalance-git-pulse status --porcelain --untracked-files=no` is
+     empty, then `git -C ~/Documents/GitHub/rebalance-git-pulse pull` (or wait for its Pulse cycle);
+     `git -C ~/Documents/GitHub/rebalance-git-pulse log -1 --format=%H -- "Deployed Skills/relay-xyz"`
+     is the publish commit.
+   - `python3 "$C/sync.py" --root "$C" --status` → `errors: []`, no relay-xyz actions or conflicts.
+   - `readlink -f ~/.claude/skills/relay-xyz` → `$C/relay-xyz` (same for `~/.agents/skills`,
+     `~/.gemini/config/skills`, `~/.zcode/skills`, `~/.grok-bot/skills`).
+   - Deployed bytes match the merge: `gh api "repos/HiQS-Labs/XYZ-forge/contents/skills/1-hourly/relay-xyz/SKILL.md?ref=<sha>"
+     -H "Accept: application/vnd.github.raw" | diff - "$C/relay-xyz/SKILL.md"` and the same for
+     `find-harness.sh` → no output. `grep -n "Deployed Skills" "$C/relay-xyz/SKILL.md"` shows the new
+     managed-skip line.
+   - From `~`: `cd ~ && env -u XYZ_HARNESS -u XYZ_REPO_ROOT bash ~/.claude/skills/relay-xyz/find-harness.sh --check`
+     → exit 0 with `via=config` or `via=search` (this also proves the #856/#936 locator reached the
+     Mini). A behind-upstream warning for the clone is advisory.
+   - No unmanaged links: `ls -ld ~/.codex/skills/relay-xyz ~/.gemini/antigravity/skills/relay-xyz
+     ~/.gemini/antigravity-cli/skills/relay-xyz` → all "No such file or directory".
+5. **Mac Studio, when online.** The same step 4 with its Pulse checkout (`~/git-pulse-sync`) and
+   `C="$HOME/git-pulse-sync/Deployed Skills"` (or `$XYZ_SKILLS_ROOT`). Other Macs the same when next
+   online; record which were checked.
+6. **Rollback (if a check fails after publish).** On the publisher, `intake.py` update back to the
+   prior receipt recorded in step 3. Check out that payload in a temporary Git clone outside `$C`
+   (`intake.py` requires the source to sit inside a local Git repository): if the prior receipt's
+   repository is the Pulse repo, `git clone <pulse> <tmp> && git -C <tmp> checkout <prior commit>`
+   and use `--source "<tmp>/Deployed Skills/relay-xyz"`; if it is XYZ-forge,
+   `git clone https://github.com/HiQS-Labs/XYZ-forge.git <tmp> && git -C <tmp> checkout <prior commit>`
+   and use `--source "<tmp>/skills/1-hourly/relay-xyz"`. Preview, then `--apply`; the resulting
+   `after` digest must equal the recorded prior `digest`. Commit and push as in step 3; devices pull
+   and re-run step 4.
+   (Alternatives in Skills Army HQ `references/recovery.md`: the verified backup ZIP or the staged
+   prior folder.) If the doc itself is wrong, revert the PR on `development` through the normal lane.
+7. **Close #938** only after step 4 passes on the Mini. Comment on #938 with the merge sha, CI and
+   reconcile run URLs, the publish commit, and the step-4 outputs (sync status, readlink, diff,
+   `--check` line).
diff --git a/releases.sql b/releases.sql
index d9ad6031..d748f0ce 100644
--- a/releases.sql
+++ b/releases.sql
@@ -1,6 +1,6 @@
 -- releases-app canonical dump (GH-32 grammar: GID-keyed rows, natural keys elsewhere,
 -- no integer PKs/FKs as values; rebuild renumbers deterministically)
--- generation: 1384
+-- generation: 1388
 -- table: schema_migrations
 INSERT INTO schema_migrations(version, applied_at) VALUES('1', '2026-08-19T01:32:22Z');
 INSERT INTO schema_migrations(version, applied_at) VALUES('2', '2026-08-19T18:55:40Z');
@@ -13,7 +13,7 @@ INSERT INTO schema_migrations(version, applied_at) VALUES('8', '2026-09-12T16:07
 INSERT INTO schema_migrations(version, applied_at) VALUES('9', '2026-09-23T01:01:18Z');
 -- table: settings
 INSERT INTO settings(key, value, updated_at) VALUES('enforcement', 'lenient', '2026-09-08T05:45:05Z');
-INSERT INTO settings(key, value, updated_at) VALUES('generation', '1384', '2026-10-03T01:22:26Z');
+INSERT INTO settings(key, value, updated_at) VALUES('generation', '1388', '2026-10-03T02:52:08Z');
 INSERT INTO settings(key, value, updated_at) VALUES('repo_slug', 'XYZ-forge', '2026-09-08T05:45:05Z');
 -- table: repos
 INSERT INTO repos(global_id, slug, updated_at) VALUES('repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'XYZ-forge', '2026-09-08T05:45:05Z');
@@ -790,6 +790,7 @@ INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, positi
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3ZE4CX1AKEJ9PC0VQXQ8N8S', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '854', 'Execute approved gate dispositions', 'In progress', '116', '🚧', NULL, NULL, NULL, 'PROJECT/2-WORKING/GH-854-GATE-DISPOSITIONS.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/854', '- **GH-854 · Execute approved gate dispositions** — [bounded execution](PROJECT/2-WORKING/GH-854-GATE-DISPOSITIONS.md); rated 70/50/50/85. Independent plan QA Approved; canonical stabilization list stays on issue854.', '2026-10-02T23:10:32Z', '2026-10-02T23:10:33Z', '70', '50', '50', '85', NULL, 'in-progress');
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3ZE4DSS0TANB4NYFFQHDT8Q', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '920', 'Deferred ungated-warning fixture copy failure', 'Deferred · vision', '116', '⏸️', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-920-UNGATED-FIXTURE-DEFERRED.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/920', '- **GH-920 · Deferred ungated-warning fixture copy failure** 🆕 **captured 2026-10-02 via HQ** — [GH-920-UNGATED-FIXTURE-DEFERRED.md](PROJECT/1-INBOX/GH-920-UNGATED-FIXTURE-DEFERRED.md) · [#920](https://github.com/HiQS-Labs/XYZ-forge/issues/920) (rated 15/30/50/75)', '2026-10-02T23:10:33Z', '2026-10-02T23:10:33Z', '15', '30', '50', '75', NULL, NULL);
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3ZNNDQE19MMEPH9CPTWRPAW', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '898', 'board_sync: source the repo allow-list from the rebalanceOS active-repos signal', 'In progress', '116', '🚧', NULL, NULL, NULL, 'PROJECT/2-WORKING/GH-898-BOARD-SYNC-ACTIVE-REPOS.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/898', '- **GH-898 · board_sync: source the repo allow-list from the rebalanceOS active-repos signal** — opt-in repos_source reads rebalanceOS top-active repos read-only, falls back to the pinned list. rated 55/25/50/75 → [GH-898-BOARD-SYNC-ACTIVE-REPOS.md](PROJECT/2-WORKING/GH-898-BOARD-SYNC-ACTIVE-REPOS.md)', '2026-10-03T01:22:10Z', '2026-10-03T01:22:16Z', '55', '25', '50', '75', NULL, 'in-progress');
+INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M3ZSH59X2E9ZSXNE2A68MRX6', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '938', 'relay-xyz SKILL.md: First-time setup tells Skills Army-managed Macs to run install.sh', 'In progress', '116', '🚧', NULL, NULL, NULL, 'PROJECT/2-WORKING/GH-938-RELAY-XYZ-MANAGED-SETUP.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/938', '- **GH-938 · relay-xyz SKILL.md: First-time setup tells Skills Army-managed Macs to run install.sh** — [GH-938-RELAY-XYZ-MANAGED-SETUP.md](PROJECT/2-WORKING/GH-938-RELAY-XYZ-MANAGED-SETUP.md) · [#938](https://github.com/HiQS-Labs/XYZ-forge/issues/938) (rated 40/35/50/85)', '2026-10-03T02:29:44Z', '2026-10-03T02:52:08Z', '40', '35', '50', '85', NULL, 'in-progress');
 -- table: jog_queue
 INSERT INTO jog_queue(global_id, repo_gid, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason) VALUES('jog-01M122D1G6F8AWEKQHKFPCFD37', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '275', '1', 'completed', '2026-08-27T16:56:10Z', '2026-08-27T18:11:04Z', '5', NULL, 'preflight: already-landed');
 INSERT INTO jog_queue(global_id, repo_gid, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason) VALUES('jog-01M122D1WM4Z659A8N591AR0H8', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '269', '1', 'failed', '2026-08-27T16:56:10Z', '2026-08-27T18:39:22Z', '3', NULL, 'drive failed (exit 7)');
@@ -2385,6 +2386,10 @@ INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_bef
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-add', 'rmi-01M3ZNNDQE19MMEPH9CPTWRPAW', '2026-10-03T01:22:10Z', '7432318690f24dfb810cffcae7bb2309', 'default', 'd7ef3cc796ecc0cb489645795646014da5adb067d1339d8faa1222af25b1252b', 'a2aa43168a0c04e8b45813c07ae3358b28f2d9db3b92886bacc6578cc4c2b5df');
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-update', 'rmi-01M3ZNNDQE19MMEPH9CPTWRPAW', '2026-10-03T01:22:16Z', '36a2cab6d2fb487aa5a9dfae88a7cb7c', 'default', 'a2aa43168a0c04e8b45813c07ae3358b28f2d9db3b92886bacc6578cc4c2b5df', 'c269effc942a05377563b9041f5e13db2d940d9b01696e4e3ee89ae627bdb710');
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('merge-rebuild', 'reanchor:167', '2026-10-03T01:22:26Z', '45697b6543484f24946d8d6bb2a60e7c', 'default', 'c269effc942a05377563b9041f5e13db2d940d9b01696e4e3ee89ae627bdb710', 'c269effc942a05377563b9041f5e13db2d940d9b01696e4e3ee89ae627bdb710');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-add', 'rmi-01M3ZSH59X2E9ZSXNE2A68MRX6', '2026-10-03T02:29:44Z', '4efbbe163f574d19813ccc766232aeb8', 'default', 'c269effc942a05377563b9041f5e13db2d940d9b01696e4e3ee89ae627bdb710', 'c23e3d87cbed5a58fc74ffef43161bbcdfd63929094eb71849d7d9440f8491ba');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-repoint', 'rmi-01M3ZSH59X2E9ZSXNE2A68MRX6', '2026-10-03T02:32:20Z', '908224aca9b2456fa9b74e9fdcf7315f', 'default', 'c23e3d87cbed5a58fc74ffef43161bbcdfd63929094eb71849d7d9440f8491ba', '628bd30d589ce5aeb2aacb2bbc9f87f2e0e68be243ce256fa94e64e4a2a9bae8');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-update', 'rmi-01M3ZSH59X2E9ZSXNE2A68MRX6', '2026-10-03T02:32:20Z', '0b339d6d6e374e89846521c27f951d3f', 'default', '628bd30d589ce5aeb2aacb2bbc9f87f2e0e68be243ce256fa94e64e4a2a9bae8', '4b414b2bc60452f29f0b277f0117b2b09140f7469f7ad09ce201f5418dbb5bf1');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-update', 'rmi-01M3ZSH59X2E9ZSXNE2A68MRX6', '2026-10-03T02:52:08Z', '5f20edbe17fb4e6291feb4646d095651', 'default', '4b414b2bc60452f29f0b277f0117b2b09140f7469f7ad09ce201f5418dbb5bf1', '2bd1d5f5630a48434849d65fbde930a8d3bfcd5c1b61dbff65e9dcc9861b4e4f');
 -- table: work_events
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M2CBC3C2HSWRSBY81TAZHYY0', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '568', 'df2ee890077d486dbe23311c5dd74d82', 'updated', '{"marker": "\u2705", "section": "Completed"}', '2026-09-13T03:01:02Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M2CGH1A7Z979TG5DQJHN8DX6', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '591', '6d3d7a7619c247b5a85a039ea98756bd', 'parked', '{"section": "Queue / parked intake"}', '2026-09-13T04:31:07Z');
@@ -2952,3 +2957,6 @@ INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload,
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3ZE4E3HTK195M905ZX5FF6R', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '920', '86579f96fe5b4c19b2860d9cfd4e3bd1', 'deferred', '{"marker": "\u23f8\ufe0f", "section": "Deferred \u00b7 vision", "source": "roadmap-update", "transition": true}', '2026-10-02T23:10:33Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3ZNNDR4V4SK5ZPSMNHK9NS8', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '898', '7432318690f24dfb810cffcae7bb2309', 'parked', '{"section": "Queue / parked intake"}', '2026-10-03T01:22:10Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3ZNNKG1QSHYS6ZP8TNVMZ7K', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '898', '36a2cab6d2fb487aa5a9dfae88a7cb7c', 'in_flight', '{"accepted_start": true, "marker": "\ud83d\udea7", "section": "In progress", "source": "roadmap-update", "transition": true}', '2026-10-03T01:22:16Z');
+INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3ZSH5AVNEM89RR63VKWVQD5', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '938', '4efbbe163f574d19813ccc766232aeb8', 'parked', '{"section": "Queue / parked intake"}', '2026-10-03T02:29:44Z');
+INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3ZSNX8PA9BD85P0VXMHVVS2', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '938', '0b339d6d6e374e89846521c27f951d3f', 'updated', '{"marker": "\ud83c\udd95", "section": "Queue / parked intake", "source": "roadmap-update", "transition": false}', '2026-10-03T02:32:20Z');
+INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M3ZTT54Q5J3VE47RETCWV953', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '938', '5f20edbe17fb4e6291feb4646d095651', 'in_flight', '{"accepted_start": true, "marker": "\ud83d\udea7", "section": "In progress", "source": "roadmap-update", "transition": true}', '2026-10-03T02:52:08Z');
diff --git a/skills/1-hourly/relay-xyz/SKILL.md b/skills/1-hourly/relay-xyz/SKILL.md
index 1b3b6af7..277fbfd3 100644
--- a/skills/1-hourly/relay-xyz/SKILL.md
+++ b/skills/1-hourly/relay-xyz/SKILL.md
@@ -64,11 +64,25 @@ manual mode).
 
 ## First-time setup on a new clone or machine (make the skill discoverable)
 
-This repo keeps its skills in top-level `skills/`, which Claude Code does **not** scan. A session
-finds `relay-xyz` only if it's symlinked into `~/.claude/skills/`. A fresh clone or second machine has
-no such symlink, so the skill is invisible in **every** session there — the "other VS Code sessions
-can't find the relay-xyz files" failure. Fix it **once per clone** (idempotent, self-locating, no
-hardcoded path):
+First check whether Skills Army HQ already manages this skill on the machine:
+
+```bash
+readlink ~/.claude/skills/relay-xyz   # or the relay-xyz entry in your app's skills root
+```
+
+**Managed by Skills Army HQ — skip `install.sh`.** If the link resolves into a `Deployed Skills/relay-xyz`
+folder, the skill is already discoverable and Skills Army HQ owns the link; its rule is not to run copied
+`install.sh` files. Running it there exits 1 on the live link (GH-678 keeps it) and can add links in app
+roots the collection does not target. Manage links with Skills Army HQ (`sync.py`) and go straight to the
+locator below: run its `--check` from the installed path. If it does not resolve a harness, save your
+canonical XYZ-forge clone with the one-line command `--check` prints (`${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness`),
+or prefix a single command with `XYZ_HARNESS=/path/to/XYZ-forge`. Do not export it from shell startup files.
+
+**Not managed (no link, or a dangling one).** This repo keeps its skills in top-level `skills/`, which
+Claude Code does **not** scan. A session finds `relay-xyz` only if it's symlinked into `~/.claude/skills/`.
+A fresh clone or second machine without Skills Army HQ has no such symlink, so the skill is invisible in
+**every** session there — the "other VS Code sessions can't find the relay-xyz files" failure. Fix it
+**once per maintained clone** (idempotent, self-locating, no hardcoded path):
 
 ```bash
 bash skills/1-hourly/relay-xyz/install.sh   # symlinks this clone's skills/1-hourly/relay-xyz into ~/.claude/skills/
````

## C. SKILL.md @ c7519fc6 lines 60-125 (cat -n)
````
    60	  be a foreign repo if the locator can reach a canonical XYZ-forge harness.
    61	
    62	**Not** for: scaffolding a brand-new thread from scratch (that's `/relay`), or work that needs a human checkpoint between every turn (use plain `/relay`
    63	manual mode).
    64	
    65	## First-time setup on a new clone or machine (make the skill discoverable)
    66	
    67	First check whether Skills Army HQ already manages this skill on the machine:
    68	
    69	```bash
    70	readlink ~/.claude/skills/relay-xyz   # or the relay-xyz entry in your app's skills root
    71	```
    72	
    73	**Managed by Skills Army HQ — skip `install.sh`.** If the link resolves into a `Deployed Skills/relay-xyz`
    74	folder, the skill is already discoverable and Skills Army HQ owns the link; its rule is not to run copied
    75	`install.sh` files. Running it there exits 1 on the live link (GH-678 keeps it) and can add links in app
    76	roots the collection does not target. Manage links with Skills Army HQ (`sync.py`) and go straight to the
    77	locator below: run its `--check` from the installed path. If it does not resolve a harness, save your
    78	canonical XYZ-forge clone with the one-line command `--check` prints (`${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness`),
    79	or prefix a single command with `XYZ_HARNESS=/path/to/XYZ-forge`. Do not export it from shell startup files.
    80	
    81	**Not managed (no link, or a dangling one).** This repo keeps its skills in top-level `skills/`, which
    82	Claude Code does **not** scan. A session finds `relay-xyz` only if it's symlinked into `~/.claude/skills/`.
    83	A fresh clone or second machine without Skills Army HQ has no such symlink, so the skill is invisible in
    84	**every** session there — the "other VS Code sessions can't find the relay-xyz files" failure. Fix it
    85	**once per maintained clone** (idempotent, self-locating, no hardcoded path):
    86	
    87	```bash
    88	bash skills/1-hourly/relay-xyz/install.sh   # symlinks this clone's skills/1-hourly/relay-xyz into ~/.claude/skills/
    89	```
    90	
    91	It also replaces a stale/dangling symlink and verifies `find-harness.sh` resolves the harness. The
    92	locator below handles *where the harness scripts live*; this step handles *whether Claude Code can
    93	load the skill at all* — a layer the locator can't reach, since it runs only after the skill loads.
    94	
    95	## Preconditions — locate the harness (bundled locator, never hardcode a path)
    96	
    97	`relay-xyz` ships its own device-agnostic locator, [`find-harness.sh`](find-harness.sh), beside this
    98	skill. It checks an explicit override, a caller's vendored harness, the current repo, its own
    99	installed location, a per-Mac config at `${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness`, and bounded
   100	canonical XYZ-forge clone locations. A copied Skills Army deployment therefore works from a foreign
   101	repo. `--check` shows a command to save the chosen canonical harness in that config and warns when
   102	its cached upstream is ahead. It never fetches while checking.
   103	
   104	Run this first. It finds the locator, exports the harness env, `cd`s into the clone that ships the
   105	harness, and prints a one-glance readiness line:
   106	
   107	```bash
   108	# Find the bundled locator. The skill installs at one of these — all anchored on $HOME or
   109	# the CWD, never an absolute machine path:
   110	for L in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/1-hourly/relay-xyz/find-harness.sh}" \
   111	         "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
   112	         "$HOME/.codex/skills/relay-xyz/find-harness.sh" \
   113	         "$HOME/.gemini/config/skills/relay-xyz/find-harness.sh" \
   114	         "$HOME/.gemini/antigravity/skills/relay-xyz/find-harness.sh" \
   115	         "$HOME/.gemini/antigravity-cli/skills/relay-xyz/find-harness.sh" \
   116	         "./.claude/skills/relay-xyz/find-harness.sh" \
   117	         "$(git rev-parse --show-toplevel 2>/dev/null)/skills/1-hourly/relay-xyz/find-harness.sh"; do
   118	  [ -n "$L" ] && [ -x "$L" ] && break
   119	done
   120	[ -x "$L" ] || { echo "relay-xyz: locator not found — set XYZ_HARNESS to your XYZ-forge clone"; exit 1; }
   121	
   122	eval "$("$L" --env)"   # exports HARNESS, TICK, TICK_REPO_ROOT, RELAY_HAS_{TICK,CODEX,AGY,COMMANDCODE,DEEPSEEK}
   123	cd "$HARNESS"
   124	"$L" --check           # prints: harness path + which Path-A workers (tick/codex/agy/cmd/dsh) are on PATH
   125	```
````

## D. TESTS-RESULTS/2026-10-02+GH-938/SUMMARY.md
# GH-938 verification — relay-xyz First-time setup (docs only)

Tested head: `204750c576f2bdc12764d42915bbcdedf2985388` (branch `fix/gh938-relay-xyz-managed-setup`),
base `5212dae44bf5e1873be4689d63ef792ec1b6d93e` (origin/development). Environment: Linux box
(Debian, node v20.19.2), disposable full clones. Provenance: `provenance.jsonl` (sha256 per artifact).

| Check | Result |
|---|---|
| `test/find-harness.sh` (pins :41, :43) | 50 pass, 0 fail |
| `test/gh678-installer-live-links.sh` | pass (24 installers) |
| `test/path-integrity.sh` | 3 pass, 0 fail |
| `test/gh681-reviewer-probe-rules.sh` | all cases passed |
| `test/gh346-gateway-allowlists.sh` | 55 pass, 0 fail |
| `test/gh278-turn-timeout-parity.sh` | 11 pass, 0 fail |
| Red control: bogus repo path token in SKILL.md | path-integrity exit 1 (expected), restored exit 0 |
| Red control: exact CWD-relative `--check` line | find-harness :43 pin FAIL (expected), restored 50/0 |
| Wording grep `Deployed Skills` | head: line 73; base: no match |
| Full `./validate.sh` (Large tier) | exit 1: 399/410 passed, 11 failed, 14m47s, 2026-10-02 19:54–20:09 PDT |
| Base attribution of the 11 failures | all 11 fail identically on base `5212dae4` on this box |

The 11 full-gate failures are environment/pre-existing on this Linux box, not caused by this diff
(a one-section markdown edit no failing suite reads): gh610-claude-subscription (real Claude probe),
gh399-packet-acceptance-continuation, gh390-timeout-attribution and gh492-idle-kill (network probe
classification), gh505-relay-attest (N3), gh402-board-sync, gh544-pre-push-gate (criss-cross fixture),
swarm-preflight (T37c/T38 stale-lock), gh123-lock-progress-bound (timing), gh280-jog-marathon-adapter
(H2 containment), gh436-merge-cleanup. Each also failed alone in the gate's serial re-run. Hosted CI on
the PR is the cross-platform signal.

## E. provenance.jsonl
```
{"name": "full-gate", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "./validate.sh", "exit_code": 1, "artifact": "validate-full.log", "checks": "399/410 passed; 11 failed (each also failed alone in the gate serial re-run)", "started": "2026-10-02 19:54:49 PDT", "ended": "2026-10-02 20:09:35 PDT", "clone": "/workspace/xyz/gate-938 (git clone of the task clone, branch checked out, origin reset to GitHub, npm ci)", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "qualification": "all 11 failures reproduce on base 5212dae4 (see base-attribution); none attributable to this docs diff", "artifact_sha256": "8929d44072c57542c72adf664c19e5e8d4e138fabf0e8715f6d908cfefc0f68b"}
{"name": "base-attribution", "head_sha": "5212dae44bf5e1873be4689d63ef792ec1b6d93e", "command": "for t in <11 failed suites>; do bash test/$t.sh; done", "exit_code": 1, "artifact": "base-5212dae4/base-attrib.log", "checks": "11/11 fail on base with the same messages", "clone": "/workspace/xyz/base-938 (detached at base)", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "qualification": "environment/pre-existing failures", "artifact_sha256": "d4d6ed31bf62a8c24a0e14a39ca51f68e3c66ff3fd70cabaff3b840cb1b26885"}
{"name": "focused:find-harness", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "bash test/find-harness.sh", "exit_code": 0, "artifact": "focused-find-harness.log", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "61644359889fda5a778f8c32322062608fab49f1db247022e3cb58701992b7de"}
{"name": "focused:gh678-installer-live-links", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "bash test/gh678-installer-live-links.sh", "exit_code": 0, "artifact": "focused-gh678-installer-live-links.log", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "6c2bcc2e49afa63210bf66ccf324498c668fc8824a1553aa083b6dce339ed3d4"}
{"name": "focused:path-integrity", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "bash test/path-integrity.sh", "exit_code": 0, "artifact": "focused-path-integrity.log", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "ffaa657ec8886071cd0c20c071feea3ff6fd89868dd793345c6fd08aed930e85"}
{"name": "focused:gh681-reviewer-probe-rules", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "bash test/gh681-reviewer-probe-rules.sh", "exit_code": 0, "artifact": "focused-gh681-reviewer-probe-rules.log", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "9e4556d9e9287da0288f49e94d3c1d26673274af21a74cf95cd64a3ba27b1776"}
{"name": "focused:gh346-gateway-allowlists", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "bash test/gh346-gateway-allowlists.sh", "exit_code": 0, "artifact": "focused-gh346-gateway-allowlists.log", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "4ac8c4f9a54f72b15b0d6748afa6a35435ee7db93aba3d8373e587caf705eb1b"}
{"name": "focused:gh278-turn-timeout-parity", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "bash test/gh278-turn-timeout-parity.sh", "exit_code": 0, "artifact": "focused-gh278-turn-timeout-parity.log", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "56acc8a29d0820453e13939fd214f0a3787b638d53fba4b4a7f5b3eb65d2ed74"}
{"name": "red-control:path-integrity", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "add `skills/1-hourly/relay-xyz/bogus-gh938.sh` token to SKILL.md; bash test/path-integrity.sh; restore", "exit_code": 1, "artifact": "red-path-integrity.log", "qualification": "expected red; restored tree re-ran exit 0 (focused-path-integrity.log). Run on the task working tree whose SKILL.md blob 277fbfd3 equals the head blob", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "798c60b292629f1eb195965b9db13d70ef61a5410503b2328f5dd5986499d38d"}
{"name": "red-control:find-harness-pin-43", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "append the line 'bash skills/1-hourly/relay-xyz/find-harness.sh --check' to SKILL.md; bash test/find-harness.sh; restore", "exit_code": 1, "artifact": "red-find-harness.log", "qualification": "expected red on the :43 pin; restored 50/0", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "68a85d1067be7a06927db146ee38900ca57e3766a9f7946f96d56bc93bd1d845"}
{"name": "wording-grep-red-green", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "grep -n 'Deployed Skills' skills/1-hourly/relay-xyz/SKILL.md (head) vs git show 5212dae4:... | grep", "exit_code": 0, "artifact": "grep-wording-red-green.log", "qualification": "head exit 0 (line 73); base exit 1", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "a69d5d533ddbcead57eb281c416f6822fc560b092d3bc4e40afa3a61f1fabcc7"}
{"name": "prior-art-recon", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "python3 utils/py/prior_art_recon.py --query \"relay-xyz install.sh Skills Army managed\"", "exit_code": 0, "artifact": "prior-art-recon.txt", "qualification": "3 open PRs listed (#935/#932/#929); none touch relay-xyz files (gh pr view --json files)", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clone; no codex/claude CLIs on the box", "artifact_sha256": "949f2bf1abba40577d7456375e84c0c013c118cf756f3676c58f8417e11bd8d0"}
```

## F. focused logs (tails) and red controls
### focused-find-harness.log (last 6 lines)
```
  PASS: copied skill warns on a non-development branch
  PASS: invalid config falls through to canonical search
  PASS: copied skill reports held lock and cached-upstream lag
  PASS: dead holder is reported as a stale lock
  PASS: copied skill compares vendored drift with configured live harness
  find-harness: 50 pass, 0 fail
```
### focused-path-integrity.log (last 6 lines)
```
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.com.apple.provenance'
  PASS: make-pkg.sh source list matches the committed tarball (18 files)
  PASS: all referenced relay/script/doc paths resolve (scanned 619 scripts + curated docs)
  checked 171 cross-folder skill links
  PASS: cross-folder skill Markdown links resolve
  path-integrity: 3 pass, 0 fail
```
### focused-gh678-installer-live-links.log (last 6 lines)
```
  PASS: browserbase: replaces a dangling link
  PASS: open-router: refuses a live foreign link (exit 1, link untouched)
  PASS: open-router: replaces a dangling link
  PASS: vendor-stack: refuses a live foreign link (exit 1, link untouched)
  PASS: vendor-stack: replaces a dangling link
  PASS: matrix covered all 24 discovered installers
```
### focused-gh681-reviewer-probe-rules.log (last 6 lines)
```
  PASS: case 6: skills/1-hourly/relay-xyz/SKILL.md carries the probe allowance
  PASS: case 7: reviewer worktree begins with .relay-scratch/ pre-created
  PASS: case 7: a probe that writes only under .relay-scratch/ is not off-lane
  PASS: case 7: a probe that leaves .pytest_cache/ in the worktree is off-lane (residue still fails the turn)
  PASS: case 8: apply_reviewer_turn_env injects PYTHONDONTWRITEBYTECODE and TMPDIR for reviewer turns only
gh681-reviewer-probe-rules: all cases passed
```
### focused-gh346-gateway-allowlists.log (last 6 lines)
```
  PASS: 2.10 no worktree created before the refusal
  PASS: 2.7 find-harness.sh reports RELAY_HAS_COMMANDCODE
  PASS: 2.7 find-harness.sh reports RELAY_HAS_DEEPSEEK
  PASS: 2.7 --env actually emits the new flags
  PASS: 2.8 relay-xyz SKILL.md documents the deepseek worker
  gh346-gateway-allowlists: 55 pass, 0 fail
```
### focused-gh278-turn-timeout-parity.log (last 6 lines)
```
  PASS: bash-shim: no fixture leaked into the repo root
  PASS: py-shim: shim exited 7
  PASS: py-shim: untracked.md was cleaned up
  PASS: py-shim: tracked.md was restored
  PASS: py-shim: no fixture leaked into the repo root
  gh278-turn-timeout-parity (total): 11 pass, 0 fail
```
### red-path-integrity.log (last 6 lines)
```
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.com.apple.provenance'
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.com.apple.provenance'
tar: Ignoring unknown extended header keyword 'LIBARCHIVE.xattr.com.apple.provenance'
  PASS: make-pkg.sh source list matches the committed tarball (18 files)
  broken path reference 'skills/1-hourly/relay-xyz/bogus-gh938.sh' in skills/1-hourly/relay-xyz/SKILL.md
  FAIL: one or more referenced paths do not exist (see above) — fix the path or the reference
```
### red-find-harness.log (last 6 lines)
```
  PASS: copied skill warns on a non-development branch
  PASS: invalid config falls through to canonical search
  PASS: copied skill reports held lock and cached-upstream lag
  PASS: dead holder is reported as a stale lock
  PASS: copied skill compares vendored drift with configured live harness
  find-harness: 49 pass, 1 fail
```
### grep-wording-red-green.log (last 6 lines)
```
# head 204750c576f2bdc12764d42915bbcdedf2985388
73:**Managed by Skills Army HQ — skip `install.sh`.** If the link resolves into a `Deployed Skills/relay-xyz`
exit=0
# base 5212dae4
exit=1
```

## G. validate-full.log: summary block
```

===============================
Summary
===============================
telemetry: /workspace/xyz/gate-938/.tick/telemetry/validate-parallel-1790996089119-938622.jsonl (420 suite events, 407 registered)
10 slowest suites:
  name  duration_s  rc
  gh549-work-events.sh  173.158  0
  pdda-install-startup-docs.sh  118.251  0
  marathon-drive.sh  118.159  0
  gh436-merge-cleanup.sh  88.716  1
  marathon-root-audit.sh  88.117  0
  gh365-pdda-gov-scan.sh  67.998  0
  pdda-repo-contract.sh  67.111  0
  agy-turn.sh  62.833  0
  gh365-tier-fail-closed.sh  55.116  0
  gh280-jog-marathon-adapter.sh  51.715  1
re-run ladder: 11 suite(s), 244.926s total
passed: 399 / 410
failed:
  - gh610-claude-subscription.sh
  - gh399-packet-acceptance-continuation.sh
  - gh390-timeout-attribution.sh
  - gh492-idle-kill.sh
  - gh505-relay-attest.sh
  - gh402-board-sync.sh
  - gh544-pre-push-gate.sh
  - swarm-preflight.sh
  - gh123-lock-progress-bound.sh
  - gh280-jog-marathon-adapter.sh
  - gh436-merge-cleanup.sh

real	14m46.531s
user	30m55.541s
sys	8m17.921s
VALIDATE_EXIT=1
end 2026-10-02 20:09:35 PDT
```

## H. base attribution (5212dae4)
```
gh610-claude-subscription base_exit=1
gh399-packet-acceptance-continuation base_exit=1
gh390-timeout-attribution base_exit=1
gh492-idle-kill base_exit=1
gh505-relay-attest base_exit=1
gh402-board-sync base_exit=1
gh544-pre-push-gate base_exit=1
swarm-preflight base_exit=1
gh123-lock-progress-bound base_exit=1
gh280-jog-marathon-adapter base_exit=1
gh436-merge-cleanup base_exit=1
```

## I. test/find-harness.sh @ c7519fc6 lines 38-44
```
    38	# in every installed/foreign-CWD scenario. Pin the installed-root discovery before exercising the
    39	# locator itself, so the documentation cannot reintroduce a path bug while this script stays green.
    40	ok "skill front door searches the user install root" \
    41	  "grep -q '\$HOME/.claude/skills/relay-xyz/find-harness.sh' '$SKILL'"
    42	ok "skill front door does not prescribe the CWD-relative command" \
    43	  "! grep -q '^bash skills/1-hourly/relay-xyz/find-harness.sh --check$' '$SKILL'"
    44	
```
`````
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

swept file: no — the packet explicitly restricts review to quoted bytes and supplies `SKILL.md` lines 60–125, not the whole touched file.

- [Pass] The quoted setup change routes a `Deployed Skills/relay-xyz` link around `install.sh` and to the locator, config, or command-scoped override (`SKILL.md:65-79` in section C). The unchanged locator block includes the `$HOME/.claude/skills/relay-xyz/find-harness.sh` pin and `"$L" --check` (`SKILL.md:104-124`).
- [Pass] The quoted diff adds no `.sh` or test file (section A), and `releases.sql` adds only the GH-938 roadmap row plus its receipts/events and generation metadata (section B). The CHANGELOG calls the installer change deferred (section B).
- [Should] Supply the complete `SKILL.md` at `c7519fc6` in the next packet, or an equivalent read-only final-file view, so the mandatory whole-file sweep can be completed. Section C stops at line 125, while the packet itself identifies a pre-existing inaccurate installer claim at `SKILL.md:207-209` (section B, Recon). Keep that known claim's disposition explicit; no installer behavior change is requested.
- [Should] Strengthen the 11-failure attribution before calling it identical: section H quotes only `base_exit=1` for each suite, while SUMMARY says all 11 fail "identically" and section E says "same messages." Quote decisive head and base messages for each suite, or narrow the claim to what the provided exits establish. This is evidence clarification, not a request to rerun suites here.
- [Nit] The stated `Definition of Done` remains the scaffold placeholder below the embedded packet. The four binding requirements in the packet can fill it without changing the artifact.

VERDICT: FAIL
Basis: The quoted change appears aligned with GH-938, but the required whole-file review is impossible from this packet, and the base-attribution quotation does not support the claimed identical failures. These are review-evidence gaps before a READY PR sign-off.

Handing off to Producer (claude-a) — go to the Producer window and say "take your turn".

### Producer · Round 2 (claude-a)

Definition of Done for this final QA (fills the scaffold placeholder, from the packet's binding
requirements 1-4): (1) the SKILL.md diff routes a `Deployed Skills/relay-xyz` link past `install.sh`
to the locator `--check`, `${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness`, or a one-command
`XYZ_HARNESS`, and keeps the install path for unmanaged machines; (2) no new suite or TESTS entry and
the named pins stay true, with evidence under TESTS-RESULTS/ + provenance.jsonl; (3) the plan keeps
the reviewed checklist; (4) every full-gate failure is attributed with evidence.

Dispositions for Round 1 findings:
- Should (whole-file sweep impossible) — **Implemented.** The complete `skills/1-hourly/relay-xyz/SKILL.md`
  at the tested head `204750c5` (identical blob `277fbfd3` at branch tip `2c326c24`) is quoted below
  with line numbers. Known pre-existing claim at `SKILL.md:221-223` (was 207-209 at base; shifted by
  +14): "only `install.sh` writes anything, and it writes only into `~/.claude/skills/`" is inaccurate
  (install.sh also links other app roots). Disposition: **Deferred** with the install.sh detection follow-up, recorded
  in the plan's Deferred section; out of the operator's docs-only "First-time setup" scope.
- Should (11-failure attribution) — **Implemented.** New `TESTS-RESULTS/2026-10-02+GH-938/failure-attribution.md`
  (commit `2c326c24`) compares decisive failing assertions per suite, head vs base. Where the gate's
  40-line tail did not show them (gh436, swarm-preflight, gh402) the suite was re-run alone on head
  (`head-204750c5/`) and the `FAIL` line sets diffed against base: empty diffs. Three provenance rows
  added with sha256. SUMMARY now says "same failing assertions — failure-attribution.md".
- Nit (DoD placeholder) — **Implemented** above.

## failure-attribution.md (verbatim)

# Full-gate failure attribution — head 204750c5 vs base 5212dae4 (same Linux box)

Head lines come from the gate's serial re-run (`validate-full.log`, which keeps only the last 40 lines
per failed suite); where that tail did not show the failing assertions, the suite was re-run alone on
head and logged under `head-204750c5/`. Base lines come from `base-5212dae4/base-<suite>.log`.
Temp-dir and ULID path segments are ignored in the comparison.

| Suite | Head (204750c5) decisive failure | Base (5212dae4) | Match |
|---|---|---|---|
| gh610-claude-subscription | `FAIL: test_real_probe_and_consult_dispatch` | same test fails | same |
| gh399-packet-acceptance-continuation | `FAIL: C4 no relay file produced (marathon-drive rc=1)` | same | same |
| gh390-timeout-attribution | `FAIL: idle: BAD timeout-unclassified :: ... one-shot network probe failed` | same | same |
| gh492-idle-kill | `FAIL: expected timeout-idle-unknown for the blocked turn, got timeout-unclassified` | same | same |
| gh505-relay-attest | `FAIL: N3: candidate binding wrong for a relay beside source` | same | same |
| gh402-board-sync | `29 passed, 5 failed`; `FAIL-` lines (head-204750c5/head-gh402-board-sync.log) | `29 passed, 5 failed`; identical `FAIL-` lines (diff empty) | same |
| gh544-pre-push-gate | `FAIL: criss-cross fixture is degenerate: fewer than two best common ancestors` | same | same |
| swarm-preflight | `98 passed, 2 failed`; T37c/T38 stale-lock (head-204750c5/head-swarm-preflight.log) | `98 passed, 2 failed`; identical `FAIL:` lines (diff empty) | same |
| gh123-lock-progress-bound | 3 `FAIL:` lines (moving queue exited 75 after 2s; acquired within bound; writer wrote no file) | same 3 | same (timing-sensitive) |
| gh280-jog-marathon-adapter | `FAIL: H2 unexpected vendored row state: ... containment-violation ... (exit 6)` | same (tmp/ULID path differs) | same |
| gh436-merge-cleanup | `FAILED (failures=18, skipped=6)` (head-204750c5/head-gh436-merge-cleanup.log) | `FAILED (failures=18, skipped=6)`; identical `FAIL:` test list (diff empty) | same |

Conclusion: every full-gate failure reproduces on the base commit with the same failing assertions,
so none is attributable to this one-section markdown diff.

## Provenance rows added (verbatim)

```
{"name": "head-standalone:gh436-merge-cleanup", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "bash test/gh436-merge-cleanup.sh", "exit_code": 1, "artifact": "head-204750c5/head-gh436-merge-cleanup.log", "qualification": "standalone re-run on head to capture full failing assertions (gate tail truncated); FAIL lines identical to base", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clones; no codex/claude CLIs on the box", "artifact_sha256": "a4d7e5a79e0b0e87e94719764cc951773cb42e9422dc91e20508bde22b1832d4"}
{"name": "head-standalone:swarm-preflight", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "bash test/swarm-preflight.sh", "exit_code": 1, "artifact": "head-204750c5/head-swarm-preflight.log", "qualification": "standalone re-run on head to capture full failing assertions (gate tail truncated); FAIL lines identical to base", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clones; no codex/claude CLIs on the box", "artifact_sha256": "f44720f79ea307486e5dcc1e3ef7b62e2e0cc0400d8b90136f4c093e8818cc5d"}
{"name": "head-standalone:gh402-board-sync", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "bash test/gh402-board-sync.sh", "exit_code": 1, "artifact": "head-204750c5/head-gh402-board-sync.log", "qualification": "standalone re-run on head to capture full failing assertions (gate tail truncated); FAIL lines identical to base", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clones; no codex/claude CLIs on the box", "artifact_sha256": "eb2120b62a8879c81ff721e41cea97e0ea63ebb28ae8ff18bf0afd072f477e4d"}
{"name": "failure-attribution", "head_sha": "204750c576f2bdc12764d42915bbcdedf2985388", "command": "manual comparison of head vs base failing assertions", "exit_code": 0, "artifact": "failure-attribution.md", "environment": "Linux box (Debian, Python 3, node v20.19.2), disposable full clones; no codex/claude CLIs on the box", "artifact_sha256": "40aff6c8ca0889020eb146b9a5909b2cfe08241220572ae700824a79eae67b61"}
```

## Full skills/1-hourly/relay-xyz/SKILL.md @ 2c326c24 (cat -n)

`````
     1	---
     2	name: relay-xyz
     3	description: >-
     4	  Drive an automated /relay review loop on THIS repo with the shipped
     5	  relay-automation harness (relay-drive.sh + codex-turn.sh / agy-turn.sh /
     6	  poll.sh) rather than improvising the handoff by hand. Use when the operator
     7	  wants to "run an automated relay", "have Codex or agy review this
     8	  end-to-end", "drive a relay to completion headless", "run the relay harness",
     9	  or set up the all-Claude hands-free poll loop. The skill can start from a
    10	  foreign repo because its locator selects a separate XYZ-forge harness. /relay
    11	  scaffolds the thread and owns the turn protocol; relay-xyz is the repo-specific
    12	  layer that runs the real scripts. NOT for scaffolding a thread from scratch
    13	  (that is /relay).
    14	---
    15	
    16	# relay-xyz — automated relays on the shipped harness
    17	
    18	**ALWAYS locate and run the bundled locator first — never claim the harness is missing without it.**
    19	Resolve the installed skill from stable install roots; do not assume the session CWD is this repo:
    20	
    21	```bash
    22	L=""
    23	for candidate in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/1-hourly/relay-xyz/find-harness.sh}" \
    24	                 "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
    25	                 "$HOME/.codex/skills/relay-xyz/find-harness.sh" \
    26	                 "$HOME/.gemini/config/skills/relay-xyz/find-harness.sh" \
    27	                 "$HOME/.gemini/antigravity/skills/relay-xyz/find-harness.sh" \
    28	                 "$HOME/.gemini/antigravity-cli/skills/relay-xyz/find-harness.sh" \
    29	                 "$(git rev-parse --show-toplevel 2>/dev/null)/.claude/skills/relay-xyz/find-harness.sh" \
    30	                 "$(git rev-parse --show-toplevel 2>/dev/null)/skills/1-hourly/relay-xyz/find-harness.sh"; do
    31	  [ -n "$candidate" ] && [ -f "$candidate" ] && { L="$candidate"; break; }
    32	done
    33	[ -n "$L" ] || { echo "relay-xyz: locator not found — install the skill or set XYZ_HARNESS" >&2; exit 1; }
    34	bash "$L" --check
    35	```
    36	
    37	That locator resolves the harness from wherever your CWD is and reports which workers
    38	(tick/codex/agy/cmd/dsh) are on PATH. See
    39	[Preconditions](#preconditions--locate-the-harness-bundled-locator-never-hardcode-a-path) below for the
    40	full env-exporting form (`eval "$(... --env)"` + `cd`) that every recipe in this doc assumes has already
    41	run.
    42	
    43	This repo **already ships** the relay automation. Don't reinvent the CLI handoff turn by turn — call
    44	the scripts under [`relay-automation/`](https://github.com/HiQS-Labs/XYZ-forge/blob/development/relay-automation/). `/relay` defines the thread format
    45	and turn protocol and scaffolds the dated file; **`relay-xyz` is the thin repo-specific layer that
    46	drives that thread to completion with the shipped supervisor + turn-takers.**
    47	
    48	Use `/relay` to *create* the thread (or reuse one under `relay-system/<date>/`), then `relay-xyz` to
    49	*run* it headless or hands-free.
    50	
    51	## When to use
    52	
    53	- "Run an automated relay" / "drive this relay to completion" / "run the relay harness."
    54	- "Have Codex or agy review `<file>` end-to-end."
    55	- Setting up the all-Claude hands-free `/loop` poll so two Claude windows self-serialize.
    56	- Running automated relays in **two different repos at the same time on one machine** — see
    57	  [Concurrent relays across repos](#concurrent-relays-across-repos-same-machine) (each repo needs its own
    58	  vendored `.xyz/`).
    59	- You have a relay thread (or are about to scaffold one with `/relay`); the current working tree may
    60	  be a foreign repo if the locator can reach a canonical XYZ-forge harness.
    61	
    62	**Not** for: scaffolding a brand-new thread from scratch (that's `/relay`), or work that needs a human checkpoint between every turn (use plain `/relay`
    63	manual mode).
    64	
    65	## First-time setup on a new clone or machine (make the skill discoverable)
    66	
    67	First check whether Skills Army HQ already manages this skill on the machine:
    68	
    69	```bash
    70	readlink ~/.claude/skills/relay-xyz   # or the relay-xyz entry in your app's skills root
    71	```
    72	
    73	**Managed by Skills Army HQ — skip `install.sh`.** If the link resolves into a `Deployed Skills/relay-xyz`
    74	folder, the skill is already discoverable and Skills Army HQ owns the link; its rule is not to run copied
    75	`install.sh` files. Running it there exits 1 on the live link (GH-678 keeps it) and can add links in app
    76	roots the collection does not target. Manage links with Skills Army HQ (`sync.py`) and go straight to the
    77	locator below: run its `--check` from the installed path. If it does not resolve a harness, save your
    78	canonical XYZ-forge clone with the one-line command `--check` prints (`${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness`),
    79	or prefix a single command with `XYZ_HARNESS=/path/to/XYZ-forge`. Do not export it from shell startup files.
    80	
    81	**Not managed (no link, or a dangling one).** This repo keeps its skills in top-level `skills/`, which
    82	Claude Code does **not** scan. A session finds `relay-xyz` only if it's symlinked into `~/.claude/skills/`.
    83	A fresh clone or second machine without Skills Army HQ has no such symlink, so the skill is invisible in
    84	**every** session there — the "other VS Code sessions can't find the relay-xyz files" failure. Fix it
    85	**once per maintained clone** (idempotent, self-locating, no hardcoded path):
    86	
    87	```bash
    88	bash skills/1-hourly/relay-xyz/install.sh   # symlinks this clone's skills/1-hourly/relay-xyz into ~/.claude/skills/
    89	```
    90	
    91	It also replaces a stale/dangling symlink and verifies `find-harness.sh` resolves the harness. The
    92	locator below handles *where the harness scripts live*; this step handles *whether Claude Code can
    93	load the skill at all* — a layer the locator can't reach, since it runs only after the skill loads.
    94	
    95	## Preconditions — locate the harness (bundled locator, never hardcode a path)
    96	
    97	`relay-xyz` ships its own device-agnostic locator, [`find-harness.sh`](find-harness.sh), beside this
    98	skill. It checks an explicit override, a caller's vendored harness, the current repo, its own
    99	installed location, a per-Mac config at `${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness`, and bounded
   100	canonical XYZ-forge clone locations. A copied Skills Army deployment therefore works from a foreign
   101	repo. `--check` shows a command to save the chosen canonical harness in that config and warns when
   102	its cached upstream is ahead. It never fetches while checking.
   103	
   104	Run this first. It finds the locator, exports the harness env, `cd`s into the clone that ships the
   105	harness, and prints a one-glance readiness line:
   106	
   107	```bash
   108	# Find the bundled locator. The skill installs at one of these — all anchored on $HOME or
   109	# the CWD, never an absolute machine path:
   110	for L in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/1-hourly/relay-xyz/find-harness.sh}" \
   111	         "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
   112	         "$HOME/.codex/skills/relay-xyz/find-harness.sh" \
   113	         "$HOME/.gemini/config/skills/relay-xyz/find-harness.sh" \
   114	         "$HOME/.gemini/antigravity/skills/relay-xyz/find-harness.sh" \
   115	         "$HOME/.gemini/antigravity-cli/skills/relay-xyz/find-harness.sh" \
   116	         "./.claude/skills/relay-xyz/find-harness.sh" \
   117	         "$(git rev-parse --show-toplevel 2>/dev/null)/skills/1-hourly/relay-xyz/find-harness.sh"; do
   118	  [ -n "$L" ] && [ -x "$L" ] && break
   119	done
   120	[ -x "$L" ] || { echo "relay-xyz: locator not found — set XYZ_HARNESS to your XYZ-forge clone"; exit 1; }
   121	
   122	eval "$("$L" --env)"   # exports HARNESS, TICK, TICK_REPO_ROOT, RELAY_HAS_{TICK,CODEX,AGY,COMMANDCODE,DEEPSEEK}
   123	cd "$HARNESS"
   124	"$L" --check           # prints: harness path + which Path-A workers (tick/codex/agy/cmd/dsh) are on PATH
   125	```
   126	
   127	After this, `$HARNESS` is the harness repo root, `$TICK` is the absolute `bin/tick`, and
   128	`TICK_REPO_ROOT` points `tick` at that clone's event log. The relay/turn scripts self-resolve their
   129	own location (`$(dirname "$BASH_SOURCE")/..`), so invoke them with **repo-relative** paths exactly as
   130	the [relay automation README](https://github.com/HiQS-Labs/XYZ-forge/blob/development/relay-automation/README.md) shows.
   131	The relay always operates on **the
   132	harness clone** (its `.tick/` log and guarded git root live there), whatever repo you launched from —
   133	so a clone with only `relay-system/` thread files still drives the real harness next door.
   134	
   135	## Concurrent relays across repos (same machine)
   136	
   137	`relay-drive.sh`/`marathon-drive.sh` hold **one global driver lock per harness clone**. This is
   138	intentional — two worktrees on the same `ROOT@HEAD` can corrupt git state (GH-42) — but it means
   139	**every repo pointed at the same harness clone shares that one lock**, so their automated relays
   140	*serialize*: a second one blocks (`exit 1`) until the first frees.
   141	
   142	### The driver-lock exclusion matrix (GH-354 Phase 3 — canonical)
   143	
   144	> This table is the **one canonical statement** of what the driver lock guarantees (PDDA Principle #4).
   145	> Anything else that describes the lock — driver headers, monitor docs — links here rather than
   146	> restating it. A second copy is how the wrong sentence in `marathon-drive.sh:194-196` survived.
   147	
   148	Both drivers resolve the lock through **one shared resolver** (GH-448) — `utils/py/rtl.py::driver_lock_path`
   149	and its Bash twin `relay-automation/driver-lock-lib.sh::driver_lock_path_for_repo` — which yields three
   150	shapes:
   151	
   152	| Repo shape | Lock path | Display label |
   153	|---|---|---|
   154	| normal clone (`.git` is a directory) | `<root>/.git/relay-driver.lock` | `.git/relay-driver.lock` |
   155	| **linked worktree** (`.git` is a file) | `<git-common-dir>/relay-driver.lock` — i.e. **the parent clone's** | `.git/relay-driver.lock` |
   156	| vendored `.xyz/` (no `.git`) | `<root>/.relay-driver.lock` | `.relay-driver.lock` |
   157	
   158	The middle row is the load-bearing one: **a linked worktree does not get its own lane.** It resolves
   159	to the same lock as the clone it was cut from — pinned by `test/gh448-driver-lock-resolver.sh`
   160	(*"worktree case resolves to the git COMMON dir, not `<worktree>/.git/…`"*, plus a bash/python
   161	*"parity"* assertion per shape). So all three driver pairs mutually exclude *per clone*:
   162	
   163	| Pair | Excludes? | Pinned by |
   164	|---|---|---|
   165	| marathon ↔ marathon | **yes** | `test/driver-lock.sh` — *"live lock (alive holder) → driver refuses (exit 1)"*, *"live lock left intact (not stolen)"* |
   166	| marathon ↔ relay | **yes** | `test/gh376-relay-drive-lock-parity.sh` — *"THE PIN (bash): relay-drive.sh refuses — the frozen twin agrees with the Python half"* |
   167	| relay ↔ relay | **yes** | `test/gh376-relay-drive-lock-parity.sh` — *"neither lane left a worktree-local lock behind at `$WT/.relay-driver.lock`"*, *"twin parity: both lanes emit a byte-identical REFUSAL"* |
   168	
   169	**This became true only in GH-376.** Before it, `relay-drive` used a two-branch guess with no case for
   170	a linked worktree, so it took a *per-worktree* `.relay-driver.lock` while `marathon-drive` took the
   171	shared one — the bottom two rows did **not** exclude, and #354's original premise that the lock was
   172	"the hard blocker (by design)" was false for them. The negative control
   173	(*"pre-fix 2-branch logic sails past the held lock"*) is what pins that it can't return.
   174	
   175	**To actually run two swarms concurrently, use separate full clones** — not linked worktrees, which
   176	share the lock by the table above, and not a shared harness, which serializes. Per-run hygiene that
   177	keeps the event stream readable even across clones: distinct `--phase-id` / `--relay-task`, plus
   178	`MARATHON_LANE_NS` for the lane namespace and an explicit `XYZ_SESSION_ID` (its fallback to `PHASE_ID`
   179	cannot tell one run from another).
   180	
   181	To run relays in **different repos at the same time on one machine**, give each repo its **own harness**
   182	so each gets its own lock, `.tick/`, and worktrees:
   183	
   184	| Install path / Tier | Ships | Relay capability | Releases ledger? | Lock |
   185	|---|---|---|---|---|
   186	| `install.sh` (tick-only) | `bin/tick` + `src/*.js` | ❌ falls back to the centralized harness | ❌ no | shared (serializes) |
   187	| **Tier 1 (default)**: `xyz-vendor.sh <target-repo> [--no-register]` | full core harness (`relay-automation/` minus `xyz-releases-onboard.sh`, `bin/`, `src/`, `test/`, `skills/`, `utils/` minus overlay) into gitignored `.xyz/` | ✅ per-repo | ❌ no overlay | **own** `.xyz/.relay-driver.lock` |
   188	| **Tier 2 (opt-in)**: `xyz-vendor.sh <target-repo> --with-releases` (or auto-detected via `releases.db` at root) | full core harness + RELEASES overlay (`releases_app.py`, `releases_cycle.py`, `releases-merge-resolve.sh`, `release-lanes.sh`, `utils/timeline/`, `xyz-releases-onboard.sh`, `RELEASES-DB-FAQS.md`) | ✅ per-repo | ✅ opt-in overlay | **own** `.xyz/.relay-driver.lock` |
   189	
   190	Updating a vendored copy (`xyz-sync.sh update`, or re-running `xyz-vendor.sh` over an existing
   191	`.xyz/`) replaces the harness **code** and preserves the per-repo state above — `relay-system/`,
   192	`.tick/`, `.relay-driver.lock`, and the `XYZ.json*` telemetry ride across the rebuild (GH-312).
   193	Note that RELEASES ledger runtime state (`releases.db`, `releases.sql`,
   194	`RELEASES-PREVIEW.html`) lives at the target repository root, outside `.xyz/`, while `.xyz/`-resident
   195	runtime state is preserved across swaps. This matters because `.xyz/` is gitignored: state lost there
   196	is unrecoverable, with no reflog or stash behind it. A new runtime artifact under `.xyz/` must be added
   197	to the preserve list in `xyz-vendor.sh`'s `materialize_vendor()`, or the next update will delete it.
   198	
   199	So: **`xyz-vendor.sh` (not `install.sh`) is the path to concurrent per-repo relays.** Once a repo has
   200	`.xyz/`, `find-harness.sh` prefers it automatically (env → `.xyz/` → current repo → script-relative → config → search), and
   201	`find-harness.sh --check` **warns** when you're in a foreign repo with no `.xyz/` (using the shared
   202	harness) and points you at the vendor command. Two vendored repos each run `relay-drive.sh` from their
   203	own `.xyz/relay-automation/`, holding independent locks — no contention. (Editing the central harness
   204	clone also can't disturb a vendored run, since it uses its own pinned `.xyz/` copy.)
   205	
   206	## Per-repo persistence (don't cache a path)
   207	
   208	Once a target repo has used relay-xyz once, don't leave behind a machine-specific breadcrumb so the
   209	next session skips the "run `find-harness.sh` first" gate above. The only two persistence channels
   210	Claude Code **auto-loads** are:
   211	
   212	- **The target repo's memory** — seed a line the first time a run succeeds there, e.g. "this repo uses
   213	  relay-xyz; run `find-harness.sh --check` first."
   214	- **That repo's own `CLAUDE.md`, by skill name** — a pointer such as "for automated relays, use the
   215	  `relay-xyz` skill" (not a path).
   216	
   217	Either breadcrumb must be a **portable pointer** — the skill name or the `find-harness.sh` command —
   218	**never a cached absolute path and never a bare root pointer file** dropped into the target repo. A
   219	bare file isn't auto-loaded (a skimming agent skips it exactly like it skips this doc's own body), it's
   220	machine-specific (breaks on the next clone or device), a stale cached path is *worse* than no path at
   221	all, and cleaning one up later has cross-repo blast radius. **relay-xyz never auto-installs any file
   222	into a target repo** — only `install.sh` writes anything, and it writes only into `~/.claude/skills/`
   223	on the machine running it, never into the target repo itself.
   224	
   225	## The two automated paths
   226	
   227	**Role split (GH-221): Claude Code is the orchestrator/reviewer here, not a default builder.** The
   228	Claude Code session driving `relay-drive.sh`/`marathon-drive.sh` plans, dispatches, and reviews/verifies
   229	turns — it does not spawn itself as the headless build lane. **Agy CLI and Codex CLI are the builders**:
   230	the two cost-blind (subscription-billed, not per-call API) headless turn-takers `--agent-cmd` /
   231	`--builder` default to. **Claude CLI (subscription or API, according to authentication) is not a builder by default** —
   232	`--builder claude` / a `claude-turn.sh` shim stay fully supported, but only as an explicit,
   233	usage-acknowledged choice the *user* makes locally, never something a session reaches for on its own
   234	reasoning that it's "just another supported turn-taker." If a task needs a headless build lane and
   235	neither agy nor codex is on PATH, stop and ask — don't default to spawning a headless Claude CLI turn.
   236	
   237	| Path | One session? | Models | Driver |
   238	|---|---|---|---|
   239	| **A. Headless single-session** | yes — Claude drives both roles | Codex / agy as co-equal headless workers | `relay-drive.sh` + a turn-taker shim |
   240	| **B. Hands-free poll** | no — two live Claude windows | all-Claude | `poll.sh` under `/loop` in each window |
   241	
   242	Path A is the marquee flow — what "have Codex or agy review this for me" means. Path B is the all-Claude
   243	self-serializing loop: no human nudge, no second model.
   244	
   245	### Path A — headless single-session (relay-drive.sh + a shim)
   246	
   247	`relay-drive.sh` is the **supervisor** (round cap, no-progress escalation, reads the file's `STATUS:`
   248	as the terminal signal). The **turn-taker** is `--agent-cmd` — a shipped shim (`codex-turn.sh` or
   249	`agy-turn.sh`) that owns the safety boundary: path-allowlist, commit-bypass guard, **no push**.
   250	Whose-turn is a `tick` relay task, handed off with `tick release --to`.
   251	
   252	End-to-end headless review of an artifact (run after Preconditions — `$TICK` and `$HARNESS` set, CWD
   253	is the harness clone). Choose either worker. The examples below pass `ALLOW_PATHS="$ARTIFACT"`, which
   254	fits a **build/fix** turn; for a pure **review** turn set `ALLOW_PATHS=""` (relay file only) so the
   255	reviewer reports instead of editing — see the env table's `ALLOW_PATHS` row (note that fixed log paths break concurrent same-machine runs; prefer the shims' per-PID default or use per-PID `$$` variables):
   256	
   257	#### The one-line form (GH-346 Phase 3a) — name the reviewer, skip the table
   258	
   259	If a profile exists for the model you want, the whole env block below collapses to one call:
   260	
   261	```bash
   262	eval "$(relay-automation/resolve-profile.sh 'glm 5.3 max' --env)"
   263	ALLOW_PATHS="" relay-automation/relay-drive.sh \
   264	  --relay-file "$RELAY" --relay-task "$TASK" \
   265	  --agent-cmd "$RELAY_AGENT_CMD" --reviewer "$RELAY_REVIEWER" --review-once
   266	```
   267	
   268	`--env` emits the lane's `*_AGENT`, `*_MODEL`, its gateway variable, `*_REASONING_EFFORT`,
   269	`*_FLAGS`, plus `RELAY_AGENT_CMD`, `$HARNESS` and `$TICK`. Profiles live in the `profiles` block of
   270	`~/.xyz/device_config.json`:
   271	
   272	```json
   273	"profiles": {
   274	  "glm 5.3 max":  { "harness": "commandcode", "gateway": "self",
   275	                    "model": "zai-org/glm-5.3", "effort": "max" },
   276	  "qwen 3.8 max": { "harness": "deepseek", "gateway": "openrouter",
   277	                    "model": "qwen/qwen3.8-max" }
   278	}
   279	```
   280	
   281	`"gateway": "self"` is for a harness that is **its own router** — Command Code resolves models from
   282	its own catalog and has no OpenRouter key or base URL, so naming a third-party router there would
   283	emit a value the shim ignores and telemetry would then record a route that never happened.
   284	
   285	Name matching is fuzzy (it reuses `resolve-model-alias.sh`), so `GLM5.3 max`, `glm 5.3 max` and
   286	`max glm 5.3` are one entry. `--list` shows every profile and flags broken ones; `--explain` says
   287	which tier answered.
   288	
   289	**This never blocks a turn.** A missing config, malformed JSON, or an unmatched name falls through
   290	to the shims' own defaults — the tables below — and says why on stderr. An explicit `*_AGENT` +
   291	`*_MODEL` already in the environment always wins and is never second-guessed.
   292	
   293	The tables below remain correct and are what a fall-through lands on. Use them when no profile
   294	exists, or when you want a one-off that is not worth naming.
   295	
   296	| Worker | Availability check | Handoff target | Env prefix | Shim | Log |
   297	|---|---|---|---|---|---|
   298	| Codex | `"$RELAY_HAS_CODEX" = 1` | `codex` | `CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log"` | `relay-automation/codex-turn.sh` | `${TMPDIR:-/tmp}/codex-turn-$$.log` |
   299	| agy | `"$RELAY_HAS_AGY" = 1` | `agy` | `AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log"` | `relay-automation/agy-turn.sh` | `${TMPDIR:-/tmp}/agy-turn-$$.log` |
   300	| Commandcode | `"$RELAY_HAS_COMMANDCODE" = 1` | `commandcode` | `COMMANDCODE_AGENT=commandcode ALLOW_PATHS="$ARTIFACT" COMMANDCODE_LOG="${TMPDIR:-/tmp}/commandcode-turn-$$.log"` | `relay-automation/commandcode-turn.sh` | `${TMPDIR:-/tmp}/commandcode-turn-$$.log` |
   301	| DeepSeek | `"$RELAY_HAS_DEEPSEEK" = 1` | `deepseek` | `DEEPSEEK_AGENT=deepseek ALLOW_PATHS="$ARTIFACT" DEEPSEEK_LOG="${TMPDIR:-/tmp}/deepseek-turn-$$.log"` | `relay-automation/deepseek-turn.sh` | `${TMPDIR:-/tmp}/deepseek-turn-$$.log` |
   302	
   303	**Model selection per worker** (GH-346) — the one lookup that used to mean reading each shim's
   304	source. `RELAY_HAS_*` is set by `find-harness.sh --env`; every worker below also honors
   305	`<PREFIX>_FLAGS` and `RELAY_TURN_TIMEOUT_S`:
   306	
   307	| Worker | Model env | Default | Notes |
   308	|---|---|---|---|
   309	| Codex | *(none)* | codex CLI's own | `codex-turn.sh` never passes `--model`; set it in codex's own config |
   310	| agy | `AGY_MODEL` | agy CLI's own | validated against `agy models` — an unlisted id fails fast rather than falling back |
   311	| Commandcode | `COMMANDCODE_MODEL` | `meta/muse-spark-1.2-contributor` | `cmd --list-models` for the live catalog (GLM, Qwen, DeepSeek all reachable here) |
   312	| DeepSeek | `DEEPSEEK_MODEL` | `deepseek/deepseek-v4-pro` | accepts a colloquial alias (`"deepseek v4 pro"`); also `DEEPSEEK_PROVIDER` (`openrouter`\|`deepseek`\|`alibaba`) selecting the endpoint and its key variable. An unrecognised value REFUSES the turn (it used to fall through to DeepSeek silently). `alibaba` is the Alibaba Token Plan, which serves Qwen under bare ids (`qwen3.8-max`, not `qwen/...`) and reads its key from `ALIBABA_TOKEN_PLAN_API_KEY` or, failing that, the file named by `ALIBABA_TOKEN_PLAN_API_KEY_FILE`. |
   313	| Aider | `AIDER_MODEL` | `openrouter/anthropic/claude-sonnet-5`, or `openai/agents-a1` when `AIDER_OPENAI_API_BASE` is set | force `AIDER_FLAGS=--edit-format diff` on GLM |
   314	| Claude | `CLAUDE_MODEL` | `claude-sonnet-4-6` | Explicit operator choice, never a session default; see [subscription setup](https://github.com/HiQS-Labs/XYZ-forge/blob/development/relay-automation/README.md#claude-subscription-mode) |
   315	| Pi | `PI_MODEL` | **none — required** | refuses to guess (GH-295) |
   316	
   317	Codex example:
   318	
   319	```bash
   320	# 0. The reviewer you want must be on PATH (set by the locator).
   321	[ "$RELAY_HAS_CODEX" = 1 ] || { echo "codex not on PATH — use agy or Path B"; exit 1; }
   322	
   323	# 1. Have a relay thread with an embedded "▶ TAKE YOUR TURN" block.
   324	#    Reuse one under relay-system/<date>/, or scaffold a fresh thread with /relay first.
   325	RELAY=relay-system/<date>/<slug>.md
   326	ARTIFACT=<repo-relative-path-the-turn-reviews>     # e.g. skills/1-hourly/relay-xyz/SKILL.md
   327	TASK="RELAY-$(basename "$RELAY" .md)"              # use a per-relay id, not literal RELAY-TURN
   328	
   329	# 2. Seed the relay task and hand the first turn to the Codex agent.
   330	"$TICK" log     task.created "$TASK" --agent claude-a
   331	"$TICK" claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
   332	"$TICK" release "$TASK" --agent claude-a --to codex
   333	
   334	# 3. Drive it. The shim dispatches ONLY when the token's actor == CODEX_AGENT.
   335	CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
   336	relay-automation/relay-drive.sh \
   337	  --relay-file "$RELAY" \
   338	  --relay-task "$TASK" \
   339	  --agent-cmd  relay-automation/codex-turn.sh \
   340	  --reviewer   "$CODEX_AGENT" \
   341	  --round-cap  4
   342	```
   343	
   344	agy example:
   345	
   346	```bash
   347	[ "$RELAY_HAS_AGY" = 1 ] || { echo "agy not on PATH — use codex or Path B"; exit 1; }
   348	
   349	RELAY=relay-system/<date>/<slug>.md
   350	ARTIFACT=<repo-relative-path-the-turn-reviews>
   351	TASK="RELAY-$(basename "$RELAY" .md)"
   352	
   353	"$TICK" log     task.created "$TASK" --agent claude-a
   354	"$TICK" claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
   355	"$TICK" release "$TASK" --agent claude-a --to agy
   356	
   357	AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
   358	relay-automation/relay-drive.sh \
   359	  --relay-file "$RELAY" \
   360	  --relay-task "$TASK" \
   361	  --agent-cmd  relay-automation/agy-turn.sh \
   362	  --reviewer   "$AGY_AGENT" \
   363	  --round-cap  4
   364	```
   365	
   366	Commandcode example:
   367	
   368	```bash
   369	[ -x "$(command -v cmd 2>/dev/null)" ] || { echo "cmd not on PATH — use codex or agy"; exit 1; }
   370	
   371	RELAY=relay-system/<date>/<slug>.md
   372	ARTIFACT=<repo-relative-path-the-turn-reviews>
   373	TASK="RELAY-$(basename "$RELAY" .md)"
   374	
   375	"$TICK" log     task.created "$TASK" --agent claude-a
   376	"$TICK" claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
   377	"$TICK" release "$TASK" --agent claude-a --to commandcode
   378	
   379	COMMANDCODE_AGENT=commandcode ALLOW_PATHS="$ARTIFACT" COMMANDCODE_LOG="${TMPDIR:-/tmp}/commandcode-turn-$$.log" \
   380	relay-automation/relay-drive.sh \
   381	  --relay-file "$RELAY" \
   382	  --relay-task "$TASK" \
   383	  --agent-cmd  relay-automation/commandcode-turn.sh \
   384	  --reviewer   "$COMMANDCODE_AGENT" \
   385	  --round-cap  4
   386	```
   387	
   388	`$TICK` is absolute, so either worker path still works if CWD drifts.
   389	
   390	**Important — run the shim OUTSIDE the Bash sandbox.** When *you* (Claude Code) drive this, the
   391	`codex` / `agy` subprocess needs the OS keychain + outbound network to authenticate. Claude Code's
   392	Bash sandbox blocks both: `codex` errors (looks like a keychain/login fault, but it's the sandbox),
   393	and `agy -p` **fails silently — exit 0, empty output** (the shim catches this and exits 5, but only
   394	un-sandboxed). Run these Bash calls with `dangerouslyDisableSandbox: true`. (Memory:
   395	`codex-cli-needs-sandbox-disabled`, `agy-antigravity-cli`.)
   396	
   397	**Important — never hand-roll backgrounding for a driven run (GH-183/187 dogfood, 2026-07-10).** A
   398	multi-round `marathon-drive.sh`/`relay-drive.sh` run can easily exceed the calling tool's own
   399	foreground timeout. Always use that tool's **native** background-execution mechanism (e.g. Claude
   400	Code's `run_in_background`), never a manual `nohup ... & disown` — a disown can itself fail (exit
   401	1) while the backgrounded job survives anyway, undetected, and races a subsequent re-fire against
   402	the same repo/worktree state (observed: a stray `git worktree` plus a `tick` token stuck in
   403	`claimed`, never handed off). If a driver call *does* get killed mid-turn: `git worktree remove
   404	--force <path>` (see `git worktree list` for stragglers) then `tick reap <agent> --by <caller>
   405	--task <task>` to clear the stuck claim — `reap` is the sanctioned recovery (logs an auditable
   406	`task.released` event), not a hand-written `tick release`.
   407	
   408	#### Inspecting token state, and a one-shot review
   409	
   410	- **Inspect whose-turn mid-drive:** `"$TICK" info <task>` prints the token's `status` / `claimer` /
   411	  `handoff-to` (this is what the driver reads internally). The verb is **`info`**, not `status` —
   412	  `tick status` is not a verb and errors with `unknown verb: status`.
   413	- **Single deliberate review turn:** pass `--review-once` to `relay-drive.sh` to drive exactly ONE
   414	  turn and classify the outcome by exit code, so a correct "changes requested" review is not mistaken
   415	  for a stall:
   416	
   417	  | Exit | Meaning |
   418	  |---|---|
   419	  | `0` | reviewer Approved/Closed |
   420	  | `5` | reviewer completed a turn and handed back **without** approving ("changes requested") — a *successful* single review, not a stall |
   421	  | `3` | genuine stall — the reviewer did nothing (token + STATUS unchanged) |
   422	  | `4` | escalated by design (`STATUS: Escalated`), round cap, or a close mismatch |
   423	
   424	  Without `--review-once` a non-approval handback advances the multi-round loop instead (the producer
   425	  takes the next turn); use `--review-once` when you want exactly one review and a clean exit code.
   426	
   427	- **Review an external / cross-repo artifact (a PR or diff from another repo):** pass
   428	  `--artifact-file <path>` to `relay-drive.sh` to seed it READ-ONLY into the isolated worktree at
   429	  `.relay-artifacts/<basename>` — the reviewer reads it there without it being committed into the
   430	  target repo (a reviewer edit fails the turn). To scaffold the thread for such a review, use
   431	  `relay-automation/new-relay.sh --title T --reviewer <agent> --artifact-file <path>` (add `--embed`
   432	  to inline the artifact in a fence-collision-safe block instead of referencing the seed path). The
   433	  scaffolder only writes a thread; you still drive it with `relay-drive.sh` per the paths above.
   434	
   435	- **Drive a full relay/build that lands in a DIFFERENT repo (`--target-root`):** the *normal* case —
   436	  the harness lives in `XYZ-forge`, the code you want built or reviewed-and-committed lives in
   437	  your own repo. Pass `--target-root <repo>` to `relay-drive.sh` (or `marathon-drive.sh`): the relay
   438	  thread + `tick` token stay in the harness clone, while the worktree base, `ALLOW_PATHS` resolution,
   439	  and the file-scoped commit all route to `<repo>` (the harness clone is never touched). `find-harness.sh`
   440	  (Preconditions) solves discovery of *the harness*; `--target-root` is the inverse — pointing the
   441	  harness **at** your repo. **A same-repo lane must OMIT `--target-root`** — passing it for the harness's
   442	  own repo trips a relay-file off-lane false-positive (exit 6; see [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)).
   443	
   444	- **One-shot cross-repo review without a relay loop (`CONSULT_ROOT`):** to apply a lens to a file in a
   445	  foreign repo with Codex/agy headless — no Producer↔Reviewer loop, advisory only — reach for
   446	  `consult.sh` with `CONSULT_ROOT` set to that repo. Advisors run in a throwaway worktree of
   447	  `CONSULT_ROOT`, so they read it but can never mutate it:
   448	  ```bash
   449	  CONSULT_ROOT=/path/to/your/repo \
   450	  relay-automation/consult.sh --models codex \
   451	    --prompt-file /abs/path/Q.md --out "$TMPDIR/consult"
   452	  ```
   453	  **`$TMPDIR` gotcha:** when a prompt/artifact is *authored* in a sandboxed step and *consumed*
   454	  un-sandboxed (or vice-versa), `$TMPDIR` resolves to a different dir and the path 404s
   455	  (`prompt file not found`). Pass prompts/artifacts by **absolute path**, never a bare `$TMPDIR`-relative one.
   456	
   457	### Path B — hands-free poll (all-Claude, two windows)
   458	
   459	In each Claude window, run a guarded `/loop` that uses `poll.sh` as the gate, then take the turn from
   460	the relay file's embedded instructions. The token *is* the lock — a window acts only when the token is
   461	claimable by its agent **and** the artifact scope is clean.
   462	
   463	Each window is its own shell, so run Preconditions in each one (or `cd` into the `find-harness.sh
   464	--root` output) before the loop — the `relay-automation/` paths below are relative to `$HARNESS`.
   465	
   466	```
   467	# In each window (set --agent to that window's id). --claude-agents lists EVERY Claude id in
   468	# the relay so the poller knows whose turns can self-poll vs. which need a cross-model nudge:
   469	/loop 60s run relay-automation/poll.sh --mode relay --agent <claude-a|claude-b> \
   470	  --claude-agents "claude-a,claude-b" \
   471	  --relay-file relay-system/<date>/<slug>.md --artifact <path> \
   472	  --deadline "$(date -v+30M +%s)" --dry-run ;\
   473	  if it prints "DECISION: run-runner", take your turn on that relay file per its embedded \
   474	  instructions (review/produce, append your block, `tick release RELAY-TURN --to <other>` or \
   475	  `tick done` on approve, commit); on "DECISION: stop" CronList+CronDelete this job; else do nothing.
   476	```
   477	
   478	`--claude-agents` is load-bearing: a turn belonging to an agent **not** in this list yields
   479	`DECISION: nudge-cross-model` (a one-line "take your turn" for the human to relay to a non-Claude
   480	window), not `idle`. List both Claude ids and Path B stays fully hands-free; omit one and that
   481	window's turns surface as a manual nudge. `60s` keeps the prompt cache warm; the lock/heartbeat is the
   482	real correctness guard, not the timer. Always set a `--deadline` so the loop self-closes — cron jobs
   483	are per-session, and you can't stop another window's loop from yours. `poll.sh` exits `10` on a closed
   484	relay (`STATUS: Approved|Closed`); see `/relay` → "Self-closing loops". Optionally run **one** extra
   485	window with `--watchdog-authority` (longer interval, e.g. `120s`) so a stalled turn escalates exactly
   486	once.
   487	
   488	**Worked recipe — "Dueling Claudes":** for the full copy-paste two-window setup (Reporter↔Maintainer,
   489	same machine, with the one human go-gate before commit), see
   490	[relay-automation/DUELING-CLAUDES.md](https://github.com/HiQS-Labs/XYZ-forge/blob/development/relay-automation/DUELING-CLAUDES.md). It carries the exact
   491	`/loop` strings, the fresh-token-per-run rule, and the foreign-CWD `tick` pitfalls for Path B.
   492	
   493	### Path B cadence — fixed interval (today) vs adaptive (GH-33)
   494	
   495	The `/loop 60s` above is a **fixed** cadence: it wakes every 60s and usually decides "do nothing,"
   496	burning a re-invocation per idle minute. **Adaptive cadence** lets `poll.sh` suggest *when* to wake
   497	next from its own `DECISION`:
   498	
   499	- `poll.sh --emit-delay` adds a `DELAY: <seconds> (<reason>)` line (act-now → 0, idle backoff → 300,
   500	  dirty → 30, waiting-for-peer-commit → 90, cross-model → 120; clamped to `--deadline`). Additive —
   501	  the `DECISION:` line is unchanged, so the fixed `/loop 60s` recipe above still works untouched.
   502	- `relay-automation/relay-loop.sh` wraps it. **Default** = one tick that prints `NEXT-POLL: <seconds>`
   503	  and exits `poll.sh`'s code (10 = stop) — the unit a `/loop` **dynamic-mode** tick reads to schedule
   504	  its next wake (via `ScheduleWakeup`), so an idle relay backs off and a live one stays responsive.
   505	- The cadence is **not** Claude-locked: `relay-loop.sh --sleep-loop` self-paces in pure bash
   506	  (tick → sleep `DELAY` → repeat until stop), and the `NEXT-POLL`/`DELAY` output is plain text any
   507	  scheduler (cron, systemd timer) can consume. `/loop` dynamic mode is one option, not a dependency.
   508	
   509	Dynamic-mode `/loop` (self-paced) replacement for the fixed recipe — read `NEXT-POLL`, sleep that long:
   510	
   511	```
   512	/loop run relay-automation/relay-loop.sh --mode relay --agent <claude-a|claude-b> \
   513	  --claude-agents "claude-a,claude-b" --relay-file relay-system/<date>/<slug>.md \
   514	  --artifact <path> --deadline "$(date -v+30M +%s)" --dry-run ;\
   515	  act on "DECISION: run-runner" as above; on "DECISION: stop" CronDelete this job; \
   516	  otherwise ScheduleWakeup after the printed "NEXT-POLL:" seconds.
   517	```
   518	
   519	## Turn-taker shims & their env
   520	
   521	Both shims are thin dispatchers over `relay-turn-lib.sh` (the model-agnostic containment core), so
   522	they share the same env shape:
   523	
   524	| Env | `codex-turn.sh` | `agy-turn.sh` | Meaning |
   525	|---|---|---|---|
   526	| dispatch gate | `CODEX_AGENT` | `AGY_AGENT` | NO-OPS unless `RELAY_AGENT == this` |
   527	| extra writable paths | `ALLOW_PATHS` | `ALLOW_PATHS` | comma-sep git paths the turn may change (the relay file is always allowed). **For a review turn, set `ALLOW_PATHS=""` — relay file only.** If the artifact is writable, the reviewer tends to start *editing and building* it instead of reviewing (it can read any path regardless), which over-runs the turn cap (exit 7) — observed 2026-06-26. A build/fix turn is the only case that needs the artifact in `ALLOW_PATHS`. **A whole DIRECTORY is a valid lane entry** (GH-90): an entry that names an existing directory, or any entry written with a **trailing slash** (`skills/1-hourly/standup/fixtures/` — the only form that works when the turn is about to *create* the directory), makes that directory and everything beneath it writable. Without either signal the entry is a FILE path, and a file entry is never a bare prefix — GH-59: `green` must not reach `greenfield/output.txt`. Before GH-90 a bare directory entry was unmatchable by construction and the turn failed as a *containment violation*, which reads as a misbehaving builder rather than a malformed lane spec; the off-lane report now names that mistake explicitly. |
   528	| peer id | `RELAY_PEER` | `RELAY_PEER` | so the turn hands off `--to <peer>` (else "the other agent") |
   529	| binary | `CODEX_BIN` | `AGY_BIN` | override the CLI path |
   530	| autonomy | `CODEX_FLAGS` (default `-s workspace-write`) | `AGY_MODEL` / `AGY_FLAGS` | the codex sandbox/approval flags or the agy model |
   531	| transcript | `CODEX_LOG` | `AGY_LOG` | where the CLI transcript lands (default a `$TMPDIR` file) |
   532	| turn ceiling | `RELAY_TURN_TIMEOUT_S` | `RELAY_TURN_TIMEOUT_S` | per-turn wall-clock cap (Aider default: 900s in both runtime shims; hung CLI → exit 7) |
   533	
   534	If a fresh device's `codex` still blocks writes, escalate autonomy:
   535	`CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox'` (or `-c approval_policy=never`).
   536	For agy, the common failure is different: sandboxed runs can exit `0` with empty
   537	output, so run the lane sandbox-OFF before concluding the worker is broken.
   538	
   539	## Exit codes
   540	
   541	- **`relay-drive.sh`**: `0` closed Approved/Closed · `3` no-progress (token actor didn't move) ·
   542	  `4` round-cap / closed-not-approved · `2` usage.
   543	- **shims** (`codex-turn.sh` / `agy-turn.sh`): `0` acted or deferred · `5` CLI failed (or agy empty
   544	  output) · `6` off-allowlist edit reverted (or committed mid-turn → reset) · `7` timeout-killed · `2` usage.
   545	- **`poll.sh`**: `10` relay closed (stop the loop); on stdout one of
   546	  `DECISION: run-runner | run-watchdog | nudge-cross-model | stop | idle`
   547	  (`nudge-cross-model` = turn belongs to an agent not in `--claude-agents`; relay it as a manual nudge).
   548	
   549	## Safety boundary (what the shim guarantees)
   550	
   551	The shim is the containment contract, so an unattended turn can't run away: **path-allowlist**
   552	(anything off `RELAY_FILE` + `ALLOW_PATHS` is reverted, exit 6), **commit-bypass guard** (if the CLI
   553	commits mid-turn, the shim resets and re-commits file-scoped), and **no push** (turns commit locally
   554	only — `git push` yourself when ready). `.tick/` is gitignored and per-device, so this is single-clone
   555	coordination, not cross-machine.
   556	
   557	**Never hand-edit a clone while a driven turn is in flight there (GH-141).** `rtl_before()` snapshots
   558	the dirty set once, at turn start. A second session's edit landing *during* the turn window produces a
   559	porcelain entry with no match in that snapshot — **byte-identical to the agent's own off-lane
   560	self-escape** — so `rtl_check()` reverts it in the real tree. This is not a bug that can be fixed by
   561	detection: preserving newly-dirty non-allowlisted paths would disable the documented GH-22
   562	self-escape backstop. Observed live twice (2026-07-05, 2026-07-18); the second incident silently
   563	deleted an untracked doc and reverted a tracked one mid-session. Since 2026-07-18 the pre-revert
   564	content is copied to `.tick/orphan-backups/<utc>-<pid>/<path>` first, so a wrongly-caught edit is
   565	**recoverable** — but the revert still happens. Wait for the turn, or work in a separate worktree.
   566	
   567	**Worktree isolation is ON by default for driven runs.** `relay-drive.sh` exports
   568	`RELAY_WORKTREE_ISOLATION=1`, so each turn-taker runs in a throwaway `git worktree` of `ROOT@HEAD` —
   569	an off-task model's stray *creations/renames* (not just tracked edits) can't reach the real tree,
   570	closing the gap where the allowlist only reverted named tracked files. Opt out per run with
   571	`RELAY_WORKTREE_ISOLATION=0`; direct/attended shim use keeps the leaf default OFF. Also: `--agent-cmd`
   572	runs a bare executable path directly, so an **absolute path with spaces** (a clone under
   573	`…/GH Repos/…`) is safe — no quoting needed.
   574	
   575	## Verify the harness is green before a real run
   576	
   577	These are anchored on `$HARNESS` (set by Preconditions) so they resolve whatever your CWD is — don't
   578	drop the `$HARNESS/` prefix or they'll 404 from a foreign session:
   579	
   580	```bash
   581	bash "$HARNESS/validate.sh"            # the tick/automation suite
   582	bash "$HARNESS/test/codex-turn.sh"     # before a Codex run
   583	bash "$HARNESS/test/agy-turn.sh"       # before an agy run
   584	```
   585	
   586	**If your turn's `--artifact`/`ALLOW_PATHS` includes anything under `relay-automation/`, re-run
   587	`bash "$HARNESS/skills/1-hourly/relay-automation/make-pkg.sh"` after the turn lands, before trusting a green
   588	`validate.sh`.** `relay-pkg-freshness.sh` catches a stale vendored `relay-pkg.tar.gz`, but it reads
   589	as one more red line in a 100+-test suite rather than a real, fix-needed gap — this has bitten two
   590	separate passes on `relay-automation/agy-turn.sh`/`consult.sh` (GH-178's original B1/A4 pass on
   591	2026-07-08, and the GH-183/187 fix on 2026-07-10). Don't wait to discover it after the fact.
   592	
   593	Run the shim test matching the worker you'll drive (both are first-class). Run these un-sandboxed —
   594	`mktemp`/network under the Bash sandbox can fail them for reasons unrelated to the code.
   595	
   596	## Relationship to the other skills
   597	
   598	- **`/relay`** — portable, dependency-free. Owns the thread template, turn block formats, evidence
   599	  contract, and guardrails. **Use it to scaffold the thread**; relay-xyz never redefines the protocol,
   600	  only runs it.
   601	- **`/xyz`** — concurrent, non-overlapping path-scoped lanes (parallel *builds*), also `tick`-backed.
   602	  A relay is sequential review (one writer, turn-based); `xyz` is parallel construction. Different
   603	  shapes.
   604	- **`consult.sh`** — `relay-automation/consult.sh` asks one question of Codex *and* agy in parallel,
   605	  captures both transcripts, leaves synthesis to you. Advisory-only, read-only, **not** a relay turn —
   606	  reach for it when you want a second opinion without a review loop.
   607	
   608	## Framing
   609	
   610	Open with a human sentence ("Driving a headless Codex or agy review of `<artifact>` — round cap 4…") and
   611	close with the result + exit code. The structured thread lives in the relay file; the operator gets a
   612	sentence and a verdict, not a wall of transcript.
   613	
   614	## Review Scope & Commensurate Complexity Standard
   615	
   616	Reviewers (Codex, agy, Claude, etc.) and authors must adhere to a strict standard of **commensurate complexity**:
   617	
   618	1. **Surgical, DRY, Safe, Secure, and Stable within Reason:** Reviews must evaluate correctness, safety, and invariants against the stated requirements without encouraging speculative over-engineering.
   619	2. **Commensurate Machinery & Tests:** Defensive handling, recovery mechanisms, and test footprints must remain strictly commensurate with the scale and role of the core code. An 80-line sync script or local tool must not become entangled with multi-layered enterprise fail-safes, distributed locks, journaled recovery, or bespoke fuzzing/scanning runtimes unless the operator explicitly specifies it.
   620	3. **Operational Envelope Grounding:** Reviewers must grade against the explicitly declared operational envelope (e.g. local developer CLI, single-repo task) rather than unrequested enterprise multi-tenant threat models.
   621	4. **Challenge Unwarranted Complexity:** Reviewers should actively challenge speculative abstractions, parallel subsystems, and overbuilding, acting as a filter *against* bloat rather than an engine of scope creep.
   622	5. **Measure, read-only (GH-681):** a headless Reviewer MAY run narrow, non-mutating probes and queries against the seeded artifact to measure a claim — output and temp files under `.relay-scratch/` or `$TMPDIR` only, with `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"` first, and the command, exit status and decisive output quoted in the finding (scratch is discarded after the turn). It may NOT run `validate.sh`, `test/*.sh`, pytest, or executable fixtures in the relay worktree — those belong in a disposable full clone (`AGENTS.md`); a claim only measurable that way is graded `[Unverified — needs clone run]`. Containment is unchanged. The canonical wording is the reviewer note in `relay-automation/relay-turn-lib.sh` (`rtl_turn_prompt`); the marathon reviewer brief (`utils/py/marathon_drive.py`, step 4b) already allows `$TMPDIR` probes.
   623	6. **Generalizations carry a falsifier (GH-681):** a finding that asks for a behaviour change is a generalization unless the Reviewer can paste the concrete input — a row, a value, a `file:line` — that fails under the current code. Every `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`, `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Producer may disposition a request lacking these as `Declined — unproven generalization`. Protocol rule, not a mechanical check; canonical wording in `relay-automation/new-relay.sh` (Reviewer bullet), mirrored in `skills/1-hourly/relay/SKILL.md` and the marathon brief (step 4c). Origin: the gh673 final QA relay, where a Round-1 `[Blocker]` generalized one late-error observation into a rule that blanks every issue on real data, and the same seat `[Pass]`ed it next round.
   624	7. **No new tests where the repo forbids them (XYZ-forge, GH-831):** there, a new `test/` suite, a new
   625	   `validate.sh` TESTS entry or new gate machinery in the diff is itself a finding, and a reviewer does not
   626	   ask for one. Verification uses the existing suite that covers the change, or a manual check recorded
   627	   under `TESTS-RESULTS/` with its `provenance.jsonl`. Other repos keep their own test policy.
   628	
   629	## QA / Consult Template Formatting
   630	
   631	Since agents often scaffold relay threads manually (when the `/relay` slash command isn't used or available), it is critical to structure QA / consultation threads correctly. **Do not** write open-ended instructions like "QA this codebase against the requirements."
   632	
   633	Headless agents (Codex, agy, Aider) perform best when given **explicit questions and a defined operational envelope**. A proper QA thread must include:
   634	1. The goal, operational envelope, and files to read.
   635	2. Explicit statement of commensurate complexity and non-goals.
   636	3. A numbered list of concrete, specific questions to answer.
   637	4. Instructions on what the agent should output (e.g. file:line citations).
   638	
   639	**Example format:**
   640	```markdown
   641	---
   642	Goal: QA Phase 3 Implementation (Semantic Layer)
   643	Date: 2026-08-25
   644	NEXT: Reviewer
   645	STATUS: Open
   646	---
   647	
   648	# Context
   649	
   650	Adjudicate the implementation of Phase 3 Semantic Layer against its plan in PROJECT/2-WORKING/GH-1-firebase-ai-reports-plan.md.
   651	
   652	Operational Envelope: Local CLI tool. Tests and machinery must be commensurate with scope; do not demand unrequested enterprise multi-tenant fail-safes.
   653	
   654	Read the plan doc in full, plus the code it references:
   655	- api/src/indexer.ts
   656	- api/src/semantic.ts
   657	
   658	Questions:
   659	
   660	1. Are the requirements for soft-failing met? Does it gracefully continue if the vector index is missing or empty?
   661	2. Are limits capped properly? The plan says "findNearest capped at top-K <= 10". Is this enforced securely?
   662	3. Is the Indexer idempotent? Review `processItem` in `indexer.ts` which uses a hash check. Does this prevent unnecessary re-embedding?
   663	4. Is the implementation surgical and DRY? Flag any unnecessary layers of abstraction or unneeded machinery.
   664	
   665	Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite file:line where you disagree with a specific claim.
   666	
   667	Write your verdict below and change the STATUS to Approved/Closed if it passes.
   668	
   669	<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
   670	▶ TAKE YOUR TURN (codex)
   671	<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
   672	```
`````

Ask for Reviewer (Round 2): complete the whole-file sweep of SKILL.md above, check the attribution
evidence, and set STATUS Approved if nothing blocks a READY PR (merge readiness is not requested).

handing off to Reviewer (codex) — take your turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
