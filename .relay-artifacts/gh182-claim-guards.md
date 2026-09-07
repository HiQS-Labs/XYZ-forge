# GH-182 claim guards — full diff (branch fix/gh182-claim-guards, base development)

```diff
diff --git a/src/rebalance/cli/onboard.py b/src/rebalance/cli/onboard.py
index 2ccbc1b..749a1b3 100644
--- a/src/rebalance/cli/onboard.py
+++ b/src/rebalance/cli/onboard.py
@@ -174,6 +174,11 @@ def onboard_cmd(
             "repos": d.get("repos", []),
             "priority_tier": d.get("priority_tier") or 3,
             "tags": d.get("tags", []),
+            # Rebuilt field by field, so anything omitted here is dropped. Leaving
+            # provenance out is what left every onboarded row unstamped, and an
+            # unstamped row cannot later be told apart from an operator-entered
+            # one — which is what blocked repairing GH-182 automatically.
+            "provenance": d.get("provenance", ""),
         }
         for d in (_as_dict(c) for c in chosen)
     ]
@@ -189,6 +194,8 @@ def onboard_cmd(
         database_path=db,
     )
     typer.echo(f"Registered {result.project_count} project(s) -> {result.registry_path}")
+    for name, repo, owner in result.skipped_claims:
+        typer.echo(f"  skipped {name!r}: {repo} is already claimed by {owner!r}")
 
     # 6. Initial refresh.
     if skip_refresh:
diff --git a/src/rebalance/ingest/preflight.py b/src/rebalance/ingest/preflight.py
index d2f0b2c..d24865e 100644
--- a/src/rebalance/ingest/preflight.py
+++ b/src/rebalance/ingest/preflight.py
@@ -11,6 +11,7 @@ from rebalance.lib.time_ops import now_utc
 from rebalance.ingest.registry import (
     Project,
     Registry,
+    canonical_repo_key,
     load_registry,
     read_registry,
     save_registry,
@@ -48,6 +49,11 @@ class ConfirmResult:
     registry_path: str
     project_count: int
     sync_ok: bool
+    # Entries refused because a registry entry already claims one of their
+    # repositories: (candidate name, repository, name of the existing claimant).
+    # Reported rather than dropped silently — the operator decides what to do
+    # with a rejected candidate (GUIDING-PRINCIPLES 7).
+    skipped_claims: list[tuple[str, str, str]] = field(default_factory=list)
 
 
 @dataclass
@@ -311,6 +317,29 @@ def discover_candidates(
 # ---------------------------------------------------------------------------
 
 
+def _claimed_repos(registry: Registry) -> dict[str, str]:
+    """Canonical repository key -> the name of the entry already claiming it.
+
+    Archived entries hold no claim: retiring a project must not stop a new one
+    from taking over its repositories. Within the remaining segments the first
+    claimant wins, so an existing duplicate (there are seven today) reports one
+    stable owner instead of flapping between them.
+    """
+    claimed_by: dict[str, str] = {}
+    for segment in (
+        registry.active_projects,
+        registry.most_likely_active_projects,
+        registry.semi_active_projects,
+        registry.dormant_projects,
+        registry.potential_projects,
+    ):
+        for project in segment:
+            for repo in project.repos:
+                if key := canonical_repo_key(repo):
+                    claimed_by.setdefault(key, project.name)
+    return claimed_by
+
+
 def confirm_and_write(
     projects: list[dict[str, Any]],
     vault_path: Path,
@@ -324,9 +353,29 @@ def confirm_and_write(
     Creates standard vault directories (Projects/, Daily Notes/) if missing.
     """
     registry = load_registry(registry_path)
+    claimed_by = _claimed_repos(registry)
+    skipped_claims: list[tuple[str, str, str]] = []
+    written = 0
 
     for proj_dict in projects:
         project = Project.model_validate(proj_dict)
+
+        # A repository belongs to at most one project. This append is the write
+        # that put seven repositories into the registry twice (GH-182): discovery
+        # names a candidate after its repository because no project name exists
+        # yet, and nothing here checked whether a real project already claimed it.
+        collision = next(
+            (
+                (repo, claimed_by[key])
+                for repo in project.repos
+                if (key := canonical_repo_key(repo)) and key in claimed_by and claimed_by[key] != project.name
+            ),
+            None,
+        )
+        if collision is not None:
+            skipped_claims.append((project.name, collision[0], collision[1]))
+            continue
+
         # Respect explicit status field: active → active_projects (scored/tracked).
         # Otherwise fall back to activity-based segmentation.
         explicit_status = (proj_dict.get("status") or "").strip().lower()
@@ -335,6 +384,10 @@ def confirm_and_write(
         else:
             segment = _segment_project(proj_dict)
             getattr(registry, segment).append(project)
+        for repo in project.repos:
+            if key := canonical_repo_key(repo):
+                claimed_by.setdefault(key, project.name)
+        written += 1
 
     save_registry(registry_path=registry_path, registry=registry)
 
@@ -356,8 +409,9 @@ def confirm_and_write(
 
     return ConfirmResult(
         registry_path=str(registry_path),
-        project_count=len(projects),
+        project_count=written,
         sync_ok=sync_ok,
+        skipped_claims=skipped_claims,
     )
 
 
diff --git a/src/rebalance/ingest/project_inference.py b/src/rebalance/ingest/project_inference.py
index 718f18c..09179d0 100644
--- a/src/rebalance/ingest/project_inference.py
+++ b/src/rebalance/ingest/project_inference.py
@@ -23,7 +23,7 @@ from rebalance.ingest.db import (
     ensure_project_schema,
 )
 from rebalance.ingest.project_classifier import normalize_match_text
-from rebalance.ingest.registry import sync_db
+from rebalance.ingest.registry import canonical_repo_key, sync_db
 
 _GENERIC_ALIAS_TOKENS = {
     "app",
@@ -701,18 +701,56 @@ def _delete_stale_inferred_rows(database_path: Path, project_names: set[str]) ->
 def _partition_writable_rows(
     database_path: Path, projects: list[dict[str, Any]]
 ) -> tuple[list[dict[str, Any]], list[str]]:
-    """Split inferred rows into writable vs. curated-name collisions.
-
-    A name already present in project_registry WITHOUT the inference marker is
-    operator-curated state — inference must not touch it (the registry upsert
-    is keyed by name, so writing would clobber the curated row wholesale).
+    """Split inferred rows into writable vs. rows inference must not write.
+
+    Two things make a row unwritable, and they are the same contract seen from
+    two angles — inference owns its own rows and nothing else:
+
+    - **A curated name.** A name already in project_registry WITHOUT the
+      inference marker is operator-curated state (the upsert is keyed by name,
+      so writing would clobber the curated row wholesale).
+    - **A repository another project already claims.** One repository belongs to
+      at most one project; writing a second claim makes every project-level read
+      count that repository twice. This is GH-182, and inference reaches
+      project_registry through ``sync_db`` directly rather than through the
+      registry projection, so the projection's guard never sees these rows.
+
+    Claims are compared through :func:`canonical_repo_key`, and a project never
+    conflicts with itself. Ownership is collected as a *set* per repository
+    rather than first-writer-wins, so the outcome does not depend on the order
+    SQLite happens to return rows in — the existing duplicates would otherwise
+    make this decision flap between runs.
     """
     with db_connection(database_path, ensure_project_schema) as conn:
-        rows = conn.execute("SELECT name, custom_fields_json FROM project_registry").fetchall()
+        rows = conn.execute("SELECT name, custom_fields_json, repos_json FROM project_registry").fetchall()
+
     curated_names = {row["name"] for row in rows if not _is_inference_owned(row["custom_fields_json"])}
-    writable = [p for p in projects if p["name"] not in curated_names]
-    skipped = sorted(p["name"] for p in projects if p["name"] in curated_names)
-    return writable, skipped
+
+    claimants: dict[str, set[str]] = {}
+    for row in rows:
+        try:
+            repos = json.loads(row["repos_json"] or "[]")
+        except (json.JSONDecodeError, ValueError):
+            repos = []
+        for repo in repos:
+            if key := canonical_repo_key(str(repo)):
+                claimants.setdefault(key, set()).add(row["name"])
+
+    def _claimed_elsewhere(project: dict[str, Any]) -> bool:
+        for repo in project.get("repos") or []:
+            key = canonical_repo_key(str(repo))
+            if key and claimants.get(key, set()) - {project["name"]}:
+                return True
+        return False
+
+    writable: list[dict[str, Any]] = []
+    skipped: list[str] = []
+    for project in projects:
+        if project["name"] in curated_names or _claimed_elsewhere(project):
+            skipped.append(project["name"])
+        else:
+            writable.append(project)
+    return writable, sorted(skipped)
 
 
 def infer_project_registry(
diff --git a/src/rebalance/ingest/registry.py b/src/rebalance/ingest/registry.py
index 50406cf..381f668 100644
--- a/src/rebalance/ingest/registry.py
+++ b/src/rebalance/ingest/registry.py
@@ -8,6 +8,8 @@ from typing import Any
 import yaml
 from pydantic import BaseModel, Field
 
+from rebalance.ingest.config import canonical_github_repo_name
+
 
 class Project(BaseModel):
     name: str
@@ -46,6 +48,29 @@ class Registry(BaseModel):
     archived_projects: list[Project] = Field(default_factory=list)
 
 
+class DuplicateRepoClaimError(ValueError):
+    """Two registry entries claim the same repository.
+
+    Raised at the projection boundary. The registry markdown is hand-edited YAML,
+    so the projection is the only layer that sees an operator's edit before it
+    reaches SQLite. A duplicate claim projects as two ``project_registry`` rows and
+    every project-level read then counts one repository twice — GH-182, and the
+    same counted-once rule as SOP.md section 6.
+    """
+
+
+def canonical_repo_key(repo: str) -> str:
+    """The comparison key for a repository claim: canonical owner, casefolded.
+
+    Org renames are folded through :func:`canonical_github_repo_name` so a claim
+    survives a rename. A claim must not rest on a mutable spelling — that is what
+    let one repository enter the store under two names in the first place
+    (SOP.md section 6, clause 1). Returns "" for anything unusable, which callers
+    skip rather than treat as a claim.
+    """
+    return canonical_github_repo_name(repo or "").strip().casefold()
+
+
 YAML_BLOCK_PATTERN = re.compile(r"```ya?ml\s*(.*?)```", re.DOTALL | re.IGNORECASE)
 
 
@@ -127,8 +152,32 @@ Sections:
 
 
 def _registry_to_projection(registry: Registry) -> dict[str, Any]:
+    """Flatten the registry's active projects into the ``projects.yaml`` shape.
+
+    Refuses to project two entries that claim one repository. This guard sits here
+    rather than on a database constraint on purpose: the registry markdown is
+    hand-edited YAML and is the source of truth, so a constraint in SQLite could
+    only fail *after* the fact, at this same boundary. Failing loudly here keeps
+    the duplicate out of the store instead of detecting it once it is in.
+    """
     projects = []
+    claimed_by: dict[str, str] = {}
     for project in registry.active_projects:
+        for repo in project.repos:
+            key = canonical_repo_key(repo)
+            if not key:
+                continue
+            owner = claimed_by.get(key)
+            if owner is not None and owner != project.name:
+                raise DuplicateRepoClaimError(
+                    f"{repo!r} is claimed by two active projects: {owner!r} and "
+                    f"{project.name!r}. One repository belongs to at most one project — "
+                    f"projecting both would count its activity twice on every "
+                    f"project-level surface. Remove the claim from whichever entry is a "
+                    f"discovery placeholder (its name is one of its own repos) and "
+                    f"re-run the sync."
+                )
+            claimed_by[key] = project.name
         # Persist the typed ``external`` flag inside custom_fields_json so it
         # round-trips through the project_registry table without a schema column
         # (get_projects already decodes custom_fields, and read paths that open
diff --git a/tests/test_repo_claim_guard.py b/tests/test_repo_claim_guard.py
new file mode 100644
index 0000000..337b14c
--- /dev/null
+++ b/tests/test_repo_claim_guard.py
@@ -0,0 +1,303 @@
+"""GH-182 — a repository belongs to at most one project, enforced on the write paths.
+
+Companion to ``test_alias_dedup_invariant.py``, which *detects* two projects claiming one
+repository. These tests pin the two guards that stop the second claim being written at all.
+
+Deterministic and configuration-agnostic: every org and repo name is synthetic, the alias
+map is injected rather than read from an operator's ``rbos.config``, and the registry is a
+fresh temp file. Nothing here depends on which orgs this checkout's owner has renamed.
+
+Where the guards sit, and why there and not on a database constraint: the registry markdown
+is hand-edited YAML and is the source of truth, so SQLite can only ever fail *after* a bad
+edit, at the same projection boundary guard 2 already occupies.
+
+1. ``confirm_and_write`` refuses a candidate whose repository an entry already claims, and
+   reports it rather than dropping it silently.
+2. The refusal is canonical — an org-renamed spelling of a claimed repository still collides.
+3. An archived entry holds no claim; retiring a project frees its repositories.
+4. Re-confirming a project's own repository is not a collision.
+5. ``_registry_to_projection`` refuses to project two active entries claiming one repository.
+6. The fixture is not inert — the meta-check. Without the guard the duplicate IS written,
+   which is how this defect reached production: the first test written for it inserted a
+   duplicate that could never have failed.
+"""
+
+import pytest
+
+from rebalance.ingest import config as config_mod
+from rebalance.ingest import preflight as preflight_mod
+from rebalance.ingest.preflight import confirm_and_write
+from rebalance.ingest.registry import (
+    DuplicateRepoClaimError,
+    Project,
+    Registry,
+    _registry_to_projection,
+    canonical_repo_key,
+    read_registry,
+    save_registry,
+)
+
+OLD_ORG = "oldorg"
+NEW_ORG = "NewOrg"
+REPO = "widget-service"
+OLD_FULL = f"{OLD_ORG}/{REPO}"
+NEW_FULL = f"{NEW_ORG}/{REPO}"
+
+
+@pytest.fixture
+def aliases(monkeypatch):
+    """Inject a synthetic alias map so this never reads the operator's config."""
+    monkeypatch.setattr(config_mod, "get_github_org_aliases", lambda: {OLD_ORG: NEW_ORG})
+    return {OLD_ORG: NEW_ORG}
+
+
+@pytest.fixture
+def registry_path(tmp_path):
+    """A registry holding one real, human-named project that claims the repository."""
+    path = tmp_path / "Projects" / "00-project-registry.md"
+    registry = Registry(
+        active_projects=[Project(name="Widget Service", status="active", repos=[NEW_FULL], provenance="inferred")]
+    )
+    save_registry(registry_path=path, registry=registry)
+    return path
+
+
+def _placeholder(repo: str) -> dict:
+    """A discovery candidate, shaped exactly as ``discover_candidates`` emits one.
+
+    Its name IS its repository, because at discovery time no project name exists yet.
+    That placeholder becoming a permanent project is the whole of GH-182.
+    """
+    return {
+        "name": repo,
+        "status": "active",
+        "summary": "Recent activity: 9 commits, 19 total events (last 30 days).",
+        "repos": [repo],
+        "tags": ["A"],
+        "provenance": "remote-activity",
+    }
+
+
+def _write(projects, registry_path, tmp_path):
+    return confirm_and_write(
+        projects=projects,
+        vault_path=tmp_path / "vault",
+        registry_path=registry_path,
+        projects_yaml_path=tmp_path / "vault" / "projects.yaml",
+        database_path=tmp_path / "nonexistent.db",
+    )
+
+
+def test_canonical_repo_key_folds_a_renamed_owner(aliases):
+    assert canonical_repo_key(OLD_FULL) == canonical_repo_key(NEW_FULL)
+    assert canonical_repo_key(f"  {NEW_ORG.upper()}/{REPO}  ") == canonical_repo_key(NEW_FULL)
+    assert canonical_repo_key("") == ""
+
+
+def test_claimed_repository_is_refused_and_reported(aliases, registry_path, tmp_path):
+    result = _write([_placeholder(NEW_FULL)], registry_path, tmp_path)
+
+    assert result.project_count == 0
+    assert result.skipped_claims == [(NEW_FULL, NEW_FULL, "Widget Service")]
+
+    names = [p.name for p in read_registry(registry_path).active_projects]
+    assert names == ["Widget Service"]
+
+
+def test_the_refusal_is_canonical_not_literal(aliases, registry_path, tmp_path):
+    """The stale spelling must collide too, or an org rename re-opens the hole."""
+    result = _write([_placeholder(OLD_FULL)], registry_path, tmp_path)
+
+    assert result.project_count == 0
+    assert result.skipped_claims == [(OLD_FULL, OLD_FULL, "Widget Service")]
+
+
+def test_an_archived_entry_holds_no_claim(aliases, tmp_path):
+    """Retiring a project must free its repositories, or nothing can ever take them over."""
+    path = tmp_path / "Projects" / "00-project-registry.md"
+    save_registry(
+        registry_path=path,
+        registry=Registry(archived_projects=[Project(name="Retired", repos=[NEW_FULL])]),
+    )
+
+    result = _write([_placeholder(NEW_FULL)], path, tmp_path)
+
+    assert result.project_count == 1
+    assert result.skipped_claims == []
+
+
+def test_a_project_may_reconfirm_its_own_repository(aliases, registry_path, tmp_path):
+    same = {"name": "Widget Service", "status": "active", "repos": [NEW_FULL]}
+    result = _write([same], registry_path, tmp_path)
+
+    assert result.project_count == 1
+    assert result.skipped_claims == []
+
+
+def test_two_candidates_in_one_batch_cannot_both_claim_it(aliases, tmp_path):
+    """The batch checks itself, not only what was already on disk."""
+    path = tmp_path / "Projects" / "00-project-registry.md"
+    save_registry(registry_path=path, registry=Registry())
+
+    result = _write([_placeholder(NEW_FULL), _placeholder(OLD_FULL)], path, tmp_path)
+
+    assert result.project_count == 1
+    assert result.skipped_claims == [(OLD_FULL, OLD_FULL, NEW_FULL)]
+
+
+def test_provenance_survives_confirm_and_write(aliases, tmp_path):
+    """An unstamped row cannot be told apart from an operator's own — GH-182's real blocker."""
+    path = tmp_path / "Projects" / "00-project-registry.md"
+    save_registry(registry_path=path, registry=Registry())
+
+    _write([_placeholder(NEW_FULL)], path, tmp_path)
+
+    written = read_registry(path).active_projects
+    assert [p.provenance for p in written] == ["remote-activity"]
+
+
+def test_projection_refuses_two_active_claims(aliases):
+    registry = Registry(
+        active_projects=[
+            Project(name="Widget Service", repos=[NEW_FULL]),
+            Project(name=OLD_FULL, repos=[OLD_FULL]),
+        ]
+    )
+    with pytest.raises(DuplicateRepoClaimError) as excinfo:
+        _registry_to_projection(registry)
+
+    message = str(excinfo.value)
+    assert "Widget Service" in message and OLD_FULL in message
+
+
+def test_projection_allows_one_project_listing_a_repo_twice(aliases):
+    registry = Registry(active_projects=[Project(name="Widget Service", repos=[NEW_FULL, OLD_FULL])])
+
+    projected = _registry_to_projection(registry)
+
+    assert [p["name"] for p in projected["projects"]] == ["Widget Service"]
+
+
+def test_the_projection_fixture_is_not_inert(aliases, monkeypatch):
+    """Bypass the claim key and the same registry projects BOTH rows — the duplicate is real.
+
+    Without this, ``test_projection_refuses_two_active_claims`` could pass against a registry
+    the projection would have rejected for some unrelated reason.
+    """
+    import rebalance.ingest.registry as registry_mod
+
+    monkeypatch.setattr(registry_mod, "canonical_repo_key", lambda repo: "")
+    registry = Registry(
+        active_projects=[
+            Project(name="Widget Service", repos=[NEW_FULL]),
+            Project(name=OLD_FULL, repos=[OLD_FULL]),
+        ]
+    )
+
+    projected = _registry_to_projection(registry)
+
+    assert [p["name"] for p in projected["projects"]] == ["Widget Service", OLD_FULL]
+
+
+def test_the_fixture_is_not_inert(aliases, registry_path, tmp_path, monkeypatch):
+    """Without the guard the duplicate IS written — so these tests can actually fail.
+
+    The first guard written for this defect class inserted a duplicate whose metrics were
+    all zero, so summing it changed nothing and the test passed forever. Never again
+    without a check that the fixture would break the thing it claims to protect.
+    """
+    monkeypatch.setattr(preflight_mod, "_claimed_repos", lambda registry: {})
+
+    result = _write([_placeholder(NEW_FULL)], registry_path, tmp_path)
+
+    assert result.project_count == 1
+    assert result.skipped_claims == []
+    names = [p.name for p in read_registry(registry_path).active_projects]
+    assert names == ["Widget Service", NEW_FULL]
+
+
+# ---------------------------------------------------------------------------
+# Guard 3 — the inference writer, which reaches project_registry through
+# sync_db directly and so is never seen by the projection guard.
+# ---------------------------------------------------------------------------
+
+
+@pytest.fixture
+def inference_db(tmp_path, aliases):
+    """A store where one project already claims the repository."""
+    import sqlite3
+
+    from rebalance.ingest.db.schema import ensure_project_schema
+
+    path = tmp_path / "inference.db"
+    with sqlite3.connect(path) as conn:
+        ensure_project_schema(conn)
+        conn.execute(
+            "INSERT INTO project_registry (name, status, repos_json, custom_fields_json) VALUES (?, ?, ?, ?)",
+            (
+                "Widget Service",
+                "active",
+                f'["{NEW_FULL}"]',
+                '{"inference": {"generated_by": "activity_inference_v1"}}',
+            ),
+        )
+    return path
+
+
+def _inferred(name: str, repo: str) -> dict:
+    return {"name": name, "status": "active", "repos": [repo], "custom_fields": {}}
+
+
+def test_inference_will_not_write_a_repo_another_project_claims(inference_db):
+    from rebalance.ingest.project_inference import _partition_writable_rows
+
+    writable, skipped = _partition_writable_rows(inference_db, [_inferred(OLD_FULL, OLD_FULL)])
+
+    assert writable == []
+    assert skipped == [OLD_FULL]
+
+
+def test_inference_still_writes_its_own_row(inference_db):
+    """A project re-writing the repository it already owns is not a conflict."""
+    from rebalance.ingest.project_inference import _partition_writable_rows
+
+    writable, skipped = _partition_writable_rows(inference_db, [_inferred("Widget Service", NEW_FULL)])
+
+    assert [p["name"] for p in writable] == ["Widget Service"]
+    assert skipped == []
+
+
+def test_inference_writes_an_unclaimed_repo(inference_db):
+    from rebalance.ingest.project_inference import _partition_writable_rows
+
+    writable, skipped = _partition_writable_rows(inference_db, [_inferred("Gadget", f"{NEW_ORG}/gadget-service")])
+
+    assert [p["name"] for p in writable] == ["Gadget"]
+    assert skipped == []
+
+
+def test_inference_partition_does_not_depend_on_row_order(tmp_path, aliases):
+    """With a duplicate already stored, the decision must not flap between runs.
+
+    Ownership is collected per repository as a set, so which of the two existing
+    claimants SQLite returns first cannot change the answer.
+    """
+    import sqlite3
+
+    from rebalance.ingest.db.schema import ensure_project_schema
+    from rebalance.ingest.project_inference import _partition_writable_rows
+
+    path = tmp_path / "dupes.db"
+    with sqlite3.connect(path) as conn:
+        ensure_project_schema(conn)
+        for name in ("Widget Service", NEW_FULL):
+            conn.execute(
+                "INSERT INTO project_registry (name, status, repos_json, custom_fields_json)"
+                " VALUES (?, 'active', ?, '{}')",
+                (name, f'["{NEW_FULL}"]'),
+            )
+
+    writable, skipped = _partition_writable_rows(path, [_inferred("Third Claimant", NEW_FULL)])
+
+    assert writable == []
+    assert skipped == ["Third Claimant"]
```
