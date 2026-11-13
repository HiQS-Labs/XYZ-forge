• Let me read the relevant files.relay-automation/relay-turn-lib.sh:826:  mkdir -p "$wt/.relay-scratch"
relay-automation/relay-turn-lib.sh:898:    case "$path" in .relay-scratch|.relay-scratch/|.relay-scratch/*) continue ;; esac
relay-automation/relay-turn-lib.sh:1067:    role_note=' You are the REVIEWER this turn: do NOT edit or create any artifact or source file; the relay file is the only tracked file you may change. You MAY run narrow, non-mutating probes and queries against the seeded artifact to measure a claim. Put probe output and temp files under .relay-scratch/ or $TMPDIR, never elsewhere in the tree: export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR". Scratch is discarded after your turn, so quote the command, exit status and decisive output in the finding itself. Do NOT run validate.sh, test/*.sh, pytest, or executable fixtures here, except a phase gate command that the REVIEWER steps in your relay file explicitly tell you to run (GH-1428) — those belong in a disposable full clone; a claim that can only be measured that way is graded [Unverified — needs clone run], and the harness gate runs after your turn. Any other change to the tree is reverted and fails your turn. When approving, hand the token off with done and set STATUS: Approved.'
relay-automation/relay-turn-lib.sh:1075:  local scratch_note=" Verification output (probe results, generated JSON, logs) goes under .relay-scratch/ — pre-created for you, exempt from containment, never copied back; scratch files anywhere else in the tree are reverted and FAIL your turn."
relay-automation/relay-turn-lib.sh:1078:    prog_note=" Programmatic tool mode is enabled: diagnostic Python scripts may be executed via script_runner.py with output directed to .relay-scratch/."
relay-automation/relay-turn-lib.sh:1232:# Deliberately NARROW — this is a room, not an amnesty (same line GH-91 drew for .relay-scratch):
relay-automation/relay-turn-lib.sh:1240:# for inspection) — NOT .relay-scratch/, which rtl_enforce sweeps at end of turn and which would
relay-automation/relay-turn-lib.sh:1274:  printf '%s-turn: SCRATCH RELOCATION (GH-113): untracked %s moved to %s — turn NOT failed. Write scratch under $TMPDIR or .relay-scratch/ instead.\n' \
relay-automation/relay-turn-lib.sh:1318:  case "$p" in .relay-scratch|.relay-scratch/|.relay-scratch/*)
relay-automation/relay-turn-lib.sh:1319:    rm -rf "${RTL_ROOT:?}/.relay-scratch"
relay-automation/relay-turn-lib.sh:1550:  [[ -d "${RTL_ROOT:?}/.relay-scratch" ]] && rm -rf "${RTL_ROOT:?}/.relay-scratch"
921:    rtl_scratch_relocate "$path" "$wt" "$RTL_ROOT" nested && continue   # GH-1002: nested files too
922:    rtl_scratch_relocate_dir "$path" "$wt" "$RTL_ROOT" && continue      # GH-1002: all-scratch new dir
1213:rtl_orphan_backup() {  # <path> — copy pre-revert content aside; must never block the revert
1249:rtl_scratch_shaped() {  # <path> <src-root> [nested] — 0 = untracked scratch-shaped file/path, no side effects
1268:rtl_scratch_relocate() {  # <path> <src-root> [dest-root] [nested] — 0 = relocated, 1 = not scratch-shaped
1270:  rtl_scratch_shaped "$p" "$src_root" "$mode" || return 1
1276:  rtl_log_always "rtl_scratch_relocate: path=$p src=$src_root dest=$dest (GH-113)"
1281:# inside it never reaches rtl_scratch_relocate. Expand only such an entry (the caller has already
1284:rtl_scratch_relocate_dir() {  # <dir/> <src-root> <dest-root> — 0 = whole dir relocated, 1 = not all scratch
1290:  for f in "${files[@]}"; do rtl_scratch_shaped "$f" "$src_root" nested || return 1; done
---
      "${RTL_TOOL:-relay}" "$drift_count" >&2
  fi
}

rtl_was_dirty_before() {  # <porcelain-entry> — true if this exact status+path was dirty pre-turn
  local e="$1" b
  for b in ${RTL_BEFORE[@]+"${RTL_BEFORE[@]}"}; do [[ "$b" == "$e" ]] && return 0; done
  return 1
}

# GH-141 — recoverability-only mitigation for the concurrent peer-edit race.
#
# rtl_check CANNOT distinguish "a peer session's concurrent mid-turn edit" from "the agent's own
# off-lane self-escape": both produce byte-identical porcelain diffs, and rtl_before's snapshot is
# taken once at turn start, so anything that turns dirty DURING the turn window looks identical.
# Any fix of the shape "don't revert a newly-dirty non-allowlisted path" would silently disable
# rtl_enforce's documented backstop against the already-observed GH-22 self-escape vector.
#
# So the revert DECISION IS DELIBERATELY UNCHANGED. This only copies the pre-revert content aside
# first, turning "not recoverable in general" (GH-141's live 2026-07-05 incident, and a second
# occurrence on 2026-07-18) into a recoverable one. Mirrors the refs/relay-orphan/<sha> pattern
# rtl_enforce already uses for the moved-HEAD case. Backups land under .tick/, which rtl_check
# exempts intrinsically, so a backup can never itself be flagged as off-lane.
rtl_orphan_backup() {  # <path> — copy pre-revert content aside; must never block the revert
  local p="$1" dest
  [[ -n "$p" && -e "$RTL_ROOT/$p" ]] || return 0
  : "${RTL_ORPHAN_BACKUP:="$RTL_ROOT/.tick/orphan-backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
  dest="$RTL_ORPHAN_BACKUP/$p"
  mkdir -p "$(dirname "$dest")" 2>/dev/null || return 0
  cp -R "$RTL_ROOT/$p" "$dest" 2>/dev/null || return 0
  printf '%s-turn: pre-revert copy of %s saved under %s\n' "$RTL_TOOL" "$p" "$RTL_ORPHAN_BACKUP" >&2
  rtl_log_always "rtl_check: orphan-backup path=$p dest=$RTL_ORPHAN_BACKUP"
}

# GH-113 — relocate, don't fail, the headless builder's root-level scratch.
#
# The observed incident (marathon/daybreak-wave-2, 2026-08-20): the A builder wrote fix_lens1.py /
# test_lens6.py / tmp.json into the working-tree ROOT while debugging, rtl_check reverted them at
# exit 6, and a turn whose actual lane work was fine died on incidental scratch. Prose in the prompt
# is not a guarantee the builder model weights, so this is the mechanical half of the fix: a
# scratch-SHAPED write is moved into the sanctioned scratch lane and the turn proceeds.
#
# Deliberately NARROW — this is a room, not an amnesty (same line GH-91 drew for .relay-scratch):
#   - ROOT-LEVEL only (no "/" in the path): the incident shape is a transient script dropped in the
#     tree root; a nested off-lane path is a lane mistake, not scratch, and still violates.
#   - UNTRACKED only: an edit to a TRACKED file is an off-lane content change whatever its name —
#     the GH-22 self-escape backstop must keep biting there (GH-113 acceptance pins this).
#   - NAME must look like transient scratch (tmp*/temp*/scratch*/debug*/test_*/fix_*/repro_*/probe_*
#     prefix, or *.tmp/*.temp/*.bak/*.orig/~ suffix). "offlane.md" and friends still violate.
# The destination is .tick/scratch/ (exempted intrinsically, never rides into a commit, recoverable
# for inspection) — NOT .relay-scratch/, which rtl_enforce sweeps at end of turn and which would
# therefore destroy the evidence this function exists to preserve.
#
# GH-1002 widened two things, worktree side only where it matters:
#   - hyphenated prefixes (test-*, fix-*, repro-*, probe-*) count as scratch — A names probes that way;
#   - with the 4th arg `nested` (passed ONLY by rtl_worktree_end), a nested untracked FILE whose
#     basename is scratch-shaped relocates too. That is safe there because worktree copy-back is
#     allowlist-only, so nothing outside the lane can land in ROOT either way; the in-ROOT rtl_check
#     path never passes `nested`, so a nested scratch-shaped path there still violates (gh113 2b).
rtl_scratch_shaped() {  # <path> <src-root> [nested] — 0 = untracked scratch-shaped file/path, no side effects
  local p="$1" src_root="$2" mode="${3:-}" name
  [[ -n "$p" && -n "$src_root" ]] || return 1
  case "$p" in ""|.|..|.*|*/) return 1 ;; esac
  if [[ "$p" == */* ]]; then
    [[ "$mode" == nested ]] || return 1
    case "/$p" in */.*) return 1 ;; esac   # no dot-directory components
    [[ -f "$src_root/$p" ]] || return 1
  fi
  name="${p##*/}"
  [[ "$name" =~ ^(tmp|temp|scratch|debug|(test|fix|repro|probe)[-_]) ]] \
    || [[ "$name" =~ \.(tmp|temp|bak|orig)$ ]] \
    || [[ "$name" == *~ ]] \
    || return 1
  git -C "$src_root" ls-files --error-unmatch -- "$p" >/dev/null 2>&1 && return 1
  [[ -e "$src_root/$p" ]] || return 1
  return 0
}

