# GH-527 — recorded negative control

Suite: `test/gh527-destructive-git-guard.sh` (26 pass / 0 fail unmutated)
Guard: `relay-automation/hooks/gh527-destructive-git-guard.sh`
Recorded: 2026-08-14, macOS, branch `fix/critical-2026-08-14`

The guard is **snapshot-then-allow**, so the suite asserts what it *preserves*, not what it
blocks. Two properties carry the issue, and each was observed failing.

## Mutation A — the guard does nothing

Replace the `XYZ_NO_GIT_SNAPSHOT` early-exit line with an unconditional `exit 0`, so the hook
returns before inspecting anything.

```
gh527-destructive-git-guard: 17 pass, 9 fail
```

Nine assertions go red — the snapshot announcement, the snapshot directory, its contents, and
the end-to-end recovery. Restored: 26/0.

## Mutation B — the clean-tree control, and why one edit is not enough

**Two single-line mutations were tried first and both stayed green (26/0).** Recorded because
the reason matters more than the result:

- `if not paths:` → `if False:` — still silent, because with no dirty paths `saved` stays `0`
  and the announcement is behind `if saved:`.
- `if saved:` → `if True:` — still silent, because on a clean tree the function already returned
  at the `if not paths:` early exit and never reaches that line.

Clean-tree silence is **defended in depth by two independent conditions**. Falsifying it takes
both edits at once:

```
sed -e 's|^if not paths:|if False:|' -e 's|^if saved:|if True:|'
→ FAIL: CONTROL: clean tree — guard stays silent
gh527-destructive-git-guard: 25 pass, 1 fail
```

**Exactly one assertion fails** — the control itself — which is the property that separates a
precise assertion from a blunt one. Restored: 26/0.

## Why this control exists

GH-527's acceptance asks for a control showing the guard does *not* fire on a clean tree, "so it
is not a blanket that trains people to override it". An always-firing guard would satisfy every
other assertion in the suite while being useless in practice, so the negative is the assertion
that gives the positives their meaning.

## Honest limit

The suite drives the guard through its PreToolUse payload shape, not through a live Claude Code
Bash call. It proves the guard's logic and its registration in `.claude/settings.json`
independently; it does not prove the harness actually invokes it on a real tool call. Nothing in
this repo's test surface can assert that without the harness in the loop.
