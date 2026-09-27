# GH-842 — hosted catch-up qualifies direct pushes to development (option B)

**Change:** `utils/py/wave_reconcile.py` only (+62). `catch_up_prs`, when qualifying, now also lists
first-parent commits after `DIRECT_COMMIT_CUTOVER` (`41db4367`) and adds each one that is not a PR merge,
not a `github-actions[bot]` commit, not an express landing and not already receipted as a `("commit", sha)`
landing. The existing `--commit` qualifier, tier selection (tier 1 → Small) and receipt matcher do the rest.
`wave-reconcile.yml` already runs `--catch-up --gate --qualify` on every PR-closed, scheduled and dispatched run,
so no workflow change.

**Decisions (settled from the issue and #854, #842 comment):** forward-only from a cutover (D-a); express
landings excluded by their committed `express-landing` receipt (D-b); every other non-bot, non-PR direct commit
qualifies (D-c).

## Evidence (base `41db436717513327626f12da450e907a628ebc85`)

| Check | Result |
|---|---|
| Base control (`base-control.log`) | base catch-up yields only `("pr", n)`; no commit discovery exists |
| Witness, real history, cutover `development~25` (`witness-head.log`) | 25 first-parent commits: 10 PR merges and 10 bot commits skipped; **5 direct pushes qualify** (`85a60f2c`, `07f0c46d`, `4909c482`, `42e85b1c`, `41db4367`) |
| Witness, express range (`witness-express.log`) | express landing `13707659` (GH-801) excluded; its two closeout commits qualify (tier 1, Small) |
| Codex r1 falsifier (`witness-owner.py.txt`) | older PR #5 and a newer, **already-receipted** direct commit both close drifted GH-421. At the reviewed commit `3e58be2d`: commit invisible, PR #5 owns → **FAIL** (`witness-owner-r1.log`). At head: commit owns and is a catch-up landing; after the closeout, a repeat run adds nothing → **PASS** (`witness-owner-head.log`) |
| `test/gh421-auto-wave-reconcile.sh` | OK (catch-up, direct commit, only-receipted owners) |
| `test/gh425-gate-provenance-pr.sh` | OK |
| `test/gh740-hosted-lane-publish.sh` | OK (`--commit` receipt round-trip) |

No new tests (AGENTS.md). The witness (`witness.py.txt`) is a manual script: it runs the real functions against
the live merged-PR listing (read-only) and the real `development` history.

**Codex r1 (`relay-system/2026-09-27/gh842-prdirect-review.md`): FAIL, one finding, accepted and fixed.** A receipted
direct commit's metadata was dropped, so an older PR could own its issue's lifecycle, and an interrupted closeout could
not be recovered. Now every eligible direct commit stays in `metadata` (commit time normalised to UTC like a PR's
`merged_at`), the closed-issue drift loop lets a direct closer own the issue, and only commits flagged `catchUp` become
landings. The real-history witnesses were re-run from a detached `development` worktree, since the hosted lane runs on `development`.

**Known behaviour, by design:** if the cutover commit is absent (a fixture repo), discovery logs
`Direct-commit recovery inactive` and adds nothing; the hosted lane requires a full clone, so the cutover is present there.
