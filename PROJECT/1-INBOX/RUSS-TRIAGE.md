Subject: XYZ-forge — notes from a full read

To: Noel and team · From: Russ · Date: 2026-09-02
Reviewed at: HiQS-Labs/XYZ-forge, branch development @ 0f62aa4a.

Source card: RESULT-20260822-000011-noel_feedback_doc_v1
Source URL: <local server url redacted>
Card metadata: Result · Active · Created Aug 22, 2026, 9:42 AM · Updated Sep 2, 2026, 12:16 PM · Ontology: mydarium, runtime, assay

Apologies for the delay — I read this properly back on 22 August and then sat on it longer than I meant to. Rather than send stale notes, I re-checked every line against today's HEAD before sending. That turned out to be 688 commits later, and I've marked anything the re-check changed.

How this was made

Worth being explicit, since you'll recognise the shape: this is agent-generated under my direction, not a hand-read. I put it through the pipeline I use for external material — decompose the subject into dimensions, dispatch parallel readers, grade every claim by evidence level, then run the whole thing past a different vendor adversarially before I'd let myself believe it.

Concretely: the primary evaluator was Claude (Fable 5), and the adversarial pass was Codex (gpt-5.6-terra) — deliberately a different vendor, so the challenge isn't the same model marking its own work. Under the evaluator, two readers worked in parallel: one on your dispatch mechanics (from the Python twins, per your GH-308 note), one on mine for comparison. Between them they covered the kernel (bin/tick, src/), relay-automation/, the principles/AGENTS/ROUTER/PDDA set, and the launch tooling.

Being precise about who checked what, because it changes how much weight to put on it: I took the consensus of the two readers. I did not personally re-read every line. The evaluator re-verified a named subset of the load-bearing claims — the ones the findings actually rest on — and the Codex pass independently re-checked the Tier-A items. So the chain is reader → evaluator → adversarial challenge → me, and I'm the last link, not the verification layer.

Everything is graded by how it was established — E1 (ran it), E2 (read the code), E3 (docs only). Nothing below is E3. The E1 work was npm run test:unit (11/11 green) plus scratch-repo experiments against tick: claim, overlap, reap, reclaim, zombie replay, concurrent claims. All in throwaway directories; nothing touched your live repo.

Then the package went to Codex as an adversarial challenge before you saw it. It came back REVISE and corrected me on four counts — the shim count, a URL count, the commit figure, and one severity grade. What you're reading is the corrected version. Two classes of thing didn't survive that process and so aren't here: anything I couldn't pin to a file and line, and anything that was really a difference of architecture rather than a defect.

Two honest caveats. The re-check this week was a read, not a re-run — the reproductions in 1.3 and 3.1 are from August, and while the code they describe hasn't changed, I haven't re-executed them. And the failure mode of this whole method is a confident wrong claim with a citation attached. If you hit one, that's mine, not the tooling's — tell me and I'll withdraw it.

Grading uses your own [Should] / [Nit] vocabulary. Nothing here is a [Blocker] in your sense. The harness works, and section 4 is the part I'd keep exactly as it is.

One thing worth saying up front. Your §13 now calls out two anti-patterns it didn't carry in August: "a check that validates the artifact it just generated (#351)" and "a parity check that compares a lane to itself (#348)". Two of my findings below (1.2 and 1.4) are that same shape — a check that can't falsify its claim because it never runs on the path it's supposed to govern. You got there independently on your own gates; these are two more instances of it.

------------------------------------------------------------------------

1. Bugs and mismatches (ranked)

1.1 [Should] The launch-artifact marker in the live public repo authorises a destructive rebuild

.xyz-launch-artifact is still sitting in the public repo root, and it says: "The presence of this file authorises the build script to clear this directory on the next run."

In utils/build-launch-artifact.sh, the stated safety rule (:32-38) accepts "a previous artifact, proven by the marker file this script writes" as a valid destination. The marker test at :155 is reached before the refusal at :164. Then :192 clears the directory (find "$DEST_NORM" -mindepth 1 -maxdepth 1 -exec rm -rf {} +), and :324-338 does git init plus one commit.

So a fresh gh repo clone HiQS-Labs/XYZ-forge qualifies as "a previous artifact, safe to rebuild". Run the private repo's copy of the script against that clone and the clone and its history are gone locally. A force-push afterwards would replace the public history — which is now well past 400 commits on development with several non-owner authors.

