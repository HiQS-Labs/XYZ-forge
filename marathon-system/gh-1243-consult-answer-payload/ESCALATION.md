# ESCALATION — Marathon Phase gh-1243-consult-answer-payload

phase: gh-1243-consult-answer-payload
task: MARATHON-GH-1243-CONSULT-ANSWER-PAYLOAD-TURN
relay-drive-exit: 4
reason: cap-stalled
gate: not-run
relay-file: marathon-system/gh-1243-consult-answer-payload/RELAY.md

turn-log: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b1243-admission-gate-6x0bna0l/repo/relay-system/logs/2026-11-09/agy-turn-MARATHON-GH-1243-CONSULT-ANSWER-PAYLOAD-TURN-13677.log

<details>
<summary>Last 7 lines of failing turn log</summary>

```text
**Verdict:** Changes requested in [RELAY.md](file:///private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.ZMRllC/marathon-system/gh-1243-consult-answer-payload/RELAY.md#L129-L170) (`NEXT: codex (Builder)`).

### Summary of Round 1 Review (`agy`)
- **`[Blocker] R1` — Contract `fix_probes[0]` fails (`exit 1`)**: [`_neutralize_answer_text`](file:///private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.ZMRllC/utils/py/consult.py#L253-L317) does not strip Codex transcript preamble/exec logs/token footers when handed raw transcript text, causing [`TESTS-RESULTS/2026-11-10+GH-1386/consult-admission.py`](file:///private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.ZMRllC/TESTS-RESULTS/2026-11-10+GH-1386/consult-admission.py#L1-L2) (required by [`GH-1243-CONSULT-ANSWER-PAYLOAD.md`](file:///private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.ZMRllC/PROJECT/2-WORKING/GH-1243-CONSULT-ANSWER-PAYLOAD.md#L45-L50)) to fail with `AssertionError`.
- **`[Blocker] R2` — Requiring `--output-last-message` as the sole creator of `<label>.codex.md` and moving `consult_codex_attestation` off `<label>.codex.md` breaks existing stdout-only Codex test stubs**: [`run_one`](file:///private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.ZMRllC/utils/py/consult.py#L804-L813) and the post-run loop in [`consult.py`](file:///private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.ZMRllC/utils/py/consult.py#L919-L978) leave `<label>.codex.md` missing when stdout-only stubs in [`test/consult.sh`](file:///private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.ZMRllC/test/consult.sh#L20-L30) and [`test/gh308-consult-guards.sh`](file:///private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.ZMRllC/test/gh308-consult-guards.sh#L31-L60) run, and omit `> **ATTESTATION**` from `<label>.codex.md`. Both R1 and R2 can be fixed entirely inside [`utils/py/consult.py`](file:///private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/rtl-wt.ZMRllC/utils/py/consult.py) without expanding the scope lock.

handing off to codex — codex, take your turn.
```
</details>
