# RELAY · GH-268 installers branch QA (governance adjudication)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
-->

NEXT: Producer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-268-installers-branch-qa-governance-adjudication): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/gh268-branch-review-artifact.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/7c523f9d-cb85-4799-8499-ebdeb6e9fb95/scratchpad/gh268-branch-review-artifact.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-22
- Definition of Done: **Adjudicate the branch `marathon/gh-268-installers-2026-07-22` (14 commits vs
  `development`, full diff + commit log embedded in the artifact) against this repo's own governance
  docs — not general code-quality taste.** Before grading, read all three in full:
  - `GUIDING-PRINCIPLES.md` (repo root)
  - `AGENTS.md` (repo root) — this repo's canonical agent behavior/decision-quality/proof rules
  - `PROJECT/PDDA.md` — the PDDA (Plan-Driven Development Agent) lifecycle framework this repo runs on

  What happened on this branch (context, not a claim to take on faith — verify against the diff): a
  GH-268 Phase 1 remediation item ("every skill ships an install.sh") was built via an operator-directed
  marathon trial — first an aider+qwen3.8-max builder (partially successful, 2/9 files, logged in two
  now-closed GH issues #279/#280 for its reliability problems), then completed via codex-builder +
  agy-reviewer for the remaining 7 (0 failures). A separate unrelated stash (`RELEASES.md` +
  `GH-272.md`) was folded in as its own commit, and install.sh modes were normalized to 755 in another.

  Grade against these dimensions, citing `file:line` (diff) or doc:line (governance doc) for every
  finding per the citation rule above:
  1. **PDDA compliance** — is this branch's work traceable to a real GH issue/capture doc (GH-268 in
     `PROJECT/2-WORKING/`)? Is the Issue-first SOP honored? Does the PDDA ledger/checklist update
     (the Phase 1 checkbox commit) meet PDDA's own documentation standards?
  2. **Guiding Principles adherence** — commit hygiene (one purpose per commit — is that honored across
     the 14?), blast-radius discipline (was risky work properly isolated — throwaway branch, no push,
     worktree-isolated builder turns), and any principle a commit or the overall approach violates.
  3. **AGENTS.md decision-quality/proof rules** — are claims in commit messages and the doc-update
     commit backed by actual evidence (e.g. does "functionally verified" claim match what's
     demonstrable from the diff), not asserted without proof.
  4. **Installer correctness itself** — spot-check that the 9 `skills/*/install.sh` files are
     structurally sound (shebang, idempotency, symlink safety) independent of process — a governance
     pass that ignores whether the actual deliverable works would be incomplete.

  A `[Pass]` on any dimension needs a citation exactly like a `[Blocker]` does — "looks fine" is not
  a grade. If a dimension doesn't apply or can't be assessed from the artifact alone, say so explicitly
  rather than silently omitting it.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · codex

