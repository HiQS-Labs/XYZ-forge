# Linux setup — the cold-start path that actually works

What a stranger has to do, in order, to get XYZ-forge from `git clone` to a running marathon on a
fresh Ubuntu box. This differs from `README.md` in several places; each difference is marked
**[not in README]** and carries the finding that documents it.

Verified end to end on Ubuntu 24.04.1 (WSL2), Node 22.23.2, 2026-08-20. Every step below was
executed and its exit code logged under `evidence/`.

---

## 0. Sizing, before anything else

| Resource | Floor | Why |
|---|---|---|
| RAM | **16 GB** | `marathon-system/nightwatch-wave-2-.../RELAY.md:153` states 16 GB for the serial `marathon.sh --plan` route. |
| Cores | 4 works | Sizing doc budgets 1.5–2 GB per concurrent lane. 4 cores ran the marathons below fine. |
| Disk | ~2 GB | Repo + `node_modules` + a 205 MB `agy` binary. |

**Nothing in the harness enforces this.** There is no `xyz doctor`, no memory floor, no refusal — the
run starts and then dies through OOM or swap-thrash at an unpredictable depth. Check it yourself:

```bash
free -h && nproc
```

Under WSL this is capped by `C:\Users\<you>\.wslconfig`, not by physical RAM. Editing it requires
`wsl --shutdown` to take effect — it is read only at VM boot.

---

## 1. A **Linux** Node — and the trap that follows it

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
. "$HOME/.nvm/nvm.sh"
nvm install 22
```

README says Node 18+. The repo has no `.nvmrc`, no `.node-version` and no `engines` field, so pick a
current LTS.

### The trap — **[not in README]**, finding **F-006** / **F-008**

`nvm` appends its loader to the **bottom** of `~/.bashrc`. Ubuntu's stock `~/.bashrc` returns early
when the shell is not interactive (line 8):

```bash
case $- in
    *i*) ;;
      *) return;;
esac
```

`bash -lc` is a login **but non-interactive** shell, so the nvm block never runs. Every marathon turn,
every CI job and every agent harness runs in exactly that kind of shell. Consequences:

- `command -v node` is **empty**, while `command -v npm` succeeds and points at
  `/mnt/c/Program Files/nodejs/npm` — the **Windows** npm, leaking in through WSL interop. A Windows
  npm resolving platform-gated dependencies against a Linux filesystem produces a `node_modules` that
  fails later in ways that read as repo bugs.
- Worse, and this is **F-008**: `npm install -g @openai/codex` installs into the nvm version's bindir —
  precisely the directory a non-interactive shell cannot see. So you install a builder, see exit 0,
  see a working `codex --version` in your terminal, and the marathon still reports it missing.

**Fix.** Put the nvm bindir on `PATH` explicitly rather than relying on dotfile load order. This repo
ships one at `evidence/_env/prelude.sh`; source it at the top of every command:

```bash
. evidence/_env/prelude.sh    # prepends ~/.nvm/versions/node/<newest>/bin and asserts it is not /mnt/c
```

Verify before continuing — this must print a `/home/...` path, never `/mnt/c/...`:

```bash
command -v node && command -v npm && file -b "$(command -v node)"
# -> ELF 64-bit LSB executable, x86-64 ... GNU/Linux
```

---

## 2. System packages the README does not list

```bash
sudo apt-get update
sudo apt-get install -y sqlite3 jq
```

**[not in README]**, findings **F-010** and **F-011**. `README.md:180-184` lists Codex CLI, agy CLI,
Node 18+, git and Python 3.8+. It does not list these two, and stock Ubuntu 24.04 ships neither.

- **`sqlite3`** — 6 suites fail without it (`gh32-releases-app`, `gh53-releases-merge-resolve`,
  `gh54-merged-dump-refusals`, `gh57-releases-fuzz`, `gh57-live-merge-resolve`, `gh69-roadmap-shadow`).
  Confusingly, the *documented* releases path works fine without it, because `ROUTER.md` routes
  releases through `python3 utils/py/releases_app.py` and Python's built-in `sqlite3` module is
  present. So the docs' happy path works while six suites are red.
- **`jq`** — `standup/collect.sh` hard-requires it and ~40 assertions in `gh77-standup-triage` fail
  from that one absence. To its credit it degrades loudly and says exactly why.

> If you cannot use `sudo`, static builds of both drop into `~/.local/bin` and work, provided that
> directory is on the `PATH` your non-interactive shells actually see (see §1).

---

## 3. A global git identity

```bash
git config --global user.email "you@example.com"
git config --global user.name  "Your Name"
```

**[not in README]**, finding **F-012**. Many suites `git init` a scratch repo under `mktemp -d` and
commit into it. Those scratch repos inherit only **global** config, so with no global identity every
such commit fails with exit 128, and the suite reports the downstream symptom ("no relay file
produced") rather than the cause.

This is invisible to maintainers — any machine that has ever committed has a global identity — and
guaranteed on a fresh box or container.

---

## 4. Clone, install, hooks

```bash
git clone https://github.com/HiQS-Suite/XYZ-forge
cd XYZ-forge
git checkout -b my-work
npm install
bash githooks/install.sh
```

`npm install` is not optional; the suite dies on a missing module without it.

---

## 5. If you are working from a fork

```bash
gh repo set-default HiQS-Suite/XYZ-forge
```

**[not in README or ROUTER]**, finding **F-009**. On a fork, `gh` resolves issue lookups against your
fork, which has none of the upstream issues. `pdda-check-issue-doc-sync` then reports
`issue #N state unavailable (gh absent/offline and no cached state)` — every clause of which is false
when `gh` is installed and authenticated. Its suggested remedy (`utils/pdda/pdda.sh gh-refresh`) uses
the same resolution and fails identically, so the warning cannot be cleared by following it.

