# GH-1527 manual check — build_queue.py against the 2026-11-19 hand queue

Manual check, not a test suite (AGENTS.md *No new tests*, GH-831). Candidate commit and file hashes
are in `provenance.jsonl`.

## Inputs (saved 2026-11-19 ~23:15Z, after PR #1525 merged at 22:53Z)

- `inputs/pr_minder.json` — `python3 skills/2-daily/pr-minder/scripts/pr_minder.py --json --repo-root .`
- `inputs/pr_meta.json` — `gh pr list --state open --limit 300 --json number,author,title,body,mergeable`
- `inputs/issues.json` — `gh issue list --state open --limit 1000 --search "created:>=2026-11-05" --json number,title,labels,body,createdAt`

Command (both replay runs):

```
python3 skills/1-hourly/kickstart/scripts/build_queue.py --as-of 2026-11-19 --owner noelsaw1 \
  --other-session 1400,1418 --needs-operator 1435,1427 \
  --prs-json inputs/pr_minder.json --pr-meta-json inputs/pr_meta.json --issues-json inputs/issues.json \
  --out queue-replay-N.md
```

## Results

| Check | Observed | Verdict |
|---|---|---|
| Determinism | `cmp queue-replay-1.md queue-replay-2.md` → exit 0 | pass |
| Main path (live, no saved inputs, owner from `gh api user`) | `queue-live.md`, exit 0; body identical to the replay (`diff` of all lines after the header → no output) | pass |
| Adjacent path (replay without `--owner`) | refused: `build_queue: replay needs --owner (saved inputs must not depend on who runs it)`, exit 1 | pass |
| Held PR routes to Needs-operator | `routing/out-held-other.md` (copy of inputs with `held` set on #1417): #1417 in_queue=False in_needs=True | pass |
| Non-owner PR routes to Needs-operator | same run, #1460 author set to `someone-else`: in_queue=False in_needs=True | pass |
| `--other-session` applies to PRs | `routing/out-other1526.md`: #1526 in_needs=True, not in queue | pass |
| `--needs-operator` applies to PRs | `routing/out-decide1526.md`: #1526 in_needs=True, not in queue | pass |
| Same PR with no override | `routing/out-base.md`: #1526 in queue (bucket A), #1417 in queue | pass |
| **Red control** | `routing/out-red-control.md` = held-run output with #1417 hand-moved into the queue: assertion prints `#1417 want=needs in_queue=True in_needs=True -> FAIL`, exit 1 | assertion rejects a wrong output |

Routing assertion used for the rows above (run from a scratch directory, kept here as text):

```python
import re,sys
# route_check.py OUTPUT.md NUMBER queue|needs -> exit 0 if #NUMBER sits only in that section
text=open(sys.argv[1]).read(); n=sys.argv[2]; want=sys.argv[3]
q=text.split("## Queue (execution order)")[1].split("## Needs the operator")[0]
nd=text.split("## Needs the operator")[1].split("## Not queued")[0]
pat=re.compile(rf"#{n}\b")
inq,inn=bool(pat.search(q)),bool(pat.search(nd))
ok=(inq and not inn) if want=="queue" else (inn and not inq)
print(f"#{n} want={want} in_queue={inq} in_needs={inn} -> {'PASS' if ok else 'FAIL'}"); sys.exit(0 if ok else 1)
```

## Diff against the hand queue (`temp/kickstart-2026-11-19-a6590cb2.md`, primary checkout, local only)

Completion rule: every difference is live-state drift (cited from the saved inputs) or a stated
rule. Defects found by this diff during the build were fixed before this receipt (below).

| Hand queue | Generated | Explanation |
|---|---|---|
| 0a #1526 merge when CodeRabbit clean | 1. #1526 CLEAN | match |
| 1 #1525 CLEAN | absent | drift: merged 476326496 at 22:53Z, before inputs were saved |
| 0b #1527 codify | 14. #1527 small bug | rule E7 (title names `build_queue.py`); the in-flight task itself. Once its PR (title `GH-1527`) is open, rule 3 folds it into that PR's line |
| 2 #1501 CONFLICTING | 7. #1501 B (closes #1487) | match; fold via `Closes #1487` |
| 3 #1507 with #1506 | 8. #1507 B (closes #1506) | match |
| 4 #1460 with #1459 | 3. #1460 B (closes #1459) | match |
| 5 UNKNOWN batch #1497 #1496 #1495 #1471 #1467 #1417 | B: #1417 #1467 #1471 #1497; C batch: #1495 #1496 | drift: inputs show `conflicting: true`, `mergeable: CONFLICTING` for the first four; `behind: true`, `MERGEABLE` for #1495/#1496 |
| 6 drafts #1391 #1024 | 10. draft #1391 (closes #1386); #1024 → Needs-operator | rule PR3: #1024 carries pr_minder `held: Review authority limit / unresolved escalation` |
| 7 #1519 | 13. E | match |
| 8 #1517 express docs | 16. F | match (after fix 1) |
| 9 #1500 #1499 | 11, 12. E | match |
| 10 #1522 | 17. F | match |
| 11 #1508 | Needs-operator (unclassified) | rule 9: no label, title names no file |
| 12 stale #1412 #1408 #1398 #1394 #1386 #1441 #1523 | 18. G: #1374 #1375 #1380 #1394 #1398 #1408 #1412 #1441 #1523 | #1386 folded into draft #1391 (title `GH-1386`, rule 3); #1374 #1375 #1380 added by rule 4 (`merge-batch` label, created 2026-11-08, inside the 14-day window) |
| 13 refactors #1480–#1483 after #1475 #1467 #1471 | 19–22. H with #1475, #1467, #1471; #1483 "no predecessor named" | rule 5 reads `after #N` from title/body; #1483 names none |
| 14 final QA | 23. final QA | match |
| — | 15. #1473 F | rule 6 (title names `CHANGELOG.md`); the hand queue cited #1473 only as an overlap check under item 2 |
| Needs-operator #1518 #1435 #1427 #1400 #1418 | all present | `decide` title regex (#1518), `--needs-operator`, `--other-session` |
| — | Needs-operator: 15 unclassified issues in the window | rule 9: the hand queue omitted them silently; the builder hands scope to the operator instead of guessing |
| — | Not queued: #1352 #1383 #1474 #1476 #1477 #1520 | rule 8 title prefixes (Radar, Umbrella, Research, Plan, Spike, Daily goals) |

## Defects the diff found during the build (fixed before this receipt)

1. #1517 routed to G: bare `\bsweep\b` matched "auto-sweep". Rule 4 narrowed to
   `^\S+ sweep <YYYY-MM-DD>`; plan updated.
2. #1526's line said "(closes #1518)" although #1518 is an operator decision. Folded mentions now
   exclude issues routed to Needs-operator (issue rules 1–2 win).

Verdict: pass. No unexplained difference remains.
