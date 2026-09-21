from __future__ import annotations

import json
import hashlib
import re
import sqlite3
import time
from datetime import datetime
from dataclasses import replace
from pathlib import Path
from typing import Any, Callable
from urllib.parse import urlsplit
from utils.py.releases_cycle import read_work_status

from .contract import (
    MAX_RECORDS,
    ConnectorConfig,
    bounded_text,
    deadline_guard,
    empty_batch,
    parse_time,
    repo_key,
    repo_name,
    safe_path,
    utc_now,
)

Connector = Callable[[ConnectorConfig, float], dict[str, Any]]


def canonical_github_key(stored_name: Any, html_url: Any = None) -> str | None:
    """Prefer GitHub's item URL when a cached repo slug predates a rename."""
    if isinstance(html_url, str):
        parts = [part for part in urlsplit(html_url).path.split("/") if part]
        if len(parts) >= 2:
            key = repo_key("/".join(parts[:2]))
            if key:
                return key
    return repo_key(stored_name)


def native_item_identity(row: dict[str, Any]) -> bool:
    """An item URL cannot lend a foreign repository, type or number to this row."""
    try:
        url = urlsplit(str(row.get("html_url") or ""))
        path = url.path.strip("/").split("/")
        kind = "pull" if row.get("item_type") == "pull_request" else "issues"
        return (url.scheme == "https" and url.netloc.lower() == "github.com"
                and not url.query and not url.fragment and len(path) == 4
                and path[2] == kind and path[3] == str(row.get("number"))
                and repo_key("/".join(path[:2])) == repo_key(row.get("repo_full_name"))
                and str(repo_key(row.get("repo_full_name"))).startswith("github.com/"))
    except ValueError:
        return False


