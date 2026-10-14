# RELAY · Final QA: hiqs-ai-resolve GH-49 rename + network doc
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(hiqs-gh49-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh49-final.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-hiqs-ai-resolve/e1cc774f-3230-482b-8148-e7d7414b4fa4/scratchpad/gh49-final.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-14
- Definition of Done: the committed change (artifact = `git diff -M origin/main..HEAD`) implements the
  Codex-approved plan `docs/issue-49/plan.md` (plan QA: `relay-system/2026-10-14/hiqs-gh49-plan-qa.md`, Approved r2)
  and satisfies issue #49, with honest evidence.

### Operational envelope & non-goals
Documentation + skill-folder rename in a private single-maintainer repo (Lovable-synced `main`). No runtime code
change (#50). No new tests. Grade against the plan, not unrequested machinery. READ-ONLY: write only this relay file.

### Read (absolute paths, read-only)
- Task clone at HEAD ae7a29e: `/Users/noelsaw/Documents/GH Repos/hiqs-ai-resolve-gh49-hiqs-skill-rename-2026-10-14`
  (`docs/issue-49/plan.md`, `docs/issue-49/durability-probe.md`, `skills/hiqs-research/SKILL.md`,
  `skills/hiqs-image/SKILL.md`, `skills/hiqs-chain/SKILL.md`, `CHANGELOG.md`, `consumer/chain.ts:220-325`).
- Probe raw output: `/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-hiqs-ai-resolve/e1cc774f-3230-482b-8148-e7d7414b4fa4/scratchpad/durability-probe/`.

### Producer's verification evidence (re-run any of these read-only)
- `git grep -n -E 'resolve-research|resolve-image' -- 'skills/*.md'` → only the two "formerly" notes.
- `git diff --quiet origin/main -- skills/hiqs-chain/assets/image-manifest.json` → unchanged.
- Red control: substituting `../resolve-image/SKILL.md` back into a copy of hiqs-chain/SKILL.md makes the grep count 1.
- Frontmatter `name:` equals folder for both; `../hiqs-image/SKILL.md` link resolves; one `## Network requirement` heading
  (moved to end of file so it does not swallow the following "Return one JSON object" paragraph).
- skills-army-hq `intake.py add <clone>/skills/hiqs-{research,image}` previews: success (no apply).
- Durability probe: pass (see durability-probe.md).

### Questions
1. Does the diff match the approved plan step by step (renames, name/title/canonical lines, hiqs-chain description + link,
   network section wording incl. the "clue, not proof" caveat, wrapper pointers, CHANGELOG)? Anything missing or extra?
2. Is the network section accurate against `consumer/chain.ts` and is the anchor link `#network-requirement` valid?
3. Is the durability-probe record honest and does it support the claim that the doc guidance works for a sandboxed agent?
4. Any accidental files, whitespace, or broken Markdown?

Cite file:line for every finding. Set STATUS: Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Ship.

VERDICT: PASS

Basis: The seeded diff implements the approved documentation/rename plan. The network guidance preserves diagnostic uncertainty, and the recorded fresh-agent probe is supported by its raw transcript. No required correction found; this approval covers the reviewed artifact, not deployment or an unrun runtime gate.

swept file: yes

Read the entire `.relay-artifacts/gh49-final.diff`, all six resulting changed files (including the complete skill files and CHANGELOG), approved plan-QA record, relevant `consumer/chain.ts:220–325`, and raw probe transcript/final message. No additional pre-existing defect found in the affected files. Source paths below are relative to task clone `/Users/noelsaw/Documents/GH Repos/hiqs-ai-resolve-gh49-hiqs-skill-rename-2026-10-14` (`R`). Raw probe directory (`P`) is `/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-hiqs-ai-resolve/e1cc774f-3230-482b-8148-e7d7414b4fa4/scratchpad/durability-probe`.

- **[Pass] Rename and scope match the plan.** `skills/hiqs-research/SKILL.md:2`, `:6`, `:16` and `skills/hiqs-image/SKILL.md:2`, `:6`, `:41` update names, titles and canonical paths while retaining former names. Runtime description/link are updated at `skills/hiqs-chain/SKILL.md:3`, `:18`; `CHANGELOG.md:5` records the change. The artifact has exactly six diff sections: CHANGELOG, the plan, probe record and three skill files; no runtime, bundle or manifest section. A read-only Python scan of all skill Markdown returned exactly `hiqs-image/SKILL.md:41` and `hiqs-research/SKILL.md:16` for old names. Both frontmatter names equal their folder names, and both old folders are absent. This meets `docs/issue-49/plan.md:35–40` without rewriting historical evidence.

- **[Pass] Canonical network guidance and links are correct.** `skills/hiqs-chain/SKILL.md:24–28` contains one Network requirement section after the JSON/reporting paragraph; the wrapper pointers at `skills/hiqs-research/SKILL.md:12` and `skills/hiqs-image/SKILL.md:33` resolve to its heading. All five local Markdown links in the three skill files resolve. The wording “Diagnostic clue, not proof” matches `consumer/chain.ts:306–318` (dispatch precedes fetch; non-timeout transport errors map to `contract_rejected`) and `:243`, `:314`, `:321–323` (response-shape rejection can omit HTTP status too). No runtime classifier fix is implied. In-memory red control, command `python3 -c 'from pathlib import Path; import sys; s=Path(sys.argv[1]).read_text(); print(s.count("../resolve-image/SKILL.md"), s.replace("../hiqs-image/SKILL.md","../resolve-image/SKILL.md").count("../resolve-image/SKILL.md"))' "$R/skills/hiqs-chain/SKILL.md"`; the equivalent expression in the combined read-only probe exited **0**, decisive output `STALE-LINK CONTROL: 0 -> 1`. No artifact was mutated.

- **[Pass] Durability record supports its bounded claim.** `docs/issue-49/durability-probe.md:5`, `:9`, `:13–30` records a sandboxed agent that reports failure and recommends network-enabled execution rather than asserting a contract bug. Raw `P/transcript.log:8` records `sandbox: workspace-write`; `:87` records runtime exit 4; `:96–97` record two `ENOTFOUND` results; `:106`, `:115` preserve diagnostic uncertainty and subsequent contract investigation. The final message is verbatim and both copied skill documents equal the reviewed files. Probe command: `python3 -c 'from pathlib import Path; import sys; r,p=map(Path,sys.argv[1:]); d=(r/"docs/issue-49/durability-probe.md").read_text(); q="\n".join(x[2:] for x in d.splitlines() if x.startswith("> ")); assert q and q==(p/"last-message.md").read_text().rstrip("\n"); assert all((r/"skills"/n/"SKILL.md").read_bytes()==(p/"skills"/n/"SKILL.md").read_bytes() for n in ("hiqs-research","hiqs-chain")); print("PASS: verbatim final message; both probe skills equal reviewed files")' "$R" "$P"`. Exit **0**; decisive output `PASS: verbatim final message; both probe skills equal reviewed files`. This is one successful diagnostic-guidance probe, not proof of universal agent behavior or successful provider execution.

Limitations: Graph Verify lookup found only the other checkout's `hiqs-ai-resolve` generation `2026-09-12T03:16:16Z`; chain lookup returned zero, and coverage reported untracked/missing/excluded paths. Direct source reads supplied review evidence. Intake previews are producer-reported, not independently rerun. No Git command, test suite, executable fixture, new agent run, paid request or deployment was performed. Runtime remeasurement is **[Unverified — needs clone run]**; the harness gate remains separate. Only this relay file was edited.

Relay closed (Approved), no further turn needed. Producer (claude-a) receives the completed review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
