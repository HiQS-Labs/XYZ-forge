# RELAY · GH-1620 flywheel review-rule final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1620-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/flywheel/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- What changed: one documentation block of 29 lines inserted into `skills/2-daily/flywheel/SKILL.md` directly under the heading `## Choose the work and answer the three rubrics`, above that section's first paragraph. See `git diff origin/development -- skills/2-daily/flywheel/SKILL.md` (the seeded `.relay-artifacts/SKILL.md` is the whole file at the reviewed head). The only other files in the diff are this relay thread. Issue: #1620 (read it with `gh issue view 1620 --repo HiQS-Labs/XYZ-forge`).
- Settled scope, not findings: the operator wrote the wording of the block and decided the rule (spike before more plan review; at most four review rounds per review loop; the orchestrating agent or operator overrides at the cap and records it; what an override never touches). Do not reopen the policy, the wording or the choice of rule. Grade only the three checks below.
- Definition of Done (the three checks):
  1. **Scope.** The rule applies only to Flywheel architecture and implementation work (the #1400 arc and the issues, plans and daily ledgers under it). Nothing in the diff changes any other skill's review limits, and the rule does not read as a repo-wide rule. Work Flywheel drives for other projects keeps each owning skill's limits.
  2. **Consistency with the rest of the Flywheel skill.** The block does not contradict Rubric 1A's "no silent cap, permission, safety, or gate changes" or step 4 of the Standing authorization ladder ("increases caps"). Its last paragraph says the rule is an explicit, recorded operator decision for this one project, so applying it is neither a silent cap change nor a cap increase. Check that this holds against the actual wording of Rubric 1A and of step 4 in the artifact.
  3. **No override can skip a protected control.** Nothing in the block lets an override, a spike or the "orchestrating agent decides at the cap" step skip red-then-green evidence on the real path, the push gate, safety/containment/attempt limits, or the operator's merge decision. Look for any phrase that could be read as letting an override waive one of them, including the pull-request clause in point 3 ("never recorded as approved").
- Proportion: this is skill documentation only, XYZ-forge forbids new tests (`AGENTS.md`, GH-831), and no script or test is expected. A finding that asks for a behaviour change must carry `Observed input:` (a quoted phrase with `file:line`), `Affected scope:` and `Falsifier:`. Wording preferences are not findings.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

VERDICT: PASS

Basis: The seeded skill satisfies all three scoped documentation checks. Read the entire 302-line artifact and issue #1620; no pre-existing defects were found within those checks. No wording or policy changes requested.

swept file: yes

- [Pass] Scope is explicit: `.relay-artifacts/SKILL.md:28–32` restricts the rule to Flywheel's own #1400 architecture/implementation arc and says other projects retain each owning skill's review limits. This agrees with the existing workflow ownership at lines 16–22 and unrelated-campaign boundary at lines 115–119. The inserted block does not purport to change another skill or establish a repo-wide limit.
- [Pass] The recorded exception is consistent with the existing ladder: lines 40–46 cap each review loop at four and require the override and reason on the issue; lines 52–53 identify the standing operator decision. Rubric 1A at line 67 forbids **silent** changes, while ladder step 4 at lines 109–113 still requires escalation for cap/spending increases and control bypasses. Applying the stated four-round limit neither authorizes a fifth round nor resets attempt allowances (lines 125 and 167–172).
- [Pass] Protected controls remain binding: lines 49–50 expressly preserve real-path red-then-green evidence, the push gate, safety, containment, attempt limits and the operator's merge decision. The spike at lines 34–39 is time-boxed disposable-clone evidence and “lands nothing by itself.” The final-review PR clause at lines 46–48 requires disclosed findings and says “never recorded as approved”; publication therefore supplies no approval. Existing exact-head QA and per-PR merge approval at lines 138–152 and 272–276 continue to apply.
- [Pass] Whole-file comparison: `cat .relay-artifacts/SKILL.md` exited 0; comparing its lines outside 26–54 with GitHub `fetch_file(repository_full_name="HiQS-Labs/XYZ-forge", path="skills/2-daily/flywheel/SKILL.md", ref="development")`, blob `ec26c5c11d2fdc4a6afe5b7262073503f3afbb0d`, using `[...lines.slice(0,25), ...lines.slice(54)].join("\n") === base.content` returned `true`. The seeded skill differs from that published file only by the 29-line block directly under the rubric-section heading at line 24.

Verification boundary: static documentation review only; no tests, executable fixtures or docs gate run, and no later gate assumed. This verdict does not certify merge readiness or a repository-wide changed-file inventory. Graph discovery found no index for this isolated checkout; nearest Forge index generation `2026-11-25T18:19:12Z` reported the seeded artifact and relay paths missing, so all review conclusions use the directly read local artifact rather than graph completeness.

Relay closed (Approved), no further turn needed. Token handoff: `done RELAY-gh1620-final-qa-r1 --agent codex` via the absolute env-pinned tick.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
