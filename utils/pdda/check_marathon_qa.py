#!/usr/bin/env python3
"""check_marathon_qa.py — Mechanical marathon Wave QA receipt & checklist gate (GH-784).

Asserts that:
1. Every marathon plan doc carries an '## Acceptance & Quality Checklist'.
2. Each wave defines the 3 mandatory items:
   - Wave N Proof of Done Test Suite Green
   - Wave N Post-Build Codex QA Relay executed (receipt recorded under relay-system/...)
   - Wave N CodeRabbit / Peer Review findings adjudicated
3. For any checked item (- [x]) citing a relay transcript, the transcript file
   exists on disk relative to the repository root.
4. When --pre-pr is passed (or doc is in 3-COMPLETED / marked Completed), all waves
   must be verified (- [x]) and all on-disk transcripts must exist before a PR can
   be created or a plan promoted.
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone


def find_repo_root():
    candidate = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    if os.path.isdir(os.path.join(candidate, ".git")) or os.path.isfile(os.path.join(candidate, ".git")):
        return candidate
    return os.getcwd()


class MarathonQAChecker:
    def __init__(self, root, mode="observe", fmt="text", pre_pr=False, strict=False):
        self.root = os.path.abspath(root)
        self.mode = mode
        self.format = fmt
        self.pre_pr = pre_pr
        self.strict = strict
        self.errors = 0
        self.warns = 0
        self.info = 0
        self.findings = []

    def record(self, severity, file_path, line_no, message, action=""):
        rel_path = os.path.relpath(file_path, self.root) if file_path.startswith(self.root) else file_path
        if severity == "error":
            self.errors += 1
        elif severity == "warn":
            self.warns += 1
        else:
            self.info += 1

        finding = {
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "severity": severity,
            "check": "pdda-check-marathon-qa",
            "file": rel_path,
            "line": line_no,
            "message": message,
            "action": action,
        }
        self.findings.append(finding)

        if self.format == "json":
            sys.stdout.write(json.dumps(finding) + "\n")
        elif self.format == "tsv":
            sys.stdout.write(f"{severity}\t{rel_path}\t{line_no}\t{message}\t{action}\n")
        else:
            prefix = severity.upper()
            action_suffix = f" — {action}" if action else ""
            sys.stdout.write(f"{prefix} [pdda-check-marathon-qa] {rel_path}:{line_no} {message}{action_suffix}\n")

    def parse_doc(self, file_path, explicit_target=False):
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except Exception as e:
            self.record("error", file_path, 1, f"failed to read file: {e}", "fix-file-access")
            return

        is_completed_dir = "PROJECT/3-COMPLETED" in file_path
        frontmatter = {}
        in_fm = False
        body_start = 0

        for idx, line in enumerate(lines):
            stripped = line.strip()
            if idx == 0 and stripped == "---":
                in_fm = True
                continue
            if in_fm:
                if stripped == "---":
                    in_fm = False
                    body_start = idx + 1
                    break
                if ":" in line:
                    k, v = line.split(":", 1)
                    frontmatter[k.strip().lower()] = v.strip().strip("'\"")

        doc_status = frontmatter.get("status", "").lower()
        is_completed = is_completed_dir or "completed" in doc_status or "shipped" in doc_status
        must_be_complete = self.pre_pr or is_completed

        # Look for ## Acceptance & Quality Checklist
        checklist_line = None
        for idx in range(body_start, len(lines)):
            line = lines[idx]
            if re.match(r"^##\s+Acceptance\s+(?:&|and)\s+Quality\s+Checklist\b", line, re.IGNORECASE):
                checklist_line = idx + 1
                break

        is_generated_queue = "marathon-plan.sh" in frontmatter.get("generated_by", "")
        has_marathon_meta = bool(
            frontmatter.get("marathon_gid") or
            frontmatter.get("doc_type") in ("marathon", "marathon-plan")
        )
        base_name = os.path.basename(file_path)
        is_marathon_filename = bool(re.match(r"^MARATHON-PLAN-[A-Za-z0-9._-]+\.md$", base_name, re.IGNORECASE))

        # Scan for declared waves outside the checklist section
        declared_waves = set()
        for idx, line in enumerate(lines):
            if checklist_line and idx >= (checklist_line - 1):
                if re.match(r"^##\s+", line) and not re.match(r"^###\s+", line):
                    pass
                else:
                    continue
            for m in re.finditer(r"(?:\*\*Wave\s+(\d+)[:\*]|^###?\s+Wave\s+(\d+)\b|^\s*-\s*\*{0,2}Wave\s+(\d+)[:\*])", line, re.IGNORECASE):
                wn = m.group(1) or m.group(2) or m.group(3)
                if wn:
                    declared_waves.add(int(wn))

        has_waves = bool(declared_waves) or bool(
            re.search(r"\bwaves?:", "".join(lines), re.IGNORECASE) or
            re.search(r"\*\*Wave\s+\d+:\*\*", "".join(lines), re.IGNORECASE)
        )
        is_marathon_plan = has_marathon_meta or (is_marathon_filename and not is_generated_queue) or (explicit_target and has_waves)

        if not is_marathon_plan:
            if explicit_target:
                self.record("info", file_path, 1, "not a marathon plan doc (skipped)")
            return

        if not checklist_line:
            # If doc is an active or completed marathon plan with waves, missing checklist is an error/warn
            if has_waves or must_be_complete or has_marathon_meta:
                sev = "error" if must_be_complete else "warn"
                self.record(sev, file_path, 1,
                            "missing '## Acceptance & Quality Checklist' section",
                            "add-marathon-checklist")
            else:
                self.record("info", file_path, 1, "no '## Acceptance & Quality Checklist' section found (skipped)")
            return

        # Parse the checklist section
        current_wave = None
        wave_items = {}  # wave_num -> list of {line, checked, text, is_proof, is_codex, is_peer, receipt}

        for idx in range(checklist_line, len(lines)):
            line = lines[idx]
            line_no = idx + 1
            # Stop at the next ## heading
            if re.match(r"^##\s+", line) and not re.match(r"^###\s+", line):
                break

            wave_hdr_match = re.match(r"^###\s+Wave\s+(\d+)\b", line, re.IGNORECASE)
            if wave_hdr_match:
                current_wave = int(wave_hdr_match.group(1))
                if current_wave not in wave_items:
                    wave_items[current_wave] = []
                continue

            item_match = re.match(r"^\s*-\s*\[([ xX])\]\s*(.*)$", line)
            if item_match:
                checked = item_match.group(1).lower() == "x"
                text = item_match.group(2).strip()

                # Infer wave number from text if not under a ### Wave N header
                wave_num = current_wave
                inline_wave = re.search(r"\bWave\s+(\d+)\b", text, re.IGNORECASE)
                if inline_wave:
                    wave_num = int(inline_wave.group(1))

                if wave_num is None:
                    wave_num = 1

                if wave_num not in wave_items:
                    wave_items[wave_num] = []

                is_proof = bool(re.search(r"Proof of Done|Test Suite Green", text, re.IGNORECASE))
                is_codex = bool(re.search(r"Post-Build Codex QA|Codex QA Relay", text, re.IGNORECASE))
                is_peer = bool(re.search(r"CodeRabbit|Peer Review", text, re.IGNORECASE))

                receipt_match = re.search(r"[`'\"]?(relay-system/[^`'\"\s]+)[`'\"]?", text)
                receipt_path = receipt_match.group(1) if receipt_match else None

                wave_items[wave_num].append({
                    "line": line_no,
                    "checked": checked,
                    "text": text,
                    "is_proof": is_proof,
                    "is_codex": is_codex,
                    "is_peer": is_peer,
                    "receipt": receipt_path,
                })

        if not wave_items:
            sev = "error" if must_be_complete else "warn"
            self.record(sev, file_path, checklist_line,
                        "checklist section is empty (no wave checklist items found)",
                        "populate-marathon-checklist")
            return

        # Check for missing checklists for any declared wave (F1)
        for expected_wave in sorted(declared_waves):
            if expected_wave not in wave_items:
                self.record("error", file_path, checklist_line,
                            f"Wave {expected_wave} declared in plan but missing its '### Wave {expected_wave}' checklist section",
                            "add-wave-checklist")

        all_waves = sorted(set(list(wave_items.keys()) + list(declared_waves)))
        for wave_num in all_waves:
            if wave_num not in wave_items:
                continue
            items = wave_items[wave_num]
            has_proof = any(it["is_proof"] for it in items)
            has_codex = any(it["is_codex"] for it in items)
            has_peer = any(it["is_peer"] for it in items)

            first_line = items[0]["line"] if items else checklist_line

            if not has_proof:
                self.record("error", file_path, first_line,
                            f"Wave {wave_num} missing mandatory Proof of Done test suite checklist item",
                            "add-proof-of-done-check")
            if not has_codex:
                self.record("error", file_path, first_line,
                            f"Wave {wave_num} missing mandatory Post-Build Codex QA Relay checklist item",
                            "add-codex-qa-relay-check")
            if not has_peer:
                self.record("error", file_path, first_line,
                            f"Wave {wave_num} missing mandatory CodeRabbit / Peer Review adjudication checklist item",
                            "add-peer-review-check")

            for it in items:
                line_no = it["line"]
                # 1. Mandatory receipt check on Codex item (F2)
                if it["is_codex"] and not it["receipt"]:
                    if it["checked"] or must_be_complete:
                        self.record("error", file_path, line_no,
                                    f"Wave {wave_num} Post-Build Codex QA Relay item missing receipt citation (relay-system/...)",
                                    "cite-relay-system-receipt")
                    else:
                        self.record("warn", file_path, line_no,
                                    f"Wave {wave_num} Post-Build Codex QA Relay item has no receipt citation",
                                    "pending-receipt-citation")

                # 2. Transcript existence check
                if it["receipt"]:
                    full_receipt = os.path.join(self.root, it["receipt"])
                    # Check for placeholder strings like <date> or <label>
                    if "<" in it["receipt"] or ">" in it["receipt"]:
                        if it["checked"]:
                            self.record("error", file_path, line_no,
                                        f"Wave {wave_num} checked but transcript path contains unexpanded placeholder '{it['receipt']}'",
                                        "record-actual-transcript-path")
                        elif must_be_complete:
                            self.record("error", file_path, line_no,
                                        f"Wave {wave_num} has unexpanded placeholder transcript '{it['receipt']}' before PR/completion",
                                        "execute-codex-qa-relay")
                    elif not os.path.isfile(full_receipt):
                        if it["checked"]:
                            self.record("error", file_path, line_no,
                                        f"Wave {wave_num} checked but transcript '{it['receipt']}' does not exist on disk",
                                        "commit-missing-relay-transcript")
                        elif must_be_complete:
                            self.record("error", file_path, line_no,
                                        f"Wave {wave_num} transcript '{it['receipt']}' missing on disk before PR/completion",
                                        "execute-codex-qa-relay")

                # 3. Checkbox verification check
                if not it["checked"]:
                    if must_be_complete:
                        self.record("error", file_path, line_no,
                                    f"Wave {wave_num} unverified item: '{it['text']}' — cannot open PR or complete marathon without verified wave QA",
                                    "verify-and-check-item")
                    else:
                        self.record("warn", file_path, line_no,
                                    f"Wave {wave_num} item pending verification: '{it['text']}'",
                                    "pending-wave-qa")

    def run(self, doc_paths=None):
        explicit = bool(doc_paths)
        if doc_paths:
            targets = [os.path.abspath(p) for p in doc_paths]
        else:
            targets = []
            working_dir = os.path.join(self.root, "PROJECT", "2-WORKING")
            completed_dir = os.path.join(self.root, "PROJECT", "3-COMPLETED")
            for d in (working_dir, completed_dir):
                if os.path.isdir(d):
                    for root_dir, _, files in os.walk(d):
                        for f in files:
                            if f.endswith(".md") and f != "blank.md":
                                full = os.path.join(root_dir, f)
                                targets.append(full)
            targets = sorted(list(set(targets)))

        for t in targets:
            self.parse_doc(t, explicit_target=explicit)

        if self.format not in ("json", "tsv"):
            sys.stdout.write(f"SUMMARY [pdda-check-marathon-qa] errors={self.errors} warns={self.warns} info={self.info}\n")

        if self.errors > 0:
            if self.mode == "full" or self.strict or self.pre_pr:
                return 1
        return 0


def main():
    parser = argparse.ArgumentParser(description="Mechanical marathon Wave QA receipt & checklist gate (GH-784)")
    parser.add_argument("--root", default="", help="Repository root")
    parser.add_argument("--doc", action="append", default=[], help="Specific doc path to check")
    parser.add_argument("--pre-pr", action="store_true", help="Assert that all waves are verified before PR opening")
    parser.add_argument("--strict", action="store_true", help="Exit non-zero on any error regardless of mode")
    parser.add_argument("--mode", default=os.environ.get("PDDA_MODE", "observe"),
                        choices=["observe", "light", "full"], help="Enforcement mode")
    parser.add_argument("--format", default=os.environ.get("PDDA_FORMAT", "text"),
                        choices=["text", "json", "tsv"], help="Output format")
    parser.add_argument("docs", nargs="*", help="Optional document paths to check")

    args = parser.parse_args()
    root = args.root or find_repo_root()
    all_docs = args.doc + args.docs

    checker = MarathonQAChecker(root=root, mode=args.mode, fmt=args.format, pre_pr=args.pre_pr, strict=args.strict)
    rc = checker.run(all_docs)
    sys.exit(rc)


if __name__ == "__main__":
    main()
