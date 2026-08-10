# XYZ Cockpit — Installation & Setup

End-user steps for running the XYZ Cockpit alpha, in the order they actually get used. See
[README.md](README.md) for what the extension does and does not do.

There are two ways to run it:

- **A. Development mode (F5)** — fastest to try, but only runs in a temporary window and needs to
  be relaunched every time.
- **B. Permanent install (VSIX)** — installs into your normal VS Code so the icon is always there.
  Requires a manual reinstall after any source change.

Do A first to confirm it works, then B if you want it to stick around.

---

## 0. Prerequisites

Dependencies are not committed to git (`node_modules/` is gitignored), so every fresh checkout —
including a second worktree or a freshly pulled clone — needs its own install:

```bash
cd tools/vscode-cockpit
npm install
```

If you ever see `sh: tsc: command not found` when launching, this step was skipped or ran in the
wrong folder. Re-run it here and retry.

---

## A. Development mode (F5)

1. **File → Open Folder…** and select `tools/vscode-cockpit` **itself** — not the repo root, and
   not a parent folder. VS Code only discovers `.vscode/launch.json` at the root of the folder
   that's open, so opening the wrong level means Run and Debug won't show a launch config at all.
2. Open the **Run and Debug** panel (bug-with-play-button icon in the Activity Bar, or
   `Cmd+Shift+D`).
3. Confirm the dropdown at the top reads **"Run XYZ Cockpit Extension"**, then press the green ▷
   (or just press **F5**).
   - If that config isn't in the dropdown, step 1 didn't land on the right folder — go back and
     re-open exactly `tools/vscode-cockpit`.
4. A **second, new VS Code window** opens, titled `[Extension Development Host]` in its title bar.
   That title is the confirmation you're in the right window — the extension does not appear in
   the original window at all.
5. In that new window, open a folder with real data to look at — e.g. the root of this repo — then
   look for the XYZ Cockpit icon in **that window's** Activity Bar.

**If you get a "preLaunchTask 'npm: compile' terminated with exit code 127" dialog:** that's step 0
not having been done yet in this checkout. Run `npm install` in `tools/vscode-cockpit`, then choose
**Debug Anyway** or press F5 again.

---

## B. Permanent install (VSIX)

This packages the extension and installs it like any marketplace extension, so it survives across
windows and restarts without needing F5.

1. From `tools/vscode-cockpit`, package it:

   ```bash
   npm run compile
   npx @vscode/vsce package --allow-missing-repository
   ```

   This produces `xyz-cockpit-0.1.0.vsix` in the same folder. (`--allow-missing-repository` and the
   missing-LICENSE warning are expected and harmless — this isn't being published anywhere.)

2. In VS Code: `Cmd+Shift+P` → **"Extensions: Install from VSIX..."**
3. Pick the `xyz-cockpit-0.1.0.vsix` file just built.
4. Reload the window when prompted.
5. The XYZ Cockpit icon now appears permanently in the Activity Bar, in every window — no F5
   needed.

**This install is static.** If the extension's source changes later (a new data source, a UI
tweak), that change is invisible to an already-installed VSIX. Re-run step 1 to rebuild the `.vsix`
with the new code, then repeat steps 2–4 to reinstall it. Development mode (A) always reflects the
current source with no rebuild step, which is why it's the faster loop while actively changing
something.

---

## Troubleshooting reference

| Symptom | Cause | Fix |
|---|---|---|
| Extensions sidebar (marketplace list) doesn't show XYZ Cockpit | That panel only lists marketplace/VSIX-installed extensions. A dev-mode (F5) run never appears there — it only exists in the Extension Development Host window. | Use method A and look in the *new* window, or install via method B. |
| Run and Debug has no "Run XYZ Cockpit Extension" entry | Wrong folder opened as workspace root. | Re-open exactly `tools/vscode-cockpit`, not a parent folder. |
| `sh: tsc: command not found` | `node_modules/` missing in this checkout (gitignored, not carried by git operations). | `npm install` in `tools/vscode-cockpit`. |
| Cockpit view is empty on real data | Not yet observed in practice — file an issue against GH-480 if it happens, with which folder was open. | — |
