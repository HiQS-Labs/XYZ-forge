# Lane brief — GH-205: realistic turn-timeout + per-lane override + no false HALT on a done turn

Execution surface of record: `PROJECT/1-INBOX/GH-205-TURN-TIMEOUT-FALSE-HALT.md`
(issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/205)

## Task

A builder turn that already produced + committed its artifact with a green gate can still be
killed at `relay-automation/codex-turn.sh:131`'s `RELAY_TURN_TIMEOUT_S` default (300s), classified
exit 7, and HALT the whole marathon — the reviewer round never runs.

1. Raise the shim default (`codex-turn.sh`, and the same default in `agy-turn.sh`) to 900s;
   keep the `RELAY_TURN_TIMEOUT_S` env override.
2. Add per-lane `turn_timeout_s:` to the MARATHON.yaml schema: parse in `bin/marathon-yaml`,
   plumb through `relay-automation/marathon.sh` into the lane's drive env as
   `RELAY_TURN_TIMEOUT_S`.
3. In the drive/halt classification: on exit 7, if the lane's declared artifact(s) exist and the
   pre-advance gate passes, proceed to the reviewer round instead of HALT. A true hang (no
   artifact, or red gate) still HALTs.
4. Document `RELAY_TURN_TIMEOUT_S` and `turn_timeout_s:` in `relay-automation/README.md` and
   `relay-automation/MARATHON.example.yaml`.

## Definition of done

- `test/marathon-yaml.sh`: `turn_timeout_s:` parses and defaults correctly.
- `test/marathon.sh`: per-lane value reaches the shim env.
- `test/codex-turn.sh` / `test/marathon.sh`: exit-7 with artifact present + gate green advances to
  review; exit-7 with no artifact still halts.
- `bash validate.sh` green.
