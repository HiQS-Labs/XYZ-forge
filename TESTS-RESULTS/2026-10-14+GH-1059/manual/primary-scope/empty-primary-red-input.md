Observed at8eb6f70c before the input correction; a sentinel stopped the call before any retirement.

```python
import sys
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path.cwd()/'skills/2-daily/merge-cleanup/scripts'))
import merge_cleanup as m
with patch.object(sys,'argv',['merge_cleanup.py','--primary','','--retire-published-pr','1059','--checkout',str(Path.cwd().parent/'candidate')]),patch.object(m,'retire_published_checkouts',side_effect=RuntimeError('RED: empty primary inferred from CWD')):
 try:m.main()
 except RuntimeError as e:
  assert str(e)=='RED: empty primary inferred from CWD';print(e)
 else:raise AssertionError('expected empty-primary witness')
```
