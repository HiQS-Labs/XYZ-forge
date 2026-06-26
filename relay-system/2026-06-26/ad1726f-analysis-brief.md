# Briefing — Verify analysis of commit `ad1726f` (LTVera V1.2 scope revision)

You are the **Reviewer**. A teammate (Claude) analyzed a documentation commit and made
magnitude + impact claims. Your job: **confirm or challenge** that analysis using ONLY the
evidence embedded below. This is advisory; you are not editing the LTVera repo. Be skeptical,
concrete, and willing to disagree.

---

## 1. Evidence — the commit

```
commit ad1726f  Author: ssalomonbinoid (Sam, PM)  Date: 2026-06-25
docs(v1.2): scope revision — read-only MVP, Binoid measurement tenant, Option A holdout

V1.2 revised to read-only recommendations; automated Klaviyo writes move to V1.3.
Measurement tenant confirmed as Binoid (clean baseline, 395K+ customers).
Measurement design: Option A merchant-mediated holdout, Sam leads data side.
Bounce next activation priority. P22.5 gate + S2/CC1/CC3 move to V1.3 scope.
All three stakeholders (Sam, Elan, Noel) signed off 2026-06-25.

1 file changed, 80 insertions(+), 30 deletions(-)
  ONLY file touched: PROJECT/2-WORKING/v1.2/V1.2-DECISIONS-FILE-2026-06-22.md
```

Key diff content (paraphrased from the unified diff):

- **§2.1 Holdout** changed from *Incremental* (Black Crow held constant in BOTH arms;
  treatment = Black Crow + LTVera, control = Black Crow alone; delta = LTVera's *incremental*
  lift over the incumbent) → **Option A Merchant-Mediated** (treatment = LTVera-recommended
  customers the merchant targets in Klaviyo; control = held-out, no campaign). Sam owns list
  generation, window design, post-period analysis. Merchant cooperation required.
- **§2.2 Measurement tenant** changed from a Bloomz-probe-conditional choice (no predictive
  vendor → Bloomz; runs one → Bounce) → **Binoid confirmed**. Rationale: Bloomz probe found a
  confound (3 live cross-sell/replenishment flows); Bounce has Black Crow + a read-only Klaviyo
  key needing re-key. Binoid: no incumbent cross-sell, write-scoped, 395,000+ customers, BQ
  source. New text: "The Binoid lift number measures LTVera against no incumbent system — the
  largest and most attributable number for investors."
- The ORIGINAL §2.1 text (now removed) explicitly warned: "Pausing Black Crow measures 'LTVera
  vs. nothing,' **overstates LTVera's value**, and costs the client real revenue."
- **§4.1** changed from "Live Klaviyo Writes in v1.2 — Confirmed" → "V1.2 Scope — Read-Only
  Recommendations." No automated Klaviyo API writes in v1.2; automated activation (P22.5) moves
  to V1.3. Table: S1/S4/S5 = ✅ Landed (`de26630`); S2 (write-path membership check) and CC1/CC3
  (activation-worker double-write guard) = ➡ Move to V1.3 gate.
- The 9-step go-live gate is relabeled "this gate sequence moves to V1.3"; steps 2, 5, 9 ticked.

## 2. Evidence — git history of the OTHER two docs (build plan + SWE notes)

These two files were NOT touched by ad1726f. Their last commits:

```
62916e3  2026-06-24  docs(v1.2): deploy record §3c.2 — activation-gate blockers shipped to prod (3e332c1)
6079cf2  2026-06-23  docs(v1.2): mark S2 + CC1/CC3 landed + DB-verified; gate steps 2/3/4 ticked
741c380  2026-06-23  docs(v1.2): absorb Sam Q1-Q4 answers; 9-step gate; flag Q5 still open
```

So: S2 + CC1/CC3 were marked **landed + DB-verified** on 2026-06-23, and the activation-gate
blockers were **shipped to prod** (commit 3e332c1) on 2026-06-24 — i.e. ONE DAY BEFORE the
2026-06-25 revision reclassified those same items as "moves to V1.3."

Grep of `V1.2-BUILD-SWE-INTERNAL.md` still asserts the OLD design: "hold Black Crow constant in
BOTH arms," the Bloomz probe "points to Bounce, not Binoid per Sam's rule," and P22.5 activation
wiring described as in-scope. Binoid is BQ-only (0 Postgres products) with noted caveats:
per-tenant cluster source, recompute scheduling, OOS-exclusion empty for pure-BQ.

---

## 3. The analysis to verify (Claude's claims)

**Claim A — Magnitude:** The change is **major as a product/decision** but **minor (net-negative)
as engineering lift**. The two come apart: it redefines what V1.2 is, defers a whole subsystem
(the write path) to V1.3, swaps the measurement tenant, and changes what the investor number
means — but it adds ~no new build and instead removes write-path hardening from V1.2's critical
path.

**Claim B — Engineering lift:** New build ≈ none (read-only feed = P22 scorer + P26 readout,
already largely in place). Removed from V1.2: activation FSM, test-profile write+revert, Klaviyo
flow wiring, suppression sign-off, finishing S2/CC1/CC3. Small NEW work created: reconcile the
build plan + SWE notes to new scope, and verify prod isn't left with a live write path and
nothing feeding it (possibly quarantine the shipped activation worker). "An afternoon, not a
sprint."

**Claim C — Savings are sunk, not banked:** Because S2/CC1/CC3 + the activation worker already
shipped (06-23/06-24), the deferral doesn't save that effort — it was already paid.

**Claim D — Measurement lift meaning changed:** The reported lift is now purchase-rate + AOV
delta between treatment and held-out control on Binoid — an **absolute lift vs. doing nothing**,
NOT the incremental-vs-Black-Crow figure the original §2.1 was built to produce. Claude flagged
this is the *same* "LTVera vs nothing" measurement the old doc warned "overstates LTVera's value,"
now reframed as a feature.

**Claim E — Doc drift:** The commit updated only the decisions file, so the build plan and SWE
notes now contradict the design of record and need reconciling.

---

## 4. Your task

For EACH claim A–E: mark **CONFIRM / PARTIAL / CHALLENGE**, with a one-line reason grounded in
the evidence above. Then give an overall verdict: is "major decision / minor engineering lift" a
fair characterization? Flag anything Claude got wrong, overstated, or missed. Keep it tight.
