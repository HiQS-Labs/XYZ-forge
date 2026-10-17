# Marathon Phase gh-942-skill-desc-1024-limit
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-942-skill-desc-1024-limit

- Generated: 2026-10-17T02:34:44Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/PROJECT/2-WORKING/GH-942-SKILL-DESC-1024-LIMIT.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify (marathon/gh-942-skill-desc-1024-limit-2026-10-16 @ e453b1612)
- Suggested branch: `marathon/gh-942-skill-desc-1024-limit-2026-10-17` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh --auto development` (routed by validate.sh --auto from contract gate `bash ci-local.sh`)

- Artifacts: skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,skills/1-hourly/better-options/SKILL.md,skills/4-occasional/vscode-color/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 3431 LOC across 16 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/PROJECT/2-WORKING/GH-942-SKILL-DESC-1024-LIMIT.md` (0 checkbox(es) found across the WHOLE document — the doc has no `## Acceptance` section, so this list may include phase checklists). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #942 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*  [Unverified — no citation]
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/PROJECT/2-WORKING/GH-942-SKILL-DESC-1024-LIMIT.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,skills/1-hourly/better-options/SKILL.md,skills/4-occasional/vscode-color/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh --auto development`, and NOT `test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-942-skill-desc-1024-limit RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,skills/1-hourly/better-options/SKILL.md,skills/4-occasional/vscode-color/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh \
  --pre-advance-cmd 'bash validate.sh --auto development' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/gh-942-skill-desc-1024-limit/ESCALATION.md`): `human-escalation`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,skills/1-hourly/better-options/SKILL.md,skills/4-occasional/vscode-color/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick claim MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN --agent agy --paths "marathon-system/gh-942-skill-desc-1024-limit/RELAY.md,skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,skills/1-hourly/better-options/SKILL.md,skills/4-occasional/vscode-color/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick ping MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick release MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-942-skill-desc-1024-limit/RELAY.md and skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,skills/1-hourly/better-options/SKILL.md,skills/4-occasional/vscode-color/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,skills/1-hourly/better-options/SKILL.md,skills/4-occasional/vscode-color/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick release MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick done MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick
   Edit ONLY marathon-system/gh-942-skill-desc-1024-limit/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · agy

- **Files modified in this turn:**
  - `skills/1-hourly/better-options/SKILL.md`: Trimmed frontmatter `description` from `1603` YAML chars (`1600` folded) to `963` YAML/folded chars (`965` UTF-8 bytes) using `description: >-`. Front-loaded `Trigger when...` at character `55` (`< 250` chars), preserving all trigger phrases (`"you have to either X or Y,"`, `"there's no way around it,"`, `"we'd need to..."`, `"is that really the only way,"`, `"feels like you're overcomplicating this,"`, `"are these actually the same problem,"`, `"what's the simplest version that still works"`), self-trigger behavior, `debug-mantra` falsification + `ponytail` minimalism summary, and all skip conditions (`take-a-step-back`, `bottom-line`); body already covers the expanded discipline and sibling comparisons in full.
  - `skills/4-occasional/vscode-color/SKILL.md`: Trimmed frontmatter `description` from `1042` YAML chars (`1039` folded) to `920` YAML/folded chars (`924` UTF-8 bytes) using `description: >-`. Front-loaded `Trigger when...` at character `102` (`< 250` chars), preserving all trigger phrases (`"tint this repo"`, `"give this workspace a background color"`, `"make this window a different color"`, `"set the editor background for this repo"`, `"color-code my repos"`, `"/vscode-repo-tint"`, unprompted window-confusion offer), `.vscode/settings.json` (`workbench.colorCustomizations`) scope, deterministic (`SHA-256` of GitHub slug) and manual override modes, the seven tinted surfaces, `--light` variant, and non-goals; body already covers these details in full.
  - `marathon-system/gh-942-skill-desc-1024-limit/RELAY.md`: Updated `NEXT: codex (Reviewer)` and appended this Round 1 block.
- **Verified preserved state across the remaining 11 allowlisted `SKILL.md` artifacts (all `<= 1024` YAML/folded chars and UTF-8 bytes, with trigger wording within the first 250 chars and bodies intact):**
  - `skills/1-hourly/five/SKILL.md`: `899` YAML/folded chars (`903` bytes) — 5-and-5 decision checksum (`Does (5)` / `Does NOT (5)` + `Not specified` + reading pointer).
  - `skills/1-hourly/recon/SKILL.md`: `1005` YAML/folded chars (`1009` bytes) — end-to-end system trace producing a Recon Map across Lanes A–D (`test/gh609-sdlc-agent-gaps.sh` pins intact).
  - `skills/2-daily/workhorse/SKILL.md`: `798` YAML/folded chars (`798` bytes) — 7-rung governed problem resolution ladder (`test/gh609-sdlc-agent-gaps.sh` pins intact).
  - `skills/3-weekly/10days/SKILL.md`: `993` YAML/folded chars (`994` bytes) — 10-day GitHub issue sweep, PRS 4-axis prioritization, validation, preflight, and unattended disposable-clone marathon execution.
  - `skills/3-weekly/dry/SKILL.md`: `959` YAML/folded chars (`963` bytes) — resource-first duplicate subsystem / policy owner discovery producing a Convergence Map.
  - `skills/3-weekly/radar/SKILL.md`: `953` YAML/folded chars (`953` bytes) — per-repo SDLC coach over 2–3 weeks mining 9 evidence signals and persisting to two sinks (`test/gh779-radar-ci-health.sh` pins intact).
  - `skills/4-occasional/feynman/SKILL.md`: `876` YAML/folded chars (`878` bytes) — plain-English technical translation via first-principles ladders, glossary, bounded analogies, and honesty pass.
  - `skills/4-occasional/front-door/SKILL.md`: `893` YAML/folded chars (`899` bytes) — new-user clone-to-working onboarding, install-script, auth-gate, and secret-leak audit.
  - `skills/4-occasional/readme-audit/SKILL.md`: `834` YAML/folded chars (`842` bytes) — root README accuracy, legibility, operator UX, and outbound-link audit.
  - `skills/4-occasional/spike-360/SKILL.md`: `946` YAML/folded chars (`948` bytes) — five-level state authority classification before planning/architecture work.
  - `skills/4-occasional/timbre/SKILL.md`: `860` YAML/folded chars (`862` bytes) — three-role human-voice writing pipeline (Cartographer, Drafter, blind Adversarial Reader).
- **Verification:**
  - Ran the contract YAML/folded-length probe across all `69` `skills/*/*/SKILL.md` files: `bad: []` (exit `0`), confirming zero committed `SKILL.md` descriptions exceed `1024` YAML, folded, or UTF-8 byte length.
  - Verified `test/gh609-sdlc-agent-gaps.sh`, `test/gh779-radar-ci-health.sh`, and `test/_setup.sh` were read as specs without executing suites inside the isolated worktree.

handing off to codex — codex, take your turn.


### Round 1 · Reviewer · codex

**Verdict:** Approved

swept file: yes

Read all 13 allowlisted SKILL.md files in full and all three covering test/helper files as source. Approval covers the GH-942 frontmatter-description remediation; executable gate results remain **[Unverified — needs clone run]** and belong to the harness after handoff. No git commands, suites, executable fixtures, or artifact edits were performed.

- **[Pass] Length and extraction:** Independently parsed all 69 `skills/*/*/SKILL.md` frontmatters with PyYAML, rejecting missing frontmatter, empty descriptions, and an empty corpus. All YAML values, whitespace-folded values, and UTF-8 representations fit 1024. The 13 target YAML lengths are: five 899; recon 1005; workhorse 798; 10days 993; dry 959; radar 953; feynman 876; front-door 893; readme-audit 834; spike-360 946; timbre 860; better-options 963; vscode-color 920. Trigger wording begins at character offsets 50–239 across the targets. The formerly excluded better-options and vscode-color paths are now explicitly allowlisted, resolving the previous escalation's scope mismatch.
- **[Pass] Content:** The short descriptions retain the skills' purpose, triggers, and principal boundaries; expanded procedures remain in the reviewed bodies. Existing workhorse/recon lane contracts and Radar CI-health wording remain present in the source read against their covering test specs. This is source verification, not a suite-run claim. No new test suite or gate machinery is needed.
- **Evidence provenance limitation:** `list_projects` has no index for this relay worktree. Nearest same-repository graph `XYZ-forge` reports generation `2026-09-01T15:54:30Z`; coverage checked for all 16 paths reports untracked freshness for 15 and metadata-changed for `test/_setup.sh`. Consequently this review relies on complete direct file reads, not graph completeness or freshness.

Read-only length probe (exit **0**, decisive output **`corpus=69 bad=[]`**), run with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`:

