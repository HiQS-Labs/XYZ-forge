#!/usr/bin/env python3
"""run_record.py (GH-1543 / KS-15) — canonical v1 kickstart run-record parser,
sibling-locked atomic appender, redacted snapshotter, and confined checkpoint helper.

Version 1 grammar:
  Headers:
    RUN-RECORD-VERSION: 1 [(optional note)]
    LANDING_CLONE: <path> [(optional note)]
  Event lines (optional leading "- " bullet tolerated):
    OPERATOR_AMENDMENT: <ID> <ISO-UTC-TS> <text citing operator turn/comment/decision>
    PARENT_NOTE: <ID> <ISO-UTC-TS> <text>
    INTERVENTION: <ID> <ISO-UTC-TS> <text>
    APPLIED: <ID> (?:→|->) <disposition: applied|superseded|escalated> <action> [<ISO-UTC-TS>]
    APPLIED: <ID> (?:→|->) <compact action> [<ISO-UTC-TS>]   (defaults disposition="applied")
    GATE: <target> [head <sha>] <route> [<Ns>|(duration not recorded)] <green|red> [...]
    BASELINE: <summary>

Reserved-word precedence on APPLIED:
  If the first whitespace-delimited token after the arrow (stripping optional trailing ":")
  is exact lowercase "applied", "superseded", or "escalated", it is parsed as the explicit
  disposition and the remaining action/reason MUST be non-empty (so "APPLIED: OA-1 → escalated"
  is a validation error). For "superseded", the remainder must reference a declared newer
  amendment ID (appearing later in the record). Repeated APPLIED lines for the same ID are allowed only when the prior
  disposition was "escalated"; any APPLIED after terminal "applied" or "superseded" is an error.

Compatibility examples:
  APPLIED: OA-1 → applied merged #1508 per operator decision 2026-11-20T07:00Z
  APPLIED: OA-1 → superseded by OA-2 2026-11-20T07:05Z
  APPLIED: OA-1 → escalated run held pending operator confirmation 2026-11-20T07:05Z
  APPLIED: OA-1 → merged #1508
  GATE: #1501 head 2e9bb2bdd full 856s green
  GATE: final-QA 0a87e686d tier1+full green (duration not recorded)
"""
from __future__ import annotations

import argparse
import datetime as dt
import fcntl
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

RUN_RECORD_VERSION = 1
FORBIDDEN_BRANCHES = frozenset({"development", "main", "master"})
RESERVED_DISPOSITIONS = frozenset({"applied", "superseded", "escalated"})
TERMINAL_DISPOSITIONS = frozenset({"applied", "superseded"})
VALID_ROUTES = frozenset({"docs", "fast", "full", "tier1+full"})

HEADER_VERSION_RE = re.compile(r"^RUN-RECORD-VERSION:\s*(\S+)(?:\s+\(.*\))?\s*$")
HEADER_LANDING_RE = re.compile(r"^LANDING_CLONE:\s*(.*)$")
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
TS_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T~?\d{2}:\d{2}(?::\d{2})?Z$")
STRICT_TS_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2})?Z$")
OPERATOR_CITE_RE = re.compile(r"\boperator\s+(?:turn|comment|decision)\b", re.I)

EVENT_PREFIX_RE = re.compile(
    r"^(?:-\s+)?(OPERATOR_AMENDMENT|PARENT_NOTE|INTERVENTION|APPLIED|GATE|BASELINE):(.*)$"
)
APPLIED_SPLIT_RE = re.compile(r"^(\S+)\s*(?:→|->)\s*(.*)$")
GATE_HEAD_RE = re.compile(
    r"^(?P<target>\S+)\s+head\s+(?P<sha>[0-9a-fA-F]{7,40})\s+"
    r"(?P<route>docs|fast|full|tier1\+full)\s+"
    r"(?:(?P<sec>\d+)s\s+|\(duration not recorded\)\s+)?(?P<verdict>green|red)(?:\s+(?P<rest>.*))?$"
)
GATE_FINAL_RE = re.compile(
    r"^(?P<target>final-QA)\s+(?P<sha>[0-9a-fA-F]{7,40})\s+"
    r"(?P<route>docs|fast|full|tier1\+full)\s+"
    r"(?:(?P<sec>\d+)s\s+|\(duration not recorded\)\s+)?(?P<verdict>green|red)(?:\s+(?P<rest>.*))?$"
)

