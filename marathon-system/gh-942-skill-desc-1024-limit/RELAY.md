# Marathon Phase gh-942-skill-desc-1024-limit
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-942-skill-desc-1024-limit

- Generated: 2026-10-16T21:25:57Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/PROJECT/2-WORKING/GH-942-SKILL-DESC-1024-LIMIT.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify (development @ 52bc35112)
- Suggested branch: `marathon/gh-942-skill-desc-1024-limit-2026-10-16` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh --auto development` (routed by validate.sh --auto from contract gate `bash ci-local.sh`)

- Artifacts: skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 3188 LOC across 14 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/PROJECT/2-WORKING/GH-942-SKILL-DESC-1024-LIMIT.md` (0 checkbox(es) found across the WHOLE document — the doc has no `## Acceptance` section, so this list may include phase checklists). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #942 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/PROJECT/2-WORKING/GH-942-SKILL-DESC-1024-LIMIT.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh --auto development`, and NOT `test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-942-skill-desc-1024-limit RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh \
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


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick claim MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN --agent agy --paths "marathon-system/gh-942-skill-desc-1024-limit/RELAY.md,skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick ping MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick release MARATHON-GH-942-SKILL-DESC-1024-LIMIT-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-942-skill-desc-1024-limit/RELAY.md and skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/1-hourly/five/SKILL.md,skills/1-hourly/recon/SKILL.md,skills/2-daily/workhorse/SKILL.md,skills/3-weekly/10days/SKILL.md,skills/3-weekly/dry/SKILL.md,skills/3-weekly/radar/SKILL.md,skills/4-occasional/feynman/SKILL.md,skills/4-occasional/front-door/SKILL.md,skills/4-occasional/readme-audit/SKILL.md,skills/4-occasional/spike-360/SKILL.md,skills/4-occasional/timbre/SKILL.md,test/gh609-sdlc-agent-gaps.sh,test/gh779-radar-ci-health.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
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

