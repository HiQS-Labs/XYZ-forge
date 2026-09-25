#!/usr/bin/env python3
"""GH-646: opt-in, qualified, current-state projection of one exact issue label.

The child receives no DB handle. The existing parent owns locks, deadlines and cursors.
One distinct actionable issue is processed per bounded invocation; replay is set-to-value.
"""
import json
import os
import re
import subprocess
import sys
import time

from releases_app import (_is_lifecycle_event, _live_roadmap_event, _START_EVENTS,
                          read_native_issue, _repo_from_issue_url, _utc_datetime, now_iso)

LABEL = "in-progress"


def _gh(args, deadline):
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        raise TimeoutError("label projection deadline exhausted")
    proc = subprocess.run([os.environ.get("XYZ_LABELS_GH_BIN", os.environ.get("RELEASES_GH_BIN", "gh"))]
                          + args, capture_output=True, text=True, timeout=remaining)
    if proc.returncode:
        raise RuntimeError("gh failed: %s" % proc.stderr.strip())
    return proc.stdout


def _names(issue):
    labels = issue["labels"]
    if any(not isinstance(label, dict) or not isinstance(label.get("name"), str) for label in labels):
        raise ValueError("native issue labels unavailable")
    return {label["name"] for label in labels}


def project(current, deadline):
    repo, number, url = current["repo"], current["number"], current["issue_url"]
    native = read_native_issue(repo, number, url, timeout=max(.001, deadline - time.monotonic()))
    before = _names(native)
    label = current["status_label"]
    latest = current.get("latest_lifecycle")
    state = _live_roadmap_event(current.get("section"), current.get("marker"), False)
    genuine = latest and _is_lifecycle_event(latest)
    if genuine:
        observed = _utc_datetime(latest.get("at"))
        if observed is None or observed > _utc_datetime(now_iso()):
            raise ValueError("current lifecycle timestamp unavailable or future; authority unknown")
    active = label == LABEL and state == "in_flight" and genuine and latest["event"] in _START_EVENTS
    stopped = label is None and genuine and latest["event"] not in _START_EVENTS
    terminal = state in ("completed", "deferred")
    if label == LABEL and not active:
        raise ValueError("established label lacks current genuine start authority")
    desired = active and native["state"] == "open"
    if not desired and not (stopped or native["state"] == "closed" and (active or terminal)):
        raise ValueError("unresolved-label-conflict: unestablished NULL/open issue preserved")
    if desired and LABEL not in before:
        # Exact REST label lookup avoids paginated/list matching. Create only after verified 404.
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("label projection deadline exhausted")
        proc = subprocess.run([os.environ.get("XYZ_LABELS_GH_BIN", os.environ.get("RELEASES_GH_BIN", "gh")),
                               "api", "--include", "repos/%s/labels/%s" % (repo, LABEL)],
                              capture_output=True, text=True, timeout=remaining)
        if proc.returncode:
            if not re.search(r"^HTTP/\S+ 404\b", proc.stdout, re.M):
                raise RuntimeError("label definition lookup failed: %s" % proc.stderr.strip())
            _gh(["label", "create", LABEL, "--repo", repo, "--color", "FBCA04",
                 "--description", "Explicitly accepted work in progress"], deadline)
        else:
            body = re.split(r"\r?\n\r?\n", proc.stdout, maxsplit=1)[-1]
            if json.loads(body).get("name") != LABEL:
                raise ValueError("label definition identity mismatch")
        # Definition lookup/create may take network time. Recheck native state before add.
        fresh = read_native_issue(repo, number, url, timeout=max(.001, deadline - time.monotonic()))
        if fresh["state"] != "open":
            raise RuntimeError("native-state-conflict: issue closed before active label mutation")
        _gh(["issue", "edit", str(number), "--repo", repo, "--add-label", LABEL], deadline)
    elif not desired and LABEL in before:
        _gh(["issue", "edit", str(number), "--repo", repo, "--remove-label", LABEL], deadline)
    verified = read_native_issue(repo, number, url,
                                 timeout=max(.001, deadline - time.monotonic()))
    after = _names(verified)
    if desired and verified["state"] != "open":
        raise RuntimeError("native-state-conflict: issue closed during active label projection")
    if (LABEL in after) != desired or after - {LABEL} != before - {LABEL}:
        raise RuntimeError("label effect readback failed or unrelated labels changed")


def run(batch):
    cfg = batch.get("config") or {}
    allowed = cfg.get("repos")
    if not isinstance(allowed, list) or not allowed or any(
            not isinstance(repo, str) or not re.fullmatch(r"[^/\s]+/[^/\s]+", repo) for repo in allowed):
        raise ValueError("github_labels requires explicit allowed owner/repository identities")
    deadline = time.monotonic() + float(os.environ.get("XYZ_CONNECTOR_WINDOW_S", "5"))
    processed, advanced = None, None
    for ev in sorted(batch.get("events") or [], key=lambda item: item["id"]):
        if ev.get("gh_number") is None:
            advanced = ev["id"]
            continue
        current = ev.get("current")
        if not ev.get("source_valid"):
            raise ValueError("label source unavailable: %s" % ev.get("source_error"))
        if not ev.get("status_label_supported") or not current:
            raise ValueError("unsupported label schema or missing/ambiguous owned current row")
        repo, number = _repo_from_issue_url(current.get("issue_url"))
        if (not current.get("identity_valid") or repo != current.get("repo")
                or number != ev["gh_number"]
                or number != current.get("number") or current.get("repo_id") != ev.get("repo_id")
                or current.get("status_label") not in (None, LABEL)):
            raise ValueError("foreign, malformed or ambiguous owned issue identity/label")
        if repo not in allowed:
            # An independently qualified but intentionally opted-out owned repository is
            # not a foreign URL defect. A subset allowlist must not stall included work.
            advanced = ev["id"]
            continue
        payload = ev.get("payload") if isinstance(ev.get("payload"), dict) else {}
        repair = ev.get("event") == "label_repair"
        terminal = _live_roadmap_event(current.get("section"), current.get("marker"), False) in ("completed", "deferred")
        if repair and (current.get("status_label") is not None or not terminal
                       or payload.get("roadmap_gid") != current.get("global_id")):
            raise ValueError("repair intent no longer names a NULL terminal row")
        eligible = _is_lifecycle_event(ev) or repair or payload.get("source") == "backfill" and terminal
        if not eligible:
            advanced = ev["id"]
            continue
        # Migration/backfill appearance never establishes activation or inactive authority.
        latest = current.get("latest_lifecycle")
        if current.get("status_label") is None and not terminal and not latest:
            advanced = ev["id"]
            continue
        key = (repo, number)
        if processed is not None and processed != key:
            break
        if processed is None:
            project(current, deadline)
            processed = key
        advanced = ev["id"]
    if advanced is not None:
        print("advanced_to: %d" % advanced)
    return 0


def main():
    try:
        return run(json.load(sys.stdin))
    except Exception as exc:
        print("github_labels: %s; cursor retained" % exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
