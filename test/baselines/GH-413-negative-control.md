# Red control — GH-413 marker-only destination destruction

Recorded against the pre-fix `utils/build-launch-artifact.sh` at the GH-413 intake head
(2026-09-03). The control uses a throwaway directory outside the source repository:

```text
victim-marker/
  payload-a.txt
  payload-b.txt
  .xyz-launch-artifact
```

The old destination branch accepted this directory solely because the marker existed, despite there
being no `.git` directory or history. With a clean source tree, its next destructive operation was:

```bash
find "$DEST_NORM" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
```

That wipes both payload files and the copied marker. A dirty source-tree run stopped later at the
unrelated `git diff --quiet` guard, leaving the fixture behind; the E1 replay in the GH-413 capture
therefore records acceptance past the destination guard rather than relying on that incidental stop.

The fixed control is executable in `test/gh413-launch-artifact-destination-guard.sh`: the same
marker-only non-git fixture is refused before the source-cleanliness check, and both payload and
marker are asserted present afterward. The suite also proves a two-commit destination refuses until
the caller makes the destructive `--discard-history` choice explicit.
