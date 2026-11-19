# RELAY · GH-1527 Plan QA: kickstart build_queue.py
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-19.
-->

NEXT: Producer
STATUS: Approved
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
6. **Manual relay: commit only the relay file** (`relay(gh1527-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1527-KICKSTART-BUILD-QUEUE.md` (the plan; no code yet)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-19
- Definition of Done: the plan satisfies issue #1527's requirements (listed in the plan's
  "Requirements" section) with the smallest design that works.

Operational envelope: a local, operator-invoked stdlib Python CLI (~200 lines) that prints Markdown.
No daemon, no writes to GitHub or the ledger. Machinery and checks must be commensurate. XYZ-forge
forbids new test suites (AGENTS.md, GH-831): verification is a manual check under `TESTS-RESULTS/`.

**Step A — paraphrase first (GH-1414).** Before opening any other file, read only the plan doc and
write 2–5 sentences each under **What this proposes** and **How the existing system works, per this
document**, plus a short **What it's not**. Label inference as inference.

**Step B — source-backed check.** Then read: `skills/2-daily/pr-minder/scripts/pr_minder.py` (its
`--json` row shape), `skills/1-hourly/kickstart/SKILL.md` (section 1 Parent), and `AGENTS.md`
(No new tests). Answer:

1. Does the plan reuse pr_minder's classification rather than re-implementing it? Is the one extra
   `gh pr list` call (author, title, body for issue links) justified by pr_minder's actual row keys?
