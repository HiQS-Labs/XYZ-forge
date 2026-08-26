# Marathon Phase p1
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-P1-TURN builder=agy reviewer=codex round-cap=4 -->

## Phase Brief

# Marathon preflight packet — gh-197-vendor-tier-split

- Generated: 2026-08-26T06:12:00Z
- Mode: gh-bundle
- Sources: /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197/PROJECT/2-WORKING/GH-197-VENDOR-TIER-SPLIT.md 
- Target root: /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197 (development @ 33b20193f)
- Suggested branch: `marathon/gh-197-vendor-tier-split-2026-08-26` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- **Source issue state: CLOSED** — issue #197 is CLOSED since 2026-08-26T06:08:24Z. This is advisory: confirm the follow-up is still intended before building.
- Gate: `bash validate.sh`

- Artifacts: relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,skills/relay-xyz/SKILL.md,relay-automation/README.md,relay-automation/xyz-releases-onboard.sh,test/gh197-vendor-tier-split.sh,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/xyz-sync-check.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1793 LOC across 12 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/xyz-sync-check.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197/PROJECT/2-WORKING/GH-197-VENDOR-TIER-SPLIT.md` (its `## Acceptance` section, 10 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #197 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] `xyz-vendor.sh <target>` (no flag) lands `.xyz/` with zero overlay files; harness runnability sanity (`bin/tick`, `relay-turn-lib.sh`) still passes
- [ ] `xyz-vendor.sh <target> --with-releases` lands the full overlay incl. `RELEASES-DB-FAQS.md`
- [ ] `releases.db` at target root forces Tier 2 on re-vendor with no flag (LTVera-Pandas-shaped fixture)
- [ ] `xyz-releases-onboard.sh` happy path: legacy `RELEASES.md` → imported DB, banner prepended, `releases check` clean, commit command printed, no commit made
- [ ] Gitignore carve-out appended exactly once, only when a `*.db`-style rule exists
- [ ] Shared-tracking-URL collision → report + nonzero stop; no issue auto-filed in the target repo
- [ ] Test pins that the overlay writes nothing under `.xyz/` (GH-312)
- [ ] `VENDOR_DIRS` rationale comment names `utils`
- [ ] SKILL.md tier table + README `## Vendoring tiers` landed; SOP doc lives in `relay-automation/`
- [ ] Full gate green in a disposable clone (separate full clone, not a linked worktree — GH-564); ROADMAP synced (`releases_app.py roadmap sync`)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,skills/relay-xyz/SKILL.md,relay-automation/README.md,relay-automation/xyz-releases-onboard.sh,test/gh197-vendor-tier-split.sh,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/xyz-sync-check.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/xyz-vendor.sh,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/xyz-sync-check.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-197-vendor-tier-split RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,skills/relay-xyz/SKILL.md,relay-automation/README.md,relay-automation/xyz-releases-onboard.sh,test/gh197-vendor-tier-split.sh,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/xyz-sync-check.sh,test/_setup.sh \
  --pre-advance-cmd 'bash validate.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,skills/relay-xyz/SKILL.md,relay-automation/README.md,relay-automation/xyz-releases-onboard.sh,test/gh197-vendor-tier-split.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197/bin/tick
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197/bin/tick claim MARATHON-P1-TURN --agent agy --paths "marathon-system/p1/RELAY.md,relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,skills/relay-xyz/SKILL.md,relay-automation/README.md,relay-automation/xyz-releases-onboard.sh,test/gh197-vendor-tier-split.sh"
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197/bin/tick ping MARATHON-P1-TURN --agent agy
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197/bin/tick release MARATHON-P1-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/p1/RELAY.md and relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,skills/relay-xyz/SKILL.md,relay-automation/README.md,relay-automation/xyz-releases-onboard.sh,test/gh197-vendor-tier-split.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,skills/relay-xyz/SKILL.md,relay-automation/README.md,relay-automation/xyz-releases-onboard.sh,test/gh197-vendor-tier-split.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197/bin/tick release MARATHON-P1-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197/bin/tick done MARATHON-P1-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/26d7a714-8618-4a55-9110-200be4c389fb/scratchpad/clone-197/bin/tick
   Edit ONLY marathon-system/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · agy

Implemented the GH-197 two-tier vendoring architecture and onboarding SOP across all 6 scoped artifacts:

1. **`relay-automation/xyz-vendor.sh`**:
   - Added `--with-releases` option to the CLI argument loop and usage documentation.
   - Added sticky Tier 2 auto-detection when `releases.db` is present at the target repository root (with stdout notification).
   - Defined `RELEASES_OVERLAY` manifest and implemented deny-list removal in `materialize_vendor()` for Tier 1 default vendoring (retaining overlay and staging `RELEASES-DB-FAQS.md` for Tier 2).
   - Stamped `tier=1` or `tier=2` into `.xyz/VERSION`.
   - Updated `VENDOR_DIRS` comment to explicitly list `utils/` and document the deny-list mechanism.

2. **`relay-automation/xyz-releases-onboard.sh`** (new):
   - Mechanized the legacy `RELEASES.md` -> `releases.db` onboarding SOP (LTVera-Pandas `ad0d816`).
   - Verifies preconditions (`releases.db` absent, `RELEASES.md` present).
   - Executes `releases init` and `releases import`.
   - Audits `.gitignore` and appends `!releases.db` carve-out only when `*.db`-style ignore rules exist (appended idempotently exactly once).
   - Prepends app-managed banner comment to `RELEASES.md`.
   - Reconciles `MIG-` placeholders to GitHub issue URLs (`reconcile --map`) with shared-tracking-URL collision detection (stops with non-zero exit report, never auto-files issues).
   - Executes `releases check` for consistency.
   - Prints the exact commit command without committing.

3. **`skills/relay-xyz/SKILL.md`**:
   - Replaced install-path table with comprehensive tier table (install.sh tick-only / Tier 1 default / Tier 2 opt-in).
   - Refreshed GH-312 description clarifying that ledger state resides at the target repository root while `.xyz/`-resident state is preserved across rebuilds.

4. **`relay-automation/README.md`**:
   - Updated `Components` table row for `xyz-vendor.sh` / `xyz-sync.sh` and added `xyz-releases-onboard.sh`.
   - Added dedicated `## Vendoring tiers` section documenting Tier 1 vs Tier 2 architecture, overlay manifest, and the onboarding SOP.

5. **`test/xyz-vendor.sh`**:
   - Updated `utils/` verification to account for Tier 1 overlay removal (asserting non-overlay tools present, overlay absent, and `tier=1` in `VERSION`).

6. **`test/gh197-vendor-tier-split.sh`** (new):
   - Added comprehensive suite covering all 10 acceptance criteria: Tier 1 default, Tier 2 `--with-releases`, sticky auto-detection, GH-312 root isolation pin, onboarding happy path, gitignore carve-out, shared-tracking-URL collision detection, and re-vendor adoption preservation.
