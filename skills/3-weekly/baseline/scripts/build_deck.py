#!/usr/bin/env python3
"""Build a self-contained Baseline slide deck (one HTML file) from a JSON spec.

Usage:
    build_deck.py <spec.json> [--out <deck.html>] [--check]

Exit codes: 0 built (or valid with --check), 1 could not read or write, 2 the spec is invalid.

The spec is refused, never trimmed: a slide that does not fit is a slide that still
carries the thread's noise, and only the author can decide what to cut.
"""
import argparse
import hashlib
import html
import json
import re
import subprocess
import sys
from pathlib import Path

GRADES = ("confirmed", "partly", "not-found", "unverified")
CHECKED_GRADES = ("confirmed", "partly", "not-found")
ASK_TYPES = ("change", "carve-out", "fix", "explain", "measure", "keep", "decide")
# Asks that alter the rule or its tooling need at least one claim that held up.
EVIDENCE_BACKED_ASKS = ("change", "carve-out", "fix")
MAX_ITEMS = 7
TEMPLATE = Path(__file__).resolve().parent.parent / "assets" / "deck-template.html"


def validate(spec):
    """Return a list of 'path: problem' strings; empty means the spec is buildable."""
    errors = []

    def text(obj, key, path, cap, required=True):
        value = obj.get(key) if isinstance(obj, dict) else None
        if value is None or value == "":
            if required:
                errors.append("%s.%s: required" % (path, key))
            return ""
        if not isinstance(value, str):
            errors.append("%s.%s: must be a string" % (path, key))
            return ""
        if len(value) > cap:
            errors.append("%s.%s: %d characters, the slide holds %d" % (path, key, len(value), cap))
        return value

    def rows(obj, key, path, low, high):
        value = obj.get(key, []) if isinstance(obj, dict) else []
        if not isinstance(value, list) or not all(isinstance(v, (dict, str)) for v in value):
            errors.append("%s.%s: must be a list" % (path, key))
            return []
        if not low <= len(value) <= high:
            errors.append("%s.%s: %d entries, expected %d to %d" % (path, key, len(value), low, high))
        return value

    if not isinstance(spec, dict):
        return ["spec: must be a JSON object"]

    text(spec, "title", "spec", 90)
    text(spec, "date", "spec", 10)
    text(spec, "repo", "spec", 80, required=False)
    text(spec, "commit", "spec", 40, required=False)
    text(spec, "prepared_for", "spec", 80, required=False)
    text(spec, "prepared_by", "spec", 120, required=False)
    for i, src in enumerate(rows(spec, "sources", "spec", 1, 8)):
        text(src, "label", "sources[%d]" % i, 60)
        text(src, "url", "sources[%d]" % i, 300, required=False)

    heard = spec.get("heard")
    if not isinstance(heard, dict):
        errors.append("spec.heard: required")
        heard = {}
    text(heard, "summary", "heard", 420)
    for i, q in enumerate(rows(heard, "quotes", "heard", 0, 3)):
        text(q, "text", "heard.quotes[%d]" % i, 280)
        text(q, "who", "heard.quotes[%d]" % i, 60)
        text(q, "source", "heard.quotes[%d]" % i, 80, required=False)
    for i, line in enumerate(rows(heard, "not_saying", "heard", 0, 3)):
        if not isinstance(line, str) or not line or len(line) > 160:
            errors.append("heard.not_saying[%d]: a string of 1 to 160 characters" % i)

    items = rows(spec, "items", "spec", 1, MAX_ITEMS)
    if len(items) > MAX_ITEMS:
        errors.append("spec.items: move the rest to 'parked'; a longer deck is the thread again")
    for i, item in enumerate(items):
        path = "items[%d]" % i
        if not isinstance(item, dict):
            errors.append("%s: must be an object" % path)
            continue
        text(item, "title", path, 90)
        said = item.get("said") if isinstance(item.get("said"), dict) else {}
        text(said, "text", path + ".said", 280)
        text(said, "who", path + ".said", 60)
        text(said, "source", path + ".said", 80, required=False)
        text(item, "event", path, 320)

        held_up = False
        for j, ev in enumerate(rows(item, "evidence", path, 1, 4)):
            epath = "%s.evidence[%d]" % (path, j)
            if not isinstance(ev, dict):
                errors.append("%s: must be an object" % epath)
                continue
            text(ev, "claim", epath, 180)
            grade = ev.get("grade")
            if grade not in GRADES:
                errors.append("%s.grade: one of %s" % (epath, ", ".join(GRADES)))
            if grade in CHECKED_GRADES:
                text(ev, "ref", epath, 160)  # where it was checked
            else:
                text(ev, "ref", epath, 160, required=False)
            if grade == "unverified":
                text(ev, "settle", epath, 180)  # what would settle it
            else:
                text(ev, "settle", epath, 180, required=False)
            text(ev, "url", epath, 300, required=False)
            held_up = held_up or grade in ("confirmed", "partly")

        rule = item.get("rule") if isinstance(item.get("rule"), dict) else {}
        text(rule, "text", path + ".rule", 280)
        text(rule, "ref", path + ".rule", 160, required=False)
        text(rule, "url", path + ".rule", 300, required=False)
        text(item, "cost", path, 240)
        text(item, "need", path, 180)
        ask = item.get("ask") if isinstance(item.get("ask"), dict) else {}
        text(ask, "text", path + ".ask", 240)
        if ask.get("type") not in ASK_TYPES:
            errors.append("%s.ask.type: one of %s" % (path, ", ".join(ASK_TYPES)))
        elif ask["type"] in EVIDENCE_BACKED_ASKS and not held_up:
            errors.append(
                "%s.ask.type: '%s' needs at least one confirmed or partly-confirmed claim; "
                "use measure, explain, keep or decide" % (path, ask["type"])
            )
        text(item, "owner", path, 60)
        question = text(item, "question", path, 160)
        if question and (not question.rstrip().endswith("?") or question.count("?") != 1):
            errors.append("%s.question: exactly one question, ending in '?'" % path)

    for i, parked in enumerate(rows(spec, "parked", "spec", 0, 8)):
        text(parked, "text", "parked[%d]" % i, 160)
        text(parked, "why", "parked[%d]" % i, 160, required=False)
    return errors


