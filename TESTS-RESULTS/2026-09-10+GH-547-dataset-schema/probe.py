#!/usr/bin/env python3
import csv
import gzip
import hashlib
import io
import json
import re
import sys
import tarfile
import tempfile
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

OUT = Path(__file__).resolve().parent
SWE = "SWE-Gym/MoatlessTools-Agent-Verifier-Train-Data"
SWE_REV = "57a05d234f92268307d6db677094e0b33d62c15e"
TRAJ = "SWE-Gym/OpenHands-Sampled-Trajectories"
TRAJ_REV = "baf3a4e4bff514d48ddc08a93a2ade5c126212c7"
NL_TEST = "https://tickettagger.blob.core.windows.net/datasets/nlbse23-issue-classification-test.csv.tar.gz"


def get(url, binary=False):
    req = urllib.request.Request(url, headers={"User-Agent": "xyz-gh547-schema-probe/1"})
    with urllib.request.urlopen(req, timeout=60) as response:
        data = response.read()
    return data if binary else data.decode("utf-8")


def digest(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def main():
    started = datetime.now(timezone.utc)
    csv.field_size_limit(16 * 1024 * 1024)
    swe_info = json.loads(get("https://datasets-server.huggingface.co/info?dataset=" + urllib.parse.quote(SWE, safe="")))
    swe_rows = json.loads(get("https://datasets-server.huggingface.co/first-rows?dataset=" + urllib.parse.quote(SWE, safe="") + "&config=default&split=train"))
    hf_meta = json.loads(get("https://huggingface.co/api/datasets/" + SWE))
    traj_meta = json.loads(get("https://huggingface.co/api/datasets/" + TRAJ))
    traj_info = json.loads(get("https://datasets-server.huggingface.co/info?dataset=" + urllib.parse.quote(TRAJ, safe="")))
    traj_rows = json.loads(get("https://datasets-server.huggingface.co/rows?dataset=" + urllib.parse.quote(TRAJ, safe="") + "&config=default&split=train.raw&offset=0&length=2"))
    swe_repo = json.loads(get("https://api.github.com/repos/SWE-Gym/SWE-Gym"))
    nlbse_repo = json.loads(get("https://api.github.com/repos/nlbse2023/issue-report-classification"))

    row_shapes = []
    fail_counts = Counter()
    for item in swe_rows["rows"][:5]:
        row = item["row"]
        messages = row.get("messages", [])
        fail_counts[str(row.get("fail"))] += 1
        row_shapes.append({
            "message_count": len(messages),
            "roles": [m.get("role") for m in messages],
            "content_lengths": [len(m.get("content", "")) for m in messages],
            "content_sha256": [digest(m.get("content", "")) for m in messages],
            "has_instance_id": bool(row.get("instance_id")),
            "has_exp_name": bool(row.get("exp_name")),
            "fail": row.get("fail"),
        })

    tawos_meta = json.loads(get("https://api.figshare.com/v2/articles/21308124"))
    tawos_schema_text = get("https://raw.githubusercontent.com/SOLAR-group/TAWOS/main/TAWOS_Database_Schema_Creation_Script.sql")
    tables = {}
    for name, body in re.findall(r"CREATE TABLE `([^`]+)` \((.*?)\n\)", tawos_schema_text, re.S):
        tables[name] = re.findall(r"^\s*`([^`]+)`\s+", body, re.M)

    with tempfile.TemporaryDirectory(prefix="gh547-nlbse-") as td:
        archive = Path(td) / "test.tar.gz"
        archive.write_bytes(get(NL_TEST, binary=True))
        with tarfile.open(archive, "r:gz") as tf:
            members = [m for m in tf.getmembers() if m.isfile()]
            if len(members) != 1:
                raise RuntimeError(f"expected one NLBSE member, found {len(members)}")
            fh = tf.extractfile(members[0])
            if fh is None:
                raise RuntimeError("could not read NLBSE CSV member")
            reader = csv.DictReader(io.TextIOWrapper(fh, encoding="utf-8", errors="replace", newline=""))
            labels = Counter()
            samples = []
            rows = 0
            for row in reader:
                rows += 1
                label = row.get("labels") or row.get("label") or ""
                labels[label] += 1
                if len(samples) < 5:
                    samples.append({k: {"present": bool(v), "length": len(v or ""), "sha256": digest(v or "")} for k, v in row.items()})
            nlbse = {
                "source_repository_revision": nlbse_repo.get("pushed_at"),
                "source_repository_license": (nlbse_repo.get("license") or {}).get("spdx_id"),
                "linked_dataset_license_separately_declared": False,
                "archive_bytes": archive.stat().st_size,
                "member_name_sha256": digest(members[0].name),
                "member_bytes": members[0].size,
                "columns": reader.fieldnames,
                "rows": rows,
                "label_counts": dict(sorted(labels.items())),
                "sample_shapes": samples,
            }

    result = {
        "schema_version": "gh547-dataset-schema-probe@1",
        "retrieved_at_utc": datetime.now(timezone.utc).isoformat(),
        "nlbse": nlbse,
        "swe_gym": {
            "dataset": SWE,
            "revision": hf_meta.get("sha"),
            "revision_matches_pin": hf_meta.get("sha") == SWE_REV,
            "dataset_metadata_license": swe_info["dataset_info"]["default"].get("license") or None,
            "code_repository_license": (swe_repo.get("license") or {}).get("spdx_id"),
            "dataset_server": swe_info["dataset_info"]["default"],
            "bounded_sample_rows": len(row_shapes),
            "bounded_sample_fail_counts": dict(fail_counts),
            "sample_shapes": row_shapes,
            "task_b_assessment": "verifier patch conversations; not chronological action trajectories",
        },
        "swe_gym_trajectory": {
            "dataset": TRAJ,
            "revision": traj_meta.get("sha"),
            "revision_matches_pin": traj_meta.get("sha") == TRAJ_REV,
            "dataset_metadata_license": traj_info["dataset_info"]["default"].get("license") or None,
            "split": traj_info["dataset_info"]["default"]["splits"]["train.raw"],
            "features": traj_info["dataset_info"]["default"]["features"],
            "sample_shapes": [{
                "message_count": len(x["row"].get("messages", [])),
                "roles": [m.get("role") for m in x["row"].get("messages", [])],
                "tool_call_names": [c.get("function", {}).get("name") for m in x["row"].get("messages", []) for c in (m.get("tool_calls") or [])],
                "resolved": x["row"].get("resolved"),
                "has_test_result": x["row"].get("test_result") is not None,
                "message_content_sha256": [digest(m.get("content") or "") for m in x["row"].get("messages", [])],
            } for x in traj_rows["rows"]],
        },
        "tawos": {
            "article_id": tawos_meta["id"],
            "version": tawos_meta["version"],
            "license": tawos_meta["license"],
            "files": [{"name": f["name"], "size": f["size"], "md5": f["computed_md5"]} for f in tawos_meta["files"]],
            "tables": tables,
            "representative_rows": "not sampled; full 637.55 MB archive required",
        },
    }
    payload = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if not nlbse["rows"] or not row_shapes or not traj_rows["rows"] or not tables:
        raise RuntimeError("empty source evidence cannot pass the schema probe")
    if hf_meta.get("sha") != SWE_REV:
        raise RuntimeError("SWE-Gym revision moved from the frozen pin")
    if traj_meta.get("sha") != TRAJ_REV:
        raise RuntimeError("SWE-Gym trajectory revision moved from the frozen pin")
    (OUT / "results.json").write_text(payload)
    elapsed = (datetime.now(timezone.utc) - started).total_seconds()
    (OUT / "runtime.log").write_text(f"status=completed\nelapsed_seconds={elapsed:.3f}\nstdout_bytes={len(payload.encode())}\n")
    provenance = {
        "utc": datetime.now(timezone.utc).isoformat(),
        "command": "python3 probe.py",
        "protocol_sha256": hashlib.sha256((OUT / "PROTOCOL.md").read_bytes()).hexdigest(),
        "probe_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "results_sha256": hashlib.sha256(payload.encode()).hexdigest(),
        "status": "completed",
        "raw_text_published": False,
    }
    (OUT / "provenance.jsonl").write_text(json.dumps(provenance, sort_keys=True) + "\n")
    print(payload, end="")


if __name__ == "__main__":
    import urllib.parse
    try:
        main()
    except Exception as exc:
        print(f"probe failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        raise
