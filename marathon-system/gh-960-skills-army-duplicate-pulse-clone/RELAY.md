# Marathon Phase gh-960-skills-army-duplicate-pulse-clone
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-960-skills-army-duplicate-pulse-clone

- Generated: 2026-10-16T03:54:04Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/PROJECT/2-WORKING/GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify (development @ 6055afca2)
- Suggested branch: `marathon/gh-960-skills-army-duplicate-pulse-clone-2026-10-16` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash ci-local.sh`

- Artifacts: skills/3-weekly/skills-army-hq/scripts/sync.py,skills/3-weekly/skills-army-hq/references/recovery.md
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 419 LOC across 2 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/PROJECT/2-WORKING/GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE.md` (0 checkbox(es) found across the WHOLE document — the doc has no `## Acceptance` section, so this list may include phase checklists). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #960 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/PROJECT/2-WORKING/GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `skills/3-weekly/skills-army-hq/scripts/sync.py,skills/3-weekly/skills-army-hq/references/recovery.md` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash ci-local.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-960-skills-army-duplicate-pulse-clone RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact skills/3-weekly/skills-army-hq/scripts/sync.py,skills/3-weekly/skills-army-hq/references/recovery.md \
  --pre-advance-cmd 'bash ci-local.sh' \
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

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): skills/3-weekly/skills-army-hq/scripts/sync.py,skills/3-weekly/skills-army-hq/references/recovery.md
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/bin/tick claim MARATHON-GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE-TURN --agent agy --paths "marathon-system/gh-960-skills-army-duplicate-pulse-clone/RELAY.md,skills/3-weekly/skills-army-hq/scripts/sync.py,skills/3-weekly/skills-army-hq/references/recovery.md"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/bin/tick ping MARATHON-GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/bin/tick release MARATHON-GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-960-skills-army-duplicate-pulse-clone/RELAY.md and skills/3-weekly/skills-army-hq/scripts/sync.py,skills/3-weekly/skills-army-hq/references/recovery.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/3-weekly/skills-army-hq/scripts/sync.py,skills/3-weekly/skills-army-hq/references/recovery.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/bin/tick release MARATHON-GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/bin/tick done MARATHON-GH-960-SKILLS-ARMY-DUPLICATE-PULSE-CLONE-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify/bin/tick
   Edit ONLY marathon-system/gh-960-skills-army-duplicate-pulse-clone/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · agy

- **Files touched:**
  - `skills/3-weekly/skills-army-hq/scripts/sync.py`
  - `skills/3-weekly/skills-army-hq/references/recovery.md`
  - `marathon-system/gh-960-skills-army-duplicate-pulse-clone/RELAY.md`
- **Key decisions & implementation (GH-960):**
  - Added read-only Git Pulse clone health checks in `sync.py` (`repo_health`, invoked on normal preview, `--status`, and `--apply` runs without network calls or filesystem writes):
    - Resolves `sync_repo_dir` from `${GIT_PULSE_CONFIG_DIR:-~/.config/git-pulse}/config.sh` (also respecting `GIT_HISTORY_CONFIG_DIR` and `HOME` overrides, expanding `$CONFIG_DIR`, `$HOME`, and `~` via `shlex.split(..., comments=True)` without executing shell code) and defaults to `$CONFIG_DIR/repo` as `git-pulse` does.
    - Emits `WARN duplicate-clone check skipped: no git-pulse config at <path>` when `config.sh` is absent instead of passing silently.
    - Compares the resolved git top-level of `sync_repo_dir` against the collection root's git top-level (`collection_repo(root)`). When they differ and share a normalized remote URL, emits `WARN DUPLICATE_PULSE_CLONE` naming both paths, stating which checkout `git-pulse` maintains and which checkout the skill links read, reporting each checkout's ahead/behind count against its last-fetched `origin`, and printing the 4-step remediation sequence.
    - Emits `WARN STALE_PULSE_COLLECTION` when the collection checkout is behind its last-fetched upstream (`behind > 0`) or when its `FETCH_HEAD` is at least 24 hours old (`PULSE_STALE_HOURS = 24`), printing the fast-forward + `catalog`/`sync` recovery steps.
    - Mirrors the 4-step remediation procedure in `skills/3-weekly/skills-army-hq/references/recovery.md` under `### Reconciling a duplicate or stale Git Pulse clone (GH-960)`.
- **Verification:**
  - `PYTHONDONTWRITEBYTECODE=1 python3 -B test/test_deploy_skills.py` -> 33 passed in 31.5s.
  - `.relay-scratch/verify_gh960.py` -> verified all 4 acceptance scenarios on temporary git repos in `$TMPDIR`: (1) two clones of one remote with `config.sh` pointing at the writer clone warns `DUPLICATE_PULSE_CLONE` with paths, ahead/behind counts, and remediation steps; (2) `config.sh` pointing at the collection root is clean; (3) missing `config.sh` reports `duplicate-clone check skipped: no git-pulse config`; (4) collection behind upstream or with `FETCH_HEAD` >= 24h warns `STALE_PULSE_COLLECTION`.
