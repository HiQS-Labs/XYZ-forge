#!/usr/bin/env python3
"""wave_reconcile.py (GH-165) — Post-Merge Wave & Marathon Lifecycle Reconciler.

The canonical, single-command Python reconciler to automate post-merge lifecycle
transitions across Active Docs (PROJECT/2-WORKING/ -> 3-COMPLETED/ or 4-MISC/),
ROADMAP.md, releases.db SQLite ledger, generated dashboards, and next-wave marathon planning.
"""

import argparse
import fcntl
import glob
import hashlib
import json
import time
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

sys.dont_write_bytecode = True
from harness_paths import github_slug_from_origin, harness_home, harness_tool, is_vendored, repo_root, resolve_tool


class ReconcileError(Exception):
    """Custom exception class ensuring proper rollback catching."""

    def __init__(self, message, code=2):
        super().__init__(message)
        self.code = code


def log(msg):
    print(f"wave-reconcile: {msg}", flush=True)


# GH-684: the one skip literal. A catch-up-recovered landing whose doc fails hygiene is reported as
# `wave-reconcile: SKIPPED GH-<n> — <reason>`; utils/py/hosted_lane_report.py imports this marker so
# the emitter and the consumer cannot drift. The end-of-run summary deliberately does NOT start with it.
SKIP_MARKER = "SKIPPED "


def log_err(msg):
    print(f"wave-reconcile: ERROR — {msg}", file=sys.stderr, flush=True)


def die(msg, code=2):
    log_err(msg)
    raise ReconcileError(msg, code=code)


class ReconcilerLock:
    """Lock manager preventing concurrent reconciliation runs."""

    def __init__(self, lock_path):
        self.lock_path = lock_path
        self.fd = None

    def __enter__(self):
        try:
            self.fd = open(self.lock_path, "w")
            fcntl.flock(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.fd.write(f"pid={os.getpid()}\ntime={datetime.now().isoformat()}\n")
            self.fd.flush()
            return self
        except (BlockingIOError, OSError) as e:
            die(f"Could not acquire reconciler lock at {self.lock_path}: {e}", code=8)

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.fd:
            try:
                fcntl.flock(self.fd, fcntl.LOCK_UN)
                self.fd.close()
            except OSError:
                pass


def check_hosted_reconciler_in_flight(repo_root, repo_slug=None, force=False):
    """Refuse local reconciliation if hosted wave-reconcile.yml is running/queued (GH-496)."""
    cmd = [
        "gh", "run", "list",
        "--workflow", "wave-reconcile.yml",
        "--json", "databaseId,status,conclusion,createdAt,headSha,event",
        "--limit", "10",
    ]
    if repo_slug:
        cmd.extend(["--repo", repo_slug])

    try:
        res = subprocess.run(
            cmd,
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=15,
        )
    except FileNotFoundError:
        if force:
            log("  WARNING: 'gh' CLI not found; bypassing hosted in-flight check via --force-local-reconcile")
            return
        die("Hosted reconciler check failed: 'gh' command not found. Pass --force-local-reconcile to bypass.", code=8)
    except subprocess.TimeoutExpired:
        if force:
            log("  WARNING: 'gh run list' timed out; bypassing hosted in-flight check via --force-local-reconcile")
            return
        die("Hosted reconciler check failed: 'gh run list' timed out. Pass --force-local-reconcile to bypass.", code=8)
    except Exception as e:
        if force:
            log(f"  WARNING: gh run list failed ({e}); bypassing hosted in-flight check via --force-local-reconcile")
            return
        die(f"Hosted reconciler check failed: {e}. Pass --force-local-reconcile to bypass.", code=8)

    if res.returncode != 0:
        if force:
            log(f"  WARNING: gh run list exited {res.returncode}; bypassing hosted in-flight check via --force-local-reconcile")
            return
        err = res.stderr.strip() or "unknown error"
        die(f"Hosted reconciler check failed: unable to query GitHub Actions ({err}). Pass --force-local-reconcile to bypass.", code=8)

    stdout = res.stdout.strip()
    if not stdout:
        runs = []
    else:
        try:
            runs = json.loads(stdout)
        except ValueError:
            if force:
                return
            die("Hosted reconciler check failed: malformed JSON from gh run list. Pass --force-local-reconcile to bypass.", code=8)

    in_flight = [
        r for r in runs
        if r.get("status") in ("queued", "in_progress", "waiting", "requested")
    ]
    if in_flight:
        run_ids = ", ".join(f"#{r.get('databaseId')} ({r.get('status')})" for r in in_flight)
        if force:
            log(f"  WARNING: Overriding active hosted reconciliation run(s): {run_ids} via --force-local-reconcile")
            return
        die(
            f"Hosted reconciliation workflow (wave-reconcile.yml) is currently in-flight: {run_ids}. "
            "Refusing local reconciliation to prevent concurrent landing collisions. "
            "Wait for hosted workflow to complete, or pass --force-local-reconcile to override.",
            code=8,
        )


class RollbackJournal:
    """Snapshots pre-mutation file states and rolls back on failure."""

    def __init__(self, repo_root=None):
        # GH-698 finding 4: rollback telemetry must land in the TARGET repo's
        # .tick/events even when reconciliation runs from another cwd.
        self.repo_root = os.path.abspath(repo_root) if repo_root else os.getcwd()
        self.backups = {}  # original_path -> backup_temp_path
        self.created_files = set()
        self.deleted_files = set()

    def snapshot(self, path):
        p = os.path.abspath(path)
        if p not in self.backups and os.path.exists(p):
            tmp = tempfile.NamedTemporaryFile(delete=False)
            tmp.close()
            shutil.copy2(p, tmp.name)
            self.backups[p] = tmp.name

    def track_created(self, path):
        self.created_files.add(os.path.abspath(path))

    def rollback(self):
        log("Rolling back all uncommitted mutations...")
        # GH-698 F8/GH-707: a rollback is a silent red. Keep the signal on the
        # existing event surface, but use tick's envelope and an explicitly
        # non-coordination type. In particular, do not invent a `task`: older
        # bare records could seed a phantom task, while the #702 projection
        # filter safely ignores this analytics record.
        try:
            events_dir = os.path.join(self.repo_root, ".tick", "events")
            if os.path.isdir(events_dir):
                now = datetime.now(timezone.utc)
                ts = now.isoformat(timespec="milliseconds").replace("+00:00", "Z")
                filename_ts = ts.replace(":", "-")
                evt = os.path.join(
                    events_dir, f"{filename_ts}-wave-reconcile-rollback.jsonl"
                )
                with open(evt, "a", encoding="utf-8") as fh:
                    fh.write(json.dumps({
                        "schema_version": "0.2.0",
                        "ts": ts,
                        "type": "wave_reconcile.rollback",
                        "agent": "wave_reconcile",
                        "reason": "uncommitted-mutations",
                    }) + "\n")
        except Exception:
            pass  # the event must never worsen the rollback
        for created in self.created_files:
            if os.path.exists(created):
                try:
                    os.unlink(created)
                except OSError:
                    pass
        for orig, backup in self.backups.items():
            try:
                os.makedirs(os.path.dirname(orig), exist_ok=True)
                shutil.copy2(backup, orig)
            except OSError as e:
                log_err(f"Failed restoring {orig} from {backup}: {e}")
        self.cleanup()

    def changed(self):
        """Whether any journaled artifact differs, ignoring empty directories."""
        return any(os.path.exists(p) for p in self.created_files) or any(
            not os.path.exists(p) or Path(p).read_bytes() != Path(backup).read_bytes()
            for p, backup in self.backups.items()
        )

    def cleanup(self):
        for backup in self.backups.values():
            if os.path.exists(backup):
                try:
                    os.unlink(backup)
                except OSError:
                    pass
        self.backups.clear()
        self.created_files.clear()


def resolve_repo_root():
    """Find repository root containing .git."""
    cur = os.path.abspath(os.getcwd())
    while cur != os.path.dirname(cur):
        if os.path.isdir(os.path.join(cur, ".git")) or os.path.isfile(os.path.join(cur, ".git")):
            return cur
        cur = os.path.dirname(cur)
    return os.path.abspath(os.getcwd())


def check_porcelain_cleanliness(repo_root, allow_dirty=False):
    """Assert clean git working tree before mutation."""
    cmd = ["git", "-C", repo_root, "status", "--porcelain"]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        die(f"git status failed: {r.stderr}")
    dirt = r.stdout.strip()
    if dirt and not allow_dirty:
        die(
            f"Working tree is dirty. Must be completely clean to reconcile:\n{dirt}",
            code=3,
        )
    return dirt


def verify_rollback_completeness(repo_root, baseline):
    """GH-271: a rollback must restore the pre-run tree, not merely claim to.

    The 2026-08-23 failure left regenerated dashboards and a stray MARATHON-PLAN-<date>.md
    behind after "Rolling back all uncommitted mutations..." reported success. Compare
    porcelain against the pre-run baseline (fixtures may legitimately start dirty under
    --allow-dirty) and name every leftover — an incomplete rollback must be visible, never
    a silent success.
    """
    if baseline is None:
        return
    cmd = ["git", "-C", repo_root, "status", "--porcelain"]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        log_err(f"Rollback completeness could not be verified: git status failed: {r.stderr}")
        return
    current = r.stdout.strip()
    if current != baseline:
        base_lines = set(baseline.splitlines())
        log_err("Rollback INCOMPLETE — working tree differs from the pre-run state. Leftovers:")
        for line in current.splitlines():
            if line not in base_lines:
                log_err(f"  {line}")


def check_current_branch(repo_root, expected_branch="development", skip_branch_check=False):
    """Verify active branch matches target branch."""
    if skip_branch_check:
        return
    cmd = ["git", "-C", repo_root, "branch", "--show-current"]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    current = r.stdout.strip()
    if current != expected_branch:
        die(
            f"Active branch is '{current}', but post-merge reconciliation requires '{expected_branch}'.",
            code=3,
        )


def pull_upstream(repo_root, branch="development"):
    """Fast-forward pull from origin."""
    cmd = ["git", "-C", repo_root, "pull", "--ff-only", "origin", branch]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        die(f"git pull --ff-only failed: {r.stderr}")


def fetch_issue_state(repo_root, issue_num, offline_manifest=None):
    """Linked issue state, or None when unknowable (GH-202).

    None means PROMOTE as before — backward-compatible for offline manifests that
    carry no issue list; only a positively-OPEN issue suppresses promotion.
    Offline manifests may declare {"issues": [{"number": N, "state": "OPEN"}]}.
    """
    if offline_manifest:
        for entry in offline_manifest.get("issues", []):
            if str(entry.get("number")) == str(issue_num):
                return str(entry.get("state", "")).upper()
        return None  # legacy manifest without an issues key: unknown, promote as before
    # LIVE reconcile: a failed gh is a failed fact-check, not an unknown state. A transient
    # error (network, rate limit) must NOT silently fall back to promotion (GH-202 review,
    # Agy round 1 blocker) — that would mis-promote every open issue on a bad network day.
    try:
        r = subprocess.run(
            ["gh", "issue", "view", str(issue_num), "--json", "state"],
            cwd=repo_root, capture_output=True, text=True, check=False,
        )
    except OSError as exc:
        die(f"gh issue view #{issue_num} could not run ({exc}); refusing to guess issue state — "
            f"fix gh access or pass --offline with an issues[] manifest", code=6)
    if r.returncode != 0:
        die(f"gh issue view #{issue_num} failed (exit {r.returncode}): {r.stderr.strip()}; "
            f"refusing to guess issue state — fix gh access or pass --offline with an issues[] manifest", code=6)
    try:
        import json as _json
        return str(_json.loads(r.stdout).get("state", "")).upper()
    except ValueError:
        die(f"gh issue view #{issue_num} returned unparseable output; refusing to guess issue state", code=6)


def record_merge_evidence(doc_path, pr_meta, dry_run=False, journal=None):
    """Open-issue docs stay in 2-WORKING; record the merged-PR evidence in place (GH-202)."""
    merged_at = (pr_meta.get("mergedAt") or "")[:10]
    label = landing_label(pr_meta)
    verb = "landed" if pr_meta.get("artifactKind") == "commit" else "merged"
    note = "\n## Merge evidence\n\n- " + label + " " + verb + " " + (merged_at or "(date unknown)") + " — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).\n"
    with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    if ("\n- " + label + " " + verb + " ") in content or content.startswith("- " + label + " " + verb + " "):
        return  # idempotent
    print("TRANSITION " + json.dumps(["doc", "merge-evidence", label, os.path.basename(doc_path)]), flush=True)
    if not dry_run:
        if journal is not None:
            journal.snapshot(doc_path)
        with open(doc_path, "a", encoding="utf-8") as f:
            f.write(note)


def fetch_pr_metadata(repo_root, pr_id, offline_manifest=None, dry_run=False):
    """Fetch merged PR metadata from GitHub or offline manifest."""
    if offline_manifest:
        for entry in offline_manifest.get("prs", []):
            if str(entry.get("number")) == str(pr_id):
                return entry
        die(f"PR #{pr_id} not found in offline manifest", code=4)

    if dry_run:
        # In dry run without offline manifest, try gh if available or return stub preview
        pass

    cmd = [
        "gh",
        "pr",
        "view",
        str(pr_id),
        "--json",
        "number,title,state,mergedAt,mergeCommit,baseRefName,headRefName,body,url,headRefOid,commits",
    ]
    r = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        if dry_run:
            log(f"dry-run: gh pr view unavailable ({r.stderr.strip()}); using synthetic preview metadata for PR #{pr_id}")
            return {
                "number": int(pr_id),
                "title": f"Preview PR #{pr_id}",
                "state": "MERGED",
                "mergedAt": datetime.now().isoformat() + "Z",
                "baseRefName": "development",
                "headRefOid": None,
                "commits": [],
                "body": f"Closes #{pr_id}",
            }
        die(f"gh pr view {pr_id} failed: {r.stderr}", code=4)
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError as e:
        die(f"Failed parsing gh pr view JSON for PR #{pr_id}: {e}", code=4)


def fetch_commit_metadata(repo_root, commit_id, offline_manifest=None):
    """Return direct-commit landing metadata in the reconciler's internal shape."""
    if offline_manifest:
        for entry in offline_manifest.get("commits", []):
            if str(entry.get("sha", "")).startswith(str(commit_id)):
                message = entry.get("message") or ""
                return {
                    "number": str(entry.get("sha", commit_id))[:12],
                    "title": message.splitlines()[0] if message else f"commit {commit_id}",
                    "state": "MERGED", "mergedAt": entry.get("committedAt"),
                    "baseRefName": "development", "body": message,
                    "url": entry.get("url", ""), "artifactKind": "commit",
                    "sha": entry.get("sha", commit_id),
                    "mergeCommit": {"oid": entry.get("sha", commit_id)},
                }
        die(f"Commit {commit_id} not found in offline manifest", code=4)

    resolved = subprocess.run(
        ["git", "-C", repo_root, "rev-parse", "--verify", f"{commit_id}^{{commit}}"],
        capture_output=True, text=True, check=False,
    )
    if resolved.returncode != 0:
        die(f"Commit {commit_id} cannot be resolved locally", code=4)
    sha = resolved.stdout.strip()
    reachable = subprocess.run(
        ["git", "-C", repo_root, "merge-base", "--is-ancestor", sha, "development"],
        capture_output=True, text=True, check=False,
    )
    if reachable.returncode != 0:
        die(f"Commit {sha} is not reachable from local development", code=4)
    shown = subprocess.run(
        ["git", "-C", repo_root, "show", "-s", "--format=%cI%x00%B", sha],
        capture_output=True, text=True, check=False,
    )
    if shown.returncode != 0 or "\0" not in shown.stdout:
        die(f"Could not read commit metadata for {sha}", code=4)
    committed_at, message = shown.stdout.split("\0", 1)
    message = message.strip()
    slug = github_slug_from_origin(repo_root)
    return {
        "number": sha[:12], "title": message.splitlines()[0], "state": "MERGED",
        "mergedAt": committed_at, "baseRefName": "development", "body": message,
        "url": f"https://github.com/{slug}/commit/{sha}" if slug else "",
        "artifactKind": "commit", "sha": sha, "mergeCommit": {"oid": sha},
    }


def landing_label(meta):
    if meta.get("artifactKind") == "commit":
        return "commit " + str(meta.get("sha") or meta.get("number"))[:12]
    return "PR #" + str(meta.get("number", "?"))


QUALIFICATION_SCHEMA = "wave-qualification@1"
QUALIFICATION_PATH = r"TESTS-RESULTS/[0-9]{4}-[0-9]{2}-[0-9]{2}\+GH-591/wave-[0-9a-f]{40}/validation\.jsonl"


def qualification_summary(raw, tested_sha):
    """Require the existing runner's complete, unquarantined sequential evidence."""
    rows = [json.loads(line) for line in raw.splitlines() if line.strip()]
    if not rows or any(not isinstance(row, dict) for row in rows):
        raise ValueError("missing or malformed validation telemetry")
    starts = [row for row in rows if row.get("event") == "run.start"]
    summaries = [row for row in rows if row.get("event") == "run.summary"]
    if len(starts) != 1 or len(summaries) != 1 or rows[-1] != summaries[0]:
        raise ValueError("validation telemetry has no unique completed run")
    start, summary = starts[0], summaries[0]
    registered = start.get("registered")
    if (start.get("commit") != tested_sha or start.get("mode") != "sequential"
            or start.get("tier") != 3 or type(registered) is not int or registered <= 0
            or not start.get("run") or any(row.get("run") != start["run"]
                or row.get("runner") != "validate" for row in rows)):
        raise ValueError("validation run identity, mode or registry does not match")
    suites = [row for row in rows if row.get("event") == "suite"]
    sequential = [row for row in suites if row.get("lane") == "sequential"]
    if (len(sequential) != registered or len({row.get("name") for row in sequential}) != registered
            or any(type(row.get("rc")) is not int or row["rc"] != 0 for row in suites)
            or summary.get("failed") != 0 or summary.get("total") != registered + 3
            or summary.get("passed") != summary["total"]
            or summary.get("envelope_rc") != "0" or summary.get("suite_events_match") != "yes"
            or str(summary.get("run_set")) != str(registered)
            or str(summary.get("registered")) != str(registered)):
        raise ValueError("validation telemetry is failed, incomplete or quarantined")
    names = {row.get("name") for row in suites}
    if not {"python:test_python_layer.py", "gamma-poison-staleness-probe"} <= names:
        raise ValueError("validation is missing required full-suite probes")
    return summary


def qualification_receipt_matches(repo_root, entry, meta):
    """An integrated snapshot passed; never claim the historical merge tree ran."""
    tested, landing = entry.get("tested_commit"), (meta.get("mergeCommit") or {}).get("oid")
    if (entry.get("schema_version") != QUALIFICATION_SCHEMA
            or not isinstance(tested, str) or not re.fullmatch(r"[0-9a-f]{40}", tested)
            or not isinstance(landing, str) or not re.fullmatch(r"[0-9a-f]{40}", landing)
            or entry.get("landing_commit") != landing
            or entry.get("result") != "pass" or type(entry.get("rc")) is not int or entry["rc"] != 0
            or entry.get("gate") != "validate.sh --sequential"
            or entry.get("artifact_kind") != meta.get("artifactKind", "pr")):
        return False
    if meta.get("artifactKind") != "commit" and (
            type(entry.get("pr")) is not int or entry["pr"] != meta.get("number")):
        return False
    if "pr_number" in entry and entry["pr_number"] != entry.get("pr"):
        return False
    telemetry = entry.get("telemetry", "")
    if not isinstance(telemetry, str) or not re.fullmatch(QUALIFICATION_PATH, telemetry):
        return False
    path = Path(repo_root).resolve() / telemetry
    try:
        if path.resolve() != path:  # Neither a file nor a parent may redirect evidence.
            return False
        raw = path.read_bytes()
        if hashlib.sha256(raw).hexdigest() != entry.get("telemetry_sha256"):
            return False
        qualification_summary(raw, tested)
        for older, newer in ((landing, tested), (tested, "HEAD")):
            if subprocess.run(["git", "merge-base", "--is-ancestor", older, newer],
                              cwd=repo_root, capture_output=True, check=False).returncode:
                return False
    except (OSError, ValueError, TypeError, KeyError):
        return False
    return True


def committed_qualifications(repo_root):
    """Only bot-committed completion receipts can suppress a replay or recover a lost event."""
    paths = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", "HEAD", "--",
                                     "TESTS-RESULTS/"], cwd=repo_root, text=True).splitlines()
    found = []
    for path in paths:
        if not re.fullmatch(QUALIFICATION_PATH.replace("validation", "provenance"), path):
            continue
        raw = subprocess.check_output(["git", "show", f"HEAD:{path}"], cwd=repo_root, text=True)
        for line in raw.splitlines():
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if isinstance(entry, dict) and entry.get("schema_version") == QUALIFICATION_SCHEMA:
                found.append(entry)
    return found