- [Blocker] The unrelated `PROJECT/2-WORKING/GH-272.md` is added directly to the active bucket with no YAML frontmatter, `## Status` table, verification steps, or descriptive issue filename, and the full diff adds no `ROADMAP.md` pointer for that path (`.relay-artifacts/gh268-branch-review-artifact.md:44-60`). Active docs require those structures, and promotion must preserve the issue capture plus ledger pointer (`PROJECT/PDDA.md:51-72`, `PROJECT/PDDA.md:193-202`, `PROJECT/PDDA.md:222-247`, `PROJECT/PDDA.md:367-385`). Fix: remove this unrelated file from the GH-268 branch, or replace it with a correctly named, fully compliant promotion and its exact one-line roadmap pointer.
- [Should] Commit `f64d8a3` combines the GH-272 bug capture and a release-ledger seed in one pre-marathon-stash commit, so it is neither one-purpose nor part of the GH-268 installer outcome (`.relay-artifacts/gh268-branch-review-artifact.md:16`, `.relay-artifacts/gh268-branch-review-artifact.md:44-79`). This weakens the attested/relevant signal required of each turn (`GUIDING-PRINCIPLES.md:11-18`). Fix: drop the unrelated stash commit from this branch; land any still-needed GH-272 and `RELEASES.md` work separately on their own governance rails.
- [Should] The checked GH-268 item still says the same nine skills “have no `install.sh`,” immediately before a same-day note saying all nine now have one (`.relay-artifacts/gh268-branch-review-artifact.md:29-40`). PDDA treats docs as resumable runtime state and says disagreement with reality is a docs bug (`GUIDING-PRINCIPLES.md:38-40`). Fix: make the old audit statement explicitly historical (for example, “Originally confirmed before remediation”) while retaining the evidence-bearing Done note.
- [Pass] The installer effort is locally traceable to the existing GH-268 active doc, and every phase brief points back to that exact Phase 1 item (`.relay-artifacts/gh268-branch-review-artifact.md:21-40`, `.relay-artifacts/gh268-branch-review-artifact.md:94-117`, `.relay-artifacts/gh268-branch-review-artifact.md:177-195`, `.relay-artifacts/gh268-branch-review-artifact.md:255-274`), matching the issue-first execution-surface contract (`PROJECT/PDDA.md:204-220`). The artifact alone cannot independently establish the remote issue's live state; no change is requested for GH-268 traceability.
- [Pass] The phase records show scoped allowlists, no agent self-commit, no push, and separate builder/reviewer grading (`.relay-artifacts/gh268-branch-review-artifact.md:119-162`, `.relay-artifacts/gh268-branch-review-artifact.md:197-240`, `.relay-artifacts/gh268-branch-review-artifact.md:276-325`), satisfying containment and independent verification (`GUIDING-PRINCIPLES.md:26-28`, `GUIDING-PRINCIPLES.md:44-44`; `AGENTS.md:92-105`). Worktree isolation itself is not independently observable from this artifact, so that narrower fact is not graded; no change requested.
- [Pass] The “functionally verified” note is backed in the artifact by explicit, independently reviewed records of `bash -n`, first install, idempotent rerun, dangling-link repair, and real-path refusal across the 2+6+1 lanes (`.relay-artifacts/gh268-branch-review-artifact.md:152-162`, `.relay-artifacts/gh268-branch-review-artifact.md:230-240`, `.relay-artifacts/gh268-branch-review-artifact.md:311-325`), meeting the observable-proof rule (`AGENTS.md:52-55`). No change requested.
- [Pass] All nine installer hunks are mode `100755`, start with the required shebang and strict mode, resolve their source through `$BASH_SOURCE`, honor `CLAUDE_SKILLS_DIR`, preserve a correct link, replace only symlinks, refuse real-path collisions, and create the final link (`.relay-artifacts/gh268-branch-review-artifact.md:572-665`, `.relay-artifacts/gh268-branch-review-artifact.md:666-759`, `.relay-artifacts/gh268-branch-review-artifact.md:760-853`, `.relay-artifacts/gh268-branch-review-artifact.md:854-947`, `.relay-artifacts/gh268-branch-review-artifact.md:948-994`). This is a structural review only; runtime execution was prohibited for this turn. No installer change requested.
- [Nit] The artifact heading says “14 commits,” but lines 4-18 list 15 hashes (`.relay-artifacts/gh268-branch-review-artifact.md:3-18`). Fix the count when regenerating the review artifact so the adjudication scope is unambiguous.

**Verdict:** Changes requested

### Round 1 · Producer · claude-a

Dispositions (operator confirmed each before I acted):
- **[Blocker] GH-272.md duplicate → Implemented.** Independently verified before acting: a proper,
  ROADMAP-linked capture doc for issue #272 already exists at
  `PROJECT/1-INBOX/GH-272-WORKTREE-TICK-ROOT-MISMATCH.md` (ROADMAP.md:74); the file I'd added at
  `PROJECT/2-WORKING/GH-272.md` was a stray untracked duplicate that predated this session, with no
  PDDA structure and no roadmap pointer of its own. Removed via a new commit (`0807b1a`) — history is
  not rewritten (repo SOP: new commits, not amend/rebase), so the add-then-remove stays visible in
  the log rather than being hidden.
- **[Should] commit `f64d8a3` bundling → Declined (superseded), not rewritten.** The objectionable
  content (GH-272.md) is now removed by `0807b1a`; the remaining `RELEASES.md` content in `f64d8a3` is
  legitimate and wanted. Un-bundling the historical commit itself would require rewriting published
  history, which this repo's git safety rules avoid by default — a forward-fix commit was used
  instead, consistent with how this relay's own producer/reviewer loop is supposed to work.
- **[Should] self-contradictory Phase 1 checklist line → Implemented.** Reworded the old audit
  statement to be explicitly historical ("Originally confirmed ... before remediation") in `05f5d29`;
  the evidence-bearing Done note is unchanged.
- **[Nit] stale commit count in the review artifact → Implemented.** Regenerated the artifact
  (`.relay-artifacts/gh268-branch-review-artifact.md`) against current HEAD; branch is now at 19
  commits (grew further while landing these fixes) and the header reflects that live count.

New work: none — this round is fix-only, no new scope added. Handing back to Reviewer against the
refreshed artifact.

### Round 2 · Reviewer · codex

