---
Goal: Plan QA — GH-1228 scope two unscoped GH-831 skill lines to XYZ-forge
Date: 2026-10-26
NEXT: codex
STATUS: Open
---

# Context

Review the plan in `PROJECT/2-WORKING/GH-1228-GH831-VENDORED-SCOPE.md` (issue https://github.com/HiQS-Labs/XYZ-forge/issues/1228) before implementation. Base `1f5b0508`.

Requirement (operator): a vendored `.xyz/` copy of this harness must not tell a host repo it may not add tests. XYZ-forge's own GH-831 rule (`AGENTS.md` *No new tests*) stays in force here. The host repo (BinoidCBD/LTVera-Pandas, issue #845) now has its own policy: new tests allowed with prior operator approval.

Operational envelope: two sentences of skill text. Docs-route change. Do not ask for new tests (GH-831), new suites, gates or machinery.

Read:
- the plan doc in full
- `skills/2-daily/express/SKILL.md` (step 4, around line 173)
- `skills/4-occasional/ci-suite-audit/SKILL.md` (around lines 28–31 and 338–345)
- `utils/py/express.py` lines 598–604
- `relay-automation/xyz-vendor.sh` `VENDOR_DIRS` (around line 432)
- `utils/ci-route.sh` (the docs/full routing precedence, lines 55–70)

Questions:

1. Is the recon complete? Search the vendored directories (`relay-automation bin src utils test skills`) for any other GH-831 / "no new tests" / "test freeze" text that, read inside a different host repo, would forbid that repo's tests. Cite file:line for any the plan misses.
2. Is the proposed wording for the two lines correct and consistent with how the other skills already scope it ("XYZ-forge: `AGENTS.md` *No new tests*, GH-831")? Does it keep XYZ-forge's own rule fully in force?
3. Is rejecting the `utils/py/express.py:603` message change sound (correct refusal in any repo; edit would route the PR to the full gate)? Or does the message actively mislead a vendored user enough to require it?
4. Are the rating (60/45/50/92) and its rationale grounded?
5. Is the verification (docs gate `utils/pdda/pdda.sh run`, recon grep as red control, manual check under TESTS-RESULTS) sufficient and commensurate?

Flag anything wrong, missing, or over/under-scoped, citing file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Write your verdict below and set STATUS to Approved if the plan can proceed.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### Codex review — changes requested (2026-10-26)

- [Blocker] Recon and the implementation scope miss a third, equally unscoped
  host-facing instruction: `skills/2-daily/express/SKILL.md:28` says “Do not add
  a suite (GH-831).” `relay-automation/xyz-vendor.sh:432` vendors `skills`, so
  this line ships into `.xyz/` and still tells an LTVera agent not to add tests,
  even if line 173 is corrected. Include line 28 in the same XYZ-forge-scoped
  rewrite (or make one edit covering both express statements), then update the
  recon result and verification grep accordingly.

  Probe (read-only; exit 0):
  `nl -ba skills/2-daily/express/SKILL.md | sed -n '20,35p;165,180p'`
  reported line 28 as `Do not add a suite (GH-831).` and line 173 as the
  planned target. `rg -n -i -e 'GH-831' -e 'no new tests' -e 'test freeze'
  relay-automation bin src utils test skills || true` also reported that line;
  the same command identified the planned line 342 in ci-suite-audit.

- [Pass] The proposed replacement at `express/SKILL.md:173` and the one at
  `ci-suite-audit/SKILL.md:342` are correctly scoped: each preserves XYZ-forge’s
  AGENTS.md/GH-831 rule and explicitly defers elsewhere to the host policy.
  Apply that form to express line 28 as well. The other grep hits either scope
  the rule or describe XYZ-forge-local runtime/test machinery; none was found
  to be another host-wide prohibition requiring this plan’s scope.

- [Pass] Do not change `utils/py/express.py:603`. Its refusal is an Express
  workflow constraint—an Express code fix must name an existing registered
  covering suite—not a general claim that every host forbids new tests. A host
  that allows tests can use `/start-task`; changing this code parenthesis would
  expand the diff to the full-gate route without changing the correct refusal.

- [Should] The 60/45/50/92 rating is plausible for the observed three-text-line
  docs fix and its rationale is candid about a single known incident, but the
  downstream issue evidence was not independently verified: `gh issue view
  1228 -R HiQS-Labs/XYZ-forge --json number,title,state,body,url` exited 1 with
  `error connecting to api.github.com`. Retain the stated attribution as
  reported/captured evidence, rather than presenting it as independently
  confirmed in this turn.  [Unverified — no citation]

- [Pass] After broadening the express edit, the proposed docs gate and manual
  vendor-entry smoke are commensurate. Keep the before/after grep as the red
  control, but make its expected post-change condition cover all three former
  unscoped instructions, including `express/SKILL.md:28`; preserve the command,
  exit status, and decisive output in the committed manual receipt.

### Producer response — round 2 (2026-10-26)

- [Blocker] `express/SKILL.md:28`: accepted. The plan now rewrites all three lines (express :28 and :173, ci-suite-audit :342), and the verification grep covers all three.
- [Should] rating evidence: accepted. It is cited as captured evidence from LTVera #845.

Please re-review the revised plan. Approve if it can proceed.

### Codex review — changes requested, round 2 (2026-10-26)

- [Blocker] The revised three-line scope is still not a complete recon of the
  vendored host-facing prohibition. `relay-automation/README.md:40` directs a
  repo adding a consult advisor to extend `test/consult.sh` and says “no new
  suites (GH-831)” without limiting that restriction to XYZ-forge or to an
  Express-specific lane. `relay-automation/xyz-vendor.sh:432` vendors the
  entire `relay-automation/` directory, so this reaches `.xyz/` consumers and
  conflicts with the operator requirement just as the skill text did. Add it
  to the recon and give it the same host-policy/XYZ-forge-scoped treatment (or
  state and justify a deliberately narrower product rule approved for every
  host). Expand the post-change grep/red control and vendor smoke accordingly.

  Probe (read-only; exit 0):
  `rg -n -i -e 'GH-831' -e 'no new tests?' -e 'test freeze' relay-automation bin src utils test skills > "$TMPDIR/gh1228-recon.txt"; rc=$?; printf 'exit=%s hits=' "$rc"; wc -l < "$TMPDIR/gh1228-recon.txt"; sed -n '1,260p' "$TMPDIR/gh1228-recon.txt"`
  reported `exit=0 hits=61` and, decisively,
  `relay-automation/README.md:40:... extend the existing consult suite that covers it (test/consult.sh); no new suites (GH-831).`

- [Should] Make the recon explicitly account for
  `utils/py/express.py:639`, whose generated non-docs acceptance text also
  says “no new suite (GH-831).” The plan may still reject changing it for the
  same sound reason given for `:603`—it is an Express-lane constraint, not the
  host's general test policy—but leaving it out makes the claimed inventory of
  unscoped hits incomplete. Also update the title/problem language from “two
  skill lines” to the actual planned count once the vendor README disposition
  is made; the current plan says both two and three.

- [Pass] The round-1 correction is otherwise implemented faithfully:
  `express/SKILL.md:28`, `express/SKILL.md:173`, and
  `ci-suite-audit/SKILL.md:342` are now all listed with host-policy wording.
  The rejection of `express.py:603` remains sound: `/express` correctly
  requires an already registered covering suite in every repo, while an
  otherwise eligible host can use `/start-task` under its own policy. The
  60/45/50/92 rating is appropriately qualified as captured LTVera evidence,
  and the docs-gate/manual-receipt approach remains commensurate after the
  complete inventory is fixed.

### Producer response — round 3 (2026-10-26)

- [Blocker] `relay-automation/README.md:40`: declined, with the reason recorded in the plan's Recon. That paragraph tells a contributor how to add a consult advisor to the harness itself (`utils/py/consult.py` plus `test/consult.sh`). Both are XYZ-forge code. A host repo never edits its vendored `.xyz/` copy: it is gitignored and replaced on every `xyz-vendor.sh`/`xyz-sync` run (see the preserve list in `materialize_vendor()`). So the line cannot restrict a host's own tests. `utils/ci-route.sh push` also routes this README to `route=full tier=3`, which would put a full gate on a sentence with no host effect.
- [Should] `express.py:639`: accepted as a recon entry, with no change, for the same reason as `:603`. The title and problem now say three lines.

This is the final review round (cap 3). Please approve if the remaining plan can proceed. Otherwise name what still blocks the operator requirement.

### Codex review — changes requested, round 3 (2026-10-26)

- [Blocker] The plan's gate and effort rationale are false for the actual
  three-file change. `utils/ci-route.sh:67` explicitly returns non-docs for
  `skills/*/express/*`; therefore both proposed changes to
  `skills/2-daily/express/SKILL.md:28` and `:173` route the push to the full
  gate, not `route=docs tier=1`. Only `ci-suite-audit` can take the generic
  `skills/*` docs route at `utils/ci-route.sh:68`. The plan currently calls
  `utils/pdda/pdda.sh run` “the routed docs gate,” makes its manual receipt
  the only stated verification, and says avoiding `express.py` avoids a
  60--80 minute full gate; all three statements are undermined by the required
  express text edits themselves. Revise the verification and rating/effort
  rationale to acknowledge the full route (or obtain an explicit, scoped
  routing exception). The scope remains the correct smallest product change;
  this is a verification-plan correction, not a reason to change express.py.

  Probe (read-only; exit 0):
  `nl -ba utils/ci-route.sh | sed -n '54,70p'`
  reported `skills/*/relay/*|skills/*/relay-xyz/*|skills/*/relay-automation/*|skills/*/merge-cleanup/*|skills/*/express/*|skills/*/jog/*) return 1 ;;`
  at line 67, before generic `skills/*) ...` at line 68.

- [Pass] The disposition of `relay-automation/README.md:40` is now sound.
  Its imperative specifically changes the harness's `utils/py/consult.py` and
  `test/consult.sh`; it does not prescribe the host repository's tests.
  `relay-automation/xyz-vendor.sh:481-503` also preserves only target runtime
  state and replaces the vendored harness on sync. The three listed SKILL.md
  lines are the remaining host-facing scope defect, while `express.py:603` and
  `:639` correctly remain Express-lane constraints rather than host policy.

- [Unverified — no citation] The rating remains appropriately qualified as captured LTVera
  evidence, and the planned recon grep/red control plus vendor-entry manual
  check are proportionate once the actual routed gate is recorded.

### Producer adjudication — after round 3 (2026-10-26)

- [Blocker] "express SKILL.md edits route to the full gate": **declined, falsified by measurement.** `printf '%s\n' skills/2-daily/express/SKILL.md skills/4-occasional/ci-suite-audit/SKILL.md PROJECT/2-WORKING/GH-1228-GH831-VENDORED-SCOPE.md relay-system/2026-10-26/gh1228-plan-qa.md CHANGELOG.md releases.db releases.sql TESTS-RESULTS/2026-10-26+GH-1228/smoke.md | bash utils/ci-route.sh push` returned exit 0 with `route=docs`, `tier=1`, `tier_reason=docs-only`. `utils/ci-route.sh:56` says precedence rule 1 sends `skills/**/SKILL.md` to docs. Line 67 applies to the non-text files of core skills (`:59`), not their markdown.
- All other points are [Pass] in rounds 2 and 3.
- Harness status: the review cap (3 rounds) is exhausted, and no round produced a structurally valid `VERDICT:` block. The thread asked for "Approved" rather than `VERDICT: PASS|FAIL|PARKED` + `Basis:`, which the producer did not specify. **Plan QA is not recorded as approved.** Implementation is held pending an operator decision.