def qualify_landings(repo_root, metas, journal):
    """Produce retained provenance in the existing closeout transaction, after a real full gate."""
    from gate_env import gate_env
    from proc_group import run_bounded

    previous = committed_qualifications(repo_root)
    pending = [meta for meta in metas if not any(
        qualification_receipt_matches(repo_root, entry, meta) for entry in previous)]
    if not pending:
        return
    check_porcelain_cleanliness(repo_root)
    tested = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo_root, text=True).strip()
    for meta in pending:
        landing = (meta.get("mergeCommit") or {}).get("oid", "")
        if (meta.get("state") != "MERGED" or meta.get("baseRefName") != "development"
                or not re.fullmatch(r"[0-9a-f]{40}", landing)
                or subprocess.run(["git", "merge-base", "--is-ancestor", landing, tested],
                                  cwd=repo_root, capture_output=True, check=False).returncode):
            die(f"Qualification refuses {landing_label(meta)}: merge not in the tested development snapshot", code=6)
    log(f"Qualifying {len(pending)} landing(s) in integrated snapshot {tested} with the full sequential suite")
    with tempfile.TemporaryDirectory(prefix="wave-qualification-") as temporary:
        scratch = Path(temporary).resolve()
        clone = scratch / "repo"
        telemetry = clone / ".tick" / "telemetry"
        # Reuse the harness environment contract, then isolate Git and runner controls.
        env = {k: v for k, v in gate_env().items()
               if not k.startswith(("GIT_", "RT_", "XYZ_VALIDATE_", "PYTEST_"))
               and k not in ("XYZ_HARNESS_DB", "PYTHONPATH", "PYTHONHOME")}
        config = scratch / "gitconfig"
        config.write_text('[user]\nname = Qualification Fixture\nemail = qualification@example.invalid\n'
                          '[init]\ndefaultBranch = main\n')
        env.update(GIT_CONFIG_GLOBAL=str(config), GIT_CONFIG_NOSYSTEM="1",
                   RELAY_SELF_SUFFICIENCY_SKIP="1", TICK_REPO_ROOT=str(clone))
        def command(args, capture=False):
            result = run_bounded(args, cwd=str(clone if clone.exists() else scratch), env=env, timeout=5400)
            if not capture:
                print(result.stdout, end="", flush=True)
                print(result.stderr, end="", file=sys.stderr, flush=True)
            if result.timed_out or result.rc != 0:
                raise subprocess.CalledProcessError(124 if result.timed_out else result.rc, args,
                                                    result.stdout, result.stderr)
            return result
        try:
            # --no-local prevents object hardlinks/alternates as well as shared git metadata.
            command(["git", "clone", "--no-local", "--quiet", repo_root, str(clone)])
            command(["git", "checkout", "--quiet", "--detach", tested])
            origin = subprocess.check_output(["git", "remote", "get-url", "origin"],
                                             cwd=repo_root, text=True).strip()
            command(["git", "remote", "set-url", "origin", origin])
            before_config = command(["git", "config", "--local", "--list"], True).stdout
            command(["python3", "-c", "import pytest"])
            command(["npm", "ci"])
            validation = command(["bash", "validate.sh", "--sequential"])
            if (command(["git", "rev-parse", "HEAD"], True).stdout.strip() != tested
                    or command(["git", "status", "--porcelain"], True).stdout.strip()
                    or command(["git", "config", "--local", "--list"], True).stdout != before_config):
                die("Qualification clone identity/content changed under the suite", code=6)
            # Suites may launch nested validator probes. Bind proof to the exact
            # process we launched, not another passing run in the telemetry directory.
            files = list(telemetry.glob(f"validate-sequential-*-{validation.pgid}.jsonl"))
            if len(files) != 1:
                die("Qualification requires exactly one retained validation run", code=6)
            raw = files[0].read_bytes()
            summary = qualification_summary(raw, tested)
            if summary['run'] != f"{tested[:9]}-{validation.pgid}":
                die("Qualification telemetry does not identify the launched validation process", code=6)
        except (subprocess.SubprocessError, OSError, ValueError) as exc:
            die(f"Full-suite qualification failed; no receipt produced: {exc}", code=6)
    if subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo_root, text=True).strip() != tested:
        die("Publishing HEAD changed during qualification; rerun from fresh development", code=6)
    check_porcelain_cleanliness(repo_root)
    now = datetime.now(timezone.utc)
    folder = Path(repo_root) / "TESTS-RESULTS" / f"{now:%Y-%m-%d}+GH-591" / f"wave-{tested}"
    folder.mkdir(parents=True, exist_ok=True)
    telemetry_path, receipt_path = folder / "validation.jsonl", folder / "provenance.jsonl"
    for path in (telemetry_path, receipt_path):
        if path.exists():
            die(f"Refusing to overwrite qualification evidence: {path.name}", code=6)
        journal.track_created(path)
    telemetry_path.write_bytes(raw)
    entries = []
    for meta in pending:
        entry = dict(schema_version=QUALIFICATION_SCHEMA, artifact_kind=meta.get("artifactKind", "pr"),
                     tested_commit=tested, landing_commit=meta["mergeCommit"]["oid"], result="pass", rc=0,
                     gate="validate.sh --sequential", timestamp=now.isoformat(),
                     telemetry=str(telemetry_path.relative_to(repo_root)),
                     telemetry_sha256=hashlib.sha256(raw).hexdigest(), passed=summary["passed"],
                     total=summary["total"])
        if meta.get("artifactKind") != "commit":
            entry["pr"] = meta["number"]
        if os.environ.get("GITHUB_ACTIONS") == "true":
            entry["run_url"] = (f"https://github.com/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/"
                                f"{os.environ.get('GITHUB_RUN_ID', '')}")
        entries.append(json.dumps(entry, sort_keys=True))
    receipt_path.write_text("\n".join(entries) + "\n", encoding="utf-8")
    log(f"Full-suite qualification passed; retained {receipt_path.relative_to(repo_root)}")


