---
Goal: QA the plan to remove AEGIS's fork of releases_app.py via an upstream setting
Date: 2026-09-09
NEXT: Reviewer
STATUS: Open
---

# Context

You are reviewing a **plan**, not code. Challenge whether it is the right shape, or whether it
digs a bigger hole. Be concrete and adversarial.

## The situation (all measured 2026-09-09, not assumed)

`HiQS-Labs/AEGIS-Sleuth-Slackbot` carries a tracked file `utils/py/releases_app.py`. It is a
**fork** of this repo's `utils/py/releases_app.py`. The vendoring tool (`relay-automation/xyz-vendor.sh`)
writes only into the target's gitignored `.xyz/`, so it never updates that tracked copy, and
`xyz-sync.sh check` reports `ok` while the fork rots.

Measurements:

- tracked fork: 3798 lines. vendored/upstream: 5503 lines.
- Diffed against its closest upstream ancestor (`33da1bac`), the fork is **17 lines, 2 hunks**.
  The rest of the line gap is age, not divergence.
- **Zero** functions exist only in the fork.
- Hunk 1 (the real deviation, at fork line 1768):
  ```python
  # AEGIS-SLEUTH DEVIATION from upstream releases_app.py (not present in XYZ-forge):
  # this repo's RELEASES.md convention is literal "Release: TBD" on every block that
  # hasn't shipped a version yet ... The upstream schema already supports "no version yet"
  # as SQL NULL (releases.version is nullable and UNIQUE(repo_id, version) permits any
  # number of NULLs), it just never maps the literal string "TBD" to it.
  if version == "TBD":
      version = None
  ```
