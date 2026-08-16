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
    match = TESTS_RE.search(validate.read_text(encoding="utf-8"))
    if not match:
        raise ValueError(f"could not find TESTS array in {validate}")
    return [entry for entry in QUOTED_ENTRY_RE.findall(match.group(1)) if entry.endswith(".sh")]


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


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--json", action="store_true", help="emit JSON (the default output format)")
    args = parser.parse_args(argv)
    try:
        report = inventory(args.root.resolve())
    except (OSError, ValueError) as error:
        print(f"gate-inventory: {error}", file=sys.stderr)
        return 2
    json.dump(report, sys.stdout, indent=2, sort_keys=True)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
