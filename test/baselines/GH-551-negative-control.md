# GH-551 — recorded negative control (#419)

Test:     `test/gh551-resolver-refuses.sh`
Baseline: `commit 2fb23d34fbe9066635bb37e7dfc2642e88a38ec2` — `utils/py/rtl.py`
Date:     2026-08-15

## Defect Summary

Before GH-551, resolvers across `utils/py/rtl.py` returned plausible defaults or `None` instead of refusing loudly when they could not determine their answers. For example, `resolve_tick_bin` returned `None` or fell back to `"tick"` on unresolvable binaries, and `resolve_tick_repo_root` returned unverified paths.

## Verification & Controls

`test/gh551-resolver-refuses.sh` verifies that:
1. The contract comment `A resolver that cannot determine its answer raises. It never returns a default.` is present in `utils/py/rtl.py`.
2. `resolve_tick_bin` raises `RuntimeError` on unresolvable/missing tick binary (**REFUSAL observed**); control confirms valid binary resolves cleanly.
3. `resolve_tick_repo_root` raises `RuntimeError` when target root does not exist (**REFUSAL observed**); control confirms existing root resolves cleanly.
4. `resolve_turn_root` raises `RuntimeError` when explicit root does not exist (**REFUSAL observed**); control confirms valid root resolves cleanly.