- Hunk 2: a `re.DOTALL` fix on `INSERT_RE` that **upstream already had independently**. It was
  re-derived and re-fixed downstream (AEGIS #183/#184) purely because someone was reading the fork.
  That is the concrete cost already paid.
- Capability drift: the vendored copy has `roadmap rate`, `repoint`, `update`, `move`. The fork has
  none of them. AEGIS's `ROUTER.md` documents the **fork's** path, so following the docs gets the
  copy that cannot do half the job.

## The proposed plan

1. **Upstream (this repo, issue #525):** add a setting, proposed `unshipped_version_token`,
   default unset. Read it at the import site. When set, a `Release:` value equal to that token is
   stored as SQL NULL instead of a version string. Off by default, so no existing install changes.
   Mechanism already exists: `get_setting(conn, key, default)` at `utils/py/releases_app.py:432`;
   current settings rows in AEGIS are `enforcement`, `generation`, `repo_slug`.
2. **Downstream (AEGIS, issue #187):** delete the local edit, adopt the upstream file verbatim,
   set `unshipped_version_token=TBD` in `releases.db`, repoint `ROUTER.md` at the canonical copy.
3. **Governance:** add a rule to AEGIS's `AGENTS.md` and `temp/SOP.md` — never edit vendored
   XYZ / PDDA / PRS files in place; if behavior must differ it goes upstream as a setting, and a
   new setting means filing an upstream issue.

Two options were explicitly **rejected** by the operator: porting the TBD behavior upstream as
hardcoded default behavior, and keeping the fork with a CI drift-check.

# Questions

Answer each with a verdict and cite `file:line` where you disagree with a specific claim.

1. **Is a settings row the right seam at all?** The alternative seams are a config file, an env
   var, or a per-repo adapter/hook. The setting lives in `releases.db`, which is a *generated,
   committed* artifact that gets rebuilt by `check --rebuild` and merged by hand across branches.
   Does putting behavior-controlling config inside the same DB that the tool regenerates create a
   bootstrap or merge hazard? Specifically: does the setting survive `check --rebuild`, and what
   happens on a fresh `releases init` before anyone sets it?

2. **Is `unshipped_version_token` the right shape?** Single token vs a list. Should it instead be
   a boolean (`allow_placeholder_version`) plus a fixed token, or a regex? Argue for one and say
   what the others cost. Consider that a repo could legitimately want `TBD`, `N/A`, and `-`.

3. **Does this actually end the drift, or just move it?** After AEGIS adopts the upstream file
   verbatim, nothing prevents the next person from editing it again — the file is still tracked in
   AEGIS. Is a tracked copy of a vendored tool defensible at all, or should AEGIS delete
   `utils/py/releases_app.py` entirely and call `.xyz/utils/py/releases_app.py`? What breaks if the
   tracked copy is deleted (CI, docs, contributors without a vendored `.xyz/`, the gitignore)?

4. **Is the governance rule enforceable, or is it just a note?** A rule in `AGENTS.md` that no
   check enforces is a rule that will be broken again. Name the cheapest mechanism that would have
   actually caught this fork — and say whether it is worth building, or whether the rule plus
   deleting the tracked copy is sufficient on its own.

5. **What is the migration risk?** AEGIS has a live `releases.db` with real history and an intact
   receipt chain. Adopting a 1705-line-newer tool means schema migrations may run. What is the
   order of operations that does not corrupt the ledger, and what is the rollback if the newer tool
   refuses the existing DB?

6. **Is anything in the framing above wrong or overstated?** Especially: is the claim that the fork
   is "only 17 lines of real divergence" safe to act on, given the 1705-line version gap? Say what
   you would verify before trusting it.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered.

Write your verdict below and change STATUS to Approved/Closed if the plan is sound as written.

# QA Verdict

1. **Is a settings row the right seam at all?**
   **Verdict:** Yes, it is an acceptable seam. There is no bootstrap hazard: `releases init` writes a blank DB with defaults, and `get_setting` handles the missing key gracefully by falling back to `None` (preserving standard upstream behavior). The setting survives `check --rebuild` because `load_dump` correctly reads and inserts `settings` rows from the dump (see `utils/py/releases_app.py:4739`). The only friction is the lack of a CLI command to set it, requiring a manual SQL `INSERT` or editing the logical dump, which is acceptable for a one-time configuration.

2. **Is `unshipped_version_token` the right shape?**
   **Verdict:** No. A single token is inflexible because a repo could legitimately want `TBD`, `N/A`, and `-` concurrently. A comma-separated list (e.g. `unshipped_version_tokens=TBD,N/A,-`) is the right shape. It is cheap to implement (`setting.split(',')`) and handles multiple valid placeholders without the fragility or ReDoS risk of a regex. A boolean (`allow_placeholder`) would be imprecise, forcing the parser to blindly accept any non-version string.

3. **Does this actually end the drift, or just move it?**
   **Verdict:** It just moves it. Adopting the upstream file verbatim while keeping it tracked in `utils/py/releases_app.py` guarantees future drift because anyone can edit it again. AEGIS should **delete** the tracked copy entirely. Drift is physically impossible if the file doesn't exist, as `xyz-sync.sh` overwrites the vendored `.xyz/` copy on sync. Deleting it breaks CI, docs (`ROUTER.md`), and local scripts until they are repointed to `.xyz/utils/py/releases_app.py`. Contributors will be forced to run the vendoring script, which is the correct workflow.

4. **Is the governance rule enforceable, or is it just a note?**
   **Verdict:** A rule in `AGENTS.md` is just a note. The cheapest and most absolute enforcing mechanism is deleting the tracked copy (as concluded in Q3) — the vendoring tool automatically clobbers local edits in `.xyz/`. If the file *must* be tracked for some reason, the cheapest automated mechanism is a CI check: `cmp utils/py/releases_app.py .xyz/utils/py/releases_app.py`. Deleting the tracked copy is sufficient on its own and requires no new tooling.

5. **What is the migration risk?**
   **Verdict:** The 1705-line gap means AEGIS might be missing multiple schema migrations. Some migrations might be marked `txn_safe=False`, which causes `releases migrate` to explicitly refuse to run against a live ledger (`utils/py/releases_app.py:1420`). The correct, safe order of operations is: vendor the new tool, then run `releases check --rebuild` (not `migrate`). `--rebuild` safely materializes the new DDL on a fresh DB, parsing the logical dump and bypassing live-ledger restrictions. If the newer tool refuses the existing dump, the rollback is trivial: `--rebuild` creates a `.bak` of the displaced DB, or the operator can simply revert the tool and use the untouched DB.

6. **Is anything in the framing above wrong or overstated?**
   **Verdict:** Yes, the claim that the fork is "only 17 lines of real divergence" is dangerously overstated. While the fork only added 17 lines relative to its *own* ancestor, it ignores the 1705 lines of upstream changes AEGIS is about to inherit. Upstream may have introduced breaking CLI changes, removed features AEGIS relies on, or added new mandatory schema fields. Before trusting this plan, one must verify the upstream changelog between `33da1bac` and `HEAD` for breaking changes, and verify that AEGIS's CI passes cleanly with the new tool.

**Conclusion:** The plan needs adjustments (list instead of single token, deleting the tracked copy instead of verbatim adoption, using `--rebuild` for migration). STATUS remains Open.
<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
