# RELAY · Pulse issue 2 existing fix and projection QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pulse-issue-2-existing-fix-and-projection-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **pulse2-review.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-17

### Artifact — pulse2-review.md
```
Review existing PR #680 at 345391d5988724fcb910ee8714d76728c38acbcc for Pulse issue #2. Read test/agent-chorus.sh installer block, test/gh678-installer-live-links.sh, skills/agent-chorus/install.sh, skills/skills-army-hq/scripts/sync.py reconcile and references/recovery.md. No code edits; relay only. No test execution in reviewer worktree.
Operational envelope: local skills tool with configurable skill collection and IDE target roots. User explicitly requires support for different collections and IDEs. Avoid speculative new machinery.
Questions: Does the PR stop the observed HOME leak and preserve live foreign links? Does the regression test check real behavior? Does it impose this user's 25 skills or three enabled IDEs on other users? Is applying the agent-chorus folder through intake update and using sync --migrate-from for its one unowned Gemini config link safe and scoped? Two other existing unmanaged Gemini links will be preserved in a recovery note and repointed individually to the same copied skill, without enabling whole IDE targets. User requested source and projected-folder fix. No merge requested. Existing PR remains unmerged and that will be disclosed.
Evidence: fresh full-clone focused runs: agent-chorus 213 pass/0 fail; installer matrix 45 PASS lines/exit 0, clone config and HEAD unchanged. No full gate run in this follow-up. Prior PR reports full-gate baseline failures. Git history correction: 3c820f0661165b3becc05b51d3062e67ec9066ee August 20 introduced Gemini targets while test only redirected Claude and Codex; August 23 9be6f70f is rename, not introduction. Existing PR's date claim is incorrect and should be noted as documentation follow-up.
Return explicit Approved or Changes requested, grounded file/line findings. Distinguish necessary fixes from optional follow-ups. Scope is verifying and deploying the existing fix, not creating a doctor subsystem or changing all-target defaults.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex — Round 1 — 2026-09-17

VERDICT: FAIL
Decision: Changes requested
Basis: The reported default-HOME leak is addressed, but configurable target overrides can still escape the test sandbox, and the pre-existing legacy-link branch bypasses foreign-link preservation. Deployment scope also requires an actual preview before it can be called one-link-only.
swept file: no
Scope: Read the entire embedded review artifact, installer, installer matrix, sync.py and recovery.md; inspected the complete agent-chorus installer block and supporting setup/intake paths. The initial whole-suite read was output-truncated, so this is not a claimed full sweep of all 1,361 lines of test/agent-chorus.sh. No source/artifact execution, tests, Git commands, or deployment performed. The supplied commit identity and test counts are producer-reported, not independently attested here.

- [Pass] The observed default-path leak is closed at all three installer calls: `test/agent-chorus.sh:686`, `:703`, and `:726` bind HOME to the fixture. The current-name branch refuses an existing live foreign link (`skills/agent-chorus/install.sh:61`). Retain these changes.
- [Blocker] Configurable Gemini roots still escape containment: those same three calls inherit `GEMINI_CONFIG_SKILLS_DIR`, `ANTIGRAVITY_SKILLS_DIR`, and `ANTIGRAVITY_CLI_SKILLS_DIR`; `skills/agent-chorus/install.sh:82`–84 gives them precedence over HOME. An exported real IDE root therefore receives installer writes despite sandbox HOME; the assertion at `test/agent-chorus.sh:693` runs only afterward and checks just Gemini Config. Fix: explicitly bind all three roots inside WORK on every invocation (or clear them in an installer-only wrapper), and check all five destinations. In a disposable full clone, exercise inherited overrides pointing to separate sentinel fixtures and show they remain untouched; never use real app roots for that control.
- [Blocker] Pre-existing live foreign legacy links are still overwritten. `skills/agent-chorus/install.sh:30`–33 repoints any `agent2agent` link whose text ends in `/skills/agent2agent` or `/skills/agent-chorus`, even when that directory exists in a different checkout. This runs before the new current-name guard (`:54`), so an eventual refusal can already have changed the legacy link. Fix: preserve/refuse live legacy links resolving elsewhere; retain migration of dangling legacy links and idempotence for links already resolving to SELF_DIR. Add a live foreign legacy fixture to the matrix.
- [Pass] The regression matrix exercises actual installers, checks nonzero refusal plus unchanged link text, then verifies dangling-link replacement by directory identity (`test/gh678-installer-live-links.sh:19`–39). These are behavioral checks, not source-pattern checks. Keep them; the reported green counts alone do not supply a witnessed pre-fix red control.
- [Should] The containment assertion at `test/gh678-installer-live-links.sh:42`–44 conflates a pre-existing legitimate real Claude installation with a write during this run, and inspects no Gemini paths. Fix in a follow-up: compare before/after state in controlled sentinel roots and assert all intended sandbox destinations; do not infer a write merely from an existing link.
- [Pass] No production requirement for this operator's 25 skills or three enabled IDEs appears here: `skills/skills-army-hq/scripts/sync.py:97`–98 derives targets and names from config/inventory, and `:181` accepts a collection root. The matrix's fixed 22 is a repository-installer count (`test/gh678-installer-live-links.sh:46`), not a deployed-collection size. Preserve configurability and existing all-target defaults.
- [Should] Treat migration as preview-scoped, not inherently one-link-scoped. `sync.py:97`–101 reconciles all inventory across enabled targets and existing receipts; `:234`–236 can apply valid actions even while returning conflicts. `--migrate-from` restricts permission to replace matching source links (`:116`–124), not the full action set. Before deployment, retain a preview proving the only intended changes; inspect actions, changes, errors, and any withdrawals. No new filtering subsystem is required.
- [Pass] Explicit source migration validates skill/repository identity (`sync.py:203`–215), requires the current destination to match (`:119`), records previous link text (`:124`, `:134`), and refuses retargeted owned links (`:109`–110). Recovery requires preserving link text outside discovery roots and verifying the copied skill (`skills/skills-army-hq/references/recovery.md:7`–16, `:131`–136). Use intake update for the copied folder, then this preview/apply route for the unowned managed-target link. The two unmanaged IDE links can remain individually scoped without enabling whole targets; record their exact old text and verify their final read-through. This is procedural review, not evidence that deployment occurred.
- [Nit] Documentation follow-up: correct the PR's introduction date using the supplied August 20 commit, distinguishing the August 23 rename. The embedded artifact explicitly says “August 23 9be6f70f is rename, not introduction”; Git history was not independently inspected under the no-Git constraint.

Necessary before approval: close the two containment/ownership findings and supply focused positive plus negative-control evidence from a disposable full clone. The matrix observation check and date correction are follow-ups. No merge is authorized; PR #680 remains unmerged per the supplied artifact, and no full-gate success is claimed.

Handing off to Producer — address the necessary findings and append dispositions/evidence; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
