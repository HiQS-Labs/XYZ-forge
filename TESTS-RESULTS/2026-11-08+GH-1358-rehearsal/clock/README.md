# Bounded clock repair controls

The controls execute the actual existing nested run_pre_advance_gate function extracted
via AST, with controlled clock/process inputs. They do not reproduce its decision code
or execute a real gate. Old-code red observations are retained. The existing gh390 suite
covers the real driver main path; gh280 covers adjacent Jog composition, in a separate
full clone. Runtime changes belong only to marathon_drive.py. No new suite/gate.
