#!/usr/bin/env python3
"""Bake the GitHub Pages site's data-driven pages under PAGES/.

Two artifacts, both regenerated from committed ledgers so the site never hand-edits
data that the repo already owns:

  PAGES/roadmap.html          <- `releases_app.py --root <root> roadmap list --json`
                                 (the same JSON seam ROADMAP-DASHBOARD.md renders from)
  PAGES/models-harnesses.html <- harnesses.db (read-only; falls back to loading the
                                 committed harnesses.sql dump into :memory:)

The remaining PAGES/ pages are handwritten static HTML; this builder only owns the
data-driven two. The deploy workflow (.github/workflows/pages.yml) reruns this on
every deploy, so the committed copies are a convenience snapshot, not the source of
truth — which is why --check reports drift informationally rather than being wired
into any gate.

Empty-input rule (AGENTS.md "an empty input passes every check"): a failed query or
a JSON parse yielding zero rows exits 2 with a loud message instead of baking an
empty page that looks successful.
"""

import argparse
import datetime
import html
import json
import os
import re
import sqlite3
import subprocess
import sys

REPO_URL = "https://github.com/HiQS-Labs/XYZ-forge"
SITE_URL = "https://hiqs-labs.github.io/XYZ-forge"

NAV = [
    ("index.html", "Welcome"),
    ("use-cases.html", "Use Cases"),
    ("how-it-works.html", "How it Works"),
    ("faq.html", "FAQ"),
    ("models-harnesses.html", "Models &amp; Harnesses"),
    ("roadmap.html", "Roadmap"),
    ("issues.html", "Issues"),
    ("contact.html", "Contact"),
]

# Display order for roadmap sections; anything unknown sorts after these, alphabetically.
SECTION_ORDER = [
    "In progress",
    "Queue",
    "Queue / parked intake",
    "Deferred · vision",
    "Completed",
]

FAVICON = (
    "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E"
    "%3Ctext y='13' font-size='13'%3E%E2%9A%99%EF%B8%8F%3C/text%3E%3C/svg%3E"
)


def e(value):
    """html.escape for everything that came out of a database or subprocess."""
    return html.escape(str(value), quote=True)


def fail(msg):
    sys.stderr.write("site_build: FAIL: %s\n" % msg)
    sys.exit(2)


# ---------------------------------------------------------------- data loading


def load_roadmap(root):
    """Roadmap rows via the documented releases_app JSON seam."""
    app = os.path.join(root, "utils", "py", "releases_app.py")
    if not os.path.isfile(app):
        fail("releases_app.py not found at %s" % app)
    proc = subprocess.run(
        [sys.executable, app, "--root", root, "roadmap", "list", "--json"],
        capture_output=True, text=True,
    )
    if proc.returncode != 0:
        fail("releases_app roadmap list --json exited %d: %s"
             % (proc.returncode, proc.stderr.strip()[:500]))
    try:
        rows = json.loads(proc.stdout)
    except ValueError as exc:
        fail("roadmap list --json stdout is not JSON (%s); first 200 bytes: %r"
             % (exc, proc.stdout[:200]))
    if not isinstance(rows, list) or not rows:
        fail("roadmap list --json returned %s rows — refusing to bake an empty roadmap page"
             % ("0" if isinstance(rows, list) else "non-list"))
    required = ("title", "section", "position", "status_marker", "issue_url", "gh_number")
    for row in rows:
        missing = [k for k in required if k not in row]
        if missing:
            fail("roadmap row missing keys %s: %r" % (missing, row))
    return rows


def _connect_harnesses(root):
    """Read-only connection to harnesses.db, or :memory: rebuilt from the SQL dump."""
    db_path = os.environ.get("XYZ_HARNESS_DB", os.path.join(root, "harnesses.db"))
    if os.path.isfile(db_path):
        return sqlite3.connect("file:%s?mode=ro" % db_path, uri=True), db_path
    sql_path = os.environ.get("XYZ_HARNESS_SQL", os.path.join(root, "harnesses.sql"))
    if os.path.isfile(sql_path):
        con = sqlite3.connect(":memory:")
        con.executescript(open(sql_path, encoding="utf-8").read())
        return con, sql_path + " (loaded into :memory:)"
    fail("neither %s nor %s exists — no harness data to bake" % (db_path, sql_path))


