**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (kimi's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

kimi version 2.6.3
• Let me start by reading the referenced files to understand the situation. The consult question is about judging a preparation packet for issue #1638 in XYZ-forge. Let me read the key files:

  1. `relay-system/2026-11-27/gh1658-runA-prep-qa.md` — full review thread
  2. `PROJECT/1-INBOX/GH-1638-RELAY-SEED-DIR-NESTING.md` — capture
  3. `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1638.sh`
  4. `sim-gh1638.patch`
  5. `fake*-gh1638*.patch`, `matrix.txt`, `preflight-arms.txt`, `pkg-freshness-arms.txt`, `SUMMARY.md`
  6. Source seam: `relay-automation/relay-turn-lib.sh` lines 722-830, `utils/py/rtl.py:1156-1161`, `WORKTREE-SAFETY.md`

  Let me read these files in parallel.

• I'll read the review thread, capture, and packet artifacts first.

• Now let me read the packet evidence: the probe readable copy, sim-gh1638.patch, the fakes, matrix.txt, preflight-arms.txt, pkg-freshness-arms.txt, SUMMARY.md, and WORKTREE-SAFETY.md.

• Now the packet evidence: probe, patches, matrix, arms, summary.

• Interesting. Matrix line 11: `GH-1638 sim-gh1638 rc=1 rtl_worktree_begin: seed seeded: could not clear the checkout copy`. That's the source-only arm failing the package check... wait, no — the probe arm 3: rm shadowed to refuse paths ending in /seeded. The sim without the package fails the package check first? No — the probe would fail at arm... hmm, actually matrix line 11 shows the source-only sim failing with "could not clear the checkout copy" — that's arm 3's message? Actually no: fail messages include "relay-pkg.tar.gz does not carry the live relay-turn-lib.sh" for the source-only arm. The message shown for sim-gh1638 (source only) is "seed seeded: could not clear the checkout copy" — hmm, that's from arm 3? Wait — arm 3 fails with "uncleared checkout copy still reported a seed". The stderr from the inner bash shows "rtl_worktree_begin: seed seeded: could not clear the checkout copy" — that's the stderr printed by the simulated fix's abort helper, which is expected on arm 3 (the rm is shadowed to refuse). Since `st` accumulates, the last failing message... actually fail() writes to stderr and sets st=1. The matrix records the last failure message? Or the first? The message recorded is the last `fail` call that fired, I think, since each fail overwrites... no, each fail appends to stderr. The matrix captured only the last line? It records "stderr" — probably the last fail message or the decisive one. Whatever — for sim-gh1638 (without pkg), the package check fails → "relay-pkg.tar.gz does not carry the live relay-turn-lib.sh" should be one message, and other arms might also produce messages. The recorded message "seed seeded: could not clear the checkout copy" is the stderr of the inner shell in arm 3, not a fail() message. Fine.

  Wait, actually there's something important: matrix line 11 says sim-gh1638 (source-only) rc=1 with that message. rc=1 is expected for source-only (package drift). But hold on — the source-only sim must still pass arms 1-6 behaviorally. The message suggests arm 3's inner shell printed the abort message (expected). OK.

  Now key things to verify:

  1. Does the revised sim resolve the round-4 Blocker?
     - (a) containment of the deepest existing ancestor proven before any `mkdir -p`: In sim-gh1638.patch lines 30-43: it resolves `_wtp` (worktree physical), then `_anc="$wt/$(dirname "$a")"` and walks up with `dirname` until an existing path or symlink, resolves it physically, and requires it inside `$_wtp`. This happens BEFORE `mkdir -p "$wt/$(dirname "$a")"` (line 41). Yes — the ancestor check precedes the mkdir. Then after mkdir, it re-resolves the parent and re-checks containment, and computes `_dst="$_par/$(basename "$a")"`.
     - But wait — there's a subtlety. The `..` lexical guard at line 32: `case "/$a/" in */../*|*/./*|*//*)`. For `a="parent/new/seeded"`, `/$a/` = `/parent/new/seeded/` — no match, good. For `a="x/../../outside6/seeded"`, `/$a/` = `/x/../../outside6/seeded/` — matches `*/../*`, refused. Good — that's arm 6.
     - However: does the ancestor-walk handle the `..` case anyway even without the lexical guard? The ancestor walk starts at `$wt/$(dirname "$a")`. For `a="x/../../outside6/seeded"`, dirname is `x/../../outside6`. `$wt/x/../../outside6` — `[[ -e ... ]]`... path resolution with `..` — `-e` on a path containing `..` resolves lexically through the filesystem; `$wt/x/../../outside6` = `$TMPDIR/outside6` (wt is directly under $T/wt6). Hmm wait — in arm 6, wt6 is `$T/wt6`, and `outside6` is `$T/outside6`. So `$wt/x/../../outside6` = `$T/wt6/rtl-wt.XXX/x/../../outside6`. If `$wt/x` doesn't exist... the walk: `while [[ ! -e "$_anc" && ! -L "$_anc" ]]; do _anc="$(dirname "$_anc")"; done`. `-e` with a nonexistent intermediate `x` returns false even with `..` afterwards. Walk goes: `$wt/x/../../outside6` → dirname → `$wt/x/../..` → dirname → `$wt/x/..` → `-e`? `$wt/x/..` — x doesn't exist so false → dirname → `$wt/x` → false → dirname → `$wt` → true. So `_anc=$wt`, inside worktree — passes. Then `mkdir -p "$wt/x/../../outside6"` creates `$T/outside6`? No — outside6 already exists in arm 6. Then `_par="$(cd "$wt/x/../../outside6" && pwd -P)"` = `$T/outside6` — wait, `$wt/x/../../outside6` resolves to `$T/outside6`? `$wt` = `$T/wt6/rtl-wt.XXX`, so `$wt/x/../../outside6` = `$T/wt6/rtl-wt.XXX/x/../../outside6` → `..` cancels rtl-wt.XXX and wt6 partially: `rtl-wt.XXX/x/..` = `rtl-wt.XXX`, `/..` = `wt6`... so `$T/wt6/outside6`. Hmm wait: `$T/wt6/rtl-wt.XXX/x/../../outside6`: start at rtl-wt.XXX, go into x (created by mkdir -p), then `..` → rtl-wt.XXX, then `..` → wt6, then outside6. So `$T/wt6/outside6`. But arm 6 put outside6 at `$T/outside6`, and the probe checks `[ ! -e "$T/wt6/outside6" ]`. Interesting — so with a `..` traversal of 2 from a 1-deep parent... the host side `$R6/x` exists so `RTL_ROOT/$a` = `$R6/x/../../outside6/seeded` = resolves through the repo: `$R6/x/../..` = parent of $R6 = `$T`, so `$T/outside6/seeded` — exists. So the copy source exists.
     
     Anyway, the lexical guard refuses `..` before any of this, and fake5 (without the guard) fails on arm 6 per matrix line 17. Good.

     - (b) teardown on failure: `_rtl_seed_abort` uses `git -C "$RTL_ROOT" worktree remove --force "$1"` only; if it fails, prints "git worktree remove refused ... left in place for inspection". No raw `rm -rf "$wt"`. The `rm -rf "$_dst"` is the destination directory inside the worktree — that's allowed (the falsifier says "no raw rm -rf of the worktree"). The destination removal is fine as long as containment is proven. The abort helper is called for all failure paths: bad segments, ancestor outside, mkdir failure, parent resolution outside, dst clear failure, copy failure. Good.

     Wait — one more check on (a): "containment of the deepest existing ancestor is proven before any `mkdir -p`". In the sim, order: lexical guard → resolve wt → find ancestor (walk up from `$wt/$(dirname "$a")` to deepest existing) → resolve ancestor physically → check inside `_wtp` → THEN mkdir -p → re-resolve parent → check `_par` inside `_wtp` → compute `_dst` → clear dst → copy. Yes, the deepest existing ancestor containment check precedes mkdir. The round-4 replay had the checkout `parent` as a tracked symlink to outside; the walk finds `$_anc = $wt/parent` (a symlink, `-L` true, loop stops), `cd ... && pwd -P` resolves through the symlink to `$O` (physical), which is not inside `$_wtp` → abort before mkdir. And mkdir -p with the parent being a symlink: `mkdir -p "$wt/parent/new"` would create `$O/new` — that's what the old fake4 did. Now refused. Good.

     Now — is there a gap? What about the `rm -rf "$_dst"` — could `_dst` resolve outside? `_dst="$_par/$(basename "$a")"`. `_par` is physically resolved and checked inside `_wtp`. `basename "$a"` — if `a` has no slashes, basename is `a`. Since the lexical guard rejects `/../`, `/. /`, `//` segments, basename can't be `..` or `.` — well, what about `a=".."`? `/$a/` = `/../` matches `*/../*`? `/../` — pattern `*/../*` needs something before /../ and something after. `/../` = `/` + `..` + `/`. `*/../*`: `*` matches empty? The string is `/../`. Pattern `*/../*` — first `*` matches empty, then `/../`... the pattern requires `/..` followed by `/`. In `/../`, after `/..` there is `/`. So `*`="" then `/..` then `/*` matches `/`. Yes it matches. OK refused. `a="."`? `/. /` — pattern `*/./*`: `*`="", `/.` then `/*`? String `/. /` is `/./` — `/.` matches, then `/*` matches `/`. Refused. Good. And empty segment `a=""`? `//$/`... `/$a/` = `//` matches `*//*`. Refused. But would `RTL_ALLOW` ever contain such entries? Doesn't matter — guard exists.

     But hold on: what about an entry like `a="foo/../bar"`? Guard refuses. What about an entry where `dirname` itself needs creation but an intermediate is a symlink created... The walk stops at the deepest existing ancestor — if `parent` exists as a real dir but `parent/new` doesn't, ancestor = `$wt/parent` resolved — fine, then mkdir creates `parent/new` under the real parent. Good.

     What if the ancestor exists but `cd` fails (permission)? Then `_anc=""` → abort. Good.

     Edge: ancestor walk when `$wt/$(dirname "$a")` itself exists but is a FILE (not dir)? E.g. checkout has `parent` as a regular file and entry `parent/new/seeded`. `_anc = $wt/parent` exists (file). `cd "$_anc"` fails (not a dir) → `_anc=""` → abort. Good.

     Edge: `mkdir -p` succeeds but `_par` resolution... `_par` uses `cd` physical; if the created dir is somehow a symlink? mkdir -p on a path where the leaf exists as symlink to outside — but leaf didn't exist before mkdir (if it existed, mkdir -p is a no-op success). Hmm — what if `parent/new` exists as a symlink to outside? Then the ancestor walk: `_anc = $wt/parent/new` exists as symlink (-L true), stop; `cd -P` resolves to outside → not inside → abort. Good, that's the arm-4 shape one level deeper.

     So (a) and (b) look resolved in the sim. Now the probe: does arm 4 test exactly the round-4 replay? Yes — arm 4 in probe-gh1638.sh:62-77 constructs `parent` as tracked symlink to `$O` committed, then replaces it with a real dir `parent/new/seeded` (untracked), host has real dir. Entry `parent/new/seeded`. Expect rc 9 and no path and `$O/new` must not exist. Good. Arm 5 tests refused teardown reported and worktree left. Arm 6 tests `..` entry.

  2. Does the probe discriminate? Matrix lines 10-17:
     - base rc=1 (line 10) — good; message shows arm 6 fired? "a '..' directory entry created a directory outside the worktree" — that's fail from arm 6. Base fails.
     - sim (source-only) rc=1 — package drift check. Good — probe requires the regenerated package.
     - sim-with-pkg rc=0. Good.
     - fake (skip dirs) rc=1: arm 6 fired ("still reported a seed (rc=0)") — because skip-dirs leaves `cp -R src dst` nesting... wait, skip-dirs fake: what is it? Presumably `continue` for directories — so the seeded dir wouldn't be seeded at all. It fails arm 1 (host edit not seeded... actually it would fail "seed did not carry the current content"). But matrix says the recorded message is arm 6's. Multiple fails accumulate; recorded message may be the last one. Fine.
     - fake2 overlay rc=1, fake3 rm-unchecked rc=1, fake4 mkdir-first rc=1, fake5 no-dotdot-guard rc=1 — all red.

     Question 2 also asks: is there a fake fix that would still read fixed while leaving the defect or creating a new containment hole? Let me think hard about this.

     Candidate fakes to consider:
     - A fix that checks containment but uses the LOGICAL path instead of physical (no `pwd -P`), i.e., doesn't resolve symlinks. Then arm 4 (checkout parent symlink → outside): `_anc` = `$wt/parent` logically; without -P, `cd` pwd gives `$wt/parent` (logical) which passes the `$_wtp/*` check. Then `mkdir -p "$wt/parent/new"` → creates `$O/new` outside. Arm 4 catches this (checks `[ ! -e "$O/new" ]`). So caught.
     - A fix that resolves the ancestor but checks containment of the destination only after mkdir without re-resolving? Arm 4 catches since ancestor check would be against logical path. If they resolve ancestor physically, arm 4 passes the check; the remaining hole would be the parent created fresh — a newly created dir can't be a symlink to outside (mkdir creates a real dir, or fails if path exists as symlink... `mkdir -p` on existing symlink-to-dir succeeds as no-op? Actually `mkdir -p existing-symlink-to-dir` exits 0 (it checks -d? Let me think: mkdir -p uses stat; a symlink to a directory satisfies the "exists as directory" check? GNU mkdir -p: if the path exists and is a directory (stat follows symlinks), it succeeds silently. So if the leaf `parent/new` existed as symlink to outside dir, mkdir -p is a no-op and `_par` resolution `cd -P` → outside → abort. But if the fix re-checks with logical cd, it'd pass and then `rm -rf "$_dst"`/`cp -R` writes outside. Is that caught by the probe? Arm 4's fixture has `parent` (the ancestor) as the symlink, resolved at ancestor stage. There's no arm where the ancestor is a real dir but the parent itself is a symlink. But wait — if the parent exists as a symlink, then the parent IS the deepest existing ancestor of... no. The walk starts at `$wt/$(dirname "$a")` = the parent itself. If parent exists (as symlink), the walk stops immediately at the parent. So the "deepest existing ancestor" IS the parent in that case, and resolving it physically catches it. So the mkdir-then-recheck with -P covers the case where parent is created fresh (can't be a symlink then — mkdir -p creates real dirs for missing components... unless a RACE swaps it, out of scope for local tooling).
     - A fake that does `rm -rf "$_dst"` but without checking `$_dst` existence/removal result — fake3 covers ignoring rm failure; caught by arm 3.
     - A fake that uses `git worktree remove` without --force? Teardown of a dirty worktree would fail → reported → left in place. Probe arm 5 shadows git to refuse; fine either way. A fake that on teardown failure falls back to raw rm — arm 5 catches (checks worktree still exists).
     - A fake that seeds correctly for directories but breaks file entries? Arm 1 checks plain.txt seeds p2. Good.
     - A fake that handles the mirror but leaves the SEED-DELETE branch? Out of scope (declared non-goal keeps SEED-DELETE behavior; the issue is about existing directories).
     - A fake that refuses `..` but NOT `.`/empty? Arm 6 uses `..`. Is there an arm with `.` or empty segment? No arm 7 for `./` or empty. A fix that guards only `..` lexically would pass the probe while still accepting `a="sub/./seeded"`? But what's the actual defect with a `.` segment? `sub/./seeded` resolves to `sub/seeded` — no traversal. Empty segment `sub//seeded` same. The danger of `.`/`..` was traversal outside. A lone `.` or empty segment doesn't traverse. The surviving seat's [Should] asked to refuse them; producer folded it in. Missing an arm for `.`/empty is a [Nit] at most — but does a fake that only refuses `..` create a containment hole? `x/../..` contains `..` — refused. `./` alone: harmless. So no hole; just a spec-completeness nit. Actually wait — what about an entry with a trailing slash, `a="seeded/"`? `/$a/` = `/seeded//` matches `*//*` → refused. Baseline: dirname "seeded/" → "."? For file entries unchanged. For a directory entry "seeded/" with the guard refused... would the real fix refuse a trailing-slash entry that the issue would want accepted? RTL_ALLOW entries come from config; do any have trailing slashes? If a real config had `seeded/`, the fixed code would refuse it → begin fails. Is that a false negative? The issue's scope is the seeded dir; typical entries are clean paths. Hmm, but "refuse empty path segments" — a trailing slash produces an empty final segment. Refusing is the conservative choice; a begin-fail is loud, not silent. I'd call it acceptable; maybe a [Nit] that the packet doesn't state whether trailing-slash entries occur in practice. Let me check whether any real allowlist uses trailing slashes... that may be overkill. The probe's arm 1 uses "seeded" and "plain.txt" — the real configs in relay drives use entries like "relay-system", "PROJECT"... probably clean. I'll note it as a nit at most.

     - Bigger question: does the FULL fix as specified create any NEW containment hole? The `_rtl_seed_abort` helper tears down via git only. But note: at abort time during the seed loop, the worktree may contain node_modules copy etc. `git worktree remove --force` handles dirty trees. OK.

     - What about `rm -rf "$_dst"` where `_dst` is `$_par/$(basename "$a")` and `_par` is inside the worktree — but what if `_dst` itself is a symlink to outside? `rm -rf` on a symlink removes the link, not the target (rm -rf does not follow symlinks for removal). Safe. What if `_dst` is a directory containing a symlink to outside? rm -rf removes the tree without following symlinks (removes the link itself). Safe on macOS/BSD rm too. OK.

     - What about `cp -R "$RTL_ROOT/$a" "$_dst"`? Source is host dir; could the source be a symlink to outside? Guard at line 26: `[[ -d "$RTL_ROOT/$a" && ! -L "$RTL_ROOT/$a" ]]` — directory and NOT a symlink. So symlink entries fall to the file branch (unchanged behavior). OK.

     - Hardlink? Out of scope.

     So discrimination looks strong. Now — the probe runs the REAL rtl_worktree_begin from the live library. The sim patch must actually implement the plan. Let me verify the sim matches the plan's described order. One thing to check: plan says "resolve the worktree and the deepest existing ancestor of the entry's parent physically and require that ancestor inside the worktree... only then mkdir -p the parent, resolve it again and require containment; remove an existing destination and confirm it is gone; then cp -R". The sim does exactly this order. 

     Wait, one subtle thing in the sim: `_anc="$wt/$(dirname "$a")"; while [[ ! -e "$_anc" && ! -L "$_anc" ]]; do _anc="$(dirname "$_anc")"; done`. If `$wt` itself... `_anc` eventually becomes `$wt` which exists. What if the loop walks above `$wt`? Only if `$wt` itself doesn't exist — impossible here. But what about `dirname` reducing `/` to `/`? If entry is like `/abs`, but absolute entries are skipped earlier (line 778). OK.

     Another subtlety: `_wtp="$(cd "$wt" && pwd -P)"`. If wt path contains a symlink component (TMPDIR symlink, e.g. macOS /tmp → /private/tmp). `mktemp -d` created it; `cd -P` gives physical. `_anc` resolved with `cd -P` too — both physical, comparison consistent. Good.

     Now, `rm -rf "$_dst" || [[ -e ... ]]`: the construct `if ! rm -rf "$_dst" || [[ -e "$_dst" || -L "$_dst" ]]; then`. Due to `!` binding: `! rm -rf` true when rm fails → abort. If rm succeeds but path still exists → abort. Good — matches "confirm it is gone".

  3. Is scope still one-turn Jog? One seed loop branch + one helper `_rtl_seed_abort` in one file + package regeneration. The hardened version is bigger than the original smallest plan but still a single bounded edit in one file plus make-pkg. It's within commensurate complexity for local dev tooling that does `rm -rf` — the hardening is exactly what the reviewers demanded. I'd say yes, still Jog-sized. The containment logic (~30 lines of Bash) is at the upper end but justifiable: this code path deletes recursively. Alternatively one could argue the whole directory-mirror semantics (delete + re-copy) is inherently destructive and the safe minimal version would be... hmm, there's an argument (ponytail) that the truly minimal safe fix would be different, e.g. copy to temp then swap, or use rsync --delete. But rsync may not exist; cp + rm is fine given containment proven. The packet is fine.

  Let me now check remaining evidence: SUMMARY.md, preflight-arms.txt, pkg-freshness-arms.txt, fake5 patch, and sim-gh1638-with-pkg.patch existence, plus WORKTREE-SAFETY.md lines ~59-79. Also verify the claim "fake5-gh1638-no-dotdot-guard.patch reads unfixed" (matrix line 17 says rc=1).

  Also I should verify the probe actually discriminates by running it? The question says advisory; the first panel's reviewer ran replays. I can run the probe read-only against the BASE tree (unfixed) to confirm base reads unfixed — the envelope in the QA doc allows running the probe read-only. That would strengthen my answer: base must read nonzero. But careful: the probe writes under its own mktemp in TMPDIR. I can run it with TMPDIR set to a scratch dir. The instructions from the thread: `bash TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1638.sh; echo $?`. It writes only under its own mktemp dir and removes it. This is a throwaway copy. Let me run base probe to confirm rc=1 and message. Also maybe run the probe with the sim applied? Applying the sim to the live tree would modify the throwaway copy — allowed (throwaway), but I shouldn't modify repo files... it says "You are ADVISORY ONLY: output your analysis as text; do not rely on writing files". Modifying files in a throwaway copy to verify could be seen as fine, but "do not rely on writing files" — I think they mean the deliverable is text. Running read-only probes is explicitly permitted by the thread. Applying a patch to test the green arm writes files; in a throwaway copy it's harmless, but let me be careful: I could copy relay-turn-lib.sh to a temp location, apply the patch there... Actually the probe hardcodes L="$SRC/relay-automation/relay-turn-lib.sh" relative to $PWD. I could create a scratch dir with copies. That's "writing files" but in temp/throwaway space, not the deliverable. The instruction "do not rely on writing files" means my verdict shouldn't depend on artifacts I write. Verification replays in temp dirs are standard practice and the prior panels did exactly that (in-memory or temp fixtures). I'll do minimal verification: run the base probe (read-only per thread), and possibly an in-memory replay of the sim's seed block with the round-4 hostile fixture to confirm the green arm behaves as claimed.

  Actually, the strongest verification: replicate the round-4 replay against the CURRENT sim-gh1638.patch block (the reviewer’s round-4 replay used patch lines [6:37] excluding '-'; the patch has changed since). And replicate against fake4 to see it fail. Let me write a small python replay in /tmp... The Bash tool writes nothing to the repo if I use mktemp under $TMPDIR. Let me do that.

  Also check WORKTREE-SAFETY.md:59-79 for the Git-managed removal requirement, and the preflight-arms/pkg-freshness-arms files, SUMMARY.md, fake5 patch. Let me read those now.

• I have the thread, capture, seam source, probe, sim and matrix. Now the remaining packet artifacts and WORKTREE-SAFETY.

• I have everything I need on the artifacts. Let me now verify two things live:

  1. Run the base probe read-only to confirm base reads unfixed (rc=1). The thread says this is allowed: `bash TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1638.sh; echo $?` — writes only under its own mktemp in TMPDIR and removes it.

  2. Replicate the round-4 replay against the CURRENT sim-gh1638.patch (the reviewer’s replay used lines [6:37] minus '-'; the patch has since changed), to confirm the escaping-parent fixture now fails cleanly (rc=1, no outside dir, Git-managed teardown attempted, no raw rm of the worktree). And maybe also check the sim's abort path with git shadowed. Let me do the replay in a python heredoc with temp dirs, using the same narrow-replay technique.

  Also I want to check the sim's `case` pattern more carefully for a subtle bug: `case "/$a/" in */../*|*/./*|*//*)`. Consider `a="parent/new/seeded"`: fine. Consider a normal entry with one level `a="seeded"`: `/$a/` = `/seeded/` — no match. Good.

  But here's a subtle one: `a=".hidden"` (a dotfile dir). `/.hidden/` — does it match `*/./*`? The pattern `*/./*` requires a literal `/.` followed by `/`. `/.hidden/` contains `/.h` — the `/.` in pattern must match `/.` in string and then next char must be `/`. In `/.hidden/`, after `/.` comes `h`, not `/`. No match. Good. What about `a="sub/.hidden"`? `/sub/.hidden/` — pattern `*/./*`: needs `/.` then `/`. After `/.` comes `h`. No match. Good.

  What about a directory literally named `..foo`? `/..foo/` — `*/../*`? After `/..` comes `f` not `/`. No match. Good. So the guard only refuses genuine segments. 

  Now — a trickier question on the ancestor walk. The walk: `_anc="$wt/$(dirname "$a")"`. For `a="parent/new/seeded"`, dirname = `parent/new`. `_anc=$wt/parent/new`. If neither exists: walk up to `$wt/parent` (exists? in arm 4 fixture, `parent` is a symlink committed at HEAD — the worktree checkout has `parent` as symlink). `-L` true → stop. `cd -P` → resolves to `$O`. Check against `_wtp` — outside → abort before mkdir. Good.

  In the CURRENT probe arm 4, after commit they `rm parent && mkdir -p parent/new/seeded` — wait, that replaces the symlink with real dirs on the HOST (RTL_ROOT), not the worktree. The worktree still checks out `parent` as the tracked symlink. Right.

  Now what does the sim do in the CURRENT patch for that fixture? `_anc` walk stops at `$wt/parent` (symlink), `cd -P` → `$O` → abort via `_rtl_seed_abort`. The abort runs `git -C "$RTL_ROOT" worktree remove --force "$wt"`. In the probe arm 4, that's real git — removes the worktree. rc 9 expected. And `$O/new` must not exist — since we abort before mkdir, nothing created. 

  Now the replay check I want: run the same harness as the round-4 reviewer but on the current patch text to confirm the fixed branch refuses and never calls raw rm. Actually the patch content changed: the block is now lines 23-57 (the `if [[ -d ...` branch). Let me extract from the current sim the added block and run the hostile fixture with git/rm stubbed.

  One more thing to scrutinize in the current sim: after `mkdir -p`, `_par="$(cd "$wt/$(dirname "$a")" ... && pwd -P)"`. If mkdir -p created the path, cd succeeds. Then `case "$_par" in "$_wtp"|"$_wtp"/*)`. Since `_wtp` is physical and `_par` physical, fine.

  Then `_dst="$_par/$(basename "$a")"`. basename of `parent/new/seeded` = `seeded`. OK.

  Then removal of existing `$_dst`: note the worktree at HEAD — `parent/new/seeded` doesn't exist in the checkout (parent is a symlink). Fine.

  Potential hole: what if `$_dst` exists in the checkout as a SYMLINK to outside? `rm -rf "$_dst"` removes the symlink only. Then `cp -R "$RTL_ROOT/$a" "$_dst"` — creates a real dir at `$_dst`. Fine, no write outside.

  What if `$_dst` exists as a MOUNT or bind mount? Local dev tooling; out of scope.

  What about `cp -R "$RTL_ROOT/$a" "$_dst"` where `$_dst` parent is inside worktree — copy destination is inside. Good.

  What about the case where the entry `a` exists on host as a directory but the checkout has it as a regular FILE? e.g. host `seeded/` dir, checkout `seeded` file at HEAD. `_dst` = file. `rm -rf "$_dst"` removes the file. `cp -R src dst` creates dir. Fine — mirrors host.

  Now, the probe's arm 4 in the packet vs the sim: I should verify the sim actually refuses. Let me run the narrow replay on the current patch. Also confirm base probe rc=1.

  Also confirm: does the probe have any arm where the FULL fix (with package) would fail? The producer ran it green (matrix line 12 rc=0). I could optionally apply sim+pkg in a scratch copy and run the probe to verify the green arm — that's stronger evidence than trusting the matrix. It's a throwaway copy; the instruction "do not rely on writing files" refers to my deliverable. Let me do it in a temp dir: copy the whole repo? The probe needs relay-turn-lib.sh and the package at $PWD-relative paths, plus the probe script. I can create a scratch dir, copy `relay-automation/relay-turn-lib.sh`, `skills/.../relay-pkg.tar.gz`, and `TESTS-RESULTS/.../probe-gh1638.sh` preserving layout, apply sim-gh1638-with-pkg.patch... wait the patch paths are `relay-automation/relay-turn-lib.sh` and `skills/1-hourly/relay-automation/relay-pkg.tar.gz` (git binary patch). `git apply` needs a git repo? No — `git apply` works outside a repo for regular patches, and for binary patches it also works (delta application needs the original file, which exists). Let me test: in scratch dir, `git apply --binary` the with-pkg patch — should work with the original files present.

  Then run the probe from the scratch root with TMPDIR set to a temp dir. Expected rc=0.

  That's a real end-to-end verification of the green arm. Let me do that. It writes only to temp dirs. 

  Also run base probe in the current repo (read-only per thread rules).

  Let me also double-check the fake5 arm claim: fake5 is the same as sim but without the lexical `case` guard, and includes the regenerated package binary patch. Matrix line 17 says rc=1 with message "a '..' directory entry created a directory outside the worktree". Wait — the message says "created a directory outside" — meaning arm 6's `[ ! -e "$T/wt6/outside6" ]` check fired?? Hmm, for fake5 without the lexical guard: entry `x/../../outside6/seeded`. Walk from `$wt/x/../../outside6`... does `-e` see it? `$wt/x` doesn't exist in the fresh checkout. `-e` on path with nonexistent intermediate → false. Walk: `$wt/x/../../outside6` → dirname → `$wt/x/../..` → `-e`? Path contains `x/..` where x doesn't exist → the kernel resolves `x/..`... actually on Unix, path resolution of `a/b/../c` where `b` doesn't exist → ENOENT. So false. → `$wt/x/..` → ENOENT (x missing)? Hmm — actually no: `x/..` where x doesn't exist → ENOENT. → `$wt/x` → false → `$wt` → true. `_anc=$wt` inside → pass. Then `mkdir -p "$wt/x/../../outside6"` → creates `$T/wt6/outside6` (since wt is `$T/wt6/rtl-wt.XXX`, x/../../outside6 → wait: `$wt/x/../../outside6` = `.../rtl-wt.XXX/x/../../outside6`. With x existing after mkdir -p: rtl-wt.XXX/x/.. → rtl-wt.XXX; /.. → wt6; /outside6. So mkdir creates `$T/wt6/outside6`. Then `_par` resolves to `$T/wt6/outside6` — outside `_wtp` (`$T/wt6/rtl-wt.XXX`)? The containment check `case "$_par" in "$_wtp"|"$_wtp"/*)` → `$T/wt6/outside6` does NOT start with `$T/wt6/rtl-wt.XXX/` → abort "resolves outside the worktree". So even fake5 refuses via the physical re-check! But the probe failure message says "created a directory outside the worktree" — meaning the abort happened AFTER mkdir created `$T/wt6/outside6`. The probe arm 6 checks `[ ! -e "$T/wt6/outside6" ]` → fails → "created a directory outside the worktree". And rc... the begin fails (rc 9) and no path — those checks pass, but the "create nothing outside" check fails. So fake5 reads unfixed because mkdir happened before containment. Interesting — so the ancestor-walk alone (which starts at the parent, not the entry) doesn't catch `..` traversal because the walk path also contains `..` and nonexistent intermediates make -e false all the way up to $wt. Wait, actually the walk went up to $wt and passed — the `..` segments were in the unvalidated remainder. The mkdir then created the outside dir, and only the post-mkdir re-resolve caught it. So the lexical guard is what makes arm 6 fully clean (refuse before any creation). That's exactly what the surviving seat's [Should] was about, and fake5 demonstrates the residual hole without it: a fake without the guard leaves a directory created outside the worktree (albeit caught by the probe). Good — the packet's claim holds together. Let me verify this understanding by running fake5's block in the replay harness too — that would concretely show "mkdir outside happens before refusal". Good for my finding.

  Let me also think about whether the guard pattern has a bypass: entry `a` where dirname is `.`? e.g. `a="seeded"` → dirname `.` → guard on `/$a/` = `/seeded/` no match. Walk starts `$wt/.` — exists (it's wt). Fine.

  What about `a="./seeded"`? Guard `/. /` → `/./seeded/` matches `*/./*` → refused. OK.

  What about backslash or other separators? Bash on macOS, forward slashes only. Fine.

  Now — one more possible fake: a fix that keeps the lexical guard and ancestor check but skips the POST-mkdir re-check, i.e. `_dst="$wt/$a"` string-based with containment only at ancestor level. Could it write outside? `_dst="$wt/$a"` where ancestor was proven inside and `a` has no `..`/`.`/empty segments... then `$wt/$a` string starts with `$wt/` and each segment is a normal name; mkdir -p creates real dirs; the physical path equals the string path (assuming no symlinks created in between — none). So string-based dst is actually safe given the guard+ancestor proof... EXCEPT if an intermediate component of `$a` exists in the checkout as a symlink pointing outside! E.g. `a="sub/dir/seeded"` where checkout `sub` is a symlink to outside. The ancestor walk starts at `$wt/sub/dir` — doesn't exist → up to `$wt/sub` — exists as symlink → `-L` true → stop → `cd -P` resolves outside → abort. So caught by the ancestor walk. What if `sub/dir` exists as symlink (deepest is dir)? Walk stops at `$wt/sub/dir` (symlink) → cd -P → outside → abort. Good. So the ancestor walk covers symlink-in-the-middle at ANY existing level of the parent chain. The post-mkdir check covers races and non-symlink weirdness. Fine.

  Could a builder's fix use `realpath` instead of `cd && pwd -P`? realpath on macOS exists (or python). Doesn't matter — the probe discriminates behavior, not implementation.

  Now, is there a fake that reads fixed (probe rc=0) but leaves a real defect? The probe checks: package equality, mirror semantics (no nest, current bytes, nested file kept, deleted child absent, file entry seeded), failed copy → fail begin, refused rm → fail begin with no path, escaping parent → fail + nothing outside, refused git teardown → reported + not raw-deleted, `..` entry → refused + nothing outside. 

  Candidate hole: SEED-DELETE branch unchanged (`rm -rf "$wt/$a"` when host entry absent) — out of scope, declared non-goal (line 13 of capture). Could `a` with `..` reach the SEED-DELETE branch? Host side doesn't exist → `[[ -e "$RTL_ROOT/$a" ]]` false → `rm -rf "$wt/$a"` with `..` in `a`! Wait — that's PRE-EXISTING behavior, not introduced by this fix. E.g. RTL_ALLOW=("x/../../evil") with host `x/../../evil` absent → `rm -rf "$wt/x/../../evil"`. rm -rf on nonexistent path is a no-op success. But if `wt/x` doesn't exist... rm -rf with nonexistent intermediate → fails silently (rm -rf returns 0 for nonexistent leaf but ENOENT for missing intermediate? Actually `rm -rf a/b` where `a` doesn't exist → rm -rf succeeds silently, GNU rm: "rm -rf nonexistent" exits 0). No deletion risk since rm doesn't follow `..` into nonexistence... Actually if `$wt/x` DOES exist and `../../evil` resolves outside — but then the host side `$RTL_ROOT/$a` with the same `..` would exist too presumably... Not necessarily: host `x/../../evil` resolves relative to RTL_ROOT; worktree `x/../../evil` resolves relative to wt. If wt is at `/tmp/wt6/rtl-wt.XXX`, `wt/x/../../evil` → `/tmp/wt6/evil`. Pre-existing hazard, unchanged by this packet, and out of scope (non-goal line 13 explicitly keeps SEED-DELETE behavior). Not a blocker for this packet; could be a [Nit]/park note. Actually wait — is it even a hazard? RTL_ALLOW comes from operator config (RELAY_ALLOWLIST), not attacker input. The hardening here is belt-and-braces for a config that already names directories. The `..` segments in the DELETE branch are a pre-existing edge; the packet's scope is the existing-directory mirror. Fine as a nit at most. Hmm — but the packet's own plan (line 55) now refuses `.`/`..`/empty for the mirror branch; the DELETE branch remains unguarded. Consistency argues the guard could apply to the whole loop, but expanding scope after the cap... The probe wouldn't catch it, but it's the same class of input. I'll note it as a [Nit]/observation, not a hold reason: RTL_ALLOW is operator-supplied config; a `..` entry today would already misbehave at baseline in the delete branch; this packet fixes the mirror branch only and declares the rest non-goals. It's a fair, bounded scope cut.

  Another candidate hole: the abort helper runs `git -C "$RTL_ROOT" worktree remove --force "$1"`. What if the begin failed BEFORE `git worktree add` succeeded... no, abort is only called after the worktree exists (inside the seed loop). What if abort itself is called with wt already removed? Not possible in the loop.

  What about the seedsig sidecar `${wt}.seedsig` — created after the loop. On abort, the sidecar isn't created; git worktree remove handles the worktree; the sidecar file is at `${wt}.seedsig` (sibling path, e.g. `rtl-wt.XXX.seedsig`) — never created since loop aborted. Fine.

  Now let me also double check `_rtl_seed_abort` message: "git worktree remove refused for %s; left in place for inspection". Probe arm 5 greps for 'worktree remove' — matches. Good.

  One more: the sim's `rm -rf "$_dst"` uses the shell builtin/external rm — the probe arm 3 shadows `rm` as a function to refuse `*/seeded`. In the sim, the removal is `rm -rf "$_dst"` where `_dst` ends with `/seeded` → function refuses → `if ! rm -rf ...` → abort path. Good. Note: the abort helper calls `git worktree remove` — arm 3's git is NOT shadowed, so teardown works. rc 9, no path. Good.

  Now — the plan says the deepest-existing-ancestor check happens "before creating or removing anything". In the sim, the guard order: lexical check → resolve wt → ancestor walk+resolve+contain → mkdir → re-resolve parent → contain → rm dst → cp. Yes. ✓.

  (b): teardown on failure is `git worktree remove --force` only, refusal reported, no raw rm of the worktree. In `_rtl_seed_abort`: only git teardown; refusal printed. There's no `rm -rf "$wt"` anywhere in the new code. The only raw rm is `rm -rf "$_dst"` (destination inside worktree — allowed and required for the mirror) and the pre-existing `rm -rf "$wt"` at line 745/751 (before worktree add / on add failure — pre-existing, and at that point it's not yet a git worktree, just an empty mktemp dir). Fine.

  So on criteria 1 and 2, the packet looks sound. Let me now verify live: (1) base probe rc=1; (2) replay hostile fixture against current sim block (expect rc=1, empty stdout, REFUSE message, NO "mock raw removal", outside/new NOT created); (3) optionally fake5 block replay (expect mkdir-outside-then-refuse — demonstrating the probe catches it); (4) green arm: scratch-copy the two files + probe, apply with-pkg patch, run probe expecting rc=0. That's the strongest verification. Let me do it.

  Note on the green arm run: probe arm 5 uses chmod 000 on seeded/f.txt — running as... on macOS as non-root, chmod 000 makes cp fail with permission denied. The producer's matrix shows it works. Also arm 5 shadows git function to refuse `git worktree remove` — `command git` fallback for others. Fine.

  Let me run these now. I'll do them as separate Bash calls in one message since they're independent:

  1. Base probe: `cd /private/.../consult-wt-92820-m8z33h8p && PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp-consult" bash TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1638.sh; echo rc=$?` — need mkdir -p for TMPDIR. Probe does mktemp -d "${TMPDIR:-/tmp}/gh1638-probe.XXXXXX". It cleans up at end (`cd / && rm -rf "$T"`). OK.

  2. Replay harness (python3) with current sim block.

  3. Green arm in scratch dir.

  Let me write the replay carefully. The current sim added block: from the patch, added lines between `if [[ -e "$RTL_ROOT/$a" ]]; then` and `rtl_trace ... SEED`. I'll extract added lines (strip leading '+') from the patch region. In the round-4 replay they took `patch[6:37]` lines not starting with '-'. The new patch's added block: lines 26-57 of the patch file (0-indexed 25-56), i.e. the `if [[ -d ...` through `fi`. Simplest: take all lines starting with '+' in the second hunk after the `-` removal lines... Actually easier: extract the added block as: for the second hunk, lines that start with '+' and are not the `+++` header. But the first hunk adds `_rtl_seed_abort`. I need both the helper and the branch. Let me reconstruct: take the full post-image of the relevant region by applying the patch to a copy of the real relay-turn-lib.sh with `git apply` in a scratch dir — much more reliable. Then define a `seed()` harness function that runs with RTL_ROOT, wt, a set, and stub git/rm/rtl_trace as needed.

  Actually simplest replay: create scratch dir, copy relay-turn-lib.sh, apply sim-gh1638.patch via `git apply --check` then apply (needs git? `git apply` works outside repo). Then source the patched lib in a bash harness with the hostile fixture (real git, real rm — since post-fix the abort should REFUSE before any rm, and teardown via real git worktree remove is fine in a temp repo). Round-4 reviewer stubbed git and rm to prove no raw removal and a refusal; with real git, teardown succeeds. The key assertions: rc=1, no stdout, stderr REFUSE ancestor message, `$O/new` NOT created, and worktree removed by git (so `$wt` gone). Let me also stub `rm` to log calls to prove the refusal happened before any rm call... but wait — teardown: `git worktree remove --force` — git internally deletes files (not via the shell `rm` function; it's the git binary). The stubbed-rm harness from round 4 printed "mock raw removal called for -rf" for the OLD patch because the old patch had `rm -rf "$wt"`. For the new patch, no such call. I'll stub both and assert no "raw removal" line. git itself is stubbed to refuse teardown in one variant (to check refusal reporting) — but arm 5 of the probe already covers that; I can rely on producer's matrix for arm 5. I'll do the git-refuse variant too, quickly: expect "git worktree remove refused" message and worktree still exists, and no rm call.

  Fixtures need a real git repo for `git worktree add`. The round-4 replay stubbed everything and never invoked git; I'll use real git in a temp dir (fast enough: git init, one commit, worktree add). Actually simpler: stub `git()` to simulate... no — the new code path before the abort doesn't call git at all (walk uses cd/pwd; guard is lexical). The abort helper calls `git worktree remove`. If I stub git to return 0 (mock successful removal), I can assert: rc=1, no stdout, REFUSE message on stderr, no raw rm, outside/new not created. That mirrors round-4's approach and is fast/deterministic. Let me do:

  ```python
  from pathlib import Path
  from tempfile import TemporaryDirectory
  from subprocess import run

  d = Path('TESTS-RESULTS/2026-11-27+GH-1658-runA-prep')
  patch = (d/'sim-gh1638.patch').read_text().splitlines()
  # added lines of hunk 2 (the seed branch): after line "if [[ -e ..." context
  # Extract all '+' lines from the patch (both helper and branch), then wrap.
  added = [l[1:] for l in patch if l.startswith('+') and not l.startswith('+++')]
  # The branch block includes the helper then the branch; build a seed() that mimics the loop body:
  block = '\n'.join(added[?])
  ```

  Hmm, the added lines include: helper function (6 lines: `_rtl_seed_abort() { ... }` plus blank), then branch lines. Taking ALL added lines and defining them inside a bash function won't work because the helper is a function definition (fine inside?) — a function definition inside a function is legal in bash. The branch references `wt`, `a`, `RTL_ROOT` — I'll pass via env. The branch's final `fi` closes `if [[ -e ... ]]`. I need the surrounding `if [[ -e "$RTL_ROOT/$a" ]]; then ... fi`? The patch context: the hunk replaces
  ```
      if [[ -e "$RTL_ROOT/$a" ]]; then
  -     mkdir -p ...
  -     cp -R ...
  +     <branch>
         rtl_trace ...
  ```
  So the added branch lines sit INSIDE the existing `if`. For my harness, wrap: `if [[ -e "$RTL_ROOT/$a" ]]; then <added branch lines> fi`. The branch contains its own `if [[ -d ...]] ... else ... fi` — self-contained. But the helper function def must be OUTSIDE seed(). Let me split: first added hunk = helper (lines from patch[8:15] approx). Rather than hardcode, find the index of ' rtl_worktree_begin() {' added line? The helper added lines: patch lines 9-15 in 1-indexed (the `_rtl_seed_abort` block + blank). Branch added lines: 26-57. I'll extract by markers: helper_start = first added line starting with '+_rtl_seed_abort'; branch_start = first added line starting with '+      if [[ -d "$RTL_ROOT/$a"'... The patch uses 6-space indentation (inside function + if). Let me just take added lines list and split at the line that begins with '+      if [[ -d "$RTL_ROOT/$a"'. 

  Then harness bash:
  ```
  RTL_ROOT="$1"; wt="$2"; a="parent/new/seeded"
  git() { echo "mock git $*" >&2; return ${GIT_RC:-0}; }
  rm() { echo "mock raw removal called for $*" >&2; return 0; }
  rtl_trace() { printf 'TRACE %s\n' "$*" >&2; }
  seed() {
    if [[ -e "$RTL_ROOT/$a" ]]; then
    <branch lines, dedented by 6? no — keep as-is, indentation irrelevant>
    fi
  }
  seed
  ```
  Indentation doesn't matter in bash. The branch lines reference `local _wtp ...` — `local` inside seed() is fine.

  Fixture: host `parent/new/seeded` real dir with f.txt; wt dir with `parent` symlink to outside. wt must exist (mktemp). RTL_ROOT=host. Expect: rc=1, stdout empty, stderr contains "REFUSE seed parent/new/seeded: an existing ancestor", NOT contains "mock raw removal", outside/new must not exist. And with GIT_RC=1: stderr contains "git worktree remove refused", and wt still exists, still no rm call.

  Also fake5 variant: branch without the case-guard lines. Expect: rc=1 (refused at post-mkdir check), but `mkdir -p` created wt6-side outside dir — demonstrating probe catches it. In my fixture: wt/x/../../... hmm fake5 fixture is arm-6 shape: wt root = `$T/wt6`, worktree `$wt6/rtl-wt.XXX`... my simpler fixture: wt = temp/wt, entry `x/../../outside6/seeded`, host has x/../../outside6/seeded (real dir). mkdir -p `$wt/x/../../outside6` → creates `temp/outside6`? Let's compute: wt=temp/wt; `temp/wt/x/../../outside6` → temp/wt/x/.. → temp/wt; /.. → temp; /outside6 → temp/outside6. So it creates temp/outside6 — outside wt. Then cd -P resolves to temp/outside6 → not under wt → REFUSE "resolves outside". rc 1. mkdir happened → probe would flag "created a directory outside the worktree". In my harness, assert temp/outside6 exists → demonstrates fake5's residual hole, matching matrix message. 

  Green arm: 
  ```
  S=$(mktemp -d); mkdir -p $S/relay-automation $S/skills/1-hourly/relay-automation $S/TESTS-RESULTS/2026-11-27+GH-1658-runA-prep
  cp relay-automation/relay-turn-lib.sh $S/relay-automation/
  cp skills/1-hourly/relay-automation/relay-pkg.tar.gz $S/skills/1-hourly/relay-automation/
  cp TESTS-RESULTS/.../probe-gh1638.sh $S/TESTS-RESULTS/.../
  cd $S && git apply --binary <orig>/TESTS-RESULTS/.../sim-gh1638-with-pkg.patch  (need orig path before cd)
  # check pkg member == live lib? the patch binary-delta requires original bytes
  cd $S && PYTHONDONTWRITEBYTECODE=1 TMPDIR=$S/tmp bash TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1638.sh; echo rc=$?
  ```
  Expect rc=0. The probe's arm 5 needs `git worktree remove --force` real; the fixture repo is real. chmod 000 as non-root → cp fails. Running as current user (noel) — fine.

  Wait — probe line 5 unsets GIT_* env vars; fine. It sources "$L" — the patched lib. arm 5's git() function checks `${3:-}` = worktree, `${4:-}` = remove → for `git -C "$RTL_ROOT" worktree remove --force "$wt"`: args: -C, root, worktree, remove, --force, wt. $3=worktree $4=remove → return 1. Good.

  Also verify the applied with-pkg patch makes the package member identical to the patched lib — the probe checks that itself (line 11-12). If git apply of the binary delta works, good.

  Let me now also confirm the probe file I run in the green arm matches the inline contract probe — consumer-validation.txt claims equality; the readable copy equals inline per round-3 review. Fine.

  One more check for criterion 2: "base and every retained fake read unfixed, the full fix with the regenerated package reads fixed (matrix.txt)". Matrix lines 10-17 confirm: base 1, sim 1 (source-only, package drift), sim-with-pkg 0, fakes 1-5 all 1. I verified fake5 reads unfixed by analysis + will verify by replay. Good.

  And the question "Is there a fake fix that would still read fixed while leaving the defect or creating a new containment hole? Give the concrete input if so." — I've considered: skip-dirs (fails arm1: no current bytes... actually skip dirs leaves HEAD content → arm1 "did not carry the current content" fails), overlay (deleted child survives → fails), rm-unchecked (arm3), mkdir-first (arm4 creates outside → fails), no-dotdot-guard (arm6 creates outside → fails), return-true-ish "echo path without seeding" (arm1 content checks fail + readable arm requires existing dir). What about a fix that does the mirror via `rsync -a --delete`? Would pass contents; does rsync exist on macOS? Not by default (OpenSSH removed it; some macs have it). If a builder used rsync and it existed, probe would pass — and behavior is correct (mirror incl. deletions). No hole. What about a fix using `cp -R src/. dst` after `rm -rf dst`? Same as sim semantics minus nothing — passes and is correct. Fine.

  A fix that hard-codes arms? The probe writes fixture paths dynamically... arm detection: e.g. fix checks if basename is "seeded" — but fixtures use `seeded`, `parent/new/seeded`, `x/../../outside6/seeded`. A name-based hack would break on arm 4/6. It'd be absurd; not a real concern for a builder lane.

  What about a fix that refuses `..` but the sim's walk has a subtle bug when `wt` path itself contains a symlink (TMPDIR=/tmp → /private/tmp on macOS)? `mktemp -d "${wt_root}/rtl-wt.XXXXXX"`; `_wtp=$(cd "$wt" && pwd -P)` → physical. `_anc` also physical. Consistent. The sim computes `_dst="$_par/$(basename "$a")"` — physical base + basename; then `cp -R "$RTL_ROOT/$a" "$_dst"`. Fine. Probe arm1 checks `find "$wt/seeded" ...` with the echoed `$wt` (logical) — fine since logical/physical both reach the same dir.

  OK — also criterion 3: scope. The final plan: one helper + one branch in the seed loop + make-pkg. ~40 added lines in one file. Still one-turn Jog. Yes. The hardening was demanded by review; it's proportionate because the feature is a recursive delete.

  Now, anything that should HOLD? Let me think about whether the round-4 blocker's falsifier is fully met:
  - "a directory entry with an escaping checkout parent fails without returning a worktree path or creating any outside directory" → sim refuses at ancestor check before mkdir; probe arm 4 verifies with real git. ✓ (will verify in replay)
  - "a controlled Git teardown refusal yields an observable failure with no raw worktree deletion" → arm 5. ✓ (producer matrix; I'll optionally verify in replay with stubbed git)
  - "The ordinary mirror, package, and existing failure controls still pass with the corrected simulated fix" → matrix with-pkg 0. ✓ (will run green arm live)

  Potential residual issues to grade:
  - The DELETE branch (`rm -rf "$wt/$a"` for host-absent entries) remains unguarded against `..` entries (pre-existing). [Nit] — out of declared scope; a `..` entry there would resolve outside... wait, actually would it delete outside? `rm -rf "$wt/x/../../evil"` — if `$wt/x` doesn't exist, GNU/BSD rm -rf: `rm -rf` on a path whose intermediate doesn't exist → exits 0 silently (no error for -f). If `$wt/x` exists (checked out) and the path resolves outside to an existing dir → rm -rf WOULD delete outside! But this is baseline behavior, unchanged, and requires operator config to contain a `..` entry. The packet guards the mirror branch only. Since the packet's declared non-goal keeps SEED-DELETE behavior, and RTL_ALLOW is operator-supplied (not untrusted input), I grade [Nit] with a suggestion to fold the guard into the whole loop when implemented, or park it. Not a hold: the question asks about THIS packet's fitness; the defect is pre-existing, out of the issue's scope (issue = nesting), and the plan/criteria are internally consistent.

  - Arm 6 fixture: `mkdir -p "$R6/x"` makes host side resolve; checkout has no x. Good. But note the probe's arm 6 expects rc 9 AND no path AND nothing created. With the sim's lexical guard, refusal happens at the case check — nothing created. ✓

  - One inconsistency check: capture "Smallest plan" (line 55) says "File entries keep `mkdir -p` + `cp -R`" — sim line 55-56 does that. ✓. Capture line 57 says matrix entries match. ✓ SUMMARY says four [added] criteria. ✓ (round-3 finding fixed)

  - The contract `remediation` string mentions the criteria; gate `bash test/worktree-isolation.sh` — does that suite cover the seam? Round 2 reviewer noted it exercises the live library (`:181-191`). And relay-pkg-freshness result must be recorded in delivery receipt (Acceptance line 36, remediation line 108). ✓

  - Contract `round_cap: 9` vs the 4 review rounds of preparation — cap 9 is for Jog build rounds; prep rounds were 4. The QA thread header says round_cap 9 expected. Fine.

  - `prepared_commit` pin matches SUMMARY and matrix header. ✓

  - Fake5's package regeneration: the with-pkg binary patch in fake5 — matrix line 17 shows it ran; fine.

  Now, is there anything about the FIRST panel's [Should] that was folded in correctly? The seat asked: refuse '.', '..' and empty path segments in a directory entry. Plan line 55: "Refuse an entry with a `.`, `..` or empty path segment (lexical, before any filesystem work...)". Sim line 32: case guard. Probe arm 6: only tests `..`. A `.` or empty segment is not probe-tested — a fake that guards only `..` would read fixed while accepting `.`/empty segments. Concrete input: `RTL_ALLOW=("sub/./seeded")` or `("sub//seeded")`. Does accepting those create a hole? `sub/./seeded` resolves to `sub/seeded` — the ancestor walk and physical re-check still apply; containment still proven before mkdir; no traversal possible (`.` and empty segments don't move up). The defect: none real — it's hygiene/consistency, not a containment hole. The issue's own [added] criteria don't mention segment refusal; it came from the consult seat as defense-in-depth. So: [Nit] — the guard exists in plan+sim; the probe covers only `..`; a `.`/empty-accepting fake would read fixed but creates no containment hole (physical checks still bound it). Actually wait — could `a="."`? guard refuses `.`. Without guard: dirname of "." is "."; walk: `$wt/.` exists → `_anc=$wt` → inside → mkdir -p `$wt/.` fine → `_par=$wt` → `_dst="$wt/."`... wait basename of "." is ".". `_dst=$wt/.` → `[[ -e $_dst ]]` true → `rm -rf "$wt/."`! rm -rf on a directory path `/.` — rm refuses to remove `.`? `rm -rf dir/.` → rm: "." and ".." may not be removed? Actually `rm -rf /path/to/dir/.` — BSD/GNU rm: refusing to remove '.' or '..'? Let me think: `rm -rf foo/.` → GNU rm removes the CONTENTS of foo but not foo itself? No — POSIX says rm -r on dir/. removes the directory content... Actually `rm -rf dir/.` removes dir's contents and then dir itself? Testing knowledge: `rm -rf dir/.` returns 0 and empties dir but leaves dir? Hmm, I recall `rm -rf /path/.` can remove the directory itself (dangerous quirk). E.g., `mkdir a; touch a/f; rm -rf a/.; ls a` → "No such file or directory" — yes, a is GONE on GNU coreutils. On BSD rm similar. So an entry `.` with a permissive fake (no guard) could nuke `$wt` itself mid-seed → then cp fails → begin fails... but worktree deleted raw — though via rm of ".", not the worktree path... it deletes the worktree contents! That IS a raw worktree deletion hole. But: only if the fake refuses `..` (passes arm 6) while accepting `.`. The packet's sim refuses both. Could a builder's natural fix refuse `..` but not `.`? The plan explicitly says refuse `.` too; a builder following the plan would refuse both. The probe wouldn't catch a `.`-accepting fake (no arm). Is that a HOLD-level gap? The question: "Is there a fake fix that would still read fixed while leaving the defect or creating a new containment hole? Give the concrete input if so." — Concrete input: `RTL_ALLOW=(".")` on a tree where host `.` exists (it does — RTL_ROOT itself). Entry `.` is a directory (RTL_ROOT/. exists). Mirror branch: without guard, `_dst=$wt/.` → rm -rf $wt/. → deletes the worktree contents → cp -R "$RTL_ROOT/." "$wt/." → recreates with full host content... then begin "succeeds" seeding everything. Probe arm 1: would the seeded checks pass? wt/seeded/f.txt=v2? If host repo has seeded/f.txt... the fixture repos don't have a top-level layout matching... this fake would be bizarre. But more realistically the fake reads fixed on arms 1-6 (none use `.`), so probe rc=0 while `.` entry nukes the worktree. Hmm — but does any REAL config ever have `.` or empty or `..` entries? RTL_ALLOW comes from the operator/driver config (RELAY_ALLOWLIST with repo-relative paths). Real-world entries: "relay-system", "sandbox-app/src", etc. The probability of a `.` entry is near zero; the guard is defense-in-depth per the seat. The probe testing `..` demonstrates the guard class works. I grade this [Nit]/[Should]-lite: the packet met the letter of the seat's ask (guard in plan+sim; probe arm for `..`); a residual probe gap exists for `.`/empty inputs but no realistic hole given physical checks... wait, no — for `.` the physical checks DON'T save you: `_par=$wt` is inside, `_dst=$wt/.` rm is the hole. The mirror's rm of `_dst` where `_dst` = `wt/.` is the danger. But hold on — could that happen with the SIM's guard? No: sim refuses `.` lexically. Only a hypothetical fake that guards `..` only. The discriminating-check question asks exactly this: is there a fake reading fixed that creates a new hole? Strictly: yes — a `..`-only guard fake, input `RTL_ALLOW=(".")`, reads fixed (no arm exercises it) and `rm -rf "$wt/."` would delete the worktree. But wait — would the sim itself... no, sim refuses. So the packet's PLANNED fix is safe; the PROBE has a coverage gap. Does that make the packet unfit? The packet = plan + probe + sim. Jog will have a builder implement the plan; the plan is explicit (refuse `.`, `..`, empty). A builder deviating from the plan in exactly the unprobed dimension while satisfying all probes is conceivable but the deviation would be deliberate non-compliance with an explicit remediation string. Hmm. The remediation says "entries with '.', '..' or empty segments are refused". lint... the probe can't check the plan, only behavior. Given the operational envelope (operator-supplied allowlists, local tooling) and that this gap was introduced by accepting the seat's own [Should], I judge it [Nit] — worth one line, not a hold. Actually let me reconsider: could I construct an arm-7 input where even the SIM's guard... no, sim refuses. OK, Nit.

  Let me also sanity-check the sim's guard pattern against a subtle bypass: `a="foo/../bar"` refused. `a="foo//bar"` refused (empty). `a="./foo"` refused. `a="foo/."`? `/$a/` = `/foo/./` — matches `*/./*`? Pattern needs `/.` then `/`: `/foo/./` ends with `./` → `/.` then `/` yes → refused. `a="foo/.."` → `/foo/../` matches → refused. Trailing-slash `a="foo/"` → `/foo//` matches `*//*` → refused. Conservative; fine. Leading `/` → absolute → skipped earlier. Windows backslashes → not path separators on macOS bash. OK.

  Now let me run the verifications. Three bash calls (independent, parallel):
  1. Base probe run.
  2. Python replay: current-sim hostile fixture (git stubbed success + git stubbed refuse) + fake5 variant.
  3. Green arm: scratch apply + probe run.

  For the replay, extract from sim-gh1638.patch: added lines; helper = lines from '+_rtl_seed_abort' up to the blank before '+ rtl_worktree_begin'? Actually the helper added block is lines 9-15 (`+_rtl_seed_abort() {` through `+}` and `+`). Then branch added lines start at `+      if [[ -d "$RTL_ROOT/$a" && ! -L ...`. I'll collect all added lines, find index of the branch start.

  Harness script (bash -c):
  ```bash
  RTL_ROOT="$1"; wt="$2"; a="$3"; GIT_RC="$4"
  git() { echo "mock git $*" >&2; return "$GIT_RC"; }
  rm() { echo "MOCK-RAW-RM $*" >&2; return 0; }
  rtl_trace() { printf 'TRACE %s\n' "$*" >&2; }
  <helper>
  seed() {
    if [[ -e "$RTL_ROOT/$a" ]]; then
  <branch lines>
    fi
  }
  seed
  ```
  Wait — the branch lines include `local _wtp _anc _par _dst` — `local` valid inside seed(). But they also reference `_rtl_seed_abort` (defined globally). Good.

  For fake5: same but drop the 3 lines of the `case` guard (the `+        case "/$a/" in`, `+          */../*...` , `+        esac` lines).

  Assertions:
  - sim + escaping-parent: rc=1, stdout empty, stderr has 'REFUSE seed parent/new/seeded: an existing ancestor does not resolve inside the worktree', stderr lacks 'MOCK-RAW-RM', (outside/'new').is_dir() False.
  - sim + GIT_RC=1: stderr has 'git worktree remove refused', wt still exists, no MOCK-RAW-RM.
  - fake5 + arm6-shape fixture (entry x/../../outside6/seeded): rc=1 (refused after mkdir), outside dir created → demonstrates probe catches it.

  Fixture build in python: temp dir; host/parent/new/seeded with f.txt; wt/parent symlink→outside. Run bash.

  Green arm script:
  ```bash
  set -e
  S=$(mktemp -d /tmp/gh1638-green.XXXXXX)
  mkdir -p "$S/relay-automation" "$S/skills/1-hourly/relay-automation" "$S/TESTS-RESULTS/2026-11-27+GH-1658-runA-prep" "$S/tmp"
  cp relay-automation/relay-turn-lib.sh "$S/relay-automation/"
  cp skills/1-hourly/relay-automation/relay-pkg.tar.gz "$S/skills/1-hourly/relay-automation/"
  cp TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1638.sh "$S/TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/"
  git -C "$S" apply --binary "$PWD/TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/sim-gh1638-with-pkg.patch"
  cd "$S"
  PYTHONDONTWRITEBYTECODE=1 TMPDIR="$S/tmp" bash TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1638.sh; echo "GREEN_RC=$?"
  ```
  `git apply` outside a repo: works (it applies to files relative to cwd). Binary delta patch needs the preimage — present. If `git apply` complains about "outside repository"... it doesn't; git apply works in non-repo dirs. Let me run it. Note: `set -e` with the probe expected rc 0 — if nonzero, the echo still runs? With set -e, a failing command aborts. Better to not use set -e and capture rc explicitly.

  Base probe:
  ```bash
  mkdir -p "$PWD/.relay-scratch/tmp-consult"
  PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp-consult" bash TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/probe-gh1638.sh; echo "BASE_RC=$?"
  ```
  Expected rc=1. (This is the current repo = baseline, since no implementation exists.)

  These three are independent — run in parallel.nested copy under /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-92820-m8z33h8p/.relay-scratch/tmp-consult/gh1638-probe.h2z1hS/rtl-wt.XRhAU4/seeded
seed did not carry the current content
file deleted on the host survives in the seeded directory
cp: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-92820-m8z33h8p/.relay-scratch/tmp-consult/gh1638-probe.h2z1hS/repo2/seeded/f.txt: Permission denied
failed directory copy reported a successful seed (rc=0)
uncleared checkout copy still reported a seed (rc=0, path=/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-92820-m8z33h8p/.relay-scratch/tmp-consult/gh1638-probe.h2z1hS/rtl-wt.dz3OZ9)
escaping checkout parent still reported a seed (rc=0)
seeding created a directory outside the worktree (/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-92820-m8z33h8p/.relay-scratch/tmp-consult/gh1638-probe.h2z1hS/outside/new)
seed failure with refused teardown reported success (rc=0)
refused Git teardown was not reported
a '..' directory entry still reported a seed (rc=0)
a '..' directory entry created a directory outside the worktree
BASE_RC=1
APPLIED
cp: /tmp/gh1638-green.W3h5ho/tmp/gh1638-probe.8UCvms/repo2/seeded/f.txt: Permission denied
rtl_worktree_begin: seed seeded: copy failed
probe: refusing rm -rf /private/tmp/gh1638-green.W3h5ho/tmp/gh1638-probe.8UCvms/rtl-wt.qRGbAN/seeded
rtl_worktree_begin: seed seeded: could not clear the checkout copy
GREEN_RC=0
SIM arm4-shape : rc=1 stdout=''
  stderr: TRACE rtl_worktree_begin: REFUSE seed : refusing a '.', '..' or empty path segment | rtl_worktree_begin: seed : refusing a '.', '..' or empty path segment
  outside/new created: False | wt exists: True
Traceback (most recent call last):
  File "<stdin>", line 55, in <module>
AssertionError
Results:

  1. **Base probe**: BASE_RC=1, with all expected failure messages — base reads unfixed on every arm. ✓ Confirms matrix line 10.

  2. **Replay harness**: my first replay has a harness bug — the refusal fired with "seed :" — empty `$a`. Because I passed `a` as `$3` but in the script I set `a="$3"` — wait, I passed entry as third arg but the run only passed `['_', str(host), str(wt)]` — I forgot to pass the entry! Looking at my script: `RTL_ROOT="$1"; wt="$2"; a="$3"` but `run(['bash','-c',script,'_',str(host),str(wt)])` — only 2 args. So `$a` empty → `/$a/` = `//` → matches `*//*` → refused for empty segment. My harness bug, not a packet bug. The empty-segment refusal actually fired (nice accidental confirmation the guard catches empty segments). Let me fix and re-run replays 1-3.

  3. **Green arm**: GREEN_RC=0 — the full simulated fix with regenerated package reads FIXED end-to-end through the real probe (arms 1-6 + package check). The stderr shows the expected abort messages from arms 2/3. ✓ Confirms matrix line 12.

  Let me re-run the replay with the entry passed correctly.SIM arm4-shape : rc=1 stdout=''
  stderr: TRACE rtl_worktree_begin: REFUSE seed parent/new/seeded: an existing ancestor does not resolve inside the worktree | rtl_worktree_begin: seed parent/new/seeded: an existing ancestor does not resolve inside the worktree
  outside/new created: False | wt exists: True
SIM git-refuse : rc=1 wt exists: True
  stderr: TRACE rtl_worktree_begin: REFUSE seed parent/new/seeded: an existing ancestor does not resolve inside the worktree | rtl_worktree_begin: seed parent/new/seeded: an existing ancestor does not resolve inside the worktree | rtl_worktree_begin: git worktree remove refused for /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-92820-m8z33h8p/.relay-scratch/tmp-consult/gh1638-tiebreak-2_ek0b1y/wt; left in place for inspection
FAKE5 arm6-shape: rc=1 created-outside=True
  stderr: TRACE rtl_worktree_begin: REFUSE seed x/../../outside6/seeded resolves outside the worktree | rtl_worktree_begin: seed x/../../outside6/seeded resolves outside the worktree
ALL REPLAY ASSERTIONS PASSED
All verifications pass:

  1. **Base probe** (live tree, prepared commit): rc=1, every arm fails as expected → base reads unfixed. Matches matrix line 10.

  2. **Green arm** (sim-gh1638-with-pkg.patch applied in scratch): probe rc=0 → full fix with regenerated package reads fixed end-to-end. Matches matrix line 12.

  3. **Replay of round-4 hostile fixture against the current sim block**: rc=1, no path, nothing created outside, refusal before any `rm`, Git-managed teardown only; when git refuses teardown, the refusal is reported and the worktree is left in place, no raw deletion. This is exactly the round-4 falsifier.

  4. **fake5 replay**: without the lexical guard, the arm-6 shape leaks the mkdir outside before refusing — matching matrix line 17 and confirming the probe discriminates that fake.

  One more check I should do: confirm fake5's patch as retained actually lacks the case guard (I read it — lines 26-50 of fake5 patch, indeed no `case "/$a/"` line; it goes from `local _wtp _anc _par _dst` straight to `_wtp=...`). ✓ Already read.

  Also confirm the claim about the sim's guard order once more from the patch text: lines 31-33 case guard; 34-40 ancestor resolution+containment; 41 mkdir; 42-47 re-resolve parent + containment; 48-52 rm dst + confirm gone; 53 cp. Yes: ancestor containment proven before mkdir (line 41), and rm of worktree appears nowhere; `_rtl_seed_abort` (lines 9-15) uses only `git worktree remove --force` and prints "git worktree remove refused … left in place for inspection".

  Now the minor observations to grade:

  [Nit 1] The probe has no arm for `.` or empty segments (only `..`, arm 6). A hypothetical fix guarding only `..` would read fixed while accepting `RTL_ALLOW=(".")` — concrete input: a directory entry `.` on a host tree where `.` exists; the mirror branch would compute `_dst=$wt/.` and `rm -rf "$wt/."` deletes the worktree contents mid-seed. This is exactly the class the consult seat asked to close, and the packet closes it in plan+sim; the probe just doesn't exercise it. Given RTL_ALLOW is operator-supplied config and the remediation string explicitly requires refusing all three segment types, this is a coverage nit, not a hole in the planned fix. Also note the SEED-DELETE branch (`relay-turn-lib.sh:787-789`, kept as a declared non-goal at capture line 13) remains unguarded for `..` entries — pre-existing behavior, out of scope, but worth folding the same lexical guard over the whole loop at implementation time or parking.

  [Nit 2] Trailing-slash/empty-final-segment entries (e.g. `RTL_ALLOW=("seeded/")`) are refused by the guard (`/$a/` = `/seeded//` matches `*//*`). No real config is known to use them; refusal is loud (begin fails), not silent. Worth one line in the delivery notes at most. Actually — is this even true for the file branch? The guard only applies to the directory branch. A file entry `seeded/` — `[[ -d "$RTL_ROOT/seeded/" ]]` is true for a dir... then guard refuses it even though baseline would seed it. Baseline `cp -R "$RTL_ROOT/seeded/" "$wt/seeded/"` — works. So the hardened branch turns a previously-working trailing-slash entry into a refusal. Edge-case behavior change, loud failure, config hygiene assumption. I'll mention as a nit under the same heading.

  [Pass] Scope: still one loop branch + one helper in one file + package regen; ~48 added lines; commensurate for a recursive-delete seam; the probe is the sanctioned manual shape (GH-831 respected — no new suite; gate is the existing test/worktree-isolation.sh plus the existing relay-pkg-freshness check recorded in the delivery receipt).

  Also confirm: capture Acceptance criterion 3 line 35 + [added] line 44 now include "any removal before the copy is confined to a path that resolves strictly inside the worktree" and failed-copy → non-zero. The round-4 demand "Prove the destination's existing ancestry is inside the worktree before creating missing parents" is in the plan line 55 ("resolve the worktree and the deepest existing ancestor of the entry's parent physically and require that ancestor inside the worktree... only then mkdir -p"). ✓ "Use Git-managed teardown... make a teardown refusal visible" — helper + arm 5. ✓

  One thing to double check on truthfulness: the matrix line 11 for sim-gh1638 (source-only) records message "seed seeded: could not clear the checkout copy" and rc=1 — that's the arm-3 inner-shell stderr, plus the package-drift fail. rc=1 correct (source-only must read unfixed because package check fails). ✓ consistent with SUMMARY line 52.

  Also verify the claim in the QA thread header that #1666/#1423 passed — not my question; the consult asks only about #1638.

  Verdict: PUBLISH.

  Structure of the answer per instructions:
  - VERDICT: PUBLISH
  - numbered reasons with file:line citations
  - (1) short direct ANSWER; (2) graded FINDINGS [Blocker]/[Should]/[Nit]/[Pass]; (3) one-line RECOMMENDATION.

  Let me write the final message. Include the observed evidence: base probe rc=1 live, green arm rc=0 live, replays. Citations: sim-gh1638.patch lines, probe arms, matrix lines, capture lines, rtl.py lines, relay-turn-lib.sh lines, WORKTREE-SAFETY.md lines.

• All checks pass. I have what I need.

  **Verification I ran** (throwaway fixtures only):
  - Base probe on the live tree at the prepared pin → `rc=1`, every arm red (nested copy, stale content, surviving deleted child, silent failed copy, uncleared checkout, escaping parent creating `outside/new`, unreported teardown refusal, `..` entry creating outside dir) — matches `matrix.txt:10`.
  - Green arm: applied `sim-gh1638-with-pkg.patch` in a scratch dir and ran the real probe → `rc=0` — matches `matrix.txt:12`.
  - Replay of the round-4 hostile fixture against the current sim block → refused before any creation, no raw `rm` of the worktree; with `git worktree remove` shadowed to refuse, the refusal is reported and the worktree left in place.
  - Replay of `fake5`'s block (guardless) on the arm-6 shape → `mkdir` leaks outside *before* refusal — confirming the probe catches it.

  ---

  ## ANSWER

  **VERDICT: PUBLISH.** The round-4 Blocker is resolved in plan, simulated fix and probe; the packet discriminates base, all six fakes and the full fix; scope remains a one-turn Jog task. Preparation-only publication is fit; no HOLD reason survives with a failing input.

  ## FINDINGS

  1. **[Pass] Round-4 Blocker criterion (a) — containment of the deepest existing ancestor before any `mkdir -p`.** `sim-gh1638.patch:31-40` refuses `.`/`..`/empty segments lexically, resolves the worktree physically (`_wtp`), walks up from `$wt/$(dirname "$a")` to the deepest existing ancestor, resolves it with `cd … && pwd -P`, and requires it inside `$_wtp` — all *before* the `mkdir -p` at `:41`. My replay of the reviewer's exact fixture (checkout `parent` symlink → outside, real host dir) printed `REFUSE seed parent/new/seeded: an existing ancestor does not resolve inside the worktree`, rc=1, empty stdout, `outside/new` not created, no `rm` invoked. The capture plan states the same order (`GH-1638-RELAY-SEED-DIR-NESTING.md:55`). Post-mkdir re-resolution (`sim-gh1638.patch:42-47`) closes the race/non-symlink remainder.
  2. **[Pass] Round-4 Blocker criterion (b) — Git-managed teardown only, refusal reported, no raw `rm -rf` of the worktree.** All six failure paths call the one helper `_rtl_seed_abort` (`sim-gh1638.patch:9-15`), which runs only `git -C "$RTL_ROOT" worktree remove --force` and on refusal prints `git worktree remove refused … left in place for inspection`. No `rm -rf "$wt"` exists in the new code; the only raw removal is `rm -rf "$_dst"` (`:48-52`) whose parent was just proven inside the worktree — permitted by the falsifier and required for the mirror. `WORKTREE-SAFETY.md:59-88` mandates exactly this. Probe arm 5 (`probe-gh1638.sh:78-92`) verifies refusal-reporting plus no raw deletion; my shadowed-git replay reproduced it.
  3. **[Pass] Discrimination.** `matrix.txt:10-17` — base 1 (observed live), source-only sim 1 (package-drift check at `probe-gh1638.sh:10-12`, with `pkg-freshness-arms.txt:1-12` recording the existing freshness gate 1→0), with-package 0 (observed live, `GREEN_RC=0`), and all five retained fakes 1: skip-dirs (fails arm-1 current-bytes at `probe-gh1638.sh:31`), overlay (fails deleted-child at `:33`), rm-unchecked (arm 3, `:49-61`), mkdir-first (arm 4, `:62-77`), no-dotdot-guard (arm 6, `:93-106` — my replay confirms the guardless variant creates the outside directory before refusing, so the probe genuinely catches it).
  4. **[Pass] No fake reading fixed leaves a defect or new containment hole.** The probe exercises the real `rtl_worktree_begin` against dynamically built fixtures (no hardcodable names), requires a usable returned path before content checks (`:28-29`), pins package bytes, and every retained fake has a failing arm. The one probe gap — no arm for a `.`- or empty-segment entry — does not rise to a hole for the *planned* fix (the sim refuses all three at `:32`), and the physical re-checks bound the realistic inputs.
  5. **[Nit] Probe arm 6 covers only `..`; `.`/empty segments are guarded in plan and sim but unexercised.** Concrete input that would defeat a non-compliant builder: `RTL_ALLOW=(".")` with host `.` existing — a fix guarding only `..` would pass all six arms while `rm -rf "$wt/."` deletes the worktree mid-seed. The remediation string explicitly requires refusing all three (`GH-1638-RELAY-SEED-DIR-NESTING.md:108`), and `RTL_ALLOW` is operator-supplied config, so this is coverage hygiene, not a packet defect. Related, same nit: the guard also refuses trailing-slash entries (`"seeded/"` → `*//*`), a loud behavior change for a config shape no known consumer uses; and the pre-existing SEED-DELETE branch (`relay-automation/relay-turn-lib.sh:787-789`, declared non-goal at capture `:13`) stays unguarded for `..` entries — fold the lexical guard over the whole loop at implementation time or park it.
  6. **[Pass] Scope is still one-turn Jog.** Final shape: one seed-loop branch plus one small helper in one file (`sim-gh1638.patch`, ~48 added lines) plus `make-pkg.sh` regeneration and a delivery receipt — exactly the capture's "one loop plus one small helper in one file" (`GH-1638-RELAY-SEED-DIR-NESTING.md:55,58`). The hardening was reviewer-demanded, is proportionate to a recursive-delete seam, and stays within the GH-831 envelope (no new suite; existing `test/worktree-isolation.sh` gate, existing freshness check, manual inline probe). Failure handoff unchanged: `utils/py/rtl.py:1156-1161` returns None and the caller exits 5 as documented.
  7. **[Pass] Contract truthfulness.** Acceptance and the four `[added]` criteria (`GH-1638-RELAY-SEED-DIR-NESTING.md:33-45`) match the probe's assertions one-to-one; pin `6142128d9c433d6b12972c6cd9a6f864f0ed9da2`, gate, artifacts and `round_cap: 9` are consistent with `SUMMARY.md:8,17` and the review thread's parser/linter read-backs (rounds 2-4 verified).

  ## RECOMMENDATION

  Publish the #1638 packet as-is; optionally add a `.`-segment probe arm at implementation time, and fold the segment guard across the whole seed loop (including SEED-DELETE) when the real fix lands.

To resume this session: kimi -r session_f2c10c76-a53d-4689-982f-338daeb5a2d7
