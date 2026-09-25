#!/usr/bin/env python3
"""Report declared negative-control evidence for validate.sh decision gates.

Discovery deliberately comes from validate.sh's TESTS array: adding a registered
executable gate therefore adds an inventory row without a second registry edit.
Evidence is deliberately separate from discovery and lives beside the gate as a
single JSON comment, for example::

    # gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"rejected fixture"}

An absent declaration is reported as explicit ``none``.  This tool never treats a
filename, a successful invocation, or a prose mention as negative-control evidence.
"""

from __future__ import annotations

import argparse
import json
import hashlib
import shlex
import subprocess
import re
import sys
from pathlib import Path
from typing import Any


ACCEPTED_FORMS = {
    "pre-fix-replay",
    "deliberate-mutation",
    "controlled-bad-fixture",
}
EVIDENCE_RE = re.compile(r"^\s*#\s*gate-evidence:\s*(\{.*\})\s*$", re.MULTILINE)
TESTS_RE = re.compile(r"^TESTS=\((.*?)^\)", re.MULTILINE | re.DOTALL)
QUOTED_ENTRY_RE = re.compile(r'"([^"\n]+)"')
SELF_COMPARISON_RE = re.compile(
    r"\b(?:cmp|diff)\s+(?P<left>[^\s;|]+)\s+(?P=left)(?:\s|$)"
)
COMPARISON_RE = re.compile(r"\b(?:cmp|diff)\s+([^\s;|]+)")
REDIRECT_RE = re.compile(r">\s*([^\s;|]+)")
GENERATE_RE = re.compile(r"\b(?:gen(?:erate)?|render|build|make|write|update|regen(?:erate)?)\w*\b", re.I)
SNAPSHOT_NAME_RE = re.compile(r"(?:expected|golden|snapshot|baseline|artifact)", re.I)
HEREDOC_RE = re.compile(r"<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)")


def registered_gates(root: Path) -> list[str]:
    """Return the registered shell gates, in validate.sh order."""
    validate = root / "validate.sh"
    return registered_entries(validate.read_text(encoding="utf-8"))


def registered_entries(source: str) -> list[str]:
    """Parse registry text without evaluating a candidate runner."""
    match = TESTS_RE.search(source)
    if not match:
        raise ValueError("could not find TESTS array")
    entries = shlex.split(match.group(1), comments=True)
    if not entries or len(entries) != len(set(entries)):
        raise ValueError("TESTS must contain nonempty, unique literal entries")
    if any(not re.fullmatch(r"[A-Za-z0-9_./-]+\.sh", entry) for entry in entries):
        raise ValueError("TESTS contains unsupported nonliteral entries")
    return entries


def source_outside_heredocs(source: str) -> str:
    """Ignore fixture payloads: comments and commands in them are not this gate's code."""
    executable_lines: list[str] = []
    heredoc_end: str | None = None
    for line in source.splitlines():
        if heredoc_end is not None:
            if line.strip() == heredoc_end:
                heredoc_end = None
            continue
        executable_lines.append(line)
        heredoc = HEREDOC_RE.search(line)
        if heredoc:
            heredoc_end = heredoc.group(1)
    return "\n".join(executable_lines)


def declared_evidence(source: str) -> tuple[dict[str, Any] | None, str | None]:
    """Read the one machine-readable declaration; reject ambiguity or bad shape."""
    declarations = EVIDENCE_RE.findall(source_outside_heredocs(source))
    if not declarations:
        return None, None
    if len(declarations) != 1:
        return None, "multiple gate-evidence declarations"
    try:
        evidence = json.loads(declarations[0])
    except json.JSONDecodeError as error:
        return None, f"invalid gate-evidence JSON: {error.msg}"
    if not isinstance(evidence, dict):
        return None, "gate-evidence must be a JSON object"
    if evidence.get("form") not in ACCEPTED_FORMS:
        return None, "gate-evidence form must be an accepted negative-control form"
    if evidence.get("observed") is not True:
        return None, "gate-evidence must record observed: true"
    if not isinstance(evidence.get("result"), str) or not evidence["result"].strip():
        return None, "gate-evidence must record a non-empty result"
    return evidence, None


