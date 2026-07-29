#!/usr/bin/env python3
import os
import re
import sys
import tempfile
import subprocess
import shlex
import time
from rtl import RelayTurnLib, claim_paths_for_turn, claim_task_or_exit, rtl_default_log, resolve_turn_root

def die(msg):
    print(f"aider-turn: {msg}", file=sys.stderr)
    sys.exit(2)

def aider_supports_add_gitignore_files(aider_bin):
    # GH-186: probe the installed binary's actual CLI surface — old aider builds still advertise
    # --add-gitignore-files (needed for gitignored relay files), current releases removed it.
    try:
        r = subprocess.run([aider_bin, "--help"], capture_output=True, text=True)
    except Exception:
        return False
    if r.returncode != 0:
        return False
    return "--add-gitignore-files" in r.stdout

def relay_sig(root, path):
    # GH-251: content signature of the relay file (git hash-object at ROOT, cksum fallback).
    try:
        r = subprocess.run(["git", "-C", root, "hash-object", "--", path], capture_output=True, text=True)
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    except Exception:
        pass
    try:
        with open(path, "rb") as fh:
            r = subprocess.run(["cksum"], stdin=fh, capture_output=True, text=True)
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    except Exception:
        pass
    return "none"

def main():
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    # GH-308 port (GH-296): fall back to the CWD's git toplevel (not xyz_root) when AIDER_TURN_ROOT is
    # unset, matching aider-turn.sh and agy-turn.py's resolve_turn_root. Rooting worktree isolation and
    # artifact copy-back at xyz_root (the shim's own checkout) instead of the operator's target repo was
    # a silent divergence on the default lane for a non-vendored run.
    root = resolve_turn_root(os.environ.get("AIDER_TURN_ROOT"), xyz_root)
    aider_bin = os.environ.get("AIDER_BIN", "aider")
    # GH-147 Phase 2 (LM_STUDIO lane): mirrors relay-automation/aider-turn.sh — AIDER_OPENAI_API_BASE
    # set selects the LM Studio / OpenAI-compatible seam (default model openai/agents-a1); unset keeps
    # the OpenRouter default, byte-identical to the pre-GH-147 behavior. Same env-var contract Phase 1
    # proved in utils/py/consult.py — reused verbatim, not redefined.
    aider_openai_api_base = os.environ.get("AIDER_OPENAI_API_BASE", "")
    if aider_openai_api_base:
        aider_model = os.environ.get("AIDER_MODEL", "openai/agents-a1")
    else:
        aider_model = os.environ.get("AIDER_MODEL", "openrouter/anthropic/claude-sonnet-5")

    me = os.environ.get("RELAY_AGENT", "")
    f = os.environ.get("RELAY_FILE", "")
    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    aider_agent = os.environ.get("AIDER_AGENT", "")

    if not me: die("RELAY_AGENT required")
    if not f: die("RELAY_FILE required")
    if not aider_agent: die("AIDER_AGENT required")

    if me != aider_agent:
        print(f"aider-turn: actor {me} is not the aider agent ({aider_agent}) — deferring (window-driven)", file=sys.stderr)
        sys.exit(0)

    # Auth pre-flight. Two seams share this shim (GH-147 Phase 2): OpenRouter is pure API-key (a missing
    # key would make aider prompt interactively and deadlock the headless turn, so fail fast with the
    # remedy); the LM Studio / OpenAI-compatible seam authenticates via AIDER_OPENAI_API_BASE +
    # AIDER_OPENAI_API_KEY (dummy default) instead and needs no OPENROUTER_API_KEY at all.
    aider_auth_args = []
    aider_env = os.environ.copy()
    if aider_openai_api_base:
        # Keep the key out of ps-visible argv. Aider/LiteLLM reads OPENAI_API_KEY from its child env.
        aider_env["OPENAI_API_KEY"] = os.environ.get("AIDER_OPENAI_API_KEY", "dummy")
        aider_auth_args = ["--openai-api-base", aider_openai_api_base]
    elif not os.environ.get("OPENROUTER_API_KEY"):
        print("aider-turn: OPENROUTER_API_KEY is not set — Aider cannot reach OpenRouter (or set AIDER_OPENAI_API_BASE for an OpenAI-compatible/LM Studio endpoint). Export it, then retry.", file=sys.stderr)
        sys.exit(5)

    allow_paths = os.environ.get("ALLOW_PATHS", "")
    peer = os.environ.get("RELAY_PEER", "")
    
    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)
    
    prompt = rtl.turn_prompt(me, t, peer)
    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    drift_brief = rtl.drift_brief(me, tick_repo_root)
    
    if drift_brief:
        prompt = drift_brief + "\n" + prompt
        
    prompt += "\n\nNOTE (Aider harness): do NOT run any tick commands — the harness has already claimed the token and will release/close it for you after your edit. Spend this turn ONLY editing the file(s) added to the chat: append your block to the relay file and set its STATUS, and edit the artifact(s) if this is a build turn."

    claim_paths = claim_paths_for_turn(root, f, allow_paths)
    rel_relay = claim_paths[0]
    file_args = ["--file", rel_relay]
    for path in claim_paths[1:]:
        file_args.extend(["--file", path])
    
    read_args = []
    if not allow_paths:
        rtl_artifact = rtl.get_artifact()
        if rtl_artifact and os.path.isfile(rtl_artifact):
            read_args.extend(["--read", rtl_artifact])
            try:
                # get changed files from diff
                diff_cmd = ["sed", "-nE", "s#^diff --git a/(.+) b/.+$#\\1#p; s#^\\+\\+\\+ b/(.+)$#\\1#p", rtl_artifact]
                diff_res = subprocess.run(diff_cmd, capture_output=True, text=True)
                changed_files = set(diff_res.stdout.splitlines())
                for cp in changed_files:
                    if cp and os.path.isfile(os.path.join(root, cp)) and cp != rel_relay:
                        read_args.extend(["--read", cp])
            except Exception:
                pass

    tick_repo_root, _tick_bin = claim_task_or_exit(root, xyz_root, f, allow_paths, t, me, "aider-turn")

    # GH-161/GH-280 parity fix: codex-turn.py already uses rtl_default_log (persistent, gitignored
    # relay-system/logs/<day>/... — survives past the turn); this port was missed, matching the same
    # gap that existed in the Bash aider-turn.sh (fixed separately). agy-turn.py has the identical gap.
    aider_log = os.environ.get("AIDER_LOG") or rtl_default_log(root, "aider-turn", t)
    aider_aux_dir = os.environ.get("AIDER_AUX_DIR", os.path.join(tempfile.gettempdir(), f"aider-aux-{os.getpid()}"))
    os.makedirs(aider_aux_dir, exist_ok=True)
    
    # GH-278: keep the default aligned with the Bash compatibility shim and relay-xyz docs.
    # 900s gives thinking-heavy builders enough headroom while preserving the bounded exit-7 kill.
    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))
    
    gitignore_args = ["--no-gitignore"]
    if aider_supports_add_gitignore_files(aider_bin):
        gitignore_args.append("--add-gitignore-files")

    aider_args = [
        "--model", aider_model, "--yes-always", "--no-auto-commits"
    ] + aider_auth_args + gitignore_args + [
        "--no-check-update", "--no-analytics", "--no-show-model-warnings", "--no-stream", "--map-tokens", "0",
        "--chat-history-file", os.path.join(aider_aux_dir, "chat.history.md"),
        "--input-history-file", os.path.join(aider_aux_dir, "input.history"),
        "--llm-history-file", os.path.join(aider_aux_dir, "llm.history")
    ] + file_args + read_args
    
    xflags = os.environ.get("AIDER_FLAGS", "")
    if xflags:
        aider_args.extend(shlex.split(xflags))
        
    # GH-251: signature the relay file BEFORE the turn so a review-only turn that produced a graded
    # review in the transcript but landed NO relay-file append can be detected and salvaged after.
    relay_presig = relay_sig(root, f)

    rtl.before()

    wt = ""
    run_cwd = root
    
    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
        wt = rtl.worktree_begin()
        if wt:
            run_cwd = wt
            print(f"aider-turn: worktree isolation ON ({wt})", file=sys.stderr)
            os.environ["TICK_REPO_ROOT"] = tick_repo_root
        else:
            print("aider-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
            sys.exit(5)

    cmd = [aider_bin] + aider_args + ["--message", prompt]
    
    bounded_rc = 0
    try:
        with open(aider_log, "w") as log_f:
            subprocess.run(cmd, cwd=run_cwd, env=aider_env, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, check=True)
    except subprocess.TimeoutExpired:
        bounded_rc = 7
    except subprocess.CalledProcessError as e:
        bounded_rc = e.returncode
    except Exception as e:
        bounded_rc = 5

    if wt:
        off_lane = rtl.worktree_end(wt)
        if off_lane:
            print("aider-turn: aider made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
            sys.exit(6)

    if bounded_rc == 7:
        print(f"aider-turn: aider exceeded {turn_timeout}s wall-clock cap — killed", file=sys.stderr)
    elif bounded_rc != 0:
        print(f"aider-turn: aider failed (exit {bounded_rc}) — see {aider_log}", file=sys.stderr)
        sys.exit(5)
        
    if bounded_rc == 0 and os.path.getsize(aider_log) == 0:
        print("aider-turn: aider exited 0 but produced NO output — likely a blocked/misconfigured backend. Failing the turn.", file=sys.stderr)
        sys.exit(5)
        
    # GH-251 transcript-salvage backstop. On a REVIEW-ONLY turn (ALLOW_PATHS empty), if the relay file
    # is byte-unchanged after the turn but the transcript carries a graded review (a `Verdict:` anchor),
    # recover it: append the turn transcript to the relay file (attributed) so the review LANDS instead
    # of being discarded as a stall. Runs BEFORE rtl.enforce so the append is the file-scoped commit.
    if not allow_paths and bounded_rc == 0 and os.path.getsize(aider_log) > 0:
        relay_postsig = relay_sig(root, f)
        has_verdict = False
        try:
            with open(aider_log, "r", errors="replace") as lf:
                log_text = lf.read()
            has_verdict = bool(re.search(r"verdict[ \t]*:", log_text, re.IGNORECASE))
        except Exception:
            log_text = ""
        if relay_postsig == relay_presig and has_verdict:
            with open(f, "a") as rf:
                rf.write(f"\n\n---\n\n### Review salvaged from {aider_model} transcript (aider-turn.sh · GH-251)\n\n")
                rf.write("_Aider completed a review turn but did not land it as a relay-file append; the harness\n")
                rf.write("recovered the graded review from the turn transcript verbatim below (attributed, not edited)._\n\n")
                rf.write("```text\n")
                rf.write(log_text)
                rf.write("\n```\n")
            print("aider-turn: review turn landed no relay-file delta but the transcript carried a graded review — salvaged it into the relay file (attributed; GH-251)", file=sys.stderr)

    # GH-278: Aider pre-creates 0-byte stubs for --file targets before it starts writing.
    # If the turn is killed (exit 7), these empty stubs must not be committed as "progress".
    if bounded_rc == 7 and allow_paths:
        for ap in claim_paths[1:]:
            ap_full = os.path.join(root, ap)
            if os.path.isfile(ap_full) and os.path.getsize(ap_full) == 0:
                try:
                    r = subprocess.run(["git", "-C", root, "ls-files", "--error-unmatch", ap], capture_output=True)
                    if r.returncode == 0:
                        subprocess.run(["git", "-C", root, "checkout", "HEAD", "--", ap], capture_output=True)
                    else:
                        os.remove(ap_full)
                except Exception:
                    pass

    rc = rtl.enforce(t, me, aider_log, "aider")

    if bounded_rc == 7:
        sys.exit(7)

    sys.exit(rc)

if __name__ == "__main__":
    main()