> Partially effective only. Setting the default repo fixed the resolution target, but issues that do
> not exist upstream either still fail. Warn-only in any case — `errors=0`.

---

## 6. Builders

Marathon needs at least one headless builder. Neither is installable via a plain `npm install` of the
repo.

```bash
npm install -g @openai/codex        # then authenticate; see below
```

`agy` (Google Antigravity CLI) is **not** on npm — `@google/antigravity`, `@antigravity/cli` and `agy`
all resolve to nothing or placeholders, and `antigravity.google/docs/cli` returns 404. Install it from
<https://antigravity.google/product/antigravity-cli>; it lands at `~/.local/bin/agy`, which is **not**
on the default `PATH`. Installing the Antigravity **IDE** does not give you the CLI — an IDE install
inspected during this bring-up contained `antigravity-ide` and `antigravity-ide.cmd` and no `agy`
binary anywhere.

Check what the harness can actually see — this is the authority, not `command -v`:

```bash
. evidence/_env/prelude.sh
bash skills/relay-xyz/find-harness.sh --check
```

### agy 1.1.16 — apply the auth-preflight fix first, finding **F-015**

If your `agy` is 1.1.16 or later, **the agy lane is hard-blocked on an unpatched tree.** `whoami` is no
longer a subcommand (nor is `login`, which is the remedy the harness tells you to run), so the auth
preflight falls through to agy's interactive TUI, which emits a terminal takeover and then blocks —
ignoring SIGTERM. `agy_auth_preflight` returns `False` at 5s, 15s and 30s; raising the timeout does not
help, because the probe can never complete.

The fix is in `utils/py/rtl.py` on branch `fix/agy-tui-takeover-auth-verdict`. Confirm it is present:

```bash
grep -q AGY_TUI_TAKEOVER_MARKERS utils/py/rtl.py && echo "fix present" || echo "agy lane will block"
```

Without it you will see `agy shim exited 5` on every turn.

---

## 7. Run the gate — **unsandboxed**

```bash
./validate.sh --print-mode
./validate.sh --sequential 2>&1 | tee validate.log
```

Sequential is the source of truth; parallel output is explicitly not promotion evidence.

**If you drive this repo from an agent harness, the Bash tool is very likely sandboxed** (finding
**F-020**). `relay-automation/hooks/gh177-sandbox-test-guard.sh` will refuse every suite invocation:

```
GH-177 guard: refusing to run the test suite under a SANDBOXED Bash call.
```

That refusal is correct and is doing you a favour — sandbox-broken `mktemp` fed a destructive EXIT
trap that wiped this repo twice. Re-run with the sandbox explicitly disabled, which is the second
option the guard itself offers.

**Do not trust a pipeline's exit code.** `./validate.sh --sequential | tail -80` reports `tail`'s
status, not the suite's. That is how a red suite gets reported green (findings **F-014**, **F-021**).
Use `PIPESTATUS[0]`, or `evidence/_env/run.sh`, which does it for you and appends a machine-readable
`EXIT_CODE:` trailer.

Budget ~23 minutes on 4 cores. `ROUTER.md` budgets ~16 min, measured on a 32 GB M1 Max.

---

## 8. Running a marathon against your own repo

This is the part with the most undocumented shape. The lifecycle is
**triage → preflight → dry-run → confirm → fire** (`.claude/commands/pre-marathon.md:6-22`). There is
no `compute` verb (finding **F-002**).

### 8a. Vendor the harness into the target — do NOT use `--target-root`

```bash
cd /path/to/XYZ-forge
relay-automation/xyz-vendor.sh /path/to/target-repo
```

Finding **F-018**. `marathon.sh --target-root`'s help recommends it for "a public repo that gitignores
`marathon-system/` and `relay-system/` on purpose" — but `relay-drive` then **refuses** that exact
combination, because `--target-root` keeps the relay thread in the harness repo by design and a build
turn therefore has no writable path for its findings:

```
relay-drive: --target-root build turn cannot report: ... the turn would be discarded after full cost.
```

The refusal is excellent — it fires before any builder turn is spent and names two remedies. Take the
first. Note the consequence the help does not mention: the target must now **track**
`marathon-system/` and `relay-system/`, which is the thing `--target-root` was offered to avoid.

