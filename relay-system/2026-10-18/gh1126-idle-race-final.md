# RELAY · GH-1126 final QA: sample/classify lock
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1126-idle-race-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/review-diff.patch.txt** — the read-only path that
  `relay-drive.sh --artifact-file TESTS-RESULTS/2026-10-18+GH-1126/review-diff.patch.txt` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Final QA request.**
- Approved plan: `PROJECT/2-WORKING/GH-1126-IDLE-LABEL-PROBE-RACE.md`. Plan relay `relay-system/2026-10-18/gh1126-idle-race-plan.md` was Approved in round 3.
- The seeded artifact is the scoped diff `review-diff.patch.txt`, bound to base and head in `review-diff.binding.txt`. Review it against the repository copy of `utils/py/turn_diagnostics.py` (whole file).
- Evidence is in `TESTS-RESULTS/2026-10-18+GH-1126/`: `race-control.py.txt` plus logs, the disposable-clone suite logs, and `provenance.jsonl`.

**Verify (cite file:line):**
1. The lock is acquired only in `_sample()` → `_sample_locked()` and `classify()` → `_classify_locked()`. `cpu_ratio()`, `idle_seconds()` and `termination_record()` take no lock. Check there is no reentrant acquisition on any path, including `termination_record()` → `classify()` and `_sample_locked()` → `cpu_ratio()`.
2. Classifier semantics (labels, thresholds, order) are byte-unchanged inside `_classify_locked`.
3. The race control is non-vacuous:
   - On base, classify finishes while the probe is held, with the exact reported detail.
   - On the candidate, classify is blocked until release, then returns idle-unknown.
   - With no sample in flight, classify returns immediately.
   - The exception-path limitation is recorded, not claimed fixed.
4. The covering suites listed in the plan ran green in a disposable full clone with stable identity.
5. No new test file or case, and no caller edits.
6. Pre-existing defects in the touched regions.

End with VERDICT and a `swept file: yes|no` line.

### Reviewer · Round 1 — codex

**Ship. VERDICT: PASS.**
**Basis:** The scoped implementation meets the final-QA criteria; no blocking implementation defect found. Approval covers this review, with the final-commit harness/pre-push gate still outstanding as planned.
swept file: yes

- [Pass] Lock ownership is confined to `_sample()` → `_sample_locked()` (`utils/py/turn_diagnostics.py:389-393`) and `classify()` → `_classify_locked()` (`:500-512`). `cpu_ratio()` (`:453-476`) and `idle_seconds()` (`:478-498`) take no lock. `termination_record()` and `emit_termination_record()` call classify once without an outer lock (`:570-590`); sampling calls only the unlocked ratio helper (`:424-432`). No reentrant acquisition on these paths. No caller or test change appears in the seeded patch.
- [Pass] Labels, thresholds and decision order are unchanged. A non-mutating source audit reverse-applied the seeded code hunks **in memory**, checked both Git-blob hashes against the patch indices, and compared the classifier executable body byte-for-byte. Command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -` (stdin: reverse-hunk reconstruction, hashlib blob calculation, AST body-range comparison, provenance SHA256/size checks and AST lock inventory). Exit **0**; decisive output: `base blob 5aa1852317294f1b14ecad84552e418434354a59 candidate blob 64f61dc27c5013beacfb037afe5f33f73fbb0bf3`, `classifier executable body byte-identical`, `provenance: all 10 nonempty artifacts match bytes and SHA256`, `lock acquisitions: ['_sample', 'classify']`. Source: `utils/py/turn_diagnostics.py:511-568`; scoped patch index `5aa18523..64f61dc2`.
- [Pass] Race evidence is non-vacuous: `race-control.py.txt:19-41` holds the third-sample probe behind an event and contrasts base completion with candidate blocking; the actual exact-detail base result is in `clone-race-control-clone.log.txt:1-3`, candidate wait/release/idle-unknown in `:8-12`, and no-in-flight return in `:13` (all paths under `TESTS-RESULTS/2026-10-18+GH-1126/`). Exception-before-probe remains explicitly unclassified (`:14`); this fix does not claim otherwise. The candidate negative wait uses a one-second bounded join, so it is scheduling-sensitive evidence, corroborated by the lock structure rather than a proof from timing alone.
- [Pass] Reviewed the existing clone-run receipts: `clone-gh390-timeout-attribution.log.txt` ends “14 pass, 0 fail”; `clone-gh492-idle-kill.log.txt` ends “16 pass, 0 fail”; `clone-gh648-l1-turn-termination.log.txt:1` says “PASS: 73 assertions”; `clone-gh648-l3-consult-cap.log.txt:1` records the wall/idle cases passing; `clone-gh610-claude-subscription.log.txt:8-17` includes the formerly failing integration case and “OK”; `clone-gh648-l4-285-revalidate.log.txt:1-6` records the shim cases and rejected no-kill mutation. Their nonempty bytes match the provenance hashes. **Evidence limit:** disposable-full-clone execution and stable before/after identity are attested in `README.txt:1`, not accompanied by raw identity snapshots; I did not independently rerun suites or establish final-commit gate success here. User's execution boundary was observed.
- [Nit] Whole-file sweep found a pre-existing documentation mismatch at `utils/py/turn_diagnostics.py:248-250`: the two-tuple helper claims a failed ps probe is treated as “no signal” rather than idle, while the classifier does not inspect nproc (`:511-568`). Optional correction: remove that unsupported docstring promise. No behavior expansion requested. The already documented exception-before-probe and unlocked idle-progress observation limits remain; no additional pre-existing defect found in the changed lock regions. The accepted whole-sample classification delay is accurately disclosed in the plan's Risk / rollback section.

Relay closed (Approved), no further turn needed. Producer (claude-a) owns the subsequent harness gate and publication steps.

### Round 2 — Producer (claude-a) → Reviewer (codex)

- **Nit (`turn_diagnostics.py:248-250`) — Implemented.** The docstring is changed only: it no longer promises "no signal" handling, and now states that `classify()` does not inspect the process count. No code change.
- **Header:** your Round 1 verdict reads **PASS**, but the thread header still says `STATUS: Open`, and the driver recorded no approval. Please confirm the verdict against the one-line docstring change. If PASS stands, set the header to `STATUS: Approved`, so the approval is recorded by the reviewer and not the producer.

VERDICT + `swept file:` line.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

### System · relay-drive — 2026-10-18T16:57:39Z
terminal STATUS Approved written by FAILED reviewer turn (codex; shim returned non-zero) — reverted
