"""Manual controlled entry-point replay; no network/provider or real ledger mutations."""
import argparse, contextlib, hashlib, io, json, pathlib, sqlite3, sys, tempfile
from unittest.mock import patch
sys.path.insert(0, str(pathlib.Path.cwd() / 'utils/py'))
import jog_run as j

def run(root, **kw):
    args = dict(root=str(root), target_root=str(root/'target'), dry_run=True,
                simulate=False, executor='marathon', builder='codex', reviewer=None,
                auto_merge=False, checkpoint_root=None, max_tasks=1)
    args.update(kw)
    out=io.StringIO(); rc=0
    with contextlib.redirect_stdout(out),contextlib.redirect_stderr(out):
        try: j.jog_run_main(argparse.Namespace(**args))
        except SystemExit as e: rc=e.code
    return dict(rc=rc,output=out.getvalue())

with tempfile.TemporaryDirectory(prefix='gh1443-manual-') as t:
    root=pathlib.Path(t); db=root/'releases.db'
    c=sqlite3.connect(db); c.execute('CREATE TABLE jog_queue(gh_number INTEGER, position INTEGER, attempt_count INTEGER, status TEXT)')
    c.execute("INSERT INTO jog_queue VALUES(1443,1,0,'pending')"); c.commit(); c.close()
    before=hashlib.sha256(db.read_bytes()).hexdigest()
    results={}
    with patch.object(j,'_validate_execution_target',return_value=str(root/'target')), patch.object(j,'_dry_run_preflight',return_value='exit 3 — not ready'):
        results['missing_reviewer']=run(root)
        results['same_reviewer']=run(root,reviewer='codex')
        results['bad_checkpoint_options']=run(root,reviewer='agy',checkpoint_root=str(root/'target'),max_tasks=None)
        # Controlled helper output preserves current public result shape for baseline replay.
        results['failed_preflight']=run(root,reviewer='agy')
        results['bare_preview']=run(root,target_root=None)
    results['promotion_lint']=j.lint_probe(str(root), 'python3 -c "assert False"')
    results['db_unchanged']=before==hashlib.sha256(db.read_bytes()).hexdigest()
    results['no_jog_state']=not (root/'.tick').exists()
    print(json.dumps(results,indent=2))
