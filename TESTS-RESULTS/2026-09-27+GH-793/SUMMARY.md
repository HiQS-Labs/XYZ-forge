# GH-793: gh492 idle-kill fails under the parallel gate, passes alone

Base `bc0a291e`. Fix `067f7253`, rebased unchanged onto the staging tip.

## Root cause (reproduced deterministically)

`TurnDiagnostics` takes each sample by running `ps -axo …` and `pgrep`. After 3 idle-looking samples it also runs one `lsof` network probe, with a 5 s timeout. The test compressed real timescales to a 0.2 s interval, a fixed 4 s (or 3 s) window and a fixed 1.0 s bound. Under the gate's process churn those tools slow down, so:

- **Few samples:** the window held too few samples, and the blocked turn classified `timeout-unclassified` instead of `timeout-idle-unknown`.
- **Stale progress:** the progressing turn's last observed progress landed early.
- **Late read:** `idle_seconds()` was read only after `stop()`, which joins each sampler for up to 2 s, and after the kill. That post-window time counted as idle, giving `CONTROL FAILED: … idle=6.81s`.

Evidence (`slow-tools-repro.sh.txt`, which puts `PATH` shims in front that delay `ps`, `pgrep` and `lsof`, then runs gh492 unchanged):

| Tool delay (`ps`/`pgrep`, `lsof`) | Base `bc0a291e` | Head `067f7253` |
|---|---|---|
| 0.5 s, 1 s | 14/16: **`CONTROL FAILED … idle=2.85s`** | **16/16** |
| 1 s, 3 s | 11/16: **`got timeout-unclassified`** | **16/16** |
| 1.5 s, 6 s | 10/16 | 15/16. The only failure is `lsof` running past its own 5 s probe timeout, where the product reports `unclassified` by design (see *Limit*) |

CPU saturation alone does not reproduce it: 5 of 5 green at base under 2×ncpu busy loops (`cpu-load-attempt.sh.txt`). The trigger is slow process-table tools, not busy CPUs. The same class was seen in `gh610` on hosted run 36087662555 ("never established a safe idle window … samples=3").

## Fix (test only; `utils/py/turn_diagnostics.py` is unchanged)

1. **Windows are measured in samples as well as seconds.** Each run lasts at least 4 s (3 s for consult) **and** until each sampler has `IDLE_MIN_SAMPLES + 1` samples, with a hard cap of 30 s. On a fast host it is unchanged.
2. **Idle is read when the window closes,** before `stop()` and the kills.
3. **The two "not idle" bounds scale to what the sampler can resolve.** Progress is only visible at a sample. So the progressing-turn control and the shared-parent consult check allow `max(1.0 s, 2 × the largest sample gap actually observed)`. On a fast host that is still 1.0 s. The blocked-turn checks (`≥ 1.0 s`), the separation check (blocked > progressing + 0.5 s) and all classification checks are unchanged.

## The checks still bite (mutations of `turn_diagnostics.py`, restored after)

- The product ignores file progress: **`CONTROL FAILED … idle=4.08s`**.
- The product ignores `root_pid` scoping: **`FAIL: CONSULT: a hung advisor reported idle=0.05s even when correctly scoped`**.

## Runs

`bash test/gh492-idle-kill.sh` at head: 5 of 5, 16 pass, 0 fail.

## Limit (documented, not weakened)

If `lsof` itself exceeds its 5 s timeout, the product cannot attribute the blocked turn and reports `timeout-unclassified`. That is correct degradation, so the test still expects `timeout-idle-unknown` and will fail on such a host. That is only seen here at the extreme 1.5 s / 6 s shim level. If a real gate reaches it, the fix is a product decision about the probe timeout, not a looser test.

**Route:** `changed_tests=gh492-idle-kill.sh`, `tier=3` (a test changed). Under #854 D2 that obligation is paid at the window's landing.
