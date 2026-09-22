# Hosted reconciliation lane — captured snapshot

This report recomputes the supplied `runs-40.json`; it is not a live GitHub query. All run ids, bucket counts, dates and streaks below come from the command shown here. “Green” means the captured workflow conclusion is `success`, not an independent attestation that every intended reconciliation effect occurred. The denominator includes cancelled runs and all event types in the capture.

Comparison baselines are reported historical observations: **7/40 at #732 v6 on 2026-09-21** and **14/40 at triage on 2026-09-22**, supplied by the phase brief and the canonical GH-732 working document. Their original snapshots are not supplied, so this report does not claim to recompute those historical populations. The command uses them only for comparison arithmetic and independently counts the current file.

The issue requires **10 consecutive green scheduled/PR-closed runs**, with #741 landed so failures name their real cause. The command reports both the literal head streak and the schedule/pull_request head streak. The capture identifies `pull_request` events but does not retain their action, so PR-closed eligibility cannot independently be verified here. Neither #741 landing status nor failure-cause correctness is attested by this snapshot. The numerical streak requirement is unmet regardless.

Run the following command from the repository root; its output immediately follows. The provenance command reproduces the whole report without network access.

```sh
python3 - <<'PY'
from pathlib import Path
import json, itertools
p = Path('TESTS-RESULTS/2026-09-22+GH-732/d2')
runs = json.loads((p/'runs-40.json').read_text())
assert runs and len(runs)==40, 'missing or incomplete capture'
assert len({r['databaseId'] for r in runs})==len(runs), 'duplicate run ids'
assert all(r['status']=='completed' and r['conclusion'] in ('success','failure','cancelled') for r in runs)
assert all(a['createdAt']>=b['createdAt'] for a,b in zip(runs,runs[1:])), 'input not newest first'
print('Capture:', (p/'runs-40.CAPTURE.txt').read_text().strip())
print('Runs:', len(runs))
print('Created-at range (UTC):', min(r['createdAt'] for r in runs), 'through', max(r['createdAt'] for r in runs))
for conclusion, label in [('success','green'),('failure','failed'),('cancelled','cancelled')]:
    ids = [r['databaseId'] for r in runs if r['conclusion']==conclusion]
    print(f'{label}: {len(ids)}/{len(runs)} ({len(ids)/len(runs):.1%}); run ids: '+', '.join(map(str,ids)))
head = list(itertools.takewhile(lambda r:r['conclusion']=='success',runs))
eligible = [r for r in runs if r['event'] in ('schedule','pull_request')]
assert eligible
streak = list(itertools.takewhile(lambda r:r['conclusion']=='success',eligible))
print('Consecutive green at head:',len(head),'ids:',[r['databaseId'] for r in head])
print('Consecutive green schedule/pull_request at head:',len(streak),'ids:',[r['databaseId'] for r in streak])
print('Required streak: 10; numerical exit condition met:',len(streak)>=10)
print('Historical comparisons (reported baselines from phase brief, not recovered historical snapshots):')
green = sum(r['conclusion']=='success' for r in runs)
for label, old in [('2026-09-21, #732 v6',7),('2026-09-22, triage',14)]:
    print(f'{label}: {old}/40 ({old/40:.1%}); current difference: {green-old:+d} green, {(green-old)/40*100:+.1f} percentage points')
PY
```

```text
Capture: captured 2026-09-22T04:40:19Z by: gh run list --workflow wave-reconcile.yml --limit 40 --json databaseId,conclusion,status,createdAt,event,headSha,displayTitle
Runs: 40
Created-at range (UTC): 2026-09-17T21:45:06Z through 2026-09-22T01:27:14Z
green: 14/40 (35.0%); run ids: 35675811851, 35664881540, 35660654369, 35657379435, 35648397179, 35640574137, 35631562023, 35603022453, 35563474939, 35557918938, 35369188177, 35359578145, 35339851891, 35308543173
failed: 24/40 (60.0%); run ids: 35671086913, 35623940059, 35552996436, 35537102291, 35530081997, 35522250328, 35508325244, 35490654720, 35468625140, 35453406870, 35439479508, 35422170395, 35417583619, 35417045449, 35403385165, 35400339925, 35397041888, 35394524286, 35383956981, 35382467088, 35379772292, 35377282990, 35375197135, 35372725722
cancelled: 2/40 (5.0%); run ids: 35293890339, 35278394550
Consecutive green at head: 1 ids: [35675811851]
Consecutive green schedule/pull_request at head: 1 ids: [35675811851]
Required streak: 10; numerical exit condition met: False
Historical comparisons (reported baselines from phase brief, not recovered historical snapshots):
2026-09-21, #732 v6: 7/40 (17.5%); current difference: +7 green, +17.5 percentage points
2026-09-22, triage: 14/40 (35.0%); current difference: +0 green, +0.0 percentage points
```
