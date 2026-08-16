# GH-1 init order negative control — `test/gh1-fixture-guard.sh`

Recorded 2026-08-16. Per #419: a check never observed failing is not evidence.

## What had to be falsifiable

Order-independence matters (the GH-567 lesson: validate the sandbox path at the USE boundary, and never let a guard's correctness depend on which line a check happens to sit on). The control to record is a mutation pair, not a pre-fix replay, because the pre-fix code passes the new pin too — the pin exists to make the init check's position load-bearing against future reordering or deletion.

## Controls (Mutation Pair)

The mutation was performed in a scratch copy under `/tmp` (never in the repo tree).

**Mutation:** Delete the init check from `_fixture_check` entirely, then run `require_fixture /etc` without calling `fixture_guard_init`. With the check deleted, both case patterns evaluate to `/*` (empty root variables). The path `/etc` passes them, `os.path.realpath` resolves it fine, and `[ -d /etc ]` evaluates to true — so `/etc` is ACCEPTED.

**Unmutated (the pin passes):**
```bash
mkdir -p /tmp/scratch-gh1
cp test/lib/fixture-guard.sh /tmp/scratch-gh1/
( . /tmp/scratch-gh1/fixture-guard.sh && require_fixture /etc "label" )
echo $?
```
*Observed:* exit 2 (refused)

**Mutated (the pin fails):**
```bash
# Delete the init check line from _fixture_check
sed -i.bak '/\[ -n "$FIXTURE_GUARD_RESOLVED" \]/d' /tmp/scratch-gh1/fixture-guard.sh
( . /tmp/scratch-gh1/fixture-guard.sh && require_fixture /etc "label" )
echo $?
```
*Observed:* exit 0 (accepted)
