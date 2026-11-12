# GH-1436 / GH-1437 focused verification

Source: bf38b326; Python 3.13.15 with yaml/pytest/requests; separate disposable full clone.

Eight existing suites passed: marathon-plan (70 passed, 2 explicit legacy parity skips), swarm-preflight, HQ park and synthesis, wave-reconcile and GH-168 scope, GH-251, GH-732 summary. No new suites or registry entries.

Manual matrix: 20 contract cases; invalid outer values, target string/list/null/ref-list, probe container/entry/operand types, artifact container/entry types and lanes types. Every malformed row is held, including unregistered discovery; the real reconciliation result handler accepts unrelated identity and refuses the owned identity. Healthy, partial, and optional-null markers retain behavior; partial execution contract still refuses via extract_contract.

HQ: six malformed contracts refuse before any issue-create stub or capture write; partial contract preview remains accepted. Environment: missing yaml, pytest or requests and a simulated older interpreter exit 3 before a suite sentinel; healthy environment reaches it. The real Apple Python 3.9.6 entry path also exits 3 with the exact PATH remedy.

Red controls at 1a1a636d: same string target crashes planner with AttributeError; old extracted environment block prints warning and returns zero under Apple Python 3.9.6. Helper import red is additionally retained. Extraction was nonempty; green scripts assert nonempty outputs and observed exit codes.

Scripts retained here are manual evidence, not registered suites. Commands originally ran from the gate clone root with scripts under temp/. No claims of full-gate or hosted success yet.

Final independent QA Approved at 9c506687 after the retained HQ parser and optional-null merge repairs. A concurrent unrelated development landing (#1434, board_sync) was integrated by the existing merge-cleanup ledger resolver at 0ca9aa15: preview proved disjoint rows, kept the higher-generation task side, replayed GH-1430 through roadmap verbs, preserved both CHANGELOG additions, and ran releases-merge-resolve successfully. Peer code and #1438 README section remain intact. Generated LEADERBOARD changes are excluded by task-branch policy. The integrated state requires fresh full qualification after the first in-flight push gate completes.

First full push qualification at 8d0f73af failed honestly: 407/408, sole gh139 quiet-grep inventory failure; push refused after 534 seconds. The retained log includes successful clone identity invariant. Seven test assertions were mechanically changed from printf pipelines to equivalent grep here-strings (84728877), outer-reviewed by the supervising agent with unchanged predicates and nonempty/rc checks; the obsolete three-site baseline row was removed (c48c940c). Fresh gh251 and gh139 rechecks passed. No production change followed independent final approval. Integrated full qualification at c48c940c is pending.
