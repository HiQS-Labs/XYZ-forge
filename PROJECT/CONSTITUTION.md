# Constitution

**PDDA's lane, stated in one line: a thin repo-governance and safety layer.** Not a general AI
project-management framework, not a spec-driven-development platform, and not a coding-agent runner.
This document states that lane's non-negotiables so later scripts, docs, and agents point at one
canonical policy instead of re-arguing it inside every plan.

This is a synthesis of the June 23, 2026 external feedback review (Perplexity, ChatGPT, Gemini),
reduced and agreed by the operator, and reviewed by agy (`relay-system/2026-06-23/pdda-feedback-synthesis.md`).
See [`PROJECT/2-WORKING/GH-144-PDDA-FEEDBACK-SYNTHESIS.md`](2-WORKING/GH-144-PDDA-FEEDBACK-SYNTHESIS.md)
for the full synthesis this document distills. This file states the non-negotiables the synthesis
already agreed on; it does not add new ones the synthesis did not name.

## Non-negotiables

- **Local-first privacy.** Personal work evidence (notes, calendar, git pulse, local vault content)
  stays local by default. No hidden cloud sync for private notes.
- **Deterministic before LLM.** A finding that can be expressed as a regex, schema, or
  file-existence check must be checked deterministically first. LLM review only covers what
  deterministic checks cannot express.
- **Verified-success-only.** Do not report a win — a build, a fix, a completed phase — unless the
  relevant validation script or test actually ran and passed. This applies to every agent working
  in this repo, not only PDDA-governed doc work.
- **Reversibility on destructive actions.** Any destructive or quasi-destructive action (auto-repair,
  stale-doc handling, self-repair) must have an explicit rollback path or an explicit human gate.
  Silent, unreviewable mutation is never acceptable.
- **No hidden cloud sync for private notes.** Restated for emphasis: local evidence bridges (e.g. a
  future rebalance/PDDA connection) must not upload private notes to a third party as a side effect
  of convenience.

## Deterministic vs. advisory split

- Deterministic checks (regex, schema, file-existence, path/format validation) **may block** a build.
- LLM-based review (readiness review, planning-quality checks, cross-artifact analysis) **may warn,
  propose, or rank — it may never block.** Any LLM-emitted `error` severity is clamped to `warn`.
- Destructive repair actions require explicit operator authorization; self-repair, where it exists,
  may choose only from a bounded, pre-approved menu — never an open-ended rewrite.

This split is already implemented mechanically in [`PROJECT/PDDA.md`](PDDA.md) (see its "Enforcement
modes" section: deterministic checks gate on `PDDA_MODE`; the LLM layer is advisory and fail-open by
design). This document states the split as a constitutional principle so it cannot be silently
loosened by a future script change without also amending this file. If the two documents ever appear
to disagree, `PROJECT/PDDA.md`'s enforcement mechanics are the implementation of record; this document
is the policy of record — a discrepancy is a bug in one of the two, not a license to pick either.

## Enforcement-mode default

The default enforcement mode stays **permissive** (`observe`) outside deliberate hardening work,
matching Gemini's freeze/observe-mode signal from the June 23 feedback: a system like this should warn
about doc rot, not block a perfectly good build, until a repo deliberately opts into `full`. The
precedence rule between `PDDA_MODE` (env) and a committed `.pdda-mode` file, and the `observe` /
`light` / `full` ladder, are already documented canonically in `PROJECT/PDDA.md` → "Enforcement
modes" — this document does not restate the mechanics, only ratifies the default as policy. For
concrete operator triggers on when to stay below `full`, see
[`PROJECT/PDDA-MODE-GUIDE.md`](PDDA-MODE-GUIDE.md).

## Scope boundary

What this layer should build more of, and what it must not become, is recorded separately in
[`PROJECT/DO-NOT-BUILD.md`](DO-NOT-BUILD.md) so the anti-scope list is not buried inside a phased plan.

## Sources

- [`PROJECT/2-WORKING/GH-144-PDDA-FEEDBACK-SYNTHESIS.md`](2-WORKING/GH-144-PDDA-FEEDBACK-SYNTHESIS.md)
  — the synthesis this document distills (Decision summary, "What to preserve" sections).
- [`PROJECT/1-INBOX/PDDA/FEEDBACK-PERPLEXITY.md`](1-INBOX/PDDA/FEEDBACK-PERPLEXITY.md) — Step 1
  (shared constitution), Step 12 (deterministic-vs-LLM rules).
- [`PROJECT/1-INBOX/PDDA/FEEDBACK-CHATGPT.md`](1-INBOX/PDDA/FEEDBACK-CHATGPT.md) — "The decision" /
  "Do keep the parts that are genuinely opinionated" (pointer ledger, deterministic-then-advisory,
  verified-success-only, safety rails) and the positioning statement quoted at the top of this doc.
- [`PROJECT/1-INBOX/PDDA/FEEDBACK-GEMINI.md`](1-INBOX/PDDA/FEEDBACK-GEMINI.md) — freeze-the-Bash and
  `PDDA_MODE`-as-escape-hatch signal behind the enforcement-mode default above.
- [`PROJECT/PDDA.md`](PDDA.md) — canonical enforcement mechanics for the deterministic/advisory split
  and the `PDDA_MODE` precedence rule.

## Amending this document

This document should change only when the underlying synthesis or a new cross-model feedback review
changes one of the non-negotiables above. Treat it like any other constitution: cheap to read, and
expensive to amend on a whim.
