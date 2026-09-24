# Conflict magnets — captured-window measurement

The inputs establish ledger conflict involvement, but **complete per-file counts of PRs needing manual/B1 resolution are not derivable from inputs**. The observed counts below are lower bounds on conflict involvement, not estimates of the missing totals. No Git command was run during this turn.

The history captures cover the brief's 2026-08-31 through 2026-09-21 window (`--since=2026-08-31 --until=2026-09-22`). They aggregate paths and retain subjects, not per-file conflict hunks or repair results. A touched file is not necessarily a conflicted file. Despite its description as non-merge history, `resolver-commits.txt` includes merge subjects and overlaps the merge capture; do not add their lengths or treat matching “resolve” subjects as resolution evidence. Issue numbers in branch names are not PR numbers. Candidate-to-PR attribution beyond explicit PR subjects is not derivable from inputs.

The attempt records identify PR #723 as a B1 handoff with `releases.db` among its conflicts; they do not establish that its ledger repair completed. PR #688 has a resolved B1 attempt and repair commit `2e5a26f931f604473c4227d02f635dd1116abbee`, but an empty `conflict_files` list: attribution to any target file is not derivable from inputs. Empty attribution is unknown, not proof of no conflicts. The capture's directory listing also contains lock filenames; locks are not attempt records and are not counted.

| File | Actual window total needing manual/B1 resolution | Interpretation of observed count below |
|---|---|---|
| `validate.sh` | not derivable from inputs | No file-attributed PR in supplied attempts; no evidence of absence |
| `skills/relay-automation/relay-pkg.tar.gz` | not derivable from inputs | No file-attributed PR in supplied attempts; no evidence of absence |
| `releases.db` | not derivable from inputs | PR #723 is confirmed conflict involvement, with handoff outcome |

Decision — `validate.sh`: **registry** (derive the `TESTS` list from `test/*.sh` + an explicit exclusions list; the frozen-twin and registration guards must still fire). Retain as a conditional follow-up recommendation: the shared list is visible in `validate.sh`, but this capture cannot quantify resolution savings. Do not implement or prioritize it on a fabricated conflict count.

Decision — `skills/relay-automation/relay-pkg.tar.gz`: **tarball** (generate on demand / in CI instead of committing; first check who consumes the committed bytes). Recommend only after preserving the documented extraction install and the package-presence/extraction/freshness/path-integrity checks quoted below. They currently consume the committed bytes; simply deleting the archive breaks that contract. Conflict savings are not established by these inputs.

