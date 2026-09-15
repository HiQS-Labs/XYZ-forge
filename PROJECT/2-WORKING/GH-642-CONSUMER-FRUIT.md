---
gh_issue: 642
source: https://github.com/HiQS-Labs/XYZ-forge/issues/642
title: "Low-hanging fruit from two foreign-repo marathons: make the consumer-repo SOP turnkey"
status: Active (2-WORKING — implemented on feat/gh642-consumer-fruit; QA'd 3 rounds; gate evidence on final SHA)
created: 2026-09-15
updated: 2026-09-15
owner: noelsaw1
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 4
rating: "pri/sev/appeal/effort 60/35/50/48 · calc 193"
goal: >
  Land the surgical tranche of #642 so a consumer-repo marathon stops tripping on layout and
  fix-round traps: vendor ignores go to .git/info/exclude (never the target .gitignore), the
  claude-turn Python twin warns on Opus-class models with the Sonnet-sized default budget,
  marathon_drive --force on a spent token auto-suffixes a fresh relay-task id, isolated worktree
  turns get a disposable copy of ROOT/node_modules, a new utils/py/xyz_init_clone.py produces the
  validated consumer-clone layout in one command, and swarm_preflight warns loudly on a
  zero-item acceptance checklist. All behavior fixes land in the Python twins per GH-308; the
  frozen Bash fallbacks are untouched.
---

# GH-642: Consumer-repo fruit — make the foreign-repo marathon SOP turnkey

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-09-15 on branch `feat/gh642-consumer-fruit`** — plan APPROVED (Codex, 3 rounds); all six tranche items landed. Final QA ran 3 rounds: rounds 2–3 confirm every item's implementation correct; round 3's remaining findings were test-falsifiability only, and its exact prescribed assertions (default-stream stderr capture, runtime call-site pins) were applied and **mutation-checked red → green**. Focused suite **52 pass / 0 fail**; pinned suites green: xyz-vendor 76/0, gh312 14/0, gh308 38/0, gh320 10/0, gh365 5/0, relay-pkg-freshness 3/0. `ci-local.sh` runs once on this final SHA (evidence in the PR). | Push + PR against `development` (operator-visible next); merge is the operator's call. Deferred follow-ups (fix-rounds, handback preservation, --scaffold, dual-home) need their own issues + arcs. |

## Rating rationale (2026-09-15, noelsaw1 session)

`60/35/50/48`. **sev 35** — no data loss or corruption; consequences are workflow hard-stops,
wasted rounds, and burned API budget (Opus turns capped mid-flight by a Sonnet-sized default;
a vendor append that halted a `--require-clean` fire until manually reverted). **pri 60** —
operator-filed after two field runs in two days; friction recurs on every consumer-repo marathon
and sits on the product's core promise (the machinery an unattended run needs). **appeal 50** —
neutral; no operator score supplied. **effort 48** (re-scored from 60 on round-1 review evidence):
six items, most in dual-runtime-adjacent code with strict twin governance, a new initializer, and
cross-Git-layout test fixtures.

## Field evidence

[#621](https://github.com/HiQS-Labs/XYZ-forge/issues/621) — two foreign-repo marathons on
`jpollock/local-addon-nexus-ai` (gh-52, gh-60); the run-2 report (comment of 2026-09-15) is the
incidence source for every item. Consumer side: umbrella
[local-addon-nexus-ai#60](https://github.com/jpollock/local-addon-nexus-ai/issues/60), PRs #61–#64.

## Recon findings (task clone @ origin/development d5c18633; Codex-verified round 1)

Already satisfied at HEAD — the Nexus `.xyz` vendor predates them (source 033a48ee, 2026-08-26);
consumer remedy is `xyz-sync update`, not new work:

| #642 item | State at HEAD | Evidence |
|---|---|---|
| Ship `releases_app.py` in `--with-releases` overlay | **Already landed** | `relay-automation/xyz-vendor.sh:336-344` `RELEASES_OVERLAY` includes `utils/py/releases_app.py` |
| Claude effort support | **Already landed (Python twin)** | `utils/py/claude_cli.py:19-24` `effort_flags` reads `CLAUDE_REASONING_EFFORT` (low/medium/high/xhigh/max) |
| Acceptance-inlining loss protection | **Already hardened** | `utils/py/swarm_preflight.py:1472-1485` — GH-399 makes a lossy inline NOT-READY |

## Scope — the surgical tranche (this arc)

1. **Vendor ignores → `.git/info/exclude`** (`relay-automation/xyz-vendor.sh` — not a frozen twin).
   Direction 1 (lines ~296-304) currently creates/appends the target `.gitignore`; move that
   destination to `git -C "$TARGET_REPO" rev-parse --git-path info/exclude` (creates the dir as
   needed; correct for normal clones, linked worktrees, and `--separate-git-dir`). Direction 2's
   pre-mutation `git check-ignore` refusal (~:252-294) is untouched — it already honors
   info/exclude. Blast radius (round-1 SHOULD): update the destination-encoded comments at
   `xyz-vendor.sh:388-392`, `test/gh312-vendor-preserves-state.sh:5-9`,
   `skills/vendor-stack/SKILL.md:123-127`, and the `.gitignore`-pinned assertions at
   `test/xyz-vendor.sh:76-77,105-114,146-150`; add fixtures for all three Git shapes.
2. **Opus-budget warning, Python twin only** (`utils/py/claude-turn.py`). Non-fatal stderr warning
   before dispatch when `CLAUDE_MODEL` matches `claude-opus*` and `CLAUDE_MAX_BUDGET` is unset or
   the 0.50 default (field evidence: bare Opus smoke call ≈ $0.68 of cache-write; the default cap
   hard-stops mid-turn). **Governance disposition:** the bash twin's missing effort flag is NOT
   ported — `claude-turn.sh` is a frozen fallback (GH-308) and a missing flag in a fallback is not
   a safety defect; `CLAUDE_REASONING_EFFORT` works on the default Python runtime. No
   `Frozen-twin-exception`.
3. **`--force` auto-suffix on a spent token** (`utils/py/marathon_drive.py` only — bash twin
   frozen). Token-identity spec: spent ≡ `tick info` reports `status: done|circuit_broken`;
   missing/malformed tick output fails the fire BEFORE render/commit/seed (never interpreted as
   free); when the id was auto-derived (no explicit `--relay-task`), `--force` is set, and the
   default token is spent, scan `MARATHON-<PHASE>-TURN-R2, R3, …` for the first not-found id and
   use it, announced on stderr. The suffix resolves BEFORE render, receipt, heartbeat, and seed —
   every downstream consumer (including the receipt's `token` field, `MACHINE-CONTRACTS.md:94-103`,
   Contract B) sees exactly one resolved id. The lane-attempt-cap key (lane/phase, not token) is
   unchanged. Explicit `--relay-task` is never rewritten.
4. **Worktree build deps — disposable copy, NOT a symlink** (`relay-automation/relay-turn-lib.sh`,
   non-frozen shared Bash runtime). After `rtl_worktree_begin` creates the worktree, if
   `$RTL_ROOT/node_modules` exists and the worktree lacks it, `cp -R` it in (one-shot; writes stay
   disposable — a symlink would let turn writes traverse into ROOT's real `node_modules`,
   reopening the containment gap isolation exists to close, round-1 BLOCKER). Teardown unchanged.
   The focused suite records copy size/time so the cost is observed, not assumed.
5. **`utils/py/xyz_init_clone.py`** — new Python executable (no-new-Bash rail, GH-551; no
   exception needed). `xyz-init-clone.py <repo-url> --umbrella N [--slug s] [--dir D]`:
   `--umbrella` required (marathon-triage: an unnamed umbrella is not ready); slug defaults from
   the repo name, validated ≤3 lowercase words; clone name `marathon-gh-<umbrella>-<slug>`, an
   occupied derived name retries with the documented `-r2` suffix, and an existing checkout is
   never merged into or overwritten (git's non-empty rule + retry); clone from the canonical
   remote; self-vendor via
   `relay-automation/xyz-vendor.sh` — Tier 2 (`--with-releases`) is **always** passed (a marathon
   needs the ledger overlay; resolves the round-1 optional-vs-always contradiction); installs
   `githooks/install.sh` when the cloned repo ships one; prints next steps (bootstrap hint + drive
   invocation shape).
6. **Preflight zero-criteria warning** (`utils/py/swarm_preflight.py` only — `utils/swarm-preflight.sh`
   is the frozen Bash fallback; the plan's earlier `relay-automation/swarm-preflight.sh` path was
   wrong, per round-1). When `acc_items` is known and zero, emit a stderr warning naming the doc
   and the fix **before the dry-run exit** (~:1688-1694) so dry runs see it too; exit codes
   unchanged; `SP_ACC_INLINE.criteria` already records the zero truthfully (no new packet field —
   avoids duplicating truth).

## Non-goals (deferred — follow-up issues to be filed and parked)

- **Gate-red auto-recycle** (`--fix-rounds N`): escalation + token lifecycle semantics in both
  driver runtimes; feature-sized arc of its own.
- **Operator-block preservation across relay re-renders / `--handback`**: render-semantics change;
  interacts with the GH-505 attestation model.
- **Preflight `--scaffold`**: new intake subcommand; own contract discussion.
- **Dual-home contracts** (issue-body contract fallback): changes the `--gh-issue` resolution
  contract in `MACHINE-CONTRACTS.md`.
- **claude-turn bash-twin effort parity**: dispositioned by GH-308 — frozen fallback stays frozen.

Also dispositioned: `find-harness.sh` vendored-diff warning polish (minor; fold into any future
find-harness touch), ledger-absent-in-stale-vendors (consumer remedy is re-vendor; #621).

## Implementation order (verification inline)

1. **p1 — vendor excludes** (item 1). Verify in the **disposable full clone**: updated
   `test/xyz-vendor.sh` + new focused-suite cases green across the three Git shapes.
2. **p2 — Opus-budget warning + token auto-suffix + worktree copy** (items 2–4). Verify: focused
   suite — warning emitted/suppressed correctly; stub `tick` matrix (spent → `-R2` announced;
   explicit id untouched; missing tick → fail fast); tmp repo with `node_modules` (disposable copy
   present in worktree, size/time recorded, absent-behavior unchanged).
3. **p3 — `utils/py/xyz_init_clone.py`** (item 5). Verify: e2e against a local bare fixture repo —
   name derivation + `-r2` retry, `--umbrella` required, occupied/existing-dir refusals, vendor ran
   with `--with-releases`, hooks installed when present.
4. **p4 — preflight zero-criteria warning** (item 6). Verify: warning on a checklist-less doc in
   both normal and `--dry-run` paths; existing preflight suites green.
5. **Gates** — implementation edits in the task clone; **all `test/*.sh` runs, `./validate.sh`,
   and `bash ci-local.sh` run in a separate disposable full clone** (AGENTS.md:15-16) — a sibling
   `git clone` of the task clone whose origin is the task clone and which never pushes. After any
   `relay-automation/` edit: regenerate `relay-pkg.tar.gz` (`skills/relay-automation/make-pkg.sh`)
   and pass the freshness check. **`bash ci-local.sh` exactly once on the final commit** in the
   disposable clone; cite that SHA in the PR.

## Bounded test scope

One new focused suite, `test/gh642-consumer-fruit.sh`, covering the six items with tmp-dir
fixtures (bare repo + linked worktree + separate-git-dir shapes, stub `tick`, stub claude binary,
local bare remote for the initializer e2e). **Test non-scope:** no new test framework, no live
CLI/network calls, no fuzzing, no hosted-CI simulation. Existing suites pinning touched behavior
(`test/xyz-vendor.sh`, `test/gh312-vendor-preserves-state.sh`, preflight suites, parity suites)
stay green, with item-1 destination assertions moved in the same commit.

## Risks / rollback

- Item 1 changes documented vendor behavior; consumers relying on `.gitignore` semantics lose
  nothing (exclude is honored by `git check-ignore` and the driver's committability probe).
  Rollback: revert one hunk + its assertions.
- Item 3 changes which token id a forced re-fire claims. Guarded: only auto-derived ids, only
  spent tokens, `--force` only; explicit ids win; receipt identity stays singular. Rollback:
  revert one hunk.
- Item 4 adds per-turn copy cost proportional to `node_modules` size; the test records the
  observation so the cost is visible. Rollback: revert one hunk.
- Items are independent; any can land or revert alone. No schema/DB format changes beyond the
  roadmap row already written.
