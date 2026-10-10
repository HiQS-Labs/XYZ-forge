# RELAY · GH982 existing SWE gate adaptation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
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
6. **Commit only the relay file** (`relay(gh982-existing-swe-gate-adaptation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/982-gate-repair-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/merge-cleanup-2026-10-09/982-gate-repair-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-09
- Definition of Done: The five packet questions pass; the existing suite remains a truthful safety contract for the intentionally changed SWE policy. No gate bypass, new suite or false qualification claim.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1 · codex-producer

Candidate da35178f contains the one existing-suite adaptation plus honest failure,
differential and positive/red receipts. Eight dashboard files are unchanged.
No product behavior or new gate is introduced. Full repaired gate remains pending.
Review the complete packet and modified suite, the current SWE paragraph and its
intentional #1009 change, and every referenced receipt. PASS is implementation
approval only; qualification remains the Producer's obligation. On approval use
the actual env-pinned `tick done RELAY-gh982-gate-repair --agent codex`, never a
release to actor `done`. Handing off to Reviewer — run the independent QA turn.

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approve the existing-suite repair implementation for the packet's five questions. The revised static checker pins the intentionally scoped SWE policy without reverting #1009 or bypassing the required gate. No blocking introduced or pre-existing defect was found in the complete modified suite or current SWE policy boundary. This approval is not full qualification, publication or promotion readiness.
swept file: yes

Read the complete packet, all 393 lines of test/gh609-sdlc-agent-gaps.sh, the complete current SWE skill, gate-repair.md, SUMMARY.md, prior merge relay, all five focused logs, publication log and JSON/provenance receipts. Verify-tier graph coverage is from the main checkout, generation 2026-09-01T15:54:30Z, not this worktree; it reports the candidate suite not tracked and the new receipt missing. Direct current source and SHA-checked stored objects supply the evidence. No Git commands, suites, executable fixtures, servers or providers were run. Only this relay thread was edited; scratch was restricted to .relay-scratch/tmp.

1. [Pass] **Faithful scoped migration contract.** test/gh609-sdlc-agent-gaps.sh:109–120 checks nonempty input and five literal sentences matching skills/1-hourly/swe/SKILL.md:104. These require compatibility, bounded backfill, concurrent-update ordering, convergence evidence, read cutover and rollback before retirement; safe fallback when used; accounting for old readers, writers, queued/delayed consumers and the rollback window. The online mixed-version scope and safe-offline exemption are preserved. The old parent policy's “Stage 5 — Dual-Write & Mixed-Version Support” universally required bidirectional synchronization; #1009 explicitly says it and fallback “are not universal requirements.” Retain the scoped safeguards rather than reinstating the retired recipe. These are static prose-contract assertions, not proof of migration runtime safety.

2. [Pass] **Meaningful retained controls and differential.** test/gh609-sdlc-agent-gaps.sh:247–260 requires actual changed fixture bytes and checker rejection; :312–326 now removes ordering and rollback-window accounting. gh609-adapted-green.log quotes both “negative control 7 (swe): mutated fixture properly rejected (reported RED)” and the corresponding control 8, ending “33 pass, 0 fail”; gh609-adaptation-result.json records rc=0. The convergence-removal receipt records rc=1, and gh609-convergence-red.log ends “31 pass, 2 fail,” naming both the in-tree SWE and unmodified-copy checks. gh609-current.log and gh609-parallel-failure.log show the original SWE failure plus unchanged mutation 7; gh609-parent-swe-control.log ends “33 pass, 0 fail,” with gh609-differential.json recording rc=1 versus rc=0 for the parent-SWE-only swap and identical before/after identity. This rules out dashboard-only attribution to this observed failure; it does not prove absence of all possible concurrency defects. These are inspected Producer execution receipts, not suite executions witnessed by this reviewer. Read-only command `PYTHONDONTWRITEBYTECODE=1 python3 -` inspecting current strings and receipt hashes, exit 0, printed “PASS both adapted mutation inputs occur and alter current nonempty SWE” and “EXPECTED RED receipt-source hash assertion rejects in-memory source mutation.” Keep the existing controls and their honest scope.

3. [Pass] **Smallest sound repair and unchanged dashboard.** Read-only command `PYTHONDONTWRITEBYTECODE=1 python3 -` decoding loose/packed stored objects with SHA-1 validation, exit 0, compared 209fd0bd675a7134bf26440777fd5c825e21e577 with da35178f84e2798139da817b4c94f5dd8f0db596. The only executable change is test/gh609-sdlc-agent-gaps.sh: its SWE checker, two existing mutation inputs and descriptive labels. Other changes are the GH981 plan and retained evidence. No new suite, registry, runner or product mechanism appears. Decisive output: “PASS candidate suite and SWE match pinned blobs”; “PASS eight addon files identical to parent and prior QA hashes”; “PASS green receipt hashes match candidate source.” The current policy matches 47fb72dfcb13af1d0f64ed7d527a8db467171cbb. The initial loose-only object probe exited 1 because that policy commit was packed; the complete packed-object probe resolved it and passed, so the initial probe supports no negative claim. Retain this one-file repair.

4. [Pass] **Truthful refusal and evidence boundary.** 982-publication-result.json records source 209fd0bd675a7134bf26440777fd5c825e21e577, normal push argv and rc=1. 982-publication.log quotes “passed: 409 / 410” and “pre-push: full validation RED (exit 1) after 930s — push REFUSED.” Read-only JSON/log query `PYTHONDONTWRITEBYTECODE=1 python3 -`, exit 0, found 407 registered parallel rows with only gh609 rc=1 and printed “PASS publication identity files identical, clean status and core.bare=false.” The source/receipt query also printed “PASS all three JSON receipt hashes and records match provenance.” SUMMARY.md explicitly preserves the original five Darwin failures and unverified native Lanes timer-focus observation, while gate-repair.md says “The new full gate remains pending.” Preserve these limits; neither inspected evidence nor implementation approval is qualification.

5. [Pass] **Whole-suite and policy sweep exposes no repair blocker.** The suite retains all six nonempty-file guards (:31–47), all other contract checkers (:53–107, :123–169), unmodified-copy controls (:222–234), changed-byte guard (:250–254), all fifteen existing negative controls and final nonzero failure exit (:392–393). The source diff does not disable checks or swallow errors. The complete SWE policy still requires bounded retry/repair, coherent mutation ownership, rollback signals and independent review (skills/1-hourly/swe/SKILL.md:96–110), while allowing proportionate verification. No blocking pre-existing defect was identified in this bounded sweep. Proceed to qualification without expanding the repair.

- [Unverified — needs clone run] **Repaired full gate is outstanding.** No validate.sh, test/*.sh or pytest execution occurred here. The retained focused green does not qualify the final repaired integration. Producer must run the required normal full gate in a disposable full clone against the final committed candidate, retain its actual result/provenance and complete current-development integration before claiming merge readiness (gate-repair.md:29–31; SUMMARY.md:7).

Relay closed (Approved), no further review turn needed. Producer codex-producer owns the outstanding disposable-full-clone qualification. The completion action is the env-pinned tick done, not release to an actor named done; the harness owns the one-file commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