HOME_PATH_RE = re.compile(r"(?:/Users|/home)/[A-Za-z0-9._-]+")
SECRET_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{10,}\b"), "[REDACTED]"),
    (re.compile(r"\bgithub_pat_[A-Za-z0-9_]{10,}\b"), "[REDACTED]"),
    (re.compile(r"\bsk-[A-Za-z0-9_-]{16,}\b"), "[REDACTED]"),
    (re.compile(r"(\bAuthorization:\s*Bearer\s+)[^\r\n]+", re.I), r"\1[REDACTED]"),
    (re.compile(r"(\bAuthorization:[ \t]*)(?![ \t]*Bearer[ \t]+\[REDACTED\])[^\r\n]+", re.I), r"\1[REDACTED]"),
    (re.compile(r"(\bBearer\s+)[A-Za-z0-9._~+/=-]{8,}", re.I), r"\1[REDACTED]"),
]
STRAY_TAG_RE = re.compile(r"</?(?:content|invoke(?:\s+[^>]*)?|parameter(?:\s+[^>]*)?)>", re.I)


def utc_now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _extract_landing_path(raw: str) -> str:
    val = raw.strip()
    if not val:
        return ""
    # Strip trailing parenthetical comment like "(the ONLY --primary ...)"
    val = re.sub(r"\s+\([^()]*\)\s*$", "", val).strip()
    return val


def _strip_trailing_ts(text: str) -> tuple[str, str | None]:
    parts = text.rsplit(None, 1)
    if len(parts) == 2 and TS_RE.match(parts[1]):
        return parts[0].strip(), parts[1]
    if len(parts) == 1 and TS_RE.match(parts[0]):
        return "", parts[0]
    return text.strip(), None


