# RELAY · GH-268 item 9 — cross-vendor relay re-test: does the item 7+8 change hold up under a second vendor
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-28.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh268-item9-crossvendor-retest): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh268.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/470800c2-5919-46da-80b9-1e63ee237bde/scratchpad/gh268.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-28
- Definition of Done: this relay IS GH-268 item 9 — the cross-model re-test the beta report asked
  for. You are the second vendor. Codex already reviewed this change as a Consult and found two
  Blockers, both now fixed. **Do not repeat Codex's findings** (listed below); the value of a second
  vendor is what the first one missed.

### Why this relay exists

GH-268's report: *"The Codex and Antigravity CLIs were not installed/authenticated... The run was
therefore Claude-reviewing-Claude, which shares blind spots — the weakest configuration for catching
issues and the likely reason 1 of 9 pre-existing defects surfaced."* Both CLIs are live now. This is
the re-test.

### What the change is

Items 7 + 8 of the same report:
- Every relay turn must end with an explicit hand-off cue naming who acts next (the report: the
  Reviewer turn never told the user to return to the Producer window).
- The reviewer is told pre-existing defects in a touched file are in scope, and must emit a literal
  `swept file: yes|no` line.
- `relay-automation/target-checks.sh` runs a *foreign* repo's own checks (php -l, phpcs, npm, pytest,
  ruff, make test) so a cross-repo lane has a real gate. `utils/py/marathon_drive.py` wires it in
  automatically when `--target-root` is set and the target has no `validate.sh`.

### Already found by Codex — do not re-report

1. `[Blocker]` a target that HAS its own `validate.sh` was gated on the **harness's** one instead. Fixed.
2. `[Blocker]` `vendor/bin/phpcs` (how WordPress plugins actually install PHPCS) was skipped as
   "not installed", so `php -l` alone passed the gate. Fixed via `resolve_tool()`.
3. `[Should]` relative `--target-root` resolved twice. Fixed.
4. `[Should]` `php -l`/PHPCS cannot mechanically catch the report's two named defects. Acknowledged
   in the docs rather than overclaimed.

### Grade these

- **The fixes for 1 and 2 above** — are they actually correct, or did they introduce something new?
  `resolve_tool()` does a prefix substitution on the command string; is that sound for every entry in
  the `CHECKS` table?
- **Where can `target-checks.sh` still report success while meaningfully nothing was checked?** Codex
  found the vendor/bin case. Find a *different* one, or say plainly that you cannot.
- **`--strict` on the auto-wired path only.** Right call, or does it make cross-repo lanes fail on
  machines that simply lack a linter?
- **Anything in the two relay templates that is now wrong, contradictory, or unfollowable** — you are
  an agent who has to obey these instructions, so this is the one thing you can judge better than a
  human reviewer can.
- **The `find`/`xargs` in the php-lint command** — quoting, empty-match behaviour, exit-code
  propagation.

Cite `file:line`. Uncited `[Pass]` findings are downgraded per the ground rules.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

**Verdict:** Changes requested
**swept file: yes**

- **The fixes for 1 and 2 above**
  - `[Blocker]` The prefix substitution `cmd="${resolved}${cmd#"$tool"}"` is fatally flawed when the tool is not the first word. For `php-lint`, `$cmd` starts with `find .`, so `${cmd#"$tool"}` does nothing, resulting in `/path/to/phpfind . ...` which will fail with "command not found".
  - **Fix**: Only perform the substitution if the command actually starts with the tool name (e.g. `[[ "$cmd" == "$tool "* ]]`), or structure the checks array so the tool path substitution is done safely.
- **Where can `target-checks.sh` still report success while meaningfully nothing was checked?**
  - `[Blocker]` If a project defines multiple checks (e.g., `php-lint` and `phpcs`), but `phpcs` is missing, `phpcs` is skipped while `php-lint` passes. `ran=1, failed=0, skipped=1` produces a 0 exit code (a "green" gate). The WordPress-security ruleset is silently bypassed.
  - **Fix**: The script should exit 1 if *any* detected check is skipped, or properly track required vs optional checks.
- **`--strict` on the auto-wired path only**
  - `[Pass]` This is the right call. A cross-repo lane verifying a foreign repo should fail loudly if the target expects a linter but the harness lacks it, preventing silent false greens. Operators wanting leniency can manually supply `--pre-advance-cmd`. (Citation: `utils/py/marathon_drive.py:289`)
- **Anything in the two relay templates that is now wrong, contradictory, or unfollowable**
  - `[Blocker]` In `utils/py/marathon_drive.py:677-678`, when `is_consult` is true, the template tells the Producer to "Implement the brief by creating/editing the artifact file(s): `<the diff file>`". Telling the Producer to apply fixes by editing the read-only `.diff` file itself is unfollowable and contradictory.
  - **Fix**: Instruct the Producer to edit the actual underlying source files, not the diff artifact.
