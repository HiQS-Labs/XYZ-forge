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

## Verified findings you can build on

These have been confirmed by direct inspection. You do not need to re-derive them, but you should
spot-check anything you intend to act on.

**Ownership confusion**

1. All five `PROJECT/*.md` governance docs take **PDDA** as their subject: `CONSTITUTION.md`,
   `DO-NOT-BUILD.md`, `PDDA-MODE-GUIDE.md`, `PDDA-SYNC-POLICY.md`, `PDDA.md`. Only `PDDA.md` mentions
   XYZ at all.
2. `CONSTITUTION.md` opens with *"PDDA's lane, stated in one line: a thin repo-governance and safety
   layer."* `DO-NOT-BUILD.md:3` reads *"the explicit anti-scope list for PDDA (and any
   repo-governance/safety layer built alongside it)."* Neither filename signals this.
3. Both cite four provenance sources — `PROJECT/2-WORKING/GH-144-PDDA-FEEDBACK-SYNTHESIS.md` and
   `PROJECT/1-INBOX/PDDA/FEEDBACK-{PERPLEXITY,CHATGPT,GEMINI}.md`. **All four are absent from this
   repo**, and there is no `PROJECT/1-INBOX/PDDA/` directory. Their evidence chain lives upstream.
4. `PROJECT/PDDA-SYNC-POLICY.md` establishes that `PROJECT/PDDA.md` and `utils/pdda/**` are sync
   **inputs** that *"may be replaced wholesale by the next one"* — and exists because commit
   `cfd56b0` did exactly that, *"which is how the guardrails went missing."* It declares itself
   *"deliberately repo-owned."* The ownership status of `CONSTITUTION.md` and `DO-NOT-BUILD.md` is
   **not** stated anywhere and must be determined, not assumed.
5. **XYZ Forge has no scope document of its own.** A repo-wide search for anti-scope language finds
   only PDDA's. `GUIDING-PRINCIPLES.md` contains no product-scope statement — its scope language is
   about containing an agent turn, and its single "Scope note" (`:126`) is about binary install
   paths. `AGENTS.md` has none.

**Factual drift in `GUIDING-PRINCIPLES.md`**

6. **Principle 7 is false as written.** It claims *"Node standard library only — no deps, no lockfile;
   the repo ships no root manifest."* Reality: `package.json` and `package-lock.json` are both
   git-tracked and declare `acorn ^8.17.0` and `acorn-walk ^8.3.5`. Only `src/acorn-extract.js`
   consumes them, so a narrower true statement is available — the *kernel* is stdlib-only — but three
   of the principle's four clauses are contradicted by files in the repo root.
7. **Line 3 calls the project `xyz-3-agents-swarm`**, the predecessor repo name. `package.json`'s
   `name` field has the same staleness.
