# ci-doctor + ci-score run — measured results

**Date:** 2026-08-31 · **Repo:** `HiQS-Labs/XYZ-forge` · **Audited commit:** `d0b644d`
**Issue:** #344 (the plan this executes — steps 1 and 2 of its four-step close)

Both tools are free, need no StarSling account and no GitHub App — only an authenticated `gh`,
Python 3.9+ with PyYAML, and Node. `ci-speedup` is what `skills/ci-doctor/` already vendors;
`ci-score` was the one genuine gap named in #344 and is run here for the first time.

---

## 1. ci-doctor / ci-speedup — the measured critical path

**Sampled:** 8 runs / 16 jobs across 1 workflow, 2026-08-01 → 2026-08-31, 4/20 PRs (flagged SHORT).
Only the 8 runs since `ci.yml` last changed were used; the 12 earlier runs measured a retired
configuration and were excluded rather than blended.

### The headline

> A typical PR waits **5m 58s** for all checks. The slowest check it waits on is
> **`portability canary (ubuntu — advisory, never breakage)`** at **P50 8m 54s**.

Inside that job, on the representative run
([33345497500](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/33345497500), job wall 15m 02s):

| Step | Wall | Share |
|---|---:|---:|
| Shellcheck tracked shell scripts | 39s | 4% |
| Run PDDA deterministic gate | 59s | 7% |
| **Run validate.sh suite (minus a documented flaky test)** | **13m 14s** | **88%** |
| (+16 setup/cleanup steps ≤14s) | — | — |

Cross-run check on the dominant step: 12m 56s – 13m 14s across 2 runs. **Tight spread — the number
is stable, not an outlier.**

Structural pattern matched: **OPT75** (MEDIUM risk) — "the long pole's time is one addressable
step; speed it up or move it off the PR path."

### The finding the tool cannot see, and we can

