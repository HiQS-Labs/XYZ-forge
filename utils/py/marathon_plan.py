#!/usr/bin/env python3
import os
import sys
import re
import subprocess
import tempfile
import shutil
import datetime

# ── Parity shims for behavior missing from the vendored node engine ──────────
# The Python entry point delegates rendering to utils/py/_marathon_plan_node.js, a
# copy of the canonical bash JS engine (utils/marathon-plan.sh) that has drifted on
# two points. These helpers restore parity without touching the node file:
#   S  — docOf must prefer the lane's own GH-<n> pointer over an earlier PROJECT doc
#        link (bash utils/marathon-plan.sh docOf). The node copy still uses the older
#        "first 2-WORKING/GH- else first 2-WORKING else first md link" order, which
#        mis-picks a distractor doc. We normalize the ROADMAP so the node engine
#        resolves the SAME doc bash would — a no-op unless the two pickers diverge.
#   N  — a PR-REVIEW-QUEUE-<today>.md overlay must surface as a "## Review lanes"
#        section (bash GH-86). The node copy omits it; we append it post-render.

_LINK_RE = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')

def _strip_md(v):
    v = re.sub(r'`([^`]+)`', r'\1', v)
    v = re.sub(r'\*\*([^*]+)\*\*', r'\1', v)
    v = re.sub(r'\*([^*]+)\*', r'\1', v)
    v = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'\1', v)
    return v.strip()

def _is_md_doc(target):
    return bool(re.search(r'\.md($|#)', target)) and ('PROJECT/' in target) and ('relay-system/' not in target)

def _node_pick(cands):
    for t in cands:
        if re.search(r'2-WORKING/GH-\d+-', t, re.I):
            return t
    for t in cands:
        if '2-WORKING/' in t:
            return t
    return cands[0] if cands else None

def _bash_pick(cands, issue):
    if issue is not None:
        own = re.compile(r'(^|/)GH-%d-[^/]+\.md($|#)' % issue, re.I)
        for t in cands:
            if '2-WORKING/' in t and own.search(t):
                return t
        for t in cands:
            if own.search(t):
                return t
    for t in cands:
        if '2-WORKING/' in t:
            return t
    return cands[0] if cands else None

def _issue_of(title, links):
    m = re.search(r'\bGH-(\d+)\b', title)
    if m:
        return int(m.group(1))
    for _text, target in links:
        m2 = re.search(r'github\.com/[^\s)]+/issues/(\d+)', target)
        if m2:
            return int(m2.group(1))
    return None

def _normalize_roadmap(text):
    # For each ledger bullet, if the node engine's docOf would pick a different md doc than the bash
    # docOf, prune the rival md-doc links (down-convert them to plain text) so the node engine resolves
    # the bash-correct doc. Bullet prose/links never appear in the rendered output, so this is invisible
    # except via the resolved doc. No-op when pickers agree.
    #
    # A ledger bullet can span CONTINUATION lines (a distractor doc on the first line, the item's own
    # GH-<n> doc on a wrapped line — GH-255 Codex review r2). So group each bullet WITH its continuation
    # lines into a block, collect the links across the whole block, and prune rival links across every
    # line of the block — mirroring how the engine assembles a bullet before collecting its links.
    lines = text.split('\n')
    n = len(lines)

    def _is_ledger_bullet(l):
        # canonical ledger item: an UNINDENTED bold bullet `- **Title** …`
        return re.match(r'^- \*\*', l) is not None

    def _ends_block(l):
        # a block ends ONLY at the next unindented ledger boundary — a `##`/`###` heading or the next
        # `- **` bullet. Blank lines, nested lists, and wrapped continuation lines stay IN the block
        # (mirrors how the engine assembles a bullet before collecting its links; GH-255 Codex r3).
        return re.match(r'^(#{2,3}\s|- \*\*)', l) is not None

    out_lines = []
    i = 0
    while i < n:
        line = lines[i]
        if not _is_ledger_bullet(line):
            out_lines.append(line)
            i += 1
            continue
        block = [line]
        j = i + 1
        while j < n and not _ends_block(lines[j]):
            block.append(lines[j])
            j += 1
        i = j
        block_text = '\n'.join(block)
        links = _LINK_RE.findall(block_text)
        cands = [target.split('#')[0] for (_t, target) in links if _is_md_doc(target)]
        if len(cands) < 2:
            out_lines.extend(block)
            continue
        tm = re.match(r'\s*- \*\*(.+?)\*\*', line)
        title = tm.group(1) if tm else ''
        issue = _issue_of(title, links)
        np = _node_pick(cands)
        bp = _bash_pick(cands, issue)
        if np == bp:
            out_lines.extend(block)
            continue

        def _repl(m):
            target = m.group(2)
            base = target.split('#')[0]
            if _is_md_doc(target) and base != bp:
                return m.group(1)
            return m.group(0)

        out_lines.extend(_LINK_RE.sub(_repl, bl) for bl in block)
    return '\n'.join(out_lines)

