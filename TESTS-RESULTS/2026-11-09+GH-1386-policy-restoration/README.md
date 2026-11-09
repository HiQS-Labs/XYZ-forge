# Restore the original promotion policy

This change restores the exact policy bytes retained before the bounded #1386 trial. It is prepared and qualified ahead of time, and stays unmerged until the real trial finishes or the original batch cutoff requires closeout. It creates no runner, schedule, cleanup or promotion dispatch.

The restored file matches original-policy.json byte for byte. Full registry qualification of this PR is separate from the real batch sweep and is not counted as a workload or speedup result. Source/runtime repairs that land meanwhile remain owned by development; this PR changes only the policy and its evidence.
