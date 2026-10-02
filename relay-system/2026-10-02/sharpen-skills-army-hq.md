# RELAY · Sharpen Skills Army HQ Skill
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(sharpen-skills-army-hq-skill): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/3-weekly/skills-army-hq/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Definition of Done: Thoroughly audit `skills/3-weekly/skills-army-hq/SKILL.md` (and its supporting scripts/references) against operational ground truth.
  1. Identify any high-confidence gaps, failure modes, or ambiguities in:
     - Intake & Sync CLI flag documentation (e.g. `--allow-drift`, `--root`, `--canonical`).
     - Safe error handling and recovery procedures (interrupted writes, stale locks).
     - Upstream drift detection vs working tree branches.
     - Cross-IDE target discovery contracts and symlink verification.
  2. ONLY propose sharpenings that have a HIGH confidence level and represent a MEANINGFUL operational improvement. Do not recommend cosmetic rewrites or ceremony.
  3. If no high-confidence meaningful gaps exist, output VERDICT: PASS with Basis: "Skill is already sharp and functionally complete; no meaningful changes warranted."

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes
VERDICT: FAIL
Basis: Two high-confidence operational clarifications are warranted in the drift guidance. Both are documentation changes; no new runtime mechanism or gate is requested.

- [Should] **R1 — distinguish working-tree equality from upstream freshness before re-vendoring.** `.relay-artifacts/SKILL.md:164` says “Remedy is always the same” and immediately prescribes replacing the payload from the selected Forge path. The checker only hashes local files; it cannot determine whether that checkout is older, newer, on the intended branch, or locally modified. A difference does not establish which copy should replace the other. Clarify that `ok` means matching local `SKILL.md` content (with CRLF normalization), not current upstream; inspect the selected checkout/version and preserve differing improvements before following the update remedy. Do not prescribe automatic branch switching or discarding changes.
  Observed input: `utils/py/skill_drift_check.py:31` reads `path.read_bytes()`, and lines 39–53 classify solely by those digests; `skills/3-weekly/skills-army-hq/scripts/sync.py:45` accepts the selected path after checking only the checker file and `skills/` directory. These are the concrete implementation inputs behind the unconditional remedy at artifact lines 164–165.
  Affected scope: Drift interpretation and remediation when the selected canonical checkout's working-tree version has not been established as the intended source version.
  Falsifier: In a disposable clone, compare a newer vendored skill with an older local canonical checkout. Expected current behavior: `DRIFTED`, with no upstream freshness/direction determination. A checker that instead establishes the intended upstream revision and distinguishes this case would invalidate the rationale.

- [Should] **R2 — state that sync refusal cannot prevent or undo an already-linked payload update.** The heading at `.relay-artifacts/SKILL.md:147` implies a deployment barrier, while workflow line 97 applies intake before sync. The existing Pulse warning at lines 68–69 correctly describes immediate read-through but does not cover intake updates. Add a short boundary statement: updating a linked collection payload also changes what apps can read immediately; sync's drift refusal governs reconciliation, not intake writes or rollback. Review the intended source/version before applying an update to a live collection; do not rely on a subsequent sync refusal to hold it back.
  Observed input: `skills/3-weekly/skills-army-hq/scripts/intake.py:722` stages an applied update, and `action_apply` at lines 435–439 renames the old payload out and the new payload into the same destination; the drift refusal is separately in `scripts/sync.py:86`. Artifact line 97 explicitly orders intake before sync.
  Affected scope: Updates to collection folders that existing app symlinks already reference. New unlinked payloads do not have this immediate read-through effect.
  Falsifier: In a disposable clone, update a skill with an existing app symlink, then run a refusing drift sync. Expected current behavior: the app link already reads the updated payload before sync and still does afterward. If intake holds the new payload out of the linked destination until successful sync, this clarification would be unnecessary.

- [Pass] CLI placement/precedence, recovery and ownership guidance are materially covered: artifact lines 106 and 128–134 describe intake globals and root selection; `scripts/intake.py:623` onward implements the parser and `default_root` at line 580 supplies the environment/default selection. `references/recovery.md` explicitly says “A dead process releases its lock; a live holder is never displaced” and supplies pending-receipt recovery and source-bundle fallback. `references/targets.md` says “a filesystem link and readable SKILL.md do not prove a running app has refreshed its skill inventory.” Keep these contracts; no additional meaningful changes identified in the remaining whole-file sweep.
- [Unverified — needs clone run] Runtime crash recovery, concurrent locking, mutation replay and actual installed-app discovery were not exercised. No tests, executable fixtures, or Git commands were run. Findings R1/R2 are source-grounded documentation findings, not claims of reproduced runtime failure. Source inspection command: `nl -ba utils/py/skill_drift_check.py | sed -n '26,65p'` (exit 0), decisive output: `return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()`; `nl -ba skills/3-weekly/skills-army-hq/scripts/intake.py | sed -n '415,442p'` (exit 0), decisive output: `dest.rename(old)` then `new.rename(dest)`. Read the entire seeded skill, both references, README and both supporting scripts. Graph lookup used project `XYZ-forge`, generation `2026-09-01T15:54:30Z`; coverage returned `not_tracked` for the reviewed paths, so direct current-worktree source reads supplied the evidence instead of stale graph results.

Handing off to Producer (claude-a) to disposition R1 and R2 and revise only the operational guidance warranted by the evidence.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