To be fair to it: the script never pushes. This is a two-step footgun, not a one-step one. But the header still says it's "meant to be re-run freely", and that's the sentence I'd change first.

Suggest: drop the marker from the public repo (it's the source of record now, not a build output), or rewrite it as provenance-only. And have the script refuse a destination with more than one commit, or any commit not authored "XYZ", unless you pass an explicit --discard-history.

Re-check note: this file changed since August, but only for the GH-204 redaction portability work. The ordering is untouched.

1.2 [Should] The structural block validator is off the headless path

§12 names bin/validate-relay-block (GH-21 Phase 1) as the separated-grading check "before the lock releases".

bin/tick resolves that validator at :256 and :281, but only on the --relay-file path (usage at :101/:103, exit 8 documented at :120).

The handoff backstop in rtl_enforce calls tick done "$task" --agent "$agent" (~~:1433) and tick release "$task" --agent "$agent" --to "$_peer" (~~:1443). --relay-file doesn't appear anywhere in relay-turn-lib.sh — I grepped the whole file. I found no harness-side invocation in relay-turn-lib.sh, utils/py/rtl.py, relay_drive.py or marathon_drive.py either (relay_drive's own --relay-file is a different argument). The turn prompt tells the agent to release --to <peer> / done without the flag.

Net: on the driven path the only mechanical check on a review block is the uncited-claim downgrade, which by its own comment checks absence rather than accuracy. The STATUS/VERDICT/Basis structure is validated only when the model volunteers the flag.

Suggest: pass --relay-file from the backstop and decide what exit 8 means there — escalate, I'd think, rather than proceed. Or move the structural check into rtl_enforce before staging.

Re-check note, and the reason I kept this at the top: those two calls were edited since August — they gained TICK_REPO_ROOT pinning. So this isn't code nobody has looked at recently; the flag just didn't come along with it.

1.3 [Should] tick log — the verb that seeds every run — is exempt from the foreign-cwd guard

bin/tick:37-39: MUTATING_GUARD_VERBS covers claim/take/scope/release/break/done/ping/reap. log is deliberately outside it, and the comment now says why: "Best-effort cost/log are intentionally left out so a turn's auxiliary cost capture never hard-fails on this."

That reasoning is sound for cost. The problem is that assertResolvedRoot returns early for any verb outside the set (:42), and appendEvent in src/events.js calls ensureEventsDir, which creates .tick/events wherever the root resolved — and tick log task.created is how every run gets seeded.

Repro from August (cwd = plain dir, no git, no .tick, TICK_REPO_ROOT unset):

- tick claim T1 --agent s --paths 'x/**' → refused, rc 1. Guard works.
- tick log task.created T9 --agent s --paths 'x/**' → rc 0, and <cwd>/.tick/events/...jsonl now exists.
- Same log with TICK_REPO_ROOT pinned → rc 0, event only in the intended root.

This is the GH-12 shape, on the verb that starts every run. Your driven path is protected because it pins TICK_REPO_ROOT; the exposed path is the operator one in the README. relay_drive.py already names the resulting symptom ("not found in the resolved tick log").

Suggest: guard log for task.* types and keep cost.* best-effort. That keeps the property the exemption exists to protect — task.* isn't cost capture.

1.4 [Should] The skill-first guard hook matches six filenames; six shims and the default Python lane go around it

§4 says: "The PreToolUse guard (relay-automation/hooks/relay-xyz-guard.sh) enforces this by blocking driver calls before the skill loads."

relay-xyz-guard.sh:105-111 blocks exactly six: relay-drive.sh, marathon-drive.sh, marathon.sh, poll.sh, codex-turn.sh, agy-turn.sh.

