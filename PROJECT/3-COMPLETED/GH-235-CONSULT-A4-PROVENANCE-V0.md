---
gh_issue: 235
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/235
title: "Consult A4 provenance v0: prompt-trace classifier for cited claims (FIRSTHAND vs ECHOED)"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence. Bash side shipped
  commits 1e87a1f/e1a7b61; Python port shipped commit 19830e4."
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: gh-issue-capture
complexity: 2
risk: 2
effort: 2
phases: 0
ratings_provisional: true
related:
  - PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md
  - PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md
  - PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md
  - PROJECT/2-WORKING/GH-223-CONSULT-PY-CITATION-STAMP-PARITY.md
  - relay-automation/consult.sh
  - relay-automation/relay-turn-lib.sh
  - test/consult.sh
goal: >
  Ship the v0 slice of GH-178 A4: a prompt-trace classifier that distinguishes a citation an advisor
  found firsthand (FIRSTHAND) from one it echoed out of the operator prompt (ECHOED), on already-cited
  claims only. Extends rtl_has_uncited_claim()'s machinery; leaves the shipped NO FIRSTHAND stamp
  unchanged (no regression). Defers the INFERENCE/UNSUPPORTED-ASSERTED split, the reconciliation
  backstop, and cross-advisor false-consensus to a later issue.
---

# GH-235 · Consult A4 provenance v0 — prompt-trace classifier for cited claims

## Status

| What was just completed | What's next |
|---|---|
| 2026-07-17: consult picked **v0**; issue #235 filed; v0 **built by a Codex↔agy relay** (`relay-system/2026-07-17/gh235-a4-v0-build.md`). Codex implemented `rtl_classify_cited_claims()` + prompt persistence + `PROVENANCE.txt` sidecar + warn line + 20 tests (commit `bfbd357`); agy reviewed → **Approved** (5 cited `[Pass]`, `6158eed`). Verified: `test/consult.sh` 62/62, `validate.sh` 115/115. relay-pkg regenerated. | Merge `development` → `main` (CI `tier1` gate), then close #235. Optionally move this doc `1-INBOX` → `3-COMPLETED` on close. Deferred follow-ons (INFERENCE/UNSUPPORTED split, reconciliation backstop, false-consensus, consult.py parity) stay future-scoped, coordinated with #226. |
| **2026-07-21:** Bash side shipped commits `1e87a1f`/`e1a7b61`; Python port shipped commit `19830e4`; issue #235 closed on GitHub. Deferred follow-ons noted above remain future-scoped. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## Decision basis

The full firsthand-vs-asserted design lives in [GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md](GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md).
The scope fork (4-category v1 vs. 2-category v0) was adjudicated by a live cross-model consult on
2026-07-17; both advisors independently recommended v0. Transcripts:
`relay-system/2026-07-17/a4-scope-181325/` (local, gitignored).

## Scope (v0)

1. Persist operator `PROMPT_TEXT` (not `PREAMBLE`) → `$RUN_DIR/${LABEL}.PROMPT.txt` in `consult.sh`.
2. New `relay-turn-lib.sh` predicate (sibling to `rtl_has_uncited_claim()`) that classifies
   **already-cited** claim lines FIRSTHAND vs. ECHOED by substring-matching the citation string against
   the persisted prompt — reusing `RTL_CLAIM_WORD_RE`/`RTL_CITATION_RE` verbatim.
3. New per-advisor `$RUN_DIR/${LABEL}.${model}.PROVENANCE.txt` sidecar (per-category counts + the
   matched prompt span for each ECHOED claim).
4. New stdout `warn` only when ECHOED appears on an otherwise-cited transcript.
5. **No change** to the existing `NO FIRSTHAND VERIFICATION CITED` stamp — no regression.

## Highest risk

False FIRSTHAND from citation format-drift (prompt "consult.sh lines 117-126" vs. advisor
`consult.sh:117`; quoted span → `file:line`). State the limitation honestly; do not overclaim. Name it
a "prompt-trace classifier for cited claims," not "the full provenance taxonomy."

## Deferred to a later issue

INFERENCE/UNSUPPORTED-ASSERTED split · reconciliation-layer conditional backstop · cross-advisor
false-consensus · relay-side provenance · `utils/py/consult.py` parity (own follow-on, cf. GH-223) ·
citation-accuracy verification.

## Coordination

Coordinates with #226 (operator-facing summary surface). v0 is largely orthogonal — adds a sidecar,
preserves the existing stamp; the one new stdout warn line is the only human-surface touch.

## Done means

New `test/consult.sh` assertions (FIRSTHAND vs. ECHOED; existing uncited stamp unregressed) +
`./validate.sh` green.
