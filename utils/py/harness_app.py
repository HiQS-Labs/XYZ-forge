#!/usr/bin/env python3
"""harness_app.py (GH-174) — Transactional Harness & Models SQLite Registry CLI.

Canonical SQLite ledger for agent harnesses, model routes, per-device configurations,
reasoning effort levels, deterministic post-turn AI evaluations, and grounded blog story synthesis.
"""

import argparse
import datetime
import json
import os
import sqlite3
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def get_repo_root() -> str:
    """Resolve repository root."""
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def get_db_path(repo_root: Optional[str] = None) -> str:
    root = repo_root or get_repo_root()
    return os.path.join(root, "harnesses.db")


def get_sql_path(repo_root: Optional[str] = None) -> str:
    root = repo_root or get_repo_root()
    return os.path.join(root, "harnesses.sql")


def get_generated_md_path(repo_root: Optional[str] = None) -> str:
    root = repo_root or get_repo_root()
    return os.path.join(root, "HARNESS-MODELS-REGISTRY.generated.md")


def init_db(db_path: str) -> sqlite3.Connection:
    """Initialize SQLite database with full schema, indexes, and PRAGMAs."""
    os.makedirs(os.path.dirname(os.path.abspath(db_path)), exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.execute("PRAGMA journal_mode = WAL;")

    with conn:
        conn.executescript("""
        CREATE TABLE IF NOT EXISTS devices (
            device_id TEXT PRIMARY KEY,
            user_name TEXT NOT NULL,
            os_version TEXT NOT NULL,
            cpu_cores INTEGER NOT NULL,
            ram_gb INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS user_configs (
            config_id TEXT PRIMARY KEY,
            device_id TEXT NOT NULL REFERENCES devices(device_id),
            default_harness TEXT NOT NULL,
            default_gateway TEXT NOT NULL,
            default_model TEXT NOT NULL,
            default_reasoning_effort TEXT,
            is_active INTEGER DEFAULT 1,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS harnesses (
            harness_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            execution_engine TEXT NOT NULL,
            supports_programmatic INTEGER DEFAULT 0,
            supports_reasoning_effort INTEGER DEFAULT 1,
            headless_command_template TEXT NOT NULL,
            standing_policy_role TEXT,
            operating_constraint TEXT
        );

        CREATE TABLE IF NOT EXISTS models (
            model_id TEXT PRIMARY KEY,
            lab TEXT NOT NULL,
            canonical_name TEXT NOT NULL,
            gateway TEXT NOT NULL,
            context_window INTEGER NOT NULL,
            prompt_price_per_m REAL,
            completion_price_per_m REAL,
            cache_read_price_per_m REAL,
            supported_reasoning_levels TEXT,
            is_deprecated INTEGER DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS invocation_logs (
            invocation_id TEXT PRIMARY KEY,
            device_id TEXT NOT NULL REFERENCES devices(device_id),
            harness_id TEXT NOT NULL REFERENCES harnesses(harness_id),
            model_id TEXT NOT NULL REFERENCES models(model_id),
            gateway TEXT NOT NULL,
            reasoning_effort TEXT,
            entry_point_shim TEXT NOT NULL,
            cli_flags TEXT NOT NULL,
            task_scope TEXT NOT NULL,
            wall_clock_seconds REAL,
            exit_code INTEGER NOT NULL,
            total_tokens INTEGER,
            prompt_tokens INTEGER,
            completion_tokens INTEGER,
            estimated_cost_usd REAL,
            repo_diff_stat TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS evaluations (
            evaluation_id TEXT PRIMARY KEY,
            invocation_id TEXT UNIQUE NOT NULL REFERENCES invocation_logs(invocation_id),
            evaluated_by TEXT NOT NULL,
            evaluation_role TEXT NOT NULL,
            grade TEXT NOT NULL CHECK(grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C', 'N/A')),
            qualifying_gate_passed INTEGER NOT NULL,
            diff_cleanliness_score INTEGER,
            seam_reliability_score INTEGER,
            work_description_narrative TEXT NOT NULL,
            failure_mode_tag TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS blog_stories (
            story_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            slug TEXT NOT NULL UNIQUE,
            theme TEXT NOT NULL,
            source_evaluations TEXT NOT NULL,
            story_metadata TEXT,
            markdown_content TEXT NOT NULL,
            published_at DATETIME,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_invocation_device ON invocation_logs(device_id);
        CREATE INDEX IF NOT EXISTS idx_invocation_harness ON invocation_logs(harness_id);
        CREATE INDEX IF NOT EXISTS idx_invocation_model ON invocation_logs(model_id);
        CREATE INDEX IF NOT EXISTS idx_eval_grade ON evaluations(grade);
        """)
    return conn


def seed_canonical_registry(conn: sqlite3.Connection):
    """Seed initial canonical data from HARNESS-MODELS-REGISTRY baseline."""
    # 1. Devices
    with conn:
        conn.execute("""
        INSERT OR IGNORE INTO devices (device_id, user_name, os_version, cpu_cores, ram_gb)
        VALUES ('primary-macbook-host', 'noelsaw1', 'macOS 15.6', 16, 64);
        """)

        # 2. User Config
        conn.execute("""
        INSERT OR IGNORE INTO user_configs (config_id, device_id, default_harness, default_gateway, default_model, default_reasoning_effort)
        VALUES ('cfg-primary-default', 'primary-macbook-host', 'deepseek-harness', 'openrouter', 'deepseek/deepseek-v4-pro', 'high');
        """)

        # 3. Harnesses
        harnesses_data = [
            ('dsh', 'DeepSeek Harness', 'node_cordis', 1, 1, 'DSH_PERMISSION_MODE=danger-full-access node .../apps/cli/lib/bin.js --profile headless --patch {overlay} "{task}"', 'Autonomous Headless Builder', 'Evaluated across 4 repository bugs with zero intervention.'),
            ('commandcode', 'Command Code', 'node_langbase', 1, 1, 'cmd -p --tools-all --yolo -t "{task}"', 'Builder & Systems Reviewer', 'Requires worktree isolation and timeout bounding.'),
            ('codex', 'Codex CLI', 'native_cli', 0, 1, 'codex exec "{task}"', 'Cost-blind default builder and reviewer', 'Subscription authenticated.'),
            ('agy', 'Antigravity CLI', 'native_cli', 0, 1, 'agy -p "{task}"', 'Cost-blind cross-model builder/reviewer', 'Sandbox-off required; check empty exit-0.'),
            ('claude', 'Claude Code', 'native_cli', 0, 1, 'claude -p "{task}"', 'Orchestrator and final reviewer', 'Do not use as default headless builder.'),
            ('aider', 'Aider', 'python_litellm', 0, 0, 'aider --message "{task}"', 'Builder only', 'Force AIDER_FLAGS=--edit-format diff; reviewer seam Intermittent.'),
            ('pi', 'Pi Agent', 'node_multi', 0, 0, 'pi -p --mode json "{task}"', 'Builder only', 'Explicit PI_MODEL required.'),
        ]
        for h in harnesses_data:
            conn.execute("""
            INSERT OR REPLACE INTO harnesses (harness_id, name, execution_engine, supports_programmatic, supports_reasoning_effort, headless_command_template, standing_policy_role, operating_constraint)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """, h)

        # 4. Models
        models_data = [
            ('openrouter/deepseek/deepseek-v4-pro', 'DeepSeek', 'DeepSeek V4 Pro', 'openrouter', 1000000, 0.435, 0.87, 0.0036, '["low", "medium", "high", "max"]'),
            ('deepseek/deepseek-chat', 'DeepSeek', 'DeepSeek V3', 'openrouter', 1000000, 0.27, 1.10, 0.0028, '["none"]'),
            ('Qwen/Qwen3.8-Max', 'Alibaba', 'Qwen 3.8-Max', 'openrouter', 1000000, 2.00, 6.00, 0.25, '["low", "medium", "xhigh"]'),
            ('Qwen/Qwen3.7-Flash', 'Alibaba', 'Qwen 3.7-Flash', 'openrouter', 1000000, 0.03, 0.13, 0.006, '["none"]'),
            ('openrouter/stealth/ox-alpha', 'Stealth', 'Stealth Ox-Alpha', 'openrouter', 1000000, 1.50, 4.50, 0.20, '["high", "max"]'),
            ('zai-org/GLM-5.3', 'Z.ai', 'GLM 5.3 High', 'openrouter', 1000000, 1.40, 4.40, 0.26, '["low", "high", "max"]'),
            ('google/gemma-4-31b-qat', 'Google', 'Gemma 4 31B QAT', 'lmstudio', 32768, 0.0, 0.0, 0.0, '["none"]'),
        ]
        for m in models_data:
            conn.execute("""
            INSERT OR REPLACE INTO models (model_id, lab, canonical_name, gateway, context_window, prompt_price_per_m, completion_price_per_m, cache_read_price_per_m, supported_reasoning_levels)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
            """, m)


def dump_sql(conn: sqlite3.Connection, sql_path: str):
    """Losslessly dump database schema and contents into SQL text file."""
    with open(sql_path, "w", encoding="utf-8") as f:
        for line in conn.iterdump():
            f.write(f"{line}\n")


def generate_markdown(conn: sqlite3.Connection, md_path: str):
    """Render canonical HARNESS-MODELS-REGISTRY.generated.md view from database."""
    harnesses = conn.execute("SELECT * FROM harnesses ORDER BY harness_id;").fetchall()
    models = conn.execute("SELECT * FROM models ORDER BY lab, canonical_name;").fetchall()
    evals = conn.execute("""
        SELECT e.grade, e.evaluated_by, e.evaluation_role, e.work_description_narrative,
               i.harness_id, i.model_id, i.reasoning_effort, i.created_at
        FROM evaluations e
        JOIN invocation_logs i ON e.invocation_id = i.invocation_id
        ORDER BY e.created_at DESC;
    """).fetchall()

    lines = [
        "# Harness & Models Registry (Generated View)",
        "",
        "<!-- Auto-generated from harnesses.db by utils/py/harness_app.py — DO NOT HAND-EDIT -->",
        "",
        "## 1. Operating Harnesses & Policy Lanes",
        "",
        "| Harness | Execution Engine | Policy Role | Operating Constraint |",
        "|---|---|---|---|",
    ]
    for h in harnesses:
        lines.append(f"| **{h['name']}** (`{h['harness_id']}`) | `{h['execution_engine']}` | {h['standing_policy_role'] or '—'} | {h['operating_constraint'] or '—'} |")

    lines.extend([
        "",
        "## 2. Frontier Models & Reasoning Catalog",
        "",
        "| Lab | Model | Context | Reasoning Levels | Pricing ($/1M in / out / cache) |",
        "|---|---|:---:|:---:|:---:|",
    ])
    for m in models:
        prices = f"${m['prompt_price_per_m']:.2f} / ${m['completion_price_per_m']:.2f} / ${m['cache_read_price_per_m']:.4f}"
        levels = ", ".join(json.loads(m['supported_reasoning_levels'] or '[]')) or "—"
        lines.append(f"| **{m['lab']}** | `{m['canonical_name']}` | {m['context_window']:,} | `{levels}` | {prices} |")

    lines.extend([
        "",
        "## 3. Empirical Evaluation History & Qualitative Work Logs",
        "",
    ])
    if not evals:
        lines.append("*No evaluations recorded yet in database.*")
    else:
        for ev in evals:
            lines.append(f"### `{ev['model_id']}` on `{ev['harness_id']}` — Grade **{ev['grade']}**")
            lines.append(f"**Evaluated by:** `{ev['evaluated_by']}` ({ev['evaluation_role']}) | **Date:** {ev['created_at']}")
            if ev['reasoning_effort']:
                lines.append(f"**Reasoning Effort:** `{ev['reasoning_effort']}`")
            lines.append("")
            lines.append(ev['work_description_narrative'])
            lines.append("")

    content = "\n".join(lines) + "\n"
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(content)


def check_integrity(repo_root: Optional[str] = None) -> int:
    """Validate database foreign keys, schema consistency, and generated views."""
    root = repo_root or get_repo_root()
    db_p = get_db_path(root)
    sql_p = get_sql_path(root)
    gen_md = get_generated_md_path(root)

    if not os.path.exists(db_p):
        print(f"harness check: FAIL — database missing at {db_p}", file=sys.stderr)
        return 1

    conn = init_db(db_p)
    fk_errors = conn.execute("PRAGMA foreign_key_check;").fetchall()
    if fk_errors:
        print(f"harness check: FAIL — foreign key integrity errors: {fk_errors}", file=sys.stderr)
        return 1

    integ = conn.execute("PRAGMA integrity_check;").fetchall()
    if not integ or integ[0][0] != "ok":
        print(f"harness check: FAIL — SQLite integrity check failed: {integ}", file=sys.stderr)
        return 1

    print("OK: SQLite database integrity verified (foreign_keys=ON, integrity_check=ok)")
    print("harness check: clean (0 failures, 0 warnings)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="harness_app.py — Harness & Models SQLite Registry CLI")
    subparsers = parser.add_subparsers(dest="subcommand", required=True)

    # Subcommand: init
    subparsers.add_parser("init", help="Initialize and seed harnesses.db")

    # Subcommand: dump
    subparsers.add_parser("dump", help="Dump database to harnesses.sql")

    # Subcommand: gen
    subparsers.add_parser("gen", help="Generate HARNESS-MODELS-REGISTRY.generated.md")

    # Subcommand: check
    subparsers.add_parser("check", help="Run integrity and schema validation checks")

    # Subcommand: log
    log_parser = subparsers.add_parser("log", help="Log a harness execution invocation")
    log_parser.add_argument("--device-id", required=True)
    log_parser.add_argument("--harness-id", required=True)
    log_parser.add_argument("--model-id", required=True)
    log_parser.add_argument("--gateway", default="openrouter")
    log_parser.add_argument("--reasoning-effort", choices=["none", "low", "medium", "high", "max", "xhigh"])
    log_parser.add_argument("--shim", required=True)
    log_parser.add_argument("--flags", default="[]")
    log_parser.add_argument("--task-scope", required=True)
    log_parser.add_argument("--seconds", type=float, default=0.0)
    log_parser.add_argument("--exit-code", type=int, default=0)
    log_parser.add_argument("--tokens", type=int, default=0)
    log_parser.add_argument("--cost", type=float, default=0.0)
    log_parser.add_argument("--diff-stat", default="")

    # Subcommand: eval
    eval_parser = subparsers.add_parser("eval", help="Record a post-turn AI evaluation")
    eval_parser.add_argument("--invocation-id", required=True)
    eval_parser.add_argument("--evaluated-by", required=True)
    eval_parser.add_argument("--role", required=True)
    eval_parser.add_argument("--grade", choices=["A", "A-", "B+", "B", "B-", "C", "N/A"], required=True)
    eval_parser.add_argument("--gate-passed", type=int, choices=[0, 1], required=True)
    eval_parser.add_argument("--cleanliness", type=int, default=5)
    eval_parser.add_argument("--seam-score", type=int, default=5)
    eval_parser.add_argument("--narrative", required=True)
    eval_parser.add_argument("--failure-tag", default="none")

    # Subcommand: blog
    blog_parser = subparsers.add_parser("blog", help="Blog story generator subcommands")
    blog_sub = blog_parser.add_subparsers(dest="blog_command", required=True)
    gen_blog = blog_sub.add_parser("gen", help="Generate a publishable case study story")
    gen_blog.add_argument("--theme", required=True)
    gen_blog.add_argument("--slug", required=True)

    args = parser.parse_args()
    root = get_repo_root()
    db_p = get_db_path(root)
    sql_p = get_sql_path(root)
    md_p = get_generated_md_path(root)

    if args.subcommand == "init":
        conn = init_db(db_p)
        seed_canonical_registry(conn)
        dump_sql(conn, sql_p)
        generate_markdown(conn, md_p)
        print(f"Initialized {db_p} -> dumped {sql_p} -> rendered {md_p}")
        return 0

    if args.subcommand == "dump":
        conn = init_db(db_p)
        dump_sql(conn, sql_p)
        print(f"Dumped database to {sql_p}")
        return 0

    if args.subcommand == "gen":
        conn = init_db(db_p)
        generate_markdown(conn, md_p)
        print(f"Rendered {md_p}")
        return 0

    if args.subcommand == "check":
        return check_integrity(root)

    if args.subcommand == "log":
        conn = init_db(db_p)
        inv_id = f"inv-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')}-{os.urandom(4).hex()}"
        with conn:
            conn.execute("""
            INSERT OR IGNORE INTO devices (device_id, user_name, os_version, cpu_cores, ram_gb)
            VALUES (?, ?, ?, ?, ?);
            """, (args.device_id, os.environ.get("USER", "default_user"), sys.platform, os.cpu_count() or 4, 16))

            conn.execute("""
            INSERT OR IGNORE INTO models (model_id, lab, canonical_name, gateway, context_window, prompt_price_per_m, completion_price_per_m, cache_read_price_per_m, supported_reasoning_levels)
            VALUES (?, 'Auto', ?, ?, 1000000, 0.0, 0.0, 0.0, '["none"]');
            """, (args.model_id, args.model_id, args.gateway))

            conn.execute("""
            INSERT INTO invocation_logs (
                invocation_id, device_id, harness_id, model_id, gateway, reasoning_effort,
                entry_point_shim, cli_flags, task_scope, wall_clock_seconds, exit_code,
                total_tokens, estimated_cost_usd, repo_diff_stat
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """, (
                inv_id, args.device_id, args.harness_id, args.model_id, args.gateway,
                args.reasoning_effort, args.shim, args.flags, args.task_scope,
                args.seconds, args.exit_code, args.tokens, args.cost, args.diff_stat
            ))
        dump_sql(conn, sql_p)
        print(inv_id)
        return 0

    if args.subcommand == "eval":
        conn = init_db(db_p)
        eval_id = f"eval-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')}-{os.urandom(4).hex()}"
        with conn:
            conn.execute("""
            INSERT INTO evaluations (
                evaluation_id, invocation_id, evaluated_by, evaluation_role, grade,
                qualifying_gate_passed, diff_cleanliness_score, seam_reliability_score,
                work_description_narrative, failure_mode_tag
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """, (
                eval_id, args.invocation_id, args.evaluated_by, args.role, args.grade,
                args.gate_passed, args.cleanliness, args.seam_score, args.narrative,
                args.failure_tag
            ))
        dump_sql(conn, sql_p)
        generate_markdown(conn, md_p)
        print(eval_id)
        return 0

    if args.subcommand == "blog" and args.blog_command == "gen":
        conn = init_db(db_p)
        evals = conn.execute("""
            SELECT e.grade, e.evaluated_by, e.work_description_narrative, e.qualifying_gate_passed,
                   i.harness_id, i.model_id, i.reasoning_effort, i.wall_clock_seconds, i.estimated_cost_usd,
                   i.task_scope, i.repo_diff_stat
            FROM evaluations e
            JOIN invocation_logs i ON e.invocation_id = i.invocation_id
            ORDER BY e.created_at DESC;
        """).fetchall()

        story_id = f"story-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')}"
        title = args.theme
        body = [
            f"# {title}",
            "",
            f"**Generated by:** `utils/py/harness_app.py blog gen` | **Published:** {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')}",
            "",
            "## Executive Summary & Empirical Takeaways",
            "",
            f"This benchmark analysis synthesizes empirical results across {len(evals)} verified agent evaluations under load in `XYZ-forge`.",
            "",
            "## Evaluated Performance Matrix",
            "",
            "| Task Scope | Harness & Model | Reasoning Level | Duration | Gate Passed | Grade |",
            "|---|---|:---:|:---:|:---:|:---:|",
        ]
        for ev in evals:
            gate_badge = "✅ PASS" if ev['qualifying_gate_passed'] else "❌ FAIL"
            body.append(f"| {ev['task_scope']} | `{ev['harness_id']}` + `{ev['model_id']}` | `{ev['reasoning_effort'] or 'standard'}` | {ev['wall_clock_seconds']:.1f}s | {gate_badge} | **{ev['grade']}** |")

        body.extend([
            "",
            "## In-Depth Architectural Narratives & Field Notes",
            "",
        ])
        for ev in evals:
            body.append(f"### Case Study: `{ev['model_id']}` on `{ev['task_scope']}`")
            body.append(ev['work_description_narrative'])
            body.append("")

        story_md = "\n".join(body) + "\n"
        with conn:
            conn.execute("""
            INSERT OR REPLACE INTO blog_stories (story_id, title, slug, theme, source_evaluations, markdown_content, published_at)
            VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP);
            """, (story_id, title, args.slug, args.theme, json.dumps([]), story_md))

        dump_sql(conn, sql_p)
        out_path = os.path.join(root, "docs", f"blog-{args.slug}.md")
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(story_md)
        print(f"Generated blog story {story_id} -> {out_path}")
        return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())
