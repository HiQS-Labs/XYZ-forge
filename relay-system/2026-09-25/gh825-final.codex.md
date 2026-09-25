# RELAY · GH-825 handsfree final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 4

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
6. **Commit only the relay file** (`relay(gh825-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/1-hourly/handsfree/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-25
- Definition of Done: Skill meets issue #825 and the approved plan without new tests or scheduler code; all safety/stop claims are honest and the diff is scoped.

## Review packet

Operational envelope: a single portable Markdown skill, one catalog row, a short changelog entry, and the existing GH-825 plan. No new tests by explicit user instruction. Review commensurate to the doc-only behavior and do not request speculative scheduler code or a test framework.

Read `PROJECT/2-WORKING/GH-825-HANDSFREE-SKILL.md` and issue #825 if reachable, then the seeded `SKILL.md`, `ARCHITECTURE.md` row, and `CHANGELOG.md` entry. The Codex plan QA approved `relay-system/2026-09-25/gh825-plan-r2.codex.md`. Current focused evidence: skill-creator quick_validate says “Skill is valid!”; `git check-ignore` confirms /temp/; `git diff --check` and PDDA frontmatter/status-table/changelog checks pass. Full qualifying gate is pending and will run in a disposable full clone against the final approved commit.

Questions: (1) Does the skill actually set up a 10-minute same-conversation native wake and cap actions at 3 hours? (2) Does it avoid false portability claims for Codex CLI/IDE, Claude Code, Antigravity CLI/Gemini, and handle unavailable scheduler honestly? (3) Does it write a collision-safe ignored note without replacing canonical task state? (4) Does each wake move an authorized milestone using live result and SHA, then cancel with verified readback on stop? (5) Are any issue/plan acceptance criteria missing or overbuilt? Cite file:line and classify any unmet requirement. Output exactly one `VERDICT: PASS`, `VERDICT: FAIL`, or `VERDICT: PARKED` line; do not add a second free-form Verdict field. Set `STATUS: Approved` only on PASS. Write only this thread.

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
Basis: The Markdown scope and ordinary wake/stop protocol meet the approved plan, but the setup failure instruction can misreport a created job as unarmed. One short instruction correction is required; no scheduler code or new tests are requested.
swept file: yes

- [Should] Distinguish pre-creation refusal from post-creation verification failure (.relay-artifacts/SKILL.md:33–38,54–59). The latter currently falls under “If any check fails, leave the wake **unarmed**” without cleanup. Fix: when creation has been attempted and receipt/readback fails, retain any known job identity, attempt cancellation and inactive readback using the existing stop protocol; if state cannot be established, report possibly active plus the manual stop action. Do not create a replacement until the first job's state is resolved.
  Observed input: The instruction at line 36 requires an “active-job readback” after creation; line 54 applies “any check fails” to that check and directs “unarmed.” These literal instructions cover a successful creation followed by a failed readback without directing cancellation. This is a text-level failure-path review, not an observed scheduler incident.
  Affected scope: Only setup attempts where creation has occurred or its outcome is unknown and subsequent verification fails; capability refusal before creation remains unarmed.
  Falsifier: Walk through creation returning job J followed by unavailable readback: the instructions must require cancellation of J and either inactive proof or a possibly-active/manual-stop report. Conversely, missing cancellation capability before creation must create no job. An existing instruction explicitly applying that cleanup to setup failures would discharge this finding; lines 92–98 currently sit under “At each wake.”
- [Pass] Whole 106-line seeded skill swept; no additional material or pre-existing defects found. The note is explicitly unique/non-overwriting and subordinate to canonical state (.relay-artifacts/SKILL.md:25–32); scheduling is capability-gated and CLI/IDE parity is not assumed (33–52). No change requested to those contracts.
- [Pass] The scheduled prompt and wake steps require actual run identity, SHA and result, reject pending/empty/stale results, and advance authorized work (64–87). Deadline checks precede further action, renewal/overlap are prohibited, and normal terminal cancellation requires inactive/absent proof (75–76,92–102). These are instruction-level controls, not proof of live scheduler execution.
- [Pass] Catalog and changelog match the requested skill scope (ARCHITECTURE.md:54; CHANGELOG.md:3–10). No new runtime machinery is called for by the artifact. Full repository diff scope is not independently attested because this turn prohibits Git commands.
- [Nit] Include the explicit 10-minute cadence in the note's field list (.relay-artifacts/SKILL.md:28–30), as requested by plan acceptance criterion 1; it currently appears in the scheduling instructions but not the note inventory.
- [Unverified — network unavailable] Live issue parity: command `gh issue view 825 --repo HiQS-Labs/XYZ-forge --json title,body`, exit 1, decisive output “error connecting to api.github.com”. Review uses the complete local approved plan and review packet.
- [Unverified — needs clone run] No validate.sh, test scripts, pytest, executable fixtures, or Git commands were run. Reported structural/gate results were not rerun; the qualifying gate remains with the harness in a disposable full clone. No live scheduler was created or exercised.

Handing off to Producer (claude-a) — correct the setup-failure instruction and return for review.

### Producer · Round 2

- [Should] Setup may leave a created job active after readback failure — Implemented at `skills/1-hourly/handsfree/SKILL.md:55-62`: pre-creation refusal is separate from uncertain post-creation state; known/discoverable job is cancelled with inactive proof, otherwise reported possibly active with manual stop; no replacement until resolved. Proof: reviewed the committed diff `ce31fafc`.
- [Nit] Note omits cadence — Implemented at `skills/1-hourly/handsfree/SKILL.md:28`: note now records the 10-minute cadence. Proof: reviewed `ce31fafc`.
- [Pass] Scope remains one Markdown skill and pointers; no new tests or scheduler code. No action required.
- [Unverified] Live issue fetch unavailable in reviewer environment; local approved plan contains the issue requirements. Qualifying gate still pending in a disposable full clone after final approval.

Verification: skill-creator `quick_validate.py` -> `Skill is valid!`; `git diff --check` -> clean. No new test files. Re-review the two exact lines above and confirm the failure path closes before approval.
Commit: ce31fafc

### Reviewer · Round 2

VERDICT: PASS
Basis: Both prior findings are resolved. The complete seeded skill meets the approved plan's instruction-level requirements within the declared Markdown-only scope. This approval is not a live scheduler or qualifying-gate attestation.
swept file: yes

- [Pass] Setup failure handling now distinguishes pre-creation refusal from uncertain creation, preserves/discovers the job identity, requires cancellation with inactive proof, reports possibly-active state with manual stop when proof fails, and forbids replacement until resolved (.relay-artifacts/SKILL.md:54–64). The prior round's successful-create/failed-readback counterexample now reaches cleanup rather than an unsupported “unarmed” report.
- [Pass] Note inventory explicitly includes “10-minute cadence”; its unique, non-overwriting path and subordinate resume-only role remain intact (.relay-artifacts/SKILL.md:25–32). The repository ignore rule is `/temp/` (.gitignore:13).
- [Pass] Swept all 111 lines, including unchanged content; no additional material or pre-existing defects found. Same-conversation access, cancellation, receipt and readback remain prerequisites; platform parity is explicitly not assumed (.relay-artifacts/SKILL.md:33–52). Missing capability is reported honestly (54–64).
- [Pass] Wake instructions require live run identity/SHA/result and authorized milestone progress, reject pending/empty/stale evidence, check the deadline before action, and require inactive/absent readback at stop (.relay-artifacts/SKILL.md:69–103). Delayed wakes do not extend the deadline or permit overlapping loops (105–107). These are agent instructions, not a scheduler-enforced runtime timeout.
- [Pass] Catalog and changelog describe the same bounded native-wake skill (ARCHITECTURE.md:54; CHANGELOG.md:3–10); the local approved plan's five acceptance criteria are represented by the skill and the pending verification obligations (PROJECT/2-WORKING/GH-825-HANDSFREE-SKILL.md, “Acceptance and falsification”). No scheduler code or new tests are requested.
- [Unverified — network unavailable] Live issue parity: `gh issue view 825 --repo HiQS-Labs/XYZ-forge --json title,body` exited 1 with “error connecting to api.github.com”. Review relies on the local approved plan and review packet; current external platform documentation was not independently revalidated this turn.
- [Unverified — needs clone run] No Git commands, test scripts, pytest, executable fixtures, or repository gates were run. Full diff scope and producer-reported structural checks are not independently attested. The harness must run the qualifying gate in a disposable full clone; no live scheduler was created or exercised.

Relay closed (Approved), no further review turn needed. Producer (claude-a) owns the remaining qualifying gate and publication steps.


### Attestation · relay-drive — 2026-09-25T18:07:16Z
task: RELAY-gh825-final
reviewer: codex
status: Approved
reviewed-head: 1cfa3ee71ad628dbbc37cfe84114511f9daac84b
added-range: 11862+2874
added-sha256: af85195794c4222aa19af7a256e50cefecb673bebc66eebb262b7c2e97315b2f
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
