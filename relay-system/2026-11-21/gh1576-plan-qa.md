# RELAY · GH-1576 Plan QA: refuse push from unwired clone
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-21.
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
6. **Manual relay: commit only the relay file** (`relay(gh1576-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1576-PREPUSH-HOOK-CHECK.md` (the plan; no code yet)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-21
- Definition of Done: the plan satisfies issue #1576 (asks 1-3 and its red/green) with the smallest
  change that works, grounded in the real push sites.

Issue #1576 asks: (1) clone provisioning runs `bash githooks/install.sh`; (2) immediately before every
push by start-task and the lanes that reuse its push step (kickstart children, express, jog,
merge-cleanup repairs), run `bash githooks/install.sh --check`, stop and do not push on failure, never
fall back to `--no-verify`; (3) extend the existing provisioning and push steps, no new subsystem, no
new suite (GH-831). Red: a fresh clone without install pushes with no gate. Green: the same sequence
through the changed push step refuses before push, and after install the push runs the hook.

Operational envelope: grade against the stated requirements, commensurate complexity, and this repo's
own threat model (`githooks/install.sh` header states `--no-verify` and per-clone wiring are not fixable
client-side). XYZ-forge forbids new tests (AGENTS.md, GH-831); verification is existing suites plus a
manual check under `TESTS-RESULTS/`. This touches gate/hook surfaces: do not suggest deferring a finding.

**Step A — paraphrase first (GH-1414).** Before opening any other file, read only the plan doc and
write 2-5 sentences each under **What this proposes** and **How the existing system works, per this
document**, plus a short **What it's not**. Label inference as inference.

**Step B — source-backed check.** Then read the cited sites (`githooks/install.sh`,
`utils/py/express.py:551,704,1109,1143,1284`, `utils/py/jog_run.py:1209,2320`,
`skills/1-hourly/kickstart/scripts/run_record.py:590`,
`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:964,1031,1534`,
`skills/1-hourly/start-task/SKILL.md:290`) and `AGENTS.md` (No new tests). Answer:
1. Is the push-site table complete for "start-task and lanes that reuse its push step"? Name any push
   call site in the lane family it misses (cite file:line).
2. Does the plan extend the existing authority (`install.sh --check`, express `gate_check`) rather than
   add a second writer or detector? Is the "absent installer -> not applicable" rule safe, or does it
   reopen the silent-ungated hole for a Forge clone?
3. merge-cleanup: is installing the hook in the throwaway landing clone and moving `:1048` to
   `PUSH_GATE_TIMEOUT_S` right, or does it break the repair flow (merge in progress, gate run)?
4. What prevents an unchanged, unfixed candidate from being reported delivered? Is the red/green manual
   check (base `3dc703600` red, changed code green main path + adjacent path) a real rejection?
5. Is anything over-built or missing for the envelope?

Cite `file:line` for disagreements. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, and
set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

**What this proposes**

Add the existing installer check immediately before the listed lane pushes and refuse unwired
clones. Make provisioning explicit, wire merge-cleanup's disposable landing clone, and retain
red/green evidence without adding a suite.

**How the existing system works, per this document**

Hooks do not travel with clones; the installer already detects missing wiring. Express checks
some paths, while the other listed push sites lack an executable refusal. The document says
start-task provisioning is currently prose and merge-cleanup creates an unwired repair clone.

**What it's not**

No replacement hook detector, server control, new suite, or protection against deliberate manual
bypasses. Inference: the downstream-host exception is intended to preserve cross-repo use.

**Source-backed findings**

- [Should] **F1 — Missing installer is not proof that the target is a downstream host.**
  Plan lines 72–74 make absence alone sufficient to proceed, but the existing authority explicitly
  describes Forge branches predating the hook directory (`githooks/install.sh:9`) and refuses
  missing installers in canonical mode (`utils/py/express.py:564`). This would retain an ungated
  path for an unwired Forge checkout whose branch lacks the installer. Specify a positive,
  existing target/harness-context distinction for any downstream exception; missing/unknown
  Forge installation must refuse. Do not add a second hook detector or infer host identity from
  installer absence. Apply the same applicability rule to provisioning and verification.
  Observed input: the plan's literal absent-`githooks/install.sh` case at
  `PROJECT/2-WORKING/GH-1576-PREPUSH-HOOK-CHECK.md:72`, combined with the supported old-Forge-branch
  case documented at `githooks/install.sh:9`; no runtime reproduction claimed.
  Affected scope: the proposed absent-installer branch at the newly guarded lane push sites.
  Falsifier: an unwired Forge target without the installer must refuse before push; a positively
  identified supported downstream host must retain its explicitly chosen host policy. If
  existing context cannot distinguish them, document and choose the conservative refusal.

- [Should] **F2 — Do not make Jog's policy depend on whether Express imports.**
  Plan lines 69–71 leave two implementations conditional on import success. Express's
  `VENDORED = False` is initialized at `utils/py/express.py:93` and updated only inside its
  CLI `main()` at `:1603`; importing `gate_check` does not initialize that mode.
  Choose the planned direct installer subprocess call in Jog, with F1's explicit applicability
  decision, rather than an optional CLI-module import. Keep Express's own reuse local.
  Observed input: a library import of `express.gate_check` for the plan's downstream host lacking
  a root installer takes the false-mode return at `utils/py/express.py:564`, even when Express's
  CLI would set vendored mode.
  Affected scope: Jog's proposed reuse/fallback at plan lines 69–74.
  Falsifier: the same target must receive the same admission decision regardless of Express's
  import availability; a supported vendored-host case must agree with the selected host policy.

- [Should] **F3 — Tie refusal evidence to the other changed push boundaries.**
  Plan lines 85–92 exercise kickstart before/after installation and its rerun, but do not identify
  which existing checks witness refusal at Jog, merge-cleanup, and Express closeout. An unchanged
  `merge_cleanup.py:1048` or `express.py:1284` could therefore survive the stated manual check.
  Name the relevant existing assertions or retained manual controls for those new decisions,
  including a real merge-cleanup repair push after provisioning. Require nonzero refusal and
  an unchanged origin ref when unwired, then a successful hooked push when wired; retain exact
  revisions, commands, outputs and provenance. No new suite is needed. Also clarify that
  "same sequence" at plan line 87 means the guarded lane command: plain `git push` remains
  outside the implementation and cannot be expected to refuse merely because this plan lands.
  This is a verification-plan correction, not a request for another runtime mechanism.

- [Pass] **Push-site inventory and authority are grounded.** Within the named Python lane family,
  the source search found the seven push calls already listed in the plan; no additional direct
  call site was found. The operative installer check is `githooks/install.sh:62`–85, including
  executable-stub and overriding-`core.hooksPath` refusal. The proposed direct calls extend this
  authority rather than introduce a writer/detector.
  Read-only command: `rg -n '"push", "origin"' utils/py/express.py utils/py/jog_run.py skills/1-hourly/kickstart/scripts/run_record.py skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`.
  Exit 0; decisive output: `run_record.py:590`, `express.py:1143,1284`,
  `merge_cleanup.py:1048,1534`, `jog_run.py:1209,2320`. Source/AST inspection of the named
  lane directories supplemented this literal search; this is bounded source evidence, not a
  claim about every indirect publisher in the repository.

- [Pass] **Repair sequencing supports the proposed wiring and timeout.**
  `prepare_landing_clone` deliberately leaves a merge open at
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:997`, but B1 commits that merge at
  `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:678` before returning the SHA passed to
  `push_resolved_head` (`merge_cleanup.py:2064`, `:2072`). Installing hooks does not itself
  execute the gate. Using the existing `PUSH_GATE_TIMEOUT_S` (`:106`) instead of the
  180-second network default (`:105`) is appropriate for a now-hooked repair push. Preserve
  the existing merge-attempt context at `:1045` and the function's `(False, reason)` failure
  convention, rather than mechanically introducing an exception. Runtime success still needs
  the disposable-clone evidence requested in F3.

- [Unverified — needs clone run] No red/green, suite, or hooked push was run in this reviewer
  worktree, and no later phase gate is assumed. The proposed kickstart refusal would reject
  the unchanged candidate at that entry point; F3 closes the remaining evidence gap.
  The full plan was swept, including recon, risks and non-goals. No additional pre-existing
  defect in the plan was found beyond F1–F3. Graph project/generation and coverage could not
  be checked because graph tools are unavailable; source reads were used instead.

swept file: yes
VERDICT: FAIL
Basis: The push inventory, existing authority and repair ordering support this small change.
The missing-installer exception and optional Express import leave applicability inconsistent,
and the verification plan must identify rejection evidence for the other new push checks.
This is plan QA, not implementation approval.

Handing off to Producer (claude-a) — revise the plan and disposition F1–F3, then return it for review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
