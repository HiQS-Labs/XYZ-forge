#!/usr/bin/env python3
import os
import re
import sys
import tempfile
import subprocess
import shlex
import time
from datetime import datetime
import shutil
from rtl import RelayTurnLib, resolve_tick_bin, resolve_tick_repo_root, agy_auth_output_verdict

# Aider can exit 0 while printing an auth/config error transcript, or return only reasoning tokens with
# empty visible content (GH-147 spike 0.1/0.4). Either is a failed advisor, not a real answer — trusting
# the exit code alone false-greens the consult.
_AIDER_FAIL_RE = re.compile(
    r"litellm\.[A-Za-z]*Error|AuthenticationError|Incorrect API key|invalid_api_key"
    r"|Unable to list models|No API key was provided|NotFoundError|Traceback \(most recent call last\)"
)

# GH-178 A4 / GH-223 (Python port): same claim/citation definition as relay-turn-lib.sh's shared
# RTL_CLAIM_WORD_RE / RTL_CITATION_RE (used by both B3's per-line downgrade and consult.sh's A4
# stamp) — kept in lockstep with the Bash source, not redesigned. A "citation" is a quoted span
# ("..."/`...`) or a file:line reference (name:NNN); a "claim" is the [Pass] tag or one of a short
# list of assertion phrases (verified/confirmed/LGTM/looks good/etc).
_RTL_CLAIM_WORD_RE = re.compile(
    r"(^|[^A-Za-z])([Vv]erified|[Cc]onfirmed|LGTM|[Ll]ooks [Gg]ood|[Cc]hecks [Oo]ut|[Aa]ll [Gg]ood"
    r"|[Ww]orks [Aa]s [Ee]xpected|[Nn]o issues( found)?)([^A-Za-z]|$)"
)
_RTL_CITATION_RE = re.compile(r'"[^"]+"|`[^`]+`|[A-Za-z0-9_./-]+:[0-9]+')
_RTL_PASS_TAG_RE = re.compile(r"\[Pass\]")
_RTL_UNVERIFIED_RE = re.compile(r"\[Unverified — no citation\]")

def _citation_window():
    # Mirror Bash `win="${RTL_CITATION_WINDOW:-3}"` with awk-compatible numeric coercion: unset/empty
    # → 3; otherwise the leading integer ("5"→5, "3x"→3), a non-numeric value → 0.
    raw = os.environ.get("RTL_CITATION_WINDOW")
    if not raw:
        return 3
    m = re.match(r'\s*([+-]?\d+)', raw)
    return int(m.group(1)) if m else 0

