# Relay: GH-1543 (KS-15) Final QA Delta — CodeRabbit Major Fixes

NEXT: Producer
ROUND: 1 / 3
STATUS: Approved
PRODUCER: antigravity
REVIEWER: codex
ARTIFACT: skills/1-hourly/kickstart/scripts/run_record.py

## Context
The prior head `f947c09dded95e315e2240fed3ca0f836360c8d4` was Approved and attested by Codex in `relay-system/2026-11-20/gh1543-final-qa.md`.
CodeRabbit posted 5 Major findings on PR #1544. This delta (`f947c09dd..c6d506058`) addresses all 5 surgically:
1. Quoted JSON `"Authorization": "Basic ..."` redaction in `SECRET_PATTERNS`.
2. Canonical `record_path.resolve()` + existence check before lock creation in `atomic_append`.
3. Reject malformed/duplicate `LANDING_CLONE` headers in `checkpoint_record` before any checkout/commit.
4. Pass `--untracked-files=all` to `git status --porcelain` in `checkpoint_record` so `status.showUntrackedFiles=no` cannot mask untracked files.
5. Refuse gitignored untracked `--dest` before `_atomic_write_text` (while allowing tracked files matching ignore rules) and restore starting branch on refusal.

All 5 controls were added to Section 6 of `TESTS-RESULTS/2026-11-20+GH-1543/manual-check.md`, executed verbatim into `outputs/check-transcript.log`, verified with `mypy --strict` (0 issues) and `utils/pdda/pdda.sh run` (rc=0, 0 errors), and hashed in `provenance.jsonl` for `candidate_sha=c6d5060587bcd10c1bb2d7f04d2cae0c253a042d`.

```diff
diff --git a/skills/1-hourly/kickstart/scripts/run_record.py b/skills/1-hourly/kickstart/scripts/run_record.py
index 26a14035c..83ad7d7e8 100755
--- a/skills/1-hourly/kickstart/scripts/run_record.py
+++ b/skills/1-hourly/kickstart/scripts/run_record.py
@@ -80,6 +80,7 @@ SECRET_PATTERNS: list[tuple[re.Pattern[str], str]] = [
     (re.compile(r"\bsk-[A-Za-z0-9_-]{16,}\b"), "[REDACTED]"),
     (re.compile(r"(\bAuthorization:\s*Bearer\s+)[^\r\n]+", re.I), r"\1[REDACTED]"),
     (re.compile(r"(\bAuthorization:[ \t]*)(?![ \t]*Bearer[ \t]+\[REDACTED\])[^\r\n]+", re.I), r"\1[REDACTED]"),
+    (re.compile(r"([\"\']Authorization[\"\']\s*:\s*[\"\'])[^\"\'\r\n]+([\"\'])", re.I), r"\1[REDACTED]\2"),
     (re.compile(r"(\bBearer\s+)[A-Za-z0-9._~+/=-]{8,}", re.I), r"\1[REDACTED]"),
 ]
 STRAY_TAG_RE = re.compile(r"</?(?:content|invoke(?:\s+[^>]*)?|parameter(?:\s+[^>]*)?)>", re.I)
@@ -367,6 +368,9 @@ def atomic_append(record_path: Path, line: str, *, require_landing_clone: bool =
     if not EVENT_PREFIX_RE.match(line_stripped):
         raise ValueError(f"line does not match a v1 event prefix: {line_stripped!r}")
 
+    record_path = record_path.resolve()
+    if not record_path.is_file():
+        raise FileNotFoundError(f"run record does not exist: {record_path}")
     lock_path = Path(f"{record_path}.lock")
     lock_fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR, 0o600)
     try:
@@ -527,6 +531,9 @@ def checkpoint_record(
 
     raw_record = record_path.read_text(encoding="utf-8")
     parsed = parse_record(raw_record)
+    lc_errors = [err for err in parsed["errors"] if "LANDING_CLONE" in err]
+    if lc_errors:
+        raise ValueError(f"refusing checkpoint: invalid LANDING_CLONE header: {'; '.join(lc_errors)}")
     if parsed["landing_clone"]:
         lc_resolved = Path(os.path.expanduser(parsed["landing_clone"])).resolve()
         if clone_root == lc_resolved:
@@ -534,7 +541,7 @@ def checkpoint_record(
 
     redacted = redact_text(raw_record)
 
-    status = _git(clone_root, "status", "--porcelain")
+    status = _git(clone_root, "status", "--porcelain", "--untracked-files=all")
     if status.stdout.strip():
         raise ValueError("refusing checkpoint: --clone has staged, unstaged, or untracked changes")
 
@@ -556,6 +563,11 @@ def checkpoint_record(
 
     try:
         dest_abs = _check_fs_confinement(clone_root, dest)
+        tracked = _git(clone_root, "ls-files", "--error-unmatch", "--", dest.as_posix(), check=False).returncode == 0
+        if not tracked:
+            ignored = _git(clone_root, "check-ignore", "-q", "--", dest.as_posix(), check=False).returncode == 0
+            if ignored:
+                raise ValueError(f"refusing checkpoint: destination is gitignored and untracked: {dest.as_posix()}")
     except Exception:
         if orig_ref != branch:
             _git(clone_root, "checkout", orig_ref, check=False)
```

