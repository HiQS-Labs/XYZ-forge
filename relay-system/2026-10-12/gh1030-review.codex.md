# RELAY · GH1030 merged-risk review and GH1019 policy review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1030-merged-risk-review-and-gh1019-policy-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/merge_cleanup_candidate.py** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh1030/merge_cleanup_candidate.py` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: operator-review
- Started: 2026-10-12
- Definition of Done: Independent code review, no implementation or test runs. Explicitly separate code behavior from test evidence (the full gate is running elsewhere). Only modify this relay file, no other writes, commits or pushes. Do not merge any PR.

Operational envelope: Post-merge regression review of development d09b8f9d and policy code proposed by PR1019 74b871f4. Read-only source review. No new features, suites or gates. The candidate merge_cleanup.py is seeded under .relay-artifacts/merge_cleanup_candidate.py. Review relevant callers in the existing cleanup orchestrator as well as the proposed policy.

Questions:
1. Read relay-automation/relay-turn-lib.sh relevant scratch and worktree functions in full, and git diff 53e40d6c^ 53e40d6c for these paths. Are nested/hyphen scratch files confined to the intended worktree copyback and root behavior?
2. Read utils/py/harness_paths.py and the lane_attempt_gate function plus both call sites in utils/py/marathon_drive.py. Does vendored .xyz precede XYZ_HARNESS; does check_only prevent capped relay commits and duplicate fire records?
3. Read the embedded progress observer and integration in relay-automation/marathon.sh. Is there a second executor or a concrete regression? Check symlink identity fix 45afc936 and missing/mismatched receipt handling. Do not treat synthetic metadata as actual approval.
4. Read merged slug identity changes in utils/py/releases_app.py and relay-automation/xyz-releases-onboard.sh. Can foreign owner/repo rows be admitted by the new normalization? Inspect prior_art_recon.py bounded fallback and addon app.js/preview.py for concrete regressions.
5. Confirm validate.sh gh492-idle-kill removal and test/gh306-registry-bidirectional.sh exemption, and review gh609 assertions relevant to already-merged governance.
6. Review the entire candidate merge_cleanup.py and compare with current file: default opt-out, target-owned policy, strategy rejection, capability failure behavior, cleanup, ledger side effects. Can it rewrite shared history without an explicit request? Note the tracked Forge opt-in .merge-cleanup.json in PR1019. Its current conflict in CHANGELOG.md/releases.db/releases.sql is a known landing blocker, not a runtime-code finding.

Output: concise graded findings with file:line, literal swept file: yes/no for each area, Observed input/Affected scope/Falsifier for change requests. Do not invent failures or demand new tests. If no concrete code findings, say so and Approve source review only; no merge readiness claim. If findings remain, hand back. Only update this relay, and let the driver own its commit.

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
Basis: Approved source review only. No concrete code finding identified in the six bounded areas below, including the pre-existing code in the entire 1,501-line candidate. This does not attest the external gate, approve PR1019 landing, or establish merge readiness. No source/artifact edits, git commands, suite executions, commits, or pushes performed.

- **1. Scratch / copyback — [Pass] source path:** relay-automation/relay-turn-lib.sh:722, :862, :1150, :1169, :1185, :1196: read relevant worktree and scratch functions in full. Nested recognition is enabled by worktree-end calls (:921–:922); the in-root call (:1227) omits it. Tracked files fail scratch classification; directory expansion requires every enumerated file to qualify; copyback iterates only RTL_ALLOW (:933). Hyphen prefixes are recognized by the shared predicate. No concrete regression found in this path.
  swept file: no
  Scope: complete named functions, not every library function. Historical diff verification unavailable; see limits.
- **2. Harness / attempt cap — [Pass] source path:** entire utils/py/harness_paths.py read; running .xyz discovery (:44) precedes XYZ_HARNESS (:52) and preserves logical symlink identity. utils/py/marathon_drive.py:1143 returns before the attempt append for check_only; early call at :3050 precedes relay rendering/commit, later call at :3300 counts the fire, and child environment at :3347 suppresses nested counting. No concrete cap regression found. The parking path can still emit its diagnostic/terminal receipt; the attempt counter is the read-only part.
  swept file: no
  Scope: full resolver plus gate, both call sites and child handoff, not all of marathon_drive.py. Actual capped-run/commit-count evidence: [Unverified — needs clone run].
- **3. Progress observer — [Pass] source path:** embedded observer at relay-automation/marathon.sh:54–:316 and integration at :542–:675 read. Observer reads/reports; the original phase driver remains the executor and the launcher waits before advancing (:634–:658). Receipt checks include execution, phase, lane, product path and token (:129); missing/mismatched receipts return an empty object, which cannot qualify (:147). Product root uses abspath (:267), matching target-path spelling in utils/py/marathon_drive.py:325. Returned success and qualified phases are separately counted (:292–:296). Synthetic metadata is not evidence of actual approval. No concrete regression found in reviewed paths.
  swept file: no
  Scope: full embedded Python and relevant launcher/receipt integration, not every launcher/driver branch. Commit 45afc936 provenance and real-run receipt evidence remain unverified here.