def check_provenance_receipts(repo_root, pr_meta):
    """Require a JSONL receipt attributable to this PR (GH-425).

    Accept top-level pr/pr_number (positive integer or decimal string), or an
    exact full commit matching GitHub's mergeCommit. Explicit PR fields must all
    match; a conflicting PR cannot be rescued by a commit match. Filenames and
    issue numbers are not PR identity. This checks attribution, not test success
    or whether the receipt was committed; report only the identity actually read.
    """
    pr_num = pr_meta.get("number")
    results_dir = os.path.join(repo_root, "TESTS-RESULTS")
    if not os.path.isdir(results_dir):
        die(f"--gate failure: TESTS-RESULTS directory missing; cannot verify provenance for PR #{pr_num}", code=6)

    def pr_number(value):
        if type(value) is int and value > 0:
            return str(value)
        if isinstance(value, str) and re.fullmatch(r"[1-9][0-9]*", value):
            return value
        return None

    expected_pr = pr_number(pr_num)

    candidate_shas = set()
    merge_commit = pr_meta.get("mergeCommit") or {}
    merge_sha = merge_commit.get("oid") if isinstance(merge_commit, dict) else None
    if isinstance(merge_sha, str) and re.fullmatch(r"[0-9a-fA-F]{40}", merge_sha):
        candidate_shas.add(merge_sha.lower())

    head_oid = pr_meta.get("headRefOid")
    if isinstance(head_oid, str) and re.fullmatch(r"[0-9a-fA-F]{40}", head_oid):
        candidate_shas.add(head_oid.lower())

    commits_list = pr_meta.get("commits") or []
    if isinstance(commits_list, list):
        for c in commits_list:
            if isinstance(c, dict):
                c_oid = c.get("oid")
                if isinstance(c_oid, str) and re.fullmatch(r"[0-9a-fA-F]{40}", c_oid):
                    candidate_shas.add(c_oid.lower())

    for root, dirs, files in os.walk(results_dir):
        dirs.sort()
        for name in sorted(files):
            if name not in ("error_log.jsonl", "provenance.jsonl"):
                continue
            path = os.path.join(root, name)
            if os.path.islink(path) or not os.path.isfile(path):
                continue
            try:
                with open(path, encoding="utf-8") as receipt:
                    for line_num, line in enumerate(receipt, 1):
                        try:
                            entry = json.loads(line)
                        except ValueError:
                            continue
                        if not isinstance(entry, dict):
                            continue
                        if str(entry.get("schema_version", "")).startswith("wave-qualification"):
                            if qualification_receipt_matches(repo_root, entry, pr_meta):
                                log(f"  Full-suite integration receipt matched for {landing_label(pr_meta)}: "
                                    f"{os.path.relpath(path, repo_root)}:{line_num}")
                                return
                            continue  # A malformed qualification cannot fall through to legacy PR identity.
                        pr_fields = [key for key in ("pr", "pr_number") if key in entry]
                        matched = None
                        if pr_fields:
                            if expected_pr and all(pr_number(entry[key]) == expected_pr for key in pr_fields):
                                matched = f"{pr_fields[0]}={expected_pr}"
                        elif candidate_shas:
                            entry_commits = []
                            for key in ("commit", "identity_before", "identity_after"):
                                val = entry.get(key)
                                if isinstance(val, str):
                                    val = val.strip()
                                    if len(val) >= 7 and re.fullmatch(r"[0-9a-fA-F]{7,40}", val):
                                        entry_commits.append((key, val))
                            for key, c_val in entry_commits:
                                c_lower = c_val.lower()
                                if any(cand.startswith(c_lower) or c_lower.startswith(cand) for cand in candidate_shas):
                                    matched = f"{key}={c_val}"
                                    break
                        if matched:
                            relpath = os.path.relpath(path, repo_root)
                            log(f"  Provenance receipt matched for PR #{pr_num}: {relpath}:{line_num} ({matched})")
                            return
            except (OSError, UnicodeError):
                continue  # An unreadable receipt cannot establish attribution.
    die(f"--gate failure: No provenance.jsonl or error_log.jsonl entry matches PR #{pr_num} "
        "by pr/pr_number or exact merge commit in TESTS-RESULTS/", code=6)


def validate_pre_merge_receipts(repo_root, head_sha, pr_num=None):
    """Ensure a passing test receipt matching HEAD SHA or PR number is COMMITTED in Git tree (GH-496)."""
    try:
        tree_files = subprocess.check_output(
            ["git", "ls-tree", "-r", "--name-only", "HEAD", "TESTS-RESULTS/"],
            cwd=repo_root,
            text=True,
            stderr=subprocess.DEVNULL,
        ).splitlines()
    except Exception:
        tree_files = []

    matching_receipts = [
        f for f in tree_files
        if f.endswith("provenance.jsonl") or f.endswith("error_log.jsonl")
    ]
    if not matching_receipts:
        return f"No committed provenance.jsonl or error_log.jsonl receipts found under TESTS-RESULTS/ at HEAD {head_sha[:10]}."

    try:
        recent_shas = subprocess.check_output(
            ["git", "log", "-n", "10", "--format=%H", "HEAD"],
            cwd=repo_root,
            text=True,
            stderr=subprocess.DEVNULL,
        ).splitlines()
    except Exception:
        recent_shas = [head_sha]
    recent_shas_lower = set(s.lower() for s in recent_shas)

    found_match = False
    expected_pr = str(pr_num) if pr_num else None
    for receipt_rel in matching_receipts:
        try:
            content = subprocess.check_output(
                ["git", "show", f"HEAD:{receipt_rel}"],
                cwd=repo_root,
                text=True,
                stderr=subprocess.DEVNULL,
            )
            for line in content.splitlines():
                if not line.strip():
                    continue
                try:
                    entry = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(entry, dict):
                    continue
                c_val = str(entry.get("commit") or "").lower()
                c_len = len(c_val)
                matched_sha = None
                commit_match = False
                if c_val and c_len >= 7:
                    try:
                        resolved = subprocess.check_output(
                            ["git", "rev-parse", "--verify", f"{c_val}^{{commit}}"],
                            cwd=repo_root,
                            text=True,
                            stderr=subprocess.DEVNULL,
                        ).strip().lower()
                        if resolved == head_sha.lower() or resolved in recent_shas_lower:
                            commit_match = True
                            matched_sha = resolved
                    except Exception:
                        pass

                pr_match = False
                if expected_pr:
                    pr_val = str(entry.get("pr") or entry.get("pr_number") or "")
                    if pr_val == expected_pr:
                        pr_match = True
                        if not matched_sha and c_val and c_len >= 7:
                            try:
                                matched_sha = subprocess.check_output(
                                    ["git", "rev-parse", "--verify", f"{c_val}^{{commit}}"],
                                    cwd=repo_root,
                                    text=True,
                                    stderr=subprocess.DEVNULL,
                                ).strip().lower()
                            except Exception:
                                pass

                if commit_match or pr_match:
                    outcomes = [entry[key] for key in ("result", "status") if key in entry]
                    rc = entry.get("rc")
                    outcome_ok = bool(outcomes) or "rc" in entry
                    outcome_ok = outcome_ok and all(
                        isinstance(value, str) and value in ("pass", "passed", "PASS")
                        for value in outcomes)
                    if "rc" in entry:
                        outcome_ok = outcome_ok and type(rc) is int and rc == 0
                    if outcome_ok:
                        # GH-496 / Codex QA: verify receipt is not stale.
                        # If matched_sha is not HEAD, verify that no code or docs outside
                        # TESTS-RESULTS/ changed between the tested commit and HEAD.
                        if matched_sha and matched_sha != head_sha.lower():
                            try:
                                diff_out = subprocess.check_output(
                                    ["git", "diff", "--name-only", f"{matched_sha}..{head_sha}"],
                                    cwd=repo_root,
                                    text=True,
                                    stderr=subprocess.DEVNULL,
                                ).splitlines()
                                code_modifications = [
                                    f for f in diff_out
                                    if not f.startswith("TESTS-RESULTS/")
                                ]
                                if code_modifications:
                                    # Stale receipt: code changed after this qualification run!
                                    continue
                            except Exception:
                                continue
                        found_match = True
                        break
            if found_match:
                break
        except Exception:
            continue

    if not found_match:
        target = f"PR #{pr_num}" if pr_num else f"commit {head_sha[:10]}"
        return f"No committed passing test receipt at HEAD matches {target} in TESTS-RESULTS/ (AGENTS.md: uncommitted provenance is not proof)."
    return None


