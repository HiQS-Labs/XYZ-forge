"""GH-1399 manual exercise: the reviewer-only (--review-once) approval path in relay_drive.py.

Usage: python3 review-once-manual.py <harness-checkout> <label>

Drives the REAL <harness>/utils/py/relay_drive.py through the REAL codex-turn.sh shim (worktree
isolation on) with a stub `codex` that plays the reviewer and approves. Every scenario builds a
fresh fixture (bare remote + target clone + tick log + relay file). The parent process below plays
marathon-drive's part of recover_already_satisfied_lane: reserve the lane (which exports
XYZ_ATTEMPT_CONTEXT), spawn relay-drive --review-once with that inherited environment and
LANE_ATTEMPT_COUNTED=1, then lane_attempt_reset (rtl.archive_lane_attempts) and finally ask
gate_receipt.attempt_admission about the final candidate.

Not a suite: nothing here is wired into validate.sh; output is captured by hand.
"""
import json, os, shutil, subprocess, sys, tempfile

HARNESS, LABEL = os.path.abspath(sys.argv[1]), sys.argv[2]
sys.path.insert(0, HARNESS + "/utils/py")
import rtl, gate_receipt  # noqa: E402  (the harness under test, not the clone this file lives in)

for k in list(os.environ):
    if k.startswith(("RELAY_", "XYZ_ATTEMPT", "LANE_ATTEMPT", "TICK_", "MARATHON_")) or k in ("ALLOW_PATHS", "RTL_ARTIFACT"):
        del os.environ[k]
os.environ.update(XYZ_HARNESS_LOGGING="0", XYZ_DEVICE_CONFIG_PATH="/dev/null", MARATHON_ALLOW_TRUNK_COMMIT="1")


def sh(*a, cwd=None, env=None, check=True):
    p = subprocess.run(a, cwd=cwd, env=env, text=True, capture_output=True)
    if check and p.returncode:
        raise RuntimeError(f"{a}: {p.stderr}")
    return p.stdout.strip()


STUB = """#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="@A@"
f="$PWD/relay.md"
"@TICK@" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths relay.md >/dev/null 2>&1
printf '\\n### Round 1 \\xc2\\xb7 Reviewer \\xc2\\xb7 %s\\n**Verdict:** Approved\\n' "$RELAY_AGENT" >>"$f"
perl -pi -e 's/^STATUS:.*/STATUS: Approved/; s/^NEXT:.*/NEXT: done/' "$f"
"@TICK@" done "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
exit 0
"""
DISPATCH = """#!/usr/bin/env bash
export CODEX_AGENT="$RELAY_AGENT" CODEX_BIN="@STUB@" CODEX_TURN_ROOT="@A@" CODEX_LOG="@WORK@/codex-$RELAY_TASK.log"
exec bash "@MAIN@/relay-automation/codex-turn.sh"
"""


def fixture():
    work = tempfile.mkdtemp(prefix="ro.")
    main = work + "/harness"
    os.makedirs(main)
    for d in ("relay-automation", "utils", "bin", "src"):
        shutil.copytree(f"{HARNESS}/{d}", f"{main}/{d}", symlinks=True)
    sh("git", "init", "-q", main); sh("git", "-C", main, "add", "-A")
    sh("git", "-C", main, "-c", "user.email=h@t", "-c", "user.name=h", "commit", "-qm", "seed")
    remote, a = work + "/remote.git", work + "/agent-a"
    sh("git", "init", "-q", "--bare", "-b", "main", remote)
    seed = work + "/.seed"
    sh("git", "init", "-q", "-b", "main", seed)
    sh("git", "-C", seed, "-c", "user.email=s@t", "-c", "user.name=s", "commit", "-q", "--allow-empty", "-m", "init")
    sh("git", "-C", seed, "remote", "add", "origin", remote); sh("git", "-C", seed, "push", "-q", "origin", "main")
    sh("git", "clone", "-q", remote, a)
    sh("git", "-C", a, "config", "user.email", "a@t"); sh("git", "-C", a, "config", "user.name", "a")
    tick = main + "/bin/tick"
    sh(tick, "init", env=dict(os.environ, TICK_REPO_ROOT=a))
    os.makedirs(a + "/bin"); os.symlink(tick, a + "/bin/tick")
    open(a + "/.gitignore", "w").write(".tick/\nbin/\n")
    open(a + "/relay.md", "w").write("# RELAY fixture\n\nNEXT: bld\nSTATUS: Open\nROUND: 1 / 2\n\n## Body\n\nseeded body line one\n")
    open(a + "/src.txt", "w").write("v1\n")
    sh("git", "-C", a, "add", ".gitignore", "relay.md", "src.txt"); sh("git", "-C", a, "commit", "-qm", "seed relay")
    stub, dispatch = work + "/codex", work + "/dispatch.sh"
    for path_, body in ((stub, STUB), (dispatch, DISPATCH)):
        open(path_, "w").write(body.replace("@A@", a).replace("@TICK@", tick).replace("@STUB@", stub)
                               .replace("@WORK@", work).replace("@MAIN@", main))
        os.chmod(path_, 0o755)
    return dict(work=work, main=main, a=a, tick=tick, dispatch=dispatch)


