# RELAY · Plan QA: GH-744 skills/ frequency-tier reorganization
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
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
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh744-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-744-SKILLS-FREQUENCY-TIERS.md` (the plan; committed at 51aeb57c)
- Reviewer: agy   ·   Producer: claude-a   (re-pointed from codex 2026-09-21: codex-cli 0.154.0-alpha.6.2 fails every tool call with `missing field code_mode_host_duration_ns`; operator chose agy)
- Started: 2026-09-21
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/744
- Definition of Done: the plan is grounded in the actual paths, complete against the issue's four
  requirements, extends the existing scanners/publishers/locators rather than adding a parallel
  subsystem, and its acceptance checks would actually catch the failures they claim to.

### Operational envelope (grade against THIS, not an imagined one)
A one-time `git mv` of 60 skill directories into four tier folders inside a single-maintainer
developer harness repo, plus repointing the code and docs that address `skills/<name>`. No runtime
service, no multi-tenant surface, no data migration. Machinery and tests must stay commensurate:
no resolver library, no registry file, no layout fuzzer, no compatibility symlink layer unless you
can show a concrete consumer that breaks without it (cite it). The Producer will disposition
requests for unrequested machinery as `Rejected (Out of Scope / Ponytail)`.

### Read these (repo-relative, all in the worktree at HEAD)
- The plan doc above — in full, including the Recon section and the Ordered implementation list.
- `utils/py/skill_drift_check.py` (the `scan()` glob), `utils/py/xyz_mini_sync.py` (MANIFEST),
  `utils/ci-route.sh:24-50,300-320` (subsystem registry), `relay-automation/xyz-vendor.sh:425-445` (VENDOR_DIRS).
- `skills/relay-xyz/find-harness.sh:100-215`, `skills/hq/find-hq.sh:35-70`, `skills/file-xyz-bug/find-xyz.sh:40-70`,
  `skills/vendor-stack/find-pdda.sh:20-40`, `skills/vendor-stack/install.sh:45-55`,
  `skills/relay-to-issue/relay-to-issue.sh:45-52`, `skills/relay-automation/make-pkg.sh`,
  `skills/agent-chorus/scripts/agent_chorus.py:79-90`, `skills/merge-cleanup/scripts/scan_clones.py:185-195`.
- `mini/skills/skill-viewer/scripts/list_skills.py:64-85` (why it is NOT changed).
- `test/gh396-find-harness-roots.sh`, `test/hq-locator.sh`, `test/gh660-skill-drift.sh`, `test/path-integrity.sh:20-60,130-150`, `test/ci-route.sh:60-80,150-190`.
- `ARCHITECTURE.md:35-100` (the Skills Index the plan regroups).

### Questions (answer each by number; cite file:line)
1. Consumers: run `grep -rn -E 'skills/[a-z0-9-]+' --include='*.sh' --include='*.py' --include='*.yml' --include='*.json' .` (excluding `.git`, `CHANGELOG.md`, `relay-system/`, `marathon-system/`, `PROJECT/`, `temp/`, `.xyz/`) and name any executable consumer of a `skills/<name>` path that the plan's Recon section does NOT list. Ignore comment-only hits.
2. Locators: for each bash locator listed, is `../..` → `../../..` the complete change, or does another self-relative derivation in that file (e.g. the `_hp_lib` source line, a `LIVE_HARNESS` probe) also need it? Is there any locator that also runs from a FLAT layout (XYZ-mini publish, Deployed Skills copy) where a depth bump would mis-resolve rather than fall through?
3. `agent_chorus.py` and `scan_clones.py` are published/copied to flat layouts too. Does the plan's "walk up to the nearest ancestor containing `skills/` (or `bin/tick`), fall back to `parents[3]`" resolve correctly at both depths and in a vendored `.xyz/`? Name a concrete layout where it picks the wrong root, if one exists.
4. `skill_drift_check.py`: the plan keeps one-level scanning for XYZ-mini collections and adds two-level for forge. Does `test/gh660-skill-drift.sh` still act as a red control (detect drift on its own fixture) after that change, or does it need a two-level fixture to prove the new branch?
5. `ci-route.sh`: will `skills/*/hq/*`-style globs in the `case` statement match `git diff --name-only` output correctly (bash `case` globbing, `*` matching `/`)? Cite the exact line pattern that would be wrong if so.
6. Tier assignment: the operator anchored 9 skills; the Producer placed the other 51. Is any placement contradicted by that skill's own trigger description (cite the SKILL.md line)? This is advisory — one `[Nit]` per disagreement, not a blocker.
7. Rating `55/25/50/45`: is any axis contradicted by evidence in the repo (e.g. an open issue showing this layout blocks work, which would raise sev/pri)? Appeal must stay 50 unless the operator set it.
8. Missing requirement: does the plan omit anything the issue's Acceptance section requires, or anything AGENTS.md / ROUTER.md requires for a change of this shape (issue-first, PDDA capture, CHANGELOG, full gate in a disposable clone)?
9. Rollback: is a single revert of the merge commit actually sufficient, or does any generated artifact (`relay-pkg.tar.gz`, `releases.sql`, a security-scan baseline) need a paired action?

Output: one graded finding per question (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), file:line cited,
`swept file: yes|no`, then `VERDICT: PASS|FAIL` and `Basis:`. Set `STATUS: Approved` on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
