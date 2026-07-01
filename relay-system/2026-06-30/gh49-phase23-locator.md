# RELAY · GH-49 Phase 2+3 — .xyz locator preference + staleness banner
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-30.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh49-phase23-locator): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- **Deliverable (Producer edits ONE file):** `skills/relay-xyz/find-harness.sh` — add a vendored `.xyz/` preference + a staleness banner.
- Reviewer: agy   ·   Producer: codex
- Started: 2026-06-30
- **Spec:** `PROJECT/2-WORKING/GH-49-VENDORED-LOCAL-COPY.md` → "Phase 2 — locator preference chain" and "Phase 3 — staleness gate (warn loudly, continue)". Read both + their QA checklists.
- **Decision (binding):** `decisions/2026-06-30-vendored-harness-locator.md` — staleness posture is **warn-loudly-continue, NEVER block**; the default (no-`.xyz/`) path must stay **byte-for-byte unchanged**.
- **Context:** `relay-automation/xyz-vendor.sh` (just shipped) writes `<repo>/.xyz/` containing `relay-automation/relay-drive.sh`, `bin/tick`, `src/*.js`, and a `VERSION` file with `source_commit=<sha>` / `tick_version=` / `vendored_utc=`. This is what the locator must prefer + staleness-check against.

### Producer brief — edit `skills/relay-xyz/find-harness.sh`

The current resolution order (read the file) is: (1) env override `$XYZ_HARNESS`/`$XYZ_REPO_ROOT` → (2) current git repo root → (3) this script's own location (`…/<repo>/skills/relay-xyz` → `<repo>`). `_has_harness()` tests `-x "$1/relay-automation/relay-drive.sh"`. Add, minimally and bash-3.2-safe (no `readlink -f`, no assoc arrays; match the file's existing style):

