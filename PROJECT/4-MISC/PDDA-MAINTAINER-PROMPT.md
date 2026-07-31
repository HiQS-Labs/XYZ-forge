# Handoff prompt — PDDA maintainer (`Hypercart-Dev-Tools/pdda`)

Written to be handed to an agent or maintainer working **in the `pdda` repo**. Everything it asks
for is upstream. Filed from
[xyz-3-agents-swarm#381](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/381).

Copy everything below the line.

---

You are maintaining `Hypercart-Dev-Tools/pdda`, which defines the `RELEASES.md` contract that
`pdda-sync.sh` distributes to consumer repos. Four requests. Push back on any of them if you
disagree — the reasoning matters more than the specific wording.

## 1 · The headline problem: the contract never says `RELEASES.md` is optional

This is the most important item, and it is **purely a prose problem** — your tooling is already
correct and needs no change:

- `pdda.sh releases` is warn-only and never blocks (`# J. releases (warn-only nudge; never blocks, even in full)`).
- It skips entirely when the file is absent: *"RELEASES.md not found — nothing to check"*.

But `PROJECT/PDDA.md` § "RELEASES.md — release ledger" documents the format, every field, and two
skills at length, and **nowhere states that the file is optional or that a sparse one is fine.** A
reader — increasingly an LLM maintainer — infers from that treatment that the file is expected to be
populated and kept current.

The observed consequence: assistants repeatedly offer to fill it in, populate it, bring it up to
date, or add the release that just shipped. Each offer is individually helpful and reasonable. In
aggregate they turn a planning aid into a **de-facto pre-CHANGELOG** — a second, hand-maintained
history of what shipped, guaranteed to disagree with `CHANGELOG.md` the first time someone updates
one and not the other. Two sources of truth for the same fact is the defect.

Nobody decides to cause this. It happens **one helpful suggestion at a time**, which is exactly why
it needs to be stated rather than assumed.

**Requested:** open the section with the optionality, before the format. Something like:

> `RELEASES.md` is an **optional planning aid**. It is not a required artifact, not a checklist, and
> not something to keep topped up. An empty file, a stale file, or no file at all are all valid
> states — `pdda.sh releases` skips a missing file and never blocks.
>
> **Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
> already shipped.** Do not treat a sparse file as an incomplete one. Edit it only when an operator
> explicitly asks for release *planning*.

Phrasing it as an instruction rather than a description is deliberate: the audience that causes the
drift reads this file as instructions.

## 2 · The admission rule exists only as an adjective

The section opens with *"a single forward-looking planning ledger for **major releases**, not a
lifecycle bucket of per-tag docs."* That word "major" is the entire rule governing what may enter
the file, and nothing elaborates or checks it — `pdda.sh releases` validates `Target Date` and keys
its overdue nudge off `Status: Shipped`, but never asks whether a block *belongs*.

There is nothing to point at when declining an entry, which is what makes the drift one-way.

**Requested:** state it as a rule:

> A block earns its place by being worth *planning toward* — a named arc with a theme, a target
> date, and a milestone. If the only thing that can go in `Description:` is a restatement of what
> changed, it belongs in `CHANGELOG.md` and nowhere else.

## 3 · Add an optional `Iterations:` field

An admission rule with no alternative destination gets broken under deadline. Give the excluded
thing somewhere to go:

```text
Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Draft
```

`Iterations:` reserves a band of patch numbers that are **reserved and deliberately not
enumerated**. Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they never
get a block. It turns *"where does 0.2.3 go?"* from a question resolved by adding a row into one
with a written answer.

It also makes the rule **mechanically checkable** rather than rhetorical: *a version inside an
existing band is already accounted for, so a block for it is by definition a duplicate.* A skill can
test that. "Is this release meaningful?" it cannot.

**Rejected alternative, in case it comes up:** persisting `Iteration 1:` … `Iteration 5:` labels per
release. That is 20–25 named rows across a 5-release horizon, each an invitation to fill in what
shipped — the same drift, arriving as structure instead of as appended blocks. One optional field
beats five required ones.

**Compatibility, already verified in a consumer repo:** adding `Iterations:` to a live block leaves
`pdda.sh releases` at **rc=0, errors=0, warns=0** and `pdda.sh run` fully green. The parser tolerates
unknown labels today, so this is additive with no migration. Keep it optional; absence means no band.

**Please also decide and write down what happens when a band is exhausted** — `0.2.5` is needed and
the band ends at `0.2.4`. Widen, or promote to `0.3.0`? Left unstated, this is precisely how the
convention rots: the first person to hit it adds a block and the rule dies quietly. The consumer
repo has provisionally written *"widen it or promote the next release — do not start enumerating"*,
but this call should be yours.

## 4 · Propagate to all vendored copies — and resolve a divergence first

`PROJECT/PDDA.md` is sync-managed (`file PROJECT/PDDA.md` in `pdda-sync-manifest.conf`), so consumer
repos cannot fix any of the above locally — the next sync reverts it.

**10 live copies found on disk.** Eight are byte-identical to upstream at 1015 lines:

`rebalance-OS` · `giant-brains-claude-skills` · `LTVera-Pandas` · `pdda` · `aegis-sleuth-slack-bot` ·
`hyper-pandas-python-stack` · `cactus` · `sleuth-app`

Two are not, and one of them needs a decision **before** it is re-synced:

| Repo | Lines | Differing |
|---|---|---|
| `xyz-3-agents-swarm` | **839** | 394 |
| `fast-key-replacement-macos` | **464** | 711 |

**`fast-key-replacement-macos`** is simply far behind — a straight re-sync should do it.

**`xyz-3-agents-swarm` carries a local field upstream does not have: `Milestone:`.** Upstream instead
has `Front-door reviewed:` / `Shakedown reviewed:` / `License file:`. Each side has fields the other
lacks, so this is divergence, not staleness.

`Milestone:` is load-bearing in that repo — it is the release → issue-set join key, holding a GitHub
milestone **title** so release scope can be queried rather than hand-maintained:

```
gh issue list --milestone "Quicksilver" --state open --json number,title,labels
```

That query *is* release-driven work selection, with no second cache and no local issue list. It
looks worth having upstream on its own merits.

**Because `PROJECT/PDDA.md` is sync-managed, the next `pdda-sync.sh` into that repo will overwrite
its copy and delete `Milestone:` with it.** Please either adopt `Milestone:` upstream first, or
coordinate before syncing that repo. A blind re-sync silently breaks a documented workflow there.

## What has already been done consumer-side (no action needed)

`RELEASES.md` is **not** in the sync manifest, so `xyz-3-agents-swarm` applied the local half
immediately without risk of being clobbered:

- the file now opens with the optionality instruction — do not top it up, sparse is valid;
- then states the admission rule and the band convention;
- its `0.1.0` block carries `Iterations: 0.1.0-0.1.4`;
- `pdda.sh run` verified green with the new field present.

That is deliberately only the local half. The contract is yours, and duplicating it downstream would
just be a second thing to drift.
