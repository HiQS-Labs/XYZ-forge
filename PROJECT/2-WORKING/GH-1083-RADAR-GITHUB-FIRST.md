---
title: 'GH-1083: GitHub-first radar evidence'
status: Active
created: 2026-10-15
updated: 2026-10-15
owner: Codex
gh_issue: 1083
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1083
doc_type: feature
effort: 2
complexity: 2
risk: 2
phases: 1
goal: Make GitHub authoritative for radar work facts while retaining documentation hints and fallback
---

# GH-1083 — Radar GitHub-first evidence

## Status

| What was just completed | What's next |
|---|---|
| Issue, source and prior-art inspection complete; task rated and registered | Final independent QA, then normal documentation-gated PR publication |

Update only `skills/3-weekly/radar/SKILL.md` as the product payload. GitHub issues/PRs own live state, kinship, recurrence, closure/reopens, milestone membership and merged/shipped evidence. PDDA docs seed discovery and provide explicit degraded fallback. Revisit Transform and CI churn SOP precedence; distinguish losing GitHub from losing doc hints. No new tests or runtime code. Refresh through Skills Army after merge, not from an unmerged task clone.


## Ground truth and bounded recon

Base: `dc7245b4d34e49b9adfba25cf5efbae08bf99c0e`. Non-code recon: instruction source -> agent reads git/GitHub/docs/ledger -> lenses -> advisory report -> confirmation-bound report sinks. No runtime change or new source-of-truth store. `radar/SKILL.md:52-54,110-114` gives RGT declaration authority to docs; `:147-179` seeds kinship and false-close evidence from docs; `:337-347` explicitly says the doc wins; `:623-624` treats missing GitHub and PROJECT as parallel missing inputs. Source read in full. Later clauses in release alignment, historical reports and retirement must obey the same fact precedence, not merely the opening paragraph.

Prior-art CLI found #880 via broad keywords; GitHub file inspection shows no radar file in that PR. Current radar still contains the reported rules, so it is not an existing fix. No open PR references #1083. No existing capture/rating was found. Related #860 concerns CI churn behavior; #779 concerns regression signals; #945 concerns asset recommendations, not authority. Do not expand those tasks.

Rating read-back: `70/45/50/85`, no override. Priority reflects explicit operator selection; severity reflects misleading advisory progress/recurrence reports, with no observed data loss or operational execution. Appeal is neutral; cheapness reflects one instruction file. Recurrence inspection window: Oct 2–15 versus Sep 18–Oct 1, 2026; title-scoped radar issue search finds related improvements, not distinct verified incidents of this precedence defect. Trend is unknown; no escalating recurrence claim.

## Bet, alternatives and rollback

Outcome: radar recommendations use verified current work facts instead of stale capture docs. Smallest bet: add one source hierarchy, update its conflicting local rules, reuse existing reads, report templates and sinks. No scripts, queries-as-a-service, test suite, state store or automatic doc repair.

Alternatives ranked: (1) update central and conflicting local instructions together (chosen); (2) add only a top-level GitHub-first sentence (leaves explicit contrary rules active); (3) remove all doc discovery (loses useful context and offline fallback). For SOP policy, retain a narrow justified exception: adopted landed thresholds remain operating policy rather than being silently replaced by an unmerged proposal. GitHub establishes adoption/status/version; report mismatches as drift. Strongest counterargument for plan QA: would that exception accidentally restore broad doc authority? It must never override issue/PR state, history or evidence of a superseding adopted policy.

Reversibility: Easy. Revert the skill edit; no data/schema/runtime migration. Scope is the existing radar skill plus ordinary governance/evidence. Skills Army refresh remains an explicit post-merge handoff; start-task does not authorize merge.

## Ordered implementation and verification

1. After plan approval, admit the exact owned issue row with `roadmap update --gid ... --accepted-start`. Amend the skill's source hierarchy and local RGT/kinship/false-close/history/release/retirement claims. -> expect live GitHub verification of every doc-derived work fact, explicit unknowns on partial reads, no doc-only retirement or shipped claims; no semantic kinship from reference existence alone.
2. Make Transform declaration GitHub-first using the existing explicit `rgt:` vocabulary, retain labelled doc fallback only when GitHub is unavailable, and document the narrow adopted-SOP policy exception. Update degradation and report wording. -> expect GitHub loss lowers whole-report confidence, PROJECT loss removes only hints; draft/unmerged work does not become shipped or adopted.
3. Record a bounded manual radar dry run of changed behaviors under `TESTS-RESULTS/2026-10-15+GH-1083/`: live issue/PR observations plus labelled conflict/fallback scenarios. Apply old contradictory clauses as textual red controls, then apply the new instructions. -> nonempty dated input, citable decisions, no report-sink or issue/doc mutations, and no claim this tests every future model response.
4. Run independent final Codex relay QA, inspect actual changed-path classification, publish through the existing docs gate, retain provenance and open a ready PR against development. -> only skill Markdown plus task records; no new tests and no full runtime suite for a docs route. Verify exact remote PR head/checks and safely retire this workflow's published clones via the existing closeout mode.

## Acceptance map and falsifiers

| Issue requirement | Pass evidence | Red control |
|---|---|---|
| GitHub work facts win; stale docs become drift | Open live issue beats a controlled completed-doc claim; merged PR establishes landing; unmerged PR remains in flight | Old blanket SOP doc-wins clause and doc-primary closure instruction conflict with live authoritative facts |
| Docs seed discovery and degraded fallback | Related-doc hint gets issue/relationship verification; unavailable live evidence stays labelled unverified | Existing reference alone or absent timeline is not proof of kinship or zero reopens |
| RGT and SOP rules revisited | Explicit GitHub RGT beats conflicting doc RGT; adopted-policy exception scoped and justified | Old doc-only Transform rule ignores the GitHub declaration; draft SOP proposal must not silently replace adopted policy; newer adopted GitHub policy beats stale doc thresholds |
| Distinct degradation costs | Simulate missing gh, missing PROJECT and partial GitHub access separately | Old table lacks whole-report confidence degradation and removes RGT when only PROJECT is absent |

## Verification and handoff

Plan QA Approved with mechanical attestation at reviewed head 35b5d75cd622f26e5690ebdb164245cdad1d436f. Incorporated the optional reverse-SOP-conflict and unknown-adoption checks as tests of existing requirements. Admission recorded on owned row rmi-01M50N8DK8P3KW3CZ89N0YZGJV before skill edits. Skill edit is committed at 033b83a2. Bounded manual dry-run evidence covers eight cases, with nonempty timestamped GitHub observations, controlled conflict/fallback inputs and textual baseline red controls. Format validation passed. Changed paths classify docs / tier 1 / full_required=false. Final independent QA and normal docs publication gate remain pending. Required receipts are retained under TESTS-RESULTS/2026-10-15+GH-1083/. Post-merge action: use Skills Army HQ scripts to intake/update radar from merged development and sync this device's configured IDE targets; do not hand-copy the deployed skill. Keep this pointer in the PR and issue handoff until performed.

## Lessons Learned (For Future Agents)

An opening precedence rule cannot correct explicit contradictory per-lens instructions. Keep observation authority distinct from adopted operational policy and unavailable evidence distinct from a negative result.
