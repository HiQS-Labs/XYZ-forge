# RELAY · EVE-STUDY plan review (whole-plan feedback)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-02.
-->

NEXT: claude-a
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(eve-study-plan-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **EVE-REVIEW.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-02

### Artifact — EVE-REVIEW.md
````
---
status: Draft - Paused
date: 2026-06-18
owner: "@noelsaw1"
subject: Deep, clean-room study of the Eve framework (Apache-2.0)
goal: Extract durable, high-level patterns we can apply to xyz-3-agents-swarm — without copying any Eve code.
related:
  - decisions/2026-06-14-graduate-relay-automation-phase-2.md
---

# EVE-STUDY — Deep clean-room review of the Eve framework

## 0. One-paragraph charter

Eve (Apache-2.0, local clone at `$EVE_REPO`, indexed by Ask Self code RAG) is the
closest mainstream framework to this repo's *aesthetic*: filesystem-first, durable,
hook/skill/schedule-shaped agent substrate. This study mines Eve for **durable, high-level
patterns** — ideas and designs, not code — and lands them as reusable learning artifacts we
can apply to `tick` and `relay-automation`. **We copy zero code.** Ideas and architecture
are not copyrightable; only their *expression* is. So the entire study is conducted clean-room:
we read Eve, describe what we learn in our own words, and re-derive any implementation
independently for our own context.

Output home: **`PROJECT/2-WORKING/EVE-STUDY/`**.
Artifact format: **living pattern catalog (`LESSONS.md`) + a decision record per pattern we commit to adopt.**
Priority themes: **durability & resumability · subagent orchestration · sandbox & isolation · filesystem-first design.**

---

## 1. The clean-room rule (load-bearing — read before every phase)

This is the constraint the whole plan exists to honor. Treat it as a hard gate, not a guideline.

**Allowed**
- Read Eve source via Ask Self RAG and direct file reads.
- Describe mechanisms, data flows, and design choices **in our own words**.
- Record **pointers** to Eve concepts (e.g. "Eve's session-resume lives around its Workflow SDK adapter")
  as provenance — a reference is not a copy.
- Re-implement any idea from scratch, idiomatically for *our* stack, after the study, in a separate work stream.

**Forbidden**
- Pasting Eve source — even a few lines — into our repo, the artifacts, decision records, commits, or chat.
- Transliterating a file (renaming symbols / reformatting the same code) — that is a copy, not a pattern.
- Lifting distinctive names, file layouts, or comments verbatim. Capture the *shape of the idea*, not the artifact.
- Mirroring an algorithm's control-flow / logic skeleton step-for-step — structural copying is still copying expression.
  For any non-trivial algorithm, capture its *outcome + constraints*, then re-derive the logic independently with the source closed.

**Why this is clean (and why we still bother):** Apache-2.0 *permits* reuse with attribution + NOTICE
propagation. We avoid that obligation entirely by never copying expression — and because patterns/ideas
aren't copyrightable, paraphrased lessons carry no license encumbrance. We keep a provenance log anyway
so the lineage is transparent and defensible if ever questioned.

**Per-phase gate:** every phase exits with a one-line attestation — *"No Eve source text — and no
step-for-step logic skeleton — entered any artifact in this phase."* If you can't attest it, the phase isn't done.

---

## 2. Folder skeleton (created in Phase 0)

```
PROJECT/2-WORKING/EVE-STUDY/
  PLAN.md                  <- this file
  00-PROVENANCE.md         <- append-only: which Eve concept inspired which lesson (pointers only)
  10-ARCHITECTURE-MAP.md   <- Eve's structure in our words (Phase 1)
  20-patterns/             <- one deep-dive per priority theme (Phase 2)
     durability.md
     subagent-orchestration.md
     sandbox-isolation.md
     filesystem-first.md
  30-APPLICABILITY.md      <- pattern -> where it helps us, adopt/adapt/reject (Phase 3)
  LESSONS.md               <- living catalog: the durable patterns, distilled (Phase 4)
  ../../../decisions/NNNN-adopt-<pattern>.md   <- one per pattern we commit to (Phase 4)
```

---

## 3. Phases

Each phase lists: **objective · inputs · steps · output · exit gate (incl. clean-room attestation).**
This repo's `phase-qa` discipline applies — the QA checklist under each phase is the exit gate.

### Phase 0 — Setup, guardrails, provenance scaffold
- **Objective:** make the study safe and repeatable before any reading starts.
- **Inputs:** `$EVE_REPO` path; confirmation that the Ask Self index for Eve is built.
- **Steps:**
  1. Confirm `$EVE_REPO` resolves and is the Apache-2.0 Eve repo (check `LICENSE`/`NOTICE`).
  2. Confirm Ask Self has finished ingesting Eve (`reingest` if stale); run one smoke query.
  3. Create the folder skeleton from §2; seed `00-PROVENANCE.md` with the clean-room rule header.
  4. Record Eve's commit SHA + license terms at top of `00-PROVENANCE.md` (so the study is pinned to a snapshot).
- **Output:** populated skeleton + pinned provenance header.
- **Exit gate / QA:**
  - [ ] `$EVE_REPO` confirmed Apache-2.0; commit SHA recorded.
  - [ ] Ask Self smoke query returns relevant Eve chunks.
  - [ ] Skeleton exists; provenance file carries the clean-room rule + license pin.
  - [ ] **Attestation:** no Eve source text copied this phase.

### Phase 1 — Territory map (breadth-first, RAG-driven)
- **Objective:** a faithful map of Eve's architecture, in our words — no deep dives yet.
- **Inputs:** Ask Self; Eve's top-level layout and entry points.
- **Steps:**
  1. RAG-survey: directory layout, the primitive set (instructions / agent.ts / tools / skills / channels /
     connections / subagents / sandbox / hooks / schedules), and how they're discovered/wired.
  2. Identify the *seams*: where durability, delegation, isolation, and filesystem-convention each live.
  3. Write `10-ARCHITECTURE-MAP.md` as prose + our own diagrams. Pointers to Eve files allowed; content not.
- **Output:** `10-ARCHITECTURE-MAP.md`.
- **Exit gate / QA:**
  - [ ] Every Eve primitive named and explained in one paragraph each, in our words.
  - [ ] The four priority seams located and cross-linked to their Phase-2 deep-dive files.
  - [ ] DRY check: map doesn't restate Eve's docs; it interprets them for *our* lens.
  - [ ] **Attestation:** no Eve source text copied this phase.

### Phase 2 — Deep dives (one file per priority theme)
- **Objective:** for each priority theme, extract the durable pattern and its rationale.
- **Inputs:** `10-ARCHITECTURE-MAP.md`; targeted Ask Self queries per theme.
- **Steps (repeat per theme — durability, subagent-orchestration, sandbox-isolation, filesystem-first):**
  1. **What it does** — the mechanism, paraphrased.
  2. **Why it's durable** — what makes the choice survive scale / crashes / change; the underlying principle.
  3. **Failure modes** — how Eve behaves under partial state corruption, crash mid-write, and filesystem races.
     Most relevant to our `O_EXCL` claim model — note anything that stress-tests our assumptions.
  4. **The pattern, abstracted** — name it in *our* vocabulary, decoupled from Eve's implementation.
  5. **Anti-pattern check** — where Eve got this *wrong*, or over-engineered it for needs we don't have. Capture it
     so we don't import their tech debt. (Adopt-bias is the failure mode of this whole study — fight it here.)
  6. **Dependency reality check** — does the pattern only work because of an Eve dependency we don't use? If so,
     flag it a possible *false win* before it reaches the applicability table.
  7. **Mechanical contrast (anti-drift gate)** — the *specific* delta between Eve's implementation and our current
     `tick` / `relay-automation` code. If you can't state the concrete change, the pattern isn't distilled enough —
     keep going. A vague "it uses files for state" does **not** pass this gate.
  8. **Provenance line** — append the Eve concept pointer to `00-PROVENANCE.md`.
- **Output:** `20-patterns/{durability,subagent-orchestration,sandbox-isolation,filesystem-first}.md`.
- **Per-theme anchor questions:**
  - *Durability:* what is the minimal unit of replayable state? How is resume distinguished from restart?
    (vs. our append-only `.tick/events/` + `STATE.md` projection.)
  - *Subagent orchestration:* how is delegation scoped, supervised, and rejoined?
    (vs. orchestrator + Codex/Gemini peers + relay/marathon.)
  - *Sandbox & isolation:* what's the unit of isolation and how are collisions prevented vs. detected?
    (vs. `tick claim` + `O_EXCL` lock + drift/collision analysis.)
  - *Filesystem-first:* what conventions remove configuration, and where does convention-over-config break down?
    (vs. `.tick/`, `relay-system/<date>/<slug>.md`, `skill/`.)
- **Exit gate / QA (per file):**
  - [ ] All eight steps present; pattern named in our vocabulary.
  - [ ] Failure modes documented; anti-pattern check done (or an explicit "none found — here's why").
  - [ ] Mechanical-contrast gate passed — a concrete Eve-vs-us delta is stated, not a vague abstraction.
  - [ ] Dependency reality check done; any false win flagged.
  - [ ] Provenance line appended.
  - [ ] **Attestation:** no Eve source text — and no step-for-step logic skeleton — copied this phase.

### Phase 3 — Applicability mapping (adopt / adapt / reject)
- **Objective:** convert patterns into decisions about *our* codebase.
- **Inputs:** the four deep-dive files.
- **Steps:**
  1. For each durable pattern, map to concrete surfaces: `tick` kernel, `relay-automation` loop, `marathon`,
     skills, decision-record flow.
  2. Classify each: **Adopt** (clear win, low risk) / **Adapt** (good idea, needs reshaping for us) /
     **Reject** (doesn't fit — record *why*, so we don't relitigate).
  3. For Adopt/Adapt, sketch the *independent* re-derivation at a high level (no Eve code referenced in the sketch).
  4. Flag blast-radius for anything touching the `tick` kernel or the event-log format (those are load-bearing).
- **Output:** `30-APPLICABILITY.md` — a ranked table: pattern · surface · adopt/adapt/reject · rationale · blast radius.
- **Exit gate / QA:**
  - [ ] Every Phase-2 pattern classified with a one-line rationale.
  - [ ] Rejects carry an explicit reason (anti-relitigation).
  - [ ] Kernel/event-log-touching items flagged with blast radius.
  - [ ] **Attestation:** no Eve source text copied this phase.

### Phase 4 — Housing the artifacts (catalog + decision records)
- **Objective:** land the durable output so it outlives this session and drives real work.
- **Inputs:** `30-APPLICABILITY.md`.
- **Steps:**
  1. Distill `LESSONS.md` — the living catalog: every durable pattern, in our words, with its
     applicability verdict and a one-line "so what for us." This is the canonical takeaway doc.
  2. Write a decision record in `decisions/` **only for high-impact adoptions** — anything that touches the
     `tick` kernel, the event-log format, or the `relay-automation` contract. Lower-impact Adopt/Adapt items
     live in `LESSONS.md` only (no ADR overhead). Use this repo's record format (status / date / reversibility /
     revisit / the bet / rejected / expected signal). One file per high-impact pattern.
  3. Cross-link: `LESSONS.md` → decision records; decision records → `20-patterns/*` provenance.
  4. Convert any "later" items into `BACKLOG.md` entries so nothing dangles.
  5. Update repo memory (a `project` memory: "Eve study lives in PROJECT/2-WORKING/EVE-STUDY; lessons in LESSONS.md").
