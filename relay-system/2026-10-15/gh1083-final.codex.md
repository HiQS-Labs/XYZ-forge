# RELAY · GH1083 radar GitHub-first final QA and bounded dry run
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: —
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1083-radar-github-first-final-qa-and-bounded-dry-run): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/3-weekly/radar/SKILL.md**, canonical task plan and retained verification packet.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: all four #1083 requirements met by a minimal skill-only payload, with truthful bounded manual dry-run evidence and post-merge deployment handoff.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Producer · Final review and dry-run request

Read all of skills/3-weekly/radar/SKILL.md, the original requirements in TESTS-RESULTS/2026-10-15+GH-1083/issue-source.json and the task plan PROJECT/2-WORKING/GH-1083-RADAR-GITHUB-FIRST.md. Apply the updated instructions yourself to dry-run-input.md and live-facts.json in the same evidence folder. Write a compact A–H decision report in this relay, then compare manual-dry-run.md and provenance.jsonl against your application. Do not execute any full Radar inventory or write either report sink. The cases deliberately combine dated real GitHub facts and explicitly controlled overlays; don't treat overlays as live repo state.

Questions:
1. Is GitHub truly primary across state/kinship/recurrence/closure/reopens/milestones/landed claims, with every doc-derived work fact verified when accessible and stale docs reported as drift? Does the whole skill contain a contradictory doc-wins clause? A resolving link is not kinship, issue closure is not code landing and an open PR is not shipped.  [Unverified — no citation]
2. Are explicit GitHub RGT declarations, quoted examples, conflicting declarations, adoption counts and doc fallback handled consistently without inferring Transform or dropping the five-bucket sum? Is the CI SOP exception restricted to adopted operating policy, preserving both draft-vs-adopted and newer-adopted-vs-stale-doc directions?
3. Are full/partial GitHub loss and PROJECT-only loss distinct, unknowns honest, and quiet/solved/retirement and sink confirmation boundaries preserved? Source evidence/read-only analysis is not an automatic repair, issue write or deployment.
4. Is the one-Markdown payload minimal and aligned with the approved plan/rating? No new scripts, tests, registry entries, runners or runtime edits. Instructions can be manually exercised but this is not proof of all future model responses.

Plan QA approved with mechanical attestation; existing Codex prerequisite 43/0 in a full helper clone, identity unchanged. Producer manual dry run has eight cases and textual red controls; format validation passes; classifier selects docs tier 1, no full runtime gate. Normal publication docs gate is pending until after final approval. Post-merge Skills Army refresh is explicitly tracked in plan; do not merge or deploy from this turn.

