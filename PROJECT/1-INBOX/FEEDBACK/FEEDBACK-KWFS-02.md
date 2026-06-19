Feedback for the XYZ repo maintainer (from a first-time external consumer)
Context: I drove this relay against a different repo than where the tooling lives. That cross-repo path is where almost all the friction was. The containment core itself was excellent.

A. The builder instructions (the prompt handed to the consumer)
"this repo's turn-taker shim" is the single biggest wrong assumption. The tooling was not in the consuming repo, and there was no fallback step. I only found it because the user's tool-rejection happened to contain the xyz-3-agents-swarm path. The instructions need an explicit precondition/bootstrap block: "The shim+tick live in xyz-3-agents-swarm. They are NOT self-contained — bin/tick requires xyz/src/, so you cannot copy bin/tick alone. Either run from the xyz checkout, or vendor relay-automation/ + bin/tick + src/."

The cross-repo env contract is undocumented and non-obvious. I had to derive that, to review code in repo B while tooling lives in repo A, you must: run with CWD = tooling repo (so ./bin/tick and its src/ resolve), set AGY_TURN_ROOT=B and TICK_REPO_ROOT=B, put REL inside B, and — the sharp one — list TARGET files by absolute path, because agy's CWD is the tooling repo, so relative reads resolve against the wrong tree. None of that is in the instructions; all of it is load-bearing. Add a "Cross-repo mode" subsection with that exact recipe.

The PONG preflight is missing the sandbox caveat. The instructions say run agy -p "Reply with exactly: PONG", but that check itself fails empty under a sandbox — so a consumer who runs it in their default (sandboxed) shell sees the failure and concludes agy is broken. Say "run the PONG check sandbox-OFF too."

.tick/ pollution isn't called out. Seeding the token creates an untracked .tick/ in the target repo; I had to add a gitignore line. The instructions should tell the consumer to gitignore .tick/ (or note that the tooling will).

B. The scripts themselves (relay-automation/ + bin/tick)
What's genuinely good — keep it:

agy-turn.sh header gotchas (a) silent-empty-under-sandbox → exit 5, and (b) cost-blind, were accurate and saved me real debugging. Containment behaved exactly as documented: off-lane reverts, commit-bypass guard, file-scoped commit, no push. Both agy turns exited clean.
The honesty in relay-turn-lib.sh (field-report citations, the documented setsid/process-group kill gap, rename-hijack handling) is excellent — I trusted it because it disclosed its own edges.
What to add/fix, prioritized:

Ship a documented cross-repo "consumer mode." Right now AGY_TURN_ROOT is described as "tests point at a fixture" — but the real second use case is production cross-repo review. Either a thin relay-drive-external.sh --target-repo <path> --rel <path> wrapper, or a CONSUMING.md, that encodes the recipe from A2. This is the one change that would've cut my setup time most.

Guard the absolute-path footgun. Add a preflight in the shim: if AGY_TURN_ROOT != git-root-of-CWD and any TARGET path in the REL is relative, warn loudly ("agy reads relative to CWD, not AGY_TURN_ROOT — use absolute TARGET paths"). This failure is silent today (agy would just "find nothing").

Fail fast on sandbox, don't just detect after. The empty-output→exit-5 detection is post-hoc (after a full turn timeout in the worst case). A cheap pre-run reachability probe to agy's backend would fail in seconds with "looks sandboxed" instead of burning a turn.

tick analyze/cost surface should self-label the agy lane as cost-blind. It silently shows nothing for agy turns; a consumer reading a cost report can't tell "zero" from "not captured." One printed line would fix it.

Minor: the shim commits into the target product repo's history with a generic message. For a consumer reviewing a real product repo, interleaved relay(RELAY-TURN): agy turn commits may be unwanted. A --no-commit (stage-and-leave) mode would let the consumer squash/control history.

Net: the containment and turn-token model are production-quality; the gap is entirely in documenting and tooling the cross-repo consumer path, which today is tribal knowledge a first-timer has to reverse-engineer.