def load_harness_data(root):
    con, source = _connect_harnesses(root)
    try:
        cur = con.cursor()
        try:
            harnesses = cur.execute(
                "SELECT harness_id, name, execution_engine, supports_reasoning_effort,"
                " standing_policy_role FROM harnesses ORDER BY harness_id"
            ).fetchall()
            models = cur.execute(
                "SELECT model_id, lab, canonical_name, gateway, context_window, is_deprecated"
                " FROM models ORDER BY lab, canonical_name"
            ).fetchall()
            evals = cur.execute(
                "SELECT h.harness_id, m.canonical_name, e.grade, e.qualifying_gate_passed,"
                " e.diff_cleanliness_score, e.seam_reliability_score, e.failure_mode_tag,"
                " COUNT(*)"
                " FROM evaluations e"
                " JOIN invocation_logs i ON e.invocation_id = i.invocation_id"
                " JOIN harnesses h ON i.harness_id = h.harness_id"
                " JOIN models m ON i.model_id = m.model_id"
                " GROUP BY h.harness_id, m.canonical_name, e.grade, e.qualifying_gate_passed,"
                " e.diff_cleanliness_score, e.seam_reliability_score, e.failure_mode_tag"
                " ORDER BY h.harness_id, m.canonical_name"
            ).fetchall()
        except sqlite3.Error as exc:
            fail("cannot read harness data from %s (%s) — is it a harnesses registry?"
                 % (source, exc))
    finally:
        con.close()
    if not harnesses:
        fail("harnesses table returned 0 rows from %s" % source)
    if not models:
        fail("models table returned 0 rows from %s" % source)
    if not evals:
        fail("evaluations join returned 0 rows from %s — refusing to bake an empty grades table"
             % source)
    return harnesses, models, evals, source


# ---------------------------------------------------------------- rendering


def render_page(title, description, active, body, gen_source=None):
    nav = "\n".join(
        '      <a href="%s"%s>%s</a>' % (
            href, ' aria-current="page"' if href == active else "", label)
        for href, label in NAV
    )
    gen_comment = ""
    gen_note = ""
    if gen_source:
        stamp = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
        gen_comment = "<!-- gen-time: %s -->\n" % stamp
        gen_note = ('<p class="gen-note">Generated by '
                    '<a href="%s/blob/development/utils/py/site_build.py">utils/py/site_build.py</a> '
                    'from %s. Regenerated on every deploy; not hand-edited.</p>\n'
                    % (REPO_URL, gen_source))
    return """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>%(title)s — XYZ Forge</title>
<meta name="description" content="%(desc)s">
<link rel="canonical" href="%(canonical)s">
<link rel="stylesheet" href="assets/style.css">
<link rel="icon" href="%(favicon)s">
%(gen_comment)s</head>
<body>
<header class="site-head">
  <div class="wrap">
    <a class="brand" href="index.html">XYZ Forge</a>
    <nav aria-label="Site">
%(nav)s
    </nav>
  </div>
</header>

<main>
  <div class="wrap">
%(body)s
  </div>
</main>

<footer class="site-foot">
  <div class="wrap">
    <span>XYZ Forge — multi-agent coordination. Provided “AS IS,” without warranty.</span>
    <span>
      <a href="%(repo)s">GitHub</a> ·
      <a href="issues.html">Issues</a> ·
      <a href="%(repo)s/blob/development/LICENSE">License</a>
    </span>
  </div>
</footer>
</body>
</html>
""" % {
        "title": e(title), "desc": e(description), "canonical": e(SITE_URL + "/" + active),
        "favicon": FAVICON, "gen_comment": gen_comment, "nav": nav, "body": body,
        "repo": REPO_URL,
    }


