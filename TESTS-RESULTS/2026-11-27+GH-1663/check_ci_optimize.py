#!/usr/bin/env python3
"""GH-1663 retained manual check (not a suite, not a gate; GH-831).

Self-consistency and link portability of skills/4-occasional/ci-optimize/SKILL.md.

  check_ci_optimize.py --skill-file FILE --label L [--base-file BASE] [--jsonl OUT] [--red-controls]

Prints one JSON object per run and exits 0 only when every assertion holds.
--base-file supplies the unchanged file, used to prove the score band lines are untouched.
--red-controls (run on the candidate) reverts each edit alone in a temp copy and requires exactly
the matching assertion(s) to flip to false.
Reads FILE only; builds throwaway layouts under a temp dir. Python 3.9+.
"""
import argparse, hashlib, json, os, re, shutil, sys, tempfile

REPO_FORGE = "HiQS-Labs/XYZ-forge"
REPO_PRED = "Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm"
EXPECT_FORGE = {35, 365, 558}
EXPECT_PRED = {42, 376, 528, 544, 549, 564}
BAND_RE = re.compile(r"^\* \*\*(20–24|14–19|<14) ")

ASSERTIONS = [
    "a1_heading_count_matches_headings",
    "a2_description_names_principle_count_and_rubric_rows",
    "a3_extension_intro_present",
    "a4_scorecard_note_present_and_bands_unchanged",
    "a5_roadmap_sentence_scoped",
    "a6_wave4_node_matches_wave4_list",
    "a7_provenance_attributed_by_repo",
    "a8_every_relative_link_has_flat_fallback",
    "a9_relative_links_valid_in_forge_tree",
]


def sha(text):
    return hashlib.sha1(text.encode("utf-8")).hexdigest()