The tree ships eight relay-automation/*-turn.sh shims. Matched: codex, agy. Not matched: claude-turn.sh, aider-turn.sh, pi-turn.sh, deepseek-turn.sh, commandcode-turn.sh, smallcode-turn.sh. Also unmatched: relay-loop.sh, runner.sh, consult.sh, and any direct python3 utils/py/relay_drive.py | marathon_drive.py | poll.py — which per AGENTS.md is the authoritative runtime now.

Mitigation you already have: the Bash shims exec the Python twins, so the common path is guarded. The bypass is direct Python, or an unlisted shim.

Suggest: match relay-automation/*-turn.sh as a glob plus utils/py/(relay_drive|marathon_drive|poll)\.py. And then the §13 test — enumerate every driver entrypoint and assert the hook blocks each one, so the next shim can't quietly land outside it.

Re-check note: this hook is byte-identical to August, and the shim count is still eight.

1.5 [Nit] Kernel code points at two ADRs that aren't in the public tree

src/events.js:5-8 cites decisions/2026-06-18-epoch-fencing.md and src/project.js:55-60 cites decisions/2026-07-01-cross-agent-dep-conflict.md. decisions/ in the public repo holds exactly one file, 2026-08-10-marathon-gate-baseline-strategy.md.

Looks like build-launch-artifact.sh drops decisions and rescues only the file a shipped test reads. These two are the rationale for load-bearing kernel behaviour — epoch fencing especially — so I'd add them to KEEP_FILES.

1.6 [Nit] Docs drift, two small ones

README → PROJECT/4-MISC/ at :71, :569 and :570. The bucket isn't in the public repo — PROJECT/ has 1-INBOX, 2-WORKING, 3-COMPLETED and the loose docs, no 4-MISC. I assume the build recreates buckets with mkdir -p and git drops the empty dir. A .gitkeep per bucket would hold them.

§7 vs package.json. §7 says "Node standard library only — no deps, no lockfile; the repo ships no root manifest", and package.json:18-21 carries acorn and acorn-walk under dependencies, with a package-lock.json and an npm install in the README. Either amend §7 or move the parser deps to devDependencies — the principle reads stronger if it's exactly true.

------------------------------------------------------------------------

2. Measured against your own principles

Nothing new here, just naming the pattern: 1.2 and 1.4 are both cases where a doc states a guarantee ("before the lock releases", "enforces this by blocking driver calls") and the mechanism covers a narrower path than the sentence implies. 1.3 and 3.1 are the same shape from the kernel side, where the caller's contract is stderr prose.

The common fix is smaller than the four issues suggest: one --json result line per verb, plus a distinct exit code for the transient case, would make 1.3 and 3.1 mechanical instead of best-effort — and would make the §13 red-control tests for all four trivial to write.

------------------------------------------------------------------------

3. Questions

3.1 What is GH-408, and does it already cover the claim exit codes?

bin/tick:116 documents exit 1 as "claim not acquired (GH-408)". I can't reach GH-408 — the public repo's highest number right now is #389, so it's above the current allocation. Private tracker, or a forward reference?

I ask because if it already covers this, ignore the rest of this item. If not: src/lock.js:44-52 throws a bare Error on EEXIST ("another tick claim is in progress... retry shortly"), and bin/tick:463-465 maps every thrown error to exit 1 — the same code as a durable loss. rtl.py runs claim, re-reads info, and fails the turn if the claimer isn't this agent, with no retry. So under load a transient collision fails a headless turn exactly like a real loss. A distinct code (75 / EX_TEMPFAIL, say) that drivers retry on would separate them.

More generally — there are a good number of GH-<n> references in the public docs and code that resolve to the private tracker. Not a problem for you, but for anyone reading the public repo it's a dead end fairly often. A read-only archive, or a one-line note in the ROUTER saying where those numbers live, would help. Where a rail actually depends on the rationale, inlining a sentence would help more.

3.2 CODEX_FLAGS — is the default meant to include approval_policy=never?

skills/relay-xyz/SKILL.md:515 gives the default as -s workspace-write, and :520 presents -c approval_policy=never as something you opt into for more autonomy. But utils/py/codex-turn.py:17 defaults to -s workspace-write -c approval_policy=never already.

The sandbox half is documented and the approval half isn't, and the approval half is the autonomy-relevant one. Probably just a doc lag — but it's the flag I'd most want stated explicitly.

------------------------------------------------------------------------

4. What I'd keep exactly as it is

The kernel is genuinely good and it does what it claims — I checked rather than assumed. 11/11 unit tests; overlap rejection; reap-then-reclaim raising the epoch; a zombie's verb refused; a replayed stale event fenced at projection with an audit row rather than silently dropped; the O_EXCL lock serializing concurrent claims. Projection being a pure function of the event set is the right call and it shows.

The containment layering in relay-turn-lib.sh is the part I'd steal: snapshot HEAD and the dirty set, bounded run, worktree copy-back of allowlisted changed files only, revert off-lane with an orphan backup, stage the allowlist, one scoped commit, never push. What I appreciated most is that the known gaps are written down next to the code instead of quietly hoped over.

Which raises the question I most want to ask you. Those inline rationale comments are the best documentation in the repo — and they're also the thing most likely to rot, because nothing fails when a comment stops matching the code beneath it. Does anything catch that, or is it culture and review?

What I could find is deterministic at the document level and cultural at the comment level. pdda.sh ships ten checks — frontmatter, status tables, hardcoded paths, roadmap, roadmap coverage, changelog, stale working docs, issue↔doc sync, releases, governance — with an observe/light/full mode ladder so they can actually block. check_issue_doc_sync reconciles a doc's gh_issue: frontmatter against live GitHub state, and I liked that it warns rather than passes when gh is offline: "a check that could not run is NOT a check that passed" is the same instinct as §13. But none of them reads an inline comment. So src/events.js can keep pointing at a decisions/ file that isn't there (my 1.5) and every PDDA run stays green — which I think is exactly the shape of drift you'd want to know about.

I ask because we have the same problem from the other end. We keep inline comments deliberately thin and push the rationale into governance records instead, which trades comment rot for pointer rot — the reference outlives the thing it points at, and you don't find out until someone follows it. Our deterministic checks are all at the record level too: a structural audit for orphans and broken references, a semantic pass over the graph, and a SHA-256 hash on the governance policy that fails closed in strict mode when the governed content changes underneath it. That last one is the only thing we have that actually detects drift rather than flagging staleness by age, and it only covers one file.

Honestly I think we've both automated the layer that was easy to automate and left the expensive part — keeping prose true — to human attention we then don't schedule. We call that gardening and it competes for time with everything else, always losing. If you've found anything deterministic that reaches further than the document boundary, I'd genuinely like to steal it.

Also worth keeping: the outcome taxonomy (3 no-progress / 4 escalated / 5 gate-or-relay / 6 containment / 7 timeout / 8 parked / 108 gate-killed, each with a typed reason in ESCALATION.md) — that's more honest than most harnesses manage. The resource-guarded gates. The uncited-[Pass] downgrade. marathon-recover.sh reporting UNGATED COMMIT. And DO-NOT-BUILD.md with named incumbents and a reconsideration trigger — that one I'm copying outright.

§13 is the best sentence in the repo. "A green gate without a witnessed red control is not evidence" is a rule I've since adopted, and the two examples you added for #351 and #348 are what made it concrete for me.

------------------------------------------------------------------------

And since I was reading yours against mine

You'll have guessed I wasn't reading this neutrally — the second reader was pointed at my own system the whole time. The one-sentence version of the difference, for whatever it's worth:

  XYZ puts the intelligence in the harness and treats the model as an untrusted subprocess; mine puts it in the graph and treats the model as a colleague who has to show receipts.

Both are coherent, and I think the bet is different rather than better. Yours buys mechanical containment and vendor breadth — you can drop a new CLI in behind a shim and the allowlist, the worktree and the commit guard still hold it. Mine buys durable, queryable intent, and pays for it with a Postgres dependency and a lot more ceremony than node + git.

We overlap in exactly one place — dispatch — and that's where the comparison gets interesting, because two things that look like one difference are actually two.

The first is what a unit of work is. Yours is the turn; mine is a card that carries its own lifecycle, edges and provenance, and is the same object type whether it's governing a decision or dispatching work. I don't think the turn is the better unit there, and I'd defend the card: because governance and dispatch are the same type, "what dispatched this, under which decision, and what came back" is one query rather than a join across a thread file, a commit message and an issue number. Your .tick/ log is the better coordination primitive — atomic, fenced, replay- deterministic — but it's gitignored, so the coordination provenance doesn't survive the run.

The second is how long the executor lives, and that's genuinely orthogonal to the first. Your turn is a fresh bounded subprocess that structurally cannot carry stale context into the next one. My default is a long-lived session in a tmux lane, which can — and has: I have a case where a lane reported ready while holding a context that made it read a completed task as unstarted, and it cost a full timeout to notice.

That's the concession, and it's narrower than "your unit is better" but sharper. I already have a one-shot dispatch path — a card handed to a headless process that exits when it's done — so this isn't something my design can't express. It's that your safe mode is the default and mine is the option, and defaults are what you actually get at 2am. You made the harder choice the automatic one.

------------------------------------------------------------------------

Happy to open these as issues individually if that's easier than a single thread — say the word and I'll file them, or leave them here if you'd rather triage first. I'm happy to send PRs for 1.5 and 1.6 since they're small, but I didn't want to open PRs on someone else's repo uninvited.

- Russ