- **Files touched (10 frontmatter-only edits):**
  - `skills/1-hourly/five/SKILL.md`: trimmed `description: >-` from `1061` to `899` chars (`903` UTF-8 bytes), front-loading `Trigger on /five, "five-step", "walk the 5 steps", "run the 5-step process", "do the five steps", or when the user asks to apply Elon's five-step process to a spec, plan, architecture, workflow, or codebase.` to char `82` (was `339`) while keeping all step behaviors, exclusions, and escalation rules intact (full procedural detail already lives in body lines 36-80, 122-127).
  - `skills/4-occasional/feynman/SKILL.md`: trimmed `description: >-` from `1241` to `876` chars (`878` bytes), front-loading `Use whenever the user says "feynman", "explain like I'm", "teach me this", "test if I understand", "help me actually understand", "break this down simply", "check my mental model", or asks for a clear explanation of a concept, paper, codebase, architecture, or mechanism.` to char `99` (was `229`) and preserving all four loop steps, modes (`explain` / `quiz` / `audit`), intensities (`lite`, `full`, `rigorous`), and anti-jargon/analogy rules (detailed in body lines 12, 48-53, 85-119).
  - `skills/4-occasional/front-door/SKILL.md`: trimmed `description: >-` from `1193` to `893` chars (`899` bytes), front-loading `Trigger on "/front-door", "front door audit", "audit the front door", "would a stranger understand this repo", "check our onboarding / first impression", "external DX check", or before open-sourcing, launching, or sharing a repo externally.` to char `130` (was `149`) while preserving all 7 friction checks, report-only safety rails, and exclusions (`readme-audit`, `sop`, `honest`; detailed in body lines 41, 47-59, 65-68, 100-123).
  - `skills/4-occasional/readme-audit/SKILL.md`: trimmed `description: >-` from `1183` to `834` chars (`842` bytes), front-loading `Trigger on "/readme-audit", "audit the README", "is the README accurate", "update the README to match the code", "README drift", "check README claims", or before a release/handoff.` to char `98` (was `264`) while preserving claim extraction/verification (`VERIFIED`, `STALE`, `WRONG`, `UNDOCUMENTED`), approval gating, and exclusions (`sop`, `honest`, `front-door`; detailed in body lines 29-38, 44-80).
  - `skills/4-occasional/spike-360/SKILL.md`: trimmed `description: >-` from `1151` to `946` chars (`948` bytes), preserving `Trigger on "/spike-360", ...` at char `183` alongside all four lens roles (Customer/PM, UX/DX, Security/Abuse, Ops/SRE), single-finding rule (`file:line` or command, failure scenario, smallest mitigation), `MUST-FIX BEFORE MERGE` vs `PARK FOR LATER` triage, and exclusions (`consult`, `review-xyz`, `recon`; detailed in body lines 40-75, 101-103).
  - `skills/4-occasional/timbre/SKILL.md`: trimmed `description: >-` from `1136` to `860` chars (`862` bytes), front-loading `Use whenever the user says "timbre", "humanize", "rewrite in my voice", "make this sound like me", "calibrate my voice", "update my voice profile", "strip the AI tone", "too AI-sounding", or asks to draft/edit prose (emails, posts, essays, docs, bios, replies, announcements) in their personal voice.` to char `66` (was `286`) while preserving `VOICE.md` profile lookup, 3-5 sample calibration, 9-dimension voice extraction, anti-AI-slop rules, and `match` / `blend` / `cleanup` modes (detailed in body lines 25-28, 40-51, 76-85, 105-115, 236-261).
  - `skills/2-daily/workhorse/SKILL.md`: converted `description: >` to `description: >-` (`798` chars / `798` bytes) and front-loaded `Trigger on /workhorse, "workhorse", "tackle this", "work through this problem", "methodical progress", or when an ambiguous or complex task requires structured, governed execution across the full ladder.` to char `50` (was `595`).
  - `skills/3-weekly/10days/SKILL.md`: kept `description: >-` (`993` chars / `994` bytes) and front-loaded `Trigger on "/10days", "run the 10 day sweep", or the operator's canned request to sweep recent GH issues, validate them, plan, preflight, and execute the marathon.` to char `163` (was `730`, resolving the GH-943 QA Nit).
  - `skills/3-weekly/dry/SKILL.md`: kept `description: >-` (`959` chars / `963` bytes) and front-loaded `Use whenever the user says "dry", "dedupe", "consolidate duplicates", "we have two of these", "merge these skills/configs/scripts", "find duplicate logic", "single source of truth", or after noticing parallel scripts, twin docs, or copy-pasted blocks drifting apart.` to char `50` (was `524`).
  - `skills/3-weekly/radar/SKILL.md`: kept `description: >-` (`953` chars / `953` bytes) and front-loaded `Trigger when the operator asks "how is our development cycle going", "are we just fixing bugs", "what keeps breaking", "did we introduce any regressions", "summarize radar history", "radar arc", "is the plan still right", "strategic review", "impact review", "run the radar", "/radar", or "/radar --arc".` to char `106` (was `497`, resolving the GH-943 QA Nit).
- **Unchanged allowlisted files (4):**
  - `skills/1-hourly/recon/SKILL.md`: already `description: >-` at `1005` chars (`1009` bytes) with `Fires when` at char `203` and `Also self-trigger` at char `239`.
  - `test/gh609-sdlc-agent-gaps.sh`, `test/gh779-radar-ci-health.sh`, `test/_setup.sh`: read in full and left untouched per `PROJECT/2-WORKING/GH-942-SKILL-DESC-1024-LIMIT.md` ("Frontmatter-only edits; no new suite (GH-831)"). Every body pin in `test/gh609-sdlc-agent-gaps.sh` and `test/gh779-radar-ci-health.sh` remains intact, and keeping edits strictly under `skills/**/SKILL.md` preserves docs-surface routing in `utils/ci-route.sh`.
- **Verification:**
  - Ran the `PROJECT/2-WORKING/GH-942-SKILL-DESC-1024-LIMIT.md` `fix_probes` check across `skills/*/*/SKILL.md` -> `bad: []` (exit `0`; all 38 committed skills have `len(desc) <= 1024`).
  - Verified via `skills/3-weekly/skills-army-hq/scripts/intake.py` `skill_info()` that every allowlisted skill parses cleanly with `description: >-`, `<= 1005` chars, `<= 1009` UTF-8 bytes, and trigger phrases starting within chars `50..203`.
