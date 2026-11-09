# RELAY · GH-1376 compatibility extension final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-08.
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
6. **Commit only the relay file** (`relay(gh-1376-compatibility-extension-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/flywheel/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-11-08
- Definition of Done: Review the complete seeded flywheel skill, complete skills/3-weekly/10days/SKILL.md, plan Compatibility extension and its acceptance map, TESTS-RESULTS/2026-11-08+GH-1376/compat-consumer-smoke.md and compat-pdda.log/provenance, and the approved gh1376-compat-plan receipt. Operational envelope: instruction-level local Forge composition. No runtime integration, actual sweep, scheduler, new gate/test, installed-copy edit, merge or deployment is claimed. Enforce commensurate complexity.
- Questions: (1) Do selection AND dispatch preserve the explicitly invoked 10days exception and a single owner, without Jog duplication or loosening standalone start-marathon confirmation? (2) Does red-gate recovery preserve halt, limits, attempts, evidence/readiness and safety/ownership holds, with standalone behavior intact? (3) Is Daily optional observation only, without dispatch authority or invented link/automatic integration? (4) Are handoff and ready-PR routing complete? (5) Do changed source and committed evidence satisfy the plan without a new subsystem, test or gate? Scope verdict to actual source/evidence; report material findings with exact lines, observed input, affected scope and falsifier. Do not rerun suites in the review worktree.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: FAIL
Basis: Block pending one narrow safety correction in the required complete 10days sweep. Read the entire seeded flywheel, entire 10days skill, canonical plan including compatibility acceptance map, approved compatibility-plan receipt and supplied smoke/provenance/PDDA evidence. The compatibility additions are proportionate instruction-level composition; the pre-existing cleanup defect below remains in scope under the whole-file review contract.

- [Should] Preserve dirty lane worktrees instead of force-removing them. `skills/3-weekly/10days/SKILL.md:520`–526 explicitly says to “fall back to `git worktree remove --force <path>` if it still reports uncommitted/stray state.” This discards uncommitted tracked or untracked lane work, despite the wave's committed portion having been merged. It contradicts `WORKTREE-SAFETY.md:547`–549: “Never default a script to `--force` as a way to ‘fix’ a remove that failed.” Cheapest fix: remove that fallback; preserve the worktree on dirty-state failure and report its path/state for owner reconciliation under the existing cleanup-failure reporting path. No new gate or test is needed.
  Observed input: the literal cleanup instruction at 10days lines 520–522 selects forced removal specifically on “uncommitted/stray state”; the safety guide at lines 547–549 documents that this input is refused by normal removal and discarded by force.
  Affected scope: post-merge lane cleanup when ordinary worktree removal refuses because files remain uncommitted or untracked.
  Falsifier: a lane with its committed patch integrated plus one unique untracked file must remain present after cleanup refusal and be reported; a clean integrated lane should still be removed normally. A demonstrated existing preservation step covering that unique file before force removal would invalidate this finding; none appears in the complete skill.
- [Pass] Selection and dispatch retain one owner and the explicit exception: `.relay-artifacts/SKILL.md:102`–108 says “Do not send its issues through Jog or start a second sweep to resume it”; lines 135–148 select and dispatch through 10days while requiring exact-plan/order approval for start-marathon. Reciprocal `skills/3-weekly/10days/SKILL.md:95`–112 preserves standalone use.
- [Pass] Recovery and handoff retain limits and holds: `.relay-artifacts/SKILL.md:110`–122 requires failed/relevant checks, readiness recheck, attempt history, lock state and next owner; `skills/3-weekly/10days/SKILL.md:104`–112 and 527–533 keep red-wave advancement held and distinguish standalone behavior. Ready PRs route directly to approval/landing at seeded lines 132–134 and step 6; no new merge authority is granted.
- [Pass] Daily is optional observation only: seeded lines 94–100 say “not an automatic observer adapter” and forbid dispatch/repair/merge authority and installed-copy changes. This matches the recorded Daily contract in `relay-system/2026-11-08/gh1376-compat-plan.codex.md` Setup. No invented Daily link or runtime integration is claimed.
- [Pass] Evidence is scoped honestly: `TESTS-RESULTS/2026-11-08+GH-1376/compat-consumer-smoke.md:3` says “no live sweep, repair, schedule, merge or observer integration executed”; compat-pdda.log ends “no errors, 102 warning(s)” and records optional LLM readiness skipped. The two compatibility provenance entries name their revisions and evidence hashes. Narrow read-only Python hash/source comparison (exit 0) produced “compat-consumer-smoke nonempty hash matches; recorded exit 0”, “compat-pdda nonempty hash matches; recorded exit 0”, and “seed matches canonical flywheel source”. Command: `python3` with `hashlib.sha256(p.read_bytes()).hexdigest() == r['sha256']` for both compatibility records, nonempty byte assertions, and byte equality of seeded/canonical flywheel. This confirms artifact integrity, not execution of the recorded gate.

Verification limits: static reads via `cat`, `nl -ba`, `sed`, `rg` and the narrow Python integrity probe, all exit 0. No git, suite, executable fixture, runtime sweep or external query was run. Runtime recovery and exact-head harness gate remain [Unverified — needs clone run]. No other material pre-existing defect identified in this scope.

Handing off to Producer — go to the Producer window and say 'take your turn'; correct the cleanup fallback and return for review.

### Producer · Round 1 disposition

Implemented the narrow whole-file safety finding: dirty/untracked lane cleanup refusal now preserves path/state for owner reconciliation; no force-removal fallback. Existing clean removal and cleanup-failure reporting remain. Scope is one local instruction correction, no new machinery. Native Git manual refusal/clean-path check and provenance follow under compat-cleanup-smoke.md. Request round 2 against the committed correction and compatibility source/evidence; do not revisit unchanged approved plan scope.

### Reviewer · Round 2

swept file: yes

VERDICT: PASS
Basis: Read the complete seeded flywheel and complete 10days skill, compatibility acceptance map, approved plan receipt, consumer/cleanup evidence, PDDA summary and provenance. The sole Round 1 safety finding is resolved. No additional material pre-existing defect identified in the reviewed instruction-level scope. Approval covers source instructions and supplied evidence, not live execution, deployment or landing.

- [Pass] Cleanup now preserves unique state. `skills/3-weekly/10days/SKILL.md:520–527` permits removal only after integration with no unique state, and explicitly says “preserve the worktree” and “never force-remove it” on uncommitted/untracked refusal. `TESTS-RESULTS/2026-11-08+GH-1376/compat-cleanup-smoke.md` records “dirty lane native removal refused rc=128; unique untracked bytes remained” and clean removal rc=0 after deliberate preservation. This addresses the Round 1 falsifier without adding machinery.
- [Pass] One owner and firing boundaries remain intact: `.relay-artifacts/SKILL.md:102–108` prohibits Jog duplication and limits the exception to an explicitly requested sweep; steps 2–3 select AND dispatch through 10days while retaining exact-plan/order confirmation for start-marathon. `skills/3-weekly/10days/SKILL.md:95–112` reciprocates and preserves standalone operation.
- [Pass] Recovery retains halt, budgets, attempts, readiness and safety holds at seeded lines 110–122 and 10days lines 104–112, 528–534. Seeded steps 1 and 6 route verified ready PRs to approval/landing without rebuilding. Daily remains optional observation only at seeded lines 94–100 (“not an automatic observer adapter”), consistent with the approved plan receipt's recorded Daily contract.
- [Pass] The plan's Compatibility extension acceptance items 1–5 are represented by the source and narrowly scoped consumer evidence. `compat-consumer-smoke.md:3` expressly excludes live execution; `compat-pdda.log` reports “no errors, 102 warning(s)” with optional LLM readiness skipped. Historical receipts are not treated as current runtime proof.

Probe: read-only Python with `hashlib.sha256(p.read_bytes()).hexdigest() == r['sha256']`, nonempty byte assertions for the three compatibility provenance records, and seeded/canonical flywheel byte equality; exit 0. Decisive output: “compat-consumer-smoke: nonempty hash matches; recorded exit 0”, “compat-pdda: nonempty hash matches; recorded exit 0”, “compat-cleanup-smoke: nonempty hash matches; recorded exit 0”, “seed matches canonical flywheel source”. These establish evidence integrity, not independent replay of recorded commands. Static reads exited 0. No git, executable fixture or suite was run. Runtime recovery and final-head harness gate remain [Unverified — needs clone run].

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
