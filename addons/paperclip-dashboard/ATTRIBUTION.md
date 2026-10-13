# Attribution

This optional design spike draws from [Paperclip](https://github.com/paperclipai/paperclip), through [noelsaw1/paperclip-fork](https://github.com/noelsaw1/paperclip-fork) at **90182b4f8b40d6ee217937ba61199b4abc31dee7**.

Copyright (c) 2025 Paperclip AI. The upstream MIT notice is retained verbatim in [LICENSE.paperclip](LICENSE.paperclip).

| Reference at pinned revision | Adaptation here |
|---|---|
| [Dashboard.tsx](https://github.com/noelsaw1/paperclip-fork/blob/90182b4f8b40d6ee217937ba61199b4abc31dee7/ui/src/pages/Dashboard.tsx) | Summary cards, agent observations and recent activity arranged as an operator overview |
| [SidebarShell.tsx](https://github.com/noelsaw1/paperclip-fork/blob/90182b4f8b40d6ee217937ba61199b4abc31dee7/ui/src/components/SidebarShell.tsx) | Workspace rail and collapsible navigation |
| [MetricCard.tsx](https://github.com/noelsaw1/paperclip-fork/blob/90182b4f8b40d6ee217937ba61199b4abc31dee7/ui/src/components/MetricCard.tsx) | Bordered cards with a label, value and supporting text |
| [FilterBar.tsx](https://github.com/noelsaw1/paperclip-fork/blob/90182b4f8b40d6ee217937ba61199b4abc31dee7/ui/src/components/FilterBar.tsx) | Compact view controls and search |
| [EmptyState.tsx](https://github.com/noelsaw1/paperclip-fork/blob/90182b4f8b40d6ee217937ba61199b4abc31dee7/ui/src/components/EmptyState.tsx) | Clear empty-state presentation |

`index.html`, `app.css` and `app.js` are a native HTML/CSS/JavaScript interpretation of these presentation patterns. No upstream React component, server, dependency manifest, branding asset or font is imported. The palette, SVG shapes, contextual detail panel, synthetic records and preview launcher are authored for this spike. XYZ-specific data and status logic reuse the existing Flightdeck modules; original XYZ additions follow the repository license. This experiment is not affiliated with or endorsed by Paperclip AI.

Keep this attribution and MIT notice with any retained or redistributed adaptation.