- **4. Identity / discovery / addon — [Pass] source and predicate probe:** utils/py/releases_app.py:5401–:5416 requires row-owned slug/origin and exact issue number/URL agreement after bare-name normalization; :5528 retains row ownership. Probe below rejected a same-name foreign-owner URL. Full relay-automation/xyz-releases-onboard.sh read: origin-derived slug feeds staged init (:119); staged check precedes materialization (:228, :266). Full utils/py/prior_art_recon.py read: REST fallback deliberately reads one page of 100, filters locally and returns up to 30 (:51–:80); it cannot prove exhaustive absence. Full addon app.js and preview.py read: shared issue selection, synthetic notice, pause after three failed automatic reads, fixed asset map and explicit live-read opt-in (addons/paperclip-dashboard/app.js:1, :46, :113; addons/paperclip-dashboard/preview.py:20, :38, :59). No concrete regression found in these reviewed sources.
  swept file: no
  Scope: full onboarding/scanner/addon files and relevant identity/evidence functions, not all of releases_app.py or all shared Flightdeck code.
- **5. Registry / governance — [Pass] source path:** validate.sh:219 documents removed idle-kill registration; test/gh306-registry-bidirectional.sh:48 exempts the retained file. test/gh609-sdlc-agent-gaps.sh:109–:122 pins workload-scoped safeguards matching skills/1-hourly/swe/SKILL.md:104; controls at :312–:326 remove ordering and rollback-window clauses. No concrete assertion mismatch found. No test result claimed: [Unverified — needs clone run].
  swept file: no
  Scope: registry entries and relevant gh609 assertions/controls, not every validate.sh/registry branch.
- **6. Candidate policy / cleanup — [Pass] full-file source review and policy probes:** entire .relay-artifacts/merge_cleanup_candidate.py:1–:1501 read and compared with current skills/2-daily/merge-cleanup/scripts/merge_cleanup.py using diff -u. Policy belongs to target repo_path (:150); absence retains legacy squash (:164, :173); opted-in squash/rebase is rejected (:169); capability uncertainty fails closed (:176–:188). Main, landing loop and direct merge entry resolve policy (:1269, :908, :931, :194). Existing repair uses a normal push (:419); landing uses GitHub merge (:207), and primary advances ff-only (:1174). No new shared-history rewrite path or force push identified. Policy adds no ledger writes; existing repair, reconcile, durable-write and teardown paths remain (:1044, :1179, :1189, :1459). Cleanup refreshes eligibility and uses worktree removal or Trash (:759, :796, :819). No concrete pre-existing defect identified in the candidate sweep.
  swept file: yes
  Forge opt-in .merge-cleanup.json in PR1019 is reported by Setup, not independently fetched here. Known CHANGELOG.md/releases.db/releases.sql conflicts remain landing blockers, separate from this source verdict.

**Narrow probe receipt:** command "export PYTHONDONTWRITEBYTECODE=1 TMPDIR=\"$PWD/.relay-scratch/tmp\"; mkdir -p \"$TMPDIR\"; python3 -B -" with stdin AST-selecting only candidate resolve_merge_policy/check_merge_capability and releases_app _repo_from_issue_url/resolve_roadmap_identity. Exit 0. No git/network invocation; capability responses supplied in memory; temporary policy data confined to TMPDIR. This is a predicate probe, not a suite or real GitHub capability check.

Inputs: missing policy; JSON {"preserve_commit_history":true}; explicit squash/rebase; capability outputs {}, false, true; repo_rows={1:"aegis-sleuth-slack-bot"}, origin="HiQS-Labs/AEGIS-Sleuth-Slackbot", gh_number=10, URL https://github.com/{owner}/AEGIS-Sleuth-Slackbot/issues/10.
Decisive output:
```text
default squash
opt-in merge
squash rejected
rebase rejected
{} refused
{"mergeCommitAllowed":false} refused
{"mergeCommitAllowed":true} accepted
HiQS-Labs True
Other False
```
An earlier invocation also supplied returncode=1/empty stdout and reported "capability 1 refused" (exit 0). These negative inputs demonstrate rejection in the selected predicates, not full workflow execution.

**Limits:** MCP graph tools were unavailable; source fallback used. Direct git use was prohibited, so historical comparisons were attempted with "gh api repos/HiQS-Labs/XYZ-forge/commits/53e40d6c --jq '.files[] | select(.filename == \"relay-automation/relay-turn-lib.sh\" or .filename == \"utils/py/marathon_drive.py\") | {filename,patch}'" and "gh api repos/HiQS-Labs/XYZ-forge/commits/45afc936 --jq '.files[] | {filename,patch}'". Both reported "error connecting to api.github.com"; the compound query command exited 1 (a later unquoted contents query also hit zsh glob rejection). Historical diffs remain [Unverified — network unavailable]. No current PR-state, actual hosted capability, provenance, or external gate claim follows from this review.

Relay closed (Approved), no further reviewer turn needed. Operator-review retains responsibility for external gate evidence and landing-conflict resolution. Driver owns the relay-file commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
