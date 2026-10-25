# GH-1219 Manual Check — `consult.py` blind A/B reconcile with neutral answer payloads and `key.json`

## Summary

Verified in throwaway git repositories under `$TMPDIR` with stub advisor binaries (never invoking live models or mutating this repository's working tree) across all required cases, both before the fix (**red control**) and after the fix (**green control**):

1. **Red control (pre-fix `79528ea3`)**: running `consult.py` / `consult.sh` produces only the advisor-named transcripts (`<label>.codex.md`, `<label>.agy.md`), prepended with `> **ATTESTATION**` (`> Model:`, `> Provider:`, `> Sandbox:`), raw CLI banners (`OpenAI Codex v0.1.0`, `model: gpt-5-codex`), and advisor-named citation stamps (`codex's answer carries...`), with no `answer-*.md` or `key.json`.
2. **Green control (post-fix)**:
   - **Neutral payloads (`answer-A.md`, `answer-B.md`)**: contain no `ATTESTATION`, `Model:`, `Provider:`, `Sandbox:`, CLI banners, advisor/model/provider names, or named transcript filenames; kept warnings (such as `**NO FIRSTHAND VERIFICATION CITED**`) replace the advisor name with the neutral ID (`A's answer carries...`), while named originals (`<label>.codex.md`, `<label>.agy.md`) remain intact with their full attestation headers and advisor-named stamps.
   - **Correct mapping (`key.json`)**: maps each neutral ID (`A`, `B`, …) to its `advisor`, original `file`, and `answer_file`.
   - **Seeded stable order & `consult.sh` entry point parity**: rerunning with the same `--label` through the default `relay-automation/consult.sh` entry point (which execs `utils/py/consult.py`) produces the exact same shuffled order, `key.json`, and `answer-*.md` contents; changing `--label` (`abcheck` vs `panel2`) deterministically permutes the order (`A=codex, B=agy` vs `A=agy, B=codex`).
   - **Degraded single-model run**: when 2 advisors are requested and 1 fails, the surviving named transcript receives the `**SINGLE-MODEL — NOT RECONCILED** (only codex answered...)` stamp and `DEGRADED-SINGLE-MODEL.txt` sidecar as before, while `answer-A.md` strips the advisor-identifying single-model stamp and writes `key.json`.
   - **JSON-mode answers (`CONSULT_GEMINI_JSON=1`)**: when `${label}.gemini.json` carries a JSON envelope with identifying `model`, `provider`, and `metadata` fields alongside `.response`, `answer-A.md` projects only the decoded `.response` Markdown with zero envelope/model/provider strings, while keeping `${label}.gemini.json` byte-identical.

## Commands & Output

### 1. Throwaway Git Repo Red/Green Check (`$TMPDIR`)

Command:

```bash
python3 - <<'PYEOF'
import os, subprocess, tempfile, shutil, json, glob, re

repo_root = os.getcwd()
old_consult_bytes = subprocess.check_output(["git", "show", "79528ea36f3769712349b77c44edcb4c22029fbd:utils/py/consult.py"])

def run_cases(use_old=False):
    results = {}
    with tempfile.TemporaryDirectory(prefix="gh1219-probe-") as tmp:
        harness_dir = os.path.join(tmp, "harness")
        os.makedirs(os.path.join(harness_dir, "utils"))
        shutil.copytree(os.path.join(repo_root, "utils/py"), os.path.join(harness_dir, "utils/py"))
        shutil.copytree(os.path.join(repo_root, "relay-automation"), os.path.join(harness_dir, "relay-automation"))
        if use_old:
            with open(os.path.join(harness_dir, "utils/py/consult.py"), "wb") as f:
                f.write(old_consult_bytes)

        test_repo = os.path.join(tmp, "repo")
        os.makedirs(test_repo)
        subprocess.run(["git", "-C", test_repo, "init", "-q", "-b", "main"], check=True)
        subprocess.run(["git", "-C", test_repo, "config", "user.email", "t@t"], check=True)
        subprocess.run(["git", "-C", test_repo, "config", "user.name", "t"], check=True)
        with open(os.path.join(test_repo, "app.py"), "w") as f:
            f.write("def compute():\n    return 42\n")
        subprocess.run(["git", "-C", test_repo, "add", "app.py"], check=True)
        subprocess.run(["git", "-C", test_repo, "commit", "-qm", "init"], check=True)

        bin_dir = os.path.join(tmp, "bin")
        os.makedirs(bin_dir)

        codex_stub = os.path.join(bin_dir, "codex-stub")
        with open(codex_stub, "w") as f:
            f.write("""#!/usr/bin/env bash
printf 'OpenAI Codex v0.1.0\\n--------\\nmodel: gpt-5-codex\\nprovider: openai\\nsandbox: read-only\\n\\nANSWER: The implementation in app.py:1 is solid.\\n[Pass] looks good\\nRECOMMENDATION: proceed\\n'
""")
        os.chmod(codex_stub, 0o755)

        agy_stub = os.path.join(bin_dir, "agy-stub")
        with open(agy_stub, "w") as f:
            f.write("""#!/usr/bin/env bash
case "${1:-}" in whoami|models) echo "agystub"; exit 0 ;; esac
printf 'ANSWER: Verified "return 42" at app.py:2.\\n[Pass] confirmed by "return 42" at app.py:2\\nRECOMMENDATION: ship\\n'
""")
        os.chmod(agy_stub, 0o755)

        gemini_json_stub = os.path.join(bin_dir, "gemini-json-stub")
        with open(gemini_json_stub, "w") as f:
            f.write("#!/usr/bin/env python3\nimport json\nprint(json.dumps({'model': 'gemini-2.5-pro', 'provider': 'google-gca', 'metadata': {'advisor': 'gemini', 'session': 's-99'}, 'response': 'ANSWER: Checked \"def compute():\" at app.py:1.\\n[Pass] verified by \"def compute():\" at app.py:1\\nRECOMMENDATION: approve'}))\n")
        os.chmod(gemini_json_stub, 0o755)

        env = dict(os.environ)
        env["XYZ_ROOT"] = harness_dir
        env["PYTHONPATH"] = os.path.join(harness_dir, "utils/py")
        env["CONSULT_ROOT"] = test_repo
        env["CODEX_BIN"] = codex_stub
        env["AGY_BIN"] = agy_stub
        env["GEMINI_BIN"] = gemini_json_stub
        env["CODEX_FLAGS"] = " "
        env["XYZ_WRITE_OPS_LOG"] = "0"

        h_py = os.path.join(harness_dir, "utils/py/consult.py")
        h_sh = os.path.join(harness_dir, "relay-automation/consult.sh")

        # 1. Direct consult.py 2-model panel (label=abcheck -> A=codex, B=agy)
        out1 = os.path.join(tmp, "out1")
        subprocess.run(["python3", h_py, "--prompt", "Check app.py", "--models", "codex,agy", "--out", out1, "--label", "abcheck"], env=env, check=True, capture_output=True)
        rd1 = sorted(glob.glob(os.path.join(out1, "abcheck-*")))[0]

        # 2. Default consult.sh entry point rerun with same label (abcheck)
        out2 = os.path.join(tmp, "out2")
        subprocess.run(["bash", h_sh, "--prompt", "Check app.py", "--models", "codex,agy", "--out", out2, "--label", "abcheck"], env=env, check=True, capture_output=True)
        rd2 = sorted(glob.glob(os.path.join(out2, "abcheck-*")))[0]

        # 3. Different label (label=panel2 -> seed flips order: A=agy, B=codex)
        out3 = os.path.join(tmp, "out3")
        subprocess.run(["bash", h_sh, "--prompt", "Check app.py", "--models", "codex,agy", "--out", out3, "--label", "panel2"], env=env, check=True, capture_output=True)
        rd3 = sorted(glob.glob(os.path.join(out3, "panel2-*")))[0]

        # 4. Degraded single-model run (codex answers, agy fails)
        agy_fail = os.path.join(bin_dir, "agy-fail")
        with open(agy_fail, "w") as f:
            f.write("#!/usr/bin/env bash\nexit 1\n")
        os.chmod(agy_fail, 0o755)
        env_deg = dict(env, AGY_BIN=agy_fail)
        out4 = os.path.join(tmp, "out4")
        subprocess.run(["bash", h_sh, "--prompt", "Check app.py", "--models", "codex,agy", "--out", out4, "--label", "degcheck"], env=env_deg, check=True, capture_output=True)
        rd4 = sorted(glob.glob(os.path.join(out4, "degcheck-*")))[0]

        # 5. CONSULT_GEMINI_JSON=1 run
        env_json = dict(env, CONSULT_GEMINI_JSON="1")
        out5 = os.path.join(tmp, "out5")
        subprocess.run(["bash", h_sh, "--prompt", "Check app.py", "--models", "gemini", "--out", out5, "--label", "jsoncheck"], env=env_json, check=True, capture_output=True)
        rd5 = sorted(glob.glob(os.path.join(out5, "jsoncheck-*")))[0]

        has_ab1 = os.path.isfile(os.path.join(rd1, "answer-A.md")) and os.path.isfile(os.path.join(rd1, "answer-B.md")) and os.path.isfile(os.path.join(rd1, "key.json"))
        if not has_ab1:
            results["has_neutral_payloads"] = False
            results["run1_files"] = sorted(os.listdir(rd1))
            return results

        ans_a1 = open(os.path.join(rd1, "answer-A.md")).read()
        ans_b1 = open(os.path.join(rd1, "answer-B.md")).read()
        key1 = json.load(open(os.path.join(rd1, "key.json")))
        key2 = json.load(open(os.path.join(rd2, "key.json")))
        key3 = json.load(open(os.path.join(rd3, "key.json")))
        ans_a4 = open(os.path.join(rd4, "answer-A.md")).read()
        orig_deg4 = open(os.path.join(rd4, "degcheck.codex.md")).read()
        ans_a5 = open(os.path.join(rd5, "answer-A.md")).read()
        orig_json5 = open(os.path.join(rd5, "jsoncheck.gemini.json")).read()
        key5 = json.load(open(os.path.join(rd5, "key.json")))

        leak_re = re.compile(r"(ATTESTATION|Model:|Provider:|Sandbox:|codex|agy|gemini|openai|google-gca|gpt-5-codex|gemini-2\.5-pro|\.codex\.md|\.agy\.md|\.gemini\.json)", re.IGNORECASE)

        results["has_neutral_payloads"] = True
        results["run1_key"] = key1
        results["run1_answer_A"] = ans_a1.strip()
        results["run1_answer_B"] = ans_b1.strip()
        results["run1_no_leaks_in_A_or_B"] = (leak_re.search(ans_a1) is None) and (leak_re.search(ans_b1) is None)
        results["run1_named_originals_intact"] = ("ATTESTATION" in open(os.path.join(rd1, "abcheck.codex.md")).read()) and ("codex's answer" in open(os.path.join(rd1, "abcheck.codex.md")).read())
        results["rerun_consult_sh_matches_consult_py"] = (key1 == key2) and (ans_a1 == open(os.path.join(rd2, "answer-A.md")).read()) and (ans_b1 == open(os.path.join(rd2, "answer-B.md")).read())
        results["panel2_shuffled_order"] = {k: v["advisor"] for k, v in key3.items()}
        results["degraded_single_model"] = {
            "named_original_has_single_model_stamp": "SINGLE-MODEL" in orig_deg4 and "only codex answered" in orig_deg4,
            "neutral_A_stripped_single_model_stamp": "SINGLE-MODEL" not in ans_a4 and leak_re.search(ans_a4) is None,
        }
        results["gemini_json_mode"] = {
            "raw_json_has_envelope_metadata": "gemini-2.5-pro" in orig_json5 and "google-gca" in orig_json5,
            "neutral_A_only_decoded_response": ans_a5.strip(),
            "neutral_A_no_leaks": leak_re.search(ans_a5) is None,
            "key": key5,
        }
    return results

print("=== RED (pre-fix 79528ea3) ===")
print(json.dumps(run_cases(use_old=True), indent=2))
print("=== GREEN (post-fix) ===")
print(json.dumps(run_cases(use_old=False), indent=2))
PYEOF
```

Output:

```json
=== RED (pre-fix 79528ea3) ===
{
  "has_neutral_payloads": false,
  "run1_files": [
    "abcheck.PROMPT.txt",
    "abcheck.agy.PROVENANCE.txt",
    "abcheck.agy.md",
    "abcheck.codex.NO-CITATION.txt",
    "abcheck.codex.PROVENANCE.txt",
    "abcheck.codex.md"
  ]
}
=== GREEN (post-fix) ===
{
  "has_neutral_payloads": true,
  "run1_key": {
    "A": {
      "advisor": "codex",
      "answer_file": "answer-A.md",
      "file": "abcheck.codex.md"
    },
    "B": {
      "advisor": "agy",
      "answer_file": "answer-B.md",
      "file": "abcheck.agy.md"
    }
  },
  "run1_answer_A": "**NO FIRSTHAND VERIFICATION CITED** \u2014 treat conclusions as conditional (A's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)\n\nANSWER: The implementation in app.py:1 is solid.\n[Pass] looks good\nRECOMMENDATION: proceed",
  "run1_answer_B": "ANSWER: Verified \"return 42\" at app.py:2.\n[Pass] confirmed by \"return 42\" at app.py:2\nRECOMMENDATION: ship",
  "run1_no_leaks_in_A_or_B": true,
  "run1_named_originals_intact": true,
  "rerun_consult_sh_matches_consult_py": true,
  "panel2_shuffled_order": {
    "A": "agy",
    "B": "codex"
  },
  "degraded_single_model": {
    "named_original_has_single_model_stamp": true,
    "neutral_A_stripped_single_model_stamp": true
  },
  "gemini_json_mode": {
    "raw_json_has_envelope_metadata": true,
    "neutral_A_only_decoded_response": "ANSWER: Checked \"def compute():\" at app.py:1.\n[Pass] verified by \"def compute():\" at app.py:1\nRECOMMENDATION: approve",
    "neutral_A_no_leaks": true,
    "key": {
      "A": {
        "advisor": "gemini",
        "answer_file": "answer-A.md",
        "file": "jsoncheck.gemini.json"
      }
    }
  }
}
```

### 2. Existing Consult Suites

```text
$ bash test/consult.sh && bash test/gh308-consult-guards.sh && bash test/gh589-consult-no-tick.sh && bash test/gh648-l3-consult-cap.sh
== test: consult ==
  consult: 62 passed, 0 failed
== test: gh308-consult-guards ==
  gh308-consult-guards: 4 pass, 0 fail
== test: gh589-consult-no-tick ==
gh589-consult-no-tick: 6 passed, 0 failed
PASS: default 600s, override, wall partial, truthful idle kill, completion, wall/idle JSON preservation
```
