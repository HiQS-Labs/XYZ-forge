---
gh_issue: 83
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/83
title: README onboarding UX — single operator path, plain-language intro, de-brittle stale test count
status: Closed (issue #83 closed)
created: 2026-07-02
updated: 2026-07-02
owner: noel
doc_type: docs
complexity: 2
risk: 1
effort: 2
roadmap_exempt: false
non_goals:
  - Not a rewrite of ROUTER.md or AGENTS.md — those stay the agent-facing startup map; this only fixes README's human-facing landing page
  - Not touching relay-automation/README.md content — only linking to its existing "Headless bring-up (Codex + agy)" section
  - Not adding new features or docs — a trim + reorder + de-brittle of the existing README (least-code, DRY)
related:
  - README.md
  - ROUTER.md
  - relay-automation/README.md
---

# GH-83 — README onboarding UX

## Signal

Cross-model `/consult` (Codex `gpt-5.4` + agy) reviewed `README.md` cold as a brand-new
operator. Both independently graded the same issues **[Blocker]**. Raw transcripts:
`relay-system/2026-07-02/readme-onboarding-125602/`.

## Agreed findings (reconciled)

1. **No single "do this first"** — the top fires four starting moves at once (ROUTER.md,
   `./validate.sh`, a 4-step "Start here", `install.sh`). *(Blocker, both)*
2. **Humans sent to `ROUTER.md` first** — ROUTER self-declares it is the agent entry point;
   README is the human overview. *(Blocker, both)*
3. **Insider-heavy opener** — "coordination spike", `tick`, `relay-automation/` used before
   defined. *(Should, both)*
4. **Stale test count (freshness bug)** — README claims `47/47` twice; `validate.sh` is
   actually `80/80`. Docs disagree with reality → docs are the bug (GUIDING-PRINCIPLES #9).
5. **Indirect auth pointer** — line 10 says per-CLI auth is "see Start here below"; the real
   path is `relay-automation/README.md#headless-bring-up-codex--agy`, never linked directly.
   *(agy's unique catch)*
6. **Serves 4 audiences at once** — "Install into another repo" appears before "What `tick`
   is". *(Should, both)*

## Fix

Rewrite README's top into a self-sufficient human landing page: plain-language two-layer value
prop + honest beta note → **one** Step 1 (`./validate.sh`) → explicit path branch (live relay /
kernel / install) → 4-line glossary. Scope the ROUTER pointer as agent-facing. De-brittle the
test count (stop hardcoding it). Move install/kernel mechanics below the concept sections.

## Definition of done

- README top stands alone for a human with one unmistakable first action.
- No stale hardcoded test count anywhere in README.
- Auth pointer links directly to the bring-up section.
- `./validate.sh` green + `utils/pdda/pdda.sh run` clean.
