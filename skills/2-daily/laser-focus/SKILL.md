---
name: laser-focus
description: >-
  Keep a release on target while a client or product owner keeps sending new input. First lock the
  frame: discover the active target version from ground truth, ask the operator to confirm it (plus
  any deadline and the freeze mode), and require that target to be published in the repo's declared
  ledger before anything else happens (a mandatory gate; ledger writes go only through /releases).
  Optionally break the target into a consult-checked 10–20 goal checklist that makes up 100% of it.
  Then audit each client/PO statement (verbatim quote vs. inference, authorized decider, live gates)
  and place it with one ordered rule: align into the target, defer to the next point release, park
  for later, or needs a decision or trade-off. Keeps the result in one dedicated GitHub issue,
  "Laser Focus - version <T> triage <yyyy-mm-dd>", edited in place. Trigger on /laser-focus,
  "laser focus", "triage this client feedback", "what of this goes in the current release", "the PO
  changed scope again", "stay focused on <version>", or "park scope creep". Not for one blocker's
  necessity (sanity-check), day/week planning (daily-planner, weekly-planner), ledger authoring
  (releases), whether to build at all (worth-it), retrospective health (radar), or landing a branch
  (merge-cleanup).
---

# /laser-focus — lock the target, then place every new input against it

Clients and product owners change their minds mid-sprint. Without discipline, an agent turns one comment
into a priority shift, declares items unblocked without checking, deletes an option the client actually
picked, and quietly widens the release. `laser-focus` makes every placement traceable to:
- a confirmed target;
- the client's own words;
- live evidence.

**It writes in two places only:**
- its own dedicated GitHub issue in the repo being triaged (authorized by invoking the skill);
- whatever a `/releases` route you explicitly choose writes, under that route's own preview and confirmation.

**It never touches:** `releases.db` directly, other files, commits, client PR/issue threads, labels,
assignees, owners, or the provisional-decisions register.

## Usage

```
/laser-focus <PR/issue refs, pasted notes, test summaries…> [--repo owner/name]
```

## Steps

### Step 0 — Resolve the repo identity

1. Resolve the target repo (`--repo`, else the current checkout's GitHub remote).
2. Run `gh auth status`; stop if it fails.
3. Use local ledger readers **only** when the local checkout's `origin` is that repo. For a foreign
   `--repo`, use GitHub-only discovery and report the local ledger as `skipped`.
4. Never combine one repo's GitHub state with another repo's ledger.

### Step 1 — Frame lock (mandatory; the first output; read-only)

1. **Discover target candidates**, following the target repo's own source-of-truth policy (`ROUTER.md`,
   `PROJECT/PDDA.md`, or equivalent):
   - PDDA ledger repos: the read-only readers `releases next`, `releases list` and `releases show`, run through
     the repo's own CLI path (`utils/py/releases_app.py`, or `.xyz/utils/py/releases_app.py` in a
     vendored repo). If `releases.sql` exists without `releases.db`, report a gap; never rebuild.
   - Frozen files (for example a retired `ROADMAP.md`) are never read as current state.
   - All repos: open milestones, recent tags and Releases, pinned or open tracker issues, and the operator's
     own wording.
2. **Report** each source as `found` / `absent` / `unavailable` / `stale` / `conflicting`, in one short table.
3. **Ask, then stop.** Send one message with:
   - **Q1:** "Is `<T>` the overall goal? Any hard deadline or launch gate?" With zero or conflicting
     candidates, instead ask the operator to name `<T>` and its canonical ledger spelling.
   - **Q2:** "Swaps allowed, or strict freeze except for blockers and clarifications?"
   - **Scope source:** "Where is `<T>`'s current scope defined?" (ledger manifest or exit criterion,
     milestone, tracker issue, or a list from the operator).

No triage, no GitHub write, and no ledger route runs before the answers arrive. The answers form the
**frame record**: `<T>`, deadline, freeze mode, scope source, and the time zone date (default
`America/Los_Angeles`).

### Step 1b — Ledger alignment (mandatory gate; never skipped)

Triage against a target the ledger doesn't know is not grounded. Compare the frame record with the
declared ledger and classify each finding:

