# GH1216 workload plan QA for GH1358

Independent native Codex reviewer: /root/gh1216_workload_plan. Read-only review.

Approve with one correction: apply prefix normalization only to named profiles
(tier == 2). Tier1 explicitly promises to preserve manual AIDER_MODEL overrides.
The current CLI reproduction confirms the defect in emit_env.

Required evidence: unprefixed named Aider/OpenRouter profile gets one prefix;
already-prefixed profile, tier1 manual override, other gateways/lanes and raw JSON
remain unchanged. Witness pre-fix failure and repaired success using existing
`test/gh346-profile-resolve.sh` or recorded manual checks in a disposable full clone.
No provider execution, new suite, schema or routing abstraction.

Disposition: tier2 restriction included in issue acceptance and prepared contract.
This approves workload scope only, not discovery implementation, admission or full
qualification. Workload remains unadmitted until the current two-wake window ends.