def seed_token(fx, task):
    e = dict(os.environ, TICK_REPO_ROOT=fx["a"])
    sh(fx["tick"], "log", "task.created", task, "--agent", "bld", env=e)
    sh(fx["tick"], "claim", task, "--agent", "bld", "--paths", "relay.md", env=e)
    sh(fx["tick"], "release", task, "--agent", "bld", "--to", "rev", env=e)


def run_review_once(fx, task, env_extra):
    env = dict(os.environ, RELAY_TARGET_ROOT=fx["a"], TICK_REPO_ROOT=fx["a"], TICK_BIN=fx["tick"],
               XYZ_ROOT=fx["main"], RELAY_WORKTREE_ISOLATION="1", **env_extra)
    env.pop("RELAY_DRIVER_LOCKED", None)
    p = subprocess.run(["python3", fx["main"] + "/utils/py/relay_drive.py", "--relay-file", fx["a"] + "/relay.md",
                        "--relay-task", task, "--agent-cmd", fx["dispatch"], "--review-once",
                        "--reviewer", "rev", "--builder", "bld"], env=env, text=True, capture_output=True, cwd=fx["main"])
    return p.returncode, (p.stdout + p.stderr)


def key_lines(out):
    keep = ("attest", "review-once", "REFUSED", "refused", "FAILED", "escalat", "forged")
    return [l.strip() for l in out.splitlines() if any(k in l for k in keep)][:6]


def approval_path(fx, task):
    return sh("git", "-C", fx["a"], "rev-parse", "--absolute-git-dir") + f"/relay-attest/{task}.json"


def describe_attempt(fx, live):
    if os.path.exists(live):
        row = json.loads(open(live).read().splitlines()[-1])
        return f"state={row['state']} attestation={'set' if row.get('attestation') else 'ABSENT'} candidate={'set' if row.get('candidate') else 'ABSENT'}"
    return "live attempts file gone"


def scenario(name, lane, make_context):
    fx = fixture()
    task = "T-" + name
    seed_token(fx, task)
    os.environ.pop(rtl.ATTEMPT_CONTEXT_ENV, None)
    live = None
    if lane is not None:
        n, ctx = rtl.lane_attempt_reserve(fx["a"], lane, fx["a"], cap=5, kind="lane")
        live = ctx["record"]
        make_context(fx, ctx, live)          # may mutate the parent's inherited env to model staleness
    head_before = sh("git", "-C", fx["a"], "rev-parse", "HEAD")
    child_env = {"LANE_ATTEMPT_COUNTED": "1", "XYZ_HARNESS_CONTEXT": "marathon-phase"} if lane else {}
    rc, out = run_review_once(fx, task, child_env)
    print(f"[{LABEL}] {name}: relay-drive --review-once rc={rc}")
    for l in key_lines(out):
        print(f"[{LABEL}] {name}:   | {l}")
    ap = approval_path(fx, task)
    rec = json.load(open(ap)) if os.path.exists(ap) else None
    print(f"[{LABEL}] {name}: approval record written={rec is not None}"
          + (f" linked_attempt_context={'attempt_context' in rec}" if rec else ""))
    text = open(fx["a"] + "/relay.md").read()
    print(f"[{LABEL}] {name}: relay.md STATUS={[l for l in text.splitlines() if l.startswith('STATUS:')]} "
          f"attestation trailer committed={'Attestation \u00b7 relay-drive' in sh('git', '-C', fx['a'], 'show', 'HEAD:relay.md')}")
    return fx, task, live, rc, rec, head_before


