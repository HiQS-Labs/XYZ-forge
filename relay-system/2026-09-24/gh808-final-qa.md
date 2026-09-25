# RELAY · GH-808 final QA: gh251 nested-run scope-down
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
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
6. **Commit only the relay file** (`relay(gh808-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh808.diff** — the read-only path that
  `relay-drive.sh --artifact-file /tmp/gh808-evidence/gh808.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-24
- Definition of Done: issue #808's acceptance — gh251's nested `validate.sh --paths-file` runs
  select a tier-2 lane that still sets `T2_PYTEST=1`, with (a) every existing assertion preserved
  verbatim (6 pass lines unchanged), (b) suite duration ≤ 120 s standalone (target met: 67.5 s vs
  1050.6 s before, −93.6%), (c) a witnessed red control (mutating the SKIPPED message in
  validate.sh fails the suite; restore returns green), (d) matched before/after evidence +
  provenance committed (`TESTS-RESULTS/2026-09-24+GH-808/`), (e) no containment or policy change,
  no `validate.sh` edit.

### Context and questions (grade against THESE, not against speculative hardening)

Operational envelope: a developer-tooling repo's own test suite, macOS-first, single-repo. The
change under review is deliberately minimal (one test file, 5 added lines). Commensurate
complexity applies: do not demand enterprise machinery, new runners, or speculative abstractions.
Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/808. Plan + evidence:
`PROJECT/2-WORKING/GH-808-GH251-GATE-COST.md` and `TESTS-RESULTS/2026-09-24+GH-808/SUMMARY.md`
in the worktree (the diff also carries them). The worktree is a checkout of the task branch; you
may read any repo path read-only.

1. Correctness of the retarget: does `skills/3-weekly/skills-army-hq/scripts/sync.py` (a real,
   tracked `.py` path) classify tier 2 and set `T2_PYTEST=1` per `utils/ci-route.sh:35-47` and
   `validate.sh`'s paths-file handling (~`:908/:928/:937`)? Is the comment's claim about why the
   path was chosen accurate?
2. Coverage preservation: are all six assertions in `test/gh251-validate-pytest-skip.sh`
   functionally unchanged by the retarget (i.e., none of them secretly depended on the releases
   lane or on `releases_app.py` specifically)?
3. Coupling risk: does pointing the paths-file at the skills-army-hq lane create a spurious
   failure mode if that lane's routing or the sync.py path moves? Is that risk acceptable /
   documented for a test whose subject is the pytest lane?
4. Evidence integrity: does `TESTS-RESULTS/2026-09-24+GH-808/` (SUMMARY, provenance.jsonl, logs)
   substantiate the before/after and red-control claims, with matched invocation shapes and
   pinned commits (GH-430)?
5. Scope hygiene: anything in the diff beyond the fix + intake/evidence (unrelated files,
   accidental edits, ledger drift)? The releases.sql change is the documented GH-808 intake row
   (park/rate/repoint/update) merged over upstream — is it clean?
6. GH-268 sweep: you are touching `test/gh251-validate-pytest-skip.sh` — pre-existing defects in
   that file are in scope; declare `swept file: yes/no`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
