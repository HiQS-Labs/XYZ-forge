# RELAY · GH1077 close-the-loop skill final QA and forward example
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: —
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh1077-close-the-loop-skill-final-qa-and-forward-example): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/close-the-loop/SKILL.md** in the committed checkout; read that canonical file directly.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: one Markdown skill that reports possible session follow-ups with evidence, no invented obligations or default writes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Bounded final review and forward example

Read the whole skills/2-daily/close-the-loop/SKILL.md and its seeded alias .relay-artifacts/SKILL.md, PROJECT/2-WORKING/GH-1077-CLOSE-THE-LOOP.md, the 2-daily index in ARCHITECTURE.md, and TESTS-RESULTS/2026-10-15+GH-1077/session-example.md. The user requests a pure SKILL.md in the daily folder that looks back through current conversation for possible forgotten doc/GitHub updates and returns a numbered list. Default report-only. No scripts, installers, new tests, devices/session-log scraping or automatic execution. Express was considered and rejected because this is a new workflow without critical-hotfix/registered-covering-suite eligibility; do not weaken that policy.

First use the new skill to answer the fictional conversation example. Give its numbered report in this relay, using only the supplied history/status observations; no real GitHub query, filesystem writes outside this thread or execution. Do not infer unavailable earlier turns. No intended answer is supplied.

Then assess the resulting behavior and skill instructions: are candidate actions grounded, cancellations/deferrals and mere brainstorming respected, partial context and unverified status honest, and doc/issue/PR targets correctly scoped? Is the single-file payload sufficient and lean? Does the report preserve useful next actions without becoming a general backlog scan or execution pipeline? Is index registration accurate and rating65/20/50/85 modest? Cite concrete contradictions if any; no speculative new machinery.

