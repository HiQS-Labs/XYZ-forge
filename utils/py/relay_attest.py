"""relay-drive/attest@1 — the one record that says a relay reviewer approved (GH-505 / GH-509).

The driver (relay_drive.py) is the only process in a relay the party under review does not run.
It is the ONLY writer of this record, and it writes it only after watching a reviewer-role turn
append review text to a relay file whose reviewed revision the driver pinned before dispatch.

Everything else — marathon recovery, jog's merge — READS the record, and reads it only against
trusted expectations (task, expected reviewer, relay file, target repo). Existence proves nothing:
`load()` validates the reviewer, the terminal status (record == file == trailer), and the exact
byte range the reviewer added; `candidate_ok()` validates that a merge candidate is the reviewed
revision plus transcript-only commits.

The record lives under <git-common-dir>/relay-attest/. A worktree-isolated Codex turn cannot reach
it and containment never copies back into .git. An unsandboxed same-user host process can write
it — that is the stated non-goal (GH-505 plan); the driver's own exit code never depends on the
record, only on its in-process memory.
"""
import hashlib
import json
import os
import re
import subprocess
import tempfile

SCHEMA = "relay-drive/attest@1"
TRAILER_HEAD = "### Attestation · relay-drive"
TERMINAL = ("Approved", "Closed")
# Paths a commit may touch between the reviewed revision and a merge candidate without
# invalidating the review: the transcript tree, plus the relay file itself when it is tracked
# inside the target repo.
TRANSCRIPT_DIR = "relay-system"

_HEADER_KEYS = (b"STATUS:", b"NEXT:", b"ROUND:")

# The ONE other edit the harness itself makes to pre-existing relay lines: rtl_check_uncited_findings
# (relay-turn-lib.sh, GH-173 B3) downgrades an uncited [Pass]/"verified" claim in place after a
# reviewer turn. It is idempotent, so applying the same transform to BOTH snapshots makes the
# comparison see only what the reviewer added. Kept byte-for-byte in step with the awk: the claim
# words, the citation shapes, the inclusive window, and the two rewrite forms.
_CLAIM_RE = re.compile(rb"(^|[^A-Za-z])([Vv]erified|[Cc]onfirmed|LGTM|[Ll]ooks [Gg]ood|[Cc]hecks [Oo]ut|[Aa]ll [Gg]ood|[Ww]orks [Aa]s [Ee]xpected|[Nn]o issues( found)?)([^A-Za-z]|$)")
_CITE_RE = re.compile(rb'"[^"]+"|`[^`]+`|[A-Za-z0-9_./-]+:[0-9]+')
_UNCITED = "[Unverified — no citation]".encode("utf-8")


def _downgrade_uncited(lines):
    try:
        win = int(os.environ.get("RTL_CITATION_WINDOW", "3"))
    except ValueError:
        win = 3
    bodies = [l.rstrip(b"\r\n") for l in lines]
    out = []
    for i, line in enumerate(lines):
        body = bodies[i]
        nl = line[len(body):]
        if _UNCITED in body:
            out.append(line)
            continue
        if not (b"[Pass]" in body or _CLAIM_RE.search(body)):
            out.append(line)
            continue
        if any(_CITE_RE.search(bodies[j]) for j in range(i, min(len(lines), i + win + 1))):
            out.append(line)
            continue
        body = body.replace(b"[Pass]", _UNCITED) if b"[Pass]" in body else body + b"  " + _UNCITED
        out.append(body + nl)
    return out


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def canonical(path):
    """The relay file's bytes with (a) its FIRST STATUS:/NEXT:/ROUND: lines reduced to bare keys and
    (b) the harness's own uncited-claim downgrade applied.

    Those header lines are the only edits a turn is permitted to make above its own appended block,
    and the downgrade is the only edit the harness makes there — so normalising both makes
    "append-only" checkable whatever the file's leading format (marathon's and jog's title-first
    renders, frontmatter threads, bare KEY: lines) and whatever the harness stamped after the turn.
    """
    with open(path, "rb") as f:
        raw = f.read()
    seen = set()
    out = []
    for line in raw.splitlines(keepends=True):
        for key in _HEADER_KEYS:
            if key not in seen and line.startswith(key):
                seen.add(key)
                line = key + b"\n"
                break
        out.append(line)
    return b"".join(_downgrade_uncited(out))


def file_status(path):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("STATUS:"):
                    return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return ""


def git_common_dir(repo):
    out = subprocess.run(["git", "-C", repo, "rev-parse", "--git-common-dir"],
                         capture_output=True, text=True)
    if out.returncode != 0:
        raise RuntimeError(f"not a git repo: {repo}")
    gcd = out.stdout.strip()
    return gcd if os.path.isabs(gcd) else os.path.join(repo, gcd)


def path_for(task, target_repo):
    safe = re.sub(r"[^A-Za-z0-9._-]", "_", task)
    return os.path.join(git_common_dir(target_repo), "relay-attest", safe + ".json")


def trailer_text(record):
    return (f"\n{TRAILER_HEAD} — {record['attested_at']}\n"
            f"task: {record['task']}\n"
            f"reviewer: {record['reviewer']}\n"
            f"status: {record['status']}\n"
            f"reviewed-head: {record['reviewed_head']}\n"
            f"added-range: {record['added_start']}+{record['added_len']}\n"
            f"added-sha256: {record['added_sha256']}\n")


def write(record):
    """Atomic publish: temp file in the same dir + os.replace. Raises on failure; leaves nothing."""
    path = path_for(record["task"], record["target_repo"])
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".attest.", dir=os.path.dirname(path))
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(record, f, indent=2, sort_keys=True)
            f.write("\n")
        os.replace(tmp, path)
    except BaseException:
        try:
            os.remove(tmp)
        except OSError:
            pass
        raise
    return path