def render(spec):
    spec = dict(spec)
    spec.pop("id", None)
    # Saved answers are keyed by slide position, so any spec change starts the answers fresh.
    seed = json.dumps(spec, sort_keys=True, ensure_ascii=False)
    spec["id"] = hashlib.sha1(seed.encode("utf-8")).hexdigest()[:12]
    # No raw "<" inside the <script> element: "</script" and "<!--" would end or derail it.
    # \u003c is a valid JSON escape, so the text parses back unchanged.
    payload = json.dumps(spec, ensure_ascii=False).replace("<", "\\u003c")
    template = TEMPLATE.read_text(encoding="utf-8")
    for marker in ("__DECK_TITLE__", "__DECK_DATA__"):
        if template.count(marker) != 1:
            raise ValueError("template %s must contain %s exactly once" % (TEMPLATE, marker))
    # One pass, so a title or a quote that happens to contain a marker is left as text.
    values = {"__DECK_TITLE__": html.escape("Baseline: " + spec["title"]), "__DECK_DATA__": payload}
    return re.sub("__DECK_(?:TITLE|DATA)__", lambda match: values[match.group(0)], template)


def warn_if_tracked(out):
    """The deck quotes people; say so if git would pick the file up."""
    try:
        inside = subprocess.run(
            ["git", "-C", str(out.parent), "rev-parse", "--is-inside-work-tree"],
            capture_output=True, text=True,
        )
        if inside.returncode != 0:
            return
        ignored = subprocess.run(
            ["git", "-C", str(out.parent), "check-ignore", "-q", str(out)], capture_output=True
        )
        if ignored.returncode == 1:
            print(
                "baseline: warning: %s is not git-ignored. The deck quotes people; "
                "keep it out of commits." % out,
                file=sys.stderr,
            )
    except OSError:
        return


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("spec", type=Path, help="deck spec (JSON)")
    parser.add_argument("--out", type=Path, help="output HTML (default: beside the spec)")
    parser.add_argument("--check", action="store_true", help="validate only, write nothing")
    args = parser.parse_args(argv)

    try:
        spec = json.loads(args.spec.read_text(encoding="utf-8"))
    except OSError as exc:
        print("baseline: cannot read %s: %s" % (args.spec, exc), file=sys.stderr)
        return 1
    except ValueError as exc:
        print("baseline: %s is not valid JSON: %s" % (args.spec, exc), file=sys.stderr)
        return 2

    errors = validate(spec)
    if errors:
        print("baseline: %d problem(s) in %s" % (len(errors), args.spec), file=sys.stderr)
        for line in errors:
            print("  - " + line, file=sys.stderr)
        return 2
    slides = 3 + 2 * len(spec["items"]) + (1 if spec.get("parked") else 0)
    if args.check:
        print("baseline: spec ok, %d items, %d slides" % (len(spec["items"]), slides))
        return 0

    out = args.out or args.spec.with_suffix(".html")
    try:
        page = render(spec)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(page, encoding="utf-8")
    except (OSError, ValueError) as exc:
        print("baseline: cannot build %s: %s" % (out, exc), file=sys.stderr)
        return 1
    warn_if_tracked(out.resolve())
    print("baseline: wrote %s (%d items, %d slides)" % (out, len(spec["items"]), slides))
    return 0


if __name__ == "__main__":
    sys.exit(main())
