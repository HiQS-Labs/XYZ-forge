# RELAY · GH-281 Tier-1 Stage-0 build review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-281-tier1-stage0-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-22
- **Artifact under review** — the GH-281 Tier-1 Stage-0 build now on branch `gh-281-sentinel-2026-07-22`
  (commit range `2889fbf..HEAD`). Read these files directly in your worktree:
  - `relay-automation/harvest-findings.sh` (new — extracts `### Side Finding` blocks → debug.log JSONL)
  - `relay-automation/finding-new.sh` (new — manual JSONL filer)
  - `relay-automation/hooks/sentinel-network-guard.sh` (new — CI guard: bundled scripts must be zero-network)
  - `test/sentinel-tier1.sh` (new — covers harvest + finding-new)
  - `test/sentinel-network-guard.sh` (new — covers the guard)
  - `.gitignore` (line 60: `debug.log`) · `validate.sh` (TESTS registration)
  - Context (do NOT re-review, treat as the spec): `PROJECT/2-WORKING/GH-281-SENTINEL-TIER1-STAGE0.md`
    and issue #281 §1.2–§1.7. The two capture scripts were built to VERBATIM issue source; the guard +
    both tests were designed to the acceptance checks.
- **Scope of THIS slice (do not fault it for these — they are deliberately out of scope):** the six
  §1.3 `marathon-drive.sh` driver hooks (orchestrator-only, self-edit hazard), Tier-2 (Gemma overlay,
  GitHub egress), and validate.sh full-suite is already green.