def parse_record(text: str, *, require_landing_clone: bool = False) -> dict[str, Any]:
    """Parse and validate a v1 kickstart run record."""
    errors: list[str] = []
    versions: list[tuple[int, str]] = []
    landing_clones: list[tuple[int, str]] = []
    amendments: list[dict[str, Any]] = []
    interventions: list[dict[str, Any]] = []
    applied: list[dict[str, Any]] = []
    gates: list[dict[str, Any]] = []
    baselines: list[dict[str, Any]] = []

    amendment_by_id: dict[str, dict[str, Any]] = {}
    intervention_ids: set[str] = set()
    latest_applied: dict[str, dict[str, Any]] = {}

    if not text or not text.strip():
        errors.append("record is empty")

    for line_no, raw_line in enumerate(text.splitlines(), 1):
        line = raw_line.strip()
        if not line:
            continue

        m_ver = HEADER_VERSION_RE.match(line)
        if m_ver:
            versions.append((line_no, m_ver.group(1)))
            continue
        if line.startswith("RUN-RECORD-VERSION:"):
            errors.append(f"line {line_no}: malformed RUN-RECORD-VERSION header")
            continue

        m_lc = HEADER_LANDING_RE.match(line)
        if m_lc:
            lc_val = _extract_landing_path(m_lc.group(1))
            if not lc_val:
                errors.append(f"line {line_no}: LANDING_CLONE header is empty")
            else:
                landing_clones.append((line_no, lc_val))
            continue

        m_ev = EVENT_PREFIX_RE.match(line)
        if not m_ev:
            continue

        kind = m_ev.group(1)
        payload = m_ev.group(2).strip()

        if kind in ("OPERATOR_AMENDMENT", "PARENT_NOTE", "INTERVENTION"):
            parts = payload.split(None, 2)
            if len(parts) < 3:
                errors.append(f"line {line_no}: {kind} requires <ID> <ISO-UTC-TS> <text>")
                continue
            ev_id, ts, body = parts[0], parts[1], parts[2].strip()
            if not ID_RE.match(ev_id):
                errors.append(f"line {line_no}: {kind} invalid ID {ev_id!r}")
                continue
            if not TS_RE.match(ts):
                errors.append(f"line {line_no}: {kind} invalid UTC timestamp {ts!r}")
                continue
            if not body:
                errors.append(f"line {line_no}: {kind} text is empty")
                continue
            if kind == "OPERATOR_AMENDMENT" and not OPERATOR_CITE_RE.search(body):
                errors.append(
                    f"line {line_no}: OPERATOR_AMENDMENT {ev_id} must cite an operator turn/comment/decision"
                )
                continue

            entry = {"kind": kind, "id": ev_id, "ts": ts, "text": body, "line_no": line_no}
            if kind == "INTERVENTION":
                if ev_id in intervention_ids:
                    errors.append(f"line {line_no}: duplicate INTERVENTION ID {ev_id!r}")
                    continue
                intervention_ids.add(ev_id)
                interventions.append(entry)
            else:
                if ev_id in amendment_by_id:
                    errors.append(f"line {line_no}: duplicate amendment ID {ev_id!r}")
                    continue
                amendment_by_id[ev_id] = entry
                amendments.append(entry)

        elif kind == "APPLIED":
            m_ap = APPLIED_SPLIT_RE.match(payload)
            if not m_ap:
                errors.append(f"line {line_no}: APPLIED requires '<ID> → <disposition/action>'")
                continue
            target_id = m_ap.group(1).strip()
            rest = m_ap.group(2).strip()
            if not ID_RE.match(target_id):
                errors.append(f"line {line_no}: APPLIED invalid target ID {target_id!r}")
                continue
            if target_id not in amendment_by_id:
                errors.append(f"line {line_no}: APPLIED references undeclared amendment ID {target_id!r}")
                continue
            if not rest:
                errors.append(f"line {line_no}: APPLIED {target_id} missing disposition/action")
                continue

            body_no_ts, ts = _strip_trailing_ts(rest)
            toks = body_no_ts.split(None, 1)
            first_raw = toks[0] if toks else ""
            first_clean = first_raw.rstrip(":")
            if first_clean in RESERVED_DISPOSITIONS:
                disposition = first_clean
                action = toks[1].strip() if len(toks) > 1 else ""
                if not action:
                    errors.append(
                        f"line {line_no}: APPLIED {target_id} missing action/reason after disposition '{disposition}'"
                    )
                    continue
            else:
                disposition = "applied"
                action = body_no_ts
                if not action:
                    errors.append(f"line {line_no}: APPLIED {target_id} missing action")
                    continue

            superseded_by: str | None = None
            if disposition == "superseded":
                target_line = amendment_by_id[target_id]["line_no"]
                newer_ids = [
                    aid
                    for aid, aentry in amendment_by_id.items()
                    if aid != target_id
                    and aentry["line_no"] > target_line
                    and re.search(rf"(?<![A-Za-z0-9._-]){re.escape(aid)}(?![A-Za-z0-9._-])", action)
                ]
                if not newer_ids:
                    errors.append(
                        f"line {line_no}: APPLIED {target_id} disposition 'superseded' must name a declared newer amendment ID (declared after {target_id})"
                    )
                    continue
                superseded_by = newer_ids[-1]

            prior = latest_applied.get(target_id)
            if prior is not None and prior["disposition"] in TERMINAL_DISPOSITIONS:
                errors.append(
                    f"line {line_no}: duplicate terminal disposition for {target_id!r} (already '{prior['disposition']}')"
                )
                continue

            ap_entry = {
                "id": target_id,
                "disposition": disposition,
                "action": action,
                "ts": ts,
                "superseded_by": superseded_by,
                "line_no": line_no,
            }
            applied.append(ap_entry)
            latest_applied[target_id] = ap_entry

        elif kind == "GATE":
            mg = GATE_HEAD_RE.match(payload) or GATE_FINAL_RE.match(payload)
            if not mg:
                errors.append(f"line {line_no}: malformed GATE line {payload!r}")
                continue
            sec_str = mg.group("sec")
            gates.append(
                {
                    "target": mg.group("target"),
                    "sha": mg.group("sha"),
                    "route": mg.group("route"),
                    "seconds": int(sec_str) if sec_str is not None else None,
                    "verdict": mg.group("verdict"),
                    "note": (mg.group("rest") or "").strip() or None,
                    "line_no": line_no,
                }
            )

        elif kind == "BASELINE":
            if not payload:
                errors.append(f"line {line_no}: BASELINE line is empty")
                continue
            baselines.append({"text": payload, "line_no": line_no})

    version: int | None = None
    if not versions:
        errors.append("missing mandatory RUN-RECORD-VERSION: 1 header")
    else:
        if len(versions) > 1:
            errors.append(f"duplicate RUN-RECORD-VERSION headers at lines {[ln for ln, _ in versions]}")
        v_line, v_raw = versions[0]
        if v_raw != str(RUN_RECORD_VERSION):
            errors.append(f"line {v_line}: unsupported RUN-RECORD-VERSION {v_raw!r} (expected {RUN_RECORD_VERSION})")
        else:
            version = RUN_RECORD_VERSION

    landing_clone: str | None = None
    if len(landing_clones) > 1:
        errors.append(f"duplicate LANDING_CLONE headers at lines {[ln for ln, _ in landing_clones]}")
    if landing_clones:
        landing_clone = landing_clones[0][1]
    elif require_landing_clone:
        errors.append("missing required LANDING_CLONE header")

    unresolved_amendments: list[dict[str, Any]] = []
    escalated_amendments: list[dict[str, Any]] = []
    for am in amendments:
        ap = latest_applied.get(am["id"])
        if ap is None:
            unresolved_amendments.append({**am, "state": "pending"})
        elif ap["disposition"] == "escalated":
            item = {**am, "state": "escalated", "applied": ap}
            unresolved_amendments.append(item)
            escalated_amendments.append(item)

    return {
        "version": version,
        "landing_clone": landing_clone,
        "amendments": amendments,
        "interventions": interventions,
        "applied": applied,
        "gates": gates,
        "baselines": baselines,
        "unresolved_amendments": unresolved_amendments,
        "escalated_amendments": escalated_amendments,
        "errors": errors,
        "valid": len(errors) == 0,
    }


