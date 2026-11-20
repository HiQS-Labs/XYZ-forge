# Case RAW — #1517 medium research → isolated capture → isolated pickup

Disposition: **prepared locally in isolated trial state — not published, not integration-ready.** State per Conveyor handoff vocabulary: short of `prepared — awaiting publication/merge` (no preparation PR exists; Step 5 preflight and Step 6 review not run).

| Step | What ran | Result |
| --- | --- | --- |
| Intake | `gh issue view 1517`; branch `roadmap list --json`; `git ls-files PROJECT` | Open, 0 comments, no row, no capture, no contract → RAW accepted |
| Selection | `00-selection-note.md` frozen 19:08Z before research, deadline 19:50:24Z, 1 research attempt | Recorded before launch |
| Research | 1 read-only Claude `Explore` child (subscription) | Returned SHA-pinned receipt (`research-receipt.md`), no writes; budget now 0 |
| Capture | Parent wrote `isolated-root/PROJECT/1-INBOX/GH-1517-MERGE-CLEANUP-SWEEP-WORDING.md` | Issue body untouched; contract via existing schema |
| Parser + Jog linter | `extract_contract` + `contract_probes_from_doc` from evidence clone `utils/py`, bytecode off | keys `artifacts,fix_probes,gate,remediation,target`; labels `['grep_present:skills/2-daily/merge-cleanup/SKILL.md']`; reason `None` (`parser-polarity.out`) |
| Polarity | Regex on branch SKILL.md, live `6000f3de` SKILL.md, and a simulated reworded copy in memory | branch 1 match (unfixed), live 1 match (unfixed), simulated fix 0 (landed) |
| PRS writer | `releases_app.py --root isolated-root roadmap pickup … --rated 30/30/50/90 --dry-run`, then without `--dry-run`; `roadmap list --json`; `check` | dry-run rc0 (db hash unchanged `b0a4f7b4…`); pickup rc0 `added roadmap entry rmi-01M7NERCQV784J7A707AZP7ZGZ`; read-back 30/30/50/90 ovr null, exact URL and doc; `check: clean (0 failures, 11 warning(s))`; isolated db `205eb851…`; evidence clone db still `b0a4f7b4…` |

Interventions: isolated root needed a git repo (`refused: rule=not-a-git-repo … (GH-448)`); routine repair 1 of 3: `git init` in the scratch isolated root (not a Forge clone). The isolated row points to a capture that exists in that isolated root only; it is not a canonical row.

Not done (needs parent): Step 5 `swarm-preflight.sh --dry-run` in a separate disposable full clone; Step 6 independent preparation QA, publication, canonical pickup on the real ledger, readiness label. Gate is full route (`ci-route`: `docs_only=true full_required=true route=full`), so a docs-only lane claim would be wrong.

Open unknowns from research: lines 418-422 / 463-464 manual exit-4 text; #1516's `merge_cleanup.py` hunks and its `releases.*` landing conflict.
