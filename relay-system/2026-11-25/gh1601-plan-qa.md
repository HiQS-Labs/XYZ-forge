# RELAY · GH-1601 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

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
6. **Manual relay: commit only the relay file** (`relay(gh1601-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1601-YESTERDAY-TODAY-SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1601-YESTERDAY-TODAY-SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Operational envelope: an instruction-only skill (one `SKILL.md`, about 130 lines, no scripts) that an agent follows on one operator's machine to refresh a team's per-day planned-work GitHub issue from the previous day's issue, using `gh` and `git` reads and one body edit. XYZ-forge forbids new tests (`AGENTS.md` "No new tests", GH-831). Grade against the stated requirements and commensurate complexity; do not ask for scripts, a new suite or a new subsystem.
- Operator decisions already made (do not reopen): the skill is a **new named skill** `yesterday-today` in `skills/2-daily/`; it must be a thin layer reusing `daily-planner --mode ledger` by reference where that applies; its validation step uses a low-effort read-only Codex sub-agent given the two issue URLs and a checklist, never the author's conclusions.
- Definition of Done: the plan is grounded in the cited paths, the overlap with `daily-planner` is correctly characterized, each acceptance item would fail on base `ac0e8b65b`, and nothing required by the issue is missing.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc's frontmatter `non_goals`, `goal`, `## Status`, `## Requirements`, `## Recon`, `## Preflight bet`, `## Plan`, `## Acceptance`, `## Verification` and `## Risks`. Do not open source files or the issue yet. At the top of your review block write:
- **What this proposes** (2-5 sentences)
- **How the existing system works, per this document** (2-5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections, label inference)
- **Input boundary:** the sections you had read when you wrote the paraphrase.

### Step B: source-backed technical validation
Now read the requirements and source, and label this assessment **source-backed**:
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1601
- `skills/2-daily/daily-planner/SKILL.md` (the "Daily Work Ledger" section, lines 128-183)
- `skills/README.md` (the contract, "Mode before skill (GH-1299)"), `ARCHITECTURE.md` Skills Index (`2-daily` table)
- `skills/2-daily/todo-list/SKILL.md` (section 4, the issue-closeout procedure), `skills/2-daily/where-are-we-at/SKILL.md`
- `utils/ci-route.sh` (the docs/full route for `skills/2-daily/<name>/SKILL.md`)

Answer each with `file:line` evidence:

1. Are the Recon claims about `daily-planner --mode ledger` true at the cited lines? In particular: does it already rewrite a ledger issue body or verify checkbox claims against PR reviews? Is "thin layer over it" achievable, or does the skill have to stand on its own with a reference?
2. Does the plan satisfy "Mode before skill (GH-1299)": are the existing skills checked, and is each rejection reason true?
3. The plan's `## Requirements` section lists nine lessons the skill must carry; `## Plan` lists the steps. Is any lesson missing, merged away or contradicted by the plan's steps? Check especially: the save-old-body and re-read-live-body rule before `gh issue edit`, the "plan, not an approval" rule, the header/estimate preservation, the Codex `gpt-6.2-astra` low-effort read-only validator that never receives the author's conclusions, and the traps (zsh word-splitting, expired cloud login reported as not checked, proxied grep false negatives, no bare @mentions, no personal emails or secrets in an issue).
4. Is the registration surface complete (index row; anything else this repo requires when a skill is added, such as a catalog, a README table or a pinned count)? Name any file the plan misses, with the line that pins it.
5. What prevents an unchanged base from passing each acceptance item A1-A6, and is each red control the right observation? Distinguish checks that prove the skill is right from checks that only prove a file exists.
6. Is the smoke plan (A5) a real exercise of the skill's steps 1-2 from the consumer entry point, and does its adjacent path (missing today ledger) actually reach a stop the skill can show without writing anything?
7. Is anything here more machinery than the problem needs, or is a required case missing? Flag over- and under-engineering concretely.

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

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

**What this proposes.** Add a prompt-only `/yesterday-today` skill that finds both work ledgers, checks yesterday’s claims and feedback against GitHub, and updates today’s issue body. It carries the goal header and completion estimate forward and calls for one independent read-only Codex review after publication.

**How the existing system works, per this document.** Daily Planner locates date-stamped ledger issues, carries unfinished items for one operator, and records work in per-operator claim comments. This plan borrows its discovery rules for compatible ledgers and adds a team-wide evidence review and issue-body update.

**What it's not.** The frontmatter excludes helper code, changes to claim comments, unattended creation of a missing ledger, deployment, and skill installation.

**Input boundary.** Plan frontmatter `non_goals` and `goal`, and the Status, Requirements, Recon, Preflight bet, Plan, Acceptance, Verification, and Risks sections. Paraphrase based on the plan text before checking the issue or implementation sources.

**Step B — source-backed**

Plan line citations refer to `.relay-artifacts/GH-1601-YESTERDAY-TODAY-SKILL.md`.

- [Pass] A standalone, prompt-only workflow with a discovery reference fits the job. Daily Planner verifies claim-comment authorship and scans carryover, reviews and remediation for one operator, with bounded review-thread checks for top candidates. Its publish path posts or patches claim comments. It has no team-wide checkbox-to-review verification and issue-body replacement workflow (`skills/2-daily/daily-planner/SKILL.md:151-155,167-183`; `skills/3-weekly/weekly-planner/scripts/planner_core.py:3107-3148`). Tighten Recon's shorthand about review verification to reflect Step 3. The other candidates serve distinct units of work: local telemetry synthesis (`skills/2-daily/daily-planner/SKILL.md:132`), topic status (`skills/2-daily/where-are-we-at/SKILL.md:48-57,167-169`), weekly planning and sequencing (`skills/3-weekly/weekly-planner/SKILL.md:49-50,85-95`), and per-issue closeout comments (`skills/2-daily/todo-list/SKILL.md:166-187`). This supports the named skill under `skills/README.md:23-28`. The proposed single skill is proportionate.
- [Should] Make discovery and A5 explicitly read-only, including the missing-today stop. **Observed input:** Plan :64,81-83 points to Daily Planner discovery and :101 says “writes nothing,” while the referenced command at `skills/2-daily/daily-planner/SKILL.md:143-159` reaches unconditional JSON/Markdown writes at `skills/3-weekly/weekly-planner/scripts/planner_core.py:3299,3325-3331` even without `--publish-ledger`. Its default timezone is Los Angeles (:2085-2093), and its prior-date rule chooses the newest existing title (:2283-2300), which can differ from the requested previous workday (Plan :40,82). **Affected scope:** compatible repos reusing discovery, and missing-today smoke. Reuse the documented title and selection conventions with GitHub reads, use the resolved operator-local dates, and fall back to the documented weekly links for custom titles. Distinguish confirmed absence from incomplete or failed lookup. Smoke from the new skill on a real pair, then on a date with confirmed absence, and record resolved dates, a checkbox count, the stop message, and which read commands ran. **Falsifier:** a compatible repo with a missing prior-workday issue and an older issue returns the resolved workday as missing, and a successful empty today lookup offers creation with zero writes; a failed lookup reports unavailable.
- [Should] Specify the two branches of the pre-edit comparison and the publish-to-validation handoff. **Observed input:** Plan :40 requires verifying the body is unchanged, but :88 only says to re-read it before the edit. Plan :46 puts independent QA after publication, while :89 gives inputs and independence without requiring a read of the published body. **Affected scope:** a changed or unreadable live body before edit, or validation after a successful publication. On changed body, rebase the draft on the live content and repeat the check, or stop. On failed read, stop. Have the validator fetch the published body from its issue URL after a confirmed write. **Falsifier:** with saved body `A` and live body `A + teammate update`, no stale edit is issued; on success, the validator reads the live issue and receives only the two URLs and checklist.
- [Should] Make the implementation checklist preserve the full issue brief. **Observed input:** Plan :43 says “requested reviewers,” but :86 says only “reviewers.” Plan :45 calls out the official count, progress bar and items list, and conditions share changes on the ledger’s own rule; :88 leaves these implicit. Plan :41,84 names deployed as a separate state but lists merge and review evidence only. Plan :47 mentions possible production/VM reads while [GH-1601 §2](https://github.com/HiQS-Labs/XYZ-forge/issues/1601) excludes any server access. Plan :67 keeps relay-xyz for skill QA, while :75 suggests it for ledger validation. **Affected scope:** open PRs with outstanding review requests, customized goal/estimate sections, deployment claims, and validator dispatch. Make those fields and the ledger’s estimate rule explicit. Check linked deployment evidence available in GitHub and report unavailable evidence as unchecked. Keep the trial merge local to a throwaway clone, with the independent ledger validator following :46,89. **Falsifier:** a PR with a past review and a current request reports both distinctly; a merged PR with no deployment evidence keeps deployment unverified; an estimate governed by a custom rule retains its components and follows that rule; validation uses the published issue with the specified low-effort read-only model.
- [Pass] The outline carries the reviews endpoint and head-aware approval, full feedback reads and optional Slack disclosure, state categories and work ordering, and the plan-versus-approval boundary (Plan :41-44,84-87). A2 should inspect the four concrete final-reply fields (:48) and every trap at :47, including the zsh and proxy cases, mention etiquette and private data. Carry those into Step 9, whose current text is a pointer (:90).
- [Pass] Registration is one Skills Index row in the documented tier (`skills/README.md:13-24`, `ARCHITECTURE.md:75-105`). The viewer discovers files by glob and derives the count and name set (`mini/skills/skill-viewer/scripts/list_skills.py:83-84`; `test/gh589-skill-viewer.sh:17-25`). No additional pinned catalog registration was found in that contract. Docs routing follows `utils/ci-route.sh:63-69,333-344,459-477` for the planned paths. Gate and viewer suite execution [Unverified — needs clone run].
- [Should] Make A1–A6 distinguish the candidate from the base and make each control test its intended claim. **Observed input:** Plan :97-102 uses path absence for A1/A2, a negative-only scan for A3, and no registry change for A6. An empty diff satisfies A6 verbatim and can yield an empty A3 scan. A4’s index row and A5’s entry-point load discriminate against base, but the existing A4 suites alone can pass there. The current seeded tree probe `python3 -c 'from pathlib import Path; print(Path("skills/2-daily/yesterday-today/SKILL.md").is_file()); print("[yesterday-today](" in Path("ARCHITECTURE.md").read_text())'` returned exit 0 and two lines of output, `False` and `False` (exact base revision not independently inspected in this turn). **Affected scope:** acceptance on an unchanged checkout, a stub skill, or an empty scan. Use the exact file path and check readable, nonempty content, frontmatter and triggers in A1. For A2, run the nine-point checklist and show it rejecting one omitted requirement. For A3, choose one command, scan explicitly named, nonempty deliverables, inspect for generic content, and show a harmless synthetic forbidden string is detected. A4 should require the exact linked row, A5 should fail if the consumer skill cannot load, and A6 should be an invariant on the nonempty candidate diff, with a forbidden path example that the check rejects if a red observation is required. **Falsifier:** unchanged base fails the delivery assertions at the entry point and index; a stub or omitted lesson fails the relevant content check; the synthetic private marker and forbidden path each fail their respective control without adding a test suite.
- [Should] Close the delivery and evidence loop in the plan. **Observed input:** Plan :34,91-106 ends at the smoke and existing checks. [GH-1601 §3](https://github.com/HiQS-Labs/XYZ-forge/issues/1601) requires final relay QA and a PR against `development`. `AGENTS.md:123-124,166-170,268-273` requires committed `provenance.jsonl` and independent QA evidence. **Affected scope:** implementation handoff and pre-PR verification. Name the provenance file alongside the smoke receipt and add final relay QA on the implemented artifact and evidence before the PR. **Falsifier:** delivery criteria identify the provenance file, required final QA receipt, and `development` target.
- [Nit] Align the Status table's unconditional “changelog” (:34) with the conditional entry in Plan :92.

Swept the entire seeded plan. Its pre-existing issues are included above. The nearest graph index was the main Forge checkout (generation 2026-11-23T23:18:20Z), not this isolated worktree, so the findings use direct worktree source. No configured reviewer phase gate appears in Setup, and no suites or live ledger smoke were run this turn.

VERDICT: FAIL

Basis: The plan needs explicit read-only discovery and write guards, discriminating acceptance checks, and the final QA and provenance requirements. Handing off to Producer to revise the plan and return it for review.

### Producer · Round 1

Dispositions (each verified against the source before acting; `planner_core.py:3299,3325-3331` and `:2283-2300` read firsthand):

- [Pass] Recon shorthand: **Implemented.** Recon now says daily-planner's review step covers the operator's own PRs and requests, and that its engine writes `temp/planner/*` without `--publish-ledger`.
- [Should] Read-only discovery and A5: **Implemented.** The skill reuses daily-planner's conventions (title pattern, timezone, lowest-number duplicate rule) with plain read-only `gh` and does not run the engine; step 1 distinguishes confirmed-absent from lookup-failed; A5 records dates, checkbox count, stop text, read commands and a zero-write check.
- [Should] Two branches of the pre-edit check and validator handoff: **Implemented** (Plan step 7 changed-body and failed-read branches; step 8 validator fetches the published body after a confirmed write).
- [Should] Preserve the full brief: **Implemented** (requested reviewers kept separate from past reviews; goal header and estimate rule explicit; deployed needs linked evidence else "deployment unverified"; no server reads, reported "not checked"; trial merge only in a throwaway local clone; relay-xyz is for this PR's QA, the skill's validator is the Codex astra sub-agent).
- [Should] Discriminating A1-A6: **Implemented** with a red control per check (A2 omitted item, A3 planted string, A6 synthetic test path); A1 prints file/line count/frontmatter name; A4 pins the exact row.
- [Should] Delivery loop: **Implemented** (Plan steps 4-5, new A7: final QA receipt, `provenance.jsonl`, base `development`).
- [Nit] Status table: **Implemented.**

Handing off to Reviewer for round 2.

### Reviewer · Round 2

swept file: yes

**What this proposes.** Add a short prompt-only skill that finds today’s and the previous workday’s GitHub ledgers, checks yesterday’s work and feedback, and uses that evidence to update today’s body. The update preserves the goal and completion estimate, checks for intervening edits before publishing, and gets one independent review of the published body.

**How the existing system works, per this document.** Daily Planner discovers date-stamped ledger issues and records a single operator’s work in claim comments. Its engine also writes local planner output, so the proposed workflow borrows the discovery conventions and performs the lookups itself with read-only GitHub commands.

**What it's not.** The frontmatter excludes helper code, changes to Daily Planner, unattended creation of a missing ledger, server writes, and installation.

**Input boundary.** Plan frontmatter `non_goals` and `goal`, and Status, Requirements, Recon, Preflight bet, Plan, Acceptance, Verification, and Risks. This paraphrase was drafted before opening the issue or implementation source this round.

**Step B — source-backed**

Plan line citations refer to `.relay-artifacts/GH-1601-YESTERDAY-TODAY-SKILL.md`.

- [Pass] The new skill fits the documented unit of work. Daily Planner discovers ledger titles, verifies claim-comment authorship, and checks the operator's own PRs and review requests (`skills/2-daily/daily-planner/SKILL.md:151-155,167-175`). Its publishing branch calls `sync_daily_ledger_comment` (`skills/3-weekly/weekly-planner/scripts/planner_core.py:3128-3144`), and the CLI writes JSON and Markdown even without publishing (:3299,3325-3331). Plan :64,81 correctly reuses title, timezone and canonical-issue conventions without calling the engine. The alternatives work at a different scope: local telemetry (`skills/2-daily/daily-planner/SKILL.md:132`), topic assessment (`skills/2-daily/where-are-we-at/SKILL.md:14-25,42`), a shared weekly planning engine (`skills/3-weekly/weekly-planner/SKILL.md:49-50`), and per-issue closeout comments (`skills/2-daily/todo-list/SKILL.md:166-187`). Plan :64-76 satisfies the existing-skill check in `skills/README.md:25-28`. The prompt-only design is proportionate.
- [Should] Save the body used to draft the update before drafting. **Observed input:** Plan :88 starts by rewriting today's body and only then introduces “save the old body to a file.” Its equality branch permits the edit without tying the saved body to the draft's input, contrary to the no-blind-overwrite requirement at Plan :40. If the draft is based on body `A`, and the snapshot and pre-edit read both see `A + teammate update`, the specified equality check passes while the draft still omits the update. **Affected scope:** today's body changes after it was read for drafting and before the saved snapshot. Make the initial successful body read both the saved baseline and the source of the draft. On rebase, use the newly read body as both, then repeat the comparison. **Falsifier:** given draft source `A` and a later read of `A + teammate update`, the instructions allow only a rebased draft preserving the update or a stop. The explicit failed-read and changed-body branches and the published-body validator at Plan :88-89 resolve the other parts of the first-round finding.
- [Should] Make an unresolved prior ledger a stop before drafting. **Observed input:** Plan :82 distinguishes failed or incomplete lookups and explicitly stops on absent **today** only. Plan :83 immediately requires reading yesterday's confirmed ledger, and Plan :22-25,84 requires its claims as input. For a resolved prior date of Tuesday with only Monday and Wednesday ledgers present, step 2 has no Tuesday issue to read, yet Tuesday's absence has no explicit stop. **Affected scope:** the resolved prior workday is missing, or either ledger lookup is unavailable. Stop without rewriting today's body when either required input is unavailable, and report the precise failed or missing lookup. Use the offer to create only for confirmed absence of today's ledger. **Falsifier:** a successful lookup finds an older ledger and today's ledger but no ledger for the resolved prior workday. The skill reports that gap without treating yesterday as empty or silently using the older issue.
- [Pass] The other operational lessons are reflected in the steps. Plan :84-87 covers checkbox claims, head-aware reviews, linked deployment evidence, no server access, full feedback, Slack disclosure, outstanding review requests, local trial sequencing, and the plan-versus-approval boundary. Plan :88-90 preserves the goal and estimate components, requires the low-effort read-only Codex `gpt-6.2-astra` validator to fetch the published issue using the two URLs and checklist, and spells out all traps and the four final-reply fields. Plan :93-94,106 adds provenance, final relay QA and the `development` PR base from [GH-1601 §3](https://github.com/HiQS-Labs/XYZ-forge/issues/1601). The stale unconditional changelog reference in the status table is gone (Plan :34,92).
- [Pass] The required registration is one row with a purpose in the `2-daily` index (`skills/README.md:13,17-24`, `ARCHITECTURE.md:75-84`). The viewer globs the skill tree and compares its count and names to disk (`mini/skills/skill-viewer/scripts/list_skills.py:83-84`, `test/gh589-skill-viewer.sh:17-25`). The proposed skill path is a docs surface (`utils/ci-route.sh:63-69,333-344,459-477`).
- [Pass] A1 now requires a usable entry file with metadata and triggers. A2 tests content by mapping all nine requirements and removing one for the red control. A3 requires nonempty inputs and a planted-string control. A4's linked entry distinguishes the candidate from base independently of the existing suites. A5 exercises the loaded skill's steps 1–2 on a real pair, plus the missing-today stop and failed-lookup distinction. A6 requires a nonempty diff and rejects a planted test path. These are materially better than presence-only and empty-input checks (Plan :98-105). A1, A2 and A5 need the new skill, A3 needs the named candidate deliverables, A4 needs the new row, and A6 needs the candidate diff. These are plan checks. Smoke and suite execution remain [Unverified — needs clone run].
- [Should] Align the A6 allowlist with the plan's changelog mode. **Observed input:** Plan :92 allows a `CHANGELOG.md` write when branch mode calls for it, and `PROJECT/PDDA.md:1064-1067` requires that write in `CHANGELOG_WRITES=branch`. Plan :105 excludes that path unconditionally. **Affected scope:** a candidate prepared with branch mode enabled. Admit the file only when the existing branch-write condition applies, or state that this plan uses the default and omits the branch-mode case. **Falsifier:** for a branch-mode candidate with the required entry, the same A6 check accepts the documented delivery paths and still rejects `test/new-suite.sh`.
- [Nit] Call the quoted A4 string the first cell of the required row and require a nonempty purpose cell. Plan :103 calls the cell the “exact row,” while `ARCHITECTURE.md:79-84` has two columns. Narrow probe `python3 -c 'from pathlib import Path; a=Path("ARCHITECTURE.md").read_text().splitlines(); prefix="| [daily-planner](skills/2-daily/daily-planner/SKILL.md) |"; print("existing row as full line:", prefix in a); print("existing row as prefix:", any(line.startswith(prefix) for line in a)); print("seeded skill exists:", Path("skills/2-daily/yesterday-today/SKILL.md").is_file()); print("seeded index contains link:", any("[yesterday-today](skills/2-daily/yesterday-today/SKILL.md)" in line for line in a))'` → exit 0, `existing row as full line: False`, `existing row as prefix: True`, `seeded skill exists: False`, `seeded index contains link: False`. The named base commit was not independently queried.
- [Nit] In the preflight summary at Plan :75, name Codex for the ledger validator and leave relay-xyz with implementation QA as specified at :67,89,94.

The entire seeded plan was swept, including existing sections. The findings above include the remaining defects found in that sweep. The closest graph was the main Forge checkout (generation 2026-11-23T23:18:20Z). The seeded plan and relay were absent from that index, so the citations and decisions use direct worktree reads. Setup names no reviewer phase gate.

VERDICT: FAIL

Basis: The plan needs to bind the publish guard to the draft's actual input, stop on an unresolved prior ledger, and reconcile the changelog rule with A6. Handing off to Producer to revise the plan and return it for round 3.

### Producer · Round 2

- [Should] Saved baseline must be the draft's source: **Implemented.** Plan step 7: the first successful read is both baseline file and draft source; on a changed live body the new read becomes both and the draft is redone.
- [Should] Unresolved prior ledger is a stop: **Implemented.** Plan step 1 stops before drafting when the resolved previous-workday ledger is absent or either lookup is unavailable; no silent use of an older issue.
- [Should] A6 vs changelog mode: **Implemented.** `CHANGELOG.md` admitted only under `CHANGELOG_WRITES=branch`; this plan runs under the default.
- [Nit] A4 first-cell wording and nonempty purpose cell: **Implemented.**
- [Nit] Preflight naming of the validator: **Implemented** in Recon (relay-xyz is for this change's QA only; the skill's validator is the Codex sub-agent).

Handing off to Reviewer for round 3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
