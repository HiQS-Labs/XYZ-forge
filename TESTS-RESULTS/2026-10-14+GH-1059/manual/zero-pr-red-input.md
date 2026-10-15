Observed at c391afec before60c1ad18 fixed the parser default. Broad-workflow entry was stopped by the probe before mutation; the new39-case probe confirms zero/negative/missing scope now exits2.

```python
import sys
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path.cwd()/'skills/2-daily/merge-cleanup/scripts'))
import merge_cleanup as m
with patch.object(sys,'argv',['merge_cleanup.py','--primary',str(Path.cwd()),'--retire-published-pr','0','--execute']),patch.object(m,'prepare_primary_landing',side_effect=RuntimeError('RED: invalid zero PR reached broad workflow')):
 try:m.main()
 except RuntimeError as e:
  assert str(e)=='RED: invalid zero PR reached broad workflow';print(e)
 else:raise AssertionError('expected broad-workflow witness')
```
