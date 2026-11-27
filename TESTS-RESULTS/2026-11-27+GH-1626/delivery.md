# GH-1626 delivery evidence

The landing loop now calls `prune_retained_scratch` only with `--execute`. The guard applies during finalization, including early returns from the loop. The pruning helper and the current run’s own scratch cleanup retain their existing behavior.

## Manual check

On 2026-11-27 UTC, using Python 3.14.7 on Darwin arm64, ran the retained probe from the relay worktree before and after editing `merge_cleanup.py`.

```sh
TMPDIR="$PWD/.relay-scratch" PYTHONDONTWRITEBYTECODE=1 \
  python3 TESTS-RESULTS/2026-11-27+GH-1626/readiness_probe.py
```

| Source | Fixture prefix | Dry run kept old folder | Execute kept old folder | Probe exit |
|---|---|---|---|---|
| Before edit | `merge-cleanup-` | No | No | 1, dry run pruned retained scratch |
| After edit | `merge-cleanup-` | Yes | No | 0 |
| After edit, in-memory fixture variant | `merge-check-` | Yes | No | 0 |

Both landing calls in each run returned `0` and refreshed fixture PR `9` exactly once. The variant used the same probe with `merge-check-oldprobe/repo` and three `merge-check-newer00{i}` fixtures. It exercised real directory deletion in the isolated temp root. The fixture stubs PR refresh, merge policy and capability, origin lookup, the competing-run check, and `lsof`.

SHA-256 of `merge_cleanup.py` before the edit was `95f4ec318806edef968ffa28097e1f41866a4849a189645a4f5e9d4aa099e181`. After the edit it was `cf6153e42e4fef101cb8689f83a8e6d52e66d85fd3c1e4b795801456284008f9`.

The builder turn reserved `test/gh436-merge-cleanup.sh` for the relay harness. Its result was pending at handoff. The builder reviewed the merge-cleanup assertions in `test/gh549-work-events.sh` and left the suite unchanged.