def read_xyz_work(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
    batch = empty_batch("xyz_work", ("established_work",), "unavailable")
    roots = sorted(set(root.expanduser().resolve() for root in config.xyz_roots))
    sources = []
    window = min(deadline, time.monotonic() + 2)
    for root in roots[:4]:
        root_id = hashlib.sha256(str(root).encode()).hexdigest()[:16]
        at = utc_now()
        report = read_work_status(Path(__file__).resolve().parents[2], root, window, at)
        source = {"id": root_id, "read_at": at, "generation": report.get("generation"),
                  "schema_version": report.get("schema_version"),
                  "supported": report.get("status_label_supported") is True,
                  "error": report.get("error_code"), "excluded_rows": 0}
        sources.append(source)
        if not report.get("schema_ready"):
            continue
        ordered = sorted(report["issues"], key=lambda row: not (isinstance(row, dict) and row.get("status_label") == "in-progress" and row.get("recent_start")))
        for row in ordered[:2000]:
            if not isinstance(row, dict):
                source["excluded_rows"] += 1
                continue
            key, number = repo_key(row.get("repo")), row.get("number")
            if not key or not key.startswith("github.com/") or type(number) is not int or number <= 0:
                source["excluded_rows"] += 1
                continue
            start = row.get("recent_start")
            start = {name: start.get(name) for name in ("at", "event", "freshness")} if isinstance(start, dict) else None
            lifecycle = row.get("latest_lifecycle")
            lifecycle = {name: lifecycle.get(name) for name in ("at", "event")} if isinstance(lifecycle, dict) else None
            evidence = {**source, "status_label": row.get("status_label"),
                        "supported": row.get("status_label_supported") is True,
                        "start": start, "lifecycle": lifecycle}
            evidence.pop("excluded_rows")  # Root diagnostic, not order-dependent issue evidence.
            if row.get("identity_valid") is not True:
                # The helper owns this identity, but this row cannot establish work.
                # Preserve a per-issue gap; unrelated qualified rows stay usable.
                evidence.update(error="unqualified-ledger-row", status_label=None,
                                start=None, lifecycle=None)
            batch["issues"].append({"repo_id": key, "number": number,
                                    "work_evidence": [evidence], "source_ref": "xyz_work"})
            batch["repos"].append({"id": key, "source_refs": ["xyz_work"]})
        if len(report["issues"]) > 2000:
            source["error"] = "issue-cap"
    grouped = {}
    for row in batch["issues"]:
        key = (row["repo_id"], row["number"])
        if key not in grouped:
            grouped[key] = {**row, "work_evidence": []}
        grouped[key]["work_evidence"].extend(row["work_evidence"])
    batch["issues"] = sorted(grouped.values(), key=lambda row: (not any(e["status_label"] == "in-progress" and e["start"] for e in row["work_evidence"]), row["repo_id"], row["number"]))[:2000]
    incomplete = (len(roots) > 4 or len(grouped) > 2000 or not sources
                  or any(s["error"] or not s["supported"] for s in sources))
    finalized = {s["id"]: s for s in sources}
    for row in batch["issues"]:
        for evidence in row["work_evidence"]:
            evidence["root_error"] = finalized[evidence["id"]]["error"]
            evidence["error"] = evidence.get("error") or evidence["root_error"]
            evidence["roots_complete"] = not incomplete
    batch["repos"] = [{"id": key, "source_refs": ["xyz_work"]} for key in sorted({row["repo_id"] for row in batch["issues"]})]
    batch["source"].update({"availability": "ok" if any(s["supported"] and not s["error"] for s in sources) else "unavailable",
                            "coverage": "partial", "observed_through": None,
                            "roots": sources, "error": "issue-cap" if len(grouped) > 2000 else "root-cap" if len(roots) > 4 else
                            "source-unavailable-or-unsupported" if not sources or any(s["error"] or not s["supported"] for s in sources) else None})
    return batch


def work_references(text: str, repo: str | None = None) -> dict[str, list[int]]:
    """Keep issue and PR intent separate; qualified URLs must match this repo."""
    refs: dict[str, list[int]] = {"issues": [], "prs": []}
    pattern = r"https?://[^\s<>]+|(?:(?P<kind>PR|pull\s+request)\s*#?|(GH-|#|\bissue\s+))(?P<number>\d+)\b"
    for match in re.finditer(pattern, text, re.I):
        if match.group("number"):
            kind = "prs" if match.group("kind") else "issues"
            number = int(match.group("number"))
        else:
            try:
                url = urlsplit(match.group().rstrip(').,]'))
            except ValueError:
                continue
            parts = url.path.strip('/').split('/')
            if url.hostname != "github.com" or len(parts) < 4 or parts[2] not in {"issues", "pull"} or not parts[3].isdigit():
                continue
            target = repo_key('/'.join(parts[:2]))
            if repo and target != repo and not (repo.startswith('local/') and target.rsplit('/', 1)[-1] == repo.rsplit('/', 1)[-1]):
                continue
            kind, number = ("prs" if parts[2] == "pull" else "issues"), int(parts[3])
        if number > 0 and number not in refs[kind]:
            refs[kind].append(number)
    return refs


def issue_numbers(text: str, repo: str | None = None) -> list[int]:
    return work_references(text, repo)["issues"]


def _available(batch: dict[str, Any], observed: str | None, coverage: str = "partial") -> dict[str, Any]:
    batch["source"].update({"availability": "ok", "coverage": coverage, "observed_through": observed, "error": None})
    return batch


def read_clio(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
    caps = ("agent_intent", "repo_attention")
    batch = empty_batch("clio", caps, "unavailable")
    if not config.clio_jsonl:
        return batch
    path = safe_path(config.clio_jsonl)
    newest: str | None = None
    repos: dict[str, dict[str, Any]] = {}
    lanes: dict[tuple[str, str], dict[str, Any]] = {}
    rows = bounded_text(path).splitlines()[-MAX_RECORDS:]
    parsed = []
    for line in rows:
        deadline_guard(deadline)
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict) and parse_time(row.get("timestamp")):
            parsed.append(row)
    for row in sorted(parsed, key=lambda row: datetime.fromisoformat(parse_time(row["timestamp"]).replace("Z", "+00:00")).timestamp()):
        deadline_guard(deadline)
        occurred = parse_time(row.get("timestamp"))
        key = repo_key(row.get("repo"))
        prompt_full = " ".join(str(row.get("prompt") or "").split())
        prompt = prompt_full[:240]
        if not occurred or not key or not prompt_full:
            continue
        newest = max(newest or occurred, occurred)
        repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [str(row.get("repo"))], "source_refs": ["clio"]})
        refs = work_references(prompt_full, key)
        referenced_issues = refs["issues"]
        session = str(row.get("session_id") or row.get("id") or occurred)
        lane_key = (key, session)
        prior = lanes.get(lane_key, {})
        if prior:
            latest = datetime.fromisoformat(occurred.replace("Z", "+00:00")).timestamp()
            previous = datetime.fromisoformat(prior["last_prompt_at"].replace("Z", "+00:00")).timestamp()
            if (latest - previous) > 7200:
                prior = {}
        has_reference = bool(referenced_issues or refs["prs"])
        lane = {
            "id": f"clio:{key}:{session}",
            "repo_id": key, "issue": referenced_issues[0] if referenced_issues else None,
            "issues": referenced_issues if has_reference else prior.get("issues", []),
            "prs": refs["prs"] if has_reference else prior.get("prs", []),
            "agent": row.get("agent") or prior.get("agent") or "Agent", "session_id": row.get("session_id"),
            "branch": row.get("branch") or prior.get("branch"), "device": row.get("machine") or prior.get("device"),
            "task": prompt, "last_prompt_at": occurred, "last_progress_at": None,
            "confidence": "inferred", "source_ref": "clio",
            "issue_context_at": occurred if has_reference else prior.get("issue_context_at"),
        }
        lane["issue"] = next(iter(lane["issues"]), None)
        lanes[lane_key] = lane
    batch["repos"] = list(repos.values())
    batch["lanes"] = list(lanes.values())
    return _available(batch, newest, "partial")