def analyze(text, base_text=None):
    lines = text.splitlines()
    out, ok = {}, {}
    # guarded extractions: an empty extraction must fail, not pass
    heads = [int(m.group(1)) for l in lines if (m := re.match(r"^### (\d+)\. ", l))]
    n = len(heads)
    sc_i = next((i for i, l in enumerate(lines) if l.startswith("## CI/CD Audit Scorecard")), None)
    sc_end = next((i for i in range(sc_i + 1, len(lines)) if lines[i].startswith("## ")), len(lines)) if sc_i is not None else None
    sc = lines[sc_i:sc_end] if sc_i is not None else []
    rows = [l for l in sc if re.match(r"^\| \d+ \| \*\*", l)]
    try:
        fm_end = lines.index("---", 1)
        desc = " ".join(lines[1:fm_end])
    except ValueError:
        desc = ""
    h_i = next((i for i, l in enumerate(lines) if re.match(r"^## The \d+ Foundational Principles", l)), None)
    h_n = int(re.match(r"^## The (\d+)", lines[h_i]).group(1)) if h_i is not None else None
    out.update(principle_headings=n, scorecard_rows=len(rows), heading_says=h_n)

    ok["a1_heading_count_matches_headings"] = n >= 1 and h_n == n

    m = re.search(r"(\d+)-point", desc)
    ok["a2_description_names_principle_count_and_rubric_rows"] = bool(
        n >= 1 and rows and m and int(m.group(1)) == len(rows) and f"{n} principles" in desc)
    out["description_point"] = int(m.group(1)) if m else None

    intro = ""
    if h_i is not None:
        intro = next((l for l in lines[h_i + 1:] if l.strip()), "")
    il = intro.lower()
    ok["a3_extension_intro_present"] = bool(
        "principles 1-12" in il and "scored" in il and "waves" in il and "13-14" in il
        and "situational extensions" in il and "when the situation arises" in il and "outside" in il)

    after_table = []
    seen_row = False
    for l in sc:
        if re.match(r"^\| \d+ \| \*\*", l):
            seen_row = True
        elif seen_row and l.strip() and not l.startswith("|"):
            after_table.append(l)
    note = next((l for l in after_table if l.startswith(">")), "")
    bands = [l for l in sc if BAND_RE.match(l)]
    bands_same = True
    if base_text is not None:
        bl = base_text.splitlines()
        bs = next((i for i, l in enumerate(bl) if l.startswith("## CI/CD Audit Scorecard")), 0)
        base_bands = [l for l in bl[bs:] if BAND_RE.match(l)]
        bands_same = bool(base_bands) and base_bands == bands
    ok["a4_scorecard_note_present_and_bands_unchanged"] = bool(
        note and "P13" in note and "P14" in note and "no scorecard row" in note and "P1–P12" in note
        and len(bands) == 3 and bands_same)

    rs = next((l for l in lines if l.startswith("Adopt ") and "waves" in l), "")
    ok["a5_roadmap_sentence_scoped"] = "Principles 1-12" in rs

    node = next((l for l in lines if 'W4["' in l), "")
    node = node[node.index('W4["'):] if node else ""
    lst = next((l for l in lines if l.startswith("4. **Wave 4")), "")
    node_set = set()
    for a, b in re.findall(r"P(\d+)(?:-P(\d+))?", node):
        node_set.update(range(int(a), int(b or a) + 1))
    list_set = {int(x) for x in re.findall(r"P(\d+)", lst)}
    out.update(wave4_node=sorted(node_set), wave4_list=sorted(list_set))
    ok["a6_wave4_node_matches_wave4_list"] = bool(node_set) and node_set == list_set

    para = ""
    for i, l in enumerate(lines):
        if l.startswith("Distilled from"):
            j = i
            while j < len(lines) and lines[j].strip():
                j += 1
            para = " ".join(lines[i:j])
            break
    cut = para.find("predecessor")
    forge_part, pred_part = (para[:cut], para[cut:]) if cut >= 0 else (para, "")
    nums = lambda t: {int(x) for x in re.findall(r"#(\d+)", t)}
    got_f, got_p = nums(forge_part), nums(pred_part)
    out.update(provenance_forge=sorted(got_f), provenance_predecessor=sorted(got_p))
    ok["a7_provenance_attributed_by_repo"] = bool(
        para and para.count("[%s]" % REPO_FORGE) == 1 and para.count("[%s]" % REPO_PRED) == 1 and "predecessor" in para
        and got_f == EXPECT_FORGE and got_p == EXPECT_PRED)

    # relative links, in three throwaway layouts
    links = [m for m in re.findall(r"\]\(([^)]+)\)", text) if not re.match(r"^(https?:|#|mailto:)", m)]
    tmp = tempfile.mkdtemp(prefix="gh1663-")
    res = []
    try:
        def put(path, content="x\n"):
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, "w", encoding="utf-8").write(content)
        tree = os.path.join(tmp, "tree", "skills", "4-occasional", "ci-optimize")
        put(os.path.join(tree, "SKILL.md"), text)
        put(os.path.join(tmp, "tree", "skills", "1-hourly", "sanity-check", "SKILL.md"))
        put(os.path.join(tmp, "tree", "skills", "4-occasional", "ci-suite-audit", "SKILL.md"))
        flat = os.path.join(tmp, "flat", "collection")
        put(os.path.join(flat, "ci-optimize", "SKILL.md"), text)
        put(os.path.join(flat, "sanity-check", "SKILL.md"))
        put(os.path.join(flat, "ci-suite-audit", "SKILL.md"))
        solo = os.path.join(tmp, "solo", "collection")
        put(os.path.join(solo, "ci-optimize", "SKILL.md"), text)
        for l in links:
            name = os.path.basename(os.path.dirname(l))
            res.append({
                "link": l, "skill": name,
                "resolves_in_forge_tree": os.path.exists(os.path.normpath(os.path.join(tree, l))),
                "resolves_in_flat_install_with_sibling": os.path.exists(os.path.normpath(os.path.join(flat, "ci-optimize", l))),
                "resolves_in_flat_install_sibling_absent": os.path.exists(os.path.normpath(os.path.join(solo, "ci-optimize", l))),
                "flat_fallback_sentence": ("In a flat installed collection, resolve `%s` by name." % name) in text,
            })
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    out["relative_links"] = res
    ok["a8_every_relative_link_has_flat_fallback"] = len(res) >= 2 and all(r["flat_fallback_sentence"] for r in res)
    ok["a9_relative_links_valid_in_forge_tree"] = len(res) >= 2 and all(r["resolves_in_forge_tree"] for r in res)

    out["assertions"] = {k: ok[k] for k in ASSERTIONS}
    out["ok"] = all(ok.values())
    return out


