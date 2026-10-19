# GH-1169 verification — express vendored-host mode

Manual checks and existing-suite runs for [#1169](https://github.com/HiQS-Labs/XYZ-forge/issues/1169) at `dc33ddfd`.
No suite or registry entry was added (GH-831). Suites and host scenarios ran in a disposable `--no-local` clone of the
task branch. Machine paths are replaced with `~`, `<tmp>`, `<W>` and `<scratch>`.

Host fixture (`host-fixture.sh.txt`, driven by `run-all.sh.txt` → `host-checks.log.txt`): a bare clone of the local
HiQS-Labs/XYZ-layout-engine at a local path ending `github.com/HiQS-Labs/XYZ-layout-engine.git` (so the reconciler's
slug regex sees the real identity and nothing reaches GitHub), a working clone with `origin/HEAD → origin/main`, `.xyz/`
vendored from this branch with `xyz-vendor.sh --no-register`, the host's own PDDA install (`observe` mode), a `gh` stub
(issue view/close, repo view, issue API) and a temp `HOME`. Each scenario starts from a fresh fixture.

| Check | Result |
|---|---|
| Covering suites, unchanged | `gh267-express-skill` 113/0, `gh358` 8/0, `gh425` OK, `gh429` 15/0 (`suite-*.log.txt`) |
| S1 dry-run `check --docs-only` | PASS; suite `utils/pdda/pdda.sh run (host PDDA gate, PDDA_MODE=full…)`; gate `none — this host has no pre-push hook…` |
| S2 clean non-preview `run --docs-only` | rc 0; landing reachable from bare `main`; no `development` branch created; host clean on `main` and equal to bare `main`; receipt `commit` = landing SHA, `command` `bash utils/pdda/pdda.sh run`, `rc` 0, `environment` `express driver, direct main push`; one `gh issue close`; ship and reconcile persisted |
| S3a host PDDA with a doc lacking frontmatter | `observe` (host default) rc 0 — the defect passes; `PDDA_MODE=full` rc 1 (`missing YAML frontmatter`, `missing usable '## Status' table`) — why the lane forces full mode |
| S3b red control: non-preview `run --docs-only` with that doc | rc 3 `suite-red — utils/pdda/pdda.sh run exited 1`; bare `main` unchanged; no receipt on disk; no `issue close`; issue still OPEN |
| S4 red control: root `utils/py/wave_reconcile.py` decoy (exit 99 + marker) | clean landing rc 0; marker absent — express ran the vendored reconciler |
| S5a non-docs, `--suite test/demo.sh`, no `validate.sh` | rc 3 `suite-unregistered — no validate.sh TESTS registry…`; no traceback (before GH-1169: `FileNotFoundError`) |
| S5b non-docs, `--suite "utils/pdda/pdda.sh run"` | rc 3 `suite-missing`; no traceback; no docs bypass by spelling |
| S6 red control: vendored branch disabled (canonical express from the Forge clone on the same host) | rc 3 `gate-unwired` — today's behaviour, which the vendored branch replaces |
| S7 `express.releases_app(host)` with a root `utils/py/releases_app.py` | vendored → `<host>/.xyz/utils/py/releases_app.py`; canonical → `<host>/utils/py/releases_app.py` |
| S8 recovery recipe exactly as documented for vendored hosts (canonical steps 1–7 incl. identity snapshots; `REPO`, full-mode PDDA command, `.xyz/utils/py` driver, `resume … --repo "$REPO"`), broken landing | recipe rc 1; documented `resume` rc 4 `no COMMITTED valid express receipt…`, writes nothing |
| S8 same, clean landing | recipe rc 0, receipt committed with `recovery-run.log`; documented `resume` rc 0, closes the issue and reconciles |
| Smoke, main path (GH-1088) | fresh GitHub clone of XYZ-layout-engine with `.xyz/` from `944c43c9`: `check --issue 38 --docs-only --dry-run` → PASS (`origin/main`, host PDDA gate, no pre-push hook) → `smoke-host-xyz-layout-engine.log.txt` |
| Canonical parity, successful path (final QA F2) | fresh GitHub clone of XYZ Forge at `7eeae804`, gate installed, one-line README change, open issue #1169: `check --docs-only --dry-run` with the `origin/development` driver and with this branch's driver → both rc 0 `PASS`, output byte-identical (`canonical-compare.sh.txt` → `canonical-compare.log.txt`). The first run of this comparison found an extra `gate :` line in canonical output; fixed in `dc33ddfd` (printed only when vendored) |
| Canonical recovery text | same script: `recovery_recipe` for `test/pdda-repo-contract.sh` and `test/gh267-express-skill.sh` byte-identical to `origin/development` |

Observed during the run: overriding `HOME` hides `gh`'s login, so the first host smoke failed `issue-missing`; it was
rerun with the real `HOME` (the fixture scenarios use the `gh` stub, so they keep a temp `HOME`). The dry-run `run`
in S1's first draft stopped at `roadmap-identity` because a dry-run ledger phase parks nothing; S1 therefore records
`check`, and S2 exercises the full motion.