# GH-271: closing-keyword clause + trailing title tag decide LINKAGE (what a merged PR may
# complete); bare mentions are references only. The #-or-GH- prefix is mandatory in both —
# "closes 5 issues" must not extract issue 5 — and keywords must sit on the same line as the
# ref, so a title ending in "fixed" cannot capture a body that opens with "#123".
CLOSING_KEYWORD_CLAUSE = re.compile(
    r"\b(?:closes?|closed|fix(?:es|ed)?|resolves?|resolved)[ \t]*:?[ \t]+"
    r"((?:#|GH-)[0-9]{1,6}\b"
    r"(?:(?:[ \t]*,[ \t]*(?:and[ \t]+)?|[ \t]+and[ \t]+)(?:#|GH-)[0-9]{1,6}\b)*)",
    re.IGNORECASE,
)
REF_IN_CLAUSE = re.compile(r"(?:#|GH-)([0-9]{1,6})\b", re.IGNORECASE)
# GH-429: GitHub also honours a closing keyword followed by the issue's full URL. Captured as
# (slug, number); extract_linked_issues keeps only the target repo's own slug, because
# fetch_issue_state and find_active_doc_for_issue key on the bare number and a foreign repo's
# "Closes https://github.com/other/repo/issues/7" must not promote this repo's GH-7.
CLOSING_KEYWORD_URL = re.compile(
    r"\b(?:closes?|closed|fix(?:es|ed)?|resolves?|resolved)[ \t]*:?[ \t]+"
    r"https?://github\.com/([\w.\-]+/[\w.\-]+?)/issues/([0-9]{1,6})\b",
    re.IGNORECASE,
)
# A `#N`/`GH-N` inside a URL (fragment `/#123`, path `/GH-123`, query `?#123`, `?issue=#123`,
# `&#123`) is part of the link, not a reference — GH-271 QA rounds 1+3. The lookbehind is one
# fixed-width character class.
MENTION = re.compile(r"(?<![A-Za-z0-9_/?.=&])(?:[Gg][Hh]-|#)([0-9]{1,6})\b")
TITLE_TRAILER = re.compile(
    r"\([ \t]*((?:(?:#|GH-)[0-9]{1,6}\b[ \t]*(?:[,;][ \t]*)?)+)[ \t]*\)[ \t]*$",
    re.IGNORECASE,
)
CODE_FENCE = re.compile(r"```.*?```", re.DOTALL)
INLINE_CODE = re.compile(r"`[^`\n]*`")


def _strip_code_blocks(text):
    """GitHub ignores closing keywords inside code; so does the reconciler."""
    return INLINE_CODE.sub(" ", CODE_FENCE.sub(" ", text))


def extract_linked_issues(pr_meta, repo_slug=None):
    """Split a PR's issue references into (closers, mentions) — GH-271.

    closers: refs introduced by a GitHub closing keyword (close/closes/closed/fix/fixes/
    fixed/resolve/resolves/resolved) before a #- or GH--prefixed number, comma lists
    included, plus a trailing "(#N)"/"(GH-N)" title tag. These mirror GitHub's own linking
    rules — extended to the repo's GH-N spelling, since PRs merge into `development` and
    the reconciler parses text rather than relying on default-branch auto-close — and are
    eligible for every reconciler action (promotion when the issue is closed, evidence +
    stays-active when open).

    mentions: bare GH-N/#N references in prose. The old extractor treated every mention as
    a link (PR #185's body yielded ten "linked" issues, two of them live active lanes), so
    a mention now only ever records merge evidence on an OPEN issue's active doc — never a
    promotion, ROADMAP move, or doc relocation.

    Both lists are deduplicated and sorted.
    """
    title = _strip_code_blocks(pr_meta.get("title") or "").strip()
    body = _strip_code_blocks(pr_meta.get("body") or "")
    closers, mentions = set(), set()

    scan_text = title + "\n" + body
    for m in CLOSING_KEYWORD_CLAUSE.finditer(scan_text):
        closers.update(int(n) for n in REF_IN_CLAUSE.findall(m.group(1)))
    if repo_slug:
        closers.update(int(n) for slug, n in CLOSING_KEYWORD_URL.findall(scan_text)
                       if slug.lower() == repo_slug.lower())
    trailer = TITLE_TRAILER.search(title)
    if trailer:
        closers.update(int(n) for n in REF_IN_CLAUSE.findall(trailer.group(1)))

    mentions.update(int(n) for n in MENTION.findall(scan_text))
    mentions -= closers
    return sorted(closers), sorted(mentions)


# GH-698 item 2 (LTVera#511 finding 8, 1-INBOX slice): reconcile scans must see the
# whole PROJECT tree — 1-INBOX docs whose issues closed were invisible to a
# 2-WORKING-only scan (12 of 27 offenders in the consuming-repo audit). Order
# matters: the ACTIVE doc wins, so 2-WORKING is searched first.
RECONCILE_FOLDERS = ("2-WORKING", "1-INBOX")


def find_active_doc_for_issue(repo_root, issue_num):
    """Find an issue's doc across the reconciled PROJECT folders (2-WORKING first)."""
    for folder in RECONCILE_FOLDERS:
        working_dir = os.path.join(repo_root, "PROJECT", folder)
        if not os.path.isdir(working_dir):
            continue
        for fname in sorted(os.listdir(working_dir)):
            if not fname.endswith(".md"):
                continue
            # Match GH-123-*.md or 123-*.md
            if re.match(rf"^(?:GH-)?{issue_num}-", fname, re.IGNORECASE):
                return os.path.join(working_dir, fname)
    return None


def parse_doc_frontmatter(doc_path):
    """Parse key-value pairs from document YAML frontmatter."""
    if not doc_path or not os.path.isfile(doc_path):
        return {}
    try:
        with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
        if not lines or lines[0].strip() != "---":
            return {}
        fm = {}
        for line in lines[1:]:
            if line.strip() == "---":
                break
            if ":" in line:
                k, v = line.split(":", 1)
                fm[k.strip().lower()] = v.strip().strip("'\"").lower()
        return fm
    except Exception:
        return {}


def validate_lessons_learned(content, doc_name):
    """Detect a missing or placeholder ## Lessons Learned section (GH-496). Returns the finding or None.

    GH-693: the section is highly recommended, never a promotion gate. Every caller routes the
    finding through warn_lessons_learned() — nothing dies, skips, or exits non-zero on it."""
    m = re.search(r"##\s+Lessons\s+Learned.*?(?=\n##\s+(?!#)|\Z)", content, re.IGNORECASE | re.DOTALL)
    if not m:
        return f"Doc {doc_name} has no '## Lessons Learned (For Future Agents)' section."

    section_text = m.group(0)
    lines = section_text.splitlines()
    body_lines = lines[1:]

    # Strip HTML comments
    clean_body = re.sub(r"<!--.*?-->", "", "\n".join(body_lines), flags=re.DOTALL)

    substantive_lines = []
    for line in clean_body.splitlines():
        trimmed = line.strip()
        if not trimmed:
            continue
        # Check for empty placeholder markers
        if re.match(r"^(?:[-*]\s*)?(?:TODO\b.*|TBD\b.*|None(?:\s+yet)?|N/A|\[.*?\]|\[?\s*\]?)$", trimmed, re.IGNORECASE):
            continue
        substantive_lines.append(trimmed)

    if not substantive_lines:
        return f"Doc {doc_name} has empty/placeholder '## Lessons Learned' section."
    return None


# GH-693: the one advisory emitter. The operator demoted Lessons Learned from a mandatory section
# (enforced since GH-165, tightened in GH-496, skip-and-report since GH-684) to a highly recommended
# one: a reflection field the reconciler cannot evaluate must not block lifecycle writes or red a
# hosted lane (#691). It is said loudly in every log and the promotion proceeds.
WARN_MARKER = "WARN — "


def warn_lessons_learned(content, doc_name):
    finding = validate_lessons_learned(content, doc_name)
    if finding:
        log(f"{WARN_MARKER}{finding} Highly recommended, not required (GH-693) — promotion proceeds.")


def validate_frontmatter_schema(doc_path):
    """Validate YAML frontmatter against required PDDA schema (GH-496)."""
    doc_name = os.path.basename(doc_path)
    if not os.path.isfile(doc_path):
        return f"Doc {doc_name} does not exist."
    try:
        with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
    except Exception as e:
        return f"Cannot read {doc_name}: {e}"

    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return f"Doc {doc_name} missing opening YAML frontmatter delimiter ('---') at line 1."

    closing_idx = -1
    for i, line in enumerate(lines[1:], 1):
        if line.strip() == "---":
            closing_idx = i
            break

    if closing_idx == -1:
        return f"Doc {doc_name} missing closing YAML frontmatter delimiter ('---')."

    fm = {}
    for line in lines[1:closing_idx]:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" in line:
            k, v = line.split(":", 1)
            fm[k.strip().lower()] = v.strip().strip("'\"")

    required_keys = ["title", "status", "created", "updated", "owner", "goal"]
    missing = [k for k in required_keys if not fm.get(k)]
    if missing:
        return f"Doc {doc_name} frontmatter missing required field(s): {', '.join(missing)}"

    date_re = re.compile(r"^\d{4}-\d{2}-\d{2}$")
    for date_key in ("created", "updated"):
        val = fm.get(date_key, "")
        val_date = val.split()[0] if val else ""
        if not date_re.match(val_date):
            return f"Doc {doc_name} frontmatter field '{date_key}' has invalid date format: '{val}' (expected YYYY-MM-DD)."

    return None


def validate_and_update_doc(doc_path, pr_meta, is_merged=True, dry_run=False, journal=None):
    """For merged docs, warn on a missing/placeholder ## Lessons Learned (GH-693); update frontmatter and compute destination path."""
    with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    merged_at = pr_meta.get("mergedAt")
    if merged_at:
        try:
            ship_date = datetime.fromisoformat(merged_at.replace("Z", "+00:00")).strftime(
                "%Y-%m-%d"
            )
        except Exception:
            ship_date = datetime.now().strftime("%Y-%m-%d")
    else:
        ship_date = datetime.now().strftime("%Y-%m-%d")

    if is_merged:
        # Lessons Learned is advisory (GH-693): report, never die.
        warn_lessons_learned(content, os.path.basename(doc_path))

        new_status = "Complete"
        dest_folder = "3-COMPLETED"
    else:
        # Unmerged / declined / closed without merge -> route to 4-MISC
        new_status = "Declined"
        dest_folder = "4-MISC"

    # Update frontmatter status and updated date
    new_content = re.sub(
        r"^status:\s*.*$", f"status: {new_status}", content, flags=re.MULTILINE | re.IGNORECASE
    )
    new_content = re.sub(
        r"^updated:\s*.*$", f"updated: {ship_date}", new_content, flags=re.MULTILINE | re.IGNORECASE
    )

    dest_dir = os.path.join(os.path.dirname(os.path.dirname(doc_path)), dest_folder)
    dest_path = os.path.join(dest_dir, os.path.basename(doc_path))
    print("TRANSITION " + json.dumps(["doc", "move", os.path.basename(doc_path), dest_folder, ship_date]), flush=True)

    if not dry_run:
        if journal:
            journal.snapshot(doc_path)
            # GH-271: a destination that already exists (an earlier reconciliation promoted
            # this doc and was committed) is an overwrite, not a creation — snapshot it too,
            # or rollback's unlink leaves a tracked path deleted in porcelain.
            if os.path.exists(dest_path):
                journal.snapshot(dest_path)
            journal.track_created(dest_path)
        os.makedirs(dest_dir, exist_ok=True)
        with open(dest_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        if doc_path != dest_path:
            os.unlink(doc_path)

    return dest_path, ship_date

def ledger_rows(repo_root, sql, params=()):
    """Read the existing ledger without creating a DB or silently hiding schema errors."""
    db = Path(repo_root) / "releases.db"
    if not db.is_file():
        return []
    # Some legacy adopters carry an empty placeholder; their markdown remains authoritative.
    mode = Path(repo_root, ".pdda-mode")
    releases_mode = mode.is_file() and "ROADMAP_SOURCE=releases" in mode.read_text()
    if db.stat().st_size == 0 and not releases_mode:
        return []
    try:
        conn = sqlite3.connect(db.resolve().as_uri() + "?mode=ro", uri=True)
        try:
            conn.row_factory = sqlite3.Row
            return [dict(row) for row in conn.execute(sql, params)]
        finally:
            conn.close()
    except sqlite3.Error as exc:
        die(f"Cannot read reconciliation ledger: {exc}", code=6)


def ledger_write(repo_root, args, dry_run=False, journal=None):
    # Both paths emit the same stable intent; dry-run never calls a mutating CLI.
    # In particular repoint --dry-run requires a destination that preview has not created.
    print("TRANSITION " + json.dumps(args, ensure_ascii=False), flush=True)
    if dry_run:
        return
    snapshot_ledger_artifacts(repo_root, journal=journal)
    cmd = ["python3", harness_tool(repo_root, "utils/py/releases_app.py"), "--root", repo_root, *args]
    result = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False)
    if result.returncode:
        die(f"{' '.join(args[:2])} failed (exit {result.returncode}): {result.stderr}\n{result.stdout}", code=6)


