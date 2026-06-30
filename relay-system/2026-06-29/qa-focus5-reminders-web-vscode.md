# RELAY · QA review: Focus5 reminders panel + card restack + web vscode focus-if-open
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-29.
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
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(qa-focus5-reminders-web-vscode): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **qa-review-changeset.diff** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-06-29

### Definition of Done — what to review (focus on correctness/security/edge-cases, NOT build status)

Three independently-shipped changes are in the diff. Review each for correctness, edge cases, and
security. **Already verified by the producer** (do not re-litigate): `swift build` green,
`FOCUS5_SELFTEST` passes, `pytest tests/test_focus5_scan.py` = **89 passed**, `rebalance doctor` +
PDDA gate pass. Spend your turn on what tests/builds DON'T catch.

1. **Focus 5 Float — Apple Reminders bottom panel** (`RemindersStore.swift` [new], `ContentView.swift`
   `RemindersSection`/`ReminderRow`, `Focus5Model.swift` wiring, `make-app.sh` TCC plist keys).
   Scrutinize: the EventKit authorization state machine (`.writeOnly`/`.restricted` mapping); the
   **2-second check-then-fade** (`completingIDs` held across `refresh()` so a poll mid-window can't
   drop the row early — is the held-row union logic correct? double-tap guard? leak if the task is
   cancelled?); `@MainActor` + `withCheckedContinuation` from `fetchReminders` (any actor-hop /
   data-race smell); single-writer + failure-reverts-optimistic-state; SF Symbol names actually exist
   (`circle.inset.filled`); the "no FDA needed" claim (read-back via EventKit, not SQLite).

2. **Card layout restack + narrow-width controls** (`ContentView.swift` `RepoCardView`, the `「」`
   narrow button + `narrowWindow()` finding the `FloatingPanel`). Scrutinize: SwiftUI layout
   correctness (`fixedSize`, wrapping vs clipping at the 180px min width), and whether `narrowWindow()`
   safely no-ops if the panel can't be found.

3. **Web app VS Code focus-if-open (Phase 2)** (`web.py` `POST /api/focus5/open`,
   `_focus5_open_allowlist`, `_resolve_code_binary`, `_request_is_local`; `web_components.py`
   `button_link(attrs=…)`; the `_FOCUS5_OPEN_ASSETS` click JS; `tests/test_focus5_scan.py`).
   Scrutinize **hardest here** (this route executes a binary): command-injection surface
   (argv list, no shell — is the allowlisted `local_path` ever attacker-influenced?); the
   **same-origin-only guard** — is dropping the client-host loopback check acceptable given the
   server's loopback bind, or a real gap? the **unescaped `attrs` injection** in `button_link` (is the
   `identity` value that flows into `data-f5-open` fully escaped at the call site — any XSS path?);
   HTTP status semantics (404 unknown / 409 no-binary / 403 cross-origin); the JS `vscode://` fallback
   correctness; whether the test mocks hide a real path.

Grade findings `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` with a concrete fix each, then set a Verdict.

