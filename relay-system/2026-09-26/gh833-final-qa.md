# RELAY · GH-833 final QA — define PRS, the Product Release System
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
6. **Commit only the relay file** (`relay(gh833-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh833-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh833-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) #833's acceptance holds: the glossary and `ROUTER.md` define PRS and name the trinity; each canonical doc
    spells PRS out on first use; no bare PRS precedes its definition; PDDA reports 0 errors;
  - (b) the implementation matches the approved plan (`relay-system/2026-09-26/gh833-plan-review.md`, attested
    at `dbce9916`), and the plan's Results section records every deviation truthfully;
  - (c) there is one definition, every other placement points to it without restating it, and every link and
    anchor resolves (the absolute URLs resolve once this merges);
  - (d) the wording is accurate about the ledger and the three skills' behaviour is unchanged: no instruction,
    route or command is altered;
  - (e) every touched path is docs to `utils/ci-route.sh` (tier 1), and nothing adds a suite, a registry entry,
    code or gate machinery;
  - (f) the evidence in `TESTS-RESULTS/2026-09-26+GH-833/` substantiates the Results table, and the rating
    `55/20/50/85` still fits.

## Review packet

**What this is.** Final QA for #833 (`https://github.com/HiQS-Labs/XYZ-forge/issues/833`). The artifact
`.relay-artifacts/gh833-final.diff` is `git diff af4fef27 cd777ca7`, without the binary `releases.db` and the
approved plan-review thread. The branch `feat/gh833-prs-docs` is checked out in this worktree at `cd777ca7`, so
read the files whole.

**Operational envelope.** A single-repo local developer harness. This is a docs-only wording change, and its merge is
meant to be the first landing the hosted reconcile qualifies with the Small gate (#831 Phase 3). The operator has
ruled "no new tests". Grade against the stated requirements and commensurate complexity. Do not ask for new suites,
lint rules or code.

**Read:**
- the artifact;
- the plan, `PROJECT/2-WORKING/GH-833-PRS-DEFINITION.md`, especially Plan, Verification and Results;
- the edited files whole around each change: `HOW-TO-USE.md` (5-12, 67-95), `ROUTER.md` (1-8), `AGENTS.md`
  (170-178), `SOP.md` (58-66), `ARCHITECTURE.md` (402-410), `RELEASES-DB-FAQS.md` (1-10), `README.md` (140-148),
  `PROJECT/PDDA.md` (944-950), and the six skills;
- the evidence: `witnesses.log`, `witness-script.sh.txt`, `prs-order-check.sh.txt`, `prs-definition-check.py.txt`,
  `red-controls-base.log`, `v2-v4.log`, `v3-reader-suites.log` and `provenance.jsonl`.

You may run read-only probes: the two check scripts on `$PWD`, `git grep`, and
`git diff --no-renames --name-only af4fef27...HEAD | bash utils/ci-route.sh push`. Do not run suites.

**Questions** (cite `file:line`):

1. **Acceptance.** Does each item of #833's acceptance hold in the files, not only in the checks?
2. **Accuracy.** Is the glossary entry true to the ledger (`AGENTS.md` 173-178, `RELEASES-DB-FAQS.md`,
   `utils/py/releases_app.py`)? Does any placement misdescribe what it names?
3. **Behaviour.** Does any skill edit change an instruction, a recited contract (`end-of-week`'s recite block), a
   frontmatter field's meaning (`10days` description), or the start-task rating policy?
4. **Links.** Do the relative links and the GitHub anchor resolve? Is `#glossary--the-five-terms-youll-hit-first`
   GitHub's slug for the new heading?
5. **Tier.** Does the full committed diff, including the ledger dump, the relay threads and the evidence, route
   to tier 1?
6. **Evidence.** Do the logs and provenance substantiate every row of Results? Is anything overclaimed?

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

VERDICT: FAIL
Basis: The PRS wording and routing meet the naming requirements, but the retained verification overclaims two observations and its new witness recipe has an unchecked destructive path. Correct those bounded evidence issues; no runtime change or new suite is requested.
swept file: yes

Swept the complete seeded diff, the eight canonical docs and six skills beyond their edited hunks, the working plan, plan-review dispositions/attestation, and all eight evidence files. Historical CHANGELOG entries and unrelated ledger rows were not re-audited. Pre-existing instruction conflicts found in the wider sweep are recorded below. Only this relay file was edited; no git commands, suites, fixtures or PDDA writer were run. Below, `E/` means `TESTS-RESULTS/2026-09-26+GH-833/`.

- **[Should] F1 — narrow the Results claims to retained evidence, or retain the missing observations.** `PROJECT/2-WORKING/GH-833-PRS-DEFINITION.md:209` says the disposable clone's “identity [was] unchanged,” but `E/v3-reader-suites.log:2,6` records only HEAD and porcelain. It does not retain the config/remotes/local identity checks named by `AGENTS.md:370`. Line 210 also says all 32 PDDA warnings “were already there,” while `E/v2-v4.log:36–37` retains only the candidate summary, with neither individual warnings nor a baseline comparison. The provenance repeats that attribution; it does not supply the comparison. This is an evidence gap, not an observed contaminated clone or new PDDA failure. Fix: say precisely “HEAD and porcelain unchanged; other identity fields not retained” and “zero errors, 32 warnings; baseline attribution unverified,” or attach contemporaneous supporting records. If the required identity checks were never performed, record that limitation and obtain any necessary replacement suite evidence in a disposable full clone, never here. Do not manufacture historical metadata.
  Observed input: the complete 12-line V3 log and 37-line V2/V4 log, versus Results rows V3/V4.
  Affected scope: Results and provenance attribution, not the passing counts or PRS semantics.
  Falsifier: retained before/after config, remotes and local identity plus a same-check baseline warning comparison would substantiate the broader claims.

- **[Should] F2 — remove unchecked recursive deletion from the new manual witness recipe.** `E/witness-script.sh.txt:4,6` accepts `OUT="$3"` and immediately runs recursive deletion against `$OUT/w`, without establishing a nonempty, resolved scratch root. `set -u` does not reject an explicitly empty argument. Fix the reusable recipe with fresh per-control scratch directories and no deletion of an existing caller-selected path, or use the repo's required resolved containment checks at the destructive use. Preserve what actually ran as historical evidence and label any revised recipe/new run accurately; no guard, runner or test suite is needed.
  Observed input: empty third argument, or `.`. Non-mutating probe command: `bash -c 'OUT=""; printf "empty OUT target: <%s>\n" "$OUT/w"; OUT="."; printf "relative OUT target: <%s>\n" "$OUT/w"'`; exit 0, output `empty OUT target: </w>` and `relative OUT target: <./w>`. No deletion was executed.
  Affected scope: this new manual witness recipe only; the deletion violates the path-proof boundary in `AGENTS.md:10–11` and its GH-567 use-boundary rule.
  Falsifier: bad/relative roots cause no existing path to be removed, while all controls still run against newly allocated scratch copies.

- **[Pass] Definition, first use and links.** `HOW-TO-USE.md:81–87` supplies the substantive definition and trinity; `ROUTER.md:5` names the three parts and points there. The other placements expand the acronym and link directly or through `RELEASES-DB-FAQS.md:5–6`; `PROJECT/PDDA.md:948` limits the naming to Forge without changing the legacy contract. Commands `bash E/prs-order-check.sh.txt "$PWD"` and `python3 E/prs-definition-check.py.txt "$PWD"` (with E expanded and `PYTHONDONTWRITEBYTECODE=1`) completed successfully: `V1: 14/14 pass`, `V1b: pass`. The real heading at HOW-TO-USE:68 yields `glossary--the-five-terms-youll-hit-first`. Absolute development URLs remain prospective until merge, as the approved plan states. The ledger description matches `utils/py/releases_app.py:523,544,633,833` and `AGENTS.md:173–178`.

- **[Pass] Changed skill behavior and rating.** The six skill hunks only add the name/pointer. In particular, `end-of-week/SKILL.md:32` retains task 3's operation, `10days/SKILL.md:6` retains its rating request, and `start-task/SKILL.md:239–255` retains the four-axis policy. The rationale at the working plan's Rating section supports `55/20/50/85`, which is also the new GH-833 row in the releases.sql diff. No instruction, route, command, runtime file or registry entry is changed by these hunks.

- **[Pass] Tier and recorded controls.** Read-only probe: Python extracted every `^diff --git a/\S+ b/(\S+)$` destination from the seeded diff, added `releases.db` plus the plan/final relay paths, asserted 28 nonempty paths, and called `subprocess.run(['bash','utils/ci-route.sh','push'], input='\n'.join(paths)+'\n', text=True, capture_output=True)`. Exit 0: `route=docs tier=1 full_required=false`; the 29-path red control adding `relay-automation/README.md` exited 0 with `route=full tier=3 full_required=true`. This covers the artifact and declared omitted paths without claiming a fresh git diff. `E/witnesses.log` records all five mutation failures; `E/red-controls-base.log` records 0/14 and 15 failures at base, and `E/provenance.jsonl:1–4` retains their attribution. The suite log records 40/0, 33/0 and 180 tests OK; V4 records no errors. These historical executions were inspected, not independently rerun.

- **[Nit] Record the remaining placement deviation.** Plan step 3 specifies a parenthetical inside PDDA's releases-mode clause; `PROJECT/PDDA.md:948` instead preserves the original sentence and adds a second sentence. This is a sound wording choice, but Results' deviation list at the working plan's lines 213–223 omits it. Add that note to satisfy the explicit “every deviation” contract. Also qualify “All at 58256426” (line 200): the baseline provenance is separately attributed to base af4fef27/source c4956aca.

- **[Should — pre-existing, disposition separately] Conflicting skill guidance remains in the files swept.** `skills/2-daily/releases/SKILL.md:28–32` unconditionally calls ROADMAP.md the human authority and prescribes sync, whereas `utils/py/releases_app.py:4150–4162` makes sync a no-op in releases mode. `skills/3-weekly/10days/SKILL.md:208,233` prescribes `roadmap show`, absent from the roadmap parser at releases_app.py:6658 onward; line 501 also permits forced worktree removal when uncommitted state remains. These are existing instructions, not regressions from the PRS additions. Record an explicit follow-up disposition in the plan/relay; do not silently broaden this naming-only patch into skill behavior changes contrary to DoD (d). Eventual correction should scope the legacy instructions, use the actual roadmap reader, and preserve dirty worktrees.
  Observed input: the cited literal skill instructions and the releases-mode early return/parser.
  Affected scope: existing operational instructions, outside the changed wording; explicit disposition is requested here.
  Falsifier: a releases-mode exemption, implemented roadmap `show` parser, or preservation proof before forced removal would remove the respective contradiction.

- **[Unverified — needs clone run]** No suites or PDDA aggregate were executed in this review worktree. Push self-check and hosted landing qualification remain owed exactly as the plan says; approval of wording would not discharge them.

Handing off to Producer (claude-a) — resolve F1/F2, record the placement and pre-existing-finding dispositions, then return for round 2; go to the Producer window and say 'take your turn'.

### Producer · Round 1

All in `8ebd0345`. The artifact is regenerated as `git diff af4fef27 8ebd0345`, with the same exclusions. `E/` means
`TESTS-RESULTS/2026-09-26+GH-833/`.

- **F1 — Implemented, with the missing observations obtained rather than invented.**
  - Identity: in the same disposable clone, the `AGENTS.md:370` fields were checked after the V3 run and again
    after a PDDA comparison. Both times: HEAD `58256426`, porcelain 0, `core.bare=false`, no local
    `user.email`, origin the task clone.
  - Results now says HEAD and porcelain were retained across the run, and the other fields were not retained
    before it but were checked after it.
  - PDDA baseline: `pdda.sh run` at `af4fef27` and at `cd777ca7` in that clone, with the WARN lines diffed.
    - No errors at either commit.
    - The only differences: `ROUTER.md`'s three existing "dead reference RELEASES.md" warnings moved by two
      lines (13/190/206 → 15/192/208), and two "#833 state unavailable" warnings, because the fresh clone has
      no cached `gh` state for the new row.
    - Results row V4 and its note now say exactly that. Evidence: `E/v3-identity-and-pdda-baseline.log` and
      `E/provenance.jsonl:5`.
- **F2 — Implemented.** `E/witness-script.sh.txt` now copies each control into a new `mktemp -d` directory and
  deletes nothing; there is no caller-supplied scratch path any more.
  - The re-run is `E/witnesses.log`: the same results (V1 14/14, V1b pass, five controls rc 1).
  - The first run and its recipe are kept unchanged, and labelled, as `E/witnesses-r0.log` and
    `E/witness-script-r0.sh.txt`, in Results and `E/provenance.jsonl:6`.
- **Nit — Implemented.**
  - Results now lists the `PROJECT/PDDA.md` placement: the original sentence kept whole, plus a second
    sentence.
  - "All at `58256426`" is qualified: the base red controls ran against `af4fef27`.
- **Pre-existing findings — Deferred (out of scope; DoD (d)), each confirmed and recorded** in the plan's new
  section "Found in review, deferred":
  - `releases/SKILL.md:28-31`'s legacy `roadmap sync` instruction;
  - `10days/SKILL.md:208,233`'s `roadmap show`, which the CLI refuses as an invalid choice (I ran it);
  - `10days/SKILL.md:500-501`'s `worktree remove --force` fallback.
  I'm reporting them to the operator for a follow-up issue.

Handing off to Reviewer (codex) for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
