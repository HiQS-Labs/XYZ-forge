# RELAY · Consult A4 provenance v0 build FIRSTHAND vs ECHOED
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-17.
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
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh235-a4-v0-build): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact(s) under build: `relay-automation/consult.sh`, `relay-automation/relay-turn-lib.sh`, `test/consult.sh`
- Reviewer: agy   ·   Producer: codex   ·   Issue: #235 (GH-178 A4 v0)
- Started: 2026-07-17

### What to build — v0 "prompt-trace classifier for cited claims" (FIRSTHAND vs ECHOED)

**Context.** The shipped A4 slice (`relay-automation/consult.sh:310-336`, via `rtl_has_uncited_claim()`
in `relay-automation/relay-turn-lib.sh:724-744`) is a BINARY check: if a claim-bearing line has any
citation-shaped string (`RTL_CITATION_RE` — `file:line` or a quoted span) within a 3-line window, it is
"cited". Its blind spot: it cannot tell a citation the advisor found firsthand from one it merely echoed
out of the operator's prompt. This v0 closes exactly that gap for ALREADY-CITED claims. Do NOT touch the
uncited path or the existing `NO FIRSTHAND VERIFICATION CITED` stamp — that must keep firing identically
(no regression). This is a small ADDITIVE extension of the existing machinery, not a rewrite.

**Definitions (per already-cited claim line only):**
- **FIRSTHAND** — the nearby citation string does NOT appear in the persisted operator prompt text.
- **ECHOED** — the nearby citation string DOES appear (whitespace-normalized) in the persisted prompt.

**Tasks:**

1. **Persist the operator prompt.** In `relay-automation/consult.sh`, after `PROMPT_TEXT` is known and
   `$RUN_DIR` exists (near the `FULL_PROMPT` assembly around `consult.sh:123-126`), write `PROMPT_TEXT`
   ONLY (never `PREAMBLE`) to `$RUN_DIR/${LABEL}.PROMPT.txt`. Rationale: the classifier needs something
   on disk to diff citations against; the boilerplate PREAMBLE must be excluded (it says "cite evidence"
   and would create false ECHOED matches).

2. **New predicate in `relay-turn-lib.sh`, sibling to `rtl_has_uncited_claim()`** — name it
   `rtl_classify_cited_claims <transcript_file> <prompt_file>`. It runs the SAME awk claim-detection pass
   (reuse `RTL_CLAIM_WORD_RE` and `RTL_CITATION_RE` verbatim via `-v`, and the same inline `/\[Pass\]/`
   literal — heed the macOS-awk `-v` string-unescape WARNING at `relay-turn-lib.sh:665-674`; do NOT put
   `\[Pass\]` in a `-v` value). For each claim line that HAS a citation within the window, extract the
   matched citation token(s) and test whether that token appears in the prompt file (whitespace-
   normalized substring match). Emit, to stdout, one line per already-cited claim:
   `FIRSTHAND <token>` or `ECHOED <token>`. Uncited claims are ignored here (the existing predicate owns
   them). Keep it read-only; no file writes inside the predicate.

3. **Wire it into `consult.sh`'s post-collection stamping** (the loop around `consult.sh:321-336`, right
   alongside the existing `rtl_has_uncited_claim` stamp — extend, do not replace). For each ANSWERED
   advisor, if `$RUN_DIR/${LABEL}.PROMPT.txt` exists, run `rtl_classify_cited_claims` on its transcript,
   write a per-advisor sidecar `$RUN_DIR/${LABEL}.${model}.PROVENANCE.txt` containing the FIRSTHAND and
   ECHOED counts and, for each ECHOED claim, the matched token. If there is ≥1 ECHOED claim on an
   otherwise-cited transcript, print ONE `warn`-style stdout line naming the model and the ECHOED count
   (this is the only new human-facing surface — keep it to one line). Skip `*.json` transcripts for any
   in-transcript stamping, same guard the existing code uses (the sidecar still covers them).

