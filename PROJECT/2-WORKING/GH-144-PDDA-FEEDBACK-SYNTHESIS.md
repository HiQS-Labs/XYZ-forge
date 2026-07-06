---
gh_issue: 144
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/144
complexity: 3
risk: 2
effort: 3
ratings_provisional: true
title: PDDA feedback synthesis — actionable planning doc
status: Active (2-WORKING) — Phases 1-2 verified/completed (marathon Lane C, 2026-07-06): CONSTITUTION.md + DO-NOT-BUILD.md already met their observables; PDDA.md gained a Constitution/DO-NOT-BUILD cross-link, a check severity (blocking vs warn-only) table, and a link to the new PDDA-MODE-GUIDE.md. Phases 3-5 remain deferred, decision-gated on the evidence-bridge open questions below. Issue #144 stays open pending operator decision on Phase 3-5 disposition.
created: 2026-06-23
updated: 2026-07-06
owner: Noel (operator) · Codex (producer)
doc_type: plan
related:
  - PROJECT/1-INBOX/PDDA/FEEDBACK-PERPLEXITY.md
  - PROJECT/1-INBOX/PDDA/FEEDBACK-CHATGPT.md
  - PROJECT/1-INBOX/PDDA/FEEDBACK-GEMINI.md
  - PROJECT/PDDA.md
  - ROUTER.md
goal: >
  Synthesize the June 23 external feedback into one actionable PDDA direction-setting
  plan that keeps PDDA as a thin repo-governance and safety layer, identifies what to
  preserve, what to defer, and what to build next, and sequences the work into phased,
  observable steps with QA gates.
non_goals:
  - Not promoting this to PROJECT/2-WORKING yet; this is a proposal, not active execution.
  - Not turning PDDA into a general spec-driven-development platform or generic AI method.
  - Not rewriting existing PDDA scripts or docs in this pass; this document is the synthesis only.
reviewed:
  - Perplexity feedback: expansive improvement menu, strongest on evidence-bridge ideas
  - ChatGPT feedback: strongest on positioning and scope control
  - Gemini feedback: strongest on freeze/observe-mode pressure and anti-overengineering signal
---

# PDDA feedback synthesis

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1-2 verified/completed** (marathon Lane C, 2026-07-06) — `CONSTITUTION.md`/`DO-NOT-BUILD.md` already satisfied all Phase 1 observables (created in `1019503`/`52f4521`); the deterministic/advisory split, `PDDA_MODE` precedence, and the LLM `error`→`warn` clamp were already documented and verified live in `utils/pdda/pdda-doc-ready.sh:115` (per `2610e45`). Added in this pass: a `PDDA.md`↔`CONSTITUTION.md` cross-link, a "Check severity contract" blocking-vs-warn-only table in `PDDA.md` (audited against the actual `pdda.sh` severities — none found mislabeled), and a new `PROJECT/PDDA-MODE-GUIDE.md` operator guide with concrete observe/light/full triggers. `pdda.sh run` (`full` mode): 0 errors/warns attributable to this lane's files (1 pre-existing unrelated error in a concurrent marathon lane's `MARATHON-142-143-144.md`, outside this lane's edit scope). | **Operator decision needed on Phase 3-5 disposition**: Phases 3–5 (artifact ergonomics, evidence bridge to rebalance, outward integrations) remain deferred and decision-gated — see "Open questions before promotion to 2-WORKING" below. Once decided, either spin 3–5 to a new deferred/future issue and close #144, or keep #144 open pending that work. |

