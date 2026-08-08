---
gh_issue: 422
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/422
title: "GH-422 — the source-URL gate's blast radius was measured on the harness only; make the failure self-remediating and ship a bulk backfill"
status: "Shipped 2026-08-04 — preflight resolves the target's real owner/repo instead of a placeholder, and utils/py/backfill_source_url.py fixes a repo's docs in one command. test/gh422-backfill-source-url.sh 20/0; controls observed at 15/3 (pre-fix replay) and 16/2 (conflict-guard mutation). Fleet dry-run: 34 docs to change across 3 repos, 1 conflict left for a human."
created: 2026-08-04
updated: 2026-08-04
owner: noel
doc_type: fix
complexity: 2
risk: 2
effort: 2
related:
  - "#400 / PR #420 — introduced the gate this remediates. The gate is correct and unchanged; only the cost of satisfying it moves."
  - "#419 — this is an instance of failing to apply its blast-radius discipline beyond the harness repo, and its negative-control forms are what this fix's evidence uses."
  - "#413 — the agy QA round that found two extractors disagreeing about the same document. That exact failure recurred here and was caught by dry-running against a real consumer."
  - "#417 — the fleet update this unblocks matters because 5 of 6 stale copies sit at spaced paths and carry GH-319's fake pre-advance gate."
  - "#312 — vendor state preservation; the update path is safe now, which is why updating is even on the table."
non_goals:
  - "Softening or narrowing the GH-400 source-url gate. Those docs genuinely lack provenance; the gate stays a hard fail. This reduces the cost of satisfying it, not the standard."
  - "Auto-running the backfill. Never on a hook, never inside preflight, never as part of xyz-sync update. It edits tracked files, so it is operator-invoked only."
  - "Editing the consuming repos from here. They run the tool in their own tree and review their own diff."
  - "Auto-correcting a mismatch. When source: cites a different issue than gh_issue, the wrong field may be gh_issue; a machine cannot tell, so it reports and leaves the file alone."
  - "Touching the frozen Bash twins (GH-308). Python only."
goal: >
  Make a correct gate cheap to satisfy. The harness already knows the owner/repo it was telling
  operators to look up by hand, and it can fix a whole repo's docs in one command instead of a
  dozen manual frontmatter edits — so the fleet update needed for GH-319 exposure does not arrive
  bundled with a pile of homework.
---

# GH-422 · a correct gate that was expensive to satisfy

## Status
| What was just completed | What's next |
|---|---|
| Both halves shipped: preflight resolves the target's real `owner/repo` and points at the bulk tool; `utils/py/backfill_source_url.py` remediates a repo in one command. 20/0, two independent negative controls observed. A real defect was found by dry-running against `cactus` and fixed before merge. | Operator review, then the fleet update: three zero-blocker copies immediately, the other three after their operators run the backfill. |

## What was actually wrong

PR #420's gate is right and stays. Two things around it were not.

**1. The blast radius was measured on the wrong population.** It was chosen from this repo alone —
1 of 48 docs — while the repos vendoring the harness carried far more. That is the same shape as the
defects #419 exists to catch: a decision made from a sample that did not include the affected group.

**2. The remediation it printed was a placeholder.** `Set source: https://github.com/<owner>/<repo>/issues/154`
— for a value `repo_slug_for()` already resolves from the target's `origin`, a few hundred lines away
in the same file. An operator with a dozen affected docs did that lookup a dozen times.

**What the gate does NOT do**, stated precisely because it was overstated once in discussion: it sets
`ready=0`, prints NOT-READY, exits 5, and writes no packet. **No file is modified, nothing is deleted,
no git state changes.** It is a refusal to start a lane, reversible by adding one line. It shares
nothing with GH-312's destructive class.

## What shipped

**The message resolves the real slug** and names the bulk tool, so the fix is a paste or a single
command rather than a lookup. Falls back to the placeholder only when no remote resolves.

**`utils/py/backfill_source_url.py`** derives the URL from the **target** repo's own `origin` — never
the harness's — so a vendored install cites its own GitHub project. Three deliberate conservatisms:

- **Dry-run by default.** It edits tracked files; writing needs `--apply`.
- **A mismatch is never rewritten.** When `source:` cites a different issue than `gh_issue`, the wrong
  field may be `gh_issue`. A machine cannot tell which, and rewriting the URL to agree would launder
  bad provenance into provenance that *looks* verified — the exact failure GH-400 exists to prevent.
  It reports and exits non-zero so a caller cannot read it as a clean sweep.
