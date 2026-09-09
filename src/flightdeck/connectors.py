from __future__ import annotations

import json
import re
import sqlite3
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Callable
from urllib.parse import urlsplit

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
    conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True, timeout=1)
    try:
        conn.execute("PRAGMA query_only=ON")
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
        items = _sqlite_rows(conn, """
            SELECT repo_full_name,item_type,number,title,state,is_draft,is_merged,head_sha,
                   mergeable_state,review_decision,check_status,html_url,updated_at,fetched_at
              FROM github_items
             WHERE item_type='issue' OR state='open'
             ORDER BY COALESCE(updated_at,fetched_at) DESC LIMIT 2000
        """)
        for row in items:
            deadline_guard(deadline)
            key = canonical_github_key(row["repo_full_name"], row["html_url"])
            if not key:
                continue
            repo = repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [], "source_refs": ["rebalance"]})
            if row["repo_full_name"] not in repo["aliases"]:
                repo["aliases"].append(row["repo_full_name"])
            target = batch["prs"] if row["item_type"] == "pull_request" else batch["issues"]
            normalized = {"repo_id": key, "number": row["number"], "title": row["title"], "state": row["state"], "updated_at": row["updated_at"], "fetched_at": row["fetched_at"], "url": row["html_url"], "source_ref": "rebalance"}
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
    for field in ("repos", "checkouts", "issues", "prs", "lanes", "events"):
        value = payload.get(field, [])
        if not isinstance(value, list):
            raise ValueError(f"{field} must be a list")
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
    return _available(batch, observed, str(payload.get("coverage") or "partial"))


def read_topology(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
    return _read_json_source("topology", config.topology_json, ("checkouts",), deadline)


def read_continuity(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
    return _read_json_source("continuity", config.continuity_json, ("milestones", "handoffs"), deadline)


REGISTRY: dict[str, Connector] = {
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
            batches.append(reader(config, deadline))
        except (OSError, ValueError, TypeError, AttributeError, sqlite3.Error, json.JSONDecodeError, TimeoutError) as exc:
            batches.append(empty_batch(connector_id, (), "unavailable", type(exc).__name__))
    return batches
