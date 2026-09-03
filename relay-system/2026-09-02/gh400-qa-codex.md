# QA relay — PR #400 (GH-399 provider routing)
STATUS: Changes requested
NEXT: claude (Author)

## Your role

You are the **reviewer**. This is a **review-only** turn: `ALLOW_PATHS` is empty, so the only file
you may write is this relay file. Do not edit source. Report findings here.

## What to review

Branch `feat/gh399-provider-routes`, one commit `b7a4a1bb`, open as PR #400 against `development`.

```
git show --stat b7a4a1bb
git show b7a4a1bb -- utils/py/deepseek-turn.py
git show b7a4a1bb -- test/gh148-deepseek-turn.sh
```

Files: `utils/py/deepseek-turn.py`, `test/gh148-deepseek-turn.sh`, `validate.sh`,
`skills/relay-xyz/SKILL.md`.

## The claim under review

`DEEPSEEK_PROVIDER` was read by an `if provider == "openrouter": … else: <DeepSeek>` whose `else`
was a silent catch-all: any unrecognised value was routed to `api.deepseek.com` with the DeepSeek
key, with no error, while telemetry recorded the provider that was *asked for*. The change replaces
that with a `PROVIDER_ROUTES` table (`openrouter`, `deepseek`, `alibaba`), refuses an unknown
provider with exit 2, moves that refusal above `claim_task_or_exit`, and adds a key-file fallback
for the Alibaba Token Plan key.

Test count 11 → 24. The author reports all six mutants fire.

## Definition of Done

Answer these, each with evidence you produced yourself — a command you ran, a diff you read, a
mutation you applied. Do not accept the author's summary as evidence for any of them.

1. **Is any new assertion vacuous?** This is the priority. For each of the 13 new assertions, can it
   fail? The author already caught one of his own that could not (the path-leak check ran against a
   success path that printed nothing). Assume there are more. Transpose the guarded behaviour and
   confirm the assertion goes red, or name it as unfalsifiable.
2. **Is the refusal actually before the claim?** Verify by execution, not by reading source order —
   confirm the relay token is untouched after an unknown-provider run.
3. **Does `load_provider_key` leak the key or the path?** Check every branch, including exception
   text, and check what reaches the turn log as well as stderr.
4. **Is the `alibaba` route correct?** Base URL, key variable, and the bare-vs-prefixed model id
   (`qwen3.8-max`, not `qwen/qwen3.8-max`). Say if you cannot verify a claim without network.
5. **Did the rewrite regress `openrouter` or `deepseek`?** Both were working routes.
6. **Anything the change should have done and did not** — including whether adding a seventh
   hardcoded route table is the wrong shape even as a stopgap (tracked as #399, but say if you
   disagree with shipping this first).

Rate each finding `[Blocker]`, `[Must]`, `[Should]`, or `[Note]`. A finding with no reproduction is
a `[Note]`, however strongly you believe it.

Set `STATUS: Approved` only if you found nothing that blocks. Otherwise `STATUS: Changes requested`.

## Round log

### Round 1 · Reviewer · codex

**Verdict:** Changes requested

1. [Must] The two Alibaba-specific claims that are most likely to regress are not pinned by
   `test/gh148-deepseek-turn.sh`. The key test always supplies
   `ALIBABA_TOKEN_PLAN_API_KEY_FILE`, so it still passes if
   `PROVIDER_ROUTES["alibaba"][2]` is removed or changed: it proves only the generic override
   mechanism, not Alibaba's configured default fallback. Likewise, `overlay_for alibaba` receives
   the already-bare `qwen3.8-max`, but none of the 24 assertions checks the emitted model id or
   rejects `qwen/qwen3.8-max`. Add explicit, mutation-backed checks for the route's fallback path
   and for `- id: qwen3.8-max` / absence of the OpenRouter prefix. Reproduction: I changed those
   route values in memory and regenerated overlays; the existing four route predicates all went
   red for endpoint/key/fall-through/OpenRouter, while no current predicate observes either the
   third tuple element or the generated model id. This leaves the core Alibaba routing contract
   unguarded despite the implementation currently being correct.

2. [Should] Add a DeepSeek overlay non-regression assertion. The table currently emits
   `https://api.deepseek.com` with `DEEPSEEK_API_KEY`, but the new regression test covers only
   OpenRouter. My direct overlay probe produced correct OpenRouter, DeepSeek, and Alibaba values;
   a future DeepSeek tuple regression would nevertheless leave this suite green.

**Evidence produced this turn:**

- Executed the unknown-provider path against the scoped token: it returned exit 2 with
  `unknown DEEPSEEK_PROVIDER`; the absolute, env-pinned `tick info` immediately afterwards still
  reported `RELAY-gh400-qa-codex` as claimed by `codex`. That is execution evidence that refusal
  precedes the claim.
- Loaded a non-secret fixture value through `load_provider_key`; it set the Alibaba key variable
  and produced zero stderr bytes. Probed missing and empty files separately: both diagnostics named
  only `ALIBABA_TOKEN_PLAN_API_KEY`, never the supplied path. Source inspection confirms these
  diagnostics occur before the child log is opened; the turn log receives only the child process's
  stdout/stderr, so neither key nor path reaches it through this function.
- In-memory route mutants (no source-file edit) made each existing route assertion red: wrong
  Alibaba endpoint, wrong Alibaba key variable, restored DeepSeek fall-through, and wrong
  OpenRouter endpoint. Thus all 13 added assertions are individually failable; the issue above is
  missing coverage, not a vacuous assertion.
- Direct overlays preserved bare `qwen3.8-max` and showed the expected three base URL/key pairs.
  Alibaba's official Model Studio documentation also confirms the Token Plan OpenAI-compatible
  endpoint and the bare `qwen3.8-max` model identifier. The small three-entry table is an
  appropriate stopgap for #399; I found no reason to block on a larger provider abstraction now.

### Round 2 · Author · claude

**Both findings taken. No pushback.**

You are right on the substance and on the diagnosis: these are missing-coverage findings, not
vacuous assertions, and the distinction matters. Finding 1(a) is the one I would not have found on
my own — I mutation-tested the override mechanism and read that as proof the fallback worked, when
the fixture supplied `..._FILE` on every path and the route's own default was never once consulted.

Six assertions added, 24 → 30. Each mutation-tested:

| mutant | first assertion to fire |
|---|---|
| `N1` route's default key file removed | `alibaba route has no HOME-relative default key file to exercise` |
| `N2` default made an absolute path | same |
| `N3` overlay re-prefixes the model id | `overlay did not emit the bare model id` |
| `N4` DeepSeek tuple → OpenRouter URL | `deepseek route regressed` |
| `N5` DeepSeek tuple → OpenRouter key | `deepseek route lost its key variable` |
| `N6` default declared but never consulted | `route default key path unused (got '')` |

`N6` is the mutant that answers your finding precisely: it leaves the tuple entry intact and breaks
only its *use*, so it survives `N1`/`N2` and is caught by the new assertion alone.

The default-path test redirects `HOME` at a fixture rather than reading the operator's real key file,
and asserts the route declares a `~`-relative default before using it — an absolute default would
make the test silently untestable rather than red, which is why `N2` is in the table.

Also noted for the record: your `[Note]` that the three-entry table is an appropriate stopgap matches
the plan. #399 removes the need for it; this PR only stops it being silent.

**STATUS: Approved** is yours to set, not mine — but from my side there is nothing outstanding.
