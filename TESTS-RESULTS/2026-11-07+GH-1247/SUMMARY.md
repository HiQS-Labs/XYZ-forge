# GH-1247 / GH-1362 verification

Base: `3bf02f73ce0cb11a82f970357209980f808ccb3c`. Candidate: `50c63255f32a6a4f5195cb82379dfec86c1d4a99`.

The manual probe exercises the actual ref classifier and claim inspector against disposable Git repositories. Base observations are in baseline.log; candidate.log records fixed main paths and adjacent negative paths. Remote matching lightweight and annotated tags pass, while local-only/differing tags and failed remote queries preserve. A deployed scanner resolves explicit/configured harnesses; idle claims verify, active claims stay active, absent/broken lookup stays unverified, and foreign configured origin is rejected. Git/claims fixtures are disclosed in the probe and provenance; this does not claim live retirement of a user checkout.

Existing `test/gh436-merge-cleanup.sh` passed on the candidate in a separate full clone. Its fixture paths are redacted in gh436.log. Repository identity remained unchanged. An earlier baseline-suite attempt overlapped a checkout change and is excluded from evidence.

Final independent review Approved (relay-system/2026-11-07/gh1247-final.codex.md); full classified push gate passed on 5d7edd631138bd4fc4b30c610cd66afcc0d9067f in 660 seconds, with stable clone identity. Documentation closeout follows without production changes. Live issue bodies for #1247/#1362/#1359 were re-read successfully by the producer on 2026-11-07, confirming the scoped acceptance and research-only boundary. The classifier selected tier 3 for the scanner change. No new suite, test registry entry or gate was added. `manual-probe.py` is a retained manual reproduction artifact.

Lessons decision: NO_ENTRY. Tag identity and deployed lookup each helped in controlled reproductions, but this task adds no broadly new operating lesson beyond the existing preservation contract.