def _ctx_human(n):
    if not n:
        return "—"
    if n >= 1000000 and n % 1000000 == 0:
        return "%dM" % (n // 1000000)
    if n >= 1000 and n % 1000 == 0:
        return "%dK" % (n // 1000)
    return "{:,}".format(n)


def _grade_badge(grade):
    cls = "ok" if str(grade).startswith("A") else ("warn" if str(grade) in ("C", "N/A") else "")
    return '<span class="badge %s">%s</span>' % (cls, e(grade))


def render_roadmap(rows):
    sections = {}
    for row in rows:
        sections.setdefault(row["section"], []).append(row)
    for items in sections.values():
        items.sort(key=lambda r: (r["position"] is None, r["position"] or 0))

    def section_key(name):
        try:
            return (0, SECTION_ORDER.index(name), name)
        except ValueError:
            return (1, 0, name)

    parts = []
    parts.append("<h1>Roadmap</h1>")
    parts.append('<p class="page-intro">Live from the repository\'s committed releases ledger '
                 '(<code>releases.db</code>) — the same source of truth the repo\'s own dashboard '
                 'renders. Status markers: ✅ done · 🚧 in progress · ⏸ paused. Each entry links '
                 'to its GitHub issue.</p>')
    if sections.get("In progress"):
        active_count = len(sections["In progress"])
        parts.append('<div class="note"><strong>%d item%s in progress.</strong> The current '
                     'long-horizon focus is named in the repo\'s roadmap dashboard.</div>'
                     % (active_count, "s are" if active_count != 1 else " is"))

    for name in sorted(sections, key=section_key):
        items = sections[name]
        heading = ('<div class="rm-section">\n<h2>%s <span class="rm-count">%d item%s</span></h2>'
                   % (e(name), len(items), "" if len(items) == 1 else "s"))
        body = ["<ul class=\"rm-items\">"]
        for row in items:
            marker = e(row["status_marker"]) or "•"
            title = e(row["title"])
            gh = row["gh_number"]
            url = row["issue_url"]
            if url:
                title = '<a href="%s">%s</a>' % (e(url), title)
                gh_html = '<span class="gh"><a href="%s">#%s</a></span>' % (e(url), e(gh))
            elif gh:
                gh_html = '<span class="gh">#%s</span>' % e(gh)
            else:
                gh_html = ""
            body.append('<li><span class="marker">%s</span>'
                        '<span class="title">%s</span>%s</li>' % (marker, title, gh_html))
        body.append("</ul>")
        block = "\n".join(body)
        if name == "Completed":
            parts.append(heading)
            parts.append('<details class="rm-collapse"><summary>Show %d completed items</summary>'
                         '\n%s\n</details>\n</div>' % (len(items), block))
        else:
            parts.append(heading + "\n" + block + "\n</div>")
    return "\n".join(parts)


def render_models(harnesses, models, evals):
    parts = []
    parts.append("<h1>Models &amp; Harnesses Tested</h1>")
    parts.append('<p class="page-intro">Every harness and model XYZ has been evaluated with, '
                 'from the committed harnesses registry. Full narratives live in the repo\'s '
                 '<a href="%s/blob/development/HARNESS-MODELS-REGISTRY.md">HARNESS-MODELS-REGISTRY.md</a>; '
                 'benchmark artifacts in <a href="%s/tree/development/TESTS-RESULTS">TESTS-RESULTS/</a>.</p>'
                 % (REPO_URL, REPO_URL))

    parts.append("<h2>Evaluated pairs — grades</h2>")
    parts.append('<div class="table-wrap"><table>\n<thead><tr><th>Harness</th><th>Model</th>'
                 '<th>Grade</th><th>Gate</th><th>Diff cleanliness /5</th>'
                 '<th>Seam reliability /5</th><th>Failure mode</th><th>Evals</th></tr></thead>\n<tbody>')
    for hid, model, grade, gate, clean, seam, failtag, count in evals:
        gate_html = "✓ passed" if gate else '<span class="badge warn">not passed</span>'
        parts.append("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>"
                     "<td>%s</td><td>%s</td></tr>"
                     % (e(hid), e(model), _grade_badge(grade), gate_html,
                        e(clean if clean is not None else "—"),
                        e(seam if seam is not None else "—"),
                        e(failtag or "—"), e(count)))
    parts.append("</tbody>\n</table>\n</div>")
    parts.append('<p>Grades come from the evaluations ledger: A-range means the pairing is '
                 'production-usable as driven; B-range usable with caveats; C or N/A means not '
                 'recommended for that pairing. “Evals” counts the individual verified '
                 'invocations behind each row.</p>')

    parts.append("<h2>Harnesses</h2>")
    parts.append('<div class="table-wrap"><table>\n<thead><tr><th>ID</th><th>Name</th>'
                 '<th>Engine</th><th>Reasoning effort</th><th>Standing role</th></tr></thead>\n<tbody>')
    for hid, name, engine, reasoning, role in harnesses:
        parts.append("<tr><td><code>%s</code></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>"
                     % (e(hid), e(name), e(engine), "yes" if reasoning else "no", e(role)))
    parts.append("</tbody>\n</table>\n</div>")

    parts.append("<h2>Models</h2>")
    parts.append('<div class="table-wrap"><table>\n<thead><tr><th>Model</th><th>Lab</th>'
                 '<th>Gateway</th><th>Context</th><th>Status</th></tr></thead>\n<tbody>')
    for mid, lab, cname, gateway, ctx, deprecated in models:
        status = ('<span class="badge warn">deprecated</span>' if deprecated
                  else '<span class="badge ok">active</span>')
        parts.append("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>"
                     % (e(cname or mid), e(lab), e(gateway), _ctx_human(ctx), status))
    parts.append("</tbody>\n</table>\n</div>")
    return "\n".join(parts)


# ---------------------------------------------------------------- write / check

GEN_TIME_RE = re.compile(r"<!-- gen-time: [^>]*-->")


def normalized(text):
    return GEN_TIME_RE.sub("<!-- gen-time: NORMALIZED -->", text)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    default_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("--root", default=default_root, help="repo root (default: inferred)")
    ap.add_argument("--pages-dir", default=None, help="site dir (default: <root>/PAGES)")
    ap.add_argument("--check", action="store_true",
                    help="compare on-disk generated pages against a fresh bake; exit 1 on drift")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    pages = os.path.abspath(args.pages_dir) if args.pages_dir else os.path.join(root, "PAGES")

    roadmap_rows = load_roadmap(root)
    harnesses, models, evals, harness_source = load_harness_data(root)

    artifacts = {
        "roadmap.html": render_page(
            "Roadmap", "The XYZ Forge roadmap, generated from the committed releases ledger.",
            "roadmap.html", render_roadmap(roadmap_rows),
            gen_source="the committed releases ledger (<code>releases.db</code>)",
        ),
        "models-harnesses.html": render_page(
            "Models & Harnesses", "Harnesses and models XYZ has been evaluated with, with grades "
            "from the committed evaluations ledger.",
            "models-harnesses.html", render_models(harnesses, models, evals),
            gen_source="the committed harnesses registry (<code>%s</code>)" % e(harness_source),
        ),
    }

    drift = []
    for name, content in sorted(artifacts.items()):
        path = os.path.join(pages, name)
        if args.check:
            if not os.path.isfile(path):
                drift.append("%s: MISSING" % name)
            elif normalized(open(path, encoding="utf-8").read()) != normalized(content):
                drift.append("%s: STALE" % name)
            continue
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(content)
        print("site_build: wrote %s (%d bytes)" % (path, len(content)))
    print("site_build: roadmap items=%d sections=%d | harnesses=%d models=%d graded-pairs=%d"
          % (len(roadmap_rows), len({r["section"] for r in roadmap_rows}),
             len(harnesses), len(models), len(evals)))

    if args.check:
        if drift:
            for line in drift:
                sys.stderr.write("site_build: DRIFT %s\n" % line)
            sys.stderr.write("site_build: rerun `python3 utils/py/site_build.py` and commit the "
                             "refreshed pages (the deploy workflow also regenerates them).\n")
            sys.exit(1)
        print("site_build: check CLEAN (roadmap.html, models-harnesses.html up to date)")


if __name__ == "__main__":
    main()
