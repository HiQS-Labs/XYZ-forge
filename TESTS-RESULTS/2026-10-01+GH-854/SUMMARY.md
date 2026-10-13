# GH-854 retained local qualification evidence

One clean 4-wide development run qualifies; the October 1 attempt is excluded. Both tested development `57bd97af4a0e8d456927e20b49d64b232d95f36d` in disposable full clones under caffeinate.

| Receipt | Outcome | Counts |
|---|---|---|
| local-qualification-1 | September 30: 414/414, zero retries, intact Git identity, clean envelope | Yes, 1/3 |
| excluded-attempt-2 | October 1: 414/414 after xyz-completion retry; missing conc-1 after successful concurrent writers, identity intact, clean envelope | No |

Each directory retains original provenance, before/after identity, raw gate output, structured telemetry, archived raw pool logs and SHA-256 manifest. Local original evidence commits: `5b4c6e2a607e58489329c398e19997f02871f84d` and `24e3af0cd6024e0e5605f22293a6b9c848bb77da`. Archive member bytes are unchanged. This records evidence, makes no production fix or resolution claim, and leaves #854 and #853 open. The third organic PR-closed full-registry qualification is separately recorded on #854 (run36929882188). Publishing these receipts adds no new qualifying local run.

The four raw files in each directory were compared byte-for-byte with the original local evidence commit named above before copying. SHA-256 manifests were rechecked. Original provenance is retained unchanged; storage under October1 does not change the September30 run date.