def disqualifying_shapes(source: str) -> list[str]:
    """Find the two known structures that cannot falsify a drift/parity claim."""
    executable = "\n".join(
        line for line in source_outside_heredocs(source).splitlines()
        if not line.lstrip().startswith("#")
    )
    shapes: list[str] = []
    if SELF_COMPARISON_RE.search(executable):
        shapes.append("self-comparing-parity")

    redirected = {
        target
        for line in executable.splitlines()
        if GENERATE_RE.search(line)
        for target in REDIRECT_RE.findall(line)
        if SNAPSHOT_NAME_RE.search(target)
    }
    compared = {operand for operand in COMPARISON_RE.findall(executable)}
    if redirected & compared:
        shapes.append("self-regenerating-drift")
    return shapes


def no_evidence(reason: str) -> dict[str, Any]:
    return {"observed": False, "form": "none", "result": "none", "reason": reason}


def inventory(root: Path) -> dict[str, Any]:
    """Build the machine-readable inventory without executing any gate."""
    rows: list[dict[str, Any]] = []
    for entry in registered_gates(root):
        path = root / "test" / entry
        source = path.read_text(encoding="utf-8") if path.is_file() else ""
        shapes = disqualifying_shapes(source)
        evidence, error = declared_evidence(source)
        if not path.is_file():
            negative_control = no_evidence("registered gate file is missing")
        elif shapes:
            negative_control = no_evidence(
                "structurally incapable of falsifying its claim: " + ", ".join(shapes)
            )
        elif error:
            negative_control = no_evidence(error)
        elif evidence is None:
            negative_control = no_evidence("no declared negative-control evidence")
        else:
            negative_control = evidence
        rows.append(
            {
                "gate": f"test/{entry}",
                "discovered_from": "validate.sh:TESTS",
                "disqualifying_shapes": shapes,
                "negative_control": negative_control,
            }
        )
    return {
        "schema_version": 1,
        "scope": "registered executable decision gates",
        "discovery": "validate.sh:TESTS",
        "gates": rows,
    }



def audit(root: Path) -> dict[str, Any]:
    """Read canonical discovery/selection; source references are not execution proof."""
    gates = registered_gates(root)
    tracked = subprocess.check_output(
        ["git", "-C", str(root), "ls-files", "test"], text=True
    ).splitlines()
    if not tracked:
        raise ValueError("empty tracked test discovery")
    routes = subprocess.check_output(
        ["bash", str(root / "utils/ci-route.sh"), "subsystems"], text=True
    ).splitlines()
    if not routes:
        raise ValueError("empty subsystem discovery")
    ownership: dict[str, list[str]] = {}
    for line in routes:
        subsystem, entries = line.split("\t", 1)
        for entry in entries.split():
            ownership.setdefault(entry, []).append(subsystem)
    runners = {name: (root / name).read_text() for name in ("validate.sh", "ci-local.sh")}
    sources = {name: (root / name).read_text(encoding="utf-8") for name in tracked if name.endswith((".sh", ".py", ".js", ".mjs"))}
    rows = []
    for name in tracked:
        if not name.endswith((".sh", ".py", ".js", ".mjs")):
            continue
        path = root / name
        entry = name.removeprefix("test/")
        selected = []
        references = []
        if entry in gates:
            selected = list(runners)
            references = ["validate.sh:TESTS", "ci-local.sh:read_tests"]
            state = "registered-shell"
        elif name.startswith("test/lib/") or Path(name).name in {"_setup.sh", "_scratch-repo.sh"}:
            state = "helper"
        else:
            # Literal direct callers/imports only; dynamic dispatch remains explicitly unknown.
            tokens = {name, Path(name).name}
            if name.endswith(".py"):
                tokens.add(Path(name).stem)
            for caller in tracked:
                if caller == name or not caller.endswith((".sh", ".py", ".js")):
                    continue
                caller_source = sources[caller]
                if any(token in caller_source for token in tokens):
                    references.append(caller)
            selected = [runner for runner, text in runners.items() if name in text]
            if name.startswith("test/flightdeck/") and name.endswith(".py"):
                selected = [runner for runner, text in runners.items() if '"$HERE/test/flightdeck/"' in text]
            if name.startswith("test/unit/") and name.endswith(".test.js"):
                selected = [runner for runner, text in runners.items() if "npm run test:unit" in text]
            state = "explicit-non-shell-lane" if selected else "reference-only-or-uncollected"
        rows.append({"path": name, "classification": state, "selected_by": selected,
                     "subsystems": ownership.get(entry, []), "source_references": sorted(set(references)),
                     "coverage_review": "unreviewed"})
    return {"schema_version": 1, "mode": "observe", "registered_shell_suites": len(gates),
            "tracked_shell_files": sum(name.endswith(".sh") for name in tracked),
            "rows": rows, "limitations": [
                "Literal source references may be comments, fixtures or imports; they are not execution proof.",
                "Dynamic collectors and case/assertion/invariant counts require focused runtime evidence.",
                "Negative-control declarations and advisory review metadata are not authenticated approvals."]}


