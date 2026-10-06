# Final review blocked

The third/final review found no code blocker but relay-drive exited4 and refused terminal attestation with `review-body-rewritten`. The producer had appended its round3 brief below the pre-existing append marker. The reviewer inserted its review above that marker, before the producer brief; the protected review body therefore changed. This was a producer packaging error, not a code defect or approval. No final3 attestation exists. Prior round2 approval predates the GH920 selection change and cannot cover it. No push, PR, merge or qualification count follows this rejected review.

The start-task binding three-round budget is exhausted. Preserve candidate and all receipts. Operator decision required for one additional protocol-correct review attempt; no self-attestation or reset budget. Next after valid approval: mandatory full push gate, exact-head hosted result, ready PR, then separate landing authority.
