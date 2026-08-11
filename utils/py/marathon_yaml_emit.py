#!/usr/bin/env python3
"""Emit a runnable MARATHON.yaml from a generated plan and preflight packets.

Documented command (run from the target repository root):

    python3 utils/py/marathon_yaml_emit.py \
      --plan PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md \
      --packets relay-system/preflight/YYYY-MM-DD \
      --reviewer agy \
      --output PROJECT/2-WORKING/MY-MARATHON/MARATHON.yaml

The plan supplies ranked lane order and real dependencies. Each packet supplies
the phase id, executable brief path, and artifact allowlist. The output is not
written until the complete join has been validated.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path


class EmitError(Exception):
    """A user-facing input or join error."""


@dataclass(frozen=True)
class Lane:
    issue: int
    title: str
    dependency_issue: int | None
    score: float


@dataclass(frozen=True)
class Packet:
    issue: int
    path: Path
    artifact: str


def split_markdown_row(line: str) -> list[str]:
    """Split a Markdown table row without treating an escaped pipe as a cell."""
    stripped = line.strip()
    if not (stripped.startswith("|") and stripped.endswith("|")):
        return []
    cells: list[str] = []
    current: list[str] = []
    escaped = False
    for char in stripped[1:-1]:
        if escaped:
            current.append(char)
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == "|":
            cells.append("".join(current).strip())
            current = []
        else:
            current.append(char)
    if escaped:
        current.append("\\")
    cells.append("".join(current).strip())
    return cells


def parse_plan(path: Path) -> list[Lane]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise EmitError(f"cannot read plan {path}: {exc}") from exc

    section_start = next(
        (i for i, line in enumerate(lines) if line.strip() == "## Per-item scoring"), None
    )
    if section_start is None:
        raise EmitError(f"plan {path} has no '## Per-item scoring' section")

    table_lines: list[str] = []
    for line in lines[section_start + 1 :]:
        if line.startswith("## "):
            break
        if line.lstrip().startswith("|"):
            table_lines.append(line)
    if len(table_lines) < 3:
        raise EmitError(f"plan {path} has no lane rows in its Per-item scoring table")

    header = split_markdown_row(table_lines[0])
    required = ("Item", "deps", "score")
    if not all(name in header for name in required):
        raise EmitError(
            f"plan {path} Per-item scoring table must contain columns: {', '.join(required)}"
        )
    item_i, deps_i, score_i = (header.index(name) for name in required)

    lanes: list[Lane] = []
    seen: set[int] = set()
    last_score = float("-inf")
    for raw in table_lines[2:]:
        cells = split_markdown_row(raw)
        if len(cells) != len(header):
            raise EmitError(f"plan {path} has a malformed scoring row: {raw.strip()}")
        item = cells[item_i]
        match = re.match(r"^\[#([0-9]+)\]\s+(.+)$", item)
        if not match:
            raise EmitError(
                f"plan {path} lane row is not issue-backed and cannot be matched to a packet: {item}"
            )
        issue = int(match.group(1))
        if issue in seen:
            raise EmitError(f"plan {path} contains duplicate lane #{issue}")
        seen.add(issue)

        deps_cell = cells[deps_i].strip()
        dep_issue: int | None = None
        if deps_cell not in ("", "-", "—"):
            dep_tokens = [token.strip() for token in deps_cell.split(",")]
            if len(dep_tokens) != 1 or not re.fullmatch(r"#[0-9]+", dep_tokens[0]):
                raise EmitError(
                    f"plan lane #{issue} records unsupported dependencies '{deps_cell}'; "
                    "MARATHON.yaml accepts one scalar dependency"
                )
            dep_issue = int(dep_tokens[0][1:])

        try:
            score = float(cells[score_i])
        except ValueError as exc:
            raise EmitError(
                f"plan lane #{issue} has a non-numeric ranking score '{cells[score_i]}'"
            ) from exc
        if score < last_score:
            raise EmitError(
                f"plan {path} scoring rows are not in score-ascending lane order at #{issue}"
            )
        last_score = score
        lanes.append(Lane(issue, match.group(2).strip(), dep_issue, score))

    if not lanes:
        raise EmitError(f"plan {path} contains no active issue-backed lanes")
    return lanes


def one_packet_field(path: Path, lines: list[str], label: str) -> str:
    prefix = f"- {label}:"
    values = [line[len(prefix) :].strip() for line in lines if line.startswith(prefix)]
    if len(values) != 1 or not values[0]:
        raise EmitError(
            f"malformed packet {path}: expected exactly one non-empty '{prefix}' field"
        )
    return values[0]


def parse_packet(path: Path) -> Packet:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise EmitError(f"cannot read packet {path}: {exc}") from exc

    headings = [
        re.fullmatch(r"# Marathon preflight packet — ([a-z0-9][a-z0-9._-]*)", line)
        for line in lines
    ]
    headings = [match for match in headings if match]
    if len(headings) != 1:
        raise EmitError(f"malformed packet {path}: expected exactly one preflight packet heading")
    phase_id = headings[0].group(1)
    slug_issue = re.match(r"^gh-([0-9]+)(?:-|$)", phase_id)
    if not slug_issue:
        raise EmitError(
            f"malformed packet {path}: phase slug '{phase_id}' does not identify a GH issue"
        )
    issue = int(slug_issue.group(1))

    sources = one_packet_field(path, lines, "Sources")
    if not re.search(rf"(?:^|[/\\])GH-{issue}(?:-|\.)", sources, re.IGNORECASE):
        raise EmitError(
            f"malformed packet {path}: Sources does not name the capture doc for issue #{issue}"
        )
    verdict = one_packet_field(path, lines, "Verdict")
    if verdict.lower() != "ready":
        raise EmitError(f"malformed packet {path}: Verdict is '{verdict}', expected 'ready'")

    artifact = one_packet_field(path, lines, "Artifacts")
    artifacts = [part.strip() for part in artifact.split(",")]
    if any(not part for part in artifacts) or len(set(artifacts)) != len(artifacts):
        raise EmitError(f"malformed packet {path}: Artifacts contains an empty or duplicate path")
    return Packet(issue, path, ",".join(artifacts))


def collect_packets(root: Path) -> dict[int, Packet]:
    if not root.is_dir():
        raise EmitError(f"packet directory not found: {root}")
    packets: dict[int, Packet] = {}
    for path in sorted(root.rglob("packet.md")):
        packet = parse_packet(path)
        if packet.issue in packets:
            raise EmitError(
                f"duplicate packet for lane #{packet.issue}: {packets[packet.issue].path} and {path}"
            )
        packets[packet.issue] = packet
    return packets


def brief_value(path: Path) -> str:
    resolved = path.resolve()
    cwd = Path.cwd().resolve()
    try:
        return resolved.relative_to(cwd).as_posix()
    except ValueError:
        return resolved.as_posix()


def safe_scalar(value: str, field: str, packet: Path | None = None) -> str:
    if not value or "\n" in value or "\r" in value or " #" in value:
        where = f" from packet {packet}" if packet else ""
        raise EmitError(
            f"{field}{where} cannot be represented by the constrained MARATHON.yaml reader: {value!r}"
        )
    return value


def render(lanes: list[Lane], packets: dict[int, Packet], reviewer: str, plan: Path) -> str:
    lane_issues = {lane.issue for lane in lanes}
    packet_issues = set(packets)
    missing = [lane for lane in lanes if lane.issue not in packet_issues]
    if missing:
        detail = ", ".join(f"packet for lane #{lane.issue} ({lane.title})" for lane in missing)
        raise EmitError(f"missing {detail} under the supplied packet directory")
    unmatched = sorted(packet_issues - lane_issues)
    if unmatched:
        packet = packets[unmatched[0]]
        raise EmitError(
            f"packet {packet.path} (lane #{packet.issue}) does not correspond to a lane in plan {plan}"
        )

    for lane in lanes:
        if lane.dependency_issue is not None and lane.dependency_issue not in lane_issues:
            raise EmitError(
                f"plan lane #{lane.issue} depends on #{lane.dependency_issue}, which is not an emitted lane"
            )

    plan_name = re.sub(r"[^a-z0-9._-]+", "-", plan.stem.lower()).strip("-._") or "marathon"
    output = [
        "# Generated by utils/py/marathon_yaml_emit.py; edit the plan or packets, then re-emit.",
        f"name: {plan_name}",
        "phases:",
    ]
    reviewer_value = safe_scalar(reviewer, "reviewer")
    phase_ids = {lane.issue: f"gh{lane.issue}" for lane in lanes}
    for lane in lanes:
        packet = packets[lane.issue]
        output.extend(
            [
                f"  - id: {phase_ids[lane.issue]}",
                f"    reviewer: {reviewer_value}",
                f"    brief: {safe_scalar(brief_value(packet.path), 'brief', packet.path)}",
                f"    artifact: {safe_scalar(packet.artifact, 'artifact', packet.path)}",
            ]
        )
        if lane.dependency_issue is not None:
            output.append(f"    depends_on: {phase_ids[lane.dependency_issue]}")
    return "\n".join(output) + "\n"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Emit MARATHON.yaml by joining a generated plan with ready preflight packets."
    )
    parser.add_argument("--plan", required=True, type=Path, help="generated marathon plan Markdown")
    parser.add_argument(
        "--packets", required=True, type=Path, help="directory containing per-lane packet.md files"
    )
    parser.add_argument(
        "--reviewer",
        required=True,
        help="explicit reviewer id; must start with codex, gemini, or agy",
    )
    parser.add_argument("--output", required=True, type=Path, help="MARATHON.yaml path to write")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if not re.match(r"^(codex|gemini|agy)", args.reviewer):
        raise EmitError(
            f"reviewer '{args.reviewer}' must start with codex, gemini, or agy; no default is used"
        )
    if not args.output.parent.is_dir():
        raise EmitError(f"output parent directory not found: {args.output.parent}")

    plan_resolved = args.plan.resolve()
    output_resolved = args.output.resolve()
    packets = collect_packets(args.packets)
    protected = {plan_resolved, *(packet.path.resolve() for packet in packets.values())}
    if output_resolved in protected:
        raise EmitError(f"output path would overwrite an input: {args.output}")

    lanes = parse_plan(args.plan)
    rendered = render(lanes, packets, args.reviewer, args.plan)
    args.output.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except EmitError as exc:
        print(f"marathon-yaml-emit: {exc}", file=sys.stderr)
        raise SystemExit(1)