- **Output:** `LESSONS.md` + `decisions/NNNN-adopt-*.md` + backlog entries.
- **Exit gate / QA:**
  - [ ] `LESSONS.md` is self-contained — a reader who never saw Eve understands each pattern and why it matters to us.
  - [ ] Every **high-impact** Adopt has a decision record; lower-impact Adopts live in `LESSONS.md`; every Reject is captured.
  - [ ] Loose-ends sweep: no orphaned "TODO/later" without a backlog home.
  - [ ] **Attestation:** `LESSONS.md` and all decision records contain zero Eve source text.

### Phase 5 — (optional) Follow-through
- **Objective:** turn the highest-value Adopt into a real change, on its own branch, as a separate work stream.
- **Note:** this is *implementation*, gated by its own clean-room check — re-derive from `LESSONS.md`, never
  from Eve open in a second window. Out of scope for the study itself; listed so the handoff is explicit.

---

## 4. Method notes

- **RAG-first, read-second.** Drive breadth with Ask Self queries; only open specific Eve files when the RAG
  answer needs grounding. This keeps raw source out of context (and out of temptation to copy).
- **Paraphrase-on-ingest.** Never park a raw snippet "to summarize later." Summarize at read time, in our words.
  Nothing verbatim is allowed to land even transiently in an artifact.
