# RELAY · GH-664 skills-army-hq drift gate QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
-->

NEXT: Producer
STATUS: Approved
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

## Reviewer — codex — Round 1

swept file: yes

VERDICT: PASS

Basis: Static approval within the stated local CLI envelope; no blocking defect found in the normal deployment gate or the pre-existing reconciliation/retirement code swept. This is not a claim of passing execution. Read the complete named files (including intake's persistence path and the full test module). The current worktree is absent from both pages of the graph project inventory, so evidence is direct source, not another checkout's graph. Per the operator's explicit restrictions, no Git command, source execution, test run, mutation probe, or historical diff was performed; the three-commit diff and exact historical equivalence to 731ae5f0 remain unverified. Harness validation remains outstanding.

- [Pass] Gate ordering and scope: `skills/skills-army-hq/scripts/sync.py:197` makes status/dry-run non-applying; `sync.py:219` inventories before `sync.py:226` gates, and reconciliation/transaction follow at lines 227/233. Lines 78–87 refuse drift in deployable inventory with an enabled target before link writes, naming the canonical skills path; lines 88–90 disclose overrides. `intake.py:268` includes every valid immediate skill folder, including unregistered additions, and rejects invalid/missing payloads rather than silently deploying them. Unrecognized names never enter refusal (`utils/py/skill_drift_check.py:34`, `sync.py:78`). No fix required.
- [Pass] Resolution/subprocess: `sync.py:38` implements the documented priority, errors on a nonempty broken explicit root, skips stale provenance, and emits the skipped-check warning at line 74. This is a reasonable compatibility boundary: absent canonical coverage is disclosed, not represented as clean. `sync.py:54` uses argv elements and the current interpreter, preserving spaces; the repo root matches the checker's normalization at `utils/py/skill_drift_check.py:70`. Its report keys match `sync.py:58`; malformed JSON/missing keys fail before deployment through `sync.py:235`. No fix required.
- [Pass] Persistence: `intake.py:229` returns the original config, `intake.py:671` changes only its targets member, and `intake.py:522` / `intake.py:510` carry/write the whole config, preserving canonical. `sync.py:58` emits only JSON-compatible strings/lists/dicts; `sync.py:228` includes warnings/drift in the transaction details. History is written only when actions/changes/errors exist (line 232); a no-op reports drift without a new receipt. Local paths are consistent with the existing local receipt contract. No fix required.
- [Pass] Tests use the real checker: `test/test_deploy_skills.py:481` copies the production checker, and line 64 executes the CLI in a subprocess. Lines 499–506 assert refusal, the canonical path, an absent sample destination, and explicit override deployment. Removing the gate would contradict the refusal exit assertion and report assertions; this conclusion is source-derived, not mutation-tested. Each case gets a fresh env dict at line 54, so test-local env assignments do not leak into another case. No mock substitutes for the drift checker.
- [Should] Test isolation and proof can be tightened without adding machinery: `test/test_deploy_skills.py:54` inherits the operator's XYZ_FORGE_ROOT, so existing tests that expect an unconstrained deployment can instead fail against an unrelated or broken host canonical checkout. Clear that key in setUp; individual drift cases already set their own. At line 502, check the whole destination/owned-link state (including dangling symlinks), not only sample.exists(). Extend line 527 through one intake write and reload canonical, and assert the override's changelog drift receipt after line 506. These are nonblocking coverage improvements; source inspection supports the behavior.
- [Nit] Printed remedy is not shell-safe for the explicitly supported space-containing paths: `sync.py:81` interpolates an unquoted --source path. Use shlex.quote for that argument (and show python3 plus the intended intake path/root if meant to be copy-pastable). The checker invocation itself is correctly quoted by argv.
- [Nit] `skills/skills-army-hq/SKILL.md:135` says the checker runs on every apply/status, but `sync.py:221` skips it for --retire-trinity. Qualify the sentence as normal reconciliation; retirement only withdraws the old skill (`sync.py:154`, `sync.py:169`) and is not a deployment bypass.
- [Nit] Pre-existing documentation mismatch: `skills/skills-army-hq/SKILL.md:12` names the pulse collection, while the no-root examples at lines 98–99 initialize the scripts' default Documents/Deployed Skills (`intake.py:555`, `sync.py:179`). Add --root to examples intended to operate on the pulse collection; invoking a script through that collection's path does not change its default root.
- [Pass] Port placement and framing: `skills/daily/SKILL.md:39` puts fresh-state calibration in Guardrails; `skills/swe/SKILL.md:103` contains the exact requested sibling heading immediately above the sibling list; `skills/skills-army-hq/references/targets.md:16` adds the Grok row and line 30 distinguishes Mac staging from box import. `skills/skills-army-hq/SKILL.md:16` and line 43 distinguish canonical source from transport consistently. Current placement is sound; historical restoration was not checked. No fix required.

Relay closed (Approved), no further turn needed. Nonblocking findings are available to Producer (claude-a); the harness owns commit and gate execution.


### Attestation · relay-drive — 2026-09-17T03:53:55Z
task: RELAY-gh664-drift-gate-qa
reviewer: codex
status: Approved
reviewed-head: 56e3d5cdfaf45e37d8feb4e31c359898e01d0acf
added-range: 9226+5504
added-sha256: 996edaa359563085c5f37fd2ad8e4016619c7f251a1418f5919a927dd0ffe85f
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
