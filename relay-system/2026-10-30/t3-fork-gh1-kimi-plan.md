# RELAY · T3 fork GH1 Kimi terminal auth plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(t3-fork-gh1-kimi-terminal-auth-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/plan-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/.codex/task-artifacts/t3code-fork-gh1-kimi-auth/plan-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: author
- Started: 2026-10-30
- Definition of Done: Review the embedded plan packet against its stated outcome and verification criteria. This is plan QA, not implementation. Grade only the bounded ACP compatibility scope and commensurate complexity. Require a grounded failure path, shared resolver, modern precedence, correct legacy replacement argv/environment, missing-PTY filtering, malformed metadata handling and focused red-before-green tests. Account login completion remains explicitly unverified.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1
Submitted the grounded plan and source snapshot in the read-only artifact packet. No production changes have been made. Request independent plan QA against the stated acceptance criteria.
VERDICT: PASS
Basis: Ready for review; this is an author submission, not independent approval.

### Reviewer · Round 1
Ship the bounded compatibility plan. This approves the plan, not an implemented fix or completed account login.

swept file: yes

- [Pass] **Failure origin is grounded.** (`.relay-artifacts/plan-packet.md:161`, `.relay-artifacts/plan-packet.md:1122`) The reported legacy input has no top-level `type` (packet line 7); normalization defaults it to `agent` (line 161), and execution calls `authenticate` for that shape (lines 1103–1126). The read-only source-expression probe below returned `{"normalizedType":"agent","terminalBranch":false,"authenticateBranch":true}` with exit status **0**. This measures the compatibility branch, not Kimi's live serialization failure.
- [Pass] **One resolver is the right size.** (`.relay-artifacts/plan-packet.md:16`) Packet lines 16–19 specify shared classification/display/execution, explicit modern-type precedence, legacy replacement command/argv, validated metadata, and rollback without schema changes. This fixes the missing compatibility interpretation at its two consumers rather than adding another auth flow. Modern argv remains `resolved.args + method.args`; legacy argv must remain only the metadata args, including the empty default.
- [Pass] **Environment and lifecycle contracts are preserved in the plan.** (`.relay-artifacts/plan-packet.md:17`, `.relay-artifacts/plan-packet.md:1000`, `.relay-artifacts/plan-packet.md:1103`) Packet line 17 retains base → resolved → auth-method environment precedence and missing-PTY filtering. The source currently merges in that order (line 1000), filters terminal methods at discovery (lines 944–947), closes the initial runtime before PTY launch, reconnects, and verifies before `onChanged(true)` (lines 1103–1149). Apply the helper's legacy env at the auth-method precedence position; retain the existing no-PTY execution guard (lines 986–990).
- [Pass] **Verification is focused and falsifiable at plan level.** (`.relay-artifacts/plan-packet.md:22`, `.relay-artifacts/plan-packet.md:1467`, `.relay-artifacts/plan-packet.md:1503`) Packet lines 22–26 require legacy red-before-green behavior, modern/explicit-type/malformed normalization coverage, existing cancellation and verification assertions, focused checks and final independent review. Existing spawn assertions pin command, argv and environment (lines 1467–1474); cancellation and failed verification are covered in the supplied tests (lines 1503–1535). No new subsystem, suite or frontend machinery is warranted.
- [Unverified — needs clone run] No tests, typechecks, executable fixtures or live login were run during this review. Implementation evidence must show the planned red and green results, including legacy env/argv, explicit-type precedence, malformed metadata and no-PTY filtering. The live runtime/version claims in packet line 7 remain author-reported; completed account login and client integration remain explicitly unverified (lines 12 and 26).

Read-only probe command (exit 0; decisive output quoted above):
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"
node <<'JS'
const fs = require('node:fs');
const packet = fs.readFileSync('.relay-artifacts/plan-packet.md', 'utf8');
const expr = packet.match(/const type = (method\.type \?\? "agent");/);
if (!expr || !packet.includes('if (method.type === "terminal") {') || !packet.includes('if (method.type === undefined || method.type === "agent") {')) process.exit(2);
const method = { id: 'login', name: 'Login', _meta: { 'terminal-auth': { command: '/managed/kimi', args: ['login'], env: {}, type: 'terminal' } } };
const normalizedType = Function('method', `return (${expr[1]});`)(method);
console.log(JSON.stringify({ normalizedType, terminalBranch: method.type === 'terminal', authenticateBranch: method.type === undefined || method.type === 'agent' }));
if (normalizedType !== 'agent' || method.type === 'terminal') process.exit(1);
JS
```

Reviewed all 1,965 lines of the packet, including all four complete source snapshots; no additional concrete pre-existing defect was found within the bounded review scope.

VERDICT: PASS
Basis: The plan meets the stated bounded ACP compatibility outcome with a shared resolver and focused verification. Implementation and runtime completion claims remain subject to the evidence above.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