### Artifact — qa-review-changeset.diff
```
# QA review changeset — branch feat/apple-reminders-write
# Scope: Focus 5 Float Apple Reminders panel + card restack + web VS Code focus-if-open (Phase 2)

diff --git a/macOS/Apps/Focus5Float/Sources/Focus5Float/ContentView.swift b/macOS/Apps/Focus5Float/Sources/Focus5Float/ContentView.swift
index 8273e38..cf69976 100644
--- a/macOS/Apps/Focus5Float/Sources/Focus5Float/ContentView.swift
+++ b/macOS/Apps/Focus5Float/Sources/Focus5Float/ContentView.swift
@@ -1,5 +1,6 @@
 import SwiftUI
 import AppKit
+import EventKit
 
 // Phase 3 UI: vertical stack of collapsible repo cards over the live
 // /focus-5.json (Phase 4), using the harvested Theme + components. Collapsed
@@ -27,12 +28,15 @@ struct ContentView: View {
         .animation(.easeInOut(duration: 0.35), value: model.banner)
     }
 
-    /// The vault `focus5.md` note, rendered as the last card in the roster scroll
-    /// (Focus 5 / Dirty Five only). Content-hugging so it takes only the space it
-    /// needs; hidden until the first successful fetch so an offline cold-start
-    /// doesn't flash the "add a note" hint.
-    @ViewBuilder private var noteFooter: some View {
-        if model.viewMode != .telemetry && model.noteLoaded {
+    // MARK: Bottom sections (Reminders + Note)
+
+    /// The two bottom sections — Apple Reminders (A) over the focus5.md note (B) —
+    /// rendered inline at the end of the single roster scroll so they size to
+    /// their content (liquid) and flow right under the cards with no dead space.
+    /// Non-telemetry only; the note appears once its first fetch lands.
+    @ViewBuilder private var bottomSections: some View {
+        RemindersSection(store: model.reminders)
+        if model.noteLoaded {
             Focus5NoteView(exists: model.noteExists, content: model.noteContent)
         }
     }
@@ -84,6 +88,17 @@ struct ContentView: View {
                 .foregroundStyle(Theme.text2)
                 .help(model.viewMode == .telemetry ? "Re-read telemetry files" : "Re-pull /focus-5.json")
 
+                Button {
+                    narrowWindow()
+                } label: {
+                    Text("「」")
+                        .font(.system(size: 13))
+                        .fixedSize()
+                }
+                .buttonStyle(.borderless)
+                .foregroundStyle(Theme.text2)
+                .help("Snap to narrowest width (keeps height)")
+
                 if model.viewMode != .telemetry && model.isOffline {
                     Button {
                         Task { await model.startServer() }
@@ -142,6 +157,15 @@ struct ContentView: View {
         .padding(Theme.Space.m)
     }
 
+    /// Snap the floating panel to its minimum width, leaving height + position
+    /// otherwise as-is (the bottom-left corner stays put, the right edge moves in).
+    private func narrowWindow() {
+        guard let panel = NSApp.windows.first(where: { $0 is FloatingPanel }) else { return }
+        var frame = panel.frame
+        frame.size.width = panel.minSize.width   // height unchanged
+        panel.setFrame(frame, display: true, animate: true)
+    }
+
     /// The roster/telemetry health light — a dirty-count + tinted dot, adapting to
     /// the active tab. Lives on the status row (row 2) so it no longer widens the
     /// tab row.
@@ -198,7 +222,7 @@ struct ContentView: View {
                                    title: model.isDirtyView ? "Nothing at risk" : "No active repos found",
                                    detail: "The server roster is empty. Build it server-side (open /focus-5 in the browser or run a Focus 5 sync), then Refresh here to re-pull.")
                             .frame(minHeight: 160)
-                        noteFooter
+                        bottomSections
                     }
                     .padding(Theme.Space.m)
                 }
@@ -211,7 +235,7 @@ struct ContentView: View {
                         if !model.offRoster.isEmpty {
                             OffRosterFooter(warnings: model.offRoster)
                         }
-                        noteFooter
+                        bottomSections
                     }
                     .padding(Theme.Space.m)
                 }
@@ -307,16 +331,16 @@ struct RepoCardView: View {
 
     var body: some View {
         VStack(alignment: .leading, spacing: 6) {
-            // Always-visible summary
+            // Row 1 — position badge + actions (Open / status / chevron), so the
+            // controls share one slim row regardless of how wide the name is.
             HStack(spacing: Theme.Space.s) {
                 KeyCap(text: "#\(card.position)")
-                Text(card.repoName)
-                    .font(Theme.bodyMed).foregroundStyle(Theme.text).lineLimit(1)
                 Spacer(minLength: Theme.Space.s)
                 Button("Open ↗") { VSCodeLauncher.launch(repoPath: card.localPath, fallbackURL: card.vscodeUrl) }
                     .buttonStyle(.borderless)
                     .font(Theme.caption)
                     .foregroundStyle(Theme.accent)
+                    .fixedSize()
                     .help("Open \(card.repoName) in VS Code")
                 StatusDot(isDirty: card.isDirty, healthAvailable: card.healthAvailable)
                 Image(systemName: expanded ? "chevron.down" : "chevron.right")
@@ -324,8 +348,16 @@ struct RepoCardView: View {
                     .foregroundStyle(Theme.text3)
             }
 
+            // Row 2 — repo name, full width + prominent; wraps in the narrow panel
+            // instead of competing with the badge/controls for horizontal space.
+            Text(card.repoName)
+                .font(Theme.display).foregroundStyle(Theme.text)
+                .fixedSize(horizontal: false, vertical: true)
+                .frame(maxWidth: .infinity, alignment: .leading)
+
+            // Rank reason / last-commit line — smaller + greyer (a caption, not body).
             Text(card.rankReason)
-                .font(Theme.body).foregroundStyle(Theme.text2)
+                .font(.system(size: 11)).foregroundStyle(Theme.text3)
                 .lineLimit(2).fixedSize(horizontal: false, vertical: true)
 
             HStack(spacing: Theme.Space.m) {
@@ -458,6 +490,121 @@ struct TelemetryRowView: View {
     }
 }
 
+// MARK: - Apple Reminders (section A)
+
+/// Section A — the 10 most-recent active tasks from the default Apple Reminders
+/// list, read+written LIVE via EventKit (see `RemindersStore`). Branches on the
+/// TCC authorization state: an enable button before the grant, a System-Settings
+/// hint if denied, the bounded scrollable task list once granted. Each row's
+/// checkbox completes the reminder (the only mutation in v1).
+struct RemindersSection: View {
+    let store: RemindersStore
+
+    var body: some View {
+        VStack(alignment: .leading, spacing: Theme.Space.xs) {
+            Text("REMINDERS")
+                .font(Theme.caption).foregroundStyle(Theme.text3).tracking(0.5)
+            content
+        }
+        .frame(maxWidth: .infinity, alignment: .leading)
+        .padding(.top, Theme.Space.s)
+    }
+
+    @ViewBuilder private var content: some View {
+        switch store.access {
+        case .notDetermined:
+            Button {
+                // A non-activating accessory panel must come forward so the
+                // system TCC prompt is presented frontmost.
+                NSApp.activate(ignoringOtherApps: true)
+                Task { await store.requestAccess() }
+            } label: {
+                Label("Enable Apple Reminders", systemImage: "checklist")
+            }
+            .buttonStyle(.borderless)
+            .font(Theme.body).foregroundStyle(Theme.accent)
+            .help("Grant Reminders access to show your default list here")
+
+        case .denied:
+            Text("Reminders access is off. Enable it in System Settings ▸ Privacy & Security ▸ Reminders, then Refresh.")
+                .font(Theme.monoSmall).foregroundStyle(Theme.text3)
+                .fixedSize(horizontal: false, vertical: true)
+
+        case .granted:
+            if store.items.isEmpty {
+                Text("No active reminders.")
+                    .font(Theme.body).foregroundStyle(Theme.text3)
+                    .padding(.vertical, 2)
+            } else {
+                // Inline (no inner scroll) so the section sizes to its content and
+                // flows within the single panel scroll — liquid, no reserved slab.
+                VStack(spacing: 4) {
+                    ForEach(store.items, id: \.calendarItemIdentifier) { reminder in
+                        ReminderRow(reminder: reminder, store: store)
+                    }
+                }
+            }
+            if let err = store.loadError {
+                Text(err)
+                    .font(Theme.monoSmall).foregroundStyle(Theme.diffRemove)
+                    .fixedSize(horizontal: false, vertical: true)
+            }
+        }
+    }
+}
+
+/// One reminder: a tap-to-complete checkbox + title (+ relative due date). The
+/// checkbox is the single write surface — completing drops the row on re-read.
+struct ReminderRow: View {
+    let reminder: EKReminder
+    let store: RemindersStore
+
+    /// True during the ~2s check-then-fade beat after the user completes it.
+    private var isCompleting: Bool {
+        store.completingIDs.contains(reminder.calendarItemIdentifier)
+    }
+
+    var body: some View {
+        HStack(alignment: .top, spacing: Theme.Space.s) {
+            Button {
+                Task { await store.complete(reminder) }
+            } label: {
+                Image(systemName: isCompleting ? "circle.inset.filled" : "circle")
+                    .font(.system(size: 13))
+                    .foregroundStyle(isCompleting ? Theme.accent : Theme.text3)
+            }
+            .buttonStyle(.borderless)
+            .disabled(isCompleting)
+            .help("Mark complete")
+
+            VStack(alignment: .leading, spacing: 1) {
+                Text(reminder.title ?? "(untitled)")
+                    .font(Theme.body).foregroundStyle(isCompleting ? Theme.text3 : Theme.text)
+                    .strikethrough(isCompleting)
+                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
+                if let due = dueText {
+                    Text(due).font(Theme.monoSmall).foregroundStyle(Theme.text3)
+                }
+            }
+            Spacer(minLength: 0)
+        }
+        .padding(Theme.Space.s)
+        .frame(maxWidth: .infinity, alignment: .leading)
+        .background(Theme.elevated, in: RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
+        .opacity(isCompleting ? 0.6 : 1)
+        .animation(.easeInOut(duration: 0.2), value: isCompleting)
+    }
+
+    /// "due <relative>" for a dated reminder (past or future), else nil.
+    private var dueText: String? {
+        guard let comps = reminder.dueDateComponents,
+              let date = Calendar.current.date(from: comps) else { return nil }
+        let f = RelativeDateTimeFormatter()
+        f.unitsStyle = .short
+        return "due \(f.localizedString(for: date, relativeTo: Date()))"
+    }
+}
+
 // MARK: - Bottom note (vault focus5.md)
 
 /// Free-form note pulled from the operator's Obsidian vault (`focus5.md`), shown
diff --git a/macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5FloatApp.swift b/macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5FloatApp.swift
index a1dd176..bd819c1 100644
--- a/macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5FloatApp.swift
+++ b/macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5FloatApp.swift
@@ -151,9 +151,9 @@ final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
     private func buildPanel() {
         // Compact by default now the header is a slim emoji tab row over a
         // wrapped status line: 200 wide is a comfortable starting point that can
-        // be dragged down to the 180 floor without clipping. 560 tall keeps a
-        // calm default now the note hugs its content instead of reserving a slab.
-        let defaultRect = NSRect(x: 0, y: 0, width: 200, height: 560)
+        // be dragged down to the 180 floor without clipping. 660 tall leaves the
+        // roster room above the new two-section bottom drawer (Reminders + note).
+        let defaultRect = NSRect(x: 0, y: 0, width: 200, height: 660)
 
         let hostingView = FirstMouseHostingView(rootView: ContentView(model: model))
         hostingView.frame = defaultRect
@@ -188,9 +188,9 @@ final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
         panel.minSize = NSSize(width: 180, height: 320)
 
         // Frame autosave — remembers position & size across launches. Bumped to
-        // ".v3" to retire any stale wide frame saved under the old 360/380 layout;
-        // the window resets once to the new compact default, then persists again.
-        panel.setFrameAutosaveName("Focus5FloatPanel.v3")
+        // ".v4" so the taller default (room for the Reminders + note drawer) takes
+        // effect once over any stale ".v3" height, then persists again.
+        panel.setFrameAutosaveName("Focus5FloatPanel.v4")
         if panel.frame.origin == .zero {
             panel.center()
         }
diff --git a/macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5Model.swift b/macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5Model.swift
index 21b5988..36d259c 100644
--- a/macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5Model.swift
+++ b/macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5Model.swift
@@ -49,6 +49,10 @@ final class Focus5Model {
     var noteExists = false            // true once the vault actually has a focus5.md
     var noteLoaded = false            // true after the first successful note fetch
 
+    // Bottom Apple Reminders — read+write DIRECTLY via EventKit (not the server).
+    // See RemindersStore for why the app is the runtime that can hold the grant.
+    let reminders = RemindersStore()
+
     // Transient top banner ("Repos refreshed") — set after a successful *manual*
     // refresh so the recycle button gives visible feedback; the view fades it out
     // on clear. Background polling never sets it (it'd flash unprompted every 90s).
@@ -95,6 +99,7 @@ final class Focus5Model {
         } else {
             _ = await fetchAndApply(dirty: isDirtyView)
             await refreshNote()
+            await reminders.refresh()   // EventKit; no-ops until access granted
         }
     }
 
diff --git a/macOS/Apps/Focus5Float/Sources/Focus5Float/RemindersStore.swift b/macOS/Apps/Focus5Float/Sources/Focus5Float/RemindersStore.swift
new file mode 100644
index 0000000..244ca9c
--- /dev/null
+++ b/macOS/Apps/Focus5Float/Sources/Focus5Float/RemindersStore.swift
@@ -0,0 +1,131 @@
+import Foundation
+import EventKit
+import os
+
+// Apple Reminders, read + write, DIRECTLY via EventKit — not through `rebalance
+// serve`. Focus 5 Float is a signed, LaunchServices-launched app bundle with a
+// stable bundle id, which is exactly the runtime the Apple Reminders plan
+// (Phase 5.0) proved can hold the Reminders TCC grant; the Python/server path
+// can't write (suppressed under the agent tree) and reads stale by design. We
+// need only the Reminders (EventKit) grant — NOT Full Disk Access — because the
+// read-back here goes through EventKit, not the SQLite extractor.
+//
+// Scope v1: show the 10 most-recent ACTIVE tasks from the default list; the only
+// mutation is `complete` (least destructive). create/edit/delete stay with the
+// `rebalance apple-reminders` CLI (human-in-the-loop).
+
+private let log = Logger(subsystem: "me.neochro.Focus5Float", category: "reminders")
+
+@MainActor
+@Observable
+final class RemindersStore {
+    /// Coarse authorization state the UI branches on. Collapses EventKit's many
+    /// raw statuses into the three the bottom panel actually renders.
+    enum Access { case notDetermined, denied, granted }
+
+    var access: Access = .notDetermined
+    var items: [EKReminder] = []        // ≤10, newest-first, active only
+    var listName: String?               // default list title, for the header
+    var loadError: String?              // last read/write failure (nil when none)
+    /// Reminders saved as complete but still shown (filled) for a brief beat
+    /// before they drop off — mirrors Apple Reminders' check-then-fade.
+    var completingIDs: Set<String> = []
+
+    private let store = EKEventStore()
+    static let maxItems = 10
+
+    init() { syncAuthorization() }
+
+    /// Map EventKit's raw status onto our 3-state enum. Read needs full access;
+    /// `.writeOnly` can't list reminders, so it counts as "needs access".
+    func syncAuthorization() {
+        switch EKEventStore.authorizationStatus(for: .reminder) {
+        case .notDetermined:
+            access = .notDetermined
+        case .fullAccess, .authorized:
+            access = .granted
+        case .denied, .restricted, .writeOnly:
+            access = .denied
+        @unknown default:
+            access = .notDetermined
+        }
+    }
+
+    /// Present the system TCC prompt. Must be reached from a LaunchServices-
+    /// launched bundle (an installed `.app`), not `swift run` under a terminal/
+    /// agent tree — there the prompt is suppressed (see Phase 5.0 findings).
+    func requestAccess() async {
+        do {
+            let granted = try await store.requestFullAccessToReminders()
+            access = granted ? .granted : .denied
+            log.info("reminders access request → \(granted ? "granted" : "denied")")
+            if granted { await refresh() }
+        } catch {
+            access = .denied
+            loadError = error.localizedDescription
+            log.error("reminders access request failed: \(error.localizedDescription)")
+        }
+    }
+
+    /// Re-read the ≤10 most-recent active reminders from the default list.
+    /// No-op (keeps the UI in its access-prompt state) until access is granted.
+    func refresh() async {
+        syncAuthorization()
+        guard access == .granted else { return }
+        guard let calendar = store.defaultCalendarForNewReminders() else {
+            items = []; listName = nil
+            return
+        }
+        listName = calendar.title
+
+        let predicate = store.predicateForIncompleteReminders(
+            withDueDateStarting: nil, ending: nil, calendars: [calendar])
+        let fetched: [EKReminder] = await withCheckedContinuation { cont in
+            store.fetchReminders(matching: predicate) { reminders in
+                cont.resume(returning: reminders ?? [])
+            }
+        }
+
+        // "Most recent" = newest creationDate first; nils sort oldest. Keep any
+        // row mid-fade (in `completingIDs`) on screen even though EventKit no
+        // longer returns it as incomplete, so the check-then-fade beat survives a
+        // poll/refresh landing inside the 2s window.
+        let sorted = fetched.sorted {
+            ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
+        }
+        var next = Array(sorted.prefix(Self.maxItems))
+        if !completingIDs.isEmpty {
+            let shown = Set(next.map(\.calendarItemIdentifier))
+            let held = items.filter {
+                completingIDs.contains($0.calendarItemIdentifier)
+                    && !shown.contains($0.calendarItemIdentifier)
+            }
+            next = held + next
+        }
+        items = next
+        loadError = nil
+        log.info("reminders refreshed: \(self.items.count) of list \"\(calendar.title)\"")
+    }
+
+    /// Mark one reminder done via EventKit, then hold it on screen (filled) for
+    /// ~2s before re-reading so it fades like Apple Reminders. On failure, revert
+    /// and surface the error — never claim a success the store disagrees with.
+    func complete(_ reminder: EKReminder) async {
+        let id = reminder.calendarItemIdentifier
+        guard !completingIDs.contains(id) else { return }   // ignore double-taps
+        reminder.isCompleted = true
+        do {
+            try store.save(reminder, commit: true)
+            log.info("reminder completed: \(id)")
+        } catch {
+            reminder.isCompleted = false
+            loadError = "Couldn't complete: \(error.localizedDescription)"
+            log.error("reminder complete failed: \(error.localizedDescription)")
+            return
+        }
+        completingIDs.insert(id)                       // show it filled, keep it visible
+        try? await Task.sleep(nanoseconds: 2_000_000_000)
+        completingIDs.remove(id)
+        await refresh()                                // now let it drop off
+    }
+}
diff --git a/macOS/Apps/Focus5Float/make-app.sh b/macOS/Apps/Focus5Float/make-app.sh
index cbeda77..5d2ceb5 100755
--- a/macOS/Apps/Focus5Float/make-app.sh
+++ b/macOS/Apps/Focus5Float/make-app.sh
@@ -73,6 +73,11 @@ $ICON_KEY
   <key>LSMinimumSystemVersion</key><string>14.0</string>
   <key>LSUIElement</key><true/>
   <key>NSHighResolutionCapable</key><true/>