- **The `find`/`xargs` in the php-lint command**
  - `[Blocker]` Empty-match hang: `xargs` without `-r` (or `--no-run-if-empty`) on GNU systems runs the command once even if there is no input. If `find` returns nothing, `php -l` runs with no arguments and hangs indefinitely waiting for `stdin`, permanently blocking the lane.
  - `[Should]` Exit code masking: `bash -c "$cmd"` does not inherit the script's `set -o pipefail`. If `find` fails (e.g., permission denied), its exit code is swallowed and the pipeline falsely passes.
  - **Fix**: Add `-r` to `xargs` (`xargs -0 -r -n1 php -l`) and prepend `set -o pipefail; ` inside the `bash -c` command string.

---
handing off to Producer — Producer, take your turn.

### Producer (r1)

Four Blockers raised. Three real and fixed; one is a false positive, declined with evidence. Every
finding was checked against source before I acted on it.

* **[Blocker] prefix substitution mangles a command whose tool is not the leading word —
  Implemented.** Correct and reproduced exactly as described:
  `${resolved}${cmd#"$tool"}` with `tool=php` and a command starting `find` yields
  `/vendor/bin/phpfind . -name ...`. Substitution is now guarded by `[[ "$cmd" == "$tool "* ]]`; when
  the tool resolves project-local but is not the leading word, its directory is prepended to `PATH`
  for that command instead of splicing the string. Latent rather than live — it needs `php` resolved
  under `vendor/bin` — but it would have failed a gate for a reason having nothing to do with the
  code under review, which is the worst kind of gate failure.

* **[Blocker] `xargs` empty-match hang — Implemented.** The sharpest finding here, and one I could
  not have hit locally: BSD/macOS `xargs` does not run on empty input, GNU does, so `php -l` with no
  arguments would read stdin and **hang the lane indefinitely** — on ubuntu CI, not on this machine.
  `-r` added (accepted as a no-op on macOS, so it stays portable).

* **[Should] `bash -c` does not inherit `pipefail` — Implemented.** Correct: a `find` that fails on a
  permission-denied subtree would be masked by a passing `xargs` and the gate would report green.
  `set -o pipefail;` now prefixes the command string.

* **[Blocker] the consult-mode template tells the Producer to edit the read-only `.diff` —
  DECLINED, not real.** `grep -n is_consult utils/py/marathon_drive.py` returns **nothing**; there is
  no consult mode in that file. The cited lines 677-679 are `if args.artifact_paths:` /
  `claim_paths` / `builder_impl_line`, and `--artifact` is marathon-drive's list of **writable source
  paths** for the builder. The read-only `.diff` seed is `--artifact-file`, a *different flag on a
  different script* (`relay-drive.sh`). Two similarly-named flags were conflated. Worth recording
  rather than quietly dropping: a cross-vendor reviewer reading a 341-line diff will sometimes
  reason confidently about a file it only half-remembers, so a cited `file:line` is necessary but
  not sufficient — I verified this one and it did not survive.

* **[Blocker] a skipped check still yields a green gate — Declined as stated, already mitigated.**
  This restates what Codex raised, and the blanket prescription ("exit 1 if *any* detected check is
  skipped") would break the documented lenient mode: a developer running this by hand on a machine
  without every linter should not be hard-blocked. What is actually load-bearing is the case where
  **nobody chose the gate** — and there the harness already passes `--strict`
  (`utils/py/marathon_drive.py`), so a detected-but-missing tool fails. A lenient run now also prints
  `PARTIAL GATE` and states that exit 0 means "what ran, passed", not "checked". If that proves
  insufficient in practice, the right fix is a distinct exit code for partial, not removing the
  lenient mode.

* **[Pass] `--strict` on the auto-wired path only** — agreed, and it is cited correctly.

**Six new regression cases** pin the three implemented findings, including that `phpfind` can never
reappear and that `-r`/`pipefail` stay in the emitted command. 29 → **34 pass, 0 fail**.

**On the re-test itself (this is GH-268 item 9's actual result):** two vendors reviewed the same
change and their findings did not overlap once. Codex found the wrong-`validate.sh` selection and
the `vendor/bin` skip; agy found the substitution bug, the `xargs` hang, and the `pipefail` mask.
Neither found the other's. That is direct evidence for the multi-model claim the original beta test
could not evaluate — and the `xargs` hang in particular is a defect this machine's own OS would have
hidden until CI.

Also worth stating: this relay is the first real use of the item 7 + 8 changes, and both worked —
the review block carries `swept file: yes`, and the turn ended with an explicit
`handing off to Producer`. Neither existed before this change.

NEXT: Reviewer — please confirm the three fixes and say whether you accept the two declines.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
