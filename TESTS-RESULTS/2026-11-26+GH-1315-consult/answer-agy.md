### (1) ANSWER

**Finding 1 is real, worse at pinned `HEAD` than the reviewer saw (72 nested duplicate files across two recursive levels, not 36), and blocking; Finding 2 is factually false at pinned `HEAD` (15 rows exist, including both post-packet receipts) and non-blocking.** The `sync.py` fix itself (`skills/3-weekly/skills-army-hq/scripts/sync.py:283-286`) is clean and verified. Both findings stemmed from two directory-allowlist bugs in `relay-automation/relay-turn-lib.sh`, not from builder negligence.

---

### (2) GRADED FINDINGS

#### Finding 1 — `[Blocker]` Recursive nested duplicate directory in `TESTS-RESULTS/2026-11-25+GH-1315/`

* **(a) Factually correct at pinned `HEAD` (`7f61d64d4`)?** **Yes — and doubled.** At `e6d89792c` (the commit `agy` reviewed), one nested copy existed (36 files). Escalation commit `40d32085e` swept in a second recursive copy from attempt 2, leaving **two** nested levels and **72** stale/conflicting files committed at `7f61d64d4` (depth 1 holds a stale 13-row `provenance.jsonl`; depth 2 holds a stale 11-row `provenance.jsonl` and the old `git`-based `readiness_probe.py`).
  * **Root cause (for context):** `relay-automation/relay-turn-lib.sh:784` runs `cp -R "$RTL_ROOT/$a" "$wt/$a"` when `$wt/$a` already exists as a directory, nesting `2026-11-25+GH-1315` inside itself on every isolated builder turn.
  * **Evidence command & output:**
    ```text
    $ find TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315 -type f | wc -l && \
      find TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315/2026-11-25+GH-1315 -type f | wc -l && \
      git diff --name-status a54cfabe4a4edab4dfe8d933ee0db89a22be7874 HEAD -- TESTS-RESULTS/ | cut -f1 | sort | uniq -c
          72
          36
      72 A
       2 M
    ```
    ```text
    $ shasum -a 256 TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py \
      TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315/readiness_probe.py \
      TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315/2026-11-25+GH-1315/readiness_probe.py
    fbb1122d6991310bbdd587aae76350b37ef6399fcc7f11624a636adf0dc52d43  TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py
    fbb1122d6991310bbdd587aae76350b37ef6399fcc7f11624a636adf0dc52d43  TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315/readiness_probe.py
    b449acfdcd94a8c94b536e7137d3999da86a0b095075527b93dff8e20ac66c41  TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315/2026-11-25+GH-1315/readiness_probe.py
    ```
