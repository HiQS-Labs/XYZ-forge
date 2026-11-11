#!/usr/bin/env python3
"""gate_receipt.py — On-disk deterministic local gate receipt contract (GH-124).

WHY THIS FILE EXISTS
--------------------
Auto-PR (marathon-closeout.sh --auto-pr) and in-flight QA attestation comments require machine-checkable
proof that a commit passed the qualification gate before pushing or opening a PR.

This module provides a unified interface for writing and checking deterministic JSON receipts
stored at `.xyz/receipts/<SHA>.json`, while falling back to `.gate-evidence/<SHA>.txt` when present.
"""

import argparse
import datetime
import json
import os
import sys
import re
import shlex
from pathlib import Path

from rtl import (ATTEMPT_CONTEXT_ENV, attempt_git, attempt_origin, attempt_origin_url, archive_lane_attempts,
                 lane_attempt_row, lane_attempt_reserve, lane_attempt_finish)


ADMIN_BRANCHES = {"main", "development", "master"}


def _merge_attempt(repo_root, sha, context):
    path = context.get("record", "")
    if not os.path.isabs(path):
        raise ValueError("merge repair record must be absolute")
    with open(path) as f:
        record = json.load(f)
    attempts = record.get("attempts", [])
    index = context.get("index", len(attempts) - 1)
    if not isinstance(index, int) or isinstance(index, bool) or index < 0 or index >= len(attempts):
        raise ValueError("merge repair reservation index is invalid")
    row = attempts[index]
    origin = record.get("origin", record.get("repo", ""))
    # Compare through Git's configured source identity, not an unbound outcome flag.
    source = row.get("clone_path", "")
    if not origin or attempt_origin_url(origin) != attempt_origin(repo_root):
        raise ValueError("merge repair target repository does not match")
    if row.get("outcome") == "in_progress":
        if index != len(attempts) - 1:
            raise ValueError("active merge repair was superseded by a later reservation")
        if not source or attempt_origin(source) != attempt_origin(repo_root):
            raise ValueError("active merge repair source is unavailable or mismatched")
        if attempt_git(source, "rev-parse", "HEAD") != sha:
            raise ValueError("active repair candidate is not its source HEAD")
        if not row.get("head_sha"):
            raise ValueError("merge repair has no reserved starting revision")
        attempt_git(source, "merge-base", "--is-ancestor", row["head_sha"], sha)
    elif row.get("outcome") == "resolved":
        if sha not in (row.get("commit"), row.get("resolved_head")):
            raise ValueError("completed repair does not cover this candidate")
    else:
        raise ValueError("merge repair is neither active nor resolved for this candidate")
    return {"kind": "merge-repair", "record": path, "index": index, "state": row.get("outcome")}


def _resolve_lane_context(context):
    # A crash after rename but before the protected reference update can leave the old
    # live path. Recover only one matching id from this lane's existing archive area.
    if os.path.isfile(context.get("record", "")):
        path = Path(context["record"])
        if path.parent.name == "attempts" and path.parent.parent.name == ".tick":
            context = dict(context, archived=False)
        elif (path.name == "attempts" and path.parent.parent.name == "attempt-history"
              and path.parent.parent.parent.name == ".tick"):
            context = dict(context, archived=True)
        else:
            raise ValueError("reservation is outside the canonical attempt areas")
        try:
            return context, lane_attempt_row(context)
        except ValueError:
            if context["archived"]:
                raise
            # A new budget may now occupy the old live filename; recover only the old id.
    original = Path(context.get("record", ""))
    if not original.is_absolute() or original.parent.name != "attempts":
        raise ValueError("attempt record is missing")
    matches = []
    for candidate in (original.parent.parent / "attempt-history").glob(original.name + "-*/attempts"):
        recovered = dict(context, record=str(candidate), archived=True)
        try:
            row = lane_attempt_row(recovered)
        except (OSError, ValueError):
            continue
        matches.append((recovered, row))
    if len(matches) != 1:
        raise ValueError("no unique archived reservation matches the missing reference")
    return matches[0]


