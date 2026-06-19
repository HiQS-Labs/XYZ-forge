Reading additional input from stdin...
OpenAI Codex v0.140.0
--------
workdir: /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019edc60-a042-7ff1-9100-de85a94d0840
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review the document at PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md (a clean-room study *plan* for studying the Apache-2.0 "Eve" framework to extract high-level patterns for this repo WITHOUT copying code). Also skim PROJECT/2-WORKING/EVE-STUDY/INITIAL-COMPARISON.md for context.

Evaluate on exactly two axes and be concrete (cite section numbers / line content):

1. ACCURACY — Are the factual and legal/IP claims correct and defensible?
   - The idea/expression dichotomy claims ("ideas and architecture are not copyrightable; only expression is"; "mirroring an algorithm's control-flow / logic skeleton step-for-step is still copying expression").
   - The Apache-2.0 reasoning (§1 "Why this is clean"): that paraphrased patterns carry "no license encumbrance" and avoid attribution/NOTICE obligations entirely.
   - Any overstatement, missing nuance, or claim a lawyer would push back on. Note where it is RIGHT too, not only wrong.
   - Internal/doc accuracy: e.g. §2 skeleton calls this file PLAN.md but it is named EVE-REVIEW.md; any other self-inconsistencies.

2. CLEAN-ROOM ADHERENCE — Does the plan's *own method* actually keep the study clean-room, or are there leak paths?
   - The classic clean-room standard is TWO separated teams (one reads source + writes a spec, a different team implements from the spec only). This plan is one person reading source AND deriving lessons AND later re-implementing. Is that still meaningfully "clean-room"? Does the doc acknowledge this gap?
   - Leak paths: RAG ("Ask Self") pulling raw Eve source into context; paraphrase-on-ingest discipline; provenance-as-pointers; the per-phase attestation gate. Are these sufficient, and are there holes?
   - Is anything mislabeled as safe that isn't (e.g. "pointers are not copies", "structural/control-flow capture")?

