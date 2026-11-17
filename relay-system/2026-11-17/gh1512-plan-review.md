# RELAY · GH-1512 whack-a-mole connect-the-dots and debug-mantra recon plan review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
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
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268).
     Pre-existing defects in a file you are touching are IN SCOPE; if you find none, say so explicitly.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no` line.**
     Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do **not** edit the artifact; only append findings here.
     Every `[Blocker]` or `[Should]` requesting a behaviour change MUST carry three lines:
     `Observed input:` (the failing input you saw), `Affected scope:` (the input predicate the change would govern),
     `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected result).
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1512-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268).

## Setup
- Artifact under review: **PROJECT/2-WORKING/GH-1512-WHACK-A-MOLE-CONNECT-THE-DOTS.md**
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-17
- Definition of Done:
  (a) Plan correctly captures the two documentation edits:
      1. skills/3-weekly/whack-a-mole/SKILL.md §5: after root cause / invariant is found, run /connect-the-dots (../connect-the-dots/SKILL.md) on the invariant before proposing a new mechanism, and name any existing enforcer in the umbrella issue. Exactly one sentence plus a hand-off line; no new section.
      2. skills/1-hourly/debug-mantra/SKILL.md §2: in second mantra ("trace the fail path"), add recon (../recon/SKILL.md) as an escalation when fail path spans unread modules before forming hypothesis. Exactly one sentence in explanatory text, without altering the recited mantra block.
  (b) Strictly complies with AGENTS.md "No new tests" (GH-831) — no new test files or registry entries.
  (c) Verifies route via utils/ci-route.sh (docs-only / tier 1), runs deterministic docs gate utils/pdda/pdda.sh run, and specifies publisher suites (gh620/gh589) in a disposable -gate clone.
  (d) Commensurate complexity respected; no speculative abstractions or enterprise machinery.
  (e) Paraphrase-first comprehension (GH-1414): Reviewer begins with 2-5 sentences each under:
      - **What this proposes**
      - **How the existing system works, per this document**
      - **What it's not**

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**What this proposes**

The plan adds invariant-enforcer discovery to whack-a-mole before a new mechanism is proposed, then carries the candidates and gaps into the umbrella issue. It adds recon escalation to debug-mantra when the failure path crosses unread modules, before forming a hypothesis.

**How the existing system works, per this document**

Whack-a-mole already uses debug-mantra and recon to identify the recurring invariant violation, then drafts remediation. Debug-mantra already orders debugger use, source tracing with knob enumeration, and instrumentation; the plan inserts the recon pointer into that explanatory flow.

**What it's not**

This is not a runtime or tooling change, a new workflow section, or a change to the recited mantra block. The document explicitly rules out new tests and registry entries, and reuses existing skills and publisher suites.

**Block — verification instructions need two small corrections before execution.**

swept file: yes

- [Pass] The intended behavior and scope meet DoD (a), (b), and (d): the plan at `PROJECT/2-WORKING/GH-1512-WHACK-A-MOLE-CONNECT-THE-DOTS.md:56` names the invariant, existing enforcers, the umbrella issue and hand-off; line 59 supplies exactly the unread-module escalation sentence. Lines 35–38 explicitly preserve sections, recital and the no-new-tests/runtime boundaries. No additional mechanism is proposed. Keep these constraints during implementation.
- [Should] Supply actual changed paths to the route classifier. The command at plan line 61 has no stdin producer, so it cannot establish the claimed docs-only route. Narrow non-mutating probe: Python `subprocess.run(["bash", "utils/ci-route.sh", "pull_request"], input=data, text=True, capture_output=True)` with `data=""` returned exit 0 and decisive output `docs_only=false`, `route=full`, `tier=3`; with `data="skills/3-weekly/whack-a-mole/SKILL.md\nskills/1-hourly/debug-mantra/SKILL.md\n"` it returned exit 0, `docs_only=true`, `route=docs`, `tier=1`. The probe wrapper exited 0. Fix line 61 to feed the nonempty complete candidate/base changed-path list on stdin and assert route/tier, rather than relying on exit status alone.
  Observed input: The plan's bare `utils/ci-route.sh pull_request` invocation supplies no changed-path list; the empty-stdin control classified as full/tier 3.
  Affected scope: Route verification for this candidate, including its documentation and relay/evidence paths.
  Falsifier: Feed the actual complete nonempty candidate path list; expect `route=docs` and `tier=1`. A full/tier-3 result on that list would falsify the docs-only assumption and must be resolved honestly.
- [Should] Bind the publisher-suite run to the edited candidate and retain attributable evidence. Plan line 63 only specifies a gate clone "created from origin"; it never brings the candidate commit into that clone. Both publisher suites clone their own `REPO` into fixtures (`test/gh620-skills-army-mini-sync.sh:45`, `test/gh589-xyz-mini-sync.sh:30`), so an origin-default checkout would exercise the old payload. Fix the step to bring the exact committed candidate into the disposable full clone, verify its HEAD and changed skill bytes, run the named existing suites there, and retain commands, exit statuses and nonempty logs with `provenance.jsonl` under the existing `TESTS-RESULTS/<date>+GH-1512/` convention. Follow the pre/post clone-identity checks in `WORKTREE-SAFETY.md` §12; no new test or runner is needed.
  Observed input: "Run publisher suites ... in a disposable `-gate` clone created from origin" without a candidate revision or transfer step (plan line 63).
  Affected scope: Publisher evidence used to approve the two edited skill files and final diff.
  Falsifier: A gate-clone receipt identifying the exact candidate SHA and matching skill bytes, with passing suite logs and intact pre/post clone identity, would establish that the intended candidate was tested and make this correction unnecessary.
- [Nit] Plan line 56 puts the hand-off sentence in the same quoted paragraph. Make the hand-off a separate line when implementing, as DoD (a) explicitly requires "Exactly one sentence plus a hand-off line"; no added section is needed.

Whole-file sweep found the verification gaps above; no additional pre-existing defects were found in the reviewed plan. This is plan approval only: publisher suites and the deterministic docs gate remain **[Unverified — needs clone run]**; no gate, fixture, Git command, or artifact edit was executed this turn. Graph freshness/coverage endpoints were unavailable; evidence came from direct Markdown and shell-source reads plus the route probe.

**VERDICT: FAIL**

**Basis:** The two documentation changes are appropriately small and match the requested behavior, but DoD (c) needs executable route input and candidate-bound publisher evidence. Correct the two verification bullets, then return the plan for approval.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

### Producer · Round 1

**Dispositions:**
- [Should] Supply actual changed paths to route classifier: **Implemented.** Updated `PROJECT/2-WORKING/GH-1512-WHACK-A-MOLE-CONNECT-THE-DOTS.md` Step 3 to feed `git diff --name-only origin/development...HEAD | bash utils/ci-route.sh pull_request` and assert `docs_only=true`, `route=docs`, `tier=1`.
- [Should] Bind publisher-suite run to edited candidate and retain evidence: **Implemented.** Updated plan to fetch and checkout the candidate commit SHA in the disposable `-gate` clone, verify clone identity and matching skill bytes, execute `bash test/gh620-skills-army-mini-sync.sh` and `bash test/gh589-xyz-mini-sync.sh`, and record logs and `provenance.jsonl` under `TESTS-RESULTS/2026-11-17+GH-1512/publisher-suites/`.
- [Nit] Separate hand-off line in whack-a-mole §5: **Implemented.** Structured the planned addition as one sentence followed by a separate indented hand-off line (`Hand off candidate modules and unaddressed gaps to §6.`).

Returning plan for Round 2 review and approval.