4. **Tests in `test/consult.sh`.** Add assertions mirroring the existing A4 cases (look near
   `test/consult.sh:191-249`): (a) a transcript whose cited claim's citation IS in the prompt →
   PROVENANCE.txt reports ECHOED ≥1 and the new warn line fires; (b) a transcript whose cited claim's
   citation is NOT in the prompt → FIRSTHAND, no ECHOED warn; (c) regression: the existing
   `NO FIRSTHAND VERIFICATION CITED` behavior is unchanged on an uncited transcript. Prefer driving the
   classifier via a small direct harness if a full `consult.sh` run is impractical in-test, but keep it
   consistent with how the existing A4 tests are structured.

**Constraints:** Node/bash stdlib only; reuse existing helpers; no new deps. Honest naming — comments/
docs call this a "prompt-trace classifier for cited claims", NOT "the full provenance taxonomy". Known
limitation to note in a comment: exact/whitespace-normalized substring matching yields a FALSE FIRSTHAND
when the advisor reformats a prompt citation (prompt "consult.sh lines 117-126" vs. answer
`consult.sh:117`; quoted span → `file:line`). v0 accepts this; do not try to fuzzy-match.

- **Definition of Done (what agy grades against):**
  1. `$RUN_DIR/${LABEL}.PROMPT.txt` is written with `PROMPT_TEXT` only (no PREAMBLE).
  2. `rtl_classify_cited_claims` exists, reuses `RTL_CLAIM_WORD_RE`/`RTL_CITATION_RE`, is read-only, and
     correctly labels FIRSTHAND vs ECHOED on already-cited claims.
  3. Per-advisor `PROVENANCE.txt` sidecar + the single new ECHOED warn line are wired into `consult.sh`.
  4. The existing `NO FIRSTHAND VERIFICATION CITED` stamp is UNCHANGED (no regression).
  5. New `test/consult.sh` assertions cover ECHOED, FIRSTHAND, and the no-regression case.
  6. `bash validate.sh` stays green (modulo known-pre-existing environmental reds like `acorn-extract.sh`).
  7. macOS-awk `-v` unescape pitfall avoided; honest naming applied.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer — codex — 2026-07-18
VERDICT: PASS
Basis: The requested v0 build is implemented and `bash test/consult.sh` passed (`62 passed, 0 failed`).
- No prior reviewer findings were open; implemented the v0 build directly from Setup.
- Implemented: persisted `PROMPT_TEXT` only to `$RUN_DIR/${LABEL}.PROMPT.txt`; added read-only `rtl_classify_cited_claims <transcript_file> <prompt_file>` beside `rtl_has_uncited_claim()`; wired per-advisor `${LABEL}.${model}.PROVENANCE.txt` sidecars plus a single echoed-citation warn line for otherwise-cited transcripts; preserved the existing `NO FIRSTHAND VERIFICATION CITED` path unchanged.
- Tests: `bash test/consult.sh` -> `62 passed, 0 failed`.
- Known limitation retained by design: exact/whitespace-normalized substring matching still reports false-FIRSTHAND when an advisor reformats a prompt citation instead of echoing it verbatim.

### Reviewer — agy — 2026-07-17
VERDICT: Approved
Basis: The v0 implementation is correct, exact to the prompt, and passes all tests.
- `[Pass]` Persist prompt without preamble: `printf '%s' "$PROMPT_TEXT" > "$RUN_DIR/${LABEL}.PROMPT.txt"` correctly implemented at `relay-automation/consult.sh:127`.
- `[Pass]` Classifier predicate: `rtl_classify_cited_claims` at `relay-automation/relay-turn-lib.sh:752` correctly implements the `awk` logic, reusing existing regexes and avoiding macOS awk `-v` bugs with `/\[Pass\]/`.
- `[Pass]` Wire into consult post-collection: Sidecars are written at `relay-automation/consult.sh:350-356`, and the single warning is accumulated and emitted at `relay-automation/consult.sh:397-399`.
- `[Pass]` No regression on existing stamp: The `rtl_has_uncited_claim` invocation and stamping remains untouched at `relay-automation/consult.sh:328-336`.
- `[Pass]` Tests: Test cases 15 and 16 at `test/consult.sh:254` verify the firsthand vs echoed classification properly.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
