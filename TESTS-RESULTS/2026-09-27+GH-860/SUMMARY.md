# GH-860 — radar and whack-a-mole check CI churn against the repo's SOP

Skill text only: `skills/3-weekly/radar/SKILL.md` (Step 0 SOP detection, new Step 2c, Step 4 §2–3, Sink B,
guardrail, degradation rows, recital item 3) and `skills/3-weekly/whack-a-mole/SKILL.md` (§2 CI churn
pre-check, §3 signal 6, §4 `CI-shaped` flag and E5 rule, §6 `## CI churn — SOP status`, §7 report line).
The shared text (SOP detection, E1–E8, declaration rule, the four wordings) lives once, in radar Step 2c;
whack-a-mole references it. The Cluster signature block is unchanged.

| Check | Result |
|---|---|
| `bash test/gh779-radar-ci-health.sh` (unregistered, by hand) | 20 pass, 0 fail |
| `bash test/gh781-wam-radar-seed.sh` (unregistered, by hand) | 17 pass, 0 fail |
| `utils/pdda/pdda.sh run` | 0 errors |
| `test/path-integrity.sh` | pass |

**Not run:** the issue's three hand replays (SOP-draft, run-4, no-SOP). The operator directed minimum ceremony
for the #854 window; the first real radar run exercises Step 2c. Until the window lands, radar on `development`
detects `SOP: #857 (draft, not landed)`, because the SOP doc is on the staging branch only.

Landed on `staging/stabilize-2026-10` per the operator's 2026-09-27 direction, which supersedes #860's
"normal path" note. The capture doc and ledger row go into the landing ledger commit.
