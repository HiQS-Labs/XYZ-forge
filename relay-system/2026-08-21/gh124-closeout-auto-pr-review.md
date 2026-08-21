# Relay: Architectural Review of End-of-Day Closeout & Auto-PR Automation (GH-124)
STATUS: Active
NEXT: aider

<!-- relay-drive: task=RELAY-GH124-CLOSEOUT-REVIEW producer=claude reviewer=aider round-cap=4 -->

## Phase Brief

Review the proposed architectural solutions and quick wins for eliminating end-of-day friction in marathon and ad-hoc multi-agent sessions, as tracked in [HiQS-Suite/XYZ-forge#124](https://github.com/HiQS-Suite/XYZ-forge/issues/124).

---

### Context & Problem Statement

Every marathon run and intensive ad-hoc task in `XYZ-forge` operates in a linked git worktree or separate full clone for containment. Over an 8-hour working day with multiple parallel lanes:
1. **QA Ambiguity:** It takes considerable manual effort to determine which phases were QA'ed, which model (Agy, Codex, Claude) reviewed them, and where the test receipts live.
2. **Merge Drift & Late Conflicts:** Parallel lanes push to `development` throughout the day; an active long-running lane is blindsided by merge conflicts at closeout.
3. **Manual PR Overhead:** Operators must manually push branches, write PR descriptions, link issues, and attach telemetry receipts.
4. **Workspace Residue:** Multiple ephemeral full clones and linked worktrees accumulate on disk, requiring tedious auditing and cleanup.

---

### Proposals Under Review

#### Category 1: Quick Wins (SOPs, Flags & Lightweight Helpers)
- **QW1 (In-Flight Phase QA Attestation):** When a reviewer turn produces `Approved`, the driver automatically posts a 2-line receipt comment to the GitHub issue and/or prepends a tag to the issue title (`[QA: Codex Pass]`).
- **QW2 (One-Shot PR Scaffold `marathon-closeout.sh --auto-pr`):** A helper script that validates the branch against pre-push, pushes to origin, and executes `gh pr create --base development --head <branch>` with automated summary markdown.
- **QW3 (Workspace Garbage Collector `xyz workspace sweep`):** A script that audits all linked worktrees and disposable clone folders, verifies `git log origin/development..<branch>` is empty (all commits pushed), and removes clean workspaces in one step.
- **QW4 (Early Rebase Drift Alert):** A pre-turn hook in `relay-turn-lib.sh` that fetches `origin/development` and alerts the builder if the trunk has moved ahead by $>3$ commits before starting a long build turn.

#### Category 2: Medium Complexity Solutions (Driver-Native & Tooling Integrations)
- **M1 (Driver-Native PR Synthesis in `marathon_drive.py`):** When all phases in a marathon wave reach terminal state `Approved`, the driver synthesizes reviewer notes, test receipts, and telemetry into a standardized PR against `development` with label `automated-lane / ready-for-review`.
- **M2 (Ephemeral Workspace CLI `utils/py/workspace_manager.py`):** Formalize disposable clone lifecycle under `xyz clone new|sync|pr-and-sweep`.
- **M3 (Live Standup Closeout Dashboard `/standup`):** Extend `/standup` to aggregate all daily active worktrees, unpushed branches, open PRs, and QA attestation into a single formatted Markdown/HTML view.

---

### Objective for Reviewer (Aider -> OpenRouter -> stealth/ox-alpha)

1. **Safety & Invariant Analysis:** Identify potential regression risks, dangerous edge cases, or false-assurance hazards in these proposals (e.g., risk of auto-PR opening incomplete/broken PRs, risk of workspace GC deleting uncommitted/unpushed work, risk of git index corruption during background rebase checks).
2. **ROI & Priority Ranking:** Rank the proposed Quick Wins and Medium solutions by implementation cost vs. daily operator friction reduced.
3. **Concrete Implementation Guidance:** Recommend specific safeguards (e.g. verification predicates, CLI flags, `--dry-run` defaults, fail-closed guards) that must be enforced before adopting these features in `marathon_drive.py` and `relay_drive.py`.

---

▶ TAKE YOUR TURN:
Review the proposals and problem statement above. Append your structured review block below, and update `STATUS:` and `NEXT:`.


---

### Review salvaged from openrouter/stealth/ox-alpha transcript (aider-turn.sh · GH-251)

_Aider completed a review turn but did not land it as a relay-file append; the harness
recovered the graded review from the turn transcript verbatim below (attributed, not edited)._

```text
Warning: Input is not a terminal (fd=0).
────────────────────────────────────────────────────────────────────────────────
Aider v0.86.3.dev53+g5dc9490bb
Model: openrouter/stealth/ox-alpha with whole edit format
Git repo: .git with 2,098 files
Warning: For large repos, consider using --subtree-only and .aiderignore
See: https://aider.chat/docs/faq.html#can-i-use-aider-in-a-large-mono-repo
Repo-map: disabled
Added relay-system/2026-08-21/gh124-closeout-auto-pr-review.md to the chat.

--------------------------------------------------------------------------------

► THINKING                                                                      

Let me understand the task. I'm playing the role of "aider" agent in a          
file-based relay. The relay file is                                             
relay-system/2026-08-21/gh124-closeout-auto-pr-review.md. My job:               

 1 Review the proposals (QW1-QW4, M1-M3) for the end-of-day closeout & auto-PR  
   automation.                                                                  
 2 Append a structured review block below the "▶ TAKE YOUR TURN" marker.        
 3 Update STATUS: and NEXT:.                                                    

The NEXT is currently "aider" — meaning it's my turn now. After my turn, I      
should set NEXT to the other agent. The producer was claude, so the other agent 
is claude. The round-cap=4.                                                     

The instructions say: do NOT run tick commands, just edit the file. So I need to
output the entire updated file content with my review appended, and update      
STATUS and NEXT.                                                                

STATUS: currently "Active". After my review turn... Since this is a review relay
with round-cap 4, and I'm the reviewer (aider), after appending my review block 
I should set STATUS appropriately. Options: keep "Active" if more rounds needed,
or "Approved" when approving. The instruction says "(or done + set STATUS:      
Approved when approving)". Hmm — but this is a review of proposals; as reviewer 
I can provide my structured review and then hand back to claude (producer) for  
response, or approve/done.                                                      

Given the objective asks for safety analysis, ROI ranking, and implementation   
guidance, I should provide a thorough review. Then decide: do I approve outright
or send back? The relay has round-cap=4; this appears to be round 1 (producer   
wrote brief, now aider reviews). A reasonable flow: aider reviews, sets NEXT:   
claude so producer can respond/address concerns, STATUS stays Active. Or if my  
review concludes the proposals are sound with safeguards, I could mark          
Approved... but typically the reviewer would want the producer to               
acknowledge/incorporate. However, the task says "Review the proposed            
architectural solutions" — the deliverable IS the review itself. The producer   
already delivered their proposals; my turn is the review. If my review finds    
them acceptable-with-safeguards, I could either:                                

 • Set STATUS: Approved, NEXT: done — ending the relay with my review as final  
   output.                                                                      
 • Keep Active, NEXT: claude — letting producer respond.                        

Given the review objectives are substantive questions directed at me ("Objective
for Reviewer"), and my review answers them, I think the cleanest completion is  
to append the full review and mark STATUS: Approved with NEXT: done, since the  
review itself is the terminal artifact requested. But wait — round-cap=4        
suggests multiple rounds anticipated. The producer might want to respond to my  
critique. Hmm.                                                                  

Actually, looking at the structure: "producer=claude reviewer=aider             
round-cap=4". The producer created the proposals; the reviewer reviews. If the  
reviewer's review contains required changes/safeguards, the producer should     
respond. But the objective explicitly frames MY turn as producing the final     
review deliverable: safety analysis, ROI ranking, implementation guidance.      
There's no request for me to ask clarifying questions back.                     

I'll go with: append comprehensive review, set STATUS: Approved (the proposals  
are conditionally approved with mandatory safeguards), NEXT: done. Actually, let
me reconsider — "STATUS: Approved" per the note means approving. My review does 
identify risks but concludes the proposals are worth adopting WITH safeguards.  
That's an approval with conditions. I'll mark Approved and NEXT: done,          
documenting the conditions clearly in my block.                                 

Hmm, but one could argue keeping it active for claude to respond is better      
collaboration. The relay format with round-cap allows up to 4 rounds. But since 
my review fully addresses all three objectives and doesn't require further input
from the producer, terminating with Approved/done is defensible and cleaner.    
Many relay protocols have the reviewer make the final call. I'll do that.       

Now let me write the actual review content. It needs to be high-quality,        
expert-level software architecture review covering:                             

 1 Safety & Invariant Analysis for each proposal:                               
    • QW1 (QA attestation): risk of false attestation — "Approved" from a       
      reviewer turn may be surface-level; auto-posting receipts could create    
      false assurance. Need verification predicate: attestation must link to    
      concrete artifacts (test run IDs, diff scope). Risk of title-tag          
      drift/collision. Idempotency: don't double-post on retries.               
    • QW2 (--auto-pr): biggest hazard — opening PRs with failing checks or      
      uncommitted changes. Must fail-closed: require clean worktree (git status 
      --porcelain empty), require local CI/gate pass receipt, require issue     
      linkage, --dry-run default? Actually they said dry-run defaults           
      recommended. Also race: branch may be behind development → PR would show  
      conflicts; pre-check mergeability via git merge-tree or gh pr create      
      failure handling.                                                         
    • QW3 (workspace sweep): most dangerous — deleting unpushed/uncommitted     
      work. Guards: never delete if git status --porcelain non-empty; verify git
      log origin/development..<branch> empty AND git rev-parse HEAD ==          
      origin/<branch> (branch pushed to its own remote ref, not just merged into
      development); use git worktree remove rather than rm -rf; refuse paths    
      outside registry; require explicit --yes or interactive confirm; log      
      everything to an audit trail; consider moving to trash/quarantine dir     
      instead of hard delete for N days.                                        
    • QW4 (drift alert): background fetch during a build turn — risk of touching
      git index? Fetch itself doesn't touch working index, but running git      
      concurrently with an active builder process could contend on lock files   
      (.git/index.lock less so for fetch, but refs locking possible). Recommend 
      read-only operations, timeout guards, and caching FETCH_HEAD comparison;  
      alert threshold >3 commits; avoid auto-rebase (explicitly out of scope) — 
      only alert.                                                               
    • M1 (driver-native PR synthesis): same hazards as QW2 amplified —          
      automation at scale. Require terminal-state machine integrity: only       
      synthesize when ALL phases Approved AND gate receipts present AND no      
      unresolved reviewer comments. Label automated-lane / ready-for-review must
      not bypass human review. Rate-limit/fingerprint to prevent duplicate PRs  
      on driver restart (idempotency key = issue number + wave id).             
    • M2 (workspace_manager CLI): good formalization; ensure single source of   
      truth registry (e.g., .xyz/workspaces.json) with stale-lock handling;     
      subcommand pr-and-sweep composes QW2+QW3 guards.                          
    • M3 (standup dashboard): low risk; watch for secret leakage in aggregated  
      logs (tokens in URLs), and performance of scanning many worktrees.        
 2 ROI & Priority Ranking:                                                      
    • QW4 highest ROI (tiny cost, prevents the most expensive failure mode —    
      late merge conflicts).                                                    
    • QW3 next (high friction relief, moderate cost, but needs careful guards). 
    • QW2 (high operator relief; medium cost).                                  
    • QW1 cheap but lower value / some false-assurance risk; do lightweight     
      version.                                                                  
    • M3 medium-high value, low-medium cost.                                    
    • M1 defer until QW2 proven; highest risk.                                  
    • M2 fold into QW3 evolution.                                               
   Provide a ranked table with cost/value/risk.                                 
 3 Concrete Implementation Guidance:                                            
    • Fail-closed predicates list.                                              
    • --dry-run default for sweep and auto-pr; --execute opt-in.                
    • Verification predicate examples (shell snippets).                         
    • Idempotency keys.                                                         
    • Audit logging under .relay-scratch or dedicated log.                      
    • Never auto-push to development directly; always via PR.                   
    • Concurrency: file locks for workspace registry.                           
    • Config flags in marathon_drive.py / relay_drive.py: feature-flag each     
      behavior, default off initially.                                          

Also update header: STATUS: Approved, NEXT: done. And maybe add a "Round 1 —    
aider review" heading before my block.                                          

Format: The file ends with "▶ TAKE YOUR TURN: ... Append your structured review 
block below, and update STATUS: and NEXT:." So I append after that line.        

I should also include the relay-drive comment line? The original has <!--       
relay-drive: task=RELAY-GH124-CLOSEOUT-REVIEW producer=claude reviewer=aider    
round-cap=4 -->. I'll leave it untouched.                                       

Let me draft the appended block:                                                

--------------------------------------------------------------------------------

Round 1 — Reviewer Block (aider)                                                

Verdict: Conditionally Approved — adopt QW4 → QW3 → QW2 → QW1 in that order with
fail-closed guards; defer M1 until QW2 has ≥2 weeks of incident-free operation; 
evolve QW3 into M2; ship M3 anytime.                                            

1. Safety & Invariant Analysis                                                  

Per-proposal table/bullets...                                                   

QW1 — In-Flight Phase QA Attestation                                            

 • False-assurance hazard (HIGH): An Approved verdict from a reviewer turn is   
   not proof tests ran. Auto-posting [QA: Codex Pass] without artifact linkage  
   trains operators to trust unverified tags.                                   
 • Required guard: attestation comment MUST embed machine-checkable receipts:   
   gate command + exit code + commit SHA + timestamp (e.g., gate: validate.sh @ 
   abc1234 → PASS). No receipt, no tag.                                         
 • Idempotency: driver retries/restarts must not double-post; key on (issue,    
   phase-id, reviewer-model) and check for existing comment before posting.     
 • Title-tag mutation: prepending tags mutates a shared identifier; scripts that
   parse titles will break. Prefer labels over title edits where possible; if   
   titles, enforce a strict regex and single-writer (driver-only).              

QW2 — One-Shot PR Scaffold                                                      

 • Broken-PR hazard (HIGH): auto-PR is only safe if the tree is verifiably green
   and clean at push time.                                                      
 • Fail-closed predicate chain (all must pass, abort otherwise):                
    1 git status --porcelain empty (no uncommitted work);                       
    2 HEAD == named branch tip, detached-HEAD → abort;                          
    3 project gate re-run locally OR fresh gate receipt for exact SHA;          
    4 issue linkage resolvable (relay token/issue number present in commit      
      messages or relay file);                                                  
    5 mergeability pre-check vs origin/development (see QW4 synergy).           
 • Default --dry-run: print the exact gh pr create invocation + generated body; 
   require --execute to fire. Never prompt interactively inside marathon turns  
   (non-TTY hangs).                                                             
 • Never target trunk directly: script must hard-fail if base ≠ development     
   unless --base explicitly overridden by a human-typed flag.                   

QW3 — Workspace Garbage Collector                                               

 • Data-loss hazard (CRITICAL): this is the only proposal that destroys work.   
   Treat every deletion as guilty-until-proven-innocent.                        
 • Deletion predicate (ALL must hold):                                          
    1 path is registered in the workspace registry (never sweep by glob/path    
      guess);                                                                   
    2 git status --porcelain empty and no untracked-but-precious files (check   
      against a denylist: .relay-scratch, relay files, telemetry);              
    3 git rev-parse HEAD is reachable from origin/<branch> (branch actually     
      pushed — checking only origin/development..HEAD empty is insufficient: a  
      lane whose branch was never pushed but whose commits were cherry-picked   
      upstream would falsely pass);                                             
    4 no open PR references the branch (gh pr list --head <branch>);            
    5 workspace not locked/active (PID liveness check on lane lockfile).        
 • Soft-delete first: move to quarantine dir (.xyz/trash/<timestamp>-<name>/)   
   with 72h retention; hard purge only via explicit --purge.                    
 • Use git worktree remove, never rm -rf; for full clones, verify path prefix   
   against registry root before any recursive delete.                           
 • Audit log: every sweep decision (kept/deleted + why) appended to a persistent
   log; dry-run prints this table.                                              

QW4 — Early Rebase Drift Alert                                                  

 • Concurrency hazard (MEDIUM): running git fetch inside a live builder turn can
   contend on .git/refs lockfiles and, worse, a naive hook that also runs git   
   rebase would corrupt an in-flight session. Alert-only is correct; codify     
   "this hook must NEVER mutate working state."                                 
 • Implementation: read-only git fetch --quiet origin development with timeout  
   (e.g., 10s) and || true (offline must not kill turns); compare git rev-list  
   --count HEAD..FETCH_HEAD; alert at >3. Cache result per-turn to avoid        
   repeated fetches.                                                            
 • False comfort: alert without action budget is noise. Pair with a suggested   
   (human-approved) rebase checkpoint between phases, never mid-phase.          

M1 — Driver-Native PR Synthesis                                                 

 • Inherits every QW2 hazard at automation scale, plus:                         
 • Duplicate-PR hazard: driver crash/restart mid-closeout can re-fire synthesis.
   Idempotency key = (issue, wave-id); check gh pr list --search before         
   creating.                                                                    
 • Terminal-state integrity: synthesize only when the phase state machine shows 
   ALL phases Approved AND each has a valid QW1-style receipt. One missing      
   receipt ⇒ no PR, surfaced on /standup instead.                               
 • Label semantics: automated-lane / ready-for-review must map to a human review
   requirement in branch protection; it must never be a merge-eligible label.   
 • Recommendation: do NOT build M1 until QW2 has operated ≥2 weeks with zero    
   bad-PR incidents; M1 should literally shell out to the hardened QW2 script   
   rather than reimplementing git logic in Python.                              

M2 — Ephemeral Workspace CLI                                                    

 • Sound direction; becomes the registry that makes QW3 safe. Requirements:     
   single JSON registry with file-lock (flock) semantics, stale-lock TTL, sync  
   must be fetch+ff-only (never rewrite lane branches), pr-and-sweep strictly   
   composes QW2→QW3 predicate chains.                                           

M3 — Standup Dashboard                                                          

 • Low risk. Two cautions: redact tokens/credentials when aggregating remote    
   URLs into the view; bound scan time (many worktrees × git log can stall the  
   dashboard — parallelize with timeout, degrade gracefully).                   

2. ROI & Priority Ranking                                                       

                                                                                
                                     Friction                                   
 Rank  Item           Impl. Cost     Removed       Risk           Verdict       
 ────────────────────────────────────────────────────────────────────────────── 
 1     QW4 drift      XS (~50 LOC    Prevents      Low            Ship first    
       alert          hook)          costliest     (read-only)                  
                                     failure                                    
                                     (late                                      
                                     conflicts)                                 
 2     QW3 sweep      M              High (disk    Critical if    Ship second   
                                     audit pain    unguarded →                  
                                     daily)        guards above                 
                                                   mandatory                    
 3     QW2 auto-pr    M              High (manual  High if        Ship third    
                                     PR overhead   unguarded                    
                                     ×N                                         
                                     lanes/day)                                 
 4     QW1            S              Medium (QA    Medium (false  Lightweight   
       attestation                   ambiguity)    assurance)     version w/    
                                                                  receipts      
 5     M3 standup     S–M            Medium        Low            Anytime       
                                     (visibility)                               
 6     M2 workspace   M              Medium        Low            Evolve from   
       CLI                           (formalizes                  QW3           
                                     QW3)                                       
 7     M1 native PR   L              Same as QW2   Highest        Defer; wrap   
       synth                                                      QW2 later     
                                                                                

Rationale: QW4 is nearly free and attacks the most expensive failure mode.      
QW3/QW2 remove the most daily minutes but are exactly the two components that   
can destroy or publish work — hence the heavy predicate emphasis. M1's marginal 
value over a hardened QW2 is small; its blast radius is not.                    

3. Concrete Implementation Guidance                                             

Global invariants for marathon_drive.py / relay_drive.py:                       

 1 Fail-closed everywhere: any predicate that cannot be evaluated (network down,
   gh auth expired, registry missing) ⇒ abort the destructive/publishing action,
   never skip-and-continue.                                                     
 2 Feature-flag each behavior (XYZ_CLOSEOUT_AUTOPR=0|1, etc.), default off for  
   one sprint; enable per-lane via config.                                      
 3 Dry-run defaults: both --auto-pr and sweep print plans; mutation requires    
   --execute (or env XYZ_EXECUTE=1 for non-interactive marathon use, logged     
   loudly).                                                                     
 4 No interactive prompts in driver context: non-TTY ⇒ fail fast, surface on    
   /standup.                                                                    
 5 Single writer rule: only the driver mutates issue titles/labels/comments;    
   helper scripts invoked manually get --read-only views.                       
 6 Audit everything: append-only JSONL log (who/what/predicate-results/action)  
   per closeout action; this is your incident forensics.                        
 7 Never auto-push to development; trunk moves exclusively through PRs,         
   automated or not.                                                            
 8 Timeouts on all network git ops so a hung fetch can't deadlock a relay turn  
   (cf. tick discipline).                                                       

Suggested predicate snippet (shared lib, e.g. utils/sh/closeout_guards.sh):     

                                                                                
 assert_clean_and_pushed() {                                                    
   local wt="$1" branch="$2"                                                    
   [ -z "$(git -C "$wt" status --porcelain)" ] || die "uncommitted changes"     
   [ "$(git -C "$wt" rev-parse --abbrev-ref HEAD)" = "$branch" ] || die "not on 
 $branch"                                                                       
   git -C "$wt" fetch --quiet origin "$branch" || die "fetch failed"            
   git -C "$wt" rev-parse HEAD >/dev/null && \                                  
     git -C "$wt" merge-base --is-ancestor HEAD "origin/$branch" || die         
 "unpushed commits"                                                             
 }                                                                              
                                                                                

(merge-base --is-ancestor HEAD origin/branch proves the tip is pushed; stronger 
than counting origin/development..HEAD.)                                        

Closing                                                                         

Approve the proposal set as scoped, conditional on the guards above being       
implemented before any destructive/publishing flag ships. Sequence: QW4 →       
QW3(+guards) → QW2(+guards) → QW1(light) → M3; M2 evolves from QW3; M1 deferred 
pending QW2 track record.                                                       

--------------------------------------------------------------------------------

Then update header: STATUS: Approved NEXT: done                                 

Wait — should NEXT be "claude"? The instruction: "when finished, release --to   
the other agent (the role named by NEXT in the file) (or done + set STATUS:     
Approved when approving)." Since I'm approving, I set STATUS: Approved and NEXT:
done. Yes.                                                                      

Hmm, but is "Approved" right for a review of proposals? The relay is a review   
task; my approval = the review is complete and the proposals are endorsed with  
conditions. I'll mark "Approved" and note "conditional" in the body.            
Alternatively STATUS: "Complete". The harness note explicitly ties Approved to  
approving, so Approved it is.                                                   

One consideration: the file listing must contain the ENTIRE file content. Let me
reconstruct the original file exactly and append.                               

Original content:                                                               

                                                                                
 # Relay: Architectural Review of End-of-Day Closeout & Auto-PR Automation      
 (GH-124)                                                                       
 STATUS: Active                                                                 
 NEXT: aider                                                                    
                                                                                
 <!-- relay-drive: task=RELAY-GH124-CLOSEOUT-REVIEW producer=claude             
 reviewer=aider round-cap=4 -->                                                 
                                                                                
 ## Phase Brief                                                                 
                                                                                
 Review the proposed architectural solutions and quick wins for eliminating     
 end-of-day friction in marathon and ad-hoc multi-agent sessions, as tracked in 
 [HiQS-Suite/XYZ-forge#124](https://github.com/HiQS-Suite/XYZ-forge/issues/124) 
 .                                                                              
                                                                                
 ---                                                                            
                                                                                
 ### Context & Problem Statement                                                
                                                                                
 Every marathon run and intensive ad-hoc task in `XYZ-forge` operates in a      
 linked git worktree or separate full clone for containment. Over an 8-hour     
 working day with multiple parallel lanes:                                      
 1. **QA Ambiguity:** It takes considerable manual effort to determine which    
 phases were QA'ed, which model (Agy, Codex, Claude) reviewed them, and where   
 the test receipts live.                                                        
 2. **Merge Drift & Late Conflicts:** Parallel lanes push to `development`      
 throughout the day; an active long-running lane is blindsided by merge         
 conflicts at closeout.                                                         
 3. **Manual PR Overhead:** Operators must manually push branches, write PR     
 descriptions, link issues, and attach telemetry receipts.                      
 4. **Workspace Residue:** Multiple ephemeral full clones and linked worktrees  
 accumulate on disk, requiring tedious auditing and cleanup.                    
                                                                                
 ---                                                                            
                                                                                
 ### Proposals Under Review                                                     
                                                                                
 #### Category 1: Quick Wins (SOPs, Flags & Lightweight Helpers)                
 - **QW1 (In-Flight Phase QA Attestation):** When a reviewer turn produces      
 `Approved`, the driver automatically posts a 2-line receipt comment to the     
 GitHub issue and/or prepends a tag to the issue title (`[QA: Codex Pass]`).    
 - **QW2 (One-Shot PR Scaffold `marathon-closeout.sh --auto-pr`):** A helper    
 script that validates the branch against pre-push, pushes to origin, and       
 executes `gh pr create --base development --head <branch>` with automated      
 summary markdown.                                                              
 - **QW3 (Workspace Garbage Collector `xyz workspace sweep`):** A script that   
 audits all linked worktrees and disposable clone folders, verifies `git log    
 origin/development..<branch>` is empty (all commits pushed), and removes clean 
 workspaces in one step.                                                        
 - **QW4 (Early Rebase Drift Alert):** A pre-turn hook in `relay-turn-lib.sh`   
 that fetches `origin/development` and alerts the builder if the trunk has      
 moved ahead by $>3$ commits before starting a long build turn.                 
                                                                                
 #### Category 2: Medium Complexity Solutions (Driver-Native & Tooling          
 Integrations)                                                                  
 - **M1 (Driver-Native PR Synthesis in `marathon_drive.py`):** When all phases  
 in a marathon wave reach terminal state `Approved`, the driver synthesizes     
 reviewer notes, test receipts, and telemetry into a standardized PR against    
 `development` with label `automated-lane / ready-for-review`.                  
 - **M2 (Ephemeral Workspace CLI `utils/py/workspace_manager.py`):** Formalize  
 disposable clone lifecycle under `xyz clone new|sync|pr-and-sweep`.            
 - **M3 (Live Standup Closeout Dashboard `/standup`):** Extend `/standup` to    
 aggregate all daily active worktrees, unpushed branches, open PRs, and QA      
 attestation into a single formatted Markdown/HTML view.                        
                                                                                
 ---                                                                            
                                                                                
 ### Objective for Reviewer (Aider -> OpenRouter -> stealth/ox-alpha)           
                                                                                
 1. **Safety & Invariant Analysis:** Identify potential regression risks,       
 dangerous edge cases, or false-assurance hazards in these proposals (e.g.,     
 risk of auto-PR opening incomplete/broken PRs, risk of workspace GC deleting   
 uncommitted/unpushed work, risk of git index corruption during background      
 rebase checks).                                                                
 2. **ROI & Priority Ranking:** Rank the proposed Quick Wins and Medium         
 solutions by implementation cost vs. daily operator friction reduced.          
 3. **Concrete Implementation Guidance:** Recommend specific safeguards (e.g.   
 verification predicates, CLI flags, `--dry-run` defaults, fail-closed guards)  
 that must be enforced before adopting these features in `marathon_drive.py`    
 and `relay_drive.py`.                                                          
                                                                                
 ---                                                                            
                                                                                
 ▶ TAKE YOUR TURN:                                                              
 Review the proposals and problem statement above. Append your structured       
 review block below, and update `STATUS:` and `NEXT:`.                          
                                                                                

I'll preserve all of that, change STATUS/NEXT lines, and append my review block 
after the TAKE YOUR TURN section.                                               

Note the math notation $>3$ in QW4 — preserve as-is.                            

Length: The review should be thorough but not bloated. This is fine.            

Let me finalize the file. Also, per the harness note, I shouldn't claim to run  
tick commands — I'll just present the edited file. I should briefly explain the 
changes first (per system prompt: explain needed changes, then file listing).   

One more thought on STATUS wording: maybe "STATUS: Approved" plus keep a note.  
The header format is simple key: value. I'll do:                                

STATUS: Approved NEXT: done                                                     

And within my block, clarify "conditional approval."                            

Write it out now.                                                               

--------------------------------------------------------------------------------

► ANSWER                                                                        

Understood — acting as aider, reviewer turn for RELAY-GH124-CLOSEOUT-REVIEW. Per
the harness note I will not run any tick/git/test commands; I'm spending the    
turn solely editing relay-system/2026-08-21/gh124-closeout-auto-pr-review.md.   

Changes made:                                                                   

 1 Appended a structured Round 1 reviewer block addressing all three objectives:
   per-proposal safety/invariant analysis (with the critical data-loss hazard in
   QW3 and broken-PR hazards in QW2/M1 called out), a cost-vs-friction ROI      
   ranking, and concrete fail-closed safeguards (predicate chains, --dry-run    
   defaults, idempotency keys, soft-delete quarantine, feature flags).          
 2 Updated header: STATUS: Approved (conditional on the enumerated guards       
   shipping before any destructive/publishing flag is enabled) and NEXT: done,  
   since the review deliverable is complete and requires no further producer    
   round.                                                                       

relay-system/2026-08-21/gh124-closeout-auto-pr-review.md                        

                                                                                
 @@ -1,8 +1,8 @@                                                                
  # Relay: Architectural Review of End-of-Day Closeout & Auto-PR Automation     
 (GH-124)                                                                       
 -STATUS: Active                                                                
 -NEXT: aider                                                                   
 +STATUS: Approved                                                              
 +NEXT: done                                                                    
                                                                                
  <!-- relay-drive: task=RELAY-GH124-CLOSEOUT-REVIEW producer=claude            
 reviewer=aider round-cap=4 -->                                                 
                                                                                
  ## Phase Brief                                                                
                                                                                
 @@ -43,5 +43,96 @@                                                             
                                                                                
  ---                                                                           
                                                                                
  ▶ TAKE YOUR TURN:                                                             
  Review the proposals and problem statement above. Append your structured      
 review block below, and update `STATUS:` and `NEXT:`.                          
 +                                                                              
 +---                                                                           
 +                                                                              
 +## Round 1 — Reviewer Block (aider)                                           
 +                                                                              
 +**Verdict: Conditionally Approved.** The proposal set is sound and            
 well-scoped, but two of the seven items (QW3, QW2/M1) are capable of           
 destroying or publishing work autonomously. Approval is contingent on the      
 fail-closed guards in §3 being implemented *before* any destructive/publishing 
 flag ships. Recommended sequence: **QW4 → QW3(+guards) → QW2(+guards) →        
 QW1(light) → M3**, with M2 evolving out of QW3 and M1 deferred.                
 +                                                                              
 +---                                                                           
 +                                                                              
 +### 1. Safety & Invariant Analysis                                            
 +                                                                              
 +#### QW1 — In-Flight Phase QA Attestation                                     
 +- **False-assurance hazard (HIGH):** An `Approved` verdict from a reviewer    
 turn is not evidence that tests ran. Auto-posting `[QA: Codex Pass]` without   
 artifact linkage trains operators to trust unverified tags — this *worsens*    
 the QA-ambiguity problem it targets.                                           
 +- **Required guard:** every attestation comment MUST embed machine-checkable  
 receipts: gate command, exit code, exact commit SHA, UTC timestamp (e.g.       
 `gate: validate.sh @ a1b2c3d → PASS`). No receipt ⇒ no tag, no comment.        
 +- **Idempotency:** driver retries/restarts must not double-post. Key on       
 `(issue, phase-id, reviewer-model)` and probe for an existing comment before   
 posting.                                                                       
 +- **Title mutation:** prepending tags mutates a shared identifier; anything   
 parsing issue titles breaks silently. Prefer GitHub labels over title edits;   
 if titles are used, enforce a strict grammar and a single-writer rule          
 (driver-only).                                                                 
 +                                                                              
 +#### QW2 — One-Shot PR Scaffold (`--auto-pr`)                                 
 +- **Broken-PR hazard (HIGH):** auto-PR is only safe if the tree is verifiably 
 clean and green at push time. A stale gate receipt from an earlier SHA is not  
 a receipt for HEAD.                                                            
 +- **Fail-closed predicate chain (all must pass; any failure aborts, no        
 partial push):**                                                               
 +  1. `git status --porcelain` empty — no uncommitted/untracked work;          
 +  2. HEAD is on the named branch (detached HEAD ⇒ abort);                     
 +  3. fresh gate pass for the exact HEAD SHA (re-run locally or validate       
 receipt SHA == HEAD);                                                          
 +  4. issue linkage resolvable (relay token / issue number present in relay    
 file or commit trailers);                                                      
 +  5. mergeability pre-check vs `origin/development` (synergy with QW4 — see   
 §3 snippet).                                                                   
 +- **Default `--dry-run`:** print the exact `gh pr create` invocation plus the 
 generated summary body; mutation requires `--execute`. Never fall back to      
 interactive prompting inside marathon turns (non-TTY hangs deadlock the lane). 
 +- **Trunk protection:** hard-fail if base ≠ `development` unless a            
 human-typed `--base` override is passed; the script must never be able to push 
 directly to `development`.                                                     
 +                                                                              
 +#### QW3 — Workspace Garbage Collector (`xyz workspace sweep`)                
 +- **Data-loss hazard (CRITICAL):** this is the only proposal that destroys    
 work. Every candidate deletion is guilty until proven innocent.                
 +- **The stated predicate is insufficient.** `git log                          
 origin/development..<branch>` empty does NOT prove safety: a lane whose branch 
 was never pushed but whose commits were cherry-picked/rebased into             
 `development` passes this check while its unique ref is still unpushed.        
 Likewise it says nothing about uncommitted files.                              
 +- **Required deletion predicate (ALL must hold):**                            
 +  1. path is present in the workspace registry — never sweep by glob or path  
 guessing;                                                                      
 +  2. `git status --porcelain` empty, AND no protected untracked artifacts     
 (denylist: `.relay-scratch/`, relay files, telemetry dirs);                    
 +  3. `git merge-base --is-ancestor HEAD origin/<branch>` — the branch tip is  
 actually pushed to its own remote ref;                                         
 +  4. no open PR references the branch (`gh pr list --head <branch>` empty);   
 +  5. lane lockfile absent or PID dead (workspace not actively in use).        
 +- **Soft-delete first:** move to quarantine (`.xyz/trash/<ts>-<name>/`) with  
 72h retention; hard purge only via explicit `--purge`. Use `git worktree       
 remove` for worktrees — never `rm -rf`; for full clones, assert the path is    
 under the registry root before any recursive delete.                           
 +- **Audit trail:** append every decision (kept/deleted + which predicates     
 ran) to a persistent JSONL log; `--dry-run` prints this table.                 
 +                                                                              
 +#### QW4 — Early Rebase Drift Alert                                           
 +- **Concurrency hazard (MEDIUM):** a `git fetch` in a pre-turn hook contends  
 on ref lockfiles with a live builder; and if anyone "improves" this hook into  
 an auto-rebase it will corrupt in-flight sessions. Codify the invariant:       
 **this hook is read-only and must NEVER mutate working state.**                
 +- **Robustness:** `git fetch --quiet origin development` with a short timeout 
 (≈10s) and `|| true` — offline/flaky network must degrade to "skip check",     
 never kill the turn. Compare via `git rev-list --count HEAD..FETCH_HEAD`;      
 alert at >3. Cache the result per turn to avoid repeat fetches.                
 +- **Noise risk:** an alert with no action path gets ignored within a week.    
 Pair it with a *suggested* (human-approved) rebase checkpoint between phases — 
 never mid-phase.                                                               
 +                                                                              
 +#### M1 — Driver-Native PR Synthesis                                          
 +- Inherits every QW2 hazard at automation scale, plus:                        
 +- **Duplicate-PR hazard:** driver crash/restart mid-closeout re-fires         
 synthesis. Idempotency key = `(issue, wave-id)`; search existing PRs before    
 creating.                                                                      
 +- **Terminal-state integrity:** synthesize only when the phase state machine  
 shows ALL phases `Approved` AND each carries a valid QW1-style receipt. One    
 missing receipt ⇒ no PR; surface the gap on `/standup` instead.                
 +- **Label semantics:** `automated-lane / ready-for-review` must map to a      
 *required human review* in branch protection. It must never be merge-eligible  
 by itself.                                                                     
 +- **Recommendation:** do not build M1 until QW2 has ≥2 weeks of zero-bad-PR   
 operation; when built, M1 should shell out to the hardened QW2 script rather   
 than reimplementing git logic in Python.                                       
 +                                                                              
 +#### M2 — Ephemeral Workspace CLI                                             
 +- Sound; it becomes the registry that makes QW3 safe. Requirements: single    
 JSON registry with `flock`-style locking and stale-lock TTL; `sync` is fetch + 
 ff-only (never rewrites lane branches); `pr-and-sweep` strictly composes the   
 QW2 → QW3 predicate chains, adding no logic of its own.                        
 +                                                                              
 +#### M3 — Standup Dashboard                                                   
 +- Low risk. Two cautions: redact credentials/tokens when aggregating remote   
 URLs into the view; bound scan cost (many worktrees × `git log` can stall the  
 dashboard — parallelize with timeouts and degrade gracefully).                 
 +                                                                              
 +---                                                                           
 +                                                                              
 +### 2. ROI & Priority Ranking                                                 
 +                                                                              
 +| Rank | Item | Impl. Cost | Daily Friction Removed | Unguarded Risk |        
 Verdict |                                                                      
 +|------|------|-----------|------------------------|----------------|-------- 
 -|                                                                             
 +| 1 | QW4 drift alert | XS (~50-line hook) | Prevents the costliest failure   
 mode (late merge conflicts) | Low (read-only) | Ship first |                   
 +| 2 | QW3 sweep | M | High (daily disk-audit pain across many lanes) |        
 CRITICAL (destroys work) | Ship second, guards mandatory |                     
 +| 3 | QW2 auto-pr | M | High (manual PR overhead × N lanes/day) | HIGH        
 (publishes broken code) | Ship third, guards mandatory |                       
 +| 4 | QW1 attestation | S | Medium (QA ambiguity) | Medium (false assurance)  
 | Lightweight version w/ receipts |                                            
 +| 5 | M3 standup | S–M | Medium (closeout visibility) | Low | Anytime |       
 +| 6 | M2 workspace CLI | M | Medium (formalizes QW3 lifecycle) | Low | Evolve 
 from QW3 |                                                                     
 +| 7 | M1 native PR synth | L | Marginal over hardened QW2 | Highest | Defer | 
 +                                                                              
 +Rationale: QW4 is nearly free and attacks the most expensive failure mode.    
 QW3/QW2 remove the most operator-minutes per day but are precisely the two     
 components that can destroy or publish work — hence the heavy predicate        
 emphasis. M1's incremental value over a battle-tested QW2 wrapper is small;    
 its blast radius is not.                                                       
 +                                                                              
 +---                                                                           
 +                                                                              
 +### 3. Concrete Implementation Guidance                                       
 +                                                                              
 +Global invariants for `marathon_drive.py` / `relay_drive.py` / helper         
 scripts:                                                                       
 +                                                                              
 +1. **Fail-closed everywhere.** Any predicate that cannot be evaluated         
 (network down, `gh` auth expired, registry missing) aborts the                 
 destructive/publishing action. Never skip-and-continue on unevaluable checks.  
 +2. **Feature-flag each behavior** (`XYZ_CLOSEOUT_AUTOPR`,                     
 `XYZ_SWEEP_ENABLED`, …), default OFF for one sprint; enable per-lane via       
 config.                                                                        
 +3. **Dry-run defaults.** `--auto-pr` and `sweep` print their plan; mutation   
 requires `--execute` (or `XYZ_EXECUTE=1` for non-interactive marathon use,     
 logged loudly).                                                                
 +4. **No interactive prompts in driver context.** Non-TTY ⇒ fail fast and      
 surface the pending decision on `/standup`; a blocked prompt deadlocks a lane. 
 +5. **Single-writer rule.** Only the driver mutates issue                      
 titles/labels/comments; manually invoked helpers get read-only views.          
 +6. **Append-only audit log** (JSONL: actor, action, predicate results,        
 outcome) per closeout event — this is your incident forensics.                 
 +7. **Trunk moves only via PRs,** automated or not. No code path pushes        
 directly to `development`.                                                     
 +8. **Timeouts on all network git ops** so a hung fetch can never deadlock a   
 relay turn (same discipline as the tick protocol).                             
 +                                                                              
 +Shared predicate sketch (e.g. `utils/sh/closeout_guards.sh`):                 
 +                                                                              
                                                                                

assert_clean_and_pushed() {                                                     

local wt="$1" branch="$2"                                                       

[ -z "$(git -C "$wt" status --porcelain)" ] || die "uncommitted changes"        

[ "$(git -C "$wt" rev-parse --abbrev-ref HEAD)" = "$branch" ] || die "not on    
$branch"                                                                        

git -C "$wt" fetch --quiet origin "$branch" || die "fetch failed"               

git -C "$wt" merge-base --is-ancestor HEAD "origin/$branch" \                   

                                                                                
 || die "unpushed commits on $branch"                                           
                                                                                

}                                                                               

                                                                                
                                                                                
                                                                                
 (`merge-base --is-ancestor HEAD origin/<branch>` proves the tip is pushed —    
 strictly stronger than counting `origin/development..HEAD`.)                   
                                                                                
                                                                                
                                                                                
 ---                                                                            
                                                                                
                                                                                
                                                                                
 ### Closing                                                                    
                                                                                
                                                                                
                                                                                
 Proposal set approved as scoped, conditional on the §3 guards landing before   
 any destructive/publishing flag is enabled. Build order: QW4 → QW3(+guards) →  
 QW2(+guards) → QW1(light) → M3; M2 grows out of QW3; M1 deferred pending a     
 clean QW2 track record. No further reviewer round required.                    
                                                                                

Tokens: 2.1k sent, 8.8k received.

githooks/pre-push

relay-automation/relay-turn-lib.sh

utils/py/marathon_drive.py
Warning: it's best to only add files that need changes to the chat.
https://aider.chat/docs/troubleshooting/edit-errors.html

utils/py/relay_drive.py

validate.sh
--------------------------------------------------------------------------------

► THINKING                                                                      

The user has added files to the chat: githooks/pre-push,                        
relay-automation/relay-turn-lib.sh, utils/py/marathon_drive.py,                 
utils/py/relay_drive.py, validate.sh. They're asking if there are others we     
should add.                                                                     

Context: I'm in a relay turn as aider, reviewing GH-124 (closeout & auto-pr     
automation). My previous turn appended a review block to the relay file. Now the
user is asking about which files should be added to the chat — presumably to    
implement the recommendations from my review.                                   

Wait, let me re-read. The user message says: "I added these files to the chat:  
githooks/pre-push, relay-automation/relay-turn-lib.sh,                          
utils/py/marathon_drive.py, utils/py/relay_drive.py, validate.sh. Let me know if
there are others we should add."                                                

This seems like a question about what other files would be relevant. Given my   
review recommendations touched on:                                              

 • QW4: pre-turn hook in relay-turn-lib.sh (already added)                      
 • QW2: marathon-closeout.sh --auto-pr (NOT yet in chat)                        
 • QW3: workspace sweep script (doesn't exist yet)                              
 • M1: marathon_drive.py PR synthesis (already added)                           
 • M2: workspace_manager.py (doesn't exist)                                     
 • M3: standup dashboard                                                        

So files that would be useful to add:                                           

  1 relay-automation/marathon-closeout.sh — referenced by open_lane_pr() in     
    marathon_drive.py; central to QW2/M1                                        
  2 relay-automation/relay-drive.sh and relay-automation/marathon-drive.sh — the
    Bash twins (frozen under GH-308), important for parity considerations       
  3 utils/ci-route.sh — referenced by pre-push hook for classification          
  4 utils/pdda/pdda.sh — docs gate used by pre-push                             
  5 githooks/install.sh — installs the hooks                                    
  6 AGENTS.md or similar docs                                                   
  7 bin/tick — the token system                                                 
  8 test/gh544-pre-push-gate.sh — existing tests for pre-push                   
  9 test/gh402-branch-enforcement.sh — branch guard tests                       
 10 utils/telemetry/append-xyz-completion.sh — telemetry                        
 11 relay-automation/gate-env.sh / utils/py/gate_env.py — gate env contract     
 12 relay-automation/target-checks.sh — cross-repo gates                        
 13 .gitignore — relevant for write-set trackability                            
 14 marathon-system/ phase dirs? No.                                            
 15 skills/standup/triage.py — for M3                                           

The question is ambiguous though: "Let me know if there are others we should    
add." This could mean: (a) Files needed to implement my review recommendations  
(b) Files generally useful for the ongoing work                                 

Given the context of the relay review turn, and that my review recommended      
specific implementation guidance, the user probably wants to start implementing 
some of the recommendations (maybe QW4 first, since it ranked #1).              

Actually wait — should I be careful here? The harness note said this is a       
reviewer turn where I edit ONLY the relay file. But now the user (operator) is  
asking a direct question about file management. This seems like an operator     
interaction outside the strict relay protocol. The instruction says "Let me know
if there are others we should add" — so they want a list of files.              

I should answer with a list of files that would be helpful, organized by        
purpose. No code changes are needed right now — it's just a question. Per my    
instructions: "If the request is ambiguous, ask questions" and "Determine if any
code changes are needed."                                                       

No code changes needed here — just answer the question.                         

Let me think about what's most relevant:                                        

For implementing the review recommendations:                                    

QW4 (drift alert) — highest priority:                                           

 • relay-automation/relay-turn-lib.sh ✓ (already added) — the pre-turn hook     
   location                                                                     
 • relay-automation/relay-drive.sh — exports RELAY_PEER etc., calls             
   rtl_turn_prompt; the hook needs wiring there too                             
 • relay-automation/marathon-agent.sh — agent dispatch wrapper                  
 • Tests: test/relay-turn-handoff.sh, test/gh268-relay-cue-and-target-checks.sh 
   — patterns for testing turn prompts                                          

QW2/QW3/M1/M2:                                                                  

 • relay-automation/marathon-closeout.sh — CRITICAL, already called by          
   marathon_drive.py's open_lane_pr(); the natural home for --auto-pr           
 • relay-automation/marathon-drive.sh — frozen Bash twin; parity constraints    
   (GH-308)                                                                     
 • relay-automation/relay-drive.sh — Bash twin of relay_drive.py                
 • utils/ci-route.sh — classifier used by pre-push; tier registry               
 • githooks/install.sh — hook installation                                      
 • test/gh544-pre-push-gate.sh — 78 assertions pinning pre-push behavior; any   
   change here must update it                                                   
 • test/gh35-test-tiers.sh — pins validate.sh behavior                          
 • test/gh402-branch-enforcement.sh — branch guard tests                        
 • test/baselines/GH-402-negative-control.md etc. — negative controls           
 • validate.sh ✓ already added                                                  
 • utils/py/gate_env.py + relay-automation/gate-env.sh — GH-441 contract; new   
   driver exports must be classified                                            
 • .gitignore — write-set trackability (GH-514), relay-system/logs/             
 • bin/tick — token ops for idempotency keys                                    
 • utils/telemetry/append-xyz-completion.sh — telemetry emission                
 • skills/standup/triage.py — M3 dashboard extension point                      
 • PROJECT/ capture docs — process requirements (GH-400 acceptance blocks)      

Also for the relay workflow itself:                                             

 • relay-automation/new-relay.sh — creates relay threads                        
 • relay-automation/rtl.py / utils/py/rtl.py — shared Python runtime lib        
   (driver_lock_path imported by both drivers)                                  

I should organize this into a concise answer. Also note which ones matter most  
depending on what we're implementing first (QW4 per my ranking).                

Also worth noting: if we're going to modify marathon_drive.py or relay_drive.py 
at all, the frozen-twin guard (GH-308) means the Bash twins need consideration, 
and test suites gh308-frozen-twin-guard.sh will fire.                           

And critically: any new env var exported by drivers must be added to            
GATE_SCRUBBED_ENV in marathon_drive.py AND gate_env.py AND gate-env.sh (the     
contract test gh441-gate-env-contract.sh enforces this). So those files matter. 

Let me also mention test/lib/clone-identity.sh and require_fixture helpers?     
Probably too deep. Keep it focused.                                             

Format: A clear structured list grouped by purpose, with brief reasons. Ask what
they plan to implement first so I can prioritize. Keep it reasonably concise but
complete.                                                                       

--------------------------------------------------------------------------------

► ANSWER                                                                        

No code changes needed for this — here's the map of what else is worth adding,  
grouped by why it matters. Priorities assume we follow the review's build order 
(QW4 → QW3 → QW2 → QW1 → M3).                                                   

Needed for QW4 (drift alert — first up)                                         

 • relay-automation/relay-drive.sh — the Bash twin that calls rtl_turn_prompt;  
   the drift hook has to be wired on both lanes or the alert silently exists    
   only on one (the exact GH-284/GH-322 failure class).                         
 • relay-automation/marathon-agent.sh — agent dispatch wrapper; confirms where a
   pre-turn hook can run without touching frozen code.                          
 • test/relay-turn-handoff.sh and test/gh268-relay-cue-and-target-checks.sh —   
   the established patterns for asserting on turn-prompt content; the           
   drift-alert suite will clone their shape.                                    

Needed for QW2 / M1 (closeout & auto-PR)                                        

 • relay-automation/marathon-closeout.sh — the single most important missing    
   file. open_lane_pr() in marathon_drive.py already shells out to it           
   (--open-only --no-commit), and it hardcodes BASE_BRANCH="development" — it's 
   the natural home for --auto-pr and the predicate chain.                      
 • relay-automation/marathon-drive.sh — frozen Bash twin (GH-308). Any          
   driver-side change needs its parity stance decided up front, or              
   test/gh308-frozen-twin-guard.sh goes red.                                    
 • utils/py/gate_env.py and relay-automation/gate-env.sh — the GH-441 contract. 
   Any new env var the drivers export (e.g. a closeout feature flag) must be    
   classified scrub-or-pass in all three places or                              
   test/gh441-gate-env-contract.sh fails.                                       
 • test/gh402-branch-enforcement.sh (+                                          
   test/baselines/GH-402-negative-control.md) — pins the branch-guard behavior  
   auto-PR must compose with, not bypass.                                       
 • test/gh561-* if it exists (the lane-branch cut/PR flow in                    
   refuse_trunk_commit()/open_lane_pr()) — same reason.                         

Needed for QW3 / M2 (workspace sweep)                                           

 • .gitignore — sweep safety depends on knowing what's ignored vs untracked;    
   also relay-system/logs/ exemptions live here.                                
 • bin/tick — token state is the authority for "is this lane still live"; the   
   sweep predicate reads it.                                                    
 • utils/telemetry/append-xyz-completion.sh — the audit-trail emission path for 
   keep/delete decisions.                                                       

Needed for anything touching pre-push / gates                                   

 • utils/ci-route.sh — the classifier pre-push and validate.sh share; a new     
   route (e.g. "harness-only") lands here.                                      
 • githooks/install.sh — hook installation/dispatch stub.                       
 • test/gh544-pre-push-gate.sh — 78 assertions pinning pre-push; any edit to    
   githooks/pre-push must update it in the same commit (the releases-skill      
   lesson: register gate + suite together).                                     
 • test/gh35-test-tiers.sh — pins validate.sh's tier/nice contracts.            

Lower priority / later phases                                                   

 • skills/standup/triage.py — M3's extension point.                             
 • utils/py/rtl.py — shared Python runtime (both drivers import driver_lock_path
   from it); only needed if sweep/PR logic grows shared Python helpers.         
 • relay-automation/new-relay.sh — only if we formalize relay-thread creation   
   for the new features.                                                        

One caution before we start: marathon_drive.py and relay_drive.py are loaded via
importlib from bare <stdin> in some tests, so utils/py/ isn't always on sys.path
— new imports there need the same local-insert pattern the existing code uses.  

Which item do you want to tackle first? If it's QW4, adding                     
relay-automation/relay-drive.sh plus the two turn-prompt test files is enough to
start.                                                                          

Tokens: 102k sent, 2.5k received.

.gitignore

bin/tick

githooks/install.sh

relay-automation/gate-env.sh

relay-automation/marathon-agent.sh

relay-automation/marathon-closeout.sh

relay-automation/marathon-drive.sh

relay-automation/new-relay.sh

relay-automation/relay-drive.sh

skills/standup/triage.py

test/gh268-relay-cue-and-target-checks.sh

test/gh308-frozen-twin-guard.sh

test/gh35-test-tiers.sh

test/gh402-branch-enforcement.sh

test/gh441-gate-env-contract.sh

test/gh544-pre-push-gate.sh

test/relay-turn-handoff.sh

utils/ci-route.sh

utils/py/gate_env.py

utils/py/rtl.py

utils/telemetry/append-xyz-completion.sh
--------------------------------------------------------------------------------

► THINKING                                                                      

The user has added a comprehensive set of files to the chat. They're asking if  
there are others we should add. Let me think about what's still missing based on
my earlier analysis and what's now present.                                     

Now in the chat:                                                                

 • .gitignore ✓                                                                 
 • bin/tick ✓                                                                   
 • githooks/install.sh ✓                                                        
 • relay-automation/gate-env.sh ✓                                               
 • relay-automation/marathon-agent.sh ✓                                         
 • relay-automation/marathon-closeout.sh ✓                                      
 • relay-automation/new-relay.sh ✓                                              
 • relay-automation/relay-drive.sh ✓ (Bash twin)                                
 • relay-automation/marathon-drive.sh ✓ (frozen Bash twin)                      
 • skills/standup/triage.py ✓                                                   
 • test/gh268-relay-cue-and-target-checks.sh ✓                                  
 • test/gh308-frozen-twin-guard.sh ✓                                            
 • test/gh35-test-tiers.sh ✓                                                    
 • test/gh402-branch-enforcement.sh ✓                                           
 • test/gh441-gate-env-contract.sh ✓                                            
 • test/gh544-pre-push-gate.sh ✓                                                
 • test/relay-turn-handoff.sh ✓                                                 
 • utils/ci-route.sh ✓                                                          
 • utils/py/gate_env.py ✓                                                       
 • utils/py/rtl.py ✓                                                            
 • utils/telemetry/append-xyz-completion.sh ✓                                   

Plus from the first batch:                                                      

 • validate.sh ✓                                                                
 • utils/py/marathon_drive.py ✓                                                 
 • utils/py/relay_drive.py ✓                                                    
 • githooks/pre-push ✓                                                          
 • relay-automation/relay-turn-lib.sh ✓                                         
 • test/gh308-frozen-twin-guard.sh ✓                                            
 • append-xyz-completion.sh ✓                                                   

What's still missing that would matter:                                         

  1 test/_setup.sh — referenced by many test files (source "$(dirname           
    "$0")/_setup.sh" gh441-gate-env-contract). It provides pass/fail helpers,   
    $WORK, $TICK, etc. If we write new tests following those patterns, we need  
    to see it.                                                                  
  2 test/lib/fixture-guard.sh — require_fixture, fixture_guard_init. Referenced 
    by gh308-frozen-twin-guard.sh, gh544-pre-push-gate.sh, gh35-test-tiers.sh.  
    Needed for any new fixture-based suite.                                     
  3 utils/py/swarm_preflight.py — referenced by marathon_drive.py (from         
    swarm_preflight import extract_contract, eval_probes) and listed as a frozen
    twin pair in gh308-frozen-twin-guard.sh                                     
    (utils/swarm-preflight.sh:utils/py/swarm_preflight.py). If we touch anything
    related to preflight packets (SP_SUGGESTED_BRANCH is read from env set by   
    preflight), we may need it.                                                 
  4 relay-automation/target-checks.sh — referenced heavily by marathon_drive.py 
    (the cross-repo gate fallback) and tested by gh268. If auto-PR composes with
    gates, this matters. Medium priority.                                       
  5 relay-automation/driver-lock-lib.sh — shared lock resolver Bash twin;       
    referenced by relay-drive.sh. Only needed if we touch locking.              
  6 relay-automation/harvest-findings.sh — called by marathon_drive.py for      
    Sentinel Tier 1. Low priority unless touching debug log paths.              
  7 utils/pdda/pdda.sh + utils/pdda-local-checks.sh — tier 1 docs gate; only    
    needed if docs change or we add routes.                                     
  8 test/ci-route.sh — classifier tests; needed if we extend ci-route.sh        
    registry.                                                                   
  9 src/events.js, src/project.js, src/scope.js, src/claim.js — tick internals; 
    bin/tick requires them. If sweep predicates read token state via tick info, 
    we don't need internals. But if we add new event types (e.g., closeout audit
    events), we'd need src/events.js. Medium-low priority.                      
 10 AGENTS.md — referenced repeatedly ("Re-anchor to the committed QUEUE lanes  
    (AGENTS.md)"). It defines conventions; useful context but not strictly      
    required for edits.                                                         
 11 test/baselines/GH-402-negative-control.md — referenced by gh402 suite       
    comments. Low priority.                                                     
 12 githooks/pre-push — already added in first batch? Let me check: yes,        
    "githooks/pre-push" was in the second message ("I added these files to the  
    chat: githooks/pre-push, relay-automation/relay-turn-lib.sh, ..."). Yes it's
    there.                                                                      
 13 marathon-closeout.sh — added now ✓.                                         
 14 utils/py/agy-turn.py / other turn shims — not needed for closeout work.     
 15 test/gh561-* — I mentioned earlier; does it exist? The TESTS array doesn't  
    show a gh561 file. The GH-561 behavior is pinned inside                     
    gh402-branch-enforcement.sh (cases reference GH-561). So no separate file   
    needed.                                                                     
 16 test/gh514-write-set-trackable.sh — pins write-set tracking; relevant if    
    closeout adds new write paths. Medium priority.                             
 17 test/gh388-run-log-durability.sh — durability contract; low priority.       
 18 relay-automation/non-durable-log-roots.conf — read by rtl.py                
    non_durable_conf_path(). Relevant if sweep touches logs. Low.               
 19 test/gh484-phase-dir-default.sh — pins phases dir defaults; low.            
 20 PROJECT/** capture docs — PDDA process requires capture docs for issues;    
    when we implement QW4 etc., we'd create PROJECT/1-INBOX/GH-124-*.md capture 
    doc. Not needed to add existing ones, but worth noting the PDDA workflow:   
    pdda-roadmap-coverage.sh checks coverage of ROADMAP vs ledger. Actually for 
    implementing features per repo convention, each issue needs a capture doc.  
    That's a new file we'd create, not add.                                     
 21 ROADMAP.md / RELEASES.md — releases ledger; if we register work in the      
    ledger. Probably out of scope for code changes but the repo convention      
    (gh69-roadmap-shadow) syncs ROADMAP.md into releases.db. Adding features    
    might require roadmap entries. Worth mentioning.                            
 22 test/test_python_layer.py — pytest layer run by validate.sh on every tier 3 
    run and pulled in on tier 2 when .py changes. If we edit utils/py/.py, this 
    suite runs. We should probably see it to know what it asserts. Medium-high  
    priority actually! Any change to utils/py/marathon_drive.py or              
    relay_drive.py will be exercised by test_python_layer.py. Let me include it.
 23 test/marathon-drive.sh — big driver suite (referenced in route_agent        
    comment: "test/marathon-drive.sh case (20b) asserts the Bash rejection"). If
    we modify marathon_drive.py behavior, this suite must stay green. High      
    priority for M1/QW2 driver-side work.                                       
 24 test/marathon.sh — orchestrator suite; mentioned as non-regression control. 
    Medium.                                                                     
 25 marathon.sh (root orchestrator) — drives phases; if M1 adds wave-level      
    synthesis, marathon.sh is where wave state lives. High priority for M1      
    specifically.                                                               
 26 utils/py/marathon_plan.py / _marathon_plan.py — plan generation; emits      
    MARATHON.yaml. If M1 needs wave metadata, maybe. Low-medium.                
 27 test/gh284-runlog-heartbeat.sh — run log idempotency; relevant to QW1       
    attestation posting (similar duplicate-comment hazard). Medium-high for QW1.
 28 test/xyz-harness-hooks.sh — reads XYZ_HARNESS_CONTEXT/XYZ_SESSION_ID;       
    relevant if we add new env vars. Medium.                                    
 29 test/debug-mantra.sh — reads MARATHON_LANE_NS; medium-low.                  
 30 test/gh322-runlog-python-lane.sh — loads marathon_drive.py via importlib    
    from stdin; important constraint documentation but we know it already.      

So the most valuable additions, ranked:                                         

High value (needed before editing):                                             

 1 test/_setup.sh — shared test harness helpers (pass/fail, WORK, TICK). Nearly 
   every new suite will source it.                                              
 2 test/lib/fixture-guard.sh — require_fixture/fixture_guard_init for           
   containment.                                                                 
 3 test/test_python_layer.py — runs on every gate; will exercise our Python     
   edits.                                                                       
 4 test/marathon-drive.sh — the main driver behavioral suite.                   
 5 marathon.sh — wave-level orchestrator (M1 target).                           

Medium value: 6. utils/py/swarm_preflight.py — frozen twin; SP_SUGGESTED_BRANCH 
origin; extract_contract/eval_probes imported by marathon_drive. 7.             
relay-automation/target-checks.sh — cross-repo gate helper. 8.                  
test/gh284-runlog-heartbeat.sh — pattern for idempotent GitHub comment updates  
(QW1). 9. test/gh514-write-set-trackable.sh — write-set preflight; closeout     
writes new files. 10. test/xyz-harness-hooks.sh — env var assertions. 11.       
test/ci-route.sh — if extending the subsystem registry. 12. src/events.js (+    
maybe src/project.js) — if adding audit event types to tick.                    

Context/convention files: 13. AGENTS.md — queue/lane conventions referenced     
everywhere. 14. ROADMAP.md — if ledger entries are needed. 15.                  
relay-automation/driver-lock-lib.sh — only if touching locks. 16.               
relay-automation/non-durable-log-roots.conf — small config read by rtl.py.      

I should keep the response focused and prioritized, explaining why each matters 
and what breaks without it. Also note which are NOT needed (turn shims, pdda    
internals) to bound scope.                                                      

Also worth noting: the user asked "Let me know if there are others we should    
add." So primarily an advisory answer, no code changes yet. Keep it reasonably  
concise but complete. Use headers/groups like last time since that format worked
well.                                                                           

One more consideration: test/baselines/GH-402-negative-control.md — the gh402   
suite references it in comments but the suite itself doesn't read it at runtime 
(it's evidence documentation). Skip or mention as optional.                     

Also test/gh35-test-tiers.sh references ci-local.sh (copies it into fixture R7).
If we ever touch ci-local.sh... it's referenced in validate.sh comments too. But
we're not planning to touch it. Mention as optional.                            

Also utils/releases_app.py — no, out of scope.                                  

Also bin/validate-relay-block — used by tick release/done with --relay-file. Our
relay file edits get validated by it during release. Hmm — actually that's      
interesting: when the harness releases RELAY-GH124-CLOSEOUT-REVIEW with         
--relay-file, bin/validate-relay-block validates the block structure. If our    
appended block lacks proper VERDICT/Basis structure it could fail. But that's   
runtime, not something we need to read to answer this question. Could mention   
briefly? It might matter for relay turns but not for the feature work. Skip to  
avoid noise. Actually wait — it could matter: if we later drive relays through  
these features. Not needed now.                                                 

Format: grouped list with brief justifications, then a suggested minimal "start 
here" set. No file listings needed since no code changes requested.             

--------------------------------------------------------------------------------

► ANSWER                                                                        

Good coverage — the core loop (drivers, twins, gates, hooks, key suites) is all 
here. What's left falls into three tiers:                                       

Add before writing any code (shared infrastructure everything else depends on)  

 • test/_setup.sh — nearly every suite sources it (pass/fail, $WORK, $TICK,     
   TEST_NAME). Any new suite we write for QW2–QW4 will follow its patterns;     
   without it we'd be guessing at the helper contracts.                         
 • test/lib/fixture-guard.sh — require_fixture / fixture_guard_init; mandatory  
   adoption for any fixture-creating suite (GH-1/GH-10 guard enforces this), so 
   new tests can't be written correctly without seeing it.                      
 • test/test_python_layer.py — pytest runs unconditionally on tier 3 and gets   
   pulled in whenever a *.py path changes. Editing                              
   marathon_drive.py/relay_drive.py without knowing what it asserts is how you  
   find out at push time.                                                       
 • test/marathon-drive.sh — the main behavioral suite for the Python driver     
   (e.g. case 20b pins agent routing). Driver-side changes for QW2/M1 must keep 
   it green; it also documents the exit-code contract end-to-end.               

Add for specific proposals                                                      

 • marathon.sh — the wave-level orchestrator. M1 ("when all phases reach        
   Approved…") lives here more than in marathon_drive.py: wave state, phase     
   sequencing, and the whole-run telemetry record are its job. Required before  
   designing M1.                                                                
 • utils/py/swarm_preflight.py — frozen twin (utils/swarm-preflight.sh); it's   
   where SP_SUGGESTED_BRANCH originates (the branch-guard reads it), and        
   marathon_drive.acceptance_probes_unmet() imports extract_contract/eval_probes
   from it. Touching preflight or packet fields means touching this.            
 • relay-automation/target-checks.sh — the cross-repo default gate; auto-PR's   
   predicate chain should compose with it rather than grow a parallel detection 
   mechanism.                                                                   
 • test/gh284-runlog-heartbeat.sh — QW1 attestation posting has exactly the     
   duplicate-GitHub-comment hazard this suite pins (marker-based                
   update-in-place). Copy its idempotency pattern, don't invent one.            
 • test/gh514-write-set-trackable.sh — closeout/sweep introduce new write paths 
   (quarantine dirs, audit JSONL); this preflight refuses runs whose write-set  
   isn't trackable, so new paths need to be declared or gitignored deliberately.
 • test/xyz-harness-hooks.sh — asserts on XYZ_HARNESS_CONTEXT/XYZ_SESSION_ID;   
   any new driver-exported env var (feature flags like XYZ_CLOSEOUT_AUTOPR) must
   clear the GH-441 registry and not collide with what this suite reads.        
 • test/ci-route.sh — only if we extend the subsystem registry (e.g. a closeout 
   subsystem mapping marathon-closeout.sh → focused suites).                    
 • src/events.js (+ optionally src/project.js) — only if the sweep/closeout     
   audit trail becomes a native tick event type instead of a standalone JSONL.  
   Defer until that design decision is made.                                    

Context / conventions (cheap to add, prevents rework)                           

 • AGENTS.md — referenced by every park message ("re-anchor to the committed    
   QUEUE lanes"); it defines lane/branch conventions the review's               
   recommendations assume.                                                      
 • ROADMAP.md — GH-69 shadows it into the releases ledger; landing these        
   features likely means roadmap entries, and the sync refuses duplicates.      
 • relay-automation/driver-lock-lib.sh — only if sweep/PR work touches locking  
   (probably not).                                                              
 • relay-automation/non-durable-log-roots.conf — tiny config both lanes read;   
   relevant only if audit logs could land somewhere volatile.                   

Explicitly not needed                                                           

Turn shims (codex/agy/claude/aider/pi-turn.*), PDDA internals (utils/pdda/*),   
releases_app.py, consult/deep-research — none intersect the closeout/sweep/alert
surface.                                                                        

Minimal start set: test/_setup.sh, test/lib/fixture-guard.sh,                   
test/test_python_layer.py, test/marathon-drive.sh. With those four plus what's  
already here, we can begin QW4 (the drift-alert hook) immediately — it touches  
relay-turn-lib.sh + both relay_drive twins, all of which are in the chat.       

Tokens: 211k sent, 3.5k received.

AGENTS.md

ROADMAP.md

relay-automation/driver-lock-lib.sh

relay-automation/non-durable-log-roots.conf

relay-automation/target-checks.sh

src/events.js

test/_setup.sh

test/ci-route.sh

test/gh284-runlog-heartbeat.sh

test/gh514-write-set-trackable.sh

test/lib/fixture-guard.sh

test/marathon-drive.sh

test/test_python_layer.py

test/xyz-harness-hooks.sh

utils/py/releases_app.py

utils/py/swarm_preflight.py
--------------------------------------------------------------------------------

► THINKING                                                                      

The user has added all the files I requested. Now they're asking if there are   
others we should add. Let me think about what's still missing.                  

Looking at what's in the chat now:                                              

 • .gitignore                                                                   
 • AGENTS.md                                                                    
 • ROADMAP.md                                                                   
 • bin/tick                                                                     
 • githooks/install.sh                                                          
 • githooks/pre-push                                                            
 • relay-automation/driver-lock-lib.sh                                          
 • relay-automation/gate-env.sh                                                 
 • relay-automation/marathon-agent.sh                                           
 • relay-automation/marathon-closeout.sh                                        
 • relay-automation/marathon-drive.sh (frozen Bash twin)                        
 • relay-automation/new-relay.sh                                                
 • relay-automation/non-durable-log-roots.conf                                  
 • relay-automation/relay-drive.sh (frozen Bash twin)                           
 • relay-automation/relay-turn-lib.sh                                           
 • relay-automation/target-checks.sh                                            
 • skills/standup/triage.py                                                     
 • src/events.js                                                                
 • test/_setup.sh                                                               
 • test/ci-route.sh                                                             
 • test/gh268-relay-cue-and-target-checks.sh                                    
 • test/gh284-runlog-heartbeat.sh                                               
 • test/gh308-frozen-twin-guard.sh                                              
 • test/gh35-test-tiers.sh                                                      
 • test/gh402-branch-enforcement.sh                                             
 • test/gh441-gate-env-contract.sh                                              
 • test/gh514-write-set-trackable.sh                                            
 • test/gh544-pre-push-gate.sh                                                  
 • test/lib/fixture-guard.sh                                                    
 • test/marathon-drive.sh                                                       
 • test/relay-turn-handoff.sh                                                   
 • test/test_python_layer.py                                                    
 • test/xyz-harness-hooks.sh                                                    
 • utils/ci-route.sh                                                            
 • utils/py/gate_env.py                                                         
 • utils/py/marathon_drive.py                                                   
 • utils/py/releases_app.py                                                     
 • utils/py/relay_drive.py                                                      
 • utils/py/rtl.py                                                              
 • utils/py/swarm_preflight.py                                                  
 • utils/telemetry/append-xyz-completion.sh                                     
 • validate.sh                                                                  

What's still missing that we'd need?                                            

  1 marathon.sh — I mentioned this earlier as needed for M1. It's the wave-level
    orchestrator. Still not in chat. This is important for M1 design but not for
    QW4 start.                                                                  
  2 utils/swarm-preflight.sh — the frozen Bash twin of swarm_preflight.py. If we
    touch preflight, the guard requires knowing both. But swarm_preflight.py is 
    already here; the Bash twin is frozen so we wouldn't edit it. Maybe not     
    critical.                                                                   
  3 test/baselines/GH-402-negative-control.md — mentioned earlier; nice-to-have 
    context but not essential.                                                  
  4 test/gh561-* — I mentioned "if it exists". Looking at validate.sh's TESTS   
    array... I don't see a gh561 suite registered. The GH-561 behavior is tested
    within test/gh402-branch-enforcement.sh itself (cases reference GH-561). So 
    no separate file exists — good, nothing to add.                             
  5 src/project.js — mentioned as optional with events.js. Only if audit trail  
    becomes tick events. Defer.                                                 
  6 test/gh91-relay-scratch.sh — if QW3 sweep interacts with .relay-scratch/,   
    this pins its contract. Worth mentioning for QW3 specifically.              
  7 relay-automation/harvest-findings.sh — referenced by marathon_drive.py      
    (xyz_harvest_findings). Only relevant if debug-log capture changes. Probably
    not needed.                                                                 
  8 relay-automation/DEBUG-MANTRA.md — referenced by drivers. Not relevant to   
    our work.                                                                   
  9 utils/pdda/pdda.sh — doc gates. We'll need to update docs (ROADMAP entries  
    etc.) and the PDDA gate checks them. But we don't need to edit pdda.sh      
    itself. Not needed in chat.                                                 
 10 CHANGELOG.md — per AGENTS.md rule 7, consequential bets get recorded in     
    CHANGELOG.md. When we land features, we'll edit it. Worth adding when we're 
    ready to land.                                                              
 11 PROJECT/** capture docs — the PDDA lifecycle wants a capture doc per issue. 
    These are created fresh, not existing files to add.                         
 12 test/gh484-phase-dir-default.sh — pins phases-dir defaults; only if we      
    change phase dir handling. Not needed.                                      
 13 test/gh388-runlog-durability.sh — durability of run logs; relevant if       
    closeout writes logs. Marginal.                                             
 14 utils/hq/* — HQ registry; workspace_manager (M2) might read it ("the UI     
    resolves local checkout paths from the utils/hq/ registry"). For M2 later.  
    Mention as deferred.                                                        
 15 bin/marathon-yaml — marathon plan emission; not needed unless MARATHON.yaml 
    fields change (e.g., turn_timeout_s). Not needed for our scope.             
 16 test/gh391-emit-marathon-yaml.sh — same, defer.                             
 17 githooks/pre-push — already in chat. Good.                                  
 18 .github/workflows/ci.yml — referenced by tests (gh544 asserts on it). If we 
    add new CI steps or change triggers we'd need it. For our scope probably not
    editing CI. Could mention as optional.                                      
 19 ci-local.sh — the qualifying gate runner; parses TESTS array from           
    validate.sh. If we register new suites in validate.sh's TESTS array,        
    ci-local.sh picks them up automatically by parsing. We don't strictly need  
    the file unless we modify it. Actually wait — do we need to register new    
    suites? Yes! New test suites must be registered in validate.sh's TESTS array
    (per the releases-skill lesson: "Register the two together or neither").    
    validate.sh is already in chat. ci-local.sh parses TESTS automatically so no
    edit needed there. OK.                                                      
 20 test/gh1-adoption-guard.sh — enforces require_fixture adoption for          
    fixture-creating suites. Our new suites will create fixtures, so they must  
    adopt require_fixture. The guard derives offenders from source. We don't    
    need the file itself since we know the pattern from _setup.sh +             
    fixture-guard.sh + existing suites. Fine.                                   
 21 utils/py/agy-turn.py / other turn shims — explicitly not needed (I said     
    before).                                                                    
 22 relay-automation/consult.sh / utils/py/consult.py — not needed.             
 23 test/oracle-guard.sh — ALLOW_PATHS sensitivity; not directly needed.        
 24 README.md — documents install steps, HQ section links. If we add user-facing
    commands (xyz workspace sweep), README updates might be expected. Optional, 
    defer.                                                                      
 25 HARNESS-MODELS-REGISTRY.md, ROUTER.md, GUIDING-PRINCIPLES.md,               
    WORKTREE-SAFETY.md — canonical docs referenced by AGENTS.md.                
    WORKTREE-SAFETY.md is actually quite relevant! relay-turn-lib.sh says       
    "Before touching anything below: read WORKTREE-SAFETY.md (repo root) — it   
    documents the git-worktree footguns and the safe recovery path for a        
    corrupted RTL_ROOT/.git (GH-177)." Since QW4 touches relay-turn-lib.sh and  
    QW3 deals with worktrees, having WORKTREE-SAFETY.md would be valuable       
    context. Worth mentioning.                                                  
 26 decisions/*.md — decision records like                                      
    decisions/2026-06-15-unattended-agent-containment.md are referenced in      
    relay-turn-lib.sh. If we make consequential design decisions, we may write  
    new ones. Existing ones optional.                                           

So my answer: the set is essentially complete for starting QW4. Remaining useful
additions:                                                                      

Priority:                                                                       

 1 marathon.sh — needed before designing M1 (wave orchestration, whole-run      
   telemetry).                                                                  
 2 WORKTREE-SAFETY.md — required reading per relay-turn-lib.sh header before    
   touching worktree code; QW3/QW4 both intersect.                              
 3 test/gh91-relay-scratch.sh — pins .relay-scratch/ contract which QW3's       
   protected-artifact denylist must respect.                                    

When landing: 4. CHANGELOG.md — AGENTS.md rule 7 requires recording             
consequential bets. 5. .github/workflows/ci.yml — only if CI steps change; gh544
asserts on its content so edits must be coordinated.                            

Deferred (M2): 6. utils/hq/hq.sh (+ registry) — workspace_manager resolves paths
through it.                                                                     

Not needed:                                                                     

 • frozen Bash twins of things whose Python side we edit (we never edit them)   
 • turn shims, consult, releases internals, PDDA internals                      
 • ci-local.sh (parses TESTS automatically)                                     

Also worth noting: no separate gh561 suite exists — GH-561 assertions live      
inside test/gh402-branch-enforcement.sh, which is already here.                 

Should I suggest any code changes now? The user asked "Let me know if there are 
others we should add." So this is another file-request turn, not an edit turn.  
No code changes needed yet. Keep it concise.                                    

Actually, let me double-check one thing: the review said build order QW4 first. 
QW4 = drift alert hook in relay-turn-lib.sh. Files needed: relay-turn-lib.sh ✓, 
relay-drive.sh (Bash) ✓, utils/py/relay_drive.py ✓, marathon-agent.sh ✓, test   
patterns ✓. All present. So we can genuinely start once they confirm.           

One more consideration: test/gh358-lock-instrumentation.sh? No, telemetry lock  
stuff, irrelevant.                                                              

test/watchdog-*? Not relevant.                                                  

test/gh492-idle-kill.sh? Covers agy-turn.py and consult.py idle thresholds. Not 
relevant.                                                                       

OK. Also should I flag that PROJECT/PDDA-ACTIVITY.jsonl is gitignored (in       
.gitignore) — not relevant.                                                     

Format: concise answer, grouped lists, end with readiness statement. No file    
listings needed since no code changes.                                          

--------------------------------------------------------------------------------

► ANSWER                                                                        

That completes the working set — everything needed to start QW4 is now in the   
chat. A few more worth adding at specific points, then we're done:              

Add before designing M1 (not needed for QW4)                                    

 • marathon.sh — still the one significant gap. Wave-level orchestration, phase 
   sequencing, and the whole-run telemetry record live there; M1's "all phases  
   Approved → synthesize PR" trigger is a wave-state question, not a driver     
   question.                                                                    
 • WORKTREE-SAFETY.md — relay-turn-lib.sh's own header makes it required reading
   before touching anything below the worktree-isolation section ("documents the
   git-worktree footguns and the safe recovery path for a corrupted             
   RTL_ROOT/.git"). QW4 edits that file and QW3 deletes worktrees, so we want   
   the footgun list in front of us, not reconstructed from memory.              

Add when we reach QW3                                                           

 • test/gh91-relay-scratch.sh — pins the .relay-scratch/ contract (pre-created, 
   exempt, discarded). The sweep's protected-artifact denylist must treat it    
   exactly as this suite does, or a sweep deletes sanctioned scratch output     
   mid-lane.                                                                    

Add when landing (not before)                                                   

 • CHANGELOG.md — AGENTS.md rule 7: consequential bets get recorded there. We'll
   need it in the same commit as the first feature.                             
 • .github/workflows/ci.yml — only if CI steps change. Note                     
   test/gh544-pre-push-gate.sh greps this file's content, so any edit has to    
   move both together.                                                          

Deferred to M2                                                                  

 • utils/hq/hq.sh (+ whatever registry file it reads) — workspace_manager.py    
   resolves local checkout paths through the HQ registry per the releases_app   
   comment; irrelevant until M2 starts.                                         

Clarifications on earlier suggestions                                           

 • No test/gh561-* exists — I flagged it conditionally earlier; the GH-561      
   assertions live inside test/gh402-branch-enforcement.sh (cases 1, 2, 6),     
   which is already here. Nothing to add.                                       
 • ci-local.sh doesn't need adding — it parses validate.sh's TESTS array at     
   runtime, so registering our new suites in validate.sh (already in chat) is   
   sufficient.                                                                  
 • Frozen Bash twins stay out — utils/swarm-preflight.sh etc. are never edited  
   (GH-308); their Python sides are here.                                       

One standing caution now that the full picture is visible: validate.sh's TESTS  
registration and the suite file must land in the same commit (the releases-skill
lesson recorded in the TESTS comments), and every new fixture-creating suite    
must adopt require_fixture or test/gh1-adoption-guard.sh fails the gate.        

Ready to start on QW4 whenever you give the word — the drift-alert hook touches 
relay-turn-lib.sh plus both relay_drive twins, all present.                     

Tokens: 345k sent, 2.8k received.

.github/workflows/ci.yml

CHANGELOG.md

WORKTREE-SAFETY.md

ci-local.sh

test/gh1-adoption-guard.sh

test/gh91-relay-scratch.sh

utils/hq/hq.sh

utils/swarm-preflight.sh
Only 3 reflections allowed, stopping.

```
