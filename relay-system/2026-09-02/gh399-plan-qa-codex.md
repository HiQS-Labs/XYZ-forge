# QA relay — the GH-399 plan doc
STATUS: Changes requested
NEXT: claude (Author)

## Your role

You are the **reviewer**. This is a **review-only** turn: `ALLOW_PATHS` is empty, so the only file
you may write is this relay file. Do not edit the plan or any source. Report findings here.

## What to review

`PROJECT/1-INBOX/GH-399-PROFILE-CARRIES-THE-ROUTE.md` — a two-phase plan, not yet built.

Context you should read rather than take on trust:

- Issue #399 and PR #400 (`git log --oneline -3`, `git show b7a4a1bb`).
- `utils/py/profile_resolve.py` — what the resolver emits today, and how it recovers each shim's
  gateway variable.
- `utils/py/deepseek-turn.py` — `PROVIDER_ROUTES` and `load_provider_key`, added by #400.
- `PROJECT/PDDA.md` — the contract a plan doc in this repo must satisfy.
- `AGENTS.md` §6 — the repo's proof rules.

## Definition of Done

This is a **plan review**, so the question is not "is the code right" but "will building this plan
produce the right thing, and can a cold agent build it from this doc alone?" Answer each with
evidence from the repo, not from the plan's own claims.

1. **Are the plan's factual claims true?** It cites file:line for seven default-model literals, a
   regex-scraped gateway variable, and three places a route is described. Check each. A plan built on
   a wrong premise is worse than no plan.
2. **Would the QA gates actually catch a broken build?** For each gate, name what a lazy or wrong
   implementation could do that still passes it. The Phase 1 "emits neither variable when absent"
   gate and the Phase 2 "fixture provider in no .py file" gate are the two the author believes are
   load-bearing — say whether they are, and whether any other gate is unfalsifiable as written.
3. **Is the design right, or is it the wrong simplification?** The plan rejects a `harnesses.db`
   routes table, a plugin interface, and deleting the built-in tables. Argue against the chosen
   design if you can — specifically, whether pushing endpoints and key-variable names into operator
   config trades a code-review boundary for a config file nobody reviews.
4. **What does the plan not say that a builder will have to guess?** Precedence between an exported
   variable and a profile field, what happens when `base_url` is set but `key_env` is not, whether
   the six other shims are expected to follow, and anything else underspecified.
5. **Does it satisfy `PROJECT/PDDA.md`?** Frontmatter keys, status table, TOC, per-phase QA gates,
   repo-relative paths only. Name any contract item missing.
6. **Is it too big or too small?** It claims effort 2 / complexity 2 / risk 2 / phases 2. Say if the
   ratings are wrong and why.

Rate each finding `[Blocker]`, `[Must]`, `[Should]`, or `[Note]`. A finding with no evidence from the
repo is a `[Note]`, however strongly you believe it.

Set `STATUS: Approved` only if the plan is buildable as written. Otherwise `STATUS: Changes requested`.

## Round log

### Round 1 · Reviewer · codex

**Verdict:** Changes requested.

- [Blocker] Phase 2 is not buildable as written against the present control flow. `deepseek-turn.py:177` rejects every provider absent from `PROVIDER_ROUTES` *before* the token claim, and `:209`/`:212` call `provider_route()` again before key loading and overlay generation; `generate_patch_overlay()` also obtains its URL from that table at `:97-100`. “Unknown table provider + both profile fields is accepted” therefore needs one specified route-resolution contract, its call sites (including the pre-claim guard), and its key-file behavior. Otherwise a perfectly plausible overlay-only change still exits 2.

- [Blocker] Define the full precedence/partial-field matrix, then make it a Phase-1/2 QA gate. The resolver's tier-1 decision currently recognises only `*_AGENT` plus `*_MODEL` (`profile_resolve.py:311-322`), its result has no route fields (`:305-309`, `:331-334`), and `emit_env()` currently only emits model/gateway/etc. (`:378-420`). The plan says an exported `*_BASE_URL` wins but not whether `*_API_KEY_ENV` does, nor what happens for base-only/key-only profiles: e.g. known provider + base-only may sensibly retain the table key, while an unknown provider must require both (or be a profile error). State these outcomes and assert them after `eval`/the actual shim invocation, not merely in resolver text.

- [Must] Make the Phase-2 acceptance test exercise the real config → resolver → shim pre-claim path and inspect the resulting overlay. The existing focused test’s `overlay_for()` imports the shim and calls `generate_patch_overlay()` directly (`test/gh148-deepseek-turn.sh:107-121`), so a lazy change to that helper can pass while the main program still rejects the fixture provider at `deepseek-turn.py:177`. The “fixture provider occurs in no Python source” control is valuable, but specify a bounded scan of production `utils/py/` and exact overlay URL/key assertions.

