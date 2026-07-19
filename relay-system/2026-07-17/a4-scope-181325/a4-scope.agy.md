**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (agy's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

### ANSWER
Ship the 2-category (v0) collapse for the first implementation pass. Under Principle 7 ("least code that clears the bar", `GUIDING-PRINCIPLES.md:34`) and the proposal's own honest assessment (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:256-261`), the full 4-category taxonomy introduces too much unproven surface area. The shipped mechanism's core blind spot (`consult.sh:310-336`) is that it accepts prompt-echoed citations as independent verification. The v0 split (ECHOED vs. FIRSTHAND) directly closes this exact gap by adding one new substring test on top of the existing `RTL_CITATION_RE` logic (`relay-turn-lib.sh:676`), delivering the bulk of A4's value durably without the risk of grading uncited prose. 

### FINDINGS
- **[Blocker]** Implementing the 4-category v1 right now. Splitting INFERENCE from UNSUPPORTED-ASSERTED requires fuzzy-matching claim prose against the prompt (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:91-92`), which introduces significant false-positive risk and complexity before the basic prompt-persistence plumbing is even proven on real data.
- **[Should]** Implement the 2-category v0 pass. It cleanly extends the existing `rtl_has_uncited_claim()` (`relay-turn-lib.sh:714-744`) by applying a strict substring check only on already-detected citation strings. This minimizes risk and perfectly satisfies the "new relay path vs. reuse" tie-breaker (`GUIDING-PRINCIPLES.md:108`).
- **[Pass]** The single highest-risk failure mode of the v0 scope is a false-negative caused by whitespace, punctuation, or casing modifications: if the advisor echoes a cited span from the prompt but slightly alters the formatting, a naive string match will fail, letting an ECHOED claim slip through and falsely be marked as FIRSTHAND.

### RECOMMENDATION
Ship the 2-category v0 first to close the prompt-echo loophole using a simple citation substring match, explicitly deferring the riskier fuzzy-matching taxonomy until the new plumbing is proven.