def _atomic_write_text(dest: Path, content: str) -> None:
    parent = dest.parent
    parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{dest.name}.", suffix=".tmp", dir=str(parent))
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(content)
            fh.flush()
            os.fsync(fh.fileno())
        os.replace(tmp_path, dest)
        try:
            dir_fd = os.open(str(parent), os.O_RDONLY)
            try:
                os.fsync(dir_fd)
            finally:
                os.close(dir_fd)
        except OSError:
            pass
    except Exception:
        try:
            tmp_path.unlink(missing_ok=True)
        except OSError:
            pass
        raise


def atomic_append(record_path: Path, line: str, *, require_landing_clone: bool = False) -> dict[str, Any]:
    """Append one validated v1 line under a persistent sibling lock with full-record validation."""
    if "\n" in line or "\r" in line:
        raise ValueError("append line must be a single line with no embedded newlines")
    line_stripped = line.strip()
    if not line_stripped:
        raise ValueError("append line must not be empty")
    if not EVENT_PREFIX_RE.match(line_stripped):
        raise ValueError(f"line does not match a v1 event prefix: {line_stripped!r}")

    lock_path = Path(f"{record_path}.lock")
    lock_fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR, 0o600)
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX)
        if not record_path.is_file():
            raise FileNotFoundError(f"run record does not exist: {record_path}")
        existing = record_path.read_text(encoding="utf-8")
        sep = "" if (not existing or existing.endswith("\n")) else "\n"
        candidate = f"{existing}{sep}{line_stripped}\n"
        parsed = parse_record(candidate, require_landing_clone=require_landing_clone)
        if not parsed["valid"]:
            raise ValueError("; ".join(parsed["errors"]))
        _atomic_write_text(record_path, candidate)
        return parsed
    finally:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
        finally:
            os.close(lock_fd)


def redact_text(text: str) -> str:
    """Normalize local home paths, redact secret tokens, and strip stray tool XML tags."""
    if not text or not text.strip():
        raise ValueError("cannot create snapshot from empty input")
    out = STRAY_TAG_RE.sub("", text)
    out = HOME_PATH_RE.sub("~", out)
    for pat, repl in SECRET_PATTERNS:
        out = pat.sub(repl, out)
    # Remove trailing blank spaces left behind by stripped tags while keeping a clean final newline
    out = "\n".join(ln.rstrip() for ln in out.splitlines()) + "\n"
    if not out.strip():
        raise ValueError("snapshot is empty after redaction")
    return out


def write_snapshot(record_path: Path, out_path: Path | None = None) -> str:
    if not record_path.is_file():
        raise FileNotFoundError(f"run record does not exist: {record_path}")
    raw = record_path.read_text(encoding="utf-8")
    redacted = redact_text(raw)
    if out_path is not None:
        _atomic_write_text(out_path, redacted)
    return redacted


def _git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    proc = subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True,
        text=True,
    )
    if check and proc.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed (rc={proc.returncode}): {proc.stderr.strip()}")
    return proc


def _git_common_dir(path: Path) -> Path | None:
    proc = _git(path, "rev-parse", "--git-common-dir", check=False)
    if proc.returncode != 0:
        return None
    raw = proc.stdout.strip()
    if not raw:
        return None
    p = Path(raw)
    return (p if p.is_absolute() else (path / p)).resolve()


