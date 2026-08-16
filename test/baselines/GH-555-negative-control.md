# GH-555 negative control — `test/meter-release.sh`

Recorded 2026-08-15. Per #419: a check never observed failing is not evidence.

**RE-POINTED 2026-08-15.** Meter was re-scoped from its metering manifest to the public-repository
launch, and this gate moved with it. The prior control (manifest audit + six member cases) is
superseded and recorded below as the observed FAILING state, because the pre-fix version of this
file did not merely go stale — **it reported a false green**, and that is the thing worth pinning.

## The observed failure — the reason this file was rewritten

Run on `64e68cde`, in a clean clone, before any change:

```
$ bash test/meter-release.sh --release-gate
  PASS: the frozen manifest here matches RELEASES.md's Meter block (7 entries)
  PASS: #378 complete — ... PASS: #380 complete — ... PASS: #555 complete — ...
manifest: 7 complete, 0 remaining, 0 false completion claim(s)
GOALPOST MET — all 7 manifest entries complete and every member case executes green
```

**That verdict was false in two independent ways, both observed directly rather than reasoned about.**

### Defect 1 — the ledger cross-check could not fail

`manifest_matches_releases_md()` grepped RELEASES.md's `Manifest:` line for each expected `#N`. That
line is a paragraph carrying the release's full dated re-scope history, so it names every number ever
admitted **or retired**. Measured on the real file:

```
  #378 in Manifest: line? YES     #491 in Manifest: line? YES
  #379 in Manifest: line? YES     #551 in Manifest: line? YES
  #380 in Manifest: line? YES     #555 in Manifest: line? YES
  #382 in Manifest: line? YES     #563 in Manifest: line? YES
```

All eight matched — including **#563, which the script had never heard of**. The check would have
passed for any subset of any manifest. It was also one-directional: it asked *"is everything I list
in the ledger?"* and never *"is everything the ledger lists in me?"*, so a ledger declaring two
members while the file measured seven was invisible.

### Defect 2 — "complete" never consulted the issue

`audit_manifest()` credited an entry as complete when three files existed (gate, its registration in
`validate.sh`, a recorded control). Issue state was fetched but used only for the reverse error
(CLOSED with no gate). **Six OPEN issues were therefore counted complete**, and the goalpost reported
MET. This is the #461 family: a guard reporting green on a condition it cannot observe.

## What the fix had to be falsifiable against

- Membership is read from a machine-readable `Manifest-Members:` field, compared in **both**
  directions, and prose can no longer satisfy it.
- An entry is COMPLETE only when its evidence machinery is in place **and** its issue is CLOSED.
- The artifact audit and the stranger's path each detect their own specific violation.

## The control, and a defect it found in the fix

`bash test/meter-release.sh --mutate-evidence` builds a **compliant fixture artifact**, breaks it in
eleven specific ways, requires each break to be detected by **name**, and restores the fixture green
in the same run.

**First run of the rewritten control: 7 passed / 3 failed.** It caught two real defects in the fix
itself, which is why detection is now keyed to check IDs rather than counts:

1. The private-marker sweep emitted **one** failure regardless of how many markers were present, so
   planting a new marker in an artifact that already leaked one changed nothing observable. A
   mutation that "proves" detection by watching a count move proves nothing when the count is
   saturated. Fixed: one failure **per marker**, and assertions name the check ID.
2. The fixture compared its `CHANGELOG.md` against **this repository's**, which currently carries
   private markers — so the baseline fixture was non-compliant and every downstream mutation was
   unprovable. Fixed: the control uses a clean reference root, so it tests the checker rather than
   the current state of the repository.

Both were found by the control, not by review. That is the control working.

## Final observed state

```
$ bash test/meter-release.sh --mutate-evidence
  PASS: unmutated fixture artifact passes every Half A check (7 checks) — discriminating, not always-red
  PASS: a planted private path is DETECTED by the private-marker sweep
  PASS: a removed CHANGELOG.md is DETECTED
  PASS: a modified CHANGELOG.md is DETECTED — 'verbatim' is enforced, not just 'present'
  PASS: a surviving relay-system/ is DETECTED
  PASS: a second commit is DETECTED — fresh history is enforced
  PASS: a surviving internal PROJECT doc is DETECTED
  PASS: a secret-scan record with no pinned version or commit is DETECTED
  PASS: a ledger declaring retired #378 is DETECTED (direction 2 works)
  PASS: a ledger missing #563 is DETECTED (direction 1 works)
  PASS: a prose Manifest: paragraph cannot satisfy the cross-check (the original defect stays fixed)
  PASS: restoring the inputs restores the verdict — the detector is not simply always-red

  meter-release --mutate-evidence: 12 passed, 0 failed
  negative control OBSERVED in both directions
```

Mutation 8 exists specifically to pin Defect 1 shut: a prose `Manifest:` paragraph naming every
number ever admitted is fed to the cross-check and **must be refused**.

The baseline fixture passing all 7 Half A checks is what makes this discriminating — a checker that
refused everything would fail the baseline and the restore, so it cannot pass by being paranoid.

## Goalpost state on arrival

```
$ bash test/meter-release.sh --release-gate   # exit 1
GOALPOST NOT MET — the public launch is not done.
```

RED on arrival, before any sanitization was performed — the Litmus and Nightwatch ordering, and the
reason both releases could tell a finished entry from a claimed one.

## What this deliberately does not prove

Half A reads a declaration and a filename; it cannot know a recorded secret scan was honestly
recorded. That limit is inherited and stated rather than papered over. Half B closes part of it by
executing the stranger's path under a scrubbed environment (`env -i`, no author `HOME`, no tokens),
which is the strongest available evidence that no private context is required.
