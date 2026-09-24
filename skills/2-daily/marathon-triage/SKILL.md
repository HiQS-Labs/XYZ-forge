---
name: marathon-triage
description: >
  Triage PDDA intake and active work into a ranked, preflight-checked, collision-safe marathon
  candidate list — end to end, unattended. Reconcile GH capture docs with live issue state, write
  the capture docs that are missing, run the planner dry run and per-candidate preflight, and group
  disjoint write-sets into safe waves. Use when asked to triage the inbox, build or refresh a
  marathon queue, choose work to swarm next, identify concurrent issues, or plan a marathon without
  executing it. Requires this repo's PROJECT lifecycle, the RELEASES DB roadmap ledger, and
  swarm-preflight.sh / marathon-plan.sh resolved from the harness root (bare repo root or a vendored
  `.xyz/` install — see Step 0). Never fires the marathon.
---

# Marathon triage

Produce an honest, ranked marathon plan without firing work. Treat `PROJECT/**` as the execution
record, GitHub as the live signal stream, and deterministic preflight output as stronger than prose.

---

## Recite this — verbatim, as the first thing in your first response

> **Marathon-Triage Discipline:**
> 1. **Resolve the harness and arm the guard (Step 0).** Run the locator block first — it exports `$HARNESS` and is the relay-xyz guard's proof-of-load; with the guard enabled and no prior proof-of-load, planner/preflight calls are cancelled with exit 2.
> 2. **Inventory and reconcile (Steps 1–2).** List every open issue and every `GH-*.md` capture; give each exactly one classification from live GitHub state, never from stale local text.
> 3. **Capture the intake that is missing (Step 3).** For each in-scope open issue with no capture doc, render it with the existing writer and park its ledger row; list what was written.
> 4. **Compute, don't ask (Steps 4–5).** Run `marathon_plan.py --dry-run --deep` and `swarm-preflight.sh --dry-run` per candidate — ordinary readiness computation, inside the default (it refreshes remote-tracking refs and uses a transient worktree; it publishes no packet, plan file or doc); record every exit code and verdict from direct calls, and classify non-zero codes instead of stopping.
> 5. **Report with decisions (Step 6).** A complete report — or an explicit blocked report naming what could not be established — with the classification table, ranked candidates and exact verdicts, collision map and waves, and one `RECOMMEND / BECAUSE / UNLESS` per open call. Promotion, closing, firing, branch cutting and writing the plan file stay behind operator confirmation; the umbrella issue and full clone are prerequisites for *firing*, not for triage.
>
> **Overall Goal:** An operator who types `/marathon-triage` gets the complete computation — captures written, planner and preflight run, decisions framed — without walking the agent through any step.

Then begin work.

---

## Guardrails