def load(task, *, expected_reviewer, relay_file, target_repo, path=None):
    """Validated read. Returns (record, None) or (None, reason). Never trusts existence."""
    try:
        path = path or path_for(task, target_repo)
    except RuntimeError as e:
        return None, str(e)
    try:
        with open(path, "r") as f:
            rec = json.load(f)
    except FileNotFoundError:
        return None, f"no attestation record for {task} at {path}"
    except (OSError, ValueError) as e:
        return None, f"attestation record unreadable/malformed: {e}"
    if not isinstance(rec, dict) or rec.get("schema") != SCHEMA:
        return None, "attestation record has the wrong schema"
    for k in ("task", "reviewer", "status", "reviewed_head", "added_start", "added_len",
              "added_sha256", "trailer_sha256", "relay_file", "target_repo", "isolated"):
        if k not in rec:
            return None, f"attestation record missing field {k}"
    if rec["task"] != task:
        return None, f"attestation record is for task {rec['task']}, not {task}"
    if relay_file is None:
        # Caller resolved the record through a harness-written receipt (marathon result@1
        # `attest_path`) and has no independent relay-file path; the record names the file, and
        # every content check below still runs against that file.
        relay_file = rec["relay_file"]
    if os.path.realpath(rec["relay_file"]) != os.path.realpath(relay_file):
        return None, f"attestation record is for relay file {rec['relay_file']}, not {relay_file}"
    if os.path.realpath(rec["target_repo"]) != os.path.realpath(target_repo):
        return None, f"attestation record is for repo {rec['target_repo']}, not {target_repo}"
    if not expected_reviewer or rec["reviewer"] != expected_reviewer:
        return None, f"attestation reviewer is {rec['reviewer']}, expected {expected_reviewer or '(none)'}"
    if rec["status"] not in TERMINAL:
        return None, f"attestation status {rec['status']} is not terminal"
    current = file_status(relay_file)
    if current != rec["status"]:
        return None, f"relay file STATUS is now {current or '(none)'}, attestation says {rec['status']}"
    try:
        canon = canonical(relay_file)
    except OSError as e:
        return None, f"relay file unreadable: {e}"
    start, length = int(rec["added_start"]), int(rec["added_len"])
    if start < 0 or length <= 0 or start + length > len(canon):
        return None, "attestation added-range is out of bounds for the current relay file"
    added = canon[start:start + length]
    if sha256(added) != rec["added_sha256"]:
        return None, "review text no longer matches the attested digest"
    trailer = trailer_text(rec).encode("utf-8")
    if sha256(trailer) != rec["trailer_sha256"]:
        return None, "attestation record does not match its own trailer"
    if canon[start + length:start + length + len(trailer)] != trailer:
        return None, "attestation trailer is not where the record says it is"
    return rec, None


def candidate_ok(record, candidate_sha, target_repo):
    """Is `candidate_sha` the reviewed revision plus transcript-only commits? -> (bool, reason).

    Contract (GH-505 plan, round 2 Q9): reviewed_head must be an ancestor of the candidate AND the
    endpoint tree diff must be empty outside relay-system/, the relay file's own tracked path, and
    the relay file's directory when it has one (marathon's per-phase dir holds only harness records).
    Any git error refuses. Non-isolated turns and seeded-artifact reviews are never merge-eligible:
    the reviewed input was not the pinned target tree.
    """
    if not record.get("isolated"):
        return False, "review ran without worktree isolation; its input was not a pinned revision"
    if record.get("artifact_sha256"):
        return False, "review was of a seeded artifact, not the target tree; transcript-only attestation"
    reviewed = record["reviewed_head"]
    if not candidate_sha:
        return False, "no candidate revision"
    anc = subprocess.run(["git", "-C", target_repo, "merge-base", "--is-ancestor", reviewed, candidate_sha],
                         capture_output=True, text=True)
    if anc.returncode == 1:
        return False, f"reviewed head {reviewed[:12]} is not an ancestor of candidate {candidate_sha[:12]}"
    if anc.returncode != 0:
        return False, f"git merge-base failed: {anc.stderr.strip()}"
    spec = ["--", f":(top,exclude){TRANSCRIPT_DIR}"]
    rel = record.get("relay_file_rel")
    if rel:
        spec.append(f":(top,literal,exclude){rel}")
        # The relay file's own directory is harness metadata too — marathon keeps RELAY.md beside
        # ESCALATION.md and its receipts under <phases-dir>/<phase>/ — but never the target root.
        d = os.path.dirname(rel)
        if d:
            spec.append(f":(top,literal,exclude){d}/")
    diff = subprocess.run(["git", "-C", target_repo, "diff", "--quiet", reviewed, candidate_sha] + spec,
                          capture_output=True, text=True)
    if diff.returncode == 1:
        return False, f"candidate {candidate_sha[:12]} changes non-transcript content after reviewed head {reviewed[:12]}"
    if diff.returncode != 0:
        return False, f"git diff failed: {diff.stderr.strip()}"
    return True, None


def rev_parse(repo, ref="HEAD"):
    out = subprocess.run(["git", "-C", repo, "rev-parse", ref], capture_output=True, text=True)
    return out.stdout.strip() if out.returncode == 0 else ""


def repo_relative(path, repo):
    """Repo-relative path when `path` is a TRACKED file inside `repo`; else None."""
    try:
        rel = os.path.relpath(os.path.realpath(path), os.path.realpath(repo))
    except ValueError:
        return None
    if rel.startswith(".."):
        return None
    out = subprocess.run(["git", "-C", repo, "ls-files", "--error-unmatch", "--", rel],
                         capture_output=True, text=True)
    return rel if out.returncode == 0 else None
