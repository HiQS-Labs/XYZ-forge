# RELAY · Text Replacement Studio — script-resolution portability fix
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: —
STATUS: Closed
ROUND: 3 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions. The artifact under review is **embedded in the Round 1 Producer block below** (a git diff + surrounding code), because it lives in a *different* repo than this relay file — so review it from the embedded text, do NOT try to open files on disk.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act.
3. **Do your role's work:**
   - **Reviewer:** review the embedded diff against the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS`.

## Setup
- Artifact under review: **embedded below** — changes in `text-replacement-studio-macos` repo: `macOS/Sources/TextReplacementCore/Integration/PythonBridge.swift` + `macOS/make-app.sh`
- Definition of Done: **The two changes make the packaged macOS app locate its Python scripts durably across ANY device, username, and checkout location — not just this one machine's configuration. Flag anything that is still device-/checkout-specific or makes a hidden environmental assumption.**
- Producer: claude (Claude Code, Opus)   ·   Reviewer: agy (Antigravity CLI, independent model)
- Handoff: cli-driven (agy)
- Started: 2026-06-24

## Context the reviewer needs
**The app** (Text Replacement Studio) is a SwiftUI macOS app installed to `/Applications`. It manages macOS Text Replacements by shelling out to Python scripts (`native_to_json.py` etc.) that live in the repo's `scripts/` dir. `PythonBridge.resolveScriptsDirectory()` must find that `scripts/` dir at runtime.

**The bug being fixed:** When launched from `/Applications` (Finder launch), the original resolver failed with `scriptsDirectoryNotFound` → user saw "Import failed". Because: (a) CWD is `/` so walking up finds nothing; (b) the executable is inside the `.app` bundle so walking up from it finds nothing; (c) the only remaining fallback was a hardcoded absolute path pointing at an OLD repo location that no longer exists.

**The two changes (full diff):**

```diff
# macOS/Sources/TextReplacementCore/Integration/PythonBridge.swift
@@ -69,6 +69,14 @@ public struct PythonBridge: Sendable {
+        // Packaged .app: scripts are bundled under Contents/Resources/scripts. This is what makes
+        // an install to /Applications self-contained (CWD is `/` and the exe is inside the bundle,
+        // so the walk-up below finds nothing).
+        if let resources = Bundle.main.resourceURL {
+            let bundled = resources.appendingPathComponent("scripts")
+            if hasScripts(bundled) { return bundled }
+        }
+
         var roots = [URL(fileURLWithPath: fm.currentDirectoryPath)]
         if let exe = Bundle.main.executableURL { roots.append(exe.deletingLastPathComponent()) }
         for root in roots {
@@ -83,7 +91,7 @@ public struct PythonBridge: Sendable {
-        let known = URL(fileURLWithPath: ("~/Documents/GH Repos/fast-key-replacement-macos/scripts" as NSString).expandingTildeInPath)
+        let known = URL(fileURLWithPath: ("~/Documents/GitHub-Repos/text-replacement-studio-macos/scripts" as NSString).expandingTildeInPath)
         if hasScripts(known) { return known }

         throw BridgeError.scriptsDirectoryNotFound

# macOS/make-app.sh  (packaging script that builds the .app and installs to /Applications)
@@ -52,6 +52,14 @@ done   (just after copying the AppIcon into Contents/Resources)
+# Bundle the repo's Python scripts so the installed app is self-contained. PythonBridge
+# resolves these from Contents/Resources/scripts (CWD is `/` on a Finder launch, and the
+# executable lives inside the bundle, so it can't walk up to the repo).
+SCRIPTS_SRC="$PKG_DIR/../scripts"
+[ -d "$SCRIPTS_SRC" ] || { echo "✗ scripts/ not found at $SCRIPTS_SRC"; exit 1; }
+[ -f "$SCRIPTS_SRC/json_to_apple_sqlite.py" ] || { echo "✗ json_to_apple_sqlite.py missing in $SCRIPTS_SRC"; exit 1; }
+cp -R "$SCRIPTS_SRC" "$APP/Contents/Resources/scripts"
```

**Full surrounding function after the change** (`resolveScriptsDirectory()`):
```swift
static func resolveScriptsDirectory() throws -> URL {
    let fm = FileManager.default
    func hasScripts(_ dir: URL) -> Bool {
        fm.fileExists(atPath: dir.appendingPathComponent("json_to_apple_sqlite.py").path)
    }

    if let env = ProcessInfo.processInfo.environment["FKR_SCRIPTS_DIR"], !env.isEmpty {
        let url = URL(fileURLWithPath: (env as NSString).expandingTildeInPath)
        if hasScripts(url) { return url }
    }

    // Packaged .app: scripts are bundled under Contents/Resources/scripts.
    if let resources = Bundle.main.resourceURL {
        let bundled = resources.appendingPathComponent("scripts")
        if hasScripts(bundled) { return bundled }
    }

    var roots = [URL(fileURLWithPath: fm.currentDirectoryPath)]
    if let exe = Bundle.main.executableURL { roots.append(exe.deletingLastPathComponent()) }
    for root in roots {
        var dir = root
        for _ in 0..<8 {
            if hasScripts(dir.appendingPathComponent("scripts")) {
                return dir.appendingPathComponent("scripts")
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            dir = parent
        }
    }

    let known = URL(fileURLWithPath: ("~/Documents/GitHub-Repos/text-replacement-studio-macos/scripts" as NSString).expandingTildeInPath)
    if hasScripts(known) { return known }

    throw BridgeError.scriptsDirectoryNotFound
}
```

**Other relevant facts:**
- The scripts are pure Python stdlib (sqlite3, plistlib, json, argparse, …) plus a same-dir local module `replacements_common.py`. The app invokes them via `/usr/bin/env python3` (overridable by `FKR_PYTHON` env). The `.app` bundles **no** Python interpreter.
- `make-app.sh` ad-hoc signs with `codesign --force --deep --sign -`. The scripts are copied into `Contents/Resources/scripts` BEFORE signing.
- `Bundle.main.resourceURL` for the manually-assembled `.app` (executable in `Contents/MacOS/`, resources in `Contents/Resources/`) is expected to be `…/Contents/Resources`.
- Verified so far: running the bundled `native_to_json.py` via system python3 exported 83 replacements (exit 0). NOT yet verified: that the Swift `Bundle.main.resourceURL` lookup actually resolves in the running packaged app (the python test bypassed Swift).

## Ground rules
1. This file is the single source of truth. The artifact is embedded above — review it from the embedded text, not from disk.
2. Take a turn only if `NEXT` names your role.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight. Findings are bullets, not essays.
5. The Reviewer never edits the artifact — propose graded findings with concrete suggested fixes.
6. Grade every finding: `[Blocker]` must-fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked & sound.
7. Post a Verdict every turn. `Changes requested` keeps it open for the Producer; `Approved` closes it.
10. Evidence contract — state your verdict `Basis:` (behaviorally proven | textual only | N/A).

## Roles
- **Producer** — claude. Authored the fix; decides & implements proposals.
- **Reviewer** — agy. Reviews against the DoD for true cross-device portability; proposes graded findings. Never edits.

---
## Log

### Round 1 · Producer · claude · 2026-06-24
**Did:** Fixed the packaged app failing to find its Python `scripts/` dir when launched from `/Applications` (user-reported "Import failed"). Two changes (full diff embedded in "Context" above):
- `PythonBridge.swift`: added a `Bundle.main.resourceURL/scripts` lookup so the resolver finds scripts bundled inside the `.app`; also re-pointed the stale hardcoded fallback path.
- `make-app.sh`: copy the repo's `scripts/` into `Contents/Resources/scripts` at packaging time so the install is self-contained.
**Review this — the operator's specific worry is portability across machines, NOT just "does it work on my box."** Please scrutinize:
- Is the `Bundle.main.resourceURL/scripts` approach genuinely device-independent (any username, any `/Applications` install)?
- The re-pointed hardcoded fallback `~/Documents/GitHub-Repos/text-replacement-studio-macos/scripts` — is this still a machine-/checkout-specific assumption that should be removed rather than re-pointed? Does it ever help on a different device?
- The `/usr/bin/env python3` dependency: the app bundles no interpreter. On a fresh Mac without Command Line Tools, `/usr/bin/python3` is a stub that prompts to install CLT. Is this a portability blocker that needs handling (detection, clear error, or bundling), or acceptable?
- Any other hidden environmental assumption that would make these "fixes for this config only" rather than durable.
**Verification:** ran the bundled `native_to_json.py` via system python3 → exported 83 replacements (exit 0). Did NOT verify the Swift `Bundle.main.resourceURL` resolution inside the running packaged app (textual confidence only).
**Open questions:** Should the hardcoded fallback be deleted outright? Is the python3 runtime dependency worth hardening now or documenting as a known requirement?
**Commit:** none (artifact lives in another repo; embedded above)

### Round 1 · Reviewer · agy · 2026-06-24
**Verdict:** Changes requested
**Basis:** Textual only

- **[Blocker] Hardcoded fallback path is checkout-specific:**
  - *Finding:* The fallback path `~/Documents/GitHub-Repos/text-replacement-studio-macos/scripts` is device/checkout-specific and violates the Definition of Done. If the repository is cloned to a different path or run on a machine without this specific directory structure, the fallback will fail or potentially run outdated scripts from a stale repository clone.
  - *Proposed Fix:* Delete the hardcoded `known` fallback path completely. The recursive walk-up logic already dynamically finds the `scripts/` directory relative to the current working directory or the executable path, making a hardcoded fallback redundant and unsafe.
- **[Pass] Bundled resource lookup:**
  - *Finding:* `Bundle.main.resourceURL?.appendingPathComponent("scripts")` correctly and dynamically locates the python scripts in a self-contained packaged `.app` bundle, resolving the Finder launch issue.
- **[Pass] Packaging validation in `make-app.sh`:**
  - *Finding:* The checks `[ -d "$SCRIPTS_SRC" ]` and `[ -f "$SCRIPTS_SRC/json_to_apple_sqlite.py" ]` correctly guard against packaging the app without scripts.
- **[Should] Python 3 environmental assumption UI handling:**
  - *Finding:* The app relies on `/usr/bin/env python3` which is not pre-installed on fresh macOS installations (or points to the Xcode CLT stub).
  - *Proposed Fix:* In the execution logic (where the script is invoked), catch launch/interpreter errors and present a user-facing prompt or settings page explaining how to install Python 3 or select a custom Python path, rather than showing a generic "Import failed".

### Round 2 · Producer · claude · 2026-06-24
**Decisions on proposals:** (verified each against the source before deciding)
- [Blocker] Hardcoded fallback is checkout-specific — **Implemented** → deleted the `known`/`hasScripts(known)` fallback in `PythonBridge.resolveScriptsDirectory()`; it now throws `scriptsDirectoryNotFound` directly after the bundle lookup + walk-up. Agreed with the *stale-clone* risk — a re-pointed path isn't just dead, it could silently run outdated scripts. · Proof: rebuilt + reinstalled to `/Applications`; bundled scripts present at `Contents/Resources/scripts`; `native_to_json.py` exported 83 replacements (exit 0).
- [Pass] Bundled resource lookup — acknowledged; this is the actual portable fix. Confirmed scripts land at the exact path `Bundle.main.resourceURL/scripts` resolves to.
- [Pass] Packaging validation in `make-app.sh` — acknowledged.
- [Should] python3 environmental assumption UX — **Deferred to operator** (scope decision, not a code defect). Routing to the user: harden now (preflight check in `PythonBridge` that python3 is resolvable → actionable error) vs. document as a known requirement. The blocker (true portability) is independent of this.
**Did:** Removed the machine-specific fallback path (PythonBridge.swift); replaced with an explanatory comment. Rebuilt + reinstalled the app.
**Verification:** ran `make-app.sh` → built/signed/installed OK · ran bundled `native_to_json.py` via system python3 → 83 replacements, exit 0 · confirmed `Contents/Resources/scripts/json_to_apple_sqlite.py` present. Did NOT script-drive the GUI import toast (manual confirmation by operator).
**Re-review this:** the Blocker is resolved by deletion; re-review optional. The python3 [Should] awaits an operator decision.
**Commit:** none (artifact lives in the text-replacement-studio-macos repo, uncommitted per operator)

### Round 3 · Producer · claude · 2026-06-24
**Decisions on proposals:**
- [Should] python3 environmental assumption — **Implemented** (operator chose "harden in code"). Added `BridgeError.pythonNotFound` with actionable guidance (install Command Line Tools via `xcode-select --install`, or set `FKR_PYTHON`) and a `preflightPython()` probe that runs before any script call in `PythonBridge.run()`. Portable: probes the *configured* interpreter, no hardcoded interpreter paths. · Proof: built `trstudio`; `import` → "Imported 83 replacements" (exit 0); `FKR_PYTHON=/nonexistent/python3 import` → the actionable pythonNotFound message (not exit-127 noise). Rebuilt + reinstalled the `.app`.
**Did:** Hardened the python3 dependency per the [Should]. All three substantive findings now resolved; the surviving fixes carry no machine-/checkout-specific assumptions.
**Verification:** `swift build -c release --product trstudio` OK · happy + error paths exercised via CLI (above) · `make-app.sh` rebuilt/installed OK.
**Re-review this:** optional — relay goal (confirm portability, fix what isn't) met.
**Commit:** none (artifact in text-replacement-studio-macos repo, uncommitted per operator)

**STATUS set to Closed by operator direction** — independent review complete, all findings dispositioned.

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
