/Users/noelsaw/Documents/Noel Saw/0. Claude Prompts.md

The log makes both sequences explicit. Here's what you're actually typing, and the plan to delete the typing — quick wins first.

**What the corpus shows you doing manually:**

- **Pre-marathon (×~25):** write/park capture doc → add to marathon plan → "preflight sweep for all active Marathon files to make sure nothing's been completed already" → cleanup → `--dry-run` → fire.
- **Post-marathon (×~45 combined):** commit & push (incl. your manual edits) → PR with notes → merge if green → pull, switch back to development → close GH issues → move docs to correct PROJECT/ folder → PDDA sweep → sometimes a Slack handoff blurb.

**Plan, in order of effort:**

**1. Today — two custom slash commands (~10 min).** These prompts are typed into interactive Claude Code, so `.claude/commands/` files are the exact right tool — cheaper than skills, verbatim prompt stored once:
- `/pre-marathon` — "Sweep all active MARATHON plan files: verify no phase is already satisfied (check probes/artifacts), clean up stale phase dirs and ESCALATION.md leftovers, slot any open tasks that fit into a remaining plan, then `--dry-run` each plan and report the execution order."
- `/post-marathon` — "Commit and push all changed files including my manual edits. Create PR with notes; merge if green. Pull, switch back to development. Close all GH issues resolved by this run. Move completed docs to PROJECT/3-COMPLETED. Run full PDDA sweep. End with `/loose-ends`."

This alone kills the ×38 commit-push family, the closeout chain, and the preflight-sweep prompt.

**2. This week — `loose-ends-sequence.md` per repo.** Encodes the repo-specific tail (PDDA sweep command, doc folders, gitignore rules) so `/post-marathon`'s final `/loose-ends` call executes the right sequence per repo instead of you re-specifying it.

**3. Next — extract the deterministic half to a script.** The git ceremony inside post-marathon (commit → push → PR → merge → pull → switch) is zero-judgment; a `marathon-closeout.sh` beside the harness makes it one command *and* usable headless later. The slash command then shrinks to "run marathon-closeout.sh, then close issues/file docs/PDDA sweep."

**4. Later — harness integration.** Once 3's script is stable, wire it as a `--post-approve-cmd` in marathon-drive (symmetric to `--pre-advance-cmd`) so the marathon closes itself out and your interactive session starts at "review the PR" instead of "do the ceremony."

Deploy note: put the commands in each repo's `.claude/commands/` (or `~/.claude/commands/` once, globally — I'd start global since the sequence is near-identical across your 14 repos, with repo differences pushed into step 2's manifests).

Want me to write the two command files and one example `loose-ends-sequence.md` (xyz-3-agents-swarm) now? I'll draft them from the exact phrasings in your log so nothing you currently ask for gets dropped.