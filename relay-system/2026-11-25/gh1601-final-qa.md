# RELAY · GH-1601 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1601-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/yesterday-today/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Also read (committed in this checkout): the approved plan `PROJECT/2-WORKING/GH-1601-YESTERDAY-TODAY-SKILL.md` (its `## Requirements` and `## Acceptance` A1-A7), the evidence folder `TESTS-RESULTS/2026-11-25+GH-1601/` (SUMMARY.md and logs, provenance.jsonl), the `ARCHITECTURE.md` diff (`git diff origin/development -- ARCHITECTURE.md`), and the approved plan-QA thread `relay-system/2026-11-25/gh1601-plan-qa.md`.
- Operational envelope: an instruction-only skill (one `SKILL.md`, no scripts) followed by an agent on one operator's machine; read-only `gh`/`git` plus one guarded issue-body edit. XYZ-forge forbids new tests (`AGENTS.md` "No new tests", GH-831): a new `test/` file or registry entry in the diff is itself a finding, and you should not ask for one. Grade against the stated requirements and commensurate complexity; do not ask for scripts or a subsystem.
- Operator decisions already made (do not reopen): a new named skill `yesterday-today` in `skills/2-daily/`; thin reuse of `daily-planner`'s conventions by reference; Codex `gpt-6.2-astra` low-effort read-only validator that never receives the author's conclusions; plan QA already Approved at round 3.
- Definition of Done: each issue requirement and each of A1-A7 is met by the committed artifact and evidence; nothing private or client-specific is in the repo files; the skill is about 130 lines or fewer; no duplicate subsystem or writer slipped in.

### Step A: paraphrase first (GH-1414)
Before reading the evidence or the plan, read ONLY `skills/2-daily/yesterday-today/SKILL.md`. At the top of your review block write 2-5 sentences each under **What this skill does** and **What it is not**, and an **Input boundary** line. Then read the rest and label the following **source-backed**.

### Step B: questions (answer each with `file:line` evidence)
1. Is each of the nine requirements in the plan's `## Requirements` carried by a step or trap, and is any contradicted? Check especially: yesterday = latest working day strictly before today; stop on a confirmed-absent today ledger (offer to create) versus a missing yesterday or failed lookup (stop, name the gap); the baseline-is-draft-source and changed-body branches before `gh issue edit`; review verdict/`commit_id`/older-head distinction; deployment evidence; goal header, scope rule, SOP sections and estimate with formula and dated change log; validator inputs and independence.
2. Does the skill say anything that implies an approval, or permit a write to a server, a merge or a deploy?
3. Is the description's use-versus-`daily-planner` sentence accurate against `skills/2-daily/daily-planner/SKILL.md:128-183`? Does the skill avoid running that engine for a documented reason?
4. For each of A1-A7: what prevents an unchanged base from passing, and where is the observed rejection in the evidence? Is the A5 smoke a real exercise of steps 1-2 and its adjacent path? Note anything the receipt over-claims.
5. Does the diff contain any new test file, registry entry, script, or private/client-specific string? Is `ARCHITECTURE.md` the only catalog change needed?
6. Is anything here more machinery than the problem needs, or is a required case missing?

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) and a VERDICT; set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

swept file: yes

**What this skill does.** It finds today’s ledger and the ledger for the preceding working day, then checks yesterday’s claims, feedback, and open PRs against GitHub. It carries the shared goal and estimate into a guarded update of today’s issue body. After publication, it asks one independent reviewer to read the published result and audit it against the two issues.

**What it is not.** The updated ledger conveys planned work and the evidence behind it. Merge, deploy, and test sign-off stay outside the workflow, and the shared body update is distinct from Daily Planner’s per-operator claim comment.

**Input boundary.** The seeded `.relay-artifacts/SKILL.md` alone, read in full before the plan, issue, and receipts.

**Step B — source-backed**

Skill citations refer to `.relay-artifacts/SKILL.md`. Plan citations refer to `PROJECT/2-WORKING/GH-1601-YESTERDAY-TODAY-SKILL.md`. Receipt citations refer to `TESTS-RESULTS/2026-11-25+GH-1601/`.

