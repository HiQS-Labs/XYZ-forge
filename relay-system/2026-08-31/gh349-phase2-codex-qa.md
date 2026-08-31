---
Goal: Independent adversarial QA of the GH-349 branch (second reviewer, after agy PASS)
Date: 2026-08-31
Branch: fix/gh-349-releases-roadmap-vendored @ e286b06e
Reviewer: codex (gpt-5.6-sol, reasoning=high)
NEXT: Reviewer
STATUS: Open
---

# Context

You are the **second, independent** reviewer of branch `fix/gh-349-releases-roadmap-vendored`
(PR #350). A prior reviewer (agy) returned **PASS** with one minor finding, already fixed.
Your job is **not** to re-confirm that verdict. Assume it may be wrong. Look for what it missed.

This branch generalises this repo's releases roadmap layer so a **vendored `.xyz/` install in
another GitHub org** can run `releases roadmap sync` against a link-style `ROADMAP.md`.

The branch has three layers of history, and each one found defects in the one before it:

- **Phase 1** (commits up to `186c9944`) — the original fix. Shipped a **blocking regression**:
  it swapped an anchored `^GH-(\d+)` key match for a whole-title `re.search`, which harvested a
  key out of titles that merely *cite* an issue, created a duplicate `GH-111` in **this repo's
  own** `ROADMAP.md`, and made `cmd_roadmap_sync` refuse outright here. Its own regression suite
  was green (18/18) because it exercised only the new link format and never re-parsed the 72
  bold-style entries the parser already served.
- **Phase 2** (`4265244e`) — fixed that plus three more defects found by the reporting repo
  (`BinoidCBD/LTVera-Pandas` issue #322, reviewing PR #350).
- **Phase 3** (`e286b06e`) — fixed agy's one minor finding (dotted-range umbrella titles).

**The pattern worth noticing: every pass so far found something the previous pass's green suite
did not.** Phase 1 was green and broken. Phase 2 was green and had the range bug. Phase 3 is
green. Assume it is not yet done.

## Read these

1. `git log --oneline origin/development..HEAD` — the three phases.
2. `git diff origin/development...HEAD` — the whole branch.
3. `utils/py/releases_app.py` — `_is_ledger_bullet`, `_roadmap_gh_number`, `_is_doc_pointer`,
   `_roadmap_issue_url` (all immediately above `parse_roadmap_ledger`), `parse_roadmap_ledger`,
   and `cmd_roadmap_sync`.
4. `test/gh349-releases-roadmap-vendored.sh` — sections 6 and 7 are new.
5. `ROADMAP.md` — this repo's own ledger, 72 bold-style entries. **This is the corpus the parser
   already served.** Phase 1's regression was visible in one pass over it.
6. `PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md` — the reasoning, including what was
   deliberately NOT done and why.
7. `relay-system/2026-08-31/gh349-phase2-review-qa.md` — agy's review. **Challenge it.**

You may also read `/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md` — the real
foreign-org, link-style ledger this branch exists to support (51 entries). Read-only.

## The single most useful thing you can do

**Differential-test the parser against both real ledgers**, rather than reasoning about the
regexes in the abstract. That is what caught every defect so far. For example:

```bash
python3 - <<'PY'
import sys, importlib.util, collections, subprocess
def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec); sys.argv = [name]
    try: spec.loader.exec_module(m)
    except SystemExit: pass
    return m
open("/tmp/old_app.py","w").write(subprocess.run(
    ["git","show","origin/development:utils/py/releases_app.py"],
    capture_output=True, text=True).stdout)
new = load("new", "utils/py/releases_app.py")
old = load("old", "/tmp/old_app.py")
for label, R in (("upstream", "ROADMAP.md"),
                 ("LTVera", "/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md")):
    b = new.parse_roadmap_ledger(R)
    print(label, "entries:", len(b))
    c = collections.Counter(x["gh_number"] for x in b if x["gh_number"])
    print("  dup keys:", {k: v for k, v in c.items() if v > 1})
    # every row: does the key, the doc pointer and the URL agree with the source line?
    for x in b:
        ...  # your assertions here
PY
```

Then go further than the existing suite does: write your own fixtures for shapes neither ledger
contains yet.

## Questions — answer each, numbered, with `file:line` citations

1. **Find a ledger-entry shape that still parses wrong.** Either real (in one of the two
   `ROADMAP.md` files) or plausible (a shape a maintainer would reasonably write). For each:
   the input line, the field that comes out wrong, and what it should be. This is the question
   that matters most — the previous two reviews each missed one.

2. **`_roadmap_gh_number()` / `_ROADMAP_MULTI_KEY_RE`.** The separator set is
   `(?:[/,+&]|\.\.\.?)`. Dashes were deliberately excluded, on the grounds that
   `GH-100 — 2026 planning` is a single-issue title. Is that trade-off right? What does
   `GH-135–140` (en dash) do today, and does it matter? Is there a discriminator that gets
   both cases right, or is the exclusion genuinely the correct call?

3. **`_roadmap_issue_url()` precedence.** Branch (c) — when `gh_number is None`, take the first
   URL on the first line only. Justify or attack it. Under what real ledger shape does branch (c)
   store a wrong URL? Note `raw.splitlines()[0]` is the bullet's first *physical* line: what
   happens to an entry whose link target wraps, or whose first line ends mid-link?

4. **`_is_doc_pointer()`.** It rejects `://` and a leading `//`, and requires the pre-`#` part to
   end `.md`. Attack it: a Windows path, a `mailto:`, a bare `#anchor`, a query string
   (`doc.md?raw=1`), an empty pre-anchor part, a path with a space. Which of these reach the
   `doc_path` column, and does any of them matter?

5. **The `roadmap-empty-parse` guard in `cmd_roadmap_sync`.** It re-reads the file with its
   *own* `^##\s+Ledger\s*$` detection, separate from `parse_roadmap_ledger`'s. agy asserted they
   "match exactly." **Verify that independently** — construct a `ROADMAP.md` where the two
   disagree, if one exists. If the guard can be made to miss, the table gets deleted, which is
   the exact failure this branch exists to prevent. Also assess the missing `--allow-empty`
   override: dead end, or correct fail-safe?

6. **Interaction between the guard and the fixes.** Phase 2/3 made the parser return `None` for
   more titles than before (umbrella and range headings). Can a ledger now exist that parses to
   a *non-zero* number of entries where every one is un-keyed — and if so, what does
   `roadmap sync` do with rows that have no `gh_number`? Trace the actual DB path, don't assume.

7. **Section 7 of the suite** parses this repo's own `ROADMAP.md` on every run and fails on any
   duplicate GH key. Would it *actually* have caught the Phase 1 regression? Is a duplicate-key
   assertion the right invariant, or is it catching a symptom while a whole class of mis-keying
   (a wrong-but-unique key) still passes silently? Propose a stronger invariant if there is one.

8. **Where do you disagree with agy?** It rated the branch PASS with one minor finding. Name
   anything it got wrong, waved through, or asserted without checking. Its answers to Q4
   (`URL_EXTRACT_RE`'s second caller at `utils/py/releases_app.py:1886`, the legacy `GH_URL`
   import path) and Q7 (guard durability) are the two most assertion-heavy — start there.

9. **The non-parser parts of the branch.** `validate.sh` registry entry,
   `relay-automation/hooks/security-scan-baseline.txt` addition, `CHANGELOG.md`, and the PDDA
   doc. Both `test/gh306-registry-bidirectional.sh` and `test/security-scan.sh` were **red** on
   this branch before Phase 2 and neither prior review caught it. Is anything else in the branch
   red, unregistered, undocumented, or over-engineered?

## Verification already run

- `test/gh349-releases-roadmap-vendored.sh` — 32 passed, 0 failed
- `bash validate.sh --auto origin/development` — 305 / 305 suites passed, exit 0
- `utils/pdda/pdda.sh run` — 0 errors

**Do not treat these as evidence of correctness.** Phase 1 was green and shipped a blocking
regression. Read the code and test it yourself.

## Deliberately out of scope

`LTVera-Pandas/ROADMAP.md` has two entries keyed `GH-199`, so `roadmap sync` there refuses with
`roadmap-duplicate-gh`. That is a data condition in that repo. Do not file it as a branch defect —
but DO say if you think one-row-per-GH-key is the wrong design constraint.

## Your output

Answer all nine with `file:line` citations. Rank findings **blocking / major / minor**. A finding
with a concrete failing input beats a stylistic observation — if you can produce the input line
that breaks it, give it. If the branch is genuinely sound, say so plainly and set `STATUS:` to
`Approved`; if not, leave it `Open` with changes requested. Do not approve to be agreeable.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### codex (Reviewer) — round 1 — 2026-08-31

## Verdict: CHANGES REQUESTED

The branch still writes incorrect field values for real entries in the reporting repo. `STATUS`
must remain `Open`.

### 1. Ledger-entry shapes that still parse incorrectly

**Major — branch (c) assigns cited issues to unkeyed entries.** This is present in the real foreign
ledger, not just a synthetic edge case:

```markdown
- [Grow Willies — Tier-1 Shopify tenant onboarding](PROJECT/2-WORKING/GROW-WILLIES-TENANT-ONBOARDING.md) — ... **Phase 4 (signals) BLOCKED** on [#42](https://github.com/BinoidCBD/LTVera-Pandas/issues/42).
```

The title has no key, so `_roadmap_gh_number()` returns `None`; the own link is a document, so
`_roadmap_issue_url()` falls through to branch (c) and stores the first URL on the physical line,
issue #42 (`utils/py/releases_app.py:2832-2837,2853-2872`). That URL is a blocker, not this row's
canonical issue; GH-42 already has its own distinct ledger row
(`/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md:45,77`). The correct `issue_url`
for Grow Willies is `None`. The same defect assigns #47 to the unkeyed "Marathon Plan" row even
though the prose says #47 is merely its only fireable lane
(`/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md:81`).

**Major — the doc-pointer gate is bypassed by the regexes before it.** A plausible input such as:

```markdown
- [GH-42 — upstream design](https://github.com/acme/specs/blob/main/DESIGN.md) — external reference.
```

stores the absolute URL in `doc_path`, not `None`. The broad `doc` search accepts any non-space
target ending `.md` and wins before `_is_doc_pointer()` is consulted
(`utils/py/releases_app.py:2840-2850,2917-2925`). This is the exact value class Phase 2 claims to
have removed (`PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md:117-124,142-145`). The two
`doc` regexes and the link-target fallback need one shared relative-path validator.

### 2. Multi-key separators and dashes

**Minor — `GH-135–140` is still keyed as 135.** `_ROADMAP_MULTI_KEY_RE` covers dotted ranges but
not U+2013 EN DASH, while `_ROADMAP_KEY_RE` sees a word boundary after `135` and returns it
(`utils/py/releases_app.py:2813-2818,2832-2837`). This matters because a wrong-but-unique key is
persisted silently, while a collision makes sync refuse.

The stated trade-off conflates two different characters. `GH-135–140` uses an **en dash**, the
conventional numeric-range delimiter; `GH-100 — 2026 planning` uses an **em dash** separating the
key from prose. Add en dash between two numeric endpoints to the multi-key pattern and continue to
exclude em dash. An ASCII-hyphen form can remain conservative or be recognized only when tightly
bounded by digits; it is not necessary to sacrifice the unambiguous en-dash case.

### 3. `_roadmap_issue_url()` precedence and wrapped targets

Branches (a) and (b) are defensible: an own issue link or a URL whose terminal number corroborates
the title key is structural evidence. Branch (c) is not. The real Grow Willies and Marathon Plan
rows above prove that "first URL on the first line" often means blocker or child work, not identity
(`/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md:77,81`). For an unkeyed row whose
own target is a document, the safe result is `None`; alternatively the format needs an explicit
canonical-link marker. Merely being first is not a discriminator (`utils/py/releases_app.py:2853-2872`).

Wrapping also loses data. `m_link` uses `.` without DOTALL, and branch (c) searches only
`raw.splitlines()[0]`; if the target starts on the next physical line, or the first line ends at
`https://github.com/org/repo/` and `issues/42` continues on the next, `link_target`/the URL are not
reconstructed and `issue_url` becomes `None` (`utils/py/releases_app.py:2870-2872,2901-2907,2917`).
That is preferable to a wrong URL but should either be documented as unsupported or covered by a
multiline-link fixture.

### 4. `_is_doc_pointer()` attack

The helper does not implement its own "relative document path" contract:

- `C:\\docs\\plan.md` reaches `doc_path` (ends in `.md`); it is not a repo path on the supported
  POSIX runtime.
- `mailto:notes.md` reaches `doc_path` because the scheme lacks `://`.
- `#anchor` and an empty pre-anchor part are rejected.
- `doc.md?raw=1` is rejected because the pre-`#` value no longer ends `.md`; that is reasonable for
  a filesystem column, though it means URL-like query targets are unsupported.
- `docs/My Plan.md` reaches `doc_path` through the fallback; a plain target with spaces is accepted,
  while CommonMark's angle-bracket form is not parsed.
- `/docs/plan.md` reaches `doc_path` even though it is absolute rather than repo-relative.

More importantly, an absolute URL ending `.md` reaches the column through the preceding `doc`
regex without calling the helper at all (`utils/py/releases_app.py:2840-2850,2917-2925`). A sound
fix validates the selected candidate once, after extraction, and rejects schemes, drive prefixes,
leading `/`/`//`, and paths that escape the repository.

### 5. `roadmap-empty-parse` guard

I could not construct a lexical disagreement: parser and guard use the same stripped Ledger-header
test and the same unstripped next-`##` boundary test
(`utils/py/releases_app.py:2884-2891,3264-3275`). Even if these later drift, the existing-row query
still prevents deletion whenever `roadmap_items` contains data
(`utils/py/releases_app.py:3276-3279`). The destructive failure this guard targets is therefore
closed.

**Minor — deliberate clearing is a supported-workflow dead end.** The CLI exposes only `--dry-run`
for sync (`utils/py/releases_app.py:4720-4724`), so an intentionally empty legacy ledger cannot
clear a non-empty mirror. agy's proposed direct-SQL escape is expressly forbidden: this repo says
never hand-edit `releases.sql` or `releases.db` (`AGENTS.md:131-137`). Keep fail-closed as the
default, but add an explicit, conspicuous `--allow-empty` override (ideally requiring an empty
ledger and reporting the delete count).

### 6. All-unkeyed ledgers and the DB path

Yes. A ledger consisting only of umbrellas/ranges parses to a non-zero list, so the empty-parse
guard does not run and the duplicate-GH check skips every row
(`utils/py/releases_app.py:3263-3290`). Sync keys each such row as `("title", title)`, compares it
with the existing table, and adds/updates/removes normally
(`utils/py/releases_app.py:3307-3330,3352-3368`). Distinct unkeyed titles therefore persist.

There is an ambiguity the branch does not guard: two identical unkeyed titles both enter `adds` on
the first sync. SQLite's `UNIQUE(repo_id, gh_number)` permits multiple NULL `gh_number` values
(`utils/py/releases_app.py:583-600`), and the next sync collapses them to one dictionary key while
leaving both DB rows present. Also, renaming an unkeyed title is modeled as delete+add, so its GID
changes. At minimum, sync should refuse duplicate title keys among unkeyed parsed entries. This is
more reachable now that umbrella and range titles intentionally become unkeyed.

The one-row-per-non-NULL-GH constraint remains correct: downstream enrichment is itself keyed by
`gh_number`, and unkeyed rows are excluded (`utils/timeline/export_timeline.py:103-126`). The two
GH-199 rows in the reporting repo are therefore correctly treated as ambiguous data, not a reason
to weaken the constraint.

### 7. Section 7's invariant

It would catch the exact Phase 1 regression: the mis-keyed execution checklist became a second
GH-111, and Section 7 counts duplicate non-NULL keys
(`test/gh349-releases-roadmap-vendored.sh:183-202`; `ROADMAP.md:192`). It is still a symptom-level
invariant. A title incorrectly assigned a unique key, a wrong `doc_path`, or a wrong-but-unique
`issue_url` passes.

The stronger guard is a checked-in golden projection for representative corpora: ordered
`(title, gh_number, doc_path, issue_url)` tuples for this ledger plus a sanitized snapshot of the
foreign ledger, with intentional changes reviewed as fixture changes. At minimum, Section 7 should
assert the full title-to-key mapping, not merely "non-empty and no duplicates." Synthetic fixtures
should add negative controls for a wrong unique key, an external `.md` URL, an en-dash range, and an
unkeyed entry whose first issue URL is only a blocker.

### 8. Disagreements with agy

1. The assertion that branch (c) is safe is false. The reporting ledger itself supplies two
   counterexamples (`/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md:77,81` versus
   `relay-system/2026-08-31/gh349-phase2-review-qa.md:152-160`).
2. `_is_doc_pointer()` is not sound, and the earlier doc regex bypasses it for absolute `.md` URLs
   (`utils/py/releases_app.py:2840-2850,2917-2925` versus
   `relay-system/2026-08-31/gh349-phase2-review-qa.md:168-175`).
3. The guard regexes do match today, but "use direct SQL" is not an acceptable intentional-empty
   workflow under this repo's DB rail (`AGENTS.md:131-137` versus
   `relay-system/2026-08-31/gh349-phase2-review-qa.md:183-187`).
4. The claim that widening the shared URL regex has "zero adverse impact" on the legacy `GH_URL`
   caller is unsupported. That caller now accepts PR URLs into `gh_release_url`
   (`utils/py/releases_app.py:116,1881-1891`), while consumers label the field "GitHub release"
   (`utils/py/releases_app.py:236-255,2680-2690`). The legacy-import test checks block/import
   counts but not this field's PR semantics (`test/gh32-releases-app.sh:104-120`). Split the roadmap
   issue/PR matcher from the legacy release-field matcher, or explicitly document and test that a
   PR is valid in `gh_release_url`; do not wave the cross-caller behavior through.
5. agy's Q7 correctly noted that a unique mis-key escapes, but still passed without a field-level
   oracle (`relay-system/2026-08-31/gh349-phase2-review-qa.md:189-194,212-213`). The real branch-(c)
   errors demonstrate why that gap matters.

### 9. Non-parser branch surfaces

- Registration is present, but its comment still says `30/0` while the suite and verification
  table say `32/0` (`validate.sh:338-348`;
  `PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md:153-158`). The PDDA checklist also still
  says `30/30` at line 147. **Minor documentation drift.**
- The test header's numbered list repeats item 5 and understates the later sections
  (`test/gh349-releases-roadmap-vendored.sh:4-12`). **Minor.**
- The security baseline entry exactly matches an established test-helper pattern, so adding it is
  consistent (`relay-automation/hooks/security-scan-baseline.txt:83-89`). `eval` is unnecessary for
  a new suite, but replacing the shared idiom is not required for GH-349.
- CHANGELOG/PDDA are extensive, but their relative-doc-path correctness claim is stronger than the
  implementation because absolute `.md` URLs bypass the helper (`CHANGELOG.md:5-8`;
  `PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md:117-124,142-145`). Correct the code and add
  the missing fixtures before retaining that claim.

No project test or gate suite was run during this reviewer turn, per the relay containment
instruction. Verification was limited to read-only source/ledger inspection and standalone regex
probes that did not import or execute repository source.

## Ranked findings

| Severity | Finding |
|---|---|
| **Major** | Real unkeyed LTVera entries store blocker/lane URLs as their own `issue_url` through branch (c). |
| **Major** | Absolute/scheme `.md` targets bypass `_is_doc_pointer()` and still populate `doc_path`. |
| **Minor** | En-dash numeric ranges (`GH-135–140`) are mis-keyed as the first issue. |
| **Minor** | Intentional empty sync has no supported override; duplicate unkeyed titles are not refused. |
| **Minor** | Legacy `GH_URL` PR acceptance is a cross-caller behavior change with no contract test. |
| **Minor** | Registry/PDDA counts and the suite header are stale. |

VERDICT: CHANGES REQUESTED
