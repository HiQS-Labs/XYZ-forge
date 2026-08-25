# RELAY · Sharpen Opinionated SOPs section (SOP.md + AGENTS.md pointer)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-24.
-->

NEXT: done
STATUS: Approved
ROUND: 3 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
6. **Commit only the relay file** (`relay(opinionated-sops-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `SOP.md` (new "## 4. Opinionated SOPs" section) and `AGENTS.md` (the two-line pointer under "What this file owns")
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-08-24
- Definition of Done: The "Opinionated SOPs" section (a) is clearly marked as XYZ-maintainer-only defaults that public/downstream users may disable, have their LLM maintainers ignore, or strip by script on upstream pull; (b) states the primary-checkout-stays-on-`development` rule unambiguously; (c) states the express-vs-fresh-clone rule: direct commit+push to `development` only on explicit user request for critical express work, otherwise the LLM starts new work in a new local full-clone folder (NOT a git worktree, per GH-564) → feat/fix branch → PR into `development`; (d) does not contradict AGENTS.md, GH-564 clone-isolation, or SOP.md §1–3; (e) the AGENTS.md pointer is short, accurate, and consistent with that file's "do not restate" rule. Wording clarity, internal consistency, and correct scoping are in scope; restructuring the rest of SOP.md is not.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · Round 1

swept file: yes (`SOP.md` and `AGENTS.md`, whole files)

- [Blocker] The primary-checkout rule identifies the primary as “this folder,” but this file exists
  in every full clone and worktree; after following the next bullet, the feature clone would also
  call itself the primary and be told to remain on `development` (`SOP.md:131-138`). Fix: define one
  operator-designated primary clone by role, explicitly say the rule does not apply to task clones,
  and remove “this folder.”
- [Blocker] The default branch creation conflicts with the existing interactive rail: the new rule
  directs the LLM to create a `feat/` or `fix/` branch whenever express mode was not requested
  (`SOP.md:134-138`), while AGENTS permits a new interactive branch only when the user explicitly
  requests one (`AGENTS.md:327`). Fix: state unambiguously that this maintainer policy is the standing
  explicit authorization for that fresh-clone task branch, or add a short corresponding carve-out to
  the AGENTS pointer/rail; do not leave precedence implicit.
- [Blocker] The shown clone command does not produce the documented GitHub PR lane: `git clone .`
  makes the source checkout path the new clone's `origin` (`SOP.md:63-66`, repeated at
  `SOP.md:136-138`), while fresh-clone hook wiring is per clone (`AGENTS.md:116-121`). Fix: prescribe
  cloning the GitHub remote into the new folder, branching from `origin/development`, installing the
  hook in that clone, then pushing the task branch and opening the PR into `development`.
- [Should] The file declares itself specialized specifically for campaigns and benchmark provenance
  (`SOP.md:3-8`), but §4 now governs all maintainer development work (`SOP.md:123-138`). Fix: amend the
  opening scope statement to name §4 as a maintainer-workflow appendix/exception so a cold reader does
  not discard the section as out of scope.
- [Should] Pre-existing full-file defect: “Local Gate Qualification” runs `./validate.sh`
  (`SOP.md:33`, `SOP.md:68-74`), whereas AGENTS says `validate.sh` is a self-check and only
  `ci-local.sh` writes qualifying evidence (`AGENTS.md:122-129`). Fix: either run `bash ci-local.sh`
  here or rename the step to a non-qualifying preflight and say qualification remains outstanding.
- [Pass] The downstream opt-out is explicit—including disable, LLM-ignore, and scripted stripping—
  and the AGENTS pointer stays short instead of duplicating the policy (`SOP.md:123-129`;
  `AGENTS.md:21-30`).

Verdict: Changes requested
VERDICT: FAIL
Basis: Three blockers prevent the maintainer workflow from being unambiguous and executable as written.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · claude-a · Round 2

Dispositions for Round 1 findings:

- [Blocker 1 — "this folder" primary ambiguity] **Implemented.** Rule now defines one
  "operator-designated primary clone" by role, removes "this folder", and states task clones are
  exempt (`SOP.md` §4, first bullet).
- [Blocker 2 — conflict with AGENTS.md no-auto-branch rail] **Implemented.** §4 now states the policy
  is the standing explicit authorization for exactly one `feat/`/`fix/` branch per fresh task clone
  (same carve-out shape as the marathon per-lane branch) and explicitly not a licence to commit onto
  `development`. The AGENTS.md pointer names the carve-out too.
- [Blocker 3 — `git clone .` origin trap] **Implemented.** §4 now prescribes cloning the GitHub
  remote (`git clone git@github.com:HiQS-Suite/XYZ-forge.git ../XYZ-forge-<topic>`), per-clone
  `githooks/install.sh` (GH-549), and branching off `origin/development`. §2's `git clone .` was left
  as-is: that path provisions local campaign clones (destructive-suite isolation), not the PR lane.
- [Should 1 — file scope statement excludes §4] **Implemented.** Scope block now names §4 as a
  maintainer-workflow appendix exception.
- [Should 2 — validate.sh presented as qualifying] **Implemented (minimal).** Step 3 renamed "Local
  Gate Preflight (non-qualifying)" with a line naming `bash ci-local.sh` as the qualifying run.

Handing off to Reviewer — codex, take your turn.

### Reviewer · codex · Round 2

swept file: yes (`SOP.md` and `AGENTS.md`, whole files)

- [Should] The lifecycle diagram still calls step 3 “Local Gate Qualifying” and maps it to
  `./validate.sh`, contradicting the corrected “Local Gate Preflight (non-qualifying)” prose and its
  statement that `bash ci-local.sh` is the qualifying run (`SOP.md:36-37`, `SOP.md:71-79`). Fix:
  rename the diagram node to “Local Gate Preflight (non-qualifying)” (or similarly compact wording)
  so the overview and detailed step make the same claim.
- [Pass] The primary is now operator-designated by role, stays on `development`, and explicitly
  excludes disposable task clones (`SOP.md:136-140`).
- [Pass] The normal lane now specifies a GitHub-origin full clone rather than a worktree, per-clone
  hook wiring, a task branch from `origin/development`, and a PR back into `development`; express
  commits remain limited to explicit user requests for critical work (`SOP.md:141-160`).
- [Pass] The downstream opt-out and maintainer-only scope remain explicit, while the AGENTS pointer
  is concise and supplies the interactive-branch carve-out without restating the workflow
  (`SOP.md:128-134`; `AGENTS.md:21-32`).
- [Pass] No other pre-existing defects relevant to the Definition of Done were found in the full-file
  sweep (`SOP.md:1-160`; `AGENTS.md:1-357`).

Verdict: Changes requested
VERDICT: FAIL
Basis: The policy itself is sound, but the stale top-level diagram still teaches the opposite gate
qualification rule from the corrected step text.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · claude-a · Round 3

Disposition for Round 2 finding:

- [Should — lifecycle diagram stale label] **Implemented.** Diagram node 3 renamed to
  "Local Gate Preflight (non-qualifying)", matching the corrected Step 3 heading (`SOP.md` §2
  diagram).

Handing off to Reviewer — codex, take your turn.

### Reviewer · codex · Round 3

swept file: yes (`SOP.md` and `AGENTS.md`, whole files)

- [Pass] The lifecycle diagram now labels step 3 “Local Gate Preflight (non-qualifying)” and maps it
  to `./validate.sh`, matching the detailed step's distinction between that self-check and the
  qualifying `bash ci-local.sh` run (`SOP.md:27-52`; `SOP.md:71-79`).
- [Pass] The section remains explicitly maintainer-only and optional downstream, including the
  disable, LLM-ignore, and scripted-strip options (`SOP.md:128-134`).
- [Pass] The primary-checkout rule is unambiguous by role, keeps the operator-designated primary on
  `development`, and exempts disposable task clones (`SOP.md:136-140`).
- [Pass] The normal lane requires a GitHub-origin full clone rather than a worktree, per-clone gate
  wiring, one `feat/`/`fix/` branch from `origin/development`, and a PR back into `development`;
  direct commit + push remains restricted to an explicit request for critical express work
  (`SOP.md:141-160`).
- [Pass] The AGENTS pointer is concise, accurately identifies the maintainer-only policy, and makes
  its narrow interactive-branch carve-out explicit without restating the workflow (`AGENTS.md:21-32`;
  `AGENTS.md:329-330`).
- [Pass] No other pre-existing defects relevant to the Definition of Done were found in the full-file
  sweep (`SOP.md:1-160`; `AGENTS.md:1-357`).

Verdict: Approved
VERDICT: PASS
Basis: The Round 2 inconsistency is resolved, and the complete artifacts satisfy all five Definition
of Done criteria without a remaining in-scope defect.

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
