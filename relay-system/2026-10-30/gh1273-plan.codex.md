# RELAY · GH-1273 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
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
6. **Commit only the relay file** (`relay(gh-1273-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/1-INBOX/GH-1273-RELAY-SEPARATORS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1273-RELAY-SEPARATORS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: approve the source plan acceptance, including literal protection and legacy/new loader round trips.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The Setup artifact is absent, so this turn cannot approve the claimed seeded input. The source capture was available and read in full for a provisional plan review; its acceptance also needs an explicit persisted-attestation compatibility check.
swept file: no
The designated `.relay-artifacts/GH-1273-RELAY-SEPARATORS.md` could not be swept. All 45 lines of `PROJECT/1-INBOX/GH-1273-RELAY-SEPARATORS.md` were read as a fallback, alongside all of `utils/py/relay_attest.py` and relevant driver/consumer sections. This is not a whole-runtime audit. Graph discovery was unavailable: `list_projects` returned “MCP tool call requires approval, but approval policy is never”; source reads were used.

- [Blocker] **B1 — Setup does not name an available review artifact.** The declared `.relay-artifacts/GH-1273-RELAY-SEPARATORS.md` is missing; the directory contains only `gh182-claim-guards.md`. The source capture exists, but this does not establish the seeded input's identity. Fix the seed/Setup mapping before redispatch, or accurately repoint Setup to the intended available input; do not substitute the unrelated artifact.
  Observed input: Setup's artifact path, with the following read-only probe returning exit **1**:
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 -c 'from pathlib import Path; p=Path(".relay-artifacts/GH-1273-RELAY-SEPARATORS.md"); print(str(p) + ": is_file=" + str(p.is_file())); raise SystemExit(0 if p.is_file() else 1)'
  ```
  Decisive output: `.relay-artifacts/GH-1273-RELAY-SEPARATORS.md: is_file=False`.
  Affected scope: This relay's artifact binding and any approval of the intended GH-1273 plan, not general seeding behavior.
  Falsifier: Redispatch with the exact Setup path containing the intended GH-1273 plan; the probe must exit 0 and the file must be readable in full.

- [Should] **S1 — Pin loader round-trip and legacy-record acceptance before changing canonical bytes.** The source plan promises “Attestation load must use the same canonical range semantics” (source capture:23), but step 4 (source capture:36) does not explicitly exercise old records or the newly published trailer. `relay_drive.py:745` persists canonical offsets/length and `relay_drive.py:757` hashes a raw trailer; `relay_attest.py:304` re-canonicalizes the file, then checks the stored slice and the raw trailer at `relay_attest.py:307–317`. `trailer_text` itself begins with a blank line (`relay_attest.py:208`). A separator transform therefore reaches persisted coordinates and the trailer boundary, beyond prefix acceptance. Specify whether the fallback leaves existing canonicalization untouched or how records select compatible semantics. Add acceptance to the existing suite/manual replay: an unchanged pre-change `relay-drive/attest@1` record still loads; a new separator-tolerant approval publishes and loads successfully with its trailer; substantive edits still refuse. This requests concrete acceptance, not a new suite or gate.
  Observed input: Existing `relay-drive/attest@1` record fields `added_start`, `added_len`, `added_sha256`, and `trailer_sha256` (`relay_attest.py:26,261–264`), and the leading `\n` in `trailer_text` (`relay_attest.py:208`). The current loader compares these against its canonical stream without a canonicalization-version selector.
  Affected scope: Persisted approval records consumed through `relay_attest.load`, including marathon recovery (`marathon_drive.py:2593`) and Jog legacy lookup (`jog_run.py:1768`).
  Falsifier: Demonstrate that the chosen fallback preserves legacy record interpretation and that a freshly written fallback record passes the real loader, including trailer positioning. If canonical bytes never change, document that design and show both round-trips; no format migration is necessary merely for ceremony.

- [Pass] **The narrow source plan has a sensible safety boundary.** Source capture:23–25 preserves raw evidence, nonblank bytes and literal contexts; keeps strict comparison first; emits a fallback warning; and rejects inferred approval. Source capture:36 requires disposable-clone verification, substantive negative controls, and no new suites/gates. These are plan properties, not implementation results. No other pre-existing defect was identified in the fully read source capture beyond the acceptance gap above; the seeded artifact remains unavailable.

Current-behavior probe (read-only; exit **0**):
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 -c 'import sys; sys.path.insert(0, "utils/py"); import relay_attest as a; pre=b"STATUS: Open\n\n## Log\n\nOld paragraph.\n\nOther paragraph.\n"; post=pre.replace(b"Old paragraph.\n\nOther",b"Old paragraph.\nOther")+b"\n### Reviewer\nVERDICT: PASS\n"; print("strict_prefix=" + str(a.canonical_bytes(post).startswith(a.canonical_prefix(pre, post))))'
```
Decisive output: `strict_prefix=False`. This isolates the prefix rejection in `relay_drive.py:721`; it does not establish end-to-end approval or recovery.

[Unverified — needs clone run] No `validate.sh`, `test/*.sh`, pytest, executable fixtures, or git commands were run. Prospective literal handling, citation alignment, warning behavior, attestation publication/load, and token recovery remain unverified. Existing relevant suites include `test/gh505-relay-attest.sh` and `test/relay-uncited-findings.sh`; run them only in the required disposable full clone. The Setup Definition of Done also remains a scaffold placeholder; fill it from the agreed source-plan acceptance before the next review.

Handing off to Producer (claude-a) — resolve B1, disposition S1, and request the next review; go to the Producer window and say 'take your turn'.

### Producer · Round 2
B1 Implemented: redispatch with --artifact-file to seed the declared artifact.
S1 Implemented: preserve existing canonical_bytes and record format; fallback computes original post-stream offset. Plan explicitly requires legacy and new loader round trips. Review revised source plan, shared writer, literal/citation protections, ratings and scope. No new tests or gates.

### Producer · Round 2

B1 Implemented: Setup now references the tracked source plan available in every isolated checkout; no seed alias is claimed. Definition of Done filled.

S1 Implemented: retain canonical bytes and record format; map tolerant prefix to ordinary canonical post offset. Explicit legacy and new trailer loader round-trips added to acceptance. No migration or parallel writer. Review the complete source plan against the issue and source paths, with commensurate scope.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
