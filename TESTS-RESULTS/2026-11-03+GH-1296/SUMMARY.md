# GH-1296: launch packets name the lanes preflight would refuse

- **Change:** `utils/py/harness.py`. `make_packet` now checks each emitted lane read-only for the two refusals the #1279 window hit: no Preflight Contract (preflight exit 3), and a contract artifact missing from the frozen file list at `target.ref` (artifacts in `artifacts_new` are exempt, as in `swarm_preflight.py`). A flagged lane keeps its folder but its README entry says **Not launchable yet** with the reason and drops the `cp` / dry-run commands. The command's JSON gains `not_launchable`.
- **Manual check (red/green, no test file, GH-831).** Same instance, same ticks; only `packet --wave 1` was rerun after the edit (`init --from-prs --limit 10 --unregistered 5`, slots 1-15, Python 3.13).

| Lane | Before: README | After: README | Live `swarm-preflight --dry-run` |
|---|---|---|---|
| #670, #1267, #1265, #1266 | launch commands | launch commands | ready (rc 0) |
| #1204, #216, #446 | launch commands | **Not launchable yet** | rc 3, no Preflight Contract heading |
| #1175, #1317, #1315 | launch commands | **Not launchable yet** | no capture doc in this checkout; not run |
| #1265 with `skills/consult/SKILL.md` moved (control doc here) | n/a | blocker on that path | rc 5, "artifact path not found at target.ref" |

  `launch-README-before.md` vs `launch-README-after.md` is the red/green pair; `live-preflight-verdicts.txt` and `gh1296-check-output.txt` hold the rest.
- **A false positive was caught and fixed by this comparison.** The first version flagged #670 (`test/gh670-claude-reviewer.sh` absent) while live preflight said ready: that file is in the contract's `artifacts_new`. The check now skips `artifacts_new`.
- **Not done:** the contracts for #1204, #216, #446 were not authored. #1204 is a five-phase plan, #216 was reported from LTVera-Pandas against the retired `ROADMAP.md` format, and #446 needs a choice between `--write` and a default change. Those are owner decisions on their own issues; the lanes now say "not launchable" until they exist. #722 (the stale-path case) is closed and no longer a candidate.
- **Limits:** the check mirrors only these two refusals, not stale `fix_probes` or the other preflight conditions. One wave, one date; the ledger and open issues move. The live artifact-path refusal was exercised only with the control doc, not a real lane.
- **Environment note:** `packet` needs Python 3.11+ (`contextlib.chdir`). The default `python3` on this Mac is 3.9 and fails there with `AttributeError`; not changed here.
