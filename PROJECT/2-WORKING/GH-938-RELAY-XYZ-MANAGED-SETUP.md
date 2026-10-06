---
gh_issue: 938
source: https://github.com/HiQS-Labs/XYZ-forge/issues/938
title: "relay-xyz SKILL.md: First-time setup tells Skills Army-managed Macs to run install.sh"
status: active
created: 2026-10-02
updated: 2026-10-02
owner: XYZ Forge maintainers
doc_type: bugfix
branch: fix/gh938-relay-xyz-managed-setup
effort: 1
complexity: 1
risk: 1
phases: 1
non_goals:
  - No change to install.sh (managed-collection detection is deferred; see Deferred)
  - No change to find-harness.sh, Skills Army HQ scripts, or any app link
  - No new test suite or validate.sh TESTS entry (GH-831)
  - No deployment to any Mac in this PR; deployment is the post-merge checklist below
goal: >
  A machine whose relay-xyz link already resolves into a Skills Army HQ Deployed Skills collection
  is told to skip install.sh and go to the locator, so following the skill creates no unmanaged links.
---

# GH-938: relay-xyz first-time setup on Skills Army-managed Macs

## Status

| What was just completed | What's next |
|---|---|
| Intake parked (rated 40/35/50/85), recon at `5212dae4`, plan written. Codex plan QA (relay-xyz, 3 rounds): R1 FAIL (`Unchanged` stopped the checklist; fixed), R2 and R3 PASS; harness attestation refused both PASSes on mechanics (`review-body-rewritten`, then `close-mismatch`), so the receipt is content-approved but unattested: `relay-system/2026-10-02/gh938-plan-qa.codex.md`. Admitted (`--accepted-start`, In progress 🚧). SKILL.md "First-time setup" rewritten. Focused suites green with red controls; full `./validate.sh` at `204750c5`: 399/410, the 11 failures reproduce on base `5212dae4` (environment) — `TESTS-RESULTS/2026-10-02+GH-938/`.  Final Codex QA (relay-xyz): R1 FAIL (whole-file sweep impossible from packet; failure attribution under-evidenced) → full SKILL.md supplied, `failure-attribution.md` added; R2 PASS, attested (`relay-system/2026-10-02/gh938-final-qa.codex.md`). | Ready PR to `development`; after merge, the checklist below. |

## Rating — 2026-10-02: `40/35/50/85` (priority/severity/appeal/effort)

- **Severity 35:** Following the documented step on a managed Mac fails (exit 1 on live links) and can
  create app links Skills Army HQ does not own, in roots it does not target. Nothing is lost and the
  links are removable; the skill already works there. Recoverable, low reach (operator Macs).
- **Priority 40:** Operator asked for it now as the follow-on to #856's deployment. Recurrence window
  2026-09-19–10-02: #856 (adjacent: locator assumed the install.sh layout) and #938. Preceding window
  2026-09-05–18: #678 (installers replaced managed links) and #660 (deployed-skill drift). Same
  family (repo docs/installers assuming the pre-Skills-Army layout), no rising rate.
- **Appeal 50:** Neutral; no operator score given.
- **Effort 85:** One markdown section. Cheap to write; the full gate (relay-xyz is a full-gate path)
  is the main cost.

## Recon — observed at `5212dae4` (origin/development, 2026-10-02)

- `skills/1-hourly/relay-xyz/SKILL.md:65-79` ("First-time setup on a new clone or machine") tells
  every clone/machine to run `bash skills/1-hourly/relay-xyz/install.sh` and says it "replaces a
  stale/dangling symlink". No exception for managed machines.
- `skills/1-hourly/relay-xyz/install.sh:42-70`: a live link that is not this copy is refused
  (GH-678) and the script exits 1; absent roots (`~/.codex/skills`, `~/.gemini/antigravity/skills`,
  `~/.gemini/antigravity-cli/skills`) get `mkdir -p` and a new link to whichever copy ran it.
- Skills Army HQ (`skills/3-weekly/skills-army-hq/SKILL.md`): "Do not run copied `install.sh`
  files"; only `intake.py`/`sync.py` mutate the collection or app links. Deployed SOP (GH-672): app
  links point into the device's Pulse checkout `Deployed Skills/`.
