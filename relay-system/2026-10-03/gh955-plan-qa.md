# RELAY · GH-955 plan QA — centralized downstream publisher
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
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
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh955-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- **Artifact under review:** `PROJECT/1-INBOX/GH-955-CENTRAL-DOWNSTREAM-PUBLISHER.md` (the plan). This is a plan review; no code has been written yet.
- **Reviewer:** codex · **Producer:** claude-a · **Started:** 2026-10-03
- **Operational envelope:** a local developer CLI that the operator runs occasionally on one Mac to refresh three small downstream repos. Grade against the stated requirements and commensurate complexity, not enterprise multi-tenant threat models. XYZ-forge forbids new test suites (GH-831); new checks go into existing suites as assertions.
- **Requirements (operator, verbatim intent):**
  - XYZ-forge is upstream again for every standalone repo, reversing #882 / XYZ-skills-army-mini#2.
  - One centralized publisher, including Skills Army HQ and Agent Chorus.
  - It can target one repo or many in one run.
  - The HiQS org scan confirms the downstream set.
- **Source paths to read (ground truth):**
  - `utils/py/xyz_mini_sync.py` (the publisher being generalized; just reworked by #950)
  - `test/gh589-xyz-mini-sync.sh`, `test/gh620-skills-army-mini-sync.sh`
  - `skills/2-daily/agent-chorus/sync-to-standalone.sh`, `skills/2-daily/agent-chorus/publish-manifest.tsv`, `skills/2-daily/agent-chorus/standalone/ci.yml` (the second publisher and the child CI that calls it)
  - `skills/3-weekly/skills-army-hq/UPSTREAM.md`, `skills/3-weekly/push-to-skills-army-mini/SKILL.md`, `skills/3-weekly/push-to-xyz-mini/SKILL.md`, `skills/README.md`, `ROUTER.md`, `utils/ci-route.sh`, `mini/ADAPTATIONS.md`
- **Definition of Done (for the plan):** every requirement maps to an ordered step with inline verification. Claims match the actual paths. The plan extends the existing publisher instead of adding a parallel one. Migration risks (child CI, adoption of a child with no MANIFEST.txt, the #934 edits) are handled. Checks are falsifiable without new suites. The rating rationale is grounded.

### Questions for the Reviewer
1. **Grounding.** Are the plan's factual claims true at the cited paths? In particular: the comparison table of the two publishers; the child CI calling `sync-to-standalone.sh --check` and a smoke path that does not exist in the child; the forge sources' modes matching the TSV's 644/755.
2. **DRY.** Does generalizing `xyz_mini_sync.py` in place (`publish_one` + a multi-target loop + profiles) avoid a second subsystem? Is anything in steps 1–6 duplicative or speculative?
3. **`--adopt`.** Is it the smallest safe way to bring AgentChorus-Skill (no MANIFEST.txt, a `.xyz-canonical-revision` marker) under the ownership guard? Is there a simpler correct path, for example a one-time manual MANIFEST.txt commit in the child?
4. **`--check`.** Is a read-only check the right replacement for the bash `--check` the child CI calls? Is comparing managed paths and `source_sha` enough, given that adapted and seed paths are skipped?
5. **Multi-target semantics.** Continue on failure, worst exit code wins, `--dest` refused for more than one target, fixed order. Is anything missing that would cause a wrong publication?
6. **Missing requirements.** Is anything the operator asked for unmapped? Is any #882 reversal surface missing from step 7 (`grep` the repo for `UPSTREAM.md`, `push-to-skills-army-mini`, `#882`, `skills-army-mini is upstream`)?
7. **Over- or under-engineering.** Flag machinery not commensurate with an occasional-refresh local CLI.

Cite `file:line` for every finding. Behaviour-change requests carry `Observed input:`, `Affected scope:` and `Falsifier:` lines.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
