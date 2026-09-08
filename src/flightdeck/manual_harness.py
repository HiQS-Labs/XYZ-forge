"""Manual, experimental Flightdeck fixture harness. Deliberately not a CI entry point."""

from __future__ import annotations

import argparse
import json
import sqlite3
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from .aggregate import FlightdeckAggregator
from .contract import ConnectorConfig
from .server import FlightdeckServer

REPO = "BinoidCBD/LTVera-Pandas"
REPO_ID = "github.com/binoidcbd/ltvera-pandas"


def instant(minutes_ago: int) -> str:
    return (datetime.now(timezone.utc) - timedelta(minutes=minutes_ago)).isoformat().replace("+00:00", "Z")


def write_fixtures(root: Path) -> ConnectorConfig:
    clio = root / "clio.jsonl"
    prompts = [
        {
            "timestamp": instant(42), "repo": "LTVera-Pandas", "agent": "codex", "session_id": "lane-440",
            "branch": "fix/gh-440", "machine": "fixture-studio",
            "prompt": "x" * 260 + f" https://github.com/{REPO}/issues/440 and make a PR",
        },
        {
            "timestamp": instant(18), "repo": "LTVera-Pandas", "agent": "codex", "session_id": "lane-440",
            "prompt": "Continue smoke testing the current branch",
        },
        {
            "timestamp": instant(12), "repo": "LTVera-Pandas", "agent": "agy", "session_id": "lane-many",
            "prompt": "Review GH-421, #390, and https://github.com/BinoidCBD/LTVera-Pandas/issues/332",
        },
    ]
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
        conn.execute("INSERT INTO github_items VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (REPO, "issue", number, title, "open", 0, 0, None, None, None, None, f"https://github.com/{REPO}/issues/{number}", instant(15), instant(2)))
    conn.execute("INSERT INTO github_items VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (REPO, "pull_request", 442, "Fix issue 440", "open", 0, 0, "abc123", "clean", "REVIEW_REQUIRED", "success", f"https://github.com/{REPO}/pull/442", instant(8), instant(2)))
    conn.execute("INSERT INTO github_links VALUES(?,?,?,?,?,?)", (REPO, "pull_request", 442, "issue", 440, "closes"))
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
    assert repo["checkout_count"] == 2
    assert len(repo["prs"]) == 1 and repo["prs"][0]["issue"] == 440
    assert any(item["kind"] == "milestone" and item.get("issue") == 440 for item in repo["events"])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run the manual Flightdeck fixture harness (never CI)")
    parser.add_argument("--check", action="store_true", help="validate fixtures and exit without serving")
    parser.add_argument("--port", type=int, default=8770)
    args = parser.parse_args(argv)
    with tempfile.TemporaryDirectory(prefix="flightdeck-manual-") as tmp:
        config = write_fixtures(Path(tmp))
        verify(FlightdeckAggregator(config).snapshot())
        print("flightdeck manual harness: fixture checks passed")
        if args.check:
            return 0
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
