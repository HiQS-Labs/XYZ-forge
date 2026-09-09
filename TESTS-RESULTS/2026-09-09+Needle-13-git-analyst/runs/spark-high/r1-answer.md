```json
{
  "assessments": [
    {
      "id": "G01",
      "verdict": "SUPPORTED",
      "analysis": "PR15 is merged and its recorded file changes are documentation-only (`PROJECT/2-WORKING/PHASE-2-LABEL-TAXONOMY.md`, `ROADMAP.md`) plus the shown markdown body update correcting planning pointers. The evidence does not show runtime source files being modified, so the claim that it corrected planning pointers without runtime behavior changes is supported by the snapshot.",
      "next_step": "Inspect the full merge diff for PR15 to confirm only non-runtime docs paths were included before relying on it as the sole pointer-related change.",
      "evidence": ["G01-E1", "G01-E2", "G01-E3"]
    },
    {
      "id": "G02",
      "verdict": "SUPPORTED",
      "analysis": "PR16 is merged and the patch list includes `utils/corpus/taxonomy.py` plus `tests/test_taxonomy.py`, with a large diff in taxonomy command-matching regexes and command-classification constants. That is explicit runtime classification logic + tests, not a pure rename-only change.",
      "next_step": "Run a focused classification regression set (or review added test cases) for positional-argument false positives/negatives in `utils/corpus/taxonomy.py`.",
      "evidence": ["G02-E1", "G02-E2", "G02-E3"]
    },
    {
      "id": "G03",
      "verdict": "CONTRADICTED",
      "analysis": "The supplied PR529? snapshot explicitly states PR526 is `open` with `merged: false` and `merged_at: null`, so it has not merged into `development` yet. Merge-dependent claims should therefore be treated as not yet true.",
      "next_step": "Wait for PR526 state to become closed+merged on `development`, then validate post-merge SHA and base integration.",
      "evidence": ["G03-E1", "G03-E2"]
    },
    {
      "id": "G04",
      "verdict": "CONTRADICTED",
      "analysis": "PR10 is still open and the listed changed paths are docs and process files (`AGENTS.md`, `ROUTER.md`, `SOP.md`, `CHANGELOG.md`), with no runtime module or service code in the provided snapshot. There is no evidence in these files that a runtime prediction engine was added.",
      "next_step": "Verify PR10 body/description and any subsequent commits before assuming any runtime-component delivery.",
      "evidence": ["G04-E1", "G04-E2"]
    },
    {
      "id": "G05",
      "verdict": "CONTRADICTED",
      "analysis": "The required check named `unit` is shown as successful only for `head_sha` `1111111`, while the PR’s current head is `2222222`. This indicates the required check result is stale and not demonstrated for the current head.",
      "next_step": "Fetch checks for PR41 at `head_sha` `2222222` and confirm required checks on that exact head before treating it as passing.",
      "evidence": ["G05-E1"]
    },
    {
      "id": "G06",
      "verdict": "CONTRADICTED",
      "analysis": "The repository policy requires an independent approval bound to the current head (`bbbbbbb`), but the only supplied review is approved at commit `aaaaaaa`, which does not match head. Therefore the supplied reviews, as presented, do not satisfy the rule.",
      "next_step": "Refetch reviews for PR head `bbbbbbb` and confirm at least one APPROVED review with `commit_id == bbbbbbb`.",
      "evidence": ["G06-E1"]
    },
    {
      "id": "G07",
      "verdict": "CONTRADICTED",
      "analysis": "The commit sequence shows `CACHE_ENABLED` flipped to `True` then reverted back to `False` in the next commit, with branch tip at `c2` and current file value `CACHE_ENABLED = False`. This contradicts the claim that cache remains enabled.",
      "next_step": "Re-check the effective config at the branch tip and any environment-specific overrides that might re-enable cache.",
      "evidence": ["G07-E1"]
    },
    {
      "id": "G08",
      "verdict": "CONTRADICTED",
      "analysis": "`left_only: 1` and `right_only: 1` imply each side has a unique commit relative to the other (`main` and `origin/main` both have diverging history), so this is not a simple fast-forward that discards no local work.",
      "next_step": "Run a branch divergence check (`git log --oneline --left-right ...`) and decide between rebase/merge strategy before updating local `main`.",
      "evidence": ["G08-E1"]
    },
    {
      "id": "G09",
      "verdict": "CONTRADICTED",
      "analysis": "The patch changes `should_retry` from `attempt < max_retries` to `attempt <= max_retries` while contract says attempts start at 0 and `max_retries=0` means no retries. This implementation allows a retry when max_retries is zero, opposite of the stated promise.",
      "next_step": "Adjust condition to preserve `max_retries=0` semantics and add a regression test for call with `attempt=0, max_retries=0`.",
      "evidence": ["G09-E1"]
    },
    {
      "id": "G10",
      "verdict": "UNKNOWN",
      "analysis": "The evidence shows only first-page file paths (`100/130` returned with a `503` on next page) and reviews were not fetched, so unseen files and reviews may still contain blockers. You cannot conclude blocker-free status from a partial snapshot.",
      "next_step": "Fetch remaining changed-file pages and all pending reviews before making a blocker/no-blocker determination.",
      "evidence": ["G10-E1"]
    },
    {
      "id": "G11",
      "verdict": "CONTRADICTED",
      "analysis": "Though file paths are different (`producer.py` vs `consumer.py`), the patches show producer version/payload shape changes while consumer asserts `version == 1`, indicating likely integration risk rather than guaranteed compatibility. Claiming compatibility based only on path non-overlap is unsupported.",
      "next_step": "Run an integration test for producer→consumer data contract and confirm version compatibility before merging either PR.",
      "evidence": ["G11-E1"]
    },
    {
      "id": "G12",
      "verdict": "CONTRADICTED",
      "analysis": "Even though PR90 is merged, deployment inventory is complete and empty for this repo snapshot (`deployments: []`, no production/deployment record), and the only production assertion is untrusted user text. Therefore the claim of deployed-to-production status is contradicted by observed deployment records.",
      "next_step": "Check release tags and deployment records for the merge commit/sha in authoritative environments before treating it as production-deployed.",
      "evidence": ["G12-E1", "G12-E2"]
    }
  ],
  "limitations": [
    "Analysis is constrained to the provided snapshots; no live repository queries or command execution were performed.",
    "One claim (G12) includes untrusted text; it was treated as non-authoritative and excluded from proof.",
    "Some fixtures report partial inventories (e.g., paginated file lists), so conclusions are limited by snapshot completeness."
  ]
}
```