- [Pass] The prior GH-272 blocker is resolved by an auditable forward-removal commit (`0807b1a`), and the refreshed effective diff now moves directly from the GH-268 doc to `RELEASES.md` without adding a `PROJECT/2-WORKING/GH-272.md` hunk (`.relay-artifacts/gh268-branch-review-artifact.md:21-25`, `.relay-artifacts/gh268-branch-review-artifact.md:52-58`). This preserves history while removing the duplicate active doc, consistent with PDDA's one-canonical-execution-surface and active-doc contracts (`PROJECT/PDDA.md:35-49`, `PROJECT/PDDA.md:51-72`). No further GH-272 change requested.
- [Pass] The GH-268 checklist now describes the nine missing installers as the pre-remediation state, followed by a dated Done note and its verification scope (`.relay-artifacts/gh268-branch-review-artifact.md:39-50`). That restores the project doc as resumable current state (`GUIDING-PRINCIPLES.md:38-40`). No further checklist wording change requested.
- [Should] The effective branch diff still adds an unrelated placeholder release seed to `RELEASES.md` (`.relay-artifacts/gh268-branch-review-artifact.md:54-71`), while the branch's traced purpose is GH-268 installer remediation (`.relay-artifacts/gh268-branch-review-artifact.md:25-53`, `.relay-artifacts/gh268-branch-review-artifact.md:86-117`). Calling the seed legitimate does not make it relevant to this branch, and the quality bar requires relevant, structured signal (`GUIDING-PRINCIPLES.md:11-18`). Fix: add a forward commit removing only this `RELEASES.md` seed from the GH-268 branch; land the wanted release-ledger change separately on its own rail. Do not rewrite `f64d8a3`.
- [Pass] The refreshed artifact count is internally correct: its heading says 19 commits and lines 4-22 enumerate 19 hashes (`.relay-artifacts/gh268-branch-review-artifact.md:3-22`). No artifact-count change requested.
- [Pass] GH-268 traceability, containment, and separated grading remain evidenced by the three scoped phase briefs and their builder/reviewer records (`.relay-artifacts/gh268-branch-review-artifact.md:88-154`, `.relay-artifacts/gh268-branch-review-artifact.md:171-232`, `.relay-artifacts/gh268-branch-review-artifact.md:249-317`), matching issue-first execution state, allowlist containment, and independent verification (`PROJECT/PDDA.md:204-220`; `GUIDING-PRINCIPLES.md:26-28`, `GUIDING-PRINCIPLES.md:44-44`). Worktree isolation itself remains unobservable from this artifact and is not independently confirmed.
- [Pass] The verification claim remains backed by independently reviewed records of syntax and contained behavior checks (`.relay-artifacts/gh268-branch-review-artifact.md:144-154`, `.relay-artifacts/gh268-branch-review-artifact.md:222-232`, `.relay-artifacts/gh268-branch-review-artifact.md:303-317`), satisfying the observable-proof rule (`AGENTS.md:52-55`). No proof-text change requested.
- [Pass] All nine installer hunks are executable mode `100755` and retain the required strict mode, `$BASH_SOURCE` resolution, `CLAUDE_SKILLS_DIR` override, idempotent correct-link handling, symlink-only replacement, real-path refusal, and final link creation (`.relay-artifacts/gh268-branch-review-artifact.md:660-753`, `.relay-artifacts/gh268-branch-review-artifact.md:754-847`, `.relay-artifacts/gh268-branch-review-artifact.md:848-941`, `.relay-artifacts/gh268-branch-review-artifact.md:942-1082`). This turn is structural review only; runtime execution was prohibited. No installer change requested.

**Verdict:** Changes requested

### Round 2 · Producer · claude-a

Dispositions:
- **[Should] RELEASES.md unrelated to this branch's purpose → Declined, operator-directed.** Presented
  to the operator as a new/residual finding (round 1's GH-272 co-bundling concern is resolved; this is
  what's left once GH-272.md was removed). Operator explicitly chose to keep `RELEASES.md` on this
  branch rather than forward-remove it — it was brought in here on the operator's own prior direct
  instruction, and they've now confirmed that instruction stands even knowing the governance critique.
  Recorded here as an operator-authorized exception, not a missed finding: this branch carries one
  Should-level item (an unrelated but legitimate `RELEASES.md` seed) by explicit choice.
- All Round 1 findings previously verified Pass by the Reviewer (GH-272 removal, checklist wording,
  artifact count) — no further action.

No new work. This branch's remaining open item is a known, operator-accepted exception rather than an
unresolved defect. Deferring to the operator on whether to spend a further Reviewer round chasing a
formal Approved, or to treat this QA pass as concluded with the exception on record.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
