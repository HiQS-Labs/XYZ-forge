# RELAY · GH-1157 final QA: skills-army-hq hard rules (implemented diff + evidence)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1157-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation on this branch — the diff from base
  `9a61625fa7af15e7dd2b12c06a89242ed689b088` to `HEAD`. The only runtime change is
  `skills/3-weekly/skills-army-hq/SKILL.md` (commit `4bf3361b`). Supporting artifacts in the same
  range: `PROJECT/2-WORKING/GH-1157-SKILLS-ARMY-HARD-RULES.md` (the approved plan, promoted),
  `TESTS-RESULTS/2026-10-18+GH-1157/` (evidence + `provenance.jsonl`),
  `relay-system/2026-10-18/gh1157-plan-qa.md` (plan QA, Approved r2), `releases.db`/`releases.sql`
  (ledger row for GH-1157 only).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: the diff implements the plan's **Asks / acceptance criteria** items 1–8 and
  nothing else in the runtime surface; every factual claim the new prose makes about
  `scripts/intake.py` / `scripts/sync.py` is true at this revision; `name: skills-army-hq` is intact;
  the evidence folder's logs support exactly the claims `SUMMARY.md` makes and `provenance.jsonl`
  covers every artifact with a matching sha256; no new test, suite, registry entry or gate
  machinery (GH-831); no contradiction with the untouched sections of `SKILL.md`.

## Review packet

**Goal.** Final QA of the completed GH-1157 change before the PR is opened against `development`.
Pre-implementation plan QA already Approved the design (round 2, attested); this review grades the
*implementation* and its *evidence* against that plan.

**Operational envelope.** A documentation-only change to one `SKILL.md` of a local developer
toolkit, plus governance/evidence artifacts. Commensurate complexity: do not ask for scripts, hooks,
device configuration or tests; a request for a new test is a finding against the request (GH-831).

