---
name: idea
description: File an admission-ready GitHub issue from the repo you are standing in — recon-lite and the debug-mantra plan pivots run at filing time, so the issue body carries an Observed table, a plan that names the existing subsystem and writer, checkbox Acceptance with red controls, a PRS proposal, a Preflight Contract and a review footer, then lands through `hq park --create` (issue + 1-INBOX capture + ledger row) and `releases roadmap rate`. Trigger on /idea, "file an issue for this", "write this up as a GH issue", "capture this idea", "park this", or the legacy /file-issue. NOT for a bug in the xyz harness seen from another repo (that is /file-xyz-bug), and NOT for rewriting an existing issue (retrofit is a later phase: comment on that issue instead).
---

# /idea — admission-ready intake

An issue filed by hand enters the flywheel with no plan, no contract and no ledger row, and the
#1175 reconciler cannot admit it (Phase 0: 0 admissible of 281 open). This skill does the recon and
the plan while the context is fresh and files the result through the writers the repo already has.
It makes an issue **admission-ready**, never admitted: `ratings_provisional` stays set, no
`approved`/`reviewed` marker is ever written, and #522 keeps the admission decision.

Writers this skill calls, and nothing else: `hq park --create` (issue, capture doc, ledger row),
`releases roadmap rate` (the four axes), `gh issue comment` (the dispositions record). It writes no
code, no tests (AGENTS.md *No new tests*, GH-831), and never commits.

## Usage

```
/idea <one-line what and why>      # harvest → tier → recon-lite → body → check → consult → preview → ONE confirm → file
/idea                              # ask for the one-liner first
```

## Steps

0. **Locate HQ and resolve the target.** Use the hq skill's own locator (never a second locator,
   never a cached path), then resolve where intake will land: HQ resolves the project **by name**
   through its registry (`hq-lib.sh:245-263`), which need not be the checkout you are standing in
   (a task clone resolves to the registered primary).

   ```bash
   for L in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/2-daily/hq/find-hq.sh}" \
            "$HOME/.claude/skills/hq/find-hq.sh" \
            "$(git rev-parse --show-toplevel 2>/dev/null)/skills/2-daily/hq/find-hq.sh"; do
     [ -n "$L" ] && [ -x "$L" ] && break
   done
   [ -x "$L" ] || { echo "idea: hq locator not found — install the hq skill"; exit 1; }
   eval "$("$L" --env)" && "$L" --check                       # HQ_SH
   TARGET=$(bash "$HQ_SH" resolve <project> | sed -n 's/^REPO_PATH=//p')   # where park will write
   CALLER=$(git rev-parse --show-toplevel)
   [ "$TARGET" = "$CALLER" ] || echo "idea: intake lands in $TARGET, not in this checkout ($CALLER)"
   git -C "$TARGET" fetch origin development --quiet
   BASE=$(git -C "$TARGET" rev-parse --short origin/development)   # footer: base
   ```

   From here on **every write and read uses `$TARGET`**: the capture path, `releases_app.py --root
   "$TARGET"`, `gh` run with `-C "$TARGET"` or `--repo <slug>`, preflight `--target-root "$TARGET"`,
   and the final report. The recon in Step 4 is done in the caller; its `Recon: <sha>` must resolve
   in the target (`git -C "$TARGET" cat-file -e <sha>`), or redo the recon there. These exports do
   not survive to the next Bash call (see `file-xyz-bug` Step 0); re-resolve in each command that
   needs them.

1. **Harvest first, ask second.** Reconstruct from this session before asking anything: the
   `file-xyz-bug` Step 1 table (what broke / exact command / observed / where / version) applies
   unchanged, with "expected behaviour", "reproducibility" and "blocking?" as the only questions
   worth asking, capped at three. Redact per `file-xyz-bug` Step 2: the body is public.

