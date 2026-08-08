---
gh_issue: 416
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/416
title: "GH-416 — a dependency sync silently deleted three shipped guardrails and left CI red for two days"
status: "In flight (2-WORKING) — captured 2026-08-05 for release 0.2.0 Litmus. FOUR OF FIVE CRITERIA ALREADY SHIPPED via PR #413 (2026-08-03); only criterion 5 (the sync-review policy) is outstanding and this lane is scoped to it. Preflight READY 2026-08-08; operator go given; queued as phase 1 of 3 in MARATHON-2026-08-08-LITMUS-WAVE-2."
created: 2026-08-05
updated: 2026-08-08
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 1
risk: 1
effort: 2
phases: 1
ratings_provisional: true
related:
  - "#419 — the class. Three red tests read as background noise for two days because a failure that has been red a while stops being read as information."
  - "#315 / #319 / #351 — the same observation-layer family, named in the issue."
  - "#189 / #284 — the two features the sync deleted. Both belong upstream; see Follow-ups."
non_goals:
  - "Re-doing criteria 1-4. They shipped in PR #413 and were verified on 2026-08-05; re-opening them would be work with no deliverable."
  - "Upstream adoption of GH-189 and GH-284 Phase 3. Tracked as a follow-up, not this lane."
  - "Restoring the roll-up's `(none — ...)` line. It belongs upstream; putting it back in a file the next sync overwrites would repeat this incident."
  - "Putting the policy in PROJECT/PDDA.md. That file is sync-managed (utils/pdda/PDDA-SOURCE.md:12) — writing the sync-review policy into a file the sync replaces is the incident, restaged."
goal: >
  A routine dependency sync replaced `utils/pdda/**` wholesale and deleted three locally-developed
  guardrails plus a behaviour change, announced by nothing but three red tests whose messages did not
  mention deletion. The structural fix shipped. What did not ship is the stated policy for reviewing
  the next sync — the criterion that stops this recurring rather than repairing this instance.
---