2. Are the PR and issue ordering rules a closed, deterministic list that matches the issue's
   required order (CLEAN → CONFLICTING → UNKNOWN batch → drafts → small bugs → docs → stale batch →
   refactors → final QA; held/others'/decision/other-session → Needs-operator)? Flag any rule that
   can put an item in two buckets or none.
3. Is sending unclassified issues to Needs-operator (rather than guessing a bucket) the right
   conservative default, given the issue's labels are sparse?
4. Determinism: do the replay inputs (`--prs-json`, `--pr-meta-json`, `--issues-json`, `--as-of`)
   make output byte-identical for identical inputs? Anything time- or order-dependent left?
5. What prevents an unchanged, unbuilt candidate from being reported delivered? Is the planned
   manual check (diff vs the 2026-11-19 hand queue with each difference explained, determinism
   `cmp`, red control for held and non-owner PRs) a real rejection, not just a successful run?
6. Is anything over-built or missing for the stated envelope?

Cite `file:line` for disagreements. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis,
and set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes**

A local stdlib Python command builds a Markdown kickstart queue from pr_minder classifications and GitHub metadata. It orders PRs and recent issues by explicit first-match rules, diverts uncertain ownership or scope to the operator, and supports saved-input replay. Verification compares a live snapshot with the hand queue and checks deterministic output and held/non-owner routing.

**How the existing system works, per this document**

The parent currently assembles the queue by hand and records authority in a local run record. pr_minder already supplies PR state classifications but lacks author and body fields, so the plan adds one metadata query. Issue labels are sparse; the proposed issue categories therefore use title heuristics and explicit operator overrides.

**What it's not**

It is not a dispatcher, daemon, ledger writer or replacement PR classifier. Inference: a generated authority template still requires the parent to record an actual operator grant before dispatch.

**Call: Block pending two bounded plan corrections.**

- [Should] **S1 — apply explicit ownership/decision exclusions to PRs too.** Requirement 4 covers other-session-owned and decision-needed items (plan:35), but the PR decision list (plan:64–69) never consults the overrides; they appear only under Issues (plan:73–74). Define the existing override flags for both item kinds and place them before PR draft/state routing. No session discovery subsystem is needed.
  Observed input: the plan's PR rule 6, “otherwise → bucket A,” includes an own, non-held, non-draft clean PR even when its number is supplied in `--other-session`; only issue rule 1 consumes that flag.
  Affected scope: PR numbers explicitly supplied in `--other-session` or `--needs-operator`.
  Falsifier: replay one eligible own clean PR with and without its number in each override; without the override expect A, with either override expect Needs-operator and no queue entry. If another documented PR rule already enforces this, cite it and decline.

- [Should] **S2 — correct the PR input contract before implementation.** The plan calls `unknown` “mergeability not yet computed” (plan:43–48), but `pr_minder.py:201–219` computes it from author-history completeness and timestamp. Merge state is examined separately at `pr_minder.py:220–225`, and the JSON serializer excludes `pr_data` (`pr_minder.py:540–542`). Thus the present row cannot distinguish a mergeability-UNKNOWN PR from CLEAN solely through the listed flags. Correct the recon and explicitly decide whether C means author-history unknown or GitHub mergeability UNKNOWN; if the latter is required, describe the smallest source-backed way to obtain that state while retaining pr_minder as the classifier. Do not silently implement a second classifier.
  Observed input: `pr_minder.py:217` assigns `row["unknown"] = not (complete and ts)`; the plan's literal interpretation at line 45 disagrees with that assignment.
  Affected scope: PR routing to C versus the clean fallback A when history availability and mergeability differ.
  Falsifier: an own, non-draft, unheld PR with complete author history, mergeability UNKNOWN, no failing checks and no measured drift. Document its intended bucket and show the chosen input actually distinguishes it from CLEAN; also document a CLEAN PR with unavailable author history.

- [Pass] **Reuse and envelope:** author/body enrichment is justified: row construction keeps those inside `pr_data` (`pr_minder.py:199–200`), which JSON omits (`pr_minder.py:540–542`). A subprocess wrapper, fixed Markdown, and saved-input replay are proportionate (plan:96–106,115–125). Parent integration belongs between intake and dispatch (`skills/1-hourly/kickstart/SKILL.md:30–35`), preserving its explicit authority boundary at lines 49–50.

- [Pass] **Ordering/default:** first-match rules plus explicit fallbacks make the lists mutually exclusive and exhaustive within the selected issue window; the final sequence is literally “A → B → C → D → E → F → G → H → final QA” (plan:60–87). Sparse-label issues conservatively reach “Needs-operator (unclassified: operator picks scope)” (plan:84–85). These are sensible defaults, subject to S1/S2.

- [Nit] **Replay detail:** `--as-of` plus saved inputs and ascending item numbers supplies the main deterministic contract (plan:87,93–99). Pin the issue-window cutoff to that date, and render secondary sections/folded issue numbers in numeric order too. State that owner, exclusions and since-days are also replay inputs. This is a specification clarification, not a request for more machinery.

- [Should] **Acceptance evidence needs a short completion rule.** Plan:103–111 lists real output comparisons, not merely a successful invocation, but does not say unexplained/misclassified differences reject delivery; nor does it explicitly require the retained `provenance.jsonl` required by `AGENTS.md:162–168`. Add those two requirements and tie the receipt to the implemented candidate revision/command. Do not report the plan itself as delivered code. The held/non-owner cases are useful negative routing checks; record an assertion failure against a controlled wrong output to witness that the check can reject, rather than calling a passing routing example a witnessed red control.

**Review limits:** swept the entire plan, including recon, risks, rating and non-goals; the omissions above are in scope regardless of when introduced. This is plan QA, with no implementation or executed acceptance evidence to approve. No prohibited gate or executable fixture was run. Graph reference project `Users-noelsaw-Documents-GH-Repos-XYZ-forge` was ready at generation `2026-11-18T19:39:07Z`, but belongs to a different checkout; local source reads govern the citations here. Coverage reported no recorded gap for pr_minder, not proof of completeness.

swept file: yes
VERDICT: FAIL
Basis: The small design is appropriate, but PR overrides do not meet requirement 4 and the stated UNKNOWN input contract contradicts its source. Correct those and make the manual acceptance rejection/evidence rule explicit before building.

Handing off to Producer (claude-a) — disposition the findings and revise the plan.

### Producer · Round 1

Dispositions (plan revised in `PROJECT/2-WORKING/GH-1527-KICKSTART-BUILD-QUEUE.md`):

- **S1 — Accepted.** `--other-session` and `--needs-operator` now apply to PR and issue numbers
  alike and are PR rules 1–2, before held/author/draft/state routing. The acceptance check adds the
  falsifier as written: one own clean PR → A without overrides, Needs-operator with each override.
- **S2 — Accepted.** Recon corrected: pr_minder `unknown` is author-history availability
  (`pr_minder.py:217`), not mergeability, and is not used for routing. Bucket C now means
  pr_minder `behind` or GitHub raw `mergeable == UNKNOWN`, read from the same single
  `gh pr list` metadata call (adds the `mergeable` field; no new classification). Both worked cases
  from the falsifier are documented (UNKNOWN mergeability → C; CLEAN with unavailable author
  history → A).
- **Nit — Accepted.** Issue window pinned to `--as-of`; the full replay input set is named; every
  section renders in ascending number.
- **Should (acceptance) — Accepted.** Completion rule added: an unexplained difference or a
  rule-contradicting route rejects delivery. `provenance.jsonl` required, tied to the candidate
  commit and commands. The red control is now a routing assertion run against a deliberately wrong
  output, recorded failing.

Handing to Reviewer (codex) for round 2.

### Reviewer · Round 2

**What this proposes**

A local stdlib CLI prints a kickstart queue and authority template from existing PR classifications and one PR metadata enrichment, plus recent issues. First-match rules order work, hold explicit exclusions for the operator, and make saved-input replay possible.

**How the existing system works, per this document**

The parent currently assembles the queue manually and records the operator grant in a run record. pr_minder owns conflict, drift, checks, draft and hold assessment; its JSON omits raw PR metadata. Its `unknown` means unavailable author history, so the proposed enrichment separately supplies GitHub mergeability.

**What it's not**

It is not an executor, new PR classifier, daemon or ledger writer. Inference: printing the authority template does not itself grant authority; the parent must record the operator grant before dispatch.

**Call: Ship the plan.** Citations below use `plan` for `PROJECT/2-WORKING/GH-1527-KICKSTART-BUILD-QUEUE.md`.

- [Pass] **S1 resolved:** explicit session/decision overrides now precede every PR route (plan:66–74), and issue overrides precede folding (plan:88–90). The manual acceptance specifies both override cases and the clean control (plan:135–137).
- [Pass] **S2 resolved; classification stays with its owner:** plan:43–53 correctly separates author-history unknown from raw mergeability, consistent with `skills/2-daily/pr-minder/scripts/pr_minder.py:217–225`. The serializer omits `pr_data` at that file's lines 540–542, justifying the single metadata call. The two contrasting worked cases at plan:82–84 make the intended C/A distinction explicit without duplicating the classifier.
- [Pass] **Closed ordering and conservative default:** first-match PR/issue lists at plan:71–100 resolve overlaps by precedence; their explicit fallbacks cover the specified valid input contract. The required A through H and final QA sequence is at plan:102. Sparse-label issues reach Needs-operator at plan:99–100 rather than inferred execution scope. No additional bucket defect found in the whole-plan sweep.
- [Pass] **Replay contract:** plan:113–118 pins saved inputs, owner, exclusions, date and window and orders secondary lists. Read queue sorting there as ascending number within each bucket, as explicitly required by plan:102; bucket priority remains primary. No remaining wall-clock dependence is specified for saved-input replay.
- [Pass] **Acceptance can reject delivery:** plan:127–139 ties retained provenance and commands to the implemented candidate, rejects unexplained or rule-contradicting differences, requires byte comparison, and witnesses a failing routing assertion against deliberately wrong output. This is an acceptance design, not evidence that an unchanged/unbuilt candidate has been delivered.
- [Pass] **Proportionate integration:** plan:122–145 limits work to the CLI, parent instructions and retained manual evidence, consistent with AGENTS.md's “No new tests” rule. Parent intake/dispatch at `skills/1-hourly/kickstart/SKILL.md:30–35` is the appropriate insertion point; its explicit authorization boundary at lines 49–50 remains applicable. No further machinery is needed for the stated envelope.

**Review limits:** Swept the entire plan, including requirements, recon, output, implementation steps, non-goals, rollback, risks and rating; no additional pre-existing plan defect found. This approves design only: no implementation, runtime correctness, latency or executed acceptance result is claimed. No gate, fixture, live pr_minder invocation or git command was run. Verify-tier source checks used the explicitly named local files; the reference graph project `Users-noelsaw-Documents-GH-Repos-XYZ-forge` is ready at generation `2026-11-18T19:39:07Z` but belongs to another checkout. Coverage reports missing freshness for the plan and kickstart skill; direct local reads govern those claims. No recorded graph gap is not proof of completeness.

swept file: yes
VERDICT: PASS
Basis: The bounded corrections address the prior findings. The plan now defines source-backed routing, deterministic replay and candidate-bound rejection evidence at a scale appropriate to a local Markdown-producing CLI.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-19T23:07:43Z
task: RELAY-gh1527-plan-qa
reviewer: codex
status: Approved
reviewed-head: f455d9c6a3bf04f181defab03654d031b5d3a6bd
added-range: 15880+4315
added-sha256: a8807334e74b66bc93ce60bb55580b319973cacb13a5254cbbc048798b218965
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
