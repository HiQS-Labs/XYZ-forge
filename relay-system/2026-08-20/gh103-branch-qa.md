# RELAY · GH-103 branch QA (PR #104)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-20.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh103-branch-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh103-qa-brief.md** — the read-only path that
  `relay-drive.sh --artifact-file /tmp/claude/gh103-qa-brief.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-20
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) r1
swept file: yes

- **[Blocker] HTML injection via unescaped URLs in `href` attributes (DoD #4).** The `esc()` function is correctly defined, but URLs are injected directly into `href` attributes without it. If a database URL contains a double quote (`"`), it breaks the attribute and allows XSS.
  - `utils/timeline/RELEASES.html:483`: `' · <a href="'+c.links.issue+'">issue</a>'`
  - `utils/timeline/RELEASES.html:484`: `' · <a href="'+c.links.doc+'">doc</a>'`
  - `utils/timeline/RELEASES.html:504`: `href="'+m.url+'"`
  - `utils/timeline/RELEASES.html:520`: `href="'+rel.milestoneUrl+'"`
  - `utils/timeline/RELEASES.html:578`: `href="'+jf.issueUrl+'"`
  - `utils/timeline/RELEASES.html:590`: `href="'+wn.marathon.url+'"`
  - `utils/timeline/RELEASES.html:595`: `href="'+wn.issueUrl+'"`
  *Fix: Wrap all of these variables in `esc()`, e.g., `href="'+esc(c.links.issue)+'"`, since `esc()` correctly transforms `"` to `&quot;`.*

- **[Blocker] Staleness hazard from committed generated artifact (DoD #5).** The snapshot `RELEASES-PREVIEW.html` is committed to the repository, but unlike `ROADMAP-DASHBOARD.md`, there is no check wiring (e.g., in `validate.sh` or `ci-local.sh`) to ensure it gets regenerated and hasn't drifted from the DB.
  - `RELEASES-PREVIEW.html` addition in diff.
  *Fix: Either add `RELEASES-PREVIEW.html` to `.gitignore` so it's strictly a local artifact, or wire a staleness check in the gate suite that regenerates it and fails on `git diff --exit-code`, identical to the dashboard pattern.*

- **[Should] SQLite URI string interpolation hazard (DoD #1).** The `mode=ro` guarantee is correctly present, but interpolating a raw path into the `file:` URI is unsafe. If `args.db` contains a `?`, `#`, or URL-unsafe characters (like spaces), it corrupts the URI and SQLite will misinterpret or reject it.
  - `utils/timeline/export_timeline.py:1141`: `cx = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)`
  - `utils/timeline/export_timeline.py:1190`: `cx = sqlite3.connect(f"file:{args.db}?mode=ro", uri=True)`
  *Fix: Use `pathlib`'s `as_uri()` which correctly encodes the path: `sqlite3.connect(f"{args.db.resolve().as_uri()}?mode=ro", uri=True)`.*

- **[Nit] Band parsing fails on spaces around the hyphen (DoD #3).** The regex requires exactly `(\S+)-(\S+)`. If `RELEASES.md` contains spaces (e.g. `Iterations: 0.6.0 - 0.6.4`), `\S+` fails to match because it doesn't match spaces, leading to false drift reports.
  - `utils/timeline/export_timeline.py:1023`: `if m := re.match(r"^(\S+)-(\S+)$", block.get("iterations", ""))`
  *Fix: Accommodate spaces with `r"^\s*(\S+?)\s*-\s*(\S+?)\s*$"`.*

- **[Pass] Concurrency and path traversal for `/data.json` handler (DoD #2).** Verified. Path traversal is mitigated because `super().do_GET()` delegates to `SimpleHTTPRequestHandler` which uses `self.translate_path` to resolve against `directory` securely. Concurrency is safe because `ThreadingHTTPServer` spawns a thread per request, and `sqlite3.connect` is invoked locally inside `do_GET`, establishing thread-isolated DB connections.
  - `utils/timeline/export_timeline.py:1134-1141`
  - `utils/timeline/export_timeline.py:1153`

**Verdict:** Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
