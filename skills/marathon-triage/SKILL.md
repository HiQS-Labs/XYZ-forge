---
name: marathon-triage
description: >
  Triage PDDA intake and active work into a ranked, preflight-checked, collision-safe marathon
  candidate list. Reconcile GH capture docs with live issue state, identify missing or stale
  preflight contracts, run dry-run readiness checks, and group disjoint write-sets into safe waves.
  Use when asked to triage the inbox, build or refresh a marathon queue, choose work to swarm next,
  identify concurrent issues, or plan a marathon without executing it. Requires this repo's
  PROJECT lifecycle, ROADMAP ledger, and swarm-preflight.sh / marathon-plan.sh resolved from the
  harness root (bare repo root or a vendored `.xyz/` install — see Workflow Step 0).
---

# Marathon triage

Produce an honest, ranked marathon plan without firing work. Treat `PROJECT/**` as the execution
record, GitHub as the live signal stream, and deterministic preflight output as stronger than prose.

## Guardrails

- Read `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `ROADMAP.md`, and `PROJECT/PDDA.md` first.
- Default to read-only. Do not move docs, promote intake, author contracts, close issues, generate a
  plan file, cut a branch, or fire a marathon without explicit operator confirmation.
- Never override a deterministic PDDA or preflight finding with narrative judgment.
- Use the repo's standing target branch policy. Do not invent a branch or silently substitute a
  builder.
- If GitHub is unavailable, mark live-state evidence `UNKNOWN`; do not infer it from stale local text.

## Workflow

### 0. Resolve the harness root

Resolve the harness root via the locator loop and evaluate its exported environment:

```bash
L=""
for candidate in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/relay-xyz/find-harness.sh}" \
                 "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
                 "$HOME/.codex/skills/relay-xyz/find-harness.sh" \
                 "$HOME/.gemini/config/skills/relay-xyz/find-harness.sh" \
                 "$HOME/.gemini/antigravity/skills/relay-xyz/find-harness.sh" \
                 "$HOME/.gemini/antigravity-cli/skills/relay-xyz/find-harness.sh" \
                 "$(git rev-parse --show-toplevel 2>/dev/null)/.claude/skills/relay-xyz/find-harness.sh" \
                 "$(git rev-parse --show-toplevel 2>/dev/null)/skills/relay-xyz/find-harness.sh"; do
  [ -n "$candidate" ] && [ -f "$candidate" ] && { L="$candidate"; break; }
done
[ -n "$L" ] || { echo "relay-xyz: locator not found — install the skill or set XYZ_HARNESS" >&2; exit 1; }
eval "$("$L" --env)"
```

Reference every script below as `$HARNESS/utils/swarm-preflight.sh` and
`$HARNESS/utils/marathon-plan.sh` — not bare `utils/...` paths, which resolve to nothing (or to an
unrelated `utils/` directory) in a vendored `.xyz/` install.

### 1. Inventory intake and active work

List open issues and all issue capture docs in deterministic order:

```bash
gh issue list --state open --limit 200 --json number,title,labels \
  --jq 'sort_by(.number) | .[] | "\(.number)\t\(.title)\t[\(.labels|map(.name)|join(","))]"'

find PROJECT/1-INBOX PROJECT/2-WORKING -maxdepth 1 -type f \
  -name 'GH-[0-9]*.md' -print | LC_ALL=C sort -V
```

Read `ROADMAP.md` pointers and each candidate's frontmatter, status table, acceptance criteria, and
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
| `BLOCKED` | Preflight exits 5, 6, or 7 | Report the exact blocker; do not queue |
| `NOT-A-WORK-ITEM` | Feedback, report, duplicate, deferred, or meta-only | Exclude and explain |
| `UNKNOWN` | GitHub or required evidence unavailable | Exclude until verified |

A contract exists only when valid JSON appears under a heading matching `Preflight Contract` and
satisfies `$HARNESS/utils/swarm-preflight.sh`'s current schema (Step 0). Run the script rather than
hand-validating it.

### 3. Preflight candidates

Use paths for inbox docs and issue numbers for promoted docs:

```bash
$HARNESS/utils/swarm-preflight.sh --project-doc PROJECT/1-INBOX/GH-<n>-<slug>.md --dry-run
$HARNESS/utils/swarm-preflight.sh --gh-issue <n> --dry-run
```

Record the exact exit and verdict: ready `0`, usage `2`, invalid contract `3`, already landed `4`,
not ready `5`, blocked target `6`, or ambiguous `7`.

Audit `artifacts`, `artifacts_new`, and `lanes` against the issue's actual scope. Flag placeholder,
missing, over-broad, or unrelated write-sets; a ready exit does not make a dishonest write-set safe.

### 4. Rank and form waves

Prefer an existing, current `MARATHON-PLAN-*.md` generated by `$HARNESS/utils/marathon-plan.sh`
(Step 0). Running the planner writes a file, so request confirmation before generating or
refreshing one.

Apply the PDDA selection rule: gate on `risk <= 2`, then rank by lowest `effort + complexity`, then
fewest `phases`. Do not store a new composite score.

Place lanes together only when their declared and audited write-sets are disjoint and all zone caps
hold. Shared ledgers such as `ROADMAP.md` and `CHANGELOG.md` collide. Kernel paths obey the repo's
one-kernel-lane-per-wave cap.

### 5. Report

Return:

1. Classification table with issue, doc, live state, contract state, and reason.
2. Ranked candidates with ratings and exact preflight verdict.
3. Collision map and recommended waves.
4. Decisions needed — one **default recommendation per item**, not a flat symmetric list of
   options the operator has to weigh unaided. For each item that needs a call, emit:

   ```
   RECOMMEND: <the single default action — archive | close | promote | contract | unblock | hold>
   BECAUSE:   <the evidence behind it — live state, preflight verdict, rating, collision risk>
   UNLESS:    <the specific condition under which the operator should override the default>
   ```

   The operator starts from the recommendation and only overrides when the `UNLESS` clause
   holds — never from a blank menu. Reserve a bare options list only for genuinely balanced
   calls where no default is defensible, and say so explicitly.

Keep the default report inline. If the operator requests a persisted report, write a dated
`PROJECT/1-INBOX/MARATHON-TRIAGE-YYYY-MM-DD.md` with `doc_type: report`, source/provenance, and
`roadmap_exempt: true`. If promoted to `2-WORKING`, add the full PDDA frontmatter, exact status table,
and ROADMAP pointer. Never execute the marathon from this skill.

