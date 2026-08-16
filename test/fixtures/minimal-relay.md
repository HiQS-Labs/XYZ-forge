# RELAY · self-sufficiency test

NEXT: agy
STATUS: In Progress

## ▶ TAKE YOUR TURN — read this first

You are the **Reviewer**, taking a single turn in this relay. No external files to read —
everything you need is in this file and in the prompt you received.

**Review criterion:** confirm that this relay file contains all three:
1. A `NEXT:` header line (top of file)
2. A `STATUS:` header line (top of file)
3. A `## Log` section (bottom of this file)

**Do this in order:**

1. **Claim the relay token** — use the exact `tick claim` command from your prompt. The
   `--paths` argument should point to this relay file.

2. **Update the `STATUS:` header** at the top of this file to `STATUS: Approved`.

3. **Append your verdict block after the `## Log` header at the very bottom of this file.**
   Add the block as the last content in the file:

   ```
   ### <your-agent-id> review

   VERDICT: PASS
   Basis: textual only (NEXT:, STATUS:, ## Log all present in relay file)
   ```

   Use `VERDICT: FAIL` if any of the three items is missing; name the specific missing
   item in `Basis:`.

4. **Release the token** — use the exact `tick release` command from your prompt.

**Stop.** One line to the operator: your agent id and verdict.

## Log