This is ordinary reversible prose creation. One independent final QA is requested, not a runtime audit or full test campaign. Format validation passed; documentation route is selected by the existing classifier. Only this relay thread writable. Do not run git, validate.sh, test/*.sh, pytest or fixtures. No external mutation. Append one reviewer block with the applied example report, graded findings, swept file: yes/no, literal VERDICT: PASS|FAIL|PARKED and Basis. Approve with STATUS: Approved and NEXT: — when supported. The harness records the one scoped commit. Round1/3.

### Reviewer · Round 1

Ship within this bounded prose-review scope.

swept file: yes

#### Applied example report

Scope: only the fictional conversation and supplied observations in `TESTS-RESULTS/2026-10-15+GH-1077/session-example.md`; earlier turns were compacted away. No live status checks or task execution performed.

1. **Add the rollback result to ExampleOrg/Widget#44** — Request: “After the parser fix lands, update ExampleOrg/Widget#44 with the rollback result.” Supplied observations say PR47 merged and issue44 still has no rollback result. Target: https://github.com/ExampleOrg/Widget/issues/44. Status: confirmed pending in the supplied snapshot. Next: recover the actual rollback result from the parser work evidence, then prepare the requested issue update; the result itself is not supplied here.  [Unverified — no citation]
2. **Revisit the investigation of ExampleOrg/Widget#71 after the parser work** — Request: “Please investigate ExampleOrg/Widget#71, but finish the parser fix first”; assistant promised to return. PR47 is merged, but no issue71 observation or investigation outcome is available. Target: https://github.com/ExampleOrg/Widget/issues/71. Status: unverified. Next: confirm the parser wrap-up is complete and inspect #71/current investigation evidence before resuming or duplicating work.

#### Graded findings

- [Pass] Grounded candidates and honest uncertainty: `.relay-artifacts/SKILL.md:22-37` requires tracing requests to their latest outcome, distinguishes observation from inference and rejects open status alone as an orphan. The example preserves #44's missing update without inventing its rollback result, and #71 without claiming its investigation never happened.
- [Pass] Exclusions work on the supplied inputs: `.relay-artifacts/SKILL.md:25-27` says “Respect later corrections, cancellations, superseding decisions and deliberate deferrals” and “An intentional handoff is not forgotten work.” The example's next release has not occurred, caching was merely brainstorming, #60 was cancelled, and PR52 awaits named owner Pat; none belongs in the candidate list. No additional or pre-existing defects found in the complete 57-line artifact.
- [Pass] Reporting stays bounded and useful: `.relay-artifacts/SKILL.md:18-20,29-32,41-57` discloses missing history, limits checks to named artifacts, binds issue numbers to repositories, requires evidence/status/next steps, and stops without default writes. The explicit-action exception at lines 55-57 preserves actual user authorization without turning this report-only invocation into an execution pipeline.
- [Pass] Single-file payload and registration: `.relay-artifacts/SKILL.md:1-9` supplies identifying frontmatter and triggers; `ARCHITECTURE.md:72-96` declares 19 daily skills and describes close-the-loop as reporting possible forgotten conversation follow-ups. The read-only probe below found seed/source equality, only `SKILL.md` in the payload, 19 disk skills and 19 index rows with no set differences. No installer, script, dependency or new suite is needed for the stated reporting behavior.
- [Pass] Scope/rating are proportionate: `PROJECT/2-WORKING/GH-1077-CLOSE-THE-LOOP.md`, “Scope and fit” explicitly rejects express because this is a new workflow rather than a critical hotfix with an existing covering suite. Its “Ratings:65/20/50/85” explanation ties the score to explicit demand, bounded risk, neutral appeal and a small prose change; no override or unsupported incident claim appears.

#### Probe receipt and limits

Read-only command (with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`; scratch directory created beforehand):

```sh
python3 - <<'PY'
from pathlib import Path
seed=Path(".relay-artifacts/SKILL.md")
source=Path("skills/2-daily/close-the-loop/SKILL.md")
print("seed_matches_source:",seed.read_bytes()==source.read_bytes())
payload=sorted(str(p.relative_to(source.parent)) for p in source.parent.rglob("*") if p.is_file())
print("payload_files:",payload)
dirs=sorted(p.name for p in Path("skills/2-daily").iterdir() if p.is_dir() and (p/"SKILL.md").is_file())
arch=Path("ARCHITECTURE.md").read_text().split("### `2-daily`",1)[1].split("### `3-weekly`",1)[0]
rows=[line.split("](",1)[1].split("/SKILL.md)",1)[0].rsplit("/",1)[-1] for line in arch.splitlines() if line.startswith("| [")]
print("daily_skill_count:",len(dirs))
print("index_row_count:",len(rows))
print("missing_from_index:",sorted(set(dirs)-set(rows)))
print("index_missing_on_disk:",sorted(set(rows)-set(dirs)))
PY
```

Exit status: 0. Decisive output:

```text
seed_matches_source: True
payload_files: ['SKILL.md']
daily_skill_count: 19
index_row_count: 19
missing_from_index: []
index_missing_on_disk: []
```

This is a manual application and static prose review, not proof of future model compliance. No tests, executable fixtures, workflows, live GitHub queries or git commands ran. The existing harness gate remains outside this review turn; no gate result is asserted here.

VERDICT: PASS

Basis: The whole artifact satisfies the report-only Definition of Done and produces grounded, correctly scoped follow-ups from the supplied example while respecting exclusions and missing context. No required fixes found.

Done — relay closed (Approved), no further review turn needed. Handing the token to codex-producer for harness closeout.

### Producer · Round 2

The operator clarified the core requirement: catch missing propagation from session findings/decisions into execution docs even without an explicit promise. The skill now traces finding → source issue/record → downstream task/date execution consumer, with bounded discovery and minimal pointer proposals. The fictional example includes a completed spike recorded in issue80 while tomorrow's importer plan retains the old approach and no link. Apply the UPDATED skill to the whole UPDATED session-example.md; no intended report is supplied. No live queries or execution.

Round1 produced a useful report/static PASS under the initial scope, but the harness refused close-mismatch. Do not call it attested approval. Cumulative review is round2/3, not a reset. Whole new skill remains the sole payload; verify no overbroad synchronization, inferred obligation presented as explicit request, or default writes. Prior Setup's seed alias is superseded: read the committed canonical skill directly; do not create/change .relay-artifacts files. Only this thread writable.

Append your applied report and graded verdict with file:line evidence, swept file: yes/no, VERDICT and Basis. On approval, set STATUS: Approved and NEXT: —, then use the env-pinned absolute tick to **done RELAY-GH1077-FINAL-R2-20261015 --agent codex**. Do not merely release the token on approval; that caused the prior close-mismatch. No git commands/self-commit. No tests or real external actions.

### Reviewer · Round 2

swept file: yes

#### Applied example report

Scope: only the whole updated fictional conversation and supplied observations in `TESTS-RESULTS/2026-10-15+GH-1077/session-example.md:1-27`. Earlier turns are unavailable; no live checks or task execution performed. Status refers to the supplied snapshot. All shortened `session-example.md` citations below refer to that path.

1. **Update ExampleOrg/Widget#44 with the rollback result** — Explicit request: “After the parser fix lands, update ExampleOrg/Widget#44 with the rollback result.” PR47 merged, but issue44 has no rollback result (`session-example.md:7-8,20-21`). Source: merged parser PR47; downstream target: https://github.com/ExampleOrg/Widget/issues/44. Status: confirmed pending in the supplied observations. Next: recover the actual rollback result from the parser evidence and propose the requested issue update; the result itself is unavailable here.
2. **Check the deferred investigation of ExampleOrg/Widget#71** — Explicit request: “Please investigate ExampleOrg/Widget#71, but finish the parser fix first”; the assistant promised to return (`session-example.md:11-12`). PR47 merged, but no observation of issue71 is available (`session-example.md:20-22`). Target: https://github.com/ExampleOrg/Widget/issues/71; no investigation record is supplied. Status: unverified. Next: confirm parser wrap-up is complete and inspect #71/current investigation evidence before resuming or duplicating work.
3. **Carry the streaming-spike decision into tomorrow's importer plan** — Inferred handoff gap, not an explicit promise: the completed spike's decision and limitations are recorded in ExampleOrg/Widget#80, while tomorrow's plan retains the pre-spike approach and lacks a link (`session-example.md:9-10,24-27`). Source already updated: https://github.com/ExampleOrg/Widget/issues/80. Downstream target: `PROJECT/2-WORKING/IMPORTER-EXECUTION.md`. Status: confirmed pending in the supplied observations. Next: read the recorded conclusion and propose a short canonical issue pointer plus its execution implication, including relevant limitations. The actual decision is not supplied, so no replacement approach can be specified yet.

#### Graded findings

- [Pass] Clarified propagation requirement: `skills/2-daily/close-the-loop/SKILL.md:13-15,23-32,48-53` traces findings into concrete execution consumers without requiring a promise and distinguishes inferred gaps from explicit requests. Item 3 preserves both the missing pointer and stale approach observed at `TESTS-RESULTS/2026-10-15+GH-1077/session-example.md:24-26`, without inventing the spike conclusion. No behavior fix needed.
- [Pass] Bounded discovery and minimal propagation: `skills/2-daily/close-the-loop/SKILL.md:19-32` restricts checks to available conversation, directly relevant links and bounded task/date lookups with a concrete consumer role. “Do not demand updates to every document for every task” (lines 26-27) and the canonical-pointer preference (lines 29-32) prevent blanket synchronization and duplicated findings. No expansion needed.
- [Pass] Exclusions and uncertainty: `skills/2-daily/close-the-loop/SKILL.md:34-43,60-61` respects cancellations, superseding decisions, deliberate deferrals and unaccepted ideas, and separates unavailable status from absence. `TESTS-RESULTS/2026-10-15+GH-1077/session-example.md:13-17,20-22` supplies an untriggered release deferral, caching brainstorm, cancelled rewrite and Pat's ordinary review handoff; none yields a candidate. Issue71 remains unverified. No obligation is inferred from missing earlier turns.
- [Pass] Useful report without default execution: `skills/2-daily/close-the-loop/SKILL.md:47-53` requires numbered, deduplicated, evidenced candidates and smallest next steps; lines 15,39-43,63-66 prohibit execution for the sweep while honoring separately authorized selected actions after a current-state recheck. The example correctly scopes the Widget issues and supplied importer plan. No doc, issue or PR action was executed.
- [Pass] Lean payload and accurate registration: `skills/2-daily/close-the-loop/SKILL.md:1-8` identifies the skill and triggers; `ARCHITECTURE.md:72-96` registers it among 19 daily entries. The read-only probe below found only SKILL.md in its payload and equal disk/index sets. No script, installer, dependency or new suite is needed for this prose behavior.
- [Pass] Proportionate scope and rating: `PROJECT/2-WORKING/GH-1077-CLOSE-THE-LOOP.md:23-32,49-60` keeps the workflow reversible, explicitly rejects express eligibility, explains ratings 65/20/50/85, and records bounded downstream propagation. These are editorial estimates, not measured outcomes; the supplied scope supports their modest rationale.

I read the entire canonical 66-line skill, the entire updated example and task doc, and the daily index. No additional or pre-existing defects found within this bounded scope. Round 1's close-mismatch is not treated as attested approval.

#### Probe receipt and limits

Read-only command:

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
from pathlib import Path
source=Path("skills/2-daily/close-the-loop/SKILL.md")
print("skill_lines:",len(source.read_text().splitlines()))
print("payload_files:",sorted(str(p.relative_to(source.parent)) for p in source.parent.rglob("*") if p.is_file()))
dirs=sorted(p.name for p in Path("skills/2-daily").iterdir() if p.is_dir() and (p/"SKILL.md").is_file())
arch=Path("ARCHITECTURE.md").read_text().split("### `2-daily`",1)[1].split("### `3-weekly`",1)[0]
rows=[line.split("](",1)[1].split("/SKILL.md)",1)[0].rsplit("/",1)[-1] for line in arch.splitlines() if line.startswith("| [")]
print("daily_skill_count:",len(dirs))
print("index_row_count:",len(rows))
print("missing_from_index:",sorted(set(dirs)-set(rows)))
print("index_missing_on_disk:",sorted(set(rows)-set(dirs)))
PY
```

Exit status: 0. Decisive output:

```text
skill_lines: 66
payload_files: ['SKILL.md']
daily_skill_count: 19
index_row_count: 19
missing_from_index: []
index_missing_on_disk: []
```

This is static prose review and manual application, not proof of future model compliance or runtime/gate attestation. No git commands, tests, executable fixtures, live GitHub queries or external mutations ran. The harness gate remains outside this turn.

VERDICT: PASS

Basis: The whole updated skill satisfies the clarified Definition of Done: it catches the concrete spike-to-plan gap alongside explicit follow-ups, labels inference honestly, respects exclusions and missing context, and proposes bounded next steps without default execution. No required fixes found.

Done — relay closed (Approved), no further review turn needed. Handing off to codex-producer for harness closeout with the token marked done.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