rtl_scratch_relocate() {  # <path> <src-root> [dest-root] [nested] — 0 = relocated, 1 = not scratch-shaped
  local p="$1" src_root="$2" dest_root="${3:-$2}" mode="${4:-}" dest
  rtl_scratch_shaped "$p" "$src_root" "$mode" || return 1
  dest="${RTL_SCRATCH_DIR:="${dest_root:?}/.tick/scratch/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
  mkdir -p "$dest/$(dirname "$p")" 2>/dev/null || return 1
  mv "$src_root/$p" "$dest/$p" 2>/dev/null || return 1
  printf '%s-turn: SCRATCH RELOCATION (GH-113): untracked %s moved to %s — turn NOT failed. Write scratch under $TMPDIR or .relay-scratch/ instead.\n' \
    "${RTL_TOOL:-relay}" "$p" "$dest" >&2
  rtl_log_always "rtl_scratch_relocate: path=$p src=$src_root dest=$dest (GH-113)"
  return 0
}

# GH-1002: git's default porcelain reports a wholly new directory as ONE "dir/" entry, so a probe
# inside it never reaches rtl_scratch_relocate. Expand only such an entry (the caller has already
# applied the allowlist and containment-ignore checks): relocate its files only if EVERY one is
# scratch-shaped; otherwise move nothing and let the caller flag the entry off-lane as before.
rtl_scratch_relocate_dir() {  # <dir/> <src-root> <dest-root> — 0 = whole dir relocated, 1 = not all scratch
  local d="$1" src_root="$2" dest_root="$3" f files=()
  [[ "$d" == */ ]] || return 1
  while IFS= read -r -d '' f; do files+=("$f"); done \
    < <(git -C "$src_root" ls-files --others --exclude-standard -z -- "$d" 2>/dev/null)
  ((${#files[@]} > 0)) || return 1
  for f in "${files[@]}"; do rtl_scratch_shaped "$f" "$src_root" nested || return 1; done
Now let me look at the tests: gh91, gh184, gh113. Also check how the shell lib handles RTL_ROOT being a worktree — `git clean -fdxq -- .relay-scratch` in a linked worktree — `git clean` in a worktree only cleans that worktree; fine. But question: does the plan miss other delete/move sites? Only two `rm -rf .relay-scratch` sites per grep. Check rtl_scratch_relocate destination — goes to .tick/scratch, not .relay-scratch. Worktree path: scratch created in $wt and discarded with the worktree (rm of worktree dir presumably). Let me check rtl_worktree_end end / worktree removal for scratch copyback — line 898 continue, never copied back. Fine.

  Now check the tests.

• Now the tests:

• Now let me verify a few technical points:

  1. `git clean -fdxq -- .relay-scratch` behavior:
     - `-x`: removes ignored files too. Good.
     - `-q` quiet.
     - Tracked files: `git clean` never removes tracked files. Good.
     - In rtl_check, porcelain path forms: `.relay-scratch` (deleted tracked file — ` D .relay-scratch/pdf/tracked.json` gives path `.relay-scratch/pdf/tracked.json`), collapsed `.relay-scratch/` (untracked dir), `?? .relay-scratch/tmp/`, ` D` of tracked file, ` M` of tracked file. Plan: exempt only when `ls-files --error-unmatch` fails → tracked paths fall through to off-allowlist handling, which does `git checkout -- "$p"` and RTL_VIOLATION=1. 

     Concern: `git clean -fdxq -- .relay-scratch` — with a pathspec. Does git clean support pathspec? Yes, `git clean <pathspec>`. The `-d` removes untracked directories. One subtlety: when the porcelain path is a collapsed dir `.relay-scratch/`, the untracked dir `.relay-scratch` contains turn-created files. `git clean -fdxq -- .relay-scratch` from $RTL_ROOT removes the whole dir. Good.

     Wait — one edge: `git clean` when RTL_ROOT is a linked worktree: `git -C "$RTL_ROOT" clean` operates on the worktree's directory; scratch would be inside the worktree. Fine. But non-worktree turns: RTL_ROOT is the main checkout.

     Nested git repo inside scratch: `git clean -d` doesn't descend into nested git repos by default? Actually `git clean -fd` — directories containing a .git are not removed unless `-ff` (double force). So a nested repo inside .relay-scratch would survive `git clean -fdx` and linger → but that's an obscure edge; turn-created nested repos would linger. Minor. Actually `git clean` docs: "-ff ... Git will refuse to delete directories with .git sub folder or file unless a second -f is given". So single `-f` leaves the nested repo dir. Then the sweep at rtl_enforce also leaves it. Result: scratch dir partially survives, and next turn's sweep attempts again. Not a data-loss issue but a "scratch lingers" issue. Nit-level.

     Paths with spaces: pathspec `.relay-scratch` quoted; paths from `-z` are NUL-delimited and passed to rtl_check as whole strings; the case pattern matches prefixes fine. git clean pathspec `.relay-scratch` matches the dir and everything under. Fine.

     Another edge: in rtl_check the `rm -rf` ran on every matching porcelain entry; with `git clean` it runs per entry too — idempotent, fine.

     Edge: `git clean` fails if scratch path is actually... if RTL_ROOT isn't a git repo? rtl_check assumes git repo (git checkout used). Fine.

     Edge: `.relay-scratch` dir containing a tracked file AND untracked files — `git clean -fdx -- .relay-scratch` removes untracked, keeps tracked. 

     One real concern in rtl_check: the plan keeps the exemption branch ordered before rtl_scratch_relocate. For a tracked `.relay-scratch/pdf/tracked.json` modification, fall-through: rtl_in_allow? no. rtl_scratch_relocate — requires untracked (ls-files check in rtl_scratch_shaped returns 1 for tracked) → falls to revert path. `git checkout -- "$p"` restores tracked file. Good.

     But what about a ` D` (deleted tracked file)? rtl_orphan_backup checks `-e "$RTL_ROOT/$p"` — deleted file doesn't exist, backup skipped, fine. `git checkout -- "$p"` restores it. Good.

     Rename R: porcelain -z `R  new -> old`? With -z the format is `R  new\0old\0`? Actually -z reverses the order: "R  new\0old\0". Code at 1539 calls rtl_check "$path" (dest) and rtl_check "$src". If a tracked file under .relay-scratch is renamed to elsewhere: src is tracked under scratch → falls through, reverts. Dest path handled normally. Fine.

  2. Does anything else delete/move .relay-scratch? Grep showed only lines 826 (mkdir), 898 (exempt in worktree_end), 1319, 1550 (the two rm sites), plus prompt text. Also check relay-drive.sh/marathon-drive.sh — grep showed no matches there. Also check worktree removal code — worktree scratch is discarded with worktree; plan covers. Also rtl_scratch_relocate dest is .tick/scratch — not .relay-scratch. Good.

     Wait — also check consult.sh and other drivers use the same lib. And check if anything does `git clean` elsewhere... The plan misses nothing per grep. But let me double-check for ".relay-scratch" across relay-automation more broadly (already did — the grep covered all three files plus showed lib). Let me grep the whole relay-automation dir to be safe. Also check rtl_worktree_end's teardown — does it rm -rf the worktree (which contains scratch)? That's fine and not ROOT.

  3. gh91 section 1 & 6: 
     - Section 1: rtl_check ".relay-scratch/out2.json" → with new code: ls-files --error-unmatch fails (untracked) → exempt → git clean -fdxq -- .relay-scratch → dir removed. Assertions: RTL_VIOLATION=0 ✓, dir gone ✓.
     - Collapsed form ".relay-scratch/" ✓.
     - Section 6: enforce repo with .gitignore of .relay-scratch/: porcelain omits it, loop doesn't fire; sweep `[[ -d ... ]] && git clean -fdxq -- .relay-scratch` → dir removed. Assertions: exit 0 ✓ (clean -q returns 0), dir gone ✓, tree clean except .tick ✓. One caveat: git clean -x on ignored dir — `.relay-scratch/` is ignored; with -x, clean removes it. ✓. Note: assertion at line 169 greps porcelain excluding `?? .tick/` — git clean doesn't touch .tick (pathspec limited). ✓
     - One subtle change: `git clean -fdxq -- .relay-scratch` when the dir doesn't exist → `[[ -d ]]` guard at 1550 handles. In rtl_check, the case fires only when a porcelain path matched, so the dir/path exists — but for the deleted-tracked-file form ` D .relay-scratch/pdf/tracked.json`: untracked siblings cleaned, tracked restored later by fall-through (no — fall-through is per-path: ` D` of tracked file falls through since tracked → checkout restores; the exempt branch not taken). Hmm wait: with ` D` form, the porcelain path is `.relay-scratch/pdf/tracked.json`, case matches `.relay-scratch/*`, ls-files succeeds (tracked) → fall through → revert ✓.
     - Would any assertion change? One: previously rm -rf removed the dir even if it contained a nested git repo; git clean -d without -ff won't. gh91 has no such case. Also previously, rtl_check's rm -rf ran even if... e.g. path `.relay-scratch/` collapsed where the dir contains only ignored files? git clean -fdx handles ignored. What about a tracked dir `.relay-scratch` itself (the dir tracked, i.e. contains tracked files)? clean leaves tracked files; empty parent dirs remain (git clean removes only untracked dirs; a dir containing tracked files stays, possibly now-empty subdirs removed). gh91 asserts `[ ! -d "$R/.relay-scratch" ]` — in its fixture scratch is wholly untracked → dir fully removed ✓. But in a host repo with tracked files under .relay-scratch, after clean the dir remains (with tracked files) — that's the intended outcome (host content preserved).

  4. Failing the turn on tracked-file modification under .relay-scratch: The room/line GH-91 drew: "scratch is a room, not an amnesty" (gh91 section 2, gh113 controls). A tracked file under .relay-scratch is host content; modifying it is an off-lane edit to a tracked file — same as any other. gh113 2c pins that tracked off-lane edits still violate. The reviewer prompt at line 1067 tells models probes go under .relay-scratch — but probes there are untracked files, still exempt; only touching tracked host files fails. Consistent with the existing containment philosophy. Also note GH-184 keeps Forge itself from tracking scratch, so in Forge's own relays this never fires. Failing is right; also note the fallback: if we instead silently reverted without failing, a model could repeatedly clobber host content undetected. The turn failing signals the host to inspect.

     One nuance: RTL_VIOLATION=1 + exit 6 is per-path in the revert branch; the plan's fall-through handles both modified and deleted tracked files (checkout -- restores deletion; orphan_backup covers modification). Good.

  5. Over-built or missing:
     - Missing: the `[[ -d ]]` guard stays; fine.
     - Potential missing piece: `git clean -fdxq` — the `-x` flag also nukes ignored files under .relay-scratch, which matches "turn-created scratch (untracked or ignored)". OK.
     - Missing consideration: exit code of git clean if it fails (e.g. permission) — with `&&` chained at 1550, a clean failure silently skips sweep; same as rm -rf failure before. Nit.
     - One real gap: in rtl_check, the new ls-files exemption uses `git -C "$RTL_ROOT" ls-files --error-unmatch -- "$p"` where $p may be `.relay-scratch/` (trailing slash). Does ls-files handle trailing slash pathspec? `git ls-files --error-unmatch -- ".relay-scratch/"` — pathspec magic... trailing slash should still match everything under it; if tracked files exist, returns match → treated as tracked → falls through to off-allowlist handling with `git checkout -- ".relay-scratch/"` → error (checkout with trailing slash on dir fails), then `rm -rf "$RTL_ROOT/.relay-scratch/"` — wait the fallback at 1345: `git checkout -- "$p" 2>/dev/null || rm -rf "$RTL_ROOT/${p%/}"`. That would rm -rf the whole scratch dir including tracked files... but wait, can the collapsed form `.relay-scratch/` appear in porcelain when tracked files exist under it? No — collapsed form appears only when the directory is wholly untracked. If tracked files exist under .relay-scratch and are modified, porcelain shows individual paths, not the collapsed form. So `.relay-scratch/` + tracked is impossible from porcelain. OK — but rtl_check is also driven directly... fine.

       Actually hold on — edge: mixed dir: tracked file under .relay-scratch plus untracked new file. Porcelain shows ` M .relay-scratch/pdf/tracked.json` and `?? .relay-scratch/tmp/`. Two entries; tracked one falls through (revert + violation), untracked one exempt → clean. Order matters not. Fine.

     - Missing: plan says nothing about the `RTL_SCRATCH_DIR`/GH-113 relocation dest `.tick/scratch` — unaffected.
     - Over-built? Plan is minimal. Possibly under-built nit: git clean -fd (single f) won't remove a nested git repo inside scratch → scratch lingers partially. Consider `-ff`? That'd be `clean -ffd xq`. Does gh91 require? No. But "turn-created scratch still disappears, folder included" acceptance — if a turn clones a repo into scratch (rare), it lingers. Nit.
     - Another subtle: `git clean -fdxq -- .relay-scratch` when RTL_ROOT has `.relay-scratch` tracked as a *file*? Bizarre; skip.
     - What about `core.excludesFile` or pathspec magic chars in ".relay-scratch"? Literal dot path, fine.
     - Worktree (linked worktree as RTL_ROOT) with git clean: `git -C wt clean` — clean works in worktrees, removes only from that worktree's dir. But non-worktree turns RTL_ROOT is main checkout. Note AGENTS says never run driven lanes from linked worktrees anyway. Fine.

     - Also check: does rtl_enforce's sweep now leave the empty dir? `git clean -d` removes untracked dirs entirely after removing contents — yes, removes the dir itself.

     - One more potential missed site: grep for "relay-scratch" in relay-automation other files (consult.sh, agy-turn.sh etc.)? Grep only covered 3 files. Let me grep the dir. Also check `rtl_worktree_end`'s worktree removal — `git worktree remove --force` handles it.

  Let me quickly grep whole relay-automation.

• One more sweep for other scratch-touching sites across the automation dir:

• Good — only two destructive sites. I have everything I need. Write the answer.

• ## ANSWER

  The plan is correct and minimal. Both edits do what they claim: `git clean -fdxq -- .relay-scratch` (a) removes untracked *and* ignored files plus empty untracked dirs under the pathspec while never touching tracked files, and (b) works identically when porcelain can't see the dir (GH-91's ignored-scratch case). The `ls-files --error-unmatch` gate in `rtl_check` correctly splits the two populations: untracked/ignored scratch → exempt + clean; tracked host content → falls through to the existing orphan-backup + `git checkout --` + `RTL_VIOLATION=1` path (`relay-automation/relay-turn-lib.sh:1341-1346`). No other file in `relay-automation/` deletes or moves `.relay-scratch` — the only other sites are the worktree-side `mkdir` (`:826`), the copy-back exemption (`:898`), and prompt text (`:1067`,`:1075`). Worktree scratch dies with the worktree teardown, which never touches ROOT's tracked files, so the plan's "Not changed" note is accurate. The gh91 suite's sections 1, 2, and 6 still pass; nothing it asserts changes. Failing the turn (exit 6) on a tracked `.relay-scratch` file edit is the right outcome — it's the same "room, not an amnesty" line GH-91/GH-113 already pin, and GH-184 keeps Forge itself from ever tracking scratch, so in-repo turns never hit it.

  ## FINDINGS

  - **[Should]** Sweep robustness against a nested git repo: `git clean -fd` (single `-f`) refuses to remove a directory containing its own `.git` unless doubled (`-ff`). A turn that clones/init's a repo inside `.relay-scratch` (plausible for a probe) would leave residue that lingers turn after turn — the exact "scratch lingers in ROOT" failure GH-91's unconditional sweep exists to prevent. One extra `f` (`git clean -ffdxq -- .relay-scratch`) closes it with no other behavioral change. Not covered by gh91, so nothing pins the current spelling.

  - **[Nit]** Deleted-tracked-file form (` D .relay-scratch/pdf/tracked.json`): falls through correctly, but `rtl_orphan_backup` (`:1213-1227`) no-ops because the file no longer exists (`[[ -e "$RTL_ROOT/$p" ]]` guard) — the pre-delete content is only recoverable via `git checkout`, not the backup. Pre-existing behavior of the revert path for all deletions, not a plan defect; worth one line in the manual-check notes.

  - **[Nit]** A `git clean` failure at `:1550` (`... ]] && git clean ...`) silently skips the sweep, same as `rm -rf` failing today — no regression, but the acceptance's "scratch disappears" claim assumes clean exits 0 (it will in practice; pathspec is literal, no magic chars, `.` -prefixed literal is not pathspec magic).

  - **[Nit]** In a host repo that tracks files under `.relay-scratch/`, the dir itself will now survive turns (containing only tracked files). That is the *intended* outcome of the plan ("tracked files are host content"), but hosts will see a persistent `.relay-scratch/` dir where GH-91's docs said scratch never lingers — a README line in `relay-automation/README.md:26` may eventually need a caveat. Not required for the fix.

  - **[Pass]** Collapsed form `.relay-scratch/`: only ever produced by porcelain when the dir is wholly untracked, so the `ls-files` gate can't misfire on it; clean removes it (gh91 line 67-73 pins this and still passes).

  - **[Pass]** ` M` of a tracked file under scratch: `ls-files --error-unmatch` succeeds → falls through → `git checkout -- "$p"` restores + violation. Matches gh113 section 2c's pinned principle (`test/gh113-headless-scratch.sh:85-89`).

  - **[Pass]** Renames (`R`): both `src` and `dest` are passed to `rtl_check` (`:1539`); a tracked scratch path as either side falls through to normal handling. Spaces in paths are safe: `-z` NUL-delimited porcelain and the literal pathspec.

  - **[Pass]** Linked worktree as RTL_ROOT: `git -C <wt> clean` operates only on that worktree's working dir; and driven lanes are forbidden from linked worktrees anyway (AGENTS.md/WORKTREE-SAFETY), so this is out of envelope.

  - **[Pass]** Question 4's prompt concern: the reviewer prompt (`:1067`) sanctions *new probe output* under `.relay-scratch` — still exempt. Only edits to *host-tracked* content there fail, which is precisely GH-113's documented "tracked off-lane edit still violates" control. Silently reverting instead would let a model repeatedly clobber host files with no signal; exit 6 is the harness's escalation contract.

  ## RECOMMENDATION

  Ship the two edits as planned, with `git clean -ffdxq` (double `-f`) at both sites and one line in the plan's manual-check section noting that a ` D` tracked-scratch path has no orphan backup.
