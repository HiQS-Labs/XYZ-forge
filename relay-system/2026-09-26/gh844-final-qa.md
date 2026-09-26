# RELAY · GH-844 final QA — GH-833 evidence hygiene, and the first hosted Small run recorded
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh844-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh844-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh844-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) #844's acceptance holds: V1b-v2 confines the PRS entry to the glossary section; the witness recipe
    exits non-zero on any unexpected result or unapplied mutation; the non-goal wording is corrected; and the
    recorded runs substantiate this, including the self-test and the "v1 passes the move" gap demonstration;
  - (b) the Small-run records in the GH-831, GH-836 and GH-833 plans match the hosted evidence: run 36276061201,
    its committed receipt, and its `validation.jsonl`. Nothing is overclaimed; in particular, D1 is presented
    as the operator's decision, not taken;
  - (c) the change is docs-only (tier 1), adds no suite, registry entry or code, and keeps the original r0/r1
    evidence unchanged;
  - (d) the #844 ledger row, rating `20/10/50/90` and capture doc follow the repo's lifecycle.

## Review packet

**What this is.** The follow-up to #840. It records the first hosted Small run (GH-831 Phase 3, GH-836 step 6)
and fixes #844 (CodeRabbit's post-merge findings on GH-833's evidence; umbrella #845). The artifact
`.relay-artifacts/gh844-final.diff` is `git diff 241bfcce HEAD`, without the binary `releases.db`. The branch
`fix/gh844-small-run-record` is checked out in this worktree, so read the files whole.

**Operational envelope.** A single-repo local developer harness, and a docs and evidence change. The operator has
ruled "no new tests". Grade against the stated requirements and commensurate complexity. Do not ask for new
suites or automation.

**Read:**
- the artifact;
- `PROJECT/2-WORKING/GH-844-PRS-EVIDENCE-HYGIENE.md`;
- the Status tables and the new Phase 3 results in `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md`, plus
  `GH-836-GATE-HOTSPOTS.md` (Status, D1) and `GH-833-PRS-DEFINITION.md` (Status, non-goals);
- the hosted evidence: `TESTS-RESULTS/2026-09-26+GH-591/wave-9fd2d88543f9f52e2e40b2cb8fc4771b08440ff6/`
  (`provenance.jsonl`, `validation.jsonl`) and `…/wave-b2c307b4e6be45f105b5d1030d75578d91572db2/provenance.jsonl`;
- `TESTS-RESULTS/2026-09-26+GH-833/`: `prs-definition-check-v2.py.txt`, `witness-script-v2.sh.txt`,
  `witnesses-v2.log`, `witnesses-v2-selftest.log` and `provenance.jsonl`, compared with the v1/r1 files.

You may run read-only probes: the checks against `$PWD` (copy `.txt` to a temporary name to execute), a Python
sum of `duration_ms` over the `validation.jsonl` suite events, and
`git diff --no-renames --name-only 241bfcce...HEAD | bash utils/ci-route.sh push`. Do not run suites.

**Questions** (cite `file:line`):
1. Does v2's glossary scoping hold for an entry moved outside it, a second entry inside it, and a missing heading?
   Does the recipe's aggregate catch each unexpected outcome?
2. Do the recorded durations and counts (15.7 min gate, 19.2 min job, 73 suites, 76/76, `gh436` 221 s, `gh549`
   159 s, about 12.0 min without `gh436`, and 57.2 and 59.9 min for the full runs) match the evidence?
3. Is anything overclaimed or missing?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PARKED

Basis: The GH-844 checker changes and the Small telemetry agree with the packet. I cannot establish the job-duration portion of DoD (b) from the retained evidence, and the read-only GitHub query failed in this sandbox. This is an evidence limitation, not an observed failure of the hosted jobs. Retain the small job-metadata extract described in S1, then return for review. No suite, fixture recipe, or git command was run here.

swept file: no

Scope: read the complete artifact, the four current plans, both versions of the definition check and witness recipe, and both new witness logs; inspected the receipts and parsed the Small and two full-run telemetry files. Checked the ledger read-only. This was not an exhaustive review of the thousands of historical CHANGELOG/SQL lines. The pre-existing current-document drift found in the wider read is N1 below; no additional defect was found in the revised checker.

- **[Should] S1 — retain the evidence for job durations and the tier-log claim.** `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md:556` reports 57.2 minutes **job**, `:557` reports 19.2 minutes **job**, and `:563` reports 59.9 minutes; `:559` says both logs name their tier. The supplied qualification receipts establish passing gates, their SHAs and run URLs, but contain neither job start/end timestamps nor the two log excerpts. The gate telemetry does not substitute for job metadata: the two full-run `run.start`→`run.summary` spans are 53.4735 and 55.5461 minutes. These do not disprove the job numbers; they measure a different interval. Concrete fix: retain a small GitHub jobs response (run ID, job name/ID, start/end, conclusion) for runs 36247260339, 36276061201 and 36271811800, plus the two qualification log lines, with provenance. Alternatively narrow the prose to the measurements actually retained. No new test or automation is requested.
  - Observed input: the claims at `:556–563`, and the three `TESTS-RESULTS/2026-09-26+GH-591/wave-*/provenance.jsonl` receipts for `b2c307b4`, `9fd2d885` and `af4fef27`.
  - Affected scope: documentation/evidence for these three hosted jobs only.
  - Falsifier: job metadata whose start/end differences round to 57.2, 19.2 and 59.9 minutes, and the quoted tier lines, would resolve this finding without changing the numerical claims.
  - Probe: `gh api repos/HiQS-Labs/XYZ-forge/actions/runs/36276061201/jobs --jq '.jobs[] | {name,started_at,completed_at,conclusion}'` exited **1**: `error connecting to api.github.com`. This is not evidence that the jobs failed.

