# Manual policy check

Run from a disposable full clone. This is a retained one-off check, not a registered suite.

```python
import contextlib, io, json, subprocess, sys, tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
sys.path.insert(0, str(Path.cwd() / 'skills/2-daily/merge-cleanup/scripts'))
import merge_cleanup as m
with tempfile.TemporaryDirectory(prefix='gh1010-policy-') as directory:
    root = Path(directory)
    cfg = root / '.merge-cleanup.json'
    for value in (None, {}, {'preserve_commit_history':False}, {'preserve_commit_history':True}):
        if value is not None: cfg.write_text(json.dumps(value))
        enabled = bool(value and value.get('preserve_commit_history'))
        for strategy in (None, 'merge', 'squash', 'rebase'):
            try: result = m.resolve_merge_policy(root, strategy)
            except ValueError:
                assert enabled and strategy in ('squash','rebase')
            else:
                assert not (enabled and strategy in ('squash','rebase'))
                assert result['strategy'] == (strategy or ('merge' if enabled else 'squash'))
        print('PASS policy matrix', value)
    for text in ('{', '[]', 'null', '{"preserve_commit_history":"true"}', '{"preserve_commit_history":1}', '{"preserve_commit_histroy":true}'):
        cfg.write_text(text)
        try: m.resolve_merge_policy(root)
        except ValueError: pass
        else: raise AssertionError(text)
    cfg.unlink();cfg.mkdir()
    try: m.resolve_merge_policy(root)
    except ValueError: pass
    else: raise AssertionError('unreadable policy silently defaulted')
    cfg.rmdir();cfg.symlink_to(root/'missing')
    try: m.resolve_merge_policy(root)
    except ValueError: pass
    else: raise AssertionError('dangling policy silently defaulted')
    cfg.unlink()
    print('PASS invalid/unreadable policy refuses')
    cfg.write_text('{"preserve_commit_history":true}')
    with patch.object(m, '_gh') as gh:
        assert not m.execute_pr_merge(7,root,'squash',False)
        assert not m.execute_pr_merge(7,root,'rebase',False)
        gh.assert_not_called()
    print('PASS direct merge writer refuses forbidden methods before GitHub')
    for rc,output in ((0,'{"mergeCommitAllowed":false}'),(1,''),(0,'{}'),(0,'bad'),(0,'[]')):
        with patch.object(m,'_gh',return_value=subprocess.CompletedProcess([],rc,output,'')) as gh:
            assert not m.execute_pr_merge(7,root,dry_run=False)
            assert all(c.args[0][:2] == ['repo','view'] for c in gh.call_args_list)
    print('PASS unavailable/unknown hosting capability makes no merge call')
    def github(args,*a,**kw):
        if args[:2] == ['repo','view']: return subprocess.CompletedProcess(args,0,'{"mergeCommitAllowed":true}','')
        assert args[:4] == ['pr','merge','7','--merge'], args
        return subprocess.CompletedProcess(args,0,'','')
    with patch.object(m,'_gh',side_effect=github) as gh, patch.object(m,'refresh_pr',return_value={'state':'MERGED','mergeCommit':{'oid':'a'*40}}):
        assert m.execute_pr_merge(7,root,dry_run=False)
        assert sum(c.args[0][:2]==['pr','merge'] for c in gh.call_args_list)==1
    print('PASS opted-in writer emits --merge, verified MERGED')
    def refused(args,*a,**kw):
        return subprocess.CompletedProcess(args,0,'{"mergeCommitAllowed":true}','') if args[:2]==['repo','view'] else subprocess.CompletedProcess(args,1,'','ruleset refused')
    with patch.object(m,'_gh',side_effect=refused) as gh, patch.object(m,'refresh_pr',return_value={'state':'OPEN'}):
        assert not m.execute_pr_merge(7,root,dry_run=False)
        assert sum(c.args[0][:2]==['pr','merge'] for c in gh.call_args_list)==1
        assert not any('--squash' in c.args[0] or '--rebase' in c.args[0] for c in gh.call_args_list)
    print('PASS GitHub refusal has no fallback')
    args=SimpleNamespace(integration_branch='development',strategy='squash')
    with patch.object(m,'prepare_landing_clone') as prep, patch.object(m,'execute_pr_merge') as merge:
        assert m.land_prs([{'number':7}],root,args,False)==2
        prep.assert_not_called(); merge.assert_not_called()
    print('PASS landing refuses before repair/merge')
    with patch.object(sys,'argv',['merge_cleanup.py','--primary',str(root),'--show-merge-policy']), patch.object(m,'_gh') as gh, patch.object(m,'prepare_primary_landing') as prep, contextlib.redirect_stdout(io.StringIO()) as output:
        assert m.main()==0
        result=json.loads(output.getvalue()); assert result['strategy']=='merge'
        gh.assert_not_called();prep.assert_not_called()
    print('PASS shared JSON reporter has no scan/network/mutation')
    cfg.write_text('{"preserve_commit_history":"false"}')
    with patch.object(sys,'argv',['merge_cleanup.py','--primary',str(root),'--execute']), patch.object(m,'prepare_primary_landing') as prep, patch.object(m,'teardown_checkout') as teardown:
        assert m.main()==2
        prep.assert_not_called();teardown.assert_not_called()
    print('PASS malformed policy refuses before Phase 0 and teardown')
print('ALL POLICY PROBES PASSED')
```
