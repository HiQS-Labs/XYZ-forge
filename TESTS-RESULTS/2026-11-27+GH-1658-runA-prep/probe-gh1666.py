import sys; sys.path.insert(0, "utils/py")
import swarm_preflight as s
for cp in (0x85, 0x2028, 0x2029):
    L = chr(cp)
    t = "## Acceptance\n\n- [ ] Alpha" + L + "beta\n- [ ] Gamma\n"
    i = s.extract_acceptance_criteria(t, plain_bullets=True)
    c = s.extract_acceptance_criteria(t)
    k = s.collect_inline_checklist(t)[0]
    assert i == c and len(i) == 2 and "Alpha" in i[0] and "beta" in i[0], (hex(cp), i, c)
    assert len(k) == 2 and "beta" in " ".join([k[0][0], *k[0][1]]), (hex(cp), k)
    f = "## Acceptance\n\n- [ ] Real\n\n~~~\n~~~" + L + "\n- example output\n~~~\n"
    assert s.extract_acceptance_criteria(f, plain_bullets=True) == ["Real"], (hex(cp), "fence control")
assert s.extract_acceptance_criteria("## Acceptance\n\n- [ ] A\r\n- [ ] B\r- [ ] C\n") == ["A", "B", "C"], "CR/LF control"
