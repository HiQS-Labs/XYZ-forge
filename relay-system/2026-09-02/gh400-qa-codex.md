# QA relay — PR #400 (GH-399 provider routing)
STATUS: Open
NEXT: codex (Reviewer)

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
