# RELAY · GH-983 final QA round 3: workhorse SKILL.md + evidence-gated Stop hook
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
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
6. **Commit only the relay file** (`relay(gh983-final-r3): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/workhorse/SKILL.md` and `skills/2-daily/workhorse/stop-hook.sh` at
  HEAD (b483cb11, branch `fix/workhorse-codex-continuation`, PR #984). Supporting receipts:
  `TESTS-RESULTS/2026-10-06+GH-983/hook-evidence-probe.json`, `SUMMARY.md`, `CHANGELOG.md` (GH-983 entry).
  Prior approved rounds: `relay-system/2026-10-06/gh983-final.codex.md` (SKILL.md r2),
  `gh983-claude-compat.codex.md`. This round QAs the two commits that followed those approvals:
  94097d04 (code-review fixes to SKILL.md) and b483cb11 (Stop hook evidence gate).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-06

### Context

GH-983: workhorse could stop when its checklist had no open `- [ ]` boxes even though required
execution or operational evidence was missing. The SKILL.md contract (Rung 0 "Shared continuation and
completion contract") was approved in prior rounds. Since then:

1. **94097d04** fixed seven `/code-review` findings: the verbatim recital (point 5) now requires evidence
   before ticking and an outcome audit before the single report; `[!]` again covers an awaited operator
   decision, unknown target, or Rung 5 Costly/One-way-door confirmation; the operational-gate bullet is
   the general measurement rule (GH-983's 1/1/1 fixture enumeration removed); evidence-before-ticking
   cross-references Rung 6 steps 2–3 instead of restating them; the structured per-rung completion
   report was restored with an outcome-audit line; Rung 6 step 5 names each parent's real re-entry
   mechanism (`merge_cleanup.py --resume`, `releases jog resume <GH-NUM>`, marathon/10days lane re-fire).
2. **b483cb11** changed `stop-hook.sh` deliberately (it was byte-frozen in earlier rounds): it now also
   blocks a stop while any `- [x]` line lacks an `evidence:` pointer (regex `evidence:\s*\S`, case-
   insensitive), and its hand-back message names `[!]` only, dropping the `[-] (parked)` escape that
   contradicted the contract (GH-987). SKILL.md Rung 0 documents the line format
   `- [x] <item> — <acceptance check> — evidence: <path, commit, URL, or quoted output>`.

**Operational envelope:** a Claude Code Stop hook (bash + inline python3, fail-open on any error) plus a
markdown skill contract read by Claude and Codex. Local developer tooling, single clone. Commensurate
complexity applies: do not ask for a semantic evidence verifier, a test suite, a new gate, or
cross-session state. GH-831: a new `test/` file or `validate.sh` entry would itself be a finding.

**Non-goals:** proving end-to-end Claude session reliability; Codex runtime enforcement (the contract
says there is none); changing `install.sh` or the frontmatter hook wiring.

### Questions (answer each, cite file:line)

1. **Hook correctness.** Read `stop-hook.sh` in full. Does it still fail OPEN on every error path
   (bad JSON, bad session id, missing file, missing python3/git)? Is there any input that makes it
   block when it should not, or exit non-zero? Check specifically: a checklist line such as
   `- [x] W1 fix evidence: handling in parser` (the word "evidence:" inside the item text) and a
   line with leading indentation. State whether each is acceptable for a syntax gate.
2. **Hook/contract consistency.** Compare the hook's block message to SKILL.md Rung 0 (`[x]`/`[-]`/`[!]`
   definitions, lines ~80–90) and the Serial Execution Loop + "Stop only for…" bullet. Is there any
   remaining sentence in either file that lets an agent escape required scope via `[-]`, or that
   contradicts the other file?
3. **Recital vs contract.** Does the verbatim recital (SKILL.md "Recite this" block, point 5) now agree
   with "Audit before ending" and Rung 6 step 4? Quote the clause if it does not.
4. **Blocker scope.** Does the restored `[!]` enumeration (Serial Execution Loop; "Stop only for…")
   leave a sanctioned way to stop at a Rung 5 Costly/One-way-door confirmation gate without proceeding
   past it? Is anything now too permissive (a recoverable local failure that could be mislabelled `[!]`)?
5. **Parent re-entry.** Rung 6 step 5 names `merge_cleanup.py ... --execute --resume`,
   `releases jog resume <GH-NUM>`, and marathon/10days lane re-fire. Verify each against
   `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/jog/SKILL.md`, and
   `skills/2-daily/start-marathon/SKILL.md`. Flag any command that does not exist as written.
6. **Receipts honesty.** Does `hook-evidence-probe.json` + `SUMMARY.md` + the CHANGELOG entry describe
   the hook change truthfully, including that `stop-hook.sh_preserved` is now false and that the hook
   checks evidence was *recorded*, not that it is *true*? Does `claude-compatibility.json` need a note
   or is the provenance.jsonl supersession line sufficient?
7. **Over/under-engineering.** Is the `evidence:` regex the right size for this envelope? Flag anything
   in either commit that is speculative, duplicated, or that the skill text already said elsewhere.
8. **Pre-existing defects.** Sweep both files end to end (`swept file: yes|no` is mandatory). Anything
   in the untouched text that the new contract now makes wrong or ambiguous?

- Definition of Done: every question above answered with a citation; no `[Blocker]`; any `[Should]`
  carries `Observed input:` / `Affected scope:` / `Falsifier:`; VERDICT PASS sets `STATUS: Approved`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
