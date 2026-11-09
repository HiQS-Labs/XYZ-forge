# GH-1383 takeover qualification

Source baseline476400948, operator ownership transfer after MBP release. Existing gh436 suite controls:5baselinefailures, repaired8selectedpass. First broad run221/223 retained; repaired path-alias assertion and narrowly handled macOS zombie-only killpgEPERM. Independent static final QA and fresh platform recheck PASS; receipt relay-system/2026-11-09/gh1383-takeover-final.codex.md. Broader rerun/fullgate pending.

Reviewed PR1384 runtime/test preservation patch integrated before first landing/deployment. No source branches or helper clones deleted. Temporary paths in logs name disposable fixtures; no secrets captured. No batch performance claim from tests. Clone bound180s adds to canary300s/sweep900s command limits.
