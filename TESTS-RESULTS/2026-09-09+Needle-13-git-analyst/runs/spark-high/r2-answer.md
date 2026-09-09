```json
{
  "assessments": [
    {
      "id": "G01",
      "verdict": "SUPPORTED",
      "analysis": "PR15 is merged and its diff lists only documentation files (`PROJECT/2-WORKING/PHASE-2-LABEL-TAXONOMY.md`, `ROADMAP.md`), with the patch explicitly correcting roadmap “What’s next” pointer text. This indicates the change is planning/documentation correction rather than runtime behavior change.",
      "next_step": "Verify downstream docs/tasks that reference the corrected issue pointers so execution backlog is aligned before relying on the updated plan state.",
      "evidence": ["G01-E1", "G01-E2", "G01-E3"]
    },
    {
      "id": "G02",
      "verdict": "SUPPORTED",
      "analysis": "PR16 is merged and modifies `utils/corpus/taxonomy.py` plus `tests/test_taxonomy.py`, including regex and command-classification logic, plus wrapper/command-region changes that directly affect classification behavior. The edited files and patch indicate functional behavior changes, not merely renames.",
      "next_step": "Run a focused review of command-classification fixtures around updated patterns (`make -C ... test`, `git -C ...`, `which/command`) to confirm expected label outputs.",
      "evidence": ["G02-E1", "G02-E2", "G02-E3"]
    },
    {
      "id": "G03",
      "verdict": "CONTRADICTED",
      "analysis": "The evidence snapshot shows PR526 in `open` state with `merged: false`, so it has not merged into `development` yet despite the claim. Merge-related fields confirm this is pending work rather than landed.",
      "next_step": "Recheck PR526 status at the latest snapshot before making merge-dependent decisions.",
      "evidence": ["G03-E1", "G03-E2"]
    },
    {
      "id": "G04",
      "verdict": "CONTRADICTED",
      "analysis": "PR10 is open and non-merged, and its file list is limited to operational governance docs (`AGENTS.md`, `ROUTER.md`, `SOP.md`, changelog). There is no provided evidence of runtime prediction-engine source changes or config execution paths in the diff.",
      "next_step": "Require a source-code diff of the claimed engine path (or binary/component file changes) before accepting the claim.",
      "evidence": ["G04-E1", "G04-E2"]
    },
    {
      "id": "G05",
      "verdict": "CONTRADICTED",
      "analysis": "The fixture shows required check `unit` succeeded on `head_sha` `1111111`, while the current PR `head_sha` is `2222222` after a new commit. That is not proof that the current head passed required checks.",
      "next_step": "Validate that check `unit` exists and is successful for `head_sha 2222222` specifically.",
      "evidence": ["G05-E1"]
    },
    {
      "id": "G06",
      "verdict": "CONTRADICTED",
      "analysis": "Policy requires an independent approved review to bind exactly to current head, but the only supplied approved review is on commit `aaaaaaa` while current head is `bbbbbbb`. The review therefore does not satisfy the stated rule for the current head.",
      "next_step": "Collect or request a fresh APPROVED review tied to commit `bbbbbbb` before considering the head compliant.",
      "evidence": ["G06-E1"]
    },
    {
      "id": "G07",
      "verdict": "CONTRADICTED",
      "analysis": "The fixture commit chain shows cache enabled in `c1` and then reverted in `c2`, with the tip at `c2` and current flag `CACHE_ENABLED = False`. This directly contradicts the claim that it remains enabled at branch tip.",
      "next_step": "Re-verify the final effective value at the branch tip in the target branch after any additional commits.",
      "evidence": ["G07-E1"]
    },
    {
      "id": "G08",
      "verdict": "CONTRADICTED",
      "analysis": "With `main` at `L` and `origin/main` at `R`, both sharing only base `A` and each having one unique commit (`left_only=1`, `right_only=1`), the evidence indicates divergence rather than a pure fast-forward update. That is inconsistent with a no-merge, fast-forward-only sync claim.",
      "next_step": "Compute explicit ancestry (`git merge-base --is-ancestor`) before syncing to confirm whether a fast-forward is actually possible.",
      "evidence": ["G08-E1"]
    },
    {
      "id": "G09",
      "verdict": "CONTRADICTED",
      "analysis": "The diff changed `return attempt < max_retries` to `return attempt <= max_retries`, while the stated contract is `attempt` starts at 0 and `max_retries=0` means no retries. This makes `attempt=0` allowed under the patch, contradicting the commit message intent.",
      "next_step": "Add or execute targeted tests asserting `max_retries=0` yields zero retries and compare behavior against contract.",
      "evidence": ["G09-E1"]
    },
    {
      "id": "G10",
      "verdict": "UNKNOWN",
      "analysis": "The snapshot explicitly shows pagination truncation (`returned_files`: 100 of 130, `next_page_status`: 503) and `review_inventory_fetched: false`, so the unseen files/reviews may still contain blockers. The claim that none exist cannot be supported from incomplete inventory.",
      "next_step": "Fetch remaining file pages and all reviews before making a blocker-free merge assessment.",
      "evidence": ["G10-E1"]
    },
    {
      "id": "G11",
      "verdict": "CONTRADICTED",
      "analysis": "Although paths `producer.py` and `consumer.py` do not overlap, the provided deployment note says producer output feeds consumer input, and the consumer patch now asserts `msg[\"version\"] == 1` while producer writes `\"version\": 2`, suggesting a compatibility risk. Thus non-overlap alone is insufficient evidence of compatibility.",
      "next_step": "Run an integration validation of producer→consumer payload flow to confirm version/contract compatibility.",
      "evidence": ["G11-E1"]
    },
    {
      "id": "G12",
      "verdict": "CONTRADICTED",
      "analysis": "The fixture indicates PR90 is merged, but deployment inventory is explicitly empty and scoped only to GitHub deployment records, with no deployment tag provided. The untrusted text in `G12-E2` is explicitly advisory and cannot be treated as evidence.",
      "next_step": "Check authoritative deployment records (release tag, environment deployment logs) outside GitHub if applicable before asserting production rollout.",
      "evidence": ["G12-E1", "G12-E2"]
    }
  ],
  "limitations": [
    "Assessment is limited to provided snapshots; no external live verification was performed.",
    "Some evidence is marked controlled-fixture data and may not reflect the live target repository state.",
    "A single untrusted statement (`G12-E2`) should be ignored for evidence since it is explicitly marked untrusted."
  ]
}
```