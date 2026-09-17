### ANSWER
The corrected findings are factually sound and perfectly aligned with the pasted evidence, successfully proving a systemic flaw in the idle oracle and divergent shim implementations.

### FINDINGS
**[Pass] F1: AGREE** — The four cited commits address isolated symptoms (e.g., GH-608 touching only `deepseek-turn.py`), and the pasted issue titles (#237, #241, #276, etc.) verify a shared timeout/idle trigger surface across multiple shims. 

**[Pass] F2: AGREE** — The `turn_diagnostics.py` docstring explicitly admits the missing network probe, proving the oracle cannot distinguish API waits from local stalls. Issue titles (#241, #242, #397, #480) confirm the divergent, per-shim aftermath handling.

**[Pass] F3: AGREE** — Verbatim code confirms `#285` has mitigation in `agy-turn.py` (`_kill_turn_group`) and `#521` delegates to `rtl_run_bounded` in `muse-turn.py` (lacking an idle-kill path), validating their placement in revalidate and investigate lanes. `#369` is accurately confirmed as closed.

**[Pass] F4: AGREE** — Standardizing on the existing `rtl_run_bounded` primitive (noted in closed issue #369) and making the `timeout-idle-no-progress` ambiguity non-destructive directly resolves the root causes while preserving valid provider-specific fixes like GH-114's PTY provisioning.

### RECOMMENDATION
**VERDICT: FILE-UMBRELLA** — Consolidate these systemic timeout/idle issues into a single umbrella to fix the network-blind oracle and unify the aftermath contracts.