- Read `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, the RELEASES DB (`releases roadmap list`), and `PROJECT/PDDA.md` first.
- **The default includes ordinary readiness computation.** `marathon_plan.py --dry-run --deep`
  publishes no plan file (`--dry-run` prints the report only; `--deep` delegates to
  `swarm-preflight.sh --dry-run` per ready item) and `swarm-preflight.sh --dry-run` publishes no
  packet — but neither is side-effect-free: preflight runs `git fetch --prune` on the target and adds
  then removes a detached temporary worktree at `target.ref` (`utils/py/swarm_preflight.py`
  `:1297`, `:1355-1361`, `:1378-1380`) before its dry-run exit. That is Git metadata and a transient
  worktree, not a published artifact. Run them; do not ask whether to. If the operator explicitly
  asks for a *strictly read-only audit*, that override covers the metadata effects too: skip Step 3's
  writes and report the captures you would have written, and either obtain readiness evidence from an
  authorised disposable clone or report it as **unavailable** — a skipped preflight is not a verdict.
- **Writing a `1-INBOX` capture doc and parking its ledger row through the writer is intake, not
  execution.** It is reversible, repo-local and part of this skill's default; the *commit* is listed
  as an operator decision in the report.
- **The umbrella issue and the derived full clone are prerequisites for firing a selected marathon
  (Step 7), not for triage.** Inventory, capture, the planner dry run, preflight and the report all
  run without an umbrella; creating or linking one is a decision the report proposes.
- **Confirmation is reserved for exactly five actions:** promote a capture to `2-WORKING`, close an
  issue, fire a marathon, cut a branch, or write the plan file (the planner *without* `--dry-run`).
  Nothing else in this skill waits on the operator.
- Never override a deterministic PDDA or preflight finding with narrative judgment.
- Use the repo's standing target branch policy. Do not invent a branch or silently substitute a
  builder.
- If GitHub is unavailable, mark live-state evidence `UNKNOWN`; do not infer it from stale local text.

---

## Drive loop — how an agent runs this skill end to end

Follow the steps in order; each has an exit contract and a next action. **Do not stop at the first
non-zero exit — classify it.** Every run ends in one of two report shapes (Step 6): a **complete
report**, or a **blocked report** that names the command, its exit code, the evidence that could not
be established and the next action. Asking the operator whether to run a step is neither.

| Step | Command / action | Exit → action |
|---|---|---|
| 0 | locator block below | locator not found → **blocked report** (install the skill or set `XYZ_HARNESS`); else continue |
| 1 | `gh issue list` + `find PROJECT/1-INBOX PROJECT/2-WORKING` | `gh` failure → live state `UNKNOWN`, continue with local docs |
| 2 | one classification per issue and per doc | — |
| 3 | render + park each missing capture | writer refusal → record it per issue, continue |
| 4 | `python3 "$HARNESS/utils/py/marathon_plan.py" --dry-run --deep` | `0` clean → continue · `2` usage → fix the invocation, one retry · `3` ledger unparseable → **blocked report** naming the ledger error · `4` drift → record per item, continue · `5` items held → record the held set, continue · `6` `gh` required-but-absent → one re-run without `--require-gh`, mark live state `UNKNOWN` · any other code → unknown, never success; blocked report |
| 5 | `swarm-preflight.sh --dry-run` per candidate — **direct calls, even for items `--deep` covered** (deep delegation discards preflight output and handles only 4/5/6/7, so planner success is not a candidate's verdict) | `0` READY · `2` usage → fix, one retry · `3` NEEDS-CONTRACT · `4` CONTRACT-STALE · `5` BLOCKED (not ready) · `6` BLOCKED (target) · `7` BLOCKED (ambiguous) — every code is a classification, none is a stop |
| 6 | report | the **Done rule** below decides whether it may claim *completion*; otherwise it is a blocked report |
| 7 | before firing (operator-confirmed only) | umbrella issue + `marathon add` + derived full clone — see "Before firing" |

**Done rule:** do not claim a *complete* triage until all four hold — (a) every open issue and every
`GH-*.md` doc in `1-INBOX`/`2-WORKING` has exactly one classification; (b) every `READY` /
`NEEDS-PROMOTE` / `CONTRACT-STALE` candidate has a recorded preflight exit code and verdict from a
direct call; (c) the planner dry-run output is quoted (waves, held items, drift lines); (d) every
capture written in Step 3 is listed with its ledger gid, and any failed ledger add is listed as
*intake half-complete*. When one of these cannot be met — planner exit `3`, `gh` unavailable, a writer
refusal — emit a **blocked report** instead: the command, its exit, what is missing, the next action;
no fabricated waves, no retry beyond the one bounded retry above. "Asked the operator whether to
preflight / run the planner / write the captures" is neither shape — it is Step 4, 5 or 3 left undone.

**Permission-classifier blocks:** if a harness permission layer cancels a planner or preflight call,
first check that Step 0 actually ran in this session (the `relay-xyz guard — STOP` message means it
did not); then retry the identical command once before escalating.

---

## Workflow

### 0. Resolve the harness root — this is also the guard's proof-of-load

**Run this block as the first Bash call of the session.** Besides exporting `$HARNESS`, a Bash call
that runs `find-harness.sh` is what the relay-xyz guard hook
(`relay-automation/hooks/relay-xyz-guard.sh`) accepts as proof the skill stack is loaded.
`marathon-plan` and `swarm-preflight` are Tier-A entrypoints (Bash shims and Python twins alike).
With the guard enabled and no prior proof-of-load in this session, calls to them are blocked with
exit 2 and the message `relay-xyz guard — STOP` (the hook is fail-open and session-scoped; a session
that already loaded `relay-xyz` is not blocked). The remedy is to run this block, not to ask the
operator.

```bash
L=""
for candidate in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/1-hourly/relay-xyz/find-harness.sh}" \
                 "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
                 "$HOME/.codex/skills/relay-xyz/find-harness.sh" \
                 "$HOME/.gemini/config/skills/relay-xyz/find-harness.sh" \
                 "$HOME/.gemini/antigravity/skills/relay-xyz/find-harness.sh" \
                 "$HOME/.gemini/antigravity-cli/skills/relay-xyz/find-harness.sh" \
                 "$(git rev-parse --show-toplevel 2>/dev/null)/.claude/skills/relay-xyz/find-harness.sh" \
                 "$(git rev-parse --show-toplevel 2>/dev/null)/skills/1-hourly/relay-xyz/find-harness.sh"; do
  [ -n "$candidate" ] && [ -f "$candidate" ] && { L="$candidate"; break; }