- **Provenance is pointers, not payload — kept light.** `00-PROVENANCE.md` says *where* an idea came from, never
  *what* the code was. A per-theme "files reviewed" list plus the inspiring concept is enough — don't let it become
  a line-by-line ledger.
- **One snapshot.** Pin Eve's commit SHA in Phase 0; if Eve changes upstream mid-study, finish against the pin.

## 5. Definition of done

- `LESSONS.md` exists, is self-contained, and reads as *our* knowledge — no Eve expression anywhere.
- Each adopted pattern has a decision record in `decisions/`.
- Provenance log is complete (every lesson traces to an Eve pointer).
- A blast-radius flag exists on anything that would touch the `tick` kernel or event-log format.
- Final attestation in `00-PROVENANCE.md`: *the entire study copied zero Eve code and mirrored no logic skeletons.*

## 6. Open inputs (fill at kickoff)

- `$EVE_REPO` = `________` (local path to the Eve clone)
- Eve commit SHA pinned for this study = `________`
- Ask Self index status for Eve = `________`
````
- Definition of Done: The EVE-STUDY plan is sound, structured, and compliant with PDDA requirements (YAML keys, status table, Table of Contents, triage ratings, and clean-room rules) and AGENTS.md (explicit assumptions, tradeoffs, and reversibility scale).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy · 2026-07-02
**Verdict:** Changes requested