+  <!-- Apple Reminders bottom panel reads/writes via EventKit. Full-access key is
+       the macOS 14+ requirement; the legacy key is kept for older fallbacks.
+       (Reminders grant only — no Full Disk Access; read-back is via EventKit.) -->
+  <key>NSRemindersFullAccessUsageDescription</key><string>Focus 5 Float shows your most recent Reminders and lets you check them off.</string>
+  <key>NSRemindersUsageDescription</key><string>Focus 5 Float shows your most recent Reminders and lets you check them off.</string>
   <key>NSPrincipalClass</key><string>NSApplication</string>
   <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
 </dict>
diff --git a/src/rebalance/web.py b/src/rebalance/web.py
index 26c25bb..021ca08 100644
--- a/src/rebalance/web.py
+++ b/src/rebalance/web.py
@@ -462,8 +462,14 @@ def _f5_card(card: dict[str, Any]) -> str:
         card.get("repo_full_name") or card.get("local_path") or "", quote=True
     )
     # Top-right action cluster: the standard "Open ↗" button (shared helper, so it
-    # matches the dashboard home) next to the ✕ hide control.
-    open_btn = button_link("Open", vs_href, title="Open repo in VS Code")
+    # matches the dashboard home) next to the ✕ hide control. `data-f5-open` carries
+    # the repo identity so the click JS can POST it to /api/focus5/open (focus-if-
+    # open via the server's `code <folder>`); the vscode:// href stays as the no-JS
+    # / failure fallback so the button is never dead.
+    open_btn = button_link(
+        "Open", vs_href, title="Open repo in VS Code",
+        attrs=f'data-f5-open="{identity}"',
+    )
     hide_btn = (
         f"<button class='f5-hide' data-f5-hide=\"{identity}\" "
         f"title='Hide from Focus 5' aria-label='Hide {name} from Focus 5'>✕</button>"
@@ -473,7 +479,7 @@ def _f5_card(card: dict[str, Any]) -> str:
         f"<div class='f5-card'>"
         f"{actions}"
         f"<div><div class='f5-pos'>#{card['position']}</div>"
-        f"<a class='f5-name' href='{vsurl}' title='Open in VS Code'>{name}</a>"
+        f"<a class='f5-name' href='{vsurl}' title='Open in VS Code' data-f5-open=\"{identity}\">{name}</a>"
         f"<div class='f5-reason'>{reason}{reason_badge}</div></div>"
         f"{_f5_health(card)}{_f5_pr(card)}{_f5_activity(card)}"
         f"</div>"
@@ -522,7 +528,7 @@ def _focus5_body(data: dict[str, Any], *, view: str = "focus5") -> str:
     )
     strip = _f5_warning_strip(data)
     cards = "".join(_f5_card(c) for c in roster)