The long pole is `canary-ubuntu`. That job is declared `continue-on-error: true` at
[ci.yml:236](.github/workflows/ci.yml#L236) — **it can never fail the build.** It is also, per the
cost spine below, **100% of the sampled runner-minute bill.**

So the single slowest thing a developer waits for before merging is a job whose result is, by
explicit design, advisory. `ci.yml`'s own comment block (lines 210–232) says how the canary is
meant to be consumed: *"the canary's status is a line in the promotion output, consulted at the
moment a human is already deciding something."* That is promotion time, not PR time.

**This is the OPT75 "move it off the PR path" branch, and it is unusually safe here** because it
does not weaken any gate — there is no gate to weaken. Moving the canary to a schedule, or to
push-on-`development`, removes ~8m 54s from the PR critical path and changes the merge signal by
exactly nothing. Every guardrail in the tool's own prompt ("never buy speed by checking less") is
satisfied: the commit that merges is still verified by precisely what verifies it today, because
the canary never verified it.

The alternative reading is worth stating: the canary's 13m is `validate.sh` itself, and GH-528
already shipped `--parallel N` (measured 946s → 184s, 5.1x, byte-identical pass/fail sets) as
explicitly experimental. Promoting that would attack the same 13m without moving the job. **Both
are live options; the relocation is the cheaper and lower-risk of the two.**

### Runner-minute cost spine

| Workflow | Job | Runner | Raw min/mo | Billable min/mo | Share |
|---|---|---|---:|---:|---:|
| `ci.yml` | portability canary (ubuntu — advisory, never breakage) | `starsling-ubuntu-24.04-8` | 2959.9 | **3122.4** | 100% |

### Also noticed (off the critical path)

- **OPT14** — repeated checkout/setup with no artifact handoff, `boundary-macos` + `canary-ubuntu`.
  ~242 runner-min/mo. The tool flags its own fix as **wall-clock-negative** (build-once-then-fan-out
  adds a serial gate). Bill saving only.
- **OPT28** — full git history checkout, [ci.yml:162](.github/workflows/ci.yml#L162) and
  [ci.yml:245](.github/workflows/ci.yml#L245). ~54 runner-min/mo. **This is a false positive.**
  The lines immediately above the second one (241–245) document why `fetch-depth: 0` is
  load-bearing: several tests synthesize an "older" ancestor with `git rev-list --max-parents=0
  HEAD`, and a shallow clone silently defeats the fixture. This is exactly the case the skill's own
  prompt warns about — "recover the file's intent from git history first." The comment is the
  refutation. **Do not act on it.**

### Honest limits of this run

- No required-check set is readable — the data pass queried rulesets and branch protection without
  admin access. Ranking therefore falls back to the slowest checks across sampled PRs rather than
  the declared merge gate.
- 4/20 PRs sampled, flagged SHORT by the tool.
- The checkout was on `fix/gh345-sleep-readiness`, not `development`; the tool named the skew
  itself. Timings come from `development` runs, YAML from this branch. `ci.yml` is unmodified on
  this branch, so the skew is nominal here.

---

## 2. ci-score — configuration adherence

**Score: 43/100 — 3 of 7 applicable checks passed** (rubric `ci-score-v0.1.3`, 11 checks, 1
workflow file). Report verified (`verify_report.py` → `report: OK`).

The tool states this itself and it bears repeating: **the score measures adherence to a rubric, not
speed.** A faster repo can score lower.

| | Check | Evidence |
|---|---|---|
| ❌ | Pinned action SHAs | 0 of 2 remote action references SHA-pinned |
| ❌ | Dependency caching | no cache action or `setup-*` cache input in any workflow |
| ❌ | Shallow checkout | `fetch-depth: 0` on 1 PR-gating workflow |
| ❌ | Path filters | `paths:` filters on 0 of 1 PR workflows |
| ✅ | Concurrency groups | declared on 1 of 1 |
| ✅ | Superseded runs cancelled | `cancel-in-progress` on 1 of 1 |
| ✅ | Job timeouts | `timeout-minutes` set |
| n/a | Build caching, test sharding, change-scoped builds, scoped OIDC | not applicable to this repo |

### Adjudication — two of the four failures are real

**Real, worth doing:**

1. **Pinned action SHAs** (high impact, low risk). `actions/checkout@v4` is a moving tag. Pinning to
   a SHA is a supply-chain control with no downside beyond a dependabot-style bump. This is the one
   finding across both tools that is unambiguous, cheap, and currently unaddressed.
2. **Dependency caching** (high impact, low risk). Worth measuring before acting — the canary's
   install steps are ≤14s each and did not appear in the drill-down, so the actual saving may be
   small. Measure, then decide.

**False positives — the rubric cannot see how this repo does it:**

3. **Shallow checkout.** Same finding as OPT28 above, same refutation: `fetch-depth: 0` is
   load-bearing and documented at [ci.yml:241-245](.github/workflows/ci.yml#L241-L245). Two
   independent tools flagged it; the repo's own comment answers both.
4. **Path filters.** The rubric looks for `paths:` in the workflow trigger. This repo does path-based
   routing *inside* the workflow instead, via `utils/ci-route.sh` and the "Classify CI route" step
   ([ci.yml:247-288](.github/workflows/ci.yml#L247-L288)), which fails closed in three named cases.
   That is a deliberate, more careful design than a `paths:` filter, chosen because a trigger-level
   filter cannot fail closed. **Scoring it as a gap is the rubric's blind spot, not a defect.**

---

## What both runs together say about #344's open question

#344 asked whether StarSling's paid optimization tier is worth buying. Two free tools have now
measured this repo end to end. Between them they produced:

- one large, real, safe wall-clock win (relocate an advisory job off the PR path — **which the paid
  tier's catalog would also have found, and which we can act on for free**),
- one real supply-chain fix (pin action SHAs),
- one worth-measuring caching question,
- and two false positives that only a human reading the repo's own comments could dismiss.

That last line is the argument. Both false positives would have arrived as **automated pull requests**
against `ci.yml` on the paid tier. One of them would have deleted `fetch-depth: 0` and silently
broken a test fixture that the repo went out of its way to document.

**Recommendation unchanged from #344: do not enable the paid tier.** The free tools found the wins;
the judgment needed to reject the bad findings is the part that does not come in a subscription.

---

## Reproduce

```bash
# ci-doctor step 1 (== ci-speedup)
npx --yes skills use "https://github.com/starslingdev/skills" --skill "ci-speedup"
python3 <skill>/scripts/run.py --root "$PWD" --out <scratch>/findings.json \
  --repo HiQS-Labs/XYZ-forge --with-logs
# then run the render command run.py prints, verbatim

# ci-score
npx --yes skills use "https://github.com/starslingdev/skills" --skill "ci-score"
python3 <skill>/scripts/collect_config.py --repo "$PWD" --out <scratch>/findings.json
python3 <skill>/scripts/render_report.py  --findings <scratch>/findings.json --out <scratch>/report.md
python3 <skill>/scripts/verify_report.py  --findings <scratch>/findings.json --report <scratch>/report.md
```

Write `--out` to a scratch path outside the tree — the findings JSON and its `.data` bundle contain
raw third-party job logs.
