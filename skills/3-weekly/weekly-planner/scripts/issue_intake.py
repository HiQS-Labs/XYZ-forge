"""Shared issue discovery for 10days and the held weekly preview (GH-1022).

Read adapters take explicit roots/runners/clocks. Import and normalization do no
I/O; this module never writes a ledger/checkpoint, creates a branch or dispatches.
Legacy commands deliberately retain the 200-item open-updated scan contract.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlencode

SCAN_FIELDS = "number,title,createdAt,updatedAt,labels,url"
SCAN_PROJECTION = "sort_by(.number) | .[] | {number, title, createdAt, updatedAt, url, labels: [.labels[].name]}"
BUCKETS = ("1-INBOX", "2-WORKING", "3-COMPLETED", "4-MISC")


def window_query(max_days: int, min_days: int, now: datetime) -> str:
    """Date-level UTC query; caller owns age/selection policy."""
    if not 0 <= min_days < max_days:
        raise ValueError("MAX_DAYS must be greater than MIN_DAYS")
    day = now.astimezone(timezone.utc).date()
    since = (day - timedelta(days=max_days)).isoformat()
    until = (day - timedelta(days=min_days)).isoformat()
    return f"updated:>={since}" if min_days == 0 else f"updated:{since}..{until}"


def read_command(argv: list[str], root: Path) -> str:
    result = subprocess.run(argv, cwd=root, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(f"command exited {result.returncode}: {result.stderr.strip()}")
    return result.stdout


def find_doc(number: str, root: Path) -> dict:
    """Legacy first-match traversal; presence signals never establish delivery."""
    for bucket in BUCKETS:
        # Keep find's original filesystem traversal order and regular-file rule.
        result = subprocess.run(["find", str(root / "PROJECT" / bucket), "-maxdepth", "1",
                                 "-type", "f", "-name", f"GH-{number}-*.md"],
                                capture_output=True, text=True)
        matches = result.stdout.splitlines()
        if matches:
            doc = Path(matches[0])
            try:
                content = doc.read_text(errors="replace")
            except OSError:
                content = ""
            return {"issue": int(number), "doc": str(doc.relative_to(root)), "bucket": bucket,
                    "has_contract": bool(re.search(r"^##.*preflight contract", content, re.I | re.M)
                                         and "```json" in content)}
    return {"issue": int(number), "doc": None, "bucket": None, "has_contract": False}


def legacy_scan(args: list[str], root: Path, now: datetime | None = None) -> int:
    max_arg = args[0] if args and args[0] else "10"
    min_arg = args[1] if len(args) > 1 and args[1] else "0"
    if not re.fullmatch(r"[0-9]+", max_arg) or not re.fullmatch(r"[0-9]+", min_arg):
        print("usage: scan-issues.sh [MAX_DAYS] [MIN_DAYS]  (defaults: 10 0)", file=sys.stderr)
        return 2
    # Bash arithmetic uses octal for leading zeros; retain that legacy validation.
    def bash_int(value):
        return int(value, 8 if len(value) > 1 and value.startswith("0") else 10)
    try:
        max_days, min_days = bash_int(max_arg), bash_int(min_arg)
    except ValueError:
        print(f"scan-issues.sh: MAX_DAYS ({max_arg}) must be greater than MIN_DAYS ({min_arg})", file=sys.stderr)
        return 2
    if max_days <= min_days:
        print(f"scan-issues.sh: MAX_DAYS ({max_arg}) must be greater than MIN_DAYS ({min_arg})", file=sys.stderr)
        return 2
    if not shutil.which("gh"):
        print("scan-issues.sh: gh CLI not found on PATH", file=sys.stderr)
        return 2
    # date's -v/-d input is decimal even though Bash validation above is octal.
    try:
        query = window_query(int(max_arg), int(min_arg), now or datetime.now(timezone.utc))
    except (ValueError, OverflowError):
        print("scan-issues.sh: could not compute window bounds", file=sys.stderr)
        return 2
    return subprocess.run(["gh", "issue", "list", "--state", "open", "--search", query,
                           "--limit", "200", "--json", SCAN_FIELDS, "--jq", SCAN_PROJECTION],
                          cwd=root).returncode


def legacy_find(args: list[str], cwd: Path) -> int:
    number, root_arg = "", ""
    while args:
        arg, args = args[0], args[1:]
        if arg == "--root":
            if not args:
                print("find-doc.sh: --root requires a directory argument", file=sys.stderr)
                return 2
            root_arg, args = args[0], args[1:]
        elif arg in ("-h", "--help"):
            print("usage: find-doc.sh [--root DIR] ISSUE_NUMBER", file=sys.stderr)
            return 0
        elif arg.startswith("-"):
            print(f"find-doc.sh: unknown option: {arg}", file=sys.stderr)
            return 2
        else:
            number = arg
    if not re.fullmatch(r"[0-9]+", number):
        print("usage: find-doc.sh [--root DIR] ISSUE_NUMBER", file=sys.stderr)
        return 2
    if not shutil.which("jq"):
        print("find-doc.sh: jq not found on PATH", file=sys.stderr)
        return 2
    raw, source = root_arg, "--root"
    if not raw:
        raw, source = os.environ.get("TENDAYS_ROOT", ""), "$TENDAYS_ROOT"
    if not raw:
        result = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=cwd,
                                capture_output=True, text=True)
        raw = result.stdout.strip() if result.returncode == 0 else str(cwd)
        source = "git toplevel/$PWD"
    root = Path(raw)
    if not root.is_absolute():
        root = cwd / root
    if not root.is_dir():
        print(f"find-doc.sh: not a directory (from {source}): {raw}", file=sys.stderr)
        return 2
    root = root.resolve()
    # Retain jq's numeric argument parsing/error behavior (e.g. leading zero).
    check = subprocess.run(["jq", "-nc", "--argjson", "issue", number, "."],
                           stdout=subprocess.DEVNULL)
    if check.returncode:
        return check.returncode
    print(json.dumps(find_doc(number, root), separators=(",", ":"), ensure_ascii=False))
    return 0


def repository_name(value: str) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[\w.-]+/[\w.-]+", value, re.ASCII):
        raise ValueError("repository must be OWNER/REPO")
    return value.lower()


def github_url_matches(value: str | None, canonical: str) -> bool:
    """Compare observed URL casing with an already qualified canonical identity."""
    return isinstance(value, str) and value.lower() == canonical.lower()


def normalize_record(record: dict, repository: str, kind: str = "issue") -> dict:
    """Repository-qualified identities; reject malformed/foreign evidence."""
    repository = repository_name(repository)
    if not isinstance(record, dict):
        raise ValueError("GitHub record must be an object")
    number = record.get("number")
    if type(number) is not int or number <= 0:
        raise ValueError("invalid GitHub number")
    segment = "issues" if kind == "issue" else "pull"
    url = record.get("html_url", record.get("url", ""))
    expected = f"https://github.com/{repository}/{segment}/{number}"
    if not github_url_matches(url, expected):
        raise ValueError(f"foreign or invalid {kind} URL: {url}")
    if not isinstance(record.get("title"), str) or not record["title"]:
        raise ValueError(f"missing title: {expected}")
    updated = record.get("updated_at", record.get("updatedAt"))
    if not isinstance(updated, str):
        raise ValueError(f"missing updatedAt: {expected}")
    parsed = datetime.fromisoformat(updated.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        raise ValueError(f"unqualified timestamp: {expected}")
    raw_state = record.get("state", "")
    if not isinstance(raw_state, str):
        raise ValueError(f"invalid state type: {expected}")
    state = raw_state.upper()
    if state not in ("OPEN", "CLOSED", "MERGED"):
        raise ValueError(f"invalid state: {expected}")
    if record.get("body") is not None and not isinstance(record["body"], str):
        raise ValueError(f"invalid body: {expected}")
    labels = record.get("labels", [])
    if not isinstance(labels, list):
        raise ValueError(f"invalid labels: {expected}")
    labels = [label["name"] if isinstance(label, dict) else label for label in labels]
    if any(not isinstance(label, str) for label in labels):
        raise ValueError(f"invalid label names: {expected}")
    return {"identity": f"{repository}/{segment}/{number}", "repository": repository,
            "kind": kind, "number": number, "url": url, "title": record["title"],
            "state": state, "body": record.get("body") or "", "updatedAt": updated,
            "createdAt": record.get("created_at", record.get("createdAt")),
            "closedAt": record.get("closed_at", record.get("closedAt")), "labels": labels}


def deduplicate(records: list[dict]) -> list[dict]:
    by_id = {}
    for record in records:
        key = record["identity"]
        if key in by_id and by_id[key] != record:
            raise ValueError(f"conflicting duplicate snapshot: {key}")
        by_id[key] = record
    return sorted(by_id.values(), key=lambda item: (item["repository"], item["kind"], item["number"]))


def read_pages(endpoint: str, root: Path, runner=read_command) -> tuple[list[dict], int]:
    """gh follows every REST Link page; failed/malformed reads never become empty success."""
    pages = json.loads(runner(["gh", "api", "--paginate", "--slurp", endpoint], root))
    if not isinstance(pages, list) or not pages or any(not isinstance(page, list) for page in pages):
        raise ValueError(f"invalid paginated response: {endpoint}")
    records = [record for page in pages for record in page]
    if any(not isinstance(record, dict) for record in records):
        raise ValueError(f"invalid record: {endpoint}")
    return records, len(pages)


def discover_weekly(repository: str, since: str, root: Path, previous: dict | None = None,
                    runner=read_command, now: datetime | None = None) -> dict:
    """Complete observations, no readiness/completion judgments or durable checkpoint.

    Relevant: updated since explicit bound plus every prior member supplied by
    caller. Dependencies not present in that snapshot are outside this stage.
    Pagination is complete transport, not an atomic GitHub snapshot; freeze must
    refresh again. Ratings/GIDs stay in RELEASES and are not manufactured here.
    """
    repository = repository_name(repository)
    bound = datetime.fromisoformat(since.replace("Z", "+00:00"))
    if bound.tzinfo is None:
        raise ValueError("--since requires an explicit timezone")
    if previous is not None:
        if (not isinstance(previous, dict) or previous.get("complete") is not True
                or repository_name(previous.get("repository")) != repository
                or not isinstance(previous.get("issues"), list)):
            raise ValueError("previous intake must be complete and from the same repository")
        prior = deduplicate([normalize_record(item, repository) for item in previous["issues"]])
    else:
        prior = []
    query = urlencode({"state": "all", "since": bound.isoformat(), "sort": "updated",
                       "direction": "asc", "per_page": 100})
    raw_issues, issue_pages = read_pages(f"repos/{repository}/issues?{query}", root, runner)
    issues = deduplicate([normalize_record(item, repository) for item in raw_issues if "pull_request" not in item])
    numbers = {item["number"] for item in issues}
    for item in prior:
        if item["number"] not in numbers:
            record = json.loads(runner(["gh", "api", f"repos/{repository}/issues/{item['number']}"], root))
            if not isinstance(record, dict) or "pull_request" in record:
                raise ValueError(f"prior member became invalid: {item['identity']}")
            refreshed = normalize_record(record, repository)
            if refreshed["identity"] != item["identity"]:
                raise ValueError("prior member identity mismatch")
            issues.append(refreshed)
    raw_prs, pr_pages = read_pages(f"repos/{repository}/pulls?state=open&per_page=100", root, runner)
    prs = []
    for item in deduplicate([normalize_record(pr, repository, "pr") for pr in raw_prs]):
        fields = "number,title,url,state,updatedAt,isDraft,headRefName,baseRefName,headRefOid,mergeable,reviewDecision,statusCheckRollup,body,author,changedFiles,labels,createdAt,closedAt"
        pr = json.loads(runner(["gh", "pr", "view", str(item["number"]), "-R", repository, "--json", fields], root))
        fresh = normalize_record(pr, repository, "pr")
        # Validate the fields consumed by existing advisory helpers, without
        # changing their policy or coercing malformed observations into readiness.
        for field in ("reviewDecision", "mergeable", "headRefName", "baseRefName"):
            if pr.get(field) is not None and not isinstance(pr[field], str):
                raise ValueError(f"invalid PR {field}: {item['identity']}")
        rollup = pr.get("statusCheckRollup")
        if rollup is not None:
            if not isinstance(rollup, list) or any(not isinstance(check, dict) for check in rollup):
                raise ValueError(f"invalid PR statusCheckRollup: {item['identity']}")
            for check in rollup:
                for field in ("__typename", "state", "status", "conclusion"):
                    if check.get(field) is not None and not isinstance(check[field], str):
                        raise ValueError(f"invalid PR CI {field}: {item['identity']}")
        if fresh != item:
            raise ValueError(f"PR changed during intake: {item['identity']}; refresh")
        files, _ = read_pages(f"repos/{repository}/pulls/{item['number']}/files?per_page=100", root, runner)
        if type(pr.get("changedFiles")) is not int or len(files) != pr["changedFiles"]:
            raise ValueError(f"incomplete PR files: {item['identity']}")
        if any(not isinstance(file.get("filename"), str) for file in files):
            raise ValueError(f"malformed PR file: {item['identity']}")
        if len({file["filename"] for file in files}) != len(files):
            raise ValueError(f"duplicate PR files: {item['identity']}")
        pr["files"] = [{"path": file["filename"]} for file in files]
        pr["identity"] = item["identity"]
        prs.append(pr)
    return {"repository": repository, "complete": True, "status": "HELD", "dispatch_allowed": False,
            "observedAt": (now or datetime.now(timezone.utc)).isoformat(), "since": bound.isoformat(),
            "issues": deduplicate(issues), "prs": prs, "pages": {"issues": issue_pages, "prs": pr_pages},
            "relevance": "updated-since plus explicit previous members; dependencies must be supplied",
            "holds": ["Branch ledger reconciliation, independent criterion review, readiness, immutable freeze and dispatch enforcement are not implemented."]}


def normalise_work_observations(observations: list[dict]) -> dict:
    """Deduplicate declared owner facts, retaining every source and conflict; no policy/effects."""
    if not isinstance(observations, list) or not observations:
        raise ValueError("nonempty declared work observations required")
    result = {"complete": True, "status": "HELD", "dispatch_allowed": False,
              "observations": observations, "facts": [], "holds": ["Declared observations are not global quiescence, criterion delivery or dispatch approval."]}
    seen = {}
    for source in observations:
        inventory = source.get("inventory")
        if (source.get("error") or not isinstance(inventory, dict)
                or inventory.get("schema") != "releases/work-inventory@1"
                or inventory.get("read_complete") is not True or inventory.get("initialized") is not True
                or inventory.get("dispatch") is not False):
            result["complete"] = False
            result["holds"].append("Unavailable/unsupported declared root: " + source["id"])
            continue
        repositories = inventory.get("repositories")
        owners = {}
        try:
            if (type(inventory.get("generation")) is not int or inventory["generation"] <= 0
                    or type(inventory.get("schema_version")) is not int or inventory["schema_version"] < 8
                    or not isinstance(inventory.get("git_head"), str)
                    or not re.fullmatch(r"[0-9a-f]{40}(?:[0-9a-f]{24})?", inventory["git_head"])
                    or not isinstance(repositories, list) or not repositories):
                raise ValueError("owner source identities unavailable")
            for repo in repositories:
                name = repository_name(repo.get("repository"))
                gid = repo.get("global_id")
                if name in owners or not isinstance(gid, str) or not re.fullmatch(r"repo-[0-9A-HJKMNP-TV-Z]{26}", gid):
                    raise ValueError("ambiguous repository/GID ownership")
                owners[name] = gid
            if source["repository"] not in owners:
                raise ValueError("declared repository ownership mismatch")
        except (ValueError, TypeError, AttributeError):
            result["complete"] = False
            result["holds"].append("Declared owner source identity mismatch: " + source["id"])
            continue
        for kind, key in (("jog", "rows"), ("marathon", "marathons"), ("lifecycle", "lifecycle")):
            values = inventory.get(key)
            if not isinstance(values, list):
                result["complete"] = False
                result["holds"].append("Missing fact collection: " + source["id"] + ":" + key)
                continue
            for fact in values:
                try:
                    if not isinstance(fact, dict) or not isinstance(fact.get("global_id"), str) or fact.get("dispatch") is not False:
                        raise ValueError("malformed owner work fact")
                    name = repository_name(fact.get("repository"))
                    prefix = {"jog": "jog-", "marathon": "mar-", "lifecycle": "wev-"}[kind]
                    if (owners.get(name) != fact.get("repo_global_id")
                            or not re.fullmatch(prefix + r"[0-9A-HJKMNP-TV-Z]{26}", fact["global_id"])):
                        raise ValueError("work fact ownership/source identity mismatch")
                except (ValueError, TypeError):
                    result["complete"] = False
                    result["holds"].append("Malformed owned fact retained in raw source: " + source["id"] + ":" + kind)
                    continue
                identity = (kind, name, fact["global_id"])
                # Local SQLite IDs are not global identity; all business values stay material.
                semantic = {k: v for k, v in fact.items() if k not in ("id", "repo_id", "tracking_ref_id")}
                provenance = {"root_id": source["id"], "root": source["declared_root"],
                              "git_head": inventory.get("git_head"), "generation": inventory.get("generation")}
                if identity in seen and seen[identity]["fact"] != semantic:
                    result["complete"] = False
                    result["holds"].append("Conflicting stable work identity: " + ":".join(identity))
                    seen[identity].setdefault("conflicts", []).append({"fact": semantic, "source": provenance})
                elif identity in seen:
                    seen[identity]["sources"].append(provenance)
                else:
                    record = {"identity": list(identity), "fact": semantic, "sources": [provenance]}
                    seen[identity] = record
                    result["facts"].append(record)
        for context in source.get("contexts", []):
            if (not isinstance(context, dict) or context.get("schema") != "marathon/observer-snapshot@1"
                    or context.get("read_complete") is not True or context.get("dispatch") is not False):
                result["complete"] = False
                result["holds"].append("Unavailable/unsupported observer: " + source["id"])
        if not source.get("contexts"):
            result["holds"].append("No observer contexts declared for " + source["id"] + "; absence does not prove idle.")
    if not result["complete"]:
        result["status"] = "UNKNOWN"
    return result