-    return f"{head}{meta}{strip}<div class='f5-grid'>{cards}</div>{_FOCUS5_HIDE_ASSETS}"
+    return f"{head}{meta}{strip}<div class='f5-grid'>{cards}</div>{_FOCUS5_HIDE_ASSETS}{_FOCUS5_OPEN_ASSETS}"
 
 
 # Scoped CSS + JS for the per-card hide (✕) control. Kept in the Focus 5 body so
@@ -564,6 +570,35 @@ document.addEventListener('click', async (e) => {
 """
 
 
+# Scoped JS for the "Open ↗" focus-if-open action. Any element carrying
+# `data-f5-open="<identity>"` (the Open button AND the repo-name link) POSTs that
+# identity to /api/focus5/open, which runs `code <folder>` server-side so an
+# already-open VS Code window is focused instead of clobbered. On ANY failure
+# (no-JS, server down, `code` missing → 409, unknown id → 404) it falls through to
+# the element's vscode:// href, so the action is never dead.
+_FOCUS5_OPEN_ASSETS = """
+<script>
+document.addEventListener('click', async (e) => {
+  const el = e.target.closest('[data-f5-open]');
+  if (!el) return;
+  const repo = el.getAttribute('data-f5-open');
+  if (!repo) return;
+  e.preventDefault();
+  try {
+    const res = await fetch('/api/focus5/open', {
+      method: 'POST',
+      headers: { 'Content-Type': 'application/json' },
+      body: JSON.stringify({ repo }),
+    });
+    if (res.ok) return;
+  } catch (_) { /* fall through to the vscode:// fallback */ }
+  const href = el.getAttribute('href');
+  if (href && href !== '#') window.location.href = href;
+});
+</script>
+"""
+
+
 def _roster_stale(computed_at: str | None) -> bool:
     """True if the roster snapshot is missing or older than the TTL."""
     if not computed_at:
@@ -740,6 +775,142 @@ def focus5_unhide(req: Focus5HideRequest) -> JSONResponse:
     return JSONResponse(focus5_set_hidden(req.repo, hidden=False))
 
 
+# ---------------------------------------------------------------------------
+# Focus 5 "Open ↗" focus-if-open (VSCODE-OPEN-WORKSPACE Phase 2).
+#
+# The browser can't run `code <folder>`, so the dashboard POSTs a repo IDENTITY
+# here and the local server runs it. The path is NEVER client-supplied: the id is
+# resolved to a local_path from the server's own freshly-summarized roster (the
+# allowlist), unknown ids are rejected (404, logged as a tripwire), and the launch
+# is a direct-argv subprocess (shell=False) so there is no command-injection class.
+# Bound to loopback + same-origin only — this executes a binary, so it refuses any
+# request that isn't from the local dashboard itself.
+# ---------------------------------------------------------------------------
+
+# Same fixed candidate order as the Mac app's VSCodeLauncher (Homebrew arm64 →
+# Intel → app bundle); the order is part of the contract.
+_VSCODE_CODE_CANDIDATES = (
+    "/opt/homebrew/bin/code",
+    "/usr/local/bin/code",
+    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code",
+)
+
+
+def _resolve_code_binary() -> str | None:
+    """Resolve the ``code`` executable: ``VSCODE_BIN`` override → known locations →
+    PATH lookup. Returns None when none is found (caller returns 409)."""
+    import os
+    import shutil
+
+    override = os.environ.get("VSCODE_BIN")
+    if override and os.access(override, os.X_OK):
+        return override
+    for cand in _VSCODE_CODE_CANDIDATES:
+        if os.access(cand, os.X_OK):
+            return cand
+    return shutil.which("code")
+
+
+def _focus5_open_allowlist(db: Path) -> dict[str, str]:
+    """Build ``identity → local_path`` from the server's own roster — the allowlist.
+
+    Unions the default (Focus 5) and dirty (Dirty Five) boards so a card visible in
+    either view resolves. The identity is the same key the card renders
+    (``repo_full_name`` or, lacking a remote, ``local_path``). Only the server's
+    scanned data is trusted; a client-supplied path never reaches the launcher.
+    """
+    from rebalance.ingest.focus5_scan import summarize_focus5
+
+    allow: dict[str, str] = {}
+    for mode in (None, "dirty_first"):
+        try:
+            data = summarize_focus5(db, mode=mode)
+        except Exception:  # noqa: BLE001 — a probe hiccup must not break resolution
+            continue
+        for card in data.get("roster") or []:
+            identity = card.get("repo_full_name") or card.get("local_path")
+            local_path = card.get("local_path")
+            if identity and local_path:
+                allow[identity] = local_path
+    return allow
+
+
+def focus5_open_repo(repo: str) -> tuple[int, dict[str, Any]]:
+    """Resolve *repo* (a card identity) to its local_path via the allowlist and run
+    ``code <local_path>``. Returns ``(http_status, body)``. Never raises."""
+    identity = (repo or "").strip()
+    if not identity:
+        return 400, {"ok": False, "error": "empty repo identity"}
+
+    from rebalance.paths import DatabaseNotFoundError, resolve_database_path
+
+    try:
+        db = resolve_database_path()
+    except DatabaseNotFoundError:
+        return 404, {"ok": False, "error": "no database"}
+
+    local_path = _focus5_open_allowlist(db).get(identity)
+    if not local_path:
+        # Tripwire: a miss means a caller asked for an id the server never issued.
+        logger.warning("focus5 open: allowlist MISS for identity=%r", identity)
+        return 404, {"ok": False, "error": "unknown repo"}
+
+    code_bin = _resolve_code_binary()
+    if not code_bin:
+        logger.info("focus5 open: no `code` binary — client falls back to vscode://")
+        return 409, {"ok": False, "error": "code binary not found"}
+
+    import subprocess
+
+    try:
+        # Direct argv — no shell, no string interpolation. `code <folder>` returns
+        # promptly (it talks to VS Code over IPC); cap it so a hung launch can't pin
+        # the request.
+        proc = subprocess.run(  # noqa: S603 — argv list, allowlisted path, no shell
+            [code_bin, local_path],
+            stdin=subprocess.DEVNULL,
+            capture_output=True,
+            timeout=15,
+        )
+    except Exception as exc:  # noqa: BLE001 — surface as 500, client falls back
+        logger.error("focus5 open: launch failed for %s: %s", local_path, exc)
+        return 500, {"ok": False, "error": "launch failed"}
+
+    logger.info(
+        "focus5 open: identity=%r path=%s bin=%s exit=%s",
+        identity, local_path, code_bin, proc.returncode,
+    )
+    return 200, {"ok": True, "exit_code": proc.returncode}
+
+
+def _request_is_local(request: Request) -> bool:
+    """Same-origin gate for the exec endpoint.
+
+    Network reach is already constrained by the server's loopback bind (serve.py),
+    so the endpoint-level threat is a malicious page CSRF-ing the browser into
+    POSTing here. A cross-origin browser fetch always carries an ``Origin`` header,
+    so we reject any ``Origin`` whose host isn't loopback. A request with no
+    ``Origin`` (curl / a non-browser local tool) is allowed — it's already behind
+    the loopback bind. Returns False to refuse.
+    """
+    from urllib.parse import urlparse
+
+    loopback = {"127.0.0.1", "::1", "localhost"}
+    origin = request.headers.get("origin")
+    if origin and (urlparse(origin).hostname or "") not in loopback:
+        return False
+    return True
+
+
+@app.post("/api/focus5/open")
+def focus5_open(req: Focus5HideRequest, request: Request) -> JSONResponse:
+    if not _request_is_local(request):
+        logger.warning("focus5 open: rejected non-local request from %s", request.client)
+        return JSONResponse({"ok": False, "error": "forbidden"}, status_code=403)
+    status, body = focus5_open_repo(req.repo)
+    return JSONResponse(body, status_code=status)
+
+
 # ---------------------------------------------------------------------------
 # What's Next — the single ranked "what should we work on next" view.
 #
diff --git a/src/rebalance/web_components.py b/src/rebalance/web_components.py
index bdb7fbf..147d1e2 100644
--- a/src/rebalance/web_components.py
+++ b/src/rebalance/web_components.py
@@ -70,6 +70,7 @@ def button_link(
     title: str | None = None,
     arrow: bool = True,
     cls: str = "",
+    attrs: str = "",
 ) -> str:
     """Render the standard ``Label ↗`` button shared across every web page.
 
@@ -80,13 +81,15 @@ def button_link(
     """
     target = ' target="_blank" rel="noopener noreferrer"' if external else ""
     title_attr = f' title="{html.escape(title, quote=True)}"' if title else ""
+    # `attrs` is emitted verbatim (caller-escaped) — used for data-* hooks.
+    extra_attrs = f" {attrs}" if attrs else ""
     arrow_html = (
         ' <span class="rb-btn-arrow" aria-hidden="true">↗</span>' if arrow else ""
     )
     klass = ("rb-btn " + cls).strip()
     return (
         f'<a class="{html.escape(klass, quote=True)}" '
-        f'href="{html.escape(href, quote=True)}"{target}{title_attr}>'
+        f'href="{html.escape(href, quote=True)}"{target}{title_attr}{extra_attrs}>'
         f"{html.escape(label)}{arrow_html}</a>"
     )
 
diff --git a/tests/test_focus5_scan.py b/tests/test_focus5_scan.py
index 7ab8924..37d232b 100644
--- a/tests/test_focus5_scan.py
+++ b/tests/test_focus5_scan.py
@@ -942,6 +942,80 @@ class WebRouteTests(unittest.TestCase):
             self.assertEqual(resp.headers["location"], "/focus-5")
             self.assertTrue(m.called)                        # recompute fired
 
+    # --- /api/focus5/open — focus-if-open exec endpoint (VSCODE Phase 2) ---
+
+    def _post_open(self, db: Path, payload: dict, **kw):
+        from fastapi.testclient import TestClient
+        from rebalance.web import app
+        os.environ["REBALANCE_DB"] = str(db)
+        try:
+            return TestClient(app).post("/api/focus5/open", json=payload, **kw)
+        finally:
+            os.environ.pop("REBALANCE_DB", None)
+
+    def test_open_allowlist_resolves_known_and_rejects_unknown(self) -> None:
+        # The resolver runs the REAL summarize over the seeded temp repo (no mocks):
+        # a known id maps to a server-owned local_path; an unknown id is absent.
+        with tempfile.TemporaryDirectory() as tmp:
+            db, _ = self._seed(Path(tmp))
+            from rebalance import web
+            os.environ["REBALANCE_DB"] = str(db)
+            try:
+                allow = web._focus5_open_allowlist(db)
+            finally:
+                os.environ.pop("REBALANCE_DB", None)
+            self.assertTrue(allow, "seeded roster should resolve at least one repo")
+            _identity, local_path = next(iter(allow.items()))
+            self.assertTrue(os.path.isdir(local_path))     # a real, server-owned path
+            self.assertNotIn("no/such-repo", allow)        # unknown id not in allowlist
+
+    def test_open_known_repo_runs_code_with_server_path(self) -> None:
+        # Known id → the launcher runs `code <server_path>` as a direct argv (no
+        # shell). Allowlist mocked so no git/subprocess from the resolver collides.
+        with tempfile.TemporaryDirectory() as tmp:
+            db, _ = self._seed(Path(tmp))
+            fake = mock.Mock(returncode=0)
+            with mock.patch("rebalance.web._focus5_open_allowlist",
+                            return_value={"demo/repo": "/repos/demo"}), \
+                 mock.patch("rebalance.web._resolve_code_binary", return_value="/usr/bin/code"), \
+                 mock.patch("subprocess.run", return_value=fake) as run:
+                resp = self._post_open(db, {"repo": "demo/repo"})
+            self.assertEqual(resp.status_code, 200)
+            self.assertTrue(resp.json()["ok"])
+            run.assert_called_once()
+            self.assertEqual(run.call_args.args[0], ["/usr/bin/code", "/repos/demo"])
+
+    def test_open_unknown_repo_is_404_and_runs_nothing(self) -> None:
+        with tempfile.TemporaryDirectory() as tmp:
+            db, _ = self._seed(Path(tmp))
+            with mock.patch("rebalance.web._focus5_open_allowlist",
+                            return_value={"demo/repo": "/repos/demo"}), \
+                 mock.patch("rebalance.web._resolve_code_binary", return_value="/usr/bin/code"), \
+                 mock.patch("subprocess.run") as run:
+                resp = self._post_open(db, {"repo": "no/such-repo"})
+            self.assertEqual(resp.status_code, 404)
+            run.assert_not_called()
+
+    def test_open_missing_code_binary_is_409(self) -> None:
+        with tempfile.TemporaryDirectory() as tmp:
+            db, _ = self._seed(Path(tmp))
+            with mock.patch("rebalance.web._focus5_open_allowlist",
+                            return_value={"demo/repo": "/repos/demo"}), \
+                 mock.patch("rebalance.web._resolve_code_binary", return_value=None):
+                resp = self._post_open(db, {"repo": "demo/repo"})
+            self.assertEqual(resp.status_code, 409)   # client falls back to vscode://
+
+    def test_open_cross_origin_is_403_and_runs_nothing(self) -> None:
+        with tempfile.TemporaryDirectory() as tmp:
+            db, _ = self._seed(Path(tmp))
+            with mock.patch("subprocess.run") as run:
+                resp = self._post_open(
+                    db, {"repo": "anything"},
+                    headers={"origin": "http://evil.example"},
+                )
+            self.assertEqual(resp.status_code, 403)
+            run.assert_not_called()
+
     def test_dirty_view_renders_transiently_without_resync(self) -> None:
         # /focus-5?view=dirty re-ranks the cached signals under dirty_first; a
         # fresh roster means no ~30s scan, and the persisted roster is untouched.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Reviewer ([agy](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-system/2026-06-29/qa-focus5-reminders-web-vscode.md))

#### Verdict: Changes requested

#### Findings
- **Finding 1 (Security Gap / Loopback Client Host Check)**
  - **Grade:** `[Should]`
  - **Reason:** In [web.py](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/src/rebalance/web.py#L709-L726) -> `_request_is_local(request)`, dropping the client-host loopback check (`request.client.host in loopback`) introduces a security gap if the user binds the server to a non-loopback interface (e.g., `0.0.0.0`). A remote client on the local network could bypass the `Origin` check by sending a POST request without an `Origin` header (e.g. via `curl`), allowing them to launch arbitrary VS Code workspaces on the host machine.
  - **Concrete Fix:** Add a defense-in-depth client host check in `_request_is_local` to verify the client IP is loopback:
    ```python
    def _request_is_local(request: Request) -> bool:
        loopback = {"127.0.0.1", "::1", "localhost"}
        # Defense-in-depth: check client host first
        if not request.client or request.client.host not in {"127.0.0.1", "::1"}:
            return False
        origin = request.headers.get("origin")
        if origin and (urlparse(origin).hostname or "") not in loopback:
            return False
        return True
    ```
- **Finding 2 (Executable Validation Check)**
  - **Grade:** `[Nit]`
  - **Reason:** In [web.py](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/src/rebalance/web.py#L622-L634) -> `_resolve_code_binary()`, checking `os.access(override, os.X_OK)` is insufficient if `override` is a directory (since directories often have execute permissions for traversal). This could result in trying to run a directory and raising an `IsADirectoryError`/`PermissionError`.
  - **Concrete Fix:** Check `os.path.isfile(override)` in addition to `os.access`:
    ```python
    if override and os.path.isfile(override) and os.access(override, os.X_OK):
        return override
    ```
- **Finding 3 (EventKit Authorization Mapping)**
  - **Grade:** `[Pass]`
  - **Reason:** [RemindersStore.swift](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/macOS/Apps/Focus5Float/Sources/Focus5Float/RemindersStore.swift#L415-L426) correctly maps `.writeOnly` and `.restricted` EventKit statuses to `.denied`, since the bottom panel needs read-back permission to render the reminders list.
- **Finding 4 (Double-Tap Protection)**
  - **Grade:** `[Pass]`
  - **Reason:** The double-tap protection `guard !completingIDs.contains(id)` and the immediate disabling of the checkbox button in `ReminderRow` work correctly to prevent race conditions during the 2-second fade-out transition.
- **Finding 5 (HTML/XSS Injection Safety)**
  - **Grade:** `[Pass]`
  - **Reason:** The `identity` attribute is HTML-escaped at the call sites before being passed into the unescaped `attrs` of `button_link` and `data-f5-open`, preventing XSS vulnerability.
- **Finding 6 (JS Fallback & HTTP Status Codes)**
  - **Grade:** `[Pass]`
  - **Reason:** The click event listener properly intercepts the element with `data-f5-open` and falls back to the `vscode://` URL on any HTTP error (404, 409, 403, etc.) or network exception, making it highly robust.

### Round 1 — Producer ([claude-a](file:///Users/noelsaw/Documents/rebalance-OS))

#### Dispositions
- **Finding 1 (loopback client-host check) `[Should]` — Implemented.** Restored a client-host
  loopback check as **layer 1** (defense-in-depth) ahead of the same-origin check, since
  `rebalance serve` can bind a non-loopback host. A non-loopback client is now refused even with no
  `Origin` header — closing the LAN/`curl` gap. Final `_request_is_local` (`src/rebalance/web.py`):
  ```python
  loopback = {"127.0.0.1", "::1", "localhost"}
  client_host = (request.client.host if request.client else "") or ""
  if client_host not in loopback:
      return False
  origin = request.headers.get("origin")
  if origin and (urlparse(origin).hostname or "") not in loopback:
      return False
  return True
  ```
- **Finding 2 (`_resolve_code_binary` accepts a directory) `[Nit]` — Implemented.** Added
  `os.path.isfile(...)` ahead of `os.access(.., X_OK)` for the `VSCODE_BIN` override **and** each fixed
  candidate, so a path that is a directory (X_OK true for traversal) is never returned as the launcher.
- **Findings 3–6 `[Pass]` — acknowledged**, no change (EventKit auth mapping, 2s-fade double-tap guard,
  call-site HTML-escape of `identity`, JS `vscode://` fallback).

#### Verification
- Test reconciliation (the restored guard 403s a TestClient POST since its client host isn't loopback):
  the 3 launch/allowlist route tests now `mock.patch("rebalance.web._request_is_local", True)` (they
  exercise launch logic, not the gate); the cross-origin case became `test_open_non_local_request_is_403`;
  added **`test_request_is_local_guard`** (fake-request unit: loopback+no-origin allowed · same-origin
  allowed · cross-origin refused · non-loopback refused even w/o Origin · missing client refused) and
  **`test_resolve_code_binary_rejects_directory`**.
- `pytest tests/test_focus5_scan.py` → **91 passed**.

Handing back to agy to re-review the two fixes.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