8. **`README.md` cites `GUIDING-PRINCIPLES.md` §8`** for the operator-decides rationale, but that file
   has no numbered sections. The intended target is almost certainly item 8 under "How it's built"
   (*"Honest; the operator decides"*). Verify and repoint.

**Related drift found nearby — confirm before acting**

9. `.pdda-mode`'s header comment claims `light` mode "moves stale docs." Contradicted by
   `utils/pdda/pdda-lib.sh:46` and `PROJECT/PDDA.md:878` (*"No mode mutates the tree"*). Also,
   `observe` and `light` are **mechanically identical** — the only gate is
   `pdda-lib.sh:53-55`, which acts on `full` alone.
10. `PROJECT/PDDA-MODE-GUIDE.md:61` and `:69` both cite `PROJECT/PDDA.md` → "Check severity contract"
    as authoritative. **That heading does not exist.** PDDA's own `check_governance` detects dead
    *file* references but not dead *section* references, so it structurally cannot catch this class.
11. `README.md` and `ROUTER.md` state that hosted CI *"fires on nothing while this repo is private."*
    The repo is public and `.github/workflows/ci.yml:98-103` triggers on push and PR to `main` and
    `development`. The claim is stale in the project's favor.
12. `ARCHITECTURE.md`'s Skills Index lists 43 skills; **49 exist on disk**. Unindexed: `browserbase`,
    `converge`, `dry`, `merge-cleanup`, `start-task`, `workhorse`.

## Hard constraints — read these before proposing anything

- **Respect `PROJECT/PDDA-SYNC-POLICY.md`. It governs this work.** Any file you propose to remove,
  move, or rename inside the sync footprint must go through that document's classification procedure
  first: produce the deletion inventory it requires, check each path for registration, coverage,
  issue provenance, history, and replacement, and classify as sync-owned / repo-owned / **ambiguous**.
  The policy is explicit that *"no signal is not permission to assume a file is stale"* — ambiguous
  means stop and ask, not proceed.
- **Deleting a sync input does not make it stay deleted.** If `CONSTITUTION.md` or `DO-NOT-BUILD.md`
  are upstream-managed, the next sync restores them. A disposition that only works until the next
  sync is not a fix; say so if you find that to be the case.
- **Issue-first.** Anything beyond a 2–3 line fix opens a GitHub issue first, then a pointer doc at
  `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md`, parked in the ledger via
  `python3 utils/py/releases_app.py roadmap add …` before execution. This task is well beyond that
  threshold.
- **Never hand-edit** `releases.sql`, `releases.db`, or ledger rows. CLI verbs only.
- **Do not edit the 12 frozen Bash twins.** A CI guard rejects those diffs without a
  `Frozen-twin-exception:` trailer.
- **Do not weaken any check to make a gate pass.** If a doc check fails on your change, fix the doc.
- This repo runs PDDA at `PDDA_MODE=full`. Doc-contract violations **will** block your push.

## What to produce — in two stages, with a stop in between

### Stage 1 — inventory and proposal. Do not edit content yet.

Deliver a single markdown report containing:

1. **An ownership table** for every file in `PROJECT/*.md` plus `GUIDING-PRINCIPLES.md`, `AGENTS.md`,
   and `ROUTER.md`: path · subject project · sync-owned / repo-owned / ambiguous · the evidence that
   settles it (registration, coverage, provenance, history, replacement) · proposed disposition.
2. **A recommended disposition strategy**, chosen and argued rather than assumed. Consider at least:
   - relocating vendored governance under an unmistakable path (e.g. `PROJECT/vendor/pdda/`) and
     repointing every reference;
   - leaving files in place but prepending a standard provenance banner naming the owning project,
     the upstream repo, and "not XYZ Forge policy";
   - adding an XYZ-owned scope document so the project has a charter of its own, and deciding what it
     should assert given that the system now spans capture → rate → plan → preflight → execute →
     gate → land → record;
   - whether the `DO-NOT-BUILD.md:3` parenthetical (*"and any repo-governance/safety layer built
     alongside it"*) means any of its entries legitimately bind this repo's governance layer, and if
     so which.
   State the trade-offs. `GUIDING-PRINCIPLES.md`'s own North Star — durable, reversible, DRY, and
   "extend what exists rather than forking a parallel system" — is the standard to argue against.
3. **A corrections list** for `GUIDING-PRINCIPLES.md`, with exact proposed replacement text for
   principle 7 and line 3, plus any other claim you can falsify by inspection. Check every principle
   against the code; do not stop at the two already found. Flag anything you cannot verify either way.
4. **A findings list** for items 9–12 above, each confirmed or refuted with a file:line citation, and
   a recommendation. Note which belong in this change and which should be separate issues.
5. **An explicit non-goals section**: what you found but are deliberately not touching, and why.

**Stop after Stage 1 and wait for maintainer approval.** Do not proceed to edits.

### Stage 2 — execute the approved plan

Only the approved dispositions, then:

- Update every inbound reference to a moved or renamed file. `ROUTER.md`'s role-split table and
  `ARCHITECTURE.md` are the highest-traffic referrers; also sweep `README.md`, `HOW-TO-USE.md`,
  `SOP.md`, `AGENTS.md`, `skills/**/SKILL.md`, and `utils/pdda/**`.
- Verify no dangling links remain. A relative-link resolver over the top-level docs is a reasonable
  one-off script; note that `CHANGELOG.md` is a historical log with many intentionally dead
  references to relocated docs — **do not attempt to repair CHANGELOG history**, and exclude it
  rather than reporting its links as defects.
- Record the change per the PDDA contract, including a `## Lessons Learned (For Future Agents)`
  section if the capture doc is promoted.

## Verification — required before you claim done

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
directories fail silently under a sandboxed Bash tool and the run will look like a hang.

## Explicitly out of scope

- Rewriting PDDA's actual policy content. If a vendored doc is wrong *about PDDA*, that is an upstream
  issue — file it there, do not patch it here.
- Renaming the project or changing `package.json`'s `name` field. Related, but a separate decision
  with its own blast radius; note it and move on.
- Any change to `utils/pdda/**` behavior. You are auditing document ownership, not the checker.
- The 12 frozen Bash twins.
