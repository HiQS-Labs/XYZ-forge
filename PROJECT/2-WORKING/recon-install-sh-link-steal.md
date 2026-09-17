# Recon Map — skills/*/install.sh symlink replacement and the gate-time leak (GH-678)
Commit: 7374a1d2 (XYZ-forge development) · Mode: grep-only (no codebase-memory) · Lanes: A, B+C, D (three parallel read-only sub-agents) plus the debug-mantra trace in-session

## Subject and change class
Subject: the "if this symlink is not already mine, `rm -f` it and relink to myself" block shared by all 22 `skills/*/install.sh`, and `test/agent-chorus.sh:683-720`, which runs the real agent-chorus installer inside the gate with only two of its five target directories sandboxed.
Change class: cross-module (22 installers, 1 test, docs). No new source of truth; the managed collection and its receipts already exist and are untouched.

Two layered defects, confirmed by reproduction and three same-day incidents:
- **Trigger (regression since 2026-08-23, commit 9be6f70f, #193):** the installer gained three Gemini targets and the test's env override was not extended. Every gate run on every clone repoints the three real `~/.gemini/**/skills/agent-chorus` links to that clone. Three steals on 2026-09-17 (10:21 gh666, 11:24 gh669, 14:26 pr235), each a few minutes before that clone's gate artifact. Claude Code and Codex links never move because those two are sandboxed. `test/agent-chorus.sh:680` carries a comment claiming the test never writes real user skill directories; it is false for the three Gemini paths.
- **Latent:** every installer deletes any symlink not pointing at its own clone, with no record of the old target. Real directories are backed up (5 files) or refused (17 files); symlinks, the case the managed collection creates on purpose, get `rm -f`.

## The seams — where a change here escapes this file
| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Installer ↔ test env contract | `test/agent-chorus.sh:683,696,719` set only `CLAUDE_SKILLS_DIR`, `CODEX_SKILLS_DIR`; installer reads 5 vars at `skills/agent-chorus/install.sh:73-77` | test → real `$HOME` | any target var the test does not set (this is the live defect) |
| Real-HOME defaults | `${VAR:-$HOME/...}` in all 22 | any caller without full override | CI, tests, humans running from a clone |
| HQ ownership receipts | `skills/skills-army-hq/scripts/sync.py:109-124`, `intake.py:367-371`; receipt shape `sync.py:20-22` | installer `rm -f` invalidates HQ's link; HQ only preserves + errors, never reclaims unowned | installer runs after HQ sync on the same target |
| Mini projection | `utils/py/xyz_mini_sync.py:31,39,43` ship ponytail, agent-chorus, consult installers downstream | XYZ mini repos | byte change propagates on next publish; only exec bit asserted (`test/gh589-xyz-mini-sync.sh:68`) |
| Consumer vendoring | `relay-automation/xyz-vendor.sh:350,359` copies `skills/` into consumer `.xyz/` | other repos on other machines | a consumer agent runs a vendored installer (no doc instructs it; not observed) |
| standup `--check` | `skills/standup/install.sh:21-24,36-56`; asserted `test/gh77-standup-triage.sh:753-758` | exit-code contract | template unification drops or reorders check mode |
| releases legacy aliases | `skills/releases/install.sh:32-39,42-58,65-70`; asserted `test/releases-skill.sh:71-76,88-125` | must not mention `.codex`; idempotent path must still retire aliases; real dir → rc 1 | refuse logic applied to the alias loop, or a Codex path introduced |
| agent-chorus legacy repoint | `skills/agent-chorus/install.sh:24-42` (`ln -sfn`); asserted `test/agent-chorus.sh:713-715` | dangling `agent2agent` → `agent-chorus` | repoint semantics change |
| relay-xyz failure semantics | `skills/relay-xyz/install.sh:19` is `set -u` only, no rc aggregation, exit always 0 | operator sees stderr only | a fix assumes `set -e` behaviour |
| Function-scope errexit | 5 `install_one` installers call `f || rc=1`; a failed `rm -f`/`ln -s` inside falls through to "installed", returns 0 | false success | any fix that keeps that shape and relies on the exit code |

## Call paths in
- Human: `README.md:248-250` (relay-xyz, hq, agent-chorus), `skills/relay-xyz/SKILL.md:75`, `skills/hq/SKILL.md:21`, `skills/10days/SKILL.md:99`, `skills/agent-chorus/README.md:30`, `skills/vendor-stack/SKILL.md:153`, `skills/browserbase/SKILL.md:60,189,207`, `mini/README.md:37-41`, `relay-automation/DUELING-CLAUDES.md:34` (stale path). Twelve of 22 installers have no doc mention at all. Several docs misstate which directories an installer writes (relay-xyz `SKILL.md:210` says Claude only; it writes five).
- Gate: `githooks/pre-push:52` → `utils/ci-route.sh:31,43` → `validate.sh:498` → `test/agent-chorus.sh:684,697,720` → `skills/agent-chorus/install.sh`. Also `.github/workflows/ci.yml:197,480` (runner HOME, harmless).
- Other tests: `test/gh77-standup-triage.sh:753-757` (HOME sandboxed → contained); `test/releases-skill.sh:93,109,119` (Claude-only installer, dir overridden → contained).
- No script, hook, package entry, or harness executes a per-skill installer. Zero non-test code paths.

## State
- Write sites into app skill directories: the 22 installers (`rm -f` + `ln -s`, plus `ln -sfn` in agent-chorus legacy block and `rm -f` legacy aliases in releases), and HQ `intake.py:458-464` (unlink only for links with a matching receipt; migration via temp symlink + `os.replace`). There is no single write path; the two writers do not know about each other.
- Read sites: HQ `intake.py:367-371 link_text()` on every reconcile; installers read `readlink`/`cd -P` of their own link only.
- HQ classification (`sync.py:109-124`): owned-and-matching → no-op; owned-but-retargeted → "Lost ownership; retargeted link preserved", receipt kept, link untouched; owned-but-missing → recreate; foreign-same-text → requires `--adopt`; foreign-different-text → "Foreign link preserved; review before explicit migration", requires `--migrate` (resolve to recorded source + digest match) or `--migrate-from SKILL=/local/git/skill` (operator-named source, digest skipped, records `previous`); real directory → "Foreign real entry preserved". `sync.py` never unlinks an unowned link.
- Live state on this device (2026-09-17 ~14:45): three Gemini links → `XYZ-forge-pr235-agy-qa-harness/skills/agent-chorus`; Claude Code and Codex → the Pulse collection. Under the current collection the Gemini config entry has no receipt, so it is the foreign-different-text case and `--migrate-from` is a valid scripted recovery. `~/.gemini/antigravity/skills` and `~/.gemini/antigravity-cli/skills` are not HQ targets (`targets.md:20-21` calls the first historical; the second is undocumented), so nothing manages or reclaims them.

## Contracts
- `CLAUDE_SKILLS_DIR`, `CODEX_SKILLS_DIR`, `GEMINI_CONFIG_SKILLS_DIR`, `ANTIGRAVITY_SKILLS_DIR`, `ANTIGRAVITY_CLI_SKILLS_DIR`, `AGENTS_SKILLS_DIR` (workhorse only) — env overrides — consumers: tests, humans — breaking if renamed or if a new one is added without every test setting it — declared per installer.
- Installer exit code — 5 `install_one` files: 0 iff every dest installed, 1 if any skipped; `test/agent-chorus.sh:686` asserts 0. relay-xyz: always 0. 17 inline: 0 or 1 (refuse). standup adds `--check` 0/1.
- Installer messages — no test string-matches any of them. Free to change.
- Mini payload — `xyz_mini_sync.py:189-195` byte-compares on publish; a changed installer is republished automatically.
- HQ receipt — `sync.py:20-22` `{collection, root, name, text, previous}`; validated `intake.py:265-272`. Unchanged by this work.

## Build, failure and rollback today
- Build: no build step; installers are tracked executables (`test/gh132-review-xyz-skill.sh:14` asserts exec bit on one).
- Failure: a failed `rm -f`/`ln -s` inside `install_one` reports success (errexit suppressed under `f || rc=1`); relay-xyz reports success unconditionally; `file-xyz-bug/install.sh:39-47` is the only installer that checks `ln -s`.
- Detection: none automatic. HQ `sync.py --status` reports the foreign link with exit 2 but nothing runs it on a schedule. No test asserts a suite stays inside its sandbox; `validate.sh` never fakes HOME; `test/lib/fixture-guard.sh` guards git/cd paths only.
- Rollback of a stolen link: `recovery.md:5-16` manual `unlink` exception (requires operator approval and stopping the competing installer first), or `recovery.md:125-136` `sync.py --migrate-from agent-chorus=<clone>/skills/agent-chorus` then `--apply`. Only `~/.gemini/config/skills` is an HQ target; the other two Gemini directories need manual `unlink` or a re-run of the intended installer.

## Unknowns
| Unknown | Why it matters | What would settle it |
|---|---|---|
| Do consumer repos' agents ever run a vendored `.xyz/skills/*/install.sh`? | If yes, the same steal happens on consumer machines and the fix must ship via `xyz-vendor.sh` too | grep consumer repos (LTVera-Pandas, rebalanceOS, AEGIS) for `install.sh` invocations under `.xyz/` |
| Does the Mac Studio run the same gate against its own HOME? | Its three Gemini links are presumably stolen too | `readlink ~/.gemini/config/skills/agent-chorus` on that device |
| Is `~/.gemini/antigravity-cli/skills` still read by any installed app? | Decides whether to keep it as an installer target at all | Antigravity CLI docs, or the app's discovery log |

Zero-unknown claim not made: the subject is fully read inside this repo; the three unknowns are all outside it.

## Current-state radius, one line
22 installer files and their 7 textual variants; three test suites (agent-chorus, gh77-standup, releases-skill) and the gate that runs them locally and in CI; the HQ manager's link receipts on every device that runs the gate; three installers projected into the XYZ mini repos; every consumer `.xyz/` vendored copy; README plus ten skill docs, several stale; and on this device the three real Gemini directories, two of which nothing manages.
