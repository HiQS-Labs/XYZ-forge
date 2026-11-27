import sys; sys.path.insert(0, "utils/py")
import swarm_preflight as s
# Every separator Python str.splitlines() breaks on besides CR/LF; Markdown keeps them as line content.
for cp in (0x0B, 0x0C, 0x1C, 0x1D, 0x1E, 0x85, 0x2028, 0x2029):
    L = chr(cp)
    t = "## Acceptance\n\n- [ ] Alpha" + L + "beta\n- [ ] Gamma\n"
    i = s.extract_acceptance_criteria(t, plain_bullets=True)
    c = s.extract_acceptance_criteria(t)
    k = s.collect_inline_checklist(t)[0]
    assert i == c and len(i) == 2 and "Alpha" in i[0] and "beta" in i[0], (hex(cp), i, c)
    assert len(k) == 2 and k[0][1] == ["- [ ] Alpha" + L + "beta"], (hex(cp), "raw checklist line", k)
    v = s.extract_declared_deviations("## Acceptance — deviations from the issue\n- [added] Alpha" + L + "- [added] beta — reason: R\n")
    assert len(v["added"]) == 1 and v["added"][0][0].startswith("Alpha") and not v["malformed"], (hex(cp), "deviations reader", v)
    f = "## Acceptance\n\n- [ ] Real\n\n~~~\n~~~" + L + "\n- example output\n~~~\n"
    assert s.extract_acceptance_criteria(f, plain_bullets=True) == ["Real"], (hex(cp), "fence control")
assert s.extract_acceptance_criteria("## Acceptance\n\n- [ ] A\r\n- [ ] B\r- [ ] C\n") == ["A", "B", "C"], "CR/LF control"
