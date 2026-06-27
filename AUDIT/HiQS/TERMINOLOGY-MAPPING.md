---
title: Terminology Mapping — HiQS
doc_type: naming-proposal
status: Revised proposal
scope: Packaging / naming only — no internal technical renames
supersedes: aviation whiteboard draft (preserved at bottom)
---

# Terminology Mapping — HiQS

> **Status:** Revised proposal (supersedes the aviation whiteboard, preserved at the bottom).
> **Scope:** Packaging / naming only. No internal technical machinery (`tick`, relay scripts,
> `rebalance` CLI, `sleuth_reminders.py`) gets renamed — this is the label layer that rides on top.

---

## Thoughts (the three decisions behind this revision)

**1. Drop aviation. The real metaphor is track & field — and you already built it.**
`relay`, `marathon`, `race`, and `lanes` are all *already* in the code. "Cross Country" is a real
running event. Aviation was a second metaphor bolted onto a vocabulary that was already coherent,
which adds a decode step for every reader. Athletics removes that tax because the code words *are*
the theme words.

**2. "Signal" is the hinge between the brand and the metaphor.** A race starts with a *signal*
(the starter's gun); `tick` is literally a log of *signals*; coordination is agents reading each
other's signals. And separately — signal vs noise — a field of agents produces chatter, and the
**high-quality signal** is the verified, reconciled output. **HiQS is the descriptive name for what
the machinery already does** (consult reconciles N opinions, adversarial-verify kills
plausible-but-wrong findings, the relay loop converges disagreement). The name isn't aspirational;
it's the honest label.

**3. "Agent Playground" is the outer wrapper; the mechanics are races.** Your existing terms
(marathon, relay, race) are *competitive athletics*, not recess games. So let "Playground" be the
friendly marketing skin and let the system internals read as **the Meet** — the track where runners
race in lanes and pass batons.

---

## Brand architecture (4 layers, zero internal renames)

| Layer | Name | What it is |
|---|---|---|
| **Company / thesis** | **HiQS.ai** — High Quality Signals | Trustworthy output from AI, not slop |
| **Platform / surface** | **Agent Playground** (marketing) · **the Meet** (system) | Where runners race and you watch |
| **Products** | **Pacer · Rebalance · Relay · Marathon · Sprint · Consult** | The race types + the HiQS core (see below) |
| **Kernel** | `tick` — externally *"the Signal Bus"* | Unchanged binary; each event **is** a signal |

**Tagline candidate:** *Many runners. One signal.* (the swarm reduced to one trustworthy output)

---

## Athletics ↔ system mapping (revised from aviation)

| Concept | Old (aviation) | Athletics name | Why it wins |
|---|---|---|---|
| The harness / where runs originate | Airport | **The Meet** / **The Track** | A "meet" is a whole competition session |
| Long multi-phase run | Long Haul | **Marathon** ✅ | Already shipped |
| Long but bounded | Cross Country | **Cross Country** ✅ | Already a real event |
| Multi-agent handoff run | — | **Relay** ✅ | Already shipped — it's a team baton race |
| Short quick one-off | Bus | **Sprint** / **Dash** | Unambiguous "short and fast" |
| Recurring scheduled job | Commuter | **Lap** / **Circuit** | A repeated circuit = recurring run |
| The agents (X/Y/Z) | *unnamed* | **Runners** / **Racers** | Fills the biggest gap — names the protagonists |
| Path-scoped claims | — | **Lanes** ✅ | Already the word XYZ uses |
| Orchestrator | Ground Control | **Starter** / **Track Marshal** | Fires the start signal, watches the field |
| Handoff payload / context | Luggage | **Baton** 🏆 | The single best swap — relays pass a baton |
| Dashboard | — | **Scoreboard** / **Grandstand** | Where you watch runner status + signals |

### Status lifecycle (your strongest piece — keep it, just re-themed)

| Old | New |
|---|---|
| Preflight | **On Your Marks** (queued / warming up) |
| In Flight | **Running** / **On the Track** (active) |
| Grounded | **Benched** / **Cooldown** (idle / stopped) |

---

## HiQS core products

The two HiQS core products are distinct in function — name them for what they actually do
(verified against their deep-scan briefs, 2026-06-17/18):

- **Sleuth → rename needed** (core #1, **most mature — Proven**) — a production-proven, multi-tenant
  **Slack-native capture-and-scheduling assistant**: 2.5 yrs daily use, 7 live workspaces, a
  disciplined reminder state machine, 54 commands, tri-provider AI, GitHub two-way sync. Its own
  roadmap frames its role as *"the Slack-native capture-and-scheduling layer of a larger productivity
  ecosystem."* It **captures** commitments where work is discussed and **brings them back on time**.
- **Rebalance** (core #2, **"Works → Solid"**) — the attention brain: ranks "what should we work on
  next" across signals, and is where **dropped-ball detection** lives (the owner-bias finding; the
  Bloomz/NMI catch). Name stays — it already means *rebalancing where your attention goes*. It
  *consumes* Sleuth's export (`?format=rebalance`).

The pipeline reads cleanly: **capture in Slack → decide what's next.**

> Correction note: an earlier draft proposed **Radar** for Sleuth. That was based on the (then-empty)
> Sleuth brief plus Rebalance's framing, and it described the wrong thing — *detection* of dropped
> balls is a **Rebalance** capability, not Sleuth's. "Radar" is now parked as a candidate **Rebalance
> feature name**, not a product rename.

### Sleuth rename — recommendation

The job to name: *the in-Slack teammate that captures what you say and brings it back at the right
time.* The sharp, proven, differentiated core is **reminder scheduling — timing.** In the athletics
frame that names itself.

| Candidate | Fit | Note |
|---|---|---|
| **Pacer** ⭐ | **Recommended** | A distance-running pacer is the teammate whose whole job is keeping you on time — hitting the splits so nothing slips. Exactly Sleuth's core. On-theme, function-accurate, warm (teammate, not enforcer). Minor: shares the word with the NBA team — athletic-pacer meaning dominates in a productivity/fitness brand. |
| **Cadence** | Strong | Rhythm/timing of reminders; athletic-adjacent (a runner's cadence). But it's a crowded SaaS name. |
| **Scout** | OK | Keeps the detective/recon DNA of "Sleuth" and the capture-into-the-system idea; weaker on the *scheduling* half. |
| **Marshal** (Track Marshal) | OK | The official who keeps the event on schedule and in order — ties to "the Meet," but reads more enforcement than helpful teammate. |
| ~~Radar~~ | **Withdrawn** | Describes *detection* (a Rebalance capability), not Sleuth's capture/scheduling function. |

**Pick: Pacer.** "The teammate that keeps your commitments on time" is the proven core in one line,
and **Pacer → Rebalance** reads as a self-explaining pipeline: capture and pace the work, then decide
what's next.

---

## Open questions to lock

- Confirm **Pacer** for Sleuth (or pick from the table) — it's the most mature piece (Proven), so its
  name ships first and anchors the family. Decide separately whether **Radar** becomes a *Rebalance
  feature* name for dropped-ball detection.
- "Playground" (marketing) vs "the Meet" (system) — keep both, or collapse to one?
- "Lap" vs "Circuit" for recurring jobs — pick one.
- Does `tick` get the public-facing *"Signal Bus"* description in the front-door docs, or stay
  purely internal?

> **Caveat that comes with the brand:** "High Quality Signals" is a claim you have to keep. The
> adversarial-verify / reconcile machinery *is* the proof — lead with it in the front-door docs, or
> the name writes a check the relay loop has to cash.

---
---

## Original whiteboard (superseded — aviation draft)

Here's your whiteboard cleaned up. It reads as an aviation naming scheme in three layers: a **flight taxonomy** (run types), a **status lifecycle** (session states), and **machine-level constructs**. I've added a proposed swarm meaning for each — swap any that don't fit your model.

**AIRPORT — flights (run / session types)**

The four classes form a scope ladder, longest to shortest. "Airport" itself = the harness (where flights originate and get dispatched).

| Term | Aviation sense | Proposed PDDA/swarm meaning |
|---|---|---|
| Long Haul | Longest-distance flight | Long, multi-phase run (Marathon-style build→review chains) |
| Cross Country | Long but bounded | Multi-step task with a defined endpoint |
| Commuter | Short, routine, repeated | Recurring short run (scheduled / standard job) |
| Bus | Local Bus - Shortest, frequent hop | Single-shot / quick one-off task |

**STAYS — status (session lifecycle)**

Reads as a three-state lifecycle. (You wrote "STAYS" but the items are states — flag if "stays" is intentional.)

| Term | Meaning |
|---|---|
| Preflight | Setup / init — queued, not yet active |
| In Flight | Active session running (= "any active sessions") |
| Grounded | Idle, no activity — stopped / parked |

**AT MACHINE LEVEL — local constructs**

- Ground Control — the orchestrator / coordinator process (the local harness driving the agents)
- Luggage — payload carried between agents or across phases (artifacts, context, handoff state, relays)

**Open slots to fill**
- Where do the X / Y / Z agents sit? Natural fit is *aircraft* (or tail numbers) flying the routes, with Ground Control as the harness — the board doesn't name them yet.
- "Stays" vs "States" — confirm wording.
- Is "Commuter" distinct from "Shuttle" by *frequency* (commuter = scheduled, shuttle = on-demand) or purely by *length*?
