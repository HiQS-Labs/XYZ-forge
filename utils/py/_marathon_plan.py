#!/usr/bin/env python3
"""Native Python marathon-plan planner/rendering engine (GH-340).

This is a faithful, byte-compatible port of the canonical planner embedded in
``utils/marathon-plan.sh`` (the ``node - <<'NODE'`` program). It replaces the copied,
drifted ``utils/py/_marathon_plan_node.js`` on the Python (``XYZ_PYTHON=1``) path, so a
production Python marathon-plan run needs neither Node nor that JS file.

The two temporary Python parity shims that used to wrap the copied Node engine are folded
in here natively: ``doc_of()`` implements the correct own-``GH-<n>``-doc precedence (was the
``_normalize_roadmap`` input-mutation shim ``S``), and the "Review lanes" overlay is rendered
in place from ``parse_lanes_table()`` (was the ``_inject_review_lanes`` post-render shim ``N``).

Output is intentionally identical to the Bash engine on fixed fixtures. It is invoked by
``utils/py/marathon_plan.py``; the CLI wrapper, exit-code handling, ``--check``/``--dry-run``
modes, and hermetic test seams live there. ``utils/marathon-plan.sh`` (Bash) remains the
authoritative, dual-maintained twin per GH-308 — this port does not change that.

Stdlib only; no external dependency, no third renderer.
"""

import functools
import json
import math
import os
import re
import subprocess
import sys

# Ledger sections we sequence from vs. only reference.
SECTIONS = ["Queue / parked intake", "In progress", "Completed", "Deferred · vision"]
KNOWN_EMOJI = ["\U0001F7E2", "\U0001F7E1", "⏸️", "⛔", "✅",
               "\U0001F52E", "\U0001F532", "⚠️", "\U0001F195", "\U0001F41E", "\U0001F534"]

DEP_RESOLVED = frozenset(["completed-ref", "already-landed", "already-closed",
                          "deferred", "exempt", "note-only"])


class EngineExit(Exception):
    """Raised for the engine's hard-exit paths (unparseable ROADMAP / bad zones config)."""

    def __init__(self, code, message=None):
        super().__init__(message or "")
        self.code = code
        self.message = message


class ZoneConfigError(Exception):
    """Invalid zone configuration — surfaced to the caller as exit 3."""


# ── JS Number/String parity helpers ──────────────────────────────────────────
def _js_number(x):
    """Mirror JS ``Number(x)`` closely enough for zone penalties (returns float or nan)."""
    if x is None:
        return 0.0
    if isinstance(x, bool):
        return 1.0 if x else 0.0
    if isinstance(x, (int, float)):
        return float(x)
    try:
        s = str(x).strip()
        if s == "":
            return 0.0
        return float(s)
    except (ValueError, TypeError):
        return float("nan")


def _num_to_str(n):
    """Mirror JS ``String(number)``: integer-valued numbers print with no decimal point."""
    if isinstance(n, bool):
        return "true" if n else "false"
    if isinstance(n, int):
        return str(n)
    f = float(n)
    if math.isnan(f):
        return "NaN"
    if f == float("inf"):
        return "Infinity"
    if f == float("-inf"):
        return "-Infinity"
    if f == int(f) and abs(f) < 1e21:
        return str(int(f))
    return repr(f)


def _cell(v):
    if v is None:
        return "—"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return _num_to_str(v)
    return str(v)


def _rating_num(n):
    # Ratings are integers 1 (low) .. 5 (highest); render the number, or — when unrated.
    if n is not None and 1 <= n <= 5:
        return str(n)
    return "—"


def _L(x):
    """PDDA triage rating parse — parseInt-like; valid only 1..5, else None."""
    s = ("" if x is None else str(x)).strip()
    m = re.match(r"[+-]?\d+", s)
    if not m:
        return None
    n = int(m.group())
    return n if 1 <= n <= 5 else None


