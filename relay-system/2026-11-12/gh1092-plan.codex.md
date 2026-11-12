# RELAY · GH1092 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-12.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1092-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1092-REVIEWER-EVIDENCE.md
- Reviewer: codex   ·   Producer: implementation
- Started: 2026-11-12
- Definition of Done: Evaluate the bounded plan below, preserving unresolved GH981 and #1092 requirements. No production changes yet.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Plan review packet

First read ONLY PROJECT/2-WORKING/GH-1092-REVIEWER-EVIDENCE.md (no author chat).
Before any supplementary source, write 2–5 sentences under What this proposes and
How the existing system works, per this document, and short What it is not.
Record that input boundary in your review block. Then perform source-backed validation.

Read the live #1092 issue including comment 6205666218 with read-only gh; original
LTVera GH981 body with read-only gh. Read relay-automation/relay-turn-lib.sh rtl_turn_prompt,
utils/py/rtl.py turn_prompt, utils/py/codex-turn.py, relay-automation/new-relay.sh,
utils/py/relay_drive.py judge_terminal, skills/1-hourly/relay-xyz/SKILL.md item 5,
and existing test/gh681-reviewer-probe-rules.sh, test/gh397-reviewer-turn-role.sh,
test/gh505-relay-attest.sh. Target Forge AGENTS.md is the governing test policy.
Operational envelope: local operator-owned CLI; change instructions in existing shared
prompt only, no permission enforcement/controller changes or global semantic gate.

Questions:
1. Does source substantiate the proposed delivery/permission gap after merged PR1432/1445?
2. Is the supplied-clone permission narrow enough to preserve protected-worktree restrictions,
   pinning, no shared Git mutations and honest missing-environment classification?
3. Does this retain all issue scope as open where not implemented, with no fake closure?
4. Are main/adjacent checks and pre-fix rejection sufficient for this bounded delivery seam?
5. Are rating, reuse, rollback and scope commensurate? Reject speculative new machinery.
6. What prevents unchanged/unfixed prompt from being claimed delivered, and where will its
   observed rejection be retained? Source citations and existing tests are not behavioral proof.

Do not run suites here or create a clone. Review permissions only. Append one review block,
include swept file: yes/no, VERDICT and Basis, set header, and close tick on approval.

## Log

### Reviewer · Round 1

Input boundary: read the entire artifact first, without author chat or supplementary sources; the following paraphrase was recorded before source validation.

**What this proposes:** Deliver target-specific policy and narrow measurement permission through the shared reviewer prompt and existing relay-xyz documentation. Allow an explicitly assigned check only in an orchestrator-supplied, revision-pinned disposable full clone, retaining evidence and identity checks.

**How the existing system works, per this document:** Python reviewers delegate prompt construction to the shared Bash function; its current note permits seeded-artifact probes and a named phase-gate exception. Existing history/disposition and terminal attestation mechanisms remain in place but do not establish semantic truth.

**What it is not:** A controller or global semantic gate, a LTVera implementation, or closure of either issue's remaining requirements.

swept file: yes

VERDICT: FAIL
Basis: The bounded delivery design is sound, but its red control currently demonstrates missing text rather than an observed rejection of an unchanged candidate. Tighten that acceptance step before implementation. This is plan QA, not runtime qualification; no suites, executable fixtures, clone creation or git commands ran.

- [Should] S1 — Make step 5 defect-sensitive and retain the rejection. `PROJECT/2-WORKING/GH-1092-REVIEWER-EVIDENCE.md:88-95` promises a live candidate transcript but only “renders baseline prompt demonstrating missing delivery/permission text” for the red control. A baseline display has no stated acceptance verdict, so it cannot establish that the unchanged prompt fails the delivery criterion. PR1445's merged description explicitly asks “what prevents an unchanged, unfixed candidate from being reported as delivered, and where was rejection observed?” Define one manual acceptance procedure applied to baseline and candidate: require actual rendered delivery of target-rule discovery and supplied-clone permission, and the live candidate transcript's assigned check/evidence; reject baseline on the missing delivery requirements, recording the decisive missing spans and explicit failed verdict. Do not require a new global gate, a new suite, or a speculative baseline behavioral run. Retain baseline rejection, candidate render/transcript/check outputs and command/revision/exit details together under `TESTS-RESULTS/<date>+GH-1092/` with committed `provenance.jsonl` and link them from FINAL QA. Existing suite success remains separate regression evidence.
  Observed input: Step 5 at lines 90-91 specifies only “Red control renders baseline prompt demonstrating missing delivery/permission text”; step 6 names committed provenance without assigning this rejection a durable receipt.
  Affected scope: Acceptance of this prompt delivery change, including an unchanged baseline incorrectly presented as delivered; no relay terminal-policy or controller change.
  Falsifier: A retained manual baseline acceptance result explicitly rejecting missing rule/permission delivery, paired with a candidate result satisfying the same requirements and live clone-check evidence, would satisfy S1; a baseline render or green regression suite alone would not.