Give: the single most important correction on each axis, then a short prioritized list of the rest. Be a skeptical reviewer — surface what is wrong or risky, not reassurance. If something is actually fine, say so briefly.
codex
I’m reviewing the two study docs directly and checking the specific legal/IP and method claims against the text itself before making any call.
exec
/bin/zsh -lc 'nl -ba PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551
exec
/bin/zsh -lc 'nl -ba PROJECT/2-WORKING/EVE-STUDY/INITIAL-COMPARISON.md' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551
 succeeded in 0ms:
     1	Yes — there's real shared DNA, but they're solving adjacent problems from opposite ends. Here's the honest comparison.
     2	
     3	Where they overlap
     4	Concept	Eve	This repo (tick / relay-automation)
     5	Filesystem-as-interface	"A file's location says what it does; its path gives it a name." No registry.	.tick/events/ + STATE.md projection; relay threads in dated folders; skills-as-files. State is the filesystem.
     6	Durable / resumable sessions	Workflow SDK makes sessions crash-safe & resumable.	Append-only event log → replayable projection; watchdogs + poll-driven turn-takers survive restarts.
     7	Skills	"Longer procedures loaded contextually."	Literal skill/ surface + Claude Code skills loaded on trigger.
     8	Hooks / lifecycle	Hooks for event reactivity.	Watchdogs, poll loops, + Claude Code hooks (you can see them firing in this session).
     9	Schedules	Recurring work automation.	loop / schedule / cron + Marathon phase chaining.
    10	Sandbox	Controlled workspace for file/command ops.	Command sandbox + path-scoped claims (lanes).
    11	Connections	External MCP server tools.	MCP servers (context-mode, connectors).
    12	So if you squint, both are filesystem-first, durable, skill/hook/schedule-shaped agent substrates. That convergence is striking and worth noting — it's the same design vocabulary.
    13	
    14	Where they fundamentally diverge
    15	The two "multi-agent" stories are not the same thing:
    16	
    17	Eve = a framework/SDK to build one durable agent product, where a root agent delegates to its own subagents and talks to Slack/Discord/HTTP channels. The agents are cooperative and framework-coordinated. Hosted, vendor stack.
    18	This repo = a coordination spike to make separately-owned, heterogeneous vendor CLIs (Claude Code, Codex, Gemini) work concurrently on one shared git repo without colliding. Local-transport only, no accounts, no remote dependency.
    19	The load-bearing piece of this project — tick claim with O_EXCL locks, drift detection, file-collision analysis, the honest-concurrency metric — has no analog in Eve, because Eve never has two independently-owned agents racing for the same file. Its subagents are conducted; yours are negotiated.
    20	
    21	Bottom line
    22	They share a design philosophy (filesystem-first, durable, hook/skill/schedule primitives) but live at different layers: Eve is "how to build a durable agent"; this repo is "how to keep N agents you didn't build from stepping on each other." Eve is the closest mainstream framework to your aesthetic — but it assumes away the exact problem (tick's collision-free claims across heterogeneous agents) that this spike exists to solve.
    23	
    24	Want me to pull the actual Eve subagent/sandbox API pages and do a deeper primitive-by-primitive map (e.g. could tick sit under an Eve-style framework, or is it a competitor)?
 succeeded in 0ms:
     1	---
     2	status: Draft - Paused
     3	date: 2026-06-18
     4	owner: "@noelsaw1"
     5	subject: Deep, clean-room study of the Eve framework (Apache-2.0)
     6	goal: Extract durable, high-level patterns we can apply to xyz-3-agents-swarm — without copying any Eve code.
     7	related:
     8	  - decisions/2026-06-14-graduate-relay-automation-phase-2.md
     9	---
    10	
    11	# EVE-STUDY — Deep clean-room review of the Eve framework
    12	
    13	## 0. One-paragraph charter
    14	
    15	Eve (Apache-2.0, local clone at `$EVE_REPO`, indexed by Ask Self code RAG) is the
    16	closest mainstream framework to this repo's *aesthetic*: filesystem-first, durable,
    17	hook/skill/schedule-shaped agent substrate. This study mines Eve for **durable, high-level
    18	patterns** — ideas and designs, not code — and lands them as reusable learning artifacts we
    19	can apply to `tick` and `relay-automation`. **We copy zero code.** Ideas and architecture
    20	are not copyrightable; only their *expression* is. So the entire study is conducted clean-room:
    21	we read Eve, describe what we learn in our own words, and re-derive any implementation
    22	independently for our own context.
    23	
    24	Output home: **`PROJECT/2-WORKING/EVE-STUDY/`**.
    25	Artifact format: **living pattern catalog (`LESSONS.md`) + a decision record per pattern we commit to adopt.**
    26	Priority themes: **durability & resumability · subagent orchestration · sandbox & isolation · filesystem-first design.**
    27	
    28	---
    29	
    30	## 1. The clean-room rule (load-bearing — read before every phase)
    31	
    32	This is the constraint the whole plan exists to honor. Treat it as a hard gate, not a guideline.
    33	
    34	**Allowed**
    35	- Read Eve source via Ask Self RAG and direct file reads.
    36	- Describe mechanisms, data flows, and design choices **in our own words**.
    37	- Record **pointers** to Eve concepts (e.g. "Eve's session-resume lives around its Workflow SDK adapter")
    38	  as provenance — a reference is not a copy.
    39	- Re-implement any idea from scratch, idiomatically for *our* stack, after the study, in a separate work stream.
    40	
    41	**Forbidden**
    42	- Pasting Eve source — even a few lines — into our repo, the artifacts, decision records, commits, or chat.
    43	- Transliterating a file (renaming symbols / reformatting the same code) — that is a copy, not a pattern.
    44	- Lifting distinctive names, file layouts, or comments verbatim. Capture the *shape of the idea*, not the artifact.
    45	- Mirroring an algorithm's control-flow / logic skeleton step-for-step — structural copying is still copying expression.
    46	  For any non-trivial algorithm, capture its *outcome + constraints*, then re-derive the logic independently with the source closed.
    47	
    48	**Why this is clean (and why we still bother):** Apache-2.0 *permits* reuse with attribution + NOTICE
    49	propagation. We avoid that obligation entirely by never copying expression — and because patterns/ideas
    50	aren't copyrightable, paraphrased lessons carry no license encumbrance. We keep a provenance log anyway
    51	so the lineage is transparent and defensible if ever questioned.
    52	
    53	**Per-phase gate:** every phase exits with a one-line attestation — *"No Eve source text — and no
    54	step-for-step logic skeleton — entered any artifact in this phase."* If you can't attest it, the phase isn't done.
    55	
    56	---
    57	
    58	## 2. Folder skeleton (created in Phase 0)
    59	
    60	```
    61	PROJECT/2-WORKING/EVE-STUDY/
    62	  PLAN.md                  <- this file
    63	  00-PROVENANCE.md         <- append-only: which Eve concept inspired which lesson (pointers only)
    64	  10-ARCHITECTURE-MAP.md   <- Eve's structure in our words (Phase 1)
    65	  20-patterns/             <- one deep-dive per priority theme (Phase 2)
    66	     durability.md
    67	     subagent-orchestration.md
    68	     sandbox-isolation.md
    69	     filesystem-first.md
    70	  30-APPLICABILITY.md      <- pattern -> where it helps us, adopt/adapt/reject (Phase 3)
    71	  LESSONS.md               <- living catalog: the durable patterns, distilled (Phase 4)
    72	  ../../../decisions/NNNN-adopt-<pattern>.md   <- one per pattern we commit to (Phase 4)
    73	```
    74	
    75	---
    76	
    77	## 3. Phases
    78	
    79	Each phase lists: **objective · inputs · steps · output · exit gate (incl. clean-room attestation).**
    80	This repo's `phase-qa` discipline applies — the QA checklist under each phase is the exit gate.
    81	
    82	### Phase 0 — Setup, guardrails, provenance scaffold
    83	- **Objective:** make the study safe and repeatable before any reading starts.
    84	- **Inputs:** `$EVE_REPO` path; confirmation that the Ask Self index for Eve is built.
    85	- **Steps:**
    86	  1. Confirm `$EVE_REPO` resolves and is the Apache-2.0 Eve repo (check `LICENSE`/`NOTICE`).
    87	  2. Confirm Ask Self has finished ingesting Eve (`reingest` if stale); run one smoke query.
    88	  3. Create the folder skeleton from §2; seed `00-PROVENANCE.md` with the clean-room rule header.
    89	  4. Record Eve's commit SHA + license terms at top of `00-PROVENANCE.md` (so the study is pinned to a snapshot).
    90	- **Output:** populated skeleton + pinned provenance header.
    91	- **Exit gate / QA:**
    92	  - [ ] `$EVE_REPO` confirmed Apache-2.0; commit SHA recorded.
    93	  - [ ] Ask Self smoke query returns relevant Eve chunks.
    94	  - [ ] Skeleton exists; provenance file carries the clean-room rule + license pin.
    95	  - [ ] **Attestation:** no Eve source text copied this phase.
    96	
    97	### Phase 1 — Territory map (breadth-first, RAG-driven)
    98	- **Objective:** a faithful map of Eve's architecture, in our words — no deep dives yet.
    99	- **Inputs:** Ask Self; Eve's top-level layout and entry points.
   100	- **Steps:**
   101	  1. RAG-survey: directory layout, the primitive set (instructions / agent.ts / tools / skills / channels /
   102	     connections / subagents / sandbox / hooks / schedules), and how they're discovered/wired.
   103	  2. Identify the *seams*: where durability, delegation, isolation, and filesystem-convention each live.
   104	  3. Write `10-ARCHITECTURE-MAP.md` as prose + our own diagrams. Pointers to Eve files allowed; content not.
   105	- **Output:** `10-ARCHITECTURE-MAP.md`.
   106	- **Exit gate / QA:**
   107	  - [ ] Every Eve primitive named and explained in one paragraph each, in our words.
   108	  - [ ] The four priority seams located and cross-linked to their Phase-2 deep-dive files.
   109	  - [ ] DRY check: map doesn't restate Eve's docs; it interprets them for *our* lens.
   110	  - [ ] **Attestation:** no Eve source text copied this phase.
   111	
   112	### Phase 2 — Deep dives (one file per priority theme)
   113	- **Objective:** for each priority theme, extract the durable pattern and its rationale.
   114	- **Inputs:** `10-ARCHITECTURE-MAP.md`; targeted Ask Self queries per theme.
   115	- **Steps (repeat per theme — durability, subagent-orchestration, sandbox-isolation, filesystem-first):**
   116	  1. **What it does** — the mechanism, paraphrased.
   117	  2. **Why it's durable** — what makes the choice survive scale / crashes / change; the underlying principle.
   118	  3. **Failure modes** — how Eve behaves under partial state corruption, crash mid-write, and filesystem races.
   119	     Most relevant to our `O_EXCL` claim model — note anything that stress-tests our assumptions.
   120	  4. **The pattern, abstracted** — name it in *our* vocabulary, decoupled from Eve's implementation.
   121	  5. **Anti-pattern check** — where Eve got this *wrong*, or over-engineered it for needs we don't have. Capture it
   122	     so we don't import their tech debt. (Adopt-bias is the failure mode of this whole study — fight it here.)
   123	  6. **Dependency reality check** — does the pattern only work because of an Eve dependency we don't use? If so,
   124	     flag it a possible *false win* before it reaches the applicability table.
   125	  7. **Mechanical contrast (anti-drift gate)** — the *specific* delta between Eve's implementation and our current
   126	     `tick` / `relay-automation` code. If you can't state the concrete change, the pattern isn't distilled enough —
   127	     keep going. A vague "it uses files for state" does **not** pass this gate.
   128	  8. **Provenance line** — append the Eve concept pointer to `00-PROVENANCE.md`.
   129	- **Output:** `20-patterns/{durability,subagent-orchestration,sandbox-isolation,filesystem-first}.md`.
   130	- **Per-theme anchor questions:**
   131	  - *Durability:* what is the minimal unit of replayable state? How is resume distinguished from restart?
   132	    (vs. our append-only `.tick/events/` + `STATE.md` projection.)
   133	  - *Subagent orchestration:* how is delegation scoped, supervised, and rejoined?
   134	    (vs. orchestrator + Codex/Gemini peers + relay/marathon.)
   135	  - *Sandbox & isolation:* what's the unit of isolation and how are collisions prevented vs. detected?
   136	    (vs. `tick claim` + `O_EXCL` lock + drift/collision analysis.)
   137	  - *Filesystem-first:* what conventions remove configuration, and where does convention-over-config break down?
   138	    (vs. `.tick/`, `relay-system/<date>/<slug>.md`, `skill/`.)
   139	- **Exit gate / QA (per file):**
   140	  - [ ] All eight steps present; pattern named in our vocabulary.
   141	  - [ ] Failure modes documented; anti-pattern check done (or an explicit "none found — here's why").
   142	  - [ ] Mechanical-contrast gate passed — a concrete Eve-vs-us delta is stated, not a vague abstraction.
   143	  - [ ] Dependency reality check done; any false win flagged.
   144	  - [ ] Provenance line appended.
   145	  - [ ] **Attestation:** no Eve source text — and no step-for-step logic skeleton — copied this phase.
   146	
   147	### Phase 3 — Applicability mapping (adopt / adapt / reject)
   148	- **Objective:** convert patterns into decisions about *our* codebase.
   149	- **Inputs:** the four deep-dive files.
   150	- **Steps:**
   151	  1. For each durable pattern, map to concrete surfaces: `tick` kernel, `relay-automation` loop, `marathon`,
   152	     skills, decision-record flow.
   153	  2. Classify each: **Adopt** (clear win, low risk) / **Adapt** (good idea, needs reshaping for us) /
   154	     **Reject** (doesn't fit — record *why*, so we don't relitigate).
   155	  3. For Adopt/Adapt, sketch the *independent* re-derivation at a high level (no Eve code referenced in the sketch).
   156	  4. Flag blast-radius for anything touching the `tick` kernel or the event-log format (those are load-bearing).
   157	- **Output:** `30-APPLICABILITY.md` — a ranked table: pattern · surface · adopt/adapt/reject · rationale · blast radius.
   158	- **Exit gate / QA:**
   159	  - [ ] Every Phase-2 pattern classified with a one-line rationale.
   160	  - [ ] Rejects carry an explicit reason (anti-relitigation).
   161	  - [ ] Kernel/event-log-touching items flagged with blast radius.
   162	  - [ ] **Attestation:** no Eve source text copied this phase.
   163	
   164	### Phase 4 — Housing the artifacts (catalog + decision records)
   165	- **Objective:** land the durable output so it outlives this session and drives real work.
   166	- **Inputs:** `30-APPLICABILITY.md`.
   167	- **Steps:**
   168	  1. Distill `LESSONS.md` — the living catalog: every durable pattern, in our words, with its
   169	     applicability verdict and a one-line "so what for us." This is the canonical takeaway doc.
   170	  2. Write a decision record in `decisions/` **only for high-impact adoptions** — anything that touches the
   171	     `tick` kernel, the event-log format, or the `relay-automation` contract. Lower-impact Adopt/Adapt items
   172	     live in `LESSONS.md` only (no ADR overhead). Use this repo's record format (status / date / reversibility /
   173	     revisit / the bet / rejected / expected signal). One file per high-impact pattern.
   174	  3. Cross-link: `LESSONS.md` → decision records; decision records → `20-patterns/*` provenance.
   175	  4. Convert any "later" items into `BACKLOG.md` entries so nothing dangles.
   176	  5. Update repo memory (a `project` memory: "Eve study lives in PROJECT/2-WORKING/EVE-STUDY; lessons in LESSONS.md").
   177	- **Output:** `LESSONS.md` + `decisions/NNNN-adopt-*.md` + backlog entries.
   178	- **Exit gate / QA:**
   179	  - [ ] `LESSONS.md` is self-contained — a reader who never saw Eve understands each pattern and why it matters to us.
   180	  - [ ] Every **high-impact** Adopt has a decision record; lower-impact Adopts live in `LESSONS.md`; every Reject is captured.
   181	  - [ ] Loose-ends sweep: no orphaned "TODO/later" without a backlog home.
   182	  - [ ] **Attestation:** `LESSONS.md` and all decision records contain zero Eve source text.
   183	
   184	### Phase 5 — (optional) Follow-through
   185	- **Objective:** turn the highest-value Adopt into a real change, on its own branch, as a separate work stream.
   186	- **Note:** this is *implementation*, gated by its own clean-room check — re-derive from `LESSONS.md`, never
   187	  from Eve open in a second window. Out of scope for the study itself; listed so the handoff is explicit.
   188	
   189	---
   190	
   191	## 4. Method notes
   192	
   193	- **RAG-first, read-second.** Drive breadth with Ask Self queries; only open specific Eve files when the RAG
   194	  answer needs grounding. This keeps raw source out of context (and out of temptation to copy).
   195	- **Paraphrase-on-ingest.** Never park a raw snippet "to summarize later." Summarize at read time, in our words.
   196	  Nothing verbatim is allowed to land even transiently in an artifact.
   197	- **Provenance is pointers, not payload — kept light.** `00-PROVENANCE.md` says *where* an idea came from, never
   198	  *what* the code was. A per-theme "files reviewed" list plus the inspiring concept is enough — don't let it become
   199	  a line-by-line ledger.
   200	- **One snapshot.** Pin Eve's commit SHA in Phase 0; if Eve changes upstream mid-study, finish against the pin.
   201	
   202	## 5. Definition of done
   203	
   204	- `LESSONS.md` exists, is self-contained, and reads as *our* knowledge — no Eve expression anywhere.
   205	- Each adopted pattern has a decision record in `decisions/`.
   206	- Provenance log is complete (every lesson traces to an Eve pointer).
   207	- A blast-radius flag exists on anything that would touch the `tick` kernel or event-log format.
   208	- Final attestation in `00-PROVENANCE.md`: *the entire study copied zero Eve code and mirrored no logic skeletons.*
   209	
   210	## 6. Open inputs (fill at kickoff)
   211	
   212	- `$EVE_REPO` = `________` (local path to the Eve clone)
   213	- Eve commit SHA pinned for this study = `________`
   214	- Ask Self index status for Eve = `________`

