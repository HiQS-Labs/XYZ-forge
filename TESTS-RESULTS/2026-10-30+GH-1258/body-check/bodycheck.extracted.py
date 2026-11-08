import json, re, sys
s = open(sys.argv[1], encoding="utf-8").read()
tier = (re.search(r"· tier: (standard|spike)", s) or sys.exit("refuse: footer tier missing")).group(1)
heads = ["Observed", "Root cause|Diagnosis / existing gap", "Plan", "Blast radius", "Dependencies", "Acceptance",
         "Verification", "Non-goals", "Risk and rollback", "PRS proposal"] + ([] if tier == "spike" else ["Preflight Contract"])
parts = re.split(r"^## (.+)$", s, flags=re.M); body = dict(zip(parts[1::2], parts[2::2]))
for h in heads:
    k = next((x for x in body if re.match(rf"(?:{h})(\s|\(|$)", x)), None)   # heading may carry a suffix like "(date, sha)"
    if not k: sys.exit(f"refuse: missing heading ## {h}")
    if not body[k].strip(): sys.exit(f"refuse: empty section ## {k}")
acc = [l for l in body["Acceptance"].splitlines() if l.strip()]
if not acc or any(not re.match(r"- \[[ x]\] \S", l) for l in acc): sys.exit("refuse: Acceptance must be `- [ ]` items only, at least one")
prs = {m.group(1): (int(m.group(2)), m.group(3)) for m in re.finditer(r"^- (pri|sev|appeal|effort) (\d{1,3}): (.*)$", body["PRS proposal"], re.M)}
if set(prs) != {"pri", "sev", "appeal", "effort"}: sys.exit("refuse: PRS proposal needs the four axis lines")
if any(not 1 <= v <= 100 for v, _ in prs.values()) or all(v <= 5 for v, _ in prs.values()): sys.exit("refuse: axes are 1–100, not a 1–5 scale")
if any(len(r.strip()) < 25 or "TODO" in r or "rationale" in r.lower() for _, r in prs.values()): sys.exit("refuse: each axis needs an issue-specific rationale line")
if tier != "spike":
    m = re.search(r"```json\s*(\{.*?\})\s*```", body["Preflight Contract"], re.S) or sys.exit("refuse: contract JSON missing")
    c = json.loads(m.group(1))
    if c.get("target", {}).get("ref") != "development" or not c.get("gate") or not c.get("fix_probes") or not c.get("artifacts"): sys.exit("refuse: contract needs target.ref development, gate, fix_probes, artifacts")
if not re.search(r"^Recon: [0-9a-f]{7,} · base: development@[0-9a-f]{7,} · tier: ", s, re.M): sys.exit("refuse: footer needs Recon: <sha> · base: development@<sha>")
print("body check: ok", tier)
