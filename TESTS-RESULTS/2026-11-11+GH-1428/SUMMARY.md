# GH-1428 verification receipts (2026-11-11)

Manual checks for #1428. No suite or registry entry was added (GH-831). Code under test:
`6381d9af8` (fix) vs `0f21b761a` (base). Paths in logs are redacted to `<clones>`, `<scratch>`
and `<path>`.

| Check | Command / script | Result |
|---|---|---|
| Focused existing suites (disposable `-verify` full clone of `6381d9af8`) | `bash test/{gh505-relay-attest,gh681-reviewer-probe-rules,gh268-relay-cue-and-target-checks,debug-mantra,relay-pkg-freshness}.sh` | all rc=0: 63, 27, 34, 17, 3 PASS, 0 fail (`focused-*.log`) |
| **Red control, acceptance 2** (real GH-955 builder + reviewer blocks, `gh955-*.md`) | `gh1428-red-control.sh <clone> 0f21b761a 6381d9af8 …` | base attests the pair (rc 0, the bug). Fix armed: refuses with `unverified-approval` when undeclared, `no`, `yes — exit 1`, `exit 124`, or `yes` without an exit. `yes — exit 0` attests with `gate_run: yes`. Unarmed generic relay attests as today with `gate_run: undeclared` (`red-control.out`) |
| Attestation record compatibility | `load-check.out` (python, `relay_attest.load` on the records above) | new record loads; legacy record (no field) loads; invalid value refused; valid-but-swapped value refused by trailer binding |
| **Render, acceptance 1** (main + adjacent shapes) | `gh1428-render.sh <verify-clone>`, `marathon-drive --dry-run` | GH-955 focused and node-selector gates get the run-the-gate 3a step. Default, unscoped `python3 -m pytest`, file+dir, compound, and GH-54-fixture brief get the harness-only step. The builder `unverified:` line and the tooling-only fallback wording are rendered (`render.out`) |
| Selector containment (final QA R1 fix) | `containment.out` (python, `reviewer_runnable_gate` on inert files) | relative file and `::node` qualify. `../x.py`, an absolute path (even inside the target), a symlink escaping the target, a directory, and a missing file are harness-only. The pre-fix red (`../…` qualified) was witnessed by the final QA reviewer (`relay-system/2026-11-11/gh1428-final.codex.md`, R1) |
| **Codex localhost network, acceptance 3** | `python3 -m http.server --bind 127.0.0.1 <free port>`; `codex exec` (codex-cli 0.167.0-alpha.3.2) asked to `curl` it | default `-s workspace-write`: `curl: (7) Failed to connect` (red). With `-c sandbox_workspace_write.network_access=true`: `GH1428-OK` (`codex-network/`) |

Not measured here: a live reviewer turn running a real DB-backed gate (the render establishes the
instruction, not the source revision a real run imports). The next DB-backed Jog item is the field
signal (CHANGELOG).