2. **Tier, with the reason printed.** Three tiers, decided here and never silently changed:
   - `trivial` = the repo's issue-first exemption (ROUTER.md: a 2–3 line fix, a typo, a path
     repoint, a doc one-liner), obvious, local, reversible, no design decision and no uncertain
     behaviour change. A short diff alone does not qualify (`start-task` Step 5): a 6-line change
     across three files with a design choice is `standard`. **Trivial files nothing.** Print
     `idea: issue-first exemption (<reason>); nothing filed — commit the fix directly` and stop here.
   - `spike` = a question or investigation, not a change: the body omits `## Preflight Contract`
     (there is no fix to probe), Steps 5–9 run, Step 10 is replaced by the `NEEDS-SPIKE` report.
   - `standard` = everything else: all steps.

3. **Prior art.** `python3 utils/py/prior_art_recon.py --query "<seam>"`. An `existing_fix_candidates`
   hit stops the skill: confirm with the operator whether the ask is already fixed. A matching open
   issue means no new issue: say which one and stop (retrofitting it is Phase 3 of #1258, not this skill).

4. **Recon-lite.** Run the recon skill's Steps 1–3 sized to the radius (one seam for a small fix,
   the full map for a feature): entry points, call paths, every write of the state involved, the
   contracts crossed, failure and rollback paths. Pin it to `Recon: <sha>` = `git rev-parse --short HEAD`.
   Then apply `/debug-mantra plan` to the acceptance items: each must fail on the current tree, reject
   an empty input, and name its red control.