def read_git_pulse(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
    caps = ("commits", "device_coverage")
    batch = empty_batch("git_pulse", caps, "unavailable")
    if not config.git_pulse_dir:
        return batch
    root = safe_path(config.git_pulse_dir)
    files = sorted(root.glob("pulse-*.md"), key=lambda p: p.stat().st_mtime, reverse=True)[:50]
    repos: dict[str, dict[str, Any]] = {}
    newest: str | None = None
    for path in files:
        path = safe_path(path, root)
        for line in bounded_text(path).splitlines()[-MAX_RECORDS:]:
            deadline_guard(deadline)
            fields = line.strip().strip("`|").split("\t")
            if len(fields) != 6 or not fields[0].isdigit():
                continue
            epoch, timestamp, raw_repo, branch, sha, subject = fields
            occurred = parse_time(timestamp) or parse_time(epoch)
            key = repo_key(raw_repo)
            if not occurred or not key:
                continue
            newest = max(newest or occurred, occurred)
            repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [raw_repo], "source_refs": ["git_pulse"]})
            batch["events"].append({
                "id": f"pulse:{path.name}:{epoch}:{sha}", "repo_id": key,
                "kind": "commit", "summary": subject[:240], "issues": issue_numbers(subject, key), "occurred_at": occurred,
                "observed_at": datetime_from_mtime(path), "sha": sha, "branch": branch,
                "source_ref": "git_pulse", "confidence": "attested",
            })
    batch["repos"] = list(repos.values())
    return _available(batch, newest, "partial")


def datetime_from_mtime(path: Path) -> str:
    from datetime import datetime, timezone
    return datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat().replace("+00:00", "Z")


