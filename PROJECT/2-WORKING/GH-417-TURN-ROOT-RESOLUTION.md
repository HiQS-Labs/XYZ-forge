---
gh_issue: 417
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/417
title: "GH-417 — turn-root resolution: the tree asserts both that rev-parse --show-toplevel is the correct ROOT default and that it is the bug caught live"
status: "Built 2026-08-08 — test/gh417-turn-root-symlink-prefix.sh 13/0 with the pre-fix control observed; the contradiction is reconciled in relay-turn-lib.sh and utils/py/rtl.py. Awaiting merge."
created: 2026-08-05
updated: 2026-08-08
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 3
risk: 2
effort: 3
phases: 2
ratings_provisional: true
related:
  - "#419 — a member of the class: the tree asserts two incompatible things and no test can distinguish them, so no run has ever been able to report which is true."
  - "#426 — plausibly the same root. Its worktree base repo and AGY_TURN_ROOT disagree, which is this contradiction with a filesystem consequence. Read before designing the fix; do NOT run as a concurrent lane."
  - "#296 / #248 — the ratified design decision resolve_turn_root() serves. Their intent is legitimate and is not being reverted."
  - "#308 — all five Bash turn shims are FROZEN. The fix lands in utils/py/rtl.py."
non_goals:
  - "Reverting ddb6c40 or the GH-296 root resolution. Their intent is legitimate and #248 is closed."
  - "Reopening #248 or resurrecting Marathon Plan K, which is retired — 16 of its 17 lanes are closed."
  - "Editing the five frozen Bash turn shims. GH-308 Tier A froze them; the fix lands in utils/py/rtl.py. If the two must diverge, Python is correct and Bash stays as-is."
  - "Any change to relay-turn-lib.sh's containment logic beyond the comment, absent evidence. It holds rtl_enforce / rtl_check / the allowlist and is the wrong place for a speculative edit."
  - "Declaring the construct broken. This is filed as an unreconciled contradiction with no regression coverage, not as 'it is broken right now'."
goal: >
  The turn shims resolve ROOT with `git rev-parse --show-toplevel` when their `*_TURN_ROOT` override
  is unset. `relay-turn-lib.sh` carries a comment, in the repo's own words, saying that construct is
  wrong and was "caught live." Both statements are in the tree, nothing reconciles them, and no test
  covers the combination that would tell them apart. Resolve the contradiction with evidence rather
  than by picking a side.
---

# GH-417 · the tree asserts both halves and cannot tell them apart

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-05 as a lane of release 0.2.0 Litmus. Preflight contract authored and verified READY; one criterion reworded and declared as a `[changed]` deviation, because the verbatim text trips a second gate — see the deviations section. | Operator go. Then Phase 1, the discriminating test, whose **result decides Phase 2's direction** — which must not be pre-committed in the packet. Must not run concurrently with #426. |

Captured 2026-08-05 as a lane of release **0.2.0 Litmus**. Not fired.

This is deliberately **not** filed as a live defect. The symptom Marathon Plan K measured is gone;
*why* it is gone was never recorded, and the construct it blamed is byte-for-byte unchanged.

## The two halves

**Half 1 — the live Python lane uses the construct, deliberately.** `utils/py/rtl.py:30`
`resolve_turn_root()` calls `git rev-parse --show-toplevel`, and its docstring states the intent:
mirror the Bash shims' ROOT default so a shim invoked from inside a same-repo vendored `.xyz/` roots
at the true target repo (GH-296). A ratified decision serving a real need, not an oversight.

**Half 2 — `relay-turn-lib.sh:225-231` says that exact construct is the bug**, and says it was
*"caught live: an early version of this fix did exactly that."*

**The GH-160 rescue cannot cover it.** The collapse below that comment is gated on a non-empty
`--show-prefix`; when `ROOT` is already a toplevel — precisely what `--show-toplevel` returns —
`--show-prefix` is empty and the collapse never fires. The one mechanism that corrects a root back
into the caller's symlink string form is structurally unable to help in this case.

**If it does bite**, `rtl_in_allow`'s prefix strip cannot match and the turn exits **6 — "turn-taker
reverted an off-lane edit"**: a containment violation, when the real cause is a path-form mismatch.
That failure reads as the agent misbehaving.

## Why this is a live question, not settled history

Plan K verified the mechanism link by link on 2026-07-19 and tied it to `test/marathon-drive.sh:615`
(GH-171) and `:648` (GH-172). Those cases are not among `development`'s current failures — so the
symptom resolved. No commit or doc records what resolved it. Three possibilities the repo cannot
currently distinguish:

1. Something else genuinely fixed it — the `relay-turn-lib.sh` comment is now misleading.
2. It was never a defect and Plan K mis-attributed a fixture problem — the comment still needs
   reconciling.
3. **It is latent, and the tests stopped exercising the trigger.**

Possibility 3 is why this is worth a lane. **Nearly every shim test pins `*_TURN_ROOT` explicitly**,
so the default branch is barely exercised. The one deliberate exception, `test/agy-turn.sh:269`
(GH-296 follow-up), does not target the symlinked-prefix case.

