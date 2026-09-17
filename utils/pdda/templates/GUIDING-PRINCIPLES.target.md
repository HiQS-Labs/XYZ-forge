# Guiding Principles

The north star this repo's goals and implementation decisions answer to. When a design choice is
unclear, the option that better serves these principles wins.

## Purpose

PDDA exists to make a repo's project docs a **reliable source of truth and work signal for
long-running AI agent tasks** — so an agent (or human) can stop, resume, or hand off at any point and
recover full state from the docs alone, not from memory or chat history.

## Principles

1. **Docs are the runtime state, not a record of it.** The current `PROJECT/**` docs *are* the
   project's state. If reality and the docs disagree, that is the bug to fix.
2. **Resumable by a cold agent.** Every active doc must let an agent with zero prior context answer
   "what was just done, what's next" in seconds — that's why the status header is a contract.
3. **Deterministic where judgment isn't needed.** Scripts enforce the mechanical rules; the LLM
   reviewer only handles what regex can't. Never make an agent re-decide settled hygiene.
4. **One canonical place per fact.** `ROADMAP.md` points, project docs hold detail, `CHANGELOG.md`
   logs outcomes. No fact lives in two places where they can drift.
5. **A clear signal of what is live.** `PROJECT/2-WORKING` holds only truly active work, so "what
   should an agent pick up" is never ambiguous.
6. **Low-friction and portable.** The contract must be cheap to adopt (a one-command install) and
   cheap to obey, or agents will route around it.
7. **Default to the reversible action; require evidence for the expensive one.** When an item is
   stale, orphaned, or its dependency has left the repo, *close / park / archive is the default* —
   those are cheap and undoable. Keeping it open is what costs: it buys recurring triage attention on
   every future pass. So the burden of proof sits on **keeping**, not on closing. State a default and
   the one fact that would overturn it, rather than presenting symmetric options — "close as obsolete,
   or re-scope?" is how an item sits untouched for nine days.
8. **A finding that was reported is not a finding that was seen.** Detection is only half a check.
   If a run's closing line contradicts its own output, the signal is lost no matter how correct the
   detector was — so summary lines must reflect what was actually found. Corollary of #3: being
   deterministic about *detecting* is wasted if the *reporting* rounds it off.

## How to apply

When adding a feature or making a tradeoff, ask: *does this make project state more resumable,
less ambiguous, and harder to drift for a long-running agent?* If not, reconsider.

When triaging existing work, ask: *what is the reversible move here, and what single fact would
argue against it?* Then say that, rather than listing options.
