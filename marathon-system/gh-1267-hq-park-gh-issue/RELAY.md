# Marathon Phase gh-1267-hq-park-gh-issue
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-GH-1267-HQ-PARK-GH-ISSUE-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1267-hq-park-gh-issue

- Generated: 2026-11-04T00:53:20Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/PROJECT/2-WORKING/GH-1267-HQ-PARK-GH-ISSUE.md 
- Target root: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03 (development @ 98c30cff0)
- Suggested branch: `marathon/gh-1267-hq-park-gh-issue-2026-11-04` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/hq-park.sh`

- Artifacts: utils/hq/hq.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 741 LOC across 18 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/PROJECT/2-WORKING/GH-1267-HQ-PARK-GH-ISSUE.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1267](https://github.com/HiQS-Labs/XYZ-forge/issues/1267) — 4/4 criteria copied verbatim from issue #1267.*
- [ ] `bash utils/hq/hq.sh park --gh-issue <N> XYZ-forge` (preview) on an open issue with no capture prints the existing issue URL and title and the capture that would be written, whose `## Idea` contains a known non-empty substring of that issue's body, and writes nothing. Red control: on the base the same command exits 1 with `hq park: '--gh-issue' is UNRESOLVED` (the flag is swallowed as the project name; recorded).
- [ ] `bash utils/hq/hq.sh park --create --gh-issue <N> XYZ-forge` on that issue writes `PROJECT/1-INBOX/GH-<N>-*.md` whose `gh_issue:` is `<N>` and whose `## Idea` is non-empty, and exactly one ledger row with `issue_url` equal to the existing issue; and creates no GitHub issue: `gh issue list --state all --limit 1 --json number --jq '.[0].number'` is the same non-empty integer before and after (a plain `gh issue list` count is capped at 30 and proves nothing; recorded).
- [ ] The same command on an issue that already has a capture (#1263, `PROJECT/1-INBOX/GH-1263-HQ-PARK-RATING-GRAMMAR.md`; or #1258 once its PR merges) exits 1 naming the existing doc and writes nothing (recorded); the preview witness above must use a different, unregistered issue.
- [ ] `bash utils/hq/hq.sh park --title "x" XYZ-forge "fresh request"` (no `--gh-issue`) previews byte-identically to the base (both exit 0, non-empty, `diff` empty; recorded). `bash test/hq-park.sh` passes on the final commit.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/hq/hq.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/hq-park.sh`, and NOT `test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1267-hq-park-gh-issue RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/hq/hq.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh \
  --pre-advance-cmd 'bash test/hq-park.sh' \
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
1. Implement the brief by creating/editing the artifact file(s): utils/hq/hq.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick claim MARATHON-GH-1267-HQ-PARK-GH-ISSUE-TURN --agent agy --paths "marathon-system/gh-1267-hq-park-gh-issue/RELAY.md,utils/hq/hq.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick ping MARATHON-GH-1267-HQ-PARK-GH-ISSUE-TURN --agent agy
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick release MARATHON-GH-1267-HQ-PARK-GH-ISSUE-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-1267-hq-park-gh-issue/RELAY.md and utils/hq/hq.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/hq/hq.sh,skills/2-daily/hq/SKILL.md,test/ci-route.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh35-test-tiers.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-dispatch.sh,test/hq-hardening.sh,test/hq-locator.sh,test/hq-next.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick release MARATHON-GH-1267-HQ-PARK-GH-ISSUE-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick done MARATHON-GH-1267-HQ-PARK-GH-ISSUE-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick
   Edit ONLY marathon-system/gh-1267-hq-park-gh-issue/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

**Files touched:**
- `utils/hq/hq.sh`
- `skills/2-daily/hq/SKILL.md`

**Summary of changes & key decisions:**
1. **`park` argument parser (`utils/hq/hq.sh`):** Added `--gh-issue N` and `--gh-issue=N` parsing mirrored from `queue`, making `<request...>` optional (`[ "${#pargs[@]}" -ge 1 ]`) when `--gh-issue` is passed while keeping `<request...>` required (`-ge 2`) when omitted.
2. **`cmd_park` adopt branch (`utils/hq/hq.sh`):** Right after target resolution and before `title`/`slug`, Tier C, and preview:
   - Refuses non-numeric issue numbers (`rc=1`).
   - Refuses if `PROJECT/1-INBOX/GH-<N>-*.md` or `PROJECT/2-WORKING/GH-<N>-*.md` already exists in the target, naming the relative capture path (`rc=1`).
   - Refuses on Tier C (`rc=1`) so it never falls through to `gh issue create`.
   - Runs `"$HQ_GH_BIN" issue view "$issue" --json url,title,body` in `"$path"`, validates JSON and required `url`/`title` strings via `python3`, sets `src` to `url`, `title` to `${ptitle:-$fetched_title}`, `request` to the given CLI request or else the fetched `body` (allowing an empty body), and derives `slug` from `${ptitle:-$title}` (never from the fetched body).
   - Preserves fetched `num`/`src` in preview mode instead of overwriting with `<N>` placeholders, while leaving no-`--gh-issue` preview byte-identical to base.
   - In `--create` mode, skips the duplicate-issue search and `gh issue create` when `num` is already set, continuing directly into the unchanged `hq_render_capture` + `releases roadmap add` / `ROADMAP.md` registration path.
3. **Skill documentation (`skills/2-daily/hq/SKILL.md`):** Added the `hq park [--create] --gh-issue N <project> [request…]` usage bullet documenting how to adopt an existing issue.
4. **Full-file sweep (`utils/hq/hq.sh`, `skills/2-daily/hq/SKILL.md`):** Swept both files in full; guarded `--title` and `--gh-issue` shifts in `park)` when passed as a trailing flag without a value, and found no other pre-existing defects.
5. **Verification:** Verified syntax (`bash -n utils/hq/hq.sh`) and ran an isolated `$TMPDIR` probe covering preview with `--gh-issue`, `--create --gh-issue` (confirming capture frontmatter/body, pointer insertion, and zero calls to `gh issue create`), refusal on existing `1-INBOX` and `2-WORKING` captures (naming the existing doc), Tier C refusal, non-numeric refusal, and empty-body handling. Per GH-831 and the phase brief, no test files were added or modified.


### Round 1 · Reviewer · codex

**Verdict:** Changes requested

swept file: no

Reviewed the park parser, adoption branch, existing capture/ledger writer and skill documentation, plus supporting suite source. The expanded packet-wide sweep is incomplete (some large concatenated reads were truncated); this is not a whole-packet approval. No pre-existing defect is asserted from the incomplete supporting-file sweep.

**[Should] Explicit `--gh-issue -` selects new-issue creation instead of rejecting the invalid issue value.** In `utils/hq/hq.sh`, `park)` initializes `issue="-"` and also accepts that exact value from `--gh-issue`. Both argument-count selection and `cmd_park` interpret it as flag omission. The numeric validation is inside `if [ "$issue" != "-" ]`, so it never sees this supplied nonnumeric value. With `--create` and a request, `num` stays empty and the existing new-issue branch executes `gh issue create`. Preserve whether the flag was supplied (or validate its value in the parser) so explicit invalid values cannot select fresh intake.

Observed input: `bash utils/hq/hq.sh park --create --gh-issue - XYZ-forge "fresh request"`.
Affected scope: callers supplying the sentinel as an issue value; both Tier A/B and Tier C can reach fresh GitHub issue creation. Normal numeric adoption does not hit this collision.
Falsifier: the same input rejects with a nonzero status before any issue-create call, while omission of `--gh-issue` still permits fresh intake.

Narrow non-mutating measurement (no HQ invocation, executable fixture, Git operation or network call): extracted the **actual** `park)` case arm and replaced only its final `cmd_park` callee with a printer. Command, run via `python3 -`:

```python
from pathlib import Path
import subprocess
s = Path('utils/hq/hq.sh').read_text()
start = s.index('case "${1:-}"')
p = s[s.index('  park)\n', start):s.index('  queue)\n', start)]
script = ('cmd_park(){ printf "create=%s title=%s issue=%s project=%s request=%s\\n" '
          '"$1" "$2" "$3" "$4" "$5"; }\ncase "$1" in\n' + p + '\nesac\n')
for issue in ('1267', '-'):
    r = subprocess.run(['bash', '-c', script, 'probe', 'park', '--create',
                        '--gh-issue', issue, 'XYZ-forge', 'fresh request'],
                       capture_output=True, text=True)
    print(r.returncode, r.stdout.strip())
```

Decisive measured output (both parser invocations exited 0):

```text
create=1 title= issue=1267 project=XYZ-forge request=fresh request
create=1 title= issue=- project=XYZ-forge request=fresh request
```

The source trace establishes the subsequent branch selection; no real issue was created to demonstrate it. Root cause: explicit flag input and absence share the same sentinel; Fix site: park argument parser / adoption-presence decision; Why not downstream: the create writer must remain available for genuinely fresh requests.

**Verification:** `bash -n utils/hq/hq.sh` exited 0 with no output. No suites or fixtures were executed, per turn containment. **[Unverified — needs clone run]** The builder summary contains no exact commands, exit statuses or decisive output for the required preview/no-write witness, releases-DB row and unchanged newest-GitHub-issue-number witness, registered-capture refusal, or byte-identical base preview. Record those acceptance receipts in the relay when obtained through the permitted harness/disposable-clone workflow; do not run mutation-heavy checks here. `test/hq-park.sh` must pass on the final committed candidate via the harness.

Handing off to agy — agy, take your turn.