def attempt_admission(repo_root, sha=None, ref=None, context_override=None, destination_ref=None):
    """Read canonical accounting before qualification; never allocate or reset budget."""
    repo_root = os.path.realpath(repo_root)
    branch = (ref.removeprefix("refs/heads/") if ref and ref.startswith("refs/heads/")
              else attempt_git(repo_root, "branch", "--show-current"))
    destination_task = bool(destination_ref and destination_ref.startswith("refs/heads/")
                            and destination_ref.removeprefix("refs/heads/") not in ADMIN_BRANCHES)
    raw = (json.dumps(context_override) if context_override is not None else
           os.environ.get(ATTEMPT_CONTEXT_ENV, ""))
    if not raw and os.environ.get("MERGE_CLEANUP_RECORD"):
        raw = json.dumps({"kind": "merge-repair", "record": os.environ["MERGE_CLEANUP_RECORD"]})
    if not raw and branch in ADMIN_BRANCHES and not destination_task:
        return {"kind": "non-task", "branch": branch}
    sha = attempt_git(repo_root, "rev-parse", (sha or "HEAD") + "^{commit}")
    if not raw:
        if (os.environ.get("GITHUB_ACTIONS") == "true" and
                os.environ.get("GITHUB_SHA") == sha and
                os.environ.get("GITHUB_REPOSITORY")):
            import hashlib
            expected = "https://github.com/" + os.environ["GITHUB_REPOSITORY"]
            if hashlib.sha256(expected.encode()).hexdigest() == attempt_origin(repo_root):
                return {"kind": "hosted-actions", "sha": sha}
        if branch in ADMIN_BRANCHES and not destination_task:
            return {"kind": "non-task", "branch": branch}
        if not branch:
            for base in ("refs/heads/development", "refs/heads/main",
                         "refs/remotes/origin/development", "refs/remotes/origin/main"):
                try:
                    if attempt_git(repo_root, "rev-parse", base) == sha:
                        return {"kind": "integration-tip", "ref": base}
                except Exception:
                    continue
        raise ValueError("task qualification has no attempt reservation; use gate_receipt.py attempt-start")
    context = json.loads(raw)
    if not isinstance(context, dict):
        raise ValueError("attempt context must be an object")
    if context.get("kind") == "merge-repair":
        return _merge_attempt(repo_root, sha, context)
    if context.get("kind") not in ("manual", "lane"):
        raise ValueError("unknown attempt context kind")
    context, row = _resolve_lane_context(context)
    if context["kind"] != row.get("kind"):
        raise ValueError("reservation kind does not match its canonical entry")
    source = row.get("target_root", "")
    if not source or row.get("origin") != attempt_origin(repo_root):
        raise ValueError("reservation target repository does not match this qualification clone")
    if row.get("state") != "completed" and attempt_origin(source) != row["origin"]:
        raise ValueError("active reservation source is unavailable or mismatched")
    if row.get("attestation"):
        context["attestation"] = row["attestation"]
    if context.get("attestation"):
        import relay_attest
        with open(context["attestation"]) as f:
            approval = json.load(f)
        if os.path.realpath(context["attestation"]) != os.path.realpath(relay_attest.path_for(approval["task"], source)):
            raise ValueError("approval is outside the protected target attestation path")
        if row.get("candidate") != approval.get("reviewed_head"):
            raise ValueError("approval does not match the canonical reviewed candidate")
        linked = approval.get("attempt_context", {})
        if linked.get("id") != context["id"]:
            raise ValueError("approval is not bound to the consumed reservation")
        approval, why = relay_attest.load(approval["task"], expected_reviewer=approval["reviewer"],
                                         relay_file=approval["relay_file"], target_repo=source,
                                         path=context["attestation"])
        if not approval:
            raise ValueError("archived reservation approval refused: " + str(why))
        ok, why = relay_attest.candidate_ok(approval, sha, source)
        if not ok:
            raise ValueError("archived reservation candidate refused: " + str(why))
        historical = False
        completion = approval.get("phase_completion")
        if completion is not None:
            completed, why = relay_attest.phase_completion_candidate(
                approval, phase=completion.get("phase"), lane=row["task"], head=sha, target_repo=source)
            if why:
                raise ValueError("archived phase completion refused: " + str(why))
            historical = completed == sha
        if not historical and attempt_git(source, "rev-parse", "HEAD") != sha:
            raise ValueError("archived reservation candidate differs from the live target HEAD")
    elif row.get("state") == "completed":
        if row.get("candidate") != sha:
            raise ValueError("completed reservation covers a different revision")
    elif row.get("state") == "active" and not context.get("archived"):
        if attempt_git(source, "rev-parse", "HEAD") != sha:
            raise ValueError("qualification candidate differs from the live task HEAD")
        attempt_git(source, "merge-base", "--is-ancestor", row["start_sha"], sha)
        if branch and row.get("branch") and branch != row["branch"]:
            raise ValueError("pushed task ref differs from the reserved branch")
    else:
        raise ValueError("reservation is not active or completed for this revision")
    return dict(context, sha=sha, state=row["state"])


