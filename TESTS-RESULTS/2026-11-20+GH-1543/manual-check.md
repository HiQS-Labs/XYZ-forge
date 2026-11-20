# GH-1543 (KS-15) manual check — `run_record.py` v1 contract

Manual check, not a test suite (`AGENTS.md` *No new tests*, GH-831). Every claim below is backed by
the literal runnable procedure in **Reproducible manual procedure** and its verbatim output captured
in `outputs/check-transcript.log`, plus the retained fixture outputs and `pdda-run.log`. Candidate
commit and file hashes are recorded in `provenance.jsonl`.

## Static & classified gate summary

- `mypy --strict skills/1-hourly/kickstart/scripts/run_record.py` → `rc=0` (`Success: no issues found in 1 source file`).
- `utils/ci-route.sh pull_request` → `route=docs`, `tier=1`.
- `utils/pdda/pdda.sh run` → `rc=0`, `0 errors` (`pdda-run.log`).

## Key verified outcomes (verbatim decisive lines in `outputs/check-transcript.log`)

- **Baseline absence (`6270a2b5d`):** `git cat-file -e` returned `rc=128` (`run_record.py` absent on `origin/development` before GH-1543).
- **Retained fixtures (`run1-baseline-shape.md`, `run2-active-shape.md`):** fresh `validate --json` matches `outputs/run1-validate.json` and `outputs/run2-validate.json` byte-for-byte (`rc=0`).
- **Bad-input validation & atomic append (10 validate cases + 5 append cases + empty snapshot):** every malformed record/append exited `rc=1` with exact error diagnostics and unchanged target SHA-256, including `superseded` referencing an older or self amendment (F3).
- **Redaction sentinel (F1):** synthetic `ghp_`, `github_pat_`, `sk-`, `Authorization: Bearer ...`, `Authorization: Basic ...`, `Authorization: Token ...`, home-directory path, and stray XML tags produced `leak_indices=[]`, preserved `Authorization: Bearer [REDACTED]` and `Authorization: [REDACTED]`, normalized home paths to `~`, and passed `validate` (`rc=0`; retained in `outputs/redacted-snapshot.md`).
- **Concurrency:** 8-worker barrier-synchronized distinct appends all exited `rc=0` with 8/8 amendments valid; 4-worker barrier-synchronized same-ID race returned sorted exit codes `[0, 1, 1, 1]` with 1 valid `PN-RACE` amendment.
- **Disposable-clone checkpoint refusals & state invariance (F2 + confinement):** 10 refusal cases (omitted `--primary`, `--clone == --primary`, `--clone == LANDING_CLONE`, protected branches `development`/`main`, `../outside.md`, `.git`, `.git/config`, `docs/.git/hooks/pre-commit`, and target-branch escaping symlink `docs/sym-escape`) all failed with expected exit codes and `refusals_state_identical=True` (identical pre/post `HEAD`, branch, `status --porcelain`, `for-each-ref` SHA-256, `.git/config` SHA-256, and `outside_files=0`), plus dirty staged clone refusal (`rc=1`).
- **Failed-push retry, bare-remote blob proof & idempotent rerun:** bare remote held `PRE-PUBLICATION-SENTINEL` before and after failed push (`rc=1`); retry succeeded (`committed=false, pushed=true`); `git -C <bare> show docs/run-rec:docs/run-records/demo.md` matched `run_record.py snapshot` byte-for-byte (`matches_expected_snapshot=True`, exact SHA-256 equality, zero Basic credential leak); immediate rerun returned `committed=false, pushed=false, push_status="up-to-date"`.

## Scope boundary

This check verifies the KS-15 record contract (`run_record.py` v1 grammar, sibling-locked atomic append,
redacted snapshot, and confined branch checkpoint) on saved fixtures and disposable local clones.
Live run-2 checkpoint publication remains uncredited until run 2 (KS-15 acceptance).

## Reproducible manual procedure

Run from repository root:

