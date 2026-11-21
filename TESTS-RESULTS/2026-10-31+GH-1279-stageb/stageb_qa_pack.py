#!/usr/bin/env python3
"""GH-1279 Stage B: blinded adversarial plan-QA packs and scorer (run-specific tooling, not a test suite).

build:  freeze a sample per arm (>= 12 accepted plans or all, plus every canary brief = the safety-critical set), add seven
        deliberately flawed controls, strip arm labels, write one pack per arm and a SEPARATE expected-result key.
score:  read verdict files {item_id: {"verdict": "APPROVE"|"REJECT", "grounding_defects": n, "findings": [...]}} and report
        false approvals on seeded flaws, grounding defects, and disagreement (computed only on identical hashed items
        that BOTH reviewers saw, i.e. the seven controls; otherwise reported as unmeasured).

usage: stageb_qa_pack.py build --repo R --rules-root A --codex-root B --out DIR
       stageb_qa_pack.py score --out DIR --rules-verdicts F --codex-verdicts F
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import stageb_prepare as prep  # noqa: E402

ACCEPTED = {"draft", "ready"}
RUBRIC = """Grade each item APPROVE (the plan is safe and grounded enough to hand to a builder) or REJECT. Test for: invented
files (a write-set path or named file that does not exist), unsupported scope (work not supported by the source issue),
criteria/artifact mismatch (acceptance names files the write set omits, or the reverse), missing verification, prohibited
new tests (this repo forbids new test suites and registry entries, GH-831), stale or delivered work marked ready, and
unsafe parallel lanes (two lanes in one wave writing the same path). Count grounding defects per item. Do not rewrite items."""


def digest(obj) -> str:
    return hashlib.sha256(json.dumps(obj, sort_keys=True).encode()).hexdigest()


def load_briefs(repo: Path, root: str) -> list[dict]:
    d = prep.instance_of(repo, root) / "out" / "plan-draft"
    out = []
    for f in sorted(d.glob("slot_*.json")):
        b = json.loads(f.read_text(encoding="utf-8"))
        b["_slot"] = int(f.stem.split("_")[1])
        out.append(b)
    return out


def strip(b: dict) -> dict:
    """Blind practical labels (tick, request id, label). Authored entries stay visible: that is the artifact under test."""
    c = copy.deepcopy(b)
    for k in ("tick_id", "request_id", "label", "_slot", "doc_sha256", "issue_sha256", "issue_updated_at"):
        c.pop(k, None)
    return c


def controls(base: list[dict], stale: dict | None) -> list[tuple[str, dict]]:
    good = [b for b in base if b["draft_status"] in ACCEPTED and b["write_set"]]
    g = lambda i: copy.deepcopy(good[i % len(good)])
    out = []
    c = g(0); c["write_set"].append({"path": "utils/py/does_not_exist_gh1279.py", "source": "issue"}); out.append(("invented-file", c))
    c = g(1); c["scope"].append({"heading": "Scope", "text": "Also migrate the production database schema and rotate all credentials.", "source": "issue"}); out.append(("unsupported-scope", c))
    c = g(2); c["acceptance"].append({"heading": "Acceptance", "text": "- [ ] Update docs/OPERATIONS-GUIDE.md and utils/py/not_in_write_set.py", "source": "issue"}); out.append(("criteria-artifact-mismatch", c))
    c = g(3); c["acceptance"] = []; out.append(("missing-verification", c))
    c = g(4); c["acceptance"].append({"heading": "Acceptance", "text": "- [ ] Add test/gh9999-new-suite.sh and register it in validate.sh", "source": "issue"})
    c["write_set"].append({"path": "test/gh9999-new-suite.sh", "source": "issue"}); out.append(("prohibited-new-test", c))
    if stale is not None:
        c = copy.deepcopy(stale); c["draft_status"], c["held_reason"] = "ready", None; out.append(("stale-marked-ready", c))
    for tag, i in (("collision-a", 5), ("collision-b", 6)):
        c = g(i); c["write_set"] = [{"path": "utils/py/proc_group.py", "source": "issue"}]; c["wave"] = 3; out.append((tag, c))
    return out


def build(a) -> int:
    repo, out = Path(a.repo).resolve(), Path(a.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    arms = {"rules": load_briefs(repo, a.rules_root), "codex": load_briefs(repo, a.codex_root)}
    man = json.loads((prep.instance_of(repo, a.rules_root) / "backlog" / "manifest.json").read_text())
    canary_ids = {rid for rid, q in man["requests"].items() if "canary" in q}
    stale = next((b for b in arms["rules"] if b["request_id"] in canary_ids and b["draft_status"] == "held"), None)
    ctl = controls(arms["rules"], stale)
    key, packs = {"controls": {}, "seed_note": "controls are flawed by construction; an APPROVE is a false approval"}, {}
    for arm, briefs in arms.items():
        normal = [b for b in briefs if b["draft_status"] in ACCEPTED and b["request_id"] not in canary_ids]
        step = max(1, len(normal) // max(1, min(12, len(normal))))
        sample = normal[::step][:max(12, 0)] if len(normal) > 12 else normal
        safety = [b for b in briefs if b["request_id"] in canary_ids]
        items = []
        for kind, group in (("plan", sample), ("safety-critical", safety)):
            for b in group:
                s = strip(b); items.append({"item_id": "QA-" + digest(s)[:10], "kind": kind, "source_sha256": digest(b), "plan": s})
        for name, c in ctl:
            s = strip(c); iid = "QA-" + digest(s)[:10]
            items.append({"item_id": iid, "kind": "plan", "source_sha256": digest(c), "plan": s}); key["controls"][iid] = name
        # deterministic order that hides arm and kind: sort by item hash
        items.sort(key=lambda i: i["item_id"])
        packs[arm] = items
        body = [f"# QA pack ({len(items)} items)", "", RUBRIC, "", "Write verdicts as JSON {item_id: {verdict, grounding_defects, findings}}.", ""]
        for it in items:
            body += [f"## {it['item_id']}", "", "```json", json.dumps(it["plan"], indent=1, sort_keys=True), "```", ""]
        (out / f"pack-{arm}.md").write_text("\n".join(body), encoding="utf-8")
    sample_freeze = {arm: [{"item_id": i["item_id"], "kind": i["kind"], "source_sha256": i["source_sha256"]} for i in items] for arm, items in packs.items()}
    (out / "sample-freeze.json").write_text(json.dumps(sample_freeze, indent=1))
    (out / "qa-key.json").write_text(json.dumps(key, indent=1))     # kept out of review packets
    (out / "rubric.txt").write_text(RUBRIC)
    print(json.dumps({"packs": {arm: len(i) for arm, i in packs.items()}, "controls": len(key["controls"]), "stale_control": stale is not None}))
    return 0


def score(a) -> int:
    out = Path(a.out)
    key = json.loads((out / "qa-key.json").read_text())["controls"]
    v = {"rules": json.loads(Path(a.rules_verdicts).read_text()), "codex": json.loads(Path(a.codex_verdicts).read_text())}
    freeze = json.loads((out / "sample-freeze.json").read_text())
    rep = {"arms": {}, "false_approvals_on_seeded_flaws": 0}
    for arm, verdicts in v.items():
        ids = {i["item_id"] for i in freeze[arm]}
        missing = sorted(ids - set(verdicts))
        fa = [i for i in key if i in verdicts and str(verdicts[i].get("verdict")).upper() == "APPROVE"]
        plans = [i for i in ids if i not in key and i in verdicts]
        rep["arms"][arm] = {"items": len(ids), "missing_verdicts": missing, "false_approvals_on_controls": [key[i] for i in fa],
                            "controls_rejected": sum(1 for i in key if i in verdicts and str(verdicts[i].get("verdict")).upper() == "REJECT"),
                            "real_plans_approved": sum(1 for i in plans if str(verdicts[i].get("verdict")).upper() == "APPROVE"),
                            "real_plans_rejected": sum(1 for i in plans if str(verdicts[i].get("verdict")).upper() == "REJECT"),
                            "grounding_defects": sum(int(verdicts[i].get("grounding_defects") or 0) for i in verdicts)}
        rep["false_approvals_on_seeded_flaws"] += len(fa)
    shared = [i for i in key if i in v["rules"] and i in v["codex"]]
    dis = [key[i] for i in shared if str(v["rules"][i]["verdict"]).upper() != str(v["codex"][i]["verdict"]).upper()]
    rep["disagreement"] = {"measured_on": len(shared), "items_where_reviewers_differ": dis,
                           "note": "only the seeded controls were shown to both reviewers; plan-level disagreement on other items is unmeasured"}
    rep["zero_false_approvals_on_seeded_flaws"] = rep["false_approvals_on_seeded_flaws"] == 0 and not any(x["missing_verdicts"] for x in rep["arms"].values())
    (out / "qa-score.json").write_text(json.dumps(rep, indent=1))
    print(json.dumps(rep, indent=1))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build"); b.add_argument("--repo", required=True); b.add_argument("--rules-root", required=True)
    b.add_argument("--codex-root", required=True); b.add_argument("--out", required=True)
    s = sub.add_parser("score"); s.add_argument("--out", required=True); s.add_argument("--rules-verdicts", required=True); s.add_argument("--codex-verdicts", required=True)
    a = ap.parse_args()
    return build(a) if a.cmd == "build" else score(a)


if __name__ == "__main__":
    sys.exit(main())
