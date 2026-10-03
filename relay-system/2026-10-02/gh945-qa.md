# RELAY · GH-945 final QA — radar verification-asset recommendation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 2

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
6. **Commit only the relay file** (`relay(gh945-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh945-relay-diff.patch** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/marathon-clones/forge-gh945-radar-verify-reco/temp/gh945-relay-diff.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-02
- Definition of Done: commit 12d9a9c1 (GH-945) is QA-clean:
  (a) the new sibling section matches the settled design: conditional (real target AND detected asset), cited detection (Cite or drop), recommendation-only (never executes/gates), silent otherwise, extend-coverage framing, no reciprocal pointer;
  (b) body-only: frontmatter byte-identical to base, gh779 pinned strings intact;
  (c) consistent with radar's existing guardrails and the sanity-check sibling's shape;
  (d) ledger/pointer-doc changes sane.
Operational envelope: doc-only skill instruction, local developer CLI repo (XYZ-forge). Commensurate complexity; GH-831 applies (no new tests is CORRECT there).

## Reviewer questions (answer each; cite file:line or quoted spans)
1. Does the section fire only when both a qualifying target and a detected asset exist? Any wording that would make it fire (or nag) unconditionally?
2. Is the detection list concrete and reasonable (fuzzers/property suites/script targets/gate entry points)? Anything load-bearing misnamed?
3. Does anything in the diff let radar execute, gate, or auto-invoke anything? Any conflict with the recite/guardrails sections?
4. Is the insert position and voice consistent with the sanity-check sibling and the ## Boundaries table that follows?
5. Are the pointer doc and releases.sql changes consistent with the issue?
6. Commensurate complexity: over- or under-engineered for a doc-only sibling recommendation?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The recommendation itself meets the settled design; the active pointer document needs lifecycle reconciliation before approval.
swept file: yes

Scope: read the entire Radar skill, entire new pointer doc, and entire seeded patch, including all ledger changes. Ledger review is bounded to the affected row, generation and receipts, not an audit of unrelated historical rows. Used direct text reads for these non-code artifacts; no Git commands or suites ran.

- [Pass] Q1–2: the trigger is conjunctive and relevant: “When Lens 2 surfaces” a mechanically checkable target, then “If one exists and covers” its surface; lines 664–667 explicitly require silence without either target or detected asset. The examples at skills/3-weekly/radar/SKILL.md:652–655 are recognizable asset families, not invented commands. Detection must cite its file/config/entry point (lines 659–661). No required change.
- [Pass] Q3–4: the addition authorizes a recommendation to the operator, not execution or gating (skills/3-weekly/radar/SKILL.md:656–667), and favors extending adjacent coverage. It sits immediately after the sanity-check sibling and before Boundaries, matching that sibling's operator-facing voice and non-reciprocal routing. No required change to the new recommendation's scope.
- [Pass] Q6/body-only: the seeded patch's sole skill hunk is an insertion at old line 644, after frontmatter and existing GH-779 sections; no existing skill bytes are removed. This supports unchanged frontmatter relative to the supplied patch base, not an independently fetched commit comparison. One short prose section is commensurate; no new suites or machinery.
- [Pass] GH-779 literal probe: command was Python reading SKILL.md and test/gh779-radar-ci-health.sh as text, extracting pins with `[shlex.split(x)[2] for x in test_text.splitlines() if x.startswith('pin "')]`, checking each against the skill, and removing the first pin in memory as a red control. Exit 0; decisive output: `pins=17 missing=[]`, `red_control_detected= True`. This is a text probe, not execution of the shell suite.
- [Should] Q5: promote the active GH-945 document and repoint its ledger row through the canonical DB verbs. The new doc remains `PROJECT/1-INBOX/GH-945-RADAR-VERIFY-ASSET-RECO.md` with `status: Proposed` (line 5), while the patch's roadmap row says `In progress` / `in-progress` and includes an accepted-start event. PROJECT/PDDA.md:272–281 requires promotion to 2-WORKING when execution starts; ROUTER.md's promotion rule requires DB repoint/update. Update its status and “just completed / next” row to reflect implementation and QA, preserving a next action for the PR. The issue number, URL, rating 55/35/50/85, three generation increments and receipt chain otherwise agree within the patch.
  Observed input: the GH-945 roadmap INSERT points to an inbox Proposed doc despite `accepted_start: true` and the already-present implementation.
  Affected scope: this one active GH-945 pointer and its ledger doc_path/status, not unrelated ledger history.
  Falsifier: an applicable explicit exemption allowing this implemented task to remain Proposed in 1-INBOX would remove the need; none is documented in the supplied task or lifecycle policy.
- [Nit] Whole-file sweep found a pre-existing wording tension: skills/3-weekly/radar/SKILL.md:322–324 requires executing guards in disposable clones, while line 677 says “Radar never executes anything.” Interpret the new sibling's non-execution rule locally to its recommendations; a follow-up clarification can distinguish diagnostic guard runs from executing fixes/recommended assets without removing GH-779's pinned behavior.
  Observed input: “run it against every open PR head” versus “Radar never executes anything.”
  Affected scope: existing diagnostic-execution wording only.
  Falsifier: an explicit existing definition limiting “executes” to fixes would resolve the ambiguity; the quoted boundary currently says “anything.”
- [Unverified — needs clone run] Shell gate/PDDA execution and exact-commit attestation remain for the harness's disposable full-clone gate. No suite result is claimed here.

Handing off to Producer (claude-a): reconcile the GH-945 active document and ledger pointer, then return for round 2.

### Producer · Round 1 (claude-a)

- **[Should] Promote the GH-945 document and repoint its ledger row** — Implemented: doc moved
  `PROJECT/1-INBOX/` → `PROJECT/2-WORKING/` via `git mv`, frontmatter `status: Proposed` →
  `In Progress`, Status table updated to the real state (implementation committed, Round-1 [Should]
  fixed, next = Round-2 re-review + PR); ledger row repointed through the canonical verb
  (`roadmap repoint --issue-num 945 --doc-path PROJECT/2-WORKING/...`), `releases check` clean
  (0 failures). Commit 9caf47dd on the task branch. No change to the reviewed skill section
  (Round-1 [Unverified — no citation] on Q1–Q4/Q6 stands).

Handing off to Reviewer (codex) — re-review the lifecycle fix on 9caf47dd.

### Reviewer · Round 2

VERDICT: PASS
Basis: The current working-tree documents resolve Round 1's lifecycle finding; the recommendation still meets the settled design. Approval covers the supplied patch plus the inspected current lifecycle fix, not a claim that the stale patch contains that fix or that clone gates passed.
swept file: yes

Scope: reread the whole Radar skill, whole current GH-945 pointer document, and seeded patch; inspected the affected ledger row, generation and repoint receipt. No additional pre-existing blocking defect found. The Round-1 nonblocking execution-wording nit remains. Graph project enumeration has no index for this review worktree; this non-code review uses direct source text, not graph completeness claims.

- [Pass] Q1–2: skills/3-weekly/radar/SKILL.md:649–661 requires a mechanically checkable Lens-2 target and an existing relevant asset, names concrete fuzzer/property-suite/script/gate families, and requires a detection citation. Lines 664–667 explicitly keep absent-target/absent-asset cases silent. No change requested.
- [Pass] Q3–4: “Radar recommends and never executes” is immediately scoped to running the harness, extending corpora and gating adoption (skills/3-weekly/radar/SKILL.md:663–667). The section follows the sanity-check sibling and precedes Boundaries; it retains operator-facing recommendations, extension of adjacent coverage, and no reciprocal pointer. It adds no execution authority to the recitation or report guardrails.
- [Pass] Q5 / Round-1 [Should] resolved: PROJECT/2-WORKING/GH-945-RADAR-VERIFY-ASSET-RECO.md:5 now says “status: In Progress”; its Status row at line 20 records implementation and the lifecycle fix, with re-review/PR next. releases.sql:796 points both doc_path and raw_text at 2-WORKING, preserving issue 945, in-progress status and 55/35/50/85 ratings. releases.sql:3 is generation 1400 and line 2407 adds the roadmap-repoint receipt chained from the prior final digest. The original inbox file is absent. No lifecycle change remains requested.
- [Pass] Q6 / body-only: the seeded skill hunk is only a 22-line insertion at old line 644; it removes no existing bytes and leaves frontmatter outside the changed region. The current inserted text matches that hunk exactly. This is commensurate prose with no new suites or machinery; base-frontmatter preservation is supported by the supplied patch, not an independent Git comparison.
- [Pass] Narrow text probe, exit 0: ran the following Python under `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"` (no shell suite execution):
  ```python
  from pathlib import Path
  import shlex
  s = Path('skills/3-weekly/radar/SKILL.md').read_text()
  t = Path('test/gh779-radar-ci-health.sh').read_text()
  pins = [shlex.split(x)[2] for x in t.splitlines() if x.startswith('pin "')]
  assert pins
  missing = [p for p in pins if p not in s]
  print('pins=', len(pins), 'missing=', missing)
  assert not missing
  assert pins[0] not in s.replace(pins[0], '')
  print('red_control_detected=True')
  p = Path('.relay-artifacts/gh945-relay-diff.patch').read_text()
  h = p.split('diff --git a/skills/3-weekly/radar/SKILL.md')[1]
  addition = '\n'.join(x[1:] for x in h.splitlines()
                       if x.startswith('+') and not x.startswith('+++')) + '\n'
  assert addition in s
  print('seeded_skill_addition_matches_current=True')
  print('old_inbox_exists=', Path('PROJECT/1-INBOX/GH-945-RADAR-VERIFY-ASSET-RECO.md').exists())
  ```
  Decisive output: `pins= 17 missing= []`, `red_control_detected=True`, `seeded_skill_addition_matches_current=True`, `old_inbox_exists= False`.
- [Nit] Review packaging: the immutable seeded patch still shows the original inbox/Proposed state and generation 1399. The current files cited above establish the fix independently; refresh the eventual PR review artifact to include the lifecycle commit.
- [Unverified — needs clone run] PDDA/shell gates, ledger integrity execution and exact-commit attestation remain for the harness's disposable full-clone gate. No Git commands, suites, or executable fixtures ran in this turn.

Relay closed (Approved), no further turn needed. Producer (claude-a) resumes the outer gate/publication workflow.


### Attestation · relay-drive — 2026-10-03T06:20:17Z
task: RELAY-gh945-qa
reviewer: codex
status: Approved
reviewed-head: f08031a57502d4bbbf972c166e86453ce8e84f86
added-range: 11898+4252
added-sha256: df29aae395c48c1f83bf1d0dc6c0713cbd07960f27f86338a8106875240489cc
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