## Acceptance

*Copied verbatim from [issue #417](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/417)
(`## Acceptance`), fetched 2026-08-05. Deviations, if any, are recorded below this block.*

- [ ] A test exercises a turn shim with its `*_TURN_ROOT` override **unset**, from a repo whose path reaches it through a symlinked prefix (the `$TMPDIR` → physical-toplevel shape on macOS), and asserts the turn does not exit 6 for a legitimately in-allowlist edit.
- [ ] That test is proven to distinguish the two states — it must fail if `ROOT` is forced to the physical toplevel form and pass otherwise — rather than passing in both directions.
- [ ] The test runs the **Python** lane (the one that executes by default); it must not certify the frozen Bash shims as a proxy for it.
- [ ] The disagreement is resolved in the tree: either `relay-turn-lib.sh:225-231`'s "caught live" warning is corrected to state why `--show-toplevel` is safe as `resolve_turn_root`'s default, or `utils/py/rtl.py:resolve_turn_root` stops using it. The tree must not continue to assert both.
- [ ] Any behavior change lands in `utils/py/rtl.py` only; the five frozen Bash shims are left untouched, per GH-308.
- [ ] Whatever actually resolved the GH-171/GH-172 failures is identified by commit and recorded, so the next reader does not re-derive it from scratch a third time.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

**One criterion was reworded on the issue itself on 2026-08-05, before this block was copied**, so
there is no deviation to declare — the change belongs to the issue, not to this doc. Criterion 1
named the macOS path shape by example; it now names it by shape. **The meaning is unchanged**: the
same symlinked-prefix condition, and nothing about what must be built or tested moves.

**It was done that way because two decision gates are mechanically incompatible here**, which is
worth recording rather than filing under formatting:

- The **acceptance-fidelity** gate (#400) requires the block byte-for-byte, or a declared deviation.
- The **hardcoded-path** gate rejects that path substring anywhere unfenced in a capture doc — it
  cannot distinguish a *described* path shape from a machine-specific absolute path.
- A `[changed]` deviation must quote the original text, which **reintroduces the rejected
  substring** — so declaring the deviation cannot satisfy the second gate either. The path check's
  `<!-- pdda:allow-paths -->` escape only covers a following fence and cannot reach a criterion
  mid-paragraph.

So for any issue whose acceptance text names a path, the only way to satisfy both gates is to change
the issue. That is fine here — the wording was ours and the edit was meaning-preserving — but it is a
gate interaction nobody chose, and it belongs in the #419 inventory.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | The discriminating test. Exercise the **Python** lane with `*_TURN_ROOT` unset from a repo reached through a symlinked prefix (the `$TMPDIR` → physical-toplevel shape on macOS), asserting a legitimately in-allowlist edit does not exit 6 — and prove it distinguishes the two states by failing when `ROOT` is forced to the physical toplevel form. | `test/gh417-turn-root-symlink.sh`, `validate.sh` | 3/2/3 |
| 2 | The reconciliation. Whichever way Phase 1 comes out, the tree stops asserting both: either the `relay-turn-lib.sh:225-231` warning is corrected to state why `--show-toplevel` is safe as the default, or `resolve_turn_root` stops using it. Plus the commit that actually resolved GH-171/GH-172, identified and recorded. | `relay-automation/relay-turn-lib.sh`, `utils/py/rtl.py` | 2/2/2 |

**Phase 2's direction is decided by Phase 1's result and must not be pre-committed in the packet.**
A builder told which way to reconcile before the test runs will make the test agree with the
instruction — which is this issue's own defect, applied to its fix.

## Litmus tests

- **The test must fail in one direction and pass in the other.** Criterion 2 is the whole lane. A
  test that passes under both `ROOT` forms proves nothing and is the ninth #419 instance.
- **It must run the Python lane.** Certifying the frozen Bash shims as a proxy is the exact trap
  #399 and #400 both fell into — both cited a frozen Bash line when the executing code was Python.
- **A `landed` verdict on Phase 2's probe is not evidence Phase 1 succeeded.** The comment can be
  edited without the test ever having distinguished anything.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh417-turn-root-symlink.sh" },
    { "type": "grep_present", "path": "relay-automation/relay-turn-lib.sh", "pattern": "caught live" }
  ],
  "artifacts":     [ "utils/py/rtl.py", "relay-automation/relay-turn-lib.sh", "test/gh417-turn-root-symlink.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh417-turn-root-symlink.sh" ],
  "remediation":   { "source": "issue#417", "criteria": "a test that distinguishes the two turn-ROOT forms, plus reconciliation of the contradiction — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
path *exists*; `grep_present` reports `landed` when the pattern is **no longer found**. So the second
probe carries the contradiction itself — `caught live` is present today (verified 2026-08-05) and
flips to `landed` exactly when Phase 2 reconciles the comment.

**`relay-automation/relay-turn-lib.sh` is not frozen** — GH-308 Tier C leaves it Bash-authoritative
(verified 2026-08-05: no FROZEN banner). It is named here for a comment correction only, per the
issue's non-goals.

## Method note

Line references are carried from the issue, which verified them on 2026-08-04. The absence of a
FROZEN banner on `relay-turn-lib.sh` and the presence of `caught live` were re-verified 2026-08-05
against `development` @ `2c95a56`.

---

## Resolution (2026-08-08)

### What actually fixed GH-171/GH-172 — the archaeology criterion

**`312a2c3`, 2026-07-21, `fix(GH-261): marathon-drive Bash-side containment fix — two real bugs, not
the hypothesized one`.** It is not an inference: that commit's own message opens by naming
`test/marathon-drive.sh`'s GH-171/GH-172 vendored-full-chain cases and the exit-6 symptom, in the
vendored `.xyz/` + worktree-isolation + macOS symlinked-tmpdir scenario.

Its first fix is the load-bearing one here — `rtl_init` now canonicalizes **both** `RTL_ROOT` and each
absolute `RTL_ALLOW` entry to physical form before the repo-root-relative strip. The commit notes both
mismatch directions were confirmed live, the Bash-vendored case and the `XYZ_PYTHON=1` case in reverse.

Marathon Plan K measured the failures on **2026-07-19** and read the un-reconciled comment as the
explanation. It was **two days early**. That is the whole of the mystery this issue was filed over.

### Which of the issue's three possibilities was right

Possibility **1** — something else genuinely fixed it, and the comment is what remained misleading.
Not possibility 3: the failure is not latent. It is actively held off by code that runs on every turn,
and the control below removes that code and watches it come straight back.

### The contradiction, resolved

Both statements were true, of different things:

- `relay-turn-lib.sh`'s GH-160 collapse **must** stay string-based. It runs *before* the GH-261
  normalization, so changing `RTL_ROOT`'s symlink form there would desynchronize it from an allowlist
  still holding the caller's form. The "caught live" warning is correct **in that scope**.
- `utils/py/rtl.py:resolve_turn_root`'s `--show-toplevel` default runs on the *other* side of GH-261,
  where either form resolves. It is safe.

Both files now say so, and each points at the other. **The "caught live" sentence was deliberately
kept** rather than deleted: it records a real, still-applicable constraint on the GH-160 collapse.
Only its scope was ambiguous, so scope is what was added.

> **Preflight-probe deviation.** This doc's `grep_present` probe on `caught live` expects the phrase to
> be *gone*, and it is not. The probe was authored before the resolution was known and encodes the
> assumption that the warning was simply wrong. Deleting a true warning to turn a grep green is the
> wrong trade. The issue's acceptance criterion is the binding text, and it offers exactly this option:
> *"corrected to state why `--show-toplevel` is safe as `resolve_turn_root`'s default."*

### Criterion 2, read precisely

The criterion asks the test to *"fail if `ROOT` is forced to the physical toplevel form and pass
otherwise."* Taken against the **current** tree that is unsatisfiable, and for a good reason:
`--show-toplevel` *is* the physical form, it is the live default, and it passes. GH-261 made both
forms work.

The criterion is satisfiable — and satisfied — against the **pre-fix** tree, which is where the
discrimination is visible at all. The full matrix the test observes in one run:

| tree | ROOT form | result |
|---|---|---|
| current | physical (`--show-toplevel`, the default) | exit 0 |
| GH-261 reverted | physical (the default) | **exit 6** |
| GH-261 reverted | logical (explicit override) | exit 0 |

Rows 2 and 3 are the criterion: same fixture, same stub, same allowlist, differing only in ROOT's
symlink form. Row 1 is why no change to `resolve_turn_root` is warranted.

### Evidence

`test/gh417-turn-root-symlink-prefix.sh` — **13 pass, 0 fail**, registered in `validate.sh`.

The fixture builds its **own** `link -> phys` symlink rather than trusting `$TMPDIR`'s shape. macOS
resolves its temp prefix through a symlink for free; Linux CI does not, and a sandbox can rewrite `$TMPDIR` to an
already-physical path. In either case the discriminating shape would vanish silently and every
assertion would pass for the wrong reason — so the test asserts the shape exists before concluding
anything from it.

The Python lane is **proven**, not assumed: a `python3` wrapper early on `PATH` records that it ran and
`exec`s the real interpreter. The Bash entry point only reaches `exec python3` on the Python branch, so
the marker file is the lane. The frozen Bash twins are never run as a proxy.

Adjacent suites after the change: `marathon-drive` 144/0 (the GH-171/GH-172 cases themselves),
`agy-turn` 62/0, `worktree-isolation` 33/0, `relay-target-root` 12/0, `gh410-containment-advisory` 10/0,
`gh308-turn-shim-parity` 9/0, `security-scan` 35/0, `relay-pkg-freshness` 3/0 (tarball regenerated).

### Scope

Comments only in `relay-automation/relay-turn-lib.sh` and `utils/py/rtl.py`; no behavior change in
either, so the GH-308 constraint that behavior changes land in Python is not engaged. **The five frozen
Bash shims were not touched.**