**Findings & proposals:**
- **[Blocker] Missing PDDA Required Frontmatter Keys:** The YAML frontmatter in the draft plan ([EVE-REVIEW.md](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/PROJECT/1-INBOX/EVE-STUDY/EVE-REVIEW.md#L1-L9)) is missing the required keys `title`, `created`, and `updated`. PDDA requires these keys for all active working documents.
  - *Fix:* Replace the existing frontmatter with:
    ```yaml
    ---
    title: "EVE-STUDY Plan — Deep clean-room review of the Eve framework"
    status: Draft - Paused
    created: 2026-06-18
    updated: 2026-07-02
    owner: "@noelsaw1"
    subject: Deep, clean-room study of the Eve framework (Apache-2.0)
    goal: Extract durable, high-level patterns we can apply to xyz-3-agents-swarm — without copying any Eve code.
    related:
      - decisions/2026-06-14-graduate-relay-automation-phase-2.md
    ---
    ```
- **[Blocker] Missing ## Status Table:** There is no `## Status` table in the plan. PDDA requires active docs to carry a status table with the exact columns `What was just completed | What's next`.
  - *Fix:* Insert the following status table directly below the H1 title in the plan:
    ```md
    ## Status

    | What was just completed | What's next |
    |---|---|
    | Plan drafted by Producer | Plan review by Reviewer (`agy`) |
    ```
- **[Blocker] Missing Triage Ratings:** The plan does not carry the four triage fields (`effort`, `complexity`, `risk`, `phases`) in its frontmatter. PDDA requires these fields for all medium-large work.
  - *Fix:* Add the following fields to the YAML frontmatter:
    ```yaml
    effort: 3
    complexity: 3
    risk: 2
    phases: 5
    ```
- **[Should] Missing Table of Contents:** The plan spans 5 phases but does not include a `## Table of contents` section listing the phases. PDDA requires a Table of Contents for multi-phase plans.
  - *Fix:* Add a `## Table of contents` section that lists each phase.
- **[Should] Make Assumptions, Tradeoffs, and Reversibility Scale Explicit:** The plan does not explicitly declare its overall assumptions, tradeoffs, and a reversibility read as required by `AGENTS.md` (Principles #2 and #3).
  - *Fix:* Add a short section (e.g., `## 0.1. Playbook Read`) detailing:
    - *Assumptions:* Ask Self index of Eve is accurate/complete; clean-room boundaries can be maintained without developer cross-contamination.
    - *Tradeoffs:* Heavy clean-room scaffolding and provenance tracking vs. velocity.
    - *Reversibility:* Easy (design-only; we can abort or change paths without legacy code impact).
- **[Nit] Open Inputs Ready to Populate:** Section 6 contains blank placeholders for `$EVE_REPO`, commit SHA, and Ask Self status. The Reviewer has confirmed that a local Eve clone exists at `/Users/noelsaw/Documents/GH Repos/eve` with HEAD SHA `7ddc64edb33f56d1dbc704e1c09c0b78f0ac405a`.
  - *Fix:* Populate these inputs at kickoff.

**Commit:** none — review only

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

