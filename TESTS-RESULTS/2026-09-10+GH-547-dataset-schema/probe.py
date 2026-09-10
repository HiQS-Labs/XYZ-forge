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
    swe_info = json.loads(get("https://datasets-server.huggingface.co/info?dataset=" + urllib.parse.quote(SWE, safe="")))
    swe_rows = json.loads(get("https://datasets-server.huggingface.co/first-rows?dataset=" + urllib.parse.quote(SWE, safe="") + "&config=default&split=train"))
    hf_meta = json.loads(get("https://huggingface.co/api/datasets/" + SWE))

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
            "repository_license_declared": None,
            "dataset_server": swe_info["dataset_info"]["default"],
            "bounded_sample_rows": len(row_shapes),
            "bounded_sample_fail_counts": dict(fail_counts),
            "sample_shapes": row_shapes,
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