Operational envelope: local advisory skill, human report confirmation preserved. Apply commensurate complexity/ponytail; no speculative API scanner, parser framework or extra gate. Only this relay file writable; no self-commit, git mutations, validate.sh, test/*.sh, pytest, executable fixtures or external writes. Read-only narrow source probes are allowed under reviewer scratch rules. Report concrete findings with file:line evidence, swept file: yes/no, VERDICT: PASS|FAIL|PARKED and Basis. Every behavior-change Should/Blocker needs Observed input / Affected scope / Falsifier.

On approval set STATUS: Approved and NEXT: — and **done RELAY-GH1083-FINAL-20261015 --agent codex** using the env-pinned absolute tick. Never merely release on approval. Otherwise set NEXT: Producer and release to codex-producer. Harness owns the scoped commit. Cumulative cap 3 rounds.

### Reviewer · Round 1

Ship — approved for the bounded skill review; publication gate and post-merge deployment remain producer handoffs.

swept file: yes

VERDICT: PASS

Basis: Read all 725 lines of `skills/3-weekly/radar/SKILL.md`, the canonical plan, original issue snapshot and retained verification packet. Applied A–H independently to the supplied dated facts and controlled overlays. No blocking or required Should finding; no residual broad doc-wins rule found. Whole-file sweep found the optional pre-existing wording nit below, not an additional required fix. Reversibility: Easy, instruction-only change. SWE/ponytail review finds no need for a new mechanism.

Independent A–H decision report (all skill citations below refer to `skills/3-weekly/radar/SKILL.md`):

- [Pass] **A — state/membership:** At the retained observation time, #1083 is open, milestone null. The completed/Q4 overlay is doc drift, not closure/membership authority. Cite both sources; do not repair the doc. Evidence: `TESTS-RESULTS/2026-10-15+GH-1083/live-facts.json:15`, `:17`; skill:68–85,430–437.
- [Pass] **B — landing/retirement:** #1078 landed on development at the retained merge SHA/time; sampled #1082/#1079/#1062 are open and remain in flight. Neither the release-note overlay nor historical strike-through proves their landing, quiet, or retirement. A merge is not deployment and does not alone prove that a named defect was fixed. Evidence: `live-facts.json:37–45,65–85` in the same packet; skill:71–72,247–251,334–342,539–542,598–608,649–656.
- [Pass] **C — declarations/adoption:** The controlled governing GitHub declaration yields Transform; the conflicting doc Grow is drift. #1083's quoted classifier example is not a declaration about #1083. For these two supplied governing records, one has a genuine explicit declaration; that is bounded adoption coverage, not repository-wide adoption. Actual conflicting live declarations go to Unclassified; doc-only fallback is separately labelled when the governing live evidence is unavailable. Retain all five buckets and sum every commit exactly once; Harness remains separately excluded from the RGT denominator. Evidence: issue-source.json body quotes the old classifier while asking to change it; skill:126–143 explicitly supplies the five buckets, conflict/example rule and denominator.
- [Pass] **D — adopted policy:** Controlled adopted GitHub v2 governs at E1=20%; doc v1=30% is stale and unadopted v3=10% stays draft. With adoption/version evidence unavailable, disclose unverified policy/lower confidence; do not assert that any candidate is verified adopted. No convenient threshold selection. This preserves both draft-vs-adopted and newer-adopted-vs-stale-doc directions. Evidence: skill:367–385,387–401.
- [Pass] **E — kinship:** Two resolving URLs do not form a cluster when live evidence says infrastructure context/unrelated failures. If relationship evidence is unavailable, retain an unverified candidate hint and degraded confidence, not verified kinship or an exhaustive negative. Evidence: skill:74–85,175–189.
- [Pass] **F — full GitHub loss:** Mark the whole report degraded. Doc completion and Transform may appear only as explicitly unverified doc-reported fallback; no doc-only retirement or quiet/solved credit. No inaccessible Sink B update. Preview Sink A with limits, write only on confirmation. Evidence: skill:81–86,139–140,260–261,605–606,658–667.
- [Pass] **G — PROJECT loss:** Lose doc hints/context, doc-fallback RGT and the usual Sink A location. Accessible GitHub kinship and explicit RGT continue; offer repo-root Sink A subject to the same confirmation. Evidence: skill:85–86,575–576,660,668.
- [Pass] **H — partial GitHub loss:** Successful issue details support only those returned state facts. Failed timelines leave reopen counts unknown; truncated PR lists do not prove completeness or zero adoption in uncovered records. Label the whole report partially verified and name affected claims; no unsupported quiet/solved credit. Evidence: skill:81–85,133,200–208,260–261,644–655,676–677.

- [Pass] **Evidence comparison and scope:** The producer's A–H outcomes match this independent application (`TESTS-RESULTS/2026-10-15+GH-1083/manual-dry-run.md:7–14`). Its explicit limitation, "not an executable suite, full radar scan or guarantee about every future model response" (`:3`), is truthful. Textual baseline controls (`:18–24`) expose the old conflicting rules; they are not an executed baseline model. `provenance.jsonl:1–4` distinguishes the helper-clone prerequisite, manual exercise, format validation and docs-tier routing. These are retained producer receipts, not commands rerun by this reviewer. The plan's "Update only ... as the product payload" and explicit post-merge Skills Army handoff agree with skill-only scope; no script/test/registry/runtime mechanism is needed. No git/diff audit or full gate was run in this turn; final changed-path/publication checks remain the harness/producer's responsibility.
- [Nit] **Pre-existing tally explanation overclaims truncation detection:** skill:118–122 describes a 50-line view of a 548-commit history, then says "the sum check is the only thing that tells them apart." A 50-line truncated file can still have bucket counts summing to 50; that equality checks bucketing consistency, not source completeness. The following independent rev-list cross-check is the relevant completeness check. Optional prose correction: distinguish those two purposes, retaining the existing check rather than adding machinery. Source probe: `nl -ba skills/3-weekly/radar/SKILL.md | sed -n '1,245p'`, exit 0; decisive output: "capped `git log` at exactly **50 lines for both windows of a 548-commit repo**" and "Cross-check the total against `git rev-list --no-merges --count` as well". This nit does not invalidate the bounded authority decisions above.

Graph evidence limit: `list_projects` was paginated through all 84 projects; this worktree is not indexed. Nearest XYZ-forge graph generation is 2026-09-01T15:54:30Z; coverage returned skill `not_tracked` and task/evidence `missing`. Used direct full-source reads of these non-code files, not stale graph content. No reindex, source mutation, executable fixture, test suite, report sink, external write, merge or deployment was performed.

Relay closed (Approved), no further reviewer turn needed. Producer should run the normal publication gate, preserve this receipt and retain the post-merge Skills Army refresh handoff.


### Attestation · relay-drive — 2026-10-15T20:58:58Z
task: RELAY-GH1083-FINAL-20261015
reviewer: codex
status: Approved
reviewed-head: 2b182d1bda69ee61a66d838c497f22e062621be1
added-range: 8613+6596
added-sha256: 79b521ab1932068faf01e3bd81eda8afeaa7afbe824680721acbed4e22c97c1c
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
