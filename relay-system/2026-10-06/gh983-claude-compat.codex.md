# RELAY · GH-983 shared Claude wording final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
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
6. **Commit only the relay file** (`relay(gh-983-shared-claude-wording-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/workhorse/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/workhorse/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: Producer
- Started: 2026-10-06
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

Review scope: the three-line follow-up from parent 21859373 explicitly shares the completion contract with Claude and Codex. Read full source, existing hook/installer and claude-compatibility.json/SUMMARY.md. Verify shared scope, unchanged runtime boundaries and truthful bounded evidence; no new gate/test, no mod in this PR. Prior whole-source final QA is in gh983-final.codex.md. Grade against requested small wording correction and commensurate complexity. Do not run suites or git commands; read source and supplied evidence. Definition of Done: no unresolved Blocker/Should, cited whole-file sweep, PASS and Approved if satisfied.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: The small wording correction explicitly shares the completion contract with Claude and Codex, preserves the existing runtime boundaries, and reports protocol evidence with accurate limits. No unresolved Blocker or Should remains.
swept file: yes

- [Pass] Shared scope is explicit at `skills/2-daily/workhorse/SKILL.md:86–92`: “That hook is Claude-only and checks checklist syntax, not acceptance evidence” and “Claude and Codex follow the contract below.” The heading is “Shared continuation and completion contract (Claude and Codex).” Lines 94–121 retain same-turn continuation, acceptance evidence, ending audit, independent work, permissions and truthful blocker/runtime-limit reporting. Preserve these clauses; no further wording change needed.
- [Pass] Runtime boundaries remain truthful at `SKILL.md:17–26,123–132`: Claude Stop frontmatter remains; no Codex runtime gate is installed; Goals require an explicit request and Codex hooks require separate configuration/trust. The full existing `stop-hook.sh:36–49` reads checkbox syntax and emits a block only for open items; checked boxes do not prove acceptance. `install.sh:29–48,53–58` preserves live foreign links and existing discovery destinations. Current hook/installer SHA256 values match the recorded base hashes in `TESTS-RESULTS/2026-10-06+GH-983/provenance.jsonl` (comparison receipt). Preserve both files; no new gate, suite, configuration or source mechanism is needed.
- [Pass] Bounded evidence is accurately labeled at `TESTS-RESULTS/2026-10-06+GH-983/claude-compatibility.json:3–24` and `SUMMARY.md:5–13`: current source hash, open→block and checked→allow, old-heading red control, preserved hook/installer, and “not end-to-end Claude session or semantic evidence enforcement.” The earlier base also passed the ten decision states; no causal improvement or reliability guarantee is claimed. Preserve these qualifications.
- [Pass] Read-only receipt probe: command `python3 -c 'import hashlib,json,pathlib; p=pathlib.Path; c=json.loads(p("TESTS-RESULTS/2026-10-06+GH-983/claude-compatibility.json").read_text()); print("skill_hash_matches="+str(hashlib.sha256(p("skills/2-daily/workhorse/SKILL.md").read_bytes()).hexdigest()==c["skill_sha256"])); print("recorded_hook_cases="+str([(r["case"],r["exit_code"],r["blocks"]) for r in c["hook_checks"]]))'`, with `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`, exited 0: `skill_hash_matches=True`; `recorded_hook_cases=[('open', 0, True), ('checked', 0, False)]`. The matched current hash is `a6054d9fd3c99ac0caf92adef14d9acfd137637e86734c9664d2404983cb0931` (`claude-compatibility.json:3`). A separate in-memory inspection matched the hook/installer base hashes, parsed both recorded decisions, and observed the shared-heading predicate false after substituting the old Codex-only heading. Its first attempt exited 1 because the reviewer used `r['check']` on a provenance row without that key; correcting the probe to `r.get('check')` exited 0. This was a probe error, not an artifact defect.
- [Unverified — needs clone run] No suite, pytest, executable fixture, hook, installer or mutation-heavy gate was executed here. The hook results are inspected receipts from the supplied disposable-clone probe, not firsthand end-to-end Claude behavior. Final committed-state qualification belongs to the harness after this turn; review approval does not authorize merge, deployment or runtime configuration.

Whole-file sweep: read all 376 current SKILL.md lines, all 51 hook lines, all 58 installer lines, the complete compatibility JSON and SUMMARY, provenance receipts and prior gh983-final.codex.md QA. No additional actionable pre-existing defect was identified. Verify-tier graph inventory (both pages) contains no project for this worktree; nearest named XYZ-forge points to a different checkout, generation `2026-09-01T15:54:30Z`. Coverage reports skill/hook/installer freshness `not_tracked` and the new evidence/prior relay `missing`; full current direct reads supplied evidence, with no graph-completeness claim. Editing this relay is Easy and reversible. Only this relay file was edited; no git command was run.

Relay closed (Approved), no further review turn needed. NEXT returns to Producer for the harness-owned commit and final qualification.


### Attestation · relay-drive — 2026-10-06T22:52:43Z
task: GH983-CLAUDE-COMPAT
reviewer: Reviewer
status: Approved
reviewed-head: c9185e4db9d61229207250c43cdbd0ecdb3f5ebe
added-range: 6027+4372
added-sha256: 44282e75d09ed5420b43c6d43982829d9dc1e6b6af49b90c744a3b19841a9344
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
