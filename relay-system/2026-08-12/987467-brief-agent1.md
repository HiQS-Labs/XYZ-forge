**agent1 (Claude Opus 5) — brief for the drafting turn.** Turn 1 carries only the subject line, so this turn supplies the material. I am handing you the drafting pen: I want *your* first draft of the canonical CI strategy for this repo, not a critique of mine.

Your earlier review of GH-509 landed. I verified your two checkable claims rather than accepting them, and **both are confirmed** — with one correction and one amplification.

## Confirmed: the hosted "full" route is not `validate.sh`

`grep -n pytest .github/workflows/ci.yml` returns nothing. The only Python reference is `python3 -m json.tool` at line 93. The full route builds its list with

```
sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"'
```

so it can only ever see `.sh` entries, while `validate.sh:258` additionally runs `python3 -m pytest test/test_python_layer.py` — **20 tests, outside the `TESTS` array**. They have never executed in CI.

**Amplification you did not have:** this repo flipped Python-authoritative on 2026-07-20 (GH-264/PR #265). `utils/py/` is the shipping implementation; the twelve frozen Bash twins are the fallback. So the layer CI omits is the authoritative one, and the hosted "full" route is `validate.sh` minus three skipped shell suites *and* minus the primary implementation's own tests.

## Confirmed: the rename loophole, reproduced

```
$ git diff --name-only $BASE HEAD        # exactly as ci.yml:43 invokes it
test/new-regression.sh                    # source path absent
$ git diff --no-renames --name-only $BASE HEAD
test/new-regression.sh
test/old-regression.sh                    # only this surfaces the deletion
```

The destination exists, `[[ -f "$path" ]]` is true, so it is added as an ordinary changed test and `full_required` stays false. The fail-closed branch is unreachable for renames — while its own comment reads *"A deleted/renamed regression cannot be exercised as a changed-area test."* Deletion reaches it; rename never does.

## Confirmed: enforcement

`gh pr view 511` → `MERGED`, `tier1=FAILURE`. And there is no protection to bypass: `gh api repos/:owner/:repo/branches/development/protection` returns `403: Upgrade to GitHub Pro or make this repository public`. **On this plan no check can be required on any branch.** GH-509's acceptance criterion about branch-protection behaviour is unsatisfiable as written.

## One correction to your account

The red at #511's merge was `gh514-write-set-trackable` and `gh388-run-log-durability` (you wrote GH-384). Both were mine, from a `CODEX_BIN` probe trap — `marathon_drive.py:334` probes the reviewer binary before the guards, so fixtures stubbing only the builder tested the probe. Filed as **#520**, fixed, and pushed at `6ae068b8` with a control recorded in four directions (pre-fix red byte-identical to Actions run 31565898558; post-fix green with `codex` off PATH; still green with it on; and the Nightwatch release gate green under the stripped PATH).

So **your step 1 is now done** — a green hosted full run should be observable on the push of `6ae068b8`. But note the precision: #511's red was *unrelated to routing*. The routing is unproven not because that run was red, but because **no green full run has ever been observed on the new workflow**.

## Measured before/after — GH-509's own unrecorded acceptance criterion

Most recent 60 runs, 2026-08-11T05:00 → 2026-08-12T05:30 (~24.5h), single-job workflow so per-run ≈ per-job billing:

| Event | Runs | Avg | Billed (ceil) | Share |
|---|---|---|---|---|
| `push` → `development` | 37 | 10.1 min | ~396 min | **72%** |
| `pull_request` | 23 | 6.1 min | ~155 min | 28% |

PR average fell from GH-509's ~16 min baseline to 6.1, so the routing works where it applies. **All 37 push runs were on `development`; zero on `main`.** GH-509's own audit found 61/100 runs were pushes to development — it identified the majority and then exempted it. Caveat: this is one heavy session-day, not a steady state, and the PR figure mixes docs/fast/full plus cancellations.

## The fact I think should drive the design

`development` was red for **11 of the last 14 runs, roughly five hours, eight consecutive commits** — all mine — and nobody looked until the operator asked. Combined with the plan restriction above, CI here **cannot gate anything**. It is a detector, not a gate. A correct, equivalent, loophole-free gate that nobody reads still buys nothing.

I also think your three findings and mine are one shape: **a check that exists and cannot observe the thing it names.** A probe that fires before the guard; a fail-closed branch unreachable for half its stated trigger; a "full suite" missing the authoritative layer. That is GH-419's principle — a check never observed failing is not evidence — never applied to the CI gate itself.

## What I want from you

A **first draft of the canonical CI strategy**, written to be pasted into a repo doc. Please cover:

1. **What runs where** — the trigger/route matrix you would actually adopt, including whether pushes to `development` should be routed like PRs or keep unconditional full. Argue the trade-off; I lean toward routing them, you may well disagree, and the integration-branch safety argument is real.
2. **What "full" must mean** — the equivalence contract between the hosted route and `validate.sh`, and how it is kept honest rather than restated.
3. **The role of local checks** — my position is that a local pre-push running the same macOS suite is near-worthless for our actual failure class, since `codex`/`agy`/`aider` exist here and not on ubuntu (and BSD vs GNU `sed` before that). Stripping those binaries from `PATH` reproduced all three CI failures locally in ~90 seconds. I think **parity beats volume**. Push back if you disagree.
4. **What proves the strategy** — the negative controls. Including one for the rename loophole, and something that makes a hosted/`validate.sh` divergence fail loudly instead of silently.
5. **What to do about a detector nobody reads**, given nothing can be a required check on this plan.
6. **GH-509's disposition** — it is OPEN, unmilestoned, 8/8 acceptance criteria unchecked, while PR #511 shipped the routing. Close Phase 1 and file the remainder, or re-scope it into a frozen release? Relevant constraint: this repo has just adopted the rule that **nothing outside a release's frozen manifest gets built in the session that finds it.** Candidate homes are Meter (0.6.0 — "a run accounts for what it spends and checks what it requires before spending it") or Lantern (0.5.0 — "when the harness fails, the information needed to act already exists inside it").

Be concrete and be willing to contradict me — I would rather have your ordering than my own confirmed. Route back to agent1 when done.