done
[ -n "$L" ] || { echo "relay-xyz: locator not found — install the skill or set XYZ_HARNESS" >&2; exit 1; }
eval "$("$L" --env)"
```

Reference every script below as `$HARNESS/utils/swarm-preflight.sh`,
`$HARNESS/utils/py/marathon_plan.py` and `$HARNESS/utils/hq/hq-lib.sh` — not bare `utils/...` paths,
which resolve to nothing (or to an unrelated `utils/` directory) in a vendored `.xyz/` install.

### 1. Inventory intake and active work

List open issues and all issue capture docs in deterministic order:

```bash
gh issue list --state open --limit 200 --json number,title,labels \
  --jq 'sort_by(.number) | .[] | "\(.number)\t\(.title)\t[\(.labels|map(.name)|join(","))]"'

find PROJECT/1-INBOX PROJECT/2-WORKING -maxdepth 1 -type f \
  -name 'GH-[0-9]*.md' -print | LC_ALL=C sort -V
```

Read the ledger's parked pointers (`releases roadmap list`) and each candidate's frontmatter, status table, acceptance criteria, and
`Swarm Preflight Contract`. Do not treat a title match as a contract.

### 2. Reconcile each issue document

Query each issue number with one batched `gh issue list` or `gh issue view`. Assign exactly one
classification:

| Classification | Meaning | Recommendation |
|---|---|---|
| `STALE-CLOSED` | Capture is active but the issue is closed | Reconcile outcome; move to `3-COMPLETED` only if shipped, otherwise `4-MISC` |
| `READY` | Open, promoted, valid contract, dry-run exit 0 | Candidate for ranking |
| `CONTRACT-STALE` | Preflight exit 4 says the fix already landed | Verify delivery evidence; propose reconciliation |
| `NEEDS-PROMOTE` | Open, contract exists, still in `1-INBOX` | Propose promotion and full active-doc contract |
| `NEEDS-CONTRACT` | Open, no valid preflight JSON contract | Propose bounded acceptance and write-set contract |
| `NEEDS-CAPTURE` | Open, in scope, and no `GH-<n>-*.md` exists in `1-INBOX` or `2-WORKING` | **Write the capture now (Step 3)**, then classify as `NEEDS-CONTRACT` |
| `BLOCKED` | Preflight exits 5, 6, or 7 | Report the exact blocker; do not queue |
| `NOT-A-WORK-ITEM` | Feedback, report, duplicate, deferred, or meta-only | Exclude and explain |
| `UNKNOWN` | GitHub or required evidence unavailable | Exclude until verified |

A contract exists only when valid JSON appears under a heading matching `Preflight Contract` and
satisfies `$HARNESS/utils/swarm-preflight.sh`'s current schema (Step 0). Run the script rather than
hand-validating it.

### 3. Capture the intake that is missing — with the existing writers

For every `NEEDS-CAPTURE` issue, produce the same two artifacts `hq park --create` produces for a
new issue, using the same functions it uses. Never hand-author frontmatter, never add a second
write path:

```bash
source "$HARNESS/utils/hq/hq-lib.sh"      # hq_render_capture, hq_roadmap_line, hq_slug
NUM=<n>; URL="https://github.com/<org>/<repo>/issues/$NUM"
TITLE="$(gh issue view "$NUM" --json title --jq .title)"
BODY="$(gh issue view "$NUM" --json body --jq .body)"
CREATED="$(gh issue view "$NUM" --json createdAt --jq '.createdAt[0:10]')"
DOC="PROJECT/1-INBOX/GH-${NUM}-$(hq_slug "$TITLE" | tr '[:lower:]' '[:upper:]').md"

# <num> <src> <title> <created> <doc_type> <project> <repo> <request> — ratings default to
# ratings_provisional: true, which marathon-plan already parks out of active waves.
hq_render_capture "$NUM" "$URL" "$TITLE" "$CREATED" bugfix <project> <org>/<repo> "$BODY" > "$DOC"

