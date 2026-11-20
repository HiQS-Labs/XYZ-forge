# RELAY · GH-1543 Plan QA: kickstart KS-15 run-record contract
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-19.
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
6. **Manual relay: commit only the relay file** (`relay(gh1543-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1543-KS15-RECORD-CONTRACT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1543-KS15-RECORD-CONTRACT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-11-19
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

- Operational envelope: a local, stdlib-only Python CLI/module (~220 lines) under `skills/1-hourly/kickstart/scripts/run_record.py` plus a concise contract section in `skills/1-hourly/kickstart/SKILL.md`. No DB, daemon, or new test suite (`AGENTS.md`, GH-831). Verification is a paired red/green manual check under `TESTS-RESULTS/2026-11-20+GH-1543/`.

**Step A — paraphrase first (GH-1414).** Before reading any other file, read only `PROJECT/2-WORKING/GH-1543-KS15-RECORD-CONTRACT.md` and write 2–5 sentences each under **What this proposes** and **How the existing system works, per this document**, plus a short **What it's not**. Label inference as inference.

**Step B — source-backed check.** Then read `skills/1-hourly/kickstart/SKILL.md`, `skills/1-hourly/kickstart/scripts/build_queue.py`, `utils/ci-route.sh` (`is_docs_surface`), and `AGENTS.md` (*No new tests*). Answer:
1. Does the v1 grammar cleanly cover all KS-15 / U1 / U10 / U12 / U16 requirements (`RUN-RECORD-VERSION: 1`, `LANDING_CLONE:`, `OPERATOR_AMENDMENT:`, `PARENT_NOTE:`, `INTERVENTION:`, `APPLIED:`, `GATE:`, `BASELINE:`) and match both the active run-2 header and run-1 baseline lines?
2. Are the atomic append (`fcntl.flock` + temp + `fsync` + `os.replace`) and redaction rules (`~` home normalization, token redaction, stray XML/tool-tag stripping, non-empty check) sound and commensurate?
3. Does `checkpoint` safely prevent mutating `development`/`main` or dirty unrelated files while supporting idempotent run-record branch commits/pushes?
4. What prevents an unchanged/unbuilt candidate from being reported delivered? Are the 4 planned red controls real rejections?
5. Is the PRS rating (`85/65/50/80`) grounded and appeal neutral? Is anything over-built or missing for the stated envelope?

Cite `file:line` for disagreements. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, set `STATUS: Approved` only on PASS, and flip `NEXT: Producer`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes**

Add one stdlib Python parser/writer for versioned Markdown run records, with validation, atomic append, redacted snapshots and optional branch checkpoint publication. A short skill contract and retained manual red/green evidence support downstream kickstart work.

**How the existing system works, per this document**

Run records currently use free-form Markdown, including amendments, interventions and gate results, without a shared parser or atomic writer. The document says the live record already has version and landing-clone headers, while the published run-1 baseline includes compact application and gate forms. Its recon says the kickstart scripts directory currently contains only `build_queue.py` and the CI router treats the skill subtree as docs.

**What it's not**

This is not a database, daemon, downstream status/recovery implementation, template change or live run-2 publication. Inference: delivery-state decisions remain downstream responsibilities unless this contract explicitly supplies their inputs.

**Source-backed findings (whole seeded artifact)**

- [Should] F1 — Specify a stable lock and validate inside it. `.relay-artifacts/GH-1543-KS15-RECORD-CONTRACT.md:39` orders validation BEFORE the locked read and leaves the lock object unspecified. Locking the replaced record inode cannot serialize later openers; validating duplicate IDs outside the lock also permits two individually valid appends to create an invalid record. Fix the plan to use a persistent sibling lock, acquire it before reading/validating the complete candidate, hold through replacement, and fsync the parent directory if crash durability is promised. Extend the existing manual concurrency check to cover the same-ID race, without a new suite.
  Observed input: line 39 says “validates ... against the existing record ... BEFORE writing, then performs an `fcntl.flock`-locked atomic read”; line 74 only checks lost/torn lines.
  Affected scope: concurrent appends to the same record, including duplicate event IDs.
  Falsifier: two synchronized writers append the same ID; exactly one succeeds, the other rejects, and the final record validates. Distinct IDs must both survive even when one writer opens after replacement while another waits.

- [Should] F2 — Make checkpoint confinement and commit scope explicit. `.relay-artifacts/GH-1543-KS15-RECORD-CONTRACT.md:41` promises “never mutates ... the primary checkout” but supplies no primary-checkout identity rule, destination containment rule, or staged-index policy. A relative `--dest ../outside.md` meets the displayed argument shape while escaping the clone; merely rejecting branch names does not establish checkout identity. Fix the plan to define the allowed dedicated run-record checkout/branch, resolve and confine destination paths (including symlink parents), reject unrelated staged/unstaged/untracked state before mutation, stage/commit only the destination, and push an explicit intended ref without force. State failure and retry behavior, including retrying an unpushed commit when the snapshot is unchanged.
  Observed input: line 41 accepts `--clone <dir> --branch <branch> --dest <relpath>` and lists only integration-branch and dirty-unrelated-tree refusals.
  Affected scope: checkpoint filesystem writes, branch switching, commits and optional pushes.
  Falsifier: manual disposable-clone cases with `../outside.md`, a symlink escaping the clone, unrelated staged changes, and the primary checkout must reject before any file/ref/index mutation; a valid dedicated branch must publish only the redacted destination, and retry after a failed push must publish the existing commit.

- [Should] F3 — Correct the evidence contract before implementation. `.relay-artifacts/GH-1543-KS15-RECORD-CONTRACT.md:73` control (c), “pre-redaction fixture contains ... (grep matches),” is a useful positive contamination control, not a CLI rejection; line 80 nevertheless says “All 4 red controls fail pre-change / reject bad inputs.” Since the module is new, a missing-command failure also cannot prove its decision gates. Fix the wording to distinguish baseline absence, candidate bad-input rejections, and the redaction sentinel; retain exact exit codes and unchanged-byte assertions for rejected writes. For line 74's push check, inspect the destination blob from the local bare remote's branch ref, not just the producer clone; include a different pre-publication observer value. This follows `LESSONS-LEARNED.md:196`.
  Observed input: lines 73–74 and 80 specify those conflicting outcomes and a push smoke check without a remote-artifact assertion.
  Affected scope: manual acceptance evidence for validation, append, snapshot and checkpoint; no new test machinery.
  Falsifier: evidence showing the contaminated fixture is detected, the candidate removes all sentinels, each invalid candidate input rejects without mutation, and the bare remote itself contains the intended snapshot would satisfy the corrected claim.

- [Should] F4 — Remove ambiguity in the shared parser contract. `.relay-artifacts/GH-1543-KS15-RECORD-CONTRACT.md:33` allows both explicit dispositions and arbitrary compact action text, but does not define reserved-word precedence or repeated `APPLIED` semantics. For example, `APPLIED: OA-1 → escalated` can mean a malformed explicit disposition with missing action, or compact action “escalated” defaulting to applied; downstream unresolved-state results would differ. Define this precedence, required nonempty action, repeated-disposition policy, and whether escalated remains unresolved; state validation rules for mandatory/nonempty `LANDING_CLONE` and duplicate headers. Keep compatibility examples alongside these rules.
  Observed input: line 33's two overlapping forms and line 38's “lacking a valid APPLIED disposition” definition.
  Affected scope: v1 parsing and unresolved-amendment computation shared by downstream consumers.
  Falsifier: one documented expected parse/diagnostic for that exact line, plus explicit applied/superseded/escalated and compact legacy examples, removes the ambiguity without expanding scope.

- [Pass] The capability inventory includes all eight requested header/event names (artifact lines 29–35), tolerates bulleted events (line 36), and explicitly preserves the compact APPLIED and final-QA forms (lines 33–34). This establishes planned shape coverage, not actual compatibility with both historical records.
- [Unverified — needs source evidence] The active run-2 file is absent from this isolated checkout; no published run-1 artifact was supplied here. Read-only probe: `python3` with `Path('temp/kickstart-2026-11-20-ks1541.md').exists()` and `Path('skills/1-hourly/kickstart/scripts/run_record.py').exists()` exited 0 and printed `False` for both. Historical examples at artifact line 49 are assertions in the plan. Retain exact source excerpts/revisions in implementation evidence; do not describe this review as having validated either live record.
- [Pass] One module and manual evidence fit the stated envelope: artifact lines 37–43 and 55 exclude a DB, daemon and new suite, consistent with `AGENTS.md:165` (“No new tests”). The current writer is `build_queue.py:166–203,247–249`; it emits Authority/Queue sections and writes `--out` directly. Deferring its template changes is explicit at artifact line 55; existing records therefore need explicit v1 initialization/migration instructions in the concise contract.
- [Pass] No delivered-candidate decision is implemented by this proposal: artifact line 55 expressly defers live run-2 credit. Existing `kickstart/SKILL.md:151–156` requires PR URLs, commit SHAs, gates and independent review before completion. Preserve that boundary: parser validity or checkpoint success alone proves neither a build nor delivery. No new delivery gate is requested here.
- [Pass] The router's `is_docs_surface` (`utils/ci-route.sh:62–69`) classifies ordinary skill paths as docs unless a subsystem claims them. This classification is not runtime verification of the new Python module; the retained manual checks remain necessary.
- [Nit] Artifact line 75 unconditionally says update CHANGELOG; make it conditional on `CHANGELOG_WRITES`, per `ROUTER.md` Canonical rules and `PROJECT/PDDA.md:1064–1067` (off/unset disables PR-branch writes).
- [Unverified — no citation] The proposed appeal 50 is explicitly neutral (artifact line 64); the priority and effort rationale are stated at lines 62 and 65. The numerical priority/severity and run-1 recurrence remain source-attributed estimates, not independently measured facts. Treat ~220 lines as an estimate rather than a cap that squeezes out safety checks. No DB/daemon/framework overbuild was found in the whole artifact; the unresolved concerns are contract precision and evidence.

swept file: yes

VERDICT: FAIL

Basis: The whole plan was reviewed, including its pre-existing sections. F1–F4 are concrete specification/evidence gaps that should be resolved before building the shared writer and checkpoint helper; no runtime failure is claimed for an implementation that does not yet exist. Source-backed review used the local files; the graph's nearest project was the separate canonical XYZ-forge checkout, generation `2026-11-18T19:39:07Z`, with missing freshness for the two kickstart paths, so it was not used as proof of this worktree's contents. No gate, executable fixture, pytest, or git command was run. Runtime checks remain [Unverified — needs clone run]; no later gate is assumed.

Handing off to Producer (antigravity) — disposition F1–F4 and revise the plan; then return for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
