---
gh_issue: 1485
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1485
title: "feat(whack-a-mole): sharpen for cross-repo topology, multi-domain failure taxonomy, and phased umbrellas"
status: Active — Plan QA Round 3 (truthful verification labeling)
created: 2026-11-14
updated: 2026-11-14
owner: start-task lane
goal: Sharpen whack-a-mole to detect cross-repo upstream/downstream boundaries, decompose compound multi-domain failure modes, and structure multi-domain umbrella remediation plans into phased delivery lanes.
doc_type: enhancement
effort: 2
complexity: 2
risk: 1
phases: 1
related:
  - GH-1383 (optimize merge sequences umbrella)
  - GH-1475 (merge-cleanup 3-phase remediation plan)
  - GH-781 (radar reports seeding)
  - GH-860 (CI churn SOP)
context_tags: [whack-a-mole, skills, multi-domain, cross-repo, diagnosis]
---

# GH-1485 — Sharpen Whack-a-Mole: Cross-Repo, Multi-Domain Taxonomy & Phased Umbrellas

## Status
| What was just completed | What's next |
|---|---|
| Implementation complete; 34/34 tests passed; all 4 behavioral checks verified under TESTS-RESULTS/2026-11-14+GH-1485/. | Run Codex Final QA and independent Claude Code Opus 5.5 review |

## 1. Problem & Context
The recent `merge-cleanup` and `wave_reconcile` batch issues across `XYZ-forge` and `BinoidCBD/LTVera-Pandas` exposed three operational gaps in `whack-a-mole`:
1. **Single-repo scanner boundary:** `whack-a-mole` scans `gh repo view` by default. When a shared engine is consumed across repos, symptoms (failed batch runs, disk leaks, crash transcripts) surface in the consumer repo, while the fix churn and implementation sit in the upstream repo.
2. **Single-invariant vs compound failures:** While §5 already admits two entangled causes or unrelated bugs, compound failures across platform/harness, OS/resource, git concurrency, and domain merge engines lacked a clear taxonomy to separate root causes from environmental catalysts.
3. **Rigid linear remediation structure:** The standard linear `Reproduce -> Guard -> Fix -> Sweep -> Verify` template is ideal for single-defect clusters, but cannot cleanly model multi-phase remediations where defensive pre-flights and cleanup containment must land before deeper protocol refactors.

## 2. Surgical Scope & Adjudicated Rationale (Codex Round 1 Dispositions)

1. **Cross-Repo Boundaries & Radar Compatibility (Disposition 1):**
   - The filed umbrella and its scored `Cluster signature` block remain strictly **repo-local** to the repository where the umbrella is filed.
   - External evidence (from upstream tool repos or downstream consumers) is ingested as **diagnostic context** and symptom mapping.
   - External issue IDs (`owner/repo#N`) can be listed in the body's symptom mappings, but the scored paths, commits, and signals in the Cluster signature belong to the owning repo. External items never dilute or distort radar's re-score algorithm or earn quiet credit.
2. **Bounded Discovery & Preserving SOP Ownership (Disposition 4):**
   - Cross-repo discovery is bounded to **1 hop** along explicit tool dependency links (e.g., framework repos named in `.merge-cleanup.json`, `.tick`, or local checkouts).
   - Runtime telemetry inspection is bounded to reading recent local run logs (`TESTS-RESULTS/`, runner stderr) and existing issue comment addendums.
   - CI churn SOP pre-checks reuse radar Step 2c verbatim. Measurements remain strictly repo-scoped; consumer CI counts and upstream CI counts are never pooled.
3. **Conditional Taxonomy & Preserving Simple Paths (Disposition 3):**
   - The 4-plane taxonomy (Platform/Harness, Resource/OS, Concurrency/State, Domain Logic) is **opt-in / conditional**, invoked only when symptoms indicate cross-layer friction.
   - The primary decision in §5 remains: one root cause, two entangled causes, or unrelated bugs sharing a file (the exit to not file is strictly preserved).
   - Invariant analysis requires distinguishing primary invariant violations from environmental catalysts and secondary casualties.
   - The Phased Remediation structure (Phase 1 Containment, Phase 2 Core Invariant, Phase 3 Decoupling) is **optional and dependency-driven** for compound clusters. The simple linear flow remains the primary default for single-domain bugs.

## 3. Falsifiable Acceptance Checks
- `AC1 (Scope & Discovery)`: `SKILL.md` documents 1-hop bounded upstream/downstream discovery preferences while keeping the scored Cluster signature repo-local.
- `AC2 (Multi-domain Decomposition)`: `SKILL.md` specifies the conditional 4-plane taxonomy and requires classifying signals into primary causes vs. catalysts without eliminating the unrelated-bugs exit.
- `AC3 (Phased Umbrella Template)`: `SKILL.md` documents both the default linear remediation template and the optional phased remediation lanes template, preserving exact radar Cluster signature keys.
- `AC4 (Quality & Lint Gates)`: `test_deploy_skills.py` (34/34) and `test/skills-army-hq.sh` pass cleanly with zero warnings.

## 4. Planned Behavioral Checks & Negative Controls (To Execute in Step 7)
Planned manual scenario controls to be executed during implementation, with resulting evidence and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-14+GH-1485/`:
- **Planned Control 1 (Upstream/Downstream Correlation):** An upstream tool error signature correlated with a downstream batch failure is recognized as a unified diagnostic context without corrupting local signature paths.
- **Planned Control 2 (Adjacency Negative Control):** A cross-repo mention without matching error signature or file seam is rejected as mere adjacency (two-signal rule upheld).
- **Planned Control 3 (Catalyst Separation):** A coincident resource exhaustion symptom (e.g. disk full from unpruned workdirs) is classified as an environmental catalyst/amplifier, not the primary concurrency invariant violation.
- **Planned Control 4 (Signature Rejection Control):** A signature block missing any required key or attempting non-repo-local paths fails the template contract.
