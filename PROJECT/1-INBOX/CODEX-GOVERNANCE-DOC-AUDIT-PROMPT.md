# Codex task — governance-document identity audit

## Why you are being asked to do this

This repository (`HiQS-Labs/XYZ-forge`) vendors a second project's governance documents into
`PROJECT/`, and readers — humans and agents alike — are mistaking them for this project's own policy.
An external reviewer read `PROJECT/CONSTITUTION.md` and `PROJECT/DO-NOT-BUILD.md` as XYZ Forge's
charter and produced a materially wrong assessment of the project's intended scope, *despite* the
first line of `CONSTITUTION.md` naming PDDA as its subject. If that misreading is that easy to make
with the text open, it will keep happening — including to agents doing repo triage, which is worse,
because they will act on it.

Your job is to make the ownership of every governance document unambiguous, and to correct the
factual drift in this project's *own* principles doc. This is a documentation-correctness task with a
real blast radius: several of these files are dependency-sync inputs, and one of them is the policy
that governs how syncs are reviewed. Read before you cut.

## Starting observations — refresh against the audit commit

Tracking issue: https://github.com/HiQS-Labs/XYZ-forge/issues/453. Reuse this issue.
The original prompt remains in its issue body; this revision incorporates the review comment.

These observations were checked during the 2026-09-05 prompt review, while the primary checkout
was changing. Record the audit clone's base SHA and refresh every count, citation, and live-state
claim before relying on it. Prefer codebase-memory discovery, verify its project/generation and
coverage, and fall back to direct source for changed, missing, or excluded evidence.

**Ownership confusion**

1. Five governance documents at `PROJECT/`'s top level discuss PDDA: `CONSTITUTION.md`,
   `DO-NOT-BUILD.md`, `PDDA-MODE-GUIDE.md`, `PDDA-SYNC-POLICY.md`, and `PDDA.md`.
   **Subject, maintenance ownership, and authority in XYZ are different questions.** In particular,
   `PDDA-SYNC-POLICY.md` expressly governs this repository's review of PDDA imports.
2. `CONSTITUTION.md` states PDDA's lane; `DO-NOT-BUILD.md` describes PDDA's anti-scope and adds
   “and any repo-governance/safety layer built alongside it.” Their generic titles invite confusion.
   `ROUTER.md` also calls the constitution the “policy of record”; treat that as local adoption
   evidence, not permission to silently disown or broaden it.
3. Both cite a feedback synthesis and three feedback files that were absent locally at review time.
   Absence proves a broken local evidence chain, not its precise upstream location. Verify the
   upstream repository, revision and source URLs; mark unavailable provenance unresolved.
4. `PROJECT/PDDA-SYNC-POLICY.md` explicitly calls itself repo-owned and identifies `PROJECT/PDDA.md`
   and `utils/pdda/**` as replaceable sync inputs. Determine the other documents' ownership from
   registration, test coverage, issue provenance, introduction history and the import manifest.
   Imported origin does not cancel protected local behavior attached to a file.
5. `GUIDING-PRINCIPLES.md` already has a Purpose section describing XYZ's harness and shipping goal,
   and `AGENTS.md` supplies a work-selection purpose. No clearly distinguished XYZ charter/anti-scope
   document was established by the prompt review. Check existing framing before proposing a new
   document; extending the Purpose section is a first-class option.

**Factual drift in `GUIDING-PRINCIPLES.md`**

6. **Principle 7 is false as written.** It claims *"Node standard library only — no deps, no lockfile;
   the repo ships no root manifest."* Reality: `package.json` and `package-lock.json` are both
   git-tracked and declare `acorn ^8.17.0` and `acorn-walk ^8.3.5`. `src/acorn-extract.js`
   consumes them. A kernel-only statement may be true, but verify the bounded kernel import graph
   before proposing it; the root-manifest, dependency and lockfile claims are contradicted.
7. **Line 3 calls the project `xyz-3-agents-swarm`**, the predecessor repo name. `package.json`'s
   `name` field has the same staleness.
