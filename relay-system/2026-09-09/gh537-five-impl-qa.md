# RELAY · GH-537 /five skill — final implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-09.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh537-five-impl-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: skills/five/SKILL.md (the implementation); supporting surfaces: ARCHITECTURE.md (one Skills Index row), CHANGELOG.md (one 2026-09-09 entry), PROJECT/2-WORKING/GH-537-FIVE-SKILL.md (plan + acceptance checklist)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-09
- Definition of Done: the acceptance-criteria checklist in PROJECT/2-WORKING/GH-537-FIVE-SKILL.md, including the behavioral-QA item (dense/sparse/empty inputs + red control, recorded below).
- Machine vocabulary (GH-533 workaround): end your review block with your prose verdict AND, on their own lines, `VERDICT: PASS` (or FAIL) and `Basis: <one line>` — bin/validate-relay-block requires them.

## Questions for the Reviewer to adjudicate (answer each, with file:line citations)

1. Does skills/five/SKILL.md satisfy every acceptance criterion in PROJECT/2-WORKING/GH-537-FIVE-SKILL.md — 5+5 contract, grounding rule WITH the silence-is-not-a-non-goal clause, empty-input guard with precedence over the count, no-filler markers, checksum-not-substitute bottom line, trigger-rich folded frontmatter?
2. Do the three named surfaces exist and only those (SKILL.md + one index row + one CHANGELOG entry)? Any fourth surface or scope creep in the branch diff (base e569ca72)?
3. Is the embedded behavioral-QA record below sound: do the dense/sparse/empty outputs actually demonstrate the criteria, and does the red control genuinely construct an output the criteria reject (a check that cannot fail is not a check)?
4. Is the CHANGELOG entry accurate to what was done and verified (no overclaim — note which verifications it cites)?
5. Any duplicate subsystem, writer, or parallel mechanism introduced (there should be none — this is one markdown file)?
6. Read the whole SKILL.md, not just the new file in isolation: any internal contradiction, or trigger phrasing that would mis-fire (e.g. firing when the user wants a plain summary)?

## Embedded record — behavioral QA executed 2026-09-09 (producer; inputs in temp/, untracked by design)

<details><summary>five-qa-transcript.md (verbatim)</summary>

```
# GH-537 behavioral QA — /five procedure executed on three inputs + red control
Executed 2026-09-09 by claude-a (producer). Inputs in temp/five-qa-input-*.md.

## Input (a) — dense: temp/five-qa-input-dense.md (7 decisions, 3 explicit non-goals, one unrequested consequential choice class)

Output produced by following skills/five/SKILL.md Procedure steps 1-5:

**Five — Move the run-time folder from ~/.xyz-rt to ~/Library/Application Support/XYZForge**

**Does (5):**
1. Telemetry flips to enabled-by-default after the move (was opt-in) — Decisions 6  [UNREQUESTED]
2. Config format changes JSON -> TOML at the new location, auto-converted once — Decisions 5
3. First-launch confirmation prompt removed; daemon starts unattended — Decisions 4  [UNREQUESTED]
4. Move is one-way (atomic rename); no fallback copy of the old folder is kept — Decisions 3
5. A symlink ~/.xyz-rt -> new location is left behind for existing scripts — Decisions 2

**Does NOT (5):**
1. Does not migrate the legacy cache directory (regenerated on first run) — Non-goals
2. Does not update third-party docs referencing ~/.xyz-rt — Non-goals
3. Does not add a --rt-path CLI flag — Non-goals
4. Does not keep a fallback copy of the old folder — Decisions 3
5. — no further exclusions stated

Not specified (called, not assumed): fate of the symlink in later releases; Windows path handling; non-cache user data left in the old folder.

Bottom line: if telemetry-on-by-default matters to you, read Decisions 6 before approving.

Contract check (dense): two full 5-slot lists [PASS]; every substantive item cited [PASS]; unrequested consequential choice (telemetry, item 1) surfaced and ranked first [PASS]; explicit exclusions all captured [PASS]; adjacent-but-silent capabilities routed to Not specified, none claimed as explicit non-goals [PASS]; bottom line names the highest-consequence item [PASS]; honest marker used for slot 5 of NOT-list rather than filler [PASS]. VERDICT: PASS

## Input (b) — sparse: temp/five-qa-input-sparse.md (1 real decision, 1 explicit exclusion)

Output:

**Five — Fix: reorder startup checks so the fast path runs first**

**Does (5):**
1. Cheap validation runs before the network round-trip (validate() before connect()) — body, sentence 1
2. — nothing else load-bearing found
3. — nothing else load-bearing found
4. — nothing else load-bearing found
5. — nothing else load-bearing found

**Does NOT (5):**
1. No config changes — body, last line
2. — no further exclusions stated
3. — no further exclusions stated
4. — no further exclusions stated
5. — no further exclusions stated

Not specified (called, not assumed): none.

Bottom line: single-decision change; the one sentence is the whole plan.

Contract check (sparse): honest sparse markers, zero filler [PASS]; real items still cited [PASS]; empty Not specified declared rather than invented [PASS]. VERDICT: PASS

## Input (c) — empty: no artifact in scope

Output:

Five: no artifact to checksum.

Contract check (empty): refusal emitted, nothing invented, count contract correctly overridden by empty-input guard [PASS]. VERDICT: PASS

## Red control — deliberately bad output that MUST FAIL

Bad output (constructed to violate the contract):

**Five — move plan**
Does: 1. Improves platform alignment! 2. Modernizes configuration! 3. Streamlines startup! 4. Better telemetry! 5. Cleaner folder layout!
Does NOT: 1. Does not support Windows 2. Does not include a GUI 3. Does not change pricing 4. Does not affect the CLI 5. Does not require a restart

Check against contract: highlights are marketing (no decisions, no file/section citations — banned table) [FAIL as intended]; non-goals 1-3 never appear in the artifact (Windows, GUI, pricing) — silence dressed as explicit exclusion [FAIL as intended]; no Not specified section [FAIL]; no bottom line [FAIL]. The check REJECTS this output. RED CONTROL CONFIRMED: the criteria can fail.

## Summary
Dense PASS, sparse PASS, empty PASS, red control rejects as required. All four behavioral criteria from PROJECT/2-WORKING/GH-537-FIVE-SKILL.md acceptance list satisfied.
```

</details>

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