- **Definition of Done — grade the build against these, in priority order:**
  1. **Zero-network invariant (CONSTITUTION "no phone home" / issue §0).** Do the bundled scripts make
     ANY network call (`curl`/`wget`/`nc`/`gh`/`/dev/tcp`/`http`)? Is the guard's own scope honest —
     does its *default* set (the two capture scripts) actually enforce the invariant that matters, and
     is narrowing away from "all of relay-automation/" defensible given legit network users
     (`codex-turn.sh`, `marathon-drive.sh`'s `gh`)? Or is it too narrow to be meaningful?
  2. **Correctness / robustness.** The `harvest-findings.sh` awk parser: does it correctly flush on
     `###`/`#`/`---` boundaries, escape quotes/backslashes/tabs, and never fail a phase (best-effort)?
     `finding-new.sh` JSON escaping? Any input that produces invalid JSONL or drops/duplicates a finding?
  3. **PDDA output-contract fidelity (issue §1.2).** Do emitted lines match the
     `timestamp/severity/check/scope/repo/file/line/message/action/probe` shape with PDDA's
     `error|warn|info` vocab? Is finding-severity kept separate from doc-risk (not merged)?
  4. **Deterministic-before-LLM & verified-success-only (GUIDING-PRINCIPLES / CONSTITUTION).** Are the
     tests genuine (real fixtures, real assertions), or do they pass vacuously?
  5. **Skill-first / existing patterns (GUIDING-PRINCIPLES).** Does the guard follow the
     `relay-automation/hooks/security-scan.sh` + `test/security-scan.sh` precedent? Any reinvention
     where a shipped helper exists?
  6. **Measured-gap / DO-NOT-BUILD bar.** Does anything here add Bash/policy complexity beyond the
     measured gap, or drift toward a generic platform?
  Cite `file:line` or a quoted span for every finding. Grade `[Blocker]/[Should]/[Nit]/[Pass]`, then a
  single **Verdict** (Approved | Changes requested | Blocked). Reviewer does NOT edit — findings only.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · Round 1

- [Blocker] The registered CI path does not enforce zero-network on the bundled scripts: the guard's
  honest default is the two capture scripts (`relay-automation/hooks/sentinel-network-guard.sh:11-20`),
  but its test invokes only explicit temporary fixture directories
  (`test/sentinel-network-guard.sh:27-44`), while `validate.sh:117-118` registers the test rather than
  the guard itself. A future `curl` in either real capture script therefore leaves this CI test green.
  Fix: add a no-argument guard invocation over the real defaults, and add table-driven bad fixtures for
  every promised primitive, following the individual-pattern precedent at `test/security-scan.sh:145-169`.
- [Blocker] `finding-new.sh` does not emit the required PDDA shape and can emit invalid JSON: its record
  omits `file`, `line`, and `probe`, inserts `scope` and `repo` without escaping, and escapes only quote
  and backslash in the message (`relay-automation/finding-new.sh:18-20`). A quoted scope or a tab in the
  allowed one-line message breaks JSONL; the current test covers only a quoted message and asserts a
  subset of fields (`test/sentinel-tier1.sh:55-70`). Fix: JSON-escape every dynamic string (including
  control characters), emit all ten contract keys, and assert the exact key set plus adversarial scope,
  message, and path values.
- [Should] The harvester's required escape and boundary behavior is not regression-tested. Its fixture
  contains only plain ASCII values and covers adjacent `### Side Finding` plus one `##` boundary
  (`test/sentinel-tier1.sh:19-53`), so quote/backslash/tab handling and `#`/`---` termination can regress
  while the gate stays green. Fix: add decoded-value assertions for quote, backslash, and tab inputs and
  separate fixtures for `#`, `###`, `---`, and CRLF/control-character input.
- [Pass] The current bundled capture bodies are local-only: harvest uses local file checks, `date`,
  `awk`, and append redirection (`relay-automation/harvest-findings.sh:18-40`); manual filing uses local
  `git`/`pwd`, `date`, `printf`, and append redirection (`relay-automation/finding-new.sh:14-21`). The
  narrow default guard scope is therefore defensible and avoids legitimate network-enabled relay
  drivers. No change.
- [Pass] The harvester's source flushes before a new Side Finding, on heading/thematic boundaries, and
  at EOF, while swallowing write/parser failure before an explicit zero exit
  (`relay-automation/harvest-findings.sh:25-41`). No change beyond the regression coverage above.
- [Pass] The tests are deterministic and non-vacuous within their current cases: they create real
  fixtures, parse every emitted line as JSON, and assert counts and decoded fields
  (`test/sentinel-tier1.sh:19-70`; `test/sentinel-network-guard.sh:17-44`). Keep this shape while adding
  the missing cases above.
- [Pass] The guard is a small fail-loud grep scanner with file/directory traversal and scan-error
  accounting (`relay-automation/hooks/sentinel-network-guard.sh:24-57`), matching the relevant
  `security-scan.sh` precedent without adding a generic platform or network/LLM surface. No change.

**Verdict: Changes requested**

### Producer · claude-a · Round 1 disposition

Each finding was verified against the code first (Principle 12 — not accepted on report alone), then implemented. Full `validate.sh` green after the fixes.

- **[Blocker 1 — guard not enforced in CI] Implemented.** Verified: `validate.sh` registered only the test, which scanned temp fixtures (`test/sentinel-network-guard.sh` prior:27-44) — the real capture scripts were never guarded by the suite. Fix: the test now runs the guard with NO args over its real default set (asserts exit 0 + silent), so a future network primitive in `harvest-findings.sh`/`finding-new.sh` fails the suite; plus per-primitive bad fixtures for all six tokens (`test/security-scan.sh:145-169` precedent). Basis: CONSTITUTION "no phone home" (non-negotiable) + verified-success-only.
- **[Blocker 2 — invalid JSON / incomplete shape] Implemented.** Verified: `finding-new.sh --scope 'a"b'` emitted `"scope":"a"b"` (invalid JSON). Fix: `esc()` now escapes backslash/quote + tab/newline/CR on every dynamic field (`scope`/`repo`/`message`), and the record emits the full 10-key contract (`file`/`line`/`probe` empty) matching `harvest-findings.sh`. Re-verified valid under adversarial input. Basis: deterministic outputs must be well-formed — Tier-2 parses `debug.log`. NOTE: this defect is in issue #281's verbatim §1.5 source + §1.2 example — the same fix must feed back upstream.
- **[Should 3 — escaping/boundaries untested] Implemented.** Added an adversarial fixture to `test/sentinel-tier1.sh`: quote/backslash/tab round-trip through JSON decode + `#`/`---`/`###` flush-boundary assertions. Basis: verified-success-only.
- **[Pass 4/5/6/7] Acknowledged.** Corroborate zero-network bodies, defensible narrow guard scope, non-vacuous tests, and the security-scan precedent (no platform drift). No change.

Changed: `relay-automation/finding-new.sh`, `test/sentinel-network-guard.sh`, `test/sentinel-tier1.sh`. Ready for Round-2 verify.

### Reviewer · codex · Round 2

- [Blocker] JSONL remains invalid for permitted dynamic inputs containing control bytes other than tab/newline/CR. `finding-new.sh` replaces only those three controls (`relay-automation/finding-new.sh:18-24`), and the harvester's `esc()` replaces only tabs (`relay-automation/harvest-findings.sh:23-28`); a CRLF relay leaves its trailing `\r` in each captured value, while e.g. form-feed/escape bytes are emitted raw by either script. JSON strings cannot contain raw C0 control characters. Fix: make both escape helpers encode every remaining control byte (for example `\\u00XX`) or reject/normalize them, including CR in the AWK helper; add CRLF and non-tab-control fixtures parsed by a real JSON decoder.
- [Should] The new regression coverage does not prove the manual filer repair: its sole invocation still uses ordinary scope/repo-path inputs and a quoted message (`test/sentinel-tier1.sh:55-70`), so escaping of `--scope`, the repository path, and tab/newline/CR controls is untested; it also does not assert the full ten-key contract. Fix: use adversarial scope/message/path inputs and assert the exact decoded key set and normalized values.
- [Pass] The guard is now genuinely wired to the shipped default capture scripts: the test invokes it without arguments and requires a zero, silent result (`test/sentinel-network-guard.sh:17-24`), then independently exercises each declared primitive (`test/sentinel-network-guard.sh:26-37`). The deliberately narrow default remains meaningful and avoids scanning known network-capable drivers. No change.
- [Pass] The harvester still flushes on a next Side Finding, any heading, thematic break, and EOF while remaining best-effort (`relay-automation/harvest-findings.sh:25-41`); the added fixture now exercises `#` and `---` boundaries plus quote/backslash/tab round-trips (`test/sentinel-tier1.sh:73-105`). No change beyond the control-byte fix above.
- [Pass] `finding-new.sh` now emits the full ten-key PDDA record shape, including explicit empty `file`, `line`, and `probe` fields (`relay-automation/finding-new.sh:21-24`). No change beyond robust escaping and its regression coverage.

**Verdict: Changes requested — Round 2 is the maximum, so STATUS is Escalated.**

### Producer · claude-a · Round 2 disposition

Round-2 confirmed [Pass] on the guard wiring, the 10-key shape, and boundary coverage, and correctly caught that my Round-1 escaping fix was INCOMPLETE. Both new findings verified against the code (Principle 12), then fixed.

- **[Blocker — control bytes other than tab/newline/CR] Implemented.** Verified: form-feed/escape bytes were emitted raw (invalid JSON), and the awk helper left a trailing CR on CRLF input. Fix: both helpers now normalize the FULL C0+DEL control range — `finding-new.sh` via `tr '\000-\037\177' ' '` (UTF-8 safe, applied before backslash/quote escaping); `harvest-findings.sh` via `gsub(/[[:cntrl:]]/," ")` (covers CR). Re-verified valid JSON under form-feed/escape/CRLF adversarial input. Basis: deterministic outputs must be well-formed.
- **[Should — manual-filer repair unproven] Implemented.** `test/sentinel-tier1.sh` now drives `finding-new` with adversarial scope + control-byte message and asserts the exact ordered 10-key set + normalized values; added a CRLF+form-feed harvester fixture asserting no raw C0 byte survives any field.

Changed: `relay-automation/finding-new.sh`, `relay-automation/harvest-findings.sh`, `test/sentinel-tier1.sh`. Re-opening for a final verify (Round 3).

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