## Review prompt
Verify the 5-fix delta in `skills/1-hourly/kickstart/scripts/run_record.py` and the updated section-6 evidence/provenance in `TESTS-RESULTS/2026-11-20+GH-1543/`. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, set `STATUS: Approved` only on PASS, and flip `NEXT: Producer`.

## Log

## Codex reviewer — round 1

Ship. No blocking finding in the five-fix delta.

Basis: swept the complete seeded `.relay-artifacts/run_record.py` and compared it byte-for-byte with the named source (identical). The quoted Authorization rule removes the Basic value; canonical resolution precedes sibling-lock construction and missing-file refusal precedes lock creation; LANDING_CLONE parser errors stop checkpoint before checkout; status explicitly requests all untracked files; the ignored/untracked destination check precedes the write, permits tracked destinations, and restores the starting ref on refusal. These extend existing mechanisms without a parallel writer.

Read section 6 and its retained transcript: JSON redaction and symlink-target update succeed; duplicate LANDING_CLONE and hidden untracked-file controls refuse; ignored destination refuses with original content and development branch preserved. Recomputed all eight provenance entries: every artifact is nonempty and its size and SHA-256 match; all entries name candidate c6d5060587bcd10c1bb2d7f04d2cae0c253a042d.

Independent read-only probe (exit 0; environment `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`):

```python
import hashlib, json, runpy
from pathlib import Path
m = runpy.run_path('.relay-artifacts/run_record.py')
print('seed_equals_source=', Path('.relay-artifacts/run_record.py').read_bytes() ==
      Path('skills/1-hourly/kickstart/scripts/run_record.py').read_bytes())
for line in Path('TESTS-RESULTS/2026-11-20+GH-1543/provenance.jsonl').read_text().splitlines():
    r = json.loads(line)
    b = Path(r['artifact']).read_bytes()
    print(r['artifact'], 'nonempty=', bool(b),
          'hash_ok=', hashlib.sha256(b).hexdigest() == r['sha256'],
          'size_ok=', len(b) == r['size_bytes'])
for s in ['{"Authorization": "Basic dXNlcjpwYXNz"}',
          "{'Authorization': 'Basic dXNlcjpwYXNz'}"]:
    print('redact=', m['redact_text'](s).strip())
for s in ['RUN-RECORD-VERSION: 1\nLANDING_CLONE:\n',
          'RUN-RECORD-VERSION: 1\nLANDING_CLONE: /a\nLANDING_CLONE: /b\n']:
    print('lc_errors=', m['parse_record'](s)['errors'])
```

Command: `python3 - <<'PY'` with the above body and closing `PY`. Decisive output: `seed_equals_source= True`; eight rows each `nonempty= True hash_ok= True size_ok= True`; both quoted Authorization forms contain only `[REDACTED]`; errors are `line 2: LANDING_CLONE header is empty` and `duplicate LANDING_CLONE headers at lines [2, 3]`.

Limitations: Git/checkpoint/concurrency scenarios were assessed from source and the retained, hash-verified producer evidence, not rerun here. No Git command, fixture, suite, or gate was executed in this reviewer turn, and no future gate is assumed. Graph generation 2026-11-18T19:39:07Z belongs to the main checkout and reports both evidence paths missing; direct full-source review supplies the evidence instead. This PASS is the requested delta review, not promotion qualification.

swept file: yes
VERDICT: PASS

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