> **Header note (resolved):** this doc has been promoted to `PROJECT/2-WORKING` and already uses
> PDDA's exact active-doc contract header, `What was just completed | What's next` (see the table
> above). This note is kept only as provenance that the rename happened; there is nothing left to do.

## Table of Contents

- [Decision summary](#decision-summary)
- [What the feedback agrees on](#what-the-feedback-agrees-on)
- [What to preserve](#what-to-preserve)
- [What to avoid building](#what-to-avoid-building)
- [Phase 1 — Lock positioning and scope](#phase-1--lock-positioning-and-scope)
- [Phase 2 — Harden the contract and enforcement modes](#phase-2--harden-the-contract-and-enforcement-modes)
- [Phase 3 — Improve artifact ergonomics without becoming Spec Kit](#phase-3--improve-artifact-ergonomics-without-becoming-spec-kit)
- [Phase 4 — Add the evidence bridge to rebalance](#phase-4--add-the-evidence-bridge-to-rebalance)
- [Phase 5 — Add only the integrations that prove the lane](#phase-5--add-only-the-integrations-that-prove-the-lane)
- [Recommended first PRs](#recommended-first-prs)
- [Open questions before promotion to 2-WORKING](#open-questions-before-promotion-to-2-working)

## Decision summary

The verdict is to keep refining PDDA only as a thin repo-governance and safety layer.

The three feedback docs differ in style. They genuinely converge on the *boundary* (first two
bullets); the evidence bridge (third bullet) is **Perplexity's distinctive proposal, not a
three-way agreement** — flagged as such so it is not over-weighted:

- PDDA is strongest when it enforces doc lifecycle, roadmap pointer discipline, deterministic checks,
  advisory LLM review, verified-success reporting, and autonomous-agent safety rails.
  *(Shared across all three.)*
- PDDA is weakest when it tries to become a general planning framework, generic docs linter,
  generic multi-agent runner, or full work-management product.
  *(Shared across all three — ChatGPT and Gemini are emphatic here.)*
- The distinctive *future* surface — the bridge between repo truth and local work evidence
  (`rebalance`) — is **Perplexity's proposal only**: ChatGPT and Gemini do not mention `rebalance`
  and instead converge on scope containment (freeze the custom Bash, offload commodity linting).
  Treated here as a deferred bet, not a consensus mandate.

> **Proposed near-term scope (added after the agy peer review, 2026-06-23):** only **Phase 1**
> (positioning/constitution) and **Phase 2** (contract + enforcement-mode hardening) are proposed for
> near-term execution — both are pure thin-layer governance/safety with low maintenance cost.
> **Phases 3–5 are deferred** to a future/sibling track and must not be built until the open question
> on the evidence bridge (below) is resolved. This keeps the proposal aligned with its own anti-scope
> list and with Gemini/ChatGPT's "freeze and contain" signal rather than expanding PDDA into a platform.

## What the feedback agrees on

- **Perplexity:** expand carefully around a constitution, artifact taxonomy, evidence snapshots,
  clarify/analyze/checklist/converge steps, and prioritization driven by local evidence.
- **ChatGPT:** do not compete head-on with Spec Kit, Task Master, OpenHands, AGENTS.md, or generic
  docs-as-code tooling; preserve the strict lifecycle/ledger/checking layer.
- **Gemini:** freeze the Bash unless a gap is real, lean on `PDDA_MODE` as the escape hatch, and
  prefer observe/light modes to avoid a brittle strict system eating product time.

The synthesis is not "average the three." It is:

1. Keep the thin, opinionated kernel.
2. Make the kernel's boundaries explicit.
3. Add the evidence bridge only where it strengthens that kernel.
4. Refuse platform sprawl.

## What to preserve

- `ROADMAP.md` as a pointer ledger, never a second plan body.
- `PROJECT/PDDA.md` as the canonical active-doc contract.
- Deterministic checks as the only blocking layer.
- LLM review as advisory only, never a build blocker.
- "Do not report success unless the relevant validation ran."
- Relay containment, cost visibility, and recovery/safety work as a separate but related trust layer.
- The option to stay in `observe` or `light` mode when strictness costs more than it saves.

## What to avoid building

- A generic spec-driven-development framework.
- A generic PRD-to-tasks generator as a product surface.
- A generic multi-agent platform or agent marketplace.
- A full Kanban or visual project-management UI before the CLI/MCP contract is stable.
- Replacements for commodity Markdown linting when off-the-shelf tools are enough.
- New Bash or policy complexity unless a measured gap justifies it.

## Phase 1 — Lock positioning and scope

**Intent:** define the lane before adding more mechanics. If this phase is skipped, later work will
recreate the same argument inside every script and planning doc.

### Checklist

- [x] Create `PROJECT/CONSTITUTION.md` or equivalent and state the non-negotiables explicitly:
      local-first privacy, deterministic-before-LLM, verified-success-only, reversibility on
      destructive actions, and no hidden cloud sync for private notes.
      *Observable:* file exists, is linked from `ROUTER.md`, and names the required principles.
      **Already done** (`1019503`) — verified 2026-07-06: `ROUTER.md:14` links it; all five
      non-negotiables are named under "Non-negotiables".
- [x] Create `PROJECT/DO-NOT-BUILD.md` and record the explicit anti-scope list from this synthesis.
      *Observable:* file exists and lists at least the five avoided product directions above.
      **Already done** (`52f4521`) — verified 2026-07-06: 6 entries in the table plus 2 restated
      items, all attributed to their source feedback doc.
- [x] Add one positioning section to `PROJECT/PDDA.md` or a sibling doc that states PDDA's lane in
      one paragraph: "thin repo-governance and safety layer," not "general AI project framework."
      *Observable:* a grep for `thin repo-governance and safety layer` returns one canonical hit.
      **Already done** — the phrase lives once, canonically, in `PROJECT/CONSTITUTION.md:3` (the
      "sibling doc" the observable allows). Done-now: added a cross-link from `PROJECT/PDDA.md`'s
      intro back to `CONSTITUTION.md`/`DO-NOT-BUILD.md` (without repeating the exact phrase, so the
      one-canonical-hit grep still holds) for startup-path symmetry.
- [x] Record the deterministic/advisory split as policy: deterministic checks may block; LLM review
      may warn only.
      *Observable:* the policy is present in one canonical file, not implied across comments.
      **Already done** — `PROJECT/CONSTITUTION.md` → "Deterministic vs. advisory split".
- [x] Decide whether `PDDA_MODE` default should remain permissive (`observe` or `light`) outside
      deliberate hardening work.
      *Observable:* the default and its rationale are documented in one place.
      **Already done** — default is `observe`, documented + rationale in
      `PROJECT/CONSTITUTION.md` → "Enforcement-mode default" and mechanically in `PROJECT/PDDA.md` →
      "Enforcement modes".

### QA checklist — Phase 1

- [x] A new agent can answer "what is PDDA for?" by reading one file, not reconstructing it from
      feedback threads. — `PROJECT/CONSTITUTION.md`'s opening paragraph answers this in one read.
- [x] The constitution and do-not-build files are linked from the startup path (`ROUTER.md` or a
      doc it directly points to). — confirmed `ROUTER.md:14-15`.
- [x] The deterministic-vs-LLM rule is stated once canonically and does not conflict with
      `PROJECT/PDDA.md`. — `CONSTITUTION.md` explicitly names `PDDA.md` as the implementation of
      record for the same split; no conflict found.
- [x] Scope-control docs do not introduce a second roadmap or duplicate the plan body. — confirmed;
      both docs are governance/policy, not plan bodies, and carry no task checklists.

## Phase 2 — Harden the contract and enforcement modes

**Intent:** make the current system safer and cheaper to live with before adding new features.

### Checklist

- [x] Document precedence when both `PDDA_MODE` env and any file-based mode indicator are set.
      *Observable:* one explicit precedence rule exists; no ambiguity remains.
      **Already done** (`2610e45`) — `PROJECT/PDDA.md` → "Enforcement modes": env `PDDA_MODE` wins
      if set, else first non-comment line of `.pdda-mode`, else built-in default `observe`.
- [x] Clamp every LLM readiness or reviewer finding to `warn` max before wider activation.
      *Observable:* no LLM path is capable of emitting a blocking severity in the documented contract.
      **Already done, verified live** (`2610e45`) — documented in `PROJECT/PDDA.md` → "LLM-assisted
      doc readiness review", and confirmed in code: `utils/pdda/pdda-doc-ready.sh:115` clamps any
      `error` severity to `warn` before it can be recorded.
- [x] Audit the existing deterministic scripts and remove or demote any check that is acting like
      policy theater rather than catching real drift.
      *Observable:* each check is tagged internally or documented as blocking vs warn-only.
      **Done now** — audited all 8 deterministic checks' actual `pdda_record_finding` severities in
      `utils/pdda/pdda.sh` and added a "Check severity contract" table to `PROJECT/PDDA.md` (after
      section 1). Finding: severities were already correctly calibrated — no check found acting as
      policy theater; `changelog`, `stale`, and `issue-doc-sync` were already warn-only per `2610e45`,
      now made explicit in one table instead of implied across script comments.
- [x] Make the stale-doc and destructive-action rules explicitly reversible and human-mediated.
      *Observable:* destructive auto-repair remains absent or clearly gated.
      **Already done, verified live** (`2610e45`) — `pdda.sh stale` and `pdda.sh issue-doc-sync` only
      emit a `warn` recommending the exact `git mv`; grepped `utils/pdda/*.sh` for any auto-move/
      auto-rm of a repo doc and found none (only tmp-file cleanup in `pdda-gh-refresh.sh`, unrelated).
- [x] Write a short "when to stay in observe/light mode" operator guide.
      *Observable:* guide exists and names concrete triggers for not using strict/full mode.
      **Done now** — created `PROJECT/PDDA-MODE-GUIDE.md` with concrete stay-below-`full` triggers
      (fresh install, known untriaged backlog, active migration, new/changed check, low value-to-
      friction ratio, single-operator repo) and graduate-to-`full` triggers, linked from both
      `PROJECT/PDDA.md` and `PROJECT/CONSTITUTION.md`.

### QA checklist — Phase 2

- [x] A reviewer can point to one source of truth for enforcement severity and mode precedence. —
      `PROJECT/PDDA.md` → "Enforcement modes" (precedence + mode table) and the new "Check severity
      contract" table (per-check severity capability).
- [x] No documented LLM step can block a build. — confirmed in doc and in code
      (`pdda-doc-ready.sh:115`).
- [x] Every destructive or quasi-destructive action has an explicit rollback or human gate. —
      confirmed: stale-doc and issue-doc-sync drift are both flag-only, recommending a human-run
      `git mv`; no code path executes the move.
- [x] The operator guide uses real examples of when strictness is worth the friction and when it is
      not. — `PROJECT/PDDA-MODE-GUIDE.md` names six concrete stay-below-`full` scenarios and three
      graduate-to-`full` scenarios, not abstract advice.

## Phase 3 — Improve artifact ergonomics without becoming Spec Kit

> **Status: Deferred (future track).** Not part of the near-term proposed scope (Phases 1–2). Kept
> here as forward design only; do not start until the evidence-bridge open question is resolved.

**Intent:** borrow the useful parts of spec/task discipline without cloning another framework.

### Checklist

- [ ] Define the minimum artifact taxonomy for larger work: when a single active doc is enough and
      when a feature folder with `SPEC.md`, `PLAN.md`, `TASKS.md`, and `EVIDENCE.md` becomes worth it.
      *Observable:* one doc states the folder threshold and example shape.
- [ ] Add a lightweight clarify gate for multi-phase work before promotion to `PROJECT/2-WORKING`.
      *Observable:* the contract names required clarifications or an explicit exemption field.
- [ ] Define task requirements for phased plans: ID, dependency note, write scope, verification
      command, and expected evidence artifact.
      *Observable:* the task contract is written down in one canonical place.
- [ ] Add a checklist generator or template only if it covers PDDA-specific categories that generic
      templates miss: privacy, evidence readiness, rollback path, changelog provenance.
      *Observable:* categories are listed and justified as PDDA-specific.
- [ ] Add a warn-only cross-artifact analyzer concept that compares roadmap, plan, tasks, and
      evidence for contradictions.
      *Observable:* the analyzer's intended finding classes are enumerated before implementation.

### QA checklist — Phase 3

- [ ] The artifact model is smaller and clearer than Spec Kit, not a local clone of it.
- [ ] A small bugfix can still stay a single doc without violating the contract.
- [ ] Multi-phase plans have observable task fields and post-phase QA gates.
- [ ] Any analyzer remains warn-only until false-positive rate is proven acceptable.

## Phase 4 — Add the evidence bridge to rebalance

> **Status: Deferred (future track), decision-gated.** Not in the near-term scope. This is
> **Perplexity's** distinctive proposal (not a three-way consensus — see Decision summary), so it is a
> deferred bet gated behind the open question on whether it becomes its own sibling track.

**Intent:** connect repo state to actual work signals — the distinctive lane **Perplexity** identified
(ChatGPT and Gemini did not raise it).

### Checklist

- [ ] Define one evidence snapshot artifact or command that joins active docs with local evidence:
      commits, notes, calendar, issues, stale docs, and freshness state.
      *Observable:* the output contract names both Markdown and machine-readable forms.
- [ ] Add an evidence-freshness block to high-level answers and reports so stale sources do not
      masquerade as current truth.
      *Observable:* freshness categories and wording are specified.
- [ ] Define one weekly prioritization command for PDDA + rebalance that answers:
      what got real attention, what is stale, what is over-consuming time, and what lacks provenance.
      *Observable:* the question set is fixed in the command contract.
- [ ] Define one morning brief contract that combines active roadmap items, work evidence, calendar
      constraints, and suggested next action.
      *Observable:* each recommendation must cite an artifact or evidence source.
- [ ] Keep the bridge read-first: snapshot and ranking before mutation or auto-rewrite.
      *Observable:* no silent rewriting is allowed in the first version.

### QA checklist — Phase 4

- [ ] Every recommendation in the evidence snapshot or morning brief cites a local artifact or evidence row.
- [ ] Freshness is visible enough that a stale source cannot quietly drive prioritization.
- [ ] The bridge strengthens PDDA's lane instead of turning it into a general personal dashboard.
- [ ] First versions are additive reports, not hidden mutators.

## Phase 5 — Add only the integrations that prove the lane

> **Status: Deferred (future track).** Not in the near-term scope (Phases 1–2). Forward design only;
> gated behind the same evidence-bridge decision as Phases 3–4.

**Intent:** integrate outward only where it reinforces the governance/evidence contract.

### Checklist

- [ ] Promote the task-list to GitHub issue bridge only if it round-trips stable source pointers and
      verification commands.
      *Observable:* one trial issue links back to its source doc and the source doc links back.
- [ ] Define agent/integration profiles only if they clarify real operational differences:
      sandbox needs, cost visibility, MCP/browser support, self-commit rules, multi-repo limits.
      *Observable:* profile fields are concrete and operational, not marketing descriptions.
- [ ] Package relay containment as a named safety contract rather than scattering it across comments.
      *Observable:* one canonical safety artifact names worktree isolation, commit policy, epoch
      fencing, stale-writer prevention, and recovery boundaries.
- [ ] Surface scheduler health only if it directly affects freshness and recommendation trust.
      *Observable:* scheduler status fields map to recommendation suppression or caution rules.
- [ ] Refuse any integration that exists only because another ecosystem has it.
      *Observable:* each accepted integration has a one-line statement of differentiated value.

### QA checklist — Phase 5

- [ ] Every integration has a clear reason tied to PDDA's lane.
- [ ] No integration introduces a second planning framework or duplicate control plane.
- [ ] Safety-contract docs match the actual relay/runtime behavior.
- [ ] External bridges remain auditable and reversible.

## Recommended first PRs

PRs 1–2 are the near-term, low-maintenance changes the feedback most strongly supports (all three
sources agree), in order. PR 3 is **deferred and decision-gated** — listed for sequencing only, not
for near-term execution.

1. **Constitution + do-not-build boundary** *(near-term)*
   - Why: it prevents scope drift before more tooling is added.
   - Success signal: a new agent or contributor can explain PDDA's lane after one read.
2. **Enforcement-mode and LLM-severity hardening** *(near-term)*
   - Why: it lowers operational friction and removes the most dangerous policy ambiguity.
   - Success signal: no LLM path can block, and `PDDA_MODE` behavior is explicit.
3. **Evidence snapshot bridge** *(deferred — Phase 4; gated by the open question below)*
   - Why: it is the most differentiated next move (Perplexity's proposal) and connects PDDA to rebalance.
   - **Dependency guard:** when it does ship, the first version must operate **only on existing
     single-file active docs** plus git/notes signals — it must **not** depend on the Phase 3 artifact
     taxonomy, or the two deadlock. Either lock artifact structure (Phase 3) first, or keep the
     snapshot strictly single-file-scoped.
   - Success signal: PDDA can rank or flag work using cited local evidence rather than docs alone.

## Open questions before promotion to 2-WORKING

- Should the constitution live at `PROJECT/CONSTITUTION.md`, `.rebalance/constitution.md`, or another
  path that can be shared across repos?
- Is feature-folder promotion a real need now, or should PDDA first prove the evidence bridge and
  defer artifact expansion?
- Which single evidence output should ship first: weekly priorities, morning brief, or a neutral
  `EVIDENCE-SNAPSHOT.md`?
- Does the repo want one combined PDDA+rebalance plan, or should the evidence bridge become its own
  sibling track once execution starts?
- Should the custom deterministic Bash checks be replaced (or partly offloaded) by a standard
  `.markdownlint.json` — plus `Vale`/`lychee` for prose and link hygiene — keeping only the
  repo-specific agent-operating-contract checks as custom code? Both Gemini (`FEEDBACK-GEMINI.md`) and
  ChatGPT (`FEEDBACK-CHATGPT.md`) recommend this to cut maintenance overhead. The real question is
  *which* checks (the exact `## Status` header, the hardcoded-path ban, the pointer-only `ROADMAP.md`
  contract) are hard to express in off-the-shelf linters and must stay custom.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"path_absent","path":"PROJECT/CONSTITUTION.md"},{"type":"path_absent","path":"PROJECT/DO-NOT-BUILD.md"}],"artifacts":["PROJECT/CONSTITUTION.md","PROJECT/DO-NOT-BUILD.md"],"artifacts_new":["PROJECT/CONSTITUTION.md","PROJECT/DO-NOT-BUILD.md"],"lanes":{"orchestrator_only":[]}}
```