- **[Pass] P1 — glossary scoping handles the three requested cases.** `TESTS-RESULTS/2026-09-26+GH-833/prs-definition-check-v2.py.txt:35` locates the heading, `:41` bounds the section, and `:45–49` reject outside/duplicate entries. A read-only `python3 -` probe compiled that exact file and used `unittest.mock.patch.object(Path, 'read_text', ...)` to substitute only HOW-TO-USE text in memory; no tree files changed. Probe exit **0**. Decisive output: `green rc=0 V1b: pass`; `moved rc=1 ... entry sits outside the glossary section`; `duplicate rc=1 ... 2 ... entries ... want 1`; `missing_heading rc=1 ... no Glossary heading`.

- **[Pass] P2 — aggregate status and the recorded gap witness are consistent.** `witness-script-v2.sh.txt:18`, `:22`, `:24` latch failures; `:40` exits with that status. `witnesses-v2.log:43–53` records the moved entry rejected by v2, accepted by v1, and `AGGREGATE: PASS`. `witnesses-v2-selftest.log:53–57` records `rc=0 (want 1) UNEXPECTED` and `AGGREGATE: FAIL`; `provenance.jsonl:8` explicitly records normal exit 0 and self-test exit 1. This is source/log review, not a claim that I reran the executable witness recipe. The corrected non-goal is at `PROJECT/2-WORKING/GH-833-PRS-DEFINITION.md:13`.

- **[Pass] P3 — Small counts and gate timings match retained telemetry.** In `TESTS-RESULTS/2026-09-26+GH-591/wave-9fd2d88543f9f52e2e40b2cb8fc4771b08440ff6/`, `provenance.jsonl:1` and `validation.jsonl` agree. A `python3 -` JSON/hash probe asserted nonempty rows, compared SHA-256 with `telemetry_sha256`, selected `event == 'suite'`, and summed `duration_ms`. Output: `hash match True`, `suite events 75 receipt suites 73 sum seconds 942.276`; largest entries were `gh436 220.740`, `gh549 158.665`, `pdda-install-startup-docs 87.964`, `tier2:pdda 77.232`, `pdda-repo-contract 58.301` seconds. Summary: `passed: 76, failed: 0, total: 76, envelope_drift: none`. Thus 15.7 minutes, 23%/17%, and approximately 12.0 minutes without gh436 are supported. The 76th result includes the identity check, as the plan's D5 explains. D1 remains an operator decision at `GH-836-GATE-HOTSPOTS.md:257`; the diff changes no suite membership.

- **[Pass] P4 — docs routing and ledger state.** A read-only `python3 -` probe extracted the 11 `diff --git` destination paths from the seeded artifact, added the omitted `releases.db` path, and supplied them to `bash utils/ci-route.sh push`; exit **0**, `route=docs`, `tier=1`, `tier_reason=docs-only`. No original r0/r1 recipe/log/check path is modified in the supplied diff; provenance only appends. A SQLite `mode=ro` query returned `integrity_check: ok` and GH844 `(844, 'In progress', 'PROJECT/2-WORKING/GH-844-PRS-EVIDENCE-HYGIENE.md', 20, 10, 50, 90)`. The SQL diff carries add/repoint/update receipts, and the capture's rating is at `GH-844-PRS-EVIDENCE-HYGIENE.md:34`.

- **[Nit] N1 — synchronize the current frontmatter with the new status tables.** `GH-831-THREE-TIER-GATE.md:5–7` still says Phase 2 PR open and updated September 25; `GH-836-GATE-HOTSPOTS.md:5` still says awaiting merge, and `:18` says hosted evidence is owed. Their new Status rows say Phase 3/step 6 is complete. Update those current fields while retaining historical recon/results. This drift predates the new body claims but becomes more misleading with them.

Handing off to Producer (claude-a): retain the narrow hosted evidence for S1 and disposition N1, then open the next review round. The harness owns the relay-file commit.

### Producer · Round 1

All in `6baa4e53`. The artifact is regenerated as `git diff 241bfcce 6baa4e53`, without `releases.db` and this thread.

- **S1 — Implemented.** `TESTS-RESULTS/2026-09-26+GH-831/phase3-hosted-runs.jsonl` holds one GitHub API record
  per run, with its provenance in that folder's `provenance.jsonl`. Each record has: the run ID, head SHA,
  event, conclusion, run created/started/updated times, each job's ID, name, start and completion, and the
  first `wave-reconcile: Qualifying …` log line.
  - The numbers stand, with one relabel: my "job" minutes were the run's created → updated span. Run spans are
    57.2 / 59.9 / 19.2 min; the reconcile jobs themselves took 57.0 / 59.7 / 19.1 min. The GH-831 table and
    comparison bullet now say "run" and give the job time in parentheses. The CHANGELOG says "reconcile runs".
  - The log lines name tier 3, tier 3, and tier 1 with `validate.sh --sequential --subsystem small`.
- **N1 — Implemented.**
  - GH-831's frontmatter now says Phases 1 and 2 merged and Phase 3 evidence recorded, updated 2026-09-26.
  - GH-836's says merged, step 6 done, and D1/D3 await the operator. Its related-list line no longer says the
    #831 evidence is owed.

Handing off to Reviewer (codex) for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