def _sqlite_rows(conn: sqlite3.Connection, sql: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
    conn.row_factory = sqlite3.Row
    return [dict(row) for row in conn.execute(sql, params).fetchall()]


def read_rebalance(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
    caps = ("projects", "issues", "pull_requests", "checks", "next_actions", "commits")
    batch = empty_batch("rebalance", caps, "unavailable")
    if not config.rebalance_db:
        return batch
    path = safe_path(config.rebalance_db)
    conn = sqlite3.connect(f"{path.resolve().as_uri()}?mode=ro", uri=True, timeout=1)
    try:
        conn.execute("PRAGMA query_only=ON")
        remaining = max(0, int((deadline - time.monotonic()) * 1000))
        conn.execute(f"PRAGMA busy_timeout={min(250, remaining)}")
        conn.set_progress_handler(lambda: int(time.monotonic() >= deadline), 1000)
        deadline_guard(deadline)
        repos: dict[str, dict[str, Any]] = {}
        project_keys: dict[str, list[str]] = {}
        for row in _sqlite_rows(conn, "SELECT name, status, summary, repos_json FROM project_registry LIMIT 100"):
            try:
                aliases = json.loads(row.get("repos_json") or "[]")
            except json.JSONDecodeError:
                aliases = []
            for alias in aliases if isinstance(aliases, list) else []:
                raw = alias.get("repo") if isinstance(alias, dict) else alias
                key = repo_key(raw)
                if key:
                    repos.setdefault(key, {"id": key, "name": row["name"] or repo_name(key), "summary": row.get("summary"), "aliases": [str(raw)], "source_refs": ["rebalance"]})
                    project_keys.setdefault(str(row["name"]), []).append(key)
        action_rows = _sqlite_rows(conn, "SELECT computed_at,payload_json FROM ranked_next_actions ORDER BY computed_at DESC LIMIT 1")
        if action_rows:
            try:
                ranked = json.loads(action_rows[0]["payload_json"]).get("ranked", [])
            except (json.JSONDecodeError, AttributeError):
                ranked = []
            for action in ranked[:100] if isinstance(ranked, list) else []:
                keys = project_keys.get(str(action.get("project")), [])
                if len(keys) == 1:
                    repos[keys[0]].setdefault("next_actions", []).append({
                        "title": str(action.get("title") or "")[:240], "why": str(action.get("why") or "")[:240],
                        "person": action.get("person"), "computed_at": action_rows[0]["computed_at"], "source_ref": "rebalance",
                    })
        link_rows = _sqlite_rows(conn, """
            SELECT repo_full_name,source_number,target_number,link_kind
              FROM github_links
             WHERE source_type='pull_request' AND target_type='issue'
             ORDER BY CASE link_kind WHEN 'closes' THEN 0 ELSE 1 END, target_number
             LIMIT 5000
        """)
        pr_issues: dict[tuple[str, int], list[int]] = {}
        for link in link_rows:
            key = repo_key(link["repo_full_name"])
            if key and link["link_kind"] == "closes":
                pr_issues.setdefault((key, int(link["source_number"])), []).append(int(link["target_number"]))
        columns = {row[1] for row in conn.execute("PRAGMA table_info(github_items)")}
        optional = "," + ",".join(name if name in columns else f"NULL AS {name}" for name in ("labels_json", "state_reason"))
        select = """
            SELECT repo_full_name,item_type,number,title,state,is_draft,is_merged,head_sha,
                   mergeable_state,review_decision,check_status,html_url,updated_at,fetched_at
        """ + optional + " FROM github_items "
        established = []
        keys = config.established_issues[:2000]
        for offset in range(0, len(keys), 200):
            deadline_guard(deadline)
            chunk = keys[offset:offset + 200]
            predicates = " OR ".join("(lower(repo_full_name)=? AND number=?)" for _ in chunk)
            params = tuple(value for repo, number in chunk for value in (repo.removeprefix("github.com/"), number))
            established.extend(_sqlite_rows(conn, select + f" WHERE item_type='issue' AND ({predicates}) LIMIT 2000", params))
        items = established + _sqlite_rows(conn, select + """
             WHERE item_type='issue' OR state='open'
             ORDER BY COALESCE(updated_at,fetched_at) DESC LIMIT 2000
        """)
        deadline_guard(deadline)
        wanted = set(keys)
        # Exact lookup can return case-variant duplicate cache rows. Keep the
        # newest observation, while retaining quiet established work before caps.
        def observed(row):
            try:
                parsed = datetime.fromisoformat((row.get("fetched_at") or "").replace("Z", "+00:00"))
                return parsed.timestamp() if parsed.tzinfo else float("-inf")
            except (ValueError, TypeError, OverflowError):
                return float("-inf")
        items.sort(key=observed, reverse=True)
        items.sort(key=lambda row: (repo_key(row["repo_full_name"]), row["number"]) not in wanted)
        latest = {}
        conflicting = set()
        for row in items:
            identity = (repo_key(row["repo_full_name"]), row["item_type"], row["number"])
            signature = (row["state"], row.get("labels_json"), row.get("state_reason"), native_item_identity(row))
            prior = latest.setdefault(identity, (observed(row), signature))
            if observed(row) == prior[0] and signature != prior[1]:
                conflicting.add(identity)
        seen = set()
        for row in items:
            deadline_guard(deadline)
            key = repo_key(row["repo_full_name"])
            if not key:
                continue
            identity = (key, row["item_type"], row["number"])
            if identity in seen:
                continue
            seen.add(identity)
            repo = repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [], "source_refs": ["rebalance"]})
            if row["repo_full_name"] not in repo["aliases"]:
                repo["aliases"].append(row["repo_full_name"])
            target = batch["prs"] if row["item_type"] == "pull_request" else batch["issues"]
            normalized = {"repo_id": key, "number": row["number"], "title": row["title"], "state": row["state"], "updated_at": row["updated_at"], "fetched_at": row["fetched_at"], "url": row["html_url"], "source_ref": "rebalance"}
            try:
                labels = json.loads(row["labels_json"]) if row["labels_json"] is not None else None
            except (ValueError, TypeError):
                labels = None
            normalized.update({"labels": labels if isinstance(labels, list) and all(isinstance(label, str) for label in labels) else None,
                               "native_conflict": identity in conflicting,
                               "state_reason": row["state_reason"], "native_identity_valid": native_item_identity(row),
                               "native_max_age_seconds": config.native_max_age_seconds})
            if row["item_type"] == "pull_request":
                normalized.update({k: row[k] for k in ("is_draft", "is_merged", "head_sha", "mergeable_state", "review_decision", "check_status")})
                title_issues = issue_numbers(row["title"] or "", key)
                closing_issues = pr_issues.get((repo_key(row["repo_full_name"]), int(row["number"])), [])
                normalized["issues"] = closing_issues or title_issues
                normalized["issue"] = next(iter(normalized["issues"]), None)
                normalized["issue_basis"] = "Cached closing link" if closing_issues else "PR title (inferred)"
            target.append(normalized)
        for row in _sqlite_rows(conn, "SELECT repo_full_name,sha,message,committed_at,html_url FROM github_direct_commits ORDER BY committed_at DESC LIMIT 2000"):
            key = canonical_github_key(row["repo_full_name"], row["html_url"])
            occurred = parse_time(row["committed_at"])
            if key and occurred:
                repo = repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [], "source_refs": ["rebalance"]})
                if row["repo_full_name"] not in repo["aliases"]:
                    repo["aliases"].append(row["repo_full_name"])
                batch["events"].append({"id": f"rebalance:{key}:{row['sha']}", "repo_id": key, "kind": "commit", "summary": row["message"] or "Commit", "issues": issue_numbers((row["message"] or "").split("\n", 1)[0], key), "occurred_at": occurred, "observed_at": occurred, "sha": row["sha"], "url": row["html_url"], "source_ref": "rebalance", "confidence": "attested"})
        batch["repos"] = list(repos.values())
        observed = max((str(item.get("fetched_at") or "") for item in items), default=None) or utc_now()
        return _available(batch, observed, "partial")
    finally:
        conn.set_progress_handler(None, 0)
        conn.close()