def _validate_dest_syntax(dest_rel: str) -> Path:
    if not dest_rel or not dest_rel.strip():
        raise ValueError("--dest must be a non-empty relative path")
    p = Path(dest_rel)
    if p.is_absolute():
        raise ValueError(f"--dest must be relative, got absolute path {dest_rel!r}")
    if any(part in ("..", "") for part in p.parts):
        raise ValueError(f"--dest must not contain '..' traversal: {dest_rel!r}")
    if any(part == ".git" for part in p.parts):
        raise ValueError(f"--dest must not target Git metadata (.git): {dest_rel!r}")
    return p


def _check_branch_tree_symlinks(clone: Path, branch: str, dest: Path) -> None:
    """Inspect existing local branch tree before checkout; refuse if dest or any ancestor is a symlink."""
    ref_check = _git(clone, "show-ref", "--verify", "--quiet", f"refs/heads/{branch}", check=False)
    if ref_check.returncode != 0:
        return
    prefixes: list[str] = []
    cur = Path()
    for part in dest.parts:
        cur = cur / part
        prefixes.append(cur.as_posix())
    for pref in prefixes:
        ls = _git(clone, "ls-tree", f"refs/heads/{branch}", "--", pref, check=False)
        if ls.returncode != 0:
            continue
        for ln in ls.stdout.splitlines():
            parts = ln.split()
            if parts and parts[0] == "120000":
                raise ValueError(
                    f"target branch {branch!r} has symlink entry at {pref!r}; refusing before branch switch"
                )


def _check_fs_confinement(clone_root: Path, dest: Path) -> Path:
    """Verify every existing ancestor component and final target stay strictly inside clone_root."""
    cur = clone_root
    for part in dest.parts:
        cur = cur / part
        if cur.is_symlink():
            raise ValueError(f"destination path component is a symlink: {cur}")
        if cur.exists():
            resolved = cur.resolve()
            if not resolved.is_relative_to(clone_root):
                raise ValueError(f"destination path escapes clone root: {resolved}")
    final_resolved = (clone_root / dest).resolve()
    if not final_resolved.is_relative_to(clone_root) or final_resolved == clone_root:
        raise ValueError(f"destination resolves outside clone root: {final_resolved}")
    return clone_root / dest