def manifest_members(repo_root, repo_slug):
    rows = ledger_rows(repo_root, """SELECT r.global_id AS release_gid, i.url
        FROM manifest_items m JOIN releases r ON r.id=m.release_id
        JOIN issue_refs i ON i.id=m.issue_ref_id WHERE m.state='dialed_in'""")
    if rows and not repo_slug:
        die("Cannot resolve repository identity for manifest lookup", code=6)
    members = []
    for row in rows:
        match = re.fullmatch(r"https://github.com/([^/]+/[^/]+)/issues/([1-9][0-9]*)", row["url"] or "")
        if match and match[1].lower() == repo_slug.lower():
            members.append(dict(row, issue=int(match[2])))
    return members


def ship_manifest_items(repo_root, issue_num, pr_meta, repo_slug, dry_run=False, journal=None):
    for member in manifest_members(repo_root, repo_slug):
        if member["issue"] != issue_num:
            continue
        sha = (pr_meta.get("mergeCommit") or {}).get("oid", "")
        if not re.fullmatch(r"[0-9a-fA-F]{40}", sha):
            die(f"PR #{pr_meta.get('number')} has no full merge commit for manifest evidence", code=6)
        ledger_write(repo_root, ["manifest", "ship", "--gid", member["release_gid"],
                     member["url"], "--evidence", sha], dry_run, journal)


def unreconciled_prs(repo_root, repo_slug, metadata):
    """Recover every supported merge from committed receipts, not just closed-issue drift.

    The existing workflow's first introduction is the activation boundary. This is
    deliberately not an arbitrary lookback or a second watermark/ledger.
    """
    shallow = subprocess.check_output(['git', 'rev-parse', '--is-shallow-repository'],
                                      cwd=repo_root, text=True).strip()
    if shallow != 'false':
        die('Merged-PR recovery requires a full, non-shallow clone', code=6)
    dates = subprocess.check_output(
        ['git', 'log', '--follow', '--diff-filter=A', '--format=%cI', '--',
         '.github/workflows/wave-reconcile.yml'], cwd=repo_root, text=True).splitlines()
    if not dates or not repo_slug:
        die('Cannot recover merged PRs without full workflow history and repository identity', code=6)
    try:
        activated = datetime.fromisoformat(dates[-1].replace('Z', '+00:00'))
    except ValueError:
        die('Invalid workflow activation timestamp; restore full Git history', code=6)
    result = subprocess.run(
        ['gh', 'api', '--paginate', '--slurp',
         f'repos/{repo_slug}/pulls?state=closed&base=development&sort=updated&direction=desc&per_page=100'],
        cwd=repo_root, capture_output=True, text=True, check=False)
    if result.returncode:
        die(f'Merged-PR recovery failed: {result.stderr}', code=6)
    previous = committed_qualifications(repo_root)
    pending = []
    try:
        pages = json.loads(result.stdout)
        if not isinstance(pages, list) or any(not isinstance(page, list) for page in pages):
            raise ValueError('expected paginated pull-request arrays')
        for page in pages:
            for pr in page:
                if not isinstance(pr, dict):
                    raise ValueError('invalid pull-request record')
                if ('merged_at' not in pr or not isinstance(pr.get('base'), dict)
                        or not isinstance(pr['base'].get('ref'), str)):
                    raise ValueError('pull request lacks merged_at or base.ref')
                merged = pr['merged_at']
                if merged is not None and not isinstance(merged, str):
                    raise ValueError('invalid merged_at timestamp')
                if merged is None:
                    continue
                if datetime.fromisoformat(merged.replace('Z', '+00:00')) < activated:
                    continue
                if (pr.get('base') or {}).get('ref') != 'development':
                    continue
                if (type(pr.get('number')) is not int or pr['number'] <= 0
                        or not re.fullmatch(r'[0-9a-f]{40}', pr.get('merge_commit_sha') or '')):
                    raise ValueError('merged PR has no exact landing identity')
                meta = dict(number=pr['number'], title=pr.get('title') or '', body=pr.get('body') or '',
                            state='MERGED', mergedAt=merged, baseRefName='development',
                            mergeCommit={'oid':pr['merge_commit_sha']}, url=pr.get('html_url') or '',
                            headRefOid=(pr.get('head') or {}).get('sha'), commits=[])
                key = ('pr', str(pr['number']))
                metadata[key] = meta  # Reuse the batch response; no per-PR metadata query.
                if not any(qualification_receipt_matches(repo_root, entry, meta) for entry in previous):
                    pending.append(str(pr['number']))
    except (ValueError, TypeError, AttributeError) as exc:
        die(f'Malformed merged-PR recovery response: {exc}', code=6)
    log(f'Receipt recovery found {len(pending)} pending PR(s) since workflow activation {activated.isoformat()}')
    return pending


def catch_up_prs(repo_root, repo_slug, offline_manifest=None, qualification_metadata=None):
    """Derive drift from committed state; no PR watermark or auxiliary ledger.

    Timeline pagination recovers closing PRs even outside an arbitrary recent-PR window.
    Only merged development PRs whose closers match the closed issue qualify.
    """
    issues = {m["issue"] for m in manifest_members(repo_root, repo_slug)}
    # Roadmap-only drift survives when a doc was archived or a manifest already shipped.
    # Terminal rows must drop out again so successful catch-up remains idempotent.
    for row in ledger_rows(repo_root,
            "SELECT gh_number, issue_url FROM roadmap_items WHERE gh_number IS NOT NULL "
            "AND section NOT IN (?, ?)", ("Completed", "Deferred · vision")):
        expected = f"https://github.com/{repo_slug}/issues/{row['gh_number']}"
        if repo_slug and (row["issue_url"] or "").lower() == expected.lower():
            issues.add(row["gh_number"])
    for folder in RECONCILE_FOLDERS:
        for path in Path(repo_root, "PROJECT", folder).glob("GH-*.md"):
            match = re.match(r"GH-([0-9]+)-", path.name)
            if match:
                issues.add(int(match[1]))
    found = set(unreconciled_prs(repo_root, repo_slug, qualification_metadata)) if qualification_metadata is not None else set()
    for issue in sorted(issues):
        if fetch_issue_state(repo_root, issue, offline_manifest) != "CLOSED":
            continue
        if offline_manifest is not None:
            candidates = offline_manifest.get("prs", [])
        else:
            result = subprocess.run(["gh", "api", "--paginate", "--slurp",
                f"repos/{repo_slug}/issues/{issue}/timeline?per_page=100"],
                cwd=repo_root, capture_output=True, text=True, check=False)
            if result.returncode:
                die(f"Catch-up timeline for GH-{issue} failed: {result.stderr}", code=6)
            numbers = set()
            for page in json.loads(result.stdout):
                for event in page:
                    referenced = (event.get("source") or {}).get("issue") or {}
                    if referenced.get("pull_request") and referenced.get("repository_url", "").lower() == (
                        f"https://api.github.com/repos/{repo_slug}".lower()):
                        numbers.add(referenced["number"])
            candidates = [(qualification_metadata or {}).get(("pr", str(n))) or fetch_pr_metadata(repo_root, n)
                          for n in sorted(numbers)]
        if qualification_metadata is not None:
            for pr in candidates:
                qualification_metadata[("pr", str(pr["number"]))] = pr
        matches = [pr for pr in candidates if pr.get("state", "").upper() == "MERGED"
                   and pr.get("baseRefName") == "development"
                   and issue in extract_linked_issues(pr, repo_slug)[0]]
        if not matches:
            log(f"WARNING — Closed GH-{issue} has reconciliation drift but no attributable merged development PR; "
                "leaving this legacy row unchanged and continuing (GH-584; non-PR closure tracked by GH-492)")
            continue
        # The most recent closing PR owns the current lifecycle transition.
        found.add(str(max(matches, key=lambda pr: (pr.get("mergedAt") or "", pr["number"]))["number"]))
    if qualification_metadata is not None:
        return sorted(found, key=lambda n: (qualification_metadata.get(("pr", n), {}).get("mergedAt") or "", int(n)))
    return sorted(found, key=int)


