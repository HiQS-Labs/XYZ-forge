---
gh_issue: 226
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/226
title: "Full provenance follow-up should coordinate with the already-reworked consult/relay summary surface"
status: Proposed (1-INBOX — not yet active)
created: 2026-07-17
updated: 2026-07-20
owner: noel
doc_type: enhancement
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
related:
  - PROJECT/2-WORKING/GH-173-JEDI-WRIGHT-FEEDBACK.md
  - PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md
  - PROJECT/1-INBOX/GH-211-CONSULT-RELAY-TLDR-SUMMARIES.md
  - skills/consult/SKILL.md
non_goals:
  - Not implementing the fuller provenance taxonomy in this capture doc.
  - Not reopening GH-178's already-shipped narrow A4 slice unless the coordinated pass proves it insufficient.
  - Not editing the external giant-brains relay skill from this intake doc; that repo boundary is part of what this issue must clarify first.
goal: >
  Capture the coordination gap Jedi Wright pointed out on 2026-07-17: GH-211 already reworked the
  consult/relay operator-summary surface, GH-178 intentionally shipped only a narrow provenance
  slice, and the next "full provenance" pass should decide those surfaces together so the
  human-facing reporting layer is not reworked twice.
---

# GH-226 · provenance follow-up vs. summary-surface coordination

## Status

| What was just completed | What's next |
|---|---|
| Jedi answered all four questions on the issue thread (2026-07-20). Inventoried every GH-211/GH-178 surface from the shipped commits (**§ Inventory of touched surfaces**) and locked the reporting contract + file ownership (**§ Decision**): one issue, two lanes (consult / relay), `giant-brains` deferred. Work branched to `gh-226/provenance-coordination`. | Post the follow-up comment to Jedi confirming locked scope + linking the draft execution plan. On his sign-off, promote this doc 1-INBOX → 2-WORKING with the bounded contract and fire the two-lane pass. |

## Problem summary

Jedi's note was not about re-opening the already-shipped GH-211 TLDR/category formatting work or
GH-178's narrow provenance stamp in isolation. The point was the overlap between them:

- **GH-211** intentionally changed the **operator-facing summary shape** only.
- **GH-178** intentionally shipped only a **narrow provenance slice**, not the full firsthand-vs-asserted taxonomy.
- A future provenance pass that ignores GH-211's changed summary surface will likely touch the same
  operator-facing layer a second time and drift between consult, relay, and transcript semantics.

That makes this a coordination/design issue first, not a "small missing patch" bug.

## Why this is a separate follow-up

This issue exists because neither parent issue actually owned the boundary between format and provenance:

- **GH-178** deliberately stopped at presence/absence-style provenance stamping.
- **GH-211** deliberately avoided verdict/provenance semantics.

The missing work is deciding how fuller provenance should appear in the **human-facing report**
without fighting the already-shipped TLDR/category structure.

## Questions this issue owns

1. Which operator-facing surfaces are in scope for the coordinated provenance pass?
2. Should consult and relay present provenance identically, or only consistently?
3. What is the minimum viable next distinction:
   - cited vs uncited
   - firsthand-read vs operator-asserted
   - conditional vs verified verdicts
4. Does the next execution stay one issue, or split into:
   - this repo's consult/transcript surfaces
   - the external relay skill/reporting surface in `giant-brains-claude-skills`

## Definition of done

- [x] Inventory the operator-facing summary surfaces touched by GH-211 and the provenance surfaces touched by GH-178. → **§ Inventory of touched surfaces**
- [x] Decide the reporting contract for fuller provenance so the operator-facing layer is edited once, not twice. → **§ Decision**
- [x] Record explicit file ownership and repo boundaries for the next implementation pass. → **§ Decision → File ownership**
- [x] Either:
  - [x] promote this issue into active execution with a bounded contract (**one issue, two lanes**), or
  - [ ] ~~split it into narrower follow-up issue(s)~~ — rejected; see **§ Decision → One issue vs. split**.

> Scope decisions below reflect Jedi Wright's issue-thread answers (2026-07-20). Pending his sign-off
> on the draft execution plan before promotion out of 1-INBOX.

## Inventory of touched surfaces

Built 2026-07-20 from `git log`/`git show` of the shipped GH-211 and GH-178 commits (not from
memory). Checkboxes track which surfaces the coordinated provenance pass must account for.

### A. GH-211 — operator-facing summary surfaces (format only, `91f2fda`)

