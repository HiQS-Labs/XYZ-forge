# GH-1314 — historical verifier calibration: inconclusive before candidate execution

The one approved run stopped during supervisor preconditions, before any of the eight
candidate status/init commands. This is **not passing calibration evidence**.

- Setup and helper elapsed: **1.510037899017334 seconds** of the 600-second envelope.
- Both historical standalone clones were created and checked out successfully.
- Helper exited **2**: `HOME/TMPDIR must start empty`.
- Candidate commands: **0/8**. Both control classifications and replay remain **unverified**.
- No `outcome.json` was produced; `inconclusive.json` rejects acceptance.
- No retry, changed expectations, tick, actor repair, model call or full suite.

After stop, owned HOME was empty; owned TMPDIR contained `xcrun_db` (491 bytes).
Its stat/hash is retained in `post-stop-owned-environment.json`. This is a post-stop
observation, not proof attributing its creation to a specific setup command. A setup
command/environment mismatch is a hypothesis for separate review, not repaired here.

## Evidence and replay

`launch.sanitized.json` retains all four setup command results and the helper result,
including complete stdout/stderr and exit codes. `config.sanitized.json` retains the
frozen identities and absolute deadline. `helper.txt` is the exact approved helper;
`PROTOCOL.sanitized.md` is a path-sanitized derivative of the frozen protocol. The raw
protocol hash and exact helper hash are in `provenance.jsonl`; original raw protocol,
launch/config, both clones and owned runtime state remain locally retained. The hash
manifest identifies these published derivatives. No candidate output/state inventory,
Python/SQLite identity receipt or semantic result exists: preconditions stopped first.

Source comparison: bad `b78df4b93049498b19dd47fe6a90d006f9c42700`, good
`47deab48b8c749d699c6b6c77c38dfdaa5682025`. Requirements and commands are fully described
in the protocol; repeating requires a new explicitly approved run, not an automatic retry.

## Limits and next decision

Same-user evidence separation is supervised, not immutable. Inventories cover declared
paths only; process groups do not prove containment of new-session descendants. This
run establishes only that setup completed and the empty-environment precondition refused.
It establishes neither semantic calibration nor general verifier safety. Review setup
isolation/dependencies before proposing a separately approved replacement experiment.
