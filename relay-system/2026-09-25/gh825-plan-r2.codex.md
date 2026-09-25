# RELAY · GH-825 handsfree plan QA revised
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
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
6. **Commit only the relay file** (`relay(gh825-plan-r2): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-825-HANDSFREE-SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-825-HANDSFREE-SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-25
- Definition of Done: The revised GH-825 plan is grounded, minimal, and meets its five acceptance criteria, including cancellation preflight and inactive-job proof.

## Review packet

Operational envelope: one portable Markdown skill, local developer use; no new scheduler, daemon, shell sleep loop, installer, or tests. The user explicitly requires no new tests for the skill file. Grade against the issue and plan, with commensurate complexity.

Read the seeded plan in full and the local skill contracts it cites. Recheck the prior finding recorded in the plan: cancellation capability before arming, cancellation readback after termination, and the OpenAI app versus CLI/IDE distinction. Ask whether each acceptance criterion has a falsifier and whether the temporary note is a resume aid rather than task authority. Report concrete file:line findings. Output exactly one `VERDICT: PASS`, `VERDICT: FAIL`, or `VERDICT: PARKED` line; do not add a second `Verdict` field with free-form text. Set `STATUS: Approved` only on PASS. Keep all writes in this relay thread.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: The revised plan closes the prior cancellation and platform-assumption gaps and is ready for implementation within the declared Markdown-only scope. Approval is for the plan, not a runtime scheduling or final gate attestation.
swept file: yes

- [Pass] Entire seeded artifact reviewed, including pre-existing sections; no additional material defects found. Scope remains one skill, catalog entry and changelog, with no scheduler, daemon, installer or new tests (.relay-artifacts/GH-825-HANDSFREE-SKILL.md:36). The location/catalog contract is supported by skills/README.md:3 and its “Add a skill” rule; existing relay scheduling remains separate (plan:29; skills/1-hourly/relay-xyz/SKILL.md:445).
- [Pass] Prior finding resolved: criterion 2 requires same-conversation capability and cancellation capability before creating a job, then a receipt/existence check (plan:43). Criterion 4 requires inactive/absent proof and explicit live-job/manual-stop reporting on cancellation failure (plan:45). This extends the existing self-delete contract in skills/1-hourly/relay/SKILL.md:153 without altering relay state.
- [Pass] Platform claims are bounded (plan:30,54). The fetched [OpenAI scheduled-task documentation](https://learn.chatgpt.com/docs/automations?surface=app), sections “Schedule a task inside a chat” and CLI/IDE availability, supports minute-based existing-chat tasks while distinguishing app management from CLI/IDE. The [Claude documentation](https://code.claude.com/docs/en/scheduled-tasks), “Limitations,” supports running-and-idle session scope. The [Antigravity codelab](https://codelabs.developers.google.com/getting-started-google-antigravity), sections 4–5, supports scheduling and disabling/deleting jobs, without establishing same-chat CLI continuation. Preserve invocation-time capability checks during implementation.
- [Pass] All five criteria have checkable failure cases (plan:42–46): note collision/empty or nonignored note; missing wake/cancel capability; pending/empty/stale-SHA evidence; still-active/unverified cancellation; and new tests or failed structural checks. Criteria 1–4 explicitly name red controls; criterion 5 is directly falsified by adding tests or failing its named checks. Final implementation review and disposable-clone gates remain required (plan:61).
- [Pass] The note is a resume aid, not task authority: plan:31 explicitly reserves authority to PROJECT docs, the issue and actual results; plan:36 calls the note a “collision-safe resume aid”; plan:44 requires live evidence and authorized milestones at each wake.
- [Unverified — network unavailable] Live issue body could not be independently checked. Command: `gh issue view 825 --repo HiQS-Labs/XYZ-forge --json title,body`; exit 1; decisive output: “error connecting to api.github.com”. Review uses the seeded plan and the relay's stated five-criterion Definition of Done; no claim of live issue parity.
- [Unverified — needs clone run] No executable fixtures or gates were run in this worktree. Structural checks and final runtime/gate evidence remain implementation obligations, not evidence supplied by this plan approval.

Relay closed (Approved), no further review turn needed. Producer may implement the approved plan and obtain final QA.


### Attestation · relay-drive — 2026-09-25T18:00:03Z
task: RELAY-gh825-plan-r2
reviewer: codex
status: Approved
reviewed-head: f1a3a757c73303b26da52d96ca69bb35f43dc12a
added-range: 6362+3329
added-sha256: 5140e509f84bda80f578b798e4edee3d58a5f56d3ea14f4f194546d2774cc9ec
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
