Reading additional input from stdin...
2026-08-31T23:32:17.724287Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 98 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a05a2a-a01d-7642-9876-7afed0bb3215
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Vote: which implementation of GH-349 should this repo merge?

Two branches independently implement **GH-349** — generalising this repo's releases roadmap ledger
so a vendored `.xyz/` install in a *different* GitHub org can run `releases roadmap sync` against a
link-style `ROADMAP.md`. Both rewrite `parse_roadmap_ledger` and `cmd_roadmap_sync` in
`utils/py/releases_app.py`. Only one can merge as-is; they conflict.

You are one of two independent advisors. **Vote, and justify with evidence you gathered yourself.**
Do not defer to the other advisor, to the PR descriptions, or to either branch's own test counts.

## The two candidates

| | Branch | Commit | Its GH-349 suite |
|---|---|---|---|
| **A** | `fix/gh-349-releases-roadmap-vendored` (PR #350) | `d2fb87ba` | `test/gh349-releases-roadmap-vendored.sh` |
| **B** | `fix/gh351-gh349-releases-ledger-fixes` (PR #352) | `b2f7947f` | `test/gh349-vendored-roadmap-ledger.sh` |

Base for both: `origin/development` (`9d44be35`).

**Your worktree is checked out at A.** Read B, and the common ancestor, with `git show`:

```bash
git show origin/development:utils/py/releases_app.py             > /tmp/base.py
git show origin/fix/gh351-gh349-releases-ledger-fixes:utils/py/releases_app.py > /tmp/B.py
cp utils/py/releases_app.py /tmp/A.py     # your worktree is A
diff /tmp/base.py /tmp/A.py | head -200
diff /tmp/base.py /tmp/B.py | head -200
git show origin/fix/gh351-gh349-releases-ledger-fixes:test/gh349-vendored-roadmap-ledger.sh
```

**Scope your vote to GH-349 only.** B also adds a `manifest unship` verb (GH-351) and a timestamp
migration. Those are separate scopes, are not in A, and are not what you are voting on — ignore them.

## Measure, do not reason from the diff alone

The decisive evidence is how each parser behaves on **real ledgers**, not how its regexes read. Two
real corpora are available:

- `ROADMAP.md` in your worktree — this repo's own ledger, bold-style `- **Title**` bullets. This is
  the corpus the parser **already served** before either branch, so any change here is a behaviour
  change that must be justified.
- `/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md` — a real foreign-org, link-style
  `- [Title](path)` ledger. Read-only; this is the corpus GH-349 exists to support.

A harness that loads both parsers side by side:

```python
import sys, importlib.util, collections
def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec); sys.argv = [name]
    try: spec.loader.exec_module(m)
    except SystemExit: pass
    return m
A = load("A", "/tmp/A.py"); B = load("B", "/tmp/B.py")
for label, R in (("own", "ROADMAP.md"),
                 ("foreign", "/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md")):
    for tag, mod in (("A", A), ("B", B)):
        e = mod.parse_roadmap_ledger(R)
        c = collections.Counter(x["gh_number"] for x in e if x["gh_number"])
        print(label, tag, "entries:", len(e),
              "dupkeys:", {k: v for k, v in c.items() if v > 1})
        # then inspect: doc_path values, issue_url vs gh_number, entries with empty titles, …
```

Also write your own fixtures for shapes neither corpus contains.

## Questions your vote must answer

1. **Correctness on the two real ledgers.** For each parser: how many entries, any duplicate
   `gh_number` (note: `cmd_roadmap_sync` hard-refuses on a duplicate key — so a duplicate means sync
   is broken for that repo), any `doc_path` that is not a resolvable repo-relative document, any
   `issue_url` whose trailing number disagrees with the row's `gh_number`, any row with an empty or
   junk title. Give counts and concrete examples.

2. **Behaviour change on this repo's own ledger.** Diff each parser's output against
   `origin/development`'s parser over `ROADMAP.md`. Which rows change, and is each change a
   correction or a regression? Justify each one.

3. **The bullet-matching rule.** What does each treat as a ledger entry? Test markdown task-list
   items (`- [ ]`, `- [x]`), plain prose bullets, nested/indented sub-bullets, and a `ROADMAP.md`
   with **no** `## Ledger` header. What gets ingested that should not, or dropped that should not?

4. **Refusal contract.** Both add a guard against a 0-entry parse deleting the mirror. Compare the
   guard, its rule name, whether the guard's own notion of "the ledger" agrees with the parser's, and
   whether there is any escape hatch for a genuinely-empty ledger. Can either guard be made to miss?

5. **Test suites.** Judge them on what they would *catch*, not their assertion counts. For each: name
   one real defect the suite would miss. Does either suite test against a real corpus rather than only
   synthetic fixtures?

6. **Anything else** — API/contract divergence, cross-caller effects of shared changes, maintainability.

## Your answer

Open with a single line:

`VOTE: A` or `VOTE: B` or `VOTE: NEITHER`

Then the evidence, question by question, with `file:line` citations and the actual command output you
observed. Then, in one short paragraph: if the losing branch contains anything the winner should
adopt, name it specifically.

Be concrete and be willing to say a candidate is unsafe. A vote with no measurements behind it is
worth nothing here.

hook: SessionStart
hook: SessionStart Completed
codex
I’m using the consult review workflow to independently measure both implementations against the two ledgers and adversarial markdown shapes; I’ll keep the vote strictly to GH-349.
exec
/bin/zsh -lc "pwd && sed -n '1,240p' /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/skills/consult/SKILL.md && sed -n '1,220p' ROUTER.md && git status --short --branch && git log -1 --oneline" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 6135ms:
2026-08-31 16:32:27.780 xcodebuild[75347:6479040]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:28.165 xcodebuild[75347:6479039] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-S0HjZOuT' (errno=Operation not permitted)
2026-08-31 16:32:28.954 xcodebuild[75351:6479087]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:29.144 xcodebuild[75351:6479086] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
## HEAD (no branch)
?? PROJECT/1-INBOX/GH-351-MANIFEST-SHIP-RETRACTION.md
?? relay-system/2026-08-31/gh349-vote-163216/
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-ID3JUQnD' (errno=Operation not permitted)
2026-08-31 16:32:30.687 xcodebuild[75360:6479155]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:30.881 xcodebuild[75360:6479154] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-n1M2Itpl' (errno=Operation not permitted)
2026-08-31 16:32:31.505 xcodebuild[75362:6479167]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:31.698 xcodebuild[75362:6479166] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
69006fcd WIP on fix/gh-349-releases-roadmap-vendored: d2fb87ba fix(releases): position is not identity — close all six codex QA findings (GH-349)

mcp: codebase-memory-mcp/index_status started
mcp: codebase-memory-mcp/index_status (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "git show origin/development:utils/py/releases_app.py | nl -ba | sed -n '320,620p'
git show origin/fix/gh351-gh349-releases-ledger-fixes:utils/py/releases_app.py | nl -ba | sed -n '320,680p'
nl -ba utils/py/releases_app.py | sed -n '320,680p'
git diff --no-ext-diff --unified=20 origin/development -- utils/py/releases_app.py
git diff --no-ext-diff --unified=20 origin/development..origin/fix/gh351-gh349-releases-ledger-fixes -- utils/py/releases_app.py
git show origin/fix/gh351-gh349-releases-ledger-fixes:test/gh349-vendored-roadmap-ledger.sh | nl -ba | sed -n '1,300p'
nl -ba test/gh349-releases-roadmap-vendored.sh | sed -n '1,300p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 12392ms:
2026-08-31 16:32:48.593 xcodebuild[75537:6479926]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:48.924 xcodebuild[75537:6479924] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-SxnTVoXH' (errno=Operation not permitted)
2026-08-31 16:32:49.635 xcodebuild[75539:6479959]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:49.831 xcodebuild[75539:6479958] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
   320	        "ledger": os.path.join(root, LEDGER_NAME),
   321	    }
   322	
   323	
   324	# ── lock + audit sidecar ────────────────────────────────────────────────────────────────────────
   325	
   326	def audit_log(root, outcome, detail=""):
   327	    """Append-only contention evidence, OUTSIDE the DB (r4 review finding: a refused writer
   328	    inserting into the committed DB would itself be an unlocked write, able to tear the very trio
   329	    it exists to audit). Line shape: <session_id> <timestamp> <outcome> <detail>, outcome in
   330	    acquired|refused|retried|recovered."""
   331	    _, audit_path, _ = lock_paths(root)
   332	    line = "%s %s %s %s\n" % (session_id(), now_iso(), outcome, detail)
   333	    try:
   334	        with open(audit_path, "a", encoding="utf-8") as fh:
   335	            fh.write(line)
   336	    except OSError as exc:
   337	        print("warn: rule=lock-audit: could not append to %s (%s)" % (audit_path, exc))
   338	
   339	
   340	class WriterLock:
   341	    """Repo-scoped writer lock (PRD Git story 1). Every acquisition attempt is logged to the
   342	    sidecar; a busy lock retries for RELEASES_APP_LOCK_WAIT seconds, then refuses with exit 4 —
   343	    and a refusal changes no committed artifact (that is the r4 negative control)."""
   344	
   345	    def __init__(self, root):
   346	        self.root = root
   347	        self.lock_path, _, self.journal_path = lock_paths(root)
   348	        self.fh = None
   349	
   350	    def acquire(self):
   351	        wait = _env_float("RELEASES_APP_LOCK_WAIT", 3.0)
   352	        deadline = time.time() + max(wait, 0.0)
   353	        announced_retry = False
   354	        while True:
   355	            self.fh = open(self.lock_path, "a+", encoding="utf-8")
   356	            try:
   357	                fcntl.flock(self.fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
   358	            except OSError:
   359	                self.fh.close()
   360	                self.fh = None
   361	                if not announced_retry:
   362	                    audit_log(self.root, "retried", "lock busy; retrying for up to %.0fs" % wait)
   363	                    announced_retry = True
   364	                if time.time() >= deadline:
   365	                    audit_log(self.root, "refused", "lock still busy after %.0fs" % wait)
   366	                    refuse("writer-lock",
   367	                           "another releases-app writer holds %s; refusal recorded in the "
   368	                           "lock-audit sidecar; no committed artifact was changed"
   369	                           % self.lock_path, code=EXIT_LOCK_REFUSED)
   370	                time.sleep(0.1)
   371	                continue
   372	            self.fh.seek(0)
   373	            self.fh.truncate()
   374	            self.fh.write("%s %s %s\n" % (now_iso(), session_id(), os.getpid()))
   375	            self.fh.flush()
   376	            audit_log(self.root, "acquired", "pid %d" % os.getpid())
   377	            return self
   378	
   379	    def release(self):
   380	        if self.fh is not None:
   381	            try:
   382	                fcntl.flock(self.fh.fileno(), fcntl.LOCK_UN)
   383	            finally:
   384	                self.fh.close()
   385	                self.fh = None
   386	
   387	    def __enter__(self):
   388	        return self.acquire()
   389	
   390	    def __exit__(self, *exc):
   391	        self.release()
   392	        return False
   393	
   394	
   395	# ── DB connection (PRAGMA foreign_keys asserted per connection) ─────────────────────────────────
   396	
   397	def connect(db_path, must_exist=True):
   398	    if must_exist and not os.path.exists(db_path):
   399	        refuse("not-initialized", "no %s here; run `releases init` first" % DB_NAME)
   400	    # isolation_level=None: transactions are BEGIN/COMMIT'd explicitly by perform_write, so the
   401	    # intent journal -> COMMIT -> stage -> rename ordering is the ONLY ordering that exists.
   402	    conn = sqlite3.connect(db_path, isolation_level=None)
   403	    conn.row_factory = sqlite3.Row
   404	    conn.execute("PRAGMA foreign_keys = ON")
   405	    if conn.execute("PRAGMA foreign_keys").fetchone()[0] != 1:
   406	        conn.close()
   407	        refuse("foreign-keys-pragma",
   408	               "PRAGMA foreign_keys=ON did not take effect on this connection; refusing to run")
   409	    return conn
   410	
   411	
   412	def get_setting(conn, key, default=None):
   413	    row = conn.execute("SELECT value FROM settings WHERE key = ?", (key,)).fetchone()
   414	    return row["value"] if row else default
   415	
   416	
   417	def get_generation(conn):
   418	    try:
   419	        return int(get_setting(conn, GENERATION_KEY, "0"))
   420	    except ValueError:
   421	        return 0
   422	
   423	
   424	def enforcement_mode(conn):
   425	    return get_setting(conn, "enforcement", "lenient")
   426	
   427	
   428	# ── migration 001 (v1 schema, PRD "Schema (v1)") ────────────────────────────────────────────────
   429	
   430	def _gid_check(column, prefix):
   431	    """Exact-shape global-id CHECK: the type prefix plus exactly 26 characters of the Crockford
   432	    base32 alphabet, written out in full (PRD GID shape note — prefix-only GLOBs were theater)."""
   433	    return "CHECK (%s GLOB '%s%s')" % (column, prefix, CROCKFORD_GLOB_CLASS * 26)
   434	
   435	
   436	MIGRATION_001 = """
   437	CREATE TABLE schema_migrations (
   438	  version INTEGER PRIMARY KEY,
   439	  applied_at TEXT NOT NULL
   440	);
   441	
   442	CREATE TABLE settings (            -- per-repo DB, so per-repo enforcement mode lives here
   443	  key TEXT PRIMARY KEY,
   444	  value TEXT NOT NULL
   445	);
   446	
   447	CREATE TABLE repos (
   448	  id INTEGER PRIMARY KEY,
   449	  global_id TEXT NOT NULL UNIQUE {repo_gid},
   450	  slug TEXT NOT NULL UNIQUE CHECK (length(trim(slug)) > 0)
   451	);  -- device-local paths deliberately NOT committed (review finding): the UI resolves local
   452	    -- checkout paths from the utils/hq/ registry, which is already per-device.
   453	
   454	CREATE TABLE issue_refs (          -- normalized issue reference: real URL XOR placeholder
   455	  id INTEGER PRIMARY KEY,
   456	  global_id TEXT NOT NULL UNIQUE {ref_gid},
   457	  url TEXT UNIQUE CHECK (url IS NULL OR url GLOB 'https://github.com/*/issues/*'),
   458	  temp_id TEXT UNIQUE CHECK (temp_id IS NULL OR
   459	    temp_id GLOB 'TMP-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]' OR
   460	    temp_id GLOB 'MIG-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]'),  -- MIG-: import-only (CLI-enforced)
   461	  created_at TEXT NOT NULL,
   462	  CHECK ((url IS NULL) != (temp_id IS NULL))   -- exactly one
   463	);
   464	
   465	CREATE TABLE marathons (
   466	  id INTEGER PRIMARY KEY,
   467	  global_id TEXT NOT NULL UNIQUE {mar_gid},
   468	  repo_id INTEGER NOT NULL REFERENCES repos(id),
   469	  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   470	  status TEXT NOT NULL CHECK (status IN ('planned','running','done','escalated','abandoned')),
   471	  created_at TEXT NOT NULL
   472	);
   473	
   474	CREATE TABLE releases (
   475	  id INTEGER PRIMARY KEY,
   476	  global_id TEXT NOT NULL UNIQUE {rel_gid},
   477	  repo_id INTEGER NOT NULL REFERENCES repos(id),
   478	  version TEXT CHECK (version IS NULL OR length(trim(version)) > 0),
   479	  codename TEXT,
   480	  status TEXT NOT NULL CHECK (status IN ('draft','active','shipped','cut')),
   481	  target_date TEXT CHECK (target_date IS NULL OR target_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
   482	  shipped_date TEXT CHECK (shipped_date IS NULL OR shipped_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
   483	  description TEXT NOT NULL CHECK (length(trim(description)) > 0),
   484	  exit_criterion TEXT,
   485	  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   486	  marathon_id INTEGER REFERENCES marathons(id),
   487	  gh_release_url TEXT,
   488	  milestone TEXT,
   489	  front_door_reviewed TEXT CHECK (front_door_reviewed IN ('Yes','No') OR front_door_reviewed IS NULL),
   490	  shakedown_reviewed  TEXT CHECK (shakedown_reviewed  IN ('Yes','No') OR shakedown_reviewed  IS NULL),
   491	  license_file        TEXT CHECK (license_file        IN ('Yes','No') OR license_file        IS NULL),
   492	  UNIQUE (repo_id, version)
   493	);
   494	
   495	CREATE TABLE manifest_items (
   496	  id INTEGER PRIMARY KEY,
   497	  global_id TEXT NOT NULL UNIQUE {mfi_gid},
   498	  release_id INTEGER NOT NULL REFERENCES releases(id),
   499	  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   500	  state TEXT NOT NULL CHECK (state IN ('open','shipped','cut')),
   501	  UNIQUE (release_id, issue_ref_id)
   502	);
   503	
   504	CREATE TABLE manifest_state_events (   -- append-only re-scope trail (review finding: the old
   505	  id INTEGER PRIMARY KEY,              -- single overwriteable state_changed cell lost history)
   506	  item_id INTEGER NOT NULL REFERENCES manifest_items(id),
   507	  from_state TEXT NOT NULL CHECK (from_state IN ('open','shipped','cut')),
   508	  to_state   TEXT NOT NULL CHECK (to_state   IN ('open','shipped','cut')),
   509	  at TEXT NOT NULL,
   510	  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0)   -- a cut without a reason is refused
   511	);
   512	-- Append-only is enforced by triggers, not convention (r2 review finding):
   513	CREATE TRIGGER mse_no_update BEFORE UPDATE ON manifest_state_events
   514	  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
   515	CREATE TRIGGER mse_no_delete BEFORE DELETE ON manifest_state_events
   516	  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
   517	-- (same trigger pair on op_receipts). Transition LEGALITY and the item-state/event coupling are
   518	-- CLI-enforced, stated as such: the CLI updates manifest_items.state and appends the event in ONE
   519	-- transaction; a direct writer that skips the event is caught by the digest chain below, not
   520	-- prevented.
   521	
   522	CREATE TABLE doc_lines (               -- document-level verbatim preservation (r2: the 86-line
   523	  id INTEGER PRIMARY KEY,              -- preamble is release-less; legacy_lines can't hold it)
   524	  repo_id INTEGER NOT NULL REFERENCES repos(id),
   525	  position INTEGER NOT NULL,           -- ordering among document-level segments
   526	  content TEXT NOT NULL,
   527	  UNIQUE (repo_id, position)
   528	);
   529	
   530	CREATE TABLE legacy_lines (            -- lossless import: unmapped/continuation lines, verbatim
   531	  id INTEGER PRIMARY KEY,
   532	  release_id INTEGER NOT NULL REFERENCES releases(id),
   533	  position INTEGER NOT NULL,
   534	  content TEXT NOT NULL,
   535	  disposition TEXT,                    -- NULL = pending; else 'kept'|'migrated'|'dropped:<why>'
   536	  UNIQUE (release_id, position)
   537	);
   538	
   539	CREATE TABLE grandfather_entries (     -- r3: referenced throughout but previously never defined
   540	  id INTEGER PRIMARY KEY,
   541	  import_run TEXT NOT NULL,            -- one id per `releases import` invocation
   542	  release_gid TEXT,                    -- NULL for document-level entries
   543	  rule TEXT NOT NULL,                  -- which rule was tolerated/defaulted
   544	  source_value TEXT,                   -- what the legacy file had (NULL = field absent)
   545	  supplied_value TEXT,                 -- what import wrote (default, MIG- ref, normalization)
   546	  disposition TEXT                     -- NULL = pending; strict flip requires none pending
   547	);
   548	
   549	CREATE TABLE op_receipts (             -- append-only CLI operation log (append-only via the same
   550	  id INTEGER PRIMARY KEY,              -- trigger pair as manifest_state_events)
   551	  op TEXT NOT NULL,
   552	  target_gid TEXT,
   553	  at TEXT NOT NULL,
   554	  txn_id TEXT NOT NULL,                -- one per CLI transaction
   555	  session_id TEXT NOT NULL,            -- r3: stable per-dogfood-session id (env-provided), so the
   556	                                       --   exit gate's ">=2 sessions" is mechanically checkable
   557	  state_digest_before TEXT NOT NULL,   -- sha256 of the BUSINESS-STATE dump (r3: excludes
   558	  state_digest_after TEXT NOT NULL     --   op_receipts, lock_audit, generation, and all digest
   559	);                                     --   fields — the old dump digest was self-referential and
   560	                                       --   uncomputable). Chain rule: each receipt's `before` must
   561	                                       --   equal the previous receipt's `after`; `check` recomputes
   562	                                       --   the current business-state digest and a mismatch with the
   563	                                       --   latest `after` = receipt-less mutation.
   564	CREATE TRIGGER op_no_update BEFORE UPDATE ON op_receipts
   565	  BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;
   566	CREATE TRIGGER op_no_delete BEFORE DELETE ON op_receipts
   567	  BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;
   568	
   569	CREATE INDEX idx_releases_repo ON releases(repo_id);
   570	CREATE INDEX idx_items_release ON manifest_items(release_id);
   571	CREATE INDEX idx_mse_item ON manifest_state_events(item_id);
   572	CREATE INDEX idx_legacy_release ON legacy_lines(release_id);
   573	CREATE INDEX idx_gf_import ON grandfather_entries(import_run);
   574	""".format(
   575	    repo_gid=_gid_check("global_id", "repo-"),
   576	    ref_gid=_gid_check("global_id", "ref-"),
   577	    mar_gid=_gid_check("global_id", "mar-"),
   578	    rel_gid=_gid_check("global_id", "rel-"),
   579	    mfi_gid=_gid_check("global_id", "mfi-"),
   580	)
   581	
   582	
   583	MIGRATION_002_DDL = """
   584	CREATE TABLE IF NOT EXISTS roadmap_items (  -- GH-69/GH-269: roadmap ledger.
   585	  id INTEGER PRIMARY KEY,                   --
   586	  global_id TEXT NOT NULL UNIQUE {rmi_gid}, -- edit; `releases roadmap sync` mirrors it here. Rows
   587	  repo_id INTEGER NOT NULL REFERENCES repos(id),  -- follow the GH-32 grammar (GID-keyed, no
   588	  gh_number INTEGER,                        -- integer ids as dump values), so merges and rebuilds
   589	  title TEXT NOT NULL CHECK (length(trim(title)) > 0),  -- need nothing new.
   590	  section TEXT NOT NULL CHECK (length(trim(section)) > 0),
   591	  position INTEGER NOT NULL,                -- order within its section at last sync
   592	  status_marker TEXT,                       -- the entry's leading status emoji, when present
   593	  complexity INTEGER, risk INTEGER, effort INTEGER,     -- cx/risk/eff when the entry states them
   594	  doc_path TEXT,                            -- first PROJECT/** link
   595	  issue_url TEXT,                           -- first this-repo issue/PR URL
   596	  raw_text TEXT NOT NULL,                   -- the entry block VERBATIM (lossless shadow)
   597	  first_seen TEXT NOT NULL,
   598	  updated_at TEXT NOT NULL,                 -- last sync that CHANGED this row (not last sync run)
   599	  UNIQUE (repo_id, gh_number)
   600	);
   601	CREATE INDEX IF NOT EXISTS idx_roadmap_repo ON roadmap_items(repo_id);
   602	""".format(rmi_gid=_gid_check("global_id", "rmi-"))
   603	
   604	
   605	def _ddl_statements(script):
   606	    """Split a trigger-free DDL script into individual statements.
   607	
   608	    GH-111: exists so migrations can avoid executescript(), which commits the caller's
   609	    transaction. Deliberately NOT general — it would mis-split a CREATE TRIGGER body, whose
   610	    BEGIN…END contains its own semicolons. Only trigger-free scripts may use it; migration
   611	    004 issues its trigger DDL as explicit single execute() calls instead.
   612	    """
   613	    if "CREATE TRIGGER" in script.upper():
   614	        raise ValueError("_ddl_statements cannot split trigger bodies; issue them individually")
   615	    # sqlite3.complete_statement() is comment- and string-literal-aware; a naive split(";")
   616	    # cuts mid-statement on the first `--` comment containing a semicolon.
   617	    statements, buffer = [], ""
   618	    for line in script.splitlines(keepends=True):
   619	        buffer += line
   620	        if sqlite3.complete_statement(buffer):
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-tpuNT0Lh' (errno=Operation not permitted)
2026-08-31 16:32:51.244 xcodebuild[75556:6480040]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:51.439 xcodebuild[75556:6480039] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-2H97YWWJ' (errno=Operation not permitted)
2026-08-31 16:32:52.057 xcodebuild[75569:6480098]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:52.258 xcodebuild[75569:6480097] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
   320	    }
   321	
   322	
   323	# ── lock + audit sidecar ────────────────────────────────────────────────────────────────────────
   324	
   325	def audit_log(root, outcome, detail=""):
   326	    """Append-only contention evidence, OUTSIDE the DB (r4 review finding: a refused writer
   327	    inserting into the committed DB would itself be an unlocked write, able to tear the very trio
   328	    it exists to audit). Line shape: <session_id> <timestamp> <outcome> <detail>, outcome in
   329	    acquired|refused|retried|recovered."""
   330	    _, audit_path, _ = lock_paths(root)
   331	    line = "%s %s %s %s\n" % (session_id(), now_iso(), outcome, detail)
   332	    try:
   333	        with open(audit_path, "a", encoding="utf-8") as fh:
   334	            fh.write(line)
   335	    except OSError as exc:
   336	        print("warn: rule=lock-audit: could not append to %s (%s)" % (audit_path, exc))
   337	
   338	
   339	class WriterLock:
   340	    """Repo-scoped writer lock (PRD Git story 1). Every acquisition attempt is logged to the
   341	    sidecar; a busy lock retries for RELEASES_APP_LOCK_WAIT seconds, then refuses with exit 4 —
   342	    and a refusal changes no committed artifact (that is the r4 negative control)."""
   343	
   344	    def __init__(self, root):
   345	        self.root = root
   346	        self.lock_path, _, self.journal_path = lock_paths(root)
   347	        self.fh = None
   348	
   349	    def acquire(self):
   350	        wait = _env_float("RELEASES_APP_LOCK_WAIT", 3.0)
   351	        deadline = time.time() + max(wait, 0.0)
   352	        announced_retry = False
   353	        while True:
   354	            self.fh = open(self.lock_path, "a+", encoding="utf-8")
   355	            try:
   356	                fcntl.flock(self.fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
   357	            except OSError:
   358	                self.fh.close()
   359	                self.fh = None
   360	                if not announced_retry:
   361	                    audit_log(self.root, "retried", "lock busy; retrying for up to %.0fs" % wait)
   362	                    announced_retry = True
   363	                if time.time() >= deadline:
   364	                    audit_log(self.root, "refused", "lock still busy after %.0fs" % wait)
   365	                    refuse("writer-lock",
   366	                           "another releases-app writer holds %s; refusal recorded in the "
   367	                           "lock-audit sidecar; no committed artifact was changed"
   368	                           % self.lock_path, code=EXIT_LOCK_REFUSED)
   369	                time.sleep(0.1)
   370	                continue
   371	            self.fh.seek(0)
   372	            self.fh.truncate()
   373	            self.fh.write("%s %s %s\n" % (now_iso(), session_id(), os.getpid()))
   374	            self.fh.flush()
   375	            audit_log(self.root, "acquired", "pid %d" % os.getpid())
   376	            return self
   377	
   378	    def release(self):
   379	        if self.fh is not None:
   380	            try:
   381	                fcntl.flock(self.fh.fileno(), fcntl.LOCK_UN)
   382	            finally:
   383	                self.fh.close()
   384	                self.fh = None
   385	
   386	    def __enter__(self):
   387	        return self.acquire()
   388	
   389	    def __exit__(self, *exc):
   390	        self.release()
   391	        return False
   392	
   393	
   394	# ── DB connection (PRAGMA foreign_keys asserted per connection) ─────────────────────────────────
   395	
   396	def connect(db_path, must_exist=True):
   397	    if must_exist and not os.path.exists(db_path):
   398	        refuse("not-initialized", "no %s here; run `releases init` first" % DB_NAME)
   399	    # isolation_level=None: transactions are BEGIN/COMMIT'd explicitly by perform_write, so the
   400	    # intent journal -> COMMIT -> stage -> rename ordering is the ONLY ordering that exists.
   401	    conn = sqlite3.connect(db_path, isolation_level=None)
   402	    conn.row_factory = sqlite3.Row
   403	    conn.execute("PRAGMA foreign_keys = ON")
   404	    if conn.execute("PRAGMA foreign_keys").fetchone()[0] != 1:
   405	        conn.close()
   406	        refuse("foreign-keys-pragma",
   407	               "PRAGMA foreign_keys=ON did not take effect on this connection; refusing to run")
   408	    return conn
   409	
   410	
   411	def get_setting(conn, key, default=None):
   412	    row = conn.execute("SELECT value FROM settings WHERE key = ?", (key,)).fetchone()
   413	    return row["value"] if row else default
   414	
   415	
   416	def get_generation(conn):
   417	    try:
   418	        return int(get_setting(conn, GENERATION_KEY, "0"))
   419	    except ValueError:
   420	        return 0
   421	
   422	
   423	def enforcement_mode(conn):
   424	    return get_setting(conn, "enforcement", "lenient")
   425	
   426	
   427	# ── migration 001 (v1 schema, PRD "Schema (v1)") ────────────────────────────────────────────────
   428	
   429	def _gid_check(column, prefix):
   430	    """Exact-shape global-id CHECK: the type prefix plus exactly 26 characters of the Crockford
   431	    base32 alphabet, written out in full (PRD GID shape note — prefix-only GLOBs were theater)."""
   432	    return "CHECK (%s GLOB '%s%s')" % (column, prefix, CROCKFORD_GLOB_CLASS * 26)
   433	
   434	
   435	MIGRATION_001 = """
   436	CREATE TABLE schema_migrations (
   437	  version INTEGER PRIMARY KEY,
   438	  applied_at TEXT NOT NULL
   439	);
   440	
   441	CREATE TABLE settings (            -- per-repo DB, so per-repo enforcement mode lives here
   442	  key TEXT PRIMARY KEY,
   443	  value TEXT NOT NULL
   444	);
   445	
   446	CREATE TABLE repos (
   447	  id INTEGER PRIMARY KEY,
   448	  global_id TEXT NOT NULL UNIQUE {repo_gid},
   449	  slug TEXT NOT NULL UNIQUE CHECK (length(trim(slug)) > 0)
   450	);  -- device-local paths deliberately NOT committed (review finding): the UI resolves local
   451	    -- checkout paths from the utils/hq/ registry, which is already per-device.
   452	
   453	CREATE TABLE issue_refs (          -- normalized issue reference: real URL XOR placeholder
   454	  id INTEGER PRIMARY KEY,
   455	  global_id TEXT NOT NULL UNIQUE {ref_gid},
   456	  url TEXT UNIQUE CHECK (url IS NULL OR url GLOB 'https://github.com/*/issues/*'),
   457	  temp_id TEXT UNIQUE CHECK (temp_id IS NULL OR
   458	    temp_id GLOB 'TMP-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]' OR
   459	    temp_id GLOB 'MIG-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]'),  -- MIG-: import-only (CLI-enforced)
   460	  created_at TEXT NOT NULL,
   461	  CHECK ((url IS NULL) != (temp_id IS NULL))   -- exactly one
   462	);
   463	
   464	CREATE TABLE marathons (
   465	  id INTEGER PRIMARY KEY,
   466	  global_id TEXT NOT NULL UNIQUE {mar_gid},
   467	  repo_id INTEGER NOT NULL REFERENCES repos(id),
   468	  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   469	  status TEXT NOT NULL CHECK (status IN ('planned','running','done','escalated','abandoned')),
   470	  created_at TEXT NOT NULL
   471	);
   472	
   473	CREATE TABLE releases (
   474	  id INTEGER PRIMARY KEY,
   475	  global_id TEXT NOT NULL UNIQUE {rel_gid},
   476	  repo_id INTEGER NOT NULL REFERENCES repos(id),
   477	  version TEXT CHECK (version IS NULL OR length(trim(version)) > 0),
   478	  codename TEXT,
   479	  status TEXT NOT NULL CHECK (status IN ('draft','active','shipped','cut')),
   480	  target_date TEXT CHECK (target_date IS NULL OR target_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
   481	  shipped_date TEXT CHECK (shipped_date IS NULL OR shipped_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
   482	  description TEXT NOT NULL CHECK (length(trim(description)) > 0),
   483	  exit_criterion TEXT,
   484	  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   485	  marathon_id INTEGER REFERENCES marathons(id),
   486	  gh_release_url TEXT,
   487	  milestone TEXT,
   488	  front_door_reviewed TEXT CHECK (front_door_reviewed IN ('Yes','No') OR front_door_reviewed IS NULL),
   489	  shakedown_reviewed  TEXT CHECK (shakedown_reviewed  IN ('Yes','No') OR shakedown_reviewed  IS NULL),
   490	  license_file        TEXT CHECK (license_file        IN ('Yes','No') OR license_file        IS NULL),
   491	  UNIQUE (repo_id, version)
   492	);
   493	
   494	CREATE TABLE manifest_items (
   495	  id INTEGER PRIMARY KEY,
   496	  global_id TEXT NOT NULL UNIQUE {mfi_gid},
   497	  release_id INTEGER NOT NULL REFERENCES releases(id),
   498	  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   499	  state TEXT NOT NULL CHECK (state IN ('open','shipped','cut')),
   500	  UNIQUE (release_id, issue_ref_id)
   501	);
   502	
   503	CREATE TABLE manifest_state_events (   -- append-only re-scope trail (review finding: the old
   504	  id INTEGER PRIMARY KEY,              -- single overwriteable state_changed cell lost history)
   505	  item_id INTEGER NOT NULL REFERENCES manifest_items(id),
   506	  from_state TEXT NOT NULL CHECK (from_state IN ('open','shipped','cut')),
   507	  to_state   TEXT NOT NULL CHECK (to_state   IN ('open','shipped','cut')),
   508	  at TEXT NOT NULL,
   509	  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0)   -- a cut without a reason is refused
   510	);
   511	-- Append-only is enforced by triggers, not convention (r2 review finding):
   512	CREATE TRIGGER mse_no_update BEFORE UPDATE ON manifest_state_events
   513	  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
   514	CREATE TRIGGER mse_no_delete BEFORE DELETE ON manifest_state_events
   515	  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
   516	-- (same trigger pair on op_receipts). Transition LEGALITY and the item-state/event coupling are
   517	-- CLI-enforced, stated as such: the CLI updates manifest_items.state and appends the event in ONE
   518	-- transaction; a direct writer that skips the event is caught by the digest chain below, not
   519	-- prevented.
   520	
   521	CREATE TABLE doc_lines (               -- document-level verbatim preservation (r2: the 86-line
   522	  id INTEGER PRIMARY KEY,              -- preamble is release-less; legacy_lines can't hold it)
   523	  repo_id INTEGER NOT NULL REFERENCES repos(id),
   524	  position INTEGER NOT NULL,           -- ordering among document-level segments
   525	  content TEXT NOT NULL,
   526	  UNIQUE (repo_id, position)
   527	);
   528	
   529	CREATE TABLE legacy_lines (            -- lossless import: unmapped/continuation lines, verbatim
   530	  id INTEGER PRIMARY KEY,
   531	  release_id INTEGER NOT NULL REFERENCES releases(id),
   532	  position INTEGER NOT NULL,
   533	  content TEXT NOT NULL,
   534	  disposition TEXT,                    -- NULL = pending; else 'kept'|'migrated'|'dropped:<why>'
   535	  UNIQUE (release_id, position)
   536	);
   537	
   538	CREATE TABLE grandfather_entries (     -- r3: referenced throughout but previously never defined
   539	  id INTEGER PRIMARY KEY,
   540	  import_run TEXT NOT NULL,            -- one id per `releases import` invocation
   541	  release_gid TEXT,                    -- NULL for document-level entries
   542	  rule TEXT NOT NULL,                  -- which rule was tolerated/defaulted
   543	  source_value TEXT,                   -- what the legacy file had (NULL = field absent)
   544	  supplied_value TEXT,                 -- what import wrote (default, MIG- ref, normalization)
   545	  disposition TEXT                     -- NULL = pending; strict flip requires none pending
   546	);
   547	
   548	CREATE TABLE op_receipts (             -- append-only CLI operation log (append-only via the same
   549	  id INTEGER PRIMARY KEY,              -- trigger pair as manifest_state_events)
   550	  op TEXT NOT NULL,
   551	  target_gid TEXT,
   552	  at TEXT NOT NULL,
   553	  txn_id TEXT NOT NULL,                -- one per CLI transaction
   554	  session_id TEXT NOT NULL,            -- r3: stable per-dogfood-session id (env-provided), so the
   555	                                       --   exit gate's ">=2 sessions" is mechanically checkable
   556	  state_digest_before TEXT NOT NULL,   -- sha256 of the BUSINESS-STATE dump (r3: excludes
   557	  state_digest_after TEXT NOT NULL     --   op_receipts, lock_audit, generation, and all digest
   558	);                                     --   fields — the old dump digest was self-referential and
   559	                                       --   uncomputable). Chain rule: each receipt's `before` must
   560	                                       --   equal the previous receipt's `after`; `check` recomputes
   561	                                       --   the current business-state digest and a mismatch with the
   562	                                       --   latest `after` = receipt-less mutation.
   563	CREATE TRIGGER op_no_update BEFORE UPDATE ON op_receipts
   564	  BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;
   565	CREATE TRIGGER op_no_delete BEFORE DELETE ON op_receipts
   566	  BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;
   567	
   568	CREATE INDEX idx_releases_repo ON releases(repo_id);
   569	CREATE INDEX idx_items_release ON manifest_items(release_id);
   570	CREATE INDEX idx_mse_item ON manifest_state_events(item_id);
   571	CREATE INDEX idx_legacy_release ON legacy_lines(release_id);
   572	CREATE INDEX idx_gf_import ON grandfather_entries(import_run);
   573	""".format(
   574	    repo_gid=_gid_check("global_id", "repo-"),
   575	    ref_gid=_gid_check("global_id", "ref-"),
   576	    mar_gid=_gid_check("global_id", "mar-"),
   577	    rel_gid=_gid_check("global_id", "rel-"),
   578	    mfi_gid=_gid_check("global_id", "mfi-"),
   579	)
   580	
   581	
   582	MIGRATION_002_DDL = """
   583	CREATE TABLE IF NOT EXISTS roadmap_items (  -- GH-69/GH-269: roadmap ledger.
   584	  id INTEGER PRIMARY KEY,                   --
   585	  global_id TEXT NOT NULL UNIQUE {rmi_gid}, -- edit; `releases roadmap sync` mirrors it here. Rows
   586	  repo_id INTEGER NOT NULL REFERENCES repos(id),  -- follow the GH-32 grammar (GID-keyed, no
   587	  gh_number INTEGER,                        -- integer ids as dump values), so merges and rebuilds
   588	  title TEXT NOT NULL CHECK (length(trim(title)) > 0),  -- need nothing new.
   589	  section TEXT NOT NULL CHECK (length(trim(section)) > 0),
   590	  position INTEGER NOT NULL,                -- order within its section at last sync
   591	  status_marker TEXT,                       -- the entry's leading status emoji, when present
   592	  complexity INTEGER, risk INTEGER, effort INTEGER,     -- cx/risk/eff when the entry states them
   593	  doc_path TEXT,                            -- first PROJECT/** link
   594	  issue_url TEXT,                           -- first this-repo issue/PR URL
   595	  raw_text TEXT NOT NULL,                   -- the entry block VERBATIM (lossless shadow)
   596	  first_seen TEXT NOT NULL,
   597	  updated_at TEXT NOT NULL,                 -- last sync that CHANGED this row (not last sync run)
   598	  UNIQUE (repo_id, gh_number)
   599	);
   600	CREATE INDEX IF NOT EXISTS idx_roadmap_repo ON roadmap_items(repo_id);
   601	""".format(rmi_gid=_gid_check("global_id", "rmi-"))
   602	
   603	
   604	def _ddl_statements(script):
   605	    """Split a trigger-free DDL script into individual statements.
   606	
   607	    GH-111: exists so migrations can avoid executescript(), which commits the caller's
   608	    transaction. Deliberately NOT general — it would mis-split a CREATE TRIGGER body, whose
   609	    BEGIN…END contains its own semicolons. Only trigger-free scripts may use it; migration
   610	    004 issues its trigger DDL as explicit single execute() calls instead.
   611	    """
   612	    if "CREATE TRIGGER" in script.upper():
   613	        raise ValueError("_ddl_statements cannot split trigger bodies; issue them individually")
   614	    # sqlite3.complete_statement() is comment- and string-literal-aware; a naive split(";")
   615	    # cuts mid-statement on the first `--` comment containing a semicolon.
   616	    statements, buffer = [], ""
   617	    for line in script.splitlines(keepends=True):
   618	        buffer += line
   619	        if sqlite3.complete_statement(buffer):
   620	            statements.append(buffer.strip())
   621	            buffer = ""
   622	    if buffer.strip():
   623	        statements.append(buffer.strip())
   624	    return statements
   625	
   626	
   627	def _table_exists(conn, name):
   628	    return conn.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
   629	                        (name,)).fetchone() is not None
   630	
   631	
   632	def _col(row, name, default=None):
   633	    """Read a column that may not exist yet on an un-migrated ledger. sqlite3.Row raises
   634	    IndexError for an absent key, so a bare row["baseline_count"] would turn "you have not run
   635	    `releases migrate`" into a traceback."""
   636	    try:
   637	        return row[name]
   638	    except (IndexError, KeyError):
   639	        return default
   640	
   641	
   642	def _has_column(conn, table, column):
   643	    """Schema probe. The dump writer uses it so a PRE-migration database can still be dumped
   644	    (and therefore digested) — `perform_migration` needs `business_digest` on the old shape
   645	    before it touches anything, and the dump grammar's absent-trailing-fields-read-as-NULL rule
   646	    makes the shorter record a legal dump rather than a lossy one."""
   647	    if not _table_exists(conn, table):
   648	        return False
   649	    return any(r["name"] == column for r in conn.execute("PRAGMA table_info(%s)" % table))
   650	
   651	
   652	def _ensure_roadmap_schema(conn, stamp=True):
   653	    """Apply migration 002 idempotently. MUST run inside a perform_write mutate when the DB
   654	    predates it: the new schema_migrations row is business state, and a schema change outside a
   655	    receipt would trip check's receipt-vs-change bypass detection — correctly.
   656	
   657	    GH-111: issued as individual execute() calls, NOT executescript(). Python's sqlite3
   658	    COMMITs any open transaction before running a script, so the old idiom would silently
   659	    split perform_migration()'s single transaction when 002 and 004 are both pending —
   660	    leaving 002 durable after a 004 failure while the journal still claims all-or-nothing.
   661	
   662	    stamp=False is the REGISTRY entry point: `apply_migrations` owns the ledger row there, and
   663	    `_rebuild` calls it with stamping suppressed entirely so it can write the ledger itself
   664	    afterwards. A self-stamping callback would collide with that on the primary key.
   665	    """
   666	    for statement in _ddl_statements(MIGRATION_002_DDL):
   667	        conn.execute(statement)
   668	    if stamp and conn.execute("SELECT 1 FROM schema_migrations WHERE version = 2").fetchone() is None:
   669	        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (2, ?)",
   670	                     (now_iso(),))
   671	
   672	
   673	MIGRATION_004_ITEMS_NEW = """
   674	CREATE TABLE manifest_items_new (
   675	  id INTEGER PRIMARY KEY,
   676	  global_id TEXT NOT NULL UNIQUE {mfi_gid},
   677	  release_id INTEGER NOT NULL REFERENCES releases(id),
   678	  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   679	  state TEXT NOT NULL CHECK (state IN ('dialed_in','shipped','cut')),
   680	  dialed_in_at TEXT,
   320	def artifact_paths(root):
   321	    return {
   322	        "db": os.path.join(root, DB_NAME),
   323	        "dump": os.path.join(root, DUMP_NAME),
   324	        "bak": os.path.join(root, DB_BAK_NAME),
   325	        "gen": os.path.join(root, GEN_NAME),
   326	        "drift": os.path.join(root, DRIFT_NAME),
   327	        "ledger": os.path.join(root, LEDGER_NAME),
   328	    }
   329	
   330	
   331	# ── lock + audit sidecar ────────────────────────────────────────────────────────────────────────
   332	
   333	def audit_log(root, outcome, detail=""):
   334	    """Append-only contention evidence, OUTSIDE the DB (r4 review finding: a refused writer
   335	    inserting into the committed DB would itself be an unlocked write, able to tear the very trio
   336	    it exists to audit). Line shape: <session_id> <timestamp> <outcome> <detail>, outcome in
   337	    acquired|refused|retried|recovered."""
   338	    _, audit_path, _ = lock_paths(root)
   339	    line = "%s %s %s %s\n" % (session_id(), now_iso(), outcome, detail)
   340	    try:
   341	        with open(audit_path, "a", encoding="utf-8") as fh:
   342	            fh.write(line)
   343	    except OSError as exc:
   344	        print("warn: rule=lock-audit: could not append to %s (%s)" % (audit_path, exc))
   345	
   346	
   347	class WriterLock:
   348	    """Repo-scoped writer lock (PRD Git story 1). Every acquisition attempt is logged to the
   349	    sidecar; a busy lock retries for RELEASES_APP_LOCK_WAIT seconds, then refuses with exit 4 —
   350	    and a refusal changes no committed artifact (that is the r4 negative control)."""
   351	
   352	    def __init__(self, root):
   353	        self.root = root
   354	        self.lock_path, _, self.journal_path = lock_paths(root)
   355	        self.fh = None
   356	
   357	    def acquire(self):
   358	        wait = _env_float("RELEASES_APP_LOCK_WAIT", 3.0)
   359	        deadline = time.time() + max(wait, 0.0)
   360	        announced_retry = False
   361	        while True:
   362	            self.fh = open(self.lock_path, "a+", encoding="utf-8")
   363	            try:
   364	                fcntl.flock(self.fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
   365	            except OSError:
   366	                self.fh.close()
   367	                self.fh = None
   368	                if not announced_retry:
   369	                    audit_log(self.root, "retried", "lock busy; retrying for up to %.0fs" % wait)
   370	                    announced_retry = True
   371	                if time.time() >= deadline:
   372	                    audit_log(self.root, "refused", "lock still busy after %.0fs" % wait)
   373	                    refuse("writer-lock",
   374	                           "another releases-app writer holds %s; refusal recorded in the "
   375	                           "lock-audit sidecar; no committed artifact was changed"
   376	                           % self.lock_path, code=EXIT_LOCK_REFUSED)
   377	                time.sleep(0.1)
   378	                continue
   379	            self.fh.seek(0)
   380	            self.fh.truncate()
   381	            self.fh.write("%s %s %s\n" % (now_iso(), session_id(), os.getpid()))
   382	            self.fh.flush()
   383	            audit_log(self.root, "acquired", "pid %d" % os.getpid())
   384	            return self
   385	
   386	    def release(self):
   387	        if self.fh is not None:
   388	            try:
   389	                fcntl.flock(self.fh.fileno(), fcntl.LOCK_UN)
   390	            finally:
   391	                self.fh.close()
   392	                self.fh = None
   393	
   394	    def __enter__(self):
   395	        return self.acquire()
   396	
   397	    def __exit__(self, *exc):
   398	        self.release()
   399	        return False
   400	
   401	
   402	# ── DB connection (PRAGMA foreign_keys asserted per connection) ─────────────────────────────────
   403	
   404	def connect(db_path, must_exist=True):
   405	    if must_exist and not os.path.exists(db_path):
   406	        refuse("not-initialized", "no %s here; run `releases init` first" % DB_NAME)
   407	    # isolation_level=None: transactions are BEGIN/COMMIT'd explicitly by perform_write, so the
   408	    # intent journal -> COMMIT -> stage -> rename ordering is the ONLY ordering that exists.
   409	    conn = sqlite3.connect(db_path, isolation_level=None)
   410	    conn.row_factory = sqlite3.Row
   411	    conn.execute("PRAGMA foreign_keys = ON")
   412	    if conn.execute("PRAGMA foreign_keys").fetchone()[0] != 1:
   413	        conn.close()
   414	        refuse("foreign-keys-pragma",
   415	               "PRAGMA foreign_keys=ON did not take effect on this connection; refusing to run")
   416	    return conn
   417	
   418	
   419	def get_setting(conn, key, default=None):
   420	    row = conn.execute("SELECT value FROM settings WHERE key = ?", (key,)).fetchone()
   421	    return row["value"] if row else default
   422	
   423	
   424	def get_generation(conn):
   425	    try:
   426	        return int(get_setting(conn, GENERATION_KEY, "0"))
   427	    except ValueError:
   428	        return 0
   429	
   430	
   431	def enforcement_mode(conn):
   432	    return get_setting(conn, "enforcement", "lenient")
   433	
   434	
   435	# ── migration 001 (v1 schema, PRD "Schema (v1)") ────────────────────────────────────────────────
   436	
   437	def _gid_check(column, prefix):
   438	    """Exact-shape global-id CHECK: the type prefix plus exactly 26 characters of the Crockford
   439	    base32 alphabet, written out in full (PRD GID shape note — prefix-only GLOBs were theater)."""
   440	    return "CHECK (%s GLOB '%s%s')" % (column, prefix, CROCKFORD_GLOB_CLASS * 26)
   441	
   442	
   443	MIGRATION_001 = """
   444	CREATE TABLE schema_migrations (
   445	  version INTEGER PRIMARY KEY,
   446	  applied_at TEXT NOT NULL
   447	);
   448	
   449	CREATE TABLE settings (            -- per-repo DB, so per-repo enforcement mode lives here
   450	  key TEXT PRIMARY KEY,
   451	  value TEXT NOT NULL
   452	);
   453	
   454	CREATE TABLE repos (
   455	  id INTEGER PRIMARY KEY,
   456	  global_id TEXT NOT NULL UNIQUE {repo_gid},
   457	  slug TEXT NOT NULL UNIQUE CHECK (length(trim(slug)) > 0)
   458	);  -- device-local paths deliberately NOT committed (review finding): the UI resolves local
   459	    -- checkout paths from the utils/hq/ registry, which is already per-device.
   460	
   461	CREATE TABLE issue_refs (          -- normalized issue reference: real URL XOR placeholder
   462	  id INTEGER PRIMARY KEY,
   463	  global_id TEXT NOT NULL UNIQUE {ref_gid},
   464	  url TEXT UNIQUE CHECK (url IS NULL OR url GLOB 'https://github.com/*/issues/*'),
   465	  temp_id TEXT UNIQUE CHECK (temp_id IS NULL OR
   466	    temp_id GLOB 'TMP-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]' OR
   467	    temp_id GLOB 'MIG-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]'),  -- MIG-: import-only (CLI-enforced)
   468	  created_at TEXT NOT NULL,
   469	  CHECK ((url IS NULL) != (temp_id IS NULL))   -- exactly one
   470	);
   471	
   472	CREATE TABLE marathons (
   473	  id INTEGER PRIMARY KEY,
   474	  global_id TEXT NOT NULL UNIQUE {mar_gid},
   475	  repo_id INTEGER NOT NULL REFERENCES repos(id),
   476	  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   477	  status TEXT NOT NULL CHECK (status IN ('planned','running','done','escalated','abandoned')),
   478	  created_at TEXT NOT NULL
   479	);
   480	
   481	CREATE TABLE releases (
   482	  id INTEGER PRIMARY KEY,
   483	  global_id TEXT NOT NULL UNIQUE {rel_gid},
   484	  repo_id INTEGER NOT NULL REFERENCES repos(id),
   485	  version TEXT CHECK (version IS NULL OR length(trim(version)) > 0),
   486	  codename TEXT,
   487	  status TEXT NOT NULL CHECK (status IN ('draft','active','shipped','cut')),
   488	  target_date TEXT CHECK (target_date IS NULL OR target_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
   489	  shipped_date TEXT CHECK (shipped_date IS NULL OR shipped_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
   490	  description TEXT NOT NULL CHECK (length(trim(description)) > 0),
   491	  exit_criterion TEXT,
   492	  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   493	  marathon_id INTEGER REFERENCES marathons(id),
   494	  gh_release_url TEXT,
   495	  milestone TEXT,
   496	  front_door_reviewed TEXT CHECK (front_door_reviewed IN ('Yes','No') OR front_door_reviewed IS NULL),
   497	  shakedown_reviewed  TEXT CHECK (shakedown_reviewed  IN ('Yes','No') OR shakedown_reviewed  IS NULL),
   498	  license_file        TEXT CHECK (license_file        IN ('Yes','No') OR license_file        IS NULL),
   499	  UNIQUE (repo_id, version)
   500	);
   501	
   502	CREATE TABLE manifest_items (
   503	  id INTEGER PRIMARY KEY,
   504	  global_id TEXT NOT NULL UNIQUE {mfi_gid},
   505	  release_id INTEGER NOT NULL REFERENCES releases(id),
   506	  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
   507	  state TEXT NOT NULL CHECK (state IN ('open','shipped','cut')),
   508	  UNIQUE (release_id, issue_ref_id)
   509	);
   510	
   511	CREATE TABLE manifest_state_events (   -- append-only re-scope trail (review finding: the old
   512	  id INTEGER PRIMARY KEY,              -- single overwriteable state_changed cell lost history)
   513	  item_id INTEGER NOT NULL REFERENCES manifest_items(id),
   514	  from_state TEXT NOT NULL CHECK (from_state IN ('open','shipped','cut')),
   515	  to_state   TEXT NOT NULL CHECK (to_state   IN ('open','shipped','cut')),
   516	  at TEXT NOT NULL,
   517	  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0)   -- a cut without a reason is refused
   518	);
   519	-- Append-only is enforced by triggers, not convention (r2 review finding):
   520	CREATE TRIGGER mse_no_update BEFORE UPDATE ON manifest_state_events
   521	  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
   522	CREATE TRIGGER mse_no_delete BEFORE DELETE ON manifest_state_events
   523	  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
   524	-- (same trigger pair on op_receipts). Transition LEGALITY and the item-state/event coupling are
   525	-- CLI-enforced, stated as such: the CLI updates manifest_items.state and appends the event in ONE
   526	-- transaction; a direct writer that skips the event is caught by the digest chain below, not
   527	-- prevented.
   528	
   529	CREATE TABLE doc_lines (               -- document-level verbatim preservation (r2: the 86-line
   530	  id INTEGER PRIMARY KEY,              -- preamble is release-less; legacy_lines can't hold it)
   531	  repo_id INTEGER NOT NULL REFERENCES repos(id),
   532	  position INTEGER NOT NULL,           -- ordering among document-level segments
   533	  content TEXT NOT NULL,
   534	  UNIQUE (repo_id, position)
   535	);
   536	
   537	CREATE TABLE legacy_lines (            -- lossless import: unmapped/continuation lines, verbatim
   538	  id INTEGER PRIMARY KEY,
   539	  release_id INTEGER NOT NULL REFERENCES releases(id),
   540	  position INTEGER NOT NULL,
   541	  content TEXT NOT NULL,
   542	  disposition TEXT,                    -- NULL = pending; else 'kept'|'migrated'|'dropped:<why>'
   543	  UNIQUE (release_id, position)
   544	);
   545	
   546	CREATE TABLE grandfather_entries (     -- r3: referenced throughout but previously never defined
   547	  id INTEGER PRIMARY KEY,
   548	  import_run TEXT NOT NULL,            -- one id per `releases import` invocation
   549	  release_gid TEXT,                    -- NULL for document-level entries
   550	  rule TEXT NOT NULL,                  -- which rule was tolerated/defaulted
   551	  source_value TEXT,                   -- what the legacy file had (NULL = field absent)
   552	  supplied_value TEXT,                 -- what import wrote (default, MIG- ref, normalization)
   553	  disposition TEXT                     -- NULL = pending; strict flip requires none pending
   554	);
   555	
   556	CREATE TABLE op_receipts (             -- append-only CLI operation log (append-only via the same
   557	  id INTEGER PRIMARY KEY,              -- trigger pair as manifest_state_events)
   558	  op TEXT NOT NULL,
   559	  target_gid TEXT,
   560	  at TEXT NOT NULL,
   561	  txn_id TEXT NOT NULL,                -- one per CLI transaction
   562	  session_id TEXT NOT NULL,            -- r3: stable per-dogfood-session id (env-provided), so the
   563	                                       --   exit gate's ">=2 sessions" is mechanically checkable
   564	  state_digest_before TEXT NOT NULL,   -- sha256 of the BUSINESS-STATE dump (r3: excludes
   565	  state_digest_after TEXT NOT NULL     --   op_receipts, lock_audit, generation, and all digest
   566	);                                     --   fields — the old dump digest was self-referential and
   567	                                       --   uncomputable). Chain rule: each receipt's `before` must
   568	                                       --   equal the previous receipt's `after`; `check` recomputes
   569	                                       --   the current business-state digest and a mismatch with the
   570	                                       --   latest `after` = receipt-less mutation.
   571	CREATE TRIGGER op_no_update BEFORE UPDATE ON op_receipts
   572	  BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;
   573	CREATE TRIGGER op_no_delete BEFORE DELETE ON op_receipts
   574	  BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;
   575	
   576	CREATE INDEX idx_releases_repo ON releases(repo_id);
   577	CREATE INDEX idx_items_release ON manifest_items(release_id);
   578	CREATE INDEX idx_mse_item ON manifest_state_events(item_id);
   579	CREATE INDEX idx_legacy_release ON legacy_lines(release_id);
   580	CREATE INDEX idx_gf_import ON grandfather_entries(import_run);
   581	""".format(
   582	    repo_gid=_gid_check("global_id", "repo-"),
   583	    ref_gid=_gid_check("global_id", "ref-"),
   584	    mar_gid=_gid_check("global_id", "mar-"),
   585	    rel_gid=_gid_check("global_id", "rel-"),
   586	    mfi_gid=_gid_check("global_id", "mfi-"),
   587	)
   588	
   589	
   590	MIGRATION_002_DDL = """
   591	CREATE TABLE IF NOT EXISTS roadmap_items (  -- GH-69/GH-269: roadmap ledger.
   592	  id INTEGER PRIMARY KEY,                   --
   593	  global_id TEXT NOT NULL UNIQUE {rmi_gid}, -- edit; `releases roadmap sync` mirrors it here. Rows
   594	  repo_id INTEGER NOT NULL REFERENCES repos(id),  -- follow the GH-32 grammar (GID-keyed, no
   595	  gh_number INTEGER,                        -- integer ids as dump values), so merges and rebuilds
   596	  title TEXT NOT NULL CHECK (length(trim(title)) > 0),  -- need nothing new.
   597	  section TEXT NOT NULL CHECK (length(trim(section)) > 0),
   598	  position INTEGER NOT NULL,                -- order within its section at last sync
   599	  status_marker TEXT,                       -- the entry's leading status emoji, when present
   600	  complexity INTEGER, risk INTEGER, effort INTEGER,     -- cx/risk/eff when the entry states them
   601	  doc_path TEXT,                            -- first PROJECT/** link
   602	  issue_url TEXT,                           -- first this-repo issue/PR URL
   603	  raw_text TEXT NOT NULL,                   -- the entry block VERBATIM (lossless shadow)
   604	  first_seen TEXT NOT NULL,
   605	  updated_at TEXT NOT NULL,                 -- last sync that CHANGED this row (not last sync run)
   606	  UNIQUE (repo_id, gh_number)
   607	);
   608	CREATE INDEX IF NOT EXISTS idx_roadmap_repo ON roadmap_items(repo_id);
   609	""".format(rmi_gid=_gid_check("global_id", "rmi-"))
   610	
   611	
   612	def _ddl_statements(script):
   613	    """Split a trigger-free DDL script into individual statements.
   614	
   615	    GH-111: exists so migrations can avoid executescript(), which commits the caller's
   616	    transaction. Deliberately NOT general — it would mis-split a CREATE TRIGGER body, whose
   617	    BEGIN…END contains its own semicolons. Only trigger-free scripts may use it; migration
   618	    004 issues its trigger DDL as explicit single execute() calls instead.
   619	    """
   620	    if "CREATE TRIGGER" in script.upper():
   621	        raise ValueError("_ddl_statements cannot split trigger bodies; issue them individually")
   622	    # sqlite3.complete_statement() is comment- and string-literal-aware; a naive split(";")
   623	    # cuts mid-statement on the first `--` comment containing a semicolon.
   624	    statements, buffer = [], ""
   625	    for line in script.splitlines(keepends=True):
   626	        buffer += line
   627	        if sqlite3.complete_statement(buffer):
   628	            statements.append(buffer.strip())
   629	            buffer = ""
   630	    if buffer.strip():
   631	        statements.append(buffer.strip())
   632	    return statements
   633	
   634	
   635	def _table_exists(conn, name):
   636	    return conn.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
   637	                        (name,)).fetchone() is not None
   638	
   639	
   640	def _col(row, name, default=None):
   641	    """Read a column that may not exist yet on an un-migrated ledger. sqlite3.Row raises
   642	    IndexError for an absent key, so a bare row["baseline_count"] would turn "you have not run
   643	    `releases migrate`" into a traceback."""
   644	    try:
   645	        return row[name]
   646	    except (IndexError, KeyError):
   647	        return default
   648	
   649	
   650	def _has_column(conn, table, column):
   651	    """Schema probe. The dump writer uses it so a PRE-migration database can still be dumped
   652	    (and therefore digested) — `perform_migration` needs `business_digest` on the old shape
   653	    before it touches anything, and the dump grammar's absent-trailing-fields-read-as-NULL rule
   654	    makes the shorter record a legal dump rather than a lossy one."""
   655	    if not _table_exists(conn, table):
   656	        return False
   657	    return any(r["name"] == column for r in conn.execute("PRAGMA table_info(%s)" % table))
   658	
   659	
   660	def _ensure_roadmap_schema(conn, stamp=True):
   661	    """Apply migration 002 idempotently. MUST run inside a perform_write mutate when the DB
   662	    predates it: the new schema_migrations row is business state, and a schema change outside a
   663	    receipt would trip check's receipt-vs-change bypass detection — correctly.
   664	
   665	    GH-111: issued as individual execute() calls, NOT executescript(). Python's sqlite3
   666	    COMMITs any open transaction before running a script, so the old idiom would silently
   667	    split perform_migration()'s single transaction when 002 and 004 are both pending —
   668	    leaving 002 durable after a 004 failure while the journal still claims all-or-nothing.
   669	
   670	    stamp=False is the REGISTRY entry point: `apply_migrations` owns the ledger row there, and
   671	    `_rebuild` calls it with stamping suppressed entirely so it can write the ledger itself
   672	    afterwards. A self-stamping callback would collide with that on the primary key.
   673	    """
   674	    for statement in _ddl_statements(MIGRATION_002_DDL):
   675	        conn.execute(statement)
   676	    if stamp and conn.execute("SELECT 1 FROM schema_migrations WHERE version = 2").fetchone() is None:
   677	        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (2, ?)",
   678	                     (now_iso(),))
   679	
   680	
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-vkw7YabM' (errno=Operation not permitted)
2026-08-31 16:32:53.645 xcodebuild[75592:6480226]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:53.840 xcodebuild[75592:6480225] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-iAXpFNXI' (errno=Operation not permitted)
2026-08-31 16:32:54.454 xcodebuild[75595:6480244]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:54.652 xcodebuild[75595:6480243] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/utils/py/releases_app.py b/utils/py/releases_app.py
index 354fe55d..bb9cc9ea 100644
--- a/utils/py/releases_app.py
+++ b/utils/py/releases_app.py
@@ -96,42 +96,49 @@ JOURNAL_NAME = "releases-app-journal.json"
 PROJECT_FIELDS = (
     "Release ID", "Release status", "Target date", "Shipped date", "Codename",
     "Tracking issue", "GitHub release", "Front-door reviewed", "Shakedown reviewed",
     "License file",
 )
 
 STATUSES = ("draft", "active", "shipped", "cut")
 STATUS_RENDER = {"draft": "Draft", "active": "Active", "shipped": "Shipped", "cut": "Cut"}
 MARATHON_STATUSES = ("planned", "running", "done", "escalated", "abandoned")
 ITEM_STATES = ("open", "shipped", "cut")
 # manifest-state transition legality is CLI-enforced (PRD schema note). GH-111 retires FREEZE for
 # DIALED-IN membership: a task is dialed into a release, ships, or is cut. `shipped` is no longer a
 # dead end that only the schema knew about — `manifest ship` writes it. Both `shipped` and `cut` are
 # terminal FOR THAT ROW: re-admitting an item is a NEW dial-in row, which keeps the trail append-only
 # and readable rather than flipping one row back and forth.
 LEGAL_ITEM_TRANSITIONS = {("dialed_in", "shipped"), ("dialed_in", "cut")}
 GH_ISSUE_URL_RE = re.compile(r"^https://github\.com/[^/\s]+/[^/\s]+/issues/[0-9]+$")
 TMP_RE = re.compile(r"^TMP-[A-Z0-9]{6}$")
 MIG_RE = re.compile(r"^MIG-[A-Z0-9]{6}$")
 DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
+# The legacy `GH_URL:` import field means a RELEASE pointer; it accepted issue URLs only before
+# GH-349 and still does. Widening it to PRs was an unrequested cross-caller change with no contract
+# test behind it — codex QA, 2026-08-31. The roadmap ledger keeps its own, wider matcher below.
 URL_EXTRACT_RE = re.compile(r"https://github\.com/[^/\s]+/[^/\s]+/issues/[0-9]+")
 
+# The roadmap ledger has always accepted a `pull` URL in an entry (the pre-GH-349 regex did too),
+# so it matches both kinds — org-agnostic, which is the whole point of GH-349.
+ROADMAP_URL_RE = re.compile(r"https://github\.com/[^/\s]+/[^/\s]+/(?:issues|pull|pulls)/[0-9]+")
+
 # Crockford base32 (PRD GID shape note): every global_id CHECK is the type prefix plus exactly
 # 26 characters of [0-9A-HJKMNP-TV-Z], written out in full in the migration so length AND
 # alphabet are schema-refused, not convention.
 CROCKFORD_GLOB_CLASS = "[0-9A-HJKMNP-TV-Z]"
 
 GENERATION_KEY = "generation"
 
 CRASH_BOUNDARIES = ("pre-commit", "post-commit", "post-stage", "mid-rename", "post-rename")
 
 
 def _env_float(name, default):
     raw = os.environ.get(name, "")
     try:
         return float(raw) if raw else default
     except ValueError:
         return default
 
 
 # ── small utilities ─────────────────────────────────────────────────────────────────────────────
 
@@ -2698,43 +2705,43 @@ def cmd_project_sync(args):
         conn.close()
 
 
 # ── GH-269: roadmap ledger (`releases roadmap sync` / `list`) ────────────────────────────────
 # Ledger contract: the database is the ONLY thing humans and
 # agents edit; this code only READS it and mirrors the ledger into roadmap_items. The parser is a
 # twin of the marathon planner's (utils/py/_marathon_plan.py) with one deliberate difference: the
 # planner recognises only its four SECTIONS and skips the rest silently, while the shadow captures
 # EVERY `###` section under `## Ledger` — the shadow's job is to mirror what the file says, not to
 # re-decide what the planner should see.
 
 ROADMAP_NAME = "ROADMAP.md"
 _ROADMAP_STATUS_MARKERS = ["\U0001F195", "\U0001F6A7", "\u2705", "\u23F8\uFE0F", "\U0001F7E1",
                            "\u2699\uFE0F", "\U0001F532", "\u26D4", "\U0001F52E", "\U0001F7E2",
                            "\U0001F534", "\U0001F41E"]
 
 
 # ── GH-108: the one canonical rating grammar ────────────────────────────────────────────────────
 # `rated N/N/N/N` — exactly four slash-separated integers 1-100, axis order fixed as
 # pri/sev/appeal/effort — optionally followed by ` ovr N` (an integer 4-400 on calc's own scale).
-# There is no labeled long form: the axis NAMES live in PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md,
-# not in the entry line. Higher is better on every axis, effort included (it scores CHEAPNESS), so
-# the four combine without sign-flipping.
+# There is no labeled long form: the axis NAMES live in RELEASES-DB-FAQS.md (and
+# PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md), not in the entry line. Higher is better on every axis,
+# effort included (it scores CHEAPNESS), so the four combine without sign-flipping.
 #
 # The refusal contract matters as much as the grammar: the PRESENCE of a `rated` or `ovr` token
 # either parses as the full form or refuses with a named rule. A malformed shape must never read
 # as "unrated" — that would silently drop an operator's prioritisation and look like they never
 # scored the task.
 # The TOKEN test requires a digit after the word, so ordinary prose ("a highly rated entry",
 # "underrated") is not mistaken for a score — while a genuinely malformed `rated 70/40/55` still
 # counts as a token and is refused rather than read as unrated.
 _RATED_TOKEN_RE = re.compile(r"\brated\s+\d")
 # The DUPLICATE test is deliberately NARROWER than the presence test: it counts only
 # slash-bearing matches. "the rated 3rd priority item ... rated 90/90/90/90" is ONE rating
 # beside prose, and refusing it as a duplicate rejects a correctly-scored entry
 # (aider/qwen3.8-max QA r1, [Should] #1 — reproduced before fixing). The PRESENCE test stays
 # broad on purpose: a bare `rated 70` is a truncated score, and reading it as "unrated" would
 # be exactly the silent drop this contract exists to prevent. Prose shaped "rated <int> <word>"
 # with no real score beside it therefore still refuses — loudly, and fixable in one edit, which
 # is the trade this repo prefers over an invisible drop.
 _RATED_SCORE_TOKEN_RE = re.compile(r"\brated\s+\d+/")
 _RATED_RE = re.compile(r"\brated\s+(\d+)/(\d+)/(\d+)/(\d+)(?![\w/])")
 # `ovr` requires a DIGIT, not merely a following token. Unbackticked prose — "the ovr wins over
@@ -2788,88 +2795,191 @@ def parse_rating(raw, title):
     values = [int(g) for g in m.groups()]
     for axis, value in zip(("pri", "sev", "appeal", "effort"), values):
         if not 1 <= value <= 100:
             refuse("rating-range", "%s scores %s at %d; every axis is 1-100 (100 = strongest, "
                                    "effort included — it scores cheapness)" % (where, axis, value))
     out = dict(zip(RATING_COLUMNS[:4], values))
     out["rating_ovr"] = None
     if ovr_tokens:
         mo = _OVR_RE.search(raw)
         if not mo:
             refuse("ovr-shape", "%s carries an `ovr` token with no integer after it; %s"
                    % (where, _RATING_GRAMMAR))
         ovr = int(mo.group(1))
         if not 4 <= ovr <= 400:
             refuse("ovr-range", "%s overrides to %d; the override is on calc's own 4-400 scale"
                    % (where, ovr))
         out["rating_ovr"] = ovr
     return out
 
 
+# GH-349 review (LTVera-Pandas #322): a ledger entry's GH number is a KEY, not a mention. It is
+# only read from the HEAD of the title. An unanchored search harvested 111 out of "Execution
+# checklist for GH-111 + GH-108", which collided with the real GH-111 entry and made
+# `roadmap sync` refuse outright on this repo's own ROADMAP.md. A title that names several issues
+# (`#129/#130/#131 · Wave 1 …`) is an umbrella heading, not a key, and must stay unnumbered.
+_ROADMAP_KEY_RE = re.compile(r"^(?:GH-|#)(\d+)\b")
+# The separator set distinguishes a RANGE from prose. `..`/`...` and U+2013 EN DASH are the
+# conventional numeric-range delimiters (`GH-135..140`, `GH-135–140` — six issues, not issue 135).
+# U+2014 EM DASH is deliberately EXCLUDED: `GH-100 — 2026 planning` is a single-issue title whose
+# key would otherwise be silently dropped. The ASCII hyphen is excluded for the same reason.
+# The first pass conflated the two dashes; codex QA separated them, 2026-08-31.
+_ROADMAP_MULTI_KEY_RE = re.compile(
+    r"^(?:GH-|#)\d+\s*(?:[/,+&\u2013]|\.\.\.?)\s*(?:GH-|#)?\d+")
+
+# Markdown task-list items (`- [ ]`, `- [x]`) share the `- [` prefix with a link bullet but are
+# not ledger entries; without this they parsed as rows with an empty or "x" title.
+_ROADMAP_TASKBOX_RE = re.compile(r"^- \[[ xX]\]")
+
+
+def _is_ledger_bullet(line):
+    """A ledger entry opener: a bold bullet or a link bullet, never a task-list checkbox."""
+    if line.startswith("- **"):
+        return True
+    return line.startswith("- [") and not _ROADMAP_TASKBOX_RE.match(line)
+
+
+def _roadmap_gh_number(title):
+    """The GH number a ledger entry is keyed by, or None. Anchored at the head of the title."""
+    if _ROADMAP_MULTI_KEY_RE.match(title):
+        return None
+    m = _ROADMAP_KEY_RE.match(title)
+    return int(m.group(1)) if m else None
+
+
+# A scheme in a markdown link target: `https:`, `mailto:`, or a Windows drive prefix `C:`. Any of
+# these means the target is not a repo-relative path, whatever it ends with.
+_DOC_SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
+
+
+def _doc_pointer(target):
+    """The repo-relative document path a link target names, or None.
+
+    The `doc_path` column is a path a consumer resolves against the filesystem, so an absolute
+    URL, a mail address or a drive-lettered path in it yields a miss indistinguishable from a
+    dead pointer. codex QA found the first cut let all three through, because the extraction
+    regexes accepted any `.md`-suffixed target and this check was only consulted on the fallback
+    branch. It is now the SINGLE validator every candidate passes through, whichever regex found
+    it — a scheme-bearing `https://github.com/acme/specs/blob/main/DESIGN.md` is rejected here
+    even though it ends `.md`."""
+    if not target:
+        return None
+    target = target.strip()
+    if not target:
+        return None
+    if _DOC_SCHEME_RE.match(target) or target.startswith("/") or "\\" in target:
+        return None
+    path = target.split("#", 1)[0].split("?", 1)[0]
+    return path if path.endswith(".md") else None
+
+
+def _roadmap_issue_url(raw, link_target, gh_number):
+    """The URL a ledger entry is keyed to, or None.
+
+    Exactly two things count as evidence of identity: the bullet's OWN link target, and a URL in
+    the block whose number corroborates the title's GH key. Nothing else — an unanchored search
+    keyed GH-94 to a DIFFERENT repo's issue #2 and GH-68 to a PR, because both hooks cite other
+    work in passing.
+
+    An earlier cut kept a third branch for UNKEYED entries: the first URL on the bullet's first
+    line. codex QA showed that branch is wrong on the reporting repo's live data, where it stored
+    a BLOCKER as the row's identity — `Grow Willies …` took #42 (a blocker that has its own ledger
+    row) and `Marathon Plan 2026-07-07 …` took #47 (merely its only fireable lane). Being first is
+    not evidence. An unkeyed entry whose own link is a document now stores nothing.
+
+    Position never implies identity here: no URL beats a wrong URL."""
+    if link_target:
+        target = link_target.strip()
+        m = ROADMAP_URL_RE.fullmatch(target)
+        if m:
+            num = int(target.rsplit("/", 1)[1])
+            if gh_number is None or num == gh_number:
+                return m.group(0)
+    if gh_number is None:
+        return None
+    for cand in ROADMAP_URL_RE.findall(raw):
+        if int(cand.rsplit("/", 1)[1]) == gh_number:
+            return cand
+    return None
+
+
 def parse_roadmap_ledger(path):
     """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
-    from its `- **` line to the next `- **`, `###`, or `##`."""
+    from its bullet line (`- **` or `- [`) to the next bullet, `###`, or `##`."""
     lines = open(path, encoding="utf-8").read().splitlines()
     entries = []
     sec = None
     inledger = False
     pos = {}
     i, n = 0, len(lines)
     while i < n:
         line = lines[i]
         if re.match(r"^##\s+Ledger\s*$", line.strip()):
             inledger = True
             i += 1
             continue
         if inledger and re.match(r"^##\s+", line):
             break
         if inledger and line.startswith("### "):
             sec = line[4:].strip()
             i += 1
             continue
-        if inledger and sec and line.startswith("- **"):
+        if inledger and sec and _is_ledger_bullet(line):
             j = i + 1
-            while j < n and not (lines[j].startswith("- **") or lines[j].startswith("### ")
+            while j < n and not (_is_ledger_bullet(lines[j]) or lines[j].startswith("### ")
                                  or re.match(r"^##\s+", lines[j])):
                 j += 1
             raw = "\n".join(lines[i:j]).rstrip()
-            m = re.match(r"^- \*\*(.+?)\*\*", raw)
-            title = m.group(1).strip() if m else raw[4:80]
-            gh = re.match(r"^GH-(\d+)\b", title)
+            m_bold = re.match(r"^- \*\*(.+?)\*\*", raw)
+            m_link = re.match(r"^- \[(.+?)\](?:\((.*?)\))?", raw)
+            if m_bold:
+                title = m_bold.group(1).strip()
+            elif m_link:
+                title = m_link.group(1).strip()
+            else:
+                title = raw[2:].strip()[:80]
+            gh_number = _roadmap_gh_number(title)
             marker = None
             for cand in _ROADMAP_STATUS_MARKERS:
                 if cand in raw:
                     marker = cand
                     break
             cre = re.search(r"cx/risk/eff (\d+)/(\d+)/(\d+)", raw)
-            doc = re.search(r"\]\((PROJECT/[^)]+\.md)", raw)
-            issue = re.search(r"https://github\.com/HiQS-(?:Suite|Labs)/XYZ-forge/(?:issues|pull)/\d+", raw)
+            link_target = m_link.group(2) if m_link else None
+            doc = (re.search(r"\]\((PROJECT/[^)#]+\.md)(?:#[^)]*)?\)", raw)
+                   or re.search(r"\]\(([^)#\s]+\.md)(?:#[^)]*)?\)", raw))
+            # Every candidate goes through the one validator — the extraction regexes only find
+            # a shape, they do not decide whether it is a document pointer.
+            doc_path = _doc_pointer(doc.group(1)) if doc else None
+            if doc_path is None:
+                doc_path = _doc_pointer(link_target)
+            issue_url = _roadmap_issue_url(raw, link_target, gh_number)
             pos[sec] = pos.get(sec, 0) + 1
             entry = {
-                "gh_number": int(gh.group(1)) if gh else None,
+                "gh_number": gh_number,
                 "title": title, "section": sec, "position": pos[sec],
                 "status_marker": marker,
                 "complexity": int(cre.group(1)) if cre else None,
                 "risk": int(cre.group(2)) if cre else None,
                 "effort": int(cre.group(3)) if cre else None,
-                "doc_path": doc.group(1) if doc else None,
-                "issue_url": issue.group(0) if issue else None,
+                "doc_path": doc_path,
+                "issue_url": issue_url,
                 "raw_text": raw,
             }
             entry.update(parse_rating(raw, title))
             entries.append(entry)
             i = j
             continue
         i += 1
     return entries
 
 
 _ROADMAP_FIELDS = ("gh_number", "title", "section", "position", "status_marker",
                    "complexity", "risk", "effort", "doc_path", "issue_url", "raw_text") \
                   + RATING_COLUMNS
 
 
 
 def validate_raw_text(raw_text, issue_num=None):
     """GH-257: validate that raw_text matches the markdown shape the renderer requires.
 
     The renderer (utils/roadmap-dashboard.sh) parses bullets starting with an exact `- **<title>**`
@@ -3163,52 +3273,102 @@ def cmd_roadmap_update(args):
 def cmd_roadmap_sync(args):
     root = resolve_root(args.root)
     # PR #240 review: sync mirrors ROADMAP.md and DELETES rows absent from it — in a releases-mode
     # repo the DB is canonical and rows arrive via `roadmap add` with no markdown source line, so
     # mirroring would destroy parked intake. Skip cleanly (exit 0): wave_reconcile.py calls sync
     # unconditionally post-merge and must stay green in both modes.
     try:
         with open(os.path.join(root, ".pdda-mode")) as f:
             if "ROADMAP_SOURCE=releases" in f.read():
                 print("roadmap sync: skipped — releases-mode repo (the DB is canonical; sync only "
                       "mirrors ROADMAP.md in legacy mode, and would delete rows parked by `roadmap add`)")
                 return
     except OSError:
         pass
     conn = connect(artifact_paths(root)["db"])
     try:
         md_path = os.path.join(root, ROADMAP_NAME)
         if not os.path.exists(md_path):
             refuse("roadmap-missing", "no %s at %s — nothing to shadow" % (ROADMAP_NAME, root))
         parsed = parse_roadmap_ledger(md_path)
+        if len(parsed) == 0:
+            ledger_has_content = False
+            in_ledger_check = False
+            for line in open(md_path, encoding="utf-8").read().splitlines():
+                if re.match(r"^##\s+Ledger\s*$", line.strip()):
+                    in_ledger_check = True
+                    continue
+                if in_ledger_check and re.match(r"^##\s+", line):
+                    break
+                # A `###` section heading is ledger STRUCTURE, not content: a ledger with its
+                # sections and no bullets is genuinely empty. Format drift, by contrast, is
+                # bullets in a shape the parser missed — still non-heading lines, still caught.
+                if (in_ledger_check and line.strip()
+                        and not line.strip().startswith("<!--")
+                        and not line.startswith("###")):
+                    ledger_has_content = True
+                    break
+            has_rows = bool(_table_exists(conn, "roadmap_items")
+                            and conn.execute("SELECT 1 FROM roadmap_items LIMIT 1").fetchone())
+            if ledger_has_content or has_rows:
+                # --allow-empty is the ONE sanctioned way to clear the mirror. It is deliberately
+                # narrow: it never excuses a ledger that still has content, so it cannot be used to
+                # paper over the format drift this guard exists to catch. Without it, an
+                # intentionally emptied ledger was a dead end, and AGENTS.md forbids the hand-edit
+                # of releases.db that agy suggested as the workaround. codex QA, 2026-08-31.
+                if ledger_has_content or not getattr(args, "allow_empty", False):
+                    refuse("roadmap-empty-parse",
+                           "parsed 0 entries from %s (%s); refusing to delete roadmap_items%s"
+                           % (ROADMAP_NAME,
+                              "ledger is non-empty" if ledger_has_content else "table has existing rows",
+                              "" if ledger_has_content else " — pass --allow-empty if the ledger is "
+                              "meant to be empty and you intend to clear the mirror"))
+                n_rows = conn.execute("SELECT COUNT(*) FROM roadmap_items").fetchone()[0]
+                print("roadmap sync: --allow-empty — %s ledger is empty, clearing %d mirrored row(s)"
+                      % (ROADMAP_NAME, n_rows))
         # duplicate GH keys in the markdown would make the mirror ambiguous — name it, do not pick
         seen = {}
         for e in parsed:
             if e["gh_number"] is not None:
                 if e["gh_number"] in seen:
                     refuse("roadmap-duplicate-gh",
                            "GH-%d appears twice in %s (%r and %r). The mirror keys entries by GH "
                            "number; merge or renumber one of them, then re-run."
                            % (e["gh_number"], ROADMAP_NAME, seen[e["gh_number"]][:60],
                               e["title"][:60]))
                 seen[e["gh_number"]] = e["title"]
 
+        # An unkeyed row is keyed by its TITLE instead (see the `have`/`parsed` key below), so two
+        # identical unkeyed titles are the same ambiguity as a duplicate GH number — and more
+        # reachable since GH-349 made umbrella and range headings deliberately unkeyed. Left
+        # unguarded, both enter `adds` on the first sync and collapse to one key on the next,
+        # leaving an orphan row behind. codex QA, 2026-08-31.
+        seen_titles = set()
+        for e in parsed:
+            if e["gh_number"] is None:
+                if e["title"] in seen_titles:
+                    refuse("roadmap-duplicate-title",
+                           "the unkeyed entry %r appears twice in %s. Entries without a GH number "
+                           "are mirrored by title, so two identical ones are ambiguous; give one a "
+                           "GH key or retitle it, then re-run." % (e["title"][:80], ROADMAP_NAME))
+                seen_titles.add(e["title"])
+
         repo = conn.execute("SELECT id, global_id FROM repos ORDER BY id LIMIT 1").fetchone()
         if repo is None:
             refuse("no-repo", "the DB has no repos row; run `releases init` first")
 
         # GH-108/GH-111: feature commands do NOT self-migrate. Rating storage arrives through
         # `releases migrate` (migration 003); sync refuses clearly when a rated entry meets a
         # ledger that cannot hold it, rather than installing schema of its own or — worse —
         # writing the entry with its scores silently dropped.
         rating_ok = _has_column(conn, "roadmap_items", "rating_pri")
         if not rating_ok and any(e["rating_pri"] is not None for e in parsed):
             refuse("schema-behind",
                    "%s carries `rated` scores but this ledger has no rating columns. Run "
                    "`releases migrate` first — sync mirrors ROADMAP.md, it never installs schema."
                    % ROADMAP_NAME)
 
         have = {}
         if _table_exists(conn, "roadmap_items"):
             for r in conn.execute("SELECT * FROM roadmap_items WHERE repo_id = ?", (repo["id"],)):
                 key = ("gh", r["gh_number"]) if r["gh_number"] is not None else ("title", r["title"])
                 have[key] = {c: _col(r, c) for c in r.keys()}
@@ -4607,40 +4767,45 @@ def build_parser():
     sp.add_argument("--side-by-side", action="store_true", default=True,
                     help="the only mode in Phase 0 (accepted for CLI-shape compatibility)")
 
     sp = sub.add_parser("check",
                         help="DB<->dump<->generated consistency; FK pragma; stale WAL; "
                              "receipt-vs-change bypass detection; temp-ref staleness; "
                              "duplication warnings; per-boundary crash recovery")
     sp.add_argument("--rebuild", action="store_true",
                     help="rebuild the DB from the dump (git-merge resolution ONLY)")
 
     sp = sub.add_parser("reconcile", help="fill real URLs into temp refs")
     sp.add_argument("--map", action="append", metavar="TMP-X=URL",
                     help="placeholder -> real issue URL (repeatable)")
 
     sp = sub.add_parser("dashboard", help="render the releases and roadmap dashboard HTML")
 
     sp = sub.add_parser("roadmap", help="Roadmap ledger (GH-269): sync/list the ledger items")
     rsub = sp.add_subparsers(dest="roadmap_cmd", required=True)
     sp_rs = rsub.add_parser("sync", help="mirror legacy ROADMAP.md's ledger into roadmap_items (one-way)")
     sp_rs.add_argument("--dry-run", action="store_true", help="report the diff, write nothing")
+    sp_rs.add_argument("--allow-empty", action="store_true",
+                       help="permit clearing roadmap_items when the ledger is genuinely empty. "
+                            "Without it a 0-entry parse REFUSES (rule=roadmap-empty-parse) so "
+                            "format drift can never silently delete the mirror; this flag never "
+                            "excuses a ledger that still has content")
     sp_rl = rsub.add_parser("list", help="print the shadow rows")
     sp_rl.add_argument("--json", dest="as_json", action="store_true",
                        help="emit rows as a JSON array (machine-readable; the default rendering "
                             "is a display, not an API)")
 
     sp_ra = rsub.add_parser("add", help="intake a single issue into the roadmap ledger directly")
     sp_ra.add_argument("--issue-num", required=True, type=int, help="GH issue number")
     sp_ra.add_argument("--issue-url", required=True, help="GH issue URL")
     sp_ra.add_argument("--title", required=True, help="Issue title")
     sp_ra.add_argument("--created", required=True, help="Created date YYYY-MM-DD")
     sp_ra.add_argument("--doc-path", required=True, help="Capture doc relpath")
     sp_ra.add_argument("--raw-text", default=None,
                        help="pre-rendered ROADMAP line (hq park passes hq_roadmap_line output so "
                             "preview and stored row share one template). GH-249: a `rated "
                             "N/N/N/N [ovr N]` token in this line is parsed and stored — in a "
                             "releases-mode repo this is the ONLY way to score an entry, since "
                             "`roadmap sync` is a no-op there")
     sp_ra.add_argument("--dry-run", action="store_true", help="print what would be written and write nothing")
 
     sp_rr = rsub.add_parser("rate", help="score a roadmap row that is already parked (GH-253)")
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-9TzdQw4V' (errno=Operation not permitted)
2026-08-31 16:32:56.045 xcodebuild[75600:6480274]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:56.242 xcodebuild[75600:6480273] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-gkBtoAH7' (errno=Operation not permitted)
2026-08-31 16:32:56.860 xcodebuild[75606:6480320]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:57.056 xcodebuild[75606:6480319] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/utils/py/releases_app.py b/utils/py/releases_app.py
index 354fe55d..71966c0a 100644
--- a/utils/py/releases_app.py
+++ b/utils/py/releases_app.py
@@ -88,44 +88,43 @@ DRIFT_NAME = "RELEASES.generated.md.drift"
 LEDGER_NAME = "RELEASES.md"          # READ-ONLY for this tool, forever in Phase 0
 LOCK_NAME = "releases-app.lock"
 AUDIT_NAME = "releases-app-lock-audit.log"
 JOURNAL_NAME = "releases-app-journal.json"
 
 # GitHub Projects are a one-way visual projection of this DB.  The immutable Release ID field
 # is deliberately the remote idempotency key: we do not add GitHub-owned IDs to the release
 # schema, and deleting a card merely lets the next sync recreate its projection.
 PROJECT_FIELDS = (
     "Release ID", "Release status", "Target date", "Shipped date", "Codename",
     "Tracking issue", "GitHub release", "Front-door reviewed", "Shakedown reviewed",
     "License file",
 )
 
 STATUSES = ("draft", "active", "shipped", "cut")
 STATUS_RENDER = {"draft": "Draft", "active": "Active", "shipped": "Shipped", "cut": "Cut"}
 MARATHON_STATUSES = ("planned", "running", "done", "escalated", "abandoned")
 ITEM_STATES = ("open", "shipped", "cut")
 # manifest-state transition legality is CLI-enforced (PRD schema note). GH-111 retires FREEZE for
 # DIALED-IN membership: a task is dialed into a release, ships, or is cut. `shipped` is no longer a
-# dead end that only the schema knew about — `manifest ship` writes it. Both `shipped` and `cut` are
-# terminal FOR THAT ROW: re-admitting an item is a NEW dial-in row, which keeps the trail append-only
-# and readable rather than flipping one row back and forth.
-LEGAL_ITEM_TRANSITIONS = {("dialed_in", "shipped"), ("dialed_in", "cut")}
+# dead end that only the schema knew about — `manifest ship` writes it. GH-351 adds `manifest unship`
+# to retract a false shipped item back to dialed_in.
+LEGAL_ITEM_TRANSITIONS = {("dialed_in", "shipped"), ("dialed_in", "cut"), ("shipped", "dialed_in")}
 GH_ISSUE_URL_RE = re.compile(r"^https://github\.com/[^/\s]+/[^/\s]+/issues/[0-9]+$")
 TMP_RE = re.compile(r"^TMP-[A-Z0-9]{6}$")
 MIG_RE = re.compile(r"^MIG-[A-Z0-9]{6}$")
 DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
 URL_EXTRACT_RE = re.compile(r"https://github\.com/[^/\s]+/[^/\s]+/issues/[0-9]+")
 
 # Crockford base32 (PRD GID shape note): every global_id CHECK is the type prefix plus exactly
 # 26 characters of [0-9A-HJKMNP-TV-Z], written out in full in the migration so length AND
 # alphabet are schema-refused, not convention.
 CROCKFORD_GLOB_CLASS = "[0-9A-HJKMNP-TV-Z]"
 
 GENERATION_KEY = "generation"
 
 CRASH_BOUNDARIES = ("pre-commit", "post-commit", "post-stage", "mid-rename", "post-rename")
 
 
 def _env_float(name, default):
     raw = os.environ.get(name, "")
     try:
         return float(raw) if raw else default
@@ -856,57 +855,83 @@ CREATE TABLE IF NOT EXISTS jog_queue (
 CREATE INDEX IF NOT EXISTS idx_jog_queue_repo_pos ON jog_queue(repo_id, position);
 CREATE INDEX IF NOT EXISTS idx_jog_queue_status ON jog_queue(status);
 """
 
 
 def _ensure_jog_schema(conn, stamp=True):
     """Apply migration 006 idempotently."""
     ddl = MIGRATION_006_DDL.format(jog_gid=_gid_check("global_id", "jog-"))
     for statement in _ddl_statements(ddl):
         conn.execute(statement)
     if stamp and conn.execute("SELECT 1 FROM schema_migrations WHERE version = 6").fetchone() is None:
         conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (6, ?)",
                      (now_iso(),))
 
 
 def _migration_006(conn):
     """GH-259: Add dedicated jog_queue table for serial execution."""
     _ensure_jog_schema(conn, stamp=False)
 
 
+def _migration_007(conn):
+    """GH-349 Scope #3: Add updated_at modification timestamps to remaining tables.
+
+    Only roadmap_items and jog_queue previously carried updated_at; adding updated_at to
+    releases, manifest_items, marathons, repos, settings, issue_refs, doc_lines, legacy_lines,
+    and grandfather_entries allows consumers to detect changes and staleness across the ledger.
+    """
+    stamp = now_iso()
+    tables = ("releases", "manifest_items", "marathons", "repos", "settings", "issue_refs",
+              "doc_lines", "legacy_lines", "grandfather_entries")
+    for table in tables:
+        if _table_exists(conn, table) and not _has_column(conn, table, "updated_at"):
+            conn.execute("ALTER TABLE %s ADD COLUMN updated_at TEXT" % table)
+            if table == "issue_refs" and _has_column(conn, table, "created_at"):
+                conn.execute("UPDATE issue_refs SET updated_at = COALESCE(created_at, ?)", (stamp,))
+            elif table == "marathons" and _has_column(conn, table, "created_at"):
+                conn.execute("UPDATE marathons SET updated_at = COALESCE(created_at, ?)", (stamp,))
+            elif table == "releases":
+                conn.execute("UPDATE releases SET updated_at = COALESCE(shipped_date, baseline_at, ?)", (stamp,))
+            elif table == "manifest_items":
+                conn.execute("UPDATE manifest_items SET updated_at = COALESCE(dialed_in_at, ?)", (stamp,))
+            else:
+                conn.execute("UPDATE %s SET updated_at = ?" % table, (stamp,))
+
+
 # The migration REGISTRY is the truth (GH-111). apply/rebuild stamp exactly the versions
 # present here — never a hard-coded range — so a deliberate gap (e.g. GH-111's 004 landing
 # before GH-108's 003) yields a ledger of {1,2,4} rather than a false claim to 3. Pending
 # migrations apply in ascending numeric order; gaps are safe only because migrations are
 # mutually INDEPENDENT, a standing constraint on every future entry.
 #
 # `txn_safe` marks a callback that may run inside perform_migration()'s single transaction:
 # it must never use executescript() or any other implicit-commit API. 001 is exempt because
 # it is reachable only on a fresh database (cmd_init) or a rebuild, never alongside other
 # pending versions on a live ledger.
 MIGRATIONS = {
     1: {"apply": lambda conn: conn.executescript(MIGRATION_001), "txn_safe": False},
     2: {"apply": lambda conn: _ensure_roadmap_schema(conn, stamp=False), "txn_safe": True},
     3: {"apply": _migration_003, "txn_safe": True},
     4: {"apply": _migration_004, "txn_safe": True},
     5: {"apply": _migration_005, "txn_safe": True},
     6: {"apply": _migration_006, "txn_safe": True},
+    7: {"apply": _migration_007, "txn_safe": True},
 }
 
 
 
 def registry_versions():
     """Ordered versions this codebase defines. The ledger never claims more than this."""
     return sorted(MIGRATIONS)
 
 
 def pending_versions(conn):
     try:
         applied = {r["version"] for r in conn.execute("SELECT version FROM schema_migrations")}
     except sqlite3.OperationalError:
         applied = set()   # fresh DB: the tracker table itself is created by migration 001
     return [v for v in registry_versions() if v not in applied]
 
 
 def apply_migrations(conn, stamp_ledger=True):
     """Apply pending registry migrations in ascending order.
 
@@ -950,129 +975,170 @@ def _emit(w, table, columns, rows):
         w("INSERT INTO %s(%s) VALUES(%s);" % (table, ", ".join(columns), values))
 
 
 def dump_text(conn, generation, include_receipts=True, include_generation=True):
     """Canonical logical dump. include_receipts=False, include_generation=False yields exactly
     the BUSINESS-STATE text the receipt digests hash (r3: excluding op_receipts, generation and
     digest fields keeps the digest computable and non-self-referential)."""
     out = []
 
     def w(s=""):
         out.append(s)
 
     w("-- releases-app canonical dump (GH-32 grammar: GID-keyed rows, natural keys elsewhere,")
     w("-- no integer PKs/FKs as values; rebuild renumbers deterministically)")
     if include_generation:
         w("-- generation: %d" % generation)
 
     _emit(w, "schema_migrations", ["version", "applied_at"],
           _rows(conn, "SELECT version, applied_at FROM schema_migrations ORDER BY version"))
 
-    settings_sql = "SELECT key, value FROM settings"
+    settings_cols = ["key", "value"]
+    settings_select = "SELECT key, value{extra} FROM settings"
+    if _has_column(conn, "settings", "updated_at"):
+        settings_cols.append("updated_at")
+        settings_extra = ", updated_at"
+    else:
+        settings_extra = ""
     if not include_generation:
-        settings_sql += " WHERE key != '%s'" % GENERATION_KEY
-    _emit(w, "settings", ["key", "value"], _rows(conn, settings_sql + " ORDER BY key"))
-
-    _emit(w, "repos", ["global_id", "slug"],
-          _rows(conn, "SELECT global_id, slug FROM repos ORDER BY id"))
-
-    _emit(w, "issue_refs", ["global_id", "url", "temp_id", "created_at"],
-          _rows(conn, "SELECT global_id, url, temp_id, created_at FROM issue_refs ORDER BY id"))
-
-    _emit(w, "marathons", ["global_id", "repo_gid", "tracking_ref_gid", "status", "created_at"],
+        settings_select += " WHERE key != '%s'" % GENERATION_KEY
+    _emit(w, "settings", settings_cols, _rows(conn, settings_select.format(extra=settings_extra) + " ORDER BY key"))
+
+    repo_cols = ["global_id", "slug"]
+    repo_extra = ""
+    if _has_column(conn, "repos", "updated_at"):
+        repo_cols.append("updated_at")
+        repo_extra = ", updated_at"
+    _emit(w, "repos", repo_cols,
+          _rows(conn, "SELECT global_id, slug%s FROM repos ORDER BY id" % repo_extra))
+
+    ref_cols = ["global_id", "url", "temp_id", "created_at"]
+    ref_extra = ""
+    if _has_column(conn, "issue_refs", "updated_at"):
+        ref_cols.append("updated_at")
+        ref_extra = ", updated_at"
+    _emit(w, "issue_refs", ref_cols,
+          _rows(conn, "SELECT global_id, url, temp_id, created_at%s FROM issue_refs ORDER BY id" % ref_extra))
+
+    mar_cols = ["global_id", "repo_gid", "tracking_ref_gid", "status", "created_at"]
+    mar_extra = ""
+    if _has_column(conn, "marathons", "updated_at"):
+        mar_cols.append("updated_at")
+        mar_extra = ", m.updated_at"
+    _emit(w, "marathons", mar_cols,
           _rows(conn, """SELECT m.global_id, r.global_id AS repo_gid, t.global_id AS tracking_ref_gid,
-                         m.status, m.created_at
+                         m.status, m.created_at%s
                          FROM marathons m JOIN repos r ON r.id = m.repo_id
-                         JOIN issue_refs t ON t.id = m.tracking_ref_id ORDER BY m.id"""))
+                         JOIN issue_refs t ON t.id = m.tracking_ref_id ORDER BY m.id""" % mar_extra))
 
     # GH-111 appends three baseline fields to the RELEASE record and three membership fields to
     # the MANIFEST ITEM record, both in fixed trailing order. They are emitted only when the
     # schema has them, so a pre-004 database still dumps (and digests) cleanly; on the way back
     # in, absent trailing fields read as NULL.
     rel_cols = ["global_id", "repo_gid", "version", "codename", "status", "target_date",
                 "shipped_date", "description", "exit_criterion", "tracking_ref_gid",
                 "marathon_gid", "gh_release_url", "milestone", "front_door_reviewed",
                 "shakedown_reviewed", "license_file"]
     rel_select = """SELECT rel.global_id, r.global_id AS repo_gid, rel.version, rel.codename,
                     rel.status, rel.target_date, rel.shipped_date, rel.description,
                     rel.exit_criterion, t.global_id AS tracking_ref_gid,
                     mar.global_id AS marathon_gid, rel.gh_release_url, rel.milestone,
                     rel.front_door_reviewed, rel.shakedown_reviewed, rel.license_file{extra}
                     FROM releases rel JOIN repos r ON r.id = rel.repo_id
                     JOIN issue_refs t ON t.id = rel.tracking_ref_id
                     LEFT JOIN marathons mar ON mar.id = rel.marathon_id ORDER BY rel.id"""
+    rel_extra = ""
     if _has_column(conn, "releases", "baseline_count"):
         rel_cols += ["baseline_count", "baseline_at", "baseline_source"]
-        rel_extra = ", rel.baseline_count, rel.baseline_at, rel.baseline_source"
-    else:
-        rel_extra = ""
+        rel_extra += ", rel.baseline_count, rel.baseline_at, rel.baseline_source"
+    if _has_column(conn, "releases", "updated_at"):
+        rel_cols.append("updated_at")
+        rel_extra += ", rel.updated_at"
     _emit(w, "releases", rel_cols, _rows(conn, rel_select.format(extra=rel_extra)))
 
     mfi_cols = ["global_id", "release_gid", "issue_ref_gid", "state"]
     mfi_select = """SELECT mi.global_id, rel.global_id AS release_gid,
                     t.global_id AS issue_ref_gid, mi.state{extra}
                     FROM manifest_items mi JOIN releases rel ON rel.id = mi.release_id
                     JOIN issue_refs t ON t.id = mi.issue_ref_id{join} ORDER BY mi.id"""
+    mfi_extra, mfi_join = "", ""
     if _has_column(conn, "manifest_items", "dialed_in_at"):
         # marathon_id is an integer FK, and integer FKs never appear as dump VALUES — the row
         # carries its marathon's GID, exactly as the release record does.
         mfi_cols += ["dialed_in_at", "dial_reason", "marathon_gid"]
-        mfi_extra = ", mi.dialed_in_at, mi.dial_reason, mar.global_id AS marathon_gid"
+        mfi_extra += ", mi.dialed_in_at, mi.dial_reason, mar.global_id AS marathon_gid"
         mfi_join = " LEFT JOIN marathons mar ON mar.id = mi.marathon_id"
-    else:
-        mfi_extra, mfi_join = "", ""
+    if _has_column(conn, "manifest_items", "updated_at"):
+        mfi_cols.append("updated_at")
+        mfi_extra += ", mi.updated_at"
     _emit(w, "manifest_items", mfi_cols,
           _rows(conn, mfi_select.format(extra=mfi_extra, join=mfi_join)))
 
     _emit(w, "manifest_state_events", ["item_gid", "from_state", "to_state", "at", "reason"],
           _rows(conn, """SELECT mi.global_id AS item_gid, e.from_state, e.to_state, e.at, e.reason
                          FROM manifest_state_events e JOIN manifest_items mi ON mi.id = e.item_id
                          ORDER BY e.id"""))
 
-    _emit(w, "doc_lines", ["repo_gid", "position", "content"],
-          _rows(conn, """SELECT r.global_id AS repo_gid, d.position, d.content
+    doc_cols = ["repo_gid", "position", "content"]
+    doc_extra = ""
+    if _has_column(conn, "doc_lines", "updated_at"):
+        doc_cols.append("updated_at")
+        doc_extra = ", d.updated_at"
+    _emit(w, "doc_lines", doc_cols,
+          _rows(conn, """SELECT r.global_id AS repo_gid, d.position, d.content%s
                          FROM doc_lines d JOIN repos r ON r.id = d.repo_id
-                         ORDER BY d.repo_id, d.position"""))
-
-    _emit(w, "legacy_lines", ["release_gid", "position", "content"],
-          _rows(conn, """SELECT rel.global_id AS release_gid, l.position, l.content
+                         ORDER BY d.repo_id, d.position""" % doc_extra))
+
+    leg_cols = ["release_gid", "position", "content"]
+    leg_extra = ""
+    if _has_column(conn, "legacy_lines", "updated_at"):
+        leg_cols.append("updated_at")
+        leg_extra = ", l.updated_at"
+    _emit(w, "legacy_lines", leg_cols,
+          _rows(conn, """SELECT rel.global_id AS release_gid, l.position, l.content%s
                          FROM legacy_lines l JOIN releases rel ON rel.id = l.release_id
-                         ORDER BY l.release_id, l.position"""))
+                         ORDER BY l.release_id, l.position""" % leg_extra))
 
+    gf_extra = ""
+    if _has_column(conn, "grandfather_entries", "updated_at"):
+        gf_extra = ", g.updated_at"
     gf_rows = _rows(conn, """SELECT g.import_run, COALESCE(g.release_gid, '(document)') AS rgid,
-                             g.rule, g.source_value, g.supplied_value, g.disposition, g.id AS _id
+                             g.rule, g.source_value, g.supplied_value, g.disposition, g.id AS _id%s
                              FROM grandfather_entries g
-                             ORDER BY g.import_run, COALESCE(g.release_gid, ''), g.rule, g.id""")
+                             ORDER BY g.import_run, COALESCE(g.release_gid, ''), g.rule, g.id""" % gf_extra)
     if gf_rows:
         w("-- table: grandfather_entries (natural key per PRD grammar: import_run + "
           "release_gid-or-(document) + rule + source ordinal)")
         ordinal = {}
         for row in gf_rows:
             key = (row["import_run"], row["rgid"], row["rule"])
             ordinal[key] = ordinal.get(key, 0) + 1
-            values = ", ".join(_sql_str(row[c]) for c in
-                               ("import_run", "rgid", "rule", "source_value",
-                                "supplied_value", "disposition"))
+            cols = ["import_run", "rgid", "rule", "source_value", "supplied_value", "disposition"]
+            if _has_column(conn, "grandfather_entries", "updated_at"):
+                cols.append("updated_at")
+            values = ", ".join(_sql_str(row.get(c)) for c in cols)
             w("-- gf-key: %s/%s/%s/%d" % (row["import_run"], row["rgid"], row["rule"],
                                            ordinal[key]))
-            w("INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value, "
-              "supplied_value, disposition) VALUES(%s);" % values)
+            ins_cols = ["import_run", "release_gid", "rule", "source_value", "supplied_value", "disposition"]
+            if _has_column(conn, "grandfather_entries", "updated_at"):
+                ins_cols.append("updated_at")
+            w("INSERT INTO grandfather_entries(%s) VALUES(%s);" % (", ".join(ins_cols), values))
 
     if _table_exists(conn, "roadmap_items"):
         # GH-108's five rating columns are appended in fixed trailing order, emitted only when the
         # schema has them (same absent-reads-as-NULL rule as the GH-111 fields above). `calc` is
         # NEVER dumped: it is derived at read time from the four axes, and storing a derived value
         # invites the drift class this grammar exists to prevent.
         rmi_cols = ["global_id", "repo_gid", "gh_number", "title", "section", "position",
                     "status_marker", "complexity", "risk", "effort", "doc_path", "issue_url",
                     "raw_text", "first_seen", "updated_at"]
         rmi_select = """SELECT ri.global_id, r.global_id AS repo_gid, ri.gh_number, ri.title,
                         ri.section, ri.position, ri.status_marker, ri.complexity, ri.risk,
                         ri.effort, ri.doc_path, ri.issue_url, ri.raw_text, ri.first_seen,
                         ri.updated_at{extra}
                         FROM roadmap_items ri JOIN repos r ON r.id = ri.repo_id
                         ORDER BY ri.id"""
         if _has_column(conn, "roadmap_items", "rating_pri"):
             rmi_cols += list(RATING_COLUMNS)
             rmi_extra = "".join(", ri.%s" % c for c in RATING_COLUMNS)
         else:
             rmi_extra = ""
@@ -1226,50 +1292,58 @@ def perform_write(root, conn, op, target_gid, mutate):
         }
         _atomic_write(lock.journal_path, json.dumps(journal, indent=2) + "\n")
 
         digest_before = business_digest(conn)
         conn.execute("BEGIN IMMEDIATE")
         try:
             mutate(conn)
         except BaseException:
             # a refused/mutating error never leaves a live journal behind: the DB rolled back,
             # so there is nothing to recover — clear the journal and re-raise. (An injected
             # crash uses os._exit and deliberately does NOT pass through here.)
             try:
                 conn.rollback()
             except sqlite3.Error:
                 pass
             try:
                 os.unlink(lock.journal_path)
             except OSError:
                 pass
             raise
-        cur = conn.execute("UPDATE settings SET value = ? WHERE key = ?",
-                           (str(generation), GENERATION_KEY))
-        if cur.rowcount == 0:
-            conn.execute("INSERT INTO settings(key, value) VALUES (?, ?)",
-                         (GENERATION_KEY, str(generation)))
+        now = now_iso()
+        if _has_column(conn, "settings", "updated_at"):
+            cur = conn.execute("UPDATE settings SET value = ?, updated_at = ? WHERE key = ?",
+                               (str(generation), now, GENERATION_KEY))
+            if cur.rowcount == 0:
+                conn.execute("INSERT INTO settings(key, value, updated_at) VALUES (?, ?, ?)",
+                             (GENERATION_KEY, str(generation), now))
+        else:
+            cur = conn.execute("UPDATE settings SET value = ? WHERE key = ?",
+                               (str(generation), GENERATION_KEY))
+            if cur.rowcount == 0:
+                conn.execute("INSERT INTO settings(key, value) VALUES (?, ?)",
+                             (GENERATION_KEY, str(generation)))
         digest_after = business_digest(conn)
         conn.execute("""INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id,
                          state_digest_before, state_digest_after)
                          VALUES (?, ?, ?, ?, ?, ?, ?)""",
-                     (op, target_gid, now_iso(), txn_id, session_id(),
+                     (op, target_gid, now, txn_id, session_id(),
                       digest_before, digest_after))
         _crash("pre-commit")
         conn.commit()
         _crash("post-commit")
 
         staged = [(_stage_write(paths["dump"], dump_text(conn, generation)), paths["dump"])]
         if os.path.exists(paths["gen"]):
             staged.append((_stage_write(paths["gen"],
                                         gen_marker(generation) + "\n" + render_ledger(conn)),
                            paths["gen"]))
         _crash("post-stage")
 
         for i, (tmp, final) in enumerate(staged):
             os.replace(tmp, final)
             if i == 0 and len(staged) > 1:
                 _crash("mid-rename")
         _crash("post-rename")
 
         os.unlink(lock.journal_path)
         refresh_preview(root)  # GH-106: adoption-gated, best-effort — after full durability
@@ -1332,45 +1406,53 @@ def perform_migration(root, conn):
         if os.path.exists(paths["gen"]):
             planned.append(paths["gen"])
         journal = {
             "app": APP, "txn_id": txn_id, "session_id": session_id(), "op": "migrate",
             "generation": generation, "planned_outputs": planned, "db": paths["db"],
             "started_at": now_iso(), "pending_migrations": pending,
         }
         _atomic_write(lock.journal_path, json.dumps(journal, indent=2) + "\n")
 
         digest_before = business_digest(conn)
         conn.execute("PRAGMA foreign_keys = OFF")
         try:
             conn.execute("BEGIN IMMEDIATE")
             apply_migrations(conn)
             violations = conn.execute("PRAGMA foreign_key_check").fetchall()
             if violations:
                 refuse("migration-fk-violation",
                        "the migrated schema has %d foreign-key violation(s) (first: %s); the "
                        "migration is rolled back and the ledger is untouched"
                        % (len(violations), tuple(violations[0])))
-            cur = conn.execute("UPDATE settings SET value = ? WHERE key = ?",
-                               (str(generation), GENERATION_KEY))
-            if cur.rowcount == 0:
-                conn.execute("INSERT INTO settings(key, value) VALUES (?, ?)",
-                             (GENERATION_KEY, str(generation)))
+            now = now_iso()
+            if _has_column(conn, "settings", "updated_at"):
+                cur = conn.execute("UPDATE settings SET value = ?, updated_at = ? WHERE key = ?",
+                                   (str(generation), now, GENERATION_KEY))
+                if cur.rowcount == 0:
+                    conn.execute("INSERT INTO settings(key, value, updated_at) VALUES (?, ?, ?)",
+                                 (GENERATION_KEY, str(generation), now))
+            else:
+                cur = conn.execute("UPDATE settings SET value = ? WHERE key = ?",
+                                   (str(generation), GENERATION_KEY))
+                if cur.rowcount == 0:
+                    conn.execute("INSERT INTO settings(key, value) VALUES (?, ?)",
+                                 (GENERATION_KEY, str(generation)))
             digest_after = business_digest(conn)
             conn.execute("""INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id,
                              state_digest_before, state_digest_after)
                              VALUES ('migrate', ?, ?, ?, ?, ?, ?)""",
                          ("migrations: %s" % ",".join(str(v) for v in pending), now_iso(),
                           txn_id, session_id(), digest_before, digest_after))
             _crash("pre-commit")
             conn.commit()
         except BaseException:
             try:
                 conn.rollback()
             except sqlite3.Error:
                 pass
             conn.execute("PRAGMA foreign_keys = ON")
             raise      # journal deliberately left in place
         conn.execute("PRAGMA foreign_keys = ON")
         _crash("post-commit")
 
         staged = [(_stage_write(paths["dump"], dump_text(conn, generation)), paths["dump"])]
         if os.path.exists(paths["gen"]):
@@ -1676,44 +1758,51 @@ def check_tracking_token(token, allow_mig=False):
     if MIG_RE.match(token):
         if allow_mig:
             return ("temp", token)
         refuse("mig-import-only",
                "MIG-XXXXXX placeholders are import-only (migration debt, distinct from the "
                "GitHub-down TMP- fallback); disposition them via `releases reconcile`")
     refuse("issue-url-shape",
            "tracking reference %r must be https://github.com/<org>/<repo>/issues/<n> or "
            "TMP-XXXXXX" % token)
 
 
 def issue_ref_for_token(conn, token, allow_mig=False):
     """Find or create the issue_refs row for a URL/TMP-/MIG- token (identity is the row, so
     re-adding an existing URL reuses it)."""
     kind, value = check_tracking_token(token, allow_mig=allow_mig)
     col, other = ("url", "temp_id") if kind == "url" else ("temp_id", "url")
     row = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % col, (value,)).fetchone()
     if row:
         return row
     gid = new_gid("ref-")
-    conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at) "
-                 "VALUES (?, ?, ?, ?)",
-                 (gid, value if kind == "url" else None,
-                  value if kind == "temp" else None, now_iso()))
+    now = now_iso()
+    if _has_column(conn, "issue_refs", "updated_at"):
+        conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at, updated_at) "
+                     "VALUES (?, ?, ?, ?, ?)",
+                     (gid, value if kind == "url" else None,
+                      value if kind == "temp" else None, now, now))
+    else:
+        conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at) "
+                     "VALUES (?, ?, ?, ?)",
+                     (gid, value if kind == "url" else None,
+                      value if kind == "temp" else None, now))
     return conn.execute("SELECT * FROM issue_refs WHERE global_id = ?", (gid,)).fetchone()
 
 
 def _github_slug_from_origin(root):
     """Best-effort '<org>/<repo>' from a github.com origin remote; None when unresolved."""
     try:
         out = subprocess.check_output(["git", "-C", root, "remote", "get-url", "origin"],
                                       stderr=subprocess.DEVNULL).decode().strip()
     except Exception:
         return None
     m = re.search(r"github\.com[/:]([\w.\-]+/[\w.\-]+?)(?:\.git)?$", out)
     return m.group(1) if m else None
 
 
 def tracking_token_to_url(conn, root, token):
     """GH-222: canonicalize `releases update --tracking-issue <N|URL>` to a real issue URL.
     A bare issue number expands against the tracked repo slug (when org/repo shaped) or the
     github.com origin remote; a full URL passes the shared shape check. Placeholders are
     refused: a re-point supersedes a real issue with a real issue (the TMP-/MIG- lifecycle
     belongs to `add` and `reconcile --map`). GitHub issue state is never consulted — the
@@ -1784,82 +1873,102 @@ def find_release(conn, gid):
 
 
 def _qa(value):
     return value if value in ("Yes", "No") else None
 
 
 # ── commands ────────────────────────────────────────────────────────────────────────────────────
 
 def cmd_init(args):
     root = resolve_root(args.root)
     paths = artifact_paths(root)
     if os.path.exists(paths["db"]):
         refuse("already-initialized", "%s already exists here" % DB_NAME)
     slug = args.slug or os.path.basename(os.path.normpath(root))
     lock = WriterLock(root)
     lock.acquire()
     try:
         conn = connect(paths["db"], must_exist=False)
         try:
             apply_migrations(conn)
-            conn.execute("INSERT INTO repos(global_id, slug) VALUES (?, ?)",
-                         (new_gid("repo-"), slug))
-            conn.execute("INSERT INTO settings(key, value) VALUES ('enforcement', 'lenient')")
-            conn.execute("INSERT INTO settings(key, value) VALUES ('repo_slug', ?)", (slug,))
-            conn.execute("INSERT INTO settings(key, value) VALUES (?, '1')", (GENERATION_KEY,))
+            now = now_iso()
+            if _has_column(conn, "repos", "updated_at"):
+                conn.execute("INSERT INTO repos(global_id, slug, updated_at) VALUES (?, ?, ?)",
+                             (new_gid("repo-"), slug, now))
+            else:
+                conn.execute("INSERT INTO repos(global_id, slug) VALUES (?, ?)",
+                             (new_gid("repo-"), slug))
+            if _has_column(conn, "settings", "updated_at"):
+                conn.execute("INSERT INTO settings(key, value, updated_at) VALUES ('enforcement', 'lenient', ?)", (now,))
+                conn.execute("INSERT INTO settings(key, value, updated_at) VALUES ('repo_slug', ?, ?)", (slug, now))
+                conn.execute("INSERT INTO settings(key, value, updated_at) VALUES (?, '1', ?)", (GENERATION_KEY, now))
+            else:
+                conn.execute("INSERT INTO settings(key, value) VALUES ('enforcement', 'lenient')")
+                conn.execute("INSERT INTO settings(key, value) VALUES ('repo_slug', ?)", (slug,))
+                conn.execute("INSERT INTO settings(key, value) VALUES (?, '1')", (GENERATION_KEY,))
             generation = get_generation(conn)
             _atomic_write(paths["dump"], dump_text(conn, generation))
         finally:
             conn.close()
     finally:
         lock.release()
     print("initialized %s (slug %r, enforcement=lenient, generation 1); canonical dump at %s"
           % (paths["db"], slug, paths["dump"]))
 
 
 def _grandfather(conn, import_run, release_gid, rule, source_value, supplied_value):
-    conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value,
-                     supplied_value, disposition) VALUES (?, ?, ?, ?, ?, NULL)""",
-                 (import_run, release_gid, rule, source_value, supplied_value))
+    if _has_column(conn, "grandfather_entries", "updated_at"):
+        conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value,
+                         supplied_value, disposition, updated_at) VALUES (?, ?, ?, ?, ?, NULL, ?)""",
+                     (import_run, release_gid, rule, source_value, supplied_value, now_iso()))
+    else:
+        conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value,
+                         supplied_value, disposition) VALUES (?, ?, ?, ?, ?, NULL)""",
+                     (import_run, release_gid, rule, source_value, supplied_value))
 
 
 def cmd_import(args):
     root = resolve_root(args.root)
     paths = artifact_paths(root)
     conn = connect(paths["db"])
     try:
         if conn.execute("SELECT COUNT(*) c FROM releases").fetchone()["c"]:
             refuse("import-once",
                    "this DB already holds releases; the legacy import is ONE-SHOT (PRD Phase 0) "
                    "— diverge via the dump merge procedure, not re-import")
         ledger = args.file or paths["ledger"]
         if not os.path.exists(ledger):
             refuse("import-source-missing", "no ledger file at %s" % ledger)
         doc_lines, blocks = parse_legacy_ledger(ledger)
         repo = conn.execute("SELECT * FROM repos ORDER BY id LIMIT 1").fetchone()
         import_run = "imp-%s-%s" % (_dt.datetime.now(_dt.timezone.utc).strftime("%Y%m%dT%H%M%S"),
                                     uuid.uuid4().hex[:6])
 
         def mutate(conn):
+            now = now_iso()
             for pos, content in enumerate(doc_lines):
-                conn.execute("INSERT INTO doc_lines(repo_id, position, content) VALUES (?, ?, ?)",
-                             (repo["id"], pos, content))
+                if _has_column(conn, "doc_lines", "updated_at"):
+                    conn.execute("INSERT INTO doc_lines(repo_id, position, content, updated_at) VALUES (?, ?, ?, ?)",
+                                 (repo["id"], pos, content, now))
+                else:
+                    conn.execute("INSERT INTO doc_lines(repo_id, position, content) VALUES (?, ?, ?)",
+                                 (repo["id"], pos, content))
             for block in blocks:
                 f = block["fields"]
 
                 def fv(label):
                     vals = f.get(label, [])
                     return vals[-1] if vals else None
 
                 version = (fv("Release") or "").strip()
                 if not version:
                     refuse("release-value", "a block's Release: value is empty (malformed ledger)")
                 gid = new_gid("rel-")
 
                 status_raw = fv("Status")
                 if not status_raw:
                     status = "draft"
                     _grandfather(conn, import_run, gid, "status-default", None, "draft")
                 else:
                     status, normalized = _normalize_status(status_raw)
                     if normalized:
                         _grandfather(conn, import_run, gid, "status-enum", status_raw, status)
@@ -1923,153 +2032,181 @@ def cmd_import(args):
                 else:
                     # SOP 1 postdates every legacy block: import — and ONLY import — may create
                     # MIG-XXXXXX placeholders, each recorded here (r2 review finding).
                     mig = "MIG-" + uuid.uuid4().hex[:6].upper()
                     ref = issue_ref_for_token(conn, mig, allow_mig=True)
                     _grandfather(conn, import_run, gid, "tracking-issue-missing", tracking_raw,
                                  mig)
 
                 codename = fv("Codename")
                 exit_criterion = fv("Exit criterion")
                 milestone = fv("Milestone")
 
                 # GH-28 thresholds on legacy rows are grandfathered (tolerated + tracked), not
                 # warned-and-written: the debt IS the record.
                 if sentence_count(description) > 4:
                     _grandfather(conn, import_run, gid, "description-length",
                                  description[:80] + ("..." if len(description) > 80 else ""), None)
                 if exit_criterion and len(exit_criterion) > 1000:
                     _grandfather(conn, import_run, gid, "exit-criterion-length",
                                  "%d chars" % len(exit_criterion), None)
-                if conn.execute("SELECT 1 FROM releases WHERE version = ?", (version,)).fetchone():
-                    refuse("version-uniqueness",
-                           "duplicate Release: %r in the legacy ledger (structural)" % version)
-
-                conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
-                             target_date, shipped_date, description, exit_criterion,
-                             tracking_ref_id, marathon_id, gh_release_url, milestone,
-                             front_door_reviewed, shakedown_reviewed, license_file)
-                             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?)""",
-                             (gid, repo["id"], version, codename, status, target_date,
-                              shipped_date, description, exit_criterion, ref["id"],
-                              gh_release_url, milestone, qa.get("front_door_reviewed"),
-                              qa.get("shakedown_reviewed"), qa.get("license_file")))
+                if _has_column(conn, "releases", "updated_at"):
+                    conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
+                                 target_date, shipped_date, description, exit_criterion,
+                                 tracking_ref_id, marathon_id, gh_release_url, milestone,
+                                 front_door_reviewed, shakedown_reviewed, license_file, updated_at)
+                                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?, ?)""",
+                                 (gid, repo["id"], version, codename, status, target_date,
+                                  shipped_date, description, exit_criterion, ref["id"],
+                                  gh_release_url, milestone, qa.get("front_door_reviewed"),
+                                  qa.get("shakedown_reviewed"), qa.get("license_file"), now))
+                else:
+                    conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
+                                 target_date, shipped_date, description, exit_criterion,
+                                 tracking_ref_id, marathon_id, gh_release_url, milestone,
+                                 front_door_reviewed, shakedown_reviewed, license_file)
+                                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?)""",
+                                 (gid, repo["id"], version, codename, status, target_date,
+                                  shipped_date, description, exit_criterion, ref["id"],
+                                  gh_release_url, milestone, qa.get("front_door_reviewed"),
+                                  qa.get("shakedown_reviewed"), qa.get("license_file")))
                 rel_id = conn.execute("SELECT id FROM releases WHERE global_id = ?",
                                       (gid,)).fetchone()["id"]
                 for ln, text in sorted(block["extras"], key=lambda e: e[0]):
-                    conn.execute("""INSERT INTO legacy_lines(release_id, position, content,
-                                 disposition) VALUES (?, ?, ?, NULL)""", (rel_id, ln, text))
+                    if _has_column(conn, "legacy_lines", "updated_at"):
+                        conn.execute("""INSERT INTO legacy_lines(release_id, position, content,
+                                     disposition, updated_at) VALUES (?, ?, ?, NULL, ?)""",
+                                     (rel_id, ln, text, now))
+                    else:
+                        conn.execute("""INSERT INTO legacy_lines(release_id, position, content,
+                                     disposition) VALUES (?, ?, ?, NULL)""", (rel_id, ln, text))
 
         txn = perform_write(root, conn, "import", None, mutate)
         gf = conn.execute("SELECT COUNT(*) c FROM grandfather_entries").fetchone()["c"]
         ll = conn.execute("SELECT COUNT(*) c FROM legacy_lines").fetchone()["c"]
         dl = conn.execute("SELECT COUNT(*) c FROM doc_lines").fetchone()["c"]
         print("imported %d block(s) from %s (txn %s): %d doc_lines, %d legacy_lines, "
               "%d grandfather_entries pending disposition"
               % (len(blocks), ledger, txn[:12], dl, ll, gf))
     finally:
         conn.close()
 
 
 def cmd_add(args):
     root = resolve_root(args.root)
     paths = artifact_paths(root)
     conn = connect(paths["db"])
     try:
         mode = enforcement_mode(conn)
         validate_release_fields(conn, mode, version=args.version, status=args.status,
                                 target_date=args.target_date, shipped_date=args.shipped_date,
                                 description=args.description, exit_criterion=args.exit_criterion)
         gid = new_gid("rel-")
 
         def mutate(conn):
             ref = issue_ref_for_token(conn, args.tracking_issue)
             marathon_id = None
             if args.marathon:
                 row = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
                                    (args.marathon,)).fetchone()
                 if not row:
                     refuse("unknown-gid", "no marathon with global id %r" % args.marathon)
                 marathon_id = row["id"]
-            conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
-                         target_date, shipped_date, description, exit_criterion, tracking_ref_id,
-                         marathon_id, gh_release_url, milestone, front_door_reviewed,
-                         shakedown_reviewed, license_file)
-                         VALUES (?, (SELECT id FROM repos ORDER BY id LIMIT 1), ?, ?, ?, ?, ?, ?, ?,
-                                 ?, ?, ?, ?, ?, ?, ?)""",
-                         (gid, args.version, args.codename, args.status, args.target_date,
-                          args.shipped_date, args.description, args.exit_criterion, ref["id"],
-                          marathon_id, args.gh_release_url, args.milestone,
-                          _qa(args.front_door), _qa(args.shakedown), _qa(args.license)))
+            if _has_column(conn, "releases", "updated_at"):
+                conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
+                             target_date, shipped_date, description, exit_criterion, tracking_ref_id,
+                             marathon_id, gh_release_url, milestone, front_door_reviewed,
+                             shakedown_reviewed, license_file, updated_at)
+                             VALUES (?, (SELECT id FROM repos ORDER BY id LIMIT 1), ?, ?, ?, ?, ?, ?, ?,
+                                     ?, ?, ?, ?, ?, ?, ?, ?)""",
+                             (gid, args.version, args.codename, args.status, args.target_date,
+                              args.shipped_date, args.description, args.exit_criterion, ref["id"],
+                              marathon_id, args.gh_release_url, args.milestone,
+                              _qa(args.front_door), _qa(args.shakedown), _qa(args.license), now_iso()))
+            else:
+                conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
+                             target_date, shipped_date, description, exit_criterion, tracking_ref_id,
+                             marathon_id, gh_release_url, milestone, front_door_reviewed,
+                             shakedown_reviewed, license_file)
+                             VALUES (?, (SELECT id FROM repos ORDER BY id LIMIT 1), ?, ?, ?, ?, ?, ?, ?,
+                                     ?, ?, ?, ?, ?, ?, ?)""",
+                             (gid, args.version, args.codename, args.status, args.target_date,
+                              args.shipped_date, args.description, args.exit_criterion, ref["id"],
+                              marathon_id, args.gh_release_url, args.milestone,
+                              _qa(args.front_door), _qa(args.shakedown), _qa(args.license)))
             print("added release %s (version %s, status %s)" % (gid, args.version, args.status))
 
         perform_write(root, conn, "add", gid, mutate)
     finally:
         conn.close()
 
 
 def cmd_update(args):
     root = resolve_root(args.root)
     paths = artifact_paths(root)
     conn = connect(paths["db"])
     try:
         row = find_release(conn, args.gid)
         mode = enforcement_mode(conn)
         # GH-222: `--tracking-issue <N|URL>` re-points the tracking ref (validated pre-write,
         # applied inside the perform_write transaction so the dump/receipt chain stays atomic).
         new_tracking_url = None
         if args.tracking_issue is not None:
             new_tracking_url = tracking_token_to_url(conn, root, args.tracking_issue)
         eff_version = args.version if args.version is not None else row["version"]
         validate_release_fields(conn, mode, version=eff_version,
                                 status=args.status, target_date=args.target_date,
                                 shipped_date=args.shipped_date, description=args.description,
                                 exit_criterion=args.exit_criterion, editing_gid=args.gid)
 
         def mutate(conn):
             tracking_ref_id = row["tracking_ref_id"]
             if new_tracking_url is not None:
                 ref = issue_ref_for_token(conn, new_tracking_url)
                 tracking_ref_id = ref["id"]
+            upd_clause = ""
+            extra_params = ()
+            if _has_column(conn, "releases", "updated_at"):
+                upd_clause = ", updated_at=?"
+                extra_params = (now_iso(),)
             conn.execute("""UPDATE releases SET version=?, codename=?, status=?, target_date=?,
                          shipped_date=?, description=?, exit_criterion=?, tracking_ref_id=?,
                          gh_release_url=?, milestone=?, front_door_reviewed=?, shakedown_reviewed=?,
-                         license_file=? WHERE global_id=?""",
+                         license_file=?""" + upd_clause + " WHERE global_id=?",
                          (eff_version,
                           args.codename if args.codename is not None else row["codename"],
                           args.status if args.status is not None else row["status"],
                           args.target_date if args.target_date is not None else row["target_date"],
                           args.shipped_date if args.shipped_date is not None else row["shipped_date"],
                           args.description if args.description is not None else row["description"],
                           args.exit_criterion if args.exit_criterion is not None
                           else row["exit_criterion"],
                           tracking_ref_id,
                           args.gh_release_url if args.gh_release_url is not None
                           else row["gh_release_url"],
                           args.milestone if args.milestone is not None else row["milestone"],
                           _qa(args.front_door) if args.front_door is not None
                           else row["front_door_reviewed"],
                           _qa(args.shakedown) if args.shakedown is not None
                           else row["shakedown_reviewed"],
                           _qa(args.license) if args.license is not None
-                          else row["license_file"],
-                          args.gid))
+                          else row["license_file"]) + extra_params + (args.gid,))
             # GH-111 baseline auto-capture, in the SAME writer-locked transaction as the status
             # flip — a dial-in landing between the two would pin a manifest state that never
             # existed. Only on draft -> active, only when nothing is captured yet: an
             # active -> draft -> active round trip is a SILENT no-op here (the explicit
             # `releases baseline` verb is the one that refuses), because a legitimate status
             # round trip must not fail while an accidental second capture stays impossible.
             new_status = args.status if args.status is not None else row["status"]
             if (row["status"] == "draft" and new_status == "active"
                     and _col(row, "baseline_count") is None
                     and _has_column(conn, "releases", "baseline_count")):
                 count = _capture_baseline(conn, row["id"], "observed")
                 if count:
                     print("baseline for %s captured at %d (observed)" % (args.gid, count))
             if new_tracking_url is not None:
                 print("re-pointed tracking issue -> %s (old ref row kept its identity)"
                       % new_tracking_url)
             print("updated release %s" % args.gid)
 
         perform_write(root, conn, "update", args.gid, mutate)
     finally:
@@ -2078,42 +2215,47 @@ def cmd_update(args):
 
 def _live_manifest_count(conn, release_id):
     """The commitment denominator: dialed-in plus shipped. Cut rows are history, not scope —
     counting them contradicts the repo's own prose that a cut REDUCES the manifest."""
     return conn.execute("""SELECT COUNT(*) FROM manifest_items
                             WHERE release_id = ? AND state IN ('dialed_in','shipped')""",
                         (release_id,)).fetchone()[0]
 
 
 def _capture_baseline(conn, release_id, source):
     """Write the kickoff snapshot. Returns the count, or 0 when the manifest is empty.
 
     An empty manifest yields NO baseline rather than a baseline of zero. Releases here are
     created as a row first and dialed in afterwards, so a naive snapshot-on-activate would give
     most releases a 0 and then report every real commitment as scope growth — the metric would
     lie in the common case. Baseline-less is the honest state, and `releases baseline` fills it
     in later."""
     count = _live_manifest_count(conn, release_id)
     if not count:
         return 0
-    conn.execute("""UPDATE releases SET baseline_count = ?, baseline_at = ?, baseline_source = ?
-                     WHERE id = ?""", (count, now_iso(), source, release_id))
+    now = now_iso()
+    if _has_column(conn, "releases", "updated_at"):
+        conn.execute("""UPDATE releases SET baseline_count = ?, baseline_at = ?, baseline_source = ?,
+                        updated_at = ? WHERE id = ?""", (count, now, source, now, release_id))
+    else:
+        conn.execute("""UPDATE releases SET baseline_count = ?, baseline_at = ?, baseline_source = ?
+                        WHERE id = ?""", (count, now, source, release_id))
     return count
 
 
 def cmd_baseline(args):
     """Capture a release's baseline explicitly — the path for a release that was activated with
     an empty manifest (`releases add --status active` has no draft->active transition to hook)."""
     root = resolve_root(args.root)
     conn = connect(artifact_paths(root)["db"])
     try:
         row = find_release(conn, args.gid)
         if not _has_column(conn, "releases", "baseline_count"):
             refuse("schema-behind",
                    "this ledger predates the baseline columns; run `releases migrate` first")
         if row["baseline_count"] is not None:
             refuse("baseline-already-set",
                    "release %s already has a baseline of %d (%s, taken %s). A baseline is "
                    "write-once: overwriting it would erase the very thing it measures."
                    % (args.gid, row["baseline_count"], row["baseline_source"], row["baseline_at"]))
         if not _live_manifest_count(conn, row["id"]):
             refuse("baseline-empty-manifest",
@@ -2133,42 +2275,47 @@ def cmd_baseline(args):
 def cmd_ship(args):
     root = resolve_root(args.root)
     paths = artifact_paths(root)
     conn = connect(paths["db"])
     try:
         row = find_release(conn, args.gid)
         evidence = (args.evidence or "").strip()
         if not evidence:
             refuse("ship-needs-evidence",
                    "shipping requires --evidence citing the exit-criterion run (structural, "
                    "both modes)")
         if row["status"] not in ("draft", "active"):
             refuse("transition",
                    "cannot ship a release in status %r (legal: draft|active -> shipped); "
                    "transition legality is CLI-enforced" % row["status"])
         when = args.date or now_iso()[:10]
         if not valid_date(when):
             refuse("date-shape", "--date %r must be a valid YYYY-MM-DD calendar date" % when)
 
         def mutate(conn):
-            conn.execute("UPDATE releases SET status='shipped', shipped_date=? WHERE global_id=?",
-                         (when, args.gid))
+            if _has_column(conn, "releases", "updated_at"):
+                conn.execute("""UPDATE releases SET status='shipped', shipped_date=?, updated_at=?
+                                WHERE global_id=?""",
+                             (when, now_iso(), args.gid))
+            else:
+                conn.execute("UPDATE releases SET status='shipped', shipped_date=? WHERE global_id=?",
+                             (when, args.gid))
             # The evidence citation rides in the append-only audit trail (the schema has no
             # evidence column by design): a ship-evidence receipt in the SAME transaction as the
             # status flip. check()'s chain rule skips op='ship-evidence' rows.
             conn.execute("""INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id,
                          state_digest_before, state_digest_after)
                          VALUES ('ship-evidence', ?, ?, ?, ?, '', '')""",
                          (args.gid, "evidence: %s" % evidence, new_txn_id(), session_id()))
             print("shipped %s on %s (evidence recorded in the op_receipts audit trail)"
                   % (args.gid, when))
 
         perform_write(root, conn, "ship", args.gid, mutate)
     finally:
         conn.close()
 
 
 def cmd_manifest_add(args):
     root = resolve_root(args.root)
     paths = artifact_paths(root)
     conn = connect(paths["db"])
     try:
@@ -2198,150 +2345,246 @@ def cmd_manifest_add(args):
                        "issue is already dialed into %s — a task belongs to ONE release at a time. "
                        "To hand it over: `manifest cut --gid %s <issue> --reason \"handed off\"` "
                        "then dial it in here."
                        % (", ".join("%s (%s)" % (h["global_id"], h["codename"] or "?")
                                     for h in held), held[0]["global_id"]))
             marathon_id = None
             if getattr(args, "marathon", None):
                 mar = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
                                    (args.marathon,)).fetchone()
                 if not mar:
                     refuse("unknown-marathon", "no marathon with gid %r" % args.marathon)
                 # The two marathon links are independent FKs, so nothing in the schema stops an item
                 # on release B carrying release A's marathon. That would let the viewer assert a
                 # membership the data never claimed (GH-109). CLI-enforced, since SQLite cannot
                 # express a cross-table CHECK.
                 if rel["marathon_id"] != mar["id"]:
                     refuse("marathon-not-this-release",
                            "marathon %s does not belong to release %s; an item's marathon must be "
                            "its own release's marathon" % (args.marathon, args.gid))
                 marathon_id = mar["id"]
-            conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state,
-                                                       dialed_in_at, dial_reason, marathon_id)
-                         VALUES (?, ?, ?, 'dialed_in', ?, ?, ?)""",
-                         (gid, rel["id"], ref["id"], now_iso(),
-                          getattr(args, "reason", None), marathon_id))
+            if _has_column(conn, "manifest_items", "updated_at"):
+                conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state,
+                                                           dialed_in_at, dial_reason, marathon_id, updated_at)
+                             VALUES (?, ?, ?, 'dialed_in', ?, ?, ?, ?)""",
+                             (gid, rel["id"], ref["id"], now_iso(),
+                              getattr(args, "reason", None), marathon_id, now_iso()))
+            else:
+                conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state,
+                                                           dialed_in_at, dial_reason, marathon_id)
+                             VALUES (?, ?, ?, 'dialed_in', ?, ?, ?)""",
+                             (gid, rel["id"], ref["id"], now_iso(),
+                              getattr(args, "reason", None), marathon_id))
             print("manifest item %s dialed into %s (state=dialed_in)" % (gid, args.gid))
 
         perform_write(root, conn, "manifest-add", gid, mutate)
     finally:
         conn.close()
 
 
 def cmd_manifest_ship(args):
     """GH-110/GH-111: move a dialed-in member to shipped.
 
     Before this verb, `shipped` was a state the schema allowed and no code path ever wrote, so a
     manifest member could never be marked done and mid-release progress was unreportable. The
     event table's `reason` is NOT NULL, so shipping carries `--evidence` for the same reason
     `releases ship` does: a claim that work landed should cite what landed.
     """
     root = resolve_root(args.root)
     paths = artifact_paths(root)
     conn = connect(paths["db"])
     try:
         rel = find_release(conn, args.gid)
         evidence = (args.evidence or "").strip()
         if not evidence:
             refuse("ship-needs-evidence",
                    "marking a manifest item shipped without evidence is refused (structural, "
                    "both modes) — cite the commit, PR, or test receipt")
         kind, value = check_tracking_token(args.issue)
 
         def mutate(conn):
             column = "url" if kind == "url" else "temp_id"
             ref = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % column,
                                (value,)).fetchone()
             if not ref:
                 refuse("unknown-issue", "no issue_refs row for %r" % value)
             item = _live_manifest_item(conn, rel, ref, value, args.gid, "shipped")
-            conn.execute("UPDATE manifest_items SET state='shipped' WHERE id=?", (item["id"],))
+            if _has_column(conn, "manifest_items", "updated_at"):
+                conn.execute("UPDATE manifest_items SET state='shipped', updated_at=? WHERE id=?",
+                             (now_iso(), item["id"]))
+            else:
+                conn.execute("UPDATE manifest_items SET state='shipped' WHERE id=?", (item["id"],))
             # State and event land in ONE transaction — the coupling the digest chain checks.
             conn.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at,
                          reason) VALUES (?, ?, 'shipped', ?, ?)""",
                          (item["id"], item["state"], now_iso(), evidence))
             print("manifest item %s shipped (%s -> shipped); evidence recorded"
                   % (item["global_id"], item["state"]))
 
         perform_write(root, conn, "manifest-ship", args.gid, mutate)
     finally:
         conn.close()
 
 
+def cmd_manifest_unship(args):
+    """GH-351: retract a shipped manifest item back to dialed_in.
+
+    Allows correcting a false `shipped` state (e.g. unmerged PR, wrong branch) without leaving
+    an incorrect permanent shipped row or creating contradictory duplicate rows via re-dial.
+    Appends an auditable retraction event to manifest_state_events.
+    """
+    root = resolve_root(args.root)
+    paths = artifact_paths(root)
+    conn = connect(paths["db"])
+    try:
+        rel = find_release(conn, args.gid)
+        reason = (args.reason or "").strip()
+        if not reason:
+            refuse("unship-needs-reason",
+                   "retracting a shipped manifest item without a reason is refused (structural, "
+                   "both modes)")
+        kind, value = check_tracking_token(args.issue)
+
+        def mutate(conn):
+            column = "url" if kind == "url" else "temp_id"
+            ref = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % column,
+                               (value,)).fetchone()
+            if not ref:
+                refuse("unknown-issue", "no issue_refs row for %r" % value)
+
+            item = conn.execute("""SELECT * FROM manifest_items
+                                   WHERE release_id=? AND issue_ref_id=? AND state='shipped'
+                                   ORDER BY id DESC LIMIT 1""",
+                                (rel["id"], ref["id"])).fetchone()
+            if not item:
+                prior = conn.execute("""SELECT state FROM manifest_items
+                                        WHERE release_id=? AND issue_ref_id=?
+                                        ORDER BY id DESC LIMIT 1""",
+                                     (rel["id"], ref["id"])).fetchone()
+                if prior:
+                    refuse("transition",
+                           "issue %r is in release %s at state %r, not shipped"
+                           % (value, args.gid, prior["state"]))
+                refuse("unknown-issue", "issue %r is not in release %s's manifest" % (value, args.gid))
+
+            # Check exclusivity: is the issue already dialed_in in this release or another?
+            existing_dialed_in = conn.execute("""SELECT 1 FROM manifest_items
+                                                 WHERE release_id=? AND issue_ref_id=? AND state='dialed_in'
+                                                   AND id != ?""",
+                                              (rel["id"], ref["id"], item["id"])).fetchone()
+            if existing_dialed_in:
+                refuse("manifest-duplicate",
+                       "issue is already dialed into this release as dialed_in; unship would create a duplicate live row")
+
+            held = conn.execute("""SELECT r.global_id, r.codename FROM manifest_items mi
+                                   JOIN releases r ON r.id = mi.release_id
+                                   WHERE mi.issue_ref_id = ? AND mi.release_id != ?
+                                     AND mi.state = 'dialed_in'""",
+                                (ref["id"], rel["id"])).fetchall()
+            if held:
+                refuse("dialed-in-elsewhere",
+                       "issue is already dialed into %s — a task belongs to ONE release at a time."
+                       % (", ".join("%s (%s)" % (h["global_id"], h["codename"] or "?") for h in held)))
+
+            if (item["state"], "dialed_in") not in LEGAL_ITEM_TRANSITIONS:
+                refuse("transition",
+                       "cannot move an item from %r to 'dialed_in' (legality is CLI-enforced)"
+                       % item["state"])
+
+            if _has_column(conn, "manifest_items", "updated_at"):
+                conn.execute("UPDATE manifest_items SET state='dialed_in', updated_at=? WHERE id=?",
+                             (now_iso(), item["id"]))
+            else:
+                conn.execute("UPDATE manifest_items SET state='dialed_in' WHERE id=?", (item["id"],))
+            conn.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at, reason)
+                            VALUES (?, 'shipped', 'dialed_in', ?, ?)""",
+                         (item["id"], now_iso(), reason))
+            print("manifest item %s un-shipped (shipped -> dialed_in); retraction event appended"
+                  % item["global_id"])
+
+        perform_write(root, conn, "manifest-unship", args.gid, mutate)
+    finally:
+        conn.close()
+
+
 def cmd_manifest_marathon(args):
     """Link an ALREADY dialed-in item to its release's marathon.
 
     Migration 004 leaves `marathon_id` NULL on every migrated row, deliberately: the only fact
     available at migration time is "this release has a marathon", and inferring membership from
     that is precisely the defect #109 names. So membership on pre-existing manifests is recorded
     the same way a baseline is — witnessed by an operator, one item at a time — rather than
     guessed by a migration and then indistinguishable from the real thing.
     """
     root = resolve_root(args.root)
     conn = connect(artifact_paths(root)["db"])
     try:
         rel = find_release(conn, args.gid)
         kind, value = check_tracking_token(args.issue)
 
         def mutate(conn):
             column = "url" if kind == "url" else "temp_id"
             ref = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % column,
                                (value,)).fetchone()
             if not ref:
                 refuse("unknown-issue", "no issue_refs row for %r" % value)
             item = conn.execute("""SELECT * FROM manifest_items
                                    WHERE release_id=? AND issue_ref_id=? AND state='dialed_in'""",
                                 (rel["id"], ref["id"])).fetchone()
             if not item:
                 refuse("unknown-issue",
                        "issue %r is not dialed into release %s" % (value, args.gid))
             mar = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
                                (args.marathon,)).fetchone()
             if not mar:
                 refuse("unknown-marathon", "no marathon with gid %r" % args.marathon)
             if rel["marathon_id"] != mar["id"]:
                 refuse("marathon-not-this-release",
                        "marathon %s does not belong to release %s; an item's marathon must be "
                        "its own release's marathon" % (args.marathon, args.gid))
             if item["marathon_id"] is not None and item["marathon_id"] != mar["id"]:
                 refuse("marathon-link-permanent",
                        "manifest item %s already belongs to another marathon; marathon links are "
                        "historical and permanent" % item["global_id"])
-            conn.execute("UPDATE manifest_items SET marathon_id=? WHERE id=?",
-                         (mar["id"], item["id"]))
+            if _has_column(conn, "manifest_items", "updated_at"):
+                conn.execute("UPDATE manifest_items SET marathon_id=?, updated_at=? WHERE id=?",
+                             (mar["id"], now_iso(), item["id"]))
+            else:
+                conn.execute("UPDATE manifest_items SET marathon_id=? WHERE id=?",
+                             (mar["id"], item["id"]))
             print("manifest item %s linked to marathon %s" % (item["global_id"], args.marathon))
 
         perform_write(root, conn, "manifest-marathon", args.gid, mutate)
     finally:
         conn.close()
 
 
 def _live_manifest_item(conn, rel, ref, token, gid_arg, target_state):
     """Select the ONE live (dialed_in) manifest row for this (release, issue), or refuse.
 
     GH-111: dropping UNIQUE(release_id, issue_ref_id) means a (release, issue) pair can now
     hold several rows — a cut row plus a later redial. The old lookup had no state predicate
     and was correct ONLY while that UNIQUE guaranteed a single row; left as-is it could pick
     the historical cut row and refuse "cut is terminal" while a live row sat beside it.
     """
     item = conn.execute("""SELECT * FROM manifest_items
-                           WHERE release_id=? AND issue_ref_id=? AND state='dialed_in'""",
+                            WHERE release_id=? AND issue_ref_id=? AND state='dialed_in'""",
                         (rel["id"], ref["id"])).fetchone()
     if item:
         if (item["state"], target_state) not in LEGAL_ITEM_TRANSITIONS:
             refuse("transition",
                    "cannot move an item from %r to %r (legality is CLI-enforced)"
                    % (item["state"], target_state))
         return item
     # No live row. Distinguish "never here" from "here, but already terminal" — the second is a
     # transition error, and saying so is how the operator learns the item's actual state.
     prior = conn.execute("""SELECT state FROM manifest_items
                             WHERE release_id=? AND issue_ref_id=?
                             ORDER BY id DESC LIMIT 1""",
                          (rel["id"], ref["id"])).fetchone()
     if prior:
         refuse("transition",
                "issue %r is in release %s at state %r, not dialed_in; %s and cut are terminal for "
                "that row (re-admitting is a new dial-in)" % (token, gid_arg, prior["state"],
                                                              prior["state"]))
     refuse("unknown-issue", "issue %r is not in release %s's manifest" % (token, gid_arg))
 
@@ -2350,67 +2593,76 @@ def cmd_manifest_cut(args):
     root = resolve_root(args.root)
     paths = artifact_paths(root)
     conn = connect(paths["db"])
     try:
         rel = find_release(conn, args.gid)
         reason = (args.reason or "").strip()
         if not reason:
             refuse("cut-needs-reason",
                    "a manifest cut without a reason is refused (structural, both modes)")
         kind, value = check_tracking_token(args.issue)
 
         def mutate(conn):
             if kind == "url":
                 ref = conn.execute("SELECT * FROM issue_refs WHERE url = ?", (value,)).fetchone()
             else:
                 ref = conn.execute("SELECT * FROM issue_refs WHERE temp_id = ?",
                                    (value,)).fetchone()
             if not ref:
                 refuse("unknown-issue", "no issue_refs row for %r" % value)
             item = _live_manifest_item(conn, rel, ref, value, args.gid, "cut")
-            conn.execute("UPDATE manifest_items SET state='cut' WHERE id=?", (item["id"],))
+            if _has_column(conn, "manifest_items", "updated_at"):
+                conn.execute("UPDATE manifest_items SET state='cut', updated_at=? WHERE id=?",
+                             (now_iso(), item["id"]))
+            else:
+                conn.execute("UPDATE manifest_items SET state='cut' WHERE id=?", (item["id"],))
             # item state and its event land in ONE transaction (PRD: the coupling is
             # CLI-enforced; a direct writer that skips the event is caught by the digest chain)
             conn.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at,
                          reason) VALUES (?, ?, 'cut', ?, ?)""",
                          (item["id"], item["state"], now_iso(), reason))
             print("manifest item %s cut (%s -> cut); re-scope event appended"
                   % (item["global_id"], item["state"]))
 
         perform_write(root, conn, "manifest-cut", args.gid, mutate)
     finally:
         conn.close()
 
 
 def cmd_marathon_add(args):
     root = resolve_root(args.root)
     paths = artifact_paths(root)
     conn = connect(paths["db"])
     try:
         gid = new_gid("mar-")
 
         def mutate(conn):
             ref = issue_ref_for_token(conn, args.tracking_issue)
             repo_id = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()["id"]
-            conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
-                         created_at) VALUES (?, ?, ?, ?, ?)""",
-                         (gid, repo_id, ref["id"], args.status, now_iso()))
+            if _has_column(conn, "marathons", "updated_at"):
+                conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
+                             created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)""",
+                             (gid, repo_id, ref["id"], args.status, now_iso(), now_iso()))
+            else:
+                conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
+                             created_at) VALUES (?, ?, ?, ?, ?)""",
+                             (gid, repo_id, ref["id"], args.status, now_iso()))
             print("marathon %s added (status %s)" % (gid, args.status))
 
         perform_write(root, conn, "marathon-add", gid, mutate)
     finally:
         conn.close()
 
 
 def cmd_marathon_list(args):
     root = resolve_root(args.root)
     conn = connect(artifact_paths(root)["db"])
     try:
         for row in conn.execute("""SELECT m.global_id, m.status, m.created_at, t.url, t.temp_id
                                    FROM marathons m JOIN issue_refs t ON t.id = m.tracking_ref_id
                                    ORDER BY m.id"""):
             print("%s  %-9s  %s  %s" % (row["global_id"], row["status"], row["created_at"],
                                         row["url"] or row["temp_id"]))
     finally:
         conn.close()
 
 
@@ -2554,40 +2806,43 @@ def cmd_show(args):
                                   GROUP BY rule""", (rel["global_id"],)).fetchall()
         if pending:
             print("Grandfathered: %s"
                   % ", ".join("%s x%d" % (g["rule"], g["n"]) for g in pending))
     finally:
         conn.close()
 
 
 def cmd_next(args):
     """The next release to work on: unshipped, earliest target date first. A release with no
     target date sorts last — undated is not urgent, it is unplanned."""
     root = resolve_root(args.root)
     conn = connect(artifact_paths(root)["db"])
     try:
         rows = conn.execute("""SELECT global_id, version, codename, status, target_date
                                FROM releases WHERE status IN ('draft', 'active')
                                ORDER BY target_date IS NULL, target_date, version""").fetchall()
         if not rows:
             print("no unshipped releases — the ledger has nothing queued")
             return
+        if all(r["target_date"] is None for r in rows):
+            print("warning: every candidate release is undated (unplanned); ordering degraded to version order",
+                  file=sys.stderr)
         head = rows[0]
         print("NEXT: %s %s (%s) target=%s gid=%s"
               % (head["version"] or "-", head["codename"] or "", head["status"],
                  head["target_date"] or "unplanned", head["global_id"]))
         for r in rows[1:]:
             print("then: %s %s (%s) target=%s"
                   % (r["version"] or "-", r["codename"] or "", r["status"],
                      r["target_date"] or "unplanned"))
         if args.verbose:
             print()
             cmd_show(argparse.Namespace(root=args.root, gid=head["global_id"], version=None,
                                         full=False))
     finally:
         conn.close()
 
 
 def _project_field_map(payload):
     fields = {field.get("name"): field for field in payload.get("fields", [])}
     missing = [name for name in PROJECT_FIELDS if not fields.get(name, {}).get("id")]
     if missing:
@@ -2695,46 +2950,53 @@ def cmd_project_sync(args):
         print("project sync: %d release card(s) %s"
               % (len(releases), "applied" if args.apply else "planned"))
     finally:
         conn.close()
 
 
 # ── GH-269: roadmap ledger (`releases roadmap sync` / `list`) ────────────────────────────────
 # Ledger contract: the database is the ONLY thing humans and
 # agents edit; this code only READS it and mirrors the ledger into roadmap_items. The parser is a
 # twin of the marathon planner's (utils/py/_marathon_plan.py) with one deliberate difference: the
 # planner recognises only its four SECTIONS and skips the rest silently, while the shadow captures
 # EVERY `###` section under `## Ledger` — the shadow's job is to mirror what the file says, not to
 # re-decide what the planner should see.
 
 ROADMAP_NAME = "ROADMAP.md"
 _ROADMAP_STATUS_MARKERS = ["\U0001F195", "\U0001F6A7", "\u2705", "\u23F8\uFE0F", "\U0001F7E1",
                            "\u2699\uFE0F", "\U0001F532", "\u26D4", "\U0001F52E", "\U0001F7E2",
                            "\U0001F534", "\U0001F41E"]
 
 
-# ── GH-108: the one canonical rating grammar ────────────────────────────────────────────────────
-# `rated N/N/N/N` — exactly four slash-separated integers 1-100, axis order fixed as
-# pri/sev/appeal/effort — optionally followed by ` ovr N` (an integer 4-400 on calc's own scale).
-# There is no labeled long form: the axis NAMES live in PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md,
-# not in the entry line. Higher is better on every axis, effort included (it scores CHEAPNESS), so
-# the four combine without sign-flipping.
+# ── GH-108 / GH-349: the one canonical rating grammar ──────────────────────────────────────────
+# `rated N/N/N/N` — exactly four slash-separated integers 1-100, axis order fixed as:
+#   1. Priority (`pri`): urgency and importance of the outcome (1-100, 100 = critical/must-have)
+#   2. Severity (`sev`): severity of the problem or defect if left unaddressed (1-100, 100 = blocker)
+#   3. Appeal (`appeal`): user, operator, or ecosystem attractiveness/value (1-100, 100 = beloved)
+#   4. Effort (`effort`): CHEAPNESS of implementation (1-100, 100 = trivial/cheap, 1 = massive/costly)
+# Followed optionally by ` ovr N` (an integer 4-400 on calc's own scale, overriding calc for ranking).
+# Higher is better on every axis, effort included (it scores cheapness), so the four combine
+# additively without sign-flipping.
+#
+# Canonicality: `rated` is the canonical rating vocabulary across all installs (vendored or central).
+# The legacy triple `cx/risk/eff` (complexity/risk/effort) is deprecated and cannot be combined
+# with `rated` on the same entry.
 #
 # The refusal contract matters as much as the grammar: the PRESENCE of a `rated` or `ovr` token
 # either parses as the full form or refuses with a named rule. A malformed shape must never read
 # as "unrated" — that would silently drop an operator's prioritisation and look like they never
 # scored the task.
 # The TOKEN test requires a digit after the word, so ordinary prose ("a highly rated entry",
 # "underrated") is not mistaken for a score — while a genuinely malformed `rated 70/40/55` still
 # counts as a token and is refused rather than read as unrated.
 _RATED_TOKEN_RE = re.compile(r"\brated\s+\d")
 # The DUPLICATE test is deliberately NARROWER than the presence test: it counts only
 # slash-bearing matches. "the rated 3rd priority item ... rated 90/90/90/90" is ONE rating
 # beside prose, and refusing it as a duplicate rejects a correctly-scored entry
 # (aider/qwen3.8-max QA r1, [Should] #1 — reproduced before fixing). The PRESENCE test stays
 # broad on purpose: a bare `rated 70` is a truncated score, and reading it as "unrated" would
 # be exactly the silent drop this contract exists to prevent. Prose shaped "rated <int> <word>"
 # with no real score beside it therefore still refuses — loudly, and fixable in one edit, which
 # is the trade this repo prefers over an invisible drop.
 _RATED_SCORE_TOKEN_RE = re.compile(r"\brated\s+\d+/")
 _RATED_RE = re.compile(r"\brated\s+(\d+)/(\d+)/(\d+)/(\d+)(?![\w/])")
 # `ovr` requires a DIGIT, not merely a following token. Unbackticked prose — "the ovr wins over
@@ -2790,76 +3052,84 @@ def parse_rating(raw, title):
         if not 1 <= value <= 100:
             refuse("rating-range", "%s scores %s at %d; every axis is 1-100 (100 = strongest, "
                                    "effort included — it scores cheapness)" % (where, axis, value))
     out = dict(zip(RATING_COLUMNS[:4], values))
     out["rating_ovr"] = None
     if ovr_tokens:
         mo = _OVR_RE.search(raw)
         if not mo:
             refuse("ovr-shape", "%s carries an `ovr` token with no integer after it; %s"
                    % (where, _RATING_GRAMMAR))
         ovr = int(mo.group(1))
         if not 4 <= ovr <= 400:
             refuse("ovr-range", "%s overrides to %d; the override is on calc's own 4-400 scale"
                    % (where, ovr))
         out["rating_ovr"] = ovr
     return out
 
 
 def parse_roadmap_ledger(path):
     """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
-    from its `- **` line to the next `- **`, `###`, or `##`."""
+    from its bullet line (`- **`, `- [`, `- `) to the next `- `, `###`, or `##`."""
     lines = open(path, encoding="utf-8").read().splitlines()
     entries = []
     sec = None
-    inledger = False
+    has_ledger_header = any(re.match(r"^##\s+Ledger\s*$", l.strip()) for l in lines)
+    inledger = not has_ledger_header
     pos = {}
     i, n = 0, len(lines)
     while i < n:
         line = lines[i]
-        if re.match(r"^##\s+Ledger\s*$", line.strip()):
+        if has_ledger_header and re.match(r"^##\s+Ledger\s*$", line.strip()):
             inledger = True
             i += 1
             continue
-        if inledger and re.match(r"^##\s+", line):
+        if has_ledger_header and inledger and re.match(r"^##\s+", line):
             break
         if inledger and line.startswith("### "):
             sec = line[4:].strip()
             i += 1
             continue
-        if inledger and sec and line.startswith("- **"):
+        if inledger and sec and (line.startswith("- **") or line.startswith("- [") or line.startswith("- ")):
             j = i + 1
-            while j < n and not (lines[j].startswith("- **") or lines[j].startswith("### ")
+            while j < n and not (lines[j].startswith("- ") or lines[j].startswith("### ")
                                  or re.match(r"^##\s+", lines[j])):
                 j += 1
             raw = "\n".join(lines[i:j]).rstrip()
-            m = re.match(r"^- \*\*(.+?)\*\*", raw)
-            title = m.group(1).strip() if m else raw[4:80]
-            gh = re.match(r"^GH-(\d+)\b", title)
+            m_bold = re.match(r"^- \*\*(.+?)\*\*", raw)
+            m_link = re.match(r"^- \[(.+?)\]", raw)
+            if m_bold:
+                title = m_bold.group(1).strip()
+            elif m_link:
+                title = m_link.group(1).strip()
+            else:
+                m_plain = re.match(r"^- (.+)", raw)
+                title = m_plain.group(1).strip() if m_plain else raw[2:80]
+            gh = re.match(r"^(?:GH-|#)(\d+)\b", title) or re.search(r"\b(?:GH-|#)(\d+)\b", title)
             marker = None
             for cand in _ROADMAP_STATUS_MARKERS:
                 if cand in raw:
                     marker = cand
                     break
             cre = re.search(r"cx/risk/eff (\d+)/(\d+)/(\d+)", raw)
-            doc = re.search(r"\]\((PROJECT/[^)]+\.md)", raw)
-            issue = re.search(r"https://github\.com/HiQS-(?:Suite|Labs)/XYZ-forge/(?:issues|pull)/\d+", raw)
+            doc = re.search(r"\]\((PROJECT/[^)]+\.md)", raw) or re.search(r"\((PROJECT/[^)]+\.md)\)", raw) or re.search(r"\]\(([^)]+\.md)\)", raw)
+            issue = re.search(r"https://github\.com/[^/\s]+/[^/\s]+/(?:issues|pull)/\d+", raw)
             pos[sec] = pos.get(sec, 0) + 1
             entry = {
                 "gh_number": int(gh.group(1)) if gh else None,
                 "title": title, "section": sec, "position": pos[sec],
                 "status_marker": marker,
                 "complexity": int(cre.group(1)) if cre else None,
                 "risk": int(cre.group(2)) if cre else None,
                 "effort": int(cre.group(3)) if cre else None,
                 "doc_path": doc.group(1) if doc else None,
                 "issue_url": issue.group(0) if issue else None,
                 "raw_text": raw,
             }
             entry.update(parse_rating(raw, title))
             entries.append(entry)
             i = j
             continue
         i += 1
     return entries
 
 
@@ -3163,40 +3433,47 @@ def cmd_roadmap_update(args):
 def cmd_roadmap_sync(args):
     root = resolve_root(args.root)
     # PR #240 review: sync mirrors ROADMAP.md and DELETES rows absent from it — in a releases-mode
     # repo the DB is canonical and rows arrive via `roadmap add` with no markdown source line, so
     # mirroring would destroy parked intake. Skip cleanly (exit 0): wave_reconcile.py calls sync
     # unconditionally post-merge and must stay green in both modes.
     try:
         with open(os.path.join(root, ".pdda-mode")) as f:
             if "ROADMAP_SOURCE=releases" in f.read():
                 print("roadmap sync: skipped — releases-mode repo (the DB is canonical; sync only "
                       "mirrors ROADMAP.md in legacy mode, and would delete rows parked by `roadmap add`)")
                 return
     except OSError:
         pass
     conn = connect(artifact_paths(root)["db"])
     try:
         md_path = os.path.join(root, ROADMAP_NAME)
         if not os.path.exists(md_path):
             refuse("roadmap-missing", "no %s at %s — nothing to shadow" % (ROADMAP_NAME, root))
         parsed = parse_roadmap_ledger(md_path)
+        if len(parsed) == 0:
+            with open(md_path, encoding="utf-8") as f:
+                content = f.read().strip()
+            if content:
+                refuse("roadmap-empty",
+                       "parsed 0 entries from non-empty %s; refusing sync to prevent accidental "
+                       "wipe of roadmap_items" % ROADMAP_NAME)
         # duplicate GH keys in the markdown would make the mirror ambiguous — name it, do not pick
         seen = {}
         for e in parsed:
             if e["gh_number"] is not None:
                 if e["gh_number"] in seen:
                     refuse("roadmap-duplicate-gh",
                            "GH-%d appears twice in %s (%r and %r). The mirror keys entries by GH "
                            "number; merge or renumber one of them, then re-run."
                            % (e["gh_number"], ROADMAP_NAME, seen[e["gh_number"]][:60],
                               e["title"][:60]))
                 seen[e["gh_number"]] = e["title"]
 
         repo = conn.execute("SELECT id, global_id FROM repos ORDER BY id LIMIT 1").fetchone()
         if repo is None:
             refuse("no-repo", "the DB has no repos row; run `releases init` first")
 
         # GH-108/GH-111: feature commands do NOT self-migrate. Rating storage arrives through
         # `releases migrate` (migration 003); sync refuses clearly when a rated entry meets a
         # ledger that cannot hold it, rather than installing schema of its own or — worse —
         # writing the entry with its scores silently dropped.
@@ -4139,118 +4416,187 @@ def validate_merged_dump(text, tables):
                        "conflict that no union can settle. Decide which row wins, delete the other, "
                        "then rebuild." % (table, gid))
             seen_gids.add(gid)
 
 
 def load_dump(conn, tables, skip_schema_migrations=False):
     """Insert parsed dump rows into the (already-migrated, empty) DB, resolving the grammar's
     natural keys to physical ids in dump order.
 
     skip_schema_migrations=True is the rebuild path (GH-111). The migration LEDGER is owned by
     exactly one writer there — `_rebuild`, which stamps the registry's versions after this
     returns — so loading the dump's own rows would either collide on the primary key or leave a
     v2 ledger describing a v4 schema. The dump's other tables load normally."""
     def _int_or_none(v):
         return None if v in (None, "") else int(v)
 
     if not skip_schema_migrations:
         for row in tables.get("schema_migrations", []):
             conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)",
                          (int(row["version"]), row["applied_at"]))
+    now = now_iso()
     for row in tables.get("settings", []):
-        conn.execute("INSERT INTO settings(key, value) VALUES (?, ?)", (row["key"], row["value"]))
+        if _has_column(conn, "settings", "updated_at"):
+            conn.execute("INSERT INTO settings(key, value, updated_at) VALUES (?, ?, ?)",
+                         (row["key"], row["value"], row.get("updated_at") or now))
+        else:
+            conn.execute("INSERT INTO settings(key, value) VALUES (?, ?)", (row["key"], row["value"]))
     repo_ids = {}
     for row in tables.get("repos", []):
-        cur = conn.execute("INSERT INTO repos(global_id, slug) VALUES (?, ?)",
-                           (row["global_id"], row["slug"]))
+        if _has_column(conn, "repos", "updated_at"):
+            cur = conn.execute("INSERT INTO repos(global_id, slug, updated_at) VALUES (?, ?, ?)",
+                               (row["global_id"], row["slug"], row.get("updated_at") or now))
+        else:
+            cur = conn.execute("INSERT INTO repos(global_id, slug) VALUES (?, ?)",
+                               (row["global_id"], row["slug"]))
         repo_ids[row["global_id"]] = cur.lastrowid
     ref_ids = {}
     for row in tables.get("issue_refs", []):
-        cur = conn.execute("""INSERT INTO issue_refs(global_id, url, temp_id, created_at)
-                              VALUES (?, ?, ?, ?)""",
-                           (row["global_id"], row.get("url"), row.get("temp_id"),
-                            row["created_at"]))
+        if _has_column(conn, "issue_refs", "updated_at"):
+            ref_updated = row.get("updated_at") or row.get("created_at") or now
+            cur = conn.execute("""INSERT INTO issue_refs(global_id, url, temp_id, created_at, updated_at)
+                                  VALUES (?, ?, ?, ?, ?)""",
+                               (row["global_id"], row.get("url"), row.get("temp_id"),
+                                row["created_at"], ref_updated))
+        else:
+            cur = conn.execute("""INSERT INTO issue_refs(global_id, url, temp_id, created_at)
+                                  VALUES (?, ?, ?, ?)""",
+                               (row["global_id"], row.get("url"), row.get("temp_id"),
+                                row["created_at"]))
         ref_ids[row["global_id"]] = cur.lastrowid
     mar_ids = {}
     for row in tables.get("marathons", []):
-        cur = conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
-                              created_at) VALUES (?, ?, ?, ?, ?)""",
-                           (row["global_id"], repo_ids[row["repo_gid"]],
-                            ref_ids[row["tracking_ref_gid"]], row["status"], row["created_at"]))
+        if _has_column(conn, "marathons", "updated_at"):
+            mar_updated = row.get("updated_at") or row.get("created_at") or now
+            cur = conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
+                                  created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)""",
+                               (row["global_id"], repo_ids[row["repo_gid"]],
+                                ref_ids[row["tracking_ref_gid"]], row["status"], row["created_at"],
+                                mar_updated))
+        else:
+            cur = conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
+                                  created_at) VALUES (?, ?, ?, ?, ?)""",
+                               (row["global_id"], repo_ids[row["repo_gid"]],
+                                ref_ids[row["tracking_ref_gid"]], row["status"], row["created_at"]))
         mar_ids[row["global_id"]] = cur.lastrowid
     rel_ids = {}
     for row in tables.get("releases", []):
-        cur = conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
-                              target_date, shipped_date, description, exit_criterion,
-                              tracking_ref_id, marathon_id, gh_release_url, milestone,
-                              front_door_reviewed, shakedown_reviewed, license_file,
-                              baseline_count, baseline_at, baseline_source)
-                              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
-                           (row["global_id"], repo_ids[row["repo_gid"]], row.get("version"),
-                            row.get("codename"), row["status"], row.get("target_date"),
-                            row.get("shipped_date"), row["description"], row.get("exit_criterion"),
-                            ref_ids[row["tracking_ref_gid"]],
-                            mar_ids.get(row["marathon_gid"]) if row.get("marathon_gid") else None,
-                            row.get("gh_release_url"), row.get("milestone"),
-                            row.get("front_door_reviewed"), row.get("shakedown_reviewed"),
-                            row.get("license_file"),
-                            # absent trailing fields read as NULL — a pre-004 dump is still loadable
-                            _int_or_none(row.get("baseline_count")), row.get("baseline_at"),
-                            row.get("baseline_source")))
+        if _has_column(conn, "releases", "updated_at"):
+            rel_updated = row.get("updated_at") or row.get("shipped_date") or row.get("baseline_at") or now
+            cur = conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
+                                  target_date, shipped_date, description, exit_criterion,
+                                  tracking_ref_id, marathon_id, gh_release_url, milestone,
+                                  front_door_reviewed, shakedown_reviewed, license_file,
+                                  baseline_count, baseline_at, baseline_source, updated_at)
+                                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
+                               (row["global_id"], repo_ids[row["repo_gid"]], row.get("version"),
+                                row.get("codename"), row["status"], row.get("target_date"),
+                                row.get("shipped_date"), row["description"], row.get("exit_criterion"),
+                                ref_ids[row["tracking_ref_gid"]],
+                                mar_ids.get(row["marathon_gid"]) if row.get("marathon_gid") else None,
+                                row.get("gh_release_url"), row.get("milestone"),
+                                row.get("front_door_reviewed"), row.get("shakedown_reviewed"),
+                                row.get("license_file"),
+                                _int_or_none(row.get("baseline_count")), row.get("baseline_at"),
+                                row.get("baseline_source"), rel_updated))
+        else:
+            cur = conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
+                                  target_date, shipped_date, description, exit_criterion,
+                                  tracking_ref_id, marathon_id, gh_release_url, milestone,
+                                  front_door_reviewed, shakedown_reviewed, license_file,
+                                  baseline_count, baseline_at, baseline_source)
+                                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
+                               (row["global_id"], repo_ids[row["repo_gid"]], row.get("version"),
+                                row.get("codename"), row["status"], row.get("target_date"),
+                                row.get("shipped_date"), row["description"], row.get("exit_criterion"),
+                                ref_ids[row["tracking_ref_gid"]],
+                                mar_ids.get(row["marathon_gid"]) if row.get("marathon_gid") else None,
+                                row.get("gh_release_url"), row.get("milestone"),
+                                row.get("front_door_reviewed"), row.get("shakedown_reviewed"),
+                                row.get("license_file"),
+                                _int_or_none(row.get("baseline_count")), row.get("baseline_at"),
+                                row.get("baseline_source")))
         rel_ids[row["global_id"]] = cur.lastrowid
     item_ids = {}
     for row in tables.get("manifest_items", []):
         # `open` is the pre-2026-08-20 name for `dialed_in`. Old dumps stay loadable — they are the
         # git-merge surface, and a colleague's branch may carry one for weeks — but only the new
         # vocabulary is ever emitted.
         state = "dialed_in" if row["state"] == "open" else row["state"]
-        cur = conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state,
-                              dialed_in_at, dial_reason, marathon_id)
-                              VALUES (?, ?, ?, ?, ?, ?, ?)""",
-                           (row["global_id"], rel_ids[row["release_gid"]],
-                            ref_ids[row["issue_ref_gid"]], state,
-                            row.get("dialed_in_at"), row.get("dial_reason"),
-                            mar_ids.get(row["marathon_gid"]) if row.get("marathon_gid") else None))
+        if _has_column(conn, "manifest_items", "updated_at"):
+            item_updated = row.get("updated_at") or row.get("dialed_in_at") or now
+            cur = conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state,
+                                  dialed_in_at, dial_reason, marathon_id, updated_at)
+                                  VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
+                               (row["global_id"], rel_ids[row["release_gid"]],
+                                ref_ids[row["issue_ref_gid"]], state,
+                                row.get("dialed_in_at"), row.get("dial_reason"),
+                                mar_ids.get(row["marathon_gid"]) if row.get("marathon_gid") else None,
+                                item_updated))
+        else:
+            cur = conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state,
+                                  dialed_in_at, dial_reason, marathon_id)
+                                  VALUES (?, ?, ?, ?, ?, ?, ?)""",
+                               (row["global_id"], rel_ids[row["release_gid"]],
+                                ref_ids[row["issue_ref_gid"]], state,
+                                row.get("dialed_in_at"), row.get("dial_reason"),
+                                mar_ids.get(row["marathon_gid"]) if row.get("marathon_gid") else None))
         item_ids[row["global_id"]] = cur.lastrowid
     for row in tables.get("manifest_state_events", []):
         conn.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at, reason)
                         VALUES (?, ?, ?, ?, ?)""",
                      (item_ids[row["item_gid"]], row["from_state"], row["to_state"], row["at"],
                       row["reason"]))
     for row in tables.get("doc_lines", []):
-        conn.execute("""INSERT INTO doc_lines(repo_id, position, content) VALUES (?, ?, ?)""",
-                     (repo_ids[row["repo_gid"]], int(row["position"]), row["content"]))
+        if _has_column(conn, "doc_lines", "updated_at"):
+            conn.execute("""INSERT INTO doc_lines(repo_id, position, content, updated_at) VALUES (?, ?, ?, ?)""",
+                         (repo_ids[row["repo_gid"]], int(row["position"]), row["content"], row.get("updated_at") or now))
+        else:
+            conn.execute("""INSERT INTO doc_lines(repo_id, position, content) VALUES (?, ?, ?)""",
+                         (repo_ids[row["repo_gid"]], int(row["position"]), row["content"]))
     for row in tables.get("legacy_lines", []):
-        conn.execute("""INSERT INTO legacy_lines(release_id, position, content, disposition)
-                        VALUES (?, ?, ?, ?)""",
-                     (rel_ids[row["release_gid"]], int(row["position"]), row["content"],
-                      row.get("disposition")))
+        if _has_column(conn, "legacy_lines", "updated_at"):
+            conn.execute("""INSERT INTO legacy_lines(release_id, position, content, disposition, updated_at)
+                            VALUES (?, ?, ?, ?, ?)""",
+                         (rel_ids[row["release_gid"]], int(row["position"]), row["content"],
+                          row.get("disposition"), row.get("updated_at") or now))
+        else:
+            conn.execute("""INSERT INTO legacy_lines(release_id, position, content, disposition)
+                            VALUES (?, ?, ?, ?)""",
+                         (rel_ids[row["release_gid"]], int(row["position"]), row["content"],
+                          row.get("disposition")))
     for row in tables.get("grandfather_entries", []):
         rgid = row.get("release_gid")
         if rgid in ("(document)", ""):
             rgid = None
         elif rgid is not None and not rgid.startswith("rel-"):
             rgid = None   # tolerate older shapes; the (document) marker is the contract
-        conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value,
-                        supplied_value, disposition) VALUES (?, ?, ?, ?, ?, ?)""",
-                     (row["import_run"], rgid, row["rule"], row.get("source_value"),
-                      row.get("supplied_value"), row.get("disposition")))
+        if _has_column(conn, "grandfather_entries", "updated_at"):
+            conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value,
+                            supplied_value, disposition, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)""",
+                         (row["import_run"], rgid, row["rule"], row.get("source_value"),
+                          row.get("supplied_value"), row.get("disposition"), row.get("updated_at") or now))
+        else:
+            conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value,
+                            supplied_value, disposition) VALUES (?, ?, ?, ?, ?, ?)""",
+                         (row["import_run"], rgid, row["rule"], row.get("source_value"),
+                          row.get("supplied_value"), row.get("disposition")))
     for row in tables.get("roadmap_items", []):
         conn.execute("""INSERT INTO roadmap_items(global_id, repo_id, gh_number, title, section,
                         position, status_marker, complexity, risk, effort, doc_path, issue_url,
                         raw_text, first_seen, updated_at,
                         rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                      (row["global_id"], repo_ids[row["repo_gid"]], _int_or_none(row.get("gh_number")),
                       row["title"], row["section"], int(row["position"]),
                       row.get("status_marker"), _int_or_none(row.get("complexity")),
                       _int_or_none(row.get("risk")), _int_or_none(row.get("effort")),
                       row.get("doc_path"), row.get("issue_url"), row["raw_text"],
                       row["first_seen"], row["updated_at"],
                       *[_int_or_none(row.get(c)) for c in RATING_COLUMNS]))
     for row in tables.get("jog_queue", []):
         conn.execute("""INSERT INTO jog_queue(global_id, repo_id, gh_number, position, status,
                         created_at, updated_at, attempt_count, lease_pid, failure_reason)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                      (row["global_id"], repo_ids[row["repo_gid"]], int(row["gh_number"]),
                       int(row["position"]), row["status"], row["created_at"], row["updated_at"],
                       int(row.get("attempt_count") or 0),
@@ -4308,46 +4654,54 @@ def _rebuild(root, conn):
             try:
                 load_dump(tconn, parsed, skip_schema_migrations=True)
             except sqlite3.IntegrityError as exc:
                 # backstop for damage validate_merged_dump does not yet name: still a refusal with a
                 # rule and a pointer, never a traceback.
                 refuse("dump-load",
                        "the dump could not be loaded: %s. This usually means the merged dump "
                        "contains a row twice, or a reference to a row that is not in it. Fix "
                        "%s and rebuild; the live DB has not been touched." % (exc, DUMP_NAME))
             # Step 3: stamp exactly the registry's versions. Each keeps the dump's own applied_at
             # where the dump had it — the ledger row is business state that feeds the digest, so
             # restamping an unchanged migration with "now" would make every rebuild look like a
             # content change. Versions the dump did NOT carry are genuinely new here and take the
             # current time, which is the honest record of when this schema actually arrived.
             dump_applied = {int(r["version"]): r["applied_at"]
                             for r in parsed.get("schema_migrations", [])}
             stamped_at = now_iso()
             for version in registry_versions():
                 tconn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)",
                               (version, dump_applied.get(version, stamped_at)))
-            tconn.execute("UPDATE settings SET value = ? WHERE key = ?",
-                          (str(new_gen), GENERATION_KEY))
-            if tconn.execute("SELECT 1 FROM settings WHERE key = ?",
-                             (GENERATION_KEY,)).fetchone() is None:
-                tconn.execute("INSERT INTO settings(key, value) VALUES (?, ?)",
-                              (GENERATION_KEY, str(new_gen)))
+            if _has_column(tconn, "settings", "updated_at"):
+                tconn.execute("UPDATE settings SET value = ?, updated_at = ? WHERE key = ?",
+                              (str(new_gen), stamped_at, GENERATION_KEY))
+                if tconn.execute("SELECT 1 FROM settings WHERE key = ?",
+                                 (GENERATION_KEY,)).fetchone() is None:
+                    tconn.execute("INSERT INTO settings(key, value, updated_at) VALUES (?, ?, ?)",
+                                  (GENERATION_KEY, str(new_gen), stamped_at))
+            else:
+                tconn.execute("UPDATE settings SET value = ? WHERE key = ?",
+                              (str(new_gen), GENERATION_KEY))
+                if tconn.execute("SELECT 1 FROM settings WHERE key = ?",
+                                 (GENERATION_KEY,)).fetchone() is None:
+                    tconn.execute("INSERT INTO settings(key, value) VALUES (?, ?)",
+                                  (GENERATION_KEY, str(new_gen)))
             new_digest = business_digest(tconn)
             tconn.execute("""INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id,
                              state_digest_before, state_digest_after)
                              VALUES ('merge-rebuild', NULL, ?, ?, ?, ?, ?)""",
                           (now_iso(), new_txn_id(), session_id(), old_digest, new_digest))
         finally:
             tconn.close()
         probe = connect(tmp_db)   # FK pragma + openability of the rebuilt DB, before it goes live
         probe.close()
     except BaseException:
         try:
             os.unlink(tmp_db)
         except OSError:
             pass
         raise
 
     shutil.copy2(paths["db"], paths["bak"])
     os.replace(tmp_db, paths["db"])
     conn.close()
     fresh = connect(paths["db"])
@@ -4467,47 +4821,58 @@ def cmd_reconcile(args):
         if not args.map:
             refuse("reconcile-map", "pass --map TMP-XXXXXX=<url> (repeatable)")
 
         def mutate(conn):
             for pair in args.map:
                 if "=" not in pair:
                     refuse("reconcile-map", "--map expects TMP-XXXXXX=<url>, got %r" % pair)
                 temp, url = pair.split("=", 1)
                 temp, url = temp.strip(), url.strip()
                 if not (TMP_RE.match(temp) or MIG_RE.match(temp)):
                     refuse("reconcile-map",
                            "--map key %r must be a TMP-XXXXXX or MIG-XXXXXX placeholder" % temp)
                 if not GH_ISSUE_URL_RE.match(url):
                     refuse("issue-url-shape",
                            "mapped URL %r must be https://github.com/<org>/<repo>/issues/<n>"
                            % url)
                 row = conn.execute("SELECT * FROM issue_refs WHERE temp_id = ?",
                                    (temp,)).fetchone()
                 if not row:
                     refuse("unknown-temp-ref", "no issue_refs row carries temp id %r" % temp)
-                conn.execute("UPDATE issue_refs SET url = ?, temp_id = NULL WHERE id = ?",
-                             (url, row["id"]))
+                now = now_iso()
+                if _has_column(conn, "issue_refs", "updated_at"):
+                    conn.execute("UPDATE issue_refs SET url = ?, temp_id = NULL, updated_at = ? WHERE id = ?",
+                                 (url, now, row["id"]))
+                else:
+                    conn.execute("UPDATE issue_refs SET url = ?, temp_id = NULL WHERE id = ?",
+                                 (url, row["id"]))
                 if temp.startswith("MIG-"):
-                    conn.execute("""UPDATE grandfather_entries SET disposition = ?
-                                 WHERE rule = 'tracking-issue-missing' AND supplied_value = ?
-                                   AND disposition IS NULL""",
-                                 ("reconciled:%s" % now_iso(), temp))
+                    if _has_column(conn, "grandfather_entries", "updated_at"):
+                        conn.execute("""UPDATE grandfather_entries SET disposition = ?, updated_at = ?
+                                     WHERE rule = 'tracking-issue-missing' AND supplied_value = ?
+                                       AND disposition IS NULL""",
+                                     ("reconciled:%s" % now, now, temp))
+                    else:
+                        conn.execute("""UPDATE grandfather_entries SET disposition = ?
+                                     WHERE rule = 'tracking-issue-missing' AND supplied_value = ?
+                                       AND disposition IS NULL""",
+                                     ("reconciled:%s" % now, temp))
                 print("reconciled %s -> %s (row %s kept its identity)"
                       % (temp, url, row["global_id"]))
 
         perform_write(root, conn, "reconcile", None, mutate)
     finally:
         conn.close()
 
 
 # ── CLI ─────────────────────────────────────────────────────────────────────────────────────────
 
 def build_parser():
     p = argparse.ArgumentParser(prog="releases",
                                  description="GH-32 SQLite-backed RELEASES ledger CLI "
                                              "(Phase 0+1: side-by-side generation only)")
     p.add_argument("--root", help="repo root (default: git toplevel of the CWD)")
     sub = p.add_subparsers(dest="cmd", required=True)
 
     sp = sub.add_parser("init", help="create the DB + dump; settings default lenient")
     sp.add_argument("--slug", help="repo slug (default: root directory basename)")
 
@@ -4563,40 +4928,45 @@ def build_parser():
         _p.add_argument("--reason", default=None,
                         help="the case for committing this task to this release")
         _p.add_argument("--marathon", default=None,
                         help="marathon gid; must be THIS release's marathon")
     sp_ship = msub.add_parser("ship",
                               help="mark a dialed-in item shipped (REQUIRES --evidence)")
     sp_ship.add_argument("--gid", required=True)
     sp_ship.add_argument("issue", help="issue URL or TMP-XXXXXX")
     sp_ship.add_argument("--evidence", default="",
                          help="commit, PR, or test receipt (empty is refused)")
     sp_mar = msub.add_parser("marathon",
                              help="link an already dialed-in item to its release's marathon")
     sp_mar.add_argument("--gid", required=True)
     sp_mar.add_argument("issue", help="issue URL or TMP-XXXXXX")
     sp_mar.add_argument("--marathon", required=True, help="marathon gid; must be THIS release's")
     sp_cut = msub.add_parser("cut",
                              help="cut an item from a release's manifest (REQUIRES --reason)")
     sp_cut.add_argument("--gid", required=True)
     sp_cut.add_argument("issue", help="issue URL or TMP-XXXXXX")
     sp_cut.add_argument("--reason", default="")
+    sp_unship = msub.add_parser("unship",
+                                help="retract a shipped manifest item back to dialed_in (REQUIRES --reason)")
+    sp_unship.add_argument("--gid", required=True)
+    sp_unship.add_argument("issue", help="issue URL or TMP-XXXXXX")
+    sp_unship.add_argument("--reason", default="")
 
     sp = sub.add_parser("marathon", help="marathon CRUD (v1: add/list)")
     msub = sp.add_subparsers(dest="marathon_cmd", required=True)
     sp_add = msub.add_parser("add")
     sp_add.add_argument("--tracking-issue", required=True, help="issue URL or TMP-XXXXXX")
     sp_add.add_argument("--status", default="planned", choices=MARATHON_STATUSES)
     msub.add_parser("list")
 
     sp = sub.add_parser("list", help="list releases")
     sp.add_argument("--all-repos", action="store_true",
                     help="aggregate RELEASES_APP_EXTRA_DBS too; duplicate GIDs fail loudly")
     sp.add_argument("--status", choices=STATUSES)
 
     sp = sub.add_parser("show", help="full record for one release (by --gid or --version)")
     sp.add_argument("--gid")
     sp.add_argument("--version")
     sp.add_argument("--full", action="store_true",
                     help="print long values verbatim (default elides them at %d chars)"
                          % SHOW_ELIDE)
 
@@ -4748,42 +5118,43 @@ def build_parser():
                               "executor (GH-280 Phase 5); no default is selected")
     sp_jrun.add_argument("--executor", choices=["relay", "marathon"], default="marathon",
                          help="per-task executor (GH-280 Phase 5): 'marathon' is the default — the "
                               "reviewed one-phase driver via the structured contracts, requires "
                               "--reviewer; 'relay' is the legacy rollback path kept for a "
                               "documented compatibility window")
     sp_jrun.add_argument("--max-tasks", type=int, default=None, help="maximum tasks to process in this run")
     sp_jrun.add_argument("--simulate", action="store_true", help="simulate drive execution in test environments")
     sp_jrun.add_argument("--dry-run", action="store_true", help="simulate queue run without mutations")
 
     return p
 
 
 def main(argv=None):
     args = build_parser().parse_args(argv)
     handlers = {
         "init": cmd_init, "import": cmd_import, "add": cmd_add, "update": cmd_update,
         "ship": cmd_ship, "migrate": cmd_migrate, "baseline": cmd_baseline,
         "manifest": lambda a: cmd_manifest_add(a) if a.manifest_cmd in ("dial-in", "add")
         else (cmd_manifest_ship(a) if a.manifest_cmd == "ship"
-              else (cmd_manifest_marathon(a) if a.manifest_cmd == "marathon"
-                    else cmd_manifest_cut(a))),
+              else (cmd_manifest_unship(a) if a.manifest_cmd == "unship"
+                    else (cmd_manifest_marathon(a) if a.manifest_cmd == "marathon"
+                          else cmd_manifest_cut(a)))),
         "marathon": lambda a: cmd_marathon_add(a) if a.marathon_cmd == "add"
         else cmd_marathon_list(a),
         "list": cmd_list, "show": cmd_show, "next": cmd_next, "gen": cmd_gen,
         "check": cmd_check, "reconcile": cmd_reconcile,
         "project": lambda a: cmd_project_sync(a) if a.project_cmd == "sync" else None,
         # A lookup, not a ternary chain: `rate` (GH-253) was the fourth branch, and the nested
         # form was already one subcommand past readable.
         "roadmap": lambda a: {"add": cmd_roadmap_add, "sync": cmd_roadmap_sync,
                               "rate": cmd_roadmap_rate, "list": cmd_roadmap_list,
                               "repoint": cmd_roadmap_repoint, "update": cmd_roadmap_update}[a.roadmap_cmd](a),
         "dashboard": cmd_dashboard,
         "jog": lambda a: {"add": cmd_jog_add, "list": cmd_jog_list,
                           "bump": cmd_jog_bump, "drop": cmd_jog_drop,
                           "retry": cmd_jog_retry, "skip": cmd_jog_skip,
                           "clear": cmd_jog_clear, "to-marathon": cmd_jog_to_marathon,
                           "run": cmd_jog_run, "resume": cmd_jog_resume,
                           "retry-gate": cmd_jog_retry_gate, "retry-build": cmd_jog_retry_build,
                           "land": cmd_jog_land, "reconcile": cmd_jog_land}[a.jog_cmd](a),
     }
     handlers[args.cmd](args)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-CJ3OqnT3' (errno=Operation not permitted)
2026-08-31 16:32:58.446 xcodebuild[75615:6480364]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:58.647 xcodebuild[75615:6480363] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-Ufvzbzor' (errno=Operation not permitted)
2026-08-31 16:32:59.271 xcodebuild[75618:6480379]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:32:59.467 xcodebuild[75618:6480378] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
     1	#!/usr/bin/env bash
     2	# gh349-vendored-roadmap-ledger.sh — GH-349: roadmap layer and releases ledger in vendored installs.
     3	#
     4	# Asserts:
     5	#   Scope 1: `roadmap sync` refuses rather than deleting when 0 entries are parsed from non-empty ROADMAP.md.
     6	#   Scope 1: Link-style bullets `- [Title](path) — ...` parse cleanly.
     7	#   Scope 2: Issue URLs from foreign orgs (arbitrary GitHub orgs/repos) are captured into issue_url.
     8	#   Scope 3: Migration 007 applies `updated_at` timestamps to all 9 tables from pre-migration state,
     9	#            non-null backfill, direct rebuild from untouched v6 dump backfills all 9 tables,
    10	#            updates advance timestamps (including settings.generation), exact timestamp preservation
    11	#            across all non-generation tables with stable keys, and pinned rebuild timestamp on settings.generation.
    12	#   Scope 4: Rating system doc and validation (shape refusal, axis ranges, ovr range/orphan, vocabulary clash).
    13	#   Advisory: `releases next` warns when all candidates are undated.
    14	set -uo pipefail
    15	
    16	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    17	ROOT_DIR="$(cd "$HERE/.." && pwd)"
    18	APP="$ROOT_DIR/utils/py/releases_app.py"
    19	
    20	pass=0; fail=0
    21	ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
    22	is(){ [ "$1" = "$2" ]; }
    23	has(){ printf '%s' "$1" | grep -Fq "$2"; }
    24	
    25	echo "== test: gh349-vendored-roadmap-ledger =="
    26	
    27	command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
    28	command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }
    29	
    30	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh349-vendored.XXXXXX")"
    31	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
    32	. "$HERE/lib/fixture-guard.sh"
    33	fixture_guard_init "$WORK"
    34	cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
    35	trap cleanup EXIT
    36	
    37	mkrepo(){
    38	  local r="$WORK/$1"
    39	  mkdir -p "$r"
    40	  git -C "$r" init -q -b main
    41	  git -C "$r" config user.email test@invalid
    42	  git -C "$r" config user.name test
    43	  printf '%s\n' "$r"
    44	}
    45	
    46	R="$(mkrepo repo)"
    47	require_fixture "$R" "fixture repo"
    48	
    49	ra(){
    50	  require_fixture "$R" "fixture repo"
    51	  python3 "$APP" --root "$R" "$@"
    52	}
    53	
    54	ra init --slug vendored-repo >/dev/null
    55	
    56	# ── 1. Scope 1 & 2: Link bullets and foreign org issue URLs ────────────────────────
    57	cat > "$R/ROADMAP.md" <<'MD'
    58	# Foreign Org Roadmap
    59	## Ledger
    60	### Active
    61	- [GH-101 · Custom Feature](PROJECT/2-WORKING/GH-101.md) — Link-style bullet format. rated 80/60/70/50. → [#101](https://github.com/ExternalOrg/ExternalRepo/issues/101)
    62	- [External Pull Request](PROJECT/2-WORKING/GH-102.md) — External PR link. → [#102](https://github.com/OtherOrg/OtherRepo/pull/102)
    63	- **GH-103 · Bold Format** — Standard format for comparison. rated 60/40/80/70. → [#103](https://github.com/ExternalOrg/ExternalRepo/issues/103)
    64	MD
    65	
    66	out="$(ra roadmap sync 2>&1)"
    67	ok "roadmap sync parsed link-style bullets and bold bullets" "$(has "$out" "+3 added"; echo $?)"
    68	
    69	# Check issue_url from foreign orgs
    70	URL_101="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=101;")"
    71	ok "foreign org issue url extracted properly" "$(is "$URL_101" "https://github.com/ExternalOrg/ExternalRepo/issues/101"; echo $?)"
    72	
    73	URL_102="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE title='External Pull Request';")"
    74	ok "foreign org pull url extracted properly" "$(is "$URL_102" "https://github.com/OtherOrg/OtherRepo/pull/102"; echo $?)"
    75	
    76	COUNT_ITEMS="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items;")"
    77	ok "all 3 items mirrored" "$(is "$COUNT_ITEMS" "3"; echo $?)"
    78	
    79	# ── 2. Scope 1: Non-empty file with 0 parsed entries refuses and protects data ────
    80	cat > "$R/ROADMAP.md" <<'MD'
    81	# Malformed format where nothing is under ## Ledger
    82	Some notes about the roadmap without a Ledger section.
    83	MD
    84	
    85	out="$(ra roadmap sync 2>&1 || true)"
    86	ok "sync on non-empty roadmap with 0 parsed entries is refused (rule=roadmap-empty)" "$(has "$out" "rule=roadmap-empty"; echo $?)"
    87	
    88	# Confirm data was NOT deleted
    89	COUNT_AFTER="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items;")"
    90	ok "roadmap_items preserved without wipe" "$(is "$COUNT_AFTER" "3"; echo $?)"
    91	
    92	# ── 3. Scope 3: Pre-migration fixture, direct rebuild from untouched v6 dump, non-null backfill, v7 exact preservation ──
    93	R_PRE="$(mkrepo pre_mig_repo)"
    94	require_fixture "$R_PRE" "pre-mig fixture repo"
    95	
    96	# Build a pre-007 fixture (v6 schema migrations) with untouched v6 dump
    97	python3 - "$R_PRE" "$APP" <<'PYPRE'
    98	import sys, os, importlib.util
    99	root = sys.argv[1]
   100	app_path = sys.argv[2]
   101	spec = importlib.util.spec_from_file_location("releases_app", app_path)
   102	ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
   103	db_path = os.path.join(root, "releases.db")
   104	conn = ra.connect(db_path, must_exist=False)
   105	# Apply migrations 001 through 006 only
   106	for v, m_spec in sorted(ra.MIGRATIONS.items()):
   107	    if v < 7:
   108	        m_spec["apply"](conn)
   109	        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)", (v, ra.now_iso()))
   110	# Populate all 9 target tables without updated_at
   111	conn.execute("INSERT INTO settings(key, value) VALUES ('enforcement', 'lenient')")
   112	conn.execute("INSERT INTO settings(key, value) VALUES ('repo_slug', 'pre-repo')")
   113	conn.execute("INSERT INTO settings(key, value) VALUES ('generation', '1')")
   114	conn.execute("INSERT INTO repos(global_id, slug) VALUES ('repo-01ARZ3NDEKTSV4RRFFQ69G5FA0', 'pre-repo')")
   115	conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES ('ref-01ARZ3NDEKTSV4RRFFQ69G5FA1', 'https://github.com/A/B/issues/1', NULL, '2026-08-01T00:00:00Z')")
   116	conn.execute("INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status, created_at) VALUES ('mar-01ARZ3NDEKTSV4RRFFQ69G5FA2', 1, 1, 'running', '2026-08-01T00:00:00Z')")
   117	conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status, description, tracking_ref_id, marathon_id)
   118	                VALUES ('rel-01ARZ3NDEKTSV4RRFFQ69G5FA3', 1, '1.0.0', 'Kickoff', 'active', 'pre-mig release', 1, 1)""")
   119	conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state, dialed_in_at, dial_reason, marathon_id)
   120	                VALUES ('mfi-01ARZ3NDEKTSV4RRFFQ69G5FA4', 1, 1, 'dialed_in', '2026-08-01T00:00:00Z', 'first item', 1)""")
   121	conn.execute("INSERT INTO doc_lines(repo_id, position, content) VALUES (1, 0, '# Title')")
   122	conn.execute("INSERT INTO legacy_lines(release_id, position, content) VALUES (1, 0, 'Legacy notes')")
   123	conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value, supplied_value, disposition)
   124	                VALUES ('imp-20260801', 'rel-01ARZ3NDEKTSV4RRFFQ69G5FA3', 'status-enum', 'Draft', 'draft', NULL)""")
   125	paths = ra.artifact_paths(root)
   126	ra._atomic_write(paths["dump"], ra.dump_text(conn, 1))
   127	conn.commit()
   128	conn.close()
   129	PYPRE
   130	
   131	# Test direct rebuild from untouched v6 dump (exercises loading pre-007 dump into v7 schema)
   132	python3 "$APP" --root "$R_PRE" check --rebuild >/dev/null
   133	
   134	TABLES=("releases" "manifest_items" "marathons" "repos" "settings" "issue_refs" "doc_lines" "legacy_lines" "grandfather_entries")
   135	all_rebuild_non_null=1
   136	for tbl in "${TABLES[@]}"; do
   137	  null_count="$(sqlite3 "$R_PRE/releases.db" "SELECT COUNT(*) FROM $tbl WHERE updated_at IS NULL;")"
   138	  if [ "$null_count" -ne 0 ]; then
   139	    all_rebuild_non_null=0
   140	    echo "table $tbl has $null_count NULL updated_at rows after rebuild from untouched v6 dump" >&2
   141	  fi
   142	done
   143	ok "direct rebuild from untouched v6 dump populates 100% non-NULL updated_at across all 9 tables" "$(is "$all_rebuild_non_null" "1"; echo $?)"
   144	
   145	# Test newly created issue_ref has non-null updated_at
   146	NEW_REF="$(python3 "$APP" --root "$R_PRE" add --version 2.0.0 --status draft --tracking-issue https://github.com/A/B/issues/2 --description "v2.0.0" | grep -o 'rel-[0-9A-HJKMNP-TV-Z]\{26\}')"
   147	REF_UPDATED_AT="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM issue_refs WHERE url='https://github.com/A/B/issues/2';")"
   148	ok "newly inserted issue_ref has non-null updated_at" "$([ -n "$REF_UPDATED_AT" ] && echo 0 || echo 1)"
   149	
   150	# Test timestamp advancement on mutation
   151	GEN_TIME_BEFORE="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM settings WHERE key='generation';")"
   152	TIME_BEFORE="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM releases WHERE global_id='$NEW_REF';")"
   153	sleep 1
   154	python3 "$APP" --root "$R_PRE" update --gid "$NEW_REF" --description "updated description" >/dev/null
   155	GEN_TIME_AFTER="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM settings WHERE key='generation';")"
   156	TIME_AFTER="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM releases WHERE global_id='$NEW_REF';")"
   157	ok "release update advances release updated_at timestamp" "$([ "$TIME_AFTER" \> "$TIME_BEFORE" ] && echo 0 || echo 1)"
   158	ok "mutation advances settings.generation updated_at timestamp" "$([ "$GEN_TIME_AFTER" \> "$GEN_TIME_BEFORE" ] && echo 0 || echo 1)"
   159	
   160	# Test dump and rebuild exact timestamp preservation across all non-generation tables using stable keys
   161	python3 "$APP" --root "$R_PRE" check >/dev/null
   162	
   163	snapshot_non_generation_tables(){
   164	  local db="$1"
   165	  echo "--- settings (non-generation) ---"
   166	  sqlite3 "$db" "SELECT key, value, updated_at FROM settings WHERE key != 'generation' ORDER BY key;"
   167	  echo "--- repos ---"
   168	  sqlite3 "$db" "SELECT global_id, slug, updated_at FROM repos ORDER BY global_id;"
   169	  echo "--- issue_refs ---"
   170	  sqlite3 "$db" "SELECT global_id, COALESCE(url, temp_id), updated_at FROM issue_refs ORDER BY global_id;"
   171	  echo "--- marathons ---"
   172	  sqlite3 "$db" "SELECT global_id, status, updated_at FROM marathons ORDER BY global_id;"
   173	  echo "--- releases ---"
   174	  sqlite3 "$db" "SELECT global_id, version, updated_at FROM releases ORDER BY global_id;"
   175	  echo "--- manifest_items ---"
   176	  sqlite3 "$db" "SELECT global_id, state, updated_at FROM manifest_items ORDER BY global_id;"
   177	  echo "--- doc_lines ---"
   178	  sqlite3 "$db" "SELECT position, content, updated_at FROM doc_lines ORDER BY position;"
   179	  echo "--- legacy_lines ---"
   180	  sqlite3 "$db" "SELECT position, content, updated_at FROM legacy_lines ORDER BY position;"
   181	  echo "--- grandfather_entries ---"
   182	  sqlite3 "$db" "SELECT import_run, COALESCE(release_gid, '(doc)'), rule, updated_at FROM grandfather_entries ORDER BY import_run, id;"
   183	}
   184	
   185	SNAPSHOT_BEFORE="$(snapshot_non_generation_tables "$R_PRE/releases.db")"
   186	RELEASES_APP_NOW="2026-09-01T12:00:00Z" python3 "$APP" --root "$R_PRE" check --rebuild >/dev/null
   187	SNAPSHOT_AFTER="$(snapshot_non_generation_tables "$R_PRE/releases.db")"
   188	ok "check --rebuild preserves exact updated_at values across all non-generation tables" "$(is "$SNAPSHOT_BEFORE" "$SNAPSHOT_AFTER"; echo $?)"
   189	
   190	GEN_AFTER="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM settings WHERE key='generation';")"
   191	ok "check --rebuild stamps pinned rebuild time into settings.generation.updated_at" "$(is "$GEN_AFTER" "2026-09-01T12:00:00Z"; echo $?)"
   192	
   193	# ── 4. Scope 4: Canonical rating vocabulary, axis parsing, ranges, ovr, malformed shape, vocabulary clash ──
   194	cat > "$R/ROADMAP.md" <<'MD'
   195	# Foreign Org Roadmap
   196	## Ledger
   197	### Active
   198	- [GH-110 · Rated Feature](PROJECT/2-WORKING/GH-110.md) — 4-axis rated. rated 90/80/70/60. ovr 350. → [#110](https://github.com/ExternalOrg/ExternalRepo/issues/110)
   199	MD
   200	ra roadmap sync >/dev/null
   201	RATING_VALS="$(sqlite3 "$R/releases.db" "SELECT rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr FROM roadmap_items WHERE gh_number=110;")"
   202	ok "4-axis rating and ovr parsed into database" "$(is "$RATING_VALS" "90|80|70|60|350"; echo $?)"
   203	
   204	# Test malformed rating shape (e.g. 3 axes instead of 4) refusal
   205	cat > "$R/ROADMAP.md" <<'MD'
   206	# Foreign Org Roadmap
   207	## Ledger
   208	### Active
   209	- [GH-111 · Malformed Rating Shape](PROJECT/2-WORKING/GH-111.md) — Malformed shape. rated 70/40/55. → [#111](https://github.com/ExternalOrg/ExternalRepo/issues/111)
   210	MD
   211	out="$(ra roadmap sync 2>&1 || true)"
   212	ok "malformed rating shape (rated 70/40/55) is refused (rule=rating-shape)" "$(has "$out" "rule=rating-shape"; echo $?)"
   213	
   214	# Test rating axis out of range (>100 on axis) refusal
   215	cat > "$R/ROADMAP.md" <<'MD'
   216	# Foreign Org Roadmap
   217	## Ledger
   218	### Active
   219	- [GH-112 · Bad Rating Range](PROJECT/2-WORKING/GH-112.md) — Out of range. rated 150/80/70/60. → [#112](https://github.com/ExternalOrg/ExternalRepo/issues/112)
   220	MD
   221	out="$(ra roadmap sync 2>&1 || true)"
   222	ok "rating axis out of range (>100) is refused (rule=rating-range)" "$(has "$out" "rule=rating-range"; echo $?)"
   223	
   224	# Test ovr out of range (>400) refusal
   225	cat > "$R/ROADMAP.md" <<'MD'
   226	# Foreign Org Roadmap
   227	## Ledger
   228	### Active
   229	- [GH-113 · Bad OVR Range](PROJECT/2-WORKING/GH-113.md) — Bad ovr. rated 80/70/60/50. ovr 500. → [#113](https://github.com/ExternalOrg/ExternalRepo/issues/113)
   230	MD
   231	out="$(ra roadmap sync 2>&1 || true)"
   232	ok "ovr out of range (>400) is refused (rule=ovr-range)" "$(has "$out" "rule=ovr-range"; echo $?)"
   233	
   234	# Test orphan ovr (ovr without rated) refusal
   235	cat > "$R/ROADMAP.md" <<'MD'
   236	# Foreign Org Roadmap
   237	## Ledger
   238	### Active
   239	- [GH-114 · Orphan OVR](PROJECT/2-WORKING/GH-114.md) — Orphan ovr. ovr 300. → [#114](https://github.com/ExternalOrg/ExternalRepo/issues/114)
   240	MD
   241	out="$(ra roadmap sync 2>&1 || true)"
   242	ok "orphan ovr without rated is refused (rule=ovr-orphan)" "$(has "$out" "rule=ovr-orphan"; echo $?)"
   243	
   244	# Test rating vocabulary clash (legacy cx/risk/eff mixed with rated) refusal
   245	cat > "$R/ROADMAP.md" <<'MD'
   246	# Foreign Org Roadmap
   247	## Ledger
   248	### Active
   249	- [GH-115 · Clash Rating](PROJECT/2-WORKING/GH-115.md) — Clash. cx/risk/eff 3/2/1. rated 80/70/60/50. → [#115](https://github.com/ExternalOrg/ExternalRepo/issues/115)
   250	MD
   251	out="$(ra roadmap sync 2>&1 || true)"
   252	ok "rating vocabulary clash (cx/risk/eff + rated) is refused (rule=rating-vocabulary-clash)" "$(has "$out" "rule=rating-vocabulary-clash"; echo $?)"
   253	
   254	# ── 5. Advisory: undated release warning in `releases next` ────────────────────────
   255	ra add --version 2.0.0 --status active --tracking-issue https://github.com/ExternalOrg/ExternalRepo/issues/100 --description "v2.0.0" >/dev/null
   256	
   257	out_err="$(ra next 2>&1 >/dev/null || true)"
   258	ok "releases next emits warning when all candidates are undated" "$(has "$out_err" "warning: every candidate release is undated"; echo $?)"
   259	
   260	echo "gh349: $pass passed, $fail failed"
   261	[ "$fail" -eq 0 ]
     1	#!/usr/bin/env bash
     2	# GH-349 — releases ledger: roadmap layer generalisation for vendored installs
     3	#
     4	# Tests:
     5	#   1. parse_roadmap_ledger accepts link-style bullets: `- [Title](doc_path) — ...`
     6	#   2. parse_roadmap_ledger extracts issue and PR URLs from any GitHub org/repo
     7	#   3. roadmap sync successfully populates roadmap_items from link-style bullets in legacy mode
     8	#   4. roadmap sync refuses with rule=roadmap-empty-parse when parsing 0 entries from a non-empty
     9	#      ledger (prevents table deletion)
    10	#   5. RELEASES-DB-FAQS.md contains the canonical rating system documentation
    11	#   6. LTVera-Pandas #322 review regressions: anchored GH key, umbrella titles, doc_path vs URL,
    12	#      issue_url anchoring, task-list checkboxes
    13	#   7. this repo's own ROADMAP.md parses with no duplicate GH keys
    14	#   8. codex QA regressions: unkeyed entries never adopt a cited blocker, absolute/scheme/absolute-
    15	#      path targets never reach doc_path, en dash is a range and em dash is not
    16	#   9. ambiguity + clearing refusals: duplicate unkeyed titles, and --allow-empty
    17	#  10. the legacy GH_URL matcher keeps its issue-only contract, separate from the roadmap matcher
    18	set -uo pipefail
    19	
    20	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    21	ROOT_DIR="$(cd "$HERE/.." && pwd)"
    22	APP="$ROOT_DIR/utils/py/releases_app.py"
    23	
    24	pass=0; fail=0
    25	ok()   { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1" >&2; fail=$((fail+1)); fi }
    26	has()  { printf '%s' "$1" | grep -Fq -- "$2"; }
    27	
    28	echo "== test: gh349-releases-roadmap-vendored =="
    29	command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
    30	command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }
    31	
    32	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh349-vendored.XXXXXX")"
    33	. "$HERE/lib/fixture-guard.sh"
    34	fixture_guard_init "$WORK"
    35	cleanup() {
    36	  case "${WORK:-}" in
    37	    "${TMPDIR:-/tmp}"/gh349-vendored.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    38	    *) echo "gh349: REFUSING cleanup outside the workspace: ${WORK:-<empty>}" >&2 ;;
    39	  esac
    40	}
    41	trap cleanup EXIT
    42	
    43	R="$WORK/r"
    44	mkdir -p "$R"; require_fixture "$R" "vendored roadmap fixture"
    45	git -C "$R" init -q -b main
    46	git -C "$R" config user.email gh349@test.invalid
    47	git -C "$R" config user.name gh349
    48	ra() { require_fixture "$R" "vendored roadmap fixture"; python3 "$APP" --root "$R" "$@"; }
    49	
    50	ra init --slug test-vendored-repo >/dev/null
    51	ra migrate >/dev/null
    52	
    53	# ── 1. Create link-style ROADMAP.md with external orgs ──────────────────────────────
    54	cat > "$R/ROADMAP.md" <<'MD'
    55	# Vendored Repo Roadmap
    56	
    57	## Ledger
    58	
    59	### Queue / parked intake
    60	- [GH-349 — releases ledger roadmap layer never generalised to a vendored install](PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md) - narrative body. (rated 85/70/90/60) -> [#349](https://github.com/ExternalOrg/CustomRepo/issues/349)
    61	- [GH-420 — external pull request tracking](docs/pr-420.md) - narrative body. (rated 50/40/60/70 ovr 220) -> [#420](https://github.com/OtherOrg/AnotherRepo/pull/420)
    62	- [Un-numbered item with link](docs/plans/item.md) - plain title. (rated 60/60/60/60)
    63	### In progress
    64	- **GH-100 · traditional bold bullet** 🚧 — standard bold form. (rated 75/65/80/55) -> [#100](https://github.com/CustomOrg/CustomRepo/issues/100)
    65	MD
    66	
    67	# ── 2. Sync link-style bullets in legacy mode ───────────────────────────────────────
    68	out="$(ra roadmap sync 2>&1)"; rc=$?
    69	ok "sync succeeds with link-style bullets (rc=$rc)" "[ $rc -eq 0 ]"
    70	ok "  and captured all 4 ledger entries" "has \"\$out\" '+4 added'"
    71	
    72	count="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
    73	ok "  and database has 4 roadmap items" "[ \"$count\" = '4' ]"
    74	
    75	# Verify link-style item fields
    76	gh349_title="$(sqlite3 "$R/releases.db" "SELECT title FROM roadmap_items WHERE gh_number=349")"
    77	ok "  and GH-349 title extracted correctly" "[ \"$gh349_title\" = 'GH-349 — releases ledger roadmap layer never generalised to a vendored install' ]"
    78	
    79	gh349_doc="$(sqlite3 "$R/releases.db" "SELECT doc_path FROM roadmap_items WHERE gh_number=349")"
    80	ok "  and GH-349 doc_path extracted correctly" "[ \"$gh349_doc\" = 'PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md' ]"
    81	
    82	gh349_url="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=349")"
    83	ok "  and GH-349 external org issue URL extracted correctly" "[ \"$gh349_url\" = 'https://github.com/ExternalOrg/CustomRepo/issues/349' ]"
    84	
    85	gh349_pri="$(sqlite3 "$R/releases.db" "SELECT rating_pri FROM roadmap_items WHERE gh_number=349")"
    86	ok "  and GH-349 rating_pri extracted correctly" "[ \"$gh349_pri\" = '85' ]"
    87	
    88	# Verify PR URL extraction on external org
    89	gh420_url="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=420")"
    90	ok "  and GH-420 external org pull URL extracted correctly" "[ \"$gh420_url\" = 'https://github.com/OtherOrg/AnotherRepo/pull/420' ]"
    91	
    92	gh420_ovr="$(sqlite3 "$R/releases.db" "SELECT rating_ovr FROM roadmap_items WHERE gh_number=420")"
    93	ok "  and GH-420 rating_ovr extracted correctly" "[ \"$gh420_ovr\" = '220' ]"
    94	
    95	# ── 3. Re-sync without changes is a no-op ───────────────────────────────────────────
    96	out="$(ra roadmap sync 2>&1)"; rc=$?
    97	ok "second sync is no-op (rc=$rc)" "[ $rc -eq 0 ]"
    98	ok "  and reports already in sync" "has \"\$out\" 'already in sync'"
    99	
   100	# ── 4. Empty-parse refusal guard ───────────────────────────────────────────────────
   101	# Simulate format drift / malformed ledger where 0 entries are parsed from non-empty ledger
   102	cat > "$R/ROADMAP.md" <<'MD'
   103	# Malformed Roadmap
   104	
   105	## Ledger
   106	
   107	### Queue / parked intake
   108	Some unbulleted drift prose that parses to 0 entries.
   109	MD
   110	
   111	out="$(ra roadmap sync 2>&1)"; rc=$?
   112	ok "sync refuses on 0 parsed entries from non-empty ledger (rc=$rc)" "[ $rc -ne 0 ]"
   113	ok "  and refusal cites rule=roadmap-empty-parse" "has \"\$out\" 'rule=roadmap-empty-parse'"
   114	
   115	count_after="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
   116	ok "  and existing roadmap_items were NOT deleted" "[ \"$count_after\" = '4' ]"
   117	
   118	# ── 5. RELEASES-DB-FAQS.md rating documentation ─────────────────────────────────────
   119	faqs="$ROOT_DIR/RELEASES-DB-FAQS.md"
   120	ok "RELEASES-DB-FAQS.md exists" "[ -f \"$faqs\" ]"
   121	ok "  and documents canonical rating grammar" "grep -Fq 'rated <pri>/<sev>/<appeal>/<effort>' \"$faqs\""
   122	ok "  and documents cheapness effort axis" "grep -Fq 'cheapness' \"$faqs\""
   123	ok "  and documents legacy cx/risk/eff separation" "grep -Fq 'cx/risk/eff' \"$faqs\""
   124	
   125	# ── 6. Review regressions (LTVera-Pandas #322 review of PR #350) ────────────────────
   126	# Four defects the first cut of this fix introduced or left standing:
   127	#   a. an unanchored GH search harvested a number out of a title that merely MENTIONS one,
   128	#      colliding with the real entry and making `roadmap sync` refuse on XYZ-forge's own ledger
   129	#   b. a multi-issue umbrella title was keyed to whichever issue it named first
   130	#   c. `doc_path` was filled with the link target even when that target was a GitHub URL
   131	#   d. `issue_url` took the first URL anywhere in the block, so a hook citing another repo or a
   132	#      PR in passing silently re-keyed the entry
   133	#   e. markdown task-list items (`- [ ]`) parsed as entries with an empty title
   134	cat > "$R/ROADMAP.md" <<'MD'
   135	# Review Regression Roadmap
   136	
   137	## Ledger
   138	
   139	### Queue / parked intake
   140	- [ ] a task-list checkbox that is not a ledger entry
   141	- [x] another checkbox that is not a ledger entry
   142	- [GH-500 — issue-linked bullet with no PDDA doc](https://github.com/ExternalOrg/CustomRepo/issues/500) - the link target is the issue itself, not a document.
   143	- [GH-501 — hook cites other work in passing](docs/plans/gh-501.md) - the canonical issue lived in [otherrepo#2](https://github.com/ExternalOrg/OtherRepo/issues/2) and it shipped via [#502](https://github.com/ExternalOrg/CustomRepo/pull/502).
   144	- [#503 — a hash-prefixed title is a real key](docs/plans/gh-503.md) - narrative body.
   145	### In progress
   146	- **Execution checklist for GH-500 + GH-501** — a bold title that MENTIONS issues it is not keyed by.
   147	- **#601/#602/#603 · umbrella wave heading** — names three issues; none of them is its key.
   148	- **GH-701..706 · umbrella wave range** — a dotted RANGE is six issues, not issue 701.
   149	- **GH-707 — 2026 planning cycle** — an em-dash before a number is NOT a range; this IS keyed.
   150	MD
   151	
   152	out="$(ra roadmap sync 2>&1)"; rc=$?
   153	ok "review-regression ledger syncs (rc=$rc)" "[ $rc -eq 0 ]"
   154	
   155	count6="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
   156	ok "  and task-list checkboxes are not entries (7 rows, not 9)" "[ \"$count6\" = '7' ]"
   157	
   158	box="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items WHERE title = '' OR title = 'x'")"
   159	ok "  and no empty-titled checkbox row was stored" "[ \"$box\" = '0' ]"
   160	
   161	mention="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'Execution checklist%'")"
   162	ok "  and a title that only MENTIONS GH-500/GH-501 is not keyed by either" "[ \"$mention\" = 'NULL' ]"
   163	
   164	umbrella="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE '#601%'")"
   165	ok "  and a multi-issue umbrella title carries no key" "[ \"$umbrella\" = 'NULL' ]"
   166	
   167	hash_key="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items WHERE gh_number = 503")"
   168	ok "  and a hash-prefixed single-issue title IS keyed" "[ \"$hash_key\" = '1' ]"
   169	
   170	rng="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-701%'")"
   171	ok "  and a dotted RANGE umbrella carries no key (agy QA)" "[ \"$rng\" = 'NULL' ]"
   172	
   173	dash="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-707%'")"
   174	ok "  but an em-dash before a number is NOT a range — that title keeps its key" "[ \"$dash\" = '707' ]"
   175	
   176	doc500="$(sqlite3 "$R/releases.db" "SELECT COALESCE(doc_path,'NULL') FROM roadmap_items WHERE gh_number=500")"
   177	ok "  and an issue-linked bullet leaves doc_path NULL, not a URL" "[ \"$doc500\" = 'NULL' ]"
   178	
   179	url500="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=500")"
   180	ok "  and that bullet's own link target becomes issue_url" "[ \"$url500\" = 'https://github.com/ExternalOrg/CustomRepo/issues/500' ]"
   181	
   182	url501="$(sqlite3 "$R/releases.db" "SELECT COALESCE(issue_url,'NULL') FROM roadmap_items WHERE gh_number=501")"
   183	ok "  and a hook citing a foreign repo/PR does not re-key the entry" "[ \"$url501\" = 'NULL' ]"
   184	
   185	doc501="$(sqlite3 "$R/releases.db" "SELECT doc_path FROM roadmap_items WHERE gh_number=501")"
   186	ok "  and its real doc_path still resolves" "[ \"$doc501\" = 'docs/plans/gh-501.md' ]"
   187	
   188	# ── 7. This repo's own ROADMAP.md still parses, with no duplicate keys ──────────────
   189	# The regression that made this review necessary: the widened key search created a second
   190	# GH-111 in XYZ-forge's own ledger, which `roadmap sync` refuses on outright.
   191	self_dup="$(python3 - "$ROOT_DIR" <<'PY'
   192	import collections, importlib.util, os, sys
   193	root = sys.argv[1]
   194	spec = importlib.util.spec_from_file_location("ra", os.path.join(root, "utils/py/releases_app.py"))
   195	m = importlib.util.module_from_spec(spec)
   196	sys.argv = ["ra"]
   197	try:
   198	    spec.loader.exec_module(m)
   199	except SystemExit:
   200	    pass
   201	e = m.parse_roadmap_ledger(os.path.join(root, "ROADMAP.md"))
   202	c = collections.Counter(x["gh_number"] for x in e if x["gh_number"])
   203	print("%d %s" % (len(e), ",".join(str(k) for k, v in sorted(c.items()) if v > 1) or "none"))
   204	PY
   205	)"
   206	ok "this repo's own ROADMAP.md parses a non-empty ledger" "[ \"${self_dup%% *}\" -gt 0 ]"
   207	ok "  and yields no duplicate GH keys (would refuse roadmap sync)" "[ \"${self_dup##* }\" = 'none' ]"
   208	
   209	
   210	# ── 8. codex QA regressions (second review, 2026-08-31) ─────────────────────────────
   211	# agy passed the branch; codex found two Majors it missed:
   212	#   a. an UNKEYED entry took the first URL on its first line as its own identity — on the real
   213	#      reporting ledger that stored a BLOCKER (#42) as "Grow Willies"'s issue_url
   214	#   b. an absolute `.md` URL bypassed the doc-pointer check entirely, because the extraction
   215	#      regex accepted any `.md`-suffixed target and the validator was only consulted on the
   216	#      fallback branch
   217	# Plus: en dash is a numeric range (em dash is not), and duplicate UNKEYED titles are ambiguous.
   218	cat > "$R/ROADMAP.md" <<'MD'
   219	# Codex Review Regression Roadmap
   220	
   221	## Ledger
   222	
   223	### Queue / parked intake
   224	- [An unkeyed entry blocked by another issue](docs/plans/unkeyed.md) - **BLOCKED** on [#42](https://github.com/ExternalOrg/CustomRepo/issues/42), which has its own ledger row.
   225	- [GH-800 — upstream design lives outside the repo](https://github.com/ExternalOrg/SpecRepo/blob/main/DESIGN.md) - an absolute URL is not a doc pointer.
   226	- [GH-801 — mail target](mailto:notes.md) - a scheme with no slashes is still a scheme.
   227	- [GH-802 — absolute path](/docs/plan.md) - leading slash is not repo-relative.
   228	- [GH-803 — anchored doc](docs/plans/gh-803.md#phase-2) - an anchor is stripped, the path survives.
   229	### In progress
   230	- **GH-804..809 · dotted range umbrella** — six issues, not issue 804.
   231	- **GH-810–815 · en dash range umbrella** — en dash is the numeric-range delimiter.
   232	- **GH-816 — 2026 planning cycle** — an EM dash before a year is not a range.
   233	MD
   234	
   235	out="$(ra roadmap sync 2>&1)"; rc=$?
   236	ok "codex-regression ledger syncs (rc=$rc)" "[ $rc -eq 0 ]"
   237	
   238	unkeyed="$(sqlite3 "$R/releases.db" "SELECT COALESCE(issue_url,'NULL') FROM roadmap_items WHERE title LIKE 'An unkeyed entry%'")"
   239	ok "  and an UNKEYED entry does not adopt a cited blocker as its identity" "[ \"$unkeyed\" = 'NULL' ]"
   240	
   241	doc800="$(sqlite3 "$R/releases.db" "SELECT COALESCE(doc_path,'NULL') FROM roadmap_items WHERE gh_number=800")"
   242	ok "  and an absolute .md URL never reaches doc_path" "[ \"$doc800\" = 'NULL' ]"
   243	
   244	url800="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=800")"
   245	ok "  and that entry keeps no issue_url either (the link is not an issue)" "[ -z \"$url800\" ]"
   246	
   247	doc801="$(sqlite3 "$R/releases.db" "SELECT COALESCE(doc_path,'NULL') FROM roadmap_items WHERE gh_number=801")"
   248	ok "  and a mailto: target is rejected (a scheme without // is still a scheme)" "[ \"$doc801\" = 'NULL' ]"
   249	
   250	doc802="$(sqlite3 "$R/releases.db" "SELECT COALESCE(doc_path,'NULL') FROM roadmap_items WHERE gh_number=802")"
   251	ok "  and a leading-slash absolute path is rejected" "[ \"$doc802\" = 'NULL' ]"
   252	
   253	doc803="$(sqlite3 "$R/releases.db" "SELECT doc_path FROM roadmap_items WHERE gh_number=803")"
   254	ok "  but a real relative doc survives, with its #anchor stripped" "[ \"$doc803\" = 'docs/plans/gh-803.md' ]"
   255	
   256	dotted="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-804%'")"
   257	ok "  and a dotted range umbrella carries no key" "[ \"$dotted\" = 'NULL' ]"
   258	
   259	endash="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-810%'")"
   260	ok "  and an EN DASH range umbrella carries no key (codex QA)" "[ \"$endash\" = 'NULL' ]"
   261	
   262	emdash="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-816%'")"
   263	ok "  but an EM DASH before a year is prose — that title keeps its key" "[ \"$emdash\" = '816' ]"
   264	
   265	# ── 9. Ambiguity and clearing refusals ──────────────────────────────────────────────
   266	cat > "$R/ROADMAP.md" <<'MD'
   267	# Ambiguous Roadmap
   268	
   269	## Ledger
   270	
   271	### Queue / parked intake
   272	- [A repeated unkeyed title](docs/a.md) - first occurrence.
   273	- [A repeated unkeyed title](docs/b.md) - second occurrence, same title.
   274	MD
   275	
   276	out="$(ra roadmap sync 2>&1)"; rc=$?
   277	ok "sync refuses two identical UNKEYED titles (rc=$rc)" "[ $rc -ne 0 ]"
   278	ok "  and cites rule=roadmap-duplicate-title" "has \"\$out\" 'rule=roadmap-duplicate-title'"
   279	
   280	# A genuinely empty ledger: still refuses by default, clears only with the explicit override.
   281	cat > "$R/ROADMAP.md" <<'MD'
   282	# Emptied Roadmap
   283	
   284	## Ledger
   285	
   286	### Queue / parked intake
   287	MD
   288	
   289	out="$(ra roadmap sync 2>&1)"; rc=$?
   290	ok "an empty ledger still REFUSES by default (rc=$rc)" "[ $rc -ne 0 ]"
   291	ok "  and the refusal names the --allow-empty escape hatch" "has \"\$out\" '--allow-empty'"
   292	
   293	before_empty="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
   294	ok "  and nothing was deleted" "[ \"$before_empty\" -gt 0 ]"
   295	
   296	out="$(ra roadmap sync --allow-empty 2>&1)"; rc=$?
   297	ok "--allow-empty clears the mirror when the ledger is genuinely empty (rc=$rc)" "[ $rc -eq 0 ]"
   298	after_empty="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
   299	ok "  and roadmap_items is now empty" "[ \"$after_empty\" = '0' ]"
   300	

exec
/bin/zsh -lc "rg -n -C 15 'def parse_roadmap_ledger|def cmd_roadmap_sync|roadmap-empty-parse|allow-empty|ROADMAP_BULLET|GH_URL|roadmap-duplicate' utils/py/releases_app.py
git show origin/development:utils/py/releases_app.py | rg -n -C 15 'def parse_roadmap_ledger|def cmd_roadmap_sync|roadmap-empty-parse|allow-empty|ROADMAP_BULLET|GH_URL|roadmap-duplicate'
git show origin/fix/gh351-gh349-releases-ledger-fixes:utils/py/releases_app.py | rg -n -C 15 'def parse_roadmap_ledger|def cmd_roadmap_sync|roadmap-empty-parse|allow-empty|ROADMAP_BULLET|GH_URL|roadmap-duplicate'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 4801ms:
2026-08-31 16:33:09.271 xcodebuild[75654:6480713]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:33:09.470 xcodebuild[75654:6480712] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-27jqu2k5' (errno=Operation not permitted)
2026-08-31 16:33:10.091 xcodebuild[75658:6480745]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:33:10.292 xcodebuild[75658:6480743] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
1469-           "%s manually" % (db_gen, jgen, journal_path))
1470-
1471-
1472-# ── legacy RELEASES.md parsing (import + drift) ─────────────────────────────────────────────────
1473-
1474-LABEL_RE = re.compile(r"^([A-Za-z][A-Za-z0-9 '&/_-]{0,48}):(?:[ \t](.*))?$")
1475-
1476-# Labels the v1 schema maps to columns. Everything else in a block — `Iterations:` bands (absent
1477-# from the schema BY DESIGN, aegis proved them harmful), `Manifest:` prose, `RC evidence:`,
1478-# `Post RC update:`, ad-hoc labels, and continuation paragraphs — is preserved VERBATIM, in
1479-# order, in legacy_lines until dispositioned. `Manifest-Members:` bare numbers stay legacy too:
1480-# they cannot be auto-converted to URLs offline (the rebalanceOS retired-tracker case is the
1481-# reason), and each becomes a grandfather entry awaiting disposition.
1482-MAPPED_LABELS = {
1483-    "Release", "Status", "Target Date", "Codename", "Description", "Exit criterion",
1484:    "GH_URL", "Milestone", "Front-door reviewed", "Shakedown reviewed", "License file",
1485-    "Shipped", "Tracking Issue",
1486-}
1487-UNMAPPED_LABELS = {"Iterations", "Manifest", "Manifest-Members", "RC evidence", "Post RC update"}
1488-
1489-
1490-def parse_legacy_ledger(path):
1491-    """Parse a RELEASES.md-format ledger. Returns (doc_lines, blocks): doc_lines is the verbatim
1492-    preamble (everything before the first `Release:` line); each block carries its mapped field
1493-    values (LAST occurrence wins, matching the awk consumers) and its extras — unmapped label
1494-    lines and continuation lines, verbatim, with their original line numbers as ordering."""
1495-    with open(path, encoding="utf-8") as fh:
1496-        lines = fh.read().split("\n")
1497-    doc, blocks = [], []
1498-    current = None
1499-    for idx, raw in enumerate(lines):
--
1566-            w("Target Date: %s" % rel["target_date"])
1567-        if rel["codename"]:
1568-            w("Codename: %s" % rel["codename"])
1569-        if rel["description"]:
1570-            w("Description: %s" % rel["description"])
1571-        if rel["exit_criterion"]:
1572-            w("Exit criterion: %s" % rel["exit_criterion"])
1573-        members = conn.execute("""SELECT t.url, t.temp_id FROM manifest_items mi
1574-                                  JOIN issue_refs t ON t.id = mi.issue_ref_id
1575-                                  WHERE mi.release_id = ? ORDER BY mi.id""",
1576-                               (rel["id"],)).fetchall()
1577-        if members:
1578-            nums = [ (m["url"] or "").rsplit("/", 1)[-1] or (m["temp_id"] or "?") for m in members ]
1579-            w("Manifest-Members: %s" % " ".join(nums))
1580-        if rel["gh_release_url"]:
1581:            w("GH_URL: %s" % rel["gh_release_url"])
1582-        if rel["tracking_url"]:
1583-            w("Tracking Issue: %s" % rel["tracking_url"])
1584-        elif rel["tracking_temp"]:
1585-            w("Tracking Issue: %s" % rel["tracking_temp"])
1586-        if rel["milestone"]:
1587-            w("Milestone: %s" % rel["milestone"])
1588-        if rel["front_door_reviewed"]:
1589-            w("Front-door reviewed: %s" % rel["front_door_reviewed"])
1590-        if rel["shakedown_reviewed"]:
1591-            w("Shakedown reviewed: %s" % rel["shakedown_reviewed"])
1592-        if rel["license_file"]:
1593-            w("License file: %s" % rel["license_file"])
1594-        for ll in conn.execute("""SELECT content FROM legacy_lines l
1595-                                  WHERE l.release_id = ? ORDER BY l.position""",
1596-                               (rel["id"],)).fetchall():
--
1866-
1867-                description = fv("Description")
1868-                if not (description or "").strip():
1869-                    description = "(imported without a Description; legacy block omitted it)"
1870-                    _grandfather(conn, import_run, gid, "description-default", None, description)
1871-
1872-                raw_target = fv("Target Date")
1873-                target_date = None
1874-                if raw_target is not None and raw_target.strip():
1875-                    if valid_date(raw_target.strip()):
1876-                        target_date = raw_target.strip()
1877-                    else:
1878-                        _grandfather(conn, import_run, gid, "target-date-invalid", raw_target, None)
1879-                        block["extras"].append((block["line"], "Target Date: %s" % raw_target))
1880-
1881:                gh_raw = fv("GH_URL")
1882-                gh_release_url = None
1883-                if gh_raw and gh_raw.strip():
1884-                    m = URL_EXTRACT_RE.search(gh_raw)
1885-                    if m:
1886-                        gh_release_url = m.group(0)
1887-                        if gh_release_url != gh_raw.strip():
1888-                            _grandfather(conn, import_run, gid, "gh-url-normalized", gh_raw,
1889-                                         gh_release_url)
1890-                    else:
1891-                        _grandfather(conn, import_run, gid, "gh-url-unparsed", gh_raw, None)
1892-
1893-                qa = {}
1894-                for label, column in (("Front-door reviewed", "front_door_reviewed"),
1895-                                      ("Shakedown reviewed", "shakedown_reviewed"),
1896-                                      ("License file", "license_file")):
--
2513-
2514-def cmd_show(args):
2515-    """Full record for ONE release — the detail reader `list` deliberately does not provide."""
2516-    root = resolve_root(args.root)
2517-    full = getattr(args, "full", False)
2518-    conn = connect(artifact_paths(root)["db"])
2519-    try:
2520-        rel = _resolve_one(conn, args.gid, args.version)
2521-        ref = conn.execute("SELECT url, temp_id FROM issue_refs WHERE id = ?",
2522-                           (rel["tracking_ref_id"],)).fetchone()
2523-        print("GID:           %s" % rel["global_id"])
2524-        print("Release:       %s" % (rel["version"] or "(unversioned)"))
2525-        print("Status:        %s" % rel["status"])
2526-        for label, key in (("Codename", "codename"), ("Target Date", "target_date"),
2527-                           ("Shipped", "shipped_date"), ("Milestone", "milestone"),
2528:                           ("GH_URL", "gh_release_url"), ("Description", "description"),
2529-                           ("Exit criterion", "exit_criterion"),
2530-                           ("Front-door reviewed", "front_door_reviewed"),
2531-                           ("Shakedown reviewed", "shakedown_reviewed"),
2532-                           ("License file", "license_file")):
2533-            if rel[key]:
2534-                print("%-14s %s" % (label + ":", _elide(rel[key], full)))
2535-        print("%-14s %s" % ("Tracking:", (ref["url"] or ref["temp_id"]) if ref else "-"))
2536-
2537-        items = conn.execute("""SELECT t.url, t.temp_id, mi.state FROM manifest_items mi
2538-                                JOIN issue_refs t ON t.id = mi.issue_ref_id
2539-                                WHERE mi.release_id = ? ORDER BY mi.id""",
2540-                             (rel["id"],)).fetchall()
2541-        print("Manifest:      %d item(s)" % len(items))
2542-        for it in items:
2543-            print("  - %s [%s]" % (it["url"] or it["temp_id"], it["state"]))
--
2793-    out = dict(zip(RATING_COLUMNS[:4], values))
2794-    out["rating_ovr"] = None
2795-    if ovr_tokens:
2796-        mo = _OVR_RE.search(raw)
2797-        if not mo:
2798-            refuse("ovr-shape", "%s carries an `ovr` token with no integer after it; %s"
2799-                   % (where, _RATING_GRAMMAR))
2800-        ovr = int(mo.group(1))
2801-        if not 4 <= ovr <= 400:
2802-            refuse("ovr-range", "%s overrides to %d; the override is on calc's own 4-400 scale"
2803-                   % (where, ovr))
2804-        out["rating_ovr"] = ovr
2805-    return out
2806-
2807-
2808:def parse_roadmap_ledger(path):
2809-    """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
2810-    from its `- **` line to the next `- **`, `###`, or `##`."""
2811-    lines = open(path, encoding="utf-8").read().splitlines()
2812-    entries = []
2813-    sec = None
2814-    inledger = False
2815-    pos = {}
2816-    i, n = 0, len(lines)
2817-    while i < n:
2818-        line = lines[i]
2819-        if re.match(r"^##\s+Ledger\s*$", line.strip()):
2820-            inledger = True
2821-            i += 1
2822-            continue
2823-        if inledger and re.match(r"^##\s+", line):
--
2917-        rating = parse_rating(raw_text, args.title)
2918-
2919-        if args.dry_run:
2920-            print("ROADMAP line: %s" % raw_text)
2921-            if rating["rating_pri"] is not None:
2922-                print("rating: %s" % "/".join(str(rating[c]) for c in RATING_COLUMNS[:4]))
2923-                if rating["rating_ovr"] is not None:
2924-                    print("ovr: %d" % rating["rating_ovr"])
2925-            return
2926-
2927-        # Dup guard — only when the shadow table exists; a pre-migration ledger gets the schema
2928-        # installed inside mutate (mirrors cmd_roadmap_sync) instead of a raw OperationalError.
2929-        if _table_exists(conn, "roadmap_items"):
2930-            row = conn.execute("SELECT id FROM roadmap_items WHERE issue_url = ?", (args.issue_url,)).fetchone()
2931-            if row:
2932:                refuse("roadmap-duplicate", "issue %s is already parked in the roadmap" % args.issue_url)
2933-
2934-            row2 = conn.execute("SELECT id FROM roadmap_items WHERE gh_number = ?", (args.issue_num,)).fetchone()
2935-            if row2:
2936:                refuse("roadmap-duplicate", "issue GH-%d is already parked in the roadmap" % args.issue_num)
2937-
2938-        gid = new_gid("rmi-")
2939-
2940-        def mutate(conn):
2941-            _ensure_roadmap_schema(conn)
2942-            ts = now_iso()
2943-            section = "Queue / parked intake"   # the canonical ledger queue heading (GH-243)
2944-            max_pos = conn.execute("SELECT MAX(position) FROM roadmap_items WHERE section = ?", (section,)).fetchone()
2945-            pos = (max_pos[0] or 0) + 1 if max_pos else 1
2946-            
2947-            repo = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()
2948-            if not repo:
2949-                refuse("no-repo", "the DB has no repos row; run `releases init` first")
2950-            
2951-            # Mirrors cmd_roadmap_sync: feature commands never self-migrate. A rated line meeting
--
3148-                        updates.append("%s = ?" % c)
3149-                        params.append(rating[c])
3150-            if args.section is not None:
3151-                updates.append("section = ?")
3152-                params.append(args.section)
3153-            
3154-            params.append(param)
3155-            conn.execute("UPDATE roadmap_items SET %s WHERE %s" % (", ".join(updates), where), params)
3156-
3157-        perform_write(root, conn, "roadmap-update", row["global_id"], mutate)
3158-        print("updated %s" % label)
3159-    finally:
3160-        conn.close()
3161-
3162-
3163:def cmd_roadmap_sync(args):
3164-    root = resolve_root(args.root)
3165-    # PR #240 review: sync mirrors ROADMAP.md and DELETES rows absent from it — in a releases-mode
3166-    # repo the DB is canonical and rows arrive via `roadmap add` with no markdown source line, so
3167-    # mirroring would destroy parked intake. Skip cleanly (exit 0): wave_reconcile.py calls sync
3168-    # unconditionally post-merge and must stay green in both modes.
3169-    try:
3170-        with open(os.path.join(root, ".pdda-mode")) as f:
3171-            if "ROADMAP_SOURCE=releases" in f.read():
3172-                print("roadmap sync: skipped — releases-mode repo (the DB is canonical; sync only "
3173-                      "mirrors ROADMAP.md in legacy mode, and would delete rows parked by `roadmap add`)")
3174-                return
3175-    except OSError:
3176-        pass
3177-    conn = connect(artifact_paths(root)["db"])
3178-    try:
3179-        md_path = os.path.join(root, ROADMAP_NAME)
3180-        if not os.path.exists(md_path):
3181-            refuse("roadmap-missing", "no %s at %s — nothing to shadow" % (ROADMAP_NAME, root))
3182-        parsed = parse_roadmap_ledger(md_path)
3183-        # duplicate GH keys in the markdown would make the mirror ambiguous — name it, do not pick
3184-        seen = {}
3185-        for e in parsed:
3186-            if e["gh_number"] is not None:
3187-                if e["gh_number"] in seen:
3188:                    refuse("roadmap-duplicate-gh",
3189-                           "GH-%d appears twice in %s (%r and %r). The mirror keys entries by GH "
3190-                           "number; merge or renumber one of them, then re-run."
3191-                           % (e["gh_number"], ROADMAP_NAME, seen[e["gh_number"]][:60],
3192-                              e["title"][:60]))
3193-                seen[e["gh_number"]] = e["title"]
3194-
3195-        repo = conn.execute("SELECT id, global_id FROM repos ORDER BY id LIMIT 1").fetchone()
3196-        if repo is None:
3197-            refuse("no-repo", "the DB has no repos row; run `releases init` first")
3198-
3199-        # GH-108/GH-111: feature commands do NOT self-migrate. Rating storage arrives through
3200-        # `releases migrate` (migration 003); sync refuses clearly when a rated entry meets a
3201-        # ledger that cannot hold it, rather than installing schema of its own or — worse —
3202-        # writing the entry with its scores silently dropped.
3203-        rating_ok = _has_column(conn, "roadmap_items", "rating_pri")
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-PgEdHHRd' (errno=Operation not permitted)
2026-08-31 16:33:11.696 xcodebuild[75664:6480769]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:33:11.900 xcodebuild[75664:6480768] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-wJRFRRdn' (errno=Operation not permitted)
2026-08-31 16:33:12.527 xcodebuild[75670:6480829]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:33:12.722 xcodebuild[75670:6480826] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
1551-           "%s manually" % (db_gen, jgen, journal_path))
1552-
1553-
1554-# ── legacy RELEASES.md parsing (import + drift) ─────────────────────────────────────────────────
1555-
1556-LABEL_RE = re.compile(r"^([A-Za-z][A-Za-z0-9 '&/_-]{0,48}):(?:[ \t](.*))?$")
1557-
1558-# Labels the v1 schema maps to columns. Everything else in a block — `Iterations:` bands (absent
1559-# from the schema BY DESIGN, aegis proved them harmful), `Manifest:` prose, `RC evidence:`,
1560-# `Post RC update:`, ad-hoc labels, and continuation paragraphs — is preserved VERBATIM, in
1561-# order, in legacy_lines until dispositioned. `Manifest-Members:` bare numbers stay legacy too:
1562-# they cannot be auto-converted to URLs offline (the rebalanceOS retired-tracker case is the
1563-# reason), and each becomes a grandfather entry awaiting disposition.
1564-MAPPED_LABELS = {
1565-    "Release", "Status", "Target Date", "Codename", "Description", "Exit criterion",
1566:    "GH_URL", "Milestone", "Front-door reviewed", "Shakedown reviewed", "License file",
1567-    "Shipped", "Tracking Issue",
1568-}
1569-UNMAPPED_LABELS = {"Iterations", "Manifest", "Manifest-Members", "RC evidence", "Post RC update"}
1570-
1571-
1572-def parse_legacy_ledger(path):
1573-    """Parse a RELEASES.md-format ledger. Returns (doc_lines, blocks): doc_lines is the verbatim
1574-    preamble (everything before the first `Release:` line); each block carries its mapped field
1575-    values (LAST occurrence wins, matching the awk consumers) and its extras — unmapped label
1576-    lines and continuation lines, verbatim, with their original line numbers as ordering."""
1577-    with open(path, encoding="utf-8") as fh:
1578-        lines = fh.read().split("\n")
1579-    doc, blocks = [], []
1580-    current = None
1581-    for idx, raw in enumerate(lines):
--
1648-            w("Target Date: %s" % rel["target_date"])
1649-        if rel["codename"]:
1650-            w("Codename: %s" % rel["codename"])
1651-        if rel["description"]:
1652-            w("Description: %s" % rel["description"])
1653-        if rel["exit_criterion"]:
1654-            w("Exit criterion: %s" % rel["exit_criterion"])
1655-        members = conn.execute("""SELECT t.url, t.temp_id FROM manifest_items mi
1656-                                  JOIN issue_refs t ON t.id = mi.issue_ref_id
1657-                                  WHERE mi.release_id = ? ORDER BY mi.id""",
1658-                               (rel["id"],)).fetchall()
1659-        if members:
1660-            nums = [ (m["url"] or "").rsplit("/", 1)[-1] or (m["temp_id"] or "?") for m in members ]
1661-            w("Manifest-Members: %s" % " ".join(nums))
1662-        if rel["gh_release_url"]:
1663:            w("GH_URL: %s" % rel["gh_release_url"])
1664-        if rel["tracking_url"]:
1665-            w("Tracking Issue: %s" % rel["tracking_url"])
1666-        elif rel["tracking_temp"]:
1667-            w("Tracking Issue: %s" % rel["tracking_temp"])
1668-        if rel["milestone"]:
1669-            w("Milestone: %s" % rel["milestone"])
1670-        if rel["front_door_reviewed"]:
1671-            w("Front-door reviewed: %s" % rel["front_door_reviewed"])
1672-        if rel["shakedown_reviewed"]:
1673-            w("Shakedown reviewed: %s" % rel["shakedown_reviewed"])
1674-        if rel["license_file"]:
1675-            w("License file: %s" % rel["license_file"])
1676-        for ll in conn.execute("""SELECT content FROM legacy_lines l
1677-                                  WHERE l.release_id = ? ORDER BY l.position""",
1678-                               (rel["id"],)).fetchall():
--
1975-
1976-                description = fv("Description")
1977-                if not (description or "").strip():
1978-                    description = "(imported without a Description; legacy block omitted it)"
1979-                    _grandfather(conn, import_run, gid, "description-default", None, description)
1980-
1981-                raw_target = fv("Target Date")
1982-                target_date = None
1983-                if raw_target is not None and raw_target.strip():
1984-                    if valid_date(raw_target.strip()):
1985-                        target_date = raw_target.strip()
1986-                    else:
1987-                        _grandfather(conn, import_run, gid, "target-date-invalid", raw_target, None)
1988-                        block["extras"].append((block["line"], "Target Date: %s" % raw_target))
1989-
1990:                gh_raw = fv("GH_URL")
1991-                gh_release_url = None
1992-                if gh_raw and gh_raw.strip():
1993-                    m = URL_EXTRACT_RE.search(gh_raw)
1994-                    if m:
1995-                        gh_release_url = m.group(0)
1996-                        if gh_release_url != gh_raw.strip():
1997-                            _grandfather(conn, import_run, gid, "gh-url-normalized", gh_raw,
1998-                                         gh_release_url)
1999-                    else:
2000-                        _grandfather(conn, import_run, gid, "gh-url-unparsed", gh_raw, None)
2001-
2002-                qa = {}
2003-                for label, column in (("Front-door reviewed", "front_door_reviewed"),
2004-                                      ("Shakedown reviewed", "shakedown_reviewed"),
2005-                                      ("License file", "license_file")):
--
2765-
2766-def cmd_show(args):
2767-    """Full record for ONE release — the detail reader `list` deliberately does not provide."""
2768-    root = resolve_root(args.root)
2769-    full = getattr(args, "full", False)
2770-    conn = connect(artifact_paths(root)["db"])
2771-    try:
2772-        rel = _resolve_one(conn, args.gid, args.version)
2773-        ref = conn.execute("SELECT url, temp_id FROM issue_refs WHERE id = ?",
2774-                           (rel["tracking_ref_id"],)).fetchone()
2775-        print("GID:           %s" % rel["global_id"])
2776-        print("Release:       %s" % (rel["version"] or "(unversioned)"))
2777-        print("Status:        %s" % rel["status"])
2778-        for label, key in (("Codename", "codename"), ("Target Date", "target_date"),
2779-                           ("Shipped", "shipped_date"), ("Milestone", "milestone"),
2780:                           ("GH_URL", "gh_release_url"), ("Description", "description"),
2781-                           ("Exit criterion", "exit_criterion"),
2782-                           ("Front-door reviewed", "front_door_reviewed"),
2783-                           ("Shakedown reviewed", "shakedown_reviewed"),
2784-                           ("License file", "license_file")):
2785-            if rel[key]:
2786-                print("%-14s %s" % (label + ":", _elide(rel[key], full)))
2787-        print("%-14s %s" % ("Tracking:", (ref["url"] or ref["temp_id"]) if ref else "-"))
2788-
2789-        items = conn.execute("""SELECT t.url, t.temp_id, mi.state FROM manifest_items mi
2790-                                JOIN issue_refs t ON t.id = mi.issue_ref_id
2791-                                WHERE mi.release_id = ? ORDER BY mi.id""",
2792-                             (rel["id"],)).fetchall()
2793-        print("Manifest:      %d item(s)" % len(items))
2794-        for it in items:
2795-            print("  - %s [%s]" % (it["url"] or it["temp_id"], it["state"]))
--
3055-    out = dict(zip(RATING_COLUMNS[:4], values))
3056-    out["rating_ovr"] = None
3057-    if ovr_tokens:
3058-        mo = _OVR_RE.search(raw)
3059-        if not mo:
3060-            refuse("ovr-shape", "%s carries an `ovr` token with no integer after it; %s"
3061-                   % (where, _RATING_GRAMMAR))
3062-        ovr = int(mo.group(1))
3063-        if not 4 <= ovr <= 400:
3064-            refuse("ovr-range", "%s overrides to %d; the override is on calc's own 4-400 scale"
3065-                   % (where, ovr))
3066-        out["rating_ovr"] = ovr
3067-    return out
3068-
3069-
3070:def parse_roadmap_ledger(path):
3071-    """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
3072-    from its bullet line (`- **`, `- [`, `- `) to the next `- `, `###`, or `##`."""
3073-    lines = open(path, encoding="utf-8").read().splitlines()
3074-    entries = []
3075-    sec = None
3076-    has_ledger_header = any(re.match(r"^##\s+Ledger\s*$", l.strip()) for l in lines)
3077-    inledger = not has_ledger_header
3078-    pos = {}
3079-    i, n = 0, len(lines)
3080-    while i < n:
3081-        line = lines[i]
3082-        if has_ledger_header and re.match(r"^##\s+Ledger\s*$", line.strip()):
3083-            inledger = True
3084-            i += 1
3085-            continue
--
3187-        rating = parse_rating(raw_text, args.title)
3188-
3189-        if args.dry_run:
3190-            print("ROADMAP line: %s" % raw_text)
3191-            if rating["rating_pri"] is not None:
3192-                print("rating: %s" % "/".join(str(rating[c]) for c in RATING_COLUMNS[:4]))
3193-                if rating["rating_ovr"] is not None:
3194-                    print("ovr: %d" % rating["rating_ovr"])
3195-            return
3196-
3197-        # Dup guard — only when the shadow table exists; a pre-migration ledger gets the schema
3198-        # installed inside mutate (mirrors cmd_roadmap_sync) instead of a raw OperationalError.
3199-        if _table_exists(conn, "roadmap_items"):
3200-            row = conn.execute("SELECT id FROM roadmap_items WHERE issue_url = ?", (args.issue_url,)).fetchone()
3201-            if row:
3202:                refuse("roadmap-duplicate", "issue %s is already parked in the roadmap" % args.issue_url)
3203-
3204-            row2 = conn.execute("SELECT id FROM roadmap_items WHERE gh_number = ?", (args.issue_num,)).fetchone()
3205-            if row2:
3206:                refuse("roadmap-duplicate", "issue GH-%d is already parked in the roadmap" % args.issue_num)
3207-
3208-        gid = new_gid("rmi-")
3209-
3210-        def mutate(conn):
3211-            _ensure_roadmap_schema(conn)
3212-            ts = now_iso()
3213-            section = "Queue / parked intake"   # the canonical ledger queue heading (GH-243)
3214-            max_pos = conn.execute("SELECT MAX(position) FROM roadmap_items WHERE section = ?", (section,)).fetchone()
3215-            pos = (max_pos[0] or 0) + 1 if max_pos else 1
3216-            
3217-            repo = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()
3218-            if not repo:
3219-                refuse("no-repo", "the DB has no repos row; run `releases init` first")
3220-            
3221-            # Mirrors cmd_roadmap_sync: feature commands never self-migrate. A rated line meeting
--
3418-                        updates.append("%s = ?" % c)
3419-                        params.append(rating[c])
3420-            if args.section is not None:
3421-                updates.append("section = ?")
3422-                params.append(args.section)
3423-            
3424-            params.append(param)
3425-            conn.execute("UPDATE roadmap_items SET %s WHERE %s" % (", ".join(updates), where), params)
3426-
3427-        perform_write(root, conn, "roadmap-update", row["global_id"], mutate)
3428-        print("updated %s" % label)
3429-    finally:
3430-        conn.close()
3431-
3432-
3433:def cmd_roadmap_sync(args):
3434-    root = resolve_root(args.root)
3435-    # PR #240 review: sync mirrors ROADMAP.md and DELETES rows absent from it — in a releases-mode
3436-    # repo the DB is canonical and rows arrive via `roadmap add` with no markdown source line, so
3437-    # mirroring would destroy parked intake. Skip cleanly (exit 0): wave_reconcile.py calls sync
3438-    # unconditionally post-merge and must stay green in both modes.
3439-    try:
3440-        with open(os.path.join(root, ".pdda-mode")) as f:
3441-            if "ROADMAP_SOURCE=releases" in f.read():
3442-                print("roadmap sync: skipped — releases-mode repo (the DB is canonical; sync only "
3443-                      "mirrors ROADMAP.md in legacy mode, and would delete rows parked by `roadmap add`)")
3444-                return
3445-    except OSError:
3446-        pass
3447-    conn = connect(artifact_paths(root)["db"])
3448-    try:
--
3450-        if not os.path.exists(md_path):
3451-            refuse("roadmap-missing", "no %s at %s — nothing to shadow" % (ROADMAP_NAME, root))
3452-        parsed = parse_roadmap_ledger(md_path)
3453-        if len(parsed) == 0:
3454-            with open(md_path, encoding="utf-8") as f:
3455-                content = f.read().strip()
3456-            if content:
3457-                refuse("roadmap-empty",
3458-                       "parsed 0 entries from non-empty %s; refusing sync to prevent accidental "
3459-                       "wipe of roadmap_items" % ROADMAP_NAME)
3460-        # duplicate GH keys in the markdown would make the mirror ambiguous — name it, do not pick
3461-        seen = {}
3462-        for e in parsed:
3463-            if e["gh_number"] is not None:
3464-                if e["gh_number"] in seen:
3465:                    refuse("roadmap-duplicate-gh",
3466-                           "GH-%d appears twice in %s (%r and %r). The mirror keys entries by GH "
3467-                           "number; merge or renumber one of them, then re-run."
3468-                           % (e["gh_number"], ROADMAP_NAME, seen[e["gh_number"]][:60],
3469-                              e["title"][:60]))
3470-                seen[e["gh_number"]] = e["title"]
3471-
3472-        repo = conn.execute("SELECT id, global_id FROM repos ORDER BY id LIMIT 1").fetchone()
3473-        if repo is None:
3474-            refuse("no-repo", "the DB has no repos row; run `releases init` first")
3475-
3476-        # GH-108/GH-111: feature commands do NOT self-migrate. Rating storage arrives through
3477-        # `releases migrate` (migration 003); sync refuses clearly when a rated entry meets a
3478-        # ledger that cannot hold it, rather than installing schema of its own or — worse —
3479-        # writing the entry with its scores silently dropped.
3480-        rating_ok = _has_column(conn, "roadmap_items", "rating_pri")

codex
I’ve confirmed the candidates diverge in more than syntax: A adds title-key ambiguity protection and a narrowly defined empty-ledger override, while B broadens the parser to any top-level `- ` bullet. I’m now running both modules in memory against the real corpora and a controlled edge-case matrix.
exec
/bin/zsh -lc "python3 -c 'import collections,os,subprocess,sys,types
root=os.getcwd()
def source(ref): return subprocess.check_output([\"git\",\"show\",ref+\":utils/py/releases_app.py\"],text=True)
def load(name,src):
 m=types.ModuleType(name);m.__file__=name+\".py\";old=sys.argv;sys.argv=[name]
 try: exec(compile(src,m.__file__,\"exec\"),m.__dict__)
 except SystemExit: pass
 finally: sys.argv=old
 return m
mods={\"base\":load(\"base\",source(\"origin/development\")),\"A\":load(\"A\",open(\"utils/py/releases_app.py\").read()),\"B\":load(\"B\",source(\"origin/fix/gh351-gh349-releases-ledger-fixes\"))}
foreign=\"/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md\"
for label,path in [(\"own\",\"ROADMAP.md\"),(\"foreign\",foreign)]:
 print(\"\\\\nCORPUS\",label,path)
 for tag,m in mods.items():
  es=m.parse_roadmap_ledger(path);cnt=collections.Counter(e[\"gh_number\"] for e in es if e[\"gh_number\"] is not None)
  badpath=[(e[\"title\"],e[\"doc_path\"]) for e in es if e[\"doc_path\"] and (e[\"doc_path\"].startswith(\"/\") or \"://\" in e[\"doc_path\"] or e[\"doc_path\"].startswith(\"mailto:\"))]
  mismatch=[]
  for e in es:
   if e[\"issue_url\"]:
    n=int(e[\"issue_url\"].rstrip(\"/\").rsplit(\"/\",1)[-1])
    if e[\"gh_number\"] "'!= n:mismatch.append((e["title"],e["gh_number"],e["issue_url"]))
  junk=[(e["title"],e["raw_text"].splitlines()[0]) for e in es if not e["title"].strip() or e["title"].strip() in ("x","X","[]")]
  print(tag,"entries",len(es),"dups",{k:v for k,v in cnt.items() if v>1},"badpath",len(badpath),"mismatch",len(mismatch),"junk",junk)
  for x in badpath[:5]:print("  badpath",x)
  for x in mismatch[:5]:print("  mismatch",x)
base=mods["base"].parse_roadmap_ledger("ROADMAP.md")
for tag in "AB":
 oth=mods[tag].parse_roadmap_ledger("ROADMAP.md");print("'"\\\\nDIFF base ->\",tag,\"counts\",len(base),len(oth))
 for i in range(max(len(base),len(oth))):
  x=base[i] if i<len(base) else None;y=oth[i] if i<len(oth) else None
  if x"'!=y:
   print("idx",i+1,"BASE",{k:x.get(k) for k in ("title","gh_number","doc_path","issue_url","section")} if x else None)
   print("     "+tag,{k:y.get(k) for k in ("title","gh_number","doc_path","issue_url","section")} if y else None)'"'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 5018ms:
2026-08-31 16:33:53.882 xcodebuild[75853:6482470]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:33:54.148 xcodebuild[75853:6482469] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-EBODVMfn' (errno=Operation not permitted)
2026-08-31 16:33:54.810 xcodebuild[75855:6482508]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:33:55.003 xcodebuild[75855:6482506] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-mIIiOtuc' (errno=Operation not permitted)
2026-08-31 16:33:56.442 xcodebuild[75864:6482581]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:33:56.639 xcodebuild[75864:6482580] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-ICnDmZqr' (errno=Operation not permitted)
2026-08-31 16:33:57.246 xcodebuild[75866:6482590]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:33:57.442 xcodebuild[75866:6482589] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
\nCORPUS own ROADMAP.md
base entries 73 dups {} badpath 0 mismatch 3 junk []
  mismatch ('GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)', 61, 'https://github.com/HiQS-Labs/XYZ-forge/issues/62')
  mismatch ('#129/#130/#131 · Wave 1 of the Harness Driver & Relay Seam Hardening marathon — three preflighted driver/relay fixes', None, 'https://github.com/HiQS-Labs/XYZ-forge/issues/129')
  mismatch ('Execution checklist for GH-111 + GH-108', None, 'https://github.com/HiQS-Labs/XYZ-forge/issues/111')
A entries 73 dups {} badpath 0 mismatch 0 junk []
B entries 73 dups {111: 2} badpath 0 mismatch 1 junk []
  mismatch ('GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)', 61, 'https://github.com/HiQS-Labs/XYZ-forge/issues/62')
\nCORPUS foreign /Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md
base entries 0 dups {} badpath 0 mismatch 0 junk []
A entries 51 dups {199: 2} badpath 0 mismatch 0 junk []
B entries 52 dups {199: 2} badpath 0 mismatch 5 junk []
  mismatch ('Release 1.3.5x — Late July 2026', None, 'https://github.com/BinoidCBD/LTVera-Pandas/issues/79')
  mismatch ('GH-94 — Nexmail contract gap analysis', 94, 'https://github.com/BinoidCBD/nexmail-ltvera-connector/issues/2')
  mismatch ('Grow Willies — Tier-1 Shopify tenant onboarding', None, 'https://github.com/BinoidCBD/LTVera-Pandas/issues/42')
  mismatch ('Marathon Plan 2026-07-07 — connector/seed dogfood bugs + #47', None, 'https://github.com/BinoidCBD/LTVera-Pandas/issues/47')
  mismatch ('GH-68 — pgvector in Postgres + semantic cross-sell for Bounce', 68, 'https://github.com/BinoidCBD/LTVera-Pandas/pull/69')
\nDIFF base -> A counts 73 73
idx 8 BASE {'title': 'GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)', 'gh_number': 61, 'doc_path': None, 'issue_url': 'https://github.com/HiQS-Labs/XYZ-forge/issues/62', 'section': 'Queue / parked intake'}
     A {'title': 'GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)', 'gh_number': 61, 'doc_path': None, 'issue_url': 'https://github.com/HiQS-Labs/XYZ-forge/issues/61', 'section': 'Queue / parked intake'}
idx 57 BASE {'title': 'GH-135..140 · Wave-1 follow-ups: consult preflight verdict, attempts-gate root, suite registration, twin-divergence record, SIGPIPE sweep+guard, utcnow swap', 'gh_number': 135, 'doc_path': 'PROJECT/3-COMPLETED/GH-135-CONSULT-AGY-PREFLIGHT.md', 'issue_url': None, 'section': 'Completed'}
     A {'title': 'GH-135..140 · Wave-1 follow-ups: consult preflight verdict, attempts-gate root, suite registration, twin-divergence record, SIGPIPE sweep+guard, utcnow swap', 'gh_number': None, 'doc_path': 'PROJECT/3-COMPLETED/GH-135-CONSULT-AGY-PREFLIGHT.md', 'issue_url': None, 'section': 'Completed'}
idx 58 BASE {'title': '#129/#130/#131 · Wave 1 of the Harness Driver & Relay Seam Hardening marathon — three preflighted driver/relay fixes', 'gh_number': None, 'doc_path': None, 'issue_url': 'https://github.com/HiQS-Labs/XYZ-forge/issues/129', 'section': 'Completed'}
     A {'title': '#129/#130/#131 · Wave 1 of the Harness Driver & Relay Seam Hardening marathon — three preflighted driver/relay fixes', 'gh_number': None, 'doc_path': None, 'issue_url': None, 'section': 'Completed'}
idx 61 BASE {'title': 'Execution checklist for GH-111 + GH-108', 'gh_number': None, 'doc_path': 'PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md', 'issue_url': 'https://github.com/HiQS-Labs/XYZ-forge/issues/111', 'section': 'Completed'}
     A {'title': 'Execution checklist for GH-111 + GH-108', 'gh_number': None, 'doc_path': 'PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md', 'issue_url': None, 'section': 'Completed'}
\nDIFF base -> B counts 73 73
idx 58 BASE {'title': '#129/#130/#131 · Wave 1 of the Harness Driver & Relay Seam Hardening marathon — three preflighted driver/relay fixes', 'gh_number': None, 'doc_path': None, 'issue_url': 'https://github.com/HiQS-Labs/XYZ-forge/issues/129', 'section': 'Completed'}
     B {'title': '#129/#130/#131 · Wave 1 of the Harness Driver & Relay Seam Hardening marathon — three preflighted driver/relay fixes', 'gh_number': 129, 'doc_path': None, 'issue_url': 'https://github.com/HiQS-Labs/XYZ-forge/issues/129', 'section': 'Completed'}
idx 61 BASE {'title': 'Execution checklist for GH-111 + GH-108', 'gh_number': None, 'doc_path': 'PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md', 'issue_url': 'https://github.com/HiQS-Labs/XYZ-forge/issues/111', 'section': 'Completed'}
     B {'title': 'Execution checklist for GH-111 + GH-108', 'gh_number': 111, 'doc_path': 'PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md', 'issue_url': 'https://github.com/HiQS-Labs/XYZ-forge/issues/111', 'section': 'Completed'}

exec
/bin/zsh -lc "nl -ba utils/py/releases_app.py | sed -n '2810,3025p'
git show origin/fix/gh351-gh349-releases-ledger-fixes:utils/py/releases_app.py | nl -ba | sed -n '2980,3200p'
git show origin/development:utils/py/releases_app.py | nl -ba | sed -n '2760,2935p'
nl -ba test/gh349-releases-roadmap-vendored.sh | sed -n '125,340p'
git show origin/fix/gh351-gh349-releases-ledger-fixes:test/gh349-vendored-roadmap-ledger.sh | nl -ba | sed -n '1,210p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 7254ms:
2026-08-31 16:34:11.402 xcodebuild[75905:6483007]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:11.600 xcodebuild[75905:6483006] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-8AauyUut' (errno=Operation not permitted)
2026-08-31 16:34:12.228 xcodebuild[75911:6483037]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:12.420 xcodebuild[75911:6483036] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
  2980	# Canonicality: `rated` is the canonical rating vocabulary across all installs (vendored or central).
  2981	# The legacy triple `cx/risk/eff` (complexity/risk/effort) is deprecated and cannot be combined
  2982	# with `rated` on the same entry.
  2983	#
  2984	# The refusal contract matters as much as the grammar: the PRESENCE of a `rated` or `ovr` token
  2985	# either parses as the full form or refuses with a named rule. A malformed shape must never read
  2986	# as "unrated" — that would silently drop an operator's prioritisation and look like they never
  2987	# scored the task.
  2988	# The TOKEN test requires a digit after the word, so ordinary prose ("a highly rated entry",
  2989	# "underrated") is not mistaken for a score — while a genuinely malformed `rated 70/40/55` still
  2990	# counts as a token and is refused rather than read as unrated.
  2991	_RATED_TOKEN_RE = re.compile(r"\brated\s+\d")
  2992	# The DUPLICATE test is deliberately NARROWER than the presence test: it counts only
  2993	# slash-bearing matches. "the rated 3rd priority item ... rated 90/90/90/90" is ONE rating
  2994	# beside prose, and refusing it as a duplicate rejects a correctly-scored entry
  2995	# (aider/qwen3.8-max QA r1, [Should] #1 — reproduced before fixing). The PRESENCE test stays
  2996	# broad on purpose: a bare `rated 70` is a truncated score, and reading it as "unrated" would
  2997	# be exactly the silent drop this contract exists to prevent. Prose shaped "rated <int> <word>"
  2998	# with no real score beside it therefore still refuses — loudly, and fixable in one edit, which
  2999	# is the trade this repo prefers over an invisible drop.
  3000	_RATED_SCORE_TOKEN_RE = re.compile(r"\brated\s+\d+/")
  3001	_RATED_RE = re.compile(r"\brated\s+(\d+)/(\d+)/(\d+)/(\d+)(?![\w/])")
  3002	# `ovr` requires a DIGIT, not merely a following token. Unbackticked prose — "the ovr wins over
  3003	# calc" — otherwise refuses an entry carrying a perfectly good rating (aider/qwen3.8-max QA r1,
  3004	# [Should] #2 — reproduced before fixing). The asymmetry with `rated` above is deliberate and is
  3005	# what makes it safe: the override is OPTIONAL, so a dropped `ovr` degrades to "no override"
  3006	# while the four axes still land, whereas a dropped `rated` loses the whole score. A real typo
  3007	# is still caught, because the SHAPE test needs the integer to end cleanly: `ovr 35O` matches
  3008	# the token and then fails the shape.
  3009	_OVR_TOKEN_RE = re.compile(r"\bovr\s+\d")
  3010	_OVR_RE = re.compile(r"\bovr\s+(\d+)(?![\w/])")
  3011	_LEGACY_CRE_RE = re.compile(r"cx/risk/eff (\d+)/(\d+)/(\d+)")
  3012	
  3013	_RATING_GRAMMAR = "the grammar is `rated N/N/N/N` (pri/sev/appeal/effort, 1-100) with an " \
  3014	                  "optional ` ovr N` (4-400)"
  3015	
  3016	
  3017	def parse_rating(raw, title):
  3018	    """Parse the rating tokens out of one ROADMAP entry. Returns the five column values."""
  3019	    blank = dict.fromkeys(RATING_COLUMNS)
  3020	    rated_tokens = _RATED_TOKEN_RE.findall(raw)
  3021	    ovr_tokens = _OVR_TOKEN_RE.findall(raw)
  3022	    if not rated_tokens and not ovr_tokens:
  3023	        return blank
  3024	    where = "entry %r" % title[:60]
  3025	
  3026	    if _LEGACY_CRE_RE.search(raw) and rated_tokens:
  3027	        refuse("rating-vocabulary-clash",
  3028	               "%s carries BOTH `cx/risk/eff` and `rated`. The two vocabularies measure different "
  3029	               "things and never share a row; convert the entry to `rated` and delete the legacy "
  3030	               "triple." % where)
  3031	    score_tokens = _RATED_SCORE_TOKEN_RE.findall(raw)
  3032	    if len(score_tokens) > 1:
  3033	        refuse("rating-duplicate", "%s carries %d `rated` scores; exactly one is allowed"
  3034	               % (where, len(score_tokens)))
  3035	    if len(ovr_tokens) > 1:
  3036	        refuse("ovr-duplicate", "%s carries %d `ovr` tokens; at most one is allowed"
  3037	               % (where, len(ovr_tokens)))
  3038	    if ovr_tokens and not rated_tokens:
  3039	        refuse("ovr-orphan",
  3040	               "%s carries `ovr` with no `rated` scores. The override replaces the computed score "
  3041	               "for ranking; it does not stand in for the four axes, which keep their honest "
  3042	               "values underneath. %s" % (where, _RATING_GRAMMAR))
  3043	
  3044	    m = _RATED_RE.search(raw)
  3045	    if not m:
  3046	        refuse("rating-shape",
  3047	               "%s carries a `rated` token that does not parse — %s. A malformed rating is refused "
  3048	               "rather than read as unrated, so a mistyped score is never silently dropped."
  3049	               % (where, _RATING_GRAMMAR))
  3050	    values = [int(g) for g in m.groups()]
  3051	    for axis, value in zip(("pri", "sev", "appeal", "effort"), values):
  3052	        if not 1 <= value <= 100:
  3053	            refuse("rating-range", "%s scores %s at %d; every axis is 1-100 (100 = strongest, "
  3054	                                   "effort included — it scores cheapness)" % (where, axis, value))
  3055	    out = dict(zip(RATING_COLUMNS[:4], values))
  3056	    out["rating_ovr"] = None
  3057	    if ovr_tokens:
  3058	        mo = _OVR_RE.search(raw)
  3059	        if not mo:
  3060	            refuse("ovr-shape", "%s carries an `ovr` token with no integer after it; %s"
  3061	                   % (where, _RATING_GRAMMAR))
  3062	        ovr = int(mo.group(1))
  3063	        if not 4 <= ovr <= 400:
  3064	            refuse("ovr-range", "%s overrides to %d; the override is on calc's own 4-400 scale"
  3065	                   % (where, ovr))
  3066	        out["rating_ovr"] = ovr
  3067	    return out
  3068	
  3069	
  3070	def parse_roadmap_ledger(path):
  3071	    """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
  3072	    from its bullet line (`- **`, `- [`, `- `) to the next `- `, `###`, or `##`."""
  3073	    lines = open(path, encoding="utf-8").read().splitlines()
  3074	    entries = []
  3075	    sec = None
  3076	    has_ledger_header = any(re.match(r"^##\s+Ledger\s*$", l.strip()) for l in lines)
  3077	    inledger = not has_ledger_header
  3078	    pos = {}
  3079	    i, n = 0, len(lines)
  3080	    while i < n:
  3081	        line = lines[i]
  3082	        if has_ledger_header and re.match(r"^##\s+Ledger\s*$", line.strip()):
  3083	            inledger = True
  3084	            i += 1
  3085	            continue
  3086	        if has_ledger_header and inledger and re.match(r"^##\s+", line):
  3087	            break
  3088	        if inledger and line.startswith("### "):
  3089	            sec = line[4:].strip()
  3090	            i += 1
  3091	            continue
  3092	        if inledger and sec and (line.startswith("- **") or line.startswith("- [") or line.startswith("- ")):
  3093	            j = i + 1
  3094	            while j < n and not (lines[j].startswith("- ") or lines[j].startswith("### ")
  3095	                                 or re.match(r"^##\s+", lines[j])):
  3096	                j += 1
  3097	            raw = "\n".join(lines[i:j]).rstrip()
  3098	            m_bold = re.match(r"^- \*\*(.+?)\*\*", raw)
  3099	            m_link = re.match(r"^- \[(.+?)\]", raw)
  3100	            if m_bold:
  3101	                title = m_bold.group(1).strip()
  3102	            elif m_link:
  3103	                title = m_link.group(1).strip()
  3104	            else:
  3105	                m_plain = re.match(r"^- (.+)", raw)
  3106	                title = m_plain.group(1).strip() if m_plain else raw[2:80]
  3107	            gh = re.match(r"^(?:GH-|#)(\d+)\b", title) or re.search(r"\b(?:GH-|#)(\d+)\b", title)
  3108	            marker = None
  3109	            for cand in _ROADMAP_STATUS_MARKERS:
  3110	                if cand in raw:
  3111	                    marker = cand
  3112	                    break
  3113	            cre = re.search(r"cx/risk/eff (\d+)/(\d+)/(\d+)", raw)
  3114	            doc = re.search(r"\]\((PROJECT/[^)]+\.md)", raw) or re.search(r"\((PROJECT/[^)]+\.md)\)", raw) or re.search(r"\]\(([^)]+\.md)\)", raw)
  3115	            issue = re.search(r"https://github\.com/[^/\s]+/[^/\s]+/(?:issues|pull)/\d+", raw)
  3116	            pos[sec] = pos.get(sec, 0) + 1
  3117	            entry = {
  3118	                "gh_number": int(gh.group(1)) if gh else None,
  3119	                "title": title, "section": sec, "position": pos[sec],
  3120	                "status_marker": marker,
  3121	                "complexity": int(cre.group(1)) if cre else None,
  3122	                "risk": int(cre.group(2)) if cre else None,
  3123	                "effort": int(cre.group(3)) if cre else None,
  3124	                "doc_path": doc.group(1) if doc else None,
  3125	                "issue_url": issue.group(0) if issue else None,
  3126	                "raw_text": raw,
  3127	            }
  3128	            entry.update(parse_rating(raw, title))
  3129	            entries.append(entry)
  3130	            i = j
  3131	            continue
  3132	        i += 1
  3133	    return entries
  3134	
  3135	
  3136	_ROADMAP_FIELDS = ("gh_number", "title", "section", "position", "status_marker",
  3137	                   "complexity", "risk", "effort", "doc_path", "issue_url", "raw_text") \
  3138	                  + RATING_COLUMNS
  3139	
  3140	
  3141	
  3142	def validate_raw_text(raw_text, issue_num=None):
  3143	    """GH-257: validate that raw_text matches the markdown shape the renderer requires.
  3144	
  3145	    The renderer (utils/roadmap-dashboard.sh) parses bullets starting with an exact `- **<title>**`
  3146	    prefix. An unparseable line (e.g. `- [ ] #255 ...`, `-   **`, or unclosed bold) is dropped by
  3147	    the dashboard renderer. Validating at write time catches malformed input immediately.
  3148	    """
  3149	    if not isinstance(raw_text, str):
  3150	        refuse("invalid-raw-text", "raw_text must be a string")
  3151	    if "\r" in raw_text or "\n" in raw_text:
  3152	        refuse("invalid-raw-text",
  3153	               "malformed --raw-text: raw_text must be a single line (no newlines permitted)")
  3154	    stripped = raw_text.strip()
  3155	    if not re.match(r'^- \*\*[^\r\n*]+?\*\*', stripped):
  3156	        refuse("invalid-raw-text",
  3157	               "malformed --raw-text %r: expected markdown bullet starting with '- **<title>**' "
  3158	               "(e.g. '- **GH-%s · <title>** ...')" % (raw_text, str(issue_num) if issue_num else "<num>"))
  3159	    if issue_num is not None:
  3160	        gh_patterns = [r'\bGH-%d\b' % issue_num, r'#%d\b' % issue_num]
  3161	        if not any(re.search(p, raw_text) for p in gh_patterns):
  3162	            refuse("invalid-raw-text",
  3163	                   "malformed --raw-text: does not reference issue GH-%d / #%d" % (issue_num, issue_num))
  3164	    return stripped
  3165	
  3166	
  3167	
  3168	def cmd_roadmap_add(args):
  3169	    root = resolve_root(args.root)
  3170	    paths = artifact_paths(root)
  3171	    conn = connect(paths["db"])
  3172	    try:
  3173	        basename = os.path.basename(args.doc_path)
  3174	        # hq park passes the hq_roadmap_line rendering via --raw-text so preview and stored row
  3175	        # share ONE template; the inline fallback exists only for direct CLI use.
  3176	        if args.raw_text:
  3177	            raw_text = validate_raw_text(args.raw_text, args.issue_num)
  3178	        else:
  3179	            raw_text = "- **GH-%d · %s** 🆕 **captured %s via HQ** — [%s](%s) · [#%d](%s)" % (
  3180	                args.issue_num, args.title, args.created, basename, args.doc_path,
  3181	                args.issue_num, args.issue_url
  3182	            )
  3183	        # GH-249: the rating rides in the ledger line, parsed by the SAME parse_rating() the
  3184	        # markdown sync uses — one grammar, one parser, never a second scorer. Before this, ratings
  3185	        # could only enter through `roadmap sync`, which GH-169 turned into a no-op in releases-mode
  3186	        # repos, so every row parked after the flip was silently unrated.
  3187	        rating = parse_rating(raw_text, args.title)
  3188	
  3189	        if args.dry_run:
  3190	            print("ROADMAP line: %s" % raw_text)
  3191	            if rating["rating_pri"] is not None:
  3192	                print("rating: %s" % "/".join(str(rating[c]) for c in RATING_COLUMNS[:4]))
  3193	                if rating["rating_ovr"] is not None:
  3194	                    print("ovr: %d" % rating["rating_ovr"])
  3195	            return
  3196	
  3197	        # Dup guard — only when the shadow table exists; a pre-migration ledger gets the schema
  3198	        # installed inside mutate (mirrors cmd_roadmap_sync) instead of a raw OperationalError.
  3199	        if _table_exists(conn, "roadmap_items"):
  3200	            row = conn.execute("SELECT id FROM roadmap_items WHERE issue_url = ?", (args.issue_url,)).fetchone()
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-bzMqRzuJ' (errno=Operation not permitted)
2026-08-31 16:34:13.840 xcodebuild[75925:6483126]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:14.041 xcodebuild[75925:6483125] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-AZOq83Tq' (errno=Operation not permitted)
2026-08-31 16:34:14.668 xcodebuild[75927:6483138]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:14.867 xcodebuild[75927:6483137] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
  2760	    if not rated_tokens and not ovr_tokens:
  2761	        return blank
  2762	    where = "entry %r" % title[:60]
  2763	
  2764	    if _LEGACY_CRE_RE.search(raw) and rated_tokens:
  2765	        refuse("rating-vocabulary-clash",
  2766	               "%s carries BOTH `cx/risk/eff` and `rated`. The two vocabularies measure different "
  2767	               "things and never share a row; convert the entry to `rated` and delete the legacy "
  2768	               "triple." % where)
  2769	    score_tokens = _RATED_SCORE_TOKEN_RE.findall(raw)
  2770	    if len(score_tokens) > 1:
  2771	        refuse("rating-duplicate", "%s carries %d `rated` scores; exactly one is allowed"
  2772	               % (where, len(score_tokens)))
  2773	    if len(ovr_tokens) > 1:
  2774	        refuse("ovr-duplicate", "%s carries %d `ovr` tokens; at most one is allowed"
  2775	               % (where, len(ovr_tokens)))
  2776	    if ovr_tokens and not rated_tokens:
  2777	        refuse("ovr-orphan",
  2778	               "%s carries `ovr` with no `rated` scores. The override replaces the computed score "
  2779	               "for ranking; it does not stand in for the four axes, which keep their honest "
  2780	               "values underneath. %s" % (where, _RATING_GRAMMAR))
  2781	
  2782	    m = _RATED_RE.search(raw)
  2783	    if not m:
  2784	        refuse("rating-shape",
  2785	               "%s carries a `rated` token that does not parse — %s. A malformed rating is refused "
  2786	               "rather than read as unrated, so a mistyped score is never silently dropped."
  2787	               % (where, _RATING_GRAMMAR))
  2788	    values = [int(g) for g in m.groups()]
  2789	    for axis, value in zip(("pri", "sev", "appeal", "effort"), values):
  2790	        if not 1 <= value <= 100:
  2791	            refuse("rating-range", "%s scores %s at %d; every axis is 1-100 (100 = strongest, "
  2792	                                   "effort included — it scores cheapness)" % (where, axis, value))
  2793	    out = dict(zip(RATING_COLUMNS[:4], values))
  2794	    out["rating_ovr"] = None
  2795	    if ovr_tokens:
  2796	        mo = _OVR_RE.search(raw)
  2797	        if not mo:
  2798	            refuse("ovr-shape", "%s carries an `ovr` token with no integer after it; %s"
  2799	                   % (where, _RATING_GRAMMAR))
  2800	        ovr = int(mo.group(1))
  2801	        if not 4 <= ovr <= 400:
  2802	            refuse("ovr-range", "%s overrides to %d; the override is on calc's own 4-400 scale"
  2803	                   % (where, ovr))
  2804	        out["rating_ovr"] = ovr
  2805	    return out
  2806	
  2807	
  2808	def parse_roadmap_ledger(path):
  2809	    """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
  2810	    from its `- **` line to the next `- **`, `###`, or `##`."""
  2811	    lines = open(path, encoding="utf-8").read().splitlines()
  2812	    entries = []
  2813	    sec = None
  2814	    inledger = False
  2815	    pos = {}
  2816	    i, n = 0, len(lines)
  2817	    while i < n:
  2818	        line = lines[i]
  2819	        if re.match(r"^##\s+Ledger\s*$", line.strip()):
  2820	            inledger = True
  2821	            i += 1
  2822	            continue
  2823	        if inledger and re.match(r"^##\s+", line):
  2824	            break
  2825	        if inledger and line.startswith("### "):
  2826	            sec = line[4:].strip()
  2827	            i += 1
  2828	            continue
  2829	        if inledger and sec and line.startswith("- **"):
  2830	            j = i + 1
  2831	            while j < n and not (lines[j].startswith("- **") or lines[j].startswith("### ")
  2832	                                 or re.match(r"^##\s+", lines[j])):
  2833	                j += 1
  2834	            raw = "\n".join(lines[i:j]).rstrip()
  2835	            m = re.match(r"^- \*\*(.+?)\*\*", raw)
  2836	            title = m.group(1).strip() if m else raw[4:80]
  2837	            gh = re.match(r"^GH-(\d+)\b", title)
  2838	            marker = None
  2839	            for cand in _ROADMAP_STATUS_MARKERS:
  2840	                if cand in raw:
  2841	                    marker = cand
  2842	                    break
  2843	            cre = re.search(r"cx/risk/eff (\d+)/(\d+)/(\d+)", raw)
  2844	            doc = re.search(r"\]\((PROJECT/[^)]+\.md)", raw)
  2845	            issue = re.search(r"https://github\.com/HiQS-(?:Suite|Labs)/XYZ-forge/(?:issues|pull)/\d+", raw)
  2846	            pos[sec] = pos.get(sec, 0) + 1
  2847	            entry = {
  2848	                "gh_number": int(gh.group(1)) if gh else None,
  2849	                "title": title, "section": sec, "position": pos[sec],
  2850	                "status_marker": marker,
  2851	                "complexity": int(cre.group(1)) if cre else None,
  2852	                "risk": int(cre.group(2)) if cre else None,
  2853	                "effort": int(cre.group(3)) if cre else None,
  2854	                "doc_path": doc.group(1) if doc else None,
  2855	                "issue_url": issue.group(0) if issue else None,
  2856	                "raw_text": raw,
  2857	            }
  2858	            entry.update(parse_rating(raw, title))
  2859	            entries.append(entry)
  2860	            i = j
  2861	            continue
  2862	        i += 1
  2863	    return entries
  2864	
  2865	
  2866	_ROADMAP_FIELDS = ("gh_number", "title", "section", "position", "status_marker",
  2867	                   "complexity", "risk", "effort", "doc_path", "issue_url", "raw_text") \
  2868	                  + RATING_COLUMNS
  2869	
  2870	
  2871	
  2872	def validate_raw_text(raw_text, issue_num=None):
  2873	    """GH-257: validate that raw_text matches the markdown shape the renderer requires.
  2874	
  2875	    The renderer (utils/roadmap-dashboard.sh) parses bullets starting with an exact `- **<title>**`
  2876	    prefix. An unparseable line (e.g. `- [ ] #255 ...`, `-   **`, or unclosed bold) is dropped by
  2877	    the dashboard renderer. Validating at write time catches malformed input immediately.
  2878	    """
  2879	    if not isinstance(raw_text, str):
  2880	        refuse("invalid-raw-text", "raw_text must be a string")
  2881	    if "\r" in raw_text or "\n" in raw_text:
  2882	        refuse("invalid-raw-text",
  2883	               "malformed --raw-text: raw_text must be a single line (no newlines permitted)")
  2884	    stripped = raw_text.strip()
  2885	    if not re.match(r'^- \*\*[^\r\n*]+?\*\*', stripped):
  2886	        refuse("invalid-raw-text",
  2887	               "malformed --raw-text %r: expected markdown bullet starting with '- **<title>**' "
  2888	               "(e.g. '- **GH-%s · <title>** ...')" % (raw_text, str(issue_num) if issue_num else "<num>"))
  2889	    if issue_num is not None:
  2890	        gh_patterns = [r'\bGH-%d\b' % issue_num, r'#%d\b' % issue_num]
  2891	        if not any(re.search(p, raw_text) for p in gh_patterns):
  2892	            refuse("invalid-raw-text",
  2893	                   "malformed --raw-text: does not reference issue GH-%d / #%d" % (issue_num, issue_num))
  2894	    return stripped
  2895	
  2896	
  2897	
  2898	def cmd_roadmap_add(args):
  2899	    root = resolve_root(args.root)
  2900	    paths = artifact_paths(root)
  2901	    conn = connect(paths["db"])
  2902	    try:
  2903	        basename = os.path.basename(args.doc_path)
  2904	        # hq park passes the hq_roadmap_line rendering via --raw-text so preview and stored row
  2905	        # share ONE template; the inline fallback exists only for direct CLI use.
  2906	        if args.raw_text:
  2907	            raw_text = validate_raw_text(args.raw_text, args.issue_num)
  2908	        else:
  2909	            raw_text = "- **GH-%d · %s** 🆕 **captured %s via HQ** — [%s](%s) · [#%d](%s)" % (
  2910	                args.issue_num, args.title, args.created, basename, args.doc_path,
  2911	                args.issue_num, args.issue_url
  2912	            )
  2913	        # GH-249: the rating rides in the ledger line, parsed by the SAME parse_rating() the
  2914	        # markdown sync uses — one grammar, one parser, never a second scorer. Before this, ratings
  2915	        # could only enter through `roadmap sync`, which GH-169 turned into a no-op in releases-mode
  2916	        # repos, so every row parked after the flip was silently unrated.
  2917	        rating = parse_rating(raw_text, args.title)
  2918	
  2919	        if args.dry_run:
  2920	            print("ROADMAP line: %s" % raw_text)
  2921	            if rating["rating_pri"] is not None:
  2922	                print("rating: %s" % "/".join(str(rating[c]) for c in RATING_COLUMNS[:4]))
  2923	                if rating["rating_ovr"] is not None:
  2924	                    print("ovr: %d" % rating["rating_ovr"])
  2925	            return
  2926	
  2927	        # Dup guard — only when the shadow table exists; a pre-migration ledger gets the schema
  2928	        # installed inside mutate (mirrors cmd_roadmap_sync) instead of a raw OperationalError.
  2929	        if _table_exists(conn, "roadmap_items"):
  2930	            row = conn.execute("SELECT id FROM roadmap_items WHERE issue_url = ?", (args.issue_url,)).fetchone()
  2931	            if row:
  2932	                refuse("roadmap-duplicate", "issue %s is already parked in the roadmap" % args.issue_url)
  2933	
  2934	            row2 = conn.execute("SELECT id FROM roadmap_items WHERE gh_number = ?", (args.issue_num,)).fetchone()
  2935	            if row2:
   125	# ── 6. Review regressions (LTVera-Pandas #322 review of PR #350) ────────────────────
   126	# Four defects the first cut of this fix introduced or left standing:
   127	#   a. an unanchored GH search harvested a number out of a title that merely MENTIONS one,
   128	#      colliding with the real entry and making `roadmap sync` refuse on XYZ-forge's own ledger
   129	#   b. a multi-issue umbrella title was keyed to whichever issue it named first
   130	#   c. `doc_path` was filled with the link target even when that target was a GitHub URL
   131	#   d. `issue_url` took the first URL anywhere in the block, so a hook citing another repo or a
   132	#      PR in passing silently re-keyed the entry
   133	#   e. markdown task-list items (`- [ ]`) parsed as entries with an empty title
   134	cat > "$R/ROADMAP.md" <<'MD'
   135	# Review Regression Roadmap
   136	
   137	## Ledger
   138	
   139	### Queue / parked intake
   140	- [ ] a task-list checkbox that is not a ledger entry
   141	- [x] another checkbox that is not a ledger entry
   142	- [GH-500 — issue-linked bullet with no PDDA doc](https://github.com/ExternalOrg/CustomRepo/issues/500) - the link target is the issue itself, not a document.
   143	- [GH-501 — hook cites other work in passing](docs/plans/gh-501.md) - the canonical issue lived in [otherrepo#2](https://github.com/ExternalOrg/OtherRepo/issues/2) and it shipped via [#502](https://github.com/ExternalOrg/CustomRepo/pull/502).
   144	- [#503 — a hash-prefixed title is a real key](docs/plans/gh-503.md) - narrative body.
   145	### In progress
   146	- **Execution checklist for GH-500 + GH-501** — a bold title that MENTIONS issues it is not keyed by.
   147	- **#601/#602/#603 · umbrella wave heading** — names three issues; none of them is its key.
   148	- **GH-701..706 · umbrella wave range** — a dotted RANGE is six issues, not issue 701.
   149	- **GH-707 — 2026 planning cycle** — an em-dash before a number is NOT a range; this IS keyed.
   150	MD
   151	
   152	out="$(ra roadmap sync 2>&1)"; rc=$?
   153	ok "review-regression ledger syncs (rc=$rc)" "[ $rc -eq 0 ]"
   154	
   155	count6="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
   156	ok "  and task-list checkboxes are not entries (7 rows, not 9)" "[ \"$count6\" = '7' ]"
   157	
   158	box="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items WHERE title = '' OR title = 'x'")"
   159	ok "  and no empty-titled checkbox row was stored" "[ \"$box\" = '0' ]"
   160	
   161	mention="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'Execution checklist%'")"
   162	ok "  and a title that only MENTIONS GH-500/GH-501 is not keyed by either" "[ \"$mention\" = 'NULL' ]"
   163	
   164	umbrella="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE '#601%'")"
   165	ok "  and a multi-issue umbrella title carries no key" "[ \"$umbrella\" = 'NULL' ]"
   166	
   167	hash_key="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items WHERE gh_number = 503")"
   168	ok "  and a hash-prefixed single-issue title IS keyed" "[ \"$hash_key\" = '1' ]"
   169	
   170	rng="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-701%'")"
   171	ok "  and a dotted RANGE umbrella carries no key (agy QA)" "[ \"$rng\" = 'NULL' ]"
   172	
   173	dash="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-707%'")"
   174	ok "  but an em-dash before a number is NOT a range — that title keeps its key" "[ \"$dash\" = '707' ]"
   175	
   176	doc500="$(sqlite3 "$R/releases.db" "SELECT COALESCE(doc_path,'NULL') FROM roadmap_items WHERE gh_number=500")"
   177	ok "  and an issue-linked bullet leaves doc_path NULL, not a URL" "[ \"$doc500\" = 'NULL' ]"
   178	
   179	url500="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=500")"
   180	ok "  and that bullet's own link target becomes issue_url" "[ \"$url500\" = 'https://github.com/ExternalOrg/CustomRepo/issues/500' ]"
   181	
   182	url501="$(sqlite3 "$R/releases.db" "SELECT COALESCE(issue_url,'NULL') FROM roadmap_items WHERE gh_number=501")"
   183	ok "  and a hook citing a foreign repo/PR does not re-key the entry" "[ \"$url501\" = 'NULL' ]"
   184	
   185	doc501="$(sqlite3 "$R/releases.db" "SELECT doc_path FROM roadmap_items WHERE gh_number=501")"
   186	ok "  and its real doc_path still resolves" "[ \"$doc501\" = 'docs/plans/gh-501.md' ]"
   187	
   188	# ── 7. This repo's own ROADMAP.md still parses, with no duplicate keys ──────────────
   189	# The regression that made this review necessary: the widened key search created a second
   190	# GH-111 in XYZ-forge's own ledger, which `roadmap sync` refuses on outright.
   191	self_dup="$(python3 - "$ROOT_DIR" <<'PY'
   192	import collections, importlib.util, os, sys
   193	root = sys.argv[1]
   194	spec = importlib.util.spec_from_file_location("ra", os.path.join(root, "utils/py/releases_app.py"))
   195	m = importlib.util.module_from_spec(spec)
   196	sys.argv = ["ra"]
   197	try:
   198	    spec.loader.exec_module(m)
   199	except SystemExit:
   200	    pass
   201	e = m.parse_roadmap_ledger(os.path.join(root, "ROADMAP.md"))
   202	c = collections.Counter(x["gh_number"] for x in e if x["gh_number"])
   203	print("%d %s" % (len(e), ",".join(str(k) for k, v in sorted(c.items()) if v > 1) or "none"))
   204	PY
   205	)"
   206	ok "this repo's own ROADMAP.md parses a non-empty ledger" "[ \"${self_dup%% *}\" -gt 0 ]"
   207	ok "  and yields no duplicate GH keys (would refuse roadmap sync)" "[ \"${self_dup##* }\" = 'none' ]"
   208	
   209	
   210	# ── 8. codex QA regressions (second review, 2026-08-31) ─────────────────────────────
   211	# agy passed the branch; codex found two Majors it missed:
   212	#   a. an UNKEYED entry took the first URL on its first line as its own identity — on the real
   213	#      reporting ledger that stored a BLOCKER (#42) as "Grow Willies"'s issue_url
   214	#   b. an absolute `.md` URL bypassed the doc-pointer check entirely, because the extraction
   215	#      regex accepted any `.md`-suffixed target and the validator was only consulted on the
   216	#      fallback branch
   217	# Plus: en dash is a numeric range (em dash is not), and duplicate UNKEYED titles are ambiguous.
   218	cat > "$R/ROADMAP.md" <<'MD'
   219	# Codex Review Regression Roadmap
   220	
   221	## Ledger
   222	
   223	### Queue / parked intake
   224	- [An unkeyed entry blocked by another issue](docs/plans/unkeyed.md) - **BLOCKED** on [#42](https://github.com/ExternalOrg/CustomRepo/issues/42), which has its own ledger row.
   225	- [GH-800 — upstream design lives outside the repo](https://github.com/ExternalOrg/SpecRepo/blob/main/DESIGN.md) - an absolute URL is not a doc pointer.
   226	- [GH-801 — mail target](mailto:notes.md) - a scheme with no slashes is still a scheme.
   227	- [GH-802 — absolute path](/docs/plan.md) - leading slash is not repo-relative.
   228	- [GH-803 — anchored doc](docs/plans/gh-803.md#phase-2) - an anchor is stripped, the path survives.
   229	### In progress
   230	- **GH-804..809 · dotted range umbrella** — six issues, not issue 804.
   231	- **GH-810–815 · en dash range umbrella** — en dash is the numeric-range delimiter.
   232	- **GH-816 — 2026 planning cycle** — an EM dash before a year is not a range.
   233	MD
   234	
   235	out="$(ra roadmap sync 2>&1)"; rc=$?
   236	ok "codex-regression ledger syncs (rc=$rc)" "[ $rc -eq 0 ]"
   237	
   238	unkeyed="$(sqlite3 "$R/releases.db" "SELECT COALESCE(issue_url,'NULL') FROM roadmap_items WHERE title LIKE 'An unkeyed entry%'")"
   239	ok "  and an UNKEYED entry does not adopt a cited blocker as its identity" "[ \"$unkeyed\" = 'NULL' ]"
   240	
   241	doc800="$(sqlite3 "$R/releases.db" "SELECT COALESCE(doc_path,'NULL') FROM roadmap_items WHERE gh_number=800")"
   242	ok "  and an absolute .md URL never reaches doc_path" "[ \"$doc800\" = 'NULL' ]"
   243	
   244	url800="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=800")"
   245	ok "  and that entry keeps no issue_url either (the link is not an issue)" "[ -z \"$url800\" ]"
   246	
   247	doc801="$(sqlite3 "$R/releases.db" "SELECT COALESCE(doc_path,'NULL') FROM roadmap_items WHERE gh_number=801")"
   248	ok "  and a mailto: target is rejected (a scheme without // is still a scheme)" "[ \"$doc801\" = 'NULL' ]"
   249	
   250	doc802="$(sqlite3 "$R/releases.db" "SELECT COALESCE(doc_path,'NULL') FROM roadmap_items WHERE gh_number=802")"
   251	ok "  and a leading-slash absolute path is rejected" "[ \"$doc802\" = 'NULL' ]"
   252	
   253	doc803="$(sqlite3 "$R/releases.db" "SELECT doc_path FROM roadmap_items WHERE gh_number=803")"
   254	ok "  but a real relative doc survives, with its #anchor stripped" "[ \"$doc803\" = 'docs/plans/gh-803.md' ]"
   255	
   256	dotted="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-804%'")"
   257	ok "  and a dotted range umbrella carries no key" "[ \"$dotted\" = 'NULL' ]"
   258	
   259	endash="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-810%'")"
   260	ok "  and an EN DASH range umbrella carries no key (codex QA)" "[ \"$endash\" = 'NULL' ]"
   261	
   262	emdash="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-816%'")"
   263	ok "  but an EM DASH before a year is prose — that title keeps its key" "[ \"$emdash\" = '816' ]"
   264	
   265	# ── 9. Ambiguity and clearing refusals ──────────────────────────────────────────────
   266	cat > "$R/ROADMAP.md" <<'MD'
   267	# Ambiguous Roadmap
   268	
   269	## Ledger
   270	
   271	### Queue / parked intake
   272	- [A repeated unkeyed title](docs/a.md) - first occurrence.
   273	- [A repeated unkeyed title](docs/b.md) - second occurrence, same title.
   274	MD
   275	
   276	out="$(ra roadmap sync 2>&1)"; rc=$?
   277	ok "sync refuses two identical UNKEYED titles (rc=$rc)" "[ $rc -ne 0 ]"
   278	ok "  and cites rule=roadmap-duplicate-title" "has \"\$out\" 'rule=roadmap-duplicate-title'"
   279	
   280	# A genuinely empty ledger: still refuses by default, clears only with the explicit override.
   281	cat > "$R/ROADMAP.md" <<'MD'
   282	# Emptied Roadmap
   283	
   284	## Ledger
   285	
   286	### Queue / parked intake
   287	MD
   288	
   289	out="$(ra roadmap sync 2>&1)"; rc=$?
   290	ok "an empty ledger still REFUSES by default (rc=$rc)" "[ $rc -ne 0 ]"
   291	ok "  and the refusal names the --allow-empty escape hatch" "has \"\$out\" '--allow-empty'"
   292	
   293	before_empty="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
   294	ok "  and nothing was deleted" "[ \"$before_empty\" -gt 0 ]"
   295	
   296	out="$(ra roadmap sync --allow-empty 2>&1)"; rc=$?
   297	ok "--allow-empty clears the mirror when the ledger is genuinely empty (rc=$rc)" "[ $rc -eq 0 ]"
   298	after_empty="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
   299	ok "  and roadmap_items is now empty" "[ \"$after_empty\" = '0' ]"
   300	
   301	# --allow-empty must NEVER excuse a ledger that still has content (format drift).
   302	cat > "$R/ROADMAP.md" <<'MD'
   303	# Malformed Roadmap
   304	
   305	## Ledger
   306	
   307	### Queue / parked intake
   308	Some unbulleted drift prose that parses to 0 entries.
   309	MD
   310	
   311	out="$(ra roadmap sync --allow-empty 2>&1)"; rc=$?
   312	ok "--allow-empty does NOT excuse a non-empty ledger that parses to 0 (rc=$rc)" "[ $rc -ne 0 ]"
   313	ok "  and still cites rule=roadmap-empty-parse" "has \"\$out\" 'rule=roadmap-empty-parse'"
   314	
   315	# ── 10. The legacy GH_URL field keeps its pre-GH-349 issue-only contract ────────────
   316	legacy_split="$(python3 - "$ROOT_DIR" <<'PY'
   317	import importlib.util, os, sys
   318	root = sys.argv[1]
   319	spec = importlib.util.spec_from_file_location("ra", os.path.join(root, "utils/py/releases_app.py"))
   320	m = importlib.util.module_from_spec(spec)
   321	sys.argv = ["ra"]
   322	try:
   323	    spec.loader.exec_module(m)
   324	except SystemExit:
   325	    pass
   326	pr = "https://github.com/Org/Repo/pull/9"
   327	iss = "https://github.com/Org/Repo/issues/9"
   328	yn = lambda x: "yes" if x else "no"
   329	print("%s %s %s %s" % (
   330	    yn(m.URL_EXTRACT_RE.fullmatch(pr)),       # legacy vs a PR URL   — must be no
   331	    yn(m.URL_EXTRACT_RE.fullmatch(iss)),      # legacy vs an issue   — must be yes
   332	    yn(m.ROADMAP_URL_RE.fullmatch(pr)),       # roadmap vs a PR URL  — must be yes
   333	    yn(m.ROADMAP_URL_RE.fullmatch(iss))))     # roadmap vs an issue  — must be yes
   334	PY
   335	)"
   336	ok "legacy GH_URL matcher still rejects a PR URL (no cross-caller widening)" "[ \"$(echo "$legacy_split" | cut -d' ' -f1)\" = 'no' ]"
   337	ok "  and still accepts an issue URL" "[ \"$(echo "$legacy_split" | cut -d' ' -f2)\" = 'yes' ]"
   338	ok "  while the roadmap matcher accepts both PR and issue URLs" "[ \"$(echo "$legacy_split" | cut -d' ' -f3-4)\" = 'yes yes' ]"
   339	
   340	
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-4ZTAGgGu' (errno=Operation not permitted)
2026-08-31 16:34:16.272 xcodebuild[75950:6483259]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:16.472 xcodebuild[75950:6483258] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-4ptQKRMI' (errno=Operation not permitted)
2026-08-31 16:34:17.093 xcodebuild[75957:6483315]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:17.297 xcodebuild[75957:6483314] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
     1	#!/usr/bin/env bash
     2	# gh349-vendored-roadmap-ledger.sh — GH-349: roadmap layer and releases ledger in vendored installs.
     3	#
     4	# Asserts:
     5	#   Scope 1: `roadmap sync` refuses rather than deleting when 0 entries are parsed from non-empty ROADMAP.md.
     6	#   Scope 1: Link-style bullets `- [Title](path) — ...` parse cleanly.
     7	#   Scope 2: Issue URLs from foreign orgs (arbitrary GitHub orgs/repos) are captured into issue_url.
     8	#   Scope 3: Migration 007 applies `updated_at` timestamps to all 9 tables from pre-migration state,
     9	#            non-null backfill, direct rebuild from untouched v6 dump backfills all 9 tables,
    10	#            updates advance timestamps (including settings.generation), exact timestamp preservation
    11	#            across all non-generation tables with stable keys, and pinned rebuild timestamp on settings.generation.
    12	#   Scope 4: Rating system doc and validation (shape refusal, axis ranges, ovr range/orphan, vocabulary clash).
    13	#   Advisory: `releases next` warns when all candidates are undated.
    14	set -uo pipefail
    15	
    16	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    17	ROOT_DIR="$(cd "$HERE/.." && pwd)"
    18	APP="$ROOT_DIR/utils/py/releases_app.py"
    19	
    20	pass=0; fail=0
    21	ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
    22	is(){ [ "$1" = "$2" ]; }
    23	has(){ printf '%s' "$1" | grep -Fq "$2"; }
    24	
    25	echo "== test: gh349-vendored-roadmap-ledger =="
    26	
    27	command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
    28	command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }
    29	
    30	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh349-vendored.XXXXXX")"
    31	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
    32	. "$HERE/lib/fixture-guard.sh"
    33	fixture_guard_init "$WORK"
    34	cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
    35	trap cleanup EXIT
    36	
    37	mkrepo(){
    38	  local r="$WORK/$1"
    39	  mkdir -p "$r"
    40	  git -C "$r" init -q -b main
    41	  git -C "$r" config user.email test@invalid
    42	  git -C "$r" config user.name test
    43	  printf '%s\n' "$r"
    44	}
    45	
    46	R="$(mkrepo repo)"
    47	require_fixture "$R" "fixture repo"
    48	
    49	ra(){
    50	  require_fixture "$R" "fixture repo"
    51	  python3 "$APP" --root "$R" "$@"
    52	}
    53	
    54	ra init --slug vendored-repo >/dev/null
    55	
    56	# ── 1. Scope 1 & 2: Link bullets and foreign org issue URLs ────────────────────────
    57	cat > "$R/ROADMAP.md" <<'MD'
    58	# Foreign Org Roadmap
    59	## Ledger
    60	### Active
    61	- [GH-101 · Custom Feature](PROJECT/2-WORKING/GH-101.md) — Link-style bullet format. rated 80/60/70/50. → [#101](https://github.com/ExternalOrg/ExternalRepo/issues/101)
    62	- [External Pull Request](PROJECT/2-WORKING/GH-102.md) — External PR link. → [#102](https://github.com/OtherOrg/OtherRepo/pull/102)
    63	- **GH-103 · Bold Format** — Standard format for comparison. rated 60/40/80/70. → [#103](https://github.com/ExternalOrg/ExternalRepo/issues/103)
    64	MD
    65	
    66	out="$(ra roadmap sync 2>&1)"
    67	ok "roadmap sync parsed link-style bullets and bold bullets" "$(has "$out" "+3 added"; echo $?)"
    68	
    69	# Check issue_url from foreign orgs
    70	URL_101="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=101;")"
    71	ok "foreign org issue url extracted properly" "$(is "$URL_101" "https://github.com/ExternalOrg/ExternalRepo/issues/101"; echo $?)"
    72	
    73	URL_102="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE title='External Pull Request';")"
    74	ok "foreign org pull url extracted properly" "$(is "$URL_102" "https://github.com/OtherOrg/OtherRepo/pull/102"; echo $?)"
    75	
    76	COUNT_ITEMS="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items;")"
    77	ok "all 3 items mirrored" "$(is "$COUNT_ITEMS" "3"; echo $?)"
    78	
    79	# ── 2. Scope 1: Non-empty file with 0 parsed entries refuses and protects data ────
    80	cat > "$R/ROADMAP.md" <<'MD'
    81	# Malformed format where nothing is under ## Ledger
    82	Some notes about the roadmap without a Ledger section.
    83	MD
    84	
    85	out="$(ra roadmap sync 2>&1 || true)"
    86	ok "sync on non-empty roadmap with 0 parsed entries is refused (rule=roadmap-empty)" "$(has "$out" "rule=roadmap-empty"; echo $?)"
    87	
    88	# Confirm data was NOT deleted
    89	COUNT_AFTER="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items;")"
    90	ok "roadmap_items preserved without wipe" "$(is "$COUNT_AFTER" "3"; echo $?)"
    91	
    92	# ── 3. Scope 3: Pre-migration fixture, direct rebuild from untouched v6 dump, non-null backfill, v7 exact preservation ──
    93	R_PRE="$(mkrepo pre_mig_repo)"
    94	require_fixture "$R_PRE" "pre-mig fixture repo"
    95	
    96	# Build a pre-007 fixture (v6 schema migrations) with untouched v6 dump
    97	python3 - "$R_PRE" "$APP" <<'PYPRE'
    98	import sys, os, importlib.util
    99	root = sys.argv[1]
   100	app_path = sys.argv[2]
   101	spec = importlib.util.spec_from_file_location("releases_app", app_path)
   102	ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
   103	db_path = os.path.join(root, "releases.db")
   104	conn = ra.connect(db_path, must_exist=False)
   105	# Apply migrations 001 through 006 only
   106	for v, m_spec in sorted(ra.MIGRATIONS.items()):
   107	    if v < 7:
   108	        m_spec["apply"](conn)
   109	        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)", (v, ra.now_iso()))
   110	# Populate all 9 target tables without updated_at
   111	conn.execute("INSERT INTO settings(key, value) VALUES ('enforcement', 'lenient')")
   112	conn.execute("INSERT INTO settings(key, value) VALUES ('repo_slug', 'pre-repo')")
   113	conn.execute("INSERT INTO settings(key, value) VALUES ('generation', '1')")
   114	conn.execute("INSERT INTO repos(global_id, slug) VALUES ('repo-01ARZ3NDEKTSV4RRFFQ69G5FA0', 'pre-repo')")
   115	conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES ('ref-01ARZ3NDEKTSV4RRFFQ69G5FA1', 'https://github.com/A/B/issues/1', NULL, '2026-08-01T00:00:00Z')")
   116	conn.execute("INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status, created_at) VALUES ('mar-01ARZ3NDEKTSV4RRFFQ69G5FA2', 1, 1, 'running', '2026-08-01T00:00:00Z')")
   117	conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status, description, tracking_ref_id, marathon_id)
   118	                VALUES ('rel-01ARZ3NDEKTSV4RRFFQ69G5FA3', 1, '1.0.0', 'Kickoff', 'active', 'pre-mig release', 1, 1)""")
   119	conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state, dialed_in_at, dial_reason, marathon_id)
   120	                VALUES ('mfi-01ARZ3NDEKTSV4RRFFQ69G5FA4', 1, 1, 'dialed_in', '2026-08-01T00:00:00Z', 'first item', 1)""")
   121	conn.execute("INSERT INTO doc_lines(repo_id, position, content) VALUES (1, 0, '# Title')")
   122	conn.execute("INSERT INTO legacy_lines(release_id, position, content) VALUES (1, 0, 'Legacy notes')")
   123	conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value, supplied_value, disposition)
   124	                VALUES ('imp-20260801', 'rel-01ARZ3NDEKTSV4RRFFQ69G5FA3', 'status-enum', 'Draft', 'draft', NULL)""")
   125	paths = ra.artifact_paths(root)
   126	ra._atomic_write(paths["dump"], ra.dump_text(conn, 1))
   127	conn.commit()
   128	conn.close()
   129	PYPRE
   130	
   131	# Test direct rebuild from untouched v6 dump (exercises loading pre-007 dump into v7 schema)
   132	python3 "$APP" --root "$R_PRE" check --rebuild >/dev/null
   133	
   134	TABLES=("releases" "manifest_items" "marathons" "repos" "settings" "issue_refs" "doc_lines" "legacy_lines" "grandfather_entries")
   135	all_rebuild_non_null=1
   136	for tbl in "${TABLES[@]}"; do
   137	  null_count="$(sqlite3 "$R_PRE/releases.db" "SELECT COUNT(*) FROM $tbl WHERE updated_at IS NULL;")"
   138	  if [ "$null_count" -ne 0 ]; then
   139	    all_rebuild_non_null=0
   140	    echo "table $tbl has $null_count NULL updated_at rows after rebuild from untouched v6 dump" >&2
   141	  fi
   142	done
   143	ok "direct rebuild from untouched v6 dump populates 100% non-NULL updated_at across all 9 tables" "$(is "$all_rebuild_non_null" "1"; echo $?)"
   144	
   145	# Test newly created issue_ref has non-null updated_at
   146	NEW_REF="$(python3 "$APP" --root "$R_PRE" add --version 2.0.0 --status draft --tracking-issue https://github.com/A/B/issues/2 --description "v2.0.0" | grep -o 'rel-[0-9A-HJKMNP-TV-Z]\{26\}')"
   147	REF_UPDATED_AT="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM issue_refs WHERE url='https://github.com/A/B/issues/2';")"
   148	ok "newly inserted issue_ref has non-null updated_at" "$([ -n "$REF_UPDATED_AT" ] && echo 0 || echo 1)"
   149	
   150	# Test timestamp advancement on mutation
   151	GEN_TIME_BEFORE="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM settings WHERE key='generation';")"
   152	TIME_BEFORE="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM releases WHERE global_id='$NEW_REF';")"
   153	sleep 1
   154	python3 "$APP" --root "$R_PRE" update --gid "$NEW_REF" --description "updated description" >/dev/null
   155	GEN_TIME_AFTER="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM settings WHERE key='generation';")"
   156	TIME_AFTER="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM releases WHERE global_id='$NEW_REF';")"
   157	ok "release update advances release updated_at timestamp" "$([ "$TIME_AFTER" \> "$TIME_BEFORE" ] && echo 0 || echo 1)"
   158	ok "mutation advances settings.generation updated_at timestamp" "$([ "$GEN_TIME_AFTER" \> "$GEN_TIME_BEFORE" ] && echo 0 || echo 1)"
   159	
   160	# Test dump and rebuild exact timestamp preservation across all non-generation tables using stable keys
   161	python3 "$APP" --root "$R_PRE" check >/dev/null
   162	
   163	snapshot_non_generation_tables(){
   164	  local db="$1"
   165	  echo "--- settings (non-generation) ---"
   166	  sqlite3 "$db" "SELECT key, value, updated_at FROM settings WHERE key != 'generation' ORDER BY key;"
   167	  echo "--- repos ---"
   168	  sqlite3 "$db" "SELECT global_id, slug, updated_at FROM repos ORDER BY global_id;"
   169	  echo "--- issue_refs ---"
   170	  sqlite3 "$db" "SELECT global_id, COALESCE(url, temp_id), updated_at FROM issue_refs ORDER BY global_id;"
   171	  echo "--- marathons ---"
   172	  sqlite3 "$db" "SELECT global_id, status, updated_at FROM marathons ORDER BY global_id;"
   173	  echo "--- releases ---"
   174	  sqlite3 "$db" "SELECT global_id, version, updated_at FROM releases ORDER BY global_id;"
   175	  echo "--- manifest_items ---"
   176	  sqlite3 "$db" "SELECT global_id, state, updated_at FROM manifest_items ORDER BY global_id;"
   177	  echo "--- doc_lines ---"
   178	  sqlite3 "$db" "SELECT position, content, updated_at FROM doc_lines ORDER BY position;"
   179	  echo "--- legacy_lines ---"
   180	  sqlite3 "$db" "SELECT position, content, updated_at FROM legacy_lines ORDER BY position;"
   181	  echo "--- grandfather_entries ---"
   182	  sqlite3 "$db" "SELECT import_run, COALESCE(release_gid, '(doc)'), rule, updated_at FROM grandfather_entries ORDER BY import_run, id;"
   183	}
   184	
   185	SNAPSHOT_BEFORE="$(snapshot_non_generation_tables "$R_PRE/releases.db")"
   186	RELEASES_APP_NOW="2026-09-01T12:00:00Z" python3 "$APP" --root "$R_PRE" check --rebuild >/dev/null
   187	SNAPSHOT_AFTER="$(snapshot_non_generation_tables "$R_PRE/releases.db")"
   188	ok "check --rebuild preserves exact updated_at values across all non-generation tables" "$(is "$SNAPSHOT_BEFORE" "$SNAPSHOT_AFTER"; echo $?)"
   189	
   190	GEN_AFTER="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM settings WHERE key='generation';")"
   191	ok "check --rebuild stamps pinned rebuild time into settings.generation.updated_at" "$(is "$GEN_AFTER" "2026-09-01T12:00:00Z"; echo $?)"
   192	
   193	# ── 4. Scope 4: Canonical rating vocabulary, axis parsing, ranges, ovr, malformed shape, vocabulary clash ──
   194	cat > "$R/ROADMAP.md" <<'MD'
   195	# Foreign Org Roadmap
   196	## Ledger
   197	### Active
   198	- [GH-110 · Rated Feature](PROJECT/2-WORKING/GH-110.md) — 4-axis rated. rated 90/80/70/60. ovr 350. → [#110](https://github.com/ExternalOrg/ExternalRepo/issues/110)
   199	MD
   200	ra roadmap sync >/dev/null
   201	RATING_VALS="$(sqlite3 "$R/releases.db" "SELECT rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr FROM roadmap_items WHERE gh_number=110;")"
   202	ok "4-axis rating and ovr parsed into database" "$(is "$RATING_VALS" "90|80|70|60|350"; echo $?)"
   203	
   204	# Test malformed rating shape (e.g. 3 axes instead of 4) refusal
   205	cat > "$R/ROADMAP.md" <<'MD'
   206	# Foreign Org Roadmap
   207	## Ledger
   208	### Active
   209	- [GH-111 · Malformed Rating Shape](PROJECT/2-WORKING/GH-111.md) — Malformed shape. rated 70/40/55. → [#111](https://github.com/ExternalOrg/ExternalRepo/issues/111)
   210	MD

exec
/bin/zsh -lc "git show origin/fix/gh351-gh349-releases-ledger-fixes:utils/py/releases_app.py | nl -ba | sed -n '3070,3170p'
git show origin/fix/gh351-gh349-releases-ledger-fixes:utils/py/releases_app.py | nl -ba | sed -n '3430,3505p'
nl -ba utils/py/releases_app.py | sed -n '3270,3360p'
nl -ba ROADMAP.md | sed -n '1,260p'
nl -ba /Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md | sed -n '1,280p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 4809ms:
2026-08-31 16:34:28.040 xcodebuild[76025:6483682]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:28.240 xcodebuild[76025:6483681] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-q5mUiRSc' (errno=Operation not permitted)
2026-08-31 16:34:28.860 xcodebuild[76031:6483748]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:29.063 xcodebuild[76031:6483747] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
  3070	def parse_roadmap_ledger(path):
  3071	    """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
  3072	    from its bullet line (`- **`, `- [`, `- `) to the next `- `, `###`, or `##`."""
  3073	    lines = open(path, encoding="utf-8").read().splitlines()
  3074	    entries = []
  3075	    sec = None
  3076	    has_ledger_header = any(re.match(r"^##\s+Ledger\s*$", l.strip()) for l in lines)
  3077	    inledger = not has_ledger_header
  3078	    pos = {}
  3079	    i, n = 0, len(lines)
  3080	    while i < n:
  3081	        line = lines[i]
  3082	        if has_ledger_header and re.match(r"^##\s+Ledger\s*$", line.strip()):
  3083	            inledger = True
  3084	            i += 1
  3085	            continue
  3086	        if has_ledger_header and inledger and re.match(r"^##\s+", line):
  3087	            break
  3088	        if inledger and line.startswith("### "):
  3089	            sec = line[4:].strip()
  3090	            i += 1
  3091	            continue
  3092	        if inledger and sec and (line.startswith("- **") or line.startswith("- [") or line.startswith("- ")):
  3093	            j = i + 1
  3094	            while j < n and not (lines[j].startswith("- ") or lines[j].startswith("### ")
  3095	                                 or re.match(r"^##\s+", lines[j])):
  3096	                j += 1
  3097	            raw = "\n".join(lines[i:j]).rstrip()
  3098	            m_bold = re.match(r"^- \*\*(.+?)\*\*", raw)
  3099	            m_link = re.match(r"^- \[(.+?)\]", raw)
  3100	            if m_bold:
  3101	                title = m_bold.group(1).strip()
  3102	            elif m_link:
  3103	                title = m_link.group(1).strip()
  3104	            else:
  3105	                m_plain = re.match(r"^- (.+)", raw)
  3106	                title = m_plain.group(1).strip() if m_plain else raw[2:80]
  3107	            gh = re.match(r"^(?:GH-|#)(\d+)\b", title) or re.search(r"\b(?:GH-|#)(\d+)\b", title)
  3108	            marker = None
  3109	            for cand in _ROADMAP_STATUS_MARKERS:
  3110	                if cand in raw:
  3111	                    marker = cand
  3112	                    break
  3113	            cre = re.search(r"cx/risk/eff (\d+)/(\d+)/(\d+)", raw)
  3114	            doc = re.search(r"\]\((PROJECT/[^)]+\.md)", raw) or re.search(r"\((PROJECT/[^)]+\.md)\)", raw) or re.search(r"\]\(([^)]+\.md)\)", raw)
  3115	            issue = re.search(r"https://github\.com/[^/\s]+/[^/\s]+/(?:issues|pull)/\d+", raw)
  3116	            pos[sec] = pos.get(sec, 0) + 1
  3117	            entry = {
  3118	                "gh_number": int(gh.group(1)) if gh else None,
  3119	                "title": title, "section": sec, "position": pos[sec],
  3120	                "status_marker": marker,
  3121	                "complexity": int(cre.group(1)) if cre else None,
  3122	                "risk": int(cre.group(2)) if cre else None,
  3123	                "effort": int(cre.group(3)) if cre else None,
  3124	                "doc_path": doc.group(1) if doc else None,
  3125	                "issue_url": issue.group(0) if issue else None,
  3126	                "raw_text": raw,
  3127	            }
  3128	            entry.update(parse_rating(raw, title))
  3129	            entries.append(entry)
  3130	            i = j
  3131	            continue
  3132	        i += 1
  3133	    return entries
  3134	
  3135	
  3136	_ROADMAP_FIELDS = ("gh_number", "title", "section", "position", "status_marker",
  3137	                   "complexity", "risk", "effort", "doc_path", "issue_url", "raw_text") \
  3138	                  + RATING_COLUMNS
  3139	
  3140	
  3141	
  3142	def validate_raw_text(raw_text, issue_num=None):
  3143	    """GH-257: validate that raw_text matches the markdown shape the renderer requires.
  3144	
  3145	    The renderer (utils/roadmap-dashboard.sh) parses bullets starting with an exact `- **<title>**`
  3146	    prefix. An unparseable line (e.g. `- [ ] #255 ...`, `-   **`, or unclosed bold) is dropped by
  3147	    the dashboard renderer. Validating at write time catches malformed input immediately.
  3148	    """
  3149	    if not isinstance(raw_text, str):
  3150	        refuse("invalid-raw-text", "raw_text must be a string")
  3151	    if "\r" in raw_text or "\n" in raw_text:
  3152	        refuse("invalid-raw-text",
  3153	               "malformed --raw-text: raw_text must be a single line (no newlines permitted)")
  3154	    stripped = raw_text.strip()
  3155	    if not re.match(r'^- \*\*[^\r\n*]+?\*\*', stripped):
  3156	        refuse("invalid-raw-text",
  3157	               "malformed --raw-text %r: expected markdown bullet starting with '- **<title>**' "
  3158	               "(e.g. '- **GH-%s · <title>** ...')" % (raw_text, str(issue_num) if issue_num else "<num>"))
  3159	    if issue_num is not None:
  3160	        gh_patterns = [r'\bGH-%d\b' % issue_num, r'#%d\b' % issue_num]
  3161	        if not any(re.search(p, raw_text) for p in gh_patterns):
  3162	            refuse("invalid-raw-text",
  3163	                   "malformed --raw-text: does not reference issue GH-%d / #%d" % (issue_num, issue_num))
  3164	    return stripped
  3165	
  3166	
  3167	
  3168	def cmd_roadmap_add(args):
  3169	    root = resolve_root(args.root)
  3170	    paths = artifact_paths(root)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-ANapdkvf' (errno=Operation not permitted)
2026-08-31 16:34:30.445 xcodebuild[76039:6483778]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:30.654 xcodebuild[76039:6483777] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-qoCo4w2x' (errno=Operation not permitted)
2026-08-31 16:34:31.279 xcodebuild[76042:6483794]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:31.479 xcodebuild[76042:6483793] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
  3430	        conn.close()
  3431	
  3432	
  3433	def cmd_roadmap_sync(args):
  3434	    root = resolve_root(args.root)
  3435	    # PR #240 review: sync mirrors ROADMAP.md and DELETES rows absent from it — in a releases-mode
  3436	    # repo the DB is canonical and rows arrive via `roadmap add` with no markdown source line, so
  3437	    # mirroring would destroy parked intake. Skip cleanly (exit 0): wave_reconcile.py calls sync
  3438	    # unconditionally post-merge and must stay green in both modes.
  3439	    try:
  3440	        with open(os.path.join(root, ".pdda-mode")) as f:
  3441	            if "ROADMAP_SOURCE=releases" in f.read():
  3442	                print("roadmap sync: skipped — releases-mode repo (the DB is canonical; sync only "
  3443	                      "mirrors ROADMAP.md in legacy mode, and would delete rows parked by `roadmap add`)")
  3444	                return
  3445	    except OSError:
  3446	        pass
  3447	    conn = connect(artifact_paths(root)["db"])
  3448	    try:
  3449	        md_path = os.path.join(root, ROADMAP_NAME)
  3450	        if not os.path.exists(md_path):
  3451	            refuse("roadmap-missing", "no %s at %s — nothing to shadow" % (ROADMAP_NAME, root))
  3452	        parsed = parse_roadmap_ledger(md_path)
  3453	        if len(parsed) == 0:
  3454	            with open(md_path, encoding="utf-8") as f:
  3455	                content = f.read().strip()
  3456	            if content:
  3457	                refuse("roadmap-empty",
  3458	                       "parsed 0 entries from non-empty %s; refusing sync to prevent accidental "
  3459	                       "wipe of roadmap_items" % ROADMAP_NAME)
  3460	        # duplicate GH keys in the markdown would make the mirror ambiguous — name it, do not pick
  3461	        seen = {}
  3462	        for e in parsed:
  3463	            if e["gh_number"] is not None:
  3464	                if e["gh_number"] in seen:
  3465	                    refuse("roadmap-duplicate-gh",
  3466	                           "GH-%d appears twice in %s (%r and %r). The mirror keys entries by GH "
  3467	                           "number; merge or renumber one of them, then re-run."
  3468	                           % (e["gh_number"], ROADMAP_NAME, seen[e["gh_number"]][:60],
  3469	                              e["title"][:60]))
  3470	                seen[e["gh_number"]] = e["title"]
  3471	
  3472	        repo = conn.execute("SELECT id, global_id FROM repos ORDER BY id LIMIT 1").fetchone()
  3473	        if repo is None:
  3474	            refuse("no-repo", "the DB has no repos row; run `releases init` first")
  3475	
  3476	        # GH-108/GH-111: feature commands do NOT self-migrate. Rating storage arrives through
  3477	        # `releases migrate` (migration 003); sync refuses clearly when a rated entry meets a
  3478	        # ledger that cannot hold it, rather than installing schema of its own or — worse —
  3479	        # writing the entry with its scores silently dropped.
  3480	        rating_ok = _has_column(conn, "roadmap_items", "rating_pri")
  3481	        if not rating_ok and any(e["rating_pri"] is not None for e in parsed):
  3482	            refuse("schema-behind",
  3483	                   "%s carries `rated` scores but this ledger has no rating columns. Run "
  3484	                   "`releases migrate` first — sync mirrors ROADMAP.md, it never installs schema."
  3485	                   % ROADMAP_NAME)
  3486	
  3487	        have = {}
  3488	        if _table_exists(conn, "roadmap_items"):
  3489	            for r in conn.execute("SELECT * FROM roadmap_items WHERE repo_id = ?", (repo["id"],)):
  3490	                key = ("gh", r["gh_number"]) if r["gh_number"] is not None else ("title", r["title"])
  3491	                have[key] = {c: _col(r, c) for c in r.keys()}
  3492	                for c in RATING_COLUMNS:
  3493	                    have[key].setdefault(c, None)
  3494	        schema_missing = not _table_exists(conn, "roadmap_items") or conn.execute(
  3495	            "SELECT 1 FROM schema_migrations WHERE version = 2").fetchone() is None
  3496	
  3497	        adds, updates, keeps = [], [], []
  3498	        matched = set()
  3499	        for e in parsed:
  3500	            key = ("gh", e["gh_number"]) if e["gh_number"] is not None else ("title", e["title"])
  3501	            row = have.get(key)
  3502	            if row is None:
  3503	                adds.append(e)
  3504	                continue
  3505	            matched.add(key)
  3270	        conn.close()
  3271	
  3272	
  3273	def cmd_roadmap_sync(args):
  3274	    root = resolve_root(args.root)
  3275	    # PR #240 review: sync mirrors ROADMAP.md and DELETES rows absent from it — in a releases-mode
  3276	    # repo the DB is canonical and rows arrive via `roadmap add` with no markdown source line, so
  3277	    # mirroring would destroy parked intake. Skip cleanly (exit 0): wave_reconcile.py calls sync
  3278	    # unconditionally post-merge and must stay green in both modes.
  3279	    try:
  3280	        with open(os.path.join(root, ".pdda-mode")) as f:
  3281	            if "ROADMAP_SOURCE=releases" in f.read():
  3282	                print("roadmap sync: skipped — releases-mode repo (the DB is canonical; sync only "
  3283	                      "mirrors ROADMAP.md in legacy mode, and would delete rows parked by `roadmap add`)")
  3284	                return
  3285	    except OSError:
  3286	        pass
  3287	    conn = connect(artifact_paths(root)["db"])
  3288	    try:
  3289	        md_path = os.path.join(root, ROADMAP_NAME)
  3290	        if not os.path.exists(md_path):
  3291	            refuse("roadmap-missing", "no %s at %s — nothing to shadow" % (ROADMAP_NAME, root))
  3292	        parsed = parse_roadmap_ledger(md_path)
  3293	        if len(parsed) == 0:
  3294	            ledger_has_content = False
  3295	            in_ledger_check = False
  3296	            for line in open(md_path, encoding="utf-8").read().splitlines():
  3297	                if re.match(r"^##\s+Ledger\s*$", line.strip()):
  3298	                    in_ledger_check = True
  3299	                    continue
  3300	                if in_ledger_check and re.match(r"^##\s+", line):
  3301	                    break
  3302	                # A `###` section heading is ledger STRUCTURE, not content: a ledger with its
  3303	                # sections and no bullets is genuinely empty. Format drift, by contrast, is
  3304	                # bullets in a shape the parser missed — still non-heading lines, still caught.
  3305	                if (in_ledger_check and line.strip()
  3306	                        and not line.strip().startswith("<!--")
  3307	                        and not line.startswith("###")):
  3308	                    ledger_has_content = True
  3309	                    break
  3310	            has_rows = bool(_table_exists(conn, "roadmap_items")
  3311	                            and conn.execute("SELECT 1 FROM roadmap_items LIMIT 1").fetchone())
  3312	            if ledger_has_content or has_rows:
  3313	                # --allow-empty is the ONE sanctioned way to clear the mirror. It is deliberately
  3314	                # narrow: it never excuses a ledger that still has content, so it cannot be used to
  3315	                # paper over the format drift this guard exists to catch. Without it, an
  3316	                # intentionally emptied ledger was a dead end, and AGENTS.md forbids the hand-edit
  3317	                # of releases.db that agy suggested as the workaround. codex QA, 2026-08-31.
  3318	                if ledger_has_content or not getattr(args, "allow_empty", False):
  3319	                    refuse("roadmap-empty-parse",
  3320	                           "parsed 0 entries from %s (%s); refusing to delete roadmap_items%s"
  3321	                           % (ROADMAP_NAME,
  3322	                              "ledger is non-empty" if ledger_has_content else "table has existing rows",
  3323	                              "" if ledger_has_content else " — pass --allow-empty if the ledger is "
  3324	                              "meant to be empty and you intend to clear the mirror"))
  3325	                n_rows = conn.execute("SELECT COUNT(*) FROM roadmap_items").fetchone()[0]
  3326	                print("roadmap sync: --allow-empty — %s ledger is empty, clearing %d mirrored row(s)"
  3327	                      % (ROADMAP_NAME, n_rows))
  3328	        # duplicate GH keys in the markdown would make the mirror ambiguous — name it, do not pick
  3329	        seen = {}
  3330	        for e in parsed:
  3331	            if e["gh_number"] is not None:
  3332	                if e["gh_number"] in seen:
  3333	                    refuse("roadmap-duplicate-gh",
  3334	                           "GH-%d appears twice in %s (%r and %r). The mirror keys entries by GH "
  3335	                           "number; merge or renumber one of them, then re-run."
  3336	                           % (e["gh_number"], ROADMAP_NAME, seen[e["gh_number"]][:60],
  3337	                              e["title"][:60]))
  3338	                seen[e["gh_number"]] = e["title"]
  3339	
  3340	        # An unkeyed row is keyed by its TITLE instead (see the `have`/`parsed` key below), so two
  3341	        # identical unkeyed titles are the same ambiguity as a duplicate GH number — and more
  3342	        # reachable since GH-349 made umbrella and range headings deliberately unkeyed. Left
  3343	        # unguarded, both enter `adds` on the first sync and collapse to one key on the next,
  3344	        # leaving an orphan row behind. codex QA, 2026-08-31.
  3345	        seen_titles = set()
  3346	        for e in parsed:
  3347	            if e["gh_number"] is None:
  3348	                if e["title"] in seen_titles:
  3349	                    refuse("roadmap-duplicate-title",
  3350	                           "the unkeyed entry %r appears twice in %s. Entries without a GH number "
  3351	                           "are mirrored by title, so two identical ones are ambiguous; give one a "
  3352	                           "GH key or retitle it, then re-run." % (e["title"][:80], ROADMAP_NAME))
  3353	                seen_titles.add(e["title"])
  3354	
  3355	        repo = conn.execute("SELECT id, global_id FROM repos ORDER BY id LIMIT 1").fetchone()
  3356	        if repo is None:
  3357	            refuse("no-repo", "the DB has no repos row; run `releases init` first")
  3358	
  3359	        # GH-108/GH-111: feature commands do NOT self-migrate. Rating storage arrives through
  3360	        # `releases migrate` (migration 003); sync refuses clearly when a rated entry meets a
     1	---
     2	title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
     3	status: Active
     4	created: 2026-06-16
     5	updated: 2026-08-21
     6	branch: main
     7	supersedes: PROJECT/2-WORKING/ROADMAP-COMBINED.md (promoted to canonical 2026-06-17); folds in the former standalone ROADMAP.md (adversarial-hardening track, now Part B)
     8	synthesizes:
     9	  - PROJECT/1-INBOX/LOOPS.md
    10	  - PROJECT/4-MISC/COST-OBSERVABILITY-PLAN.md
    11	  - PROJECT/1-INBOX/MARATHON.md
    12	goal: >
    13	  Keep one long-horizon marathon under load at all times — work long, parallel, and failure-prone
    14	  enough to tax the whole XYZ system (worktree isolation, path claims, the driver lock, multi-round
    15	  handoff, escalation, resume). That purpose is a work-selection filter: prefer the marathon-shaped
    16	  candidate, run only real work (an idle gap is honest; a manufactured marathon is not), and treat
    17	  the failures a run surfaces as the deliverable. See AGENTS.md -> Repo-specific rails for the four
    18	  rules. Mechanically, this file is the canonical pointer/ledger index for that work — queued
    19	  intake, in progress, completed, and deferred — linking to the PROJECT/** docs that own the
    20	  execution detail. It is an index, not a plan body.
    21	---
    22	
    23	<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
    24	     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
    25	     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
    26	     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
    27	     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
    28	     Enforced by `utils/pdda/pdda.sh roadmap` + `utils/pdda/pdda.sh roadmap-coverage` (deterministic) + `utils/pdda/pdda.sh doc-ready` ROADMAP rubric (LLM).      SHADOW (GH-69): this ledger is mirrored into releases.db's roadmap_items table. After editing
    29	     the ledger, run `python3 utils/py/releases_app.py roadmap sync` (a no-change sync is a free
    30	     no-op). This file remains the ONLY source of truth; the sync is one-way and never writes here.
    31	-->
    32	
    33	# Combined Roadmap: Cost-Observed Marathon Loops + Adversarial Hardening
    34	
    35	> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
    36	> gates, deep notes) lives in the linked `PROJECT/**` docs; keep it there. See the contract banner above.
    37	
    38	Three tracks, sequenced independently:
    39	
    40	- **Part A — Marathon:** cost observability (done) → headless multi-phase chaining (done) → real-monolith dogfood (active)
    41	- **Part B — Adversarial Hardening:** epoch fencing (done) → chaos suite → cross-repo E2E → reference deploy
    42	- **Part C — Autonomous Self-Improvement:** the gated LOOPS.md endgame
    43	
    44	## Status
    45	
    46	| What was just completed | What's next |
    47	|---|---|
    48	| **2026-08-19:** release **0.7.1 “Bulwark”** cut end-to-end through the RELEASES CLI, merged (PR #66), and **SHIPPED** the same day — the first release never hand-edited, and the first shipped through `releases ship` with its exit-criterion evidence recorded in the receipt chain (`gh32-releases-artifacts` 10/0, `gh53-releases-merge-resolve` 15/0, `gh54-merged-dump-refusals` 19/0, `check` clean at generation 9). **PR #55** (GH-35 tiered test selection + CPU governance; GH-45 worktree-gate refusal) and **PR #60** (GH-57 SQLite ledger fuzzing, 42/0) merged. **PR #70** closed GH-57’s live-merge gap: `test/gh57-live-merge-resolve.sh` (30/0) drives a REAL `git merge` and found four resolver defects, all fixed (failed-resolve half-closed the merge; rewound generation header accepted; `releases.db.bak` committable; `--root ""` retargeting). This ledger was purged of 256 upstream-numbered entries the same day (see below) and reconciled against GitHub issue state. | **[#75](https://github.com/HiQS-Labs/XYZ-forge/issues/75)** — single-page HTML dashboard over both DB subsystems (**front of the line, operator call 2026-08-19**). **[#67](https://github.com/HiQS-Labs/XYZ-forge/issues/67) (P1)** — decide the Commandcode `--yolo` default landed silently by PR #60. **[#59](https://github.com/HiQS-Labs/XYZ-forge/issues/59)** — re-arm hosted CI: the repo is public and Actions is enabled, yet pushes produce no runs. **[#58](https://github.com/HiQS-Labs/XYZ-forge/issues/58)** — GH-35 Phase 3 follow-ups (tier-2 hygiene gap P2 + two P3s), recommended to ride with Phase 3. **[#61](https://github.com/HiQS-Labs/XYZ-forge/issues/61)** — RELEASES ledger durability hardening (#62–#65). Next release on the shelf: **0.6.0 “Meter”**, target 2026-09-26. External contributions resolved 2026-08-21: PR #51, #99 and #119 merged; **PR #29 closed** — its tooling half landed as #51, but its Windows/MSYS2 *evidence* half never landed anywhere and was requested as a follow-up, so that platform still has no coverage. |
    49	
    50	### Immediate next-up (ordered)
    51	
    52	> **THE MARATHON — [#179](https://github.com/HiQS-Labs/XYZ-forge/issues/179) (release 0.7.3 "Bulkhead": harness reliability hardening).**
    53	> **Handed over from [#77](https://github.com/HiQS-Labs/XYZ-forge/issues/77) on 2026-08-22 — Daybreak SHIPPED** (0.7.2, all
    54	> four waves merged, gh77 suite green, #77/#82-#87 closed with evidence). Bulkhead is the next arc,
    55	> built from the 2026-08-22 radar targets: the suite-containment class (both polarities), headless-turn
    56	> reliability, and the roadmap-reconcile writer. Twelve members (7 radar targets 2026-08-22 + 5 Gen 3.5
    57	> soak defects 2026-08-23), disjoint-leaning write-sets, each with a
    58	> capture doc + preflight contract:
    59	> **[#113](https://github.com/HiQS-Labs/XYZ-forge/issues/113)** headless scratch containment (rated 85/60/85/60 → [GH-113-HEADLESS-SCRATCH-CONTAINMENT.md](PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md)) ·
    60	> **[#114](https://github.com/HiQS-Labs/XYZ-forge/issues/114)** headless TTY/idle hang (rated 80/60/80/60 → [GH-114-HEADLESS-TTY-IDLE-HANG.md](PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md)) ·
    61	> **[#115](https://github.com/HiQS-Labs/XYZ-forge/issues/115)** round-cap escalation (rated 75/50/85/70 → [GH-115-ROUND-CAP-ESCALATION.md](PROJECT/2-WORKING/GH-115-ROUND-CAP-ESCALATION.md)) ·
    62	> **[#168](https://github.com/HiQS-Labs/XYZ-forge/issues/168)** wave_reconcile scope (rated 80/55/85/70 → [GH-168-WAVE-RECONCILE-SCOPE.md](PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md)) ·
    63	> **[#8](https://github.com/HiQS-Labs/XYZ-forge/issues/8)** kernel boundary hardening (rated 75/55/80/65 → [GH-8-KERNEL-BOUNDARY-HARDENING.md](PROJECT/2-WORKING/GH-8-KERNEL-BOUNDARY-HARDENING.md)) ·
    64	> **[#2](https://github.com/HiQS-Labs/XYZ-forge/issues/2)** orphan-backup relocation (rated 80/55/85/55 → [GH-2-ORPHAN-BACKUP-RELOCATION.md](PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md)) ·
    65	> **[#50](https://github.com/HiQS-Labs/XYZ-forge/issues/50)** sandboxed git half-apply (rated 65/35/85/80 → [GH-50-SANDBOXED-GIT-HALF-APPLY.md](PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md)) ·
    66	> **[#180](https://github.com/HiQS-Labs/XYZ-forge/issues/180)** repro-builder timeout-record crash (rated 70/45/85/80 → [GH-180-REPRO-TIMEOUT-CRASH.md](PROJECT/2-WORKING/GH-180-REPRO-TIMEOUT-CRASH.md)) ·
    67	> **[#181](https://github.com/HiQS-Labs/XYZ-forge/issues/181)** repro-builder telemetry fidelity (rated 90/75/90/60 → [GH-181-REPRO-ADAPTER-FIDELITY.md](PROJECT/2-WORKING/GH-181-REPRO-ADAPTER-FIDELITY.md)) ·
    68	> **[#182](https://github.com/HiQS-Labs/XYZ-forge/issues/182)** self-healer facade/safety (rated 75/55/80/55 → [GH-182-HEALER-FACADE-SAFETY.md](PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md)) ·
    69	> **[#183](https://github.com/HiQS-Labs/XYZ-forge/issues/183)** explorer env-family soundness (rated 65/50/75/70 → [GH-183-EXPLORER-ENV-SOUNDNESS.md](PROJECT/2-WORKING/GH-183-EXPLORER-ENV-SOUNDNESS.md)) ·
    70	> **[#184](https://github.com/HiQS-Labs/XYZ-forge/issues/184)** tracked scratch artifact (rated 60/40/80/90 → [GH-184-TRACKED-SCRATCH-ARTIFACT.md](PROJECT/2-WORKING/GH-184-TRACKED-SCRATCH-ARTIFACT.md)).
    71	> The five #180–#184 members joined 2026-08-23 from the Gen 3.5 soak (#174/#177) — the first
    72	> cohort auto-filed under SOP §1's auto-file rule. Marathon now twelve members.
    73	> Plan computed and preflighted, NOT fired — operator fires per GUIDING-PRINCIPLES §8.
    74	
    75	> **Previous marathon (completed) — [#77](https://github.com/HiQS-Labs/XYZ-forge/issues/77) (`collect.sh`: the eight `/standup` lenses).**
    76	> Exactly one long-horizon marathon is in flight at a time (AGENTS.md → Repo-specific rails); this is it.
    77	> **Handed over from [#10](https://github.com/HiQS-Labs/XYZ-forge/issues/10) on 2026-08-19 by operator
    78	> call** — recorded as a deliberate swap rather than a second marathon, which the rail forbids. #10
    79	> stands down to ⏸️ and keeps its Ballast-cut history; it is the obvious next candidate when this lands.
    80	> #77 qualifies on the same filter: **eight near-identical work units**, one per lens, each with an
    81	> identical transform (bounded read → six required fields → fixture → assertions) and a machine-checkable
    82	> pass condition (`collect.sh --fixture lens-<n>` feeds `triage.py` with no `D5`, suite green). It taxes
    83	> the harness where a short task never does — eight parallel lanes editing one shared `collect.sh` and one
    84	> shared suite, which is exactly the path-claim and collision surface the swarm exists to manage. A lane
    85	> clobbering another's edit is the failure this run is meant to surface, and surfacing it is the
    86	> deliverable (rail 4). Shipping under release **0.7.2 "Daybreak"**.
    87	> Everything numbered below rides *alongside* it, not instead of it.
    88	
    89	1. **[#75](https://github.com/HiQS-Labs/XYZ-forge/issues/75) — build the single-page dashboard** over `releases` + `roadmap_items`. Deliberately **not** the marathon: it is one generator emitting one file and taxes nothing. It is the instrument you watch the marathon through — the drift this week (a shipped release left `active`, four stale status markers) was invisible until someone audited by hand. Also the first real consumer of the GH-69 shadow rows, which was #69's stated gate for its later stages.
    90	2. **[#67](https://github.com/HiQS-Labs/XYZ-forge/issues/67) — P1: ratify or revert the Commandcode `--yolo` default.** A permission-posture change to a builder default, landed inside a fuzzing PR, undecided.
    91	3. **[#59](https://github.com/HiQS-Labs/XYZ-forge/issues/59) — find out why hosted CI fires on nothing**, then narrow triggers to push/merge on `development` + `main` and wire the required check behind `main`'s new branch protection. **The "fires on nothing" half RESOLVED ITSELF at 17:09 UTC on 2026-08-21** — `pull_request` (run 32506672733) and `push` on `development` (run 32506697196) both fired normally, with no change to the workflow's triggers, after four days and three check-less merges (#116, #121, #122). Cause not established; it changed between 16:45 and 17:09 UTC, and the audit log needs `admin:org` — **if you flipped a setting in that window, record it on the issue.** Seven hypotheses were ruled out with evidence during the outage (billing was the leading theory and was wrong). **Still open:** narrowing the triggers and wiring the required check behind `main`'s branch protection — and note that both new runs concluded *success* while the canary job failed, so a green PR here currently proves nothing until #123 clears. History codified in `.github/workflows/ci.yml`'s header. rated 75/60/40/70.
    92	4. **[#123](https://github.com/HiQS-Labs/XYZ-forge/issues/123) — clear the Linux portability canary**: 7 failing assertions across 5 suites, found by the FIRST end-to-end run of that job (2026-08-21, run 32504570094). It had been dying at step 1 on a missing shebang and reporting the run green since the 2026-08-17 re-arm — advisory jobs make their own failures invisible. Two of the seven are new code from #116 (`utils/leaderboard.sh` ordering, `roadmap sync` dry-run), so they are drift we shipped, not drift we inherited. Per #232, reproduce in a container before calling any of them environment noise. rated 70/55/45/65.
    93	5. **[#58](https://github.com/HiQS-Labs/XYZ-forge/issues/58) — GH-35 Phase 3**, folding in the tier-2 hygiene gap (P2) and the two P3 defects from the PR #55 review.
    94	
    95	> **Standing radar finding (2026-08-19, 21-day window, 122 commits on `development`):** flow is
    96	> roughly **Run 72% / Grow 16% / Transform 0%** — no `PROJECT/**` doc declares `rgt: transform`, so
    97	> by the strict rule no transform work can be *claimed*, not that none happened. The dominant defect
    98	> cluster is **guards that could not report red**: the dashboard check verified its own output (three
    99	> stale dashboards reached `development` under a green gate on 2026-07-30 alone), the pre-push hook
   100	> double-niced and blocked itself, and GH-57's resolver held four defects invisible until a real
   101	> `git merge` was driven. One durable fix — every guard ships a recorded negative control against the
   102	> *real* artifact — retires the cluster. That is release **0.2.0 Litmus**'s declared scope.
   103	
   104	> **Provenance note (2026-08-19):** this repo succeeds
   105	> [`xyz-3-agents-swarm`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm); the migration kept the old GH numbering in
   106	> inherited ledger entries. 256 upstream-numbered entries were removed from this ledger on the
   107	> operator's call and preserved verbatim in
   108	> [docs/ROADMAP-UPSTREAM-ARCHIVE.md](docs/ROADMAP-UPSTREAM-ARCHIVE.md) ([#69](https://github.com/HiQS-Labs/XYZ-forge/issues/69)).
   109	> Every `GH-nnn` below refers to THIS repo's issues.
   110	
   111	## Model assignment (heuristic)
   112	
   113	Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-correctness reasoning
   114	(epoch-fencing kernel, dup-token determinism) → **Opus**. Full build-track table:
   115	[MARATHON-HARNESS.md → Model assignment](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#model-assignment-build-track-guidance).
   116	
   117	> **Operational note (carve-out — operationally critical):** Gemini CLI retired 2026-06-19; **agy**
   118	> (Antigravity CLI) is the permanent cross-model lane. **Run agy turns sandbox-OFF** (it exits 0 with
   119	> empty output when its backend is blocked) and an agy lane is **cost-blind** (no token output).
   120	> Detail: [MARATHON-HARNESS.md → Operational note](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#operational-note--cross-model-lane).
   121	
   122	## Ledger
   123	
   124	### Ad-hoc detours
   125	
   126	*(empty — GH-23 closed and moved to Completed 2026-08-19. Heading kept so an out-of-band
   127	detour has a home; note that the marathon planner does NOT read this section — see `## Entry format`.)*
   128	
   129	### Queue / parked intake
   130	- **GH-351 — manifest ship has no retraction verb** (2026-08-31) - a false `shipped` row is permanent and re-dialing doubles it, leaving one issue both shipped and pending. Bug filed via /file-xyz-bug from `ltvera`. Issue [#351](https://github.com/HiQS-Labs/XYZ-forge/issues/351). -> [PROJECT/1-INBOX/GH-351-MANIFEST-SHIP-RETRACTION.md](PROJECT/1-INBOX/GH-351-MANIFEST-SHIP-RETRACTION.md)
   131	- **GH-349 — releases ledger roadmap layer never generalised to a vendored install** (2026-08-31) - `roadmap sync` parses 0 entries from a link-style ROADMAP.md and deletes every `roadmap_items` row while exiting 0; plus a this-org-hardcoded issue-URL regex, 12 tables with no `updated_at`, and two rating vocabularies with no stated winner. Bug filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#349](https://github.com/HiQS-Labs/XYZ-forge/issues/349). -> [PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md](PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md)
   132	- **GH-223 — pre-push gate push double-applies through ref lock** (2026-08-24) - gate-green push reports its own landed commit as a lock rejection; observed 2x of ~10 gated pushes; quick-fix shape. Captured via /idea; dialed into 0.9.0 Cargo. Issue [#223](https://github.com/HiQS-Labs/XYZ-forge/issues/223). -> [PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md](PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md)
   133	- **GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed** (2026-08-24) - `whoami` no longer exists in agy CLI >=1.1.19, so the auth pre-flight hard-fails every headless agy-turn.sh run and misreports it as a login problem. Bug filed via /file-xyz-bug from `aegis-sleuth-slack-bot`. Issue [#221](https://github.com/HiQS-Labs/XYZ-forge/issues/221). -> [PROJECT/1-INBOX/GH-221-AGY-WHOAMI-PREFLIGHT.md](PROJECT/1-INBOX/GH-221-AGY-WHOAMI-PREFLIGHT.md)
   134	- **GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth** (2026-08-24) - both assume a bare `utils/` at repo root; under vendored `.xyz/` they die on missing files / ENOENT. Fixed locally in the reporting repo, not yet upstream. Bug filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#215](https://github.com/HiQS-Labs/XYZ-forge/issues/215). -> [PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md](PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md)
   135	- **GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets** (2026-08-24) - reconciler never completes in a repo whose ROADMAP.md uses `- [Title](path) — ...` bullets; exit 3 every time. Open design question, not patched. Bug filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#216](https://github.com/HiQS-Labs/XYZ-forge/issues/216). -> [PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md](PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md)
   136	- **GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view** 🆕 **queued 2026-08-19 at the FRONT of the line (operator call)** — a `releases dashboard` verb renders one self-contained HTML file from `releases.db`, with a card per release (version, codename, status, target, days-to-target, manifest open/closed split, exit criterion) and a card per `roadmap_items` row grouped by section in ledger order, plus a header strip carrying generation, receipt count, and a stale-sync banner when `ROADMAP.md` is ahead of the shadow. Read-only by construction: no writer lock, no generation bump, no receipt — safe to run mid-merge. First real consumer of the GH-69 shadow rows. rated 90/40/85/55. → [#75](https://github.com/HiQS-Labs/XYZ-forge/issues/75)
   137	- **GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)** 🆕 **queued 2026-08-19 — filed 2026-08-19 out of the PR #60 review and un-triaged until now** — four scoped test follow-ups under one parent: exact ledger state asserted after crash recovery ([#62](https://github.com/HiQS-Labs/XYZ-forge/issues/62)), writer-lock stress and owner-death recovery ([#63](https://github.com/HiQS-Labs/XYZ-forge/issues/63)), seeded malformed-dump property coverage ([#64](https://github.com/HiQS-Labs/XYZ-forge/issues/64)), and a portable artifact-hash helper ([#65](https://github.com/HiQS-Labs/XYZ-forge/issues/65)). rated 45/55/40/50. → [#61](https://github.com/HiQS-Labs/XYZ-forge/issues/61)
   138	- **GH-67 · Commandcode builder default widened to `--yolo` — closer evaluation → possible build** 🆕 **queued 2026-08-19 as the NEXT immediate item (operator call, session close)** — PR #60 moved the default from the bounded `--permission-mode auto-accept` to `--yolo` (alias for `--dangerously-skip-permissions`), unmentioned in a fuzzing PR. Evaluate whether the turn shim’s containment (worktree isolation, `ALLOW_PATHS`, commit-bypass guard) genuinely makes the child CLI’s permission mode irrelevant; if yes, RATIFY — write the containment argument down in AGENTS.md/the shim docs and pin it — if no, revert the default and drop the `--yolo` test pin. Sibling check either way: `claude-turn.py` uses `--permission-mode acceptEdits`; confirm the two adapters differ on purpose. rated 88/80/45/70 ovr 340. → [#67](https://github.com/HiQS-Labs/XYZ-forge/issues/67)
   139	- **GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI** 🚧 **Phase 0+1 BUILT and merged 2026-08-19 (PR #34, builder GLM 5.3 per the #33 evaluation)** — schema/CLI/writer-protocol/canonical-dump/import landed (`utils/py/releases_app.py`, suite 81/0, full gate green, independently verified); the PRD survived a 4-round Codex sol-high relay review first. Still ahead: the `/releases` route migration (Phase 0 entry gate for the measured dogfood window), the Phase 2 strict flip, and the Phase 3 cockpit card. rated 70/50/65/35. → [GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) · [#32](https://github.com/HiQS-Labs/XYZ-forge/issues/32) · [#33](https://github.com/HiQS-Labs/XYZ-forge/issues/33)
   140	- **GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue** 🆕 **queued 2026-08-18, sharpened via /consult (single-model, agy quota-failed) 2026-08-18, post-Ballast 0.7.0 follow-up** — root cause is two gaps: the discipline rubric only fires on manual `/releases clean`, and release-level notes have no home of their own. Consult caught that the original plan would've reversed documented "never blocks" policy and that the parser can't see continuation-paragraph bloat at all — both fixed: checks are now permanently advisory, scoped to active/unshipped blocks, with a required parser-folding step. rated 40/35/40/55. → [GH-28-RELEASES-LEDGER-DISCIPLINE.md](PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md) · [#28](https://github.com/HiQS-Labs/XYZ-forge/issues/28)
   141	- **GH-17 · SOP for evaluating new agent harnesses and frontier models** 🆕 **queued 2026-08-16** — establish a standardized operating procedure, checklist, and per-harness tracking issue workflow for new harness discovery, isolation, non-interactive execution, and cross-model matrix evaluation. rated 45/30/50/60. → [GH-17-SOP-HARNESS-MODEL-EVAL.md](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md) · [#17](https://github.com/HiQS-Labs/XYZ-forge/issues/17)
   142	- **GH-18 · Harness evaluation: Command Code (cmd) and model matrix** 🆕 **queued 2026-08-16** — evaluate Command Code CLI (v1.26.0), PATH resolution, auth, non-interactive `-p` execution, and model review benchmarks with `qwen/qwen3.7-flash` and `qwen/qwen3.8-max`. rated 35/25/45/55. → [GH-18-COMMANDCODE-EVAL.md](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md) · [#18](https://github.com/HiQS-Labs/XYZ-forge/issues/18)
   143	### In progress
   144	- **GH-204 · BSD `sed -i ''` no-ops on Linux at production call sites** 🚧 **active 2026-08-24 for release 0.7.4 "Linux-RC" (#224 Phase 2) — marathon lane computed, not fired** — portable in-place edits in `build-launch-artifact.sh` + `meter-release.sh`, content-asserted escalation write in the authoritative Python lane (`relay_drive.py`; the Bash twin is FROZEN per GH-308), and a gate-registered content-assertion regression suite. cx2/risk2/eff2. → [GH-204-BSD-SED-PORTABILITY.md](PROJECT/2-WORKING/GH-204-BSD-SED-PORTABILITY.md) · [#204](https://github.com/HiQS-Labs/XYZ-forge/issues/204)
   145	- **GH-205 · validate.sh mutates four tracked files per run — gate not idempotent** 🚧 **active 2026-08-24 for release 0.7.4 "Linux-RC" (#224 Phase 2) — marathon lane computed, not fired** — fixture-isolate `test/gh174-harness-registry.sh` (writes into `$ROOT/harnesses.db` + blog doc) so a pristine checkout stays porcelain-clean through a full gate; pinned by a new regression suite. cx2/risk1/eff2. → [GH-205-GATE-IDEMPOTENCY.md](PROJECT/2-WORKING/GH-205-GATE-IDEMPOTENCY.md) · [#205](https://github.com/HiQS-Labs/XYZ-forge/issues/205)
   146	- **GH-123 · Linux portability canary — remainder: gh358 lock contention on shared runners** 🚧 **active 2026-08-24 for release 0.7.4 "Linux-RC" (#224 Phase 2) — marathon lane computed, not fired** — the last live canary failure: make `test/gh358-lock-instrumentation.sh` deterministic under shared-runner CPU load (`XYZ_LOCK_WAIT_S` tuning or bounded retry); other 4 suites resolved on development / PR #209. cx2/risk2/eff2. → [GH-123-LINUX-CANARY-REMAINDER.md](PROJECT/2-WORKING/GH-123-LINUX-CANARY-REMAINDER.md) · [#123](https://github.com/HiQS-Labs/XYZ-forge/issues/123)
   147	- **GH-182 · self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design** 🚧 **queued 2026-08-23 for THE MARATHON (release 0.7.3 "Bulkhead", #179) — Gen 3.5 soak cohort, auto-filed per SOP §1** — fail-fast sandbox requirements (disposable root covering the target, never the invoking checkout), mandatory regression gate, configurable realistic timeouts, restore-on-any-exit; no reachable in-place patch path. rated 75/55/80/55. → [GH-182-HEALER-FACADE-SAFETY.md](PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md) · [#182](https://github.com/HiQS-Labs/XYZ-forge/issues/182)
   148	- **GH-201 · Gen 3.5 follow-ups — remaining ATE hardening arc (tasks 3–8b of #174)** 🚧 **active 2026-08-24 for release 0.9.0 "Cargo" (draft)** — deterministic Phase 1–3 fixes (A1–A9/A11), the remaining data-path wiring (explorer→repro-builder + E2E rewrite), explorer sharpening + per-probe zero-mutation oracle, gated Phase 4 autonomy (full-clone dispatch, GH-221 predicates, budget governor), the five-canary calibration hour, and the Gemma Tier-1 sensor (Part H, advisory-until-calibrated); healer safety rides separately as #182 on Bulkhead. rated 80/70/80/45. → [GH-201-GEN35-FOLLOWUPS.md](PROJECT/2-WORKING/GH-201-GEN35-FOLLOWUPS.md) · [#201](https://github.com/HiQS-Labs/XYZ-forge/issues/201)
   149	- **GH-141 · make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison** 🚧 **active 2026-08-22 on branch `gh141-fuzz-ate-utility`** — one selector owns the synthetic suites (validate.sh `--list` consumed by fuzz-loop, all 14 synthetic suites registered, divergence regression), telemetry de-aliased (nested `classification.status` removed; severity/likely_cause become derived signal from documented exit classes and output classes, consumers updated in-phase), the ATE chain fails loudly (#142's exit-code contract: 0 filed · 3 no-records · 1 gh-failed, propagated through run_variations) with a hermetic stub-`gh` chain regression, and ATE decoupled from Aider (neutral default labels, `expects_edits` grid key fixing #146's 17 false-HIGH no_edit verdicts, turn-shim grid declared, SKILL.md generalized). Phase 3 (generative boundary fuzzing) deliberately NOT scheduled — #143's counted comparison picks the target first, per the issue's own recommendation. rated 80/65/85/55. → [GH-141-FUZZ-ATE-UTILITY.md](PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md) · [#141](https://github.com/HiQS-Labs/XYZ-forge/issues/141) · [#142](https://github.com/HiQS-Labs/XYZ-forge/issues/142) · [#146](https://github.com/HiQS-Labs/XYZ-forge/issues/146)
   150	- **GH-5 · kernel robustness: node:test unit runner** 🆕 **active 2026-08-15 on `gh-5/events-quarantine-unit-tests` (public-repo tracker)** — 11 direct unit tests on the built-in `node:test` runner (was 13; the 2 quarantine-dependent tests deferred to #14), zero new dependencies, `npm run test:unit`, `npm test` → `validate.sh` unchanged. The quarantine-in-reader approach was rejected on orchestrator review per the correction on #5 (silent event loss on the concurrent path while writes are non-atomic) and re-routed to #14. **#5 stays open until this PR's tests and #14's atomic write have both landed.** rated 45/40/45/80. → [GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md](PROJECT/2-WORKING/GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md) · [#5](https://github.com/HiQS-Labs/XYZ-forge/issues/5)
   151	### Completed
   152	- **GH-222 · releases update cannot re-point a release's tracking issue** ✅ **SHIPPED 2026-08-28 (PR #311)** — a superseded tracking umbrella (LTVera-Pandas #225→#236) leaves the ledger permanently pointing at a closed issue; `releases update` has no `--tracking-issue` and `reconcile` only fills TMP refs. Dialed into 0.7.3 Bulkhead by operator 2026-08-24. Issue [#222](https://github.com/HiQS-Labs/XYZ-forge/issues/222). -> [PROJECT/1-INBOX/GH-222-RELEASES-TRACKING-REPOINT.md](PROJECT/1-INBOX/GH-222-RELEASES-TRACKING-REPOINT.md)
   153	- **GH-105 · vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)** ✅ **SHIPPED 2026-08-28 (PR #284)** — was: always in the vendored payload, never wired by default: `releases_app.py` + merge resolver + FAQs + `utils/timeline/`, with target-repo ledger state at the target root and GH-312 preserve-list coverage. rated 75/50/60/45. → [GH-105-VENDOR-RELEASES-ADDON.md](PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md) · [#105](https://github.com/HiQS-Labs/XYZ-forge/issues/105)
   154	- **GH-233 · AgentChorus Gen 2 Phase 2 ** ✅ **SHIPPED 2026-08-26 (PR #244)** — Lifecycle Verbs, Watch Invalidation, Concurrency Suite & Citation Linter** 🚧 **active 2026-08-25 for release 0.7.4 "Linux-RC" (#224)** — operator-mediated invite with SKILL.md invariant reconciliation, atomic start --supersedes, terminal watch invalidation, multi-agent concurrency stress suite, and verify-citations ref-pinning linter. cx3/risk2/eff3. → [GH-233-AGENTCHORUS-GEN2-PHASE2.md](PROJECT/2-WORKING/GH-233-AGENTCHORUS-GEN2-PHASE2.md) · [#233](https://github.com/HiQS-Labs/XYZ-forge/issues/233)
   155	- **GH-232 · wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs** ✅ **SHIPPED 2026-08-26 (PR #235)** — inspect linked GitHub issue state before doc promotion; keep docs in PROJECT/2-WORKING/ while linked issue is OPEN; append merge evidence without moving file. cx2/risk2/eff2. → [GH-232-WAVE-RECONCILER-MULTIPHASE.md](PROJECT/2-WORKING/GH-232-WAVE-RECONCILER-MULTIPHASE.md) · [#232](https://github.com/HiQS-Labs/XYZ-forge/issues/232)
   156	- **GH-228 · Org rename HiQS-Suite → HiQS-Labs: a hardcoded regex silently drops issue URLs from the roadmap shadow** ✅ **SHIPPED 2026-08-24 (commit 64c2d2d1; issue closed)** — widen regex in releases_app.py to HiQS-(?:Suite|Labs), update default repo and remote in scripts, add regression test in gh69 suite. rated 80/60/75/90. → [GH-228-ROADMAP-ORG-RENAME-REGEX.md](PROJECT/3-COMPLETED/GH-228-ROADMAP-ORG-RENAME-REGEX.md) · [#228](https://github.com/HiQS-Labs/XYZ-forge/issues/228)
   157	- **GH-226 · xyz-vendor.sh transcript gate refuses repos that gitignore transcripts** ✅ **SHIPPED 2026-08-24 (commit 654e4440, QA 3ee2e8f0; issue closed)** — downgrade transcript gitignore check from exit 6 to advisory warning so downstream repos can vendor `.xyz/`. rated 75/50/80/85. → [GH-226-VENDOR-TRANSCRIPT-GATE.md](PROJECT/3-COMPLETED/GH-226-VENDOR-TRANSCRIPT-GATE.md) · [#226](https://github.com/HiQS-Labs/XYZ-forge/issues/226)
   158	- **GH-114 · headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)** ✅ **SHIPPED 2026-08-24 (PR #214)** — force fully headless invocation (no /dev/tty), and make idle-kills name the real blocker in the turn log. rated 80/60/80/60. → [GH-114-HEADLESS-TTY-IDLE-HANG.md](PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md) · [#114](https://github.com/HiQS-Labs/XYZ-forge/issues/114)
   159	- **GH-113 · headless agy builder writes root scratch files, tripping containment (exit 6)** ✅ **SHIPPED 2026-08-24 (PR #214)** — give headless builder turns a sanctioned scratch lane (.relay-scratch/<turn>/) so debugging temp files relocate instead of failing the turn; tracked-file violations still exit 6. rated 85/60/85/60. → [GH-113-HEADLESS-SCRATCH-CONTAINMENT.md](PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md) · [#113](https://github.com/HiQS-Labs/XYZ-forge/issues/113)
   160	- **GH-91 · a build turn has nowhere to write verification output ** ✅ **SHIPPED 2026-08-24 (PR #214)** — containment kills a complete, green turn** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — issue option 1: `.relay-scratch/` as an intrinsic write category — pre-created by `rtl_worktree_begin`, exempted in `rtl_worktree_end` (no signature check; never copied back), exempted-and-discarded in `rtl_check` (non-worktree path), and NAMED in `rtl_turn_prompt` at the point of use. New suite `test/gh91-relay-scratch.sh` 15/0 with controls (stray still exit-6, lookalike prefix not exempt, off-lane copies nothing back); containment-pinning neighbors green. Surfaced by the daybreak wave-1 re-fire after #90. rated 60/65/55/75. → [GH-91-RELAY-SCRATCH-DIR.md](PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md) · [#91](https://github.com/HiQS-Labs/XYZ-forge/issues/91)
   161	- **GH-168 · wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR** ✅ **SHIPPED 2026-08-24 (PR #220)** — scope the drift check to the reconciled PR; unrelated drift warns without rollback; move-not-add idempotent promotion. rated 80/55/85/70. → [GH-168-WAVE-RECONCILE-SCOPE.md](PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md) · [#168](https://github.com/HiQS-Labs/XYZ-forge/issues/168)
   162	- **GH-50 · sandboxed git --track / branch -D half-applies and loses uncommitted work** ✅ **SHIPPED 2026-08-24 (PR #220)** — branch ops refuse-or-succeed atomically when .git/config is unwritable. rated 65/35/85/80. → [GH-50-SANDBOXED-GIT-HALF-APPLY.md](PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md) · [#50](https://github.com/HiQS-Labs/XYZ-forge/issues/50)
   163	- **GH-2 · test-suite run relocated an untracked file into .tick/orphan-backups/** ✅ **SHIPPED 2026-08-24 (PR #220)** — reproduce under parallel load, then guard every mv/rm/find-delete on a derived path with resolved containment. rated 80/55/85/55. → [GH-2-ORPHAN-BACKUP-RELOCATION.md](PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md) · [#2](https://github.com/HiQS-Labs/XYZ-forge/issues/2)
   164	- **GH-202 · wave_reconcile aborts on marathon-plan exit 5 (items held) and promotes capture docs for OPEN issues** ✅ **SHIPPED 2026-08-24 (PR #210)** — hotfix, the reconciler sits on every merge critical path** — tolerate the items-held planning state (log + continue), and consult the linked issue's open/closed state before promoting a doc: OPEN keeps the doc active with recorded merge evidence (idempotent), unknown state promotes as before (offline-manifest backward compat). rated 85/65/85/70. → [GH-202-WAVE-RECONCILER-STATE.md](PROJECT/2-WORKING/GH-202-WAVE-RECONCILER-STATE.md) · [#202](https://github.com/HiQS-Labs/XYZ-forge/issues/202)
   165	- **GH-197 · two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)** ✅ **SHIPPED 2026-08-24 (PR #210)** — deny-list tier split in `materialize_vendor()` (`--with-releases`), sticky Tier 2 auto-detect via `releases.db` at target root for the 9 vendored repos, and `xyz-releases-onboard.sh` mechanizing the LTVera-Pandas `ad0d816` onboarding (import, gitignore carve-out, banner, MIG- reconcile with shared-tracking-URL refusal, no auto-commit). rated 80/55/65/50. → [GH-197-VENDOR-TIER-SPLIT.md](PROJECT/2-WORKING/GH-197-VENDOR-TIER-SPLIT.md) · [#197](https://github.com/HiQS-Labs/XYZ-forge/issues/197)
   166	- **GH-193 · AgentChorus Gen 2 ** ✅ **SHIPPED 2026-08-24 (PR #210)** — telemetry, decision-quality metrics, measurable experiments (Agent2Agent renamed)** 🚧 **active 2026-08-24 for release 0.7.3 "Bulkhead" (#179); Phases 0-1 SHIPPED (PR #196, PR #200 2026-08-24 — telemetry + registry + outcome + audit + data policy; suite 142/142); pilot window running; phases 2-3 continue** — make discussion decisions measurable: metadata-only telemetry with a structural no-content allowlist, a store-level aggregate registry, per-model outcome attribution, supersession/lifecycle verbs, verify-citations with ref pinning, and experiment flags (steelman, stance prior) gated on the ≥10-discussion pilot corpus. rated 75/70/85/50. → [GH-193-AGENTCHORUS-GEN2.md](PROJECT/2-WORKING/GH-193-AGENTCHORUS-GEN2.md) · [#193](https://github.com/HiQS-Labs/XYZ-forge/issues/193)
   167	
   168	- **GH-1 · suite-wide fixture containment + clone-identity invariant gate** ✅ **SHIPPED 2026-08-24 (PR #210)** — the detect-half (`test/lib/clone-identity.sh` bracket in `validate.sh`) and the shared resolved-containment `require_fixture` (`test/lib/fixture-guard.sh`) landed via PR #6; the reopen condition "#1 closes when #10's acceptance lands" fired when `31c31b7` delivered the derived-from-source adoption guard (`test/gh1-adoption-guard.sh`, no hand-maintained exception list) + ci-local identity bracket and the operator closed #10. Verified at close: gh1-fixture-guard 17/0, gh1-adoption-guard 11/0. → [GH-1-SUITE-CONTAINMENT-GATE.md](PROJECT/2-WORKING/GH-1-SUITE-CONTAINMENT-GATE.md) · [#1](https://github.com/HiQS-Labs/XYZ-forge/issues/1)
   169	- **GH-174 · Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator** ✅ **SHIPPED 2026-08-23 (PR #174; issue closed)** — migrate static HARNESS-MODELS-REGISTRY.md into active SQLite ledger (harnesses.db) with DRY per-device configs, reasoning level tracking, deterministic post-turn AI grading hooks, and automated blog generation. rated 85/75/95/45. → [GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md](PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md) · [#174](https://github.com/HiQS-Labs/XYZ-forge/issues/174)
   170	- **GH-115 · marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)** ✅ **SHIPPED 2026-08-23 (PR #194; Bulkhead wave)** — progress-aware bounded cap extension + per-phase cap override; stalled caps still escalate. rated 75/50/85/70. → [GH-115-ROUND-CAP-ESCALATION.md](PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md) · [#115](https://github.com/HiQS-Labs/XYZ-forge/issues/115)
   171	- **GH-8 · kernel boundary hardening — CLI numeric validation, task/agent format contract** ✅ **SHIPPED 2026-08-23 (PR #188; Bulkhead wave)** — reject NaN/malformed CLI input and unbounded task/agent strings at the boundary instead of persisting them. rated 75/55/80/65. → [GH-8-KERNEL-BOUNDARY-HARDENING.md](PROJECT/3-COMPLETED/GH-8-KERNEL-BOUNDARY-HARDENING.md) · [#8](https://github.com/HiQS-Labs/XYZ-forge/issues/8)
   172	- **GH-180 · repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — map null-exit records to a first-class timeout signature instead of `int(None)`; the fuzzer's most common record class must build reproducers, not crash them. rated 70/45/85/80. → [GH-180-REPRO-TIMEOUT-CRASH.md](PROJECT/3-COMPLETED/GH-180-REPRO-TIMEOUT-CRASH.md) · [#180](https://github.com/HiQS-Labs/XYZ-forge/issues/180)
   173	- **GH-181 · repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — telemetry schema 1.1 (`argv` list + realized `env` + failure signature, emitter side) and signature-matching ingest; the real GH-141 record becomes the permanent end-to-end regression fixture (#174's finding-travels-untouched criterion). rated 90/75/90/60. → [GH-181-REPRO-ADAPTER-FIDELITY.md](PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md) · [#181](https://github.com/HiQS-Labs/XYZ-forge/issues/181)
   174	- **GH-183 · active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — declared `--base-env` driving the full missing/empty/corrupted vector set from a clean environment; ambient `RELAY_*` provably cannot satisfy mutations. rated 65/50/75/70. → [GH-183-EXPLORER-ENV-SOUNDNESS.md](PROJECT/3-COMPLETED/GH-183-EXPLORER-ENV-SOUNDNESS.md) · [#183](https://github.com/HiQS-Labs/XYZ-forge/issues/183)
   175	- **GH-184 · committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — remove the PR #160 artifact and add a derived no-tracked-scratch guard, so the lane's by-design discard can never dirty a clone (success-shaped-exit mutation found in soak §3.5). rated 60/40/80/90. → [GH-184-TRACKED-SCRATCH-ARTIFACT.md](PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md) · [#184](https://github.com/HiQS-Labs/XYZ-forge/issues/184)
   176	- **GH-195 · marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call** ✅ **SHIPPED 2026-08-23 (in PR #194)** — GH-115's own new test committed a live transcript onto the real clone on every `validate.sh` run because `marathon-root-audit.sh` only audits `bash <driver>.sh` invocations, never a direct Python call; same defect class as GH-401, reopened via a different invocation shape. Root-caused via direct instrumentation after ~2.5h of correctly-reasoned-but-wrong process-hunting. rated 60/40/50/20. → [GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md](PROJECT/3-COMPLETED/GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md) · [#195](https://github.com/HiQS-Labs/XYZ-forge/issues/195)
   177	- **GH-10 · prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — resolves the 2026-08-17 marathon cut (enforcement without adoption) by adopting for real: `_setup.sh` centrally, 35 suites mechanically, 7 by hand (out-of-root fixtures nested under pinned sandboxes); `test/gh1-adoption-guard.sh` derives offenders from source every run (exemptions declared in-file — no permanent exception list), controls prove it fires; `ci-local.sh` gains the GH-1 identity bracket; ledger records **Unaudited suites: 0**. Drive-by: fixture-guard.sh shellcheck `-S error` fix (pre-existing ci-local red). rated 55/70/50/80. → [GH-10-REQUIRE-FIXTURE-ADOPTION.md](PROJECT/2-WORKING/GH-10-REQUIRE-FIXTURE-ADOPTION.md) · [#10](https://github.com/HiQS-Labs/XYZ-forge/issues/10)
   178	- **GH-35 · 3-tier test suite selection (docs / utility subsystems / core) + CPU governance** ✅ **Phases 1+2 BUILT 2026-08-18 on `development` (standalone clone `XYZ-forge-gh35`)** — one fail-closed subsystem registry in `utils/ci-route.sh` (hq, releases, telemetry, ate, swe-diagram, pdda, agent2agent) consumed by `githooks/pre-push` and `validate.sh`; `--tier/--subsystem/--auto/--paths-file`; the parallel default rebalanced from `cores-2` (up to 8) to `cores/2` (cap 4) with every worker under `nice -n 10`, plus `--throttle`/`--burst`/`XYZ_VALIDATE_THROTTLE`/`XYZ_VALIDATE_MAX_JOBS`. Utility pushes drop from the full ~4-min pool to their focused suites (~20-45s target, measurement owed). New suite `test/gh35-test-tiers.sh` 56/0; pre-push suite extended to 85/0. Phase 3 (CI alignment + every-file-classified sweep) pending. rated 55/45/50/45. → [GH-35-TEST-TIER-ROUTING.md](PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md) · [#35](https://github.com/HiQS-Labs/XYZ-forge/issues/35)
   179	- **GH-42 · relay automation: supported Commandcode turn-taker** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — add a Python-authoritative, containment-preserving Commandcode adapter with mocked regression coverage; Muse Spark Contributor is the initial builder and Codex performs independent QA. rated 50/35/55/45. → [GH-42-COMMANDCODE-TURN.md](PROJECT/2-WORKING/GH-42-COMMANDCODE-TURN.md) · [#42](https://github.com/HiQS-Labs/XYZ-forge/issues/42)
   180	- **GH-170 · Agent2Agent: close transcript glitches and harden publishing** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — external canonical transcript store with required producer packets, structured scope extension and close operations, verified Git handoffs, heartbeat-aware stale reporting, and a manifest-driven drift-refusing standalone publisher with downstream CI (HiQS-Labs/Agent2Agent-Skill#1–5). rated 75/60/85/55. → [GH-170-AGENT2AGENT-GLITCHES.md](PROJECT/2-WORKING/GH-170-AGENT2AGENT-GLITCHES.md) · [#170](https://github.com/HiQS-Labs/XYZ-forge/issues/170)
   181	- **GH-165 · Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — implement the canonical Python post-merge wave and marathon lifecycle reconciler (`utils/py/wave_reconcile.py`) to atomically transition active docs from `2-WORKING` to `3-COMPLETED`, archive `ROADMAP.md` entries, sync `releases.db`, rebake dashboard views, and compute next-wave concurrency plans without split-brain script sprawl. rated 90/80/90/35. → [GH-165-POST-MERGE-WAVE-RECONCILER.md](PROJECT/1-INBOX/GH-165-POST-MERGE-WAVE-RECONCILER.md) · [#165](https://github.com/HiQS-Labs/XYZ-forge/issues/165)
   182	- **GH-124 · eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — eliminate 50+ minutes of daily closeout friction: on-disk local gate receipts (`ci-local.sh` / `validate.sh`), driver-refreshed early drift alerts, safe manifest-bounded workspace sweep with soft quarantine, hardened `marathon-closeout.sh`, and post-gate in-flight QA attestation comments. rated 85/60/90/40. → [GH-124-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md) · [#124](https://github.com/HiQS-Labs/XYZ-forge/issues/124)
   183	- **GH-77 · `/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — the instrument the operator reaches for constantly, and the answer to the confidence problem the 2026-08-19 audit exposed: a shipped release left `active` for a day, four ledger markers contradicting GitHub, five issues filed into no index — all discoverable in seconds, none discovered by anything. Session + local state only (no history sweep; `/radar` keeps that job), park-only write authority, both halves every run, tactical list hard-capped at 7 items and the strategic read at ~5 lines. Carries an interface catalogue for the RELEASES CLI, the ROADMAP entry schema, PDDA lifecycle, and the one-marathon rail, so every recommendation names the exact command that closes it. rated 95/70/85/30. → [GH-77-STANDUP-SESSION-TRIAGE.md](PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md) · [#77](https://github.com/HiQS-Labs/XYZ-forge/issues/77) · [GH-77-STANDUP-SESSION-TRIAGE.md](PROJECT/2-WORKING/GH-77-STANDUP-SESSION-TRIAGE.md)
   184	- **GH-153 · RELEASES dashboard sidebar + full-cycle rollup (technical spike)** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — additive left-sidebar navigation in the ONE shared timeline template (default ON, hamburger slideout, minimize-to-icon-rail, project switcher, explicit non-link placeholders) so both baked artifacts inherit it with no restructure; new shared read-only `utils/py/releases_cycle.py` extends the HQ daily rollup from marathon-runs-only to the entire ledger cycle AND feeds the sidebar panel (one source of truth — the two surfaces cannot disagree); `utils/hq/rollup.sh` gains the per-repo `## RELEASES cycle` section with the verbatim-embed rule and visible per-repo failure banners. Suites: gh153 40/0, hq-rollup 36/0, gh103 38/0. rated 70/55/80/45. → [GH-153-RELEASES-SIDEBAR-ROLLUP.md](PROJECT/3-COMPLETED/GH-153-RELEASES-SIDEBAR-ROLLUP.md) · [#153](https://github.com/HiQS-Labs/XYZ-forge/issues/153)
   185	- **GH-148 · DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — integrate open-source DeepSeek Harness (`dsh`) with modular Cordis plugin architecture, implement Python twin `utils/py/deepseek-turn.py` and shim `relay-automation/deepseek-turn.sh` with OpenRouter `deepseek/deepseek-v4-pro` route, pass 11/11 suite assertions (`test/gh148-deepseek-turn.sh`), and resolve 3 candidate bugs (GH-142, GH-68, GH-65) in an isolated clone with A-grade builder qualification. rated 85/75/90/40. → [GH-148-DEEPSEEK-HARNESS.md](PROJECT/3-COMPLETED/GH-148-DEEPSEEK-HARNESS.md) · [#148](https://github.com/HiQS-Labs/XYZ-forge/issues/148)
   186	- **GH-144 · Agent2Agent 3+ participant onboarding + read-only status quick wins** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — `start --agents N` prints every non-initiator invitation and seat-agnostic `status --id` reports roster/turn/advisory doorbells without writing; no protocol, storage, routing, or transport expansion. Focused suite 129/0 with recorded pre-fix red control. rated 55/30/80/90. → [GH-144-AGENT2AGENT-3PLUS-UX.md](PROJECT/3-COMPLETED/GH-144-AGENT2AGENT-3PLUS-UX.md) · [#144](https://github.com/HiQS-Labs/XYZ-forge/issues/144)
   187	- **GH-132 · feat(skills): formal /review-xyz code review skill & multi-model harness** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — first-class deterministic code review skill (/review-xyz) and Python engine (utils/py/review_xyz.py) providing throwaway-worktree isolated multi-model code review (Command Code -> Qwen 3.8-Max, GLM-5.3; Aider/OpenRouter; Codex; Agy), structured finding extraction ([Blocker]/[Should]/[Nit]/[Pass]), and automated GitHub PR/issue commenting. rated 80/70/85/40. → [GH-132-REVIEW-XYZ-SKILL.md](PROJECT/3-COMPLETED/GH-132-REVIEW-XYZ-SKILL.md) · [#132](https://github.com/HiQS-Labs/XYZ-forge/issues/132)
   188	- **GH-155 · 3rd Gen ATE & Fuzzing ** ✅ **SHIPPED 2026-08-23 (PR #173)** — All 5 Phases Built (Metamorphic Invariants, Differential Oracles, Reproducers, Self-Healing & Active Explorers)** 🚧 **active 2026-08-22 on branch `feat/gh155-p5-active-explorer`** — build deterministic $0 metamorphic invariant assertion oracles (Phase 1), differential multi-harness cross-testing oracles (Phase 2), hermetic delta-minimizers (Phase 3), autonomous self-healing loops (Phase 4), and the 4-family active explorer (Phase 5). 5-phase roadmap ratified in issue #155. rated 85/70/90/50. → [GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md](PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md) · [#155](https://github.com/HiQS-Labs/XYZ-forge/issues/155)
   189	- **GH-135..140 · Wave-1 follow-ups: consult preflight verdict, attempts-gate root, suite registration, twin-divergence record, SIGPIPE sweep+guard, utcnow swap** ✅ **SHIPPED 2026-08-22 (PR #145, squash 9c07f0cc; issues closed)** — six follow-up issues fixed on one branch: consult.py routes non-zero whoami exits through the shared verdict (#135); TICK_REPO_ROOT resolves ahead of the lane-attempt gate with the NOTE still after the lock (#136); the Wave-1 suites + the gh139 guard registered in TESTS (#137); the post-#129 twin divergence pinned (#138); 369 of 482 pipe-into-`grep -q` sites swept to capture-then-match with a ratchet guard over a ~120-entry shrinking baseline (#139 — the sweep's own gate run caught and repaired three negation-inversion conversions and signal-triage's escaped-quote mangle, each verified by suite re-run); the three utcnow() sites swapped timezone-aware (#140). Full gate 237/237; relay QA by agy returned VERDICT: PASS. → [GH-135-CONSULT-AGY-PREFLIGHT.md](PROJECT/3-COMPLETED/GH-135-CONSULT-AGY-PREFLIGHT.md) · [GH-136-ATTEMPTS-GATE-ROOT.md](PROJECT/3-COMPLETED/GH-136-ATTEMPTS-GATE-ROOT.md) · [GH-137-SUITE-REGISTRATION.md](PROJECT/3-COMPLETED/GH-137-SUITE-REGISTRATION.md) · [GH-138-TWIN-DIVERGENCE-RECORD.md](PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md) · [GH-139-SIGPIPE-SWEEP-GUARD.md](PROJECT/3-COMPLETED/GH-139-SIGPIPE-SWEEP-GUARD.md) · [GH-140-UTCNOW-DEPRECATION.md](PROJECT/3-COMPLETED/GH-140-UTCNOW-DEPRECATION.md)
   190	- **#129/#130/#131 · Wave 1 of the Harness Driver & Relay Seam Hardening marathon — three preflighted driver/relay fixes** ✅ **SHIPPED 2026-08-22 (PR #134, squash d92236cb; issues closed)** — relay-drive self-resolves TICK_REPO_ROOT via resolve_turn_root when unset and replaces the misleading "token missing" with a diagnostic naming the resolved root and searched event dir, every escalation pinned at exit 4; the agy auth preflight classifies usage/CLI-syntax errors as unverifiable (non-blocking) while credentials errors stay exit 5; marathon-drive's phase write-set (RELAY.md/ESCALATION.md) commits route to `phase_commit_root` — the repo containing phase_dir — making `--target-root` + target `--phases-dir` runnable for the first time. Three suites (33 assertions) with recorded pre-fix negative controls; full gate 233/233; first-gate run caught the gh376 twin-parity ordering defect (NOTE must print after the lock refusal). Follow-ups filed as #135-#140. → [#129](https://github.com/HiQS-Labs/XYZ-forge/issues/129) · [#130](https://github.com/HiQS-Labs/XYZ-forge/issues/130) · [#131](https://github.com/HiQS-Labs/XYZ-forge/issues/131)
   191	- **GH-111 · retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state** ✅ **SHIPPED 2026-08-21 (PR #116; issue closed)** — membership became machine-checkable instead of a sentence someone remembered to write: three states (`dialed_in`/`shipped`/`cut`), exclusivity by a partial unique index over ACTIVE membership only, a real `releases migrate` upgrade path where none existed, and BASELINES replacing what the freeze used to buy (progress against the live manifest, growth against the kickoff count). Closed #109 (the viewer asserted marathon membership the data never claimed) and #110 (`shipped` was a state nothing could write). rated 85/75/70/35. → [GH-111-DIALED-IN.md](PROJECT/3-COMPLETED/GH-111-DIALED-IN.md) · [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111)
   192	- **GH-108 · pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)** ✅ **SHIPPED 2026-08-21 (PR #116; issue closed)** — one scoring vocabulary for every task in the ledger, oriented so a single glance answers what should go to the front of the line: four axes 1-100 where higher is always better (effort scores cheapness), a combined 4-400 `calc` derived and never stored, and an `ovr` override that pins anything visible. Authored as `rated N/N/N/N` on a ROADMAP entry; read via `bash utils/leaderboard.sh` or LEADERBOARD.html. rated 80/50/75/40. → [GH-108-RATING-SYSTEM.md](PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md) · [#108](https://github.com/HiQS-Labs/XYZ-forge/issues/108)
   193	- **Execution checklist for GH-111 + GH-108** ✅ **SHIPPED 2026-08-21 (PR #116)** — the running list covering every deliverable of the two plans above, in dependency order, so a stall at any point left the next move unambiguous. Retired with them: both plans are now in 3-COMPLETED, which was this doc's own stated end condition. rated 40/20/35/95. → [GH-108-GH-111-EXECUTION-TODO.md](PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md) · [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111)
   194	- **GH-101 · Feasibility Study: Promoting Programmatic Script Runner (`script_runner.py`) into Core Relay & Consult Runtimes** ✅ **SHIPPED 2026-08-20 (issue closed)** — evaluated and promoted programmatic tool mode across `consult.py` and `relay_drive.py` behind `--tool-mode programmatic` (default off); completed 3-test qualification ladder (Test 1 architectural review & fail-closed threat scoping; Test 2 consult dogfooding with throwaway worktree isolation, pre-created `.relay-scratch/`, and 1,935-trial paired density benchmark in `TESTS-RESULTS/2026-08-20+GH-101/`; Test 3 relay-drive PGID process cleanup stress and fail-closed sandbox checks in `test/synthetic/gh101-relay-programmatic-stress.sh`); promoted to Production-Ready (A-Grade) in `HARNESS-MODELS-REGISTRY.md`. → [GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md](PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md) · [#101](https://github.com/HiQS-Labs/XYZ-forge/issues/101)
   195	- **GH-103 · technical spike: RELEASES SQLite → timeline-ui ledger viewer (RELEASES dashboard view)** ✅ **SHIPPED 2026-08-20 (PR #104; issue closed)** — read-only exporter `utils/timeline/export_timeline.py` projects `releases.db` into timeline-ui's `data.json` contract; viewer `utils/timeline/RELEASES.html` (header collapse caret, full-viewport liquid layout, scrollable detour lanes); `--preview` bakes the committed `RELEASES-PREVIEW.html` snapshot, auto-refreshed after every CLI write by the GH-106 hook; `--serve` answers `/data.json` live from the DB; band-aware RELEASES.md-vs-DB drift banner. Zero DB writes (SQLite `mode=ro`). Prototype for the queued #75 `releases dashboard` verb; follow-on integration tracked in #107 (Cargo). → [GH-103-TIMELINE-LEDGER-SPIKE.md](PROJECT/1-INBOX/GH-103-TIMELINE-LEDGER-SPIKE.md) · [#103](https://github.com/HiQS-Labs/XYZ-forge/issues/103)
   196	- **GH-102 · Unify Telemetry Schema & Inspection Tooling Across Fuzzing and ATE** ✅ **SHIPPED 2026-08-20 (issue closed)** — standardized shared data contract (`schema_version: "1.0"`), instrumented `utils/fuzzing/fuzz-loop.sh` with argv-safe JSONL emission and sub-second millisecond timing; updated `utils/ate/scripts/run_variations.py` to triage `tokens_source` (`api_usage` vs `config_provided` vs `unsupported`); upgraded `utils/ate/scripts/checkin.py` into a universal inspector with nearest-rank percentiles and comparative side-by-side mode; verified via `test/synthetic/gh102-telemetry-schema.sh` (8/8 PASS) and archived receipts in `TESTS-RESULTS/2026-08-20+GH-102/`. → [GH-102-UNIFIED-TELEMETRY-TOOLING.md](PROJECT/3-COMPLETED/GH-102-UNIFIED-TELEMETRY-TOOLING.md) · [#102](https://github.com/HiQS-Labs/XYZ-forge/issues/102)
   197	- **GH-94 · research: programmatic tool calling & code-mode execution for harnesses, telemetry, and containment** ✅ **SHIPPED 2026-08-20 (PR #100; issue closed)** — implemented `utils/py/script_runner.py` with AST serialization normalization, PGID process-group session management (`setsid`), and fail-closed macOS seatbelt sandboxing (`sandbox-exec`); instrumented `utils/ate/scripts/run_variations.py` with telemetry schema 1.0; completed 438-iteration variation campaign with local Gemma 4 classifier triage archived in `TESTS-RESULTS/2026-08-20+GH-94/`; verified synthetic suites `gh94-script-serialization.sh` and `gh94-containment-invariants.sh` (7/7 PASS). → [GH-94-PROGRAMMATIC-TOOL-CALLING.md](PROJECT/3-COMPLETED/GH-94-PROGRAMMATIC-TOOL-CALLING.md) · [#94](https://github.com/HiQS-Labs/XYZ-forge/issues/94)
   198	- **GH-57 · test(releases): SQLite ledger fuzzing recipes & multi-scenario resilience suite** ✅ **SHIPPED 2026-08-19 (PR #60 + PR #70; issue closed)** — synthetic fuzzing recipes and edge-case scenario coverage in `test/gh57-releases-fuzz.sh` (42/42 assertions) for concurrent branch divergence, multi-generation merge headers, duplicate settings/GID collisions, crash injection & journal recovery at 5 boundaries, common-dir lock contention, torn dump protection, and Markdown drift; evaluated non-interactive model routing across Muse Spark, Qwen 3.8-Max, GLM-5.2, and Codex. → [GH-57-RELEASES-SQLITE-FUZZING.md](PROJECT/3-COMPLETED/GH-57-RELEASES-SQLITE-FUZZING.md) · [#57](https://github.com/HiQS-Labs/XYZ-forge/issues/57)
   199	- **GH-45 · validate.sh must refuse to run from a linked worktree — an observed run corrupted the parent clone** ✅ **SHIPPED 2026-08-18 (PR #55, built on `development` in clone `XYZ-forge-gh35`; issue closed 2026-08-19)** — `validate.sh` AND `ci-local.sh` now refuse (exit 2, before anything runs, every tier) when invoked from a linked git worktree, using the issue's verified `--absolute-git-dir` vs `--git-common-dir` comparison anchored on both HERE and the CWD. The refusal names the observed 2026-08-19 damage (core.bare=true, origin repointed, remote refs deleted, development overwritten with fixture commits); `XYZ_ALLOW_WORKTREE_GATE=1` overrides and announces itself. Pinned in `test/gh35-test-tiers.sh` §9 incl. the required control (normal checkout of the same repo still runs, silently). → [GH-45-WORKTREE-GATE-REFUSAL.md](PROJECT/3-COMPLETED/GH-45-WORKTREE-GATE-REFUSAL.md) · [#45](https://github.com/HiQS-Labs/XYZ-forge/issues/45) · [#564](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/564)
   200	- **GH-39 · RELEASES app: one-way GitHub Project release-card projection** ✅ **SHIPPED 2026-08-18 (issue closed)** — explicit `project sync` dry-run/apply writer maps every ledger release by immutable Release ID, refuses mismatched Project schema, and keeps GitHub cards read-only from the ledger’s perspective. → [GH-39-RELEASES-PROJECT-SYNC.md](PROJECT/3-COMPLETED/GH-39-RELEASES-PROJECT-SYNC.md) · [#39](https://github.com/HiQS-Labs/XYZ-forge/issues/39)
   201	- **GH-23 · Kernel invariant: enforce path-overlap rejection on direct tick claim and tick scope** ✅ **SHIPPED — issue closed 2026-08-19; built on `fix/gh-23-kernel-overlap-enforcement`** — enforce collision-free path claims at the kernel boundary by rejecting direct `tick claim` and `tick scope` when requested paths overlap active claims held by other agents; wire `--force` bypass; add regression test coverage. → [GH-23-KERNEL-OVERLAP-ENFORCEMENT.md](PROJECT/3-COMPLETED/GH-23-KERNEL-OVERLAP-ENFORCEMENT.md) · [#23](https://github.com/HiQS-Labs/XYZ-forge/issues/23)
   202	- **GH-4 · the pre-push gate does not travel with clones: fresh clones push unverified** ✅ **SHIPPED 2026-08-17, orchestrator-authored directly** — `validate.sh` warns non-fatally when the clone is ungated (verified both directions: fires when ungated, silent when gated); README documents the install step as a correctness requirement. A prior driven-marathon attempt escalated after 5 rounds without landing this (see `test/baselines/GH-4-negative-control.md`'s design note). → [GH-4-GATE-TRAVELS-WITH-CLONES.md](PROJECT/3-COMPLETED/GH-4-GATE-TRAVELS-WITH-CLONES.md) · [#4](https://github.com/HiQS-Labs/XYZ-forge/issues/4)
   203	- **GH-14 · appendEvent writes non-atomically, so concurrent readers can observe torn event files** ✅ **SHIPPED 2026-08-17 (PR #21)** — `appendEvent` writes to a `.tmp` name then `renameSync`s into place; a `.jsonl` file that exists is always complete. `test/gh14-atomic-append.sh` 6/0; negative control `test/baselines/GH-14-negative-control.md` (5/1 pre-fix). Gap: the two `test/unit/events.test.js` cases deferred from PR #7 (quarantine, empty-file skip) were not re-authored; #5 stays open on that gap. → [GH-14-ATOMIC-EVENT-APPEND.md](PROJECT/3-COMPLETED/GH-14-ATOMIC-EVENT-APPEND.md) · [#14](https://github.com/HiQS-Labs/XYZ-forge/issues/14)
   204	- **GH-15 · parallel runs are unreliable in a fresh clone; the GH-528 contention retry is not honoring its contract** ✅ **SHIPPED 2026-08-17 (PR #20 + orchestrator reconciliation)** — `validate.sh`'s parallel retry gives every suite `stdin=/dev/null`, adds a completeness catch-up for suites with no result line, and a tally-integrity guard. `test/gh528-parallel-contention-retry.sh` 9/0; negative control `test/baselines/GH-15-parallel-contention-negative-control.md` (5/4 pre-fix). Ten consecutive parallel fresh-clone runs: 10/10 exit 0, zero failures, zero contention. → [GH-15-PARALLEL-FRESH-CLONE-RELIABILITY.md](PROJECT/3-COMPLETED/GH-15-PARALLEL-FRESH-CLONE-RELIABILITY.md) · [#15](https://github.com/HiQS-Labs/XYZ-forge/issues/15)
   205	- **GH-3 · improve-loop.sh --state-dir durability — provenance evidence must not evaporate** ✅ **SHIPPED 2026-08-17 (closed as landed)** — durable default and path-printing were already landed pre-Ballast (GH-430); the sole remaining gap, a recorded negative control, closed 2026-08-17 (`test/baselines/GH-3-state-dir-negative-control.md`, 6/2 pre-fix → 8/0 post-fix). → [GH-3-IMPROVE-LOOP-STATE-DIR.md](PROJECT/3-COMPLETED/GH-3-IMPROVE-LOOP-STATE-DIR.md) · [#3](https://github.com/HiQS-Labs/XYZ-forge/issues/3)
   206	### Deferred · vision
   207	
   208	*(empty since the 2026-08-19 purge — its one entry was upstream-numbered; see
   209	[docs/ROADMAP-UPSTREAM-ARCHIVE.md](docs/ROADMAP-UPSTREAM-ARCHIVE.md). The heading stays because the
   210	planner's `SECTIONS` list names it.)*
   211	
   212	## Entry format
   213	
   214	**This section documents the contract the marathon planner already enforces. It does not introduce
   215	one.** It exists because all three sibling repos (`rebalanceOS`, `sleuth-app`,
   216	`aegis-sleuth-slack-bot`) carry an `## Entry format` section and this repo — which *owns* the
   217	planner — did not, so the rule lived only in downstream copies. See
   218	[#69](https://github.com/HiQS-Labs/XYZ-forge/issues/69).
   219	
   220	One flat bullet per item, name in **bold**:
   221	
   222	```
   223	- **Project / track name** — one-line status summary. → [linked doc](PROJECT/...)
   224	```
   225	
   226	The bold name is required, not cosmetic. The planner (`utils/py/_marathon_plan.py`, and its frozen
   227	Bash twin `utils/marathon-plan.sh`) recognises a ledger entry only when it matches `^- \*\*`, and
   228	only under one of these four `###` headings, spelled exactly:
   229	
   230	| Recognised `###` heading |
   231	|---|
   232	| `Queue / parked intake` |
   233	| `In progress` |
   234	| `Completed` |
   235	| `Deferred · vision` |
   236	
   237	Source of truth for that list: `utils/py/_marathon_plan.py:31` (`SECTIONS`) and
   238	`utils/marathon-plan.sh:232`.
   239	
   240	**Entries anywhere else are skipped silently** — the planner reports `no ledger items parsed` and
   241	writes no plan, with nothing naming what it passed over.
   242	
   243	### What that currently means here
   244	
   245	`### Ad-hoc detours` is **not** in the recognised list, so its one remaining entry (GH-23; the
   246	other three were upstream-numbered and left with the 2026-08-19 purge) is invisible to the
   247	planner. Whether that is intended — a detour arguably should not be marathon-plannable — has never
   248	been written down either way. It is recorded here as an observation, not changed: renaming the
   249	heading would silently make those items plannable, which is a decision for the owner and not a
   250	formatting fix. Tracked on [#69](https://github.com/HiQS-Labs/XYZ-forge/issues/69).
   251	
   252	**After editing the ledger, run `python3 utils/py/releases_app.py roadmap sync`** — the GH-69
   253	shadow mirrors every entry (all sections, this one included) into `releases.db`'s `roadmap_items`
   254	table, losslessly and one-way. `--dry-run` previews; `roadmap list` reads it back. Pinned by
   255	`test/gh69-roadmap-shadow.sh`.
   256	
   257	Bullets above `## Ledger` (the Part A/B/C lines under `## Status`) are narrative, sit outside the
   258	ledger, and are correctly not parsed.
     1	<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
     2	     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
     3	     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
     4	     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
     5	     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
     6	     Enforced by `pdda.sh roadmap` + `pdda.sh roadmap-coverage` (deterministic) + utils/pdda/pdda-doc-ready.sh ROADMAP rubric (LLM). -->
     7	
     8	# Roadmap
     9	
    10	> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
    11	> gates, deep notes) lives in the linked `PROJECT/**` docs; keep it there. **What shipped and why
    12	> lives in [CHANGELOG.md](CHANGELOG.md)** — do not restate release narrative here. See the
    13	> contract banner above.
    14	
    15	## Status
    16	
    17	*Last reconciled against `git log` and CHANGELOG on 2026-08-10.*
    18	
    19	| What was just completed | What's next |
    20	|---|---|
    21	| **v1.3.5x Phase 2 — the seasonal calendar is live, seeded, visible and actionable (2026-08-06 → 08-07).** All five slices shipped: engine, seed caller, two new verticals, both UI screens, the match rail, the freshness triggers, and the dispatch prefill that opens a campaign from a calendar row with the slot's own products. CHANGELOG 0.4.27–0.4.30. | **The remaining work is calibration, not building.** Every score is `assumed`, which is WEAK by construction, so every match renders demoted-and-labelled until **Sam recalibrates the band**; the `detected` tier is gated on [#141](https://github.com/BinoidCBD/LTVera-Pandas/issues/141) and warehouse-tenant best-sellers on [#142](https://github.com/BinoidCBD/LTVera-Pandas/issues/142). Elan's E1–E4 defaults remain 🟡 inferred, not owner-closed. See [PHASE-2-COMPLETION-PLAN-2026-08-06.md](PROJECT/3-COMPLETED/PHASE-2-COMPLETION-PLAN-2026-08-06.md). |
    22	| **GH-143 Phase 0 — per-tenant campaign performance is deployed and carrying live data for Bounce (2026-08-07).** PRs [#145](https://github.com/BinoidCBD/LTVera-Pandas/pull/145) + [#151](https://github.com/BinoidCBD/LTVera-Pandas/pull/151). CHANGELOG 0.4.34 / 0.4.38. | **Two blockers before it serves more than one tenant:** [#152](https://github.com/BinoidCBD/LTVera-Pandas/issues/152) (Binoid and Bloomz collect nothing — duplicate `Placed Order` metrics) and the unverified RLS *read-path* claim. Phases 1–3 not started. |
    23	| **GH-127 — the legacy `wp-db-toolkit` BigQuery project is empty (executed 2026-08-06, merged [#130](https://github.com/BinoidCBD/LTVera-Pandas/pull/130)).** Data migrated first, then 49 datasets + 2 buckets deleted under recorded authorization. CHANGELOG 0.4.35. | **Tier 5c (project shutdown) is unauthorized and out of scope.** Issue [#127](https://github.com/BinoidCBD/LTVera-Pandas/issues/127) is still open pending the operator's close call. |
    24	
    25	## Ledger
    26	
    27	### Queue / parked intake
    28	
    29	- [GH-199 — Previous Newsletter Design Analysis](PROJECT/1-INBOX/GH-199-NEWSLETTER-DESIGN-ANALYSIS.md) — captured 2026-08-18 from [issue #199](https://github.com/BinoidCBD/LTVera-Pandas/issues/199). Three phases: (1) Gemini 3.6 Flash vision seam + Utilities page shell, (2) upload up to 10 images and pattern analysis, (3) per-store Save history. Phase 2 is the current build. Not promoted.
    30	- [GH-276 — Scope the coverage gate to decisioning state, not all signals](PROJECT/1-INBOX/GH-276-SIGNAL-COVERAGE-GATE-SCOPE.md) — captured 2026-08-27 from [issue #276](https://github.com/BinoidCBD/LTVera-Pandas/issues/276). Part (a) of [#42](https://github.com/BinoidCBD/LTVera-Pandas/issues/42), pre-authorized by Sam's 2026-07-15 answer on #43 — no design decision needed. Critical: every non-Bounce tenant gets zero signals today. Queued for `/jog`.
    31	- [GH-275 — Five mechanical follow-ups from #255](PROJECT/1-INBOX/GH-275-MECHANICAL-FOLLOWUPS.md) — captured 2026-08-27 from [issue #275](https://github.com/BinoidCBD/LTVera-Pandas/issues/275). Five independent one-PR-each fixes, each with its own acceptance test. Item 5 (make `refresh-nbp-scores` run seven days) answers the open question on [#282](https://github.com/BinoidCBD/LTVera-Pandas/issues/282). Queued for `/jog`.
    32	- [GH-207 — VM start failures on GCE capacity stockouts have no alarm](PROJECT/1-INBOX/GH-207-VM-STOCKOUT-ALARM.md) — captured 2026-08-27 from [issue #207](https://github.com/BinoidCBD/LTVera-Pandas/issues/207). Production was down ~10 hours on 2026-08-19 with no alert; restore already done, this is the durable fix. Not a code defect — GCE capacity stockout. Queued for `/jog`.
    33	- [GH-115 — Cloud SQL buffer-server-pg has automated backups disabled](PROJECT/1-INBOX/GH-115-BUFFER-SERVER-BACKUPS.md) — captured 2026-08-27 from [issue #115](https://github.com/BinoidCBD/LTVera-Pandas/issues/115). The only copy of in-flight Woo order events not yet projected to BQ has backups off. Infra-only, one `gcloud sql instances patch` call. Queued for `/jog`.
    34	- [GH-251 — Tenant-authored custom calendar events](PROJECT/1-INBOX/GH-251-TENANT-CUSTOM-CALENDAR-EVENTS.md) — captured 2026-08-26 from [issue #251](https://github.com/BinoidCBD/LTVera-Pandas/issues/251). Add "Add Custom Calendar Event" menu item + batch editor (6 field-sets, Save|Reset) + Edit/Delete, backed by new tenant-scoped CRUD on `CalendarWindow` (`layer='brand'`). Not promoted.
    35	- [GH-230 — v1.5x umbrella: customer-facing systems MVP](https://github.com/BinoidCBD/LTVera-Pandas/issues/230) — filed 2026-08-24 as the release-ledger tracking issue for release `1.5.0` in `releases.db` (GID `rel-01M0TN92A6BP20SWRRGKHVCN7Q`). Bundles [#228](https://github.com/BinoidCBD/LTVera-Pandas/issues/228) and [#229](https://github.com/BinoidCBD/LTVera-Pandas/issues/229), both dialed into its manifest, as the two MVP systems. Not promoted.
    36	- [GH-229 — Shopify invite-based tenant onboarding](PROJECT/1-INBOX/GH-229-SHOPIFY-INVITE-ONBOARDING.md) — captured 2026-08-24 from [issue #229](https://github.com/BinoidCBD/LTVera-Pandas/issues/229). Canonical interim Tenant UX: the shop owner invites `onboarding@ltvera.com`, and an LTVera operator securely configures the connector through first sync; App Store/OAuth remains deferred. Related to package UX [#228](https://github.com/BinoidCBD/LTVera-Pandas/issues/228). Dialed into release v1.5x ([#230](https://github.com/BinoidCBD/LTVera-Pandas/issues/230)). Not promoted.
    37	- [GH-228 — Customer package/tiering system: per-tenant feature gates + numeric limits](https://github.com/BinoidCBD/LTVera-Pandas/issues/228) — filed 2026-08-24 as a rough outline from a 5-way codebase recon. ⚠️ **Naming collision:** `Tenant.tier` already exists but is a data-retention concept (Phase 9), unrelated to packaging — the new tier concept needs a different field/table name. No billing/plan infrastructure exists today (no Stripe, no feature-flag system); this is new infrastructure. Four operator questions open in the issue before this becomes a scoped plan. Dialed into release v1.5x ([#230](https://github.com/BinoidCBD/LTVera-Pandas/issues/230)). Not promoted.
    38	- [GH-174 — Auto-deploy development to GCE ltvera-dev on merge](PROJECT/1-INBOX/GH-174-GCE-AUTO-DEPLOY.md) — captured 2026-08-13 from [issue #174](https://github.com/BinoidCBD/LTVera-Pandas/issues/174). One repo script (`scripts/deploy-gce.sh`) owns the GCE deploy; a green CI run on `development` ships it without SSH. Not promoted.
    39	- [GH-157 — Universal Mailgun email helper: one send path for all app mail](PROJECT/1-INBOX/GH-157-MAILGUN-EMAIL-HELPER.md) — captured 2026-08-11 from [issue #157](https://github.com/BinoidCBD/LTVera-Pandas/issues/157). **Phases 1–3 merged 2026-08-12 via PR [#159](https://github.com/BinoidCBD/LTVera-Pandas/pull/159)** (CHANGELOG 0.4.46): `app/mailer.py` is the single send path for app-originated mail, connection-health migrated onto it with the inlined SendGrid call deleted, and #155's two silent-swallow paths now emit a structured `email.send.failed` ERROR. The Keycloak realm repoint is **not** part of this — it shipped and deployed under [#156](https://github.com/BinoidCBD/LTVera-Pandas/issues/156), and Keycloak keeps its own SMTP path permanently (upstream Java, SMTP-only). Supersedes [#155](https://github.com/BinoidCBD/LTVera-Pandas/issues/155). ⚠️ **Still open:** `ltvera-mailgun-api-key` does not exist and the app service account holds project-level `secretAccessor`, so the plan's split-IAM gate is unmet — that gates the Phase 3 production proof, and until the key is set connection-health ops mail stays inert (as it already was).
    40	- [GH-156 — SendGrid → Mailgun for transactional mail](PROJECT/1-INBOX/GH-156-MAILGUN-SMTP-MIGRATION.md) — captured 2026-08-11 from [issue #156](https://github.com/BinoidCBD/LTVera-Pandas/issues/156). SendGrid is over quota and rejecting Keycloak's welcome/password-reset mail ([#155](https://github.com/BinoidCBD/LTVera-Pandas/issues/155)). Operator-fixed scope: **get the existing system working with Mailgun, nothing more** — add `mg.ltvera.com` (decided in the GH-157 doc) to the Binoid Mailgun account, publish its Cloudflare DNS, swap the SMTP constants at `scripts/keycloak_admin_ops.py:44-54`, new GSM secret. The universal helper is [#157](https://github.com/BinoidCBD/LTVera-Pandas/issues/157), deferred. Owner: Matthew. Not promoted.
    41	- [GH-128 — Security audit, unified install & configuration surface](PROJECT/1-INBOX/GH-128-SECURITY-AUDIT-REMEDIATION.md) — captured 2026-08-06 from [issue #128](https://github.com/BinoidCBD/LTVera-Pandas/issues/128); unifies three prior audits into one phased remediation plan. **Phase 1 landed** via a 7-lane marathon (PR [#135](https://github.com/BinoidCBD/LTVera-Pandas/pull/135), CHANGELOG 0.4.36); the doc records which lanes did **not** land and needed a recovery pass. Later phases not started.
    42	- [GH-101 — Klaviyo rate-limit baseline per tenant](PROJECT/1-INBOX/GH-101-KLAVIYO-RATE-LIMIT-BASELINE.md) — captured 2026-07-31 from [issue #101](https://github.com/BinoidCBD/LTVera-Pandas/issues/101). Rules, the per-client SOP and a passive probe (`scripts/probe_klaviyo_rate_limits.py`) shipped ahead of the numbers. ⚠️ **Nothing is measured yet** — needs a device with a tenant key and network to `a.klaviyo.com`. Not promoted.
    43	- [GH-110 — Verify Postgres→BigQuery deploy completeness](PROJECT/1-INBOX/GH-110-POSTGRES-BQ-DEPLOY-VERIFY.md) — captured 2026-08-03 from [issue #110](https://github.com/BinoidCBD/LTVera-Pandas/issues/110). A deploy-completeness audit across buffer-server Cloud Run, the GCE VM Postgres and the BQ datasets — **not** the publisher build. Read-only probes only. Not promoted.
    44	- [GH-112 — Woo + Shopify sync-failure notifications](PROJECT/1-INBOX/GH-112-TENANT-CONNECTION-ALERTING.md) — merged (PR #125) and deployed 2026-08-06 (CHANGELOG 0.4.27). ⚠️ **Alerting is live but its email is inert** — no `CONNECTION_HEALTH_*` keys are set in production. Two things outstanding: inject the read-only buffer Cloud SQL DSN + SendGrid secret reference, and cover the **untested suppression state machine**.
    45	- [GH-42 — Signals blocked for non-Bounce tenants](PROJECT/1-INBOX/GH-42-SIGNAL-CLUSTERING-MULTITENANT.md) — captured 2026-07-07 from [issue #42](https://github.com/BinoidCBD/LTVera-Pandas/issues/42). Design doc authored. **Needs a Sam decision** (does the `taxonomy_halt` block native signals or only prior-borrowing?) before build. Blocks grow-willies Phases 4–5.
    46	- [GH-51 — Elan copy sync: SKUs, cross-sell angles, Tinctures subject line](PROJECT/1-INBOX/GH-51-ELAN-COPY-SYNC.md) — captured 2026-07-14 from [issue #51](https://github.com/BinoidCBD/LTVera-Pandas/issues/51). **Owner: Sam, working it with Elan** — merchant-side positioning calls, not LTVera's; our input is already delivered. Not blocked; gates GH-48 tasks 2.4–2.7 in practice.
    47	- [GH-59 — Woo extraction pipeline duplicated across two trees](PROJECT/1-INBOX/GH-59-WOO-EXTRACT-TREE-DUPLICATION.md) — captured 2026-07-20 from [issue #59](https://github.com/BinoidCBD/LTVera-Pandas/issues/59). Two definitions of one contract (`utils/wp-bq/` vs `pipelines/bq-extraction/`) that have already drifted; **failure mode is silent**. Phase 0 is evidence-gathering, not a build. Nothing is currently blocked on it. Not promoted.
    48	- [Unified UTC time helper — audit, then decide whether to build](PROJECT/1-INBOX/UTC-TIME-HELPER-AUDIT.md) — captured 2026-07-09. 46 aware `datetime.now(timezone.utc)` calls coexist with 18 naive `datetime.utcnow()` calls while all 34 ORM `DateTime` columns are `timezone=True`. **Phase 0 is an audit, not a build**; go/no-go genuinely open.
    49	- [#86 — `open-cdp` is a benchmark dataset modelled as an active tenant](https://github.com/BinoidCBD/LTVera-Pandas/issues/86) — filed 2026-07-27. It must be `active` because `tenants.status` permits nothing else, so it is enumerated for scheduled syncs at maximum cost (5,477,522 orders). **It must stay reachable** — it is the only dataset large enough to reveal query-plan shape, which the v1.3.5x Phase 1.5 performance work depends on. Not promoted.
    50	- [#103 — brand voice + claims rules](https://github.com/BinoidCBD/LTVera-Pandas/issues/103) — scheduled as v1.3.5x Phase 3.5; build list in [GH-79-RELEASE-1-3-5X.md](PROJECT/2-WORKING/v1.3.5/GH-79-RELEASE-1-3-5X.md). Sam's supporting slice shipped 2026-08-07 (CHANGELOG 0.4.33) across four working docs: [mining playbook](PROJECT/2-WORKING/v1.3.5/GH-103-BRAND-VOICE-MINING-PLAYBOOK.md), [tenant Q&A](PROJECT/2-WORKING/v1.3.5/GH-103-BRAND-VOICE-QA.md), [prompt-generator spec](PROJECT/2-WORKING/v1.3.5/GH-103-PROMPT-GENERATOR.md), [file manifest](PROJECT/ARCHIVE/v1.3.5/GH-103-FILE-MANIFEST.md). ⚠️ Three unowned items are recorded in CHANGELOG 0.4.33's ops note.
    51	- [#164 — provisional decisions become per-tenant levers with factory defaults](https://github.com/BinoidCBD/LTVera-Pandas/issues/164) — filed 2026-08-11 as a sketch, not an audit. **Folded into v1.3.5x Phase 3.5** as a *decision*, not a build: that phase introduces three per-tenant config columns, so it must state whether they adopt the existing lever pattern (`app/recommendations/levers.py` + `RecommendationLeverConfig` + an audited reset) or deliberately do not. The seven-cluster migration itself stays on the issue and is **not** a v1.3.5x deliverable.
    52	- [#163 — Sam's brand-voice generator has no seam into the product](https://github.com/BinoidCBD/LTVera-Pandas/issues/163) — filed 2026-08-11. `generate_prompt()` has zero callers inside `app/`; the only paths in are a CLI and the tests, and `brand_voice_data/bounce.json` is hand-maintained for one tenant. Overlaps Phase 3.5's `brand_voice_text` column and #164's storage question — read all three before that migration.
    53	- [#105 — brand classifier](https://github.com/BinoidCBD/LTVera-Pandas/issues/105) — 🔒 **Option A decided** by the operator 2026-07-31 (one structured LLM call over an `n=150` catalog sample — the codebase's first schema-constrained call), a documented override of the recommendation, not drift. **Builder: Noel;** the eval stays Sam's. ⚠️ **Its coverage gate is arithmetically broken as specified** — 6 seeded category days against `MIN_DAYS` 4–5. Build list in [GH-79-RELEASE-1-3-5X.md](PROJECT/2-WORKING/v1.3.5/GH-79-RELEASE-1-3-5X.md) Phase 2. Not started.
    54	- [#106 — product reviews via Yotpo](https://github.com/BinoidCBD/LTVera-Pandas/issues/106) — confirmed live on Bounce 2026-07-31, closing #79 Q1 in favour of integrating. Plan agy-reviewed; **sequenced credential-last** so six of nine steps ship with no key. Build list in [GH-79-RELEASE-1-3-5X.md](PROJECT/2-WORKING/v1.3.5/GH-79-RELEASE-1-3-5X.md) Phase 2.
    55	
    56	### In progress
    57	
    58	- [GH-199 Task 2 — Admin settings UI for newsletter system instructions](PROJECT/2-WORKING/GH-199-ADMIN-SETTINGS.md) — started 2026-08-20 from the #199 follow-on checklist (thumbs vs editable prompts). First slice built on `gh-199-newsletter-design` (CHANGELOG 1.3.5.14): global `system_settings`, `/admin/settings`, pipeline overlay. Later sections (conversational prompt, calendar classifier) not started. Not the Phase 3 Save-history plan.
    59	- [GH-240 — WP/Woo buffer sync stalled: poison NUMERIC HOL-blocks both stores](PROJECT/2-WORKING/GH-240-BUFFER-POISON-HOL.md) — promoted 2026-08-27 from [issue #240](https://github.com/BinoidCBD/LTVera-Pandas/issues/240). Production receipt of GH-45 H3: one overflowing money field aborted the shared projection txn and froze Bloomz + Binoid since 2026-08-07. North star: both sites stay in sync. Not a plugin deploy and not GH-45 Phase 2 wholesale.
    60	- [GH-147 — required_subject render-time validation against brief payload](PROJECT/3-COMPLETED/GH-147-REQUIRED-SUBJECT-VALIDATION.md) — started 2026-08-15 from [issue #147](https://github.com/BinoidCBD/LTVera-Pandas/issues/147), branch `fix/gh-147-required-subject-validation`. **Items 1 & 2 built and verified.** Validates superlative/metric claims across all products (not just hero) and sort key alignment for 'ranked by X' at render time, failing closed before spending quota. Pinned by 26 unit tests in `tests/test_subject_validation.py` with negative controls run for non-hero products and sort keys. ⏸️ **Item 3 (second-person possessives like "your picks") deferred** pending a product decision on store-wide ranking copy.
    61	- [GH-170 — the system-admin console: 'no tenant selected' is a bare 403](PROJECT/3-COMPLETED/GH-170-SYSTEM-ADMIN-NO-TENANT.md) — promoted 2026-08-12 from [issue #170](https://github.com/BinoidCBD/LTVera-Pandas/issues/170), carrying M5–M8 out of [#162](https://github.com/BinoidCBD/LTVera-Pandas/issues/162) so that stays a review record. Root cause: `system_admin` passes every role check but has no membership, so `require_tenant()` fails and five pages 403 while the user's permissions are correct. **Surfacing only — no permissions change** ([#120](https://github.com/BinoidCBD/LTVera-Pandas/issues/120) owns that). **Merged into `development` 2026-08-13 via PR [#175](https://github.com/BinoidCBD/LTVera-Pandas/pull/175); operator browser-verified on ltvera-dev; issue closed.** The negative case (read-only user keeps the role message) is tests-only — the browser check was waived; see the doc's Phase 4.
    62	- [Release 1.3.5x — Late July 2026](PROJECT/2-WORKING/v1.3.5/GH-79-RELEASE-1-3-5X.md) — the umbrella for Elan's 7-24 design drop, 24 screens across 6 phases, authored 2026-07-27 from [issue #79](https://github.com/BinoidCBD/LTVera-Pandas/issues/79). **Phases 0.5, 1 and 2 are built and deployed** (CHANGELOG 0.4.27–0.4.30). ⚠️ **The release's definition of done — one real email delivered — is not met, and the gap is not engineering:** it needs a Nexmail key carrying `templates:write` (a capability the current key has never held, **distinct from the security rotation that stays deferred indefinitely**) and one contract-validation run against Klaviyo. ⚠️ Caution for future agents: **GH-55 is reference, not a plan to execute** — it assumes LTVera computes treatment/control audiences, which Elan's MVP forbids. Superseded v1.3 remainder archived to `PROJECT/4-MISC/v1.3-SUPERSEDED-BY-v1.3.5/`.
    63	  - [Phase 2 completion plan](PROJECT/3-COMPLETED/PHASE-2-COMPLETION-PLAN-2026-08-06.md) — five sequenced slices (seed the library · grow the taxonomy · onboarding review screen · Calendar page · dispatch prefill). **All five are built and deployed**; the chain runs end to end from catalog scoring into a prefilled Dispatch widget. Adds no scope — every slice maps to an existing release-plan checkbox. ⚠️ What remains is **not slice work**: every score is `assumed`, so every match renders WEAK by construction until Sam recalibrates the band, and the `detected` tier waits on [#141](https://github.com/BinoidCBD/LTVera-Pandas/issues/141).
    64	  - [Slice F — the Calendar month grid](PROJECT/3-COMPLETED/SLICE-F-CALENDAR-MONTH-GRID-2026-08-11.md) — authored 2026-08-11 from [issue #160](https://github.com/BinoidCBD/LTVera-Pandas/issues/160). The page ships the mockup's *"Up next"* rail; the month grid, layer chips and three context actions were never built, and the release-plan line was ticked on the rail alone. Additive above the untouched rail, no new dependency. ⚠️ Phase 1 first establishes whether the slots route's `date.today()` is already a live UTC off-by-one before the grid inherits it. **Not started.**
    65	  - [Phase 2 build record](PROJECT/3-COMPLETED/PHASE-2-BUILD-2026-08-04.md) — engine + both UI screens, merged and deployed.
    66	  - [Phase 2 swarm preflight](PROJECT/2-WORKING/v1.3.5/phase-2-calendar/SWARM-PREFLIGHT-2026-08-04.md) — concluded Phase 2 should be built directly rather than swarmed. Preflight only; nothing fired.
    67	  - [GH-87 — Phase 0 foundations build](PROJECT/3-COMPLETED/GH-87-PHASE0-FOUNDATIONS.md) — authored 2026-07-27 from [issue #87](https://github.com/BinoidCBD/LTVera-Pandas/issues/87). Builds the 7 of 10 Phase 0 items needing no answer from Elan or Sam; the one hard blocker is mitigated by shipping `review_avg`/`review_count` **nullable**. **Sequenced, not swarmed** (single Alembic head; `app/db/models.py` touched by four items). Plan dry-run validated; **not yet fired**.
    68	- [GH-143 — per-tenant campaign performance and heuristics](PROJECT/2-WORKING/v1.3.5/GH-143-CAMPAIGN-PERFORMANCE.md) — promoted 2026-08-07 from [issue #143](https://github.com/BinoidCBD/LTVera-Pandas/issues/143). **Phase 0 merged and deployed**; see CHANGELOG 0.4.34 / 0.4.38 for what shipped and the RLS defect found in production. Quota constraint measured in [KLAVIYO-API-RATE-LIMIT-FINDINGS.md](PROJECT/ARCHIVE/v1.3.5/KLAVIYO-API-RATE-LIMIT-FINDINGS.md). ⚠️ **Open:** [#152](https://github.com/BinoidCBD/LTVera-Pandas/issues/152) blocks Binoid and Bloomz; the RLS read-path claim is unverified. Elan's Q1 is 🟡 provisionally answered "ranking" (inferred from Sam's shipped `prompt_generator`), so Phase 2 is unblocked but the answer stays Elan's to close. Phases 1–3 not started.
    69	- [GH-127 — Retire `wp-db-toolkit` BigQuery](PROJECT/2-WORKING/GH-127-WPDBTK-BQ-DECOMMISSION.md) — promoted 2026-08-06 from [issue #127](https://github.com/BinoidCBD/LTVera-Pandas/issues/127). **Tiers 5a+5b executed 2026-08-06; merged as PR [#130](https://github.com/BinoidCBD/LTVera-Pandas/pull/130)** (CHANGELOG 0.4.35). Closes the open question carried in [WPDBTK-FULL-MIGRATION.md](PROJECT/2-WORKING/WPDBTK-FULL-MIGRATION.md) Stage 4. ⚠️ **Tier 5c (project shutdown) is explicitly out of scope and unauthorized.** ⚠️ Issue #127's acceptance criterion 3 was unachievable as written — 2 of the 5 legacy views had been unparseable since the GH-38 cutover and were dropped, not migrated. Remaining: the operator's call on closing the issue.
    70	- [GH-173 — User management API: audited membership CRUD + console Members panel](PROJECT/3-COMPLETED/GH-173-USER-MANAGEMENT-API.md) — ✅ complete in 0.5.0/0.5.1: audited membership CRUD, durable revoke, and stale-response protection landed. Out of scope: `system_role`/`is_active` editing (Keycloak-owned) and invite flow.
    71	- [GH-185 — Calendar → Dispatch blockers](PROJECT/2-WORKING/GH-185-DISPATCH-BLOCKERS.md) — started 2026-08-15 from [issue #185](https://github.com/BinoidCBD/LTVera-Pandas/issues/185), branch `fix/gh-185-dispatch-blockers`. Eleven findings from live production testing; **slice 1 of 3 built.** Fixed: **F1**, which had dead-ended the Create button and the hub's Open Dispatch card since `1ce22f3` by sending `"slot_id": ""` into a `uuid.UUID | None` field (422 before any handler ran), and **F3**, a stale `dispatch_required_subject` surviving a slot open — not cosmetic, because that field is demanded of the provider word-for-word. Both pinned by tests **proven to fail without the fix**. ⚠️ **The durable part is `tests/test_dispatch_payload_contract.py`**: state tests mock the fetch and route tests build their own valid payloads, so nothing ever fed the UI's real serialized dict to the real model — which is why F1 survived every run between shipping and a human clicking the button. 🛑 **F7 is blocked on one operator decision** — scheduled commits 502 on a naive `send_at`, and there is no tenant timezone anywhere in the schema, so "9am where?" has no answer yet (options and a recommendation are in the doc). ⏸️ **F8 and F9 are questions, not queued work** — F8's framing is contested by the operator on the issue, and F9 collides with #184 (NexMail is now the *default* writer, and its draft path outlives the Cloudflare proxy) in a way neither issue names.
    72	- [GH-187 — per-tenant independence](PROJECT/3-COMPLETED/GH-187-PER-TENANT-INDEPENDENCE.md) — started and ✅ **COMPLETE 2026-08-14**. Audit of what still assumes every tenant is configured identically, triggered by #184. Found less than feared — four per-tenant mechanisms already exist — and closed two of three gaps *smaller* than filed, on the unanimous advice of an independent Codex + agy consult. Shipped as code: the `store_id = "bounce"` default is removed and now required, because it fed a `WHERE store_id` filter and a forgotten argument would have returned Bounce's rows to another tenant instead of failing. The other two are corrected documentation with named build triggers; neither has fired. ⚠️ **The trigger for per-tenant ranking config is a tenant that needs a different number, not a second tenant existing** — read the doc before building a settings table.
    73	- [GH-94 — Nexmail contract gap analysis](PROJECT/3-COMPLETED/GH-94-NEXMAIL-CONTRACT-GAP-ANALYSIS.md) — started 2026-07-29, ✅ **COMPLETE 2026-08-14** (both phases closed; doc stays with the v1.3.5x folder, which moves as a unit). ⚠️ **The canonical issue lived in another repo: [nexmail-ltvera-connector#2](https://github.com/BinoidCBD/nexmail-ltvera-connector/issues/2)**, now closed; the local pointer [#94](https://github.com/BinoidCBD/LTVera-Pandas/issues/94) is closed too. **§5 is the SOT for what Nexmail's authoring surface actually does — read it before planning any Nexmail work.** The posture verdict is 🔴 **broken**: a generated body comes back as images (54 characters of real text in 31,412 of HTML), so the proof checks cannot run against it, which is why the MVP email is composed locally and Nexmail is deferred. The Klaviyo-writer question that once gated this is settled — **LTVera writes** (2026-07-30) — and `POST /esp/campaigns` is discharged by never being called, so the isolated-ESP-account gate no longer applies. Two things remain open by decision rather than omission: the Nexmail key rotation (deferred indefinitely, operator 2026-07-31) and the vendor ask for a public `save-source` and preflight, which is NexMail's to ship.
    74	- [GH-58 — Back-in-stock detection: append-only inventory observations seam](PROJECT/2-WORKING/GH-58-BACK-IN-STOCK-DETECTION.md) — promoted 2026-07-20 from [issue #58](https://github.com/BinoidCBD/LTVera-Pandas/issues/58), branch `gh-58-inventory-observations`. Every inventory load is destructive today, so an `outofstock → instock` transition cannot be detected at all. Cross-model consult (Codex + agy) independently chose the append-only design. **Phase 0 (availability policy) is drafted and awaiting operator sign-off**; Phase 2's column set derives from it, so no build starts until it is settled.
    75	- [GH-45 — Consolidated buffer-pipeline audit + remediation](PROJECT/2-WORKING/GH-45-BUFFER-PIPELINE-AUDIT.md) — started 2026-07-10 from [issue #45](https://github.com/BinoidCBD/LTVera-Pandas/issues/45). **Phase 0 complete (2026-07-10):** 1 critical (reconciliation pagination drops same-second orders) + 7 high findings, all verified; 5-phase remediation plan authored, **awaiting operator review** before Phase 1.
    76	- [GH-907 — Buffer Bridge floods Action Scheduler](PROJECT/2-WORKING/GH-907-BUFFER-BRIDGE-FLOOD.md) — promoted 2026-07-02 from `universal-child-theme-oct-2024#907` (foreign repo). Codex-reviewed. **Phase 0 complete;** Phase 1 next. Cross-repo: plugin here, buffer server in `WP-DB-Toolkit`.
    77	- [Grow Willies — Tier-1 Shopify tenant onboarding](PROJECT/2-WORKING/GROW-WILLIES-TENANT-ONBOARDING.md) — started 2026-07-07. **Phases 0–3 PASSED** (connector, first sync at 43k customers / 4k orders, RLS isolation proven). **Phase 4 (signals) BLOCKED** on [#42](https://github.com/BinoidCBD/LTVera-Pandas/issues/42).
    78	- [GH-48 — Klaviyo rollout playbook: human+AI task breakdown](PROJECT/2-WORKING/v1.2/email-campaign-001/GH-48-KLAVIYO-ROLLOUT-TASK-BREAKDOWN.md) — started 2026-07-10 from [issue #48](https://github.com/BinoidCBD/LTVera-Pandas/issues/48). **Phases 0–3 complete**, plus an accuracy pass 2026-07-14 (`c872ca5`) that closed Q1–Q4. **Remaining: Sam's 3 send-posture decisions (Q6a/b/c) — the only thing gating the send** — plus Q5 and #51. The readout script still needs a real BQ run against tenant data.
    79	- [GH-55 — In-house Klaviyo end-to-end write system](PROJECT/ARCHIVE/v1.3.5/carried-forward/GH-55-KLAVIYO-WRITE-SYSTEM.md) — started 2026-07-15 from [issue #55](https://github.com/BinoidCBD/LTVera-Pandas/issues/55). Plan authored; **build not started — Phase 0 (API endpoint map + scope check) is next**, and see GH-94 above before starting it. Guardrail: never writes to Binoid's live account for v1.2.
    80	- [Reference-model review checklist: pivoting from flows to campaigns](PROJECT/2-WORKING/v1.3.5/carried-forward/REFMODEL-CAMPAIGN-PIVOT-REVIEW-2026-07-23.md) — started 2026-07-23, prompted by Elan's [CAMPAIGN-MVP-HANDOFF-7-22-2026.md](PROJECT/2-WORKING/v1.3.5/phase-1/CAMPAIGN-MVP-HANDOFF-7-22-2026.md). Audits the MKII reference model (flows-shaped) against what Campaigns needs (cohort-level) and flags the gaps. **Next: Sam sources an applied e-commerce/marketing data scientist** as the outside reviewer.
    81	- [Marathon Plan 2026-07-07 — connector/seed dogfood bugs + #47](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md) — reopened 2026-07-10 to add [#47](https://github.com/BinoidCBD/LTVera-Pandas/issues/47) as a disjoint lane. #47 is the doc's only currently fireable lane.
    82	
    83	### Completed
    84	
    85	- [GH-239 — Export 5-10% tenant data sample (Bloomz, Bounce) for local Docker import](PROJECT/3-COMPLETED/GH-239-TENANT-SAMPLE-EXPORT.md) — **✅ 2026-08-25**, [issue #239](https://github.com/BinoidCBD/LTVera-Pandas/issues/239) closed via PR [#242](https://github.com/BinoidCBD/LTVera-Pandas/pull/242) (relay Approved r2). Deterministic seeded sample (bounce 7.57%, bloomzhemp 7.58% + BQ-translated facts), one-command idempotent import, hard validation gate (leak/FK/RLS/lineage) — ALL CHECKS PASSED ×3; full pytest 1973 passed. Dataset distribution + local-login recipe: #243.
    86	- [GH-38 — Postgres→BigQuery publisher](PROJECT/3-COMPLETED/GH-38-POSTGRES-BQ-PIPELINE.md) — **✅ 2026-08-03**, [issue #38](https://github.com/BinoidCBD/LTVera-Pandas/issues/38) closed (absorbs #67). Both Shopify cutovers done at exact Postgres↔BigQuery parity; closed on production evidence, not the build record. ⚠️ One live finding handed to [#110](https://github.com/BinoidCBD/LTVera-Pandas/issues/110): Bounce's publish watermarks stopped advancing 2026-07-31. Follow-up: `rag_bq.py` must be updated before Bounce's legacy line-grain `orders` view can be dropped.
    87	- [GH-68 — pgvector in Postgres + semantic cross-sell for Bounce](PROJECT/2-WORKING/v1.3.5/carried-forward/GH-68-PGVECTOR-SEMANTIC-BESTSELLERS.md) — **✅ built, merged and deployed 2026-07-23** (PRs [#69](https://github.com/BinoidCBD/LTVera-Pandas/pull/69), [#73](https://github.com/BinoidCBD/LTVera-Pandas/pull/73)); GH-76 then split semantic into its own `discovery` family 2026-07-23. ⚠️ **The feature is OFF** — `recommendations_semantic_cross_sell` defaults `False` and no operator has approved enabling it; GH-76 made the decision a real one, it did not make it. ⚠️ **Embeddings are Bounce-only** (65/65); Grow Willies (2,853) and Open CDP (159,324) have none, and no policy exists for who backfills or when. ⚠️ Scope landed narrower than the title — Best Sellers enrichment is unbuilt and untracked.
    88	- [GH-80 — back-in-stock projector dropped `latest_run_at` from its SELECT](PROJECT/3-COMPLETED/GH-80-BACK-IN-STOCK-DROPPED-COLUMN.md) — **✅ fixed 2026-07-27**, [issue #80](https://github.com/BinoidCBD/LTVera-Pandas/issues/80). The family had never served a single recommendation. **Second instance of this failure mode**, so the fix ships a column-contract test asserting the emitted SQL.
    89	- [GH-81 — Shopify ingest nulled `order_lines.product_id`](PROJECT/3-COMPLETED/GH-81-SHOPIFY-PRODUCT-LINKAGE.md) — **✅ fixed 2026-07-27**, [issue #81](https://github.com/BinoidCBD/LTVera-Pandas/issues/81). Destructive, not merely incomplete, and the sync still reported success. ⚠️ **Does not repair already-nulled rows** — a backfill from `order_lines.shopify_product_id` is a separate open decision.
    90	- [GH-57 — Klaviyo campaign conversion ranking (read-only)](PROJECT/3-COMPLETED/GH-57-KLAVIYO-CAMPAIGN-CONVERSION-REPORT.md) — **✅ 2026-07-20**, [issue #57](https://github.com/BinoidCBD/LTVera-Pandas/issues/57), PR [#60](https://github.com/BinoidCBD/LTVera-Pandas/pull/60). Claims verified by an agy accuracy relay. ⚠️ Durable finding: the account carries a dead legacy-Shopify `Placed Order` metric that under-reports email revenue ~63× — conversion metrics must be pinned by id + integration. Its ranking logic now lives in `app/campaigns/performance.py` (GH-143); the script imports it.
    91	
    92	### Deferred · vision · vision
    93	
    94	- No deferred docs.
    95	
    96	---
    97	
    98	*Add new work here only when a real `PROJECT/**` doc exists to own the execution detail.*

exec
/bin/zsh -lc "python3 -c 'import os,subprocess,sys,types,io,collections
def source(ref):return subprocess.check_output([\"git\",\"show\",ref+\":utils/py/releases_app.py\"],text=True)
def load(name,src):
 m=types.ModuleType(name);m.__file__=name+\".py\";old=sys.argv;sys.argv=[name]
 try:exec(compile(src,m.__file__,\"exec\"),m.__dict__)
 except SystemExit:pass
 finally:sys.argv=old
 return m
mods={\"A\":load(\"A\",open(\"utils/py/releases_app.py\").read()),\"B\":load(\"B\",source(\"origin/fix/gh351-gh349-releases-ledger-fixes\"))}
foreign=\"/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas\"; own=os.getcwd()
for corpus,root in [(\"own\",own),(\"foreign\",foreign)]:
 print(\"\\\\nDOC VALIDITY\",corpus)
 for tag,m in mods.items():
  es=m.parse_roadmap_ledger(os.path.join(root,\"ROADMAP.md\")); bad=[(e[\"title\"],e[\"doc_path\"]) for e in es if e[\"doc_path\"] and not os.path.isfile(os.path.join(root,e[\"doc_path\"]))]
  print(tag,\"doc paths\",sum(bool(e[\"doc_path\"]) for e in es),\"unresolvable\",len(bad))
  for x in bad:print(\" \",x)
  c=collections.defaultdict(list)
  for e in es:
   if e[\"gh_number\"] is not None:c[e[\"gh_number\"]].append(e)
  for k,v in c.items():
   if len(v)>1:print(\" duplicate\",k,[(e[\"title\"],e[\"doc_path\"],e[\"issue_url\"]) for e in v])
fixtures={\"header-shapes\":\"# R\\\\n## Ledger\\\\n### S\\\\n- [ ] todo\\\\n- [x] done\\\\n- prose bullet\\\\n  - nested subbullet\\\\n- [GH-1 Link](docs/a.md) body\\\\n- **GH-2 Bold** body\\\\n\",\"no-header\":\"# R\\\\n### S\\\\n- [GH-3 Link](docs/c.md) body\\\\n- plain prose\\\\n\"}
for name,txt in fixtures.items():
 print(\"\\\\nFIXTURE\",name)
 for tag,m in mods.items():
  m.open=lambda *a,**k:io.StringIO(txt)
  es=m.parse_roadmap_ledger(\"irrelevant\")
  print(tag,len(es),[(e[\"title\"],e[\"gh_number\"],e[\"raw_text\"].replace(\"\\\\n\",\" | \")) for e in es])
'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 2531ms:
2026-08-31 16:34:52.625 xcodebuild[76520:6485192]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:52.820 xcodebuild[76520:6485188] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-ataDsmB1' (errno=Operation not permitted)
2026-08-31 16:34:53.463 xcodebuild[76526:6485267]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:34:53.672 xcodebuild[76526:6485265] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
\nDOC VALIDITY own
A doc paths 69 unresolvable 19
  ('GH-205 · validate.sh mutates four tracked files per run — gate not idempotent', 'PROJECT/2-WORKING/GH-205-GATE-IDEMPOTENCY.md')
  ('GH-182 · self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design', 'PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md')
  ('GH-105 · vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)', 'PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md')
  ('GH-233 · AgentChorus Gen 2 Phase 2', 'PROJECT/2-WORKING/GH-233-AGENTCHORUS-GEN2-PHASE2.md')
  ('GH-232 · wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs', 'PROJECT/2-WORKING/GH-232-WAVE-RECONCILER-MULTIPHASE.md')
  ('GH-114 · headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)', 'PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md')
  ('GH-113 · headless agy builder writes root scratch files, tripping containment (exit 6)', 'PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md')
  ('GH-168 · wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR', 'PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md')
  ('GH-50 · sandboxed git --track / branch -D half-applies and loses uncommitted work', 'PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md')
  ('GH-2 · test-suite run relocated an untracked file into .tick/orphan-backups/', 'PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md')
  ('GH-202 · wave_reconcile aborts on marathon-plan exit 5 (items held) and promotes capture docs for OPEN issues', 'PROJECT/2-WORKING/GH-202-WAVE-RECONCILER-STATE.md')
  ('GH-197 · two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)', 'PROJECT/2-WORKING/GH-197-VENDOR-TIER-SPLIT.md')
  ('GH-1 · suite-wide fixture containment + clone-identity invariant gate', 'PROJECT/2-WORKING/GH-1-SUITE-CONTAINMENT-GATE.md')
  ('GH-10 · prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket', 'PROJECT/2-WORKING/GH-10-REQUIRE-FIXTURE-ADOPTION.md')
  ('GH-35 · 3-tier test suite selection (docs / utility subsystems / core) + CPU governance', 'PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md')
  ('GH-42 · relay automation: supported Commandcode turn-taker', 'PROJECT/2-WORKING/GH-42-COMMANDCODE-TURN.md')
  ('GH-170 · Agent2Agent: close transcript glitches and harden publishing', 'PROJECT/2-WORKING/GH-170-AGENT2AGENT-GLITCHES.md')
  ('GH-124 · eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene', 'PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md')
  ('GH-77 · `/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?', 'PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md')
B doc paths 69 unresolvable 19
  ('GH-205 · validate.sh mutates four tracked files per run — gate not idempotent', 'PROJECT/2-WORKING/GH-205-GATE-IDEMPOTENCY.md')
  ('GH-182 · self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design', 'PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md')
  ('GH-105 · vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)', 'PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md')
  ('GH-233 · AgentChorus Gen 2 Phase 2', 'PROJECT/2-WORKING/GH-233-AGENTCHORUS-GEN2-PHASE2.md')
  ('GH-232 · wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs', 'PROJECT/2-WORKING/GH-232-WAVE-RECONCILER-MULTIPHASE.md')
  ('GH-114 · headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)', 'PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md')
  ('GH-113 · headless agy builder writes root scratch files, tripping containment (exit 6)', 'PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md')
  ('GH-168 · wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR', 'PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md')
  ('GH-50 · sandboxed git --track / branch -D half-applies and loses uncommitted work', 'PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md')
  ('GH-2 · test-suite run relocated an untracked file into .tick/orphan-backups/', 'PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md')
  ('GH-202 · wave_reconcile aborts on marathon-plan exit 5 (items held) and promotes capture docs for OPEN issues', 'PROJECT/2-WORKING/GH-202-WAVE-RECONCILER-STATE.md')
  ('GH-197 · two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)', 'PROJECT/2-WORKING/GH-197-VENDOR-TIER-SPLIT.md')
  ('GH-1 · suite-wide fixture containment + clone-identity invariant gate', 'PROJECT/2-WORKING/GH-1-SUITE-CONTAINMENT-GATE.md')
  ('GH-10 · prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket', 'PROJECT/2-WORKING/GH-10-REQUIRE-FIXTURE-ADOPTION.md')
  ('GH-35 · 3-tier test suite selection (docs / utility subsystems / core) + CPU governance', 'PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md')
  ('GH-42 · relay automation: supported Commandcode turn-taker', 'PROJECT/2-WORKING/GH-42-COMMANDCODE-TURN.md')
  ('GH-170 · Agent2Agent: close transcript glitches and harden publishing', 'PROJECT/2-WORKING/GH-170-AGENT2AGENT-GLITCHES.md')
  ('GH-124 · eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene', 'PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md')
  ('GH-77 · `/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?', 'PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md')
 duplicate 111 [('GH-111 · retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state', 'PROJECT/3-COMPLETED/GH-111-DIALED-IN.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/111'), ('Execution checklist for GH-111 + GH-108', 'PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/111')]
\nDOC VALIDITY foreign
A doc paths 46 unresolvable 4
  ('GH-276 — Scope the coverage gate to decisioning state, not all signals', 'PROJECT/1-INBOX/GH-276-SIGNAL-COVERAGE-GATE-SCOPE.md')
  ('GH-275 — Five mechanical follow-ups from #255', 'PROJECT/1-INBOX/GH-275-MECHANICAL-FOLLOWUPS.md')
  ('GH-207 — VM start failures on GCE capacity stockouts have no alarm', 'PROJECT/1-INBOX/GH-207-VM-STOCKOUT-ALARM.md')
  ('GH-115 — Cloud SQL buffer-server-pg has automated backups disabled', 'PROJECT/1-INBOX/GH-115-BUFFER-SERVER-BACKUPS.md')
 duplicate 199 [('GH-199 — Previous Newsletter Design Analysis', 'PROJECT/1-INBOX/GH-199-NEWSLETTER-DESIGN-ANALYSIS.md', 'https://github.com/BinoidCBD/LTVera-Pandas/issues/199'), ('GH-199 Task 2 — Admin settings UI for newsletter system instructions', 'PROJECT/2-WORKING/GH-199-ADMIN-SETTINGS.md', None)]
B doc paths 46 unresolvable 4
  ('GH-276 — Scope the coverage gate to decisioning state, not all signals', 'PROJECT/1-INBOX/GH-276-SIGNAL-COVERAGE-GATE-SCOPE.md')
  ('GH-275 — Five mechanical follow-ups from #255', 'PROJECT/1-INBOX/GH-275-MECHANICAL-FOLLOWUPS.md')
  ('GH-207 — VM start failures on GCE capacity stockouts have no alarm', 'PROJECT/1-INBOX/GH-207-VM-STOCKOUT-ALARM.md')
  ('GH-115 — Cloud SQL buffer-server-pg has automated backups disabled', 'PROJECT/1-INBOX/GH-115-BUFFER-SERVER-BACKUPS.md')
 duplicate 199 [('GH-199 — Previous Newsletter Design Analysis', 'PROJECT/1-INBOX/GH-199-NEWSLETTER-DESIGN-ANALYSIS.md', 'https://github.com/BinoidCBD/LTVera-Pandas/issues/199'), ('GH-199 Task 2 — Admin settings UI for newsletter system instructions', 'PROJECT/2-WORKING/GH-199-ADMIN-SETTINGS.md', None)]
\nFIXTURE header-shapes
A 0 []
B 0 []
\nFIXTURE no-header
A 0 []
B 0 []

exec
/bin/zsh -lc "python3 -c 'import subprocess,sys,types,io
def source(ref):return subprocess.check_output([\"git\",\"show\",ref+\":utils/py/releases_app.py\"],text=True)
def load(name,src):
 m=types.ModuleType(name);m.__file__=name+\".py\";old=sys.argv;sys.argv=[name]
 try:exec(compile(src,m.__file__,\"exec\"),m.__dict__)
 except SystemExit:pass
 finally:sys.argv=old
 return m
mods={\"A\":load(\"A\",open(\"utils/py/releases_app.py\").read()),\"B\":load(\"B\",source(\"origin/fix/gh351-gh349-releases-ledger-fixes\"))};N=chr(10)
fixtures={\"header-shapes\":N.join([\"# R\",\"## Ledger\",\"### S\",\"- [ ] todo\",\"- [x] done\",\"- prose bullet\",\"  - nested subbullet\",\"- [GH-1 Link](docs/a.md) body\",\"- **GH-2 Bold** body\"]),\"no-header\":N.join([\"# R\",\"### S\",\"- [GH-3 Link](docs/c.md) body\",\"- plain prose\"])}
for name,txt in fixtures.items():
 print(\"FIXTURE\",name)
 for tag,m in mods.items():
  m.open=lambda *a,**k:io.StringIO(txt);es=m.parse_roadmap_ledger(\"x\")
  print(tag,len(es),[(e[\"title\"],e[\"gh_number\"],e[\"raw_text\"].replace(N,\" | \")) for e in es])'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
2026-08-31T23:35:11.590413Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
 succeeded in 2463ms:
2026-08-31 16:35:09.401 xcodebuild[76577:6485802]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:09.601 xcodebuild[76577:6485801] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-FIcE2XYn' (errno=Operation not permitted)
2026-08-31 16:35:10.220 xcodebuild[76579:6485820]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:10.410 xcodebuild[76579:6485819] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
FIXTURE header-shapes
A 2 [('GH-1 Link', 1, '- [GH-1 Link](docs/a.md) body'), ('GH-2 Bold', 2, '- **GH-2 Bold** body')]
B 5 [('', None, '- [ ] todo'), ('x', None, '- [x] done'), ('prose bullet', None, '- prose bullet |   - nested subbullet'), ('GH-1 Link', 1, '- [GH-1 Link](docs/a.md) body'), ('GH-2 Bold', 2, '- **GH-2 Bold** body')]
FIXTURE no-header
A 0 []
B 2 [('GH-3 Link', 3, '- [GH-3 Link](docs/c.md) body'), ('plain prose', None, '- plain prose')]

exec
/bin/zsh -lc "nl -ba utils/py/releases_app.py | sed -n '4810,4860p'
git show origin/fix/gh351-gh349-releases-ledger-fixes:utils/py/releases_app.py | nl -ba | sed -n '4930,4985p'
git show origin/fix/gh351-gh349-releases-ledger-fixes:test/gh349-vendored-roadmap-ledger.sh | rg -n 'ROADMAP.md|ROADMAP|task|checkbox|own|duplicate|allow-empty|LTVera|PROJECT/'
nl -ba test/gh349-releases-roadmap-vendored.sh | sed -n '185,215p'
rg -n -C 1 'GH-61|GH-135\\.\\.140|#129/#130/#131|Execution checklist for GH-111' ROADMAP.md
rg -n -C 1 'GH-199' /Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 4800ms:
2026-08-31 16:35:43.442 xcodebuild[76811:6487582]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:43.638 xcodebuild[76811:6487581] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-jz9hLo8C' (errno=Operation not permitted)
2026-08-31 16:35:44.250 xcodebuild[76813:6487622]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:44.441 xcodebuild[76813:6487621] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
  4930	        _p.add_argument("--marathon", default=None,
  4931	                        help="marathon gid; must be THIS release's marathon")
  4932	    sp_ship = msub.add_parser("ship",
  4933	                              help="mark a dialed-in item shipped (REQUIRES --evidence)")
  4934	    sp_ship.add_argument("--gid", required=True)
  4935	    sp_ship.add_argument("issue", help="issue URL or TMP-XXXXXX")
  4936	    sp_ship.add_argument("--evidence", default="",
  4937	                         help="commit, PR, or test receipt (empty is refused)")
  4938	    sp_mar = msub.add_parser("marathon",
  4939	                             help="link an already dialed-in item to its release's marathon")
  4940	    sp_mar.add_argument("--gid", required=True)
  4941	    sp_mar.add_argument("issue", help="issue URL or TMP-XXXXXX")
  4942	    sp_mar.add_argument("--marathon", required=True, help="marathon gid; must be THIS release's")
  4943	    sp_cut = msub.add_parser("cut",
  4944	                             help="cut an item from a release's manifest (REQUIRES --reason)")
  4945	    sp_cut.add_argument("--gid", required=True)
  4946	    sp_cut.add_argument("issue", help="issue URL or TMP-XXXXXX")
  4947	    sp_cut.add_argument("--reason", default="")
  4948	    sp_unship = msub.add_parser("unship",
  4949	                                help="retract a shipped manifest item back to dialed_in (REQUIRES --reason)")
  4950	    sp_unship.add_argument("--gid", required=True)
  4951	    sp_unship.add_argument("issue", help="issue URL or TMP-XXXXXX")
  4952	    sp_unship.add_argument("--reason", default="")
  4953	
  4954	    sp = sub.add_parser("marathon", help="marathon CRUD (v1: add/list)")
  4955	    msub = sp.add_subparsers(dest="marathon_cmd", required=True)
  4956	    sp_add = msub.add_parser("add")
  4957	    sp_add.add_argument("--tracking-issue", required=True, help="issue URL or TMP-XXXXXX")
  4958	    sp_add.add_argument("--status", default="planned", choices=MARATHON_STATUSES)
  4959	    msub.add_parser("list")
  4960	
  4961	    sp = sub.add_parser("list", help="list releases")
  4962	    sp.add_argument("--all-repos", action="store_true",
  4963	                    help="aggregate RELEASES_APP_EXTRA_DBS too; duplicate GIDs fail loudly")
  4964	    sp.add_argument("--status", choices=STATUSES)
  4965	
  4966	    sp = sub.add_parser("show", help="full record for one release (by --gid or --version)")
  4967	    sp.add_argument("--gid")
  4968	    sp.add_argument("--version")
  4969	    sp.add_argument("--full", action="store_true",
  4970	                    help="print long values verbatim (default elides them at %d chars)"
  4971	                         % SHOW_ELIDE)
  4972	
  4973	    sp = sub.add_parser("next", help="the next unshipped release, by target date")
  4974	    sp.add_argument("--verbose", action="store_true", help="also print its full record")
  4975	
  4976	    sp = sub.add_parser("gen", help="side-by-side generation (Phase 0: NEVER writes RELEASES.md)")
  4977	    sp.add_argument("--side-by-side", action="store_true", default=True,
  4978	                    help="the only mode in Phase 0 (accepted for CLI-shape compatibility)")
  4979	
  4980	    sp = sub.add_parser("check",
  4981	                        help="DB<->dump<->generated consistency; FK pragma; stale WAL; "
  4982	                             "receipt-vs-change bypass detection; temp-ref staleness; "
  4983	                             "duplication warnings; per-boundary crash recovery")
  4984	    sp.add_argument("--rebuild", action="store_true",
  4985	                    help="rebuild the DB from the dump (git-merge resolution ONLY)")
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-7XMdDRHt' (errno=Operation not permitted)
2026-08-31 16:35:45.839 xcodebuild[76823:6487701]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:46.038 xcodebuild[76823:6487700] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-YlAbX3jy' (errno=Operation not permitted)
2026-08-31 16:35:46.653 xcodebuild[76825:6487713]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:46.852 xcodebuild[76825:6487712] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
5:#   Scope 1: `roadmap sync` refuses rather than deleting when 0 entries are parsed from non-empty ROADMAP.md.
57:cat > "$R/ROADMAP.md" <<'MD'
61:- [GH-101 · Custom Feature](PROJECT/2-WORKING/GH-101.md) — Link-style bullet format. rated 80/60/70/50. → [#101](https://github.com/ExternalOrg/ExternalRepo/issues/101)
62:- [External Pull Request](PROJECT/2-WORKING/GH-102.md) — External PR link. → [#102](https://github.com/OtherOrg/OtherRepo/pull/102)
80:cat > "$R/ROADMAP.md" <<'MD'
194:cat > "$R/ROADMAP.md" <<'MD'
198:- [GH-110 · Rated Feature](PROJECT/2-WORKING/GH-110.md) — 4-axis rated. rated 90/80/70/60. ovr 350. → [#110](https://github.com/ExternalOrg/ExternalRepo/issues/110)
205:cat > "$R/ROADMAP.md" <<'MD'
209:- [GH-111 · Malformed Rating Shape](PROJECT/2-WORKING/GH-111.md) — Malformed shape. rated 70/40/55. → [#111](https://github.com/ExternalOrg/ExternalRepo/issues/111)
215:cat > "$R/ROADMAP.md" <<'MD'
219:- [GH-112 · Bad Rating Range](PROJECT/2-WORKING/GH-112.md) — Out of range. rated 150/80/70/60. → [#112](https://github.com/ExternalOrg/ExternalRepo/issues/112)
225:cat > "$R/ROADMAP.md" <<'MD'
229:- [GH-113 · Bad OVR Range](PROJECT/2-WORKING/GH-113.md) — Bad ovr. rated 80/70/60/50. ovr 500. → [#113](https://github.com/ExternalOrg/ExternalRepo/issues/113)
235:cat > "$R/ROADMAP.md" <<'MD'
239:- [GH-114 · Orphan OVR](PROJECT/2-WORKING/GH-114.md) — Orphan ovr. ovr 300. → [#114](https://github.com/ExternalOrg/ExternalRepo/issues/114)
245:cat > "$R/ROADMAP.md" <<'MD'
249:- [GH-115 · Clash Rating](PROJECT/2-WORKING/GH-115.md) — Clash. cx/risk/eff 3/2/1. rated 80/70/60/50. → [#115](https://github.com/ExternalOrg/ExternalRepo/issues/115)
   185	doc501="$(sqlite3 "$R/releases.db" "SELECT doc_path FROM roadmap_items WHERE gh_number=501")"
   186	ok "  and its real doc_path still resolves" "[ \"$doc501\" = 'docs/plans/gh-501.md' ]"
   187	
   188	# ── 7. This repo's own ROADMAP.md still parses, with no duplicate keys ──────────────
   189	# The regression that made this review necessary: the widened key search created a second
   190	# GH-111 in XYZ-forge's own ledger, which `roadmap sync` refuses on outright.
   191	self_dup="$(python3 - "$ROOT_DIR" <<'PY'
   192	import collections, importlib.util, os, sys
   193	root = sys.argv[1]
   194	spec = importlib.util.spec_from_file_location("ra", os.path.join(root, "utils/py/releases_app.py"))
   195	m = importlib.util.module_from_spec(spec)
   196	sys.argv = ["ra"]
   197	try:
   198	    spec.loader.exec_module(m)
   199	except SystemExit:
   200	    pass
   201	e = m.parse_roadmap_ledger(os.path.join(root, "ROADMAP.md"))
   202	c = collections.Counter(x["gh_number"] for x in e if x["gh_number"])
   203	print("%d %s" % (len(e), ",".join(str(k) for k, v in sorted(c.items()) if v > 1) or "none"))
   204	PY
   205	)"
   206	ok "this repo's own ROADMAP.md parses a non-empty ledger" "[ \"${self_dup%% *}\" -gt 0 ]"
   207	ok "  and yields no duplicate GH keys (would refuse roadmap sync)" "[ \"${self_dup##* }\" = 'none' ]"
   208	
   209	
   210	# ── 8. codex QA regressions (second review, 2026-08-31) ─────────────────────────────
   211	# agy passed the branch; codex found two Majors it missed:
   212	#   a. an UNKEYED entry took the first URL on its first line as its own identity — on the real
   213	#      reporting ledger that stored a BLOCKER (#42) as "Grow Willies"'s issue_url
   214	#   b. an absolute `.md` URL bypassed the doc-pointer check entirely, because the extraction
   215	#      regex accepted any `.md`-suffixed target and the validator was only consulted on the
136-- **GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view** 🆕 **queued 2026-08-19 at the FRONT of the line (operator call)** — a `releases dashboard` verb renders one self-contained HTML file from `releases.db`, with a card per release (version, codename, status, target, days-to-target, manifest open/closed split, exit criterion) and a card per `roadmap_items` row grouped by section in ledger order, plus a header strip carrying generation, receipt count, and a stale-sync banner when `ROADMAP.md` is ahead of the shadow. Read-only by construction: no writer lock, no generation bump, no receipt — safe to run mid-merge. First real consumer of the GH-69 shadow rows. rated 90/40/85/55. → [#75](https://github.com/HiQS-Labs/XYZ-forge/issues/75)
137:- **GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)** 🆕 **queued 2026-08-19 — filed 2026-08-19 out of the PR #60 review and un-triaged until now** — four scoped test follow-ups under one parent: exact ledger state asserted after crash recovery ([#62](https://github.com/HiQS-Labs/XYZ-forge/issues/62)), writer-lock stress and owner-death recovery ([#63](https://github.com/HiQS-Labs/XYZ-forge/issues/63)), seeded malformed-dump property coverage ([#64](https://github.com/HiQS-Labs/XYZ-forge/issues/64)), and a portable artifact-hash helper ([#65](https://github.com/HiQS-Labs/XYZ-forge/issues/65)). rated 45/55/40/50. → [#61](https://github.com/HiQS-Labs/XYZ-forge/issues/61)
138-- **GH-67 · Commandcode builder default widened to `--yolo` — closer evaluation → possible build** 🆕 **queued 2026-08-19 as the NEXT immediate item (operator call, session close)** — PR #60 moved the default from the bounded `--permission-mode auto-accept` to `--yolo` (alias for `--dangerously-skip-permissions`), unmentioned in a fuzzing PR. Evaluate whether the turn shim’s containment (worktree isolation, `ALLOW_PATHS`, commit-bypass guard) genuinely makes the child CLI’s permission mode irrelevant; if yes, RATIFY — write the containment argument down in AGENTS.md/the shim docs and pin it — if no, revert the default and drop the `--yolo` test pin. Sibling check either way: `claude-turn.py` uses `--permission-mode acceptEdits`; confirm the two adapters differ on purpose. rated 88/80/45/70 ovr 340. → [#67](https://github.com/HiQS-Labs/XYZ-forge/issues/67)
--
188-- **GH-155 · 3rd Gen ATE & Fuzzing ** ✅ **SHIPPED 2026-08-23 (PR #173)** — All 5 Phases Built (Metamorphic Invariants, Differential Oracles, Reproducers, Self-Healing & Active Explorers)** 🚧 **active 2026-08-22 on branch `feat/gh155-p5-active-explorer`** — build deterministic $0 metamorphic invariant assertion oracles (Phase 1), differential multi-harness cross-testing oracles (Phase 2), hermetic delta-minimizers (Phase 3), autonomous self-healing loops (Phase 4), and the 4-family active explorer (Phase 5). 5-phase roadmap ratified in issue #155. rated 85/70/90/50. → [GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md](PROJECT/3-COMPLETED/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md) · [#155](https://github.com/HiQS-Labs/XYZ-forge/issues/155)
189:- **GH-135..140 · Wave-1 follow-ups: consult preflight verdict, attempts-gate root, suite registration, twin-divergence record, SIGPIPE sweep+guard, utcnow swap** ✅ **SHIPPED 2026-08-22 (PR #145, squash 9c07f0cc; issues closed)** — six follow-up issues fixed on one branch: consult.py routes non-zero whoami exits through the shared verdict (#135); TICK_REPO_ROOT resolves ahead of the lane-attempt gate with the NOTE still after the lock (#136); the Wave-1 suites + the gh139 guard registered in TESTS (#137); the post-#129 twin divergence pinned (#138); 369 of 482 pipe-into-`grep -q` sites swept to capture-then-match with a ratchet guard over a ~120-entry shrinking baseline (#139 — the sweep's own gate run caught and repaired three negation-inversion conversions and signal-triage's escaped-quote mangle, each verified by suite re-run); the three utcnow() sites swapped timezone-aware (#140). Full gate 237/237; relay QA by agy returned VERDICT: PASS. → [GH-135-CONSULT-AGY-PREFLIGHT.md](PROJECT/3-COMPLETED/GH-135-CONSULT-AGY-PREFLIGHT.md) · [GH-136-ATTEMPTS-GATE-ROOT.md](PROJECT/3-COMPLETED/GH-136-ATTEMPTS-GATE-ROOT.md) · [GH-137-SUITE-REGISTRATION.md](PROJECT/3-COMPLETED/GH-137-SUITE-REGISTRATION.md) · [GH-138-TWIN-DIVERGENCE-RECORD.md](PROJECT/3-COMPLETED/GH-138-TWIN-DIVERGENCE-RECORD.md) · [GH-139-SIGPIPE-SWEEP-GUARD.md](PROJECT/3-COMPLETED/GH-139-SIGPIPE-SWEEP-GUARD.md) · [GH-140-UTCNOW-DEPRECATION.md](PROJECT/3-COMPLETED/GH-140-UTCNOW-DEPRECATION.md)
190:- **#129/#130/#131 · Wave 1 of the Harness Driver & Relay Seam Hardening marathon — three preflighted driver/relay fixes** ✅ **SHIPPED 2026-08-22 (PR #134, squash d92236cb; issues closed)** — relay-drive self-resolves TICK_REPO_ROOT via resolve_turn_root when unset and replaces the misleading "token missing" with a diagnostic naming the resolved root and searched event dir, every escalation pinned at exit 4; the agy auth preflight classifies usage/CLI-syntax errors as unverifiable (non-blocking) while credentials errors stay exit 5; marathon-drive's phase write-set (RELAY.md/ESCALATION.md) commits route to `phase_commit_root` — the repo containing phase_dir — making `--target-root` + target `--phases-dir` runnable for the first time. Three suites (33 assertions) with recorded pre-fix negative controls; full gate 233/233; first-gate run caught the gh376 twin-parity ordering defect (NOTE must print after the lock refusal). Follow-ups filed as #135-#140. → [#129](https://github.com/HiQS-Labs/XYZ-forge/issues/129) · [#130](https://github.com/HiQS-Labs/XYZ-forge/issues/130) · [#131](https://github.com/HiQS-Labs/XYZ-forge/issues/131)
191-- **GH-111 · retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state** ✅ **SHIPPED 2026-08-21 (PR #116; issue closed)** — membership became machine-checkable instead of a sentence someone remembered to write: three states (`dialed_in`/`shipped`/`cut`), exclusivity by a partial unique index over ACTIVE membership only, a real `releases migrate` upgrade path where none existed, and BASELINES replacing what the freeze used to buy (progress against the live manifest, growth against the kickoff count). Closed #109 (the viewer asserted marathon membership the data never claimed) and #110 (`shipped` was a state nothing could write). rated 85/75/70/35. → [GH-111-DIALED-IN.md](PROJECT/3-COMPLETED/GH-111-DIALED-IN.md) · [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111)
192-- **GH-108 · pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)** ✅ **SHIPPED 2026-08-21 (PR #116; issue closed)** — one scoring vocabulary for every task in the ledger, oriented so a single glance answers what should go to the front of the line: four axes 1-100 where higher is always better (effort scores cheapness), a combined 4-400 `calc` derived and never stored, and an `ovr` override that pins anything visible. Authored as `rated N/N/N/N` on a ROADMAP entry; read via `bash utils/leaderboard.sh` or LEADERBOARD.html. rated 80/50/75/40. → [GH-108-RATING-SYSTEM.md](PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md) · [#108](https://github.com/HiQS-Labs/XYZ-forge/issues/108)
193:- **Execution checklist for GH-111 + GH-108** ✅ **SHIPPED 2026-08-21 (PR #116)** — the running list covering every deliverable of the two plans above, in dependency order, so a stall at any point left the next move unambiguous. Retired with them: both plans are now in 3-COMPLETED, which was this doc's own stated end condition. rated 40/20/35/95. → [GH-108-GH-111-EXECUTION-TODO.md](PROJECT/3-COMPLETED/GH-108-GH-111-EXECUTION-TODO.md) · [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111)
194-- **GH-101 · Feasibility Study: Promoting Programmatic Script Runner (`script_runner.py`) into Core Relay & Consult Runtimes** ✅ **SHIPPED 2026-08-20 (issue closed)** — evaluated and promoted programmatic tool mode across `consult.py` and `relay_drive.py` behind `--tool-mode programmatic` (default off); completed 3-test qualification ladder (Test 1 architectural review & fail-closed threat scoping; Test 2 consult dogfooding with throwaway worktree isolation, pre-created `.relay-scratch/`, and 1,935-trial paired density benchmark in `TESTS-RESULTS/2026-08-20+GH-101/`; Test 3 relay-drive PGID process cleanup stress and fail-closed sandbox checks in `test/synthetic/gh101-relay-programmatic-stress.sh`); promoted to Production-Ready (A-Grade) in `HARNESS-MODELS-REGISTRY.md`. → [GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md](PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md) · [#101](https://github.com/HiQS-Labs/XYZ-forge/issues/101)
28-
29:- [GH-199 — Previous Newsletter Design Analysis](PROJECT/1-INBOX/GH-199-NEWSLETTER-DESIGN-ANALYSIS.md) — captured 2026-08-18 from [issue #199](https://github.com/BinoidCBD/LTVera-Pandas/issues/199). Three phases: (1) Gemini 3.6 Flash vision seam + Utilities page shell, (2) upload up to 10 images and pattern analysis, (3) per-store Save history. Phase 2 is the current build. Not promoted.
30-- [GH-276 — Scope the coverage gate to decisioning state, not all signals](PROJECT/1-INBOX/GH-276-SIGNAL-COVERAGE-GATE-SCOPE.md) — captured 2026-08-27 from [issue #276](https://github.com/BinoidCBD/LTVera-Pandas/issues/276). Part (a) of [#42](https://github.com/BinoidCBD/LTVera-Pandas/issues/42), pre-authorized by Sam's 2026-07-15 answer on #43 — no design decision needed. Critical: every non-Bounce tenant gets zero signals today. Queued for `/jog`.
--
57-
58:- [GH-199 Task 2 — Admin settings UI for newsletter system instructions](PROJECT/2-WORKING/GH-199-ADMIN-SETTINGS.md) — started 2026-08-20 from the #199 follow-on checklist (thumbs vs editable prompts). First slice built on `gh-199-newsletter-design` (CHANGELOG 1.3.5.14): global `system_settings`, `/admin/settings`, pipeline overlay. Later sections (conversational prompt, calendar classifier) not started. Not the Phase 3 Save-history plan.
59-- [GH-240 — WP/Woo buffer sync stalled: poison NUMERIC HOL-blocks both stores](PROJECT/2-WORKING/GH-240-BUFFER-POISON-HOL.md) — promoted 2026-08-27 from [issue #240](https://github.com/BinoidCBD/LTVera-Pandas/issues/240). Production receipt of GH-45 H3: one overflowing money field aborted the shared projection txn and froze Bloomz + Binoid since 2026-08-07. North star: both sites stay in sync. Not a plugin deploy and not GH-45 Phase 2 wholesale.

exec
/bin/zsh -lc "rg -n -C 2 'add_parser\\(\"sync\"|allow-empty' utils/py/releases_app.py
git show origin/fix/gh351-gh349-releases-ledger-fixes:utils/py/releases_app.py | rg -n -C 2 'add_parser\\(\"sync\"|allow-empty'
git show origin/development:utils/py/releases_app.py | rg -n -C 2 'def parse_roadmap_ledger|def cmd_roadmap_sync|add_parser\\(\"sync\"'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 4750ms:
2026-08-31 16:35:53.901 xcodebuild[76854:6487892]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:54.100 xcodebuild[76854:6487891] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-H65gZBHq' (errno=Operation not permitted)
2026-08-31 16:35:54.721 xcodebuild[76860:6487949]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:54.919 xcodebuild[76860:6487948] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
4993-    sp = sub.add_parser("roadmap", help="Roadmap ledger (GH-269): sync/list the ledger items")
4994-    rsub = sp.add_subparsers(dest="roadmap_cmd", required=True)
4995:    sp_rs = rsub.add_parser("sync", help="mirror legacy ROADMAP.md's ledger into roadmap_items (one-way)")
4996-    sp_rs.add_argument("--dry-run", action="store_true", help="report the diff, write nothing")
4997-    sp_rl = rsub.add_parser("list", help="print the shadow rows")
--
5042-    sp = sub.add_parser("project", help="GitHub Project release-card projection")
5043-    psub = sp.add_subparsers(dest="project_cmd", required=True)
5044:    sp_sync = psub.add_parser("sync", help="plan or apply DB -> GitHub Project draft cards")
5045-    sp_sync.add_argument("--owner", required=True, help="GitHub organization or user owning the Project")
5046-    sp_sync.add_argument("--number", required=True, type=int, help="GitHub Project number")
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-Pbs6wWpl' (errno=Operation not permitted)
2026-08-31 16:35:56.294 xcodebuild[76866:6487981]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:56.491 xcodebuild[76866:6487980] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-VAFXncxP' (errno=Operation not permitted)
2026-08-31 16:35:57.115 xcodebuild[76869:6488006]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:35:57.314 xcodebuild[76869:6488005] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
2806-
2807-
2808:def parse_roadmap_ledger(path):
2809-    """ROADMAP.md -> [entry dict], file order. Same block boundaries as the planner: an entry runs
2810-    from its `- **` line to the next `- **`, `###`, or `##`."""
--
3161-
3162-
3163:def cmd_roadmap_sync(args):
3164-    root = resolve_root(args.root)
3165-    # PR #240 review: sync mirrors ROADMAP.md and DELETES rows absent from it — in a releases-mode
--
4623-    sp = sub.add_parser("roadmap", help="Roadmap ledger (GH-269): sync/list the ledger items")
4624-    rsub = sp.add_subparsers(dest="roadmap_cmd", required=True)
4625:    sp_rs = rsub.add_parser("sync", help="mirror legacy ROADMAP.md's ledger into roadmap_items (one-way)")
4626-    sp_rs.add_argument("--dry-run", action="store_true", help="report the diff, write nothing")
4627-    sp_rl = rsub.add_parser("list", help="print the shadow rows")
--
4672-    sp = sub.add_parser("project", help="GitHub Project release-card projection")
4673-    psub = sp.add_subparsers(dest="project_cmd", required=True)
4674:    sp_sync = psub.add_parser("sync", help="plan or apply DB -> GitHub Project draft cards")
4675-    sp_sync.add_argument("--owner", required=True, help="GitHub organization or user owning the Project")
4676-    sp_sync.add_argument("--number", required=True, type=int, help="GitHub Project number")

exec
/bin/zsh -lc "python3 -c 'import subprocess,sys,types,io
def source(ref):return subprocess.check_output([\"git\",\"show\",ref+\":utils/py/releases_app.py\"],text=True)
def load(name,src):
 m=types.ModuleType(name);m.__file__=name+\".py\";old=sys.argv;sys.argv=[name]
 try:exec(compile(src,m.__file__,\"exec\"),m.__dict__)
 except SystemExit:pass
 finally:sys.argv=old
 return m
mods={\"A\":load(\"A\",open(\"utils/py/releases_app.py\").read()),\"B\":load(\"B\",source(\"origin/fix/gh351-gh349-releases-ledger-fixes\"))};N=chr(10);txt=N.join([\"# R\",\"## Ledger\",\"### S\",\"- [GH-10 Remote](https://example.com/DESIGN.md)\",\"- [GH-11 Mail](mailto:notes.md)\",\"- [GH-12 Absolute](/docs/a.md)\",\"- [GH-13 Traverse](../../outside.md)\"])
for tag,m in mods.items():
 m.open=lambda *a,**k:io.StringIO(txt);print(tag,[(e[\"gh_number\"],e[\"doc_path\"],e[\"issue_url\"]) for e in m.parse_roadmap_ledger(\"x\")])'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 2516ms:
2026-08-31 16:36:14.591 xcodebuild[76980:6488898]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:36:14.792 xcodebuild[76980:6488897] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-doLejwjH' (errno=Operation not permitted)
2026-08-31 16:36:15.422 xcodebuild[76983:6488943]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:36:15.624 xcodebuild[76983:6488942] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
A [(10, None, None), (11, None, None), (12, None, None), (13, '../../outside.md', None)]
B [(10, 'https://example.com/DESIGN.md', None), (11, 'mailto:notes.md', None), (12, '/docs/a.md', None), (13, '../../outside.md', None)]

exec
/bin/zsh -lc "python3 -c 'import subprocess,sys,types
def source(ref):return subprocess.check_output([\"git\",\"show\",ref+\":utils/py/releases_app.py\"],text=True)
def load(name,src):
 m=types.ModuleType(name);m.__file__=name+\".py\";old=sys.argv;sys.argv=[name]
 try:exec(compile(src,m.__file__,\"exec\"),m.__dict__)
 except SystemExit:pass
 finally:sys.argv=old
 return m
A=load(\"A\",open(\"utils/py/releases_app.py\").read());B=load(\"B\",source(\"origin/fix/gh351-gh349-releases-ledger-fixes\"));p=\"/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/ROADMAP.md\";a=A.parse_roadmap_ledger(p);b=B.parse_roadmap_ledger(p);print([(i+1,e[\"title\"],e[\"raw_text\"].splitlines()[0]) for i,e in enumerate(b) if e[\"title\"] not in {x[\"title\"] for x in a}])'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o
 succeeded in 2492ms:
2026-08-31 16:36:52.177 xcodebuild[77231:6490827]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:36:52.374 xcodebuild[77231:6490826] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-SsfFOO0d' (errno=Operation not permitted)
2026-08-31 16:36:52.996 xcodebuild[77246:6490930]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-31 16:36:53.195 xcodebuild[77246:6490928] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
[(52, 'No deferred docs.', '- No deferred docs.')]

codex
The decisive result is in: both branches reject the actual foreign ledger because it contains two independently linked `GH-199` rows, so neither fulfills GH-349’s stated end-to-end sync goal as-is. B also breaks this repository’s current ledger with a duplicate `GH-111`; A is otherwise substantially safer.
exec
/bin/zsh -lc "git show origin/fix/gh351-gh349-releases-ledger-fixes:utils/py/releases_app.py | sed -n '104,130p'
git show origin/development:utils/py/releases_app.py | sed -n '104,130p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-74995-bacelv2o

consult: advisor failed or exceeded the 300s cap
