import importlib.util as u
sp = u.spec_from_file_location("bq", "skills/1-hourly/kickstart/scripts/build_queue.py")
m = u.module_from_spec(sp); sp.loader.exec_module(m)
f, S, B = m.parse_daily_goals_refs, "HiQS-Labs/XYZ-forge", chr(96)
assert f("- [ ] " + B + "other/repo#9" + B + " then #10\n", S, 1) == [], "backticked foreign lead admitted a later #N"
assert f("- [ ] other/repo#9 then #10\n", S, 1) == [], "plain foreign lead control"
assert f("- [ ] " + B + "#12" + B + " then #10\n", S, 1) == [12], "backticked local lead control"
assert f("- [ ] #11 then #10\n", S, 1) == [11], "local lead control"
assert f("Do #14 and " + B + "other/repo#9" + B + " #15\n", S, 1) == [14, 15], "no-task-list path changed"