5. **Render the body** to a local file, exactly these headings in this order (the reconciler and the
   preflight read them by name), then **run the check below and refuse to continue on exit 1**:

   ```
   ## Observed            measured table (claim · command · observed) with receipts
   ## Root cause          or "Diagnosis / existing gap" for a feature: origin, fix site, removes-the-class or one-instance
   ## Plan                ordered steps, each naming the existing subsystem and writer it extends
   ## Blast radius        seams table pinned to Recon <sha>; integration base development@<sha> stated separately;
                          truthful write-set incl. docs/helpers; builder/reviewer route
   ## Dependencies
   ## Acceptance          `- [ ]` items ONLY (swarm_preflight.py's extractor reads nothing else); each names its red control
   ## Verification        existing suite or manual check under TESTS-RESULTS/<date>+GH-<n>/ (no new tests)
   ## Non-goals
   ## Risk and rollback
   ## PRS proposal        four lines `- pri N: …`, `- sev N: …`, `- appeal N: …`, `- effort N: …`, 1–100, one
                          issue-specific rationale each; appeal 50 unless the operator set it; effort scores CHEAPNESS
   ## Preflight Contract  JSON: target.repo, target.ref "development", gate, fix_probes (≥1, each UNFIXED at target.ref:
                          grep_absent/path_absent/grep_present/path_present/command), artifacts (≥1); every new file in
                          BOTH artifacts and artifacts_new with a path_absent probe (swarm_preflight.py:1366-1373). Omitted for spike.
   Recon: <sha> · base: development@<sha> · tier: <standard|spike> · review: pending
   ```

   The footer is one line and is the last line of the body. The review hash (Step 6) covers every
   byte above it, so writing the hash into it changes nothing that was hashed.

   The check (the skill's own refusal; it is not a test file, it runs on the draft in hand):

   ```bash
   python3 - body.md <<'PY'
   import json, re, sys
   s = open(sys.argv[1], encoding="utf-8").read()
   tier = (re.search(r"· tier: (standard|spike)", s) or sys.exit("refuse: footer tier missing")).group(1)
   heads = ["Observed", "Root cause|Diagnosis / existing gap", "Plan", "Blast radius", "Dependencies", "Acceptance",
            "Verification", "Non-goals", "Risk and rollback", "PRS proposal"] + ([] if tier == "spike" else ["Preflight Contract"])
   parts = re.split(r"^## (.+)$", s, flags=re.M); body = dict(zip(parts[1::2], parts[2::2]))
   for h in heads:
       k = next((x for x in body if re.match(rf"(?:{h})(\s|\(|$)", x)), None)   # heading may carry a suffix like "(date, sha)"
       if not k: sys.exit(f"refuse: missing heading ## {h}")
       if not body[k].strip(): sys.exit(f"refuse: empty section ## {k}")
   acc = [l for l in body["Acceptance"].splitlines() if l.strip()]
   if not acc or any(not re.match(r"- \[[ x]\] \S", l) for l in acc): sys.exit("refuse: Acceptance must be `- [ ]` items only, at least one")
   prs = {m.group(1): (int(m.group(2)), m.group(3)) for m in re.finditer(r"^- (pri|sev|appeal|effort) (\d{1,3}): (.*)$", body["PRS proposal"], re.M)}
   if set(prs) != {"pri", "sev", "appeal", "effort"}: sys.exit("refuse: PRS proposal needs the four axis lines")
   if any(not 1 <= v <= 100 for v, _ in prs.values()) or all(v <= 5 for v, _ in prs.values()): sys.exit("refuse: axes are 1–100, not a 1–5 scale")
   if any(len(r.strip()) < 25 or "TODO" in r or "rationale" in r.lower() for _, r in prs.values()): sys.exit("refuse: each axis needs an issue-specific rationale line")
   if tier != "spike":
       m = re.search(r"```json\s*(\{.*?\})\s*```", body["Preflight Contract"], re.S) or sys.exit("refuse: contract JSON missing")
       c = json.loads(m.group(1))
       if c.get("target", {}).get("ref") != "development" or not c.get("gate") or not c.get("fix_probes") or not c.get("artifacts"): sys.exit("refuse: contract needs target.ref development, gate, fix_probes, artifacts")
   if not re.search(r"^Recon: [0-9a-f]{7,} · base: development@[0-9a-f]{7,} · tier: ", s, re.M): sys.exit("refuse: footer needs Recon: <sha> · base: development@<sha>")
   print("body check: ok", tier)
   PY
   ```

6. **Consult (standard and spike).** Load the consult skill and fan the rendered body out with the
   start-task Step 6 questions (claims grounded in the cited paths? requirement missing? extends
   the existing subsystem and writer? blast radius, ordering, rollback and falsifiable checks
   sufficient? ratings grounded, appeal neutral?). Adjudicate every finding against the tree, revise
   the body, re-run the Step 5 check, keep the dispositions for Step 9. Then compute the hash and
   finish the footer:

   ```bash
   HASH=$(sed '$d' body.md | shasum -a 256 | cut -c1-64)   # everything above the footer line
   # footer: review: consult <run-id> models=<codex,agy | codex, degraded | agy, degraded> hash $HASH
   ```

   `models=` names the seats that answered; `consult.sh` exits 0 on a single answer, so a degraded
   run must be legible from the issue alone. This is a **draft review** for #522's reviewer, not the
   review: it never writes `approved`, and `start-task` Step 6 still runs when the work is picked up.

7. **Preview, one confirmation.** Export the judgment fields from the recon and preview (hq previews
   by default):

   ```bash
   HQ_PARK_WHY="<one paragraph>" HQ_PARK_KEY_CONCEPTS="a|b|c" HQ_PARK_NON_GOALS="x|y" \
   HQ_PARK_RELATED="#n|#m" HQ_PARK_COMPLEXITY=<1-5> HQ_PARK_RISK=<1-5> HQ_PARK_EFFORT=<1-5> HQ_PARK_PHASES=<n> \
   bash "$HQ_SH" park --title "<one line, no rating token>" <project> "$(cat body.md)"
   ```

   The title must not match `parse_rating`'s token-presence rule, lowercase `rated` or `ovr`
   followed by whitespace and a digit (`releases_app.py:3299,3317`), in any form: `rated 80/55/50/65`,
   `rated 5/5`, `rated 70`, `ovr 200`. `hq_roadmap_line` interpolates the title into the ledger
   line and `parse_rating` reads the whole line, so a complete token pre-rates the row and makes
   Step 8's `roadmap rate` refuse, and a malformed one aborts `roadmap add` **after** the issue and
   capture exist. Check it before previewing:

   ```bash
   printf '%s' "$TITLE" | grep -Eiq '(^|[^[:alnum:]_])(rated|ovr)[[:space:]]+[0-9]' && { echo "refuse: rating token in title"; exit 1; }
   ```

   Score examples belong in the body. Show the operator the title, the body, the capture-doc path
   and the ledger line together, and get **one** confirmation. `hq park` refuses a title that
   matches an open issue (`hq.sh:306`); that is the dedupe, do not work around it.

8. **File, rate, read back.** Run un-sandboxed (`gh` needs the keychain):

   ```bash
   … bash "$HQ_SH" park --create --title "<title>" <project> "$(cat body.md)"     # prints "✓ issue: <url>"; N is its trailing number
   python3 utils/py/releases_app.py --root "$TARGET" roadmap rate --issue-num N --rated P/S/A/E --dry-run
   python3 utils/py/releases_app.py --root "$TARGET" roadmap rate --issue-num N --rated P/S/A/E
   python3 utils/py/releases_app.py --root "$TARGET" roadmap list --json | python3 -c 'import json,sys;print([r for r in json.load(sys.stdin) if r.get("gh_number")==N])'
   ```

   `hq park` drops the rating (`hq_roadmap_line` carries no `rated` token), so `roadmap rate` is the
   writer. Never pass `--force`: a second `roadmap rate` on the same row refuses (`already-rated`,
   exit 3) and that refusal is correct. Never clear `ratings_provisional` in the doc. The capture
   doc embeds the body verbatim under `## Idea`, so the Acceptance checkboxes and the Preflight
   Contract reach the doc with no HQ change.

9. **Post the dispositions:** `gh -C "$TARGET" issue comment N --body-file dispositions.md` with
   the consult run dir, each finding and its disposition, and the hash from Step 6.

10. **Preflight the capture, refuse on any nonzero.** Spike tier: print
    `NEEDS-SPIKE: issue <url>, doc <path>, row <gid>; no contract by design, not a build candidate`
    and skip to Step 11. Otherwise:

    ```bash
    bash utils/swarm-preflight.sh --project-doc "$TARGET/PROJECT/1-INBOX/GH-N-<SLUG>.md" --target-root "$TARGET" --dry-run; echo "exit=$?"
    ```

    `--project-doc` reads the fresh local capture directly (`--gh-issue` searches only `2-WORKING`);
    the uncommitted capture and ledger are fine: dirty state is recorded, not a verdict condition
    (`swarm_preflight.py:1312-1316,1640-1645`). `--dry-run` publishes nothing but **does** fetch and
    create/remove a detached worktree in the target. Exit 0 is READY. Anything else is reported by
    name, never as success: 3 contract missing/invalid, 4 STALE (a probe already satisfied at
    `target.ref`: either a wrong probe or already-delivered work; say which you found), 5 NOT-READY
    (an artifact missing at `target.ref` and absent from `artifacts_new`), 6 BLOCKED, 7 AMBIGUOUS.
    By now the issue, the capture doc and the ledger row already exist (Step 8 ran first), so the
    report is exactly:

    ```
    filed, not admission-ready: issue <url> · doc <path> · row <gid> · verdict <NAME> (exit <n>): <reason line from the log>
    ```

    Nothing is rolled back and nothing is admitted. Fix the body and the doc together, or leave it
    for the operator. The skill never invents a replacement probe to turn a verdict green.

11. **Report** in five lines: the issue URL; the capture-doc path under `$TARGET` and the ledger row
    id; the rating as read back; the preflight exit and verdict (or `NEEDS-SPIKE`); and that the
    capture, `releases.db` and `releases.sql` are **uncommitted in `$TARGET`** on its current branch,
    so the operator knows the one action left is theirs.

## Guardrails

- The only writers are `hq park --create`, `releases roadmap rate` and `gh issue comment`. No file
  under `utils/`, no new flag, no new script, no test, no commit, no push.
- Never write `approved`, `reviewed` or any admission marker. Never clear `ratings_provisional`.
- Never retrofit an existing issue's body. Never file when prior art names an open match.
- Trivial tier files nothing; spike tier files without a contract and reports `NEEDS-SPIKE`.
- A rating is four 1–100 integers with one rationale line each; never 1–5 values, never a template default.
- A `swarm-preflight` verdict other than READY is reported as what it is. Success is exit 0 only.
