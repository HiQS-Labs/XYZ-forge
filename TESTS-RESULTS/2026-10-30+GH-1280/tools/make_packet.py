#!/usr/bin/env python3
"""Assemble the GH-1280 long-run contract review packet (one Markdown file, hash-bound)."""
import hashlib, json, os, sys

SP = os.path.dirname(os.path.realpath(__file__))
OUT = os.path.join(SP, "gh1280-long-contract-packet.md")


def sha(p):
    return hashlib.sha256(open(os.path.join(SP, p), "rb").read()).hexdigest()


def fence(p, lang=""):
    body = open(os.path.join(SP, p)).read()
    return "#### `%s` (sha256 `%s`)\n\n````%s\n%s\n````\n" % (p, sha(p), lang, body.rstrip())


ctl = json.load(open(os.path.join(SP, "ev/03-controls.json")))
tb = json.load(open(os.path.join(SP, "ev/05-track-b.json")))
ta = json.load(open(os.path.join(SP, "ev/04-trackA-report-from-telemetry.json")))
gen4 = json.load(open(os.path.join(SP, "out-smoke/campaign-report.json")))

parts = [open(os.path.join(SP, "packet-head.md")).read(), "\n## Smoke results (machine summaries)\n"]
parts.append("### Controls (step 3) — elapsed %ss\n" % ctl["elapsed_s"])
parts += ["- %s: **%s** — expect: %s" % (c["control"], "PASS" if c["pass"] else "FAIL", c["expect"]) for c in ctl["controls"]]
parts.append("\nSandbox red step detail: rc=%s stderr tail: `%s`\n" % (
    ctl["controls"][3]["steps"][0]["rc"], ctl["controls"][3]["steps"][0]["stderr"].strip().splitlines()[-1][:200]))
parts.append("Gate-boundary control detail: `%s`\n" % json.dumps(ctl["controls"][4]["steps"][1]))
parts.append("Canary control detail: `%s`\n" % json.dumps(ctl["controls"][5]["steps"][1]))
parts.append("### Track B (step 5)\n")
parts += ["- B1 %s: %s (rcs %s; status keys match %s; ledger queries match %s)" % (
    r["case"], "PASS" if r.get("pass") else "FAIL", r.get("rcs"), r.get("status_match"), r.get("queries_match")) for r in tb["B1"]]
parts.append("- B2: %s rows before %s after %s" % ("PASS" if tb["B2"]["pass"] else "FAIL", tb["B2"]["rows_before"], tb["B2"]["rows_after"]))
b3 = tb["B3"]
parts.append("- B3: %s rcs %s receipts %s quarantined %s slot1 tool runs before/after recovery %s/%s slot1 outputs %s survivors %s\n" % (
    "PASS" if b3["pass"] else "FAIL", b3["rcs"], b3["receipts"], b3["status"].get("quarantined"),
    b3["slot1_tool_runs_before_recovery"], b3["slot1_tool_runs_after_recovery"], b3["slot1_output_files"], b3["surviving_pids"]))
parts.append("### Track A (step 4) — supervisor tracker rebuilt from the complete telemetry\n")
parts.append("- events %s, stop `%s`, streak at end %s, distinct signatures %s, gated %s" % (
    ta["events"], ta.get("stop_reason"), ta["streak_at_end"], len(ta["signatures"]), ta["gated_events"]))
parts.append("- counts `%s`" % json.dumps(ta["counts"]))
parts.append("- per target `%s`" % json.dumps(ta["per_target"]))
parts.append("- supervisor-classified candidates: %d" % len(ta["candidates"]))
parts.append("- gen4 report: mutations %s batches %s counts %s host_violations %s contamination %s errors %s\n" % (
    gen4["mutations"], gen4["batches"], gen4["counts"], gen4["host_violations"], gen4["contamination_events"], gen4["errors"]))
for f in ["ev/09-verify.json", "ev/09-verify-v5-stdout.json", "ev/supervisor-r1-fixes.diff", "ev/06-replay-control.txt", "ev/06-candidate-status-creates-state.txt", "ev/07-final-checks.txt",
          "ev/timeline.txt", "ev/00-identity.txt"]:
    parts.append(fence(f, "text"))
parts.append("\n## Frozen long-run contract and tooling (bound by sha256)\n")
for f in ["contract-long.json", "contract-long-replay.json", "targets-long.json", "profile-long.sb"]:
    parts.append(fence(f, "json" if f.endswith(".json") else ""))
for f in ["supervisor.py", "prep.py", "stub.py", "controls.py", "track_b.py", "verify.py"]:
    parts.append(fence(f, "python"))
open(OUT, "w").write("\n".join(parts) + "\n")
print(OUT, hashlib.sha256(open(OUT, "rb").read()).hexdigest())