# single-edit reverts (candidate -> state with only that edit undone) and the assertions each must flip
def mutants(text):
    def sub(t, old, new):
        assert t.count(old) == 1, "mutant anchor not unique: " + old[:50]
        return t.replace(old, new)
    desc_new = ("Provides 14 principles (a 12-point scored audit rubric plus two situational\n"
                "  extensions), failure prevention mechanisms, and a phased adoption roadmap calibrated to repository risk.")
    desc_old = ("Provides a structured 12-point audit rubric, failure prevention\n"
                "  mechanisms, and a phased adoption roadmap calibrated to repository risk.")
    m = {}
    m["edit1_description"] = (sub(text, desc_new, desc_old), {"a2_description_names_principle_count_and_rubric_rows"})
    i = text.index("developer runs (XYZ-forge issues")
    j = text.index("Every rule states", i)
    m["edit2_provenance"] = (text[:i] + "developer runs (#35, #42/#376, #365, #528, #544, #558, #549, #564). " + text[j:],
                             {"a7_provenance_attributed_by_repo"})
    t = sub(text, "## The 14 Foundational Principles\n\nPrinciples 1-12 are scored in the scorecard and sequenced in the four waves. Principles 13-14 are situational extensions: apply them when the situation arises. They are intentionally outside the 12-row scored rubric and the waves.\n\n",
            "## The 12 Foundational Principles\n\n")
    m["edit3_heading_and_intro"] = (t, {"a1_heading_count_matches_headings", "a3_extension_intro_present"})
    t = sub(text, "Adopt Principles 1-12 in 4", "Adopt these principles in 4")
    t = sub(t, "P9 Hosted CI, ", "")
    m["edit4_roadmap_sentence_and_node"] = (t, {"a5_roadmap_sentence_scoped", "a6_wave4_node_matches_wave4_list"})
    m["edit5_scorecard_note"] = (sub(text, "> P13 and P14 are situational extensions with no scorecard row: the 0–24 scale and the A/B/C bands below score P1–P12 only.\n\n", ""),
                                 {"a4_scorecard_note_present_and_bands_unchanged"})
    m["edit6_ci_suite_audit_fallback"] = (sub(text, " In a flat installed collection, resolve `ci-suite-audit` by name.", ""),
                                          {"a8_every_relative_link_has_flat_fallback"})
    return m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--skill-file", required=True)
    ap.add_argument("--label", required=True)
    ap.add_argument("--base-file")
    ap.add_argument("--jsonl")
    ap.add_argument("--red-controls", action="store_true")
    a = ap.parse_args()
    text = open(a.skill_file, encoding="utf-8").read()
    if not text.strip():
        print(json.dumps({"label": a.label, "ok": False, "error": "empty skill file"}))
        return 1
    base_text = open(a.base_file, encoding="utf-8").read() if a.base_file else None
    r = analyze(text, base_text)
    r.update(kind="ci-optimize-selfconsistency", label=a.label, file_sha1=sha(text))
    code = 0 if r["ok"] else 1
    print(json.dumps(r, indent=2))
    if a.jsonl:
        open(a.jsonl, "a").write(json.dumps(r) + "\n")
    if a.red_controls:
        rc_ok = True
        for name, (mt, expect_false) in mutants(text).items():
            mr = analyze(mt, base_text)
            false_now = {k for k, v in mr["assertions"].items() if not v}
            good = (not mr["ok"]) and false_now == expect_false
            rc_ok &= good
            row = {"kind": "ci-optimize-red-control", "label": a.label, "mutant": name,
                   "exit_status_of_checker": 0 if mr["ok"] else 1, "assertions_false": sorted(false_now),
                   "expected_false": sorted(expect_false), "mutant_sha1": sha(mt), "pass": good}
            print(json.dumps(row))
            if a.jsonl:
                open(a.jsonl, "a").write(json.dumps(row) + "\n")
        if not rc_ok:
            print("RED CONTROL FAILURE", file=sys.stderr)
            code = code or 2
    return code


if __name__ == "__main__":
    sys.exit(main())