def update_roadmap_entry(repo_root, issue_num, landing, ship_date, is_merged=True, dry_run=False, journal=None, doc_path=None):
    """Move entry in ROADMAP.md and/or releases.db to Completed/Deferred section with shipping badge."""
    roadmap_path = os.path.join(repo_root, "ROADMAP.md")
    db_path = os.path.join(repo_root, "releases.db")
    target_section_md = "### Completed" if is_merged else "### Deferred / cancelled"
    target_section_db = "Completed" if is_merged else "Deferred · vision"
    badge_sub = f"✅ **SHIPPED {ship_date} ({landing})**" if is_merged else f"🛑 **DECLINED {ship_date} ({landing})**"

    updated = False

    # GH-421: read desired state first; every write uses the existing receipt-backed CLI.
    if os.path.isfile(db_path):
        rows = ledger_rows(repo_root, "SELECT * FROM roadmap_items WHERE gh_number = ?", (issue_num,))
        if rows:
            row = rows[0]
            raw_text = row["raw_text"] or ""
            title_match = re.search(r"^-\s+\*\*([^*]+)\*\*", raw_text)
            title_part = title_match.group(1).strip() if title_match else f"GH-{issue_num} · {row['title']}"
            rest = raw_text.split("—", 1)[1] if "—" in raw_text else " " + (
                raw_text[title_match.end():].strip() if title_match else raw_text)
            if doc_path and row["doc_path"]:
                rest = rest.replace(row["doc_path"], doc_path)
            new_raw_text = f"- **{title_part}** {badge_sub} —{rest}".strip()
            marker = "✅" if is_merged else "⛔"
            if doc_path and row["doc_path"] != doc_path:
                ledger_write(repo_root, ["roadmap", "repoint", "--issue-num", str(issue_num),
                             "--doc-path", doc_path], dry_run, journal)
            if (row["section"], row["status_marker"], raw_text) != (target_section_db, marker, new_raw_text):
                ledger_write(repo_root, ["roadmap", "update", "--issue-num", str(issue_num),
                             "--section", target_section_db, "--status-marker", marker,
                             "--raw-text", new_raw_text], dry_run, journal)
            updated = True

    # 2. Update ROADMAP.md if present (legacy mode)
    if os.path.isfile(roadmap_path):
        with open(roadmap_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()

        entry_pattern = re.compile(rf"^-\s+\*\*GH-{issue_num}\b")
        starts = [i for i, line in enumerate(lines) if entry_pattern.search(line)]
        if not starts:
            log(f"No entry found in ROADMAP.md for GH-{issue_num} (skipping roadmap move)")
            return updated

        blocks = []
        for start_idx in starts:
            end_idx = len(lines)
            for j in range(start_idx + 1, len(lines)):
                if lines[j].startswith("- **") or lines[j].startswith("### ") or lines[j].startswith("## "):
                    end_idx = j
                    break
            blocks.append((start_idx, end_idx, lines[start_idx:end_idx]))

        expected_marker = "SHIPPED" if is_merged else "DECLINED"
        canonical = next(
            (block for _, _, block in blocks if expected_marker in block[0]),
            blocks[0][2],
        )
        block_lines = list(canonical)
        first_line = block_lines[0]

        if len(blocks) == 1 and expected_marker in first_line:
            log(f"GH-{issue_num} is already marked {expected_marker} in ROADMAP.md")
            return True

        title_match = re.search(r"^-\s+\*\*([^*]+)\*\*", first_line)
        title_part = title_match.group(1).strip() if title_match else f"GH-{issue_num}"

        if "—" in first_line:
            rest = first_line.split("—", 1)[1]
        else:
            after_title = first_line[title_match.end():] if title_match else first_line
            rest = re.sub(r"^(?:\s*✅\s*(?:\*\*.*?\*\*)?|\s*🚧\s*(?:\*\*.*?\*\*)?|\s*🛑\s*(?:\*\*.*?\*\*)?|\s*)", "", after_title)
            if not rest.startswith(" ") and rest != "\n" and rest != "":
                rest = " " + rest
            if not rest.endswith("\n"):
                rest += "\n"

        new_first_line = f"- **{title_part}** {badge_sub} —{rest}"
        block_lines[0] = new_first_line

        removed = set()
        for start_idx, end_idx, _ in blocks:
            removed.update(range(start_idx, end_idx))
        new_lines = [line for idx, line in enumerate(lines) if idx not in removed]

        target_idx = None
        for k, line in enumerate(new_lines):
            if line.strip() == target_section_md:
                target_idx = k
                break

        if target_idx is None and not is_merged:
            target_section_md = "### Completed"
            for k, line in enumerate(new_lines):
                if line.strip() == target_section_md:
                    target_idx = k
                    break

        if target_idx is None:
            die(f"Could not find '{target_section_md}' section in ROADMAP.md", code=5)

        insert_pos = target_idx + 1
        new_lines = new_lines[:insert_pos] + block_lines + new_lines[insert_pos:]

        if not dry_run:
            if journal:
                journal.snapshot(roadmap_path)
            with open(roadmap_path, "w", encoding="utf-8") as f:
                f.writelines(new_lines)

        updated = True

    return updated


def fix_mangled_roadmap_entries(repo_root, dry_run=False, journal=None):
    roadmap_path = os.path.join(repo_root, "ROADMAP.md")
    if not os.path.isfile(roadmap_path):
        return
    with open(roadmap_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    changed = False
    for i, line in enumerate(lines):
        if line.startswith("- **") and " ** " in line:
            new_line = re.sub(r"^-\s+\*\*(GH-\d+)\s+\*\*", r"- **\1**", line)
            if new_line != line:
                lines[i] = new_line
                changed = True
    if changed and not dry_run:
        if journal:
            journal.snapshot(roadmap_path)
        with open(roadmap_path, "w", encoding="utf-8") as f:
            f.writelines(lines)


def marathon_plan_findings(output, returncode):
    """Return exit-driving structured findings emitted by marathon-plan."""
    drift_types = {"already-landed", "already-closed"}
    held_types = {
        "unrated", "needs-doc", "needs-contract", "note-only",
        "not-ready", "blocked", "blocked-dep",
    }
    relevant_types = drift_types if returncode == 4 else held_types
    findings = []
    for line in output.splitlines():
        try:
            finding = json.loads(line)
        except (json.JSONDecodeError, TypeError):
            continue
        check = str(finding.get("check", ""))
        finding_type = check.split("/", 1)[1] if "/" in check else check
        if finding_type in relevant_types:
            findings.append(finding)
    return findings


def finding_issue_numbers(finding):
    """Extract issue identities from a planner finding without guessing by title."""
    file_name = str(finding.get("file", ""))
    evidence = " ".join(str(finding.get(key, "")) for key in ("file", "message", "action"))
    numbers = {
        int(number)
        for number in re.findall(r"(?:GH-|issue\s+#|#)([0-9]{1,6})\b", evidence, re.IGNORECASE)
    }
    # Active-doc lookup also supports the legacy `123-title.md` filename shape.
    legacy_doc = re.match(r"^(?:GH-)?([0-9]{1,6})(?:[^0-9]|$)", os.path.basename(file_name), re.IGNORECASE)
    if legacy_doc:
        numbers.add(int(legacy_doc.group(1)))
    return numbers


def describe_finding(finding):
    """Produce a stable, operator-readable held-item label."""
    issue_nums = sorted(finding_issue_numbers(finding))
    file_name = str(finding.get("file", "")).strip()
    identity = ", ".join(f"GH-{number}" for number in issue_nums)
    if identity and file_name:
        return f"{identity} ({file_name})"
    if identity:
        return identity
    if file_name:
        return file_name
    return str(finding.get("message", "")).strip() or "unidentified planner item"


def handle_marathon_plan_result(result, reconciled_issues):
    """Scope planner drift/held failures to the issues reconciled in this run."""
    if result.returncode == 0:
        return
    if result.returncode not in (4, 5):
        die(
            f"Subprocess 'marathon-plan.sh' failed with exit {result.returncode}:\n"
            f"{result.stderr}\n{result.stdout}",
            code=6,
        )

    findings = marathon_plan_findings(result.stdout, result.returncode)
    if not findings:
        # Preserve GH-202 compatibility with older/stub planners that expose only
        # the exit-5 contract. Exit 4 must remain attributable and therefore
        # fails closed when structured evidence is absent.
        if result.returncode == 5:
            log("  marathon-plan reports items held (exit 5) without structured findings — continuing (GH-202 compatibility)")
            return
        die("marathon-plan reported drift (exit 4) without attributable structured findings", code=6)

    reconciled = {int(issue) for issue in reconciled_issues}
    owned = [
        finding for finding in findings
        if finding_issue_numbers(finding) & reconciled
    ]
    unrelated = [finding for finding in findings if finding not in owned]

    if owned:
        labels = ", ".join(describe_finding(finding) for finding in owned)
        die(
            "marathon-plan found drift/held state attributable to the reconciled "
            f"PR item(s): {labels}",
            code=6,
        )

    log("  WARNING — marathon-plan found pre-existing unrelated drift/held items; keeping reconciliation:")
    for finding in unrelated:
        log(f"    - {describe_finding(finding)}")


def snapshot_ledger_artifacts(repo_root, dry_run=False, journal=None):
    """GH-424: capture the ledger and generated views BEFORE the first write.

    Repeated calls retain the original state, including originally absent artifacts.
    Both per-issue writes and downstream regeneration use this same snapshot set.
    """
    if dry_run or journal is None:
        return
    for name in (
        "releases.db", "releases.sql",
        "RELEASES-PREVIEW.html",
        "LEADERBOARD.html", "LEADERBOARD.md",
        os.path.join(".tick", "marathon-plan.fingerprint"),
    ):
        path = os.path.abspath(os.path.join(repo_root, name))
        if path in journal.backups or path in journal.created_files:
            continue
        if os.path.exists(path):
            journal.snapshot(path)
        else:
            journal.track_created(path)


def compute_marathon_planner_fingerprint(repo_root):
    """Compute a SHA256 digest of canonical marathon inputs to avoid redundant replanning (GH-496)."""
    h = hashlib.sha256()
    db_path = os.path.join(repo_root, "releases.db")
    if os.path.isfile(db_path):
        try:
            conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
            cur = conn.cursor()
            cur.execute("SELECT global_id, gh_number, title, section, position, complexity, risk, effort FROM roadmap_items ORDER BY global_id")
            for row in cur.fetchall():
                h.update(str(row).encode("utf-8"))
            conn.close()
        except Exception:
            pass

    working_dir = os.path.join(repo_root, "PROJECT", "2-WORKING")
    if os.path.isdir(working_dir):
        for fname in sorted(os.listdir(working_dir)):
            if fname.endswith(".md") and not fname.startswith("MARATHON-PLAN-"):
                h.update(fname.encode("utf-8"))
                fpath = os.path.join(working_dir, fname)
                try:
                    with open(fpath, "rb") as f:
                        h.update(f.read())
                except Exception:
                    pass

    planner_src = harness_tool(repo_root, "utils/py/marathon_plan.py")
    if os.path.isfile(planner_src):
        try:
            with open(planner_src, "rb") as f:
                h.update(f.read())
        except Exception:
            pass
    return h.hexdigest()


def run_subprocesses(repo_root, dry_run=False, journal=None, reconciled_issues=None):
    """Orchestrate releases sync, view exports, and marathon replanning with DB rollback protection."""
    log("Running downstream database sync and dashboard regeneration...")

    snapshot_ledger_artifacts(repo_root, dry_run=dry_run, journal=journal)

    def _plan_docs():
        found = set()
        for pattern in ("MARATHON-PLAN-*.md", os.path.join("PROJECT", "2-WORKING", "MARATHON-PLAN-*.md")):
            found.update(glob.glob(os.path.join(repo_root, pattern)))
        return found

    pre_plan_docs = _plan_docs() if not dry_run else set()
    if journal and not dry_run:
        # Codex consult: a same-dated plan doc that already exists gets OVERWRITTEN by the
        # replan, and tracking-only-created would leave rollback no bytes to restore.
        for existing_doc in pre_plan_docs:
            journal.snapshot(existing_doc)

    # GH-358: resolve each harness tool against the repo first, then the harness home. On a
    # vendored install these five live only under <repo>/.xyz/ and every one was unreachable,
    # so the reconciler died on its first downstream step.
    releases_app = harness_tool(repo_root, "utils/py/releases_app.py")
    sync_cmd = ["python3", releases_app, "--root", repo_root, "roadmap", "sync"]
    check_cmd = ["python3", releases_app, "--root", repo_root, "check"]
    timeline_cmd = ["python3", harness_tool(repo_root, "utils/timeline/export_timeline.py"), "--preview"]
    lb_cmd = ["bash", harness_tool(repo_root, "utils/leaderboard.sh")]
    plan_cmd = ["bash", harness_tool(repo_root, "utils/marathon-plan.sh"), "--format", "json"]

    if dry_run:
        sync_cmd.append("--dry-run")
        plan_cmd.append("--dry-run")

    steps = [
        ("releases roadmap sync", sync_cmd),
        ("releases check", check_cmd),
    ]
    skip_marathon = False
    fp_dir = os.path.join(repo_root, ".tick")
    fp_file = os.path.join(fp_dir, "marathon-plan.fingerprint")
    plan_fp = compute_marathon_planner_fingerprint(repo_root)

    if not dry_run:
        # GH-474: RELEASES-PREVIEW.html is an ADOPTED view — opt-in by presence.
        if os.path.exists(os.path.join(repo_root, "RELEASES-PREVIEW.html")):
            steps.append(("export_timeline.py --preview", timeline_cmd))
        else:
            log("  (skipping export_timeline.py --preview — RELEASES-PREVIEW.html is not adopted here)")
        if os.path.exists(os.path.join(repo_root, "LEADERBOARD.md")):
            if os.path.exists(harness_tool(repo_root, "utils/leaderboard.sh")):
                steps.append(("leaderboard.sh", lb_cmd))
            else:
                log("  (skipping leaderboard.sh — utils/leaderboard.sh not found)")
        else:
            log("  (skipping leaderboard.sh — LEADERBOARD.md is not adopted here)")

        has_plan = bool(glob.glob(os.path.join(repo_root, "PROJECT", "2-WORKING", "MARATHON-PLAN-*.md"))) or bool(glob.glob(os.path.join(repo_root, "MARATHON-PLAN-*.md")))
        if has_plan and os.path.isfile(fp_file):
            try:
                with open(fp_file, "r") as f:
                    if f.read().strip() == plan_fp:
                        skip_marathon = True
            except Exception:
                pass

        if skip_marathon:
            log("  (skipping marathon-plan.sh — canonical inputs unchanged)")
        else:
            steps.append(("marathon-plan.sh", plan_cmd))
    else:
        steps.append(("marathon-plan.sh --dry-run", plan_cmd))

    # GH-271: registration of created views/plan docs must happen even when a step DIES —
    # the marathon-plan failure path raises from inside the loop, and a post-loop pass
    # would never run, which is exactly how the stray MARATHON-PLAN escaped rollback.
    try:
        for name, cmd in steps:
            log(f"  -> {name}")
            # GH-429 / GH-496: dashboard and leaderboard paths
            step_env = dict(
                os.environ,
                ROADMAP_DASHBOARD_ROOT=str(repo_root),
                LEADERBOARD_DB=str(os.path.join(repo_root, "releases.db")),
                LEADERBOARD_OUTPUT=str(os.path.join(repo_root, "LEADERBOARD.md")),
            )
            r = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False, env=step_env)
            if name.startswith("marathon-plan"):
                handle_marathon_plan_result(r, reconciled_issues or set())
            elif r.returncode != 0:
                die(f"Subprocess '{name}' failed with exit {r.returncode}:\n{r.stderr}\n{r.stdout}", code=6)

        if not dry_run and not skip_marathon:
            try:
                os.makedirs(fp_dir, exist_ok=True)
                with open(fp_file, "w") as f:
                    f.write(plan_fp)
            except Exception:
                pass
    finally:
        if journal and not dry_run:
            for plan_doc in _plan_docs() - pre_plan_docs:
                journal.track_created(plan_doc)


def run_validation_gate(repo_root):
    """Run pdda doc-health verification gate."""
    log("Running PDDA doc-hygiene gate...")
    gate_cmd = ["bash", "utils/pdda-local-checks.sh"] if os.path.exists(os.path.join(repo_root, "utils", "pdda-local-checks.sh")) else ["bash", "utils/pdda/pdda.sh"]
    r = subprocess.run(
        gate_cmd,
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    # GH-429: the exit status IS the consuming repo's enforcement decision — pdda-lib.sh makes
    # `observe`/`light` exit 0 and `full` exit non-zero on errors. Grepping stdout for ERROR
    # overrode that mode and made a live reconciliation impossible on any repo with a standing
    # observe-mode backlog. Block on the status; surface the findings when it reports but passes.
    if r.returncode != 0:
        die(f"PDDA validation gate failed:\n{r.stdout}", code=7)
    if "ERROR" in r.stdout:
        found = re.search(r"(\d+) error\(s\) found", r.stdout)
        count = found.group(1) if found else "some"
        log(f"  WARNING — pdda reported {count} finding(s) but exited 0 (repo enforcement mode is not blocking); continuing")


def run_pre_merge(repo_root, args):
    """Execute pre-merge validation checks for PR or current branch (GH-496)."""
    log("Running pre-merge closeout checks...")
    try:
        head_sha = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=repo_root, text=True
        ).strip()
    except Exception as e:
        die(f"Cannot determine HEAD SHA: {e}", code=2)

    pr_num = None
    pr_title = ""
    pr_body = ""
    if args.pr:
        pr_num = args.pr[0]
        try:
            r = subprocess.run(
                ["gh", "pr", "view", str(pr_num), "--json", "number,title,body,headRefOid"],
                cwd=repo_root,
                capture_output=True,
                text=True,
                timeout=10,
            )
            if r.returncode == 0:
                data = json.loads(r.stdout)
                pr_title = data.get("title", "")
                pr_body = data.get("body", "")
                head_sha = data.get("headRefOid") or head_sha
            elif not args.offline:
                die(f"Failed to query PR #{pr_num} via gh pr view (exit {r.returncode}): {r.stderr.strip()}", code=2)
        except ReconcileError:
            raise
        except Exception as e:
            if not args.offline:
                die(f"Cannot query PR #{pr_num} metadata: {e}", code=2)

    if not pr_title and not pr_body:
        try:
            commits_text = subprocess.check_output(
                ["git", "log", "-n", "10", "--format=%B"],
                cwd=repo_root,
                text=True,
            )
            pr_title = commits_text.splitlines()[0] if commits_text else ""
            pr_body = commits_text
        except Exception:
            pass

    repo_slug = github_slug_from_origin(repo_root)
    closers, mentions = extract_linked_issues({"title": pr_title, "body": pr_body}, repo_slug=repo_slug)
    log(f"  Target: {('PR #' + str(pr_num)) if pr_num else head_sha[:10]}")
    log(f"  Closing issues detected: {closers or '(none)'}")

    diff_docs = []
    try:
        base_ref = "origin/development"
        try:
            mb = subprocess.check_output(
                ["git", "merge-base", "HEAD", base_ref],
                cwd=repo_root,
                text=True,
                stderr=subprocess.DEVNULL,
            ).strip()
            diff_range = f"{mb}..HEAD" if mb else "HEAD~1..HEAD"
        except Exception:
            diff_range = "HEAD~1..HEAD"

        diff_status = subprocess.check_output(
            ["git", "diff", "--name-status", diff_range],
            cwd=repo_root,
            text=True,
            stderr=subprocess.DEVNULL,
        ).splitlines()
        for dline in diff_status:
            parts = dline.split()
            if len(parts) >= 2:
                for p in parts[1:]:
                    if "PROJECT/2-WORKING/" in p and p.endswith(".md"):
                        fname = os.path.basename(p)
                        if not fname.startswith("recon-") and not fname.startswith("MARATHON-PLAN-"):
                            diff_docs.append(os.path.join(repo_root, p))
    except Exception:
        pass

    target_docs = set()
    errors = []

    for issue_num in closers:
        working_dir = os.path.join(repo_root, "PROJECT", "2-WORKING")
        matches = []
        if os.path.isdir(working_dir):
            for fname in sorted(os.listdir(working_dir)):
                if fname.endswith(".md") and re.match(rf"^(?:GH-)?{issue_num}-", fname, re.IGNORECASE):
                    matches.append(os.path.join(working_dir, fname))
        if len(matches) > 1:
            errors.append(f"Ambiguous active doc match for issue #{issue_num}: {', '.join(os.path.basename(m) for m in matches)}")
        elif len(matches) == 1:
            target_docs.add(matches[0])
        else:
            completed_dir = os.path.join(repo_root, "PROJECT", "3-COMPLETED")
            comp_matches = [
                os.path.join(completed_dir, f)
                for f in sorted(os.listdir(completed_dir))
                if f.endswith(".md") and re.match(rf"^(?:GH-)?{issue_num}-", f, re.IGNORECASE)
            ] if os.path.isdir(completed_dir) else []
            if comp_matches:
                target_docs.add(comp_matches[0])

    for d in diff_docs:
        if os.path.isfile(d):
            target_docs.add(d)

    log(f"  Active docs evaluated: {[os.path.basename(d) for d in sorted(target_docs)] or '(none)'}")

    doc_contract_failed = False
    for doc_path in sorted(target_docs):
        doc_name = os.path.basename(doc_path)
        if doc_name.startswith("recon-") or doc_name.startswith("MARATHON-PLAN-"):
            continue
        try:
            with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
        except Exception as e:
            errors.append(f"Cannot read {doc_name}: {e}")
            doc_contract_failed = True
            continue

        if "roadmap_exempt: true" in content or "doc_type: research" in content:
            continue

        # 1. Frontmatter
        fm_err = validate_frontmatter_schema(doc_path)
        if fm_err:
            errors.append(fm_err)
            doc_contract_failed = True

        # 2. Lessons Learned — advisory (GH-693); frontmatter above stays the doc contract.
        warn_lessons_learned(content, doc_name)

    # 3. Test receipts
    receipt_err = validate_pre_merge_receipts(repo_root, head_sha, pr_num)
    if receipt_err:
        errors.append(receipt_err)

    if errors:
        log_err("Pre-merge validation FAILED with the following error(s):")
        for e in errors:
            log_err(f"  - {e}")
        exit_code = 5 if doc_contract_failed else 6
        sys.exit(exit_code)

    log("Pre-merge validation PASSED! ✅")
    sys.exit(0)


def main():
    parser = argparse.ArgumentParser(
        description="wave_reconcile.py — Canonical Post-Merge Wave & Marathon Lifecycle Reconciler"
    )
    parser.add_argument(
        "--root",
        help="Target repository root path (default: current working directory)",
    )
    parser.add_argument(
        "--pr",
        nargs="+",
        help="One or more merged PR numbers/IDs to reconcile",
    )
    parser.add_argument(
        "--commit",
        nargs="+",
        help="One or more commits landed directly on development to reconcile",
    )
    parser.add_argument(
        "--marathon",
        help="Marathon identifier / milestone name",
    )
    parser.add_argument(
        "--manifest",
        help="Path to structured JSON reconciliation manifest",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Hermetic preview: assert zero file/DB/ref mutations",
    )
    parser.add_argument(
        "--offline",
        help="Run without network using offline JSON manifest cache",
    )
    parser.add_argument(
        "--skip-pull",
        action="store_true",
        help="Skip git pull --ff-only origin development (for testing/isolated clones)",
    )
    parser.add_argument(
        "--skip-branch-check",
        action="store_true",
        help="Skip active branch check (for tests on feature branches)",
    )
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Allow dirty working tree (for test fixtures only)",
    )
    parser.add_argument(
        "--force-promote",
        action="store_true",
        help="Force promotion of active docs and roadmap entries to Completed regardless of linked issue OPEN state",
    )
    parser.add_argument(
        "--gate",
        "--require-receipts",
        action="store_true",
        dest="require_receipts",
        help="Require a receipt matching each PR number or exact merge commit before closeout (GH-425)",
    )
    parser.add_argument(
        "--pre-merge",
        action="store_true",
        help="Run read-only pre-merge checks on closing active docs (frontmatter, lessons learned, test receipts) (GH-496)",
    )
    parser.add_argument(
        "--force-local-reconcile",
        action="store_true",
        help="Bypass hosted in-flight reconciler check for emergency local reconciliation (GH-496)",
    )

    parser.add_argument("--qualify", action="store_true",
                        help="Run the full sequential suite and retain integration evidence before gated closeout")
    parser.add_argument("--catch-up", action="store_true", help="Recover closed-issue drift from committed docs and manifest")
    parser.add_argument("--only-receipted", action="store_true",
                        help="GH-740 publish retry: never run the suite — process only landings that already have a "
                             "committed, matching qualification receipt; defer recovered ones that do not (their own "
                             "run qualifies them); an explicit --pr/--commit without a receipt fails closed. "
                             "Requires --catch-up --qualify.")

    args = parser.parse_args()
    if args.qualify and (not args.require_receipts or args.dry_run or args.offline or args.allow_dirty or args.pre_merge):
        parser.error("--qualify requires --gate and a live, clean, non-preview post-merge checkout")
    if args.only_receipted and not (args.catch_up and args.qualify):
        parser.error("--only-receipted requires --catch-up --qualify (it is the hosted publish step's bounded retry)")

    repo_root = os.path.abspath(args.root) if args.root else resolve_repo_root()

    if args.pre_merge:
        try:
            run_pre_merge(repo_root, args)
        except ReconcileError as re_err:
            sys.exit(re_err.code)
        return

    lock_file = os.path.join(repo_root, ".git", "wave-reconcile.lock")
    journal = RollbackJournal(repo_root=repo_root)
    baseline = None

    try:
        if args.force_local_reconcile and os.environ.get("GITHUB_ACTIONS") == "true":
            die("--force-local-reconcile is prohibited inside GITHUB_ACTIONS", code=2)

        # Preflight phase
        log(f"Starting wave reconciliation (dry_run={args.dry_run}, root={repo_root})")
        baseline = check_porcelain_cleanliness(repo_root, allow_dirty=(args.allow_dirty or args.dry_run))
        check_current_branch(repo_root, skip_branch_check=args.skip_branch_check)

        repo_slug = github_slug_from_origin(repo_root)
        has_workflow = os.path.isfile(os.path.join(repo_root, ".github", "workflows", "wave-reconcile.yml"))
        if not args.offline and not args.dry_run and os.environ.get("GITHUB_ACTIONS") != "true":
            if repo_slug and has_workflow:
                check_hosted_reconciler_in_flight(repo_root, repo_slug=repo_slug, force=args.force_local_reconcile)

        if not args.skip_pull and not args.dry_run and not args.offline:
            pull_upstream(repo_root)

        offline_manifest = None
        if args.offline:
            try:
                with open(args.offline, "r", encoding="utf-8") as f:
                    offline_manifest = json.load(f)
            except Exception as e:
                die(f"Failed loading offline manifest from {args.offline}: {e}", code=4)

        landing_items = [("pr", value) for value in (args.pr or [])]
        landing_items.extend(("commit", value) for value in (args.commit or []))
        if args.manifest:
            try:
                with open(args.manifest, "r", encoding="utf-8") as f:
                    mdata = json.load(f)
                    landing_items.extend(("pr", str(p)) for p in mdata.get("prs", []))
            except Exception as e:
                die(f"Failed loading manifest from {args.manifest}: {e}", code=4)

        if not landing_items and not args.marathon and not args.catch_up:
            die("No PRs, commits, or marathon specified. Pass --pr <N>..., --commit <SHA>..., --marathon <name>, or --catch-up", code=2)

        with ReconcilerLock(lock_file):
            reconciled_issues = set()
            repo_slug = github_slug_from_origin(repo_root)  # GH-429: URL-form closers, this repo only
            metadata = {}
            # GH-684: landings named on the command line (or manifest) fail closed as before; only the
            # ones --catch-up recovers may be skipped-and-reported when their doc is defective.
            explicit_items = {(kind, str(value)) for kind, value in landing_items}
            skipped_issues = set()
            if args.catch_up:
                landing_items.extend(("pr", str(n)) for n in catch_up_prs(
                    repo_root, repo_slug, offline_manifest, qualification_metadata=metadata if args.qualify else None))
            landing_items = list(dict.fromkeys((kind, str(value)) for kind, value in landing_items))
            if args.qualify and landing_items:
                for kind, value in landing_items:
                    if (kind, value) not in metadata:
                        metadata[(kind, value)] = (fetch_commit_metadata(repo_root, value) if kind == "commit"
                                                  else fetch_pr_metadata(repo_root, value))
                if args.only_receipted:
                    # GH-740: the publish step's retry after a raced push. The receipts it just published
                    # are on HEAD, so this run's landings match; anything else (the racer) is deferred to
                    # its own queued run rather than qualified here. Same matcher as the qualifier.
                    # `metadata` keeps every closer so the newest-owner rule below is unchanged.
                    previous = committed_qualifications(repo_root)
                    kept = []
                    for item in landing_items:
                        if any(qualification_receipt_matches(repo_root, entry, metadata[item]) for entry in previous):
                            kept.append(item)
                        elif item in explicit_items:
                            die(f"--only-receipted refuses explicit {landing_label(metadata[item])}: "
                                "no committed qualification receipt", code=6)
                        else:
                            log(f"deferred {landing_label(metadata[item])} — no committed qualification receipt; "
                                "its own run qualifies it")
                    landing_items = kept
                else:
                    qualify_landings(repo_root, [metadata[item] for item in landing_items], journal)
            # A recovered batch can contain several closing PRs for one issue.
            # Qualify every landing, but let its newest known closer own all lifecycle
            # writes, including when that closer already has a committed receipt.
            issue_owners = {}
            if args.catch_up and args.qualify:
                for key, meta in metadata.items():
                    if meta.get('state') != 'MERGED' or meta.get('baseRefName') != 'development':
                        continue
                    rank = (meta.get('mergedAt') or '', str(meta['number']))
                    for issue in extract_linked_issues(meta, repo_slug)[0]:
                        if issue not in issue_owners or rank > issue_owners[issue][0]:
                            issue_owners[issue] = (rank, key)
            for landing_kind, landing_id in landing_items:
                if (landing_kind, landing_id) in metadata:
                    pr_meta = metadata[(landing_kind, landing_id)]
                elif landing_kind == "commit":
                    pr_meta = fetch_commit_metadata(repo_root, landing_id, offline_manifest)
                else:
                    pr_meta = fetch_pr_metadata(repo_root, landing_id, offline_manifest, dry_run=args.dry_run)
                landing = landing_label(pr_meta)
                log(f"Processing {landing}...")
                state = pr_meta.get("state", "").upper()
                is_merged = (state == "MERGED")

                if not is_merged:
                    log(f"  {landing} state is '{state}' (unmerged/declined) -> routing to 4-MISC/")

                base_ref = pr_meta.get("baseRefName", "")
                if base_ref and base_ref != "development":
                    die(
                        f"{landing} target base is '{base_ref}', not 'development'.",
                        code=4,
                    )

                linked_issues, mentioned_issues = extract_linked_issues(pr_meta, repo_slug=repo_slug)
                # GH-425: unconditional whenever --gate/--require-receipts is requested — this
                # attributes evidence to the PR itself, not to whichever issue it happens to
                # close. Narrowing this to "only if the PR closes/references a tracked issue"
                # (introduced in GH-421's build) silently drops the guarantee for exactly the
                # PRs least likely to be scrutinized: ones with no linked issue at all.
                if args.require_receipts:
                    check_provenance_receipts(repo_root, pr_meta)
                reconciled_issues.update(linked_issues)
                log(f"  {landing} closes {linked_issues}; references {mentioned_issues}")
                # GH-271: mentions never act on their own. --force-promote is the one
                # explicit operator override that widens the action set past closers.
                action_issues = (
                    sorted(set(linked_issues) | set(mentioned_issues))
                    if args.force_promote
                    else linked_issues
                )

                for issue_num in action_issues:
                    owner = issue_owners.get(issue_num)
                    if owner and owner[1] != (landing_kind, landing_id):
                        log(f"  GH-{issue_num} lifecycle belongs to newer PR #{owner[1][1]}; retaining this landing's qualification")
                        continue
                    doc_path = find_active_doc_for_issue(repo_root, issue_num)
                    issue_state = fetch_issue_state(repo_root, issue_num, offline_manifest)
                    fm = parse_doc_frontmatter(doc_path) if doc_path else {}
                    is_multiphase = (
                        fm.get("umbrella") in ("true", "1", "yes")
                        or fm.get("multiphase") in ("true", "1", "yes")
                        or fm.get("multi_phase") in ("true", "1", "yes")
                    )

                    is_open = (issue_state == "OPEN") or (issue_state is None and is_multiphase)

                    if doc_path and is_open and is_merged and not args.force_promote:
                        # GH-202/GH-232: a merged PR does not complete an open issue or multi-phase umbrella.
                        # Phased umbrellas and open issues keep their active doc; evidence recorded in place.
                        log(f"  Issue #{issue_num} is OPEN — keeping {os.path.basename(doc_path)} active; recording merge evidence")
                        record_merge_evidence(doc_path, pr_meta, dry_run=args.dry_run, journal=journal)
                        log(f"  Issue #{issue_num} is OPEN — preserving active ROADMAP.md entry (skipping move to Completed)")
                    elif doc_path:
                        # GH-684 kept the shape "a defective BACKLOG doc stops only itself" (log
                        # `SKIP_MARKER`, discard from reconciled_issues, add to skipped_issues,
                        # continue) for a hygiene check run before this issue's first lifecycle
                        # write. Its only check was Lessons Learned, which GH-693 made advisory —
                        # validate_and_update_doc now warns instead — so no backlog item is skipped
                        # for it any more; the marker and skipped_issues stay for the next real defect.
                        if is_merged:
                            ship_manifest_items(repo_root, issue_num, pr_meta, repo_slug, args.dry_run, journal)
                        log(f"  Found active doc: {os.path.basename(doc_path)}")
                        dest_path, ship_date = validate_and_update_doc(
                            doc_path, pr_meta, is_merged=is_merged, dry_run=args.dry_run, journal=journal
                        )
                        log(f"  Moved -> {os.path.basename(dest_path)} (destination: {os.path.basename(os.path.dirname(dest_path))})")
                        updated = update_roadmap_entry(
                            repo_root,
                            issue_num,
                            landing,
                            ship_date,
                            is_merged=is_merged,
                            dry_run=args.dry_run,
                            journal=journal,
                            doc_path=os.path.relpath(dest_path, repo_root),
                        )
                        if updated:
                            log(f"  ROADMAP.md entry updated for GH-{issue_num}")
                    else:
                        log(f"  No active doc in 2-WORKING for GH-{issue_num}")
                        ship_date = (pr_meta.get("mergedAt") or datetime.now().isoformat())[:10]
                        if not is_open or args.force_promote:
                            if is_merged:
                                ship_manifest_items(repo_root, issue_num, pr_meta, repo_slug, args.dry_run, journal)
                            updated = update_roadmap_entry(
                                repo_root,
                                issue_num,
                                landing,
                                ship_date,
                                is_merged=is_merged,
                                dry_run=args.dry_run,
                                journal=journal,
                            )
                            if updated:
                                log(f"  ROADMAP.md entry updated for GH-{issue_num}")
                        else:
                            log(f"  Issue #{issue_num} is OPEN — preserving active ROADMAP.md entry (skipping move to Completed)")

                # GH-271: reference-only mentions never promote or move anything. When the
                # mentioned issue is OPEN (or an unknowable-state umbrella), record merge
                # evidence on its active doc — the "Advances GH-N (phase k of n)" convention
                # GH-202/GH-232 pin — and nothing else. Issues already handled above (the
                # force-promote widening) are skipped.
                for issue_num in mentioned_issues:
                    if issue_num in action_issues:
                        continue
                    doc_path = find_active_doc_for_issue(repo_root, issue_num)
                    if not doc_path:
                        continue
                    issue_state = fetch_issue_state(repo_root, issue_num, offline_manifest)
                    fm = parse_doc_frontmatter(doc_path)
                    is_multiphase = (
                        fm.get("umbrella") in ("true", "1", "yes")
                        or fm.get("multiphase") in ("true", "1", "yes")
                        or fm.get("multi_phase") in ("true", "1", "yes")
                    )
                    is_open = (issue_state == "OPEN") or (issue_state is None and is_multiphase)
                    if is_open and is_merged:
                        log(f"  Issue #{issue_num} referenced without a closing keyword and OPEN — recording merge evidence only")
                        record_merge_evidence(doc_path, pr_meta, dry_run=args.dry_run, journal=journal)

            # Global roadmap cleanups
            fix_mangled_roadmap_entries(repo_root, dry_run=args.dry_run, journal=journal)

            # GH-421: skip downstream regeneration only when there was genuinely nothing to
            # act on this run (catch-up mode found no new PRs, and no --pr/--marathon target
            # was given) — the scheduled cron trigger's common case. NOT when a real PR or
            # marathon lane was processed but happened not to move a doc: run_subprocesses does
            # independent, valuable work every time (release-timeline export incl. the GH-474
            # preview refresh, releases check, the PDDA gate) that existing suites (gh202,
            # gh425, gh454) already pin as running on every real post-merge invocation,
            # regardless of doc lifecycle outcome. Byte-identical output on a genuine repeat
            # (issue #421's actual idempotency requirement) is satisfied by these regenerators
            # already being deterministic, not by skipping them.
            if not args.dry_run and not landing_items and not args.marathon:
                log("Nothing to reconcile; no artifacts written")
                journal.cleanup()
                return

            if skipped_issues:
                log(f"{len(skipped_issues)} backlog item(s) skipped — "
                    + ", ".join(f"GH-{n}" for n in sorted(skipped_issues)))

            # Subprocess orchestration
            run_subprocesses(
                repo_root,
                dry_run=args.dry_run,
                journal=journal,
                reconciled_issues=reconciled_issues,
            )

            # Final validation gate
            if not args.dry_run:
                run_validation_gate(repo_root)

            log("Wave reconciliation completed successfully! ✅")
            journal.cleanup()

    except ReconcileError as re_err:
        journal.rollback()
        verify_rollback_completeness(repo_root, baseline)
        sys.exit(re_err.code)
    except (Exception, SystemExit) as exc:
        journal.rollback()
        verify_rollback_completeness(repo_root, baseline)
        raise exc


if __name__ == "__main__":
    main()
