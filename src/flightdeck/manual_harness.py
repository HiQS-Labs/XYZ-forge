"""Manual, experimental Flightdeck fixture harness. Deliberately not a CI entry point."""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import subprocess
import threading
import urllib.request
import tempfile
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

from .aggregate import FlightdeckAggregator
from .contract import ConnectorConfig
from .connectors import work_references, read_clio
from .server import FlightdeckServer

REPO = "BinoidCBD/LTVera-Pandas"
REPO_ID = "github.com/binoidcbd/ltvera-pandas"


NOW = datetime(2026, 9, 8, 20, tzinfo=timezone.utc)


def instant(minutes_ago: int) -> str:
    return (NOW - timedelta(minutes=minutes_ago)).isoformat().replace("+00:00", "Z")


def write_fixtures(root: Path) -> ConnectorConfig:
    clio = root / "clio.jsonl"
    prompts = [
        {
            "timestamp": instant(182), "repo": REPO, "agent": "codex", "session_id": "lane-440",
            "branch": "fix/gh-440", "machine": "fixture-studio",
            "prompt": "x" * 260 + f" https://github.com/{REPO}/issues/440 and make a PR",
        },
        {
            "timestamp": instant(18), "repo": REPO, "agent": "codex", "session_id": "lane-440",
            "prompt": "Continue smoke testing the current branch",
        },
        {
            "timestamp": instant(12), "repo": REPO, "agent": "agy", "session_id": "lane-many",
            "prompt": "Review GH-421, #390, and https://github.com/BinoidCBD/LTVera-Pandas/issues/332",
        },
    ]
    for minutes in (130, 80):
        prompts.append({"timestamp": instant(minutes), "repo": REPO, "session_id": "lane-440", "prompt": "Continue validation"})
    prompts.append({"timestamp": instant(10), "repo": REPO, "session_id": "lane-review", "agent": "claude-code", "prompt": f"QA https://github.com/{REPO}/pull/442"})
    # Interleaved exports deliberately append earlier prompts after the latest one.
    clio.write_text("".join(json.dumps(row) + "\n" for row in prompts), encoding="utf-8")

    db = root / "rebalance.db"
    conn = sqlite3.connect(db)
    conn.executescript("""
        CREATE TABLE project_registry(name TEXT, status TEXT, summary TEXT, repos_json TEXT);
        CREATE TABLE ranked_next_actions(computed_at TEXT, payload_json TEXT);
        CREATE TABLE github_links(repo_full_name TEXT, source_type TEXT, source_number INTEGER, target_type TEXT, target_number INTEGER, link_kind TEXT);
        CREATE TABLE github_items(repo_full_name TEXT, item_type TEXT, number INTEGER, title TEXT, state TEXT, is_draft INTEGER, is_merged INTEGER, head_sha TEXT, mergeable_state TEXT, review_decision TEXT, check_status TEXT, html_url TEXT, updated_at TEXT, fetched_at TEXT);
        CREATE TABLE github_direct_commits(repo_full_name TEXT, sha TEXT, message TEXT, committed_at TEXT, html_url TEXT);
    """)
    conn.execute("INSERT INTO project_registry VALUES(?,?,?,?)", ("LTVera Pandas", "active", "Manual harness: several agents and issues", json.dumps([REPO])))
    conn.execute("INSERT INTO ranked_next_actions VALUES(?,?)", (instant(1), json.dumps({"ranked": [{"project": "LTVera Pandas", "title": "Validate all visible issue lanes"}]})))
    for number, title in ((440, "Commit review fixes"), (421, "Draft reconciler"), (390, "Repeat-rate calibration"), (332, "Calibration query")):
        conn.execute("INSERT INTO github_items VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (REPO, "issue", number, title, "open", 0, 0, None, None, None, None, f"https://github.com/{REPO}/issues/{number}", instant(180), instant(2)))
    conn.execute("INSERT INTO github_items VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (REPO, "pull_request", 442, "Fix issue 440", "open", 0, 0, "abc123", "clean", "REVIEW_REQUIRED", "success", f"https://github.com/{REPO}/pull/442", instant(8), instant(2)))
    conn.execute("INSERT INTO github_links VALUES(?,?,?,?,?,?)", (REPO, "pull_request", 442, "issue", 83, "closes"))
    conn.execute("INSERT INTO github_direct_commits VALUES(?,?,?,?,?)", (REPO, "abc123", "fix: exercise manual harness", instant(7), f"https://github.com/{REPO}/commit/abc123"))
    conn.commit(); conn.close()

    pulse = root / "pulse"; pulse.mkdir()
    pulse.joinpath("pulse-fixture.md").write_text(f"1\t{instant(7)}\t{REPO}\tfix/gh-440\tabc123\tfix: exercise manual harness\n", encoding="utf-8")
    topology = root / "topology.json"
    topology.write_text(json.dumps({"schema_version": 1, "coverage": "complete", "generated_at": instant(1), "repos": [], "checkouts": [
        {"repo_id": REPO_ID, "device": "fixture-studio", "path": "/fixture/LTVera-Pandas", "kind": "full_clone", "branch": "development"},
        {"repo_id": REPO_ID, "device": "fixture-studio", "path": "/fixture/LTVera-Pandas-440", "kind": "full_clone", "branch": "fix/gh-440"},
    ]}), encoding="utf-8")
    continuity = root / "continuity.json"
    continuity.write_text(json.dumps({"schema_version": 1, "coverage": "complete", "generated_at": instant(1), "events": [
        {"id": "milestone-440", "repo_id": REPO_ID, "kind": "milestone", "summary": "Smoke tests passed", "occurred_at": instant(5), "observed_at": instant(4), "issue": 440, "source_ref": "continuity", "confidence": "attested"}
    ]}), encoding="utf-8")
    return ConnectorConfig(db, clio, pulse, topology, continuity, frozenset(("rebalance", "clio", "git_pulse", "topology", "continuity")))


def verify(snapshot: dict) -> None:
    repo = next(item for item in snapshot["repos"] if item["id"] == REPO_ID)
    lane = next(item for item in repo["lanes"] if item["session_id"] == "lane-440")
    assert lane["issues"] == [440], lane
    assert {421, 390, 332}.issubset({number for item in repo["lanes"] for number in item.get("issues", [])})
    review = next(item for item in repo["lanes"] if item["session_id"] == "lane-review")
    assert review["prs"] == [442], review
    assert repo["checkout_count"] == 2
    assert len(repo["prs"]) == 1 and repo["prs"][0]["issue"] == 83
    assert len(repo["events"]) == 2, "repo/SHA deduplication failed"
    assert all(source["availability"] == "ok" for source in snapshot["sources"])
    assert any(item["kind"] == "milestone" and item.get("issue") == 440 for item in repo["events"])


def verify_intent_boundaries(root: Path) -> None:
    assert work_references("#440 https://github.com/elsewhere/repo/issues/99 PR #442 https://[bad", REPO_ID) == {"issues": [440], "prs": [442]}
    # No new reference after a gap must not revive an unrelated old task.
    rows = [
        {"timestamp": instant(300), "repo": REPO, "session_id": "gap", "prompt": "GH-999"},
        {"timestamp": instant(10), "repo": REPO, "session_id": "gap", "prompt": "Start something else"},
        {"timestamp": instant(80), "repo": REPO, "session_id": "topic", "prompt": "GH-901"},
        {"timestamp": instant(10), "repo": REPO, "session_id": "topic", "prompt": "Switch to PR #442"},
    ]
    path = root / "boundaries.jsonl"
    path.write_text("\n".join(json.dumps(row) for row in rows))
    config = ConnectorConfig(None, path, None, None, None, frozenset({"clio"}))
    lanes = read_clio(config, time.monotonic() + 2)["lanes"]
    assert len(lanes) == 2
    assert all(not lane["issues"] for lane in lanes), lanes
    assert next(lane for lane in lanes if lane["session_id"] == "topic")["prs"] == [442]


def main(argv: list[str] | None = None) -> int:
    global NOW
    parser = argparse.ArgumentParser(description="Run the manual Flightdeck fixture harness (never CI)")
    parser.add_argument("--check", action="store_true", help="validate fixtures and exit without serving")
    parser.add_argument("--port", type=int, default=8770)
    args = parser.parse_args(argv)
    with tempfile.TemporaryDirectory(prefix="flightdeck-manual-") as tmp:
        config = write_fixtures(Path(tmp))
        verify_intent_boundaries(Path(tmp))
        verify(FlightdeckAggregator(config).snapshot())
        server = FlightdeckServer(("127.0.0.1", 0), config)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        before = {path: path.read_bytes() for path in Path(tmp).rglob("*") if path.is_file()}
        thread.start()
        try:
            base = f"http://127.0.0.1:{server.server_port}"
            with urllib.request.urlopen(base + "/flightdeck.json", timeout=10) as response:
                snapshot = json.load(response)
            verify(snapshot)
            for asset in ("/flightdeck/", "/flightdeck/app.js", "/flightdeck/issue-context.mjs"):
                with urllib.request.urlopen(base + asset, timeout=5) as response:
                    assert response.read(), asset
                    if asset.endswith(".mjs"):
                        assert "javascript" in response.headers["Content-Type"]
            subprocess.run(["node", str(Path(__file__).with_name("manual_checks.mjs"))],
                           input=json.dumps({"snapshot": snapshot, "now": NOW.timestamp() * 1000}), text=True, check=True, env={**os.environ, "TZ": "UTC"})
            assert all(path.read_bytes() == value for path, value in before.items()), "consumer wrote to source"
        finally:
            server.shutdown(); server.server_close(); thread.join(timeout=2)
        print("flightdeck manual harness: fixture checks passed")
        if args.check:
            return 0
        NOW = datetime.now(timezone.utc)
        preview = Path(tmp) / "preview"
        preview.mkdir()
        config = write_fixtures(preview)
        server = FlightdeckServer(("127.0.0.1", args.port), config)
        print(f"open http://127.0.0.1:{server.server_port}/flightdeck/ (Ctrl-C to stop)")
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            return 0
        finally:
            server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