**Phase 2 — `.xyz/` preference (new step, slots AFTER env override, BEFORE the current-git-repo step):**
- Compute the caller's repo root (`git rev-parse --show-toplevel`, fall back to `$PWD` if not in a repo). If `<caller-root>/.xyz/` is a valid vendored harness — i.e. `_has_harness "<caller-root>/.xyz"` (relay-drive.sh present) **and** `bin/tick` present under it — set `HARNESS="<caller-root>/.xyz"`.
- **Gating is critical:** the `.xyz/` branch must be taken ONLY when that `.xyz/` exists. No `.xyz/` ⇒ resolution must be **byte-for-byte identical** to today (env still #1; then current-git-repo; then script-relative). An explicit `$XYZ_HARNESS`/`$XYZ_REPO_ROOT` still wins over a present `.xyz/`.
- Record that we resolved to a vendored copy (e.g. a `VENDORED=1` flag + the resolved `.xyz` path) so Phase 3 + `--check` can report it.

**Phase 3 — staleness banner (warn loudly, continue — NEVER block):**
- Only when `HARNESS` resolved to a `.xyz/` (VENDORED=1): try to find a **reachable live harness OTHER than the `.xyz/`** — the script's own location (step 3: `…/skills/relay-xyz` → `<clone>`) is the natural one; `_has_harness` it. Env override, if set and not the `.xyz`, also counts.
- If such a live harness is reachable, read `source_commit` from `<.xyz>/VERSION` and compare to the live harness HEAD (`git -C <live> rev-parse HEAD`):
  - vendored commit **== live HEAD** → current → no banner.
  - vendored commit is an **ancestor** of live HEAD (`git -C <live> merge-base --is-ancestor <vendored> HEAD`) → **behind** → print a loud multi-line banner to **stderr** naming the vendored short-SHA, the live short-SHA, and the remedy `xyz-sync --update <repo>` (the command name is fine even though xyz-sync is Phase 4).
  - any other case (diverged / unknown / missing VERSION / git error) → a softer one-line "vendored copy differs from / can't be compared to the live harness" note; **never error, never block**.
- **No reachable live harness** (the WIP/offline case) ⇒ **no banner at all**, resolve to `.xyz/` silently.
- All staleness logic must be **fail-open**: wrap git calls so any failure ⇒ no banner, exit paths unchanged. The banner goes to **stderr** so `--root`/`--env` **stdout stays clean and machine-parseable** (eval-safe).
- Surface the vendored + staleness state in the `--check` human output too.

**Do NOT** change the `--root`/`--env`/`--check` stdout contract for the no-`.xyz/` case, edit any other file, or add a hard failure/exit on staleness. Keep the diff tight.

## Definition of Done (Reviewer grades against this)
1. **Default path byte-identical:** with no `.xyz/` present, `find-harness.sh --root` and `--env` produce exactly today's output and the same resolution order (env → current-git-repo → script-relative). This is the #1 gate.
2. **`.xyz/` preferred when present:** standing in a repo that has a valid `<root>/.xyz/`, the locator resolves `HARNESS` to `<root>/.xyz` — unless `$XYZ_HARNESS` is set (which still wins).
3. **Staleness = warn-continue:** a `.xyz/` behind a reachable live harness prints a loud stderr banner (vendored SHA, live SHA, `xyz-sync --update` remedy) and STILL resolves/exits 0; a current `.xyz/` prints nothing; **no `.xyz/` case can ever block or non-zero-exit** on staleness.
4. **No reachable harness ⇒ silent** resolve from `.xyz/` (no banner).
5. **stdout clean:** `--env` output is still pure `export …` lines (banner only on stderr); `bash -n` clean; bash 3.2-safe; fail-open on every git call.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer — codex — Round 1 (turn killed off-lane; surviving edit gate-verified by claude-a)
Process note (honest): codex's produce turn **exceeded the 480s wall-clock cap and was killed**, and it
also created an **off-lane** `PROJECT/1-INBOX/SELF-HEALING.md` which **containment reverted** (exit 6).
So this turn did not self-append or hand off. However, the edit to the **allowlisted** file
`skills/relay-xyz/find-harness.sh` was copied back and is coherent + complete. Rather than discard good
work, claude-a (orchestrator) **independently verified it by execution** before committing (GUIDING #12),
then recorded it here and hands to the Reviewer.

- Implemented (in `skills/relay-xyz/find-harness.sh`, +98/-4):
  - `.xyz/` slotted as resolution step 2 (env → **.xyz/** → current-git-repo → script-relative); gated on
    `_has_vendored_harness` (relay-drive.sh **and** bin/tick present). Env override still wins.
  - Staleness (Phase 3): when resolved to `.xyz/` and a live harness is reachable (env or script-relative,
    ≠ the `.xyz/`), compares `.xyz/VERSION` `source_commit` to live HEAD — `current`→silent,
    ancestor→**behind** loud stderr banner (vendored/live SHA + `xyz-sync --update <repo>`), else→soft
    "differs" note; no reachable harness→silent `standalone`. All git calls fail-open; banner is stderr-only.
  - `--check` surfaces the vendored + staleness state.
- claude-a verification (execution, sandbox-off):
  - **Default byte-identity (#1 gate):** with no `.xyz/`, `--root`/`--env`/`--check` **stdout AND stderr
    are byte-identical to HEAD** (baseline vs edited, same CWD).
  - **Positive:** standing in a vendored scratch repo resolves to `<root>/.xyz`; `VERSION=liveHEAD`→no
    banner; `VERSION=ancestor`→behind banner on stderr with `--env` exit 0 and **stdout still pure
    `export` lines**; `XYZ_HARNESS` override wins over a present `.xyz/`; `.xyz/` with no reachable live
    harness → silent standalone. `bash -n` clean.
- Verdict for reviewer: ready for review against the Phase 2+3 DoD. Please independently confirm the
  default-path byte-identity claim and the never-block staleness posture.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