def decision_view(root: Path, path: Path) -> dict[str, Any]:
    """Validate bounded advisory metadata; NEVER infer authentication from candidate files."""
    records = json.loads(path.read_text())
    if not isinstance(records, list) or not records:
        raise ValueError("decision input must be a nonempty list")
    ids: set[str] = set()
    result = []
    for record in records:
        if not isinstance(record, dict):
            raise ValueError("decision must be an object")
        errors = []
        for field in ("id", "behavior", "consequence", "issue", "overlap", "reason", "reviewer", "review_source", "routing", "red_evidence"):
            if not isinstance(record.get(field), str) or not record[field].strip():
                errors.append(f"missing {field}")
        ident = record.get("id")
        if isinstance(ident, str):
            if ident in ids:
                errors.append("duplicate id")
            ids.add(ident)
        if record.get("outcome") not in {"reuse", "extend", "add", "no-add"}:
            errors.append("invalid outcome")
        bindings = record.get("content")
        if not isinstance(bindings, dict) or not bindings:
            errors.append("missing content bindings")
        else:
            for name, expected in bindings.items():
                file = (root / name).resolve()
                if not file.is_relative_to(root) or not file.is_file():
                    errors.append(f"missing/outside content: {name}")
                elif not isinstance(expected, str) or hashlib.sha256(file.read_bytes()).hexdigest() != expected:
                    errors.append(f"stale content: {name}")
        if record.get("reviewer") == record.get("proposer"):
            errors.append("self-issued review")
        result.append({**record, "state": "unreviewed" if errors else "advisory-reviewed",
                       "metadata_errors": errors, "approval_trusted": False,
                       "would_refuse_mandatory": True,
                       "authority_reason": "No authenticated reviewer/check authority is configured"})
    return {"schema_version": 1, "mode": "observe", "enforcement": "disabled", "decisions": result}

def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] == "admission":
        import test_admission
        return test_admission.main(argv[1:])
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--json", action="store_true", help="emit JSON (the default output format)")
    parser.add_argument("--audit", action="store_true", help="read-only discovery and routing view (not collection proof)")
    parser.add_argument("--decisions", type=Path, help="validate advisory decision JSON; does not approve admission")
    args = parser.parse_args(argv)
    try:
        root = args.root.resolve()
        report = audit(root) if args.audit else inventory(root)
        if args.decisions:
            report["admission"] = decision_view(root, args.decisions)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"gate-inventory: {error}", file=sys.stderr)
        return 2
    json.dump(report, sys.stdout, indent=2, sort_keys=True)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
