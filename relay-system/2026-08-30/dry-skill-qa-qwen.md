# RELAY · DRY skill QA after sharpening — Policy class, loosened one-rule, audit-the-guards (qwen3.8-max via CommandCode)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-30.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(dry-skill-qa-qwen): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-08-30
- Artifact under review: `skills/dry/SKILL.md` — read it in the repo at that path.
  Read-only for you: do NOT edit it; append findings here only.
- Definition of Done: `dry` is a Claude Code skill that audits a codebase for **subsystem
  duplication** — several pieces doing the same job with no shared owner. It was just **sharpened
  after losing a blind head-to-head**: on the same repo and commit, a manual audit found 9 findings
  and this skill found 3. Three of the misses were design, not budget — the skill's one rule
  excluded them by construction. Five changes were made in response (Policy resource class, loosened
  one rule, an audit-the-guards step, read the repo's rules first, mandatory issue cross-check).

  Grade the CURRENT file. Do not grade the old version, and do not restate the skill back.

  1. **The loosened one rule now reads: "a finding must name a shared *resource* or a shared
     *policy*, never a shared *syntax*."** The old wording ("resource, never shape") suppressed
     text-similarity noise but blinded the skill to constants defined N times with N values. Does
     the new wording now let noise back in? **Name a concrete false positive it admits that the old
     wording correctly rejected.** A generic worry with no worked example is a `[Nit]`.
  2. **The Policy class says to "group by what the constant decides rather than what it is
     called."** Is that an actionable instruction or a wish? If an agent cannot execute it
     mechanically, say what method would replace it — the rival definitions genuinely do not share a
     name, so name-matching is not the answer.
  3. **"Audit the guards" sits inside Step 2 (build the index).** Is that the right place, or should
     it be its own step? It is the technique that produced the skill's only unique win in the
     head-to-head, so burying it is a real risk.
  4. **Self-consistency.** Five edits landed on an existing document. Quote any place where new text
     contradicts surviving old text, or where the same instruction now appears twice.
  5. **Has it bloated?** The skill preaches minimalism. It is now 201 lines. Quote anything that is
     prose rather than instruction and say what replaces or deletes it.
  6. **What is still missing?** The manual audit also found: a vendor client bypassing a shared
     error-body helper, retry/backoff written six times with no jitter, a production script reading
     config from a vendored tree, and `sys.path` surgery enabling cross-tree imports. Would the
     current file catch each of those four? For any it would miss, name the class that is absent.

  Cite `file:line` or a quoted span for every `[Pass]`. Sibling skills for context are in the same
  tree: `skills/recon/SKILL.md`, `skills/triangulate/SKILL.md`, `skills/converge/SKILL.md`,
  `skills/ponytail/SKILL.md`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### R1 · Reviewer (commandcode) · 2026-08-30

swept file: yes — read all 201 lines of `skills/dry/SKILL.md`; also read `skills/recon/SKILL.md`, `skills/triangulate/SKILL.md`, `skills/converge/SKILL.md`, and `skills/ponytail/SKILL.md` to verify every cross-link.

**Q1 — does the loosened rule let noise back in?**

- [Should] Yes — worked false positive. A health probe's `CONNECT_TIMEOUT=2` and a bulk uploader's `CONNECT_TIMEOUT=60` both decide "how long to wait for a connection." Under the new wording they form one Policy cluster, and "A cluster where the values **disagree** is a live defect" (`skills/dry/SKILL.md:65-66`) makes it a ranked defect — but two different operations are *supposed* to carry different timeouts, and merging them into one constant is exactly the wrong DRY. Old wording rejected this correctly: a bare constant was not a resource. The unconditional disagree-equals-defect sentence is the amplifier.
  → Fix: gate on decision ownership — "disagreeing values are a defect only if one owner should answer. Touchers serving different operations or failure domains may rightly disagree; say why the decision should be single before filing." (The Q2 test below also rejects this case mechanically: no single event is gated by both constants.)

**Q2 — is "group by what the constant decides" actionable?**

- [Should] It is a wish, not an instruction — an agent cannot execute "what it decides" mechanically.
  → Replacement method, reading-based, no parser: (1) for each indexed constant, list its read sites; (2) name the predicate each read site gates ("does this order count as paid?", "should this request retry?"); (3) cluster constants whose predicates name the same real-world distinction, with the operational test: **could one real-world event (a single order, request, upload) be classified differently by the two value sets?** Yes → one decision split across N sites; if the constants never co-apply to any single event they are different policies however alike they look. Cheap proxy when the read is hard: the predicates reference the same entity/field (`order.status`, `payment.state`).

**Q3 — is "Audit the guards" in the right place?**

- [Should] Inside Step 2 as an H3 (`skills/dry/SKILL.md:95`, under the Step 2 heading at `skills/dry/SKILL.md:84`) is logically fine — it consumes the index — but structurally risky: the technique that produced the skill's only unique win is subordinate to "build the index" and can be skipped as a detail, especially in a quick pass that only picked "two or three" classes (`skills/dry/SKILL.md:52`).
  → Fix: promote to its own numbered heading, e.g. `## Step 2b — Audit the guards, do not trust them` (no renumbering of Steps 3–6 needed).

**Q4 — self-consistency**

- [Should] Frontmatter class list is stale: "the same table, file, env var, endpoint, binary, or config key" (`skills/dry/SKILL.md:5-6`) has no Policy/constants entry, while Step 1's table (`skills/dry/SKILL.md:61`) and the one rule (`skills/dry/SKILL.md:30`) now do. The description is the routing surface; the new capability is undersold there.
  → Fix: extend the enumeration, e.g. "…config key — or where N files define the same decision with different answers."
- [Should] The one rule's flagship example falls out of Step 3's threshold: "two modules that both define what counts as a paid order, with different value sets" (`skills/dry/SKILL.md:32-33`) is only two touchers, and Step 3 requires "≥3 touching files (≥2 if any toucher *writes* it)" (`skills/dry/SKILL.md:113`) without defining whether a constant's *definer* is a writer. Read the wrong way, the pivot filters out the exact finding the rule promises.
  → Fix: add one clause to Step 3 — "for Policy, a definer counts as a writer."
- No duplicated instructions found; no other new-vs-surviving contradictions.

**Q5 — bloat**

- [Nit] 201 lines is tolerable, but both new prose patches are commentary, not instruction:
  - "An earlier version of this skill said 'resource, never shape', and that wording blinded it to the highest-value duplication class there is…" (`skills/dry/SKILL.md:37-38`) — changelog inside the skill. → Delete the sentence; the line before it already carries the rule.
  - "A guard that was fixed once is not a guard that works. Confidently incomplete is worse than visibly broken." (`skills/dry/SKILL.md:108-109`) — aphorisms. → Delete; "run it, then check its coverage against your index" (`skills/dry/SKILL.md:98-99`) already says the thing.

**Q6 — what is still missing**

- [Pass] retry/backoff written six times with no jitter: **caught**. The Policy row explicitly names "retry counts and backoff formulas" (`skills/dry/SKILL.md:61`); six definers clear the ≥3 threshold and any divergence fires signal 4 (`skills/dry/SKILL.md:135-137`).
- [Should] vendor client bypassing a shared error-body helper: **missed**. Step 3's pivot is binary — "**They meet** → not a finding. One gateway already exists" (`skills/dry/SKILL.md:121`) — so the mixed case (gateway exists, some touchers route around it) dies at "meet." Yet that is precisely the shape converge's fleet table expects dry to emit: "Bypassed gateway — a single canonical module exists; files that import it still reach the resource directly" (`skills/converge/SKILL.md:59`). Absent class: **Contract/Bypass** — the existing shared module, and who reaches around it.
  → Fix: add a third pivot outcome: "some touchers route through a shared module and others do not → bypass finding," and let signal 4 rank it.
- [Should] production script reading config from a vendored tree, and `sys.path` surgery: **missed**, one class gap — **Boundary** (first-party code reaching into an excluded tree). Step 2 excludes vendor trees (`skills/dry/SKILL.md:86-87`), which hides the vendored config resource entirely, and no class row covers import-path manipulation. Worse: a path literal pointing *into* an excluded tree only becomes a resource if it happens to clear the toucher thresholds, so the real shape of this finding — one script crossing the line — stays below them.
  → Fix: (a) extend the File/Config rows: "a first-party reference pointing *into* an excluded directory is reportable at any toucher count — exclusion hides the tree, not reaches into it"; (b) add to the Config or Process row: "module/import-path surgery (`sys.path`, `PYTHONPATH`, `NODE_PATH`, classpath tweaks)."

**Rest of the sweep**

- [Should] Neighbors (`skills/dry/SKILL.md:195-201`) omits converge — the fleet layer whose only input is dry's maps and whose own Neighbors lists dry (`skills/converge/SKILL.md:143`). A dry run that ends with two maps has no onward routing.
  → Fix: add "- [converge](../converge/SKILL.md) — reads two or more of these maps across repos or re-runs; run it once you have two."
- [Pass] Step 1b and the issue cross-check — the other two edits — landed clean: "Quote the rule in the finding. Do not paraphrase it." (`skills/dry/SKILL.md:82`) and "label it `new`, `tracked (#N)`, or `closed-but-present (#N)`" (`skills/dry/SKILL.md:185`) are both mechanically executable.
- [Pass] Cross-references hold: "exactly as in recon" (`skills/dry/SKILL.md:91`) matches recon's graph-only rule (`skills/recon/SKILL.md:58`); the crossing/irreversible handoff (`skills/dry/SKILL.md:147-149`) matches the vocabulary in triangulate/converge (`skills/converge/SKILL.md:144-145`); the ponytail line (`skills/dry/SKILL.md:201`) matches ponytail's charter.
- Pre-existing code (GH-268): whole file swept. Beyond the stale frontmatter list above (surviving text the edits made stale), I found no pre-existing defects; say-so recorded here rather than left unstated.

**Verdict: Changes requested** — the Policy class and guard audit are real improvements, but the unconditional disagree-equals-defect framing (Q1), the unexecutable grouping rule (Q2), the buried unique-win technique (Q3), and the two absent classes (Q6) need a pass before approval.

Handing off to Producer (claude-a) — go to the claude-a window and say "take your turn": log dispositions for these findings and implement the fixes.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
