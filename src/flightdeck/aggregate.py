from __future__ import annotations

import hashlib
import json
import time
from collections import defaultdict
from datetime import datetime, timezone
from typing import Any

from . import SCHEMA_VERSION
from .connectors import read_connectors
from .contract import ConnectorConfig, repo_key, repo_name, utc_now

MAX_REPOS = 100
MAX_ITEMS = 2_000
MAX_EVENTS = 5_000
MAX_BYTES = 2 * 1024 * 1024


def _timestamp(value: Any) -> float:
    if not value:
        return 0.0
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).timestamp()
    except ValueError:
        return 0.0


def _merge_repo(current: dict[str, Any], incoming: dict[str, Any]) -> None:
    for field in ("name", "summary"):
        if incoming.get(field) and not current.get(field):
            current[field] = incoming[field]
    for field in ("aliases", "source_refs"):
        current[field] = sorted(set(current.get(field, [])) | set(incoming.get(field, [])))
    actions = current.setdefault("next_actions", [])
    seen = {item.get("title") for item in actions}
    actions.extend(item for item in incoming.get("next_actions", []) if item.get("title") not in seen)


def _classify_pr(pr: dict[str, Any], source_ok: bool) -> tuple[str, str]:
    if not source_ok or not pr.get("head_sha") or not pr.get("fetched_at"):
        return "needs-qa", "Verification data incomplete"
    if pr.get("mergeable_state") in {"conflicting", "dirty"} or pr.get("check_status") in {"failure", "failed", "error"} or pr.get("review_decision") == "CHANGES_REQUESTED":
        return "blocked", "Cached head has a blocker"
    if pr.get("is_draft"):
        return "needs-qa", "Draft"
    if pr.get("check_status") in {"pending", "queued", None, ""}:
        return "needs-qa", "Checks or requirements need verification"
    if pr.get("review_decision") in {"REVIEW_REQUIRED", "review_required"}:
        return "review", "Review requested"
    if pr.get("mergeable_state") in {"clean", "mergeable", "has_hooks"} and pr.get("check_status") in {"success", "passed"} and pr.get("review_decision") in {"APPROVED", "approved"}:
        return "ready", "Cached candidate; verify before merge"
    return "needs-qa", "Readiness unknown"