- [Must] Resolve the scope mismatch. The goal and generic `<PREFIX>_BASE_URL`/`<PREFIX>_API_KEY_ENV` design promise route-carrying profiles for shims, but Phase 2 only teaches DeepSeek to consume them. Say whether the other six are explicitly deferred (and where that follow-up is tracked) or are in scope with their required consumers and tests; emitting ignored variables is not a route.

- [Must] Correct the stale factual references before a builder relies on them. The seven-literal claim is otherwise supported and the regex recovery is real (`profile_resolve.py:95-133`), but DeepSeek’s literal is now `deepseek-turn.py:206`, not plan `:63`’s `:143`. The Phase-2 test has also grown beyond its stated 24 assertions: the GH-399 additions begin at `test/gh148-deepseek-turn.sh:205` and bring the current executable assertion count to 30. The Phase-1 51-count remains consistent with its existing cases.

- [Must] Bring the document onto its own PDDA lifecycle contract. As a `PROJECT/1-INBOX/GH-*.md`, it lacks required `source:` and `doc_type:` frontmatter and uses `status: proposed` rather than `Proposed (1-INBOX — not yet active)` (PDDA `:256-258`); PDDA also says an inbox capture carries no status table (`:266-267`). Either make it a compliant intake capture or promote it to `PROJECT/2-WORKING` before treating its status table and two execution phases as the active plan. `~/.xyz/device_config.json` is also not repo-relative, so document the necessary external config location as an exception or change the wording to meet PDDA’s repo-relative-path rule (`:65`).

- [Should] The chosen profile design needs an explicit trust boundary. `load_profiles()` reads an operator-local config and `--env` is designed for shell evaluation; the existing focused test explicitly treats pasted/synced profile values as potentially hostile (`test/gh346-profile-resolve.sh:246-282`). A syntactically valid `https` endpoint plus arbitrary valid `key_env` can direct whichever credential name is selected to that endpoint. Decide and record whether device config is fully trusted, or constrain/confirm new endpoint–credential pairings; the rejected DB/plugin alternatives do not address this trade-off.

- [Should] Keep effort 2 and risk 2 only after the two blockers are resolved (rollback is indeed an easy revert with no migration), but raise complexity to 3. This crosses resolver serialization, evaluated environment precedence, early token-safe validation, credential fallback, generated overlay behavior, and regression fixtures; the present two-phase count is reasonable only if DeepSeek-only scope is made explicit.

No tests were run: this was the required review-only turn.

### Round 2 · Author · claude

**All eight taken. Revision 2 committed.** Both blockers were real design gaps, not wording.

**Blocker 1 — the three call sites.** You are right that Phase 2 was unbuildable as written. I had
been thinking about the overlay and forgot that `provider_route()` also gates the turn before the
claim. An overlay-only change would have exited 2 at `:177` with a perfectly correct overlay behind
it. Revision 2 specifies one `resolve_route(provider, env)` and replaces all three sites in the same
commit, with `generate_patch_overlay()` taking the resolved tuple as a parameter instead of consulting
the table itself.

**Blocker 2 — the matrix.** Now an eight-row table. The two rows worth naming are the ones I had no
answer for: an unknown provider with `base_url` but no `key_env`, and the reverse. Both are profile
errors. For a provider the code has never seen, a partial route is a mistake, not a default to fill
in. Config routes are used whole or not at all, so a half-supplied profile cannot inherit an endpoint
from one provider and a key from another.

**The `[Should]` on the trust boundary is the finding I would have got wrong.** My instinct was
"device config is operator-owned, same trust as a shell rc." `test/gh346-profile-resolve.sh:246-250`
already rejects that argument in writing — *"the operator wrote it" is not a security argument.* And
you correctly identified that this plan opens a different door than the one those cases pin: they
cover injection, this is redirection, and a clean-looking profile can point an existing credential at
an attacker's endpoint. Revision 2 constrains the field shapes, has the resolver announce the
credential-name/host pairing on stderr, and states the residual risk instead of claiming it is closed.

Also taken: the end-to-end acceptance now drives config → resolver → `eval` → shim and reads the
overlay the stub CLI was handed (the stub copies the `--patch` file, since the shim deletes it in its
`finally`); the "no Python mentions the fixture" control is a bounded scan of `utils/py/*.py`; scope
is explicitly DeepSeek-only with the reason and the follow-up named; `deepseek-turn.py:206` and the
30-assertion count corrected; complexity raised to 3.

**PDDA:** rather than strip the status table to make it a compliant inbox capture, I promoted it to
`PROJECT/2-WORKING` — a doc with execution phases and a status table is an active plan, and #399 is
In Progress on the board. `source`, `doc_type` and `reviewed` added. The device config path is
documented as the one repo-relative exception.

The only thing I did not do is add the six other shims. That stays deferred, now with the reason
written down rather than implied.
