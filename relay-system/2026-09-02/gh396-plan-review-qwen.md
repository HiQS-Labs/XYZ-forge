---
Goal: Second-opinion QA of the GH-396 plan — adjudicate DeepSeek's review, then find what it missed
Date: 2026-09-02
Producer: claude-a
Reviewer: deepseek
NEXT: deepseek
STATUS: Open
---

# Context

You are the **second** reviewer. A first reviewer (DeepSeek V4 Pro) has already reviewed this plan
and returned ten required changes. Your job is two things, in this order:

**Part A — adjudicate DeepSeek.** For each of its ten required changes, say **uphold / reject /
narrow**, with a reason and `file:line`. Do not accept a finding because it sounds reasonable —
check it against the tree. A rejected finding needs the evidence that shows it wrong; an upheld one
needs the evidence DeepSeek did not supply.

**Part B — find what DeepSeek missed.** It answered the questions it was asked. You are asked to look
where it did not.

Read, in this order:

1. `relay-system/2026-09-02/gh396-plan-review-deepseek.md` — DeepSeek's full verdict, under `# Log`.
2. `PROJECT/1-INBOX/GH-396-HARNESS-ROOT-RESOLVER.md` — the plan (frontmatter + body).
3. `PROJECT/1-INBOX/recon-harness-root-resolution.md` — the recon map the plan was written against.
4. `skills/relay-xyz/find-harness.sh` (whole file), `utils/py/wave_reconcile.py:25-70`,
   `utils/py/rtl.py:275-320`, `utils/py/swarm_preflight.py:10-25` and `:1165-1180`,
   `utils/py/marathon_plan.py:105-130`, `relay-automation/xyz-vendor.sh:340-420`,
   `relay-automation/xyz-sync.sh:1-60` and `:400-460`, `skills/file-xyz-bug/find-xyz.sh:15-75`,
   `test/gh358-wave-reconcile-vendored-paths.sh`.

# Part A — DeepSeek's ten required changes

1. Phase 0: add symlink fixture and linked-worktree override test cases.
2. Phase 1: derive `CALLER_ROOT` from `git -C "$_o" rev-parse --show-toplevel` (with `dirname`
   fallback), not bare `dirname(HARNESS)`.
3. Phase 2: module docstring must state `resolve_harness` and `resolve_tool` have separate,
   non-interchangeable precedence rules.
4. Cut the `XYZ_RESOLVER_LEGACY=1` kill switch as YAGNI.
5. Phase 4: make `vendored-smoke` blocking on `development`, not advisory.
6. Phase 3: shrink to the five symlink-loop copies + the four `find-*.sh` locators + `gate-env.sh`;
   leave the other ~10 live scripts' inline predicates as-is.
7. Phase 3: account for `find-harness.sh:76` sourcing `driver-lock-lib.sh`.
8. Phase 1: add `--quiet` to the acceptance criteria.
9. Phase 0: add a `--quiet` test case.
10. Phase 4: update `device_config.py`'s docstring for `XYZ_DEFAULT_HARNESS`.

For #2 specifically: is `git -C "$_o" rev-parse --show-toplevel` **correct** when `$_o` is a vendored
`.xyz/` that is **gitignored** inside the consumer repo? (`xyz-vendor.sh:300` enforces `.xyz/` in
`.gitignore`.) `git rev-parse` from inside an ignored directory still resolves the enclosing repo —
confirm or refute with a command. And what does it return when the consumer repo is a **linked
worktree** — the worktree root, or the main checkout? DeepSeek's own finding #1 says the worktree
case is a distinct topology; does its proposed fix #2 actually handle it?

For #5: is DeepSeek right that the bare-harness CI is already boundary on `development`? Read
`.github/workflows/ci.yml:150-194` and `:234-245` and say exactly which jobs gate which branch.

# Part B — what DeepSeek did not look at

11. **Repo-first `harness_tool` in a consumer that has its own `utils/`.** `wave_reconcile.harness_tool`
    (`utils/py/wave_reconcile.py:31-68`) returns `$REPO/utils/…` when it exists, else the harness copy.
    The plan extracts this as the shared `resolve_tool`. A consumer repo that has its **own**
    `utils/py/releases_app.py` or `utils/roadmap-dashboard.sh` — unrelated to the harness, same
    filename — would shadow the harness tool silently. Is that a real risk for the three consumer
    repos named in the recon map, and does `test/gh358-…:128-131` ("a canonical checkout must prefer
    its own copy") pin the behaviour that creates it? If so, what should `resolve_tool` do instead —
    probe for a marker, prefer harness-home when `is_vendored`, or something else?

12. **`find-xyz.sh:22-25` refuses a vendored `.xyz` as authoritative** ("vendored is never
    authoritative" is policy there). The plan's shared helper makes vendored-wins the universal
    rule. Does the plan break `find-xyz.sh`'s intake-locator contract, and should the helper expose
    a `--prefer-bare` mode or should `find-xyz.sh` simply not adopt it?

13. **The two staleness stores disagree by construction** (recon map §State: `.xyz/VERSION` vs
    `~/.config/xyz/registry.tsv`, two writers, no single write path). Phase 1 makes `find-harness.sh`
    warn from `VERSION`; `xyz-sync.sh check` warns from the registry. After this plan lands, an
    operator can still get two different "am I stale" answers from two commands. Is that in scope
    (the plan lists a single "current harness" pointer as a non-goal needing `spike-360`), or is
    there a cheap Phase 1 change — e.g. `find-harness.sh` also reading the registry row and saying
    "VERSION says X, registry says Y" — that closes the gap without a new store?

14. **`swarm_preflight.py:1171`'s deliberate second anchor.** Phase 2 says keep it and comment why.
    Read the code. Is it genuinely a different question from `harness_home()`, or is it the same
    `..` arithmetic that the shared module should own? If the plan is wrong to keep it, say so.

15. **Phase ordering.** Phase 0 tests must arrive red at `1b6058d7`. But Phase 0 also *creates*
    `test/_vendored_fixture.sh`, which runs the real `xyz-vendor.sh --no-register`. Does
    `xyz-vendor.sh` have any behaviour (registry writes, gitignore enforcement at `:300`, the
    destructive swap at `:400-414`) that makes it unsafe to invoke from a test fixture inside the
    harness's own checkout? Should the fixture builder vendor into `$TMPDIR` only, and does the
    plan say so?

16. **The `RELAY_HAS_DEEPSEEK` fix (#393)** derives readiness from `python3` + an API-key env. But
    `deepseek-turn.py`'s actual requirements may include more (a `requests`/`httpx` import, a
    specific provider env, `DEEPSEEK_BIN` honoured). Read `utils/py/deepseek-turn.py`'s top ~120
    lines and say what the readiness check must actually assert to be honest.

17. **Anything else.** A seam in the recon map the plan ignores; an acceptance grep in Phases 2–3
    that would pass for the wrong reason; a claimed number (8 strategies, ~290 sites, 12 spellings,
    21 fixtures, 329 suites) you measured differently — give the number and the command.

Cite `file:line` for every claim. Where you disagree with DeepSeek, say so plainly and show why.

Write your verdict below as `### Round 1 · Reviewer · deepseek-shim (qwen 3.8 max via OpenRouter)`, then set
`STATUS: Approved` if the plan **as amended by the upheld changes** is ready to build, or leave
`STATUS: Open` with the consolidated numbered list of required changes (DeepSeek's upheld ones plus
yours).

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

# Log