- [Pass] The requirement map supports R1’s date rule, lookup order, confirmed-absent-today branch, prior-date stop, and publish guard (Skill :25–35,71–81), subject to F1. The first body read is both the baseline and draft source. A changed body requires redrafting from that body and checking again, or stopping. A failed pre-edit read stops publication. R2 checks merge evidence, verdict/reviewer/`commit_id`, older heads, end-of-day comments and GitHub deployment evidence, and distinguishes unavailable deployment evidence (Skill :37–50), subject to F2. R3 covers full feedback and Slack disclosure (:52–56), R4 covers live PR state and separates past reviews from current requests (:58–62), R5 covers classification and ordering (:64–67), and R6 retains the goal header, scope, SOPs and estimate components with evidence for share changes and a dated row (:71–76). R7 gives the specified read-only Codex model only two URLs and the checklist, makes it fetch the published body, and requires firsthand adjudication and an unavailable-review disclosure (:83–96). R8 covers the access, shell and privacy traps (:49–50,100–104). R9 specifies the four reply fields (:105). See Plan :40–48 and [GH-1601 §§1–3](https://github.com/HiQS-Labs/XYZ-forge/issues/1601).
- [Should] F1 — Make the failed-today-lookup stop explicit in Step 1. **Observed input:** Plan :82 requires a stop before drafting if *either* lookup is unavailable. Skill :31–32 labels failed or incomplete lookups unavailable, but :33–35 only direct a stop for confirmed absence of today or an absent/unavailable yesterday. The failed-body-read stop at :79 is at the later pre-edit gate. **Affected scope:** today’s lookup fails or is incomplete while the exact prior-workday issue is found. **Falsifier:** for that input, Step 1 reports today’s ledger unavailable, stops before drafting, and makes no creation offer. Add that stop alongside the existing prior-date rule.
- [Should] F2 — Carry the deployment evidence link into the ledger. **Observed input:** Plan :84 requires *linked* GitHub evidence for a deployed label. Skill :47–49 requires evidence visible in GitHub but gives no direction to link it, while :75 expressly requires links for estimate changes. **Affected scope:** a deployment label supported by a GitHub release, deploy comment, or run, including when no estimate share changes. **Falsifier:** for an item with a qualifying run and an unchanged estimate, the ledger’s deployed label still points to that run. Require the link in Step 3.
- [Pass] The authority boundary is explicit at Skill :18–23,49–50,60–62,67,77–81,93. The only external write described is the guarded shared issue-body edit. Trial merges are confined to a local throwaway clone. GitHub evidence can support a factual approval or deployment claim, and the plan itself conveys no sign-off. The Daily Planner boundary matches `skills/2-daily/daily-planner/SKILL.md:151–159,167–183`. The documented engine path selects the newest existing earlier title and writes JSON and Markdown locally (`skills/3-weekly/weekly-planner/scripts/planner_core.py:2283–2300,3299,3325–3331`), supporting the reason for using its conventions with direct reads (Skill :20–23).
- [Pass] A1’s base rejection is the missing skill path (`a1-a4-text.log:1–8`); the candidate has the name, three triggers and Daily Planner sentence (Skill :1–14). A2’s checker catches the removed validator section (`a2-nine-points.log:8,11–14`), and A1’s path absence would prevent base from supplying that section. The keyword hits alone do not verify all nine behaviors, as F1 and F2 show. A4’s base rejection is the missing catalog row (`a1-a4-text.log:9–12`), and the existing viewer/path-integrity suites report 8/0 and 3/0 (`suites-and-gate.log:1–9`, run attributed to `06ff1609e` in `provenance.jsonl:4`). These suites can also pass on base. The local `ARCHITECTURE.md` matched both the GitHub `development` and `ac0e8b65b` copies byte for byte with only line 105 removed. `skills/README.md:13,17–24` defines that registration, and `mini/skills/skill-viewer/scripts/list_skills.py:81–93` discovers the file by glob. Narrow probe `cmp .relay-artifacts/SKILL.md skills/2-daily/yesterday-today/SKILL.md && wc -l .relay-artifacts/SKILL.md` → exit 0, `105 .relay-artifacts/SKILL.md`. One instruction-only skill and the index entry are proportionate.
- [Should] F3 — Complete A3 on the final nonempty inputs and use a clearly fictional planted marker. **Observed input:** Plan :102 requires nonempty checks for all evidence-folder files and the index diff. `a3-privacy-scan.log:1–10` names only four evidence files in its nonempty check and records a separate index scan with no nonempty check. The summary claims the broader scope (`SUMMARY.md:9`). The planted control at `a3-privacy-scan.log:11–13` prints a literal brand-like identifier instead of a clearly fictional marker. **Affected scope:** A3’s privacy claim for the entire candidate, especially the summary, provenance, route, gate, and diff-invariant receipts omitted from the recorded nonempty list. **Falsifier:** the receipt enumerates all nonempty final inputs, including the index patch, records a no-hit result and shows an obviously fictional planted value caught by the same detector. A missing base skill or patch must reject before scanning. The existing planted run shows `rc=0` for a hit, but the receipt has no observed base/empty-input rejection for A3. The skill itself contains generic examples (Skill :27–35,100–105).
- [Should] F4 — Record a complete A5 exercise from the consumer path. **Observed input:** Plan :104 requires a real issue pair, the emitted offer-to-create stop, the exact read commands, a zero-write check and the unavailable distinction. `smoke-steps1-2.log:1–14` records dates, yesterday’s body/comment/checkbox counts, and an adjacent `[]` with `rc=0`. It shows neither the consumer-path load nor identification of today’s exact issue in the pair. It ends at the empty search, before any stop or zero-write output. `SUMMARY.md:19` says the skill “would stop” and summarizes a Git status check without the recorded result. **Affected scope:** A5 main and adjacent branches, including an incomplete or failed lookup. **Falsifier:** one redacted receipt shows the loaded entry point, both exact dates and matched issues, the previous day’s counts, the actual stop output after confirmed absence, a failed lookup reported as unavailable, and the commands and zero-write result. A base checkout fails at the consumer entry point per `a1-a4-text.log:7–8`; replaying the GitHub queries alone could pass there. Retain safe placeholders for private identities and preserve command quoting.
- [Should] F5 — Bind A6 and route to the final candidate. **Observed input:** `a6-diff-invariant.log:1–9` records a 12-path pass, a synthetic `test/new-suite.sh` rejection, and the empty/base-diff rejection (both `rc=1`), but gives no path inventory. `route.log:1–11`, presented as the changed paths against `origin/development`, lists only four files, omitting even the new skill and the index. `suites-and-gate.log:10–11` records an unsupported route invocation. The GitHub compare for `ac0e8b65b...06ff1609e` returned HTTP 404. **Affected scope:** claims about the complete delivery diff, including the absence of new test files, registry changes, or scripts. **Falsifier:** an exact candidate/base path inventory drives both the allowlist and the route result, includes the skill, index and evidence and shows no `test/` or `validate.sh` changes. Preserve the recorded red controls and refresh any existing-suite evidence required on the final candidate per Plan :110.
- [Pass] A7’s provenance file is present (`provenance.jsonl:1–7`) and the plan receipt is Approved (`relay-system/2026-11-25/gh1601-plan-qa.md:243–250`). Final relay approval and the `development` PR base remain delivery-stage checks (Plan :93–94,106). An unchanged base cannot carry this final receipt or the new evidence. No A7 base/control run or completed PR was established in this turn.

The sweep found no additional pre-existing defect in the new skill. The nearest graph was the main Forge checkout, generation `2026-11-23T23:18:20Z`; coverage showed the seed, plan, and receipts missing there, so findings use direct worktree reads. No reviewer phase gate is declared. No suite or live smoke was re-run in the review worktree.

VERDICT: FAIL

Basis: Two approved instructions are incomplete, and the receipts do not yet establish the full privacy scan, read-only smoke, or final diff scope. Handing off to Producer to update the skill and receipts and return them for round 2.

### Producer · Round 1

Each finding re-read against the source before acting.

- [Should] F1 failed-today-lookup stop: **Implemented.** Skill step 1 now stops before drafting, reports "unavailable", and makes no creation offer. Smoke adjacent path B observes the nonzero lookup.
- [Should] F2 link deployment evidence: **Implemented.** Skill step 3: the ledger links the evidence, else "deployment unverified".
- [Should] F3 A3 completeness: **Implemented.** `a3-privacy-scan.log` enumerates all eleven final inputs including the index patch, has a reject-on-empty control and uses a fictional planted marker. (A first run failed on zsh word-splitting of an unquoted variable, the very trap step 9 names; rerun with an array.)
- [Should] F4 complete A5: **Implemented.** `smoke-steps1-2.log` rewritten: entry-point read through the clone path, both dates and matched issues (placeholders), yesterday's counts, confirmed-absent stop, failed-lookup "unavailable" stop, zero-write result. SUMMARY states that the stop lines are what the skill directs, selected by the observed command results.
- [Should] F5 A6/route on the final candidate: **Implemented.** `a6-diff-invariant.log` lists the staged inventory (16 paths) against `origin/development`, drives the allowlist and `utils/ci-route.sh push` from that same inventory, and keeps both red controls; suites and the docs gate re-run on the final candidate.

Handing off to Reviewer for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