def rtl_has_uncited_claim(path, window=None):
    """Python port of relay-turn-lib.sh's rtl_has_uncited_claim() (GH-178 A4 / GH-223): flags <path>
    if it carries zero citations anywhere, OR at least one claim-bearing line has no citation within
    `window` lines of itself (including its own line) — even though the file cites something
    elsewhere. Does NOT verify a citation is accurate, only that one was attempted nearby. Missing or
    unreadable file fails safe (flagged), matching the Bash version.
    """
    if window is None:
        window = _citation_window()
    try:
        with open(path, "r", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError:
        return True
    if not lines:
        return True
    any_cite = any(_RTL_CITATION_RE.search(l) for l in lines)
    if not any_cite:
        return True
    for i, line in enumerate(lines):
        if _RTL_UNVERIFIED_RE.search(line):
            continue
        claim = bool(_RTL_PASS_TAG_RE.search(line)) or bool(_RTL_CLAIM_WORD_RE.search(line))
        if not claim:
            continue
        window_end = min(len(lines), i + window + 1)
        cited = any(_RTL_CITATION_RE.search(lines[j]) for j in range(i, window_end))
        if not cited:
            return True
    return False

def _rtl_norm(s):
    # Mirror the awk norm(): collapse runs of whitespace to a single space, strip leading/trailing.
    return re.sub(r"[ \t\r\n\f\v]+", " ", s).strip()

def rtl_classify_cited_claims(transcript_path, prompt_path, window=None):
    """Python port of relay-turn-lib.sh's rtl_classify_cited_claims() (GH-235 A4 v0): for each
    ALREADY-CITED claim line in <transcript_path>, decide whether the nearby citation string was
    discovered firsthand in the transcript or merely echoed from the operator prompt text persisted
    in <prompt_path>. Yields ("ECHOED", token) or ("FIRSTHAND", token) per claim, matching the awk
    line-order. Missing/unreadable inputs yield nothing (mirrors the Bash early return). Known v0
    limitation (shared with Bash): exact/whitespace-normalized substring matching only — no fuzzy
    reformat matching."""
    if window is None:
        window = _citation_window()
    if not (transcript_path and os.path.isfile(transcript_path) and prompt_path and os.path.isfile(prompt_path)):
        return
    try:
        with open(prompt_path, "r", errors="replace") as f:
            prompt_lines = f.read().splitlines()
        with open(transcript_path, "r", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError:
        return
    # awk builds prompt as each line + "\n" then norms it (newlines collapse to spaces).
    prompt_norm = _rtl_norm("".join(pl + "\n" for pl in prompt_lines))
    n = len(lines)
    for i, line in enumerate(lines):
        if _RTL_UNVERIFIED_RE.search(line):
            continue
        claim = bool(_RTL_PASS_TAG_RE.search(line)) or bool(_RTL_CLAIM_WORD_RE.search(line))
        if not claim:
            continue
        first_token = None
        echoed_token = None
        window_end = min(n, i + window + 1)
        for j in range(i, window_end):
            for mo in _RTL_CITATION_RE.finditer(lines[j]):
                token = mo.group(0)
                if first_token is None:
                    first_token = token
                if _rtl_norm(token) in prompt_norm:
                    echoed_token = token
                    break
            if echoed_token is not None:
                break
        if first_token is None:
            continue
        if echoed_token is not None:
            yield ("ECHOED", echoed_token)
        else:
            yield ("FIRSTHAND", first_token)

def die(msg):
    print(f"consult: {msg}", file=sys.stderr)
    sys.exit(2)

def warn(msg):
    print(f"consult: {msg}", file=sys.stderr)

def aider_answer_ok(out_path):
    """False if the Aider transcript shows an auth/config failure or has no visible answer."""
    try:
        with open(out_path, "r", errors="replace") as f:
            text = f.read()
    except OSError:
        return False
    if not text.strip():
        with open(out_path, "a") as f:
            f.write("\nconsult: Aider returned no visible content (empty answer — likely reasoning-only or a silent failure).\n")
        return False
    if _AIDER_FAIL_RE.search(text):
        with open(out_path, "a") as f:
            f.write("\nconsult: Aider transcript shows an auth/config failure — counted as FAILED (was exit 0).\n")
        return False
    return True

def consult_codex_attestation(out_path):
    # GH-308 port (consult.sh run_codex): prepend an ATTESTATION provenance header (which
    # model/provider/sandbox actually answered), parsed from the codex output. This lived only in the
    # Bash twin, so every codex transcript on the default lane silently lost the provenance stamp.
    if not os.path.isfile(out_path):
        return
    model = provider = sandbox = "unknown"
    try:
        with open(out_path, "r", errors="replace") as f:
            for line in f:
                if model == "unknown" and line.startswith("model:"):
                    model = line[len("model:"):].strip() or "unknown"
                elif provider == "unknown" and line.startswith("provider:"):
                    provider = line[len("provider:"):].strip() or "unknown"
                elif sandbox == "unknown" and line.startswith("sandbox:"):
                    sandbox = line[len("sandbox:"):].strip() or "unknown"
    except OSError:
        return
    header = f"> **ATTESTATION**\n> Model: {model}\n> Provider: {provider}\n> Sandbox: {sandbox}\n\n"
    try:
        with open(out_path, "r", errors="replace") as f:
            body = f.read()
        with open(out_path, "w") as f:
            f.write(header + body)
    except OSError:
        pass

def consult_agy_isolation_breach(out_path, root):
    # GH-308 port (GH-178 B1, consult.sh run_agy): True if the agy transcript cited the real repo root
    # (grounding escaped the isolation worktree), after filtering the GH-183/187 false-positive shapes
    # (tick-command narration, markdown file:// citations). Missing on the Python lane, so a real agy
    # grounding-escape was counted as a clean cross-model answer instead of failing the advisor.
    try:
        with open(out_path, "r", errors="replace") as f:
            for line in f:
                if line.startswith("[trace] "):
                    continue
                if "TICK_REPO_ROOT=" in line or "file://" in line or "](" in line:
                    continue
                if root in line:
                    return True
    except OSError:
        pass
    return False

def guarded_with_timeout(cmd, cwd, log_file, timeout_s, env=None):
    try:
        with open(log_file, "w") as f:
            proc = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)
            return proc
    except Exception as e:
        with open(log_file, "a") as f:
            f.write(f"\nconsult: failed to launch process: {e}\n")
        return None

def agy_auth_preflight(agy_bin, log_file):
    secs = int(os.environ.get("AGY_AUTH_TIMEOUT_S", 5))
    tmp = f"{log_file}.auth"
    try:
        with open(tmp, "w") as f:
            subprocess.run([agy_bin, "whoami"], stdout=f, stderr=subprocess.STDOUT, timeout=secs, check=True)
        # GH-375: `agy whoami` exits 0 while failing to run at all without a TTY, so exit status
        # cannot decide this — see agy_auth_output_verdict in rtl.py. Same hole as agy-turn.py, so
        # the same verdict function; a consult that proceeds on unestablished auth burns the panel.
        severity, detail = agy_auth_output_verdict(tmp)
        if severity == "unverifiable":
            # Not a failure. `agy whoami` needs a TTY and consult runs headless, so this branch is
            # the NORMAL path here, not an edge case — failing it closed would disable the agy seat
            # on every consult. Recorded in the log so a later credential failure is diagnosable.
            with open(log_file, "a") as f:
                if os.path.exists(tmp):
                    with open(tmp) as tf: f.write(tf.read())
                f.write(f"\nconsult: WARNING — {detail}. Proceeding; if agy fails on credentials, "
                        f"run `agy login` in a normal terminal.\n")
            if os.path.exists(tmp): os.remove(tmp)
            return True
        if severity:
            with open(log_file, "a") as f:
                if os.path.exists(tmp):
                    with open(tmp) as tf: f.write(tf.read())
                f.write(f"\nconsult: agy auth pre-flight exited 0 but {detail}. Run `agy login` in a normal terminal, then retry.\n")
            if os.path.exists(tmp): os.remove(tmp)
            return False
        if os.path.exists(tmp): os.remove(tmp)
        return True
    except subprocess.TimeoutExpired:
        with open(log_file, "a") as f:
            if os.path.exists(tmp):
                with open(tmp) as tf: f.write(tf.read())
            f.write(f"\nconsult: agy auth pre-flight timed out after {secs}s; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.\n")
    except subprocess.CalledProcessError as e:
        with open(log_file, "a") as f:
            if os.path.exists(tmp):
                with open(tmp) as tf: f.write(tf.read())
            f.write(f"\nconsult: agy auth pre-flight failed (exit {e.returncode}). Run `agy login` in a normal terminal, then retry.\n")
    except Exception as e:
        pass

    if os.path.exists(tmp): os.remove(tmp)
    return False

def main():
    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    root = os.environ.get("CONSULT_ROOT", xyz_root)
    consult_tick_root = resolve_tick_repo_root(root)
    consult_tick_bin = resolve_tick_bin(consult_tick_root, xyz_root)
    
    rtl = RelayTurnLib(root, xyz_root, "", "")  # Dummy init for transcript root
    
    codex_bin = os.environ.get("CODEX_BIN", "codex")
    agy_bin = os.environ.get("AGY_BIN", os.environ.get("GEMINI_BIN", "agy"))
    gemini_bin = os.environ.get("GEMINI_BIN", agy_bin)
    aider_bin = os.environ.get("AIDER_BIN", "aider")
    
    prompt_file = ""
    prompt_text = ""
    out_dir = ""
    models_str = "codex,agy"
    label = "consult"
    
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--prompt-file" and i + 1 < len(args):
            prompt_file = args[i+1]
            i += 2
        elif arg == "--prompt" and i + 1 < len(args):
            prompt_text = args[i+1]
            i += 2
        elif arg == "--out" and i + 1 < len(args):
            out_dir = args[i+1]
            i += 2
        elif arg == "--models" and i + 1 < len(args):
            models_str = args[i+1]
            i += 2
        elif arg == "--label" and i + 1 < len(args):
            label = args[i+1]
            i += 2
        elif arg == "--help":
            print("Usage: consult.sh --prompt \"question\" [--out DIR] [--models codex,agy] [--label SLUG]")
            sys.exit(0)
        else:
            die(f"unknown argument: {arg}")
            
    if not prompt_file and not prompt_text:
        die("one of --prompt-file or --prompt is required")
    if prompt_file and prompt_text:
        die("--prompt-file and --prompt are mutually exclusive")
        
    if prompt_file:
        if not os.path.isfile(prompt_file):
            die(f"prompt file not found: {prompt_file}")
        with open(prompt_file) as f:
            prompt_text = f.read()
            
    try:
        subprocess.run(["git", "-C", root, "rev-parse", "--is-inside-work-tree"], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        warn(f"consult requires a git repo (advisor isolation uses a throwaway worktree): {root}")
        sys.exit(3)
        
    if not out_dir:
        res = rtl._run_rtl(f"rtl_transcript_root {shlex.quote(root)}")
        if res.returncode != 0:
            sys.exit(1)
        ts_base = res.stdout.strip()
        out_dir = os.path.join(ts_base, datetime.now().strftime("%Y-%m-%d"))
        
    run_dir = os.path.join(out_dir, f"{label}-{datetime.now().strftime('%H%M%S')}")
    os.makedirs(run_dir, exist_ok=True)
    
    preamble = "You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy)."
    full_prompt = f"{preamble}\n\n=== CONSULT QUESTION ===\n{prompt_text}"
    # GH-235 A4 v0: persist ONLY the operator's PROMPT_TEXT (never the PREAMBLE) so the prompt-trace
    # classifier below can tell an echoed citation from a firsthand one. Written with no trailing
    # newline to mirror the Bash `printf '%s'`.
    prompt_snapshot = os.path.join(run_dir, f"{label}.PROMPT.txt")
    with open(prompt_snapshot, "w") as f:
        f.write(prompt_text)

    base_res = subprocess.run(["git", "-C", root, "stash", "create"], capture_output=True, text=True)
    base = base_res.stdout.strip()
    if not base:
        base = "HEAD"
        
    wt = tempfile.mkdtemp(prefix=f"consult-wt-{os.getpid()}-")
    
    res = subprocess.run(["git", "-C", root, "worktree", "add", "--detach", wt, base], capture_output=True)
    if res.returncode != 0:
        die(f"could not create isolation worktree (base {base})")
        
    try:
        try:
            ls_res = subprocess.run(["git", "-C", root, "ls-files", "--others", "--exclude-standard", "-z"], capture_output=True)
            if ls_res.stdout:
                for f in ls_res.stdout.split(b'\0'):
                    if not f: continue
                    f = f.decode('utf-8')
                    src = os.path.join(root, f)
                    dst = os.path.join(wt, f)
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    try:
                        shutil.copy2(src, dst)
                    except:
                        pass
        except Exception:
            pass
            
        timeout_s = int(os.environ.get("CONSULT_TIMEOUT", 300))
        models = [m.strip() for m in models_str.split(",") if m.strip()]
        
        procs = []
        
        for m in models:
            if m == "codex":
                f_out = os.path.join(run_dir, f"{label}.codex.md")
                cflags = os.environ.get("CODEX_FLAGS", "-s read-only").split()
                cenv = dict(os.environ)
                if os.environ.get("CODEX_ALLOW_API_KEY", "0") != "1":
                    cenv.pop("OPENAI_API_KEY", None)
                cmd = [codex_bin, "exec"] + cflags + [full_prompt]
                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, cenv)
                procs.append((proc, "codex", f_out, time.time(), cmd))
            elif m == "agy":
                f_out = os.path.join(run_dir, f"{label}.agy.md")
                if not agy_auth_preflight(agy_bin, f_out):
                    procs.append((None, "agy", f_out, time.time(), None))
                    continue
                cmd = [agy_bin, "--dangerously-skip-permissions", "--print-timeout", f"{timeout_s}s", "-p", full_prompt]
                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, dict(os.environ))
                procs.append((proc, "agy", f_out, time.time(), cmd))
            elif m == "gemini":
                ext = "json" if os.environ.get("CONSULT_GEMINI_JSON", "0") == "1" else "md"
                f_out = os.path.join(run_dir, f"{label}.gemini.{ext}")
                cenv = dict(os.environ)
                cenv["GOOGLE_GENAI_USE_GCA"] = cenv.get("GOOGLE_GENAI_USE_GCA", "true")
                cmd = [gemini_bin, "--yolo", "--skip-trust"]
                if ext == "json": cmd += ["-o", "json"]
                cmd += ["-p", full_prompt]
                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, cenv)
                procs.append((proc, "gemini", f_out, time.time(), cmd))
            elif m == "aider":
                f_out = os.path.join(run_dir, f"{label}.aider.md")
                aider_base = os.environ.get("AIDER_OPENAI_API_BASE", "")
                auth_args = []
                if aider_base:
                    # LM Studio / OpenAI-compatible seam (GH-147): the client still needs a non-empty key
                    # even when the local server ignores it, so a dummy is fine for a keyless endpoint.
                    aider_model = os.environ.get("AIDER_MODEL", "openai/agents-a1")
                    auth_args = ["--openai-api-base", aider_base, "--openai-api-key", os.environ.get("AIDER_OPENAI_API_KEY", "dummy")]
                else:
                    if not os.environ.get("OPENROUTER_API_KEY"):
                        with open(f_out, "w") as f:
                            f.write("consult: OPENROUTER_API_KEY not set — Aider cannot reach OpenRouter (or set AIDER_OPENAI_API_BASE for an OpenAI-compatible/LM Studio endpoint). Export it, then retry.\n")
                        procs.append((None, "aider", f_out, time.time(), None))
                        continue
                    aider_model = os.environ.get("AIDER_MODEL", "openrouter/anthropic/claude-sonnet-5")
                cmd = [aider_bin, "--model", aider_model] + auth_args + ["--message", full_prompt, "--yes-always", "--no-auto-commits", "--no-gitignore", "--no-check-update", "--no-analytics", "--no-show-model-warnings", "--no-stream", "--map-tokens", "0"]
                proc = guarded_with_timeout(cmd, wt, f_out, timeout_s, dict(os.environ))
                procs.append((proc, "aider", f_out, time.time(), cmd))
            else:
                warn(f"unknown model '{m}' — skipping")
                
        if not procs:
            die(f"no valid models to consult (got: {models_str})")
            
        answered = 0
        failed = 0
        summary = ""
        survivor_model = ""
        survivor_out = ""
        results = []  # (model, out_path, ok) — used by the GH-223 citation-stamp pass below

        for proc, m, out, start_time, cmd in procs:
            if proc is None:
                failed += 1
                summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
                results.append((m, out, False))
                continue

            try:
                rem = max(0, timeout_s - (time.time() - start_time))
                proc.wait(timeout=rem)

                # GH-308 port (consult.sh run_codex): stamp the codex transcript with its provenance
                # ATTESTATION header (whether the run succeeded or not, mirroring the Bash `[[ -f ]]` guard).
                if m == "codex":
                    consult_codex_attestation(out)

                # GH-308 port (GH-178 B1, consult.sh run_agy): a successful agy run whose transcript cited
                # the real repo root escaped its isolation worktree — fail the advisor (Bash `return 5`)
                # rather than count a silent grounding breach as a clean answer.
                breached = False
                if m == "agy" and proc.returncode == 0 and os.path.isfile(out) and os.path.getsize(out) > 0:
                    if consult_agy_isolation_breach(out, root):
                        with open(out, "a") as f:
                            f.write(f"\nconsult: [FAIL] agy transcript cited the real repo root ({root}) instead of the isolation worktree. This is a known agy isolation breach (grounding escaped $WT). Failing the turn to prevent a silent breach.\n")
                        breached = True

                if breached:
                    failed += 1
                    summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
                    results.append((m, out, False))
                elif proc.returncode == 0 and (m != "aider" or aider_answer_ok(out)):
                    answered += 1
                    summary += f"\n  [ok]   {m} -> {out}"
                    survivor_model = m
                    survivor_out = out
                    results.append((m, out, True))
                elif proc.returncode == 0:
                    # exit 0 but the aider transcript proved an auth/config failure or empty answer
                    failed += 1
                    summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
                    results.append((m, out, False))
                else:
                    failed += 1
                    summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
                    with open(out, "a") as f:
                        f.write(f"\nconsult: advisor failed with exit {proc.returncode}\n")
                    results.append((m, out, False))
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
                failed += 1
                summary += f"\n  [FAIL] {m} -> {out} (see transcript for error)"
                with open(out, "a") as f:
                    f.write(f"\nconsult: advisor failed or exceeded the {timeout_s}s cap\n")
                results.append((m, out, False))

        # GH-178 A4 / GH-223 (Python port): mechanically stamp any ANSWERED advisor whose transcript
        # trips rtl_has_uncited_claim() (defined above) — shared claim/citation definition with B3's
        # per-line downgrade — with the same stdout+prepended-transcript+sidecar mechanism as the A2
        # SINGLE-MODEL stamp below. Does NOT verify a citation is ACCURATE, only that a claim has one
        # attempted nearby. Mirrors relay-automation/consult.sh:310-336 — do not redesign, just port.
        citeless_models = []
        provenance_warnings = []  # (model, echoed_count) — GH-235 A4 v0 prompt-trace warnings
        for m, out, ok in results:
            if not ok:
                continue
            uncited = rtl_has_uncited_claim(out)
            if uncited:
                citeless_models.append(m)
                nocite = (
                    f"**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional "
                    f"({m}'s answer carries an unsupported [Pass]/verified/confirmed-style claim "
                    f"with no quoted span or file:line citation nearby, despite the consult "
                    f"PREAMBLE asking advisors to cite evidence.)"
                )
                if not out.endswith(".json"):
                    try:
                        with open(out, "r", errors="replace") as f:
                            existing = f.read()
                        with open(out, "w") as f:
                            f.write(nocite + "\n\n" + existing)
                    except OSError:
                        pass
                with open(os.path.join(run_dir, f"{label}.{m}.NO-CITATION.txt"), "w") as f:
                    f.write(nocite + "\n")

            # GH-235 A4 v0 (Python port of relay-automation/consult.sh:346-368): when the prompt
            # snapshot exists, classify each already-cited claim as FIRSTHAND or ECHOED (its citation
            # already appears in the operator prompt) and write a per-advisor PROVENANCE.txt sidecar.
            # An echoed citation on an otherwise-cited advisor (uncited == 0) raises a stdout warning.
            if os.path.isfile(prompt_snapshot):
                firsthand_count = 0
                echoed_count = 0
                echoed_tokens = []
                for kind, token in rtl_classify_cited_claims(out, prompt_snapshot):
                    if kind == "FIRSTHAND":
                        firsthand_count += 1
                    elif kind == "ECHOED":
                        echoed_count += 1
                        echoed_tokens.append(token)
                provenance = os.path.join(run_dir, f"{label}.{m}.PROVENANCE.txt")
                with open(provenance, "w") as f:
                    f.write(f"FIRSTHAND_COUNT={firsthand_count}\n")
                    f.write(f"ECHOED_COUNT={echoed_count}\n")
                    for token in echoed_tokens:
                        f.write(f"ECHOED {token}\n")
                if not uncited and echoed_count > 0:
                    provenance_warnings.append((m, echoed_count))

        # GH-178 A2 / GH-215 (Python port): a panel that started with MORE THAN ONE requested advisor
        # but ended with exactly one survivor is not a reconciled cross-model result — no second read
        # happened, so treating its verdict as reconciled is exactly the failure mode this consult
        # exists to avoid. Stamp it MECHANICALLY — into the surviving transcript itself, plus a
        # format-agnostic sidecar marker — so the caveat travels with the data instead of living only
        # in this run's stdout. Deliberately does NOT fire when only one model was ever requested: that
        # is an intentional single-model query, not a degrade. Mirrors relay-automation/consult.sh
        # (see the "GH-178 A2" comment there) — do not redesign, just port.
        degraded = False
        if len(procs) > 1 and answered == 1:
            degraded = True
            stamp = (
                f"**SINGLE-MODEL — NOT RECONCILED** (only {survivor_model} answered; {failed} of "
                f"{len(procs)} requested advisor(s) failed — this is one model's read, not a "
                f"cross-model consult. Do not treat any claim below as cross-verified.)"
            )
            if not survivor_out.endswith(".json"):
                try:
                    with open(survivor_out, "r", errors="replace") as f:
                        existing = f.read()
                    with open(survivor_out, "w") as f:
                        f.write(stamp + "\n\n" + existing)
                except OSError:
                    pass
            with open(os.path.join(run_dir, "DEGRADED-SINGLE-MODEL.txt"), "w") as f:
                f.write(stamp + "\n")

        if os.environ.get("CONSULT_GEMINI_JSON", "0") == "1":
            gj = os.path.join(run_dir, f"{label}.gemini.json")
            if os.path.exists(gj) and os.path.getsize(gj) > 0:
                if consult_tick_bin:
                    tick_env = dict(os.environ)
                    tick_env["TICK_REPO_ROOT"] = consult_tick_root
                    try:
                        subprocess.run(
                            [
                                consult_tick_bin,
                                "cost",
                                f"CONSULT-{label}",
                                "--agent",
                                "gemini",
                                "--from-gemini-json",
                                gj,
                                "--tool",
                                "gemini",
                            ],
                            env=tick_env,
                            stderr=subprocess.DEVNULL,
                            stdout=subprocess.DEVNULL,
                        )
                    except Exception:
                        warn("gemini tokens not captured (no parseable stats)")
                
    finally:
        subprocess.run(["git", "-C", root, "worktree", "remove", "--force", wt], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        subprocess.run(["git", "-C", root, "worktree", "prune"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        if os.path.exists(wt):
            shutil.rmtree(wt, ignore_errors=True)
        
    print(f"consult: {answered} answered, {failed} failed -> {run_dir}{summary}")
    if degraded:
        warn(f"SINGLE-MODEL — NOT RECONCILED (stamped into {survivor_out} and {os.path.join(run_dir, 'DEGRADED-SINGLE-MODEL.txt')})")
    if citeless_models:
        warn(f"NO FIRSTHAND VERIFICATION CITED for: {' '.join(citeless_models)} (stamped into transcript(s) + sidecar(s) in {run_dir})")
    for pw_model, pw_count in provenance_warnings:
        warn(f"prompt-trace classifier: {pw_model} echoed {pw_count} cited claim(s) from {label}.PROMPT.txt (see {os.path.join(run_dir, f'{label}.{pw_model}.PROVENANCE.txt')})")
    if answered == 0:
        warn("all advisors failed")
        sys.exit(5)
    sys.exit(0)

if __name__ == "__main__":
    main()
