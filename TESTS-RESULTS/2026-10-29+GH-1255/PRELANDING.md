# Pre-landing review corrections

Rebalance dd8c558 removes upstream transcript copies, links the canonical Forge reviews, places recovery after scheduling, and limits durable retry claims to files reached by the replay. An interrupted whole scan must be repeated explicitly. Capture runtime and existing suites are byte-unchanged from f89758e.

Forge corrects the dated heading, upstream PR pointer and current review/roadmap status. The first peer review caught a status edit clearing four ratings; the existing roadmap update verb restored 85/85/50/65 plus canonical links. The second independent review Approved, with driver attestation in `relay-system/2026-10-29/gh1255-prelanding.codex.md`.

Forge PDDA: zero errors, 39 existing warnings. Rebalance observe-mode PDDA: 25 existing findings, unchanged from prior receipt. RELEASES check remains clean with existing warnings. No runtime suite rerun for these documentation-only corrections. Deployment acceptance remains pending.