* **(b) Blocking for the #1315 PR?** **Yes.** Merging `a54cfabe4..HEAD` as-is would commit 72 garbage duplicate files (including two conflicting older `provenance.jsonl` files and an outdated `readiness_probe.py`) into `TESTS-RESULTS/2026-11-25+GH-1315/`, violating `TESTS-RESULTS/README.md:11-20` and polluting the evidence tree.
* **(c) Smallest repair:** Remove the nested subtree in one commit (`git rm -r TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315`) and confirm `find TESTS-RESULTS/2026-11-25+GH-1315 -maxdepth 2 -name '2026-11-25+GH-1315'` prints nothing. (Track the `relay-turn-lib.sh:784` seeding bug separately outside #1315.)

#### Finding 2 — `[Pass]` Claimed two fresh receipts in `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl`

* **(a) Factually correct at pinned `HEAD` (`7f61d64d4`)?** **No — superseded by commit `40d32085e`.** At `7f61d64d4`, top-level `TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl` has **15 lines**, not 13: lines 14–15 (`relay-cli-red-control` exit `1`, `relay-cli-candidate` exit `0`) are stamped `2026-11-26T17:45:28Z` (after packet generation at `2026-11-26T17:43:29Z`, `marathon-system/gh-1315-legacy-preview-parity/RELAY.md:11`) and match the exact SHA-256 digests of `sync.py` (`68955508...`) and `readiness_probe.py` (`fbb1122d...`).
  * **Why `agy` saw 13 lines:** `relay-automation/relay-turn-lib.sh:1633` filters staged files with `grep -qxF "$_ap" <<<"$_staged"`, which never matches a directory entry (`TESTS-RESULTS/2026-11-25+GH-1315`) against file paths returned by `git diff --cached --name-only`. So Codex's turn commit `b72c50122` committed only `RELAY.md` while leaving `provenance.jsonl` staged in `RTL_ROOT`; `agy`'s worktree cut at `b72c50122` saw only 13 lines, and escalation commit `40d32085e` then committed lines 14–15 into `HEAD`.
  * **Evidence command & output:**
    ```text
    $ git show e6d89792c:TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl | wc -l && \
      git show 7f61d64d4:TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl | wc -l && \
      python3 -c 'import json,pathlib; [print(f"L{i}: at={d.get(\"at\")} kind={d.get(\"kind\")} exit={d.get(\"exit_code\")} sha256={str(d.get(\"source_sha256\"))[:12]}") for i,d in enumerate((json.loads(l) for l in pathlib.Path("TESTS-RESULTS/2026-11-25+GH-1315/provenance.jsonl").read_text().splitlines()),1) if i>=12]'
          13
          15
    L12: at=2026-11-26T17:20:36Z kind=relay-cli-before exit=1 sha256=562b41117410
    L13: at=2026-11-26T17:20:36Z kind=relay-cli-after exit=0 sha256=689555085d1c
    L14: at=2026-11-26T17:45:28Z kind=relay-cli-red-control exit=1 sha256=562b41117410
    L15: at=2026-11-26T17:45:28Z kind=relay-cli-candidate exit=0 sha256=689555085d1c
    ```
    ```text
    $ shasum -a 256 skills/3-weekly/skills-army-hq/scripts/sync.py TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py
    689555085d1c4f8e4a573ab7cdd417c3390fb829cee94cae4c76f153b6970960  skills/3-weekly/skills-army-hq/scripts/sync.py
    fbb1122d6991310bbdd587aae76350b37ef6399fcc7f11624a636adf0dc52d43  TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py
    ```
* **(b) Blocking for the #1315 PR?** **No.** Top-level `provenance.jsonl` accurately retains both attempt 1 (`L12-13`) and attempt 2 (`L14-15`) hash-bound receipts matching disk.
* **(c) Smallest repair:** None needed on `provenance.jsonl` for #1315 (file the `relay-turn-lib.sh:1633` directory-pathspec commit bug separately).

#### Code & Readiness Probe — `[Pass]`

* `skills/3-weekly/skills-army-hq/scripts/sync.py:283-286` adds the minimal 4-line `shared.require(name in state["skills"], ...)` guard before `retire_legacy()`, and `python3 -B TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py` exits `0` (`unadopted legacy migration is refused by preview and apply (adoption remedy named); no backup ZIP, staging directory or link; recorded-skill preview and apply unchanged`). Note that the harness gate `bash test/skills-army-hq.sh` (with pytest available) still shows `gate: not-run` (`marathon-system/gh-1315-legacy-preview-parity/ESCALATION.md:7`) and must run in a disposable clone before PR merge.

---

### (3) RECOMMENDATION

Delete `TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315/`, run the `bash test/skills-army-hq.sh` gate (with pytest) in a disposable clone, keep `sync.py` and the 15-line top-level `provenance.jsonl` as-is, and open the #1315 PR (filing the two `relay-turn-lib.sh` directory-allowlist bugs separately).

`CONSULT: FINDINGS-REAL-REPAIR-NEEDED`
Finding 1 is real and blocking at pinned `HEAD` `7f61d64d4` because escalation commit `40d32085e` doubled the recursive duplicate tree to 72 stale/conflicting files under `TESTS-RESULTS/2026-11-25+GH-1315/2026-11-25+GH-1315/` that must be deleted before opening a PR. Finding 2 is already satisfied at `HEAD` (lines 14–15 are committed and hash-matched; `agy` only missed them because `relay-turn-lib.sh:1633` failed to commit directory-allowlist edits on the builder turn), so removing the nested directory and running the deferred harness gate is all the repair #1315 needs.
