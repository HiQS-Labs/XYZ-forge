# RELAY · GH-938 (XYZ-forge) relay-xyz managed-setup docs — FINAL QA on committed diff + evidence
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Open
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
