#!/usr/bin/env python3
"""wave_reconcile.py (GH-165) — Post-Merge Wave & Marathon Lifecycle Reconciler.

The canonical, single-command Python reconciler to automate post-merge lifecycle
transitions across Active Docs (PROJECT/2-WORKING/ -> 3-COMPLETED/ or 4-MISC/),
ROADMAP.md, releases.db SQLite ledger, generated dashboards, and next-wave marathon planning.
"""

import argparse
import fcntl
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path


class ReconcileError(Exception):
    """Custom exception class ensuring proper rollback catching."""

    def __init__(self, message, code=2):
        super().__init__(message)
        self.code = code


def log(msg):
    print(f"wave-reconcile: {msg}", flush=True)


def log_err(msg):
    print(f"wave-reconcile: ERROR — {msg}", file=sys.stderr, flush=True)


def die(msg, code=2):
    log_err(msg)
    raise ReconcileError(msg, code=code)


class ReconcilerLock:
    """Lock manager preventing concurrent reconciliation runs."""

    def __init__(self, lock_path):
        self.lock_path = lock_path
        self.fd = None

    def __enter__(self):
        try:
            self.fd = open(self.lock_path, "w")
            fcntl.flock(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.fd.write(f"pid={os.getpid()}\ntime={datetime.now().isoformat()}\n")
            self.fd.flush()
            return self
        except (BlockingIOError, OSError) as e:
            die(f"Could not acquire reconciler lock at {self.lock_path}: {e}", code=8)

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.fd:
            try:
                fcntl.flock(self.fd, fcntl.LOCK_UN)
                self.fd.close()
                if os.path.exists(self.lock_path):
                    os.unlink(self.lock_path)
            except OSError:
                pass


class RollbackJournal:
    """Snapshots pre-mutation file states and rolls back on failure."""

    def __init__(self):
        self.backups = {}  # original_path -> backup_temp_path
        self.created_files = set()
        self.deleted_files = set()

    def snapshot(self, path):
        p = os.path.abspath(path)
        if p not in self.backups and os.path.exists(p):
            tmp = tempfile.NamedTemporaryFile(delete=False)
            tmp.close()
            shutil.copy2(p, tmp.name)
            self.backups[p] = tmp.name

    def track_created(self, path):
        self.created_files.add(os.path.abspath(path))

    def rollback(self):
        log("Rolling back all uncommitted mutations...")
        for created in self.created_files:
            if os.path.exists(created):
                try:
                    os.unlink(created)
                except OSError:
                    pass
        for orig, backup in self.backups.items():
            try:
                os.makedirs(os.path.dirname(orig), exist_ok=True)
                shutil.copy2(backup, orig)
            except OSError as e:
                log_err(f"Failed restoring {orig} from {backup}: {e}")
        self.cleanup()

    def cleanup(self):
        for backup in self.backups.values():
            if os.path.exists(backup):
                try:
                    os.unlink(backup)
                except OSError:
                    pass
        self.backups.clear()
        self.created_files.clear()


def resolve_repo_root():
    """Find repository root containing .git."""
    cur = os.path.abspath(os.getcwd())
    while cur != os.path.dirname(cur):
        if os.path.isdir(os.path.join(cur, ".git")) or os.path.isfile(os.path.join(cur, ".git")):
            return cur
        cur = os.path.dirname(cur)
    return os.path.abspath(os.getcwd())


def check_porcelain_cleanliness(repo_root, allow_dirty=False):
    """Assert clean git working tree before mutation."""
    cmd = ["git", "-C", repo_root, "status", "--porcelain"]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        die(f"git status failed: {r.stderr}")
    dirt = r.stdout.strip()
    if dirt and not allow_dirty:
        die(
            f"Working tree is dirty. Must be completely clean to reconcile:\n{dirt}",
            code=3,
        )
    return dirt


def verify_rollback_completeness(repo_root, baseline):
    """GH-271: a rollback must restore the pre-run tree, not merely claim to.

    The 2026-08-23 failure left regenerated dashboards and a stray MARATHON-PLAN-<date>.md
    behind after "Rolling back all uncommitted mutations..." reported success. Compare
    porcelain against the pre-run baseline (fixtures may legitimately start dirty under
    --allow-dirty) and name every leftover — an incomplete rollback must be visible, never
    a silent success.
    """
    if baseline is None:
        return
    cmd = ["git", "-C", repo_root, "status", "--porcelain"]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        return
    current = r.stdout.strip()
    if current != baseline:
        base_lines = set(baseline.splitlines())
        log_err("Rollback INCOMPLETE — working tree differs from the pre-run state. Leftovers:")
        for line in current.splitlines():
            if line not in base_lines:
                log_err(f"  {line}")


def check_current_branch(repo_root, expected_branch="development", skip_branch_check=False):
    """Verify active branch matches target branch."""
    if skip_branch_check:
        return
    cmd = ["git", "-C", repo_root, "branch", "--show-current"]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    current = r.stdout.strip()
    if current != expected_branch:
        die(
            f"Active branch is '{current}', but post-merge reconciliation requires '{expected_branch}'.",
            code=3,
        )


def pull_upstream(repo_root, branch="development"):
    """Fast-forward pull from origin."""
    cmd = ["git", "-C", repo_root, "pull", "--ff-only", "origin", branch]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        die(f"git pull --ff-only failed: {r.stderr}")


def fetch_issue_state(repo_root, issue_num, offline_manifest=None):
    """Linked issue state, or None when unknowable (GH-202).

    None means PROMOTE as before — backward-compatible for offline manifests that
    carry no issue list; only a positively-OPEN issue suppresses promotion.
    Offline manifests may declare {"issues": [{"number": N, "state": "OPEN"}]}.
    """
    if offline_manifest:
        for entry in offline_manifest.get("issues", []):
            if str(entry.get("number")) == str(issue_num):
                return str(entry.get("state", "")).upper()
        return None  # legacy manifest without an issues key: unknown, promote as before
    # LIVE reconcile: a failed gh is a failed fact-check, not an unknown state. A transient
    # error (network, rate limit) must NOT silently fall back to promotion (GH-202 review,
    # Agy round 1 blocker) — that would mis-promote every open issue on a bad network day.
    try:
        r = subprocess.run(
            ["gh", "issue", "view", str(issue_num), "--json", "state"],
            cwd=repo_root, capture_output=True, text=True, check=False,
        )
    except OSError as exc:
        die(f"gh issue view #{issue_num} could not run ({exc}); refusing to guess issue state — "
            f"fix gh access or pass --offline with an issues[] manifest", code=6)
    if r.returncode != 0:
        die(f"gh issue view #{issue_num} failed (exit {r.returncode}): {r.stderr.strip()}; "
            f"refusing to guess issue state — fix gh access or pass --offline with an issues[] manifest", code=6)
    try:
        import json as _json
        return str(_json.loads(r.stdout).get("state", "")).upper()
    except ValueError:
        die(f"gh issue view #{issue_num} returned unparseable output; refusing to guess issue state", code=6)


def record_merge_evidence(doc_path, pr_meta, dry_run=False, journal=None):
    """Open-issue docs stay in 2-WORKING; record the merged-PR evidence in place (GH-202)."""
    pr_id = pr_meta.get("number", "?")
    merged_at = (pr_meta.get("mergedAt") or "")[:10]
    note = "\n## Merge evidence\n\n- PR #" + str(pr_id) + " merged " + (merged_at or "(date unknown)") + " — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).\n"
    with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    if ("\n- PR #" + str(pr_id) + " merged ") in content or content.startswith("- PR #" + str(pr_id) + " merged "):
        return  # idempotent
    if not dry_run:
        if journal is not None:
            journal.snapshot(doc_path)
        with open(doc_path, "a", encoding="utf-8") as f:
            f.write(note)


def fetch_pr_metadata(repo_root, pr_id, offline_manifest=None, dry_run=False):
    """Fetch merged PR metadata from GitHub or offline manifest."""
    if offline_manifest:
        for entry in offline_manifest.get("prs", []):
            if str(entry.get("number")) == str(pr_id):
                return entry
        die(f"PR #{pr_id} not found in offline manifest", code=4)

    if dry_run:
        # In dry run without offline manifest, try gh if available or return stub preview
        pass

    cmd = [
        "gh",
        "pr",
        "view",
        str(pr_id),
        "--json",
        "number,title,state,mergedAt,baseRefName,headRefName,body,url",
    ]
    r = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        if dry_run:
            log(f"dry-run: gh pr view unavailable ({r.stderr.strip()}); using synthetic preview metadata for PR #{pr_id}")
            return {
                "number": int(pr_id),
                "title": f"Preview PR #{pr_id}",
                "state": "MERGED",
                "mergedAt": datetime.now().isoformat() + "Z",
                "baseRefName": "development",
                "body": f"Closes #{pr_id}",
            }
        die(f"gh pr view {pr_id} failed: {r.stderr}", code=4)
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError as e:
        die(f"Failed parsing gh pr view JSON for PR #{pr_id}: {e}", code=4)


def check_provenance_receipts(repo_root, pr_meta):
    """Check committed provenance receipts for marathon gate (GH-430)."""
    pr_num = pr_meta.get("number")
    results_dir = os.path.join(repo_root, "TESTS-RESULTS")
    if not os.path.isdir(results_dir):
        die(f"--gate failure: TESTS-RESULTS directory missing; cannot verify provenance for PR #{pr_num}", code=6)
    # Search for committed receipts matching PR or recent date
    found = False
    for root, _, files in os.walk(results_dir):
        for f in files:
            if f in ("error_log.jsonl", "provenance.jsonl"):
                found = True
                break
        if found:
            break
    if not found:
        die(f"--gate failure: No committed provenance.jsonl or error_log.jsonl found in TESTS-RESULTS/ for PR #{pr_num}", code=6)
    log(f"  Provenance receipts verified for PR #{pr_num} (GH-430 compliant)")


# GH-271: closing-keyword clause + trailing title tag decide LINKAGE (what a merged PR may
# complete); bare mentions are references only. The #-or-GH- prefix is mandatory in both —
# "closes 5 issues" must not extract issue 5 — and keywords must sit on the same line as the
# ref, so a title ending in "fixed" cannot capture a body that opens with "#123".
CLOSING_KEYWORD_CLAUSE = re.compile(
    r"\b(?:closes?|closed|fix(?:es|ed)?|resolves?|resolved)[ \t]*:?[ \t]+"
    r"((?:#|GH-)[0-9]{1,6}\b(?:[ \t]*,[ \t]*(?:and[ \t]+)?(?:#|GH-)[0-9]{1,6}\b)*)",
    re.IGNORECASE,
)
REF_IN_CLAUSE = re.compile(r"(?:#|GH-)([0-9]{1,6})\b", re.IGNORECASE)
MENTION = re.compile(r"(?:\b[Gg][Hh]-|#)([0-9]{1,6})\b")
TITLE_TRAILER = re.compile(
    r"\([ \t]*((?:(?:#|GH-)[0-9]{1,6}\b[ \t]*(?:[,;][ \t]*)?)+)[ \t]*\)[ \t]*$",
    re.IGNORECASE,
)
CODE_FENCE = re.compile(r"```.*?```", re.DOTALL)
INLINE_CODE = re.compile(r"`[^`\n]*`")


def _strip_code_blocks(text):
    """GitHub ignores closing keywords inside code; so does the reconciler."""
    return INLINE_CODE.sub(" ", CODE_FENCE.sub(" ", text))


def extract_linked_issues(pr_meta):
    """Split a PR's issue references into (closers, mentions) — GH-271.

    closers: refs introduced by a GitHub closing keyword (close/closes/closed/fix/fixes/
    fixed/resolve/resolves/resolved) before a #- or GH--prefixed number, comma lists
    included, plus a trailing "(#N)"/"(GH-N)" title tag. These mirror GitHub's own linking
    rules — extended to the repo's GH-N spelling, since PRs merge into `development` and
    the reconciler parses text rather than relying on default-branch auto-close — and are
    eligible for every reconciler action (promotion when the issue is closed, evidence +
    stays-active when open).

    mentions: bare GH-N/#N references in prose. The old extractor treated every mention as
    a link (PR #185's body yielded ten "linked" issues, two of them live active lanes), so
    a mention now only ever records merge evidence on an OPEN issue's active doc — never a
    promotion, ROADMAP move, or doc relocation.

    Both lists are deduplicated and sorted.
    """
    title = (pr_meta.get("title") or "").strip()
    body = _strip_code_blocks(pr_meta.get("body") or "")
    closers, mentions = set(), set()

    scan_text = title + "\n" + body
    for m in CLOSING_KEYWORD_CLAUSE.finditer(scan_text):
        closers.update(int(n) for n in REF_IN_CLAUSE.findall(m.group(1)))
    trailer = TITLE_TRAILER.search(title)
    if trailer:
        closers.update(int(n) for n in REF_IN_CLAUSE.findall(trailer.group(1)))

    mentions.update(int(n) for n in MENTION.findall(scan_text))
    mentions -= closers
    return sorted(closers), sorted(mentions)


def find_active_doc_for_issue(repo_root, issue_num):
    """Find matching active doc in PROJECT/2-WORKING/."""
    working_dir = os.path.join(repo_root, "PROJECT", "2-WORKING")
    if not os.path.isdir(working_dir):
        return None
    for fname in os.listdir(working_dir):
        if not fname.endswith(".md"):
            continue
        # Match GH-123-*.md or 123-*.md
        if re.search(rf"(?:^|[^\d])(GH-)?{issue_num}(?:[^\d]|$)", fname, re.IGNORECASE):
            return os.path.join(working_dir, fname)
    return None


def parse_doc_frontmatter(doc_path):
    """Parse key-value pairs from document YAML frontmatter."""
    if not doc_path or not os.path.isfile(doc_path):
        return {}
    try:
        with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
        if not lines or lines[0].strip() != "---":
            return {}
        fm = {}
        for line in lines[1:]:
            if line.strip() == "---":
                break
            if ":" in line:
                k, v = line.split(":", 1)
                fm[k.strip().lower()] = v.strip().strip("'\"").lower()
        return fm
    except Exception:
        return {}


def validate_and_update_doc(doc_path, pr_meta, is_merged=True, dry_run=False, journal=None):
    """Assert ## Lessons Learned, update frontmatter, and compute destination path."""
    with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    merged_at = pr_meta.get("mergedAt")
    if merged_at:
        try:
            ship_date = datetime.fromisoformat(merged_at.replace("Z", "+00:00")).strftime(
                "%Y-%m-%d"
            )
        except Exception:
            ship_date = datetime.now().strftime("%Y-%m-%d")
    else:
        ship_date = datetime.now().strftime("%Y-%m-%d")

    if is_merged:
        # Assert lessons learned section exists for merged docs
        if not re.search(r"##\s+Lessons\s+Learned", content, re.IGNORECASE):
            die(
                f"Doc {os.path.basename(doc_path)} is missing mandatory '## Lessons Learned (For Future Agents)' section.",
                code=5,
            )

        new_status = "Complete"
        dest_folder = "3-COMPLETED"
    else:
        # Unmerged / declined / closed without merge -> route to 4-MISC
        new_status = "Declined"
        dest_folder = "4-MISC"

    # Update frontmatter status and updated date
    new_content = re.sub(
        r"^status:\s*.*$", f"status: {new_status}", content, flags=re.MULTILINE | re.IGNORECASE
    )
    new_content = re.sub(
        r"^updated:\s*.*$", f"updated: {ship_date}", new_content, flags=re.MULTILINE | re.IGNORECASE
    )

    dest_dir = os.path.join(os.path.dirname(os.path.dirname(doc_path)), dest_folder)
    dest_path = os.path.join(dest_dir, os.path.basename(doc_path))

    if not dry_run:
        if journal:
            journal.snapshot(doc_path)
            # GH-271: a destination that already exists (an earlier reconciliation promoted
            # this doc and was committed) is an overwrite, not a creation — snapshot it too,
            # or rollback's unlink leaves a tracked path deleted in porcelain.
            if os.path.exists(dest_path):
                journal.snapshot(dest_path)
            journal.track_created(dest_path)
        os.makedirs(dest_dir, exist_ok=True)
        with open(dest_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        os.unlink(doc_path)

    return dest_path, ship_date


def update_roadmap_entry(repo_root, issue_num, pr_num, ship_date, is_merged=True, dry_run=False, journal=None):
    """Move multiline entry block in ROADMAP.md to Completed/Deferred section with shipping badge."""
    roadmap_path = os.path.join(repo_root, "ROADMAP.md")
    if not os.path.isfile(roadmap_path):
        log_err("ROADMAP.md not found; skipping roadmap update")
        return False

    with open(roadmap_path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    # Locate every matching entry block. Older reconciler runs could leave the same
    # issue in both an active and terminal section (#163); selecting only the first
    # match and then inserting it again preserves that duplicate forever.
    entry_pattern = re.compile(rf"^-\s+\*\*GH-{issue_num}\b")
    starts = [i for i, line in enumerate(lines) if entry_pattern.search(line)]
    if not starts:
        log(f"No entry found in ROADMAP.md for GH-{issue_num} (skipping roadmap move)")
        return False

    blocks = []
    for start_idx in starts:
        end_idx = len(lines)
        for j in range(start_idx + 1, len(lines)):
            if lines[j].startswith("- **") or lines[j].startswith("### ") or lines[j].startswith("## "):
                end_idx = j
                break
        blocks.append((start_idx, end_idx, lines[start_idx:end_idx]))

    expected_marker = "SHIPPED" if is_merged else "DECLINED"
    canonical = next(
        (block for _, _, block in blocks if expected_marker in block[0]),
        blocks[0][2],
    )
    block_lines = list(canonical)
    first_line = block_lines[0]

    # A single canonical terminal entry is a true no-op on a second run.
    if len(blocks) == 1 and expected_marker in first_line:
        log(f"GH-{issue_num} is already marked {expected_marker} in ROADMAP.md")
        return True

    target_section = "### Completed" if is_merged else "### Deferred / cancelled"
    badge_sub = f"✅ **SHIPPED {ship_date} (PR #{pr_num})**" if is_merged else f"🛑 **DECLINED {ship_date} (PR #{pr_num})**"

    if expected_marker not in first_line and "—" in first_line:
        prefix, rest = first_line.split("—", 1)
        title_part = prefix.split("**")[1] if "**" in prefix else f"GH-{issue_num}"
        new_first_line = f"- **{title_part}** {badge_sub} —{rest}"
    elif expected_marker not in first_line:
        new_first_line = re.sub(
            r"(\*\*[^*]+\*\*)\s+(?:[^\—]+)\s+—", rf"\1 {badge_sub} —", first_line
        )
    else:
        new_first_line = first_line

    block_lines[0] = new_first_line

    # Remove every old occurrence, then insert exactly one canonical block. This
    # is a move, never an add, and repairs the historical double-listing shape.
    removed = set()
    for start_idx, end_idx, _ in blocks:
        removed.update(range(start_idx, end_idx))
    new_lines = [line for idx, line in enumerate(lines) if idx not in removed]

    # Locate target section header
    target_idx = None
    for k, line in enumerate(new_lines):
        if line.strip() == target_section:
            target_idx = k
            break

    if target_idx is None and not is_merged:
        # Fallback to ### Completed if ### Deferred is absent
        target_section = "### Completed"
        for k, line in enumerate(new_lines):
            if line.strip() == target_section:
                target_idx = k
                break

    if target_idx is None:
        die(f"Could not find '{target_section}' section in ROADMAP.md", code=5)

    # Insert block right under section header
    insert_pos = target_idx + 1
    new_lines = new_lines[:insert_pos] + block_lines + new_lines[insert_pos:]

    if not dry_run:
        if journal:
            journal.snapshot(roadmap_path)
        with open(roadmap_path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)

    return True


def marathon_plan_findings(output, returncode):
    """Return exit-driving structured findings emitted by marathon-plan."""
    drift_types = {"already-landed", "already-closed"}
    held_types = {
        "unrated", "needs-doc", "needs-contract", "note-only",
        "not-ready", "blocked", "blocked-dep",
    }
    relevant_types = drift_types if returncode == 4 else held_types
    findings = []
    for line in output.splitlines():
        try:
            finding = json.loads(line)
        except (json.JSONDecodeError, TypeError):
            continue
        check = str(finding.get("check", ""))
        finding_type = check.split("/", 1)[1] if "/" in check else check
        if finding_type in relevant_types:
            findings.append(finding)
    return findings


def finding_issue_numbers(finding):
    """Extract issue identities from a planner finding without guessing by title."""
    file_name = str(finding.get("file", ""))
    evidence = " ".join(str(finding.get(key, "")) for key in ("file", "message", "action"))
    numbers = {
        int(number)
        for number in re.findall(r"(?:GH-|issue\s+#|#)([0-9]{1,6})\b", evidence, re.IGNORECASE)
    }
    # Active-doc lookup also supports the legacy `123-title.md` filename shape.
    legacy_doc = re.match(r"^(?:GH-)?([0-9]{1,6})(?:[^0-9]|$)", os.path.basename(file_name), re.IGNORECASE)
    if legacy_doc:
        numbers.add(int(legacy_doc.group(1)))
    return numbers


def describe_finding(finding):
    """Produce a stable, operator-readable held-item label."""
    issue_nums = sorted(finding_issue_numbers(finding))
    file_name = str(finding.get("file", "")).strip()
    identity = ", ".join(f"GH-{number}" for number in issue_nums)
    if identity and file_name:
        return f"{identity} ({file_name})"
    if identity:
        return identity
    if file_name:
        return file_name
    return str(finding.get("message", "")).strip() or "unidentified planner item"


def handle_marathon_plan_result(result, reconciled_issues):
    """Scope planner drift/held failures to the issues reconciled in this run."""
    if result.returncode == 0:
        return
    if result.returncode not in (4, 5):
        die(
            f"Subprocess 'marathon-plan.sh' failed with exit {result.returncode}:\n"
            f"{result.stderr}\n{result.stdout}",
            code=6,
        )

    findings = marathon_plan_findings(result.stdout, result.returncode)
    if not findings:
        # Preserve GH-202 compatibility with older/stub planners that expose only
        # the exit-5 contract. Exit 4 must remain attributable and therefore
        # fails closed when structured evidence is absent.
        if result.returncode == 5:
            log("  marathon-plan reports items held (exit 5) without structured findings — continuing (GH-202 compatibility)")
            return
        die("marathon-plan reported drift (exit 4) without attributable structured findings", code=6)

    reconciled = {int(issue) for issue in reconciled_issues}
    owned = [
        finding for finding in findings
        if finding_issue_numbers(finding) & reconciled
    ]
    unrelated = [finding for finding in findings if finding not in owned]

    if owned:
        labels = ", ".join(describe_finding(finding) for finding in owned)
        die(
            "marathon-plan found drift/held state attributable to the reconciled "
            f"PR item(s): {labels}",
            code=6,
        )

    log("  WARNING — marathon-plan found pre-existing unrelated drift/held items; keeping reconciliation:")
    for finding in unrelated:
        log(f"    - {describe_finding(finding)}")


def run_subprocesses(repo_root, dry_run=False, journal=None, reconciled_issues=None):
    """Orchestrate releases sync, view exports, and marathon replanning with DB rollback protection."""
    log("Running downstream database sync and dashboard regeneration...")

    # Snapshot DB files in journal for transactional integrity
    db_file = os.path.join(repo_root, "releases.db")
    sql_file = os.path.join(repo_root, "releases.sql")
    pre_views = set()
    if not dry_run and journal:
        journal.snapshot(db_file)
        journal.snapshot(sql_file)
        # GH-271: the regen steps below also rewrite the baked views and marathon-plan drops
        # a dated plan doc — none of which the journal previously knew about, which is how a
        # failed run's rollback left regenerated dashboards and a stray MARATHON-PLAN behind
        # while reporting success (2026-08-23). Snapshot existing views (new ones are tracked
        # as created post-run); plan docs are always new files, so a before/after glob covers
        # them.
        for view in (
            "ROADMAP-DASHBOARD.md",
            "RELEASES-PREVIEW.html",
            "LEADERBOARD.html",
            "LEADERBOARD.md",
        ):
            view_path = os.path.join(repo_root, view)
            if os.path.exists(view_path):
                journal.snapshot(view_path)
                pre_views.add(view_path)

    def _plan_docs():
        found = set()
        for pattern in ("MARATHON-PLAN-*.md", os.path.join("PROJECT", "2-WORKING", "MARATHON-PLAN-*.md")):
            found.update(glob.glob(os.path.join(repo_root, pattern)))
        return found

    pre_plan_docs = _plan_docs() if not dry_run else set()

    sync_cmd = ["python3", "utils/py/releases_app.py", "roadmap", "sync"]
    check_cmd = ["python3", "utils/py/releases_app.py", "check"]
    timeline_cmd = ["python3", "utils/timeline/export_timeline.py", "--preview"]
    dash_cmd = ["bash", "utils/roadmap-dashboard.sh"]
    plan_cmd = ["bash", "utils/marathon-plan.sh", "--format", "json"]

    if dry_run:
        sync_cmd.append("--dry-run")
        plan_cmd.append("--dry-run")

    steps = [
        ("releases roadmap sync", sync_cmd),
        ("releases check", check_cmd),
    ]
    if not dry_run:
        steps.extend(
            [
                ("export_timeline.py --preview", timeline_cmd),
                ("roadmap-dashboard.sh", dash_cmd),
                ("marathon-plan.sh", plan_cmd),
            ]
        )
    else:
        steps.append(("marathon-plan.sh --dry-run", plan_cmd))

    # GH-271: registration of created views/plan docs must happen even when a step DIES —
    # the marathon-plan failure path raises from inside the loop, and a post-loop pass
    # would never run, which is exactly how the stray MARATHON-PLAN escaped rollback.
    try:
        for name, cmd in steps:
            log(f"  -> {name}")
            r = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False)
            if name.startswith("marathon-plan"):
                handle_marathon_plan_result(r, reconciled_issues or set())
            elif r.returncode != 0:
                die(f"Subprocess '{name}' failed with exit {r.returncode}:\n{r.stderr}\n{r.stdout}", code=6)
    finally:
        if journal and not dry_run:
            for view in (
                "ROADMAP-DASHBOARD.md",
                "RELEASES-PREVIEW.html",
                "LEADERBOARD.html",
                "LEADERBOARD.md",
            ):
                view_path = os.path.join(repo_root, view)
                if os.path.exists(view_path) and view_path not in pre_views:
                    journal.track_created(view_path)
            for plan_doc in _plan_docs() - pre_plan_docs:
                journal.track_created(plan_doc)


def run_validation_gate(repo_root):
    """Run pdda doc-health verification gate."""
    log("Running PDDA doc-hygiene gate...")
    gate_cmd = ["bash", "utils/pdda-local-checks.sh"] if os.path.exists(os.path.join(repo_root, "utils", "pdda-local-checks.sh")) else ["bash", "utils/pdda/pdda.sh"]
    r = subprocess.run(
        gate_cmd,
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    # Check for error lines
    if r.returncode != 0 or "ERROR" in r.stdout:
        die(f"PDDA validation gate failed:\n{r.stdout}", code=7)


def main():
    parser = argparse.ArgumentParser(
        description="wave_reconcile.py — Canonical Post-Merge Wave & Marathon Lifecycle Reconciler"
    )
    parser.add_argument(
        "--root",
        help="Target repository root path (default: current working directory)",
    )
    parser.add_argument(
        "--pr",
        nargs="+",
        help="One or more merged PR numbers/IDs to reconcile",
    )
    parser.add_argument(
        "--marathon",
        help="Marathon identifier / milestone name",
    )
    parser.add_argument(
        "--manifest",
        help="Path to structured JSON reconciliation manifest",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Hermetic preview: assert zero file/DB/ref mutations",
    )
    parser.add_argument(
        "--offline",
        help="Run without network using offline JSON manifest cache",
    )
    parser.add_argument(
        "--skip-pull",
        action="store_true",
        help="Skip git pull --ff-only origin development (for testing/isolated clones)",
    )
    parser.add_argument(
        "--skip-branch-check",
        action="store_true",
        help="Skip active branch check (for tests on feature branches)",
    )
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Allow dirty working tree (for test fixtures only)",
    )
    parser.add_argument(
        "--force-promote",
        action="store_true",
        help="Force promotion of active docs and roadmap entries to Completed regardless of linked issue OPEN state",
    )
    parser.add_argument(
        "--gate",
        "--require-receipts",
        action="store_true",
        dest="require_receipts",
        help="Enforce provenance receipts on merged PRs before marathon closeout (GH-430)",
    )

    args = parser.parse_args()

    repo_root = os.path.abspath(args.root) if args.root else resolve_repo_root()
    lock_file = os.path.join(repo_root, ".git", "wave-reconcile.lock")
    journal = RollbackJournal()
    baseline = None

    try:
        # Preflight phase
        log(f"Starting wave reconciliation (dry_run={args.dry_run}, root={repo_root})")
        baseline = check_porcelain_cleanliness(repo_root, allow_dirty=(args.allow_dirty or args.dry_run))
        check_current_branch(repo_root, skip_branch_check=args.skip_branch_check)

        if not args.skip_pull and not args.dry_run and not args.offline:
            pull_upstream(repo_root)

        offline_manifest = None
        if args.offline:
            try:
                with open(args.offline, "r", encoding="utf-8") as f:
                    offline_manifest = json.load(f)
            except Exception as e:
                die(f"Failed loading offline manifest from {args.offline}: {e}", code=4)

        pr_list = args.pr or []
        if args.manifest:
            try:
                with open(args.manifest, "r", encoding="utf-8") as f:
                    mdata = json.load(f)
                    pr_list.extend([str(p) for p in mdata.get("prs", [])])
            except Exception as e:
                die(f"Failed loading manifest from {args.manifest}: {e}", code=4)

        if not pr_list and not args.marathon:
            die("No PRs or marathon specified. Pass --pr <N>... or --marathon <name>", code=2)

        with ReconcilerLock(lock_file):
            reconciled_issues = set()
            for pr_id in pr_list:
                log(f"Processing PR #{pr_id}...")
                pr_meta = fetch_pr_metadata(repo_root, pr_id, offline_manifest, dry_run=args.dry_run)
                state = pr_meta.get("state", "").upper()
                is_merged = (state == "MERGED")

                if not is_merged:
                    log(f"  PR #{pr_id} state is '{state}' (unmerged/declined) -> routing to 4-MISC/")

                base_ref = pr_meta.get("baseRefName", "")
                if base_ref and base_ref != "development":
                    die(
                        f"PR #{pr_id} target base is '{base_ref}', not 'development'.",
                        code=4,
                    )

                if args.require_receipts:
                    check_provenance_receipts(repo_root, pr_meta)

                linked_issues, mentioned_issues = extract_linked_issues(pr_meta)
                reconciled_issues.update(linked_issues)
                log(f"  PR #{pr_id} closes {linked_issues}; references {mentioned_issues}")
                # GH-271: mentions never act on their own. --force-promote is the one
                # explicit operator override that widens the action set past closers.
                action_issues = (
                    sorted(set(linked_issues) | set(mentioned_issues))
                    if args.force_promote
                    else linked_issues
                )

                for issue_num in action_issues:
                    doc_path = find_active_doc_for_issue(repo_root, issue_num)
                    issue_state = fetch_issue_state(repo_root, issue_num, offline_manifest)
                    fm = parse_doc_frontmatter(doc_path) if doc_path else {}
                    is_multiphase = (
                        fm.get("umbrella") in ("true", "1", "yes")
                        or fm.get("multiphase") in ("true", "1", "yes")
                        or fm.get("multi_phase") in ("true", "1", "yes")
                    )

                    is_open = (issue_state == "OPEN") or (issue_state is None and is_multiphase)

                    if doc_path and is_open and is_merged and not args.force_promote:
                        # GH-202/GH-232: a merged PR does not complete an open issue or multi-phase umbrella.
                        # Phased umbrellas and open issues keep their active doc; evidence recorded in place.
                        log(f"  Issue #{issue_num} is OPEN — keeping {os.path.basename(doc_path)} active; recording merge evidence")
                        record_merge_evidence(doc_path, pr_meta, dry_run=args.dry_run, journal=journal)
                        log(f"  Issue #{issue_num} is OPEN — preserving active ROADMAP.md entry (skipping move to Completed)")
                    elif doc_path:
                        log(f"  Found active doc: {os.path.basename(doc_path)}")
                        dest_path, ship_date = validate_and_update_doc(
                            doc_path, pr_meta, is_merged=is_merged, dry_run=args.dry_run, journal=journal
                        )
                        log(f"  Moved -> {os.path.basename(dest_path)} (destination: {os.path.basename(os.path.dirname(dest_path))})")
                        updated = update_roadmap_entry(
                            repo_root,
                            issue_num,
                            pr_id,
                            ship_date,
                            is_merged=is_merged,
                            dry_run=args.dry_run,
                            journal=journal,
                        )
                        if updated:
                            log(f"  ROADMAP.md entry updated for GH-{issue_num}")
                    else:
                        log(f"  No active doc in 2-WORKING for GH-{issue_num}")
                        ship_date = datetime.now().strftime("%Y-%m-%d")
                        if not is_open or args.force_promote:
                            updated = update_roadmap_entry(
                                repo_root,
                                issue_num,
                                pr_id,
                                ship_date,
                                is_merged=is_merged,
                                dry_run=args.dry_run,
                                journal=journal,
                            )
                            if updated:
                                log(f"  ROADMAP.md entry updated for GH-{issue_num}")
                        else:
                            log(f"  Issue #{issue_num} is OPEN — preserving active ROADMAP.md entry (skipping move to Completed)")

                # GH-271: reference-only mentions never promote or move anything. When the
                # mentioned issue is OPEN (or an unknowable-state umbrella), record merge
                # evidence on its active doc — the "Advances GH-N (phase k of n)" convention
                # GH-202/GH-232 pin — and nothing else. Issues already handled above (the
                # force-promote widening) are skipped.
                for issue_num in mentioned_issues:
                    if issue_num in action_issues:
                        continue
                    doc_path = find_active_doc_for_issue(repo_root, issue_num)
                    if not doc_path:
                        continue
                    issue_state = fetch_issue_state(repo_root, issue_num, offline_manifest)
                    fm = parse_doc_frontmatter(doc_path)
                    is_multiphase = (
                        fm.get("umbrella") in ("true", "1", "yes")
                        or fm.get("multiphase") in ("true", "1", "yes")
                        or fm.get("multi_phase") in ("true", "1", "yes")
                    )
                    is_open = (issue_state == "OPEN") or (issue_state is None and is_multiphase)
                    if is_open and is_merged:
                        log(f"  Issue #{issue_num} referenced without a closing keyword and OPEN — recording merge evidence only")
                        record_merge_evidence(doc_path, pr_meta, dry_run=args.dry_run, journal=journal)

            # Subprocess orchestration
            run_subprocesses(
                repo_root,
                dry_run=args.dry_run,
                journal=journal,
                reconciled_issues=reconciled_issues,
            )

            # Final validation gate
            if not args.dry_run:
                run_validation_gate(repo_root)

            log("Wave reconciliation completed successfully! ✅")
            journal.cleanup()

    except ReconcileError as re_err:
        journal.rollback()
        verify_rollback_completeness(repo_root, baseline)
        sys.exit(re_err.code)
    except (Exception, SystemExit) as exc:
        journal.rollback()
        verify_rollback_completeness(repo_root, baseline)
        raise exc


if __name__ == "__main__":
    main()