def _read_json_source(connector_id: str, path: Path | None, capabilities: tuple[str, ...], deadline: float) -> dict[str, Any]:
    batch = empty_batch(connector_id, capabilities, "unavailable")
    if not path:
        return batch
    resolved = safe_path(path)
    deadline_guard(deadline)
    payload = json.loads(bounded_text(resolved))
    if not isinstance(payload, dict) or int(payload.get("schema_version", 0)) != 1:
        raise ValueError("unsupported or missing schema_version")
    truncated = False
    for field in ("repos", "checkouts", "issues", "prs", "lanes", "events"):
        value = payload.get(field, [])
        if not isinstance(value, list):
            raise ValueError(f"{field} must be a list")
        truncated = truncated or len(value) > MAX_RECORDS
        for item in value[:MAX_RECORDS]:
            if not isinstance(item, dict):
                raise ValueError(f"{field} record must be an object")
            identity = "id" if field == "repos" else "repo_id"
            if not isinstance(item.get(identity), str) or not item[identity]:
                raise ValueError(f"{field} record needs {identity}")
            for key, part in item.items():
                if key in {"aliases", "source_refs"}:
                    valid = isinstance(part, list) and all(isinstance(v, str) for v in part)
                elif key in {"issues", "prs"}:
                    valid = isinstance(part, list) and all(type(v) is int for v in part)
                elif key == "next_actions":
                    valid = isinstance(part, list) and all(isinstance(v, dict) and all(not isinstance(x, (dict, list)) for x in v.values()) for v in part)
                else:
                    valid = not isinstance(part, (dict, list))
                if not valid:
                    raise ValueError(f"invalid {field}.{key}")
        batch[field] = value[:MAX_RECORDS]
    observed = parse_time(payload.get("observed_through") or payload.get("generated_at"))
    return _available(batch, observed, "partial" if truncated else str(payload.get("coverage") or "partial"))


def read_topology(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
    return _read_json_source("topology", config.topology_json, ("checkouts",), deadline)


def read_continuity(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
    return _read_json_source("continuity", config.continuity_json, ("milestones", "handoffs"), deadline)


REGISTRY: dict[str, Connector] = {
    "xyz_work": read_xyz_work,
    "rebalance": read_rebalance,
    "clio": read_clio,
    "git_pulse": read_git_pulse,
    "topology": read_topology,
    "continuity": read_continuity,
}


def read_connectors(config: ConnectorConfig, deadline: float) -> list[dict[str, Any]]:
    batches: list[dict[str, Any]] = []
    for connector_id, reader in REGISTRY.items():
        if connector_id not in config.enabled:
            batches.append(empty_batch(connector_id, (), "disabled"))
            continue
        try:
            batch = reader(config, deadline)
            batches.append(batch)
            if connector_id == "xyz_work":
                config = replace(config, established_issues=tuple(sorted({
                    (row["repo_id"], row["number"]) for row in batch["issues"]
                    if any(e.get("status_label") == "in-progress" and e.get("start") for e in row["work_evidence"])
                })))
        except (OSError, ValueError, TypeError, AttributeError, sqlite3.Error, json.JSONDecodeError, TimeoutError) as exc:
            batches.append(empty_batch(connector_id, (), "unavailable", type(exc).__name__))
    return batches
