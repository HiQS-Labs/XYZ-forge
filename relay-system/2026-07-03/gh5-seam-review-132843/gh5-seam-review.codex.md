Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f29ab-5b75-7cc2-86ec-b38328e4234a
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Review: GH-5 contract-seam warning in `utils/marathon-plan.sh` (PR #103)

Read ONLY these files directly (they are at the repo root of your worktree; do NOT search the wider
filesystem): **`utils/marathon-plan.sh`** — focus on the GH-5 additions: `dirPrefixes`, `sharedSpine`,
the `contractSeams` computation after wave-packing (`waves.forEach(... r.wave ...)`), and the
"## Contract seams" output section — and **`test/marathon-plan.sh`** (scenario K).

## Context
`marathon-plan.sh` ranks ROADMAP items into collision-safe waves. The wave-packer defers a lane only
on an EXACT write-set path collision, so two lanes writing disjoint files under a shared directory
(e.g. `src/schema/producer.js` + `src/schema/consumer.js`) co-wave and look independent while the
consumer stalls on the producer. GH-5 adds a heuristic that flags such "contract seams" so the plan
can say "pin a CONTRACT.md" before launch. It is ADVISORY: it never changes wave assignment or the exit
code; it only adds a report section + `warn`/`coupled-lanes` findings.

## The heuristic
`sharedSpine(wsA, wsB)` returns the deepest directory of >= 2 segments (a string containing "/")
shared by any path in A and any path in B. `dirPrefixes(p)` splits a path, drops the last segment
(file or trailing glob like `**`), and returns cumulative dir prefixes. Top-level-only sharing (both
under `src/`) is intentionally NOT a seam. Only lanes with a proven write-set (from a contract) are
judged.

## Answer these — graded [Blocker]/[Should]/[Nit]/[Pass], cite `utils/marathon-plan.sh:LINE`

1. **Heuristic correctness.** Does `sharedSpine`/`dirPrefixes` do what's intended? Check: a glob write-set
   (`src/schema/**` — does dropping the last segment give `src/schema`?); a 2-segment path (`bin/tick` →
   prefixes `["bin"]`, no "/" → correctly not a seam); a file at repo root (`README.md`); a path with a
   trailing slash; deeply nested shared dirs (returns the DEEPEST?).
2. **False positives / negatives.** Could it flag genuinely-independent lanes (noise that erodes trust),
   or miss a real coupling? Is "shared dir deeper than top-level" a reasonable proxy for "shared contract
   seam", given the issue's own suggestion? Is judging only same-wave pairs right (should cross-wave
   coupling matter)?
3. **Advisory guarantee.** Confirm the seam logic never changes wave membership, the `active`/`held`
   sets, or the exit code — purely additive output + findings.
4. **Determinism.** Is the output still byte-deterministic for `--check` (stable pair ordering, stable
   `best` selection in `sharedSpine` on ties)?
5. **Only-proven-write-sets.** Zone-inferred lanes have `writeset: []`; confirm they're skipped
   (`if (!a.writeset.length || !b.writeset.length) continue`) so a keyword-inferred lane can't produce a
   phantom seam.

