---
Goal: Independent plan QA (pre-fire) for marathon #1214 — five member plans + MARATHON.yaml
Date: 2026-10-25
NEXT: Reviewer
STATUS: Open
---

# Context

You are the independent plan reviewer (GH-784 Wave Plan QA, `/start-task` step 6 parity) for a marathon that has **not fired yet**. One strict chain of five lanes; builder `agy`, post-build reviewer `codex`; default per-phase gate `bash validate.sh`.

Operational envelope: local developer harness (Bash + stdlib Python, one operator). Commensurate complexity; no enterprise fail-safes. **GH-831 D7:** a new `test/` suite, `validate.sh` registry entry or gate machinery (guards, lanes, runners, telemetry stages) is itself a finding — do not ask for one. Verification is existing suites + manual checks under `TESTS-RESULTS/`.

Read in full:
- `PROJECT/2-WORKING/GH-1214-LESSONS-READBACK/CAPTURE.md` and `MARATHON.yaml`
- `PROJECT/2-WORKING/GH-1222-RELEASES-LIVE-MANIFEST-COUNT.md` (p1)
- `PROJECT/2-WORKING/GH-1221-IMPROVE-LOOP-BUILD-CAN.md` (p2)
- `PROJECT/2-WORKING/GH-1219-CONSULT-BLIND-B-RECONCILE.md` (p3)
- `PROJECT/2-WORKING/GH-1218-LESSONS-READ-BACK-EVIDENCE.md` (p4)
- `PROJECT/2-WORKING/GH-1220-MARATHON-RESUME-REUSES-PHASE.md` (p5)

and the code each one cites (verify every `file:line` claim you rely on).

Questions:

1. **Write-sets.** For each phase, is the declared `artifact` / contract write-set sufficient to complete the plan *and* pass `bash validate.sh` without a containment revert (exit 6)? Name any file the builder will predictably have to touch that is missing (e.g. a package tarball, a suite whose pinned assertion becomes untrue, a vendored copy), or any entry that is unnecessary.
2. **p1 #1222.** Is `COUNT(DISTINCT issue_ref_id)` correct for both `_live_manifest_count` and migration 004's backfill (`utils/py/releases_app.py` ~2517-2533, ~824-833)? Any caller relying on the old count?
3. **p2 #1221.** Is the snapshot/compare/restore design in `relay-automation/improve-loop.sh` sound and minimal? Does it handle the default `STATE_DIR`, ignored paths and pre-existing dirty files without false positives? Any bash-3.2 or `-z` parsing pitfalls the plan should name?
4. **p3 #1219.** With `consult.sh` frozen and execing `consult.py` by default, is the Python-only change + skill text complete? Will the neutral-payload stripping hit every identity source (attestation, stamps, banners)?
5. **p4 #1218.** Is `rtl_turn_prompt` (`relay-automation/relay-turn-lib.sh:995`) truly the single point every shim (incl. SmallCode) reaches? How should the reader resolve `LESSONS-LEARNED.md` (RTL_ROOT vs git toplevel) so it is silent in vendored repos without the file? Will the added block break any prompt-pinning suite?
6. **p5 #1220.** Is passing `MARATHON_CONFIG_SHA256` by environment from `marathon_drive` to its relay-drive child sound (does the env reach `relay_drive.py` through `relay-drive.sh`)? Is the identity tuple computable at both write and compare time? Does legacy-accept keep `jog` and existing attestation suites green?
7. **Order and coupling.** Is the chain order p1→p5 right, given p4/p5 modify code the running driver uses? Any cross-lane dependency the order violates?
8. **Over/under-engineering.** Anything to cut, or anything missing that would make a phase fail its gate?

Flag anything wrong, missing, mis-scoped, or over/under-engineered. Cite `file:line`. Every `[Blocker]` or `[Should]` requesting a change MUST carry `Observed input:`, `Affected scope:`, `Falsifier:` lines (GH-681); a `[Blocker]` must cite an observed failure. Write your verdict in one reviewer block below and set `STATUS: Approved` if the plans may fire as written, otherwise hand back with `STATUS: Changes requested`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