- **Frontmatter only.** The body is asserted byte-identical before any write.

## The defect the fleet dry-run caught, before merge

Dry-running against `cactus` reported **0 to change** where the blast measurement said 4.

`cactus` docs use `issue: 9`, not `gh_issue: 9`. The **gate** still blocks them, because preflight
resolves a doc by globbing `GH-9-*.md` for `--gh-issue 9` and checks against that number. The
**backfill** read only frontmatter, so it skipped precisely the docs the gate refuses — leaving an
operator blocked with a tool that reported success.

That is the two-extractors-disagree failure agy found in #400's checker during #413, recurring in new
code within a day. Fixed by giving the tool the gate's exact effective-issue rule (frontmatter, else
the `GH-<n>-` filename), and pinned by **C5b/C5c**, which assert not just that the tool writes a line
but that `check_source_url` then agrees the doc passes. A tool claiming a fix the gate still rejects
is worse than no tool.

**A second correction from the same run:** the fleet exposure is **34 docs, not the 18** first
reported. The original blast script used a non-recursive glob and missed subdirectories such as
`PROJECT/2-WORKING/v1.3.5/`, whose docs do block under `--project-doc`. The measurement that flagged
an under-measurement was itself under-measured.

## Fleet dry-run (read-only, nothing written)

| Repo | To change | Already correct | Conflicts |
|---|---|---|---|
| `rebalance-OS` | 16 | 23 | 0 |
| `LTVera-Pandas` | 14 | 19 | **1** |
| `cactus` | 4 | 0 | 0 |
| `pdda` | 0 | 6 | 0 |
| `sleuth-app` | 0 | 8 | 0 |
| `fast-key-replacement-macos` | 0 | 0 | 0 |

The one conflict — `LTVera-Pandas` `GH-94-…` citing issue #2 under `gh_issue: 94` — is deliberately
left for a human. It is exactly the case a machine must not guess.

## Verification

- `test/gh422-backfill-source-url.sh` **20/0**, registered in `validate.sh`.
- **Negative controls (#419), both forms, because the tool is net-new and has no meaningful "before":**
  - *pre-fix replay* of the preflight message → **15 pass / 3 fail** (C8/C8b/C8c; the placeholder is still emitted)
  - *deliberate mutation* disabling the conflict guard → **16 pass / 2 fail** (C4b/C4c; the conflict is silently rewritten and the exit code goes clean)
- One bug in this fix's own body-integrity guard was caught by the suite before merge: it sliced the
  rewritten text with offsets computed from the original, so every insertion tripped it and every doc
  fell through to `skip`. Fixed by re-matching frontmatter on the new text rather than loosening the
  assertion.

## Acceptance

*Copied verbatim from [issue #422](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/422)
(`## Acceptance`), fetched 2026-08-04. Deviations, if any, are recorded below this block.*

- [ ] The NOT-READY message for a missing source URL resolves the real `owner/repo` from the target repo's `origin` remote, so the suggested line can be pasted verbatim, and falls back to the placeholder only when no remote resolves.
- [ ] A backfill utility adds a `source:` line to every capture doc that declares a `gh_issue` and carries no valid issue URL, deriving the URL from the target repo's own `origin` rather than from the harness's.
- [ ] The utility is dry-run by default, printing each file it would change and the exact line it would insert; writing requires an explicit opt-in flag.
- [ ] The utility never rewrites an existing `source:` that cites a different issue than `gh_issue` — it reports the conflict and leaves the file alone, because the incorrect field may be `gh_issue` rather than the URL.
- [ ] The utility edits only the YAML frontmatter block and leaves the document body byte-identical.
- [ ] A regression test covers, at minimum: a missing `source:` is added; a valid one is left untouched; a mismatch is reported and not rewritten; the body is unchanged; and dry-run writes nothing. Its negative control is observed and recorded, per #419.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

Criterion 2 is met **more broadly than written**: the issue says "declares a `gh_issue`", and the tool
also covers a doc identified only by its `GH-<n>-` filename, because that is what the gate blocks.
Covering strictly more than a criterion asks is not a deviation from it — narrowing to the literal
wording would have reproduced the `cactus` defect above.