def get_receipt_dir(repo_root):
    return os.path.join(repo_root, ".xyz", "receipts")


def get_receipt_path(repo_root, sha):
    return os.path.join(get_receipt_dir(repo_root), f"{sha}.json")


def write_receipt(repo_root, sha, gate, mode, exit_code, passed=None, total=None, duration_s=None, scope=None):
    """Write an on-disk JSON receipt for a qualified gate run."""
    admission = attempt_admission(repo_root, sha) if int(exit_code) == 0 else None
    receipt_dir = get_receipt_dir(repo_root)
    os.makedirs(receipt_dir, exist_ok=True)
    
    receipt_data = {
        "sha": sha,
        "gate": gate,
        "mode": mode,
        "exit_code": int(exit_code),
        "passed": int(passed) if passed is not None else None,
        "total": int(total) if total is not None else None,
        "duration_s": float(duration_s) if duration_s is not None else None,
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "host": f"{os.uname().sysname} {os.uname().release}" if hasattr(os, "uname") else "unknown"
    }
    if admission is not None:
        receipt_data["attempt"] = admission
    if scope is not None:
        receipt_data["scope"] = str(scope)
    
    target_path = get_receipt_path(repo_root, sha)
    tmp_path = f"{target_path}.tmp.{os.getpid()}"
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(receipt_data, f, indent=2)
        f.write("\n")
    os.replace(tmp_path, target_path)
    return receipt_data


def valid_pass_receipt(data, sha):
    """The shared on-disk/committed-bundle pass predicate."""
    return (
        isinstance(data, dict)
        and bool(sha)
        and data.get("sha") == sha
        and not isinstance(data.get("exit_code"), bool)
        and data.get("exit_code") == 0
    )


def is_full_gate_receipt(data, sha):
    """Return True when data is a passing full-gate validate.sh receipt for sha (GH-1236)."""
    return (
        valid_pass_receipt(data, sha)
        and data.get("gate") == "validate.sh"
        and data.get("mode") != "marathon"
        and data.get("scope") == "full"
    )


def check_receipt(repo_root, sha, max_age_s=None, require_full_gate=False):
    """Check whether a valid pass receipt exists on-disk for the given SHA."""
    json_path = get_receipt_path(repo_root, sha)
    if os.path.exists(json_path):
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if not isinstance(data, dict):
                return False, f"Corrupt receipt JSON at {json_path}: expected JSON object"
            if valid_pass_receipt(data, sha):
                if require_full_gate and not is_full_gate_receipt(data, sha):
                    return False, (
                        f"Receipt for {sha} is not a full-gate validate.sh receipt "
                        f"(gate={data.get('gate')!r}, mode={data.get('mode')!r}, scope={data.get('scope')!r})"
                    )
                if max_age_s is not None and "timestamp" in data:
                    ts = datetime.datetime.fromisoformat(data["timestamp"])
                    if ts.tzinfo is None:
                        ts = ts.replace(tzinfo=datetime.timezone.utc)
                    age = (datetime.datetime.now(datetime.timezone.utc) - ts).total_seconds()
                    if age > max_age_s:
                        return False, f"Receipt expired (age: {age:.0f}s > max: {max_age_s}s)"
                return True, data
            if data.get("sha") != sha:
                return False, f"Receipt sha is {data.get('sha')}, expected {sha}"
            return False, f"Receipt exit_code is {data.get('exit_code')}, expected 0"
        except Exception as e:
            return False, f"Corrupt receipt JSON at {json_path}: {e}"

    if require_full_gate:
        return False, f"No full-gate receipt found for {sha}"

    # Fallback to legacy .gate-evidence/<sha>.txt
    txt_path = os.path.join(repo_root, ".gate-evidence", f"{sha}.txt")
    if os.path.exists(txt_path):
        try:
            with open(txt_path, "r", encoding="utf-8") as f:
                content = f.read()
            if f"commit: {sha}" in content and "result: green" in content:
                return True, {"sha": sha, "gate": "ci-local.sh", "mode": "sequential", "exit_code": 0, "source": "gate-evidence"}
            return False, "gate-evidence file exists but result is not green"
        except Exception as e:
            return False, f"Error reading {txt_path}: {e}"

    return False, f"No gate receipt found for {sha}"