- [Pass] Source substantiates the narrow delivery gap after the reused changes: `utils/py/codex-turn.py:53` calls the bridge, `utils/py/rtl.py:866-868` delegates to `rtl_turn_prompt`, and `relay-automation/relay-turn-lib.sh:1067` permits seeded probes but sends clone-only claims to Unverified without the proposed supplied-clone route. `utils/py/relay_drive.py:744-754` conditions refusal on `MARATHON_REVIEWER_GATE_CMD`; it is not generic semantic approval. Read-only `gh api` reads of PR1432 and PR1445 returned exit 0, `merged: true`, merge SHAs `2688c788007e925bdbc0a352cca282917c9077b7` and `76a53663834193d75e1994c8c6b5e4d3f089584b` respectively. No new controller is warranted.
- [Pass] Proposed authority is appropriately bounded: artifact lines 78-83 require an assigned command, separate full clone, reviewed-revision pin, identity brackets, no protected checkout execution or shared Git mutation, and missing-environment Unverified. Keep that last classification for sandbox/network/DB access failures too; prose permission alone does not supply writable sandbox access. `codex-turn.py` currently adds only the shared `.tick` directory to its extra sandbox roots. The planned live supplied-clone smoke must establish that its orchestrator-provided environment actually supports the assigned command.
- [Pass] Requirements remain open rather than falsely closed: artifact lines 100-115 explicitly preserve six decisions and original eight findings. Live `gh api repos/BinoidCBD/LTVera-Pandas/issues/981 --jq .body` (exit 0) still says “The original eight checkboxes above remain open”; live #1092 and comment 6205666218 (both read via `gh api`, exit 0) retain factual approval, umbrella verification and cross-repository policy work beyond this bounded seam. Artifact's “neither closes” and non-goals preserve that scope; no LTVera runtime/browser closure is established here.
- [Pass] Reuse, rating and rollback are commensurate: artifact lines 58-68 and 119-122 bound this to prompt/docs/package, call reversal Easy, explain the four scores without claiming a recurrence rate, and reject parallel machinery. Existing `test/gh681-reviewer-probe-rules.sh` explicitly distinguishes wording cases from behavioral residue containment; `test/gh397-reviewer-turn-role.sh` case 8 covers reviewer scope; `test/gh505-relay-attest.sh` covers attestation/forgery, not factual truth. Running these plus the planned main/adjacent smokes in a disposable clone is appropriate once S1 is corrected.

Source access limits: graph search returned “MCP tool call requires approval, but approval policy is never”; used direct source reads instead. Initial `gh issue view` calls failed connection (exit 1); read-only `gh api` retries supplied both issue bodies and the requested comment. Entire plan swept; no additional pre-existing plan defects found. Runtime/suite claims remain [Unverified — needs clone run].

Handing off to Producer (implementation) — address S1 in the plan, log its disposition and reopen round 2; go to the Producer window and say 'take your turn'.

### Producer · Round 2

Disposition S1: Implemented in plan step 5. One manual acceptance procedure now rejects the
baseline explicitly on absent target-rule/supplied-clone clauses and requires candidate rendered
clauses plus live transcript/check evidence. Both verdicts and provenance have one durable location.
Sandbox/network/DB failures remain Unverified. No controller or suite added.

Reviewer: recheck S1 and the revised plan against the retained round-1 source validation;
read any source necessary for changed claims, but do not repeat the plan-only paraphrase.
No implementation writes have occurred. Handing off to codex.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