- Since #856/#936, `find-harness.sh` (same folder) resolves a copied deployment via the per-device
  config `${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness` or a bounded clone search, and `--check`
  prints the command that saves the config. `SKILL.md:81-111` already documents this; the setup
  section just never routes managed machines there.
- Mac Mini observation (2026-10-02 ~6:50 PM PT, read-only): `~/.claude/skills`, `~/.agents/skills`,
  `~/.gemini/config/skills`, `~/.zcode/skills`, `~/.grok-bot/skills` → `relay-xyz` all resolve to
  `~/Documents/GitHub/rebalance-git-pulse/Deployed Skills/relay-xyz`; the three install.sh-only
  roots above have no `relay-xyz` entry; `sync.py --status` clean.
- Consumers of this file that the edit must keep true:
  - `test/find-harness.sh:40-43` — SKILL.md contains `$HOME/.claude/skills/relay-xyz/find-harness.sh`,
    and has no line that is exactly `bash skills/1-hourly/relay-xyz/find-harness.sh --check`.
  - `test/path-integrity.sh` Check B scans this file for repo-path tokens (`skills/…`, `test/…`,
    `relay-automation/…`, `bin/…` ending `.sh`/`.md`/`.tar.gz`); every token must resolve. App
    discovery paths (`~/.claude/skills/…` etc.) are blanked first.
  - `test/gh278-turn-timeout-parity.sh:60`, `test/gh346-gateway-allowlists.sh:401`,
    `test/gh681-reviewer-probe-rules.sh:94-101` grep other sections (timeouts, deepseek, reviewer
    rules); untouched by this edit.
  - `utils/ci-route.sh:67,342` and `test/ci-route.sh:176`: every relay-xyz file is a full-gate path,
    so this landing qualifies on the Large tier (full registry).
- No twin/mirror of this section: the phrase appears only in this SKILL.md, CHANGELOG history and an
  old relay thread. Deployed copies are produced by Skills Army HQ after merge, not by this PR.
- Observed: the concurrency section (now `SKILL.md` ~L250) said `install.sh` "writes only into
  `~/.claude/skills/`"; it writes five app roots. Corrected in the PR #941 review fixes.

## Plan (one phase)

1. Rewrite only the "First-time setup" section of `skills/1-hourly/relay-xyz/SKILL.md`:
   - Lead with a check: `readlink ~/.claude/skills/relay-xyz` (or the same entry in the app's skills
     root).
   - **Managed** (resolves into a `Deployed Skills/relay-xyz` folder): skip `install.sh`; Skills Army
     HQ owns the links (`sync.py`); go to the locator, run its `--check`; if no harness resolves,
     save the canonical clone with the command `--check` prints (`~/.config/xyz/harness`), or prefix
     one command with `XYZ_HARNESS=…`. No shell startup exports.
   - **Not managed** (no link, or a dangling one): keep the existing `install.sh` instruction, which
     is still correct for a maintained primary clone.
   - Keep the two `test/find-harness.sh` pins true; add no unresolvable repo-path tokens.
   Verify inline: `bash test/find-harness.sh`, `bash test/path-integrity.sh`,
   `bash test/gh681-reviewer-probe-rules.sh`, `bash test/gh346-gateway-allowlists.sh`,
   `bash test/gh278-turn-timeout-parity.sh` green; `utils/pdda/pdda.sh run` 0 errors.
2. CHANGELOG entry (PDDA rules); update this doc's Status.
3. Full gate once on the final approved commit, in a disposable full clone (relay-xyz is full-gate);
   receipt and `provenance.jsonl` under `TESTS-RESULTS/2026-10-02+GH-938/`.