exec
/bin/zsh -lc 'rg --files PROJECT/2-WORKING/EVE-STUDY' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551
 succeeded in 0ms:
PROJECT/2-WORKING/EVE-STUDY/INITIAL-COMPARISON.md
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md

codex
I have the core text; now I’m checking for internal contradictions and places where the method overclaims what its own safeguards actually achieve.
exec
/bin/zsh -lc "nl -ba PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md | sed -n '15,60p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551
exec
/bin/zsh -lc "nl -ba PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md | sed -n '164,210p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551
 succeeded in 0ms:
    15	Eve (Apache-2.0, local clone at `$EVE_REPO`, indexed by Ask Self code RAG) is the
    16	closest mainstream framework to this repo's *aesthetic*: filesystem-first, durable,
    17	hook/skill/schedule-shaped agent substrate. This study mines Eve for **durable, high-level
    18	patterns** — ideas and designs, not code — and lands them as reusable learning artifacts we
    19	can apply to `tick` and `relay-automation`. **We copy zero code.** Ideas and architecture
    20	are not copyrightable; only their *expression* is. So the entire study is conducted clean-room:
    21	we read Eve, describe what we learn in our own words, and re-derive any implementation
    22	independently for our own context.
    23	
    24	Output home: **`PROJECT/2-WORKING/EVE-STUDY/`**.
    25	Artifact format: **living pattern catalog (`LESSONS.md`) + a decision record per pattern we commit to adopt.**
    26	Priority themes: **durability & resumability · subagent orchestration · sandbox & isolation · filesystem-first design.**
    27	
    28	---
    29	
    30	## 1. The clean-room rule (load-bearing — read before every phase)
    31	
    32	This is the constraint the whole plan exists to honor. Treat it as a hard gate, not a guideline.
    33	
    34	**Allowed**
    35	- Read Eve source via Ask Self RAG and direct file reads.
    36	- Describe mechanisms, data flows, and design choices **in our own words**.
    37	- Record **pointers** to Eve concepts (e.g. "Eve's session-resume lives around its Workflow SDK adapter")
    38	  as provenance — a reference is not a copy.
    39	- Re-implement any idea from scratch, idiomatically for *our* stack, after the study, in a separate work stream.
    40	
    41	**Forbidden**
    42	- Pasting Eve source — even a few lines — into our repo, the artifacts, decision records, commits, or chat.
    43	- Transliterating a file (renaming symbols / reformatting the same code) — that is a copy, not a pattern.
    44	- Lifting distinctive names, file layouts, or comments verbatim. Capture the *shape of the idea*, not the artifact.
    45	- Mirroring an algorithm's control-flow / logic skeleton step-for-step — structural copying is still copying expression.
    46	  For any non-trivial algorithm, capture its *outcome + constraints*, then re-derive the logic independently with the source closed.
    47	
    48	**Why this is clean (and why we still bother):** Apache-2.0 *permits* reuse with attribution + NOTICE
    49	propagation. We avoid that obligation entirely by never copying expression — and because patterns/ideas
    50	aren't copyrightable, paraphrased lessons carry no license encumbrance. We keep a provenance log anyway
    51	so the lineage is transparent and defensible if ever questioned.
    52	
    53	**Per-phase gate:** every phase exits with a one-line attestation — *"No Eve source text — and no
    54	step-for-step logic skeleton — entered any artifact in this phase."* If you can't attest it, the phase isn't done.
    55	
    56	---
    57	
    58	## 2. Folder skeleton (created in Phase 0)
    59	
    60	```

 succeeded in 0ms:
   164	### Phase 4 — Housing the artifacts (catalog + decision records)
   165	- **Objective:** land the durable output so it outlives this session and drives real work.
   166	- **Inputs:** `30-APPLICABILITY.md`.
   167	- **Steps:**
   168	  1. Distill `LESSONS.md` — the living catalog: every durable pattern, in our words, with its
   169	     applicability verdict and a one-line "so what for us." This is the canonical takeaway doc.
   170	  2. Write a decision record in `decisions/` **only for high-impact adoptions** — anything that touches the
   171	     `tick` kernel, the event-log format, or the `relay-automation` contract. Lower-impact Adopt/Adapt items
   172	     live in `LESSONS.md` only (no ADR overhead). Use this repo's record format (status / date / reversibility /
   173	     revisit / the bet / rejected / expected signal). One file per high-impact pattern.
   174	  3. Cross-link: `LESSONS.md` → decision records; decision records → `20-patterns/*` provenance.
   175	  4. Convert any "later" items into `BACKLOG.md` entries so nothing dangles.
   176	  5. Update repo memory (a `project` memory: "Eve study lives in PROJECT/2-WORKING/EVE-STUDY; lessons in LESSONS.md").
   177	- **Output:** `LESSONS.md` + `decisions/NNNN-adopt-*.md` + backlog entries.
   178	- **Exit gate / QA:**
   179	  - [ ] `LESSONS.md` is self-contained — a reader who never saw Eve understands each pattern and why it matters to us.
   180	  - [ ] Every **high-impact** Adopt has a decision record; lower-impact Adopts live in `LESSONS.md`; every Reject is captured.
   181	  - [ ] Loose-ends sweep: no orphaned "TODO/later" without a backlog home.
   182	  - [ ] **Attestation:** `LESSONS.md` and all decision records contain zero Eve source text.
   183	
   184	### Phase 5 — (optional) Follow-through
   185	- **Objective:** turn the highest-value Adopt into a real change, on its own branch, as a separate work stream.
   186	- **Note:** this is *implementation*, gated by its own clean-room check — re-derive from `LESSONS.md`, never
   187	  from Eve open in a second window. Out of scope for the study itself; listed so the handoff is explicit.
   188	
   189	---
   190	
   191	## 4. Method notes
   192	
   193	- **RAG-first, read-second.** Drive breadth with Ask Self queries; only open specific Eve files when the RAG
   194	  answer needs grounding. This keeps raw source out of context (and out of temptation to copy).
   195	- **Paraphrase-on-ingest.** Never park a raw snippet "to summarize later." Summarize at read time, in our words.
   196	  Nothing verbatim is allowed to land even transiently in an artifact.
   197	- **Provenance is pointers, not payload — kept light.** `00-PROVENANCE.md` says *where* an idea came from, never
   198	  *what* the code was. A per-theme "files reviewed" list plus the inspiring concept is enough — don't let it become
   199	  a line-by-line ledger.
   200	- **One snapshot.** Pin Eve's commit SHA in Phase 0; if Eve changes upstream mid-study, finish against the pin.
   201	
   202	## 5. Definition of done
   203	
   204	- `LESSONS.md` exists, is self-contained, and reads as *our* knowledge — no Eve expression anywhere.
   205	- Each adopted pattern has a decision record in `decisions/`.
   206	- Provenance log is complete (every lesson traces to an Eve pointer).
   207	- A blast-radius flag exists on anything that would touch the `tick` kernel or event-log format.
   208	- Final attestation in `00-PROVENANCE.md`: *the entire study copied zero Eve code and mirrored no logic skeletons.*
   209	
   210	## 6. Open inputs (fill at kickoff)

exec
/bin/zsh -lc 'rg -n "PLAN.md|decision record|clean-room|Apache-2.0|NOTICE|provenance|Attestation|RAG-first|Paraphrase-on-ingest|project memory|pointers|control-flow|logic skeleton|Each adopted pattern|high-impact|closest mainstream" PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md PROJECT/2-WORKING/EVE-STUDY/INITIAL-COMPARISON.md' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551
 succeeded in 0ms:
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:5:subject: Deep, clean-room study of the Eve framework (Apache-2.0)
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:11:# EVE-STUDY — Deep clean-room review of the Eve framework
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:15:Eve (Apache-2.0, local clone at `$EVE_REPO`, indexed by Ask Self code RAG) is the
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:16:closest mainstream framework to this repo's *aesthetic*: filesystem-first, durable,
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:20:are not copyrightable; only their *expression* is. So the entire study is conducted clean-room:
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:25:Artifact format: **living pattern catalog (`LESSONS.md`) + a decision record per pattern we commit to adopt.**
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:30:## 1. The clean-room rule (load-bearing — read before every phase)
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:37:- Record **pointers** to Eve concepts (e.g. "Eve's session-resume lives around its Workflow SDK adapter")
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:38:  as provenance — a reference is not a copy.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:42:- Pasting Eve source — even a few lines — into our repo, the artifacts, decision records, commits, or chat.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:45:- Mirroring an algorithm's control-flow / logic skeleton step-for-step — structural copying is still copying expression.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:48:**Why this is clean (and why we still bother):** Apache-2.0 *permits* reuse with attribution + NOTICE
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:50:aren't copyrightable, paraphrased lessons carry no license encumbrance. We keep a provenance log anyway
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:54:step-for-step logic skeleton — entered any artifact in this phase."* If you can't attest it, the phase isn't done.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:62:  PLAN.md                  <- this file
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:63:  00-PROVENANCE.md         <- append-only: which Eve concept inspired which lesson (pointers only)
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:79:Each phase lists: **objective · inputs · steps · output · exit gate (incl. clean-room attestation).**
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:82:### Phase 0 — Setup, guardrails, provenance scaffold
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:86:  1. Confirm `$EVE_REPO` resolves and is the Apache-2.0 Eve repo (check `LICENSE`/`NOTICE`).
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:88:  3. Create the folder skeleton from §2; seed `00-PROVENANCE.md` with the clean-room rule header.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:90:- **Output:** populated skeleton + pinned provenance header.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:92:  - [ ] `$EVE_REPO` confirmed Apache-2.0; commit SHA recorded.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:94:  - [ ] Skeleton exists; provenance file carries the clean-room rule + license pin.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:95:  - [ ] **Attestation:** no Eve source text copied this phase.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:110:  - [ ] **Attestation:** no Eve source text copied this phase.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:145:  - [ ] **Attestation:** no Eve source text — and no step-for-step logic skeleton — copied this phase.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:162:  - [ ] **Attestation:** no Eve source text copied this phase.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:164:### Phase 4 — Housing the artifacts (catalog + decision records)
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:170:  2. Write a decision record in `decisions/` **only for high-impact adoptions** — anything that touches the
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:173:     revisit / the bet / rejected / expected signal). One file per high-impact pattern.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:174:  3. Cross-link: `LESSONS.md` → decision records; decision records → `20-patterns/*` provenance.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:180:  - [ ] Every **high-impact** Adopt has a decision record; lower-impact Adopts live in `LESSONS.md`; every Reject is captured.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:182:  - [ ] **Attestation:** `LESSONS.md` and all decision records contain zero Eve source text.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:186:- **Note:** this is *implementation*, gated by its own clean-room check — re-derive from `LESSONS.md`, never
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:193:- **RAG-first, read-second.** Drive breadth with Ask Self queries; only open specific Eve files when the RAG
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:195:- **Paraphrase-on-ingest.** Never park a raw snippet "to summarize later." Summarize at read time, in our words.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:197:- **Provenance is pointers, not payload — kept light.** `00-PROVENANCE.md` says *where* an idea came from, never
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:205:- Each adopted pattern has a decision record in `decisions/`.
PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:208:- Final attestation in `00-PROVENANCE.md`: *the entire study copied zero Eve code and mirrored no logic skeletons.*
PROJECT/2-WORKING/EVE-STUDY/INITIAL-COMPARISON.md:22:They share a design philosophy (filesystem-first, durable, hook/skill/schedule primitives) but live at different layers: Eve is "how to build a durable agent"; this repo is "how to keep N agents you didn't build from stepping on each other." Eve is the closest mainstream framework to your aesthetic — but it assumes away the exact problem (tick's collision-free claims across heterogeneous agents) that this spike exists to solve.

codex
The plan is useful but not defensible as written: its copyright/Apache analysis is too categorical, and its method is not a true clean-room because the same person reads Eve and later re-derives from that exposure.

**Findings**

**Accuracy**
- [Blocker] Most important correction: rewrite §1’s Apache claim. Saying “we avoid that obligation entirely” and that paraphrased lessons carry “no license encumbrance” overstates what paraphrase buys you ([EVE-REVIEW.md §1](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:48), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:50)). The defensible version is: if the study truly avoids protectable expression and derivative copying, Apache notice/attribution duties are likely not triggered. That is a contingent conclusion, not a guarantee created by the plan itself.
- [Should] The idea/expression sentence is too absolute. “Ideas and architecture are not copyrightable” ignores non-literal copying and protectable structure/sequence/organization; your own warning about “control-flow / logic skeleton” already concedes that structure can carry expression ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:19), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:45)). This should be narrowed to “high-level ideas may be reusable; concrete structure and arrangement may still be protected.”
- [Should] “Apache-2.0 permits reuse with attribution + NOTICE propagation” is incomplete legal shorthand ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:48)). Operationally that may be enough for this doc, but a lawyer would object that it compresses the license too hard.
- [Nit] The document is internally inconsistent on artifacts: §0 says “a decision record per pattern we commit to adopt” ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:25)); Phase 4 says only high-impact adoptions get decision records ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:170)); Definition of done swings back to “Each adopted pattern has a decision record” ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:205)). Also §2 says `PLAN.md` is “this file,” but the file is `EVE-REVIEW.md` ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:62)).
- [Pass] The strongest part of the IP posture is the ban on transliteration and step-for-step logic capture; that is a prudent compliance rule even if it is not a precise statement of doctrine ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:42)). The context doc also correctly frames Eve as adjacent rather than equivalent to `tick`’s problem space ([INITIAL-COMPARISON.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/INITIAL-COMPARISON.md:17), [INITIAL-COMPARISON.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/INITIAL-COMPARISON.md:22)).

**Clean-Room Adherence**
- [Blocker] Most important correction: stop labeling this a clean-room without qualification. Classic clean-room means separated reader/spec-writer and implementer; this plan has one person read source, distill lessons, then later implement from those lessons ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:20), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:39), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:186)). That is a contamination-reduction process, not a true clean-room.
- [Should] The RAG claim is backwards. “RAG-first” does not “keep raw source out of context” unless the retrieval layer is explicitly configured to return summaries instead of code chunks; as written, Ask Self is a direct leak path into model context ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:15), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:35), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:193), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:194)).
- [Should] “A reference is not a copy” is too broad as a safety label ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:38)). Bare paths and commit SHAs are usually fine, but the example provenance pointer already carries a distinctive Eve term ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:37)), which clashes with the later ban on lifting distinctive names ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:44)).
- [Should] The per-phase attestation is good discipline but weak as a control because it is self-certification by the same exposed reader ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:53), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:145), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:208)). If “clean-room” matters, you need separation or at least independent review of the distilled spec before implementation.
- [Pass] The paraphrase-on-ingest rule and the Phase 2 anti-pattern/dependency/mechanical-contrast gates are meaningful contamination reducers and good study hygiene; they just do not cure the single-reader/single-implementer problem ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:121), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:195)).

RECOMMENDATION: Revise this before use: narrow the Apache/copyright claims, relabel it as a single-analyst source study unless you add a separate implementer/spec boundary, and tighten the RAG/provenance rules; reversibility is Easy because this is a wording/process correction, not a code or license change.
tokens used
28,390
The plan is useful but not defensible as written: its copyright/Apache analysis is too categorical, and its method is not a true clean-room because the same person reads Eve and later re-derives from that exposure.

**Findings**

**Accuracy**
- [Blocker] Most important correction: rewrite §1’s Apache claim. Saying “we avoid that obligation entirely” and that paraphrased lessons carry “no license encumbrance” overstates what paraphrase buys you ([EVE-REVIEW.md §1](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:48), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:50)). The defensible version is: if the study truly avoids protectable expression and derivative copying, Apache notice/attribution duties are likely not triggered. That is a contingent conclusion, not a guarantee created by the plan itself.
- [Should] The idea/expression sentence is too absolute. “Ideas and architecture are not copyrightable” ignores non-literal copying and protectable structure/sequence/organization; your own warning about “control-flow / logic skeleton” already concedes that structure can carry expression ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:19), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:45)). This should be narrowed to “high-level ideas may be reusable; concrete structure and arrangement may still be protected.”
- [Should] “Apache-2.0 permits reuse with attribution + NOTICE propagation” is incomplete legal shorthand ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:48)). Operationally that may be enough for this doc, but a lawyer would object that it compresses the license too hard.
- [Nit] The document is internally inconsistent on artifacts: §0 says “a decision record per pattern we commit to adopt” ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:25)); Phase 4 says only high-impact adoptions get decision records ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:170)); Definition of done swings back to “Each adopted pattern has a decision record” ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:205)). Also §2 says `PLAN.md` is “this file,” but the file is `EVE-REVIEW.md` ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:62)).
- [Pass] The strongest part of the IP posture is the ban on transliteration and step-for-step logic capture; that is a prudent compliance rule even if it is not a precise statement of doctrine ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:42)). The context doc also correctly frames Eve as adjacent rather than equivalent to `tick`’s problem space ([INITIAL-COMPARISON.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/INITIAL-COMPARISON.md:17), [INITIAL-COMPARISON.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/INITIAL-COMPARISON.md:22)).

**Clean-Room Adherence**
- [Blocker] Most important correction: stop labeling this a clean-room without qualification. Classic clean-room means separated reader/spec-writer and implementer; this plan has one person read source, distill lessons, then later implement from those lessons ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:20), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:39), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:186)). That is a contamination-reduction process, not a true clean-room.
- [Should] The RAG claim is backwards. “RAG-first” does not “keep raw source out of context” unless the retrieval layer is explicitly configured to return summaries instead of code chunks; as written, Ask Self is a direct leak path into model context ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:15), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:35), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:193), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:194)).
- [Should] “A reference is not a copy” is too broad as a safety label ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:38)). Bare paths and commit SHAs are usually fine, but the example provenance pointer already carries a distinctive Eve term ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:37)), which clashes with the later ban on lifting distinctive names ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:44)).
- [Should] The per-phase attestation is good discipline but weak as a control because it is self-certification by the same exposed reader ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:53), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:145), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:208)). If “clean-room” matters, you need separation or at least independent review of the distilled spec before implementation.
- [Pass] The paraphrase-on-ingest rule and the Phase 2 anti-pattern/dependency/mechanical-contrast gates are meaningful contamination reducers and good study hygiene; they just do not cure the single-reader/single-implementer problem ([EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:121), [EVE-REVIEW.md](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-10361-2551/PROJECT/2-WORKING/EVE-STUDY/EVE-REVIEW.md:195)).

RECOMMENDATION: Revise this before use: narrow the Apache/copyright claims, relabel it as a single-analyst source study unless you add a separate implementer/spec boundary, and tighten the RAG/provenance rules; reversibility is Easy because this is a wording/process correction, not a code or license change.
