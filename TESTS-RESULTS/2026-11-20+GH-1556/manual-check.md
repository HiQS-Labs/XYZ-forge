# Manual Check — GH-1556 (KS-11: Fail-Closed Decision Defaults)

- **Issue:** #1556 (parent arc #1541, milestone KS-11)
- **Base Commit Before Evidence Commit:** `a28c8b677b9d98833c44b968f58222cdada9799f`
- **Changed Files:** `skills/1-hourly/kickstart/SKILL.md` (lines 142–160), `skills/1-hourly/kickstart/scripts/build_queue.py` (lines 55–63)
- **CI Route:** `route=docs`, `tier=1`, `full_required=false` (`outputs/ci-route.txt`)
- **Static Type Check:** `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py` exit `0` (`outputs/mypy.txt`)

## 1. Pinned Historical Baseline (`outputs/historical-baseline-0edbab45d6.txt`)
- **Classification:** **Historical absence** (NOT a witnessed behavioral failure).
- Verified `git merge-base --is-ancestor 0edbab45d6 HEAD` exit `0`; extracted nonempty pre-KS-03 `build_queue.py` and `SKILL.md` confirming `ks11_mentions=0`, `round_cap_mentions=0`.

## 2. Live `utils/ci-route.sh` Classifier Probes (`outputs/ci-route-probes.txt`)
- `skills/1-hourly/kickstart/SKILL.md` -> exit `0`, `route=docs`, `full_required=false`.
- `githooks/pre-push` -> exit `0`, `route=fast`, `full_required=false`, `tier_reason=unmapped path: githooks/pre-push` (proves `full_required=false` cannot establish absence of a hook surface).
- `validate.sh` (from #1519 / PR #1532) -> exit `0`, `route=full`, `full_required=true`.

## 3. Candidate Sensitivity Ablation (`outputs/ablation-githooks-pre-push.txt`)
- Held all predicates constant on `githooks/pre-push` (`full_required=false`, current-head reviewer approval, reviewer-tagged & accepted Minor/nit deferral, reversible).
- **Ablated scratch copy** (independent protected-surface clause removed, `full_required`-only): fails to block deferral on `githooks/pre-push` (**unsafe permission / missing prohibition**).
- **Actual candidate** (`SKILL.md:146-151`, `build_queue.py:55-61`): **observed PARK** citing the quoted independent hook-surface prohibition.

## 4. Bounded Policy Walkthrough Matrix (Observed vs Expected Recorded Separately)

> Sourced fields in case KS-11a-2 come verbatim from live `gh pr view 1532` retained in `outputs/gh1519-pr1532-input.json`. All synthetic control fields in cases KS-11a-1/3/4/5, KS-11b-1, and KS-11c-1..4 are explicitly labeled **reconstructed**.

| Case | Source / Labeling | Quoted Policy Location | Evaluated Predicates | Baseline (`0edbab45d6`) Observed | Candidate Observed Action & Disclosure | Expected |
|---|---|---|---|---|---|---|
| **KS-11a-1** | Synthetic (reconstructed): docs-only `SKILL.md`, `full_required=false`, current-head approval, reviewer-tagged & accepted Minor/nit | `SKILL.md:146-152`, `build_queue.py:55-62` | `head_match=True`, `minor_tagged_accepted=True`, `protected_surface=False`, `full_required=False`, `reversibility=Easy` | No rule (historical absence; operator question) | **LAND** with explicit Minor/nit deferral disclosure in PR body & run record (never unqualified `Approved`) | LAND + disclosure |
| **KS-11a-2** | **Sourced verbatim (`outputs/gh1519-pr1532-input.json`):** PR #1532 (`headRefOid` `2a3601a9...`, `validate.sh`, 3-round cap with open provenance nit) | `SKILL.md:146-152`, `build_queue.py:55-62` | `head_approved=False`, `changed_files` includes `validate.sh` (`full_required=True`, gate surface) | No rule (historical absence; triggered #1519 question) | **PARK** in `PARKED/` and continue independent work (no operator question) | PARK |
| **KS-11a-3** | Synthetic (reconstructed) + live probe: `githooks/pre-push` (`full_required=False`), current-head approval, accepted Minor/nit | `SKILL.md:148-151`, `build_queue.py:57-60` | `head_match=True`, `minor_tagged_accepted=True`, `full_required=False`, **direct file inspection: hook surface (`githooks/*`)** | No rule (historical absence) | **PARK** (independent hook prohibition overrides `full_required=false`) | PARK |
| **KS-11a-4** | Synthetic (reconstructed): `full_required=True` or Costly / unknown reversibility with accepted Minor/nit | `SKILL.md:148-151`, `build_queue.py:57-60` | `protected_or_unknown=True` | No rule (historical absence) | **PARK** (`unknown -> PARK`, Costly/gate blocks deferral) | PARK |
| **KS-11a-5** | Synthetic (reconstructed): stale approval (`reviewed_sha != current_head`) on docs-only PR | `SKILL.md:146`, `build_queue.py:55` | `head_match=False` | No rule (historical absence) | **PARK** (approval does not cover final head SHA) | PARK |
| **KS-11b-1** | Synthetic (reconstructed): `merge-cleanup` landing forecast identifies PR as conflict hub | `SKILL.md:153`, `build_queue.py:63` | `forecast_conflict_hub=True` | No rule (historical absence) | **SEPARATE RECORDED BATCH** (do not stall clean PRs or ask operator) | Separate batch |
| **KS-11c-1** | Synthetic (reconstructed): `--owner` comment releasing hold, applicable to current issue/head, not superseded (positive control) | `SKILL.md:154`, `build_queue.py:65` | `author==owner`, `applicable=True`, `superseded=False` | No rule (historical absence) | **RELEASE** hold and proceed | RELEASE |
| **KS-11c-2** | Synthetic (reconstructed): `--owner` comment inapplicable to current issue/head | `SKILL.md:154`, `build_queue.py:65` | `author==owner`, `applicable=False` | No rule (historical absence) | **HOLD** (stays parked) | HOLD |
| **KS-11c-3** | Synthetic (reconstructed): non-owner comment attempting hold release | `SKILL.md:154`, `build_queue.py:65` | `author!=owner` | No rule (historical absence) | **HOLD** (unauthorized author ignored) | HOLD |
| **KS-11c-4** | Synthetic (reconstructed): earlier `--owner` release superseded by later owner hold or run-record amendment | `SKILL.md:154`, `build_queue.py:65` | `author==owner`, `superseded=True` | No rule (historical absence) | **HOLD** (superseded release does not unlock) | HOLD |

## 5. Governance & Provenance
- `env -u PDDA_LLM_BIN bash ./utils/pdda/pdda.sh run` (`outputs/pdda-run.log`): `0` errors.
- No `CHANGELOG.md` edit on task branch (honoring `CHANGELOG_WRITES` policy); no new test suites (GH-831).
- `provenance.jsonl`: SHA-256 and byte counts for all retained artifacts.