def checkpoint_record(
    record_path: Path,
    clone_dir: Path,
    primary_dir: Path,
    branch: str,
    dest_rel: str,
    *,
    message: str | None = None,
    push: bool = False,
) -> dict[str, Any]:
    """Write a redacted snapshot to a confined, clean, dedicated run-record branch clone."""
    if not primary_dir.exists() or not primary_dir.is_dir():
        raise ValueError(f"--primary must be an existing directory: {primary_dir}")
    if not clone_dir.exists() or not clone_dir.is_dir():
        raise ValueError(f"--clone must be an existing directory: {clone_dir}")

    dest = _validate_dest_syntax(dest_rel)
    if branch in FORBIDDEN_BRANCHES:
        raise ValueError(f"refusing checkpoint on protected integration branch {branch!r}")

    top = _git(clone_dir, "rev-parse", "--show-toplevel", check=False)
    if top.returncode != 0:
        raise ValueError(f"--clone is not a git repository: {clone_dir}")
    clone_root = Path(top.stdout.strip()).resolve()
    primary_root = primary_dir.resolve()

    if clone_root == primary_root:
        raise ValueError("refusing checkpoint: --clone resolves to --primary checkout")

    clone_common = _git_common_dir(clone_root)
    primary_common = _git_common_dir(primary_root)
    if clone_common is not None and primary_common is not None and clone_common == primary_common:
        raise ValueError("refusing checkpoint: --clone shares git common dir with --primary checkout")

    chk_ref = _git(clone_root, "check-ref-format", "--branch", branch, check=False)
    if chk_ref.returncode != 0:
        raise ValueError(f"invalid branch name {branch!r}")

    raw_record = record_path.read_text(encoding="utf-8")
    parsed = parse_record(raw_record)
    if parsed["landing_clone"]:
        lc_resolved = Path(os.path.expanduser(parsed["landing_clone"])).resolve()
        if clone_root == lc_resolved:
            raise ValueError("refusing checkpoint: --clone resolves to the record's LANDING_CLONE")

    redacted = redact_text(raw_record)

    status = _git(clone_root, "status", "--porcelain")
    if status.stdout.strip():
        raise ValueError("refusing checkpoint: --clone has staged, unstaged, or untracked changes")

    # Pre-switch symlink inspection preserves starting branch/refs untouched on refusal
    branch_exists = _git(clone_root, "show-ref", "--verify", "--quiet", f"refs/heads/{branch}", check=False).returncode == 0
    if branch_exists:
        _check_branch_tree_symlinks(clone_root, branch, dest)
    else:
        _check_fs_confinement(clone_root, dest)

    sym = _git(clone_root, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
    orig_ref = sym.stdout.strip() if sym.returncode == 0 else _git(clone_root, "rev-parse", "HEAD").stdout.strip()

    if orig_ref != branch:
        if branch_exists:
            _git(clone_root, "checkout", branch)
        else:
            _git(clone_root, "checkout", "-b", branch)

    try:
        dest_abs = _check_fs_confinement(clone_root, dest)
    except Exception:
        if orig_ref != branch:
            _git(clone_root, "checkout", orig_ref, check=False)
        raise

    _atomic_write_text(dest_abs, redacted)
    _git(clone_root, "add", "--", dest.as_posix())
    diff_rc = _git(clone_root, "diff", "--cached", "--quiet", "--", dest.as_posix(), check=False).returncode
    committed = False
    if diff_rc == 1:
        commit_msg = message or f"chore(kickstart): checkpoint run record {dest.as_posix()}"
        _git(clone_root, "commit", "-m", commit_msg, "--", dest.as_posix())
        committed = True

    head_sha = _git(clone_root, "rev-parse", "HEAD").stdout.strip()
    pushed = False
    push_status = "skipped"
    if push:
        ls_rem = _git(clone_root, "ls-remote", "--heads", "origin", f"refs/heads/{branch}")
        remote_sha = ls_rem.stdout.split()[0] if ls_rem.stdout.strip() else None
        if remote_sha == head_sha:
            push_status = "up-to-date"
        else:
            _git(clone_root, "push", "origin", f"HEAD:refs/heads/{branch}")
            pushed = True
            push_status = "pushed"

    return {
        "clone": str(clone_root),
        "branch": branch,
        "dest": dest.as_posix(),
        "head_sha": head_sha,
        "committed": committed,
        "pushed": pushed,
        "push_status": push_status,
    }


def _format_append_line(args: argparse.Namespace) -> str:
    ts = args.ts or utc_now_iso()
    if not STRICT_TS_RE.match(ts):
        raise ValueError(f"invalid --ts {ts!r}; expected strict UTC ISO-8601 (YYYY-MM-DDTHH:MM[:SS]Z)")

    kind = args.kind
    if kind in ("operator-amendment", "parent-note", "intervention"):
        if not args.id or not args.text:
            raise ValueError(f"--kind {kind} requires --id and --text")
        prefix = {
            "operator-amendment": "OPERATOR_AMENDMENT",
            "parent-note": "PARENT_NOTE",
            "intervention": "INTERVENTION",
        }[kind]
        return f"{prefix}: {args.id} {ts} {args.text.strip()}"

    if kind == "applied":
        if not args.id or not args.action:
            raise ValueError("--kind applied requires --id and --action")
        disp = args.disposition or "applied"
        if disp not in RESERVED_DISPOSITIONS:
            raise ValueError(f"invalid --disposition {disp!r}")
        return f"APPLIED: {args.id} → {disp} {args.action.strip()} {ts}"

    if kind == "gate":
        if not args.target or not args.sha or not args.route or not args.verdict:
            raise ValueError("--kind gate requires --target, --sha, --route, and --verdict")
        if args.route not in VALID_ROUTES:
            raise ValueError(f"invalid --route {args.route!r}")
        if args.verdict not in ("green", "red"):
            raise ValueError(f"invalid --verdict {args.verdict!r}")
        if args.seconds is not None and args.seconds < 0:
            raise ValueError("--seconds must be non-negative")
        dur = f"{args.seconds}s" if args.seconds is not None else "(duration not recorded)"
        if args.target == "final-QA":
            if args.seconds is not None:
                return f"GATE: final-QA {args.sha} {args.route} {dur} {args.verdict}"
            return f"GATE: final-QA {args.sha} {args.route} {args.verdict} {dur}"
        if args.seconds is not None:
            return f"GATE: {args.target} head {args.sha} {args.route} {dur} {args.verdict}"
        return f"GATE: {args.target} head {args.sha} {args.route} {args.verdict} {dur}"

    raise ValueError(f"unsupported --kind {kind!r}")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Kickstart v1 run-record contract CLI (GH-1543 / KS-15)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_val = sub.add_parser("validate", help="parse and validate a v1 run record")
    p_val.add_argument("record", help="path to run record file")
    p_val.add_argument("--require-landing-clone", action="store_true")
    p_val.add_argument("--json", action="store_true", dest="as_json")

    p_app = sub.add_parser("append", help="atomically validate and append one v1 event line")
    p_app.add_argument("record", help="path to run record file")
    p_app.add_argument("--kind", choices=["operator-amendment", "parent-note", "intervention", "applied", "gate"])
    p_app.add_argument("--line", help="raw formatted v1 event line (alternative to --kind)")
    p_app.add_argument("--id")
    p_app.add_argument("--ts", help="UTC timestamp YYYY-MM-DDTHH:MM[:SS]Z (default: now)")
    p_app.add_argument("--text")
    p_app.add_argument("--disposition", choices=["applied", "superseded", "escalated"])
    p_app.add_argument("--action")
    p_app.add_argument("--target")
    p_app.add_argument("--sha")
    p_app.add_argument("--route", choices=sorted(VALID_ROUTES))
    p_app.add_argument("--seconds", type=int)
    p_app.add_argument("--verdict", choices=["green", "red"])
    p_app.add_argument("--require-landing-clone", action="store_true")

    p_snap = sub.add_parser("snapshot", help="emit a redacted snapshot of a run record")
    p_snap.add_argument("record", help="path to run record file")
    p_snap.add_argument("--out", help="write redacted snapshot atomically here instead of stdout")

    p_cp = sub.add_parser("checkpoint", help="commit (and optionally push) a redacted snapshot to a dedicated branch clone")
    p_cp.add_argument("--record", required=True, help="path to source run record")
    p_cp.add_argument("--clone", required=True, help="path to dedicated clean run-record clone")
    p_cp.add_argument("--primary", required=True, help="path to primary checkout (must differ from --clone)")
    p_cp.add_argument("--branch", required=True, help="dedicated non-integration branch name")
    p_cp.add_argument("--dest", required=True, help="relative destination path inside --clone")
    p_cp.add_argument("--message", help="commit message")
    p_cp.add_argument("--push", action="store_true", help="push explicitly to origin HEAD:refs/heads/<branch>")

    args = ap.parse_args(argv)
    try:
        if args.cmd == "validate":
            rec = Path(args.record)
            if not rec.is_file():
                sys.stderr.write(f"run_record: file not found: {rec}\n")
                return 1
            parsed = parse_record(rec.read_text(encoding="utf-8"), require_landing_clone=args.require_landing_clone)
            if args.as_json:
                print(json.dumps(parsed, indent=2, sort_keys=True))
            else:
                if parsed["valid"]:
                    print(
                        f"OK v{parsed['version']} landing_clone={parsed['landing_clone'] or 'none'} "
                        f"amendments={len(parsed['amendments'])} unresolved={len(parsed['unresolved_amendments'])} "
                        f"interventions={len(parsed['interventions'])} gates={len(parsed['gates'])}"
                    )
                else:
                    for err in parsed["errors"]:
                        sys.stderr.write(f"run_record: {err}\n")
            return 0 if parsed["valid"] else 1

        if args.cmd == "append":
            if bool(args.line) == bool(args.kind):
                sys.stderr.write("run_record: specify exactly one of --kind or --line\n")
                return 2
            line = args.line if args.line else _format_append_line(args)
            atomic_append(Path(args.record), line, require_landing_clone=args.require_landing_clone)
            print(line)
            return 0

        if args.cmd == "snapshot":
            out_p = Path(args.out) if args.out else None
            redacted = write_snapshot(Path(args.record), out_p)
            if out_p is None:
                sys.stdout.write(redacted)
            return 0

        if args.cmd == "checkpoint":
            res = checkpoint_record(
                Path(args.record),
                Path(args.clone),
                Path(args.primary),
                args.branch,
                args.dest,
                message=args.message,
                push=args.push,
            )
            print(json.dumps(res, indent=2, sort_keys=True))
            return 0

    except Exception as exc:
        sys.stderr.write(f"run_record: {exc}\n")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