def noop(fx, ctx, live):
    pass


def stale_missing(fx, ctx, live):
    # the context names a reservation file that does not exist anywhere
    bogus = dict(ctx, record=fx["a"] + "/.tick/attempts/never-existed", id="1" * 32)
    os.environ[rtl.ATTEMPT_CONTEXT_ENV] = json.dumps(bogus)


def stale_superseded(fx, ctx, live):
    # the reservation was finished and a later attempt consumed the budget after it
    rtl.lane_attempt_finish(ctx, "failed", sh("git", "-C", fx["a"], "rev-parse", "HEAD"))
    rtl.lane_attempt_reserve(fx["a"], os.path.basename(live), fx["a"], cap=5, kind="lane", force=True)
    os.environ[rtl.ATTEMPT_CONTEXT_ENV] = json.dumps(ctx)    # env still names the first (superseded) row


def stale_archived(fx, ctx, live):
    # the reservation was already archived by an earlier completion; env still names the live path
    rtl.archive_lane_attempts(live)
    os.environ[rtl.ATTEMPT_CONTEXT_ENV] = json.dumps(ctx)


def manual_kind(fx, ctx, live):
    os.environ[rtl.ATTEMPT_CONTEXT_ENV] = json.dumps(dict(ctx, kind="manual"))


print(f"=== harness {LABEL}: {sh('git', '-C', HARNESS, 'rev-parse', 'HEAD')}")

# (a) reviewer-only recovery approval -> archive -> final candidate admission
fx, task, live, rc, rec, hb = scenario("a-lane-approval", "lane-a", noop)
print(f"[{LABEL}] a: reservation row after approval: {describe_attempt(fx, live)}")
env_parent = os.environ.get(rtl.ATTEMPT_CONTEXT_ENV)
try:
    archive = rtl.archive_lane_attempts(live)                       # marathon lane_attempt_reset
    print(f"[{LABEL}] a: archive_lane_attempts -> {'archived' if archive else archive}")
except Exception as e:
    print(f"[{LABEL}] a: archive_lane_attempts -> {type(e).__name__}: {e}")
final = sh("git", "-C", fx["a"], "rev-parse", "HEAD")
print(f"[{LABEL}] a: final candidate moved past the pre-review head (reviewer turn + attest commit): {final != hb}")
try:
    print(f"[{LABEL}] a: attempt_admission(final candidate) -> ADMITTED {json.dumps({k: v for k, v in gate_receipt.attempt_admission(fx['a'], sha=final).items() if k in ('kind', 'state', 'archived')})}")
except Exception as e:
    print(f"[{LABEL}] a: attempt_admission(final candidate) -> REFUSED {type(e).__name__}: {e}")

# (b) control: no lane context in the environment
scenario("b-no-context", None, noop)

# (c) controls: stale / missing / superseded / archived / non-lane context
for nm, fn in (("c1-missing", stale_missing), ("c2-superseded", stale_superseded),
               ("c3-archived", stale_archived), ("c4-manual-kind", manual_kind)):
    scenario(nm, "lane-" + nm, fn)

# (c5) what a refused standalone invocation leaves behind: unset the stale context and re-run
fx, task, live, rc, rec, hb = scenario("c5-rerun", "lane-c5", stale_missing)
os.environ.pop(rtl.ATTEMPT_CONTEXT_ENV, None)
rc2, out2 = run_review_once(fx, task, {})
print(f"[{LABEL}] c5: re-run of the same relay without the stale context -> rc={rc2}")
for l in key_lines(out2):
    print(f"[{LABEL}] c5:   | {l[:200]}")
