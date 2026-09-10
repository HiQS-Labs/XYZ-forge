#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import statistics
import subprocess
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

MAPPING = {
    "Bug": "bug_fix", "Build Failure": "bug_fix", "Problem Ticket": "bug_fix",
    "Incident": "bug_fix", "Public Security Vulnerability": "bug_fix",
    "Suggestion": "feature_enhancement", "Improvement": "feature_enhancement",
    "New Feature": "feature_enhancement", "Enhancement Request": "feature_enhancement",
    "Wish": "feature_enhancement", "Documentation": "documentation",
    "Investigation": "research_evaluation", "Test Task": "testing_validation",
    "Test": "testing_validation",
}


def sha(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def mysql_rows(socket, sql):
    cmd = ["mysql", "--no-defaults", "--batch", "--raw", "--skip-column-names",
           f"--socket={socket}", "tawos_cleaned", "-e", sql]
    out = subprocess.run(cmd, check=True, capture_output=True, text=True).stdout
    return [line.split("\t") for line in out.splitlines() if line]


def mysql_json(socket, sql):
    return [json.loads(row[0]) for row in mysql_rows(socket, sql)]


def quantiles(values):
    ordered = sorted(values)
    def at(p):
        return ordered[min(len(ordered) - 1, int((len(ordered) - 1) * p))]
    return {"min": ordered[0], "median": at(.5), "p90": at(.9), "p95": at(.95),
            "p99": at(.99), "max": ordered[-1]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--socket", required=True)
    ap.add_argument("--archive", required=True)
    ap.add_argument("--model", required=True)
    ap.add_argument("--private-review", required=True)
    args = ap.parse_args()
    here = Path(__file__).resolve().parent
    started = datetime.now(timezone.utc)

    archive = Path(args.archive)
    md5 = hashlib.md5(archive.read_bytes()).hexdigest()
    if md5 != "e9c5ecc7649d55f0cf2fb4efb5664494":
        raise RuntimeError("TAWOS archive MD5 mismatch")

    counts = dict(mysql_rows(args.socket, "SELECT 'issues',COUNT(*) FROM Issue UNION ALL SELECT 'projects',COUNT(*) FROM Project UNION ALL SELECT 'components',COUNT(*) FROM Component UNION ALL SELECT 'issue_components',COUNT(*) FROM Issue_Component UNION ALL SELECT 'change_logs',COUNT(*) FROM Change_Log"))
    counts = {k: int(v) for k, v in counts.items()}
    if counts["issues"] != 458232 or counts["projects"] != 39:
        raise RuntimeError(f"unexpected corpus identity: {counts}")

    types = {k: int(v) for k, v in mysql_rows(args.socket, "SELECT Type,COUNT(*) FROM Issue GROUP BY Type ORDER BY COUNT(*) DESC")}
    resolutions = {k: int(v) for k, v in mysql_rows(args.socket, "SELECT COALESCE(Resolution,'<NULL>'),COUNT(*) FROM Issue GROUP BY Resolution ORDER BY COUNT(*) DESC")}
    projects = {k: int(v) for k, v in mysql_rows(args.socket, "SELECT p.Project_Key,COUNT(*) FROM Issue i JOIN Project p ON p.ID=i.Project_ID GROUP BY p.ID,p.Project_Key ORDER BY COUNT(*) DESC")}
    years = {k: int(v) for k, v in mysql_rows(args.socket, "SELECT YEAR(Creation_Date),COUNT(*) FROM Issue GROUP BY YEAR(Creation_Date) ORDER BY YEAR(Creation_Date)")}
    length_buckets = {k: int(v) for k, v in mysql_rows(args.socket, "SELECT CASE WHEN CHAR_LENGTH(CONCAT_WS(' ',Title,Description_Text))<=4096 THEN '0-4096' WHEN CHAR_LENGTH(CONCAT_WS(' ',Title,Description_Text))<=16384 THEN '4097-16384' WHEN CHAR_LENGTH(CONCAT_WS(' ',Title,Description_Text))<=32768 THEN '16385-32768' ELSE '32769+' END,COUNT(*) FROM Issue GROUP BY 1 ORDER BY 1")}
    component_cardinality = {k: int(v) for k, v in mysql_rows(args.socket, "SELECT CASE WHEN c=0 THEN 'none' WHEN c=1 THEN 'one' ELSE 'multiple' END,COUNT(*) FROM (SELECT i.ID,COUNT(ic.Component_ID)c FROM Issue i LEFT JOIN Issue_Component ic ON ic.Issue_ID=i.ID GROUP BY i.ID)x GROUP BY 1")}
    fk_errors = mysql_rows(args.socket, "SELECT COUNT(*) FROM Issue i LEFT JOIN Project p ON p.ID=i.Project_ID WHERE p.ID IS NULL UNION ALL SELECT COUNT(*) FROM Issue_Component ic LEFT JOIN Issue i ON i.ID=ic.Issue_ID LEFT JOIN Component c ON c.ID=ic.Component_ID WHERE i.ID IS NULL OR c.ID IS NULL")
    fk_error_counts = [int(x[0]) for x in fk_errors]
    if any(fk_error_counts):
        raise RuntimeError(f"relational integrity errors: {fk_error_counts}")

    sample_sql = """WITH ranked AS (SELECT i.ID,p.Project_Key,i.Type,i.Resolution,i.Title,i.Description_Text,ROW_NUMBER() OVER(PARTITION BY i.Project_ID,i.Type ORDER BY SHA2(CONCAT(i.ID,':GH547'),256)) rn FROM Issue i JOIN Project p ON p.ID=i.Project_ID) SELECT JSON_OBJECT('id',ID,'project',Project_Key,'type',Type,'resolution',Resolution,'title',Title,'description',Description_Text) FROM ranked WHERE rn<=2"""
    review = mysql_json(args.socket, sample_sql)
    stress = mysql_json(args.socket, "SELECT JSON_OBJECT('id',i.ID,'project',p.Project_Key,'type',i.Type,'resolution',i.Resolution,'title',i.Title,'description',i.Description_Text) FROM Issue i JOIN Project p ON p.ID=i.Project_ID ORDER BY CHAR_LENGTH(CONCAT_WS(' ',i.Title,i.Description_Text)) DESC,i.ID LIMIT 100")
    if not review or not stress:
        raise RuntimeError("empty deterministic sample")

    private_path = Path(args.private_review)
    private_path.parent.mkdir(parents=True, exist_ok=True)
    with private_path.open("w") as f:
        for row in review:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    from transformers import AutoTokenizer
    tokenizer = AutoTokenizer.from_pretrained(args.model, local_files_only=True)
    def token_summary(rows):
        lengths = []
        public = []
        for row in rows:
            text = " ".join(x or "" for x in [row.get("title"), row.get("description")])
            n = len(tokenizer(text, truncation=False, add_special_tokens=True)["input_ids"])
            lengths.append(n)
            public.append({"record_sha256": sha(str(row["id"])), "text_sha256": sha(text),
                           "project": row["project"], "native_type": row["type"],
                           "mapped_purpose": MAPPING.get(row["type"]), "characters": len(text),
                           "tokens": n})
        return {"n": len(rows), "tokens": quantiles(lengths),
                "over_8192": sum(x > 8192 for x in lengths), "records": public}

    purpose_counts = Counter()
    unsupported = Counter()
    for native, n in types.items():
        if native in MAPPING:
            purpose_counts[MAPPING[native]] += n
        else:
            unsupported[native] += n
    mapped_n = sum(purpose_counts.values())

    result = {
        "schema_version": "gh547-tawos-qualification@1",
        "retrieved_at_utc": datetime.now(timezone.utc).isoformat(),
        "input": {"figshare_article": 21308124, "version": 1, "archive_bytes": archive.stat().st_size, "archive_md5": md5, "license": "Apache-2.0"},
        "integrity": {"counts": counts, "foreign_key_error_counts": fk_error_counts},
        "distributions": {"native_types": types, "resolutions": resolutions, "projects": projects, "years": years, "character_buckets": length_buckets, "component_cardinality": component_cardinality},
        "mapping": {"native_to_purpose": MAPPING, "purpose_counts": dict(purpose_counts), "mapped_n": mapped_n, "coverage": mapped_n / counts["issues"], "unsupported_native_types": dict(unsupported), "unsupported_n": sum(unsupported.values())},
        "review_sample": token_summary(review),
        "longest_100_stress": token_summary(stress),
        "private_review_manifest": {"path": str(private_path), "sha256": hashlib.sha256(private_path.read_bytes()).hexdigest(), "published": False},
        "gates": {
            "structural_pass": counts["issues"] == 458232 and counts["projects"] == 39 and not any(fk_error_counts),
            "token_pass": token_summary(review)["over_8192"] / len(review) < .01,
            "aggregate_coverage_pass": mapped_n / counts["issues"] >= .70,
            "mapped_class_floor_pass": all(n >= 500 for n in purpose_counts.values()),
            "label_quality_review": "pending independent adjudication",
        },
    }
    payload = json.dumps(result, indent=2, sort_keys=True) + "\n"
    (here / "results.json").write_text(payload)
    elapsed = (datetime.now(timezone.utc) - started).total_seconds()
    (here / "runtime.log").write_text(f"status=completed\nelapsed_seconds={elapsed:.3f}\nreview_sample_n={len(review)}\nstress_sample_n={len(stress)}\n")
    provenance = {"utc": datetime.now(timezone.utc).isoformat(), "command": "analyze_tawos.py --socket <local> --archive <cache> --model <pinned-cache> --private-review <cache>", "protocol_sha256": hashlib.sha256((here/'PROTOCOL.md').read_bytes()).hexdigest(), "runner_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), "results_sha256": hashlib.sha256(payload.encode()).hexdigest(), "private_review_sha256": result["private_review_manifest"]["sha256"], "status": "completed", "raw_text_published": False}
    (here / "provenance.jsonl").write_text(json.dumps(provenance, sort_keys=True) + "\n")
    print(json.dumps({"gates": result["gates"], "mapping": result["mapping"], "review_tokens": result["review_sample"]["tokens"], "stress_tokens": result["longest_100_stress"]["tokens"]}, indent=2))


if __name__ == "__main__":
    main()