def _cell(v):
    return str(v) if v is not None else "—"

def _parse_lanes_table(raw):
    lines = re.split(r'\r?\n', raw)
    h = -1
    for idx, l in enumerate(lines):
        if re.match(r'^##\s+Lanes\s*$', l.strip()):
            h = idx
            break
    if h < 0:
        return []
    def split_row(l):
        s = l.strip()
        if s.startswith('|'):
            s = s[1:]
        if s.endswith('|'):
            s = s[:-1]
        return [_strip_md(c.strip()) for c in s.split('|')]
    i = h + 1
    while i < len(lines) and not re.match(r'^\s*\|', lines[i]) and not re.match(r'^#{1,6}\s+', lines[i]):
        i += 1
    if i >= len(lines) or not re.match(r'^\s*\|', lines[i]):
        return []
    header = split_row(lines[i])
    i += 1
    if i < len(lines) and re.match(r'^\s*\|?\s*-{2,}', lines[i]):
        i += 1
    def col(name):
        for idx, c in enumerate(header):
            if c.lower() == name.lower():
                return idx
        return -1
    lane_idx, pr_idx, rev_idx = col('Lane'), col('PR'), col('Reviewer')
    def at(cells, idx):
        return cells[idx] if 0 <= idx < len(cells) else ''
    rows = []
    while i < len(lines) and re.match(r'^\s*\|', lines[i]):
        cells = split_row(lines[i])
        rows.append({
            'lane': at(cells, lane_idx) if lane_idx >= 0 else (cells[0] if cells else ''),
            'pr': at(cells, pr_idx) if pr_idx >= 0 else '',
            'reviewer': at(cells, rev_idx) if rev_idx >= 0 else '',
        })
        i += 1
    return rows

def _review_lanes_block(review_rel, review_raw):
    lanes = _parse_lanes_table(review_raw)
    o = []
    o.append("## Review lanes (manual overlay — run via relay-xyz)")
    o.append("")
    o.append(f"A separate manual overlay — [{review_rel}]({review_rel}) — is not derived from")
    o.append("ROADMAP.md and does not appear in the waves above (a review lane evaluates an existing PR")
    o.append("diff; it doesn't remediate a ledger item). Fire each via `relay-xyz`, per the overlay doc.")
    o.append("")
    if lanes:
        o.append("| Lane | PR | Reviewer |")
        o.append("|---|---|---|")
        for l in lanes:
            o.append(f"| {_cell(l['lane'])} | {_cell(l['pr'])} | {_cell(l['reviewer'])} |")
    else:
        o.append(f"_{review_rel} exists but its `## Lanes` table could not be parsed._")
    o.append("")
    return o

def _inject_review_lanes(render_out, queue_dir, today):
    review_rel = f"PR-REVIEW-QUEUE-{today}.md"
    review_path = os.path.join(queue_dir, review_rel)
    try:
        with open(review_path, "r", encoding="utf-8") as f:
            review_raw = f.read()
    except OSError:
        return
    try:
        with open(render_out, "r", encoding="utf-8") as f:
            content = f.read()
    except OSError:
        return
    lines = content.split('\n')
    try:
        anchor = lines.index("## How to fire a lane")
    except ValueError:
        return
    block = _review_lanes_block(review_rel, review_raw)
    lines[anchor:anchor] = block
    with open(render_out, "w", encoding="utf-8") as f:
        f.write('\n'.join(lines))