```bash
set -euo pipefail
RR="skills/1-hourly/kickstart/scripts/run_record.py"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/ks15-manual-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "=== 0. Baseline absence on origin/development (6270a2b5d) ==="
set +e
git cat-file -e "6270a2b5d:$RR" 2>&1
echo "baseline_rc=$?"
set -e

echo "=== 1. Validate retained run-1 and run-2 fixtures ==="
python3 "$RR" validate --json TESTS-RESULTS/2026-11-20+GH-1543/inputs/run1-baseline-shape.md > "$WORK/r1.json"
echo "run1_rc=$? matches_retained=$(cmp -s "$WORK/r1.json" TESTS-RESULTS/2026-11-20+GH-1543/outputs/run1-validate.json && echo true || echo false)"
python3 "$RR" validate --require-landing-clone --json TESTS-RESULTS/2026-11-20+GH-1543/inputs/run2-active-shape.md > "$WORK/r2.json"
echo "run2_rc=$? matches_retained=$(cmp -s "$WORK/r2.json" TESTS-RESULTS/2026-11-20+GH-1543/outputs/run2-validate.json && echo true || echo false)"

echo "=== 2. Bad-input validate & append (including F3 older/self supersession) ==="
python3 - "$RR" "$WORK" <<'PYEOF'
import hashlib, subprocess, sys
from pathlib import Path
rr, work = sys.argv[1], Path(sys.argv[2])

bad_validate = [
    ("missing_version", "LANDING_CLONE: ~/x\n"),
    ("wrong_version", "RUN-RECORD-VERSION: 2\nLANDING_CLONE: ~/x\n"),
    ("dup_landing_clone", "RUN-RECORD-VERSION: 1\nLANDING_CLONE: ~/a\nLANDING_CLONE: ~/b\n"),
    ("oa_no_cite", "RUN-RECORD-VERSION: 1\n- OPERATOR_AMENDMENT: OA-1 2026-11-20T01:00Z missing cite\n"),
    ("dup_id", "RUN-RECORD-VERSION: 1\n- PARENT_NOTE: PN-1 2026-11-20T01:00Z a\n- PARENT_NOTE: PN-1 2026-11-20T01:01Z b\n"),
    ("applied_unknown", "RUN-RECORD-VERSION: 1\n- APPLIED: NOPE -> done\n"),
    ("applied_empty_escalated", "RUN-RECORD-VERSION: 1\n- PARENT_NOTE: PN-1 2026-11-20T01:00Z x\n- APPLIED: PN-1 -> escalated\n"),
    ("applied_dup_terminal", "RUN-RECORD-VERSION: 1\n- PARENT_NOTE: PN-1 2026-11-20T01:00Z x\n- APPLIED: PN-1 -> applied: done\n- APPLIED: PN-1 -> applied: again\n"),
    ("superseded_older_F3", "RUN-RECORD-VERSION: 1\n- OPERATOR_AMENDMENT: OA-1 2026-11-20T01:00Z old (operator turn)\n- OPERATOR_AMENDMENT: OA-2 2026-11-20T01:05Z new (operator turn)\n- APPLIED: OA-2 -> superseded by OA-1\n"),
    ("superseded_self_F3", "RUN-RECORD-VERSION: 1\n- OPERATOR_AMENDMENT: OA-1 2026-11-20T01:00Z old (operator turn)\n- APPLIED: OA-1 -> superseded by OA-1\n"),
]
for name, body in bad_validate:
    fp = work / f"{name}.md"
    fp.write_text(body)
    r = subprocess.run([sys.executable, rr, "validate", str(fp)], text=True, capture_output=True)
    print(f"validate:{name} rc={r.returncode} stderr={r.stderr.strip()}")
    assert r.returncode == 1

app = work / "append-target.md"
app.write_text("RUN-RECORD-VERSION: 1\n- PARENT_NOTE: PN-1 2026-11-20T01:00Z seed\n")
h0 = hashlib.sha256(app.read_bytes()).hexdigest()
print(f"append_pre_sha256={h0}")
bad_appends = [
    ("dup_id", ["append", str(app), "--kind", "parent-note", "--id", "PN-1", "--text", "dup"]),
    ("oa_no_cite", ["append", str(app), "--kind", "operator-amendment", "--id", "OA-1", "--text", "no cite"]),
    ("unknown_id", ["append", str(app), "--kind", "applied", "--id", "NOPE", "--action", "done"]),
    ("reserved_empty", ["append", str(app), "--kind", "applied", "--id", "PN-1", "--disposition", "escalated", "--action", ""]),
    ("superseded_self_F3", ["append", str(app), "--line", "APPLIED: PN-1 -> superseded by PN-1"]),
]
for name, args in bad_appends:
    r = subprocess.run([sys.executable, rr, *args], text=True, capture_output=True)
    h1 = hashlib.sha256(app.read_bytes()).hexdigest()
    print(f"append:{name} rc={r.returncode} sha256_unchanged={h1 == h0} stderr={r.stderr.strip()}")
    assert r.returncode == 1 and h1 == h0

empty_fp = work / "empty.md"
empty_fp.write_text("")
r = subprocess.run([sys.executable, rr, "snapshot", str(empty_fp)], text=True, capture_output=True)
print(f"snapshot:empty rc={r.returncode} stderr={r.stderr.strip()}")
assert r.returncode == 1
PYEOF

echo "=== 3. Redaction sentinel (F1: Bearer + Basic + Token + tokens + /Users + XML tags) ==="
python3 - "$RR" "$WORK" <<'PYEOF'
import subprocess, sys
from pathlib import Path
rr, work = sys.argv[1], Path(sys.argv[2])
# Assemble synthetic tokens dynamically so no raw credential pattern is stored in repo
t_ghp = "ghp_" + "A1b2C3d4E5f6G7h8I9j0K1l2"
t_pat = "github_pat_" + "11ABCDEFG_0123456789abcdef"
t_sk = "sk-" + "live1234567890abcdef1234"
t_basic = "dXNlcjpwYXNzd29yZA=="
t_bearer = "eyJhbGciOiJIUzI1NiJ9.payload.sig12345"
t_tok = "rawtokensecret123"
src = work / "redaction-src.md"
src.write_text(
    "# Kickstart run redaction check\n"
    "RUN-RECORD-VERSION: 1\n"
    "LANDING_CLONE: " + "/Users/" + "alice/kickstart-clones/landing\n\n"
    "## Progress log\n"
    f"- note-ghp: {t_ghp}\n"
    f"- note-pat: {t_pat}\n"
    f"- note-sk: {t_sk}\n"
    f"- note-bearer: Authorization: Bearer {t_bearer}\n"
    f"- note-basic: Authorization: Basic {t_basic}\n"
    f"- note-token: Authorization: Token {t_tok}\n"
    "- note-path: " + "/Users/" + "alice/Documents/GH Repos/XYZ-forge\n"
    "- note-tags: <content>kept</content> <invoke name=\"foo\">bar</invoke>\n"
)
out = Path("TESTS-RESULTS/2026-11-20+GH-1543/outputs/redacted-snapshot.md")
r = subprocess.run([sys.executable, rr, "snapshot", str(src), "--out", str(out)], text=True, capture_output=True)
rv = subprocess.run([sys.executable, rr, "validate", str(out)], text=True, capture_output=True)
txt = out.read_text()
sentinels = [t_ghp, t_pat, t_sk, t_basic, t_bearer, t_tok, "/Users/" + "alice", "<content>", "<invoke"]
leaks = [i for i, s in enumerate(sentinels) if s in txt]
print(f"snapshot_rc={r.returncode} validate_rc={rv.returncode} validate_out={rv.stdout.strip()} leak_indices={leaks}")
print("--- redacted-snapshot.md ---")
print(txt.rstrip())
assert r.returncode == 0 and rv.returncode == 0 and not leaks
assert "Authorization: Bearer [REDACTED]" in txt and "Authorization: [REDACTED]" in txt
PYEOF

echo "=== 4. Concurrency (8 distinct parallel appends + 4-way same-ID race) ==="
python3 - "$RR" "$WORK" <<'PYEOF'
import concurrent.futures, json, subprocess, sys, threading
from pathlib import Path
rr, work = sys.argv[1], Path(sys.argv[2])

c8 = work / "conc8.md"
c8.write_text("RUN-RECORD-VERSION: 1\nLANDING_CLONE: ~/x\n")
b8 = threading.Barrier(8)
def w8(i: int) -> tuple[int, int, str, str]:
    b8.wait()
    r = subprocess.run([sys.executable, rr, "append", str(c8), "--kind", "parent-note", "--id", f"PN-{i}", "--text", f"worker-{i}"], text=True, capture_output=True)
    return i, r.returncode, r.stdout.strip(), r.stderr.strip()
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
    res8 = sorted(ex.map(w8, range(8)))
for i, rc, out, err in res8:
    print(f"conc8 worker={i} rc={rc} stdout={out!r} stderr={err!r}")
rv8 = subprocess.run([sys.executable, rr, "validate", "--json", str(c8)], text=True, capture_output=True)
d8 = json.loads(rv8.stdout)
print(f"conc8 validate_rc={rv8.returncode} valid={d8['valid']} amendments={len(d8['amendments'])} ids={[a['id'] for a in d8['amendments']]}")
assert all(rc == 0 for _, rc, _, _ in res8) and rv8.returncode == 0 and len(d8["amendments"]) == 8

c4 = work / "conc4.md"
c4.write_text("RUN-RECORD-VERSION: 1\nLANDING_CLONE: ~/x\n")
b4 = threading.Barrier(4)
def w4(i: int) -> tuple[int, int, str, str]:
    b4.wait()
    r = subprocess.run([sys.executable, rr, "append", str(c4), "--kind", "parent-note", "--id", "PN-RACE", "--text", f"racer-{i}"], text=True, capture_output=True)
    return i, r.returncode, r.stdout.strip(), r.stderr.strip()
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
    res4 = sorted(ex.map(w4, range(4)))
for i, rc, out, err in res4:
    print(f"conc4 worker={i} rc={rc} stdout={out!r} stderr={err!r}")
rv4 = subprocess.run([sys.executable, rr, "validate", "--json", str(c4)], text=True, capture_output=True)
d4 = json.loads(rv4.stdout)
rcs4 = sorted(rc for _, rc, _, _ in res4)
print(f"conc4 sorted_rcs={rcs4} validate_rc={rv4.returncode} valid={d4['valid']} amendments={len(d4['amendments'])}")
assert rcs4 == [0, 1, 1, 1] and rv4.returncode == 0 and len(d4["amendments"]) == 1
PYEOF

echo "=== 5. Disposable full-clone checkpoint refusals, unchanged-state brackets, failed-push retry, bare-remote blob proof, and idempotent rerun ==="
python3 - "$RR" "$WORK" <<'PYEOF'
import hashlib, json, subprocess, sys
from pathlib import Path
rr, work = sys.argv[1], Path(sys.argv[2])

def git(repo: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()

def bracket(repo: Path, label: str) -> dict[str, str]:
    st = {
        "head": git(repo, "rev-parse", "HEAD"),
        "branch": git(repo, "rev-parse", "--abbrev-ref", "HEAD"),
        "status": git(repo, "status", "--porcelain"),
        "refs_sha": hashlib.sha256(git(repo, "for-each-ref").encode()).hexdigest()[:16],
        "config_sha": hashlib.sha256((repo / ".git/config").read_bytes()).hexdigest()[:16],
    }
    print(f"bracket[{label}]: {json.dumps(st, sort_keys=True)}")
    return st

bare = work / "remote.git"
subprocess.run(["git", "init", "--bare", "-b", "development", str(bare)], check=True, capture_output=True)
seed = work / "seed"
subprocess.run(["git", "clone", str(bare), str(seed)], check=True, capture_output=True)
git(seed, "config", "user.email", "test@example.com")
git(seed, "config", "user.name", "Test")
(seed / "README.md").write_text("seed\n")
git(seed, "add", "README.md")
git(seed, "commit", "-m", "init")
git(seed, "push", "-u", "origin", "development")

git(seed, "checkout", "-b", "docs/run-rec")
(seed / "docs/run-records").mkdir(parents=True)
(seed / "docs/run-records/demo.md").write_text("PRE-PUBLICATION-SENTINEL\n")
git(seed, "add", ".")
git(seed, "commit", "-m", "pre-publication sentinel")
git(seed, "push", "-u", "origin", "docs/run-rec")

outside = work / "outside_dir"
outside.mkdir()
git(seed, "checkout", "-b", "docs/sym-escape", "development")
(seed / "escape_link").symlink_to(outside)
git(seed, "add", "escape_link")
git(seed, "commit", "-m", "escaping symlink fixture")
git(seed, "push", "-u", "origin", "docs/sym-escape")

cp_clone = work / "cp_clone"
primary_fake = work / "primary_fake"
primary_fake.mkdir()
landing_fake = work / "landing_fake"
landing_fake.mkdir()
subprocess.run(["git", "clone", str(bare), str(cp_clone)], check=True, capture_output=True)
git(cp_clone, "config", "user.email", "test@example.com")
git(cp_clone, "config", "user.name", "Test")
git(cp_clone, "fetch", "origin", "docs/sym-escape:refs/heads/docs/sym-escape")

rec_ok = work / "cp_rec.md"
rec_ok.write_text(
    "RUN-RECORD-VERSION: 1\n"
    f"LANDING_CLONE: {landing_fake}\n"
    "- OPERATOR_AMENDMENT: OA-1 2026-11-20T01:00Z proceed (operator turn)\n"
    "- note-auth: Authorization: Basic dXNlcjpwYXNzd29yZA==\n"
)
rec_same_lc = work / "cp_rec_same_lc.md"
rec_same_lc.write_text(
    "RUN-RECORD-VERSION: 1\n"
    f"LANDING_CLONE: {cp_clone}\n"
    "- OPERATOR_AMENDMENT: OA-1 2026-11-20T01:00Z proceed (operator turn)\n"
)

pre = bracket(cp_clone, "pre-refusals")
refusals = [
    ("omitted_primary", 2, ["--record", str(rec_ok), "--clone", str(cp_clone), "--branch", "docs/run-rec", "--dest", "docs/run-records/demo.md"]),
    ("clone_eq_primary", 1, ["--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(cp_clone), "--branch", "docs/run-rec", "--dest", "docs/run-records/demo.md"]),
    ("clone_eq_landing", 1, ["--record", str(rec_same_lc), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/run-rec", "--dest", "docs/run-records/demo.md"]),
    ("protected_development", 1, ["--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "development", "--dest", "docs/run-records/demo.md"]),
    ("protected_main", 1, ["--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "main", "--dest", "docs/run-records/demo.md"]),
    ("traversal_dotdot", 1, ["--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/run-rec", "--dest", "../outside.md"]),
    ("git_dir_F2", 1, ["--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/run-rec", "--dest", ".git"]),
    ("git_config_F2", 1, ["--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/run-rec", "--dest", ".git/config"]),
    ("nested_git_F2", 1, ["--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/run-rec", "--dest", "docs/.git/hooks/pre-commit"]),
    ("target_branch_symlink", 1, ["--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/sym-escape", "--dest", "escape_link/leak.md"]),
]
for name, exp_rc, args in refusals:
    r = subprocess.run([sys.executable, rr, "checkpoint", *args], text=True, capture_output=True)
    print(f"refusal:{name} rc={r.returncode} stderr={r.stderr.strip()}")
    assert r.returncode == exp_rc
post = bracket(cp_clone, "post-refusals")
print(f"refusals_state_identical={pre == post} outside_files={len(list(outside.iterdir()))}")
assert pre == post and len(list(outside.iterdir())) == 0

# Dirty staged refusal
(cp_clone / "dirty.txt").write_text("x\n")
git(cp_clone, "add", "dirty.txt")
r_dirty = subprocess.run([sys.executable, rr, "checkpoint", "--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/run-rec", "--dest", "docs/run-records/demo.md"], text=True, capture_output=True)
print(f"refusal:dirty_staged rc={r_dirty.returncode} stderr={r_dirty.stderr.strip()}")
assert r_dirty.returncode == 1
git(cp_clone, "reset", "--hard", "HEAD")
(cp_clone / "dirty.txt").unlink(missing_ok=True)

# Bare remote blob BEFORE publication
pre_blob = git(bare, "show", "docs/run-rec:docs/run-records/demo.md")
print(f"bare_remote_pre_blob={pre_blob!r}")
assert pre_blob == "PRE-PUBLICATION-SENTINEL"

# Expected redacted snapshot bytes
snap_res = subprocess.run([sys.executable, rr, "snapshot", str(rec_ok)], text=True, capture_output=True, check=True)
expected_bytes = snap_res.stdout.encode("utf-8")
expected_sha = hashlib.sha256(expected_bytes).hexdigest()
print(f"expected_redacted_bytes={len(expected_bytes)} expected_sha256={expected_sha}")

# Failed-push retry
git(cp_clone, "fetch", "origin", "docs/run-rec")
git(cp_clone, "checkout", "-b", "docs/run-rec", "origin/docs/run-rec")
git(cp_clone, "remote", "set-url", "origin", str(work / "nonexistent.git"))
r_fail = subprocess.run([sys.executable, rr, "checkpoint", "--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/run-rec", "--dest", "docs/run-records/demo.md", "--push"], text=True, capture_output=True)
print(f"push_fail rc={r_fail.returncode} stderr={r_fail.stderr.strip()}")
assert r_fail.returncode == 1
assert git(bare, "show", "docs/run-rec:docs/run-records/demo.md") == "PRE-PUBLICATION-SENTINEL"

git(cp_clone, "remote", "set-url", "origin", str(bare))
r_retry = subprocess.run([sys.executable, rr, "checkpoint", "--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/run-rec", "--dest", "docs/run-records/demo.md", "--push"], text=True, capture_output=True)
print(f"push_retry rc={r_retry.returncode} stdout={r_retry.stdout.strip()}")
d_retry = json.loads(r_retry.stdout)
assert r_retry.returncode == 0 and d_retry["committed"] is False and d_retry["pushed"] is True

post_blob_bytes = subprocess.check_output(["git", "-C", str(bare), "show", "docs/run-rec:docs/run-records/demo.md"])
post_sha = hashlib.sha256(post_blob_bytes).hexdigest()
print(f"bare_remote_post_bytes={len(post_blob_bytes)} post_sha256={post_sha} matches_expected_snapshot={post_blob_bytes == expected_bytes}")
print("--- bare remote published blob ---")
print(post_blob_bytes.decode("utf-8").rstrip())
assert post_blob_bytes == expected_bytes and b"dXNlcjpwYXNzd29yZA==" not in post_blob_bytes

r_noop = subprocess.run([sys.executable, rr, "checkpoint", "--record", str(rec_ok), "--clone", str(cp_clone), "--primary", str(primary_fake), "--branch", "docs/run-rec", "--dest", "docs/run-records/demo.md", "--push"], text=True, capture_output=True)
print(f"idempotent_noop rc={r_noop.returncode} stdout={r_noop.stdout.strip()}")
d_noop = json.loads(r_noop.stdout)
assert r_noop.returncode == 0 and d_noop["committed"] is False and d_noop["pushed"] is False and d_noop["push_status"] == "up-to-date"
PYEOF
echo "=== ALL MANUAL CHECKS PASSED ==="
```