**Non-goals (decided, out of scope).** Script changes, Git Pulse Sync hook, device config, publisher
policy (#961), status exit-code semantics (#958), downstream child publication, any device repair.

**Read.** `git diff 9a61625f..HEAD --stat` and the full diff of `skills/3-weekly/skills-army-hq/SKILL.md`;
the plan doc's "Asks / acceptance criteria" (items 1–8); `TESTS-RESULTS/2026-10-18+GH-1157/*`;
the scripts the prose describes.

**Questions — answer each with a grade and a citation:**

1. **Asks → diff.** Map each of the plan's items 1–8 to the diff. Is any item missing, partially
   done, or implemented differently from the approved wording? Is anything in the runtime surface
   outside those items?
2. **Truth of the new prose.** Spot-check the load-bearing claims in the new "Hard rules" and
   "Definition of done": (a) intake applies with no drift gate and app links expose bytes at once;
   (b) status never compares receipt digests with deployed bytes and exit 0 can carry warnings;
   (c) a symlinked root is refused; (d) there is no supported stale-receipt refresh; (e) the
   corrected unrelated-changes sentence (applies, then declines the commit with `WARN not committed`,
   exit 0). Cite `file:line` for each or name the one that is false.
3. **Identity.** Is `name: skills-army-hq` intact and the frontmatter still valid YAML for the
   reader (`package_info`), so the existence/identity/copy-parity checks named in the plan stay
   compatible?
4. **Evidence honesty.** Do `parse-positive.log` (exit 0, 0 `__pycache__`), `parse-red-control.log`
   (exit 1, refusal), `pdda-run.log` (no errors) and `releases-check.log` (clean) say what
   `SUMMARY.md` says they say? Does `provenance.jsonl` have one line per other artifact with a
   sha256 that matches the file bytes at HEAD, and the stated base/candidate SHAs?
5. **GH-831.** Is there any new test file, `validate.sh` TESTS entry, runner, guard or gate
   machinery in the diff? (Expected: none.)
6. **Contradictions / sweep.** Read the whole `SKILL.md` at HEAD (`swept file: yes|no`). Does the
   new block contradict any remaining sentence (GH-672 SOP, drift guard, read-through boundary,
   commands)? Any pre-existing defect still uncorrected that a reader of the new rules would trip on?
7. **PR readiness.** Is the branch ready to push through the docs-route gate and open as a PR
   against `development`, stopping there (no merge)? Name any blocker.

Write graded findings with `file:line` citations, declare `swept file: yes|no`, set a VERDICT and
Basis, and set `STATUS: Approved` if the implementation passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Ship for the docs-gated push and PR against development; no implementation blocker.

swept file: yes

- [Pass] **1 — Asks → implementation.** All eight approved items are present in `skills/3-weekly/skills-army-hq/SKILL.md`: item 1 at :14–44 (five rules); item 2 at :46–58 (four separate facets); item 3 at :60–62 (bytecode suppression); item 4 at :3–9 (routing-first description); item 5 at :16–20 and :96–103 (moved prohibition and pointer); item 6 at :184 (root example); item 7 at :245–249 (preserved read-through boundary); item 8 at :81–85 (apply first, commit warning afterward). Base-to-HEAD object comparison shows precisely those hunks, no other skill edits.
- [Pass] **2 — Truth of prose, by source inspection.** Intake stages/replaces payloads without invoking the sync drift gate (`scripts/intake.py:785–807,845–858`, `:481–507`); links target the stable collection path (`scripts/sync.py:250–252`), exposing replacement bytes immediately. Status inventories current digests but never compares them with skill receipt digests (`scripts/intake.py:289–302`; `scripts/sync.py:365–387`); warnings are independent of the errors-only return code (`scripts/sync.py:69–72,387`). Root/ancestor symlinks are refused (`scripts/intake.py:54–61`). Catalog uses `setdefault`, identical updates return `Unchanged`, and the parser exposes no selective receipt refresh (`scripts/intake.py:687–707,797–798,839–842`). Transaction precedes `commit_skill`; unrelated paths decline only the commit, print `WARN not committed`, and return 0 (`scripts/intake.py:466–471,845–858`). These are static findings, not claims of a fresh runtime suite run. Script paths here are relative to `skills/3-weekly/skills-army-hq/`.
- [Pass] **3 — Identity/reader compatibility.** Literal `name: skills-army-hq` remains at `SKILL.md:2`; folded description syntax is supported by `scripts/intake.py:98–144`. Read-only probe: `PYTHONDONTWRITEBYTECODE=1 python3 -B -` importing the current intake module and calling `package_info(Path("skills/3-weekly/skills-army-hq"))`; exit 0, decisive output: `PARSE: name=skills-army-hq; routing description accepted`. Existing existence/identity/copy checks require no changed expectations.
- [Pass] **4 — Evidence honesty and integrity.** `TESTS-RESULTS/2026-10-18+GH-1157/parse-positive.log:2–5` records name, description, exit 0 and zero bytecode directories; `parse-red-control.log:2–3` records the missing-name refusal and exit 1. `pdda-run.log:174–175` reports no errors, 34 warnings, exit 0; `releases-check.log:15–16` reports clean, 10 warnings, exit 0, as disclosed in `SUMMARY.md:9–12`. Hash probe: `PYTHONDONTWRITEBYTECODE=1 python3 -B -` loading each JSONL row, asserting the non-provenance artifact set is exactly covered once and `hashlib.sha256((folder / row["artifact"]).read_bytes()).hexdigest() == row["sha256"]`, plus exact base/candidate equality; exit 0, decisive output: `PROVENANCE: 5/5 artifacts covered; all sha256/base/candidate values match`. Revisions match `SUMMARY.md:14–17` and `provenance.jsonl:1–5`: base `9a61625fa7af15e7dd2b12c06a89242ed689b088`, candidate `4bf3361b7c07b6c846432c809de243110840ccfb`. The recorded logs do not independently prove warnings predated this branch, but their other-document locations and the measured change scope support that characterization.
- [Pass] **5 — GH-831 / scope.** Read-only `python3 -B -` probe decoded existing commit/tree objects and compared base to HEAD without invoking git; exit 0, decisive output: `HEAD c40b425a0d38cf841acdc0c421c215986d933dcd`, `CHANGED PATHS 12`, `WORKTREE SKILL equals HEAD blob`. Paths are the one skill markdown, plan, two relay files, six evidence files, and two ledger files. No new test, registry entry, executable, runner, guard or gate machinery. This agrees with the bounded surface in `PROJECT/2-WORKING/GH-1157-SKILLS-ARMY-HARD-RULES.md` under “Smallest affected surface, restated.”
- [Pass] **6 — Whole-file sweep.** Read all 263 lines of `SKILL.md`, including GH-672 SOP (:111–151), conversational authorization (:153–173), commands/configuration (:175–217), drift guard (:219–249) and dependencies (:251–263). No additional pre-existing defect or material contradiction found. “Editable configuration” (:212,228) describes configuration rather than authorizing hand edits against rule 1; dirty-source support (:205–206) describes script capability while rule 4 requires verified clean release inputs for this workflow. Warning exceptions at :197,243–244 remain subject to rule 2's explicit approval. The preserved read-through paragraph agrees with the elevated warning.
- [Pass] **7 — PR readiness.** Ready for the planned docs-route push gate and opening a PR against `development`, then stopping; no review blocker. This is review approval, not gate or merge attestation (`PROJECT/2-WORKING/GH-1157-SKILLS-ARMY-HARD-RULES.md`, Status / ordered implementation steps 6–7; `SUMMARY.md:26–28`).
- [Unverified — needs clone run] No `validate.sh`, `test/*.sh`, pytest or executable fixture was run here. Existing recorded docs/ledger outputs were inspected; any subsequent harness gate must attest its own final committed state.

VERDICT: PASS
Basis: The prose implements the approved bounded plan, load-bearing claims agree with inspected code, and retained evidence supports the stated documentation-level qualification. No artifact/source edits or git commands were performed during this review.

Relay closed (Approved), no further review turn needed. Producer claude-a owns the subsequent docs-gated push / PR step; stop before merge.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
