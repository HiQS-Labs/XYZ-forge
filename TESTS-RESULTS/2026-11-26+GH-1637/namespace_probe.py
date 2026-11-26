# GH-1637 retained manual probe (not a suite; GH-831): two concurrent consult invocations sharing one archive
# root and the same relay basename must get distinct prompt files and output namespaces. Evaluates the path-writing
# block of the current relay_drive.consult_adjudicate in two forked processes. Run from a disposable full clone:
#   python3 TESTS-RESULTS/2026-11-26+GH-1637/namespace_probe.py
import ast, multiprocessing as mp, os, secrets, tempfile, time
from pathlib import Path
from types import SimpleNamespace

path = Path("utils/py/relay_drive.py")
fn = next(n for n in ast.walk(ast.parse(path.read_text()))
          if isinstance(n, ast.FunctionDef) and n.name == "consult_adjudicate")


def assignment(name):
    return next(i for i, n in enumerate(fn.body) if isinstance(n, ast.Assign)
                and any(isinstance(t, ast.Name) and t.id == name for t in n.targets))


block = compile(ast.Module(fn.body[assignment("out_base"):assignment("env")], []), str(path), "exec")
ctx = mp.get_context("fork")
barrier, results = ctx.Barrier(2, timeout=10), ctx.Queue()


def run(task, archive):
    env = dict(os=os, time=time, tempfile=tempfile, secrets=secrets,
               get_env=lambda key, default=None: archive if key == "XYZ_ARCHIVE_ROOT" else default,
               root_dir=archive, relay_file=f"{task}/RELAY.md", question=task, cand=task,
               args=SimpleNamespace(relay_task=task))
    exec(block, env)
    barrier.wait()
    results.put((task, Path(env["prompt_file"]).read_text(), env["out_dir"], env["label"]))


with tempfile.TemporaryDirectory(prefix="cap-consult-probe-", dir=Path.cwd()) as archive:
    children = [ctx.Process(target=run, args=(task, archive)) for task in ("candidate-A", "candidate-B")]
    for child in children:
        child.start()
    for child in children:
        child.join(15)
        if child.is_alive():
            child.terminate()
            child.join()
            raise SystemExit("probe timed out")
        if child.exitcode != 0:
            raise SystemExit(f"probe child failed: {child.exitcode}")
    rows = [results.get(timeout=2), results.get(timeout=2)]
    for task, question, out_dir, label in sorted(rows):
        print(f"{task} read {question}; output namespace {Path(out_dir).name}/{label}")
        assert question == task, "a candidate read another candidate's question"
    distinct = len({(row[2], row[3]) for row in rows}) == 2
    print("distinct output namespaces:", distinct)
    assert distinct
