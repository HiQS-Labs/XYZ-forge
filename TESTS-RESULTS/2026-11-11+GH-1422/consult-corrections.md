# Consult corrections — GH-1422

Reviewed input: PR #1425 at `a4030e356f6542a71d5bf915bf2bc30e635d97a3`.
User authorized agreed corrections after Agy Gemini Flash 3.8 / Claude Code consult.

## Dispositions

- Implemented: restore unclear necessity OR user consequence as sanity-check trigger.
- Implemented: explicitly say when no needed marathon fits.
- Implemented (clarity): put identity comparison before any trust in a run/fetch/push.
- Implemented (historical accuracy): restore telemetry assertion wording about passing runs.
- Rejected: restore stale lexical-only require_fixture claim. At reviewed head,
  test/gh544-pre-push-gate.sh:58–63 imports the shared guard; test/lib/fixture-guard.sh:45–55
  resolves real paths and checks containment. The review's falsifier holds.
- Rejected: duplicate roadmap source/creation commands. Mandatory ROUTER.md:15,194,205
  already names source of truth and add/pickup verbs.
- Rejected: treating FAQ/safety reads as new policy. Mandatory ROUTER.md:185,214 already
  routes relevant changes to FAQ; original AGENTS startup already requires WORKTREE-SAFETY.
- No change: shorter branch and bypass wording retains the relevant limits; historical
  explanations need not be expanded. Prior provenance rows remain historical, not rewritten.

## Verification

Current AGENTS is 27,812 UTF-8 bytes; 4,956 bytes below 32 KiB (also below 28,000 target).
Fresh link/anchor and default tracked instruction-chain probes pass on these exact bytes.
Both restored phrases fail presence checks at a4030e356 and pass on the correction.
Read-through smoke covers principle 6, marathon idle behavior and clone identity sequencing.
See appended provenance.jsonl record for content hash and target list.

Independent review applies to the prior revision; these four small corrections were applied
and checked by the author, without another delegated review. No runtime or policy expansion.

Documentation gate: exit 0, zero errors, 99 existing backlog warnings; summary in consult-docs-gate.txt.
