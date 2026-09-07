**SINGLE-MODEL — NOT RECONCILED** (only agy answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**Changes requested.** Your safety proof holds—`marathons` and `issue_refs` are completely unprojected by the dashboard—but the proposed fix of extending the allowlist is the wrong approach. The allowlist fundamentally misunderstands the schema and will falsely refuse any future `releases add` or `manifest` write. Discard the allowlist entirely and invert the check to target `roadmap_items`.

### Findings

**[Blocker] The safety proof is validated, but the allowlist approach will break the core Releases app.**
You are correct that `marathons` and `issue_refs` do not reach `ROADMAP-DASHBOARD.md`. Tracing `cmd_roadmap_list` (`utils/py/releases_app.py:3545-3581`) shows it performs a flat `SELECT * FROM roadmap_items` with no joins or subqueries. Furthermore, `issue_url` is a plain `TEXT` column (`releases_app.py:605`), not a foreign key, making `issue_refs` completely separable from `marathons`. Finally, the guard protects nothing else but `ROADMAP-DASHBOARD.md` (`dashboard-staleness-guard.sh:108-109`). 

However, adding two tables to the allowlist leaves `releases`, `manifest_items`, `schema_migrations`, `repos`, and others unclassified. Any push containing a `releases add` will hit the catch-all and falsely refuse.

**[Blocker] The "fail-closed" framing is factually incorrect.**
A guard that cries wolf on every non-roadmap DB write isn't failing closed; it's broken. The catch-all branch at `dashboard-staleness-guard.sh:162` is specifically meant to catch malformed `roadmap_items` rows that the renderer dropped. By triggering on *any* unclassified DB change, it misdiagnoses completely unrelated operations. Inverting the check to trigger *only* when `roadmap_items` changes accurately targets the only table the renderer consumes.

**[Should] The correct fix is to invert the check.**
Replace lines 147-158 in `dashboard-staleness-guard.sh` with a single check for `roadmap_items`. This is the option I would ship because it structurally matches the renderer's sole input, requires no external dependencies (unlike asking the app), and eliminates endless allowlist maintenance:
```bash
      changed_roadmap=0
      while IFS= read -r dline; do
        case "$dline" in
          '-'INSERT\ INTO\ roadmap_items*|'+'INSERT\ INTO\ roadmap_items*) changed_roadmap=1; break ;;
        esac
      done < <(git -C "$REPO" diff --no-renames "$remote_sha" "$local_sha" -- releases.sql 2>/dev/null)
      if [ "$changed_roadmap" -eq 0 ]; then
        continue
      fi
```

**[Nit] Empirical JSON output is a weak proof.**
As you suspected, grepping for `mar-` in the JSON is unsound because an empty `marathons` table yields the same result (absence of evidence is not evidence of absence). The sound proof is reading `cmd_roadmap_list`, which proves structurally that no other tables are read.

**[Nit] The `INSERT INTO` grammar match remains fragile.**
GH-315 noted the classifier misses non-`INSERT` grammars. A two-line guard change is an acceptable scope here, but you might consider using a looser match (like `*roadmap_items*`) to catch any diff line touching the table (including schema changes) rather than relying on a strict `INSERT INTO` prefix.

### Recommendation
Reject the two-line allowlist addition; invert the guard to trigger only on `roadmap_items` mutations.