class Engine:
    def __init__(self, cfg):
        # cfg mirrors the QP_* env the Bash engine consumed.
        self.ROOT = cfg["root"]
        self.ROADMAP = cfg["roadmap"]
        self.QUEUE_DIR = cfg["queue_dir"]
        self.TODAY = cfg["today"]
        self.NOW = cfg["now"]
        self.POLICY = cfg["policy"]
        self.FORMAT = cfg["format"]
        self.DEEP = cfg["deep"]
        self.REQUIRE_GH = cfg["require_gh"]
        self.SWARM_PREFLIGHT = cfg.get("swarm_preflight", "")
        self.SP_CMD = cfg.get("sp_cmd") or "utils/swarm-preflight.sh"
        self.MD_CMD = cfg.get("md_cmd") or "relay-automation/marathon-drive.sh"
        self.MP_CMD = cfg.get("mp_cmd") or "utils/marathon-plan.sh"
        self.BASE_FILES_FILE = cfg.get("base_files_file", "")
        self.UTILS_DIR = cfg["utils_dir"]
        self.EXPLICIT_ZONES_CONFIG = cfg.get("zones_config", "")
        self.GH_STATE_FILE = cfg.get("gh_state_file", "")
        self.BRANCHES_FILE = cfg.get("branches_file", "")
        self.GH_FORCE = cfg.get("gh_force", "")
        self.ZONES_FILE_ENV = cfg.get("zones_file_env", "")  # QUEUE_PLAN_ZONES_FILE

        self.findings = []
        self._base_files = None
        self._branch_cache = None
        self.gh_unverified = 0

        self.ZONES = self._resolve_zone_config()
        self._resolve_gh()

    # ── tiny readers ──────────────────────────────────────────────────────────
    @staticmethod
    def _read_file_safe(p):
        try:
            with open(p, "r", encoding="utf-8") as f:
                return f.read()
        except OSError:
            return None

    def _exists_at(self, rel, base=None):
        try:
            return os.path.exists(os.path.normpath(os.path.join(base or self.ROOT, rel)))
        except (OSError, ValueError):
            return False

    def _read_json_or_throw(self, abs_path, label):
        raw = self._read_file_safe(abs_path)
        if raw is None:
            raise ZoneConfigError("%s: cannot read %s" % (label, abs_path))
        try:
            return json.loads(raw)
        except ValueError as e:
            raise ZoneConfigError("%s: invalid JSON in %s: %s" % (label, abs_path, e))

    # ── zone configuration ─────────────────────────────────────────────────────
    def _compile_zone_config(self, raw, source_path):
        if not isinstance(raw, dict):
            raise ZoneConfigError("zones config must be an object (%s)" % source_path)
        if not isinstance(raw.get("zones"), list):
            raise ZoneConfigError("zones config missing zones[] (%s)" % source_path)
        dz = raw.get("defaultZone")
        if (not isinstance(dz, dict) or not isinstance(dz.get("name"), str)
                or dz.get("name", "").strip() == ""):
            raise ZoneConfigError("zones config missing defaultZone.name (%s)" % source_path)

        def num_or(default, val):
            n = _js_number(val)
            if not math.isfinite(n):
                return default
            return int(n) if n == int(n) else n

        def int_or_none(val):
            return val if (isinstance(val, int) and not isinstance(val, bool)) else None

        names = set()
        zones = []
        for idx, zone in enumerate(raw["zones"]):
            if not isinstance(zone, dict):
                raise ZoneConfigError("zones[%d] must be an object (%s)" % (idx, source_path))
            name = zone.get("name")
            if not isinstance(name, str) or name.strip() == "":
                raise ZoneConfigError("zones[%d] missing name (%s)" % (idx, source_path))
            if name in names:
                raise ZoneConfigError("duplicate zone name '%s' (%s)" % (name, source_path))
            names.add(name)
            path_regex = None
            infer_regex = None
            if zone.get("pathRegex") is not None:
                try:
                    flags = re.IGNORECASE if zone.get("pathRegexCaseInsensitive") else 0
                    path_regex = re.compile(zone["pathRegex"], flags)
                except re.error as e:
                    raise ZoneConfigError("zones[%d] invalid pathRegex '%s' (%s): %s"
                                          % (idx, zone["pathRegex"], source_path, e))
            if zone.get("inferKeywordRegex") is not None:
                try:
                    infer_regex = re.compile(zone["inferKeywordRegex"])
                except re.error as e:
                    raise ZoneConfigError("zones[%d] invalid inferKeywordRegex '%s' (%s): %s"
                                          % (idx, zone["inferKeywordRegex"], source_path, e))
            zones.append({
                "name": name,
                "pathPrefixes": list(zone["pathPrefixes"]) if isinstance(zone.get("pathPrefixes"), list) else [],
                "pathRegex": path_regex,
                "inferKeywordRegex": infer_regex,
                "maxPerWave": int_or_none(zone.get("maxPerWave")),
                "penalty": num_or(0, zone.get("penalty")),
                "conservativeWhenInferred": zone.get("conservativeWhenInferred") is True,
                "escalateOrchestratorOnly": zone.get("escalateOrchestratorOnly") is True,
            })
        if dz["name"] in names:
            raise ZoneConfigError("defaultZone.name '%s' duplicates a named zone (%s)"
                                  % (dz["name"], source_path))
        return {
            "sourcePath": source_path,
            "zones": zones,
            "defaultZone": {
                "name": dz["name"],
                "penalty": num_or(0, dz.get("penalty")),
                "maxPerWave": int_or_none(dz.get("maxPerWave")),
                "conservativeWhenInferred": dz.get("conservativeWhenInferred") is True,
                "escalateOrchestratorOnly": dz.get("escalateOrchestratorOnly") is True,
                "pathPrefixes": [],
                "pathRegex": None,
                "inferKeywordRegex": None,
            },
        }

    def _resolve_zone_config(self):
        cwd = os.getcwd()
        if self.EXPLICIT_ZONES_CONFIG:
            explicit = os.path.normpath(os.path.join(cwd, self.EXPLICIT_ZONES_CONFIG))
            return self._compile_zone_config(self._read_json_or_throw(explicit, "--zones-config"), explicit)
        if self.ZONES_FILE_ENV:
            env_path = os.path.normpath(os.path.join(cwd, self.ZONES_FILE_ENV))
            return self._compile_zone_config(
                self._read_json_or_throw(env_path, "QUEUE_PLAN_ZONES_FILE"), env_path)
        root_local = os.path.join(self.ROOT, ".marathon-plan-zones.json")
        if os.path.exists(root_local):
            return self._compile_zone_config(self._read_json_or_throw(root_local, root_local), root_local)
        builtin = os.path.join(self.UTILS_DIR, "marathon-plan-zones.default.json")
        return self._compile_zone_config(self._read_json_or_throw(builtin, "built-in zones config"), builtin)

    def _zone_rank(self, name):
        for i, z in enumerate(self.ZONES["zones"]):
            if z["name"] == name:
                return i
        return len(self.ZONES["zones"])

    @staticmethod
    def _zone_matches_path(zone, artifact_path):
        for prefix in zone["pathPrefixes"]:
            if artifact_path == prefix or artifact_path.startswith(prefix):
                return True
        if zone["pathRegex"] and zone["pathRegex"].search(artifact_path):
            return True
        return False

    # ── net-new artifact detection ──────────────────────────────────────────────
    def _file_existed_at_base_ref(self, rel_path, ref):
        normalized = rel_path
        if normalized.startswith("./"):
            normalized = normalized[2:]
        if self.BASE_FILES_FILE:
            if self._base_files is None:
                raw = self._read_file_safe(self.BASE_FILES_FILE)
                if raw is None:
                    self._base_files = set()
                else:
                    self._base_files = set(
                        s.strip() for s in re.split(r"\r?\n", raw) if s.strip())
            return normalized in self._base_files
        try:
            subprocess.run(["git", "cat-file", "-e", "%s:%s" % (ref, normalized)],
                           cwd=self.ROOT, stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, check=True)
            return True
        except (subprocess.CalledProcessError, OSError):
            return False

    # ── doc parsing ─────────────────────────────────────────────────────────────
    def _frontmatter(self, doc):
        raw = self._read_file_safe(doc)
        if raw is None:
            return {}
        if raw.startswith("﻿"):  # strip a leading UTF-8 BOM if present
            raw = raw[1:]
        lines = re.split(r"\r?\n", raw)
        i = 0
        while i < len(lines) and lines[i].strip() == "":
            i += 1
        if i >= len(lines) or not re.match(r"^---\s*$", lines[i]):
            return {}
        fm = {}
        i += 1
        while i < len(lines):
            if re.match(r"^---\s*$", lines[i]):
                break
            m = re.match(r"^([A-Za-z0-9_]+):\s*(.*)$", lines[i])
            if m:
                fm[m.group(1)] = m.group(2).strip()
            i += 1
        return fm

    def _extract_contract(self, doc):
        raw = self._read_file_safe(doc)
        if raw is None:
            return None
        lines = re.split(r"\r?\n", raw)
        h = -1
        for j, l in enumerate(lines):
            if re.match(r"^#{1,6}\s+.*preflight\s+contract", l, re.I):
                h = j
                break
        if h < 0:
            return None
        start = -1
        for j in range(h + 1, len(lines)):
            if re.match(r"^```json\s*$", lines[j], re.I):
                start = j + 1
                break
            if re.match(r"^#{1,6}\s+", lines[j]):
                break
        if start < 0:
            return None
        end = -1
        for j in range(start, len(lines)):
            if re.match(r"^```\s*$", lines[j]):
                end = j
                break
        if end < 0:
            return None
        try:
            return json.loads("\n".join(lines[start:end]))
        except ValueError:
            return None

    def _eval_probe(self, p):
        def at(rel):
            return os.path.normpath(os.path.join(self.ROOT, rel or ""))
        try:
            t = p.get("type")
            if t == "path_absent":
                return "landed" if os.path.exists(at(p.get("path"))) else "unfixed"
            if t == "path_present":
                return "blocked" if not os.path.exists(at(p.get("path"))) else "unfixed"
            if t == "grep_present":
                if not os.path.exists(at(p.get("path"))):
                    return "blocked"
                content = self._read_file_safe(at(p.get("path"))) or ""
                return "unfixed" if re.search(p.get("pattern", ""), content) else "landed"
            if t == "grep_absent":
                if os.path.exists(at(p.get("path"))):
                    content = self._read_file_safe(at(p.get("path"))) or ""
                    if re.search(p.get("pattern", ""), content):
                        return "landed"
                return "unfixed"
            return "blocked"
        except (OSError, re.error):
            return "blocked"

    # ── git / gh, with a hermetic test seam ────────────────────────────────────
    def _branches(self):
        if self._branch_cache is not None:
            return self._branch_cache
        if self.BRANCHES_FILE:
            raw = self._read_file_safe(self.BRANCHES_FILE) or ""
            self._branch_cache = [s.strip() for s in re.split(r"\r?\n", raw) if s.strip()]
            return self._branch_cache
        try:
            out = subprocess.run(["git", "branch", "-a", "--format=%(refname:short)"],
                                 cwd=self.ROOT, stdout=subprocess.PIPE,
                                 stderr=subprocess.DEVNULL, check=True).stdout.decode("utf-8")
            self._branch_cache = [s.strip() for s in re.split(r"\r?\n", out) if s.strip()]
        except (subprocess.CalledProcessError, OSError):
            self._branch_cache = []
        return self._branch_cache

    def _branch_matches_slug(self, slug):
        if not slug:
            return False
        low = slug.lower()
        return any(low in b.lower() for b in self._branches())

    def _resolve_gh(self):
        self.GH_MODE = "live"
        self.GH_STATE = None
        if self.GH_FORCE == "off":
            self.GH_MODE = "off"
            return
        if self.GH_STATE_FILE:
            try:
                self.GH_STATE = json.loads(self._read_file_safe(self.GH_STATE_FILE) or "{}")
                self.GH_MODE = "stub"
                return
            except ValueError:
                self.GH_MODE = "off"
                return
        try:
            subprocess.run(["sh", "-c", "command -v gh"], stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, check=True)
        except (subprocess.CalledProcessError, OSError):
            self.GH_MODE = "off"
            return
        try:
            subprocess.run(["gh", "auth", "status"], stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, check=True)
        except (subprocess.CalledProcessError, OSError):
            self.GH_MODE = "off"
            return

    def _gh_state(self, n):
        if n is None:
            return None
        if self.GH_MODE == "off":
            return None
        if self.GH_MODE == "stub":
            if self.GH_STATE and str(n) in self.GH_STATE and self.GH_STATE[str(n)]:
                return self.GH_STATE[str(n)]
            return None
        try:
            out = subprocess.run(["gh", "issue", "view", str(n), "--json", "state", "-q", ".state"],
                                 cwd=self.ROOT, stdout=subprocess.PIPE,
                                 stderr=subprocess.DEVNULL, check=True).stdout.decode("utf-8")
            return out.strip().upper() or None
        except (subprocess.CalledProcessError, OSError):
            return None

    # ── ledger parse ────────────────────────────────────────────────────────────
    @staticmethod
    def _strip_md(v):
        v = re.sub(r"`([^`]+)`", r"\1", v)
        v = re.sub(r"\*\*([^*]+)\*\*", r"\1", v)
        v = re.sub(r"\*([^*]+)\*", r"\1", v)
        v = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1", v)
        return v.strip()

    def _parse_bullet(self, block, section):
        text = " ".join(l.strip() for l in block)
        text = re.sub(r"\s+", " ", text).strip()
        title_match = re.match(r"^- \*\*(.+?)\*\*", text)
        if title_match:
            title = self._strip_md(title_match.group(1))
        else:
            title = self._strip_md(re.sub(r"^- ", "", text))
        status = "—"
        for e in KNOWN_EMOJI:
            if e in text:
                status = e
                break
        links = []
        for m in re.finditer(r"\[([^\]]+)\]\(([^)]+)\)", text):
            links.append({"label": m.group(1), "target": m.group(2)})
        return {"title": title, "status": status, "links": links, "raw": text, "section": section}

    def _parse_ledger(self, raw):
        lines = re.split(r"\r?\n", raw)
        out = []
        in_ledger = False
        current = None
        i = 0
        n = len(lines)
        while i < n:
            line = lines[i]
            if not in_ledger:
                if re.match(r"^##\s+Ledger\s*$", line.strip()):
                    in_ledger = True
                i += 1
                continue
            if re.match(r"^##\s+", line) and not re.match(r"^##\s+Ledger\s*$", line.strip()):
                break
            sm = re.match(r"^###\s+(.+?)\s*$", line)
            if sm:
                current = sm.group(1).strip() if sm.group(1).strip() in SECTIONS else None
                i += 1
                continue
            if not current or not re.match(r"^- \*\*", line):
                i += 1
                continue
            block = [line]
            while i + 1 < n:
                nx = lines[i + 1]
                if re.match(r"^###\s+", nx) or re.match(r"^##\s+", nx) or re.match(r"^- \*\*", nx):
                    break
                block.append(nx)
                i += 1
            out.append(self._parse_bullet(block, current))
            i += 1
        return out

    def _parse_lanes_table(self, raw):
        lines = re.split(r"\r?\n", raw)
        h = -1
        for idx, l in enumerate(lines):
            if re.match(r"^##\s+Lanes\s*$", l.strip()):
                h = idx
                break
        if h < 0:
            return []

        def split_row(l):
            s = l.strip()
            s = re.sub(r"^\|", "", s)
            s = re.sub(r"\|$", "", s)
            return [self._strip_md(c.strip()) for c in s.split("|")]

        i = h + 1
        while i < len(lines) and not re.match(r"^\s*\|", lines[i]) and not re.match(r"^#{1,6}\s+", lines[i]):
            i += 1
        if i >= len(lines) or not re.match(r"^\s*\|", lines[i]):
            return []
        header = split_row(lines[i])
        i += 1
        if i < len(lines) and re.match(r"^\s*\|?\s*-{2,}", lines[i]):
            i += 1

        def col(name):
            for idx, c in enumerate(header):
                if c.lower() == name.lower():
                    return idx
            return -1

        lane_idx, pr_idx, rev_idx = col("Lane"), col("PR"), col("Reviewer")
        rows = []
        while i < len(lines) and re.match(r"^\s*\|", lines[i]):
            cells = split_row(lines[i])

            def at(cs, idx):
                return cs[idx] if 0 <= idx < len(cs) else ""
            rows.append({
                "lane": at(cells, lane_idx) if lane_idx >= 0 else (cells[0] if cells else ""),
                "pr": at(cells, pr_idx) if pr_idx >= 0 else "",
                "reviewer": at(cells, rev_idx) if rev_idx >= 0 else "",
            })
            i += 1
        return rows

    # ── item resolution ────────────────────────────────────────────────────────
    @staticmethod
    def _gh_issue_of(item):
        t = re.search(r"\bGH-(\d+)\b", item["title"])
        if t:
            return int(t.group(1))
        for l in item["links"]:
            m = re.search(r"github\.com/[^\s)]+/issues/(\d+)", l["target"])
            if m:
                return int(m.group(1))
        return None

    def _doc_of(self, item, gh=None):
        mds = [l["target"] for l in item["links"]
               if re.search(r"\.md($|#)", l["target"]) and "PROJECT/" in l["target"]
               and "relay-system/" not in l["target"]]
        if not mds:
            return None
        issue = gh if gh is not None else self._gh_issue_of(item)
        own = None
        if issue is not None:
            own = re.compile(r"(^|/)GH-%d-[^/]+\.md($|#)" % issue, re.I)
        pick = None
        if own is not None:
            for t in mds:
                if "2-WORKING/" in t and own.search(t):
                    pick = t
                    break
        if pick is None and own is not None:
            for t in mds:
                if own.search(t):
                    pick = t
                    break
        if pick is None:
            for t in mds:
                if "2-WORKING/" in t:
                    pick = t
                    break
        if pick is None:
            pick = mds[0]
        return re.sub(r"#.*$", "", pick)

    @staticmethod
    def _slug_of(doc_rel, title):
        if doc_rel:
            base = os.path.basename(doc_rel)
            if base.endswith(".md"):
                base = base[:-3]
        else:
            base = title
        s = re.sub(r"[^a-z0-9]+", "-", base.lower())
        s = re.sub(r"^-+|-+$", "", s)
        return s or "item"

    def _zone_of(self, contract, item):
        if contract and isinstance(contract.get("artifacts"), list):
            arts = contract["artifacts"]
            orch_only = (contract.get("lanes") or {}).get("orchestrator_only") or []
            for zone in self.ZONES["zones"]:
                if not zone["escalateOrchestratorOnly"]:
                    continue
                touches = any(any(a == o or a.startswith(o) for o in orch_only) for a in arts)
                if touches:
                    return {"zone": zone["name"], "inferred": False, "writeset": arts, "zoneRule": zone}
            for zone in self.ZONES["zones"]:
                if any(self._zone_matches_path(zone, a) for a in arts):
                    return {"zone": zone["name"], "inferred": False, "writeset": arts, "zoneRule": zone}
            return {"zone": self.ZONES["defaultZone"]["name"], "inferred": False,
                    "writeset": arts, "zoneRule": self.ZONES["defaultZone"]}
        hay = (item["title"] + " " + item["raw"]).lower()
        for zone in self.ZONES["zones"]:
            if zone["inferKeywordRegex"] and zone["inferKeywordRegex"].search(hay):
                return {"zone": zone["name"], "inferred": True, "writeset": [], "zoneRule": zone}
        return {"zone": self.ZONES["defaultZone"]["name"], "inferred": True,
                "writeset": [], "zoneRule": self.ZONES["defaultZone"]}

    @staticmethod
    def _deps_of(item):
        deps = []
        outer = re.compile(
            r"(?:after|once|depends on|gated on|blocked by)\s+((?:(?:GH-|#)\d+(?:\s*(?:,|&|/|and|or)\s*)*)+)",
            re.I)
        inner = re.compile(r"(?:GH-|#)(\d+)")
        for m in outer.finditer(item["raw"]):
            for nm in inner.finditer(m.group(1)):
                d = int(nm.group(1))
                if d not in deps:
                    deps.append(d)
        return deps

    @staticmethod
    def _is_go_gated(item):
        return bool(re.search(
            r"gated on operator go|gated on (a |an )?operator|operator go\b|awaiting go\b",
            item["raw"], re.I))

    # ── GH-5 contract-seam helpers ──────────────────────────────────────────────
    @staticmethod
    def _dir_prefixes(p):
        s = str(p)
        ends_dir = bool(re.search(r"/$", s))
        parts = [seg for seg in s.split("/") if seg]
        if not ends_dir and parts:
            parts.pop()
        out = []
        acc = ""
        for seg in parts:
            acc = acc + "/" + seg if acc else seg
            out.append(acc)
        return out

    def _shared_spine(self, ws_a, ws_b):
        def depth(x):
            return len(x.split("/"))
        best = None
        for pa in ws_a:
            pref = self._dir_prefixes(pa)
            for pb in ws_b:
                set_b = set(self._dir_prefixes(pb))
                for d in pref:
                    if "/" not in d or d not in set_b:
                        continue
                    if (best is None or depth(d) > depth(best)
                            or (depth(d) == depth(best) and d < best)):
                        best = d
        return best

    # ── findings ────────────────────────────────────────────────────────────────
    def _flag(self, severity, ftype, rec, message, action):
        self.findings.append({
            "severity": severity, "type": ftype,
            "item": rec["title"] if rec else "(run)",
            "file": rec["docRel"] if rec else "",
            "message": message, "action": action,
        })

    @staticmethod
    def _find_by_gh(deduped, d):
        for x in deduped:
            if x["gh"] == d:
                return x
        return None

    def _list_md_recursive(self, d):
        out = []
        try:
            ents = os.listdir(d)
        except OSError:
            return out
        for name in ents:
            full = os.path.join(d, name)
            if os.path.isdir(full):
                out.extend(self._list_md_recursive(full))
            elif name.endswith(".md") and name != "blank.md":
                out.append(full)
        return out

    # ── main compute ────────────────────────────────────────────────────────────
    def run(self, render_out):
        """Parse → resolve → score → wave-pack → render. Prints the report to stdout,
        writes the rendered doc to ``render_out``, returns the exit code."""
        raw = self._read_file_safe(self.ROADMAP)
        if raw is None:
            raise EngineExit(3, "marathon-plan: cannot read ROADMAP")
        ledger = self._parse_ledger(raw)
        if not ledger:
            raise EngineExit(3, "marathon-plan: no ledger items parsed (is '## Ledger' present?)")

        records = []
        for item in ledger:
            gh = self._gh_issue_of(item)
            doc_rel = self._doc_of(item, gh)
            doc_abs = os.path.normpath(os.path.join(self.ROOT, doc_rel)) if doc_rel else None
            doc_exists = self._exists_at(doc_rel) if doc_rel else False
            slug = self._slug_of(doc_rel, item["title"])
            fm = self._frontmatter(doc_abs) if doc_exists else {}
            ratings = {"complexity": _L(fm.get("complexity")),
                       "risk": _L(fm.get("risk")), "effort": _L(fm.get("effort"))}
            rated = all(ratings[k] is not None for k in ("complexity", "risk", "effort"))
            ratings_exempt = str(fm.get("ratings_exempt", "")).lower() == "true"
            contract = self._extract_contract(doc_abs) if doc_exists else None
            z = self._zone_of(contract, item)
            suggested_branch = "marathon/%s-%s" % (slug, self.TODAY)
            records.append({
                "title": item["title"], "section": item["section"], "emoji": item["status"],
                "raw": item["raw"], "gh": gh, "docRel": doc_rel, "docExists": doc_exists,
                "slug": slug, "ratings": ratings, "rated": rated, "ratingsExempt": ratings_exempt,
                "contract": contract, "zone": z["zone"], "zoneInferred": z["inferred"],
                "writeset": z["writeset"], "zoneRule": z["zoneRule"],
                "deps": self._deps_of(item), "goGated": self._is_go_gated(item),
                "suggestedBranch": suggested_branch,
                "flags": [], "signals": [], "state": None, "score": None,
                "wave": None, "ghState": None,
            })

        # Dedup identical (gh, docRel) pairs — keep the first.
        seen = set()
        deduped = []
        for r in records:
            key = ("gh:%d" % r["gh"]) if r["gh"] is not None else ("doc:%s|title:%s" % (r["docRel"] or "", r["title"]))
            if key in seen:
                continue
            seen.add(key)
            deduped.append(r)

        # ── per-item validation signals ────────────────────────────────────────
        for r in deduped:
            if r["gh"] is None and not r["docRel"]:
                r["state"] = "note-only"
                self._flag("info", "note-only", r,
                           "ledger note with no issue and no project doc — nothing to sequence",
                           "human: action or drop the note")
                continue
            if r["docRel"] and not r["docExists"]:
                self._flag("warn", "drift", r,
                           "project doc pointer does not exist on disk: %s" % r["docRel"],
                           "fix or drop the ledger link")
            if r["gh"] is not None:
                st = self._gh_state(r["gh"])
                r["ghState"] = st
                if st is None and self.GH_MODE == "off":
                    self.gh_unverified += 1
                    r["flags"].append("gh-unverified")
                if st == "CLOSED" and r["section"] in ("Queue / parked intake", "In progress"):
                    r["state"] = "already-closed"
                    self._flag("warn", "already-closed", r,
                               'issue #%d is CLOSED but the ledger lists it under "%s"' % (r["gh"], r["section"]),
                               "close the ledger: move to Completed or drop the pointer")
                if st == "OPEN" and r["section"] == "Completed":
                    self._flag("warn", "drift", r,
                               "ledger marks this Completed but issue #%d is still OPEN" % r["gh"],
                               "reopen the ledger entry or close the issue")

            if (r["state"] is None and r["contract"]
                    and isinstance(r["contract"].get("fix_probes"), list) and r["contract"]["fix_probes"]):
                if r["section"] not in ("Completed", "Deferred · vision"):
                    verdicts = [self._eval_probe(p) for p in r["contract"]["fix_probes"]]
                    if verdicts and all(v == "landed" for v in verdicts):
                        r["state"] = "already-landed"
                        self._flag("warn", "already-landed", r,
                                   "all fix_probes report 'landed' — the fix is already present",
                                   "verify-and-close, not a build lane")

            if r["state"] is None:
                sig = []
                if r["contract"] and isinstance(r["contract"].get("artifacts"), list):
                    ref = (r["contract"].get("target") or {}).get("ref") or "HEAD"
                    has_new = any(self._exists_at(a) and not self._file_existed_at_base_ref(a, ref)
                                  for a in r["contract"]["artifacts"])
                    if has_new:
                        sig.append("some-artifacts-exist")
                if self._branch_matches_slug(r["slug"]):
                    sig.append("branch-matches-slug")
                try:
                    if any(r["slug"] in f.lower() for f in os.listdir(os.path.join(self.ROOT, "test"))):
                        sig.append("tests-reference-slug")
                except OSError:
                    pass
                if r["emoji"] == "\U0001F7E2" and r["section"] != "Completed":
                    sig.append("built-not-closed-emoji")
                r["signals"] = sig
                if len(sig) >= 2:
                    r["state"] = "partial"
                    self._flag("warn", "undocumented-partial-completion", r,
                               "%d signals of work not reflected in ledger status: %s" % (len(sig), ", ".join(sig)),
                               "human: reconcile — confirm scope done vs remaining, update ledger status")

        # run-level coverage drift
        self._coverage_drift(ledger)

        # ── readiness classification ───────────────────────────────────────────
        for r in deduped:
            if r["state"]:
                continue
            if r["section"] == "Completed":
                r["state"] = "completed-ref"
                continue
            if r["section"] == "Deferred · vision":
                r["state"] = "deferred"
                continue
            if r["ratingsExempt"]:
                r["state"] = "exempt"
                continue
            if r["gh"] is not None and not r["docRel"]:
                r["state"] = "needs-doc"
                self._flag("info", "needs-doc", r,
                           "issue #%d has no PROJECT capture doc linked in the ledger" % r["gh"],
                           "promote to a 2-WORKING capture doc with a preflight contract")
                continue
            if r["docExists"] and not r["rated"]:
                r["state"] = "unrated"
                missing = [k for k in ("complexity", "risk", "effort") if r["ratings"][k] is None]
                self._flag("info", "unrated", r,
                           "project doc missing rating key(s): %s" % ", ".join(missing),
                           "add complexity/risk/effort frontmatter (see PDDA.md)")
                continue
            if r["docExists"] and not r["contract"]:
                r["state"] = "needs-contract"
                self._flag("info", "needs-contract", r,
                           "rated, but no preflight contract — not marathon-ready",
                           "add a ## Swarm Preflight Contract json block")
                continue
            if r["goGated"]:
                r["state"] = "gated"
                continue
            r["state"] = "ready"

        # ── optional deep delegation ───────────────────────────────────────────
        if self.DEEP and self.SWARM_PREFLIGHT:
            for r in deduped:
                if r["state"] != "ready" or not r["docRel"]:
                    continue
                code = 0
                try:
                    subprocess.run(["bash", self.SWARM_PREFLIGHT, "--project-doc", r["docRel"], "--dry-run"],
                                   cwd=self.ROOT, stdout=subprocess.DEVNULL,
                                   stderr=subprocess.DEVNULL, check=True)
                except subprocess.CalledProcessError as e:
                    code = e.returncode or 1
                except OSError:
                    code = 1
                if code == 4:
                    r["state"] = "already-landed"
                    self._flag("warn", "already-landed", r,
                               "swarm-preflight --dry-run → stale (exit 4)",
                               "verify-and-close, not a build lane")
                elif code == 5:
                    r["state"] = "not-ready"
                    self._flag("info", "not-ready", r,
                               "swarm-preflight --dry-run → not marathon-ready (exit 5)",
                               "see swarm-preflight next-action")
                elif code in (6, 7):
                    r["state"] = "blocked"
                    self._flag("info", "blocked", r,
                               "swarm-preflight --dry-run → %s (exit %d)"
                               % ("blocked" if code == 6 else "ambiguous", code),
                               "resolve target/contract before sequencing")

        # ── dependency resolution ──────────────────────────────────────────────
        for r in deduped:
            for d in r["deps"]:
                if not any(x["gh"] == d for x in deduped):
                    self._flag("info", "dep-not-found", r,
                               "lists a dependency on #%d, which is not in the ledger" % d,
                               "fix the issue number or add a ledger pointer")

        dep_changed = True
        while dep_changed:
            dep_changed = False
            for r in deduped:
                if r["state"] != "ready":
                    continue
                blocked_by = []
                for d in r["deps"]:
                    dep = self._find_by_gh(deduped, d)
                    if not dep or dep["state"] in DEP_RESOLVED or dep["state"] == "ready":
                        continue
                    blocked_by.append(d)
                if blocked_by:
                    r["state"] = "blocked-dep"
                    dep_changed = True
                    self._flag("info", "blocked-dep", r,
                               "depends on a held/unbuildable item (%s) — excluded from active waves until the dependency is sequenceable"
                               % ", ".join("#" + str(d) for d in blocked_by),
                               "rate/unblock the dependency first")

        # ── scoring ─────────────────────────────────────────────────────────────
        W = {"eff": 2, "cx": 1, "risk": 2, "dep": 3, "zone": 1}
        risk_sign = -1 if self.POLICY == "derisk-first" else 1
        risk_w = 4 if self.POLICY == "derisk-first" else W["risk"]

        def score_of(r):
            if not r["rated"]:
                return None
            s = W["eff"] * r["ratings"]["effort"] + W["cx"] * r["ratings"]["complexity"] \
                + risk_sign * risk_w * r["ratings"]["risk"]
            zone_penalty = r["zoneRule"]["penalty"] if (r["zoneRule"] and math.isfinite(_js_number(r["zoneRule"]["penalty"]))) else 0
            s += W["dep"] * len(r["deps"]) + W["zone"] * zone_penalty
            if r["state"] == "gated":
                s += 100
            return s

        for r in deduped:
            r["score"] = score_of(r)

        # ── wave packing ────────────────────────────────────────────────────────
        def active_cmp(a, b):
            # JS: `if (a.score !== b.score) return a.score - b.score;` — null coerces to 0 in the
            # subtraction, so a ready-but-unrated lane (score None) sorts as 0. Mirror that exactly.
            sa, sb = a["score"], b["score"]
            if sa != sb:
                na = 0 if sa is None else sa
                nb = 0 if sb is None else sb
                return na - nb
            if len(a["deps"]) != len(b["deps"]):
                return len(a["deps"]) - len(b["deps"])
            za, zb = self._zone_rank(a["zone"]), self._zone_rank(b["zone"])
            if za != zb:
                return za - zb
            ga = a["gh"] if a["gh"] is not None else 1000000000
            gb = b["gh"] if b["gh"] is not None else 1000000000
            if ga != gb:
                return -1 if ga < gb else 1
            if a["slug"] < b["slug"]:
                return -1
            if a["slug"] > b["slug"]:
                return 1
            return 0

        active = sorted([r for r in deduped if r["state"] == "ready"],
                        key=functools.cmp_to_key(active_cmp))

        waves = []
        placed_issue = {}
        pending = active[:]
        guard = 0
        while pending and guard < 100:
            guard += 1
            wave = []
            wave_writeset = set()
            wave_zone_counts = {}
            deferred = []
            for r in pending:
                dep_unmet = False
                for d in r["deps"]:
                    dep = self._find_by_gh(deduped, d)
                    if not dep or dep["state"] in DEP_RESOLVED:
                        continue
                    if d not in placed_issue:
                        dep_unmet = True
                        break
                collides = any(p in wave_writeset for p in r["writeset"])
                cap = r["zoneRule"]["maxPerWave"] if (r["zoneRule"] and isinstance(r["zoneRule"]["maxPerWave"], int)) else None
                zone_cap_clash = cap is not None and wave_zone_counts.get(r["zone"], 0) >= cap
                inferred_zone_clash = bool(r["zoneRule"] and r["zoneRule"]["conservativeWhenInferred"]
                                           and r["zoneInferred"] and any(w["zone"] == r["zone"] for w in wave))
                if dep_unmet or collides or zone_cap_clash or inferred_zone_clash:
                    deferred.append(r)
                    continue
                wave.append(r)
                for p in r["writeset"]:
                    wave_writeset.add(p)
                wave_zone_counts[r["zone"]] = wave_zone_counts.get(r["zone"], 0) + 1
            if len(wave) == 0:
                waves.append(deferred)
                for r in deferred:
                    if r["gh"] is not None:
                        placed_issue[r["gh"]] = len(waves) - 1
                break
            waves.append(wave)
            for r in wave:
                if r["gh"] is not None:
                    placed_issue[r["gh"]] = len(waves) - 1
            pending = deferred
        for i, w in enumerate(waves):
            for r in w:
                r["wave"] = i + 1

        # GH-5 contract seams
        contract_seams = []
        for w in waves:
            for i in range(len(w)):
                for j in range(i + 1, len(w)):
                    a, b = w[i], w[j]
                    if not a["writeset"] or not b["writeset"]:
                        continue
                    spine = self._shared_spine(a["writeset"], b["writeset"])
                    if spine:
                        contract_seams.append({"wave": a["wave"], "a": a, "b": b, "spine": spine})
                        self._flag("warn", "coupled-lanes", a,
                                   "same-wave lane shares the `%s/` spine with %s — write-disjoint but likely a shared contract seam"
                                   % (spine, ("#" + str(b["gh"])) if b["gh"] else b["slug"]),
                                   "pin a CONTRACT.md for the %s/ interface and point both lane prompts at it before launching" % spine)

        # ── exit code ───────────────────────────────────────────────────────────
        has_drift = any(r["state"] in ("already-landed", "already-closed") for r in deduped)
        held = [r for r in deduped if r["state"] in
                ("unrated", "needs-doc", "needs-contract", "note-only", "not-ready", "blocked", "blocked-dep")]
        exit_code = 0
        if has_drift:
            exit_code = 4
        elif held:
            exit_code = 5
        if self.GH_MODE == "off" and self.REQUIRE_GH:
            exit_code = 6

        # ── report ──────────────────────────────────────────────────────────────
        counts = {
            "queue": sum(1 for r in deduped if r["section"] == "Queue / parked intake"),
            "inprog": sum(1 for r in deduped if r["section"] == "In progress"),
            "active": len(active),
        }
        weight_str = "eff:%d,cx:%d,risk:%d%s,dep:%d,zone:%d" % (
            W["eff"], W["cx"], risk_w, "(−)" if risk_sign < 0 else "", W["dep"], W["zone"])

        report = self._render_report(deduped, active, waves, held, has_drift,
                                     exit_code, counts, weight_str)
        # Print report to stdout exactly as the Bash engine did (no trailing extra newline).
        sys.stdout.write(report)

        rendered = self._render_queue_doc(deduped, active, waves, held, has_drift,
                                          contract_seams, weight_str)
        with open(render_out, "w", encoding="utf-8") as f:
            f.write(rendered)
        return exit_code

    def _coverage_drift(self, ledger):
        pointed = set()
        for it in ledger:
            for l in it["links"]:
                t = re.sub(r"#.*$", "", l["target"])
                if t.endswith(".md"):
                    pointed.add(os.path.basename(t))
        for full in self._list_md_recursive(self.QUEUE_DIR):
            base = os.path.basename(full)
            if re.match(r"^(MARATHON-PLAN|QUEUE)-\d{4}-\d\d-\d\d\.md$", base):
                continue
            if base in pointed:
                continue
            fm = self._frontmatter(full)
            if str(fm.get("roadmap_exempt", "")).lower() == "true":
                continue
            self.findings.append({
                "severity": "info", "type": "drift", "item": base,
                "file": os.path.relpath(full, self.ROOT),
                "message": "2-WORKING doc has no ROADMAP ledger pointer",
                "action": "add a ledger pointer or set roadmap_exempt: true",
            })

    # ── report rendering ────────────────────────────────────────────────────────
    def _render_report(self, deduped, active, waves, held, has_drift, exit_code, counts, weight_str):
        if self.FORMAT == "json":
            lines = []
            for f in self.findings:
                obj = {"timestamp": self.NOW, "severity": f["severity"],
                       "check": "marathon-plan/%s" % f["type"], "file": f["file"] or "",
                       "message": f["message"], "action": f["action"]}
                lines.append(json.dumps(obj, ensure_ascii=False, separators=(",", ":")))
            summary = {"timestamp": self.NOW, "severity": "warn" if exit_code else "info",
                       "check": "marathon-plan/summary", "file": "",
                       "message": "items=%d active=%d waves=%d drift=%s held=%d gh=%s"
                       % (len(deduped), len(active), len(waves),
                          "true" if has_drift else "false", len(held), self.GH_MODE),
                       "action": "summary"}
            lines.append(json.dumps(summary, ensure_ascii=False, separators=(",", ":")))
            return "\n".join(lines) + "\n"

        out = []
        out.append("marathon-plan · %s · policy=%s · weights{%s} · gh=%s"
                   % (self.TODAY, self.POLICY, weight_str, self.GH_MODE))
        out.append("  ledger items : %d  (queue %d · in-progress %d)"
                   % (len(deduped), counts["queue"], counts["inprog"]))
        out.append("  active lanes : %d across %d wave(s)   held: %d%s"
                   % (len(active), len(waves), len(held),
                      ("   gh-unverified: %d" % self.gh_unverified) if self.gh_unverified else ""))
        if self.GH_MODE == "off":
            out.append("  NOTE gh %s: open/closed state not verified — relying on ledger section only"
                       % ("disabled" if self.GH_FORCE == "off" else "unavailable"))
        out.append("")
        out.append("FLAGS (deterministic signals — never auto-resolved)")
        order = {"warn": 0, "info": 1}

        def find_cmp(a, b):
            d = order[a["severity"]] - order[b["severity"]]
            if d:
                return d
            if a["type"] < b["type"]:
                return -1
            if a["type"] > b["type"]:
                return 1
            return 0

        sorted_f = sorted(self.findings, key=functools.cmp_to_key(find_cmp))
        if not sorted_f:
            out.append("  (none)")
        for f in sorted_f:
            out.append("  %s [%s]  %s" % (f["severity"].upper().ljust(4), f["type"], f["item"]))
            out.append("        %s" % f["message"])
            out.append("        → %s" % f["action"])
        out.append("")
        out.append("SUMMARY [marathon-plan] items=%d active=%d waves=%d drift=%s held=%d (exit %d)"
                   % (len(deduped), len(active), len(waves),
                      "true" if has_drift else "false", len(held), exit_code))
        return "\n".join(out) + "\n"

    # ── marathon-plan doc rendering ─────────────────────────────────────────────
    def _render_queue_doc(self, deduped, active, waves, held, has_drift, contract_seams, weight_str):
        zone_rows = list(self.ZONES["zones"]) + [self.ZONES["defaultZone"]]
        capped = [z for z in zone_rows if isinstance(z["maxPerWave"], int)]
        cap_summary = ", ".join("%s≤%d/wave" % (z["name"], z["maxPerWave"]) for z in capped) if capped else "none"
        o = []
        o.append("---")
        o.append("title: Marathon Plan — ranked, freshness-validated, collision-aware queue")
        o.append("status: Active (2-WORKING)")
        o.append("created: %s" % self.TODAY)
        o.append("updated: %s" % self.TODAY)
        o.append("owner: noel")
        o.append("branch: main")
        o.append("doc_type: project")
        o.append("source: ../../ROADMAP.md (open ledger entries)")
        o.append("generated_by: %s" % self.MP_CMD)
        o.append("roadmap_exempt: true")
        o.append("goal: >")
        o.append("  A sequenced concurrency plan derived from ROADMAP.md: ranks surviving work by PDDA")
        o.append("  complexity/risk/effort, validates each item is still real, and batches collision-safe")
        o.append("  lanes into waves. Generated — edit the ledger, not this file.")
        o.append("---")
        o.append("")
        o.append("<!-- GENERATED by utils/marathon-plan.sh from ROADMAP.md — re-run to refresh; edit the ledger, not this file. -->")
        o.append("")
        o.append("# Marathon Plan %s — pre-pre-flight sequenced queue" % self.TODAY)
        o.append("")
        o.append("> Derived from [ROADMAP.md](../../ROADMAP.md) · policy `%s` · weights {%s} · gh=%s."
                 % (self.POLICY, weight_str, self.GH_MODE))
        o.append("> The roadmap says **what/why**; this says **what is still real and in what order**. Execution")
        o.append("> detail still lives in each `PROJECT/**` doc — this is a scheduling overlay.")
        o.append("")
        o.append("## Status")
        o.append("")
        o.append("| What was just completed | What's next |")
        o.append("|---|---|")
        first_wave = " ‖ ".join(("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in waves[0]) if waves else "(none)"
        o.append("| Generated by `utils/marathon-plan.sh` on %s from the live ROADMAP ledger (%d items; %d active across %d wave(s); %d held). Drift present: %s. | **Wave 1:** %s. Fire each lane via `swarm-preflight → marathon-drive`, scoped by `ALLOW_PATHS`. Re-run this script when the ledger changes. |"
                 % (self.TODAY, len(deduped), len(active), len(waves), len(held),
                    "yes — see Held/Flagged" if has_drift else "no", first_wave))
        o.append("")
        o.append("## The one safety rule")
        o.append("")
        o.append("Two lanes are safe to run concurrently **iff their write-sets are disjoint** and their zone")
        o.append("caps are respected. Current caps: %s." % cap_summary)
        o.append("")
        o.append("## Collision map")
        o.append("")
        o.append("| Zone | Parallel-safe? | Active items here |")
        o.append("|---|---|---|")
        for zone in zone_rows:
            items = [("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in active if r["zone"] == zone["name"]]
            safe = "✅ one lane per file"
            if isinstance(zone["maxPerWave"], int):
                safe = "❌ serialize — one at a time" if zone["maxPerWave"] == 1 else "❌ cap %d per wave" % zone["maxPerWave"]
            elif zone["conservativeWhenInferred"]:
                safe = "✅ one lane per file (serialize when inferred)"
            o.append("| %s | %s | %s |" % (zone["name"], safe, ", ".join(items) if items else "—"))
        o.append("")
        o.append("## Per-item scoring")
        o.append("")
        o.append("Every input is shown so the ordering is verifiable by hand (lower score = earlier).")
        o.append("")
        o.append("| Item | cx | risk | eff | zone | deps | score | wave |")
        o.append("|---|---|---|---|---|---|---|---|")
        for r in active:
            ident = ("[#%d] %s" % (r["gh"], r["title"])) if r["gh"] else r["title"]
            deps_cell = ",".join("#" + str(d) for d in r["deps"]) if r["deps"] else "—"
            o.append("| %s | %s | %s | %s | %s%s | %s | %s | %s |"
                     % (_cell(ident), _rating_num(r["ratings"]["complexity"]),
                        _rating_num(r["ratings"]["risk"]), _rating_num(r["ratings"]["effort"]),
                        r["zone"], "*" if r["zoneInferred"] else "", deps_cell,
                        _cell(r["score"]), _cell(r["wave"])))
        if not active:
            o.append("| (no active, ready, rated items) | — | — | — | — | — | — | — |")
        o.append("")
        o.append("`*` = zone inferred from keywords (no preflight contract write-set to prove it).")
        o.append("")
        o.append("## Recommended waves")
        o.append("")
        if not waves:
            o.append("_No active lanes — every item is held or flagged (see below)._")
        for i, w in enumerate(waves):
            lanes = " ‖ ".join(("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in w)
            o.append("**Wave %d:** %s" % (i + 1, lanes if lanes else "(empty)"))
            o.append("")
            for r in w:
                ident = ("#" + str(r["gh"])) if r["gh"] else r["slug"]
                o.append("- %s → suggested_branch: `%s`" % (ident, r["suggestedBranch"]))
            if w:
                o.append("")
        o.append("## Contract seams — pin a contract before launching (GH-5)")
        o.append("")
        if not contract_seams:
            o.append("_None — no two same-wave lanes share a directory spine (deeper than a top-level dir)._")
            o.append("")
        else:
            o.append("These same-wave lanes are **write-disjoint but share a directory spine**, so they likely share")
            o.append("an interface (a not-yet-built module/schema). xyz is not for tightly-coupled work: pin a short")
            o.append("`CONTRACT.md` for the seam and point **each** lane's prompt at it (code TO the contract, not to")
            o.append("the other lane's source), or the split can stall when the consumer waits on the producer's handoff.")
            o.append("")
            for s in contract_seams:
                an = ("#" + str(s["a"]["gh"])) if s["a"]["gh"] else s["a"]["slug"]
                bn = ("#" + str(s["b"]["gh"])) if s["b"]["gh"] else s["b"]["slug"]
                o.append("- **Wave %d:** %s ‖ %s share `%s/` → pin a contract for that seam." % (s["wave"], an, bn, s["spine"]))
            o.append("")
        o.append("## Held / flagged — excluded from active waves")
        o.append("")
        buckets = [
            ("✅ Likely done — verify-and-close, not a build lane", ["already-landed", "already-closed"]),
            ("\U0001F527 Reconcile — undocumented partial completion", ["partial"]),
            ("⏸️ Gated on operator GO", ["gated"]),
            ("⚠️ Not yet sequenceable — rate / add doc / add contract",
             ["unrated", "needs-doc", "needs-contract", "not-ready", "blocked"]),
            ("⛔ Blocked on a held dependency", ["blocked-dep"]),
            ("\U0001F6AB Rating-exempt (completed / hub / superseded)", ["exempt"]),
            ("\U0001F5D2️ Notes (no issue, no doc)", ["note-only"]),
        ]
        for label, states in buckets:
            items = [r for r in deduped if r["state"] in states]
            if not items:
                continue
            o.append("### %s" % label)
            for r in items:
                ident = ("#%d " % r["gh"]) if r["gh"] else ""
                why = " (would score %s)" % r["score"] if (r["state"] == "gated" and r["score"] is not None) else ""
                o.append("- %s%s — `%s`%s" % (ident, r["title"], r["state"], why))
            o.append("")

        # GH-86: native "Review lanes" overlay (folds the former _inject_review_lanes shim).
        review_rel = "PR-REVIEW-QUEUE-%s.md" % self.TODAY
        review_raw = self._read_file_safe(os.path.join(self.QUEUE_DIR, review_rel))
        if review_raw is not None:
            review_lanes = self._parse_lanes_table(review_raw)
            o.append("## Review lanes (manual overlay — run via relay-xyz)")
            o.append("")
            o.append("A separate manual overlay — [%s](%s) — is not derived from" % (review_rel, review_rel))
            o.append("ROADMAP.md and does not appear in the waves above (a review lane evaluates an existing PR")
            o.append("diff; it doesn't remediate a ledger item). Fire each via `relay-xyz`, per the overlay doc.")
            o.append("")
            if review_lanes:
                o.append("| Lane | PR | Reviewer |")
                o.append("|---|---|---|")
                for l in review_lanes:
                    o.append("| %s | %s | %s |" % (_cell(l["lane"]), _cell(l["pr"]), _cell(l["reviewer"])))
            else:
                o.append("_%s exists but its `## Lanes` table could not be parsed._" % review_rel)
            o.append("")

        o.append("## How to fire a lane")
        o.append("")
        o.append("Per lane, the existing pipeline applies — no new control plane:")
        o.append("")
        o.append("```")
        o.append("%s --project-doc <PROJECT/**/doc.md>   # or --gh-issue N" % self.SP_CMD)
        o.append("   → ready packet (candidate/freshness/fix-still-required + lane assignment)")
        o.append("%s ...   # build→gate→review, contained" % self.MD_CMD)
        o.append("```")
        o.append("")
        o.append("- **Lane scoping:** give each lane an `ALLOW_PATHS` matching only its zone above.")
        o.append("- If the lane's allowlist includes filesystem-touching `test/*.sh`, treat those tests as read-only specs in-turn; the outer harness gate verifies them after the turn, outside the isolated worktree.")
        o.append("")
        o.append("---")
        o.append("")
        o.append("*Generated from [ROADMAP.md](../../ROADMAP.md) (source of truth). Re-run `%s` after editing the ledger.*" % self.MP_CMD)
        return "\n".join(o) + "\n"


def run(cfg, render_out):
    """Entry point used by marathon_plan.py. Returns the exit code."""
    engine = Engine(cfg)
    return engine.run(render_out)