def main():
    parser = argparse.ArgumentParser(description="Manage on-disk local gate receipts.")
    subparsers = parser.add_subparsers(dest="action", required=True)

    write_p = subparsers.add_parser("write")
    write_p.add_argument("--repo", default=".")
    write_p.add_argument("--sha", required=True)
    write_p.add_argument("--gate", required=True)
    write_p.add_argument("--mode", default="sequential")
    write_p.add_argument("--scope", default=None)
    write_p.add_argument("--exit-code", type=int, required=True)
    write_p.add_argument("--passed", type=int, default=None)
    write_p.add_argument("--total", type=int, default=None)
    write_p.add_argument("--duration", type=float, default=None)

    check_p = subparsers.add_parser("check")
    check_p.add_argument("--repo", default=".")
    check_p.add_argument("--sha", required=True)
    check_p.add_argument("--max-age-s", type=int, default=None)
    check_p.add_argument("--require-full-gate", action="store_true")

    admit_p = subparsers.add_parser("admit", help="verify existing task accounting without booking")
    admit_p.add_argument("--repo", default=".")
    admit_p.add_argument("--sha")
    admit_p.add_argument("--ref")
    admit_p.add_argument("--destination-ref")
    start_p = subparsers.add_parser("attempt-start", help="book through the canonical lane writer")
    start_p.add_argument("--repo", default=".")
    start_p.add_argument("--task", required=True)
    start_p.add_argument("--accounting-root", help="maintained coordinator root; survives task checkout retirement")
    start_p.add_argument("--env", action="store_true")
    finish_p = subparsers.add_parser("attempt-finish", help="finish the current manual reservation")
    finish_p.add_argument("--repo", default=".")
    finish_p.add_argument("--outcome", choices=("completed", "failed"), required=True)

    args = parser.parse_args()
    repo_root = os.path.abspath(args.repo)

    try:
        if args.action == "write" and args.exit_code == 0:
            attempt_admission(repo_root, args.sha)
        if args.action == "admit":
            print(json.dumps(attempt_admission(repo_root, args.sha, args.ref, destination_ref=args.destination_ref)))
            return
        if args.action == "attempt-start":
            count, context = lane_attempt_reserve(args.accounting_root or repo_root, args.task, repo_root,
                                                 cap=int(os.environ.get("LANE_MAX_ATTEMPTS", "2")),
                                                 kind="manual")
            if context is None:
                print(f"gate-attempt: budget exhausted after {count} consumed rounds", file=sys.stderr)
                sys.exit(3)
            if args.env:
                print("export " + ATTEMPT_CONTEXT_ENV + "=" + shlex.quote(json.dumps(context)))
            else:
                print(json.dumps(context))
            return
        if args.action == "attempt-finish":
            context = json.loads(os.environ.get(ATTEMPT_CONTEXT_ENV, ""))
            if context.get("kind") != "manual":
                raise ValueError("attempt-finish requires the manual reservation context")
            attempt_admission(repo_root, context_override=context)
            context, current = _resolve_lane_context(context)
            if current.get("state") == "completed" and args.outcome == "completed" and context.get("archived"):
                print(json.dumps({"id": current["id"], "state": "completed", "context": context}))
                return
            os.environ[ATTEMPT_CONTEXT_ENV] = json.dumps(context)
            row = lane_attempt_finish(context, args.outcome, attempt_git(repo_root, "rev-parse", "HEAD"),
                                      archive=args.outcome == "completed")
            print(json.dumps({"id": row["id"], "state": row["state"],
                              "context": json.loads(os.environ[ATTEMPT_CONTEXT_ENV])}))
            return
    except Exception as exc:
        print(f"gate-attempt: REFUSED — {exc}; use gate_receipt.py attempt-start", file=sys.stderr)
        sys.exit(2)

    if args.action == "write":
        receipt = write_receipt(
            repo_root=repo_root,
            sha=args.sha,
            gate=args.gate,
            mode=args.mode,
            exit_code=args.exit_code,
            passed=args.passed,
            total=args.total,
            duration_s=args.duration,
            scope=args.scope,
        )
        print(f"gate-receipt: wrote {get_receipt_path(repo_root, args.sha)}")
        sys.exit(0)

    elif args.action == "check":
        ok, res = check_receipt(
            repo_root,
            args.sha,
            max_age_s=args.max_age_s,
            require_full_gate=args.require_full_gate,
        )
        if ok:
            print(f"gate-receipt: valid pass receipt for {args.sha[:8]} ({res.get('gate', 'unknown')})")
            sys.exit(0)
        else:
            print(f"gate-receipt: REFUSED — {res}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