- **Alignment gap:**
  - `<T>` is absent from the ledger, or has an ineligible status;
  - or a row is contradicted by evidence (a CHANGELOG ship entry, or the operator's explicit statement). A merged PR is a contradiction only when its delivered scope contradicts the row. It never proves a whole release shipped.
- **Optional omission** (listed once, never gating): for example, no exit criterion. `/releases` treats
  a sparse ledger as valid.
- **Unavailable:** a source that couldn't be read. Name it.

**Gate.** Triage starts only when all three hold:
1. **Target represented:** `<T>` exists in the declared ledger with an eligible status (`draft` or
   `active`, never `shipped`), spelled as the operator confirmed.
2. **Every flagged row has a disposition:** either cleaned through a confirmed `/releases clean <version>`, or
   kept with a reason the operator supplied or explicitly approved (for example, a parallel release).
3. **Nothing invented:** no field is written to make the gate pass. A target date comes only from an
   operator-stated or sourced deadline, never from a wish to reorder `releases next`.

`releases next` is **scheduling evidence only**: it sorts `draft`/`active` rows by date, undated last.
Report it, but don't treat it as proof of which release is the target.

**Routes.** Offer only what the evidence calls for. Each route runs its own preview and confirmation:
- `/releases plan <T>` when `<T>` is absent or ineligible. It needs a tracking issue: use the operator's
  release tracker, never the dated triage issue.
- `/releases clean <version>` for each row with evidence.
- **Plain GitHub repos** (no ledger): the ledger is an open milestone or tracker issue for `<T>`.
  - If one exists, cite it.
  - If none exists, show the exact `gh` command and run it only on the operator's explicit yes. This is the single write outside the skill's own issue.

Re-check the gate with the read-only readers after any route runs.

**Not met?** Stop. State the remaining gap and the route that clears it. Declining alignment ends the run:
no triage table and no issue. The truthful alternative is to **correct the frame**, either by naming a
different `<T>` or by supplying the reason a row stays active. Never edit the ledger to match a guess.

### Step 1c — 100% goal breakdown (ask once; optional)

Ask: "Break `<T>` into a 10–20 goal checklist that together make up 100% of `<T>`?"

If yes, draft the goals from the confirmed scope source. Each goal has:
- an id `G-NN`;
- an outcome stated as observable done;
- a source (issue, PR, manifest line, or operator quote; inference is labelled);
- the live owner, or `owner: none (live)`;
- a weight;
- `check:` — a read-only check with its expected result and the condition under which it fails.

Weights total 100 and express each goal's share of `<T>`'s scope (the agreed denominator, not effort or
progress). List the explicit non-goals.

Score the draft against this rubric:

| # | Criterion | Pass when |
|---|---|---|
| R1 | Coverage (100% rule) | Every in-scope item in the scope source maps to at least one goal. |
| R2 | No overflow | No goal falls outside `<T>`'s confirmed scope; out-of-scope items appear as non-goals. |
| R3 | Mutually exclusive | No two goals claim the same deliverable. |
| R4 | Falsifiable | Each goal has an observable done state and a `check:` with expected result and fail condition. |
| R5 | Grounded | Each goal cites a live source; inference is labelled. |
| R6 | Grain | 10–20 goals; weights total 100; no goal is weighted more than ~3× another without a stated reason. |
| R7 | Ownership | Owners match live assignees and declared decision rights; unowned is stated, never guessed. |
| R8 | Non-goals | Exclusions named in the scope source are listed explicitly. |

Then QA it with the [consult](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/1-hourly/consult/SKILL.md)
skill:
1. Use its locator and the default pair, with `--out "$(mktemp -d)"` so the repo gets no files.
2. Ask the advisors to score R1–R8 pass/fail with evidence.
3. Reconcile per consult's rules, and record a disposition for every failed criterion (fixed, or accepted with a reason).
4. Show the final checklist and get the operator's approval.

If no advisor answers, say "Independent review did not run" and present the self-scored rubric.

The approved checklist is the **frozen done-list** for `<T>`, and the placements in Step 3 compare against it.
If the operator says no, the Step 1 scope source is the baseline.

### Step 2 — Harvest and evidence audit (read-only)

1. **Collect every surface:**
   - for a PR: its conversation comments, its review bodies, **and** each inline review comment (including replies within threads);
   - pasted Slack or meeting notes are tagged `excerpt-only (later replies unverified)`.
2. **One row per statement:**
   - link, author, timestamp;
   - the **verbatim quote**;
   - the **agent's inference**, in a separate column.
3. **Client intent and implementation state are separate questions:**
   - **Intent.** A priority change, removal or new requirement needs a quote from an **authorized
     decider**, per the repo's declared decision rights. The latest decision from an authorized decider wins; a
     later remark from a non-decider does not override it.
   - **State.** "Unblocked" or "done" needs live evidence: PR state, review decision, CI rollup, and merged
     into the integration branch. Merged is not deployed.
4. **Selection preservation.** Keep the option the client picked unless a later authorized decision
   explicitly supersedes it.
5. **Evidence grade.** Record n, reviewer count, and confounding (variants that differ in more than one
   variable). The grade sets **confidence**, not placement:
   - an authorized decider's choice between built variants is binding, not "n=1 evidence";
   - one reporter of a reproducible defect is enough;
   - n=1 user research cannot justify new scope.
6. **Ownership.** Read owners and assignees live; never reassign anyone.

### Step 3 — Classification: one ordered rule list

**Decision state** (intent statements only):
- `decided`: an authorized decider stated it;
- `unresolved`: deciders conflict, a decider asked a question, or the only source is a non-decider's assertion;
- `superseded`.

A decided intent with missing implementation detail is still `decided`. A **defect report** is evidence,
not a decision: it skips `C1`.

**Buckets:**
1. **Align into `<T>`**;
2. **Defer to `T+1`** (the next point release in the repo's own numbering);
3. **Park for `T+2+` or backlog**;
4. **Needs clarification or an explicit trade-off.**

Walk the table top to bottom; the **first match wins**, and each item gets exactly one code:

| Order | Code | Placement | Matches when |
|---|---|---|---|
| 1 | `R0` | record only | No new acceptance effect: restates a recorded decision, already shipped, rejected, or superseded. A selection among built options is **not** R0. |
| 2 | `C1` | bucket 4 | (Intent only.) The decision state is `unresolved`, or a non-decider dissents from a recorded decision. The decider is asked; nothing changes. |
| 3 | `A1` | bucket 1 | A **verified** launch or acceptance blocker. Under strict freeze it is labelled `freeze exception: blocker`; it is never treated as a swap. |
| 4 | `C4` | bucket 4 | A possible blocker that is not yet verified. Verify it, then re-place. |
| 5 | `A4` | bucket 1 | Descoping, or selecting among already-scoped or already-built options. |
| 6 | `A2` | bucket 1 | Resolves an ambiguity inside an existing done-list goal (or the scope source). |
| 7 | `A3` | bucket 1 | A zero-blast-radius clarification that changes no deliverable. |
| 8 | `C2` | bucket 4 | Decided, but conflicts with a constraint, spec or deadline. |
| 9 | `P2` | bucket 3 | Rests only on weak empirical evidence. An authorized decider's own choice is never P2. |
| 10 | `P1` | bucket 3 | Decided direction, but not yet specific enough to scope. |
| 11 | `C3` | bucket 4 | Specific, supported new scope under swaps-allowed: "pull X into `<T>` ⇒ defer Y", with owner and cost. |
| 12 | `D1` | bucket 2 | Specific, supported new scope under strict freeze, or a declined swap. |

Nothing falls through. An item that matches no row becomes `C1`, with the ambiguity stated as the question.

**Approved swaps revise the done-list.** When the operator approves a `C3`:
- the item moves to bucket 1;
- `G-NN` is added;
- the swapped-out goal moves to non-goals or `T+1`;
- weights are rebalanced to 100;
- the revision is logged with its date.

Bucket 1 never grows the done-list any other way.

**Worked examples:**
- An authorized PO picks an already-built variant B → `A4`, bucket 1, B preserved.
- The PO asks for a new layout with no deadline → `D1` under strict freeze, `C3` under swaps-allowed;
  `P1` if it's too vague to scope.
- A teammate who isn't a decider writes "this is now top priority" → `C1`; no priority changes.
- A single unreproduced "export is broken" report days before launch → `C4`; verify, then `A1` or `R0`.

**Each row records:**
- **id**, one per statement:
  - `pr<N>-ic<id>` (PR conversation comment);
  - `pr<N>-rv<id>` (review body);
  - `pr<N>-rc<id>` (inline review comment);
  - `issue<N>-ic<id>`;
  - `note-<sha8 of normalized quote>`.

  Add `-s<k>` when one comment carries several statements.
- quote, decision state, code, bucket;
- `claimed_severity`: what the source claimed ("urgent", "top priority"), shown next to the rule that placed it;
- the goal it maps to (`G-NN` or `none`);
- owner (unchanged), blast radius, handoff;
- `last_verified: R-NNN`. Only rows whose evidence was re-established in the current run count as fresh; carried rows say `carried`;
- for buckets 2–4: `check:` (a read-only re-verification) and `revisit_when:` (the trigger to look again).

### Step 4 — Persist to the dedicated issue

Authorization comes from invoking the skill, and covers only this issue.

**Before the first write:**
- Check repo visibility **and** outside collaborators. If the repo is public or has outside or client
  collaborators, warn once and confirm before posting verbatim internal notes.
- If that check fails, fail closed: print the body in chat and post nothing.
- Closing or editing an issue does not recall notifications or erase GitHub's edit history.

**Identity:**
- title `Laser Focus - version <T> triage <yyyy-mm-dd>`, using the frame-record date;
- first body line `<!-- laser-focus:<T-slug>:<yyyy-mm-dd> -->`, where `<T-slug>` is lowercase with non-alphanumerics turned into hyphens.
- Discover through the REST issues list with `state=all`, paginated, on `-R <repo>`. A marker match beats a title match; among duplicates, the lowest number is canonical.
- If listing or auth fails, stop and print the body in chat. Never create blind.
- After an uncertain create, rediscover before retrying.

**The first write** happens in the same turn as the first triage table appears in chat (after the gate).

**Updates are read-modify-write:**
1. re-read the body and `updatedAt` right before writing;
2. merge new rows into the existing body, keyed by statement id;
3. if the body changed since it was read, merge again or stop and show the difference. Never overwrite.

Safety assumes serialized runs; say so if two sessions might overlap.

**Body layout:**
1. the header: `Last updated <ts> · run R-NNN · Ledger gate: passed (<how>) · Done-list: <n> goals | scope-source only`, plus per-run counts (aligned / deferred / parked / needs-decision / record-only);
2. the frame record;
3. the gate result and its dispositions;
4. the done-list with its revision log;
5. the triage table.

Over about 60 KB, move older quote text into a comment and keep the rows.

**Comment mode** (only when the operator asks): post each iteration as one comment with the marker
`<!-- laser-focus-iter:<T-slug>:<date>:<N> -->`, so a retry finds it rather than duplicating it. The body
header still updates and links to the latest iteration.

**A new day means a new issue.** Link the prior `Laser Focus - version <T>` issue and carry forward its
unresolved bucket-4 rows as `carried`. Settled rows are not re-triaged.

### Step 5 — Hand off (never auto-invoke)

End with a per-bucket next step:

| Bucket | Next step |
|---|---|
| 1 | [start-task](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/1-hourly/start-task/SKILL.md), or the day queue in [daily-planner](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/2-daily/daily-planner/SKILL.md) |
| 2–3 | [`/releases plan`](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/2-daily/releases/SKILL.md) once the operator confirms placement; [idea](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/1-hourly/idea/SKILL.md) or [conveyor](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/1-hourly/conveyor/SKILL.md) for issue intake |
| 4 | the owner question, or a proposed entry for the [weekly-planner](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/3-weekly/weekly-planner/SKILL.md) provisional-decisions register (link or propose; never write it) |

Two more handoffs:
- Disputed value → [worth-it](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/3-weekly/worth-it/SKILL.md).
- Disputed blocker necessity → [sanity-check](https://github.com/HiQS-Labs/XYZ-forge/blob/development/skills/1-hourly/sanity-check/SKILL.md).

## Guardrails

- `laser-focus` never writes `releases.db` itself. Ledger changes go only through a chosen `/releases` route,
  with that route's preview and confirmation.
- The frame lock and the ledger gate come first, every run. No triage runs against an unconfirmed or unpublished target.
- Quote or it didn't happen: no priority change, removal or "unblocked" claim without the decider's words
  or live-gate evidence.
- Preserve picks, owners and assignees. Never comment on, label or edit the client's PRs or issues.
- No files and no commits; consult output goes to a temp directory outside the repo.
- Examples use placeholders (`<T>`, `T+1`). Never hard-code a product's live version numbers here.

## What it's not

- **Not `sanity-check`:** that skill asks whether one blocker is real. `laser-focus` asks which version each decision lands in.
- **Not `daily-planner` / `weekly-planner`:** those plan cadence. Their provisional-decisions protocol tracks *unresolved* decisions; `laser-focus` places decisions already made.
- **Not `releases`:** that skill authors the ledger. `laser-focus` reads it and hands writes to it.
- **Not `worth-it`:** that skill asks whether to build at all.
- **Not `radar`:** that skill looks back at delivery health.
- **Not `baseline`:** that skill turns complaints into decks; it is also why this skill calls its first step "frame lock".
- **Not `merge-cleanup`:** that skill lands branches.
- **Not `idea`, `conveyor` or `start-task`:** those handle intake and execution.
- **Replaces the never-built `/finish-line`:** it keeps that idea's frozen done-list and parked-item fields
  (`claimed_severity`, a named rule, evidence re-established each run, `check:`, `revisit_when:`).