Decision — `releases.db`: **ledger** (the #496 Phase 3 spike, held). Keep held: the explicit ledger conflict and the unattributed B1 repair justify investigating transport separately, not untracking the database in this measurement lane.

Run the following command from the repository root; its output immediately follows. The accompanying provenance record also contains a self-contained command that reproduces this whole report. Source-line evidence reflects this checkout, while numerical counts use only the captured inputs.

```sh
python3 - <<'PY'
from pathlib import Path
import json
p = Path('TESTS-RESULTS/2026-09-22+GH-732/c1')
records = [json.loads(f.read_text()) for f in sorted((p/'attempt-records').glob('*.json'))]
assert records, 'empty attempt corpus'
lo, hi = '2026-08-31', '2026-09-22'
active = [(r, [a for a in r['attempts'] if lo <= a['started'][:10] < hi and a['rung'] == 'B1']) for r in records]
active = [(r,a) for r,a in active if a]
assert active, 'no in-window B1 attempts'
print('Window: '+lo+' <= attempt local date < '+hi)
print('B1 records:', len(active))
for r, attempts in active:
    print('PR', r['pr'], 'conflict_files='+json.dumps(r['conflict_files']), 'attempts='+json.dumps([{k:a[k] for k in ('started','outcome','commit','reason') if k in a} for a in attempts], sort_keys=True))
print('\nPer-file confirmed involvement (NOT completed manual-resolution totals):')
for name in ('validate.sh','skills/relay-automation/relay-pkg.tar.gz','releases.db'):
    prs = sorted({r['pr'] for r,a in active if name in r['conflict_files']})
    resolved = sorted({r['pr'] for r,a in active if name in r['conflict_files'] and any(x['outcome']=='resolved' for x in a)})
    print(name, 'confirmed B1 conflict PRs='+str(len(prs)), 'PRs='+str(prs), 'file-attributed resolved PRs='+str(len(resolved)), 'PRs='+str(resolved))
print('\nB1 PRs without file attribution:', sorted({r['pr'] for r,a in active if not r['conflict_files']}))
for name in ('merge-commits-touching-magnets.txt','resolver-commits.txt'):
    rows = [s for s in (p/name).read_text().splitlines() if s.strip()]
    assert rows, 'empty history capture'
    print('\n'+name+': '+str(len(rows))+' candidate rows (not conflicts or PR counts)')
    print('Candidate SHAs: '+', '.join(s.split()[0] for s in rows))
print('\nConsumer evidence (source lines, not tests executed):')
for name in ('skills/relay-automation/SKILL.md','test/skill-extract.sh','test/relay-pkg-freshness.sh','test/path-integrity.sh'):
    lines = [(i,s) for i,s in enumerate(Path(name).read_text().splitlines(),1) if 'relay-pkg.tar.gz' in s or 'tar xzf' in s]
    assert lines
    for i,s in lines: print(f'{name}:{i}: {s}')
PY
```

```text
Window: 2026-08-31 <= attempt local date < 2026-09-22
B1 records: 2
PR 688 conflict_files=[] attempts=[{"commit": "2e5a26f931f604473c4227d02f635dd1116abbee", "outcome": "resolved", "started": "2026-09-17T21:47:45-0700"}]
PR 723 conflict_files=["CHANGELOG.md", "LEADERBOARD.md", "releases.db", "releases.sql"] attempts=[{"outcome": "handoff", "reason": "code/doc conflict outside the ledger set: CHANGELOG.md", "started": "2026-09-21T17:27:36-0700"}]

Per-file confirmed involvement (NOT completed manual-resolution totals):
validate.sh confirmed B1 conflict PRs=0 PRs=[] file-attributed resolved PRs=0 PRs=[]
skills/relay-automation/relay-pkg.tar.gz confirmed B1 conflict PRs=0 PRs=[] file-attributed resolved PRs=0 PRs=[]
releases.db confirmed B1 conflict PRs=1 PRs=[723] file-attributed resolved PRs=0 PRs=[]

B1 PRs without file attribution: [688]

merge-commits-touching-magnets.txt: 29 candidate rows (not conflicts or PR counts)
Candidate SHAs: 304b52dd, 4424c9ef, f660eadd, f213272c, 5bf6ef3a, 3549a994, 443b0c70, 196424fb, e344a1bd, 3425e65a, 97620bc4, 3807434c, 939be43a, bb198b62, 676baab1, 1dddcda8, 04b8e9e0, 3833e2e7, c15ca0f5, e0e70215, a48189fc, 2867af9d, e363aba1, 4fe61689, 425f558f, 711aa0c2, cf951476, fced2191, 21004b3c

resolver-commits.txt: 72 candidate rows (not conflicts or PR counts)
Candidate SHAs: 9c384240, e565c0fe, 25c84cbd, 5107b99d, ab3a75d5, bd8c6950, 5e60cb01, 3ea01917, 6928de21, 1e434d58, 7689a2ae, 43cf4452, ef781146, 49e5b9a4, 74daa7d2, 9e1e9bf4, 567d50df, d5c18633, 731ae5f0, a67b3df8, 3ca5ad55, 526433d4, 69ca13ea, 99c263ea, 308dd184, 062e94aa, 52938679, 02268668, 4648460d, d78711cd, 03189d0c, b4966580, 201fcc44, 5ba227b0, 5830b536, 3d80fcfc, f213272c, 5bf6ef3a, 2aa33011, 3549a994, 443b0c70, 196424fb, e10a1b16, 3425e65a, 98f927f8, 6a6a26f3, bb198b62, bbbeda01, 1dddcda8, 28f85a17, 04b8e9e0, e53f5d06, d732760e, c15ca0f5, d589322f, b7a4a1bb, 87e30924, e0e70215, a48189fc, e363aba1, 4fe61689, 425f558f, 711aa0c2, ea983859, 56f01563, 96d4f388, b5460ce7, aed7c2d1, 557ece5a, 2511f77b, 21004b3c, 2526bf9b

Consumer evidence (source lines, not tests executed):
skills/relay-automation/SKILL.md:14: ## Components (in `relay-pkg.tar.gz` beside this file)
skills/relay-automation/SKILL.md:56: The relay scripts + tests ship as `relay-pkg.tar.gz` beside this SKILL.md (regenerable
skills/relay-automation/SKILL.md:62: tar xzf skills/relay-automation/relay-pkg.tar.gz -C "$DIR"
test/skill-extract.sh:7: PKG="$ROOT/skills/relay-automation/relay-pkg.tar.gz"
test/skill-extract.sh:9: [ -f "$PKG" ] && pass "relay-pkg.tar.gz present beside the skill" || fail "package missing — run skills/relay-automation/make-pkg.sh"
test/skill-extract.sh:12: tar xzf "$PKG" -C "$D"
test/relay-pkg-freshness.sh:5: PKG="$ROOT/skills/relay-automation/relay-pkg.tar.gz"
test/relay-pkg-freshness.sh:7: [ -f "$PKG" ] && pass "relay-pkg.tar.gz present" || fail "package missing: $PKG"
test/relay-pkg-freshness.sh:11: tar xzf "$PKG" -C "$D"
test/relay-pkg-freshness.sh:34:   || fail "relay-pkg.tar.gz is stale — run skills/relay-automation/make-pkg.sh"
test/path-integrity.sh:24: TARBALL="$ROOT/skills/relay-automation/relay-pkg.tar.gz"
test/path-integrity.sh:42:   fail "packaging files missing: expected make-pkg.sh + relay-pkg.tar.gz under skills/relay-automation/"
```