# GH-416 · what is left is the policy, not the repair

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-05 as a lane of release 0.2.0 Litmus. **Criteria 1–4 verified already shipped** (PR #413); the lane is scoped to criterion 5 alone. Preflight contract authored and verified READY; acceptance reads `match — 5/5 criteria copied verbatim from issue #416`. | Operator go. One phase: the PDDA-sync review policy, in a repo-owned file the sync cannot replace. |

**Verified 2026-08-05 against `development` @ `2c95a56` — four of five criteria are already met:**

| Criterion | State | Evidence |
|---|---|---|
| 1. `tier1` green on `development` | **met** | green since PR #413 |
| 2. Every repo-owned check lives outside `utils/pdda/**` | **met** | `utils/pdda-local-checks.sh` exists |
| 3. Each restored check has a test that fails when the check is removed | **met** | `test/pdda-local-checks.sh` exists; every check has a trip fixture and a clean fixture |
| 4. The `utils/pdda/**` path-integrity exemption is documented at the point of exemption | **met** | shipped in PR #413 |
| 5. **A stated policy for the next PDDA sync** | **OUTSTANDING** | no policy doc exists; `PDDA sync` appears only in `CHANGELOG.md` and `ROADMAP.md` |

Wired into both `validate.sh` and `.github/workflows/ci.yml`, verified 2026-08-05.

**This lane is therefore one criterion wide.** Recorded explicitly because a capture doc that
restated all five would send a builder to rebuild four things that exist — and preflight would not
catch it, since it has no issue-state or done-ness check (that is #418, a sibling lane in this same
release).

## What was lost, and why it read as noise

`cfd56b0` closed two failures and left three. Those three were carried for two days as "pre-existing
noise" — including in PR #413's own body. They were three deleted guardrails:

| # | Behaviour | Evidence |
|---|---|---|
| 1 | GH-189, doc side — a `3-COMPLETED` doc whose frontmatter status is still non-terminal | `non-terminal` in `pdda.sh`: **4 → 0** |
| 2 | GH-189, ledger side — the entire `roadmap-issue-state` subcommand | **5 → 0**; the test got `unknown command` |
| 3 | GH-284 Phase 3 — the missing-`Milestone:` warning, the release → issue-set join key | reduced to a bare `printf` |

**Two were invisible behind the other two.** The test files fail-fast, so #2 and #4 could not be seen
until #1 and #3 were fixed. That is the observation-layer failure this release is named for.

**The structural cause:** local checks were living inside a tree that is replaced wholesale, and
`pdda.sh` offers no extension seam. Every check this repo added upstream was on borrowed time.

## Acceptance

*Copied verbatim from [issue #416](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/416)
(`## Acceptance`), fetched 2026-08-05. Deviations, if any, are recorded below this block.*

- [ ] `tier1` is green on `development`.
- [ ] Every check this repo owns lives outside `utils/pdda/**`, so a future sync cannot delete it.
- [ ] Each restored check has a test that fails when the check is removed or stops detecting — not merely one that asserts a clean exit.
- [ ] The `utils/pdda/**` path-integrity exemption is documented with its reason at the point of exemption.
- [ ] A stated policy for what happens the next time a PDDA sync lands: how the diff is reviewed for deleted local behaviour, rather than trusting a green-after-fixups suite.

## Acceptance — deviations from the issue

**No criterion is altered, dropped, or added.** Criteria 1–4 were verified met on 2026-08-05 before
this doc was written; the lane's write-set covers criterion 5 only.

This is scope, not deviation: the definition of done is unchanged, and four parts of it are already
satisfied. Recorded here rather than left implicit, because a reader comparing this doc's write-set
to its acceptance block would otherwise see a gap and wonder which is wrong.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | The sync-review policy, in a **repo-owned** file the sync cannot replace: how a PDDA sync diff is reviewed for deleted local behaviour, what must be checked before it is landed, and why a green-after-fixups suite is not evidence. Names the `utils/pdda/**` boundary and the `pdda-local-checks.sh` seam explicitly. | `PROJECT/PDDA-SYNC-POLICY.md`, `AGENTS.md` | 1/1/2 |

**Placement is load-bearing.** `PROJECT/PDDA.md` is sync-managed (`utils/pdda/PDDA-SOURCE.md:12`
names it as a canonical path). Writing a policy about surviving syncs into a file the sync replaces
would be this incident restaged, so the doc is repo-owned and `AGENTS.md` points at it.

## Litmus tests

- **The policy must be discoverable from where the work happens.** A doc nobody is routed to is the
  same failure as a check nobody runs (#368, a sibling lane). `AGENTS.md` or `ROUTER.md` must
  reference it, or the deliverable is a file, not a policy.
- **It must say what evidence is insufficient.** "Suite is green after fixups" was the reasoning that
  failed here. A policy that does not name that specific insufficiency has not learned from this.
- **It must not live under `utils/pdda/**` or `PROJECT/PDDA.md`.** Mechanically checkable and worth
  checking.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "PROJECT/PDDA-SYNC-POLICY.md" },
    { "type": "grep_absent", "path": "AGENTS.md", "pattern": "PDDA-SYNC-POLICY" }
  ],
  "artifacts":     [ "PROJECT/PDDA-SYNC-POLICY.md", "AGENTS.md" ],
  "artifacts_new": [ "PROJECT/PDDA-SYNC-POLICY.md" ],
  "remediation":   { "source": "issue#416", "criteria": "criterion 5 only — a stated review policy for the next PDDA sync; criteria 1-4 shipped in PR #413. Ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): both probes assert the pre-fix state —
`path_absent` reports `landed` when the path *exists*, `grep_absent` when the pattern *is found*.
Verified 2026-08-05: neither the policy doc nor the `AGENTS.md` reference exists.

**The gate is `bash validate.sh` even though this is a docs lane**, because `pdda.sh run`'s
path-integrity check reads links in `AGENTS.md` and a broken pointer would be a silent failure of the
one criterion this lane exists to satisfy.

## Method note

Criteria 1–4 were verified by direct inspection on 2026-08-05 (file existence, `validate.sh` and
`ci.yml` wiring, `grep` for an existing policy) rather than inferred from the issue's *"What has been
done"* section — which describes the PR's intent, not the merged result. Criterion 5's absence was
confirmed by searching every root and `PROJECT/` markdown file for a sync-review policy; the only
matches are narrative mentions in `CHANGELOG.md` and `ROADMAP.md`.
