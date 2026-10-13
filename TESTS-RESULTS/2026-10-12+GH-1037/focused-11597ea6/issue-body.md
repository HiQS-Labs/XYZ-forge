The GH-1012 exact-candidate review reproduced two sync ownership defects on development 2f8969a292e8dd230ab69ab9fe4ddc96a898ab55. The operator explicitly authorized only these fixes, verification and the corrected Forge release merge.

1. Entire adapted entries deliberately deleted by a child reappear on the second subsequent mini publication. Ownership currently disappears when no file survives. Preserve entry ownership in the existing manifest independently of surviving files; keep deliberate upstream removal/re-add behavior.
2. Updating the Skills Army manager README leaves both manager and installer-owned root README dirty. The skill-only auto-commit mistakes the refreshed root README for unrelated dirt and blocks Git Pulse. Admit only a clean pre-transaction owned mirror changed by this manager update; preserve refusal over unrelated dirt and the pulse's sole push ownership.

Evidence: https://github.com/HiQS-Labs/XYZ-forge/pull/1036#issuecomment-6132835261 and supporting receipt draft #1035. Existing checks and isolated recorded manual controls only; no new CI suite/case/parameter, provider pilot, installed-skill deployment, cap reset or gate bypass.

This child issue tracks implementation of the two approved findings; it does not update the separately blocked #1012 canonical issue/plan. #954 and #1024 deferred from this candidate, #930 held, #1033 separate. Preserve all other tasks and old clones. Require independent QA, exact final-head release regression/recovery and exact resulting-main MACOS-BOUNDARY green receipt before stable designation.