def die(msg):
    sys.stderr.write(f"marathon-plan: {msg}\n")
    sys.exit(2)

def emit(msg):
    sys.stderr.write(f"{msg}\n")

def usage():
    print("""Usage: utils/py/marathon_plan.py [--dry-run | --check] [--policy quick-wins|derisk-first]
                           [--deep] [--require-gh] [--format text|json]

  (default)        Print the validation report and write PROJECT/2-WORKING/MARATHON-PLAN-<today>.md.
  --dry-run        Print the report; write no marathon-plan doc.
  --check          Re-render and compare against today's marathon-plan doc; non-zero on drift. Writes nothing.
  --policy P       quick-wins (default; momentum, low-cost first) | derisk-first (high-risk first).
  --deep           Additionally delegate to utils/swarm-preflight.sh --dry-run per ready item
                   (authoritative ref-based freshness/probe verdict; slower, needs network).
  --require-gh     Treat an unavailable/offline `gh` as a hard error (exit 6) instead of degrading.
  --format F       text (default) | json (findings as one JSON object per line).

Exit: 0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent.""")
    sys.exit(0)

if __name__ == "__main__":
    policy = "quick-wins"
    out_format = "text"
    run_mode = "write"
    deep = False
    require_gh = False

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--dry-run":
            run_mode = "dry-run"
            i += 1
        elif arg == "--check":
            run_mode = "check"
            i += 1
        elif arg == "--policy":
            if i + 1 < len(args):
                policy = args[i+1]
                i += 2
            else:
                die("missing argument for --policy")
        elif arg == "--deep":
            deep = True
            i += 1
        elif arg == "--require-gh":
            require_gh = True
            i += 1
        elif arg == "--format":
            if i + 1 < len(args):
                out_format = args[i+1]
                i += 2
            else:
                die("missing argument for --format")
        elif arg in ("--help", "-h"):
            usage()
        else:
            usage()
            die(f"unknown argument: {arg}")

    if policy not in ("quick-wins", "derisk-first"):
        die("--policy must be 'quick-wins' or 'derisk-first'")
    if out_format not in ("text", "json"):
        die("--format must be 'text' or 'json'")

    here = os.path.dirname(os.path.abspath(__file__))
    here_parent = os.path.dirname(here)
    is_vendored = os.path.basename(os.path.dirname(here_parent)) == ".xyz"

    if is_vendored:
        root = os.environ.get("QUEUE_PLAN_ROOT", os.path.dirname(os.path.dirname(here_parent)))
        sp_cmd = ".xyz/utils/swarm-preflight.sh"
        md_cmd = ".xyz/relay-automation/marathon-drive.sh"
        mp_cmd = ".xyz/utils/marathon-plan.sh"
    else:
        root = os.environ.get("QUEUE_PLAN_ROOT", os.path.dirname(here_parent))
        sp_cmd = "utils/swarm-preflight.sh"
        md_cmd = "relay-automation/marathon-drive.sh"
        mp_cmd = "utils/marathon-plan.sh"

    roadmap = os.environ.get("QUEUE_PLAN_ROADMAP", os.path.join(root, "ROADMAP.md"))
    queue_dir = os.environ.get("QUEUE_PLAN_QUEUE_DIR", os.path.join(root, "PROJECT", "2-WORKING"))
    
    # Python strftime %Y-%m-%dT%H:%M:%SZ
    now = os.environ.get("QUEUE_PLAN_NOW", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    today = os.environ.get("QUEUE_PLAN_TODAY", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d"))

    if not os.path.isfile(roadmap):
        emit(f"ROADMAP not found: {roadmap}")
        sys.exit(3)

    try:
        subprocess.check_call(["node", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        die("node is required (Node stdlib only; no deps) but not found in PATH")

    tmp_dir = tempfile.mkdtemp(prefix="marathon-plan.")
    render_out = os.path.join(tmp_dir, f"MARATHON-PLAN-{today}.md")
    queue_doc = os.path.join(queue_dir, f"MARATHON-PLAN-{today}.md")

    swarm_preflight = os.path.join(here_parent, "swarm-preflight.sh")
    if not (deep and os.path.isfile(swarm_preflight) and os.access(swarm_preflight, os.X_OK)):
        swarm_preflight = ""

    # Parity shim (S): normalize the ROADMAP so the vendored node engine's older docOf
    # resolves the same doc bash's docOf would. No-op unless a bullet's two pickers diverge.
    roadmap_for_node = roadmap
    try:
        with open(roadmap, "r", encoding="utf-8") as f:
            _rm_text = f.read()
        _rm_norm = _normalize_roadmap(_rm_text)
        if _rm_norm != _rm_text:
            roadmap_for_node = os.path.join(tmp_dir, "ROADMAP.normalized.md")
            with open(roadmap_for_node, "w", encoding="utf-8") as f:
                f.write(_rm_norm)
    except OSError:
        roadmap_for_node = roadmap

    env = os.environ.copy()
    env.update({
        "QP_ROOT": root,
        "QP_ROADMAP": roadmap_for_node,
        "QP_QUEUE_DIR": queue_dir,
        "QP_TODAY": today,
        "QP_NOW": now,
        "QP_POLICY": policy,
        "QP_FORMAT": out_format,
        "QP_DEEP": "1" if deep else "0",
        "QP_REQUIRE_GH": "1" if require_gh else "0",
        "QP_SWARM_PREFLIGHT": swarm_preflight,
        "QP_SP_CMD": sp_cmd,
        "QP_MD_CMD": md_cmd,
        "QP_MP_CMD": mp_cmd,
        "QP_RENDER_OUT": render_out,
        "QP_GH_STATE_FILE": os.environ.get("QUEUE_PLAN_GH_STATE_FILE", ""),
        "QP_BRANCHES_FILE": os.environ.get("QUEUE_PLAN_BRANCHES_FILE", ""),
        "QP_GH_FORCE": os.environ.get("QUEUE_PLAN_GH", ""),
        "QP_BASE_FILES_FILE": os.environ.get("QUEUE_PLAN_BASE_FILES_FILE", ""),
    })

    node_script = os.path.join(here, "_marathon_plan_node.js")
    
    try:
        rc = subprocess.call(["node", node_script], env=env)
    except Exception as e:
        sys.stderr.write(f"node error: {e}\n")
        sys.exit(1)

    if rc in (2, 3):
        shutil.rmtree(tmp_dir, ignore_errors=True)
        sys.exit(rc)

    # Parity shim (N/GH-86): surface a PR-REVIEW-QUEUE-<today>.md overlay as a
    # "## Review lanes" section in the rendered doc — the node engine omits it.
    _inject_review_lanes(render_out, queue_dir, today)

    if run_mode == "check":
        if not os.path.isfile(queue_doc):
            emit(f"check: missing artifact: {os.path.relpath(queue_doc, root) if queue_doc.startswith(root) else queue_doc}")
            shutil.rmtree(tmp_dir, ignore_errors=True)
            sys.exit(1)
        
        try:
            subprocess.check_call(["cmp", "-s", render_out, queue_doc])
            emit(f"check: MARATHON-PLAN-{today}.md is in sync")
            shutil.rmtree(tmp_dir, ignore_errors=True)
            sys.exit(0)
        except subprocess.CalledProcessError:
            emit(f"check: drift detected in MARATHON-PLAN-{today}.md")
            subprocess.call(["diff", "-u", queue_doc, render_out], stdout=sys.stderr)
            shutil.rmtree(tmp_dir, ignore_errors=True)
            sys.exit(1)

    if run_mode == "dry-run":
        shutil.rmtree(tmp_dir, ignore_errors=True)
        sys.exit(rc)

    os.makedirs(queue_dir, exist_ok=True)
    shutil.copy2(render_out, queue_doc)
    
    rel_doc = os.path.relpath(queue_doc, root) if queue_doc.startswith(root) else queue_doc
    emit(f"wrote {rel_doc}")
    
    shutil.rmtree(tmp_dir, ignore_errors=True)
    sys.exit(rc)