4. Final Codex relay QA on the diff; ready PR to `development` with `Refs #938` (not `Closes`: #938 closes only after post-merge checklist step 4 passes on the Mac Mini) and the checklist.

## Acceptance and falsifiers

- **Wording present (falsifiable):** `grep -n 'Deployed Skills' skills/1-hourly/relay-xyz/SKILL.md`
  finds the managed-skip instruction inside the First-time setup section, before the `install.sh`
  command. Red control: the same grep on `5212dae4` finds no such line in that section.
- **Pins stay true:** `test/find-harness.sh` and `test/path-integrity.sh` pass. Red control for the
  path scan (manual, recorded): temporarily add a bogus `skills/1-hourly/relay-xyz/nope.sh` token,
  see `path-integrity.sh` fail, revert.
- **Behaviour unchanged:** no change to any `.sh`; `git diff --stat origin/development` lists only
  SKILL.md, CHANGELOG.md, this doc, the ledger dump/DB, the TESTS-RESULTS receipt and the
  `relay-system/2026-10-02/gh938-*.codex.md` review receipts.
- **Gate:** full `./validate.sh` on the final approved commit; failures attributable to this diff
  block the PR; pre-existing/environment failures are recorded as such with evidence.
- **Deployment (after merge, not this PR):** the Mini checks in the checklist below pass; #938 closes
  only after them.

## Risks and rollback

- Risk: wording breaks a grep-based suite reading this file → caught by the focused suites above and
  the full gate. Rollback: revert the PR (docs-only, Easy). Deployed copies roll back per the
  checklist's rollback step.

## Deferred

- `install.sh` managed-collection detection (skip and exit 0 when a live app link resolves into a
  collection with `.deploy-skills.json`). (The concurrency-section wording was corrected in the PR #941 review fixes.) Deferred: behaviour
  change to an installer that `test/gh678-installer-live-links.sh` pins for every skill, and the new
  path has no existing covering suite (GH-831 forbids adding one).

## Post-merge deployment checklist

Not executed by this PR. Run in order; stop at the first failure. `C` = the device's collection
(`<Pulse checkout>/Deployed Skills`); on the Mini the Pulse checkout is
`~/Documents/GitHub/rebalance-git-pulse`, on the Mac Studio `~/git-pulse-sync` (or `$XYZ_SKILLS_ROOT`).

1. **Landing.** `gh pr view <PR> -R HiQS-Labs/XYZ-forge --json state,mergeCommit` → `MERGED`; note
   `<sha>`. `gh run list -R HiQS-Labs/XYZ-forge --workflow CI --commit <sha>` → the push run
   completed `success` (the ubuntu canary is advisory; record any red). `gh run list -R
   HiQS-Labs/XYZ-forge --workflow "Wave reconciliation" --limit 5` → the `pull_request` run for this
   PR (or the next scheduled run) completed `success`; no open `hosted-reconcile-attention` issue
   for it.
2. **Choose the publisher.** Per the operator ruling recorded in CHANGELOG (GH-881), any device may
   publish, but exactly one device publishes this change. It needs a clean canonical clone on
   `development`: `git -C <clone> status -sb` shows no local commits or changes, then
   `git -C <clone> pull --ff-only`, and `git -C <clone> rev-parse HEAD` contains `<sha>`
   (`git -C <clone> merge-base --is-ancestor <sha> HEAD`). The Mini's `~/Documents/GitHub/XYZ-forge`
   does not qualify today (local relay commits, behind origin); use the Mac Studio's clone, or settle
   the Mini clone first.
3. **Publish (on the publisher).**
   - Record the prior receipt first (rollback anchor): `python3 "$C/intake.py" --root "$C" list` →
     note relay-xyz's `digest`, `repository` and `commit` (on the Mini today: `rebalance-git-pulse`
     @ `1636d8df`).
   - Preview: `python3 "$C/intake.py" --root "$C" update relay-xyz --source
     "<clone>/skills/1-hourly/relay-xyz"`. Expect `before`/`after` digests and `commit` = `<clone>`
     HEAD. `--source` is required: the Mini's receipt records the collection itself as source, which
     `intake.py` refuses (overlap). If it prints `Unchanged: relay-xyz`, the payload is already
     published: skip apply and commit, find the existing publish commit with
     `git -C <pulse> log -1 --format=%H -- "Deployed Skills/relay-xyz"` (confirm its message names
     `<sha>` or this PR; if it cannot be identified, record that on #938 instead of claiming a
     publish), and continue at step 4.
   - Apply: the same command with `--apply` before `update`. It writes a verified backup ZIP under
     `$C/backups/`.
   - Verify: `python3 "$C/intake.py" --root "$C" list` shows the relay-xyz receipt digest equal to the
     preview's `after`, `commit` = `<clone>` HEAD, `dirty: false`.
     `python3 "$C/sync.py" --root "$C" --status --canonical "<clone>"` → no errors, relay-xyz not
     `DRIFTED`.
   - Commit immediately (the Pulse writer cannot rebase a dirty tracked tree):
     `git -C <pulse> add -- "Deployed Skills/relay-xyz"` (plus `"Deployed Skills/README.md"` if the
     apply changed it), `git -C <pulse> commit -m "vendor: publish relay-xyz from XYZ-forge@<sha>
     (PR #<PR>, GH-938)"`, then push through the Pulse workflow (`git -C <pulse> push`, or the next
     Pulse cycle). `git -C <pulse> status -sb` shows nothing ahead.
4. **Mac Mini.**
   - `git -C ~/Documents/GitHub/rebalance-git-pulse status --porcelain --untracked-files=no` is
     empty, then `git -C ~/Documents/GitHub/rebalance-git-pulse pull` (or wait for its Pulse cycle);
     `git -C ~/Documents/GitHub/rebalance-git-pulse log -1 --format=%H -- "Deployed Skills/relay-xyz"`
     is the publish commit.
   - `python3 "$C/sync.py" --root "$C" --status` → `errors: []`, no relay-xyz actions or conflicts.
   - `readlink -f ~/.claude/skills/relay-xyz` → `$C/relay-xyz` (same for `~/.agents/skills`,
     `~/.gemini/config/skills`, `~/.zcode/skills`, `~/.grok-bot/skills`).
   - Deployed bytes match the merge: `gh api "repos/HiQS-Labs/XYZ-forge/contents/skills/1-hourly/relay-xyz/SKILL.md?ref=<sha>"
     -H "Accept: application/vnd.github.raw" | diff - "$C/relay-xyz/SKILL.md"` and the same for
     `find-harness.sh` → no output. `grep -n "Deployed Skills" "$C/relay-xyz/SKILL.md"` shows the new
     managed-skip line.
   - From `~`: `cd ~ && env -u XYZ_HARNESS -u XYZ_REPO_ROOT bash ~/.claude/skills/relay-xyz/find-harness.sh --check`
     → exit 0 with `via=config` or `via=search` (this also proves the #856/#936 locator reached the
     Mini). A behind-upstream warning for the clone is advisory.
   - No unmanaged links: `ls -ld ~/.codex/skills/relay-xyz ~/.gemini/antigravity/skills/relay-xyz
     ~/.gemini/antigravity-cli/skills/relay-xyz` → all "No such file or directory".
5. **Mac Studio, when online.** The same step 4 with its Pulse checkout (`~/git-pulse-sync`) and
   `C="$HOME/git-pulse-sync/Deployed Skills"` (or `$XYZ_SKILLS_ROOT`). Other Macs the same when next
   online; record which were checked.
6. **Rollback (if a check fails after publish).** On the publisher, `intake.py` update back to the
   prior receipt recorded in step 3. Check out that payload in a temporary Git clone outside `$C`
   (`intake.py` requires the source to sit inside a local Git repository): if the prior receipt's
   repository is the Pulse repo, `git clone <pulse> <tmp> && git -C <tmp> checkout <prior commit>`
   and use `--source "<tmp>/Deployed Skills/relay-xyz"`; if it is XYZ-forge,
   `git clone https://github.com/HiQS-Labs/XYZ-forge.git <tmp> && git -C <tmp> checkout <prior commit>`
   and use `--source "<tmp>/skills/1-hourly/relay-xyz"`. Preview, then `--apply`; the resulting
   `after` digest must equal the recorded prior `digest`. Commit and push as in step 3; devices pull
   and re-run step 4.
   (Alternatives in Skills Army HQ `references/recovery.md`: the verified backup ZIP or the staged
   prior folder.) If the doc itself is wrong, revert the PR on `development` through the normal lane.
7. **Close #938** only after step 4 passes on the Mini. Comment on #938 with the merge sha, CI and
   reconcile run URLs, the publish commit, and the step-4 outputs (sync status, readlink, diff,
   `--check` line).

## Merge evidence

- PR #941 merged 2026-10-03 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