class FlightdeckAggregator:
    def __init__(self, config: ConnectorConfig):
        self.config = config
        self.boot_id = hashlib.sha256(f"{time.time_ns()}".encode()).hexdigest()[:12]
        self.sequence = 0

    def snapshot(self, timeout: float = 6.0) -> dict[str, Any]:
        deadline = time.monotonic() + timeout
        batches = read_connectors(self.config, deadline)
        repos: dict[str, dict[str, Any]] = {}
        events: dict[str, dict[str, Any]] = {}
        lanes: dict[str, dict[str, Any]] = {}
        issues: dict[tuple[str, int], dict[str, Any]] = {}
        prs: dict[tuple[str, int], dict[str, Any]] = {}
        checkouts: dict[tuple[str, str, str], dict[str, Any]] = {}
        source_ok = {b["connector"]: b["source"]["availability"] == "ok" for b in batches}
        github_by_slug: dict[str, set[str]] = defaultdict(set)
        alias_targets: dict[str, set[str]] = defaultdict(set)
        for batch in batches:
            for incoming in batch["repos"]:
                key = incoming.get("id")
                if isinstance(key, str) and key.startswith("github.com/"):
                    github_by_slug[key.rsplit("/", 1)[-1]].add(key)
                    for alias in incoming.get("aliases", []):
                        normalized = repo_key(alias)
                        if normalized and normalized != key:
                            alias_targets[normalized].add(key)

        def canonical(raw: Any) -> Any:
            if not isinstance(raw, str):
                return raw
            explicit = alias_targets.get(raw, set())
            if len(explicit) == 1:
                return next(iter(explicit))
            if not raw.startswith("local/"):
                return raw
            candidates = github_by_slug.get(raw.rsplit("/", 1)[-1], set())
            if len(candidates) == 1:
                candidate = next(iter(candidates))
                redirected = alias_targets.get(candidate, set())
                return next(iter(redirected)) if len(redirected) == 1 else candidate
            return raw

        for batch in batches:
            for incoming in batch["repos"][:MAX_REPOS]:
                incoming = dict(incoming)
                key = canonical(incoming.get("id"))
                if not key:
                    continue
                incoming["id"] = key
                current = repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [], "source_refs": []})
                _merge_repo(current, incoming)
            for incoming in batch["events"][:MAX_EVENTS]:
                incoming = dict(incoming)
                key = canonical(incoming.get("repo_id"))
                if not key:
                    continue
                incoming["repo_id"] = key
                repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [], "source_refs": []})
                identity = f"{key}:{incoming.get('sha')}" if incoming.get("sha") else str(incoming.get("id"))
                prior = events.get(identity)
                if not prior or _timestamp(incoming.get("observed_at")) > _timestamp(prior.get("observed_at")):
                    events[identity] = incoming
            for incoming in batch["lanes"][:MAX_ITEMS]:
                incoming = dict(incoming)
                key = canonical(incoming.get("repo_id"))
                if not key:
                    continue
                incoming["repo_id"] = key
                repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [], "source_refs": []})
                identity = str(incoming.get("id") or f"{key}:{incoming.get('agent')}:{incoming.get('task')}")
                prior = lanes.get(identity)
                if not prior or _timestamp(incoming.get("last_prompt_at")) > _timestamp(prior.get("last_prompt_at")):
                    lanes[identity] = incoming
            for incoming in batch["issues"][:MAX_ITEMS]:
                incoming = dict(incoming)
                key, number = canonical(incoming.get("repo_id")), incoming.get("number")
                if key and isinstance(number, int):
                    incoming["repo_id"] = key
                    repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [], "source_refs": []})
                    issues[(key, number)] = incoming
            for incoming in batch["prs"][:MAX_ITEMS]:
                incoming = dict(incoming)
                key, number = canonical(incoming.get("repo_id")), incoming.get("number")
                if key and isinstance(number, int):
                    incoming["repo_id"] = key
                    repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [], "source_refs": []})
                    state, reason = _classify_pr(incoming, source_ok.get(str(incoming.get("source_ref")), False))
                    prs[(key, number)] = {**incoming, "readiness": state, "readiness_reason": reason}
            for incoming in batch["checkouts"][:MAX_ITEMS]:
                incoming = dict(incoming)
                key = canonical(incoming.get("repo_id"))
                path = incoming.get("path") or incoming.get("name")
                if key and path:
                    incoming["repo_id"] = key
                    repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [], "source_refs": []})
                    checkouts[(key, str(incoming.get("device") or "unknown"), str(path))] = incoming

        by_repo: dict[str, dict[str, list[dict[str, Any]]]] = defaultdict(lambda: defaultdict(list))
        for group, values in (("events", events.values()), ("lanes", lanes.values()), ("issues", issues.values()), ("prs", prs.values()), ("checkouts", checkouts.values())):
            for item in values:
                by_repo[str(item["repo_id"])][group].append(item)

        output_repos: list[dict[str, Any]] = []
        detail_caps = {"events": 100, "lanes": 30, "issues": 100, "prs": 100, "checkouts": 100}
        detail_truncated = False
        for key, repo in repos.items():
            groups = by_repo[key]
            for name in detail_caps:
                group = groups[name]
                group.sort(key=lambda item: _timestamp(item.get("occurred_at") or item.get("last_prompt_at") or item.get("updated_at")), reverse=True)
                if len(group) > detail_caps[name]:
                    detail_truncated = True
                    groups[name] = group[:detail_caps[name]]
            progress = [event for event in groups["events"] if event.get("kind") in {"commit", "review", "check", "milestone", "lifecycle"}]
            repo.update({name: groups[name] for name in detail_caps})
            repo["last_progress_at"] = progress[0].get("occurred_at") if progress else None
            repo["last_intent_at"] = groups["lanes"][0].get("last_prompt_at") if groups["lanes"] else None
            repo["known_checkout_count"] = len(groups["checkouts"])
            repo["checkout_count"] = len(groups["checkouts"]) if any(b["connector"] == "topology" and b["source"]["coverage"] == "complete" for b in batches) else None
            output_repos.append(repo)

        output_repos.sort(key=lambda repo: max(_timestamp(repo.get("last_progress_at")), _timestamp(repo.get("last_intent_at"))), reverse=True)
        self.sequence += 1
        snapshot = {
            "schema_version": SCHEMA_VERSION,
            "generated_at": utc_now(),
            "snapshot_id": f"{self.boot_id}:{self.sequence}",
            "sources": [batch["source"] | {"capabilities": batch["capabilities"]} for batch in batches],
            "repos": output_repos[:MAX_REPOS],
            "coverage": "partial" if any(batch["source"]["coverage"] != "complete" for batch in batches) else "complete",
            "truncated": len(output_repos) > MAX_REPOS or detail_truncated,
        }
        encoded = json.dumps(snapshot, separators=(",", ":")).encode()
        while len(encoded) > MAX_BYTES and snapshot["repos"]:
            snapshot["repos"].pop()
            snapshot["truncated"] = True
            snapshot["coverage"] = "partial"
            encoded = json.dumps(snapshot, separators=(",", ":")).encode()
        return snapshot
