# Run 4 — feedback relay: paste prompts for Codex + Gemini

Single round trip. Paste the **Codex** prompt into the Codex window first; when it's
done and committed, paste the **Gemini** prompt into the Gemini window. Then tell me
"feedback's in" and I'll fold it into the Run-4 record and close the relay.

Run from repo root: `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm`

---

## PROMPT FOR CODEX (paste verbatim)

```
You're giving feedback on the Run-4 parallel build you just did, via a file-based
relay. Do exactly this:

1. Read the whole file: relay-system/2026-06-14/run4-feedback.md
2. Confirm NEXT is "Codex". If it isn't, STOP and tell the operator.
3. Append ONE block at the very bottom, directly ABOVE the marker line
   (<!-- ↓↓↓ NEXT TURN GOES ABOVE THIS LINE ... -->), answering the four
   Questions in the file. Use this exact format:

### Round 1 · Reviewer · Codex · <today's date + time>
**1. Prompt clarity:** <your answer>
**2. Friction:** <your answer>
**3. Protocol:** <your answer>
**4. One fix:** <your answer>
**Commit:** <fill after committing>

4. Be candid — honest friction is the point, not praise. Bullets are fine.
5. Do NOT edit any earlier block or any other file.
6. At the top of the file, change "NEXT: Codex" to "NEXT: Gemini".
7. Commit just this file:
   git add relay-system/2026-06-14/run4-feedback.md
   git commit -m "relay(run4-feedback): Codex r1"
   then put the short hash in your block's Commit: line and commit that with --amend.
8. Stop. Tell the operator to paste the Gemini prompt next.
```

---

## PROMPT FOR GEMINI (paste verbatim — after Codex is done)

```
You're giving feedback on the Run-4 parallel build you just did, via a file-based
relay. Do exactly this:

1. Read the whole file: relay-system/2026-06-14/run4-feedback.md
2. Confirm NEXT is "Gemini". If it isn't, STOP and tell the operator.
3. Append ONE block at the very bottom, directly ABOVE the marker line
   (<!-- ↓↓↓ NEXT TURN GOES ABOVE THIS LINE ... -->), answering the four
   Questions in the file. Use this exact format:

### Round 1 · Reviewer · Gemini · <today's date + time>
**1. Prompt clarity:** <your answer>
**2. Friction:** <your answer>
**3. Protocol:** <your answer>
**4. One fix:** <your answer>
**Commit:** <fill after committing>

4. Be candid — honest friction is the point, not praise. Bullets are fine.
5. Do NOT edit any earlier block or any other file.
6. At the top of the file, change "NEXT: Gemini" to "NEXT: Producer".
7. Commit just this file:
   git add relay-system/2026-06-14/run4-feedback.md
   git commit -m "relay(run4-feedback): Gemini r1"
   then put the short hash in your block's Commit: line and commit that with --amend.
8. Stop. Tell the operator feedback is complete — Claude-B (Producer) takes the
   final turn.
```
