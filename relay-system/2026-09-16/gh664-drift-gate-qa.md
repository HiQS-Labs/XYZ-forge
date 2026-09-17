# RELAY · GH-664 skills-army-hq drift gate QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh664-drift-gate-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh664-qa-brief.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-16

### Artifact — gh664-qa-brief.md
```
QA PR HiQS-Labs/XYZ-forge#664 on this committed branch (fix/gh660-port-collection-skill-improvements, 3 commits on top of origin/development@74daa7d2). Read the full diff (`git diff origin/development...HEAD`) and these files IN FULL, not just the hunks:
- skills/skills-army-hq/scripts/sync.py  (the drift gate: canonical_root, drift_report, warn, drift_gate, main wiring)
- skills/skills-army-hq/scripts/intake.py  (only what sync.py depends on: load, inventory, require, DeployError, validate_targets)
- utils/py/skill_drift_check.py  (the forge-side checker sync.py shells out to; unchanged in this PR)
- skills/skills-army-hq/SKILL.md  (framing + "Drift guard" section)
- test/test_deploy_skills.py  (the five test_gh660_* cases + forge() helper)
- skills/daily/SKILL.md, skills/swe/SKILL.md, skills/skills-army-hq/references/targets.md  (three small ports)

Operational envelope: a local, single-user Python 3.9+ CLI (`sync.py`) that symlinks a skill collection into agent-app folders on one Mac. Not a service, not multi-tenant, not networked. Machinery and tests must stay commensurate with an ~80-line addition to a ~170-line script. Do not demand enterprise fail-safes, distributed locks, or config schemas; DO flag anything that breaks the existing contract of sync.py/intake.py or silently passes drift.

Non-goals: the pre-existing base-branch gate reds (pdda-check-roadmap-coverage on GH-658's doc, path-integrity fixture literals) are tracked in #667 and are NOT this PR's; do not grade them.

Questions:
1. Fail-closed vs fail-open: with NO canonical root configured, sync.py warns and proceeds. With an EXPLICIT but broken --canonical/XYZ_FORGE_ROOT/targets.json "canonical", it errors. Is that the right split, and is there any path where a drifted forge-owned skill can be deployed with --apply WITHOUT either a REFUSED (exit 2) or an explicit --allow-drift? Trace drift_gate() and main() carefully, including --status/--dry-run/--retire-trinity and the `deploying` (any enabled target) condition.
2. Resolution order: --canonical > XYZ_FORGE_ROOT > targets.json "canonical" > skills-army-hq's own recorded `repository`. The last one is a provenance path that may be a deleted task clone — it is skipped silently when it does not resolve. Is silently skipping it (with a "drift check skipped" warning) correct, or does it create a false sense of coverage?
3. Subprocess contract: drift_report() runs `python3 -B <canonical>/utils/py/skill_drift_check.py --canonical <canonical> --collection <root> --json` and accepts exit 0 or 1. The checker's `--canonical` accepts either the repo root or its skills/ dir. Any mismatch between what sync.py passes and what the checker expects, any quoting/space-in-path hazard (paths here contain spaces: "GH Repos", "Deployed Skills"), or any JSON-shape assumption that can KeyError?
4. Scope rule: only names present in the forge's skills/ are judged; collection-only skills are "unrecognized". Confirm sync.py never refuses on an unrecognized skill and never hides a drifted one because `found` (inventory) filtered it out.
5. targets.json: a new optional top-level "canonical" key. validate_targets() only checks "schema" and "targets". Does anything (intake.py transact/atomic_json rewrite of targets.json, `targets` subcommand) DROP the key on the next write? If so that is a real defect: the operator sets it once and loses it.
6. Result/receipt: `warnings` and `drift` are added to the JSON result and go through shared.transact() into changelog.md when actions/changes/errors exist. Is anything in the drift block non-serializable, huge, or a path that should not be persisted?
7. Tests: do the five test_gh660_* cases actually exercise the refusal path against a REAL subprocess call of the checker (not a mock), assert nothing was deployed on refusal, and leave no env leak (XYZ_FORGE_ROOT) between cases? Any case that would pass even if drift_gate() were deleted?
8. Docs: does SKILL.md's "Drift guard" section match the code exactly (flag names, resolution order, exit code, remedy command)? Does the "projection, not a source" framing contradict anything else in SKILL.md or references/targets.md?
9. The three ports (daily bullet, swe heading restoration, Grok Bot targets row): are they inserted in the right place, and does the swe heading restoration re-create the exact structure 731ae5f0 dropped (a `## How this differs from the sibling skills` heading above the sibling list)?
10. Commensurate complexity: is anything in this PR over-built for the envelope, or is anything missing that the acceptance criterion ("deploying a drifted skill fails loudly, citing the canonical path") requires?

Output: graded findings ([Blocker]/[Should]/[Nit]/[Pass]) each with file:line, a `swept file: yes|no` line, VERDICT PASS/FAIL, Basis. Read-only review; change only this relay thread. Approve if no blocking defects.
```
- Definition of Done: (a) `sync.py --apply` with an enabled target and any drifted forge-owned skill exits 2 with REFUSED naming the skill(s) and the canonical `skills/` path, deploying nothing; (b) `--allow-drift` deploys and records the drift; (c) no canonical root → loud warning, never a silent pass; explicit broken root → error; (d) collection-only skills never refuse; (e) targets.json "canonical" survives intake rewrites; (f) tests exercise the real checker subprocess; (g) SKILL.md matches the code; (h) the three ports land where described.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