python3 "$HARNESS/utils/py/releases_app.py" roadmap add \
  --issue-num "$NUM" --issue-url "$URL" --title "$TITLE" --created "$CREATED" --doc-path "$DOC" \
  --raw-text "$(hq_roadmap_line "$NUM" "$TITLE" "$CREATED" "$DOC" "$(basename "$DOC")" "$URL")"
python3 "$HARNESS/utils/py/releases_app.py" roadmap list | grep "GH-$NUM"     # read the row back
```

Use `feedback` instead of `bugfix` for a non-defect capture. A doc written here is a capture, not
an active-work doc: it carries no `## Status` table until promotion. Record each `(issue, doc path,
ledger gid)` for the report. If `roadmap add` fails, the intake is **half-complete** (doc exists, no
row) — report it as such with the writer's error, never as success. Committing the captures is an
operator decision (the report lists it); `NOT-A-WORK-ITEM` issues get no capture and are listed with
the reason.

### 4. Compute the plan — dry run, deep

```bash
python3 "$HARNESS/utils/py/marathon_plan.py" --dry-run --deep
```

`--dry-run` prints the report and writes no `MARATHON-PLAN-*.md`; `--deep` runs
`swarm-preflight.sh --dry-run` for every ready item and folds the verdicts in. Quote the waves, the
held items and any drift lines in the report. Handle the exit code per the drive loop table; `3`
(ledger unparseable) turns the run into a blocked report, as does any other unmet Done-rule
requirement listed there. Writing the plan file (the planner **without** `--dry-run`)
is one of the five confirmation-gated actions — propose it in the report, do not do it.

If a current `MARATHON-PLAN-*.md` already exists, `--check` reports whether it is in sync; drift is
a finding for the report, not a reason to regenerate.

### 5. Preflight the remaining candidates

Run preflight **directly for every candidate** that is not `NOT-A-WORK-ITEM` or `UNKNOWN`, including
the ready items `--deep` already touched — deep delegation discards preflight output and only
handles exits 4/5/6/7, so it cannot supply a candidate's recorded exit and verdict. Use paths for
inbox docs and issue numbers for promoted docs:

```bash
"$HARNESS/utils/swarm-preflight.sh" --project-doc PROJECT/1-INBOX/GH-<n>-<slug>.md --dry-run
"$HARNESS/utils/swarm-preflight.sh" --gh-issue <n> --dry-run
```

Record the exact exit and verdict: ready `0`, usage `2`, invalid contract `3`, already landed `4`,
not ready `5`, blocked target `6`, or ambiguous `7`. Every code maps to a classification in Step 2;
none is a reason to stop.

Audit `artifacts`, `artifacts_new`, and `lanes` against the issue's actual scope. Flag placeholder,
missing, over-broad, or unrelated write-sets; a ready exit does not make a dishonest write-set safe.

Ranking and waves: apply the PDDA selection rule — gate on `risk <= 2`, then rank by lowest
`effort + complexity`, then fewest `phases`. Do not store a new composite score. Place lanes together
only when their declared and audited write-sets are disjoint and all zone caps hold. Shared ledgers
such as the RELEASES DB and `CHANGELOG.md` collide. Kernel paths obey the repo's
one-kernel-lane-per-wave cap.

### 6. Report

Return one of the two shapes. A **complete report** (the Done rule holds) contains:

1. Classification table with issue, doc, live state, contract state, and reason — one row per open
   issue and per `GH-*.md` doc.
2. Captures written in Step 3: issue, doc path, ledger gid; and the issues excluded with reasons.
3. The planner dry-run output (waves, held, drift) and the ranked candidates with each exact
   preflight exit and verdict.
4. Collision map and recommended waves.
5. Decisions needed — one **default recommendation per item**, not a flat symmetric list of
   options the operator has to weigh unaided. For each item that needs a call, emit:

   ```
   RECOMMEND: <the single default action — commit captures | archive | close | promote | contract | unblock | write plan file | open umbrella + fire | hold>
   BECAUSE:   <the evidence behind it — live state, preflight verdict, rating, collision risk>
   UNLESS:    <the specific condition under which the operator should override the default>
   ```

   The operator starts from the recommendation and only overrides when the `UNLESS` clause
   holds — never from a blank menu. Reserve a bare options list only for genuinely balanced
   calls where no default is defensible, and say so explicitly.

A **blocked report** contains everything above that *was* established, plus one line per
unmet requirement: the command run, its exit code, the evidence that could not be established, and
the next action. It never contains fabricated waves or verdicts.

Keep the default report inline. If the operator requests a persisted report, write a dated
`PROJECT/1-INBOX/MARATHON-TRIAGE-YYYY-MM-DD.md` with `doc_type: report`, source/provenance, and
`roadmap_exempt: true`. If promoted to `2-WORKING`, add the full PDDA frontmatter, exact status table,
and the ledger pointer. Never execute the marathon from this skill.

### 7. Before firing — the umbrella issue and the derived full clone (operator-confirmed)

Nothing in this step runs during triage. It applies once the operator has **selected** a marathon
from the report and authorised firing it; the report's decisions list proposes it.

#### 7a. Every marathon has an umbrella tracking issue

**A marathon without a GitHub umbrella issue does not start.** The umbrella is the marathon's
identity: waves, clone folder, ledger row and closeout all key off its number.

Today this is under-enforced and the gap is measurable: `releases_app.py marathon add` requires
`--tracking-issue` (`utils/py/releases_app.py:4901`) and `marathons.tracking_ref_id` is `NOT NULL`
(`:479`) — but the executor never reads either. `marathon_drive.py` has no `--tracking-issue` flag
and the `MARATHON.yaml` schema has no field for one, so the requirement binds only if someone
chooses to create the ledger row. Most runs have not: **at least eight marathons are visible in
committed transcripts and `marathon-system/`, against two rows in the `marathons` table.**

Procedure, before the selected marathon fires:

1. Open the umbrella issue. Title it for the arc, not the first item. Body lists the candidate
   member issues, the wave sketch, and the acceptance rule for the marathon as a whole.
2. Register it in the ledger immediately:
   ```bash
   python3 "$HARNESS/utils/py/releases_app.py" marathon add \
     --tracking-issue https://github.com/<org>/<repo>/issues/<n> --status planned
   ```
   Offline, `TMP-XXXXXX` is an accepted placeholder — but reconcile it before the marathon closes,
   or the ledger row permanently names an issue that does not exist. The token is **shape-checked
   only** (`check_tracking_token`, `:1675-1694`); GitHub is never queried, so a typo in the URL is
   accepted silently.
3. Dial every member issue into the same release, and link them to this marathon.

Carry the umbrella number into every downstream artifact: the clone folder name (7b), the plan
doc, each phase brief, and the closeout. If you cannot name the umbrella issue, the marathon is not
ready to fire — the triage report is where that arc gets decided.

#### 7b. Marathons run in a full clone, deterministically named

**Two rules, both currently unenforced by code.** State them explicitly in the plan so a reviewer
can check them.

**A full clone, never a linked worktree and never the primary checkout.** The mechanism that makes
this necessary is real but indirect: `validate.sh:16-53` refuses to run inside a linked worktree
(GH-45, exit 2), and `driver_lock_path_for_repo` (`relay-automation/driver-lock-lib.sh:20-35`)
resolves a linked worktree's lock to its **parent's** `.git/relay-driver.lock`, so a worktree
cannot run a second driver concurrently. Nothing refuses a marathon launched from the primary
checkout — `test/gh35-test-tiers.sh:367-370` proves the primary checkout runs the gate normally —
so this rule is on the operator, not the harness.

**Clone folder name is derived, not chosen:**

```
marathon-gh-<umbrella-issue-number>-<short-description>
```

`<short-description>` is lowercase, hyphen-separated, three words or fewer, describing the arc —
not a wave label, not a phase number. One clone per marathon; a second attempt at the same arc
reuses the name with a `-r2` suffix rather than inventing a new slug.

```bash
CLONE="$HOME/marathon-clones/marathon-gh-${UMBRELLA}-${SLUG}"
git clone <remote> "$CLONE"
```

This replaces the current free-form convention, which has drifted badly and is the reason a
salvage operation once could not find its own artifacts: live folders are `gh271-waveA`,
`gh396-phase0` and `gh405-mock-board` — a wave label, a phase number and a feature name, three
different meanings under one shape — while committed transcripts also show `gh-8-…` and `gh-115-…`
with a different separator, plus a `gh-115-clean` retry folder with no stated relationship to its
original.
