# RELAY · GH1092 main delivery smoke
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-12.
-->

NEXT: Producer
STATUS: Open
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1092-main-delivery-smoke): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: relay-automation/relay-turn-lib.sh reviewer role_note only (bounded delivery smoke)
- Reviewer: codex   ·   Producer: implementation
- Started: 2026-11-12
- Definition of Done: Observe the actual shared prompt requirements and independently run the assigned focused command below; no GH981 closure or final code QA.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Bounded smoke packet

This is a live instruction-delivery smoke, not final implementation QA. Follow the actual
shared prompt you received: identify target root/revision, canonical rules and target test
policy in your transcript. Verify read-only GitHub access with `gh api repos/HiQS-Labs/XYZ-forge/issues/1092 --jq .state`.
Read the reviewer role_note and check that the supplied-clone permission reaches your prompt.

The orchestrator supplies this separate disposable FULL clone (not the protected worktree):
/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12-verify
Its HEAD must equal this turn's worktree HEAD (the committed smoke input). Its expected origin
is the task clone path ending `/XYZ-forge-gh1092-reviewer-evidence-2026-11-12/.`; bare=false,
local user.name/user.email unset. Check full .git directory, root/HEAD/origin/bare/local
identity before/after. Do not repair drift. No edits or clone creation.
Assigned command, only in that supplied clone: create temp/gh1092-reviewer-tmp for generated
output, then `PATH=/Users/noelsaw/.cache/xyz-forge-test-venv/bin:$PATH TMPDIR="$PWD/temp/gh1092-reviewer-tmp" bash test/gh681-reviewer-probe-rules.sh`.
No full suite. The command is an existing suite; it must NOT run in this relay worktree.
Retain actual command, exit, decisive output/count and identity bracket in your appended
review. A sandbox/DB/network failure is Unverified, not successful runtime verification.
Source/artifact edits remain forbidden everywhere. Mark PASS only if target-policy delivery
and actual assigned-clone execution are observed. No statement about LTVera browser safety.

## Log

### Reviewer · Round 1
VERDICT: PARKED
Basis: Instruction delivery is observed, but the assigned clone run was blocked by sandbox access before test assertions; the smoke's runtime prerequisite is outstanding.
swept file: no

- [Pass] Bounded role_note delivery: read the entire reviewer role_note at `relay-automation/relay-turn-lib.sh:1067`. The actual received prompt includes both “Read the target checkout startup instructions” and “you MAY execute only the commands explicitly assigned in this relay in an already orchestrator-supplied disposable full clone pinned to the reviewed revision”. No defect found in this bounded role_note sweep. This is not a whole-library sweep or final implementation QA.
- [Pass] Target/rules: target is XYZ Forge at protected worktree `/private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/rtl-wt.jjPbhp`, reviewed HEAD `c6d6f9d218f60118ead419b2bfae46e5e8663f14`. Startup paths read: `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `SOP.md`, `WORKTREE-SAFETY.md`, `TESTS-RESULTS/README.md`, `HARNESS-MODELS-REGISTRY.md`; relay-xyz skill consulted. Target test policy is Forge's own: AGENTS “No new tests (GH-831)” and “Run mutation-heavy suites only in a separate disposable FULL CLONE (GH-564)”. No foreign target policy was inferred. User's bounded command overrides generic full-gate startup advice for this turn.
- [Pass] Read-only GitHub access: command `gh api repos/HiQS-Labs/XYZ-forge/issues/1092 --jq .state`, exit 0, decisive output `open`.
- [Unverified — needs clone run] Actual assigned execution attempted only in supplied full clone `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12-verify`. Command: `export PYTHONDONTWRITEBYTECODE=1; mkdir -p temp/gh1092-reviewer-tmp; PATH=/Users/noelsaw/.cache/xyz-forge-test-venv/bin:$PATH TMPDIR="$PWD/temp/gh1092-reviewer-tmp" bash test/gh681-reviewer-probe-rules.sh`. Exit 2; decisive output: `mktemp: mkdtemp failed on /var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/tick-gh681-reviewer-probe-rules.XXXXXX.wEDh7rBD9s: Operation not permitted`, then `fixture-guard: REFUSING — sandbox root is EMPTY`. Zero test assertions observed; no runtime pass claimed. Next action: orchestrator supplies an execution context where this exact assigned suite can create its fixture sandbox, then reruns the bounded smoke.
- Identity bracket, read directly with Python pathlib/configparser (no reviewer Git command), exit 0 before and after: resolved clone root as above; full `.git` directory=true; HEAD=`c6d6f9d218f60118ead419b2bfae46e5e8663f14` (equal to protected worktree HEAD); origin=`/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12/.`; bare=`false`; local user.name/unset and user.email/unset. All values unchanged after the failed execution; no repair attempted.
- No source/artifact edit, clone creation, full suite, independent closure of GH981, or LTVera browser-safety assessment performed. Only this relay transcript is edited; the harness owns its commit.

Handing off to Producer — go to the Producer window and say 'take your turn'; runtime smoke remains unverified.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