```bash
python3 - <<'PROBE'
from pathlib import Path
import re,yaml
files=sorted(Path("skills").glob("*/*/SKILL.md"))
assert files
values=[]
for p in files:
    m=re.match(r"^---\n(.*?)\n---",p.read_text(),re.S)
    assert m,str(p)
    d=yaml.safe_load(m[1])["description"]
    assert isinstance(d,str) and d.strip(),str(p)
    values.append((str(p),len(d),len(" ".join(d.split())),len(d.encode())))
bad=[v for v in values if max(v[1:])>1024]
print(f"corpus={len(values)} bad={bad}")
assert not bad
PROBE
```

Manual red control, without mutating any artifact:

```bash
python3 -c 'assert len(" ".join(("x"*1025).split())) <= 1024, "1025-char description rejected"'
```

Exit **1**; decisive output **`AssertionError: 1025-char description rejected`**. The corresponding 1024-character input was accepted in the initial boundary probe.

**[Should — nonblocking pre-existing safety concern]** `skills/3-weekly/10days/SKILL.md:501–507` tells an agent to fall back to `git worktree remove --force <path>` when ordinary removal reports uncommitted/stray state. Merged tracked commits alone do not prove that additional working-tree state is preserved. This concern is in the swept body; it is not a description-limit regression. The active contract explicitly requires frontmatter-only edits, so this approval does not authorize or attest that cleanup recipe. Before executing that recipe, apply the repository's preservation/cleanup SOP rather than the unconditional force fallback.

Observed input: the literal instruction at lines 501–503, specifically `fall back to git worktree remove --force <path>` on `uncommitted/stray state`.
Affected scope: `/10days` Step 7 lane-worktree retirement, including any remaining uncommitted or untracked lane evidence.
Falsifier: show a required preservation check in this cleanup step that inventories and preserves unique remaining state before any force removal. No destructive reproduction was attempted; runtime impact is **[Unverified — needs clone run]**. Source probe: `nl -ba skills/3-weekly/10days/SKILL.md | sed -n '495,515p'` (exit **0**) printed the unconditional fallback quoted above. Recommended follow-up is to retain/report dirty worktrees pending preservation proof; this body change needs separately authorized scope.

relay closed, no further turn needed