8. **`README.md` cites `GUIDING-PRINCIPLES.md` §8`** for the operator-decides rationale, but that file
   has no numbered sections. The intended target is almost certainly item 8 under "How it's built"
   (*"Honest; the operator decides"*). Verify and repoint.

**Related drift found nearby — confirm before acting**

9. `.pdda-mode`'s header comment claims `light` mode "moves stale docs." Contradicted by
   `utils/pdda/pdda-lib.sh:46` and `PROJECT/PDDA.md:878` (*"No mode mutates the tree"*). The inspected
   exit-gating function treats `observe` and `light` identically. Do not generalize that to every
   behavior without checking all mode consumers.
10. `PROJECT/PDDA-MODE-GUIDE.md:61` and `:69` both cite `PROJECT/PDDA.md` → "Check severity contract"
    as authoritative. **That heading does not exist.** PDDA's own `check_governance` detects dead
    *file* references but not dead *section* references, so it structurally cannot catch this class.
11. `ROUTER.md` still had the obsolete private-only hosted-CI paragraph during review. README had
    already been corrected to describe local plus hosted CI. Refresh both. The workflow declares
    push/PR triggers for `main` and `development`; trigger configuration is not evidence of a passing
    hosted run. Verify repository visibility independently if relying on it.
12. The review found **44 indexed skills and 49 direct `skills/*/SKILL.md` files**. `start-task` was
    already indexed. Missing then: `browserbase`, `converge`, `dry`, `merge-cleanup`, `workhorse`.
    Recompute the set difference at the audit SHA; do not hardcode these counts as acceptance criteria.
13. Principle 9 and current-tense appendix wording still refer to `ROADMAP.md`, while XYZ's current
    roadmap authority is the RELEASES DB. Include these in the correction inventory, distinguishing
    legacy PDDA conventions and historical statements from current XYZ instructions.

## Hard constraints — read these before proposing anything

- **Respect `PROJECT/PDDA-SYNC-POLICY.md`. It governs this work.** Any file you propose to remove,
  move, or rename inside the sync footprint must go through that document's classification procedure
  first: produce the deletion inventory it requires, check each path for registration, coverage,
  issue provenance, history, and replacement, and classify as sync-owned / repo-owned / **ambiguous**.
  The policy is explicit that *"no signal is not permission to assume a file is stale"* — ambiguous
  means stop and ask, not proceed.
- **Local changes must survive the next sync.** A prepended banner can be overwritten too.
  Trace the actual import manifest/generator and update path; propose a disposable replay that
  proves the chosen result survives, or explicitly record the remaining limitation.
  **Deleting a sync input does not make it stay deleted.** If `CONSTITUTION.md` or `DO-NOT-BUILD.md`
  are upstream-managed, the next sync restores them. A disposition that only works until the next
  sync is not a fix; say so if you find that to be the case.
- **Issue-first is satisfied by #453; do not open duplicate intake.** Create/reuse its pointer doc at
  `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md`, parked in the ledger via
  `python3 utils/py/releases_app.py roadmap add …` before execution. This task is well beyond that
  threshold.
- **Never hand-edit** `releases.sql`, `releases.db`, or ledger rows. CLI verbs only.
- **Do not edit the 12 frozen Bash twins.** A CI guard rejects those diffs without a
  `Frozen-twin-exception:` trailer.
- **Do not weaken any check to make a gate pass.** If a doc check fails on your change, fix the doc.
- This repo configures PDDA full mode. Errors block; some findings remain warnings even in full
  mode. Inspect findings, not only the exit status, and never weaken a check.

## What to produce — in two stages, with a stop in between

### Stage 1 — inventory and proposal. Do not edit governance content yet.

Intake metadata, this revised task prompt, the report, review/evidence artifacts, and a new
CHANGELOG end-of-iteration entry are permitted. Do not rewrite historical changelog entries.
The report belongs in the issue's canonical project document, not a competing plan. No policy,
filename, import mechanism, checker behavior, or applicability change is authorized in Stage 1.

Deliver a single markdown report containing:

1. **An ownership table** for every file in `PROJECT/*.md` plus `GUIDING-PRINCIPLES.md`, `AGENTS.md`,
   and `ROUTER.md`: path · subject project · maintenance classification (sync-owned / repo-owned /
   ambiguous) · XYZ applicability (applies / adopted subset / upstream context only / unresolved) ·
   evidence (registration, coverage, provenance, history, replacement) · proposed disposition.
   Keep imported origin and protected local guardrails visible even when they coexist. Record every
   ambiguous classification and the precise maintainer question; do not invent authority.
2. **A recommended disposition strategy**, chosen and argued rather than assumed. Consider at least:
   - relocating vendored governance under an unmistakable path (e.g. `PROJECT/vendor/pdda/`) and
     repointing every reference;
   - leaving files in place but prepending a standard provenance banner naming the owning project,
     the verified upstream repo/revision, and the specific applicability to XYZ. Do not use a blanket
     “not XYZ Forge policy” label on adopted rules or the repo-owned sync policy;
   - extending the existing XYZ Purpose section, versus adding an XYZ-owned scope document only if
     the existing document cannot serve as the canonical home, and deciding what it
     should assert given that the system now spans capture → rate → plan → preflight → execute →
     gate → land → record;
   - whether the `DO-NOT-BUILD.md:3` parenthetical (*"and any repo-governance/safety layer built
     alongside it"*) means any of its entries legitimately bind this repo's governance layer, and if
     so which.
   State the trade-offs. `GUIDING-PRINCIPLES.md`'s own North Star — durable, reversible, DRY, and
   "extend what exists rather than forking a parallel system" — is the standard to argue against.
3. **A corrections list** for `GUIDING-PRINCIPLES.md`, with exact proposed replacement text for
   principle 7 and line 3, plus any other claim you can falsify by inspection. Check every principle
   against bounded evidence; do not stop at the two already found. Classify each as a normative
   requirement, implementation claim, historical statement, or externally dependent assertion.
   Code cannot prove values or billing terms. Mark confirmed, contradicted, or unresolved and name
   the evidence boundary; do not turn this into an entire-repository conformance project.
4. **A findings list** for items 9–13 above, each confirmed or refuted with a file:line citation, and
   a recommendation. Note which belong in this change and which should be separate issues.
5. **An explicit non-goals section**: what you found but are deliberately not touching, and why.

**Stop after Stage 1 and wait for maintainer approval of the concrete report/dispositions.**
Independent review of the report does not authorize Stage 2. List exact paths, policy-applicability
choices and any unresolved ownership question for the maintainer; do not proceed to governance edits.

### Stage 2 — execute the approved plan

Only the approved dispositions, then:

- Update every inbound reference to a moved or renamed file. `ROUTER.md`'s role-split table and
  `ARCHITECTURE.md` are the highest-traffic referrers; also sweep `README.md`, `HOW-TO-USE.md`,
  `SOP.md`, `AGENTS.md`, `skills/**/SKILL.md`, and `utils/pdda/**`.
- Verify no newly broken file links or heading references in changed documents and affected inbound
  references, including nested referrers. A bounded one-off relative-link/heading resolver is reasonable;
  require a non-empty scanned set and prove it rejects a missing file and a missing heading in a
  disposable fixture. Record pre-existing unrelated failures separately; note that `CHANGELOG.md` is a historical log with many intentionally dead
  references to relocated docs — **do not attempt to repair CHANGELOG history**, and exclude it
  rather than reporting its links as defects.
- Record the change per the PDDA contract, including a `## Lessons Learned (For Future Agents)`
  section if the capture doc is promoted.

## Verification — distinguish Stage 1 from Stage 2

Stage 1 is complete when the requested report is grounded, independently reviewed, and submitted
for approval with unresolved decisions explicit. Run relevant report/intake hygiene checks, but do
not claim the proposed policy corrections or sync persistence have been implemented or verified.

For Stage 2, run the following against the exact candidate. `validate.sh` and `test/*.sh` must run
in an **un-sandboxed, separate disposable full clone**, never a valued task clone or linked worktree.
Record candidate SHA, environment, command and exit status, plus pre/post HEAD, core.bare, origin,
and local Git user identity. Unexpected identity drift invalidates the run. Keep required
`provenance.jsonl` and red/green evidence committed with the eventual PR, under the repository's
existing evidence contract. A gate is not promotion evidence unless the promotion contract says so.

```bash
bash utils/pdda/pdda.sh run          # doc governance; must pass (this repo is PDDA_MODE=full)
./validate.sh --tier 1               # the docs gate
./validate.sh                        # full suite if you touched anything outside PROJECT/**
bash utils/pdda/pdda.sh governance   # dead governance references + ROUTER discoverability
```

Then confirm by hand: `ROUTER.md`'s startup sequence still resolves to files that exist; a fresh
reader of `PROJECT/` can tell within one line which project each governance doc governs; and
`GUIDING-PRINCIPLES.md` contains no claim contradicted by the repo root.

Report which commands you ran and their outcomes. **Do not report success on a suite you did not
run** — and note that `validate.sh` needs an un-sandboxed shell, because its `mktemp -d` scratch
directories can fail silently under a sandboxed Bash tool. Un-sandboxed execution alone does not
provide isolation; the separate disposable full clone remains mandatory.

## Explicitly out of scope

- Rewriting PDDA's actual policy content. If a vendored doc is wrong *about PDDA*, that is an upstream
  issue — draft it for review, do not patch it here or publish it without authorization.
- Renaming the project or changing `package.json`'s `name` field. Related, but a separate decision
  with its own blast radius; note it and move on.
- Any change to `utils/pdda/**` behavior. You are auditing document ownership, not the checker.
- The 12 frozen Bash twins.

- Changing which PDDA restrictions bind XYZ without explicit approval; adding a new sync system;
  repairing historical CHANGELOG links; proving every runtime invariant as part of a docs audit.
