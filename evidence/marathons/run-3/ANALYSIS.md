# Run 3 — what an under-specified brief does to a builder/reviewer loop

Run 3 varied **difficulty**, where runs 1 and 2 varied structure. Its result is the most
informative of the three, and it is not the one the design predicted.

## Result

| Phase | Design intent | Rounds | Outcome |
|---|---|---|---|
| `r3p1` stable multi-key sort | routine | 4 | Approved |
| `r3p2` exact BigInt decimal arithmetic | genuinely **hard**, fully specified | **2** | Approved |
| `r3p3` fuzzy transaction matching | deliberately **under-specified** | **7 (cap)** | **ESCALATED** |
| `r3p4` ledger statistics | routine | — | not started (chain halted) |

`marathon-drive` exit **4** (relay cap / mismatch), reason `cap-or-close-mismatch`, `gate: not-run`.
Wall clock 1035s. Builder `claude`, reviewer `codex`.

## The finding: specification quality dominated task difficulty

The phase written to be *hard* converged in **two** rounds. The phase written to be *easy but vague*
never converged at all.

`r3p2` asked for arbitrary-precision decimal arithmetic on `BigInt` — HALF_EVEN rounding at the
boundary, sign symmetry on negatives, scale alignment, a value beyond `Number.MAX_SAFE_INTEGER`
surviving a round trip. Objectively harder than fuzzy matching. But every requirement was checkable,
so the reviewer had a bar to check against, and the loop terminated.

`r3p3` asked the builder to pair transactions that "are probably the same", "sensibly", with
"good quality" matches, picking "the best one" where several are plausible, and options that let a
caller "tune how strict the matching is". No thresholds, no algorithm, no tie-break rule. Acceptance
said only "demonstrating the matching works on realistic data".

That is the whole difference. **Difficulty is bounded; ambiguity is not.**

## What the reviewer did — and did not — do

It reviewed rigorously. Three rounds, three *genuine, distinct* defects, each with a worked example
and a requested regression test. It declared `swept file: yes` every round and ran
`node --test test/fuzzy-match.test.js` itself.

> **Round 1** — `scoreMatch` converts both amounts with `Math.abs`, so a debit and a credit of the
> same magnitude receive a perfect amount score. `{amount: 100}` and `{amount: -100}` produce
> confidence `1`; these are opposite-direction transactions and clearly must not be paired.

> **Round 2** — Zero tolerances, a natural way to request exact-only matching, yield `0 / 0`.
> For identical amounts with `{amountTolerance: 0}`, `amountScore` becomes `NaN`; the pair therefore
> cannot clear `minConfidence` despite being an exact match.

> **Round 3** — `minConfidence` is documented as the minimum confidence required to form a pair, but
> the greedy selection uses a strict `>`. An exact transaction with confidence `1` is left unmatched
> when a caller sets `{minConfidence: 1}`.

All three are real. None is nitpicking. A human reviewer would have raised each of them.

**And not one of them is about the brief.** Across seven rounds the reviewer never observed that the
specification defines no thresholds, no scoring function, no tie-break rule, and no acceptance
criterion it could measure against — that there was, in the end, nothing to be right *about*.

That is the behaviour worth knowing: **the reviewer audits the artifact, never the requirements.**
Given an unbounded brief it produces an unbounded stream of individually-valid findings, and the loop
runs until the round cap stops it rather than until the work is done.

Neither agent misbehaved. Both did their jobs well. The loop still could not terminate, because
nothing in it is responsible for noticing that the target was never defined.

## Second observation: an escalated phase can leave working code behind

At the cap, the artifact existed and was green:

```
src/fuzzy-match.js        3952 bytes
test/fuzzy-match.test.js 10698 bytes
node --test test/fuzzy-match.test.js  ->  # tests 22  # pass 22  # fail 0
```

Twenty-two passing tests, three real bugs fixed along the way — and the phase is `ESCALATED`,
`STATUS: Open`, `gate: not-run`.

The harness is right to refuse. `STATUS: Approved` means a reviewer signed off, and no reviewer did.
But it is worth stating plainly for anyone reading an escalation: **an escalated phase is not
necessarily a phase that produced nothing.** Here it produced a working module that improved across
three review rounds and simply never got a signature. An operator who treats escalation as "discard
and retry" would throw away real work.

## Third observation: the round labels desynchronised

The relay's own block labels do not agree with the round counter:

```
143: ### Round 3 · Builder · claude
162: ### Round 4 · Builder · claude      <- two builder blocks in a row, no reviewer between
177: ### Round 3 · Reviewer · codex      <- reviewer numbered 3, appended after Builder 4
```

Three reviewer verdicts against four builder blocks. `cap-or-close-mismatch` is exactly the right
name for the escalation, and the driver caught it — but the transcript's own numbering cannot be read
as a reliable round index, which matters if the transcripts are being parsed rather than read.

Whether the double builder turn *caused* the mismatch or merely accompanied it is not established
here; it would need a second occurrence to separate. Recorded as an observation, not a diagnosis.

## What this run says about the harness

Positive, and it is the substantive answer to "does this survive long-horizon autonomous work":

- The round cap did its job. Without it this phase would not have stopped.
- The chain halted on first failure and did not start `r3p4`, exactly as documented.
- `gate: not-run` — it never ran the gate against unapproved work.
- `ESCALATION.md` carries the exit code and reason.
- The transcript was saved anyway, so the failure is fully inspectable. This analysis exists because
  the harness preserved seven rounds of a failed phase verbatim.
- Containment held across all three builders. `claude` peaked at 402 MB RSS, against `codex` 295 MB
  and `agy` 197 MB — worth knowing for host sizing, since the memory floor is not enforced anywhere.

The gap this run exposes is not in the containment or the plumbing, both of which behaved. It is that
nothing in the loop owns the question *"is this brief answerable?"* — and a marathon is precisely the
setting where nobody is watching for hours.