Then, in the target repo:

```bash
# harness output must be trackable
sed -i '/marathon-system\//d; /relay-system\//d' .gitignore
git add -A && git commit -m "vendor xyz harness"
```

### 8b. The capture doc and its contract

The plan and briefs must live under `PROJECT/2-WORKING/` in the target repo (GH-212), and preflight
reads a capture doc carrying a `## Swarm Preflight Contract` JSON block.

**For any greenfield (new-file) work — which is most marathons — you need `artifacts_new`**, finding
**F-019**. It is enforced with a hard exit 3 and appears in **no** operator-facing documentation,
including `relay-automation/CONTRACT.example.md`, which is the file the exit-3 message tells you to
copy. The rules, recoverable only from `utils/swarm-preflight.sh:181-190` and `:228-243`:

- `artifacts[]` is the **full** write-set; every entry must exist at `target.ref` **unless** exempted.
- `artifacts_new[]` is a **subset marker over `artifacts[]`** — not a parallel list. Every entry must
  also appear in `artifacts[]`, or you get
  `artifacts_new entry not present in artifacts[]`.
- Every `artifacts_new` entry needs a matching `fix_probes` entry of type `path_absent` on the **exact
  same path**.

A working example:

```json
{
  "target":       { "repo": ".", "ref": "main" },
  "gate":         "npm test",
  "fix_probes":   [ { "type": "path_absent", "path": "src/new.js" } ],
  "artifacts":    [ "src/existing.js", "src/new.js" ],
  "artifacts_new":[ "src/new.js" ],
  "remediation":  { "source": "self#run1", "criteria": "..." },
  "lanes":        { "agy_safe": [], "orchestrator_only": [] }
}
```

The doc also needs frontmatter carrying `complexity`, `risk` and `effort`, or it reads as `unrated`.

### 8c. Preflight, then dry-run, then fire

```bash
cd /path/to/target-repo
.xyz/utils/swarm-preflight.sh --project-doc PROJECT/2-WORKING/MY-WORK.md       # expect exit 0 "ready"
.xyz/relay-automation/marathon.sh --plan PROJECT/2-WORKING/MY-WORK/MARATHON.yaml \
    --builder agy --pre-advance-cmd "npm test" --dry-run                        # expect exit 0
.xyz/relay-automation/marathon.sh --plan PROJECT/2-WORKING/MY-WORK/MARATHON.yaml \
    --builder agy --pre-advance-cmd "npm test"
```

`--pre-advance-cmd` is required for any target without a root `validate.sh`; the default gate is
`bash validate.sh` per phase and a missing default fails fast rather than being skipped.

If preflight reports `skip_branch_prompt: false`, the GH-69 contract requires the orchestrating agent
to **ask the operator** before firing — never auto-cut a branch.

> **If you pass `--target-root` anyway** (finding **F-017**): `--plan` is existence-checked at
> `marathon.sh:136` against the **process CWD**, 19 lines before `_plan_base="${TARGET_ROOT:-$ROOT}"`
> is computed at `:155` — despite the help promising "Plan and brief paths resolve against DIR when
> set." Pass an absolute path.

### 8d. `compute` does not work in a vendored repo

```bash
.xyz/utils/marathon-plan.sh --check
# ROADMAP not found: /path/to/target-repo/ROADMAP.md      -> exit 3
```

Finding **F-022**. The planner/ranker reads the harness's own PDDA `ROADMAP.md` ledger, which a
consuming repo does not have. Ranking/wave-formation is therefore unavailable in exactly the
deployment shape `xyz-vendor.sh` creates. For a hand-written plan this does not matter — preflight and
dry-run are the steps that gate a fire — but do not expect the ranking step to run there.

---

## 9. Where the output lands

With a vendored install, everything is in the **target** repo:

| Artefact | Path |
|---|---|
| Live relay thread | `marathon-system/<slug>--<phase-id>/RELAY.md` |
| Failure record | `marathon-system/<slug>--<phase-id>/ESCALATION.md` |
| Saved transcript | `relay-system/<YYYY-MM-DD>/marathon-<phase-id>-<HHMMSS>.md` |
| Preflight packet | `relay-system/preflight/<date>/<slug>/` |
| Run log | `relay-system/run-logs/<date>/marathon-*.log` |
| Events | `.tick/events/*.jsonl` (gitignored, per-device) |

## 10. Exit codes worth knowing

`marathon.sh`: `0` all phases approved · `2` usage/parse · otherwise the failing phase's
marathon-drive code.

`marathon-drive.sh`: `0` approved+gated · `3` relay no-progress · `4` relay cap/mismatch ·
`5` pre-advance gate failed · `6` **containment violation** · `7` **turn timeout/hang** ·
`8` **lane parked** (GH-45 attempt cap — re-fire with `--force`) · `9` post-approve failed ·
`108` **gate killed** by the GH-390 resource guard.

> The brief this bring-up was run from lists exit `8` as "relay block invalid". In this revision it is
> **lane parked** (`marathon-drive.sh:65-66`). Finding **F-004**.
