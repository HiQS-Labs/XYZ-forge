from __future__ import annotations

import json
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from pathlib import Path
from unittest.mock import patch

from src.flightdeck.aggregate import FlightdeckAggregator, _classify_pr
from src.flightdeck.connectors import REGISTRY, canonical_github_key, issue_numbers, read_clio, read_connectors, read_git_pulse
from src.flightdeck.contract import ConnectorConfig
from src.flightdeck.tokens import OUTPUT, audit_css, render
from src.flightdeck.server import FlightdeckServer


def config(root: Path, enabled: frozenset[str]) -> ConnectorConfig:
    return ConnectorConfig(
        rebalance_db=None,
        clio_jsonl=root / "clio.jsonl",
        git_pulse_dir=root / "pulse",
        topology_json=root / "topology.json",
        continuity_json=root / "continuity.json",
        enabled=enabled,
    )


class ConnectorTests(unittest.TestCase):
    def test_issue_parser_accepts_urls_and_multiple_explicit_references(self) -> None:
        self.assertEqual(
            issue_numbers("Start https://github.com/BinoidCBD/LTVera-Pandas/issues/440, then GH-421 and #390"),
            [440, 421, 390],
        )

    def test_clio_extracts_issue_beyond_display_summary_limit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            prompt = "x" * 260 + " https://github.com/BinoidCBD/LTVera-Pandas/issues/440"
            root.joinpath("clio.jsonl").write_text(json.dumps({
                "timestamp": "2026-09-08T15:00:00Z", "repo": "LTVera-Pandas",
                "session_id": "s1", "prompt": prompt,
            }) + "\n", encoding="utf-8")
            lane = read_clio(config(root, frozenset({"clio"})), time.monotonic() + 1)["lanes"][0]
            self.assertEqual(lane["issues"], [440])
            self.assertEqual(len(lane["task"]), 240)

    def test_item_url_repairs_a_stale_pre_rename_repo_slug(self) -> None:
        self.assertEqual(
            canonical_github_key(
                "HiQS-Labs/aegis-sleuth-slack-bot",
                "https://github.com/HiQS-Labs/AEGIS-Sleuth-Slackbot/issues/181",
            ),
            "github.com/hiqs-labs/aegis-sleuth-slackbot",
        )

    def test_registry_is_the_expected_static_first_party_set(self) -> None:
        self.assertEqual(set(REGISTRY), {"rebalance", "clio", "git_pulse", "topology", "continuity"})

    def test_clio_reads_intent_without_counting_progress(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            root.joinpath("clio.jsonl").write_text(json.dumps({
                "timestamp": "2026-09-08T15:00:00Z", "repo": "HiQS-Labs/XYZ-forge",
                "branch": "feat/flight", "machine": "studio", "agent": "codex",
                "session_id": "s1", "prompt": "Continue GH-494 dashboard",
            }) + "\n", encoding="utf-8")
            batch = read_clio(config(root, frozenset({"clio"})), time.monotonic() + 1)
            self.assertEqual(batch["source"]["availability"], "ok")
            self.assertEqual(batch["lanes"][0]["issue"], 494)
            self.assertEqual(batch["lanes"][0]["issues"], [494])
            self.assertIsNone(batch["lanes"][0]["last_progress_at"])
            self.assertEqual(batch["repos"][0]["id"], "github.com/hiqs-labs/xyz-forge")

    def test_clio_retains_issue_context_within_session(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            rows = [
                {"timestamp": "2026-09-08T15:00:00Z", "repo": "XYZ-forge", "agent": "codex", "session_id": "s1", "prompt": "Plan issue 494"},
                {"timestamp": "2026-09-08T15:10:00Z", "repo": "XYZ-forge", "agent": "codex", "session_id": "s1", "prompt": "Now build it"},
            ]
            root.joinpath("clio.jsonl").write_text("".join(json.dumps(row) + "\n" for row in rows), encoding="utf-8")
            batch = read_clio(config(root, frozenset({"clio"})), time.monotonic() + 1)
            self.assertEqual(len(batch["lanes"]), 1)
            self.assertEqual(batch["lanes"][0]["issue"], 494)
            self.assertEqual(batch["lanes"][0]["task"], "Now build it")

    def test_clio_drops_stale_issue_context_from_long_session(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            rows = [
                {"timestamp": "2026-09-08T10:00:00Z", "repo": "XYZ-forge", "agent": "codex", "session_id": "s1", "prompt": "Review issue 490"},
                {"timestamp": "2026-09-08T15:00:01Z", "repo": "XYZ-forge", "agent": "codex", "session_id": "s1", "prompt": "Start a different task"},
            ]
            root.joinpath("clio.jsonl").write_text("".join(json.dumps(row) + "\n" for row in rows), encoding="utf-8")
            batch = read_clio(config(root, frozenset({"clio"})), time.monotonic() + 1)
            self.assertIsNone(batch["lanes"][0]["issue"])

    def test_git_pulse_deduplicates_with_other_connector_in_aggregation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); pulse = root / "pulse"; pulse.mkdir()
            pulse.joinpath("pulse-studio.md").write_text(
                "1788879600\t2026-09-08T15:00:00Z\tHiQS-Labs/XYZ-forge\tfeat/flight\tabc1234\tBuild dashboard\n",
                encoding="utf-8",
            )
            batch = read_git_pulse(config(root, frozenset({"git_pulse"})), time.monotonic() + 1)
            self.assertEqual(len(batch["events"]), 1)
            self.assertEqual(batch["events"][0]["kind"], "commit")

    def test_each_connector_can_be_disabled_without_core_branching(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            batches = read_connectors(config(root, frozenset()), time.monotonic() + 1)
            self.assertEqual(len(batches), 5)
            self.assertTrue(all(batch["source"]["availability"] == "disabled" for batch in batches))
            snapshot = FlightdeckAggregator(config(root, frozenset())).snapshot()
            self.assertEqual(snapshot["repos"], [])
            self.assertEqual({source["id"] for source in snapshot["sources"]}, set(REGISTRY))

    def test_aggregator_keeps_remaining_connector_when_peer_fails(self) -> None:
        good = {
            "connector": "clio", "schema_version": 1, "capabilities": ["agent_intent"],
            "source": {"id": "clio", "availability": "ok", "coverage": "partial", "observed_through": "2026-09-08T15:00:00Z", "error": None},
            "repos": [{"id": "local/demo", "name": "Demo", "aliases": ["demo"], "source_refs": ["clio"]}],
            "lanes": [{"id": "s1", "repo_id": "local/demo", "agent": "codex", "task": "Continue", "last_prompt_at": "2026-09-08T15:00:00Z", "last_progress_at": None, "source_ref": "clio"}],
            "events": [], "issues": [], "prs": [], "checkouts": [],
        }
        failed = {**good, "connector": "rebalance", "source": {"id": "rebalance", "availability": "unavailable", "coverage": "unknown", "observed_through": None, "error": "offline"}, "repos": [], "lanes": []}
        with tempfile.TemporaryDirectory() as tmp, patch("src.flightdeck.aggregate.read_connectors", return_value=[failed, good]):
            snapshot = FlightdeckAggregator(config(Path(tmp), frozenset())).snapshot()
        self.assertEqual(snapshot["repos"][0]["name"], "Demo")
        self.assertEqual(snapshot["repos"][0]["lanes"][0]["agent"], "codex")
        self.assertEqual(snapshot["repos"][0]["issues"], [])
        self.assertEqual(snapshot["repos"][0]["prs"], [])

    def test_malformed_json_rows_leave_healthy_peer_available(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "clio.jsonl").write_text(json.dumps({"repo": "owner/demo", "prompt": "GH-42", "timestamp": "2026-09-08T15:00:00Z"}) + "\n")
            for bad in (None, {"id": []}, {"id": "local/demo", "aliases": [None]}, {"id": "local/demo", "next_actions": [None]}):
                with self.subTest(bad=bad):
                    (root / "topology.json").write_text(json.dumps({"schema_version": 1, "repos": [bad]}))
                    snapshot = FlightdeckAggregator(config(root, frozenset({"clio", "topology"}))).snapshot()
                    self.assertTrue(snapshot["repos"])
                    self.assertTrue(snapshot["repos"][0]["lanes"])
                    source = next(s for s in snapshot["sources"] if s["id"] == "topology")
                    self.assertEqual(source["availability"], "unavailable")

    def test_checkout_count_survives_display_cap_but_not_input_cap(self) -> None:
        from datetime import datetime, timezone
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for count, exact in ((101, 101), (5001, None)):
                payload = {"schema_version": 1, "coverage": "complete", "generated_at": datetime.now(timezone.utc).isoformat(),
                           "checkouts": [{"repo_id": "local/demo", "path": f"/fixture/{i}"} for i in range(count)]}
                (root / "topology.json").write_text(json.dumps(payload))
                repo = FlightdeckAggregator(config(root, frozenset({"topology"}))).snapshot()["repos"][0]
                self.assertEqual(len(repo["checkouts"]), 100)
                self.assertEqual(repo["checkout_count"], exact)
                self.assertGreater(repo["known_checkout_count"], 100)

    def test_cached_pr_without_policy_attestation_never_claims_ready(self) -> None:
        for fetched in ("2000-01-01T00:00:00Z", "2026-09-08T15:00:00Z"):
            for check in ("success", "failure"):
                pr = {"head_sha": "new", "check_head_sha": "old", "fetched_at": fetched,
                      "check_status": check, "review_decision": "APPROVED", "mergeable_state": "clean"}
                self.assertEqual(_classify_pr(pr, True)[0], "needs-qa")

    def test_partial_cache_basename_does_not_establish_identity(self) -> None:
        def batch(connector: str, key: str):
            return {
                "connector": connector, "schema_version": 1, "capabilities": [],
                "source": {"id": connector, "availability": "ok", "coverage": "partial", "observed_through": "2026-09-08T15:00:00Z", "error": None},
                "repos": [{"id": key, "name": "XYZ Forge", "aliases": [key], "source_refs": [connector]}],
                "lanes": [], "events": [], "issues": [], "prs": [], "checkouts": [],
            }
        with tempfile.TemporaryDirectory() as tmp, patch("src.flightdeck.aggregate.read_connectors", return_value=[
            batch("rebalance", "github.com/hiqs-labs/xyz-forge"), batch("clio", "local/xyz-forge")
        ]):
            snapshot = FlightdeckAggregator(config(Path(tmp), frozenset())).snapshot()
        self.assertEqual({repo["id"] for repo in snapshot["repos"]}, {"github.com/hiqs-labs/xyz-forge", "local/xyz-forge"})

    def test_explicit_stale_slug_alias_merges_after_repo_rename(self) -> None:
        def batch(connector: str, key: str, aliases: list[str]):
            return {
                "connector": connector, "schema_version": 1, "capabilities": [],
                "source": {"id": connector, "availability": "ok", "coverage": "partial", "observed_through": "2026-09-08T15:00:00Z", "error": None},
                "repos": [{"id": key, "name": "Aegis", "aliases": aliases, "source_refs": [connector]}],
                "lanes": [], "events": [], "issues": [], "prs": [], "checkouts": [],
            }
        with tempfile.TemporaryDirectory() as tmp, patch("src.flightdeck.aggregate.read_connectors", return_value=[
            batch("rebalance", "github.com/hiqs-labs/aegis-sleuth-slackbot", ["HiQS-Labs/aegis-sleuth-slack-bot"]),
            batch("registry", "github.com/hiqs-labs/aegis-sleuth-slack-bot", ["HiQS-Labs/aegis-sleuth-slack-bot"]),
            batch("clio", "local/aegis-sleuth-slack-bot", ["aegis-sleuth-slack-bot"]),
        ]):
            snapshot = FlightdeckAggregator(config(Path(tmp), frozenset())).snapshot()
        self.assertEqual({repo["id"] for repo in snapshot["repos"]}, {"github.com/hiqs-labs/aegis-sleuth-slackbot", "local/aegis-sleuth-slack-bot"})


class TokenTests(unittest.TestCase):
    def test_breadcrumbs_have_clickable_ancestors_and_current_page_semantics(self) -> None:
        html = Path("web/flightdeck/index.html").read_text(encoding="utf-8")
        js = Path("web/flightdeck/app.js").read_text(encoding="utf-8")
        self.assertIn('aria-label="Breadcrumb"', html)
        self.assertIn("button.addEventListener('click', () => navigate", js)
        self.assertIn("current.setAttribute('aria-current', 'page')", js)

    def test_generated_tokens_are_current_and_theme_keys_match(self) -> None:
        generated = render()
        self.assertGreater(len(generated), 500)
        self.assertEqual(OUTPUT.read_text(encoding="utf-8"), generated)
        self.assertIn(':root[data-theme="light"]', generated)

    def test_token_audit_rejects_raw_component_styling(self) -> None:
        css = Path("web/flightdeck/app.css").read_text(encoding="utf-8")
        self.assertEqual(audit_css(css), [])
        self.assertIn("raw color literal", audit_css(css + "\n.card { color: #fff; }"))
        self.assertIn("raw typography literal", audit_css(css + "\n.card { font-size: 13px; }"))


class ServerTests(unittest.TestCase):
    def test_loopback_server_serves_app_and_passive_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            server = FlightdeckServer(("127.0.0.1", 0), config(Path(tmp), frozenset()))
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            try:
                base = f"http://127.0.0.1:{server.server_port}"
                with urllib.request.urlopen(base + "/flightdeck.json", timeout=2) as response:
                    payload = json.load(response)
                    self.assertEqual(payload["schema_version"], 1)
                    self.assertEqual(payload["repos"], [])
                    self.assertIn("default-src 'self'", response.headers["Content-Security-Policy"])
                with urllib.request.urlopen(base + "/flightdeck/", timeout=2) as response:
                    self.assertIn(b"FLIGHTDECK", response.read())
                request = urllib.request.Request(base + "/flightdeck.json", headers={"Host": "example.com"})
                with self.assertRaises(urllib.error.HTTPError) as rejected:
                    urllib.request.urlopen(request, timeout=2)
                self.assertEqual(rejected.exception.code, 403)
                rejected.exception.close()
            finally:
                server.shutdown(); server.server_close(); thread.join(timeout=2)


if __name__ == "__main__":
    unittest.main()
