# GH-854 integration QA

The first read-only Codex review found a missing GH-920 `rated` event and a generated `LEADERBOARD.md` change. The final-base merge replayed the event through the releases writer and left the view at development’s version. A second independent read-only review passed at `8ac9880f`. Both receipts are committed under `relay-system/2026-10-02/`; the first failure is retained.
