# RELAY · GH-336 planning-context phasing review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-29.
-->

NEXT: none — closed by operator decision (escalation triaged, fix-forward applied)
STATUS: Closed
ROUND: 4 / 4

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
6. **Commit only the relay file** (`relay(gh336-planning-context-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md` — read it in the worktree; do
  NOT edit it. This is a review-only turn (`ALLOW_PATHS=""`); append findings to this relay file only.
- Supporting context you may READ (not under review): RELEASES.md, utils/marathon-plan.sh,
  utils/swarm-preflight.sh, skills/10days/, AGENTS.md, PROJECT/GUIDING-PRINCIPLES.md.
- Producer's pre-read (verify it yourself, don't take it on faith): the doc's line 29 claims this
  proposal "consumes the existing RELEASES.md and utils/release-lanes.sh seed|rollup foundation".
  RELEASES.md exists (34 lines). A repo-wide search found NO utils/release-lanes.sh and no other
  reference to it anywhere in the tree. Confirm or refute, and grade the consequence for Phase 1's
  "lightweight" claim.
- Reviewer: codex (round 1)   ·   agy (rounds 2–3, independent QA)   ·   pi/qwen3.8-max-preview
  (round 4, third-model adversarial pass)   ·   Producer: claude-a
- Started: 2026-07-29
- **Round-2 charge (agy — read this instead of the round-1 Definition of Done, which is now answered).**
  The Producer revised the artifact in response to round 1. QA the REVISED doc. Your tie-breaker is
  `GUIDING-PRINCIPLES.md` — cite the principle number for every finding, and say plainly when the doc
  cites a principle it does not actually satisfy. Specifically:
  1. **Does the reversibility claim now hold mechanically?** The doc asserts `--planning-context=off`
     yields a byte-identical plan doc AND fire list, and names a three-file removal seam. Attack that:
     is any part of it untestable as written, and does the stickiness closure table have a hole?
  2. **Is the architecture decision right?** The Producer decided Python-only, standalone
     `utils/py/planning_context.py`, touching neither `utils/marathon-plan.sh` nor
     `utils/py/_marathon_plan_node.js`. Verify the triple-maintenance evidence yourself
     (`utils/py/marathon_plan.py` head comment; `AGENTS.md` frozen-twin section). Does an additive
     append-a-section module actually work at that seam, or does it need the render path after all?
  3. **Are the rewritten acceptance criteria falsifiable?** For each, name the test that could fail it.
     Flag any that is still prose. Check the `off` byte-identical criterion is not self-contradictory
     given that `auto`/`on` append a section to the same doc.
  4. **Did the revision introduce NEW problems?** Default mode `auto` changes today's default behavior;
     the 14-day window; the churn exclusion list; the in-doc Phase 2 evidence table (is that "new
     persistent state" in breach of the doc's own non-goal, or is it P9 doc-as-runtime-state?).
  5. **Is Phase 0 correctly scoped**, and is a 3-phase split still the right shape?
  Grade every finding, cite `file:line` for anything you call verified, and give a Verdict.
- **Round-4 charge (pi + qwen3.8-max-preview — read THIS, not the earlier charges, which are answered).**
  You are the **third** model on this artifact. Codex reviewed round 1; agy reviewed rounds 2–3 and
  Approved. Your job is NOT to re-run their checklists — it is to find what two models that already
  agreed with each other **both missed**. Read
  `PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md` in full, and the whole Log below, then:
  1. **Attack the consensus.** Codex and agy both endorsed the Python-only standalone-module decision
     and the `off`-is-default kill switch. Assume one of those is wrong. Which, and why? Verify the
     evidence yourself — `utils/py/marathon_plan.py` (does an append-a-section module actually have a
     seam to attach to, or does the plan assume a hook that does not exist?), `AGENTS.md` frozen-twin
     section, `utils/marathon-plan.sh`.
  2. **Is this plan actually buildable as written?** You are the first reviewer being asked this
     directly. Name anything a builder would hit that the doc does not answer — a missing function,
     an undefined output format, an unstated ordering dependency, a test fixture that cannot exist.
  3. **Check the arithmetic of the claims.** The doc asserts `off` is byte-identical to today AND that
     `auto`/`on` append a section to the same file. It asserts execution artifacts are byte-identical
     across all three modes. Is there any input under which those cannot all be true at once?
  4. **Churn rules sanity.** Threshold 3+ distinct commits, depth-2 directory unit, must link ≥1
     issue/PR, documentation paths excluded. At this repo's real commit volume, would that produce
     useful signal or noise? Check actual `git log` if useful.
  5. **What is missing entirely?** Not "phrased weakly" — genuinely absent. Be specific.
  Grade every finding (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), cite `file:line` for anything you call
  verified, include the literal `swept file: yes|no` line, and give a Verdict. **A finding that merely
  agrees with rounds 1–3 is worth less than a real disagreement — if you genuinely find nothing new,
  say that plainly rather than padding.**
- Definition of Done (rounds 1–3, now answered — kept for the record):

  **Q1 — Is Phase 1 lightweight, worthwhile, AND usable from day one without strong contracts?**
  - Lightweight: can Phase 1 be built as a read-only synthesis over sources that ALREADY exist
    (`RELEASES.md`, `utils/release-lanes.sh seed|rollup`, `gh` issue/PR/commit data, `git log`)?
    Name any place the doc implicitly requires new state, a cache, a schema, or a service despite
    the stated non-goal. Estimate the real surface: which files/scripts would change, roughly.
  - Worthwhile: would the four signals (release alignment, delivery arc, issue themes, churn)
    actually change an operator's planning decision, or are they decoration? Call out any signal
    that is likely low-value or unreliable at this repo's data volume, and say so plainly.
  - Usable day one WITHOUT strong contracts: with NO milestone hygiene, NO issue labels/taxonomy,
    and messy real data, does Phase 1 still degrade to something useful — or does it collapse into
    "unresolved" everywhere and become noise? Identify the minimum it must still print to earn its
    place in the output.

  **Q2 — Is Phase 2 genuinely reversible if it turns out to be too many hoops in practice?**
  - The doc claims Phase 2 "remains opt-in and must retain that escape hatch." Test that claim.
    Name every mechanism by which Phase 2, once shipped, could become de-facto mandatory or sticky
    (deterministic findings that operators start treating as gates, a versioned context shape other
    tooling begins to depend on, milestone-verification failures blocking a run, doc/CI drift,
    vendored `.xyz/` copies, `/10days` auto-fire coupling).
  - State what the doc would need to say to make "turn it off and nothing breaks" verifiable rather
    than aspirational — e.g. a named kill switch, a regression test asserting identical output with
    the feature off, a stated removal path.

  **Q3 — Are the acceptance criteria right and complete?**
  - For each existing criterion in both phases: is it falsifiable (can a test actually fail it), or
    is it prose that always passes? Flag every unfalsifiable one and propose a concrete replacement.
  - Name any MISSING criterion the phases need — especially anything covering the doc's own stated
    failure mode ("analysis silently changes scheduling or `/10days` auto-fire behavior") and its
    reversibility claim.
  - Flag any criterion that belongs in the other phase, or that is really a non-goal in disguise.

  **Also required:** a short list of the questions the operator has NOT yet answered but must, before
  Phase 1 can be built. Be blunt; if the phasing itself is wrong, say so.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · round 1

swept file: yes

- [Blocker] The Phase 1 foundation claim is false: `utils/release-lanes.sh` is absent, while the proposal says it already supplies `seed|rollup` ([GH-336:28-30](PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:28)). This makes “small read-only synthesis” materially underspecified: it needs new collectors/rendering in at least `utils/marathon-plan.sh`, `skills/10days/SKILL.md`/its implementation seam, focused tests, and likely the release-ledger helper—not merely an overlay. Fix: delete that claim and name the exact producer, output location/flag, source commands, and file/test budget; otherwise split “build the missing release rollup” into an explicitly scoped prerequisite.

- [Should] **Q1 — lightweight, worthwhile, usable day one:** as written, no on lightweight (missing foundation and no defined output seam). Yes, conditionally, on worthwhile: release alignment and delivery arc can alter grouping/defer decisions, and churn can prompt a human investigation; issue themes are low-confidence without taxonomy and churn is noisy at this repo’s volume unless path exclusions/thresholds are specified. It can be usable without contracts only if it always prints: selected release/milestone or `unresolved`, candidate count/list and receipts, fixed analysis window, and an explicit “no theme/churn signal” result—never a screen of bare `unresolved`. Fix: add those fallback rows plus bounded source/time-window/threshold rules and make all recommendations advisory.

- [Blocker] **Q2 — Phase 2 reversibility:** “opt-in”/“escape hatch” is aspiration, not a testable off-ramp ([GH-336:44-46](PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:44)). It can become sticky through a default-on `/10days` forwarding path (which intentionally fires unattended), consumers depending on the versioned context shape, milestone-validation failures treated as run gates, copied/vendored `.xyz/` behavior, and CI/docs drifting to require it. Fix: name a default-off `--planning-context=off` kill switch propagated through marathon and `/10days`; state that off emits today’s byte-identical plan/fire behavior and skips all milestone calls/findings; name the removal/revert seam; add fixtures proving off versus baseline identity and an `/10days` dry-run proving no added auto-fire decision.

- [Should] **Q3 — Phase 1 criteria:** “every claim has evidence/window” and “release is optional/unresolved” are directionally testable but lack a fixture schema and exact output; “identical candidate set…fire list” is the right invariant but needs a baseline-vs-enabled golden test across `marathon-plan`, preflight, and `/10days`; “no verbs/service/cache/gate” is an unbounded architectural assertion; and the green-gates line can pass without testing the new behavior ([GH-336:71-80](PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:71)). Fix: replace each with fixture-backed assertions for required receipt fields, no-release/messy-data output, byte-identical execution artifacts, and a scoped static/runtime no-new-persistence/no-new-tick-verb check; retain the gates only as verification, not behavior acceptance.

- [Should] **Q3 — Phase 2 criteria:** all five are partly prose: “scoped/no impact,” “sole join key,” “continue unchanged,” and “records alternatives” have no named interface, fixture, or negative case; “cannot be auto-fired” does not trace the `/10days` firing path ([GH-336:98-106](PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:98)). Fix: specify enabled/off invocation fixtures, malformed/missing selected-milestone exit/result behavior, an unchanged ordinary-plan golden output, an allowlist/preflight regression fixture, a required refactor-capture schema, and a test that `/10days` never includes a churn/refactor recommendation in its fire list. Add explicit kill-switch/removal acceptance criteria; the broad no-cache/no-new-service rule belongs in Phase 1, while versioned-shape compatibility belongs in Phase 2.

- [Should] Operator decisions still required before Phase 1: the owning command/output and default switch; the exact source/time window and offline/`gh` failure behavior; what counts as a meaningful churn recurrence and which paths are excluded; how a human selects a release when `RELEASES.md` has placeholders/missing fields; the definition and evidence record for a “material” miss; and whether `/10days` may display the overlay before its auto-fire check or must suppress it entirely on uncertainty.

Pre-existing sweep: no additional defects found outside the findings above.

Verdict: Changes requested.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · claude-a · round 2

Dispositions for every round-1 finding, then the revision. Operator answered three of the six open
questions directly; the rest are my judgement calls, tie-broken against `GUIDING-PRINCIPLES.md`
(cited inline in the doc as `(P<n>)`).

**Operator decisions applied**
- Churn recurrence = **3 or more**.
- Absent/unusable release → **feature-not-activated, pass-through mode** (not a wall of `unresolved`).
- **Python-only wherever possible**; Bash is a tech-debt nightmare. AGENTS.md + GH-308 codify this
  "unless there is an important exception."

**Findings**
- [Blocker: false foundation] — **Implemented.** Confirmed: no `utils/release-lanes.sh` anywhere in the
  tree. Removed the claim entirely rather than replacing it — Phase 1 reads `RELEASES.md` directly, so
  no release helper is needed and no prerequisite build is created. Added a doc-only **Phase 0** to
  correct the record, delete the live `Release: 0.1.0` EXAMPLE block, and resolve the dangling
  `related: GH-334` (which has neither a `PROJECT/**` doc nor a `ROADMAP.md` line).
- [Blocker: Phase 2 reversibility] — **Implemented.** Replaced aspiration with mechanism: a three-mode
  `--planning-context=auto|on|off` switch where `off` is a hard kill switch producing a byte-identical
  plan doc and fire list; a named removal seam (three files, nothing else references them); and a
  closure table addressing each stickiness vector you named. `/10days` coupling is closed by
  computing the context only *after* the fire list is frozen, asserted by test.
- [Should: Q1] — **Implemented.** Named the exact seam, output location, and default. Graded the four
  signals honestly: release alignment has real data day one (`RELEASES.md` already carries
  `Milestone:` from GH-284 Phase 3); issue themes is the weakest and now prints only when it can name
  ≥2 issues sharing a concrete artifact path; churn is bounded by a 3+ threshold, a depth-2
  sub-module unit, a required issue/PR link, and an explicit documentation-path exclusion list. Window
  fixed at 14 days (deliberately wider than a `/10days` sweep so a boundary signal isn't lost).
- [Should: Q3 Phase 1 criteria] — **Implemented.** Every criterion now names a runnable check. The
  unbounded "no event-log verbs / service / cache / gate" assertion became a scoped no-new-persistence
  diff check. The `validate.sh` / `pdda.sh run` line is explicitly demoted to *verification only, not
  behavior acceptance*.
- [Should: Q3 Phase 2 criteria] — **Implemented.** All five rewritten as fixture-backed assertions,
  plus the two you said were missing: off-parity survival and provable removal. Moved versioned-shape
  compatibility into Phase 2 and kept the no-new-persistence rule in Phase 1, as you recommended.
- [Should: operator decisions still required] — **Implemented/Modified.** Three answered by the
  operator; I decided window, `gh`-failure behavior, churn exclusions, release-selection rules,
  `/10days` suppression, and the evidence record. Three genuinely operator-only questions remain
  listed at the foot of the doc (default mode, whether to ship issue themes, Phase 0 ledger scope).
- **Unverifiable Phase 2 start condition** — **Added (not in the round-1 findings).** "Three real
  planning runs" could never be audited, so it is now a dated evidence table inside the doc, empty by
  construction. No rows, no Phase 2.

**Producer finding the reviewer did not raise — the load-bearing architecture decision.** The overlay
ships as a new Python-only `utils/py/planning_context.py`, called only from `utils/py/marathon_plan.py`,
touching neither `utils/marathon-plan.sh`, its embedded JS engine, nor `utils/py/_marathon_plan_node.js`.
Evidence: `utils/marathon-plan.sh` is GH-308's one *named* dual-maintained exception
([AGENTS.md:96-97](AGENTS.md:96)), but in practice it is **triple**-maintained —
`utils/py/marathon_plan.py:10-21` states it delegates rendering to `utils/py/_marathon_plan_node.js`,
a 46 KB hand-maintained *copy* of the Bash JS engine "that has drifted on two points," carrying two
standing parity shims, and already repaired once by a dedicated parity marathon (GH-154,
`relay-system/2026-07-16/marathon-gh154-marathon-plan-parity-225134.md`). There is no sync mechanism.
Putting new logic in that render path would triple-maintain it. A standalone additive module inherits
none of that drift, needs no `Frozen-twin-exception:` trailer, and leaves the Bash lane as a free
permanent oracle for "feature off" (P6, P7).

Revised artifact: `PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md` (now 3 phases; risk 3 → 2 on the
strength of the structural kill switch).

Handing off to Reviewer — agy takes round 2 as an independent QA pass (P12, separated grading): does
this revision survive `GUIDING-PRINCIPLES.md` as the tie-breaker, and did the Producer's own
architecture decision and criteria rewrite introduce anything new?

### Reviewer · agy · round 2

swept file: yes

- [Should] **1. Does the reversibility claim now hold mechanically?** The `off` kill switch and removal seam are mechanically sound (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:180-181). However, the stickiness closure table has a hole: "Consumers depend on the versioned shape" relies on the assertion "no other tool may read it" (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:227), which is prose, not mechanism. Fix: Add a Phase 2 criterion asserting a `grep` check in CI that finds no downstream parser of the new section in `utils/` or `relay-automation/`.
- [Pass] **2. Is the architecture decision right?** Yes. The Python-only standalone module avoids triple-maintenance. `utils/py/marathon_plan.py` delegates rendering to the un-synced `_marathon_plan_node.js` (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:68-74); appending the section after rendering is the only seam that satisfies P6 and P7.
- [Pass] **3. Are the rewritten acceptance criteria falsifiable?** Yes. Every criterion maps to a testable condition or diff. The `off` byte-identical rule does not contradict `auto`/`on`, because the execution invariance criterion correctly specifies only the candidate set, waves, and fire list (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:176-179) as invariant, not the appended advisory section itself.
- [Should] **4. Did the revision introduce NEW problems?** Yes. Defaulting to `auto` violates P1 (a primitive that reaches out can fail or leak) by forcing `gh` calls into every ordinary run. Fix: Change default to `off`. Require explicit `--planning-context=auto` so it stays opt-in until proven worthwhile. The Phase 2 evidence table (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:253) correctly uses doc-as-runtime-state (P9), not a new persistent cache.
- [Pass] **5. Is Phase 0 correctly scoped, and is a 3-phase split still the right shape?** Yes. The 3-phase split separates cleanup, advisory reads, and deterministic contracts. Deleting the unused `Release: 0.1.0` placeholder and dangling `GH-334` reference (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:96-101) directly satisfies P7 (deleting code counts as progress) and P9 (docs and reality must agree).

**Operator questions answered:**
- [Should] **Default mode:** As noted above, change the default to `off`.
- [Should] **Issue themes:** Since it is admittedly the "weakest" and "lowest-confidence signal", including it risks polluting the output and violating the "worthwhile" standard of Phase 1. Fix: Defer issue themes entirely from Phase 1 and ship only the three high-confidence signals.
- [Unverified — no citation] **Phase 0 scope:** Yes, cleaning up the ledger is in scope here rather than a separate PR.

Verdict: Changes requested.

Handing off to Producer — go to the claude-a window and say "take your turn".

### Producer · claude-a · round 3

All three round-2 `[Should]`s accepted and implemented. No declines.

- [Should 1 — stickiness hole] **Implemented.** You were right that "no other tool may read it" was
  prose wearing a mechanism's clothes. The closure table row now names an enforced CI grep over
  `utils/` and `relay-automation/` for any parser of the `## Planning context (advisory)` section, and
  it is a Phase 2 acceptance criterion in its own right rather than only a table cell.
- [Should 4 — default `auto` violates P1] **Implemented, and this was the real catch.** The doc cited
  P1 to justify `gh`-failure handling while defaulting to a mode that reaches out on every ordinary
  run — exactly the "cites a principle it does not actually satisfy" failure the round-2 charge asked
  you to look for. Default is now `off`. Added the reasoning inline so it is not re-litigated, plus
  the two consequences: day-one usability is unaffected (one flag), and `/10days` may opt in
  explicitly for its report step only, after its fire list is frozen. The kill-switch criterion now
  also asserts the **no-flag** invocation is byte-identical and issues zero `gh` calls, verified with a
  `gh` stub that fails loudly if invoked.
- [Should — issue themes] **Implemented.** Deferred out of Phase 1 entirely; Phase 1 now ships three
  signals. Grounded in the *Relevant* pillar rather than in either reviewer's preference, and scoped as
  "out until a real run shows the other three left a grouping decision unanswered" so it is not
  silently reopened as a design task.
- [Pass ×3] Noted: architecture decision, criteria falsifiability, and the Phase 0 / 3-phase shape all
  confirmed with citations. The `off`-byte-identical vs `auto`/`on` non-contradiction you checked is the
  one I most wanted a second pair of eyes on, so thank you for reading it closely.
- [Unverified — no citation: Phase 0 scope] **Not adopted as settled.** You self-flagged it uncited and
  you were right to — whether to edit `RELEASES.md` from this issue is an operator call, not a
  reviewer's. It is now the single remaining open question in the doc.

Net effect on the artifact: four signals → three; default `auto` → `off`; one prose assertion → one CI
check; one operator question left instead of three.

Handing off to Reviewer — agy takes round 3. Narrow charge: confirm these three fixes landed as
described and introduced nothing new, then Approve or say what still blocks. Do not re-open the
round-2 `[Pass]` items unless the round-3 edits changed them.

### Reviewer · agy · round 3

swept file: yes

- [Pass] **1. Stickiness hole:** The CI grep check over `utils/` and `relay-automation/` was properly added to the closure table (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:244) and formalized as a Phase 2 acceptance criterion (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:255-257).
- [Pass] **4. Default mode:** The default mode was successfully changed to `off`, the inline rationale included, and the kill switch criterion (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:197-199) was updated to assert the no-flag invocation is byte-identical and issues zero `gh` calls.
- [Pass] **Issue themes:** Issue themes have been cleanly deferred out of Phase 1 (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:162-167) and the overall signals are reduced to three.
- [Pass] **Phase 0 scope:** This remains explicitly listed as the single open operator question (PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md:305-308), correctly delegating the decision.

All requested changes landed cleanly. No new issues were introduced.

Verdict: Approved.

relay closed (Approved), no further turn needed

### Reviewer · pi (qwen3.8-max-preview) · round 4 — third-model adversarial pass

swept file: yes

Charge: find what codex (r1) and agy (r2–3, Approved) both missed. I verified every claim against the
code myself rather than re-running their checklists. Net: the **design is sound** (Points 1 and 3
confirmed independently), but the **acceptance criteria that are supposed to PROVE the safety claims**
have real holes both prior models waved through. Five `[Should]`, two `[Nit]`, two verified `[Pass]`.

**1. Attack the consensus.**
- [Pass] The Python-only standalone-module decision is correct, and I confirmed the seam actually
  exists rather than trusting the doc: `_inject_review_lanes` (utils/py/marathon_plan.py:195-216)
  ALREADY appends a `## Review lanes` section post-render, called at marathon_plan.py:376 after the
  node render and before the check/write branch. `planning_context.py` hooks that identical point —
  the doc is not assuming a hook that does not exist. Triple-maintenance avoidance is real:
  AGENTS.md:96-97 names `marathon-plan.sh` the one dual-maintained exception, and
  marathon_plan.py:10-21 documents the drifted 46 KB node copy plus two standing parity shims. The
  consensus holds; this is an independent confirmation, not an echo.
- [Should] **(headline — borders Blocker)** The load-bearing kill-switch criterion
  (GH-336-PLANNING-CONTEXT.md:199-202) asserts the no-flag/`off` invocation "neither issues a single
  `gh` call (asserted with a `gh` stub that fails loudly if invoked)." That is literally false against
  the real base planner: the node engine calls `gh` in its ORDINARY render path — `gh auth status`
  (utils/py/_marathon_plan_node.js:241) and `gh issue view` per issue (:248) — wholly independent of
  the overlay. In live mode a loud-fail `gh` shim fires on the BASE planner before the overlay is
  reached, so the test fails in `off` mode for a reason that has nothing to do with the feature. It is
  buildable ONLY under the hermetic seam the existing suite already uses — `QUEUE_PLAN_GH_STATE_FILE`
  (test/marathon-plan.sh:49; resolveGh returns in stub mode before any gh-binary call,
  _marathon_plan_node.js:236-238) — which the criterion does not name. It also conflates "zero overlay
  gh calls" with "zero gh-binary calls." agy [Pass]'d this at round 3. Fix: state the fixture runs
  under `QUEUE_PLAN_GH_STATE_FILE` (or `QUEUE_PLAN_GH=off`) so the base planner makes no gh-binary
  call, and scope the loud-fail shim to the overlay's `gh issue list --milestone` specifically.

**2. Is it buildable as written?**
- [Should] The `/10days` coupling is not mechanically testable and breaks the removal seam. `/10days`
  is a PROSE SKILL (skills/10days/SKILL.md; fire list frozen at Step 6, report at Step 8), not a
  deterministic binary — there is no `/10days` executable to "dry-run … asserted with a stubbed `gh`
  state file" (GH-336-PLANNING-CONTEXT.md:206-208). The testable surface is marathon_plan +
  swarm_preflight, already covered by Execution invariance (:195). And to make `/10days` emit the
  overlay, an agent must be instructed via skills/10days/SKILL.md — a FOURTH file the 3-file removal
  seam omits (:241, "nothing else references it"), and which the "no downstream parser" CI grep does
  NOT cover (it greps only `utils/` and `relay-automation/`, :248 and :259 — `skills/` escapes it).
  Fix: either name skills/10days/SKILL.md in the removal seam and widen the grep to `skills/`, or
  declare the `/10days` hook a doc-only instruction outside the code-removal seam and re-cast the
  criterion as "the SKILL instructs computing context only after Step 6," verified by reading the
  skill, not a stub run.
- [Should] The advisory-section row format is undefined. "Appended … as one `## Planning context
  (advisory)` section" (:114-115) with "claim rows" carrying source+window, and a test that "a fixture
  with a claim missing either fails" (:211) — but no row grammar (table? bullets? which columns?).
  Two builders would emit incompatible formats and the receipt-structure test cannot be written
  without one. Fix: pin the row shape (e.g. a 3-column `claim | source | window` table). Also pin the
  one residual ambiguity from Point 3: `on` with a NON-gh precondition failure (no release resolves,
  `gh` reachable) is not explicitly held to "emit the `off` doc + stderr reason" the way the gh-fail
  case is (:210).
- [Nit] The removal seam understates the `marathon_plan.py` surface: besides "its call site," the
  feature adds three flags (`--planning-context`, `--release`, `--context-window`, :147,:183) to an
  arg parser that currently `die()`s on any unknown argument (marathon_plan.py:280-282), plus usage
  text. "Delete three files, nothing else references it" should read "…and revert the marathon_plan.py
  call-site, arg-parser, and usage additions."
- [Nit] Ordering of the two post-render mutations is unstated: `_inject_review_lanes` inserts BEFORE
  the `## How to fire a lane` anchor (marathon_plan.py:210). State that planning_context appends at
  END (the safe choice — see Point 3).

**3. Arithmetic of the claims.**
- [Pass] The three claims CAN all hold at once, and I verified the mechanism, not just the prose. The
  fire list is the mid-doc `**Wave N:** #a ‖ #b` lines (utils/py/_marathon_plan_node.js:805), emitted
  BEFORE any end-append and kept grep-stable by design (GH-69 comment, node:803-804; test/marathon-plan.sh's
  `wave_of` greps that exact line). `## How to fire a lane` (node:856) is human instruction (a command
  code-block), not a machine-parsed list — relay-automation/marathon-drive.sh consumes relay
  files/phases/ESCALATION.md, never the plan doc's fire section. So an end-appended advisory section
  cannot change what fires; `off` (no append) is byte-identical while `auto`/`on` differ only by the
  trailing section. agy's round-2 non-contradiction [Unverified — no citation] is correct; I confirm it with the
  firing-path evidence the charge asked for. No input makes all three claims false at once.

**4. Churn rules at this repo's real volume.**
- [Should] Uncalibrated — would saturate and double-report. Measured over the last 14 days: 537 total
  commits; `utils/py/` = 40 distinct commits (`git log --since="14 days ago" -- utils/py/`; 55 by
  depth-2 name-only count), `relay-automation/` = 59. Against the ladder watch(3–4)/investigate(5–7)/
  consider-refactor(8+) (GH-336-PLANNING-CONTEXT.md:177), the primary code directory sits PERMANENTLY
  at "consider bounded refactor" — the signal fires every run forever, which an operator learns to
  ignore (the noise codex warned of in round 1, only partially addressed). Worse, `utils/py/` churn
  right now IS the GH-308 "Phase out Bash" migration tracked under the Quicksilver milestone
  (RELEASES.md:27-34) — so churn would flag exactly the directed, release-aligned work the
  release-alignment signal already surfaces: double-reporting known work. And the commit→issue linkage
  rule ("Must link ≥1 issue or PR," :179) is undefined — a subject-only parse gives 6 linked commits
  (→investigate) while a whole-message parse gives 40+ (→refactor); the rung swings on an unstated
  rule. Fix: flag churn only RELATIVE to a trailing baseline (unusual vs norm) instead of an absolute
  count, or raise the ladder to match measured volume; and pin the linkage-parse rule.

**5. Missing entirely.**
- [Should] (latent) The `--check` drift-guard interaction is never addressed. The advisory section
  goes into the SAME committed doc (:114-115). `marathon_plan.py --check` re-renders with the DEFAULT
  (`off` → no section) and `cmp`s against the committed doc (marathon_plan.py:378-391); a plan written
  with `on`/`auto` then checked with default `off` reports FALSE drift. marathon-plan.sh:54 documents
  `--check` as "a drift guard in validate.sh" (not currently wired — validate.sh:119 runs
  test/marathon-plan.sh, no `--check` loop — so latent, not active). Fix: emit the advisory section to
  a SEPARATE sidecar file (e.g. `MARATHON-PLAN-<date>.context.md`) — this simultaneously removes the
  drift hazard, sharpens the removal seam, and makes "off plan doc byte-identical" true regardless of
  mode.

**Pre-existing sweep (files GH-336 will touch):** read marathon_plan.py, the relevant spans of
_marathon_plan_node.js and marathon-plan.sh, RELEASES.md, skills/10days/, test/marathon-plan.sh, the
relevant spans of validate.sh, and the AGENTS.md frozen-twin section. One pre-existing doc/reality
disagreement, OUT of GH-336 scope: marathon-plan.sh:54 claims `--check` is a drift guard in
validate.sh, but validate.sh does not wire it (no `--check` invocation) — a separate hygiene fix, not
introduced here. No other pre-existing defects found in the touched files.

Verdict: Changes requested — **escalated.** This is round 4/4. I cannot certify reversibility as
"structural, not aspirational" while (a) the load-bearing kill-switch test is mis-specified against
the real base `gh` path (finding 1), and (b) the `/10days` "asserted by test" coupling is not
mechanically testable and its seam escapes both the removal list and the CI grep (finding 2). The
design itself is sound — Points 1 and 3 are verified `[Pass]`es — so this is not a redesign; the
defects are in the criteria that PROVE the safety claims. No Producer round remains, so this escalates
to the operator: tighten the five `[Should]`s when the build lane is cut (fix-forward), or reopen for
a criteria pass. My recommendation is fix-forward — the architecture needs no change.

Handing off to the OPERATOR (relay escalated at the final round; token returned to claude-a for
triage) — decide fix-forward vs reopen. No automatic Producer turn remains.

### Producer · claude-a · round 4 disposition (post-escalation, operator-authorized fix-forward)

The relay escalated at the round cap, so this block is filed under explicit operator authorization
rather than an automatic Producer turn. The operator chose **fix-forward** and decided the two design
questions round 4 opened. **All five `[Should]`s and both `[Nit]`s implemented. Nothing declined.**

Before acting I re-verified round 4's load-bearing claims against the code myself rather than taking
them on faith — a reviewer this sharp is exactly the one worth checking, and all of it held:

- `gh auth status` at `_marathon_plan_node.js:241` and `gh issue view` at `:248`, gated only by
  `QP_GH_FORCE=off` / `QP_GH_STATE_FILE`. **Confirmed — my criterion was false.**
- `_inject_review_lanes` at `marathon_plan.py:195`, called post-render before the check/write branch.
  **Confirmed — the seam exists.**
- `--check` does `cmp -s render_out queue_doc` at `marathon_plan.py:378-391`. **Confirmed — false-drift
  hazard is real.**
- Churn volume: **538** commits/14d, `utils/py/` **40**, `relay-automation/` **59**. **Confirmed** (I
  measure 538 where round 4 said 537 — a one-commit drift from measuring minutes later, not an error).

**Dispositions**

- [Should 1 — kill-switch `gh` claim false] **Implemented.** This was the best finding of the whole
  review: I had conflated "zero overlay `gh` calls" with "zero `gh` calls," and agy `[Pass]`'d it. The
  criterion now scopes the loud-fail stub to `gh issue list --milestone` only, and a new preamble makes
  the hermetic seam (`QP_GH_STATE_FILE`) a **precondition for every fixture**, not a footnote. Added an
  explicit correction paragraph in the body so the false claim can't be re-derived from the old prose.
- [Should 2 — `/10days` untestable + seam escape] **Implemented.** Correct on both counts: `/10days` is
  prose, so "dry-run … asserted with a stubbed `gh` state file" described a binary that does not exist.
  Recast as an assertion about `skills/10days/SKILL.md`'s step ordering, verified by reading the skill.
  `skills/` added to the removal seam **and** to the no-parser grep scope — the original two-directory
  grep let the one file that references the feature escape, which you caught and I did not.
- [Should 3 — row format undefined] **Implemented.** Pinned a four-column `Claim | Kind | Source |
  Window` table, with `Kind ∈ {fact, inference}`. That last column is load-bearing beyond formatting: it
  turns the *Attested* pillar into something a test can fail, since an unlabelled synthesis now breaks
  the receipts fixture. Also pinned the `on` + non-`gh` precondition-failure case you flagged as the
  residual ambiguity.
- [Should 4 — churn uncalibrated] **Implemented, operator-decided.** Your measurement demolished the
  flat 3+ rule, and the double-reporting observation (that `utils/py/` churn *is* the GH-308 Quicksilver
  migration) was the part I'd have missed entirely. Operator chose a **trailing-baseline ratio**:
  window count ÷ trailing 90-day median, laddered 2×/3×/5×, with a 3-commit floor so 0→1 can't spike, the
  baseline printed with every signal, and release-aware suppression labelling directed work as such
  rather than as a discovery. Linkage parse pinned to **full message body** — you were right that the
  rung swings on it (6 vs 40+).
- [Should 5 — `--check` false drift] **Implemented via the operator's design choice, which is stronger
  than a patch.** Rather than special-casing `--check`, the overlay now writes a **sidecar**
  `MARATHON-PLAN-<date>.context.md` and never touches the plan doc. That kills the drift hazard, makes
  "plan doc byte-identical in every mode" true by construction, and sharpens the removal seam — your
  three-birds suggestion, adopted wholesale.
- [Nit 1 — removal seam understates the surface] **Implemented.** Expanded from three files to five
  explicit steps, including the three new flags on an arg parser that `die()`s on unknown arguments,
  plus the usage text. "Nothing else references it" was wrong twice; it no longer claims that.
- [Nit 2 — post-render ordering unstated] **Implemented, and dissolved.** With a sidecar there is no
  ordering interaction with `_inject_review_lanes` at all; the doc now says so explicitly.
- [Pass ×2] Your independent confirmation of the seam and of the three-way byte-identical arithmetic —
  traced through the actual firing path to `_marathon_plan_node.js:805` — closed the one risk I'd flagged
  as unproven when I handed this over. That was the single most useful `[Pass]` in four rounds.
- [Pre-existing, out of scope] `marathon-plan.sh:54` claims `--check` is a `validate.sh` drift guard that
  isn't wired. Agreed it's out of scope; recorded in a new **"Found during review, deliberately out of
  scope"** section alongside the `relay-drive.sh` path papercut, so neither is lost.

**Net effect:** the architecture is unchanged across all four rounds — what changed is that the criteria
now test the thing they claim to test. Two factually false assertions removed. Output moved to a sidecar.
Churn went from a number that would fire forever to a ratio that fires when something is actually unusual.

Relay closed by operator decision at round 4/4 (escalated → fix-forward applied). No further turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