Be specific and adversarial; say [Pass] with a reason where a case is genuinely handled. End with a
one-line RECOMMENDATION (merge as-is / merge with nits / changes required).
hook: SessionStart
hook: SessionStart Completed
codex
Reviewing the GH-5 seam logic directly in the two requested files. I’m pulling exact line-numbered source first, then I’ll grade the five questions against what the code actually does.
exec
/bin/zsh -lc 'nl -ba utils/marathon-plan.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# utils/marathon-plan.sh — deterministic "pre-pre-flight" queue planner.
     3	#
     4	# Reads the canonical ROADMAP.md ledger (a queue of work: GitHub issues + PROJECT/**.md docs),
     5	# validates each item is still real (not already fixed / silently half-done), factors in the PDDA
     6	# complexity/risk/effort ratings, and emits TWO artifacts:
     7	#
     8	#   1. a VALIDATION / DRIFT REPORT on stdout — deterministic signals, each a FLAG for a human,
     9	#      never an auto-fix (already-closed / already-landed / undocumented-partial / drift / unrated);
    10	#   2. a SEQUENCED marathon-plan doc  PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md — ratings-ranked, collision-lane
    11	#      aware, reproducing the shape of the hand-authored QUEUE-2026-06-27.md.
    12	#
    13	# It is the stage BEFORE utils/swarm-preflight.sh (which is per-item readiness). Overlap is intended:
    14	# this planner REUSES swarm-preflight's contract shape + probe semantics, and can DELEGATE to it
    15	# per-item with --deep. The planner is a PRODUCER of a plan; it never executes a marathon
    16	# (GUIDING-PRINCIPLES.md §8 — the operator decides).
    17	#
    18	# Determinism: the score for every item is printed alongside its inputs so any ordering is
    19	# reproducible by hand. Same ledger + same ratings + same NOW/TODAY ⇒ byte-identical output
    20	# (so --check works as a drift guard in validate.sh, mirroring roadmap-dashboard.sh --check).
    21	#
    22	# Usage:
    23	#   utils/marathon-plan.sh                         # report on stdout + write today's marathon-plan doc
    24	#   utils/marathon-plan.sh --dry-run               # report only; write nothing
    25	#   utils/marathon-plan.sh --check                 # exit non-zero if today's marathon-plan doc is out of sync
    26	#   utils/marathon-plan.sh --policy derisk-first   # high-risk work sorts earlier (default: quick-wins)
    27	#   utils/marathon-plan.sh --deep                  # also delegate to swarm-preflight --dry-run per item
    28	#   utils/marathon-plan.sh --format json           # findings as JSON lines (pdda finding shape)
    29	#
    30	# Exit: 0 clean · 2 usage · 3 ROADMAP missing/unparseable ·
    31	#       4 emitted, drift present (already-landed/closed — reconcile the ledger) ·
    32	#       5 emitted, items held out of sequencing (unrated / note-only / not-ready) ·
    33	#       6 gh required but unavailable (--require-gh only).
    34	#
    35	# Test seam (all optional; unset in production):
    36	#   QUEUE_PLAN_ROOT / QUEUE_PLAN_ROADMAP / QUEUE_PLAN_QUEUE_DIR / QUEUE_PLAN_NOW / QUEUE_PLAN_TODAY
    37	#   QUEUE_PLAN_GH_STATE_FILE   JSON map {"24":"CLOSED",...} used instead of calling `gh` (hermetic)
    38	#   QUEUE_PLAN_BRANCHES_FILE   newline list of branch names used instead of calling `git branch`
    39	#   QUEUE_PLAN_GH              force gh mode: off|stub (off ⇒ gh-unverified; stub needs *_STATE_FILE)
    40	
    41	set -uo pipefail
    42	
    43	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    44	ROOT="${QUEUE_PLAN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
    45	ROADMAP="${QUEUE_PLAN_ROADMAP:-"$ROOT/ROADMAP.md"}"
    46	QUEUE_DIR="${QUEUE_PLAN_QUEUE_DIR:-"$ROOT/PROJECT/2-WORKING"}"
    47	NOW="${QUEUE_PLAN_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
    48	TODAY="${QUEUE_PLAN_TODAY:-"$(date -u +%Y-%m-%d)"}"
    49	
    50	die()  { printf 'marathon-plan: %s\n' "$*" >&2; exit 2; }
    51	emit() { printf '%s\n' "$*" >&2; }
    52	
    53	usage() {
    54	  cat <<'EOF'
    55	Usage: utils/marathon-plan.sh [--dry-run | --check] [--policy quick-wins|derisk-first]
    56	                           [--deep] [--require-gh] [--format text|json]
    57	
    58	  (default)        Print the validation report and write PROJECT/2-WORKING/MARATHON-PLAN-<today>.md.
    59	  --dry-run        Print the report; write no marathon-plan doc.
    60	  --check          Re-render and compare against today's marathon-plan doc; non-zero on drift. Writes nothing.
    61	  --policy P       quick-wins (default; momentum, low-cost first) | derisk-first (high-risk first).
    62	  --deep           Additionally delegate to utils/swarm-preflight.sh --dry-run per ready item
    63	                   (authoritative ref-based freshness/probe verdict; slower, needs network).
    64	  --require-gh     Treat an unavailable/offline `gh` as a hard error (exit 6) instead of degrading.
    65	  --format F       text (default) | json (findings as one JSON object per line).
    66	
    67	Exit: 0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent.
    68	EOF
    69	}
    70	
    71	POLICY="quick-wins"
    72	FORMAT="text"
    73	RUN_MODE="write"     # write | dry-run | check
    74	DEEP=0
    75	REQUIRE_GH=0
    76	
    77	while (($# > 0)); do
    78	  case "$1" in
    79	    --dry-run)    RUN_MODE="dry-run"; shift ;;
    80	    --check)      RUN_MODE="check"; shift ;;
    81	    --policy)     POLICY="${2:-}"; shift 2 ;;
    82	    --deep)       DEEP=1; shift ;;
    83	    --require-gh) REQUIRE_GH=1; shift ;;
    84	    --format)     FORMAT="${2:-}"; shift 2 ;;
    85	    --help|-h)    usage; exit 0 ;;
    86	    *)            usage; die "unknown argument: $1" ;;
    87	  esac
    88	done
    89	
    90	case "$POLICY" in quick-wins|derisk-first) ;; *) die "--policy must be 'quick-wins' or 'derisk-first'" ;; esac
    91	case "$FORMAT" in text|json) ;; *) die "--format must be 'text' or 'json'" ;; esac
    92	[[ -f "$ROADMAP" ]] || { emit "ROADMAP not found: $ROADMAP"; exit 3; }
    93	command -v node >/dev/null 2>&1 || die "node is required (Node stdlib only; no deps) but not found in PATH"
    94	
    95	TMP="$(mktemp -d "${TMPDIR:-/tmp}/marathon-plan.XXXXXX")"
    96	trap 'rm -rf "$TMP"' EXIT
    97	RENDER_OUT="$TMP/MARATHON-PLAN-$TODAY.md"
    98	QUEUE_DOC="$QUEUE_DIR/MARATHON-PLAN-$TODAY.md"
    99	
   100	# Resolve the swarm-preflight path for --deep delegation (skipped silently if absent).
   101	SWARM_PREFLIGHT="$HERE/swarm-preflight.sh"
   102	[[ "$DEEP" -eq 1 && -x "$SWARM_PREFLIGHT" ]] || SWARM_PREFLIGHT=""
   103	
   104	# One embedded Node program does the compute (parse ledger → resolve items → signals → score →
   105	# wave-pack → render). It prints the report to stdout, writes the rendered marathon-plan doc to QP_RENDER_OUT,
   106	# and exits with the flag-derived code. git/gh are reached via execSync, but the test seam env files
   107	# short-circuit them so the suite stays hermetic. CommonJS (node - <<'NODE') like roadmap-dashboard.sh.
   108	QP_ROOT="$ROOT" QP_ROADMAP="$ROADMAP" QP_QUEUE_DIR="$QUEUE_DIR" \
   109	QP_TODAY="$TODAY" QP_NOW="$NOW" QP_POLICY="$POLICY" QP_FORMAT="$FORMAT" \
   110	QP_DEEP="$DEEP" QP_REQUIRE_GH="$REQUIRE_GH" QP_SWARM_PREFLIGHT="$SWARM_PREFLIGHT" \
   111	QP_RENDER_OUT="$RENDER_OUT" \
   112	QP_GH_STATE_FILE="${QUEUE_PLAN_GH_STATE_FILE:-}" QP_BRANCHES_FILE="${QUEUE_PLAN_BRANCHES_FILE:-}" \
   113	QP_GH_FORCE="${QUEUE_PLAN_GH:-}" QP_BASE_FILES_FILE="${QUEUE_PLAN_BASE_FILES_FILE:-}" \
   114	node - <<'NODE'
   115	"use strict";
   116	const fs = require("fs");
   117	const path = require("path");
   118	const { execSync } = require("child_process");
   119	
   120	const E = process.env;
   121	const ROOT = E.QP_ROOT;
   122	const TODAY = E.QP_TODAY;
   123	const NOW = E.QP_NOW;
   124	const POLICY = E.QP_POLICY;
   125	const FORMAT = E.QP_FORMAT;
   126	const DEEP = E.QP_DEEP === "1";
   127	const REQUIRE_GH = E.QP_REQUIRE_GH === "1";
   128	const SWARM_PREFLIGHT = E.QP_SWARM_PREFLIGHT || "";
   129	const BASE_FILES_FILE = E.QP_BASE_FILES_FILE || "";
   130	
   131	// ── kernel write-set: the serialization bottleneck (QUEUE-2026-06-27 "the one safety rule") ──
   132	const KERNEL_PATHS = [
   133	  "relay-automation/relay-turn-lib.sh",
   134	  "bin/tick",
   135	  "relay-automation/relay-drive.sh",
   136	];
   137	const SHIM_RE = /relay-automation\/[a-z0-9-]+-turn\.sh$|relay-automation\/consult\.sh$/i;
   138	
   139	// Ledger sections we sequence from vs. only reference.
   140	const SECTIONS = ["Queue / parked intake", "In progress", "Completed", "Deferred · vision"];
   141	const KNOWN_EMOJI = ["🟢", "🟡", "⏸️", "⛔", "✅", "🔮", "🔲", "⚠️", "🆕", "🐞", "🔴"];
   142	
   143	// ── tiny readers ─────────────────────────────────────────────────────────────
   144	function readFileSafe(p) { try { return fs.readFileSync(p, "utf8"); } catch { return null; } }
   145	function existsAt(rel, base) { try { return fs.existsSync(path.resolve(base || ROOT, rel)); } catch { return false; } }
   146	
   147	// Check if file existed at a given ref (to identify net-new artifacts).
   148	// Hermetic test seam: if BASE_FILES_FILE is set, read it as a list of existing base paths.
   149	let BASE_FILES = null;
   150	function fileExistedAtBaseRef(relPath, ref) {
   151	  let normalized = relPath;
   152	  if (normalized.startsWith("./")) normalized = normalized.slice(2);
   153	  if (BASE_FILES_FILE) {
   154	    if (!BASE_FILES) {
   155	      try {
   156	        BASE_FILES = new Set(
   157	          fs.readFileSync(BASE_FILES_FILE, "utf8")
   158	            .split(/\r?\n/)
   159	            .map((s) => s.trim())
   160	            .filter(Boolean)
   161	        );
   162	      } catch {
   163	        BASE_FILES = new Set();
   164	      }
   165	    }
   166	    return BASE_FILES.has(normalized);
   167	  }
   168	  try {
   169	    // Check if the file existed at the base ref using git
   170	    execSync(`git cat-file -e "${ref}:${normalized}"`, { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] });
   171	    return true;
   172	  } catch {
   173	    return false;
   174	  }
   175	}
   176	
   177	// Frontmatter line reader — same simple `key: value` contract pdda-lib.sh enforces.
   178	function frontmatter(doc) {
   179	  const raw = readFileSafe(doc);
   180	  if (raw == null) return {};
   181	  const lines = raw.replace(/^\ufeff/, "").split(/\r?\n/);  // strip a leading UTF-8 BOM if present
   182	  let i = 0;
   183	  while (i < lines.length && lines[i].trim() === "") i++;
   184	  if (lines[i] == null || !/^---\s*$/.test(lines[i])) return {};
   185	  const fm = {};
   186	  for (i++; i < lines.length; i++) {
   187	    if (/^---\s*$/.test(lines[i])) break;
   188	    const m = lines[i].match(/^([A-Za-z0-9_]+):\s*(.*)$/);
   189	    if (m) fm[m[1]] = m[2].trim();
   190	  }
   191	  return fm;
   192	}
   193	
   194	// Extract a swarm-preflight contract (heading /preflight contract/i + fenced ```json) — same shape
   195	// utils/swarm-preflight.sh reads. Returns the parsed object or null (planner degrades, never dies).
   196	function extractContract(doc) {
   197	  const raw = readFileSafe(doc);
   198	  if (raw == null) return null;
   199	  const lines = raw.split(/\r?\n/);
   200	  const h = lines.findIndex((l) => /^#{1,6}\s+.*preflight\s+contract/i.test(l));
   201	  if (h < 0) return null;
   202	  let start = -1;
   203	  for (let j = h + 1; j < lines.length; j++) {
   204	    if (/^```json\s*$/i.test(lines[j])) { start = j + 1; break; }
   205	    if (/^#{1,6}\s+/.test(lines[j])) break;
   206	  }
   207	  if (start < 0) return null;
   208	  let end = -1;
   209	  for (let j = start; j < lines.length; j++) { if (/^```\s*$/.test(lines[j])) { end = j; break; } }
   210	  if (end < 0) return null;
   211	  try { return JSON.parse(lines.slice(start, end).join("\n")); } catch { return null; }
   212	}
   213	
   214	// Probe evaluator — same verdict semantics as swarm-preflight's eval-probes.mjs, run LOCALLY against
   215	// ROOT (cheap, offline). landed = already fixed; unfixed = fix still required; blocked = can't tell.
   216	function evalProbe(p) {
   217	  const at = (rel) => path.resolve(ROOT, rel || "");
   218	  try {
   219	    switch (p.type) {
   220	      case "path_absent":  return fs.existsSync(at(p.path)) ? "landed" : "unfixed";
   221	      case "path_present": return !fs.existsSync(at(p.path)) ? "blocked" : "unfixed";
   222	      case "grep_present":
   223	        if (!fs.existsSync(at(p.path))) return "blocked";
   224	        return new RegExp(p.pattern).test(fs.readFileSync(at(p.path), "utf8")) ? "unfixed" : "landed";
   225	      case "grep_absent":
   226	        return (fs.existsSync(at(p.path)) && new RegExp(p.pattern).test(fs.readFileSync(at(p.path), "utf8")))
   227	          ? "landed" : "unfixed";
   228	      default: return "blocked";
   229	    }
   230	  } catch { return "blocked"; }
   231	}
   232	
   233	// ── git / gh, with a hermetic test seam ──────────────────────────────────────
   234	let BRANCHES = null;
   235	function branches() {
   236	  if (BRANCHES) return BRANCHES;
   237	  if (E.QP_BRANCHES_FILE) {
   238	    BRANCHES = (readFileSafe(E.QP_BRANCHES_FILE) || "").split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
   239	    return BRANCHES;
   240	  }
   241	  try {
   242	    BRANCHES = execSync("git branch -a --format='%(refname:short)'", { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] })
   243	      .toString().split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
   244	  } catch { BRANCHES = []; }
   245	  return BRANCHES;
   246	}
   247	function branchMatchesSlug(slug) {
   248	  if (!slug) return false;
   249	  return branches().some((b) => b.toLowerCase().includes(slug.toLowerCase()));
   250	}
   251	
   252	// gh mode: live (real gh) | stub (state file) | off (unverified). Resolved once.
   253	let GH_MODE = "live", GH_STATE = null;
   254	(function resolveGh() {
   255	  if (E.QP_GH_FORCE === "off") { GH_MODE = "off"; return; }
   256	  if (E.QP_GH_STATE_FILE) {
   257	    try { GH_STATE = JSON.parse(readFileSafe(E.QP_GH_STATE_FILE) || "{}"); GH_MODE = "stub"; return; } catch { GH_MODE = "off"; return; }
   258	  }
   259	  try { execSync("command -v gh", { stdio: "ignore" }); } catch { GH_MODE = "off"; return; }
   260	  try { execSync("gh auth status", { stdio: "ignore" }); } catch { GH_MODE = "off"; return; }
   261	})();
   262	function ghState(n) {
   263	  if (n == null) return null;
   264	  if (GH_MODE === "off") return null;
   265	  if (GH_MODE === "stub") return (GH_STATE && GH_STATE[String(n)]) || null;
   266	  try {
   267	    return execSync(`gh issue view ${n} --json state -q .state`, { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] })
   268	      .toString().trim().toUpperCase() || null;
   269	  } catch { return null; }
   270	}
   271	
   272	// ── ledger parse (the parser lifted + extended from roadmap-dashboard.sh) ──────
   273	function stripMd(v) {
   274	  return v.replace(/`([^`]+)`/g, "$1").replace(/\*\*([^*]+)\*\*/g, "$1")
   275	    .replace(/\*([^*]+)\*/g, "$1").replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1").trim();
   276	}
   277	function parseBullet(block, section) {
   278	  const text = block.map((l) => l.trim()).join(" ").replace(/\s+/g, " ").trim();
   279	  const titleMatch = text.match(/^- \*\*(.+?)\*\*/);
   280	  const title = titleMatch ? stripMd(titleMatch[1]) : stripMd(text.replace(/^- /, ""));
   281	  let status = "—";
   282	  for (const e of KNOWN_EMOJI) { if (text.includes(e)) { status = e; break; } }
   283	  const links = [];
   284	  const re = /\[([^\]]+)\]\(([^)]+)\)/g;
   285	  let m;
   286	  while ((m = re.exec(text)) !== null) links.push({ label: m[1], target: m[2] });
   287	  return { title, status, links, raw: text, section };
   288	}
   289	function parseLedger(raw) {
   290	  const lines = raw.split(/\r?\n/);
   291	  const out = [];
   292	  let inLedger = false, current = null;
   293	  for (let i = 0; i < lines.length; i++) {
   294	    const line = lines[i];
   295	    if (!inLedger) { if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true; continue; }
   296	    if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
   297	    const sm = line.match(/^###\s+(.+?)\s*$/);
   298	    if (sm) { current = SECTIONS.includes(sm[1].trim()) ? sm[1].trim() : null; continue; }
   299	    if (!current || !/^- \*\*/.test(line)) continue;
   300	    const block = [line];
   301	    while (i + 1 < lines.length) {
   302	      const nx = lines[i + 1];
   303	      if (/^###\s+/.test(nx) || /^##\s+/.test(nx) || /^- \*\*/.test(nx)) break;
   304	      block.push(nx); i += 1;
   305	    }
   306	    out.push(parseBullet(block, current));
   307	  }
   308	  return out;
   309	}
   310	
   311	// ── item resolution ──────────────────────────────────────────────────────────
   312	function ghIssueOf(item) {
   313	  // The canonical issue is the leading "GH-NN ·" in the TITLE. An in-prose issues/ link (e.g. GH-16's
   314	  // body cites #17/#11/…) is a reference, not the item's identity — so the title WINS over links; only
   315	  // fall back to the first issue link when the title carries no GH-NN (agy QA r4 [Blocker]).
   316	  const t = item.title.match(/\bGH-(\d+)\b/);
   317	  if (t) return Number(t[1]);
   318	  for (const l of item.links) {
   319	    const m = l.target.match(/github\.com\/[^\s)]+\/issues\/(\d+)/);
   320	    if (m) return Number(m[1]);
   321	  }
   322	  return null;
   323	}
   324	function docOf(item) {
   325	  const mds = item.links.map((l) => l.target).filter((t) => /\.md($|#)/.test(t) && /PROJECT\//.test(t) && !/relay-system\//.test(t));
   326	  if (mds.length === 0) return null;
   327	  const pick = mds.find((t) => /2-WORKING\/GH-\d+-/i.test(t)) || mds.find((t) => /2-WORKING\//.test(t)) || mds[0];
   328	  return pick.replace(/#.*$/, "");
   329	}
   330	function slugOf(docRel, title) {
   331	  const base = docRel ? path.basename(docRel, ".md") : title;
   332	  return base.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "item";
   333	}
   334	function zoneOf(contract, item) {
   335	  // Proven zone from the contract write-set; else keyword-inferred (flagged zone-inferred).
   336	  if (contract && Array.isArray(contract.artifacts)) {
   337	    const arts = contract.artifacts;
   338	    const orchOnly = (contract.lanes && contract.lanes.orchestrator_only) || [];
   339	    // Zone is derived from the WRITE-SET (artifacts) only. orchestrator_only is a guardrail — paths the
   340	    // lane must NOT touch — so it never adds to the write-set; it only reclassifies an artifact that
   341	    // falls UNDER an orchestrator_only prefix as kernel-owned. (Unioning it in wrongly serialized any
   342	    // shim whose contract merely names relay-turn-lib.sh as off-limits.)
   343	    const touchesKernel = arts.some(
   344	      (a) => KERNEL_PATHS.some((k) => a === k || a.startsWith(k)) ||
   345	             orchOnly.some((o) => a === o || a.startsWith(o))
   346	    );
   347	    if (touchesKernel) return { zone: "kernel", inferred: false, writeset: arts };
   348	    if (arts.some((a) => SHIM_RE.test(a))) return { zone: "shim", inferred: false, writeset: arts };
   349	    return { zone: "independent", inferred: false, writeset: arts };
   350	  }
   351	  const hay = (item.title + " " + item.raw).toLowerCase();
   352	  if (/relay-turn-lib|containment kernel|bin\/tick|relay-drive|commit semantics|epoch fenc/.test(hay))
   353	    return { zone: "kernel", inferred: true, writeset: [] };
   354	  if (/-turn\.sh|consult\.sh|\bshim\b/.test(hay))
   355	    return { zone: "shim", inferred: true, writeset: [] };
   356	  return { zone: "independent", inferred: true, writeset: [] };
   357	}
   358	function depsOf(item) {
   359	  const deps = new Set();
   360	  // Match a dependency keyword followed by a LIST of issue refs (comma/and/&/slash separated), so
   361	  // "after GH-29, GH-30 and #31" yields all three. The list stops at the first non-issue token, so
   362	  // "after GH-29 the fix landed" still yields only 29 (no over-capture).
   363	  // Separator between refs is a RUN of comma/&//conjunction tokens (zero-or-more), so a compound
   364	  // separator like ", and" / ", & " / "and/or" is consumed and the following ref is still captured
   365	  // ("GH-100, GH-101, and GH-102" ⇒ all three). Each token consumes ≥1 char, so the `*` can't loop.
   366	  const re = /(?:after|once|depends on|gated on|blocked by)\s+((?:(?:GH-|#)\d+(?:\s*(?:,|&|\/|and|or)\s*)*)+)/gi;
   367	  let m;
   368	  while ((m = re.exec(item.raw)) !== null) {
   369	    let n; const num = /(?:GH-|#)(\d+)/g;
   370	    while ((n = num.exec(m[1])) !== null) deps.add(Number(n[1]));
   371	  }
   372	  return [...deps];
   373	}
   374	function isGoGated(item) {
   375	  return /gated on operator go|gated on (a |an )?operator|operator go\b|awaiting go\b/i.test(item.raw);
   376	}
   377	
   378	// GH-5: a "contract seam" is a directory two lanes SHARE (deeper than a top-level dir) even though
   379	// their exact write-sets are disjoint — a strong hint they depend on a common not-yet-built module or
   380	// schema. The wave-packer only defers on EXACT path collision, so such lanes co-wave and look
   381	// independent; in practice the consumer stalls on the producer's handoff unless the operator pins a
   382	// shared contract first. This detects the seam so the plan can say "pin a CONTRACT.md" up front.
   383	function dirPrefixes(p) {
   384	  const parts = String(p).split("/").filter(Boolean);
   385	  parts.pop(); // drop the file / trailing glob segment (e.g. a.js, **)
   386	  const out = []; let acc = "";
   387	  for (const seg of parts) { acc = acc ? acc + "/" + seg : seg; out.push(acc); }
   388	  return out; // "src/schema/a.js" -> ["src", "src/schema"]
   389	}
   390	function sharedSpine(wsA, wsB) {
   391	  // Deepest directory of >= 2 segments (contains a "/") shared by any path in A and any in B.
   392	  // Top-level-only sharing (both under "src/" or "test/") is intentionally NOT a seam — too coarse.
   393	  let best = null;
   394	  for (const pa of wsA) {
   395	    const pref = dirPrefixes(pa);
   396	    for (const pb of wsB) {
   397	      const setB = new Set(dirPrefixes(pb));
   398	      for (const d of pref) if (d.includes("/") && setB.has(d) && (!best || d.length > best.length)) best = d;
   399	    }
   400	  }
   401	  return best;
   402	}
   403	
   404	// PDDA triage ratings are integers 1 (low) .. 5 (highest) — see PROJECT/PDDA.md "Triage ratings".
   405	// Anything outside 1–5 (or absent) is treated as unrated (null) so the doc is held out of sequencing.
   406	const L = (x) => { const n = parseInt(String(x == null ? "" : x).trim(), 10); return n >= 1 && n <= 5 ? n : null; };
   407	
   408	// ── findings (the pdda finding shape) ────────────────────────────────────────
   409	const findings = [];
   410	function flag(severity, type, rec, message, action) {
   411	  findings.push({ severity, type, item: rec ? rec.title : "(run)", file: rec ? rec.docRel : "", message, action });
   412	}
   413	
   414	// ── build records ────────────────────────────────────────────────────────────
   415	const raw = readFileSafe(E.QP_ROADMAP);
   416	if (raw == null) { process.stderr.write("marathon-plan: cannot read ROADMAP\n"); process.exit(3); }
   417	const ledger = parseLedger(raw);
   418	if (ledger.length === 0) { process.stderr.write("marathon-plan: no ledger items parsed (is '## Ledger' present?)\n"); process.exit(3); }
   419	
   420	const records = [];
   421	for (const item of ledger) {
   422	  const gh = ghIssueOf(item);
   423	  const docRel = docOf(item);
   424	  const docAbs = docRel ? path.resolve(ROOT, docRel) : null;
   425	  const docExists = docRel ? existsAt(docRel) : false;
   426	  const slug = slugOf(docRel, item.title);
   427	  const fm = docExists ? frontmatter(docAbs) : {};
   428	  const ratings = { complexity: L(fm.complexity), risk: L(fm.risk), effort: L(fm.effort) };
   429	  const rated = ratings.complexity != null && ratings.risk != null && ratings.effort != null;
   430	  const ratingsExempt = String(fm.ratings_exempt || "").toLowerCase() === "true";
   431	  const contract = docExists ? extractContract(docAbs) : null;
   432	  const z = zoneOf(contract, item);
   433	  // GH-69: deterministic branch suggestion for this lane — from slug + run date, no git writes.
   434	  // swarm-preflight (stage 2) checks it against `git branch -a`; the orchestrator (stage 3) prompts
   435	  // the operator before cutting it. Carve-out (low-risk, independent zone) is applied by the
   436	  // orchestrator, not here — this planner emits the same deterministic name for every item.
   437	  const suggestedBranch = `marathon/${slug}-${TODAY}`;
   438	  const rec = {
   439	    title: item.title, section: item.section, emoji: item.status, raw: item.raw,
   440	    gh, docRel, docExists, slug, ratings, rated, ratingsExempt, contract,
   441	    zone: z.zone, zoneInferred: z.inferred, writeset: z.writeset,
   442	    deps: depsOf(item), goGated: isGoGated(item), suggestedBranch,
   443	    flags: [], signals: [], state: null, score: null, wave: null, ghState: null,
   444	  };
   445	  records.push(rec);
   446	}
   447	
   448	// Dedup identical (gh, docRel) pairs (e.g. an umbrella epic re-listing a child) — keep the first.
   449	const seen = new Set();
   450	const deduped = [];
   451	for (const r of records) {
   452	  // Dedup same-issue-different-title by gh when present (one issue = one canonical item); fall back to
   453	  // docRel+title for issue-less notes so distinct field-findings that share one doc anchor stay separate.
   454	  const key = r.gh != null ? `gh:${r.gh}` : `doc:${r.docRel || ""}|title:${r.title}`;
   455	  if (seen.has(key)) continue;
   456	  seen.add(key); deduped.push(r);
   457	}
   458	
   459	// ── per-item validation signals (deterministic; each a flag, never a fix) ─────
   460	let ghUnverified = 0;
   461	for (const r of deduped) {
   462	  // note-only: no issue AND no doc → nothing to build.
   463	  if (r.gh == null && !r.docRel) { r.state = "note-only"; flag("info", "note-only", r, "ledger note with no issue and no project doc — nothing to sequence", "human: action or drop the note"); continue; }
   464	
   465	  // dead pointer
   466	  if (r.docRel && !r.docExists) flag("warn", "drift", r, `project doc pointer does not exist on disk: ${r.docRel}`, "fix or drop the ledger link");
   467	
   468	  // gh state
   469	  if (r.gh != null) {
   470	    const st = ghState(r.gh);
   471	    r.ghState = st;
   472	    if (st == null && GH_MODE === "off") { ghUnverified++; r.flags.push("gh-unverified"); }
   473	    if (st === "CLOSED" && (r.section === "Queue / parked intake" || r.section === "In progress")) {
   474	      r.state = "already-closed";
   475	      flag("warn", "already-closed", r, `issue #${r.gh} is CLOSED but the ledger lists it under "${r.section}"`, "close the ledger: move to Completed or drop the pointer");
   476	    }
   477	    if (st === "OPEN" && r.section === "Completed") {
   478	      flag("warn", "drift", r, `ledger marks this Completed but issue #${r.gh} is still OPEN`, "reopen the ledger entry or close the issue");
   479	    }
   480	  }
   481	
   482	  // already-landed: the purpose-built fix_probes ALL report "landed" (the fix is already present).
   483	  // Artifact existence is deliberately NOT a trigger here — a fix that MODIFIES an existing file always
   484	  // has its artifacts present before the fix lands (e.g. GH-37 edits an existing consult.sh). fix_probes
   485	  // are the authority swarm-preflight already trusts; artifact existence is only a partial-signal below.
   486	  if (r.state == null && r.contract && Array.isArray(r.contract.fix_probes) && r.contract.fix_probes.length) {
   487	    if (r.section !== "Completed" && r.section !== "Deferred · vision") {
   488	      const verdicts = r.contract.fix_probes.map(evalProbe);
   489	      if (verdicts.every((v) => v === "landed")) {
   490	        r.state = "already-landed";
   491	        flag("warn", "already-landed", r, "all fix_probes report 'landed' — the fix is already present", "verify-and-close, not a build lane");
   492	      }
   493	    }
   494	  }
   495	
   496	  // undocumented partial completion: ≥2 independent signals, ledger status not done.
   497	  // GH-85: stop marathon-plan undocumented-partial-completion false-positives on edit-existing-file lanes
   498	  if (r.state == null) {
   499	    const sig = [];
   500	    if (r.contract && Array.isArray(r.contract.artifacts)) {
   501	      const ref = (r.contract.target && r.contract.target.ref) || "HEAD";
   502	      const hasNewArtifact = r.contract.artifacts.some((a) => existsAt(a) && !fileExistedAtBaseRef(a, ref));
   503	      if (hasNewArtifact) sig.push("some-artifacts-exist");
   504	    }
   505	    if (branchMatchesSlug(r.slug)) sig.push("branch-matches-slug");
   506	    try { if (fs.readdirSync(path.join(ROOT, "test")).some((f) => f.toLowerCase().includes(r.slug))) sig.push("tests-reference-slug"); } catch {}
   507	    if (r.emoji === "🟢" && r.section !== "Completed") sig.push("built-not-closed-emoji");
   508	    r.signals = sig;
   509	    if (sig.length >= 2) {
   510	      r.state = "partial";
   511	      flag("warn", "undocumented-partial-completion", r, `${sig.length} signals of work not reflected in ledger status: ${sig.join(", ")}`, "human: reconcile — confirm scope done vs remaining, update ledger status");
   512	    }
   513	  }
   514	
   515	  // (unrated is emitted in the readiness loop below, gated to sequenceable sections — Completed and
   516	  // Deferred items never need ratings, so flagging them here would be pure noise.)
   517	}
   518	
   519	// run-level drift: a 2-WORKING doc with no ledger pointer (coverage rule, like pdda-check-roadmap-coverage).
   520	// Walk RECURSIVELY (incl. briefs/ etc.) to match pdda_list_working_docs' `find`, skipping blank.md.
   521	function listMdRecursive(dir) {
   522	  const out = [];
   523	  let ents = [];
   524	  try { ents = fs.readdirSync(dir, { withFileTypes: true }); } catch { return out; }
   525	  for (const e of ents) {
   526	    const full = path.join(dir, e.name);
   527	    if (e.isDirectory()) out.push(...listMdRecursive(full));
   528	    else if (e.name.endsWith(".md") && e.name !== "blank.md") out.push(full);
   529	  }
   530	  return out;
   531	}
   532	(function coverageDrift() {
   533	  // "Pointed" = referenced by ANY ledger link (primary doc OR a secondary link like `brief: [...]`),
   534	  // matching pdda-check-roadmap-coverage.sh which greps the whole ROADMAP — not just each item's primary doc.
   535	  const pointed = new Set();
   536	  for (const it of ledger) for (const l of it.links) {
   537	    const t = l.target.replace(/#.*$/, "");
   538	    if (t.endsWith(".md")) pointed.add(path.basename(t));
   539	  }
   540	  for (const full of listMdRecursive(E.QP_QUEUE_DIR)) {
   541	    const base = path.basename(full);
   542	    if (/^(MARATHON-PLAN|QUEUE)-\d{4}-\d\d-\d\d\.md$/.test(base)) continue;  // generated plan docs don't need a pointer (MARATHON-PLAN- new; QUEUE- historical)
   543	    if (pointed.has(base)) continue;
   544	    const fm = frontmatter(full);                            // honor roadmap_exempt (align with the coverage check)
   545	    if (String(fm.roadmap_exempt || "").toLowerCase() === "true") continue;
   546	    findings.push({ severity: "info", type: "drift", item: base, file: path.relative(ROOT, full), message: "2-WORKING doc has no ROADMAP ledger pointer", action: "add a ledger pointer or set roadmap_exempt: true" });
   547	  }
   548	})();
   549	
   550	// ── readiness classification ─────────────────────────────────────────────────
   551	// Held buckets are never placed in an active wave. "ready" items are scored + waved.
   552	for (const r of deduped) {
   553	  if (r.state) continue;                                  // note-only / already-closed / already-landed / partial
   554	  if (r.section === "Completed") { r.state = "completed-ref"; continue; }
   555	  if (r.section === "Deferred · vision") { r.state = "deferred"; continue; }
   556	  if (r.ratingsExempt) { r.state = "exempt"; continue; }  // deliberately not rated (completed/hub/superseded)
   557	  if (r.gh != null && !r.docRel) { r.state = "needs-doc"; flag("info", "needs-doc", r, `issue #${r.gh} has no PROJECT capture doc linked in the ledger`, "promote to a 2-WORKING capture doc with a preflight contract"); continue; }
   558	  if (r.docExists && !r.rated) {
   559	    r.state = "unrated";
   560	    const missing = ["complexity", "risk", "effort"].filter((k) => r.ratings[k] == null);
   561	    flag("info", "unrated", r, `project doc missing rating key(s): ${missing.join(", ")}`, "add complexity/risk/effort frontmatter (see PDDA.md)");
   562	    continue;
   563	  }
   564	  if (r.docExists && !r.contract) { r.state = "needs-contract"; flag("info", "needs-contract", r, "rated, but no preflight contract — not marathon-ready", "add a ## Swarm Preflight Contract json block"); continue; }
   565	  if (r.goGated) { r.state = "gated"; continue; }         // scored for visibility, parked from active waves
   566	  r.state = "ready";
   567	}
   568	
   569	// Optional deep delegation: per ready item with a doc, run swarm-preflight --dry-run and downgrade.
   570	if (DEEP && SWARM_PREFLIGHT) {
   571	  for (const r of deduped) {
   572	    if (r.state !== "ready" || !r.docRel) continue;
   573	    let code = 0;
   574	    try { execSync(`bash ${JSON.stringify(SWARM_PREFLIGHT)} --project-doc ${JSON.stringify(r.docRel)} --dry-run`, { cwd: ROOT, stdio: "ignore" }); }
   575	    catch (e) { code = e.status || 1; }
   576	    if (code === 4) { r.state = "already-landed"; flag("warn", "already-landed", r, "swarm-preflight --dry-run → stale (exit 4)", "verify-and-close, not a build lane"); }
   577	    else if (code === 5) { r.state = "not-ready"; flag("info", "not-ready", r, "swarm-preflight --dry-run → not marathon-ready (exit 5)", "see swarm-preflight next-action"); }
   578	    else if (code === 6 || code === 7) { r.state = "blocked"; flag("info", "blocked", r, `swarm-preflight --dry-run → ${code === 6 ? "blocked" : "ambiguous"} (exit ${code})`, "resolve target/contract before sequencing"); }
   579	  }
   580	}
   581	
   582	// ── dependency resolution (before scoring/packing) ───────────────────────────
   583	// A dependency in one of these states is "resolved" — done or deliberately out of the active plan —
   584	// so it never blocks its dependent. Anything else (ready/unrated/needs-*/gated/...) must be built first.
   585	const DEP_RESOLVED = new Set(["completed-ref", "already-landed", "already-closed", "deferred", "exempt", "note-only"]);
   586	
   587	// Warn on a dependency that names an issue absent from the ledger (likely a typo / missing pointer).
   588	for (const r of deduped) for (const d of r.deps) {
   589	  if (!deduped.some((x) => x.gh === d)) flag("info", "dep-not-found", r, `lists a dependency on #${d}, which is not in the ledger`, "fix the issue number or add a ledger pointer");
   590	}
   591	
   592	// Exclude (don't merely defer) a ready item whose dependency can NEVER be built — a dep that is held/
   593	// unbuildable (unrated / needs-doc / needs-contract / gated / not-ready / blocked) and not itself ready.
   594	// Marking it blocked-dep keeps it OUT of the active waves instead of flushing it into a trailing wave
   595	// (agy QA r3 [Should]). Iterate to a fixpoint so the block propagates transitively (A→B→held).
   596	let depChanged = true;
   597	while (depChanged) {
   598	  depChanged = false;
   599	  for (const r of deduped) {
   600	    if (r.state !== "ready") continue;
   601	    const blockedBy = r.deps.filter((d) => {
   602	      const dep = deduped.find((x) => x.gh === d);
   603	      if (!dep || DEP_RESOLVED.has(dep.state) || dep.state === "ready") return false;
   604	      return true;                                   // dep is held / blocked-dep ⇒ unbuildable
   605	    });
   606	    if (blockedBy.length) {
   607	      r.state = "blocked-dep"; depChanged = true;
   608	      flag("info", "blocked-dep", r, `depends on a held/unbuildable item (${blockedBy.map((d) => "#" + d).join(", ")}) — excluded from active waves until the dependency is sequenceable`, "rate/unblock the dependency first");
   609	    }
   610	  }
   611	}
   612	
   613	// ── scoring (printed per item; deterministic) ─────────────────────────────────
   614	const W = { eff: 2, cx: 1, risk: 2, dep: 3, zone: 1 };
   615	const RISK_SIGN = POLICY === "derisk-first" ? -1 : 1;
   616	const RISK_W = POLICY === "derisk-first" ? 4 : W.risk;
   617	const ZONE_PEN = { independent: 0, shim: 1, kernel: 2 };
   618	function scoreOf(r) {
   619	  // Held-but-scored (gated) items get the GO penalty so they sort after active work but keep a
   620	  // sensible relative order. Only items with full ratings are scored; others are held out.
   621	  if (!r.rated) return null;
   622	  let s = W.eff * r.ratings.effort + W.cx * r.ratings.complexity + RISK_SIGN * RISK_W * r.ratings.risk;
   623	  s += W.dep * r.deps.length + W.zone * ZONE_PEN[r.zone];
   624	  if (r.state === "gated") s += 100;
   625	  return s;
   626	}
   627	for (const r of deduped) r.score = scoreOf(r);
   628	
   629	// ── wave packing (collision-safe; ≤1 kernel item per wave; deps push later) ───
   630	const active = deduped.filter((r) => r.state === "ready").sort((a, b) => {
   631	  if (a.score !== b.score) return a.score - b.score;
   632	  if (a.deps.length !== b.deps.length) return a.deps.length - b.deps.length;
   633	  const zr = { independent: 0, shim: 1, kernel: 2 };
   634	  if (zr[a.zone] !== zr[b.zone]) return zr[a.zone] - zr[b.zone];
   635	  if ((a.gh || 1e9) !== (b.gh || 1e9)) return (a.gh || 1e9) - (b.gh || 1e9);
   636	  return a.slug < b.slug ? -1 : a.slug > b.slug ? 1 : 0;
   637	});
   638	
   639	const waves = [];
   640	const placedIssue = new Map(); // gh issue → wave index it landed in (for dep ordering)
   641	const pending = active.slice();
   642	let guard = 0;
   643	while (pending.length && guard++ < 100) {
   644	  const wave = [];
   645	  const waveWriteset = new Set();
   646	  let kernelTaken = false;
   647	  const deferred = [];
   648	  for (const r of pending) {
   649	    // dependency: a dep is satisfied only if it is genuinely resolved (done/landed/closed/out-of-scope)
   650	    // OR already placed in an earlier wave. A dep that is merely HELD (unrated/needs-contract/gated) is
   651	    // NOT in `active` but is also not built — so it must still block its dependent (agy QA [Blocker]).
   652	    const depUnmet = r.deps.some((d) => {
   653	      const dep = deduped.find((x) => x.gh === d);
   654	      if (!dep || DEP_RESOLVED.has(dep.state)) return false;
   655	      return !placedIssue.has(d);
   656	    });
   657	    const collides = r.writeset.some((p) => waveWriteset.has(p));
   658	    const kernelClash = r.zone === "kernel" && kernelTaken;
   659	    // zone-inferred shim items (no proven write-set) conservatively can't share a wave with another shim.
   660	    const inferredShimClash = r.zone === "shim" && r.zoneInferred && wave.some((w) => w.zone === "shim");
   661	    if (depUnmet || collides || kernelClash || inferredShimClash) { deferred.push(r); continue; }
   662	    wave.push(r);
   663	    r.writeset.forEach((p) => waveWriteset.add(p));
   664	    if (r.zone === "kernel") kernelTaken = true;
   665	  }
   666	  if (wave.length === 0) { // unbreakable dep cycle / all deferred — flush remainder to its own wave
   667	    waves.push(deferred); deferred.forEach((r) => { if (r.gh != null) placedIssue.set(r.gh, waves.length - 1); });
   668	    break;
   669	  }
   670	  waves.push(wave);
   671	  wave.forEach((r) => { if (r.gh != null) placedIssue.set(r.gh, waves.length - 1); });
   672	  pending.length = 0; pending.push(...deferred);
   673	}
   674	waves.forEach((w, i) => w.forEach((r) => (r.wave = i + 1)));
   675	
   676	// GH-5: within each wave, flag pairs of write-disjoint lanes that share a directory spine — they
   677	// likely share a contract seam. Advisory (never re-waves them): the fix is to pin a contract, after
   678	// which they run parallel safely. Only lanes with a PROVEN write-set (from a contract) are judged.
   679	const contractSeams = [];
   680	for (const w of waves) {
   681	  for (let i = 0; i < w.length; i++) {
   682	    for (let j = i + 1; j < w.length; j++) {
   683	      const a = w[i], b = w[j];
   684	      if (!a.writeset.length || !b.writeset.length) continue;
   685	      const spine = sharedSpine(a.writeset, b.writeset);
   686	      if (spine) {
   687	        contractSeams.push({ wave: a.wave, a, b, spine });
   688	        flag("warn", "coupled-lanes", a,
   689	          `same-wave lane shares the \`${spine}/\` spine with ${b.gh ? "#" + b.gh : b.slug} — write-disjoint but likely a shared contract seam`,
   690	          `pin a CONTRACT.md for the ${spine}/ interface and point both lane prompts at it before launching`);
   691	      }
   692	    }
   693	  }
   694	}
   695	
   696	// ── exit code from flags ─────────────────────────────────────────────────────
   697	const hasDrift = deduped.some((r) => r.state === "already-landed" || r.state === "already-closed");
   698	const held = deduped.filter((r) => ["unrated", "needs-doc", "needs-contract", "note-only", "not-ready", "blocked", "blocked-dep"].includes(r.state));
   699	let exitCode = 0;
   700	if (hasDrift) exitCode = 4;
   701	else if (held.length) exitCode = 5;
   702	if (GH_MODE === "off" && REQUIRE_GH) exitCode = 6;
   703	
   704	// ── report (stdout) ──────────────────────────────────────────────────────────
   705	const counts = {
   706	  queue: deduped.filter((r) => r.section === "Queue / parked intake").length,
   707	  inprog: deduped.filter((r) => r.section === "In progress").length,
   708	  active: active.length,
   709	};
   710	const weightStr = `eff:${W.eff},cx:${W.cx},risk:${RISK_W}${RISK_SIGN < 0 ? "(−)" : ""},dep:${W.dep},zone:${W.zone}`;
   711	
   712	if (FORMAT === "json") {
   713	  for (const f of findings) process.stdout.write(JSON.stringify({ timestamp: NOW, severity: f.severity, check: `marathon-plan/${f.type}`, file: f.file || "", message: f.message, action: f.action }) + "\n");
   714	  process.stdout.write(JSON.stringify({ timestamp: NOW, severity: exitCode ? "warn" : "info", check: "marathon-plan/summary", file: "", message: `items=${deduped.length} active=${active.length} waves=${waves.length} drift=${hasDrift} held=${held.length} gh=${GH_MODE}`, action: "summary" }) + "\n");
   715	} else {
   716	  const out = [];
   717	  out.push(`marathon-plan · ${TODAY} · policy=${POLICY} · weights{${weightStr}} · gh=${GH_MODE}`);
   718	  out.push(`  ledger items : ${deduped.length}  (queue ${counts.queue} · in-progress ${counts.inprog})`);
   719	  out.push(`  active lanes : ${active.length} across ${waves.length} wave(s)   held: ${held.length}` + (ghUnverified ? `   gh-unverified: ${ghUnverified}` : ""));
   720	  if (GH_MODE === "off") out.push(`  NOTE gh ${E.QP_GH_FORCE === "off" ? "disabled" : "unavailable"}: open/closed state not verified — relying on ledger section only`);
   721	  out.push("");
   722	  out.push("FLAGS (deterministic signals — never auto-resolved)");
   723	  const order = { warn: 0, info: 1 };
   724	  const sorted = findings.slice().sort((a, b) => (order[a.severity] - order[b.severity]) || (a.type < b.type ? -1 : 1));
   725	  if (sorted.length === 0) out.push("  (none)");
   726	  for (const f of sorted) {
   727	    out.push(`  ${f.severity.toUpperCase().padEnd(4)} [${f.type}]  ${f.item}`);
   728	    out.push(`        ${f.message}`);
   729	    out.push(`        → ${f.action}`);
   730	  }
   731	  out.push("");
   732	  out.push(`SUMMARY [marathon-plan] items=${deduped.length} active=${active.length} waves=${waves.length} drift=${hasDrift} held=${held.length} (exit ${exitCode})`);
   733	  process.stdout.write(out.join("\n") + "\n");
   734	}
   735	
   736	// ── render the sequenced marathon-plan doc ───────────────────────────────────────────
   737	function cell(v) { return String(v == null ? "—" : v); }
   738	// Ratings are integers 1 (low) .. 5 (highest); render the number, or — when unrated.
   739	const ratingNum = (n) => (n >= 1 && n <= 5 ? String(n) : "—");
   740	function renderQueueDoc() {
   741	  const o = [];
   742	  o.push("---");
   743	  o.push("title: Marathon Plan — ranked, freshness-validated, collision-aware queue");
   744	  o.push("status: Active (2-WORKING)");
   745	  o.push(`created: ${TODAY}`);
   746	  o.push(`updated: ${TODAY}`);
   747	  o.push("owner: noel");
   748	  o.push("branch: main");
   749	  o.push("doc_type: project");
   750	  o.push("source: ../../ROADMAP.md (open ledger entries)");
   751	  o.push("generated_by: utils/marathon-plan.sh");
   752	  o.push("roadmap_exempt: true");
   753	  o.push("goal: >");
   754	  o.push("  A sequenced concurrency plan derived from ROADMAP.md: ranks surviving work by PDDA");
   755	  o.push("  complexity/risk/effort, validates each item is still real, and batches collision-safe");
   756	  o.push("  lanes into waves. Generated — edit the ledger, not this file.");
   757	  o.push("---");
   758	  o.push("");
   759	  o.push("<!-- GENERATED by utils/marathon-plan.sh from ROADMAP.md — re-run to refresh; edit the ledger, not this file. -->");
   760	  o.push("");
   761	  o.push(`# Marathon Plan ${TODAY} — pre-pre-flight sequenced queue`);
   762	  o.push("");
   763	  o.push(`> Derived from [ROADMAP.md](../../ROADMAP.md) · policy \`${POLICY}\` · weights {${weightStr}} · gh=${GH_MODE}.`);
   764	  o.push("> The roadmap says **what/why**; this says **what is still real and in what order**. Execution");
   765	  o.push("> detail still lives in each `PROJECT/**` doc — this is a scheduling overlay.");
   766	  o.push("");
   767	  o.push("## Status");
   768	  o.push("");
   769	  o.push("| What was just completed | What's next |");
   770	  o.push("|---|---|");
   771	  const firstWave = waves[0] ? waves[0].map((r) => r.gh ? `#${r.gh}` : r.slug).join(" ‖ ") : "(none)";
   772	  o.push(`| Generated by \`utils/marathon-plan.sh\` on ${TODAY} from the live ROADMAP ledger (${deduped.length} items; ${active.length} active across ${waves.length} wave(s); ${held.length} held). Drift present: ${hasDrift ? "yes — see Held/Flagged" : "no"}. | **Wave 1:** ${firstWave}. Fire each lane via \`swarm-preflight → marathon-drive\`, scoped by \`ALLOW_PATHS\`. Re-run this script when the ledger changes. |`);
   773	  o.push("");
   774	  o.push("## The one safety rule");
   775	  o.push("");
   776	  o.push("Two lanes are safe to run concurrently **iff their write-sets are disjoint**. The kernel");
   777	  o.push("(`relay-automation/relay-turn-lib.sh`, `bin/tick`, `relay-automation/relay-drive.sh`) is the");
   778	  o.push("serialization bottleneck: **at most one kernel lane per wave**, even in separate worktrees.");
   779	  o.push("");
   780	  o.push("## Collision map");
   781	  o.push("");
   782	  o.push("| Zone | Parallel-safe? | Active items here |");
   783	  o.push("|---|---|---|");
   784	  for (const zone of ["kernel", "shim", "independent"]) {
   785	    const items = active.filter((r) => r.zone === zone).map((r) => r.gh ? `#${r.gh}` : r.slug);
   786	    const safe = zone === "kernel" ? "❌ serialize — one at a time" : "✅ one lane per file";
   787	    o.push(`| ${zone} | ${safe} | ${items.length ? items.join(", ") : "—"} |`);
   788	  }
   789	  o.push("");
   790	  o.push("## Per-item scoring");
   791	  o.push("");
   792	  o.push("Every input is shown so the ordering is verifiable by hand (lower score = earlier).");
   793	  o.push("");
   794	  o.push("| Item | cx | risk | eff | zone | deps | score | wave |");
   795	  o.push("|---|---|---|---|---|---|---|---|");
   796	  for (const r of active) {
   797	    const id = r.gh ? `[#${r.gh}] ${r.title}` : r.title;
   798	    o.push(`| ${cell(id)} | ${ratingNum(r.ratings.complexity)} | ${ratingNum(r.ratings.risk)} | ${ratingNum(r.ratings.effort)} | ${r.zone}${r.zoneInferred ? "*" : ""} | ${r.deps.length ? r.deps.map((d) => "#" + d).join(",") : "—"} | ${cell(r.score)} | ${cell(r.wave)} |`);
   799	  }
   800	  if (active.length === 0) o.push("| (no active, ready, rated items) | — | — | — | — | — | — | — |");
   801	  o.push("");
   802	  o.push("`*` = zone inferred from keywords (no preflight contract write-set to prove it).");
   803	  o.push("");
   804	  o.push("## Recommended waves");
   805	  o.push("");
   806	  if (waves.length === 0) o.push("_No active lanes — every item is held or flagged (see below)._");
   807	  waves.forEach((w, i) => {
   808	    const lanes = w.map((r) => r.gh ? `#${r.gh}` : r.slug).join(" ‖ ");
   809	    o.push(`**Wave ${i + 1}:** ${lanes || "(empty)"}`);
   810	    o.push("");
   811	    // GH-69: suggested_branch per lane, on its own line so the "**Wave N:** #a ‖ #b" line above
   812	    // stays single-line and grep-stable (test/marathon-plan.sh's wave_of() greps that exact line).
   813	    for (const r of w) {
   814	      const id = r.gh ? `#${r.gh}` : r.slug;
   815	      o.push(`- ${id} → suggested_branch: \`${r.suggestedBranch}\``);
   816	    }
   817	    if (w.length) o.push("");
   818	  });
   819	  // GH-5: contract seams — coupled lanes that need a pinned contract before they can truly parallelize.
   820	  o.push("## Contract seams — pin a contract before launching (GH-5)");
   821	  o.push("");
   822	  if (contractSeams.length === 0) {
   823	    o.push("_None — no two same-wave lanes share a directory spine (deeper than a top-level dir)._");
   824	    o.push("");
   825	  } else {
   826	    o.push("These same-wave lanes are **write-disjoint but share a directory spine**, so they likely share");
   827	    o.push("an interface (a not-yet-built module/schema). xyz is not for tightly-coupled work: pin a short");
   828	    o.push("`CONTRACT.md` for the seam and point **each** lane's prompt at it (code TO the contract, not to");
   829	    o.push("the other lane's source), or the split can stall when the consumer waits on the producer's handoff.");
   830	    o.push("");
   831	    for (const s of contractSeams) {
   832	      const an = s.a.gh ? `#${s.a.gh}` : s.a.slug, bn = s.b.gh ? `#${s.b.gh}` : s.b.slug;
   833	      o.push(`- **Wave ${s.wave}:** ${an} ‖ ${bn} share \`${s.spine}/\` → pin a contract for that seam.`);
   834	    }
   835	    o.push("");
   836	  }
   837	  o.push("## Held / flagged — excluded from active waves");
   838	  o.push("");
   839	  const buckets = [
   840	    ["✅ Likely done — verify-and-close, not a build lane", ["already-landed", "already-closed"]],
   841	    ["🔧 Reconcile — undocumented partial completion", ["partial"]],
   842	    ["⏸️ Gated on operator GO", ["gated"]],
   843	    ["⚠️ Not yet sequenceable — rate / add doc / add contract", ["unrated", "needs-doc", "needs-contract", "not-ready", "blocked"]],
   844	    ["⛔ Blocked on a held dependency", ["blocked-dep"]],
   845	    ["🚫 Rating-exempt (completed / hub / superseded)", ["exempt"]],
   846	    ["🗒️ Notes (no issue, no doc)", ["note-only"]],
   847	  ];
   848	  for (const [label, states] of buckets) {
   849	    const items = deduped.filter((r) => states.includes(r.state));
   850	    if (items.length === 0) continue;
   851	    o.push(`### ${label}`);
   852	    for (const r of items) {
   853	      const id = r.gh ? `#${r.gh} ` : "";
   854	      const why = r.state === "gated" && r.score != null ? ` (would score ${r.score})` : "";
   855	      o.push(`- ${id}${r.title} — \`${r.state}\`${why}`);
   856	    }
   857	    o.push("");
   858	  }
   859	  o.push("## How to fire a lane");
   860	  o.push("");
   861	  o.push("Per lane, the existing pipeline applies — no new control plane:");
   862	  o.push("");
   863	  o.push("```");
   864	  o.push("utils/swarm-preflight.sh --project-doc <PROJECT/**/doc.md>   # or --gh-issue N");
   865	  o.push("   → ready packet (candidate/freshness/fix-still-required + lane assignment)");
   866	  o.push("relay-automation/marathon-drive.sh ...   # build→gate→review, contained");
   867	  o.push("```");
   868	  o.push("");
   869	  o.push("- **Lane scoping:** give each lane an `ALLOW_PATHS` matching only its zone above.");
   870	  o.push("- **Never** run two kernel lanes at once, even in separate worktrees.");
   871	  o.push("");
   872	  o.push("---");
   873	  o.push("");
   874	  o.push(`*Generated from [ROADMAP.md](../../ROADMAP.md) (source of truth). Re-run \`utils/marathon-plan.sh\` after editing the ledger.*`);
   875	  return o.join("\n") + "\n";
   876	}
   877	
   878	fs.writeFileSync(E.QP_RENDER_OUT, renderQueueDoc());
   879	process.exit(exitCode);
   880	NODE
   881	RC=$?
   882	
   883	# Node failed hard (parse error / exit 3) — pass the code straight through.
   884	if [[ "$RC" -eq 3 || "$RC" -eq 2 ]]; then
   885	  exit "$RC"
   886	fi
   887	
   888	# --check: compare the freshly-rendered doc against today's committed marathon-plan doc.
   889	if [[ "$RUN_MODE" == "check" ]]; then
   890	  if [[ ! -f "$QUEUE_DOC" ]]; then
   891	    emit "check: missing artifact: ${QUEUE_DOC#$ROOT/}"
   892	    exit 1
   893	  fi
   894	  if cmp -s "$RENDER_OUT" "$QUEUE_DOC"; then
   895	    emit "check: MARATHON-PLAN-$TODAY.md is in sync"
   896	    exit 0
   897	  fi
   898	  emit "check: drift detected in MARATHON-PLAN-$TODAY.md"
   899	  diff -u "$QUEUE_DOC" "$RENDER_OUT" >&2 || true
   900	  exit 1
   901	fi
   902	
   903	# --dry-run: report already printed; write nothing.
   904	if [[ "$RUN_MODE" == "dry-run" ]]; then
   905	  exit "$RC"
   906	fi
   907	
   908	# default: write today's marathon-plan doc.
   909	mkdir -p "$QUEUE_DIR"
   910	cp "$RENDER_OUT" "$QUEUE_DOC"
   911	emit "wrote ${QUEUE_DOC#$ROOT/}"
   912	exit "$RC"

exec
/bin/zsh -lc 'nl -ba test/marathon-plan.sh' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# test/marathon-plan.sh — regression lock for utils/marathon-plan.sh.
     3	#
     4	# Standalone (no tick/relay harness). Builds throwaway repos with a synthetic ROADMAP.md ledger +
     5	# rated capture docs + preflight contracts, and stubs git/gh via the planner's hermetic env seam
     6	# (QUEUE_PLAN_GH_STATE_FILE / QUEUE_PLAN_BRANCHES_FILE). Asserts the deterministic sequencing
     7	# (scores, waves, collision-safety), every validation signal (already-closed / already-landed /
     8	# partial / drift / unrated / note-only), the policy flip, gh degradation, and --check determinism.
     9	
    10	set -uo pipefail
    11	
    12	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    13	ROOT="$(cd "$HERE/.." && pwd)"
    14	QP="$ROOT/utils/marathon-plan.sh"
    15	
    16	WORK="$(mktemp -d "${TMPDIR:-/tmp}/marathon-plan.XXXXXX")"
    17	trap 'rm -rf "$WORK"' EXIT
    18	
    19	PASS=0; FAIL=0
    20	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    21	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
    22	
    23	DAY="2026-06-28"
    24	NOWT="2026-06-28T00:00:00Z"
    25	
    26	echo "== test: marathon-plan =="
    27	echo "  workdir: $WORK"
    28	
    29	# mk_doc <root> <filename> <cx> <risk> <eff> <contract-json>   ("-" for a rating ⇒ omit that key;
    30	#                                                                "" contract ⇒ no preflight contract)
    31	mk_doc() {
    32	  local root="$1" fn="$2" cx="$3" rk="$4" ef="$5" contract="$6"
    33	  mkdir -p "$root/PROJECT/2-WORKING"
    34	  {
    35	    printf -- '---\n'
    36	    printf 'title: %s\n' "$fn"
    37	    [ "$cx" != "-" ] && printf 'complexity: %s\n' "$cx"
    38	    [ "$rk" != "-" ] && printf 'risk: %s\n' "$rk"
    39	    [ "$ef" != "-" ] && printf 'effort: %s\n' "$ef"
    40	    printf -- '---\n\n# %s\n\n' "$fn"
    41	    [ -n "$contract" ] && printf '## Swarm Preflight Contract\n```json\n%s\n```\n' "$contract"
    42	  } >"$root/PROJECT/2-WORKING/$fn"
    43	}
    44	
    45	# run_qp <root> [args...]
    46	run_qp() {
    47	  local root="$1"; shift
    48	  QUEUE_PLAN_ROOT="$root" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" \
    49	    QUEUE_PLAN_GH_STATE_FILE="$root/.gh-state.json" QUEUE_PLAN_BRANCHES_FILE="$root/.branches" \
    50	    bash "$QP" "$@"
    51	}
    52	
    53	# wave_of <queue-doc> <issue-number> → wave number containing #N (empty if not waved)
    54	wave_of() {
    55	  grep -E '^\*\*Wave ' "$1" | grep -E "#$2([^0-9]|\$)" | sed -E 's/^\*\*Wave ([0-9]+).*/\1/' | head -1
    56	}
    57	# row_index <queue-doc> <issue-number> → line number of its per-item scoring row (sequence order)
    58	row_index() { grep -nE "\[#$2\]" "$1" | head -1 | cut -d: -f1; }
    59	
    60	contract_for() { # contract_for <missing-or-present-path> <artifact1> [artifact2]
    61	  local probe="$1"; shift
    62	  local arts="" a
    63	  for a in "$@"; do arts="$arts${arts:+,}\"$a\""; done
    64	  printf '{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"path_absent","path":"%s"}],"artifacts":[%s],"lanes":{"orchestrator_only":[]}}' "$probe" "$arts"
    65	}
    66	
    67	# ─────────────────────────────────────────────────────────────────────────────
    68	# Scenario A — sequencing & collision-safe wave packing (clean, exit 0)
    69	# ─────────────────────────────────────────────────────────────────────────────
    70	A="$WORK/A"; mkdir -p "$A"; echo '{}' >"$A/.gh-state.json"; : >"$A/.branches"
    71	mk_doc "$A" GH-100-kernela.md 2 2 2 "$(contract_for MISS_A bin/tick)"
    72	mk_doc "$A" GH-101-kernelb.md 2 2 2 "$(contract_for MISS_B relay-automation/relay-drive.sh)"
    73	mk_doc "$A" GH-102-indepa.md  2 2 2 "$(contract_for MISS_C src/indepa.js)"
    74	mk_doc "$A" GH-103-indepb.md  2 2 2 "$(contract_for MISS_D src/indepb.js)"
    75	mk_doc "$A" GH-104-shimdep.md 2 2 2 "$(contract_for MISS_E relay-automation/consult.sh)"
    76	cat >"$A/ROADMAP.md" <<EOF
    77	# Roadmap
    78	## Ledger
    79	### In progress
    80	- **GH-100 · kernelA** 🆕 — kernel lane → [d](PROJECT/2-WORKING/GH-100-kernela.md) · [#100](https://github.com/o/r/issues/100)
    81	- **GH-101 · kernelB** 🆕 — kernel lane → [d](PROJECT/2-WORKING/GH-101-kernelb.md) · [#101](https://github.com/o/r/issues/101)
    82	- **GH-102 · indepA** 🆕 — independent → [d](PROJECT/2-WORKING/GH-102-indepa.md) · [#102](https://github.com/o/r/issues/102)
    83	- **GH-103 · indepB** 🆕 — independent → [d](PROJECT/2-WORKING/GH-103-indepb.md) · [#103](https://github.com/o/r/issues/103)
    84	- **GH-104 · shimDep** 🆕 — shim, scheduled after GH-100 → [d](PROJECT/2-WORKING/GH-104-shimdep.md) · [#104](https://github.com/o/r/issues/104)
    85	EOF
    86	out="$(run_qp "$A" 2>/dev/null)"; rc=$?
    87	doc="$A/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
    88	[[ $rc -eq 0 ]] && pass "A: clean plan → exit 0" || fail "A: expected exit 0, got $rc"
    89	[[ -f "$doc" ]] && pass "A: MARATHON-PLAN doc written" || fail "A: MARATHON-PLAN doc not written"
    90	grep -q "active lanes : 5 across 2 wave(s)" <<<"$out" && pass "A: 5 active across 2 waves" || fail "A: wrong active/wave count — $(grep 'active lanes' <<<"$out")"
    91	[[ "$(wave_of "$doc" 102)" == "1" && "$(wave_of "$doc" 103)" == "1" ]] && pass "A: two disjoint independents share Wave 1" || fail "A: indeps not both Wave 1 (102=$(wave_of "$doc" 102) 103=$(wave_of "$doc" 103))"
    92	ka="$(wave_of "$doc" 100)"; kb="$(wave_of "$doc" 101)"
    93	[[ -n "$ka" && -n "$kb" && "$ka" != "$kb" ]] && pass "A: two kernel items never share a wave (100=$ka 101=$kb)" || fail "A: kernel items shared a wave (100=$ka 101=$kb)"
    94	sd="$(wave_of "$doc" 104)"
    95	[[ -n "$sd" && -n "$ka" && "$sd" -gt "$ka" ]] && pass "A: shim dep-on-kernel sequenced strictly later (shim=$sd kernel=$ka)" || fail "A: shim not after its kernel dep (shim=$sd kernel=$ka)"
    96	
    97	# GH-69: deterministic suggested_branch per active lane, from slug + run date — no git writes.
    98	grep -qF 'suggested_branch: `marathon/gh-100-kernela-'"$DAY"'`' "$doc" \
    99	  && pass "A: #100 gets a deterministic suggested_branch" \
   100	  || fail "A: #100 missing suggested_branch line"
   101	[[ "$(grep -cF 'suggested_branch: `marathon/' "$doc")" -eq 5 ]] \
   102	  && pass "A: all 5 active lanes carry a suggested_branch" \
   103	  || fail "A: expected 5 suggested_branch lines, got $(grep -cF 'suggested_branch: `marathon/' "$doc")"
   104	# Same-day re-run is deterministic (byte-identical slug+date ⇒ same branch name).
   105	run_qp "$A" >/dev/null 2>&1
   106	grep -qF 'suggested_branch: `marathon/gh-100-kernela-'"$DAY"'`' "$doc" \
   107	  && pass "A: suggested_branch is stable across a same-day re-run" \
   108	  || fail "A: suggested_branch drifted on re-run"
   109	
   110	# ─────────────────────────────────────────────────────────────────────────────
   111	# Scenario B — validation signals (drift present, exit 4)
   112	# ─────────────────────────────────────────────────────────────────────────────
   113	B="$WORK/B"; mkdir -p "$B"; echo "gh-220-partial" >"$B/.branches"
   114	echo '{"200":"CLOSED","221":"OPEN"}' >"$B/.gh-state.json"
   115	touch "$B/LANDED_FILE"                                   # makes the already-landed probe report "landed"
   116	printf 'changelog mentions gh-220-partial here\n' >"$B/CHANGELOG.md"
   117	mk_doc "$B" GH-200-closed.md   2 2 2 "$(contract_for MISS_X src/x.js)"
   118	mk_doc "$B" GH-210-landed.md   2 2 2 "$(contract_for LANDED_FILE src/y.js)"
   119	mk_doc "$B" GH-220-partial.md  2 2 2 "$(contract_for MISS_P src/p.js)"
   120	mk_doc "$B" GH-221-onesig.md   2 2 2 "$(contract_for MISS_O src/o.js)"
   121	mk_doc "$B" GH-230-unrated.md  2 -   2 "$(contract_for MISS_U src/u.js)"
   122	mk_doc "$B" GH-250-gated.md    2 2 2 "$(contract_for MISS_G src/g.js)"
   123	cat >"$B/ROADMAP.md" <<EOF
   124	# Roadmap
   125	## Ledger
   126	### In progress
   127	- **GH-200 · closed item** 🟡 — listed but closed → [d](PROJECT/2-WORKING/GH-200-closed.md) · [#200](https://github.com/o/r/issues/200)
   128	- **GH-210 · landed item** 🟢 — built → [d](PROJECT/2-WORKING/GH-210-landed.md) · [#210](https://github.com/o/r/issues/210)
   129	- **GH-220 · partial item** 🟢 — partly built → [d](PROJECT/2-WORKING/GH-220-partial.md) · [#220](https://github.com/o/r/issues/220)
   130	- **GH-221 · onesig item** 🟢 — only the emoji signal → [d](PROJECT/2-WORKING/GH-221-onesig.md) · [#221](https://github.com/o/r/issues/221)
   131	- **GH-250 · gated item** 🟡 — gated on operator GO → [d](PROJECT/2-WORKING/GH-250-gated.md) · [#250](https://github.com/o/r/issues/250)
   132	### Queue / parked intake
   133	- **GH-230 · unrated item** 🆕 — missing a rating → [d](PROJECT/2-WORKING/GH-230-unrated.md) · [#230](https://github.com/o/r/issues/230)
   134	- **GH-240 · dead pointer** 🆕 — doc link is broken → [d](PROJECT/2-WORKING/GH-240-missing.md) · [#240](https://github.com/o/r/issues/240)
   135	- **Just a field note** 🐞 — a finding with no issue and no doc, nothing to build.
   136	EOF
   137	out="$(run_qp "$B" 2>/dev/null)"; rc=$?
   138	doc="$B/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
   139	[[ $rc -eq 4 ]] && pass "B: drift present → exit 4" || fail "B: expected exit 4, got $rc"
   140	grep -q "already-closed.*closed item\|already-closed]  GH-200" <<<"$out" && pass "B: #200 flagged already-closed" || fail "B: #200 not flagged already-closed"
   141	[[ -z "$(wave_of "$doc" 200)" ]] && pass "B: closed item excluded from waves" || fail "B: closed item appeared in a wave"
   142	grep -q "already-landed]  GH-210" <<<"$out" && pass "B: #210 flagged already-landed (fix_probes landed)" || fail "B: #210 not flagged already-landed"
   143	[[ -z "$(wave_of "$doc" 210)" ]] && pass "B: landed item excluded from waves" || fail "B: landed item appeared in a wave"
   144	grep -q "undocumented-partial-completion]  GH-220" <<<"$out" && pass "B: #220 flagged partial (2 signals)" || fail "B: #220 not flagged partial"
   145	! grep -q "undocumented-partial-completion]  GH-221" <<<"$out" && pass "B: #221 NOT flagged partial (1 signal < threshold)" || fail "B: #221 wrongly flagged partial"
   146	[[ -n "$(wave_of "$doc" 221)" ]] && pass "B: one-signal item still active (in a wave)" || fail "B: one-signal item not active"
   147	grep -q "unrated]  GH-230" <<<"$out" && pass "B: #230 flagged unrated" || fail "B: #230 not flagged unrated"
   148	grep -qE "drift].*(dead pointer|GH-240|missing)" <<<"$out" && pass "B: dead doc pointer flagged drift" || fail "B: dead pointer not flagged"
   149	grep -q "note-only]" <<<"$out" && pass "B: note-only bullet flagged" || fail "B: note-only not flagged"
   150	grep -q "Gated on operator GO" "$doc" && grep -q "#250" "$doc" && pass "B: gated item parked in Held/Gated bucket" || fail "B: gated item not in gated bucket"
   151	[[ -z "$(wave_of "$doc" 250)" ]] && pass "B: gated item excluded from active waves" || fail "B: gated item appeared in a wave"
   152	
   153	# ─────────────────────────────────────────────────────────────────────────────
   154	# Scenario C — policy flip (quick-wins vs derisk-first reverse a high-risk item)
   155	# ─────────────────────────────────────────────────────────────────────────────
   156	C="$WORK/C"; mkdir -p "$C"; echo '{}' >"$C/.gh-state.json"; : >"$C/.branches"
   157	mk_doc "$C" GH-300-low.md  2 2  2 "$(contract_for MISS_L src/low.js)"
   158	mk_doc "$C" GH-301-high.md 2 4 2 "$(contract_for MISS_H src/high.js)"
   159	cat >"$C/ROADMAP.md" <<EOF
   160	# Roadmap
   161	## Ledger
   162	### In progress
   163	- **GH-300 · low risk** 🆕 — → [d](PROJECT/2-WORKING/GH-300-low.md) · [#300](https://github.com/o/r/issues/300)
   164	- **GH-301 · high risk** 🆕 — → [d](PROJECT/2-WORKING/GH-301-high.md) · [#301](https://github.com/o/r/issues/301)
   165	EOF
   166	run_qp "$C" >/dev/null 2>&1; doc="$C/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
   167	[[ "$(row_index "$doc" 300)" -lt "$(row_index "$doc" 301)" ]] && pass "C: quick-wins ranks low-risk first" || fail "C: quick-wins order wrong"
   168	run_qp "$C" --policy derisk-first >/dev/null 2>&1
   169	[[ "$(row_index "$doc" 301)" -lt "$(row_index "$doc" 300)" ]] && pass "C: derisk-first ranks high-risk first (order flipped)" || fail "C: derisk-first did not flip order"
   170	
   171	# ─────────────────────────────────────────────────────────────────────────────
   172	# Scenario D — gh degradation
   173	# ─────────────────────────────────────────────────────────────────────────────
   174	QUEUE_PLAN_ROOT="$C" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" QUEUE_PLAN_GH=off \
   175	  bash "$QP" --dry-run >"$WORK/qp_d.out" 2>/dev/null; rc=$?
   176	[[ $rc -eq 0 ]] && pass "D: gh disabled → still emits a plan, exit 0" || fail "D: gh-off expected exit 0, got $rc"
   177	grep -q "gh=off" "$WORK/qp_d.out" && pass "D: report announces gh=off" || fail "D: gh=off not announced"
   178	QUEUE_PLAN_ROOT="$C" QUEUE_PLAN_TODAY="$DAY" QUEUE_PLAN_NOW="$NOWT" QUEUE_PLAN_GH=off \
   179	  bash "$QP" --dry-run --require-gh >/dev/null 2>&1; rc=$?
   180	[[ $rc -eq 6 ]] && pass "D: --require-gh + gh-off → exit 6" || fail "D: expected exit 6, got $rc"
   181	
   182	# ─────────────────────────────────────────────────────────────────────────────
   183	# Scenario E — --check determinism / drift guard
   184	# ─────────────────────────────────────────────────────────────────────────────
   185	run_qp "$C" >/dev/null 2>&1                       # write today's MARATHON-PLAN doc
   186	run_qp "$C" --check >/dev/null 2>&1; rc=$?
   187	[[ $rc -eq 0 ]] && pass "E: --check in sync → exit 0" || fail "E: --check expected exit 0, got $rc"
   188	printf '\n- **Drifted note** 🐞 — a new ledger note, no issue, no doc.\n' >>"$C/ROADMAP.md"
   189	run_qp "$C" --check >/dev/null 2>&1; rc=$?
   190	[[ $rc -eq 1 ]] && pass "E: ledger change → --check detects drift (exit 1)" || fail "E: --check did not detect drift, got $rc"
   191	
   192	# ─────────────────────────────────────────────────────────────────────────────
   193	# Scenario F — JSON output shape
   194	# ─────────────────────────────────────────────────────────────────────────────
   195	json="$(run_qp "$A" --dry-run --format json 2>/dev/null)"
   196	echo "$json" | while IFS= read -r line; do [ -n "$line" ] && printf '%s' "$line" | node -e 'JSON.parse(require("fs").readFileSync(0,"utf8"))' || exit 1; done \
   197	  && pass "F: --format json emits one valid JSON object per line" || fail "F: json lines not all valid"
   198	grep -q '"check":"marathon-plan/summary"' <<<"$json" && pass "F: json includes a summary record" || fail "F: json summary missing"
   199	
   200	# ─────────────────────────────────────────────────────────────────────────────
   201	# Scenario G — agy QA [Blocker]: a dep on a HELD (not-built) item must defer the dependent
   202	# ─────────────────────────────────────────────────────────────────────────────
   203	G="$WORK/G"; mkdir -p "$G"; echo '{}' >"$G/.gh-state.json"; : >"$G/.branches"
   204	mk_doc "$G" GH-700-free.md   2 2 2 "$(contract_for MISS_F  src/free.js)"
   205	mk_doc "$G" GH-701-dephld.md 2 2 2 "$(contract_for MISS_DH src/dephld.js)"
   206	mk_doc "$G" GH-710-held.md   2 -   2 "$(contract_for MISS_HE src/held.js)"   # unrated ⇒ held
   207	cat >"$G/ROADMAP.md" <<EOF
   208	# Roadmap
   209	## Ledger
   210	### In progress
   211	- **GH-700 · free** 🆕 — → [d](PROJECT/2-WORKING/GH-700-free.md) · [#700](https://github.com/o/r/issues/700)
   212	- **GH-701 · dep on held** 🆕 — depends on GH-710 → [d](PROJECT/2-WORKING/GH-701-dephld.md) · [#701](https://github.com/o/r/issues/701)
   213	- **GH-710 · held (unrated)** 🆕 — → [d](PROJECT/2-WORKING/GH-710-held.md) · [#710](https://github.com/o/r/issues/710)
   214	EOF
   215	out="$(run_qp "$G" 2>/dev/null)"; doc="$G/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
   216	w700="$(wave_of "$doc" 700)"; w701="$(wave_of "$doc" 701)"
   217	{ [[ "$w700" == "1" && -z "$w701" ]] && grep -q "blocked-dep]  GH-701" <<<"$out"; } && pass "G: dep on a HELD item EXCLUDES the dependent (700=wave$w700; 701 blocked-dep, not waved) [agy Blocker r1+r3]" || fail "G: dependent-on-held not excluded (700=$w700 701=$w701)"
   218	
   219	# ─────────────────────────────────────────────────────────────────────────────
   220	# Scenario H — agy QA [Should]: comma-separated deps must ALL be parsed
   221	# ─────────────────────────────────────────────────────────────────────────────
   222	H="$WORK/H"; mkdir -p "$H"; echo '{}' >"$H/.gh-state.json"; : >"$H/.branches"
   223	mk_doc "$H" GH-800-k1.md    2 2 2 "$(contract_for MISS_K1 bin/tick)"
   224	mk_doc "$H" GH-801-k2.md    2 2 2 "$(contract_for MISS_K2 relay-automation/relay-drive.sh)"
   225	mk_doc "$H" GH-803-k3.md    2 2 2 "$(contract_for MISS_K3 relay-automation/relay-turn-lib.sh)"
   226	mk_doc "$H" GH-802-multi.md 2 2 2 "$(contract_for MISS_M  src/multi.js)"
   227	cat >"$H/ROADMAP.md" <<EOF
   228	# Roadmap
   229	## Ledger
   230	### In progress
   231	- **GH-800 · kernel1** 🆕 — → [d](PROJECT/2-WORKING/GH-800-k1.md) · [#800](https://github.com/o/r/issues/800)
   232	- **GH-801 · kernel2** 🆕 — → [d](PROJECT/2-WORKING/GH-801-k2.md) · [#801](https://github.com/o/r/issues/801)
   233	- **GH-803 · kernel3** 🆕 — → [d](PROJECT/2-WORKING/GH-803-k3.md) · [#803](https://github.com/o/r/issues/803)
   234	- **GH-802 · multi-dep** 🆕 — depends on GH-800, GH-801, and GH-803 → [d](PROJECT/2-WORKING/GH-802-multi.md) · [#802](https://github.com/o/r/issues/802)
   235	EOF
   236	run_qp "$H" >/dev/null 2>&1; doc="$H/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
   237	w800="$(wave_of "$doc" 800)"; w801="$(wave_of "$doc" 801)"; w803="$(wave_of "$doc" 803)"; w802="$(wave_of "$doc" 802)"
   238	# Oxford-comma "GH-800, GH-801, and GH-803" — all three must parse, so the dependent follows the LAST (803).
   239	[[ -n "$w802" && "$w802" -gt "$w800" && "$w802" -gt "$w801" && "$w802" -gt "$w803" ]] && pass "H: oxford-comma deps all parsed — multi-dep follows ALL kernels (800=$w800 801=$w801 803=$w803 802=$w802) [agy Blocker r2]" || fail "H: oxford-comma deps not all honored (800=$w800 801=$w801 803=$w803 802=$w802)"
   240	
   241	# ─────────────────────────────────────────────────────────────────────────────
   242	# Scenario I — agy QA [Blocker r4]: title GH-NN is canonical, beats an in-prose issue link
   243	# ─────────────────────────────────────────────────────────────────────────────
   244	I="$WORK/I"; mkdir -p "$I"; : >"$I/.branches"
   245	echo '{"910":"OPEN","911":"CLOSED"}' >"$I/.gh-state.json"
   246	mk_doc "$I" GH-910-epic.md 2 2 2 "$(contract_for MISS_E2 src/epic.js)"
   247	cat >"$I/ROADMAP.md" <<EOF
   248	# Roadmap
   249	## Ledger
   250	### In progress
   251	- **GH-910 · epic umbrella** 🆕 — sequences the sub-issue [#911](https://github.com/o/r/issues/911) → [d](PROJECT/2-WORKING/GH-910-epic.md) · [#910](https://github.com/o/r/issues/910)
   252	EOF
   253	out="$(run_qp "$I" 2>/dev/null)"; doc="$I/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
   254	{ [[ "$(wave_of "$doc" 910)" == "1" ]] && ! grep -q "already-closed" <<<"$out"; } && pass "I: title GH-910 wins over the in-prose closed #911 (item stays active, not already-closed) [agy Blocker r4]" || fail "I: ghIssueOf precedence wrong — $(grep -E 'already-closed' <<<"$out" | head -1)"
   255	
   256	# ─────────────────────────────────────────────────────────────────────────────
   257	# Scenario J — GH-85 regression cases for undocumented-partial-completion false-positives
   258	# ─────────────────────────────────────────────────────────────────────────────
   259	J="$WORK/J"; mkdir -p "$J"; : >"$J/.branches"
   260	echo '{}' >"$J/.gh-state.json"
   261	
   262	# (a) A rated+contracted lane whose artifacts all pre-exist AND whose #n is in CHANGELOG is classified READY / active (not partial).
   263	printf 'changelog mentions gh-950-existing here (#950)\n' >"$J/CHANGELOG.md"
   264	mkdir -p "$J/src"
   265	touch "$J/src/existing_art.js"
   266	echo "src/existing_art.js" >"$J/.base-files"
   267	mk_doc "$J" GH-950-existing.md 2 2 2 "$(contract_for MISS_EXP src/existing_art.js)"
   268	
   269	# (b) A lane with genuine partial signals (branch-matches-slug + tests-reference-slug) is STILL partial.
   270	echo "gh-951-genuine" >"$J/.branches"
   271	mkdir -p "$J/test"
   272	touch "$J/test/gh-951-genuine-test.sh"
   273	mk_doc "$J" GH-951-genuine.md 2 2 2 "$(contract_for MISS_GEN src/genuine_art.js)"
   274	
   275	cat >"$J/ROADMAP.md" <<EOF
   276	# Roadmap
   277	## Ledger
   278	### In progress
   279	- **GH-950 · existing artifact** 🆕 — all artifacts pre-exist → [d](PROJECT/2-WORKING/GH-950-existing.md) · [#950](https://github.com/o/r/issues/950)
   280	- **GH-951 · genuine partial** 🆕 — genuine partial signals → [d](PROJECT/2-WORKING/GH-951-genuine.md) · [#951](https://github.com/o/r/issues/951)
   281	EOF
   282	
   283	out="$(QUEUE_PLAN_BASE_FILES_FILE="$J/.base-files" run_qp "$J" 2>/dev/null)"
   284	doc="$J/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
   285	
   286	if ! grep -q "undocumented-partial-completion.*GH-950" <<<"$out" && [[ "$(wave_of "$doc" 950)" == "1" ]]; then
   287	  pass "J: (a) edit-existing-file lane in CHANGELOG is READY / active (not partial) [GH-85]"
   288	else
   289	  fail "J: (a) edit-existing-file lane was wrongly flagged partial or excluded from waves"
   290	fi
   291	
   292	if grep -q "undocumented-partial-completion.*GH-951" <<<"$out" && [[ -z "$(wave_of "$doc" 951)" ]]; then
   293	  pass "J: (b) lane with genuine partial signals is STILL partial [GH-85]"
   294	else
   295	  fail "J: (b) lane with genuine partial signals was not flagged partial or got sequenced in waves"
   296	fi
   297	
   298	# ─────────────────────────────────────────────────────────────────────────────
   299	# Scenario K — GH-5: contract-seam detection (coupled same-wave lanes)
   300	# ─────────────────────────────────────────────────────────────────────────────
   301	K="$WORK/K"; mkdir -p "$K"; echo '{}' >"$K/.gh-state.json"; : >"$K/.branches"
   302	# 920 + 921 are write-disjoint (producer.js vs consumer.js) but share the src/schema/ spine → coupled.
   303	# 922 lives in a different subtree (utils/report.js) → NOT coupled with either.
   304	mk_doc "$K" GH-920-producer.md 2 2 2 "$(contract_for MISS_SP src/schema/producer.js)"
   305	mk_doc "$K" GH-921-consumer.md 2 2 2 "$(contract_for MISS_SC src/schema/consumer.js)"
   306	mk_doc "$K" GH-922-report.md   2 2 2 "$(contract_for MISS_RP utils/report.js)"
   307	cat >"$K/ROADMAP.md" <<EOF
   308	# Roadmap
   309	## Ledger
   310	### In progress
   311	- **GH-920 · producer** 🆕 — independent → [d](PROJECT/2-WORKING/GH-920-producer.md) · [#920](https://github.com/o/r/issues/920)
   312	- **GH-921 · consumer** 🆕 — independent → [d](PROJECT/2-WORKING/GH-921-consumer.md) · [#921](https://github.com/o/r/issues/921)
   313	- **GH-922 · report** 🆕 — independent → [d](PROJECT/2-WORKING/GH-922-report.md) · [#922](https://github.com/o/r/issues/922)
   314	EOF
   315	run_qp "$K" >/dev/null 2>&1
   316	doc="$K/PROJECT/2-WORKING/MARATHON-PLAN-$DAY.md"
   317	# all three write-disjoint → same wave; the seam detector must flag ONLY 920‖921 on src/schema.
   318	seamline="$(grep -E '^\- \*\*Wave .*share ' "$doc" | grep 'src/schema')"
   319	if [[ -n "$seamline" ]] && grep -q "#920" <<<"$seamline" && grep -q "#921" <<<"$seamline"; then
   320	  pass "K: contract seam flagged — #920 ‖ #921 share src/schema/ (pin a contract)"
   321	else
   322	  fail "K: expected a src/schema seam warning for #920‖#921, got: $(grep -A3 'Contract seams' "$doc" | head -6)"
   323	fi
   324	# 922 shares no deep dir with 920/921 → must NOT appear in any seam line.
   325	if grep -E '^\- \*\*Wave .*share ' "$doc" | grep -q "#922"; then
   326	  fail "K: #922 (utils/report.js) wrongly flagged as a contract seam"
   327	else
   328	  pass "K: #922 in a disjoint subtree is NOT flagged as coupled (no false seam)"
   329	fi
   330	# the section names the fix (pin a CONTRACT.md) — the 'pin the contract' step made explicit (fix 1).
   331	grep -qi "pin a .*CONTRACT" "$doc" && pass "K: plan states the 'pin a contract' step for the seam" || fail "K: no pin-a-contract guidance in the seam section"
   332	
   333	echo
   334	echo "  marathon-plan: $PASS passed, $FAIL failed"
   335	[[ "$FAIL" -eq 0 ]]

codex
I have the surrounding planner and test coverage. Pulling the exact helper definitions now so the correctness call is tied to the actual `dirPrefixes` and `sharedSpine` implementation, not just the caller.
exec
/bin/zsh -lc "sed -n '360,460p' utils/marathon-plan.sh | nl -ba -v360" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131
 succeeded in 0ms:
   360	  // Match a dependency keyword followed by a LIST of issue refs (comma/and/&/slash separated), so
   361	  // "after GH-29, GH-30 and #31" yields all three. The list stops at the first non-issue token, so
   362	  // "after GH-29 the fix landed" still yields only 29 (no over-capture).
   363	  // Separator between refs is a RUN of comma/&//conjunction tokens (zero-or-more), so a compound
   364	  // separator like ", and" / ", & " / "and/or" is consumed and the following ref is still captured
   365	  // ("GH-100, GH-101, and GH-102" ⇒ all three). Each token consumes ≥1 char, so the `*` can't loop.
   366	  const re = /(?:after|once|depends on|gated on|blocked by)\s+((?:(?:GH-|#)\d+(?:\s*(?:,|&|\/|and|or)\s*)*)+)/gi;
   367	  let m;
   368	  while ((m = re.exec(item.raw)) !== null) {
   369	    let n; const num = /(?:GH-|#)(\d+)/g;
   370	    while ((n = num.exec(m[1])) !== null) deps.add(Number(n[1]));
   371	  }
   372	  return [...deps];
   373	}
   374	function isGoGated(item) {
   375	  return /gated on operator go|gated on (a |an )?operator|operator go\b|awaiting go\b/i.test(item.raw);
   376	}
   377	
   378	// GH-5: a "contract seam" is a directory two lanes SHARE (deeper than a top-level dir) even though
   379	// their exact write-sets are disjoint — a strong hint they depend on a common not-yet-built module or
   380	// schema. The wave-packer only defers on EXACT path collision, so such lanes co-wave and look
   381	// independent; in practice the consumer stalls on the producer's handoff unless the operator pins a
   382	// shared contract first. This detects the seam so the plan can say "pin a CONTRACT.md" up front.
   383	function dirPrefixes(p) {
   384	  const parts = String(p).split("/").filter(Boolean);
   385	  parts.pop(); // drop the file / trailing glob segment (e.g. a.js, **)
   386	  const out = []; let acc = "";
   387	  for (const seg of parts) { acc = acc ? acc + "/" + seg : seg; out.push(acc); }
   388	  return out; // "src/schema/a.js" -> ["src", "src/schema"]
   389	}
   390	function sharedSpine(wsA, wsB) {
   391	  // Deepest directory of >= 2 segments (contains a "/") shared by any path in A and any in B.
   392	  // Top-level-only sharing (both under "src/" or "test/") is intentionally NOT a seam — too coarse.
   393	  let best = null;
   394	  for (const pa of wsA) {
   395	    const pref = dirPrefixes(pa);
   396	    for (const pb of wsB) {
   397	      const setB = new Set(dirPrefixes(pb));
   398	      for (const d of pref) if (d.includes("/") && setB.has(d) && (!best || d.length > best.length)) best = d;
   399	    }
   400	  }
   401	  return best;
   402	}
   403	
   404	// PDDA triage ratings are integers 1 (low) .. 5 (highest) — see PROJECT/PDDA.md "Triage ratings".
   405	// Anything outside 1–5 (or absent) is treated as unrated (null) so the doc is held out of sequencing.
   406	const L = (x) => { const n = parseInt(String(x == null ? "" : x).trim(), 10); return n >= 1 && n <= 5 ? n : null; };
   407	
   408	// ── findings (the pdda finding shape) ────────────────────────────────────────
   409	const findings = [];
   410	function flag(severity, type, rec, message, action) {
   411	  findings.push({ severity, type, item: rec ? rec.title : "(run)", file: rec ? rec.docRel : "", message, action });
   412	}
   413	
   414	// ── build records ────────────────────────────────────────────────────────────
   415	const raw = readFileSafe(E.QP_ROADMAP);
   416	if (raw == null) { process.stderr.write("marathon-plan: cannot read ROADMAP\n"); process.exit(3); }
   417	const ledger = parseLedger(raw);
   418	if (ledger.length === 0) { process.stderr.write("marathon-plan: no ledger items parsed (is '## Ledger' present?)\n"); process.exit(3); }
   419	
   420	const records = [];
   421	for (const item of ledger) {
   422	  const gh = ghIssueOf(item);
   423	  const docRel = docOf(item);
   424	  const docAbs = docRel ? path.resolve(ROOT, docRel) : null;
   425	  const docExists = docRel ? existsAt(docRel) : false;
   426	  const slug = slugOf(docRel, item.title);
   427	  const fm = docExists ? frontmatter(docAbs) : {};
   428	  const ratings = { complexity: L(fm.complexity), risk: L(fm.risk), effort: L(fm.effort) };
   429	  const rated = ratings.complexity != null && ratings.risk != null && ratings.effort != null;
   430	  const ratingsExempt = String(fm.ratings_exempt || "").toLowerCase() === "true";
   431	  const contract = docExists ? extractContract(docAbs) : null;
   432	  const z = zoneOf(contract, item);
   433	  // GH-69: deterministic branch suggestion for this lane — from slug + run date, no git writes.
   434	  // swarm-preflight (stage 2) checks it against `git branch -a`; the orchestrator (stage 3) prompts
   435	  // the operator before cutting it. Carve-out (low-risk, independent zone) is applied by the
   436	  // orchestrator, not here — this planner emits the same deterministic name for every item.
   437	  const suggestedBranch = `marathon/${slug}-${TODAY}`;
   438	  const rec = {
   439	    title: item.title, section: item.section, emoji: item.status, raw: item.raw,
   440	    gh, docRel, docExists, slug, ratings, rated, ratingsExempt, contract,
   441	    zone: z.zone, zoneInferred: z.inferred, writeset: z.writeset,
   442	    deps: depsOf(item), goGated: isGoGated(item), suggestedBranch,
   443	    flags: [], signals: [], state: null, score: null, wave: null, ghState: null,
   444	  };
   445	  records.push(rec);
   446	}
   447	
   448	// Dedup identical (gh, docRel) pairs (e.g. an umbrella epic re-listing a child) — keep the first.
   449	const seen = new Set();
   450	const deduped = [];
   451	for (const r of records) {
   452	  // Dedup same-issue-different-title by gh when present (one issue = one canonical item); fall back to
   453	  // docRel+title for issue-less notes so distinct field-findings that share one doc anchor stay separate.
   454	  const key = r.gh != null ? `gh:${r.gh}` : `doc:${r.docRel || ""}|title:${r.title}`;
   455	  if (seen.has(key)) continue;
   456	  seen.add(key); deduped.push(r);
   457	}
   458	
   459	// ── per-item validation signals (deterministic; each a flag, never a fix) ─────
   460	let ghUnverified = 0;

codex
**Answer**

The GH-5 seam warning is mostly sound and it stays genuinely advisory, but there is one real edge-case miss: `dirPrefixes()` mishandles directory artifacts written with a trailing slash, so a valid seam can be dropped. No blocker-level flaw in the wave logic itself.

**Findings**

- [Should] `dirPrefixes()` is wrong for trailing-slash directory paths. `String(p).split("/").filter(Boolean)` removes the empty tail, then `parts.pop()` drops the last real directory, so `src/schema/` collapses to `["src"]` instead of preserving `src/schema`. That creates a false negative if a contract expresses a directory with `/` rather than `/**`. Core file/glob paths are fine, but this edge is not. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:383)

- [Pass] The intended main cases do work. `src/schema/**` becomes prefixes including `src/schema` because the last segment is dropped; `bin/tick` yields only `bin`, which is then rejected because it lacks `/`; `README.md` yields no prefixes; and the deepest shared directory wins because `best` updates only on a longer match. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:383) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:390)

- [Should] The proxy will both over- and under-report by design. It will warn on genuinely independent siblings that happen to live under the same deeper directory, and it will miss real couplings that cross directories or only share a top-level dir like `src/`. That said, “shared dir deeper than top-level” is a reasonable advisory proxy for the issue GH-5 is targeting, and limiting it to same-wave pairs is the right scope because cross-wave pairs are not concurrent-launch risk. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:391) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:679) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:820)

- [Pass] The advisory guarantee holds. Wave assignment is finished before seam detection runs, and the GH-5 block only appends `contractSeams` entries plus `warn`/`coupled-lanes` findings. Exit code is still derived only from drift, held items, and `--require-gh`; GH-5 cannot change wave membership, `active`, `held`, or the exit path. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:674) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:696)

- [Nit] Determinism is good enough for `--check`, but not fully canonical. Pair ordering is stable because `active` is deterministically sorted and seam pairs are emitted by fixed `i/j` loops, then rendered in insertion order. But `sharedSpine()` breaks equal-length ties by first encounter rather than an explicit lexical rule, so the chosen spine depends on artifact array order when two deepest candidates have the same depth. That is byte-stable for identical inputs, just not semantically canonical. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:393) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:630) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:680) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:831)

- [Pass] “Only proven write-sets” is enforced. Keyword-inferred lanes are created with `writeset: []`, and the seam loop skips any pair where either side has an empty write-set, so a zone-inferred lane cannot produce a phantom seam. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:351) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:684)

- [Nit] Scenario K covers the happy-path producer/consumer seam and one false-positive guard, but it does not lock the real edge cases introduced by this heuristic: trailing-slash directory artifacts, glob artifacts, or inferred-empty-write-set skipping. [test/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/test/marathon-plan.sh:298)

**Recommendation**

Merge with nits: the feature is additive and basically correct, but I would patch the trailing-slash handling and extend Scenario K before calling it finished.
tokens used
53,290
**Answer**

The GH-5 seam warning is mostly sound and it stays genuinely advisory, but there is one real edge-case miss: `dirPrefixes()` mishandles directory artifacts written with a trailing slash, so a valid seam can be dropped. No blocker-level flaw in the wave logic itself.

**Findings**

- [Should] `dirPrefixes()` is wrong for trailing-slash directory paths. `String(p).split("/").filter(Boolean)` removes the empty tail, then `parts.pop()` drops the last real directory, so `src/schema/` collapses to `["src"]` instead of preserving `src/schema`. That creates a false negative if a contract expresses a directory with `/` rather than `/**`. Core file/glob paths are fine, but this edge is not. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:383)

- [Pass] The intended main cases do work. `src/schema/**` becomes prefixes including `src/schema` because the last segment is dropped; `bin/tick` yields only `bin`, which is then rejected because it lacks `/`; `README.md` yields no prefixes; and the deepest shared directory wins because `best` updates only on a longer match. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:383) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:390)

- [Should] The proxy will both over- and under-report by design. It will warn on genuinely independent siblings that happen to live under the same deeper directory, and it will miss real couplings that cross directories or only share a top-level dir like `src/`. That said, “shared dir deeper than top-level” is a reasonable advisory proxy for the issue GH-5 is targeting, and limiting it to same-wave pairs is the right scope because cross-wave pairs are not concurrent-launch risk. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:391) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:679) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:820)

- [Pass] The advisory guarantee holds. Wave assignment is finished before seam detection runs, and the GH-5 block only appends `contractSeams` entries plus `warn`/`coupled-lanes` findings. Exit code is still derived only from drift, held items, and `--require-gh`; GH-5 cannot change wave membership, `active`, `held`, or the exit path. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:674) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:696)

- [Nit] Determinism is good enough for `--check`, but not fully canonical. Pair ordering is stable because `active` is deterministically sorted and seam pairs are emitted by fixed `i/j` loops, then rendered in insertion order. But `sharedSpine()` breaks equal-length ties by first encounter rather than an explicit lexical rule, so the chosen spine depends on artifact array order when two deepest candidates have the same depth. That is byte-stable for identical inputs, just not semantically canonical. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:393) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:630) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:680) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:831)

- [Pass] “Only proven write-sets” is enforced. Keyword-inferred lanes are created with `writeset: []`, and the seam loop skips any pair where either side has an empty write-set, so a zone-inferred lane cannot produce a phantom seam. [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:351) [utils/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/utils/marathon-plan.sh:684)

- [Nit] Scenario K covers the happy-path producer/consumer seam and one false-positive guard, but it does not lock the real edge cases introduced by this heuristic: trailing-slash directory artifacts, glob artifacts, or inferred-empty-write-set skipping. [test/marathon-plan.sh](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-90296-10131/test/marathon-plan.sh:298)

**Recommendation**

Merge with nits: the feature is additive and basically correct, but I would patch the trailing-slash handling and extend Scenario K before calling it finished.