- [x] `skills/consult/SKILL.md` — **the consult operator-summary contract.** Step 4 "Reconcile"
  reshaped from 3 parts → 4: added **TLDR** (front, the operator's exit ramp), **Disagree**
  (adjudication body), and **Sorted categories** at the close (`Blocking` / `Worth doing, optional`
  / `Skip · out of scope`), replacing the bare prose recommendation. This is the surface Jedi's
  Q1 placement decision lands on: provenance goes in **Disagree/adjudication + inline**, never the TLDR.
- [x] `ROADMAP.md`, `ROADMAP-DASHBOARD.md` — ledger pointer only, not a report surface (intake noise).
- [ ] **Relay's operator-facing report shape was NOT touched by GH-211** — it lives in the external
  `giant-brains-claude-skills` repo. ⚠️ **Asymmetry finding:** today only *consult's* summary has been
  reshaped; relay's operator report has not. The "already-reworked summary surface" in the issue title
  is consult-only. This is why Jedi defers giant-brains — aligning relay's report is a separate, later step.

### B. GH-178 — provenance surfaces, narrow slice (`17c1dc4`, `a7f5b04`, `d85da37`, `54972e9`, `52a94ef`)

Bash implementation (`relay-automation/`):
- [x] `relay-automation/consult.sh` — three distinct provenance mechanics:
  - **A4 stamp:** `NO FIRSTHAND VERIFICATION CITED — treat conclusions as conditional` per uncited advisor.
  - **A2 stamp:** `SINGLE-MODEL — NOT RECONCILED` / `DEGRADED-SINGLE-MODEL.txt` when only one advisor answered.
  - **Prompt-trace classifier → `*.PROVENANCE.txt` sidecar:** computes `FIRSTHAND_COUNT` vs
    prompt-echoed claims and emits `PROVENANCE_WARNINGS`. 🔑 **Key finding:** this is *exactly* Jedi's
    Q3 firsthand-read-vs-operator-asserted distinction — and it is **already computed today**, but only
    written to a sidecar file and surfaced as a `warn()`. It is **never rendered into the operator
    report.** The next pass is largely "surface an existing signal into the adjudication body," not
    "build a new classifier."
- [x] `relay-automation/relay-turn-lib.sh` — the relay-side citation mechanic: `rtl_has_uncited_claim()`
  (read-only predicate, shared with consult's A4) + `rtl_check_uncited_findings()` (per-line downgrade
  that rewrites the relay file in place). This is the relay "reviewer citation discipline" surface —
  Jedi's Q2 second contract.
- [x] `relay-automation/new-relay.sh` — reviewer template wording (asks reviewer to cite evidence).
- [x] `relay-automation/README.md` — documents the citation/provenance behavior.

Python cutover (must stay in parity — ⚠️ **any provenance change touches two implementations, not one**):
- [x] `utils/py/consult.py` — port of A4 citation stamp, A2 degraded stamp, and `rtl_has_uncited_claim`.
- [x] `utils/py/agy-turn.py` — GH-178 B1 advisor-grounding / isolation-boundary check (fail-open).

Tests pinning current behavior:
- [x] `test/consult.sh`, `test/relay-uncited-findings.sh`.

### C. Cross-cutting facts the Decision must carry

1. **Two contracts, confirmed by the code, not just Jedi's opinion.** consult's provenance mechanic keys
   on *advisor grounding* (firsthand read vs. prompt-echoed); relay's keys on *reviewer citation
   discipline* (`rtl_check_uncited_findings`). Different code, different failure mode → Jedi's Q2 "different
   contracts" is already reflected in the implementation.
2. **Dual bash+Python surface.** Provenance lives in both `relay-automation/*.sh` and `utils/py/*.py`;
   they are kept at parity deliberately (GH-223/GH-255). Scope the pass as ~2× the file count.
3. **The Q3 target signal already exists** (see A4 sidecar above) — the next pass is a *surfacing +
   placement* job (move `FIRSTHAND_COUNT`/echoed classification into the Disagree/adjudication body and
   inline annotations), plus flagging prompt-only conclusions as `conditional`. Lower build risk than
   the issue's "full taxonomy" framing implies.
4. **Placement decision (Jedi, confirmed 2026-07-20):** provenance renders in the **adjudication body +
   inline finding annotations**, NOT the TLDR. In `consult/SKILL.md` terms that is the **Disagree**
   block and per-item notes inside **Sorted categories** — not the new TLDR line.

## Decision

Locks the four questions this issue owns, using Jedi's thread answers (2026-07-20) as the spec and
the inventory above as the reality check. This is the reporting contract the next pass implements.

### Q3 — primary provenance key (settled)

**Firsthand-read vs. operator-asserted is the primary key. Cited-vs-uncited is a secondary UI
affordance, not the pivot.** A conclusion is stamped by *where it rests*:

| Stamp | Meaning | Operator treatment |
|---|---|---|
| `firsthand` | advisor/reviewer read it in-worktree (has a quoted span or `file:line`) | trust as verified |
| `operator-asserted` | rests only on a claim handed to it in the prompt | **flag `conditional`** |
| `uncited` | a `[Pass]`/verified-style claim with no citation nearby | surface as a caveat (existing A4 stamp) |

Rationale (Jedi): a reviewer can cite a claim it never verified, and a prompt-embedded fact
masquerades as a firsthand read unless tracked at the source. **This distinction is already computed**
— consult.sh's `*.PROVENANCE.txt` sidecar emits `FIRSTHAND_COUNT` and a prompt-echoed classifier
(`PROVENANCE_WARNINGS`). The next pass surfaces that existing signal; it does not build a new one.

### Q1 — placement (settled)

**Provenance renders in the adjudication body + inline finding annotations. Never the TLDR.** The TLDR
is the operator's exit ramp; a `conditional` flag buried there gets skimmed past. In `consult/SKILL.md`
terms (per GH-211's 4-part shape): provenance lives in the **Disagree** block and as per-item notes
inside **Sorted categories** — the TLDR line stays a clean call + confidence only.

### Q2 — consult vs. relay contracts (settled)

**Shared surface, separate contracts.** The inventory confirms this is already true in code, not just
preference:

- **consult** keys on *advisor grounding* — did the advisor read the repo or answer from priors?
  (mechanic: `*.PROVENANCE.txt` firsthand classifier + A4 stamp in `consult.sh` / `consult.py`).
- **relay** keys on *reviewer citation discipline* — did the reviewer quote evidence for a "verified"
  finding or assert it? (mechanic: `rtl_check_uncited_findings` / `rtl_has_uncited_claim` in
  `relay-turn-lib.sh`).

They may share a rendering convention; they must **not** share a single stamp definition, or one
silently stands in for the other.

### Q4 — one issue vs. split (decided: **one issue, two lanes**)

Kept as a single coordinated issue rather than split by repo. Executed as two non-overlapping lanes:

- **Lane C (consult):** `skills/consult/SKILL.md` + `relay-automation/consult.sh` + `utils/py/consult.py`.
- **Lane R (relay):** `relay-automation/relay-turn-lib.sh` (+ `new-relay.sh`, `README.md`).

`giant-brains-claude-skills` is **explicitly out of scope** for this pass (Jedi): its relay operator
report was never reworked by GH-211 (see asymmetry finding), so there is nothing to coordinate against
yet. Align it in a later follow-up once these mechanics settle. Opening that repo boundary now widens
blast radius without changing any core design decision here.

### File ownership (next implementation pass)

| Lane | Owns (writes) | Parity requirement |
|---|---|---|
| C — consult | `skills/consult/SKILL.md`, `relay-automation/consult.sh`, `utils/py/consult.py`, `test/consult.sh` | bash `consult.sh` ↔ Python `consult.py` must stay at parity (GH-223/GH-255) — any stamp change lands in both. |
| R — relay | `relay-automation/relay-turn-lib.sh`, `relay-automation/new-relay.sh`, `relay-automation/README.md`, `test/relay-uncited-findings.sh` | `rtl_has_uncited_claim` is shared by both call sites — keep the predicate single-sourced. |
| — deferred | `giant-brains-claude-skills` (external) | later follow-up issue; not this pass. |

Lanes C and R touch disjoint files → safe to run concurrently. The only shared dependency is the
`rtl_has_uncited_claim` predicate (already single-sourced in `relay-turn-lib.sh` and consumed by
consult), so a contract change to it is a **Lane R deliverable Lane C consumes**, not a collision.

### Draft execution plan

The fireable two-lane plan lives in
[`PROJECT/2-WORKING/MARATHON-PLAN-2026-07-20-M-GH226-PROVENANCE-IMPL.md`](../2-WORKING/MARATHON-PLAN-2026-07-20-M-GH226-PROVENANCE-IMPL.md)
(Plan M): Wave 1 single-sources the firsthand/operator-asserted contract in the shared predicate,
Wave 2 renders it into the consult and relay surfaces in parallel. **Held for Jedi's sign-off** — not
promoted to active execution, not fired.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "utils/pdda/pdda.sh roadmap-coverage",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md",
      "pattern": "## Inventory of touched surfaces"
    },
    {
      "type": "grep_absent",
      "path": "PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md",
      "pattern": "## Decision"
    }
  ],
  "artifacts": [
    "PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md",
    "PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-I-PROVENANCE-SUMMARY-COORDINATION.md"
  ],
  "remediation": {
    "source": "issue#226",
    "criteria": "GH-226's local doc gains an Inventory of touched surfaces section covering GH-211 and GH-178 operator-facing/provenance surfaces, plus a Decision section stating whether the next pass stays one coordinated issue or splits by repo/surface. The standalone marathon plan is kept in sync with that decision. utils/pdda/pdda.sh roadmap-coverage passes."
  },
  "lanes": { "agy_safe": [], "orchestrator_only": [] }
}
```
